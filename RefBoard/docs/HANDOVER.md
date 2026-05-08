# RefBoard 引継資料（HANDOVER）— 第 2 版

**作成日**: 2026-05-08（同日中の大幅改訂）
**初版作成時点**: v0.6.7（Sprint 09 Phase C 完了直後）
**第 2 版時点**: **v0.8.5**（Sprint 09 完了済み・運用フェーズ・フォント Settings・`E3006` ヘルプまで反映）
**作成時点のリポジトリ**: `origin/main`、`fxmanifest.lua` の `version '0.8.5'`、`CHANGELOG.md` 先頭が v0.8.5

---

## 0. 第 2 版で変わったこと（読み飛ばし可）

初版（v0.6.7 時点）は「Sprint 09 Phase D を次にやる」前提で書かれていたが、その後の同日中に Phase D / E（v0.6.8 / v0.7.0）でヘルプ Sprint 09 をクローズし、さらに **v0.7.1〜v0.8.3 まで 12 リリースぶんの不具合修正と運用改善**が積まれた。第 2 版ではリリース履歴・ディレクトリ・既知 TODO・ロードマップを現状（v0.8.5）に合わせて全面更新している。初版にあった「Phase D の記事 8 本」「Phase E の英語化」は**すでに完了済み**として閉じた。

- 2026-05-09 追記: v0.8.4（フォント倍率 Settings 化）完了に合わせて §4 / §7 / §9 / §10 を微修正。
- 2026-05-09 追記: v0.8.5（`E3006` ヘルプ記事と配線）完了に合わせて §4 / §7 / §9 / §10 を微修正。

---

## 1. プロジェクト概要

RefBoard は FiveM サーバー向けのサッカー試合管理リソース。oxmysql + Vue 3 / Vite NUI で構成され、複数審判によるスコア・選手・カード・PK 戦の同時編集（編集ロック付き）と、編集ログの append-only 保存を提供する。

リポジトリは `https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja`、作業ディレクトリは `RefBoard/`、ローカルパスは `H:\CURSOR\Dev\fivem-mods_ja\RefBoard`、ライセンスは MIT。

採用技術はサーバー側が FiveM Lua + oxmysql、NUI が Vue 3.5 / Vite 6 / TypeScript 5.7 / Tailwind 3.4 / Pinia / Vue Router / vue-i18n、ヘルプが marked + dompurify + fuse.js 7.3。

---

## 2. 開発環境

```bash
# NUI 開発
cd RefBoard/web
npm install
npm run dev    # ブラウザ単体（nuiMock + localStorage で動作）
npm run build  # FiveM 配布用（dist/）

# 実機（FiveM）
# server.cfg に: ensure oxmysql / ensure RefBoard
# DB 初期化: v0.7.4 以降は ensure 時に editor_locks 不在を検知して install.sql を自動実行（Config.AutoCreateSchema=true、既定）。
#            手動でやる場合は: mysql -u USER -p fivem_db < RefBoard/sql/install.sql
# テストデータ（5 チーム × 15 人）: Config.SeedDemoTeamsOnStart=true で起動時に自動投入（v0.8.3）。
#                                 不要なら false。CLI 投入も従来どおり可（idempotent）。
```

ブラウザ単体時は `nuiMock` が `localStorage` 永続化付きで CRUD を再現する。`window.__refboardMock`（DEV のみ）でリセット・ダンプ可能。**`STORAGE_VERSION` は現在 3**（v0.8.1 で 1→2、v0.8.3 で 2→3）。古い localStorage を引きずっている開発者は一度リセットすれば新シードが入る。

リリース時にバージョンを必ず一致させる箇所は、`RefBoard/web/package.json` の `version`、`RefBoard/fxmanifest.lua` の `version`、`RefBoard/web/src/constants/version.ts`（`REFBOARD_UI_VERSION`、サイドバー表示・ログに使用）の 3 つ。

---

## 3. ディレクトリ構成（v0.8.5 現在）

