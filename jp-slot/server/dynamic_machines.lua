-- 動的台の CRUD・KVS・静的台との重複検査（確率は触れない）
DynamicMachines = {}

local KVP_KEY = 'jp-slot:dynamic_machines'
local cache = {} ---@type table[]
local idCounter = 0

--- coords を数値テーブルに正規化（vector3 のままだと json.encode で壊れるためテーブル維持）
---@param m table
---@return table
local function normalizeCoordsTable(m)
    if not m or type(m.coords) ~= 'table' then
        return m
    end
    local c = m.coords
    if c.x then
        m.coords = { x = c.x + 0.0, y = c.y + 0.0, z = c.z + 0.0 }
    end
    return m
end

--- 新規 ID（同一秒内は連番サフィックス）
---@return string
local function newId()
    local t = os.time()
    idCounter = idCounter + 1
    return ('machine_dyn_%d_%d'):format(t, idCounter)
end

--- KVS から読込
function DynamicMachines.load()
    cache = {}
    local raw = GetResourceKvpString(KVP_KEY)
    if raw and raw ~= '' then
        local ok, decoded = pcall(json.decode, raw)
        if ok and type(decoded) == 'table' then
            cache = decoded
        end
    end
    for i = 1, #cache do
        normalizeCoordsTable(cache[i])
    end
    return cache
end

--- KVS へ保存
function DynamicMachines.save()
    SetResourceKvp(KVP_KEY, json.encode(cache))
end

--- メモリのコピー（参照ではなく浅い複製が必要な場合は個別に）
---@return table[]
function DynamicMachines.getAll()
    local out = {}
    for i = 1, #cache do
        out[i] = cache[i]
    end
    return out
end

---@param id string|nil
---@return table|nil
function DynamicMachines.get(id)
    if not id then
        return nil
    end
    for i = 1, #cache do
        if cache[i].id == id then
            return cache[i]
        end
    end
    return nil
end

