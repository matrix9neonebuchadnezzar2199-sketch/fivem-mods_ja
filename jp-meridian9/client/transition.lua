-- ============================================================
-- jp-meridian9 / client/transition.lua
-- ============================================================
-- 次元転送・サイト・ナイン演出（最小実装）。
-- 本格演出は INSTRUCTION-017 で拡張予定。
-- ============================================================

MRD9 = MRD9 or {}
MRD9.Transition = MRD9.Transition or {}

local State = {
    active = false,
    appliedModifier = nil,
    appliedBlackout = false,
    nyEnabled = false,
    cayoEnabled = false,
    thunderRunning = false,
    weatherKeeperRunning = false,
}

---@return table
local function cfg()
    return Config.SiteNine or {}
end

local function applyClockOverride()
    local c = cfg()
    if not c.timeFreeze then
        return
    end
    local h = tonumber(c.timeHour) or 3
    local m = tonumber(c.timeMinute) or 0
    NetworkOverrideClockTime(h, m, 0)
end

local function clearClockOverride()
    NetworkClearClockTimeOverride()
end

local function applyWeather()
    local c = cfg()
    local w = c.weather
    if type(w) ~= 'string' or w == '' then
        return
    end
    SetWeatherTypeNowPersist(w)
    SetWeatherTypeNow(w)
    SetOverrideWeather(w)
end

local function clearWeather()
    ClearOverrideWeather()
    ClearWeatherTypePersist()
end

local function applyTimecycle()
    local c = cfg()
    local m = c.timecycleModifier
    if type(m) ~= 'string' or m == '' then
        return
    end
    SetTimecycleModifier(m)
    local s = tonumber(c.timecycleStrength)
    if s and s >= 0.0 and s <= 1.0 then
        SetTimecycleModifierStrength(s)
    end
    State.appliedModifier = m
end

local function clearTimecycle()
    if State.appliedModifier then
        ClearTimecycleModifier()
        State.appliedModifier = nil
    end
end

local function applyBlackout()
    if cfg().blackout then
        SetArtificialLightsState(true)
        State.appliedBlackout = true
    end
end

local function clearBlackout()
    if State.appliedBlackout then
        SetArtificialLightsState(false)
        State.appliedBlackout = false
    end
end

-- 雪天候に雷を重ねる補助スレッド。
-- GTA V には『雷+雪』専用 weather が無いため、雪天候上で ForceLightningFlash と
-- 雷鳴サウンドを定期発火して雷光・雷鳴を演出する。
local function startThunderLoop()
    if State.thunderRunning then
        return
    end
    State.thunderRunning = true
    CreateThread(function()
        local c = cfg()
        local minMs = tonumber(c.thunderIntervalMinMs) or 8000
        local maxMs = tonumber(c.thunderIntervalMaxMs) or 20000
        if maxMs < minMs then maxMs = minMs + 1000 end
        Wait(math.random(2000, 5000))  -- 最初の雷まで短め
        while State.thunderRunning and State.active do
            pcall(function() ForceLightningFlash() end)
            -- 雷鳴サウンド（視覚フラッシュと同時に音を出す）
            pcall(function()
                PlaySoundFrontend(-1, 'LIGHTNING_STRIKE', 'Stunt_Race_Sounds', false)
            end)
            Wait(math.random(minMs, maxMs))
        end
        State.thunderRunning = false
    end)
end

local function stopThunderLoop()
    State.thunderRunning = false
end

-- 天気維持スレッド：他リソース（qbx 系・mapmanager 等）が天気を上書きするのに対抗。
-- weatherKeeperMs ごとに SetOverrideWeather / SetWeatherTypeNowPersist を再呼出。
local function startWeatherKeeper()
    if State.weatherKeeperRunning then
        return
    end
    State.weatherKeeperRunning = true
    CreateThread(function()
        local intervalMs = tonumber(cfg().weatherKeeperMs) or 5000
        while State.weatherKeeperRunning and State.active do
            Wait(intervalMs)
            local w = cfg().weather
            if type(w) == 'string' and w ~= '' then
                pcall(function() SetWeatherTypeNowPersist(w) end)
                pcall(function() SetOverrideWeather(w) end)
            end
        end
        State.weatherKeeperRunning = false
    end)
end

local function stopWeatherKeeper()
    State.weatherKeeperRunning = false
