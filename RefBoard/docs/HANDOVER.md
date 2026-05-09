# RefBoard 引継資料（第 3 版・ローカル版）

- **作成日**: 2026‑05‑09
- **対象バージョン**: v0.1.0（ローカル専用リブート起点）
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

## 3. ディレクトリ構成（v0.1.0）

```
RefBoard/
├─ fxmanifest.lua          version '0.1.0'
├─ config.lua              OpenKey, DefaultLocale のみ
├─ client/main.lua         NUI 開閉と /refboard コマンド
├─ shared/constants.lua    リソース名等の定数のみ
├─ docs/
│  ├─ HANDOVER.md          本書
│  └─ diary/               2026‑05‑09_local_reboot.md ほか
├─ CHANGELOG.md
├─ README.md
└─ web/
   ├─ package.json         version 0.1.0（`REFBOARD_UI_VERSION`・fxmanifest と整合）
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
      │  ├─ localMatchAdapter.ts  Match → MatchDetailModel ブリッジ
      │  ├─ exporters.ts          CSV／全データ JSON バックアップ
      │  └─ errorCodeMapper.ts    E2001/E3004/E3006 のみ
      ├─ views/
      │  ├─ Launcher.vue          表示名入力 → 試合一覧へ
      │  ├─ MainLayout.vue        sidebar + RouterView + ContextHelpPanel
      │  ├─ MatchList.vue         一覧／検索／削除／新規作成
      │  ├─ MatchDetail.vue       時計／ゴール／カード／交代／PK／手動編集／終了
      │  ├─ TeamManage.vue        チームとロスター
      │  ├─ DataManage.vue        終了試合一覧、CSV、全データ JSON バックアップ
      │  ├─ Settings.vue          表示名／locale／fontScale／marquee／背景
      │  └─ HelpView.vue          目次／逆引き／検索／コンテキスト
      ├─ help/
      │  ├─ ja/articles/          15 本（intro 2／match 7／team 2／data 2／trouble 2 ※統合済）
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

- **永続化**: `utils/localPersist.ts` がキーごとに `{ v: 1, data }` 形式で `localStorage` に書き、各ストアが `watch(deep)` で自動保存。`dumpAllLocal()` が全データ JSON バックアップの土台。
- **ID 採番**: `utils/localId.ts` が match/team/player/rosterMember/event/scoreHistory のカウンタを `id_counters` キーで管理。
- **時計**: `matches` ストアの `clockStartedAt`（停止時 null）と `clockAccumulatedMs` の合算で `clockNowMs(m)` を算出。UI 側は 250ms ポーリングで表示のみ更新し、保存はストアが担当。
- **得点ロジック**: `addEvent` で `goal`/`pk_goal` を加算、`voidEvent` で減算。手動スコアは `manualScoreEdit` が `scoreHistory` に履歴を残しつつ `homeScore`/`awayScore` を上書き。
- **NUI 通信**: `useNui().send('close')` 等のコンパクト関連だけ Lua にPOST。他はブラウザ／FiveM ともに `{ ok: true }` を返すスタブ。`on()` は `refboard:compact_input_mode` のみ window.message 経由で購読。
- **ヘルプ**: ja/en 各 15 本。緊急度高（🆘）と診断（🩺）カテゴリは廃止し、🔧 トラブル配下に `trouble_undo_goal` と `trouble_e3006_player_has_events` の 2 本のみ。`errorCodeMapper.ts` は `E2001`/`E3004`/`E3006` のみ保持。

## 6. 開発・ビルド・配布

```bash
cd RefBoard/web
npm install
npm run dev          # ブラウザ単体プレビュー
npm run build        # web/dist 出力（FiveM 配布物）
npx vue-tsc --noEmit # 型チェック
```

`fxmanifest.lua` は `web/dist/index.html` と `web/dist/**/*` をパッケージ。`server.cfg` には `ensure RefBoard` の 1 行のみ（`oxmysql` も ACE も不要）。`Config.OpenKey`（既定 F6）と `Config.DefaultLocale`（既定 `ja`）だけ設定可能。

## 7. 既知の TODO（v0.1.0 時点）

- 全データ JSON の **インポート** UI（v0.1.0 はエクスポートのみ）。端末移行時に必要。
- ロスタイム表記（`45+2`）の入力許容と表示整形。
- PK キャンセル UI、選手状態セルのタップ切替、`Ctrl+Z` でゴール取消ショートカット。
- ヘルプ Fuse.js のしきい値再評価（記事数が約 21 本相当から 15 本に減ったため）。
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

## 9. ロードマップ（v0.1.0 → v1.0.0）

- **v0.1.x（短期）**: JSON インポート、`intro_setup` スクショ更新、ロスタイム入力。
- **v0.2.0（中期）**: 大会／リーグの集計、CSV 出力の項目拡充、コンパクト小窓モードの再評価。
- **v0.3.0**: ヘルプ拡充（v0.1.0 では削った記事のうち再度必要になったものをローカル文脈で書き直し）、Fuse 再チューニング。
- **v0.9.0**: 実機テストシナリオ実施・記録、軽微不具合修正。
- **v1.0.0**: README 更新、デモ GIF、CHANGELOG 総括、配布 zip。

## 10. 次セッション開始フレーズ例

> リポジトリ: https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja の `RefBoard/`
> ローカル: H:\CURSOR\Dev\fivem-mods_ja\RefBoard
> 現状: v0.1.0（ローカル版リブート完了、4 連コミット済）。`RefBoard_old/` は GitHub 非追跡の素材庫。
> 次着手候補: JSON インポート UI、ロスタイム入力許容のいずれか。
> 引継資料: `RefBoard/docs/HANDOVER.md` 第 3 版、開発日記は `RefBoard/docs/diary/`。

短縮フレーズ: `JSON インポートいって` / `ロスタイムいって`

## 11. 改版履歴

- 2026‑05‑09: 第 3 版起こし。v0.1.0（ローカル版リブート）に対応。旧版の §4〜§9（サーバ連動・編集ロック・実機テスト計画）を全面差し替え。
- 2026‑05‑09: v0.1.0 の `web/package.json`・`package-lock.json`・`src/constants/version.ts`（`REFBOARD_UI_VERSION`）を 0.1.0 へ同期。HANDOVER §3 と §7 を整合修正（版数揃えの Git ハッシュは `git log -1 --oneline -- RefBoard/web/package.json` で確認）。
- 2026‑05‑09: 試合詳細ヘッダに `selfName`（操作者）を表示。未設定時は Settings へ誘導するリンクを表示。小窓モードで `transparentChrome` のときはヘッダから非表示。
