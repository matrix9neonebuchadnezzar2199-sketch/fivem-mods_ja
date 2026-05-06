--[[
  スコア更新 + match_score_history（設計書 2.5.3）
]]

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

local function eventHalfFromMatch(h)
  if h == 'halftime' then
    return '1st'
  end
  if h == '1st' or h == '2nd' or h == 'et' or h == 'pk' then
    return h
  end
  return '1st'
end

local function matchTimeMs(m)
  local acc = tonumber(m.clock_accumulated_ms) or 0
  if tonumber(m.clock_running) == 1 and m.clock_started_at then
    local st = tonumber(m.clock_started_at)
    if st then
      return acc + (os.time() * 1000 - st)
    end
  end
  return acc
end

local function withTransaction(fn)
  MySQL.query.await('START TRANSACTION')
  local ok, err = pcall(fn)
  if ok then
    MySQL.query.await('COMMIT')
    return true
  end
  MySQL.query.await('ROLLBACK')
  return false, err
end

RegisterNetEvent('refboard:score:goal', function(payload)
  local src = source
  RefboardGuard(src, 'refboard:score:goal:ack', 'net:score:goal', function()
  if not RefboardRequireEdit(src) then
    TriggerClientEvent('refboard:score:goal:ack', src, MakeError(ErrorCodes.NO_PERMISSION))
    return
  end
  if type(payload) ~= 'table' then
    TriggerClientEvent('refboard:score:goal:ack', src, MakeError(ErrorCodes.INVALID_PAYLOAD))
    return
  end
  local matchId = tonumber(payload.matchId)
  local teamId = tonumber(payload.teamId)
  local scorerPlayerId = tonumber(payload.scorerPlayerId)
  local assistPlayerId = payload.assistPlayerId ~= nil and tonumber(payload.assistPlayerId) or nil
  if not matchId or not teamId or not scorerPlayerId then
    TriggerClientEvent('refboard:score:goal:ack', src, MakeError(ErrorCodes.BAD_ARGS))
    return
  end
  if not assertEditorLock(src, matchId) then
    TriggerClientEvent('refboard:score:goal:ack', src, MakeError(ErrorCodes.NO_LOCK))
    return
  end

  local license = GetPlayerIdentifierByType(src, 'license') or ''
  local name = GetPlayerName(src) or ('ID %s'):format(src)

  Logger.info('net:score:goal', 'start', { matchId = matchId, teamId = teamId, scorer = scorerPlayerId })

  local okTx = withTransaction(function()
    local m = MySQL.single.await('SELECT * FROM matches WHERE id = ? FOR UPDATE', { matchId })
    if not m then
      error('no_match')
    end
    if m.current_half == 'pk' then
      error('pk_use_penalty_flow')
    end
    local t1 = tonumber(m.team1_id)
    local t2 = tonumber(m.team2_id)
    if teamId ~= t1 and teamId ~= t2 then
      error('bad_team')
    end

    local sc = MySQL.single.await(
      'SELECT id FROM match_players WHERE id = ? AND match_id = ? AND team_id = ?',
      { scorerPlayerId, matchId, teamId }
    )
    if not sc then
      error('bad_scorer')
    end
    if assistPlayerId then
      local as = MySQL.single.await(
        'SELECT id FROM match_players WHERE id = ? AND match_id = ? AND team_id = ?',
        { assistPlayerId, matchId, teamId }
      )
      if not as then
        error('bad_assist')
      end
    end

    local s1 = tonumber(m.team1_score) or 0
    local s2 = tonumber(m.team2_score) or 0
    if teamId == t1 then
      s1 = s1 + 1
    else
      s2 = s2 + 1
    end

    local half = eventHalfFromMatch(m.current_half)
    local mt = matchTimeMs(m)

    local evId = MySQL.insert.await(
      [[INSERT INTO match_events
          (match_id, event_type, team_id, player_id, assist_player_id, half, match_time_ms,
           recorded_by_license, recorded_by_name)
        VALUES (?, 'goal', ?, ?, ?, ?, ?, ?, ?)]],
      {
        matchId,
        teamId,
        scorerPlayerId,
        assistPlayerId,
        half,
        mt,
        license,
        name,
      }
    )
    if not evId then
      error('event_insert')
    end

    MySQL.insert.await(
      [[INSERT INTO match_score_history
          (match_id, team1_score, team2_score, half, match_time_ms, action, related_event_id,
           changed_by_license, changed_by_name, reason)
        VALUES (?, ?, ?, ?, ?, 'goal', ?, ?, ?, ?)]],
      { matchId, s1, s2, half, mt, evId, license, name, 'goal_recorded' }
    )

    MySQL.update.await(
      'UPDATE matches SET team1_score = ?, team2_score = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
      { s1, s2, matchId }
    )
  end)

  if not okTx then
    Logger.warn('net:score:goal', 'tx_failed', { matchId = matchId })
    TriggerClientEvent('refboard:score:goal:ack', src, MakeError(ErrorCodes.DB_TRANSACTION_FAILED))
    return
  end

  Logger.info('net:score:goal', 'done', { matchId = matchId })
  TriggerClientEvent('refboard:score:goal:ack', src, { ok = true })
  TriggerEvent('refboard:internal:broadcastState', matchId)
  TriggerClientEvent('refboard:autosave:saved', src, {
    matchId = matchId,
    savedAt = os.time() * 1000,
  })
  end)
end)

