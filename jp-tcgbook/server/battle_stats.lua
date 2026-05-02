--- BattleStats: 試合終了時の Elo / 戦績 / 日次カウンタ更新責務
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
end