end

---@return table|nil
local function getNorthYanktonObject()
    if GetResourceState('bob74_ipl') ~= 'started' then
        return nil
    end
    local ok, NY = pcall(function()
        return exports['bob74_ipl']:GetNorthYanktonObject()
    end)
    if not ok or type(NY) ~= 'table' then
        return nil
    end
    return NY
end

---bob74_ipl が登録した North Yankton 用 IPL リストの全アクティブ化を待つ。
---`NorthYankton.Enable(true)` は内部で `RequestIpl` を発射するだけで非同期。
---`IsIplActive` で 1 個ずつ確認し、全て active になるまでブロックする。
---@param iplList table
---@param timeoutMs integer
---@return boolean
local function waitIplsActive(iplList, timeoutMs)
    if type(iplList) ~= 'table' then
        return false
    end
    local deadline = GetGameTimer() + (timeoutMs or 15000)
    while GetGameTimer() < deadline do
        local allActive = true
        for _, ipl in ipairs(iplList) do
            if type(ipl) == 'string' and ipl ~= '' and not IsIplActive(ipl) then
                allActive = false
                break
            end
        end
        if allActive then
            return true
        end
        Wait(50)
    end
    return false
end

---@return boolean
local function applyNorthYankton()
    local c = cfg()
    if c.northYankton == false then
        return false
    end
    local NY = getNorthYanktonObject()
    if not NY or type(NY.Enable) ~= 'function' then
        MRD9.Log('NorthYankton: bob74_ipl の NorthYankton オブジェクトが取得できません。スキップ')
        return false
    end
    NY.Enable(true)
    if NY.Grave and NY.Grave.Set then
        local key = c.graveStyle
        if type(key) == 'string' and NY.Grave[key] then
            NY.Grave.Set(NY.Grave[key])
        end
    end
    if NY.Traffic and type(NY.Traffic.Enable) == 'function' then
        NY.Traffic.Enable(c.traffic == true)
    end
    State.nyEnabled = true
    return true
end

local function clearNorthYankton()
    if not State.nyEnabled then
        return
    end
    local NY = getNorthYanktonObject()
    if NY and type(NY.Enable) == 'function' then
        NY.Enable(false)
    end
    State.nyEnabled = false
end

---@return boolean
local function applyCayoPerico()
    -- INSTRUCTION-020 v3 / INSTRUCTION-021 確定運用:
    -- Cayo Perico は **client/main.lua のリソース起動時に SetIslandEnabled(true) で
    -- 常時 ON 固定**。SetIslandEnabled の動的 OFF は GTA V ストリーミングエンジン上で
    -- LS のメモリリーク・読み込み失敗を引き起こすため、Disable しない運用に確定。
    -- 任務 bucket 分離は天気・時間・タイムサイクル・街灯のみ。地形は共通。
    -- 排他で北ヤンクトンが ON のままなら念のため OFF にする。
    if State.nyEnabled then
        clearNorthYankton()
    end
    State.cayoEnabled = true
    return true
end

local function clearCayoPerico()
    -- 常時 ON 運用のため何もしない。State だけリセット。
    State.cayoEnabled = false
end

---@return boolean
local function applyIsland()
    local c = cfg()
    local key = c.island
    if key == 'cayoperico' then
        return applyCayoPerico()
    elseif key == 'northYankton' then
        return applyNorthYankton()
    end
    return false
end

local function clearIsland()
    clearCayoPerico()
    clearNorthYankton()
end

---@return nil
function MRD9.Transition.Enter()
    if State.active then
        return
    end
    State.active = true

    -- INSTRUCTION-020 v3: Config.SiteNine.island に応じて Cayo Perico / 北ヤンクトンを Enable
    -- いずれもクライアントローカル。Cayo Perico は SetIslandEnabled、北ヤンクトンは bob74_ipl 経由。
    -- 実際の同期ロード待ちは TeleportToSiteNine() で行う。
    applyIsland()

    applyClockOverride()
    applyWeather()
    applyTimecycle()
    applyBlackout()
end

