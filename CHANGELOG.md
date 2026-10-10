# Changelog

## [Unreleased]

### Added
- WoW Forever support (Interface 16001, Mainline-based client)
- Bar Slots: pick which categories appear on the bar and their order; the bar has one button per chosen category (replaces the Button Count slider). Existing button count and slot order settings carry over
- Bar Builder (`/dbar builder`): drag-and-drop window for choosing and ordering the bar's categories, replacing the checkbox list in settings

### Fixed
- Combat transitions use secure state drivers: prep-only actions are disabled, visibility preferences apply, and open flyouts close without reassigning buttons
- Right-click opens alternatives without consuming the primary item; selecting an alternative closes its flyout
- Added the documented DynamicBar keybinding section for all 12 buttons
- Combat exit rescans bags before resolving items
- Slash and options disabling clear button actions and flyouts, with changes deferred until combat ends
- Unused buttons clear their flyouts, item identifiers, and cooldown displays
- Rejuvenation slots only select items classified as rejuvenation potions
- Save & Lock stays available while positioning; first-time setup completes on locking
- Item info/count calls fall back to `C_Item` where the old globals are gone
- Item classification reads tooltip text via `C_TooltipInfo` when available
- Events the client doesn't know are skipped instead of erroring on load
- Cooldown spirals handle secret cooldown values in combat
- Item icon lookup read the wrong return from `GetItemInfoInstant`
- Config panel error on WoW Forever (bundled Ace3 updated to r1403)

### Changed
- Code cleanup: shared bar rebuild logic across display modes, shared config get/set, table-driven resolvers and flyout layouts
- Cooldowns are looked up by item instead of scanning every bag slot
- Removed unused Ace3 modules

### Fixed
- Static mode no longer re-shows a stale flyout when hovering an empty slot
- Lowering the button count in Dynamic mode now hides the extra buttons
- Grid layouts expand rows when needed to fit every configured button (default 2×6)

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
