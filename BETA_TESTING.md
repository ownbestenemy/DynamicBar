# Beta Testing Guide - v0.6-beta

## Overview

DynamicBar v0.6-beta introduces two major features that need thorough testing before public release. This guide helps beta testers focus on critical scenarios and report issues effectively.

## What's New in v0.6-beta

1. **Flask Support** - Auto-detection and prioritization of TBC/Classic flasks
2. **Button Display Modes** - Three modes for handling empty button slots (Smart/Static/Dynamic)

---

## Feature 1: Flask Support

### ⚠️ CRITICAL: Author Cannot Test This Feature
The addon author does not have access to flasks in-game. **Flask testing is entirely dependent on beta testers.**

### What to Test

#### Test 1: Single Flask Detection
**Setup:**
1. Acquire one flask (any TBC or Classic flask)
2. Enable debug mode: `/dbar debug`
3. Check classification: `/dbar dump`

**Expected Behavior:**
- Flask shows `isFlask=true, pending=false` in dump output
- Flask button appears in Prep Mode between Guardian Elixir and Food slots
- Flask button is clickable and uses the flask when left-clicked

**Report if:**
- Flask not detected (shows `isFlask=false` or `pending=true`)
- Flask button doesn't appear
- Wrong flask icon/texture displayed
- Click does nothing or uses wrong item

#### Test 2: Multiple Flasks - Priority Resolution
**Setup:**
1. Have 2+ different flasks in bags
2. Note which flask is listed first in Categories.lua (line 25-41)
3. Verify button shows highest priority flask

