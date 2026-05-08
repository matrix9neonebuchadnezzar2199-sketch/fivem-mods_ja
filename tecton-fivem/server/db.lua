-- SPDX-License-Identifier: LGPL-3.0-or-later

local M = {}

---@param v any
---@return string
local function jsonEncode(v)
    if v == nil then
        return 'null'
    end
    return json.encode(v)
end

---@param v any
---@return table
local function jsonDecode(v)
    if v == nil then
        return {}
    end
    if type(v) == 'table' then
        return v
    end
    if type(v) == 'string' then
        local ok, t = pcall(json.decode, v)
        if ok and type(t) == 'table' then
            return t
        end
    end
    return {}
end

---@param row table
---@return table
local function rowToObject(row)
    return {
        id = row.id,
        category = row.category,
        model = row.model,
        pos = vector3(tonumber(row.pos_x) or 0.0, tonumber(row.pos_y) or 0.0, tonumber(row.pos_z) or 0.0),
        rot = vector3(tonumber(row.rot_x) or 0.0, tonumber(row.rot_y) or 0.0, tonumber(row.rot_z) or 0.0),
        meta = jsonDecode(row.meta),
        scene_id = row.scene_id,
        created_by = row.created_by,
    }
end

---@param v vector3|table|nil
---@return number, number, number
local function vecCoords(v, dx, dy, dz)
    if not v then
        return dx, dy, dz
    end
    if type(v) == 'vector3' then
        return v.x, v.y, v.z
    end
    return tonumber(v.x) or dx, tonumber(v.y) or dy, tonumber(v.z) or dz
end

---@param obj table
---@return number|nil id
function M.insertObject(obj)
    local meta = jsonEncode(obj.meta or {})
    local px, py, pz = vecCoords(obj.pos, 0.0, 0.0, 0.0)
    local rx, ry, rz = vecCoords(obj.rot, 0.0, 0.0, 0.0)
    local id = MySQL.insert.await(
        [[INSERT INTO tec_objects (category, model, pos_x, pos_y, pos_z, rot_x, rot_y, rot_z, meta, scene_id, created_by)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)]],
        {
            obj.category,
            obj.model,
            px,
            py,
            pz,
            rx,
            ry,
            rz,
            meta,
            obj.scene_id,
            obj.created_by,
        }
    )
    return id
end

---@param id number
---@param obj table
---@return boolean
function M.updateObject(id, obj)
    local meta = jsonEncode(obj.meta or {})
    local px, py, pz = vecCoords(obj.pos, 0.0, 0.0, 0.0)
    local rx, ry, rz = vecCoords(obj.rot, 0.0, 0.0, 0.0)
    local n = MySQL.update.await(
        [[UPDATE tec_objects SET
            category = ?, model = ?, pos_x = ?, pos_y = ?, pos_z = ?,
            rot_x = ?, rot_y = ?, rot_z = ?, meta = ?, scene_id = ?, updated_at = CURRENT_TIMESTAMP
            WHERE id = ? AND deleted_at IS NULL]],
        {
            obj.category,
            obj.model,
            px,
            py,
            pz,
            rx,
            ry,
            rz,
            meta,
            obj.scene_id,
            id,
        }
    )
    return (n or 0) > 0
end

---@param id number
---@return boolean
function M.softDeleteObject(id)
    local n = MySQL.update.await(
        [[UPDATE tec_objects SET deleted_at = CURRENT_TIMESTAMP WHERE id = ? AND deleted_at IS NULL]],
        { id }
    )
    return (n or 0) > 0
end

---@param scene_id string
---@return table[]
function M.fetchScene(scene_id)
    local rows = MySQL.query.await(
        [[SELECT * FROM tec_objects WHERE scene_id = ? AND deleted_at IS NULL ORDER BY id ASC]],
        { scene_id }
    )
    if not rows then
        return {}
    end
    local out = {}
    for _, row in ipairs(rows) do
        out[#out + 1] = rowToObject(row)
    end
    return out
end

---@param op table
---@return number|nil id
function M.appendHistory(op)
    local before = op.before and jsonEncode(op.before) or nil
    local after = op.after and jsonEncode(op.after) or nil
    local action = op.action or op.type
    local id = MySQL.insert.await(
        [[INSERT INTO tec_history (scene_id, user_id, action, target_id, before_data, after_data)
           VALUES (?, ?, ?, ?, ?, ?)]],
        {
            op.scene_id,
            op.user_id,
            action,
            op.target_id,
            before,
            after,
        }
    )
    return id
end

---@param scene_id string
---@param snapshot table
---@return boolean
function M.upsertAutosave(scene_id, snapshot)
    local snap = jsonEncode(snapshot)
    MySQL.query.await(
        [[INSERT INTO tec_autosave (scene_id, snapshot) VALUES (?, ?)
           ON DUPLICATE KEY UPDATE snapshot = VALUES(snapshot), updated_at = CURRENT_TIMESTAMP]],
        { scene_id, snap }
    )
    return true
end

---@param scene_id string
---@return table|nil
function M.fetchAutosave(scene_id)
    local row = MySQL.single.await([[SELECT snapshot FROM tec_autosave WHERE scene_id = ?]], { scene_id })
    if not row or row.snapshot == nil then
        return nil
    end
    return jsonDecode(row.snapshot)
end

--- Build JSON-serializable snapshot for tec_autosave (vector3 → plain tables).
---@param scene_id string
---@return table
function M.buildSnapshot(scene_id)
    local objs = M.fetchScene(scene_id)
    local list = {}
    for _, o in ipairs(objs) do
        list[#list + 1] = {
            id = o.id,
            category = o.category,
            model = o.model,
            pos = { x = o.pos.x, y = o.pos.y, z = o.pos.z },
            rot = { x = o.rot.x, y = o.rot.y, z = o.rot.z },
            meta = o.meta,
            scene_id = o.scene_id,
            created_by = o.created_by,
        }
    end
    return { version = 1, scene_id = scene_id, objects = list }
end

TectonDB = M
return M
