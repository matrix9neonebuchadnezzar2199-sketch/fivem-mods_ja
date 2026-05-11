-- P3a: 調理配管（常に成功・素材なし）。ミニゲーム/失敗/★/クリは P3b 以降。

local resName = GetCurrentResourceName()
local lastUse = {}

local function doCookSession(src, recipeId)
    if type(src) ~= 'number' or src <= 0 then return end
    if type(recipeId) ~= 'string' or recipeId == '' then return end

    local recipe = Config.Recipes and Config.Recipes[recipeId]
    if not recipe then
        print(('[%s] Unknown recipe src=%d recipe=%s'):format(resName, src, recipeId))
        return
    end

    local now = os.time()
    local cd = (Config.Cooldowns and Config.Cooldowns.globalSec) or 5
    if (now - (lastUse[src] or 0)) < cd then
        print(('[%s] cook denied cooldown src=%d'):format(resName, src))
        return
    end

    local level = CookTree.ExtXP.GetLevel(src)
    if not CookTree.IsRecipeUnlocked(recipeId, level) then
        print(('[%s] Unlock denied src=%d recipe=%s lv=%d'):format(resName, src, recipeId, level))
        return
    end

    -- P3a: 常に成功（ミニゲームは P3c）
    local success = true
    if success then
        if not recipe.result or not recipe.result.item then
            print(('[%s] cook error: recipe missing result src=%d recipe=%s'):format(resName, src, recipeId))
            return
        end
        local added = CookTree.Inv.AddItem(src, recipe.result.item, recipe.result.count or 1)
        if not added then
            print(('[%s] cook aborted: AddItem failed src=%d recipe=%s'):format(resName, src, recipeId))
            return
        end
        lastUse[src] = now
        local exp = tonumber(recipe.exp) or 0
        if exp > 0 then
            CookTree.ExtXP.AddXP(src, exp)
        end
        print(('[%s] Cook success src=%d recipe=%s exp=%d'):format(resName, src, recipeId, exp))
    else
        if recipe.failureResult and recipe.failureResult.item then
            CookTree.Inv.AddItem(src, recipe.failureResult.item, recipe.failureResult.count or 1)
        end
        print(('[%s] Cook failed src=%d recipe=%s'):format(resName, src, recipeId))
    end
end

RegisterNetEvent('jp-cooktree:requestCookSession', function(recipeId)
    local src = source
    if not src or src <= 0 then return end
    doCookSession(src, recipeId)
end)

AddEventHandler('playerDropped', function()
    local src = source
    if src and src > 0 then
        lastUse[src] = nil
    end
end)

-- サーバー側コマンド（txAdmin 等 src=0 では調理不可。プレイヤーは client の cook_test から TriggerServerEvent を使用）
RegisterCommand('cook_test', function(src, args)
    if not args[1] then
        print(('[%s] Usage: cook_test <recipeId> (player client / F8 → client forwards here)'):format(resName))
        return
    end
    if not src or src <= 0 then
        print(('[%s] cook_test: use in-game F8 as player, or TriggerServerEvent from client'):format(resName))
        return
    end
    doCookSession(src, args[1])
end, false)
