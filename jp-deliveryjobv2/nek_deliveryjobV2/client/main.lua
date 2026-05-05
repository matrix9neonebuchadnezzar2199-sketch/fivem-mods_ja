-- 配達ジョブ クライアント メインループ（日本語版）

CreateThread(function()
    Wait(3000)

    -- プレイヤーデータの読み込みを待つ
    while Delivery.State.PlayerData == nil do
        Delivery.State.PlayerData = Bridge.GetPlayerData()
        Wait(500)
    end

    Wait(1000)

    -- 設定されたブリップをマップに表示
    for k, v in pairs(Config['Delivery']['Blips']) do
        local blip = AddBlipForCoord(v['x'], v['y'], v['z'])
        SetBlipSprite(blip, v['sprite'])
        SetBlipScale(blip, v['scale'])
        SetBlipAsShortRange(blip, true)

        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(v['label'])
        EndTextCommandSetBlipName(blip)
    end

    -- 業務開始NPCを生成
    Delivery.Functions.StartThread()
end)

-- ESX: ジョブ更新検知
RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    Delivery.State.PlayerData = Bridge.GetPlayerData()
    if Delivery.State.PlayerData then
        Delivery.State.PlayerData.job = job
    end
end)

-- QBCore: ジョブ更新検知
RegisterNetEvent('QBCore:Client:OnJobUpdate')
AddEventHandler('QBCore:Client:OnJobUpdate', function(JobInfo)
    Delivery.State.PlayerData = Bridge.GetPlayerData()
    if Delivery.State.PlayerData then
        Delivery.State.PlayerData.job = JobInfo
    end
end)
