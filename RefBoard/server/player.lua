--[[
  選手解決・追加・オンライン一覧（設計書 2.4.4）
]]

local function canRefer(src)
  return IsPlayerAceAllowed(src, Config.RefereePermission)
end

local function requireReferee(src)
  if not canRefer(src) then
    TriggerClientEvent('refboard:notify', src, { type = 'error', key = 'no_permission' })
    return false
  end
  return true
end

local function assertEditorLock(src, matchId)
  local r = MySQL.single.await(
    'SELECT match_id, holder_server_id FROM editor_locks WHERE id = 1'
  )
  if not r or tonumber(r.holder_server_id) ~= tonumber(src) then
    return false
  end
  local mid = r.match_id and tonumber(r.match_id)
  if not mid or mid ~= tonumber(matchId) then
    return false
  end
  return true
end

RegisterNetEvent('refboard:player:online_list', function()
  local src = source
  if not requireReferee(src) then
    return
  end
  local players = {}
  for _, sidStr in ipairs(GetPlayers()) do
    local serverId = tonumber(sidStr)
    if serverId then
      local lic = GetPlayerIdentifierByType(serverId, 'license')
      table.insert(players, {
        serverId = serverId,
        name = GetPlayerName(serverId),
        license = lic,
      })
    end
  end
  TriggerClientEvent('refboard:player:online_list:ack', src, { players = players })
end)

RegisterNetEvent('refboard:player:resolve', function(payload)
  local src = source
  if not requireReferee(src) then
    return
  end
  local serverId = payload and tonumber(payload.serverId)
  if not serverId then
    TriggerClientEvent('refboard:player:resolve:ack', src, { ok = false, error = 'bad_args' })
    return
  end
  local foundName = nil
  local license = nil
  for _, sidStr in ipairs(GetPlayers()) do
    if tonumber(sidStr) == serverId then
      foundName = GetPlayerName(serverId)
      license = GetPlayerIdentifierByType(serverId, 'license')
      break
    end
  end
  if not foundName then
    TriggerClientEvent('refboard:player:resolve:ack', src, { ok = false, error = 'not_found' })
    return
  end
  TriggerClientEvent('refboard:player:resolve:ack', src, {
    ok = true,
    name = foundName,
    license = license,
  })
end)

RegisterNetEvent('refboard:player:add', function(payload)
  local src = source
  if not requireReferee(src) then
    return
  end
  if type(payload) ~= 'table' then
    TriggerClientEvent('refboard:player:add:ack', src, { ok = false, error = 'bad_payload' })
    return
  end
  local matchId = tonumber(payload.matchId)
  local teamId = tonumber(payload.teamId)
  local serverId = tonumber(payload.serverId)
  local playerName = payload.playerName
  if not matchId or not teamId or not serverId or type(playerName) ~= 'string' or playerName == '' then
    TriggerClientEvent('refboard:player:add:ack', src, { ok = false, error = 'bad_args' })
    return
  end
  if not assertEditorLock(src, matchId) then
    TriggerClientEvent('refboard:player:add:ack', src, { ok = false, error = 'no_lock' })
    return
  end

  local jerseyNumber = payload.jerseyNumber ~= nil and tonumber(payload.jerseyNumber) or nil
  local position = type(payload.position) == 'string' and payload.position or nil
  local isStarter = payload.isStarter ~= false

  local license = payload.license
  if license ~= nil and type(license) ~= 'string' then
    license = nil
  end
  if license == '' then
    license = nil
  end

  local force = payload.force == true
  if license and not force then
    local dup = MySQL.single.await(
      [[SELECT id FROM match_players
        WHERE match_id = ? AND license IS NOT NULL AND license = ? LIMIT 1]],
      { matchId, license }
    )
    if dup then
      TriggerClientEvent('refboard:player:add:ack', src, { ok = false, error = 'duplicate_license' })
      return
    end
  end

  local ins = MySQL.insert.await(
    [[INSERT INTO match_players
        (match_id, team_id, server_id, license, player_name, jersey_number, position,
         is_starter, is_active, yellow_cards)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)]],
    {
      matchId,
      teamId,
      serverId,
      license,
      playerName,
      jerseyNumber,
      position,
      isStarter and 1 or 0,
      1,
      0,
    }
  )

  if not ins then
    TriggerClientEvent('refboard:player:add:ack', src, { ok = false, error = 'insert_failed' })
    return
  end

  TriggerClientEvent('refboard:player:add:ack', src, { ok = true, playerId = ins })
  TriggerEvent('refboard:internal:broadcastState', matchId)
end)
