local isOpen = false
local currentSpecId = 'western' -- 現在表示中の専門職 ID

-- NUI 調理: ミニゲーム完了 → サーバ応答待ち → ツリー再オープン（サーバイベントは cook スレッド中のみ受け付け）
local pendingCookServerResult = nil
local cookNuiFlow = false
local cookNuiExpectedRecipeId = nil

-- 次回 openTree() 時に NUI へフラッシュ表示する直前の調理結果（recipeId + result）。
-- グローバル汚染を防ぐためファイル先頭で local 宣言。fivem-lua.mdc §1 準拠。
local pendingCookResult = nil

-- requestCookStart 応答待ちのレシピ ID（多重押下・競合抑止）
local pendingCookRecipeId = nil

-- P3b: サーバーから返る ★（NUI オープン前に受信した分をキャッシュ）
local recipeStarsCache = {}
local starTotalCache = 0
-- ext_xp: 直近の Lv / SP（requestPlayerState 応答までの表示用）
local playerLevelCache = 1
local playerSpCache = 0
local passiveRanksCache = {}

local function buildCookRecipeBook()
    local t = {}
    for k in pairs(Config.Recipes or {}) do
        t[k] = true
    end
    return t
end

---@param level integer
---@return table<string, boolean>
local function buildRecipeUnlockedMap(level)
    if CookTree and CookTree.GetUnlockedRecipes then
        return CookTree.GetUnlockedRecipes(level) or {}
    end
    return {}
end

local function openTree()
    if isOpen then return end
    isOpen = true
    SetNuiFocus(true, true)
    local payload = {
        action = 'open',
        specializations = Config.Specializations,
        currentSpec = currentSpecId,
        level = playerLevelCache,
        sp = playerSpCache,
        stars = starTotalCache,
        recipeStars = recipeStarsCache,
        starTotal = starTotalCache,
        generalTree = Config.GeneralTree,
        generalRanks = {},
        cookRecipeBook = buildCookRecipeBook(),
        passiveRanks = passiveRanksCache,
        recipeUnlocked = buildRecipeUnlockedMap(playerLevelCache),
    }
    if pendingCookResult then
        payload.cookResult = pendingCookResult
        pendingCookResult = nil
    end
    SendNUIMessage(payload)
    TriggerServerEvent('jp-cooktree:requestPlayerState')
end

local function closeTree()
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

---@return boolean
local function runRecipeStages(recipe)
    local stages = recipe.stages or {}
    if type(stages) ~= 'table' or #stages < 1 then
        return true
    end

    local resourceName = (Config and Config.GlitchMinigamesResource) or 'jp-glitch28'
    local gm = exports[resourceName]
    if not gm then
        print(('[%s] cook: Glitch export missing (ensure %s)'):format(GetCurrentResourceName(), resourceName))
        return false
    end

    for i, stage in ipairs(stages) do
        local exportName = stage.export or stage.game
        if type(exportName) ~= 'string' or exportName == '' then
            print(('[%s] cook: invalid stage.export / stage.game at %d'):format(GetCurrentResourceName(), i))
            return false
        end

        print(('[%s] Stage %d/%d: %s'):format(
            GetCurrentResourceName(),
            i,
            #stages,
            stage.label or exportName
        ))

        local args = stage.args or {}
        local ok
        if exportName == 'StartSkillCheckGame' then
            ok = gm:StartSkillCheckGame(table.unpack(args))
        else
            local fn = gm[exportName]
            if type(fn) ~= 'function' then
                print(('[%s] cook: no export %s on %s'):format(GetCurrentResourceName(), exportName, resourceName))
                return false
            end
            ok = fn(table.unpack(args))
        end

        if ok ~= true then
            return false
        end
    end

    return true
end

RegisterNetEvent('jp-cooktree:receivePlayerState', function(data)
    if type(data) ~= 'table' then return end
    recipeStarsCache = type(data.recipeStars) == 'table' and data.recipeStars or {}
    if type(data.starTotal) == 'number' then
        starTotalCache = data.starTotal
    else
        starTotalCache = 0
        for _, c in pairs(recipeStarsCache) do
            if type(c) == 'number' then starTotalCache = starTotalCache + c end
        end
    end
    playerLevelCache = tonumber(data.level) or 1
    playerSpCache = tonumber(data.sp) or 0
    passiveRanksCache = type(data.passiveRanks) == 'table' and data.passiveRanks or {}
    if isOpen then
        SendNUIMessage({
            action = 'updatePlayerState',
            level = playerLevelCache,
            sp = playerSpCache,
            xp = tonumber(data.xp) or 0,
            nextLevelXp = data.nextLevelXp,
            recipeStars = recipeStarsCache,
            starTotal = starTotalCache,
            passiveRanks = passiveRanksCache,
            recipeUnlocked = buildRecipeUnlockedMap(playerLevelCache),
        })
    end
end)

