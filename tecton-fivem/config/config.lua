-- SPDX-License-Identifier: LGPL-3.0-or-later
--[[
  TECTON — runtime configuration (schema scaffold).
  See docs/ja/spec.md §5 for intended keys.
]]

Config = Config or {}

---@class TectonConfig
--- Database: use oxmysql connection from server.cfg (no DSN in this file by default).
Config.Database = Config.Database or {
    --- Table prefix for SQL in sql/install.sql (tec_*).
    tablePrefix = 'tec_',
}

--- Default scene / builder session
Config.Scene = Config.Scene or {
    defaultSceneId = 'default',
}

--- Autosave interval (seconds); Undo retention count
Config.Autosave = Config.Autosave or {
    intervalSeconds = 120,
}

Config.History = Config.History or {
    maxUndo = 500,
}

--- UI theme defaults (NUI may override via user prefs)
Config.UI = Config.UI or {
    background = 'rgba(20,22,28,0.92)',
    foreground = '#F5F7FA',
    accent = '#4FC3F7',
}

--- Hotkeys (rebindable; client reads these)
Config.Keys = Config.Keys or {
    toggleBuilder = 'F2',
    help = 'F1',
}
