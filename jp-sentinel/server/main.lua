local JB = Config._JpSentinel.JobBridge
local Inv = Config._JpSentinel.InventoryBridge
local Cooldown = Config._JpSentinel.Cooldown
local Tracker = Config._JpSentinel.Tracker

local ActiveSentinels = {}
Config._JpSentinel.ActiveSentinels = ActiveSentinels

---@type table<integer, { fromItem: boolean }>
local PendingThrow = {}

local nextSentinelId = 0

local function genSentinelId()
    nextSentinelId = nextSentinelId + 1
    return ('sn_%d_%d'):format(os.time(), nextSentinelId)
end

local function primaryIdentifier(src)
    local steam = nil
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:sub(1, 8) == 'license:' then
            return id
        end
        if id:sub(1, 6) == 'steam:' then
            steam = steam or id
        end
    end
    return steam or GetPlayerIdentifier(src, 0) or ('player:%s'):format(src)
end

local function hasActiveSentinelForThrower(src)
    for _, s in pairs(ActiveSentinels) do
        if s.throwerSrc == src then
            return true
        end
    end
    return false
end

---@param sentinelId string
---@param reason string
---@param throwerSrc number|nil
local function broadcastEnded(sentinelId, reason, throwerSrc)
    local payload = {
        sentinelId = sentinelId,
        reason = reason,
    }
    for _, pid in ipairs(JB.GetAllPoliceSources()) do
        TriggerClientEvent('jp-sentinel:client:trackingEnded', pid, payload)
    end
    if throwerSrc then
        TriggerClientEvent('jp-sentinel:client:trackingEnded', throwerSrc, payload)
    end
end

---@param sentinelId string
---@param reason string
local function finalizeSentinel(sentinelId, reason)
    local s = ActiveSentinels[sentinelId]
    if not s then
        return
    end
    local thrower = s.throwerSrc
    Tracker.Stop(sentinelId)
    ActiveSentinels[sentinelId] = nil
    broadcastEnded(sentinelId, reason, thrower)
end

---@param src number
---@param fromItem boolean
---@return boolean ok allowThrow を送れたとき true（ox_inventory では false で使用キャンセル）
local function handleRequestThrow(src, fromItem)
    if not JB.IsPolice(src) then
        Config.Notify(src, Config.Lang('not_police'), 'error')
        return false
    end
    if hasActiveSentinelForThrower(src) then
        Config.Notify(src, Config.Lang('already_active'), 'error')
        return false
    end
    if PendingThrow[src] then
        TriggerClientEvent('jp-sentinel:client:denyThrow', src, { reason = 'busy', remain = 0 })
        return false
    end

    local ident = primaryIdentifier(src)
    local okCd, remain = Cooldown.Check(ident)
    if not okCd then
        TriggerClientEvent('jp-sentinel:client:denyThrow', src, { reason = 'cooldown', remain = remain })
        return false
    end

    PendingThrow[src] = { fromItem = fromItem and true or false }
    TriggerClientEvent('jp-sentinel:client:allowThrow', src)
    return true
end

--- ox_inventory の data/items.lua で server.export = 'jp-sentinel.useSentinelBall' としたときに呼ばれる
exports('useSentinelBall', function(event, _item, inventory, _slot, _data)
    if event ~= 'usingItem' then
        return
    end
    local src = tonumber(inventory.id) or inventory.id
    if type(src) ~= 'number' then
        return false
    end
    if not handleRequestThrow(src, true) then
        return false
    end
end)

local function registerItemUsable()
    Inv.RegisterUsable(Config.ItemName, function(source)
        handleRequestThrow(source, true)
    end)
end

CreateThread(function()
    Wait(500)
    registerItemUsable()
end)

RegisterNetEvent('jp-sentinel:server:requestThrow', function(fromItem)
    handleRequestThrow(source, fromItem and true or false)
end)

RegisterNetEvent('jp-sentinel:server:reportMiss', function()
    local src = source
    local p = PendingThrow[src]
    if not p then
        return
    end
    if not JB.IsPolice(src) then
        PendingThrow[src] = nil
        return
    end
    PendingThrow[src] = nil
    if p.fromItem then
        Inv.RemoveItem(src, Config.ItemName, 1)
    end
end)

RegisterNetEvent('jp-sentinel:server:reportHit', function(data)
    local src = source
    local p = PendingThrow[src]
    if not p then
        TriggerClientEvent('jp-sentinel:client:abortDrone', src)
        return
    end
    if not JB.IsPolice(src) then
        PendingThrow[src] = nil
        TriggerClientEvent('jp-sentinel:client:abortDrone', src)
        return
    end

    if type(data) ~= 'table' or type(data.targetNetId) ~= 'number' or type(data.droneNetId) ~= 'number' then
        PendingThrow[src] = nil
        TriggerClientEvent('jp-sentinel:client:abortDrone', src)
        return
    end

    local hitCoords = data.hitCoords
    if type(hitCoords) == 'table' then
        hitCoords = vector3(tonumber(hitCoords.x) or 0.0, tonumber(hitCoords.y) or 0.0, tonumber(hitCoords.z) or 0.0)
    elseif hitCoords == nil then
        hitCoords = vector3(0.0, 0.0, 0.0)
    end

    PendingThrow[src] = nil

    if p.fromItem then
        Inv.RemoveItem(src, Config.ItemName, 1)
    end

    local ident = primaryIdentifier(src)
    Cooldown.Stamp(ident)

    local id = genSentinelId()
    local targetSrc = nil
    if type(data.targetServerId) == 'number' then
        targetSrc = data.targetServerId
    end

    ActiveSentinels[id] = {
        throwerSrc = src,
        throwerIdent = ident,
        targetSrc = targetSrc,
        targetNetId = data.targetNetId,
        droneNetId = data.droneNetId,
        startTime = os.time(),
        endTime = os.time() + Config.TrackDuration,
        lastCoords = hitCoords,
        lastIndoor = false,
        status = 'active',
    }

    Tracker.Start(id)

    TriggerClientEvent('jp-sentinel:client:trackingStarted', src, {
        sentinelId = id,
        endTime = ActiveSentinels[id].endTime,
    })

    Config.Notify(src, Config.Lang('throw_hit'), 'success')
    Config.Notify(src, Config.Lang('police_alert_active'), 'info')
end)

