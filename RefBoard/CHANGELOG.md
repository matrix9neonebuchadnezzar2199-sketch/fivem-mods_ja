# Changelog

## v0.6.3 — 2026-05-07

- **fix（重大）**: `editor_locks.holder_server_id` と `source` の型ずれ（数値／文字列）で `playerDropped` や acquire 判定が外れ、切断後もロックが残り「他プレイヤーが編集中」になる問題を修正（`lock.lua` は比較を `tonumber` 統一。タイムアウト時の `presence:setMode` / `notify` も数値 ID のみ送る）。
- **fix**: NUI を閉じる経路（F6・`refboard:close`）でクライアントから `refboard:lock:release` と `refboard:session:leave` を必ず送り、Web 側の `leave()` が届かない場合でもロック／プレゼンスが残らないようにした。
- **fix**: `MainLayout` の Close で `session.leave()` が例外でも `refboard:close` を続行し、マウス／キーボードフォーカスがゲームに戻るようにした。
- **feat**: ランチャーに「ゲーム画面に戻る（ツールを閉じる）」を追加（ログイン相当画面だけ開いているときの出口）。
- **chore**: サイドバー表記の UI 版を `REFBOARD_UI_VERSION` に統一。

## v0.6.2 — 2026-05-07

- **fix（重大）**: Lua が送る `refboard:setOpen` を NUI 側で購読し、**閉じている間は App シェルを描画しない**（`nuiShellOpenRef` + `App.vue` `v-if`）。ログイン・多キャラ画面を RefBoard の CEF が覆って操作不能になる問題を解消。
- **fix**: `onClientResourceStart` で **`setOpen(false)`** を必ず実行し、フォーカスとペイロードを起動直後に同期。
- **dev**: ブラウザ単体（`npm run dev`）では従来どおり常時 UI を表示（`isInFiveM()` が false のとき）。

## v0.6.1 — 2026-05-06

- **feat**: sprint_08 フェーズ3 マーキー全面展開（`TeamList` / `RosterList`、`DataManage` 試合履歴・統計表、`Settings` 見出し、`PresenceBadge`、`MatchList` に `MarqueeText`。試合一覧・データの試合履歴に **試合名**列、`match_list.col_match_name` 日英 i18n）。
- **feat**: `ScoreBoardCard` に **score-flash**（`rb-score-flash`、ゴール時スコア増分のみ 600ms、`prefers-reduced-motion` で無効）。スタイルは `web/src/styles/score-flash.css` を `main.ts` で import。
- **マーキー**: `marquee.css` の両端フェード `mask-image` を **`.rb-marquee.is-overflowing` のみ**に限定（短文時の先頭文字欠け対策）。`prefers-reduced-motion` 時は `-webkit-mask-image` も解除。
- **マーキー**: `.rb-marquee-plain` の `overflow: hidden` を削除し、親 `.rb-marquee` との二重クリップによる先頭欠けを解消。
- **開発支援**: DEV 専用 `window.__refboardToastPush` を `main.ts` に追加（フェーズ2b 目視・Toast 長文の手動発火用。`import.meta.env.DEV` のみ）。
- **sprint_08 フェーズ2b**: 6箇所にマーキー適用（`MainLayout` サイドバー5リンク `v-marquee` subtle、`Toast` 本文 ticker、`HelpView` 逆引き `item.title` subtle、`PlayerListCard` 見出し default＋選手名 subtle、`EventTimelineCard` 本文 default）。`table-fixed`＋`min-w-0` で表組みを圧縮。
- **sprint_08 設計書**: `docs/sprints/sprint_08_marquee.md` に複数行同時マーキー方針の確定文言と、フェーズ 2b 着手前の flex/grid レイアウトチェックリスト（`c172c9e` の教訓）を追記。
- **MatchList**: 試合ステータス列を `MatchStatusBadge`（日英 `match.status.*`・状態別色）に変更。
- **モック**: ブラウザ開発用 `nuiMock` に `localStorage` 永続化レイヤ（`mockPersistence.ts`）を追加。`team_create` ほか CRUD がリロード後も保持され、`window.__refboardMock`（DEV のみ）でリセット・ダンプ可能。
- **設計**: スコアボード方針（案 A）・`MarqueeText` の `variant` プリセット仕様を `docs/sprints/sprint_08_marquee.md` に確定記録。
- **マーキー基盤（フェーズ1）**: `MarqueeText.vue`（`contentRef` 計測・`VARIANTS` プリセット・`prefers-reduced-motion`）と `v-marquee` ディレクティブ（`createElement` / `textContent` で DOM 構築）。
- **`marquee.css`**: `rb-marquee` 共通スタイル、`data-marquee-mode`（`always` / `hover-only` / `off`）別の挙動、`@keyframes rb-marquee-scroll`。
- **設定**: `stores/settings.ts` に `marqueeMode`（永続化・`prefers-reduced-motion` 時は保存に `marqueeMode` が無い場合のみ初期 `off`）、`Settings.vue` ラジオ UI、日英 i18n。`App.vue` ルートに `:data-marquee-mode` と `provide('marqueeMode')`。
- **sprint_08 フェーズ2a**: `ScoreBoardCard.vue` のホーム・アウェイ正式名を `MarqueeText`（`variant="scoreboard"`）に置換。

