# nek_deliveryjobV2 日本語版（jp-deliveryjobv2）

FiveM向け配達ジョブスクリプト「nek_deliveryjobV2」の **日本語化** パッケージです。  
オリジナル: [TtvNekix/nek_deliveryjobV2](https://github.com/TtvNekix/nek_deliveryjobV2)

## 特徴

- **日本語化**: ロケール、NUI、Discord Webhook フィールド名、主要コメントを日本語化
- **マルチフレームワーク**: ESX / QBCore（`auto` で自動検出）
- **UI**: 配達進捗を画面に表示
- **ox_target**: インタラクション
- **Discord Webhook**: 業務ログ・支払いログ（任意）
- **設定**: `config/config.lua` でルート・車両・報酬などを変更可能

## 必要なもの

| リソース | 用途 |
|---------|------|
| FiveM サーバー | 本体 |
| ESX または QBCore | フレームワーク |
| [ox_lib](https://github.com/overextended/ox_lib) | UI / 通知 / コールバック |
| [ox_target](https://github.com/overextended/ox_target) | ターゲット |

## インストール

詳細は [INSTALL.md](INSTALL.md) を参照してください。

**よくある間違い**: リポジトリの親フォルダ名は `jp-deliveryjobv2` ですが、サーバーで `ensure` するのは **`nek_deliveryjobV2`** です（`fxmanifest.lua` があるのは内側のフォルダのみ）。`ensure jp-deliveryjobV2` ではリソースが見つかりません。

手順の概要:

1. **`nek_deliveryjobV2` フォルダだけ**をサーバーの `resources` 配下に置く（例: `resources/[jobs]/nek_deliveryjobV2/`）。親の `jp-deliveryjobv2` ごとコピーした場合も、中の `nek_deliveryjobV2` がリソースのルートになるようにパスを確認する
2. ESX の場合: `Data.sql` をデータベースに実行する
3. `server.cfg` に `ensure ox_lib` / `ensure ox_target` / フレームワーク / `ensure nek_deliveryjobV2` を追加する
4. サーバー再起動

## ゲーム内の流れ

1. マップの **配達センター** ブリップへ向かう
2. 受付 NPC にターゲットで **配達メニューを開く**
3. **業務を開始** → 車両スポーン・荷物出現
4. 荷物を拾い、トランクに積む
5. GPS の順に配達 → 各所でトランクから取り出して **荷物を配達する**
6. 完了後は本部へ → **車両を返却する** と報酬（設定範囲内ランダム）

## カスタマイズ

`nek_deliveryjobV2/config/config.lua` で変更できます。

- `Config['JobName']` … `false` で誰でも / `'delivery'` などでジョブ限定
- `Config['Delivery']['FinalPayout']` … 報酬の最小・最大
- `Config['Delivery']['Vehicles']['Cars']` … 使用車両
- `Config['Delivery']['Routes']` … 配達ルート（推奨: `{ name = "表示名", stops = { vec3(...), ... } }`。旧来の `vec3` 配列のみでも可で、自動的に `ルート N` と化けます）
- `Config['Locales']` … 表示文言

和製地名にしたい場合は、`name` だけ差し替えれば NUI ヘッダ（`配達ルート: …`）にそのまま反映されます。`stops` 内の座標は現行 `config.lua` からコピーして流用してください。

```lua
-- 和製地名にしたい場合の例（stops は実際の vec3 列に置き換え）
['Routes'] = {
    { name = "下町ルート",   stops = { vec3(...), vec3(...) } },
    { name = "山の手ルート", stops = { vec3(...), vec3(...) } },
    { name = "湾岸ルート",   stops = { vec3(...), vec3(...) } },
}
```

## 他リソースからの利用（exports）

リソース名はフォルダ名（既定: `nek_deliveryjobV2`）です。

```lua
local workers = exports['nek_deliveryjobV2']:GetActiveWorkers()
local isWorking = exports['nek_deliveryjobV2']:IsPlayerWorking(source)
```

## Discord Webhook

```lua
Config['EnableWebhook'] = true
Config['Webhook'] = "https://discord.com/api/webhooks/..."
```

プレイヤー識別子は `server/bridge.lua` の `getIdentifiers` で取得します（Webhook 用）。

## ライセンス

MIT License（オリジナルに準拠）— [LICENSE](LICENSE)

## クレジット

- オリジナル作者: **Nekix**（[TtvNekix](https://github.com/TtvNekix)）
- 日本語化整備: **matrix9neonebuchadnezzar2199**
- 参考: [CFX Forum](https://forum.cfx.re/t/free-esx-qbcore-nekix-delivery-job-v2/5389433)

## 変更履歴（日本語版）

[CHANGELOG_JP.md](CHANGELOG_JP.md)
