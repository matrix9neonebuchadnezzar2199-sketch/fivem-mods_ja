-- 配達ジョブ サーバーメインロジック（日本語版）

local ActiveWorkers = {}

-- 業務開始/終了をログに記録し、稼働中ワーカーリストを更新
lib.callback.register('nek_delivery:wb', function(source, action, title, color)
    local _title = title or Config.Locales['log_title']
    local _color = color or 3447003
    Delivery.Functions.SendWB(_title, action, _color, source)

    -- ログのタイトルから稼働状態を直接同期
    if title == Config.Locales['job_started_title'] then
        ActiveWorkers[source] = true
    elseif title == Config.Locales['job_title_finished'] then
        ActiveWorkers[source] = nil
    end
end)

-- 報酬支払い処理
lib.callback.register('nek_delivery:pay', function(source)
    local player = Bridge.GetPlayer(source)
    if not player then return end

    local quantity = math.random(Config['Delivery']['FinalPayout']['Min'], Config['Delivery']['FinalPayout']['Max'])

    -- セキュリティチェック：上限額を超えないことを確認
    if quantity > Config['Delivery']['FinalPayout']['Max'] then
        Delivery.Functions.SendWB(Config.Locales['security_alert'],
            string.format(Config.Locales['money_limit_alert'], quantity), 15158332, source)
    else
        player.addMoney(quantity)
        Bridge.Notify(source, string.format(Config.Locales['payment_received'], quantity))
        Delivery.Functions.SendWB(Config.Locales['payment_log_title'],
            string.format(Config.Locales['payment_log_desc'], quantity), 3066993, source)
    end
end)

-- 他のリソースから稼働中プレイヤー一覧を取得するためのexport
exports('GetActiveWorkers', function()
    local workers = {}
    for src, _ in pairs(ActiveWorkers) do
        local player = Bridge.GetPlayer(src)
        if player then
            table.insert(workers, {
                source = src,
                name = player.getName(),
                identifier = player.identifier
            })
        else
            -- プレイヤーがnilの場合は古いエントリをクリーンアップ
            ActiveWorkers[src] = nil
        end
    end
    return workers
end)

-- 特定プレイヤーが稼働中か判定するexport
exports('IsPlayerWorking', function(source)
    return ActiveWorkers[source] == true
end)

-- プレイヤー切断時のクリーンアップ
AddEventHandler('playerDropped', function()
    local src = source
    if ActiveWorkers[src] then
        ActiveWorkers[src] = nil
    end
end)

-- バージョンチェッカー
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        function checkVersion(error, latestVersion, headers)
            local currentVersion = Config['Version']
            local name = "[^4nek_deliveryV2_jp^7]"
            Citizen.Wait(2000)

            if tonumber(currentVersion) < tonumber(latestVersion) then
                print(name ..
                    " ^1は最新ではありません。\n現在のバージョン: ^8" ..
                    currentVersion ..
                    "\n最新のバージョン: ^2" ..
                    latestVersion .. "\n^3更新先^7: https://github.com/TtvNekix/nekix_deliveryV2")
            else
                print(name .. " ^2は最新版です。^7")
            end
        end

        function checkUpdates(error2, update, headers2)
            local updates = update
            local name = "[^4nek_deliveryV2_jp^7]"
            Citizen.Wait(2000)

            if update then
                print(name .. " 最新の更新内容 \n [\n" .. tostring(updates) .. "\n]")
            end
        end

        PerformHttpRequest("https://raw.githubusercontent.com/TtvNekix/deliveryv2Checker/main/version", checkVersion,
            "GET")
        PerformHttpRequest("https://raw.githubusercontent.com/TtvNekix/deliveryv2Checker/main/last-updates", checkUpdates,
            "GET")
    end
end)
