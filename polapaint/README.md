# polapaint v2.0

ポラロイド風カメラ・写真編集（NUI）・チェキ風ビューワ。写真データは **Discord CDN ではなくサーバー側ローカルファイル**（`data/photos/`）に保存し、当リソースの **`SetHttpHandler`** で JPEG を配信します。

## 要件

- **screenshot-basic**（別リソース）。**起動順**: `ensure screenshot-basic` の後に `ensure polapaint` を推奨。これは **HTTP の競合ではなく**、`exports['screenshot-basic']:requestScreenshot` が解決できるようにするためです。
- **ox_inventory** または **qb-core / qb-inventory**（`Config.Framework = 'auto'` で自動判定）。
- Lua **5.4**（`lua54 'yes'`）。

## NUI からのアップロード経路

FiveM の CEF は、URL によって **`SetHttpHandler`** に届く経路と **`files` で宣言した静的ファイル**を返す経路が分かれます。**JPEG アップロード**は `postNuiBinary` が **`http://<リソース名>/uploadCapture` / `uploadEdit`** に POST します（クエリは付けず **`X-Polapaint-*` ヘッダ**で token / name / slot を送る）。

一部環境では **`https://` の POST がサーバー HTTP ハンドラに届かず 404** になる報告があるため、バイナリ POST だけ **`http://`** としています。通常の `RegisterNUICallback` 向け JSON（`postNui`）は従来どおり **`https://`** です。

サーバーは **クエリまたはヘッダ**のどちらでも `token` 等を受け取れます。`curl` の手動テストはクエリ付き URL でも動きます。

## `SetHttpHandler` と他リソースについて

**`SetHttpHandler` はリソースごとに 1 つ登録でき、URL の先頭セグメント（リソース名）でルーティングされます。** `screenshot-basic` のハンドラと **衝突しません**（`/screenshot-basic/...` と `/polapaint/...` は別宛先）。

## 設定

### `config.lua`

- `Config.Locale` … `ja` / `en`
- `Config.Items` … items.lua のアイテム名と一致させる

### `server.cfg`（Webhook は任意）

Webhook URL は **convar** で渡します（config にハードコードしない）。

```
set polapaint_webhook ""
```

実 URL を設定すると Discord にテキスト通知（任意で埋め込み画像）。

### `Config.Webhook.publicBaseUrl`（任意）

Embed の `image.url` に使う場合、その URL は **Discord のサーバー側から取得可能な公開アドレス**である必要があります。プライベート IP やゲームポートだけでは埋め込み画像は表示されません（テキスト通知のみなら問題になりにくい）。

**ローカル NUI 内での写真表示だけが目的なら `publicBaseUrl` は空のままで構いません。**

実装では埋め込み URL を `('%s/photo/<signed>.jpg'):format(publicBaseUrl, …)` の形で組み立てます（`server/webhook.lua` 経由の画像 URL 生成と同じパス規則）。

| 例 | 結果 |
|----|------|
| `https://photos.example.com/polapaint` | `https://photos.example.com/polapaint/photo/<signed>.jpg`（意図どおり） |
| `https://photos.example.com/polapaint/` | 末尾スラッシュはコード側で除去されるため **OK** |
| `https://photos.example.com/` | リソース名パスが無く **`/photo/...` が想定とずれる** |
| `https://photos.example.com/photo` | **`/photo/photo/...` になりやすい**（プロキシの `location` と混同しないこと） |

リバースプロキシ例（ゲームサーバの `/polapaint/` を FiveM の同一リソースに渡す）:

```nginx
location /polapaint/ {
    proxy_pass http://127.0.0.1:30120/polapaint/;
    proxy_set_header Host $host;
}
```

（ポートや upstream は環境に合わせて変更）

## QBCore（qb-inventory）について

ox_inventory の **`buttons`（コンテキストから「閲覧」）** に相当する機能は QB 標準に無いため、**チェキ風ビューワーだけ**を素の QB だけで出すことは難しいです。本リソースの QB 登録では **写真アイテムの USE → `requestEdit`（ペイント編集）** になります。

- **閲覧のみ**が必要な場合: 自作の `RegisterCommand` / `exports` / qb-target から `exports['polapaint']:openPhotoViewer(slot)` を呼ぶ運用を検討してください。
- **USE = 編集**・**閲覧は別導線**という前提を運営・プレイヤーに共有してください。

## 運用上の注意

1. 写真ファイルは `polapaint/data/photos/<id>.jpg` に蓄積されます。容量管理は OS の `find` / タスクスケジューラ等での削除を推奨します。
2. **複数ノード／ロードバランサ**ではローカルファイルが共有されないため、別ストレージ連携が必要です（`server/storage.lua` の差し替えポイント）。
3. **`polapaint_old/`** は旧版アーカイブ用です。**`fxmanifest.lua` を `.disabled` にしてあるため FiveM のリソースとしては認識されません。`ensure polapaint_old` はしないでください。**（参照・履歴用のみ）

## アイテム登録

`snippets/` の例を参照して `ox_inventory` または QBCore の items に追加してください。QB は `server/main.lua` 内で `CreateUseableItem` を登録済みです。

## ライセンス

GPL-3.0-or-later（`LICENSE` 参照）。
