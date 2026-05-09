--[[
  起動時:
  - Config.SeedDemoTeamsOnStart: sql/seed_test_5teams_15roster.sql（同名チーム・既存ロスターは SQL 側でスキップ）
  - Config.SeedDemoMatchesOnStart: sql/dev_seed_20matches.sql（5チーム前提・同名シード試合はスキップ）
  teams / matches テーブル作成後に走らせるため、スキーマ準備を短時間ポーリングしてから実行。
]]

local RESOURCE = GetCurrentResourceName()

local function waitForMysql(attempts)
  local n = attempts or 25
  for _ = 1, n do
    local ok = pcall(function()
      MySQL.scalar.await('SELECT 1')
    end)
    if ok then
      return true
    end
    Wait(500)
  end
  return false
end

local function teamsTableReady()
  local ok, n = pcall(function()
    return MySQL.scalar.await(
      [[SELECT COUNT(*) FROM information_schema.tables
        WHERE table_schema = DATABASE() AND table_name = ?]],
      { 'teams' }
    )
  end)
  if not ok then
    return false
  end
  return tonumber(n) ~= nil and tonumber(n) > 0
end

local function waitForTeamsTable(maxWaitMs)
  local deadline = GetGameTimer() + (maxWaitMs or 30000)
  while GetGameTimer() < deadline do
    if teamsTableReady() then
      return true
    end
    Wait(400)
  end
  return teamsTableReady()
end

local function matchesTableReady()
  local ok, n = pcall(function()
    return MySQL.scalar.await(
      [[SELECT COUNT(*) FROM information_schema.tables
        WHERE table_schema = DATABASE() AND table_name = ?]],
      { 'matches' }
    )
  end)
  if not ok then
    return false
  end
  return tonumber(n) ~= nil and tonumber(n) > 0
end

local function waitForMatchesTable(maxWaitMs)
  local deadline = GetGameTimer() + (maxWaitMs or 30000)
  while GetGameTimer() < deadline do
    if matchesTableReady() then
      return true
    end
    Wait(400)
  end
  return matchesTableReady()
end

--- schema_bootstrap と同様に行コメント除去・セミコロン分割（文字列内 ; なし前提）
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

local function runDemoSeedFromFile()
  local raw = LoadResourceFile(RESOURCE, 'sql/seed_test_5teams_15roster.sql')
  if not raw or raw == '' then
    Logger.error('demo_seed', 'sql/seed_test_5teams_15roster.sql を読み込めません', {})
    return false
  end
  local stmts = splitSqlStatements(raw)
  if #stmts == 0 then
    Logger.error('demo_seed', 'seed SQL から有効な文が得られませんでした', {})
    return false
  end
  for i, sql in ipairs(stmts) do
    local ok, err = pcall(function()
      MySQL.query.await(sql)
    end)
    if not ok then
      Logger.error('demo_seed', 'seed 文の実行に失敗', {
        index = i,
        err = tostring(err),
        preview = sql:sub(1, 120),
      })
      return false
    end
  end
  Logger.info('demo_seed', 'テスト用チーム・ロスター SQL を適用しました', { statements = #stmts })
  return true
end

local function runDemoMatchesSeedFromFile()
  local raw = LoadResourceFile(RESOURCE, 'sql/dev_seed_20matches.sql')
  if not raw or raw == '' then
    Logger.error('demo_seed', 'sql/dev_seed_20matches.sql を読み込めません', {})
    return false
  end
  local stmts = splitSqlStatements(raw)
  if #stmts == 0 then
    Logger.error('demo_seed', '試合 seed SQL から有効な文が得られませんでした', {})
    return false
  end
  for i, sql in ipairs(stmts) do
    local ok, err = pcall(function()
      MySQL.query.await(sql)
    end)
    if not ok then
      Logger.error('demo_seed', '試合 seed 文の実行に失敗', {
        index = i,
        err = tostring(err),
        preview = sql:sub(1, 120),
      })
      return false
    end
  end
  Logger.info('demo_seed', '開発用試合20件 SQL を適用しました', { statements = #stmts })
  return true
end

AddEventHandler('onResourceStart', function(resName)
  if resName ~= RESOURCE then
    return
  end
  if Config.SeedDemoTeamsOnStart ~= true and Config.SeedDemoMatchesOnStart ~= true then
    Logger.info('demo_seed', 'SeedDemoTeamsOnStart / SeedDemoMatchesOnStart とも false のためデモシードをスキップ', {})
    return
  end

  CreateThread(function()
    if not waitForMysql(30) then
      Logger.error('demo_seed', 'MySQL 接続待ちでタイムアウト（デモシード未実行）', {})
      return
    end
    if not waitForTeamsTable(45000) then
      Logger.error('demo_seed', 'teams テーブル未準備（デモシード未実行）。install / migration を確認', {})
      return
    end
    -- schema_bootstrap の install 直後と競合しうるため短い猶予
    Wait(300)
    if Config.SeedDemoTeamsOnStart == true then
      runDemoSeedFromFile()
    end
    if Config.SeedDemoMatchesOnStart ~= true then
      return
    end
    if not waitForMatchesTable(45000) then
      Logger.error('demo_seed', 'matches テーブル未準備（試合シード未実行）', {})
      return
    end
    Wait(300)
    runDemoMatchesSeedFromFile()
  end)
end)