RegisterNetEvent('jp-sentinel:server:updateCoords', function(data)
    local src = source
    if type(data) ~= 'table' or type(data.sentinelId) ~= 'string' then
        return
    end
    local s = ActiveSentinels[data.sentinelId]
    if not s or s.throwerSrc ~= src then
        return
    end
    local c = data.coords
    if type(c) == 'table' then
        s.lastCoords = vector3(tonumber(c.x) or 0.0, tonumber(c.y) or 0.0, tonumber(c.z) or 0.0)
    end
    if data.indoor ~= nil then
        s.lastIndoor = data.indoor and true or false
    end
end)

RegisterNetEvent('jp-sentinel:server:relayFxFromPolice', function(data)
    local src = source
    if not JB.IsPolice(src) then
        return
    end
    if type(data) ~= 'table' or type(data.coords) ~= 'table' then
        return
    end
    local c = data.coords
    TriggerClientEvent('jp-sentinel:client:playFx', -1, {
        fxType = data.fxType,
        coords = vector3(tonumber(c.x) or 0.0, tonumber(c.y) or 0.0, tonumber(c.z) or 0.0),
    })
end)

RegisterNetEvent('jp-sentinel:server:broadcastFx', function(data)
    local src = source
    if type(data) ~= 'table' or type(data.sentinelId) ~= 'string' then
        return
    end
    local s = ActiveSentinels[data.sentinelId]
    if not s or s.throwerSrc ~= src then
        return
    end
    local c = data.coords
    if type(c) ~= 'table' then
        return
    end
    TriggerClientEvent('jp-sentinel:client:playFx', -1, {
        fxType = data.fxType,
        coords = vector3(tonumber(c.x) or 0.0, tonumber(c.y) or 0.0, tonumber(c.z) or 0.0),
    })
end)

RegisterNetEvent('jp-sentinel:server:reportExpired', function(data)
    local src = source
    if type(data) ~= 'table' or type(data.sentinelId) ~= 'string' then
        return
    end
    local s = ActiveSentinels[data.sentinelId]
    if not s or s.throwerSrc ~= src then
        return
    end
    finalizeSentinel(data.sentinelId, 'expired')
end)

RegisterNetEvent('jp-sentinel:server:reportShotDown', function(data)
    local src = source
    if type(data) ~= 'table' or type(data.sentinelId) ~= 'string' then
        return
    end
    local s = ActiveSentinels[data.sentinelId]
    if not s or s.throwerSrc ~= src then
        return
    end

    local thrower = s.throwerSrc

    local c = data.lostCoords
    local coords = vector3(0.0, 0.0, 0.0)
    if type(c) == 'table' then
        coords = vector3(tonumber(c.x) or 0.0, tonumber(c.y) or 0.0, tonumber(c.z) or 0.0)
    end

    Tracker.Stop(data.sentinelId)
    ActiveSentinels[data.sentinelId] = nil
    broadcastEnded(data.sentinelId, 'shotdown', thrower)

    local police = JB.GetAllPoliceSources()
    for _, pid in ipairs(police) do
        TriggerClientEvent('jp-sentinel:client:showLostBlip', pid, { coords = coords })
    end
end)

RegisterNetEvent('jp-sentinel:server:reportLost', function(data)
    local src = source
    if type(data) ~= 'table' or type(data.sentinelId) ~= 'string' then
        return
    end
    local s = ActiveSentinels[data.sentinelId]
    if not s or s.throwerSrc ~= src then
        return
    end

    local thrower = s.throwerSrc
    Tracker.Stop(data.sentinelId)
    ActiveSentinels[data.sentinelId] = nil
    broadcastEnded(data.sentinelId, 'lost', thrower)
end)

RegisterNetEvent('jp-sentinel:server:requestActive', function()
    local src = source
    if not JB.IsPolice(src) then
        return
    end
    local list = {}
    for id, s in pairs(ActiveSentinels) do
        list[#list + 1] = {
            sentinelId = id,
            coords = s.lastCoords,
            endTime = s.endTime,
            indoor = s.lastIndoor or false,
        }
    end
    TriggerClientEvent('jp-sentinel:client:syncActive', src, list)
end)

AddEventHandler('playerDropped', function()
    local src = source
    PendingThrow[src] = nil
    local toEnd = {}
    for id, s in pairs(ActiveSentinels) do
        if s.throwerSrc == src or (s.targetSrc and s.targetSrc == src) then
            toEnd[#toEnd + 1] = id
        end
    end
    for _, id in ipairs(toEnd) do
        finalizeSentinel(id, 'disconnect')
    end
end)
