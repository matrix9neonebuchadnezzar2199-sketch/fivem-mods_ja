-- SPDX-License-Identifier: LGPL-3.0-or-later
--[[
  ACE permission names for TECTON (schema scaffold).
  See docs/ja/spec.md §5.
]]

Config = Config or {}
Config.Permissions = Config.Permissions or {
    use = 'tecton.use',
    delete = 'tecton.delete',
    admin = 'tecton.admin',
}
