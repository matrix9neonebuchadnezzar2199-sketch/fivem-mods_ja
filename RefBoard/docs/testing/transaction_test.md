# RefBoard — トランザクション・整合性テスト

`Config.EnableTestCommands = true` にするとサーバーコンソールから `refboard_test_transaction` で MySQL 疎通のみ確認できます。本番では `false` のままにしてください。

## 手動テスト: ゴール記録の整合性

1. 試合を作成し、編集ロックで `MatchDetail` を開く。
2. ゴール記録ウィザードで1点記録する。
3. DB で以下を確認する:
   - `matches.team1_score` または `team2_score` が期待どおり +1。
   - `match_events` に `event_type='goal'` の行が追加されている。
   - `match_score_history` に `action='goal'` の行があり、`related_event_id` が上記 `match_events.id` と一致する。
4. 3行の `created_at` が極めて近い（同一トランザクションからのコミット）こと。

## 手動テスト: ロールバック（開発時のみ）

1. `server/score.lua` の `Score.recordGoal` トランザクション内、`match_score_history` の INSERT の直前に一時的に `error('test_rollback')` を挿入する。
2. ゴール記録を試す → クライアントは `ok=false` 相当。
3. DB で `matches` のスコア・`match_events`・`match_score_history` が増えていないことを確認する。
4. 挿入した `error` を必ず削除する。

## 並行・デッドロック

- 編集ロックにより通常は同一試合に対する並行ゴールは起きない。
- 負荷テストが必要な場合は、ステージングで複数試合IDに対し同時 INSERT を流し、MySQL のデッドロックログを監視する。
