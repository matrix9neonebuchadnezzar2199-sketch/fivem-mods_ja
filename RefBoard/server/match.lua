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

local function kickoffToUi(v)
  if type(v) ~= 'string' or v == '' then
    return ''
  end
  return string.sub(v, 1, 5)
end

local function fmtMinute(ms)
  local m = math.floor((tonumber(ms) or 0) / 60000)
  return string.format("%d'", m)
end

local function mapPlayerUiStatus(p)
  local ej = p.ejected_at_ms
  if ej ~= nil and tonumber(ej) and tonumber(ej) > 0 then
    return 'sent_off'
  end
  if tonumber(p.is_active) == 0 then
    return 'subbed_out'
  end
  if tonumber(p.is_starter) == 0 then
    return 'bench'
  end
  if (tonumber(p.yellow_cards) or 0) >= 2 then
    return 'warning_double'
  end
  if (tonumber(p.yellow_cards) or 0) >= 1 then
    return 'warning'
  end
  return 'playing'
end

local function getScoreBreakdown(matchId, team1Id, team2Id)
  local rows = MySQL.query.await(
    [[SELECT me.half, me.team_id,
        SUM(
          CASE
            WHEN me.half = 'pk' AND me.event_type = 'penalty' AND IFNULL(me.penalty_success, 0) = 1 THEN 1
            WHEN me.half <> 'pk' AND me.event_type IN ('goal', 'own_goal') THEN 1
            ELSE 0
          END
        ) AS goals
      FROM match_events me
      WHERE me.match_id = ? AND me.voided_at IS NULL
      GROUP BY me.half, me.team_id]],
    { matchId }
  ) or {}
  local b = {
    firstHalf = { home = 0, away = 0 },
    secondHalf = { home = 0, away = 0 },
    extra = { home = 0, away = 0 },
    pk = { home = 0, away = 0 },
  }
  for _, row in ipairs(rows) do
    local h = row.half
    local key
    if h == '1st' then
      key = 'firstHalf'
    elseif h == '2nd' then
      key = 'secondHalf'
    elseif h == 'et' then
      key = 'extra'
    elseif h == 'pk' then
      key = 'pk'
    else
      key = nil
    end
    if key then
      local tid = tonumber(row.team_id)
      local side = (tid == tonumber(team1Id)) and 'home' or 'away'
      b[key][side] = tonumber(row.goals) or 0
    end
  end
  return b
end

