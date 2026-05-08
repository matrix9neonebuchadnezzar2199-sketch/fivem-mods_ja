-- SPDX-License-Identifier: LGPL-3.0-or-later

--[[
  TECTON — shared documentation types (LuaLS / human reference).
  Lua does not enforce these shapes at runtime.

  TectonObject:
    id         number|nil       DB row id (nil before insert)
    category   string           e.g. "furniture", "door"
    model      string           GTA model name
    pos        vector3          world position
    rot        vector3          world rotation (degrees)
    meta       table            arbitrary JSON-serializable metadata
    scene_id   string           scene partition key
    created_by string|nil       creator identifier (e.g. license:)

  TectonOp (history / undo pipeline):
    type       string           OpType: "create" | "update" | "delete"
    target_id  number|nil      tec_objects.id (nil for batch-only ops)
    before     table|nil        snapshot before change (JSON-serializable)
    after      table|nil        snapshot after change
    scene_id   string
    user_id    string|nil       actor identifier
]]

---@class TectonObject
---@field id number|nil
---@field category string
---@field model string
---@field pos vector3
---@field rot vector3
---@field meta table
---@field scene_id string
---@field created_by string|nil

---@class TectonOp
---@field type 'create'|'update'|'delete'
---@field target_id number|nil
---@field before table|nil
---@field after table|nil
---@field scene_id string
---@field user_id string|nil
