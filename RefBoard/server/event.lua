--[[
  交代・カード・PK（match_events + match_players 更新）
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

local function withTransaction(fn)
  MySQL.query.await('START TRANSACTION')
  local ok, err = pcall(fn)
  if ok then
    MySQL.query.await('COMMIT')
    return true, nil
  end
  MySQL.query.await('ROLLBACK')
  return false, err
end

--- NUI JSON からの id（数値／文字列）を match_players.id 用に正規化
local function parsePayloadId(v)
  if v == nil then
    return nil
  end
  if type(v) == 'number' then
    local n = math.floor(v)
    return n > 0 and n or nil
  end
  if type(v) == 'string' then
    local s = v:match('^%s*(%d+)%s*$')
    if not s then
      return nil
    end
    return tonumber(s)
  end
  return tonumber(v)
end

--- PK 戦の決着判定（先攻は matches.pk_first_team_id、なければ team1）
local function evaluatePenaltyShootout(matchId)
  matchId = tonumber(matchId)
  if not matchId then
    return { decided = false }
  end
  local m = MySQL.single.await(
    [[SELECT id, team1_id, team2_id, pk_first_team_id, current_half FROM matches WHERE id = ?]],
    { matchId }
  )
  if not m or m.current_half ~= 'pk' then
    return { decided = false }
  end
  local team1Id = tonumber(m.team1_id)
  local team2Id = tonumber(m.team2_id)
  local first = tonumber(m.pk_first_team_id) or team1Id
  local second = (first == team1Id) and team2Id or team1Id
  local rows = MySQL.query.await(
    [[SELECT team_id, penalty_success FROM match_events
      WHERE match_id = ? AND half = 'pk' AND event_type = 'penalty' AND voided_at IS NULL
      ORDER BY id ASC]],
    { matchId }
  ) or {}
  local n = #rows
  if n == 0 then
    return { decided = false, score = { team1 = 0, team2 = 0 }, kicksRemaining = 10 }
  end
  local tf, ts = 0, 0
  local g1, g2 = 0, 0
  for i, row in ipairs(rows) do
    local okp = tonumber(row.penalty_success) == 1
    if okp then
      if (i - 1) % 2 == 0 then
        tf = tf + 1
      else
        ts = ts + 1
      end
      local tid = tonumber(row.team_id)
      if tid == team1Id then
        g1 = g1 + 1
      elseif tid == team2Id then
        g2 = g2 + 1
      end
    end
  end
  local shotsFirst = math.ceil(n / 2)
  local shotsSecond = math.floor(n / 2)
  local decided = false
  local winnerTeamId = nil
  if n < 10 then
    local remFirst = 5 - shotsFirst
    local remSecond = 5 - shotsSecond
    if tf > ts + remSecond or ts > tf + remFirst then
      decided = true
      winnerTeamId = (tf > ts) and first or second
    end
  else
    if n % 2 == 0 and tf ~= ts then
      decided = true
      winnerTeamId = (tf > ts) and first or second
    end
  end
  return {
    decided = decided,
    winnerTeamId = winnerTeamId,
    score = { team1 = g1, team2 = g2 },
    kicksRemaining = math.max(0, 10 - n),
  }
end

RegisterNetEvent('refboard:event:substitute', function(payload)
  local src = source
  RefboardGuard(src, 'refboard:event:substitute:ack', 'net:event:substitute', function()
  if not RefboardRequireEdit(src) then
    TriggerClientEvent('refboard:event:substitute:ack', src, { ok = false, error = 'no_permission' })
    return
  end
  if type(payload) ~= 'table' then
    TriggerClientEvent('refboard:event:substitute:ack', src, { ok = false, error = 'bad_payload' })
    return
  end
  local matchId = tonumber(payload.matchId)
  local teamId = tonumber(payload.teamId)
  local outId = tonumber(payload.outPlayerId)
  local inId = tonumber(payload.inPlayerId)
  if not matchId or not teamId or not outId or not inId or outId == inId then
    TriggerClientEvent('refboard:event:substitute:ack', src, { ok = false, error = 'bad_args' })
    return
  end
  if not assertEditorLock(src, matchId) then
    TriggerClientEvent('refboard:event:substitute:ack', src, { ok = false, error = 'no_lock' })
    return
  end
  local license = GetPlayerIdentifierByType(src, 'license') or ''
  local name = GetPlayerName(src) or ('ID %s'):format(src)

  local okTx, txErr = withTransaction(function()
    local m = MySQL.single.await('SELECT * FROM matches WHERE id = ? FOR UPDATE', { matchId })
    if not m or m.current_half == 'pk' then
      error('bad_phase')
    end
    local outP = MySQL.single.await(
      'SELECT * FROM match_players WHERE id = ? AND match_id = ? AND team_id = ? FOR UPDATE',
      { outId, matchId, teamId }
    )
    local inP = MySQL.single.await(
      'SELECT * FROM match_players WHERE id = ? AND match_id = ? AND team_id = ? FOR UPDATE',
      { inId, matchId, teamId }
    )
    if not outP or tonumber(outP.is_active) ~= 1 then
      error('bad_out')
    end
    if not inP or tonumber(inP.is_starter) ~= 0 or tonumber(inP.is_active) ~= 1 then
      error('bad_in')
    end
    local half = eventHalfFromMatch(m.current_half)
    local mt = math.floor(RefboardMatchTimeMsFromRow(m))
    MySQL.insert.await(
      [[INSERT INTO match_events
          (match_id, event_type, team_id, player_id, assist_player_id, sub_in_player_id, sub_out_player_id,
           penalty_success, half, match_time_ms, recorded_by_license, recorded_by_name)
        VALUES (?, 'substitution', ?, NULL, NULL, ?, ?, NULL, ?, ?, ?, ?)]],
      { matchId, teamId, inId, outId, half, mt, license, name }
    )
    MySQL.update.await('UPDATE match_players SET is_active = 0 WHERE id = ?', { outId })
    MySQL.update.await('UPDATE match_players SET is_active = 1 WHERE id = ?', { inId })
  end)

  if not okTx then
    TriggerClientEvent('refboard:event:substitute:ack', src, { ok = false, error = 'tx_failed', detail = tostring(txErr) })
    return
  end
  TriggerClientEvent('refboard:event:substitute:ack', src, { ok = true })
  TriggerEvent('refboard:internal:broadcastState', matchId)
  end)
end)

RegisterNetEvent('refboard:event:issue_card', function(payload)
  local src = source
  RefboardGuard(src, 'refboard:event:issue_card:ack', 'net:event:issue_card', function()
  if not RefboardRequireEdit(src) then
    TriggerClientEvent('refboard:event:issue_card:ack', src, { ok = false, error = 'no_permission' })
    return
  end
  if type(payload) ~= 'table' then
    TriggerClientEvent('refboard:event:issue_card:ack', src, { ok = false, error = 'bad_payload' })
    return
  end
  local matchId = tonumber(payload.matchId)
  local teamId = tonumber(payload.teamId)
  local playerId = parsePayloadId(payload.playerId)
  local cardType = payload.cardType
  if not matchId or not teamId or not playerId or (cardType ~= 'yellow_card' and cardType ~= 'red_card') then
    TriggerClientEvent('refboard:event:issue_card:ack', src, { ok = false, error = 'bad_args' })
    return
  end
  if not assertEditorLock(src, matchId) then
    TriggerClientEvent('refboard:event:issue_card:ack', src, { ok = false, error = 'no_lock' })
    return
  end
  local license = GetPlayerIdentifierByType(src, 'license') or ''
  local name = GetPlayerName(src) or ('ID %s'):format(src)

  local okTx, txErr = withTransaction(function()
    local m = MySQL.single.await('SELECT * FROM matches WHERE id = ? FOR UPDATE', { matchId })
    if not m or m.current_half == 'pk' then
      error('bad_phase')
    end
    local pl = MySQL.single.await(
      'SELECT * FROM match_players WHERE id = ? AND match_id = ? AND team_id = ? FOR UPDATE',
      { playerId, matchId, teamId }
    )
    if not pl or tonumber(pl.is_active) ~= 1 then
      Logger.warn('net:event:issue_card', 'bad_player_row', {
        matchId = matchId,
        teamId = teamId,
        playerId = playerId,
        found = pl ~= nil,
        is_active = pl and tonumber(pl.is_active),
      })
      error('bad_player')
    end
    local half = eventHalfFromMatch(m.current_half)
    local mt = math.floor(RefboardMatchTimeMsFromRow(m))

    if cardType == 'yellow_card' then
      local yc = tonumber(pl.yellow_cards) or 0
      if yc >= 1 then
        error('second_yellow_confirm')
      end
      local insOk, insErr = pcall(function()
        MySQL.insert.await(
          [[INSERT INTO match_events
              (match_id, event_type, team_id, player_id, assist_player_id, sub_in_player_id, sub_out_player_id,
               penalty_success, half, match_time_ms, recorded_by_license, recorded_by_name)
            VALUES (?, 'yellow_card', ?, ?, NULL, NULL, NULL, NULL, ?, ?, ?, ?)]],
          { matchId, teamId, playerId, half, mt, license, name }
        )
      end)
      if not insOk then
        error('mysql_insert:' .. tostring(insErr))
      end
      MySQL.update.await('UPDATE match_players SET yellow_cards = yellow_cards + 1 WHERE id = ?', { playerId })
    else
      local reason = type(payload.ejectionReason) == 'string' and payload.ejectionReason or 'red_card'
      local insOkR, insErrR = pcall(function()
        MySQL.insert.await(
          [[INSERT INTO match_events
              (match_id, event_type, team_id, player_id, assist_player_id, sub_in_player_id, sub_out_player_id,
               penalty_success, half, match_time_ms, recorded_by_license, recorded_by_name)
            VALUES (?, 'red_card', ?, ?, NULL, NULL, NULL, NULL, ?, ?, ?, ?)]],
          { matchId, teamId, playerId, half, mt, license, name }
        )
      end)
      if not insOkR then
        error('mysql_insert:' .. tostring(insErrR))
      end
      MySQL.update.await(
        [[UPDATE match_players SET is_active = 0, ejected_at_ms = ?, ejection_reason = ? WHERE id = ?]],
        { os.time() * 1000, reason, playerId }
      )
    end
  end)

  if not okTx then
    local es = txErr and tostring(txErr) or ''
    if es:find('second_yellow_confirm', 1, true) then
      TriggerClientEvent('refboard:event:issue_card:ack', src, { ok = false, error = 'second_yellow_confirm' })
      return
    end
    if es:find('bad_player', 1, true) then
      TriggerClientEvent('refboard:event:issue_card:ack', src, { ok = false, error = 'bad_player' })
      return
    end
    if es:find('bad_phase', 1, true) then
      TriggerClientEvent('refboard:event:issue_card:ack', src, { ok = false, error = 'bad_phase' })
      return
    end
    if es:find('mysql_insert', 1, true) then
      local short = (#es > 240) and (string.sub(es, 1, 240) .. '...') or es
      Logger.error('net:event:issue_card', 'mysql_insert_failed', { matchId = matchId, detail = short })
      TriggerClientEvent('refboard:event:issue_card:ack', src, { ok = false, error = 'db_insert_failed', detail = short })
      return
    end
    Logger.warn('net:event:issue_card', 'transaction_failed', { matchId = matchId, detail = es })
    TriggerClientEvent('refboard:event:issue_card:ack', src, { ok = false, error = 'tx_failed', detail = es })
    return
  end

  TriggerClientEvent('refboard:event:issue_card:ack', src, { ok = true })
  TriggerEvent('refboard:internal:broadcastState', matchId)
  end)
end)

RegisterNetEvent('refboard:event:record_penalty', function(payload)
  local src = source
  RefboardGuard(src, 'refboard:event:record_penalty:ack', 'net:event:record_penalty', function()
  if not RefboardRequireEdit(src) then
    TriggerClientEvent('refboard:event:record_penalty:ack', src, { ok = false, error = 'no_permission' })
    return
  end
  if type(payload) ~= 'table' then
    TriggerClientEvent('refboard:event:record_penalty:ack', src, { ok = false, error = 'bad_payload' })
    return
  end
  local matchId = tonumber(payload.matchId)
  local teamId = tonumber(payload.teamId)
  local playerId = tonumber(payload.playerId)
  local success = payload.success == true
  if not matchId or not teamId or not playerId then
    TriggerClientEvent('refboard:event:record_penalty:ack', src, { ok = false, error = 'bad_args' })
    return
  end
  if not assertEditorLock(src, matchId) then
    TriggerClientEvent('refboard:event:record_penalty:ack', src, { ok = false, error = 'no_lock' })
    return
  end
  local license = GetPlayerIdentifierByType(src, 'license') or ''
  local name = GetPlayerName(src) or ('ID %s'):format(src)

  local okTx, txErr = withTransaction(function()
    local m = MySQL.single.await('SELECT * FROM matches WHERE id = ? FOR UPDATE', { matchId })
    if not m or m.current_half ~= 'pk' then
      error('not_pk')
    end
    local pl = MySQL.single.await(
      'SELECT * FROM match_players WHERE id = ? AND match_id = ? AND team_id = ? FOR UPDATE',
      { playerId, matchId, teamId }
    )
    if not pl then
      error('bad_player')
    end
    local mt = math.floor(RefboardMatchTimeMsFromRow(m))
    MySQL.insert.await(
      [[INSERT INTO match_events
          (match_id, event_type, team_id, player_id, assist_player_id, sub_in_player_id, sub_out_player_id,
           penalty_success, half, match_time_ms, recorded_by_license, recorded_by_name)
        VALUES (?, 'penalty', ?, ?, NULL, NULL, NULL, ?, 'pk', ?, ?, ?)]],
      { matchId, teamId, playerId, success and 1 or 0, mt, license, name }
    )
  end)

  if not okTx then
    TriggerClientEvent('refboard:event:record_penalty:ack', src, { ok = false, error = 'tx_failed', detail = tostring(txErr) })
    return
  end
  TriggerClientEvent('refboard:event:record_penalty:ack', src, { ok = true })
  TriggerEvent('refboard:internal:broadcastState', matchId)

  local pkResult = evaluatePenaltyShootout(matchId)
  if pkResult.decided then
    TriggerClientEvent('refboard:event:pk_decided', -1, {
      matchId = matchId,
      winnerTeamId = pkResult.winnerTeamId,
      finalPkScore = pkResult.score,
    })
  end
  end)
end)
