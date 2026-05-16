-- 2026-05-16: mrd9_result_logs.result に 'timeout' / 'out_of_zone' を追加
-- 適用: mysql -u ... -p dbname < jp-meridian9/sql/migrations/2026-05-16_mrd9_result_logs_timeout_outofzone.sql

ALTER TABLE `mrd9_result_logs`
  MODIFY COLUMN `result` ENUM('extracted', 'died', 'disconnect', 'forced', 'timeout', 'out_of_zone', 'unknown') NOT NULL DEFAULT 'unknown';
