-- jp-mi-train: ヘリ → 列車（DBuz747 有効時は屋根を経由せず車内へ直接）

---@class HeliBoardModule
local M = {}

---@type 'idle'|'heli_approach'|'boarding'|'on_train'
M.phase = 'idle'

---@type boolean
M.helpVisible = false

---@type boolean 車内にいる
M.interiorMode = false

---@type boolean
M.exiting = false

---@param msg string
local function log(msg)
    if Config.Debug then
        print(('[%s/heli] %s'):format(GetCurrentResourceName(), msg))
    end
end

-- ============================================================
-- ヘルパー
-- ============================================================

local function IsBoardingActive()
    if _G.MiTrainBlip then
        return _G.MiTrainBlip.IsBoardingActive()
    end
    return false
end

local function TryGetLocalWagonEntity()
    local wagon = exports[GetCurrentResourceName()]:GetLastWagon()
    if wagon and wagon ~= 0 and DoesEntityExist(wagon) then
        return wagon
    end
    return nil
end

--- DBuz747 有効時はヘリから車内直行
local function ShouldBoardDirectToInterior()
    if Config.HeliBoard.boardDirectToInterior == false then
        return false
    end
    if not Config.AddonCarriage or not Config.AddonCarriage.enabled then
        return false
    end
    if not exports[GetCurrentResourceName()]:IsAddonCarriageActive() then
        return false
    end
    local entry = Config.AddonCarriage.interiorEntry
    return entry and entry.enabled ~= false
end

local function ResolveBoardingTarget()
    if not IsBoardingActive() then
        return nil, nil
    end
    local wagon = TryGetLocalWagonEntity()
    if wagon then
        return GetEntityCoords(wagon), wagon
    end
    if not _G.MiTrainBlip then
        return nil, nil
    end
    local maxAge = Config.HeliBoard.maxCoordsAgeMs or 2500
    if _G.MiTrainBlip.GetCoordsAgeMs() > maxAge then
        return nil, nil
    end
    return _G.MiTrainBlip.GetBoardingCoords(), nil
end

local function GetHeliPedIsIn(ped)
    if not IsPedInAnyVehicle(ped, false) then
        return nil
    end
    local veh = GetVehiclePedIsIn(ped, false)
    if not veh or veh == 0 or not IsThisModelAHeli(GetEntityModel(veh)) then
        return nil
    end
    return veh
end

local function CheckProximity(heliCoords, boardCoords)
    local horizontalDist = #(vector2(heliCoords.x, heliCoords.y) - vector2(boardCoords.x, boardCoords.y))
    local altDiff = heliCoords.z - boardCoords.z
    local inRange = horizontalDist <= Config.HeliBoard.detectRadius
        and altDiff >= Config.HeliBoard.minAltitudeAbove
        and altDiff <= Config.HeliBoard.maxAltitudeAbove
    return inRange, horizontalDist, altDiff
end

local function WasInteractPressed()
    return IsControlJustPressed(0, 51)
        or IsControlJustPressed(0, 38)
        or IsDisabledControlJustPressed(0, 51)
        or IsDisabledControlJustPressed(0, 38)
end

local function HorizontalDistance(a, b)
    return #(vector2(a.x, a.y) - vector2(b.x, b.y))
end

local function GetAddonCarriageEntity()
    if not exports[GetCurrentResourceName()]:IsAddonCarriageActive() then
        return nil
    end
    local addon = exports[GetCurrentResourceName()]:GetAddonCarriage()
    if addon and addon ~= 0 and DoesEntityExist(addon) then
        return addon
    end
    return nil
end

-- UI（EnterInterior より前に定義すること）
local interiorHelpVisible = false

local function HideHelp()
    if not M.helpVisible then return end
    lib.hideTextUI()
    M.helpVisible = false
end

local function ShowHelp()
    if M.helpVisible then return end
    local label = Config.HeliBoard.boardPrompt
        or (ShouldBoardDirectToInterior() and '[E] 車内に飛び込む' or '[E] 列車に飛び移る')
    lib.showTextUI(label, { position = 'top-center', icon = 'helicopter' })
    M.helpVisible = true
end

