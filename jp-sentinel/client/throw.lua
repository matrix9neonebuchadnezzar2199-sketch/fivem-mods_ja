local IsThrowMode = false

local ANIM_DICT = 'anim@mp_player_intthrow'
local ANIM_NAME = 'throw'

---@return integer|nil
local function resolveBallModel()
    local list = Config.Throw.BallModelFallbacks
    if type(list) ~= 'table' or #list == 0 then
        list = { Config.Throw.BallModel }
    end

    for _, candidate in ipairs(list) do
        if candidate and candidate ~= 0 and IsModelValid(candidate) and IsModelInCdimage(candidate) then
            RequestModel(candidate)
            local timeout = GetGameTimer() + 2000
            while not HasModelLoaded(candidate) and GetGameTimer() < timeout do
                Wait(10)
            end
            if HasModelLoaded(candidate) then
                return candidate
            end
            SetModelAsNoLongerNeeded(candidate)
        end
    end

    -- CD チェックが厳しい環境向け：IsModelValid のみで再試行
    for _, candidate in ipairs(list) do
        if candidate and candidate ~= 0 and IsModelValid(candidate) then
            RequestModel(candidate)
            local timeout = GetGameTimer() + 2000
            while not HasModelLoaded(candidate) and GetGameTimer() < timeout do
                Wait(10)
            end
            if HasModelLoaded(candidate) then
                return candidate
            end
            SetModelAsNoLongerNeeded(candidate)
        end
    end

    return nil
end

---@param ped integer
local function manualThrow(ped)
    if not DoesEntityExist(ped) then
        TriggerServerEvent('jp-sentinel:server:reportCancel')
        return
    end

    local ballModel = resolveBallModel()
    if not ballModel then
        TriggerServerEvent('jp-sentinel:server:reportCancel')
        TriggerEvent('jp-sentinel:client:notifyLocal', Config.Lang('throw_no_ball_models'), 'error')
        return
    end

    RequestAnimDict(ANIM_DICT)
    local deadline = GetGameTimer() + 5000
    while not HasAnimDictLoaded(ANIM_DICT) and GetGameTimer() < deadline do
        Wait(10)
    end
    if HasAnimDictLoaded(ANIM_DICT) then
        TaskPlayAnim(ped, ANIM_DICT, ANIM_NAME, 8.0, -8.0, -1, 48, 0.0, false, false, false)
    end

    local delay = Config.Throw.ReleaseDelay or 300
    SetTimeout(delay, function()
        local p = PlayerPedId()
        if not DoesEntityExist(p) then
            SetModelAsNoLongerNeeded(ballModel)
            TriggerServerEvent('jp-sentinel:server:reportCancel')
            return
        end

        local pos = GetEntityCoords(p)
        local fwd = GetEntityForwardVector(p)
        local spawnPos = vector3(pos.x + fwd.x * 0.5, pos.y + fwd.y * 0.5, pos.z + 0.6)

        local ball = CreateObject(ballModel, spawnPos.x, spawnPos.y, spawnPos.z, true, true, false)
        SetModelAsNoLongerNeeded(ballModel)

        ClearPedTasks(p)

        if not ball or ball == 0 or not DoesEntityExist(ball) then
            TriggerServerEvent('jp-sentinel:server:reportMiss')
            TriggerEvent('jp-sentinel:client:notifyLocal', Config.Lang('throw_missed'), 'error')
            return
        end

        SetEntityAsMissionEntity(ball, true, true)
        SetEntityDynamic(ball, true)
        SetEntityHeading(ball, GetEntityHeading(p))

        local power = Config.Throw.ThrowPower or 25.0
        local up = Config.Throw.ThrowUpward or 5.0
        ApplyForceToEntity(ball, 1, fwd.x * power, fwd.y * power, up, 0.0, 0.0, 0.0, 0, false, true, true, false, true)

        TriggerEvent('jp-sentinel:client:startImpactFromBall', ball, p)
    end)
end

RegisterNetEvent('jp-sentinel:client:allowThrow', function()
    if IsThrowMode then
        return
    end

    IsThrowMode = true
    TriggerEvent('jp-sentinel:client:notifyLocal', Config.Lang('throw_ready'), 'info')
    TriggerEvent('jp-sentinel:client:notifyLocal', Config.Lang('throw_instructions'), 'info')

    CreateThread(function()
        Wait(800)
        if not IsThrowMode then
            return
        end

        local activatedAt = GetGameTimer()
        local maxWait = Config.Throw.MaxWaitMs or 20000

        while IsThrowMode do
            local elapsed = GetGameTimer() - activatedAt

            if IsControlJustReleased(0, 24) then
                IsThrowMode = false
                manualThrow(PlayerPedId())
                break
            end

            if IsControlJustReleased(0, 25) then
                IsThrowMode = false
                TriggerServerEvent('jp-sentinel:server:reportCancel')
                TriggerEvent('jp-sentinel:client:notifyLocal', Config.Lang('throw_cancelled'), 'info')
                break
            end

            if elapsed > maxWait then
                IsThrowMode = false
                TriggerServerEvent('jp-sentinel:server:reportCancel')
                TriggerEvent('jp-sentinel:client:notifyLocal', Config.Lang('throw_timeout'), 'info')
                break
            end

            Wait(0)
        end
    end)
end)

RegisterNetEvent('jp-sentinel:client:denyThrow', function(data)
    IsThrowMode = false
    if type(data) == 'table' and data.reason == 'cooldown' and data.remain then
        TriggerEvent('jp-sentinel:client:notifyLocal', Config.Lang('cooldown_active', data.remain), 'error')
    elseif type(data) == 'table' and data.reason == 'busy' then
        TriggerEvent('jp-sentinel:client:notifyLocal', Config.Lang('already_active'), 'error')
    end
end)
