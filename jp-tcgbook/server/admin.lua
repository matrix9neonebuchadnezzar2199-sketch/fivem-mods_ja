--- 管理者 UI（/bookadmin）用サーバー処理。ACE: Config.BookAdminAce

local resourceName = GetCurrentResourceName()

--- @param source integer
--- @return boolean
local function isBookAdminAllowed(source)
    if type(source) ~= 'number' or source <= 0 then
        return false
    end
    local ace = Config.BookAdminAce or 'command.tcg_book_admin'
    return IsPlayerAceAllowed(source, ace)
end

--- @param source integer
--- @param kind string
--- @param data any
--- @param err string|nil
local function replyAdmin(source, kind, data, err)
    TriggerClientEvent(
        'jp-tcgbook:client:adminData',
        source,
        { kind = kind, success = err == nil, data = data, error = err }
    )
end

--- @return table
local function loadAssetManifest()
    local raw = LoadResourceFile(resourceName, 'html/assets/cards/asset_manifest.json')
    if not raw or raw == '' then
        return { paths = {} }
    end
    local ok, decoded = pcall(json.decode, raw)
    if not ok or type(decoded) ~= 'table' then
        return { paths = {} }
    end
    if decoded.paths and type(decoded.paths) == 'table' then
        return decoded
    end
    return { paths = {} }
end

--- image_path からツリー分類キー（character / monster / item / uncategorized）
--- @param image_path string|nil
--- @return string
local function folderKeyFromImagePath(image_path)
    local p = image_path or ''
    if p:find('assets/cards/character/', 1, true) then
        return 'character'
    end
    if p:find('assets/cards/monster/', 1, true) then
        return 'monster'
    end
    if p:find('assets/cards/item/', 1, true) then
        return 'item'
    end
    return 'uncategorized'
end

