-- ============================================================
-- jp-meridian9 / server/loot.lua
-- ============================================================
-- セッション内ルート（サーバー権威・メモリのみ）。
-- ============================================================

MRD9 = MRD9 or {}
MRD9.Loot = MRD9.Loot or {}

local lastPickupMs = {}

---@param session table
---@return boolean
local function sessionAllowsLoot(session)
    return session and session.state == 'IN_MISSION'
end

---@param itemId string
---@return table|nil
local function findItemDef(itemId)
    for _, it in ipairs(Config.Items or {}) do
        if it.id == itemId then
            return it
        end
    end
    return nil
end

---@param def table|nil
---@return string
local function propModelForItem(def)
    local d = def and def.propModel
    if type(d) == 'string' and d ~= '' then
        return d
    end
    local cfg = Config.Loot
    return (cfg and cfg.defaultPropModel) or 'prop_paper_bag_01'
end

---@param weights table|nil
---@return string
local function rollRarity(weights)
    local w = weights
    if type(w) ~= 'table' or not next(w) then
        w = Config.LootRarityWeight or { common = 70 }
    end
    local total = 0
    for _, v in pairs(w) do
        if type(v) == 'number' and v > 0 then
            total = total + v
        end
    end
    if total <= 0 then
        return 'common'
    end
    local r = math.random() * total
    local cum = 0.0
    for tier, v in pairs(w) do
        if type(v) == 'number' and v > 0 then
            cum = cum + v
            if r <= cum then
                return type(tier) == 'string' and tier or 'common'
            end
        end
    end
    return 'common'
end

