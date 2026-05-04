# Bridge API リファレンス（v1.0.0 スナップショット）

> **ファイル**: `docs/BRIDGE_API.md`  
> **対象バージョン**: jp-UnderworldBounty v1.0.0（2026-05-04 時点のコード観察）  
> **目的**: Bridge 層の現行 API を実装観察ベースで記録し、将来の差分追跡の基盤とする  
> **関連**: `docs/DESIGN.md` §6、`bridge/_init.lua`、`bridge/sv_bridge.lua`、`bridge/cl_bridge.lua`  
> **最終更新**: 2026-05-04（PHASE 1a フォローアップ反映）  

## 1. 本書の目的とスコープ

本書は jp-UnderworldBounty が現時点で提供している **フレームワーク抽象化 API** を、ソースコードから読み取った事実として記録したスナップショットである。仕様提案や理想設計ではなく、**現実装の挙動・シグネチャ・呼び出し関係**を正とする。

スコープは次のとおり。

- **含む**: `bridge/_init.lua` による `Framework` 決定、`bridge/sv_bridge.lua` の `Bridge.*`、`bridge/cl_bridge.lua` の `ClientBridge.*`、本リソース内からの呼び出し元。
- **含まない**: ESX / QBCore / Qbox の公式ドキュメント全文、`bridge/` 外での FW 直叩き（本リソース方針では禁止だが、第三者フォークは対象外）。

コード変更は PHASE 1a では行っていない（観察のみ）。

---

## 2. Bridge 層の概要

ESX・QBCore・Qbox（検出時は `qbcore` / `qbox` の別名だが実装パスは共通）は API が異なるため、`bridge/` で差を吸収する。サーバー側はグローバル **`Bridge`** テーブルにメソッドを生やし、`server/*.lua` からのみ利用する（方針としてクライアントから FW を直接呼ばない）。

クライアント側は **`ClientBridge`** テーブル（現状は `Notify` のみ）で通知を統一する。サーバー側の `Bridge` とは **名前空間が分離**されている。

ファイル構成は **`bridge/_init.lua`（共有・FW 検出）** + **`bridge/sv_bridge.lua`（サーバー）** + **`bridge/cl_bridge.lua`（クライアント）** の 3 ファイル。`fxmanifest.lua` では共有スクリプトの末尾で `_init.lua` を読み込んだ後、サーバーは `sv_bridge.lua`、クライアントは `cl_bridge.lua` を読み込む。

---

## 3. 初期化とフレームワーク検出

### 3.1 グローバル `Framework`

`bridge/_init.lua` で共有コンテキストに **`Framework`**（文字列）が設定される。

```lua
--- 要約（全文は bridge/_init.lua 参照）
Framework = 'standalone'
local mode = (Config and Config.Framework) or 'auto'
if mode == 'auto' then
  Framework = detect_auto() -- es_extended / qbx_core / qb-core の started を順に見る
else
  Framework = mode
end
```

- **`Config.Framework`**: `'auto'` | `'esx'` | `'qbcore'` | `'qbox'` | `'standalone'`（`config/config.lua`）。
- **`auto` 時の検出順**: `es_extended` → `qbx_core` → `qb-core` → 該当なしなら `standalone`。

### 3.2 `Bridge` / `ClientBridge` の初期化

- **`Bridge`**: `bridge/sv_bridge.lua` 先頭で `Bridge = Bridge or {}`。**`_init.lua` は `Bridge` を生成しない**。
- **`ClientBridge`**: `bridge/cl_bridge.lua` で `ClientBridge = ClientBridge or {}`。
- サーバー・クライアントとも **`Framework` は共有スクリプトにより既に設定済み**であることを前提に分岐する。

### 3.3 未検出・スタンドアロン時

`Framework == 'standalone'` のとき、金銭・インベントリ系は多くが **no-op 成功（`true`）または常時 true** を返す設計（詳細は各 API の項）。

---

## 4. サーバーサイド API（`bridge/sv_bridge.lua`）

内部ヘルパー（公開 API ではない）:

- **`ensure_esx()`**: `exports['es_extended']:getSharedObject()` を `pcall` で取得しキャッシュ。
- **`ensure_qb()`**: リソース名 **`qb-core`** の Export（`exports['qb-core']:GetCoreObject()`）を `pcall` で取得しキャッシュする。`exports['qbx_core']` 等は **本ファイルでは呼ばない**。
- **`qb_like_player(src)`**: 取得した `QBCore.Functions.GetPlayer(src)` を返す。`Framework == 'qbcore'` と `Framework == 'qbox'` の両方で同一経路。

