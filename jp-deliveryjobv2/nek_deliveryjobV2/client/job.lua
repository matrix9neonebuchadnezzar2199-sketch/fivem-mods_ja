-- ============================================================
-- nek_deliveryjobV2 (日本語版) - 配達ジョブ コアロジック
-- 配達のフロー：
--   1. NPC（本部受付）と対話 → メニュー表示
--   2. 業務開始 → 車両スポーン、荷物プロップ生成
--   3. 荷物を拾う → トラックに積み込む
--   4. 各配達ポイントへ移動 → 荷物を取り出す → 配達
--   5. 全配達完了後、本部に帰還 → 車両返却 → 報酬受領
-- ============================================================

-- ルート構造の正規化（旧形式: vec3 の配列のみ / 新形式: { name, stops } 両対応）
local function NormalizeDeliveryRoutes()
    for i, route in ipairs(Config['Delivery']['Routes']) do
        if route.stops == nil then
            Config['Delivery']['Routes'][i] = {
                name = string.format("ルート %d", i),
                stops = route
            }
        end
    end
end

Delivery.Functions.StopJob = function()
    -- 業務終了をログに記録し、後片付けを行う
    Bridge.TriggerCallback('nek_delivery:wb', function() end, Config['Locales']['job_finished'],
        Config['Locales']['job_title_finished'], 15158332)
    Delivery.State.inJob = false
    Delivery.State.haveBox = false
    Delivery.State.blipStatus = 'delete'
    if Delivery.State.dest_blip then
        RemoveBlip(Delivery.State.dest_blip)
    end
    Delivery.State.inAnim = false
    ClearPedTasksImmediately(PlayerPedId())
    DeleteObject(Delivery.State.entity)
    DeleteVehicle(Delivery.State.vehicle)

    -- ゾーンがあれば削除する
    if Delivery.State.deliveryZoneId then
        exports.ox_target:removeZone(Delivery.State.deliveryZoneId)
        Delivery.State.deliveryZoneId = nil
    end
    if Delivery.State.returnZoneId then
        exports.ox_target:removeZone(Delivery.State.returnZoneId)
        Delivery.State.returnZoneId = nil
    end
    SendNUIMessage({ action = 'CLOSE_UI' })
end

Delivery.Functions.GetBox = function()
    -- 荷物を拾うためのターゲットをプロップに作成
    exports.ox_target:addLocalEntity(Delivery.State.entity, {
        {
            name = 'delivery_get_box',
            icon = 'fas fa-box',
            label = Config['Locales']['box_target_label'],
            distance = 2.0,
            onSelect = function()
                ClearPedTasksImmediately(PlayerPedId())
                -- 荷物を抱えるアニメーションを再生
                TaskPlayAnim(PlayerPedId(), 'anim@heists@box_carry@', "idle", 8.0, 8.0, -1, 50, 0, false, false, false)
                AttachEntityToEntity(Delivery.State.entity, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 57005), 0.05,
                    0.1, -0.3, 300.0, 250.0, 20.0, true, true, false, true, 1, true)
                Delivery.State.haveBox = true
                exports.ox_target:removeLocalEntity(Delivery.State.entity, 'delivery_get_box')
                Wait(200)
                -- 車両への積み込みを促す
                Delivery.Functions.PutBoxInVehicle()
            end
        }
    })
    Delivery.Functions.ShowNotification(Config.Locales['get_box_notify'])
end

Delivery.Functions.PutBoxInVehicle = function()
    Delivery.Functions.ShowNotification(Config.Locales['put_box_notify'])
    -- 車両に荷物を積み込むためのターゲット
    exports.ox_target:addLocalEntity(Delivery.State.vehicle, {
        {
            name = 'delivery_put_box',
            icon = 'fas fa-truck-loading',
            label = Config.Locales['put_box_label'],
            bones = { 'boot', 'door_dside_r', 'door_pside_r' },
            distance = 2.0,
            onSelect = function()
                if Delivery.State.haveBox then
                    DeleteObject(Delivery.State.entity)
                    SetVehicleDoorsShut(Delivery.State.vehicle, false)
                    ClearPedTasksImmediately(PlayerPedId())
                    Delivery.State.haveBox = false
                    Delivery.State.gotoPoint = true
                    exports.ox_target:removeLocalEntity(Delivery.State.vehicle, 'delivery_put_box')
                    -- 次の配達ポイントへルートを設定
                    Delivery.Functions.NextStop()
                end
            end
        }
    })
end

