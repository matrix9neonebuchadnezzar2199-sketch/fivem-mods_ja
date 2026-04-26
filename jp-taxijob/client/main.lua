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

--- jp-LetterCarrier と同様: 足元Zの補正 + mission entity（道路上の vector4 でも取り残されにくい）
--- @param forceNetworked boolean|nil 設定を上書きして再試行するときtrue（再生成用）
local function createReceptionPed(forceNetworked)
    if receptionPed ~= 0 and DoesEntityExist(receptionPed) then
        return true
    end
    local m = joaat(config.depot.pedModel)
    lib.requestModel(m)
    if not HasModelLoaded(m) then
        print('[jp-taxijob] reception ped: model load failed: ' .. tostring(config.depot.pedModel))
        SetModelAsNoLongerNeeded(m)
        return false
    end
    local c = config.depot.coords
    -- 受付座標周りのコリジョンを先に流す（未ロードで CreatePed が沈む/消えるのを防ぐ）
    RequestCollisionAtCoord(c.x, c.y, c.z)
    local t0 = GetGameTimer()
    while not HasCollisionLoadedAroundEntity(PlayerPedId()) and GetGameTimer() - t0 < 3000 do
        RequestCollisionAtCoord(c.x, c.y, c.z)
        Wait(0)
    end

    local spawnZ = c.z
    local probeOk, probeZ = GetGroundZFor_3dCoord(c.x, c.y, c.z + 5.0, false)
    if probeOk and math.abs(probeZ - c.z) <= 0.8 then
        spawnZ = probeZ + 0.02
    end

    local net
    if forceNetworked == nil then
        net = config.depot.useNetworkedDepotPed == true
    else
        net = forceNetworked == true
    end
    -- pedType 4 = mission。isNetwork: config.useNetworkedDepotPed
    local ped = CreatePed(4, m, c.x, c.y, spawnZ, c.w, net, true)
    SetModelAsNoLongerNeeded(m)
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        print(('[jp-taxijob] reception ped: CreatePed failed (networked=%s)'):format(tostring(net)))
        return false
    end
    receptionPed = ped
    SetEntityAsMissionEntity(receptionPed, true, true)
    SetBlockingOfNonTemporaryEvents(receptionPed, true)
    SetPedCanRagdoll(receptionPed, false)
    SetEntityInvincible(receptionPed, true)
    SetEntityCoordsNoOffset(receptionPed, c.x, c.y, spawnZ, false, false, false)
    FreezeEntityPosition(receptionPed, true)
    SetEntityHeading(receptionPed, c.w)

    if GetResourceState('ox_target') ~= 'started' then
        print('[jp-taxijob] ox_target が started ではありません。Eキー＋球体ゾーンは使えます。ensure ox_target を確認してください。')
    else
        local tOk, tErr = pcall(function()
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
        end)
        if not tOk then
            print('[jp-taxijob] ox_target addLocalEntity 失敗: ' .. tostring(tErr) .. '（受付は Eキー＋円内で会話可）')
        end
    end
    if config.debug then
        local p = GetEntityCoords(receptionPed)
        print(('[jp-taxijob] reception ped ok id=%s pos=%.2f %.2f %.2f net=%s'):format(
            tostring(receptionPed), p.x, p.y, p.z, tostring(net)
        ))
    end
    return true
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

-- 受付周りの初期化（エラーは握り潰さず F8 に出す。ox_target 失敗時も Ped は出す）
local function logInitErr(phase, err)
    print(('[jp-taxijob] init FAIL [%s]: %s'):format(phase, tostring(err)))
end

local function initDepotClient()
    local ok, err = pcall(setCompanyBlip)
    if not ok then logInitErr('setCompanyBlip', err) end
    ok = createReceptionPed(nil)
    if not ok or receptionPed == 0 or not DoesEntityExist(receptionPed) then
        if receptionPed ~= 0 and DoesEntityExist(receptionPed) then
            DeleteEntity(receptionPed)
        end
        receptionPed = 0
        -- 設定と逆のネットワーク扱いでもう一度
        createReceptionPed(not (config.depot.useNetworkedDepotPed == true))
    end
    if receptionPed == 0 or not DoesEntityExist(receptionPed) then
        print('[jp-taxijob] 受付Pedが生成できませんでした。/jp_taxijob_debug で状態確認してください。')
    end
    ok, err = pcall(createDepotZone)
    if not ok then logInitErr('createDepotZone', err) end
end

local function waitForLocalPlayerReady()
    local deadline = GetGameTimer() + 60000
    while GetGameTimer() < deadline do
        if NetworkIsPlayerActive(PlayerId()) then
            local lp = PlayerPedId()
            if lp and lp ~= 0 and DoesEntityExist(lp) then
                return true
            end
        end
        Wait(200)
    end
    return false
end

CreateThread(function()
    -- world / ped が揃うまで待つ（早すぎる CreatePed は取り残されやすい）
    if not waitForLocalPlayerReady() then
        print('[jp-taxijob] 警告: ローカルプレイヤー待ちタイムアウト。受付は遅延生成を試行します。')
    end
    Wait(500)
    initDepotClient()
    -- 念のため再試行（初回だけコリジョン未ロード等）
    if receptionPed == 0 or not DoesEntityExist(receptionPed) then
        Wait(2000)
        if receptionPed == 0 or not DoesEntityExist(receptionPed) then
            print('[jp-taxijob] 受付Pedを再生成します（既存を削除してから）…')
            if receptionPed ~= 0 and DoesEntityExist(receptionPed) then
                DeleteEntity(receptionPed)
            end
            receptionPed = 0
            createReceptionPed(not (config.depot.useNetworkedDepotPed == true))
        end
    end
end)

