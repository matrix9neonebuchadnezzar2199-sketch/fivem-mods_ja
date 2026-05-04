# jp-mch（JP-Mods 版 Munlay Clean HUD）

軽量・完全クライアントサイドのミニマル HUD。元の [Munlay HUD](https://github.com/Moonlgiht111/Munlay-HUD-FIVEM-Minimal-Clean-HUD-for-ESX) を基に、**ESX / QBCore / Qbox / standalone** 対応のマルチフレームワーク化と**日本語 UI・ログ・コメント**を行ったフォークです。

## 特徴

- 完全クライアントサイド（サーバースクリプトなし／Resmon 目安 約 0.02ms）
- フレームワーク自動検出（`qbx_core` / `qb-core` / `es_extended` / standalone）
- 日本語 UI（現金・銀行・裏金・無職・階級など）。通貨記号は `config.lua` の `Config.CurrencySymbol` で変更可能
- `esx_status` と `pma-voice` は任意（`config.lua` で `auto` / 明示 ON/OFF）
- 解像度・セーフゾーン適応（720p〜4K、16:9 / 16:10 / 4:3 / 5:4 / ウルトラワイド）
- ユーザーレイアウト（オフセット・スケール）を KVP で永続化（キーは `jp_mch_*`。旧 `munlay_hud_*` からは起動時に読み取り移行）

## インストール

1. 本フォルダを `resources/[jp-mods]/jp-mch` に配置する
2. `server.cfg` に `ensure jp-mch` を追加する（フレームワーク本体・任意の `esx_status`・`pma-voice` の**後ろ**を推奨）
3. 必要なら `config.lua` の `Config.Framework` と `Config.CurrencySymbol` を調整する

## コマンド

| コマンド | 説明 |
|----------|------|
| `/hud` | 金銭・職業パネルの表示切替 |
| `/mapa` | ミニマップの強制表示／非表示（現在の表示状態をトグル） |
| `/hudreset` | HUD のオフセット・スケールを初期化 |

## 外部連携（exports）

```lua
exports['jp-mch']:SeatbeltState(true)
exports['jp-mch']:CruiseControlState(true)
exports['jp-mch']:SetMoneyHudVisible(true)
exports['jp-mch']:SetJobHudVisible(true)
exports['jp-mch']:SetMoneyJobHudVisible(true)
local cfg = exports['jp-mch']:GetHudConfig()
local fw  = exports['jp-mch']:GetFramework() -- 'qbox' / 'qb' / 'esx' / 'standalone'
```

旧リソース名 `munlay_hud` からの置き換え時は、上記の `exports['jp-mch']` を参照先として書き換えてください。

## standalone での金銭・職業の流し込み

同一クライアント上の別リソースからは、次のように **クライアント側**でイベントを発火してください（`RegisterNetEvent` と `AddEventHandler` の両方に対応）。

```lua
TriggerEvent('jp-mch:setMoney', cash, bank, blackMoney)
TriggerEvent('jp-mch:setJob', { name = 'police', label = '警察', grade = 2, grade_label = '巡査部長' })
```

サーバーから送る場合は `TriggerClientEvent('jp-mch:setMoney', playerId, cash, bank, black)` のように、クライアントで同名イベントを受け取ってください。

従来の `hud:updateMoney` / `hud:updateJob` もクライアント側では引き続き処理されます。

## 依存

| リソース | 必須 | 用途 |
|----------|------|------|
| `qbx_core` / `qb-core` / `es_extended` | いずれか推奨 | プレイヤーデータ（金銭・職業） |
| `esx_status` | 任意 | 空腹／喉の渇きの実値 |
| `pma-voice` | 任意 | ボイス距離検出 |

## ライセンス

MIT。元コード（Munlay HUD）の方針に従い無償で利用・改変・再配布可能です。

## 作者

日本語化・マルチ FW 対応：JP-Mods / 元コード：Moonlgiht111（Munlay HUD）
