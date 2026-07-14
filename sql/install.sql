CREATE TABLE IF NOT EXISTS `fd_djkabin_booths` (
    `id` VARCHAR(50) NOT NULL,
    `label` VARCHAR(100) NOT NULL,
    `x` FLOAT NOT NULL,
    `y` FLOAT NOT NULL,
    `z` FLOAT NOT NULL,
    `heading` FLOAT NOT NULL DEFAULT 0.0,
    `settings` LONGTEXT NULL,
    `jobs` LONGTEXT NULL,
    `public` TINYINT(1) NOT NULL DEFAULT 0,
    `from_config` TINYINT(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `fd_djkabin_playlists` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `booth_id` VARCHAR(50) NULL,
    `owner` VARCHAR(80) NULL,
    `name` VARCHAR(100) NOT NULL,
    `tracks` LONGTEXT NOT NULL,
    PRIMARY KEY (`id`),
    KEY `booth_id` (`booth_id`)
);
