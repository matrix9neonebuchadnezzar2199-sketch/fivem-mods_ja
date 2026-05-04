CREATE TABLE `blackmarket_levels` (
    `identifier` VARCHAR(64) NOT NULL,
    `blackmarket` VARCHAR(64) NOT NULL,
    `xp` INTEGER DEFAULT 0,
    PRIMARY KEY (`identifier`, `blackmarket`)
);