# jp-sentinel（JP-Sentinel）

警察職向けの自律追尾ドローン「Sentinel Ball」リソースです。スタンドアロン設計で、`Config.Framework` により ESX / QBCore / Qbox / ACE（standalone）に対応します。

## 必要環境

- FiveM（Cerulean / Lua 5.4）
- （任意）`oxmysql`：`Config.Cooldown.Persist = true` のときのみ。`false`（既定）では不要

## インストール

1. 本フォルダを `resources/[jp-mods]/jp-sentinel` などに配置する
2. `server.cfg` に `ensure jp-sentinel` を追加する
3. `config.lua` で `Config.Framework`・`Config.PoliceJobs`・`Config.StandalonePoliceAce` を環境に合わせる
4. インベントリに `Config.ItemName`（既定 `sentinel_ball`）を定義する（フレームワーク側のアイテム定義が必要）
5. standalone のときはアイテムフックは無効のため、`Config.EnableCommand = true` の `/sentinel` 運用またはインベントリ側の独自フックが必要

## テスト／アイテム連携（フレームワーク別の目安）

実際のテスト環境に合わせて **`config.lua` の `Config.Framework`** を `'qbox'` / `'qb'` / `'esx'` のいずれかに合わせてください（ジョブ判定・従来の `RegisterUsable` 消費に使用）。**インベントリが ox_inventory の場合、アイテム使用は下記の export 経由が確実**です（Qbox でも ox_inventory が多い構成）。

### 最短ルート（アイテムなし）

1. 警察ジョブ（または standalone の ACE）を付与する  
2. ゲーム内で **`/sentinel`**（`Config.EnableCommand = true` のとき）  
3. 左手に **`WEAPON_BALL`** が付いたら攻撃ボタンで投擲  

### ox_inventory（共通）：`data/items.lua` に登録

**重要：** ox_inventory は `server.export` だけの項目に **`consume` を書かないと既定で `consume = 1` になり、使用時にアイテムが消えます。**  
jp-sentinel は **命中／不発のタイミングでサーバーから `RemoveItem` する**ため、**必ず `consume = 0`** にしてください。

```lua
['sentinel_ball'] = {
    label = 'Sentinel Ball',
    weight = 300,
    stack = false,
    close = true,
    consume = 0, -- ★必須（無いと使用時に勝手に消費される）
    description = '投擲式の自律追尾ドローン。警察関係者専用。',
    client = {
        image = 'sentinel_ball.png', -- ox_inventory/web/images/ に配置（無くても動くが表示は❓になりがち）
    },
    server = {
        export = 'jp-sentinel.useSentinelBall',
    },
},
```

- 画像: `ox_inventory/web/images/sentinel_ball.png`（無くてもテスト可）  
- jp-sentinel 側では **`exports('useSentinelBall', ...)`** を実装済み。失敗時（非警察・CD・多重など）は **`usingItem` で `false` を返して使用をキャンセル**します。  
- **`ox_inventory` が動いているとき**、`reportMiss` / `reportHit` 後の消費は **`exports.ox_inventory:RemoveItem`** を優先します。

### アイテム付与（テスト用）

- **ox_inventory**: コンソール／管理者コマンドは環境依存（多くは `giveitem` 系）。txAdmin やサーバー付属の admin で **`sentinel_ball` を 1 個**付与する。  
- **QBCore/Qbox（qb-inventory 等）**: よくある `/giveitem [id] sentinel_ball 1`  
- **ESX**: `admin` や `es_extended` の give コマンドで `sentinel_ball` を付与  

### 従来フレームワークの usable（ox_inventory を使わない場合）

`bridge/inventory.lua` の **`RegisterUsable`** が、**ESX / QB / Qbox** の API で `Config.ItemName` を登録します（サーバー起動約 0.5 秒後）。**アイテム名は DB／共有設定と `Config.ItemName` を一致**させてください。

### テスト手順チェックリスト（目安）

1. `ensure jp-sentinel` でエラーなし  
2. 警察ジョブ（または ACE）を確認  
3. `/sentinel` または `sentinel_ball` を使用 → ボールが手に入る → 投擲  
4. NPC／プレイヤー命中でドローン・ブリップ確認  
5. 撃墜・タイムアウトの演出確認  

## クールダウン永続化（任意）

`Config.Cooldown.Persist = true` にした場合:

- `oxmysql` を開始済みにする
- `sql/jp_sentinel_cooldowns.sql` をデータベースに適用する

## ライセンス

MIT（本文はリポジトリルート `LICENSE` に準拠）

## 作者

[@eiho_tsukuyomi](https://x.com/eiho_tsukuyomi)
