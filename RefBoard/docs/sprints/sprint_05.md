# Sprint 05 — v0.5.0（周辺機能・データ活用）

## ゴール

試合の前後（チーム準備・履歴・エクスポート・設定）と PK 決着後フロー、UX ポリッシュ、ドキュメントまでを一気通貫で揃える。

## 完了タスク

- **5-1** `team_roster` マイグレーション、`server/team.lua`（管理一覧・詳細・CRUD・ロスター）、`TeamManage.vue` と `components/team/*`、`AddPlayerDialog` のロスター追加モード。
- **5-3** `utils/exporters.ts`（BOM 付き CSV、JSON、ファイル名規約）。
- **5-2** `server/data.lua`（チーム統計・選手統計・編集ログ・試合履歴）、`DataManage.vue` 4 タブ。
- **5-4** `views/Settings.vue`、`stores/settings.ts`（localStorage）、言語と i18n 連動。
- **5-5** `server/event.lua` の `evaluatePenaltyShootout` と `refboard:event:pk_decided`、`PenaltyShootoutPanel.vue` のオーバーレイ＋終了確認。
- **5-6** `@vueuse/core` の `onClickOutside`（`EventTimelineCard` / `ScoreBoardCard`）、キーボードショートカット、トースト、NUI `errorHandler`。
- **5-7** `docs/screenshots/` 01〜10、`README` ヒーロー、`USER_GUIDE` ja/en。

## 開発メモ（日記）

- ロスターからの試合登録は `server_id` をライセンス照合で埋め、オフライン時は `0` とした（DB 上は必須のため）。FiveM 上ではオンライン選手と紐づくと自然に ID が入る。
- PK 決着はサーバー側を真実の源とし、モックでも `maybeEmitPkDecided()` で同じイベントを飛ばして UI を検証できるようにした。
- スクリーンショットはプレースホルダ PNG（ラベル入り）でリポジトリに同梱。実機キャプチャに差し替え可能。

## 受け入れ

`AGENTS.md` の RefBoard 範囲で `npm run build` 成功、新規 SQL は `migration_004_team_roster.sql` を既存 DBへ適用。
