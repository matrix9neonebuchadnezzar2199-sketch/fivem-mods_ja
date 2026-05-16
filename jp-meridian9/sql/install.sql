-- ============================================================
-- MERIDIAN-9 / Project JANUS  DBスキーマ
-- ============================================================
-- 実行方法:
--   MySQL クライアントで対象 DB に接続後、本ファイルを流し込む。
--   例: mysql -u root -p fivem_db < install.sql
--
-- 注意:
--   - 文字コードは utf8mb4 を必須とする（日本語アイテム名等を保存するため）
--   - 既存テーブルは DROP しない（運用中の上書き事故を防止）
--   - スキーマ変更時は別途マイグレーションファイルを用意する
-- ============================================================

-- ------------------------------------------------------------
-- 契約者テーブル
-- ------------------------------------------------------------
-- ヴェガと契約を結んだプレイヤーを管理する。
-- identifier は FiveM の license:xxx 形式を使用。
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `mrd9_contracts` (
    `identifier`  VARCHAR(64)   NOT NULL COMMENT 'プレイヤー識別子（license:xxx）',
    `signed_at`   DATETIME      NOT NULL COMMENT '契約締結日時',
    `status`      ENUM('active', 'suspended', 'terminated') NOT NULL DEFAULT 'active' COMMENT '契約状態',
    `notes`       TEXT          NULL     COMMENT '運営メモ（自由記述）',
    PRIMARY KEY (`identifier`),
    INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='MERIDIAN-9 契約者管理';

-- ------------------------------------------------------------
-- 統計テーブル
-- ------------------------------------------------------------
-- 各契約者の累計成績を保存する。
-- ミッション終了時に UPDATE で更新する設計。
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `mrd9_stats` (
    `identifier`              VARCHAR(64)  NOT NULL COMMENT 'プレイヤー識別子',
    `total_missions`          INT          NOT NULL DEFAULT 0 COMMENT '総ミッション参加回数',
    `total_extracts`          INT          NOT NULL DEFAULT 0 COMMENT '脱出成功回数',
    `total_deaths`            INT          NOT NULL DEFAULT 0 COMMENT '死亡回数',
    `total_earnings`          BIGINT       NOT NULL DEFAULT 0 COMMENT '累計報酬額',
    `best_extract_value`      INT          NOT NULL DEFAULT 0 COMMENT '一回の最高回収額',
    `fastest_extract_seconds` INT          NULL              COMMENT '最速脱出時間（秒）',
    `last_mission_at`         DATETIME     NULL              COMMENT '最終参加日時',
    PRIMARY KEY (`identifier`),
    CONSTRAINT `fk_mrd9_stats_contracts`
        FOREIGN KEY (`identifier`) REFERENCES `mrd9_contracts` (`identifier`)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='MERIDIAN-9 プレイヤー統計';

-- ------------------------------------------------------------
-- ミッション履歴テーブル
-- ------------------------------------------------------------
-- 各セッションの結果を記録する。ランキング表示・運営分析に使用。
-- 大量データになるため、定期的なアーカイブを推奨。
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `mrd9_mission_logs` (
    `id`                   BIGINT        NOT NULL AUTO_INCREMENT,
    `session_id`           VARCHAR(32)   NOT NULL COMMENT 'セッション識別子',
    `identifier`           VARCHAR(64)   NOT NULL COMMENT 'プレイヤー識別子',
    `started_at`           DATETIME      NOT NULL COMMENT 'ミッション開始日時',
    `ended_at`             DATETIME      NULL     COMMENT 'ミッション終了日時',
    `outcome`              ENUM('extracted', 'died', 'timeout', 'aborted') NULL COMMENT '結果',
    `items_recovered_json` JSON          NULL     COMMENT '回収アイテム一覧（JSON）',
    `earnings`             INT           NOT NULL DEFAULT 0 COMMENT 'このミッションの報酬額',
    `mission_type`         VARCHAR(32)   NULL     COMMENT 'ミッション種別',
    `difficulty`           VARCHAR(16)   NULL     COMMENT '難易度',
    PRIMARY KEY (`id`),
    INDEX `idx_identifier`  (`identifier`),
    INDEX `idx_session`     (`session_id`),
    INDEX `idx_outcome`     (`outcome`),
    INDEX `idx_started_at`  (`started_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='MERIDIAN-9 ミッション履歴';

-- ------------------------------------------------------------
-- ルート回収監査ログ（案X: 拒否含む全試行を記録。細分は fail_reason）
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `mrd9_loot_logs` (
    `id`                 BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `player_identifier`  VARCHAR(64)   NOT NULL,
    `session_id`         VARCHAR(64)   NOT NULL,
    `mission_id`         VARCHAR(64)   NULL COMMENT '現状は session.mission.type を格納',
    `loot_id`            VARCHAR(64)   NOT NULL,
    `tier`               VARCHAR(16)   NOT NULL,
    `item_id`            VARCHAR(64)   NOT NULL,
    `count`              INT           NOT NULL DEFAULT 1,
    `coords_x`           FLOAT         NULL,
    `coords_y`           FLOAT         NULL,
    `coords_z`           FLOAT         NULL,
    `result`             ENUM(
                              'granted',
                              'failed_inventory_full',
                              'failed_locked',
                              'failed_distance',
                              'failed_other'
                          ) NOT NULL,
    `fail_reason`        VARCHAR(128)  NULL,
    `created_at`         DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_loot_player`   (`player_identifier`),
    INDEX `idx_loot_session`  (`session_id`),
    INDEX `idx_loot_mission`  (`mission_id`),
    INDEX `idx_loot_tier_res` (`tier`, `result`),
    INDEX `idx_loot_created`  (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='MERIDIAN-9 ルート回収監査';

-- ------------------------------------------------------------
-- fictionTag 近接演出ログ（mrd9_loot_logs とは別軸）
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `mrd9_fiction_events` (
    `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `session_id`      VARCHAR(64)   NOT NULL,
    `loot_id`         VARCHAR(64)   NOT NULL,
    `fiction_tag`     VARCHAR(32)   NOT NULL,
    `event_type`      VARCHAR(32)   NOT NULL,
    `triggered_by`    VARCHAR(64)   NOT NULL,
    `coords_x`        FLOAT         NULL,
    `coords_y`        FLOAT         NULL,
    `coords_z`        FLOAT         NULL,
    `created_at`      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_fiction_session` (`session_id`),
    INDEX `idx_fiction_tag` (`fiction_tag`),
    INDEX `idx_fiction_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='MERIDIAN-9 fictionTag 演出ログ';

-- ------------------------------------------------------------
-- 任務リザルトログ（脱出査定 / 死亡 / 切断）
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `mrd9_result_logs` (
    `id`                 BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `player_identifier`  VARCHAR(64)   NOT NULL,
    `session_id`         VARCHAR(64)   NOT NULL,
    `mission_id`         VARCHAR(64)   NULL,
    `result`             ENUM('extracted', 'died', 'disconnect', 'forced', 'timeout', 'out_of_zone', 'unknown') NOT NULL DEFAULT 'unknown',
    `items_subtotal`     INT           NOT NULL DEFAULT 0,
    `fiction_bounty`     INT           NOT NULL DEFAULT 0,
    `extraction_bonus`   INT           NOT NULL DEFAULT 0,
    `total`              INT           NOT NULL DEFAULT 0,
    `credit_count`       INT           NOT NULL DEFAULT 0,
    `item_count`         INT           NOT NULL DEFAULT 0,
    `fiction_item_count` INT           NOT NULL DEFAULT 0,
    `payout_mode`        VARCHAR(32)   NOT NULL DEFAULT 'unknown',
    `fail_reason`        VARCHAR(128)  NULL,
    `created_at`         DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_result_player`  (`player_identifier`),
    INDEX `idx_result_session` (`session_id`),
    INDEX `idx_result_outcome` (`result`),
    INDEX `idx_result_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='MERIDIAN-9 任務リザルト';

-- ============================================================
-- インストール完了確認用クエリ（任意）
-- ============================================================
-- SELECT TABLE_NAME, TABLE_COMMENT
-- FROM   INFORMATION_SCHEMA.TABLES
-- WHERE  TABLE_SCHEMA = DATABASE()
--   AND  TABLE_NAME LIKE 'mrd9_%';
