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
    proximityRunning = false,
    textUiOpen = false,
    busy = false,
}

---@param reason string|nil
---@return string
local function errMsgFor(reason)
    local r = tostring(reason or 'unknown')
    local key = 'loot_err_' .. r
    local msg = _(key)
    if msg == key then
        return _('loot_err_unknown')
    end
    return msg
end

---@param res table|nil
---@return string
local function pickupLabelFromResult(res)
    if type(res) ~= 'table' then
        return ''
    end
    if type(res.nameKey) == 'string' and res.nameKey ~= '' then
        return _(res.nameKey)
    end
    return tostring(res.name or res.itemId or '')
end

local function hideLootUI()
    if State.textUiOpen then
        State.textUiOpen = false
        if lib and lib.hideTextUI then
            lib.hideTextUI()
        end
    end
end

-- 近接 + E キーで取得する代替ルート（ox_target の H 経由と並列）。
-- プレイヤー周辺 2m 以内の最も近い loot を対象にする。
local function startLootProximityLoop()
    if State.proximityRunning then
        return
    end
    State.proximityRunning = true
    CreateThread(function()
        while State.proximityRunning do
            local ped = PlayerPedId()
            if ped and ped ~= 0 then
                local pc = GetEntityCoords(ped)
                local bestLootId, bestDist = nil, math.huge
                for lootId, row in pairs(State.byLootId) do
                    local ent = row.cachedEnt
                    if not ent or ent == 0 or not DoesEntityExist(ent) then
                        ent = NetworkGetEntityFromNetworkId(row.netId)
                        row.cachedEnt = ent
                    end
                    local wc = nil
                    if ent and ent ~= 0 and DoesEntityExist(ent) then
                        wc = GetEntityCoords(ent)
                    elseif row.pendingCoord then
                        wc = row.pendingCoord
                    end
                    if wc then
                        local d = #(pc - wc)
                        if d <= 2.2 and d < bestDist then
                            bestLootId, bestDist = lootId, d
                        end
                    end
                end
                if bestLootId and not State.busy then
                    if not State.textUiOpen then
                        State.textUiOpen = true
                        local lc = Config.Loot or {}
                        lib.showTextUI('[E] ' .. _('loot_pickup_label'), {
                            position = lc.textUiPosition or 'right-center',
                            icon = 'box',
                            style = lc.textUiStyle
                                or {
                                    backgroundColor = '#2e7d32',
                                    color = '#f1f8e9',
                                    fontSize = '1.35em',
                                    padding = '10px 18px',
                                    borderRadius = '8px',
                                },
                        })
                    end
                    if IsControlJustReleased(0, 38) then
                        State.busy = true
                        hideLootUI()
                        local lootId = bestLootId
                        CreateThread(function()
                            local res = lib.callback.await('jp-meridian9:loot:pickup', false, lootId)
                            if type(res) == 'table' and res.ok then
                                lib.notify({
                                    type = 'success',
                                    description = _('loot_pickup_ok', pickupLabelFromResult(res), res.count or 1),
                                })
                            elseif type(res) == 'table' then
                                lib.notify({
                                    type = 'error',
                                    description = errMsgFor(res.reason),
                                })
                            end
                            State.busy = false
                        end)
                    end
                    Wait(0)
                else
                    if State.textUiOpen then
                        hideLootUI()
                    end
                    Wait(300)
                end
            else
                Wait(800)
            end
        end
        State.proximityRunning = false
        hideLootUI()
    end)
end

AddEventHandler('jp-meridian9:onMissionStart', function()
    startLootProximityLoop()
end)
RegisterNetEvent('jp-meridian9:onMissionStart', function()
    startLootProximityLoop()
end)
RegisterNetEvent('jp-meridian9:onMissionEnd', function()
    State.proximityRunning = false
    State.markerRunning = false
    hideLootUI()
end)

---@param b integer|nil
---@return nil
local function removeBlipSafe(b)
    if b and DoesBlipExist(b) then
        RemoveBlip(b)
    end
    return nil
end

