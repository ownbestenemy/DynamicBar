-- Run from the repository root with Lua 5.1: lua5.1 tests/run.lua
local mock = dofile('tests/mock_wow.lua')
assert(loadfile('Core.lua'))('DynamicBar')
local DB = DynamicBar
DB.DPrint = function() end
DB.db = {profile = {enabled = true, _setupComplete = true, bar = {
  buttons = 13, layoutMode = 'HORIZONTAL', gridRows = 2, gridCols = 5,
  locked = true, visibilityMode = 'FADE', buttonDisplayMode = 'SMART',
}}}
for _, file in ipairs({'Data/Categories.lua','Data/BagCache.lua','Data/Resolver.lua','UI/Buttons.lua','UI/Actions.lua','UI/Flyouts.lua','UI/UI.lua','UI/ItemsBar.lua','UI/Builder.lua','Bindings.lua','Config.lua'}) do
  dofile(file)
end
DB.Data.Classifier = {cache = {}}
function DB.Data.Classifier:InspectItem(id) return self.cache[id] end
local UI, cfg, cache = DB.UI, DB.db.profile.bar, DB.Data.BagCache
local checks = 0
local function equal(actual, expected, label)
  checks = checks + 1
  assert(actual == expected, label .. ': expected ' .. tostring(expected) .. ', got ' .. tostring(actual))
end
local function rebuild(items)
  if items then mock.inventory = items end
  cache:Rebuild()
  DB:Rebuild('test')
end
local function click(btn, button)
  -- SecureActionButton's effective action falls back to the generic attributes.
  local action = btn.attrs[button == 'LeftButton' and 'type1' or 'type2'] or btn.attrs.type
  local consumed = action == 'macro'
  if btn.scripts.OnClick then btn.scripts.OnClick(btn, button, false) end
  return consumed
end
local function enterCombat()
  mock.setCombat(true)
  DB:OnPlayerRegenDisabled()
end
local function leaveCombat()
  mock.setCombat(false)
  DB:OnPlayerRegenEnabled()
end

mock.inventory = {[22829]=1, [118]=2, [22851]=1, [6948]=1}
rebuild()
local potion = UI.buttons[2]
equal(click(potion, 'RightButton'), false, 'right-click cannot consume')
equal(potion._dynFlyout:IsShown(), true, 'right-click opens alternatives')
equal(click(potion, 'LeftButton'), true, 'left-click consumes')
click(potion._dynFlyout._buttons[2], 'LeftButton')
equal(potion._dynFlyout:IsShown(), false, 'selection closes flyout')

-- All display/visibility combinations must preserve assignments and positions.
for _, display in ipairs({'SMART','STATIC','DYNAMIC'}) do
  cfg.buttonDisplayMode = display
  for _, mode in ipairs({'FADE','HIDE','GREY','ALWAYS'}) do
    cfg.visibilityMode = mode
    rebuild()
    local prep, battle
    for _, btn in ipairs(UI.buttons) do
      if btn._dynItemID == 22851 then prep = btn end
      if btn._dynItemID == 22829 then battle = btn end
    end
    local point, macro = prep.point, prep.attrs.macrotext1
    click(battle, 'RightButton')
    enterCombat()
    equal(prep.point, point, display .. '/' .. mode .. ' frozen position')
    equal(prep.attrs.macrotext1, macro, 'frozen item assignment')
    equal(click(prep, 'LeftButton'), false, 'prep key/mouse action disabled')
    equal(click(battle, 'LeftButton'), true, 'battle action remains usable')
    equal(prep:IsShown(), mode ~= 'HIDE', 'combat visibility')
    equal(prep:GetAlpha(), mode == 'FADE' and 0.3 or mode == 'GREY' and 0.4 or 1, 'combat alpha')
    equal(battle._dynFlyout:IsShown(), false, 'secure combat flyout hide')
    leaveCombat()
    equal(prep.attrs.type1, 'macro', 'prep action restored')
    equal(prep:GetAlpha(), 1, 'prep alpha restored')
  end
end

-- A final combat bag update only refreshes displayed items; exit must rescan.
cfg.buttonDisplayMode = 'SMART'; cfg.visibilityMode = 'FADE'
rebuild({[22829]=1,[118]=2})
local scans = mock.scans
enterCombat()
mock.inventory = {[13446]=1}
DB:OnBagUpdate()
equal(mock.scans, scans, 'no full combat bag scan')
leaveCombat()
equal(UI.buttons[2]._dynItemID, 13446, 'new item appears immediately after combat')
equal(cache:GetCount(118), 0, 'depleted alternative removed on combat exit')

