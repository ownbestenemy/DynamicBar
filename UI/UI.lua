-- UI/UI.lua
local DB = DynamicBar
DB.UI = DB.UI or {}
local UI = DB.UI
local L = LibStub("AceLocale-3.0"):GetLocale("DynamicBar")

UI.buttons = UI.buttons or {}

local BAR_NAME = "DynamicBarMain"
local BUTTON_SIZE = 36

-- Cache global functions (WoW Forever uses the Mainline API, which only has the C_Item versions)
local GetItemInfo = GetItemInfo or (C_Item and C_Item.GetItemInfo)
local GetItemInfoInstant = GetItemInfoInstant or (C_Item and C_Item.GetItemInfoInstant)

-- Get bar configuration from AceDB (not global DynamicBarDB)
function UI:GetBarConfig()
  return DB.db and DB.db.profile and DB.db.profile.bar
end

-- One button per slot on the bar
function UI:GetButtonCount()
  return #DB.Data.Categories:GetSlots(self:GetBarConfig())
end

-- Save current bar position to config
local function SaveBarPosition(bar)
  local cfg = UI:GetBarConfig()
  if cfg and bar then
    local point, _, relPoint, x, y = bar:GetPoint()
    cfg.point = point or "CENTER"
    cfg.relPoint = relPoint or "CENTER"
    cfg.x = x or 0
    cfg.y = y or 0
    DB:DPrint("Bar position saved: " .. point .. " -> " .. relPoint .. " (" .. x .. ", " .. y .. ")")
  end
end

local function EnsureBar()
  if UI.bar then return UI.bar end

  local bar = CreateFrame("Frame", BAR_NAME, UIParent)
  bar:SetClampedToScreen(true)
  bar:SetFrameStrata("MEDIUM")
  bar:SetFrameLevel(100)
  bar:EnableMouse(false)  -- Start locked
  bar:SetMovable(true)
  bar:RegisterForDrag("LeftButton")

  -- Drag start
  bar:SetScript("OnDragStart", function(self)
    if not InCombatLockdown() then
      self:StartMoving()
    end
  end)

  -- Drag stop - save position
  bar:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    SaveBarPosition(self)
  end)

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

-- Horizontal layout (default, backward compatible)
local function LayoutBarHorizontal(cfg)
  local buttons = UI:GetButtonCount()
  local spacing = cfg.spacingH or cfg.spacing or 2
  local padLeft = cfg.padLeft or cfg.padding or 2
  local padRight = cfg.padRight or cfg.padding or 2

  -- Inherit ElvUI spacing if enabled
  if cfg.inheritElvUI and DB.UI.Skins then
    local elvSettings = DB.UI.Skins:GetElvUIBarSettings()
    if elvSettings then
      spacing = elvSettings.buttonspacing
      padLeft = elvSettings.backdropSpacing
      padRight = elvSettings.backdropSpacing
      DB:DPrint("Using ElvUI spacing: " .. spacing .. ", padding: " .. padLeft)
    end
  end

  -- Calculate bar dimensions
  local width = (padLeft + padRight) + (BUTTON_SIZE * buttons) + (spacing * (buttons - 1))
  UI.bar:SetSize(width, BUTTON_SIZE)

  -- Position buttons left-to-right
  for i = 1, buttons do
    local btn = UI.buttons[i]
    if not btn then break end

    btn:ClearAllPoints()
    if i == 1 then
      btn:SetPoint("LEFT", UI.bar, "LEFT", padLeft, 0)
    else
      btn:SetPoint("LEFT", UI.buttons[i - 1], "RIGHT", spacing, 0)
    end
  end
end

-- Vertical layout (new)
local function LayoutBarVertical(cfg)
  local buttons = UI:GetButtonCount()
  local spacing = cfg.spacingV or 2
  local padTop = cfg.padTop or 2
  local padBottom = cfg.padBottom or 2

  -- Calculate bar dimensions
  local height = (padTop + padBottom) + (BUTTON_SIZE * buttons) + (spacing * (buttons - 1))
  UI.bar:SetSize(BUTTON_SIZE, height)

  -- Position buttons bottom-to-top
  for i = 1, buttons do
    local btn = UI.buttons[i]
    if not btn then break end

    btn:ClearAllPoints()
    if i == 1 then
      btn:SetPoint("BOTTOM", UI.bar, "BOTTOM", 0, padBottom)
    else
      btn:SetPoint("BOTTOM", UI.buttons[i - 1], "TOP", 0, spacing)
    end
  end
end

