# Changelog

## [0.6] - 2026-01-19

### Added
- **Flask Support** - Added Flask category with automatic detection and prioritization
  - Supports all TBC Classic flasks (Blinding Light, Pure Death, Relentless Assault, Fortification, etc.)
  - Flasks appear in Prep Mode between Guardian Elixirs and Food
  - Flyout menu shows all available flasks in priority order
  - Follows role-first ordering from Design Contract

- **Rejuvenation Potion Support** - Added support for dual health+mana restoration potions
  - Supports Super, Major, and Minor Rejuvenation Potions
  - Appears in Battle Mode after Mana Potion (useful for hybrid classes: Paladin, Druid, Shaman)
  - Automatically detected via tooltip parsing (restores both health and mana)
  - Flyout menu shows all available rejuvenation potions in priority order

- **Button Display Modes** - Configurable handling of empty button slots
  - **Smart Mode (Default/Recommended)** - Empty buttons are invisible but space is reserved for stable keybinds
  - **Static Mode** - All configured buttons always visible, including empty slots
  - **Dynamic Mode** - Bar auto-collapses to fit available items (⚠️ WARNING: Breaks keybinds as button positions shift)
  - Confirmation dialog warns users when switching to Dynamic mode
  - Enhanced descriptions with color-coded labels and keybind stability explanations
  - Accessible via `/dbar config` → Bar Layout → "Empty Button Slots"

- **Keybind Stability Documentation** - Added comprehensive documentation
  - New "Keybind Stability" section in README explaining which modes preserve keybinds
  - Config panel now clearly indicates which modes are "binding-safe"
  - Instructions on how to set keybinds in WoW

### Changed
- **Default button count increased from 11 to 12** - Accommodates new Rejuvenation Potion slot
- **Debug messages are now declarative** - Changed from tentative language ("requesting", "attempting") to factual statements
- **Silent rebuild operations** - UpdateLockState() no longer spams "Bar locked" messages during normal rebuilds

### Fixed
- **Performance: Flyout hover stuttering** - Removed redundant SetFrameStrata/SetFrameLevel calls from hot path (95%+ overhead reduction)
- **UX: Message spam** - Added silent parameter to UpdateLockState() to prevent chat spam during automatic operations

## [0.5-beta] - 2026-01-18
English only clients, localization planned.
