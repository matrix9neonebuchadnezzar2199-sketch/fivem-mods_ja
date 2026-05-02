--- PHASE 2b 本番 2 人対戦（サーバー権威・PHASE A）

BattlePvp = BattlePvp or {}

--- @type table<string, table>
local PvpBattles = {}
--- @type table<number, string>
local srcToSessionId = {}

--- 疑似 PvP（ソロ実機検証）の仮想プレイヤー。実プレイヤーの src は正の整数。
local VIRTUAL_SRC = -1

--- @param src number
--- @return boolean
local function isVirtualSrc(src)
    return type(src) == 'number' and src < 0
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
--- @param reason string
local function pushPvpError(src, reason)
    if TcgBattleWireLogEnabled() then
        print(('[jp-tcgbook][wire] server->client battlePvpError src=%d reason=%s'):format(src, tostring(reason)))
    end
    TriggerClientEvent('jp-tcgbook:client:battlePvpError', src, { reason = reason })
end

--- @param card table
--- @return table
local function copyCardForClient(card)
    if not card then
        return {}
    end
    return {
        card_id = card.card_id,
        name = card.name,
        rank = card.rank,
        type = card.type,
        stat_top = tonumber(card.stat_top) or 0,
        stat_right = tonumber(card.stat_right) or 0,
        stat_bottom = tonumber(card.stat_bottom) or 0,
        stat_left = tonumber(card.stat_left) or 0,
    }
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
--- @return table|nil
--- @return string|nil
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
--- @return table[]|nil
--- @return string|nil
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

