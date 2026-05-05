-- 配達ジョブ用のESXジョブテーブル登録
INSERT INTO `jobs` (name, label) VALUES
  ('delivery', '配達員')
;

INSERT INTO `job_grades` (job_name, grade, name, label, salary, skin_male, skin_female) VALUES
  ('delivery', 0, 'employee', '配達員', 0, '{}', '{}')
;
