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
        --- ギズモ配置中（NUI 非表示・フォーカス外し中）
        placementActive = false,
        --- 配置 UI 非表示後、スペースまたは /tecResume でビルダーを戻す待ち
        uiResumeAfterPlacement = false,
        propsDictionary = nil,
        propsCategories = nil,
        propsVersion = nil,
        propsLoaded = false,
        propsError = false,
        propsCount = 0,
    }
else
    TectonClient.spawnedHandles = TectonClient.spawnedHandles or {}
    TectonClient.placementActive = TectonClient.placementActive or false
    TectonClient.uiResumeAfterPlacement = TectonClient.uiResumeAfterPlacement or false
end

TectonModeHandlers = TectonModeHandlers or {}
