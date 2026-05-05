# jp-v-farming

原作 [Virgildev/v-farming](https://github.com/Virgildev/v-farming)（MIT）をベースに、**日本語優先の i18n**（`locales/ja.lua`・`locales/en.lua`・`_U`）と設定の `labelKey` 方式を追加したフォークです。

- バージョン: `1.0.0-ja.2`
- リポジトリ: [fivem-mods_ja](https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja)

## 概要

指定エリアで果物などを収穫し、NPC に売却して現金（`ox_inventory` の `cash`）を得るシンプルな農業スクリプトです。UI 文言は `Config.Locale`（`'ja'` / `'en'`）で切り替わります。作物の表示名は `Config.ItemsFarming[item].labelKey` → `locales/*.lua` のキーで解決します。

## 依存関係

- **QBCore / qb-core**（`Config.Progress` / `Config.Menu` / `Config.Notify` のいずれかを `'qb'` にする場合のみ。クライアントは `GetResourceState('qb-core') == 'started'` のときだけ `GetCoreObject()` を呼ぶため、**QBox（qb-core なし）＋ 上記をすべて `'ox'` の構成では不要**）
- **ox_lib**（`shared_script` で `@ox_lib/init.lua` を読み込み）
- **ox_target**（`Config.InteractionMode` が `'target'` または `'both'` のとき、収穫ゾーン・売却 NPC の照準操作に使用）
- **ox_inventory**（サーバー側の付与・削除・現金）
- **oxmysql**（`Config.useMyResturantWarehouseScript = true` のとき、倉庫テーブル更新に使用）

`Config.Progress` / `Config.Menu` / `Config.Notify` を `'ox'` にすると ox_lib 寄り、`'qb'` にすると QBCore 寄りの UI になります。**デフォルトは `'ox'`**（原作どおり）です。

## インストール

1. 本フォルダ `jp-v-farming` をサーバーの `resources` 配下に配置する。
2. `server.cfg` に `ensure jp-v-farming`（またはフォルダ名に合わせる）を追加する。
3. `[install]` 以下の物品定義・画像を、利用中のインベントリに合わせて登録する（`items - qb&ox.txt` または `items - qb&ox.ja.txt` 参照）。
4. `config.lua` で座標・価格・農場を調整する。

### アイテム定義（日本語版）

`[install]/items - qb&ox.ja.txt` に日本語ラベル・説明文付きのアイテム定義テンプレートを同梱しています。原本（`items - qb&ox.txt`）の代わりにこちらを使用すると、インベントリ表示が日本語になります。

## 設定ガイド

| 項目 | 説明 |
|------|------|
| `Config.Locale` | `'ja'`（日本語）または `'en'`（英語） |
| `Config.Progress` | `'ox'` / `'qb'`（収穫・売却のプログレス） |
| `Config.Menu` | `'ox'` / `'qb'`（売却数量入力） |
| `Config.Notify` | `'ox'` / `'qb'`（通知） |
| `Config.ItemsFarming` | 各アイテムに `label`（英語検索用・任意）と `labelKey`（表示用） |
| `Config.FarmingLocations` | 各農場に `labelKey`（ブリップ名用。未設定時は `FARM_` + 大文字 `item` を試行） |
| `Config.InteractionMode` | `'both'`（既定）/ `'key'` / `'target'`（下記「操作方式」参照） |
| `Config.KeyInteractDistance` | [E] 収穫の検知半径（メートル、既定 3.0） |
| `Config.KeySellDistance` | 売却 NPC 付近の [E] 検知半径（メートル、既定 2.5） |

### 操作方式の切り替え

`config.lua` の `Config.InteractionMode` で操作方式を変更できます。

- `'both'`（既定）: ox_target でマウス照準、または近づいて [E] キーの両方が使える
- `'key'`: [E] キーのみ。収穫・売却の ox_target 登録を行わない（`ox_lib` のテキスト UI のみ）
- `'target'`: ox_target のみ。従来のマウス照準操作

検知範囲は `Config.KeyInteractDistance`（収穫・既定 3.0m）と `Config.KeySellDistance`（売却 NPC・既定 2.5m）で調整可能です。

原作にオレンジ農園だけ先に存在していたため、本フォークでは `Config.ItemsFarming['orange']` と `ITEM_ORANGE` / `FARM_ORANGE` を追加済みです。

## ライセンス・クレジット

- 原作: Virgildev / v-farming（MIT）。詳細は `LICENSE`。
- 日本語化・i18n 改修: 本リポジトリのメンテナ方針に従います。

## 動作確認の目安

- サーバー起動時に `[script:jp-v-farming]` まわりで Lua エラーが出ないこと。
- 買取ブリップ・農園ブリップ・ox_target のラベルが選択言語で表示されること。
- 収穫・売却プログレス、コンテキストメニュー、売却ダイアログ、各種通知が言語に合っていること。

英語の旧 README 断片は `README.en.md` に退避しています。
