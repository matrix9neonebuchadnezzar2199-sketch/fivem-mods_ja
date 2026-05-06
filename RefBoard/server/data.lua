--[[
  集計・データ管理 API（v0.5.0）
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

RegisterNetEvent('refboard:data:team_stats', function()
  local src = source
  if not requireReferee(src) then
    return
  end
  local rows = MySQL.query.await(
    [[SELECT
        t.id, t.name, t.short_name, t.color, t.emblem_emoji,
        COUNT(DISTINCT m.id) AS matches_played,
        SUM(CASE
          WHEN (m.team1_id = t.id AND m.team1_score > m.team2_score)
            OR (m.team2_id = t.id AND m.team2_score > m.team1_score) THEN 1 ELSE 0 END) AS wins,
        SUM(CASE WHEN m.team1_score = m.team2_score THEN 1 ELSE 0 END) AS draws,
        SUM(CASE
          WHEN (m.team1_id = t.id AND m.team1_score < m.team2_score)
            OR (m.team2_id = t.id AND m.team2_score < m.team1_score) THEN 1 ELSE 0 END) AS losses,
        SUM(CASE WHEN m.team1_id = t.id THEN m.team1_score ELSE m.team2_score END) AS goals_for,
        SUM(CASE WHEN m.team1_id = t.id THEN m.team2_score ELSE m.team1_score END) AS goals_against
      FROM teams t
      LEFT JOIN matches m
        ON (m.team1_id = t.id OR m.team2_id = t.id) AND m.status = 'finished'
      WHERE t.deleted_at IS NULL
      GROUP BY t.id, t.name, t.short_name, t.color, t.emblem_emoji
      ORDER BY wins DESC, goals_for DESC]]
  ) or {}
  TriggerClientEvent('refboard:data:team_stats:ack', src, { rows = rows })
end)

RegisterNetEvent('refboard:data:player_stats', function()
  local src = source
  if not requireReferee(src) then
    return
  end
  local rows = MySQL.query.await(
    [[SELECT
        grp_key,
        MAX(player_name) AS player_name,
        MAX(has_license) AS has_license,
        COUNT(DISTINCT match_id) AS matches_played,
        COUNT(DISTINCT match_id) AS appearances,
        SUM(goals_here) AS goals,
        SUM(assists_here) AS assists,
        SUM(yellows_here) AS yellows,
        SUM(reds_here) AS reds
      FROM (
        SELECT
          IFNULL(NULLIF(TRIM(BOTH FROM mp.license), ''),
            CONCAT('__guest__|', mp.player_name, '|', IFNULL(mp.jersey_number, -1))) AS grp_key,
          mp.player_name AS player_name,
          CASE WHEN mp.license IS NULL OR TRIM(BOTH FROM mp.license) = '' THEN 0 ELSE 1 END AS has_license,
          mp.match_id AS match_id,
          (SELECT COUNT(*) FROM match_events e
            WHERE e.match_id = mp.match_id AND e.player_id = mp.id
              AND e.voided_at IS NULL AND e.event_type = 'goal') AS goals_here,
          (SELECT COUNT(*) FROM match_events e
            WHERE e.match_id = mp.match_id AND e.assist_player_id = mp.id
              AND e.voided_at IS NULL AND e.event_type = 'goal') AS assists_here,
          (SELECT COUNT(*) FROM match_events e
            WHERE e.match_id = mp.match_id AND e.player_id = mp.id
              AND e.voided_at IS NULL AND e.event_type = 'yellow_card') AS yellows_here,
          (SELECT COUNT(*) FROM match_events e
            WHERE e.match_id = mp.match_id AND e.player_id = mp.id
              AND e.voided_at IS NULL AND e.event_type = 'red_card') AS reds_here
        FROM match_players mp
        INNER JOIN matches m ON m.id = mp.match_id AND m.status = 'finished'
      ) t
      GROUP BY grp_key
      ORDER BY goals DESC, matches_played DESC]]
  ) or {}
  TriggerClientEvent('refboard:data:player_stats:ack', src, { rows = rows })
end)

RegisterNetEvent('refboard:data:score_edit_log', function(payload)
  local src = source
  if not requireReferee(src) then
    return
  end
  local from = payload and payload.from
  local to = payload and payload.to
  local editor = payload and payload.editorLicense
  if from ~= nil and type(from) ~= 'string' then
    from = nil
  end
  if from == '' then
    from = nil
  end
  if to ~= nil and type(to) ~= 'string' then
    to = nil
  end
  if to == '' then
    to = nil
  end
  if editor ~= nil and type(editor) ~= 'string' then
    editor = nil
  end
  if editor == '' then
    editor = nil
  end
  local matchId = payload and tonumber(payload.matchId)

  local wh = { 'msh.action = ?' }
  local par = { 'manual_edit' }
  if from then
    table.insert(wh, 'msh.created_at >= ?')
    table.insert(par, from)
  end
  if to then
    table.insert(wh, 'msh.created_at <= ?')
    table.insert(par, to)
  end
  if editor then
    table.insert(wh, 'msh.changed_by_license = ?')
    table.insert(par, editor)
  end
  if matchId then
    table.insert(wh, 'msh.match_id = ?')
    table.insert(par, matchId)
  end

  local sql = [[SELECT
      msh.id, msh.match_id, msh.team1_score, msh.team2_score, msh.half, msh.match_time_ms,
      msh.action, msh.reason, msh.changed_by_license, msh.changed_by_name, msh.created_at,
      m.match_date, m.match_name,
      t1.name AS team1_name, t2.name AS team2_name
    FROM match_score_history msh
    INNER JOIN matches m ON msh.match_id = m.id
    INNER JOIN teams t1 ON m.team1_id = t1.id
    INNER JOIN teams t2 ON m.team2_id = t2.id
    WHERE ]] .. table.concat(wh, ' AND ') .. [[
    ORDER BY msh.created_at DESC
    LIMIT 1000]]

  local rows = MySQL.query.await(sql, par) or {}
  TriggerClientEvent('refboard:data:score_edit_log:ack', src, { rows = rows })
end)

RegisterNetEvent('refboard:data:match_history', function(payload)
  local src = source
  if not requireReferee(src) then
    return
  end
  local status = payload and payload.status
  if status ~= 'finished' and status ~= 'cancelled' and status ~= 'draft' and status ~= 'all' then
    status = 'all'
  end
  local teamId = payload and tonumber(payload.teamId)
  local from = payload and payload.from
  local to = payload and payload.to
  if from ~= nil and type(from) ~= 'string' then
    from = nil
  end
  if from == '' then
    from = nil
  end
  if to ~= nil and type(to) ~= 'string' then
    to = nil
  end
  if to == '' then
    to = nil
  end
  local sort = payload and payload.sort
  if sort ~= 'date' and sort ~= 'spread' and sort ~= 'goals' then
    sort = 'date'
  end

  local wh = { '1=1' }
  local par = {}
  if status ~= 'all' then
    table.insert(wh, 'm.status = ?')
    table.insert(par, status)
  end
  if teamId then
    table.insert(wh, '(m.team1_id = ? OR m.team2_id = ?)')
    table.insert(par, teamId)
    table.insert(par, teamId)
  end
  if from then
    table.insert(wh, 'm.match_date >= ?')
    table.insert(par, from)
  end
  if to then
    table.insert(wh, 'm.match_date <= ?')
    table.insert(par, to)
  end

  local order
  if sort == 'spread' then
    order = 'ABS(m.team1_score - m.team2_score) DESC, m.match_date DESC'
  elseif sort == 'goals' then
    order = '(m.team1_score + m.team2_score) DESC, m.match_date DESC'
  else
    order = 'm.match_date DESC, m.updated_at DESC'
  end

  local sql = [[SELECT m.id, m.team1_id, m.team2_id, m.team1_score, m.team2_score, m.status, m.current_half,
      m.match_date, m.match_name, m.venue, m.kickoff_time,
      t1.name AS team1_name, t2.name AS team2_name
    FROM matches m
    INNER JOIN teams t1 ON t1.id = m.team1_id
    INNER JOIN teams t2 ON t2.id = m.team2_id
    WHERE ]] .. table.concat(wh, ' AND ') .. [[
    ORDER BY ]] .. order

  local rows = MySQL.query.await(sql, par) or {}
  TriggerClientEvent('refboard:data:match_history:ack', src, { rows = rows })
end)

RegisterNetEvent('refboard:data:db_meta', function()
  local src = source
  if not requireReferee(src) then
    return
  end
  TriggerClientEvent('refboard:data:db_meta:ack', src, {
    schemaVersion = '0.5.1-migration_004',
    resourceVersion = GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or '',
  })
end)