---@param tier string
---@return table|nil
local function pickItemForRarity(tier)
    local pool = {}
    for _, it in ipairs(Config.Items or {}) do
        if it.rarity == tier then
            pool[#pool + 1] = it
        end
    end
    if #pool == 0 then
        if tier ~= 'common' then
            return pickItemForRarity('common')
        end
        return nil
    end
    return pool[math.random(1, #pool)]
end

---@param center vector3|{ x: number, y: number, z: number }
---@param minR number
---@param maxR number
---@param existing vector3[]
---@param minGap number
---@param maxAttempts integer
---@return vector3|nil
local function pickRadialLootCoords(center, minR, maxR, existing, minGap, maxAttempts)
    local cx, cy, cz = center.x + 0.0, center.y + 0.0, center.z + 0.0
    for _ = 1, maxAttempts do
        local ang = math.random() * math.pi * 2
        local dist = minR + math.random() * (maxR - minR)
        local x = cx + math.cos(ang) * dist
        local y = cy + math.sin(ang) * dist
        local z = cz + 80.0
        local found, gz = GetGroundZFor_3dCoord(x + 0.0, y + 0.0, z + 0.0, false)
        if not found or not gz then
            gz = cz
        end
        local p = vector3(x, y, (gz or cz) + 0.12)
        local ok = true
        for _, q in ipairs(existing) do
            if #(p - q) < minGap then
                ok = false
                break
            end
        end
        if ok then
            return p
        end
    end
    return nil
end

---@param center vector3|{ x: number, y: number, z: number }
---@param count integer
---@return vector3[], table[] @positions, spawnMeta (weight source per index)
local function buildLootLayout(center, count)
    local positions = {}
    local meta = {}
    local fixed = Config.LootSpawns
    if type(fixed) == 'table' and #fixed > 0 and fixed[1] and fixed[1].coords then
        for i = 1, count do
            local slot = fixed[math.random(1, #fixed)]
            local c = slot.coords
            local p = vector3(c.x + 0.0, c.y + 0.0, c.z + 0.0)
            positions[#positions + 1] = p
            meta[#meta + 1] = { weight = slot.weight }
        end
        return positions, meta
    end

    local cfg = Config.Loot or {}
    local maxR = tonumber(cfg.spawnAreaRadius) or 50.0
    local minR = math.min(3.0, maxR * 0.08)
    local minGap = tonumber(cfg.minDistanceBetween) or 4.0
    local attempts = tonumber(cfg.spawnPlacementAttempts) or 28
    for _ = 1, count do
        local p = pickRadialLootCoords(center, minR, maxR, positions, minGap, attempts)
        if not p then
            break
        end
        positions[#positions + 1] = p
        meta[#meta + 1] = { weight = nil }
    end
    return positions, meta
end

---@param sessionId string|nil
function MRD9.Loot.Spawn(sessionId)
    if not sessionId or not Config.Loot or Config.Loot.enabled == false then
        return
    end
    local session = MRD9.Session.Get(sessionId)
    if not session or not sessionAllowsLoot(session) then
        return
    end

    if session.loot and next(session.loot) then
        MRD9.Loot.Cleanup(sessionId)
    end

    local sp = Config.Mission.spawnPoint
    if not sp then
        return
    end
    local center = vector3(sp.x + 0.0, sp.y + 0.0, sp.z + 0.0)
    local maxN = math.floor(math.max(1, tonumber(Config.Loot.maxPerSession) or 24))

    local positions, meta = buildLootLayout(center, maxN)
    if #positions == 0 then
        MRD9.Log('Loot.Spawn: no positions session=%s', sessionId)
        return
    end

    local lootMap = {}
    local batch = {}
    for i, p in ipairs(positions) do
        local tier = rollRarity(meta[i] and meta[i].weight)
        local def = pickItemForRarity(tier)
        if def then
            local lootId = ('L_%s_%d'):format(sessionId, i)
            lootMap[lootId] = {
                itemId = def.id,
                coords = p,
                picked = false,
                propNetId = nil,
            }
            batch[#batch + 1] = {
                lootId = lootId,
                model = propModelForItem(def),
                x = p.x,
                y = p.y,
                z = p.z,
                itemId = def.id,
                itemName = def.name or def.id,
            }
        end
    end

    session.loot = lootMap
    if #batch == 0 then
        return
    end

    TriggerClientEvent('jp-meridian9:client:lootSpawnBatch', session.leader, {
        sessionId = sessionId,
        loot = batch,
    })
    MRD9.Log('Loot.Spawn: session=%s count=%d leader=%d', sessionId, #batch, session.leader)
end

---@param sessionId string|nil
function MRD9.Loot.Cleanup(sessionId)
    local session = MRD9.Session.Get(sessionId)
    if session and session.members then
        for _, m in ipairs(session.members) do
            TriggerClientEvent('jp-meridian9:client:lootClearAll', m, {})
        end
    end
    if session then
        session.loot = nil
    end
    MRD9.Log('Loot.Cleanup session=%s', tostring(sessionId))
end

RegisterNetEvent('jp-meridian9:server:lootSpawnAck', function(data)
    local src = source
    if type(src) ~= 'number' or src <= 0 or type(data) ~= 'table' then
        return
    end
    local sessionId = data.sessionId
    if type(sessionId) ~= 'string' then
        return
    end
    local session = MRD9.Session.Get(sessionId)
    if not session or not sessionAllowsLoot(session) or src ~= session.leader then
        return
    end
    if type(session.loot) ~= 'table' then
        return
    end

    for _, row in ipairs(data.props or {}) do
        if type(row) == 'table' and type(row.lootId) == 'string' and type(row.netId) == 'number' then
            local slot = session.loot[row.lootId]
            if slot and not slot.picked then
                slot.propNetId = row.netId
            end
        end
    end

    local entries = {}
    for lootId, slot in pairs(session.loot) do
        if slot.propNetId and not slot.picked then
            entries[#entries + 1] = {
                lootId = lootId,
                netId = slot.propNetId,
                itemId = slot.itemId,
            }
        end
    end

    for _, m in ipairs(session.members) do
        TriggerClientEvent('jp-meridian9:client:lootRegister', m, {
            sessionId = sessionId,
            entries = entries,
        })
    end
end)

lib.callback.register('jp-meridian9:loot:pickup', function(source, lootId)
    local src = source
    if type(src) ~= 'number' or src <= 0 or type(lootId) ~= 'string' then
        return { ok = false, reason = 'invalid_args' }
    end

    local now = GetGameTimer()
    local cd = (Config.Loot and Config.Loot.cooldownMs) or 500
    if (lastPickupMs[src] or 0) + cd > now then
        return { ok = false, reason = 'cooldown' }
    end

    local session = MRD9.Session.GetByPlayer(src)
    if not session or not sessionAllowsLoot(session) then
        return { ok = false, reason = 'no_session' }
    end

    local memberOk = false
    for _, m in ipairs(session.members) do
        if m == src then
            memberOk = true
            break
        end
    end
    if not memberOk then
        return { ok = false, reason = 'not_member' }
    end

    local slot = session.loot and session.loot[lootId]
    if not slot or slot.picked then
        return { ok = false, reason = 'not_found' }
    end

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then
        return { ok = false, reason = 'no_ped' }
    end
    local pc = GetEntityCoords(ped)
    local lc = slot.coords
    local maxDist = (Config.Loot and Config.Loot.pickupRadius) or 3.0
    if #(pc - lc) > maxDist + 0.75 then
        return { ok = false, reason = 'too_far' }
    end

    local itemId = slot.itemId
    if type(itemId) ~= 'string' or not findItemDef(itemId) then
        return { ok = false, reason = 'bad_item' }
    end

    lastPickupMs[src] = now
    slot.picked = true

    session.inventory[src] = session.inventory[src] or {}
    local inv = session.inventory[src]
    inv[itemId] = (inv[itemId] or 0) + 1

    for _, m in ipairs(session.members) do
        TriggerClientEvent('jp-meridian9:client:lootRemoved', m, { lootId = lootId })
    end

    local def = findItemDef(itemId)
    if Config.Debug then
        print(('[jp-meridian9] loot pickup src=%d session=%s item=%s qty=%d'):format(src, session.id, itemId, inv[itemId]))
    end

    return {
        ok = true,
        itemId = itemId,
        name = def and def.name or itemId,
        count = inv[itemId],
    }
end)

AddEventHandler('playerDropped', function()
    local src = source
    if type(src) == 'number' and src > 0 then
        lastPickupMs[src] = nil
    end
end)

if Config.Debug then
    RegisterCommand('m9_loot_list', function(source)
        if source == 0 then
            return
        end
        local s = MRD9.Session.GetByPlayer(source)
        if not s or not s.loot then
            TriggerClientEvent('chat:addMessage', source, { args = { '[MRD9]', 'ルートなし' } })
            return
        end
        local n = 0
        for _ in pairs(s.loot) do
            n = n + 1
        end
        TriggerClientEvent('chat:addMessage', source, { args = { '[MRD9]', ('loot slots=%d'):format(n) } })
    end, false)
end
