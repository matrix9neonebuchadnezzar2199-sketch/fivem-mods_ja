local QBCore = exports['qb-core']:GetCoreObject()

local function getItemLabelKey(fruit)
    local info = Config.ItemsFarming[fruit]
    if info and info.labelKey then
        return info.labelKey
    end
    return 'ITEM_' .. string.upper(fruit)
end

local function getFarmBlipKey(farm)
    if farm.labelKey then
        return farm.labelKey
    end
    return 'FARM_' .. string.upper(farm.item)
end

Citizen.CreateThread(function()
    if SellerBlip then
        RemoveBlip(SellerBlip)
    end

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

Citizen.CreateThread(function()
    for _, farm in ipairs(Config.FarmingLocations) do
        for _, target in ipairs(farm.targets) do
            local radius = target.radius or 1.0
            local boxSize = target.size or vec3(radius * 2.0, radius * 2.0, 2.0)
            local rotation = target.rotation or 0.0

            exports.ox_target:addBoxZone({
                coords = target.coords,
                size = boxSize,
                rotation = rotation,
                debug = false,
                options = {
                    {
                        name = farm.label,
                        icon = "fas fa-hand",
                        label = _U('PICK_LABEL', _U(getItemLabelKey(farm.item))),
                        onSelect = function()
                            TriggerEvent("farming:harvest", { target = target, farm = farm })
                        end
                    }
                }
            })

            local blip = AddBlipForCoord(target.coords.x, target.coords.y, target.coords.z)
            SetBlipSprite(blip, farm.blipSprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, farm.blipScale)
            SetBlipColour(blip, farm.blipColor)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(_U(getFarmBlipKey(farm)))
            EndTextCommandSetBlipName(blip)
        end
    end
end)

RegisterNetEvent('farming:harvest')
AddEventHandler('farming:harvest', function(data)
    local target = data.target
    local fruit = data.farm.item
    local location = nil

    for _, farmLocation in ipairs(Config.FarmingLocations) do
        if farmLocation.item == fruit then
            location = farmLocation
            break
        end
    end

    if not location then
        print('No location found for fruit:', fruit)
        return
    end

    local animDict = location.targets[1].animDict
    local animName = location.targets[1].anim

    for _, locTarget in ipairs(location.targets) do
        if locTarget.coords.x == target.coords.x and locTarget.coords.y == target.coords.y and locTarget.coords.z == target.coords.z then
            animDict = locTarget.animDict
            animName = locTarget.anim
            break
        end
    end

    local pickLabel = _U(getItemLabelKey(fruit))
    local radius = target.radius or 1.0
    local boxSize = target.size or vec3(radius * 2.0, radius * 2.0, 2.0)
    local rotation = target.rotation or 0.0

    if Config.Progress == 'qb' then
        QBCore.Functions.Progressbar('fruit_picking', _U('PICKING_PROGRESS', pickLabel), Config.PickingProgress, false, true, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {
            animDict = animDict,
            anim = animName,
            flags = 1,
        }, {}, {},
        function()
            TriggerServerEvent('farming:giveItem', fruit, target.amount, target.coords, boxSize, rotation)
        end)
    else
        if lib.progressCircle({
            duration = Config.PickingProgress,
            label = _U('PICKING_PROGRESS', pickLabel),
            useWhileDead = false,
            canCancel = true,
            position = 'bottom',
            disable = {
                car = true,
                move = true,
                combat = true,
                sprint = true,
            },
            anim = {
                dict = animDict,
                clip = animName
            },
        }) then
            TriggerServerEvent('farming:giveItem', fruit, target.amount, target.coords, boxSize, rotation)
        end
    end
end)

Citizen.CreateThread(function()
    local pedModel = GetHashKey(Config.PedModel)
    RequestModel(pedModel)
    while not HasModelLoaded(pedModel) do
        Wait(500)
    end

    local ped = CreatePed(4, pedModel, Config.Location.coords.x, Config.Location.coords.y, Config.Location.coords.z, Config.Location.heading, false, true)
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetModelAsNoLongerNeeded(pedModel)

    exports.ox_target:addLocalEntity(ped, {
        {
            type = "client",
            event = "farming:openFruitMenu",
            icon = "fas fa-shopping-basket",
            label = _U('SELL_FRUITS_LABEL')
        }
    })
end)

RegisterNetEvent('farming:openFruitMenu')
AddEventHandler('farming:openFruitMenu', function()
    local function filterFruits(query)
        local filteredFruits = {}
        local q = query or ''
        for fruit, info in pairs(Config.ItemsFarming) do
            local jaLabel = _U(info.labelKey or getItemLabelKey(fruit))
            local enLabel = info.label or ''
            local match = q == ''
                or string.find(string.lower(jaLabel), string.lower(q), 1, true)
                or string.find(string.lower(enLabel), string.lower(q), 1, true)
            if jaLabel and match then
                table.insert(filteredFruits, {
                    title = jaLabel,
                    description = _U('MENU_ITEM_DESC', jaLabel),
                    icon = 'fas fa-hand',
                    onSelect = function()
                        TriggerEvent('farming:selectFruit', { fruit = fruit })
                    end
                })
            end
        end
        return filteredFruits
    end

    local function createMenu(searchQuery)
        local options = {}

        table.insert(options, {
            title = _U('MENU_SEARCH_TITLE'),
            description = _U('MENU_SEARCH_DESC'),
            icon = 'fas fa-search',
            onSelect = function()
                local input = lib.inputDialog(_U('MENU_SEARCH_DIALOG'), {
                    { type = 'input', label = _U('MENU_SEARCH_INPUT') }
                })

                if input and input[1] then
                    createMenu(input[1])
                end
            end
        })

        for _, menuItem in ipairs(filterFruits(searchQuery or '')) do
            table.insert(options, menuItem)
        end

        lib.registerContext({
            id = 'farming_fruit_menu_ox',
            title = _U('MENU_TITLE'),
            options = options
        })

        lib.showContext('farming_fruit_menu_ox')
    end

    createMenu()
end)

RegisterNetEvent('farming:selectFruit')
AddEventHandler('farming:selectFruit', function(data)
    local fruit = data.fruit
    local itemInfo = Config.ItemsFarming[fruit]
    if not itemInfo then
        return
    end

    local displayLabel = _U(itemInfo.labelKey or getItemLabelKey(fruit))

    local dialog
    if Config.Menu == 'qb' then
        dialog = exports['qb-input']:ShowInput({
            header = _U('SELL_DIALOG_TITLE', displayLabel),
            submitText = _U('SELL_SUBMIT'),
            inputs = {
                {
                    text = _U('SELL_DIALOG_AMOUNT'),
                    name = "amount",
                    type = "number",
                    isRequired = true,
                }
            },
        })
    elseif Config.Menu == 'ox' then
        dialog = lib.inputDialog(_U('SELL_DIALOG_TITLE', displayLabel), {
            {
                type = "number",
                label = _U('SELL_DIALOG_AMOUNT'),
                default = "1",
            }
        }, { allowCancel = true })
    end

    if dialog then
        local amount

        if Config.Menu == 'qb' then
            amount = tonumber(dialog.amount)
        elseif Config.Menu == 'ox' then
            amount = tonumber(dialog[1])
        end

        if amount and amount >= 1 then
            local sellText = _U('SELLING_PROGRESS', displayLabel)
            if Config.Menu == 'qb' then
                QBCore.Functions.Progressbar('Selling', sellText, Config.SellProgress, false, true, {
                    disableMovement = true,
                    disableCarMovement = true,
                    disableMouse = false,
                    disableCombat = true,
                }, {
                    animDict = Config.SellingAnimDict,
                    anim = Config.SellingAnimName,
                    flags = 1,
                }, {}, {},
                function()
                    TriggerServerEvent('farming:sellFruit', fruit, amount)
                end)
            elseif Config.Menu == 'ox' then
                lib.progressCircle({
                    duration = Config.SellProgress,
                    label = sellText,
                    canCancel = false,
                    position = 'bottom',
                    disable = {
                        car = true,
                        move = true,
                        combat = true,
                        sprint = true,
                    },
                    anim = {
                        dict = Config.SellingAnimDict,
                        clip = Config.SellingAnimName
                    },
                })
                TriggerServerEvent('farming:sellFruit', fruit, amount)
            end
        else
            if Config.Notify == 'qb' then
                QBCore.Functions.Notify(_U('NTF_INVALID_AMOUNT_D'), 'error')
            elseif Config.Notify == 'ox' then
                lib.notify({
                    title = _U('NTF_INVALID_AMOUNT_T'),
                    description = _U('NTF_INVALID_AMOUNT_D'),
                    type = 'error'
                })
            end
        end
    else
        if Config.Notify == 'qb' then
            QBCore.Functions.Notify(_U('NTF_SALE_CANCELED_D'), 'error')
        elseif Config.Notify == 'ox' then
            lib.notify({
                title = _U('NTF_SALE_CANCELED_T'),
                description = _U('NTF_SALE_CANCELED_D'),
                type = 'error'
            })
        end
    end
end)
