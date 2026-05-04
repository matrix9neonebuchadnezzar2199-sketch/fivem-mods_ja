local Active = {}
local LocationCd = {}

local function notify_denied(src)
  Bridge.Notify(src, _L('notify_heist_denied'), 'error')
end

local function fail(src, reason)
  local st = Active[src]
  Active[src] = nil
  TriggerClientEvent(UbEvent('client:heistEnded'), src, { reason = reason or 'fail' })
  UbEmitHook('onHeistFail', { target = src, reason = reason or 'fail' })
  Bridge.Notify(src, _L('notify_heist_fail'), 'error')
end

local function succeed(src)
  local st = Active[src]
  if not st then
    return
  end
  local sc = ScenarioById[st.scenario_id]
  if not sc then
    fail(src, 'bad_scenario')
    return
  end
  UbGrantRewards(src, sc.reward_table_id)
  UbSetBounty(src, sc.id, sc.retaliation_pattern_id)
  Bridge.Notify(src, _L('notify_reward_received'), 'success')
  Bridge.Notify(src, _L('notify_bounty_set'), 'error')
  Active[src] = nil
  local cd = Config.LocationCooldownSec or 0
  if not Config.Debug then
    LocationCd[st.location_id] = os.time() + cd
  end
  TriggerClientEvent(UbEvent('client:heistEnded'), src, { reason = 'success' })
  UbEmitHook('onHeistComplete', { target = src, scenarioId = sc.id, locationId = st.location_id })
end

RegisterNetEvent(UbEvent('server:requestStart'), function(location_id)
  local src = source
  if UbHasActiveContract and UbHasActiveContract(src) then
    notify_denied(src)
    return
  end
  if Active[src] then
    return
  end
  local loc = LocationById[location_id]
  if not loc or not loc.enabled then
    notify_denied(src)
    return
  end
  if not UbIsNearTrigger(src, loc.trigger) then
    notify_denied(src)
    return
  end
  local cd_until = LocationCd[location_id]
  if cd_until and os.time() < cd_until and not Config.Debug then
    notify_denied(src)
    return
  end
  local job = Bridge.GetJob(src):lower()
  if Config.BlacklistedJobs[job] then
    notify_denied(src)
    return
  end
  if Bridge.GetCopCount() < (Config.MinOnDutyCops or 0) then
    notify_denied(src)
    return
  end
  local sc = ScenarioById[loc.scenario_id]
  if not sc then
    notify_denied(src)
    return
  end
  for _, req in ipairs(sc.required_items or {}) do
    if not Bridge.HasItem(src, req.item, req.count or 1) then
      notify_denied(src)
      return
    end
  end
  Active[src] = {
    location_id = location_id,
    scenario_id = sc.id,
    phase = 'entry',
    started = os.time(),
    deadline = os.time() + (sc.time_limit_sec or 600),
  }
  UbEmitHook('onHeistStart', {
    target = src,
    scenarioId = sc.id,
    locationId = location_id,
  })
  Bridge.Notify(src, _L('notify_heist_started'), 'info')
  if sc.flavor_key then
    TriggerClientEvent(UbEvent('client:openFlavor'), src, sc.flavor_key)
  end
  local entry = sc.entry_minigame or 'none'
  if entry == 'none' then
    Active[src].phase = 'combat'
    TriggerClientEvent(UbEvent('client:heistSync'), src, {
      phase = 'combat',
      scenario_id = sc.id,
      deadline = Active[src].deadline,
    })
  else
    TriggerClientEvent(UbEvent('client:heistSync'), src, {
      phase = 'entry',
      scenario_id = sc.id,
      minigame = entry,
      deadline = Active[src].deadline,
    })
  end
end)

RegisterNetEvent(UbEvent('server:confirmEntry'), function(ok)
  local src = source
  local st = Active[src]
  if not st or st.phase ~= 'entry' then
    return
  end
  if not ok then
    fail(src, 'entry_failed')
    return
  end
  st.phase = 'combat'
  st.deadline = os.time() + (ScenarioById[st.scenario_id].time_limit_sec or 600)
  TriggerClientEvent(UbEvent('client:heistSync'), src, {
    phase = 'combat',
    scenario_id = st.scenario_id,
    deadline = st.deadline,
  })
end)

RegisterNetEvent(UbEvent('server:npcSpawnFailed'), function()
  local src = source
  fail(src, 'spawn_failed')
end)

RegisterNetEvent(UbEvent('server:completeCombat'), function()
  local src = source
  local st = Active[src]
  if not st or st.phase ~= 'combat' then
    return
  end
  if os.time() > (st.deadline or 0) then
    fail(src, 'timeout')
    return
  end
  succeed(src)
end)

function UbCancelHeist(src)
  if Active[src] then
    Active[src] = nil
    TriggerClientEvent(UbEvent('client:heistEnded'), src, { reason = 'cancel' })
    Bridge.Notify(src, _L('notify_heist_cancelled'), 'info')
    UbEmitHook('onHeistFail', { target = src, reason = 'cancel' })
  end
end

RegisterNetEvent(UbEvent('server:cancelHeist'), function()
  UbCancelHeist(source)
end)

RegisterNetEvent(UbEvent('server:playerDownDuringHeist'), function()
  local src = source
  if not Active[src] then
    return
  end
  local mode = Config.OnPlayerDeathDuringHeist or 'fail'
  if mode == 'cancel' then
    Active[src] = nil
    TriggerClientEvent(UbEvent('client:heistEnded'), src, { reason = 'death' })
    UbEmitHook('onHeistFail', { target = src, reason = 'death_cancel' })
  else
    fail(src, 'death')
  end
end)

function UbForceCleanupPlayer(src)
  Active[src] = nil
  if UbForceCleanupContract then
    UbForceCleanupContract(src)
  end
end

function UbExportActiveHeist(src)
  return Active[src]
end

AddEventHandler('playerDropped', function()
  local src = source
  Active[src] = nil
end)
