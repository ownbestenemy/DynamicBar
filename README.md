# DynamicBar

**Author:** Mark Sheldahl
**AI use:** Much of the code is written by AI coding assistants (Claude and Codex) at Mark's direction. Mark decides what goes in and tests in game; an automated test suite runs on every push. Details under [AI Development Transparency](#attribution).

## About

DynamicBar is a role-first, context-aware consumable action bar for TBC Classic and WoW Forever that reduces cognitive load during combat while remaining predictable and fully ToS-compliant.

### Core Features

- **Role-First Ordering** - Emergency items (Healthstone) → Health/Mana potions → Elixirs → Food/Drink → Hearthstone
- **Battle/Prep Modes** - Automatically switches between combat (essential items only) and out-of-combat (full suite) layouts
- **Dynamic Footprint** - Only shows buttons for items you actually have
- **Flyout Menus** - Right-click a button to pick an alternative item
- **Smart Positioning** - Drag-to-move with visual feedback, per-character profiles
- **Auto-Skinning** - Uses ElvUI's button style, or your Masque skin, when either is installed

### Design Philosophy

**Player Intent First:** Buttons represent capabilities, not fixed items. The addon assists decision-making but never automates gameplay.

**Combat Safety:** No layout changes during combat. Your muscle memory is protected.

**WoW ToS Compliance:** All actions require hardware events. No automation, no scripting, no AI decision-making.

## Commands

- `/dbar` or `/dbar help` - Show all commands
- `/dbar config` - Open configuration panel
- `/dbar builder` - Open the Bar Builder to choose which categories are on the bar
- `/dbar profiles` - Manage character profiles
- `/dbar debug` - Toggle debug logging
- `/dbar profileinfo` - Show current profile status

## Installation

