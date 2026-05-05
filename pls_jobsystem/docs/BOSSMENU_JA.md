# ボスメニュー連携

`pls_jobsystem` 自体はボスメニューを内蔵していません。代わりに `config.lua` の `openBossmenu(jobName)` 関数の中で、お使いの社会管理リソースを呼び出します。

## ESX (esx_society)

```lua
function openBossmenu(jobName)
    TriggerEvent('esx_society:openBossMenu', jobName, function(data, menu)
        menu.close()
    end, { wash = false })
end
```

## QBCore (qb-management)

```lua
function openBossmenu(jobName)
    TriggerEvent('qb-bossmenu:client:OpenMenu')
end
```

## OX (esx_society 風 export 自前実装)

OX には公式ボスメニューが無いため、独自に export を用意するか、互換ブリッジを利用してください。

## 動作確認

1. ジョブにボスのグレード（`is_boss = true` 等）でログインしているプレイヤーで `/open_jobs` を開く
2. 「ボスメニュー」を選択
3. 連携先のメニューが開けば成功

開かない場合は、F8 コンソールで `openBossmenu` 内の `print` を入れて呼び出されているかをまず確認してください。
