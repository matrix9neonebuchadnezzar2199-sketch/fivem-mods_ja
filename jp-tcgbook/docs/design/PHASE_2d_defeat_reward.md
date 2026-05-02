# PHASE 2d — 敗北時カードコピー付与（全体設計）

**対象リソース**: `jp-tcgbook`  
**前提**: PHASE 2c 済み（`BattlePvp.Finish` → `BattleStats.RecordFinish` → `BattleRewards.GrantOnFinish` → `destroySession` の順が確立済み）  
**文字コード**: UTF-8（BOM なし）

---

## 1. 目的・スコープ

### 1.1 目的

**リアル PvP** で **正常終了（盤面 9 マス埋め・`reason = normal`）** した対局において、**敗者**に **勝者がその対局で使用した初期手札 5 枚のうち 1 枚**と同等のカードを **所持として 1 枚付与**する。敗北の挽回感・カード循環の入口とする。

### 1.2 スコープ内

- サーバー権威での付与のみ（`Database.AddCardToPlayer`）
- `BattleRewards.GrantOnFinish(ctx)` の本実装
- セッション開始時の **`initial_hands` スナップショット**（ε3）
- `collectFinishContext` への **報酬用フィールド**追加（`GrantOnFinish` が `PvpBattles` に再アクセスしない）

### 1.3 NUI（終了オーバーレイ）— 実装済み

**PvP 対戦アリーナ**の終了パネル（`battle.js` `buildDbgResultOverlayHtml`）に、**敗者かつ `GrantOnFinish` が成功したときのみ**「敗北コピー入手: （カード名）」を表示する。

**サーバー**: `BattlePvp.Finish` は **`GrantOnFinish` 確定後**に `jp-tcgbook:client:battlePvpEnded` を送る。`buildNormalEndedPayload` に以下を載せる（敗者のクライアントにのみ意味がある）。

| フィールド | 型 | 説明 |
|------------|-----|------|
| `defeat_copy_received` | boolean | この viewer が敗北コピーを **実際に付与された**場合のみ `true` |
| `defeat_copy_card_id` | string? | 付与された `card_id`（`received==true` のとき） |
| `defeat_copy_card_name` | string? | マスタ参照の表示名（なければ `card_id` にフォールバック） |
| `is_real_pvp` | boolean | リアル PvP / ソロ検証フルフック経路なら `true`。`false` のとき NUI は「カード付与・敗北コピーなし」と注記 |

勝者・引き分け・付与失敗時は `defeat_copy_received === false`（または関連キー省略と同等の扱い）。**勝利時のカード入手 UI は仕様外**（敗北コピーのみ）。リアル PvP で勝った場合も同様。

### 1.4 スコープ外（本 PHASE ではやらない）

- NUI トースト・軽量ポップアップ（オーバーレイ以外の別演出）
- ランキング・実績バッジ
- **C2**（UR/SS をランクダウンして付与）— **運用観測後の調整候補**として config で差し替え可能な余地だけ設計メモに残す
- `tcg_players` 行不在時の EnsurePlayer 自動挿入（§19 TODO。必要になったら別パッチ）

---

## 2. 合意ポリシー（確定）

| ID | 内容 |
|----|------|
| **A1** | 付与は **敗者のみ**。**引き分け**（`outcome_for_p1 == 'draw'`）では **双方とも付与なし**。 |
| **B2** | コピー元は **勝者の「対戦開始時の手札 5 枚」**（初期スナップショット）。勝者デッキ 10 枚からランダムではない。 |
| **C1** | **マスター定義どおりの `card_id` を付与**（`tcg_player_cards` は `card_id` のみ保持。見た目のランクはマスタ参照で一致）。初期運用は **インフレ対策なし**。問題が出たら **C2**（付与前にランク正規化テーブルで別 `card_id` にマップ）を検討。 |
| **D1** | **同一 `card_id` の所持枚数上限なし**（現行スキーマ・運用に合わせる）。 |

### 2.1 経路による自動除外

- **疑似 PvP solo / `is_solo`**: `ctx.is_real_pvp == false` → `GrantOnFinish` は即 return（Stats と同様）。
- **投了・切断**: `BattlePvp.OnPlayerLeave` 経由のみ終了 → **`Finish` を呼ばない** → 本報酬は発動しない（意図どおり）。
- **`Finish` が呼ばれるのは現状 `reason = 'normal'` のみ**だが、防御的に `ctx.reason ~= 'normal'` なら付与しないことを推奨。