--- CPU 戦と同様、マスタからランダムに HandSize 枚（疑似 PvP の相手手札）
--- @return table[]|nil
--- @return string|nil
local function buildVirtualHandFromMaster()
    local cpuPool = {}
    for _, m in ipairs(TcgCardsMaster or {}) do
        cpuPool[#cpuPool + 1] = normalizeCardFromMaster(m)
    end
    local need = Config.HandSize or 5
    if #cpuPool < need then
        return nil, 'マスタ枚数が不足しています'
    end
    shuffleInPlace(cpuPool)
    local hand = {}
    for i = 1, need do
        hand[i] = cpuPool[i]
    end
    return hand, nil
end

--- 検証済みの着手のみ（サーバー権威）
--- @param session table
--- @param src number
--- @param cell_index integer
--- @param hand_index integer 0..4
--- @return table PlaceAndResolve の戻り
--- @return table 配置したカード
local function commitPlace(session, src, cell_index, hand_index)
    local myHand = session.hands[src]
    local card = table.remove(myHand, hand_index + 1)
    local result = TcgBattleRule.PlaceAndResolve(session.board, cell_index, card, src)
    session.turn_no = session.turn_no + 1
    session.turn = src == session.p1_src and session.p2_src or session.p1_src
    return result, card
end

--- @param session table
--- @param viewer_src number
--- @return table[]  インデックス 1..9（JSON 配列化しやすいよう連続テーブル）
local function buildBoardArrayForViewer(session, viewer_src)
    local arr = {}
    for i = 1, 9 do
        local cell = session.board[i]
        if not cell then
            arr[i] = nil
        else
            arr[i] = {
                card = copyCardForClient(cell.card),
                owner_server_id = cell.owner,
                is_mine = cell.owner == viewer_src,
            }
        end
    end
    return arr
end

--- @param session table
--- @param viewer_src number
--- @param extra table|nil
--- @return table
local function buildStatePayload(session, viewer_src, extra)
    local opp = viewer_src == session.p1_src and session.p2_src or session.p1_src
    local payload = {
        session_id = session.session_id,
        turn_no = session.turn_no,
        turn_server_id = session.turn,
        is_my_turn = session.turn == viewer_src,
        board = buildBoardArrayForViewer(session, viewer_src),
        my_hand = {},
        opponent_hand_count = #(session.hands[opp] or {}),
        opponent_server_id = opp,
    }
    for _, c in ipairs(session.hands[viewer_src] or {}) do
        payload.my_hand[#payload.my_hand + 1] = copyCardForClient(c)
    end
    if extra and extra.last_action then
        local la = extra.last_action
        payload.last_action = {
            src = la.src,
            cell_index = la.cell_index,
            card = copyCardForClient(la.card),
            flipped_cells = la.flipped_cells or {},
            is_mine = la.src == viewer_src,
        }
    end
    return payload
end

--- @param session table
--- @param viewer_src number
--- @param reason string
--- @return table
local function buildNormalEndedPayload(session, viewer_src, reason)
    local p1, p2 = session.p1_src, session.p2_src
    local s1 = TcgBattleRule.CalcFinalScore(session.board, p1, #(session.hands[p1] or {}))
    local s2 = TcgBattleRule.CalcFinalScore(session.board, p2, #(session.hands[p2] or {}))
    local my_s = viewer_src == p1 and s1 or s2
    local op_s = viewer_src == p1 and s2 or s1
    local outcome
    if my_s > op_s then
        outcome = 'win'
    elseif op_s > my_s then
        outcome = 'lose'
    else
        outcome = 'draw'
    end
    return {
        session_id = session.session_id,
        reason = reason,
        my_score = my_s,
        opponent_score = op_s,
        outcome = outcome,
        final_board = buildBoardArrayForViewer(session, viewer_src),
        my_hand_remaining = #(session.hands[viewer_src] or {}),
    }
end

--- @param session table
--- @param viewer_src number
--- @param resigned_src number 離脱したプレイヤー
--- @param reason string
--- @return table
local function buildAbortEndedPayload(session, viewer_src, resigned_src, reason)
    local p1, p2 = session.p1_src, session.p2_src
    local peer = resigned_src == p1 and p2 or p1
    local s1 = TcgBattleRule.CalcFinalScore(session.board, p1, #(session.hands[p1] or {}))
    local s2 = TcgBattleRule.CalcFinalScore(session.board, p2, #(session.hands[p2] or {}))
    local my_s = viewer_src == p1 and s1 or s2
    local op_s = viewer_src == p1 and s2 or s1
    local outcome
    if viewer_src == resigned_src then
        outcome = 'lose'
    elseif viewer_src == peer then
        outcome = 'win'
    else
        outcome = 'draw'
    end
    return {
        session_id = session.session_id,
        reason = reason,
        my_score = my_s,
        opponent_score = op_s,
        outcome = outcome,
        final_board = buildBoardArrayForViewer(session, viewer_src),
        my_hand_remaining = #(session.hands[viewer_src] or {}),
    }
end

--- @param session_id string
local function destroySession(session_id)
    local s = PvpBattles[session_id]
    if not s then
        return
    end
    PvpBattles[session_id] = nil
    if s.p1_src and not isVirtualSrc(s.p1_src) then
        srcToSessionId[s.p1_src] = nil
    end
    if s.p2_src and not isVirtualSrc(s.p2_src) then
        srcToSessionId[s.p2_src] = nil
    end
end

--- @param session_id string
--- @param extra table|nil
--- @param only_src number|nil
function BattlePvp.BroadcastState(session_id, extra, only_src)
    local session = PvpBattles[session_id]
    if not session then
        return
    end
    local targets = { session.p1_src, session.p2_src }
    if only_src then
        targets = { only_src }
    end
    for _, viewer in ipairs(targets) do
        if not isVirtualSrc(viewer) and GetPlayerName(viewer) ~= nil then
            local payload = buildStatePayload(session, viewer, extra)
            if TcgBattleWireLogEnabled() then
                print(('[jp-tcgbook][wire] server->client battlePvpState src=%d session=%s turn_no=%s'):format(
                    viewer, session_id, tostring(session.turn_no)))
            end
            TriggerClientEvent('jp-tcgbook:client:battlePvpState', viewer, payload)
        end
    end
end

--- @param session_id string
--- @param reason string
function BattlePvp.Finish(session_id, reason)
    local session = PvpBattles[session_id]
    if not session then
        return
    end
    local p1, p2 = session.p1_src, session.p2_src
    local pay1 = buildNormalEndedPayload(session, p1, reason)
    local pay2 = buildNormalEndedPayload(session, p2, reason)
    local was_solo = session.is_solo == true
    destroySession(session_id)
    if not was_solo and BattleLobbyClearPeerPairSilent then
        BattleLobbyClearPeerPairSilent(p1, p2)
    end
    if TcgBattleWireLogEnabled() then
        print(('[jp-tcgbook][wire] BattlePvp.Finish session=%s reason=%s'):format(session_id, reason))
    end
    if GetPlayerName(p1) ~= nil then
        TriggerClientEvent('jp-tcgbook:client:battlePvpEnded', p1, pay1)
    end
    if not isVirtualSrc(p2) and GetPlayerName(p2) ~= nil then
        TriggerClientEvent('jp-tcgbook:client:battlePvpEnded', p2, pay2)
    end
end

--- @param p1_src number
--- @param p2_src number
--- @return boolean
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

    local oldSid1 = srcToSessionId[p1_src]
    local oldSid2 = srcToSessionId[p2_src]
    if oldSid1 then
        destroySession(oldSid1)
    end
    if oldSid2 and oldSid2 ~= oldSid1 then
        destroySession(oldSid2)
    end

    math.randomseed(GetGameTimer() + p1_src * 31 + p2_src * 997)
    local first_src = math.random(2) == 1 and p1_src or p2_src
    local session_id = ('pvp_%d_%d_%d'):format(os.time(), p1_src, p2_src)

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

    local function startedPay(v)
        local opp = v == session.p1_src and session.p2_src or session.p1_src
        local pay = {
            session_id = session.session_id,
            my_hand = {},
            opponent_hand_count = #(session.hands[opp] or {}),
            opponent_server_id = opp,
            board = buildBoardArrayForViewer(session, v),
            turn_server_id = session.turn,
            turn_no = session.turn_no,
            is_my_turn = v == session.first_src,
        }
        for _, c in ipairs(session.hands[v] or {}) do
            pay.my_hand[#pay.my_hand + 1] = copyCardForClient(c)
        end
        return pay
    end

    if TcgBattleWireLogEnabled() then
        print(('[jp-tcgbook][wire] BattlePvp.Start session=%s first_src=%d'):format(session_id, first_src))
        print(('[jp-tcgbook][wire] server->client battlePvpStarted src=%d session=%s'):format(p1_src, session_id))
        print(('[jp-tcgbook][wire] server->client battlePvpStarted src=%d session=%s'):format(p2_src, session_id))
    end
    TriggerClientEvent('jp-tcgbook:client:battlePvpStarted', p1_src, startedPay(p1_src))
    TriggerClientEvent('jp-tcgbook:client:battlePvpStarted', p2_src, startedPay(p2_src))

    BattlePvp.BroadcastState(session_id, nil, nil)
    return true
end

--- 疑似 PvP：本番 `battle_pvp.lua` の状態機械のみを通す（仮想相手 src=-1・サーバー AI）
--- @param human_src number
--- @return boolean
function BattlePvp.StartSolo(human_src)
    if Config.DebugCommands ~= true then
        return false
    end
    local uid = GetPlayerUid(human_src)
    if not uid or uid == '' then
        pushLobbyErr(human_src, { error = '識別子を取得できません' })
        return false
    end
    if BattleDebugInGame and BattleDebugInGame(human_src) then
        pushLobbyErr(human_src, { error = 'デバッグCPU対戦中は使えません（先に終了）' })
        return false
    end
    if BattleLobbyGetPeer and BattleLobbyGetPeer(human_src) then
        pushLobbyErr(human_src, { error = '仮想対戦ロビー接続中です。先に切断してください' })
        return false
    end
    if BattleLobbySoloWireTestActive and BattleLobbySoloWireTestActive(human_src) then
        pushLobbyErr(human_src, { error = 'ソロ検証接続中です。先に仮想対戦を切断してください' })
        return false
    end

    local deck, err = loadActiveDeckFor(uid)
    if err then
        pushLobbyErr(human_src, { error = err })
        return false
    end
    local handHuman, herr = buildHandFiveFromDeck(deck)
    if herr then
        pushLobbyErr(human_src, { error = herr })
        return false
    end
    local handVirt, verr = buildVirtualHandFromMaster()
    if verr then
        pushLobbyErr(human_src, { error = verr })
        return false
    end

    local oldSid = srcToSessionId[human_src]
    if oldSid then
        local oldSess = PvpBattles[oldSid]
        if oldSess and oldSess.is_solo ~= true then
            pushLobbyErr(human_src, { error = '本番対戦中は疑似PvPを開始できません（先に終了）' })
            return false
        end
        destroySession(oldSid)
    end

    math.randomseed(GetGameTimer() + human_src * 997)
    local p1_src = human_src
    local p2_src = VIRTUAL_SRC
    local first_src = math.random(2) == 1 and p1_src or p2_src
    local session_id = ('pvp_solo_%d_%d'):format(os.time(), human_src)

    local session = {
        session_id = session_id,
        p1_src = p1_src,
        p2_src = p2_src,
        first_src = first_src,
        board = TcgBattleRule.CreateEmptyBoard(),
        hands = {
            [p1_src] = handHuman,
            [p2_src] = handVirt,
        },
        turn = first_src,
        turn_no = 1,
        started_at = os.time(),
        is_solo = true,
    }

    PvpBattles[session_id] = session
    srcToSessionId[human_src] = session_id

    local function startedPay(v)
        local opp = v == session.p1_src and session.p2_src or session.p1_src
        local pay = {
            session_id = session.session_id,
            my_hand = {},
            opponent_hand_count = #(session.hands[opp] or {}),
            opponent_server_id = opp,
            board = buildBoardArrayForViewer(session, v),
            turn_server_id = session.turn,
            turn_no = session.turn_no,
            is_my_turn = v == session.first_src,
        }
        for _, c in ipairs(session.hands[v] or {}) do
            pay.my_hand[#pay.my_hand + 1] = copyCardForClient(c)
        end
        return pay
    end

    if TcgBattleWireLogEnabled() then
        print(('[jp-tcgbook][wire] BattlePvp.StartSolo session=%s first_src=%d virtual=%d'):format(
            session_id, first_src, VIRTUAL_SRC))
        print(('[jp-tcgbook][wire] server->client battlePvpStarted src=%d session=%s'):format(human_src, session_id))
    end
    TriggerClientEvent('jp-tcgbook:client:battlePvpStarted', human_src, startedPay(human_src))

    BattlePvp.BroadcastState(session_id, nil, nil)

    if isVirtualSrc(session.turn) then
        Citizen.SetTimeout(500, function()
            BattlePvp.SoloAiTurn(session_id)
        end)
    end
    return true
end

--- @param session_id string
function BattlePvp.SoloAiTurn(session_id)
    local session = PvpBattles[session_id]
    if not session then
        return
    end
    if not isVirtualSrc(session.turn) then
        return
    end
    local v = VIRTUAL_SRC
    local empties = {}
    for i = 1, 9 do
        if session.board[i] == nil then
            empties[#empties + 1] = i
        end
    end
    local vhand = session.hands[v]
    if not vhand or #vhand == 0 or #empties == 0 then
        if TcgBattleWireLogEnabled() then
            print(('[jp-tcgbook][wire] solo_ai_turn abort session=%s (empty cell or hand)'):format(session_id))
        end
        return
    end
    local cell_index = empties[math.random(#empties)]
    local hand_index = 0
    if TcgBattleWireLogEnabled() then
        print(('[jp-tcgbook][wire] solo_ai_turn session=%s cell=%d hand_index=%d vhand=%d'):format(
            session_id, cell_index, hand_index, #vhand))
    end
    local result, card = commitPlace(session, v, cell_index, hand_index)

    if TcgBattleRule.IsBoardFull(session.board) then
        BattlePvp.Finish(session_id, 'normal')
        return
    end

    BattlePvp.BroadcastState(session_id, {
        last_action = {
            src = v,
            cell_index = cell_index,
            card = card,
            flipped_cells = result.flipped_cells or {},
        },
    })

    if isVirtualSrc(session.turn) then
        Citizen.SetTimeout(500, function()
            BattlePvp.SoloAiTurn(session_id)
        end)
    end
end

--- @param src number
--- @param ended_reason string|nil
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
    local session_id = session.session_id
    local reason = ended_reason or 'peer_left'

    local pay1 = buildAbortEndedPayload(session, p1, src, reason)
    local pay2 = buildAbortEndedPayload(session, p2, src, reason)

    local was_solo = session.is_solo == true
    destroySession(session_id)

    if not was_solo and BattleLobbyClearPeerPairSilent then
        BattleLobbyClearPeerPairSilent(p1, p2)
    end

    if TcgBattleWireLogEnabled() then
        print(('[jp-tcgbook][wire] BattlePvp.OnPlayerLeave session=%s reason=%s'):format(session_id, reason))
    end
    if GetPlayerName(p1) ~= nil then
        TriggerClientEvent('jp-tcgbook:client:battlePvpEnded', p1, pay1)
    end
    if not isVirtualSrc(p2) and GetPlayerName(p2) ~= nil then
        TriggerClientEvent('jp-tcgbook:client:battlePvpEnded', p2, pay2)
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

function BattlePvpInGame(src)
    return BattlePvp.GetSessionBySrc(src) ~= nil
end

function BattlePvpGetClientState(_src)
    return nil
end

--- NUI 経路・デバッグコマンド経路の共通：着手検証と反映
--- @param src number 着手主体の server id
--- @param payload table|nil
function BattlePvp.HandlePlace(src, payload)
    payload = payload or {}
    if TcgBattleWireLogEnabled() then
        print(('[jp-tcgbook][wire] server recv battlePvpPlace src=%d'):format(src))
    end
    if not getUidOrReject(src) then
        return
    end

    local session_id = payload.session_id
    if type(session_id) ~= 'string' or session_id == '' then
        pushPvpError(src, 'session_not_found')
        return
    end

    local session = PvpBattles[session_id]
    if not session then
        pushPvpError(src, 'session_not_found')
        return
    end

    if session.p1_src ~= src and session.p2_src ~= src then
        pushPvpError(src, 'not_in_session')
        return
    end

    if session.turn ~= src then
        pushPvpError(src, 'not_your_turn')
        return
    end

    local turn_no = tonumber(payload.turn_no)
    if not turn_no or turn_no ~= session.turn_no then
        pushPvpError(src, 'turn_no_mismatch')
        return
    end

    local cell_index = tonumber(payload.cell_index)
    if type(cell_index) ~= 'number' or cell_index < 1 or cell_index > 9 or math.floor(cell_index) ~= cell_index then
        pushPvpError(src, 'invalid_cell')
        return
    end

    if session.board[cell_index] ~= nil then
        pushPvpError(src, 'cell_occupied')
        return
    end

    local hand_index = tonumber(payload.hand_index)
    if type(hand_index) ~= 'number' or hand_index < 0 or hand_index > 4 or math.floor(hand_index) ~= hand_index then
        pushPvpError(src, 'invalid_hand_index')
        return
    end

    local myHand = session.hands[src]
    local cardSlot = myHand and myHand[hand_index + 1]
    if cardSlot == nil then
        pushPvpError(src, 'hand_card_missing')
        return
    end

    local result, card = commitPlace(session, src, cell_index, hand_index)

    if TcgBattleRule.IsBoardFull(session.board) then
        BattlePvp.Finish(session_id, 'normal')
        return
    end

    BattlePvp.BroadcastState(session_id, {
        last_action = {
            src = src,
            cell_index = cell_index,
            card = card,
            flipped_cells = result.flipped_cells or {},
        },
    })

    if isVirtualSrc(session.turn) then
        Citizen.SetTimeout(500, function()
            BattlePvp.SoloAiTurn(session_id)
        end)
    end
end

RegisterNetEvent('jp-tcgbook:server:battlePvpPlace', function(payload)
    BattlePvp.HandlePlace(source, payload)
end)

RegisterNetEvent('jp-tcgbook:server:battlePvpStartSolo', function()
    local src = source
    if TcgBattleWireLogEnabled() then
        print(('[jp-tcgbook][wire] server recv battlePvpStartSolo src=%d'):format(src))
    end
    if Config.DebugCommands ~= true then
        return
    end
    if not getUidOrReject(src) then
        return
    end
    BattlePvp.StartSolo(src)
end)

RegisterNetEvent('jp-tcgbook:server:battlePvpLeave', function()
    local src = source
    if TcgBattleWireLogEnabled() then
        print(('[jp-tcgbook][wire] server recv battlePvpLeave src=%d'):format(src))
    end
    if not getUidOrReject(src) then
        return
    end
    BattlePvp.OnPlayerLeave(src, 'voluntary_leave')
end)

RegisterNetEvent('jp-tcgbook:server:battlePvpRequestState', function(payload)
    local src = source
    payload = payload or {}
    if TcgBattleWireLogEnabled() then
        print(('[jp-tcgbook][wire] server recv battlePvpRequestState src=%d'):format(src))
    end
    if not getUidOrReject(src) then
        return
    end
    local session_id = payload.session_id
    if type(session_id) ~= 'string' or session_id == '' then
        pushPvpError(src, 'session_not_found')
        return
    end
    local session = PvpBattles[session_id]
    if not session then
        pushPvpError(src, 'session_not_found')
        return
    end
    if session.p1_src ~= src and session.p2_src ~= src then
        pushPvpError(src, 'not_in_session')
        return
    end
    BattlePvp.BroadcastState(session_id, nil, src)
end)

--- 不正着手デバッグ（コマンドは resource 起動時に必ず登録。権限はハンドラ内）
--- `[tcg-debug][pvp-invalid]` は Config.BattleWireLog（TcgBattleWireLogEnabled）連動
--- @param source number
--- @param optArg string|nil
--- @return integer|nil
--- @return string|nil
local function pvpTestInvalidResolveTarget(cmdSource, optArg)
    if optArg ~= nil and optArg ~= '' then
        local tid = tonumber(optArg)
        if not tid or tid < 1 or math.floor(tid) ~= tid then
            return nil, '不正なプレイヤーIDです（server ID の数値を指定）'
        end
        if GetPlayerName(tid) == nil then
            return nil, '対象プレイヤーがオンラインではありません'
        end
        return tid
    end
    if cmdSource == 0 then
        return nil, 'コンソール実行時はプレイヤーID（server ID）を指定してください'
    end
    if GetPlayerName(cmdSource) == nil then
        return nil, '実行者のプレイヤー情報が取得できません'
    end
    return cmdSource
end

--- @param source number
--- @return boolean
local function pvpTestInvalidAllowed(source)
    if Config.DebugCommands ~= true then
        return false
    end
    if source == 0 then
        return true
    end
    return IsPlayerAceAllowed(source, 'command.tcg_debug')
end

--- @param source number
--- @param msg string
local function pvpTestInvalidDeny(source, msg)
    if Config.DebugCommands ~= true then
        msg = 'デバッグコマンドは無効です（Config.DebugCommands）'
    end
    print('[tcg-debug] DENY: ' .. tostring(msg))
    if type(source) == 'number' and source > 0 then
        TriggerClientEvent('chat:addMessage', source, {
            args = { '[tcg-debug]', tostring(msg) },
        })
    end
end

--- 不正着手検証用 payload（tcg_pvp_test_invalid / NUI バッチ共通）
--- @param session table|nil 対象プレイヤーのセッション（reason が session 以外では必須）
--- @param target number 検証対象の server id（not_turn 判定に使用）
--- @param reason_code string
--- @return table|nil payload
--- @return string|nil skip_reason
local function pvpTestInvalidBuildPayload(session, target, reason_code)
    if reason_code == 'turn_no' then
        if not session then
            return nil, 'no_session'
        end
        return {
            session_id = session.session_id,
            turn_no = (session.turn_no or 1) - 5,
            cell_index = 1,
            hand_index = 0,
        }
    elseif reason_code == 'not_turn' then
        if not session then
            return nil, 'no_session'
        end
        if session.turn == target then
            return nil, 'not_opponent_turn_yet'
        end
        return {
            session_id = session.session_id,
            turn_no = session.turn_no,
            cell_index = 1,
            hand_index = 0,
        }
    elseif reason_code == 'cell_occ' then
        if not session then
            return nil, 'no_session'
        end
        local occupied = nil
        for i = 1, 9 do
            if session.board[i] ~= nil then
                occupied = i
                break
            end
        end
        if not occupied then
            return nil, 'cell_occ_needs_occupied'
        end
        return {
            session_id = session.session_id,
            turn_no = session.turn_no,
            cell_index = occupied,
            hand_index = 0,
        }
    elseif reason_code == 'cell_inv' then
        if not session then
            return nil, 'no_session'
        end
        return {
            session_id = session.session_id,
            turn_no = session.turn_no,
            cell_index = 0,
            hand_index = 0,
        }
    elseif reason_code == 'hand_inv' then
        if not session then
            return nil, 'no_session'
        end
        local emptyCell = nil
        for i = 1, 9 do
            if session.board[i] == nil then
                emptyCell = i
                break
            end
        end
        if not emptyCell then
            return nil, 'hand_inv_needs_empty_cell'
        end
        return {
            session_id = session.session_id,
            turn_no = session.turn_no,
            cell_index = emptyCell,
            hand_index = 99,
        }
    elseif reason_code == 'session' then
        return {
            session_id = 'pvp_solo_invalid_test',
            turn_no = 1,
            cell_index = 1,
            hand_index = 0,
        }
    end
    return nil, 'unknown_kind'
end

--- @param target number
--- @param reason_code string
--- @param payload table
local function pvpTestInvalidDispatchPlace(target, reason_code, payload)
    local enc = ''
    local okEnc, out = pcall(json.encode, payload)
    if okEnc and type(out) == 'string' then
        enc = out
    else
        enc = tostring(payload)
    end
    if TcgBattleWireLogEnabled() then
        print(('[jp-tcgbook][wire][pvp-invalid-harness] target=%d code=%s payload=%s'):format(
            target, reason_code, enc))
    end
    BattlePvp.HandlePlace(target, payload)
end

--- BOOK 表示中でも実行できる不正検証バッチ（ACE 不要・セッション内かつ DebugCommands のみ）
--- @param src number
--- @return boolean
local function pvpTestInvalidNuiBatchAllowed(src)
    if Config.DebugCommands ~= true then
        return false
    end
    if type(src) ~= 'number' or src < 1 then
        return false
    end
    if GetPlayerName(src) == nil then
        return false
    end
    return BattlePvp.GetSessionBySrc(src) ~= nil
end

RegisterNetEvent('jp-tcgbook:server:battlePvpTestInvalidBatch', function()
    local src = source
    if not pvpTestInvalidNuiBatchAllowed(src) then
        return
    end
    --- not_turn はソロ時に実機で踏みにくいためバッチ対象外（HandlePlace の分岐はコードレビューで確認）
    local order = { 'turn_no', 'cell_inv', 'hand_inv', 'cell_occ', 'session' }
    for _, kind in ipairs(order) do
        local session = BattlePvp.GetSessionBySrc(src)
        if kind ~= 'session' and not session then
            break
        end
        local payload, _skip = pvpTestInvalidBuildPayload(session, src, kind)
        if payload then
            pvpTestInvalidDispatchPlace(src, kind, payload)
        end
    end
end)

RegisterCommand('tcg_pvp_test_invalid', function(source, args, _rawCommand)
    local allowed = pvpTestInvalidAllowed(source)
    if not allowed then
        pvpTestInvalidDeny(source, '権限がありません (ACE: command.tcg_debug)')
        return
    end

    local reason_code = args[1]
    if not reason_code or reason_code == '' then
        print('[tcg-debug] usage: /tcg_pvp_test_invalid <reason_code> [target_server_id]')
        print('[tcg-debug]   reason_code: turn_no | not_turn | cell_occ | cell_inv | hand_inv | session')
        return
    end

    local target, terr = pvpTestInvalidResolveTarget(source, args[2])
    if not target then
        pvpTestInvalidDeny(source, terr or '対象を特定できません')
        return
    end

    local session = BattlePvp.GetSessionBySrc(target)
    if reason_code ~= 'session' and not session then
        print(('[tcg-debug] target src=%d は対戦セッション中ではありません'):format(target))
        return
    end

    local payload, skip = pvpTestInvalidBuildPayload(session, target, reason_code)
    if not payload then
        if skip == 'not_opponent_turn_yet' then
            print('[tcg-debug] 現在 target のターンです。仮想ターン中に再実行してください。')
        elseif skip == 'cell_occ_needs_occupied' then
            print('[tcg-debug] 盤面が空のため cell_occ は再現不可。1 手以上進めてから再実行してください。')
        elseif skip == 'hand_inv_needs_empty_cell' then
            print('[tcg-debug] 空マスがないため hand_inv は別状態で試してください。')
        elseif skip == 'unknown_kind' then
            print(('[tcg-debug] 未知の reason_code: %s'):format(tostring(reason_code)))
        elseif skip ~= 'no_session' then
            print(('[tcg-debug] tcg_pvp_test_invalid skip=%s'):format(tostring(skip)))
        end
        return
    end

    pvpTestInvalidDispatchPlace(target, reason_code, payload)
end, false)