-- Incomplete grids, including saved 2x5 defaults, grow to contain every slot.
cfg.buttonDisplayMode = 'STATIC'; cfg.layoutMode = 'GRID'
for _, cols in ipairs({1,5,12}) do
  cfg.gridRows = 1; cfg.gridCols = cols
  rebuild()
  equal(cfg.gridRows * cfg.gridCols >= UI:GetButtonCount(), true, 'grid has enough capacity')
  for _, btn in ipairs(UI.buttons) do equal(btn.point[1], 'BOTTOMLEFT', 'button positioned inside grid') end
end

-- Shrinking Dynamic mode clears main and flyout actions on every discarded slot.
cfg.layoutMode = 'HORIZONTAL'; cfg.buttonDisplayMode = 'DYNAMIC'; cfg.slots = nil
rebuild({[22829]=1,[118]=2,[22832]=1,[2455]=2,[6948]=1})
local discarded = UI.buttons[2]
click(discarded, 'RightButton')
cfg.slots = {'HEALTHSTONE'}
rebuild()
equal(discarded:IsShown(), false, 'discarded button hidden')
equal(discarded.attrs.type1, nil, 'discarded binding cleared')
equal(discarded._dynItemID, nil, 'discarded item ID cleared')
equal(discarded._dynCooldown:IsShown(), false, 'discarded cooldown cleared')
equal(discarded._dynFlyout:IsShown(), false, 'discarded flyout hidden')
equal(discarded._dynFlyout._count, 0, 'discarded flyout cleared')

cfg.slots = nil; cfg.buttonDisplayMode = 'SMART'
rebuild({[22829]=1,[118]=2})
click(UI.buttons[2], 'RightButton')
rebuild({})
equal(UI.buttons[2]._dynFlyout:IsShown(), false, 'empty Smart slot hides flyout')
equal(UI.buttons[2]._dynFlyout._count, 0, 'empty Smart slot clears flyout')

-- Both entry points disable actions; protected mutations defer until combat ends.
DB:InitConfig()
for _, inCombat in ipairs({false,true}) do
  for _, entry in ipairs({'slash','options'}) do
    DB:SetEnabled(true); rebuild({[22829]=1,[118]=2})
    click(UI.buttons[2], 'RightButton')
    if inCombat then enterCombat() end
    if entry == 'slash' then DB:HandleSlash('disable') else DB.options.args.general.args.enabled.set(nil, false) end
    if inCombat then
      equal(DB._needsRebuild, true, 'disable queued during combat')
      leaveCombat()
    end
    equal(UI.bar:IsShown(), false, entry .. ' disables bar')
    equal(click(UI.buttons[2], 'LeftButton'), false, entry .. ' disables binding')
    equal(UI.buttons[2]._dynFlyout:IsShown(), false, entry .. ' disables flyout')
  end
end
DB:SetEnabled(true)

-- Guided positioning survives bag rebuilds and only completes on Save & Lock.
DB.db.profile._setupComplete = false
cfg.locked = true
rebuild({[22829]=1})
DB:ShowFirstTimeSetup(); mock.runTimers(8)
StaticPopupDialogs.DYNAMICBAR_FIRST_TIME_SETUP.OnAccept()
equal(DB.db.profile._setupComplete, false, 'position now does not prematurely finish setup')
rebuild()
equal(UI.bar._lockOverlay._lockBtn:IsShown(), true, 'Save & Lock survives rebuild')
enterCombat()
equal(UI.bar._lockOverlay:IsShown(), false, 'position overlay hidden during combat')
cfg.locked = true; UI:UpdateLockState()
leaveCombat()
equal(UI.bar._lockOverlay:IsShown(), false, 'combat lock change applied safely')
cfg.locked = false; UI:UpdateLockState()
UI.bar._lockOverlay._lockBtn.scripts.OnClick()
equal(cfg.locked, true, 'Save & Lock locks bar')
equal(DB.db.profile._setupComplete, true, 'Save & Lock completes setup')
cfg.locked = false; UI:UpdateLockState(); rebuild()
equal(UI.bar._lockOverlay._lockBtn:IsShown(), true, 'later unlocks retain Save & Lock')
cfg.locked = true; UI:UpdateLockState()

