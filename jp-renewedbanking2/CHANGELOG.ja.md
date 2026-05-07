# 変更履歴（日本語版）

本ファイルは原作 [Renewed-Banking](https://github.com/Renewed-Scripts/Renewed-Banking) からの派生版独自の変更を記録します。原作の変更履歴は本家 README を参照してください。

## [1.0.1-ja] - 2026-05-07

### 修正・改善

- i18n: `comp_transaction` の動詞をロケールキー化、`give_cash` / `received_cash` の英語プレースホルダを Lua 引数順に整合、`en.json` に `_help_*` を追加（`docs/i18n_audit.md` 参照）
- Web: `fetchNui` のエラーハンドリング、`Popup` の失敗時ローディング解除、`AccountsContainer` の空配列ガード、`debugData` を Lua と同じフラット NUI メッセージ形式に統一
- Web: Font Awesome を `index.html` に集約、`Notification` の CSS タイポ修正、`setClipboard` ファイル名修正
- Web: `stores` の型付け、`HelpModal` のバックドロップをボタン化、Svelte 4 / Rollup 4 / TypeScript 5 への更新、`pnpm-lock.yaml` のみでロック管理、ルート `.gitattributes` 追加
- `fxmanifest.lua` に `dependencies { 'ox_lib', 'oxmysql', 'ox_target' }` を追記
- クライアント: `RegisterCommand('renewedbanking:close', …)`（旧 `closeBankUI`）

### 維持

- 原作の口座・送金ロジックは変更なし（詳細は `docs/known_issues.md`）

## [1.0.0-ja] - 2026-05-06

### 追加

- 完全日本語ロケール `locales/ja.json`
- UI ヘルプ（`HelpButton.svelte` / `HelpModal.svelte`）と `showHelp` ストア
- `LICENSE.ja.md`（参考訳）、本 `CHANGELOG.ja.md`、`CREDITS.md`
- 日本語 `README.md`、英語 `README.en.md`
- `tools/check-locale-keys.ps1`（`en.json` とのキー整合チェック）

### 変更

- `config.lua`: コメントの日本語化（キー・値は本家互換のまま）
- `fxmanifest.lua`: メタ情報の更新（リソース名 `Renewed-Banking` は維持）
- クライアント・サーバー・Web のコメント日本語化
- `web/public/index.html`: `lang="ja"`、タイトル変更（FiveM NUI ではタブに出ない場合あり／ブラウザ単体デバッグ用）

### 維持

- リソース名・export 名は本家互換のため **`Renewed-Banking`** のまま
- `LICENSE`（英語原文）は無改変
- ライセンス: CC BY-NC-SA 4.0

### 原作作者への連絡

- 派生公開にあたり、Issue または Discord での事前連絡は **運営方針に従い実施または記録**してください（現状: 未連絡の場合は本 README / CHANGELOG に明記）。
