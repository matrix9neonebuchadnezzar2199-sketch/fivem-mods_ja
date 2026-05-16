# INSTRUCTION-014.1 ルートアイテム可視化不具合修正

**発行日**: 2026-05-15  
**種別**: バグフィックス（INSTRUCTION-014 / INSTRUCTION-021 派生）  
**ステータス**: 実装済み（正本の方針追記は `docs/FORMAL_POLICIES.md` §INSTRUCTION-014.1）

## 1. 目的

ミッション中にルートの黄色ブリップ・地面サークル・ox_target / [E] 取得が成立しない不具合を修正する。

## 2. ルート原因

`CreateObject(..., isNetwork=true)` 直後に `NetworkGetNetworkIdFromEntity` を呼び、net object 未確定で `netId=0` → `lootSpawnAck` の `props` が空 → `lootRegister` が空配列 → UI 系が一切載らない。加えて `TransferIn` 直後の即時 `Loot.Spawn` はリーダーが遷移・コリジョン待ち中に batch が届き得る。

## 3. 実装サマリ（コード）

| ファイル | 内容 |
|----------|------|
| `client/loot.lua` | `lootSpawnBatch`: `NetworkRegisterEntityAsNetworked`（未 network のみ）→ 最大 2s で `NetworkGetEntityIsNetworked` 待機 → netId 取得。`SetNetworkIdCanMigrate(false)`。netId=0 時は `DeleteEntity`。`FreezeEntityPosition`。`Config.Debug` で受信・生成・ack 送信ログ。`lootRegister` 受信ログ。 |
| `server/session.lua` | `TransferIn` 末尾: `Loot.Spawn` を `CreateThread` + `Wait(5000)` 後、`state == 'IN_MISSION'` のときのみ実行。 |
| `server/loot.lua` | `lootSpawnAck` 冒頭と `lootRegister` 一斉送信直前に `Config.Debug` のみ `print`。 |
| `docs/FORMAL_POLICIES.md` | INSTRUCTION-014.1 表形式サマリ + ネットワークエンティティ生成規約本文。 |

## 4. 完了判定（実機）

1. `Config.Debug = true` で F8 に `loot prop created: lootId=... netId=N`（N>0）が複数。
2. F8 に `NETWORK_GET_NETWORK_ID_FROM_ENTITY: no net object` が出ない。
3. サーバーに `lootSpawnAck received: count>0` / `lootRegister broadcast: entries>0`。
4. リーダー・非リーダー双方でミニマップにスプライト 408・色 5 のブリップ。
5. 150m 以内で黄色サークルマーカー、ox_target または [E] で取得可能。

## 5. 注意

- `SetNetworkIdCanMigrate(false)` によりリーダー切断時の prop 寿命は別途（INSTRUCTION-015 以降で再評価可）。
- `Wait(5000)` は再発時 8 秒延長を検討。
