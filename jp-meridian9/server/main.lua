print('[jp-meridian9] resource loaded (server)')

---@param sql string
---@return string[]
local function splitSqlStatements(sql)
    local lines = {}
    for line in sql:gmatch('[^\r\n]+') do
        local s = line
        local commentIdx = s:find('%-%-')
        if commentIdx then
            s = s:sub(1, commentIdx - 1)
        end
        lines[#lines + 1] = s
    end
    local joined = table.concat(lines, '\n')
    local stmts = {}
    for stmt in joined:gmatch('([^;]+)') do
        local trimmed = stmt:gsub('^%s+', ''):gsub('%s+$', '')
        if trimmed ~= '' then
            stmts[#stmts + 1] = trimmed
        end
    end
    return stmts
end

---@return boolean
local function autoInstallSchema()
    local resName = GetCurrentResourceName()
    local sql = LoadResourceFile(resName, 'sql/install.sql')
    if type(sql) ~= 'string' or sql == '' then
        print('[jp-meridian9] (server) [ERROR] auto-install: sql/install.sql not found in resource')
        return false
    end
    local stmts = splitSqlStatements(sql)
    if #stmts == 0 then
        print('[jp-meridian9] (server) [ERROR] auto-install: no statements parsed from sql/install.sql')
        return false
    end
    print(('[jp-meridian9] (server) auto-install: applying %d SQL statements from sql/install.sql'):format(#stmts))
    for i, stmt in ipairs(stmts) do
        local ok, err = pcall(function()
            MySQL.query.await(stmt)
        end)
        if not ok then
            print(('[jp-meridian9] (server) [ERROR] auto-install statement #%d failed: %s'):format(i, tostring(err)))
            return false
        end
    end
    return true
end

---@return boolean
local function mrd9ContractsExists()
    local cnt = MySQL.scalar.await(
        [[SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
          WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?]],
        { 'mrd9_contracts' }
    )
    return cnt ~= nil and tonumber(cnt) ~= nil and tonumber(cnt) > 0
end

CreateThread(function()
    Wait(2000)

    local ok, result = pcall(function()
        return MySQL.scalar.await('SELECT 1')
    end)
    if ok and result == 1 then
        print('[jp-meridian9] (server) oxmysql connection OK')
    else
        print('[jp-meridian9] (server) [ERROR] oxmysql connection FAILED')
        return
    end

    if mrd9ContractsExists() then
        print('[jp-meridian9] (server) schema check OK (mrd9_contracts exists)')
        return
    end

    print('[jp-meridian9] (server) [WARN] mrd9_contracts not found. Attempting auto-install...')
    local installed = autoInstallSchema()
    if not installed then
        print('[jp-meridian9] (server) [ERROR] schema auto-install failed. Apply sql/install.sql manually.')
        return
    end

    if mrd9ContractsExists() then
        print('[jp-meridian9] (server) schema auto-install OK (mrd9_contracts created)')
    else
        print('[jp-meridian9] (server) [ERROR] schema still missing after auto-install')
    end
end)

CreateThread(function()
    Wait(3000)
    -- INSTRUCTION-020 v7: Cayo Perico は専用 MAP リソース (mnr_cayo) で常時ロード。
    -- bob74_ipl は撤去（mnr_cayo と重複ロードでクラッシュするため）。
    local cayoOk = GetResourceState('mnr_cayo') == 'started'
    if cayoOk then
        print('[jp-meridian9] (server) mnr_cayo 起動確認 OK（Cayo Perico 常時ロード）')
    else
        print('[jp-meridian9] (server) [WARN] mnr_cayo 未起動。海上に Cayo Perico が表示されません。`git clone https://github.com/Monarch-Devs/mnr_cayo.git` で導入し server.cfg に ensure mnr_cayo を追加してください')
    end
end)

local function dbgChat(src, title, body)
    if src <= 0 then
        return
    end
    TriggerClientEvent('chat:addMessage', src, {
        color = { 180, 200, 255 },
        multiline = true,
        args = { title, body },
    })
end

RegisterCommand('m9_sign_me', function(source)
    if source == 0 then
        return
    end
    if not Config.Debug then
        return
    end
    local identifier = MRD9.GetIdentifier(source)
    if not identifier then
        dbgChat(source, '[MRD9]', 'identifier が取得できません')
        return
    end
    local ok = MRD9.Contract.Sign(identifier)
    dbgChat(source, '[MRD9]', ok and '契約締結成功' or '契約既に有効')
end, false)

RegisterCommand('m9_check_contract', function(source)
    if source == 0 then
        return
    end
    if not Config.Debug then
        return
    end
    local identifier = MRD9.GetIdentifier(source)
    if not identifier then
        dbgChat(source, '[MRD9]', 'identifier が取得できません')
        return
    end
    local info = MRD9.Contract.Get(identifier)
    if info then
        dbgChat(
            source,
            '[MRD9]',
            ('契約: %s / 状態: %s / 締結: %s'):format(tostring(info.identifier), tostring(info.status), tostring(info.signed_at))
        )
    else
        dbgChat(source, '[MRD9]', '契約なし')
    end
end, false)

RegisterCommand('m9_my_stats', function(source)
    if source == 0 then
        return
    end
    if not Config.Debug then
        return
    end
    local identifier = MRD9.GetIdentifier(source)
    if not identifier then
        dbgChat(source, '[MRD9]', 'identifier が取得できません')
        return
    end
    local stats = MRD9.Stats.Get(identifier)
    if stats then
        dbgChat(
            source,
            '[MRD9]',
            ('M:%d E:%d D:%d 累計$:%d'):format(
                tonumber(stats.total_missions) or 0,
                tonumber(stats.total_extracts) or 0,
                tonumber(stats.total_deaths) or 0,
                tonumber(stats.total_earnings) or 0
            )
        )
    else
        dbgChat(source, '[MRD9]', '統計なし（契約後にミッション参加してください）')
    end
end, false)

local function dbgPrintOrChat(source, body)
    if source == 0 then
        print(('[MRD9] %s'):format(body))
    else
        dbgChat(source, '[MRD9]', body)
    end
end

RegisterCommand('m9_test_session', function(source)
    if not Config.Debug then
        return
    end
    if source == 0 then
        return
    end

    local sessionId, err = MRD9.Session.Create({
        leader = source,
        members = { source },
        missionType = 'SAMPLE_RECOVERY',
        difficulty = 'NORMAL',
    })

    if not sessionId then
        dbgChat(source, '[MRD9]', 'セッション作成失敗: ' .. tostring(err or 'unknown'))
        return
    end

    dbgChat(source, '[MRD9]', 'セッション作成成功: ' .. sessionId)

    CreateThread(function()
        Wait(1000)
        local ok, terr = MRD9.Session.TransferIn(sessionId)
        if not ok then
            dbgChat(source, '[MRD9]', '転送失敗: ' .. tostring(terr or 'unknown'))
        end
    end)
end, false)

RegisterCommand('m9_test_extract', function(source)
    if not Config.Debug then
        return
    end
    if source == 0 then
        return
    end
    MRD9.Session.RemovePlayer(source, 'extracted')
    dbgChat(source, '[MRD9]', '脱出完了（テスト）')
end, false)

RegisterCommand('m9_list_sessions', function(source)
    if not Config.Debug then
        return
    end
    local all = MRD9.Session.GetAll()
    local count = 0
    for id, s in pairs(all) do
        count = count + 1
        local msg = ('id=%s bucket=%d members=%d state=%s'):format(id, s.bucket, #s.members, tostring(s.state))
        dbgPrintOrChat(source, msg)
    end
    if count == 0 then
        dbgPrintOrChat(source, 'アクティブセッションなし')
    end
end, true)

-- ============================================================
-- 運営者向けコマンド（ACE: Config.Admin.aceName）
-- ============================================================

local function adminAceName()
    return (Config.Admin and Config.Admin.aceName) or 'jp-meridian9.admin'
end

---@param source integer
---@return boolean
local function HasAdminAce(source)
    if source == 0 then
        return true
    end
    return IsPlayerAceAllowed(source, adminAceName()) == true
end

---@param source integer
---@param msg string
local function notifyAdmin(source, msg)
    if source == 0 then
        print(('[MRD9 ADMIN] %s'):format(msg))
        return
    end
    TriggerClientEvent('chat:addMessage', source, {
        color = { 200, 180, 255 },
        multiline = true,
        args = { '[MRD9 ADMIN]', msg },
    })
end

---@return integer
local function adminListLimit()
    return (Config.Admin and Config.Admin.contractListLimit) or 50
end

RegisterCommand('m9_admin_sign', function(source, args)
    if not HasAdminAce(source) then
        return
    end
    local targetId = tonumber(args[1])
    if not targetId then
        notifyAdmin(source, '使用方法: /m9_admin_sign <playerId>')
        return
    end
    local identifier = MRD9.GetIdentifier(targetId)
    if not identifier then
        notifyAdmin(source, '対象プレイヤーが見つかりません: ' .. tostring(targetId))
        return
    end
    local ok = MRD9.Contract.Sign(identifier)
    notifyAdmin(source, ok and ('契約締結: ' .. identifier) or ('既に有効: ' .. identifier))
end, true)

RegisterCommand('m9_admin_suspend', function(source, args)
    if not HasAdminAce(source) then
        return
    end
    local targetId = tonumber(args[1])
    if not targetId then
        notifyAdmin(source, '使用方法: /m9_admin_suspend <playerId> <reason>')
        return
    end
    local reason = table.concat(args, ' ', 2)
    if reason == '' then
        reason = 'no reason'
    end
    local identifier = MRD9.GetIdentifier(targetId)
    if not identifier then
        notifyAdmin(source, '対象プレイヤーが見つかりません: ' .. tostring(targetId))
        return
    end
    MRD9.Contract.Suspend(identifier, reason)
    notifyAdmin(source, ('サスペンド: %s / 理由: %s'):format(identifier, reason))
end, true)

RegisterCommand('m9_admin_terminate', function(source, args)
    if not HasAdminAce(source) then
        return
    end
    local targetId = tonumber(args[1])
    if not targetId then
        notifyAdmin(source, '使用方法: /m9_admin_terminate <playerId> <reason>')
        return
    end
    local reason = table.concat(args, ' ', 2)
    if reason == '' then
        reason = 'no reason'
    end
    local identifier = MRD9.GetIdentifier(targetId)
    if not identifier then
        notifyAdmin(source, '対象プレイヤーが見つかりません: ' .. tostring(targetId))
        return
    end
    MRD9.Contract.Terminate(identifier, reason)
    notifyAdmin(source, ('契約解除: %s / 理由: %s'):format(identifier, reason))
end, true)

RegisterCommand('m9_admin_check', function(source, args)
    if not HasAdminAce(source) then
        return
    end
    local targetId = tonumber(args[1])
    if not targetId then
        notifyAdmin(source, '使用方法: /m9_admin_check <playerId>')
        return
    end
    local identifier = MRD9.GetIdentifier(targetId)
    if not identifier then
        notifyAdmin(source, '対象プレイヤーが見つかりません: ' .. tostring(targetId))
        return
    end
    local contract = MRD9.Contract.Get(identifier)
    local stats = MRD9.Stats.Get(identifier)
    if not contract then
        notifyAdmin(source, '契約なし: ' .. identifier)
        return
    end
    notifyAdmin(
        source,
        ('契約: %s / 状態: %s / 締結: %s'):format(tostring(contract.identifier), tostring(contract.status), tostring(contract.signed_at))
    )
    if stats then
        notifyAdmin(
            source,
            ('統計: M=%d E=%d D=%d 累計$=%d'):format(
                tonumber(stats.total_missions) or 0,
                tonumber(stats.total_extracts) or 0,
                tonumber(stats.total_deaths) or 0,
                tonumber(stats.total_earnings) or 0
            )
        )
    end
    if contract.notes and contract.notes ~= '' then
        notifyAdmin(source, 'メモ: ' .. tostring(contract.notes))
    end
end, true)

RegisterCommand('m9_admin_list', function(source, args)
    if not HasAdminAce(source) then
        return
    end
    local filter = args[1]
    local lim = adminListLimit()
    local results
    if filter == 'active' or filter == 'suspended' or filter == 'terminated' then
        results = MySQL.query.await(
            'SELECT identifier, status, signed_at FROM mrd9_contracts WHERE status = ? ORDER BY signed_at DESC LIMIT ?',
            { filter, lim }
        )
    else
        results = MySQL.query.await(
            'SELECT identifier, status, signed_at FROM mrd9_contracts ORDER BY signed_at DESC LIMIT ?',
            { lim }
        )
    end
    if not results or #results == 0 then
        notifyAdmin(source, '契約者なし')
        return
    end
    notifyAdmin(source, ('=== 契約者一覧 (%d件) ==='):format(#results))
    for _, row in ipairs(results) do
        notifyAdmin(source, ('  %s [%s] %s'):format(tostring(row.identifier), tostring(row.status), tostring(row.signed_at)))
    end
end, true)

-- ============================================================
-- 対話用コールバック（INSTRUCTION-009）
-- ============================================================

lib.callback.register('jp-meridian9:server:isContracted', function(source)
    local src = source
    if not src or src <= 0 then
        return false
    end
    local identifier = MRD9.GetIdentifier(src)
    if not identifier then
        return false
    end
    return MRD9.Contract.IsContracted(identifier)
end)

lib.callback.register('jp-meridian9:server:signContract', function(source)
    local src = source
    if not src or src <= 0 then
        return false
    end
    local identifier = MRD9.GetIdentifier(src)
    if not identifier then
        return false
    end
    return MRD9.Contract.Sign(identifier)
end)
