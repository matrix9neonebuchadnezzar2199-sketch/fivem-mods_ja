# インストールガイド

## 前提条件

次が導入・起動済みであること。

- FiveM Server（アーティファクトは可能な限り新しめ）
- **ESX** または **QBCore** のいずれか
- **ox_lib**（最新推奨）
- **ox_target**（最新推奨）
- MySQL（ESX でジョブ SQL を使う場合）

## ステップ1: ファイルの配置

GitHub から clone した場合、**`jp-deliveryjobv2` フォルダ全体**（この README や `fxmanifest.lua` が同じ階層にあるフォルダ）を、サーバーの `resources` 配下に置きます。

- **正しい例**: `server-data/resources/[jobs]/jp-deliveryjobv2/fxmanifest.lua` が存在する
- **リソース名**はフォルダ名と一致します。既定では **`ensure jp-deliveryjobv2`**
- フォルダ名を変えた場合（例: `jp-delivery`）は、`server.cfg` の `ensure` も同じ名前に合わせる

## ステップ2: データベース（ESX のみ）

phpMyAdmin 等で `Data.sql` を実行する（リソースルート直下のファイル）。

中身は `jobs` / `job_grades` に `delivery` ジョブを追加する INSERT です。

## ステップ2（代替）: QBCore

`qb-core/shared/jobs.lua` に例:

```lua
['delivery'] = {
    label = '配達員',
    defaultDuty = true,
    grades = {
        ['0'] = { name = '配達員', payment = 50 }
    }
}
```

※上記の `payment` は QBCore のジョブグレード給与です。本スクリプトの配達完了報酬は別で、`config/config.lua` の `Config['Delivery']['FinalPayout']`（最小〜最大の乱数）により支給されます。

## ステップ3: server.cfg

```cfg
ensure ox_lib
ensure ox_target
ensure es_extended
# または ensure qb-core
ensure jp-deliveryjobv2
```

`es_extended` / `qb-core` は環境に合わせて一方だけでよいです。`jp-deliveryjobv2` は依存リソースより後に置いてください。

## ステップ4: 設定確認

`config/config.lua`:

```lua
Config['Framework'] = 'auto'   -- 自動検出でよければこのまま
Config['JobName']   = false    -- 全員OK。配達員ジョブのみなら 'delivery' など
```

## ステップ5: 起動確認

サーバー起動後、コンソールに次のような表示があればフレームワーク検出は成功しています。

- `nek_delivery: ESXフレームワークを使用します` または QBCore 版
- `nek_deliveryV2_jp` のバージョンチェックメッセージ

`refresh` 後に `jp-deliveryjobv2 does not have a resource manifest` と出る場合は、`fxmanifest.lua` が **`jp-deliveryjobv2` フォルダの直下**にない配置になっています。パスを確認してください。

## ステップ6: ゲーム内テスト

1. 座標 `(-1177.998, -892.051, 13.757)` 付近（設定どおりの場合）へ移動
2. **配達センター** ブリップの有無
3. NPC に ox_target で **配達メニューを開く** が出るか

## トラブルシューティング

### `Couldn't find resource jp-deliveryjobv2`

- `resources` 以下に **`jp-deliveryjobv2` という名前のフォルダ**があり、その直下に `fxmanifest.lua` があるか確認する
- `refresh` を実行してから `ensure jp-deliveryjobv2` を試す

### NPC が出ない / メニューが出ない

- `ox_lib` が先に起動しているか（`ensure` の順序）
- F8 クライアント・サーバーコンソールのエラー

### ターゲットが反応しない

- `ox_target` が起動しているか、`/ensure ox_target` で再読み込み

### Webhook が送られない

- `Config['EnableWebhook'] = true` と `Config['Webhook']` の URL を確認
- 本パッケージでは `server/bridge.lua` に `getIdentifiers` を実装済みです（追加作業は通常不要）

### スポーン地点の通知（他車が塞いでいる等）

- スポーン地点に他車がいると、通知後に開始に失敗することがあります。`Config['Delivery']['Vehicles']['Spawner']['coords']` を調整するか、付近の車両を移動してください。

## アップデート

`jp-deliveryjobv2` フォルダを差し替えたあと、サーバーで `refresh` / `ensure jp-deliveryjobv2` または再起動してください。
