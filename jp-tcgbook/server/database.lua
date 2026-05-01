--- jp-tcgbook データベース層（oxmysql / await）
--- 公開関数は原則 { success = bool, data = any?, error = string? } を返す

Database = {}

local resourceName = GetCurrentResourceName()

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

    local upsertSql = [[
INSERT INTO tcg_cards_master
    (card_id, name, rank, type, stat_top, stat_right, stat_bottom, stat_left, image_path, description, no)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
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
    no = VALUES(no)
]]

    local count = 0
    ok, err = pcall(function()
        for _, c in ipairs(TcgCardsMaster) do
            MySQL.query.await(upsertSql, {
                c.card_id,
                c.name,
                c.rank,
                c.type,
                c.stat_top,
                c.stat_right,
                c.stat_bottom,
                c.stat_left,
                c.image_path,
                c.description,
                c.no,
            })
            count = count + 1
        end
    end)

    if not ok then
        return { success = false, error = 'カードマスタUPSERT失敗: ' .. tostring(err) }
    end

    return { success = true, data = { cardMasterCount = count } }
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

function Database.GetPlayerCards(citizenid)
    local sql = [[
SELECT
    pc.instance_id,
    pc.citizenid,
    pc.card_id,
    pc.obtained_at,
    pc.locked,
    m.name,
    m.rank,
    m.type,
    m.stat_top,
    m.stat_right,
    m.stat_bottom,
    m.stat_left,
    m.image_path,
    m.description,
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
    m.rank,
    m.type,
    m.stat_top,
    m.stat_right,
    m.stat_bottom,
    m.stat_left,
    m.image_path,
    m.description,
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
                card = {
                    card_id = r.card_id,
                    name = r.name,
                    rank = r.rank,
                    type = r.type,
                    stat_top = r.stat_top,
                    stat_right = r.stat_right,
                    stat_bottom = r.stat_bottom,
                    stat_left = r.stat_left,
                    image_path = r.image_path,
                    description = r.description,
                    no = r.no,
                },
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
