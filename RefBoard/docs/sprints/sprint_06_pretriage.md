# Sprint 6 緊急前夜版 — トリアージ強化（v0.5.1）

実機テスト直前に、**観測可能性**と**例外耐性**だけを入れる小バンプ。機能追加は行わない。

## 完了した作業（v0.5.1）

1. **SafeCall 相当** — `server/util.lua` の `RefboardGuard`（`xpcall` + `debug.traceback` + `Logger.error`、任意で ACK に `MakeError(ErrorCodes.UNHANDLED_EXCEPTION)`）。
2. **エラーコード** — `shared/error_codes.lua`（`ErrorCodes` / `MakeError`）。既存の `error` 文字列（例: `bad_payload`, `no_lock`, `duplicate_license`）と整合する `message` フィールド。
3. **Logger** — `Logger.debug|info|warn|error`、`Config.LogLevel`。スコア・ロック・試合作成など入口ログ。
4. **NUI トレース** — `useNui.ts`（`DEV` または `localStorage.refboard_trace=1`）、`Launcher.vue` の有効化リンク。
5. **グローバルエラー** — `main.ts` の `window.error` / `unhandledrejection` + `useToast`。
6. **ヘルスチェック** — `server/health.lua`、`refboard:health:check` / `:ack`、`HealthCheck.vue`、設定画面からのリンク、`health_check` NUI コールバック。
7. **付随** — `web/src/types/error.ts`、`ja.json` / `en.json` の `errors` / `health`、`CHANGELOG`、バージョン表記の同期。

## 運用メモ

- ブラウザで `localStorage.setItem('refboard_trace','1')` 後リロードでもトレース可（ランチャーのリンクと同等）。
- ヘルスチェックは試合前に 1 回、`[レポートをコピー]` で Markdown を issue / Discord へ。
- サーバー側は `Config.LogLevel = 'DEBUG'` で詳細ログ（本番は `INFO` 推奨）。

## 参照

- 実機テスト計画: `docs/testing/release_test_plan.md`
- スプリント6本線: `docs/sprints/sprint_06.md`
