-- RefBoard 開発用: 5 チーム投入済み前提で試合 20 件を追加する（単体では実行しないこと）
-- サーバーは wipe 後に seed_test_5teams_15roster.sql を流してから本ファイルを実行する

SET NAMES utf8mb4;

INSERT INTO matches (team1_id, team2_id, team1_score, team2_score, status, current_half, clock_running, clock_accumulated_ms, match_date, match_name, venue, kickoff_time, created_by_license, created_by_name, finished_at)
SELECT t1.id, t2.id, 0, 0, 'draft', '1st', 0, 0, '2026-05-01', '開発用試合01', 'テストスタジアム', NULL, 'seed:dev', 'seed:dev', NULL
FROM teams t1 JOIN teams t2 ON t2.name = 'Vinewood United' AND t2.deleted_at IS NULL
WHERE t1.name = 'Los Santos FC' AND t1.deleted_at IS NULL LIMIT 1;

INSERT INTO matches (team1_id, team2_id, team1_score, team2_score, status, current_half, clock_running, clock_accumulated_ms, match_date, match_name, venue, kickoff_time, created_by_license, created_by_name, finished_at)
SELECT t1.id, t2.id, 0, 0, 'draft', '1st', 0, 0, '2026-05-02', '開発用試合02', 'テストスタジアム', NULL, 'seed:dev', 'seed:dev', NULL
FROM teams t1 JOIN teams t2 ON t2.name = 'Paleto Bay SC' AND t2.deleted_at IS NULL
WHERE t1.name = 'Vinewood United' AND t1.deleted_at IS NULL LIMIT 1;

INSERT INTO matches (team1_id, team2_id, team1_score, team2_score, status, current_half, clock_running, clock_accumulated_ms, match_date, match_name, venue, kickoff_time, created_by_license, created_by_name, finished_at)
SELECT t1.id, t2.id, 0, 0, 'draft', 'halftime', 0, 0, '2026-05-03', '開発用試合03', 'テストスタジアム', NULL, 'seed:dev', 'seed:dev', NULL
FROM teams t1 JOIN teams t2 ON t2.name = 'Sandy Shores AC' AND t2.deleted_at IS NULL
WHERE t1.name = 'Paleto Bay SC' AND t1.deleted_at IS NULL LIMIT 1;

INSERT INTO matches (team1_id, team2_id, team1_score, team2_score, status, current_half, clock_running, clock_accumulated_ms, match_date, match_name, venue, kickoff_time, created_by_license, created_by_name, finished_at)
SELECT t1.id, t2.id, 0, 0, 'draft', '2nd', 0, 0, '2026-05-04', '開発用試合04', 'テストスタジアム', NULL, 'seed:dev', 'seed:dev', NULL
FROM teams t1 JOIN teams t2 ON t2.name = 'Grapeseed Town FC' AND t2.deleted_at IS NULL
WHERE t1.name = 'Sandy Shores AC' AND t1.deleted_at IS NULL LIMIT 1;

INSERT INTO matches (team1_id, team2_id, team1_score, team2_score, status, current_half, clock_running, clock_accumulated_ms, match_date, match_name, venue, kickoff_time, created_by_license, created_by_name, finished_at)
SELECT t1.id, t2.id, 0, 0, 'draft', '1st', 0, 0, '2026-05-05', '開発用試合05', 'テストスタジアム', NULL, 'seed:dev', 'seed:dev', NULL
FROM teams t1 JOIN teams t2 ON t2.name = 'Los Santos FC' AND t2.deleted_at IS NULL
WHERE t1.name = 'Grapeseed Town FC' AND t1.deleted_at IS NULL LIMIT 1;

INSERT INTO matches (team1_id, team2_id, team1_score, team2_score, status, current_half, clock_running, clock_accumulated_ms, match_date, match_name, venue, kickoff_time, created_by_license, created_by_name, finished_at)
SELECT t1.id, t2.id, 0, 0, 'draft', '1st', 0, 0, '2026-05-06', '開発用試合06', 'テストスタジアム', NULL, 'seed:dev', 'seed:dev', NULL
FROM teams t1 JOIN teams t2 ON t2.name = 'Vinewood United' AND t2.deleted_at IS NULL
WHERE t1.name = 'Los Santos FC' AND t1.deleted_at IS NULL LIMIT 1;

INSERT INTO matches (team1_id, team2_id, team1_score, team2_score, status, current_half, clock_running, clock_accumulated_ms, match_date, match_name, venue, kickoff_time, created_by_license, created_by_name, finished_at)
SELECT t1.id, t2.id, 0, 0, 'draft', '1st', 0, 0, '2026-05-07', '開発用試合07', 'テストスタジアム', NULL, 'seed:dev', 'seed:dev', NULL
FROM teams t1 JOIN teams t2 ON t2.name = 'Paleto Bay SC' AND t2.deleted_at IS NULL
WHERE t1.name = 'Vinewood United' AND t1.deleted_at IS NULL LIMIT 1;

