local NearLocationId = nil
local HeistRunning = false
-- DisplayHelp を短間隔で呼ぶと毎回アニメが頭から再生されて点滅するため、更新は長めに間引く
local HEIST_HELP_REFRESH_MS = 4000
local lastHeistHelpAt = 0
-- トリガー可視化（地上の薄い円）。描画負荷は近接時のみ Wait(0)
local HEIST_MARKER_DRAW_DIST = 42.0

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
  local delay = (Config.CombatEntityCleanupDelayMs or 0)
  if delay > 0 then
    UbNpcCleanupAfter(delay, true)
  else
    UbNpcCleanup(true)
  end
  UbUiMinigameClose()
  if payload and payload.reason == 'success' then
    UbNotify(_L('notify_heist_success'), 'success')
  end
end)

-- 強盗開始トリガー位置を黄色い円で示す（タイプ25＝地上のフラット円）
CreateThread(function()
  while true do
    local waitMs = 500
    if not HeistRunning then
      local ped = PlayerPedId()
      local pos = GetEntityCoords(ped)
      for _, loc in ipairs(Config.Locations or {}) do
        if loc.enabled then
          local c = loc.trigger.coords
          local dist = #(pos - c)
          if dist <= HEIST_MARKER_DRAW_DIST then
            waitMs = 0
            local r = loc.trigger.radius or 2.0
            DrawMarker(
              25,
              c.x, c.y, c.z - 0.98,
              0.0, 0.0, 0.0,
              0.0, 0.0, 0.0,
              r * 2.4, r * 2.4, 0.4,
              255, 220, 0, 130,
              false,
              false,
              2,
              false,
              nil,
              nil,
              false
            )
          end
        end
      end
    end
    Wait(waitMs)
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
      local now = GetGameTimer()
      if now - lastHeistHelpAt >= HEIST_HELP_REFRESH_MS then
        BeginTextCommandDisplayHelp('STRING')
        AddTextComponentSubstringPlayerName(_L('prompt_enter'))
        EndTextCommandDisplayHelp(0, false, false, -1)
        lastHeistHelpAt = now
      end
      if IsControlJustReleased(0, 38) then
        TriggerServerEvent(UbEvent('server:requestStart'), NearLocationId)
        Wait(600)
      end
      Wait(16)
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
