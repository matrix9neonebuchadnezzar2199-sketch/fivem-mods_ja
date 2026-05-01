--- jp-tcgbook サーバーエントリ・NUI向けイベント

--- 識別子が取れないプレイヤーは処理拒否（暫定キーは使わない）
--- @param source number
--- @return string|nil citizenid
function getUidOrReject(source)
    local uid = GetPlayerUid(source)
    if not uid then
        TriggerClientEvent('chat:addMessage', source, {
            args = { '[tcg]', 'プレイヤー識別子を取得できませんでした。' },
        })
        print(('[tcg] WARN: プレイヤー識別子取得失敗 source=%d'):format(source))
        return nil
    end
    return uid
end

local function trim(s)
    return (s or ''):match('^%s*(.-)%s*$') or ''
end

--- @return number|nil
local function parseDeckId(raw)
    local n = tonumber(raw)
    if not n or n < 1 or math.floor(n) ~= n then
        return nil
    end
    return n
end

--- @return number|nil
local function parseSlot(raw)
    local n = tonumber(raw)
    if not n or n < 1 or n > Config.DeckSize or math.floor(n) ~= n then
        return nil
    end
    return n
end

--- @return string|nil
local function parseCardId(raw)
    if raw == nil then
        return nil
    end
    if type(raw) ~= 'string' then
        raw = tostring(raw)
    end
    local s = trim(raw)
    if s == '' then
        return nil
    end
    return s
end

--- 名前（作成・リネーム共通の入口検証。詳細は Deck 側でも検証）
--- @return string|nil
local function parseDeckName(raw)
    if type(raw) ~= 'string' then
        return nil
    end
    local s = trim(raw)
    if #s < 1 or #s > 64 then
        return nil
    end
    return s
end

--- @param citizenid string
--- @return table
local function buildDeckListPayload(citizenid)
    local decksR = Deck.GetAllDecks(citizenid)
    if not decksR.success then
        return { success = false, error = decksR.error or 'デッキ一覧の取得に失敗しました' }
    end

    local cardsR = Collection.GetCollection(citizenid)
    if not cardsR.success then
        return { success = false, error = cardsR.error or '所持カードの取得に失敗しました' }
    end

    local activeId = nil
    for _, d in ipairs(decksR.data or {}) do
        if d.is_active == true or d.is_active == 1 then
            activeId = d.id
            break
        end
    end

    local activeDeck = nil
    if activeId then
        local g = Deck.GetDeck(citizenid, activeId)
        if g.success then
            activeDeck = g.data
        end
    end

    return {
        success = true,
        data = {
            decks = decksR.data or {},
            activeDeck = activeDeck,
            cards = cardsR.data or {},
            cardsMaster = TcgCardsMaster,
        },
    }
end

local function replyBookData(src, payload)
    TriggerClientEvent('jp-tcgbook:client:bookData', src, payload)
end

local function replyDeckSelected(src, payload)
    TriggerClientEvent('jp-tcgbook:client:deckSelected', src, payload)
end

local function replyDeckUpdated(src, payload)
    TriggerClientEvent('jp-tcgbook:client:deckUpdated', src, payload)
end

local function replyDeckListUpdated(src, payload)
    TriggerClientEvent('jp-tcgbook:client:deckListUpdated', src, payload)
end

RegisterNetEvent('jp-tcgbook:server:openBook', function()
    local src = source
    local uid = getUidOrReject(src)
    if not uid then
        return
    end

    print(('[tcg] openBook 受信 src=%d uid=%s'):format(src, uid))

    if not Collection.IsInitialized(uid) then
        local init = Collection.InitializePlayer(uid)
        if not init.success then
            replyBookData(src, init)
            return
        end
    end

    local player = Database.GetPlayer(uid)
    if not player.success then
        replyBookData(src, { success = false, error = player.error or 'プレイヤー情報の取得に失敗しました' })
        return
    end

    local cards = Collection.GetCollection(uid)
    if not cards.success then
        replyBookData(src, { success = false, error = cards.error or '所持カードの取得に失敗しました' })
        return
    end

    local decks = Deck.GetAllDecks(uid)
    if not decks.success then
        replyBookData(src, { success = false, error = decks.error or 'デッキ一覧の取得に失敗しました' })
        return
    end

    replyBookData(src, {
        success = true,
        data = {
            player = player.data,
            cards = cards.data or {},
            decks = decks.data or {},
            cardsMaster = TcgCardsMaster,
        },
    })
end)

RegisterNetEvent('jp-tcgbook:server:selectDeck', function(data)
    local src = source
    local uid = getUidOrReject(src)
    if not uid then
        return
    end

    data = data or {}
    local deckId = parseDeckId(data.deck_id)
    if not deckId then
        replyDeckSelected(src, { success = false, error = '不正なデッキIDです' })
        return
    end

    local result = Deck.GetDeck(uid, deckId)
    replyDeckSelected(src, result)
end)

