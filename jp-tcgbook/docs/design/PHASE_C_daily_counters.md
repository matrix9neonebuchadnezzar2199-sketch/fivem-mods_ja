# PHASE C — JST 日次カウンタ（`tcg_daily_counters`）全体設計

**対象リソース**: `jp-tcgbook`  
**全体の入口**: **`docs/design/OVERALL_DESIGN.md`**（ロードマップ・他 PHASE との位置）。  
**前提**: PHASE 2c 済み（`BattleStats.RecordFinish` がリアル PvP normal 終了で呼ばれる）。PHASE 2d 済み（`BattleRewards.GrantOnFinish` が同一 `Finish` 内で **Stats の直後**に呼ばれる）。  
**文字コード**: UTF-8（BOM なし）

---

## 1. 目的・スコープ

### 1.1 目的

**リアル PvP** で **正常終了（`reason = normal`・引き分け含む）** した対局について、**カレンダー日（JST）単位**で以下を永続化する。

- **対戦回数**（1 プレイヤー 1 試合につき 1 カウント）
- **勝ち／負け／引き分け**（生涯 `tcg_players` の wins/losses/draws と整合する増分を **日次でも**持つ）
- **敗北コピー取得回数**（2d の `AddCardToPlayer` が **実際に成功した回数**）

用途の例: デイリークエスト、イベント「本日 N 勝」、運営集計、将来のランキング補助。**ミッドナイトの cron は使わない（レイジーリセット）**。

### 1.2 スコープ内

- テーブル **`tcg_daily_counters`** の新設と **`install.sql` への追記**
- `Database.*` の UPSERT 系関数（await SQL）
- `BattleStats._updateDailyCounter` の本実装（`battle_stats.lua`）
- **敗北コピー成功時**の `copies_received` 更新（`battle_rewards.lua` または `Database` から呼び出し）
- （任意）Wire ログ 1 行 `[jp-tcgbook][wire][stats] daily …`
- `config.lua` に **日本語コメント**（タイムゾーン方針・デバッグ用除外 citizenid など）

### 1.3 スコープ外（本 PHASE ではやらない）

- NUI に「今日の戦績」を出す（別タスク）
- デイリー報酬の自動付与（カウンタだけ先に置く）
- 週次・シーズンリセット（必要なら別テーブル／別 PHASE）
- **`tcg_players` 行不在時の EnsurePlayer**（§19 と同様、別パッチ）

---

## 2. 合意ポリシー（確定前提）

| ID | 内容 |
|----|------|
| **P1** | カウント対象は **リアル PvP** のみ。`ctx.is_real_pvp == true` かつ `RecordFinish` に入った試合と一致（solo / CPU は対象外）。 |
| **P2** | **日付キーは JST の暦日** `YYYY-MM-DD`。サーバー OS のタイムゾーンに依存せず、**UTC 時刻に +9 時間**して暦日を算出する（実装スニペットは §6）。 |
| **P3** | **レイジーリセット**: 0 時ジョブは不要。**その日初めて対象処理が走ったとき**に「当日キー」の行を INSERT または UPSERT する。過去日の行はそのまま残り履歴になる。 |
| **P4** | **引き分け**は `battles += 1`・**`draws += 1`**（両者）。勝敗がついた場合は勝者 `wins += 1`、敗者 `losses += 1`。 |
| **P5** | **`copies_received`**: PHASE 2d の **コピー付与が DB 上成功したときだけ** +1（付与スキップ・引き分け・solo は 0）。 |

### 2.1 `Finish` 内の呼び出し順（既存）

```
BattleStats.RecordFinish(ctx)   -- Elo / winloss / 【本 PHASE で daily 本体】
BattleRewards.GrantOnFinish(ctx) -- 2d コピー → 【本 PHASE で copies_received】
```

そのため **`battles` / `wins` / `losses` / `draws` は `RecordFinish` 内**、`copies_received` は **`GrantOnFinish` 内（成功時）** が責務分離として自然。

---

## 3. データモデル

### 3.1 テーブル `tcg_daily_counters`

