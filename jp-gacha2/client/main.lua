local isPlaying = false
-- メニュー／数入力NUI表示中。isPlaying だけだと未抽選の間攻撃不可にならない
local nuiMenuOrInputOpen = false
local lastGachaMenu = nil
local gachaCountInput = false
local lastDrawTime = 0
local machineProps = {}
local ESX, QBCore = nil, nil

Citizen.CreateThread(function()
    local success = pcall(function()
        ESX = exports['es_extended']:getSharedObject()
    end)
    if not success then
        pcall(function()
            QBCore = exports['qb-core']:GetCoreObject()
        end)
    end
end)

local function Notify(msg)
    if QBCore then
        QBCore.Functions.Notify(msg, 'error', 3000)
    elseif ESX then
        ESX.ShowNotification(msg)
    else
        TriggerEvent('chat:addMessage', {
            color = { 255, 100, 100 },
            args = { "ガチャ", msg }
        })
    end
end

local function DrawGroundCylinderMarker(pos, rgb)
    local markerZ = pos.z + 0.05
    local ok, groundZ = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + 1.0, false)
    if ok then
        markerZ = groundZ + 0.05
    end
    DrawMarker(
        1,
        pos.x, pos.y, markerZ,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        0.6, 0.6, 0.3,
        rgb[1], rgb[2], rgb[3], 200,
        false, true, 2, false, nil, nil, false
    )
end

function StartGachaPull(count)
    if isPlaying then
        return
    end
    local now = GetGameTimer()
    if (now - lastDrawTime) / 1000 < Config.Cooldown then
        Notify("少し待ってください")
        return
    end
    isPlaying = true
    lastDrawTime = now
    TriggerServerEvent('jp-gacha:requestMultiDraw', count)
end

-- ガチャメニュー: サーバーに景品表を取りに行き NUI へ
local function ShowGachaMenu()
    if isPlaying then
        return
    end
    TriggerServerEvent('jp-gacha:requestGachaMenuData')
end

RegisterNUICallback('menuSelect', function(data, cb)
    local selected = data and data.value
    if selected == 'custom' then
        cb('ok')
        nuiMenuOrInputOpen = true
        gachaCountInput = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            type = 'showInput',
            title = '回数を入力（1〜' .. Config.MaxPullCount .. '）',
            max = Config.MaxPullCount,
            scale = Config.UIScale,
            fromGacha = true
        })
        return
    end
    SetNuiFocus(false, false)
    cb('ok')
    nuiMenuOrInputOpen = false
    local count = math.floor(tonumber(selected) or 0)
    if count > 0 then
        StartGachaPull(count)
    end
end)

RegisterNUICallback('inputSubmit', function(data, cb)
    gachaCountInput = false
    SetNuiFocus(false, false)
    nuiMenuOrInputOpen = false
    cb('ok')
    local count = tonumber(data and data.count)
    if count and count >= 1 and count <= Config.MaxPullCount then
        StartGachaPull(math.floor(count))
    else
        Notify('1〜' .. Config.MaxPullCount .. 'の数字を入力してください')
    end
end)

RegisterNUICallback('gachaInputCancel', function(_, cb)
    gachaCountInput = false
    nuiMenuOrInputOpen = true
    SetNuiFocus(true, true)
    cb('ok')
    if lastGachaMenu then
        lastGachaMenu.gachaReopen = true
        SendNUIMessage({
            type = 'showGachaMenu',
            title = lastGachaMenu.title,
            cost = lastGachaMenu.cost,
            theme = lastGachaMenu.theme,
            items = lastGachaMenu.items,
            themes = lastGachaMenu.themes,
            rarities = lastGachaMenu.rarities,
            maxPull = lastGachaMenu.maxPull,
            scale = lastGachaMenu.scale
        })
    end
end)

RegisterNUICallback('adminSave', function(data, cb)
    TriggerServerEvent('jp-gacha:saveAdminData', data)
    cb('ok')
end)

RegisterNUICallback('adminClose', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNetEvent('jp-gacha:gachaMenuData', function(data)
    if isPlaying or not data then
        return
    end
    lastGachaMenu = data
    nuiMenuOrInputOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'showGachaMenu',
        title = data.title,
        cost = data.cost,
        theme = data.theme,
        items = data.items,
        themes = data.themes,
        rarities = data.rarities,
        maxPull = data.maxPull,
        scale = data.scale or Config.UIScale
    })
end)

