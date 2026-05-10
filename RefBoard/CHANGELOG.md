# Changelog

## v0.6.0 — 2026-05-10

- **A（M-1 fetch タイムアウト）**: `useNui.ts::postToLua` に `AbortController` で 5 秒タイムアウトを追加。タイムアウト時は `{ ok: false, error: 'timeout' }`、その他のエラーは `{ ok: false, error: 'fetch_failed' }` を返す。CEF 応答停止時に UI が固まる潜在リスクを解消。
- **B（M-6 PK 連打耐性）**: `PenaltyShootoutPanel.vue` の確認系関数 3 つ（`confirmUndoLast` / `confirmReroll` / `confirmCancelAll`）に `isProcessing` フラグを追加して二重 emit を防止。`record()` は `pid` リセット → `if (!pid) return` の既存ガードで足りるため変更なし。
- **C（H-2 clearAllData 整合性）**: `seedActions.ts` で:
  - `NON_PREFIXED_KEYS = ['refboard_settings', 'refboard-locale']` を定数化（今後ノンプレフィックスキーを追加する際の登録先）。
  - `clearAllData()` 末尾で `rehydrateStoresAfterLocalStorageMutation()` を呼び、Pinia と localStorage の整合を保証。
  - `resetIdCounters()` の代わりに既存の `resetCountersMemoryOnly()` を使用し、`clearAllLocal` 直後の不要なディスク書き戻しを回避。
- **D（M-9 README 文言）**: 「v0.4.0 の注意」を「データ管理機能について（v0.4.0 以降）」へ見出し変更し、過去形・現状の挙動を明確化（ja/en 両方）。
- **E（F-1' スクリーンショット）**: `intro_setup` 記事（ja/en）に画面 4 枚（ランチャー／チーム管理／試合一覧／試合詳細）を挿入。`web/public/help/intro_setup/01〜04-*.png` に配置し、相対パス `./help/intro_setup/...` で参照。`sanitizeHelpHtml.ts` の `ALLOWED_TAGS` に `img`、`ALLOWED_ATTR` に `src` / `alt` / `width` / `height` / `loading` / `decoding` を追加（`script` / `iframe` / `on*` などは引き続き禁止）。
- **テスト**: `cancelPenaltyShootout` の void 後 events 配列残存を追加、`clearAllData` の rehydrate と id_counters クリーンアップ（最小 localStorage モック）、`resetIdCounters` / `resetCountersMemoryOnly` のセマンティクス比較を追加。**51 → 55 件**。
- **HANDOVER**: §3 ディレクトリ・§5 主要機構・§6 テスト件数・§7 TODO（F-3/F-5/F-7 を追記、解消済みを除去）・§9 ロードマップ・§10 セッションフレーズ・§11 改版履歴を v0.6.0 ベースに更新。
- **バージョン同期**: `package.json` / `package-lock.json` / `fxmanifest.lua` / `REFBOARD_UI_VERSION` を **0.6.0** へ。

## v0.5.2 — 2026-05-10（緊急バグ修正）

- **🚨 重要バグ修正（H）**: 0 名 vs 0 名で PK 戦に入ると脱出不能になる問題を修正。データロストの可能性があるため緊急パッチとしてリリース。
- **入口バリデーション**: PK 戦への移行時、両チーム 1 名以上の選手登録を必須化。`MatchStatusCard.onSelectChange` で `homePlayers.length === 0 || awayPlayers.length === 0` の場合は新規 emit `pk-validation-failed` を発火し、`MatchDetail` でトースト警告（`toast.pk_no_players`）。
- **PK 全体キャンセル**: `PenaltyShootoutPanel` 右下に「PK 戦をキャンセル」ボタンを追加。確認ダイアログで PK イベント件数を表示し、確定で `cancelPenaltyShootout` を実行。新規ストア関数 `cancelPenaltyShootout(matchId)` は PK イベント全件 void、`homePkScore`/`awayPkScore` を 0、`pkFirstTeamId` を null、`currentHalf` を `'2H'` に戻す（atomic）。
- **i18n**: ja/en に `toast.pk_no_players`, `toast.pk_cancelled`, `penalty.cancel_all`, `penalty.cancel_all_title`, `penalty.cancel_all_body` を追加。
- **テスト**: `cancelPenaltyShootout` の正常系（全件 void・状態リセット）と存在しない試合 ID の拒否を追加。**49 → 51 件**。
- **ヘルプ記事**: `match_penalty_shootout.md`（ja/en）に「開始前の注意（最低 1 名以上）」と「PK 戦をキャンセルする」セクションを追記。
- **バージョン同期**: `package.json` / `package-lock.json` / `fxmanifest.lua` / `REFBOARD_UI_VERSION` を **0.5.2** へ。

## v0.5.1 — 2026‑05‑10

