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
3. **左クリックで投擲**（物理ボール prop を生成して発射。**WEAPON_BALL は使用しない**ため ox_inventory の武器剥奪の影響を受けない）  
4. **右クリックでキャンセル**（Pending のみ解除・アイテム消費なし）  

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

### Qbox + ox_inventory（よくある構成の確定メモ）

- **`config.lua`**: `Config.Framework = 'qbox'` のまま。`Config.ItemName = 'sentinel_ball'`、`Config.EnableCommand = true`、`Config.CommandName = 'sentinel'`。`Config.PoliceJobs` は **`qbx_core/shared/jobs.lua`（またはプロジェクト内のジョブ定義）の警察ジョブ名と一致**させる（デフォルトは多くが `police`。`lspd` 等に改名しているサーバーはそれに合わせる）。
- **`server.cfg` の起動順**: `oxmysql` → `ox_lib` → `ox_inventory` → `qbx_core` など Qbox 一式 → 最後に **`ensure [jp-mods]`**（`jp-sentinel` を含む MOD は依存の後ろ）。
- **アイテム付与（テスト）**: 多くの環境で **`/giveitem [プレイヤーID] sentinel_ball 1`**。無効なら **`/additem [ID] sentinel_ball 1`** 等、サーバー付属の管理者コマンドを確認。
- **警察ジョブ**: 例 **`/setjob [ID] police 1`**（グレードはサーバー仕様に合わせる。jp-sentinel の判定は **ジョブ名の一致**が中心）。
- **まず `/sentinel` だけで [3][4] 相当を確認**してから `sentinel_ball` の使用テストに進むと切り分けが早い。
- **通常自爆の時短テスト**: テスト中のみ `Config.TrackDuration = 30` などに下げ、終わったら **`600` に戻す**。
- **トラブル**: `not_police` はジョブ名不一致が典型。コンソールに **`no export`** が出たら `items.lua` の `server.export = 'jp-sentinel.useSentinelBall'` とリソース名を確認。

### アイテム付与（テスト用）

- **ox_inventory**: コンソール／管理者コマンドは環境依存（多くは `giveitem` 系）。txAdmin やサーバー付属の admin で **`sentinel_ball` を 1 個**付与する。  
- **QBCore/Qbox（qb-inventory 等）**: よくある `/giveitem [id] sentinel_ball 1`  
- **ESX**: `admin` や `es_extended` の give コマンドで `sentinel_ball` を付与  

### 従来フレームワークの usable（ox_inventory を使わない場合）

`bridge/inventory.lua` の **`RegisterUsable`** が、**ESX / QB / Qbox** の API で `Config.ItemName` を登録します（サーバー起動約 0.5 秒後）。**アイテム名は DB／共有設定と `Config.ItemName` を一致**させてください。

### テスト手順チェックリスト（目安）

1. `ensure jp-sentinel` でエラーなし  
2. 警察ジョブ（または ACE）を確認  
3. `/sentinel` または `sentinel_ball` を使用 → 案内に従い **左クリックで投擲**（物理ボール）  
4. NPC／プレイヤー命中でドローン・ブリップ確認  
5. 撃墜・タイムアウトの演出確認  

### 状態が残って「既に展開中」だけが出るとき

- サーバーで **`restart jp-sentinel`**（メモリ状態リセット）
- または **`sentinel_reset`**（運営向け）：**ACE `command.sentinel_reset`** を付けたプレイヤーが実行すると、**自分の Pending と自分が投げた Sentinel** をサーバー側で強制終了。コンソール（txAdmin）から実行すると **全員分を一括クリア**
- リソース **`onResourceStart`** でも進行中エントリを初期化するため、**`restart` 後は空の状態から始まります**

## クールダウン永続化（任意）

`Config.Cooldown.Persist = true` にした場合:

- `oxmysql` を開始済みにする
- `sql/jp_sentinel_cooldowns.sql` をデータベースに適用する

## ライセンス

MIT（本文はリポジトリルート `LICENSE` に準拠）

## 作者

[@eiho_tsukuyomi](https://x.com/eiho_tsukuyomi)
