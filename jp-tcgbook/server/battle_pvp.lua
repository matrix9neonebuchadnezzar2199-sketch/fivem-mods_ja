--- 本番 2 人対戦（仮想ロビー成立後・サーバー権威・PHASE A 準拠）
--- CPU デバッグ戦（battle_debug.lua）と同一ルール。各クライアントへは視点変換済みペイロード（human=自分・cpu=相手）を送る。

--- @type table<string, table>  session_key -> game state
local sessions = {}
--- @type table<number, string>  player src -> session_key
local srcToSession = {}

--- @param a number
--- @param b number
--- @return string
local function makeSessionKey(a, b)
    if a < b then
        return tostring(a) .. '_' .. tostring(b)
    end
    return tostring(b) .. '_' .. tostring(a)
end

--- @param idx integer 1..9
--- @return integer r, integer c  0..2
local function idxToRc(idx)
    local z = idx - 1
    return z // 3, z % 3
end

--- @param r integer
--- @param c integer
--- @return integer
local function rcToIdx(r, c)
    return r * 3 + c + 1
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
local function cardFromMaster(m)
    return {
        card_id = m.card_id,
        name = m.name or m.card_id,
        rank = m.rank,
        type = m.type,
        stat_top = tonumber(m.stat_top) or 0,
        stat_right = tonumber(m.stat_right) or 0,
        stat_bottom = tonumber(m.stat_bottom) or 0,
        stat_left = tonumber(m.stat_left) or 0,
        image_path = m.image_path or '',
    }
end

