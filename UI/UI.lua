-- UI/UI.lua
local DB = DynamicBar
DB.UI = DB.UI or {}
local UI = DB.UI

UI.buttons = UI.buttons or {}

local BAR_NAME = "DynamicBarMain"
local BUTTON_SIZE = 36

-- Get bar configuration from AceDB (not global DynamicBarDB)
function UI:GetBarConfig()
  return DB.db and DB.db.profile and DB.db.profile.bar
end

local function EnsureBar()
  if UI.bar then return UI.bar end

  local bar = CreateFrame("Frame", BAR_NAME, UIParent)
  bar:EnableMouse(false)
  bar:SetClampedToScreen(true)
  bar:SetFrameStrata("MEDIUM")
  bar:SetFrameLevel(100)

  UI.bar = bar
  return bar
end

local function UpdateBarPosition()
  if not UI.bar then return end
  local cfg = UI:GetBarConfig()
  if not cfg then return end

  -- Update scale
  UI.bar:SetScale(cfg.scale or 1.0)

  -- Update position
  UI.bar:ClearAllPoints()
  UI.bar:SetPoint(cfg.point or "CENTER", UIParent, cfg.relPoint or "CENTER", cfg.x or 0, cfg.y or 0)
end

local function LayoutBar()
  local cfg = UI:GetBarConfig()
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
  local cfg = UI:GetBarConfig()
  local buttons = cfg.buttons or 10

  for i = 1, buttons do
    if not UI.buttons[i] then
      local name = BAR_NAME .. "Button" .. i
      local btn = UI.Buttons:CreateSecureButton(name, UI.bar, BUTTON_SIZE)
      btn:SetFrameStrata("MEDIUM")
      btn:SetFrameLevel(110 + i)
      UI.buttons[i] = btn
    else
      -- Show previously hidden buttons when count increases
      UI.buttons[i]:Show()
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

-- Get current mode based on combat state
-- Uses explicit _inCombat flag instead of InCombatLockdown() to avoid
-- race condition where PLAYER_REGEN_DISABLED fires before lockdown state syncs
local function GetCurrentMode()
  return DB._inCombat and "battle" or "prep"
end

-- AssignHearth removed - now uses ResolveHearth() like all other slots

--[[
  SLOT_ORDER defines the role-first priority ordering per Design Contract.
  Slots are assigned to buttons sequentially - no hardcoded indices.

  Order follows urgency → convenience:
  1. Emergency Conversion (Healthstone, Dark Rune) - both modes
  2. Health Potions - both modes
  3. Mana Potions - both modes
  4. Bandages - both modes (for bubble-bandage, etc.)
  5. Battle Elixir - prep only (pre-buff)
  6. Guardian Elixir - prep only (pre-buff)
  7. Food (buff) - prep only
  8. Food (non-buff) - prep only
  9. Drink - prep only
  10. Hearthstone (always last) - both modes

  Mode switching (implicit):
  - Battle mode (in combat): Shows slots with "battle" mode flag
  - Prep mode (out of combat): Shows slots with "prep" mode flag
  - Battle slots maintain same positions when switching modes
]]--
local SLOT_ORDER = {
  -- Battle mode items (always visible)
  { resolver = "ResolveHealthstone",     flyoutField = "_healthstoneFlyout",    modes = {"battle", "prep"} },
  { resolver = "ResolveHealthPotion",    flyoutField = "_healthPotionFlyout",   modes = {"battle", "prep"} },
  { resolver = "ResolveManaPotion",      flyoutField = "_manaPotionFlyout",     modes = {"battle", "prep"} },
  { resolver = "ResolveBandage",         flyoutField = "_bandageFlyout",        modes = {"battle", "prep"} },

  -- Prep-only items (hidden in combat)
  { resolver = "ResolveBattleElixir",    flyoutField = "_battleElixirFlyout",   modes = {"prep"} },
  { resolver = "ResolveGuardianElixir",  flyoutField = "_guardianElixirFlyout", modes = {"prep"} },
  { resolver = "ResolveFoodBuff",        flyoutField = "_foodBuffFlyout",       modes = {"prep"} },
  { resolver = "ResolveFoodNonBuff",     flyoutField = "_foodNonBuffFlyout",    modes = {"prep"} },
  { resolver = "ResolveDrink",           flyoutField = "_drinkFlyout",          modes = {"prep"} },

  -- Always last (both modes)
  { resolver = "ResolveHearth",          flyoutField = "_hearthFlyout",         modes = {"battle", "prep"} },
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
  if not DynamicBarDB or not DynamicBarDB.profile then
    if self.bar then self.bar:Hide() end
    return
  end

  if not DynamicBarDB.profile.enabled then
    if self.bar then self.bar:Hide() end
    return
  end

  if not UI.Actions or not UI.Buttons or not UI.Flyouts then
    DB:Print("UI modules not loaded")
    return
  end

  EnsureBar()
  UpdateBarPosition()
  EnsureButtons()
  LayoutBar()
  UI.bar:Show()

  local cfg = UI:GetBarConfig()
  if not cfg then
    DB:Print("Failed to get bar configuration")
    return
  end

  local currentMode = GetCurrentMode()
  local n = cfg.buttons or 10

  -- Clear all currently assigned buttons
  for i = 1, n do
    if UI.buttons[i] then
      UI.Actions:Clear(UI.buttons[i])
    end
  end

  -- Assign slots sequentially, filtering by current mode
  local nextButtonIdx = 1
  for _, slot in ipairs(SLOT_ORDER) do
    if nextButtonIdx > n then break end

    -- Check if this slot is valid for current mode
    local validForMode = false
    for _, mode in ipairs(slot.modes or {"prep"}) do
      if mode == currentMode then
        validForMode = true
        break
      end
    end

    if validForMode then
      slot.idx = nextButtonIdx  -- Dynamically assign button index
      AssignResolverSlot(slot)
      ApplySlotFlyout(slot)
      nextButtonIdx = nextButtonIdx + 1
    end
  end

  -- Hide any buttons beyond the current count
  for i = nextButtonIdx, #UI.buttons do
    if UI.buttons[i] then
      UI.buttons[i]:Hide()
      UI.Actions:Clear(UI.buttons[i])
    end
  end
end