Delivery.Functions.GetClosestVehicle = function()
    CreateThread(function()
        Wait(1000)
        -- 業務中、車両への接近を常時監視するループ
        while Delivery.State.gotoPoint and Delivery.State.inJob and not Delivery.State.getBox do
            local px, py, pz = table.unpack(GetEntityCoords(PlayerPedId()))
            Delivery.State.vehicle2 = Bridge.GetClosestVehicle(vec3(px, py, pz))
            Wait(2000)
        end
    end)
end

Delivery.Functions.NextStop = function()
    if not Delivery.State.inJob then return end

    if Delivery.State.deliveryZoneId then
        exports.ox_target:removeZone(Delivery.State.deliveryZoneId)
        Delivery.State.deliveryZoneId = nil
    end

    local routeData = Config['Delivery']['Routes'][Delivery.State.currentRoute]
    if Delivery.State.currentStop > #routeData.stops then
        Delivery.Functions.ShowNotification(Config.Locales['route_finished'])
        Bridge.TriggerCallback('nek_delivery:wb', function() end, Config.Locales['route_finished_log'],
            Config.Locales['route_completed'], 3447003)
        SendNUIMessage({
            action = 'ADD_RETURN_STOP'
        })
        Delivery.Functions.ComeBack()
        return
    end

    local destination = routeData.stops[Delivery.State.currentStop]
    Delivery.Functions.SetBlipRoutes(destination.x, destination.y, destination.z, 1, 27)
    Delivery.Functions.ShowNotification(Config.Locales['next_point'])

    CreateThread(function()
        local myStop = Delivery.State.currentStop
        while Delivery.State.inJob and Delivery.State.currentStop == myStop do
            local dist = #(GetEntityCoords(PlayerPedId()) - vec3(destination.x, destination.y, destination.z))
            if dist < 100.0 then
                DrawMarker(1, destination.x, destination.y, destination.z - 1.0, 0, 0, 0, 0, 0, 0, 5.0, 5.0, 2.0, 255,
                    165, 0, 150, false, true, 2, false, false, false, false)
            end
            Wait(0)
        end
    end)

    Delivery.State.deliveryZoneId = exports.ox_target:addSphereZone({
        coords = destination,
        radius = 1.5,
        debug = false,
        options = {
            {
                name = 'delivery_drop_package',
                icon = 'fas fa-box',
                label = Config.Locales['deliver_package_label'],
                canInteract = function()
                    return Delivery.State.getBox
                end,
                onSelect = function()
                    ClearPedTasksImmediately(PlayerPedId())
                    DeleteObject(Delivery.State.entity)
                    Wait(500)
                    RemoveBlip(Delivery.State.dest_blip)
                    TaskStartScenarioInPlace(PlayerPedId(), "CODE_HUMAN_MEDIC_TEND_TO_DEAD", 0, true)
                    Wait(2000)
                    ClearPedTasks(PlayerPedId())
                    Wait(1000)
                    Delivery.State.entity = CreateObject(Config['Delivery']['Prop']['Model'],
                        vec3(destination.x, destination.y, destination.z + 0.2), true, false, false)
                    PlaceObjectOnGroundProperly(Delivery.State.entity)
                    Delivery.State.getBox = false
                    SendNUIMessage({
                        action = 'UPDATE_STOP',
                        index = Delivery.State.currentStop
                    })
                    Delivery.State.currentStop = Delivery.State.currentStop + 1
                    Delivery.Functions.NextStop()
                end
            }
        }
    })

    exports.ox_target:addLocalEntity(Delivery.State.vehicle, {
        {
            name = 'delivery_take_package',
            icon = 'fas fa-box-open',
            label = Config.Locales['take_package_label'],
            bones = { 'boot', 'door_dside_r', 'door_pside_r' },
            distance = 2.0,
            canInteract = function(entity, distance, coords, name, bone)
                return not Delivery.State.getBox and Delivery.State.inJob and
                    #(GetEntityCoords(PlayerPedId()) - destination) < 50.0
            end,
            onSelect = function()
                TaskStartScenarioInPlace(PlayerPedId(), "PROP_HUMAN_BUM_BIN", 0, true)
                SetVehicleDoorOpen(Delivery.State.vehicle, 3, false, true)
                Wait(250)
                SetVehicleDoorOpen(Delivery.State.vehicle, 2, false, true)
                Wait(2000)
                ClearPedTasks(PlayerPedId())
                Wait(1000)
                Delivery.State.entity = CreateObject(Config['Delivery']['Prop']['Model'], GetEntityCoords(PlayerPedId()),
                    true, false, false)
                Wait(150)
                SetVehicleDoorsShut(Delivery.State.vehicle, false)
                ClearPedTasksImmediately(PlayerPedId())
                Wait(250)
                TaskPlayAnim(PlayerPedId(), 'anim@heists@box_carry@', "idle", 8.0, 8.0, -1, 50, 0, false, false, false)
                AttachEntityToEntity(Delivery.State.entity, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 57005), 0.05,
                    0.1, -0.3, 300.0, 250.0, 20.0, true, true, false, true, 1, true)
                Delivery.State.getBox = true
                exports.ox_target:removeLocalEntity(Delivery.State.vehicle, 'delivery_take_package')
            end
        }
    })