-- Edit Mode (Forever): the bar shows a drag handle while it is open and locks again after.
local editCallbacks = {}
EventRegistry = {RegisterCallback = function(_, event, fn) editCallbacks[event] = fn end}
EditModeManagerFrame = CreateFrame('Frame')
UI:HookEditMode()
editCallbacks['EditMode.Enter']()
local overlay = UI.bar._lockOverlay
equal(overlay:IsShown(), true, 'Edit Mode shows the drag handle')
equal(overlay._lockBtn:IsShown(), false, 'Edit Mode handle has no Save & Lock button')
rebuild()
equal(overlay:IsShown(), true, 'drag handle survives a bag rebuild in Edit Mode')
editCallbacks['EditMode.Exit']()
equal(overlay:IsShown(), false, 'leaving Edit Mode locks the bar')
equal(cfg.locked, true, 'Edit Mode never changes the saved lock setting')
cfg.locked = false; UI:UpdateLockState(true)
editCallbacks['EditMode.Enter'](); editCallbacks['EditMode.Exit']()
equal(overlay:IsShown(), true, 'a bar the player unlocked stays unlocked after Edit Mode')
equal(overlay._lockBtn:IsShown(), true, 'Save & Lock returns after Edit Mode')
cfg.locked = true; UI:UpdateLockState(true)
EventRegistry, EditModeManagerFrame = nil, nil

