# MERIDIAN-9 / Project JANUS — 全体設計

本ドキュメントは **全体設計の置き場** です。詳細はリポジトリ内の `jp-meridian9/全体設計.txt` および `ストーリー.txt` を正とし、確定した章立てはこのファイルへ段階的に転記します。

## 現状（M0〜M2 入口）

- リソース骨格・設定・FW 検出・NUI 最小・**oxmysql 3 テーブル**・**セッション／バケットプール**・**契約キャッシュ＋運営コマンド**まで完了
- **ヴェガ NPC（暫定座標）＋対話**、**パーティ編成（招待〜セッション転送）**まで完了
- **ゾンビアリーナ（INSTRUCTION-011）**: `Config.Arena` ウェーブ、`server/arena/*`、リーダー委譲スポーン、全滅時 `arena_wiped` → 送還後ノックダウン（`client/main.lua`）
- **ルート取得（INSTRUCTION-012）**: `Config.Loot` / `LootRarityWeight`、`server/loot.lua` + `client/loot.lua`、リーダー `CreateObject` + 全員 `ox_target:addEntity`、`lib.callback` 取得
- **脱出（INSTRUCTION-013）**: `Config.Extract` / `Config.ExtractPoints`、`server/extract.lua` + `client/extract.lua`、`lib.progressCircle`、`session.extractedInventory` メモリ保持、`mrd9_mission_logs` 記録
- 本格 HUD 等は未接続（各 `client/` / `server/` のプレースホルダ参照）

## 非機能

- 文字コード UTF-8（BOM なし）、改行 LF 推奨
- イベント名 `jp-meridian9:*` に統一

## 運用・例外（確定稿）

日記配置・グローバル規約の例外・画像方針・次 INSTRUCTION 前提などは **`docs/FORMAL_POLICIES.md`** に集約する（外部指示書とリポ実装の突き合わせ用）。
