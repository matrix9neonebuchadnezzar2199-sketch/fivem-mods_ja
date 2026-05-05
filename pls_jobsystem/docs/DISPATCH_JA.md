# 通報（ディスパッチ）連携

アラームや「警察を呼ぶ」アクションが発火した際、`config.lua` の `SendDispatch(coords, jobLabel)` が呼ばれます。お使いの通報リソースに合わせて中身を実装してください。

## ps-dispatch

```lua
function SendDispatch(coords, jobLabel)
    local data = exports['ps-dispatch']:GetPlayerInfo()
    TriggerServerEvent('ps-dispatch:server:notify', {
        dispatchCodeName = 'storealarm',
        firstStreet = data.street,
        gender = data.gender,
        priority = 2,
        coords = coords,
        message = ('%s で警報が作動'):format(jobLabel),
    })
end
```

## cd_dispatch

```lua
function SendDispatch(coords, jobLabel)
    local data = exports['cd_dispatch']:GetPlayerInfo()
    TriggerServerEvent('cd_dispatch:AddNotification', {
        job_table = { 'police' },
        coords = coords,
        title = '警報',
        message = ('%s で警報'):format(jobLabel),
        flash = 0, unique_id = data.unique_id, sound = 1, blip = {
            sprite = 431, scale = 1.2, colour = 1, flashes = false,
            text = ('警報: %s'):format(jobLabel),
            time = (5 * 60 * 1000), sound = 1
        }
    })
end
```

## linden_outlawalert / lb-tablet 等

各リソースの README に従って `TriggerServerEvent` / `exports` を呼び替えてください。`coords`（vector3）と `jobLabel`（文字列）はそのまま渡せます。

## 通報を無効化したい

関数の中身を空にすればアラームの UI 通知のみが残ります。

```lua
function SendDispatch(coords, jobLabel) end
```