---

## 3. 設計上の論点と決定（ε3）

### 3.1 なぜ盤面から「勝者が置いたマス」だけを集めないか

`shared/battle_rule.lua` のセルは `{ owner, card }` のみ。**奪取後は `owner` が変わる**ため、「最初に勝者が置いたカード」の復元には **`placed_by` のような別フィールド**または **配置ログ**が必要。  
**ε3（開始時スナップショット）** は `PlaceAndResolve` / `commitPlace` を変更せず、**`BattlePvp.Start` / `StartSolo` の初期化 1 箇所**で済むため採用する。

### 3.2 `session.hands` のキー

**プレイヤーの server id（数値）**。`'p1'` / `'p2'` 文字列ではない。

```lua
session.hands[p1_src], session.hands[p2_src]
```

`initial_hands` も **同一キー**で保存する。

### 3.3 スナップショットの深さ

初期手札の各要素は `normalizeCardFromMaster` 由来の **フラットなテーブル**（`card_id`, `stat_*`, …）。実行中に同一テーブルを破壊的に書き換えない前提なら **要素ごとの shallow copy で十分**なことが多いが、将来の改変に備え **`card_id` を報酬用に必ず複製**するか、**スナップショット時に各カードを `pairs` で 1 段コピー**しておくと安全。

---

## 4. データモデル

### 4.1 セッション拡張（メモリのみ）

| フィールド | 型 | 説明 |
|------------|-----|------|
| `session.initial_hands` | `table<number, table[]>` | キーは `p1_src` / `p2_src`。値は **対戦開始直後**の手札配列（各要素はカードテーブルのコピー）。 |

**設定タイミング**: `BattlePvp.Start` および `BattlePvp.StartSolo` で、`session.hands` を代入した **直後**に、`session.initial_hands[src] = copyHand(session.hands[src])` を両プレイヤー分実行。

### 4.2 Finish コンテキスト拡張（`collectFinishContext` 戻り値）

既存フィールドに加え、例:

| フィールド | 型 | 説明 |
|------------|-----|------|
| `winner_reward_pool` | `table[]` \| `nil` | **勝者**の初期手札 5 枚のコピー列（カードテーブルの配列）。引き分け時は `nil` または空。 |
| （任意）`loser_citizenid` | `string` \| `nil` | 計算済みでもよいが、`p1`/`p2` と `outcome_*` から `GrantOnFinish` 内で十分導けるため必須ではない。 |

**方針**: `GrantOnFinish` は **`ctx` のみ**参照し、`PvpBattles[session_id]` に依存しない（`destroySession` 前後に依存しない）。

---

## 5. 処理フロー

### 5.1 全体（変更なし）

```
BattlePvp.Finish
  → pay 組み立て
  → collectFinishContext(session, reason)   ← initial_hands から winner_reward_pool を詰める
  → battlePvpEnded × 2
  → BattleStats.RecordFinish(ctx)
  → BattleRewards.GrantOnFinish(ctx)      ← 本 PHASE で本実装
  → destroySession
  → ロビー解除・Wire
```

### 5.2 `GrantOnFinish` 内部（論理）

1. `ctx == nil` → return  
2. `ctx.is_real_pvp ~= true` → return  
3. `ctx.reason ~= 'normal'` → return（防御）  
4. `ctx.outcome_for_p1 == 'draw'` → Wire「draw skip」して return（A1）  
5. 勝者・敗者を `outcome_for_p1` / `p1` / `p2` から決定  
6. `loser.citizenid` が無い → Wire して return  
7. `winner_reward_pool` が空または nil → Wire して return  
8. `picked = pool[math.random(1, #pool)]`、`card_id = picked.card_id`  
9. `Database.AddCardToPlayer(loser_citizenid, card_id)` — 戻り値 `success` を Wire に記録  

### 5.3 Stats と Rewards の順序

現状 **Stats → Rewards**。  
- Elo 更新とコピー付与は独立。  
- 一方だけ DB 失敗する可能性はある → **それぞれ Wire で success を見る**。トランザクション統合は本 PHASE では不要。

---

## 6. DB・API

### 6.1 使用関数

**`Database.AddCardToPlayer(citizenid, card_id)`**

- 実装済み: `INSERT INTO tcg_player_cards (citizenid, card_id) VALUES (?, ?)`  
- 戻り値: `{ success = boolean, error? }`

### 6.2 行が無い場合

