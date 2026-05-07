# 変更履歴（日本語版）

本ファイルは原作 [Renewed-Banking](https://github.com/Renewed-Scripts/Renewed-Banking) からの派生版独自の変更を記録します。原作の変更履歴は本家 README を参照してください。

## [1.0.5-ja] - 2026-05-07

### 修正

- サーバー: `LoadResourceFile` / `StopResource` を **`GetCurrentResourceName()`** に統一。モノレポの **`jp-renewedbanking2` フォルダ名のまま `ensure` しても** `Renewed-Banking.sql`・`bundle.js` を読める。
- Web: `fetchNui` の URL を **`GetParentResourceName()`** に変更（ensure 名と一致）。`jp-renewedbanking2` で NUI コールバックが届く。
- リソース名が `Renewed-Banking` でない場合、**`exports['Renewed-Banking']` は他リソースから使えない**旨をサーバーコンソールに警告表示（本番は従来どおり `Renewed-Banking` フォルダ名を推奨）。

## [1.0.4-ja] - 2026-05-07

### 追加・変更

- `config.lua` に **`allowDepositAtAtm`**（既定 `true`）。原作どおり **ATM では入金ボタンを出さない**運用にしたい場合は `false`。
- UI を閉じる際、Lua から **`setBankingHidden`** を送り NUI の表示状態を同期（閉じたのに入力が奪われたまま等の切り分け用）。

## [1.0.3-ja] - 2026-05-07

### 修正（実機 hotfix）

- Lua から `SendNUIMessage` で `updateLocale` を送り、メイン画面の入金・出金・送金ボタンラベルが表示されるようにした（`ox:locale` に応じた `locales/*.json` を 1 回キャッシュ読み込み）
- `closeInterface` と `renewedbanking:close` で `ClearPedTasksImmediately` を実行し、ESC や UI 閉じ後にキャラが固まる問題を解消
- サーバー側の DDL を `Renewed-Banking.sql` 自動投入（v1.0.2 経路）のみに一本化し、末尾の重複 `createTables` を削除
- メイン画面・入出金ポップアップ右上に閉じる（×）ボタンを追加（アクセシビリティ対応の `button` + `aria-label`）

## [1.0.2-ja] - 2026-05-07

### 追加

- 起動時に `Renewed-Banking.sql` を自動投入する機能（手動 phpMyAdmin/HeidiSQL 不要化）。oxmysql 起動完了を待機後、SQL をセミコロン分割して `MySQL.query.await` で逐次実行。

### 変更

- `README.md` / `README.en.md` のセットアップ手順から手動 SQL 投入を必須ステップから外し、自動作成の説明に差し替え。

### 既知の制限

- SQL パーサは行頭 `--` の単行コメント行の除去と `;` 区切りの単純実装。`/* */` 複数行コメントや、文字列リテラル内の `;` には対応しない（現状の `Renewed-Banking.sql` には該当なし）。

## [1.0.1-ja] - 2026-05-07

### Breaking changes

- **クライアントコマンド**: F8 用の UI 閉じコマンドを `closeBankUI` から **`renewedbanking:close`** にリネーム。`server.cfg` やマクロで旧名を呼んでいる場合は置き換えが必要（旧名の併記は行っていない）。

### 修正・改善

- i18n: `comp_transaction` の動詞をロケールキー化、`give_cash` / `received_cash` の英語プレースホルダを Lua 引数順に整合、`en.json` に `_help_*` を追加（`docs/i18n_audit.md` 参照）
- Web: `fetchNui` のエラーハンドリング、`Popup` の失敗時ローディング解除、`AccountsContainer` の空配列ガード、`debugData` を Lua と同じフラット NUI メッセージ形式に統一
- Web: Font Awesome を `index.html` に集約、`Notification` の CSS タイポ修正、`setClipboard` ファイル名修正
- Web: `stores` の型付け、`HelpModal` のバックドロップをボタン化、Svelte 4 / Rollup 4 / TypeScript 5 への更新、`pnpm-lock.yaml` のみでロック管理、ルート `.gitattributes` 追加
- `fxmanifest.lua` に `dependencies { 'ox_lib', 'oxmysql', 'ox_target' }` を追記
- クライアント: `RegisterCommand('renewedbanking:close', …)`（上記 Breaking 参照）

### 維持

- 原作の口座・送金ロジックは変更なし（詳細は `docs/known_issues.md`）

### フォローアップ（v1.0.2-ja 以降で検討）

- NUI の `web/public/build/*` をリポジトリに含めるか、GitHub Releases の zip のみにするかの**配布ポリシー**を整理する（現状は pnpm 非導入サーバー向けに bundle を同梱。詳細は `docs/known_issues.md`）。

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
