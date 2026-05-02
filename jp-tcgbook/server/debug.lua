--- 開発者向けデバッグコマンド
--- 二重ゲート: Config.DebugCommands == true かつ（コンソール source=0 または ACE command.tcg_debug）
--- Config が false のときはコマンド本文に入らず拒否（運営でデバッグを完全オフにできる）

--- @param source number
--- @return boolean
local function isDebugAllowed(source)
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
local function dbgPrint(msg)
    print('[tcg-debug] ' .. msg)
end

--- @param source number
--- @param msg string
local function dbgReply(source, msg)
    dbgPrint(msg)
    if type(source) == 'number' and source > 0 then
        TriggerClientEvent('chat:addMessage', source, {
            args = { '[tcg-debug]', msg },
        })
    end
end

--- @param source number
--- @param msg string
local function dbgDeny(source, msg)
    if Config.DebugCommands ~= true then
        msg = 'デバッグコマンドは無効です（Config.DebugCommands）'
    end
    dbgPrint('DENY: ' .. msg)
    if type(source) == 'number' and source > 0 then
        TriggerClientEvent('chat:addMessage', source, {
            args = { '[tcg-debug]', msg },
        })
    end
end

--- @param cmdSource number コマンド実行者
--- @param optArg string|nil 省略時は実行者を対象（コンソールは必須指定）
--- @return integer|nil targetSrc
--- @return string|nil errMsg
local function resolveTargetPlayerSource(cmdSource, optArg)
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

--- @param src integer
--- @return string|nil uid
--- @return string|nil err
local function uidFromPlayerSource(src)
    local uid = GetPlayerUid(src)
    if not uid or uid == '' then
        return nil, 'UID を取得できませんでした'
    end
    return uid
end

--- @param card_id string
--- @return boolean
local function masterHasCard(card_id)
    for _, c in ipairs(TcgCardsMaster) do
        if c.card_id == card_id then
            return true
        end
    end
    return false
end

--- @param citizenid string
--- @param card_id string
--- @return integer
local function countOwnedCard(citizenid, card_id)
    local r = Database.GetPlayerCards(citizenid)
    if not r.success then
        return 0
    end
    local n = 0
    for _, row in ipairs(r.data or {}) do
        if row.card_id == card_id then
            n = n + 1
        end
    end
    return n
end

