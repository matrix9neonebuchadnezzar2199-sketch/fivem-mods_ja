--- jp-tcgbook データベース層（oxmysql / await）
--- 公開関数は原則 { success = bool, data = any?, error = string? } を返す

Database = {}

local resourceName = GetCurrentResourceName()

--- shared/cards.lua 優先（DB が Seed 前でもデッキ UI・画像パスが Lua と一致する）
local LuaMasterByCardId = {}
do
    for _, c in ipairs(TcgCardsMaster) do
        LuaMasterByCardId[c.card_id] = c
    end
end

--- @param row table SQL JOIN 行（card_id, name, …）
--- @return table NUI / クライアント向けカードペイロード
local function deckCardPayloadFromLuaOrRow(row)
    local lm = LuaMasterByCardId[row.card_id]
    if not lm then
        local nameEnFallback = nil
        if type(row.name_en) == 'string' and row.name_en ~= '' then
            nameEnFallback = row.name_en
        end
        return {
            card_id = row.card_id,
            name = row.name,
            name_en = nameEnFallback,
            rank = row.rank,
            type = row.type,
            stat_top = row.stat_top,
            stat_right = row.stat_right,
            stat_bottom = row.stat_bottom,
            stat_left = row.stat_left,
            image_path = row.image_path,
            description = row.description,
            description_en = type(row.description_en) == 'string' and row.description_en or '',
            no = row.no,
        }
    end
    local nameEn = nil
    if type(lm.name_en) == 'string' and lm.name_en ~= '' then
        nameEn = lm.name_en
    end
    return {
        card_id = lm.card_id,
        name = lm.name,
        name_en = nameEn,
        rank = lm.rank,
        type = lm.type,
        stat_top = lm.stat_top,
        stat_right = lm.stat_right,
        stat_bottom = lm.stat_bottom,
        stat_left = lm.stat_left,
        image_path = lm.image_path,
        description = lm.description,
        description_en = type(lm.description_en) == 'string' and lm.description_en or '',
        no = lm.no,
    }
end