```
RefBoard/
├── fxmanifest.lua                  # version '0.8.5'、files に seed_test_5teams_15roster.sql を含む
├── config.lua                      # AutoCreateSchema / SeedDemoTeamsOnStart / EnableTestCommands など
├── CHANGELOG.md
├── server/
│   ├── lock.lua                    # 数値 ID 統一（v0.6.3）、pcall 包み（v0.7.2）、license 一致で奪い返し（v0.7.1）
│   ├── schema_bootstrap.lua        # editor_locks 不在検知 → install.sql 自動実行（v0.7.4）
│   ├── demo_seed.lua               # 5 チーム × 15 人シード自動投入（v0.8.3）
│   ├── match.lua / score.lua / event.lua / player.lua / team.lua / data.lua
│   ├── clock.lua                   # 試合時計（v0.7.x で分離・現存）
│   ├── presence.lua / health.lua / autosave.lua / permission.lua / db.lua / util.lua / main.lua
│   └── test/transaction_test.lua
├── shared/
│   ├── error_codes.lua             # E1xxx〜E5xxx + E3006（player_has_events、v0.8.0）
│   └── constants.lua
├── sql/
│   ├── install.sql
│   ├── seed_dev_teams.sql
│   ├── seed_test_5teams_15roster.sql   # v0.8.1 追加・v0.8.3 から自動実行可能
│   └── migration_001 〜 004_*.sql
├── docs/
│   ├── 01_database.md / 02_server.md / 03_frontend.md / 04_design_mockup.md
│   ├── error_handling.md / help_system_design.md
│   ├── USER_GUIDE.md / USER_GUIDE.en.md
│   ├── HANDOVER.md                 # 本ファイル
│   ├── sprints/sprint_02 〜 09_*.md
│   ├── sprints/sprint_07_uiux_findings.md
│   ├── sprints/sprint_08_marquee.md
│   └── testing/{release_test_plan, test_results, known_issues, transaction_test}.md
└── web/
    ├── package.json                # version 0.8.5
    └── src/
        ├── views/
        │   ├── MainLayout.vue          ← ContextHelpPanel をここでマウント、ロックハートビートもここから
        │   ├── MatchDetail.vue / MatchList.vue / TeamManage.vue
        │   ├── DataManage.vue / Settings.vue / HelpView.vue / HealthCheck.vue
        │   └── Launcher.vue
        ├── components/
        │   ├── common/MarqueeText.vue
        │   ├── help/{HelpTriggerButton, ContextHelpPanel}.vue
        │   ├── match/{ScoreBoardCard, PlayerListCard, EventTimelineCard, ...}.vue
        │   ├── team/*
        │   └── Toast.vue / AutosaveIndicator.vue / PresenceBadge.vue ほか
        ├── stores/{session, autosave, presence, settings, contextHelp, matchCompactDock}.ts
        ├── utils/{errorCodeMapper, helpSearch, helpLocale, mapMatchFromServer,
        │          exporters, formatDate, lockAcquireErrors, marqueeVariants}.ts
        ├── composables/{useNui, useHeartbeat, useFocusTracker, useToast, useKeyboardShortcuts}.ts
        ├── directives/marquee.ts
        ├── styles/{marquee, score-flash}.css
        ├── i18n/{ja, en}.json
        ├── constants/version.ts
        ├── help/
        │   ├── context_map.json
        │   ├── ja/
        │   │   ├── index.json              # ツリー目次（v0.7.0 で HelpView に配線済み）
        │   │   ├── reverse_index.json
        │   │   └── articles/*.md           # 日本語 21 本（v0.8.5 で E3006 記事を追加）
        │   └── en/
        │       ├── index.json
        │       ├── reverse_index.json
        │       └── articles/*.md           # 英語 21 本（v0.8.5 で E3006 記事を追加）
        └── mocks/{nuiMock, mockPersistence, matchDetail}.ts
```

`web/src/layouts/` ディレクトリは存在しない。`MainLayout.vue` は `web/src/views/` 直下にある（初版でも注記済み・継続有効）。

---

## 4. リリース履歴（要約・v0.8.5 まで）