cache.items = {900001,22850}; cache.counts = {[900001]=1,[22850]=1}
DB.Data.Classifier.cache = {
  [900001] = {itemID=900001,health=5000,mana=0,isRejuvenationPotion=false},
  [22850] = {itemID=22850,health=1760,mana=1760,isRejuvenationPotion=true},
}
local best, list = DB.Data.Resolver:ResolveRejuvenationPotion()
equal(best, 22850, 'rejuvenation slot selects true rejuvenation potion')
equal(#list, 1, 'unrelated restorative excluded')
DB.Data.Classifier.cache[22850].pending = true
equal(DB.Data.Resolver:ResolveRejuvenationPotion(), nil, 'pending classification excluded')

-- Slot list: one button per slot, migrated once from 1.x settings.
local Cats = DB.Data.Categories
local function keys(list) return table.concat(list, ',') end
equal(#Cats:GetSlots({}), #Cats.DEFAULT_ORDER, 'new profile gets every category')
equal(keys(Cats:GetSlots({buttons = 3})), 'HEALTHSTONE,HEALTH_POT,MANA_POT', '1.x button count keeps top slots')
equal(keys(Cats:GetSlots({buttons = 2, slotOrder = {'HEARTH','FLASK','DRINK'}})), 'HEARTH,FLASK', '1.x custom order migrated')
equal(Cats:GetSlots({slotOrder = {'HEARTH'}})[13], 'OTHER_BUFF', '1.x order gains slots it predates')
equal(keys(Cats:GetSlots({slotOrder = {'GONE'}, buttons = 1})), 'HEALTHSTONE', 'invalid 1.x order falls back to default')
local migrated = {buttons = 4, slots = {'DRINK','BOGUS','DRINK','FLASK'}}
equal(keys(Cats:GetSlots(migrated)), 'DRINK,FLASK', 'unknown and duplicate keys dropped')
equal(keys(migrated.slots), 'DRINK,FLASK', 'cleaned list saved')
equal(#Cats:GetSlots({slots = {}}), #Cats.DEFAULT_ORDER, 'empty bar resets to default')
cfg.buttonDisplayMode = 'STATIC'; cfg.slots = {'FLASK','HEARTH','DRINK'}
rebuild({[22851]=1,[6948]=1})
equal(UI:GetButtonCount(), 3, 'button count follows slot list')
equal(UI.buttons[1]._dynItemID, 22851, 'first slot is the flask')
equal(UI.buttons[2]._dynItemID, 6948, 'second slot is the hearthstone')
equal(UI.buttons[4]:IsShown(), false, 'buttons past the slot list hidden')
cfg.slots = nil; cfg.buttonDisplayMode = 'SMART'
rebuild()

-- About tab shows the installed version and client
GetAddOnMetadata = function(_, field) return ({Version = '2.1-experimental', Author = 'Mark'})[field] end
GetBuildInfo = function() return '2.5.5', '12345', '', 20505 end
DB:InitConfig()
local about = DB.options.args.about.args
equal(DB.options.name, 'DynamicBar 2.1-experimental', 'version in window title')
equal(about.info.name():find('2.1-experimental', 1, true) ~= nil, true, 'About shows the version')
equal(about.info.name():find('TBC Classic', 1, true) ~= nil, true, 'About names the client')
equal(about.experimental.hidden(), false, 'experimental note shown on test builds')
WOW_PROJECT_ID, WOW_PROJECT_MAINLINE = 1, 1
equal(about.info.name():find('WoW Forever', 1, true) ~= nil, true, 'Mainline client is WoW Forever')
WOW_PROJECT_ID, WOW_PROJECT_MAINLINE, GetAddOnMetadata, GetBuildInfo = nil, nil, nil, nil
DB:InitConfig()

-- Basic mode: default slots and look, Advanced settings kept for later.
equal(DB:IsBasicMode(), false, 'profile without a mode runs Advanced')
local profile = DB.db.profile
cfg.slots = {'FLASK','HEARTH'}; cfg.layoutMode = 'VERTICAL'; cfg.buttonDisplayMode = 'STATIC'
DB.options.args.general.args.mode.set(nil, 'BASIC')
rebuild()
equal(profile.mode, 'BASIC', 'mode saved from options')
equal(UI:GetButtonCount(), #Cats.DEFAULT_ORDER, 'Basic shows every category')
equal(UI:GetBarConfig().layoutMode, 'HORIZONTAL', 'Basic uses the default layout')
equal(DB.options.args.appearance.hidden(), true, 'Basic hides the Appearance tab')
equal(DB.options.args.general.args.basicScale.hidden(), false, 'Basic shows scale on General')
UI:GetBarConfig().x = 42
UI:GetBarConfig().slots = {'DRINK'}
equal(cfg.x, 42, 'Basic position saved to the profile')
equal(keys(cfg.slots), 'FLASK,HEARTH', 'Basic leaves Advanced slots alone')
local builderOpen = false
local realToggle = UI.Builder.Toggle
UI.Builder.Toggle = function() builderOpen = true end
DB:HandleSlash('builder')
equal(builderOpen, false, 'Bar Builder not opened in Basic')
mock.setCombat(true)
DB:SetMode('ADVANCED')
equal(profile.mode, 'BASIC', 'mode not changed in combat')
mock.setCombat(false)
DB:SetMode('ADVANCED')
rebuild()
DB:HandleSlash('builder')
equal(builderOpen, true, 'Bar Builder opens in Advanced')
UI.Builder.Toggle = realToggle
equal(keys(Cats:GetSlots(UI:GetBarConfig())), 'FLASK,HEARTH', 'Advanced slots restored')
equal(UI:GetBarConfig().layoutMode, 'VERTICAL', 'Advanced layout restored')
local fresh = {}
DB.db.profile = fresh; DB:ResolveMode()
equal(fresh.mode, 'BASIC', 'new profile starts in Basic')
fresh = {_setupComplete = true}
DB.db.profile = fresh; DB:ResolveMode()
equal(fresh.mode, 'ADVANCED', 'existing profile keeps Advanced')
DB.db.profile = profile
cfg.slots = nil; cfg.layoutMode = 'HORIZONTAL'; cfg.buttonDisplayMode = 'SMART'; cfg.x = 0
rebuild()

-- Items bar: usable items no category takes, quest items first.
local ItemsBar = UI.ItemsBar
local itemDefs = {
  [5001] = {class = 15, sub = 0, spell = 'Drums'},       -- usable misc item
  [5002] = {class = 12, sub = 0, spell = 'Use Totem'},   -- quest item
  [5003] = {class = 4, sub = 0, spell = 'Trinket', equip = true},
  [5004] = {class = 15, sub = 5, spell = 'Summon Mount'},
  [5005] = {class = 15, sub = 0},                        -- no use effect
  [22829] = {class = 0, sub = 1, spell = 'Healing Potion'}, -- main bar potion
}
local savedInstant = GetItemInfoInstant
GetItemInfoInstant = function(id)
  local d = itemDefs[id]
  if d then return id, '', '', '', 123, d.class, d.sub end
  return savedInstant(id)
end
GetItemSpell = function(id) local d = itemDefs[id]; return d and d.spell end
IsEquippableItem = function(id) local d = itemDefs[id]; return d and d.equip or false end
IsShiftKeyDown = function() return true end
DB.db.profile.itemsBar = {enabled = false, point = 'CENTER', relPoint = 'CENTER', x = 0, y = -230,
  scale = 1.0, layoutMode = 'HORIZONTAL', maxButtons = 12}
local itemBag = {[5001]=1,[5002]=1,[5003]=1,[5004]=1,[5005]=1,[22829]=2}
rebuild(itemBag)
equal(ItemsBar.bar == nil or not ItemsBar.bar:IsShown(), true, 'items bar off by default')
DB.options.args.general.args.itemsEnabled.set(nil, true)
rebuild()
equal(ItemsBar.bar:IsShown(), true, 'items bar shown when enabled')
equal(ItemsBar.buttons[1]._dynItemID, 5002, 'quest item first')
equal(ItemsBar.buttons[2]._dynItemID, 5001, 'other usable item next')
equal(ItemsBar.buttons[3] == nil or not ItemsBar.buttons[3]:IsShown(), true, 'gear, mounts, plain items and main bar potions left out')
equal(ItemsBar.buttons[1].attrs.macrotext1, '/use item:5002', 'items bar button uses the item')
equal(ItemsBar.bar.w > ItemsBar.bar.h, true, 'items bar horizontal by default')
enterCombat()
rebuild({[5001]=1})
equal(ItemsBar.buttons[1]._dynItemID, 5002, 'items bar frozen in combat')
leaveCombat()
rebuild(itemBag)
ItemsBar.buttons[2].scripts.OnClick(ItemsBar.buttons[2], 'RightButton', false)
rebuild()
equal(ItemsBar.buttons[1]._dynItemID, 5002, 'hidden item removed, others kept')
equal(ItemsBar.buttons[2]:IsShown(), false, 'Shift+Right-click hides an item')
ItemsBar:ResetHidden()
rebuild()
equal(ItemsBar.buttons[2]._dynItemID, 5001, 'reset brings hidden items back')
DB.db.profile.itemsBar.maxButtons = 1
rebuild()
equal(ItemsBar.buttons[2]:IsShown(), false, 'maximum button count respected')
DB.db.profile.itemsBar.maxButtons = 12
DB.db.profile.itemsBar.layoutMode = 'VERTICAL'
rebuild()
equal(ItemsBar.bar.h > ItemsBar.bar.w, true, 'vertical items bar')
DB:SetMode('BASIC')
rebuild()
equal(ItemsBar.bar.w > ItemsBar.bar.h, true, 'Basic uses a horizontal items bar')
cfg.scale = 1.5
equal(ItemsBar:GetConfig().scale, 1.5, 'Basic items bar follows the main scale')
cfg.scale = 1.0
DB:SetMode('ADVANCED')
DB.db.profile.itemsBar.layoutMode = 'HORIZONTAL'
rebuild({[22829]=1})
equal(ItemsBar.bar:IsShown(), false, 'empty items bar hidden')
cfg.locked = false
UI:UpdateLockState(true)
equal(ItemsBar.bar:IsShown(), true, 'empty items bar shown while unlocked for placing')
equal(ItemsBar.bar._overlay:IsShown(), true, 'items bar drag handle shown while unlocked')
cfg.locked = true
UI:UpdateLockState(true)
equal(ItemsBar.bar._overlay:IsShown(), false, 'items bar handle hidden when locked')
rebuild({[5001]=3})
DB.Data.BagCache.counts[5001] = 1
UI:UpdateButtonsInCombat()
local ids = table.concat(UI:GetButtonItemIDs(), ',')
equal(ids:find('5001', 1, true) ~= nil, true, 'combat count refresh covers the items bar')
DB:SetEnabled(false)
rebuild()
equal(ItemsBar.bar:IsShown(), false, 'items bar hidden when the addon is disabled')
DB:SetEnabled(true)
DB.db.profile.itemsBar.enabled = false
GetItemInfoInstant, GetItemSpell, IsEquippableItem, IsShiftKeyDown = savedInstant, nil, nil, nil
rebuild({})
equal(_G['BINDING_NAME_CLICK DynamicBarItemsButton12:LeftButton'], 'Item 12', 'items bar bindings labelled')

-- Bar Builder: placing, reordering and removing categories.
local Builder = UI.Builder
cfg.slots = {'HEALTHSTONE','HEALTH_POT','FLASK'}
Builder:Place('HEARTH')
equal(keys(cfg.slots), 'HEALTHSTONE,HEALTH_POT,FLASK,HEARTH', 'click adds at the end')
Builder:Place('DRINK', 2)
equal(keys(cfg.slots), 'HEALTHSTONE,DRINK,HEALTH_POT,FLASK,HEARTH', 'drop inserts into the gap')
Builder:Place('HEALTHSTONE', 4)
equal(keys(cfg.slots), 'DRINK,HEALTH_POT,HEALTHSTONE,FLASK,HEARTH', 'dragging down lands before the target gap')
Builder:Place('HEARTH', 1)
equal(keys(cfg.slots), 'HEARTH,DRINK,HEALTH_POT,HEALTHSTONE,FLASK', 'dragging up lands in the target gap')
Builder:Move('DRINK', 1)
equal(keys(cfg.slots), 'HEARTH,HEALTH_POT,DRINK,HEALTHSTONE,FLASK', 'down arrow swaps with the next slot')
Builder:Move('HEARTH', -1)
equal(keys(cfg.slots), 'HEARTH,HEALTH_POT,DRINK,HEALTHSTONE,FLASK', 'first slot cannot move up')
equal(Builder:Remove('DRINK'), true, 'slot removed')
equal(keys(Builder:GetAvailable()):find('DRINK') ~= nil, true, 'removed slot is available again')
cfg.slots = {'FLASK'}
equal(Builder:Remove('FLASK'), false, 'last slot cannot be removed')
equal(keys(cfg.slots), 'FLASK', 'bar keeps its last slot')
Builder:Reset()
equal(#cfg.slots, #Cats.DEFAULT_ORDER, 'reset restores every category')
equal(#Builder:GetAvailable(), 0, 'nothing left to add after reset')

enterCombat()
Builder:Open()
equal(Builder.frame, nil, 'builder refuses to open in combat')
leaveCombat()
Builder:Open()
local win = Builder.frame
equal(win:IsShown(), true, 'builder opens out of combat')
equal(#win.barPanel.tiles, #Cats.DEFAULT_ORDER, 'one bar tile per slot')
equal(win.availPanel.empty:IsShown(), true, 'empty message when every category is on the bar')

-- Drag the first slot off the bar, then back to the top.
local top, cursorY, overBar = 500, 0, false
function win.barPanel:GetTop() return top end
function win.barPanel:IsMouseOver() return overBar end
function GetCursorPosition() return 0, cursorY end
win.barPanel.tiles[1].scripts.OnDragStart(win.barPanel.tiles[1])
equal(win.ghost:IsShown(), true, 'ghost follows the drag')
win.scripts.OnUpdate()
win.barPanel.tiles[1].scripts.OnDragStop()
equal(Builder:IndexOf('HEALTHSTONE'), nil, 'dragging off the bar removes the slot')
equal(win.ghost:IsShown(), false, 'ghost hidden after the drop')
equal(#win.availPanel.tiles >= 1 and win.availPanel.tiles[1].key, 'HEALTHSTONE', 'removed slot listed as available')
overBar, cursorY = true, top - 6 - 4  -- top half of the first row
win.availPanel.tiles[1].scripts.OnDragStart(win.availPanel.tiles[1])
win.scripts.OnUpdate()
equal(win.dropLine:IsShown(), true, 'drop line shows the gap')
win.availPanel.tiles[1].scripts.OnDragStop()
equal(cfg.slots[1], 'HEALTHSTONE', 'dropping on the first row inserts at the top')
win.barPanel.tiles[2].scripts.OnClick(win.barPanel.tiles[2], 'RightButton')
equal(Builder:IndexOf('HEALTH_POT'), nil, 'right-click removes a bar slot')
win.availPanel.tiles[1].scripts.OnClick(win.availPanel.tiles[1], 'LeftButton')
equal(cfg.slots[#cfg.slots], 'HEALTH_POT', 'clicking a category appends it')
-- Bag changes while the builder is open update its tiles.
local function hearthTile()
  for _, tile in ipairs(win.barPanel.tiles) do
    if tile.key == 'HEARTH' and tile:IsShown() then return tile end
  end
end
rebuild({})
equal(hearthTile().note:GetText(), 'None in bags', 'missing item noted')
rebuild({[6948]=1})
equal(hearthTile().note:GetText(), '', 'note cleared once the item is in bags')

-- Switching profiles while the builder is open shows the new profile's bar.
local oldProfile = DB.db.profile
DB.db.profile = {enabled = true, _setupComplete = true, bar = {slots = {'DRINK'}, layoutMode = 'HORIZONTAL',
  locked = true, visibilityMode = 'FADE', buttonDisplayMode = 'SMART'}}
DB.ApplyProfileCompat = DB.ApplyProfileCompat or function() end
DB:OnProfileEvent()
equal(win.barPanel.tiles[1].key, 'DRINK', 'builder refreshed on profile change')
equal(win.barPanel.tiles[2]:IsShown(), false, 'old profile tiles hidden')
DB.db.profile = oldProfile
cfg = DB.db.profile.bar
DB:OnProfileEvent()
enterCombat()
win.scripts.OnEvent(win, 'PLAYER_REGEN_DISABLED')
equal(win:IsShown(), false, 'builder closes when combat starts')
leaveCombat()
cfg.slots = nil
rebuild()

local bindingFile = assert(io.open('Bindings.xml'))
local bindings = bindingFile:read('*a'); bindingFile:close()
local count = 0
for index in bindings:gmatch('name="CLICK DynamicBarMainButton(%d+):LeftButton"') do
  count = count + 1
  equal(_G['BINDING_NAME_CLICK DynamicBarMainButton' .. index .. ':LeftButton'], 'Button ' .. index, 'binding label')
  equal(UI.buttons[tonumber(index)] ~= nil, true, 'binding target exists')
end
equal(count, #UI.DEFAULT_SLOT_ORDER, 'one click binding per slot')
equal(BINDING_HEADER_DYNAMICBAR, 'DynamicBar', 'binding section registered')
-- Real classifier: language-independent signals on a German client, and
-- WoW Forever's modern (unlisted) potions on an English one.
local items = {}
local function item(id, class, sub, level, spell, ...)
  items[id] = {class = class, sub = sub, level = level, spell = spell, lines = {...}}
end
local stubClassifier = DB.Data.Classifier
local saved = {GetItemInfoInstant = GetItemInfoInstant, GetItemInfo = GetItemInfo}
GetItemInfoInstant = function(id)
  local it = items[id] or {}
  return id, '', '', '', 123, it.class, it.sub
end
GetItemInfo = function(id) return 'Item ' .. id, 'item:' .. id, 1, (items[id] or {}).level or 1 end
GetItemSpell = function(id) local it = items[id]; if it and it.spell then return it.spell, 1 end end
C_TooltipInfo = {GetItemByID = function(id)
  local lines = {}
  for i, text in ipairs((items[id] or {}).lines or {}) do lines[i] = {leftText = text} end
  return {lines = lines}
end}
local spellNames
C_Spell = {GetSpellName = function(id) return spellNames[id] end}
ITEM_SPELL_TRIGGER_ONUSE, ITEM_BIND_QUEST = 'Use:', 'Quest Item'
local function loadClassifier(locale, names)
  GetLocale = function() return locale end
  spellNames = names
  DB.Data.Classifier = nil
  dofile('Data/Classifier.lua')
  return DB.Data.Classifier
end

ITEM_SPELL_TRIGGER_ONUSE = 'Benutzen:'
local de = loadClassifier('deDE', {[433] = 'Essen', [430] = 'Trinken', [19705] = 'Satt'})
item(27854, 0, 5, 65, 'Essen', 'Geräuchertes Talbukwildbret', 'Benutzen: Stellt im Verlauf von 30 Sek. 4320 Gesundheit wieder her.')
item(27860, 0, 5, 65, 'Trinken', 'Gereinigtes draenisches Wasser', 'Benutzen: Stellt im Verlauf von 30 Sek. 7200 Mana wieder her.')
item(27658, 0, 5, 65, 'Essen', 'Gebratener Grollhufbraten', 'Benutzen: Ihr seid danach satt und erhaltet 20 Ausdauer.')
item(21991, 0, 7, 70, nil, 'Schwerer Netherstoffverband', 'Benutzen: Heilt 3400 Schaden.')
item(22850, 0, 1, 70, nil, 'Superverjüngungstrank', 'Benutzen: Stellt Gesundheit und Mana wieder her.')
item(22829, 0, 1, 70, nil, 'Superheiltrank', 'Benutzen: Stellt Gesundheit wieder her.')
item(22854, 0, 3, 70, nil, 'Fläschchen des unerbittlichen Angriffs', 'Benutzen: Erhöht die Angriffskraft.')
equal(de:InspectItem(27854).isFood, true, 'German food found by its use spell')
equal(de:InspectItem(27854).isDrink, false, 'German food is not a drink')
equal(de:InspectItem(27860).isDrink, true, 'German drink found by its use spell')
equal(de:InspectItem(27658).isFoodBuff, true, 'German buff food found by the Well Fed name')
equal(de:InspectItem(27658).isFood, false, 'buff food not offered as plain food')
equal(de:InspectItem(21991).isBandage, true, 'German bandage found by item subclass')
equal(de:InspectItem(22850).isRejuvenationPotion, true, 'listed rejuvenation potion found without English text')
equal(de:InspectItem(22829).isRejuvenationPotion, false, 'healing potion is not a rejuvenation potion')
equal(de:InspectItem(22854).isFlask, true, 'German flask found by item subclass')
equal(de:InspectItem(27854).hasUse, true, 'localized Use: line recognized')

ITEM_SPELL_TRIGGER_ONUSE = 'Use:'
local en = loadClassifier('enUS', {[433] = 'Food', [430] = 'Drink', [19705] = 'Well Fed'})
item(211880, 0, 1, 80, nil, 'Algari Healing Potion', 'Use: Instantly restores 3,500,000 health.')
item(211879, 0, 1, 70, nil, 'Weak Healing Potion', 'Use: Instantly restores 120,000 health.')
item(212239, 0, 1, 80, nil, 'Algari Mana Potion', 'Use: Instantly restores 270,000 mana.')
item(19440, 0, 7, 40, nil, 'Powerful Anti-Venom', 'Use: Cures strong poisons.')
item(18000, 4, 2, 60, nil, 'Some Helm', 'Binds when equipped', 'Head')
item(27855, 0, 5, 65, 'Food', 'Mag\'har Grainbread', 'Use: Restores 4320 health over 30 sec. Must remain seated while eating.')
item(27861, 0, 5, 65, 'Drink', 'Purified Draenic Water', 'Use: Restores 7200 mana over 30 sec. Must remain seated while drinking.')
item(21990, 0, 7, 70, nil, 'Netherweave Bandage', 'Use: Heals 2000 damage over 8 sec.')
equal(en:InspectItem(27855).isFood and en.cache[27855].health, 4320, 'English food and amount unchanged')
equal(en:InspectItem(27861).isDrink and en.cache[27861].mana, 7200, 'English drink and amount unchanged')
equal(en:InspectItem(21990).isBandage and en.cache[21990].bandageHeal, 2000, 'English bandage and amount unchanged')
equal(en:InspectItem(211880).health, 3500000, 'thousands separators parsed')
equal(en:InspectItem(19440).isBandage, false, 'English first-aid item that heals nothing is not a bandage')
en:InspectItem(18000)
equal(en.cache[18000]._final, true, 'gear is not rescanned once its tooltip has loaded')

DB.Data.Classifier = en
cache.items = {211879, 211880, 212239}; cache.counts = {[211879]=1, [211880]=1, [212239]=1}
local bestPot, pots = DB.Data.Resolver:ResolveHealthPotion()
equal(bestPot, 211880, 'unlisted modern potion fills the health potion slot, strongest first')
equal(#pots, 2, 'mana potion kept out of the health potion slot')
equal(DB.Data.Resolver:ResolveManaPotion(), 212239, 'unlisted modern mana potion fills the mana slot')
cache.items = {211880, 22829}; cache.counts = {[211880]=1, [22829]=1}
equal(DB.Data.Resolver:ResolveHealthPotion(), 22829, 'listed potions still come first')

DB.Data.Classifier = stubClassifier
GetItemInfoInstant, GetItemInfo = saved.GetItemInfoInstant, saved.GetItemInfo
C_TooltipInfo, C_Spell, GetItemSpell, GetLocale = nil, nil, nil, nil

-- Every L["..."] key the addon uses has an English entry, so translators see it on CurseForge
local function readAll(path) local f = assert(io.open(path)); local t = f:read('*a'); f:close(); return t end
local english = {}
for key in readAll('Locales/enUS.lua'):gmatch('\nL%["(.-)"%] = true') do english[key] = true end
for _, file in ipairs({'Core.lua','Config.lua','UI/UI.lua','UI/ItemsBar.lua','UI/Builder.lua','Data/Categories.lua','Data/Classifier.lua'}) do
  for key in readAll(file):gmatch('L%["(.-)"%]') do
    equal(english[key], true, file .. ' locale key "' .. key .. '"')
  end
end

print('PASS: ' .. checks .. ' regression assertions (mock WoW APIs; in-game validation still required)')
