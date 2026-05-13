--[[
    jp-cooktree passive.lua
    汎用ツリー段階型ノードのランク（KVP 永続化）

    KVP キー:
      <resName>:passive_rank:<safeId>:<nodeId>  各ノードの現ランク (Int, 0〜maxRank)
]]

CookTree = CookTree or {}
CookTree.Passive = CookTree.Passive or {}

local resName = GetCurrentResourceName()

---@param identifier string
---@return string
local function safeIdentifier(identifier)
    local safe = (identifier or 'unknown'):gsub(':', '_'):gsub('[^%w_%-%.]', '_')
    if #safe > 96 then safe = safe:sub(1, 96) end
    return safe
end

---@param src number
---@return string
local function getIdentifierForKvp(src)
    if CookTree.Stars and CookTree.Stars.GetIdentifier then
        return CookTree.Stars.GetIdentifier(src)
    end
    if type(src) ~= 'number' or src <= 0 then return 'noid:0' end
    local ids = GetPlayerIdentifiers(src)
    for _, id in ipairs(ids) do
        if type(id) == 'string' and id:sub(1, 8) == 'license:' then return id end
    end
    return ('noid:%d'):format(src)
end

---@param src number
---@return string
local function getSafeId(src)
    return safeIdentifier(getIdentifierForKvp(src))
end

---@param nodeId string
---@return string
local function safeNodeId(nodeId)
    if type(nodeId) ~= 'string' or nodeId == '' then return 'invalid' end
    return nodeId:gsub('[^%w_%-]', '_'):sub(1, 64)
end

---@param key string
---@return integer
local function kvpGet(key)
    local v = GetResourceKvpInt(key)
    if not v or v < 0 then return 0 end
    return math.floor(v)
end

---@param key string
---@param value integer
local function kvpSet(key, value)
    SetResourceKvpInt(key, value)
end

---@param src number
---@param nodeId string
---@return string
local function passiveRankKey(src, nodeId)
    return ('%s:passive_rank:%s:%s'):format(resName, getSafeId(src), safeNodeId(nodeId))
end

---@return string[]
local function listAllStagedNodeIds()
    local ids = {}
    local tree = Config and Config.GeneralTree
    if type(tree) ~= 'table' then return ids end
    for nodeId, node in pairs(tree) do
        if type(nodeId) == 'string' and CookTree.IsStagedNode(node) then
            ids[#ids + 1] = nodeId
        end
    end
    return ids
end

---@param src number
---@param nodeId string
---@return integer
function CookTree.Passive.GetRank(src, nodeId)
    if type(src) ~= 'number' or src <= 0 then return 0 end
    if type(nodeId) ~= 'string' or nodeId == '' then return 0 end
    return kvpGet(passiveRankKey(src, nodeId))
end

---@param src number
---@return table<string, integer>
function CookTree.Passive.GetAll(src)
    local result = {}
    if type(src) ~= 'number' or src <= 0 then return result end
    for _, nodeId in ipairs(listAllStagedNodeIds()) do
        local rank = kvpGet(passiveRankKey(src, nodeId))
        if rank > 0 then
            result[nodeId] = rank
        end
    end
    return result
end

---@param src number
---@param nodeId string
---@return table
function CookTree.Passive.RankUp(src, nodeId)
    local node = CookTree.GetNode and CookTree.GetNode(nodeId)
    if not node then
        return { ok = false, reason = 'unknown_node' }
    end

    if not CookTree.IsStagedNode(node) then
        return { ok = false, reason = 'not_staged' }
    end

    local key = passiveRankKey(src, nodeId)
    local currentRank = kvpGet(key)
    local maxRank = math.floor(tonumber(node.maxRank) or 0)

    if currentRank >= maxRank then
        return { ok = false, reason = 'max_rank', newRank = currentRank }
    end

    local cost = CookTree.GetNodeCostPerRank(node)
    local currentSp = CookTree.ExtXP.GetSP(src)

    if currentSp < cost then
        return { ok = false, reason = 'insufficient_sp', newRank = currentRank }
    end

    local consumed = CookTree.ExtXP.ConsumeSP(src, cost)
    if not consumed then
        return { ok = false, reason = 'consume_failed', newRank = currentRank }
    end

    local newRank = currentRank + 1
    kvpSet(key, newRank)

    local spLeft = CookTree.ExtXP.GetSP(src)

    print(('[%s][Passive] RankUp src=%d node=%s rank=%d->%d cost=%d spLeft=%d'):format(
        resName, src, nodeId, currentRank, newRank, cost, spLeft))

    return { ok = true, newRank = newRank, spLeft = spLeft, cost = cost }
end

--- デバッグ: 全ランクリセット + 消費 SP 返却
---@param src number
---@return integer
function CookTree.Passive.ResetAll(src)
    if type(src) ~= 'number' or src <= 0 then return 0 end
    local refundedSp = 0

    for _, nodeId in ipairs(listAllStagedNodeIds()) do
        local key = passiveRankKey(src, nodeId)
        local rank = kvpGet(key)
        if rank > 0 then
            local node = CookTree.GetNode(nodeId)
            local costPerRank = CookTree.GetNodeCostPerRank(node)
            refundedSp = refundedSp + (rank * costPerRank)
            kvpSet(key, 0)
        end
    end

    if refundedSp > 0 then
        CookTree.ExtXP.AddSP(src, refundedSp)
    end

    print(('[%s][Passive] Reset src=%d refundedSp=%d'):format(resName, src, refundedSp))
    return refundedSp
end

if Config and Config.Debug then
    RegisterCommand('cook_reset_sp', function(source)
        if source == 0 then return end
        local refunded = CookTree.Passive.ResetAll(source)
        print(('[%s][Passive] cook_reset_sp src=%d refunded=%d'):format(resName, source, refunded))
    end, false)
end