| 版 | 日付 | 主内容 |
|----|------|-------|
| v0.1.0 〜 v0.5.1 | 05-05 〜 05-06 | 基盤 → 試合 CRUD → ロック / オートセーブ → ゴール / カード / 交代 / PK → CSV / 設定 → トリアージツール |
| v0.6.0 | 05-06 | アプリ内ヘルプ Phase 1（記事 4 本・Toast → 記事誘導） |
| v0.6.1 | 05-06 | Sprint 08 マーキー全フェーズ完了・score-flash |
| v0.6.2 〜 v0.6.4 | 05-07 | NUI シェル・ロック型ずれ・透明背景の重大バグ連続修正 |
| v0.6.5 | 05-08 | ヘルプ Phase A — 試合中記事 8 本（計 12 本） |
| v0.6.6 | 05-08 | ヘルプ Phase B — Fuse.js 検索 |
| v0.6.7 | 05-08 | ヘルプ Phase C — コンテキスト `?` パネル（4 画面） |
| v0.6.8 | 05-08 | ヘルプ Phase D — 日本語記事 20 本完成・`team_manage` / `data_manage` の `?` 配線 |
| **v0.7.0** | 05-08 | **ヘルプ Phase E — 英語 20 本・ロケール連動・目次ツリー配線。Sprint 07 受け入れ基準クリア** |
| v0.7.1 | 05-08 | 編集ロック奪い返し（同 license）・`session:leave` 強制解放・`playerDropped` 直 UPDATE・ハートビートを `MainLayout` へ移動 |
| v0.7.2 | 05-08 | `editor_locks` 未作成 DB でも `ensure` で落ちない（`lock.lua` 全面 `pcall`） |
| v0.7.3 | 05-08 | ロック取得時の `db_query_failed` を「他ユーザー編集中」モーダルに出さない（`lockAcquireErrors.ts`） |
| v0.7.4 | 05-08 | `schema_bootstrap.lua` 追加 — `editor_locks` 不在時に `install.sql` 自動実行（`Config.AutoCreateSchema`） |
| v0.7.5 | 05-08 | NUI 再表示時・ルート切替時に `lock_acquire`+`match_get` を再送、`matchId` 数値比較統一、閲覧モード時計トースト |
| v0.7.6 | 05-08 | 日付正規化 `formatDate.ts`、カード登録の無反応修正（タイムアウト・スクリプト側 ref 代入）、チーム詳細を 50% 幅 |
| v0.7.7 | 05-08 | スタジアム小窓に Ctrl+B / B での UI⇔ゲーム切替、ヘッダー帯透明化 |
| v0.7.8 | 05-08 | 小窓の全幅紺色帯廃止、復帰ボタン・案内文を約 2 倍に |
| v0.7.9 | 05-08 | 試合時計の「一時停止」をラベル付きピル型に、`clock_stop_aria` / `clock_clear_aria` 整理 |
| v0.8.0 | 05-08 | ルート `font-size` 200%→150%、ロスター 50% 幅、`teamDetailSeq` で古い ack 無視、`applyState` を `!= null` 判定、試合メンバー削除（`E3006`） |
| v0.8.1 | 05-08 | NUI モックを 5 チーム × 15 人に拡張、`STORAGE_VERSION` 1→2、`sql/seed_test_5teams_15roster.sql` 追加 |
| v0.8.2 | 05-08 | ルート `font-size` 150%→200% に戻す（CEF フィードバック） |
| **v0.8.3** | 05-08 | **`server/demo_seed.lua` で 5 チーム × 15 人 SQL を自動実行（`Config.SeedDemoTeamsOnStart`）。`STORAGE_VERSION` 2→3** |
| v0.8.4 | 05-09 | フォント倍率を Settings から切替（100/150/200%、既定 200）。`html.style.fontSize` を JS で動的反映、FOUC は `index.html` インラインで先読み |
| v0.8.5 | 05-09 | `E3006`（`player_has_events`）専用ヘルプを日英追加。`errorCodeMapper` / `reverse_index` / `index` / `context_map`（`match_detail`）に配線 |

