# Renewed-Banking 日本語化版 (jp-renewedbanking2)

[![License: CC BY-NC-SA 4.0](https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-sa/4.0/)
[![FiveM](https://img.shields.io/badge/Platform-FiveM-orange)](https://fivem.net/)

FiveM 用バンキングリソース **[Renewed-Banking](https://github.com/Renewed-Scripts/Renewed-Banking)** の **日本語 UI・日本語ドキュメント・ヘルプ機能付き**派生版です。`locales/ja.json` による文言の和訳、Lua / TypeScript / Svelte のコメント和訳、画面上の「？」ヘルプを追加しています。

## 重要：公式リソースではありません

本フォルダは **uShifty 氏 / Renewed-Scripts による原作の派生物**です。**CC BY-NC-SA 4.0** を継承しています。不具合のうち原作由来のものは本家へ、本派生版固有（翻訳・ヘルプ UI）のものは本リポジトリへ報告いただけると助かります。

**原作作者への事前連絡**: 未実施の場合は運用ポリシーに従い追記します（現状: 本 README および `CHANGELOG.ja.md` に記載のとおり派生版として公開）。

## クレジット

- **原作者**: uShifty（[Renewed-Scripts](https://github.com/Renewed-Scripts)）
- **UI 2.0 デザイン**: [qwadebot](https://github.com/qw-scripts)
- **原作リポジトリ**: https://github.com/Renewed-Scripts/Renewed-Banking
- **日本語化・ヘルプ追加**: matrix9neonebuchadnezzar2199-sketch

詳細は [`CREDITS.md`](./CREDITS.md) を参照してください。

## ライセンス

[![CC BY-NC-SA 4.0](https://licensebuttons.net/l/by-nc-sa/4.0/88x31.png)](https://creativecommons.org/licenses/by-nc-sa/4.0/)

**Creative Commons 表示-非営利-継承 4.0 国際 (CC BY-NC-SA 4.0)**。原作と同一ライセンスです。

- 改変・再配布は **同一ライセンスで**可能
- **商用利用は不可**（Tebex 販売、有料サーバー限定配布、サブスク特典などはライセンス違反になり得ます）
- **クレジット表記が必須**

法的拘束力があるのは英語原文の [`LICENSE`](./LICENSE) のみです。日本語の要約は [`LICENSE.ja.md`](./LICENSE.ja.md) を参照してください。

## 原作からの主な差分

1. `locales/ja.json` による UI・通知の日本語化（`_help_*` キーでヘルプ文言を追加）
2. Lua / TS / Svelte の **コメント和訳**（処理ロジックは本家に合わせ維持）
3. 画面上の **ヘルプ（？）** と **使い方モーダル**
4. 本 README・`CHANGELOG.ja.md`・`README.en.md`
5. **v1.0.3-ja（hotfix）**: Lua から NUI へ `updateLocale` を送信（メインボタンラベル表示）、UI 閉じ後のキャラ固まり修正、メイン・ポップアップに閉じる（×）ボタン、サーバー DDL を `Renewed-Banking.sql` 自動投入に一本化（詳細は [`CHANGELOG.ja.md`](./CHANGELOG.ja.md)）

## スクリーンショット

実機で UI を確認したら、以下に画像を配置し、この節のコメントを外して表示してください。

- メイン画面: `docs/screenshots/banking-main-ja.png`（推奨）
- ヘルプモーダル: `docs/screenshots/banking-help-ja.png`（推奨）

<!-- 画像を配置したら以下のコメントを外す
![メイン画面](docs/screenshots/banking-main-ja.png)
![ヘルプモーダル](docs/screenshots/banking-help-ja.png)
-->

## 依存リソース

`fxmanifest.lua` に `dependencies { 'ox_lib', 'oxmysql', 'ox_target' }` を記載済みです。起動順の参考にしてください。**ox_lib は 3.x 系を想定**（`server_version` の固定値はリポジトリに含めていない。自環境の `ox_lib/fxmanifest.lua` を参照のこと）。詳細は `docs/known_issues.md`。

- [oxmysql](https://github.com/overextended/oxmysql)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_target](https://github.com/overextended/ox_target)
- **QBCore または ESX**（他フレームワークは `framework.lua` の編集が必要）

## 日本語表示のために（重要）

ox_lib のロケールが **`ja`** になるよう、サーバー設定例:

```cfg
setr ox:locale ja
```

本リソースは `locales/ja.json` を同梱しています。英語に戻す場合は `setr ox:locale en` など、環境に合わせてください。

## インストール手順

1. **推奨: フォルダ名・`ensure` 名を `Renewed-Banking` にする**（`exports['Renewed-Banking']` を参照する他スクリプトとの互換のため）。**v1.0.5-ja 以降**は開発用に **`jp-renewedbanking2` のまま `ensure jp-renewedbanking2` でも起動可能**（SQL / UI ファイルは自リソースから読み込む）。本番では引き続き `Renewed-Banking` 名を推奨。
2. **初回起動時に `Renewed-Banking.sql` が自動実行され**、`bank_accounts_new` / `player_transactions` テーブルが作成される（`oxmysql` が起動していることが前提）。DDL の確認・バックアップからの手動復元用に、リソースルートの `Renewed-Banking.sql` を phpMyAdmin / HeidiSQL から流すことも可能。
3. `web` フォルダで **`pnpm install`** のあと **`pnpm run build`** を実行し、`web/public/build/` にバンドルを生成する（ロックは `pnpm-lock.yaml` のみ。`npm` を使う場合は `npm install --no-package-lock` を推奨）。
4. `server.cfg` に `ensure Renewed-Banking` を追加する（名前は上記ディレクトリ名と一致させる）。
5. 上記 **ox:locale** を希望言語に設定する。

F8 コンソールから **`renewedbanking:close`** で銀行 NUI を閉じられます（v1.0.1-ja より。旧コマンド名 `closeBankUI` は廃止）。

## 既知の制限

原作ロジックに踏み込まない方針で残している点は [`docs/known_issues.md`](./docs/known_issues.md) を参照してください。

## カスタマイズ

- `locales/ja.json` の `bank_name`（既定「ロスサントス銀行」）はサーバー固有名詞として上書きして構いません。

## 外部リソースからの利用（exports）

銀行口座の増減などに使う export の例（詳細は本家 README の英語版も参照）:

```lua
exports['Renewed-Banking']:handleTransaction(account, title, amount, message, issuer, receiver, type, transID)
exports['Renewed-Banking']:getAccountMoney(account)
exports['Renewed-Banking']:addAccountMoney(account, amount)
exports['Renewed-Banking']:removeAccountMoney(account, amount)
```

QBCore の `qb-management` からの置き換え例は本家 README の **QBCore additional Installation Steps** を参照してください。

## 既知の制限・注意

- **リソース名は `Renewed-Banking` を維持**してください。
- 原作が更新された場合、差分の取り込みは手作業になります。
- `give_cash` 通知など、原作の `locale()` 引数順と `en.json` の `%s` 順が一致しない箇所がある場合があります。日本語 `ja.json` では **実際に渡される引数順**に合わせて訳文を調整しています。

## 貢献

誤訳・改善提案は Issue / Pull Request で歓迎します。

## 変更履歴（派生版）

[`CHANGELOG.ja.md`](./CHANGELOG.ja.md)

## 英語ドキュメント

[`README.en.md`](./README.en.md)