--- @param rows table
--- @return table
local function attachFolderKeys(rows)
    local out = {}
    for _, r in ipairs(rows or {}) do
        local row = {}
        for k, v in pairs(r) do
            row[k] = v
        end
        row.folder_key = folderKeyFromImagePath(r.image_path)
        out[#out + 1] = row
    end
    return out
end

local function trim(s)
    return (s or ''):match('^%s*(.-)%s*$') or ''
end

--- @param card_id string|nil
--- @return boolean, string|nil err
local function validateCardId(card_id)
    if type(card_id) ~= 'string' then
        return false, 'card_id が不正です'
    end
    local s = trim(card_id)
    if #s < 1 or #s > 32 then
        return false, 'card_id は 1〜32 文字にしてください'
    end
    if not s:match('^[a-zA-Z0-9_]+$') then
        return false, 'card_id は英数字とアンダースコアのみにしてください'
    end
    return true, nil
end

local VALID_RANK = { UR = true, SS = true, S = true, A = true, B = true, C = true }
local VALID_TYPE = { shitei = true, free = true }

--- @param d table
--- @return table|nil row
--- @return string|nil err
--- @return table|nil warnings
local function normalizeAndValidateRow(d)
    if type(d) ~= 'table' then
        return nil, 'データが空です', nil
    end

    local okId, errId = validateCardId(d.card_id)
    if not okId then
        return nil, errId, nil
    end
    local card_id = trim(d.card_id)

    local name = trim(d.name or '')
    if #name < 1 or #name > 64 then
        return nil, '名前は 1〜64 文字にしてください', nil
    end

    local rank = trim(d.rank or '')
    if not VALID_RANK[rank] then
        return nil, 'ランクが不正です（UR/SS/S/A/B/C）', nil
    end

    local ctype = trim(d.type or '')
    if not VALID_TYPE[ctype] then
        return nil, 'タイプが不正です（shitei / free）', nil
    end

    local warnings = {}

    if (rank == 'UR' or rank == 'SS') and ctype ~= 'shitei' then
        warnings[#warnings + 1] = 'UR/SS は通常「指定（shitei）」と組み合わせます'
    end
    if (rank == 'S' or rank == 'A' or rank == 'B' or rank == 'C') and ctype ~= 'free' then
        warnings[#warnings + 1] = 'S〜C は通常「フリー（free）」と組み合わせます'
    end

    local function stat(nameKey, v)
        local n = tonumber(v)
        if not n or n < 1 or n > 10 or math.floor(n) ~= n then
            return nil, ('ステータス %s は 1〜10 の整数にしてください'):format(nameKey)
        end
        return n, nil
    end

    local st, est = stat('上', d.stat_top)
    if est then
        return nil, est, nil
    end
    local sr, esr = stat('右', d.stat_right)
    if esr then
        return nil, esr, nil
    end
    local sb, esb = stat('下', d.stat_bottom)
    if esb then
        return nil, esb, nil
    end
    local sl, esl = stat('左', d.stat_left)
    if esl then
        return nil, esl, nil
    end

    local image_path = trim(d.image_path or '')
    if #image_path > 128 then
        return nil, 'image_path が長すぎます（128 文字以内）', nil
    end

    local description = d.description
    if description == nil then
        description = ''
    end
    if type(description) ~= 'string' then
        description = tostring(description)
    end

    local no = tonumber(d.no)
    if not no or no < 1 or math.floor(no) ~= no then
        return nil, 'no は 1 以上の整数にしてください', nil
    end

    local row = {
        card_id = card_id,
        name = name,
        rank = rank,
        type = ctype,
        stat_top = st,
        stat_right = sr,
        stat_bottom = sb,
        stat_left = sl,
        image_path = image_path,
        description = description,
        no = no,
    }
    return row, nil, warnings
end

--- @param source integer
--- @return string
local function actorUid(source)
    local uid = GetPlayerUid(source)
    if uid and uid ~= '' then
        return uid
    end
    return ('player:%d'):format(source)
end

RegisterNetEvent('jp-tcgbook:server:adminBootstrap', function()
    local src = source
    if not isBookAdminAllowed(src) then
        replyAdmin(src, 'bootstrap', nil, '管理者権限がありません')
        return
    end

    local listR = Database.AdminListMaster()
    if not listR.success then
        replyAdmin(src, 'bootstrap', nil, listR.error or '一覧取得失敗')
        return
    end

    local auditR = Database.AdminListAudit(15)
    local audit = auditR.success and auditR.data or {}

    replyAdmin(src, 'bootstrap', {
        masters = attachFolderKeys(listR.data),
        assets = loadAssetManifest(),
        audit = audit,
        rules = {
            card_id_pattern = '^[a-zA-Z0-9_]{1,32}$',
            stats_range = { min = 1, max = 10 },
        },
    }, nil)
end)

RegisterNetEvent('jp-tcgbook:server:adminCheckCardId', function(raw)
    local src = source
    if not isBookAdminAllowed(src) then
        replyAdmin(src, 'checkCardId', nil, '管理者権限がありません')
        return
    end
    local card_id = type(raw) == 'table' and raw.card_id or raw
    if type(card_id) ~= 'string' then
        replyAdmin(src, 'checkCardId', nil, 'card_id 不正')
        return
    end
    local ok, err = validateCardId(card_id)
    if not ok then
        replyAdmin(src, 'checkCardId', { valid = false, exists = false, error = err }, nil)
        return
    end
    local ex = Database.AdminExistsMaster(trim(card_id))
    if not ex.success then
        replyAdmin(src, 'checkCardId', nil, ex.error)
        return
    end
    replyAdmin(src, 'checkCardId', { valid = true, exists = ex.data == true }, nil)
end)

RegisterNetEvent('jp-tcgbook:server:adminImpact', function(raw)
    local src = source
    if not isBookAdminAllowed(src) then
        replyAdmin(src, 'impact', nil, '管理者権限がありません')
        return
    end
    local card_id = type(raw) == 'table' and raw.card_id or nil
    local ok, err = validateCardId(card_id)
    if not ok then
        replyAdmin(src, 'impact', nil, err)
        return
    end
    local imp = Database.AdminImpact(trim(card_id))
    if not imp.success then
        replyAdmin(src, 'impact', nil, imp.error)
        return
    end
    replyAdmin(src, 'impact', imp.data, nil)
end)

RegisterNetEvent('jp-tcgbook:server:adminSaveCard', function(raw)
    local src = source
    if not isBookAdminAllowed(src) then
        replyAdmin(src, 'saveCard', nil, '管理者権限がありません')
        return
    end

    local row, verr, warnings = normalizeAndValidateRow(raw)
    if verr then
        replyAdmin(src, 'saveCard', nil, verr)
        return
    end

    local up = Database.AdminUpsertMaster(row)
    if not up.success then
        replyAdmin(src, 'saveCard', nil, up.error or '保存失敗')
        return
    end

    local detail = json.encode({ rank = row.rank, type = row.type, name = row.name })
    Database.AdminAppendAudit(actorUid(src), 'save', row.card_id, detail)

    local fresh = Database.AdminGetMaster(row.card_id)
    local saved = fresh.success and fresh.data or row
    local out = {}
    for k, v in pairs(saved) do
        out[k] = v
    end
    out.folder_key = folderKeyFromImagePath(saved.image_path)

    replyAdmin(src, 'saveCard', {
        row = out,
        warnings = warnings or {},
        saved_at = os.date('!%Y-%m-%dT%H:%M:%SZ'),
    }, nil)
end)

RegisterNetEvent('jp-tcgbook:server:adminDeleteCard', function(raw)
    local src = source
    if not isBookAdminAllowed(src) then
        replyAdmin(src, 'deleteCard', nil, '管理者権限がありません')
        return
    end

    local card_id = type(raw) == 'table' and raw.card_id or nil
    local ok, err = validateCardId(card_id)
    if not ok then
        replyAdmin(src, 'deleteCard', nil, err)
        return
    end
    card_id = trim(card_id)

    local ex = Database.AdminExistsMaster(card_id)
    if not ex.success or not ex.data then
        replyAdmin(src, 'deleteCard', nil, 'カードが存在しません')
        return
    end

    local del = Database.AdminDeleteMaster(card_id)
    if not del.success then
        replyAdmin(src, 'deleteCard', nil, del.error or '削除失敗')
        return
    end

    Database.AdminAppendAudit(actorUid(src), 'delete', card_id, nil)
    replyAdmin(src, 'deleteCard', { card_id = card_id }, nil)
end)

RegisterNetEvent('jp-tcgbook:server:adminListAudit', function(raw)
    local src = source
    if not isBookAdminAllowed(src) then
        replyAdmin(src, 'listAudit', nil, '管理者権限がありません')
        return
    end
    local lim = type(raw) == 'table' and raw.limit or 50
    local r = Database.AdminListAudit(lim)
    if not r.success then
        replyAdmin(src, 'listAudit', nil, r.error)
        return
    end
    replyAdmin(src, 'listAudit', r.data, nil)
end)

RegisterNetEvent('jp-tcgbook:server:adminSuggestNo', function()
    local src = source
    if not isBookAdminAllowed(src) then
        replyAdmin(src, 'suggestNo', nil, '管理者権限がありません')
        return
    end
    local n = Database.AdminNextMasterNo()
    if not n then
        replyAdmin(src, 'suggestNo', nil, 'no の取得に失敗しました')
        return
    end
    replyAdmin(src, 'suggestNo', { no = n }, nil)
end)
