# Changelog

## v0.5.0 — 2026-05-06

- **チーム管理**: `TeamManage.vue`、ロスター API（`team_roster` / `server/team.lua`）、`AddPlayerDialog` に「ロスターから選ぶ」モード。
- **データ管理**: `DataManage.vue`（試合履歴・チーム統計・選手統計・編集ログ）、`server/data.lua` 集計、`CSV` エクスポート（`utils/exporters.ts`、BOM 付き）。
- **設定**: `Settings.vue`、`stores/settings.ts`（`localStorage`）、サイドバーから遷移。
- **PK 決着**: `server/event.lua` の `evaluatePenaltyShootout`、`refboard:event:pk_decided`、`PenaltyShootoutPanel.vue` で勝者表示→試合終了確認。
- **UX**: `onClickOutside`（イベントメニュー・スコアボード）、キーボードショートカット、`Toast`、`main.ts` の `errorHandler`、ヒーロー表示/カード不透明度の設定連動。
- **DB**: `sql/migration_004_team_roster.sql` / `install.sql`（`team_roster`、`teams.emblem_emoji`）。
- **ドキュメント**: `docs/screenshots/`（01〜10 プレースホルダ）、`docs/USER_GUIDE.md` / `docs/USER_GUIDE.en.md`、`docs/sprints/sprint_05.md`、`README` 更新。

## v0.4.0 — 2026-05-05

- **ハーフ別スコア内訳**: `Match.getScoreBreakdown` 集計を `refboard:match:get` / `refboard:match:state` の `breakdown` で配信。`MatchStatusCard` で前半・後半・延長（`et` 時）・PK（`pk` 時）を表示。
- **選手交代**: `SubstitutionDialog.vue`、`refboard:event:substitute` / `Event.substitute`（トランザクション）。タイムライン・選手一覧の表示更新。
- **カード**: `CardIssueDialog.vue`、`refboard:event:issue_card`（黄 / 赤、2 枚目黄は確認のうえ赤扱い）。`PlayerListCard` の状態表示拡充。
- **PK 戦**: `MatchStatusCard` から `current_half=pk` へ遷移（確認ダイアログ・先攻選択）、`PenaltyShootoutPanel.vue`、`refboard:event:record_penalty`（`penalty_success`、内訳 `pk` のみ加算）。
- **編集フォーカス**: `useFocusTracker`（1 秒デバウンス）、`refboard:presence:focus`、`presence.editorFocus` と各カードの「編集中」バッジ連動。
- **DB**: `sql/migration_003_sprint4.sql` / `install.sql` 更新（`pk_first_team_id`、`ejected_*`、`penalty_success` 等）。トランザクション検証手順 `docs/testing/transaction_test.md`、テストコマンド `refboard_test_transaction`（`Config.EnableTestCommands`）。
- **NUI モック**: 交代・カード・PK・`match_set_half`・`breakdown` を `nuiMock.ts` で再現。
- **ドキュメント**: `docs/sprints/sprint_04.md`。

## v0.3.0 — 2026-05-05

- **NUI 開発モック**: `useNui.ts`（`import.meta.env.DEV` かつ FiveM 外で `mocks/nuiMock.ts` 分岐）、ロック ACK などを `postMessage` で再現。
- **試合データ**: `refboard:match:get` 本実装、`mapMatchFromServer.ts` で UI モデルへマップ。`refboard:match:state` ブロードキャスト（スコア・イベント・選手・履歴）。
- **ゴール記録**: `GoalRecordWizard.vue` / `PlayerSelectGrid.vue`、`refboard:score:goal` + `server/score.lua` トランザクション（`match_events` + `match_score_history` + `matches` 更新）。
- **選手追加**: `AddPlayerDialog.vue`、`refboard:player:resolve` / `player:add` / `player:online_list`、`server/player.lua`（重複ライセンスは `force` で続行可）。
- **スコア手動編集**: `ScoreEditDialog.vue`（理由5文字以上）、`ScoreHistoryDialog.vue`、`refboard:score:manual_edit`。
- **試合終了・再編集**: `Match.finish` / `Match.reopen`、`refboard:match:finish` / `finished` / `reopen`、一覧の `[再編集]`。`sql/migration_002_match_reopen.sql` + `install.sql` に `reopened_*` / `position` / `yellow_cards`。
- **ドキュメント**: `docs/sprints/sprint_03.md`。

## v0.2.0 — 2026-05-05

- **Match UI**: `MatchDetail.vue` フルモック（ヒーロー・上段3カラム・下段65/35・静的「編集中」バッジ）、`MatchList.vue`、`CreateMatchDialog.vue`。
- **試合 CRUD（MVP）**: `refboard:match:create` / `refboard:match:list`、`server/match.lua` / `team.lua` 実装。
- **編集ロック**: `server/lock.lua`（`editor_locks` + ハートビートタイムアウト + `refboard:lock:acquire:result`）、NUI `session.enterEdit` 配線、`Launcher` ロック失敗ダイアログ。
- **オートセーブ**: `refboard:autosave:draft` → `match_drafts` デバウンス → `refboard:autosave:saved`、`stores/autosave.ts`、`AutosaveIndicator.vue`。
- **ルーター**: `/workspace` シェル + 子ルート `matches` / `matches/:id`。
- **SQL**: `sql/seed_dev_teams.sql`（開発用チーム2件）。
- **ドキュメント**: `docs/sprints/sprint_02.md`。

## v0.1.1 — 2026-05-05

- **プレゼンス（A 案）**: ツール接続人数の表示。`server/presence.lua`、`refboard:presence:list` / `refboard:presence:update`、NUI `PresenceBadge` / `UserAvatar` / `stores/presence`。
- **設計書**: `docs/04_design_mockup.md` 追加、`01`〜`03` にプレゼンス・試合メタ・UI モック追記。
- **DB**: `matches` に `match_name` / `venue` / `kickoff_time`（新規 `install.sql`、既存向け `sql/migration_001_match_meta.sql`）。

## v0.1.0 — 2026-05-05

- Initial scaffolding: `sql/install.sql`, `fxmanifest.lua`, `config.lua`, docs (`01_database`, `02_server`, `03_frontend`), logo SVG.
- Server: `refboard:*` net events stub + `editor_locks` reset on resource start.
- Client: `/refboard` + key mapping, NUI open/close, NUI callbacks forwarding to server.
- Web: Vue 3 + Vite + TypeScript + Tailwind + Pinia + Vue Router + vue-i18n minimal shell (`Launcher`, `MainLayout`).
