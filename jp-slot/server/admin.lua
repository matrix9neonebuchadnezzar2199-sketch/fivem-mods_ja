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

--- プリセット表示名（1〜32文字・許容文字のみ）
local function jpSlotPresetNameValid(name)
    if type(name) ~= 'string' then
        return false
    end
    local len = utf8.len(name)
    if not len or len < 1 or len > 32 then
        return false
    end
    for _, code in utf8.codes(name) do
        local okch = (code >= 0x30 and code <= 0x39)
            or (code >= 0x41 and code <= 0x5A)
            or (code >= 0x61 and code <= 0x7A)
            or code == 0x20
            or code == 0x2D
            or code == 0x5F
            or (code >= 0x3041 and code <= 0x3096)
            or (code >= 0x30A1 and code <= 0x30FA)
            or code == 0x30FC
            or (code >= 0x4E00 and code <= 0x9FFF)
            or (code >= 0x3400 and code <= 0x4DBF)
        if not okch then
            return false
        end
    end
    return true
end

--- 左スロット file（空可・キャラ直下相対。`characters/<id>/` で始まる場合は ID 一致必須）
local function jpSlotValidateLeftStageFile(characterId, file)
    if file == nil or file == '' then
        return true
    end
    if type(file) ~= 'string' then
        return false
    end
    if file:find('%.%.', 1, true) or file:find(':', 1, true) then
        return false
    end
    if file:match('^[\\/]') then
        return false
    end
    local low = file:lower()
    if low:match('^characters/') then
        local pref = ('characters/%s/'):format(characterId):lower()
        if low:sub(1, #pref) ~= pref then
            return false
        end
    end
    return true
end

local function jpSlotValidateLeftStageSlots(slots, characterId)
    if slots == nil then
        return true
    end
    if type(slots) ~= 'table' then
        return false
    end
    if #slots > 2 then
        return false
    end
    for i = 1, #slots do
        local s = slots[i]
        if type(s) ~= 'table' then
            return false
        end
        if type(s.enabled) ~= 'boolean' then
            return false
        end
        if not jpSlotValidateLeftStageFile(characterId, s.file) then
            return false
        end
        local kind = s.kind
        if kind ~= 'image' and kind ~= 'video' then
            return false
        end
        local dm = tonumber(s.durationMs)
        if dm == nil or dm ~= math.floor(dm) or dm < 0 or dm > 60000 then
            return false
        end
    end
    return true
end

local function jpSlotValidatePresetEffectsForSave(data, characterId)
    if type(data) ~= 'table' or type(data.effects) ~= 'table' then
        return true
    end
    local keys = { 'idle', 'win', 'bonus', 'bonus_streak', 'bonus_big', 'miss_tease' }
    for i = 1, #keys do
        local sec = data.effects[keys[i]]
        if type(sec) == 'table' and type(sec.leftStage) == 'table' then
            local ls = sec.leftStage.slots
            if ls == nil then
                return false
            end
            if not jpSlotValidateLeftStageSlots(ls, characterId) then
                return false
            end
        end
    end
    return true
end

local function presetIndexGet(characterId)
    local raw = GetResourceKvpString('jp-slot:adm:preset:index:' .. characterId)
    if not raw or raw == '' then
        return {}
    end
    local ok, t = pcall(json.decode, raw)
    if ok and type(t) == 'table' then
        return t
    end
    return {}
end

local function presetIndexSet(characterId, names)
    SetResourceKvp('jp-slot:adm:preset:index:' .. characterId, json.encode(names))
end

local function presetIndexAdd(characterId, presetName)
    local arr = presetIndexGet(characterId)
    for i = 1, #arr do
        if arr[i] == presetName then
            return
        end
    end
    arr[#arr + 1] = presetName
    table.sort(arr)
    presetIndexSet(characterId, arr)
end

local function presetIndexRemove(characterId, presetName)
    local arr = presetIndexGet(characterId)
    local out = {}
    for i = 1, #arr do
        if arr[i] ~= presetName then
            out[#out + 1] = arr[i]
        end
    end
    presetIndexSet(characterId, out)
end

--- キャラ ID に紐づくプリセットから effects を1件読む（埋め込み・着席 init 用）
function JpSlotReadPresetEffectsForCharacter(characterId)
    if type(characterId) ~= 'string' or characterId == '' then
        return nil
    end
    local pcid, pname = JpSlotParseActivePresetRef()
    local tried = {}
    local function tryOne(name)
        if type(name) ~= 'string' or name == '' or tried[name] then
            return nil
        end
        tried[name] = true
        local raw = GetResourceKvpString(JpSlotPresetBodyKvpKey(characterId, name))
        if raw and raw ~= '' then
            local ok, preset = pcall(json.decode, raw)
            if ok and type(preset) == 'table' and type(preset.effects) == 'table' then
                return preset.effects
            end
        end
        return nil
    end
    if pcid == characterId and pname then
        local e = tryOne(pname)
        if e then
            return e
        end
    end
    local e2 = tryOne('default')
    if e2 then
        return e2
    end
    for _, name in ipairs(presetIndexGet(characterId)) do
        local e3 = tryOne(name)
        if e3 then
            return e3
        end
    end
    return nil
end

--- 旧 KVP（jp-slot:adm:preset:<id>・list）を luna 名前空間へ移行（1回のみ）
function JpSlotMigratePresetsV2()
    if GetResourceKvpString('jp-slot:adm:preset:migrated_v2') == '1' then
        return 0
    end
    local n = 0
    local idsOrder = {}
    local seen = {}
    local function addId(id)
        if type(id) ~= 'string' or id == '' then
            return
        end
        if id == 'list' or id == 'active' or id == 'migrated_v2' or id:sub(1, 6) == 'index:' then
            return
        end
        if not seen[id] then
            seen[id] = true
            idsOrder[#idsOrder + 1] = id
        end
    end
    local rawList = GetResourceKvpString('jp-slot:adm:preset:list')
    if rawList and rawList ~= '' then
        local okl, decoded = pcall(json.decode, rawList)
        if okl and type(decoded) == 'table' then
            for _, e in ipairs(decoded) do
                if type(e) == 'table' and type(e.id) == 'string' then
                    addId(e.id)
                end
            end
        end
    end
    local activeOld = GetResourceKvpString('jp-slot:adm:preset:active')
    if activeOld and activeOld ~= '' and activeOld:sub(1, 1) ~= '{' then
        addId(activeOld)
    end
    addId('default')

    local namesForIndex = {}
    for _, id in ipairs(idsOrder) do
        local oldKey = 'jp-slot:adm:preset:' .. id
        local body = GetResourceKvpString(oldKey)
        if body and body ~= '' then
            local newKey = JpSlotPresetBodyKvpKey('luna', id)
            SetResourceKvp(newKey, body)
            DeleteResourceKvp(oldKey)
            namesForIndex[#namesForIndex + 1] = id
            n = n + 1
        end
    end
    table.sort(namesForIndex)
    presetIndexSet('luna', namesForIndex)
    if rawList and rawList ~= '' then
        DeleteResourceKvp('jp-slot:adm:preset:list')
    end

    if activeOld and activeOld ~= '' then
        local okj, j = pcall(json.decode, activeOld)
        if okj and type(j) == 'table' and type(j.characterId) == 'string' and type(j.presetName) == 'string' then
            SetResourceKvp('jp-slot:adm:preset:active', activeOld)
        else
            SetResourceKvp(
                'jp-slot:adm:preset:active',
                json.encode({ characterId = 'luna', presetName = activeOld })
            )
        end
    end

    SetResourceKvp('jp-slot:adm:preset:migrated_v2', '1')
    print(('[jp-slot] preset migration v2 completed (%d entries)'):format(n))
    return n
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

RegisterNetEvent('jp-slot:sv:adminPresetListByCharacter', function(payload)
    local src = source
    payload = type(payload) == 'table' and payload or {}
    if not sessionOk(src, payload.token) then
        TriggerClientEvent('jp-slot:cl:adminPresetListByCharacterResult', src, { ok = false, reason = 'unauthorized' })
        return
    end
    local cid = payload.characterId
    if type(cid) ~= 'string' or cid == '' or not JpSlotCharacterIdValid(cid) then
        TriggerClientEvent('jp-slot:cl:adminPresetListByCharacterResult', src, { ok = false, reason = 'bad_character' })
        return
    end
    local idx = presetIndexGet(cid)
    local out = {}
    for _, name in ipairs(idx) do
        local raw = GetResourceKvpString(JpSlotPresetBodyKvpKey(cid, name))
        local updatedAt = os.time()
        if raw and raw ~= '' then
            local okp, pr = pcall(json.decode, raw)
            if okp and type(pr) == 'table' and type(pr.updatedAt) == 'number' then
                updatedAt = pr.updatedAt
            end
        end
        out[#out + 1] = { name = name, updatedAt = updatedAt }
    end
    TriggerClientEvent('jp-slot:cl:adminPresetListByCharacterResult', src, { ok = true, list = out })
end)

RegisterNetEvent('jp-slot:sv:adminPresetGet', function(payload)
    local src = source
    payload = type(payload) == 'table' and payload or {}
    if not sessionOk(src, payload.token) then
        TriggerClientEvent('jp-slot:cl:adminPresetGetResult', src, { ok = false, reason = 'unauthorized' })
        return
    end
    local cid = payload.characterId
    local pname = payload.presetName
    if type(cid) ~= 'string' or cid == '' or not JpSlotCharacterIdValid(cid) then
        TriggerClientEvent('jp-slot:cl:adminPresetGetResult', src, { ok = false, reason = 'bad_character' })
        return
    end
    if type(pname) ~= 'string' or pname == '' then
        TriggerClientEvent('jp-slot:cl:adminPresetGetResult', src, { ok = false, reason = 'invalid' })
        return
    end
    local raw = GetResourceKvpString(JpSlotPresetBodyKvpKey(cid, pname))
    TriggerClientEvent('jp-slot:cl:adminPresetGetResult', src, {
        ok = raw ~= nil and raw ~= '',
        data = (raw and raw ~= '') and json.decode(raw) or nil,
    })
end)

RegisterNetEvent('jp-slot:sv:adminPresetSaveNew', function(payload)
    local src = source
    payload = type(payload) == 'table' and payload or {}
    if not sessionOk(src, payload.token) then
        TriggerClientEvent('jp-slot:cl:adminPresetSaveNewResult', src, { ok = false, reason = 'unauthorized' })
        return
    end
    if not isAdmin(src) then
        TriggerClientEvent('jp-slot:cl:adminPresetSaveNewResult', src, { ok = false, reason = 'forbidden' })
        return
    end
    local cid = payload.characterId
    local pname = payload.presetName
    local data = payload.data
    if type(cid) ~= 'string' or cid == '' or not JpSlotCharacterIdValid(cid) then
        TriggerClientEvent('jp-slot:cl:adminPresetSaveNewResult', src, { ok = false, reason = 'bad_character' })
        return
    end
    if type(pname) ~= 'string' or not jpSlotPresetNameValid(pname) then
        TriggerClientEvent('jp-slot:cl:adminPresetSaveNewResult', src, { ok = false, reason = 'invalid_name' })
        return
    end
    if type(data) ~= 'table' then
        TriggerClientEvent('jp-slot:cl:adminPresetSaveNewResult', src, { ok = false, reason = 'invalid_data' })
        return
    end
    local key = JpSlotPresetBodyKvpKey(cid, pname)
    local existing = GetResourceKvpString(key)
    if existing and existing ~= '' then
        TriggerClientEvent('jp-slot:cl:adminPresetSaveNewResult', src, { ok = false, reason = 'duplicate' })
        return
    end
    local idx = presetIndexGet(cid)
    for i = 1, #idx do
        if idx[i] == pname then
            TriggerClientEvent('jp-slot:cl:adminPresetSaveNewResult', src, { ok = false, reason = 'duplicate' })
            return
        end
    end
    if not jpSlotValidatePresetEffectsForSave(data, cid) then
        TriggerClientEvent('jp-slot:cl:adminPresetSaveNewResult', src, { ok = false, reason = 'invalid_left_stage' })
        return
    end
    data.updatedAt = os.time()
    if type(data.name) ~= 'string' or data.name == '' then
        data.name = pname
    end
    SetResourceKvp(key, json.encode(data))
    presetIndexAdd(cid, pname)
    print(('[jp-slot][preset] saveNew: char=%s name=%s ok=%s'):format(tostring(cid), tostring(pname), tostring(true)))
    TriggerClientEvent('jp-slot:cl:adminPresetSaveNewResult', src, { ok = true })
end)

RegisterNetEvent('jp-slot:sv:adminPresetSaveOverwrite', function(payload)
    local src = source
    payload = type(payload) == 'table' and payload or {}
    if not sessionOk(src, payload.token) then
        TriggerClientEvent('jp-slot:cl:adminPresetSaveOverwriteResult', src, { ok = false, reason = 'unauthorized' })
        return
    end
    if not isAdmin(src) then
        TriggerClientEvent('jp-slot:cl:adminPresetSaveOverwriteResult', src, { ok = false, reason = 'forbidden' })
        return
    end
    local cid = payload.characterId
    local pname = payload.presetName
    local data = payload.data
    if type(cid) ~= 'string' or cid == '' or not JpSlotCharacterIdValid(cid) then
        TriggerClientEvent('jp-slot:cl:adminPresetSaveOverwriteResult', src, { ok = false, reason = 'bad_character' })
        return
    end
    if type(pname) ~= 'string' or pname == '' then
        TriggerClientEvent('jp-slot:cl:adminPresetSaveOverwriteResult', src, { ok = false, reason = 'invalid' })
        return
    end
    if type(data) ~= 'table' then
        TriggerClientEvent('jp-slot:cl:adminPresetSaveOverwriteResult', src, { ok = false, reason = 'invalid_data' })
        return
    end
    local key = JpSlotPresetBodyKvpKey(cid, pname)
    local existing = GetResourceKvpString(key)
    if not existing or existing == '' then
        TriggerClientEvent('jp-slot:cl:adminPresetSaveOverwriteResult', src, { ok = false, reason = 'not_found' })
        return
    end
    if not jpSlotValidatePresetEffectsForSave(data, cid) then
        TriggerClientEvent('jp-slot:cl:adminPresetSaveOverwriteResult', src, { ok = false, reason = 'invalid_left_stage' })
        return
    end
    data.updatedAt = os.time()
    SetResourceKvp(key, json.encode(data))
    presetIndexAdd(cid, pname)
    local ac, ap = JpSlotParseActivePresetRef()
    if ac == cid and ap == pname then
        if ApplyJpSlotMasterFromPreset then
            ApplyJpSlotMasterFromPreset()
        end
    end
    TriggerClientEvent('jp-slot:cl:adminPresetSaveOverwriteResult', src, { ok = true })
end)

RegisterNetEvent('jp-slot:sv:adminPresetDelete', function(payload)
    local src = source
    payload = type(payload) == 'table' and payload or {}
    if not sessionOk(src, payload.token) then
        TriggerClientEvent('jp-slot:cl:adminPresetDeleteResult', src, { ok = false, reason = 'unauthorized' })
        return
    end
    if not isAdmin(src) then
        TriggerClientEvent('jp-slot:cl:adminPresetDeleteResult', src, { ok = false, reason = 'forbidden' })
        return
    end
    local cid = payload.characterId
    local pname = payload.presetName
    if type(cid) ~= 'string' or cid == '' or not JpSlotCharacterIdValid(cid) then
        TriggerClientEvent('jp-slot:cl:adminPresetDeleteResult', src, { ok = false, reason = 'bad_character' })
        return
    end
    if type(pname) ~= 'string' or pname == '' then
        TriggerClientEvent('jp-slot:cl:adminPresetDeleteResult', src, { ok = false, reason = 'invalid' })
        return
    end
    local key = JpSlotPresetBodyKvpKey(cid, pname)
    DeleteResourceKvp(key)
    presetIndexRemove(cid, pname)
    local ac, ap = JpSlotParseActivePresetRef()
    if ac == cid and ap == pname then
        local rest = presetIndexGet(cid)
        if #rest > 0 then
            SetResourceKvp(
                'jp-slot:adm:preset:active',
                json.encode({ characterId = cid, presetName = rest[1] })
            )
        else
            DeleteResourceKvp('jp-slot:adm:preset:active')
        end
        if ApplyJpSlotMasterFromPreset then
            ApplyJpSlotMasterFromPreset()
        end
    end
    TriggerClientEvent('jp-slot:cl:adminPresetDeleteResult', src, { ok = true })
end)

RegisterNetEvent('jp-slot:sv:adminPresetSetActive', function(payload)
    local src = source
    payload = type(payload) == 'table' and payload or {}
    if not sessionOk(src, payload.token) then
        TriggerClientEvent('jp-slot:cl:adminPresetActiveResult', src, { ok = false, reason = 'unauthorized' })
        return
    end
    if not isAdmin(src) then
        TriggerClientEvent('jp-slot:cl:adminPresetActiveResult', src, { ok = false, reason = 'forbidden' })
        return
    end
    local cid = payload.characterId
    local pname = payload.presetName
    if type(cid) ~= 'string' or cid == '' or not JpSlotCharacterIdValid(cid) then
        TriggerClientEvent('jp-slot:cl:adminPresetActiveResult', src, { ok = false, reason = 'bad_character' })
        return
    end
    if type(pname) ~= 'string' or pname == '' then
        TriggerClientEvent('jp-slot:cl:adminPresetActiveResult', src, { ok = false, reason = 'invalid' })
        return
    end
    local key = JpSlotPresetBodyKvpKey(cid, pname)
    local raw = GetResourceKvpString(key)
    if not raw or raw == '' then
        TriggerClientEvent('jp-slot:cl:adminPresetActiveResult', src, { ok = false, reason = 'not_found' })
        return
    end
    SetResourceKvp(
        'jp-slot:adm:preset:active',
        json.encode({ characterId = cid, presetName = pname })
    )
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
    local defId = (Config.Characters and Config.Characters.DefaultId) or 'luna'
    local characterId = payload.characterId
    if type(characterId) == 'string' and characterId ~= '' then
        if not JpSlotCharacterIdValid(characterId) then
            characterId = defId
        end
    else
        characterId = defId
    end
    local kind = payload.kind or 'all'
    local manifest = JpSlotLoadCharacterManifest(characterId)
    if not manifest then
        TriggerClientEvent('jp-slot:cl:adminAssetsScanResult', src, {
            ok = false,
            error = 'manifest_not_found',
            characterId = characterId,
        })
        return
    end
    local base = GetResourcePath(GetCurrentResourceName()) .. '/html/assets/'
    local lib = JpSlotAssetLibraryFromManifest(manifest)
    lib.typography = JpSlotListAssetRel(base, 'ui/typography/')
    lib.symbols = JpSlotListAssetRel(base, 'symbols/')
    lib.frames = JpSlotListAssetRel(base, 'frames/')
    lib.bg = JpSlotListAssetRel(base, 'bg/')
    lib.vfx = JpSlotListAssetRel(base, 'vfx/')
    local out = JpSlotFilterAssetLibByKind(lib, kind)
    -- characterBasePath: html/assets/ からのキャラサブパス（NUI は assetsRoot + これ + manifest 相対）
    TriggerClientEvent('jp-slot:cl:adminAssetsScanResult', src, {
        ok = true,
        characterId = characterId,
        displayName = manifest.displayName,
        characterBasePath = ('characters/%s/'):format(characterId),
        assets = out,
    })
end)

RegisterNetEvent('jp-slot:sv:adminCharactersList', function(payload)
    local src = source
    payload = type(payload) == 'table' and payload or {}
    if not sessionOk(src, payload.token) then
        TriggerClientEvent('jp-slot:cl:adminCharactersListResult', src, { ok = false, reason = 'unauthorized' })
        return
    end
    local scanned = JpSlotScanCharacters()
    if #scanned == 0 then
        print('[jp-slot][WARN] adminCharactersList: character scan returned empty (check html/assets/characters/*/manifest.json)')
    end
    local list = {}
    for i = 1, #scanned do
        local e = scanned[i]
        local man = JpSlotLoadCharacterManifest(e.id)
        list[#list + 1] = {
            id = e.id,
            displayName = e.displayName,
            version = man and man.version or '',
            author = man and man.author or '',
        }
    end
    local ac, ap = JpSlotParseActivePresetRef()
    TriggerClientEvent('jp-slot:cl:adminCharactersListResult', src, {
        ok = true,
        list = list,
        activeCharacterId = ac,
        activePresetName = ap,
    })
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

--- embed init 送信用 effects の leftStage を Live Console にダンプ（診断用）
---@param label string
---@param eff table|nil
local function dumpLeftStageFromEffects(label, eff)
    if type(eff) ~= 'table' then
        print(('[jp-slot][debug] %s effects=nil'):format(label))
        return
    end
    local tabs = { 'idle', 'win', 'bonus', 'bonus_streak', 'bonus_big', 'miss_tease' }
    for ti = 1, #tabs do
        local tab = tabs[ti]
        local sec = eff[tab]
        local ls = type(sec) == 'table' and sec.leftStage or nil
        local slots = type(ls) == 'table' and ls.slots or nil
        if type(slots) == 'table' then
            for i, s in ipairs(slots) do
                print(('[jp-slot][debug] %s tab=%s slot[%d] enabled=%s kind=%s file=%s'):format(
                    label,
                    tab,
                    i,
                    tostring(s and s.enabled),
                    tostring(s and s.kind),
                    tostring(s and s.file)
                ))
            end
        end
    end
end

--- 管理画面「プレビュー」タブ：埋め込み用に台 UI の init データを送る（着席不要）
RegisterNetEvent('jp-slot:sv:adminEmbedSlotInit', function(payload)
    local src = source
    payload = type(payload) == 'table' and payload or {}
    if not sessionOk(src, payload.token) then
        print(('[jp-slot][embed] sessionOk=false src=%s token=%s'):format(
            tostring(src),
            payload.token and 'present' or 'absent'
        ))
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
        print(('[jp-slot][embed] no machine resolved src=%s wantId=%s machines=%s'):format(
            tostring(src),
            tostring(wantId or 'nil'),
            tostring((Config.Machines and #Config.Machines) or 0)
        ))
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
    local cid = payload.characterId
    if not cid or cid == '' or not JpSlotCharacterIdValid(cid) then
        cid = m.characterId or (Config.Characters and Config.Characters.DefaultId) or 'luna'
    end
    local chMan = JpSlotLoadCharacterManifest(cid)
    local embedEffects = JpSlotReadPresetEffectsForCharacter(cid)
    dumpLeftStageFromEffects('embedInit char=' .. tostring(cid), embedEffects)
    print(('[jp-slot][embed] init sent: src=%s machine=%s character=%s'):format(
        tostring(src),
        tostring(m and m.id or 'nil'),
        tostring(cid or 'nil')
    ))
    TriggerClientEvent('jp-slot:cl:adminEmbedSlotInit', src, {
        machine = m,
        effects = embedEffects,
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
        neutralPreviewCharacter = payload.neutralPreviewCharacter == true,
        character = chMan,
        characterBasePath = ('characters/%s/'):format(cid),
        characterId = cid,
        characters = JpSlotScanCharacters(),
    })
end)

--- 汚染された leftStage KVP を既定に戻す（txAdmin Live Console のみ: source=0）
--- effects.<tab>.leftStage.slots — idle のみ slot[1]=idle/portrait.png、他タブは 2 スロットとも disabled
RegisterCommand('jpslot_fix_leftstage', function(source, _args, _raw)
    if source ~= 0 then
        return
    end
    local prefix = 'jp-slot:adm:preset:'
    local reservedCid = {
        active = true,
        list = true,
        migrated_v2 = true,
        migrated_v3 = true,
        index = true,
    }
    local function emptyTwoSlots()
        return {
            slots = {
                {
                    enabled = false,
                    file = '',
                    kind = 'image',
                    durationMs = 0,
                    fadeIn = true,
                    bgm = nil,
                    voiceKeys = {},
                },
                {
                    enabled = false,
                    file = '',
                    kind = 'image',
                    durationMs = 0,
                    fadeIn = true,
                    bgm = nil,
                    voiceKeys = {},
                },
            },
        }
    end
    local function idleDefaultLeftStage()
        return {
            slots = {
                {
                    enabled = true,
                    kind = 'image',
                    file = 'idle/portrait.png',
                    durationMs = 0,
                    fadeIn = true,
                    bgm = nil,
                    voiceKeys = {},
                },
                {
                    enabled = false,
                    file = '',
                    kind = 'image',
                    durationMs = 0,
                    fadeIn = true,
                    bgm = nil,
                    voiceKeys = {},
                },
            },
        }
    end
    local tabs = { 'idle', 'win', 'bonus', 'bonus_streak', 'bonus_big', 'miss_tease' }
    local handle = StartFindKvp(prefix)
    if not handle or handle == -1 then
        print('[jp-slot][fix] StartFindKvp failed')
        return
    end
    local count = 0
    while true do
        local key = FindKvp(handle)
        if not key or key == '' then
            break
        end
        if type(key) == 'string' and key:sub(1, #prefix) == prefix then
            local rest = key:sub(#prefix + 1)
            local cid, pname = rest:match('^([^:]+):(.+)$')
            if cid and pname and pname ~= '' and not reservedCid[cid] then
                local raw = GetResourceKvpString(key)
                if raw and raw ~= '' then
                    local ok, preset = pcall(json.decode, raw)
                    if ok and type(preset) == 'table' and type(preset.effects) == 'table' then
                        preset.effects = preset.effects or {}
                        for ti = 1, #tabs do
                            local tab = tabs[ti]
                            if type(preset.effects[tab]) ~= 'table' then
                                preset.effects[tab] = {}
                            end
                            if tab == 'idle' then
                                preset.effects[tab].leftStage = idleDefaultLeftStage()
                            else
                                preset.effects[tab].leftStage = emptyTwoSlots()
                            end
                        end
                        SetResourceKvp(key, json.encode(preset))
                        count = count + 1
                        print(('[jp-slot][fix] reset leftStage for key=%s'):format(key))
                    else
                        print(('[jp-slot][fix] skip (no effects or bad json): %s'):format(key))
                    end
                end
            end
        end
    end
    EndFindKvp(handle)
    print(('[jp-slot][fix] done, %d presets reset'):format(count))
end, true)

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