--- @param t table
local function shuffleInPlace(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end

--- @param st table
--- @param viewer number
--- @return number
local function opponentSrc(st, viewer)
    if viewer == st.p1 then
        return st.p2
    end
    return st.p1
end

--- @param st table
--- @param idx integer 1..9
--- @param ownerSrc number
--- @param card table
local function applyCaptures(st, idx, ownerSrc, card)
    local r, c = idxToRc(idx)
    local opp = opponentSrc(st, ownerSrc)
    local checks = {
        { nr = r - 1, nc = c, my = card.stat_top, oppKey = 'stat_bottom' },
        { nr = r + 1, nc = c, my = card.stat_bottom, oppKey = 'stat_top' },
        { nr = r, nc = c - 1, my = card.stat_left, oppKey = 'stat_right' },
        { nr = r, nc = c + 1, my = card.stat_right, oppKey = 'stat_left' },
    }
    for _, ch in ipairs(checks) do
        if ch.nr >= 0 and ch.nr <= 2 and ch.nc >= 0 and ch.nc <= 2 then
            local ni = rcToIdx(ch.nr, ch.nc)
            local cell = st.board[ni]
            if cell and cell.owner == opp then
                local ostat = tonumber(cell.card[ch.oppKey]) or 0
                if ch.my > ostat then
                    cell.owner = ownerSrc
                end
            end
        end
    end
end

--- @param st table
--- @return boolean
local function boardFull(st)
    for i = 1, 9 do
        if st.board[i] == nil then
            return false
        end
    end
    return true
end

--- @param st table
--- @param src number
--- @return integer
local function scoreFor(st, src)
    local opp = opponentSrc(st, src)
    local boardCount = 0
    for i = 1, 9 do
        local cell = st.board[i]
        if cell and cell.owner == src then
            boardCount = boardCount + 1
        end
    end
    local handCount = #(st.hands[src] or {})
    return boardCount + handCount
end

--- @param st table
--- @return boolean
local function finalizeIfEnded(st)
    if not boardFull(st) then
        return false
    end
    st.phase = 'ended'
    local s1, s2 = st.p1, st.p2
    local sc1, sc2 = scoreFor(st, s1), scoreFor(st, s2)
    st.raw_scores = { [s1] = sc1, [s2] = sc2 }
    if sc1 > sc2 then
        st.winner_src = s1
    elseif sc2 > sc1 then
        st.winner_src = s2
    else
        st.winner_src = 'draw'
    end
    return true
end

--- @param st table
--- @param viewer number 受信クライアントの source
--- @return table
local function buildClientPayload(st, viewer)
    local opp = opponentSrc(st, viewer)
    local board = {}
    for i = 1, 9 do
        local cell = st.board[i]
        if cell then
            local own = cell.owner == viewer and 'human' or 'cpu'
            board[tostring(i)] = { owner = own, card = cell.card }
        end
    end
    local myScore, oppScore = scoreFor(st, viewer), scoreFor(st, opp)
    local winnerUi = nil
    if st.phase == 'ended' then
        if st.winner_src == 'draw' then
            winnerUi = 'draw'
        elseif st.winner_src == viewer then
            winnerUi = 'human'
        else
            winnerUi = 'cpu'
        end
    end
    return {
        mode = 'pvp',
        pvp_session_id = st.session_key,
        turn_seq = st.turn_seq,
        phase = st.phase,
        turn = st.turn_src == viewer and 'human' or 'cpu',
        board = board,
        human_hand = st.hands[viewer] or {},
        cpu_hand_count = #(st.hands[opp] or {}),
        scores = st.phase == 'ended' and { human = myScore, cpu = oppScore } or nil,
        winner = winnerUi,
        first_player = st.first_src == viewer and 'human' or 'cpu',
        log = st.log or {},
    }
end

--- @param src number
--- @param payload { error: string }
local function pushLobbyErr(src, payload)
    if TcgBattleWireLogEnabled() then
        print(('[jp-tcgbook][wire] server->client battleLobbyError src=%d %s'):format(
            src, tostring(payload and payload.error)))
    end
    TriggerClientEvent('jp-tcgbook:client:battleLobbyError', src, payload)
end

--- @param src number
--- @param st table
local function pushState(src, st)
    if TcgBattleWireLogEnabled() then
        print(('[jp-tcgbook][wire] server->client battlePvpState src=%d phase=%s turn=%s seq=%s'):format(
            src, tostring(st.phase), tostring(st.turn_src), tostring(st.turn_seq)))
    end
    TriggerClientEvent('jp-tcgbook:client:battlePvpState', src, buildClientPayload(st, src))
end

--- @param st table
--- @param p1 number
--- @param p2 number
local function pushStateBoth(st, p1, p2)
    pushState(p1, st)
    pushState(p2, st)
end

--- @param src number
--- @return boolean
function BattlePvpInGame(src)
    return srcToSession[src] ~= nil
end

--- セッション除去（通知なし・内部用）
--- @param session_key string
local function destroySessionInternal(session_key)
    local st = sessions[session_key]
    if not st then
        return
    end
    sessions[session_key] = nil
    srcToSession[st.p1] = nil
    srcToSession[st.p2] = nil
end

--- openBook 復元用
--- @param src number
--- @return table|nil
function BattlePvpGetClientState(src)
    local key = srcToSession[src]
    if not key then
        return nil
    end
    local st = sessions[key]
    if not st then
        return nil
    end
    return buildClientPayload(st, src)
end

--- @param src number
--- @param reason string|nil
local function notifyBattlePvpEnded(src, reason)
    if TcgBattleWireLogEnabled() then
        print(('[jp-tcgbook][wire] server->client battlePvpEnded src=%s reason=%s'):format(
            tostring(src), tostring(reason)))
    end
    TriggerClientEvent('jp-tcgbook:client:battlePvpEnded', src, {
        reason = reason,
    })
end

--- 通常終了または切断：両者へ battlePvpEnded、セッション削除
--- @param st table
--- @param reason string|nil
local function endSessionNotifyBoth(st, reason)
    local a, b = st.p1, st.p2
    destroySessionInternal(st.session_key)
    notifyBattlePvpEnded(a, reason)
    notifyBattlePvpEnded(b, reason)
end

--- 相手退出時：virtualBattleEnded（設計書 PHASE 2b）
--- @param p1 number
--- @param p2 number
--- @param reason string
local function notifyVirtualBattleEndedBoth(p1, p2, reason)
    local payload = { reason = reason }
    if TcgBattleWireLogEnabled() then
        print(('[jp-tcgbook][wire] server->client virtualBattleEnded src=%d reason=%s'):format(p1, reason))
        print(('[jp-tcgbook][wire] server->client virtualBattleEnded src=%d reason=%s'):format(p2, reason))
    end
    TriggerClientEvent('jp-tcgbook:client:virtualBattleEnded', p1, payload)
    TriggerClientEvent('jp-tcgbook:client:virtualBattleEnded', p2, payload)
end

--- BOOK 閉じ・明示離脱・DC（対局中）
--- @param src number
--- @param virtual_reason string|nil  virtualBattleEnded の reason（nil なら送らない）
function BattlePvpLeave(src, virtual_reason)
    local key = srcToSession[src]
    if not key then
        return
    end
    local st = sessions[key]
    if not st then
        srcToSession[src] = nil
        return
    end
    local p1, p2 = st.p1, st.p2
    destroySessionInternal(key)
    notifyBattlePvpEnded(src, 'left')
    notifyBattlePvpEnded(peer, 'peer_left')
    if BattleLobbyClearPeerPairSilent then
        BattleLobbyClearPeerPairSilent(p1, p2)
    end
    if virtual_reason then
        notifyVirtualBattleEndedBoth(p1, p2, virtual_reason)
    end
end

--- 対局完了時：ロビーペアだけ解除（virtual は送らない）
--- @param st table
function BattlePvpNotifyGameComplete(st)
    endSessionNotifyBoth(st, 'complete')
    if BattleLobbyClearPeerPairSilent then
        BattleLobbyClearPeerPairSilent(st.p1, st.p2)
    end
end

--- @param uid string
--- @return table|nil deck payload, string|nil err
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
--- @return table[]|nil cards
--- @return string|nil err
local function buildHandFromDeck(deckPayload)
    if not deckPayload or not deckPayload.slots then
        return nil, 'デッキがありません'
    end
    local deckCards = {}
    for _, sl in ipairs(deckPayload.slots) do
        if sl and sl.card and sl.card.card_id then
            local m = masterRow(sl.card.card_id)
            if m then
                deckCards[#deckCards + 1] = cardFromMaster(m)
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

--- ロビー成立後に呼ぶ。成功時のみセッション生成・初期 state 配信。
--- @param p1_src number
--- @param p2_src number
--- @return boolean ok
--- @return string|nil err
function BattlePvpStart(p1_src, p2_src)
    if p1_src == p2_src then
        return false, '同一プレイヤーです'
    end
    local uid1 = GetPlayerUid(p1_src)
    local uid2 = GetPlayerUid(p2_src)
    if not uid1 or uid1 == '' or not uid2 or uid2 == '' then
        return false, '識別子を取得できません'
    end

    local deck1, err1 = loadActiveDeckFor(uid1)
    if err1 then
        return false, ('プレイヤー%d: %s'):format(p1_src, err1)
    end
    local deck2, err2 = loadActiveDeckFor(uid2)
    if err2 then
        return false, ('プレイヤー%d: %s'):format(p2_src, err2)
    end

    local hand1, herr1 = buildHandFromDeck(deck1)
    if herr1 then
        return false, ('プレイヤー%d: %s'):format(p1_src, herr1)
    end
    local hand2, herr2 = buildHandFromDeck(deck2)
    if herr2 then
        return false, ('プレイヤー%d: %s'):format(p2_src, herr2)
    end

    math.randomseed(GetGameTimer() + p1_src * 31 + p2_src * 997)
    local first = math.random(2) == 1 and p1_src or p2_src

    local session_key = makeSessionKey(p1_src, p2_src)
    --- 既存があれば潰す（通常は無い）
    destroySessionInternal(session_key)

    local st = {
        session_key = session_key,
        p1 = p1_src < p2_src and p1_src or p2_src,
        p2 = p1_src < p2_src and p2_src or p1_src,
        board = {},
        hands = {
            [p1_src] = hand1,
            [p2_src] = hand2,
        },
        turn_src = first,
        turn_seq = 0,
        phase = 'playing',
        first_src = first,
        log = { ('先攻: サーバーID %d'):format(first) },
    }

    sessions[session_key] = st
    srcToSession[p1_src] = session_key
    srcToSession[p2_src] = session_key

    pushStateBoth(st, p1_src, p2_src)
    return true, nil
end

RegisterNetEvent('jp-tcgbook:server:battlePvpPlace', function(data)
    local src = source
    data = data or {}
    if TcgBattleWireLogEnabled() then
        print(('[jp-tcgbook][wire] server recv battlePvpPlace src=%d cell=%s hand=%s seq=%s'):format(
            src, tostring(data.cell_index), tostring(data.hand_index), tostring(data.turn_seq)))
    end
    local uid = getUidOrReject(src)
    if not uid then
        return
    end

    local key = srcToSession[src]
    if not key then
        pushLobbyErr(src, { error = '対戦セッションがありません' })
        return
    end
    local st = sessions[key]
    if not st or st.phase ~= 'playing' then
        pushLobbyErr(src, { error = '対局中ではありません' })
        return
    end

    local sid = data.pvp_session_id
    if sid ~= st.session_key then
        pushLobbyErr(src, { error = 'セッションIDが一致しません' })
        return
    end

    local seq = tonumber(data.turn_seq)
    if not seq or seq ~= st.turn_seq then
        pushLobbyErr(src, { error = '手番シーケンスが不正です（同期ずれ）' })
        return
    end

    if st.turn_src ~= src then
        pushLobbyErr(src, { error = '相手のターンです' })
        return
    end

    local cellIdx = tonumber(data.cell_index)
    local handIdx = tonumber(data.hand_index)
    if not cellIdx or cellIdx < 1 or cellIdx > 9 or math.floor(cellIdx) ~= cellIdx then
        pushLobbyErr(src, { error = 'マスが不正です（1〜9）' })
        return
    end
    handIdx = handIdx and math.floor(handIdx) or -1
    local myHand = st.hands[src] or {}
    if handIdx < 0 or handIdx >= #myHand then
        pushLobbyErr(src, { error = '手札インデックスが不正です（0 から）' })
        return
    end
    if st.board[cellIdx] ~= nil then
        pushLobbyErr(src, { error = 'そのマスは埋まっています' })
        return
    end

    local card = table.remove(myHand, handIdx + 1)
    st.board[cellIdx] = { owner = src, card = card }
    applyCaptures(st, cellIdx, src, card)
    st.log[#st.log + 1] = ('サーバーID %d: マス %d に配置'):format(src, cellIdx)

    st.turn_seq = st.turn_seq + 1
    if finalizeIfEnded(st) then
        local v1, v2 = scoreFor(st, st.p1), scoreFor(st, st.p2)
        st.log[#st.log + 1] = ('終了: %d vs %d'):format(v1, v2)
        pushStateBoth(st, st.p1, st.p2)
        BattlePvpNotifyGameComplete(st)
        return
    end

    st.turn_src = opponentSrc(st, src)
    pushStateBoth(st, st.p1, st.p2)
end)

RegisterNetEvent('jp-tcgbook:server:battlePvpLeave', function()
    local src = source
    if TcgBattleWireLogEnabled() then
        print(('[jp-tcgbook][wire] server recv battlePvpLeave src=%d'):format(src))
    end
    if not getUidOrReject(src) then
        return
    end
    BattlePvpLeave(src, 'peer_left')
end)

RegisterNetEvent('jp-tcgbook:server:battlePvpRequestState', function()
    local src = source
    if TcgBattleWireLogEnabled() then
        print(('[jp-tcgbook][wire] server recv battlePvpRequestState src=%d'):format(src))
    end
    if not getUidOrReject(src) then
        return
    end
    local key = srcToSession[src]
    if not key then
        return
    end
    local st = sessions[key]
    if not st then
        return
    end
    pushState(src, st)
end)
