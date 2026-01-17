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
  local buttons = cfg.buttons or 10
  local spacing = cfg.spacing or 6
  local padding = cfg.padding or 6

  UI.bar:SetSize(
    (padding * 2) + (BUTTON_SIZE * buttons) + (spacing * (buttons - 1)),
    BUTTON_SIZE
  )


  for i = 1, buttons do
    local btn = UI.buttons[i]
    if not btn then break end

    btn:ClearAllPoints()
    if i == 1 then
      btn:SetPoint("LEFT", UI.bar, "LEFT", padding, 0)
    else
      btn:SetPoint("LEFT", UI.buttons[i - 1], "RIGHT", spacing, 0)
    end
  end
end

local function EnsureButtons()
  local cfg = GetCfg()
  local buttons = cfg.buttons or 10

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

-- Slot metadata for resolver-driven buttons (keeps UI.lua DRY)
local SLOTS = {
  { idx = 2, resolver = "ResolveFoodNonBuff", flyoutField = "_foodNonBuffFlyout" },
  { idx = 3, resolver = "ResolveFoodBuff",    flyoutField = "_foodBuffFlyout" },
  { idx = 4, resolver = "ResolveDrink",       flyoutField = "_drinkFlyout" },
  { idx = 5, resolver = "ResolveHealthPotion",flyoutField = "_healthPotionFlyout" },
  { idx = 6, resolver = "ResolveManaPotion",  flyoutField = "_manaPotionFlyout" },
  { idx = 7, resolver = "ResolveBattleElixir",flyoutField = "_battleElixirFlyout" },
  { idx = 8, resolver = "ResolveGuardianElixir",flyoutField = "_guardianElixirFlyout" },
  { idx = 9, resolver = "ResolveHealthstone", flyoutField = "_healthstoneFlyout" },
  { idx = 10,resolver = "ResolveBandage",     flyoutField = "_bandageFlyout" },
}

local function AssignResolverSlot(slot)
  local btn = UI.buttons[slot.idx]
  if not btn then return end
  if InCombatLockdown() then return end

  local resolver = DB.Data and DB.Data.Resolver
  if not resolver then return end

  local fn = resolver[slot.resolver]
  if type(fn) ~= "function" then return end

  local itemID, flyout = fn(resolver)
  if not itemID then
    UI[slot.flyoutField] = {}
    return
  end

  UI.Actions:AssignMacro(btn, "/use item:" .. itemID, GetItemTex(itemID), itemID)
  UI[slot.flyoutField] = flyout or {}
end

local function ApplySlotFlyout(slot)
  local btn = UI.buttons[slot.idx]
  if not btn then return end
  if InCombatLockdown() then return end

  local list = UI[slot.flyoutField] or {}
  if #list <= 1 then
    if btn._dynFlyout then btn._dynFlyout:Hide() end
    return
  end

  UI.Flyouts:ApplyItemFlyout(
    btn,
    list,
    6,
    function(name, parent, size)
      return UI.Buttons:CreateSecureButton(name, parent, size)
    end,
    BUTTON_SIZE,
    function(fbtn, itemID)
      UI.Actions:AssignMacro(fbtn, "/use item:" .. itemID, GetItemTex(itemID), itemID)
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
  local n = cfg.buttons or 10
  for i = 1, n do
    UI.Actions:Clear(UI.buttons[i])
  end

  AssignHearth()

  -- Resolver-driven slots (food/drink/potions/elixirs/etc)
  for _, slot in ipairs(SLOTS) do
    if slot.idx <= n then
      AssignResolverSlot(slot)
      ApplySlotFlyout(slot)
    end
  end
end

