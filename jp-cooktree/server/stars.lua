-- レシピ別 ★ カウント（サーバー Resource KVP 永続化）
CookTree = CookTree or {}
CookTree.Stars = CookTree.Stars or {}

local resName = GetCurrentResourceName()

---@param src number
---@return string
function CookTree.Stars.GetIdentifier(src)
    if type(src) ~= 'number' or src <= 0 then return 'noid:0' end
    local id = GetPlayerIdentifier(src, 0)
    if id and id ~= '' then return id end
    print(('[%s][WARN] Stars.GetIdentifier: no identifier for src=%d, using fallback'):format(resName, src))
    return ('noid:%d'):format(src)
end

local function kvpKey(identifier, recipeId)
    local safe = (identifier or 'unknown'):gsub(':', '_'):gsub('[^%w_%-%.]', '_')
    if #safe > 96 then safe = safe:sub(1, 96) end
    if type(recipeId) ~= 'string' or recipeId == '' then recipeId = 'invalid' end
    recipeId = recipeId:gsub('[^%w_%-]', '_'):sub(1, 64)
    return ('%s:star:%s:%s'):format(resName, safe, recipeId)
end

---@param identifier string
---@param recipeId string
---@return integer
function CookTree.Stars.Get(identifier, recipeId)
    if not identifier or not recipeId then return 0 end
    local key = kvpKey(identifier, recipeId)
    local v = GetResourceKvpInt(key)
    if not v or v < 0 then return 0 end
    return math.floor(v)
end

---@param identifier string
---@param recipeId string
---@param delta integer|nil 既定 1（クリティカル時は Config 側で 2 等）
---@return integer|nil newCount nil if recipe invalid
function CookTree.Stars.Increment(identifier, recipeId, delta)
    if not Config.Recipes or not Config.Recipes[recipeId] then return nil end
    if not identifier or recipeId == '' then return nil end
    delta = delta or 1
    if type(delta) ~= 'number' or delta < 1 or math.floor(delta) ~= delta then return nil end
    delta = math.floor(delta)
    local n = CookTree.Stars.Get(identifier, recipeId) + delta
    SetResourceKvpInt(kvpKey(identifier, recipeId), n)
    return n
end

---@param identifier string
---@return table<string, integer> recipeId -> count（count>0 のみ）
function CookTree.Stars.GetAll(identifier)
    local out = {}
    if not identifier or not Config.Recipes then return out end
    for rid in pairs(Config.Recipes) do
        local c = CookTree.Stars.Get(identifier, rid)
        if c > 0 then out[rid] = c end
    end
    return out
end

---@param identifier string
---@return integer
function CookTree.Stars.GetTotal(identifier)
    local t = 0
    for _, c in pairs(CookTree.Stars.GetAll(identifier)) do
        if type(c) == 'number' then t = t + c end
    end
    return t
end
