-- MERIDIAN-9: mrd9_result_logs に強制終了結果を追加（既存 DB 向け）
-- 適用: mysql -u ... -p dbname < jp-meridian9/sql/migrations/2026-05-15_mrd9_result_logs_forced.sql

ALTER TABLE `mrd9_result_logs`
  MODIFY COLUMN `result` ENUM('extracted', 'died', 'disconnect', 'forced', 'unknown') NOT NULL DEFAULT 'unknown';
