--[[
  開発用: 全データ削除、または wipe + 5 チームロスター + 試合 20 件の疑似データ投入。
  Config.EnableTestCommands == true かつ編集モード入室済みの審判のみ。payload.confirm == 'YES' 必須。
]]

local RESOURCE = GetCurrentResourceName()

local function splitSqlStatements(raw)
  if type(raw) ~= 'string' or raw == '' then
    return {}
  end
  local normalized = raw:gsub('\r\n', '\n')
  local lines = {}
  for line in normalized:gmatch('[^\n]+') do
    local code = line:gsub('%-%-.*$', ''):gsub('%s+$', '')
    if code:match('%S') then
      lines[#lines + 1] = code
    end
  end
  local body = table.concat(lines, '\n')
  local stmts = {}
  for stmt in (body .. ';'):gmatch('(.-);') do
    local s = stmt:gsub('^%s+', ''):gsub('%s+$', '')
    if s ~= '' then
      stmts[#stmts + 1] = s
    end
  end
  return stmts
end

local function runSqlFile(relPath)
  local raw = LoadResourceFile(RESOURCE, relPath)
  if not raw or raw == '' then
    return false, ('missing_file:%s'):format(relPath)
  end
  local stmts = splitSqlStatements(raw)
  if #stmts == 0 then
    return false, 'empty_sql'
  end
  for i, sql in ipairs(stmts) do
    local ok, err = pcall(function()
      MySQL.query.await(sql)
    end)
    if not ok then
      return false, ('stmt_%d:%s'):format(i, tostring(err))
    end
  end
  return true, nil
end

local function wipeAllTables()
  MySQL.query.await('SET FOREIGN_KEY_CHECKS = 0')
  MySQL.query.await('DELETE FROM tournament_matches')
  MySQL.query.await('DELETE FROM tournaments')
  MySQL.query.await('DELETE FROM match_drafts')
  MySQL.query.await('DELETE FROM match_score_history')
  MySQL.query.await('DELETE FROM match_events')
  MySQL.query.await('DELETE FROM match_players')
  MySQL.query.await('DELETE FROM matches')
  MySQL.query.await('DELETE FROM team_roster')
  MySQL.query.await('DELETE FROM teams')
  MySQL.query.await('SET FOREIGN_KEY_CHECKS = 1')
  MySQL.update.await(
    [[UPDATE editor_locks SET match_id = NULL, holder_license = NULL, holder_name = NULL,
          holder_server_id = NULL, acquired_at = NULL, last_heartbeat = NULL WHERE id = 1]]
  )
end

local function ack(src, body)
  TriggerClientEvent('refboard:dev:data_action:ack', src, body)
end

local function validateRequest(src, payload)
  if Config.EnableTestCommands ~= true then
    ack(src, { ok = false, error = 'test_commands_disabled' })
    return false
  end
  if type(payload) ~= 'table' or payload.confirm ~= 'YES' then
    ack(src, { ok = false, error = 'bad_confirm' })
    return false
  end
  if not RefboardRequireEdit(src) then
    ack(src, { ok = false, error = 'no_permission' })
    return false
  end
  return true
end

RegisterNetEvent('refboard:dev:wipe_all', function(payload)
  local src = source
  if not validateRequest(src, payload) then
    return
  end
  local ok, err = pcall(function()
    wipeAllTables()
  end)
  if not ok then
    Logger.error('dev_data_reset', 'wipe_all_failed', { err = tostring(err) })
    ack(src, { ok = false, error = 'sql_failed', detail = tostring(err) })
    return
  end
  Logger.warn('dev_data_reset', 'wipe_all_completed', { src = src })
  ack(src, { ok = true, action = 'wipe_all' })
end)

RegisterNetEvent('refboard:dev:apply_fixture', function(payload)
  local src = source
  if not validateRequest(src, payload) then
    return
  end
  local ok, err = pcall(function()
    wipeAllTables()
    local okSeed, errSeed = runSqlFile('sql/seed_test_5teams_15roster.sql')
    if not okSeed then
      error(errSeed or 'seed_failed')
    end
    local ok20, err20 = runSqlFile('sql/dev_seed_20matches.sql')
    if not ok20 then
      error(err20 or 'matches_failed')
    end
  end)
  if not ok then
    Logger.error('dev_data_reset', 'apply_fixture_failed', { err = tostring(err) })
    ack(src, { ok = false, error = 'sql_failed', detail = tostring(err) })
    return
  end
  Logger.warn('dev_data_reset', 'apply_fixture_completed', { src = src })
  ack(src, { ok = true, action = 'apply_fixture' })
end)
