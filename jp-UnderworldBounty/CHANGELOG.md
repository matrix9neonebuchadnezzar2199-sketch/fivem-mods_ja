# Changelog

Format loosely follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- `docs/INSTRUCTIONS_PHASE_1B.md` — PHASE 1b 作業指示（`BRIDGE_API.md` §9 の6件を `BRIDGE_API_IMPROVEMENTS.md` に整理する手順・Cursor 向け）
- `docs/INSTRUCTIONS_PHASE_1A_FOLLOWUP.md` — PHASE 1a フォローアップ作業指示（要確認の確定、`RemoveMoney`/`RemoveItem` 保留コメント、`BRIDGE_API.md` §9 整理）
- `docs/BRIDGE_API.md` — v1.0.0 時点の Bridge / ClientBridge API スナップショット（呼び出し元マップ・FW マトリクス・改善候補）
- `docs/INSTRUCTIONS_PHASE_1A.md` — PHASE 1a（Bridge 層 API のスナップショット化）の Cursor 向け作業指示書
- `fxmanifest.full.lua.template` — greenfield manifest reference（現行 `fxmanifest.lua` とは bridge 構成が異なる旨を記載）
- `client/_stub.lua` — `Config.DebugUseClientStub` が true のときのみ読み込み意味を持つ開発用スタブ

### Changed

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
