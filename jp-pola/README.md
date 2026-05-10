# jp-pola — 写真撮影 MOD（ps-camera 日本語版）

ps-camera（Project Sloth Team）を **完全日本語化** したフォーク。

撮影／写真表示／フラッシュ／ズーム／URL コピーといった機能はオリジナルのまま、UI 文言・通知・コンソールログを日本語化し、運営者が触る箇所には日本語コメントを足してあります。

- **オリジナル**: https://github.com/Project-Sloth/ps-camera
- **ライセンス**: [CC BY-NC-SA 4.0](LICENSE)（**非商用**・継承）
- **バージョン**: `1.1.0-jp.4`
- **対象**: GTA5 / FiveM
- **依存**: [QBCore](https://github.com/qbcore-framework/qb-core), [screenshot-basic](https://github.com/citizenfx/screenshot-basic)（任意で `ox_inventory`）

> ESX・QBCore に依存するため [AGENTS.md](../AGENTS.md) の「単体 jp-* MOD」基準からは外れます。**フォーク／ローカライズ配布**としての位置付けです（[CONTRIBUTING_JP.md §2](../CONTRIBUTING_JP.md)）。

## 動くまでの手順（この順でチェック）

1. **依存リソース**が `server.cfg` で **`qb-core` → `screenshot-basic` → `jp-pola`** のように先に起動している（`ensure` の順序が前であること）。
2. **`ensure jp-pola`** を書く。旧 **`ps-camera` は ensure しない**（二重起動で壊れる）。
3. **`qb-core/shared/items.lua`** に `camera` と `photo` を登録（下記「インストール」の例どおり）。
4. **`jp-pola/images/` の `camera.png` / `photo.png`** を、使っているインベントリの画像フォルダにコピー（例: `ox_inventory/web/images/` や `qb-inventory/html/images/`）。**`SvConfig.Inv = 'ox'`** のときは、**`ox_inventory/data/items.lua` に `camera` / `photo` の定義**も必要（未登録だと付与できない）。
5. **`jp-pola/server/sv_main.lua` の `SvConfig.Inv`** を **`'qb'`** か **`'ox'`** に合わせる（ox_inventory なら **`'ox'`**）。
6. **`jp-pola/config.lua` の `Config.UseFivemerr`** と **認証情報**をセットで合わせる（ズレるとカメラが開かない／撮影しても何も起きない）。
   - **Fivemerr** … `Config.UseFivemerr = true` ＋ `set jp-pola_fivemerr_token "..."`（または `SvConfig.FivemerrApiToken`）。
   - **Discord** … `Config.UseFivemerr = false` ＋ `set jp-pola_webhook "..."`（または `SvConfig.webhook`）。**1.1.0-jp.3** では既定で **`Config.DiscordUploadViaServer = true`**（画像をサーバー経由で Discord に POST。CEF 直叩きの **40333 internal network error** を避ける）。従来どおりクライアントから送りたい場合だけ `false`。
7. **`restart jp-pola`**（またはサーバー再起動）。
8. ゲーム内で **カメラアイテムを使用** → 枠が出たら **シャッターは Enter**（左クリックではない。下表参照）。
9. まだダメなら **`Config.Debug = true`** にして撮影し、**F8 とサーバーコンソール**の `[jp-pola]` ログを確認。

## 操作キー

| 操作 | キー |
|---|---|
| シャッター | **Enter**（`INPUT_FRONTEND_ACCEPT` / control 176。原作 README の「左クリック」はコードと一致しません） |
| フラッシュ オン／オフ | F |
| カメラを閉じる | Backspace |
| ズームイン／アウト（徒歩） | マウスホイール |
| ズームイン／アウト（車両内） | スクロール代替キー |
| 写真画面を閉じる | Esc |

## インストール

### 1. リソースの配置

このフォルダ（`jp-pola/`）を FiveM サーバーの `resources/[jp-mods]/` などに配置し、`server.cfg` で `ensure jp-pola` する。

> 旧 ps-camera を入れていた場合は、**先に `ensure ps-camera` を外して**から入れ替える（イベント名 `ps-camera:*` は互換のため変えていません。両方入れると競合します）。

### 2. アイテム登録（QBCore）

`qb-core/shared/items.lua` に以下を追加：

```lua
['camera'] = { name = 'camera', label = 'カメラ',     weight = 1000, type = 'item', image = 'camera.png', unique = true, useable = true, shouldClose = true, combinable = nil, description = '写真を撮るためのカメラ。' },
['photo']  = { name = 'photo',  label = '写真',       weight = 500,  type = 'item', image = 'photo.png',  unique = true, useable = true, shouldClose = true, combinable = nil, description = '撮影された写真。' },
```

`jp-pola/images/` に同梱の `camera.png` / `photo.png` をインベントリのリソース（例: `qb-inventory/html/images/`）にコピー。

### 3. アップロード方式の設定

`config.lua` の `Config.UseFivemerr` で **どちらか一方** を選ぶ。

#### A. Fivemerr（既定。`Config.UseFivemerr = true`）

[fivemerr.com](https://fivemerr.com/) で API トークンを発行し、以下のいずれかで設定：

```cfg
# server.cfg（推奨。リポジトリに機微情報が入らない）
set jp-pola_fivemerr_token "your-fivemerr-token"
```

または `server/sv_main.lua` の `SvConfig.FivemerrApiToken` に直書き（旧来互換）。

#### B. Discord Webhook（`Config.UseFivemerr = false`）

Discord チャンネルに Webhook を作成し、以下のいずれかで設定：

```cfg
# server.cfg（推奨）
set jp-pola_webhook "https://discord.com/api/webhooks/..."
```

または `SvConfig.webhook` に直書き。

### 4. インベントリシステム

`server/sv_main.lua` の `SvConfig.Inv` を環境に合わせる：

- `'qb'` … 既定。qb-inventory / lj-inventory 系
- `'ox'` … ox_inventory

## 設定

| 項目 | 値 | 既定 | 説明 |
|---|---|---|---|
| `Config.UseFivemerr` | `true` / `false` | `true` | アップロード方式 |
| `Config.DiscordUploadViaServer` | `true` / `false` | `true` | Discord 時: サーバー経由アップロード（40333 回避） |
| `Config.DiscordRelayMaxBase64Chars` | 整数 | `47185920`（45MiB） | サーバー経由時の base64 最大文字数（高解像度用） |
| `Config.Debug` | `true` / `false` | `false` | デバッグ print |
| `SvConfig.Inv` | `'qb'` / `'ox'` | `'qb'` | インベントリ |
| `SvConfig.webhook` | 文字列 | `''` | Webhook 直書き（空なら convar） |
| `SvConfig.FivemerrApiToken` | 文字列 | `''` | Fivemerr 直書き（空なら convar） |

## 機能

- 一人称 / 三人称カメラビュー
- フラッシュ ON/OFF（実際に光源効果あり）
- マウスホイールズーム
- カメラ HUD（FULL HD / 60 FPS / ISO200 など装飾）
- 撮影写真の Discord または Fivemerr へのアップロード
- アップロード URL の自動クリップボードコピー
- 写真アイテム（`photo`）化して保管・他人に渡せる
- 写真使用時に撮影地（道路名）を表示

## 日本語版で変えたところ（概要）

- UI / 通知 / コンソールログを日本語化
- `fxmanifest` を `cerulean` に更新、`dependencies` を明示
- Webhook / Fivemerr トークンを **convar** から読めるように（既存の直書きも互換維持）
- `onResourceStop` でカメラプロップ・NUI フォーカス等のクリーンアップ
- デバッグ print を `Config.Debug` でガード
- `config.lua` に日本語コメント

詳細は [CHANGELOG_JP.md](CHANGELOG_JP.md) を参照。

## トラブルシュート

### `Warning: could not load 'locales/ja.json'`

**ox_lib** が `lib.locale()` のとき、現在のリソース内の `locales/<言語>.json` を読みに行き、無いとこの警告を出します。

- **jp-pola は ox_lib 不要**です。`fxmanifest.lua` に **`@ox_lib/init.lua` を追加している**場合は、不要ならその行を削除すると警告も消えます（他 MOD の manifest をコピーしたときに混ざりがち）。
- どうしても `ox_lib` を同梱したい場合は、本リソースに **`locales/en.json` と `locales/ja.json`**（空の `{}` で可）を置き、`files` に列挙する。`1.1.0-jp.2` 以降は同梱済み。

## ライセンス・クレジット

本フォークは **[CC BY-NC-SA 4.0](LICENSE)** を継承。

- 原作: **Project Sloth Team** — https://github.com/Project-Sloth/ps-camera
- 日本語版: JP-Mods（[fivem-mods_ja](https://github.com/) リポジトリ内）

**商用利用は不可**。再配布する場合も同じ CC BY-NC-SA 4.0 で配布してください（ShareAlike）。
