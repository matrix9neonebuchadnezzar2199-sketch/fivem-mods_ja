-- v0.4.0: PK先攻チーム、選手退場メタ、PK成功フラグ
SET NAMES utf8mb4;

ALTER TABLE matches
  ADD COLUMN pk_first_team_id BIGINT NULL AFTER current_half;

ALTER TABLE match_players
  ADD COLUMN ejected_at_ms BIGINT NULL AFTER yellow_cards,
  ADD COLUMN ejection_reason VARCHAR(64) NULL AFTER ejected_at_ms;

ALTER TABLE match_events
  ADD COLUMN penalty_success TINYINT(1) NULL AFTER sub_out_player_id;
