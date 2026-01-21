# Changelog

## [Unreleased]

### Added
- **Bar Layout Modes** - Choose between horizontal (default), vertical, or grid (NxM) layouts
- Grid layout system with customizable rows and columns
- Independent horizontal and vertical spacing controls for grid layouts
- Advanced per-edge padding controls (left, right, top, bottom)
- Layout mode selector in config UI

### Changed
- ElvUI spacing inheritance now only applies to horizontal layout mode
- Spacing controls are now mode-aware (single "Spacing" control for vertical mode)

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