## v0.6.0 — 2026-05-06（アプリ内ヘルプ Phase 1）

- **ヘルプ**: サイドバー「ヘルプ」から `HelpView`（`/workspace/help`、記事 `/workspace/help/article/:slug`、エラー `/workspace/help/error/:code`）。`reverse_index.json` による逆引き一覧、Markdown 記事を `marked` + `dompurify` で表示。
- **記事（日本語・4 本）**: `trouble_e1003_lock_held`、`trouble_undo_goal`、`trouble_connection_lost`、`trouble_autosave_failed`（`web/src/help/ja/articles/`）。
- **エラー → ヘルプ**: `errorCodeMapper.ts`（`error` キーと `code` の両方を `shared/error_codes.lua` に揃えて解決）。`Toast` に「解決方法を見る」（専用記事があるコードのみ `help-error` へ）。オートセーブ失敗トーストに `E4003` / `tx_failed` を付与。
- **i18n**: `help.*`、`sidebar.help`。
- **依存**: `marked`、`dompurify`、`@types/dompurify`。

**未完了（v0.6.x で継続）**: 記事 16 本、英語版記事、`Fuse.js` 検索、主要 4 画面のコンテキスト `?` パネル等は [docs/sprints/sprint_07.md](docs/sprints/sprint_07.md) の受け入れ基準に照らして残タスク。

## v0.5.1 — 2026-05-06 (Pre-test triage tooling)

- **観測可能性**: `shared/error_codes.lua`（`MakeError` / `ErrorCodes`）、`server/util.lua` の `Logger`（`Config.LogLevel`）と `RefboardGuard`（`xpcall` + スタックログ + 任意 ACK）。
- **SafeCall 相当**: 主要 NetEvent（スコア・イベント・試合 create/finish/reopen/set_half・選手 add / roster・ロック acquire/release・autosave・session enter）を `RefboardGuard` で保護。
- **NUI**: `useNui.ts` のリクエストトレース（`DEV` または `localStorage.refboard_trace=1`）、`Launcher.vue` のトレース有効化リンク、グローバル `error` / `unhandledrejection` でトースト。
- **ヘルスチェック**: `server/health.lua` + `refboard:health:check` / `:ack`、`HealthCheck.vue`、設定からの導線、`nuiMock` 対応。
- **型**: `web/src/types/error.ts`、`REFBOARD_UI_VERSION` 定数。`ja.json` / `en.json` に `errors.*` と `health.*` を追加。
- **ドキュメント**: `docs/sprints/sprint_06_pretriage.md`（前夜版スプリント指示の保存）。

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
