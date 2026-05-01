--- 所持カード・初回配布（サーバー権威）

Collection = {}

--- @param citizenid string
--- @return boolean
function Collection.IsInitialized(citizenid)
    local r = Database.GetPlayer(citizenid)
    if not r.success or not r.data then
        return false
    end
    local v = r.data.initialized
    return v == true or v == 1
end

--- Config.InitialCardRanks に沿ってフリーカードを10枚選ぶ（同名最大2枚）
--- @return table|nil, string|nil error
local function pickInitialCardIds()
    local freeByRank = {}
    for _, c in ipairs(TcgCardsMaster) do
        if c.type == 'free' then
            local list = freeByRank[c.rank]
            if not list then
                list = {}
                freeByRank[c.rank] = list
            end
            list[#list + 1] = c.card_id
        end
    end

    local counts = {}
    local selected = {}

    for _, rank in ipairs(Config.InitialCardRanks) do
        local pool = freeByRank[rank]
        if not pool or #pool == 0 then
            return nil, 'ランク ' .. rank .. ' のフリーカードがマスタに存在しません'
        end

        local candidates = {}
        for _, cid in ipairs(pool) do
            if (counts[cid] or 0) < Config.CardLimit.free then
                candidates[#candidates + 1] = cid
            end
        end

        if #candidates == 0 then
            candidates = {}
            for _, c in ipairs(TcgCardsMaster) do
                if c.type == 'free' and (counts[c.card_id] or 0) < Config.CardLimit.free then
                    candidates[#candidates + 1] = c.card_id
                end
            end
        end

        if #candidates == 0 then
            return nil, '初回配布の組み合わせを生成できませんでした'
        end

        local pick = candidates[math.random(1, #candidates)]
        selected[#selected + 1] = pick
        counts[pick] = (counts[pick] or 0) + 1
    end

    return selected
end

--- 初回のみ: カード10枚 + マイデッキ作成 + スロット投入 + initialized
--- @param citizenid string
function Collection.InitializePlayer(citizenid)
    if Collection.IsInitialized(citizenid) then
        return { success = false, error = '既に初期化済みです' }
    end

    local pc = Database.GetPlayerCards(citizenid)
    if pc.success and pc.data and #pc.data > 0 then
        return { success = false, error = 'データが不整合です。/tcg_reset を実行してください。' }
    end

    local selected, pickErr = pickInitialCardIds()
    if not selected then
        return { success = false, error = pickErr or '初回配布に失敗しました' }
    end

    local queries = {}

    queries[#queries + 1] = {
        query = [[INSERT INTO tcg_players (citizenid, initialized, rating, wins, losses, draws)
VALUES (?, FALSE, ?, 0, 0, 0)
ON DUPLICATE KEY UPDATE citizenid = VALUES(citizenid)]],
        values = { citizenid, Config.InitialRating },
    }

    for _, cardId in ipairs(selected) do
        queries[#queries + 1] = {
            query = 'INSERT INTO tcg_player_cards (citizenid, card_id) VALUES (?, ?)',
            values = { citizenid, cardId },
        }
    end

    queries[#queries + 1] = {
        query = 'INSERT INTO tcg_decks (citizenid, name, is_active) VALUES (?, ?, TRUE)',
        values = { citizenid, 'マイデッキ' },
    }

    local parts = {}
    local vals = {}
    for i = 1, 10 do
        parts[#parts + 1] = '(LAST_INSERT_ID(), ?, ?)'
        vals[#vals + 1] = i
        vals[#vals + 1] = selected[i]
    end

    queries[#queries + 1] = {
        query = 'INSERT INTO tcg_deck_cards (deck_id, slot_index, card_id) VALUES '
            .. table.concat(parts, ','),
        values = vals,
    }

    queries[#queries + 1] = {
        query = 'UPDATE tcg_players SET initialized = TRUE WHERE citizenid = ?',
        values = { citizenid },
    }

    local ok, txRes = pcall(function()
        return MySQL.transaction.await(queries)
    end)

    if not ok then
        return { success = false, error = tostring(txRes) }
    end

    if txRes == false then
        return { success = false, error = '初期化トランザクションに失敗しました' }
    end

    local idRow = MySQL.single.await(
        'SELECT id FROM tcg_decks WHERE citizenid = ? AND name = ? ORDER BY id DESC LIMIT 1',
        { citizenid, 'マイデッキ' }
    )

    local deckId = idRow and idRow.id

    return {
        success = true,
        data = {
            deckId = deckId,
            cardCount = #selected,
        },
    }
end

--- @param citizenid string
function Collection.GetCollection(citizenid)
    return Database.GetPlayerCards(citizenid)
end