- `tcg_players` に敗者行が無いと、外部キーや運用によっては失敗しうる。**現状スキーマを確認**し、FK が無ければ INSERT は成功しうるが、運営フローでは **openBook 時にプレイヤー初期化**がある前提。問題が出たら §19 の EnsurePlayer 強化へ。

### 6.3 C2 への拗張余地（設計のみ）

```text
local grant_id = Config.DefeatRewardRankMap[picked.rank] or picked.card_id
Database.AddCardToPlayer(loser_citizenid, grant_id)
```

`Config.DefeatRewardRankMap` は将来追加。PHASE 2d では未定義でよい。

---

## 7. Wire ログ（提案）

`TcgBattleWireLogEnabled()` のときのみ:

| 状況 | メッセージ例 |
|------|----------------|
| draw | `[jp-tcgbook][wire][rewards] skip draw session=...` |
| 非リアル PvP | （ログ省略可。Stats と揃えて省略でもよい） |
| citizenid 欠落 | `[jp-tcgbook][wire][rewards] skip no loser citizenid session=...` |
| pool 空 | `[jp-tcgbook][wire][rewards] skip empty winner_reward_pool session=...` |
| 付与結果 | `[jp-tcgbook][wire][rewards] grant loser=<cid> card_id=<id> ok=<bool> session=...` |

---

## 8. 変更ファイル一覧（実装時）

| ファイル | 変更内容 |
|----------|-----------|
| `server/battle_pvp.lua` | `copyInitialHandsSnapshot` 的なローカル関数、`Start` / `StartSolo` で `initial_hands` 設定、`collectFinishContext` で `winner_reward_pool` 算出 |
| `server/battle_rewards.lua` | `GrantOnFinish` 本実装 |
| `config.lua` | （任意）PHASE 2d の一行説明・将来 C2 用のプレースホルダコメント |
| `docs/verify/` | （任意）リアル PvP 1 局での付与確認ログ |

`fxmanifest.lua` の追加読み込みは不要（既に `battle_rewards.lua` が読み込まれている前提）。

---

## 9. 受け入れ条件（検証）

1. **solo 完走**: `GrantOnFinish` が発動しない（または即 return）。既存の Stats skip と整合。  
2. **リアル PvP 引き分け**: 理論上レアだが発生時、**付与なし**・ログで確認可能。  
3. **リアル PvP 勝敗あり**: 敗者の `tcg_player_cards` に **1 行追加**、`card_id` が勝者の初期 5 枚のいずれか。  
4. **投了で終了**: `Finish` 非経由のため **付与なし**。  
5. **Wire OFF**: サーバーは静か、付与自体は設定どおり実行（ログ要件は開発時のみ）。

---

## 10. リスク・メモ

- **マスタに存在しない card_id** がスナップショットに混入した場合（バグ時）: `AddCardToPlayer` は通るがコレクション表示で不整合の可能性 → 付与前に `masterRow(card_id)` の存在チェックを入れるかは実装時に判断。  
- **乱数**: サーバー標準 `math.random`。FiveM 上でソロ AI と共用されているため、**セキュリティ上の「暗号論的」である必要は低い**（どのカードが選ばれるかの公平性レベル）。

---

## 11. 単一クライアント検証（finish フック dryrun）

仮想ロビーは **自分自身を相手にできない**ため、**疑似通信対戦で完走**は単一クライアントでは踏めない。  
検証は **`tcg_debug_finish_hooks_dryrun`**（`server/battle_finish_dryrun.lua`）で `BattleStats.RecordFinish` と `BattleRewards.GrantOnFinish` を **実プレイヤー + DB 固定ダミー `jp-tcgbook-debug-peer-dummy`** のコンテキストで実行する（フック直叩き）。

- tx コンソール例: `tcg_debug_finish_hooks_dryrun lose 5`（src=5 が敗北→敗者コピーは自分）、`tcg_debug_finish_hooks_dryrun win 5`（勝利→コピーはダミー行）。
- 前提: `Config.DebugCommands`、マスタにカードが存在すること。

---

## 12. 参照

- `2026-05-02 開発日記.md` — PHASE 2c 検証・次タスク・ランキング検討メモ  
- `2026-05-01 開発日記.md` §19 — 引継ぎ・`tcg_players` TODO  
- `server/database.lua` — `AddCardToPlayer`  
- `shared/battle_rule.lua` — 盤セル構造（`placed_by` なし）
