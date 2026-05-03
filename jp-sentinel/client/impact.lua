local BALL_HASHES = {}
do
    local seen = {}
    local function addHash(h)
        if h and h ~= 0 and not seen[h] then
            seen[h] = true
            BALL_HASHES[#BALL_HASHES + 1] = h
        end
    end
    if type(Config.Throw.BallModelFallbacks) == 'table' then
        for _, h in ipairs(Config.Throw.BallModelFallbacks) do
            addHash(h)
        end
    end
    addHash(Config.Throw.BallModel)
    for _, h in ipairs({
        `w_am_baseball`,
        `prop_baseball_01`,
        joaat('prop_baseball'),
        `prop_cs_baseball`,
        `prop_proj_snowball`,
    }) do
        addHash(h)
    end
end

---@param coords vector3
---@param radius number
---@param excludePed integer
---@return integer|nil ped
local function findClosestPedNear(coords, radius, excludePed)
    local best = nil
    local bestD = radius
    for _, p in ipairs(GetGamePool('CPed')) do
        if p ~= excludePed and DoesEntityExist(p) and IsPedHuman(p) then
            local head = GetPedBoneCoords(p, 31086, 0.0, 0.0, 0.0)
            local d = #(coords - head)
            if d < bestD then
                bestD = d
                best = p
            end
        end
    end
    return best
end

---@param ballObj integer
---@param throwerPed integer
local function startImpactTrackingFromBall(ballObj, throwerPed)
    CreateThread(function()
        local startTime = GetGameTimer()
        local lastValidCoords = nil

        while GetGameTimer() - startTime < Config.Throw.MaxFlightTime do
            if not DoesEntityExist(ballObj) then
                if lastValidCoords then
                    local target = findClosestPedNear(lastValidCoords, Config.Throw.SearchRadius, throwerPed)
                    if target then
                        TriggerEvent('jp-sentinel:client:spawnDroneLocal', target, lastValidCoords)
                        return
                    end
                end
                break
            end

            local ballCoords = GetEntityCoords(ballObj)
            lastValidCoords = ballCoords

            local hitTarget = findClosestPedNear(ballCoords, Config.Throw.HitRadius, throwerPed)
            if hitTarget then
                TriggerEvent('jp-sentinel:client:spawnDroneLocal', hitTarget, ballCoords)
                if DoesEntityExist(ballObj) then
                    DeleteEntity(ballObj)
                end
                return
            end

            local vel = GetEntityVelocity(ballObj)
            local speed = math.sqrt(vel.x * vel.x + vel.y * vel.y + vel.z * vel.z)
            if speed < 0.5 and (GetGameTimer() - startTime) > 500 then
                local nearTarget = findClosestPedNear(ballCoords, Config.Throw.SearchRadius, throwerPed)
                if nearTarget then
                    TriggerEvent('jp-sentinel:client:spawnDroneLocal', nearTarget, ballCoords)
                    if DoesEntityExist(ballObj) then
                        DeleteEntity(ballObj)
                    end
                    return
                end
                break
            end

            Wait(0)
        end

        TriggerServerEvent('jp-sentinel:server:reportMiss')
        TriggerEvent('jp-sentinel:client:notifyLocal', Config.Lang('throw_missed'), 'error')
    end)
end

AddEventHandler('jp-sentinel:client:startImpactFromBall', function(ballObj, throwerPed)
    if type(ballObj) ~= 'number' or type(throwerPed) ~= 'number' then
        return
    end
    if not DoesEntityExist(ballObj) then
        TriggerServerEvent('jp-sentinel:server:reportMiss')
        TriggerEvent('jp-sentinel:client:notifyLocal', Config.Lang('throw_missed'), 'error')
        return
    end
    startImpactTrackingFromBall(ballObj, throwerPed)
end)
