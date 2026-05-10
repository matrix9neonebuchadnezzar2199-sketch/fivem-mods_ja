# RefBoard 引継資料（第 3 版・ローカル版）

- **作成日**: 2026‑05‑09（継続更新）
- **対象バージョン**: v0.6.0（ローカル専用・useNui タイムアウト・PK 確認連打耐性・clearAllData 整合・intro_setup スクショ追加を含む）
- **位置づけ**: 旧 v0.8.6 までのサーバ連動版（`RefBoard_old/`）からローカル単体版へ刷新した最初の安定リリース。

## 0. 第 3 版での主な変更

- 旧 RefBoard（v0.8.6）を `RefBoard_old/` にローカル退避し、GitHub からは除去。`H:\CURSOR\Dev\fivem-mods_ja\RefBoard_old` に素材庫として保管。
- 新 `RefBoard/` を v0.1.0 として再スタート。MySQL／oxmysql／編集ロック／プレゼンス／オートセーブ／ヘルスチェックを廃止。データは端末の `localStorage` のみ。
- NUI と Lua の通信は「F6 で UI を開閉」と「Close ボタンでフォーカスを返す」だけに削減。

## 1. リポジトリと作業パス

- GitHub: `https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja` の `RefBoard/`
- ローカル: `H:\CURSOR\Dev\fivem-mods_ja\RefBoard`
- 旧資産（GitHub 非追跡）: `H:\CURSOR\Dev\fivem-mods_ja\RefBoard_old`（`.gitignore` 済み）

## 2. 技術スタック

- FiveM Lua 5.4（NUI 開閉のみ。サーバスクリプトなし）
- Vue 3.5 + Vite 6 + TypeScript 5.7 + Tailwind 3.4 + Pinia + vue‑router + vue‑i18n
- ヘルプ: marked + dompurify + fuse.js 7.3
- 永続化: `localStorage`（キー前缀 `refboard_local_`、スキーマバージョン 1）

## 3. ディレクトリ構成（v0.6.0）