end

Delivery.Functions.ComeBack = function()
    if Delivery.State.deliveryZoneId then
        exports.ox_target:removeZone(Delivery.State.deliveryZoneId)
        Delivery.State.deliveryZoneId = nil
    end
    Delivery.Functions.SetBlipRoutes(Config['Delivery']['Vehicles']['Deleter']['x'],
        Config['Delivery']['Vehicles']['Deleter']['y'], Config['Delivery']['Vehicles']['Deleter']['z'], 1, 27)

    CreateThread(function()
        while Delivery.State.inJob and Delivery.State.returnZoneId do
            local deleteCoords = Config['Delivery']['Vehicles']['Deleter']
            local dist = #(GetEntityCoords(PlayerPedId()) - deleteCoords)
            if dist < 100.0 then
                DrawMarker(1, deleteCoords.x, deleteCoords.y, deleteCoords.z - 1.0, 0, 0, 0, 0, 0, 0, 5.0, 5.0, 2.0, 255,
                    165, 0, 150, false, true, 2, false, false, false, false)
            end
            Wait(0)
        end
    end)

    Delivery.State.returnZoneId = exports.ox_target:addSphereZone({
        coords = Config['Delivery']['Vehicles']['Deleter'],
        radius = 3.0,
        debug = false,
        options = {
            {
                name = 'delivery_return_vehicle',
                icon = 'fas fa-check',
                label = Config.Locales['return_vehicle_label'],
                canInteract = function()
                    return Delivery.State.inJob and
                        #(GetEntityCoords(PlayerPedId()) - Config['Delivery']['Vehicles']['Deleter']) < 5.0
                end,
                onSelect = function()
                    local v = Delivery.State.vehicle
                    TaskLeaveVehicle(PlayerPedId(), v)
                    Wait(2500)
                    NetworkFadeOutEntity(v, true, false)
                    Wait(2000)
                    DeleteVehicle(v)
                    DeleteObject(Delivery.State.entity)
                    Delivery.Functions.Pay()
                    Delivery.State.blipStatus = 'delete'
                    if Delivery.State.dest_blip then
                        RemoveBlip(Delivery.State.dest_blip)
                    end
                    Delivery.State.comeBack = false
                    Delivery.State.inJob = false
                    if Delivery.State.returnZoneId then
                        exports.ox_target:removeZone(Delivery.State.returnZoneId)
                        Delivery.State.returnZoneId = nil
                    end
                    SendNUIMessage({ action = 'CLOSE_UI' })
                end
            }
        }
    })
end

Delivery.Functions.Pay = function()
    -- サーバーに報酬支払いを依頼する
    Bridge.TriggerCallback('nek_delivery:pay', function() end)
end

