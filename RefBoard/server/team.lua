--[[
  チーム一覧（試合作成用）＋チーム管理（v0.5.0）＋ロスター
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

RegisterNetEvent('refboard:team:list', function()
  local src = source
  if not canRefer(src) then
    TriggerClientEvent('refboard:team:list:ack', src, { teams = {} })
    return
  end
  local rows = MySQL.query.await(
    [[SELECT id, name, short_name, color, emblem_emoji FROM teams WHERE deleted_at IS NULL ORDER BY name ASC]]
  ) or {}
  TriggerClientEvent('refboard:team:list:ack', src, { teams = rows })
end)

--- チーム管理画面用（ロスター人数・最終試合日）
RegisterNetEvent('refboard:team:manage_list', function(payload)
  local src = source
  if not requireReferee(src) then
    TriggerClientEvent('refboard:team:manage_list:ack', src, { teams = {} })
    return
  end
  local q = (payload and payload.q) or ''
  if type(q) ~= 'string' then
    q = ''
  end
  q = q:match('^%s*(.-)%s*$') or ''
  local rows
  if q == '' then
    rows = MySQL.query.await(
      [[SELECT t.id, t.name, t.short_name, t.color, t.emblem_emoji,
          (SELECT COUNT(*) FROM team_roster r WHERE r.team_id = t.id AND r.left_at IS NULL) AS roster_count,
          (SELECT MAX(m.match_date) FROM matches m
            WHERE (m.team1_id = t.id OR m.team2_id = t.id)) AS last_match_date
        FROM teams t
        WHERE t.deleted_at IS NULL
        ORDER BY t.name ASC]],
      {}
    ) or {}
  else
    local like = '%' .. q:gsub('%%', '\\%%'):gsub('_', '\\_') .. '%'
    rows = MySQL.query.await(
      [[SELECT t.id, t.name, t.short_name, t.color, t.emblem_emoji,
          (SELECT COUNT(*) FROM team_roster r WHERE r.team_id = t.id AND r.left_at IS NULL) AS roster_count,
          (SELECT MAX(m.match_date) FROM matches m
            WHERE (m.team1_id = t.id OR m.team2_id = t.id)) AS last_match_date
        FROM teams t
        WHERE t.deleted_at IS NULL AND t.name LIKE ? ESCAPE '\\'
        ORDER BY t.name ASC]],
      { like }
    ) or {}
  end
  TriggerClientEvent('refboard:team:manage_list:ack', src, { teams = rows })
end)

RegisterNetEvent('refboard:team:detail', function(payload)
  local src = source
  if not requireReferee(src) then
    TriggerClientEvent('refboard:team:detail:ack', src, { team = nil, stats = nil })
    return
  end
  local id = payload and tonumber(payload.teamId)
  if not id then
    TriggerClientEvent('refboard:team:detail:ack', src, { team = nil, stats = nil })
    return
  end
  local team = MySQL.single.await(
    [[SELECT id, name, short_name, color, emblem_emoji, created_at
      FROM teams WHERE id = ? AND deleted_at IS NULL]],
    { id }
  )
  if not team then
    TriggerClientEvent('refboard:team:detail:ack', src, { team = nil, stats = nil })
    return
  end
  local stats = MySQL.single.await(
    [[SELECT
        COUNT(DISTINCT m.id) AS matches_played,
        SUM(CASE
          WHEN (m.team1_id = ? AND m.team1_score > m.team2_score)
            OR (m.team2_id = ? AND m.team2_score > m.team1_score) THEN 1 ELSE 0 END) AS wins,
        SUM(CASE WHEN m.team1_score = m.team2_score THEN 1 ELSE 0 END) AS draws,
        SUM(CASE
          WHEN (m.team1_id = ? AND m.team1_score < m.team2_score)
            OR (m.team2_id = ? AND m.team2_score < m.team1_score) THEN 1 ELSE 0 END) AS losses,
        SUM(CASE WHEN m.team1_id = ? THEN m.team1_score ELSE m.team2_score END) AS goals_for,
        SUM(CASE WHEN m.team1_id = ? THEN m.team2_score ELSE m.team1_score END) AS goals_against
      FROM matches m
      WHERE m.status = 'finished' AND (m.team1_id = ? OR m.team2_id = ?)]],
    { id, id, id, id, id, id, id, id }
  )
  TriggerClientEvent('refboard:team:detail:ack', src, { team = team, stats = stats })
end)

RegisterNetEvent('refboard:team:create', function(payload)
  local src = source
  if not requireReferee(src) then
    TriggerClientEvent('refboard:team:create:ack', src, { ok = false, error = 'no_permission' })
    return
  end
  if type(payload) ~= 'table' then
    TriggerClientEvent('refboard:team:create:ack', src, { ok = false, error = 'bad_payload' })
    return
  end
  local name = payload.name
  if type(name) ~= 'string' or name:gsub('%s+', '') == '' then
    TriggerClientEvent('refboard:team:create:ack', src, { ok = false, error = 'bad_name' })
    return
  end
  local shortName = type(payload.shortName) == 'string' and payload.shortName or nil
  local color = type(payload.color) == 'string' and payload.color or nil
  local emblem = type(payload.emblemEmoji) == 'string' and payload.emblemEmoji or nil
  if emblem == '' then
    emblem = nil
  end
  local license = GetPlayerIdentifierByType(src, 'license') or ''
  local pname = GetPlayerName(src) or ('ID %s'):format(src)
  local ins = MySQL.insert.await(
    [[INSERT INTO teams (name, short_name, color, emblem_emoji, created_by_license, created_by_name)
      VALUES (?, ?, ?, ?, ?, ?)]],
    { name, shortName, color, emblem, license, pname }
  )
  if not ins then
    TriggerClientEvent('refboard:team:create:ack', src, { ok = false, error = 'insert_failed' })
    return
  end
  TriggerClientEvent('refboard:team:create:ack', src, { ok = true, teamId = ins })
end)

RegisterNetEvent('refboard:team:update', function(payload)
  local src = source
  if not requireReferee(src) then
    TriggerClientEvent('refboard:team:update:ack', src, { ok = false, error = 'no_permission' })
    return
  end
  if type(payload) ~= 'table' then
    TriggerClientEvent('refboard:team:update:ack', src, { ok = false, error = 'bad_payload' })
    return
  end
  local id = tonumber(payload.teamId)
  local name = payload.name
  if not id or type(name) ~= 'string' or name:gsub('%s+', '') == '' then
    TriggerClientEvent('refboard:team:update:ack', src, { ok = false, error = 'bad_args' })
    return
  end
  local shortName = type(payload.shortName) == 'string' and payload.shortName or nil
  local color = type(payload.color) == 'string' and payload.color or nil
  local emblem = type(payload.emblemEmoji) == 'string' and payload.emblemEmoji or nil
  if emblem == '' then
    emblem = nil
  end
  local n = MySQL.update.await(
    [[UPDATE teams SET name = ?, short_name = ?, color = ?, emblem_emoji = ?
      WHERE id = ? AND deleted_at IS NULL]],
    { name, shortName, color, emblem, id }
  )
  if not n or tonumber(n) < 1 then
    TriggerClientEvent('refboard:team:update:ack', src, { ok = false, error = 'not_found' })
    return
  end
  TriggerClientEvent('refboard:team:update:ack', src, { ok = true })
end)

RegisterNetEvent('refboard:team:delete', function(payload)
  local src = source
  if not requireReferee(src) then
    TriggerClientEvent('refboard:team:delete:ack', src, { ok = false, error = 'no_permission' })
    return
  end
  local id = payload and tonumber(payload.teamId)
  if not id then
    TriggerClientEvent('refboard:team:delete:ack', src, { ok = false, error = 'bad_args' })
    return
  end
  local n = MySQL.update.await('UPDATE teams SET deleted_at = NOW() WHERE id = ? AND deleted_at IS NULL', { id })
  if not n or tonumber(n) < 1 then
    TriggerClientEvent('refboard:team:delete:ack', src, { ok = false, error = 'not_found' })
    return
  end
  TriggerClientEvent('refboard:team:delete:ack', src, { ok = true })
end)

RegisterNetEvent('refboard:team:roster:list', function(payload)
  local src = source
  if not requireReferee(src) then
    TriggerClientEvent('refboard:team:roster:list:ack', src, { rows = {} })
    return
  end
  local teamId = payload and tonumber(payload.teamId)
  if not teamId then
    TriggerClientEvent('refboard:team:roster:list:ack', src, { rows = {} })
    return
  end
  local rows = MySQL.query.await(
    [[SELECT r.id, r.team_id, r.player_name, r.jersey_number, r.position, r.license, r.joined_at,
        (SELECT COUNT(DISTINCT mp.match_id) FROM match_players mp
          INNER JOIN matches m ON m.id = mp.match_id AND m.status = 'finished'
          WHERE mp.team_id = r.team_id AND mp.player_name = r.player_name
            AND (mp.jersey_number <=> r.jersey_number)) AS matches_played,
        (SELECT COUNT(*) FROM match_events e
          INNER JOIN match_players mp ON mp.id = e.player_id AND mp.match_id = e.match_id
          INNER JOIN matches m ON m.id = e.match_id AND m.status = 'finished'
          WHERE e.voided_at IS NULL AND e.event_type = 'goal' AND mp.team_id = r.team_id
            AND mp.player_name = r.player_name AND (mp.jersey_number <=> r.jersey_number)) AS goals,
        (SELECT COUNT(*) FROM match_events e
          INNER JOIN match_players mp ON mp.id = e.player_id AND mp.match_id = e.match_id
          INNER JOIN matches m ON m.id = e.match_id AND m.status = 'finished'
          WHERE e.voided_at IS NULL AND e.event_type = 'yellow_card' AND mp.team_id = r.team_id
            AND mp.player_name = r.player_name AND (mp.jersey_number <=> r.jersey_number)) AS yellows,
        (SELECT COUNT(*) FROM match_events e
          INNER JOIN match_players mp ON mp.id = e.player_id AND mp.match_id = e.match_id
          INNER JOIN matches m ON m.id = e.match_id AND m.status = 'finished'
          WHERE e.voided_at IS NULL AND e.event_type = 'red_card' AND mp.team_id = r.team_id
            AND mp.player_name = r.player_name AND (mp.jersey_number <=> r.jersey_number)) AS reds
      FROM team_roster r
      WHERE r.team_id = ? AND r.left_at IS NULL
      ORDER BY r.jersey_number IS NULL, r.jersey_number, r.id]],
    { teamId }
  ) or {}
  TriggerClientEvent('refboard:team:roster:list:ack', src, { rows = rows })
end)

RegisterNetEvent('refboard:team:roster:add', function(payload)
  local src = source
  if not requireReferee(src) then
    TriggerClientEvent('refboard:team:roster:add:ack', src, { ok = false, error = 'no_permission' })
    return
  end
  if type(payload) ~= 'table' then
    TriggerClientEvent('refboard:team:roster:add:ack', src, { ok = false, error = 'bad_payload' })
    return
  end
  local teamId = tonumber(payload.teamId)
  local playerName = payload.playerName
  if not teamId or type(playerName) ~= 'string' or playerName:gsub('%s+', '') == '' then
    TriggerClientEvent('refboard:team:roster:add:ack', src, { ok = false, error = 'bad_args' })
    return
  end
  local exists = MySQL.scalar.await('SELECT id FROM teams WHERE id = ? AND deleted_at IS NULL', { teamId })
  if not exists then
    TriggerClientEvent('refboard:team:roster:add:ack', src, { ok = false, error = 'team_not_found' })
    return
  end
  local jerseyNumber = payload.jerseyNumber ~= nil and tonumber(payload.jerseyNumber) or nil
  local position = payload.position
  if position ~= nil and type(position) ~= 'string' then
    position = nil
  end
  local license = payload.license
  if license ~= nil and type(license) ~= 'string' then
    license = nil
  end
  if license == '' then
    license = nil
  end
  local ins = MySQL.insert.await(
    [[INSERT INTO team_roster (team_id, player_name, jersey_number, position, license)
      VALUES (?, ?, ?, ?, ?)]],
    { teamId, playerName, jerseyNumber, position, license }
  )
  if not ins then
    TriggerClientEvent('refboard:team:roster:add:ack', src, { ok = false, error = 'insert_failed' })
    return
  end
  TriggerClientEvent('refboard:team:roster:add:ack', src, { ok = true, rosterId = ins })
end)

RegisterNetEvent('refboard:team:roster:update', function(payload)
  local src = source
  if not requireReferee(src) then
    TriggerClientEvent('refboard:team:roster:update:ack', src, { ok = false, error = 'no_permission' })
    return
  end
  if type(payload) ~= 'table' then
    TriggerClientEvent('refboard:team:roster:update:ack', src, { ok = false, error = 'bad_payload' })
    return
  end
  local id = tonumber(payload.rosterId)
  local teamId = tonumber(payload.teamId)
  local playerName = payload.playerName
  if not id or not teamId or type(playerName) ~= 'string' or playerName:gsub('%s+', '') == '' then
    TriggerClientEvent('refboard:team:roster:update:ack', src, { ok = false, error = 'bad_args' })
    return
  end
  local jerseyNumber = payload.jerseyNumber ~= nil and tonumber(payload.jerseyNumber) or nil
  local position = payload.position
  if position ~= nil and type(position) ~= 'string' then
    position = nil
  end
  local license = payload.license
  if license ~= nil and type(license) ~= 'string' then
    license = nil
  end
  if license == '' then
    license = nil
  end
  local n = MySQL.update.await(
    [[UPDATE team_roster SET player_name = ?, jersey_number = ?, position = ?, license = ?
      WHERE id = ? AND team_id = ? AND left_at IS NULL]],
    { playerName, jerseyNumber, position, license, id, teamId }
  )
  if not n or tonumber(n) < 1 then
    TriggerClientEvent('refboard:team:roster:update:ack', src, { ok = false, error = 'not_found' })
    return
  end
  TriggerClientEvent('refboard:team:roster:update:ack', src, { ok = true })
end)

RegisterNetEvent('refboard:team:roster:remove', function(payload)
  local src = source
  if not requireReferee(src) then
    TriggerClientEvent('refboard:team:roster:remove:ack', src, { ok = false, error = 'no_permission' })
    return
  end
  local id = payload and tonumber(payload.rosterId)
  local teamId = payload and tonumber(payload.teamId)
  if not id or not teamId then
    TriggerClientEvent('refboard:team:roster:remove:ack', src, { ok = false, error = 'bad_args' })
    return
  end
  local n = MySQL.update.await(
    'UPDATE team_roster SET left_at = NOW() WHERE id = ? AND team_id = ? AND left_at IS NULL',
    { id, teamId }
  )
  if not n or tonumber(n) < 1 then
    TriggerClientEvent('refboard:team:roster:remove:ack', src, { ok = false, error = 'not_found' })
    return
  end
  TriggerClientEvent('refboard:team:roster:remove:ack', src, { ok = true })
end)
