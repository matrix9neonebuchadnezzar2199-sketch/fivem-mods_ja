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
- [it_bridge](https://it-scripts.tebex.io/package/6706602)
- [oxmysql](https://github.com/overextended/oxmysql)
- [ox_target](https://github.com/overextended/ox_target) または [qb-target](https://github.com/qbcore-framework/qb-target)（任意）

## インストール

1. 本フォルダ `jp-it-drugs/` を `resources/[jp-mods]/` に配置します。
2. `it-drugs.sql` をデータベースにインポートします。
3. `server.cfg` に `ensure jp-it-drugs` を追加します（依存関係 `ox_lib`, `oxmysql`, `it_bridge` の後ろに置いてください）。
4. `items/items.lua` を参考に、使用しているインベントリへアイテム定義（種・ドラッグ・肥料など）を追加します。画像は `items/img/` のものを利用してください。
5. `shared/config.lua` で挙動を調整します。

## 日本語化について

- ロケールファイル: `locales/ja.lua`
- デフォルト言語: `Config.Language = 'ja'`（`shared/config.lua`）
- 英語へ戻す場合は `Config.Language = 'en'` に変更してください

## 変更点（原作からの差分）

- `locales/ja.lua` を新規追加（全UI文字列の日本語訳）
- `shared/config.lua` の `Config.Language` を `'ja'` に変更
- `README.md` を日本語版に差し替え（原文は `README.en.md` として保持）

イベント名（`it-drugs:client:〜` など）はオリジナルを維持しています。サーバー上で原作 `it-drugs` と同時起動すると衝突するため、**どちらか一方のみを `ensure` してください**。

## ライセンス

本MODは GPL-3.0 を継承します。原作のライセンス全文は `LICENSE` を参照してください。

## 関連リンク

- 原作: https://github.com/it-scripts/it-drugs
- 原作ドキュメント: https://docs.it-scripts.com/it-drugs
- 原作 Discord: https://discord.gg/4KtC77WMPK