---@param sp vector4|{ x: number, y: number, z: number, w: number|nil }
---@return boolean
function MRD9.Transition.TeleportToSiteNine(sp)
    if type(sp) ~= 'table' and type(sp) ~= 'vector4' then
        return false
    end
    local x, y, z = tonumber(sp.x), tonumber(sp.y), tonumber(sp.z)
    local w = tonumber(sp.w) or 0.0
    if not x or not y or not z then
        return false
    end

    -- (1) フェードアウト + プレイヤーを安全状態に
    DoScreenFadeOut(500)
    local fadeDeadline = GetGameTimer() + 1500
    while not IsScreenFadedOut() and GetGameTimer() < fadeDeadline do
        Wait(0)
    end

    local ped = PlayerPedId()
    SetPlayerControl(PlayerId(), false, 0)
    SetEntityVisible(ped, false, false)
    FreezeEntityPosition(ped, true)
    SetEntityCollision(ped, false, false)
    SetEntityInvincible(ped, true)

    -- (2) 先にプレイヤー座標を目的地へ移動。
    -- プレイヤー位置を更新することでストリーミングエンジンの注目点を切替える。
    SetEntityCoords(ped, x + 0.0, y + 0.0, z + 200.0, false, false, false, false)
    Wait(200)

    -- (3) MAP 固有のロード待ち（IPL active）
    local islandKey = (cfg().island or 'cayoperico')
    if islandKey == 'northYankton' then
        local NY = getNorthYanktonObject()
        if NY and type(NY.ipl) == 'table' then
            local ok = waitIplsActive(NY.ipl, 15000)
            print(('[jp-meridian9] TeleportToSiteNine: NY IPL active=%s (count=%d)'):format(tostring(ok), #NY.ipl))
        end
    end

    -- (4) ymap/ybn ストリーミング待ち
    RequestCollisionAtCoord(x + 0.0, y + 0.0, z + 0.0)
    NewLoadSceneStart(x + 0.0, y + 0.0, z + 0.0, 0.0, 0.0, 0.0, 50.0, 0)
    local sceneStart = GetGameTimer()
    local sceneDeadline = sceneStart + 12000
    while not IsNewLoadSceneLoaded() and GetGameTimer() < sceneDeadline do
        RequestCollisionAtCoord(x + 0.0, y + 0.0, z + 0.0)
        Wait(0)
    end
    NewLoadSceneStop()
    print(('[jp-meridian9] TeleportToSiteNine: NewLoadSceneLoaded after %dms'):format(GetGameTimer() - sceneStart))

    -- (5) 地面 Z 検出
    local groundFound, groundZ = false, nil
    local groundDeadline = GetGameTimer() + 10000
    while GetGameTimer() < groundDeadline do
        local f, gz = GetGroundZFor_3dCoord(x + 0.0, y + 0.0, 300.0, false)
        if f and gz and gz > -50.0 and gz < 500.0 then
            groundFound = true
            groundZ = gz
            break
        end
        RequestCollisionAtCoord(x + 0.0, y + 0.0, 200.0)
        Wait(100)
    end
    local finalZ = z
    if groundFound and groundZ then
        finalZ = groundZ + 1.0
        print(('[jp-meridian9] TeleportToSiteNine: ground Z = %.3f -> teleport Z = %.3f'):format(groundZ, finalZ))
    else
        print('[jp-meridian9] TeleportToSiteNine: ground Z not found within 10s. Using config Z')
    end

    -- (6) 最終テレポート（正確な地表 Z へ）
    SetEntityCoords(ped, x + 0.0, y + 0.0, finalZ, false, false, false, false)
    SetEntityHeading(ped, w)

    -- (7) コリジョン最終待機
    local colDeadline = GetGameTimer() + 5000
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < colDeadline do
        RequestCollisionAtCoord(x + 0.0, y + 0.0, finalZ)
        Wait(0)
    end

    Wait(500)

    SetEntityCollision(ped, true, true)
    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, false)
    SetEntityInvincible(ped, false)
    SetPlayerControl(PlayerId(), true, 0)

    DoScreenFadeIn(1000)
    return true
end

---@param rp vector4|{ x: number, y: number, z: number, w: number|nil }
---@return boolean
function MRD9.Transition.TeleportToLosSantos(rp)
    if type(rp) ~= 'table' and type(rp) ~= 'vector4' then
        return false
    end
    local x, y, z = tonumber(rp.x), tonumber(rp.y), tonumber(rp.z)
    local w = tonumber(rp.w) or 0.0
    if not x or not y or not z then
        return false
    end

    -- (1) フェードアウト + プレイヤー安全化
    DoScreenFadeOut(500)
    local fadeDeadline = GetGameTimer() + 1500
    while not IsScreenFadedOut() and GetGameTimer() < fadeDeadline do
        Wait(0)
    end

    local ped = PlayerPedId()
    SetPlayerControl(PlayerId(), false, 0)
    SetEntityVisible(ped, false, false)
    FreezeEntityPosition(ped, true)
    SetEntityCollision(ped, false, false)
    SetEntityInvincible(ped, true)

    -- (2) 先にプレイヤーを LS 座標へ移動。Island を破棄する前にプレイヤー位置を移すことで、
    -- ストリーミングエンジンが LS の ymap/ybn を先読みし始める。
    SetEntityCoords(ped, x + 0.0, y + 0.0, z + 200.0, false, false, false, false)
    Wait(200)

    -- (3) Cayo Perico / 北ヤンクトンの地形・ミニマップを無効化
    MRD9.Transition.Leave()

    -- (4) 破棄反映を待ってから LS のシーンロード開始
    Wait(800)

    RequestCollisionAtCoord(x + 0.0, y + 0.0, z + 0.0)
    NewLoadSceneStart(x + 0.0, y + 0.0, z + 0.0, 0.0, 0.0, 0.0, 50.0, 0)
    local sceneStart = GetGameTimer()
    local sceneDeadline = sceneStart + 12000
    while not IsNewLoadSceneLoaded() and GetGameTimer() < sceneDeadline do
        RequestCollisionAtCoord(x + 0.0, y + 0.0, z + 0.0)
        Wait(0)
    end
    NewLoadSceneStop()
    print(('[jp-meridian9] TeleportToLosSantos: NewLoadSceneLoaded after %dms'):format(GetGameTimer() - sceneStart))

    -- (5) LS の地表 Z 検出（事務所周辺は約 30）
    local groundFound, groundZ = false, nil
    local groundDeadline = GetGameTimer() + 5000
    while GetGameTimer() < groundDeadline do
        local f, gz = GetGroundZFor_3dCoord(x + 0.0, y + 0.0, z + 200.0, false)
        if f and gz and gz > -10.0 and gz < 1000.0 then
            groundFound = true
            groundZ = gz
            break
        end
        RequestCollisionAtCoord(x + 0.0, y + 0.0, z + 100.0)
        Wait(100)
    end
    local finalZ = z
    if groundFound and groundZ then
        finalZ = groundZ + 1.0
        print(('[jp-meridian9] TeleportToLosSantos: ground Z = %.3f -> teleport Z = %.3f'):format(groundZ, finalZ))
    end

    -- (6) 最終テレポート
    SetEntityCoords(ped, x + 0.0, y + 0.0, finalZ, false, false, false, false)
    SetEntityHeading(ped, w)

    -- (7) コリジョン最終待機
    local colDeadline = GetGameTimer() + 5000
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < colDeadline do
        RequestCollisionAtCoord(x + 0.0, y + 0.0, finalZ)
        Wait(0)
    end

    Wait(500)

    SetEntityCollision(ped, true, true)
    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, false)
    SetEntityInvincible(ped, false)
    SetPlayerControl(PlayerId(), true, 0)

    DoScreenFadeIn(1000)
    return true
end

---@return nil
function MRD9.Transition.Leave()
    if not State.active then
        return
    end
    State.active = false
    clearBlackout()
    clearTimecycle()
    clearWeather()
    clearClockOverride()
    clearNorthYankton()
end

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then
        return
    end
    -- INSTRUCTION-021: クライアント側 restart 時の安全帰還。
    -- Cayo Perico 座標に取り残されないよう、Island 無効化前にヴェガ事務所へ瞬間移動する。
    local rp = Config and Config.Mission and Config.Mission.returnPoint
    if rp and State.active then
        local ped = PlayerPedId()
        if ped and ped ~= 0 then
            FreezeEntityPosition(ped, true)
            SetEntityInvincible(ped, true)
            SetEntityCoords(ped, rp.x + 0.0, rp.y + 0.0, rp.z + 0.0, false, false, false, false)
            if rp.w then SetEntityHeading(ped, rp.w + 0.0) end
            FreezeEntityPosition(ped, false)
            SetEntityInvincible(ped, false)
        end
    end
    MRD9.Transition.Leave()
end)