INSERT INTO matches (team1_id, team2_id, team1_score, team2_score, status, current_half, clock_running, clock_accumulated_ms, match_date, match_name, venue, kickoff_time, created_by_license, created_by_name, finished_at)
SELECT t1.id, t2.id, 0, 0, 'draft', '1st', 0, 0, '2026-05-08', '開発用試合08', 'テストスタジアム', NULL, 'seed:dev', 'seed:dev', NULL
FROM teams t1 JOIN teams t2 ON t2.name = 'Sandy Shores AC' AND t2.deleted_at IS NULL
WHERE t1.name = 'Paleto Bay SC' AND t1.deleted_at IS NULL LIMIT 1;

INSERT INTO matches (team1_id, team2_id, team1_score, team2_score, status, current_half, clock_running, clock_accumulated_ms, match_date, match_name, venue, kickoff_time, created_by_license, created_by_name, finished_at)
SELECT t1.id, t2.id, 0, 0, 'draft', '1st', 0, 0, '2026-05-09', '開発用試合09', 'テストスタジアム', NULL, 'seed:dev', 'seed:dev', NULL
FROM teams t1 JOIN teams t2 ON t2.name = 'Grapeseed Town FC' AND t2.deleted_at IS NULL
WHERE t1.name = 'Sandy Shores AC' AND t1.deleted_at IS NULL LIMIT 1;

INSERT INTO matches (team1_id, team2_id, team1_score, team2_score, status, current_half, clock_running, clock_accumulated_ms, match_date, match_name, venue, kickoff_time, created_by_license, created_by_name, finished_at)
SELECT t1.id, t2.id, 0, 0, 'draft', '1st', 0, 0, '2026-05-10', '開発用試合10', 'テストスタジアム', NULL, 'seed:dev', 'seed:dev', NULL
FROM teams t1 JOIN teams t2 ON t2.name = 'Los Santos FC' AND t2.deleted_at IS NULL
WHERE t1.name = 'Grapeseed Town FC' AND t1.deleted_at IS NULL LIMIT 1;

INSERT INTO matches (team1_id, team2_id, team1_score, team2_score, status, current_half, clock_running, clock_accumulated_ms, match_date, match_name, venue, kickoff_time, created_by_license, created_by_name, finished_at)
SELECT t1.id, t2.id, 2, 1, 'finished', '2nd', 0, 0, '2026-05-11', '開発用試合11', 'テストスタジアム', NULL, 'seed:dev', 'seed:dev', CURRENT_TIMESTAMP
FROM teams t1 JOIN teams t2 ON t2.name = 'Vinewood United' AND t2.deleted_at IS NULL
WHERE t1.name = 'Los Santos FC' AND t1.deleted_at IS NULL LIMIT 1;

INSERT INTO matches (team1_id, team2_id, team1_score, team2_score, status, current_half, clock_running, clock_accumulated_ms, match_date, match_name, venue, kickoff_time, created_by_license, created_by_name, finished_at)
SELECT t1.id, t2.id, 0, 0, 'finished', '2nd', 0, 0, '2026-05-12', '開発用試合12', 'テストスタジアム', NULL, 'seed:dev', 'seed:dev', CURRENT_TIMESTAMP
FROM teams t1 JOIN teams t2 ON t2.name = 'Paleto Bay SC' AND t2.deleted_at IS NULL
WHERE t1.name = 'Vinewood United' AND t1.deleted_at IS NULL LIMIT 1;

INSERT INTO matches (team1_id, team2_id, team1_score, team2_score, status, current_half, clock_running, clock_accumulated_ms, match_date, match_name, venue, kickoff_time, created_by_license, created_by_name, finished_at)
SELECT t1.id, t2.id, 3, 3, 'finished', '2nd', 0, 0, '2026-05-13', '開発用試合13', 'テストスタジアム', NULL, 'seed:dev', 'seed:dev', CURRENT_TIMESTAMP
FROM teams t1 JOIN teams t2 ON t2.name = 'Sandy Shores AC' AND t2.deleted_at IS NULL
WHERE t1.name = 'Paleto Bay SC' AND t1.deleted_at IS NULL LIMIT 1;

