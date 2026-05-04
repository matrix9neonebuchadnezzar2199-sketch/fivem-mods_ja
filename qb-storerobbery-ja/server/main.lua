local QBCore = exports['qb-core']:GetCoreObject()

-- =====================================================================
-- KVP Persistence Helpers (FORK ADDITION)
--
-- Cooldown state is persisted via FiveM's ResourceKvp API so it
-- survives server/resource restarts. We store the absolute end-time
-- (in ms since epoch) of each cooldown so that remaining time can be
-- recomputed correctly after downtime.
-- =====================================================================
local KVP_REG_PREFIX = 'qbsr_reg_cooldown_'
local KVP_SAFE_PREFIX = 'qbsr_safe_cooldown_'

local function NowMs()
    return os.time() * 1000
end

local function GetRegisterCooldownEnd(id)
    local raw = GetResourceKvpString(KVP_REG_PREFIX .. tostring(id))
    return raw and tonumber(raw) or nil
end

local function SetRegisterCooldownEnd(id, endAtMs)
    SetResourceKvp(KVP_REG_PREFIX .. tostring(id), tostring(endAtMs))
end

local function ClearRegisterCooldown(id)
    DeleteResourceKvp(KVP_REG_PREFIX .. tostring(id))
end

local function GetSafeCooldownEnd(id)
    local raw = GetResourceKvpString(KVP_SAFE_PREFIX .. tostring(id))
    return raw and tonumber(raw) or nil
end

local function SetSafeCooldownEnd(id, endAtMs)
    SetResourceKvp(KVP_SAFE_PREFIX .. tostring(id), tostring(endAtMs))
end

local function ClearSafeCooldown(id)
    DeleteResourceKvp(KVP_SAFE_PREFIX .. tostring(id))
end

local SafeCodes = {}
local cashA = 250 --<<how much minimum you can get from a robbery
local cashB = 450 --<< how much maximum you can get from a robbery

