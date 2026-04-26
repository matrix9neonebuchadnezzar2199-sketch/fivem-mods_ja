local config = require 'config.client'
local sharedConfig = require 'config.shared'

-- ===== locale (locales/<lang>.json) =====
local localeDict = nil

local function loadLocaleDict()
    if localeDict then return end
    local name = GetCurrentResourceName()
    local lang = tostring(config.locale or 'ja')
    local raw = LoadResourceFile(name, ('locales/%s.json'):format(lang))
    if not raw and lang ~= 'en' then
        raw = LoadResourceFile(name, 'locales/en.json')
    end
    if not raw then
        localeDict = {}
        return
    end
    local ok, decoded = pcall(function()
        return json.decode(raw)
    end)
    localeDict = (ok and type(decoded) == 'table') and decoded or {}
end

---@param key string
---@return string
local function tr(key, ...)
    loadLocaleDict()
    local s = localeDict[key] or key
    if select('#', ...) > 0 then
        return s:format(...)
    end
    return s
end

-- ===== state =====
local shiftState = 'off' ---@type 'off'|'on'
local vehicleMode = nil ---@type nil|'personal'|'company'
local companyVehNetId = nil

local stats = {
    customers = 0,
    totalEarnings = 0,
    totalDistance = 0.0,
}

local function resetStats()
    stats.customers = 0
    stats.totalEarnings = 0
    stats.totalDistance = 0.0
end

local function isJobAllowedClient()
    if not config.requireJob then return true end
    if not QBX or not QBX.PlayerData or not QBX.PlayerData.job then
        return false
    end
    return QBX.PlayerData.job.name == config.requiredJobName
end

-- ===== NUI (HUD) =====
local function sendHud(msg)
    SendNUIMessage(msg)
end

local function pushHudLayoutOnce()
    sendHud({
        action = 'setLayout',
        hud = {
            position = (config.hud and config.hud.position) or 'top-right',
            scale = 1.0,
            showMeter = config.hud and config.hud.showMeter ~= false,
            showStats = config.hud and config.hud.showStats ~= false,
        },
        labels = {
            hud_title = tr('hud_title'),
            hud_current_fare = tr('hud_current_fare'),
            hud_current_distance = tr('hud_current_distance'),
            hud_total_customers = tr('hud_total_customers'),
            hud_total_earnings = tr('hud_total_earnings'),
            hud_total_distance = tr('hud_total_distance'),
            hud_summary_title = tr('hud_summary_title'),
            hud_summary_great_job = tr('hud_summary_great_job'),
        }
    })
end

local function hudUpdateStats()
    sendHud({
        action = 'updateStats',
        data = {
            customers = stats.customers,
            totalEarnings = stats.totalEarnings,
            totalDistance = stats.totalDistance,
        }
    })
end

-- ===== blip / depot ped =====
local companyBlip = 0
local receptionPed = 0
local depotZone = nil
local companyDistanceWarned = false
local companyWatchThread = nil
local healthWatchThread = nil
local nextMissionAt = 0

-- ===== qbx 相当: ミッション/メーター =====
local isLoggedIn = LocalPlayer.state.isLoggedIn
local meterIsOpen = false
local meterActive = false
local lastLocation = nil

local pickupLocation, dropOffLocation = nil, nil
local isInsidePickupZone = false
local isInsideDropZone = false
local zonePickup = nil
local zoneDrop = nil

local meterData = {
    fareAmount = 6,
    currentFare = 0,
    distanceTraveled = 0,
}

local NpcData = {
    Active = false,
    CurrentNpc = nil,
    LastNpc = nil,
    CurrentDeliver = nil,
    LastDeliver = nil,
    Npc = 0,
    NpcBlip = 0,
    DeliveryBlip = 0,
    NpcTaken = false,
    NpcDelivered = false,
}

