# 1人開発方針・疑似PvPソロの本番同等検証

**文字コード**: UTF-8（BOM なし）

---

## 1. 開発コンテキスト（運用方針・記録）

- **jp-tcgbook は基本 1人で開発する**。2クライアント常設やペア検証が前提になりにくい。
- そのため **「疑似PvPソロ」（`battlePvpStartSolo` / `BattlePvp.StartSolo`）は、開発時には本番と同じサーバー経路で検証できることが望ましい** とする。
  - 対象: **`BattleStats.RecordFinish`**（Elo・勝敗・日次・**PvP EXP／連勝**）
  - **`BattleRewards.GrantOnFinish`**（敗北コピー等）
  - **`Database.InsertMatchHistory`**（対戦履歴）
- **CPU対戦**（`battle_debug`・フリー／練習モード）は従来どおり **ランキング経済・履歴の対象外** でよい。

※現状コード（未パッチ）では `collectFinishContext` が **`is_real_pvp = (session.is_solo ~= true)`** のため、ソロは上記フックがすべてスキップされる。**本ファイルは「あるべき仕様」とパッチ方針を定義する。**

---

## 2. 現状とギャップ

| 項目 | CPU対戦（デバッグ） | 疑似PvPソロ（現状） | 目標（本ドキュメント） |
|------|---------------------|----------------------|-------------------------|
| 状態機械 | `battle_debug` | `BattlePvp`（仮想 `p2`） | そのまま利用 |
| `is_real_pvp` | false 相当（別経路） | **false**（スキップ） | フラグ ON 時 **true** |
| 履歴・EXP・報酬 | 対象外 | 対象外 | **本番と同一経路** |

---

## 3. 設計原則

### 3.1 本番安全性（必須）

- **本番サーバーでは絶対に「ソロ＝本番経路」を有効にしない。**
- 有効化は **二重ガード** とする（例）:
  1. `Config.DebugCommands == true`（デバッグビルド想定）
  2. **`Config.PvpSoloApplyFullFinishHooks == true`**（明示オプトイン・既定 `false`）

欠ければ従来どおり `is_real_pvp=false`（現状互換）。

### 3.2 仮想相手の `citizenid`

- `InsertMatchHistory` / `RecordFinish` は **2人分の `citizenid`** が必要。
- 仮想席（`VIRTUAL_SRC`）には UID が無いため、**検証専用の固定ダミー行**を `tcg_players` に用意する。
- **`tcg_debug_finish_hooks_dryrun`** が既に使っている **`jp-tcgbook-debug-peer-dummy`** と **同一文字列を共通化**する（DB 上は 1 プレイヤー・履歴の相手列も一貫）。
- 設定キー例: `Config.PvpSoloVerificationDummyCitizenid`（省略時は上記デフォルト）。
- **ソロ検証モードでマッチ開始時**（`BattlePvp.StartSolo` 内）、ダミー行が無ければ **`Database.CreatePlayer`** で作成（dryrun の `ensureDummyPeer` と同等ロジックを **共用関数化**推奨）。

### 3.3 `collectFinishContext` の振る舞い

- 条件: `session.is_solo == true` かつ **§3.1 の二重ガード成立**
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

## 4. パッチ実装チェックリスト（実装時）

1. **`config.lua`**  
   - `PvpSoloApplyFullFinishHooks`（既定 `false`）  
   - `PvpSoloVerificationDummyCitizenid`（既定 `jp-tcgbook-debug-peer-dummy`）  
   - いずれも **日本語コメント**で「本番禁止・DebugCommands と併用」の旨を記載。

2. **`server/database.lua` または共用モジュール**  
   - `EnsureVerificationDummyPeer(citizenid)` を **dryrun と共用**（重複コード削除）。

3. **`server/battle_pvp.lua`**  
   - `StartSolo`: ガード成立時のみ **`EnsureVerificationDummyPeer`** 呼び出し。  
   - `collectFinishContext`: §3.3 のとおり `is_real_pvp` と `p2.citizenid`（または仮想側）を設定。  
   - `Finish`: `display_name_b` のフォールバック（§3.4）。  
   - Wire ログ 1 行（例: `[wire] solo verification: applying full finish hooks`）を任意で追加。

4. **`server/battle_finish_dryrun.lua`**  
   - ダミー ID を **config 参照**に寄せ、文字列の二重定義をやめる。

5. **NUI（`html/index.html` / `history.css` まわり）**  
   - 「ソロは記録されない」固定文は、**検証フラグ ON のときは誤解を招く**ため、  
     - **config をクライアントへ渡す**（`openBook` の `ui` ブロックに `solo_finish_hooks: bool`）か、  
     - または運営向けに「開発サーバーでは設定により記録される」を本文に追記。  
   - 実装時は **文言をデータ駆動**にすると安全。

6. **ドキュメント**  
   - `OVERALL_DESIGN.md` のドキュメントマップに本ファイルを載せる。  
   - 開発日記に「1人開発・ソロ本番経路検証」の方針と本ファイルへのリンクを残す。

7. **検証手順**  
   - `DebugCommands=true`・`PvpSoloApplyFullFinishHooks=true` でソロ完走 → TX に **`skip non-real-pvp` が出ない**こと、`[match_history] insert ok`・`pvp_progress`・BOOK 履歴に行が出ること。

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
