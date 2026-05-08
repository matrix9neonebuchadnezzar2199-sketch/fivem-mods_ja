-- SPDX-License-Identifier: LGPL-3.0-or-later

--- ox_lib は fxmanifest の shared_scripts で `@ox_lib/init.lua` を読み込み済み。

---@diagnostic disable: undefined-global

local resName = GetCurrentResourceName()

local function vlog(msg)
    if Config.Debug and Config.Debug.verbose then
        print(('[TECTON] %s'):format(msg))
    end
end

--- プレイヤーが操作可能になるまで待つ（ストリーミング／スポーン前の CreateObject 失敗を減らす）。
local function waitForPlayablePed()
    local deadline = GetGameTimer() + 60000
    while GetGameTimer() < deadline do
        if LocalPlayer and LocalPlayer.state and LocalPlayer.state.isLoggedIn == false then
            Wait(100)
        else
            local ped = PlayerPedId()
            if ped ~= 0 and DoesEntityExist(ped) then
                local c = GetEntityCoords(ped)
                if (math.abs(c.x) > 1.0 or math.abs(c.y) > 1.0) and c.z > -150.0 and c.z < 2000.0 then
                    return true
                end
            end
            Wait(100)
        end
    end
    print('^3TECTON: scene restore skipped — ped not ready in time^0')
    return false
end

local function restoreSceneFromServer()
    local client = TectonClient
    local placement = TectonPlacement
    if not placement or type(placement.spawnExistingObject) ~= 'function' then
        print('^1TECTON: restoreScene placement unavailable^0')
        return
    end
    local rows = lib.callback.await('tecton:scene:request', false, client.scene)
    if type(rows) ~= 'table' then
        print('^1TECTON: scene:request returned non-table^0')
        return
    end
    local n = 0
    for _, obj in ipairs(rows) do
        if obj.id and obj.model then
            local handle = placement.spawnExistingObject(obj)
            if handle and handle ~= 0 then
                local oid = tonumber(obj.id) or obj.id
                client.spawnedHandles[oid] = handle
                n = n + 1
            else
                print(('^3TECTON: spawn failed for object id=%s model=%s^0'):format(tostring(obj.id), tostring(obj.model)))
            end
        end
    end
    print(('TECTON: client restored %d scene objects'):format(n))
end

local function fetchPropsCatalog()
    CreateThread(function()
        local ok, data = pcall(function()
            return lib.callback.await('tecton:props:fetch', false)
        end)
        local client = TectonClient
        if not ok or type(data) ~= 'table' or type(data.dictionary) ~= 'table' then
            client.propsError = true
            client.propsLoaded = false
            print('^1TECTON: props fetch failed (callback error or empty)^0')
            SendNUIMessage({ action = 'propsLoadFailed' })
            return
        end
        local n = 0
        for _ in pairs(data.dictionary) do
            n = n + 1
        end
        client.propsDictionary = data.dictionary
        client.propsCategories = data.categories
        client.propsVersion = data.version
        client.propsLoaded = true
        client.propsError = false
        client.propsCount = n
        print(('TECTON: props loaded (%d entries)'):format(n))
        SendNUIMessage({
            action = 'setProps',
            dictionary = data.dictionary,
            categories = data.categories,
            version = data.version,
            count = n,
        })
    end)
end

AddEventHandler('onClientResourceStart', function(res)
    if res ~= resName then
        return
    end
    fetchPropsCatalog()
    CreateThread(function()
        TectonClient.spawnedHandles = {}
        if not waitForPlayablePed() then
            return
        end
        restoreSceneFromServer()
    end)
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= resName then
        return
    end
    local placement = TectonPlacement
    local client = TectonClient
    if placement and type(placement.removeObject) == 'function' and client and client.spawnedHandles then
        for _, h in pairs(client.spawnedHandles) do
            placement.removeObject(h)
        end
    end
    if client then
        client.spawnedHandles = {}
    end
end)