local function resetNpcTask()
    if zonePickup then
        pcall(function() zonePickup:remove() end)
        zonePickup = nil
    end
    if zoneDrop then
        pcall(function() zoneDrop:remove() end)
        zoneDrop = nil
    end
    isInsidePickupZone = false
    isInsideDropZone = false

    if NpcData.NpcBlip ~= 0 and DoesBlipExist(NpcData.NpcBlip) then
        RemoveBlip(NpcData.NpcBlip)
    end
    if NpcData.DeliveryBlip ~= 0 and DoesBlipExist(NpcData.DeliveryBlip) then
        RemoveBlip(NpcData.DeliveryBlip)
    end

    if NpcData.Npc ~= 0 and DoesEntityExist(NpcData.Npc) then
        DeleteEntity(NpcData.Npc)
    end

    NpcData = {
        Active = false,
        CurrentNpc = nil,
        LastNpc = nil,
        CurrentDeliver = nil,
        LastDeliver = nil,
        Npc = 0,
        NpcBlip = 0,
        DeliveryBlip = 0,
        NpcTaken = false,
        NpcDelivered = false,
    }
    lib.hideTextUI()
end

local function resetMeterData()
    meterData = { fareAmount = 6, currentFare = 0, distanceTraveled = 0 }
    lastLocation = nil
    pickupLocation, dropOffLocation = nil, nil
end

local function closeMeterUi()
    meterIsOpen = false
    meterActive = false
    sendHud({ action = 'openMeter', toggle = false })
    sendHud({ action = 'resetMeter' })
end

-- ===== 車両ホワイトリスト (qbx + config) =====
local function isCompanyModel(modelHash)
    for i = 1, #config.companyVehicles, 1 do
        if modelHash == joaat(config.companyVehicles[i].model) then
            return true
        end
    end
    return false
end

local function isWhitelistedVehicle()
    if not cache.vehicle then
        return false
    end
    local model = GetEntityModel(cache.vehicle)

    if vehicleMode == 'company' and companyVehNetId and cache.vehicle and NetworkGetNetworkIdFromEntity(cache.vehicle) == companyVehNetId then
        return true
    end

    if isCompanyModel(model) or model == `dynasty` then
        return true
    end

    if not config.allowPersonalVehicle then
        return false
    end

    if not config.personalVehicleWhitelist or #config.personalVehicleWhitelist == 0 then
        return true
    end
    for i = 1, #config.personalVehicleWhitelist do
        if model == joaat(config.personalVehicleWhitelist[i]) then
            return true
        end
    end
    return false
end

local function isDriver()
    return cache.vehicle and cache.seat == -1
end

