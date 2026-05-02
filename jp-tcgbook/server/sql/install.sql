-- jp-tcgbook スキーマ（カードマスタの INSERT は行わない。起動時に shared/cards.lua から UPSERT）
-- MariaDB / MySQL 想定

CREATE TABLE IF NOT EXISTS tcg_players (
    citizenid VARCHAR(64) PRIMARY KEY,
    initialized BOOLEAN DEFAULT FALSE,
    rating INT DEFAULT 1500,
    wins INT DEFAULT 0,
    losses INT DEFAULT 0,
    draws INT DEFAULT 0,
    pvp_exp INT UNSIGNED NOT NULL DEFAULT 0,
    pvp_level INT UNSIGNED NOT NULL DEFAULT 1,
    pvp_win_streak INT UNSIGNED NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tcg_cards_master (
    card_id VARCHAR(32) PRIMARY KEY,
    name VARCHAR(64) NOT NULL,
    rank ENUM('UR','SS','S','A','B','C') NOT NULL,
    type ENUM('shitei','free') NOT NULL,
    stat_top TINYINT NOT NULL,
    stat_right TINYINT NOT NULL,
    stat_bottom TINYINT NOT NULL,
    stat_left TINYINT NOT NULL,
    image_path VARCHAR(128),
    description TEXT,
    no INT
);

CREATE TABLE IF NOT EXISTS tcg_player_cards (
    instance_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    citizenid VARCHAR(64) NOT NULL,
    card_id VARCHAR(32) NOT NULL,
    obtained_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    locked BOOLEAN DEFAULT FALSE,
    INDEX idx_owner (citizenid),
    INDEX idx_card (card_id),
    FOREIGN KEY (card_id) REFERENCES tcg_cards_master(card_id)
);

CREATE TABLE IF NOT EXISTS tcg_decks (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    citizenid VARCHAR(64) NOT NULL,
    name VARCHAR(64) NOT NULL,
    is_active BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_owner (citizenid),
    UNIQUE KEY uniq_owner_name (citizenid, name)
);

CREATE TABLE IF NOT EXISTS tcg_deck_cards (
    deck_id BIGINT NOT NULL,
    slot_index TINYINT NOT NULL,
    card_id VARCHAR(32) NOT NULL,
    PRIMARY KEY (deck_id, slot_index),
    FOREIGN KEY (deck_id) REFERENCES tcg_decks(id) ON DELETE CASCADE,
    FOREIGN KEY (card_id) REFERENCES tcg_cards_master(card_id)
);

CREATE TABLE IF NOT EXISTS tcg_admin_audit (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    actor_uid VARCHAR(128) NOT NULL,
    action VARCHAR(32) NOT NULL,
    card_id VARCHAR(32),
    detail_json TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_created (created_at),
    INDEX idx_card (card_id)
);

-- PHASE E1: リアル PvP・BattlePvp.Finish 経由で 1 試合 1 行（match_id = session_id UNIQUE）
CREATE TABLE IF NOT EXISTS tcg_match_history (
    match_id VARCHAR(128) NOT NULL PRIMARY KEY,
    finished_at INT UNSIGNED NOT NULL,
    reason VARCHAR(16) NOT NULL,
    is_real_pvp BOOLEAN NOT NULL DEFAULT TRUE,
    citizenid_a VARCHAR(64) NOT NULL,
    citizenid_b VARCHAR(64) NOT NULL,
    display_name_a VARCHAR(128) DEFAULT '',
    display_name_b VARCHAR(128) DEFAULT '',
    score_a INT NOT NULL,
    score_b INT NOT NULL,
    outcome_a ENUM('win', 'lose', 'draw') NOT NULL,
    rating_a_before INT UNSIGNED NOT NULL DEFAULT 1500,
    rating_a_after INT UNSIGNED NOT NULL DEFAULT 1500,
    rating_b_before INT UNSIGNED NOT NULL DEFAULT 1500,
    rating_b_after INT UNSIGNED NOT NULL DEFAULT 1500,
    defeat_copy_granted BOOLEAN NOT NULL DEFAULT FALSE,
    defeat_copy_card_id VARCHAR(32),
    season_id INT UNSIGNED NOT NULL DEFAULT 0,
    INDEX idx_citizen_a_time (citizenid_a, finished_at DESC),
    INDEX idx_citizen_b_time (citizenid_b, finished_at DESC),
    INDEX idx_finished (finished_at DESC)
);

-- PHASE C: リアル PvP normal 終了時のみ更新（BattleStats / BattleRewards）。JST 暦日キー・レイジー UPSERT
CREATE TABLE IF NOT EXISTS tcg_daily_counters (
    citizenid VARCHAR(64) NOT NULL,
    date_jst CHAR(10) NOT NULL,
    battles INT UNSIGNED NOT NULL DEFAULT 0,
    wins INT UNSIGNED NOT NULL DEFAULT 0,
    losses INT UNSIGNED NOT NULL DEFAULT 0,
    draws INT UNSIGNED NOT NULL DEFAULT 0,
    copies_received INT UNSIGNED NOT NULL DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (citizenid, date_jst),
    INDEX idx_date_jst (date_jst)
);

-- =============================================================================
-- ACE（jp-tcgbook デバッグコマンド /tcg_*）
-- すべてのデバッグコマンドは permission command.tcg_debug で制御する。
-- コンソール（source=0）はリソース側で常に許可。
--
-- server.cfg の例:
--   add_ace group.admin command.tcg_debug allow
--   add_principal identifier.license:xxxxxxxxxxxxxxxx group.admin
--
-- または txAdmin / 運営方針に合わせてグループへ付与する。
--
-- ACE（/bookadmin 管理者 UI）
--   add_ace group.admin command.tcg_book_admin allow
-- =============================================================================
