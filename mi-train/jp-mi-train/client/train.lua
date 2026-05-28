-- jp-mi-train クライアント側: 列車スポーン・ループ走行制御
-- 責務:
--   1. レール環境のセットアップ（既存トラフィック退避）
--   2. CreateMissionTrain でヘイスト用列車を生成
--   3. SetTrainCruiseSpeed でループ走行（Track 0 = LS 一周 47.8km）
--   4. 運転手 NPC を運転席に配置（戦闘逃走防止）
--   5. クリーンアップ時にレール環境を復元
-- 設計参考: TheNickoos/FiveM-Trains client.lua（CreateMissionTrain + 速度 + 待機）

---@class TrainModule
local M = {}

---@type integer|nil 現在のヘイスト列車（機関車）エンティティ
M.train = nil

---@type integer|nil 運転手 NPC エンティティ
M.driver = nil

---@type table<integer, integer> wagons[1] = 機関車, wagons[2..] = 客車（インデックスは GetTrainCarriage に対応）
M.wagons = {}

---@type integer|nil 最後尾 wagon（ヘリ侵入判定で使う）
M.lastWagon = nil

---@type boolean ホスト権限を持っているか
M.isHost = false

---@type boolean CreateMissionTrain 用モデルを先読み済みか
local trainModelsReady = false

-- ============================================================
-- ロガー
-- ============================================================

---@param msg string
local function log(msg)
    if Config.Debug then
        print(('[%s/train] %s'):format(GetCurrentResourceName(), msg))
    end
end

-- ============================================================
-- レール環境セットアップ／復元
-- ============================================================

local function PrepareTrack()
    if Config.Heist.disableRandomTrainsDuringHeist then
        DeleteAllTrains()
        SetRandomTrains(false)
        -- Track 0 = 貨物レール、Track 3 = メトロレール
        SwitchTrainTrack(0, false)
        SwitchTrainTrack(3, false)
        SetTrainsForceDoorsOpen(false)
        log('track prepared (random trains disabled)')
    end
end

local function RestoreTrack()
    if Config.Heist.disableRandomTrainsDuringHeist then
        SetRandomTrains(true)
        SwitchTrainTrack(0, true)
        SwitchTrainTrack(3, true)
        log('track restored')
    end
end

-- ============================================================
-- 列車モデル先読み（CreateMissionTrain 必須）
-- ============================================================