-- Grid layout (new)
local function LayoutBarGrid(cfg)
  local rows = cfg.gridRows or 2
  local cols = cfg.gridCols or 6
  local buttons = UI:GetButtonCount()
  -- Preserve the selected column count, expanding rows to fit every button.
  rows = math.max(rows, math.ceil(buttons / cols))
  cfg.gridRows = rows
  local spacingH = cfg.spacingH or cfg.spacing or 2
  local spacingV = cfg.spacingV or 2
  local padLeft = cfg.padLeft or cfg.padding or 2
  local padRight = cfg.padRight or cfg.padding or 2
  local padTop = cfg.padTop or 2
  local padBottom = cfg.padBottom or 2

  -- Calculate bar dimensions
  local width = (padLeft + padRight) + (BUTTON_SIZE * cols) + (spacingH * (cols - 1))
  local height = (padTop + padBottom) + (BUTTON_SIZE * rows) + (spacingV * (rows - 1))
  UI.bar:SetSize(width, height)

  -- Position buttons in grid (fill row-by-row, left-to-right, bottom-to-top)
  local btnIndex = 0
  for row = rows, 1, -1 do  -- Bottom row = row 1, top row = row N
    for col = 1, cols do
      btnIndex = btnIndex + 1
      if btnIndex > buttons then break end

      local btn = UI.buttons[btnIndex]
      if not btn then break end

      -- Calculate position
      local xOffset = padLeft + ((col - 1) * (BUTTON_SIZE + spacingH))
      local yOffset = padBottom + ((row - 1) * (BUTTON_SIZE + spacingV))

      btn:ClearAllPoints()
      btn:SetPoint("BOTTOMLEFT", UI.bar, "BOTTOMLEFT", xOffset, yOffset)
    end
    if btnIndex >= buttons then break end
  end
end

-- Main layout dispatcher
local function LayoutBar()
  local cfg = UI:GetBarConfig()
  local mode = cfg.layoutMode or "HORIZONTAL"

  if mode == "HORIZONTAL" then
    LayoutBarHorizontal(cfg)
  elseif mode == "VERTICAL" then
    LayoutBarVertical(cfg)
  elseif mode == "GRID" then
    LayoutBarGrid(cfg)
  else
    -- Fallback to horizontal for unknown modes
    DB:DPrint("Unknown layout mode: " .. tostring(mode) .. ", using HORIZONTAL")
    LayoutBarHorizontal(cfg)
  end
end

local function EnsureButtons()
  local cfg = UI:GetBarConfig()
  local buttons = UI:GetButtonCount()

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
  local tex = select(5, GetItemInfoInstant(itemID))
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

--[[
  Slots are assigned to buttons in priority order (urgency -> convenience),
  customizable via the config panel.

  Mode switching (implicit):
  - Prep mode (out of combat): every slot is shown
  - Battle mode (in combat): only slots flagged `battle` are shown; prep-only
    slots get no macro so their keybinds can't fire in combat
]]--
-- Categories live in Data/Categories.lua; kept here under the old names for compatibility
local Cats = DB.Data.Categories
UI.SLOT_DEFS = Cats.Registry
UI.DEFAULT_SLOT_ORDER = Cats.DEFAULT_ORDER