| カラム | 型 | 説明 |
|--------|-----|------|
| `citizenid` | `VARCHAR(64)` | プレイヤー ID（`tcg_players` と同一キー） |
| `date_jst` | `CHAR(10)` | JST 暦日 `YYYY-MM-DD` |
| `battles` | `INT UNSIGNED` | その日のリアル PvP 対戦回数（1 試合 1） |
| `wins` | `INT UNSIGNED` | 同日の勝ち数 |
| `losses` | `INT UNSIGNED` | 同日の負け数 |
| `draws` | `INT UNSIGNED` | 同日の引き分け数 |
| `copies_received` | `INT UNSIGNED` | 同日に **敗北コピーが成功した回数** |
| `updated_at` | `TIMESTAMP` | 最終更新（任意・運用便利） |

**主キー**: `PRIMARY KEY (citizenid, date_jst)`

**インデックス**: PK で十分。将来「その日の TOP N」用に `INDEX idx_date_jst (date_jst)` を足してもよい（任意）。

**外部キー**: `tcg_players(citizenid)` への FK は **省略推奨**（ダミー検証用 citizenid や先行書き込みとの兼ね合いで運用が楽）。整合性はアプリ側で `GetPlayer` と同様に担保。

### 3.2 行の寿命

- 1 プレイヤー × 1 暦日 = **最大 1 行**。一日に複数試合する場合は **同一行を UPDATE で累積**。

---

## 4. SQL・UPSERT 方針

### 4.1 試合終了時（各プレイヤーごと）

入力: `citizenid`, `date_jst`（JST 文字列）, そのプレイヤーの **局所的 outcome**（`'win'|'lose'|'draw'`）

1 回の試合で **双方分** 実行する（p1 と p2 で別 outcome）。

**推奨 SQL（単一プレイヤー・1 試合分）**:

```sql
INSERT INTO tcg_daily_counters
  (citizenid, date_jst, battles, wins, losses, draws, copies_received)
VALUES (?, ?, 1, ?, ?, ?, 0)
ON DUPLICATE KEY UPDATE
  battles = battles + 1,
  wins = wins + VALUES(wins),
  losses = losses + VALUES(losses),
  draws = draws + VALUES(draws);
```

- `VALUES(wins)` などは MySQL の「挿入予定値」セマンティクス。MariaDB でも同一パターンで動作させる場合は INSERT 句のプレースホルダと整合させる。
- **引き分け**: `wins=0, losses=0, draws=1`
- **勝ち**: `wins=1, losses=0, draws=0`
- **負け**: `wins=0, losses=1, draws=0`

**注意**: `ON DUPLICATE KEY UPDATE` で `copies_received` を触らない（同日複数試合でゼロ初期化しない）。

### 4.2 敗北コピー成功時（敗者のみ）

```sql
INSERT INTO tcg_daily_counters
  (citizenid, date_jst, battles, wins, losses, draws, copies_received)
VALUES (?, ?, 0, 0, 0, 0, 1)
ON DUPLICATE KEY UPDATE
  copies_received = copies_received + 1;
```

- **同日にすでに試合行がある**場合は `copies_received` だけ増える。
- **異常系**: 理論上「コピーだけ先に成功して日次行が無い」ケースは、`RecordFinish` が先なので **通常は試合行が先**。防御的に上記 UPSERT で `battles=0` の行ができるが、実運用では Finish 直後にコピーが走るため **同日行は既に存在**する想定でよい。

---

## 5. 処理フロー

### 5.1 `BattleStats.RecordFinish`

既存ガードの後、`updateRating` / `updateWinLoss` と同様に **`updateDailyCounter(ctx)` を実装**:

1. `date_jst = JstDateString()`（§6）
2. `updateDailyCounterForPlayer(ctx.p1.citizenid, date_jst, ctx.outcome_for_p1)`
3. `updateDailyCounterForPlayer(ctx.p2.citizenid, date_jst, ctx.outcome_for_p2)`

### 5.2 `BattleRewards.GrantOnFinish`

`AddCardToPlayer` が **`success`** のときだけ:

1. `date_jst = JstDateString()`（§6・`Database` か `BattleStats` と共有ヘルパ）
2. `Database.IncrementDailyCopiesReceived(loser_citizenid, date_jst)`

