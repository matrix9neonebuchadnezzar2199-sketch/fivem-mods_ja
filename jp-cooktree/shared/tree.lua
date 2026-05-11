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
