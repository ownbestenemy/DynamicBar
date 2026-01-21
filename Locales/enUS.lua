-- Locales/enUS.lua
-- English (US) - Base locale
local L = LibStub("AceLocale-3.0"):NewLocale("DynamicBar", "enUS", true)
if not L then return end

-- Addon info
L["DynamicBar"] = true
L["Loaded. (/dbar)"] = true
L["Loaded (disabled). (/dbar enable)"] = true

-- General Settings
L["General Settings"] = true
L["Enabled"] = true
L["Enable or disable the DynamicBar addon"] = true
L["Debug Mode"] = true
L["Enable debug logging to chat frame"] = true

-- Bar Layout
L["Bar Layout"] = true
L["Configure the size and appearance of the action bar. Changes apply out of combat."] = true
L["Button Count"] = true
L["Number of buttons to display on the bar"] = true
L["Choose how buttons are arranged"] = true
L["Horizontal (Default)"] = true
L["Vertical"] = true
L["Grid"] = true
L["Grid Rows"] = true
L["Number of rows in grid layout"] = true
L["Grid Columns"] = true
L["Number of columns in grid layout"] = true
L["Bar Scale"] = true
L["Overall scale of the bar and all buttons"] = true

-- Spacing
L["Horizontal Spacing"] = true
L["Horizontal space between buttons (pixels)"] = true
L["Vertical Spacing"] = true
L["Vertical space between buttons (pixels)"] = true
L["Spacing"] = true

-- Padding
L["Edge Padding"] = true
L["Space on edges of the bar (pixels) - use Advanced Padding for per-edge control"] = true
L["Show Advanced Padding"] = true
L["Adjust padding for each edge separately"] = true
L["Left Padding"] = true
L["Space on left edge (pixels)"] = true
L["Right Padding"] = true
L["Space on right edge (pixels)"] = true
L["Top Padding"] = true
L["Space on top edge (pixels)"] = true
L["Bottom Padding"] = true
L["Space on bottom edge (pixels)"] = true

-- Visibility
L["Prep-Only Slots During Combat"] = true
L["How to display prep-mode items when you enter combat"] = true
L["Prep-only items: Elixirs, Flasks, Food, Drink (not usable in combat)"] = true
L["Battle items always visible: Health/Mana Potions, Healthstone, Bandages"] = true
L["Fade Out (Recommended)"] = true
L["Hide Completely"] = true
L["Grey Out (Disabled)"] = true
L["Keep Visible (Always)"] = true

-- Button Display Mode
L["Empty Button Slots"] = true
L["How to handle buttons with no items assigned"] = true
L["Smart - Binding Safe (Recommended)"] = true
L["Static - Show All Slots"] = true
L["EXPERT: Dynamic (Breaks Keybinds)"] = true
L["Smart hides empty slots but keeps keybinds stable."] = true
L["Static shows all slots with placeholders."] = true
L["Dynamic collapses the bar (WARNING: keybinds shift when items change)."] = true

-- ElvUI
L["Use ElvUI Spacing"] = true
L["Automatically inherit button spacing and padding from ElvUI (horizontal mode only)"] = true

-- Lock/Unlock
L["Lock Bar Position"] = true
L["Lock the bar to prevent accidental dragging. Uncheck to drag the bar to a new position."] = true
L["Bar locked"] = true
L["Bar UNLOCKED - You can now drag the bar!"] = true
L["Bar position saved and locked!"] = true
L["DRAG ME"] = true
L["Save & Lock"] = true

-- Reset
L["Reset Layout"] = true
L["Reset all layout settings to default values"] = true

-- Position
L["Bar Position"] = true
L["Choose a preset position or customize manually. Changes apply out of combat."] = true
L["Position Preset"] = true
L["Choose a common position or select Custom for manual control"] = true
L["Bottom Center"] = true
L["Top Center"] = true
L["Left Side"] = true
L["Right Side"] = true
L["Custom"] = true
L["Show Advanced Controls"] = true
L["Display manual position adjustment controls"] = true
L["Anchor Point"] = true
L["Which corner/edge of the bar to anchor"] = true
L["Relative To"] = true
L["Which corner/edge of the screen to anchor to"] = true
L["X Offset"] = true
L["Horizontal offset in pixels (negative = left, positive = right)"] = true
L["Y Offset"] = true
L["Vertical offset in pixels (negative = down, positive = up)"] = true
L["Reset Position"] = true
L["Reset position to Bottom Center default"] = true

-- First-time setup
L["Bar unlocked! Drag it to your preferred position, then click 'Save & Lock'"] = true
L["Using default position. Use /dbar config to reposition later."] = true

-- Commands
L["Commands:"] = true
L["  /dbar enable  - enable the addon"] = true
L["  /dbar disable - disable the addon"] = true
L["  /dbar debug   - toggle debug logging"] = true
L["  /dbar config  - open general settings"] = true
L["  /dbar profiles - open profile management"] = true
L["  /dbar profileinfo - show current profile name and setup status"] = true
L["  /dbar dump    - dump bag/classifier/resolver state (debug on)"] = true
L["  /dbar pending - list pending items (debug on)"] = true
L["  /dbar debuglog - show persistent debug log (last 100 entries)"] = true
L["  /dbar clearlog - clear persistent debug log"] = true
L["  /dbar rebuild - force rebuild (out of combat)"] = true
L["Unknown command. Use /dbar help"] = true

-- Status messages
L["Enabled."] = true
L["Disabled (UI hiding comes later)."] = true
L["Debug ON"] = true
L["Debug OFF"] = true
L["Config UI not loaded."] = true
L["AceConfigDialog not loaded."] = true
L["AceConfig libs not loaded."] = true
L["AceDBOptions not loaded (Profiles UI unavailable)."] = true
L["UI modules not loaded"] = true
L["Failed to get bar configuration"] = true
L["Debug module not available."] = true

-- Profile info
L["Current profile: %s"] = true
L["Expected profile: %s"] = true
L["Setup complete: %s"] = true
L["WARNING: Profile mismatch!"] = true
L["First-time setup flag reset. Popup will show in 8 seconds..."] = true

-- Debug
L["Debug log not available."] = true
L["Debug log is empty. Enable debug mode with /dbar debug"] = true
L["=== Debug Log (%d entries) ==="] = true
L["=== End Debug Log ==="] = true
L["To share with addon author: Copy messages above or check SavedVariables/DynamicBarDB.lua"] = true
L["Debug log cleared (%d entries removed)."] = true

-- Errors
L["Error scheduling bag refresh: %s"] = true
