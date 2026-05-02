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

    --- M6 後追い: ランキング・履歴に出すユーザー名を更新（ベストエフォート、失敗しても openBook は続行）
    local dispName = GetPlayerDisplayName(src)
    if dispName and dispName ~= '' then
        Database.UpsertPlayerDisplayName(uid, dispName)
        --- NUI ヘッダ即時反映: 上の GetPlayer は UPSERT 前の行で display_name が NULL のことがある
        if player.data then
            player.data.display_name = dispName
        end
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

    local activeDeckId = nil
    for _, d in ipairs(decks.data or {}) do
        if d.is_active == true or d.is_active == 1 then
            activeDeckId = d.id
            break
        end
    end

    local activeDeckPayload = nil
    if activeDeckId then
        local g = Deck.GetDeck(uid, activeDeckId)
        if g.success then
            activeDeckPayload = g.data
        end
    end

    local battlePeer = BattleLobbyGetPeer(src)

    local histRows = {}
    local histRes = Database.ListMatchHistoryForCitizenid(uid, nil)
    if histRes.success and histRes.data then
        histRows = histRes.data
    end

    replyBookData(src, {
        success = true,
        data = {
            player = player.data,
            cards = cards.data or {},
            decks = decks.data or {},
            cardsMaster = TcgCardsMaster,
            activeDeck = activeDeckPayload,
            match_history = histRows,
            battleSession = battlePeer and { peer_server_id = battlePeer } or nil,
            -- NUI: デッキ自動保存デバウンス（ms）。0 でキューをほぼ即 flush
            ui = {
                autoSaveDebounceMs = math.max(0, math.floor(tonumber(Config.AutoSaveDebounceMs) or 500)),
                --- 仮想対戦の呼び出し番号（FiveM のサーバーID）
                playerServerId = src,
                --- Config.DebugCommands のとき NUI にデバッグ対戦ロビーを出す
                allow_debug_battle = Config.DebugCommands == true,
                --- NUI コンソールに fetch / message の往復ログ（TcgBattleWireLogEnabled）
                wire_log = TcgBattleWireLogEnabled(),
                --- 疑似PvPソロが本番 Finish 経路になるか（DebugCommands 時のみ StartSolo 可のため実質同義・履歴タブ説明用）
                pvp_solo_finish_hooks = Config.DebugCommands == true,
                --- PHASE E4: ランキングタブ表示（Config.EnableRankingUi）
                enable_ranking_ui = Config.EnableRankingUi == true,
            },
            --- BOOK 再オープン時にデバッグ対戦状態を復元表示
            battleCpuSession = BattleDebugGetClientState and BattleDebugGetClientState(src) or nil,
            --- 本番 2 人対戦の復元（再オープン時）
            battlePvpSession = BattlePvpGetClientState and BattlePvpGetClientState(src) or nil,
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

RegisterNetEvent('jp-tcgbook:server:requestRankingData', function()
    local src = source
    local uid = getUidOrReject(src)
    if not uid then
        return
    end

    if Config.EnableRankingUi ~= true then
        TriggerClientEvent('jp-tcgbook:client:rankingData', src, {
            success = false,
            error = 'ランキングは無効です',
        })
        return
    end

    local topN = tonumber(Config.RankingDisplayLimit) or 50
    local top = Database.GetRankingTopN(topN)
    local mine = Database.GetMyRankInfo(uid)

    local inTop = false
    if top.success and top.data then
        for _, row in ipairs(top.data) do
            if row.citizenid == uid then
                inTop = true
                break
            end
        end
    end

    local around = {}
    if top.success and mine.success and (not inTop) and mine.data then
        local ar = Database.GetRankingAround(uid, 3)
        if ar.success and ar.data then
            around = ar.data
        end
    end

    --- M6: 段位（SQL は変更せずペイロードに rank_code / badge を注入）
    if top.success and top.data then
        for _, row in ipairs(top.data) do
            EnrichRankingRowWithTier(row)
        end
    end
    for _, row in ipairs(around) do
        EnrichRankingRowWithTier(row)
    end
    if mine.success and mine.data then
        EnrichRankingRowWithTier(mine.data)
    end

    --- `GetMyRankInfo` は rank/rating/total のみのため、表示名・citizenid をマスタ行から付与
    if mine.success and mine.data then
        mine.data.citizenid = uid
        local pr = Database.GetPlayer(uid)
        if pr.success and pr.data then
            mine.data.display_name = pr.data.display_name
        end
    end

    --- NUI は NULL をフォールバック表示に回す（空文字は nil に正規化）
    local function normalizeRankingDisplayName(row)
        if type(row) ~= 'table' then
            return
        end
        local d = row.display_name
        if type(d) == 'string' and d ~= '' then
            return
        end
        row.display_name = nil
    end

    if top.success and top.data then
        for _, row in ipairs(top.data) do
            normalizeRankingDisplayName(row)
        end
    end
    for _, row in ipairs(around) do
        normalizeRankingDisplayName(row)
    end
    if mine.success and mine.data then
        normalizeRankingDisplayName(mine.data)
    end

    local ok = top.success and mine.success
    local errMsg = nil
    if not ok then
        errMsg = (not top.success and top.error) or (not mine.success and mine.error) or 'ランキング取得に失敗しました'
    end

    TriggerClientEvent('jp-tcgbook:client:rankingData', src, {
        success = ok,
        error = errMsg,
        season = 'evergreen',
        top = top.data or {},
        my_info = mine.data,
        my_in_top = inTop,
        around_me = around,
        my_citizenid = uid,
    })

    if TcgBattleWireLogEnabled() then
        local function shortCid(cid)
            if type(cid) ~= 'string' or cid == '' then
                return '?'
            end
            if #cid <= 8 then
                return cid
            end
            return cid:sub(-8)
        end
        local mi = mine.data
        local rc = mi and mi.rank_code or ''
        local bd = mi and mi.badge or ''
        local md = mi and mi.display_name
        print(('[jp-tcgbook][wire][ranking] sent src=%s top_rows=%s in_top=%s rank=%s my_rank_code=%s my_badge=%s my_disp=%s my_cid_tail=%s'):format(
            tostring(src),
            tostring(top.data and #top.data),
            tostring(inTop),
            tostring(mi and mi.rank),
            tostring(rc),
            tostring(bd),
            tostring(md ~= nil and md or '<nil>'),
            shortCid(mi and mi.citizenid)
        ))
    end
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
