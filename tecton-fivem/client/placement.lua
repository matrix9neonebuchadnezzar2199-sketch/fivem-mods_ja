-- SPDX-License-Identifier: LGPL-3.0-or-later

---@diagnostic disable: undefined-global

local M = {}

---@param v any
---@return vector3
local function asVec3(v)
    if not v then
        return vector3(0.0, 0.0, 0.0)
    end
    if type(v) == 'vector3' then
        return v
    end
    local x = tonumber(v.x) or 0.0
    local y = tonumber(v.y) or 0.0
    local z = tonumber(v.z) or 0.0
    return vector3(x, y, z)
end

---@param model string|integer
---@return table|nil { handle, model = string, pos = vector3, rot = vector3 }
function M.startPlacement(model)
    if not model or model == '' then
        return nil
    end
    lib.requestModel(model, 10000)
    local hash = type(model) == 'string' and joaat(model) or model
    local ped = PlayerPedId()
    local spawn = GetOffsetFromEntityInWorldCoords(ped, 0.0, 3.0, 0.0)
    local heading = GetEntityHeading(ped)
    local handle = CreateObject(hash, spawn.x, spawn.y, spawn.z, false, false, false)
    if not handle or handle == 0 then
        SetModelAsNoLongerNeeded(hash)
        return nil
    end
    SetEntityHeading(handle, heading)
    PlaceObjectOnGroundProperly(handle)
    local gizmo = TectonGizmo
    if not gizmo or type(gizmo.editEntity) ~= 'function' then
        SetEntityAsMissionEntity(handle, true, true)
        DeleteEntity(handle)
        SetModelAsNoLongerNeeded(hash)
        return nil
    end
    local result = gizmo.editEntity(handle)
    if not result then
        if DoesEntityExist(handle) then
            SetEntityAsMissionEntity(handle, true, true)
            DeleteEntity(handle)
        end
        SetModelAsNoLongerNeeded(hash)
        return nil
    end
    local pos = asVec3(result.position or result.pos)
    local rot = asVec3(result.rotation or result.rot)
    local outHandle = result.handle or handle
    if not DoesEntityExist(outHandle) then
        SetModelAsNoLongerNeeded(hash)
        return nil
    end
    SetEntityCoords(outHandle, pos.x, pos.y, pos.z, false, false, false, false)
    SetEntityRotation(outHandle, rot.x, rot.y, rot.z, 2, true)
    local modelName = type(model) == 'string' and model or tostring(model)
    SetModelAsNoLongerNeeded(hash)
    return {
        handle = outHandle,
        model = modelName,
        pos = pos,
        rot = rot,
    }
end

---@param obj table TectonObject-like { model, pos, rot }
---@return integer|nil handle
function M.spawnExistingObject(obj)
    if not obj or not obj.model then
        return nil
    end
    lib.requestModel(obj.model, 10000)
    local hash = joaat(obj.model)
    local pos = asVec3(obj.pos)
    local rot = asVec3(obj.rot)
    local handle = CreateObject(hash, pos.x, pos.y, pos.z, false, false, false)
    if not handle or handle == 0 then
        SetModelAsNoLongerNeeded(hash)
        return nil
    end
    SetEntityRotation(handle, rot.x, rot.y, rot.z, 2, true)
    SetModelAsNoLongerNeeded(hash)
    return handle
end

---@param handle integer|nil
function M.removeObject(handle)
    if handle and handle ~= 0 and DoesEntityExist(handle) then
        SetEntityAsMissionEntity(handle, true, true)
        DeleteEntity(handle)
    end
end

TectonPlacement = M
