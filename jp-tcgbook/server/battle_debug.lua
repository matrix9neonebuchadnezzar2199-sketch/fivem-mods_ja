--- デバッグ用 CPU 対戦（Config.DebugCommands のみ）
--- 隣接辺比較・配置直後のみ奪取・連鎖なし（設計書 PHASE A 準拠）
--- 本番 PvP とは別セッション（battle_lobby の peer とは両立しない）

--- @type table<number, table>  src -> game state
local games = {}

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
        --- NUI はコレクションと同じパスで絵を表示（JSON 配列化でマスずれしないよう board は文字列キー）
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
--- @param idx integer 1..9
--- @param owner string human|cpu
--- @param card table
local function applyCaptures(st, idx, owner, card)
    local r, c = idxToRc(idx)
    local opp = owner == 'human' and 'cpu' or 'human'
    --- 上・下・左・右: 置いたカードの辺 vs 隣の相手カードの反対側の辺
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
                    cell.owner = owner
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
--- @return integer, integer
local function scoreGame(st)
    local humBoard, cpuBoard = 0, 0
    for i = 1, 9 do
        local cell = st.board[i]
        if cell then
            if cell.owner == 'human' then
                humBoard = humBoard + 1
            else
                cpuBoard = cpuBoard + 1
            end
        end
    end
    local humHand = #(st.human_hand or {})
    local cpuHand = #(st.cpu_hand or {})
    return humBoard + humHand, cpuBoard + cpuHand
end

--- @param st table
local function finalizeIfEnded(st)
    if not boardFull(st) then
        return false
    end
    st.phase = 'ended'
    local hs, cs = scoreGame(st)
    st.scores = { human = hs, cpu = cs }
    if hs > cs then
        st.winner = 'human'
    elseif cs > hs then
        st.winner = 'cpu'
    else
        st.winner = 'draw'
    end
    return true
end