```
RefBoard/
├─ fxmanifest.lua          version '0.6.0'
├─ config.lua              OpenKey, DefaultLocale のみ
├─ client/main.lua         NUI 開閉と /refboard コマンド
├─ shared/constants.lua    リソース名等の定数のみ
├─ docs/
│  ├─ HANDOVER.md          本書
│  └─ diary/               2026‑05‑09_local_reboot.md ほか
├─ CHANGELOG.md
├─ README.md
└─ web/
   ├─ package.json         version 0.6.0（`REFBOARD_UI_VERSION`・fxmanifest と整合）
   ├─ index.html           rootFontScale FOUC 対策インラインスクリプト
   ├─ vite.config.ts       manualChunks（旧 v0.8.6 設定を踏襲）
   ├─ scripts/
   │  ├─ check-help-articles.mjs   ヘルプ整合チェック（`npm run check:help`、記事変更時に必須）
   │  └─ eval-help-fuse.mjs        Fuse 検索の簡易評価
   └─ src/
      ├─ main.ts           refboard:setOpen 受信、未処理例外トースト
      ├─ App.vue           settings.load() のみ
      ├─ router/index.ts   `/workspace/data` なし
      ├─ types/local.ts    Match/Team/Player/Event/ScoreHistory 型
      ├─ stores/
      │  ├─ matches.ts     試合 CRUD、時計、イベント、PK、手動編集、終了/再開（`addEvent` の scoring系 teamId 検証 H-3、`setPkFirstTeam` L-5、`cancelPenaltyShootout` v0.5.2）
      │  ├─ teams.ts       チーム CRUD、ロスター
      │  ├─ settings.ts    selfName, locale, fontScale, marquee 等
      │  └─ matchCompactDock.ts
      ├─ composables/useNui.ts    close/コンパクト関連のみ POST、他はダミー（v0.6.0 で AbortController 5s タイムアウト・エラー詳細）
      ├─ composables/useDialogOverlay.ts  小窓時はモーダル背後を透過（`transparentChrome`）
      ├─ dev/
      │  ├─ sampleData.ts         開発用疑似データの固定配列（チーム・試合シード）
      │  └─ seedActions.ts        投入／削除／全削除（Pinia 再 hydrate・`location.reload` なし）
      ├─ utils/
      │  ├─ localPersist.ts       localStorage ラッパ（v=1）、quota 超過時トースト（M-4）
      │  ├─ sanitizeHelpHtml.ts   ヘルプ HTML 用 DOMPurify 明示設定（H-1）
      │  ├─ localId.ts            ID カウンタ
      │  ├─ matchTime.ts          イベント時刻 `45+2` パース／表示・`eventMinutePresetFromClock`
      │  ├─ localMatchAdapter.ts  Match → MatchDetailModel ブリッジ（`computeFieldGoalBreakdown` L-6）
      │  ├─ matchTime.test.ts     parseMinute / preset 時計 等
      │  ├─ matches.test.ts       addEvent・`setPkFirstTeam`・`cancelPenaltyShootout`・clockNowMs（H-3/H-4/L-5/v0.5.2/v0.6.0）
      │  └─ dev/seedActions.test.ts   `clearAllData` rehydrate / id_counters / `resetIdCounters` vs `resetCountersMemoryOnly`（v0.6.0 H-2）
      │  └─ errorCodeMapper.ts    E2001/E3004/E3006 のみ
      ├─ components/
      │  ├─ match/MinuteInput.vue  イベント時刻（分＋ロスタイム）入力
      │  ├─ match/CompactEventList.vue  小窓モード用・直近イベント（新しい順・スクロール）
      │  └─ help/HelpHoverDialog.vue   試合一覧／試合詳細／チーム管理／設定の「?」— 記事一覧＋本文を同一モーダル内で表示（内部リンクは遷移しない）
      ├─ views/
      │  ├─ Launcher.vue          表示名入力 → 試合一覧へ
      │  ├─ MainLayout.vue        sidebar + RouterView（データ管理リンクなし）
      │  ├─ MatchList.vue         一覧／検索／削除／新規作成
      │  ├─ MatchDetail.vue       時計／ゴール／カード／交代／PK／手動編集／終了
      │  ├─ TeamManage.vue        チームとロスター
      │  ├─ Settings.vue          表示名／locale／fontScale／marquee／背景
      │  └─ HelpView.vue          目次／逆引き／検索／コンテキスト
      ├─ help/
      │  ├─ ja/articles/          16 本（intro 3／match 8／team 2／trouble 3）※ data カテゴリ削除。`intro_setup.md` は v0.6.0 で 4 枚スクショ挿入
      │  ├─ en/articles/          同上
      │  ├─ ja|en/index.json
      │  ├─ ja|en/reverse_index.json（data_off カテゴリ削除済み）
      │  └─ context_map.json（data_manage キー削除）
      └─ i18n/{ja,en}.json        `data.*` 系キー削除済み
```

## 4. リリース履歴

| 版 | 日付 | 内容 |
|---|---|---|
| v0.1.0（4 連コミット）| 2026‑05‑09 | ローカル版リブート完了 |
| └ 第 1 コミット | | Lua 最小化、サーバ／SQL／旧 docs 撤去、`RefBoard_old/` を `.gitignore` 追加 |
| └ 第 2 コミット `571cfdd` | | web からサーバ連携コード撤去、`localPersist`/`localId` 追加、`useNui` を close 中心に簡素化 |
| └ 第 3 コミット `767dd35` | | `stores/{matches,teams}` と全画面接続、`selfName`、`exportFullBackup`、`errorCodeMapper` 縮小 |
| └ 第 4 コミット `c89256a` | | i18n 通信系キー削除、ヘルプ 15 本（案 A）、CSS 警告原因の `exporters.ts` 修正、`matchServerMapping` 削除 |

旧版（v0.6.x〜v0.8.6）の履歴は `RefBoard_old/CHANGELOG.md` を参照。

## 5. 主要機構