### 5.3 dryrun（`battle_finish_dryrun.lua`）

**ダミー citizenid**（`jp-tcgbook-debug-peer-dummy`）も **本番と同じ経路**で日次が増える。検証用に **`Config.TcgDailyStatsExcludeCitizenIds`** のような **除外リスト**を設けるか、運用上「ダミー行は後から DELETE」でもよい → **設計として config で除外を任意実装**と記載する。

---

## 6. JST 暦日ヘルパ（Lua）

サーバー負荷・依存最小でよい場合:

```lua
--- UTC epoch → JST の YYYY-MM-DD（レイジーリセットのキー）
local function jstDateStringFromEpoch(epochSec)
    local t = os.date('!*t', math.floor(epochSec) + 9 * 3600)
    return ('%04d-%02d-%02d'):format(t.year, t.month, t.day)
end
```

- **試合終了時刻**は `ctx.finished_at` があればそれ、なければ `os.time()`。
- サマータイムなし（JST 固定）。

共有場所の候補: `shared/` に薄いモジュール、または `database.lua` 内 `local`（他から `Database.JstDateString()` を公開）。

---

## 7. `Database` API（案）

| 関数 | 役割 |
|------|------|
| `Database.IncrementDailyMatchCounters(citizenid, date_jst, outcome)` | §4.1 の UPSERT（outcome は win/lose/draw） |
| `Database.IncrementDailyCopiesReceived(citizenid, date_jst)` | §4.2 |

戻り値は既存慣例 `{ success = bool, error = string? }`。失敗時は Wire で 1 行（任意）。

---

## 8. Wire ログ（任意）

`TcgBattleWireLogEnabled()` のとき例:

```
[jp-tcgbook][wire][stats] daily date_jst=2026-05-02 p1=license:... b+1 w|l|d p2=jp-tcgbook-debug-peer-dummy b+1 ...
```

ログ過多なら **サマリ 1 行に両プレイヤー**に留める。

---

## 9. 受け入れ条件（検証）

1. **solo 完走**: `tcg_daily_counters` に **行が増えない**（`RecordFinish` が早期 return）。  
2. **dryrun lose**: 実プレイヤー行で **`battles`+=1, `losses`+=1**、ダミーで **`wins`+=1**。その後 **`copies_received`** が敗者行で +1（付与成功時）。  
3. **引き分け**（将来またはテスト用 ctx）: 両者 **`draws`+=1**、`wins`/`losses` は増えない。  
4. **日またぎ**: JST で日付が変わった後の最初の試合で **新しい `date_jst` の行**ができる（旧日行は残る）。  
5. **Wire OFF**: サーバーは静か、DB のみ更新。

---

## 10. 変更ファイル一覧（実装時）

| ファイル | 内容 |
|----------|------|
| `server/sql/install.sql` | `CREATE TABLE tcg_daily_counters` |
| `server/database.lua` | §7 API、`JstDateString`（公開または内部） |
| `server/battle_stats.lua` | `_updateDailyCounter` 本実装 |
| `server/battle_rewards.lua` | 付与成功時 `IncrementDailyCopiesReceived` |
| `config.lua` | タイムゾーン説明・除外 citizenid リスト（任意） |
| `fxmanifest.lua` | 変更なし（SQL は既存 install 経由） |

---

## 11. リスク・メモ

- **MySQL / MariaDB の `VALUES()` 非推奨警告**（8.0.20+）: 将来的に `ROW()` エイリアスへ移行する余地をコメントで残す。  
- **試合は RecordFinish 済み・コピーだけ失敗**: `battles` は増え **`copies_received` は増えない** — 仕様どおり。  
- **ランキングとの二重管理**: オールタイムは `tcg_players`、**「今日」** は本テーブル — 役割分担をドキュメント化済み。

---

## 12. 参照

- `docs/design/OVERALL_DESIGN.md` — 全体設計・実装順  
- `server/battle_stats.lua` — `updateDailyCounter` TODO  
- `docs/design/PHASE_2d_defeat_reward.md` — Finish 順序・コピー責務  
- `2026-05-02 開発日記.md` — PHASE C 着手メモ  