RegisterNetEvent('jp-tcgbook:server:addCardToDeck', function(data)
    local src = source
    local uid = getUidOrReject(src)
    if not uid then
        return
    end

    data = data or {}
    local deckId = parseDeckId(data.deck_id)
    local cardId = parseCardId(data.card_id)
    if not deckId then
        replyDeckUpdated(src, { success = false, error = '不正なデッキIDです' })
        return
    end
    if not cardId then
        replyDeckUpdated(src, { success = false, error = '不正なカードIDです' })
        return
    end

    local r = Deck.AddCardToDeck(uid, deckId, cardId)
    if not r.success then
        replyDeckUpdated(src, r)
        return
    end

    replyDeckUpdated(src, Deck.GetDeck(uid, deckId))
end)

RegisterNetEvent('jp-tcgbook:server:removeDeckCard', function(data)
    local src = source
    local uid = getUidOrReject(src)
    if not uid then
        return
    end

    data = data or {}
    local deckId = parseDeckId(data.deck_id)
    local slot = parseSlot(data.slot)
    if not deckId then
        replyDeckUpdated(src, { success = false, error = '不正なデッキIDです' })
        return
    end
    if not slot then
        replyDeckUpdated(src, { success = false, error = '不正なスロットです（1〜10）' })
        return
    end

    local r = Deck.RemoveCardFromDeck(uid, deckId, slot)
    if not r.success then
        replyDeckUpdated(src, r)
        return
    end

    replyDeckUpdated(src, Deck.GetDeck(uid, deckId))
end)

RegisterNetEvent('jp-tcgbook:server:createDeck', function(data)
    local src = source
    local uid = getUidOrReject(src)
    if not uid then
        return
    end

    data = data or {}
    local name = parseDeckName(data.name)
    if not name then
        replyDeckListUpdated(src, { success = false, error = 'デッキ名は1〜64文字で入力してください' })
        return
    end

    local r = Deck.CreateDeck(uid, name)
    if not r.success then
        replyDeckListUpdated(src, r)
        return
    end

    replyDeckListUpdated(src, buildDeckListPayload(uid))
end)

RegisterNetEvent('jp-tcgbook:server:duplicateDeck', function(data)
    local src = source
    local uid = getUidOrReject(src)
    if not uid then
        return
    end

    data = data or {}
    local deckId = parseDeckId(data.deck_id)
    if not deckId then
        replyDeckListUpdated(src, { success = false, error = '不正なデッキIDです' })
        return
    end

    local r = Deck.DuplicateDeck(uid, deckId)
    if not r.success then
        replyDeckListUpdated(src, r)
        return
    end

    replyDeckListUpdated(src, buildDeckListPayload(uid))
end)

RegisterNetEvent('jp-tcgbook:server:deleteDeck', function(data)
    local src = source
    local uid = getUidOrReject(src)
    if not uid then
        return
    end

    data = data or {}
    local deckId = parseDeckId(data.deck_id)
    if not deckId then
        replyDeckListUpdated(src, { success = false, error = '不正なデッキIDです' })
        return
    end

    local r = Deck.DeleteDeck(uid, deckId)
    if not r.success then
        replyDeckListUpdated(src, r)
        return
    end

    replyDeckListUpdated(src, buildDeckListPayload(uid))
end)

RegisterNetEvent('jp-tcgbook:server:renameDeck', function(data)
    local src = source
    local uid = getUidOrReject(src)
    if not uid then
        return
    end

    data = data or {}
    local deckId = parseDeckId(data.deck_id)
    local newName = parseDeckName(data.new_name)
    if not deckId then
        replyDeckListUpdated(src, { success = false, error = '不正なデッキIDです' })
        return
    end
    if not newName then
        replyDeckListUpdated(src, { success = false, error = 'デッキ名は1〜64文字で入力してください' })
        return
    end

    local r = Deck.RenameDeck(uid, deckId, newName)
    if not r.success then
        replyDeckListUpdated(src, r)
        return
    end

    replyDeckListUpdated(src, buildDeckListPayload(uid))
end)

RegisterNetEvent('jp-tcgbook:server:setActiveDeck', function(data)
    local src = source
    local uid = getUidOrReject(src)
    if not uid then
        return
    end

    data = data or {}
    local deckId = parseDeckId(data.deck_id)
    if not deckId then
        replyDeckListUpdated(src, { success = false, error = '不正なデッキIDです' })
        return
    end

    local r = Deck.SetActiveDeck(uid, deckId)
    if not r.success then
        replyDeckListUpdated(src, r)
        return
    end

    replyDeckListUpdated(src, buildDeckListPayload(uid))
end)

CreateThread(function()
    local result = Database.InitializeTables()
    if not result.success then
        print('[tcg] FATAL Database.InitializeTables: ' .. tostring(result.error))
        return
    end

    print('[tcg] テーブル作成完了')
    local n = (result.data and result.data.cardMasterCount) or #TcgCardsMaster
    print(('[tcg] カードマスタ %d 件 UPSERT 完了'):format(n))
end)