1. Extract to the `Interface\AddOns\` folder of your game client
2. Ensure the folder is named `DynamicBar`
3. Restart WoW or type `/reload`
4. On first login, you'll see a welcome popup to position the bar

## Configuration

Access via `/dbar config` or ESC → Interface → AddOns → DynamicBar

**Bar Layout:**
- **Layout Modes:**
  - **Horizontal** (default) - Single row of buttons
  - **Vertical** - Single column of buttons
  - **Grid** - Customizable rows × columns (e.g., 2×5, 3×4, 5×2)
- Bar Builder (`/dbar builder`): drag consumable categories onto the bar, reorder them, or drag them off (one button per category)
- Scale adjustments
- Horizontal and vertical spacing (grid mode supports both independently)
- Edge padding (basic unified padding or advanced per-edge control)
- ElvUI spacing inheritance (horizontal mode only)

**Bar Position:**
- Presets: Bottom Center, Top Center, Screen Center, Custom
- Manual positioning with anchor points and offsets
- Lock/unlock toggle with visual "DRAG ME" overlay
- WoW Forever: opening Edit Mode shows a drag handle on the bar, and it locks again when Edit Mode closes

**Visibility Mode:**
- **Fade Out (Recommended)** - Prep items fade during combat
- **Hide Completely** - Prep items disappear in combat
- **Grey Out** - Prep items shown but disabled
- **Always Show All** - All items visible always

**Button Display Modes:**
- **Smart (Recommended)** - Empty buttons are hidden but space reserved (stable keybinds)
- **Static** - All buttons always visible, including empty slots
- **Dynamic** - Bar shrinks/grows with items (⚠️ breaks keybinds)

### Keybind Stability

**Important:** For stable keybinds, use **Smart** or **Static** mode.

- **Smart Mode (Recommended)**: Empty buttons are hidden but button positions never change. Keybind 1 always executes button 1, even if slots 2-5 are empty.
- **Static Mode**: All buttons always visible (including empty slots). Keybinds remain stable.
- **Dynamic Mode**: ⚠️ Button positions shift as items appear/disappear. Keybinds will break - not recommended if you use keybinds.

To set keybinds: Press `ESC` → `Key Bindings` → scroll to `DynamicBar` section.

## Battle vs Prep Mode

**Battle Mode (In Combat):**
- Healthstone
- Health Potions
- Mana Potions
- Rejuvenation Potions
- Bandages
- Hearthstone

**Prep Mode (Out of Combat):**
- All battle items +
- Battle Elixirs
- Guardian Elixirs
- Flasks
- Other Buffs (Oil of Olaf, scrolls)
- Food (buff and non-buff)
- Drink

Mode switching is automatic and implicit. No manual toggling required.

## Supported Items (TBC Classic)

**Health Potions:** Minor → Super → Greater → Superior → Major Healing
**Mana Potions:** Minor → Greater → Superior → Major Mana
**Rejuvenation Potions:** Minor → Major → Super Rejuvenation (restores both health + mana)
**Healthstone:** All warlock variants
**Battle Elixirs:** First elixir found in bags (use flyout menu to select specific elixir if you have multiple types)
**Guardian Elixirs:** Fortitude, Defense, Major Defense, etc.
**Other Buffs:** Oil of Olaf and stat/armor scrolls
**Flasks:** Blinding Light, Pure Death, Relentless Assault, Fortification, Chromatic Wonder, Titans, etc.
**Bandages:** Linen → Netherweave (TBC highest tier)
**Food:** All Well Fed buff food + basic conjured food
**Drink:** All mana regeneration beverages
**Hearthstone:** Standard hearthstone

## Known Limitations (Beta)

- **Non-English clients** - Most slots work in any language; elixir type and restore amounts need translated tooltip phrases, and menus show English until a translation for your language is entered on CurseForge
- No quest/contextual items yet
- No weapon buffs/oils yet
- No visual mode indicators (implicit modes only)
- No export/import profile strings

## Attribution

This addon stands on the shoulders of decades of WoW addon innovation:

**Built With:**
- **Ace3 Framework** - nevcairiel, Mikk, Ammo, and contributors
- **LibStub** - Kaelten, Cladhaire, ckknight, Mikk, Ammo, Nevcairiel
- **CallbackHandler** - Nevcairiel and team

**AI Development Transparency:**
Much of DynamicBar's code is written by AI coding assistants (Claude by Anthropic, and Codex by OpenAI), working from Mark's requests. Mark chooses the features, merges each change, and tests in game.

What is checked, and how:
- `tests/run.lua` runs the addon's real modules against mocked WoW APIs on every push (GitHub Actions). It cannot reproduce taint, real key presses, or client differences.
- `tests/README.md` lists the in-game checks for both clients. Features not yet confirmed in game are listed in the changelog or Known Limitations.

If something does not work as described here, please report it.

## Feedback & Support

**Beta Testing:** We're actively seeking feedback on:
- Battle/Prep mode UX
- First-time setup experience
- Item classification accuracy
- Combat safety and muscle memory
- Cross-addon compatibility

**Report Issues:**
- Include your client (TBC Classic 2.5.x or WoW Forever) and its version
- Steps to reproduce
- Enable debug mode with `/dbar debug` and reproduce the issue
- Use `/dbar debuglog` to view persistent debug messages
- Share debug log by copying chat output or finding it in `WTF/Account/YourAccount/SavedVariables/DynamicBarDB.lua` (global.debugLog section)
- Other installed addons (especially UI/action bar addons)

**Debug Commands:**
- `/dbar debug` - Toggle debug mode (logs to chat and SavedVariables)
- `/dbar debuglog` - Display persistent debug log (last 100 entries)
- `/dbar clearlog` - Clear debug log
- `/dbar dump` - Dump current bag/item state
- `/dbar pending` - List items pending classification

## License

MIT. See [LICENSE](LICENSE).

## Acknowledgments

**AutoBar** by MuffinManKen pioneered smart consumable management in WoW addons. If you're looking for a mature, feature-rich solution with years of development, check out AutoBar first - it's the gold standard and has paved the way for addons like this one.

DynamicBar exists because I wanted something specific: minimal footprint, explicit control over what appears when, and a codebase I understand completely. It's a personal tool I'm sharing, not a competitor. Use what works for you.

Huge thanks to:
- MuffinManKen and the AutoBar project for pioneering this addon category
- The WoW addon development community
- Ace3 framework maintainers
- ElvUI, Masque, Dominos, and Bartender teams
- Beta testers and early adopters
- Every addon creator who pioneered UX improvements over the past 20 years

Your innovations made this possible.

---

**Remember:** This addon assists, it does not automate. Every action requires your click. Every decision is yours.