--- CPU: 空マスと手札からランダムに1手
--- @param st table
--- @return boolean 着手したか
local function cpuRandomPlace(st)
    local empties = {}
    for i = 1, 9 do
        if st.board[i] == nil then
            empties[#empties + 1] = i
        end
    end
    if #empties == 0 or #(st.cpu_hand or {}) == 0 then
        return false
    end
    local idx = empties[math.random(#empties)]
    local hi = math.random(#st.cpu_hand)
    local card = table.remove(st.cpu_hand, hi)
    st.board[idx] = { owner = 'cpu', card = card }
    applyCaptures(st, idx, 'cpu', card)
    st.turn = 'human'
    finalizeIfEnded(st)
    return true
end

--- @param st table
--- @return table
local function buildClientPayload(st)
    --- 数キーだけだと JSON が配列になり、NUI 側の board[1]〜[9] と 0 始まりがずれるため文字列キーに固定
    local board = {}
    for i = 1, 9 do
        local cell = st.board[i]
        if cell then
            board[tostring(i)] = { owner = cell.owner, card = cell.card }
        end
    end
    return {
        phase = st.phase,
        turn = st.turn,
        board = board,
        human_hand = st.human_hand,
        cpu_hand_count = #(st.cpu_hand or {}),
        scores = st.scores,
        winner = st.winner,
        first_player = st.first_player,
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
--- @param msg string
local function pushState(src, st)
    if TcgBattleWireLogEnabled() then
        print(('[jp-tcgbook][wire] server->client battleDebugState src=%d phase=%s turn=%s'):format(
            src, tostring(st.phase), tostring(st.turn)))
    end
    TriggerClientEvent('jp-tcgbook:client:battleDebugState', src, buildClientPayload(st))
end

--- @param src number
--- @return boolean
function BattleDebugInGame(src)
    return games[src] ~= nil
end

--- BOOK 閉じる・切断時
--- @param src number
function BattleDebugLeave(src)
    games[src] = nil
end

--- openBook 用に現在状態を返す（再接続表示）
--- @param src number
--- @return table|nil
function BattleDebugGetClientState(src)
    local st = games[src]
    if not st then
        return nil
    end
    return buildClientPayload(st)
end

--- @param src number
--- @param citizenid string
--- @param activeDeck table|nil
--- @return boolean, string|nil
local function startGame(src, citizenid, activeDeck)
    BattleDebugLeave(src)
    if not activeDeck or not activeDeck.slots then
        return false, '使用デッキがありません'
    end
    local deckCards = {}
    for _, sl in ipairs(activeDeck.slots) do
        if sl and sl.card and sl.card.card_id then
            local m = masterRow(sl.card.card_id)
            if m then
                deckCards[#deckCards + 1] = cardFromMaster(m)
            end
        end
    end
    if #deckCards < Config.DeckSize then
        return false, ('デッキが %d 枚未満です（要 %d 枚）'):format(#deckCards, Config.DeckSize)
    end
    shuffleInPlace(deckCards)
    local human_hand = {}
    for i = 1, math.min(Config.HandSize or 5, #deckCards) do
        human_hand[i] = deckCards[i]
    end

    local cpuPool = {}
    for _, m in ipairs(TcgCardsMaster or {}) do
        cpuPool[#cpuPool + 1] = cardFromMaster(m)
    end
    if #cpuPool < (Config.HandSize or 5) then
        return false, 'マスタ枚数が不足しています'
    end
    shuffleInPlace(cpuPool)
    local cpu_hand = {}
    for i = 1, (Config.HandSize or 5) do
        cpu_hand[i] = cpuPool[i]
    end

    math.randomseed(GetGameTimer() + src * 997)
    local first = math.random(2) == 1 and 'human' or 'cpu'

    local st = {
        board = {},
        human_hand = human_hand,
        cpu_hand = cpu_hand,
        turn = first,
        phase = 'playing',
        first_player = first,
        scores = nil,
        winner = nil,
        log = { ('先攻: %s'):format(first == 'human' and 'あなた' or 'CPU') },
    }

    games[src] = st

    if first == 'cpu' then
        cpuRandomPlace(st)
        if st.log then
            st.log[#st.log + 1] = 'CPU がランダムに配置しました'
        end
    end

    pushState(src, st)
    return true, nil
end

RegisterNetEvent('jp-tcgbook:server:battleDebugLookupId', function(data)
    local src = source
    if TcgBattleWireLogEnabled() then
        print(('[jp-tcgbook][wire] server recv battleDebugLookupId src=%d'):format(src))
    end
    if Config.DebugCommands ~= true then
        if TcgBattleWireLogEnabled() then
            print(('[jp-tcgbook][wire] server->client battleDebugLookupAck src=%d ok=false'):format(src))
        end
        TriggerClientEvent('jp-tcgbook:client:battleDebugLookupAck', src, {
            ok = false,
            error = 'デバッグ対戦は無効です（Config.DebugCommands）',
        })
        return
    end
    if not getUidOrReject(src) then
        return
    end
    data = data or {}
    local tid = tonumber(data.target_server_id)
    if not tid or tid < 1 or math.floor(tid) ~= tid then
        if TcgBattleWireLogEnabled() then
            print(('[jp-tcgbook][wire] server->client battleDebugLookupAck src=%d ok=false invalid_id'):format(src))
        end
        TriggerClientEvent('jp-tcgbook:client:battleDebugLookupAck', src, {
            ok = false,
            error = '検索するサーバーID（正の整数）を入力してください',
        })
        return
    end
    --- デバッグ: オンライン確認せず「見つかった」応答のみ返す
    if TcgBattleWireLogEnabled() then
        print(('[jp-tcgbook][wire] server->client battleDebugLookupAck src=%d ok=true tid=%d'):format(src, tid))
    end
    TriggerClientEvent('jp-tcgbook:client:battleDebugLookupAck', src, {
        ok = true,
        target_server_id = tid,
        display_name = ('検証用: サーバーID %d（応答のみ・実プレイヤーではありません）'):format(tid),
    })
end)

RegisterNetEvent('jp-tcgbook:server:battleDebugStartCpu', function()
    local src = source
    if TcgBattleWireLogEnabled() then
        print(('[jp-tcgbook][wire] server recv battleDebugStartCpu src=%d'):format(src))
    end
    if Config.DebugCommands ~= true then
        pushLobbyErr(src, {
            error = 'デバッグ対戦は無効です（Config.DebugCommands）',
        })
        return
    end
    local uid = getUidOrReject(src)
    if not uid then
        return
    end
    if BattleLobbyGetPeer(src) then
        pushLobbyErr(src, {
            error = '仮想対戦ロビー接続中です。先に切断してください',
        })
        return
    end
    if BattleLobbySoloWireTestActive and BattleLobbySoloWireTestActive(src) then
        pushLobbyErr(src, {
            error = 'ソロ検証接続中です。先に仮想対戦を切断してください',
        })
        return
    end
    if BattlePvpInGame and BattlePvpInGame(src) then
        pushLobbyErr(src, {
            error = '本番対戦中はデバッグ対戦を開始できません（先に対戦終了）',
        })
        return
    end
    if games[src] then
        pushLobbyErr(src, {
            error = '既にデバッグ対戦中です',
        })
        return
    end

    local decks = Deck.GetAllDecks(uid)
    if not decks.success then
        pushLobbyErr(src, { error = decks.error or 'デッキ取得失敗' })
        return
    end
    local activeId = nil
    for _, d in ipairs(decks.data or {}) do
        if d.is_active == true or d.is_active == 1 then
            activeId = d.id
            break
        end
    end
    if not activeId then
        pushLobbyErr(src, {
            error = '使用デッキが設定されていません',
        })
        return
    end
    local g = Deck.GetDeck(uid, activeId)
    if not g.success or not g.data then
        pushLobbyErr(src, {
            error = '使用デッキの取得に失敗しました',
        })
        return
    end

    local ok, err = startGame(src, uid, g.data)
    if not ok then
        pushLobbyErr(src, { error = err or '開始に失敗しました' })
        return
    end

    if TcgBattleWireLogEnabled() then
        print(('[jp-tcgbook][wire] server->client virtualBattleMatched src=%d is_cpu=true'):format(src))
    end
    TriggerClientEvent('jp-tcgbook:client:virtualBattleMatched', src, {
        peer_server_id = nil,
        is_cpu = true,
        is_caller = true,
    })
end)

RegisterNetEvent('jp-tcgbook:server:battleDebugPlace', function(data)
    local src = source
    if Config.DebugCommands ~= true then
        return
    end
    local uid = getUidOrReject(src)
    if not uid then
        return
    end
    data = data or {}
    if TcgBattleWireLogEnabled() then
        print(('[jp-tcgbook][wire] server recv battleDebugPlace src=%d cell=%s hand=%s'):format(
            src, tostring(data.cell_index), tostring(data.hand_index)))
    end
    local st = games[src]
    if not st or st.phase ~= 'playing' then
        pushLobbyErr(src, { error = '対局中ではありません' })
        return
    end
    if st.turn ~= 'human' then
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
    if handIdx < 0 or handIdx >= #st.human_hand then
        pushLobbyErr(src, { error = '手札インデックスが不正です（0 から）' })
        return
    end
    if st.board[cellIdx] ~= nil then
        pushLobbyErr(src, { error = 'そのマスは埋まっています' })
        return
    end

    local card = table.remove(st.human_hand, handIdx + 1)
    st.board[cellIdx] = { owner = 'human', card = card }
    applyCaptures(st, cellIdx, 'human', card)
    st.log[#st.log + 1] = ('あなた: マス %d に配置'):format(cellIdx)

    if finalizeIfEnded(st) then
        st.log[#st.log + 1] = ('終了: あなた %d vs CPU %d'):format(st.scores.human, st.scores.cpu)
        pushState(src, st)
        return
    end

    st.turn = 'cpu'
    cpuRandomPlace(st)
    if st.phase == 'playing' then
        st.log[#st.log + 1] = 'CPU がランダムに配置しました'
    else
        st.log[#st.log + 1] = ('終了: あなた %d vs CPU %d'):format(st.scores.human, st.scores.cpu)
    end
    pushState(src, st)
end)

RegisterNetEvent('jp-tcgbook:server:battleDebugLeave', function()
    local src = source
    if TcgBattleWireLogEnabled() then
        print(('[jp-tcgbook][wire] server recv battleDebugLeave src=%d'):format(src))
    end
    if not getUidOrReject(src) then
        return
    end
    BattleDebugLeave(src)
    if TcgBattleWireLogEnabled() then
        print(('[jp-tcgbook][wire] server->client battleDebugEnded src=%d'):format(src))
    end
    TriggerClientEvent('jp-tcgbook:client:battleDebugEnded', src, {})
end)
