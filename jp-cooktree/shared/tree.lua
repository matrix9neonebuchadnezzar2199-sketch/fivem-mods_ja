-- ツリー解放判定（Specializations + unlockNode の specId:nodeId 形式）
CookTree = CookTree or {}

---@param specId string
---@param nodeId string
---@param level number
function CookTree.IsNodeUnlocked(specId, nodeId, level)
    if type(level) ~= 'number' then return false end
    local spec = Config.Specializations and Config.Specializations[specId]
    if not spec or not spec.nodes then return false end
    local node = spec.nodes[nodeId]
    if not node then return false end
    if level < (node.lv or 1) then return false end
    for _, reqId in ipairs(node.requires or {}) do
        if not CookTree.IsNodeUnlocked(specId, reqId, level) then
            return false
        end
    end
    return true
end

---@param recipeId string
---@param level number
function CookTree.IsRecipeUnlocked(recipeId, level)
    local recipe = Config.Recipes and Config.Recipes[recipeId]
    if not recipe or not recipe.unlockNode then return false end
    local specId, nodeId = recipe.unlockNode:match('^(.-):(.+)$')
    if not specId or not nodeId then return false end
    return CookTree.IsNodeUnlocked(specId, nodeId, level)
end

---@param level number
---@return table<string, boolean>
function CookTree.GetUnlockedRecipes(level)
    local result = {}
    for id, _ in pairs(Config.Recipes or {}) do
        if CookTree.IsRecipeUnlocked(id, level) then
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

---@param nodeId string
---@return table|nil
function CookTree.GetNode(nodeId)
    if type(nodeId) ~= 'string' or nodeId == '' then return nil end
    local t = Config and Config.GeneralTree
    if type(t) ~= 'table' then return nil end
    return t[nodeId]
end
