local lastReportTime = 0
local hideNotifyTimer = nil

local function showChat(color, text)
    TriggerEvent('chat:addMessage', {
        color = color,
        args = { '110番', text }
    })
end

RegisterCommand(Config.Command, function()
    local now = GetGameTimer()
    local cooldownMs = Config.Cooldown * 1000
    if now - lastReportTime < cooldownMs then
        showChat({ 200, 200, 50 }, 'しばらく待ってから再度通報してください。')
        return
    end

    TriggerServerEvent('jp-110:report110')
    lastReportTime = now
end, false)

RegisterNetEvent('jp-110:receive110', function(coords)
    SendNUIMessage({
        type = 'show110',
        title = Config.NotificationTitle,
        body = Config.NotificationBody
    })
    SetNuiFocus(false, false)

    if hideNotifyTimer then
        ClearTimeout(hideNotifyTimer)
        hideNotifyTimer = nil
    end
    hideNotifyTimer = SetTimeout(Config.NotificationDuration, function()
        SendNUIMessage({ type = 'hide' })
        SetNuiFocus(false, false)
        hideNotifyTimer = nil
    end)

    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, Config.BlipSprite)
    SetBlipColour(blip, Config.BlipColor)
    SetBlipScale(blip, Config.BlipScale)
    SetBlipFlashes(blip, true)
    SetBlipFlashInterval(blip, Config.BlipFlashInterval)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('110番通報')
    EndTextCommandSetBlipName(blip)

    SetTimeout(Config.BlipDuration * 1000, function()
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end)
end)
