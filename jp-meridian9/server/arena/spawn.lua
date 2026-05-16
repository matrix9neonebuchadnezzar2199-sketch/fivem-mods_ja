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
---@param minROverride number|nil
---@param maxROverride number|nil
---@return vector3|nil
function MRD9.Arena.Spawn.PickCoordsNearPlayer(src, attempts, minROverride, maxROverride)
    if type(src) ~= 'number' or src <= 0 then
        return nil
    end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then
        return nil
    end
    local c = GetEntityCoords(ped)
    local cfg = Config.Arena
    local minR = tonumber(minROverride) or (cfg and cfg.spawnRadiusMin) or 30.0
    local maxR = tonumber(maxROverride) or (cfg and cfg.spawnRadiusMax) or 80.0
    if maxR < minR then
        maxR = minR + 1.0
    end
    local ang = math.random() * math.pi * 2
    local dist = minR + math.random() * (maxR - minR)
    local x = c.x + math.cos(ang) * dist
    local y = c.y + math.sin(ang) * dist
    return vector3(x, y, c.z + 0.5)
end

---@param sessionId string
---@param isBoss boolean
---@return boolean
function MRD9.Arena.Spawn.RequestZombie(sessionId, isBoss)
    local session = MRD9.Session.Get(sessionId)
    if not session or not session.members or #session.members == 0 then
        return false
    end
    -- INSTRUCTION-021: ターゲットをパーティメンバーからランダム選出。
    -- 旧実装はリーダー周辺固定で、複数人パーティだとリーダーだけが標的化されていた。
    local target = session.members[math.random(1, #session.members)]
    local cfg = Config.Arena
    local model = isBoss and ((cfg.bossModels and cfg.bossModels[1]) or 'u_m_y_zombie_01') or ((cfg.zombieModels and cfg.zombieModels[1]) or 'u_m_y_zombie_01')
    local health = isBoss and (cfg.bossHealth or 600) or (cfg.zombieHealth or 150)

    local coords = MRD9.Arena.Spawn.PickCoordsNearPlayer(target, cfg.spawnRetryAttempts or 5)
    if not coords then
        return false
    end

    TriggerClientEvent('jp-meridian9:client:spawnZombie', target, {
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

---@param center vector3|{ x: number, y: number, z: number }
---@param rMin number|nil
---@param rMax number|nil
---@param attempts integer|nil
---@return vector3|nil
function MRD9.Arena.Spawn.PickCoordsNearPoint(center, rMin, rMax, attempts)
    if not center then
        return nil
    end
    local cx = center.x + 0.0
    local cy = center.y + 0.0
    local cz = center.z + 0.0
    rMin = tonumber(rMin) or 5.0
    rMax = tonumber(rMax) or 10.0
    attempts = tonumber(attempts) or 8
    if rMax < rMin then
        rMax = rMin + 0.5
    end
    for _ = 1, attempts do
        local ang = math.random() * math.pi * 2
        local dist = rMin + math.random() * (rMax - rMin)
        local x = cx + math.cos(ang) * dist
        local y = cy + math.sin(ang) * dist
        return vector3(x, y, cz + 0.5)
    end
    return nil
end

---@param sessionId string
---@param center vector3|{ x: number, y: number, z: number }
---@param count integer
---@param opts table|nil
---@return boolean, integer|string @ok, spawnedCount or error key
function MRD9.Arena.SpawnAt(sessionId, center, count, opts)
    if type(sessionId) ~= 'string' or sessionId == '' or not center then
        return false, 'invalid_args'
    end
    opts = type(opts) == 'table' and opts or {}
    local target = tonumber(opts.targetSrc)
    if not target or target <= 0 then
        return false, 'no_target'
    end
    local session = MRD9.Session.Get(sessionId)
    if not session then
        return false, 'no_session'
    end

    count = math.floor(tonumber(count) or 1)
    if count < 1 then
        return false, 'invalid_count'
    end

    local cfgA = Config.Arena or {}
    local cfgS = Config.Survival or {}
    local models
    if type(cfgA.zombieModels) == 'table' and cfgA.zombieModels[1] then
        models = cfgA.zombieModels
    elseif type(cfgS.zombieModels) == 'table' and cfgS.zombieModels[1] then
        models = cfgS.zombieModels
    else
        models = { 'u_m_y_zombie_01' }
    end
    local model = models[1] or 'u_m_y_zombie_01'
    local health = tonumber(cfgA.zombieHealth) or tonumber(cfgS.zombieHealth) or 150

    local rMin = tonumber(opts.rMin) or 5.0
    local rMax = tonumber(opts.rMax) or 10.0
    local persistent = opts.persistent ~= false
    local tag = type(opts.tag) == 'string' and opts.tag ~= '' and opts.tag or 'fiction:generic'
    local isBoss = opts.isBoss == true

    local spawned = 0
    for _ = 1, count do
        local coords = MRD9.Arena.Spawn.PickCoordsNearPoint(center, rMin, rMax, 12)
        if coords then
            TriggerClientEvent('jp-meridian9:client:spawnZombie', target, {
                sessionId = sessionId,
                model = model,
                isBoss = isBoss,
                health = health,
                bucket = session.bucket,
                x = coords.x,
                y = coords.y,
                z = coords.z,
                source = tag,
                persistent = persistent,
            })
            spawned = spawned + 1
        end
    end
    return spawned > 0, spawned
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
