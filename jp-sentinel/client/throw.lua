local IsThrowMode = false

RegisterNetEvent('jp-sentinel:client:allowThrow', function()
    local ped = PlayerPedId()
    IsThrowMode = true

    GiveWeaponToPed(ped, Config.Throw.WeaponHash, 1, false, true)
    SetCurrentPedWeapon(ped, Config.Throw.WeaponHash, true)

    TriggerEvent('jp-sentinel:client:notifyLocal', Config.Lang('throw_ready'), 'info')

    CreateThread(function()
        while IsThrowMode do
            if IsControlJustReleased(0, 24) then
                Wait(400)
                IsThrowMode = false
                RemoveWeaponFromPed(ped, Config.Throw.WeaponHash)
                StartImpactTracking(ped)
                break
            end
            Wait(0)
        end
    end)
end)

RegisterNetEvent('jp-sentinel:client:denyThrow', function(data)
    IsThrowMode = false
    if type(data) == 'table' and data.reason == 'cooldown' and data.remain then
        TriggerEvent('jp-sentinel:client:notifyLocal', Config.Lang('cooldown_active', data.remain), 'error')
    elseif type(data) == 'table' and data.reason == 'busy' then
        TriggerEvent('jp-sentinel:client:notifyLocal', Config.Lang('already_active'), 'error')
    end
end)
