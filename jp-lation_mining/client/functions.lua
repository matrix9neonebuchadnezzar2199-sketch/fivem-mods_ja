-- Initialize config(s)
local shared = require 'config.shared'
local cl = require 'config.client'

-- You can change the textUI script here
-- Options: 'lation_ui', 'ox_lib', 'jg-textui', 'okokTextUI', 'qbcore' & 'custom'
local textui = 'ox_lib'

-- ui.scale（採掘メニュー・TextUI 等）既定 1.0=変更なし。config.client の ui 参照
local function getUiScale()
    if cl and cl.ui and type(cl.ui.scale) == 'number' and cl.ui.scale > 0 then
        return cl.ui.scale
    end
    return 1.0
end

local function textUiOptionsForOxs(scale, position)
    local s = scale or 1.0
    if s <= 1.0 or s == nil then
        return { position = position or 'left-center' }
    end
    return {
        position = position or 'left-center',
        style = {
            transform = string.format('scale(%s)', s),
            transformOrigin = (position or 'left-center') == 'right-center' and 'right center' or 'left center',
        },
    }
end

-- ox_lib コンテキスト: 直接 scale できないため Markdown 見出し（# ）で大きく表示
local function contextWithMarkdownIfLarge(data, scale, useMd)
    if not data or (not useMd) or not scale or scale < 1.2 then
        return data
    end
    local c = {}
    for k, v in pairs(data) do
        c[k] = v
    end
    if c.title and type(c.title) == 'string' and not c.title:match('^#+%s') then
        c.title = '# ' .. c.title
    end
    if c.options and type(c.options) == 'table' then
        local out = {}
        for i, opt in ipairs(c.options) do
            if type(opt) == 'table' then
                local o = {}
                for k, v in pairs(opt) do
                    o[k] = v
                end
                if o.title and type(o.title) == 'string' and not o.title:match('^#+%s') then
                    o.title = '## ' .. o.title
                end
                out[i] = o
            else
                out[i] = opt
            end
        end
        c.options = out
    end
    return c
end

-- Display a notification
--- @param message string
--- @param type string
function ShowNotification(message, type)
    if shared.setup.notify == 'lation_ui' then
        exports.lation_ui:notify({ title = 'Mining', message = message, type = type, icon = 'fas fa-fire' })
    elseif shared.setup.notify == 'ox_lib' then
        local s = getUiScale()
        local n = { description = message, type = type, icon = 'fas fa-fire' }
        if s and s > 1.0 then
            n.style = {
                transform = string.format('scale(%s)', s),
                transformOrigin = 'right top',
            }
        end
        lib.notify(n)
    elseif shared.setup.notify == 'esx' then
        ESX.ShowNotification(message)
    elseif shared.setup.notify == 'qb' then
        QBCore.Functions.Notify(message, type)
    elseif shared.setup.notify == 'okok' then
        exports['okokNotify']:Alert('Mining', message, 5000, type, false)
    elseif shared.setup.notify == 'sd-notify' then
        exports['sd-notify']:Notify('Mining', message, type)
    elseif shared.setup.notify == 'wasabi_notify' then
        exports.wasabi_notify:notify('Mining', message, 5000, type, false, 'fas fa-fire')
    elseif shared.setup.notify == 'custom' then
        -- Add custom notification export/event here
    end
end

-- Display a notification from server
--- @param message string
--- @param type string
RegisterNetEvent('jp-lation_mining:notify', function(message, type)
    ShowNotification(message, type)
end)

