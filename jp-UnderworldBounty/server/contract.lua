-- 情報屋契約（受注・現地ギミック・ヤクザ戦闘・成否で報酬／指名手配）

local ContractActive = {}
local ContractCooldownUntil = {}

local function contract_cooldown_key(src)
  local ids = GetPlayerIdentifiers(src)
  for i = 1, #ids do
    local id = ids[i]
    if id:sub(1, 9) == 'license2:' or id:sub(1, 8) == 'license:' then
      return id
    end
  end
  local d = Bridge.GetPlayerData(src)
  if d and d.identifier and d.identifier ~= '' then
    return d.identifier
  end
  return 'src:' .. tostring(src)
end

local function contract_begin_cooldown(src)
  local sec = math.max(0, math.floor(Config.ContractCooldownSec or 0))
  if sec <= 0 then
    return
  end
  ContractCooldownUntil[contract_cooldown_key(src)] = os.time() + sec
end

local function contract_cooldown_left_sec(src)
  local key = contract_cooldown_key(src)
  local t = ContractCooldownUntil[key]
  if not t or t <= os.time() then
    if t then
      ContractCooldownUntil[key] = nil
    end
    return 0
  end
  return t - os.time()
end

--- @param src number
--- @return boolean
function UbHasActiveContract(src)
  return ContractActive[src] ~= nil
end

--- @param src number
function UbForceCleanupContract(src)
  if not ContractActive[src] then
    return
  end
  ContractActive[src] = nil
  TriggerClientEvent(UbEvent('client:contractEnded'), src, { reason = 'forced' })
end

local function informant_trigger()
  local ci = Config.ContractInformant
  if not ci or not ci.coords then
    return nil
  end
  return {
    coords = vector3(ci.coords.x, ci.coords.y, ci.coords.z),
    radius = ci.radius or 2.0,
  }
end

local function fail_bounty(src, reason)
  local st = ContractActive[src]
  ContractActive[src] = nil
  local scid = (Config.ContractScenarioId or 'scenario_yakuza_contract')
  local pat = Config.ContractBountyPatternId or 'dark'
  UbSetBounty(src, scid, pat)
  TriggerClientEvent(UbEvent('client:contractEnded'), src, { reason = 'bounty', detail = reason })
  Bridge.Notify(src, _L('notify_bounty_set'), 'error')
  UbEmitHook('onContractFail', { target = src, reason = reason or 'bounty' })
  contract_begin_cooldown(src)
end

local function succeed_contract(src)
  local st = ContractActive[src]
  if not st then
    return
  end
  local scid = Config.ContractScenarioId or 'scenario_yakuza_contract'
  local sc = UbFindScenario(scid)
  if not sc then
    ContractActive[src] = nil
    TriggerClientEvent(UbEvent('client:contractEnded'), src, { reason = 'error' })
    contract_begin_cooldown(src)
    return
  end
  UbGrantRewards(src, sc.reward_table_id)
  Bridge.Notify(src, _L('notify_reward_received'), 'success')
  ContractActive[src] = nil
  TriggerClientEvent(UbEvent('client:contractEnded'), src, { reason = 'success' })
  UbEmitHook('onContractComplete', { target = src, scenarioId = scid })
  contract_begin_cooldown(src)
end

