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
    -- INSTRUCTION-020 v3: Cayo Perico を有効化（クライアントローカル）
    -- 北ヤンクトンと同時有効化を避ける排他制御。
    if State.nyEnabled then
        clearNorthYankton()
    end
    SetIslandEnabled('HeistIsland', true)
    State.cayoEnabled = true
    return true
end

local function clearCayoPerico()
    if not State.cayoEnabled then
        return
    end
    SetIslandEnabled('HeistIsland', false)
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

    -- (1) MAP 固有のロード待ち
    local islandKey = (cfg().island or 'cayoperico')
    if islandKey == 'northYankton' then
        local NY = getNorthYanktonObject()
        if NY and type(NY.ipl) == 'table' then
            local ok = waitIplsActive(NY.ipl, 15000)
            print(('[jp-meridian9] TeleportToSiteNine: NY IPL active=%s (count=%d)'):format(tostring(ok), #NY.ipl))
        else
            print('[jp-meridian9] TeleportToSiteNine: NorthYankton オブジェクト取得失敗')
        end
    elseif islandKey == 'cayoperico' then
        -- SetIslandEnabled は IPL 連射ではなく Heist Island のジオメトリ層を切替えるため、
        -- 個別 IPL アクティブ待機は不要。NewLoadSceneStart で十分。
        print('[jp-meridian9] TeleportToSiteNine: Cayo Perico SetIslandEnabled(true) 後の NewLoadSceneStart')
    end

    -- (2) ymap/ybn 実体ストリーミング（NewLoadSceneStart）
    -- IPL active 後でも実ジオメトリは別ストリーム。座標周辺のシーンを同期ロードする。
    RequestCollisionAtCoord(x + 0.0, y + 0.0, z + 0.0)
    NewLoadSceneStart(x + 0.0, y + 0.0, z + 0.0, 0.0, 0.0, 0.0, 50.0, 0)
    local sceneDeadline = GetGameTimer() + 12000
    while not IsNewLoadSceneLoaded() and GetGameTimer() < sceneDeadline do
        RequestCollisionAtCoord(x + 0.0, y + 0.0, z + 0.0)
        Wait(0)
    end
    NewLoadSceneStop()
    print(('[jp-meridian9] TeleportToSiteNine: NewLoadSceneLoaded after %dms'):format(GetGameTimer() - (sceneDeadline - 12000)))

    -- (3) 地面 Z を実検出して確実に陸地に着地
    -- 北ヤンクトン地形がロードされていれば GetGroundZFor_3dCoord が成功する。
    -- 失敗するなら ymap がまだロード中なので追加待機。
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
        print(('[jp-meridian9] TeleportToSiteNine: ground Z found = %.3f -> teleport Z = %.3f'):format(groundZ, finalZ))
    else
        print('[jp-meridian9] TeleportToSiteNine: ground Z not found within 10s. Using config Z (may fall into ocean)')
    end

    -- (4) テレポート
    SetEntityCoords(ped, x + 0.0, y + 0.0, finalZ, false, false, false, false)
    SetEntityHeading(ped, w)

    -- (5) コリジョン最終待機
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

    -- 帰還側は北ヤンクトンを無効化してから LS のシーンロード
    MRD9.Transition.Leave()

    RequestCollisionAtCoord(x + 0.0, y + 0.0, z + 0.0)
    NewLoadSceneStart(x + 0.0, y + 0.0, z + 0.0, 0.0, 0.0, 0.0, 50.0, 0)
    local sceneDeadline = GetGameTimer() + 12000
    while not IsNewLoadSceneLoaded() and GetGameTimer() < sceneDeadline do
        RequestCollisionAtCoord(x + 0.0, y + 0.0, z + 0.0)
        Wait(0)
    end
    NewLoadSceneStop()

    SetEntityCoords(ped, x + 0.0, y + 0.0, z + 0.0, false, false, false, false)
    SetEntityHeading(ped, w)

    local colDeadline = GetGameTimer() + 5000
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < colDeadline do
        RequestCollisionAtCoord(x + 0.0, y + 0.0, z + 0.0)
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
    MRD9.Transition.Leave()
end)