local function HideInteriorHelp()
    if not interiorHelpVisible then return end
    lib.hideTextUI()
    interiorHelpVisible = false
end

local function ShowInteriorHelp()
    if interiorHelpVisible then return end
    lib.showTextUI(Config.HeliBoard.exitTrainPrompt or '[E] 列車から降りる（安全位置へ）', {
        position = 'top-center',
        icon = 'person-walking',
    })
    interiorHelpVisible = true
end

--- 車内歩行: freight 貨車とは無衝突、DBuz747 床のみ当たり判定
---@param ped integer
local function ApplyInteriorPedCollision(ped)
    local addon = GetAddonCarriageEntity()
    local train = _G.MiTrain and _G.MiTrain.train
    if train and train ~= addon and DoesEntityExist(train) then
        SetEntityNoCollisionEntity(ped, train, true)
    end
    for _, w in ipairs(_G.MiTrain and _G.MiTrain.wagons or {}) do
        if w and w ~= addon and DoesEntityExist(w) then
            SetEntityNoCollisionEntity(ped, w, true)
        end
    end
    if addon and DoesEntityExist(addon) then
        SetEntityNoCollisionEntity(ped, addon, false)
    end
end

local function SetTrainCollisionWithPed(ped, enabled)
    local noColl = not enabled
    local train = _G.MiTrain and _G.MiTrain.train
    if train and DoesEntityExist(train) then
        SetEntityNoCollisionEntity(ped, train, noColl)
    end
    for _, w in ipairs(_G.MiTrain and _G.MiTrain.wagons or {}) do
        if w and DoesEntityExist(w) then
            SetEntityNoCollisionEntity(ped, w, noColl)
        end
    end
    local addon = exports[GetCurrentResourceName()]:GetAddonCarriage()
    if addon and addon ~= 0 and DoesEntityExist(addon) then
        SetEntityNoCollisionEntity(ped, addon, noColl)
    end
end

--- 客車コリジョン OFF → プレイヤー状態復帰（降車・リセットでクラッシュ防止）
function M.SafeExitTrain()
    if M.exiting then
        return
    end
    M.exiting = true

    local ped = PlayerPedId()
    if _G.MiTrainAddon then
        _G.MiTrainAddon.SetInteriorCollision(false)
    end
    Wait(50)

    if ped and ped ~= 0 and DoesEntityExist(ped) then
        DetachEntity(ped, true, true)
        FreezeEntityPosition(ped, false)
        SetEntityCollision(ped, true, true)
        SetTrainCollisionWithPed(ped, true)
        SetPedCanRagdoll(ped, true)
        SetEntityProofs(ped, false, false, false, false, false, false, false, false)
        SetEntityVelocity(ped, 0.0, 0.0, 0.0)

        local addon = GetAddonCarriageEntity()
        if addon then
            local exitOff = Config.HeliBoard.exitOffset or vec3(4.5, 0.0, 1.2)
            local world = GetOffsetFromEntityInWorldCoords(addon, exitOff.x, exitOff.y, exitOff.z)
            RequestCollisionAtCoord(world.x, world.y, world.z)
            SetEntityCoordsNoOffset(ped, world.x, world.y, world.z, false, false, false)
            SetEntityVelocity(ped, 0.0, 0.0, 0.0)
            log(('safe exit beside addon at (%.1f, %.1f, %.1f)'):format(world.x, world.y, world.z))
        end
    end

    M.interiorMode = false
    HideInteriorHelp()
    M.exiting = false
    log('safe exit train complete')
end