RegisterNetEvent('jp-cooktree:passiveRankUpResponse', function(result)
    if type(result) ~= 'table' then return end
    SendNUIMessage({
        action = 'rankUpResponse',
        ok = result.ok == true,
        reason = result.reason,
        nodeId = result.nodeId,
        newRank = result.newRank,
        spLeft = result.spLeft,
        cost = result.cost,
    })
end)

RegisterNetEvent('jp-cooktree:cookStartResponse', function(allowed, reason, recipeId)
    local rid = type(recipeId) == 'string' and recipeId or ''
    if rid == '' or rid ~= pendingCookRecipeId then
        return
    end

    if allowed ~= true then
        pendingCookRecipeId = nil
        SendNUIMessage({
            action = 'cookDenied',
            reason = type(reason) == 'string' and reason or 'error',
            recipeId = rid,
        })
        return
    end

    local recipe = Config.Recipes and Config.Recipes[rid]
    if not recipe then
        pendingCookRecipeId = nil
        return
    end

    pendingCookServerResult = nil
    cookNuiFlow = true
    cookNuiExpectedRecipeId = rid
    CreateThread(function()
        closeTree()
        Wait(150)
        local success = runRecipeStages(recipe)
        TriggerServerEvent('jp-cooktree:submitCookResult', rid, success == true)
        local deadline = GetGameTimer() + 8000
        while pendingCookServerResult == nil and GetGameTimer() < deadline do
            Wait(50)
        end
        local pr = pendingCookServerResult
        pendingCookServerResult = nil
        cookNuiFlow = false
        cookNuiExpectedRecipeId = nil
        pendingCookRecipeId = nil
        if pr then
            pendingCookResult = pr
        else
            pendingCookResult = { recipeId = rid, result = success and 'success' or 'failed' }
        end
        Wait(150)
        if not isOpen then openTree() end
    end)
end)

RegisterNetEvent('jp-cooktree:cookResultConfirmed', function(recipeId, resultType)
    if not cookNuiFlow then return end
    local rid = type(recipeId) == 'string' and recipeId or ''
    if cookNuiExpectedRecipeId and rid ~= cookNuiExpectedRecipeId then return end
    pendingCookServerResult = {
        recipeId = rid,
        result = type(resultType) == 'string' and resultType or 'error',
    }
end)

RegisterCommand('cooktree', function() openTree() end, false)

-- NUI: 調理（サーバー事前許可 → ミニゲーム → サーバー確定）。F8 の cook_test は再オープンしない。
RegisterNUICallback('cook', function(data, cb)
    local recipeId = data and data.recipeId
    if type(recipeId) ~= 'string' or recipeId == '' then
        cb({ ok = false })
        return
    end
    if not (Config.Recipes and Config.Recipes[recipeId]) then
        print(('[%s] NUI cook: unknown recipe %s'):format(GetCurrentResourceName(), recipeId))
        cb({ ok = false })
        return
    end
    if pendingCookRecipeId or cookNuiFlow then
        cb({ ok = false, busy = true })
        return
    end
    cb({ ok = true })

    pendingCookRecipeId = recipeId
    TriggerServerEvent('jp-cooktree:requestCookStart', recipeId)
end)

-- P3c: デバッグ用コマンド（NUI 再オープンなし）
RegisterCommand('cook_test', function(_, args)
    local recipeId = args[1]
    if not recipeId or recipeId == '' then
        print(('[%s] Usage: cook_test <recipeId>'):format(GetCurrentResourceName()))
        return
    end

    local recipe = Config.Recipes and Config.Recipes[recipeId]
    if not recipe then
        print(('[%s] Unknown recipe: %s'):format(GetCurrentResourceName(), recipeId))
        return
    end

    local nStages = #(recipe.stages or {})
    print(('[%s] cook_test start recipe=%s stages=%d'):format(GetCurrentResourceName(), recipeId, nStages))

    local success = runRecipeStages(recipe)
    print(('[%s] cook_test result success=%s'):format(GetCurrentResourceName(), tostring(success)))

    TriggerServerEvent('jp-cooktree:submitCookResult', recipeId, success == true)
end, false)

RegisterNUICallback('close', function(_, cb)
    closeTree()
    cb({ ok = true })
end)

RegisterNUICallback('selectSpec', function(data, cb)
    if Config.Specializations[data.specId] then
        currentSpecId = data.specId
    end
    cb({ ok = true, currentSpec = currentSpecId })
end)

RegisterNUICallback('rankUp', function(data, cb)
    cb({ ok = true })
    if not data or type(data.nodeId) ~= 'string' or data.nodeId == '' then return end
    TriggerServerEvent('jp-cooktree:requestPassiveRankUp', data.nodeId)
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    pendingCookRecipeId = nil
    pendingCookServerResult = nil
    cookNuiFlow = false
    cookNuiExpectedRecipeId = nil
    pendingCookResult = nil
    if isOpen then
        SetNuiFocus(false, false)
    end
end)
