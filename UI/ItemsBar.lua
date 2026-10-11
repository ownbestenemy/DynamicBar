-- UI/ItemsBar.lua
-- Second bar: quest items and other usable items no main bar category takes.
-- One button per item, growing and shrinking with the bags; hidden when empty.
-- It moves with the main bar's lock (Save & Lock, Edit Mode) but keeps its
-- own position. Like the main bar it never changes during combat.

local DB = DynamicBar
DB.UI = DB.UI or {}
local UI = DB.UI
UI.ItemsBar = UI.ItemsBar or {}
local ItemsBar = UI.ItemsBar
local L = LibStub("AceLocale-3.0"):GetLocale("DynamicBar")

ItemsBar.buttons = ItemsBar.buttons or {}
ItemsBar.MAX_BUTTONS = 12

local BAR_NAME = "DynamicBarItems"
local BUTTON_SIZE = 36

local GetItemInfo = GetItemInfo or (C_Item and C_Item.GetItemInfo)
local GetItemInfoInstant = GetItemInfoInstant or (C_Item and C_Item.GetItemInfoInstant)

-- Basic mode: horizontal, the full button count, and the main bar's scale
local BASIC_SETTINGS = { layoutMode = "HORIZONTAL", maxButtons = 12 }

function ItemsBar:GetConfig()
  local cfg = DB.db and DB.db.profile and DB.db.profile.itemsBar
  if not cfg then return nil end
  if not DB:IsBasicMode() then return cfg end
  return setmetatable({}, {
    __index = function(_, k)
      if k == "scale" then return DB.db.profile.bar.scale end
      local v = BASIC_SETTINGS[k]
      if v ~= nil then return v end
      return cfg[k]
    end,
    __newindex = function(_, k, v)
      if k == "scale" or BASIC_SETTINGS[k] ~= nil then return end
      cfg[k] = v
    end,
  })
end

-- Items hidden with Shift+Right-click, by item ID
function ItemsBar:GetHidden()
  local cfg = DB.db.profile.itemsBar
  cfg.hidden = cfg.hidden or {}
  return cfg.hidden
end

function ItemsBar:HideItem(itemID)
  if InCombatLockdown() or not itemID then return end
  self:GetHidden()[itemID] = true
  local name = GetItemInfo(itemID) or ("item:" .. itemID)
  DB:Print((L["%s hidden from the items bar. Reset hidden items in /dbar config."]):format(name))
  DB:RequestRebuild("items_hidden")
end

function ItemsBar:ResetHidden()
  DB.db.profile.itemsBar.hidden = {}
  DB:RequestRebuild("items_reset")
end

local function SavePosition(bar)
  local cfg = ItemsBar:GetConfig()
  if not cfg then return end
  local point, _, relPoint, x, y = bar:GetPoint()
  cfg.point, cfg.relPoint, cfg.x, cfg.y = point or "CENTER", relPoint or "CENTER", x or 0, y or 0
end

local function EnsureBar()
  if ItemsBar.bar then return ItemsBar.bar end

  local bar = CreateFrame("Frame", BAR_NAME, UIParent)
  bar:SetClampedToScreen(true)
  bar:SetFrameStrata("MEDIUM")
  bar:SetFrameLevel(100)
  bar:SetMovable(true)
  bar:EnableMouse(false)

  -- Drag handle shown while the bars are unlocked; hidden securely in combat
  local overlay = CreateFrame("Frame", nil, bar, "SecureHandlerStateTemplate")
  overlay:SetAllPoints(bar)
  overlay:SetFrameStrata("HIGH")
  overlay:SetFrameLevel(200)
  overlay:EnableMouse(true)
  overlay:RegisterForDrag("LeftButton")
  overlay:SetScript("OnDragStart", function()
    if not InCombatLockdown() then bar:StartMoving() end
  end)
  overlay:SetScript("OnDragStop", function()
    bar:StopMovingOrSizing()
    SavePosition(bar)
  end)
  local bg = overlay:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(overlay)
  bg:SetTexture("Interface\\Buttons\\WHITE8X8")
  bg:SetVertexColor(1, 0.8, 0, 0.35)
  local label = overlay:CreateFontString(nil, "OVERLAY")
  label:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
  label:SetText(L["Items"])
  label:SetPoint("CENTER", overlay, "CENTER", 0, 0)
  overlay:Hide()
  bar._overlay = overlay

  ItemsBar.bar = bar
  return bar