INSERT INTO matches (team1_id, team2_id, team1_score, team2_score, status, current_half, clock_running, clock_accumulated_ms, match_date, match_name, venue, kickoff_time, created_by_license, created_by_name, finished_at)
SELECT t1.id, t2.id, 1, 2, 'finished', '2nd', 0, 0, '2026-05-14', '開発用試合14', 'テストスタジアム', NULL, 'seed:dev', 'seed:dev', CURRENT_TIMESTAMP
FROM teams t1 JOIN teams t2 ON t2.name = 'Grapeseed Town FC' AND t2.deleted_at IS NULL
WHERE t1.name = 'Sandy Shores AC' AND t1.deleted_at IS NULL LIMIT 1;

INSERT INTO matches (team1_id, team2_id, team1_score, team2_score, status, current_half, clock_running, clock_accumulated_ms, match_date, match_name, venue, kickoff_time, created_by_license, created_by_name, finished_at)
SELECT t1.id, t2.id, 4, 0, 'finished', '2nd', 0, 0, '2026-05-15', '開発用試合15', 'テストスタジアム', NULL, 'seed:dev', 'seed:dev', CURRENT_TIMESTAMP
FROM teams t1 JOIN teams t2 ON t2.name = 'Los Santos FC' AND t2.deleted_at IS NULL
WHERE t1.name = 'Grapeseed Town FC' AND t1.deleted_at IS NULL LIMIT 1;

INSERT INTO matches (team1_id, team2_id, team1_score, team2_score, status, current_half, clock_running, clock_accumulated_ms, match_date, match_name, venue, kickoff_time, created_by_license, created_by_name, finished_at)
SELECT t1.id, t2.id, 0, 1, 'finished', 'pk', 0, 0, '2026-05-16', '開発用試合16', 'テストスタジアム', NULL, 'seed:dev', 'seed:dev', CURRENT_TIMESTAMP
FROM teams t1 JOIN teams t2 ON t2.name = 'Vinewood United' AND t2.deleted_at IS NULL
WHERE t1.name = 'Los Santos FC' AND t1.deleted_at IS NULL LIMIT 1;

INSERT INTO matches (team1_id, team2_id, team1_score, team2_score, status, current_half, clock_running, clock_accumulated_ms, match_date, match_name, venue, kickoff_time, created_by_license, created_by_name, finished_at)
SELECT t1.id, t2.id, 2, 2, 'finished', '2nd', 0, 0, '2026-05-17', '開発用試合17', 'テストスタジアム', NULL, 'seed:dev', 'seed:dev', CURRENT_TIMESTAMP
FROM teams t1 JOIN teams t2 ON t2.name = 'Paleto Bay SC' AND t2.deleted_at IS NULL
WHERE t1.name = 'Vinewood United' AND t1.deleted_at IS NULL LIMIT 1;

INSERT INTO matches (team1_id, team2_id, team1_score, team2_score, status, current_half, clock_running, clock_accumulated_ms, match_date, match_name, venue, kickoff_time, created_by_license, created_by_name, finished_at)
SELECT t1.id, t2.id, 1, 0, 'finished', '2nd', 0, 0, '2026-05-18', '開発用試合18', 'テストスタジアム', NULL, 'seed:dev', 'seed:dev', CURRENT_TIMESTAMP
FROM teams t1 JOIN teams t2 ON t2.name = 'Sandy Shores AC' AND t2.deleted_at IS NULL
WHERE t1.name = 'Paleto Bay SC' AND t1.deleted_at IS NULL LIMIT 1;

INSERT INTO matches (team1_id, team2_id, team1_score, team2_score, status, current_half, clock_running, clock_accumulated_ms, match_date, match_name, venue, kickoff_time, created_by_license, created_by_name, finished_at)
SELECT t1.id, t2.id, 0, 0, 'cancelled', '1st', 0, 0, '2026-05-19', '開発用試合19', 'テストスタジアム', NULL, 'seed:dev', 'seed:dev', NULL
FROM teams t1 JOIN teams t2 ON t2.name = 'Grapeseed Town FC' AND t2.deleted_at IS NULL
WHERE t1.name = 'Sandy Shores AC' AND t1.deleted_at IS NULL LIMIT 1;

INSERT INTO matches (team1_id, team2_id, team1_score, team2_score, status, current_half, clock_running, clock_accumulated_ms, match_date, match_name, venue, kickoff_time, created_by_license, created_by_name, finished_at)
SELECT t1.id, t2.id, 5, 4, 'finished', '2nd', 0, 0, '2026-05-20', '開発用試合20', 'テストスタジアム', NULL, 'seed:dev', 'seed:dev', CURRENT_TIMESTAMP
FROM teams t1 JOIN teams t2 ON t2.name = 'Los Santos FC' AND t2.deleted_at IS NULL
WHERE t1.name = 'Grapeseed Town FC' AND t1.deleted_at IS NULL LIMIT 1;