local function buildMatchSnapshot(matchId)
  matchId = tonumber(matchId)
  if not matchId then
    return nil
  end
  local m = MySQL.single.await(
    [[SELECT m.*, t1.name AS team1_name, t2.name AS team2_name
      FROM matches m
      INNER JOIN teams t1 ON t1.id = m.team1_id
      INNER JOIN teams t2 ON t2.id = m.team2_id
      WHERE m.id = ?]],
    { matchId }
  )
  if not m then
    return nil
  end
  local pRows = MySQL.query.await(
    [[SELECT id, match_id, team_id, server_id, license, player_name, jersey_number,
             position, is_starter, is_active, yellow_cards, ejected_at_ms, ejection_reason
      FROM match_players WHERE match_id = ? ORDER BY team_id, jersey_number, id]],
    { matchId }
  ) or {}
  local eRows = MySQL.query.await(
    [[SELECT e.id, e.event_type, e.team_id, e.half, e.match_time_ms, e.player_id, e.assist_player_id,
             e.sub_in_player_id, e.sub_out_player_id, e.penalty_success,
             p.player_name AS scorer_name, p.jersey_number AS scorer_no,
             ap.player_name AS assist_name, ap.jersey_number AS assist_no,
             pin.player_name AS sub_in_name, pin.jersey_number AS sub_in_no,
             pout.player_name AS sub_out_name, pout.jersey_number AS sub_out_no
      FROM match_events e
      LEFT JOIN match_players p ON p.id = e.player_id
      LEFT JOIN match_players ap ON ap.id = e.assist_player_id
      LEFT JOIN match_players pin ON pin.id = e.sub_in_player_id
      LEFT JOIN match_players pout ON pout.id = e.sub_out_player_id
      WHERE e.match_id = ? AND e.voided_at IS NULL
      ORDER BY e.id DESC]],
    { matchId }
  ) or {}
  local hRows = MySQL.query.await(
    [[SELECT id, team1_score, team2_score, action, reason, changed_by_name, created_at
      FROM match_score_history WHERE match_id = ? ORDER BY id ASC]],
    { matchId }
  ) or {}

  local playersOut = {}
  for _, p in ipairs(pRows) do
    table.insert(playersOut, {
      id = tonumber(p.id),
      team_id = tonumber(p.team_id),
      server_id = tonumber(p.server_id),
      license = p.license,
      player_name = p.player_name,
      jersey_number = p.jersey_number ~= nil and tonumber(p.jersey_number) or nil,
      position = p.position or '',
      is_starter = tonumber(p.is_starter) or 0,
      is_active = tonumber(p.is_active) or 0,
      yellow_cards = tonumber(p.yellow_cards) or 0,
      ejected_at_ms = p.ejected_at_ms,
      ejection_reason = p.ejection_reason,
      ui_status = mapPlayerUiStatus(p),
    })
  end

  local eventsOut = {}
  for _, e in ipairs(eRows) do
    local kind = 'other'
    if e.event_type == 'goal' or e.event_type == 'own_goal' then
      kind = 'goal'
    elseif e.event_type == 'yellow_card' then
      kind = 'yellow'
    elseif e.event_type == 'red_card' then
      kind = 'red'
    elseif e.event_type == 'substitution' then
      kind = 'sub'
    elseif e.event_type == 'penalty' then
      kind = 'penalty'
    end
    local text = ''
    if e.event_type == 'goal' then
      local sn = tonumber(e.scorer_no) or 0
      text = string.format('⚽ %d %s', sn, tostring(e.scorer_name or ''))
      if e.assist_name and e.assist_name ~= '' then
        local an = tonumber(e.assist_no) or 0
        text = text .. string.format(' (assist: %d %s)', an, e.assist_name)
      end
    elseif e.event_type == 'substitution' then
      local oj = tonumber(e.sub_out_no) or 0
      local ij = tonumber(e.sub_in_no) or 0
      text = string.format('🔄 OUT %d %s → IN %d %s', oj, tostring(e.sub_out_name or ''), ij, tostring(e.sub_in_name or ''))
    elseif e.event_type == 'yellow_card' then
      local sn = tonumber(e.scorer_no) or 0
      text = string.format('🟨 %d %s', sn, tostring(e.scorer_name or ''))
    elseif e.event_type == 'red_card' then
      local sn = tonumber(e.scorer_no) or 0
      text = string.format('🟥 %d %s', sn, tostring(e.scorer_name or ''))
    elseif e.event_type == 'penalty' then
      local sn = tonumber(e.scorer_no) or 0
      local okp = tonumber(e.penalty_success) == 1
      if okp then
        text = string.format('⚽ PK 成功 %d %s', sn, tostring(e.scorer_name or ''))
      else
        text = string.format('❌ PK 失敗 %d %s', sn, tostring(e.scorer_name or ''))
      end
    else
      text = tostring(e.event_type or '')
    end
    table.insert(eventsOut, {
      id = tonumber(e.id),
      match_time_ms = tonumber(e.match_time_ms) or 0,
      event_type = e.event_type,
      half = e.half,
      minute = fmtMinute(e.match_time_ms),
      kind = kind,
      text = text,
      penalty_success = e.penalty_success,
      team_id = tonumber(e.team_id),
    })
  end

  local historyOut = {}
  for _, h in ipairs(hRows) do
    table.insert(historyOut, {
      id = tonumber(h.id),
      team1_score = tonumber(h.team1_score) or 0,
      team2_score = tonumber(h.team2_score) or 0,
      action = h.action,
      reason = h.reason,
      changed_by_name = h.changed_by_name,
      created_at = h.created_at,
    })
  end

  local breakdown = getScoreBreakdown(matchId, m.team1_id, m.team2_id)
  return {
    match = m,
    players = playersOut,
    events = eventsOut,
    history = historyOut,
    breakdown = breakdown,
  }
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

RegisterNetEvent('refboard:match:get', function(payload)
  local src = source
  if not requireReferee(src) then
    return
  end
  local matchId = payload and tonumber(payload.matchId)
  if not matchId then
    TriggerClientEvent('refboard:match:get:ack', src, { match = nil, players = {}, events = {}, history = {} })
    return
  end
  local snap = buildMatchSnapshot(matchId)
  if not snap then
    TriggerClientEvent('refboard:match:get:ack', src, { match = nil, players = {}, events = {}, history = {} })
    return
  end
  TriggerClientEvent('refboard:match:get:ack', src, snap)
end)

RegisterNetEvent('refboard:match:finish', function(payload)
  local src = source
  if not requireReferee(src) then
    return
  end
  local matchId = payload and tonumber(payload.matchId)
  if not matchId or not assertEditorLock(src, matchId) then
    TriggerClientEvent('refboard:match:finish:ack', src, { ok = false, error = 'no_lock' })
    return
  end
  local m = MySQL.single.await('SELECT id, status FROM matches WHERE id = ?', { matchId })
  if not m or m.status ~= 'draft' then
    TriggerClientEvent('refboard:match:finish:ack', src, { ok = false, error = 'bad_status' })
    return
  end
  MySQL.update.await(
    [[UPDATE matches SET status = 'finished', finished_at = NOW(),
        clock_running = 0, clock_started_at = NULL
      WHERE id = ?]],
    { matchId }
  )
  MySQL.update.await('DELETE FROM match_drafts WHERE match_id = ?', { matchId })
  TriggerClientEvent('refboard:match:finish:ack', src, { ok = true })
  TriggerClientEvent('refboard:match:finished', -1, { matchId = matchId })
end)