**コード観察に基づく Qbox 依存の整理（grep: `bridge/` にて `qb-core` が `sv_bridge.lua`、`qbx_core` が `_init.lua` の検出のみ）**:

- **パターン**: `qb-core` のみを実行時依存として参照（パターン A に相当）。`_init.lua` の `auto` 検出では `qbx_core` リソースの started を見て `Framework = 'qbox'` とすることがあるが、`ensure_qb()` は依然として `qb-core` Export に依存する。
- **純粋 Qbox（`qb-core` リソース不在）**: コード上は **`GetCoreObject` が解決できないと QB/Qbox 分岐が機能しない**。互換レイヤーが別リソース名で提供される場合は本リソースからは断定できない。

> **要実機確認（v1.1）**: 運営環境で `qb-core` が無くとも `qbx_core` 等が同一 Export を提供しているか。提供されない場合は Bridge の QB/Qbox 経路は動作しない可能性がある。

---

### Bridge.GetPlayerData

**シグネチャ**: `Bridge.GetPlayerData(source: number) -> table | nil`

**説明**: プレイヤー情報のサブセットを返す。FW によりフィールド意味が異なる。

**引数**:

- `source` (number): サーバー側プレイヤー ID。

**戻り値**: 常にテーブル（Standalone 含む）または ESX/QB でプレイヤー不存在時 **`nil`**。

返却テーブル（観察上の共通キー）:

| キー | 型 | 備考 |
|------|-----|------|
| `name` | string | 表示名 |
| `money` | number | ESX: `getMoney()`、QB: **cash のみ**。銀行・ブラックは別フィールドでは渡していない |
| `job` | string | ジョブ名（小文字化は呼び出し側） |
| `identifier` | string | ESX: `identifier`、QB: `citizenid`、Standalone: `'standalone:' .. source` |

**フレームワーク別実装**:

| FW | 内部呼び出し | 備考 |
|----|----------------|------|
| ESX | `ESX.GetPlayerFromId(source)` | `getName` / `getMoney` / `job.name` |
| QBCore / Qbox | `core.Functions.GetPlayer(source)` | `PlayerData.charinfo` から姓名結合、`money.cash` |
| Standalone | なし | `GetPlayerName`、`money=0`、`job='civilian'` |

**呼び出し元**: `server/main.lua`（`/ub_test`）

**副作用**: なし（読み取り）。

**定義**: `bridge/sv_bridge.lua` 42〜78 行付近。

---

### Bridge.AddMoney

**シグネチャ**: `Bridge.AddMoney(source: number, typ: string, amount: number) -> boolean`

**説明**: 口座タイプに応じて金額を加算。`amount <= 0` は **no-op で `true`**。

**引数**:

- `typ`: `'cash'` | `'bank'` | `'black'` | `'black_money'`（ESX は `black_money` アカウント）。  
- QB 側は **`bank` 以外はすべて `cash` として `AddMoney`**。

**戻り値**: 成功 `true`、プレイヤー不存在等で `false`（ESX/QB）。Standalone は **`true`**。

**フレームワーク別実装**:

| FW | 内部呼び出し | 備考 |
|----|----------------|------|
| ESX | `xPlayer.addAccountMoney(account, amount)` | money / bank / black_money |
| QBCore / Qbox | `Player.Functions.AddMoney(mtyp, amount)` | `mtyp` は `bank` か `cash` のみ → **`black` は cash に丸められる** |
| Standalone | なし | 常に `true` |

**呼び出し元**: `server/rewards.lua`（`UbGrantRewards` 内 `pcall`）

**副作用**: 経済データ更新。

**定義**: `bridge/sv_bridge.lua` 84〜113 行付近。

---

### Bridge.RemoveMoney

**シグネチャ**: `Bridge.RemoveMoney(source: number, typ: string, amount: number) -> boolean`

**説明**: `AddMoney` と対になる減算。`amount <= 0` は no-op `true`。QB の口座マッピングは Add と同様（`black` → cash）。

**呼び出し元**: （grep 結果）本リポジトリの `server/*.lua` からは **未使用**。

**定義**: `bridge/sv_bridge.lua` 116〜145 行付近。

---

### Bridge.HasItem

**シグネチャ**: `Bridge.HasItem(source: number, item: string, count: number) -> boolean`

**説明**: アイテム所持数が `count` 以上か。`count` は最低 1 に丸め。

**戻り値**: ESX/QB で不足・不存在時 `false`。Standalone は **`true`**（インベントリ無しとみなさない）。

**フレームワーク別実装**:

