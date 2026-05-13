-- P3c/P3d: クライアント Glitch ミニゲーム結果を受け、成功／失敗／クリティカル分岐。
-- clientSuccess はクライアント報告のため改ざん可能（本番ではステーション＋検証強化を想定）。

local resName = GetCurrentResourceName()
local lastUse = {}

---@param quality string 'normal' | 'critical' | 'failed'
---@param star boolean
---@param src number
---@return table
local function buildCookMetadata(quality, star, src)
    local playerName = GetPlayerName(src)
    if type(playerName) ~= 'string' or playerName == '' then
        playerName = ('id:%d'):format(src)
    end
    return {
        quality = quality,
        star = star == true,
        cookedBy = playerName,
        cookedAt = os.time(),
    }
end

--- NUI 用: ★マップ・合計・料理 XP 状態を一括送信
---@param src number
local function pushPlayerStateToClient(src)
    if not src or src <= 0 then return end
    local ident = CookTree.Stars.GetIdentifier(src)
    local map = CookTree.Stars.GetAll(ident)
    local total = CookTree.Stars.GetTotal(ident)
    local xpState = CookTree.ExtXP.GetAll(src)
    TriggerClientEvent('jp-cooktree:receivePlayerState', src, {
        recipeStars = map,
        starTotal = total,
        level = xpState.level,
        sp = xpState.sp,
        xp = xpState.xp,
        nextLevelXp = xpState.nextLevelXp,
        passiveRanks = CookTree.Passive.GetAll(src),
    })
end

--- NUI 調理フロー用: 成否種別（クライアントは pending 再オープン時のみ使用）
---@param src number
---@param recipeId string
---@param resultType string success | critical | failed | cooldown | unlock_denied | inventory_full | error
local function notifyCookUi(src, recipeId, resultType)
    if not src or src <= 0 or type(recipeId) ~= 'string' or recipeId == '' then return end
    TriggerClientEvent('jp-cooktree:cookResultConfirmed', src, recipeId, resultType)
end

---@param src number
---@param recipeId string
---@param clientSuccess boolean ミニゲーム成否（クライアント報告）
local function handleSubmitCookResult(src, recipeId, clientSuccess)
    if type(src) ~= 'number' or src <= 0 then return end
    if type(recipeId) ~= 'string' or recipeId == '' then return end
    if type(clientSuccess) ~= 'boolean' then return end

    local recipe = Config.Recipes and Config.Recipes[recipeId]
    if not recipe then
        print(('[%s] Unknown recipe src=%d recipe=%s'):format(resName, src, recipeId))
        notifyCookUi(src, recipeId, 'error')
        return
    end

    local now = os.time()
    local cd = (Config.Cooldowns and Config.Cooldowns.globalSec) or 5
    if (now - (lastUse[src] or 0)) < cd then
        print(('[%s] cook denied cooldown src=%d'):format(resName, src))
        notifyCookUi(src, recipeId, 'cooldown')
        return
    end

    local level = CookTree.ExtXP.GetLevel(src)
    if not CookTree.IsRecipeUnlocked(recipeId, level) then
        print(('[%s] Unlock denied src=%d recipe=%s lv=%d'):format(resName, src, recipeId, level))
        notifyCookUi(src, recipeId, 'unlock_denied')
        return
    end

    if not clientSuccess then
        local fail = recipe.failureResult or { item = 'failed_dish', count = 1 }
        if not fail.item then
            print(('[%s] cook fail: no failureResult item src=%d recipe=%s'):format(resName, src, recipeId))
            notifyCookUi(src, recipeId, 'error')
            return
        end
        local metaFail = buildCookMetadata('failed', false, src)
        local addedFail = CookTree.Inv.AddItem(src, fail.item, fail.count or 1, metaFail)
        if not addedFail then
            print(('[%s] cook fail aborted: AddItem failed src=%d recipe=%s'):format(resName, src, recipeId))
            notifyCookUi(src, recipeId, 'inventory_full')
            return
        end
        lastUse[src] = now
        print(('[%s] Cook failed src=%d recipe=%s -> %s quality=failed'):format(resName, src, recipeId, fail.item))
        notifyCookUi(src, recipeId, 'failed')
        return
    end

    if not recipe.result or not recipe.result.item then
        print(('[%s] cook error: recipe missing result src=%d recipe=%s'):format(resName, src, recipeId))
        notifyCookUi(src, recipeId, 'error')
        return
    end

    local baseExp = tonumber(recipe.exp) or 0
    local critCfg = Config.CriticalMultiplier or {}
    local expMult = 1
    local starDelta = 1
    local isCritical = false
    local chance = tonumber(Config.CriticalChance) or 0.0
    if chance > 0 and math.random() < chance then
        isCritical = true
        expMult = tonumber(critCfg.exp) or 2
        starDelta = tonumber(critCfg.stars) or 2
    end

    local metaOk
    if isCritical then
        metaOk = buildCookMetadata('critical', true, src)
    else
        metaOk = buildCookMetadata('normal', false, src)
    end

    local added = CookTree.Inv.AddItem(src, recipe.result.item, recipe.result.count or 1, metaOk)
    if not added then
        print(('[%s] cook aborted: AddItem failed src=%d recipe=%s'):format(resName, src, recipeId))
        notifyCookUi(src, recipeId, 'inventory_full')
        return
    end
    lastUse[src] = now

    local expGain = math.floor(baseExp * expMult)
    if expGain > 0 then
        CookTree.ExtXP.AddXP(src, expGain)
    end

    local ident = CookTree.Stars.GetIdentifier(src)
    local newStars = CookTree.Stars.Increment(ident, recipeId, starDelta)
    if newStars then
        print(('[%s] Star count recipe=%s new=%d (+%d) src=%d'):format(resName, recipeId, newStars, starDelta, src))
    end

    if isCritical then
        print(('[%s] CRITICAL quality=critical src=%d recipe=%s exp=%d (x%d)'):format(resName, src, recipeId, expGain, expMult))
    else
        print(('[%s] Cook success quality=normal src=%d recipe=%s exp=%d'):format(resName, src, recipeId, expGain))
    end

    pushPlayerStateToClient(src)
    notifyCookUi(src, recipeId, isCritical and 'critical' or 'success')
