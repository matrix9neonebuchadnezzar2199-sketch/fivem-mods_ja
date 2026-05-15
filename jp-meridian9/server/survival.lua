-- ============================================================
-- jp-meridian9 / server/survival.lua
-- ============================================================
-- INSTRUCTION-021: オープンワールド・サバイバル
-- 3 ウェーブクリア後（または Config.Arena.enabled=false 時）に開始する
-- 持続的ゾンビ脅威。各メンバー周辺に一定間隔でゾンビをスポーンさせ、
-- 自由探索しながらも常に戦闘の緊張感を維持する。
-- ============================================================

MRD9 = MRD9 or {}
MRD9.Survival = MRD9.Survival or {}

---@type table<string, { running: boolean, startedAt: integer, cycleCount: integer }>
local survivalStates = {}

---@param session table
---@return integer
local function countAliveMembers(session)
    local n = 0
    for _, src in ipairs(session.members or {}) do
        local ped = GetPlayerPed(src)
        if ped and ped ~= 0 then
            local hp = GetEntityHealth(ped) or 0
            if hp > 0 then
                n = n + 1
            end
        end
    end
    return n
end

---@param sessionId string
---@param src integer
---@param count integer
---@param minR number
---@param maxR number
---@param health integer
---@param model string
local function spawnAroundPlayer(sessionId, src, count, minR, maxR, health, model)
    local session = MRD9.Session.Get(sessionId)
    if not session then
        return
    end
    for _ = 1, count do
        local coords
        if MRD9.Arena and MRD9.Arena.Spawn and MRD9.Arena.Spawn.PickCoordsNearPlayer then
            coords = MRD9.Arena.Spawn.PickCoordsNearPlayer(src, 5, minR, maxR)
        end
        if coords then
            TriggerClientEvent('jp-meridian9:client:spawnZombie', src, {
                sessionId = sessionId,
                model = model,
                isBoss = false,
                health = health,
                bucket = session.bucket,
                x = coords.x,
                y = coords.y,
                z = coords.z,
                source = 'survival',
            })
        end
    end
end

---@param sessionId string|nil
---@return nil
function MRD9.Survival.Start(sessionId)
    if not sessionId then
        return
    end
    local cfg = Config.Survival
    if not cfg or cfg.enabled == false then
        return
    end
    if survivalStates[sessionId] then
        return
    end
    local session = MRD9.Session.Get(sessionId)
    if not session then
        return
    end

    survivalStates[sessionId] = {
        running = true,
        startedAt = GetGameTimer(),
        cycleCount = 0,
    }

    MRD9.Log('Survival started session=%s interval=%dms count=%d radius=%.0f-%.0f',
        sessionId,
        tonumber(cfg.intervalMs) or 180000,
        tonumber(cfg.countPerPlayer) or 3,
        tonumber(cfg.radiusMin) or 30.0,
        tonumber(cfg.radiusMax) or 150.0)

    for _, m in ipairs(session.members) do
        TriggerClientEvent('jp-meridian9:notify', m, 'サイト・ナイン: 自由探索フェーズ開始（持続的脅威）')
    end

    CreateThread(function()
        local intervalMs = tonumber(cfg.intervalMs) or 180000
        local countPerPlayer = tonumber(cfg.countPerPlayer) or 3
        local minR = tonumber(cfg.radiusMin) or 30.0
        local maxR = tonumber(cfg.radiusMax) or 150.0
        local health = tonumber(cfg.zombieHealth) or 100
        local models = (type(cfg.zombieModels) == 'table' and cfg.zombieModels) or { 'u_m_y_zombie_01' }

        while true do
            local state = survivalStates[sessionId]
            if not state or not state.running then
                return
            end
            local s = MRD9.Session.Get(sessionId)
            if not s or s.state ~= 'IN_MISSION' then
                return
            end

            Wait(intervalMs)

            state = survivalStates[sessionId]
            if not state or not state.running then
                return
            end
            s = MRD9.Session.Get(sessionId)
            if not s or s.state ~= 'IN_MISSION' then
                return
            end

            if countAliveMembers(s) <= 0 then
                -- 全員ダウン中はスポーンを抑制
                goto continue
            end

            state.cycleCount = state.cycleCount + 1
            local model = models[math.random(1, #models)]
            for _, src in ipairs(s.members) do
                local ped = GetPlayerPed(src)
                if ped and ped ~= 0 and (GetEntityHealth(ped) or 0) > 0 then
                    spawnAroundPlayer(sessionId, src, countPerPlayer, minR, maxR, health, model)
                end
            end
            MRD9.Log('Survival cycle session=%s #%d', sessionId, state.cycleCount)

            ::continue::
        end
    end)
end

---@param sessionId string|nil
---@return nil
function MRD9.Survival.Stop(sessionId)
    if not sessionId then
        return
    end
    local st = survivalStates[sessionId]
    if not st then
        return
    end
    st.running = false
    survivalStates[sessionId] = nil
    MRD9.Log('Survival stopped session=%s', sessionId)
end

---@param sessionId string|nil
---@return boolean
function MRD9.Survival.IsActive(sessionId)
    return survivalStates[sessionId] ~= nil
end
