local resName = GetCurrentResourceName()

print(('[%s] resource loaded'):format(resName))

MRD9.CurrentSession = nil

RegisterNetEvent('jp-meridian9:onMissionStart', function(data)
    if type(data) ~= 'table' or not data.sessionId then
        return
    end
    MRD9.Log('Mission started: %s', data.sessionId)
    MRD9.CurrentSession = data
    if MRD9.Transition and MRD9.Transition.Enter then
        MRD9.Transition.Enter()
    end
    if MRD9.Transition and MRD9.Transition.TeleportToSiteNine and data.spawnPoint then
        MRD9.Transition.TeleportToSiteNine(data.spawnPoint)
    end
    if MRD9.HUD and MRD9.HUD.OnMissionStart then
        MRD9.HUD.OnMissionStart(data)
    end
    if MRD9.Arena and MRD9.Arena.ClientBeginMission then
        MRD9.Arena.ClientBeginMission()
    end
end)

RegisterNetEvent('jp-meridian9:onMissionEnd', function(data)
    if type(data) ~= 'table' or not data.sessionId then
        return
    end
    local reason = data.reason
    MRD9.Log('Mission ended: %s reason=%s', data.sessionId, tostring(reason))
    if MRD9.HUD and MRD9.HUD.OnMissionEnd then
        MRD9.HUD.OnMissionEnd(data)
    end
    MRD9.CurrentSession = nil

    CreateThread(function()
        local rp = data.returnPoint
        if not rp and Config and Config.Mission then
            rp = Config.Mission.returnPoint
        end
        if MRD9.Transition and MRD9.Transition.TeleportToLosSantos and rp then
            MRD9.Transition.TeleportToLosSantos(rp)
        elseif MRD9.Transition and MRD9.Transition.Leave then
            MRD9.Transition.Leave()
        end

        -- INSTRUCTION-021: 死亡系の reason すべてで気絶演出を発火（個別 died / 全滅 all_lost / arena_wiped）
        if reason == 'arena_wiped' or reason == 'died' or reason == 'all_lost' then
            local ped = PlayerPedId()
            if ped and ped ~= 0 then
                local cfg = Config.Arena
                local h = cfg and tonumber(cfg.knockdownHealth) or 1
                local ms = cfg and tonumber(cfg.ragdollDurationMs) or 5000
                SetEntityHealth(ped, h)
                SetPedToRagdoll(ped, ms, ms + 1, 0, true, true, false)
            end
        end
    end)
end)

