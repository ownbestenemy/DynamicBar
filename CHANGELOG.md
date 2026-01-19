# Changelog

## [0.6] - TBD

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
  - Accessible via `/dbar config` → Bar Layout → "Empty Button Slots"

### Changed
- **Default button count increased from 11 to 12** - Accommodates new Rejuvenation Potion slot

## [0.5-beta] - 2026-01-18
English only clients, localization planned.