--- @param rank string
--- @return table|nil masterRow
local function pickRandomFreeMasterByRank(rank)
    local pool = {}
    for _, c in ipairs(TcgCardsMaster) do
        if c.rank == rank and c.type == 'free' then
            pool[#pool + 1] = c
        end
    end
    if #pool == 0 then
        return nil
    end
    return pool[math.random(#pool)]
end

RegisterCommand('tcg_give', function(source, args)
    if not isDebugAllowed(source) then
        dbgDeny(source, '権限がありません (ACE: command.tcg_debug)')
        return
    end

    local cardRaw = args[1]
    if cardRaw == nil or cardRaw == '' then
        dbgReply(source, '用法: /tcg_give <card_id> [target_server_id]')
        return
    end

    local card_id = cardRaw:match('^%s*(.-)%s*$')
    if not masterHasCard(card_id) then
        dbgReply(source, 'マスタに存在しない card_id です: ' .. tostring(card_id))
        return
    end

    local tgtSrc, err = resolveTargetPlayerSource(source, args[2])
    if not tgtSrc then
        dbgReply(source, err or '対象を解決できません')
        return
    end

    local uid, uerr = uidFromPlayerSource(tgtSrc)
    if not uid then
        dbgReply(source, uerr or 'UID 取得失敗')
        return
    end

    local ins = Database.AddCardToPlayer(uid, card_id)
    if not ins.success then
        dbgReply(source, '付与失敗: ' .. tostring(ins.error))
        return
    end

    dbgReply(source, ('uid=%s に card_id=%s を付与'):format(uid, card_id))
end, false)

RegisterCommand('tcg_giveall', function(source, args)
    if not isDebugAllowed(source) then
        dbgDeny(source, '権限がありません (ACE: command.tcg_debug)')
        return
    end

    local tgtSrc, err = resolveTargetPlayerSource(source, args[1])
    if not tgtSrc then
        dbgReply(source, err or '対象を解決できません')
        return
    end

    local uid, uerr = uidFromPlayerSource(tgtSrc)
    if not uid then
        dbgReply(source, uerr or 'UID 取得失敗')
        return
    end

    local okCount = 0
    local failCount = 0
    for _, c in ipairs(TcgCardsMaster) do
        local ins = Database.AddCardToPlayer(uid, c.card_id)
        if ins.success then
            okCount = okCount + 1
        else
            failCount = failCount + 1
        end
    end

    dbgReply(source, ('giveall 完了 uid=%s 成功=%d 失敗=%d'):format(uid, okCount, failCount))
end, false)

RegisterCommand('tcg_givepack', function(source, args)
    if not isDebugAllowed(source) then
        dbgDeny(source, '権限がありません (ACE: command.tcg_debug)')
        return
    end

    local count = tonumber(args[1])
    if not count or count < 1 or math.floor(count) ~= count then
        dbgReply(source, '用法: /tcg_givepack <count> [target_server_id]')
        return
    end

    local tgtSrc, err = resolveTargetPlayerSource(source, args[2])
    if not tgtSrc then
        dbgReply(source, err or '対象を解決できません')
        return
    end

    local uid, uerr = uidFromPlayerSource(tgtSrc)
    if not uid then
        dbgReply(source, uerr or 'UID 取得失敗')
        return
    end

    local ranks = Config.InitialCardRanks
    if type(ranks) ~= 'table' or #ranks == 0 then
        dbgReply(source, 'Config.InitialCardRanks が空です')
        return
    end

    local limitFree = (Config.CardLimit and Config.CardLimit.free) or 2
    local added = 0
    local attempts = 0
    local maxAttempts = 50

    while added < count and attempts < maxAttempts do
        attempts = attempts + 1
        local rk = ranks[math.random(#ranks)]
        local card = pickRandomFreeMasterByRank(rk)
        if card then
            local owned = countOwnedCard(uid, card.card_id)
            if owned < limitFree then
                local ins = Database.AddCardToPlayer(uid, card.card_id)
                if ins.success then
                    added = added + 1
                end
            end
        end
    end

    if added < count then
        dbgReply(
            source,
            ('givepack 部分的 uid=%s 付与=%d/%d (試行=%d・同名上限またはマスタ不足で打ち切り)'):format(
                uid,
                added,
                count,
                attempts
            )
        )
    else
        dbgReply(source, ('givepack 完了 uid=%s 付与=%d'):format(uid, added))
    end
end, false)

RegisterCommand('tcg_reset', function(source, args)
    if not isDebugAllowed(source) then
        dbgDeny(source, '権限がありません (ACE: command.tcg_debug)')
        return
    end

    local tgtSrc, err = resolveTargetPlayerSource(source, args[1])
    if not tgtSrc then
        dbgReply(source, err or '対象を解決できません')
        return
    end

    local uid, uerr = uidFromPlayerSource(tgtSrc)
    if not uid then
        dbgReply(source, uerr or 'UID 取得失敗')
        return
    end

    dbgPrint(('AUDIT tcg_reset executor_src=%s target_src=%s uid=%s'):format(
        tostring(source),
        tostring(tgtSrc),
        uid
    ))
    print('[tcg-debug] WARN: 対象が BOOK を開いている場合の競合は未深追跡（強制クローズを試行）')

    local r = Database.ResetPlayer(uid)
    if not r.success then
        dbgReply(source, 'リセット失敗: ' .. tostring(r.error))
        return
    end

    TriggerClientEvent('jp-tcgbook:client:debugForceCloseBook', tgtSrc)
    TriggerClientEvent('chat:addMessage', tgtSrc, {
        args = { '[tcg-debug]', 'BOOK データがリセットされました（BOOK は閉じられました）' },
    })

    dbgReply(source, ('uid=%s をリセット'):format(uid))
end, false)

RegisterCommand('tcg_clearcards', function(source, args)
    if not isDebugAllowed(source) then
        dbgDeny(source, '権限がありません (ACE: command.tcg_debug)')
        return
    end

    local tgtSrc, err = resolveTargetPlayerSource(source, args[1])
    if not tgtSrc then
        dbgReply(source, err or '対象を解決できません')
        return
    end

    local uid, uerr = uidFromPlayerSource(tgtSrc)
    if not uid then
        dbgReply(source, uerr or 'UID 取得失敗')
        return
    end

    dbgPrint(('AUDIT tcg_clearcards executor_src=%s target_uid=%s'):format(tostring(source), uid))

    local r = Database.ClearPlayerCardsAndDeckSlots(uid)
    if not r.success then
        dbgReply(source, 'クリア失敗: ' .. tostring(r.error))
        return
    end

    dbgReply(source, ('uid=%s の所持カードとデッキ内カードを削除（デッキ枠は残存）'):format(uid))
end, false)

RegisterCommand('tcg_dumpdeck', function(source, args)
    if not isDebugAllowed(source) then
        dbgDeny(source, '権限がありません (ACE: command.tcg_debug)')
        return
    end

    local tgtSrc, err = resolveTargetPlayerSource(source, args[1])
    if not tgtSrc then
        dbgReply(source, err or '対象を解決できません')
        return
    end

    local uid, uerr = uidFromPlayerSource(tgtSrc)
    if not uid then
        dbgReply(source, uerr or 'UID 取得失敗')
        return
    end

    local decksR = Deck.GetAllDecks(uid)
    if not decksR.success then
        dbgReply(source, 'デッキ一覧取得失敗: ' .. tostring(decksR.error))
        return
    end

    local activeId = nil
    for _, d in ipairs(decksR.data or {}) do
        if d.is_active == true or d.is_active == 1 then
            activeId = d.id
            break
        end
    end

    if not activeId then
        dbgReply(source, '警告: アクティブデッキがありません（uid=' .. uid .. '）')
        dbgPrint('[tcg-debug] decks=' .. json.encode(decksR.data or {}))
        return
    end

    local deckR = Deck.GetDeck(uid, activeId)
    if not deckR.success then
        dbgReply(source, 'デッキ取得失敗: ' .. tostring(deckR.error))
        return
    end

    local okEnc, encoded = pcall(json.encode, deckR.data)
    if okEnc then
        dbgPrint('[tcg-debug] active_deck json=' .. encoded)
        dbgReply(source, ('アクティブデッキ id=%s をコンソールに出力しました'):format(tostring(activeId)))
    else
        dbgReply(source, 'JSON 変換失敗')
    end
end, false)

RegisterCommand('tcg_setrating', function(source, args)
    if not isDebugAllowed(source) then
        dbgDeny(source, '権限がありません (ACE: command.tcg_debug)')
        return
    end

    local rating = tonumber(args[1])
    if rating == nil or rating ~= math.floor(rating) or rating < 0 or rating > 9999 then
        dbgReply(source, 'rating は 0〜9999 の整数で指定: /tcg_setrating <rating> [target_server_id]')
        return
    end

    local tgtSrc, err = resolveTargetPlayerSource(source, args[2])
    if not tgtSrc then
        dbgReply(source, err or '対象を解決できません')
        return
    end

    local uid, uerr = uidFromPlayerSource(tgtSrc)
    if not uid then
        dbgReply(source, uerr or 'UID 取得失敗')
        return
    end

    local pl = Database.GetPlayer(uid)
    if not pl.success or not pl.data then
        dbgReply(source, 'tcg_players に行がありません（先に /book 等で初期化）')
        return
    end

    local up = Database.UpdatePlayerRating(uid, rating)
    if not up.success then
        dbgReply(source, '更新失敗: ' .. tostring(up.error))
        return
    end

    dbgReply(source, ('uid=%s の rating を %d に更新'):format(uid, rating))
end, false)

RegisterCommand('tcg_listplayers', function(source)
    if not isDebugAllowed(source) then
        dbgDeny(source, '権限がありません (ACE: command.tcg_debug)')
        return
    end

    local r = Database.ListAllPlayers()
    if not r.success then
        dbgReply(source, '取得失敗: ' .. tostring(r.error))
        return
    end

    dbgPrint('--- tcg_players (' .. tostring(#(r.data or {})) .. ' rows) ---')
    for _, row in ipairs(r.data or {}) do
        local ini = row.initialized
        if ini == true or ini == 1 then
            ini = 'true'
        else
            ini = 'false'
        end
        dbgPrint(
            ('citizenid=%s rating=%s wins=%s losses=%s initialized=%s'):format(
                tostring(row.citizenid),
                tostring(row.rating),
                tostring(row.wins),
                tostring(row.losses),
                ini
            )
        )
    end
    dbgReply(source, 'tcg_players をサーバーコンソールに出力しました')
end, false)

RegisterCommand('tcg_battleid', function(source)
    if not isDebugAllowed(source) then
        dbgDeny(source, '権限がありません (ACE: command.tcg_debug)')
        return
    end
    dbgReply(
        source,
        ('仮想対戦の呼び出し番号（サーバーID）: %d（待受側が相手に伝える番号）'):format(source)
    )
end, false)

--- PHASE 2b: 不正着手を意図的に発火（`BattlePvp.HandlePlace` 直叩き・F8 fetch 不要）
RegisterCommand('tcg_pvp_test_invalid', function(source, args)
    if not isDebugAllowed(source) then
        dbgDeny(source, '権限がありません (ACE: command.tcg_debug)')
        return
    end

    local reason_code = args[1]
    if not reason_code or reason_code == '' then
        dbgPrint('usage: /tcg_pvp_test_invalid <reason_code> [target_server_id]')
        dbgPrint('  reason_code: turn_no | not_turn | cell_occ | cell_inv | hand_inv | session')
        return
    end

    local target, terr = resolveTargetPlayerSource(source, args[2])
    if not target then
        dbgDeny(source, terr or '対象を特定できません')
        return
    end

    local session = BattlePvp and BattlePvp.GetSessionBySrc and BattlePvp.GetSessionBySrc(target) or nil
    if reason_code ~= 'session' and not session then
        dbgPrint(('[tcg-debug] target src=%d は対戦セッション中ではありません'):format(target))
        return
    end

    local payload
    if reason_code == 'turn_no' then
        payload = {
            session_id = session.session_id,
            turn_no = (session.turn_no or 1) - 5,
            cell_index = 1,
            hand_index = 0,
        }
    elseif reason_code == 'not_turn' then
        if session.turn == target then
            dbgPrint('[tcg-debug] 現在 target のターンです。仮想ターン中に再実行してください。')
            return
        end
        payload = {
            session_id = session.session_id,
            turn_no = session.turn_no,
            cell_index = 1,
            hand_index = 0,
        }
    elseif reason_code == 'cell_occ' then
        local occupied = nil
        for i = 1, 9 do
            if session.board[i] ~= nil then
                occupied = i
                break
            end
        end
        if not occupied then
            dbgPrint('[tcg-debug] 盤面が空のため cell_occ は再現不可。1 手以上進めてから再実行してください。')
            return
        end
        payload = {
            session_id = session.session_id,
            turn_no = session.turn_no,
            cell_index = occupied,
            hand_index = 0,
        }
    elseif reason_code == 'cell_inv' then
        payload = {
            session_id = session.session_id,
            turn_no = session.turn_no,
            cell_index = 0,
            hand_index = 0,
        }
    elseif reason_code == 'hand_inv' then
        local emptyCell = nil
        for i = 1, 9 do
            if session.board[i] == nil then
                emptyCell = i
                break
            end
        end
        if not emptyCell then
            dbgPrint('[tcg-debug] 空マスがないため hand_inv は別状態で試してください。')
            return
        end
        payload = {
            session_id = session.session_id,
            turn_no = session.turn_no,
            cell_index = emptyCell,
            hand_index = 99,
        }
    elseif reason_code == 'session' then
        payload = {
            session_id = 'pvp_solo_invalid_test',
            turn_no = 1,
            cell_index = 1,
            hand_index = 0,
        }
    else
        dbgPrint(('[tcg-debug] 未知の reason_code: %s'):format(tostring(reason_code)))
        return
    end

    local enc = ''
    local okEnc, out = pcall(json.encode, payload)
    if okEnc and type(out) == 'string' then
        enc = out
    else
        enc = tostring(payload)
    end
    dbgPrint(('[tcg-debug][pvp-invalid] target=%d code=%s payload=%s'):format(target, reason_code, enc))

    if BattlePvp and BattlePvp.HandlePlace then
        BattlePvp.HandlePlace(target, payload)
    else
        dbgPrint('[tcg-debug] BattlePvp.HandlePlace が見つかりません')
    end
end, false)
