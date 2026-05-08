# 開発日記: client 側 `Locale()` 置換（8A-next-2-1）

**日付**: 2026-05-08  
**コミット**: メッセージ `feat(client): wire Locale() for user-facing strings`（`git log -1 --grep='wire Locale'` で特定）

## 実施内容

- `client/client.lua` — `lib.alertDialog` 4 種（購入・レイド・ドアベル・ショーケース）と qbx_properties 連携の `Luxury Apartments!` 説明文を `Locale()` 化。
- `client/apartment.lua` — 通知・`lib.registerContext` のタイトル（通常 / レイド）を `Locale()` 化。レイド行タイトルは `menu.apartments.raid_option_title` の `string.format` 相当。
- `client/cl_property.lua` — プロパティ情報 `alertDialog`（ラベル行は `dialog.property_info.line_*`）、ガレージラベル（`ui.garage.label_format`）、ラジアル 2 件、アクセス / ドアベル系メニューと通知を `Locale()` 化。
- `client/modeler.lua` — カート空・金欠・スタッシュ非空の 3 通知を `Locale()` 化。
- **未変更**: `client/migrate.lua`（ユーザー向け英文なし）、`client/shell.lua`（コメントのみ）。

## 動作確認手順（実機）

`shared/config.lua` の `Config.Locale` を切り替えてリソース再起動後、以下を目視する。

1. **`ja`**: 購入・レイド・ドアベル・ショーケースの確認ダイアログが日本語。
2. **`ja`**: アパート入口メニュー、プロパティ内ラジアル（家具 / 管理）、アクセス付与・ドアベルメニュー、家具モデラ通知が日本語。
3. **`en`**: 上記が英語（従来の `locales/en.lua` 文言）に戻る。

## コード上の整合性

- `node tools/verify-locale-keys.mjs` — en 132 / ja 131、欠落なし（`_test.fallback` 除く）。
- 置換漏れ簡易 grep: `Select-String` による `"Title Case phrase"` 検出で残ったのは `Debug(...)` のみ（除外リスト参照）。

## スクリーンショット

本環境では FiveM 実機起動を行っていない。実機確認時はメニュー / 通知 / ラジアルを 2〜3 枚 `docs/ja/dev-diary/screenshots/` に保存すると再現性が高い。

## 参照

- 作業計画（完了・退避）: `tools/_archive/_replace-plan-client_20260508.md`
- 意図的に英語のまま残す文字列: `docs/ja/i18n-extraction.md` 末尾「8A-next-2-1 クライアント置換後の除外リスト」