詳細は `RefBoard/CHANGELOG.md` を参照。

---

## 5. Sprint 09 の最終結果（クローズ済み）

Sprint 09（v0.6.5 〜 v0.7.0）はすべて完了。当初スコープの「日本語記事 20 本」「英語版」「Fuse.js 検索」「コンテキスト `?`」「目次ツリー配線」「USER_GUIDE 更新」をすべて満たし、Sprint 07 の積み残しもクローズ済み。

| 版 | フェーズ | 状態 |
|----|---------|------|
| v0.6.5 | A — 試合中記事 8 本 | ✅ |
| v0.6.6 | B — Fuse.js 検索 | ✅ |
| v0.6.7 | C — コンテキストヘルプ | ✅ |
| v0.6.8 | D — 準備＋周辺記事 8 本 | ✅ |
| v0.7.0 | E — 英語版 20 本＋ locale 切替＋ USER_GUIDE | ✅ |

Sprint 09 完了後、運用上見つかった重大不具合への即応として v0.7.1〜v0.7.5（編集ロック・DB ブートストラップ・時計同期）を集中投入し、その後 UI 微調整・小窓改善・チーム管理改善・テストデータ拡充というフェーズに移行している。

---

## 6. v0.8.5 時点で動いている重要な仕組み

第 2 版で新たに「忘れやすいので明文化」した設計上の決定。

**DB ブートストラップ（v0.7.4）**: `server/schema_bootstrap.lua` が起動時に `information_schema` で `editor_locks` の有無を確認し、不在のときだけ `install.sql` を自動実行する。`Config.AutoCreateSchema`（既定 `true`）で無効化可能。既存 DB の列追加は引き続き手動 migration。

**テストデータ自動投入（v0.8.3）**: `server/demo_seed.lua` が `Config.SeedDemoTeamsOnStart=true` のとき `teams` テーブル準備をポーリングし、`sql/seed_test_5teams_15roster.sql` を自動実行する。本番は `false`。SQL 自体は idempotent（同名チーム・既存ロスターはスキップ）。

**編集ロック（v0.6.3 / v0.7.1 / v0.7.2 / v0.7.5 で完成形）**: `editor_locks.holder_server_id` は数値統一（`tonumber()` 比較）。同 license で再接続したらロックを奪い返す（幽霊ロック防止）。`session:leave` でも保持者なら必ず解放。`playerDropped` で `readRow` が落ちても `holder_server_id = source` 行を直 UPDATE。`lock.lua` の DB 操作はすべて `pcall` で包む。NUI 側はハートビートを `MainLayout` で送る（試合詳細以外でも 30 秒タイムアウトでロックが切れない）。NUI 再表示時とルート切替時に `lock_acquire` + `match_get` を再送する。

**フォーカス／シェル（v0.6.2 〜 v0.6.4）**: `html` / `body` は透明、シェル背景は `App.vue` 表示中のみ。`onClientResourceStart` で `setOpen(false)` を必ず実行。F6 / `refboard:close` で `lock_release` + `session_leave` を必ず送る。

**マーキー（Sprint 08）**: 常時マーキーで全文表示（`text-overflow: ellipsis` は使わない）が確定方針。複数行同時マーキーは設計意図として明文化済み。`flex` / `grid` 配下では必ず `min-w-0`、親に `overflow-hidden`、固定幅要素に `shrink-0`。詳細は `docs/sprints/sprint_08_marquee.md`。

**エラーコード**: 構造化 `code`（E1xxx〜E5xxx）+ `error`（レガシー文字列）の両持ち。NUI 側の `errorCodeMapper.ts` が両方から記事 slug を解決。現状の主要マッピングは `E1003 → trouble_e1003_lock_held`、`E2005 → match_manual_score_edit`、`E3006 → trouble_e3006_player_has_events`、`E4003 / tx_failed → trouble_autosave_failed`。

