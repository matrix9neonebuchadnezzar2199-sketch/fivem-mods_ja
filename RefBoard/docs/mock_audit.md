# RefBoard ブラウザモック（`nuiMock.ts`）CRUD 調査

`npm run dev` 時の `queueMockSideEffects` / `mockResponse` を基準に整理。永続化は `mockPersistence.ts` の `localStorage`（キー `refboard:mock:state`、スキーマ `STORAGE_VERSION`）。

| エンドポイント | カテゴリ | 現状の動作（整備後） | 永続化要否 | 整備後の動作 |
|---|---|---|---|---|
| `team_create` | 作成系 | `mockDb.teams` に追加 → `flushPersistence` | 必要 | リロード後も一覧に表示 |
| `team_update` | 更新系 | `mockDb.teams` を id で更新 → `saveMockState` | 必要 | 同上 |
| `team_delete` | 削除系 | `deleted_at` 付与（論理削除） | 必要 | 一覧から除外、ストレージには残す |
| `team_manage_list` | 取得系 | `activeTeams()` 由来のペイロード | 不要 | ストレージ上の teams を参照 |
| `team_list` | 取得系 | `activeTeams()` を返す | 不要 | 同上 |
| `team_detail` | 取得系 | `mockDb.teams` から取得 | 不要 | 同上 |
| `team_roster_list` | 取得系 | `mockRosterByTeam` | 不要 | `flush` で `mockDb` と同期 |
| `team_roster_add` | 作成系 | `mockRosterByTeam` に追加 → `flush` | 必要 | リロード後もロスター表示 |
| `team_roster_update` | 更新系 | `mockRosterByTeam` 上の行を更新 | 必要 | 同上 |
| `team_roster_remove` | 削除系 | `mockRosterByTeam` から splice | 必要 | 同上 |
| `match_create` | 作成系 | `mockListRows` / `matchDetails` / `liveDetail` 更新 → `flush` | 必要 | 試合一覧・詳細が復元 |
| `match_finish` | 更新系 | 一覧行と `liveDetail.dbStatus` | 必要 | `finished` が保持 |
| `match_reopen` | 更新系 | 一覧行 `draft`、スナップの `dbStatus` | 必要 | 再編集状態が保持 |
| `match_get` | 取得系 | `matchDetails`＋履歴を返す | 不要 | `scoreHistory` を match_id でフィルタ |
| `match_list` | 取得系 | `mockListRows` | 不要 | 永続化済みリストを読む |
| `match_set_half` | 更新系 | `liveDetail`＋一覧の `current_half` | 必要 | `flush` |
| `match_checkResume` | 取得系 | `mockDb.matchDrafts` のキー有無 | 判定 | ドラフトがあれば `hasResume` |
| `player_add` | 作成系 | `liveDetail` の選手配列 | 必要 | `matchDetails` に保存 |
| `player_add_from_roster` | 作成系 | ロスター行をコピーして追加 | 必要 | 同上 |
| `player_resolve` | 取得系 | 固定／簡易 not_found | 不要 | 変更なし |
| `player_online_list` | 取得系 | 固定リスト | 不要 | メモリのみで可 |
| `score_goal` | 作成系 | スコア・イベント・`scoreHistory` | 必要 | リロード後もスコア・履歴 |
| `score_manual_edit` | 作成系 | スコア・`scoreHistory` | 必要 | 同上 |
| `event_substitute` | 作成系 | `liveDetail` 選手状態・イベント | 必要 | 同上 |
| `event_issue_card` | 作成系 | 同上 | 必要 | 同上 |
| `event_record_penalty` | 作成系 | PK イベント・内訳 | 必要 | 同上 |
| `autosave_draft` | 作成系 | `mockDb.matchDrafts[mid]` | 必要 | `match_checkResume` と連動 |
| `data_team_stats` | 取得系 | アクティブチームのダミー統計 | 不要 | 本番は DB 集計 |
| `data_player_stats` | 取得系 | 固定行 | 不要 | 同上 |
| `data_score_edit_log` | 取得系 | `mockDb.scoreHistory` | 不要 | 永続化済みを表示 |
| `data_match_history` | 取得系 | `mockListRows` フィルタ | 不要 | 同上 |
| `data_db_meta` | 取得系 | 固定バージョン文字列 | 不要 | 同上 |
| `lock_acquire` / `lock_release` / `lock_heartbeat` | 状態系 | 即時 ACK | **不要** | リロードで解放（実機に近い） |
| `presence_list` / `presence_focus` | 取得／状態 | 固定または no-op | **不要** | メモリ想定 |
| `session_enter` / `session_leave` | 状態系 | パスワード検証は `session_enter` のみ | **不要** | 既存ロジック維持 |
| `health_check` | 取得系 | 静的 ACK | 不要 | 変更なし |

## 分類メモ（優先度）

- **A**: チーム／試合／選手／スコア／イベント／ドラフト（上表「必要」かつフェーズ 2b の足場）。
- **B**: `match_finish` / `match_reopen` / `match_set_half`（試合ライフサイクル）。
- **C**: ロック・プレゼンス・セッション・オンライン選手一覧（揮発でよい）。

## 実装上の注意（2026-05-06 時点）

- ロスターは編集用バッファ `mockRosterByTeam` に集約し、`flushPersistence` で `mockDb.rosterByTeam` に書き戻す。`mockDb` のみ直接 mutate すると次の `flush` で上書きされるため非推奨。
- `score_goal` / `score_manual_edit` は `syncMockListRowScoresFromLive()` を **`flushPersistence` より前**に呼ぶ（一覧の得点と詳細の整合）。