- **L-5 PK 先攻チーム選択 UI**: `Match.pkFirstTeamId` を型定義に追加し、`createMatch` で `null` 初期化、`setPkFirstTeam(matchId, teamId)` 関数を追加（PK イベント 1 件以上で拒否）。`matchToDetailModel` で `?? homeTeamId` の fallback を実装。`MatchStatusCard` の既存 PK 移行ダイアログから先攻 ID を `setHalf` payload で受け取り、`MatchDetail.onSetHalf` で `setPkFirstTeam` を呼ぶ。
- **PK リカバリ機能**: `PenaltyShootoutPanel` 下部に「↶ 直前のキックを取消」ボタン（PK イベント 1 件以上で有効、確認ダイアログあり）と「先攻を再抽選」ボタン（PK イベント 0 件 + 先攻設定済みのときのみ表示）を追加。それぞれ `pk-undo-last` / `pk-reroll-first` イベントで親に伝達。
- **シードデータ更新**: PK 進行中試合・PK デモ試合に `pkFirstTeamId: home.id` を明示。
- **i18n**: `penalty.undo_last`, `penalty.undo_confirm_title`, `penalty.undo_confirm_body`, `penalty.reroll_first_team`, `penalty.reroll_first_team_title`, `penalty.reroll_first_team_body` を ja/en に追加。
- **テスト**: `setPkFirstTeam` の正常系・拒否系（PK イベント存在時、不正チーム ID）、`matchToDetailModel` の `pkFirstTeamId` fallback を追加。**43 → 49 件**。
- **ヘルプ記事**: `match_penalty_shootout.md`（ja/en）に先攻選択・直前取消・再抽選の説明を追記。
- **バージョン同期**: `package.json` / `package-lock.json` / `fxmanifest.lua` / `REFBOARD_UI_VERSION` を **0.5.1** へ。

## v0.5.0 — 2026‑05‑10

- **ヘルプ（F-3）**: `npm run check:help` — `scripts/check-help-articles.mjs` で `index.json`／`reverse_index.json`／`articles/*.md`／`context_map.json` の整合と ja/en スラッグ対称、各記事フロントマター（`title`・`category` 必須）を検証。
- **ヘルプ（F-2）**: 試合一覧・チーム管理・設定の「?」を **`HelpHoverDialog`（中央モーダル）** に統一。旧右スライドの `ContextHelpPanel`／`HelpTriggerButton`／`contextHelp` ストアを削除。`context_map.json` に **`match_list`** を追加し、**`settings`** の関連記事を拡充。
- **UX（F-4）**: イベント時刻の **`formatMinute`** で `stoppage === 0` を **`M'` のみ**に統一（試合開始直後の **`0+0'`** 表記を解消）。`EventTimelineCard`／`CompactEventList` で **ロスタイム分（`+N'`）を amber で強調**（`EventMinuteColumn.vue`）。`MinuteInput` の表示も `+0` を省略。
- **修正（H-3 整合性）**: `addEvent` で `goal` / `pk_goal` / `pk_miss` の `teamId` がホーム・アウェイ以外または欠落のとき**イベントを追加せず `null` を返す**。呼び出し側でトースト通知（`toast.event_invalid_team`）。
- **修正（H-4 時計）**: `clockNowMs` / `clockAdjust` の進行中分を `Math.max(0, ...)` でクランプ。端末時刻巻き戻しによる負値表示を防止。
- **修正（L-6 内訳）**: `computeFieldGoalBreakdown()` で `breakdown.firstHalf` / `secondHalf` を void 以外の `goal` イベントの `half` から正しく集計（従来は前半 0・後半に全得点を押し込む表示バグ）。
- **セキュリティ（H-1 ヘルプ HTML）**: `sanitizeHelpHtml.ts` で DOMPurify の `ALLOWED_TAGS` / `ALLOWED_ATTR` を明示列挙、`script` / `iframe` / `on*` 属性を確実に除外。記事内リンクの `decodeURIComponent` を try/catch で保護。
- **修正（M-4 quota）**: `saveLocal` / `saveLocalBatch` で `QuotaExceededError`（DOMException 22）を検知し、8 秒クールダウンでトースト通知（`toast.local_storage_quota` を ja/en に追加）。
- **修正（M-3 整合）**: `clearMatchData()` の最後で `rehydrateStoresAfterLocalStorageMutation()` を実行し、API 単独呼び出しでも Pinia 状態と localStorage が同期されるよう改善。
- **テスト**: `stores/matches.test.ts`（不正 teamId 拒否、時計巻き戻し時の `clockNowMs`）、`localMatchAdapter.test.ts`（`computeFieldGoalBreakdown` の 1H/2H/PK 除外）を新設。**37 → 43 件**。
- 版数: `package.json` / `package-lock.json` / `fxmanifest.lua` / `REFBOARD_UI_VERSION` を **0.5.0** に同期。

### Future（v0.5.1 後に検討）

- **F-1'**: `intro_setup` への **スクリーンショット新規追加**（手元撮影可能になったら v0.5.2 等で対応）。
- **H-2 / M-1 / M-6 / M-9**: ID カウンタ・settings キー整合、fetch タイムアウト、PK 連打 race、版数表記整理。

## v0.4.1 — 2026‑05‑09

- **疑似データ**: PK 進行中の live 試合「カップ戦 PK進行中（実機検証用）」を追加（90 分同点 2-2 後、PK 4 本で 1-1・次は先攻の第 3 本）。進行中 live は **通常 1 + PK デモ 1 + PK 進行中 1** の 3 件のまま（旧「カップ戦 1回戦 第1試合」を置換）。
- 版数: `package.json` / `package-lock.json` / `fxmanifest.lua` / `REFBOARD_UI_VERSION` を **0.4.1** に同期。

