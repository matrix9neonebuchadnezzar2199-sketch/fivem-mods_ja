-- SPDX-License-Identifier: LGPL-3.0-or-later

--- ox_lib は fxmanifest の shared_scripts で `@ox_lib/init.lua` を読み込み済み。

---@diagnostic disable: undefined-global

local function vlog(msg)
    if Config.Debug and Config.Debug.verbose then
        print(('[TECTON] %s'):format(msg))
    end
end

local function ToggleBuilder()
    local state = TectonClient
    state.open = not state.open
    SetNuiFocus(state.open, state.open)
    SendNUIMessage({ action = 'setOpen', open = state.open })
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
        client.spawnedHandles[id] = result.handle
    else
        placement.removeObject(result.handle)
    end
end, false)

local openKey = (Config.Keys and Config.Keys.openBuilder) or 'F2'
lib.addKeybind({
    name = 'tecton_toggle_builder',
    description = 'Toggle TECTON builder',
    defaultKey = openKey,
    onPressed = function()
        ToggleBuilder()
    end,
})