- **永続化**: `utils/localPersist.ts` がキーごとに `{ version: 1, data }` 形式で `localStorage` に書き、各ストアが `watch(deep)` で自動保存。**アプリ内の CSV／JSON エクスポート・バックアップ UI は v0.4.0 で削除**。ブラウザのサイトデータ削除や設定の「全データ削除」で失われたデータは復旧できない。
- **ID 採番**: `utils/localId.ts` が match/team/player/rosterMember/event/scoreHistory のカウンタを `id_counters` キーで管理。
- **時計**: `matches` ストアの `clockStartedAt`（停止時 null）と `clockAccumulatedMs` の合算で `clockNowMs(m)` を算出。進行中分は **`Math.max(0, Date.now() - clockStartedAt)`** でクランプ（H-4・端末時刻巻き戻し対策）。`clockAdjust` 内の経過加算も同様。UI 側は 250ms ポーリングで表示のみ更新し、保存はストアが担当。
- **得点ロジック**: `addEvent` で `goal`/`pk_goal` を加算、`voidEvent` で減算。手動スコアは `manualScoreEdit` が `scoreHistory` に履歴を残しつつ `homeScore`/`awayScore` を上書き。**`goal` / `pk_goal` / `pk_miss` かつ非 void** のとき `teamId` がホーム・アウェイのいずれでもない／欠落なら **イベントを追加せず `null`**（H-3）。
- **ハーフ別得点内訳（L-6）**: `localMatchAdapter.ts` の `computeFieldGoalBreakdown` が void 以外の `goal` イベントを `half` で前半／後半に振り分け、`matchToDetailModel` の `breakdown.firstHalf` / `secondHalf` に反映。
- **ヘルプ HTML（H-1 / v0.6.0）**: `sanitizeHelpHtml.ts` で `HelpHoverDialog` / `HelpView` の本文を DOMPurify 明示設定でサニタイズ。記事内 `a[href]` の `decodeURIComponent` は try/catch。**v0.6.0** で `img` タグと `src` / `alt` / `width` / `height` / `loading` / `decoding` 属性を許可（`script` / `iframe` / `on*` は引き続き禁止）。記事側は **相対パス** `./help/intro_setup/01-launcher.png` のように書き、画像実体は `web/public/help/...` に配置（vite が `dist/help/...` へ自動コピー）。
- **localStorage quota（M-4）**: `saveLocal` / `saveLocalBatch` が `QuotaExceededError` を捕捉したとき、8 秒クールダウンでトースト（`toast.local_storage_quota`）。
- **疑似データ削除の整合（M-3 / H-2 v0.6.0）**: `clearMatchData()` と `clearAllData()` のいずれも末尾で `rehydrateStoresAfterLocalStorageMutation()` を呼び、Pinia と `localStorage` を同期。`clearAllData()` は **`NON_PREFIXED_KEYS`**（`refboard_settings` / `refboard-locale`）を定数として持ち、追加するノンプレフィックスキーはここに登録する運用。`clearAllLocal()` 直後は `id_counters` のディスク表現が消えているため、メモリ側だけ `resetCountersMemoryOnly()` で defaults へ戻し、不要な書き戻しを避ける。
- **PK 表示（v0.4.0〜）／先攻永続化（v0.5.1 L-5）／入口バリデーション・全体キャンセル（v0.5.2）**: `serverHalf === 'pk'` の間は **通常の試合編集 UI を出さず**、画面**下部固定**の PK 専用ドックに `PenaltyShootoutPanel` のみ。`Match.pkFirstTeamId`（`null` 時は UI 上 `homeTeamId` と同等）を `MatchStatusCard` の PK 移行確認で設定し、`MatchDetail.onSetHalf` が **`setPkFirstTeam` を `setHalf` より先**に呼ぶ。PK キックが 1 本でもあると `setPkFirstTeam` は拒否。`matchToDetailModel` の `pkFirstTeamId` は `m.pkFirstTeamId ?? m.homeTeamId`。**v0.5.2**: PK 移行の直前に **両チーム 1 名以上**の選手登録を必須（`MatchStatusCard` → `pk-validation-failed` → `toast.pk_no_players`）。`PenaltyShootoutPanel` は **3 列**グリッド＋下部の **直前キック取消**（`voidEvent`）／**キック 0 本時のみ先攻再抽選**（`pk-reroll-first`）／**PK 戦をキャンセル**（`pk-cancel-all` → `cancelPenaltyShootout`：PK イベント全件 void、`homePkScore`/`awayPkScore` 0、`pkFirstTeamId` null、`currentHalf` **`2H`**）。`pk-shot` → `addEvent`、表示は `localEventToRow`。
- **NUI 通信（M-1 v0.6.0）**: `useNui().send('close')` 等のコンパクト関連だけ Lua に POST。他はブラウザ／FiveM ともに `{ ok: true }` を返すスタブ。`postToLua` は `AbortController` で **5 秒タイムアウト**（`NUI_FETCH_TIMEOUT_MS`）、タイムアウト時は `{ ok: false, error: 'timeout' }`、その他のエラーは `{ ok: false, error: 'fetch_failed' }`。`on()` は `refboard:compact_input_mode` のみ window.message 経由で購読。
- **小窓モーダル透過**: `matchCompactDock.transparentChrome` が真のとき、`useDialogOverlay()` が `Teleport` 先の全画面オーバーレイを `bg-transparent` に切り替え（通常時は従来どおり `bg-black/55`〜`bg-black/65` 等）。ダイアログ本体の `bg-slate-900` は維持。
- **小窓ドック直近イベント**: `MatchDetail.vue` の `compactDock && !isPkPhase` ブロック内で、`CompactEventList` を前後半カード列下に配置。PK 専用ドックでは直近イベントは出さず PK パネルに集約。
- **ヘルプ**: ja/en 各 **16 本**（data カテゴリ 6 本削除）。**試合一覧・試合詳細・チーム管理・設定**の「?」はいずれも `HelpHoverDialog`（中央モーダル）：`context_map.json` のキー `match_list` / `match_detail` / `team_manage` / `settings` で関連記事スラッグを列挙。記事内の `#/workspace/help/article/…` リンクは **画面遷移せず** slug を切替（←／Esc で一覧へ）。全ヘルプ目次はサイドバー **ヘルプ** の `HelpView`。`errorCodeMapper.ts` は `E2001`/`E3004`/`E3006` のみ保持。
- **ヘルプ検索**: `utils/helpSearch.ts` の Fuse.js 設定は従来どおり（`threshold: 0.35` 等）。評価クエリは `docs/testing/help_search_queries.md`（データ管理系クエリは削除）。`web/scripts/eval-help-fuse.mjs` で再評価可能。
- **ヘルプ記事の整合検証（v0.5.0 作業 F-3）**: `npm run check:help`（`scripts/check-help-articles.mjs`）。**記事の追加・削除・リネームや `index.json` / `reverse_index.json` / `context_map.json` を編集したら必ず実行**し、インデックス↔ディスク↔逆引き↔コンテキストの参照欠落、ja/en スラッグ非対称、フロントマター欠落（`title`・`category` 必須）をローカルで検出する。失敗時は `[NG]` と件数で終了コード 1。
- **試合時刻入力**: `parseMinuteInput` に加え、オープン時の既定値に `eventMinutePresetFromClock(match, clockNowMs)`（前半／後半で 45+α・90+β に分離、PK は 0/null）。ゴール／カード／交代ダイアログは `MinuteInput` を開いた時点でプリセット。**表示**は `formatMinute` が `stoppage` 0 を `M'` のみとし、タイムライン／小窓は `EventMinuteColumn` で `+N'` を色強調（v0.5.0 F-4）。
- **カード表示**: 赤牌イベントの `note` に保存する内部的な `red_card` / `second_yellow` は、タイムライン表示テキストにそのまま出さない（`localEventToRow`）。
- **開発確認用疑似データ**: Settings の Development で「開発用データ操作パネルを表示」がオンのとき（または `npm run dev` 時）、`dev/seedActions.ts` が `saveLocalBatch` で一括書き込みし **ページリロードなし**で Pinia を再 hydrate。10 チーム × 13 名・**20 試合**（**finished 12** / **live 3**［通常 1・PK デモ完了相当 1・PK 進行中 1］/ **draft 5**）。PK 進行中は「カップ戦 PK進行中（実機検証用）」で PK ドック・3 列・通し番号をすぐ確認可能。

