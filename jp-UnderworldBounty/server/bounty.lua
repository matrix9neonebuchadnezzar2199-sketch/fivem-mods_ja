local BountyBySrc = {}

--- @param src number
--- @param scenario_id string
--- @param pattern_id string
function UbSetBounty(src, scenario_id, pattern_id)
  local pat = Config.RetaliationPatterns[pattern_id]
  if not pat then
    return
  end
  local now = os.time()
  local span = math.max(1, pat.strike_interval_max_sec - pat.strike_interval_min_sec + 1)
  local step = math.random(0, span - 1)
  BountyBySrc[src] = {
    scenario_id = scenario_id,
    pattern_id = pattern_id,
    expires_at = now + (pat.duration_sec or 3600),
    strikes_remaining = pat.max_strikes or 1,
    next_strike_at = now + (pat.strike_interval_min_sec or 60) + step,
    wave_in_progress = false,
  }
  TriggerClientEvent(UbEvent('client:bountyHud'), src, { active = true })
  UbEmitHook('onBountyTriggered', {
    target = src,
    scenarioId = scenario_id,
    patternId = pattern_id,
  })
end

--- @param src number
--- @param reason string|nil
function UbClearBounty(src, reason)
  if not BountyBySrc[src] then
    return
  end
  BountyBySrc[src] = nil
  TriggerClientEvent(UbEvent('client:bountyHud'), src, { active = false })
  UbEmitHook('onBountyCleared', { target = src, reason = reason or 'unknown' })
end

--- @param src number
--- @return table|nil
function UbGetBounty(src)
  return BountyBySrc[src]
end

CreateThread(function()
  while true do
    Wait(Config.BountyScanIntervalMs)
    local now = os.time()
    for src, st in pairs(BountyBySrc) do
      if now >= st.expires_at then
        UbClearBounty(src, 'expired')
      elseif st.strikes_remaining > 0 and not st.wave_in_progress and now >= st.next_strike_at then
        st.wave_in_progress = true
        TriggerClientEvent(UbEvent('client:openFlavor'), src, 'notify_retaliation_hint')
        TriggerClientEvent(UbEvent('client:retaliationStart'), src, {
          pattern_id = st.pattern_id,
          scenario_id = st.scenario_id,
        })
        UbEmitHook('onRetaliationStart', { target = src, patternId = st.pattern_id })
      end
    end
  end
end)

RegisterNetEvent(UbEvent('server:retaliationWaveEnd'), function(survived)
  local src = source
  local st = BountyBySrc[src]
  if not st or not st.wave_in_progress then
    return
  end
  st.wave_in_progress = false
  local pat = Config.RetaliationPatterns[st.pattern_id]
  if not survived then
    UbEmitHook('onPlayerKilled', { target = src, context = 'retaliation' })
    if pat and pat.clear_bounty_on_player_death then
      UbClearBounty(src, 'player_death')
    end
    return
  end
  UbEmitHook('onRetaliationEnd', { target = src, patternId = st.pattern_id })
  st.strikes_remaining = (st.strikes_remaining or 1) - 1
  if st.strikes_remaining <= 0 then
    UbClearBounty(src, 'strikes_done')
    return
  end
  local min_s = (pat and pat.strike_interval_min_sec) or 60
  local max_s = (pat and pat.strike_interval_max_sec) or min_s
  local span = math.max(1, max_s - min_s + 1)
  st.next_strike_at = os.time() + min_s + math.random(0, span - 1)
end)

AddEventHandler('playerDropped', function()
  local src = source
  BountyBySrc[src] = nil
end)
