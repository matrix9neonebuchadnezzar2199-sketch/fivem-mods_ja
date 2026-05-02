--- BattleRewards: 試合終了時の報酬付与（PHASE 2d）
--- BattlePvp.Finish からのみ呼ぶ。設計: docs/design/PHASE_2d_defeat_reward.md

BattleRewards = {}

--- @param ctx table collectFinishContext の戻り値
--- @return boolean granted 敗北コピーが DB 付与まで成功したか（対象外・draw・失敗は false）
--- @return string|nil card_id 付与したカード（未付与時は nil）
function BattleRewards.GrantOnFinish(ctx)
    if not ctx then
        return false, nil
    end
    if not ctx.is_real_pvp then
        return false, nil
    end
    if ctx.reason ~= 'normal' then
        return false, nil
    end

    if ctx.outcome_for_p1 == 'draw' then
        if TcgBattleWireLogEnabled() then
            print(('[jp-tcgbook][wire][rewards] skip draw session=%s'):format(tostring(ctx.session_id)))
        end
        return false, nil
    end

    local loser
    if ctx.outcome_for_p1 == 'win' then
        loser = ctx.p2
    else
        loser = ctx.p1
    end

    local loser_cid = loser and loser.citizenid
    if type(loser_cid) ~= 'string' or loser_cid == '' then
        if TcgBattleWireLogEnabled() then
            print(('[jp-tcgbook][wire][rewards] skip no loser citizenid session=%s'):format(
                tostring(ctx.session_id)))
        end
        return false, nil
    end

    local pool = ctx.winner_reward_pool
    if not pool or #pool == 0 then
        if TcgBattleWireLogEnabled() then
            print(('[jp-tcgbook][wire][rewards] skip empty winner_reward_pool session=%s'):format(
                tostring(ctx.session_id)))
        end
        return false, nil
    end

    local picked = pool[math.random(1, #pool)]
    local card_id = picked and picked.card_id
    if type(card_id) ~= 'string' or card_id == '' then
        if TcgBattleWireLogEnabled() then
            print(('[jp-tcgbook][wire][rewards] skip invalid card_id session=%s'):format(
                tostring(ctx.session_id)))
        end
        return false, nil
    end

    local res = Database.AddCardToPlayer(loser_cid, card_id)
    local ok = res and res.success == true
    if ok then
        local epoch = ctx.finished_at
        if type(epoch) ~= 'number' then
            epoch = os.time()
        end
        local date_jst = Database.JstDateStringFromEpoch(epoch)
        local dc = Database.IncrementDailyCopiesReceived(loser_cid, date_jst)
        if not dc.success and TcgBattleWireLogEnabled() then
            print(('[jp-tcgbook][wire][rewards] daily copies_received err: %s'):format(tostring(dc.error)))
        end
    end
    if TcgBattleWireLogEnabled() then
        print(('[jp-tcgbook][wire][rewards] grant loser=%s card_id=%s ok=%s session=%s'):format(
            loser_cid,
            card_id,
            tostring(ok),
            tostring(ctx.session_id)))
        if not ok and res and res.error then
            print(('[jp-tcgbook][wire][rewards] grant err: %s'):format(tostring(res.error)))
        end
    end
    if ok then
        return true, card_id
    end
    return false, nil
end
