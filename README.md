# DynamicBar

**Version:** 0.5-beta
**Author:** Mark Sheldahl
**AI-Assisted Development:** This addon was created with assistance from Claude (Anthropic). While AI helped with code generation and problem-solving, all design decisions, testing, and creative direction came from human input.

## About

DynamicBar is a role-first, context-aware consumable action bar for WoW TBC Classic that reduces cognitive load during combat while remaining predictable and fully ToS-compliant.

### Core Features

- **Role-First Ordering** - Emergency items (Healthstone) → Health/Mana potions → Elixirs → Food/Drink → Hearthstone
- **Battle/Prep Modes** - Automatically switches between combat (essential items only) and out-of-combat (full suite) layouts
- **Dynamic Footprint** - Only shows buttons for items you actually have
- **Flyout Menus** - Right-click buttons to access alternative items
- **Smart Positioning** - Drag-to-move with visual feedback, per-character profiles
- **Auto-Skinning** - Automatically matches ElvUI, Masque, Dominos, or Bartender4 styling

### Design Philosophy

**Player Intent First:** Buttons represent capabilities, not fixed items. The addon assists decision-making but never automates gameplay.

**Combat Safety:** No layout changes during combat. Your muscle memory is protected.

**WoW ToS Compliance:** All actions require hardware events. No automation, no scripting, no AI decision-making.

## Commands

- `/dbar` or `/dbar help` - Show all commands
- `/dbar config` - Open configuration panel
- `/dbar profiles` - Manage character profiles
- `/dbar debug` - Toggle debug logging
- `/dbar profileinfo` - Show current profile status

## Installation

1. Extract to `World of Warcraft\_classic_\Interface\AddOns\`
2. Ensure the folder is named `DynamicBar`
3. Restart WoW or type `/reload`
4. On first login, you'll see a welcome popup to position the bar

## Configuration

Access via `/dbar config` or ESC → Interface → AddOns → DynamicBar

**Bar Layout:**
- Button count (1-12)
- Scale, spacing, padding
- ElvUI spacing inheritance

**Bar Position:**
- Presets: Bottom Center, Top Center, Screen Center, Custom
- Manual positioning with anchor points and offsets
- Lock/unlock toggle with visual "DRAG ME" overlay

**Visibility Mode:**
- **Fade Out (Recommended)** - Prep items fade during combat
- **Hide Completely** - Prep items disappear in combat
- **Grey Out** - Prep items shown but disabled
- **Always Show All** - All items visible always

## Battle vs Prep Mode

**Battle Mode (In Combat):**
- Healthstone
- Health Potions
- Mana Potions
- Bandages

**Prep Mode (Out of Combat):**
- All battle items +
- Battle Elixirs
- Guardian Elixirs
- Food (buff and non-buff)
- Drink
- Hearthstone

Mode switching is automatic and implicit. No manual toggling required.

## Supported Items (TBC Classic)

**Health Potions:** Minor → Super → Greater → Superior → Major Healing/Rejuvenation
**Mana Potions:** Minor → Greater → Superior → Major Mana/Rejuvenation
**Healthstone:** All warlock variants
**Battle Elixirs:** Strength, Agility, Mongoose, etc.
**Guardian Elixirs:** Fortitude, Defense, Major Defense, etc.
**Bandages:** Linen → Heavy Frostweave
**Food:** All Well Fed buff food + basic conjured food
**Drink:** All mana regeneration beverages
**Hearthstone:** Standard hearthstone

## Known Limitations (Beta)

- No Flask category yet (coming in next release)
- No quest/contextual items yet
- No weapon buffs/oils yet
- No visual mode indicators (implicit modes only)
- No export/import profile strings

## Attribution

This addon stands on the shoulders of decades of WoW addon innovation:

**Inspired By:**
- Action bar addons (Bartender, Dominos, ElvUI)
- Consumable management tools
- Combat UX improvements pioneered by the addon community

**Built With:**
- **Ace3 Framework** - nevcairiel, Mikk, Ammo, and contributors
- **LibStub** - Kaelten, Cladhaire, ckknight, Mikk, Ammo, Nevcairiel
- **CallbackHandler** - Nevcairiel and team

**AI Development Transparency:**
This addon was created with assistance from Claude (Anthropic's AI). The AI helped with:
- Code generation and structure
- Problem-solving and debugging
- WoW API usage and best practices
- Design pattern implementation

However, all creative decisions, feature prioritization, testing, and user experience design came from human direction. This project represents a collaboration between human creativity and AI technical assistance.

## Feedback & Support

**Beta Testing:** We're actively seeking feedback on:
- Battle/Prep mode UX
- First-time setup experience
- Item classification accuracy
- Combat safety and muscle memory
- Cross-addon compatibility

**Report Issues:**
- Include WoW version (TBC Classic 2.5.x)
- Steps to reproduce
- Any error messages from `/dbar debug`
- Other installed addons (especially UI/action bar addons)

## License

All Rights Reserved (Beta)

This is pre-release software. Distribution, modification, and commercial use are not permitted during beta testing phase.

## Acknowledgments

Huge thanks to:
- The WoW addon development community
- Ace3 framework maintainers
- ElvUI, Masque, Dominos, and Bartender teams
- Beta testers and early adopters
- Every addon creator who pioneered UX improvements over the past 20 years

Your innovations made this possible.

---

**Remember:** This addon assists, it does not automate. Every action requires your click. Every decision is yours.
