# Changelog

## [1.0] - 2026-02-01

First stable release! Complete consumable bar for TBC Classic.

### Features
- **12-Slot Consumable Bar** - Health Potions, Mana Potions, Rejuvenation Potions, Healthstones, Dark Runes, Bandages, Battle Elixirs, Guardian Elixirs, Flasks, Buff Food, Basic Food, Drinks, Hearthstone
- **Flyout Menus** - Hover any slot to see all available items of that type, sorted by potency
- **Battle/Prep Mode** - Combat-only items stay visible; prep items (elixirs, food, drink) auto-hide in combat
- **Tabbed Config Panel** - General, Appearance, Behavior, and Profiles tabs for organized settings
- **Layout Modes** - Horizontal (default), Vertical, or Grid layouts
- **Slot Priority Reordering** - Customize which consumables appear when using fewer than 12 buttons
- **Button Display Modes** - Smart (keybind-safe), Static (show all), or Dynamic (auto-resize)
- **Visibility Modes** - Fade, Hide, Grey, or Always show unavailable items
- **Drag-to-Position** - Unlock bar, drag to desired location, click Save & Lock
- **First-Time Setup** - Guided positioning on first login
- **ElvUI Integration** - Auto-inherit button spacing and styling
- **Cooldown Timers** - Visual cooldown spirals on all buttons
- **Localization Framework** - 8 languages supported (UI strings)

### Fixed
- Rejuvenation potion detection now correctly identifies all variants
- Missing elixir items added to classification
- Item classification retry system now properly handles new items
- Flyout buttons clear correctly when item lists shrink
- Combat item counts update in real-time
- TBC Classic API compatibility throughout

## [0.6.5] - 2026-01-23

### Fixed
- Lock/unlock bar error in config panel (TBC compatibility)

## [0.6.4] - 2026-01-22

### Fixed
- Empty flyout buttons appearing after selling items

## [0.6.3] - 2026-01-22

### Fixed
- Stale flyout items after consuming/deleting items

## [0.6.2] - 2026-01-21

### Fixed
- Item counts not updating mid-combat
- CurseForge app installation (directory structure)

## [0.6.1] - 2026-01-19

### Fixed
- Depleted items now fade during combat
- Prep-only slots fully cleared in combat (keybinds safe)

## [0.6] - 2026-01-19

### Added
- Flask support
- Rejuvenation Potion slot
- Display modes (Smart/Static/Dynamic)

### Fixed
- Flyout performance (95%+ improvement)

## [0.5-beta] - 2026-01-18

Initial public release.
