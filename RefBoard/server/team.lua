local function canRefer(src)
  return IsPlayerAceAllowed(src, Config.RefereePermission)
end

RegisterNetEvent('refboard:team:list', function()
  local src = source
  if not canRefer(src) then
    return
  end
  local rows = MySQL.query.await(
    [[SELECT id, name, short_name, color FROM teams WHERE deleted_at IS NULL ORDER BY name ASC]]
  ) or {}
  TriggerClientEvent('refboard:team:list:ack', src, { teams = rows })
end)
