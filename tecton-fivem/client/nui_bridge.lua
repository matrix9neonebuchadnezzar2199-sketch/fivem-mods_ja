-- SPDX-License-Identifier: LGPL-3.0-or-later

---@diagnostic disable: undefined-global

local res = GetCurrentResourceName()

local function getState()
    return exports[res]:GetTectonBuilderState()
end

RegisterNUICallback('ready', function(_, cb)
    local s = getState()
    if s.propsLoaded and s.propsDictionary then
        SendNUIMessage({
            action = 'setProps',
            dictionary = s.propsDictionary,
            categories = s.propsCategories,
            version = s.propsVersion,
            count = s.propsCount,
        })
    elseif s.propsError then
        SendNUIMessage({ action = 'propsLoadFailed' })
    end
    local selectedObject = nil
    if s.selected then
        selectedObject = lib.callback.await('tecton:object:get', false, s.selected)
        if not selectedObject then
            s.selected = nil
        end
    end
    cb({
        ok = true,
        open = s.open,
        scene = s.scene,
        mode = s.mode,
        selected = s.selected,
        selectedObject = selectedObject,
        propsLoaded = s.propsLoaded,
        propsCount = s.propsCount or 0,
        propsError = s.propsError,
    })
end)

RegisterNUICallback('close', function(_, cb)
    local s = getState()
    if s.open then
        exports[res]:ToggleBuilder()
    end
    cb({ ok = true })
end)

--- 右ボタンドラッグ中のみマウスをゲームへ渡し、視点回転（カメラ）を可能にする。
RegisterNUICallback('cameraLook', function(data, cb)
    local s = getState()
    if not s.open then
        cb({ ok = true })
        return
    end
    local enable = type(data) == 'table' and data.enable == true
    if enable then
        SetNuiFocus(true, false)
    else
        SetNuiFocus(true, true)
    end
    cb({ ok = true })
end)

RegisterNUICallback('createObject', function(data, cb)
    local s = getState()
    local mode = (type(data) == 'table' and data.mode) or s.mode or 'furniture'
    local handler = TectonModeHandlers and TectonModeHandlers[mode]
    if not handler or type(handler.handleCreate) ~= 'function' then
        SendNUIMessage({ action = 'opAck', op = 'create', ok = false, reason = 'unsupported_mode' })
        cb({ ok = false, reason = 'unsupported_mode' })
        return
    end
    local wasOpen = s.open
    if wasOpen then
        SendNUIMessage({ action = 'setPlacementGuide', show = true })
        SetNuiFocus(false, false)
    end
    local res = handler.handleCreate(data)
    if wasOpen then
        SendNUIMessage({ action = 'setPlacementGuide', show = false })
        SetNuiFocus(true, true)
    end
    if res.ok then
        SendNUIMessage({ action = 'opAck', op = 'create', ok = true, id = res.id })
        cb({ ok = true, id = res.id })
    else
        SendNUIMessage({ action = 'opAck', op = 'create', ok = false, reason = res.reason })
        cb({ ok = false, reason = res.reason })
    end
end)

RegisterNUICallback('selectObject', function(data, cb)
    local s = getState()
    local id = data and tonumber(data.id) or nil
    s.selected = id
    local obj = nil
    if id then
        obj = lib.callback.await('tecton:object:get', false, id)
        if not obj then
            s.selected = nil
        end
    end
    SendNUIMessage({ action = 'selectedObject', selected = s.selected, object = obj })
    cb({ ok = true, selected = s.selected, object = obj })
end)

RegisterNUICallback('updateObject', function(data, cb)
    if type(data) ~= 'table' or not data.id then
        SendNUIMessage({ action = 'opAck', op = 'update', ok = false, reason = 'bad_payload' })
        cb({ ok = false, reason = 'bad_payload' })
        return
    end
    local after = data.after or data
    local ok = lib.callback.await('tecton:op:update', false, data.id, after)
    if ok then
        local client = getState()
        local hid = tonumber(data.id)
        local handle = hid and client.spawnedHandles[hid]
        if handle and handle ~= 0 and DoesEntityExist(handle) and after.pos and after.rot then
            local px = tonumber(after.pos.x) or 0.0
            local py = tonumber(after.pos.y) or 0.0
            local pz = tonumber(after.pos.z) or 0.0
            local rx = tonumber(after.rot.x) or 0.0
            local ry = tonumber(after.rot.y) or 0.0
            local rz = tonumber(after.rot.z) or 0.0
            SetEntityCoords(handle, px, py, pz, false, false, false, false)
            SetEntityRotation(handle, rx, ry, rz, 2, true)
        end
        local fresh = hid and lib.callback.await('tecton:object:get', false, hid) or nil
        SendNUIMessage({ action = 'selectedObject', selected = client.selected, object = fresh })
        SendNUIMessage({ action = 'opAck', op = 'update', ok = true, id = data.id })
        cb({ ok = true })
    else
        SendNUIMessage({ action = 'opAck', op = 'update', ok = false })
        cb({ ok = false })
    end
end)

RegisterNUICallback('deleteObject', function(data, cb)
    if type(data) ~= 'table' or not data.id then
        SendNUIMessage({ action = 'opAck', op = 'delete', ok = false, reason = 'bad_payload' })
        cb({ ok = false, reason = 'bad_payload' })
        return
    end
    local ok = lib.callback.await('tecton:op:delete', false, data.id)
    if ok then
        SendNUIMessage({ action = 'opAck', op = 'delete', ok = true, id = data.id })
        cb({ ok = true })
    else
        SendNUIMessage({ action = 'opAck', op = 'delete', ok = false })
        cb({ ok = false })
    end
end)
