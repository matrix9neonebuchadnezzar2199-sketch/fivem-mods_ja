# RefBoard 引継資料（第 3 版・ローカル版）

- **作成日**: 2026‑05‑09
- **対象バージョン**: v0.2.0（ローカル専用・運用品質更新）
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

## 3. ディレクトリ構成（v0.2.0）

```
RefBoard/
├─ fxmanifest.lua          version '0.2.0'
├─ config.lua              OpenKey, DefaultLocale のみ
├─ client/main.lua         NUI 開閉と /refboard コマンド
├─ shared/constants.lua    リソース名等の定数のみ
├─ docs/
│  ├─ HANDOVER.md          本書
│  └─ diary/               2026‑05‑09_local_reboot.md ほか
├─ CHANGELOG.md
├─ README.md
└─ web/
   ├─ package.json         version 0.2.0（`REFBOARD_UI_VERSION`・fxmanifest と整合）
   ├─ index.html           rootFontScale FOUC 対策インラインスクリプト
   ├─ vite.config.ts       manualChunks（旧 v0.8.6 設定を踏襲）
   └─ src/
      ├─ main.ts           refboard:setOpen 受信、未処理例外トースト
      ├─ App.vue           settings.load() のみ
      ├─ router/index.ts
      ├─ types/local.ts    Match/Team/Player/Event/ScoreHistory 型
      ├─ stores/
      │  ├─ matches.ts     試合 CRUD、時計、イベント、PK、手動編集、終了/再開
      │  ├─ teams.ts       チーム CRUD、ロスター
      │  ├─ settings.ts    selfName, locale, fontScale, marquee 等
      │  └─ matchCompactDock.ts
      ├─ composables/useNui.ts    close/コンパクト関連のみ POST、他はダミー
      ├─ utils/
      │  ├─ localPersist.ts       localStorage ラッパ（v=1）
      │  ├─ localId.ts            ID カウンタ
      │  ├─ matchTime.ts          イベント時刻 `45+2` パース／表示／CSV 用整形
      │  ├─ localMatchAdapter.ts  Match → MatchDetailModel ブリッジ
      │  ├─ exporters.ts          CSV／全データ JSON バックアップ／`buildPreviewDetail`
      │  ├─ localImport.ts        JSON インポート（replace／merge／部分 merge）と取り込み履歴
      │  └─ errorCodeMapper.ts    E2001/E3004/E3006 のみ
      ├─ components/
      │  ├─ match/MinuteInput.vue  イベント時刻（分＋ロスタイム）入力
      │  └─ data/ImportBackupDialog.vue  JSON 取り込みウィザード
      ├─ views/
      │  ├─ Launcher.vue          表示名入力 → 試合一覧へ
      │  ├─ MainLayout.vue        sidebar + RouterView + ContextHelpPanel
      │  ├─ MatchList.vue         一覧／検索／削除／新規作成
      │  ├─ MatchDetail.vue       時計／ゴール／カード／交代／PK／手動編集／終了
      │  ├─ TeamManage.vue        チームとロスター
      │  ├─ DataManage.vue        終了試合一覧、CSV、全データ JSON バックアップ／取り込み／履歴
      │  ├─ Settings.vue          表示名／locale／fontScale／marquee／背景
      │  └─ HelpView.vue          目次／逆引き／検索／コンテキスト
      ├─ help/
      │  ├─ ja/articles/          16 本（intro 2／match 7／team 2／data 3／trouble 2 ※統合済）
      │  ├─ en/articles/          同上
      │  ├─ ja|en/index.json      🔧 は trouble_undo_goal と trouble_e3006_player_has_events のみ
      │  ├─ ja|en/reverse_index.json
      │  └─ context_map.json
      └─ i18n/{ja,en}.json        presence/autosave/lock/health/session 系は削除済み
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

- **永続化**: `utils/localPersist.ts` がキーごとに `{ version: 1, data }` 形式で `localStorage` に書き、各ストアが `watch(deep)` で自動保存。`dumpAllLocal()` が全データ JSON バックアップの土台。
- **JSON インポート**: `replace`（全削除→全書き込み）と `merge`（`nextId` で ID を払い直し追記、`settings` は現端末のまま）。`merge` ではチーム／ロスター／試合の 3 系列を個別選択でき、試合を選ぶとホーム/アウェイチームと登場ロスターが自動同伴（`autoIncludeRelated`、既定 ON）。取り込み履歴は端末内 20 件まで保持し、`partial` フラグで部分マージを区別。UI は `components/data/ImportBackupDialog.vue`、プレビュー詳細は `exporters.buildPreviewDetail`。完了後は **ページ再読み込み** で Pinia を再 hydrate。
- **ID 採番**: `utils/localId.ts` が match/team/player/rosterMember/event/scoreHistory のカウンタを `id_counters` キーで管理。
- **時計**: `matches` ストアの `clockStartedAt`（停止時 null）と `clockAccumulatedMs` の合算で `clockNowMs(m)` を算出。UI 側は 250ms ポーリングで表示のみ更新し、保存はストアが担当。
- **得点ロジック**: `addEvent` で `goal`/`pk_goal` を加算、`voidEvent` で減算。手動スコアは `manualScoreEdit` が `scoreHistory` に履歴を残しつつ `homeScore`/`awayScore` を上書き。
- **NUI 通信**: `useNui().send('close')` 等のコンパクト関連だけ Lua にPOST。他はブラウザ／FiveM ともに `{ ok: true }` を返すスタブ。`on()` は `refboard:compact_input_mode` のみ window.message 経由で購読。
- **ヘルプ**: ja/en 各 16 本。緊急度高（🆘）と診断（🩺）カテゴリは廃止し、🔧 トラブル配下に `trouble_undo_goal` と `trouble_e3006_player_has_events` の 2 本のみ。`errorCodeMapper.ts` は `E2001`/`E3004`/`E3006` のみ保持。
- **ヘルプ検索**: `utils/helpSearch.ts` の Fuse.js 設定で `threshold: 0.35` / `minMatchCharLength: 2` / `ignoreLocation: true` / `keys: title(0.5) tags(0.3) slug(0.1) body(0.1)`。評価クエリは `docs/testing/help_search_queries.md`。再現用に `web/scripts/eval-help-fuse.mjs` あり。
- **試合時刻入力**: `utils/matchTime.ts::parseMinuteInput` で `45` / `45+2` / `45＋2` を受理し、`{ minute, stoppage }` として保存。表示は `formatMinute`（`45+2'`）と `formatMinuteForCsv`（`45+2`）で分岐。PK 中のフィールドプレーイベントは `minute=0` / `stoppage=null`、PK シュートのみラベル `PK`。

