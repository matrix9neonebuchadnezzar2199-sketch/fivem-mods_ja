--- BattleRewards: 試合終了時の報酬付与責務（PHASE 2d）
--- BattlePvp.Finish からのみ呼ぶ

BattleRewards = {}

--- TODO[PHASE-2d]:
---   - 敗者の citizenid に対し、勝者デッキから 1 枚をコピーして付与
---   - URC ランクの扱い（一律ノーマル化 or 確率変動）は方針要決定
---   - リアル PvP の normal 終了のみ（is_real_pvp）
--- @param ctx table collectFinishContext の戻り値
function BattleRewards.GrantOnFinish(ctx)
    if not ctx or not ctx.is_real_pvp then
        return
    end
end