--- 静的台の座標一覧（重複検査用）
---@return table[]
local function staticCoordsList()
    local out = {}
    local list = Config.Machines or {}
    for i = 1, #list do
        local c = list[i].coords
        if c and c.x then
            out[#out + 1] = { x = c.x, y = c.y, z = c.z }
        end
    end
    return out
end

--- 3D 距離
---@param a table|vector3
---@param b table|vector3
---@return number
local function dist3(a, b)
    local ax, ay, az = a.x, a.y, a.z
    local bx, by, bz = b.x, b.y, b.z
    local dx, dy, dz = ax - bx, ay - by, az - bz
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

---@param coords table|vector3
---@param radius number
---@return boolean
function DynamicMachines.hasDuplicateNearby(coords, radius)
    radius = radius or (Config.DynamicPlacement and Config.DynamicPlacement.DuplicateGuard) or 1.0
    local cx = coords.x + 0.0
    local cy = coords.y + 0.0
    local cz = coords.z + 0.0
    local sc = staticCoordsList()
    for i = 1, #sc do
        if dist3(coords, sc[i]) < radius then
            return true
        end
    end
    for i = 1, #cache do
        local c = cache[i].coords
        if c and c.x and dist3(coords, c) < radius then
            return true
        end
    end
    return false
end

---@param coords table|vector3
---@param radius number
---@return table|nil, number|nil
function DynamicMachines.findNearest(coords, radius)
    radius = radius or 3.0
    local best, bestD = nil, radius + 1.0
    for i = 1, #cache do
        local m = cache[i]
        local c = m.coords
        if c and c.x then
            local d = dist3(coords, c)
            if d < bestD then
                bestD = d
                best = m
            end
        end
    end
    if best and bestD <= radius then
        return best, bestD
    end
    return nil, nil
end

---@param data table
---@param createdBy string|nil
---@return boolean, string|nil, table|nil
function DynamicMachines.add(data, createdBy)
    if type(data) ~= 'table' then
        return false, 'invalid_data', nil
    end
    local pk = data.propKey
    local ck = data.characterId
    local ptid = data.paytableId
    if not pk or not Config.PropModels[pk] then
        return false, 'invalid_prop', nil
    end
    if not ck or not Config.Characters[ck] then
        return false, 'invalid_char', nil
    end
    if not ptid or not Config.Paytables[ptid] then
        return false, 'invalid_paytable', nil
    end
    local c = data.coords
    if type(c) ~= 'table' or not tonumber(c.x) or not tonumber(c.y) or not tonumber(c.z) then
        return false, 'invalid_coords', nil
    end
    local guard = (Config.DynamicPlacement and Config.DynamicPlacement.DuplicateGuard) or 1.0
    if DynamicMachines.hasDuplicateNearby(c, guard) then
        return false, 'duplicate', nil
    end
    local minB = math.floor(tonumber(data.minBet) or 100)
    local maxB = math.floor(tonumber(data.maxBet) or 10000)
    if minB < 1 or maxB < minB then
        return false, 'invalid_bet_range', nil
    end
    local id = newId()
    local entry = {
        id = id,
        coords = { x = c.x + 0.0, y = c.y + 0.0, z = c.z + 0.0 },
        heading = (tonumber(data.heading) or 0.0) + 0.0,
        propKey = pk,
        prop = Config.PropModels[pk],
        characterId = ck,
        paytableId = ptid,
        minBet = minB,
        maxBet = maxB,
        displayName = data.displayName or id,
        machineDescriptionLocaleKey = data.machineDescriptionLocaleKey,
        themeOverride = data.themeOverride,
        createdBy = createdBy or '',
        createdAt = os.time(),
        isDynamic = true,
    }
    normalizeCoordsTable(entry)
    cache[#cache + 1] = entry
    DynamicMachines.save()
    return true, nil, entry
end

---@param id string|nil
---@return boolean
function DynamicMachines.remove(id)
    if not id then
        return false
    end
    for i = 1, #cache do
        if cache[i].id == id then
            table.remove(cache, i)
            DynamicMachines.save()
            return true
        end
    end
    return false
end

---@param id string|nil
---@param field string|nil
---@param value any
---@return boolean, string|nil
function DynamicMachines.update(id, field, value)
    local m = DynamicMachines.get(id)
    if not m then
        return false, 'not_found'
    end
    if field == 'propKey' then
        if not Config.PropModels[value] then
            return false, 'invalid_prop'
        end
        m.propKey = value
        m.prop = Config.PropModels[value]
    elseif field == 'charId' or field == 'characterId' then
        local cid = tostring(value)
        if not Config.Characters[cid] then
            return false, 'invalid_char'
        end
        m.characterId = cid
    elseif field == 'paytableId' then
        if not Config.Paytables[value] then
            return false, 'invalid_paytable'
        end
        m.paytableId = value
    elseif field == 'minBet' then
        local v = math.floor(tonumber(value) or 0)
        if v < 1 then
            return false, 'invalid_min'
        end
        m.minBet = v
        if m.maxBet and m.minBet > m.maxBet then
            return false, 'min_gt_max'
        end
    elseif field == 'maxBet' then
        local v = math.floor(tonumber(value) or 0)
        if v < 1 then
            return false, 'invalid_max'
        end
        m.maxBet = v
        if m.minBet and m.minBet > m.maxBet then
            return false, 'min_gt_max'
        end
    elseif field == 'displayName' then
        m.displayName = tostring(value)
    else
        return false, 'bad_field'
    end
    DynamicMachines.save()
    return true, nil
end

---@param id string|nil
---@param coords table
---@param heading number
---@return boolean, string|nil
function DynamicMachines.setPosition(id, coords, heading)
    local m = DynamicMachines.get(id)
    if not m then
        return false, 'not_found'
    end
    if type(coords) ~= 'table' or not tonumber(coords.x) then
        return false, 'bad_coords'
    end
    local guard = (Config.DynamicPlacement and Config.DynamicPlacement.DuplicateGuard) or 1.0
    local test = { x = coords.x + 0.0, y = coords.y + 0.0, z = coords.z + 0.0 }
    for i = 1, #cache do
        if cache[i].id ~= id and cache[i].coords then
            if dist3(test, cache[i].coords) < guard then
                return false, 'duplicate'
            end
        end
    end
    for _, sc in ipairs(staticCoordsList()) do
        if dist3(test, sc) < guard then
            return false, 'duplicate_static'
        end
    end
    m.coords = { x = test.x, y = test.y, z = test.z }
    m.heading = (tonumber(heading) or 0.0) + 0.0
    normalizeCoordsTable(m)
    DynamicMachines.save()
    return true, nil
end

---@param id string|nil
---@param addDeg number
---@return boolean, string|nil
function DynamicMachines.addHeading(id, addDeg)
    local m = DynamicMachines.get(id)
    if not m then
        return false, 'not_found'
    end
    local h = (tonumber(m.heading) or 0.0) + (tonumber(addDeg) or 90.0)
    while h < 0 do
        h = h + 360.0
    end
    while h >= 360.0 do
        h = h - 360.0
    end
    m.heading = h
    DynamicMachines.save()
    return true, nil
end

--- 静的 Config.Machines + 動的 cache を結合した配列（参照用コピーは浅い）
---@return table[]
function DynamicMachines.getAllCombined()
    local out = {}
    local n = 0
    local sm = Config.Machines or {}
    for i = 1, #sm do
        n = n + 1
        out[n] = sm[i]
    end
    for i = 1, #cache do
        n = n + 1
        out[n] = cache[i]
    end
    return out
end

DynamicMachines.load()
print(('[jp-slot] 動的台をロード: %d 件'):format(#cache))