## v0.4.0 — 2026‑05‑09（BREAKING: データ管理・エクスポート削除）

- **削除（破壊的変更）**: データ管理画面（`/workspace/data`）、試合詳細の JSON/CSV ボタン、`exporters` / `localImport` / `ImportBackupDialog`、関連単体テスト、i18n の `data.*` 一式、ヘルプ記事 6 本（`data_view_history` / `data_export` / `data_import` / `data_csv_format` / `data_csv_excel_open` / `data_migration`）と `index.json` の data カテゴリ・`reverse_index` の `data_off`・`context_map` の `data_manage`。
- **PK 戦**: `PenaltyShootoutPanel` を **3 列**（通し番号・先攻・後攻）に再配置。入力 UI は各キック順列の下に配置。先攻は `pkFirstTeamId`（未設定時はホーム）。
- **ヘルプ（試合詳細）**: `HelpHoverDialog` で記事本文を **モーダル内**に表示。記事内リンクは `router.push` せず slug を切替（←／Esc で一覧へ）。
- **表示**: 赤牌イベントの内部的な `note`（`red_card` / `second_yellow`）がタイムラインにそのまま出ていた問題を修正（`localEventToRow`）。
- **UX**: ゴール／カード／交代ダイアログで、試合時計に基づく分・ロスタイムを `eventMinutePresetFromClock` で **初期プリセット**（PK 中は従来どおり除外）。
- **テスト**: `eventMinutePresetFromClock` のケースを `matchTime.test.ts` に追加（計 **37** 件）。
- **注意**: 永続化は `localStorage` のみ。アプリからのバックアップ手段はない。
- **保持**: 設定の開発者向け **疑似データ投入／試合系削除／全削除** は従来どおり。
- 版数: `package.json` / `package-lock.json` / `fxmanifest.lua` / `REFBOARD_UI_VERSION` を **0.4.0** に同期。

## v0.3.2 — 2026‑05‑10

- **PK 戦**: `serverHalf === 'pk'` の間は小窓フラグに依存せず、**画面下部固定の PK 専用ドック**のみ表示（通常の試合編集 UI は非表示）。操作者行・「試合一覧に戻る」・`PenaltyShootoutPanel` を同梱。小窓と同寸法・`transparentChrome`／`compact_dock_state` は PK 中も有効化。
- **ヘルプ（試合詳細）**: 「?」でスライドインではなく **中央モーダル**（`HelpHoverDialog.vue`、ESC／背景クリックで閉じる）。`context_map` の `match_detail` 記事一覧は `ContextHelpPanel` と同ロジックを再利用。
- **データ管理**: FiveM NUI 実行時のみ **CSV/JSON が保存できない旨**の注意（`data.fivem_export_note`）。ブラウザでのエクスポート運用を案内。
- **見送り**: FiveM CEF での Blob ダウンロードは **v0.4.0** で NUI→Lua ブリッジ予定（HANDOVER 参照）。
- 版数: `package.json` / `fxmanifest` / `REFBOARD_UI_VERSION` / エクスポート JSON の `appVersion`・`exporter_version` を **0.3.2** に同期。

## v0.3.1 — 2026‑05‑10（実機ホットフィックス）

- **疑似データ（設定）**: `location.reload()` を廃止し、`localStorage` 書き込み後に `teams` / `matches` / `settings` の Pinia を再読込。`id_counters` は `beginIdCounterBatch` / `endIdCounterBatch` でシード構築中のディスク書き込みを抑制。`saveLocalBatch` で配列キーをまとめて保存。FiveM CEF での NUI フォーカス滞留・クラッシュ回避。
- **ダウンロード**: `downloadFile` で `<a>` を `document.body` に一時追加し、`click` 後に除去・`revokeObjectURL` を遅延。`exportFullBackup` も同経路に統一（CSV / JSON / 試合パックの各ボタンが CEF で動作しやすくなる想定）。
- **小窓**: `CompactEventList` を前後半カード列（`MatchStatusCard` と同じ grid セル）の下に移動し、高さ既定を `6rem`。
- 版数: `package.json` / `fxmanifest` / `REFBOARD_UI_VERSION` / エクスポート JSON の `appVersion`・`exporter_version` を **0.3.1** に同期。

## v0.3.0 — 2026‑05‑10（CSV 出力拡充 B1 + ヘルプ I）

- ヘルプを **16 → 22 本**に拡充（日英対称）。CSV 列説明・Excel 表示・JSON での別 PC 移行・PK 2 列 UI・小窓モード・イベントが見えないときの確認。`data_export` から新記事へリンク。`eval-help-fuse.mjs` / `help_search_queries.md` に評価クエリを追加（Fuse `threshold` は 0.35 据え置き）。
- 試合単位の CSV を **サマリ 1 行**（9 列）と **イベント行**（標準 **13 列** / 詳細 **26 列**）の **2 ファイル**で出力（`refboard_m{id}_{日付}_summary.csv` / `_events.csv`）。BOM 付き UTF-8 は従来どおり。
- 詳細列に `final_score`（PK 併記）、`minute_label`（`45+2'` / `PK`）、選手・アシスト、カード色、交代 in/out、PK 成否・チーム内 `pk_shot_index`、`event_text`、`recorded_at_iso`、各イベント行の `operator`（`settings.selfName`）を追加。
- `MatchDetail.vue` と `DataManage.vue`（終了試合行）に **CSV 形式**のドロップダウンを追加。`utils/exporters.test.ts` で主要ケースを検証。
- 版数: `package.json` / `package-lock.json` / `fxmanifest.lua` / `REFBOARD_UI_VERSION` を **0.3.0** に同期。

