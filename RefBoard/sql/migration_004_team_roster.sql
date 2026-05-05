SET NAMES utf8mb4;

-- チームエンブレム（v0.5.0: 絵文字。画像アップロードは将来）
ALTER TABLE teams ADD COLUMN emblem_emoji VARCHAR(16) NULL AFTER color;

CREATE TABLE IF NOT EXISTS team_roster (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  team_id BIGINT NOT NULL,
  player_name VARCHAR(64) NOT NULL,
  jersey_number INT NULL,
  position ENUM('GK','DF','MF','FW') NULL,
  license VARCHAR(64) NULL,
  joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  left_at TIMESTAMP NULL,
  FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE,
  INDEX idx_team_roster_team (team_id, left_at),
  INDEX idx_team_roster_license (license)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