--- 車内へ（ヘリ着地直後 or 再入場）
---@param fromHeli boolean
function M.EnterInterior(fromHeli)
    if M.interiorMode or M.exiting then
        return false
    end

    local entry = Config.AddonCarriage and Config.AddonCarriage.interiorEntry
    if not entry or entry.enabled == false then
        return false
    end

    local addon = GetAddonCarriageEntity()
    if not addon then
        lib.notify({
            type = 'error',
            title = 'MI Train',
            description = '客車が見つかりません。',
            duration = 6000,
        })
        return false
    end

    local ped = PlayerPedId()
    DetachEntity(ped, true, true)
    FreezeEntityPosition(ped, false)
    SetEntityCollision(ped, true, true)
    SetPedCanRagdoll(ped, true)

    if _G.MiTrainAddon then
        _G.MiTrainAddon.SetInteriorCollision(true)
    end
    ApplyInteriorPedCollision(ped)

    local off = entry.offset or vec3(0.0, 3.5, 0.95)
    local world = GetOffsetFromEntityInWorldCoords(addon, off.x, off.y, off.z)
    RequestCollisionAtCoord(world.x, world.y, world.z)
    Wait(50)
    SetEntityCoordsNoOffset(ped, world.x, world.y, world.z, false, false, false)
    SetEntityHeading(ped, GetEntityHeading(addon) + (entry.headingOffset or 0.0))
    SetEntityVelocity(ped, 0.0, 0.0, 0.0)

    M.interiorMode = true
    M.phase = 'on_train'
    HideHelp()

    lib.notify({
        type = 'success',
        title = 'MI Train',
        description = fromHeli and '列車の車内に飛び込んだ。' or '車内に入った。',
        duration = 6000,
    })
    log(('interior enter addon=%d local (%.2f, %.2f, %.2f)'):format(addon, off.x, off.y, off.z))
    return true
end

local function DrawBoardingMarker(coords, wagon)
    local marker = Config.HeliBoard.marker
    local drawX, drawY, drawZ

    if ShouldBoardDirectToInterior() and wagon and DoesEntityExist(wagon) then
        local entry = Config.AddonCarriage.interiorEntry
        local off = entry and entry.offset or vec3(0.0, 3.5, 0.95)
        local pt = GetOffsetFromEntityInWorldCoords(wagon, off.x, off.y, off.z + 0.3)
        drawX, drawY, drawZ = pt.x, pt.y, pt.z
    elseif wagon and DoesEntityExist(wagon) then
        local pt = GetOffsetFromEntityInWorldCoords(wagon, 0.0, 0.0, marker.roofHeightOffset or 2.8)
        drawX, drawY, drawZ = pt.x, pt.y, pt.z
    else
        drawX = coords.x
        drawY = coords.y
        drawZ = coords.z + marker.zOffset
    end

    DrawMarker(
        marker.type,
        drawX, drawY, drawZ,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        marker.scale.x, marker.scale.y, marker.scale.z,
        marker.color.r, marker.color.g, marker.color.b, marker.color.a,
        false, false, 2, false, false, false, false
    )
end

local function IsPedOutsideTrainInterior(ped, addon)
    local c = GetEntityCoords(ped)
    local localPos = GetOffsetFromEntityGivenWorldCoords(addon, c.x, c.y, c.z)
    local limits = Config.HeliBoard.interiorBounds or {}
    local maxX = limits.maxLocalX or 6.0
    local maxY = limits.maxLocalY or 12.0
    local minZ = limits.minLocalZ or -0.8
    local maxZ = limits.maxLocalZ or 3.5
    if math.abs(localPos.x) > maxX or math.abs(localPos.y) > maxY then
        return true
    end
    if localPos.z < minZ or localPos.z > maxZ then
        return true
    end
    return false
end

local function FinishBoarding(ped, boardCoords, wagon)
    local targetCoords = boardCoords
    if wagon and DoesEntityExist(wagon) then
        targetCoords = GetEntityCoords(wagon)
    end

    local snapDist = HorizontalDistance(GetEntityCoords(ped), targetCoords)
    local maxSnap = Config.HeliBoard.maxBoardingSnapDistance or 18.0
    if snapDist > maxSnap then
        lib.notify({
            type = 'error',
            title = 'MI Train',
            description = '列車の最後尾から遠すぎます。黄色サークルの真上までヘリで接近してください。',
            duration = 8000,
        })
        return false
    end

    TriggerServerEvent('jp-mi-train:joinHeist')

    if ShouldBoardDirectToInterior() then
        if not M.EnterInterior(true) then
            return false
        end
        log(('heli board -> interior direct (snap %.1fm)'):format(snapDist))
        return true
    end

    -- freight のみ（屋根フォールバック・非推奨）
    M.phase = 'on_train'
    lib.notify({ type = 'success', description = '列車に乗り移った。' })
    return true
end

