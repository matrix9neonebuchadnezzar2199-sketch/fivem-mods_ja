-- スロット台プロップ（静的 Config + 動的 KVS）。Machines = {} はグローバル。
Machines = {}

local spawned = {} ---@type table<string, number>
--- 動的台の定義キャッシュ（距離判定用）
local dynamicDefs = {} ---@type table<string, table>

--- モデル読込
---@param model string|number
---@return number|nil
local function loadModel(model)
    local hash = type(model) == 'string' and joaat(model) or model
    if not hash then
        return nil
    end
    RequestModel(hash)
    local t = GetGameTimer() + 500
    while not HasModelLoaded(hash) do
        Wait(10)
        if GetGameTimer() > t then
            return nil
        end
    end
    return hash
end

--- prop / propKey からモデル名を決定
---@param def table
---@return string|nil
local function resolveModelName(def)
    if def.prop and type(def.prop) == 'string' then
        return def.prop
    end
    if def.propKey and Config.PropModels and Config.PropModels[def.propKey] then
        return Config.PropModels[def.propKey]
    end
    return 'vw_prop_casino_slot_01a'
end

--- 1台スポーン（静的・動的共通）
---@param def table
function Machines.spawnOne(def)
    if not def or not def.id then
        return
    end
    Machines.deleteOne(def.id)
    local modelName = resolveModelName(def)
    local hash = loadModel(modelName)
    if not hash then
        print('[jp-slot] モデル読込失敗: ' .. tostring(modelName))
        return
    end
    local c = def.coords
    local x, y, z
    if type(c) == 'vector3' then
        x, y, z = c.x + 0.0, c.y + 0.0, c.z + 0.0
    elseif type(c) == 'table' and c.x then
        x, y, z = c.x + 0.0, c.y + 0.0, c.z + 0.0
    else
        SetModelAsNoLongerNeeded(hash)
        return
    end
    local e = CreateObject(hash, x, y, z, false, false, false)
    if not e or e == 0 then
        SetModelAsNoLongerNeeded(hash)
        return
    end
    local heading = (def.heading or 0.0) + 0.0
    local extra = (Config.DynamicPlacement and Config.DynamicPlacement.GroundOffset) or 0.0
    if Config.MachineGroundSnap and Config.MachineGroundSnap.Enabled ~= false then
        -- Z だけ地面に合わせ、配置したい X/Y は config のまま（ペッド位置由来の Z ずれ対策）
        PlaceObjectOnGroundProperly(e)
        local p = GetEntityCoords(e)
        SetEntityCoords(e, x, y, p.z + extra, false, false, false, false)
        SetEntityHeading(e, heading)
    else
        SetEntityHeading(e, heading)
        if extra ~= 0.0 then
            SetEntityCoords(e, x, y, z + extra, false, false, false, false)
        end
    end
    FreezeEntityPosition(e, true)
    SetEntityAsMissionEntity(e, true, true)
    spawned[def.id] = e
    SetModelAsNoLongerNeeded(hash)
end

---@param machineId string|nil
function Machines.deleteOne(machineId)
    local ent = spawned[machineId]
    if ent and DoesEntityExist(ent) then
        DeleteEntity(ent)
    end
    spawned[machineId] = nil
end

--- config 由来の静的台のみ一括
function Machines.spawnAll()
    local list = Config.Machines or {}
    for i = 1, #list do
        Machines.spawnOne(list[i])
    end
end

--- 動的台一覧で差し替え同期
---@param list table[]|nil
function Machines.applyDynamicSync(list)
    local oldIds = {}
    for id, _ in pairs(dynamicDefs) do
        oldIds[#oldIds + 1] = id
    end
    for i = 1, #oldIds do
        local mid = oldIds[i]
        dynamicDefs[mid] = nil
        Machines.deleteOne(mid)
    end
    if type(list) ~= 'table' then
        return
    end
    for i = 1, #list do
        local m = list[i]
        if m and m.id then
            dynamicDefs[m.id] = m
            Machines.spawnOne(m)
        end
    end
end

--- 全削除（リソース停止時）
function Machines.cleanup()
    for k, _ in pairs(spawned) do
        Machines.deleteOne(k)
    end
end

---@param machineId string|nil
---@return number|nil
function Machines.getEntity(machineId)
    local e = spawned[machineId]
    if e and DoesEntityExist(e) then
        return e
    end
    return nil
end

--- 静的 + 動的を含め最寄りの台定義を返す
---@param maxDist number
---@return table|nil, number|nil
function Machines.findNearest(maxDist)
    maxDist = maxDist or 5.0
    local ped = PlayerPedId()
    local px, py, pz = table.unpack(GetEntityCoords(ped))
    local best, bestD = nil, maxDist + 1.0

    local function consider(m)
        if not m or not m.coords then
            return
        end
        local c = m.coords
        local cx, cy, cz = c.x, c.y, c.z
        local dx, dy, dz = px - cx, py - cy, pz - cz
        local d = math.sqrt(dx * dx + dy * dy + dz * dz)
        if d < bestD then
            bestD = d
            best = m
        end
    end

    local sm = Config.Machines or {}
    for i = 1, #sm do
        consider(sm[i])
    end
    for _, m in pairs(dynamicDefs) do
        consider(m)
    end

    if best and bestD <= maxDist then
        return best, bestD
    end
    return nil, nil
end

RegisterNetEvent('jp-slot:dyn:spawn', function(machineData)
    if type(machineData) ~= 'table' or not machineData.id then
        return
    end
    dynamicDefs[machineData.id] = machineData
    Machines.spawnOne(machineData)
end)

RegisterNetEvent('jp-slot:dyn:despawn', function(machineId)
    if machineId then
        dynamicDefs[machineId] = nil
    end
    Machines.deleteOne(machineId)
end)

RegisterNetEvent('jp-slot:dyn:respawn', function(machineData)
    if type(machineData) ~= 'table' or not machineData.id then
        return
    end
    dynamicDefs[machineData.id] = machineData
    Machines.spawnOne(machineData)
end)

RegisterNetEvent('jp-slot:dyn:syncAll', function(list)
    Machines.applyDynamicSync(list)
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then
        return
    end
    Machines.cleanup()
end)
