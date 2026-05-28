# Changelog

All notable changes to **jp-mi-train** are documented in this file.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.3.1] - 2026-05-28

### Fixed

- `HideHelp` nil error on heli boarding (`EnterInterior` called before UI helpers were defined).
- Interior walk blocked by freight wagon collision; only DBuz747 floor collides while inside.
- Crash on dismount: disable addon collision before teleporting player beside train.
- Addon model load: stop using `IsModelInCdimage` for add-on vehicles (use `RequestModel` + `HasModelLoaded`).

### Changed

- Raise DBuz747 attach height (`attachOffset.z` 1.05) and no-collision between addon and parent freight.
- Heli `[E]` boards **directly into carriage interior** (no roof step).

## [0.3.0] - 2026-05-28

### Added

- Direct heli-to-interior boarding (`boardDirectToInterior`).
- Safe exit (`SafeExitTrain`) with `[E] 列車から降りる` and auto-exit when leaving interior bounds.
- NPC reset option (ox_target) with `prepareReset` before heist cleanup.
- `resetAllowAnyone` for lab servers.

## [0.2.0] - 2026-05-27

### Added

- DBuz747 hybrid attach (`addon_carriage.lua`).
- Host entity blip, coordinate relay, spawn model preload.
- Phase 1 heist flow: start NPC, mission train, heli approach.

## [0.1.0] - 2026-05-27

### Added

- Initial MVP: mission train loop, heli boarding, host management, `/mitrain` admin commands.
