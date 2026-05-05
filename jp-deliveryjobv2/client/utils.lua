-- クライアント側 共通ユーティリティ関数（日本語版）

-- 通知を表示する
Delivery.Functions.ShowNotification = function(msg, type)
    if not type then type = 'inform' end
    lib.notify({
        title = Config.Locales['notify_title'] or "配達",
        description = msg,
        type = type
    })
end

-- 目的地ブリップを設定する（GPSルート付き）
Delivery.Functions.SetBlipRoutes = function(x, y, z, sprite, colour)
    if Delivery.State.dest_blip then
        RemoveBlip(Delivery.State.dest_blip)
    end
    Delivery.State.dest_blip = AddBlipForCoord(x, y, z)
    SetBlipSprite(Delivery.State.dest_blip, sprite)
    SetBlipDisplay(Delivery.State.dest_blip, 4)
    SetBlipScale(Delivery.State.dest_blip, 0.70)
    SetBlipColour(Delivery.State.dest_blip, colour)
    SetBlipRoute(Delivery.State.dest_blip, true)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Locales['blip_destination'] or "目的地")
    EndTextCommandSetBlipName(Delivery.State.dest_blip)
end
