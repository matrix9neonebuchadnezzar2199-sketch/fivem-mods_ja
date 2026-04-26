-- jp-koban クライアント（巡回パトロール）

---@type 'idle'|'patrolling'|'reporting'
local phase = 'idle'

local patrolPoints = {}
local currentTargetIndex = 1
local patrolCount = 0
local currentBlip = nil
local reportBlip = nil
local npcBlip = nil
local jobPed = nil
local busy = false
---@type boolean
local nuiKobanOpen = false

---@return boolean
local function hasRequiredJob()
    local playerData = exports.qbx_core:GetPlayerData()
    return playerData
        and playerData.job
        and playerData.job.name == Config.RequiredJob
end

local function getPed()
    return PlayerPedId()
end

local function getPedPos()
    return GetEntityCoords(getPed(), false)
end

---@param label string "～INPUT_CONTEXT～ …" 形式
local function showHelpE(label)
    if nuiKobanOpen then
        return
    end
    SetTextComponentFormat('STRING')
    AddTextComponentString(label)
    DisplayHelpTextFromStringLabel(0, false, true, -1)
end

local function dist2d(a, b)
    return #(vector3(a.x, a.y, 0) - vector3(b.x, b.y, 0))
end

-- jp-LetterCarrier 互換: 金額の三桁区切り表示
---@param n number|any
---@return string
local function formatMoney(n)
    local s = tostring(math.floor(tonumber(n) or 0))
    local k
    repeat
        s, k = s:gsub('^(-?%d+)(%d%d%d)', '%1,%2')
    until k == 0
    return s
end

---@return number
local function getExpectedPatrolBonus()
    if patrolCount == 10 then
        return Config.CompletionBonus10
    end
    if patrolCount == 5 then
        return Config.CompletionBonus5
    end
    return 0
end

---@return number, number 完了数, 総箇所
local function getPatrolHudCounts()
    if phase == 'reporting' then
        return patrolCount, patrolCount
    end
    if phase == 'patrolling' then
        return math.max(0, currentTargetIndex - 1), patrolCount
    end
    return 0, 0
end

local function removeBlipSafe(b)
    if b and DoesBlipExist(b) then
        RemoveBlip(b)
    end
    return nil
end

local function clearPatrolBlips()
    currentBlip = removeBlipSafe(currentBlip)
    reportBlip = removeBlipSafe(reportBlip)
    ClearGpsPlayerWaypoint()
end

local function resetAll()
    phase = 'idle'
    patrolPoints = {}
    currentTargetIndex = 1
    patrolCount = 0
    busy = false
    nuiKobanOpen = false
    clearPatrolBlips()
    lib.hideTextUI()
end

local function pickRandomPoints(need)
    local src = Config.PatrolLocations
    if #src < need then
        return {}
    end
    local idx = {}
    for i = 1, #src do
        idx[i] = i
    end
    for i = #idx, 2, -1 do
        local j = math.random(i)
        idx[i], idx[j] = idx[j], idx[i]
    end
    local out = {}
    for i = 1, need do
        out[i] = src[idx[i]]
    end
    return out
end

