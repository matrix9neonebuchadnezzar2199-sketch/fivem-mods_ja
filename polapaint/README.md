# polapaint v2.0

ポラロイド風カメラ・写真編集（NUI）・チェキ風ビューワ。写真データは **Discord CDN ではなくサーバー側ローカルファイル**（`data/photos/`）に保存し、当リソースの **`SetHttpHandler`** で JPEG を配信します。

## 要件

- **screenshot-basic**（別リソース）。**起動順**: `ensure screenshot-basic` の後に `ensure polapaint` を推奨。これは **HTTP の競合ではなく**、`exports['screenshot-basic']:requestScreenshot` が解決できるようにするためです。
- **ox_inventory** または **qb-core / qb-inventory**（`Config.Framework = 'auto'` で自動判定）。
- Lua **5.4**（`lua54 'yes'`）。

## NUI からのアップロード経路

CEF NUI からの `fetch('https://<リソース名>/uploadCapture?...', { method: 'POST', body: JPEG blob })` は、静的ファイルに無ければ **当リソースに登録した `SetHttpHandler` にディスパッチ**されます（GET / POST 共通）。v2.0 はこの経路で JPEG を受け取ります。

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

## 運用上の注意

1. 写真ファイルは `polapaint/data/photos/<id>.jpg` に蓄積されます。容量管理は OS の `find` / タスクスケジューラ等での削除を推奨します。
2. **複数ノード／ロードバランサ**ではローカルファイルが共有されないため、別ストレージ連携が必要です（`server/storage.lua` の差し替えポイント）。
3. **`polapaint_old/`** は旧版アーカイブ用です。**`fxmanifest.lua` を `.disabled` にしてあるため FiveM のリソースとしては認識されません。`ensure polapaint_old` はしないでください。**（参照・履歴用のみ）

## アイテム登録

`snippets/` の例を参照して `ox_inventory` または QBCore の items に追加してください。QB は `server/main.lua` 内で `CreateUseableItem` を登録済みです。

## ライセンス

GPL-3.0-or-later（`LICENSE` 参照）。
