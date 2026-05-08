--[[
  実機テスト前: 環境・DB・権限のヘルスチェック
]]

local EXPECTED_TABLES = {
  'teams',
  'matches',
  'match_players',
  'team_roster',
  'match_events',
  'match_score_history',
  'match_drafts',
  'editor_locks',
  'tournaments',
  'tournament_matches',
}

local function push(results, category, name, status, detail)
  results[#results + 1] = {
    category = category,
    name = name,
    status = status,
    detail = detail or '',
    timestamp = os.time() * 1000,
  }
end

local function runChecks(src, payload)
  local results = {}
  local clientVersion = type(payload) == 'table' and payload.clientVersion or ''
  local serverVersion = GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or ''

  push(results, 'server', 'ping', 'ok', 'pong')

  if clientVersion ~= '' and serverVersion ~= '' and clientVersion ~= serverVersion then
    push(results, 'server', 'version', 'warning', ('client=%s server=%s'):format(clientVersion, serverVersion))
  else
    push(results, 'server', 'version', 'ok', ('server=%s client=%s'):format(serverVersion, clientVersion ~= '' and clientVersion or '(n/a)'))
  end

  local dbOk, dbErr = pcall(function()
    return MySQL.scalar.await('SELECT 1')
  end)
  if dbOk and tonumber(dbErr) == 1 then
    push(results, 'db', 'connection', 'ok', 'connected')
  else
    push(results, 'db', 'connection', 'error', tostring(dbErr))
  end

  local schemaOk, schemaRows = pcall(function()
    local placeholders = {}
    local args = {}
    for i, tn in ipairs(EXPECTED_TABLES) do
      placeholders[i] = '?'
      args[i] = tn
    end
    return MySQL.query.await(
      ([[SELECT TABLE_NAME FROM information_schema.tables
        WHERE table_schema = DATABASE() AND TABLE_NAME IN (%s)]]):format(table.concat(placeholders, ',')),
      args
    )
  end)
  if schemaOk and type(schemaRows) == 'table' then
    local n = #schemaRows
    local want = #EXPECTED_TABLES
    if n >= want then
      push(results, 'db', 'schema', 'ok', ('found %d/%d tables'):format(n, want))
    else
      push(results, 'db', 'schema', 'warning', ('found %d/%d tables'):format(n, want))
    end
  else
    push(results, 'db', 'schema', 'error', tostring(schemaRows))
  end

  local rosterOk = false
  if schemaOk and type(schemaRows) == 'table' then
    for _, row in ipairs(schemaRows) do
      if row.TABLE_NAME == 'team_roster' then
        rosterOk = true
        break
      end
    end
  end
  push(results, 'db', 'migration_roster', rosterOk and 'ok' or 'warning', rosterOk and 'team_roster present' or 'team_roster missing (run migration_004)')

  local license = GetPlayerIdentifierByType(src, 'license')
  if license and license ~= '' then
    local disp = license
    if #disp > 28 then
      disp = disp:sub(1, 28) .. '…'
    end
    push(results, 'auth', 'license', 'ok', disp)
  else
    push(results, 'auth', 'license', 'error', 'license not found')
  end

  local editOk = RefboardIsEditApproved and RefboardIsEditApproved(src)
  if editOk then
    push(results, 'auth', 'edit_password', 'ok', 'edit mode (password verified)')
  else
    push(results, 'auth', 'edit_password', 'warning', 'view or edit password not verified')
  end

  local inPresence = RefboardPresenceHasSession and RefboardPresenceHasSession(src)
  if inPresence then
    push(results, 'presence', 'self_registration', 'ok', 'registered')
  else
    push(results, 'presence', 'self_registration', 'warning', 'not registered (session enter 未)')
  end

  local lockOk, lockRow = pcall(function()
    return MySQL.single.await(
      [[SELECT holder_name, holder_server_id, UNIX_TIMESTAMP(last_heartbeat) AS lh
        FROM editor_locks WHERE id = 1]]
    )
  end)
  if lockOk and lockRow and lockRow.holder_server_id then
    local nm = lockRow.holder_name or '?'
    push(results, 'lock', 'current_editor', 'ok', ('%s (serverId=%s)'):format(nm, tostring(lockRow.holder_server_id)))
  elseif lockOk then
    push(results, 'lock', 'current_editor', 'ok', 'none')
  else
    push(results, 'lock', 'current_editor', 'error', tostring(lockRow))
  end

  push(results, 'config', 'log_level', 'ok', tostring(Config.LogLevel or 'INFO'))
  push(
    results,
    'config',
    'test_commands',
    (Config.EnableTestCommands and 'warning') or 'ok',
    Config.EnableTestCommands and 'true (Settings: dev fixture / wipe)' or 'false'
  )

  return {
    results = results,
    serverVersion = serverVersion,
    clientVersion = clientVersion,
    logLevel = Config.LogLevel or 'INFO',
    enableTestCommands = Config.EnableTestCommands == true,
  }
end

RegisterNetEvent('refboard:health:check', function(payload)
  local src = source
  local ok, err = pcall(function()
    local out = runChecks(src, payload)
    TriggerClientEvent('refboard:health:check:ack', src, out)
  end)
  if not ok then
    Logger.error('net:health:check', 'handler_failed', { err = tostring(err) })
    TriggerClientEvent('refboard:health:check:ack', src, {
      results = {
        {
          category = 'server',
          name = 'exception',
          status = 'error',
          detail = tostring(err),
          timestamp = os.time() * 1000,
        },
      },
      serverVersion = GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or '',
      clientVersion = type(payload) == 'table' and (payload.clientVersion or '') or '',
      logLevel = Config.LogLevel or 'INFO',
      enableTestCommands = Config.EnableTestCommands == true,
    })
  end
end)
