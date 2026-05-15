-- ============================================================
-- jp-meridian9 / client/loot.lua
-- ============================================================
-- ルート: リーダーがプロップ生成、全員が ox_target で取得。
-- ============================================================

MRD9 = MRD9 or {}

local resName = GetCurrentResourceName()

local State = {
    byLootId = {},
    markerRunning = false,
    blips = {},  -- [lootId] = blipHandle
}

---@param b integer|nil
---@return nil
local function removeBlipSafe(b)
    if b and DoesBlipExist(b) then
        RemoveBlip(b)
    end
    return nil
end

---@param lootId string
---@param ent integer
local function addLootBlip(lootId, ent)
    if not ent or ent == 0 or not DoesEntityExist(ent) then
        return
    end
    if State.blips[lootId] then
        State.blips[lootId] = removeBlipSafe(State.blips[lootId])
    end
    local b = AddBlipForEntity(ent)
    SetBlipSprite(b, 478)   -- 箱（Crate）
    SetBlipColour(b, 5)     -- 黄
    SetBlipScale(b, 0.7)
    SetBlipAsShortRange(b, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(_('loot_pickup_label'))
    EndTextCommandSetBlipName(b)
    State.blips[lootId] = b
end

---@param lootId string
local function removeLootBlip(lootId)
    State.blips[lootId] = removeBlipSafe(State.blips[lootId])
end

-- アイテム位置に黄色いサークルマーカーを描画する。
-- プレイヤーから 60m 以内の loot のみ描画してパフォーマンス維持。
local function startLootMarkerLoop()
    if State.markerRunning then
        return
    end
    State.markerRunning = true
    CreateThread(function()
        while State.markerRunning and MRD9.CurrentSession do
            local ped = PlayerPedId()
            if ped and ped ~= 0 then
                local pc = GetEntityCoords(ped)
                for lootId, row in pairs(State.byLootId) do
                    local ent = NetworkGetEntityFromNetworkId(row.netId)
                    if ent and ent ~= 0 and DoesEntityExist(ent) then
                        local ec = GetEntityCoords(ent)
                        local d = #(pc - ec)
                        if d < 150.0 then
                            -- タイプ 1: 円柱マーカー、足元（地面少し上）に黄色
                            DrawMarker(
                                1,
                                ec.x + 0.0, ec.y + 0.0, ec.z - 0.95,
                                0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                                0.7, 0.7, 0.9,
                                240, 210, 30, 150,
                                false, false, 2, false, nil, nil, false
                            )
                        end
                    end
                end
            end
            Wait(0)
        end
        State.markerRunning = false
    end)
end

---@param lootId string
---@return string
local function optionName(lootId)
    return ('jp_m9_loot_%s'):format(lootId)
end

---@param netId integer
---@param timeoutMs integer
---@return integer
local function waitNetEntity(netId, timeoutMs)
    local deadline = GetGameTimer() + timeoutMs
    while GetGameTimer() < deadline do
        local ent = NetworkGetEntityFromNetworkId(netId)
        if ent and ent ~= 0 and DoesEntityExist(ent) then
            return ent
        end
        Wait(0)
    end
    return 0
end

---@param lootId string
local function removeOne(lootId)
    local row = State.byLootId[lootId]
    if not row then
        return
    end
    removeLootBlip(lootId)
    local netId = row.netId
    pcall(function()
        exports.ox_target:removeEntity(netId, row.optName)
    end)
    local ent = NetworkGetEntityFromNetworkId(netId)
    if ent and ent ~= 0 and DoesEntityExist(ent) then
        NetworkRequestControlOfEntity(ent)
        local t = GetGameTimer()
        while not NetworkHasControlOfEntity(ent) and GetGameTimer() - t < 800 do
            Wait(0)
        end
        SetEntityAsMissionEntity(ent, true, true)
        DeleteEntity(ent)
    end
    State.byLootId[lootId] = nil
end

---@param reason string|nil
---@return string
local function errMsg(reason)
    local r = tostring(reason or 'unknown')
    local key = 'loot_err_' .. r
    local msg = _(key)
    if msg == key then
        return _('loot_err_unknown')
    end
    return msg
end

RegisterNetEvent('jp-meridian9:client:lootSpawnBatch', function(data)
    if type(data) ~= 'table' or type(data.sessionId) ~= 'string' or type(data.loot) ~= 'table' then
        return
    end
    local props = {}
    for _, row in ipairs(data.loot) do
        local modelName = row.model
        if type(modelName) == 'string' and modelName ~= '' then
            local model = joaat(modelName)
            if IsModelInCdimage(model) and IsModelValid(model) then
                RequestModel(model)
                local dl = GetGameTimer() + 8000
                while not HasModelLoaded(model) do
                    if GetGameTimer() > dl then
                        break
                    end
                    Wait(0)
                end
                if HasModelLoaded(model) then
                    local x, y, z = tonumber(row.x), tonumber(row.y), tonumber(row.z)
                    if x and y and z then
                        local obj = CreateObject(model, x, y, z, true, true, false)
                        SetModelAsNoLongerNeeded(model)
                        if obj and obj ~= 0 then
                            SetEntityAsMissionEntity(obj, true, true)
                            PlaceObjectOnGroundProperly(obj)
                            local netId = NetworkGetNetworkIdFromEntity(obj)
                            if netId and netId ~= 0 then
                                SetNetworkIdExistsOnAllMachines(netId, true)
                                SetNetworkIdCanMigrate(netId, true)
                                props[#props + 1] = { lootId = row.lootId, netId = netId }
                            end
                        end
                    end
                end
            end
        end
        Wait(0)
    end
    TriggerServerEvent('jp-meridian9:server:lootSpawnAck', { sessionId = data.sessionId, props = props })
end)

RegisterNetEvent('jp-meridian9:client:lootRegister', function(data)
    if type(data) ~= 'table' or type(data.entries) ~= 'table' then
        return
    end
    startLootMarkerLoop()
    CreateThread(function()
        for _, e in ipairs(data.entries) do
            local netId = e.netId
            local lootId = e.lootId
            if type(netId) == 'number' and type(lootId) == 'string' then
                if State.byLootId[lootId] then
                    removeOne(lootId)
                end
                local ent = waitNetEntity(netId, 10000)
                if ent ~= 0 then
                    local oname = optionName(lootId)
                    local ok, err = pcall(function()
                        exports.ox_target:addEntity(netId, {
                            {
                                name = oname,
                                icon = 'fas fa-box',
                                label = _('loot_pickup_label'),
                                distance = 2.2,
                                onSelect = function()
                                    local res = lib.callback.await('jp-meridian9:loot:pickup', false, lootId)
                                    if type(res) == 'table' and res.ok then
                                        lib.notify({
                                            type = 'success',
                                            description = _('loot_pickup_ok', res.name or res.itemId, res.count or 1),
                                        })
                                    elseif type(res) == 'table' then
                                        lib.notify({
                                            type = 'error',
                                            description = errMsg(res.reason),
                                        })
                                    end
                                end,
                            },
                        })
                    end)
                    if ok then
                        State.byLootId[lootId] = { netId = netId, optName = oname }
                        addLootBlip(lootId, ent)
                    elseif Config.Debug then
                        print(('[jp-meridian9] ox_target addEntity failed: %s'):format(tostring(err)))
                    end
                end
            end
            Wait(0)
        end
    end)
end)

RegisterNetEvent('jp-meridian9:client:lootRemoved', function(data)
    if type(data) ~= 'table' or type(data.lootId) ~= 'string' then
        return
    end
    removeOne(data.lootId)
end)

RegisterNetEvent('jp-meridian9:client:lootClearAll', function()
    State.markerRunning = false
    for lootId in pairs(State.byLootId) do
        removeOne(lootId)
    end
    for lootId in pairs(State.blips) do
        removeLootBlip(lootId)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= resName then
        return
    end
    State.markerRunning = false
    for lootId in pairs(State.byLootId) do
        removeOne(lootId)
    end
    for lootId in pairs(State.blips) do
        removeLootBlip(lootId)
    end
end)