local function ToggleBuilder()
    local state = TectonClient
    lib.hideTextUI()
    state.open = not state.open
    SetNuiFocus(state.open, state.open)
    SendNUIMessage({ action = 'setOpen', open = state.open })
    if state.open and state.propsLoaded and state.propsDictionary then
        SendNUIMessage({
            action = 'setProps',
            dictionary = state.propsDictionary,
            categories = state.propsCategories,
            version = state.propsVersion,
            count = state.propsCount,
        })
    end
    if state.open then
        print('TECTON: builder open')
        vlog('builder toggled open')
    else
        print('TECTON: builder closed')
        vlog('builder toggled closed')
    end
end

exports('GetTectonBuilderState', function()
    return TectonClient
end)

exports('ToggleBuilder', ToggleBuilder)

RegisterCommand('tecton', ToggleBuilder, false)

RegisterCommand('tec', ToggleBuilder, false)

local function testTectonPlaceEnabled()
    return Config.Debug and Config.Debug.testTectonPlace == true
end

RegisterCommand('tecPlaceTest', function()
    if not testTectonPlaceEnabled() then
        return
    end
    local placement = TectonPlacement
    if not placement or type(placement.startPlacement) ~= 'function' then
        print('^1TECTON: tecPlaceTest placement unavailable^0')
        return
    end
    local result = placement.startPlacement('prop_chair_01a')
    if not result then
        print('TECTON: tecPlaceTest cancelled or failed')
        return
    end
    local client = TectonClient
    local obj = {
        category = 'furniture',
        model = 'prop_chair_01a',
        pos = { x = result.pos.x, y = result.pos.y, z = result.pos.z },
        rot = { x = result.rot.x, y = result.rot.y, z = result.rot.z },
        meta = {},
        scene_id = client.scene,
    }
    local id = lib.callback.await('tecton:op:create', false, obj)
    print(('TECTON: tecPlaceTest Placed: %s'):format(tostring(id)))
    if id then
        client.spawnedHandles[tonumber(id) or id] = result.handle
    else
        placement.removeObject(result.handle)
    end
end, false)

--- 視線方向のカプセルレイキャストで配置済み TECTON オブジェクトを選択（M2-e）。**チャット `/tecPick` のみ**（ホットキーなし）。
local function pickTectonObjectRaycast()
    local placement = TectonPlacement
    if not placement or type(placement.findSpawnedIdByHandle) ~= 'function' then
        return
    end
    local ped = PlayerPedId()
    if ped == 0 or not DoesEntityExist(ped) then
        return
    end
    local c = GetEntityCoords(ped)
    local f = GetEntityForwardVector(ped)
    local zOff = 0.65
    local len = 12.0
    local x1, y1, z1 = c.x, c.y, c.z + zOff
    local x2, y2, z2 = x1 + f.x * len, y1 + f.y * len, z1 + f.z * len
    local ray = StartShapeTestCapsule(x1, y1, z1, x2, y2, z2, 0.5, 511, ped, 7)
    local retval, hit, _, _, entityHit = GetShapeTestResult(ray)
    local deadline = GetGameTimer() + 50
    while retval == 1 and GetGameTimer() < deadline do
        Wait(0)
        retval, hit, _, _, entityHit = GetShapeTestResult(ray)
    end
    if retval ~= 2 or not hit or not entityHit or entityHit == 0 then
        lib.notify({ description = 'TECTON object ではありません', type = 'error' })
        return
    end
    local id = placement.findSpawnedIdByHandle(entityHit)
    if not id then
        lib.notify({ description = 'TECTON object ではありません', type = 'error' })
        return
    end
    local obj = lib.callback.await('tecton:object:get', false, id)
    if not obj then
        lib.notify({ description = 'TECTON object ではありません', type = 'error' })
        return
    end
    local client = TectonClient
    client.selected = id
    if not client.open then
        ToggleBuilder()
        Wait(0)
    end
    SendNUIMessage({ action = 'selectedObject', selected = id, object = obj })
end

RegisterCommand('tecPick', function()
    pickTectonObjectRaycast()
end, false)