RegisterNetEvent('jp-meridian9:notify', function(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(tostring(msg))
    EndTextCommandThefeedPostTicker(false, true)
end)

local function registerCmd(name, handler)
    if type(name) == 'string' and name ~= '' then
        RegisterCommand(name, handler, false)
    end
end

AddEventHandler('onResourceStop', function(res)
    if res ~= resName then
        return
    end
    SetNuiFocus(false, false)
end)

---クライアントローカル状態を「サイト・ナイン待機時（LS デフォルト）」へ揃える。
---INSTRUCTION-020 v4 確定運用：
---**Cayo Perico / 北ヤンクトン採用を完全撤回**（GTA V クライアントの内部状態破壊問題で
---実用に耐えないため）。サイト・ナインは **LS 内 Sandy Shores 北部の隔離区域**で運用。
---演出（天気・時間・タイムサイクル・街灯）のみ任務時に変わる。
---
---本関数は MAP 切替系ネイティブを **明示的に OFF** にして、過去の v3 残留状態を払拭する。
local function m9ApplyBaseClientState()
    -- 演出系は LS デフォルトに戻す
    pcall(function() ClearOverrideWeather() end)
    pcall(function() ClearWeatherTypePersist() end)
    pcall(function() NetworkClearClockTimeOverride() end)
    pcall(function() ClearTimecycleModifier() end)
    pcall(function() SetTimecycleModifierStrength(1.0) end)
    pcall(function() SetArtificialLightsState(false) end)
    pcall(function() NewLoadSceneStop() end)
    -- INSTRUCTION-020 v4: MAP 切替系を全て OFF（v3 残留状態の払拭含む）
    pcall(function() SetIslandEnabled('HeistIsland', false) end)
    pcall(function() if EnableMpDlcMaps then EnableMpDlcMaps(false) end end)
    if GetResourceState('bob74_ipl') == 'started' then
        local ok, NY = pcall(function()
            return exports['bob74_ipl']:GetNorthYanktonObject()
        end)
        if ok and type(NY) == 'table' and type(NY.Enable) == 'function' then
            pcall(function() NY.Enable(false) end)
        end
    end
end

-- リソース起動時のクライアント状態クリーンアップ。
-- Cayo Perico を ON にして固定し、以降 Disable しない（メモリリーク回避）。
-- 確実性のため: onClientResourceStart（リソース起動瞬間） + CreateThread Wait(2000)
-- + playerSpawned（spawnmanager 経由）の 3 経路で呼ぶ。冪等性は m9ApplyBaseClientState が保証。
AddEventHandler('onClientResourceStart', function(res)
    if res ~= resName then return end
    m9ApplyBaseClientState()
    if MRD9 and MRD9.Transition and MRD9.Transition.Leave then
        MRD9.Transition.Leave()
    end
    print('[jp-meridian9] onClientResourceStart: base state applied (LS only, MAP切替 disabled, effects OFF)')
end)

AddEventHandler('playerSpawned', function()
    m9ApplyBaseClientState()
    print('[jp-meridian9] playerSpawned: base state re-applied (LS only, MAP切替 disabled)')
end)

CreateThread(function()
    Wait(2000)
    m9ApplyBaseClientState()
    if MRD9 and MRD9.Transition and MRD9.Transition.Leave then
        MRD9.Transition.Leave()
    end
    print('[jp-meridian9] CreateThread+2s: base state applied (LS only, MAP切替 disabled, effects OFF)')
end)

-- 緊急復旧コマンド: 世界が壊れたとき F8 で `m9_recover` を叩く
RegisterCommand('m9_recover', function()
    print('[jp-meridian9] m9_recover: 強制復旧開始')
    DoScreenFadeOut(300)
    local fadeDeadline = GetGameTimer() + 800
    while not IsScreenFadedOut() and GetGameTimer() < fadeDeadline do
        Wait(0)
    end

    -- INSTRUCTION-020 v4: MAP 切替を全 OFF（v3 残留状態の払拭）
    pcall(function() SetIslandEnabled('HeistIsland', false) end)
    pcall(function() if EnableMpDlcMaps then EnableMpDlcMaps(false) end end)
    Wait(300)

    m9ApplyBaseClientState()
    if MRD9 and MRD9.Transition and MRD9.Transition.Leave then
        MRD9.Transition.Leave()
    end

    local ped = PlayerPedId()
    if ped and ped ~= 0 then
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        local rp = (Config and Config.Mission and Config.Mission.returnPoint)
        local x = rp and rp.x or 425.0
        local y = rp and rp.y or -979.3
        local z = rp and rp.z or 30.5
        local w = rp and rp.w or 0.0
        SetEntityCoords(ped, x + 0.0, y + 0.0, z + 200.0, false, false, false, false)
        Wait(300)
        RequestCollisionAtCoord(x + 0.0, y + 0.0, z + 0.0)
        NewLoadSceneStart(x + 0.0, y + 0.0, z + 0.0, 0.0, 0.0, 0.0, 50.0, 0)
        local d = GetGameTimer() + 10000
        while not IsNewLoadSceneLoaded() and GetGameTimer() < d do
            RequestCollisionAtCoord(x + 0.0, y + 0.0, z + 0.0)
            Wait(0)
        end
        NewLoadSceneStop()
        local groundFound, groundZ = false, nil
        local groundDeadline = GetGameTimer() + 5000
        while GetGameTimer() < groundDeadline do
            local f, gz = GetGroundZFor_3dCoord(x + 0.0, y + 0.0, z + 100.0, false)
            if f and gz and gz > -10.0 and gz < 1000.0 then
                groundFound = true
                groundZ = gz
                break
            end
            RequestCollisionAtCoord(x + 0.0, y + 0.0, z + 50.0)
            Wait(100)
        end
        local finalZ = (groundFound and groundZ) and (groundZ + 1.0) or z
        SetEntityCoords(ped, x + 0.0, y + 0.0, finalZ, false, false, false, false)
        SetEntityHeading(ped, w + 0.0)
        Wait(500)
        FreezeEntityPosition(ped, false)
        SetEntityInvincible(ped, false)
    end

    DoScreenFadeIn(800)
    print('[jp-meridian9] m9_recover: 強制復旧完了')
end, false)

-- 診断コマンド: 現在のクライアント状態を F8 / chat に表示
RegisterCommand('m9_status', function()
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    local bucket = -1
    pcall(function() bucket = GetPlayerRoutingBucket(PlayerId()) end)
    local lines = {
        ('player coords: %.2f, %.2f, %.2f'):format(c.x, c.y, c.z),
        ('player bucket: %s'):format(tostring(bucket)),
        ('CurrentSession: %s'):format(tostring(MRD9 and MRD9.CurrentSession and MRD9.CurrentSession.sessionId or 'nil')),
        ('bob74_ipl state: %s'):format(GetResourceState('bob74_ipl')),
    }
    for _, line in ipairs(lines) do
        print(('[jp-meridian9] [m9_status] %s'):format(line))
        TriggerEvent('chat:addMessage', {
            color = { 180, 220, 255 },
            multiline = true,
            args = { '[m9_status]', line },
        })
    end
end, false)

CreateThread(function()
    local c = Config.Commands
    if not c then
        return
    end
    registerCmd(c.stats, function()
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName('MERIDIAN-9: 統計表示は未実装（ロードマップ INSTRUCTION-006 以降）')
        EndTextCommandThefeedPostTicker(false, true)
    end)
    if Config.Debug and c.debugTeleport then
        registerCmd(c.debugTeleport, function()
            BeginTextCommandThefeedPost('STRING')
            AddTextComponentSubstringPlayerName('MERIDIAN-9: デバッグ転送は未実装')
            EndTextCommandThefeedPostTicker(false, true)
        end)
    end
end)

---@param msg string
local function nyChat(msg)
    TriggerEvent('chat:addMessage', {
        color = { 180, 220, 255 },
        multiline = true,
        args = { '[m9_ny]', msg },
    })
    print(('[jp-meridian9] [m9_ny] %s'):format(msg))
end

---@return table|nil
local function nyGetObject()
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

---@param x number
---@param y number
---@param z number
local function nyTeleport(x, y, z)
    local ped = PlayerPedId()
    if not ped or ped == 0 then
        return
    end
    DoScreenFadeOut(400)
    local fadeDeadline = GetGameTimer() + 1000
    while not IsScreenFadedOut() and GetGameTimer() < fadeDeadline do
        Wait(0)
    end
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    RequestCollisionAtCoord(x + 0.0, y + 0.0, z + 0.0)
    NewLoadSceneStart(x + 0.0, y + 0.0, z + 0.0, 0.0, 0.0, 0.0, 50.0, 0)
    local d = GetGameTimer() + 8000
    while not IsNewLoadSceneLoaded() and GetGameTimer() < d do
        RequestCollisionAtCoord(x + 0.0, y + 0.0, z + 0.0)
        Wait(0)
    end
    NewLoadSceneStop()
    SetEntityCoords(ped, x + 0.0, y + 0.0, z + 0.0, false, false, false, false)
    Wait(800)
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)
    DoScreenFadeIn(800)
