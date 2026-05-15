-- =====================================================
-- jp-meridian9 / server/arena/spawn.lua
-- =====================================================
-- このファイルは以下のプロジェクトからの派生コードを含みます:
--
--   TP-Advanced-Zombies (TitansProductions)
--   https://github.com/TitansProductions/TP-Advanced-Zombies
--   Licensed under Apache License 2.0
--
-- Modifications by jp-meridian9 contributors:
--   - ESX / QBCore 等のフレームワーク依存を削除し、Standalone + MRD9 名前空間へ統合
--   - routing bucket（セッション bucket）に合わせたスポーン座標選定とクライアント委譲
--   - `Config.Arena` を正とするパラメータ参照（旧 Config 直参照の排除）
--   - スポーン完了は `jp-meridian9:server:zombieSpawned` でサーバー登録（波管理と連携）
--
-- See LICENSE-APACHE-2.0 and NOTICE for details.
-- Apache 2.0 §4(b): This file has been modified from the original.
-- =====================================================

MRD9.Arena = MRD9.Arena or {}
MRD9.Arena.Spawn = MRD9.Arena.Spawn or {}

---@param src integer
---@param attempts integer|nil
---@return vector3|nil
function MRD9.Arena.Spawn.PickCoordsNearPlayer(src, attempts)
    if type(src) ~= 'number' or src <= 0 then
        return nil
    end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then
        return nil
    end
    local c = GetEntityCoords(ped)
    local cfg = Config.Arena
    local minR = (cfg and cfg.spawnRadiusMin) or 30.0
    local maxR = (cfg and cfg.spawnRadiusMax) or 80.0
    if maxR < minR then
        maxR = minR + 1.0
    end
    local n = attempts or (cfg and cfg.spawnRetryAttempts) or 5
    for _ = 1, n do
        local ang = math.random() * math.pi * 2
        local dist = minR + math.random() * (maxR - minR)
        local x = c.x + math.cos(ang) * dist
        local y = c.y + math.sin(ang) * dist
        local z = c.z + 50.0
        local found, gz = GetGroundZFor_3dCoord(x + 0.0, y + 0.0, z + 0.0, false)
        if found and gz then
            return vector3(x, y, gz + 0.5)
        end
    end
    return vector3(c.x + 10.0, c.y, c.z)
end

---@param sessionId string
---@param isBoss boolean
---@return boolean
function MRD9.Arena.Spawn.RequestZombie(sessionId, isBoss)
    local session = MRD9.Session.Get(sessionId)
    if not session then
        return false
    end
    local leader = session.leader
    local cfg = Config.Arena
    local model = isBoss and ((cfg.bossModels and cfg.bossModels[1]) or 'u_m_y_zombie_01') or ((cfg.zombieModels and cfg.zombieModels[1]) or 'u_m_y_zombie_01')
    local health = isBoss and (cfg.bossHealth or 600) or (cfg.zombieHealth or 150)

    local coords = MRD9.Arena.Spawn.PickCoordsNearPlayer(leader, cfg.spawnRetryAttempts or 5)
    if not coords then
        return false
    end

    TriggerClientEvent('jp-meridian9:client:spawnZombie', leader, {
        sessionId = sessionId,
        model = model,
        isBoss = isBoss == true,
        health = health,
        bucket = session.bucket,
        x = coords.x,
        y = coords.y,
        z = coords.z,
    })
    return true
end

RegisterNetEvent('jp-meridian9:server:zombieSpawned', function(data)
    local src = source
    if type(src) ~= 'number' or src <= 0 or type(data) ~= 'table' then
        return
    end
    if MRD9.Arena and MRD9.Arena.OnClientZombieSpawned then
        MRD9.Arena.OnClientZombieSpawned(src, data)
    end
end)
