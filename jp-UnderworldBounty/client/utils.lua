--- @param scenario_id string
--- @return table|nil
function UbClientFindScenario(scenario_id)
  for _, s in ipairs(Config.Scenarios or {}) do
    if s.id == scenario_id then
      return s
    end
  end
  return nil
end