## v0.2.2 — 2026‑05‑10（疑似データ投入機能）

- 設定画面下部の SQL／DB メタ表示（schemaVersion / resourceVersion 等）を削除。ローカル版で参照されない情報の整理。
- Settings の Development セクションに「疑似データを投入」「試合・チーム・ロスターを削除」「全データを削除（設定含む）」の 3 ボタンを追加（「開発用データ操作パネルを表示」がオンのとき、または `npm run dev` 時に表示）。
- 投入データは `src/dev/sampleData.ts` の固定配列。10 チーム（欧州風架空名・国籍別の姓名プール）× 13 名 = 130 名のロスター、20 試合（finished 12 / live 3 / draft 5）。`src/dev/seedActions.ts` が `localStorage` を書き換えたあと `location.reload()` で反映。旧サーバ向け SQL 疑似投入 UI は撤去。
- コンパクト小窓モード（`transparentChrome`）時、`Teleport` 系モーダルの背後オーバーレイを透過しゲーム画面が見えるようにした（`composables/useDialogOverlay.ts`）。
- PK 入力は `matches` に `pk_goal` / `pk_miss` として保存されていたが、`localMatchAdapter` が表示用 `text` を組み立てていなかったため PK 一覧・イベント欄が空行に見える不具合を修正（D-1）。
- PK 入力 UI をホーム左・アウェイ右の 2 列（小窓モードでは 1 列縦積み）に刷新。成功は ⚽、失敗は `失敗`／`Miss` 表示。`localEventToRow` に `pkTeamId` / `pkPlayerNumber` / `pkPlayerName` を追加（D-2）。
- 小窓モード（下部ドック）に直近イベント一覧を追加（新しい順・最大高さ 8rem でスクロール、読み取り専用）。PK 中は従来どおり一覧非表示（B）。
- 小窓モードで操作者名（`selfName`）を表示。未設定時は「未設定」（C）。
- 疑似データに PK デモ試合を 1 件追加（live・1-1・PK 2-2 同点で未決着、`sampleData.ts` の `pkDemo` と `seedActions.ts` で生成）。

## v0.2.1 — 2026‑05‑10（テスト基盤導入）

- vitest を devDependencies に追加。`npm test` で `src/**/*.test.ts` を実行。watch は `npm run test:watch`。
- `utils/matchTime.ts` の単体テスト（25 件）を新設。`parseMinuteInput` の正常系・正規化・異常系と `formatMinute` / `formatMinuteForCsv` を網羅。

## v0.2.0 — 2026‑05‑09（運用品質）

- ヘルプ検索 Fuse.js を 16 本構成向けに再調整（`threshold` 0.4→0.35、`minMatchCharLength` 2、`ignoreLocation` true、`keys` に `slug` 追加）。評価クエリリストを `docs/testing/help_search_queries.md` に新設。`scripts/eval-help-fuse.mjs` で再評価可能。第九コミット `ce6f281`。
- 試合イベントの時刻入力に `45+2` 表記を許容。`web/src/utils/matchTime.ts` 新設、`MinuteInput.vue` をゴール／カード／交代ダイアログで採用。表示・CSV の分列は `formatMinute` / `formatMinuteForCsv` で統一。PK 中は保存値 `minute=0` / `stoppage=null`、表示は `PK` のみ。
- JSON インポートに部分マージを追加。チーム／ロスター／試合を個別選択でき、試合選択時は関連チームとロスターを自動同伴（既定 ON）。取り込み履歴に `partial` フラグ追加。`data_import` ヘルプを v0.2.0 仕様に更新。

## v0.1.0 — 2026‑05‑09（ローカル版リブート）

サーバ連動版（旧 v0.8.6）からローカル単体版へ刷新した最初のリリース。oxmysql 依存・編集ロック・プレゼンス・オートセーブ・ヘルスチェックを全廃し、データは端末の `localStorage` のみ。詳細は 4 連コミット（`571cfdd` / `767dd35` / `c89256a` ＋初回コミット）と `docs/diary/2026-05-09_local_reboot.md`、`docs/HANDOVER.md` 第 3 版を参照。

- 2026‑05‑09 追記: `web/package.json`・`package-lock.json`・`REFBOARD_UI_VERSION` を 0.1.0 に同期（`fxmanifest.lua` と整合）。
- 2026‑05‑09 追記: 試合詳細ヘッダに操作者名（`selfName`）を表示。未設定時は Settings への誘導リンク。
- 2026‑05‑09 追記: JSON バックアップのインポート UI（置換／追記）と取り込み履歴（直近 20 件）を追加。`schemaVersion=1` のみ対応。
## v0.9.2 — 2026-05-09