Delivery.Functions.StartJob = function()
    -- 業務開始時の初期ログを送信
    Bridge.TriggerCallback('nek_delivery:wb', function() end, Config.Locales['job_started_log'],
        Config.Locales['job_started_title'], 3066993)

    if #Config['Delivery']['Routes'] == 0 then
        Delivery.Functions.ShowNotification(Config.Locales['no_routes'])
        return
    end

    NormalizeDeliveryRoutes()

    local random = math.random(1, #Config['Delivery']['Vehicles']['Cars'])

    -- 荷物運搬アニメーション辞書を読み込み
    if not HasAnimDictLoaded("anim@heists@box_carry@") then
        RequestAnimDict("anim@heists@box_carry@")
        while not HasAnimDictLoaded("anim@heists@box_carry@") do
            Citizen.Wait(0)
        end
    end

    -- 荷物プロップモデルを読み込み
    if not HasModelLoaded(Config['Delivery']['Prop']['Model']) then
        RequestModel(Config['Delivery']['Prop']['Model'])
        while not HasModelLoaded(Config['Delivery']['Prop']['Model']) do
            Citizen.Wait(0)
        end
    end

    for k, v in pairs(Config['Delivery']['Vehicles']['Spawner']['coords']) do
        local vehicles = lib.getNearbyVehicles(v, 2, true)

        if #vehicles == 0 then
            -- 配達車両をスポーン
            local model = joaat(Config['Delivery']['Vehicles']['Cars'][random])
            if not HasModelLoaded(model) then
                RequestModel(model)
                while not HasModelLoaded(model) do
                    Wait(0)
                end
            end

            Delivery.State.vehicle = CreateVehicle(model, v.x, v.y, v.z,
                Config['Delivery']['Vehicles']['Spawner']['rotation'], true, false)
            SetVehicleNumberPlateText(Delivery.State.vehicle, Config['Delivery']['Vehicles']['Plate'])
            -- リアル感のためにドアを開ける
            SetVehicleDoorOpen(Delivery.State.vehicle, 3, false, false)
            SetVehicleDoorOpen(Delivery.State.vehicle, 2, false, false)
            SetVehicleDoorsLocked(Delivery.State.vehicle, 0)
            SetModelAsNoLongerNeeded(model)

            -- ジョブ状態を初期化
            Delivery.State.inJob = true
            Delivery.State.inAnim = true
            Delivery.State.currentRoute = math.random(1, #Config['Delivery']['Routes'])
            Delivery.State.currentStop = 1
            local routeData = Config['Delivery']['Routes'][Delivery.State.currentRoute]
            SendNUIMessage({
                action = 'START_ROUTE',
                amount = #routeData.stops,
                routeName = routeData.name or ("ルート " .. tostring(Delivery.State.currentRoute))
            })
            Delivery.Functions.NextStop()
        else
            Delivery.State.inAnim = false
            Delivery.Functions.ShowNotification(Config.Locales['no_spawn_point'])
        end

        if Delivery.State.inAnim then
            -- 開始時の初期プロップを作成
            Delivery.State.entity = CreateObject(Config['Delivery']['Prop']['Model'], Config['Delivery']['Prop']['x'],
                Config['Delivery']['Prop']['y'], Config['Delivery']['Prop']['z'], true, false, false)
            Delivery.Functions.GetBox()
            Delivery.State.haveBox = false
        else
            Delivery.Functions.ShowNotification(Config.Locales['error_starting'])
        end
    end
end

Delivery.Functions.RegisterMenu = function()
    lib.registerContext({
        id = 'delivery_job_menu',
        title = Config.Locales['menu_title'],
        options = {
            {
                title = Config.Locales['menu_start_title'],
                description = Config.Locales['menu_start_desc'],
                icon = 'truck-loading',
                onSelect = function()
                    Delivery.Functions.StartJob()
                end,
                disabled = Delivery.State.inJob
            },
            {
                title = Config.Locales['menu_stop_title'],
                description = Config.Locales['menu_stop_desc'],
                icon = 'truck-loading',
                onSelect = function()
                    Delivery.Functions.StopJob()
                end,
                disabled = not Delivery.State.inJob
            }
        }
    })
end

Delivery.Functions.StartThread = function()
    CreateThread(function()
        for k, v in pairs(Config['Delivery']['Base']) do
            local model = joaat(v['model'])
            lib.requestModel(model)
            -- 業務開始用NPCをスポーン
            local ped = CreatePed(4, model, v['coords'].x, v['coords'].y, v['coords'].z - 1.0, v['coords'].w, false, true)

            SetEntityInvincible(ped, true)
            FreezeEntityPosition(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            TaskStartScenarioInPlace(ped, "WORLD_HUMAN_CLIPBOARD", 0, true)

            -- NPCにターゲット操作を追加
            exports.ox_target:addLocalEntity(ped, {
                {
                    name = 'delivery_job_menu',
                    icon = 'fas fa-truck-loading',
                    label = Config.Locales['open_menu_label'],
                    canInteract = function()
                        -- ジョブ制限が有効かをチェック
                        if Config['JobName'] and Config['JobName'] ~= false then
                            if not Delivery.State.PlayerData or not Delivery.State.PlayerData.job or Delivery.State.PlayerData.job.name ~= Config['JobName'] then
                                return false
                            end
                        end
                        return true
                    end,
                    onSelect = function()
                        Delivery.Functions.RegisterMenu()
                        lib.showContext('delivery_job_menu')
                    end
                }
            })
        end
    end)
end