end

RegisterNetEvent('jp-cooktree:submitCookResult', function(recipeId, clientSuccess)
    local src = source
    if not src or src <= 0 then return end
    handleSubmitCookResult(src, recipeId, clientSuccess)
end)

-- 調理開始前: unlock・インベントリ容量のみサーバー権威で検証（ミニゲーム前に拒否）
RegisterNetEvent('jp-cooktree:requestCookStart', function(recipeId)
    local src = source
    if not src or src <= 0 then return end
    if type(recipeId) ~= 'string' or recipeId == '' then
        TriggerClientEvent('jp-cooktree:cookStartResponse', src, false, 'unknown_recipe', recipeId or '')
        return
    end

    local recipe = Config.Recipes and Config.Recipes[recipeId]
    if not recipe then
        print(('[%s] cook start denied src=%d recipe=%s reason=unknown_recipe'):format(resName, src, recipeId))
        TriggerClientEvent('jp-cooktree:cookStartResponse', src, false, 'unknown_recipe', recipeId)
        return
    end

    local playerLevel = CookTree.ExtXP.GetLevel(src)
    if not CookTree.IsRecipeUnlocked(recipeId, playerLevel) then
        print(('[%s] cook start denied src=%d recipe=%s reason=locked lv=%d'):format(resName, src, recipeId, playerLevel))
        TriggerClientEvent('jp-cooktree:cookStartResponse', src, false, 'locked', recipeId)
        return
    end

    if not recipe.result or not recipe.result.item then
        print(('[%s] cook start denied src=%d recipe=%s reason=no_result'):format(resName, src, recipeId))
        TriggerClientEvent('jp-cooktree:cookStartResponse', src, false, 'unknown_recipe', recipeId)
        return
    end

    local count = tonumber(recipe.result.count) or 1
    if count < 1 or math.floor(count) ~= count then count = 1 end

    local okCarry, canCarry = pcall(function()
        return exports.ox_inventory:CanCarryItem(src, recipe.result.item, count)
    end)
    if not okCarry then
        print(('[%s] cook start denied src=%d recipe=%s reason=can_carry_error'):format(resName, src, recipeId))
        TriggerClientEvent('jp-cooktree:cookStartResponse', src, false, 'inventory_full', recipeId)
        return
    end
    if not canCarry then
        print(('[%s] cook start denied src=%d recipe=%s reason=inventory_full'):format(resName, src, recipeId))
        TriggerClientEvent('jp-cooktree:cookStartResponse', src, false, 'inventory_full', recipeId)
        return
    end

    TriggerClientEvent('jp-cooktree:cookStartResponse', src, true, nil, recipeId)
end)

AddEventHandler('playerDropped', function()
    local src = source
    if src and src > 0 then
        lastUse[src] = nil
    end
end)

RegisterNetEvent('jp-cooktree:requestStars', function()
    local src = source
    if not src or src <= 0 then return end
    pushPlayerStateToClient(src)
end)

RegisterNetEvent('jp-cooktree:requestPlayerState', function()
    local src = source
    if not src or src <= 0 then return end
    pushPlayerStateToClient(src)
end)

RegisterNetEvent('jp-cooktree:requestPassiveRankUp', function(nodeId)
    local src = source
    if not src or src <= 0 then return end

    if type(nodeId) ~= 'string' or nodeId == '' then
        TriggerClientEvent('jp-cooktree:passiveRankUpResponse', src, {
            ok = false,
            reason = 'invalid_node',
            nodeId = nodeId,
        })
        return
    end

    local result = CookTree.Passive.RankUp(src, nodeId)

    TriggerClientEvent('jp-cooktree:passiveRankUpResponse', src, {
        ok = result.ok,
        reason = result.reason,
        nodeId = nodeId,
        newRank = result.newRank,
        spLeft = result.spLeft,
        cost = result.cost,
    })

    if result.ok then
        pushPlayerStateToClient(src)
    end
end)
