-- jp-LetterCarrier クライアント

local S = {
    hasJob = false,
    hasCargo = false,
    courseSize = 0,
    total = 0,
    locs = {},
    blips = {},
    depotBlip = nil,
    completed = {},
    totalEarned = 0,
    rewardPer = 0,
    expectedBonus = 0,
    busy = false,
    deliveryVehicle = nil,
    readyToReport = false
}

local JobNpc = {
    ped = nil,
    blip = nil
}

local DELIVERY_MARKER_RADIUS = 60.0
local DELIVERY_USE_RADIUS = 5.0

local function formatMoney(n)
    local s = tostring(math.floor(tonumber(n) or 0))
    local k
    repeat
        s, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
    until k == 0
    return s
end

local function chatInfo(msg)
    TriggerEvent("chat:addMessage", {
        color = { 255, 255, 255 },
        args = { "配達", tostring(msg) }
    })
end

local function clearMapGraphics()
    if S.depotBlip and DoesBlipExist(S.depotBlip) then
        RemoveBlip(S.depotBlip)
    end
    S.depotBlip = nil
    for i, b in pairs(S.blips) do
        if b and DoesBlipExist(b) then
            RemoveBlip(b)
        end
        S.blips[i] = nil
    end
end

local function deleteDeliveryVehicle()
    if S.deliveryVehicle and DoesEntityExist(S.deliveryVehicle) then
        SetEntityAsMissionEntity(S.deliveryVehicle, true, true)
        DeleteVehicle(S.deliveryVehicle)
    end
    S.deliveryVehicle = nil
end

local function resetStateLocal()
    clearMapGraphics()
    deleteDeliveryVehicle()
    S.hasJob = false
    S.hasCargo = false
    S.courseSize = 0
    S.total = 0
    S.locs = {}
    S.completed = {}
    S.totalEarned = 0
    S.rewardPer = 0
    S.expectedBonus = 0
    S.busy = false
    S.readyToReport = false
    ClearGpsPlayerWaypoint()
end

local function progressBlocking(label, sec)
    if sec <= 0 then
        return
    end
    local t0 = GetGameTimer()
    local dur = sec * 1000.0
    while GetGameTimer() - t0 < dur do
        local t = (GetGameTimer() - t0) / dur
        local w = 0.28
        local cx, cy = 0.5, 0.88
        DrawRect(cx, cy, w, 0.022, 0, 0, 0, 200)
        DrawRect(cx - w / 2.0 + w * t * 0.5, cy, math.max(0.002, w * t), 0.018, 233, 69, 96, 230)
        if label and label ~= "" then
            SetTextFont(0)
            SetTextProportional(true)
            SetTextScale(0.0, 0.35)
            SetTextColour(255, 255, 255, 220)
            SetTextCentre(true)
            SetTextDropshadow(0, 0, 0, 0, 0)
            SetTextEdge(1, 0, 0, 0, 255)
            SetTextEntry("STRING")
            SetTextCentre(true)
            AddTextComponentString(label)
            DrawText(0.4, 0.83)
        end
        Wait(0)
    end
end

local function playAnimSeconds(dict, name, sec, flag)
    local ped = PlayerPedId()
    RequestAnimDict(dict)
    local guard = 0
    while not HasAnimDictLoaded(dict) and guard < 200 do
        Wait(10)
        guard = guard + 1
    end
    if not HasAnimDictLoaded(dict) then
        return
    end
    TaskPlayAnim(ped, dict, name, 8.0, -8.0, math.floor(math.max(1, sec) * 1000), flag or 49, 0.0, false, false, false)
end

local function getPedPos()
    return GetEntityCoords(PlayerPedId(), false)
end

local function dist2d(a, b)
    return #(vector3(a.x, a.y, 0) - vector3(b.x, b.y, 0))
end