## 6. 開発・ビルド・配布

```bash
cd RefBoard/web
npm install
npm run dev          # ブラウザ単体プレビュー
npm run build        # web/dist 出力（FiveM 配布物）
npx vue-tsc --noEmit # 型チェック
npm run check:help   # ヘルプ index / reverse_index / articles / context_map / ja-en 整合
node scripts/eval-help-fuse.mjs   # Fuse 検索の目視用サンプル（任意）
```

- `npm test`: vitest による単体テスト。`matchTime.test.ts` / `localMatchAdapter.test.ts` / `matches.test.ts` / `dev/seedActions.test.ts` 等（v0.6.0 時点 **55** 件）。watch は `npm run test:watch`。`seedActions.test.ts` は node 環境向けに **最小 localStorage モック**を `installLocalStorageMock` で組み立て、`afterAll` で uninstall する。

`fxmanifest.lua` は `web/dist/index.html` と `web/dist/**/*` をパッケージ。`server.cfg` には `ensure RefBoard` の 1 行のみ（`oxmysql` も ACE も不要）。`Config.OpenKey`（既定 F6）と `Config.DefaultLocale`（既定 `ja`）だけ設定可能。

## 7. 既知の TODO（v0.6.0 時点）

- 選手状態セルのタップ切替、`Ctrl+Z` でゴール取消ショートカット。
- **F-3**: ロスター（`RosterMember`）削除時、過去試合 `MatchPlayer.rosterMemberId` が dangling 化する。次に同じ ID が再採番されると別人で同スロット参照になる潜在事故。`teams.ts::removeRosterMember` 側で関連 MatchPlayer を tombstone 化するか、UI 側で「削除済みロスター」表示を出す案を検討。
- **F-5**: 複数タブ起動時の整合性（タブ A の `localStorage.setItem` がタブ B の Pinia に反映されない）。`storage` イベントリスナーで他タブ更新を検知する仕組み。単一タブ運用が前提だが要明記。
- **F-7**: `clearAllData` 中の `localStorage.removeItem` が極めて稀に例外を投げた場合の中間クラッシュ（settings だけ残る等）。現状は try/catch で吸収しているが、整合確認用のセルフチェックがあると安心。
- **v0.6.x 候補**: 大会／リーグ集計（旧 B2）、Fuse クエリの再チューニング（データ系記事削除により「CSV」等の短語が別記事に吸われる）。