**フォント倍率（v0.8.4）**: v0.8.0 / v0.8.2 でルート `font-size` を往復したのち、**v0.8.4 で `Settings` から 100% / 150% / 200% を選択**可能にした。`stores/settings.ts` の `rootFontScale`（`localStorage` の `refboard_settings`）と `App.vue` の `watchEffect` で `html.style.fontSize` を更新。初回 FOUC は `web/index.html` の `<head>` インラインで `localStorage` を先読み。

**ロックと再編集**: `editor_locks` はハートビートタイムアウトで自動解放。`Match.reopen` で finished → in_progress に戻せる（`reopened_*` 記録）。再編集は何度でも可能、最後の reopen のみカラムに残る（履歴は `edit_logs`）。

---

## 7. 既知の TODO（v0.8.5 時点で未消化）

`docs/sprints/sprint_07_uiux_findings.md` 集約のものから、初版以降にも消えていない項目を抽出。

ヘルプ／検索系で残っているのは「Fuse.js のしきい値再評価」（記事 20 本完成後の再チューニング、`tags` を厚めにする運用で当面吸収）と「`📚 項目ごと` バッジはツリー二重インデックス未実装のまま」。

UI 機能で未着手なのが、PK 戦のキャンセル / 先攻チーム間違いの取り消し UI（Sprint 10 候補）、ロスタイム表記（`45+2` 等）の入力許容、手動スコア編集での PK 内訳の直し、選手状態セルのタップ切替（出場 → 警告中…、監査ログ付き専用 NetEvent が必要）、オートセーブ失敗時の「再試行」ボタン配線、ゴール取消の `Ctrl+Z` ショートカット配線。

v0.8.x で残る新規 TODO として、ビルド警告で出ている `index.js` 肥大化のチャンク分割、`STORAGE_VERSION` 上げに伴う開発者向け案内（READMEで一行触れる程度でよい）の 2 点。

---

## 8. テストとリリース手順

コミット前は `cd RefBoard/web && npm run build` を緑にする。`npx vue-tsc --noEmit` も Sprint 09 以降は緑を維持しているので、回帰させない。マーキー実装と型エラーは混在させない（Sprint 08 の教訓）。

実機テスト（v0.9.0 で本格化予定）は `docs/testing/release_test_plan.md` をベースにし、`Config.EnableTestCommands = true` で `refboard_test_transaction` などの破壊系コマンドを使う。設定 → 「ヘルスチェック（実機テスト前）」で DB / 認証 / ロック状態を一覧確認できる。

コミットメッセージは `feat(RefBoard): <要約> (vX.Y.Z)`、`fix(RefBoard): <要約>`、`chore(RefBoard): <要約>` を踏襲。push 先は `origin/main`（個人管理リポジトリ・直 push 運用）。リリース時は `package.json` / `fxmanifest.lua` / `web/src/constants/version.ts` の 3 点を必ず同期。

---

## 9. 次の作業ロードマップ（v0.8.5 → v1.0.0）

Sprint 09 完了で「ヘルプ系」は一段落、v0.7.x で「ロック・DB ブートストラップ系」も区切り、v0.8.x で「テストデータ・運用整備」も入った。ここからは **実機テストに向けた残課題の刈り取り** と **ユーザー要望ベースの小改善** が主軸になる。

### 短期（v0.8.6 想定 / 1 リリース 1〜3 項目）

**v0.8.4（完了・2026-05-09）**: フォント倍率を Settings から切替可能に。詳細は CHANGELOG / §4 参照。

**v0.8.5（完了・2026-05-09）**: `E3006`（`player_has_events`）専用記事を日英で追加し、`errorCodeMapper` / `reverse_index` / `index` / `context_map` に配線。詳細は CHANGELOG / §4 参照。

UI 設定の作り込みと、v0.8.x で残した「記事側で吸収しきれていない」TODO を片付けるフェーズ。

