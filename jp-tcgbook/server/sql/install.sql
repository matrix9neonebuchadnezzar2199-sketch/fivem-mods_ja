-- jp-tcgbook スキーマ（カードマスタの INSERT は行わない。起動時に shared/cards.lua から UPSERT）
-- MariaDB / MySQL 想定

CREATE TABLE IF NOT EXISTS tcg_players (
    citizenid VARCHAR(64) PRIMARY KEY,
    initialized BOOLEAN DEFAULT FALSE,
    rating INT DEFAULT 1500,
    wins INT DEFAULT 0,
    losses INT DEFAULT 0,
    draws INT DEFAULT 0,
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
-- =============================================================================