RegisterNetEvent('refboard:match:reopen', function(payload)
  local src = source
  if not requireReferee(src) then
    return
  end
  local matchId = payload and tonumber(payload.matchId)
  if not matchId or not assertEditorLock(src, matchId) then
    TriggerClientEvent('refboard:match:reopen:ack', src, { ok = false, error = 'no_lock' })
    return
  end
  local m = MySQL.single.await('SELECT id, status FROM matches WHERE id = ?', { matchId })
  if not m or m.status ~= 'finished' then
    TriggerClientEvent('refboard:match:reopen:ack', src, { ok = false, error = 'bad_status' })
    return
  end
  local license = GetPlayerIdentifierByType(src, 'license') or ''
  local name = GetPlayerName(src) or ('ID %s'):format(src)
  MySQL.update.await(
    [[UPDATE matches SET status = 'draft', finished_at = NULL,
        reopened_at = NOW(), reopened_by_license = ?, reopened_by_name = ?
      WHERE id = ?]],
    { license, name, matchId }
  )
  local cur = MySQL.single.await(
    'SELECT team1_score, team2_score, current_half, clock_accumulated_ms FROM matches WHERE id = ?',
    { matchId }
  )
  MySQL.insert.await(
    [[INSERT INTO match_score_history
        (match_id, team1_score, team2_score, half, match_time_ms, action, related_event_id,
         changed_by_license, changed_by_name, reason)
      VALUES (?, ?, ?, ?, ?, 'reset', NULL, ?, ?, ?)]],
    {
      matchId,
      tonumber(cur and cur.team1_score) or 0,
      tonumber(cur and cur.team2_score) or 0,
      (cur and cur.current_half) or '1st',
      tonumber(cur and cur.clock_accumulated_ms) or 0,
      license,
      name,
      'match_reopened_for_edit',
    }
  )
  TriggerClientEvent('refboard:match:reopen:ack', src, { ok = true })
  TriggerEvent('refboard:internal:broadcastState', matchId)
end)

RegisterNetEvent('refboard:match:set_half', function(payload)
  local src = source
  if not requireReferee(src) then
    return
  end
  local matchId = payload and tonumber(payload.matchId)
  local half = payload and payload.half
  if not matchId or not assertEditorLock(src, matchId) then
    TriggerClientEvent('refboard:match:set_half:ack', src, { ok = false, error = 'no_lock' })
    return
  end
  local allowed = {
    ['1st'] = true,
    ['halftime'] = true,
    ['2nd'] = true,
    ['et'] = true,
    ['pk'] = true,
  }
  if type(half) ~= 'string' or not allowed[half] then
    TriggerClientEvent('refboard:match:set_half:ack', src, { ok = false, error = 'bad_half' })
    return
  end
  if half == 'pk' then
    local m0 = MySQL.single.await('SELECT team1_id, team2_id FROM matches WHERE id = ?', { matchId })
    if not m0 then
      TriggerClientEvent('refboard:match:set_half:ack', src, { ok = false, error = 'no_match' })
      return
    end
    local t1 = tonumber(m0.team1_id)
    local t2 = tonumber(m0.team2_id)
    local pkFirst = payload.pkFirstTeamId and tonumber(payload.pkFirstTeamId) or t1
    if pkFirst ~= t1 and pkFirst ~= t2 then
      pkFirst = t1
    end
    MySQL.update.await(
      [[UPDATE matches SET current_half = ?, pk_first_team_id = ?, updated_at = CURRENT_TIMESTAMP
        WHERE id = ?]],
      { half, pkFirst, matchId }
    )
  else
    MySQL.update.await(
      'UPDATE matches SET current_half = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
      { half, matchId }
    )
  end
  TriggerClientEvent('refboard:match:set_half:ack', src, { ok = true })
  TriggerEvent('refboard:internal:broadcastState', matchId)
end)

AddEventHandler('refboard:internal:broadcastState', function(matchId)
  local snap = buildMatchSnapshot(matchId)
  if not snap or not snap.match then
    return
  end
  TriggerClientEvent('refboard:match:state', -1, {
    matchId = tonumber(matchId),
    team1_score = tonumber(snap.match.team1_score) or 0,
    team2_score = tonumber(snap.match.team2_score) or 0,
    status = snap.match.status,
    current_half = snap.match.current_half,
    pk_first_team_id = snap.match.pk_first_team_id,
    breakdown = snap.breakdown,
    events = snap.events,
    players = snap.players,
    history = snap.history,
  })
end)
