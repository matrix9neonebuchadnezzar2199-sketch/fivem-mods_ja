--- PvP 段位（rating → tier）。DB には持たず表示時に Config から解決する（M6 PHASE E5）
--- `Config.PvpRankTiers` は **min_rating 降順**（先頭が最高段・閾値大きい順）

--- @param rating number|string|nil
--- @return table|nil tier { rank_code, badge, min_rating, rank_order? }
function ResolvePvpRankTier(rating)
    local r = tonumber(rating) or 0
    local tiers = Config.PvpRankTiers
    if type(tiers) ~= 'table' then
        return nil
    end
    for _, tier in ipairs(tiers) do
        if type(tier) == 'table' then
            local m = tonumber(tier.min_rating)
            if m ~= nil and r >= m then
                return tier
            end
        end
    end
    for i = #tiers, 1, -1 do
        local tier = tiers[i]
        if type(tier) == 'table' then
            return tier
        end
    end
    return nil
end

--- ランキング行に `rank_code`・`badge` を付与（参照テーブルをその場で変更）
--- @param row table|nil
function EnrichRankingRowWithTier(row)
    if type(row) ~= 'table' then
        return
    end
    local tier = ResolvePvpRankTier(row.rating)
    if tier and type(tier.rank_code) == 'string' and type(tier.badge) == 'string' then
        row.rank_code = tier.rank_code
        row.badge = tier.badge
    end
end
