--- BattleStats: 試合終了時の Elo / 戦績 / 日次カウンタ / 【M4】PvP EXP・連勝 更新責務
--- BattlePvp.Finish からのみ呼ぶ（OnPlayerLeave は経由しない → normal 終了のみが自然に対象）

BattleStats = {}

local DEFAULT_K = 32

local function calcEloDelta(rating_self, rating_opp, score_self, k)
    local expected = 1 / (1 + 10 ^ ((rating_opp - rating_self) / 400))
    return k * (score_self - expected)
end

local function clampRating(r)
    if r < 0 then
        return 0
    end
    if r > 9999 then
        return 9999
    end
    return r
end

--- @param ctx table
local function updateRating(ctx)
    local p1cid = ctx.p1.citizenid
    local p2cid = ctx.p2.citizenid

    local r1Res = Database.GetPlayer(p1cid)
    local r2Res = Database.GetPlayer(p2cid)
    if not (r1Res.success and r1Res.data and r2Res.success and r2Res.data) then
        if TcgBattleWireLogEnabled() then
            print(('[jp-tcgbook][wire][stats] elo skip: GetPlayer failed p1=%s p2=%s'):format(
                tostring(p1cid),
                tostring(p2cid)))
        end
        return
    end

    local initial = tonumber(Config.InitialRating) or 1500
    local r1 = tonumber(r1Res.data.rating) or initial
    local r2 = tonumber(r2Res.data.rating) or initial
    local K = tonumber(Config.EloKFactor) or DEFAULT_K

    local s1, s2
    if ctx.outcome_for_p1 == 'win' then
        s1, s2 = 1.0, 0.0
    elseif ctx.outcome_for_p1 == 'lose' then
        s1, s2 = 0.0, 1.0
    else
        s1, s2 = 0.5, 0.5
    end

    local r1_new = clampRating(math.floor(r1 + calcEloDelta(r1, r2, s1, K) + 0.5))
    local r2_new = clampRating(math.floor(r2 + calcEloDelta(r2, r1, s2, K) + 0.5))

    Database.UpdatePlayerRating(p1cid, r1_new)
    Database.UpdatePlayerRating(p2cid, r2_new)

    if TcgBattleWireLogEnabled() then
        print(('[jp-tcgbook][wire][stats] elo p1=%s %d->%d  p2=%s %d->%d  K=%d'):format(
            p1cid,
            r1,
            r1_new,
            p2cid,
            r2,
            r2_new,
            K))
    end
end

--- @param ctx table
local function updateWinLoss(ctx)
    local a = Database.IncrementMatchStats(ctx.p1.citizenid, ctx.outcome_for_p1)
    local b = Database.IncrementMatchStats(ctx.p2.citizenid, ctx.outcome_for_p2)
    if TcgBattleWireLogEnabled() then
        print(('[jp-tcgbook][wire][stats] winloss p1=%s/%s ok=%s  p2=%s/%s ok=%s'):format(
            ctx.p1.citizenid,
            ctx.outcome_for_p1,
            tostring(a.success),
            ctx.p2.citizenid,
            ctx.outcome_for_p2,
            tostring(b.success)))
        if not a.success then
            print(('[jp-tcgbook][wire][stats] winloss err p1: %s'):format(tostring(a.error)))
        end
        if not b.success then
            print(('[jp-tcgbook][wire][stats] winloss err p2: %s'):format(tostring(b.error)))
        end
    end
end

--- PHASE C: tcg_daily_counters（JST 暦日・レイジー UPSERT）
--- @param ctx table
local function updateDailyCounter(ctx)
    local epoch = ctx.finished_at
    if type(epoch) ~= 'number' then
        epoch = os.time()
    end
    local date_jst = Database.JstDateStringFromEpoch(epoch)
    local a = Database.IncrementDailyMatchCounters(ctx.p1.citizenid, date_jst, ctx.outcome_for_p1)
    local b = Database.IncrementDailyMatchCounters(ctx.p2.citizenid, date_jst, ctx.outcome_for_p2)
    if TcgBattleWireLogEnabled() then
        print(('[jp-tcgbook][wire][stats] daily date_jst=%s p1=%s/%s ok=%s p2=%s/%s ok=%s'):format(
            date_jst,
            ctx.p1.citizenid,
            ctx.outcome_for_p1,
            tostring(a.success),
            ctx.p2.citizenid,
            ctx.outcome_for_p2,
            tostring(b.success)))
        if not a.success then
            print(('[jp-tcgbook][wire][stats] daily err p1: %s'):format(tostring(a.error)))
        end
        if not b.success then
            print(('[jp-tcgbook][wire][stats] daily err p2: %s'):format(tostring(b.error)))
        end
    end