local function setNpcRouteBlip()
    local p = Config.JobPedCoords
    reportBlip = AddBlipForCoord(p.x, p.y, p.z)
    SetBlipSprite(reportBlip, Config.NpcBlipSprite)
    SetBlipDisplay(reportBlip, 4)
    SetBlipScale(reportBlip, Config.NpcBlipScale)
    SetBlipColour(reportBlip, Config.NpcBlipColor)
    SetBlipAsShortRange(reportBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('巡回報告')
    EndTextCommandSetBlipName(reportBlip)
    SetBlipRoute(reportBlip, true)
    SetNewWaypoint(p.x, p.y)
end

local function setCurrentPatrolBlip()
    currentBlip = removeBlipSafe(currentBlip)
    local pos = patrolPoints[currentTargetIndex]
    if not pos then
        return
    end
    currentBlip = AddBlipForCoord(pos.x, pos.y, pos.z)
    SetBlipSprite(currentBlip, Config.PatrolBlipSprite)
    SetBlipDisplay(currentBlip, 4)
    SetBlipScale(currentBlip, Config.PatrolBlipScale)
    SetBlipColour(currentBlip, Config.PatrolBlipColor)
    SetBlipAsShortRange(currentBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(Config.PatrolBlipLabel)
    EndTextCommandSetBlipName(currentBlip)
    SetBlipRoute(currentBlip, true)
    SetNewWaypoint(pos.x, pos.y)
end

---@param count number
local function startPatrolClient(count)
    local pts = pickRandomPoints(count)
    if #pts < count then
        lib.notify({ type = 'error', description = '巡回候補座標が不足しています。' })
        TriggerServerEvent('jp-koban:cancelPatrol')
        return
    end
    phase = 'patrolling'
    patrolCount = count
    patrolPoints = pts
    currentTargetIndex = 1
    setCurrentPatrolBlip()
    lib.notify({ type = 'inform', description = '巡回を開始しました。地図の地点へ向かってください。' })
end

-- 地面のZを誤補正しない（巡回点のZをそのまま）。円盤＝シリンダを薄っぽく
---@param pos vector3|any
---@param dist number プレイヤー距離(2D)
local function drawPatrolPointRings(pos, dist)
    local r = Config.InteractRadius or 2.0
    local dOuter = Config.OuterRingDiameter or 8.0
    local dIn = (r * 2.0) * 0.95
    local h = 0.14
    local hIn = 0.16
    local z0 = pos.z + (Config.PatrolRingZOffset or 0.1)
    if dist < (Config.MarkerDrawRadius or 40.0) + 0.0 then
        -- 大きい青系（到達エリア）
        DrawMarker(
            1, pos.x, pos.y, z0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            dOuter, dOuter, h, 20, 120, 220, 100, false, true, 2, false, nil, nil, false
        )
    end
    if dist <= (r * 2.0) + 0.0 then
        -- 小さい黄緑（Eが効く範囲）
        DrawMarker(
            1, pos.x, pos.y, z0 + 0.01, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            dIn, dIn, hIn, 80, 200, 120, 200, false, true, 2, false, nil, nil, false
        )
    end
end

---@return boolean
local function tryCheckCurrentPoint()
    if busy or phase ~= 'patrolling' then
        return false
    end
    local pos = getPedPos()
    local target = patrolPoints[currentTargetIndex]
    if not target then
        return false
    end
    if dist2d(pos, target) > Config.InteractRadius + 0.15 then
        return false
    end
    if IsPedInAnyVehicle(getPed(), false) then
        lib.notify({ type = 'error', description = '車外で確認してください。' })
        return false
    end
    busy = true
    local ok = lib.progressBar({
        duration = math.floor(Config.CheckDuration * 1000 + 0.5),
        label = '巡回確認中...',
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true, sprint = true },
    })
    busy = false
    if not ok then
        return false
    end
    ClearPedTasks(getPed())
    currentBlip = removeBlipSafe(currentBlip)
    if currentTargetIndex < #patrolPoints then
        currentTargetIndex = currentTargetIndex + 1
        setCurrentPatrolBlip()
    else
        -- 最終地点完了 → 署へ戻る
        phase = 'reporting'
        setNpcRouteBlip()
        lib.notify({ type = 'inform', description = '全地点を確認しました。受付 NPC へ戻り「巡回報告」へ。' })
    end
    return true
end

local function cancelPatrol()
    if phase == 'idle' then
        return
    end
    TriggerServerEvent('jp-koban:cancelPatrol')
    resetAll()
    lib.notify({ type = 'inform', description = '巡回を中断しました。' })
end

local function openNui()
    if not hasRequiredJob() then
        return
    end
    if phase ~= 'idle' then
        return
    end
    nuiKobanOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'open',
        bonus5 = Config.CompletionBonus5,
        bonus10 = Config.CompletionBonus10,
    })
end

RegisterNUICallback('uiClose', function(_, cb)
    nuiKobanOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'close' })
    cb('ok')
end)

RegisterNUICallback('selectCourse', function(data, cb)
    local c = math.floor(tonumber(data and data.count) or 0)
    if c ~= 5 and c ~= 10 then
        cb('err')
        return
    end
    if not hasRequiredJob() then
        lib.notify({ type = 'error', description = 'この受付は警察ジョブ専用です。' })
        cb('err')
        return
    end
    local ok, reason = lib.callback.await('jp-koban:server:tryStartPatrol', false, c)
    if not ok then
        local msg = '巡回を受け付けできません。'
        if reason == 'not_police' or reason == 'wrong_job' then
            msg = '警察（' .. tostring(Config.RequiredJob) .. '）ジョブのみ受注できます。'
        elseif reason == 'busy' then
            msg = '既に受付中の可能性があります。しばらく待って再試行してください。'
        end
        lib.notify({ type = 'error', description = msg })
        cb('err')
        return
    end
    nuiKobanOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'close' })
    startPatrolClient(c)
    cb('ok')
end)