CreateThread(function()
    local c = vec3(config.depot.coords.x, config.depot.coords.y, config.depot.coords.z)
    while true do
        local myPed = PlayerPedId()
        if myPed ~= 0 then
            local p = GetEntityCoords(myPed)
            if #(p - c) < 40.0 then
                DrawMarker(1, c.x, c.y, c.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, (config.depot.interactRadius or 8.0) * 2.0, (config.depot.interactRadius or 8.0) * 2.0, 0.5, 255, 220, 50, 90, false, true, 2, false, nil, nil, false)
            end
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
    initDepotClient()
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

-- デバッグ: 受付NPC・依存リソースの状態（F8コンソール）
--- 通知・chat が無効な環境でも出る 2D 表示（GTA ネイティブ）
local function drawDebugScreenText(lines, durationMs)
    local tEnd = GetGameTimer() + (durationMs or 12000)
    CreateThread(function()
        while GetGameTimer() < tEnd do
            local y = 0.20
            for i = 1, #lines do
                local line = tostring(lines[i] or '')
                SetTextFont(4)
                SetTextProportional(true)
                SetTextScale(0.0, 0.35)
                SetTextColour(255, 255, 200, 255)
                SetTextDropshadow(0, 0, 0, 0, 255)
                SetTextEdge(1, 0, 0, 0, 200)
                SetTextEntry('STRING')
                SetTextCentre(false)
                AddTextComponentSubstringPlayerName(line)
                DrawText(0.04, y)
                y = y + 0.028
            end
            Wait(0)
        end
    end)
end

--- 画面でも分かるように（print は F8 コンソール専用のため、チャット/通知併用 + 2D 必須表示）
local function showDebugToPlayer(summaryLines)
    local text = table.concat(summaryLines, '\n')
    -- 他が全部死んでいても表示
    drawDebugScreenText(summaryLines, 14000)
    pcall(function()
        lib.notify({
            title = 'jp-taxijob デバッグ',
            description = text,
            duration = 15000,
            type = 'inform',
            position = 'top-right',
        })
    end)
    pcall(function()
        exports.qbx_core:Notify(text, 'inform', 15000)
    end)
    pcall(function()
        TriggerEvent('chat:addMessage', {
            color = { 200, 220, 255 },
            multiline = true,
            args = { '[jp-taxijob]', text },
        })
    end)
end

-- チャットの /cmd は多くの環境でサーバーの RegisterCommand だけ届く。F8 はクライアント直なので両方使う。
local function runTaxijobDebug()
    local res = GetCurrentResourceName()
    local c = config.depot.coords
    local my = PlayerPedId()
    local d = -1.0
    if my ~= 0 then
        local pos = GetEntityCoords(my)
        d = #(pos - vector3(c.x, c.y, c.z))
    end
    local oxl = GetResourceState('ox_lib')
    local oxt = GetResourceState('ox_target')
    local qbx = GetResourceState('qbx_core')
    local existPed = receptionPed ~= 0 and DoesEntityExist(receptionPed)
    local summary = {
        ('resource: %s'):format(res),
        ('ox_lib=%s ox_target=%s qbx=%s'):format(oxl, oxt, qbx),
        ('depot: %.1f, %.1f, %.1f 距離: %.1fm'):format(c.x, c.y, c.z, d),
        ('受付Ped: %s (exist=%s) netCfg=%s'):format(
            tostring(receptionPed), tostring(existPed), tostring(config.depot.useNetworkedDepotPed)
        ),
    }
    print(('[jp-taxijob] resource=%s ox_lib=%s ox_target=%s qbx_core=%s'):format(
        res, oxl, oxt, qbx
    ))
    print(('[jp-taxijob] depot vec4(%.2f, %.2f, %.2f, %.2f) あなたからの距離=%.1fm'):format(c.x, c.y, c.z, c.w, d))
    print(('[jp-taxijob] receptionPed=%s exist=%s networked cfg=%s'):format(
        tostring(receptionPed),
        tostring(existPed),
        tostring(config.depot.useNetworkedDepotPed)
    ))
    if receptionPed ~= 0 and DoesEntityExist(receptionPed) then
        local p = GetEntityCoords(receptionPed)
        print(('[jp-taxijob] ped pos=%.2f %.2f %.2f'):format(p.x, p.y, p.z))
        summary[#summary + 1] = ('ped位置: %.1f %.1f %.1f'):format(p.x, p.y, p.z)
    else
        print('[jp-taxijob] 受付Pedを強制再生成します…')
        summary[#summary + 1] = '→ 受付を再スポーン試行中…'
        if receptionPed ~= 0 and DoesEntityExist(receptionPed) then
            DeleteEntity(receptionPed)
        end
        receptionPed = 0
        createReceptionPed(true)
        if receptionPed == 0 or not DoesEntityExist(receptionPed) then
            receptionPed = 0
            createReceptionPed(false)
        end
        local ok = receptionPed ~= 0 and DoesEntityExist(receptionPed)
        summary[#summary + 1] = ('再生成結果: %s'):format(ok and 'OK' or '失敗（F8ログ参照）')
    end
    showDebugToPlayer(summary)
end

RegisterCommand('jp_taxijob_debug', function()
    runTaxijobDebug()
end, false)

-- サーバーからの TriggerClientEvent 用（RegisterNetEvent + AddEventHandler が互換的に堅い）
RegisterNetEvent('jp-taxijob:client:debugDepot')
AddEventHandler('jp-taxijob:client:debugDepot', function()
    runTaxijobDebug()
end)

-- チャットがコマンドを食う環境用: F9 で必ずクライアント起動（設定→キー割当に「jp taxijob debug」）
RegisterKeyMapping('jp_taxijob_debug', 'jp-taxijob: 受付デバッグ', 'keyboard', 'F9')
