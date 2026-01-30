# DynamicBar - Addon Page Content

Use the sections below for your CurseForge addon page.

---

## Description (Main)

**DynamicBar** is a smart consumable action bar for TBC Classic that automatically shows the right items at the right time.

### How It Works

DynamicBar creates a single action bar with 12 slots, each dedicated to a specific consumable category. The bar automatically:

- **Shows your best available item** in each slot (highest-level health potion you have, best food, etc.)
- **Reveals alternatives on hover** - mouse over a slot to see all items you have for that category
- **Hides prep-only items during combat** - elixirs, flasks, food, and drink buttons are cleared when combat starts (no accidental buff food clicks mid-fight)
- **Fades depleted items** - when you use your last potion, the button fades to show it's empty

### The 12 Slots

| Slot | Category | Combat? | Notes |
|------|----------|---------|-------|
| 1 | Health Potion | ✓ | Shows best healing potion |
| 2 | Mana Potion | ✓ | Shows best mana potion |
| 3 | Rejuv Potion | ✓ | Dual health+mana pots |
| 4 | Healthstone | ✓ | Warlock stones |
| 5 | Bandage | ✓ | First aid |
| 6 | Battle Elixir | Prep | Attack power, spell power, etc. |
| 7 | Guardian Elixir | Prep | Armor, health, resistances |
| 8 | Flask | Prep | If you have one |
| 9 | Food | Prep | Buff food priority |
| 10 | Drink | Prep | Mana drinks |
| 11 | Utility | ✓ | Limited Invulnerability Potion, etc. |
| 12 | Hearthstone | ✓ | Always available |

### Flyout System

**Hover over any slot** to see a flyout with all matching items in your bags. Items are sorted by quality/level with the best at the bottom (closest to your cursor).

Example: Hover over Health Potion slot → see all your healing potions from best to worst.

---

## Features

### Smart Display Modes

Choose how empty slots behave:

- **Smart (Default)** - Empty buttons are hidden but keep their position. Your keybinds stay stable.
- **Static** - All 12 slots always visible, even when empty. Keybinds stable.
- **Dynamic** - Bar auto-sizes to only show available items. **Warning:** This mode shifts button positions, which breaks keybinds.

### Combat Safety

- Prep-only slots (elixirs, flasks, food, drink) are **completely cleared** during combat
- Keybinds on cleared slots do nothing - no risk of wasting buff food mid-fight
- Items fade when depleted so you know at a glance what's empty

### Customization

- Adjust button count (1-12)
- Change button size
- Choose button skin (Blizzard default or Minimal)
- Lock/unlock bar position
- Show/hide tooltip on item hover

---

## FAQ

### Q: Do my keybinds follow the items or the button positions?

**A: Keybinds follow button positions.** If you bind "E" to button slot 1, it will always activate whatever is in slot 1 (Health Potion category), regardless of which specific potion is shown.

This is intentional - your muscle memory stays consistent. "E" always means "use a health potion."

### Q: Why did my elixir buttons disappear during a fight?

**A: This is by design.** Elixirs, flasks, food, and drink are "prep-only" items. During combat:
- These buttons are cleared (no icon shown)
- Keybinds on these slots do nothing
- This prevents accidentally using buff food/elixirs mid-combat

The buttons return when you leave combat.

### Q: How do I see all my potions, not just the "best" one?

**A: Hover over the slot.** A flyout menu appears showing all items you have in that category. Click the one you want to use.

### Q: What does "Smart" display mode do?

**A: Smart mode hides empty buttons while keeping keybinds stable.**

- If you have no mana potions, the mana potion slot is hidden
- But slot 3 (Rejuv Potion) is still in position 3 on the bar
- Your keybind for slot 3 still works

Compare to "Dynamic" mode which removes empty slots entirely and shifts everything - this breaks keybinds.

### Q: Why does a button turn faded/grey?

**A: You ran out of that item during combat.** The macro still exists (can't change secure buttons in combat) but the button fades to show the item is depleted.

### Q: Can I reorder the slots?

**A: Not in v0.6.5.** Slot order is fixed by design to keep keybinds predictable. Custom ordering is planned for a future version.

### Q: Why English only?

**A: Item classification relies on tooltip parsing.** The addon reads tooltip text to categorize items (e.g., detecting "Battle Elixir" vs "Guardian Elixir"). This only works with English-language game clients currently.

Localization is planned for a future version.

### Q: The bar is stuck and I can't move it!

**A: The bar is locked.** Type `/db` or `/dynamicbar` to open settings, then uncheck "Lock Bar Position" to move it.

### Q: How do I open the settings?

**A: Type `/db` or `/dynamicbar` in chat.**

---

## Changelog (v0.6.5)

### v0.6.5
- Fixed: Lock/unlock bar error in config panel

### v0.6.4
- Fixed: Empty flyout buttons appearing after selling items

### v0.6.3
- Fixed: Stale flyout items after consuming/deleting items

### v0.6.2
- Fixed: Item counts not updating mid-combat
- Fixed: CurseForge app installation (directory structure)

### v0.6.1
- Fixed: Depleted items now fade during combat
- Fixed: Prep-only slots fully cleared in combat (keybinds safe)

### v0.6
- Added: Flask support
- Added: Rejuvenation Potion slot
- Added: Display modes (Smart/Static/Dynamic)
- Fixed: Flyout performance (95%+ improvement)

---

## Tips

1. **Bind your combat slots** (1-5, 11-12) to keys you can hit quickly
2. **Use Smart display mode** (default) for the best experience
3. **Don't worry about slot order** - the categories are designed for typical raid/dungeon flow
4. **Check flyouts** before fights to verify you have the consumables you need
