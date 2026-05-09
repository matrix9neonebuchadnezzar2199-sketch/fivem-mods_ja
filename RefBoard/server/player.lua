--[[
  選手解決・追加・オンライン一覧（設計書 2.4.4）
]]

RegisterNetEvent('refboard:player:online_list', function()
  local src = source
  if not RefboardRequireEdit(src) then
    TriggerClientEvent('refboard:player:online_list:ack', src, { players = {} })
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
  if not RefboardRequireEdit(src) then
    TriggerClientEvent('refboard:player:resolve:ack', src, { ok = false, error = 'no_permission' })
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
  RefboardGuard(src, 'refboard:player:add:ack', 'net:player:add', function()
  if not RefboardRequireEdit(src) then
    TriggerClientEvent('refboard:player:add:ack', src, { ok = false, error = 'no_permission' })
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
  if not RefboardAssertEditorLockForMatch(src, matchId) then
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
      TriggerClientEvent('refboard:player:add:ack', src, MakeError(ErrorCodes.DUPLICATE_LICENSE))
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
end)

RegisterNetEvent('refboard:player:add_from_roster', function(payload)
  local src = source
  RefboardGuard(src, 'refboard:player:add_from_roster:ack', 'net:player:add_from_roster', function()
  if not RefboardRequireEdit(src) then
    TriggerClientEvent('refboard:player:add_from_roster:ack', src, { ok = false, error = 'no_permission' })
    return
  end
  if type(payload) ~= 'table' then
    TriggerClientEvent('refboard:player:add_from_roster:ack', src, { ok = false, error = 'bad_payload' })
    return
  end
  local matchId = tonumber(payload.matchId)
  local teamId = tonumber(payload.teamId)
  local rosterId = tonumber(payload.rosterId)
  if not matchId or not teamId or not rosterId then
    TriggerClientEvent('refboard:player:add_from_roster:ack', src, { ok = false, error = 'bad_args' })
    return
  end
  if not RefboardAssertEditorLockForMatch(src, matchId) then
    TriggerClientEvent('refboard:player:add_from_roster:ack', src, { ok = false, error = 'no_lock' })
    return
  end

  local r = MySQL.single.await(
    [[SELECT id, team_id, player_name, jersey_number, position, license
      FROM team_roster WHERE id = ? AND team_id = ? AND left_at IS NULL]],
    { rosterId, teamId }
  )
  if not r then
    TriggerClientEvent('refboard:player:add_from_roster:ack', src, { ok = false, error = 'roster_not_found' })
    return
  end

  local license = r.license
  if license == '' then
    license = nil
  end

  local serverId = tonumber(payload.serverId)
  if not serverId or serverId < 1 then
    serverId = nil
    if license then
      for _, sidStr in ipairs(GetPlayers()) do
        local sid = tonumber(sidStr)
        if sid then
          local lic = GetPlayerIdentifierByType(sid, 'license')
          if lic and lic == license then
            serverId = sid
            break
          end
        end
      end
    end
  end
  if not serverId then
    serverId = 0
  end

  local force = payload.force == true
  if license and not force then
    local dup = MySQL.single.await(
      [[SELECT id FROM match_players
        WHERE match_id = ? AND license IS NOT NULL AND license = ? LIMIT 1]],
      { matchId, license }
    )
    if dup then
      TriggerClientEvent('refboard:player:add_from_roster:ack', src, MakeError(ErrorCodes.DUPLICATE_LICENSE))
      return
    end
  end

  local position = r.position
  local isStarter = payload.isStarter ~= false

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
      r.player_name,
      r.jersey_number,
      position,
      isStarter and 1 or 0,
      1,
      0,
    }
  )

  if not ins then
    TriggerClientEvent('refboard:player:add_from_roster:ack', src, { ok = false, error = 'insert_failed' })
    return
  end

  TriggerClientEvent('refboard:player:add_from_roster:ack', src, { ok = true, playerId = ins })
  TriggerEvent('refboard:internal:broadcastState', matchId)
  end)
end)

RegisterNetEvent('refboard:player:remove', function(payload)
  local src = source
  RefboardGuard(src, 'refboard:player:remove:ack', 'net:player:remove', function()
    if not RefboardRequireEdit(src) then
      TriggerClientEvent('refboard:player:remove:ack', src, { ok = false, error = 'no_permission' })
      return
    end
    if type(payload) ~= 'table' then
      TriggerClientEvent('refboard:player:remove:ack', src, MakeError(ErrorCodes.INVALID_PAYLOAD))
      return
    end
    local matchId = tonumber(payload.matchId)
    local teamId = tonumber(payload.teamId)
    local playerId = tonumber(payload.playerId)
    if not matchId or not teamId or not playerId then
      TriggerClientEvent('refboard:player:remove:ack', src, MakeError(ErrorCodes.BAD_ARGS))
      return
    end
    if not RefboardAssertEditorLockForMatch(src, matchId) then
      TriggerClientEvent('refboard:player:remove:ack', src, MakeError(ErrorCodes.NO_LOCK))
      return
    end

    local m = MySQL.single.await('SELECT status FROM matches WHERE id = ?', { matchId })
    if not m or m.status ~= 'draft' then
      TriggerClientEvent('refboard:player:remove:ack', src, MakeError(ErrorCodes.MATCH_ALREADY_FINISHED))
      return
    end

    local row = MySQL.single.await(
      'SELECT id FROM match_players WHERE id = ? AND match_id = ? AND team_id = ?',
      { playerId, matchId, teamId }
    )
    if not row then
      TriggerClientEvent('refboard:player:remove:ack', src, MakeError(ErrorCodes.PLAYER_NOT_FOUND))
      return
    end

    -- タイムラインのイベント行は残し、当該選手への FK のみ外す（試合終了まで履歴として保持）
    MySQL.update.await(
      [[UPDATE match_events SET player_id = NULL
        WHERE match_id = ? AND voided_at IS NULL AND player_id = ?]],
      { matchId, playerId }
    )
    MySQL.update.await(
      [[UPDATE match_events SET assist_player_id = NULL
        WHERE match_id = ? AND voided_at IS NULL AND assist_player_id = ?]],
      { matchId, playerId }
    )
    MySQL.update.await(
      [[UPDATE match_events SET sub_in_player_id = NULL
        WHERE match_id = ? AND voided_at IS NULL AND sub_in_player_id = ?]],
      { matchId, playerId }
    )
    MySQL.update.await(
      [[UPDATE match_events SET sub_out_player_id = NULL
        WHERE match_id = ? AND voided_at IS NULL AND sub_out_player_id = ?]],
      { matchId, playerId }
    )

    local n = MySQL.update.await(
      'DELETE FROM match_players WHERE id = ? AND match_id = ? AND team_id = ?',
      { playerId, matchId, teamId }
    )
    if not n or tonumber(n) < 1 then
      TriggerClientEvent('refboard:player:remove:ack', src, MakeError(ErrorCodes.PLAYER_NOT_FOUND))
      return
    end

    TriggerClientEvent('refboard:player:remove:ack', src, { ok = true })
    TriggerEvent('refboard:internal:broadcastState', matchId)
  end)
end)