end

RegisterCommand('m9_ny', function(source, args)
    local sub = args[1] or 'help'
    sub = string.lower(tostring(sub))

    if sub == 'help' then
        nyChat('使い方:')
        nyChat('/m9_ny on             — 北ヤンクトンを Enable')
        nyChat('/m9_ny off            — Disable')
        nyChat('/m9_ny tp             — Ludendorff 中心へテレポート')
        nyChat('/m9_ny tp x y z [h]   — 任意座標へテレポート（h は heading 任意）')
        nyChat('/m9_ny coords         — 現在座標を vector4(...) 形式で表示')
        nyChat('/m9_ny back           — ヴェガ事務所へ戻る')
        return
    end

    if sub == 'on' then
        local NY = nyGetObject()
        if not NY then
            nyChat('NorthYankton オブジェクト取得失敗（bob74_ipl が未起動？）')
            return
        end
        SetIslandEnabled('HeistIsland', false)  -- 排他制御
        NY.Enable(true)
        if NY.Grave and NY.Grave.Set then NY.Grave.Set(NY.Grave.dug) end
        if NY.Traffic and NY.Traffic.Enable then NY.Traffic.Enable(false) end
        nyChat(('Enable(true) 呼出（Cayo Perico は OFF）/ IPL count=%d / IPL ロードは数秒〜十数秒かかります'):format(type(NY.ipl) == 'table' and #NY.ipl or 0))
        return
    end

    if sub == 'off' then
        local NY = nyGetObject()
        if not NY then
            nyChat('NorthYankton オブジェクト取得失敗')
            return
        end
        NY.Enable(false)
        nyChat('Enable(false) 呼出')
        return
    end

    if sub == 'tp' then
        local x = tonumber(args[2]) or 3217.697
        local y = tonumber(args[3]) or -4834.826
        local z = tonumber(args[4]) or 113.0
        nyChat(('テレポート開始 → (%.3f, %.3f, %.3f)'):format(x, y, z))
        CreateThread(function()
            SetIslandEnabled('HeistIsland', false)  -- 排他制御
            local NY = nyGetObject()
            if NY then NY.Enable(true) end
            nyTeleport(x, y, z)
            local ped = PlayerPedId()
            if ped and ped ~= 0 then
                local h = tonumber(args[5])
                if h then SetEntityHeading(ped, h + 0.0) end
            end
            nyChat('テレポート完了')
        end)
        return
    end

    if sub == 'coords' then
        local ped = PlayerPedId()
        if not ped or ped == 0 then
            nyChat('PlayerPedId が無効')
            return
        end
        local c = GetEntityCoords(ped)
        local h = GetEntityHeading(ped)
        local line = ('vector4(%.3f, %.3f, %.3f, %.2f)'):format(c.x, c.y, c.z, h)
        nyChat(line)
        return
    end

    if sub == 'back' then
        local rp = Config and Config.Mission and Config.Mission.returnPoint
        if not rp then
            nyChat('Config.Mission.returnPoint が未設定')
            return
        end
        nyChat('ヴェガ事務所へ戻ります')
        CreateThread(function()
            local NY = nyGetObject()
            if NY then NY.Enable(false) end
            nyTeleport(rp.x, rp.y, rp.z)
            local ped = PlayerPedId()
            if ped and ped ~= 0 and rp.w then
                SetEntityHeading(ped, rp.w + 0.0)
            end
            nyChat('帰還完了')
        end)
        return
    end

    nyChat(('未知のサブコマンド: %s（/m9_ny help）'):format(sub))
end, false)

---@param msg string
local function cayoChat(msg)
    TriggerEvent('chat:addMessage', {
        color = { 255, 230, 180 },
        multiline = true,
        args = { '[m9_cayo]', msg },
    })
    print(('[jp-meridian9] [m9_cayo] %s'):format(msg))
end

RegisterCommand('m9_cayo', function(source, args)
    local sub = string.lower(tostring(args[1] or 'help'))

    if sub == 'help' then
        cayoChat('使い方:')
        cayoChat('/m9_cayo on             — Cayo Perico を Enable')
        cayoChat('/m9_cayo off            — Disable')
        cayoChat('/m9_cayo tp             — メインビーチ付近へテレポート')
        cayoChat('/m9_cayo tp x y z [h]   — 任意座標へテレポート')
        cayoChat('/m9_cayo coords         — 現在座標を表示')
        cayoChat('/m9_cayo back           — ヴェガ事務所へ戻る')
        return
    end

    if sub == 'on' then
        local NY = nyGetObject()
        if NY then NY.Enable(false) end  -- 排他制御
        SetIslandEnabled('HeistIsland', true)
        cayoChat('SetIslandEnabled(HeistIsland, true) 呼出（北ヤンクトンは OFF）。地形は周辺ロードで数秒かかります')
        return
    end

    if sub == 'off' then
        SetIslandEnabled('HeistIsland', false)
        cayoChat('SetIslandEnabled(HeistIsland, false) 呼出')
        return
    end

    if sub == 'tp' then
        -- 既定値: メインビーチ（カヨ・ペリコ北東岸）
        local x = tonumber(args[2]) or 4523.0
        local y = tonumber(args[3]) or -4974.0
        local z = tonumber(args[4]) or 4.5
        cayoChat(('テレポート開始 → (%.3f, %.3f, %.3f)'):format(x, y, z))
        CreateThread(function()
            local NY = nyGetObject()
            if NY then NY.Enable(false) end  -- 排他制御
            SetIslandEnabled('HeistIsland', true)
            Wait(200)
            nyTeleport(x, y, z)
            local ped = PlayerPedId()
            if ped and ped ~= 0 then
                local h = tonumber(args[5])
                if h then SetEntityHeading(ped, h + 0.0) end
            end
            cayoChat('テレポート完了')
        end)
        return
    end

    if sub == 'coords' then
        local ped = PlayerPedId()
        if not ped or ped == 0 then
            cayoChat('PlayerPedId が無効')
            return
        end
        local c = GetEntityCoords(ped)
        local h = GetEntityHeading(ped)
        local line = ('vector4(%.3f, %.3f, %.3f, %.2f)'):format(c.x, c.y, c.z, h)
        cayoChat(line)
        return
    end

    if sub == 'back' then
        local rp = Config and Config.Mission and Config.Mission.returnPoint
        if not rp then
            cayoChat('Config.Mission.returnPoint が未設定')
            return
        end
        cayoChat('ヴェガ事務所へ戻ります')
        CreateThread(function()
            SetIslandEnabled('HeistIsland', false)
            nyTeleport(rp.x, rp.y, rp.z)
            local ped = PlayerPedId()
            if ped and ped ~= 0 and rp.w then
                SetEntityHeading(ped, rp.w + 0.0)
            end
            cayoChat('帰還完了')
        end)
        return
    end

    cayoChat(('未知のサブコマンド: %s（/m9_cayo help）'):format(sub))
end, false)
