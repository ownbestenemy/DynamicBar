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

    -- Save the new position
    local cfg = UI:GetBarConfig()
    if cfg then
      local point, _, relPoint, x, y = self:GetPoint()
      cfg.point = point or "CENTER"
      cfg.relPoint = relPoint or "CENTER"
      cfg.x = x or 0
      cfg.y = y or 0

      DB:DPrint("Bar position saved: " .. point .. " -> " .. relPoint .. " (" .. x .. ", " .. y .. ")")
    end
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
  local buttons = cfg.buttons or 10
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
  local buttons = cfg.buttons or 10
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
  local cols = cfg.gridCols or 5
  local buttons = cfg.buttons or 10
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

-- Update bar lock state
function UI:UpdateLockState()
  if not self.bar then return end

  local cfg = self:GetBarConfig()
  if not cfg then return end

  local locked = cfg.locked ~= false  -- Default to locked

  -- Create background overlay frame if it doesn't exist
  if not self.bar._lockOverlay then
    -- Create a frame that sits on top of all buttons and handles dragging
    local overlay = CreateFrame("Frame", nil, self.bar)
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

        -- Save position
        local cfg = UI:GetBarConfig()
        if cfg then
          local point, _, relPoint, x, y = self.bar:GetPoint()
          cfg.point = point or "CENTER"
          cfg.relPoint = relPoint or "CENTER"
          cfg.x = x or 0
          cfg.y = y or 0
          DB:DPrint("Bar position saved: " .. point .. " -> " .. relPoint .. " (" .. x .. ", " .. y .. ")")
        end
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
    label:SetText("DRAG ME")
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
    btnText:SetText("Save & Lock")
    btnText:SetPoint("CENTER", lockBtn, "CENTER", 0, 0)
    btnText:SetTextColor(1, 1, 1, 1)

    -- Button click handler
    lockBtn:SetScript("OnClick", function()
      local cfg = UI:GetBarConfig()
      if cfg then
        cfg.locked = true
        if UI.UpdateLockState then
          UI:UpdateLockState()
        end
        DB:Print("Bar position saved and locked!")
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
    self.bar._lockOverlay = overlay
  end

  if locked then
    self.bar:EnableMouse(false)
    if self.bar._lockOverlay then
      self.bar._lockOverlay:Hide()
    end
    DB:Print("Bar locked")
  else
    self.bar:EnableMouse(true)
    if self.bar._lockOverlay then
      self.bar._lockOverlay:Show()
    end
    DB:Print("|cff00ff00Bar UNLOCKED - You can now drag the bar!|r")
  end
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
  UI:UpdateLockState()  -- Update lock/unlock state
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

  -- Assign ALL slots sequentially (no mode filtering)
  -- Slots will be greyed/disabled if not valid for current mode
  -- This preserves muscle memory - buttons never change position
  for i, slot in ipairs(SLOT_ORDER) do
    if i > n then break end

    slot.idx = i  -- Sequential assignment (no gaps)

    -- Check if slot is valid for current mode
    local validForMode = false
    for _, mode in ipairs(slot.modes or {"prep"}) do
      if mode == currentMode then
        validForMode = true
        break
      end
    end

    -- Assign item regardless of mode
    AssignResolverSlot(slot)
    ApplySlotFlyout(slot)

    -- Apply visibility mode for unavailable slots
    if UI.buttons[i] then
      local visMode = cfg.visibilityMode or "FADE"

      if not validForMode then
        -- Unavailable slot - apply user's chosen visibility mode
        if visMode == "FADE" then
          UI.buttons[i]:SetAlpha(0.3)  -- Fade to 30%
          UI.buttons[i]:EnableMouse(false)
          UI.buttons[i]:Show()  -- Ensure visible (might be hidden from previous mode)
        elseif visMode == "HIDE" then
          UI.buttons[i]:Hide()  -- Completely hidden
          UI.buttons[i]:SetAlpha(1.0)  -- Reset alpha for when it shows again
          UI.buttons[i]:EnableMouse(false)
        elseif visMode == "GREY" then
          UI.buttons[i]:SetAlpha(0.4)  -- Grey appearance (original behavior)
          UI.buttons[i]:EnableMouse(false)
          UI.buttons[i]:Show()
        else  -- ALWAYS
          UI.buttons[i]:SetAlpha(1.0)  -- Full visibility
          UI.buttons[i]:EnableMouse(true)  -- Allow clicks
          UI.buttons[i]:Show()
        end
      else
        -- Available slot - always full visibility and clickable
        UI.buttons[i]:SetAlpha(1.0)
        UI.buttons[i]:EnableMouse(true)
        UI.buttons[i]:Show()
      end
    end
  end

  -- Hide any buttons beyond configured button count
  for i = #SLOT_ORDER + 1, #UI.buttons do
    if UI.buttons[i] then
      UI.buttons[i]:Hide()
      UI.Actions:Clear(UI.buttons[i])
    end
  end
end

