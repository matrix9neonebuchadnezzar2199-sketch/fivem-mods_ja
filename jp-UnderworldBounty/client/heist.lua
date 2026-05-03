local NearLocationId = nil
local HeistRunning = false

RegisterNetEvent(UbEvent('client:heistSync'), function(data)
  HeistRunning = true
  if data.phase == 'entry' then
    UbRunMinigame(data.minigame, function(ok)
      TriggerServerEvent(UbEvent('server:confirmEntry'), ok)
      if not ok then
        HeistRunning = false
      end
    end)
  elseif data.phase == 'combat' then
    UbNpcBeginScenario(data.scenario_id)
  end
end)

RegisterNetEvent(UbEvent('client:heistEnded'), function(payload)
  HeistRunning = false
  UbNpcCleanup(true)
  UbUiMinigameClose()
  if payload and payload.reason == 'success' then
    UbNotify(_L('notify_heist_success'), 'success')
  end
end)

CreateThread(function()
  while true do
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    NearLocationId = nil
    for _, loc in ipairs(Config.Locations or {}) do
      if loc.enabled and #(pos - loc.trigger.coords) <= loc.trigger.radius then
        NearLocationId = loc.id
        break
      end
    end
    if NearLocationId and not HeistRunning then
      BeginTextCommandDisplayHelp('STRING')
      AddTextComponentSubstringPlayerName(_L('prompt_enter'))
      EndTextCommandDisplayHelp(0, false, true, -1)
      if IsControlJustReleased(0, 38) then
        TriggerServerEvent(UbEvent('server:requestStart'), NearLocationId)
        Wait(600)
      end
      Wait(100)
    else
      Wait(Config.ZonePollIntervalMs or 500)
    end
  end
end)

CreateThread(function()
  while true do
    Wait(500)
    if HeistRunning and IsEntityDead(PlayerPedId()) then
      TriggerServerEvent(UbEvent('server:playerDownDuringHeist'))
      HeistRunning = false
      UbNpcCleanup(true)
    end
  end
end)
