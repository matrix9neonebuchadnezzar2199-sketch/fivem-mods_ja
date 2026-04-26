local isPlaying = false
local lastDrawTime = 0
local machineProps = {}
local esxObj, qbObj = nil, nil

CreateThread(function()
    pcall(function()
        esxObj = exports['es_extended']:getSharedObject()
    end)
    if not esxObj then
        pcall(function()
            qbObj = exports['qb-core']:GetCoreObject()
        end)
    end
end)

-- 各環境用の短い通知
local function notify(msg)
    if qbObj then
        qbObj.Functions.Notify(msg, 'error', 3000)
    elseif esxObj then
        esxObj.ShowNotification(msg)
    else
        TriggerEvent('chat:addMessage', {
            color = { 255, 100, 100 },
            args = { "ガチャ", msg },
        })
    end
end

-- 各マシン: ブリップ＋代用プロップ
CreateThread(function()
    for i, machine in ipairs(Config.Machines) do
        local b = AddBlipForCoord(machine.coords.x, machine.coords.y, machine.coords.z)
        SetBlipSprite(b, Config.Blip.sprite)
        SetBlipDisplay(b, 4)
        SetBlipScale(b, Config.Blip.scale)
        SetBlipColour(b, Config.Blip.color)
        SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(Config.Blip.label)
        EndTextCommandSetBlipName(b)

        -- machine.png は NUI 専用。プロップは重そうな筐体系
        local modelHash = `prop_weighstation_02`
        RequestModel(modelHash)
        local t = 0
        while not HasModelLoaded(modelHash) and t < 200 do
            Wait(100)
            t = t + 1
        end
        if not HasModelLoaded(modelHash) then
            if Config.Debug then
                print('[jp-gacha] モデル読み込み失敗: ' .. tostring(modelHash))
            end
        else
            local prop = CreateObject(modelHash, machine.coords.x, machine.coords.y, machine.coords.z, false, false, false)
            SetEntityHeading(prop, machine.heading)
            FreezeEntityPosition(prop, true)
            SetEntityInvincible(prop, true)
            machineProps[i] = prop
            SetModelAsNoLongerNeeded(modelHash)
        end
    end
end)

-- 近接時ヘルプと E
CreateThread(function()
    while true do
        local sleep = 1000
        local pcoords = GetEntityCoords(PlayerPedId())
        for _, machine in ipairs(Config.Machines) do
            local dist = #(pcoords - machine.coords)
            if dist < Config.InteractDistance + 2.0 then
                sleep = 0
            end
            if dist < Config.InteractDistance then
                BeginTextCommandDisplayHelp("STRING")
                if Config.Cost > 0 then
                    AddTextComponentSubstringPlayerName(("~INPUT_CONTEXT~ ガチャを回す ($%d)"):format(Config.Cost))
                else
                    AddTextComponentSubstringPlayerName("~INPUT_CONTEXT~ ガチャを回す")
                end
                EndTextCommandDisplayHelp(0, false, true, -1)

                if IsControlJustReleased(0, 38) and not isPlaying then
                    local now = GetGameTimer()
                    if (now - lastDrawTime) / 1000 < Config.Cooldown then
                        notify("少し待ってください")
                    else
                        isPlaying = true
                        lastDrawTime = now
                        TriggerServerEvent('jp-gacha:requestDraw')
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

RegisterNetEvent('jp-gacha:drawResult', function(data)
    SetNuiFocus(true, false)
    SendNUIMessage({
        type = 'startGacha',
        rarity = data.rarityId,
        rarityName = data.rarityName,
        rarityColor = data.rarityColor,
        capsule = data.capsule,
        bg = data.bg,
        cutin = data.cutin,
        itemName = data.itemName,
        itemImage = data.itemImage,
        timing = Config.Timing,
    })

    SetTimeout(Config.Timing.totalDuration + 500, function()
        SetNuiFocus(false, false)
        isPlaying = false
    end)
end)

RegisterNetEvent('jp-gacha:drawDenied', function(reason)
    isPlaying = false
    if reason == 'nomoney' then
        lastDrawTime = 0
    end
    if reason == 'cooldown' then
        notify("少し待ってください")
    elseif reason == 'nomoney' then
        notify("お金が足りません")
    end
end)

RegisterNUICallback('gachaComplete', function(_, cb)
    SetNuiFocus(false, false)
    isPlaying = false
    cb('ok')
end)