| FW | 内部呼び出し |
|----|----------------|
| ESX | `getInventoryItem(item).count` |
| QBCore / Qbox | `GetItemByName`、`amount` または `count` |
| Standalone | 常に `true` |

**呼び出し元**: `server/heist.lua`（必須アイテムチェック）

**定義**: `bridge/sv_bridge.lua` 148〜167 行付近。

---

### Bridge.AddItem

**シグネチャ**: `Bridge.AddItem(source: number, item: string, count: number) -> boolean`

**説明**: アイテム付与。`count` は最低 1。

**戻り値契約（`bridge/sv_bridge.lua` の分岐のみ観察）**:

| 分岐 | `return` の有無 | `Bridge.AddItem` が返す値 |
|------|----------------|---------------------------|
| ESX | あり | 常に **`true`**（`addInventoryItem` 後に固定） |
| QBCore / Qbox | あり | **`Player.Functions.AddItem(item, count)` の戻り値をそのまま返す**（中間変数での正規化なし） |
| Standalone | あり | 常に **`true`** |

**非対称**: ESX / Standalone は常に boolean の `true`。QB/Qbox 分岐のみ FW 関数の戻り値がそのまま伝播する。

> **要実機確認（v1.1）**: `Player.Functions.AddItem` の戻り値の型・意味（boolean / table / nil 等）はフレームワーク実装依存のため、コードだけでは契約を確定できない。`server/rewards.lua` は `pcall` のみで戻り値は検証していない。

**呼び出し元**: `server/rewards.lua`

**定義**: `bridge/sv_bridge.lua` 170〜188 行付近。

---

### Bridge.RemoveItem

**シグネチャ**: `Bridge.RemoveItem(source: number, item: string, count: number) -> boolean`

**説明**: アイテム削除。QB は `Functions.RemoveItem` の戻り値をそのまま返す。

**呼び出し元**: （grep）本リポジトリ内 **未使用**。

**定義**: `bridge/sv_bridge.lua` 191〜209 行付近。

---

### Bridge.GetJob

**シグネチャ**: `Bridge.GetJob(source: number) -> string`

**説明**: `Bridge.GetPlayerData` の `job` を返す。データ無しは **`'unemployed'`**。

**呼び出し元**: `server/heist.lua`（職業・警官数判定に間接利用）、`Bridge.GetCopCount` 内部。

**定義**: `bridge/sv_bridge.lua` 212〜215 行付近。

---

### Bridge.GetCopCount

**シグネチャ**: `Bridge.GetCopCount() -> integer`

**説明**: オンラインプレイヤー全体を走査し、`Bridge.GetJob(src):lower()` が `Config.PoliceJobs` に含まれる人数を数える。

**副作用**: なし（読み取り）。`Config` 依存。

**呼び出し元**: `server/main.lua`、`server/heist.lua`

**定義**: `bridge/sv_bridge.lua` 218〜228 行付近。

---

### Bridge.Notify

**シグネチャ**: `Bridge.Notify(source: number, message: string, typ: string | nil)`

**説明**: プレイヤーへ通知。`typ` 省略時 `'info'`。

**FW 別**:

| FW | 動作 |
|----|------|
| ESX | `TriggerClientEvent('esx:showNotification', source, message)` — **typ は ESX 側に渡っていない** |
| QBCore / Qbox | `TriggerClientEvent('QBCore:Notify', source, message, mapped)`、`error` のみ `'error'`、それ以外 `'primary'` |
| Standalone | `TriggerClientEvent(UbEvent('client:standaloneNotify'), source, message, typ)` |

**呼び出し元**: `server/main.lua`、`server/heist.lua`（複数箇所）

**副作用**: クライアントイベント発火。

**定義**: `bridge/sv_bridge.lua` 232〜244 行付近。

---

## 5. クライアントサイド API（`bridge/cl_bridge.lua`）

### ClientBridge.Notify

**シグネチャ**: `ClientBridge.Notify(message: string, typ: string | nil)`

**説明**: ローカル通知。`Framework` 共有値で分岐。

| FW | 動作 |
|----|------|
| ESX | `TriggerEvent('esx:showNotification', message)` |
| QBCore / Qbox | `TriggerEvent('QBCore:Notify', message, mapped)`（サーバー側 Notify と同様の mapped） |
| Standalone | `BeginTextCommandThefeedPost` / `EndTextCommandThefeedPostTicker`（ネイティブフィード） |

**呼び出し元**: `client/notifications.lua` の `UbNotify`（同一ファイルの `client:standaloneNotify` でも使用）

**定義**: `bridge/cl_bridge.lua` 5〜19 行付近。

