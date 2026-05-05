SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS=0;

CREATE TABLE IF NOT EXISTS teams (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(64) NOT NULL,
  short_name VARCHAR(8),
  color VARCHAR(16),
  created_by_license VARCHAR(64) NOT NULL,
  created_by_name VARCHAR(64) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL,
  UNIQUE KEY uq_teams_name_alive (name, deleted_at),
  INDEX idx_teams_alive (deleted_at, name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS matches (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  team1_id BIGINT NOT NULL,
  team2_id BIGINT NOT NULL,
  team1_score INT NOT NULL DEFAULT 0,
  team2_score INT NOT NULL DEFAULT 0,
  status ENUM('draft','finished','cancelled') NOT NULL DEFAULT 'draft',
  current_half ENUM('1st','halftime','2nd','et','pk') NOT NULL DEFAULT '1st',
  clock_running TINYINT(1) NOT NULL DEFAULT 0,
  clock_started_at BIGINT NULL,
  clock_accumulated_ms BIGINT NOT NULL DEFAULT 0,
  match_date DATE NOT NULL,
  created_by_license VARCHAR(64) NOT NULL,
  created_by_name VARCHAR(64) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  finished_at TIMESTAMP NULL,
  FOREIGN KEY (team1_id) REFERENCES teams(id),
  FOREIGN KEY (team2_id) REFERENCES teams(id),
  INDEX idx_matches_status_updated (status, updated_at DESC),
  INDEX idx_matches_date (match_date DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS match_players (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  match_id BIGINT NOT NULL,
  team_id BIGINT NOT NULL,
  server_id INT NOT NULL,
  license VARCHAR(64) NULL,
  player_name VARCHAR(64) NOT NULL,
  jersey_number INT NULL,
  is_starter TINYINT(1) NOT NULL DEFAULT 1,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE,
  FOREIGN KEY (team_id) REFERENCES teams(id),
  INDEX idx_match_players_mt (match_id, team_id),
  INDEX idx_match_players_lic (license)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS match_events (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  match_id BIGINT NOT NULL,
  event_type ENUM('goal','substitution','yellow_card','red_card','own_goal','penalty') NOT NULL,
  team_id BIGINT NOT NULL,
  player_id BIGINT NULL,
  assist_player_id BIGINT NULL,
  sub_in_player_id BIGINT NULL,
  sub_out_player_id BIGINT NULL,
  half ENUM('1st','2nd','et','pk') NOT NULL,
  match_time_ms BIGINT NOT NULL,
  recorded_by_license VARCHAR(64) NOT NULL,
  recorded_by_name VARCHAR(64) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  voided_at TIMESTAMP NULL,
  voided_by_license VARCHAR(64) NULL,
  voided_by_name VARCHAR(64) NULL,
  void_reason VARCHAR(255) NULL,
  FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE,
  FOREIGN KEY (team_id) REFERENCES teams(id),
  INDEX idx_match_events_match (match_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS match_score_history (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  match_id BIGINT NOT NULL,
  team1_score INT NOT NULL,
  team2_score INT NOT NULL,
  half VARCHAR(8) NOT NULL,
  match_time_ms BIGINT NOT NULL,
  action ENUM('goal','manual_edit','undo','reset') NOT NULL,
  related_event_id BIGINT NULL,
  changed_by_license VARCHAR(64) NOT NULL,
  changed_by_name VARCHAR(64) NOT NULL,
  reason VARCHAR(255) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE,
  INDEX idx_score_history_match (match_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS match_drafts (
  match_id BIGINT PRIMARY KEY,
  state_json LONGTEXT NOT NULL,
  last_editor_license VARCHAR(64) NOT NULL,
  last_editor_name VARCHAR(64) NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS editor_locks (
  id TINYINT PRIMARY KEY,
  match_id BIGINT NULL,
  holder_license VARCHAR(64) NULL,
  holder_name VARCHAR(64) NULL,
  holder_server_id INT NULL,
  acquired_at TIMESTAMP NULL,
  last_heartbeat TIMESTAMP NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO editor_locks (id) VALUES (1);

CREATE TABLE IF NOT EXISTS tournaments (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(128) NOT NULL,
  team_count INT NOT NULL,
  scheduled_date DATE NULL,
  status ENUM('planned','ongoing','finished') NOT NULL DEFAULT 'planned',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS tournament_matches (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  tournament_id BIGINT NOT NULL,
  match_id BIGINT NULL,
  round INT NOT NULL,
  bracket_position INT NOT NULL,
  FOREIGN KEY (tournament_id) REFERENCES tournaments(id) ON DELETE CASCADE,
  FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS=1;