RegisterNetEvent('refboard:score:manual_edit', function(payload)
  local src = source
  RefboardGuard(src, 'refboard:score:manual_edit:ack', 'net:score:manual_edit', function()
  if not RefboardRequireEdit(src) then
    TriggerClientEvent('refboard:score:manual_edit:ack', src, MakeError(ErrorCodes.NO_PERMISSION))
    return
  end
  if type(payload) ~= 'table' then
    TriggerClientEvent('refboard:score:manual_edit:ack', src, MakeError(ErrorCodes.INVALID_PAYLOAD))
    return
  end
  local matchId = tonumber(payload.matchId)
  local s1 = tonumber(payload.team1Score)
  local s2 = tonumber(payload.team2Score)
  local reason = payload.reason
  local reasonOk = type(reason) == 'string' and #reason >= 5
  if not matchId or s1 == nil or s2 == nil or not reasonOk then
    local errEntry = (type(reason) == 'string' and #reason < 5) and ErrorCodes.REASON_TOO_SHORT or ErrorCodes.BAD_ARGS
    TriggerClientEvent('refboard:score:manual_edit:ack', src, MakeError(errEntry))
    return
  end
  if not assertEditorLock(src, matchId) then
    TriggerClientEvent('refboard:score:manual_edit:ack', src, MakeError(ErrorCodes.NO_LOCK))
    return
  end

  local license = GetPlayerIdentifierByType(src, 'license') or ''
  local name = GetPlayerName(src) or ('ID %s'):format(src)

  Logger.info('net:score:manual_edit', 'start', { matchId = matchId, s1 = s1, s2 = s2 })

  local okTx = withTransaction(function()
    local m = MySQL.single.await('SELECT * FROM matches WHERE id = ? FOR UPDATE', { matchId })
    if not m then
      error('no_match')
    end
    local half = eventHalfFromMatch(m.current_half)
    local mt = matchTimeMs(m)

    MySQL.insert.await(
      [[INSERT INTO match_score_history
          (match_id, team1_score, team2_score, half, match_time_ms, action, related_event_id,
           changed_by_license, changed_by_name, reason)
        VALUES (?, ?, ?, ?, ?, 'manual_edit', NULL, ?, ?, ?)]],
      { matchId, s1, s2, half, mt, license, name, reason }
    )

    MySQL.update.await(
      'UPDATE matches SET team1_score = ?, team2_score = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
      { s1, s2, matchId }
    )
  end)

  if not okTx then
    Logger.warn('net:score:manual_edit', 'tx_failed', { matchId = matchId })
    TriggerClientEvent('refboard:score:manual_edit:ack', src, MakeError(ErrorCodes.DB_TRANSACTION_FAILED))
    return
  end

  Logger.info('net:score:manual_edit', 'done', { matchId = matchId })
  TriggerClientEvent('refboard:score:manual_edit:ack', src, { ok = true })
  TriggerEvent('refboard:internal:broadcastState', matchId)
  TriggerClientEvent('refboard:autosave:saved', src, {
    matchId = matchId,
    savedAt = os.time() * 1000,
  })
  end)
end)
