-- ============================================================
-- jp-meridian9 / server/loot/fiction.lua
-- ============================================================
-- Config.FictionTags に基づく近接演出。loot スロット単位で 1 回のみ。
-- ============================================================

MRD9 = MRD9 or {}
MRD9.Loot = MRD9.Loot or {}

---@param row table|nil
local function writeFictionEvent(row)
    if not row then
        return
    end
    local ok, err = pcall(function()
        MySQL.insert.await(
            [[INSERT INTO mrd9_fiction_events
                (session_id, loot_id, fiction_tag, event_type, triggered_by, coords_x, coords_y, coords_z)
              VALUES (?, ?, ?, ?, ?, ?, ?, ?)]],
            {
                row.sessionId or '',
                row.lootId or '',
                row.fictionTag or '',
                row.eventType or '',
                row.triggeredBy or 'unknown',
                row.x,
                row.y,
                row.z,
            }
        )
    end)
    if not ok then
        MRD9.Log('fiction DB insert failed: %s', tostring(err))
    end
end

---@param src integer
---@param session table
---@param slot table
---@param lootId string
---@param fictionTag string
---@param spec table
---@return boolean, any
local function dispatchFiction(src, session, slot, lootId, fictionTag, spec)
    local onApproach = spec and spec.onApproach
    if type(onApproach) ~= 'table' then
        return false, 'no_onapproach'
    end
    local t = onApproach.type
    if t == 'spawnZombies' then
        local count = math.floor(tonumber(onApproach.count) or 3)
        local rMin = tonumber(onApproach.rMin) or 5.0
        local rMax = tonumber(onApproach.rMax) or 10.0
        local maxConcurrent = tonumber(onApproach.maxConcurrentPerSession) or 0
        local alive = tonumber(session.fictionAliveCount) or 0
        if maxConcurrent > 0 and alive + count > maxConcurrent then
            return false, 'spawnZombies_capped'
        end
        local center = slot.pickupCoords or slot.coords
        if not center then
            return false, 'no_coords'
        end
        local tag = ('fiction:%s'):format(fictionTag)
        local ok, ret = MRD9.Arena.SpawnAt(session.id, center, count, {
            targetSrc = src,
            rMin = rMin,
            rMax = rMax,
            persistent = true,
            tag = tag,
            isBoss = false,
        })
        if ok and type(ret) == 'number' and ret > 0 then
            session.fictionAliveCount = alive + ret
        end
        return ok, ret
    end
    return false, 'unknown_type:' .. tostring(t)
end

---@param src integer
---@param lootId string
---@return table
local function runFictionApproach(src, lootId)
    if type(src) ~= 'number' or src <= 0 then
        return { ok = false, reason = 'invalid_src' }
    end
    if type(lootId) ~= 'string' or lootId == '' then
        return { ok = false, reason = 'invalid_loot' }
    end

    local session = MRD9.Session.GetByPlayer(src)
    if not session or session.state ~= 'IN_MISSION' or type(session.loot) ~= 'table' then
        return { ok = false, reason = 'no_session' }
    end

    local memberOk = false
    for _, m in ipairs(session.members or {}) do
        if m == src then
            memberOk = true
            break
        end
    end
    if not memberOk then
        return { ok = false, reason = 'not_member' }
    end

    local slot = session.loot[lootId]
    if not slot or slot.picked then
        return { ok = false, reason = 'no_slot' }
    end

    local fictionTag = slot.fictionTag
    if type(fictionTag) ~= 'string' or fictionTag == '' then
        return { ok = false, reason = 'no_tag' }
    end

    local spec = (Config.FictionTags or {})[fictionTag]
    if type(spec) ~= 'table' then
        return { ok = false, reason = 'no_spec' }
    end

    if slot.spawnedFor then
        return { ok = true, triggered = false }
    end

    local onApproach = spec.onApproach
    local triggerDist = tonumber(onApproach and onApproach.triggerDistance) or 20.0
    local lc = slot.pickupCoords or slot.coords
    if not lc then
        return { ok = false, reason = 'no_coords' }
    end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then
        return { ok = false, reason = 'no_ped' }
    end
    local pc = GetEntityCoords(ped)
    if #(pc - lc) > triggerDist + 4.0 then
        return { ok = false, reason = 'distance' }
    end

    slot.spawnedFor = true
    slot.spawnedAt = os.time()

    local identifier = (MRD9.GetIdentifier and MRD9.GetIdentifier(src)) or ('src:' .. tostring(src))
    local ok, ret = dispatchFiction(src, session, slot, lootId, fictionTag, spec)

    local eventType = (spec.onApproach and spec.onApproach.type) or 'unknown'
    if not ok and ret == 'spawnZombies_capped' then
        eventType = 'spawnZombies_capped'
    end

    writeFictionEvent({
        sessionId = session.id,
        lootId = lootId,
        fictionTag = fictionTag,
        eventType = eventType,
        triggeredBy = identifier,
        x = lc.x,
        y = lc.y,
        z = lc.z,
    })

    if not ok and ret ~= 'spawnZombies_capped' then
        MRD9.Log('fiction dispatch failed lootId=%s tag=%s reason=%s', lootId, fictionTag, tostring(ret))
    end

    return { ok = true, triggered = true }
end

lib.callback.register('jp-meridian9:loot:fictionApproach', function(source, lootId)
    return runFictionApproach(source, lootId)
end)

RegisterNetEvent('jp-meridian9:server:fictionZombieKilled', function(payload)
    local src = source
    if type(src) ~= 'number' or src <= 0 or type(payload) ~= 'table' then
        return
    end
    local sessionId = payload.sessionId
    if type(sessionId) ~= 'string' or sessionId == '' then
        return
    end
    local session = MRD9.Session.Get(sessionId)
    if not session then
        return
    end
    local memberOk = false
    for _, m in ipairs(session.members or {}) do
        if m == src then
            memberOk = true
            break
        end
    end
    if not memberOk then
        return
    end
    local alive = tonumber(session.fictionAliveCount) or 0
    if alive > 0 then
        session.fictionAliveCount = alive - 1
    end
end)