---@param lootId string
---@param x number
---@param y number
---@param z number
local function addLootBlipAtCoord(lootId, x, y, z)
    if State.blips[lootId] then
        State.blips[lootId] = removeBlipSafe(State.blips[lootId])
    end
    local b = AddBlipForCoord(x + 0.0, y + 0.0, z + 0.0)
    SetBlipSprite(b, 408)
    SetBlipColour(b, 5)
    SetBlipScale(b, 0.85)
    SetBlipAsShortRange(b, false)
    SetBlipDisplay(b, 2)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(_('loot_pickup_label'))
    EndTextCommandSetBlipName(b)
    State.blips[lootId] = b
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
    SetBlipSprite(b, 408)         -- Crate（箱・宝箱風）
    SetBlipColour(b, 5)           -- 黄
    SetBlipScale(b, 0.85)
    SetBlipAsShortRange(b, false) -- 任務中は距離関係なくミニマップに常時表示
    SetBlipDisplay(b, 2)          -- ミニマップ + ESC マップ両方
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
        while State.markerRunning do
            local ped = PlayerPedId()
            if ped and ped ~= 0 then
                local pc = GetEntityCoords(ped)
                for lootId, row in pairs(State.byLootId) do
                    local ent = row.cachedEnt
                    if not ent or ent == 0 or not DoesEntityExist(ent) then
                        ent = NetworkGetEntityFromNetworkId(row.netId)
                        row.cachedEnt = ent
                    end
                    local ec = nil
                    if ent and ent ~= 0 and DoesEntityExist(ent) then
                        ec = GetEntityCoords(ent)
                    elseif row.pendingCoord then
                        ec = row.pendingCoord
                    end
                    if ec then
                        local d = #(pc - ec)
                        if row.fictionTag and row.fictionSpec and not row.fictionFired and not row._fictionPending then
                            local oa = row.fictionSpec.onApproach
                            local trig = tonumber(oa and oa.triggerDistance) or 20.0
                            if d <= trig + 1.0 then
                                row._fictionPending = true
                                local lid = lootId
                                CreateThread(function()
                                    local r = lib.callback.await('jp-meridian9:loot:fictionApproach', false, lid)
                                    if type(r) == 'table' and r.ok then
                                        row.fictionFired = true
                                    end
                                    row._fictionPending = false
                                end)
                            end
                        end
                        if d < 150.0 then
                            local lc = Config.Loot or {}
                            local zOff = tonumber(lc.markerCylinderZOffset) or 0.45
                            DrawMarker(
                                1,
                                ec.x + 0.0, ec.y + 0.0, ec.z + zOff,
                                0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                                0.7, 0.7, 0.85,
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

--- fictionTag 付きルートのブリップ見た目上書き（座標 blip／entity blip 共通）
---@param lootId string
---@param fictionSpec table|nil
local function applyFictionBlipStyle(lootId, fictionSpec)
    if not fictionSpec or type(fictionSpec.blip) ~= 'table' then
        return
    end
    local blip = State.blips[lootId]
    if not blip or not DoesBlipExist(blip) then
        return
    end
    local b = fictionSpec.blip
    if tonumber(b.sprite) then
        SetBlipSprite(blip, math.floor(tonumber(b.sprite)))
    end
    if tonumber(b.color) then
        SetBlipColour(blip, math.floor(tonumber(b.color)))
    end
    if tonumber(b.scale) then
        SetBlipScale(blip, tonumber(b.scale) + 0.0)
    end
    if b.flashing == true then
        SetBlipFlashes(blip, true)
    end
    if type(b.label) == 'string' and b.label ~= '' then
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(b.label)
        EndTextCommandSetBlipName(blip)
    end
end

--- 1 件のルート登録（並列スレッドから呼ぶ。MAP は即座標 blip、entity ストリーミング後に差し替え）
---@param e table
local function registerLootEntry(e)
    local netId = e.netId
    local lootId = e.lootId
    if type(netId) ~= 'number' or type(lootId) ~= 'string' then
        return
    end

    if State.byLootId[lootId] then
        removeOne(lootId)
    end

    local oname = optionName(lootId)
    local fictionTag = type(e.fictionTag) == 'string' and e.fictionTag ~= '' and e.fictionTag or nil
    local fictionSpec = fictionTag and Config.FictionTags and Config.FictionTags[fictionTag] or nil

    local px, py, pz = tonumber(e.x), tonumber(e.y), tonumber(e.z)
    local pendingCoord = (px and py and pz) and vector3(px + 0.0, py + 0.0, pz + 0.0) or nil

    State.byLootId[lootId] = {
        netId = netId,
        optName = oname,
        cachedEnt = nil,
        fictionTag = fictionTag,
        fictionSpec = fictionSpec,
        fictionFired = false,
        pendingCoord = pendingCoord,
    }

    if pendingCoord then
        addLootBlipAtCoord(lootId, pendingCoord.x, pendingCoord.y, pendingCoord.z)
        applyFictionBlipStyle(lootId, fictionSpec)
    end

    local ent = waitNetEntity(netId, 45000)
    local row = State.byLootId[lootId]
    if not row then
        return
    end

    if ent ~= 0 then
        row.cachedEnt = ent
        row.pendingCoord = nil
        removeLootBlip(lootId)
        addLootBlip(lootId, ent)
        applyFictionBlipStyle(lootId, fictionSpec)

        local targetLabel = _('loot_pickup_label')
        if fictionSpec and type(fictionSpec.targetLabel) == 'string' and fictionSpec.targetLabel ~= '' then
            targetLabel = fictionSpec.targetLabel
        end
        local ok, err = pcall(function()
            exports.ox_target:addLocalEntity(ent, {
                {
                    name = oname,
                    icon = 'fas fa-box',
                    label = targetLabel,
                    distance = 2.2,
                    onSelect = function()
                        local res = lib.callback.await('jp-meridian9:loot:pickup', false, lootId)
                        if type(res) == 'table' and res.ok then
                            lib.notify({
                                type = 'success',
                                description = _('loot_pickup_ok', pickupLabelFromResult(res), res.count or 1),
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
        if not ok and Config.Debug then
            print(('[jp-meridian9] ox_target addLocalEntity failed: %s'):format(tostring(err)))
        end
    elseif Config.Debug then
        print(('[jp-meridian9] lootRegister: waitNetEntity timeout lootId=%s netId=%d (coord blip のみ維持)'):format(lootId, netId))
    end
end

---@param lootId string
local function removeOne(lootId)
    local row = State.byLootId[lootId]
    if not row then
        return
    end
    removeLootBlip(lootId)
    local netId = row.netId
    local ent = row.cachedEnt
    if not ent or ent == 0 or not DoesEntityExist(ent) then
        ent = NetworkGetEntityFromNetworkId(netId)
    end
    if ent and ent ~= 0 and DoesEntityExist(ent) then
        pcall(function()
            exports.ox_target:removeLocalEntity(ent)
        end)
    else
        pcall(function()
            exports.ox_target:removeEntity(netId, row.optName)
        end)
    end
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

-- Cayo 等でコリジョン未ロードのとき PlaceObjectOnGroundProperly が空中の誤上面へ乗ることがあるため、
-- 高さから地面 Z を引き、Create 後に SetEntityCoordsNoOffset で確定する。
-- **ルート prop は `lootSpawnBatch` の全件が本関数経由**（サーバーから届いた x,y,z ごとに 1 回）。
-- zHint（config）は実機で立った足元を入れる想定。探査結果がヒントから大きく外れたら誤検出とみなしヒントを使う。
---@param x number
---@param y number
---@param zHint number
---@param opts { deadlineMs?: number }|nil 省略時 3500ms。バッチは `batchGroundResolveMs` を渡す。
---@return number
local function resolveLootGroundZ(x, y, zHint, opts)
    local zh = zHint + 0.0
    local deadlineMs = 3500
    if type(opts) == 'table' then
        local d = tonumber(opts.deadlineMs)
        if d and d >= 50.0 and d <= 8000.0 then
            deadlineMs = math.floor(d + 0.5)
        end
    end
    RequestCollisionAtCoord(x, y, zh)
    -- ヒント付近から先に探すと、海上で遠方の島コリジョンに吸われるのを減らせる
    local probes = { math.max(zh + 95.0, 120.0), math.max(zh + 220.0, 380.0), 520.0 }
    local maxDelta = 92.0
    local deadline = GetGameTimer() + deadlineMs
    while GetGameTimer() < deadline do
        for _, probeZ in ipairs(probes) do
            local ok, gz = GetGroundZFor_3dCoord(x + 0.0, y + 0.0, probeZ + 0.0, false)
            if ok and gz and gz > -120.0 and gz < 900.0 and math.abs(gz - zh) <= maxDelta then
                return gz + 0.1
            end
        end
        RequestCollisionAtCoord(x, y, zh + 40.0)
        Wait(0)
    end
    return zh
end

RegisterNetEvent('jp-meridian9:client:lootSpawnBatch', function(data)
    if type(data) ~= 'table' or type(data.sessionId) ~= 'string' or type(data.loot) ~= 'table' then
        return
    end
    if Config.Debug then
        print(('[jp-meridian9] lootSpawnBatch received: session=%s count=%d'):format(data.sessionId, #data.loot))
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
                        local cfgL = Config.Loot or {}
                        local batchMs = tonumber(cfgL.batchGroundResolveMs)
                        if not batchMs or batchMs < 50.0 then
                            batchMs = 700.0
                        end
                        local placeZ = resolveLootGroundZ(x, y, z, { deadlineMs = batchMs })
                        local obj = CreateObject(model, x, y, placeZ + 0.35, true, true, false)
                        SetModelAsNoLongerNeeded(model)
                        if obj and obj ~= 0 then
                            if not NetworkGetEntityIsNetworked(obj) then
                                NetworkRegisterEntityAsNetworked(obj)
                            end
                            local netReadyDeadline = GetGameTimer() + 2000
                            while not NetworkGetEntityIsNetworked(obj) and GetGameTimer() < netReadyDeadline do
                                Wait(0)
                            end

                            SetEntityAsMissionEntity(obj, true, true)
                            SetEntityCoordsNoOffset(obj, x + 0.0, y + 0.0, placeZ + 0.08, false, false, false)
                            -- ネットワーク化後に再度地面を取り直し（ストリーミング遅延対策）
                            local ok2, gz2 = GetGroundZFor_3dCoord(x + 0.0, y + 0.0, placeZ + 120.0, false)
                            if ok2 and gz2 and gz2 > -120.0 and gz2 < 900.0 and math.abs(gz2 - placeZ) <= 92.0 then
                                SetEntityCoordsNoOffset(obj, x + 0.0, y + 0.0, gz2 + 0.08, false, false, false)
                            end
                            FreezeEntityPosition(obj, true)

                            -- Freeze のあと再度 net 化が確定するまで待つ（未 network で
                            -- NetworkGetNetworkIdFromEntity を呼ぶと F8 に no net object 警告が出る）
                            local netId = 0
                            local idDeadline = GetGameTimer() + 5000
                            while GetGameTimer() < idDeadline do
                                if DoesEntityExist(obj) and NetworkGetEntityIsNetworked(obj) then
                                    netId = NetworkGetNetworkIdFromEntity(obj)
                                    if netId and netId ~= 0 then
                                        break
                                    end
                                elseif not DoesEntityExist(obj) then
                                    break
                                end
                                Wait(0)
                            end
                            if netId and netId ~= 0 then
                                SetNetworkIdExistsOnAllMachines(netId, true)
                                SetNetworkIdCanMigrate(netId, false)
                                local wc = GetEntityCoords(obj)
                                props[#props + 1] = {
                                    lootId = row.lootId,
                                    netId = netId,
                                    x = wc.x,
                                    y = wc.y,
                                    z = wc.z,
                                }
                                if Config.Debug then
                                    print(('[jp-meridian9] loot prop created: lootId=%s netId=%d'):format(row.lootId, netId))
                                end
                            else
                                if Config.Debug then
                                    print(('[jp-meridian9] loot prop netId=0 lootId=%s (skip)'):format(row.lootId))
                                end
                                SetEntityAsMissionEntity(obj, true, true)
                                DeleteEntity(obj)
                            end
                        end
                    end
                end
            end
        end
        Wait(0)
    end
    if Config.Debug then
        print(('[jp-meridian9] lootSpawnAck sending: session=%s count=%d'):format(data.sessionId, #props))
    end
    TriggerServerEvent('jp-meridian9:server:lootSpawnAck', { sessionId = data.sessionId, props = props })
end)

RegisterNetEvent('jp-meridian9:client:lootRegister', function(data)
    if type(data) ~= 'table' or type(data.entries) ~= 'table' then
        return
    end
    if Config.Debug then
        print(('[jp-meridian9] lootRegister received: entries=%d'):format(#data.entries))
    end
    startLootMarkerLoop()
    for i, e in ipairs(data.entries) do
        CreateThread(function()
            registerLootEntry(e)
        end)
    end
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
