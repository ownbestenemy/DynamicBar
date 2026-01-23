# Changelog

## [0.6.5] - 2026-01-23

### Fixed
- **Lock/unlock bar error** - Fixed SetBackdrop API error when toggling bar lock in config (TBC Classic compatibility)

## [0.6.4] - 2026-01-22

### Fixed
- **Empty flyout buttons on hover** - Fixed flyout showing cleared (black) buttons when hovering after item list shrinks

## [0.6.3] - 2026-01-22

### Fixed
- **Stale flyout items** - Flyout buttons now clear properly when item list shrinks (e.g., selling bandages no longer leaves empty flyout slots)

## [0.6.2] - 2026-01-21

### Fixed
- **Stale item counts in combat** - Item counts now update immediately when consuming potions/bandages mid-combat
- **CurseForge App install** - Fixed zip directory structure for proper installation via CurseForge app

## [0.6.1] - 2026-01-19

### Fixed
- **Depleted items now fade during combat** - When you use your last potion/bandage, the button fades to indicate it's empty
- **Prep-only slots fully disabled in combat** - Elixirs, flasks, food, and drink buttons are now completely cleared during combat (keybinds cannot accidentally fire them)

## [0.6] - 2026-01-19

### Added
- **Flask Support** - Flasks now appear between Guardian Elixirs and Food in prep mode
- **Rejuvenation Potions** - Dual health+mana potions appear after Mana Potion (great for hybrids)
- **Button Display Modes** - Choose how empty slots behave:
  - Smart (default): Empty buttons hidden, keybinds stable
  - Static: All slots visible, keybinds stable
  - Dynamic: Bar auto-sizes (warning: breaks keybinds)

### Changed
- Default button count: 12 (was 11)
- Quieter debug messages

### Fixed
- Flyout hover stuttering (95%+ performance improvement)
- Chat spam from automatic rebuilds

## [0.5-beta] - 2026-01-18

Initial public release. English only.
