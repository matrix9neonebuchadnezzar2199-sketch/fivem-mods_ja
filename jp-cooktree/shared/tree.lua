-- ツリー解放判定（Specializations + unlockNode の specId:nodeId 形式）
CookTree = CookTree or {}

---@param specId string
---@param nodeId string
---@return string
function CookTree.SpecRankKey(specId, nodeId)
    return (specId or '') .. ':' .. (nodeId or '')
end

--- 前提ノードは「段階1以上」で満たす（Lv 制限は従来どおり）。
---@param specId string
---@param nodeId string
---@param level number
---@param ranksTable table<string, integer>|nil specId:localId -> rank
function CookTree.IsNodeUnlocked(specId, nodeId, level, ranksTable)
    ranksTable = ranksTable or {}
    if type(level) ~= 'number' then return false end
    local spec = Config.Specializations and Config.Specializations[specId]
    if not spec or not spec.nodes then return false end
    local node = spec.nodes[nodeId]
    if not node then return false end
    if level < (node.lv or 1) then return false end
    for _, reqId in ipairs(node.requires or {}) do
        if not CookTree.IsNodeUnlocked(specId, reqId, level, ranksTable) then
            return false
        end
        local rk = ranksTable[CookTree.SpecRankKey(specId, reqId)] or 0
        if type(rk) ~= 'number' or rk < 1 then
            return false
        end
    end
    return true
end

--- unlockNode 指定: 専門職ツリー条件 + 解放ノード段階1以上。
--- unlockNode なし: 汎用ツリー上の recipe ノードが段階1以上（共通 Lv ゲートなし）。
---@param recipeId string
---@param level number
---@param ranksTable table<string, integer>|nil
function CookTree.IsRecipeUnlocked(recipeId, level, ranksTable)
    ranksTable = ranksTable or {}
    local recipe = Config.Recipes and Config.Recipes[recipeId]
    if not recipe then return false end

    if type(recipe.unlockNode) == 'string' and recipe.unlockNode ~= '' then
        local specId, nodeId = recipe.unlockNode:match('^(.-):(.+)$')
        if not specId or not nodeId then return false end
        if not CookTree.IsNodeUnlocked(specId, nodeId, level, ranksTable) then
            return false
        end
        local rk = ranksTable[CookTree.SpecRankKey(specId, nodeId)] or 0
        return type(rk) == 'number' and rk >= 1
    end

    local tree = Config.GeneralTree
    if type(tree) ~= 'table' then return false end
    for nodeId, node in pairs(tree) do
        if node.recipe == recipeId and CookTree.IsStagedNode(node) then
            local rk = ranksTable[nodeId] or 0
            return type(rk) == 'number' and rk >= 1
        end
    end
    return false
end

--- 調理 metadata 用: 解放に使うノードの現在段階（0=未投資）。
---@param recipeId string
---@param ranksTable table<string, integer>|nil
---@return integer
function CookTree.GetRecipeStarStage(recipeId, ranksTable)
    ranksTable = ranksTable or {}
    local recipe = Config.Recipes and Config.Recipes[recipeId]
    if not recipe then return 0 end
    if type(recipe.unlockNode) == 'string' and recipe.unlockNode ~= '' then
        local rk = ranksTable[recipe.unlockNode] or 0
        if type(rk) ~= 'number' or rk < 0 then return 0 end
        return math.floor(rk)
    end
    local tree = Config.GeneralTree
    if type(tree) ~= 'table' then return 0 end
    for nodeId, node in pairs(tree) do
        if node.recipe == recipeId and CookTree.IsStagedNode(node) then
            local rk = ranksTable[nodeId] or 0
            if type(rk) ~= 'number' or rk < 0 then return 0 end
            return math.floor(rk)
        end
    end
    return 0
end

---@param level number
---@param ranksTable table<string, integer>|nil
---@return table<string, boolean>
function CookTree.GetUnlockedRecipes(level, ranksTable)
    local result = {}
    for id, _ in pairs(Config.Recipes or {}) do
        if CookTree.IsRecipeUnlocked(id, level, ranksTable) then
            result[id] = true
        end
    end
    return result
end

---@param recipeId string
---@return string|nil, string|nil
function CookTree.FindRecipeOwner(recipeId)
    local recipe = Config.Recipes and Config.Recipes[recipeId]
    if not recipe or not recipe.unlockNode then return nil, nil end
    return recipe.unlockNode:match('^(.-):(.+)$')
end

--- KVP / State 用プレイヤー識別子（license: 優先）。server/stars 廃止後の共通実装。
---@param src number
---@return string
function CookTree.GetPlayerIdentifier(src)
    if type(src) ~= 'number' or src <= 0 then return 'noid:0' end
    local ids = GetPlayerIdentifiers(src)
    if type(ids) == 'table' then
        for _, id in ipairs(ids) do
            if type(id) == 'string' and id:sub(1, 8) == 'license:' then
                return id
            end
        end
    end
    return ('noid:%d'):format(src)
end

---@param node table|nil
---@return boolean
function CookTree.IsStagedNode(node)
    if not node or type(node) ~= 'table' then return false end
    if node.nodeType ~= 'staged' then return false end
    local mr = tonumber(node.maxRank)
    return mr ~= nil and mr > 0
end

---@param node table|nil
---@return integer
function CookTree.GetNodeCostPerRank(node)
    if not node or type(node) ~= 'table' then return 1 end
    local c = tonumber(node.spCostPerRank)
    if not c or c < 1 then return 1 end
    return math.floor(c)
end

---@param node table|nil
---@param stage integer 1..maxRank（その段階へ上げるときのコスト）
---@return integer
function CookTree.GetNodeCostForStage(node, stage)
    if not node or type(node) ~= 'table' then return 1 end
    local st = math.floor(tonumber(stage) or 0)
    local stages = node.spCostStages
    if type(stages) == 'table' and st >= 1 and st <= #stages then
        local c = tonumber(stages[st])
        if c and c >= 1 then return math.floor(c) end
    end
    return CookTree.GetNodeCostPerRank(node)
end

---@param nodeId string
---@return table|nil
function CookTree.GetNode(nodeId)
    if type(nodeId) ~= 'string' or nodeId == '' then return nil end
    local t = Config and Config.GeneralTree
    if type(t) ~= 'table' then return nil end
    return t[nodeId]
end

---@param specId string
---@param localNodeId string
---@return table|nil
function CookTree.GetSpecNode(specId, localNodeId)
    local spec = Config.Specializations and Config.Specializations[specId]
    if not spec or not spec.nodes then return nil end
    return spec.nodes[localNodeId]
end