## 6. 開発・ビルド・配布

```bash
cd RefBoard/web
npm install
npm run dev          # ブラウザ単体プレビュー
npm run build        # web/dist 出力（FiveM 配布物）
npx vue-tsc --noEmit # 型チェック
```

`fxmanifest.lua` は `web/dist/index.html` と `web/dist/**/*` をパッケージ。`server.cfg` には `ensure RefBoard` の 1 行のみ（`oxmysql` も ACE も不要）。`Config.OpenKey`（既定 F6）と `Config.DefaultLocale`（既定 `ja`）だけ設定可能。

## 7. 既知の TODO（v0.2.0 時点）

- PK キャンセル UI、選手状態セルのタップ切替、`Ctrl+Z` でゴール取消ショートカット。
- `intro_setup` のスクリーンショット差し替え（旧版のままなら更新）。

## 8. 実機テストの始め方

1. `server.cfg` に `ensure RefBoard` を追加し FiveM サーバを起動。
2. クライアントで F6 を押し UI を開く。
3. 設定 → 表示名を入力 → ロケールとフォント倍率を確認。
4. チーム管理で 2 チーム以上作成、各チームにロスターを 5〜11 名追加。
5. 試合管理 → 新規作成 → ハーフ分数を 1 分などに短縮して時計動作を確認。
6. ゴール／カード／交代／PK／手動スコア／終了／再開を一通り確認。
7. データ → CSV と全データ JSON バックアップを取得。
8. F5 でリロードしてデータが永続していることを確認。
9. 不具合は `RefBoard/docs/diary/` にその日のファイルを起こして記録。

## 9. ロードマップ（v0.2.0 → v1.0.0）

- **v0.2.0（完了・2026‑05‑09）**: ヘルプ Fuse 再調整、ロスタイム入力許容、JSON インポート部分マージ。
- **v0.2.x（短期）**: コンパクト小窓モードの再評価、`intro_setup` スクショ更新、ロスタイム単体テスト導入（vitest 検討）。
- **v0.3.0（中期）**: 集計・大会／リーグ、CSV 拡充、ヘルプ拡充。
- **v0.9.0**: 実機テストシナリオ実施・記録、軽微不具合修正。
- **v1.0.0**: README 更新、デモ GIF、CHANGELOG 総括、配布 zip。

## 10. 次セッション開始フレーズ例

> リポジトリ: https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja の `RefBoard/`
> ローカル: H:\CURSOR\Dev\fivem-mods_ja\RefBoard
> 現状: v0.2.0（Fuse・ロスタイム入力・JSON 部分マージまで反映）。`RefBoard_old/` は GitHub 非追跡の素材庫。
> 次着手候補: PK キャンセル UI、コンパクト小窓再評価など §7 TODO のいずれか。
> 引継資料: `RefBoard/docs/HANDOVER.md` 第 3 版、開発日記は `RefBoard/docs/diary/`。

短縮フレーズ: `小窓モードいって` / `PK キャンセルいって`

## 11. 改版履歴

- 2026‑05‑09: 第 3 版起こし。v0.1.0（ローカル版リブート）に対応。旧版の §4〜§9（サーバ連動・編集ロック・実機テスト計画）を全面差し替え。
- 2026‑05‑09: v0.1.0 の `web/package.json`・`package-lock.json`・`src/constants/version.ts`（`REFBOARD_UI_VERSION`）を 0.1.0 へ同期。HANDOVER §3 と §7 を整合修正（版数揃えの Git ハッシュは `git log -1 --oneline -- RefBoard/web/package.json` で確認）。
- 2026‑05‑09: 試合詳細ヘッダに `selfName`（操作者）を表示。未設定時は Settings へ誘導するリンクを表示。小窓モードで `transparentChrome` のときはヘッダから非表示。
- 2026‑05‑09: 全データ JSON の **インポート UI**（置換／追記、置換はダイアログ内二段確認）、`import_history` 最大 20 件、ヘルプ `data_import` 追加。完了後は `location.reload()` で反映。
- 2026‑05‑09: ヘルプ Fuse.js を 16 本構成向けに再調整（`threshold` 0.4→0.35、`keys` に `slug` 追加と重み付け変更）。評価クエリリストを `docs/testing/help_search_queries.md` に新設。
- 2026‑05‑09: イベント時刻に `45+2` 入力（`matchTime.ts` / `MinuteInput.vue`）、表示・CSV 整形、PK 中の保存ルール、ヘルプ記事・`reverse_index` 追従。版数 v0.2.0（`package.json` / `fxmanifest` / `REFBOARD_UI_VERSION`）。
- 2026‑05‑09: JSON インポート **部分マージ**（`mergeImportPartial` / `ImportSelection`、`buildPreviewDetail`、履歴 `partial`）。
