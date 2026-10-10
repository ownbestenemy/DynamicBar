-- Minimal WoW boundary for regression tests. Restricted snippets execute as Lua;
-- protected mutations from ordinary Lua are rejected while combat is active.
local mock = { combat = false, secure = false, frames = {}, drivers = {}, timers = {}, inventory = {}, scans = 0 }
local methods = {}
local noop = function() end
local function protected(frame)
  if mock.combat and not mock.secure and frame.protected then
    error('insecure protected-frame mutation in combat: ' .. tostring(frame.name))
  end
end
local function restricted(frame, script, newstate)
  local fn = assert(loadstring(script))
  setfenv(fn, {self = frame, newstate = newstate})
  local previous = mock.secure
  mock.secure = true
  local ok, err = pcall(fn)
  mock.secure = previous
  assert(ok, err)
end
function methods:SetAttribute(k, v) protected(self); self.attrs[k] = v end
function methods:GetAttribute(k) return self.attrs[k] end
function methods:SetScript(k, v) self.scripts[k] = v end
function methods:GetScript(k) return self.scripts[k] end
function methods:HookScript(k, v)
  local old = self.scripts[k]
  self.scripts[k] = function(...) if old then old(...) end; v(...) end
end
function methods:Show() protected(self); self.shown = true end
function methods:Hide() protected(self); self.shown = false end
function methods:IsShown() return self.shown end
function methods:SetShown(v) if v then self:Show() else self:Hide() end end
function methods:SetAlpha(v) self.alpha = v end
function methods:GetAlpha() return self.alpha end
function methods:EnableMouse(v) protected(self); self.mouse = v end
function methods:IsMouseEnabled() return self.mouse end
function methods:SetPoint(...) protected(self); self.point = {...} end
function methods:GetPoint() return unpack(self.point or {'CENTER', UIParent, 'CENTER', 0, 0}) end
function methods:ClearAllPoints() protected(self); self.point = nil end
function methods:SetSize(w, h) protected(self); self.w = w; self.h = h end
function methods:GetFrameStrata() return 'MEDIUM' end
function methods:GetFrameLevel() return 110 end
function methods:GetEffectiveScale() return 1 end
function methods:GetRect() return 500, 500, 36, 36 end
function methods:GetName() return self.name end
function methods:Execute(script) restricted(self, script) end
function methods:CreateTexture() return CreateFrame('Texture') end
function methods:CreateFontString() return CreateFrame('FontString') end
function CreateFrame(kind, name, parent, templates)
  local f = setmetatable({name = name, parent = parent, scripts = {}, attrs = {}, shown = true, alpha = 1, mouse = true}, {
    __index = function(_, k) return methods[k] or (k:match('^[A-Z]') and noop or nil) end,
  })
  if templates and templates:find('Secure') then
    f.protected = true
    local p = parent
    while p do p.protected = true; p = p.parent end
  end
  mock.frames[#mock.frames + 1] = f
  return f
end
local function applyDriver(frame, stateID, value)
  if stateID == 'visibility' then
    local previous = mock.secure
    mock.secure = true
    frame:SetShown(value == 'show')
    mock.secure = previous
  elseif frame.attrs['state-' .. stateID] ~= value then
    frame.attrs['state-' .. stateID] = value
    local script = frame.attrs['_onstate-' .. stateID]
    if script then restricted(frame, script, value) end
  end
end
function RegisterStateDriver(frame, stateID, driver)
  protected(frame)
  mock.drivers[frame] = mock.drivers[frame] or {}
  mock.drivers[frame][stateID] = driver
  local inCombat, outOfCombat = driver:match('%[combat%]%s+(%w+);%s+(%w+)')
  assert(inCombat and outOfCombat, 'unsupported test driver: ' .. driver)
  applyDriver(frame, stateID, mock.combat and inCombat or outOfCombat)
end
function UnregisterStateDriver(frame, stateID)
  protected(frame)
  if mock.drivers[frame] then mock.drivers[frame][stateID] = nil end
end
function mock.setCombat(value)
  mock.combat = value
  for frame, drivers in pairs(mock.drivers) do
    for stateID, driver in pairs(drivers) do
      local combatValue, prepValue = driver:match('%[combat%]%s+(%w+);%s+(%w+)')
      applyDriver(frame, stateID, value and combatValue or prepValue)
    end
  end
end
function InCombatLockdown() return mock.combat end
function GetScreenWidth() return 1920 end
function GetScreenHeight() return 1080 end
function GetTime() return 100 end
function GetItemInfo(id) return 'Item ' .. id, 'item:' .. id, 1, 1, 1, 'Consumable', 'Potion', 20, '', 123 end
function GetItemInfoInstant(id) return id, 'Consumable', 'Potion', '', 123, 0, 1 end
function GetItemCount(id) return mock.inventory[id] or 0 end
C_Container = {
  GetContainerNumSlots = function(bag)
    if bag ~= 0 then return 0 end
    mock.scans = mock.scans + 1
    mock.bag = {}
    for id, count in pairs(mock.inventory) do if count > 0 then mock.bag[#mock.bag+1] = id end end
    table.sort(mock.bag)
    return #mock.bag
  end,
  GetContainerItemLink = function(_, slot) return 'item:' .. mock.bag[slot] end,
  GetContainerItemInfo = function(_, slot) return {stackCount = mock.inventory[mock.bag[slot]]} end,
}
UIParent = CreateFrame('Frame', 'UIParent')
GameTooltip = CreateFrame('GameTooltip')
DEFAULT_CHAT_FRAME = {AddMessage = noop}
StaticPopupDialogs = {}
StaticPopup_Show = noop
C_Timer = {After = function(delay, fn) mock.timers[#mock.timers+1] = {delay = delay, fn = fn} end}
function mock.runTimers(delay)
  local timers = mock.timers
  mock.timers = {}
  for _, t in ipairs(timers) do
    if t.delay == delay then t.fn() else mock.timers[#mock.timers+1] = t end
  end
end
local locale = setmetatable({}, {__index = function(_, k) return k end})
local aceConfig = {RegisterOptionsTable = noop}
local aceDialog = {AddToBlizOptions = noop}
function LibStub(name)
  if name == 'AceLocale-3.0' then return {GetLocale = function() return locale end} end
  if name == 'AceAddon-3.0' then return {NewAddon = function() return {} end, GetAddon = function() return DynamicBar end} end
  if name == 'AceConfig-3.0' then return aceConfig end
  if name == 'AceConfigDialog-3.0' then return aceDialog end
end
return mock
