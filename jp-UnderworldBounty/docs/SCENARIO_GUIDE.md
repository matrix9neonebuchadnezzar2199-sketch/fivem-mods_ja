# シナリオ追加ガイド

設計の全体像とプレイヤー視点の流れは **`docs/PLAYER_FLOW.md`**、運営向けの空欄テンプレは **`docs/SCENARIO_TEMPLATE.md`** を参照。

## 手順

1. `config/scenarios.lua` の `Config.Scenarios` にテーブルを **1 ブロック追加**する。  
2. `id` を一意にする。  
3. `reward_table_id` を `config/rewards.lua` のキーに合わせる。  
4. `retaliation_pattern_id` を `config/retaliation.lua` のキーに合わせる。  
5. `config/locations.lua` にロケーションを追加し、`scenario_id` で結び付ける。  
6. `locales/ja.lua` と `locales/en.lua` に `flavor_key` や `label_key` 用の文言を追加する。

## フィールド概要

| フィールド | 説明 |
|-----------|------|
| `id` | シナリオ一意 ID |
| `difficulty` | 表示・拡張用（easy/normal/hard/extreme） |
| `flavor_key` | 開始時トースト用ロケールキー |
| `entry_minigame` | `none` / `lockpick` / `hacking` / `brute` |
| `time_limit_sec` | サーバー側タイムアウト判定 |
| `required_items` | `{ { item = 'lockpick', count = 1 }, ... }` |
| `enemies` | `model`, `weapon`, `coords`（vector4）, `behavior` |
| `behavior` | `passive` / `alert` / `aggressive` / `boss`（簡易 AI） |
| `reward_table_id` | 報酬テーブル参照 |
| `retaliation_pattern_id` | 報復パターン参照 |
| `success_condition` | 現状 `eliminate_all` のみ |

## JSON から読み込む（将来）

起動時に `LoadResourceFile` + `json.decode` でマージする形が想定されています。現状は Lua テーブルのみです。
