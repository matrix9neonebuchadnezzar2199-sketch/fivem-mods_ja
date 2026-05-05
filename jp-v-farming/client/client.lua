-- jp-v-farming client (i18n 対応・QBox 互換)
-- 原作: Virgildev/v-farming (MIT)

-- QBCore 互換: qb-core が存在する場合のみ取得（QBox環境では nil でOK）
local QBCore = nil
if GetResourceState('qb-core') == 'started' then
    QBCore = exports['qb-core']:GetCoreObject()
end

-- 安全に作物名を取得（labelKey 優先、なければ英語 label）
local function getItemLabel(fruit)
    local info = Config.ItemsFarming[fruit]
    if not info then return fruit end
    if info.labelKey then return _U(info.labelKey) end
    return info.label or fruit
end

local function getFarmLabel(farm)
    if farm.labelKey then return _U(farm.labelKey) end
    return farm.label or farm.item
end

-- 売却地点ブリップ
local SellerBlip
Citizen.CreateThread(function()
    if SellerBlip then RemoveBlip(SellerBlip) end
    SellerBlip = AddBlipForCoord(Config.SellerBlip.coords.x, Config.SellerBlip.coords.y, Config.SellerBlip.coords.z)
    SetBlipSprite(SellerBlip, Config.SellerBlip.blipSprite)
    SetBlipDisplay(SellerBlip, 4)
    SetBlipScale(SellerBlip, Config.SellerBlip.blipScale)
    SetBlipColour(SellerBlip, Config.SellerBlip.blipColor)
    SetBlipAsShortRange(SellerBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(_U('SELLER_BLIP_LABEL'))
    EndTextCommandSetBlipName(SellerBlip)
end)

-- 各農場の収穫ターゲットとブリップ
Citizen.CreateThread(function()
    for _, farm in ipairs(Config.FarmingLocations) do
        local farmLabel = getFarmLabel(farm)
        local fruitLabel = getItemLabel(farm.item)
        for _, target in ipairs(farm.targets) do
            if Config.InteractionMode ~= 'key' then
                exports.ox_target:addBoxZone({
                    coords = target.coords,
                    size = target.size or vec3(target.radius or 1.5, target.radius or 1.5, 2.0),
                    rotation = target.rotation or 0.0,
                    debug = false,
                    options = {{
                        name = farm.label,
                        icon = "fas fa-hand",
                        label = _U('PICK_LABEL', fruitLabel),
                        onSelect = function()
                            TriggerEvent("farming:harvest", { target = target, farm = farm })
                        end
                    }}
                })
            end
            local blip = AddBlipForCoord(target.coords.x, target.coords.y, target.coords.z)
            SetBlipSprite(blip, farm.blipSprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, farm.blipScale)
            SetBlipColour(blip, farm.blipColor)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(farmLabel)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

-- 収穫処理
RegisterNetEvent('farming:harvest', function(data)
    local target = data.target
    local fruit = data.farm.item
    local fruitLabel = getItemLabel(fruit)

    local animDict = target.animDict or "missmechanic"
    local animName = target.anim or "work_base"
    local radius = target.radius or 1.5
    local harvestSize = target.size or vec3(radius * 2.0, radius * 2.0, 2.0)
    local harvestRot = target.rotation or 0.0

    if Config.Progress == 'qb' and QBCore then
        QBCore.Functions.Progressbar('fruit_picking', _U('PICKING_PROGRESS', fruitLabel), Config.PickingProgress, false, true, {
            disableMovement = true, disableCarMovement = true, disableMouse = false, disableCombat = true,
        }, {
            animDict = animDict, anim = animName, flags = 1,
        }, {}, {}, function()
            TriggerServerEvent('farming:giveItem', fruit, target.amount, target.coords, harvestSize, harvestRot)
        end)
    else
        if lib.progressCircle({
            duration = Config.PickingProgress,
            label = _U('PICKING_PROGRESS', fruitLabel),
            useWhileDead = false, canCancel = true, position = 'bottom',
            disable = { car = true, move = true, combat = true, sprint = true },
            anim = { dict = animDict, clip = animName },
        }) then
            TriggerServerEvent('farming:giveItem', fruit, target.amount, target.coords, harvestSize, harvestRot)
        end
    end
end)

-- 買取 NPC 生成
Citizen.CreateThread(function()
    local pedModel = GetHashKey(Config.PedModel)
    RequestModel(pedModel)
    while not HasModelLoaded(pedModel) do Wait(500) end
    local ped = CreatePed(4, pedModel, Config.Location.coords.x, Config.Location.coords.y, Config.Location.coords.z, Config.Location.heading, false, true)
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetModelAsNoLongerNeeded(pedModel)
    if Config.InteractionMode ~= 'key' then
        exports.ox_target:addLocalEntity(ped, {{
            type = "client",
            event = "farming:openFruitMenu",
            icon = "fas fa-shopping-basket",
            label = _U('SELL_FRUITS_LABEL')
        }})
    end
end)

-- 買取メニュー
RegisterNetEvent('farming:openFruitMenu', function()
    local function filterFruits(query)
        local list = {}
        local q = string.lower(query or '')
        for fruit, info in pairs(Config.ItemsFarming) do
            local jaLabel = (info.labelKey and _U(info.labelKey)) or info.label or fruit
            local enLabel = info.label or ''
            if q == '' or string.find(string.lower(jaLabel), q, 1, true) or string.find(string.lower(enLabel), q, 1, true) then
                table.insert(list, {
                    title = jaLabel,
                    description = _U('MENU_ITEM_DESC', jaLabel),
                    icon = 'fas fa-hand',
                    onSelect = function() TriggerEvent('farming:selectFruit', { fruit = fruit }) end
                })
            end
        end
        return list
    end

    local function createMenu(searchQuery)
        local options = {}
        table.insert(options, {
            title = _U('MENU_SEARCH_TITLE'),
            description = _U('MENU_SEARCH_DESC'),
            icon = 'fas fa-search',
            onSelect = function()
                local input = lib.inputDialog(_U('MENU_SEARCH_DIALOG'), {{ type = 'input', label = _U('MENU_SEARCH_INPUT') }})
                if input and input[1] then createMenu(input[1]) end
            end
        })
        for _, item in ipairs(filterFruits(searchQuery or '')) do
            table.insert(options, item)
        end
        lib.registerContext({ id = 'farming_fruit_menu_ox', title = _U('MENU_TITLE'), options = options })
        lib.showContext('farming_fruit_menu_ox')
    end

    createMenu()
end)

-- 売却処理（数量入力 → 進行 → サーバーへ）
RegisterNetEvent('farming:selectFruit', function(data)
    local fruit = data.fruit
    local fruitLabel = getItemLabel(fruit)
    local dialog

    if Config.Menu == 'qb' and QBCore then
        dialog = exports['qb-input']:ShowInput({
            header = _U('SELL_DIALOG_TITLE', fruitLabel),
            submitText = _U('SELL_SUBMIT'),
            inputs = {{ text = _U('SELL_DIALOG_AMOUNT'), name = "amount", type = "number", isRequired = true }}
        })
    else
        dialog = lib.inputDialog(_U('SELL_DIALOG_TITLE', fruitLabel), {
            { type = "number", label = _U('SELL_DIALOG_AMOUNT'), default = 1, min = 1 }
        }, { allowCancel = true })
    end

    if dialog then
        local amount = (Config.Menu == 'qb' and QBCore) and tonumber(dialog.amount) or tonumber(dialog[1])
        if amount and amount >= 1 then
            if Config.Progress == 'qb' and QBCore then
                QBCore.Functions.Progressbar('Selling', _U('SELLING_PROGRESS', fruitLabel), Config.SellProgress, false, true, {
                    disableMovement = true, disableCarMovement = true, disableMouse = false, disableCombat = true
                }, {
                    animDict = Config.SellingAnimDict, anim = Config.SellingAnimName, flags = 1
                }, {}, {}, function()
                    TriggerServerEvent('farming:sellFruit', fruit, amount)
                end)
            else
                if lib.progressCircle({
                    duration = Config.SellProgress,
                    label = _U('SELLING_PROGRESS', fruitLabel),
                    canCancel = false, position = 'bottom',
                    disable = { car = true, move = true, combat = true, sprint = true },
                    anim = { dict = Config.SellingAnimDict, clip = Config.SellingAnimName },
                }) then
                    TriggerServerEvent('farming:sellFruit', fruit, amount)
                end
            end
        else
            if Config.Notify == 'qb' and QBCore then
                QBCore.Functions.Notify(_U('NTF_INVALID_AMOUNT_D'), 'error')
            else
                lib.notify({ title = _U('NTF_INVALID_AMOUNT_T'), description = _U('NTF_INVALID_AMOUNT_D'), type = 'error' })
            end
        end
    else
        if Config.Notify == 'qb' and QBCore then
            QBCore.Functions.Notify(_U('NTF_SALE_CANCELED_D'), 'error')
        else
            lib.notify({ title = _U('NTF_SALE_CANCELED_T'), description = _U('NTF_SALE_CANCELED_D'), type = 'error' })
        end
    end
end)

-- ============================================================
-- [E] キーによる収穫・売却（Config.InteractionMode = 'key' or 'both' で有効）
-- ============================================================

-- 収穫: 各農園の最寄りターゲットを監視
Citizen.CreateThread(function()
    if Config.InteractionMode == 'target' then return end

    local showingUI = false
    local currentTarget = nil
    local cooldownUntil = 0

    while true do
        local sleep = 1000
        local now = GetGameTimer()
        local playerCoords = GetEntityCoords(PlayerPedId())
        local nearestTarget, nearestFarm = nil, nil
        local nearestDist = Config.KeyInteractDistance or 3.0

        for _, farm in ipairs(Config.FarmingLocations) do
            for _, target in ipairs(farm.targets) do
                local d = #(playerCoords - vector3(target.coords.x, target.coords.y, target.coords.z))
                if d < nearestDist then
                    nearestDist = d
                    nearestTarget = target
                    nearestFarm = farm
                end
            end
        end

        if nearestTarget then
            sleep = 0
            if not showingUI or currentTarget ~= nearestTarget then
                local fruitLabel = getItemLabel(nearestFarm.item)
                lib.showTextUI(_U('KEY_HINT_PICK', fruitLabel), {
                    position = "right-center",
                    icon = 'hand',
                })
                showingUI = true
                currentTarget = nearestTarget
            end

            if now >= cooldownUntil and IsControlJustPressed(0, 38) then
                lib.hideTextUI()
                showingUI = false
                local t, f = nearestTarget, nearestFarm
                currentTarget = nil
                cooldownUntil = now + 1500
                TriggerEvent("farming:harvest", { target = t, farm = f })
            end
        else
            if showingUI then
                lib.hideTextUI()
                showingUI = false
                currentTarget = nil
            end
        end

        Wait(sleep)
    end
end)

-- 売却 NPC: 距離監視
Citizen.CreateThread(function()
    if Config.InteractionMode == 'target' then return end

    local showingUI = false
    local cooldownUntil = 0

    while true do
        local sleep = 1000
        local now = GetGameTimer()
        local playerCoords = GetEntityCoords(PlayerPedId())
        local sellerCoords = vector3(Config.Location.coords.x, Config.Location.coords.y, Config.Location.coords.z)
        local dist = #(playerCoords - sellerCoords)
        local maxDist = Config.KeySellDistance or 2.5

        if dist < maxDist then
            sleep = 0
            if not showingUI then
                lib.showTextUI(_U('KEY_HINT_SELL'), {
                    position = "right-center",
                    icon = 'basket-shopping',
                })
                showingUI = true
            end
            if now >= cooldownUntil and IsControlJustPressed(0, 38) then
                lib.hideTextUI()
                showingUI = false
                cooldownUntil = now + 1500
                TriggerEvent("farming:openFruitMenu")
            end
        else
            if showingUI then
                lib.hideTextUI()
                showingUI = false
            end
        end

        Wait(sleep)
    end
end)
