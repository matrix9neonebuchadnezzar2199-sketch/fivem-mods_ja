CREATE TABLE IF NOT EXISTS jp_sentinel_cooldowns (
    identifier VARCHAR(64) PRIMARY KEY,
    last_used_at INT NOT NULL
);