end

local function EnsureButton(i)
  local btn = ItemsBar.buttons[i]
  if btn then return btn end
  btn = UI.Buttons:CreateSecureButton(BAR_NAME .. "Button" .. i, ItemsBar.bar, BUTTON_SIZE)
  btn:SetFrameStrata("MEDIUM")
  btn:SetFrameLevel(110 + i)
  -- Shift+Right-click hides the item (right-click has no secure action here)
  btn:HookScript("OnClick", function(self, button)
    if button == "RightButton" and IsShiftKeyDown and IsShiftKeyDown() then
      ItemsBar:HideItem(self._dynItemID)
    end
  end)
  ItemsBar.buttons[i] = btn
  return btn
end

local function GetItemTex(itemID)
  return select(5, GetItemInfoInstant(itemID)) or select(10, GetItemInfo(itemID))
    or "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- Place `count` buttons in a row or column; spacing follows the main bar
local function Layout(cfg, count)
  local main = UI:GetBarConfig() or {}
  local spacing = main.spacingH or main.spacing or 2
  local pad = main.padLeft or main.padding or 2
  local length = pad * 2 + BUTTON_SIZE * count + spacing * (count - 1)
  local vertical = cfg.layoutMode == "VERTICAL"

  if vertical then
    ItemsBar.bar:SetSize(BUTTON_SIZE + pad * 2, length)
  else
    ItemsBar.bar:SetSize(length, BUTTON_SIZE + pad * 2)
  end
  for i = 1, count do
    local btn = ItemsBar.buttons[i]
    if not btn then break end
    btn:ClearAllPoints()
    if i == 1 then
      btn:SetPoint(vertical and "BOTTOM" or "LEFT", ItemsBar.bar, vertical and "BOTTOM" or "LEFT", vertical and 0 or pad, vertical and pad or 0)
    elseif vertical then
      btn:SetPoint("BOTTOM", ItemsBar.buttons[i - 1], "TOP", 0, spacing)
    else
      btn:SetPoint("LEFT", ItemsBar.buttons[i - 1], "RIGHT", spacing, 0)
    end
  end
end

-- The items the bar shows, in button order
function ItemsBar:GetItems()
  local cfg = self:GetConfig()
  local items = DB.Data.Resolver:ResolveUsableItems(self:GetHidden())
  local max = math.min(tonumber(cfg.maxButtons) or self.MAX_BUTTONS, self.MAX_BUTTONS)
  for i = #items, max + 1, -1 do items[i] = nil end
  return items
end

function ItemsBar:Rebuild()
  if InCombatLockdown() then
    DB._needsRebuild = true
    return
  end
  local profile = DB.db and DB.db.profile
  local cfg = self:GetConfig()
  local active = profile and profile.enabled and cfg and cfg.enabled

  local items = active and self:GetItems() or {}
  for i = 1, #items do EnsureButton(i) end

  for i, btn in ipairs(self.buttons) do
    UI.Actions:Clear(btn)
    local itemID = items[i]
    if itemID then
      UI.Actions:AssignMacro(btn, "/use item:" .. itemID, GetItemTex(itemID), itemID)
      btn:SetAlpha(1)
      btn:EnableMouse(true)
      btn:Show()
    else
      btn:Hide()
    end
    UI.Buttons:ConfigureCombat(btn, false, "ALWAYS")
  end

  local main = UI:GetBarConfig()
  local unlocked = active and ((main and main.locked == false) or UI._editMode)
  if not active or (#items == 0 and not unlocked) then
    if self.bar then
      UnregisterStateDriver(self.bar._overlay, "visibility")
      self.bar._overlay:Hide()
      self.bar:Hide()
    end
    return
  end

  EnsureBar()
  self.bar:SetScale(cfg.scale or 1.0)
  self.bar:ClearAllPoints()
  self.bar:SetPoint(cfg.point or "CENTER", UIParent, cfg.relPoint or "CENTER", cfg.x or 0, cfg.y or -230)
  -- An empty bar keeps one button's room while unlocked, so it can be placed
  Layout(cfg, math.max(#items, 1))
  self.bar:Show()

  if unlocked then
    RegisterStateDriver(self.bar._overlay, "visibility", "[combat] hide; show")
  else
    UnregisterStateDriver(self.bar._overlay, "visibility")
    self.bar._overlay:Hide()
  end
end
