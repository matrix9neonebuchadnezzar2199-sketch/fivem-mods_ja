local lastTossAt = 0
local hideTimer = nil

local function notifyCooldown(sec)
    TriggerEvent('chat:addMessage', {
        color = { 220, 180, 50 },
        args = { ('[🪙 コイントス] 少し待ってください（あと%s秒）'):format(sec) }
    })
end

local function scheduleHide()
    if hideTimer then
        ClearTimeout(hideTimer)
        hideTimer = nil
    end

    hideTimer = SetTimeout(Config.AnimationTime + Config.DisplayTime, function()
        SendNUIMessage({ type = 'hide' })
        SetNuiFocus(false, false)
        hideTimer = nil
    end)
end

RegisterCommand(Config.Command, function()
    local now = GetGameTimer()
    local cooldownMs = Config.Cooldown * 1000
    if now - lastTossAt < cooldownMs then
        local remainMs = cooldownMs - (now - lastTossAt)
        notifyCooldown(math.ceil(remainMs / 1000))
        return
    end

    lastTossAt = now
    TriggerServerEvent('jp-coin:tossCoin')
end, false)

RegisterNetEvent('jp-coin:showResult', function(result)
    SendNUIMessage({
        type = 'toss',
        side = result.side,
        label = result.label,
        animationTime = Config.AnimationTime
    })
    SetNuiFocus(false, false)
    scheduleHide()
end)
