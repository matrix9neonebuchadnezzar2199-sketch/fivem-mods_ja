-- SPDX-License-Identifier: LGPL-3.0-or-later

---@diagnostic disable: undefined-global

local res = GetCurrentResourceName()

local function getState()
    return exports[res]:GetTectonBuilderState()
end

---@param client table
---@param idNum number|nil
---@return integer|nil
local function resolveSpawnedHandle(client, idNum)
    if not idNum then
        return nil
    end
    local h = client.spawnedHandles[idNum]
    if h and h ~= 0 then
        return h
    end
    h = client.spawnedHandles[tostring(idNum)]
    if h and h ~= 0 then
        return h
    end
    return nil
end

--- NUI JSON の pos / rot を数値テーブルに（欠落時は nil）
---@param t table|nil
---@return table|nil
local function nuiVec3(t)
    if type(t) ~= 'table' then
        return nil
    end
    if t.x == nil and t.y == nil and t.z == nil then
        return nil
    end
    return {
        x = tonumber(t.x) or 0.0,
        y = tonumber(t.y) or 0.0,
        z = tonumber(t.z) or 0.0,
    }
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
        lib.hideTextUI()
        SendNUIMessage({ action = 'setPlacementGuide', show = false })
        SendNUIMessage({ action = 'setOpen', open = false, keepSelection = true })
        SendNUIMessage({ action = 'placementBanner', show = true })
        SetNuiFocus(false, false)
        s.open = false
        s.placementActive = true
        s.uiResumeAfterPlacement = true
    end
    local res = handler.handleCreate(data)
    if wasOpen then
        SendNUIMessage({ action = 'placementBanner', show = false })
        s.placementActive = false
        SetNuiFocus(false, false)
        --- NUI は自動では開かない。ox_lib で案内（ゲーム操作中も視認可）
        lib.showTextUI('[スペース] または /tecResume でビルダーを再表示', { position = 'bottom-center' })
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
    if type(data) == 'string' then
        local okj, dec = pcall(json.decode, data)
        if okj and type(dec) == 'table' then
            data = dec
        end
    end
    if type(data) ~= 'table' or data.id == nil then
        SendNUIMessage({ action = 'opAck', op = 'update', ok = false, reason = 'bad_payload' })
        cb({ ok = false, reason = 'bad_payload' })
        return
    end
    local hid = tonumber(data.id)
    if not hid then
        SendNUIMessage({ action = 'opAck', op = 'update', ok = false, reason = 'bad_payload' })
        cb({ ok = false, reason = 'bad_payload' })
        return
    end
    local rawAfter = data.after
    if type(rawAfter) ~= 'table' then
        SendNUIMessage({ action = 'opAck', op = 'update', ok = false, reason = 'bad_payload' })
        cb({ ok = false, reason = 'bad_payload' })
        return
    end
    local pos = nuiVec3(rawAfter.pos)
    local rot = nuiVec3(rawAfter.rot)
    if not pos or not rot then
        SendNUIMessage({ action = 'opAck', op = 'update', ok = false, reason = 'bad_payload' })
        cb({ ok = false, reason = 'bad_payload' })
        return
    end
    local after = { pos = pos, rot = rot }
    local ok = lib.callback.await('tecton:op:update', false, hid, after)
    if ok then
        local client = getState()
        local handle = resolveSpawnedHandle(client, hid)
        local placement = TectonPlacement
        if handle and placement and type(placement.applyWorldTransform) == 'function' then
            placement.applyWorldTransform(handle, pos, rot)
        end
        local fresh = lib.callback.await('tecton:object:get', false, hid)
        SendNUIMessage({ action = 'selectedObject', selected = client.selected, object = fresh })
        SendNUIMessage({ action = 'opAck', op = 'update', ok = true, id = hid })
        cb({ ok = true })
    else
        SendNUIMessage({ action = 'opAck', op = 'update', ok = false })
        cb({ ok = false })
    end
end)

RegisterNUICallback('deleteObject', function(data, cb)
    if type(data) ~= 'table' or data.id == nil then
        SendNUIMessage({ action = 'opAck', op = 'delete', ok = false, reason = 'bad_payload' })
        cb({ ok = false, reason = 'bad_payload' })
        return
    end
    local hid = tonumber(data.id)
    if not hid then
        SendNUIMessage({ action = 'opAck', op = 'delete', ok = false, reason = 'bad_payload' })
        cb({ ok = false, reason = 'bad_payload' })
        return
    end
    local ok = lib.callback.await('tecton:op:delete', false, hid)
    if ok then
        local client = getState()
        local handle = resolveSpawnedHandle(client, hid)
        local placement = TectonPlacement
        if handle and placement and type(placement.removeObject) == 'function' then
            placement.removeObject(handle)
        end
        client.spawnedHandles[hid] = nil
        client.spawnedHandles[tostring(hid)] = nil
        local sel = tonumber(client.selected)
        if sel == hid then
            client.selected = nil
        end
        SendNUIMessage({ action = 'selectedObject', selected = nil, object = nil })
        SendNUIMessage({ action = 'opAck', op = 'delete', ok = true, id = hid })
        cb({ ok = true })
    else
        SendNUIMessage({ action = 'opAck', op = 'delete', ok = false })
        cb({ ok = false })
    end
end)

RegisterNUICallback('resumeBuilder', function(_, cb)
    exports[res]:ReopenTectonBuilderAfterPlacement()
    cb({ ok = true })
end)
