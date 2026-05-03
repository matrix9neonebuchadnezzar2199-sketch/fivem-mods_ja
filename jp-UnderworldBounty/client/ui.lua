local bountyHudOn = false

--- @param active boolean
local function sendBountyHud(active)
  SendNUIMessage({
    action = 'bountyHud',
    active = active,
    label = _L('hud_bounty_active'),
  })
end

RegisterNetEvent(UbEvent('client:bountyHud'), function(data)
  bountyHudOn = data and data.active == true
  sendBountyHud(bountyHudOn)
end)

RegisterNetEvent(UbEvent('client:openFlavor'), function(key)
  SendNUIMessage({ action = 'toast', message = _L(key) })
end)

function UbUiMinigameOpen(payload)
  SetNuiFocus(true, true)
  SendNUIMessage({
    action = 'openMinigame',
    payload = payload,
  })
end

function UbUiMinigameClose()
  SetNuiFocus(false, false)
  SendNUIMessage({ action = 'closeMinigame' })
end

RegisterNUICallback('ub_minigame_result', function(data, cb)
  SetNuiFocus(false, false)
  SendNUIMessage({ action = 'closeMinigame' })
  if UbMinigameFinish then
    local fn = UbMinigameFinish
    UbMinigameFinish = nil
    fn(data and data.ok == true)
  end
  cb('ok')
end)