- **feat（設定）**: 全体フォント倍率に **250% / 300%** を追加（`rootFontScale`・`index.html` FOUC 先読み・`sanitizeRootFontScale` を同期）。
- **fix（表示）**: `text-[10px]` / `text-[11px]` / `text-[22px]` 等の **ピクセル固定**を `rem` 指定に変更し、ルート倍率変更で **補助ラベルやトーストのエラー行も追従**するようにした。
- **fix（編集ロック）**: Close / ランチャー「ゲームへ戻る」で **`refboard:close`（Lua による `session:leave` + `lock:release`）を `session.leave()` より先**に実行。`session.leave()` 先頭の `pendingRelock` 全消しをやめ、意図的閉じでもサーバ解放が確実になるよう整理。経路一覧は `docs/editor_lock_release_flows.md`。
- **fix（試合時計）**: `clock_started_at` が JSON で省略／解釈不能なとき走行中でも経過 0 になり残りが定尺に戻る問題を、`reconcileRunningClockStarted`・`watch`・Lua ACK／`match:state` の `RefboardParseEpochMs` 正規化で修正。一時停止で 90:00 に戻る症状の主因を潰す。
- **fix（カード）**: `playerId` を文字列でも受理（Lua `parsePayloadId`）、交代出場が `bench` 表示でも選択可能に、INSERT 失敗は `db_insert_failed` + ログ。トーストに `tx_failed` の `detail` を短縮表示。
- **fix（試合詳細）**: 遅い `match_get:ack` が時計操作・イベント後に届き **古いスナップショットで上書き**するレースを、`reloadMatch` で `loadMatchGen++` して進行中の取得を捨てる／時計 ACK 成功後も `reloadMatch()` で再取得するように修正。ゴール・交代は `playerId` を文字列送信＋サーバ `RefboardParsePayloadPositiveId` 共通化。
- **fix（編集ロック）**: ランチャーで `enterEdit` した直後は `lock_acquire` が **matchId なし**で `editor_locks.match_id` が NULL のままになり、時計・スコア・イベントがすべて `no_lock` になる問題に対し、`RefboardAssertEditorLockForMatch` で **保持者かつ match_id が NULL ならリクエストの試合 ID にバインド**してから検証する（clock / score / event / player / match の各 assert を置換）。

## v0.9.1 — 2026-05-09

- **feat（開発用データ）**: `Config.EnableTestCommands = true` かつ編集モード入室時のみ、設定画面に **疑似データ投入**（全削除 → `seed_test_5teams_15roster.sql` → 試合20件 `dev_seed_20matches.sql`）と **全データ初期化**（空庫）を追加。いずれも警告後に **YES** 入力で実行。サーバー `server/dev_data_reset.lua`、SQL `sql/dev_seed_20matches.sql`。
- **chore**: `fxmanifest.lua` の `files` に `dev_seed_20matches.sql` を追加。

## v0.9.0 — 2026-05-09（実機テスト準備リリース）

- **docs（実機テスト計画刷新）**: `docs/testing/release_test_plan.md` を v0.5.0 当時の前提から v0.8.6 までの全機能をカバーする内容に拡張。シナリオ 8（ヘルプ機能）、シナリオ 9（小窓モード）、シナリオ 10（マーキー）、シナリオ 11（設定永続化）を新設。シナリオ 1〜3 / 6 にも v0.6〜v0.8 の確認項目を追補。
- **docs（テスト結果テンプレート）**: `docs/testing/test_results.md` に「v0.9.0 実施回テンプレート」を追加。シナリオ 11 件・新規不具合・改善提案・総合判定を一括で記録できる形に。
- **docs（既知の問題刷新）**: `docs/testing/known_issues.md` を「未解決 / 仕様として許容（記事で吸収済み）/ 解決済み（直近 6 リリース）」の 3 セクション構成に再編。v0.7〜v0.8 で解決した重大バグ 11 件を解決済みに整理。
- **docs（デバッグ Tips 新設）**: `docs/testing/debug_tips.md` を新設し、サーバー側ログレベル / `editor_locks` 手動確認 / NUI トレース / nuiMock 操作 / ヘルスチェック / ログ採取動線を集約。
- **docs（HANDOVER）**: §8 に「実機テストの始め方」サブセクションを追加。
- **互換**: ランタイム挙動の変更なし。`fxmanifest.lua` / `package.json` / `version.ts` を 0.9.0 に同期。

## v0.8.6 — 2026-05-09

- **chore（ビルド）**: Vite の `build.rollupOptions.output.manualChunks` を関数形式で導入し、ヘルプ記事 Markdown（`help-articles-ja` / `help-articles-en` / `help-meta`）と主要ベンダ（`vendor-markdown` = marked + dompurify、`vendor-search` = fuse.js、`vendor-i18n` / `vendor-router` / `vendor-pinia` / `vendor-headlessui` / `vendor-vueuse` / `vendor`）を独立チャンクに分割。`index.js` の 500kB 超警告を解消。
- **chore（ビルド）**: `chunkFileNames` に `[hash]` を付与してチャンクのキャッシュ衝突を回避（エントリ `index.js` はハッシュなしのまま維持し、`index.html` の参照を安定化）。`chunkSizeWarningLimit` を 600 に引き上げ、分割後の警告ノイズを抑制。
- **互換**: ランタイム挙動の変更なし。FiveM 側は `fxmanifest.lua` の `files = { 'web/dist/**/*' }` で新チャンクを自動的に配信。

