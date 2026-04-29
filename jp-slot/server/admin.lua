-- 管理者コマンド・NUI サーバー側ハンドラ・プリセット・プレビュー

JpSlotPreviewMode = JpSlotPreviewMode or {}

--- ACE で管理者か
---@param source number
---@return boolean
local function isAdmin(source)
    if source == 0 then
        return true
    end
    return IsPlayerAceAllowed(source, Config.AdminAce or 'jp-slot.admin')
end

---@param source number
---@param msg string
local function notifyError(source, msg)
    TriggerClientEvent('chat:addMessage', source, {
        color = { 255, 80, 80 },
        multiline = true,
        args = { '[jp-slot]', tostring(msg) },
    })
end

---@param token string|nil
---@return boolean
local function sessionOk(src, token)
    local ok, _why = AdminAuth.verifySession(src, token)
    return ok
end

RegisterCommand(Config.AdminCommand or 'jpslotadmin', function(source, _args, _raw)
    if source == 0 then
        print('[jp-slot] コンソールからは管理NUIを開けません（ゲーム内プレイヤーで実行）。')
        return
    end
    local cfg = Config.AdminAuth or {}
    if cfg.requireAce and not AdminAuth.hasAce(source) then
        TriggerClientEvent('jp-slot:adminDenied', source, { reason = 'no_ace' })
        return
    end
    local theme = Theme.getActive()
    TriggerClientEvent('jp-slot:openAdmin', source, {
        theme = theme,
        debug = Config.Debug,
        showDebugTab = Config.Debug and Config.DebugSettings and Config.DebugSettings.ShowDebugButtons,
        uiSize = JpSlotGetUISize(),
        requirePassword = cfg.enabled ~= false,
        sessionTtl = tonumber(cfg.sessionTtl) or 1800,
    })
end, false)

RegisterNetEvent('jp-slot:sv:adminLogin', function(payload)
    local src = source
    payload = type(payload) == 'table' and payload or {}
    local token, err, lockRemain = AdminAuth.verifyPassword(src, payload.password or '')
    if token then
        TriggerClientEvent('jp-slot:cl:adminLoginResult', src, {
            ok = true,
            token = token,
            ttl = (Config.AdminAuth and Config.AdminAuth.sessionTtl) or 1800,
        })
    else
        TriggerClientEvent('jp-slot:cl:adminLoginResult', src, {
            ok = false,
            reason = err,
            lockRemain = lockRemain,
        })
    end
end)

RegisterNetEvent('jp-slot:sv:adminLogout', function(payload)
    local src = source
    payload = type(payload) == 'table' and payload or {}
    AdminAuth.logout(payload.token)
    TriggerClientEvent('jp-slot:cl:adminLogoutOk', src, {})
end)

RegisterNetEvent('jp-slot:sv:adminChangePw', function(payload)
    local src = source
    payload = type(payload) == 'table' and payload or {}
    local ok, reason = AdminAuth.changePassword(src, payload.oldPassword or '', payload.newPassword or '', payload.token)
    TriggerClientEvent('jp-slot:cl:adminChangePwResult', src, { ok = ok, reason = reason })
end)

RegisterNetEvent('jp-slot:sv:adminSetUISize', function(data)
    local src = source
    data = type(data) == 'table' and data or {}
    if not sessionOk(src, data.token) then
        notifyError(src, 'セッションが無効です')
        return
    end
    if not isAdmin(src) then
        notifyError(src, '権限がありません')
        return
    end
    local size = {
        widthPercent = math.max(30, math.min(100, tonumber(data.widthPercent) or 90)),
        heightPercent = math.max(30, math.min(100, tonumber(data.heightPercent) or 90)),
        maxWidthPx = math.max(0, math.min(7680, tonumber(data.maxWidthPx) or 0)),
    }
    SetResourceKvp('jp-slot:ui_size', json.encode(size))
    TriggerClientEvent('jp-slot:applyUISize', -1, size)
    print(('[jp-slot] UISize updated by %s: %d%% x %d%% (maxWidthPx=%d)'):format(
        GetPlayerName(src) or tostring(src),
        size.widthPercent,
        size.heightPercent,
        size.maxWidthPx
    ))
end)

RegisterNetEvent('jp-slot:sv:adminResetUISize', function(data)
    local src = source
    data = type(data) == 'table' and data or {}
    if not sessionOk(src, data.token) then
        notifyError(src, 'セッションが無効です')
        return
    end
    if not isAdmin(src) then
        notifyError(src, '権限がありません')
        return
    end
    DeleteResourceKvp('jp-slot:ui_size')
    local size = {
        widthPercent = Config.UISize.widthPercent or 90,
        heightPercent = Config.UISize.heightPercent or 90,
        maxWidthPx = Config.UISize.maxWidthPx or 0,
    }
    TriggerClientEvent('jp-slot:applyUISize', -1, size)
    print(('[jp-slot] UISize reset to defaults by %s'):format(GetPlayerName(src) or tostring(src)))
end)