**Expected Behavior:**
- Main button shows the first flask from Categories.lua that you own
- Example: If you have Flask of Fortification (22851) and Flask of Titans (13510), Fortification should show (it's listed first)

**Report if:**
- Wrong flask shown as primary
- Random flask selection instead of priority order

#### Test 3: Flask Flyout Menu
**Setup:**
1. Have 3+ different flasks in bags
2. Right-click the Flask button while out of combat

**Expected Behavior:**
- Flyout menu appears showing all flasks you own
- Flasks ordered by priority (same order as Categories.lua)
- Clicking flyout flask uses that specific flask
- Flyout disappears after clicking a flask

**Report if:**
- Flyout doesn't appear
- Flasks missing from flyout
- Clicking flyout flask does nothing
- Wrong flask used when clicking flyout item

#### Test 4: Battle/Prep Mode Switching
**Setup:**
1. Have flask in bags
2. Start out of combat (Prep Mode)
3. Enter combat
4. Exit combat

**Expected Behavior:**
- **Prep Mode (Out of Combat):** Flask button visible between Guardian Elixir and Food
- **Battle Mode (In Combat):** Flask button fades/hides/greys (depends on "Unavailable Items" setting)
- **Return to Prep Mode:** Flask button returns to full visibility

**Report if:**
- Flask shows during combat (wrong - it should hide/fade)
- Flask doesn't reappear after combat
- Mode transition causes errors or visual glitches

#### Test 5: Flask Categories to Test
**TBC Flasks (High Priority):**
- Flask of Blinding Light (22861)
- Flask of Pure Death (22866)
- Flask of Relentless Assault (22854)
- Flask of Mighty Restoration (22853)
- Flask of Fortification (22851)
- Flask of Chromatic Wonder (22849)

**Classic Flasks (Lower Priority):**
- Flask of the Titans (13510)
- Flask of Distilled Wisdom (13511)
- Flask of Supreme Power (13512)
- Flask of Chromatic Resistance (13513)

**Mixed Testing:**
- Test with both TBC + Classic flasks - verify TBC flasks take priority

---

## Feature 2: Button Display Modes

### What to Test

#### Test 6: Smart Mode (Default)
**Setup:**
1. `/dbar config` → Bar Layout → "Empty Button Slots" → **Smart - Hide Empty**
2. Remove 2-3 consumable types from bags (e.g., remove all bandages and elixirs)
3. Set button count to 11 or 12

**Expected Behavior:**
- Buttons with items: Visible and clickable
- Buttons without items: **Invisible** (but position reserved - bar width unchanged)
- Bar width stays constant even when items removed
- Keybinds remain stable (button 5 is always button 5)

**Report if:**
- Empty buttons still visible
- Bar width changes when items added/removed
- Buttons shift positions (this should NOT happen in Smart mode)

#### Test 7: Static Mode
**Setup:**
1. `/dbar config` → Bar Layout → "Empty Button Slots" → **Static - Show All Slots**
2. Remove 2-3 consumable types from bags
3. Set button count to 11 or 12

**Expected Behavior:**
- **All** configured buttons visible (including empty ones)
- Empty buttons show background/border but no item icon
- Empty buttons not clickable (EnableMouse = false)
- If buttons = 12, button 12 shows as empty placeholder (no category assigned)

**Report if:**
- Empty buttons disappear (they should stay visible)
- Empty buttons clickable (they should be disabled)
- Visual inconsistencies with empty buttons

#### Test 8: Dynamic Mode (WARNING: Breaks Keybinds)
**Setup:**
1. `/dbar config` → Bar Layout → "Empty Button Slots" → **Dynamic - Auto-Collapse**
2. Have 8 different consumable types in bags
3. Remove one item type from the middle (e.g., use all mana potions)

**Expected Behavior:**
- Bar **shrinks** when item removed
- Buttons **shift left** to fill gap (this is intentional, hence the warning)
- Bar **grows** when new item type added
- Button positions are **not stable** (button 5 might become button 4)

**Report if:**
- Bar doesn't shrink when items removed
- Buttons don't shift positions (they should in this mode)
- Bar width incorrect (should match actual button count, not configured count)

#### Test 9: Keybind Stability
**Setup:**
1. Smart Mode: Keybind a key to button 7 (e.g., bind "7" to DynamicBarMainButton7)
2. Remove items so button 6 becomes empty
3. Press the keybind

**Expected Behavior:**
- **Smart Mode:** Keybind still triggers button 7 (even though button 6 is invisible)
- **Static Mode:** Same - keybinds stable
- **Dynamic Mode:** Keybind might trigger wrong item (button positions shifted)

**Report if:**
- Smart/Static mode keybinds break when items removed
- Dynamic mode keybinds remain stable (they should break, that's the warning)

#### Test 10: Button Count Edge Cases
**Setup:**
1. Set buttons = 12 (11 categories exist)
2. Test with Static mode
3. Test with Smart mode

**Expected Behavior:**
- **Static Mode:** Button 12 visible as empty placeholder (no category assigned)
- **Smart Mode:** Button 12 hidden (no category to fill it)
- Buttons 1-11: Work normally with assigned categories

**Report if:**
- Button 12 causes errors
- Button 12 shows in Smart mode (should be hidden)
- Button 12 missing in Static mode (should show as placeholder)

---

## Cross-Feature Testing

#### Test 11: Flask + Button Display Modes
**Setup:**
1. Have flask in bags
2. Try all 3 button display modes
3. Remove flask from bags

**Expected Behavior:**
- Smart Mode: Flask button disappears when flask removed, space reserved
- Static Mode: Flask button stays visible but empty when flask removed
- Dynamic Mode: Bar shrinks when flask removed, other buttons shift left

**Report if:**
- Mode switching breaks flask display
- Flask button position changes unexpectedly
- Visual glitches during mode transitions

---

## Debug Tools

### Enable Debug Mode
```
/dbar debug
```
Enables detailed logging to chat frame and SavedVariables.

### View Item Classification
```
/dbar dump
```
Shows all items in bags with classification flags (isFlask, isFood, etc.).

### View Pending Items
```
/dbar pending
```
Lists items still waiting for tooltip text (should be empty after a few seconds).

### View Persistent Debug Log
```
/dbar debuglog
```
Shows last 100 debug entries (survives /reload and logout).

### Clear Debug Log
```
/dbar clearlog
```
Clears persistent debug log.

---

## How to Report Issues

### Required Information
1. **WoW Version:** TBC Classic 2.5.x
2. **DynamicBar Version:** v0.6-beta
3. **Other Addons Installed:** List UI/action bar addons (ElvUI, Masque, Dominos, Bartender4, etc.)
4. **Steps to Reproduce:** Exact steps to trigger the issue
5. **Expected Behavior:** What should happen
6. **Actual Behavior:** What actually happened
7. **Debug Log:** Output from `/dbar debuglog` (if applicable)

### Example Bug Report (Good)
```
**Issue:** Flask not detected

**Setup:**
- WoW: TBC Classic 2.5.4
- DynamicBar: v0.6-beta
- Other Addons: ElvUI 3.54, Questie 6.3.2
- Flask: Flask of Relentless Assault (item 22854)

**Steps:**
1. Acquired Flask of Relentless Assault
2. Enabled debug mode: /dbar debug
3. Ran /dbar dump

**Expected:** Flask shows isFlask=true, pending=false
**Actual:** Flask shows isFlask=false, pending=true

**Debug Log:**
[Paste /dbar debuglog output here]

**Screenshot:** [Optional but helpful]
```

### Example Bug Report (Bad - Missing Info)
```
"Flask doesn't work"
```
❌ No version info, no steps to reproduce, no debug output

---

## Known Limitations (Not Bugs)

1. **Flask Detection Delay:** First bag scan may show `pending=true` for 1-2 seconds while tooltip loads. This resolves automatically.

2. **Dynamic Mode Keybind Warning:** Dynamic mode intentionally breaks keybinds when items are added/removed. This is documented and expected.

3. **Combat Lockdown:** No layout changes possible during combat. This is a WoW API restriction, not a bug.

4. **ElvUI First-Time Popup Conflict:** If you see an ElvUI protected frame error on first login, it's a timing issue between DynamicBar and ElvUI setup wizards. Not related to Flask or Button Modes.

---

## Success Criteria

Before v0.6-beta can graduate to stable release, we need confirmation that:

### Flask Support
- ✅ All 11 flask types detected correctly
- ✅ Priority resolution works (first in list wins)
- ✅ Flyout menus work with multiple flasks
- ✅ Battle/Prep mode transitions work correctly
- ✅ No conflicts with elixir categories

### Button Display Modes
- ✅ Smart Mode hides empty buttons, reserves space, stable keybinds
- ✅ Static Mode shows all slots, including empty ones
- ✅ Dynamic Mode collapses/expands correctly (keybind warning acknowledged)
- ✅ Mode switching works without errors
- ✅ Button count > 11 handled gracefully

### Cross-Addon Compatibility
- ✅ Works with ElvUI (spacing, skinning)
- ✅ Works with Masque (button skinning)
- ✅ Works with Dominos/Bartender4 (no conflicts)
- ✅ Keybinds work correctly in all modes (except Dynamic, which is expected)

---

## Thank You!

Your testing is critical to making DynamicBar a reliable, polished addon. Every bug report, edge case discovery, and feature validation helps ensure a better experience for all users.

**Questions or feedback?** Contact the addon author or post in your guild's Discord/forums.

Happy testing! 🎮
