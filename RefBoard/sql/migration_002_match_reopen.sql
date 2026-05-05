-- v0.3.0: 終了試合の再編集メタ + 選手ポジション・警告回数
-- 既存 DB は一度だけ手動適用してください。

SET NAMES utf8mb4;

ALTER TABLE matches
  ADD COLUMN reopened_at TIMESTAMP NULL AFTER finished_at,
  ADD COLUMN reopened_by_license VARCHAR(64) NULL AFTER reopened_at,
  ADD COLUMN reopened_by_name VARCHAR(64) NULL AFTER reopened_by_license;

ALTER TABLE match_players
  ADD COLUMN position VARCHAR(8) NULL AFTER jersey_number,
  ADD COLUMN yellow_cards TINYINT NOT NULL DEFAULT 0 AFTER is_active;