-- Display a progress bar
--- @param data table
function ProgressBar(data)
    if shared.setup.progress == 'lation_ui' then
        if exports.lation_ui:progressBar({
            title = data.label,
            description = data.description or nil,
            icon = data.icon or nil,
            duration = data.duration,
            useWhileDead = data.useWhileDead,
            canCancel = data.canCancel,
            disable = data.disable,
            anim = {
                dict = data.anim.dict or nil,
                clip = data.anim.clip or nil,
                flag = data.anim.flag or nil
            },
            prop = {
                model = data.prop.model or nil,
                bone = data.prop.bone or nil,
                pos = data.prop.pos or nil,
                rot = data.prop.rot or nil
            }
        }) then
            return true
        end
        return false
    elseif shared.setup.progress == 'ox_lib' then
        -- Want to use ox_lib's progress circle instead of bar?
        -- Change "progressBar" to "progressCircle" below & done!
        local progLabel = data.label
        local s = getUiScale()
        if s >= 1.2 and cl and cl.ui and (cl.ui.useLargeProgressLabel ~= false) and progLabel and not progLabel:find('^#%s') then
            progLabel = '# ' .. progLabel
        end
        if lib.progressBar({
            label = progLabel,
            duration = data.duration,
            position = data.position or 'bottom',
            useWhileDead = data.useWhileDead,
            canCancel = data.canCancel,
            disable = data.disable,
            anim = {
                dict = data.anim.dict or nil,
                clip = data.anim.clip or nil,
                flag = data.anim.flag or nil
            },
            prop = {
                model = data.prop.model or nil,
                bone = data.prop.bone or nil,
                pos = data.prop.pos or nil,
                rot = data.prop.rot or nil
            }
        }) then
            return true
        end
        return false
    elseif shared.setup.progress == 'qbcore' then
        local p = promise.new()
        QBCore.Functions.Progressbar(data.label, data.label, data.duration, data.useWhileDead, data.canCancel, {
            disableMovement = data.disable.move,
            disableCarMovement = data.disable.car,
            disableMouse = false,
            disableCombat = data.disable.combat
        }, {
            animDict = data.anim.dict or nil,
            anim = data.anim.clip or nil,
            flags = data.anim.flag or nil
        }, {
            model = data.prop.model or nil,
            bone = data.prop.bone or nil,
            coords = data.prop.pos or nil,
            rotation = data.prop.rot or nil
        }, {},
        function()
            p:resolve(true)
        end,
        function()
            p:resolve(false)
        end)
        return Citizen.Await(p)
    else
        -- Add 'custom' progress bar here
    end
end

-- Register menu
--- @param data table
function RegisterMenu(data)
    if shared.setup.menu == 'lation_ui' then
        exports.lation_ui:registerMenu(data)
    elseif shared.setup.menu == 'ox_lib' then
        local s = getUiScale()
        local useMd = cl.ui and (cl.ui.useLargeMarkdownInContext ~= false)
        local ctx = contextWithMarkdownIfLarge(data, s, useMd)
        lib.registerContext(ctx)
    elseif shared.setup.menu == 'custom' then
        -- Add 'custom' menu system here
    end
end

-- Show menu
--- @param menuId string
function ShowMenu(menuId)
    if shared.setup.menu == 'lation_ui' then
        exports.lation_ui:showMenu(menuId)
    elseif shared.setup.menu == 'ox_lib' then
        lib.showContext(menuId)
    elseif shared.setup.menu == 'custom' then
        -- Add 'custom' menu system here
    end
end

-- Show input dialog
--- @param data table
function ShowInput(data)
    if shared.setup.dialogs == 'lation_ui' then
        return exports.lation_ui:input({
            title = data.title,
            subtitle = data.subtitle,
            submitText = data.submitText,
            cancelText = data.cancelText,
            type = data.type,
            options = data.options
        })
    elseif shared.setup.dialogs == 'ox_lib' then
        return lib.inputDialog(data.title, data.options, { allowCancel = true })
    elseif shared.setup.dialogs == 'custom' then
        -- Add your custom input dialog here
    end
end

-- Display TextUI
--- @param text string 
--- @param icon string
function ShowTextUI(text, icon)
    if textui == 'lation_ui' then
        exports.lation_ui:showText({
            description = text,
            icon = icon,
        })
    elseif textui == 'ox_lib' then
        local s = getUiScale()
        if s <= 1.0 then
            lib.showTextUI(text, { position = 'left-center', icon = icon })
        else
            local o = textUiOptionsForOxs(s, 'left-center')
            o.icon = icon
            lib.showTextUI(text, o)
        end
    elseif textui == 'jg-textui' then
        exports['jg-textui']:DrawText(text)
    elseif textui == 'okokTextUI' then
        exports['okokTextUI']:Open(text, 'lightblue ', 'left', false)
    elseif textui == 'qbcore' then
        exports['qb-core']:DrawText(text, 'left')
    else
        -- Add custom textUI here
    end
