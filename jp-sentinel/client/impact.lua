local BALL_HASHES = {
    `w_am_baseball`,
    `prop_baseball_01`,
    `prop_cs_baseball`,
}

---@param ped integer
---@param maxDist number
---@return integer|nil entity
local function findThrownBallNear(ped, maxDist)
    local pcoords = GetEntityCoords(ped)
    local best = nil
    local bestD = maxDist
    for _, ent in ipairs(GetGamePool('CObject')) do
        if DoesEntityExist(ent) then
            local m = GetEntityModel(ent)
            for i = 1, #BALL_HASHES do
                if m == BALL_HASHES[i] then
                    local d = #(pcoords - GetEntityCoords(ent))
                    if d < bestD then
                        bestD = d
                        best = ent
                    end
                    break
                end
            end
        end
    end
    return best
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

---@param thrower integer
function StartImpactTracking(thrower)
    local startTime = GetGameTimer()
    local lastBallCoords = nil

    CreateThread(function()
        while GetGameTimer() - startTime < Config.Throw.MaxFlightTime do
            local ballEnt = findThrownBallNear(thrower, 80.0)
            if ballEnt then
                local ballCoords = GetEntityCoords(ballEnt)
                lastBallCoords = ballCoords

                local hitPed = findClosestPedNear(ballCoords, Config.Throw.HitRadius, thrower)
                if hitPed then
                    TriggerEvent('jp-sentinel:client:spawnDroneLocal', hitPed, ballCoords)
                    return
                end
            end
            Wait(50)
        end

        if lastBallCoords then
            local ped = findClosestPedNear(lastBallCoords, Config.Throw.SearchRadius, thrower)
            if ped then
                TriggerEvent('jp-sentinel:client:spawnDroneLocal', ped, lastBallCoords)
                return
            end
        end

        TriggerServerEvent('jp-sentinel:server:reportMiss')
        TriggerEvent('jp-sentinel:client:notifyLocal', Config.Lang('throw_missed'), 'error')
    end)
end