## 8. 実機テストの始め方

1. `server.cfg` に `ensure RefBoard` を追加し FiveM サーバを起動。
2. クライアントで F6 を押し UI を開く。
3. 設定 → 表示名を入力 → ロケールとフォント倍率を確認。
4. チーム管理で 2 チーム以上作成、各チームにロスターを 5〜11 名追加。
5. 試合管理 → 新規作成 → ハーフ分数を 1 分などに短縮して時計動作を確認。
6. ゴール／カード／交代／PK／手動スコア／終了／再開を一通り確認。
7. F5 でリロードしてデータが永続していることを確認。
8. 不具合は `RefBoard/docs/diary/` にその日のファイルを起こして記録。

## 9. ロードマップ（v0.2.0 → v1.0.0）

- **v0.2.0（完了・2026‑05‑09）**: ヘルプ Fuse 再調整、ロスタイム入力許容、JSON インポート部分マージ。
- **v0.2.2（完了・2026‑05‑10）**: 小窓モード A（モーダル透過）、D‑1/D‑2（PK 表示・2 列 UI）、B（直近イベント）、C（小窓で操作者表示）、PK デモシード。Git タグ `v0.2.2`。
- **v0.2.x 残り**: `intro_setup` スクショは **F-1'** として将来（記事に画像が無いため差し替えではなく新規追加）。
- **v0.3.0（完了）**: **B1** CSV、**I** ヘルプ 22 本。タグ `v0.3.0`。
- **v0.3.1（完了）**: 疑似データ `reload` 廃止＋Pinia 再 hydrate、`downloadFile` の DOM クリック改善、小窓 `CompactEventList` 配置。タグ `v0.3.1`。
- **v0.3.2（完了）**: PK 中は下部固定 PK 専用ドック、試合詳細ヘルプを `HelpHoverDialog`、FiveM 向け CSV/JSON 不可の注意文。タグ `v0.3.2`。
- **v0.4.0（完了）**: **データ管理画面・CSV/JSON 機能の全削除**（BREAKING）。PK ドック 3 列化、`HelpHoverDialog` 内で記事遷移、赤牌 `note` 表示修正、イベント時刻プリセット。タグ **`v0.4.0`**。
- **v0.4.1（完了）**: 疑似データに **PK 進行中**試合「カップ戦 PK進行中（実機検証用）」を追加（live 3 件構成は維持）。タグ **`v0.4.1`**。
- **v0.5.0（完了・2026‑05‑10）**: F-2（`HelpHoverDialog` 統一）、F-3（`check:help`）、F-4（ロスタイム表示整理）、H-1/H-3/H-4/L-6/M-3/M-4。Git タグ **`v0.5.0`**。
- **v0.5.1（完了・2026‑05‑10）**: **L-5** — `Match.pkFirstTeamId` 永続化、`setPkFirstTeam`、PK パネルで直前取消・先攻再抽選、シード／ヘルプ／テスト追記。Git タグ **`v0.5.1`**。
- **v0.5.2（完了・2026‑05‑10）**: **緊急** — 0 名 vs 0 名で PK に入る脱出不能を防ぐ **入口バリデーション**（`pk-validation-failed`）、**PK 全体キャンセル**（`cancelPenaltyShootout` → `2H` 復帰・全 PK void）、i18n／ヘルプ／テスト **49→51** 件。Git タグ **`v0.5.2`**。
- **v0.6.0（完了・2026‑05‑10）**: **A** useNui の 5 秒 AbortController タイムアウト、**B** PK 確認系 3 関数の `isProcessing` ガード、**C** `clearAllData` の `NON_PREFIXED_KEYS` 定数化＋`rehydrate` 末尾呼び出し＋`resetCountersMemoryOnly` 切替、**D** README v0.4.0 注記の中立化、**E** `intro_setup` スクショ 4 枚＋`sanitizeHelpHtml` 拡張（`img` 許可）、テスト **51→55** 件。Git タグ **`v0.6.0`**。
- **v0.6.x 候補**: 大会／リーグ集計（旧 B2）、Fuse 再調整。
- **v0.9.0**: 実機テストシナリオ実施・記録、軽微不具合修正。
- **v1.0.0**: README 更新、デモ GIF、CHANGELOG 総括、配布 zip。

