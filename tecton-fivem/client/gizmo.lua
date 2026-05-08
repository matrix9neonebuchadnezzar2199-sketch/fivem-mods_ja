-- SPDX-License-Identifier: LGPL-3.0-or-later

---@diagnostic disable: undefined-global

local M = {}

---@param handle integer
---@return table|nil result { handle, position, rotation } from object_gizmo, or nil
function M.editEntity(handle)
    if not handle or not DoesEntityExist(handle) then
        return nil
    end
    local ok, result = pcall(function()
        return exports.object_gizmo:useGizmo(handle)
    end)
    if not ok then
        print(('^1TECTON: object_gizmo failed (%s)^0'):format(tostring(result)))
        return nil
    end
    return result
end

TectonGizmo = M
