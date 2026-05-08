-- SPDX-License-Identifier: LGPL-3.0-or-later
--[[
  Category tree + prop dictionary (schema scaffold).
  Import pipeline: tools/import_props.mjs (planned). See docs/ja/spec.md §5.
]]

Config = Config or {}
Config.Props = Config.Props or {
    ---@type table[] categories with nested children + props
    categories = {},
    ---@type table<string, table> model name → metadata (tags, tintable, …)
    dictionary = {},
}
