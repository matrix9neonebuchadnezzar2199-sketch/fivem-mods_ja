local shared = require 'config.shared'
local ic = shared.icons
local peds = {}
local blips = {}
local cam
local currentBlackmarket
local pickupBlip
local camDuration = 1000

function Create(ped)
    local coords = GetEntityCoords(ped)
    local x, y, z = coords.x + GetEntityForwardX(ped) * 1.0, coords.y + GetEntityForwardY(ped) * 1.0, coords.z + 0.5
    local camRot = GetEntityRotation(ped)
    cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", x, y, z, camRot.x, camRot.y, camRot.z + 180.0, GetGameplayCamFov(), false, 0)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, camDuration, true, true)
    Wait(camDuration)
end

function Destroy()
    RenderScriptCams(false, true, camDuration, true, false)
    DestroyCam(cam, false)
end

function reqModel(model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end
end

function createBlip(data)
    local blip = AddBlipForCoord(data.coords.xyz)
    SetBlipSprite(blip, data.sprite)
    SetBlipColour(blip, data.color)
    SetBlipScale(blip, data.scale)
    SetBlipDisplay(blip, 4)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(data.label)
    EndTextCommandSetBlipName(blip)
    SetBlipAsShortRange(blip, true)
    table.insert(blips, blip)
end

function setupBlackmarkets()
    Wait(1000)
    for k, v in pairs(shared.blackmarkets) do
        reqModel(v.ped.model)
        
        local ped = CreatePed(4, v.ped.model, v.ped.coords.xyzw, false, false)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        table.insert(peds, ped)
        createInteraction(ped, {
            label = translate('openBlackmarket'),
            icon = ic.openBlackmarket,
            distance = 2.0,
            onSelect = function ()
                openBlackmarket(k, ped)
            end
        })
        if v.blip.enabled then
            createBlip({
                coords = v.ped.coords.xyz,
                sprite = v.blip.sprite,
                color = v.blip.color,
                scale = v.blip.scale,
                label = v.blip.label
            })
        end
    end

    for _, v in ipairs(shared.pickupLocations) do
        reqModel(v.model)
        local ped = CreatePed(4, v.model, v.coords.xyzw, false, false)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        table.insert(peds, ped)
        createInteraction(ped, {
            label = translate('pickupItems'),
            icon = ic.pickupItems,
            distance = 2.0,
            onSelect = function ()
                pickupItems(v.id, ped)
            end
        })
    end
end

function openBlackmarket(blackmarket, ped)
    local b = shared.blackmarkets[blackmarket]
    if not b then return end
    local playerLevel, playerXp = lib.callback.await('matkez_blackmarket:server:getPlayerLevel', false, blackmarket)
    local prices = lib.callback.await('matkez_blackmarket:server:getBlackmarketPrices', false, blackmarket)
    local nextXp = shared.levels[playerLevel + 1] or playerXp
    local items = {}
    for i = 1, #b.items do
        local v = b.items[i]
        local item = exports.ox_inventory:Items(v.name)
        table.insert(items, {
            image = ('nui://ox_inventory/web/images/%s.png'):format(v.name),
            price = prices[v.name],
            label = item.label or v.name,
            hasLevel = playerLevel >= v.minLevel and true or false,
            name = v.name
        })
    end

    currentBlackmarket = blackmarket

    Create(ped)

    SendNUIMessage({
        event = 'show',
        label = b.label,
        items = items,
        level = playerLevel,
        xp = playerXp,
        nextXp = nextXp,
        currencyItem = b.currencyItem,
        currencyImg = ('nui://ox_inventory/web/images/%s.png'):format(b.currencyItem),
        useLevels = shared.useLevels
    })
    SetNuiFocus(true, true)
    SetEntityAlpha(cache.ped, 0, true)
end

function createRoute(coords)
    local c = shared.pickupRoute
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, c.sprite)
    SetBlipColour(blip, c.color)
    SetBlipScale(blip, c.scale)
    SetBlipRoute(blip, true)
    SetBlipRouteColour(blip, c.color)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(c.label)
    EndTextCommandSetBlipName(blip)
    pickupBlip = blip
end
RegisterNetEvent('matkez_blackmarket:client:createRoute', createRoute)

function pickupItems(id, ped)
    local pickup = lib.callback.await('matkez_blackmarket:server:pickupItems', false, id)
    if not pickup then return end
    RequestAnimDict('mp_common')
    while not HasAnimDictLoaded('mp_common') do
        Wait(10)
    end
    TaskPlayAnim(ped, 'mp_common', 'givetake1_a', 1.0, 1.0, 2000, 9, 0.0, 0, 0, 0)
    TaskPlayAnim(cache.ped, 'mp_common', 'givetake1_a', 1.0, 1.0, 2000, 9, 0.0, 0, 0, 0)
    RemoveBlip(pickupBlip)
end

RegisterNUICallback('close', function (body, r)
    SetNuiFocus(false, false)
    Destroy()
    currentBlackmarket = nil
    ResetEntityAlpha(cache.ped)
    r(true)
end)

RegisterNUICallback('order', function (body, r)
    if not currentBlackmarket then return r(false) end
    local orderResp = lib.callback.await('matkez_blackmarket:server:order', false, currentBlackmarket, body.items)
    r(orderResp)
end)

AddEventHandler('onResourceStart', function(r)
    if GetCurrentResourceName() ~= r then return false end
    setupBlackmarkets()
end)

AddEventHandler('onResourceStop', function(r)
    if GetCurrentResourceName() ~= r then return false end
    for i = 1, #peds do
        DeleteEntity(peds[i])
    end
    for i = 1, #blips do
        RemoveBlip(blips[i])
    end
    RemoveBlip(pickupBlip)
    ResetEntityAlpha(PlayerPedId())
end)