--- install.sql を読み込み、コメント除去後にセミコロンで分割して返す
local function loadSqlStatements()
    local raw = LoadResourceFile(resourceName, 'server/sql/install.sql')
    if not raw or raw == '' then
        return nil, 'install.sql を読み込めませんでした'
    end

    local s = raw:gsub('/%*.-%*/', '')

    local lines = {}
    for line in s:gmatch('[^\r\n]+') do
        local code = line:gsub('%s*%-%-.*$', '')
        if code:match('%S') then
            lines[#lines + 1] = code
        end
    end
    s = table.concat(lines, '\n')

    local stmts = {}
    for part in s:gmatch('[^;]+') do
        local trimmed = part:match('^%s*(.-)%s*$')
        if trimmed and trimmed ~= '' then
            stmts[#stmts + 1] = trimmed
        end
    end

    return stmts
end

--- 既存 DB 向け: 列が無い環境のみ ALTER（重複列エラーは無視）
function Database.ApplyOptionalSchemaPatches()
    local stmts = {
        'ALTER TABLE tcg_players ADD COLUMN pvp_exp INT UNSIGNED NOT NULL DEFAULT 0',
        'ALTER TABLE tcg_players ADD COLUMN pvp_level INT UNSIGNED NOT NULL DEFAULT 1',
        'ALTER TABLE tcg_players ADD COLUMN pvp_win_streak INT UNSIGNED NOT NULL DEFAULT 0',
        'ALTER TABLE tcg_cards_master ADD COLUMN description_en TEXT NULL',
        --- M6 後追い: カード名英語（BOOK EN）
        'ALTER TABLE tcg_cards_master ADD COLUMN name_en VARCHAR(64) DEFAULT NULL AFTER name',
        --- M6 後追い: ランキング等の表示名
        'ALTER TABLE tcg_players ADD COLUMN display_name VARCHAR(64) DEFAULT NULL',
        --- PHASE E4: `ORDER BY rating DESC, citizenid ASC` 向け（既存環境は起動時に一度だけ作成）
        'CREATE INDEX idx_tcg_players_rating_leaderboard ON tcg_players (rating, citizenid)',
    }
    for _, sql in ipairs(stmts) do
        local ok, err = pcall(function()
            MySQL.query.await(sql, {})
        end)
        if not ok then
            local msg = tostring(err):lower()
            if not msg:find('duplicate column', 1, true)
                and not msg:find('already exists', 1, true)
                and not msg:find('duplicate key name', 1, true)
            then
                print(('[jp-tcgbook] schema patch: %s'):format(tostring(err)))
            end
        end
    end
end

local function isDuplicateKeyError(err)
    if type(err) ~= 'string' then
        return false
    end
    local lower = err:lower()
    return lower:find('duplicate', 1, true) ~= nil or lower:find('uniq_', 1, true) ~= nil
end

--- テーブル作成（install.sql）＋カードマスタ UPSERT
function Database.InitializeTables()
    local stmts, errLoad = loadSqlStatements()
    if not stmts then
        return { success = false, error = errLoad }
    end

    local ok, err = pcall(function()
        for _, sql in ipairs(stmts) do
            MySQL.query.await(sql, {})
        end
    end)

    if not ok then
        return { success = false, error = 'スキーマ作成失敗: ' .. tostring(err) }
    end

    local cntRows = MySQL.query.await('SELECT COUNT(*) AS c FROM tcg_cards_master', {})
    local existing = tonumber(cntRows and cntRows[1] and cntRows[1].c) or 0
    local seedFlag = Config.SeedCardsFromLua
    if seedFlag == nil then
        seedFlag = true
    end
    local runLuaSeed = existing == 0 or seedFlag == true

    local count = 0
    if runLuaSeed then
        local upsertSql = [[
INSERT INTO tcg_cards_master
    (card_id, name, name_en, rank, type, stat_top, stat_right, stat_bottom, stat_left, image_path, description, description_en, no)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
ON DUPLICATE KEY UPDATE
    name = VALUES(name),
    name_en = VALUES(name_en),
    rank = VALUES(rank),
    type = VALUES(type),
    stat_top = VALUES(stat_top),
    stat_right = VALUES(stat_right),
    stat_bottom = VALUES(stat_bottom),
    stat_left = VALUES(stat_left),
    image_path = VALUES(image_path),
    description = VALUES(description),
    description_en = VALUES(description_en),
    no = VALUES(no)
]]

        ok, err = pcall(function()
            for _, c in ipairs(TcgCardsMaster) do
                local nameEn = nil
                if type(c.name_en) == 'string' and c.name_en ~= '' then
                    nameEn = c.name_en
                end
                MySQL.query.await(upsertSql, {
                    c.card_id,
                    c.name,
                    nameEn,
                    c.rank,
                    c.type,
                    c.stat_top,
                    c.stat_right,
                    c.stat_bottom,
                    c.stat_left,
                    c.image_path,
                    c.description,
                    type(c.description_en) == 'string' and c.description_en or '',
                    c.no,
                })
                count = count + 1
            end
        end)

        if not ok then
            return { success = false, error = 'カードマスタUPSERT失敗: ' .. tostring(err) }
        end
    end

    Database.ApplyOptionalSchemaPatches()

    return { success = true, data = { cardMasterCount = count, luaSeedSkipped = not runLuaSeed } }
end

function Database.GetPlayer(citizenid)
    local ok, result = pcall(function()
        return MySQL.query.await('SELECT * FROM tcg_players WHERE citizenid = ? LIMIT 1', { citizenid })
    end)
    if not ok then
        return { success = false, error = tostring(result) }
    end
    return { success = true, data = result[1] }
end

--- dryrun・疑似PvPソロ検証用: `tcg_players` にダミー行が無ければ作成する
--- @param citizenid string|nil 省略時は `Config.PvpSoloVerificationDummyCitizenid`
--- @return table { success = bool, error? }
function Database.EnsureVerificationDummyPeer(citizenid)
    local cid = citizenid
    if type(cid) ~= 'string' or cid == '' then
        cid = Config.PvpSoloVerificationDummyCitizenid or 'jp-tcgbook-debug-peer-dummy'
    end
    local r = Database.GetPlayer(cid)
    if r.success and r.data then
        return { success = true, data = {} }
    end
    return Database.CreatePlayer(cid)
end

function Database.CreatePlayer(citizenid)
    local ok, err = pcall(function()
        MySQL.query.await(
            'INSERT INTO tcg_players (citizenid, initialized, rating, wins, losses, draws) VALUES (?, FALSE, ?, 0, 0, 0)',
            { citizenid, Config.InitialRating }
        )
    end)
    if not ok then
        if isDuplicateKeyError(tostring(err)) then
            return { success = false, error = 'プレイヤーは既に登録されています' }
        end
        return { success = false, error = tostring(err) }
    end
    return { success = true, data = {} }
end

--- M6 後追い: ランキング・履歴向け表示名（行が無ければ DEFAULT で新規行を作成）
--- @param citizenid string
--- @param display_name string
--- @return boolean
function Database.UpsertPlayerDisplayName(citizenid, display_name)
    if type(citizenid) ~= 'string' or citizenid == '' then
        return false
    end
    if type(display_name) ~= 'string' or display_name == '' then
        return false
    end
    local dn = display_name
    if #dn > 64 then
        dn = dn:sub(1, 64)
    end
    local ok = pcall(function()
        MySQL.query.await([[
INSERT INTO tcg_players (citizenid, display_name)
VALUES (?, ?)
ON DUPLICATE KEY UPDATE display_name = VALUES(display_name)
]], { citizenid, dn })
    end)
    return ok
end

function Database.GetPlayerCards(citizenid)
    local sql = [[
SELECT
    pc.instance_id,
    pc.citizenid,
    pc.card_id,
    pc.obtained_at,
    pc.locked,
    m.name,
    m.name_en,
    m.rank,
    m.type,
    m.stat_top,
    m.stat_right,
    m.stat_bottom,
    m.stat_left,
    m.image_path,
    m.description,
    m.description_en,
    m.no
FROM tcg_player_cards pc
INNER JOIN tcg_cards_master m ON m.card_id = pc.card_id
WHERE pc.citizenid = ?
ORDER BY pc.obtained_at ASC, pc.instance_id ASC
]]
    local ok, result = pcall(function()
        return MySQL.query.await(sql, { citizenid })
    end)
    if not ok then
        return { success = false, error = tostring(result) }
    end
    return { success = true, data = result or {} }
end

function Database.AddCardToPlayer(citizenid, card_id)
    local ok, err = pcall(function()
        MySQL.query.await(
            'INSERT INTO tcg_player_cards (citizenid, card_id) VALUES (?, ?)',
            { citizenid, card_id }
        )
    end)
    if not ok then
        return { success = false, error = tostring(err) }
    end
    return { success = true, data = {} }
end

function Database.GetPlayerDecks(citizenid)
    local ok, result = pcall(function()
        return MySQL.query.await(
            [[SELECT id, citizenid, name, is_active, created_at, updated_at
              FROM tcg_decks WHERE citizenid = ? ORDER BY id ASC]],
            { citizenid }
        )
    end)
    if not ok then
        return { success = false, error = tostring(result) }
    end
    return { success = true, data = result or {} }
end

--- デッキ本体 + スロット1〜10（空きは card = nil）
function Database.GetDeckById(deck_id)
    local ok, deckRows = pcall(function()
        return MySQL.query.await('SELECT * FROM tcg_decks WHERE id = ? LIMIT 1', { deck_id })
    end)
    if not ok then
        return { success = false, error = tostring(deckRows) }
    end
    local deck = deckRows[1]
    if not deck then
        return { success = false, error = 'デッキが見つかりません' }
    end

    local sql = [[
SELECT
    dc.slot_index,
    dc.card_id,
    m.name,
    m.name_en,
    m.rank,
    m.type,
    m.stat_top,
    m.stat_right,
    m.stat_bottom,
    m.stat_left,
    m.image_path,
    m.description,
    m.description_en,
    m.no
FROM tcg_deck_cards dc
INNER JOIN tcg_cards_master m ON m.card_id = dc.card_id
WHERE dc.deck_id = ?
ORDER BY dc.slot_index ASC
]]

    local ok2, cardRows = pcall(function()
        return MySQL.query.await(sql, { deck_id })
    end)
    if not ok2 then
        return { success = false, error = tostring(cardRows) }
    end

    local bySlot = {}
    for _, row in ipairs(cardRows or {}) do
        bySlot[row.slot_index] = row
    end

    local slots = {}
    for i = 1, 10 do
        local r = bySlot[i]
        if r then
            slots[i] = {
                slot_index = i,
                card = deckCardPayloadFromLuaOrRow(r),
            }
        else
            slots[i] = { slot_index = i, card = nil }
        end
    end

    return {
        success = true,
        data = {
            id = deck.id,
            citizenid = deck.citizenid,
            name = deck.name,
            is_active = deck.is_active == true or deck.is_active == 1,
            created_at = deck.created_at,
            updated_at = deck.updated_at,
            slots = slots,
        },
    }
end

function Database.GetDeckNames(citizenid)
    local ok, result = pcall(function()
        return MySQL.query.await(
            'SELECT name FROM tcg_decks WHERE citizenid = ? ORDER BY id ASC',
            { citizenid }
        )
    end)
    if not ok then
        return { success = false, error = tostring(result) }
    end
    local names = {}
    for _, row in ipairs(result or {}) do
        names[#names + 1] = row.name
    end
    return { success = true, data = names }
end

function Database.CreateDeck(citizenid, name)
    local insertId
    local ok, err = pcall(function()
        insertId = MySQL.insert.await(
            'INSERT INTO tcg_decks (citizenid, name, is_active) VALUES (?, ?, FALSE)',
            { citizenid, name }
        )
    end)
    if not ok then
        if isDuplicateKeyError(tostring(err)) then
            return { success = false, error = '同じデッキ名が既に存在します' }
        end
        return { success = false, error = tostring(err) }
    end
    return { success = true, data = { id = insertId } }
end

function Database.UpdateDeckName(deck_id, name)
    local ok, err = pcall(function()
        MySQL.query.await('UPDATE tcg_decks SET name = ? WHERE id = ?', { name, deck_id })
    end)
    if not ok then
        if isDuplicateKeyError(tostring(err)) then
            return { success = false, error = '同じデッキ名が既に存在します' }
        end
        return { success = false, error = tostring(err) }
    end
    return { success = true, data = {} }
end

function Database.DeleteDeck(deck_id)
    local ok, err = pcall(function()
        MySQL.query.await('DELETE FROM tcg_decks WHERE id = ?', { deck_id })
    end)
    if not ok then
        return { success = false, error = tostring(err) }
    end
    return { success = true, data = {} }
end

function Database.SetDeckCard(deck_id, slot, card_id)
    local ok, err = pcall(function()
        MySQL.query.await(
            [[INSERT INTO tcg_deck_cards (deck_id, slot_index, card_id) VALUES (?, ?, ?)
              ON DUPLICATE KEY UPDATE card_id = VALUES(card_id)]],
            { deck_id, slot, card_id }
        )
    end)
    if not ok then
        return { success = false, error = tostring(err) }
    end
    return { success = true, data = {} }
end

function Database.RemoveDeckCard(deck_id, slot)
    local ok, err = pcall(function()
        MySQL.query.await(
            'DELETE FROM tcg_deck_cards WHERE deck_id = ? AND slot_index = ?',
            { deck_id, slot }
        )
    end)
    if not ok then
        return { success = false, error = tostring(err) }
    end
    return { success = true, data = {} }
end

function Database.SetActiveDeck(citizenid, deck_id)
    local ok, err = pcall(function()
        MySQL.query.await('UPDATE tcg_decks SET is_active = FALSE WHERE citizenid = ?', { citizenid })
        MySQL.query.await(
            'UPDATE tcg_decks SET is_active = TRUE WHERE id = ? AND citizenid = ?',
            { deck_id, citizenid }
        )
    end)
    if not ok then
        return { success = false, error = tostring(err) }
    end
    return { success = true, data = {} }
end

function Database.CountDecks(citizenid)
    local ok, rows = pcall(function()
        return MySQL.query.await(
            'SELECT COUNT(*) AS c FROM tcg_decks WHERE citizenid = ?',
            { citizenid }
        )
    end)
    if not ok then
        return { success = false, error = tostring(rows) }
    end
    local n = 0
    if rows and rows[1] then
        n = tonumber(rows[1].c) or 0
    end
    return { success = true, data = n }
end

--- /tcg_reset 用：指示書どおり4段階削除
function Database.ResetPlayer(citizenid)
    local ok, err = pcall(function()
        MySQL.query.await(
            'DELETE FROM tcg_deck_cards WHERE deck_id IN (SELECT id FROM tcg_decks WHERE citizenid = ?)',
            { citizenid }
        )
        MySQL.query.await('DELETE FROM tcg_decks WHERE citizenid = ?', { citizenid })
        MySQL.query.await('DELETE FROM tcg_player_cards WHERE citizenid = ?', { citizenid })
        MySQL.query.await('DELETE FROM tcg_players WHERE citizenid = ?', { citizenid })
    end)
    if not ok then
        return { success = false, error = tostring(err) }
    end
    return { success = true, data = {} }
end

--- /tcg_clearcards 用：デッキ行は残し、スロットと所持インスタンスのみ削除（空デッキ化）
function Database.ClearPlayerCardsAndDeckSlots(citizenid)
    local ok, err = pcall(function()
        MySQL.query.await(
            'DELETE FROM tcg_deck_cards WHERE deck_id IN (SELECT id FROM tcg_decks WHERE citizenid = ?)',
            { citizenid }
        )
        MySQL.query.await('DELETE FROM tcg_player_cards WHERE citizenid = ?', { citizenid })
    end)
    if not ok then
        return { success = false, error = tostring(err) }
    end
    return { success = true, data = {} }
end

--- @param rating integer
function Database.UpdatePlayerRating(citizenid, rating)
    local ok, err = pcall(function()
        MySQL.query.await('UPDATE tcg_players SET rating = ? WHERE citizenid = ?', { rating, citizenid })
    end)
    if not ok then
        return { success = false, error = tostring(err) }
    end
    return { success = true, data = {} }
end

--- 試合結果を 1 件分加算する。outcome は 'win' | 'lose' | 'draw' のみ（caller 側で固定）
--- @param citizenid string
--- @param outcome string
--- @return table { success, error? }
function Database.IncrementMatchStats(citizenid, outcome)
    local col
    if outcome == 'win' then
        col = 'wins'
    elseif outcome == 'lose' then
        col = 'losses'
    elseif outcome == 'draw' then
        col = 'draws'
    else
        return { success = false, error = 'invalid outcome: ' .. tostring(outcome) }
    end

    local sql = ('UPDATE tcg_players SET %s = %s + 1 WHERE citizenid = ?'):format(col, col)
    local ok, err = pcall(function()
        MySQL.query.await(sql, { citizenid })
    end)
    if not ok then
        return { success = false, error = tostring(err) }
    end
    return { success = true, data = {} }
end

--- UTC エポック秒から JST の暦日 `YYYY-MM-DD`（固定 UTC+9・サマータイムなし）。PHASE C・将来の履歴表示でも共用可。
--- @param epochSec number|nil 省略時は現在時刻
--- @return string
function Database.JstDateStringFromEpoch(epochSec)
    local e = tonumber(epochSec)
    if not e then
        e = os.time()
    end
    local t = os.date('!*t', math.floor(e) + 9 * 3600)
    return ('%04d-%02d-%02d'):format(t.year, t.month, t.day)
end

--- PHASE C: 日次・試合 1 プレイヤー分を加算（リアル PvP のみ caller 側）
--- @param outcome string 'win'|'lose'|'draw'
--- @return table { success, error? }
function Database.IncrementDailyMatchCounters(citizenid, date_jst, outcome)
    if type(citizenid) ~= 'string' or citizenid == '' then
        return { success = false, error = 'invalid citizenid' }
    end
    if type(date_jst) ~= 'string' or #date_jst ~= 10 then
        return { success = false, error = 'invalid date_jst' }
    end
    local w, l, d = 0, 0, 0
    if outcome == 'win' then
        w = 1
    elseif outcome == 'lose' then
        l = 1
    elseif outcome == 'draw' then
        d = 1
    else
        return { success = false, error = 'invalid outcome: ' .. tostring(outcome) }
    end

    local sql = [[
INSERT INTO tcg_daily_counters
    (citizenid, date_jst, battles, wins, losses, draws, copies_received)
VALUES (?, ?, 1, ?, ?, ?, 0)
ON DUPLICATE KEY UPDATE
    battles = battles + 1,
    wins = wins + VALUES(wins),
    losses = losses + VALUES(losses),
    draws = draws + VALUES(draws)
]]
    local ok, err = pcall(function()
        MySQL.query.await(sql, { citizenid, date_jst, w, l, d })
    end)
    if not ok then
        return { success = false, error = tostring(err) }
    end
    return { success = true, data = {} }
end

--- PHASE C: 敗北コピー成功 1 回（同日行が無ければ battles=0 で作成）
--- @return table { success, error? }
function Database.IncrementDailyCopiesReceived(citizenid, date_jst)
    if type(citizenid) ~= 'string' or citizenid == '' then
        return { success = false, error = 'invalid citizenid' }
    end
    if type(date_jst) ~= 'string' or #date_jst ~= 10 then
        return { success = false, error = 'invalid date_jst' }
    end

    local sql = [[
INSERT INTO tcg_daily_counters
    (citizenid, date_jst, battles, wins, losses, draws, copies_received)
VALUES (?, ?, 0, 0, 0, 0, 1)
ON DUPLICATE KEY UPDATE
    copies_received = copies_received + 1
]]
    local ok, err = pcall(function()
        MySQL.query.await(sql, { citizenid, date_jst })
    end)
    if not ok then
        return { success = false, error = tostring(err) }
    end
    return { success = true, data = {} }
end

local function truncDisplayName(s, maxLen)
    maxLen = maxLen or 128
    if type(s) ~= 'string' then
        return ''
    end
    if #s <= maxLen then
        return s
    end
    return s:sub(1, maxLen)
end

--- PHASE E1: 対戦履歴 1 行 INSERT（`match_id` PRIMARY KEY・同一試合の二重 INSERT は DB エラー）
--- `row`: match_id, finished_at, reason, citizenid_a/b, display_name_a/b?, score_a/b, outcome_a ('win'|'lose'|'draw'),
--- rating_*_before/after, defeat_copy_granted, defeat_copy_card_id?, season_id?, is_real_pvp?
--- @param row table
--- @return table { success, error? }
function Database.InsertMatchHistory(row)
    if type(row) ~= 'table' then
        return { success = false, error = 'row must be table' }
    end
    local mid = row.match_id
    if type(mid) ~= 'string' or mid == '' or #mid > 128 then
        return { success = false, error = 'invalid match_id' }
    end

    local oa = row.outcome_a
    if oa ~= 'win' and oa ~= 'lose' and oa ~= 'draw' then
        return { success = false, error = 'invalid outcome_a' }
    end

    local copyId = row.defeat_copy_card_id
    if copyId ~= nil and (type(copyId) ~= 'string' or copyId == '') then
        copyId = nil
    end

    local sql = [[
INSERT INTO tcg_match_history (
    match_id, finished_at, reason, is_real_pvp,
    citizenid_a, citizenid_b, display_name_a, display_name_b,
    score_a, score_b, outcome_a,
    rating_a_before, rating_a_after, rating_b_before, rating_b_after,
    defeat_copy_granted, defeat_copy_card_id, season_id
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
]]

    local ok, err = pcall(function()
        MySQL.query.await(sql, {
            mid,
            tonumber(row.finished_at) or 0,
            tostring(row.reason or 'unknown'),
            row.is_real_pvp ~= false,
            tostring(row.citizenid_a or ''),
            tostring(row.citizenid_b or ''),
            truncDisplayName(row.display_name_a),
            truncDisplayName(row.display_name_b),
            tonumber(row.score_a) or 0,
            tonumber(row.score_b) or 0,
            oa,
            tonumber(row.rating_a_before) or 1500,
            tonumber(row.rating_a_after) or 1500,
            tonumber(row.rating_b_before) or 1500,
            tonumber(row.rating_b_after) or 1500,
            row.defeat_copy_granted == true,
            copyId,
            tonumber(row.season_id) or 0,
        })
    end)
    if not ok then
        return { success = false, error = tostring(err) }
    end
    return { success = true, data = {} }
end

--- @param raw table DB 行
--- @param myCid string 閲覧者 citizenid
--- @return table NUI 向けに正規化した 1 行
local function normalizeMatchHistoryRow(raw, myCid)
    local isA = raw.citizenid_a == myCid
    local oppName = isA and raw.display_name_b or raw.display_name_a
    local oppCid = isA and raw.citizenid_b or raw.citizenid_a
    local outcome_me
    if isA then
        outcome_me = raw.outcome_a
    elseif raw.outcome_a == 'win' then
        outcome_me = 'lose'
    elseif raw.outcome_a == 'lose' then
        outcome_me = 'win'
    else
        outcome_me = 'draw'
    end
    local score_me = isA and tonumber(raw.score_a) or tonumber(raw.score_b)
    local score_opp = isA and tonumber(raw.score_b) or tonumber(raw.score_a)
    local r_before = isA and tonumber(raw.rating_a_before) or tonumber(raw.rating_b_before)
    local r_after = isA and tonumber(raw.rating_a_after) or tonumber(raw.rating_b_after)
    local copy_received = false
    if raw.defeat_copy_granted == true or raw.defeat_copy_granted == 1 then
        local loser_cid
        if raw.outcome_a == 'win' then
            loser_cid = raw.citizenid_b
        elseif raw.outcome_a == 'lose' then
            loser_cid = raw.citizenid_a
        end
        if loser_cid == myCid then
            copy_received = true
        end
    end
    return {
        match_id = raw.match_id,
        finished_at = tonumber(raw.finished_at) or 0,
        reason = tostring(raw.reason or ''),
        opponent_display = oppName or '',
        opponent_citizenid = oppCid or '',
        outcome_me = outcome_me,
        score_me = score_me or 0,
        score_opp = score_opp or 0,
        rating_me_before = r_before or 1500,
        rating_me_after = r_after or 1500,
        defeat_copy_received = copy_received,
        defeat_copy_card_id = copy_received and raw.defeat_copy_card_id or nil,
    }
end

--- M3: 自分の対戦履歴（新しい順・上限あり）
--- @param citizenid string
--- @param limit integer|nil 省略時は Config.MatchHistoryLimitOpenBook
--- @return table { success, data?, error? }
function Database.ListMatchHistoryForCitizenid(citizenid, limit)
    if type(citizenid) ~= 'string' or citizenid == '' then
        return { success = false, error = 'invalid citizenid' }
    end
    local lim = tonumber(limit)
    local defaultLim = tonumber(Config.MatchHistoryLimitOpenBook) or 50
    local maxLim = tonumber(Config.MatchHistoryLimitMax) or 100
    if not lim or lim < 1 then
        lim = defaultLim
    end
    if lim > maxLim then
        lim = maxLim
    end

    local sql = [[
SELECT *
FROM tcg_match_history
WHERE citizenid_a = ? OR citizenid_b = ?
ORDER BY finished_at DESC
LIMIT ?
]]
    local ok, rows = pcall(function()
        return MySQL.query.await(sql, { citizenid, citizenid, lim })
    end)
    if not ok then
        return { success = false, error = tostring(rows) }
    end
    local out = {}
    for _, raw in ipairs(rows or {}) do
        out[#out + 1] = normalizeMatchHistoryRow(raw, citizenid)
    end
    return { success = true, data = out }
end

--- M4: PvP 進行（EXP・表示レベル・連勝）
--- @return table { success, error? }
function Database.UpdatePlayerPvpProgress(citizenid, pvp_exp, pvp_level, pvp_win_streak)
    if type(citizenid) ~= 'string' or citizenid == '' then
        return { success = false, error = 'invalid citizenid' }
    end
    local ok, err = pcall(function()
        MySQL.query.await(
            'UPDATE tcg_players SET pvp_exp = ?, pvp_level = ?, pvp_win_streak = ? WHERE citizenid = ?',
            {
                math.max(0, math.floor(tonumber(pvp_exp) or 0)),
                math.max(1, math.floor(tonumber(pvp_level) or 1)),
                math.max(0, math.floor(tonumber(pvp_win_streak) or 0)),
                citizenid,
            }
        )
    end)
    if not ok then
        return { success = false, error = tostring(err) }
    end
    return { success = true, data = {} }
end

--- M4: 離脱時のみ連勝リセット（レート・戦績は変更しない）
--- @return table { success, error? }
function Database.ResetPvpWinStreak(citizenid)
    if type(citizenid) ~= 'string' or citizenid == '' then
        return { success = false, error = 'invalid citizenid' }
    end
    local ok, err = pcall(function()
        MySQL.query.await(
            'UPDATE tcg_players SET pvp_win_streak = 0 WHERE citizenid = ?',
            { citizenid }
        )
    end)
    if not ok then
        return { success = false, error = tostring(err) }
    end
    return { success = true, data = {} }
end

function Database.ListAllPlayers()
    local ok, result = pcall(function()
        return MySQL.query.await(
            [[SELECT citizenid, rating, wins, losses, draws, initialized
              FROM tcg_players ORDER BY citizenid ASC]],
            {}
        )
    end)
    if not ok then
        return { success = false, error = tostring(result) }
    end
    return { success = true, data = result or {} }
end

--- 管理者 UI: マスタ全件（フォルダ分類は image_path から算出）
function Database.AdminListMaster()
    local ok, result = pcall(function()
        return MySQL.query.await(
            [[SELECT card_id, name, rank, type,
                     stat_top, stat_right, stat_bottom, stat_left,
                     image_path, description, description_en, no
              FROM tcg_cards_master ORDER BY no ASC, card_id ASC]],
            {}
        )
    end)
    if not ok then
        return { success = false, error = tostring(result) }
    end
    return { success = true, data = result or {} }
end

--- @param card_id string
function Database.AdminGetMaster(card_id)
    local ok, result = pcall(function()
        return MySQL.query.await(
            [[SELECT card_id, name, rank, type,
                     stat_top, stat_right, stat_bottom, stat_left,
                     image_path, description, description_en, no
              FROM tcg_cards_master WHERE card_id = ? LIMIT 1]],
            { card_id }
        )
    end)
    if not ok then
        return { success = false, error = tostring(result) }
    end
    return { success = true, data = result[1] }
end

--- @param card_id string
function Database.AdminExistsMaster(card_id)
    local ok, rows = pcall(function()
        return MySQL.query.await(
            'SELECT 1 AS x FROM tcg_cards_master WHERE card_id = ? LIMIT 1',
            { card_id }
        )
    end)
    if not ok then
        return { success = false, error = tostring(rows) }
    end
    return { success = true, data = rows and rows[1] ~= nil }
end

--- @return integer|nil
function Database.AdminNextMasterNo()
    local ok, rows = pcall(function()
        return MySQL.query.await('SELECT COALESCE(MAX(no), 0) + 1 AS n FROM tcg_cards_master', {})
    end)
    if not ok or not rows or not rows[1] then
        return nil
    end
    return tonumber(rows[1].n)
end

--- マスタ UPSERT（管理者）
function Database.AdminUpsertMaster(row)
    --- description_en を省略した管理者保存で Lua シードの英語を消さない
    local den = row.description_en
    if den == nil then
        local okEx, ex = pcall(function()
            return MySQL.query.await(
                'SELECT description_en FROM tcg_cards_master WHERE card_id = ? LIMIT 1',
                { row.card_id }
            )
        end)
        if okEx and ex and ex[1] and ex[1].description_en ~= nil then
            den = ex[1].description_en
        else
            den = ''
        end
    end
    if type(den) ~= 'string' then
        den = tostring(den)
    end

    local sql = [[
INSERT INTO tcg_cards_master
    (card_id, name, rank, type, stat_top, stat_right, stat_bottom, stat_left, image_path, description, description_en, no)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
ON DUPLICATE KEY UPDATE
    name = VALUES(name),
    rank = VALUES(rank),
    type = VALUES(type),
    stat_top = VALUES(stat_top),
    stat_right = VALUES(stat_right),
    stat_bottom = VALUES(stat_bottom),
    stat_left = VALUES(stat_left),
    image_path = VALUES(image_path),
    description = VALUES(description),
    description_en = VALUES(description_en),
    no = VALUES(no)
]]
    local ok, err = pcall(function()
        MySQL.query.await(sql, {
            row.card_id,
            row.name,
            row.rank,
            row.type,
            row.stat_top,
            row.stat_right,
            row.stat_bottom,
            row.stat_left,
            row.image_path,
            row.description,
            den,
            row.no,
        })
    end)
    if not ok then
        return { success = false, error = tostring(err) }
    end
    return { success = true, data = {} }
end

--- 削除前影響件数
function Database.AdminImpact(card_id)
    local ok1, r1 = pcall(function()
        return MySQL.query.await(
            'SELECT COUNT(*) AS c FROM tcg_player_cards WHERE card_id = ?',
            { card_id }
        )
    end)
    if not ok1 then
        return { success = false, error = tostring(r1) }
    end
    local ok2, r2 = pcall(function()
        return MySQL.query.await(
            'SELECT COUNT(*) AS c FROM tcg_deck_cards WHERE card_id = ?',
            { card_id }
        )
    end)
    if not ok2 then
        return { success = false, error = tostring(r2) }
    end
    local owned = tonumber(r1 and r1[1] and r1[1].c) or 0
    local deckSlots = tonumber(r2 and r2[1] and r2[1].c) or 0
    return { success = true, data = { owned = owned, deck_slots = deckSlots } }
end

--- マスタ削除（参照行を先に削除）
function Database.AdminDeleteMaster(card_id)
    local ok, err = pcall(function()
        MySQL.query.await('DELETE FROM tcg_deck_cards WHERE card_id = ?', { card_id })
        MySQL.query.await('DELETE FROM tcg_player_cards WHERE card_id = ?', { card_id })
        MySQL.query.await('DELETE FROM tcg_cards_master WHERE card_id = ?', { card_id })
    end)
    if not ok then
        return { success = false, error = tostring(err) }
    end
    return { success = true, data = {} }
end

--- 監査ログ追記
function Database.AdminAppendAudit(actor_uid, action, card_id, detail_json)
    local ok, err = pcall(function()
        MySQL.insert.await(
            'INSERT INTO tcg_admin_audit (actor_uid, action, card_id, detail_json) VALUES (?, ?, ?, ?)',
            { actor_uid, action, card_id or nil, detail_json or nil }
        )
    end)
    if not ok then
        return { success = false, error = tostring(err) }
    end
    return { success = true, data = {} }
end

--- 監査ログ参照（新しい順）
function Database.AdminListAudit(limit)
    local lim = tonumber(limit) or 50
    if lim < 1 then
        lim = 1
    end
    if lim > 200 then
        lim = 200
    end
    local ok, rows = pcall(function()
        return MySQL.query.await(
            [[SELECT id, actor_uid, action, card_id, detail_json, created_at
              FROM tcg_admin_audit ORDER BY id DESC LIMIT ?]],
            { lim }
        )
    end)
    if not ok then
        return { success = false, error = tostring(rows) }
    end
    return { success = true, data = rows or {} }
end

--- ランキング除外リスト（Config.RankingExcludeCitizenids）を正規化
--- @return string[]
local function rankingExcludeList()
    local t = Config.RankingExcludeCitizenids
    if type(t) ~= 'table' then
        return {}
    end
    local out = {}
    for _, v in ipairs(t) do
        if type(v) == 'string' and v ~= '' then
            out[#out + 1] = v
        end
    end
    return out
end

--- NOT IN 句とプレースホルダ配列を構築（空なら clause は空文字）
--- @param exclude string[]
--- @return string @SQL 断片 ` AND citizenid NOT IN (?,?,?)` または ``
--- @return string[] @`?` の個数 = #exclude
local function rankingExcludeSql(exclude)
    if #exclude == 0 then
        return '', {}
    end
    local marks = {}
    for i = 1, #exclude do
        marks[i] = '?'
    end
    return ' AND citizenid NOT IN (' .. table.concat(marks, ',') .. ')', exclude
end

--- ランキング上位 N 件（除外適用・タイブレーク citizenid ASC）
--- @param limit number
--- @return table { success, data?, error? }
function Database.GetRankingTopN(limit)
    local exclude = rankingExcludeList()
    local maxL = tonumber(Config.RankingMaxLimit) or 100
    local n = math.min(tonumber(limit) or 50, maxL)
    if n < 1 then
        n = 1
    end

    local notInClause, notInParams = rankingExcludeSql(exclude)

    local sql = ([[
SELECT citizenid, rating, wins, losses, draws,
       pvp_exp, pvp_level, pvp_win_streak, display_name
FROM tcg_players
WHERE 1 = 1%s
ORDER BY rating DESC, citizenid ASC
LIMIT ?
]]):format(notInClause)

    local params = {}
    for _, cid in ipairs(notInParams) do
        params[#params + 1] = cid
    end
    params[#params + 1] = n

    local ok, result = pcall(function()
        return MySQL.query.await(sql, params)
    end)
    if not ok then
        return { success = false, error = tostring(result) }
    end
    return { success = true, data = result or {} }
end

--- 自分の順位（自分より上の人数 + 1）。ORDER は `GetRankingTopN` と同一タイブレーク
--- @param citizenid string
--- @return table { success, data?, error? }
function Database.GetMyRankInfo(citizenid)
    if type(citizenid) ~= 'string' or citizenid == '' then
        return { success = false, error = 'invalid citizenid' }
    end

    local exclude = rankingExcludeList()
    local notInClause, notInParams = rankingExcludeSql(exclude)

    local meRes = Database.GetPlayer(citizenid)
    if not (meRes.success and meRes.data) then
        return { success = false, error = 'player not found' }
    end
    local myRating = tonumber(meRes.data.rating) or 0

    local sqlAbove = ([[
SELECT COUNT(*) AS above
FROM tcg_players
WHERE citizenid <> ?
  AND (rating > ? OR (rating = ? AND citizenid < ?))%s
]]):format(notInClause)

    local sqlTotal = ([[
SELECT COUNT(*) AS total
FROM tcg_players
WHERE 1 = 1%s
]]):format(notInClause)

    local paramsAbove = { citizenid, myRating, myRating, citizenid }
    for _, cid in ipairs(notInParams) do
        paramsAbove[#paramsAbove + 1] = cid
    end

    local paramsTotal = {}
    for _, cid in ipairs(notInParams) do
        paramsTotal[#paramsTotal + 1] = cid
    end

    local ok1, r1 = pcall(function()
        return MySQL.query.await(sqlAbove, paramsAbove)
    end)
    local ok2, r2 = pcall(function()
        return MySQL.query.await(sqlTotal, paramsTotal)
    end)
    if not (ok1 and ok2) then
        return { success = false, error = tostring(r1 or r2) }
    end

    local above = tonumber(r1[1] and r1[1].above) or 0
    local total = tonumber(r2[1] and r2[1].total) or 0

    return {
        success = true,
        data = {
            rank = above + 1,
            rating = myRating,
            total = total,
        },
    }
end

--- 自分の直前後プレイヤー（上位 n + 自分 + 下位 n）。除外リスト適用
--- @param citizenid string
--- @param around number
--- @return table { success, data?, error? }
function Database.GetRankingAround(citizenid, around)
    if type(citizenid) ~= 'string' or citizenid == '' then
        return { success = false, error = 'invalid citizenid' }
    end

    local exclude = rankingExcludeList()
    local notInClause, notInParams = rankingExcludeSql(exclude)
    local n = tonumber(around) or 3
    if n < 0 then
        n = 0
    end

    local meRes = Database.GetPlayer(citizenid)
    if not (meRes.success and meRes.data) then
        return { success = false, error = 'player not found' }
    end
    local myRating = tonumber(meRes.data.rating) or 0

    local sqlUp = ([[
SELECT citizenid, rating, wins, losses, draws,
       pvp_exp, pvp_level, pvp_win_streak, display_name
FROM tcg_players
WHERE citizenid <> ?
  AND (rating > ? OR (rating = ? AND citizenid < ?))%s
ORDER BY rating ASC, citizenid DESC
LIMIT ?
]]):format(notInClause)

    local sqlDown = ([[
SELECT citizenid, rating, wins, losses, draws,
       pvp_exp, pvp_level, pvp_win_streak, display_name
FROM tcg_players
WHERE citizenid <> ?
  AND (rating < ? OR (rating = ? AND citizenid > ?))%s
ORDER BY rating DESC, citizenid ASC
LIMIT ?
]]):format(notInClause)

    local sqlSelf = [[
SELECT citizenid, rating, wins, losses, draws,
       pvp_exp, pvp_level, pvp_win_streak, display_name
FROM tcg_players
WHERE citizenid = ?
LIMIT 1
]]

    local paramsUp = { citizenid, myRating, myRating, citizenid }
    local paramsDown = { citizenid, myRating, myRating, citizenid }
    for _, cid in ipairs(notInParams) do
        paramsUp[#paramsUp + 1] = cid
        paramsDown[#paramsDown + 1] = cid
    end
    paramsUp[#paramsUp + 1] = n
    paramsDown[#paramsDown + 1] = n

    local okU, up = pcall(function()
        return MySQL.query.await(sqlUp, paramsUp)
    end)
    local okD, down = pcall(function()
        return MySQL.query.await(sqlDown, paramsDown)
    end)
    local okS, selfRows = pcall(function()
        return MySQL.query.await(sqlSelf, { citizenid })
    end)
    if not (okU and okD and okS) then
        return { success = false, error = tostring(up or down or selfRows) }
    end

    up = up or {}
    down = down or {}
    selfRows = selfRows or {}

    local result = {}
    for i = #up, 1, -1 do
        result[#result + 1] = up[i]
    end
    if selfRows[1] then
        result[#result + 1] = selfRows[1]
    end
    for _, row in ipairs(down) do
        result[#result + 1] = row
    end

    return { success = true, data = result }
end
