-- ============================================================
-- jp-meridian9 / server/extract.lua
-- ============================================================
-- 脱出処理。距離・状態検証 → スナップショット保存 → RemovePlayer。
-- ============================================================

MRD9 = MRD9 or {}
MRD9.Extract = MRD9.Extract or {}

local lastExtractMs = {}

---@param session table
---@return boolean
local function sessionAllowsExtract(session)
    return session and session.state == 'IN_MISSION'
end

---@param session table
---@param src integer
---@return boolean
local function isMember(session, src)
    if not session or not session.members then
        return false
    end
    for _, m in ipairs(session.members) do
        if m == src then
            return true
        end
    end
    return false
end

---@param inv table|nil
---@return table
local function snapshotInventory(inv)
    if MRD9.FlattenMissionInventory then
        return MRD9.FlattenMissionInventory(inv)
    end
    local out = {}
    if type(inv) ~= 'table' then
        return out
    end
    for itemId, qty in pairs(inv) do
        if type(itemId) == 'string' and type(qty) == 'number' and qty > 0 then
            out[itemId] = qty
        end
    end
    return out
end

---@param session table
---@param src integer
local function recordExtractedSnapshot(session, src)
    session.extractedInventory = session.extractedInventory or {}
    local identifier = MRD9.GetIdentifier(src)
    if not identifier or identifier == '' then
        return
    end
    session.extractedInventory[identifier] = {
        identifier = identifier,
        src = src,
        items = snapshotInventory(session.inventory and session.inventory[src]),
        extractedAt = os.time(),
        sessionId = session.id,
    }
end

---@param session table
---@param src integer
---@param outcome string
---@param earningsOverride integer|nil
local function logMissionFor(session, src, outcome, earningsOverride)
    if not MRD9.Stats or not MRD9.Stats.LogMission then
        return
    end
    local identifier = MRD9.GetIdentifier(src)
    if not identifier or identifier == '' then
        return
    end
    local items = nil
    if session.extractedInventory and session.extractedInventory[identifier] then
        items = session.extractedInventory[identifier].items
    elseif session.inventory then
        items = snapshotInventory(session.inventory[src])
    end
    MRD9.Stats.LogMission(identifier, {
        sessionId = session.id,
        startedAt = session.startedAtIso,
        endedAt = os.date('%Y-%m-%d %H:%M:%S'),
        outcome = outcome,
        items = items,
        earnings = earningsOverride or 0,
        missionType = session.mission and session.mission.type or 'SAMPLE_RECOVERY',
        difficulty = session.mission and session.mission.difficulty or 'NORMAL',
    })
end

---@param sessionId string|nil
---@param destroyReason string|nil
function MRD9.Extract.OnSessionDestroy(sessionId, destroyReason)
    local session = MRD9.Session.Get(sessionId)
    if not session then
        return
    end
    local outcome = 'aborted'
    if destroyReason == 'timeout' then
        outcome = 'timeout'
    elseif destroyReason == 'arena_wiped' or destroyReason == 'all_lost' then
        outcome = 'died'
    elseif destroyReason == 'server_shutdown' then
        outcome = 'aborted'
    end
    local membersCopy = {}
    for _, m in ipairs(session.members or {}) do
        membersCopy[#membersCopy + 1] = m
    end
    for _, src in ipairs(membersCopy) do
        local identifier = MRD9.GetIdentifier(src)
        if identifier and identifier ~= '' then
            local alreadyExtracted = session.extractedInventory and session.extractedInventory[identifier]
            if not alreadyExtracted then
                logMissionFor(session, src, outcome)
            end
        end
    end
end

lib.callback.register('jp-meridian9:extract:request', function(source, pointIdx)
    local src = source
    if type(src) ~= 'number' or src <= 0 then
        return { ok = false, reason = 'invalid_args' }
    end
    if type(pointIdx) ~= 'number' then
        return { ok = false, reason = 'invalid_args' }
    end
    if not Config.Extract or Config.Extract.enabled == false then
        return { ok = false, reason = 'disabled' }
    end

    local now = GetGameTimer()
    local cd = (Config.Extract and Config.Extract.cooldownMs) or 1500
    if (lastExtractMs[src] or 0) + cd > now then
        return { ok = false, reason = 'cooldown' }
    end

    local session = MRD9.Session.GetByPlayer(src)
    if not session or not sessionAllowsExtract(session) then
        return { ok = false, reason = 'no_session' }
    end
    if not isMember(session, src) then
        return { ok = false, reason = 'not_member' }
    end

    local pt = Config.ExtractPoints and Config.ExtractPoints[pointIdx]
    if not pt or not pt.coords then
        return { ok = false, reason = 'bad_point' }
    end

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then
        return { ok = false, reason = 'no_ped' }
    end
    local pc = GetEntityCoords(ped)
    local pr = tonumber(pt.radius) or 3.0
    if #(pc - pt.coords) > pr + 1.0 then
        return { ok = false, reason = 'too_far' }
    end

    lastExtractMs[src] = now
    recordExtractedSnapshot(session, src)

    local finalizeEarnings = 0
    if MRD9.Result and MRD9.Result.Finalize then
        local okFin, info = MRD9.Result.Finalize(session, src)
        if okFin and type(info) == 'table' and type(info.total) == 'number' then
            finalizeEarnings = info.total
        end
    end

    logMissionFor(session, src, 'extracted', finalizeEarnings)

    if MRD9.Stats and MRD9.Stats.Update then
        local identifier = MRD9.GetIdentifier(src)
        if identifier and identifier ~= '' then
            local startedAt = session.startedAt or GetGameTimer()
            local elapsed = math.floor((GetGameTimer() - startedAt) / 1000)
            MRD9.Stats.Update(identifier, {
                extracted = true,
                died = false,
                earnings = finalizeEarnings,
                extractSeconds = elapsed > 0 and elapsed or nil,
            })
        end
    end

    MRD9.Session.RemovePlayer(src, 'extracted')

    return { ok = true }
end)

AddEventHandler('playerDropped', function()
    local src = source
    if type(src) == 'number' and src > 0 then
        lastExtractMs[src] = nil
    end
end)

if Config.Debug then
    RegisterCommand('m9_extract_here', function(source)
        if source == 0 then
            return
        end
        local s = MRD9.Session.GetByPlayer(source)
        if not s then
            TriggerClientEvent('chat:addMessage', source, { args = { '[MRD9]', 'セッション未所属' } })
            return
        end
        recordExtractedSnapshot(s, source)
        local finalizeEarnings = 0
        if MRD9.Result and MRD9.Result.Finalize then
            local okFin, info = MRD9.Result.Finalize(s, source)
            if okFin and type(info) == 'table' and type(info.total) == 'number' then
                finalizeEarnings = info.total
            end
        end
        logMissionFor(s, source, 'extracted', finalizeEarnings)
        if MRD9.Stats and MRD9.Stats.Update then
            local identifier = MRD9.GetIdentifier(source)
            if identifier and identifier ~= '' then
                local startedAt = s.startedAt or GetGameTimer()
                local elapsed = math.floor((GetGameTimer() - startedAt) / 1000)
                MRD9.Stats.Update(identifier, {
                    extracted = true,
                    died = false,
                    earnings = finalizeEarnings,
                    extractSeconds = elapsed > 0 and elapsed or nil,
                })
            end
        end
        MRD9.Session.RemovePlayer(source, 'extracted')
    end, false)
end