end

-- Hide TextUI
--- @param label string
function HideTextUI(label)
    if textui == 'lation_ui' then
        local isOpen, text = exports.lation_ui:isOpen()
        if isOpen and text == label then
            exports.lation_ui:hideText()
        end
    elseif textui == 'ox_lib' then
        local isOpen, text = lib.isTextUIOpen()
        if isOpen and text == label then
            lib.hideTextUI()
        end
    elseif textui == 'jg-textui' then
        exports['jg-textui']:HideText()
    elseif textui == 'okokTextUI' then
        exports['okokTextUI']:Close()
    elseif textui == 'qbcore' then
        exports['qb-core']:HideText()
    else
        -- Add custom textUI here
    end
end

-- Add circle target zones
--- @param data table
function AddCircleZone(data)
    if shared.setup.interact == 'ox_target' then
        exports.ox_target:addSphereZone(data)
    elseif shared.setup.interact == 'qb-target' then
        exports['qb-target']:AddCircleZone(data.name, data.coords, data.radius, {
            name = data.name,
            debugPoly = shared.setup.debug}, {
            options = data.options,
            distance = 2,
        })
    elseif shared.setup.interact == 'interact' then
        exports.interact:AddInteraction({
            coords = data.coords,
            interactDst = 2.0,
            id = data.name,
            options = data.options
        })
    elseif shared.setup.interact == 'custom' then
        -- Add support for a custom target system here
    else
        print('^1[ERROR]: No interaction system was detected - please visit config/shared "setup" section^0')
    end
end

-- Add target to entity
--- @param entity number
--- @param data table
function AddTargetEntity(entity, data)
    if shared.setup.interact == 'ox_target' then
        exports.ox_target:addLocalEntity(entity, data)
    elseif shared.setup.interact == 'qb-target' then
        exports['qb-target']:AddTargetEntity(entity, {options = data, distance = 2})
    elseif shared.setup.interact == 'interact' then
        exports.interact:AddLocalEntityInteraction({
            entity = entity,
            interactDst = 2.0,
            offset = vec3(0.0, 0.0, 1.0),
            options = data
        })
    elseif shared.setup.interact == 'custom' then
        -- Add support for a custom target system here
    else
        print('^1[ERROR]: No interaction system was detected - please visit config/shared "setup" section^0')
    end
end

-- Function to remove circle zone
--- @param name string
function RemoveCircleZone(name)
    if shared.setup.interact == 'ox_target' then
        exports.ox_target:removeZone(name)
    elseif shared.setup.interact == 'qb-target' then
        exports['qb-target']:RemoveZone(name)
    elseif shared.setup.interact == 'interact' then
        exports.interact:RemoveInteraction(name)
    elseif shared.setup.interact == 'custom' then
        -- Add support for a custom target system here
    else
        print('^1[ERROR]: No interaction system defined in the sh_config file^0')
    end
end

-- Remove target from entity
--- @param entity any|number
--- @param data table|string
function RemoveTargetEntity(entity, data)
    if shared.setup.interact == 'ox_target' then
        exports.ox_target:removeLocalEntity(entity, data)
    elseif shared.setup.interact == 'qb-target' then
        exports.qtarget:RemoveTargetEntity(entity, data)
    elseif shared.setup.interact == 'interact' then
        exports.interact:RemoveLocalEntityInteraction(entity, data)
    elseif shared.setup.interact == 'custom' then
        -- Add support for a custom target system here
    else
        print('^1[ERROR]: No interaction system was detected - please visit config/shared "setup" section^0')
    end
end

-- Return an inventory's "durability/quality" types
function GetDurabilityType()
    if Inventory == 'ox_inventory' then
        return 'durability'
    else
        return 'quality'
    end
end

-- Function to spawn NPCs
--- @param model string
--- @param position vector4
function SpawnPed(model, position)
    lib.requestModel(model)
    while not HasModelLoaded(model) do Wait(0) end
    local ped = CreatePed(0, model, position.x, position.y, position.z - 1.0, position.w, false, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityInvincible(ped, true)
    return ped
end