RegisterNetEvent('jp-koban:client:completeResult', function(d)
    if d and d.ok and d.amount then
        lib.notify({ type = 'success', title = '巡回', description = ('現金 $%s を受け取りました。'):format(d.amount) })
    else
        local err = '報告の処理に失敗しました。'
        if d and d.reason == 'no_session' then
            err = '有効な巡回受付が見つかりません。最初から受け直してください。'
        elseif d and d.reason == 'not_police' then
            err = '勤務中の警察官のみ報告できます。'
        end
        lib.notify({ type = 'error', description = err })
    end
    resetAll()
end)

--- 署内 MLO では GetEntityHeightAboveGround が一階外等を指し「下げすぎ」で足が床に潜る。基本は zRef+offset 固定。
---@param ent number
---@param x number
---@param y number
---@param zRef number
local function placeJobPedOnFloor(ent, x, y, zRef)
    local off = (Config.JobPedZOffset or 0.0)
    SetEntityCoordsNoOffset(ent, x, y, zRef + off, false, false, false, false)
    -- 明らかに沈み（高さゼロ以下）のときだけ少し持ち上げ
    for _ = 1, 4 do
        Wait(0)
        if not ent or not DoesEntityExist(ent) then
            return
        end
        local h = GetEntityHeightAboveGround(ent) or 0.0
        if h > -0.12 then
            break
        end
        local p = GetEntityCoords(ent, false)
        SetEntityCoordsNoOffset(ent, p.x, p.y, p.z + 0.08, false, false, false, false)
    end
end

-- 受付 NPC
CreateThread(function()
    local model = GetHashKey(Config.JobPedModel)
    lib.requestModel(model, 10000)
    local p = Config.JobPedCoords
    -- 署 MLO: 衝突の読み込みを数フレーム促す
    for _ = 1, 32 do
        RequestCollisionAtCoord(p.x, p.y, p.z)
        RequestCollisionAtCoord(p.x, p.y, p.z - 0.5)
        Wait(0)
    end
    jobPed = CreatePed(4, model, p.x, p.y, p.z, p.w, false, true)
    if jobPed and jobPed ~= 0 then
        SetEntityAsMissionEntity(jobPed, true, true)
        SetBlockingOfNonTemporaryEvents(jobPed, true)
        SetPedCanRagdoll(jobPed, false)
        SetEntityInvincible(jobPed, true)
        SetEntityHeading(jobPed, p.w)
        placeJobPedOnFloor(jobPed, p.x, p.y, p.z)
        FreezeEntityPosition(jobPed, true)
        if Config.JobPedScenario and Config.JobPedScenario ~= '' then
            TaskStartScenarioInPlace(jobPed, Config.JobPedScenario, 0, true)
        end
        -- シナリオが足元を少し食い込ませることがあるので、同じZに戻して凍結
        Wait(250)
        if DoesEntityExist(jobPed) then
            placeJobPedOnFloor(jobPed, p.x, p.y, p.z)
            SetEntityHeading(jobPed, p.w)
            FreezeEntityPosition(jobPed, true)
        end
        exports.ox_target:addLocalEntity(jobPed, {
            {
                name = 'jp_koban_reception',
                icon = 'fa-solid fa-clipboard-list',
                label = '巡回受付',
                distance = 2.0,
                onSelect = function()
                    if phase == 'idle' then
                        openNui()
                    end
                end,
                canInteract = function()
                    local playerData = exports.qbx_core:GetPlayerData()
                    if not (playerData and playerData.job and playerData.job.name == Config.RequiredJob) then
                        return false
                    end
                    return phase == 'idle'
                end,
            },
            {
                name = 'jp_koban_report',
                icon = 'fa-solid fa-handshake',
                label = '巡回報告',
                distance = 2.0,
                onSelect = function()
                    if phase == 'reporting' then
                        TriggerServerEvent('jp-koban:completePatrol')
                    end
                end,
                canInteract = function()
                    local playerData = exports.qbx_core:GetPlayerData()
                    if not (playerData and playerData.job and playerData.job.name == Config.RequiredJob) then
                        return false
                    end
                    return phase == 'reporting'
                end,
            },
        })
    end
    SetModelAsNoLongerNeeded(model)
end)

