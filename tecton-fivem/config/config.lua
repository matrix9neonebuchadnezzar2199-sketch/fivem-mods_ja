-- SPDX-License-Identifier: LGPL-3.0-or-later

Config = Config or {}
Config.DefaultScene = 'default'

Config.Autosave = {
    interval = 'per_op',
    historyLimit = 500,
}

Config.Snap = {
    grid = 0.1,
    rotation = 15.0,
    surface = true,
    edge = true,
    edgeRange = 0.25,
}

Config.UI = {
    recentLimit = 30,
    hiContrast = false,
}

Config.Keys = {
    openBuilder = 'F2',
    help = 'F1',
}

Config.Debug = {
    bypassPermission = true,
    verbose = true,
    -- M1-a のみ: true のとき `/testTectonInsert` が有効。DB 確認後は必ず false。
    testTectonInsert = false,
}
