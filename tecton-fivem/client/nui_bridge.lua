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
    cb({
        ok = true,
        open = s.open,
        scene = s.scene,
        mode = s.mode,
        selected = s.selected,
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
        SetNuiFocus(false, false)
    end
    local res = handler.handleCreate(data)
    if wasOpen then
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
    s.selected = data and data.id or nil
    SendNUIMessage({ action = 'selectAck', ok = true, selected = s.selected })
    cb({ ok = true, selected = s.selected })
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