local function addDepotBlip()
    if S.depotBlip and DoesBlipExist(S.depotBlip) then
        return
    end
    local d = Config.DepotLocation
    S.depotBlip = AddBlipForCoord(d.x, d.y, d.z)
    SetBlipSprite(S.depotBlip, Config.DepotBlipSprite)
    SetBlipDisplay(S.depotBlip, 4)
    SetBlipScale(S.depotBlip, Config.DepotBlipScale)
    SetBlipColour(S.depotBlip, Config.DepotBlipColor)
    SetBlipAsShortRange(S.depotBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("集配所")
    EndTextCommandSetBlipName(S.depotBlip)
    SetBlipRoute(S.depotBlip, true)
    SetNewWaypoint(d.x, d.y)
end

---@param slot number
---@param wantRoute boolean
local function addStopBlip(slot, wantRoute)
    local p = S.locs[slot]
    if not p then
        return
    end
    local b = AddBlipForCoord(p.x, p.y, p.z)
    SetBlipSprite(b, 501)
    SetBlipScale(b, 0.75)
    SetBlipColour(b, 3)
    SetBlipAsShortRange(b, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("配達 " .. tostring(slot))
    EndTextCommandSetBlipName(b)
    if wantRoute then
        SetBlipRoute(b, true)
    end
    S.blips[slot] = b
end

local function drawCylMarker(pos, rgb)
    local markerZ = pos.z + 0.05
    local ok, groundZ = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + 1.0, false)
    if ok then
        markerZ = groundZ + 0.05
    end
    DrawMarker(1, pos.x, pos.y, markerZ, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.6, 0.6, 0.3, rgb[1], rgb[2], rgb[3], 200, false, true, 2, false, nil, nil, false)
end

-- 道路上の座標を避け、近傍の歩道/玄関側に寄せる
local function moveOffRoadPoint(x, y, z)
    if not IsPointOnRoad(x, y, z, PlayerPedId()) then
        return x, y, z
    end
    local bestX, bestY, bestZ = x, y, z
    for r = 2.0, 10.0, 1.5 do
        for a = 0, 330, 30 do
            local rad = math.rad(a)
            local tx = x + math.cos(rad) * r
            local ty = y + math.sin(rad) * r
            local tz = z
            local ok, gz = GetGroundZFor_3dCoord(tx, ty, z + 5.0, false)
            if ok then
                tz = gz + 0.05
            end
            if not IsPointOnRoad(tx, ty, tz, PlayerPedId()) then
                return tx, ty, tz
            end
            bestX, bestY, bestZ = tx, ty, tz
        end
    end
    return bestX, bestY, bestZ
end

local function spawnDeliveryVehicleAndWarp()
    local modelName = tostring(Config.DeliveryVehicleModel or "speedo")
    local model = GetHashKey(modelName)
    RequestModel(model)
    local guard = 0
    while not HasModelLoaded(model) and guard < 200 do
        Wait(10)
        guard = guard + 1
    end
    if not HasModelLoaded(model) then
        chatInfo("配送車両の読み込みに失敗しました。")
        return
    end

    deleteDeliveryVehicle()

    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local off = Config.DeliveryVehicleSpawnOffset or vector3(4.0, 0.0, 0.0)
    local spawn = GetOffsetFromEntityInWorldCoords(ped, off.x, off.y, off.z)

    local vehicle = CreateVehicle(model, spawn.x, spawn.y, spawn.z, heading, true, false)
    if vehicle and vehicle ~= 0 then
        SetVehicleOnGroundProperly(vehicle)
        SetVehicleColours(vehicle, 111, 111) -- white
        SetVehicleExtraColours(vehicle, 0, 0)
        SetVehicleDirtLevel(vehicle, 0.0)
        SetVehicleHasBeenOwnedByPlayer(vehicle, true)
        SetEntityAsMissionEntity(vehicle, true, true)
        TaskWarpPedIntoVehicle(ped, vehicle, -1)
        S.deliveryVehicle = vehicle
    end
    SetModelAsNoLongerNeeded(model)
end

local function ensureJobNpcBlip()
    local p = Config.JobPedCoords
    if not p then
        return
    end
    if JobNpc.blip and DoesBlipExist(JobNpc.blip) then
        return
    end
    local b = AddBlipForCoord(p.x, p.y, p.z)
    SetBlipSprite(b, 280) -- house/job-ish icon
    SetBlipDisplay(b, 4)
    SetBlipScale(b, 0.85)
    SetBlipColour(b, 2) -- green
    SetBlipAsShortRange(b, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("配達受注所")
    EndTextCommandSetBlipName(b)
    JobNpc.blip = b
end

-- NUI フォーカス: 第2引数 true でマウス操作を有効化
local function setNui(v, cursor)
    local c = (cursor == nil) and v or cursor
    SetNuiFocus(v, c)
end

-- 前方宣言
local getCompletedCount
local openDeliveryMenu

local function pushJobUi()
    local done = 0
    for i = 1, S.total do
        if S.completed[i] then
            done = done + 1
        end
    end
    -- NUI は /delivery で手動表示のみ。ここではUI更新しない。
end

getCompletedCount = function()
    local done = 0
    for i = 1, S.total do
        if S.completed[i] then
            done = done + 1
        end
    end
    return done
end

-- NUI: 先に非表示メッセージ（app.js の type: close）→ フォーカス解除
RegisterNUICallback("uiClose", function(_, cb)
    setNui(false, false)
    cb("ok")
end)

RegisterNUICallback("courseStart", function(d, cb)
    local c = 0
    if type(d) == "table" and d.count then
        c = math.floor(tonumber(d.count) or 0)
    end
    if c ~= 5 and c ~= 10 and c ~= 20 then
        cb("err")
        return
    end
    -- コース選択直後にNUIを閉じてゲーム操作へ戻す
    SendNUIMessage({ type = "close" })
    setNui(false, false)
    resetStateLocal()
    TriggerServerEvent("jp-LetterCarrier:startJob", c)
    -- 受注時に配送車を出し、運転席に乗せる
    spawnDeliveryVehicleAndWarp()
    cb("ok")
end)

RegisterNUICallback("actionReset", function(_, cb)
    if S.hasJob then
        TriggerServerEvent("jp-LetterCarrier:resetJob")
    end
    cb("ok")
end)

RegisterNUICallback("actionCancel", function(_, cb)
    if S.hasJob then
        TriggerServerEvent("jp-LetterCarrier:cancelJob")
    else
        resetStateLocal()
    end
    cb("ok")
end)

openDeliveryMenu = function()
    if S.busy then
        return
    end
    setNui(true, true)
    local done = getCompletedCount()
    local payload = {
        type = "open",
        hasJob = S.hasJob,
        total = S.total,
        completed = done,
        totalEarned = S.totalEarned,
        rewardPer = S.rewardPer,
        expectedBonus = S.expectedBonus,
        course = S.courseSize
    }
    CreateThread(function()
        Wait(0)
        SendNUIMessage(payload)
    end)
end

-- /delivery 等: Config.OpenCommand（nil のときは delivery）
RegisterCommand(tostring(Config.OpenCommand or "delivery"), function()
    openDeliveryMenu()
end, false)

-- よくある打ち間違い用のエイリアス
RegisterCommand("delivary", function()
    openDeliveryMenu()
end, false)

-- 現在地をNPC配置用 vector4 形式で取得するデバッグコマンド
RegisterCommand("getpos", function()
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    local h = GetEntityHeading(ped)
    local msg = string.format("vector4(%.2f, %.2f, %.2f, %.2f)", c.x, c.y, c.z, h)

    print("[jp-LetterCarrier] " .. msg)
    TriggerEvent("chat:addMessage", { args = { "座標", msg } })
end, false)

-- 受注データ
RegisterNetEvent("jp-LetterCarrier:clientJobData", function(p)
    if not p or not p.locations then
        return
    end
    S.hasJob = true
    -- 受注と同時に集荷完了扱い（配送フェーズへ直行）
    S.hasCargo = true
    S.courseSize = p.courseSize or 0
    S.total = p.total or 0
    S.locs = p.locations
    -- 危険防止: 道路上ポイントを歩道側へ補正
    for i = 1, #S.locs do
        local loc = S.locs[i]
        if loc then
            local nx, ny, nz = moveOffRoadPoint(loc.x, loc.y, loc.z)
            S.locs[i].x = nx
            S.locs[i].y = ny
            S.locs[i].z = nz
        end
    end
    S.totalEarned = 0
    S.rewardPer = p.rewardPer or 0
    S.expectedBonus = p.bonus or 0
    S.readyToReport = false
    S.completed = {}
    for i = 1, S.total do
        S.completed[i] = false
    end
    -- 集配所ステップは廃止。受注直後に配送先ブリップを全表示する。
    if S.depotBlip and DoesBlipExist(S.depotBlip) then
        RemoveBlip(S.depotBlip)
        S.depotBlip = nil
    end
    for i = 1, S.total do
        addStopBlip(i, false)
    end
    -- 受注直後に最低1回は強制ナビセット
    if S.locs[1] then
        SetNewWaypoint(S.locs[1].x, S.locs[1].y)
    end
    setNearestRemainingWaypoint()
    CreateThread(function()
        Wait(150)
        setNearestRemainingWaypoint()
    end)
    pushJobUi()
    chatInfo("受注完了。荷物の積み込みは完了済みです。最寄りの配送先へ向かってください。")
end)

RegisterNetEvent("jp-LetterCarrier:readyToReport", function(p)
    S.readyToReport = true
    local npc = Config.JobPedCoords
    if npc then
        SetNewWaypoint(npc.x, npc.y)
    end
    print(("[jp-LetterCarrier][client] readyToReport bonus=%s"):format(tostring(p and p.bonus)))
    chatInfo("全件配達完了。受注担当へ報告してください。")
end)

RegisterNetEvent("jp-LetterCarrier:deliveryResult", function(d)
    if not d then
        return
    end
    print(("[jp-LetterCarrier][client] deliveryResult completed=%s total=%s paid=%s"):format(
        tostring(d.completed), tostring(d.total), tostring(d.paid)
    ))
    -- 進捗カウントは tryDelivery() 側で即時加算済みのため、ここでは二重加算しない
end)

RegisterNetEvent("jp-LetterCarrier:allDeliveriesDone", function(p)
    print(("[jp-LetterCarrier][client] allDeliveriesDone bonus=%s"):format(tostring(p and p.bonus)))
    local b = 0
    if p and type(p.bonus) == "number" then
        b = p.bonus
    end
    if b > 0 then
        S.totalEarned = (S.totalEarned or 0) + b
    end
    resetStateLocal()
end)

RegisterNetEvent("jp-LetterCarrier:forceReset", function(data)
    local r = type(data) == "table" and data.reason
    local hadJob = S.hasJob
    resetStateLocal()
    if not hadJob then
        return
    end
    if r == "reset" then
        chatInfo("進捗を破棄しました。もう一度コースを選べます。")
    elseif r == "cancel" then
        chatInfo("作業を中止しました。")
    else
        chatInfo("配達ジョブをリセットしました。")
    end
end)

-- 受注用NPC生成
CreateThread(function()
    local model = GetHashKey(Config.JobPedModel or "a_m_m_business_01")
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(50)
    end
    local p = Config.JobPedCoords
    if p then
        -- 指定座標で立たせる。zが適正ならその値を優先する
        local spawnZ = (p.z or 0.0)
        local probeOk, probeZ = GetGroundZFor_3dCoord(p.x, p.y, (p.z or 0.0) + 5.0, false)
        if probeOk and math.abs(probeZ - (p.z or 0.0)) <= 0.8 then
            spawnZ = probeZ + 0.02
        end

        local ped = CreatePed(4, model, p.x, p.y, spawnZ, p.w or 0.0, false, true)
        SetEntityAsMissionEntity(ped, true, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetPedCanRagdoll(ped, false)
        SetEntityInvincible(ped, true)
        SetEntityCoordsNoOffset(ped, p.x, p.y, spawnZ, false, false, false)
        FreezeEntityPosition(ped, true)
        SetEntityHeading(ped, p.w or 0.0)
        if Config.JobPedScenario and Config.JobPedScenario ~= "" then
            TaskStartScenarioInPlace(ped, Config.JobPedScenario, 0, true)
        end
        JobNpc.ped = ped
    end
    SetModelAsNoLongerNeeded(model)
end)

-- NPCに話しかけて受注メニューを開く
CreateThread(function()
    while true do
        if JobNpc.ped and DoesEntityExist(JobNpc.ped) then
            local pos = getPedPos()
            local npos = GetEntityCoords(JobNpc.ped)
            local d = #(pos - npos)
            if d < 15.0 then
                if d < 2.0 then
                    SetTextComponentFormat("STRING")
                    if S.readyToReport then
                        AddTextComponentString("~INPUT_CONTEXT~ 配達完了を報告する")
                    else
                        AddTextComponentString("~INPUT_CONTEXT~ 配達を受注する")
                    end
                    DisplayHelpTextFromStringLabel(0, false, false, -1)
                    if IsControlJustPressed(0, 38) then
                        if S.readyToReport then
                            TriggerServerEvent("jp-LetterCarrier:reportCompletion")
                        else
                            openDeliveryMenu()
                        end
                    end
                end
                Wait(0)
            else
                Wait(500)
            end
        else
            Wait(500)
        end
    end
end)

-- 受注所ブリップを維持
CreateThread(function()
    while true do
        ensureJobNpcBlip()
        Wait(2000)
    end
end)

-- 残り配達先のうち、現在地から最寄りへ自動ナビ設定
local function setNearestRemainingWaypoint()
    if not S.hasJob then
        return
    end
    local pos = getPedPos()
    local nearest = 0
    local nearestDist = 999999.0
    for i = 1, S.total do
        if not S.completed[i] and S.locs[i] then
            local d = dist2d(pos, S.locs[i])
            if d < nearestDist then
                nearestDist = d
                nearest = i
            end
        end
    end
    for i = 1, S.total do
        if S.blips[i] and DoesBlipExist(S.blips[i]) then
            SetBlipRoute(S.blips[i], false)
        end
    end
    if nearest > 0 then
        local p = S.locs[nearest]
        print(("[jp-LetterCarrier][client] setNearestWaypoint slot=%s x=%.2f y=%.2f d=%.2f"):format(nearest, p.x, p.y, nearestDist))
        SetNewWaypoint(p.x, p.y)
        if S.blips[nearest] and DoesBlipExist(S.blips[nearest]) then
            SetBlipRoute(S.blips[nearest], true)
        end
    end
end

-- 荷物積み込み（集配所）
local function tryPickup()
    if not S.hasJob or S.hasCargo or S.busy then
        return
    end
    local d = Config.DepotLocation
    local pos = getPedPos()
    if dist2d(pos, d) > Config.InteractRadius + 0.1 then
        return
    end
    S.busy = true
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    playAnimSeconds("anim@heists@box_carry@", "idle", Config.PickupDuration, 49)
    progressBlocking("積み込み中…", Config.PickupDuration)
    ClearPedTasks(ped)
    FreezeEntityPosition(ped, false)
    S.hasCargo = true
    S.busy = false
    if S.depotBlip and DoesBlipExist(S.depotBlip) then
        SetBlipRoute(S.depotBlip, false)
    end
    for i = 1, S.total do
        addStopBlip(i, false)
    end
    setNearestRemainingWaypoint()
    pushJobUi()
    chatInfo("荷物を積み込みました。配達先へ向かってください。")
end

-- 配達
local function tryDelivery(slot)
    if not S.hasJob or not S.hasCargo or S.busy then
        return
    end
    if S.completed[slot] then
        return
    end
    local p = S.locs[slot]
    if not p then
        return
    end
    local pos = getPedPos()
    if dist2d(pos, p) > DELIVERY_USE_RADIUS then
        return
    end
    S.busy = true
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    playAnimSeconds("mp_common", "givetake1_a", Config.DeliveryDuration, 0)
    progressBlocking("配達中…", Config.DeliveryDuration)
    ClearPedTasks(ped)
    FreezeEntityPosition(ped, false)
    S.completed[slot] = true
    if S.blips[slot] and DoesBlipExist(S.blips[slot]) then
        RemoveBlip(S.blips[slot])
        S.blips[slot] = nil
    end
    -- 左側の報酬表示はサーバー応答待ちにせず即時更新
    S.totalEarned = (S.totalEarned or 0) + (Config.RewardPerDelivery or 0)
    S.busy = false
    print(("[jp-LetterCarrier][client] TriggerServerEvent deliveryComplete slot=%s"):format(tostring(slot)))
    TriggerServerEvent("jp-LetterCarrier:deliveryComplete", slot)
    setNearestRemainingWaypoint()
end

local function findNearestDeliverableSlot(pos, maxDist)
    local nearest = 0
    local best = maxDist + 0.001
    for i = 1, S.total do
        if not S.completed[i] then
            local loc = S.locs[i]
            if loc then
                local d = dist2d(pos, loc)
                if d <= maxDist and d < best then
                    best = d
                    nearest = i
                end
            end
        end
    end
    return nearest
end

-- マーカー/入力
CreateThread(function()
    local w = 500
    while true do
        if S.busy or not S.hasJob then
            w = 800
            Wait(w)
        else
            w = 500
            local ped = PlayerPedId()
            local pos = getPedPos()
            if not S.hasCargo then
                local d = Config.DepotLocation
                if dist2d(pos, d) < 50.0 then
                    w = 0
                    local dr = { 255, 220, 0 }
                    drawCylMarker(d, dr)
                    if dist2d(pos, d) <= 2.0 and not IsPedInAnyVehicle(ped, false) and IsControlJustPressed(0, 38) then
                        tryPickup()
                    end
                end
            else
                local anyNear = false
                for i = 1, S.total do
                    if not S.completed[i] then
                        local loc = S.locs[i]
                        if loc then
                            local t = vector3(loc.x, loc.y, loc.z)
                            if dist2d(pos, t) < DELIVERY_MARKER_RADIUS then
                                anyNear = true
                            end
                            if dist2d(pos, t) < DELIVERY_MARKER_RADIUS then
                                drawCylMarker(t, { 50, 150, 255 })
                            end
                        end
                    end
                end
                if not IsPedInAnyVehicle(ped, false) and IsControlJustPressed(0, 38) then
                    local slot = findNearestDeliverableSlot(pos, DELIVERY_USE_RADIUS)
                    if slot > 0 then
                        tryDelivery(slot)
                    end
                end
                w = anyNear and 0 or 500
            end
            Wait(w)
        end
    end
end)

-- 配達ジョブ中のみ、画面左寄りに進捗を常時表示
CreateThread(function()
    while true do
        if S.hasJob then
            local done = getCompletedCount()
            SetTextFont(0)
            SetTextScale(0.0, 0.35)
            SetTextColour(255, 255, 255, 255)
            SetTextProportional(true)
            SetTextEntry("STRING")
            AddTextComponentString(("配達中: %d / %d 件完了"):format(done, S.total or 0))
            DrawText(0.01, 0.50)

            SetTextEntry("STRING")
            AddTextComponentString(("報酬: $%s"):format(formatMoney(S.totalEarned or 0)))
            DrawText(0.01, 0.53)
            Wait(0)
        else
            Wait(500)
        end
    end
end)

-- ナビが消えた時の自動復旧（配送中のみ）
CreateThread(function()
    while true do
        if S.hasJob and S.hasCargo and not S.busy then
            if not IsWaypointActive() then
                setNearestRemainingWaypoint()
            end
            Wait(1500)
        else
            Wait(1500)
        end
    end
end)

-- ESC: NUI が自前で閉じる（app.js） — 保険でフォーカス監視不要
