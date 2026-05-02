--- 1 人開発用: BattleStats.RecordFinish / BattleRewards.GrantOnFinish を疑似 ctx で実行
--- 仮想ロビーは「相手 server ID 必須」のため単独クライアントでは本番 Start を踏めない——DB・ログ検証は本コマンドで代替
--- Config.DebugCommands +（プレイヤー実行時は ACE command.tcg_debug）。コンソールは server ID 必須
--- ダミー peer は `Config.PvpSoloVerificationDummyCitizenid`（`Database.EnsureVerificationDummyPeer` と共用）

local function dryrunGate(source)
    if Config.DebugCommands ~= true then
        print('[tcg-debug] finish_hooks dryrun: Config.DebugCommands が OFF です')
        return false
    end
    if type(source) == 'number' and source > 0 then
        if not IsPlayerAceAllowed(source, 'command.tcg_debug') then
            print('[tcg-debug] finish_hooks dryrun: ACE command.tcg_debug が必要です')
            return false
        end
    end
    return true
end

local function cardFromMaster(m)
    if not m then
        return nil
    end
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

--- @return table[]|nil
--- @return string|nil err
local function buildWinnerPoolFive()
    local master = TcgCardsMaster or {}
    if #master == 0 then
        return nil, 'TcgCardsMaster が空です（マスタ投入後に再試行）'
    end
    local pool = {}
    local n = math.min(5, #master)
    for i = 1, n do
        pool[#pool + 1] = cardFromMaster(master[i])
    end
    while #pool < 5 do
        pool[#pool + 1] = cardFromMaster(master[1])
    end
    return pool, nil
end

--- @param pool table[]
--- @return table[]
local function copyPoolForCtx(pool)
    local out = {}
    for i = 1, #pool do
        local c = pool[i]
        local copy = {}
        if type(c) == 'table' then
            for k, v in pairs(c) do
                copy[k] = v
            end
        end
        out[#out + 1] = copy
    end
    return out
end

--- lose: 実プレイヤーが敗北 → 報酬は自分へ（BOOK で増えた枚数を確認しやすい）
--- win:  実プレイヤーが勝利 → 報酬はダミー行へ（DB で tcg_player_cards を確認）
RegisterCommand('tcg_debug_finish_hooks_dryrun', function(source, args, _raw)
    if not dryrunGate(source) then
        return
    end

    local dummyId = Config.PvpSoloVerificationDummyCitizenid or 'jp-tcgbook-debug-peer-dummy'

    local mode = 'lose'
    local tidIdx = 1
    local a1 = args and args[1]
    if a1 == 'win' or a1 == 'lose' then
        mode = a1
        tidIdx = 2
    elseif tonumber(a1) then
        mode = 'lose'
        tidIdx = 1
    end

    local target = tonumber(args and args[tidIdx])
    if not target or target < 1 or math.floor(target) ~= target then
        if source == 0 then
            print('[tcg-debug] usage: tcg_debug_finish_hooks_dryrun [lose|win] <target_server_id>')
            print('[tcg-debug]   lose(既定): あなた敗北・コピーは自分へ / win: あなた勝利・コピーはダミー DB 行へ')
            return
        end
        target = source
    end

    if GetPlayerName(target) == nil then
        print('[tcg-debug] finish_hooks dryrun: 対象プレイヤーがオンラインではありません')
        return
    end

    local uid = GetPlayerUid(target)
    if type(uid) ~= 'string' or uid == '' then
        print('[tcg-debug] finish_hooks dryrun: 対象の識別子を取得できません')
        return
    end

    local ens = Database.EnsureVerificationDummyPeer(dummyId)
    if not ens.success then
        print('[tcg-debug] finish_hooks dryrun: ダミー相手 tcg_players の作成に失敗: ' .. tostring(ens.error))
        return
    end

    local pool, perr = buildWinnerPoolFive()
    if not pool then
        print('[tcg-debug] finish_hooks dryrun: ' .. tostring(perr))
        return
    end

    local ctx
    if mode == 'win' then
        ctx = {
            session_id = ('pvp_debug_dryrun_%d'):format(os.time()),
            reason = 'normal',
            is_real_pvp = true,
            is_solo = false,
            p1 = { src = target, citizenid = uid, score = 10 },
            p2 = { src = 0, citizenid = dummyId, score = 5 },
            outcome_for_p1 = 'win',
            outcome_for_p2 = 'lose',
            finished_at = os.time(),
            winner_reward_pool = copyPoolForCtx(pool),
        }
    else
        ctx = {
            session_id = ('pvp_debug_dryrun_%d'):format(os.time()),
            reason = 'normal',
            is_real_pvp = true,
            is_solo = false,
            p1 = { src = target, citizenid = uid, score = 4 },
            p2 = { src = 0, citizenid = dummyId, score = 9 },
            outcome_for_p1 = 'lose',
            outcome_for_p2 = 'win',
            finished_at = os.time(),
            winner_reward_pool = copyPoolForCtx(pool),
        }
    end

    print(('[tcg-debug] finish_hooks dryrun START mode=%s target_src=%d dummy=%s'):format(
        mode,
        target,
        dummyId))

    if BattleStats and BattleStats.RecordFinish then
        BattleStats.RecordFinish(ctx)
    end
    if BattleRewards and BattleRewards.GrantOnFinish then
        BattleRewards.GrantOnFinish(ctx)
    end

    print('[tcg-debug] finish_hooks dryrun END（Wire ON なら [jp-tcgbook][wire][stats] / [rewards] を確認）')
end, false)
