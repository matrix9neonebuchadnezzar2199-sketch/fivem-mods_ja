# 1人開発方針・疑似PvPソロの本番同等検証

**文字コード**: UTF-8（BOM なし）

---

## 1. 開発コンテキスト（運用方針・記録）

- **jp-tcgbook は基本 1人で開発する**。2クライアント常設やペア検証が前提になりにくい。
- そのため **「疑似PvPソロ」は、開発時に本番と同じ Finish サーバー経路で動かす**（`battlePvpStartSolo` / `BattlePvp.StartSolo`）。
  - 対象: **`BattleStats.RecordFinish`**（Elo・勝敗・日次・**PvP EXP／連勝**）
  - **`BattleRewards.GrantOnFinish`**（敗北コピー等）
  - **`Database.InsertMatchHistory`**（対戦履歴）
- **CPU対戦**（`battle_debug`・フリー／練習モード）は従来どおり **ランキング経済・履歴の対象外** でよい。

**実装**: **`Config.DebugCommands == true` のときのみ** `StartSolo` が成功する。その場合、`collectFinishContext` でダミー `citizenid` を差し込み **常に `is_real_pvp = true`**（`server/battle_pvp.lua`）。本ファイルは設計根拠・運用注意の記録として残す。

---

## 2. 現状とギャップ

| 項目 | CPU対戦（デバッグ） | 疑似PvPソロ（`DebugCommands=true` で開始可） |
|------|---------------------|-----------------------------------------------|
| 状態機械 | `battle_debug` | `BattlePvp`（仮想 `p2`） |
| `is_real_pvp` | false 相当（別経路） | **true**（ダミー citizenid） |
| 履歴・EXP・報酬 | 対象外 | **本番 Finish と同一経路** |
| 備考 | — | `DebugCommands=false` の環境では **StartSolo 不可**（本番で経済混入を防ぐ） |

---

## 3. 設計原則

### 3.1 本番安全性（必須）

- **本番サーバーでは `Config.DebugCommands=false`** とし、**疑似PvPソロ（`StartSolo`）を開始できなくする**（`BattlePvp.StartSolo` 先頭で拒否）。これにより **ソロ経由の Finish 経済は開発構成に閉じる**。
- リアル 2 人 PvP は `DebugCommands` と無関係に従来どおり動作する。

### 3.2 仮想相手の `citizenid`

- `InsertMatchHistory` / `RecordFinish` は **2人分の `citizenid`** が必要。
- 仮想席（`VIRTUAL_SRC`）には UID が無いため、**検証専用の固定ダミー行**を `tcg_players` に用意する。
- **`tcg_debug_finish_hooks_dryrun`** が既に使っている **`jp-tcgbook-debug-peer-dummy`** と **同一文字列を共通化**する（DB 上は 1 プレイヤー・履歴の相手列も一貫）。
- 設定キー例: `Config.PvpSoloVerificationDummyCitizenid`（省略時は上記デフォルト）。
- **ソロ検証モードでマッチ開始時**（`BattlePvp.StartSolo` 内）、ダミー行が無ければ **`Database.CreatePlayer`** で作成（dryrun の `ensureDummyPeer` と同等ロジックを **共用関数化**推奨）。

### 3.3 `collectFinishContext` の振る舞い

- 条件: `session.is_solo == true` かつ **`Config.DebugCommands == true`**（ソロ開始時と同一）
- 処理:
  - **`is_real_pvp = true`**（本番 Finish パイプラインに載せる）
  - 人間側は従来どおり `GetPlayerUid(human_src)`
  - 仮想側は **`citizenid = Config.PvpSoloVerificationDummyCitizenid`**（人間が常に `p1`・仮想が `p2` の現行 `StartSolo` なら `p2.citizenid` を差し替え）

### 3.4 履歴行の表示名

- `Finish` 内 `InsertMatchHistory` で `GetPlayerName(p2)` が取れないため **`display_name_b` が空**になりうる。
- 対策: **ソロ検証モードかつ仮想相手列**のとき、固定ラベル例: **`仮想対戦相手（検証）`** を入れる（運営・プレイヤー向けに「実在プレイヤーではない」と分かるように）。

### 3.5 履歴・集計の意味論

- DB の `tcg_match_history.is_real_pvp` は INSERT 時既に `true` となる実装が既存。**フラグ追加は必須ではない**。
- 運用上、`match_id` が `pvp_solo_*` の行は **開発検証でソロ由来**と判別可能。将来、ランキング集計から除外したければ **クエリ側で `match_id` LIKE 除外**または任意列追加（別 PHASE）。

### 3.6 離脱・連勝

- `OnPlayerLeave` での連勝リセットは **`session.is_solo ~= true` のときのみ**の現状を維持してよい（ソロ中断でダミー連勝をいじる必要性は低い）。必要なら後続で「人間側のみリセット」を検討。

---

## 4. 実装チェックリスト（完了確認・再検証用）

1. **`config.lua`** — `PvpSoloVerificationDummyCitizenid`・`DebugCommands` の説明（本番では false）。
2. **`Database.EnsureVerificationDummyPeer`** — `database.lua`、dryrun から利用。
3. **`battle_pvp.lua`** — `StartSolo` でダミー確保、`collectFinishContext` で `is_real_pvp` / ダミー `citizenid`、`Finish` で表示名フォールバック・Wire ログ。
4. **`battle_finish_dryrun.lua`** — ダミー ID を config 共用。
5. **NUI** — `openBook` の `ui.pvp_solo_finish_hooks`（`DebugCommands` と連動）と `app.js` の `syncHistoryTabUi`。
6. **検証** — `DebugCommands=true` でソロ完走 → **`skip non-real-pvp` が出ない**、`[match_history] insert ok`、履歴タブ・ヘッダの更新。

---

## 5. 関連ファイル（現状）

- `server/battle_pvp.lua` — `collectFinishContext`、`Finish`、`StartSolo`
- `server/battle_stats.lua` — `RecordFinish`
- `server/battle_rewards.lua` — `GrantOnFinish`
- `server/database.lua` — `InsertMatchHistory`
- `server/battle_finish_dryrun.lua` — ダミー peer 確立の参考実装
- `config.lua` — ガード・dummy citizenid

---

## 6. 明示的にやらないこと（スコープ外）

- 本番でソロをランキング対象にするかどうかの **プロダクト決定**（本ドキュメントは **開発検証用**）。  
- CPU デバッグ戦を履歴に載せる（必要なら別設計）。
