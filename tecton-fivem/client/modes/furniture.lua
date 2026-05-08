-- SPDX-License-Identifier: LGPL-3.0-or-later

---@diagnostic disable: undefined-global

local M = {}

---@param payload table|nil
---@return table
function M.handleCreate(payload)
    if type(payload) ~= 'table' or not payload.model or payload.model == '' then
        return { ok = false, reason = 'bad_payload' }
    end
    local placement = TectonPlacement
    if not placement or type(placement.startPlacement) ~= 'function' then
        return { ok = false, reason = 'placement_unavailable' }
    end
    local result = placement.startPlacement(payload.model)
    if not result then
        return { ok = false, reason = 'cancelled' }
    end
    local client = TectonClient
    local cat = type(payload.category) == 'string' and payload.category ~= '' and payload.category or 'furniture'
    local obj = {
        category = cat,
        model = payload.model,
        pos = { x = result.pos.x, y = result.pos.y, z = result.pos.z },
        rot = { x = result.rot.x, y = result.rot.y, z = result.rot.z },
        meta = {},
        scene_id = client.scene,
    }
    local id = lib.callback.await('tecton:op:create', false, obj)
    if not id then
        placement.removeObject(result.handle)
        return { ok = false, reason = 'server_error' }
    end
    local kid = tonumber(id) or id
    client.spawnedHandles[kid] = result.handle
    return { ok = true, id = id }
end

TectonModeHandlers.furniture = M