-- ===== スポーン地点 =====
local function enumerateEntitiesWithinDistance(entities, isPlayerEntities, coords, maxDistance)
    local nearbyEntities = {}
    if coords then
        coords = vec3(coords.x, coords.y, coords.z)
    else
        coords = GetEntityCoords(cache.ped)
    end
    for k, entity in pairs(entities) do
        local distance = #(coords - GetEntityCoords(entity))
        if distance <= maxDistance then
            nearbyEntities[#nearbyEntities + 1] = isPlayerEntities and k or entity
        end
    end
    return nearbyEntities
end

local function getVehiclesInArea(coords, maxDistance)
    return enumerateEntitiesWithinDistance(GetGamePool('CVehicle'), false, coords, maxDistance)
end

local function isSpawnPointClear(coords, maxDistance)
    return #getVehiclesInArea(coords, maxDistance) == 0
end

local function getVehicleSpawnPoint()
    local near = nil
    local distance = 10000.0
    for k, v in pairs(config.cabSpawns) do
        if isSpawnPointClear(vec3(v.x, v.y, v.z), 2.5) then
            local pos = GetEntityCoords(cache.ped)
            local curDistance = #(pos - vec3(v.x, v.y, v.z))
            if curDistance < distance then
                distance = curDistance
                near = k
            end
        end
    end
    return near
end

-- ===== メーター計算（qbx由来）=====
local function calculateFareAmount()
    if not meterIsOpen or not meterActive then return end
    local startPos = lastLocation
    local newPos = GetEntityCoords(cache.ped)
    if not startPos or not newPos then return end
    if startPos == newPos then return end

    local newDistance = #(startPos - newPos)
    lastLocation = newPos
    meterData.distanceTraveled = meterData.distanceTraveled + (newDistance / 1609.0)

    local fareAmount = 0.0
    if config.meter.useGpsPrice and pickupLocation and dropOffLocation then
        local gpsMiles = CalculateTravelDistanceBetweenPoints(
            pickupLocation.x, pickupLocation.y, pickupLocation.z,
            dropOffLocation.x, dropOffLocation.y, dropOffLocation.z
        ) / 1609.0
        fareAmount = (gpsMiles * config.meter.defaultPrice) + config.meter.startingPrice
    else
        fareAmount = ((meterData.distanceTraveled) * config.meter.defaultPrice) + config.meter.startingPrice
    end

    meterData.currentFare = math.floor(fareAmount)
    sendHud({
        action = 'updateMeter',
        meterData = meterData,
    })
end

-- ===== 目的地/乗車地点 =====
local function pickDifferentIndex(max, last)
    if max <= 1 then return 1 end
    local cur = math.random(1, max)
    if not last then return cur end
    local guard = 0
    while cur == last and guard < 20 do
        cur = math.random(1, max)
        guard = guard + 1
    end
    return cur
end

local function getDeliveryLocation()
    NpcData.CurrentDeliver = pickDifferentIndex(#sharedConfig.npcLocations.deliverLocations, NpcData.LastDeliver)

    if NpcData.DeliveryBlip ~= 0 and DoesBlipExist(NpcData.DeliveryBlip) then
        RemoveBlip(NpcData.DeliveryBlip)
    end

    local d = sharedConfig.npcLocations.deliverLocations[NpcData.CurrentDeliver]
    NpcData.DeliveryBlip = AddBlipForCoord(d.x, d.y, d.z)
    SetBlipColour(NpcData.DeliveryBlip, 3)
    SetBlipRoute(NpcData.DeliveryBlip, true)
    SetBlipRouteColour(NpcData.DeliveryBlip, 3)
    NpcData.LastDeliver = NpcData.CurrentDeliver

    dropOffLocation = config.pzLocations.dropLocations[NpcData.CurrentDeliver].coord.xyz
end

local function onEnterDropZone()
    if isWhitelistedVehicle() and (not isInsideDropZone) and NpcData.NpcTaken then
        isInsideDropZone = true
        lib.showTextUI(tr('text_drop'), { position = 'left-center' })
        dropNpcPoly()
    end
end

local function onExitDropZone()
    lib.hideTextUI()
    isInsideDropZone = false
end

function createNpcDelieveryLocation()
    if zoneDrop then
        pcall(function() zoneDrop:remove() end)
        zoneDrop = nil
    end
    local pz = config.pzLocations.dropLocations[NpcData.CurrentDeliver]
    zoneDrop = lib.zones.box({
        coords = pz.coord,
        size = vec3(pz.height, pz.width, (pz.maxZ - pz.minZ)),
        rotation = pz.heading,
        debug = config.debug,
        onEnter = onEnterDropZone,
        onExit = onExitDropZone
    })
end

local function applyDropOff()
    if not NpcData.NpcTaken then return end
    lib.hideTextUI()

    local veh = cache.vehicle
    if not veh then return end

    if NpcData.Npc ~= 0 and DoesEntityExist(NpcData.Npc) then
        TaskLeaveVehicle(NpcData.Npc, veh, 0)
        Wait(800)
        SetVehicleDoorShut(veh, 3, false)
        SetEntityAsMissionEntity(NpcData.Npc, false, true)
        SetEntityAsNoLongerNeeded(NpcData.Npc)

        local target = sharedConfig.npcLocations.takeLocations[NpcData.LastNpc]
        TaskGoStraightToCoord(NpcData.Npc, target.x, target.y, target.z, 1.0, -1, 0.0, 0.0)
    end

    sendHud({ action = 'toggleMeter' })
    local fare = math.floor(tonumber(meterData.currentFare) or 0)
    meterActive = false
    closeMeterUi()

    TriggerServerEvent('jp-taxijob:server:npcPay', fare)

    stats.customers = stats.customers + 1
    stats.totalEarnings = stats.totalEarnings + fare
    stats.totalDistance = stats.totalDistance + (tonumber(meterData.distanceTraveled) or 0.0)
    hudUpdateStats()

    exports.qbx_core:Notify(tr('notify_dropped_off', tostring(fare)), 'success')

    if NpcData.DeliveryBlip ~= 0 and DoesBlipExist(NpcData.DeliveryBlip) then
        RemoveBlip(NpcData.DeliveryBlip)
    end

    if NpcData.Npc ~= 0 and DoesEntityExist(NpcData.Npc) then
        local ped = NpcData.Npc
        SetTimeout(60000, function()
            if ped ~= 0 and DoesEntityExist(ped) then
                DeleteEntity(ped)
            end
        end)
    end

    if zoneDrop then
        pcall(function() zoneDrop:remove() end)
        zoneDrop = nil
    end

    resetMeterData()
    resetNpcTask()
    isInsideDropZone = false

    if shiftState == 'on' then
        nextMissionAt = GetGameTimer() + 3000
    end
end

function dropNpcPoly()
    CreateThread(function()
        while NpcData.NpcTaken do
            if isInsideDropZone and IsControlJustPressed(0, 38) then
                applyDropOff()
                break
            end
            Wait(0)
        end
    end)
end

local function callNpcPoly()
    CreateThread(function()
        while not NpcData.NpcTaken do
            if isInsidePickupZone and IsControlJustPressed(0, 38) then
                lib.hideTextUI()
                local vehicle = cache.vehicle
                if not vehicle or not isDriver() then
                    exports.qbx_core:Notify(tr('error_not_in_vehicle'), 'error')
                elseif not isWhitelistedVehicle() then
                    exports.qbx_core:Notify(tr('notify_not_whitelisted'), 'error')
                else
                    local maxSeats, freeSeat = GetVehicleMaxNumberOfPassengers(vehicle), 0
                    for i = maxSeats - 1, 0, -1 do
                        if IsVehicleSeatFree(vehicle, i) then
                            freeSeat = i
                            break
                        end
                    end

                    pickupLocation = GetEntityCoords(cache.ped)

                    meterIsOpen = true
                    meterActive = true
                    lastLocation = GetEntityCoords(cache.ped)

                    sendHud({ action = 'openMeter', toggle = true, meterData = config.meter })
                    sendHud({ action = 'toggleMeter' })

                    if NpcData.Npc ~= 0 and DoesEntityExist(NpcData.Npc) then
                        ClearPedTasksImmediately(NpcData.Npc)
                        FreezeEntityPosition(NpcData.Npc, false)
                        TaskEnterVehicle(NpcData.Npc, vehicle, -1, freeSeat, 1.0, 0)
                    end

                    exports.qbx_core:Notify(tr('notify_go_to_location'), 'inform')
                    if NpcData.NpcBlip ~= 0 and DoesBlipExist(NpcData.NpcBlip) then
                        RemoveBlip(NpcData.NpcBlip)
                    end
                    getDeliveryLocation()
                    createNpcDelieveryLocation()

                    NpcData.NpcTaken = true
                    if zonePickup then
                        pcall(function() zonePickup:remove() end)
                        zonePickup = nil
                    end
                    lib.hideTextUI()
                end
            end
            Wait(0)
        end
    end)
end

local function onEnterCallZone()
    if isWhitelistedVehicle() and (not isInsidePickupZone) and (not NpcData.NpcTaken) then
        isInsidePickupZone = true
        lib.showTextUI(tr('text_pickup'), { position = 'left-center' })
        callNpcPoly()
    end
end

local function onExitCallZone()
    lib.hideTextUI()
    isInsidePickupZone = false
end

local function createNpcPickUpLocation()
    if zonePickup then
        pcall(function() zonePickup:remove() end)
        zonePickup = nil
    end
    local pz = config.pzLocations.takeLocations[NpcData.CurrentNpc]
    zonePickup = lib.zones.box({
        coords = pz.coord,
        size = vec3(pz.height, pz.width, (pz.maxZ - pz.minZ)),
        rotation = pz.heading,
        debug = config.debug,
        onEnter = onEnterCallZone,
        onExit = onExitCallZone
    })
end

local function doTaxiNpc()
    if shiftState ~= 'on' then return end
    if NpcData.Active then
        exports.qbx_core:Notify(tr('notify_already_mission'), 'error')
        return
    end
    if not cache.vehicle or not isDriver() then
        exports.qbx_core:Notify(tr('notify_need_vehicle'), 'error')
        return
    end
    if not isWhitelistedVehicle() then
        exports.qbx_core:Notify(tr('notify_not_whitelisted'), 'error')
        return
    end

    NpcData.CurrentNpc = pickDifferentIndex(#sharedConfig.npcLocations.takeLocations, NpcData.LastNpc)

    local gender = math.random(1, #config.npcSkins)
    local pick = math.random(1, #config.npcSkins[gender])
    local model = joaat(config.npcSkins[gender][pick])

    lib.requestModel(model)
    local loc = sharedConfig.npcLocations.takeLocations[NpcData.CurrentNpc]
    NpcData.Npc = CreatePed(3, model, loc.x, loc.y, loc.z - 0.98, loc.w, true, true)
    SetModelAsNoLongerNeeded(model)
    if NpcData.Npc == 0 then
        return
    end
    PlaceObjectOnGroundProperly(NpcData.Npc)
    FreezeEntityPosition(NpcData.Npc, true)

    if NpcData.NpcBlip ~= 0 and DoesBlipExist(NpcData.NpcBlip) then
        RemoveBlip(NpcData.NpcBlip)
    end

    exports.qbx_core:Notify(tr('notify_npc_on_gps'), 'success')
    NpcData.NpcBlip = AddBlipForCoord(loc.x, loc.y, loc.z)
    SetBlipColour(NpcData.NpcBlip, 3)
    SetBlipRoute(NpcData.NpcBlip, true)
    SetBlipRouteColour(NpcData.NpcBlip, 3)
    NpcData.LastNpc = NpcData.CurrentNpc
    NpcData.Active = true

    if not config.useTarget then
        createNpcPickUpLocation()
    end
end

RegisterNetEvent('jp-taxijob:client:doTaxiNpc', function()
    doTaxiNpc()
end)

-- 互換名（qbx / qb 由来のイベント名差）
RegisterNetEvent('qb-taxi:client:DoTaxiNpc', function()
    doTaxiNpc()
end)

-- ===== 受付/勤務（メニュー）=====
local function stopCompanyWatchers()
    companyWatchThread = nil
    healthWatchThread = nil
    companyDistanceWarned = false
end

local function tryDeleteCompanyCab()
    if not companyVehNetId then return end
    pcall(function()
        lib.callback.await('jp-taxijob:server:deleteCompanyCab', false, companyVehNetId)
    end)
    companyVehNetId = nil
end

local function endShiftAndCleanup(showSummary, reason)
    if shiftState == 'off' then return end

    resetNpcTask()
    closeMeterUi()
    resetMeterData()
    tryDeleteCompanyCab()
    stopCompanyWatchers()

    if showSummary then
        sendHud({ action = 'endShift', data = stats })
    else
        sendHud({ action = 'setRootVisible', visible = false })
    end

    shiftState = 'off'
    vehicleMode = nil
    nextMissionAt = 0
    resetStats()
    TriggerServerEvent('jp-taxijob:server:endShift')
end

local function startShift(mode)
    if shiftState == 'on' then return end
    if not isJobAllowedClient() then
        exports.qbx_core:Notify(tr('notify_require_job'), 'error')
        return
    end

    shiftState = 'on'
    vehicleMode = mode
    resetStats()
    pushHudLayoutOnce()
    sendHud({ action = 'startShift', mode = mode })
    hudUpdateStats()
    companyDistanceWarned = false
    nextMissionAt = 0
    TriggerServerEvent('jp-taxijob:server:startShift', mode)
end

local function companyDistanceWatcher()
    if companyWatchThread then return end
    companyWatchThread = CreateThread(function()
        while shiftState == 'on' and vehicleMode == 'company' and companyVehNetId do
            Wait(1000)
            if not companyVehNetId then break end
            local veh = NetworkGetEntityFromNetworkId(companyVehNetId)
            if veh == 0 or not DoesEntityExist(veh) then
                break
            end
            local pcoords = GetEntityCoords(cache.ped)
            local vcoords = GetEntityCoords(veh)
            local d = #(pcoords - vcoords)
            local warn = (config.company and config.company.warnDistance) or 50.0
            local finish = (config.company and config.company.endDistance) or 100.0
            if d > warn and d <= finish and (not companyDistanceWarned) then
                companyDistanceWarned = true
                exports.qbx_core:Notify(tr('notify_too_far'), 'error')
            elseif d > finish then
                exports.qbx_core:Notify(tr('notify_too_far_end'), 'error')
                endShiftAndCleanup(true, 'too_far')
                break
            elseif d <= warn and companyDistanceWarned then
                companyDistanceWarned = false
            end
        end
        companyWatchThread = nil
    end)
end

local function vehicleHealthWatcher()
    if healthWatchThread then return end
    healthWatchThread = CreateThread(function()
        while shiftState == 'on' do
            Wait(1000)
            if cache.vehicle then
                local eng = GetVehicleEngineHealth(cache.vehicle)
                local dead = (eng <= 0.0) or IsEntityDead(cache.vehicle)
                if dead then
                    exports.qbx_core:Notify(tr('notify_vehicle_destroyed'), 'error')
                    resetNpcTask()
                    closeMeterUi()
                    resetMeterData()
                    if vehicleMode == 'company' then
                        endShiftAndCleanup(true, 'destroyed')
                        break
                    else
                        -- マイカー: ミッションは中断。勤務は継続
                        NpcData.Active = false
                    end
                end
            end
        end
        healthWatchThread = nil
    end)
end

local function openCompanyVehicleMenu()
    if not isJobAllowedClient() then
        exports.qbx_core:Notify(tr('notify_require_job'), 'error')
        return
    end
    local opts = {}
    for _, v in pairs(config.companyVehicles) do
        opts[#opts + 1] = {
            title = v.label,
            icon = 'taxi',
            onSelect = function()
                local spawnId = getVehicleSpawnPoint()
                if not spawnId then
                    exports.qbx_core:Notify(tr('notify_no_spawn_point'), 'error')
                    return
                end
                local coords4 = config.cabSpawns[spawnId]
                if not isSpawnPointClear(coords4, 2.0) then
                    exports.qbx_core:Notify(tr('notify_no_spawn_point'), 'error')
                    return
                end
                local netId = lib.callback.await('jp-taxijob:server:spawnCompanyCab', false, v.model, coords4)
                if not netId then
                    exports.qbx_core:Notify(tr('notify_no_spawn_point'), 'error')
                    return
                end
                local veh = NetToVeh(netId)
                SetVehicleFuelLevel(veh, 100.0)
                SetVehicleEngineOn(veh, true, true, false)
                companyVehNetId = netId
                startShift('company')
                companyDistanceWatcher()
                vehicleHealthWatcher()
                nextMissionAt = GetGameTimer()
                exports.qbx_core:Notify(tr('notify_shift_start_company'), 'success')
            end
        }
    end

    lib.registerContext({
        id = 'jp_taxijob_company_veh',
        title = tr('menu_select_vehicle'),
        options = opts
    })
    lib.showContext('jp_taxijob_company_veh')
end

local function openStartMenu()
    if not isJobAllowedClient() then
        exports.qbx_core:Notify(tr('notify_require_job'), 'error')
        return
    end
    lib.registerContext({
        id = 'jp_taxijob_start',
        title = tr('menu_title'),
        options = {
            {
                title = tr('menu_personal'),
                icon = 'car',
                onSelect = function()
                    if not cache.vehicle or not isDriver() then
                        exports.qbx_core:Notify(tr('notify_need_vehicle'), 'error')
                        return
                    end
                    vehicleMode = 'personal'
                    if not isWhitelistedVehicle() then
                        exports.qbx_core:Notify(tr('notify_not_whitelisted'), 'error')
                        vehicleMode = nil
                        return
                    end
                    startShift('personal')
                    vehicleHealthWatcher()
                    nextMissionAt = GetGameTimer()
                    exports.qbx_core:Notify(tr('notify_shift_start_personal'), 'success')
                end
            },
            {
                title = tr('menu_company'),
                icon = 'taxi',
                onSelect = function()
                    openCompanyVehicleMenu()
                end
            },
            {
                title = tr('menu_cancel'),
                icon = 'xmark',
                onSelect = function() end
            },
        }
    })
    lib.showContext('jp_taxijob_start')
end

local function openEndMenu()
    lib.registerContext({
        id = 'jp_taxijob_end',
        title = tr('menu_title'),
        options = {
            {
                title = tr('menu_end_shift'),
                icon = 'flag',
                onSelect = function()
                    endShiftAndCleanup(true, 'manual')
                end
            },
            {
                title = tr('menu_continue'),
                icon = 'xmark',
                onSelect = function() end
            },
        }
    })
    lib.showContext('jp_taxijob_end')
end

local function openDepotMenu()
    if not isJobAllowedClient() then
        exports.qbx_core:Notify(tr('notify_require_job'), 'error')
        return
    end
    if shiftState == 'off' then
        openStartMenu()
    else
        openEndMenu()
    end
end

-- ===== 初期化: blip / ped / depot zone / target =====
local function setCompanyBlip()
    if not config.useBlips then return end
    if companyBlip ~= 0 and DoesBlipExist(companyBlip) then
        RemoveBlip(companyBlip)
        companyBlip = 0
    end
    if not (config.blip and config.blip.enabled) then return end
    local c = (config.locations and config.locations.main and config.locations.main.coords) or config.depot.coords
    companyBlip = AddBlipForCoord(c.x, c.y, c.z)
    SetBlipSprite(companyBlip, config.blip.sprite or 198)
    SetBlipDisplay(companyBlip, 4)
    SetBlipScale(companyBlip, config.blip.scale or 0.6)
    SetBlipAsShortRange(companyBlip, true)
    SetBlipColour(companyBlip, config.blip.color or 5)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(config.blip.label or tr('blip_name'))
    EndTextCommandSetBlipName(companyBlip)
end

local function createReceptionPed()
    if receptionPed ~= 0 and DoesEntityExist(receptionPed) then
        return
    end
    local m = joaat(config.depot.pedModel)
    lib.requestModel(m)
    local c = config.depot.coords
    receptionPed = CreatePed(0, m, c.x, c.y, c.z - 1.0, c.w, false, true)
    SetModelAsNoLongerNeeded(m)
    SetBlockingOfNonTemporaryEvents(receptionPed, true)
    FreezeEntityPosition(receptionPed, true)
    SetEntityInvincible(receptionPed, true)

    exports.ox_target:addLocalEntity(receptionPed, {
        {
            name = 'jp_taxijob_depot',
            icon = 'fa-solid fa-taxi',
            label = tr('target_label'),
            onSelect = function()
                openDepotMenu()
            end,
        }
    })
end

local function createDepotZone()
    if depotZone then
        pcall(function() depotZone:remove() end)
        depotZone = nil
    end
    local c = vec3(config.depot.coords.x, config.depot.coords.y, config.depot.coords.z)
    local r = (config.depot.interactRadius or 8.0) + 0.0
    depotZone = lib.zones.sphere({
        coords = c,
        radius = r,
        debug = config.debug,
        onEnter = function()
            lib.showTextUI(tr('depot_help'), { position = 'right-center' })
        end,
        onExit = function()
            lib.hideTextUI()
        end,
        inside = function()
            if IsControlJustPressed(0, 38) then
                openDepotMenu()
            end
        end
    })
end

CreateThread(function()
    while not isLoggedIn do
        Wait(200)
    end
    setCompanyBlip()
    createReceptionPed()
    createDepotZone()
end)

CreateThread(function()
    local c = vec3(config.depot.coords.x, config.depot.coords.y, config.depot.coords.z)
    while true do
        local p = GetEntityCoords(cache.ped)
        if #(p - c) < 40.0 then
            DrawMarker(1, c.x, c.y, c.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, (config.depot.interactRadius or 8.0) * 2.0, (config.depot.interactRadius or 8.0) * 2.0, 0.5, 255, 220, 50, 90, false, true, 2, false, nil, nil, false)
        end
        Wait(0)
    end
end)

-- ===== threads: meter / 自動次ミッション =====
local meterInterval = (config.hud and tonumber(config.hud.updateInterval)) or 2000
CreateThread(function()
    while true do
        Wait(meterInterval)
        if shiftState == 'on' and meterIsOpen and meterActive then
            calculateFareAmount()
        end
    end
end)

CreateThread(function()
    while true do
        if shiftState == 'on' and (not NpcData.Active) and (GetGameTimer() >= nextMissionAt) and nextMissionAt > 0 then
            if cache.vehicle and isDriver() and isWhitelistedVehicle() then
                doTaxiNpc()
            end
        end
        Wait(250)
    end
end)

-- ===== player/qbx events =====
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    isLoggedIn = true
    setCompanyBlip()
    createReceptionPed()
    createDepotZone()
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    pcall(function()
        if depotZone then depotZone:remove() end
    end)
    if companyBlip ~= 0 and DoesBlipExist(companyBlip) then
        RemoveBlip(companyBlip)
    end
    if receptionPed ~= 0 and DoesEntityExist(receptionPed) then
        DeleteEntity(receptionPed)
    end
    resetNpcTask()
    sendHud({ action = 'setRootVisible', visible = false })
end)

-- safety: 車外メーター表示を閉じる
CreateThread(function()
    while true do
        if (not cache.vehicle) and meterIsOpen then
            closeMeterUi()
        end
        Wait(200)
    end
end)
