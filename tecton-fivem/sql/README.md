# SQL migrations

- **自動適用**: `tecton-fivem` リソース起動時に、未適用のマイグレーションだけが順に実行されます。通常は **手動で SQL を流す必要はありません**。
- **追加方法**: `sql/migrations/` に **連番の新しいファイル**（例: `002_add_tags.sql`）を置き、`server/migrate.lua` の `MIGRATIONS` 配列に `{ version = 2, file = '...', description = '...' }` を追記します。
- **編集禁止**: すでにリリース・適用済みのマイグレーションファイル（例: `001_initial.sql`）は **変更しない**でください。適用済み環境では再実行されないため、内容を直しても既存DBには反映されず、新規環境だけズレます。
- **バージョン管理**: 適用済みバージョンは DB の `tec_schema_version` テーブルに記録されます。

詳細は [`docs/ja/getting-started.md`](../docs/ja/getting-started.md) を参照してください。
