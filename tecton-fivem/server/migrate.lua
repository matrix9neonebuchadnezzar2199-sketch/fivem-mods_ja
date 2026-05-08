-- SPDX-License-Identifier: LGPL-3.0-or-later

---@diagnostic disable: undefined-global

--[[
  SQL はセミコロンで文分割しているだけなので、文字列リテラル内に `;` が含まれる
  DDL が出た場合はパーサ強化（字句解析）が必要になる可能性がある。
]]

local MIGRATIONS = {
    { version = 1, file = 'sql/migrations/001_initial.sql', description = 'initial schema' },
}

local M = {}

---@return string|nil
local function loadMigrationFile(relPath)
    local raw = LoadResourceFile(GetCurrentResourceName(), relPath)
    if not raw or raw == '' then
        print(('^1TECTON: migration file missing or empty: %s^0'):format(relPath))
        return nil
    end
    return raw
end

---@param sql string
---@return string|nil stripped or nil if unclosed block comment
local function stripBlockComments(sql)
    local out = sql
    while true do
        local s = out:find('/*', 1, true)
        if not s then
            break
        end
        local e = out:find('*/', s + 2, true)
        if not e then
            print('^1TECTON: migration parser: unclosed /* block comment^0')
            return nil
        end
        out = out:sub(1, s - 1) .. out:sub(e + 2)
    end
    return out
end

--- Semicolon split; ignores full-line `--` comments; strips trailing `--` on lines.
---@param sql string
---@return string[]
local function splitStatements(sql)
    local cleaned = stripBlockComments(sql)
    if not cleaned then
        return {}
    end
    local stmts = {}
    local buffer = cleaned .. ';'
    for part in buffer:gmatch('([^;]*);') do
        local lines = {}
        for line in part:gmatch('[^\r\n]+') do
            local t = line:match('^%s*(.-)%s*$')
            if t and t ~= '' and not t:match('^%-%-') then
                local cut = t:find('%-%-', 1, true)
                if cut then
                    t = t:sub(1, cut - 1):match('^%s*(.-)%s*$') or ''
                end
                if t ~= '' then
                    lines[#lines + 1] = t
                end
            end
        end
        local stmt = table.concat(lines, '\n'):match('^%s*(.-)%s*$')
        if stmt and stmt ~= '' then
            stmts[#stmts + 1] = stmt
        end
    end
    return stmts
end

---@return integer
local function getAppliedVersion()
    local n = MySQL.scalar.await(
        [[SELECT COUNT(*) FROM information_schema.tables
          WHERE table_schema = DATABASE() AND table_name = 'tec_schema_version']],
        {}
    )
    if (tonumber(n) or 0) == 0 then
        return 0
    end
    local row = MySQL.single.await('SELECT MAX(version) AS v FROM tec_schema_version', {})
    return tonumber(row and row.v) or 0
end

---@param migration { version: integer, file: string, description: string }
---@return boolean
local function applyMigration(migration)
    local sqlText = loadMigrationFile(migration.file)
    if not sqlText then
        return false
    end
    local statements = splitStatements(sqlText)
    if #statements == 0 then
        print(('^1TECTON: migration %s produced no executable statements^0'):format(migration.file))
        return false
    end
    for i, stmt in ipairs(statements) do
        local ok, err = pcall(function()
            MySQL.query.await(stmt, {})
        end)
        if not ok then
            print(('^1TECTON: migration %s statement %d failed^0'):format(migration.file, i))
            print(('^1TECTON: %s^0'):format(tostring(err)))
            print(('^3TECTON SQL:^0 %s'):format(stmt:sub(1, 500)))
            return false
        end
    end
    MySQL.query.await(
        'INSERT INTO tec_schema_version (version, applied_at, description) VALUES (?, NOW(), ?)',
        { migration.version, migration.description }
    )
    print(('TECTON: applied migration %03d (%s)'):format(migration.version, migration.description))
    return true
end

---@return boolean
function M.run()
    local current = getAppliedVersion()
    for _, migration in ipairs(MIGRATIONS) do
        if migration.version > current then
            if not applyMigration(migration) then
                return false
            end
            current = migration.version
        end
    end
    print(('TECTON: schema is up to date (version=%s)'):format(tostring(getAppliedVersion())))
    return true
end

Migrate = M
