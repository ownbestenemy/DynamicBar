-- UI/UI.lua
local DB = DynamicBar
DB.UI = DB.UI or {}
local UI = DB.UI

UI.buttons = UI.buttons or {}

local BAR_NAME = "DynamicBarMain"
local BUTTON_SIZE = 36

local function GetCfg()
  return DynamicBarDB and DynamicBarDB.profile and DynamicBarDB.profile.bar
end

local function EnsureBar()
  if UI.bar then return UI.bar end

  local cfg = GetCfg()
  local bar = CreateFrame("Frame", BAR_NAME, UIParent)
  bar:SetScale(cfg.scale or 1.0)
  bar:SetPoint(cfg.point or "CENTER", UIParent, cfg.relPoint or "CENTER", cfg.x or 0, cfg.y or 0)

  bar:EnableMouse(false)
  bar:SetClampedToScreen(true)
  bar:SetFrameStrata("DIALOG")
  bar:SetFrameLevel(100)

  UI.bar = bar
  return bar
end

local function LayoutBar()
  local cfg = GetCfg()
  local buttons = cfg.buttons or 8
  local spacing = cfg.spacing or 4

  UI.bar:SetSize((BUTTON_SIZE * buttons) + (spacing * (buttons - 1)), BUTTON_SIZE)

  for i = 1, buttons do
    local btn = UI.buttons[i]
    if not btn then break end

    btn:ClearAllPoints()
    if i == 1 then
      btn:SetPoint("LEFT", UI.bar, "LEFT", 0, 0)
    else
      btn:SetPoint("LEFT", UI.buttons[i - 1], "RIGHT", spacing, 0)
    end
  end
end

local function EnsureButtons()
  local cfg = GetCfg()
  local buttons = cfg.buttons or 8

  for i = 1, buttons do
    if not UI.buttons[i] then
      local name = BAR_NAME .. "Button" .. i
      local btn = UI.Buttons:CreateSecureButton(name, UI.bar, BUTTON_SIZE)
      btn:SetFrameStrata("DIALOG")
      btn:SetFrameLevel(110 + i)
      UI.buttons[i] = btn
    end
  end
end

local function GetItemTex(itemID)
  local tex = select(10, GetItemInfoInstant(itemID))
  if not tex then
    tex = select(10, GetItemInfo(itemID))
  end
  if not tex then
    tex = "Interface\\Icons\\INV_Misc_QuestionMark"
  end
  return tex
end

local function AssignHearth()
  if not UI.buttons[1] then return end
  if InCombatLockdown() then return end

  local cache = DB.Data and DB.Data.BagCache
  local cats  = DB.Data and DB.Data.Categories
  if not cache or not cats or not cats.Hearth then return end

  local itemID = cache:FindFirst(cats.Hearth)
  if not itemID then return end

  UI.Actions:AssignMacro(UI.buttons[1], "/use item:" .. itemID, GetItemTex(itemID), itemID)
end

local function AssignFoodNonBuff()
  if not UI.buttons[2] then return end
  if InCombatLockdown() then return end

  local resolver = DB.Data and DB.Data.Resolver
  if not resolver then return end

  local itemID, flyout = resolver:ResolveFoodNonBuff()
  if not itemID then
    UI._foodNonBuffFlyout = {}
    return
  end

  UI.Actions:AssignMacro(UI.buttons[2], "/use item:" .. itemID, GetItemTex(itemID), itemID)
  UI._foodNonBuffFlyout = flyout or {}
end

local function AssignFoodBuff()
  if not UI.buttons[3] then return end
  if InCombatLockdown() then return end

  local resolver = DB.Data and DB.Data.Resolver
  if not resolver then return end

  local itemID, flyout = resolver:ResolveFoodBuff()
  if not itemID then
    UI._foodBuffFlyout = {}
    return
  end

  UI.Actions:AssignMacro(UI.buttons[3], "/use item:" .. itemID, GetItemTex(itemID), itemID)
  UI._foodBuffFlyout = flyout or {}
end

local function AssignHealthPotion()
  if not UI.buttons[5] then return end
  if InCombatLockdown() then return end

  local resolver = DB.Data and DB.Data.Resolver
  if not resolver then return end

  local itemID, flyout = resolver:ResolveHealthPotion()
  if not itemID then
    UI._healthPotionFlyout = {}
    return
  end

  UI.Actions:AssignMacro(UI.buttons[5], "/use item:" .. itemID, GetItemTex(itemID), itemID)
  UI._healthPotionFlyout = flyout or {}
end

local function AssignManaPotion()
  if not UI.buttons[6] then return end
  if InCombatLockdown() then return end

  local resolver = DB.Data and DB.Data.Resolver
  if not resolver then return end

  local itemID, flyout = resolver:ResolveManaPotion()
  if not itemID then
    UI._manaPotionFlyout = {}
    return
  end

  UI.Actions:AssignMacro(UI.buttons[6], "/use item:" .. itemID, GetItemTex(itemID), itemID)
  UI._manaPotionFlyout = flyout or {}
