-- Run from the repository root with Lua 5.1: lua5.1 tests/run.lua
local mock = dofile('tests/mock_wow.lua')
assert(loadfile('Core.lua'))('DynamicBar')
local DB = DynamicBar
DB.DPrint = function() end
DB.db = {profile = {enabled = true, _setupComplete = true, bar = {
  buttons = 12, layoutMode = 'HORIZONTAL', gridRows = 2, gridCols = 5,
  locked = true, visibilityMode = 'FADE', buttonDisplayMode = 'SMART',
}}}
for _, file in ipairs({'Data/Categories.lua','Data/BagCache.lua','Data/Resolver.lua','UI/Buttons.lua','UI/Actions.lua','UI/Flyouts.lua','UI/UI.lua','Bindings.lua','Config.lua'}) do
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
local potion, flask, hearth = UI.buttons[2], UI.buttons[8], UI.buttons[12]
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

-- Incomplete grids, including saved 2x5 defaults, grow to contain all 12 slots.
cfg.buttonDisplayMode = 'STATIC'; cfg.layoutMode = 'GRID'
for _, cols in ipairs({1,5,12}) do
  cfg.gridRows = 1; cfg.gridCols = cols
  rebuild()
  equal(cfg.gridRows * cfg.gridCols >= cfg.buttons, true, 'grid has enough capacity')
  for _, btn in ipairs(UI.buttons) do equal(btn.point[1], 'BOTTOMLEFT', 'button positioned inside grid') end
end

-- Shrinking Dynamic mode clears main and flyout actions on every discarded slot.
cfg.layoutMode = 'HORIZONTAL'; cfg.buttonDisplayMode = 'DYNAMIC'; cfg.buttons = 12
rebuild({[22829]=1,[118]=2,[22832]=1,[2455]=2,[6948]=1})
local discarded = UI.buttons[2]
click(discarded, 'RightButton')
cfg.buttons = 1
rebuild()
equal(discarded:IsShown(), false, 'discarded button hidden')
equal(discarded.attrs.type1, nil, 'discarded binding cleared')
equal(discarded._dynItemID, nil, 'discarded item ID cleared')
equal(discarded._dynCooldown:IsShown(), false, 'discarded cooldown cleared')
equal(discarded._dynFlyout:IsShown(), false, 'discarded flyout hidden')
equal(discarded._dynFlyout._count, 0, 'discarded flyout cleared')

cfg.buttons = 12; cfg.buttonDisplayMode = 'SMART'
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

local bindingFile = assert(io.open('Bindings.xml'))
local bindings = bindingFile:read('*a'); bindingFile:close()
local count = 0
for index in bindings:gmatch('name="CLICK DynamicBarMainButton(%d+):LeftButton"') do
  count = count + 1
  equal(_G['BINDING_NAME_CLICK DynamicBarMainButton' .. index .. ':LeftButton'], 'Button ' .. index, 'binding label')
  equal(UI.buttons[tonumber(index)] ~= nil, true, 'binding target exists')
end
equal(count, 12, 'all 12 click bindings declared')
equal(BINDING_HEADER_DYNAMICBAR, 'DynamicBar', 'binding section registered')
print('PASS: ' .. checks .. ' regression assertions (mock WoW APIs; in-game validation still required)')
