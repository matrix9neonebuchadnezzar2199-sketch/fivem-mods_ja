-- ============================================================
-- MERIDIAN-9 共通ユーティリティ
-- ============================================================

MRD9 = MRD9 or {}

---@param msg string
---@param ... any
function MRD9.Log(msg, ...)
    if Config and Config.Debug then
        print(('[jp-meridian9] ' .. msg):format(...))
    end
end

---@param v1 vector3|{ x: number, y: number, z: number }
---@param v2 vector3|{ x: number, y: number, z: number }
---@return number
function MRD9.Distance(v1, v2)
    return #(vector3(v1.x, v1.y, v1.z) - vector3(v2.x, v2.y, v2.z))
end

---@param t table
---@return integer
function MRD9.TableLength(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

---@return string
function MRD9.GenerateSessionId()
    return ('S_%d_%d'):format(os.time(), math.random(1000, 9999))
end

--- 任務論理在庫をフラット化する。案S2: `{ main = {}, safe = {} }` と旧 `{ itemId = count }` の両対応。
---@param inv table|nil
---@return table<string, integer>
function MRD9.FlattenMissionInventory(inv)
    local flat = {}
    if type(inv) ~= 'table' then
        return flat
    end
    local function merge(t)
        if type(t) ~= 'table' then
            return
        end
        for itemId, qty in pairs(t) do
            if type(itemId) == 'string' and type(qty) == 'number' and qty > 0 then
                flat[itemId] = (flat[itemId] or 0) + qty
            end
        end
    end
    if type(inv.main) == 'table' or type(inv.safe) == 'table' then
        merge(inv.main)
        merge(inv.safe)
        return flat
    end
    merge(inv)
    return flat
end