## v0.8.5 — 2026-05-09

- **feat（ヘルプ）**: `E3006`（`player_has_events`）の専用記事を日英で追加（`trouble_e3006_player_has_events.md`）。試合メンバー削除時に「タイムラインに参照あり」で失敗したときの解決手順・取消フロー・FAQ を収録。
- **chore（ヘルプ配線）**: `errorCodeMapper.ts` の `ERROR_CODE_TO_HELP_SLUG` に `E3006` を追加し、エラートーストの「解決方法を見る」から専用記事に直行できるようにした。`reverse_index.json` の緊急度高カテゴリ、`index.json` のトラブルカテゴリ、`context_map.json` の `match_detail` にもそれぞれ登録（日英）。

## v0.8.4 — 2026-05-09

- **feat（設定）**: 全体の文字サイズ（ルート `font-size`）を **設定画面から 100% / 150% / 200%** で切替可能に。`stores/settings.ts` の `rootFontScale`（既定 **200**、`localStorage` 永続化）と `App.vue` の `watchEffect` で `html.style.fontSize` に反映。`Settings.vue` の「表示」セクションにラジオを追加。日英 i18n（`settings.font_scale.*`）。
- **chore（CSS）**: `main.css` から `html { font-size: 200% }` を削除（JS 側に集約）。FOUC 防止のため `index.html` に `<head>` インラインスクリプトを追加し、`refboard_settings` の `rootFontScale` を先読みしてから本体スクリプトを読み込む。
- **互換**: 旧 `localStorage` に `rootFontScale` キーが無い場合は `200` で動作（`sanitizeRootFontScale` で不正値も既定に丸める）。`STORAGE_VERSION` 変更なし（モック側の破壊的シードは伴わないため）。

## v0.8.3 — 2026-05-08

- **fix（本番 DB）**: テスト用 **5チーム×ロスター15人**が入らない問題に対し、既定で **`Config.SeedDemoTeamsOnStart = true`** のときリソース起動後に `sql/seed_test_5teams_15roster.sql` を自動実行する **`server/demo_seed.lua`** を追加（`teams` 準備をポーリング。SQL は従来どおり idempotent）。本番で不要なら `config.lua` で **false**。
- **manifest**: 上記 SQL を `files` に含め、`LoadResourceFile` で読込可能に。
- **dev（NUI モック）**: 古い `localStorage` を確実に差し替えるため **`STORAGE_VERSION` を 3** に更新。

## v0.8.2 — 2026-05-08

- **UI**: ルート `font-size` を **200%**（ブラウザ既定の 2 倍）に戻し、CEF 上の文字・余白（rem 系）を再拡大。

## v0.8.1 — 2026-05-08

- **dev（NUI モック）**: 初期シードを **チーム5件**・各 **ロスター15人**（GK1+DF4+MF5+FW5）に拡張。`localStorage` のモック状態は **`STORAGE_VERSION` 2** で再シードされる。
- **dev（MySQL）**: 任意実行の `sql/seed_test_5teams_15roster.sql` を追加（同名チーム・既存ロスターがある場合はスキップ）。

## v0.8.0 — 2026-05-08

- **UI**: ルート `font-size` を **150%** に変更（従来 200%）。Tailwind の rem ベースの文字・余白が一括で約 1.5 倍相当に。
- **UI（チーム管理）**: **ロスター**パネルもチーム詳細と同様に **幅 50%**（`lg:w-1/2`）に。
- **fix（チーム管理）**: チーム詳細の **更新**後にフォーム・一覧が遅れてしか変わらない問題を、**楽観的に `team` を更新**＋**古い `team:detail:ack` を無視するシーケンス**で改善。
- **fix（試合詳細）**: `refboard:match:state` で **選手配列が空**のとき一覧が更新されない条件分岐を修正（`players != null` で常にマッピング）。
- **feat（試合・下書き）**: チームメンバー表に **削除**を追加。サーバー `refboard:player:remove`（編集ロック・**draft**・**タイムライン未参照**のみ DELETE）。エラー **E3006**（イベントに紐づく選手）。

## v0.7.9 — 2026-05-08

- **fix（UI）**: 試合時計の **一時停止**を赤丸＋四角アイコンのみから、**「一時停止」ラベル付きボタン**（クリアと同系のピル型）に変更。**ツールチップ／aria** で「経過は保持」「クリアは 0 に戻す」を明示し、**クリア**と混同しないようにした。

## v0.7.8 — 2026-05-08

- **UI（小窓）**: 画面下端の **全幅の紺色帯**（外側ラッパーの `bg-slate-950`）を廃止し、**小窓パネル単体**のみ背景を表示。
- **UI（小窓）**: 右下の **操作案内・復帰ボタン**の文字を約 **2 倍**（案内 `text-xl`、ボタン `22px`、列幅も拡大）。

## v0.7.7 — 2026-05-08

- **UI（小窓）**: 黄の「復帰」案内を **小窓パネル右下**へ移動（プレゼンス表示と干渉しない）。**Ctrl+B**（NUI フォーカス時）と **B**（FiveM キー割当 `refboard_compact_toggle_input`、歩行中）で **UI 操作 ⇔ ゲーム（歩行）** を切替。Lua が `SetNuiFocus` を制御し、ヒント文を右下に表示。
- **UI（小窓）**: スタジアムコンパクト時の **メインヘッダー帯**を透明化（背面のスレート帯を非表示。プレゼンスバッジは従来どおり）。

