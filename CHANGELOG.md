# Changelog

## [0.5-beta] - 2026-01-18

### Added - Battle/Prep Mode System
- **Implicit mode switching** between combat and out-of-combat layouts
- **Battle Mode (in combat):** Emergency items only (Healthstone, potions, bandages)
- **Prep Mode (out of combat):** Full consumable suite (elixirs, food, drink, utility)
- **Frozen combat layout** - No button changes during combat for muscle memory protection
- **Visibility modes** - Choose how unavailable items display (Fade, Hide, Grey, Always)
- **Combat state tracking** - Proper `_inCombat` flag to avoid race conditions

### Added - UI/UX Features
- **Drag-to-move bar positioning** with visual "DRAG ME" overlay
- **Lock/unlock system** with one-click "Save & Lock" button
- **First-time setup popup** - Welcome screen for new characters (8-second delay for ElvUI compatibility)
- **Position presets** - Bottom Center, Top Center, Screen Center, Custom
- **Movable config window** - Drag title bar to reposition
- **Compact default spacing** - Tighter 2px spacing (was 6px) for Blizzard-like appearance

### Added - Button Skinning System
- **Auto-detection** for ElvUI, Masque, Dominos, Bartender4
- **Enhanced Blizzard default** - Proper textures, highlights, cooldown frames
- **ElvUI spacing inheritance** - Automatically matches ElvUI button spacing
- **Cooldown spirals** - Standard CooldownFrameTemplate integration

### Added - Profile System
- **Character-specific profiles** - Each character isolated (CharacterName - RealmName)
- **Per-character setup tracking** - `_setupComplete` flag properly isolated
- **Profile management UI** - Full AceDB profile support

### Added - Debug Tools
- **Persistent debug logging** - Debug messages saved to SavedVariables for easy bug reporting
- `/dbar debug` - Toggle debug logging (now logs to chat AND SavedVariables)
- `/dbar debuglog` - Display persistent debug log (last 100 entries)
- `/dbar clearlog` - Clear debug log
- `/dbar profileinfo` - Show current profile name and setup status
- `/dbar resetsetup` - Re-trigger first-time setup popup
- Enhanced debug output for combat mode transitions

### Fixed
- **Critical:** All characters were sharing "Default" profile instead of character-specific
- **Combat safety:** Race conditions with `InCombatLockdown()` during mode transitions
- **Visual:** Lock overlay now properly shows above buttons (HIGH strata, level 200)
- **Config:** ElvUI users get tighter spacing automatically
- **Profiles:** First-time setup flag now truly per-character

### Technical
- Proper event handling for `PLAYER_REGEN_ENABLED` and `PLAYER_REGEN_DISABLED`
- Combat state flag set BEFORE rebuild to avoid race conditions
- Pending rebuild queue for config changes made during combat
- Flyouts auto-hide on combat start for clean UX

---

## [0.4] - 2025-XX-XX (Pre-Beta)

### Added - Core Functionality
- Role-first button ordering (Emergency → Health/Mana → Elixirs → Bandages → Food/Drink → Hearthstone)
- Dynamic footprint (only shows buttons for items you have)
- Item resolution system (automatically selects best item per slot)
- Flyout menus (right-click for alternatives)
- Secure action buttons (WoW ToS compliant)

### Added - Item Classification
- Health potions (Minor → Major Healing/Rejuvenation)
- Mana potions (Minor → Major Mana/Rejuvenation)
- Healthstone (all warlock variants)
- Battle elixirs (offensive buffs)
- Guardian elixirs (defensive buffs)
- Bandages (all cloth types)
- Food (Well Fed buff variants)
- Drink (mana regeneration)
- Hearthstone

### Added - Configuration
- AceDB integration with per-character profiles
- Comprehensive config panel
- Button count adjustment (1-12)
- Bar scale, spacing, padding controls
- Position presets

### Technical
- Ace3 framework integration
- Bag cache system with pending retry logic
- Item classifier with tooltip-based categorization
- Resolver system for item priority
- TBC Classic compatibility (Interface-BCC: 20505)

---

## Development Notes

All versions co-authored by Claude Sonnet 4.5 (Anthropic) with human direction and testing along with human coding input.

### Version Numbering
- **0.x-beta:** Beta testing phase
- **1.0:** First stable release
- **x.y.z:** Major.Minor.Patch