**v0.8.6（次の作業）— ビルドチャンク分割**: 現状 `index.js` が肥大化して Vite が警告を出している。`vite.config.ts` の `build.rollupOptions.output.manualChunks` で `vue-router` / `pinia` / `vue-i18n` / `marked` + `dompurify` / `fuse.js` / ヘルプ記事 glob を分割し、警告を消す。受け入れ基準は「`npm run build` が警告なし」「FiveM 実機でも従来どおり起動する（NUI ロード時に複数チャンクをフェッチできる）」。

### 中期（v0.9.0 〜 v0.9.1 / 実機テストフェーズ）

**v0.9.0（実機テスト・結果記録）**: `docs/testing/release_test_plan.md` のシナリオを実機で消化し、結果を `docs/testing/test_results.md` に記録。`Config.EnableTestCommands=true` で `refboard_test_transaction` 等を回す。`docs/testing/known_issues.md` に新規発見を追記。複数審判による同時編集・編集ロックの取り合い・F6 開閉のフォーカス・小窓と歩行モードの切替・PK 戦・ハーフ別スコア・`Match.reopen` を最低限通す。

**v0.9.1（findings 反映）**: 実機テストで出た不具合のうち軽微なものをまとめて修正。Sprint 10 候補として残していた **PK 戦のキャンセル UI** と **ロスタイム `45+2` 入力許容** をここに合流させるか、別途 v0.9.2 として切るかを v0.9.0 の結果で判断する。findings の中で「監査ログ付き NetEvent が必要なもの」（選手状態セルのタップ切替、ゴール取消ショートカット）はスコープが大きいので v0.9.1 ではなく v1.x に回す。

### 長期（v1.0.0 / 正式リリース）

**v1.0.0**: USER_GUIDE 最終更新、デモ GIF（任意）、CHANGELOG の総括セクション追加、README に v1.0 機能サマリ。Sprint 07 / 08 / 09 / 実機テストの **完了宣言**を CHANGELOG と README で明記。`Config.SeedDemoTeamsOnStart` の既定を `false` にするかは要判断（本番想定なら false が安全だが、配布時のオンボーディング体験は true のほうが良い）。

### 任意で挟みうる枠

ユーザー要望で頻出したら前倒しする候補として、選手状態セルのタップ切替（要 NetEvent 設計）、`Ctrl+Z` ゴール取消（記事・ツールチップ・設定の三方同期が必要）、オートセーブ失敗時の「再試行」ボタン配線（記事側はすでに「設定 → ヘルスチェック」で吸収済みなので、ボタン配線時に記事追記）、手動スコア編集の PK 内訳対応（運用ルールで縛る案も並行検討）。

---

## 10. 次セッションでの開始フレーズ例

新しいセッション・新しい作業者への引継ぎはこう書けば即復元できる。

> **管理場所**: `https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja/tree/main/RefBoard`
> **作業ディレクトリ**: `H:\CURSOR\Dev\fivem-mods_ja\RefBoard`
> **現状**: v0.8.5。Sprint 09（ヘルプ）と v0.7.x ロック・DB ブートストラップ系修正、v0.8.x テストデータ整備＋フォント倍率 Settings 化＋`E3006` ヘルプ記事までクローズ。次は v0.8.6 候補（ビルドチャンク分割）から着手したい。引継資料は `docs/HANDOVER.md` 第 2 版。

短く済ませたい場合は「**チャンク分割いって**」「**STORAGE 案内いって**」「**実機テスト準備いって**」のいずれかでスコープが一意に決まる。

---

**改版履歴**

- 2026-05-08（初版）: Sprint 09 Phase C 完了時点（v0.6.7）。
- 2026-05-08（第 2 版）: 同日中に Sprint 09 完了（v0.7.0）と運用フェーズ突入（v0.7.1〜v0.8.3）を反映。リリース履歴・既知 TODO・ロードマップを v0.8.3 起点で全面書き直し。
- 2026-05-09: v0.8.4 完了反映（リリース履歴・TODO・ロードマップ・開始フレーズの差分更新）。
- 2026-05-09: v0.8.5 完了反映（`E3006` ヘルプ・配線。リリース履歴・TODO・ロードマップ・開始フレーズの差分更新）。