## v0.7.6 — 2026-05-08

- **fix（UI・日付）**: DB / ブリッジで日付が数値・オブジェクトになる場合でも、一覧・データ管理・チーム一覧・試合詳細の日付入力・スコア履歴に **正規化した表示**（`utils/formatDate.ts`）。
- **fix（カード）**: イエロー／レッド登録で **登録ボタンが無反応に見える**問題に、**入力検証トースト・ACK 失敗トースト・8 秒タイムアウト**、チーム選択と赤カード確定の **スクリプト側ハンドラ**（テンプレート内の ref 代入の取りこぼし防止）、ダイアログ閉鎖時の **`presetKind` クリア**を追加。
- **UI（チーム管理）**: チーム詳細パネルの横幅を **従来の約 50%**（`lg:w-1/2 lg:max-w-[50%]`）に。

## v0.7.5 — 2026-05-08

- **fix（試合時計）**: F6 で NUI を閉じるとサーバーが編集ロックを解放するが、**同じ試合詳細のまま**ツールを開き直すと `onMounted` が走らず **ロック未取得のまま**になり、`match_clock` が `no_lock` で失敗していた。**NUI 再表示時**（`nuiShellOpenRef` false→true）に `lock_acquire` + `match_get` で取り直し。
- **fix（編集ロック）**: **別の試合**へルート切替時も `lock_acquire` を送る（従来は初回マウント時のみで、一覧から試合を切り替えると前試合のロックのまま時計が失敗し得た）。
- **fix（同期）**: `refboard:match:clock:ack` / `refboard:match:state` の `matchId` が数値と文字列で混在しても適用されるよう **Number 比較**に統一。
- **UX**: 閲覧モードで時計ボタンを押したとき無反応だったため、**トースト**で案内（`score_board.clock_readonly_hint`）。

## v0.7.4 — 2026-05-08

- **feat（DB）**: 起動時に `information_schema` で `editor_locks` の有無を確認し、**無い場合のみ** `sql/install.sql` を自動実行する（`server/schema_bootstrap.lua`）。`Config.AutoCreateSchema`（既定 `true`）で無効化可能。既存 DB は変更しない。列追加用の `sql/migration_*.sql` は従来どおり手動。

## v0.7.3 — 2026-05-08

- **fix（NUI）**: 編集ロック取得が **`db_query_failed` 等の DB エラー**で失敗したときに、**「他のユーザーが編集中」モーダル**を出さない。トーストで **install.sql / DB** を案内する（`Launcher.vue` / `MatchList.vue`）。分類は `utils/lockAcquireErrors.ts`。

## v0.7.2 — 2026-05-08

- **fix（起動）**: `editor_locks` が未作成（`install.sql` 未実行）の DB でも **`ensure RefBoard` でスクリプトが落ちない**よう、`lock.lua` の `clearRow` / `readRow` / `writeRow` / ハートビート / `playerDropped` フォールバックを **`pcall` で包み**、失敗時は `Logger.warn` とクライアント向けエラー（`db_error` / `E4002`）に留める。

## v0.7.1 — 2026-05-08

- **fix（編集ロック）**: 同一 `license` で再接続しただけで `holder_server_id` が変わり **E1003（lock_held）** になるケースに対し、`refboard:lock:acquire` で **保持者 license が自分と一致すればロックを奪い返す**（幽霊ロック防止）。
- **fix（セッション）**: `refboard:session:leave` 時に **保持者なら `editor_locks` を必ず解放**（`RefboardLockReleaseIfHeldBy`）。NUI が `lock_release` を送れなかった場合の保険。
- **fix（切断）**: `playerDropped` で `readRow` が失敗したときも **`holder_server_id = source` の行を直接 UPDATE** して掃除を試みる。
- **fix（リソース再起動）**: `onResourceStart` で **`editor_locks` をクリア**し、設計書どおり再起動後に古い保持者 ID が残らないようにする。
- **fix（NUI）**: 編集ロックの **ハートビートを `MainLayout` で送る**（試合詳細以外の画面にいても 30 秒タイムアウトでロックが勝手に切れない）。

## v0.7.0 — 2026-05-08

- **ヘルプ英語版（Sprint 09 Phase E）**: `web/src/help/en/articles/` に日本語 20 本と同一 slug の英語記事を追加。`en/index.json` / `en/reverse_index.json` を新設。
- **ロケール連動**: `HelpView.vue` が UI 言語（`vue-i18n` / `refboard-locale`）に応じて `ja` / `en` の Markdown・逆引き・目次を切替。`helpSearch.ts` はロケール別に Fuse インデックスをキャッシュ（`buildHelpIndex('ja'|'en')`）。
- **目次タブ**: 左カラムに「やりたいことから / 目次（トピック順）」の切替を追加し、`index.json` のツリーを表示。
- **コンテキスト `?`**: `ContextHelpPanel` の記事タイトルが UI 言語の `reverse_index` に追従。
- **i18n**: `help.tree_tab` を `ja.json` / `en.json` に追加。`help.subtitle` を v0.7 表記に更新。
- **ユーティリティ**: `web/src/utils/helpLocale.ts`（`resolveHelpLocale`）を追加。

