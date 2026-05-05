# Glitch Minigames 日本語版 — 使い方詳細

すべてのミニゲームは `exports['glitch-minigames']` から呼び出します。  
**戻り値は `success`（boolean）が基本**で、一部は追加情報を返します。

---

## スキルチェック (Skill Check)

```lua
local success = exports['glitch-minigames']:StartSkillCheckGame(
    keys, speed, timeLimit, zoneSize, perfectZoneSize, maxFailures, randomizeZone
)
```

| 引数 | 型 | デフォルト | 説明 |
|---|---|---|---|
| `keys` | table | `{'E','F','R'}` | 各ラウンドのキー（配列長＝ラウンド数） |
| `speed` | number | `65` | バー速度（%/秒） |
| `timeLimit` | number | `15000` | 全体制限時間 (ms) |
| `zoneSize` | number | `18` | 通常成功ゾーンの幅 (%, 10〜35) |
| `perfectZoneSize` | number | `5` | パーフェクトゾーンの幅 (%, 0で無効) |
| `maxFailures` | number | `1` | 許容失敗数 |
| `randomizeZone` | boolean | `true` | ゾーン位置をラウンドごとにランダム化 |

**戻り値**: `success` (boolean)

```lua
-- 例：簡単設定
local ok = exports['glitch-minigames']:StartSkillCheckGame({'E','E','E'}, 50, 15000, 25, 0, 2, true)
```

---

## ロックピック (Lockpick)

```lua
local success = exports['glitch-minigames']:StartLockpickGame(
    rounds, sweetSpotSize, maxFailures, shakeRange, lockTime
)
```

| 引数 | 型 | デフォルト | 説明 |
|---|---|---|---|
| `rounds` | number | `3` | 鍵を開ける回数 |
| `sweetSpotSize` | number | `30` | スイートスポットの角度（度、小さいほど難） |
| `maxFailures` | number | `2` | 許容失敗数 |
| `shakeRange` | number | `40` | 振動が始まる距離（度） |
| `lockTime` | number | `500` | 解錠保持時間 (ms) |

**戻り値**: `success, successes, failures`

---

## バーヒット (Bar Hit)

```lua
local success = exports['glitch-minigames']:StartBarHitGame(
    key, rounds, speed, zoneSize, zoneStart, maxFailures, timeLimit
)
```

| 引数 | 型 | デフォルト | 説明 |
|---|---|---|---|
| `key` | string | `'E'` | 押すキー |
| `rounds` | number | `3` | 必要ラウンド数 |
| `speed` | number | `55` | バー速度 (%/秒) |
| `zoneSize` | number | `20` | 目標ゾーン幅 (%, 10〜40) |
| `zoneStart` | number/nil | `nil` | 固定位置 (%)、nilでランダム |
| `maxFailures` | number | `3` | 許容失敗数 |
| `timeLimit` | number | `30000` | 全体時間 (ms) |

---

## ファイアウォール・パルス (Firewall Pulse)

```lua
local success = exports['glitch-minigames']:StartFirewallPulse(
    requiredHacks, initialSpeed, maxSpeed, timeLimit,
    safeZoneMinWidth, safeZoneMaxWidth, safeZoneShrinkAmount
)
```

| 引数 | 型 | デフォルト | 説明 |
|---|---|---|---|
| `requiredHacks` | number | `3` | 必要成功回数 |
| `initialSpeed` | number | `2` | 初期速度 |
| `maxSpeed` | number | `10` | 最高速度 |
| `timeLimit` | number | `10` | 制限時間（秒） |
| `safeZoneMinWidth` | number | `40` | 安全ゾーン最小幅(px) |
| `safeZoneMaxWidth` | number | `120` | 安全ゾーン最大幅(px) |
| `safeZoneShrinkAmount` | number | `10` | ラウンド毎の縮小量(px) |

---

## バックドアシーケンス (Backdoor Sequence)

```lua
local success = exports['glitch-minigames']:StartBackdoorSequence(
    requiredSequences, sequenceLength, timeLimit, maxAttempts,
    timePenalty, minSimultaneousKeys, maxSimultaneousKeys, customKeys, keyHintText
)
```

代表設定例:

```lua
-- 簡単
exports['glitch-minigames']:StartBackdoorSequence(2, 4, 20, 5, 0.5, 1, 2, {'W','A','S','D'}, 'WASDのみ')
-- 標準
exports['glitch-minigames']:StartBackdoorSequence(3, 5, 15, 3, 1.0, 1, 3, nil, nil)
-- 困難
exports['glitch-minigames']:StartBackdoorSequence(5, 8, 12, 2, 2.0, 2, 4, nil, nil)
```

---

## 推奨難易度プリセット

| 用途 | 推奨ゲーム | 設定例 |
|---|---|---|
| 軽いタッチ判定（ガレージ等） | スキルチェック | `({'E'},50,8000,30,0,1,true)` |
| 一般的な解錠 | ロックピック | `(2,30,2,40,500)` |
| ハッキング演出 | ファイアウォール+シーケンス | 標準値 |
| 集中力テスト | エイムテスト/ナンバーアップ | デフォルト |
| RP系（記憶問題） | カラーメモリ/言語記憶 | デフォルト |

---

## エラーハンドリング

```lua
local ok, err = pcall(function()
    return exports['glitch-minigames']:StartSkillCheckGame({'E'}, 50, 8000, 25, 0, 1, true)
end)

if not ok then
    print('[jp-glitch28] エラー:', err)
end
```

ミニゲーム実行中に再度呼び出した場合は `false` が即座に返ることがあります（多重起動防止）。

---

## トラブルシューティング

**Q. ミニゲーム画面が出ない**  
A. リソースフォルダ名が `glitch-minigames` か、`server.cfg` で `ensure glitch-minigames` されているか確認してください。

**Q. キー入力が効かない**  
A. 一部のミニゲームは NUI フォーカス、一部はゲーム側のキー転送を使います。マウスクリック必須のものは `SetNuiFocus` 状態になります。

**Q. プレイヤーが死亡したらキャンセルされる？**  
A. 全ミニゲーム共通で死亡検知されると強制終了し、`callback(false)` が呼ばれます。

**Q. テーマを変えたい**  
A. `shared/config.lua` の `config.ActiveTheme` を `cyan` または `monochrome` に。`config.ActiveVisualTheme` で `classic` / `modern` を切り替えます。

---

## その他のエクスポート

公式ドキュメント（英語）に全パラメータ一覧があります: [minigames.glitchstudios.dev](https://minigames.glitchstudios.dev/)

日本語 UI は `ui/index.html` と `ui/js/*.js` の表示文字列を置き換えています。**エクスポート名・`exports['glitch-minigames']`・NUI コールバック URL のリソース名は変更していません。**
