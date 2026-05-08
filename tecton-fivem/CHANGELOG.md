# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added

- feat: SQL schema is now automatically applied on resource start (no more manual `install.sql` execution needed).
- feat: migration system for future schema upgrades (`sql/migrations/`, `tec_schema_version`, `server/migrate.lua`).
- feat(web): category tree and virtualized prop list from `Config.Props` (`tecton:props:fetch`, M2-a).
