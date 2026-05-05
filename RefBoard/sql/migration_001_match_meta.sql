-- 既存環境向け: install.sql 実行済みで matches に会場・キックオフ等が無い場合に一度だけ実行
ALTER TABLE matches ADD COLUMN match_name VARCHAR(128) NULL AFTER match_date;
ALTER TABLE matches ADD COLUMN venue VARCHAR(128) NULL AFTER match_name;
ALTER TABLE matches ADD COLUMN kickoff_time TIME NULL AFTER venue;
