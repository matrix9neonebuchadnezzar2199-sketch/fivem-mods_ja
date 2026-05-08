-- SPDX-License-Identifier: LGPL-3.0-or-later

--- ビルダー UI 状態と、DB id → エンティティハンドル（M1-c〜）。
--- TectonModeHandlers の入れ物。必ず main.lua より先に読み込む（fxmanifest 順）。

if not TectonClient then
    TectonClient = {
        spawnedHandles = {},
        scene = Config.DefaultScene or 'default',
        selected = nil,
        mode = 'furniture',
        open = false,
        propsDictionary = nil,
        propsCategories = nil,
        propsVersion = nil,
        propsLoaded = false,
        propsError = false,
        propsCount = 0,
    }
else
    TectonClient.spawnedHandles = TectonClient.spawnedHandles or {}
end

TectonModeHandlers = TectonModeHandlers or {}