end

local function AssignDrink()
  if not UI.buttons[4] then return end
  if InCombatLockdown() then return end

  local resolver = DB.Data and DB.Data.Resolver
  if not resolver then return end

  local itemID, flyout = resolver:ResolveDrink()
  if not itemID then
    UI._drinkFlyout = {}
    return
  end

  UI.Actions:AssignMacro(UI.buttons[4], "/use item:" .. itemID, GetItemTex(itemID), itemID)
  UI._drinkFlyout = flyout or {}
end

function UI:ApplyFoodNonBuffFlyout()
  if not self.buttons[2] then return end
  if InCombatLockdown() then return end

  local list = self._foodNonBuffFlyout or {}
  if #list <= 1 then
    if self.buttons[2]._dynFlyout then
      self.buttons[2]._dynFlyout:Hide()
    end
    return
  end

  self.Flyouts:ApplyItemFlyout(
    self.buttons[2],
    list,
    6,
    function(name, parent, size)
      return self.Buttons:CreateSecureButton(name, parent, size)
    end,
    BUTTON_SIZE,
    function(btn, itemID)
      self.Actions:AssignMacro(btn, "/use item:" .. itemID, GetItemTex(itemID), itemID)
    end
  )
end

function UI:ApplyFoodBuffFlyout()
  if not self.buttons[3] then return end
  if InCombatLockdown() then return end

  local list = self._foodBuffFlyout or {}
  if #list <= 1 then
    if self.buttons[3]._dynFlyout then
      self.buttons[3]._dynFlyout:Hide()
    end
    return
  end

  self.Flyouts:ApplyItemFlyout(
    self.buttons[3],
    list,
    6,
    function(name, parent, size)
      return self.Buttons:CreateSecureButton(name, parent, size)
    end,
    BUTTON_SIZE,
    function(btn, itemID)
      self.Actions:AssignMacro(btn, "/use item:" .. itemID, GetItemTex(itemID), itemID)
    end
  )
end

function UI:ApplyHealthPotionFlyout()
  if not self.buttons[5] then return end
  if InCombatLockdown() then return end

  local list = self._healthPotionFlyout or {}
  if #list <= 1 then
    if self.buttons[5]._dynFlyout then self.buttons[5]._dynFlyout:Hide() end
    return
  end

  self.Flyouts:ApplyItemFlyout(
    self.buttons[5], list, 6,
    function(name, parent, size) return self.Buttons:CreateSecureButton(name, parent, size) end,
    BUTTON_SIZE,
    function(btn, itemID)
      self.Actions:AssignMacro(btn, "/use item:" .. itemID, GetItemTex(itemID), itemID)
    end
  )
end

function UI:ApplyManaPotionFlyout()
  if not self.buttons[6] then return end
  if InCombatLockdown() then return end

  local list = self._manaPotionFlyout or {}
  if #list <= 1 then
    if self.buttons[6]._dynFlyout then self.buttons[6]._dynFlyout:Hide() end
    return
  end

  self.Flyouts:ApplyItemFlyout(
    self.buttons[6], list, 6,
    function(name, parent, size) return self.Buttons:CreateSecureButton(name, parent, size) end,
    BUTTON_SIZE,
    function(btn, itemID)
      self.Actions:AssignMacro(btn, "/use item:" .. itemID, GetItemTex(itemID), itemID)
    end
  )
end

function UI:ApplyDrinkFlyout()
  if not self.buttons[4] then return end
  if InCombatLockdown() then return end

  local list = self._drinkFlyout or {}
  if #list <= 1 then
    if self.buttons[4]._dynFlyout then self.buttons[4]._dynFlyout:Hide() end
    return
  end

  self.Flyouts:ApplyItemFlyout(
    self.buttons[4],
    list,
    6,
    function(name, parent, size) return self.Buttons:CreateSecureButton(name, parent, size) end,
    BUTTON_SIZE,
    function(btn, itemID)
      self.Actions:AssignMacro(btn, "/use item:" .. itemID, GetItemTex(itemID), itemID)
    end
  )
end

function UI:Rebuild()
  if not DynamicBarDB.profile.enabled then
    if self.bar then self.bar:Hide() end
    return
  end

  EnsureBar()
  EnsureButtons()
  LayoutBar()
  UI.bar:Show()

  local cfg = GetCfg()
  local n = cfg.buttons or 8
  for i = 1, n do
    UI.Actions:Clear(UI.buttons[i])
  end

  AssignHearth()
  AssignFoodNonBuff()
  AssignFoodBuff()
  AssignDrink()
  AssignHealthPotion()
  AssignManaPotion()
  self:ApplyFoodNonBuffFlyout()
  self:ApplyFoodBuffFlyout()
  self:ApplyDrinkFlyout()
  self:ApplyHealthPotionFlyout()
  self:ApplyManaPotionFlyout()
end
