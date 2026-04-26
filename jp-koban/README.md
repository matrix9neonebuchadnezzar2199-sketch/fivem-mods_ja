# jp-koban

警察向け**住宅地巡回パトロール**（Qbox + ox_lib + ox_target + qbx_core）。

## 導入

- `config.lua` の座標・報酬を確認
- `server.cfg` 例: `ensure jp-koban`（`ox_lib` / `ox_target` / `qbx_core` 前提）

---

## ジョブ制限

- **NPC への `ox_target` インタラクト**に `canInteract` を付与
- `exports.qbx_core:GetPlayerData().job.name == 'police'`（設定値: `config.lua` の `Config.RequiredJob`）のとき**のみ**、巡回受付・巡回報告のターゲットを表示
- 条件を満たさないプレイヤーには**ターゲットが出ない**（従来どおり、誤爆通知は出さない）
- **サーバー**の `jp-koban:completePatrol` 受信時に、再度 `player.PlayerData.job.name == Config.RequiredJob` を検証し、不正な報酬付与を防ぐ
- ジョブ名の変更は `config.lua` の次を編集（運営用コメント付き）:

```lua
Config.RequiredJob = 'police'
```

### 実装参照

**config.lua**

```lua
-- ジョブ制限（Qbox: job.name と一致するプレイヤーだけ受注・報告可）
Config.RequiredJob = 'police'
```

**client `ox_target` の `canInteract` 例（概念）**

- `GetPlayerData()` の `job.name` が `Config.RequiredJob` と一致するか判定

**server `completePatrol`**

- `GetPlayer` 取得後に `PlayerData.job.name` を `Config.RequiredJob` と照合。不一致の場合はセッション破棄・報酬なし（必要に応じてクライアントへ失敗を返却）

---

## 受付 NPC の足元（MLO 室内）

- `config.lua` の **`Config.JobPedZOffset`**（既定 **+0.1**）で、床に**沈まない**よう足元を上げる。**浮きすぎ**る場合は `0.05` ～ `0.0` に下げ、**沈む**場合は `0.1` ～ `0.2` に上げる。  
- 旧版の「高さネイティブに合わせて下げるだけ」の挙動は、署内 MLO では**誤検出**で足が潜るため廃止済み。

## 操作（クライアント表示）

- **巡回先**: 到達候補に近づくと**大きい青系の円**＋**内側の黄緑円**（E が効く範囲の目安）が**地面付近**に出ます。画面**左下**の **`~INPUT_CONTEXT~`（E）** 系ヘルプで案内。`NUI` を開いている（フォーカス中）ときはヘルプ非表示。  
- **受付 NPC（署前）**: 同様に**左下ヘルプ**＋**E** で受付／報告（`ox_target` も併用可）。

## 受注制御（サーバー）

- `lib.callback` `jp-koban:server:tryStartPatrol` でも、受注前に上記 `job.name` を再チェック
