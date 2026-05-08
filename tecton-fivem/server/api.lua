-- SPDX-License-Identifier: LGPL-3.0-or-later

assert(TectonDB, '[TECTON] TectonDB not loaded — check server_scripts order in fxmanifest.lua')

---@param src number
---@return boolean
local function canUse(src)
    if Config.Debug and Config.Debug.bypassPermission then
        return true
    end
    return IsPlayerAceAllowed(src, 'tecton.use')
end

---@param src number
---@return string
local function primaryIdentifier(src)
    local lic = GetPlayerIdentifierByType and GetPlayerIdentifierByType(src, 'license') or nil
    if lic and lic ~= '' then
        return lic
    end
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:sub(1, 8) == 'license:' then
            return id
        end
    end
    return 'unknown'
end

---@param src number
---@param msg string
local function vlog(src, msg)
    if Config.Debug and Config.Debug.verbose then
        print(('[TECTON] src=%s %s'):format(tostring(src), msg))
    end
end

---@param scene_id string
local function refreshAutosave(scene_id)
    local snap = TectonDB.buildSnapshot(scene_id)
    TectonDB.upsertAutosave(scene_id, snap)
end

lib.callback.register('tecton:op:create', function(source, payload)
    if not canUse(source) then
        vlog(source, 'op:create denied')
        return nil
    end
    if type(payload) ~= 'table' then
        return nil
    end
    local scene_id = payload.scene_id or Config.DefaultScene
    local obj = {
        category = payload.category or 'furniture',
        model = payload.model,
        pos = payload.pos or { x = 0.0, y = 0.0, z = 0.0 },
        rot = payload.rot or { x = 0.0, y = 0.0, z = 0.0 },
        meta = payload.meta or {},
        scene_id = scene_id,
        created_by = primaryIdentifier(source),
    }
    if not obj.model or obj.model == '' then
        return nil
    end
    local id = TectonDB.insertObject(obj)
    if not id then
        vlog(source, 'op:create insert failed')
        return nil
    end
    TectonDB.appendHistory({
        type = OpType.CREATE,
        target_id = id,
        before = nil,
        after = { id = id, category = obj.category, model = obj.model, scene_id = scene_id },
        scene_id = scene_id,
        user_id = primaryIdentifier(source),
    })
    refreshAutosave(scene_id)
    vlog(source, ('op:create id=%s model=%s'):format(tostring(id), obj.model))
    return id
end)

lib.callback.register('tecton:op:update', function(source, id, after)
    if not canUse(source) then
        return false
    end
    if type(id) ~= 'number' and type(id) ~= 'string' then
        return false
    end
    id = tonumber(id) --[[@as number]]
    if not after or type(after) ~= 'table' then
        return false
    end
    local rows = MySQL.query.await([[SELECT * FROM tec_objects WHERE id = ? AND deleted_at IS NULL]], { id })
    local beforeRow = rows and rows[1]
    if not beforeRow then
        return false
    end
    local beforeObj = {
        id = beforeRow.id,
        category = beforeRow.category,
        model = beforeRow.model,
        pos = { x = beforeRow.pos_x, y = beforeRow.pos_y, z = beforeRow.pos_z },
        rot = { x = beforeRow.rot_x, y = beforeRow.rot_y, z = beforeRow.rot_z },
        meta = type(beforeRow.meta) == 'string' and json.decode(beforeRow.meta) or beforeRow.meta or {},
        scene_id = beforeRow.scene_id,
    }
    local upd = {
        category = after.category or beforeObj.category,
        model = after.model or beforeObj.model,
        pos = after.pos or beforeObj.pos,
        rot = after.rot or beforeObj.rot,
        meta = after.meta ~= nil and after.meta or beforeObj.meta,
        scene_id = after.scene_id or beforeObj.scene_id,
    }
    local ok = TectonDB.updateObject(id, upd)
    if not ok then
        return false
    end
    local scene_id = upd.scene_id
    TectonDB.appendHistory({
        type = OpType.UPDATE,
        target_id = id,
        before = beforeObj,
        after = upd,
        scene_id = scene_id,
        user_id = primaryIdentifier(source),
    })
    refreshAutosave(scene_id)
    vlog(source, ('op:update id=%s'):format(tostring(id)))
    return true
end)

lib.callback.register('tecton:op:delete', function(source, id)
    if not canUse(source) then
        return false
    end
    id = tonumber(id)
    if not id then
        return false
    end
    local rows = MySQL.query.await([[SELECT * FROM tec_objects WHERE id = ? AND deleted_at IS NULL]], { id })
    local row = rows and rows[1]
    if not row then
        return false
    end
    local scene_id = row.scene_id
    local beforeObj = {
        id = row.id,
        category = row.category,
        model = row.model,
        pos = { x = row.pos_x, y = row.pos_y, z = row.pos_z },
        rot = { x = row.rot_x, y = row.rot_y, z = row.rot_z },
        meta = type(row.meta) == 'string' and json.decode(row.meta) or row.meta or {},
        scene_id = scene_id,
    }
    local ok = TectonDB.softDeleteObject(id)
    if not ok then
        return false
    end
    TectonDB.appendHistory({
        type = OpType.DELETE,
        target_id = id,
        before = beforeObj,
        after = nil,
        scene_id = scene_id,
        user_id = primaryIdentifier(source),
    })
    refreshAutosave(scene_id)
    vlog(source, ('op:delete id=%s'):format(tostring(id)))
    return true
end)

lib.callback.register('tecton:scene:load', function(source, scene_id)
    if not canUse(source) then
        return {}
    end
    scene_id = scene_id or Config.DefaultScene
    vlog(source, ('scene:load %s'):format(scene_id))
    return TectonDB.fetchScene(scene_id)
end)

lib.callback.register('tecton:autosave:peek', function(source, scene_id)
    if not canUse(source) then
        return nil
    end
    scene_id = scene_id or Config.DefaultScene
    return TectonDB.fetchAutosave(scene_id)
end)
