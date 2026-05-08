-- RefBoard 開発用テストデータ: チーム5件 × ロスター15人（GK1+DF4+MF5+FW5）
-- 前提: install.sql / migration 適用済み
-- 実行例: mysql -u USER -p DATABASE < sql/seed_test_5teams_15roster.sql
--
-- 同名の未削除チームが既にある場合は INSERT をスキップします。
-- ロスターが既に1人以上いるチームには選手を追加しません（再実行安全）。

SET NAMES utf8mb4;

INSERT INTO teams (name, short_name, color, emblem_emoji, created_by_license, created_by_name)
SELECT 'Los Santos FC', 'LS', '#3b82f6', '⚽', 'seed:test', 'seed:test'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM teams t WHERE t.name = 'Los Santos FC' AND t.deleted_at IS NULL);

INSERT INTO teams (name, short_name, color, emblem_emoji, created_by_license, created_by_name)
SELECT 'Vinewood United', 'VW', '#64748b', NULL, 'seed:test', 'seed:test'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM teams t WHERE t.name = 'Vinewood United' AND t.deleted_at IS NULL);

INSERT INTO teams (name, short_name, color, emblem_emoji, created_by_license, created_by_name)
SELECT 'Paleto Bay SC', 'PB', '#22c55e', NULL, 'seed:test', 'seed:test'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM teams t WHERE t.name = 'Paleto Bay SC' AND t.deleted_at IS NULL);

INSERT INTO teams (name, short_name, color, emblem_emoji, created_by_license, created_by_name)
SELECT 'Sandy Shores AC', 'SS', '#f59e0b', NULL, 'seed:test', 'seed:test'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM teams t WHERE t.name = 'Sandy Shores AC' AND t.deleted_at IS NULL);

INSERT INTO teams (name, short_name, color, emblem_emoji, created_by_license, created_by_name)
SELECT 'Grapeseed Town FC', 'GT', '#a855f7', NULL, 'seed:test', 'seed:test'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM teams t WHERE t.name = 'Grapeseed Town FC' AND t.deleted_at IS NULL);

-- 背番号 1–15 / ポジション列（nums）
INSERT INTO team_roster (team_id, player_name, jersey_number, position, license)
SELECT t.id, CONCAT('LS 選手', LPAD(nums.n, 2, '0')), nums.n, nums.p, CONCAT('seed:t', t.id, ':j', nums.n)
FROM teams t
CROSS JOIN (
  SELECT 1 AS n, 'GK' AS p
  UNION ALL SELECT 2, 'DF'
  UNION ALL SELECT 3, 'DF'
  UNION ALL SELECT 4, 'DF'
  UNION ALL SELECT 5, 'DF'
  UNION ALL SELECT 6, 'MF'
  UNION ALL SELECT 7, 'MF'
  UNION ALL SELECT 8, 'MF'
  UNION ALL SELECT 9, 'MF'
  UNION ALL SELECT 10, 'MF'
  UNION ALL SELECT 11, 'FW'
  UNION ALL SELECT 12, 'FW'
  UNION ALL SELECT 13, 'FW'
  UNION ALL SELECT 14, 'FW'
  UNION ALL SELECT 15, 'FW'
) nums
WHERE t.name = 'Los Santos FC'
  AND t.deleted_at IS NULL
  AND NOT EXISTS (SELECT 1 FROM team_roster r WHERE r.team_id = t.id AND r.left_at IS NULL LIMIT 1);

INSERT INTO team_roster (team_id, player_name, jersey_number, position, license)
SELECT t.id, CONCAT('VW 選手', LPAD(nums.n, 2, '0')), nums.n, nums.p, CONCAT('seed:t', t.id, ':j', nums.n)
FROM teams t
CROSS JOIN (
  SELECT 1 AS n, 'GK' AS p
  UNION ALL SELECT 2, 'DF'
  UNION ALL SELECT 3, 'DF'
  UNION ALL SELECT 4, 'DF'
  UNION ALL SELECT 5, 'DF'
  UNION ALL SELECT 6, 'MF'
  UNION ALL SELECT 7, 'MF'
  UNION ALL SELECT 8, 'MF'
  UNION ALL SELECT 9, 'MF'
  UNION ALL SELECT 10, 'MF'
  UNION ALL SELECT 11, 'FW'
  UNION ALL SELECT 12, 'FW'
  UNION ALL SELECT 13, 'FW'
  UNION ALL SELECT 14, 'FW'
  UNION ALL SELECT 15, 'FW'
) nums
WHERE t.name = 'Vinewood United'
  AND t.deleted_at IS NULL
  AND NOT EXISTS (SELECT 1 FROM team_roster r WHERE r.team_id = t.id AND r.left_at IS NULL LIMIT 1);

