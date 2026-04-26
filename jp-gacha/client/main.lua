local isPlaying = false
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

-- メニュー表示
local function ShowGachaMenu()
    if isPlaying then
        return
    end

    local options = {}
    for _, opt in ipairs(Config.MenuOptions) do
        if opt.count == 0 then
            table.insert(options, {
                label = opt.label,
                value = 'custom'
            })
        else
            local cost = Config.Cost * opt.count
            table.insert(options, {
                label = opt.label:format(cost),
                value = opt.count
            })
        end
    end

    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'showMenu',
        title = Config.MenuTitle,
        options = options,
        scale = Config.UIScale
    })
end

RegisterNUICallback('menuSelect', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')

    local selected = data.value
    if selected == 'custom' then
        SetNuiFocus(true, true)
        SendNUIMessage({
            type = 'showInput',
            title = '回数を入力（1〜' .. Config.MaxPullCount .. '）',
            max = Config.MaxPullCount,
            scale = Config.UIScale
        })
    elseif type(selected) == 'number' and selected > 0 then
        StartGachaPull(selected)
    end
end)

RegisterNUICallback('inputSubmit', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')

    local count = tonumber(data.count)
    if count and count >= 1 and count <= Config.MaxPullCount then
        StartGachaPull(math.floor(count))
    else
        Notify('1〜' .. Config.MaxPullCount .. 'の数字を入力してください')
    end
end)

RegisterNUICallback('menuClose', function(_, cb)
    SetNuiFocus(false, false)
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
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(Config.Blip.label)
        EndTextCommandSetBlipName(blip)

        local modelHash = GetHashKey('prop_weighstation_02')
        RequestModel(modelHash)
        local timeout = 0
        while not HasModelLoaded(modelHash) and timeout < 50 do
            Wait(100)
            timeout = timeout + 1
        end
        if HasModelLoaded(modelHash) then
            local prop = CreateObject(modelHash, machine.coords.x, machine.coords.y, machine.coords.z, false, false, false)
            SetEntityHeading(prop, machine.heading)
            FreezeEntityPosition(prop, true)
            SetEntityInvincible(prop, true)
            SetModelAsNoLongerNeeded(modelHash)
            machineProps[i] = prop
        elseif Config.Debug then
            print('[jp-gacha] Failed to load model for machine ' .. i)
        end
    end
end)

-- インタラクション
Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        local playerCoords = GetEntityCoords(PlayerPedId())

        for _, machine in ipairs(Config.Machines) do
            local dist = #(playerCoords - machine.coords)
            if dist < Config.InteractDistance + 2.0 then
                sleep = 0
                if dist < Config.InteractDistance then
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
        scale = Config.UIScale,
        skipEnabled = Config.SkipEnabled
    })
end)

-- スキップ用キー監視
Citizen.CreateThread(function()
    while true do
        if isPlaying and Config.SkipEnabled then
            if IsControlJustPressed(0, Config.SkipKey) then
                SendNUIMessage({ type = 'skipGacha' })
            end
            Wait(0)
        else
            Wait(500)
        end
    end
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

RegisterNUICallback('gachaComplete', function(_, cb)
    SetNuiFocus(false, false)
    isPlaying = false
    cb('ok')
end)