RegisterNetEvent('jp-slot:sv:adminSaveTheme', function(payload)
    local src = source
    payload = type(payload) == 'table' and payload or {}
    if not sessionOk(src, payload.token) then
        notifyError(src, 'セッションが無効です')
        return
    end
    if not isAdmin(src) then
        return
    end
    local themeData = payload.theme
    if Theme.save(themeData) then
        TriggerClientEvent('jp-slot:notify', src, { kind = 'ok', msg = 'theme_saved' })
    end
end)

RegisterNetEvent('jp-slot:sv:adminPresetList', function(payload)
    local src = source
    payload = type(payload) == 'table' and payload or {}
    if not sessionOk(src, payload.token) then
        TriggerClientEvent('jp-slot:cl:adminPresetListResult', src, { ok = false, reason = 'unauthorized' })
        return
    end
    local raw = GetResourceKvpString('jp-slot:adm:preset:list')
    local list = (raw and raw ~= '') and json.decode(raw) or {}
    local activeId = GetResourceKvpString('jp-slot:adm:preset:active') or 'default'
    TriggerClientEvent('jp-slot:cl:adminPresetListResult', src, { ok = true, list = list, activeId = activeId })
end)

RegisterNetEvent('jp-slot:sv:adminPresetGet', function(payload)
    local src = source
    payload = type(payload) == 'table' and payload or {}
    if not sessionOk(src, payload.token) then
        TriggerClientEvent('jp-slot:cl:adminPresetGetResult', src, { ok = false, reason = 'unauthorized' })
        return
    end
    local id = payload.id or ''
    local raw = GetResourceKvpString('jp-slot:adm:preset:' .. id)
    TriggerClientEvent('jp-slot:cl:adminPresetGetResult', src, {
        ok = raw ~= nil and raw ~= '',
        data = (raw and raw ~= '') and json.decode(raw) or nil,
    })
end)