-- The bar's slots in order, one button each
local function GetSlotOrder()
  local result = {}
  for _, key in ipairs(Cats:GetSlots(UI:GetBarConfig())) do
    result[#result + 1] = Cats.Registry[key]
  end
  return result
end

local function AssignItem(btn, itemID)
  UI.Actions:AssignMacro(btn, "/use item:" .. itemID, GetItemTex(itemID), itemID)
end

local function CreateFlyoutButton(name, parent, size)
  return UI.Buttons:CreateSecureButton(name, parent, size)
end

-- Show the slot's alternatives on hover; a single item (or none) needs no flyout,
-- and an empty list clears and hides any stale flyout.
local function ApplySlotFlyout(btn, list)
  if not list or #list <= 1 then list = {} end
  UI.Flyouts:ApplyItemFlyout(btn, list, 6, CreateFlyoutButton, BUTTON_SIZE, AssignItem)
end

-- Resolve the slot's best item into btn. Returns true if an item was assigned.
local function FillSlot(btn, slot)
  local resolver = DB.Data and DB.Data.Resolver
  local fn = resolver and resolver[slot.resolver]
  if type(fn) ~= "function" then return false end

  local itemID, flyout = fn(resolver)
  if not itemID then return false end

  AssignItem(btn, itemID)
  ApplySlotFlyout(btn, flyout)
  return true
end

-- Update bar lock state
function UI:UpdateLockState(silent)
  if InCombatLockdown() then
    DB._needsRebuild = true
    return
  end
  if not self.bar then return end

  local cfg = self:GetBarConfig()
  if not cfg then return end

  local locked = cfg.locked ~= false  -- Default to locked

  -- Create background overlay frame if it doesn't exist
  if not self.bar._lockOverlay then
    -- Create a frame that sits on top of all buttons and handles dragging
    local overlay = CreateFrame("Frame", nil, self.bar, "SecureHandlerStateTemplate")
    overlay:SetAllPoints(self.bar)
    overlay:SetFrameStrata("HIGH")  -- Higher than buttons
    overlay:SetFrameLevel(200)  -- Much higher than button levels (110+)
    overlay:EnableMouse(true)  -- Capture clicks for dragging
    overlay:RegisterForDrag("LeftButton")

    -- Drag handlers that delegate to parent bar
    overlay:SetScript("OnDragStart", function()
      if not InCombatLockdown() and self.bar then
        self.bar:StartMoving()
      end
    end)

    overlay:SetScript("OnDragStop", function()
      if self.bar then
        self.bar:StopMovingOrSizing()
        SaveBarPosition(self.bar)
      end
    end)

    -- Green background texture
    local bg = overlay:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(overlay)
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetVertexColor(0, 1, 0, 0.4)  -- Bright green, 40% opacity

    -- "DRAG ME" text label
    local label = overlay:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    label:SetText(L["DRAG ME"])
    label:SetPoint("CENTER", overlay, "CENTER", 0, 10)
    label:SetTextColor(1, 1, 1, 1)

    -- "Save & Lock" button
    local lockBtn = CreateFrame("Button", nil, overlay)
    lockBtn:SetSize(100, 24)
    lockBtn:SetPoint("CENTER", overlay, "CENTER", 0, -15)

    -- Button background
    local btnBg = lockBtn:CreateTexture(nil, "BACKGROUND")
    btnBg:SetAllPoints(lockBtn)
    btnBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    btnBg:SetVertexColor(0, 0.5, 0, 0.8)

    -- Button text
    local btnText = lockBtn:CreateFontString(nil, "OVERLAY")
    btnText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    btnText:SetText(L["Save & Lock"])
    btnText:SetPoint("CENTER", lockBtn, "CENTER", 0, 0)
    btnText:SetTextColor(1, 1, 1, 1)

    -- Button click handler
    lockBtn:SetScript("OnClick", function()
      local cfg = UI:GetBarConfig()
      if cfg then
        cfg.locked = true
        DB.db.profile._setupComplete = true
        if UI.UpdateLockState then
          UI:UpdateLockState()
        end
        DB:Print(L["Bar position saved and locked!"])
      end
    end)

    -- Button hover effect
    lockBtn:SetScript("OnEnter", function()
      btnBg:SetVertexColor(0, 0.7, 0, 1.0)
    end)
    lockBtn:SetScript("OnLeave", function()
      btnBg:SetVertexColor(0, 0.5, 0, 0.8)
    end)

    overlay:Hide()
    overlay._bg = bg
    overlay._label = label
    overlay._lockBtn = lockBtn
    self.bar._lockOverlay = overlay
  end

  if locked then
    self.bar:EnableMouse(false)
    if self.bar._lockOverlay then
      UnregisterStateDriver(self.bar._lockOverlay, "visibility")
      self.bar._lockOverlay:Hide()
    end
    -- Request rebuild to restore normal button visibility (only if not already in a rebuild)
    -- Use RequestRebuild instead of direct Rebuild to avoid recursion
    if not silent and not InCombatLockdown() then
      DB:RequestRebuild("lock_state")
    end
    if not silent then
      DB:Print(L["Bar locked"])
    end
  else
    self.bar:EnableMouse(true)

    -- Show ALL buttons while unlocked (for precise positioning)
    -- Users can see full bar dimensions regardless of what items they have
    if not InCombatLockdown() then
      local n = UI:GetButtonCount()
      for i = 1, n do
        if self.buttons[i] then
          self.buttons[i]:Show()
          self.buttons[i]:SetAlpha(0.5)  -- Dimmed to indicate positioning mode
        end
      end
    end

    if self.bar._lockOverlay then
      -- Hide the positioning overlay securely if combat begins while unlocked.
      RegisterStateDriver(self.bar._lockOverlay, "visibility", "[combat] hide; show")

      -- Keep the way to finish positioning visible on every unlock.
      local overlay = self.bar._lockOverlay
      local firstTime = not DB.db.profile._setupComplete
      overlay._bg:SetVertexColor(0, 1, 0, firstTime and 0.4 or 0.15)
      overlay._label:Show()
      overlay._lockBtn:Show()
    end
    if not silent then
      DB:Print("|cff00ff00" .. L["Bar UNLOCKED - You can now drag the bar!"] .. "|r")
    end
  end
end

-- Collect itemIDs from all visible buttons (for targeted cache refresh)
function UI:GetButtonItemIDs()
  local itemIDs = {}
  for i, btn in ipairs(self.buttons) do
    if btn and btn:IsShown() and btn._dynItemID then
      itemIDs[#itemIDs + 1] = btn._dynItemID
    end
  end
  return itemIDs
end

-- Update button visuals during combat (item counts, depleted items)
-- Called from BAG_UPDATE when in combat - can't modify secure attributes
function UI:UpdateButtonsInCombat()
  if not InCombatLockdown() then return end  -- Only for combat updates

  for i, btn in ipairs(self.buttons) do
    if btn and btn:IsShown() and UI.Actions then
      UI.Actions:UpdateInCombat(btn)
    end
  end
end

function UI:Rebuild()
  if InCombatLockdown() then
    DB._needsRebuild = true
    return
  end
  local DB = DynamicBar
  if not DB.db or not DB.db.profile or not DB.db.profile.enabled then
    for _, btn in ipairs(self.buttons) do
      self.Actions:Clear(btn)
      if btn._dynFlyout then ApplySlotFlyout(btn, nil) end
      btn:Hide()
      self.Buttons:ConfigureCombat(btn, false, "HIDE")
    end
    if self.bar then self.bar:Hide() end
    return
  end

  if not UI.Actions or not UI.Buttons or not UI.Flyouts then
    DB:Print(L["UI modules not loaded"])
    return
  end

  EnsureBar()
  UpdateBarPosition()
  EnsureButtons()
  LayoutBar()
  UI.bar:Show()

  local cfg = UI:GetBarConfig()
  if not cfg then
    DB:Print(L["Failed to get bar configuration"])
    return
  end

  local inBattle = GetCurrentMode() == "battle"
  local n = UI:GetButtonCount()
  local displayMode = cfg.buttonDisplayMode or "SMART"
  local visMode = cfg.visibilityMode or "FADE"

  -- Clear all buttons; slots below re-assign what they need
  for i = 1, #UI.buttons do
    UI.Actions:Clear(UI.buttons[i])
    UI.buttons[i]._dynPrepOnly = false
  end

  -- Visibility for a slot button: available slots are always full and clickable;
  -- unavailable ones follow the user's visibility mode.
  local function ApplyVisibility(btn, available)
    local alpha, clickable, shown = 1.0, true, true
    if not available then
      if visMode == "FADE" then
        alpha, clickable = 0.3, false
      elseif visMode == "HIDE" then
        clickable, shown = false, false  -- alpha reset for when it shows again
      elseif visMode == "GREY" then
        alpha, clickable = 0.4, false
      end  -- ALWAYS: full visibility, clickable
    end
    btn:SetAlpha(alpha)
    btn:EnableMouse(clickable)
    btn:SetShown(shown)
  end

  -- DYNAMIC: collapse empty slots (button positions shift, breaks keybinds)
  -- SMART:   hide empty slots but keep their positions (stable keybinds)
  -- STATIC:  always show every slot, empty or not
  local used = 0
  for _, slot in ipairs(GetSlotOrder()) do
    -- Prep-only slots are never assigned in combat, so their keybinds can't fire
    local allowed = slot.battle or not inBattle

    if displayMode == "DYNAMIC" then
      if used >= n then break end
      if allowed and FillSlot(UI.buttons[used + 1], slot) then
        used = used + 1
        UI.buttons[used]._dynPrepOnly = not slot.battle
        ApplyVisibility(UI.buttons[used], true)
      end
    else
      used = used + 1
      if used > n then used = n; break end
      local btn = UI.buttons[used]
      btn._dynPrepOnly = not slot.battle
      if allowed and FillSlot(btn, slot) then
        ApplyVisibility(btn, true)
      else
        ApplySlotFlyout(btn, nil)
        if displayMode == "STATIC" then
          ApplyVisibility(btn, allowed)
        else
          btn:Hide()
        end
      end
    end
  end

  -- Buttons past the last slot: STATIC shows empty placeholders up to the
  -- configured count; everything else (and anything past the count) is hidden.
  for i = used + 1, #UI.buttons do
    local btn = UI.buttons[i]
    if btn._dynFlyout then ApplySlotFlyout(btn, nil) end
    if displayMode == "STATIC" and i <= n then
      btn:SetAlpha(1.0)
      btn:EnableMouse(false)
      btn:Show()
    else
      btn:Hide()
    end
  end

  -- Install secure combat behavior after the prep layout is fully resolved.
  -- Dynamic mode keeps these exact positions for the duration of combat.
  for _, btn in ipairs(UI.buttons) do
    UI.Buttons:ConfigureCombat(btn, btn._dynPrepOnly, visMode)
  end
  UI:UpdateLockState(true)  -- Apply the positioning overlay after normal visibility.
end
