# Changelog

Format loosely follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- `Config.CombatEntityCleanupDelayMs`（`config/config.lua`）— 強盗終了・報復勝利後の死体・車両削除を遅延させる（`0` で即時）
- `docs/INSTRUCTIONS_PHASE_1A_LIVE_TEST.md` — PHASE 1a 実機テスト手順（手動、v1.1。`BRIDGE_API_LIVE_TEST_RESULTS.md` 記録・Cursor 整形の流れ）
- `docs/BRIDGE_API_IMPROVEMENTS.md`: BRIDGE_API.md §9 改善候補6件の優先度・対応方針・工数評価。v1.1 採用判断の基礎資料。
- `docs/INSTRUCTIONS_PHASE_1B.md` — PHASE 1b 作業指示（`BRIDGE_API.md` §9 の6件を `BRIDGE_API_IMPROVEMENTS.md` に整理する手順・Cursor 向け）
- `docs/INSTRUCTIONS_PHASE_1A_FOLLOWUP.md` — PHASE 1a フォローアップ作業指示（要確認の確定、`RemoveMoney`/`RemoveItem` 保留コメント、`BRIDGE_API.md` §9 整理）
- `docs/BRIDGE_API.md` — v1.0.0 時点の Bridge / ClientBridge API スナップショット（呼び出し元マップ・FW マトリクス・改善候補）
- `docs/INSTRUCTIONS_PHASE_1A.md` — PHASE 1a（Bridge 層 API のスナップショット化）の Cursor 向け作業指示書
- `fxmanifest.full.lua.template` — greenfield manifest reference（現行 `fxmanifest.lua` とは bridge 構成が異なる旨を記載）
- `client/_stub.lua` — `Config.DebugUseClientStub` が true のときのみ読み込み意味を持つ開発用スタブ

### Fixed

- 強盗侵入ヘルプが高速点滅する問題（`client/heist.lua` で `DisplayHelp` の再描画を間引き）
- 侵入プロンプトを `~INPUT_CONTEXT~` から **E キー表記**へ（`locales/ja.lua` / `locales/en.lua`）
- 強盗開始プロンプト文言を実装に合わせる（屋内「侵入」ではなく **屋外トリガーでイベント開始**である旨が伝わる表現に変更）
- 強盗トリガー位置に **地上マーカー（黄色の円）** を表示（`client/heist.lua`）。ヘルプ更新間隔を延長し点滅をさらに抑制

### Changed

- 強盗終了・報復ウェーブ勝利後の NPC／車両削除を `Config.CombatEntityCleanupDelayMs` に従う遅延に変更（`client/heist.lua` / `client/npc_manager.lua` / `client/retaliation.lua`）。新規報復開始時は遅延中の残骸も含め常に掃除
- `ui/css/style.css` / `ui/js/app.js`: 鍵開けミニゲームに **緑成功レンジの可視化**、バー高さを約2倍、指名手配 HUD を約2倍の文字サイズに拡大
- `docs/INSTRUCTIONS_PHASE_1A_LIVE_TEST.md`: §4.3・§5.3 の `setjob` 例を server ID 先頭形式に修正、§16 の職業行を整合（v1.3）。
- `docs/INSTRUCTIONS_PHASE_1A_LIVE_TEST.md`: §5.2 手順を実装実態に合わせて修正、§16.4 補足追加（v1.2）。
- `docs/DESIGN.md`、`README.md`、`.cursorrules` — PHASE 1a 実機テスト指示書の相互参照および一時優先指定を追加
- `docs/BRIDGE_API.md`: §9 冒頭に `BRIDGE_API_IMPROVEMENTS.md` への参照を追加。
- `docs/DESIGN.md`、`README.md`: `BRIDGE_API_IMPROVEMENTS.md` をツリー・ドキュメント表に追加。
- `docs/INSTRUCTIONS_PHASE_1B.md`: メタデータのバージョン表記を v1.1 に更新（改訂履歴と整合）。
- `.cursorrules`: ドキュメント改訂時のバージョン表記同期ルールを恒久ルールとして追加。
- `docs/INSTRUCTIONS_PHASE_1B.md`: §5 セルフチェック項目を §6 コミット手順と整合（v1.1）。
- `docs/DESIGN.md`、`README.md`、`.cursorrules` — PHASE 1b 指示書の相互参照および一時優先指定を追加
- `docs/BRIDGE_API.md`: 無印「要確認」を解消。Qbox / `qb-core` 依存と `Bridge.AddItem` 戻り値はコード観察ベースで整理し、断定できない点は「要実機確認（v1.1）」に分類。§9.2・§9.4 を整合（§9.4 は「v1.1 再評価対象（保留扱い）」）。
- `bridge/sv_bridge.lua`: `Bridge.RemoveMoney` / `Bridge.RemoveItem` に保留コメントを追加（ロジック変更なし）。
- `.cursorrules`: PHASE 1a / フォローアップ指示書の優先指定行を削除。
- `docs/INSTRUCTIONS_PHASE_1A_FOLLOWUP.md` v1.2: §4.1 / §4.2 の反映先を BRIDGE_API 内の全該当「要確認」に拡張し grep 網羅確認を必須化、§5 セルフチェックを grep ベースに変更（v1.1 全文差し替えの続き）
- `docs/2026-05-04_開発日記.md` を新設し、2026-05-04 以降の作業メモを移設（`docs/2026-05-03_開発日記.md` からリンク）
- `fxmanifest.lua` — ドキュメント参照コメント、`client/_stub.lua` をクライアント読み込みに追加
- `.cursorrules` — ドキュメント階層・設計原則・現行 bridge パスを追記
- `.gitignore` — OS/IDE/ドラフト/アセット源ファイルなどのパターンを拡張
- `README.md` — ドキュメント表・バージョン表記・英語セクション整理

## v1.0.0 — 2026-05-03

- 初版リリース候補: Bridge（ESX / QBCore・Qbox検出 / Standalone）、シナリオ駆動強盗、NPC 戦闘、闇の指名手配と報復ウェーブ、NUI ミニゲーム（鍵開け・ハッキング・力ずく）、イベントフック、`config` / `locales` 分離。
- 既知の制限: DB 永続化はスタブ。報復ドロップアイテムは未実装。`markedbills` 等のアイテム名はフレームワーク側の定義に合わせて変更すること。
