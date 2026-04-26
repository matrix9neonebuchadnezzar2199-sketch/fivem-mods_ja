local sharedConfig = require 'config.shared'
local clientConfig = require 'config.client'

---@type table|nil
local itemCryptostick = nil

local function getCryptostickItem()
    if not clientConfig.rewards or not clientConfig.rewards.enableCryptostick then return end
    local ok, items = pcall(function()
        return exports.ox_inventory:Items()
    end)
    if not ok or not items or not items['cryptostick'] then return end
    return items['cryptostick']
end

itemCryptostick = getCryptostickItem()

local function log(fmt, ...)
    print(('[jp-taxijob] ' .. fmt):format(...))
end

local function getPlayerJobName(src)
    local ok, player = pcall(function()
        return exports.qbx_core:GetPlayer(src)
    end)
    if not ok or not player or not player.PlayerData or not player.PlayerData.job then
        return nil
    end
    return player.PlayerData.job.name
end

local function isJobAllowed(src)
    if not clientConfig.requireJob then return true end
    return getPlayerJobName(src) == clientConfig.requiredJobName
end

local function nearTaxi(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    local coords = GetEntityCoords(ped)
    for _, v in pairs(sharedConfig.npcLocations.deliverLocations) do
        local dist = #(coords - v.xyz)
        if dist < 20.0 then
            return true
        end
    end
    return false
end

-- 社用車: netId 追跡
local companyCabNetId = {} ---@type table<number, number>
local function rememberCompanyCab(src, netId)
    companyCabNetId[src] = netId
end
local function forgetCompanyCab(src)
    companyCabNetId[src] = nil
end

---@param src number
---@param netId number|nil
local function deleteEntityByNetId(src, netId)
    if not netId or netId == 0 then
        return false, 'no_netid'
    end
    local ent = NetworkGetEntityFromNetworkId(netId)
    if not ent or ent == 0 or not DoesEntityExist(ent) then
        return false, 'no_entity'
    end
    DeleteEntity(ent)
    return true, 'ok'
end

---@param payment number|nil
---@return number
local function applyRandomExtraCash(payment)
    payment = tonumber(payment) or 0
    if not clientConfig.rewards or not clientConfig.rewards.enableRandomExtraCash then
        return math.floor(payment)
    end
    local rAmount = math.random(1, 5)
    local r1, r2 = math.random(1, 5), math.random(1, 5)
    if rAmount == r1 or rAmount == r2 then
        payment = payment + math.random(10, 20)
    end
    return math.floor(payment)
end

---@param src number
---@param payment number|nil
---@return boolean, string|nil
local function handleNpcPay(src, payment)
    if not isJobAllowed(src) then
        log('拒否: ジョブ不適合 src=%s', src)
        return false, 'job'
    end
    if not nearTaxi(src) then
        log('拒否: 降車地点外 src=%s pay=%s', src, tostring(payment))
        return false, 'location'
    end

    local ok, player = pcall(function()
        return exports.qbx_core:GetPlayer(src)
    end)
    if not ok or not player or not player.Functions then
        log('拒否: プレイヤー取得失敗 src=%s', src)
        return false, 'player'
    end

    local finalPay = applyRandomExtraCash(payment)
    player.Functions.AddMoney('cash', finalPay)

    if itemCryptostick and clientConfig.rewards and clientConfig.rewards.enableCryptostick then
        local chance = tonumber(clientConfig.rewards.cryptostickChance) or 0
        if chance > 0 and math.random(1, 100) <= chance then
            local addOk = pcall(function()
                return player.Functions.AddItem('cryptostick', 1, false)
            end)
            if addOk then
                pcall(function()
                    TriggerClientEvent('inventory:client:ItemBox', src, itemCryptostick, 'add')
                end)
            else
                log('cryptostick 付与に失敗: src=%s', src)
            end
        end
    end

    return true, 'ok', finalPay
end

-- qb-taxijob / qbx_taxijob 互換（qb-taxi イベント名）
RegisterNetEvent('qb-taxi:server:NpcPay', function(payment)
    local src = source
    handleNpcPay(src, payment)
end)

-- jp 命名（内部/将来互換用）
RegisterNetEvent('jp-taxijob:server:npcPay', function(payment)
    local src = source
    handleNpcPay(src, payment)
end)

---@return number|nil
local function spawnCompanyCabForPlayer(src, model, coords4)
    if not isJobAllowed(src) then
        return nil
    end
    if type(model) ~= 'string' or not coords4 then
        return nil
    end

    local netId, veh = qbx.spawnVehicle({
        model = model,
        spawnSource = coords4,
        warp = GetPlayerPed(src --[[@as number]]),
    })

    if not netId or not veh then
        return nil
    end

    local plate = 'TAXI' .. tostring(math.random(1000, 9999))
    SetVehicleNumberPlateText(veh, plate)
    TriggerClientEvent('vehiclekeys:client:SetOwner', src, plate)

    rememberCompanyCab(src, netId)
    return netId
end

lib.callback.register('jp-taxijob:server:spawnCompanyCab', function(source, model, coords4)
    return spawnCompanyCabForPlayer(source, model, coords4)
end)

-- qb 互換（既存 qbx）
lib.callback.register('qb-taxi:server:spawnTaxi', function(source, model, coords4)
    return spawnCompanyCabForPlayer(source, model, coords4)
end)

lib.callback.register('jp-taxijob:server:deleteCompanyCab', function(source, netId)
    local src = source
    if companyCabNetId[src] and netId and companyCabNetId[src] ~= netId then
        -- 追跡と異なるnetId: 念のため拒否（チートの可能性）
        return false
    end
    local ok = deleteEntityByNetId(src, netId)
    if ok then
        forgetCompanyCab(src)
    end
    return ok
end)

RegisterNetEvent('jp-taxijob:server:startShift', function(mode)
    local src = source
    if not isJobAllowed(src) then
        return
    end
    log('startShift src=%s mode=%s job=%s', src, tostring(mode), tostring(getPlayerJobName(src)))
end)

RegisterNetEvent('jp-taxijob:server:endShift', function()
    local src = source
    if not isJobAllowed(src) then
        return
    end
    log('endShift src=%s job=%s', src, tostring(getPlayerJobName(src)))
end)

AddEventHandler('playerDropped', function()
    local src = source
    local netId = companyCabNetId[src]
    if netId then
        deleteEntityByNetId(src, netId)
    end
    forgetCompanyCab(src)
end)

-- チャット用コマンドは server/bootstrap.lua で登録（main より前）
