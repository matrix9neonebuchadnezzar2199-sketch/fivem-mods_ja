AddEventHandler('onClientResourceStart', function(res)
    if res ~= GetCurrentResourceName() then
        return
    end
    CreateThread(function()
        Wait(1500)
        TriggerServerEvent('jp-sentinel:server:requestActive')
    end)
end)

if Config.EnableCommand then
    RegisterCommand(Config.CommandName, function()
        TriggerServerEvent('jp-sentinel:server:requestThrow', false)
    end, false)
end
