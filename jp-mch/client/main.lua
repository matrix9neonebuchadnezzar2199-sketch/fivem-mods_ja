-- client/main.lua
-- jp-mch: 日本語ミニマル HUD（マルチフレームワーク）

local hudData = {
    lastHunger = 100,
    lastThirst = 100,
    isTalking = false,
    voiceRange = 2,
    inVehicle = false,
    seatbelt = false,
    cash = 0,
    bank = 0,
    black = 0,
    job = nil,
    moneyHudVisible = false,
    playerId = 0,
}

local hudConfig = {
    showMoney = Config.ShowMoneyHudOnStart and Config.EnableMoney or false,
    showJob = Config.ShowMoneyHudOnStart and Config.EnableJob or false,
    enableMoneyUpdates = Config.EnableMoney,
    enableJobUpdates = Config.EnableJob,
}

-- natives キャッシュ
local PlayerPedId = PlayerPedId
local GetEntityHealth = GetEntityHealth
local GetPedArmour = GetPedArmour
local GetPlayerStamina = GetPlayerStamina
local GetPlayerSprintStaminaRemaining = GetPlayerSprintStaminaRemaining
local GetPlayerUnderwaterTimeRemaining = GetPlayerUnderwaterTimeRemaining
local IsPedSwimmingUnderWater = IsPedSwimmingUnderWater
local GetVehiclePedIsIn = GetVehiclePedIsIn
local GetEntitySpeed = GetEntitySpeed
local GetVehicleFuelLevel = GetVehicleFuelLevel
local GetIsVehicleEngineRunning = GetIsVehicleEngineRunning
local GetVehicleLightsState = GetVehicleLightsState
local SendNUIMessage = SendNUIMessage
local Wait = Wait
local PlayerId = PlayerId
local GetResourceState = GetResourceState
local GetGameTimer = GetGameTimer
local GetActiveScreenResolution = GetActiveScreenResolution
local GetSafeZoneSize = GetSafeZoneSize
local GetNumResources = GetNumResources
local GetResourceByFindIndex = GetResourceByFindIndex

local useESXStatus = false
local radarMode = 'auto' -- 'auto' / 'force_on' / 'force_off'

-- ===========================================================
-- 初回 NUI 送信：UI に辞書と通貨記号を渡す
-- ===========================================================
local function pushI18n()
    SendNUIMessage({
        type = 'setI18n',
        dict = Locale.ui,
        currency = Config.CurrencySymbol or '$',
    })
end

-- ===========================================================
-- ミニマップ制御
-- ===========================================================
local function applyRadarMode()
    if radarMode == 'force_on' then
        DisplayRadar(true)
    elseif radarMode == 'force_off' then
        DisplayRadar(false)
    else
        DisplayRadar(hudData.inVehicle)
    end
    SetRadarBigmapEnabled(false, false)
end

local function isMinimapVisible()
    if radarMode == 'force_on' then return true end
    if radarMode == 'force_off' then return false end
    return hudData.inVehicle
end

local function updateMinimapOffset()
    SendNUIMessage({ type = 'setMinimapVisible', visible = isMinimapVisible() })
end

-- ===========================================================
-- レイアウト（解像度／セーフゾーン適応）
-- ===========================================================
local lastLayout = { w = 0, h = 0, safe = 0.0 }

local function getKvpNumber(key)
    local s = GetResourceKvpString(key)
    if s then
        local n = tonumber(s)
        if n then return n end
    end
    return nil
end

-- 旧 munlay_hud_* キーから jp_mch_* キーへ片方向マイグレーション
local function migrateOldKvp()
    local oldOff = GetResourceKvpString('munlay_hud_offset_px')
    local oldScl = GetResourceKvpString('munlay_hud_scale')
    if oldOff and not GetResourceKvpString('jp_mch_offset_px') then
        SetResourceKvp('jp_mch_offset_px', oldOff)
    end
    if oldScl and not GetResourceKvpString('jp_mch_scale') then
        SetResourceKvp('jp_mch_scale', oldScl)
    end