---

## 6. 共有・境界の整理（`_init.lua` とロード順）

| 項目 | 内容 |
|------|------|
| 共有 | `Framework` グローバル、`Config`（`shared_scripts` で先行ロード） |
| サーバー専用 | `Bridge.*`（`sv_bridge.lua`） |
| クライアント専用 | `ClientBridge.*`（`cl_bridge.lua`） |
| `UbEvent` | `Bridge.Notify` の Standalone 経路で使用（`shared/constants.lua` で定義） |

---

## 7. フレームワーク対応マトリクス

凡例: ○ 実装あり　△ 制限・スタブ　× 未使用または常時成功で実質スタブ

| API | ESX | QBCore | Qbox | Standalone |
|-----|-----|--------|------|------------|
| Bridge.GetPlayerData | ○ | ○ | ○（QB 経由） | △ |
| Bridge.AddMoney | ○ | ○（cash/bank のみ） | ○（同上） | △（常に true） |
| Bridge.RemoveMoney | ○ | ○（同上） | ○（同上） | △ |
| Bridge.HasItem | ○ | ○ | ○ | △（常に true） |
| Bridge.AddItem | ○ | ○ | ○ | △（常に true） |
| Bridge.RemoveItem | ○ | ○ | ○ | △（常に true） |
| Bridge.GetJob | ○ | ○ | ○ | △ |
| Bridge.GetCopCount | ○ | ○ | ○ | △（職業は civilian 基準） |
| Bridge.Notify | ○ | ○ | ○ | ○ |
| ClientBridge.Notify | ○ | ○ | ○ | ○ |

---

## 8. 呼び出し元マップ

| ファイル | 使用している API |
|----------|------------------|
| `server/main.lua` | `GetPlayerData`, `Notify`, `GetCopCount` |
| `server/heist.lua` | `Notify`, `GetJob`, `GetCopCount`, `HasItem` |
| `server/rewards.lua` | `AddMoney`, `AddItem` |
| `client/notifications.lua` | `ClientBridge.Notify`（`UbNotify` 経由） |

`server/bounty.lua` 等は **`Bridge` 未使用**（grep 確認）。

---

## 9. 改善候補（v1.1 検討対象）

> 各候補の優先度・対応方針・工数評価は `docs/BRIDGE_API_IMPROVEMENTS.md` を参照。

実装は変更しない。観察に基づく候補のみ。

### 9.1 命名・名前空間

- サーバー `Bridge` とクライアント `ClientBridge` でプレフィックスが異なり、対応関係が一目で分かりにくい。

### 9.2 FW 間の非対称

- `AddMoney` / `RemoveMoney` で QB の `black` が **cash 扱い**になる。
- `GetPlayerData.money` が **現金のみ**で、銀行・ブラックを統一モデルで返していない。
- Qbox 検出後も実行時は `qb-core` Export 依存（`ensure_qb()`）。純粋 Qbox 構成では **要実機確認**（`docs/BRIDGE_API.md` 内部ヘルパー節参照）。

### 9.3 ドキュメント・契約

- `Bridge.Notify` の `typ` が ESX でクライアントに伝わらない。
- `AddItem` / `RemoveItem` の QB 戻り値の契約が不明瞭。

### 9.4 v1.1 再評価対象（保留扱い）

- `Bridge.RemoveMoney` / `Bridge.RemoveItem` は v1.0.0 時点で `server/*.lua` から未参照だが、想定用途（罰金、賄賂、没収等）のため **v1.1 で再評価予定**。それまで実装を維持する。削除予定ではない。
- 関数定義直前に保留コメントを追加済み（`bridge/sv_bridge.lua`）。

---

## 10. 関連ドキュメント

| ドキュメント | 内容 |
|--------------|------|
| `docs/DESIGN.md` §6 | Bridge の設計意図 |
| `docs/INSTRUCTIONS_PHASE_1A.md` | 本スナップショット作成手順 |
| `docs/CONFIG_GUIDE.md` | `Config.Framework`、`Config.PoliceJobs` |
| `docs/SEQUENCE_DIAGRAMS.md` | Standalone 通知イベント |

---

## 11. 改訂履歴

| 日付 | バージョン | 変更内容 |
|------|------------|----------|
| 2026-05-04 | v1.0.1 | PHASE 1a フォローアップ: Qbox 依存・`AddItem` 戻り値をコード観察ベースで整理、「要実機確認」明示。§9.4 を保留扱いに変更 |
| 2026-05-04 | v1.0.0 | 初版。v1.0.0 コードの観察スナップショット |
