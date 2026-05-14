print('[jp-meridian9] resource loaded (server)')

CreateThread(function()
    Wait(2000)

    local ok, result = pcall(function()
        return MySQL.scalar.await('SELECT 1')
    end)
    if ok and result == 1 then
        print('[jp-meridian9] (server) oxmysql connection OK')
    else
        print('[jp-meridian9] (server) [ERROR] oxmysql connection FAILED')
    end

    local tableExists = MySQL.scalar.await(
        [[SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
          WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?]],
        { 'mrd9_contracts' }
    )
    if tableExists and tonumber(tableExists) and tonumber(tableExists) > 0 then
        print('[jp-meridian9] (server) schema check OK (mrd9_contracts exists)')
    else
        print('[jp-meridian9] (server) [WARN] mrd9_contracts not found. Run sql/install.sql')
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