-- =====================================================================
-- Safe code generator (FORK FIX)
--
-- Original bug: every 40 minutes ALL safe codes were unconditionally
-- regenerated, invalidating any sticky-note codes players had
-- collected and breaking robberies in progress.
--
-- Fix: generate codes once at startup, then regenerate per-safe only
-- after that safe is robbed and its cooldown expires (handled in
-- setSafeStatus's SetTimeout / restore path).
-- =====================================================================

local function GenerateSafeCode(safeId)
    -- Padlock-type safes use multi-value tables; keypad uses a single int.
    -- The shape of each entry must match the original SafeCodes layout.
    if safeId == 2 then
        return { math.random(1, 149), math.random(500.0, 600.0), math.random(360.0, 400), math.random(600.0, 900.0) }
    elseif safeId == 3 then
        return { math.random(150, 359), math.random(-300.0, -60.0), math.random(0, 100), math.random(-500.0, -160.0) }
    elseif safeId == 6 then
        return { math.random(1, 149), math.random(150.0, 200.0), math.random(100, 140), math.random(150.0, 220.0), math.random(-100, 100), math.random(140, 300) }
    elseif safeId == 10 then
        return { math.random(1, 149), math.random(300.0, 500.0), math.random(200, 260), math.random(500.0, 800.0), math.random(300, 440), math.random(650, 900) }
    elseif safeId == 14 then
        return { math.random(150, 450), math.random(-360.0, 0.0), math.random(360, 720) }
    elseif safeId == 18 then
        return { math.random(150, 450), math.random(1.0, 100.0), math.random(360, 450), math.random(300.0, 340.0), math.random(350, 400), math.random(320.0, 340.0), math.random(350, 600) }
    else
        return math.random(1000, 9999)
    end
end

local function RegenerateAllSafeCodes()
    for id = 1, 19 do
        SafeCodes[id] = GenerateSafeCode(id)
    end
end

-- Initial generation at resource start
CreateThread(function()
    RegenerateAllSafeCodes()
end)

RegisterNetEvent('qb-storerobbery:server:takeMoney', function(register, isDone)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local regEntry = Config.Registers[register]
    if type(register) ~= 'number' or not regEntry or not regEntry[1] then
        return
    end
    local playerPed = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(playerPed)
    if #(playerCoords - regEntry[1].xyz) > 3.0 or (not regEntry.robbed and not isDone) or (regEntry.time <= 0 and not isDone) then
        return DropPlayer(src, 'Attempted exploit abuse')
    end
    if isDone then
        local bags = math.random(1, 3)
        local info = {
            worth = math.random(cashA, cashB)
        }
        AddItemCompat(src, 'markedbills', bags, info, 'qb-storerobbery:server:takeMoney')
        NotifyItemAdded(src, 'markedbills')
        if math.random(1, 100) <= Config.stickyNoteChance then
            local code = SafeCodes[regEntry.safeKey]
            if Config.Safes[regEntry.safeKey].type == 'keypad' then
                info = {
                    label = Lang:t('text.safe_code') .. tostring(code)
                }
            else
                local label = Lang:t('text.safe_code') .. ' '

                for i = 1, #code do
                    label = label .. tostring(math.floor((code[i] % 360) / 3.60)) .. ' - '
                end

                info = { label = label:sub(1, -3) }
            end
            AddItemCompat(src, 'stickynote', 1, info, 'qb-storerobbery:server:takeMoney')
            NotifyItemAdded(src, 'stickynote')
        end
    end
end)

RegisterNetEvent('qb-storerobbery:server:setRegisterStatus', function(register)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    if not Config.Registers[register] then return end
    -- Anti-exploit: verify proximity
    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    if #(playerCoords - Config.Registers[register][1].xyz) > 5.0 then
        return DropPlayer(src, 'Attempted exploit abuse')
    end

    Config.Registers[register].robbed = true
    Config.Registers[register].time = Config.resetTime

    -- Persist cooldown end time so it survives restarts
    SetRegisterCooldownEnd(register, NowMs() + Config.resetTime)

    TriggerClientEvent('qb-storerobbery:client:setRegisterStatus', -1, register, Config.Registers[register])
end)

RegisterNetEvent('qb-storerobbery:server:setSafeStatus', function(safe)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    if not Config.Safes[safe] then return end
    -- Anti-exploit: verify proximity
    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    if #(playerCoords - Config.Safes[safe][1].xyz) > 5.0 then
        return DropPlayer(src, 'Attempted exploit abuse')
    end

    Config.Safes[safe].robbed = true
    TriggerClientEvent('qb-storerobbery:client:setSafeStatus', -1, safe, true)

    -- Persist cooldown end timestamp so it survives restarts
    local cooldownMs = math.random(40, 80) * (60 * 1000)
    local endAt = NowMs() + cooldownMs
    SetSafeCooldownEnd(safe, endAt)

    SetTimeout(cooldownMs, function()
        if Config.Safes[safe] then
            Config.Safes[safe].robbed = false
            ClearSafeCooldown(safe)
            SafeCodes[safe] = GenerateSafeCode(safe) -- Regenerate code only for this safe
            TriggerClientEvent('qb-storerobbery:client:setSafeStatus', -1, safe, false)
        end
    end)
end)

RegisterNetEvent('qb-storerobbery:server:SafeReward', function(safe)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local playerPed = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(playerPed)
    if #(playerCoords - Config.Safes[safe][1].xyz) > 3.0 or Config.Safes[safe].robbed then
        return DropPlayer(src, 'Attempted exploit abuse')
    end
    local bags = math.random(1, 3)
    local info = {
        worth = math.random(cashA, cashB)
    }
    AddItemCompat(src, 'markedbills', bags, info, 'qb-storerobbery:server:SafeReward')
    NotifyItemAdded(src, 'markedbills')
    local luck = math.random(1, 100)
    local odd = math.random(1, 100)
    if luck <= 10 then
        local rolexCount = math.random(3, 7)
        AddItemCompat(src, 'rolex', rolexCount, nil, 'qb-storerobbery:server:SafeReward')
        NotifyItemAdded(src, 'rolex')
        if luck == odd then
            Wait(500)
            AddItemCompat(src, 'goldbar', 1, nil, 'qb-storerobbery:server:SafeReward')
            NotifyItemAdded(src, 'goldbar')
        end
    end
end)

RegisterNetEvent('qb-storerobbery:server:callCops', function(type, safe, streetLabel, coords)
    local cameraId
    if type == 'safe' then
        cameraId = Config.Safes[safe].camId
    else
        cameraId = Config.Registers[safe].camId
    end
    local alertData = {
        title = '10-33 | Shop Robbery',
        coords = { x = coords.x, y = coords.y, z = coords.z },
        description = Lang:t('email.someone_is_trying_to_rob_a_store', { street = streetLabel, cameraId1 = cameraId })
    }
    TriggerClientEvent('qb-storerobbery:client:robberyCall', -1, type, safe, streetLabel, coords)
    TriggerClientEvent('qb-phone:client:addPoliceAlert', -1, alertData)
end)

RegisterNetEvent('qb-storerobbery:server:removeAdvancedLockpick', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    RemoveItemCompat(src, 'advancedlockpick', 1, 'qb-storerobbery:server:removeAdvancedLockpick')
    NotifyItemRemoved(src, 'advancedlockpick')
end)

RegisterNetEvent('qb-storerobbery:server:removeLockpick', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    RemoveItemCompat(src, 'lockpick', 1, 'qb-storerobbery:server:removeLockpick')
    NotifyItemRemoved(src, 'lockpick')
end)

-- =====================================================================
-- Register cooldown tick (FORK FIX)
--
-- Original bugs:
--   1. `ipairs` stops at the first missing numeric key, so servers
--      with non-contiguous register IDs silently lost cooldown
--      processing for later registers (required restart to recover).
--   2. The toSend payload was a list of register tables indexed by
--      array position (1,2,3...). The client iterated it with
--      `pairs(batch)` and used those indices as register IDs,
--      corrupting Config.Registers on the client and making affected
--      registers permanently unrobbable until reconnect.
--
-- Fix: use `pairs` and key the payload by actual register ID.
-- =====================================================================
CreateThread(function()
    while true do
        local toSend = {}
        local hasUpdates = false
        for k, register in pairs(Config.Registers) do
            if register.time and register.time > 0 then
                register.time = register.time - Config.tickInterval
                if register.time <= 0 then
                    register.time = 0
                    register.robbed = false
                    ClearRegisterCooldown(k) -- FORK: clean up persisted entry
                    toSend[k] = register
                    hasUpdates = true
                end
            end
        end

        if hasUpdates then
            TriggerClientEvent('qb-storerobbery:client:setRegisterStatus', -1, toSend, false)
        end

        Wait(Config.tickInterval)
    end
end)

QBCore.Functions.CreateCallback('qb-storerobbery:server:isCombinationRight', function(_, cb, safe)
    cb(SafeCodes[safe])
end)

QBCore.Functions.CreateCallback('qb-storerobbery:server:getPadlockCombination', function(_, cb, safe)
    cb(SafeCodes[safe])
end)

QBCore.Functions.CreateCallback('qb-storerobbery:server:getRegisterStatus', function(_, cb)
    cb(Config.Registers)
end)

QBCore.Functions.CreateCallback('qb-storerobbery:server:getSafeStatus', function(_, cb)
    cb(Config.Safes)
end)

-- =====================================================================
-- Restore persisted cooldowns on resource start (FORK ADDITION)
-- =====================================================================
CreateThread(function()
    Wait(500)
    local now = NowMs()

    -- Restore register cooldowns
    for id, _ in pairs(Config.Registers) do
        local endAt = GetRegisterCooldownEnd(id)
        if endAt then
            if endAt > now then
                Config.Registers[id].robbed = true
                Config.Registers[id].time = endAt - now
            else
                ClearRegisterCooldown(id)
                Config.Registers[id].robbed = false
                Config.Registers[id].time = 0
            end
        end
    end

    -- Restore safe cooldowns
    for id, _ in pairs(Config.Safes) do
        local endAt = GetSafeCooldownEnd(id)
        if endAt then
            if endAt > now then
                Config.Safes[id].robbed = true
                local remaining = endAt - now
                SetTimeout(remaining, function()
                    if Config.Safes[id] then
                        Config.Safes[id].robbed = false
                        ClearSafeCooldown(id)
                        SafeCodes[id] = GenerateSafeCode(id) -- Regenerate code only for this safe
                        TriggerClientEvent('qb-storerobbery:client:setSafeStatus', -1, id, false)
                    end
                end)
            else
                ClearSafeCooldown(id)
                Config.Safes[id].robbed = false
            end
        end
    end
end)
