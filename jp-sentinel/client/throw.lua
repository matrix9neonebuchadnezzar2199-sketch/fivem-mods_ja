local IsThrowMode = false

-- WEAPON_BALL 投擲後に世界に出る可能性があるモデル（近い候補はすべて列挙）
local BALL_HASHES = {
    `prop_baseball_01`,
    joaat('prop_baseball'),
    `prop_cs_baseball`,
    `w_am_baseball`,
    `prop_proj_snowball`,
}

---FindFirstObject 列挙（ネイティブ失敗時は何も yield しない）
---@return fun(): integer|nil
local function enumerateObjects()
    return coroutine.wrap(function()
        local ok, handle, object = pcall(FindFirstObject)
        if not ok or not handle or handle == -1 then
            return
        end
        local success
        repeat
            if object and object ~= 0 then
                coroutine.yield(object)
            end
            success, object = FindNextObject(handle)
        until not success
        pcall(EndFindObject, handle)
    end)
end

---プレイヤーから離れた野球ボールを1つ選ぶ（誤発火した手元トラッキングを避ける）
---@param ped integer
---@return integer|nil
local function findRecentlyThrownBall(ped)
    local pcoords = GetEntityCoords(ped)
    local best = nil
    local bestD = 31.0

    local function considerEntity(obj)
        if not DoesEntityExist(obj) then
            return
        end
        local m = GetEntityModel(obj)
        for i = 1, #BALL_HASHES do
            local h = BALL_HASHES[i]
            if h ~= 0 and m == h then
                local d = #(GetEntityCoords(obj) - pcoords)
                if d > 1.5 and d < 30.0 and d < bestD then
                    bestD = d
                    best = obj
                end
                break
            end
        end
    end

    for obj in enumerateObjects() do
        considerEntity(obj)
    end

    if not best then
        for _, obj in ipairs(GetGamePool('CObject')) do
            considerEntity(obj)
        end
    end

    return best
end

RegisterNetEvent('jp-sentinel:client:allowThrow', function()
    if IsThrowMode then
        return
    end

    local ped = PlayerPedId()
    IsThrowMode = true

    GiveWeaponToPed(ped, Config.Throw.WeaponHash, 1, false, true)
    SetCurrentPedWeapon(ped, Config.Throw.WeaponHash, true)

    TriggerEvent('jp-sentinel:client:notifyLocal', Config.Lang('throw_ready'), 'info')

    CreateThread(function()
        Wait(800)
        if not IsThrowMode then
            return
        end

        local activatedAt = GetGameTimer()
        local cancelTimeout = 20000
        local thrown = false

        while IsThrowMode do
            local elapsed = GetGameTimer() - activatedAt

            if not thrown and elapsed > 200 then
                local ballObj = findRecentlyThrownBall(ped)
                if ballObj then
                    thrown = true
                    IsThrowMode = false
                    RemoveWeaponFromPed(ped, Config.Throw.WeaponHash)
                    TriggerEvent('jp-sentinel:client:startImpactFromBall', ballObj, ped)
                    break
                end
            end

            if elapsed > cancelTimeout then
                IsThrowMode = false
                RemoveWeaponFromPed(ped, Config.Throw.WeaponHash)
                TriggerServerEvent('jp-sentinel:server:reportThrowAbort')
                TriggerEvent('jp-sentinel:client:notifyLocal', Config.Lang('throw_timeout'), 'info')
                break
            end

            Wait(50)
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