RegisterNetEvent(UbEvent('server:contractAccept'), function()
  local src = source
  local cdLeft = contract_cooldown_left_sec(src)
  if cdLeft > 0 then
    local m = math.floor(cdLeft / 60)
    local s = cdLeft % 60
    Bridge.Notify(src, _L('notify_contract_cooldown', m, s), 'error')
    return
  end
  if ContractActive[src] or UbExportActiveHeist(src) then
    Bridge.Notify(src, _L('notify_heist_denied'), 'error')
    return
  end
  local trig = informant_trigger()
  if not trig or not UbIsNearTrigger(src, trig) then
    Bridge.Notify(src, _L('notify_heist_denied'), 'error')
    return
  end
  local job = Bridge.GetJob(src):lower()
  if Config.BlacklistedJobs[job] then
    Bridge.Notify(src, _L('notify_heist_denied'), 'error')
    return
  end
  if Bridge.GetCopCount() < (Config.MinOnDutyCops or 0) then
    Bridge.Notify(src, _L('notify_heist_denied'), 'error')
    return
  end
  local sites = Config.ContractSites or {}
  if #sites == 0 then
    Bridge.Notify(src, _L('notify_heist_denied'), 'error')
    return
  end
  local idx = math.random(1, #sites)
  local site = sites[idx]
  local travel = Config.ContractTravelDeadlineSec or 0
  ContractActive[src] = {
    phase = 'travel',
    site_index = idx,
    coords = site.coords,
    heading = site.heading,
    site_id = site.id,
    label_key = site.label_key,
    started = os.time(),
    deadline = travel > 0 and (os.time() + travel) or nil,
  }
  Bridge.Notify(src, _L('notify_contract_assigned', _L(site.label_key)), 'info')
  TriggerClientEvent(UbEvent('client:contractOfferSync'), src, {
    coords = { x = site.coords.x, y = site.coords.y, z = site.coords.z },
    heading = site.heading,
    label_key = site.label_key,
    deadline = ContractActive[src].deadline,
  })
  UbEmitHook('onContractStart', { target = src, siteId = site.id })
end)

RegisterNetEvent(UbEvent('server:contractCancel'), function()
  local src = source
  local st = ContractActive[src]
  if not st or st.phase ~= 'travel' then
    return
  end
  local trig = informant_trigger()
  if not trig or not UbIsNearTrigger(src, trig) then
    return
  end
  ContractActive[src] = nil
  TriggerClientEvent(UbEvent('client:contractEnded'), src, { reason = 'cancel' })
  Bridge.Notify(src, _L('notify_contract_cancelled'), 'info')
  UbEmitHook('onContractFail', { target = src, reason = 'cancel' })
end)

RegisterNetEvent(UbEvent('server:contractRequestMinigame'), function()
  local src = source
  local st = ContractActive[src]
  if not st or st.phase ~= 'travel' then
    return
  end
  if st.deadline and os.time() > st.deadline then
    Bridge.Notify(src, _L('notify_contract_deadline'), 'error')
    fail_bounty(src, 'deadline')
    return
  end
  local rad = Config.ContractSiteRadius or 2.5
  if not UbIsPlayerNearWorldCoords(src, st.coords, rad) then
    return
  end
  st.phase = 'gimmick'
  TriggerClientEvent(UbEvent('client:contractRunGimmick'), src, {})
end)

RegisterNetEvent(UbEvent('server:contractMinigameResult'), function(ok)
  local src = source
  local st = ContractActive[src]
  if not st or st.phase ~= 'gimmick' then
    return
  end
  if st.deadline and os.time() > st.deadline then
    Bridge.Notify(src, _L('notify_contract_deadline'), 'error')
    fail_bounty(src, 'deadline')
    return
  end
  local rad = Config.ContractSiteRadius or 2.5
  if not UbIsPlayerNearWorldCoords(src, st.coords, rad) then
    return
  end
  if not ok then
    Bridge.Notify(src, _L('notify_contract_gimmick_fail'), 'error')
    fail_bounty(src, 'gimmick_fail')
    return
  end
  st.phase = 'combat'
  local scid = Config.ContractScenarioId or 'scenario_yakuza_contract'
  TriggerClientEvent(UbEvent('client:contractCombatSync'), src, {
    scenario_id = scid,
    coords = { x = st.coords.x, y = st.coords.y, z = st.coords.z },
    heading = st.heading,
  })
end)

RegisterNetEvent(UbEvent('server:contractCombatComplete'), function()
  local src = source
  local st = ContractActive[src]
  if not st or st.phase ~= 'combat' then
    return
  end
  local sc = UbFindScenario(Config.ContractScenarioId or 'scenario_yakuza_contract')
  if not sc then
    ContractActive[src] = nil
    contract_begin_cooldown(src)
    return
  end
  if st.deadline and os.time() > st.deadline then
    fail_bounty(src, 'deadline')
    return
  end
  succeed_contract(src)
end)

RegisterNetEvent(UbEvent('server:contractNpcSpawnFailed'), function()
  local src = source
  if not ContractActive[src] then
    return
  end
  ContractActive[src] = nil
  TriggerClientEvent(UbEvent('client:contractEnded'), src, { reason = 'spawn_fail' })
  Bridge.Notify(src, _L('notify_contract_spawn_fail'), 'error')
  contract_begin_cooldown(src)
end)

RegisterNetEvent(UbEvent('server:contractPlayerDown'), function()
  local src = source
  local st = ContractActive[src]
  if not st or st.phase ~= 'combat' then
    return
  end
  Bridge.Notify(src, _L('notify_contract_down_bounty'), 'error')
  fail_bounty(src, 'player_down')
end)

--- @param src number
--- @param coords vector3
--- @param radius number
--- @return boolean
function UbIsPlayerNearWorldCoords(src, coords, radius)
  local ped = GetPlayerPed(src)
  if ped == 0 then
    return false
  end
  local p = GetEntityCoords(ped)
  return #(p - coords) <= (radius + 1.5)
end

AddEventHandler('playerDropped', function()
  local src = source
  ContractActive[src] = nil
end)
