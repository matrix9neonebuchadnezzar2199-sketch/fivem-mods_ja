-- ============================================================
-- jp-meridian9 / server/loot/roll.lua
-- ============================================================
-- 抽選とアイテム定義検索。Config.Items / Config.LootRarityWeight のみ参照。
-- 数値特性は旧 server/loot.lua の rollRarity / pickItemForRarity を踏襲（bias なし）。
-- ============================================================

MRD9 = MRD9 or {}
MRD9.Loot = MRD9.Loot or {}

---@param itemId string
---@return table|nil
function MRD9.Loot.FindItemDef(itemId)
    if type(itemId) ~= 'string' or itemId == '' then
        return nil
    end
    for _, it in ipairs(Config.Items or {}) do
        if it.id == itemId then
            return it
        end
    end
    return nil
end

---@param weights table|nil
---@return string
function MRD9.Loot.Roll(weights)
    local w = weights
    if type(w) ~= 'table' or not next(w) then
        w = Config.LootRarityWeight or { common = 70 }
    end
    local total = 0
    for _, v in pairs(w) do
        if type(v) == 'number' and v > 0 then
            total = total + v
        end
    end
    if total <= 0 then
        return 'common'
    end
    local r = math.random() * total
    local cum = 0.0
    for tier, v in pairs(w) do
        if type(v) == 'number' and v > 0 then
            cum = cum + v
            if r <= cum then
                return type(tier) == 'string' and tier or 'common'
            end
        end
    end
    return 'common'
end

---@param tier string
---@return table|nil
function MRD9.Loot.PickItem(tier)
    local pool = {}
    for _, it in ipairs(Config.Items or {}) do
        if it.rarity == tier then
            pool[#pool + 1] = it
        end
    end
    if #pool == 0 then
        if tier ~= 'common' then
            return MRD9.Loot.PickItem('common')
        end
        return nil
    end
    return pool[math.random(1, #pool)]
end
