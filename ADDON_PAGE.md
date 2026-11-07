# DynamicBar - Addon Page Content

Use the sections below for your CurseForge addon page.

---

## Description (Main)

**DynamicBar** is a consumable action bar for TBC Classic and WoW Forever that automatically shows the right items at the right time.

### How It Works

DynamicBar creates a single action bar with one button per consumable category (13 by default; choose and order them in the Bar Builder). The bar automatically:

- **Shows your best available item** in each slot (highest-level health potion you have, best food, etc.)
- **Shows alternatives on right-click** - right-click a slot to see every item you have for that category
- **Hides prep-only items during combat** - elixirs, flasks, food, and drink buttons are cleared when combat starts (no accidental buff food clicks mid-fight)
- **Fades depleted items** - when you use your last potion, the button fades to show it's empty

### Default Slots

| Slot | Category | Combat? | Notes |
|------|----------|---------|-------|
| 1 | Healthstone | ✓ | Warlock stones |
| 2 | Health Potion | ✓ | Shows best healing potion |
| 3 | Mana Potion | ✓ | Shows best mana potion |
| 4 | Rejuv Potion | ✓ | Dual health+mana pots |
| 5 | Bandage | ✓ | First aid |
| 6 | Battle Elixir | Prep | Attack power, spell power, etc. |
| 7 | Guardian Elixir | Prep | Armor, health, resistances |
| 8 | Flask | Prep | If you have one |
| 9 | Food (Buff) | Prep | Well Fed food |
| 10 | Food (Other) | Prep | Plain food |
| 11 | Drink | Prep | Mana drinks |
| 12 | Hearthstone | ✓ | |
| 13 | Other Buffs | Prep | Oil of Olaf, scrolls |

### Flyout System

**Right-click any slot** to see a flyout with all matching items in your bags, then click the one you want. With more than six items, Previous/Next arrows page through them (out of combat).

---

## Features

### Smart Display Modes

Choose how empty slots behave:

- **Smart (Default)** - Empty buttons are hidden but keep their position. Your keybinds stay stable.
- **Static** - All slots always visible, even when empty. Keybinds stable.
- **Dynamic** - Bar auto-sizes to only show available items. **Warning:** This mode shifts button positions, which breaks keybinds.

### Combat Safety

- Prep-only slots (elixirs, flasks, food, drink) are **completely cleared** during combat
- Keybinds on cleared slots do nothing - no risk of wasting buff food mid-fight
- Items fade when depleted so you know at a glance what's empty

### Customization

- Bar Builder: drag categories onto the bar and into the order you want
- Horizontal, vertical, or grid layout, with scale and spacing
- Buttons follow ElvUI or Masque styling when either is installed
- Lock/unlock bar position
- WoW Forever: move the bar from Edit Mode alongside your other frames

---

## FAQ

### Q: Do my keybinds follow the items or the button positions?

**A: Keybinds follow button positions.** If you bind "E" to button 2, it will always activate whatever is in slot 2 (Health Potion category on the default bar), regardless of which specific potion is shown.

This is intentional - your muscle memory stays consistent. "E" always means "use a health potion."

### Q: Why did my elixir buttons disappear during a fight?

**A: This is by design.** Elixirs, flasks, food, and drink are "prep-only" items. During combat:
- These buttons are cleared (no icon shown)
- Keybinds on these slots do nothing
- This prevents accidentally using buff food/elixirs mid-combat

The buttons return when you leave combat.

### Q: How do I see all my potions, not just the "best" one?

**A: Right-click the slot.** A flyout menu appears showing all items you have in that category. Click the one you want to use.

### Q: What does "Smart" display mode do?

**A: Smart mode hides empty buttons while keeping keybinds stable.**

- If you have no mana potions, the mana potion slot is hidden
- But slot 4 (Rejuv Potion) is still in position 4 on the bar
- Your keybind for slot 4 still works

Compare to "Dynamic" mode which removes empty slots entirely and shifts everything - this breaks keybinds.

### Q: Why does a button turn faded/grey?

**A: You ran out of that item during combat.** The macro still exists (can't change secure buttons in combat) but the button fades to show the item is depleted.

### Q: Can I reorder the slots?

**A: Yes.** Type `/dbar builder` (or use Open Bar Builder in the Behavior tab). Drag categories onto your bar, drag slots to reorder them, and drag a slot off the bar to remove it. The bar has one button per slot.

### Q: Does it work on non-English clients?

**A: Mostly.** Food, drink, buff food, bandages, flasks and all listed potions are recognized in any language, using item types and the game's own spell names. Battle vs Guardian elixirs, and ranking food or potions by how much they restore, still read English tooltip text until those phrases are translated for your language. Menus, popups and messages can all be translated; you can help on the CurseForge localization page.

### Q: The bar is stuck and I can't move it!

**A: The bar is locked.** Type `/dbar config` to open settings, then uncheck "Lock Bar Position" to move it. On WoW Forever you can also open Edit Mode and drag it there.

### Q: How do I open the settings?

**A: Type `/dbar config` in chat**, or find DynamicBar in the game's AddOns options.

---

## Changelog

See CHANGELOG.md (also shown on the Changelog tab).

---

## Tips

1. **Bind your combat slots** (1-5 and Hearthstone on the default bar) to keys you can hit quickly
2. **Use Smart display mode** (default) for the best experience
3. **Don't worry about slot order** - the categories are designed for typical raid/dungeon flow
4. **Check flyouts** before fights to verify you have the consumables you need
