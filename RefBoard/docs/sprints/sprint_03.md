# Sprint 3 — v0.3.0（試合管理の実機動作）

## ゴール

「実際に試合を1試合分、最後まで管理できる」状態。ゴール記録・選手追加・スコア手動編集・試合終了／再編集・NUI 開発モック。

## 実装タスク対応

| タスク | 内容 |
|--------|------|
| 3-5 | `composables/useNui.ts` + `mocks/nuiMock.ts`（主要コールバックのモックと遅延 `postMessage`） |
| 3-2 | `AddPlayerDialog.vue`、`server/player.lua`（resolve / add / online_list） |
| 3-1 | `GoalRecordWizard.vue`、`PlayerSelectGrid.vue`、`server/score.lua` `recordGoal` |
| 3-3 | `ScoreEditDialog.vue`、`ScoreHistoryDialog.vue`、`score:manual_edit` |
| 3-4 | `Match.finish` / `Match.reopen`、`migration_002_match_reopen.sql`、`MatchList` 再編集 |
| 3-1 連携 | `refboard:match:state` に `history` を含め一覧系を同期 |

## DB

- 新規: `install.sql` に `matches.reopened_*`、`match_players.position`、`match_players.yellow_cards` を含む。
- 既存: `sql/migration_002_match_reopen.sql` を手動実行。

## 受け入れ（チェックリスト）

1. `npm run dev` でゴールウィザード完走（モック）
2. FiveM 二台でゴール → 閲覧側 `match:state` でスコア更新
3. サーバーID入力 / オンライン一覧から選手追加
4. 手動スコア編集（理由5文字以上）→ 履歴ダイアログ表示
5. 試合終了 → 一覧で再編集 → `draft` に戻る
6. `match_score_history` が追記のみで増える
7. `npm run build` 成功