end

--- M4: 累積 EXP から表示レベル（閾値テーブル + 任意のテーブル外伸長）
--- @param totalExp number
--- @return integer
function BattleStats.ComputePvpLevelFromExp(totalExp)
    local exp = math.max(0, math.floor(tonumber(totalExp) or 0))
    local tbl = Config.PvpLevelExpThresholds
    if type(tbl) ~= 'table' or #tbl == 0 then
        return 1
    end
    local level = 1
    for i, t in ipairs(tbl) do
        local th = tonumber(t)
        if not th then
            break
        end
        if exp >= th then
            level = i + 1
        else
            break
        end
    end
    local lastTh = tonumber(tbl[#tbl]) or 0
    local extraPer = tonumber(Config.PvpExpPerLevelBeyondTable) or 0
    if extraPer > 0 and exp > lastTh and lastTh > 0 then
        level = (#tbl + 1) + math.floor((exp - lastTh) / extraPer)
    end
    local capLv = tonumber(Config.PvpLevelCap) or 999
    if level > capLv then
        level = capLv
    end
    if level < 1 then
        level = 1
    end
    return level
end

--- M4: リアル PvP のみ・勝敗に応じて EXP・連勝・レベル更新
--- @param ctx table
local function updatePvpProgress(ctx)
    local function applyFor(cid, outcome)
        if type(cid) ~= 'string' or cid == '' then
            return
        end
        local gr = Database.GetPlayer(cid)
        if not gr.success or not gr.data then
            if TcgBattleWireLogEnabled() then
                print(('[jp-tcgbook][wire][stats] pvp_progress skip GetPlayer failed cid=%s'):format(cid))
            end
            return
        end
        local row = gr.data
        local streak = tonumber(row.pvp_win_streak) or 0
        local exp = tonumber(row.pvp_exp) or 0

        if outcome == 'win' then
            local base = tonumber(Config.PvpExpWinBase) or 25
            local cap = tonumber(Config.PvpWinStreakBonusCap) or 10
            local step = tonumber(Config.PvpExpPerStreakStep) or 2
            local bonus = math.min(streak, math.max(0, cap)) * math.max(0, step)
            exp = exp + base + bonus
            streak = streak + 1
        elseif outcome == 'lose' or outcome == 'draw' then
            streak = 0
        else
            return
        end

        local level = BattleStats.ComputePvpLevelFromExp(exp)
        local up = Database.UpdatePlayerPvpProgress(cid, exp, level, streak)
        if TcgBattleWireLogEnabled() then
            print(('[jp-tcgbook][wire][stats] pvp_progress cid=%s outcome=%s exp=%d lvl=%d streak=%d ok=%s'):format(
                cid,
                outcome,
                exp,
                level,
                streak,
                tostring(up.success)))
            if not up.success then
                print(('[jp-tcgbook][wire][stats] pvp_progress err: %s'):format(tostring(up.error)))
            end
        end
    end

    applyFor(ctx.p1.citizenid, ctx.outcome_for_p1)
    applyFor(ctx.p2.citizenid, ctx.outcome_for_p2)
end

--- @param ctx table collectFinishContext の戻り値
function BattleStats.RecordFinish(ctx)
    if not ctx then
        return
    end
    if not ctx.is_real_pvp then
        if TcgBattleWireLogEnabled() then
            print(('[jp-tcgbook][wire][stats] skip non-real-pvp session=%s'):format(tostring(ctx.session_id)))
        end
        return
    end

    local c1 = ctx.p1 and ctx.p1.citizenid
    local c2 = ctx.p2 and ctx.p2.citizenid
    if type(c1) ~= 'string' or c1 == '' or type(c2) ~= 'string' or c2 == '' then
        if TcgBattleWireLogEnabled() then
            print('[jp-tcgbook][wire][stats] skip missing citizenid for real PvP stats')
        end
        return
    end

    updateRating(ctx)
    updateWinLoss(ctx)
    updateDailyCounter(ctx)
    updatePvpProgress(ctx)
end
