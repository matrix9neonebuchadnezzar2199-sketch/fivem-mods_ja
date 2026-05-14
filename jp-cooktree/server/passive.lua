--[[
    jp-cooktree passive.lua
    汎用ツリー + 汎用 recipe + 専門職ノードの段階ランク（KVP 永続化）

    KVP キー:
      <resName>:passive_rank:<safeId>:<sanitizedNodeId>
    nodeId は汎用なら hp_node、専門職は western:root（: は safeNodeId で _ に正規化）
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
    return CookTree.GetPlayerIdentifier(src)
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

---@param node table|nil
---@param rank integer
---@return integer
local function sumCostsToRank(node, rank)
    if not node or rank < 1 then return 0 end
    local s = 0
    for st = 1, rank do
        s = s + CookTree.GetNodeCostForStage(node, st)
    end
    return s
end

---@param nodeId string
---@return table|nil node
---@return string|nil kvId  KVP に使う論理 ID（: 可）
local function resolveStagedNode(nodeId)
    if type(nodeId) ~= 'string' or nodeId == '' then return nil, nil end
    local n = CookTree.GetNode(nodeId)
    if n and CookTree.IsStagedNode(n) then
        return n, nodeId
    end
    local sid, nid = nodeId:match('^([^:]+):(.+)$')
    if sid and nid then
        local spec = Config.Specializations and Config.Specializations[sid]
        local sn = spec and spec.nodes and spec.nodes[nid]
        if sn and CookTree.IsStagedNode(sn) then
            return sn, nodeId
        end
    end
    return nil, nil
end

---@return string[]
local function listAllStagedKvIds()
    local ids = {}
    local tree = Config and Config.GeneralTree
    if type(tree) == 'table' then
        for nodeId, node in pairs(tree) do
            if type(nodeId) == 'string' and CookTree.IsStagedNode(node) then
                ids[#ids + 1] = nodeId
            end
        end
    end
    for specId, spec in pairs(Config.Specializations or {}) do
        if spec.nodes then
            for nid, node in pairs(spec.nodes) do
                if type(nid) == 'string' and CookTree.IsStagedNode(node) then
                    ids[#ids + 1] = specId .. ':' .. nid
                end
            end
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
    for _, kvId in ipairs(listAllStagedKvIds()) do
        local rank = kvpGet(passiveRankKey(src, kvId))
        if rank > 0 then
            result[kvId] = rank
        end
    end
    return result
end

--- 段階型パッシブの合算値を Player Statebag に反映（他リソースが参照可能）
---@param src number
function CookTree.Passive.ApplyStatebag(src)
    if type(src) ~= 'number' or src <= 0 then return end
    local player = Player(src)
    if not player or not player.state then return end

    local armorNode = CookTree.GetNode and CookTree.GetNode('armor_cap_node')
    local armorRank = CookTree.Passive.GetRank(src, 'armor_cap_node')
    local armorBonus = 0
    local armorEpr = armorNode and tonumber(armorNode.effectPerRank)
    if armorEpr and armorEpr ~= 0 then
        armorBonus = math.floor(armorRank * armorEpr)
    end
    player.state:set('cooktree:armor_cap_bonus', armorBonus, true)

    local hpNode = CookTree.GetNode and CookTree.GetNode('hp_node')
    local hpRank = CookTree.Passive.GetRank(src, 'hp_node')
    local hpBonus = 0
    local hpEpr = hpNode and tonumber(hpNode.effectPerRank)
    if hpEpr and hpEpr ~= 0 then
        hpBonus = math.floor(hpRank * hpEpr)
    end
    player.state:set('cooktree:hp_bonus', hpBonus, true)

    print(('[%s][State] src=%d armor_cap_bonus=%d hp_bonus=%d'):format(resName, src, armorBonus, hpBonus))
end

---@param src number
---@param nodeId string
---@return table
function CookTree.Passive.RankUp(src, nodeId)
    local node, kvId = resolveStagedNode(nodeId)
    if not node or not kvId then
        return { ok = false, reason = 'unknown_node' }
    end

    if not CookTree.IsStagedNode(node) then
        return { ok = false, reason = 'not_staged' }
    end

    local key = passiveRankKey(src, kvId)
    local currentRank = kvpGet(key)
    local maxRank = math.floor(tonumber(node.maxRank) or 0)

    if currentRank >= maxRank then
        return { ok = false, reason = 'max_rank', newRank = currentRank }
    end

    local nextStage = currentRank + 1
    local cost = CookTree.GetNodeCostForStage(node, nextStage)
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
        resName, src, kvId, currentRank, newRank, cost, spLeft))

    CookTree.Passive.ApplyStatebag(src)

    return { ok = true, newRank = newRank, spLeft = spLeft, cost = cost }
end

--- デバッグ: 全ランクリセット + 消費 SP 返却
---@param src number
---@return integer
function CookTree.Passive.ResetAll(src)
    if type(src) ~= 'number' or src <= 0 then return 0 end
    local refundedSp = 0

    for _, kvId in ipairs(listAllStagedKvIds()) do
        local key = passiveRankKey(src, kvId)
        local rank = kvpGet(key)
        if rank > 0 then
            local node = select(1, resolveStagedNode(kvId))
            if node then
                refundedSp = refundedSp + sumCostsToRank(node, rank)
            end
            kvpSet(key, 0)
        end
    end

    if refundedSp > 0 then
        CookTree.ExtXP.AddSP(src, refundedSp)
    end

    print(('[%s][Passive] Reset src=%d refundedSp=%d'):format(resName, src, refundedSp))

    CookTree.Passive.ApplyStatebag(src)

    return refundedSp
end

if Config and Config.Debug then
    RegisterCommand('cook_reset_sp', function(source)
        if source == 0 then return end
        local refunded = CookTree.Passive.ResetAll(source)
        print(('[%s][Passive] cook_reset_sp src=%d refunded=%d'):format(resName, source, refunded))
    end, false)
end
