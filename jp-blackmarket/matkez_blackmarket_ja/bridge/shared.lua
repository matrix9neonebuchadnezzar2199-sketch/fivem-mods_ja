local shared = require 'config.shared'
local locales

function loadLocales()
    local jsonFile = LoadResourceFile(GetCurrentResourceName(), ('locales/%s.json'):format(shared.language))
    locales = json.decode(jsonFile)
    Wait(50)
    if not IsDuplicityVersion() then
        SendNUIMessage({
            event = 'locales',
            locales = locales
        })
    end
end

CreateThread(function()
    Wait(500)
    loadLocales()
end)

function translate(m)
    return locales[m] or 'No locale '..m
end

function notify(src, desc, notifyType, duration)
    if IsDuplicityVersion() then
        lib.notify(src, {
            description = desc,
            type = notifyType,
            duration = duration
        })
    else
        lib.notify({
            description = desc,
            type = notifyType,
            duration = duration
        })
    end
end

function createInteraction(entity, options)
    if shared.interaction == 'ox_target' then
        exports.ox_target:addLocalEntity(entity, options)
    elseif shared.interaction == 'sleepless_interact' then
        exports.sleepless_interact:addLocalEntity(entity, options)
    end
end