RegisterNetEvent('jp-slot:sv:adminPresetSave', function(payload)
    local src = source
    payload = type(payload) == 'table' and payload or {}
    if not sessionOk(src, payload.token) then
        TriggerClientEvent('jp-slot:cl:adminPresetSaveResult', src, { ok = false, reason = 'unauthorized' })
        return
    end
    local p = payload.preset
    if not p or not p.id or not p.name then
        TriggerClientEvent('jp-slot:cl:adminPresetSaveResult', src, { ok = false, reason = 'invalid' })
        return
    end
    p.updatedAt = os.time()
    SetResourceKvp('jp-slot:adm:preset:' .. p.id, json.encode(p))
    SetResourceKvp('jp-slot:adm:preset:active', p.id)
    local raw = GetResourceKvpString('jp-slot:adm:preset:list')
    local list = (raw and raw ~= '') and json.decode(raw) or {}
    local found = false
    for i, e in ipairs(list) do
        if e.id == p.id then
            list[i] = { id = p.id, name = p.name, updatedAt = p.updatedAt }
            found = true
            break
        end
    end
    if not found then
        list[#list + 1] = { id = p.id, name = p.name, updatedAt = p.updatedAt }
    end
    SetResourceKvp('jp-slot:adm:preset:list', json.encode(list))
    if ApplyJpSlotMasterFromPreset then
        ApplyJpSlotMasterFromPreset()
    end
    TriggerClientEvent('jp-slot:cl:adminPresetSaveResult', src, { ok = true })
end)

RegisterNetEvent('jp-slot:sv:adminPresetDelete', function(payload)
    local src = source
    payload = type(payload) == 'table' and payload or {}
    if not sessionOk(src, payload.token) then
        TriggerClientEvent('jp-slot:cl:adminPresetDeleteResult', src, { ok = false, reason = 'unauthorized' })
        return
    end
    local id = payload.id or ''
    SetResourceKvp('jp-slot:adm:preset:' .. id, '')
    local raw = GetResourceKvpString('jp-slot:adm:preset:list')
    local list = (raw and raw ~= '') and json.decode(raw) or {}
    local out = {}
    for _, e in ipairs(list) do
        if e.id ~= id then
            out[#out + 1] = e
        end
    end
    SetResourceKvp('jp-slot:adm:preset:list', json.encode(out))
    TriggerClientEvent('jp-slot:cl:adminPresetDeleteResult', src, { ok = true })
end)

RegisterNetEvent('jp-slot:sv:adminPresetSetActive', function(payload)
    local src = source
    payload = type(payload) == 'table' and payload or {}
    if not sessionOk(src, payload.token) then
        TriggerClientEvent('jp-slot:cl:adminPresetActiveResult', src, { ok = false, reason = 'unauthorized' })
        return
    end
    SetResourceKvp('jp-slot:adm:preset:active', payload.id or '')
    if ApplyJpSlotMasterFromPreset then
        ApplyJpSlotMasterFromPreset()
    end
    TriggerClientEvent('jp-slot:cl:adminPresetActiveResult', src, { ok = true })
end)

RegisterNetEvent('jp-slot:sv:adminAssetsScan', function(payload)
    local src = source
    payload = type(payload) == 'table' and payload or {}
    if not sessionOk(src, payload.token) then
        TriggerClientEvent('jp-slot:cl:adminAssetsScanResult', src, { ok = false, reason = 'unauthorized' })
        return
    end
    local base = GetResourcePath(GetCurrentResourceName()) .. '/html/assets/'
    local cats = {
        typography = base .. 'ui/typography/',
        characters = base .. 'characters/',
        cutins = base .. 'cutins/',
        bg = base .. 'bg/',
        vfx = base .. 'vfx/',
        bgm = base .. 'sound/bgm/',
        se = base .. 'sound/se/',
        voice = base .. 'sound/voice/',
    }
    local out = {}
    for k, dir in pairs(cats) do
        out[k] = JpSlotListDir(dir)
    end
    TriggerClientEvent('jp-slot:cl:adminAssetsScanResult', src, { ok = true, assets = out })
end)

RegisterNetEvent('jp-slot:sv:adminPreviewStart', function(payload)
    local src = source
    payload = type(payload) == 'table' and payload or {}
    if not sessionOk(src, payload.token) then
        return
    end
    JpSlotPreviewMode[src] = true
    TriggerClientEvent('jp-slot:previewMode', src, { active = true })
end)

RegisterNetEvent('jp-slot:sv:adminPreviewEnd', function(payload)
    local src = source
    payload = type(payload) == 'table' and payload or {}
    if not sessionOk(src, payload.token) then
        return
    end
    JpSlotPreviewMode[src] = nil
    TriggerClientEvent('jp-slot:previewMode', src, { active = false })
end)

--- 管理画面「プレビュー」タブ：埋め込み用に台 UI の init データを送る（着席不要）
RegisterNetEvent('jp-slot:sv:adminEmbedSlotInit', function(payload)
    local src = source
    payload = type(payload) == 'table' and payload or {}
    if not sessionOk(src, payload.token) then
        return
    end
    local wantId = payload.machineId
    local list = Config.Machines or {}
    local m = nil
    if wantId then
        for i = 1, #list do
            if list[i].id == wantId then
                m = list[i]
                break
            end
        end
    end
    if not m then
        m = list[1]
    end
    if not m then
        return
    end
    local theme = Theme.getActive()
    local jackpot = 0.0
    if Config.Jackpot and Config.Jackpot.enabled then
        local raw = GetResourceKvpString('jp-slot:jackpot:pool')
        jackpot = tonumber(raw) or ((Config.Jackpot.seedAmount or 0) + 0.0)
    end
    local payId = m.paytableId or 'normal'
    local ptFull = Config.Paytables and Config.Paytables[payId] or {}
    local ptDisp = Config.PaytableDisplay and Config.PaytableDisplay[payId]
    local hypeKey = (Config.Marquee and Config.Marquee.HypeKey) or 'marquee.hype'
    local infoKey = (Config.Marquee and Config.Marquee.InfoKey) or 'marquee.info'
    TriggerClientEvent('jp-slot:cl:adminEmbedSlotInit', src, {
        machine = m,
        theme = theme,
        jackpot = jackpot,
        balance = 999999999,
        spinDuration = (Config.Debug and Config.DebugSettings and Config.DebugSettings.SpinDuration) or Config.SpinDurationDefault,
        paytable = ptDisp,
        marquee = {
            hype = Locales.getList(hypeKey) or {},
            info = Locales.getList(infoKey) or {},
        },
        symbolIds = ptFull.symbols
            or { 'cherry', 'bell', 'watermelon', 'bar', 'seven', 'wild', 'character' },
        uiSize = JpSlotGetUISize and JpSlotGetUISize() or nil,
    })
end)

RegisterCommand('jpslotresetauth', function(source, _args, _raw)
    if source ~= 0 and not AdminAuth.hasAce(source) then
        return
    end
    SetResourceKvp('jp-slot:adm:passhash', '')
    SetResourceKvp('jp-slot:adm:salt', '')
    SetResourceKvp('jp-slot:adm:iter', '')
    AdminAuth.bootstrap()
    print('[jp-slot] admin password KVP cleared; new bootstrap if enabled.')
end, true)
