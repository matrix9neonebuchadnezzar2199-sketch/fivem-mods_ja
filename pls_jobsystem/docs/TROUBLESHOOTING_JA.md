# トラブルシューティング

## 起動時に「リソース名は 'pls_jobsystem' でなければなりません」と出る

フォルダ名が `pls_jobsystem` 以外になっています。`pls_jobsystem` にリネームし、`server.cfg` の `ensure` 行も合わせてください。

## `/open_jobs` で UI が開かない

- F8 コンソールで赤いエラーが出ていないかを確認
- ox_lib が起動していない可能性 → `ensure` 順序を確認
- 権限不足の可能性 → フレームワーク側の admin/dev グループ確認

## NUI に英語が残る

`powershell -File .\scripts\apply_nui_i18n.ps1 -Mode preview`（または `pwsh`）を実行し、対象文字列のヒット数を確認してください。0 件なら原文がバンドル内に存在せず、追加翻訳マップが必要です。`docs/i18n/nui_replacements.json` の `translations` に英文と日本語訳を追記し、再度 `-Mode apply` で適用します。

**補足:** `nui_replacements.json` のキーは PowerShell の `ConvertFrom-Json` では大文字小文字が区別されないため、同義の重複キー（例: `Animation Name` と `Animation name`）を並べないでください。

## クラフト時に通知が空欄

ロケールキーが不足しています。`locales/ja.lua` に該当キーを追加し、`locales/en.lua` のフォールバックがあるか確認してください。

## アイテム画像が表示されない

`Config.DirectoryToInventoryImages` が、お使いのインベントリのNUIパスと一致しているかを確認してください。代表値は `nui://ox_inventory/web/images/`、`nui://qb-inventory/html/images/`、`nui://quasar_inventory/html/images/` です。

## ボスメニューが開かない

`config.lua` の `openBossmenu(jobName)` 内に何も書かれていない、もしくは export 名がサーバー上のリソースと一致していません。詳細は [`BOSSMENU_JA.md`](./BOSSMENU_JA.md)。

## バックアップから復元できない

`server/backup.json` が存在し、JSON として valid であるかを確認してください。手動編集後に壊れている場合は、`backup.json` を削除してから UI 上で再作成します。
