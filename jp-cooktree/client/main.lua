local isOpen = false
local currentSpecId = 'western'      -- 現在表示中の専門職 ID

local function openTree()
    if isOpen then return end
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        specializations = Config.Specializations,
        currentSpec = currentSpecId,
        level = Config.DummyLevel,
        sp = 3,                       -- ダミー SP
        stars = Config.DummyStars,
        generalTree = Config.GeneralTree,
        generalRanks = {}, -- P2.7: 全0段表示（P3b で永続ランク）
    })
end

local function closeTree()
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterCommand('cooktree', function() openTree() end, false)

-- F8 / チャット用: サーバーへ調理リクエスト（source はサーバーで正しく取れる）
RegisterCommand('cook_test', function(_, args)
    if not args[1] then
        print(('[%s] Usage: cook_test <recipeId>'):format(GetCurrentResourceName()))
        return
    end
    TriggerServerEvent('jp-cooktree:requestCookSession', args[1])
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

-- リソース停止時のフォーカス残り防止（fivem-nui.mdc §1 必須項目）
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if isOpen then
        SetNuiFocus(false, false)
    end
end)
