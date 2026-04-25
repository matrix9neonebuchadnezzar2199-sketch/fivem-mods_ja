local lastDrawAt = 0
local hideTimer = nil

local function nowMs()
    return GetGameTimer()
end

local function showCooldownNotice(secondsLeft)
    TriggerEvent('chat:addMessage', {
        color = { 200, 200, 50 },
        args = { ('[🂠 トランプ] 少し待ってください（あと%s秒）'):format(secondsLeft) }
    })
end

local function hideCardLater()
    if hideTimer then
        ClearTimeout(hideTimer)
        hideTimer = nil
    end

    hideTimer = SetTimeout(Config.DisplayTime, function()
        SendNUIMessage({ type = 'hideCard' })
        SetNuiFocus(false, false)
        hideTimer = nil
    end)
end

RegisterCommand(Config.Command, function()
    local current = nowMs()
    local cooldownMs = Config.Cooldown * 1000
    if current - lastDrawAt < cooldownMs then
        local remainMs = cooldownMs - (current - lastDrawAt)
        local remainSec = math.ceil(remainMs / 1000)
        showCooldownNotice(remainSec)
        return
    end

    lastDrawAt = current
    TriggerServerEvent('jp-card:drawCard')
end, false)

RegisterNetEvent('jp-card:showResult', function(cardData)
    SendNUIMessage({
        type = 'showCard',
        suit = cardData.suit,
        rank = cardData.rank,
        display = cardData.display,
        color = cardData.color,
        isJoker = cardData.isJoker,
        jokerName = cardData.jokerName
    })
    SetNuiFocus(false, false)
    hideCardLater()
end)

RegisterNUICallback('closeCard', function(_, cb)
    SetNuiFocus(false, false)
    cb({})
end)