RegisterNetEvent('jp-gacha:adminData', function(payload)
    if not payload or not payload.settings or not payload.items then
        return
    end
    nuiMenuOrInputOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'showAdmin',
        settings = payload.settings,
        items = payload.items,
        rarities = payload.rarities or nil,
        scale = Config.UIScale
    })
end)

RegisterNetEvent('jp-gacha:adminSaveResult', function(res)
    SendNUIMessage({
        type = 'adminSaveResult',
        ok = res and res.ok,
        reason = res and res.reason
    })
end)

RegisterCommand(Config.AdminCommand, function()
    TriggerServerEvent('jp-gacha:requestAdminData')
end, false)

RegisterNUICallback('menuClose', function(_, cb)
    SetNuiFocus(false, false)
    nuiMenuOrInputOpen = false
    cb('ok')
end)

-- マシン設置 & Blip
Citizen.CreateThread(function()
    for i, machine in ipairs(Config.Machines) do
        local blip = AddBlipForCoord(machine.coords.x, machine.coords.y, machine.coords.z)
        SetBlipSprite(blip, Config.Blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.Blip.scale)
        SetBlipColour(blip, Config.Blip.color)
        SetBlipAsShortRange(blip, false)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(Config.Blip.label)
        EndTextCommandSetBlipName(blip)

        local modelName = Config.MachineModel or 'prop_weighstation_02'
        local modelHash = GetHashKey(modelName)
        RequestModel(modelHash)
        local timeout = 0
        while not HasModelLoaded(modelHash) and timeout < 50 do
            Wait(100)
            timeout = timeout + 1
        end

        if HasModelLoaded(modelHash) then
            local prop = CreateObject(modelHash, machine.coords.x, machine.coords.y, machine.coords.z, false, false, false)
            if prop and prop ~= 0 then
                SetEntityHeading(prop, machine.heading)
                FreezeEntityPosition(prop, true)
                SetEntityInvincible(prop, true)
                machineProps[i] = prop
            end
            SetModelAsNoLongerNeeded(modelHash)
        elseif Config.Debug then
            print(('[jp-gacha] Failed to load model for machine %d (%s)'):format(i, modelName))
        end
    end
end)

-- インタラクション
Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        local playerCoords = GetEntityCoords(PlayerPedId())

        for _, machine in ipairs(Config.Machines) do
            local dx = playerCoords.x - machine.coords.x
            local dy = playerCoords.y - machine.coords.y
            local dist2d = math.sqrt((dx * dx) + (dy * dy))
            if dist2d < 40.0 then
                sleep = 0

                DrawGroundCylinderMarker(machine.coords, { 255, 220, 0 })

                if dist2d < Config.InteractDistance then
                    BeginTextCommandDisplayHelp("STRING")
                    AddTextComponentSubstringPlayerName("~INPUT_CONTEXT~ ガチャを回す")
                    EndTextCommandDisplayHelp(0, false, true, -1)

                    if IsControlJustReleased(0, 38) then
                        ShowGachaMenu()
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

RegisterNetEvent('jp-gacha:multiDrawResult', function(results, count)
    SetNuiFocus(true, false)
    SendNUIMessage({
        type = 'startMultiGacha',
        results = results,
        count = count,
        timing = Config.Timing,
        scale = Config.UIScale
    })
end)

RegisterNetEvent('jp-gacha:drawDenied', function(reason)
    isPlaying = false
    lastDrawTime = 0
    if reason == 'cooldown' then
        Notify("少し待ってください")
    elseif reason == 'nomoney' then
        Notify("お金が足りません")
    elseif reason == 'invalid' then
        Notify("無効な回数です")
    end
end)

-- 演出中の誤入力対策（左クリック連打で殴る/撃つのを防止）
Citizen.CreateThread(function()
    while true do
        if isPlaying or nuiMenuOrInputOpen then
            DisableControlAction(0, 24, true)  -- INPUT_ATTACK
            DisableControlAction(0, 25, true)  -- INPUT_AIM
            DisableControlAction(0, 140, true) -- INPUT_MELEE_ATTACK_LIGHT
            DisableControlAction(0, 141, true) -- INPUT_MELEE_ATTACK_HEAVY
            DisableControlAction(0, 142, true) -- INPUT_MELEE_ATTACK_ALTERNATE
            DisableControlAction(0, 257, true) -- INPUT_ATTACK2
            Wait(0)
        else
            Wait(250)
        end
    end
end)

RegisterNUICallback('gachaComplete', function(_, cb)
    SetNuiFocus(false, false)
    isPlaying = false
    cb('ok')
end)
