# M3 / M4 全般設計（対戦履歴 UI・PvP EXP／連勝）

**役割**: OVERALL の **M3（PHASE E2）**・**M4（PHASE E3）** を実装単位で一本化する。詳細要件の源流は `PHASE_E_ranking_season_ui.md` §6〜§8。  
**文字コード**: UTF-8（BOM なし）

---

## 1. スコープ

| マイルストーン | 内容 | 主な成果物 |
|----------------|------|------------|
| **M3** | 自分の対戦履歴一覧を BOOK に表示 | `Database.ListMatchHistoryForCitizenid`、`openBook` の `match_history[]`、NUI **対戦履歴**タブ |
| **M4** | リアル PvP **normal 完走**時の EXP・レベル・連勝・連勝ボーナス | `tcg_players.pvp_exp` / `pvp_level` / `pvp_win_streak`、`BattleStats.RecordFinish` 内更新、`config.lua` 曲線 |

**対象外（従来どおり）**: 投了・切断での **Elo／勝敗カウント／日次／履歴 INSERT／敗北コピー**（`Finish` 非経路）。

---

## 2. データ

### 2.1 `tcg_match_history`（既存・M2）

変更なし。一覧は `(citizenid_a = ? OR citizenid_b = ?) ORDER BY finished_at DESC LIMIT ?`。インデックス `idx_citizen_a_time` / `idx_citizen_b_time` を利用。

### 2.2 `tcg_players` 追加列（M4）

| 列 | 型 | 意味 |
|----|-----|------|
| `pvp_exp` | INT UNSIGNED | PvP 由来の累積 EXP（主に勝利で加算） |
| `pvp_level` | INT UNSIGNED | 表示用レベル（`pvp_exp` から算出し格納） |
| `pvp_win_streak` | INT UNSIGNED | 現在の連勝数（敗北・引き分けで 0） |

**マイグレーション**: 新規 `CREATE TABLE` に列を含める。既存 DB は起動時に `ALTER TABLE … ADD COLUMN` を試行し、重複列エラーは無視。

---

## 3. API・権限

- **履歴一覧**: **自分の `citizenid` のみ**。サーバーで正規化して NUI に渡す（相手視点・勝敗・レート・敗北コピー受取フラグ）。
- **`LIMIT`**: `Config.MatchHistoryLimitOpenBook`（既定）と `Config.MatchHistoryLimitMax`（ハード上限）。
- **第三者の履歴**: 出さない（将来の管理者 UI は別設計）。

---

## 4. 正規化行（NUI 向け）

各行に含める想定フィールド:

- `match_id`, `finished_at`, `reason`
- `opponent_display`, `opponent_citizenid`（BOOK はライセンス全文表示方針に合わせる）
- `outcome_me`: `win` | `lose` | `draw`
- `score_me`, `score_opp`
- `rating_me_before`, `rating_me_after`
- `defeat_copy_received`, `defeat_copy_card_id`（敗者かつ `defeat_copy_granted` 時のみ）

---

## 5. EXP・レベル・連勝（M4）

### 5.1 更新タイミング

`BattleStats.RecordFinish(ctx)` 内、`ctx.is_real_pvp == true` のとき **日次カウンタ更新の後**に実行。

### 5.2 連勝・EXP ルール（実装既定）

- **勝利**: `試合前連勝 s` を読み、`gain = PvpExpWinBase + min(s, PvpWinStreakBonusCap) * PvpExpPerStreakStep` を `pvp_exp` に加算。その後 `pvp_win_streak = s + 1`。
- **敗北・引き分け**: EXP 加算なし、`pvp_win_streak = 0`。
- **投了・切断・ロビー離脱**: `BattlePvp.OnPlayerLeave` で **離脱したプレイヤー**の `pvp_win_streak` のみ `0` に更新（レート等は触らない）。

### 5.3 レベル

`Config.PvpLevelExpThresholds`（累積 EXP の昇順・閾値は「その EXP 以上で次のレベル」）と任意の `Config.PvpExpPerLevelBeyondTable` で `pvp_level` を算出し UPDATE。

---

## 6. NUI

- タブ **📜 対戦履歴**（対戦とランキングの間）。
- `bookData` で `match_history` を受け取り、表またはリストで表示。データ無しはプレースホルダ。
- ヘッダー統計に **Lv・EXP・連勝** を追記（`player` 行の新列）。

---

## 7. 検証メモ

- **履歴**: リアル PvP normal 完走後、`openBook` で行が増えること。
- **EXP／連勝**: dryrun `tcg_debug_finish_hooks_dryrun`（`is_real_pvp=true`）で Wire ログまたは DB 列が変わること。
- **連勝リセット**: 対戦中に `battlePvpLeave` または切断で離脱側の `pvp_win_streak` が 0 になること。
