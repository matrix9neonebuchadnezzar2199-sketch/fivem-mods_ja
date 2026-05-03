# イベントフック（開発者向け）

他リソースから `AddEventHandler` で購読します。イベント名は **`jp-UnderworldBounty:` + 名前** です（サーバー側で `TriggerEvent` 発火）。

報復の状態・サブ結果・タイミングは **`docs/RETALIATION_FSM.md`** と整合させること。

## 一覧

| イベント名 | タイミング | payload（例） |
|-----------|------------|----------------|
| `jp-UnderworldBounty:onHeistStart` | 強盗がサーバー承認されたとき | `{ target = src, scenarioId = string, locationId = string }` |
| `jp-UnderworldBounty:onHeistComplete` | 戦闘完了・報酬付与前 | `{ target = src, scenarioId = string, locationId = string }` |
| `jp-UnderworldBounty:onHeistFail` | 失敗・キャンセル・タイムアウト等 | `{ target = src, reason = string }` |
| `jp-UnderworldBounty:onBountyTriggered` | 指名手配が付与されたとき | `{ target = src, scenarioId = string, patternId = string }` |
| `jp-UnderworldBounty:onBountyCleared` | 期限・撃退完了・死亡解除等 | `{ target = src, reason = string }` |
| `jp-UnderworldBounty:onRetaliationStart` | 襲撃ウェーブをクライアントへ送ったとき | `{ target = src, patternId = string }` |
| `jp-UnderworldBounty:onRetaliationEnd` | プレイヤーがウェーブを生き延びたとき | `{ target = src, patternId = string }` |
| `jp-UnderworldBounty:onPlayerKilled` | 報復中にプレイヤーが死亡したとき | `{ target = src, context = string }` |
| `jp-UnderworldBounty:onRetaliationAbort` | スポーン失敗等でウェーブを消費しない強制終了（FSM RESOLVING abort） | `{ target = src, reason = string }`（実装時に発火を追加） |

## サンプル（Discord 通知のフック先）

```lua
AddEventHandler('jp-UnderworldBounty:onHeistComplete', function(payload)
  local src = payload.target
  local name = GetPlayerName(src)
  print(('[UB] %s completed %s'):format(name, payload.scenarioId))
end)
```

## 注意

- 報酬額・シナリオ ID をクライアントから絶対に信用しない設計にすること（本リソースはサーバー検証を基本とする）。  
- フックは **サーバー側** のみ発火します。