-- 警察署前の定位置ブリップ
CreateThread(function()
    while true do
        local p = Config.JobPedCoords
        if (not npcBlip or not DoesBlipExist(npcBlip)) and p then
            npcBlip = AddBlipForCoord(p.x, p.y, p.z)
            SetBlipSprite(npcBlip, Config.NpcBlipSprite)
            SetBlipDisplay(npcBlip, 4)
            SetBlipScale(npcBlip, Config.NpcBlipScale)
            SetBlipColour(npcBlip, Config.NpcBlipColor)
            SetBlipAsShortRange(npcBlip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(Config.NpcBlipLabel)
            EndTextCommandSetBlipName(npcBlip)
        end
        Wait(2000)
    end
end)

-- 円盤マーカー + 左下 ～INPUT_CONTEXT～（E）ヘルプ（NUI フォーカス中は出さない）
CreateThread(function()
    while true do
        if busy or phase ~= 'patrolling' then
            Wait(400)
        else
            local ppos = getPedPos()
            local t = patrolPoints[currentTargetIndex]
            if t then
                local d2 = dist2d(ppos, t)
                if d2 < Config.MarkerDrawRadius then
                    drawPatrolPointRings(t, d2)
                    if
                        d2 <= Config.InteractRadius + 0.05
                        and not IsPedInAnyVehicle(getPed(), false)
                    then
                        if not nuiKobanOpen then
                            showHelpE('~INPUT_CONTEXT~ 巡回確認')
                        end
                        if (not nuiKobanOpen) and IsControlJustPressed(0, 38) then
                            tryCheckCurrentPoint()
                        end
                    end
                    Wait(0)
                else
                    Wait(150)
                end
            else
                Wait(400)
            end
        end
    end
end)

-- 受付 NPC: E ＋ ヘルプ（ox_target と併用可）
CreateThread(function()
    while true do
        if not jobPed or not DoesEntityExist(jobPed) then
            Wait(1000)
        else
            local ppos = getPedPos()
            local n = GetEntityCoords(jobPed, false)
            local d2 = dist2d(ppos, n)
            if
                d2 < 2.0
                and (not nuiKobanOpen)
                and not IsPauseMenuActive()
                and not IsPedInAnyVehicle(getPed(), false)
                and hasRequiredJob()
            then
                if phase == 'idle' then
                    showHelpE('~INPUT_CONTEXT~ 巡回受付（メニュー）')
                    if IsControlJustPressed(0, 38) then
                        openNui()
                    end
                elseif phase == 'reporting' then
                    showHelpE('~INPUT_CONTEXT~ 巡回報告（完了）')
                    if IsControlJustPressed(0, 38) then
                        TriggerServerEvent('jp-koban:completePatrol')
                    end
                end
                Wait(0)
            else
                Wait(200)
            end
        end
    end
end)

-- 巡回中のみ、画面左寄りに進捗を常時表示（jp-LetterCarrier と同様）
CreateThread(function()
    while true do
        if phase == 'patrolling' or phase == 'reporting' then
            local done, total = getPatrolHudCounts()
            -- LetterCarrier: 「配達中: n / m 件完了」に合わせる
            local line1 = (('巡回中: %d / %d 箇所完了'):format(done, total))
            SetTextFont(0)
            SetTextScale(0.0, 0.70) -- 0.35 の2倍（LetterCarrier 進捗行と同倍率方針）
            SetTextColour(255, 255, 255, 255)
            SetTextProportional(true)
            SetTextDropshadow(2, 0, 0, 0, 255) -- 影付き
            SetTextEdge(1, 0, 0, 0, 255)    -- 縁取り（読みやすさ）
            SetTextEntry('STRING')
            AddTextComponentString(line1)
            DrawText(0.01, 0.48) -- 大文字化に合わせ上寄せ
            local expected = getExpectedPatrolBonus()
            local line2
            if phase == 'reporting' then
                line2 = ('受付で報告: 完遂 $%s'):format(formatMoney(expected))
            else
                line2 = ('完遂予定: $%s'):format(formatMoney(expected))
            end
            SetTextFont(0)
            SetTextScale(0.0, 0.70)
            SetTextColour(255, 255, 255, 255)
            SetTextProportional(true)
            SetTextDropshadow(2, 0, 0, 0, 255)
            SetTextEdge(1, 0, 0, 0, 255)
            SetTextEntry('STRING')
            AddTextComponentString(line2)
            DrawText(0.01, 0.56) -- 2行目は行高を確保
            Wait(0)
        else
            Wait(500)
        end
    end
end)

RegisterCommand(Config.CancelCommand or 'patrol', function()
    if phase == 'idle' then
        lib.notify({ type = 'inform', description = '巡回は開始されていません。' })
        return
    end
    cancelPatrol()
end, false)

AddEventHandler('onResourceStop', function(name)
    if name ~= GetCurrentResourceName() then
        return
    end
    nuiKobanOpen = false
    SetNuiFocus(false, false)
    lib.hideTextUI()
    currentBlip = removeBlipSafe(currentBlip)
    reportBlip = removeBlipSafe(reportBlip)
    npcBlip = removeBlipSafe(npcBlip)
    if jobPed and DoesEntityExist(jobPed) then
        DeleteEntity(jobPed)
    end
end)
