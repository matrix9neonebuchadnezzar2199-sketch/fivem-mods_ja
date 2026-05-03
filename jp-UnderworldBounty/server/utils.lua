--- @param src number
--- @param trigger table coords: vector3, radius: number
--- @return boolean
function UbIsNearTrigger(src, trigger)
  local ped = GetPlayerPed(src)
  if ped == 0 then
    return false
  end
  local c = GetEntityCoords(ped)
  local dist = #(c - trigger.coords)
  return dist <= (trigger.radius + 1.5)
end

--- @param scenario_id string
--- @return table|nil
function UbFindScenario(scenario_id)
  for _, s in ipairs(Config.Scenarios) do
    if s.id == scenario_id then
      return s
    end
  end
  return nil
end
