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

RegisterNetEvent('refboard:match:list', function(payload)
  local src = source
  if not requireReferee(src) then
    return
  end
  local status = payload and payload.status or nil
  if status == 'all' or status == '' then
    status = nil
  end
  if status and status ~= 'draft' and status ~= 'finished' and status ~= 'cancelled' then
    status = nil
  end

  local limit = tonumber(payload and payload.limit) or 50
  local offset = tonumber(payload and payload.offset) or 0
  if limit > 200 then
    limit = 200
  end

  local sql
  local params
  if status then
    sql = [[
      SELECT m.id, m.team1_id, m.team2_id, m.team1_score, m.team2_score, m.status, m.current_half,
             m.match_date, m.match_name, m.venue, m.kickoff_time,
             t1.name AS team1_name, t2.name AS team2_name
      FROM matches m
      INNER JOIN teams t1 ON t1.id = m.team1_id
      INNER JOIN teams t2 ON t2.id = m.team2_id
      WHERE m.status = ?
      ORDER BY m.updated_at DESC
      LIMIT ? OFFSET ?
    ]]
    params = { status, limit, offset }
  else
    sql = [[
      SELECT m.id, m.team1_id, m.team2_id, m.team1_score, m.team2_score, m.status, m.current_half,
             m.match_date, m.match_name, m.venue, m.kickoff_time,
             t1.name AS team1_name, t2.name AS team2_name
      FROM matches m
      INNER JOIN teams t1 ON t1.id = m.team1_id
      INNER JOIN teams t2 ON t2.id = m.team2_id
      ORDER BY m.updated_at DESC
      LIMIT ? OFFSET ?
    ]]
    params = { limit, offset }
  end

  local rows = MySQL.query.await(sql, params) or {}
  TriggerClientEvent('refboard:match:list:ack', src, { matches = rows })
end)

RegisterNetEvent('refboard:match:create', function(payload)
  local src = source
  if not requireReferee(src) then
    return
  end
  if type(payload) ~= 'table' then
    TriggerClientEvent('refboard:match:create:ack', src, { ok = false, error = 'bad_payload' })
    return
  end

  local team1Id = tonumber(payload.team1Id)
  local team2Id = tonumber(payload.team2Id)
  if not team1Id or not team2Id or team1Id == team2Id then
    TriggerClientEvent('refboard:match:create:ack', src, { ok = false, error = 'bad_teams' })
    return
  end

  local cnt = MySQL.scalar.await(
    'SELECT COUNT(1) FROM teams WHERE deleted_at IS NULL AND id IN (?, ?)',
    { team1Id, team2Id }
  ) or 0
  if tonumber(cnt) ~= 2 then
    TriggerClientEvent('refboard:match:create:ack', src, { ok = false, error = 'team_not_found' })
    return
  end

  local matchName = payload.matchName
  local venue = payload.venue
  local matchDate = payload.matchDate
  local kickoffTime = payload.kickoffTime
  if type(matchName) ~= 'string' then
    matchName = nil
  end
  if type(venue) ~= 'string' then
    venue = nil
  end
  if type(matchDate) ~= 'string' or matchDate == '' then
    TriggerClientEvent('refboard:match:create:ack', src, { ok = false, error = 'bad_date' })
    return
  end
  if kickoffTime ~= nil and type(kickoffTime) ~= 'string' then
    kickoffTime = nil
  end
  if kickoffTime == '' then
    kickoffTime = nil
  end

  local license = GetPlayerIdentifierByType(src, 'license') or ''
  local name = GetPlayerName(src) or ('ID %s'):format(src)

  local matchId = MySQL.insert.await(
    [[INSERT INTO matches
        (team1_id, team2_id, team1_score, team2_score, status, current_half,
         clock_running, clock_started_at, clock_accumulated_ms, match_date,
         match_name, venue, kickoff_time, created_by_license, created_by_name)
      VALUES (?, ?, 0, 0, 'draft', '1st', 0, NULL, 0, ?, ?, ?, ?, ?, ?)]],
    {
      team1Id,
      team2Id,
      matchDate,
      matchName,
      venue,
      kickoffTime,
      license,
      name,
    }
  )

  if not matchId then
    TriggerClientEvent('refboard:match:create:ack', src, { ok = false, error = 'insert_failed' })
    return
  end

  MySQL.insert.await(
    [[INSERT INTO match_score_history
        (match_id, team1_score, team2_score, half, match_time_ms, action, related_event_id,
         changed_by_license, changed_by_name, reason)
      VALUES (?, 0, 0, '1st', 0, 'reset', NULL, ?, ?, ?)]],
    { matchId, license, name, 'match_created' }
  )

  TriggerClientEvent('refboard:match:create:ack', src, { ok = true, matchId = matchId })
end)