local function ExecuteBoard(heli, boardCoords, wagon)
    M.phase = 'boarding'
    local ped = PlayerPedId()
    log('boarding initiated')

    TaskLeaveVehicle(ped, heli, 4160)
    Citizen.SetTimeout(500, function()
        if DoesEntityExist(heli) then
            SetVehicleAsNoLongerNeeded(heli)
        end
    end)

    local deadline = GetGameTimer() + 3000
    while IsPedInAnyVehicle(ped, false) and GetGameTimer() < deadline do
        Wait(50)
    end

    local freshCoords, freshWagon = ResolveBoardingTarget()
    if freshCoords then
        boardCoords = freshCoords
        wagon = freshWagon
    end

    if not FinishBoarding(ped, boardCoords, wagon) then
        M.phase = 'heli_approach'
    end
end

-- ============================================================
-- メイン
-- ============================================================

local active = false
local lastDebugLogAt = 0
local waitingHintVisible = false

local function ShowWaitingHint()
    if waitingHintVisible then return end
    lib.showTextUI('列車を展開中…', { position = 'top-center', icon = 'train' })
    waitingHintVisible = true
end

local function HideWaitingHint()
    if not waitingHintVisible then return end
    lib.hideTextUI()
    waitingHintVisible = false
end

function M.Start()
    if active then return end
    active = true
    M.phase = 'heli_approach'
    log('heli board watcher started')

    Citizen.CreateThread(function()
        while active do
            local sleep = 500
            local ped = PlayerPedId()

            if M.phase == 'heli_approach' then
                if not IsBoardingActive() then
                    HideHelp()
                    ShowWaitingHint()
                    sleep = 1000
                else
                    HideWaitingHint()
                    local boardCoords, wagon = ResolveBoardingTarget()
                    local heli = GetHeliPedIsIn(ped)
                    if Config.HeliBoard.requireHeliVehicle and not heli then
                        HideHelp()
                    elseif boardCoords and heli then
                        local heliCoords = GetEntityCoords(heli)
                        local distToBoard = HorizontalDistance(heliCoords, boardCoords)
                        if distToBoard <= Config.HeliBoard.markerDrawDistance then
                            sleep = 0
                            DrawBoardingMarker(boardCoords, wagon)
                        end
                        local inRange, dist, alt = CheckProximity(heliCoords, boardCoords)
                        if Config.Debug and distToBoard < Config.HeliBoard.markerDrawDistance then
                            local now = GetGameTimer()
                            if now - lastDebugLogAt > 2000 then
                                lastDebugLogAt = now
                                log(('proximity dist=%.1f alt=%.1f inRange=%s'):format(dist, alt, tostring(inRange)))
                            end
                        end
                        if inRange then
                            ShowHelp()
                            if WasInteractPressed() then
                                HideHelp()
                                ExecuteBoard(heli, boardCoords, wagon)
                            end
                        else
                            HideHelp()
                            sleep = distToBoard <= Config.HeliBoard.markerDrawDistance and 0 or 250
                        end
                    else
                        HideHelp()
                        sleep = 1500
                    end
                end

            elseif M.phase == 'boarding' then
                sleep = 200

            elseif M.phase == 'on_train' and M.interiorMode then
                sleep = 0
                FreezeEntityPosition(ped, false)
                SetPlayerControl(PlayerId(), true, 0)
                ApplyInteriorPedCollision(ped)

                local addon = GetAddonCarriageEntity()
                if not addon then
                    M.SafeExitTrain()
                else
                    ShowInteriorHelp()
                    if WasInteractPressed() then
                        HideInteriorHelp()
                        M.SafeExitTrain()
                    elseif IsPedOutsideTrainInterior(ped, addon) then
                        log('ped left interior bounds, safe exit')
                        HideInteriorHelp()
                        M.SafeExitTrain()
                    end
                end
            end

            Wait(sleep)
        end

        HideHelp()
        HideWaitingHint()
        HideInteriorHelp()
    end)
end

function M.Stop()
    active = false
    M.phase = 'idle'
    HideHelp()
    HideWaitingHint()
    HideInteriorHelp()
    M.SafeExitTrain()
end

_G.MiTrainHeli = M
