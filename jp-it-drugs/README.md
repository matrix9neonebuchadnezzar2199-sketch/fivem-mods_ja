# jp-it-drugs

[it-scripts/it-drugs](https://github.com/it-scripts/it-drugs) の **非公式日本語ローカライズ版** です。

> 原作: it-scripts (`@allroundjonu`)　/　ライセンス: GPL-3.0
> 日本語化: eiho_tsukuyomi
> リポジトリ: https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja

FiveM 向けの本格派ドラッグ経済スクリプトです。植物の栽培、精製作業台でのドラッグ製造、NPCへの売却、摂取エフェクト、管理者用メニューなどを備え、すべて config から細かく調整できます。

## 主な特徴

- **栽培システム**: マップ全土に種を植えて栽培可能（地面判定 ON/OFF、栽培数上限、成長速度ゾーン対応）
- **精製作業台**: 原料を高価値ドラッグへ加工。レシピは config で自由に定義
- **NPCへの売却**: 売却ゾーンや交渉メニューでドラッグを現金化
- **摂取エフェクト**: 各ドラッグの効果・クールダウンを設定可能
- **管理者メニュー**: `/drugadmin [plants/tables]` で全植物・全作業台を一元管理
- **完全 config 駆動**: ゾーン・価格・成長時間・許可地面・依存アイテムまですべて変更可能

## 対応フレームワーク / インベントリ

- フレームワーク: ESX / QBCore / QBox / ND_Core
- インベントリ: ox_inventory / qb-inventory / ps-inventory / esx_inventory / qs-inventory / mInventory / Origen Inventory

## 依存関係

- [ox_lib](https://github.com/overextended/ox_lib)
- **[it_bridge](https://it-scripts.tebex.io/package/6706602)**（it-scripts 公式。**GitHub では配布されていません**。Tebex で無料ダウンロード可・要アカウント。Discord 参加が求められる場合があります）
- [oxmysql](https://github.com/overextended/oxmysql)
- [ox_target](https://github.com/overextended/ox_target) または [qb-target](https://github.com/qbcore-framework/qb-target)（任意）

`it_bridge` は ESX / QBCore / QBox / ND_Core やインベントリの差分を吸収する公式ブリッジです。**フォルダ名を `it_bridge` のままにする必要**があり、他リソースからこの名前で参照されます（`jp-` 接頭辞は付けません）。

## インストール

### 重要: it_bridge の入手と配置

`jp-it-drugs` を起動するには **`it_bridge` が必須**です。未配置のままだと FiveM が依存解決に失敗し、リソースがロードされません。

1. [it-scripts Tebex（it_bridge）](https://it-scripts.tebex.io/package/6706602) から **無料でダウンロード**します。
2. 展開したフォルダを **`it_bridge`** という名前のまま `resources/[jp-mods]/it_bridge/`（または運用ポリシーに合わせた `resources/` 配下）に置きます。  
   **リネーム禁止**（`jp-it-bridge` などにすると `fxmanifest` の依存名と一致しません）。

### server.cfg の `ensure` 順序

依存リソースは **必ず `jp-it-drugs` より前**に起動してください。例:

```
ensure oxmysql
ensure ox_lib
ensure ox_target
ensure it_bridge
ensure jp-it-drugs
```

`it_bridge` 側でさらに `ox_lib` 等が必要な場合は、F8 コンソールに `Could not find dependency ... for resource it_bridge` と出ます。その依存も同様に **より前の行**に `ensure` してください。

### データベース（自動作成）

**既定では手動インポートは不要です。** リソース起動時に `server/sv_setupdatabase.lua` が `it-drugs.sql` と同じ `CREATE TABLE IF NOT EXISTS` を oxmysql 経由で実行し、`drug_plants` と `drug_processing` を用意します。コンソールに `[jp-it-drugs] データベーステーブルを確認しました` と出れば成功です。

- **手動で流したい場合**（バックアップ復元・DDL をサーバーから禁止しているホスト等）: `it-drugs.sql` をインポートし、`shared/config.lua` の **`Config.ManualDatabaseSetup = true`** にすると自動作成をスキップします。
- **自動作成が繰り返し失敗する場合**: `ensure oxmysql` が先であること、DB ユーザーに CREATE 権限があること、F8 / サーバーログのエラーを確認してください。

### 手順（チェックリスト）

1. 本フォルダ `jp-it-drugs/` を `resources/[jp-mods]/` に配置します。
2. 上記どおり **`it_bridge` を Tebex から入手し、同名フォルダで配置**します。
3. `server.cfg` に依存どおりの順で `ensure` を追加します（**`oxmysql` → `it_bridge` → `jp-it-drugs`** など。`it_bridge` は `jp-it-drugs` より前）。
4. `items/items.lua` を参考に、使用しているインベントリへアイテム定義（種・ドラッグ・肥料など）を追加します。画像は `items/img/` のものを利用してください。
5. `shared/config.lua` で挙動を調整します（DB を手動のみにする場合はここで `ManualDatabaseSetup` を変更）。

txAdmin 等で反映後、`refresh` → `restart jp-it-drugs`（またはサーバー再起動）で確認してください。

## 日本語化について

- ロケールファイル: `locales/ja.lua`
- デフォルト言語: `Config.Language = 'ja'`（`shared/config.lua`）
- 英語へ戻す場合は `Config.Language = 'en'` に変更してください

## 変更点（原作からの差分）

- `locales/ja.lua` を新規追加（全UI文字列の日本語訳）
- `shared/config.lua` の `Config.Language` を `'ja'` に変更
- `README.md` を日本語版に差し替え（原文は `README.en.md` として保持）
- DB: `sv_setupdatabase.lua` を `MySQL.query.await` で同期実行し、テーブル未作成のまま `DatabaseSetuped` が立つ競合を解消。`fxmanifest` で DB セットアップを先に読み込み

イベント名（`it-drugs:client:〜` など）はオリジナルを維持しています。サーバー上で原作 `it-drugs` と同時起動すると衝突するため、**どちらか一方のみを `ensure` してください**。

## ライセンス

本MODは GPL-3.0 を継承します。原作のライセンス全文は `LICENSE` を参照してください。

## 関連リンク

- 原作: https://github.com/it-scripts/it-drugs
- 原作ドキュメント: https://docs.it-scripts.com/it-drugs
- 原作 Discord: https://discord.gg/4KtC77WMPK
