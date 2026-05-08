# 実機テストのデバッグ Tips

実機で問題に当たったときに最初に試す手順を集約。新規実装の手順ではなく、**既存の仕組みの呼び出し方**を一覧化したもの。

## サーバー側

### ログレベル変更

`config.lua` の `Config.LogLevel = 'DEBUG'` で詳細ログ。FXServer コンソールに `[refboard]` プレフィックス付きで出る。`server/util.lua` の `Logger` が出口。

### トランザクション検証

`Config.EnableTestCommands = true` で `refboard_test_transaction` が有効化。`docs/testing/transaction_test.md` の手順を参照。本番では `false` に戻すこと。

### `editor_locks` の手動確認

```sql
SELECT id, match_id, holder_server_id, holder_name, locked_at, last_heartbeat_at
FROM editor_locks WHERE id = 1;
```

古い `holder_server_id` が残っている場合は v0.7.1 の修正で起動時クリアされるはずだが、念のため `DELETE FROM editor_locks WHERE id = 1;` で手動クリア可能。

### `match_drafts` の確認（オートセーブ）

```sql
SELECT match_id, updated_at, LENGTH(payload) FROM match_drafts ORDER BY updated_at DESC LIMIT 10;
```

### スキーマ確認

RefBoard の正本は `sql/install.sql`。`schema_bootstrap.lua` が `editor_locks` 不在時に `install.sql` を自動実行する。専用の `schema_meta` テーブルは現状未定義のため、適用状況は起動ログと `SHOW TABLES` / `DESCRIBE editor_locks` で確認する。

## クライアント側（NUI / ブラウザ単体）

### NUI トレース有効化

ランチャーの「🐛 デバッグログを有効化（再読込）」リンクで `localStorage.refboard_trace = '1'` を立て、再読込。`useNui.ts` のリクエストトレースが console に出るようになる。`DEV` ビルドでは常時有効。

### ブラウザ単体での再現

`cd RefBoard/web && npm run dev` で `nuiMock` 上で再現。`window.__refboardMock`（DEV のみ）で:

- `__refboardMock.dump()` … 現在の状態を console に出力
- `__refboardMock.reset()` … `localStorage` をクリアして初期シードに戻す
- `__refboardMock.setStorageVersion(N)` … バージョン強制（破壊的シード変更時）

### ヘルスチェック

設定 → 「ヘルスチェック（実機テスト前）」で DB / 認証 / プレゼンス / ロック / 設定 の状態を一覧表示。`refboard:health:check` が走り、`HealthCheck.vue` が結果を整形。

### Vue Devtools

`DEV` ビルド（`npm run dev`）では Vue Devtools が動く。実機 CEF では動かない（CEF が拡張をロードしないため）。

## ログ採取の動線

問題発生時に管理者へ送るべきログ:

1. FXServer コンソールの `[refboard]` 前後 100 行
2. F12 の console（CEF 内では `Esc` でメニュー → デバッガ起動）
3. `editor_locks` / `match_drafts` / 該当 `matches` 行のスナップショット（SELECT … または管理者用エクスポート）
4. `localStorage.refboard_settings` / `localStorage.refboard_mock_state` / `localStorage.refboard_trace` の値
