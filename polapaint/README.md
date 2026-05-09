# polapaint v2.0

ポラロイド風カメラ・写真編集（NUI）・チェキ風ビューワ。写真データは **Discord CDN ではなくサーバー側ローカルファイル**（`data/photos/`）に保存し、`SetHttpHandler` で JPEG を配信します。

## 要件

- **screenshot-basic**（別リソース）。`ensure screenshot-basic` の後に `ensure polapaint` を推奨。
- **ox_inventory** または **qb-core / qb-inventory**（`Config.Framework = 'auto'` で自動判定）。
- Lua **5.4**（`lua54 'yes'`）。

## 設定

### `config.lua`

- `Config.Locale` … `ja` / `en`
- `Config.Items` … items.lua のアイテム名と一致させる

### `server.cfg`（Webhook は任意）

Webhook URL は **convar** で渡します（config にハードコードしない）。

```
set polapaint_webhook ""
```

実 URL を設定すると Discord にテキスト通知（任意で埋め込み画像）。埋め込み画像を使う場合は `Config.Webhook.publicBaseUrl` に **外部から到達可能なベース URL**（例: リバースプロキシで `/polapaint` をサーバーに転送）を設定してください。

## 運用上の注意

1. **`SetHttpHandler` はプロセス全体で最後に登録したハンドラが有効**になる実装です。他リソースが同 API を使う場合は読み込み順・競合に注意してください。
2. 写真ファイルは `polapaint/data/photos/<id>.jpg` に蓄積されます。容量管理は OS の `find` / タスクスケジューラ等での削除を推奨します。
3. **複数ノード／ロードバランサ**ではローカルファイルが共有されないため、別ストレージ連携が必要です（`server/storage.lua` の差し替えポイント）。
4. NUI からのアップロードは **`http://<GetCurrentServerEndpoint>/<resource>/uploadCapture`** に対して JPEG を POST します（クライアントが `httpUploadBase` を NUI に渡します）。

## アイテム登録

`snippets/` の例を参照して `ox_inventory` または QBCore の items に追加してください。QB は `server/main.lua` 内で `CreateUseableItem` を登録済みです。

## ライセンス

GPL-3.0-or-later（`LICENSE` 参照）。
