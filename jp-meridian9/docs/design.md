# MERIDIAN-9 / Project JANUS — 全体設計

本ドキュメントは **全体設計の置き場** です。詳細はリポジトリ内の `jp-meridian9/全体設計.txt` および `ストーリー.txt` を正とし、確定した章立てはこのファイルへ段階的に転記します。

## 現状（M0〜M2 入口）

- リソース骨格・設定・FW 検出・NUI 最小・**oxmysql 3 テーブル**・**セッション／バケットプール**・**契約キャッシュ＋運営コマンド**まで完了
- **ヴェガ NPC（暫定座標）＋対話**、**パーティ編成（招待〜セッション転送）**まで完了
- **ゾンビアリーナ（INSTRUCTION-011）**: `Config.Arena` ウェーブ、`server/arena/*`、リーダー委譲スポーン、全滅時 `arena_wiped` → 送還後ノックダウン（`client/main.lua`）
- **ルート取得（INSTRUCTION-012）**: `Config.Loot` / `LootRarityWeight`、`server/loot.lua` + `client/loot.lua`、リーダー `CreateObject` + 全員 `ox_target:addEntity`、`lib.callback` 取得
- **脱出（INSTRUCTION-013）**: `Config.Extract` / `Config.ExtractPoints`、`server/extract.lua` + `client/extract.lua`、`lib.progressCircle`、`session.extractedInventory` メモリ保持、`mrd9_mission_logs` 記録
- **任務中 HUD（INSTRUCTION-014）**: `server/hud.lua` が `IN_MISSION` のみ DTO 配信、`client/hud.lua` が `m9_hud_*` NUI プロトコル（オーバーレイ・非フォーカス）、`html/*` がタイマー／パーティ／インベントリ／ウェーブ帯＋トースト。脱出案内は **013 の `lib.showTextUI` のみ**（HUD に脱出バッジなし）。
- **サイト・ナイン MAP（INSTRUCTION-020 v3）**: GTA V バニラ同梱の **Cayo Perico**（GTA Online Heist DLC）を採用。**`SetIslandEnabled('HeistIsland', true/false)`** クライアントローカルネイティブで島本体を切替。`client/transition.lua` の `Transition.Enter/Leave` で `Config.SiteNine.island` に応じて Cayo Perico / 北ヤンクトンを切替（互換性のため両方サポート）。**routing bucket と組み合わせて bucket 内クライアントだけ熱帯島が見える**真の分離方式。LS 市街地（ヴェガ事務所周辺）は無改変。座標基準 `(4523, -4974, 4.5)`（Cayo Perico メインビーチ）。演出は雷雨・夜 22 時・青いフィルター（熱帯ホラー）。v1 The Apocalypse Project と v2 North Yankton は撤回。
- 本格査定 UI 等は未接続（INSTRUCTION-015 以降）

## 非機能

- 文字コード UTF-8（BOM なし）、改行 LF 推奨
- イベント名 `jp-meridian9:*` に統一

## 運用・例外（確定稿）

日記配置・グローバル規約の例外・画像方針・次 INSTRUCTION 前提などは **`docs/FORMAL_POLICIES.md`** に集約する（外部指示書とリポ実装の突き合わせ用）。