INSERT INTO team_roster (team_id, player_name, jersey_number, position, license)
SELECT t.id, CONCAT('PB 選手', LPAD(nums.n, 2, '0')), nums.n, nums.p, CONCAT('seed:t', t.id, ':j', nums.n)
FROM teams t
CROSS JOIN (
  SELECT 1 AS n, 'GK' AS p
  UNION ALL SELECT 2, 'DF'
  UNION ALL SELECT 3, 'DF'
  UNION ALL SELECT 4, 'DF'
  UNION ALL SELECT 5, 'DF'
  UNION ALL SELECT 6, 'MF'
  UNION ALL SELECT 7, 'MF'
  UNION ALL SELECT 8, 'MF'
  UNION ALL SELECT 9, 'MF'
  UNION ALL SELECT 10, 'MF'
  UNION ALL SELECT 11, 'FW'
  UNION ALL SELECT 12, 'FW'
  UNION ALL SELECT 13, 'FW'
  UNION ALL SELECT 14, 'FW'
  UNION ALL SELECT 15, 'FW'
) nums
WHERE t.name = 'Paleto Bay SC'
  AND t.deleted_at IS NULL
  AND NOT EXISTS (SELECT 1 FROM team_roster r WHERE r.team_id = t.id AND r.left_at IS NULL LIMIT 1);

INSERT INTO team_roster (team_id, player_name, jersey_number, position, license)
SELECT t.id, CONCAT('SS 選手', LPAD(nums.n, 2, '0')), nums.n, nums.p, CONCAT('seed:t', t.id, ':j', nums.n)
FROM teams t
CROSS JOIN (
  SELECT 1 AS n, 'GK' AS p
  UNION ALL SELECT 2, 'DF'
  UNION ALL SELECT 3, 'DF'
  UNION ALL SELECT 4, 'DF'
  UNION ALL SELECT 5, 'DF'
  UNION ALL SELECT 6, 'MF'
  UNION ALL SELECT 7, 'MF'
  UNION ALL SELECT 8, 'MF'
  UNION ALL SELECT 9, 'MF'
  UNION ALL SELECT 10, 'MF'
  UNION ALL SELECT 11, 'FW'
  UNION ALL SELECT 12, 'FW'
  UNION ALL SELECT 13, 'FW'
  UNION ALL SELECT 14, 'FW'
  UNION ALL SELECT 15, 'FW'
) nums
WHERE t.name = 'Sandy Shores AC'
  AND t.deleted_at IS NULL
  AND NOT EXISTS (SELECT 1 FROM team_roster r WHERE r.team_id = t.id AND r.left_at IS NULL LIMIT 1);

INSERT INTO team_roster (team_id, player_name, jersey_number, position, license)
SELECT t.id, CONCAT('GT 選手', LPAD(nums.n, 2, '0')), nums.n, nums.p, CONCAT('seed:t', t.id, ':j', nums.n)
FROM teams t
CROSS JOIN (
  SELECT 1 AS n, 'GK' AS p
  UNION ALL SELECT 2, 'DF'
  UNION ALL SELECT 3, 'DF'
  UNION ALL SELECT 4, 'DF'
  UNION ALL SELECT 5, 'DF'
  UNION ALL SELECT 6, 'MF'
  UNION ALL SELECT 7, 'MF'
  UNION ALL SELECT 8, 'MF'
  UNION ALL SELECT 9, 'MF'
  UNION ALL SELECT 10, 'MF'
  UNION ALL SELECT 11, 'FW'
  UNION ALL SELECT 12, 'FW'
  UNION ALL SELECT 13, 'FW'
  UNION ALL SELECT 14, 'FW'
  UNION ALL SELECT 15, 'FW'
) nums
WHERE t.name = 'Grapeseed Town FC'
  AND t.deleted_at IS NULL
  AND NOT EXISTS (SELECT 1 FROM team_roster r WHERE r.team_id = t.id AND r.left_at IS NULL LIMIT 1);
