ScenarioById = ScenarioById or {}
LocationById = LocationById or {}

-- 将来: LoadResourceFile(RESOURCE, 'config/scenarios.json') を json.decode してマージ可能。

local function assert_ref(cond, msg)
  if not cond then
    print(('^1[jp-UnderworldBounty] scenario_loader: %s^0'):format(msg))
    return false
  end
  return true
end

local function validate()
  ScenarioById = {}
  LocationById = {}
  for _, s in ipairs(Config.Scenarios or {}) do
    if not assert_ref(s.id, 'scenario missing id') then
      return false
    end
    if ScenarioById[s.id] then
      return assert_ref(false, 'duplicate scenario id ' .. s.id)
    end
    ScenarioById[s.id] = s
    if not Config.RewardTables[s.reward_table_id] then
      return assert_ref(false, 'unknown reward_table_id on ' .. s.id)
    end
    if not Config.RetaliationPatterns[s.retaliation_pattern_id] then
      return assert_ref(false, 'unknown retaliation_pattern_id on ' .. s.id)
    end
  end
  for _, loc in ipairs(Config.Locations or {}) do
    if not assert_ref(loc.id, 'location missing id') then
      return false
    end
    if LocationById[loc.id] then
      return assert_ref(false, 'duplicate location id ' .. loc.id)
    end
    LocationById[loc.id] = loc
    if not loc.scenario_id or not ScenarioById[loc.scenario_id] then
      return assert_ref(false, 'location ' .. loc.id .. ' references missing scenario')
    end
  end
  return true
end

if not validate() then
  print('^1[jp-UnderworldBounty] Config validation failed; check scenarios/locations.^0')
end
