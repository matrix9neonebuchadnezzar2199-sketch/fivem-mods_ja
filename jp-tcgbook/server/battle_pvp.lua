--- PHASE 2b 本番 2 人対戦（雛形）
--- セッション生成・5 枚抽選・先攻・初期通知まで。着手検証・終了処理は後続コミット。

BattlePvp = BattlePvp or {}

--- @type table<string, table>
local PvpBattles = {}
--- @type table<number, string>  player src -> session_id
local srcToSessionId = {}

--- @param src number
--- @param payload { error: string }
local function pushLobbyErr(src, payload)
    if TcgBattleWireLogEnabled() then
        print(('[jp-tcgbook][wire] server->client battleLobbyError src=%d %s'):format(
            src, tostring(payload and payload.error)))
    end
    TriggerClientEvent('jp-tcgbook:client:battleLobbyError', src, payload)
end

--- @param card_id string
--- @return table|nil
local function masterRow(card_id)
    for _, m in ipairs(TcgCardsMaster or {}) do
        if m.card_id == card_id then
            return m
        end
    end
    return nil
end

--- @param m table
--- @return table
local function normalizeCardFromMaster(m)
    return {
        card_id = m.card_id,
        name = m.name or m.card_id,
        rank = m.rank,
        type = m.type,
        stat_top = tonumber(m.stat_top) or 0,
        stat_right = tonumber(m.stat_right) or 0,
        stat_bottom = tonumber(m.stat_bottom) or 0,
        stat_left = tonumber(m.stat_left) or 0,
    }
end

