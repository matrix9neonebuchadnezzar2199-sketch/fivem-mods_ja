# polapaint（拡張ポラロイドカメラ）

FiveM 用の拡張ポラロイドカメラ MOD。`screenshot-basic` で撮影し、Discord Incoming Webhook で画像 URL を発行、`ox_inventory` のメタデータに保存します。写真アイテムは NUI で落書きし、再アップロードして同じスロットの `metadata.url` を上書きできます。

## ライセンス

本ディレクトリ配下のコードは **GNU General Public License v3.0**（`LICENSE` 参照）です。リポジトリ他部分が別ライセンスでも、polapaint サブツリーは GPL-3.0 が適用されます。

## 依存リソース

- [ox_inventory](https://github.com/overextended/ox_inventory) … **必須**（`fxmanifest` の `dependency`）
- **screenshot-basic** … **撮影に必須**。本リポの **ルート直下 `screenshot-basic/`** に MIT ライセンスのもと**ビルド済み同梱**（`LICENSE` / `BUNDLED_WITH_POLAPAINT.md` 参照）。サーバの `resources` に **polapaint と同じ階層**でフォルダごとコピーし、`server.cfg` で **`ensure screenshot-basic` を `ensure polapaint` より前**に書く。

`server.cfg` では、`ox_inventory` と `screenshot-basic` の **後** に `ensure polapaint` するようにしてください。

## 導入手順

1. `polapaint` と **`screenshot-basic`**（リポルートのフォルダ）を `resources` 配下に**同じ階層で**配置する（例: `[jp-mods]/polapaint` と `[jp-mods]/screenshot-basic`）。
2. `config.lua` の `Config.DiscordWebhook` に、Discord サーバーで発行した **Incoming Webhook の完全な URL** を設定する（`?wait=true` はサーバー側で自動付与されます）。
3. `ox_inventory` の `data/items.lua`（または運用中の items 定義）に、**下記「アイテム設定コード」**を追記する。キー名は `config.lua` の `Config.Items.camera` / `Config.Items.photo` と一致させる（既定は `polaroid_camera` / `polaroid_photo`）。
4. **インベントリ画像（推奨）**: 下記 `items.lua` 例のとおり **`nui://polapaint/html/images/...png`** を指定すれば、**`polapaint` の `fxmanifest` の `files` に含まれる PNG** がそのまま使われます（`ox_inventory/web/images/` へのコピーは不要）。従来どおり ox 側に置く場合は PNG を `ox_inventory/web/images/` にコピーし、`image = 'polaroid_camera'`（拡張子なし）でも可。
5. `refresh` 後、`ensure polapaint` で起動確認する。

## ox_inventory アイテム設定（items.lua 追記例）

items 定義へ以下を追加する（**カメラと写真の両方**が必要です。`polaroid_photo` が無いと撮影後の `AddItem` が失敗します）。

```lua
['polaroid_camera'] = {
    label = 'ポラロイドカメラ',
    weight = 400,
    stack = true,
    consume = 0,
    close = true,
    description = '画面を撮影してチェキアイテムを作成する',
    client = {
        image = 'nui://polapaint/html/images/polaroid_camera.png',
        export = 'polapaint.useCamera',
    },
},

['polaroid_photo'] = {
    label = 'チェキ（写真）',
    weight = 50,
    stack = false,
    consume = 0,
    close = true,
    description = '使用: 落書き編集 / 右クリックメニュー「チェキを見る」: 閲覧のみ',
    client = {
        image = 'nui://polapaint/html/images/polaroid_photo.png',
        export = 'polapaint.usePhoto',
    },
    buttons = {
        {
            label = 'チェキを見る',
            action = function(slot)
                exports['polapaint']:openPhotoViewer(slot)
            end,
        },
    },
},
```

同一内容のファイル: `snippets/ox_inventory_items.lua.example`（コメント付き）。

Webhook の実トークンをリポジトリにコミットしないこと。ローカル用のメモファイルは `.gitignore` で除外する運用を推奨します。

## 設計メモ

- **カメラ**: `items.lua` では **`stack = true`** 推奨（複数台を同一スロットにまとめる）。撮影してもカメラは消費しません（`consume = 0`）。
- **写真**: 撮影後に NUI で **名前を入力** → 付与される `polaroid_photo` の **`metadata.label`** にその名前が入ります（長さは `Config.MaxPhotoNameLength` でサーバー検証）。
- **アイコン素材用プロンプト**: `assets/inventory_icons/IMAGE_PROMPTS.md` を参照。

## 操作

| 操作 | 内容 |
| --- | --- |
| ポラロイドカメラを使用 | 撮影 → 名前入力ウィンドウ → 最大幅 `Config.MaxImageWidth` に縮小済み画像を Webhook へ → `polaroid_photo` を 1 枚付与（指定名をメタデータに保存） |
| 写真アイテムを使用 | ペイント NUI（保存で同じスロットの URL を更新） |
| インベントリのコンテキスト「チェキを見る」 | チェキ風フレームの閲覧のみ NUI |

## トラブルシュート

- **`No such export useCamera in resource PolaPaint`**（`useItem` コールバック）… リソース名は **`polapaint`（全小文字）** に変更済みです。`ox_inventory` の `items.lua` で **`PolaPaint.useCamera` になっている箇所をすべて `polapaint.useCamera` に修正**し（`usePhoto`・`exports['polapaint']:openPhotoViewer` も同様）、**`restart ox_inventory`**（またはサーバ再起動）してください。エラーメッセージに **`PolaPaint`** と出ている時点で、まだ旧リソース名を参照しています。
- **`Could not find dependency screenshot-basic`** … `screenshot-basic` フォルダがサーバの `resources` に無い、または名前が違う。本リポの **`screenshot-basic/` を polapaint と並べてコピー**し、`ensure screenshot-basic` を追加する。
- **Mixed Content / `Failed to fetch`（`http://screenshot-basic/screenshot_created`）** … 新しい CEF では NUI が HTTPS のため、上流の **`http://` コールバック URL** がブロックされます。本リポ同梱の **`screenshot-basic` v1.0.1** では `dist/client.js` を **`https://`** に修正済みです。古い同梱版を手元で直す場合は `screenshot-basic/BUNDLED_WITH_POLAPAINT.md` を参照。
- **インベントリでカメラ／チェキの絵が出ない** … `items.lua` の `client.image` を **`nui://polapaint/html/images/polaroid_camera.png`**（写真は `polaroid_photo.png`）にするか、`ox_inventory/web/images/` に同名 PNG を置いて **`restart ox_inventory`** してください。
- **名前を付けても写真が増えない** … **`polaroid_photo` が `items.lua` に未定義**だと `AddItem` が `invalid_item` で失敗します（カメラだけ追加していないか確認）。**インベントリ満杯・重量オーバー**でも同様です。`config.lua` の **`Config.DiscordWebhook`** が正しいか、F8／サーバーログも併せて確認してください。
- **Webhook 未設定の通知** … `config.lua` の URL がプレースホルダのままです。
- **撮影・保存が失敗** … Discord の Webhook が無効、またはペイロードが大きすぎます。`Config.JpegQuality` を下げる、`Config.MaxImageWidth` を下げる、`Config.MaxBase64PayloadLength` を確認してください。
- **ペイント保存で真っ黒・失敗** … 外部画像の CORS により Canvas が汚染されている可能性があります。Discord CDN の URL で通常は問題ありません。

## 開発メモ

- イベント名は `polapaint:server:*` / `polapaint:client:*` です。
- 文字コードは **UTF-8（BOM なし）** で保存してください。
