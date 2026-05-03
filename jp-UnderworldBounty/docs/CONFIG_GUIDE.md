# Config ガイド（運営者向け）

## 読み方

- グローバル挙動: `config/config.lua`  
- 座標・トリガー: `config/locations.lua`  
- 敵・ミニゲーム・報酬参照: `config/scenarios.lua`  
- 報酬の数値: `config/rewards.lua`  
- 報復ウェーブ: `config/retaliation.lua`  
- 職業ブロック: `config/blacklist.lua`

## config.lua（主要項目）

| 項目 | 説明 |
|------|------|
| `Config.Framework` | `auto` / `esx` / `qbcore` / `qbox` / `standalone` |
| `Config.Locale` | `ja` または `en` |
| `Config.Debug` | `true` でクールダウン無効などテスト向け（未実装項目あり） |
| `Config.LocationCooldownSec` | 同一ロケーションの再プレイ禁止秒 |
| `Config.MinOnDutyCops` | 開始に必要なオンライン警官の最小人数 |
| `Config.BountyScanIntervalMs` | 指名手配・襲撃スケジュールのスキャン間隔 |

## 報酬アイテム名

`config/rewards.lua` の `item` は **インベントリのアイテム名** と一致させる必要があります。存在しないアイテムは `pcall` で握りつぶされるため、報酬が付かない場合は名前を確認してください。

## 警察ジョブ

`Config.PoliceJobs` にオンライン警官として数えるジョブ名（小文字キー）を追加します。
