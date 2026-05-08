--[[
  起動時: 接続先 DB に RefBoard 用テーブルが無ければ sql/install.sql を自動適用する。
  既存 DB（editor_locks あり）は一切変更しない。マイグレーション専用 SQL は別途手動。
]]

local RESOURCE = GetCurrentResourceName()

--- install.sql を行コメント除去後、セミコロンで文に分割（DDL には文字列内 ; が無い前提）
local function splitInstallStatements(raw)
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

local function waitForMysql(attempts)
  local n = attempts or 20
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

local function editorLocksTableExists()
  local ok, n = pcall(function()
    return MySQL.scalar.await(
      [[SELECT COUNT(*) FROM information_schema.tables
        WHERE table_schema = DATABASE() AND table_name = ?]],
      { 'editor_locks' }
    )
  end)
  if not ok then
    return false
  end
  return tonumber(n) ~= nil and tonumber(n) > 0
end

local function runInstallSql()
  local raw = LoadResourceFile(RESOURCE, 'sql/install.sql')
  if not raw then
    Logger.error('schema_bootstrap', 'sql/install.sql を読み込めません（リソースパスを確認）', {})
    return false
  end
  local stmts = splitInstallStatements(raw)
  if #stmts == 0 then
    Logger.error('schema_bootstrap', 'install.sql から有効な文が得られませんでした', {})
    return false
  end
  for i, sql in ipairs(stmts) do
    local ok, err = pcall(function()
      MySQL.query.await(sql)
    end)
    if not ok then
      Logger.error('schema_bootstrap', 'install.sql 実行失敗', {
        index = i,
        err = tostring(err),
        preview = sql:sub(1, 160),
      })
      return false
    end
  end
  Logger.info('schema_bootstrap', 'install.sql を自動適用しました', { statements = #stmts })
  return true
end

AddEventHandler('onResourceStart', function(resName)
  if resName ~= RESOURCE then
    return
  end
  if Config.AutoCreateSchema == false then
    Logger.info('schema_bootstrap', 'Config.AutoCreateSchema が false のためスキップ', {})
    return
  end

  CreateThread(function()
    if not waitForMysql(25) then
      Logger.error('schema_bootstrap', 'MySQL に接続できません（oxmysql・接続文字列を確認）', {})
      return
    end

    if editorLocksTableExists() then
      Logger.info('schema_bootstrap', 'DB スキーマ確認済み（editor_locks あり）', {})
      return
    end

    Logger.warn('schema_bootstrap', 'editor_locks がありません。sql/install.sql を自動実行します…', {})
    runInstallSql()
  end)
end)
