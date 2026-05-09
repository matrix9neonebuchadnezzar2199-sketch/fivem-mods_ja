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
4. スロット用アイコンは **`assets/inventory_icons/polaroid_camera.png` と `polaroid_photo.png`** を `ox_inventory/web/images/` にコピーする（リポに同梱済み。割当が逆なら `assets/inventory_icons/README.txt` を参照）。
5. `refresh` 後、`ensure polapaint` で起動確認する。

## ox_inventory アイテム設定（items.lua 追記例）

`ox_inventory/web/images/` に `polaroid_camera.png` と `polaroid_photo.png` を置いたうえで、items 定義へ以下を追加する（`image` は拡張子なしのベース名）。

```lua
['polaroid_camera'] = {
    label = 'ポラロイドカメラ',
    weight = 400,
    stack = true,
    consume = 0,
    close = true,
    description = '画面を撮影してチェキアイテムを作成する',
    client = {
        image = 'polaroid_camera',
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
        image = 'polaroid_photo',
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

- **`Could not find dependency screenshot-basic`** … `screenshot-basic` フォルダがサーバの `resources` に無い、または名前が違う。本リポの **`screenshot-basic/` を polapaint と並べてコピー**し、`ensure screenshot-basic` を追加する。
- **Webhook 未設定の通知** … `config.lua` の URL がプレースホルダのままです。
- **撮影・保存が失敗** … Discord の Webhook が無効、またはペイロードが大きすぎます。`Config.JpegQuality` を下げる、`Config.MaxImageWidth` を下げる、`Config.MaxBase64PayloadLength` を確認してください。
- **ペイント保存で真っ黒・失敗** … 外部画像の CORS により Canvas が汚染されている可能性があります。Discord CDN の URL で通常は問題ありません。

## 開発メモ

- イベント名は `polapaint:server:*` / `polapaint:client:*` です。
- 文字コードは **UTF-8（BOM なし）** で保存してください。