--- variation 0 は freightcont2 (hash 1030400667) 等を含む。未ロードだと即失敗する。
---@return boolean success
local function EnsureTrainModelsLoaded()
    if trainModelsReady then
        return true
    end

    local models = Config.Train.preloadModels
    if not models or #models == 0 then
        log('ERROR: Config.Train.preloadModels is empty')
        return false
    end

    local timeout = Config.Train.modelLoadTimeoutMs or 15000
    log(('loading %d train models (timeout=%dms each)...'):format(#models, timeout))

    for _, name in ipairs(models) do
        local hash = joaat(name)
        if not IsModelInCdimage(hash) or not IsModelValid(hash) then
            log(('WARN: model not in cdimage: %s (hash=%s)'):format(name, hash))
        else
            RequestModel(hash)
            local deadline = GetGameTimer() + timeout
            while not HasModelLoaded(hash) and GetGameTimer() < deadline do
                RequestModel(hash)
                Wait(0)
            end
            if not HasModelLoaded(hash) then
                log(('ERROR: failed to load model: %s (hash=%s)'):format(name, hash))
                return false
            end
            log(('loaded: %s'):format(name))
        end
    end

    trainModelsReady = true
    log('all train models ready')
    return true
end

-- ============================================================
-- 座標 broadcast（Blip 用）— Spawn より前に定義すること
-- ============================================================

--- 編成ハンドルを再スキャン（走行中に DoesEntityExist(機関車) が false になることがある）
function M.RefreshWagonHandles()
    if not M.train then
        return
    end

    -- add-on 客車が有効なら最後尾は addon を維持（GetTrainCarriage で上書きしない）
    if _G.MiTrainAddon and _G.MiTrainAddon.IsActive() then
        M.lastWagon = _G.MiTrainAddon.GetEntity()
        return
    end

    if DoesEntityExist(M.train) then
        M.wagons = { M.train }
        for i = 1, 10 do
            local carriage = GetTrainCarriage(M.train, i)
            if carriage and carriage ~= 0 and DoesEntityExist(carriage) then
                M.wagons[#M.wagons + 1] = carriage
            else
                break
            end
        end
        M.lastWagon = M.wagons[#M.wagons]
        return
    end

    local survivors = {}
    for _, w in ipairs(M.wagons) do
        if w and w ~= 0 and DoesEntityExist(w) then
            survivors[#survivors + 1] = w
        end
    end
    if #survivors > 0 then
        M.wagons = survivors
        M.lastWagon = survivors[#survivors]
    end
end

---@return vector3|nil trainCoords
---@return integer|nil locomotiveEntity
---@return integer|nil lastEntity
local function GetBroadcastEntities()
    M.RefreshWagonHandles()

    local loco = (M.train and M.train ~= 0 and DoesEntityExist(M.train)) and M.train or nil
    local last = (M.lastWagon and M.lastWagon ~= 0 and DoesEntityExist(M.lastWagon)) and M.lastWagon or nil

    if not loco and not last then
        for i = #M.wagons, 1, -1 do
            local w = M.wagons[i]
            if w and w ~= 0 and DoesEntityExist(w) then
                last = w
                break
            end
        end
    end

    if not loco and not last then
        return nil, nil, nil
    end

    local tc
    if loco then
        tc = GetEntityCoords(loco)
    else
        tc = GetEntityCoords(last)
    end

    return tc, loco, last
end

local lastBroadcastSkipLogAt = 0

local function BroadcastTrainCoords()
    local tc, loco, last = GetBroadcastEntities()
    if not tc then
        if Config.Debug then
            local now = GetGameTimer()
            if now - lastBroadcastSkipLogAt > 5000 then
                lastBroadcastSkipLogAt = now
                log('BroadcastTrainCoords skipped: no train entities')
            end
        end
        return
    end

    local hasLast = last ~= nil
    local lx, ly, lz = 0.0, 0.0, 0.0
    if hasLast then
        local lc = GetEntityCoords(last)
        lx, ly, lz = lc.x, lc.y, lc.z
    else
        lx, ly, lz = tc.x, tc.y, tc.z
        hasLast = true
    end

    if _G.MiTrainBlip then
        if M.isHost and (loco or last) then
            _G.MiTrainBlip.UpdateHostEntities(loco, last)
        else
            _G.MiTrainBlip.Update(tc, hasLast and vector3(lx, ly, lz) or nil)
        end
    end

    TriggerServerEvent('jp-mi-train:reportTrainCoords', tc.x, tc.y, tc.z, hasLast, lx, ly, lz)
end

-- ============================================================
-- 列車スポーン（ホストのみ呼び出す）
-- ============================================================

---@return boolean success
function M.Spawn()
    if M.train and DoesEntityExist(M.train) then
        log('spawn called but train already exists')
        return true
    end

    PrepareTrack()

    if not EnsureTrainModelsLoaded() then
        log('ERROR: train models not loaded — aborting spawn')
        RestoreTrack()
        lib.notify({
            type = 'error',
            title = 'MI Train',
            description = '列車モデルの読み込みに失敗しました。F8 で [jp-mi-train/train] を確認してください。',
            duration = 10000,
        })
        return false
    end

    -- 列車を生成
    local spawn = Config.Train.spawn
    log(('CreateMissionTrain variation=%d at (%.1f, %.1f, %.1f)')
        :format(Config.Train.variation, spawn.x, spawn.y, spawn.z))

    -- Nickoos 同様: レール準備直後に少し待つ
    Wait(100)

    local train = CreateMissionTrain(
        Config.Train.variation,
        spawn.x, spawn.y, spawn.z,
        Config.Train.direction
    )

    -- スポーン完了待ち（Nickoos は 800ms 間隔でポーリング）
    local deadline = GetGameTimer() + Config.Train.spawnTimeoutMs
    while not DoesEntityExist(train) and GetGameTimer() < deadline do
        Wait(800)
        if Config.Debug then
            log('waiting for mission train entity...')
        end
    end

    if not DoesEntityExist(train) then
        log('ERROR: train spawn timed out (check F8 for carriage hash warnings)')
        RestoreTrack()
        lib.notify({
            type = 'error',
            title = 'MI Train',
            description = '列車の生成に失敗しました。ensure を再起動するか、variation を変更して再試行してください。',
            duration = 10000,
        })
        return false
    end

    M.train = train

    -- 編成が揃うまで少し待つ（貨車の GetTrainCarriage が遅延することがある）
    Wait(200)

    -- 走行設定
    SetTrainCruiseSpeed(train, Config.Train.cruiseSpeed)
    SetEntityAsMissionEntity(train, true, true)
    SetEntityInvincible(train, true)

    -- 各車両ハンドルを取得（最大 10 両、編成長は variation 依存）
    M.wagons = { train }
    for i = 1, 10 do
        local carriage = GetTrainCarriage(train, i)
        if carriage and carriage ~= 0 and DoesEntityExist(carriage) then
            SetEntityAsMissionEntity(carriage, true, true)
            SetEntityInvincible(carriage, true)
            M.wagons[#M.wagons + 1] = carriage
        else
            break
        end
    end
    M.lastWagon = M.wagons[#M.wagons]

    log(('train spawned: %d wagons, lastWagon entity=%d'):format(#M.wagons, M.lastWagon or 0))

    local minWagons = Config.Train.minWagonCount or 2
    if #M.wagons < minWagons then
        log(('ERROR: insufficient wagons (%d < %d)'):format(#M.wagons, minWagons))
        if M.train and DoesEntityExist(M.train) then
            DeleteMissionTrain(M.train)
        end
        M.train = nil
        M.wagons = {}
        M.lastWagon = nil
        RestoreTrack()
        lib.notify({
            type = 'error',
            title = 'MI Train',
            description = '列車編成の生成が不完全です。F8 の carriage hash 警告を確認してください。',
            duration = 10000,
        })
        return false
    end

    -- 運転手 NPC を運転席に
    M.SpawnDriver()

    -- Phase 2: DBuz747 等を最後尾 freight に attach
    if _G.MiTrainAddon and M.lastWagon then
        if _G.MiTrainAddon.SpawnAndAttach(M.lastWagon) then
            local addon = _G.MiTrainAddon.GetEntity()
            if addon then
                M.lastWagon = addon
                log(('addon carriage is new lastWagon entity=%d'):format(addon))
            end
        end
    end

    -- スポーン直後に即 Blip 更新（coordsLive を有効化）
    BroadcastTrainCoords()
    TriggerServerEvent('jp-mi-train:hostReportSpawnOk', #M.wagons)

    return true
end

---@return boolean success
function M.SpawnDriver()
    if not M.train or not DoesEntityExist(M.train) then return false end

    local model = joaat(Config.Train.driver.model)
    lib.requestModel(model, 5000)

    -- seatIndex = -1 で運転席に配置
    local driver = CreatePedInsideVehicle(M.train, 26, model, -1, true, true)
    if not driver or driver == 0 then
        log('ERROR: failed to create driver ped')
        SetModelAsNoLongerNeeded(model)
        return false
    end

    SetEntityAsMissionEntity(driver, true, true)
    SetBlockingOfNonTemporaryEvents(driver, true)
    SetPedFleeAttributes(driver, 0, false)
    SetPedCombatAttributes(driver, 17, true)  -- AlwaysFight
    if Config.Train.driver.invincible then
        SetEntityInvincible(driver, true)
    end
    SetEntityCanBeDamaged(driver, false)
    SetPedCanBeDraggedOut(driver, false)
    SetPedCanBeTargetted(driver, false)

    M.driver = driver
    SetModelAsNoLongerNeeded(model)
    log(('driver ped spawned: entity=%d'):format(driver))
    return true
end

-- ============================================================
-- アニメ中の一時停止 API（Phase 2 用、現状は heli_board からは未使用）
-- ============================================================

---@param durationMs integer 停止維持時間
function M.PauseForAnimation(durationMs)
    if not M.train or not DoesEntityExist(M.train) then return end

    -- 所有権を取得
    if not NetworkHasControlOfEntity(M.train) then
        NetworkRequestControlOfEntity(M.train)
        local t = GetGameTimer() + 2000
        while not NetworkHasControlOfEntity(M.train) and GetGameTimer() < t do
            Wait(50)
        end
    end

    SetTrainCruiseSpeed(M.train, 0.0)
    -- 実速度が落ちきるまで待機（最大 5 秒）
    local t = GetGameTimer() + 5000
    while GetEntitySpeed(M.train) > 0.1 and GetGameTimer() < t do
        Wait(50)
    end

    Wait(durationMs)

    if DoesEntityExist(M.train) then
        SetTrainCruiseSpeed(M.train, Config.Train.cruiseSpeed)
    end
end

-- ============================================================
-- ループ走行維持スレッド（ホスト中だけ動く）
-- ============================================================

-- 列車が SetTrainCruiseSpeed を一度設定すれば Track 0 を周回し続ける。
-- ただしストリーミングで列車エンティティが unload されることがあるので、
-- ホスト側で定期的に「列車がまだ存在するか」をチェックする。

local function StartMaintenanceLoop()
    local loopStartedAt = GetGameTimer()
    local existMissCount = 0

    -- メンテナンス（所有権・速度復元・列車消失検知）。2 秒間隔
    Citizen.CreateThread(function()
        while M.isHost and M.train do
            Wait(2000)

            -- CreateMissionTrain は DoesEntityExist が一時的に false になることがある
            if GetGameTimer() - loopStartedAt > Config.Heist.trainLostGraceMs then
                if not DoesEntityExist(M.train) then
                    existMissCount = existMissCount + 1
                    if existMissCount >= Config.Heist.trainLostMissCount then
                        log('WARNING: train entity lost after repeated checks')
                        TriggerServerEvent('jp-mi-train:hostReportEnd', 'train_lost')
                        break
                    end
                else
                    existMissCount = 0
                end
            end

            M.RefreshWagonHandles()

            if _G.MiTrainAddon then
                _G.MiTrainAddon.MaintainAttach()
            end

            local speedEntity = M.train
            if not speedEntity or not DoesEntityExist(speedEntity) then
                speedEntity = M.lastWagon
            end

            if speedEntity and DoesEntityExist(speedEntity) then
                if not NetworkHasControlOfEntity(speedEntity) then
                    NetworkRequestControlOfEntity(speedEntity)
                end
                if M.train and DoesEntityExist(M.train) and not NetworkHasControlOfEntity(M.train) then
                    NetworkRequestControlOfEntity(M.train)
                end

                local currentSpeed = GetEntitySpeed(speedEntity)
                if currentSpeed < (Config.Train.cruiseSpeed * 0.3) then
                    if M.train and DoesEntityExist(M.train) then
                        SetTrainCruiseSpeed(M.train, Config.Train.cruiseSpeed)
                    end
                    if Config.Debug then
                        log(('speed restored (was %.1f, target %.1f)')
                            :format(currentSpeed, Config.Train.cruiseSpeed))
                    end
                end
            end
        end
    end)

    -- 座標 broadcast 用スレッド（独立、1 秒間隔）
    Citizen.CreateThread(function()
        while M.isHost and M.train do
            BroadcastTrainCoords()
            Wait(Config.Blip.updateIntervalMs)
        end
    end)
end

-- ============================================================
-- クリーンアップ
-- ============================================================

function M.Cleanup()
    log('cleanup called')

    if _G.MiTrainAddon then
        _G.MiTrainAddon.Cleanup()
    end

    if M.driver and DoesEntityExist(M.driver) then
        if not NetworkHasControlOfEntity(M.driver) then
            NetworkRequestControlOfEntity(M.driver)
            local t = GetGameTimer() + 1000
            while not NetworkHasControlOfEntity(M.driver) and GetGameTimer() < t do Wait(50) end
        end
        DeleteEntity(M.driver)
    end
    M.driver = nil

    if M.train and DoesEntityExist(M.train) then
        if not NetworkHasControlOfEntity(M.train) then
            NetworkRequestControlOfEntity(M.train)
            local t = GetGameTimer() + 1500
            while not NetworkHasControlOfEntity(M.train) and GetGameTimer() < t do Wait(50) end
        end
        DeleteMissionTrain(M.train)
    end
    M.train = nil
    M.wagons = {}
    M.lastWagon = nil

    M.isHost = false
    RestoreTrack()
end

-- ============================================================
-- ホスト昇格
-- ============================================================

function M.BecomeHost()
    M.isHost = true
    log('became host')
    Citizen.CreateThread(function()
        if M.Spawn() then
            StartMaintenanceLoop()
        else
            TriggerServerEvent('jp-mi-train:hostReportEnd', 'spawn_failed')
        end
    end)
end

-- リソース起動時にモデルを先読み（ヘイスト開始直後のスポーン失敗を防ぐ）
if Config.Train.preloadOnStart then
    Citizen.CreateThread(function()
        Wait(2000)
        EnsureTrainModelsLoaded()
    end)
end

-- ============================================================
-- exports（他クライアントモジュール用）
-- ============================================================

exports('GetLastWagon', function()
    if _G.MiTrainAddon then
        local addon = _G.MiTrainAddon.GetEntity()
        if addon then
            return addon
        end
    end
    if M.lastWagon and DoesEntityExist(M.lastWagon) then
        return M.lastWagon
    end
    return nil
end)

exports('GetTrain', function()
    if M.train and DoesEntityExist(M.train) then
        return M.train
    end
    return nil
end)

exports('IsHost', function()
    return M.isHost
end)

-- グローバル参照（同一リソース内の他ファイルから直接呼ぶ用）
_G.MiTrain = M
