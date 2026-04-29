-- 絵柄抽選・配当判定（単体テストしやすいよう関数分割）
RNG = {}

--- 空白除去
---@param s string
---@return string
local function trim(s)
    return (string.gsub(s, '^%s*(.-)%s*$', '%1'))
end

--- 重み付き抽選（キーはオプション table または平行配列）
---@param weights number[]
---@param items string[]
---@return string|nil
function RNG.pickWeighted(weights, items)
    if not weights or not items or #weights ~= #items or #items == 0 then
        return nil
    end
    local sum = 0
    for i = 1, #weights do
        sum = sum + (tonumber(weights[i]) or 0)
    end
    if sum <= 0 then
        return items[1]
    end
    local r = math.random() * sum
    local acc = 0
    for i = 1, #weights do
        acc = acc + (tonumber(weights[i]) or 0)
        if r <= acc then
            return items[i]
        end
    end
    return items[#items]
end

--- 1リール分の絵柄をペイテーブルから決定
---@param paytable table
---@return string|nil
function RNG.pickSymbolForReel(paytable)
    return RNG.pickWeighted(paytable.weights, paytable.symbols)
end

--- パターン1つとリールが一致するか（ワイルド・*対応）
---@param reel string
---@param pat string
---@return boolean
function RNG.symbolMatchesPattern(reel, pat)
    pat = trim(pat)
    if pat == '*' then
        return true
    end
    if pat == 'wild' then
        return reel == 'wild'
    end
    return reel == pat or reel == 'wild'
end

--- combo 文字列をパターン配列へ
---@param combo string
---@return string[]
local function splitCombo(combo)
    local parts = {}
    for piece in string.gmatch(combo, '([^,]+)') do
        parts[#parts + 1] = trim(piece)
    end
    return parts
end

--- 全リールがパターンに一致するか
---@param reels string[]
---@param patternParts string[]
---@return boolean
local function reelsMatchPattern(reels, patternParts)
    if #patternParts ~= #reels then
        return false
    end
    for i = 1, #reels do
        if not RNG.symbolMatchesPattern(reels[i], patternParts[i]) then
            return false
        end
    end
    return true
end

--- リール結果から配当を検索（先頭から順に最初の一致のみ）
---@param reels string[]
---@param paytable table
---@return table { multiplier number, tier string|nil, comboName string|nil }
function RNG.evaluate(reels, paytable)
    local payouts = paytable.payouts or {}
    for i = 1, #payouts do
        local row = payouts[i]
        local combo = row.combo
        if type(combo) == 'string' then
            local parts = splitCombo(combo)
            if reelsMatchPattern(reels, parts) then
                return {
                    multiplier = tonumber(row.multiplier) or 0,
                    tier = row.tier,
                    comboName = combo,
                }
            end
        end
    end
    return { multiplier = 0, tier = nil, comboName = nil }
end

--- 3リール分スピンして評価結果を返す
---@param paytableId string
---@param opts table|nil forceWin forceJackpot
---@return table
function RNG.spin(paytableId, opts)
    opts = opts or {}
    local pt = Config.Paytables[paytableId]
    if not pt then
        return { reels = { 'cherry', 'cherry', 'cherry' }, payout = { multiplier = 0 }, paytableId = paytableId }
    end
    local reels = {}
    for _ = 1, 3 do
        reels[#reels + 1] = RNG.pickSymbolForReel(pt) or 'cherry'
    end
    local payout = RNG.evaluate(reels, pt)

    -- デバッグ: 強制当選（最大80回まで再抽選）
    if opts.forceJackpot then
        local tries = 0
        while tries < 80 do
            tries = tries + 1
            local r = {}
            for _ = 1, 3 do
                r[#r + 1] = RNG.pickSymbolForReel(pt) or 'cherry'
            end
            local ev = RNG.evaluate(r, pt)
            if ev.tier == 'jackpot' then
                reels = r
                payout = ev
                break
            end
        end
    elseif opts.forceWin then
        local tries = 0
        while tries < 120 and (payout.multiplier or 0) <= 0 do
            tries = tries + 1
            local r = {}
            for _ = 1, 3 do
                r[#r + 1] = RNG.pickSymbolForReel(pt) or 'cherry'
            end
            local ev = RNG.evaluate(r, pt)
            reels = r
            payout = ev
        end
    elseif opts.forceLoss then
        local tries = 0
        while tries < 400 and (payout.multiplier or 0) > 0 do
            tries = tries + 1
            local r = {}
            for _ = 1, 3 do
                r[#r + 1] = RNG.pickSymbolForReel(pt) or 'cherry'
            end
            local ev = RNG.evaluate(r, pt)
            reels = r
            payout = ev
        end
    end

    return {
        reels = reels,
        payout = payout,
        paytableId = paytableId,
    }
end