## 10. 次セッション開始フレーズ例

> リポジトリ: https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja の `RefBoard/`
> ローカル: H:\CURSOR\Dev\fivem-mods_ja\RefBoard
> 現状: v0.6.0。先端タグ `v0.6.0`（`v0.5.2` / `v0.5.1` / `v0.5.0` / `v0.4.x` タグも維持）。バックアップ UI なし（`localStorage` のみ）。`RefBoard_old/` は GitHub 非追跡の素材庫。
> 次着手候補: §7 の **F-3** / **F-5** / **F-7**、選手状態セルのタップ切替、Fuse クエリ再調整、大会／リーグ集計（旧 B2）。
> 引継資料: `RefBoard/docs/HANDOVER.md` 第 3 版、開発日記は `RefBoard/docs/diary/`。

短縮フレーズ: `小窓モードいって` / `F-3 いって`

## 11. 改版履歴

- 2026‑05‑09: 第 3 版起こし。v0.1.0（ローカル版リブート）に対応。旧版の §4〜§9（サーバ連動・編集ロック・実機テスト計画）を全面差し替え。
- 2026‑05‑09: v0.1.0 の `web/package.json`・`package-lock.json`・`src/constants/version.ts`（`REFBOARD_UI_VERSION`）を 0.1.0 へ同期。HANDOVER §3 と §7 を整合修正（版数揃えの Git ハッシュは `git log -1 --oneline -- RefBoard/web/package.json` で確認）。
- 2026‑05‑09: 試合詳細ヘッダに `selfName`（操作者）を表示。未設定時は Settings へ誘導するリンクを表示。小窓モードで `transparentChrome` のときはヘッダから非表示。
- 2026‑05‑09: 全データ JSON の **インポート UI**（置換／追記、置換はダイアログ内二段確認）、`import_history` 最大 20 件、ヘルプ `data_import` 追加。完了後は `location.reload()` で反映。
- 2026‑05‑09: ヘルプ Fuse.js を 16 本構成向けに再調整（`threshold` 0.4→0.35、`keys` に `slug` 追加と重み付け変更）。評価クエリリストを `docs/testing/help_search_queries.md` に新設。
- 2026‑05‑09: イベント時刻に `45+2` 入力（`matchTime.ts` / `MinuteInput.vue`）、表示・CSV 整形、PK 中の保存ルール、ヘルプ記事・`reverse_index` 追従。版数 v0.2.0（`package.json` / `fxmanifest` / `REFBOARD_UI_VERSION`）。
- 2026‑05‑09: JSON インポート **部分マージ**（`mergeImportPartial` / `ImportSelection`、`buildPreviewDetail`、履歴 `partial`）。
- 2026‑05‑10: vitest を devDependencies に追加し、`utils/matchTime.ts` の単体テストを新設（`parseMinuteInput`／`formatMinute`／`formatMinuteForCsv`）。`npm test` / `npm run test:watch` を導入。版数 v0.2.1。
- 2026‑05‑10: Settings の SQL／DB メタ表示を撤去。`dev/sampleData.ts` / `dev/seedActions.ts` によるローカル疑似データ投入・削除（版数 v0.2.2）。
- 2026‑05‑10: コンパクト小窓時のモーダル背後透過（A）。`useDialogOverlay.ts` を追加し各種ダイアログのオーバーレイに適用。
- 2026‑05‑10: PK 記録の表示不具合（D-1）。`stores/matches.ts::addEvent` は従来どおり `pk_goal` / `pk_miss` を保持するが、`utils/localMatchAdapter.ts::localEventToRow` が `text` を空のまま返していたため `PenaltyShootoutPanel` の記録リストと `EventTimelineCard` が空行に見えていた。PK 行に `⚽`／`失敗` と背番号・氏名（またはラベルのみ）を付与して修正。
- 2026‑05‑10: PK 入力 UI（D-2）。`PenaltyShootoutPanel` をホーム／アウェイ 2 列表示＋チーム別の選手選択・成功／失敗ボタンに変更。`localEventToRow` に `pkTeamId` 等を追加し `localMatchAdapter.test.ts` で PK 行を検証。
- 2026‑05‑10: 小窓モードに `CompactEventList`（直近イベント・新しい順・8rem スクロール）と操作者 1 行（C）を追加。`SeedMatch.pkDemo` による PK デモ試合を疑似データに 1 件組み込み。Git タグ `v0.2.2`。
- 2026‑05‑10: **B1** 試合 CSV 拡充（サマリ 9 列＋イベント標準 13 / 詳細 26 列、2 ファイル連続 DL）。版数 **v0.3.0**。`exporters.test.ts` 追加。
- 2026‑05‑10: **I** ヘルプ 22 本化（`data_csv_format` / `data_csv_excel_open` / `data_migration` / `match_pk_recording` / `compact_dock_usage` / `troubleshooting_event_disappears`）。`index.json`・`reverse_index.json`・`context_map.json`・Fuse 評価クエリを更新。Git タグ **`v0.3.0`**（コミット `5c456d8`）。
- 2026‑05‑10: **v0.3.1** 疑似データ操作から `location.reload` を除去し Pinia 再 hydrate、`localPersist.saveLocalBatch` と `localId` バッチ、`downloadFile` の DOM 追加クリック、小窓の直近イベントを前後半カード列下へ。Git タグ **`v0.3.1`**。
- 2026‑05‑10: **v0.3.2** PK 戦を常に下部固定の専用ドックで表示、`HelpHoverDialog`、データ管理に FiveM エクスポート不可の注記。Git タグ **`v0.3.2`**。
- 2026‑05‑09: **v0.4.0** データ管理・CSV/JSON・関連ヘルプ削除（破壊的変更）。PK 3 列 UI、ヘルプモーダル内ナビ、赤牌表示、試合分プリセット、`eventMinutePresetFromClock` テスト追加。Git タグ **`v0.4.0`**。
- 2026‑05‑09: **v0.4.1** PK 進行中のシード試合追加（`SeedMatch.pkInProgress`／`seedActions`）。版数と README バッジを 0.4.1 に同期。Git タグ **`v0.4.1`**。
- 2026‑05‑09: **v0.5.0 作業** — F-1（intro_setup スクショ更新）は記事に画像が無いため **v0.5.0 スコープ外**、**F-1'** として CHANGELOG Future に記録。F-2: `MatchList`／`TeamManage`／`Settings` に `HelpHoverDialog` を展開し `ContextHelpPanel` 系を削除。`context_map.json` に `match_list`、`settings` の記事拡充。
- 2026‑05‑09: **v0.5.0 F-4** — `formatMinute` で stoppage 0 を `+0` なしに統一（`0+0'` 解消）。`EventMinuteColumn` でロスタイムを強調色表示。`MinuteInput` の `+0` 表記省略。
- 2026‑05‑10: **v0.5.0 リリース**。F-3（ヘルプ整合チェック）、F-2（`HelpHoverDialog` 統一）、F-4（ロスタイム表示整理）に加え、脆弱性・バグ修正 **H-1** / **H-3** / **H-4** / **L-6** / **M-3** / **M-4** を反映。テスト **37 → 43** 件。**F-5** は事前調査で **L-5**（PK 先攻選択 UI）が真の課題と判明したためスコープ外、v0.5.1+ で対応。Git タグ **`v0.5.0`**。
- 2026‑05‑10: **v0.5.1 リリース**。**L-5** `pkFirstTeamId`・`setPkFirstTeam`・PK リカバリ UI、シード／i18n／ヘルプ追記。テスト **43 → 49** 件。Git タグ **`v0.5.1`**。
- 2026‑05‑10: **v0.5.2 リリース（緊急）**。PK 入口バリデーション（両チーム 1 名以上）、`cancelPenaltyShootout`（PK 全 void・`2H` 復帰）、i18n／ヘルプ／CHANGELOG 追記。テスト **49 → 51** 件。Git タグ **`v0.5.2`**。
- 2026‑05‑10: **v0.6.0 リリース**。**A** `useNui::postToLua` 5 秒 `AbortController` タイムアウト＋エラー詳細。**B** PK 確認系 3 関数（`confirmUndoLast` / `confirmReroll` / `confirmCancelAll`）に `isProcessing` ガード。**C** `clearAllData` を `NON_PREFIXED_KEYS` 定数化＋末尾 `rehydrate`＋`resetCountersMemoryOnly` に切替。**D** README ja/en の v0.4.0 注記を中立見出し＋過去形へ。**E** `intro_setup`（ja/en）に 4 枚スクショ挿入、`sanitizeHelpHtml` で `img`＋src/alt/width/height/loading/decoding 許可、画像は `web/public/help/intro_setup/01〜04-*.png` に配置。テスト **51 → 55** 件（`dev/seedActions.test.ts` 新設、最小 localStorage モック）。Git タグ **`v0.6.0`**。
