# MERIDIAN-9 / Project JANUS — 全体設計

本ドキュメントは **全体設計の置き場** です。詳細はリポジトリ内の `jp-meridian9/全体設計.txt` および `ストーリー.txt` を正とし、確定した章立てはこのファイルへ段階的に転記します。

## 現状（M0〜M2 入口）

- リソース骨格・設定・FW 検出・NUI 最小・**oxmysql 3 テーブル**・**セッション／バケットプール**・**契約キャッシュ＋運営コマンド**まで完了
- **ヴェガ NPC（暫定座標）＋対話**、**パーティ編成（招待〜セッション転送）**まで完了
- **ゾンビアリーナ（INSTRUCTION-011）**: `Config.Arena` ウェーブ、`server/arena/*`、リーダー委譲スポーン、全滅時 `arena_wiped` → 送還後ノックダウン（`client/main.lua`）
- **ルート取得（INSTRUCTION-012）**: `Config.Loot` / `LootRarityWeight`、`server/loot.lua` + `client/loot.lua`、リーダー `CreateObject` + 全員 `ox_target:addEntity`、`lib.callback` 取得
- **脱出（INSTRUCTION-013）**: `Config.Extract` / `Config.ExtractPoints`、`server/extract.lua` + `client/extract.lua`、`lib.progressCircle`、`session.extractedInventory` メモリ保持、`mrd9_mission_logs` 記録
- **任務中 HUD（INSTRUCTION-014）**: `server/hud.lua` が `IN_MISSION` のみ DTO 配信、`client/hud.lua` が `m9_hud_*` NUI プロトコル（オーバーレイ・非フォーカス）、`html/*` がタイマー／パーティ／インベントリ／ウェーブ帯＋トースト。脱出案内は **013 の `lib.showTextUI` のみ**（HUD に脱出バッジなし）。
- **サイト・ナイン MAP（INSTRUCTION-020 v3 確定運用）**: GTA V バニラ同梱の **Cayo Perico**（GTA Online Heist DLC）を採用。クライアント起動時に **`SetIslandEnabled('HeistIsland', true)`** + **`EnableMpDlcMaps(true)`** を呼んで **常時 ON 固定**。動的 OFF は GTA V ストリーミング上で LS メモリリーク・読み込み失敗を引き起こすため不可（マスター実機検証で判明、FiveM コミュニティ公知）。bucket 0 のプレイヤーにも海上に Cayo Perico が遠景として見えるが、ゲート転送以外で物理アクセス不可（海上独立島）。bucket 分離は **演出のみ**（天気・時間・タイムサイクル・街灯）。座標基準は住宅街 5 ヶ所からランダム選出。演出は雷雨・夜 22 時・青いフィルター（熱帯ホラー）。v1 The Apocalypse Project・v2 North Yankton は撤回。
- **オープンワールド・サバイバル（INSTRUCTION-021）**: 任務開始から即 **`MRD9.Survival.Start`** が起動（`Config.Arena.enabled = false` 既定。3 ウェーブは廃止、アリーナはコード残置）。開始 20 秒後に最初のスポーン、以降 3 分ごとに各メンバー周辺 30〜150m に 3 体スポーンする持続的脅威。`Config.Mission.spawnPoints` 5 ヶ所からランダム選出で湧き分散、`Config.ExtractPoints` は **監視塔／ヘリポート／テント／飛行場／配電施設** の 5 ヶ所で脱出ルートも自由化。
- 本格査定 UI 等は未接続（INSTRUCTION-015 以降）

## 非機能

- 文字コード UTF-8（BOM なし）、改行 LF 推奨
- イベント名 `jp-meridian9:*` に統一

## 運用・例外（確定稿）

日記配置・グローバル規約の例外・画像方針・次 INSTRUCTION 前提などは **`docs/FORMAL_POLICIES.md`** に集約する（外部指示書とリポ実装の突き合わせ用）。