end

local function computeAndApplyHudLayout(force)
    local w, h = GetActiveScreenResolution()
    if not w or not h or w <= 0 or h <= 0 then return end
    local safe = GetSafeZoneSize() or 1.0

    if not force and lastLayout.w == w and lastLayout.h == h and math.abs((lastLayout.safe or 0) - safe) < 0.0005 then
        return
    end

    local aspect = w / h
    local baseFrac
    if aspect >= 1.77 then
        baseFrac = 0.185
    elseif aspect >= 1.6 then
        baseFrac = 0.205
    elseif aspect >= 1.5 then
        baseFrac = 0.220
    elseif aspect >= 1.34 then
        baseFrac = 0.240
    else
        baseFrac = 0.260
    end

    local offset = math.floor(w * baseFrac)
    local extra = (1.0 - safe) * w * 0.08
    offset = offset + math.floor(extra) + 12

    local minOffset = math.max(200, math.floor(w * ((w <= 1280 or h <= 720) and 0.15 or 0.16)))
    local maxOffset = math.min(math.floor(w * 0.28), 680)
    if w <= 1024 or h <= 600 then
        minOffset = math.max(minOffset, math.floor(w * 0.14))
    end
    offset = math.max(minOffset, math.min(maxOffset, math.floor(offset)))

    if isMinimapVisible() then
        if w <= 1024 then
            offset = math.max(minOffset, offset - math.floor(w * 0.020))
        elseif w <= 1280 then
            offset = math.max(minOffset, offset - math.floor(w * 0.015))
        elseif w <= 1600 then
            offset = math.max(minOffset, offset - math.floor(w * 0.010))
        end
    end

    local scale = 1.12
    if aspect < 1.6 then scale = 1.08 end
    if aspect < 1.4 then scale = 1.02 end
    if h <= 900 then scale = math.min(scale, 1.10) end
    if h <= 720 then scale = math.min(scale, 1.03) end
    if h <= 600 then scale = math.min(scale, 0.98) end

    local userOffset = getKvpNumber('jp_mch_offset_px')
    local userScale = getKvpNumber('jp_mch_scale')
    if userOffset and userOffset ~= 0 then offset = math.floor(userOffset) end
    if userScale and userScale ~= 0 then scale = tonumber(string.format('%.3f', userScale)) end

    SendNUIMessage({ type = 'setHudLayout', offsetPx = offset, scale = scale })
    lastLayout.w, lastLayout.h, lastLayout.safe = w, h, safe
end

CreateThread(function()
    Wait(1500)
    migrateOldKvp()
    computeAndApplyHudLayout(true)
    while true do
        Wait(2000)
        computeAndApplyHudLayout(false)
    end
end)

RegisterCommand(Config.Commands.ResetLayout, function()
    DeleteResourceKvp('jp_mch_offset_px')
    DeleteResourceKvp('jp_mch_scale')
    DeleteResourceKvp('munlay_hud_offset_px')
    DeleteResourceKvp('munlay_hud_scale')
    computeAndApplyHudLayout(true)
    print(Locale.log.layout_reset)
end, false)

-- ===========================================================
-- ヘルパ：0..100 正規化
-- ===========================================================
local function norm100(v)
    if v == nil then return 0 end
    v = math.max(0.0, math.min(100.0, v + 0.0))
    if v >= 99.0 then return 100 end
    return math.floor(v + 0.5)
end

local function shouldUsePmaVoice()
    if Config.UsePmaVoice == false then return false end
    if Config.UsePmaVoice == true then return true end
    local st = GetResourceState('pma-voice')
    return st == 'started' or st == 'starting'
end