## v0.6.8 — 2026-05-08

- **ヘルプ（日本語 20 本完成）**: Phase D 記事 8 本を追加 — `intro_what_is_refboard` / `intro_setup` / `match_create_new` / `team_create` / `team_add_roster_member` / `data_view_history` / `data_export` / `trouble_health_check_guide`（`web/src/help/ja/articles/`）。
- **ヘルプ目次**: `index.json` に「はじめに」「チーム管理」「データ管理」を追加し、試合管理へ「新しい試合を作る」を先頭に配置。トラブルに「ヘルスチェックの見方」を追加。
- **逆引き**: `reverse_index.json` に はじめに / チーム / データ・履歴 / 試合の準備 / 診断 カテゴリを追加（既存の緊急・試合中と合わせ全 7 カテゴリ）。Fuse.js 検索インデックスは次回 Help 表示時に件数増加。
- **コンテキストヘルプ**: `context_map.json` を更新 — `team_manage` / `data_manage` に関連記事を割当、`match_detail` に `match_create_new` を追加、`settings` に `trouble_health_check_guide` を追加。

## v0.6.7 — 2026-05-08

- **コンテキストヘルプ**: 画面ヘッダの `?` ボタンから、その画面に関連する記事だけを右スライドインパネルで提示する仕組みを実装。
- **新規コンポーネント**: `HelpTriggerButton.vue`（`?` 丸ボタン）、`ContextHelpPanel.vue`（Teleport で `body` にマウントするスライドインパネル）。Pinia store `contextHelp` で開閉状態を一元管理。
- **配置**: `MatchDetail` / `TeamManage` / `DataManage` / `Settings` の 4 画面に `?` を配置。コンパクトドック中の MatchDetail には出さない（ヘッダごと隠れるため）。
- **マッピング**: `web/src/help/context_map.json` を新設し、画面 ID → 記事 slug 配列で定義。`match_detail` は試合中・トラブル系 11 件、`settings` は接続・オートセーブ 2 件。`team_manage` / `data_manage` は Phase D で記事追加時に埋める（現状空配列で「関連記事なし」表示）。
- **遷移**: 記事クリックで `help-article` ルートへフル遷移（Phase B 検索と挙動を統一）。`Esc` / オーバーレイクリックで閉じる。ルート変更時は自動的に閉じる。
- **i18n**: `help.context.*`（open_aria / open_title / panel_aria / close_aria / title / subtitle / empty / open_all）を `ja.json` / `en.json` に追加。
- **既知の制約**: `team_manage` / `data_manage` のコンテキスト記事は Phase D（v0.6.8）で記事 20 本完成に合わせて配線予定。

## v0.6.6 — 2026-05-08

- **ヘルプ検索**: `fuse.js` 7.3 を導入し、タイトル / タグ / 本文（plain text 化）の重み付き全文検索を実装（`web/src/utils/helpSearch.ts`）。
- **HelpView**: ヘッダーに検索ボックスを追加。クエリ入力で左カラムが検索結果リストに切り替わり、各行に「🎯 逆引き」バッジを表示。Enter で先頭ヒットを開く。IME 確定後に検索が走るよう `compositionend` を購読。
- **i18n**: `help.search.*`（placeholder / clear / searching / results_for / no_results / badge_reverse / badge_tree）を `ja.json` / `en.json` に追加。
- **パフォーマンス**: 検索インデックスは `onMounted` で lazy 構築し、モジュールレベルでキャッシュ。`resetHelpIndex()` を export して将来の locale 切替（Phase E）に備える。
- **既知の制約**: 検索対象は現状 `reverse_index.json` 系のみ。`index.json` の項目ごとツリーは **Phase E** で HelpView に配線予定（バッジ `📚 項目ごと` と併用）。

## v0.6.5 — 2026-05-08

- **ヘルプ**: 日本語記事を 4 → 12 本に拡充（試合管理カテゴリ 8 本追加: `match_record_goal` / `match_record_assist` / `match_substitute_player` / `match_yellow_card` / `match_red_card` / `match_penalty_shootout` / `match_manual_score_edit` / `match_finish`）。
- **ヘルプ**: `web/src/help/ja/index.json` に「試合管理」カテゴリを追加。`reverse_index.json` に「試合中」カテゴリを追加し、各項目に `actionUrl` を付与。
- **ドキュメント**: `docs/sprints/sprint_09_help_phase2.md`（v0.6.5 〜 v0.7.0 の 5 フェーズ計画）を新設。
- **既知の制約**: 左カラムの「項目ごと」ツリー（`index.json`）はまだ HelpView から読み込まれていない。Phase B 以降で UI 改修予定。
- **エラー → ヘルプ**: `E2005`（`reason_too_short`）を `match_manual_score_edit` 記事に紐づけ。

## v0.6.4 — 2026-05-07

- **fix（重大）**: `ensure` 直後やシェル非表示時、`#app` が空でも **`body` の `bg-bg`（不透明）が全画面を塗り**ゲームが見えない問題を修正。`html` / `body` を **透明**にし、見た目の背景は **`App.vue` のシェル表示中のみ**付与する。

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
