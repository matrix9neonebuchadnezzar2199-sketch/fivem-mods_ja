# PolaPaint

FiveM 用の拡張ポラロイドカメラ MOD。`screenshot-basic` で撮影し、Discord Incoming Webhook で画像 URL を発行、`ox_inventory` のメタデータに保存します。写真アイテムは NUI で落書きし、再アップロードして同じスロットの `metadata.url` を上書きできます。

## ライセンス

本ディレクトリ配下のコードは **GNU General Public License v3.0**（`LICENSE` 参照）です。リポジトリ他部分が別ライセンスでも、PolaPaint サブツリーは GPL-3.0 が適用されます。

## 依存リソース

- [ox_inventory](https://github.com/overextended/ox_inventory)
- [screenshot-basic](https://github.com/citizenfx/screenshot-basic)

`server.cfg` では、上記の **後** に `ensure PolaPaint` するようにしてください。

## 導入手順

1. `PolaPaint` を `resources` 配下に配置する。
2. `config.lua` の `Config.DiscordWebhook` に、Discord サーバーで発行した **Incoming Webhook の完全な URL** を設定する（`?wait=true` はサーバー側で自動付与されます）。
3. `ox_inventory` の `items.lua` に、`snippets/ox_inventory_items.lua.example` を参考にアイテムを追加する（アイテム名は `config.lua` の `Config.Items` と一致させる）。
4. スロット用アイコンは **`assets/inventory_icons/polaroid_camera.png` と `polaroid_photo.png`** を `ox_inventory/web/images/` にコピーする（リポに同梱済み。割当が逆なら README.txt の追記を参照）。
5. `refresh` 後、`ensure PolaPaint` で起動確認する。

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

- **Webhook 未設定の通知** … `config.lua` の URL がプレースホルダのままです。
- **撮影・保存が失敗** … Discord の Webhook が無効、またはペイロードが大きすぎます。`Config.JpegQuality` を下げる、`Config.MaxImageWidth` を下げる、`Config.MaxBase64PayloadLength` を確認してください。
- **ペイント保存で真っ黒・失敗** … 外部画像の CORS により Canvas が汚染されている可能性があります。Discord CDN の URL で通常は問題ありません。

## 開発メモ

- イベント名は `PolaPaint:server:*` / `PolaPaint:client:*` です。
- 文字コードは **UTF-8（BOM なし）** で保存してください。