-- ===========================================================
-- メイン Tick：ヘルス／アーマー／スタミナ／空腹／喉／酸素
-- ===========================================================
CreateThread(function()
    Wait(500)
    pushI18n()

    hudData.playerId = GetPlayerServerId(PlayerId())
    SendNUIMessage({ type = 'showHUD', show = true })
    Wait(50)
    SendNUIMessage({ type = 'toggleMoneyHUD', show = hudConfig.showMoney })
    Wait(50)
    SendNUIMessage({ type = 'updateHUD', playerId = hudData.playerId })
    if not hudConfig.showJob then
        SendNUIMessage({
            type = 'updateJob',
            job = { name = 'unemployed', label = '', grade = 0, grade_label = '' },
        })
    end

    local lastVehicle, lastHealth, lastArmor, lastStamina = 0, -1, -1, -1
    local lastHungerSent, lastThirstSent, lastOxygenSent = -1, -1, -1
    local lastShowOxygen = false
    local healthBuffer, bufferSize = {}, 3
    local lastForceTick = GetGameTimer()
    local forceTickMs = 4000

    while true do
        Wait(200)
        local ped = PlayerPedId()

        local cur = GetEntityHealth(ped)
        local health = 0
        if cur > 100 then
            cur = math.max(100, math.min(200, cur))
            health = ((cur - 100) / 100) * 100
        end
        health = math.max(0, math.min(100, health))
        table.insert(healthBuffer, health)
        if #healthBuffer > bufferSize then table.remove(healthBuffer, 1) end
        local sum = 0
        for _, v in ipairs(healthBuffer) do
            sum = sum + v
        end
        local healthInt = norm100(sum / #healthBuffer)

        local armorInt = norm100(GetPedArmour(ped))

        local stamina = 100
        local st = GetPlayerStamina(PlayerId())
        if st then
            stamina = st
        else
            local sprint = GetPlayerSprintStaminaRemaining(PlayerId())
            if sprint then stamina = (sprint <= 10) and (sprint * 10) or sprint end
        end
        local staminaInt = norm100(stamina)

        local isUnderwater = IsPedSwimmingUnderWater(ped)
        local oxygen = 100
        if isUnderwater then
            local uw = GetPlayerUnderwaterTimeRemaining(PlayerId()) or 10.0
            oxygen = math.max(0.0, math.min(10.0, uw)) * 10.0
        end
        local oxygenInt = norm100(oxygen)

        if not useESXStatus then
            hudData.lastHunger = math.max(0, hudData.lastHunger - 0.025)
            hudData.lastThirst = math.max(0, hudData.lastThirst - 0.035)
        end
        local hungerInt = norm100(hudData.lastHunger)
        local thirstInt = norm100(hudData.lastThirst)

        local vehicle = GetVehiclePedIsIn(ped, false)
        local newInVehicle = vehicle ~= 0
        if newInVehicle ~= hudData.inVehicle then
            hudData.inVehicle = newInVehicle
            applyRadarMode()
            SendNUIMessage({ type = 'updateHUD', inVehicle = newInVehicle })
            SendNUIMessage({ type = 'updateVehicle', inVehicle = newInVehicle })
            updateMinimapOffset()
            computeAndApplyHudLayout(true)
        end

        local vitalChanged = (lastHungerSent == -1 or math.abs(hungerInt - lastHungerSent) >= 1)
            or (lastThirstSent == -1 or math.abs(thirstInt - lastThirstSent) >= 1)
            or (lastOxygenSent == -1 or math.abs(oxygenInt - lastOxygenSent) >= 1)
            or (lastShowOxygen ~= isUnderwater)

        if math.abs(healthInt - lastHealth) > 1
            or armorInt ~= lastArmor
            or math.abs(staminaInt - lastStamina) > 2
            or vitalChanged
        then
            lastHealth, lastArmor, lastStamina = healthInt, armorInt, staminaInt
            lastHungerSent, lastThirstSent, lastOxygenSent = hungerInt, thirstInt, oxygenInt
            lastShowOxygen = isUnderwater
            SendNUIMessage({
                type = 'updateHUD',
                health = healthInt,
                armor = armorInt,
                stamina = staminaInt,
                hunger = hungerInt,
                thirst = thirstInt,
                oxygen = oxygenInt,
                showOxygen = isUnderwater,
                talking = hudData.isTalking,
                voiceRange = hudData.voiceRange,
                inVehicle = newInVehicle,
                playerId = hudData.playerId,
            })
        end

        if GetGameTimer() - lastForceTick > forceTickMs then
            lastForceTick = GetGameTimer()
            SendNUIMessage({
                type = 'updateHUD',
                hunger = hungerInt,
                thirst = thirstInt,
                oxygen = oxygenInt,
                showOxygen = isUnderwater,
            })
        end

        if vehicle == 0 and lastVehicle ~= 0 then
            lastVehicle = 0
            SendNUIMessage({ type = 'updateVehicle', inVehicle = false })
        elseif vehicle ~= 0 and vehicle ~= lastVehicle then
            lastVehicle = vehicle
        end
    end
end)

-- ===========================================================
-- ボイス（喋っているか）
-- ===========================================================
CreateThread(function()
    local last = false
    while true do
        Wait(100)
        local t = NetworkIsPlayerTalking(PlayerId())
        if t ~= last then
            last = t
            hudData.isTalking = t
            SendNUIMessage({ type = 'setTalking', talking = t })
        end
    end
end)

-- ===========================================================
-- ボイス距離（pma-voice 互換）
-- ===========================================================
CreateThread(function()
    if not shouldUsePmaVoice() then return end

    local last = hudData.voiceRange or 2
    while true do
        Wait(400)
        local prox = (LocalPlayer and LocalPlayer.state and LocalPlayer.state.proximity) or nil
        local r = last
        if prox then
            local m = prox.mode
            if m == 1 or m == 'whisper' then
                r = 1
            elseif m == 3 or m == 'shout' then
                r = 3
            else
                r = 2
            end
        else
            r = 2
        end
        if r ~= last then
            last = r
            hudData.voiceRange = r
            SendNUIMessage({ type = 'setVoiceRange', range = r })
        end
    end
end)

-- ===========================================================
-- 車両 HUD 更新
-- ===========================================================
CreateThread(function()
    while true do
        Wait(90)
        if hudData.inVehicle then
            local ped = PlayerPedId()
            local v = GetVehiclePedIsIn(ped, false)
            if v ~= 0 then
                local speed = math.floor(GetEntitySpeed(v) * 3.6)
                local fuel = math.floor(GetVehicleFuelLevel(v))
                local engineOn = GetIsVehicleEngineRunning(v)
                local lightsOn, highBeams = GetVehicleLightsState(v)
                local lightsState = 0
                if lightsOn == 1 then lightsState = (highBeams == 1) and 2 or 1 end
                SendNUIMessage({
                    type = 'updateVehicle',
                    inVehicle = true,
                    speed = speed,
                    fuel = fuel,
                    engineOn = engineOn,
                    lights = lightsState,
                    seatbelt = hudData.seatbelt,
                })
            end
        else
            Wait(140)
        end
    end
end)

-- ===========================================================
-- 金銭・職業 HUD（Bridge 経由でフレームワーク非依存）
-- ===========================================================
local function updateMoneyVisibility()
    if hudConfig.showMoney and hudConfig.enableMoneyUpdates then
        SendNUIMessage({ type = 'toggleMoneyOnly', show = true })
        SendNUIMessage({
            type = 'updateMoney',
            cash = hudData.cash,
            bank = hudData.bank,
            black = hudData.black,
        })
    else
        SendNUIMessage({ type = 'toggleMoneyOnly', show = false })
    end
end

local function updateJobVisibility()
    if hudConfig.showJob and hudConfig.enableJobUpdates and hudData.job then
        SendNUIMessage({ type = 'toggleJobOnly', show = true })
        SendNUIMessage({ type = 'updateJob', job = hudData.job })
    else
        SendNUIMessage({ type = 'toggleJobOnly', show = false })
    end
end

local function pullFromBridge()
    if not Bridge or not Bridge.ready then return end
    if hudConfig.enableMoneyUpdates and Bridge.GetMoney then
        local c, b, k = Bridge.GetMoney()
        hudData.cash, hudData.bank, hudData.black = c or 0, b or 0, k or 0
        if hudConfig.showMoney then
            SendNUIMessage({
                type = 'updateMoney',
                cash = hudData.cash,
                bank = hudData.bank,
                black = hudData.black,
            })
        end
    end
    if hudConfig.enableJobUpdates and Bridge.GetJob then
        local j = Bridge.GetJob()
        if j then
            hudData.job = j
            if hudConfig.showJob then SendNUIMessage({ type = 'updateJob', job = j }) end
        end
    end
end

RegisterCommand(Config.Commands.ToggleMoney, function()
    hudData.moneyHudVisible = not hudData.moneyHudVisible
    hudConfig.showMoney = hudData.moneyHudVisible and Config.EnableMoney
    hudConfig.showJob = hudData.moneyHudVisible and Config.EnableJob
    hudConfig.enableMoneyUpdates = Config.EnableMoney
    hudConfig.enableJobUpdates = Config.EnableJob
    if hudData.moneyHudVisible then pullFromBridge() end
    updateMoneyVisibility()
    updateJobVisibility()
end, false)

CreateThread(function()
    Bridge.OnReady(function()
        print(string.format(Locale.log.loaded, Bridge.name))
        Bridge.RegisterUpdates(
            function(c, b, k)
                hudData.cash, hudData.bank, hudData.black = c or 0, b or 0, k or 0
                if hudConfig.enableMoneyUpdates and hudConfig.showMoney then
                    SendNUIMessage({
                        type = 'updateMoney',
                        cash = hudData.cash,
                        bank = hudData.bank,
                        black = hudData.black,
                    })
                end
            end,
            function(j)
                if not j then return end
                hudData.job = j
                if hudConfig.enableJobUpdates and hudConfig.showJob then
                    SendNUIMessage({ type = 'updateJob', job = j })
                end
            end
        )
        Wait(800)
        pullFromBridge()
    end)
end)

-- ===========================================================
-- ミニマップ ON/OFF（FiveM ネイティブ HUD は他リソースに任せる）
-- ===========================================================
CreateThread(function()
    while true do
        Wait(0)
        if radarMode == 'force_on' then
            DisplayRadar(true)
        elseif radarMode == 'force_off' then
            DisplayRadar(false)
        else
            DisplayRadar(hudData.inVehicle)
        end
    end
end)

CreateThread(function()
    local minimap = RequestScaleformMovie('minimap')
    while not HasScaleformMovieLoaded(minimap) do
        Wait(0)
    end
    SetRadarBigmapEnabled(true, false)
    Wait(0)
    SetRadarBigmapEnabled(false, false)
    while true do
        Wait(0)
        if not HasScaleformMovieLoaded(minimap) then
            minimap = RequestScaleformMovie('minimap')
            while not HasScaleformMovieLoaded(minimap) do
                Wait(0)
            end
            SetRadarBigmapEnabled(true, false)
            Wait(0)
            SetRadarBigmapEnabled(false, false)
        end
        BeginScaleformMovieMethod(minimap, 'SETUP_HEALTH_ARMOUR')
        ScaleformMovieMethodAddParamInt(3)
        EndScaleformMovieMethod()
    end
end)

CreateThread(function()
    Wait(800)
    applyRadarMode()
    updateMinimapOffset()
    Wait(1200)
    if hudConfig.enableMoneyUpdates and hudConfig.showMoney then
        SendNUIMessage({ type = 'updateMoney', cash = 0, bank = 0, black = 0 })
    end
    if hudConfig.enableJobUpdates and hudConfig.showJob then
        SendNUIMessage({
            type = 'updateJob',
            job = {
                name = 'unemployed',
                label = Locale.ui.unemployed,
                grade = 0,
                grade_label = Locale.ui.no_grade,
            },
        })
    end
end)

-- ===========================================================
-- esx_status（任意）
-- ===========================================================
CreateThread(function()
    if Config.UseEsxStatus == false then return end

    local function findRes()
        local n = (GetNumResources and GetNumResources()) or 0
        for i = 0, n - 1 do
            local r = GetResourceByFindIndex(i)
            if r and string.find(r, 'esx_status', 1, true) then return r end
        end
        return 'esx_status'
    end

    local res = findRes()
    local waited = 0
    while (GetResourceState(res) == 'missing' or GetResourceState(res) == 'stopped') and waited < 20 do
        Wait(500)
        waited = waited + 1
    end
    if GetResourceState(res) ~= 'started' then
        print(Locale.log.esx_status_none)
        return
    end

    useESXStatus = true
    print(Locale.log.esx_status_ok)

    local function pct(s)
        if not s then return nil end
        if type(s.percent) == 'number' then return s.percent end
        if type(s.getPercent) == 'function' then
            local ok, p = pcall(s.getPercent, s)
            if ok and type(p) == 'number' then return p end
        end
        if type(s.val) == 'number' and type(s.max) == 'number' and s.max > 0 then
            return (s.val / s.max) * 100.0
        end
        return nil
    end

    local lastTick = 0
    local function apply(h, t)
        local changed = false
        if h ~= nil and h ~= hudData.lastHunger then
            hudData.lastHunger = h
            changed = true
        end
        if t ~= nil and t ~= hudData.lastThirst then
            hudData.lastThirst = t
            changed = true
        end
        if changed then
            SendNUIMessage({
                type = 'updateHUD',
                hunger = norm100(hudData.lastHunger),
                thirst = norm100(hudData.lastThirst),
            })
            lastTick = GetGameTimer()
        end
    end

    RegisterNetEvent('esx_status:onTick', function(status)
        local h, t
        if type(status) == 'table' then
            local arr = (#status > 0) and status or status
            for _, st in pairs(arr) do
                if st and (st.name == 'hunger' or st.name == 'food') then h = pct(st) end
                if st and st.name == 'thirst' then t = pct(st) end
            end
        end
        apply(h, t)
    end)

    CreateThread(function()
        while true do
            Wait(1200)
            if GetGameTimer() - lastTick > 1500 then
                local h, t
                TriggerEvent('esx_status:getStatus', 'hunger', function(s) h = pct(s) end)
                TriggerEvent('esx_status:getStatus', 'thirst', function(s) t = pct(s) end)
                Wait(50)
                apply(h, t)
            end
        end
    end)
end)

-- ===========================================================
-- exports（外部リソースから呼ばれる API）
-- ===========================================================
exports('SeatbeltState', function(state)
    hudData.seatbelt = state
    if hudData.inVehicle then
        SendNUIMessage({ type = 'updateVehicle', seatbelt = state })
    end
end)

exports('CruiseControlState', function(state)
    SendNUIMessage({ type = 'updateVehicle', cruiseControl = state })
end)

exports('SetMoneyHudVisible', function(visible)
    hudConfig.showMoney = visible and Config.EnableMoney
    hudConfig.enableMoneyUpdates = Config.EnableMoney
    updateMoneyVisibility()
end)

exports('SetJobHudVisible', function(visible)
    hudConfig.showJob = visible and Config.EnableJob
    hudConfig.enableJobUpdates = Config.EnableJob
    updateJobVisibility()
end)

exports('SetMoneyJobHudVisible', function(visible)
    hudConfig.showMoney = visible and Config.EnableMoney
    hudConfig.showJob = visible and Config.EnableJob
    hudConfig.enableMoneyUpdates = Config.EnableMoney
    hudConfig.enableJobUpdates = Config.EnableJob
    updateMoneyVisibility()
    updateJobVisibility()
end)

exports('GetHudConfig', function()
    return hudConfig
end)

exports('GetFramework', function()
    return Bridge and Bridge.name or 'unknown'
end)

RegisterCommand(Config.Commands.ToggleMinimap, function()
    local visible = isMinimapVisible()
    radarMode = visible and 'force_off' or 'force_on'
    applyRadarMode()
    updateMinimapOffset()
    computeAndApplyHudLayout(true)
end, false)
