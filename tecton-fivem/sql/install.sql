-- TECTON: run once on the same database oxmysql uses (e.g. fivem_db).
-- If tables are missing, INSERT fails with "Table '...tec_objects' doesn't exist".

CREATE TABLE IF NOT EXISTS tec_objects (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  category      VARCHAR(32) NOT NULL,
  model         VARCHAR(64) NOT NULL,
  pos_x DOUBLE, pos_y DOUBLE, pos_z DOUBLE,
  rot_x DOUBLE, rot_y DOUBLE, rot_z DOUBLE,
  meta          JSON NULL,
  scene_id      VARCHAR(64) NOT NULL,
  created_by    VARCHAR(64),
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at    TIMESTAMP NULL,
  INDEX idx_scene (scene_id),
  INDEX idx_cat (category)
);

CREATE TABLE IF NOT EXISTS tec_history (
  id          BIGINT AUTO_INCREMENT PRIMARY KEY,
  scene_id    VARCHAR(64) NOT NULL,
  user_id     VARCHAR(64),
  action      VARCHAR(16) NOT NULL,
  target_id   INT NULL,
  before_data JSON NULL,
  after_data  JSON NULL,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_scene_time (scene_id, created_at)
);

CREATE TABLE IF NOT EXISTS tec_autosave (
  scene_id   VARCHAR(64) PRIMARY KEY,
  snapshot   JSON NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tec_user_prefs (
  user_id    VARCHAR(64) PRIMARY KEY,
  recents    JSON,
  favorites  JSON,
  ui_state   JSON
);
