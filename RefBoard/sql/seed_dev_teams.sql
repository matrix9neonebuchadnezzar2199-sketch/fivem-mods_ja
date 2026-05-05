-- 開発・テスト用: 試合作成に最低2チーム必要（重複実行は IGNORE でスキップ）
INSERT IGNORE INTO teams (name, short_name, color, created_by_license, created_by_name) VALUES
('Los Santos FC', 'LS', '#3B82F6', 'seed', 'seed'),
('Vinewood United', 'VW', '#64748B', 'seed', 'seed');
