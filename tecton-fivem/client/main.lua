-- SPDX-License-Identifier: LGPL-3.0-or-later

--- ox_lib は fxmanifest の shared_scripts で `@ox_lib/init.lua` を読み込み済み。

---@diagnostic disable: undefined-global

local state = {
    open = false,
    scene = Config.DefaultScene or 'default',
    selected = nil,
    mode = 'furniture',
}

local function vlog(msg)
    if Config.Debug and Config.Debug.verbose then
        print(('[TECTON] %s'):format(msg))
    end
end

local function ToggleBuilder()
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
    return state
end)

exports('ToggleBuilder', ToggleBuilder)

RegisterCommand('tecton', ToggleBuilder, false)

RegisterCommand('tec', ToggleBuilder, false)

local openKey = (Config.Keys and Config.Keys.openBuilder) or 'F2'
lib.addKeybind({
    name = 'tecton_toggle_builder',
    description = 'Toggle TECTON builder',
    defaultKey = openKey,
    onPressed = function()
        ToggleBuilder()
    end,
})