--- @param t table
local function shuffleInPlace(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end

--- @param uid string
--- @return table|nil deckPayload
--- @return string|nil err
local function loadActiveDeckFor(uid)
    local decks = Deck.GetAllDecks(uid)
    if not decks.success then
        return nil, decks.error or 'デッキ取得失敗'
    end
    local activeId = nil
    for _, d in ipairs(decks.data or {}) do
        if d.is_active == true or d.is_active == 1 then
            activeId = d.id
            break
        end
    end
    if not activeId then
        return nil, '使用デッキが設定されていません'
    end
    local g = Deck.GetDeck(uid, activeId)
    if not g.success or not g.data then
        return nil, '使用デッキの取得に失敗しました'
    end
    return g.data, nil
end

--- @param deckPayload table
--- @return table[]|nil hand
--- @return string|nil err
local function buildHandFiveFromDeck(deckPayload)
    if not deckPayload or not deckPayload.slots then
        return nil, 'デッキがありません'
    end
    local deckCards = {}
    for _, sl in ipairs(deckPayload.slots) do
        if sl and sl.card and sl.card.card_id then
            local m = masterRow(sl.card.card_id)
            if m then
                deckCards[#deckCards + 1] = normalizeCardFromMaster(m)
            end
        end
    end
    if #deckCards < Config.DeckSize then
        return nil, ('デッキが %d 枚未満です（要 %d 枚）'):format(#deckCards, Config.DeckSize)
    end
    shuffleInPlace(deckCards)
    local hand = {}
    local n = math.min(Config.HandSize or 5, #deckCards)
    for i = 1, n do
        hand[i] = deckCards[i]
    end
    return hand, nil
end

--- @param session table
--- @param viewer_src number
--- @return table
local function buildStartedPayload(session, viewer_src)
    local opp = viewer_src == session.p1_src and session.p2_src or session.p1_src
    return {
        session_id = session.session_id,
        my_hand = session.hands[viewer_src] or {},
        opponent_hand_count = 5,
        opponent_server_id = opp,
        board = TcgBattleRule.CreateEmptyBoard(),
        turn_server_id = session.turn,
        turn_no = session.turn_no,
        is_my_turn = viewer_src == session.first_src,
    }
end

--- @param session_id string
local function destroySession(session_id)
    local s = PvpBattles[session_id]
    if not s then
        return
    end
    PvpBattles[session_id] = nil
    srcToSessionId[s.p1_src] = nil
    srcToSessionId[s.p2_src] = nil
end

--- @param p1_src number ロビーから渡す第1引数（例: 待受側 tid）
--- @param p2_src number 第2引数（例: 呼び出し側 src）
--- @return boolean ok
function BattlePvp.Start(p1_src, p2_src)
    if p1_src == p2_src then
        local msg = '同一プレイヤーです'
        pushLobbyErr(p1_src, { error = msg })
        pushLobbyErr(p2_src, { error = msg })
        return false
    end

    local uid1 = GetPlayerUid(p1_src)
    local uid2 = GetPlayerUid(p2_src)
    if not uid1 or uid1 == '' then
        local msg = ('プレイヤー%d: 識別子を取得できません'):format(p1_src)
        pushLobbyErr(p1_src, { error = msg })
        pushLobbyErr(p2_src, { error = msg })
        return false
    end
    if not uid2 or uid2 == '' then
        local msg = ('プレイヤー%d: 識別子を取得できません'):format(p2_src)
        pushLobbyErr(p1_src, { error = msg })
        pushLobbyErr(p2_src, { error = msg })
        return false
    end

    local deck1, err1 = loadActiveDeckFor(uid1)
    if err1 then
        local msg = ('プレイヤー%d: %s'):format(p1_src, err1)
        pushLobbyErr(p1_src, { error = msg })
        pushLobbyErr(p2_src, { error = msg })
        return false
    end
    local deck2, err2 = loadActiveDeckFor(uid2)
    if err2 then
        local msg = ('プレイヤー%d: %s'):format(p2_src, err2)
        pushLobbyErr(p1_src, { error = msg })
        pushLobbyErr(p2_src, { error = msg })
        return false
    end

    local hand1, herr1 = buildHandFiveFromDeck(deck1)
    if herr1 then
        local msg = ('プレイヤー%d: %s'):format(p1_src, herr1)
        pushLobbyErr(p1_src, { error = msg })
        pushLobbyErr(p2_src, { error = msg })
        return false
    end
    local hand2, herr2 = buildHandFiveFromDeck(deck2)
    if herr2 then
        local msg = ('プレイヤー%d: %s'):format(p2_src, herr2)
        pushLobbyErr(p1_src, { error = msg })
        pushLobbyErr(p2_src, { error = msg })
        return false
    end

    math.randomseed(GetGameTimer() + p1_src * 31 + p2_src * 997)
    local first_src = math.random(2) == 1 and p1_src or p2_src
    local session_id = ('pvp_%d_%d_%d'):format(os.time(), p1_src, p2_src)

    --- 同一 ID の残留があれば破棄（通常は無い）
    destroySession(session_id)

    local session = {
        session_id = session_id,
        p1_src = p1_src,
        p2_src = p2_src,
        first_src = first_src,
        board = TcgBattleRule.CreateEmptyBoard(),
        hands = {
            [p1_src] = hand1,
            [p2_src] = hand2,
        },
        turn = first_src,
        turn_no = 1,
        started_at = os.time(),
    }

    PvpBattles[session_id] = session
    srcToSessionId[p1_src] = session_id
    srcToSessionId[p2_src] = session_id

    local pay1 = buildStartedPayload(session, p1_src)
    local pay2 = buildStartedPayload(session, p2_src)

    if TcgBattleWireLogEnabled() then
        print(('[jp-tcgbook][wire] BattlePvp.Start session=%s first_src=%d'):format(session_id, first_src))
        print(('[jp-tcgbook][wire] server->client battlePvpStarted src=%d session=%s'):format(
            p1_src, session_id))
        print(('[jp-tcgbook][wire] server->client battlePvpStarted src=%d session=%s'):format(
            p2_src, session_id))
    end
    TriggerClientEvent('jp-tcgbook:client:battlePvpStarted', p1_src, pay1)
    TriggerClientEvent('jp-tcgbook:client:battlePvpStarted', p2_src, pay2)

    return true
end

--- @param src number
--- @param ended_reason string|nil  相手へ渡す battlePvpEnded.reason（既定 peer_left）
function BattlePvp.OnPlayerLeave(src, ended_reason)
    local sid = srcToSessionId[src]
    if not sid then
        return
    end
    local session = PvpBattles[sid]
    if not session then
        srcToSessionId[src] = nil
        return
    end
    local p1, p2 = session.p1_src, session.p2_src
    local peer = src == p1 and p2 or p1
    local session_id = session.session_id
    local reason = ended_reason or 'peer_left'

    destroySession(session_id)

    if BattleLobbyClearPeerPairSilent then
        BattleLobbyClearPeerPairSilent(p1, p2)
    end

    if GetPlayerName(peer) ~= nil then
        if TcgBattleWireLogEnabled() then
            print(('[jp-tcgbook][wire] server->client battlePvpEnded src=%d session=%s reason=%s'):format(
                peer, session_id, reason))
        end
        TriggerClientEvent('jp-tcgbook:client:battlePvpEnded', peer, {
            session_id = session_id,
            reason = reason,
        })
    end
end

--- @param src number
--- @return table|nil
function BattlePvp.GetSessionBySrc(src)
    local sid = srcToSessionId[src]
    if not sid then
        return nil
    end
    return PvpBattles[sid]
end

--- battle_debug / battle_lobby 互換
--- @param src number
--- @return boolean
function BattlePvpInGame(src)
    return BattlePvp.GetSessionBySrc(src) ~= nil
end

--- openBook 復元は着手検証コミットまで未対応
--- @param _src number
--- @return nil
function BattlePvpGetClientState(_src)
    return nil
end
