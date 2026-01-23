-- UI/UI.lua
local DB = DynamicBar
DB.UI = DB.UI or {}
local UI = DB.UI
local L = LibStub("AceLocale-3.0"):GetLocale("DynamicBar")

UI.buttons = UI.buttons or {}

local BAR_NAME = "DynamicBarMain"
local BUTTON_SIZE = 36

-- Get bar configuration from AceDB (not global DynamicBarDB)
function UI:GetBarConfig()
  return DB.db and DB.db.profile and DB.db.profile.bar
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
-- Slot definitions keyed by name for reordering support
local SLOT_DEFS = {
  HEALTHSTONE = { key = "HEALTHSTONE", resolver = "ResolveHealthstone", flyoutField = "_healthstoneFlyout", modes = {"battle", "prep"}, name = "Healthstone" },
  HEALTH_POT  = { key = "HEALTH_POT",  resolver = "ResolveHealthPotion", flyoutField = "_healthPotionFlyout", modes = {"battle", "prep"}, name = "Health Potion" },
  MANA_POT    = { key = "MANA_POT",    resolver = "ResolveManaPotion", flyoutField = "_manaPotionFlyout", modes = {"battle", "prep"}, name = "Mana Potion" },
  REJUV_POT   = { key = "REJUV_POT",   resolver = "ResolveRejuvenationPotion", flyoutField = "_rejuvenationPotionFlyout", modes = {"battle", "prep"}, name = "Rejuv Potion" },
  BANDAGE     = { key = "BANDAGE",     resolver = "ResolveBandage", flyoutField = "_bandageFlyout", modes = {"battle", "prep"}, name = "Bandage" },
  BATTLE_ELIX = { key = "BATTLE_ELIX", resolver = "ResolveBattleElixir", flyoutField = "_battleElixirFlyout", modes = {"prep"}, name = "Battle Elixir" },
  GUARD_ELIX  = { key = "GUARD_ELIX",  resolver = "ResolveGuardianElixir", flyoutField = "_guardianElixirFlyout", modes = {"prep"}, name = "Guardian Elixir" },
  FLASK       = { key = "FLASK",       resolver = "ResolveFlask", flyoutField = "_flaskFlyout", modes = {"prep"}, name = "Flask" },
  FOOD_BUFF   = { key = "FOOD_BUFF",   resolver = "ResolveFoodBuff", flyoutField = "_foodBuffFlyout", modes = {"prep"}, name = "Food (Buff)" },
  FOOD_OTHER  = { key = "FOOD_OTHER",  resolver = "ResolveFoodNonBuff", flyoutField = "_foodNonBuffFlyout", modes = {"prep"}, name = "Food (Other)" },
  DRINK       = { key = "DRINK",       resolver = "ResolveDrink", flyoutField = "_drinkFlyout", modes = {"prep"}, name = "Drink" },
  HEARTH      = { key = "HEARTH",      resolver = "ResolveHearth", flyoutField = "_hearthFlyout", modes = {"battle", "prep"}, name = "Hearthstone" },
}

-- Default slot order (keys)
local DEFAULT_SLOT_ORDER = {
  "HEALTHSTONE", "HEALTH_POT", "MANA_POT", "REJUV_POT", "BANDAGE",
  "BATTLE_ELIX", "GUARD_ELIX", "FLASK", "FOOD_BUFF", "FOOD_OTHER", "DRINK",
  "HEARTH",
}

-- Export for Config.lua
UI.SLOT_DEFS = SLOT_DEFS
UI.DEFAULT_SLOT_ORDER = DEFAULT_SLOT_ORDER

-- Build ordered slot array from profile or default
local function GetSlotOrder()
  local cfg = DB.db and DB.db.profile and DB.db.profile.bar
  local customOrder = cfg and cfg.slotOrder

  -- Use custom order if defined and valid
  if customOrder and type(customOrder) == "table" and #customOrder > 0 then
    local result = {}
    for _, key in ipairs(customOrder) do
      if SLOT_DEFS[key] then
        result[#result + 1] = SLOT_DEFS[key]
      end
    end
    -- If we got valid slots, use them
    if #result > 0 then return result end
  end

  -- Default order
  local result = {}
  for _, key in ipairs(DEFAULT_SLOT_ORDER) do
    result[#result + 1] = SLOT_DEFS[key]
  end
  return result
end

-- SLOT_ORDER is computed dynamically per Rebuild() call via GetSlotOrder()

local function AssignResolverSlot(slot)
  local btn = UI.buttons[slot.idx]
  if not btn then return nil end
  if InCombatLockdown() then return nil end

  local resolver = DB.Data and DB.Data.Resolver
  if not resolver then return nil end

  local fn = resolver[slot.resolver]
  if type(fn) ~= "function" then return nil end

  local itemID, flyout = fn(resolver)
  if not itemID then
    UI[slot.flyoutField] = {}
    return nil
  end

  UI.Actions:AssignMacro(btn, "/use item:" .. itemID, GetItemTex(itemID), itemID)
  UI[slot.flyoutField] = flyout or {}
  return itemID
end

local function ApplySlotFlyout(slot)
  local btn = UI.buttons[slot.idx]
  if not btn then return end
  if InCombatLockdown() then return end

  local list = UI[slot.flyoutField] or {}
  if #list <= 1 then
    if btn._dynFlyout then
      -- Clear all flyout buttons before hiding (prevents stale items)
      if btn._dynFlyout._buttons then
        for i = 1, #btn._dynFlyout._buttons do
          UI.Actions:Clear(btn._dynFlyout._buttons[i])
        end
      end
      btn._dynFlyout._count = 0  -- Reset count so hover won't re-show the flyout
      btn._dynFlyout:Hide()
    end
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
function UI:UpdateLockState(silent)
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
    self.bar._lockOverlay = overlay
  end

  if locked then
    self.bar:EnableMouse(false)
    if self.bar._lockOverlay then
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
      local n = cfg.buttons or 12
      for i = 1, n do
        if self.buttons[i] then
          self.buttons[i]:Show()
          self.buttons[i]:SetAlpha(0.5)  -- Dimmed to indicate positioning mode
        end
      end
    end

    if self.bar._lockOverlay then
      -- Always show overlay for dragging functionality
      self.bar._lockOverlay:Show()

      -- Get child elements (bg texture is first child, label is fontstring)
      local children = { self.bar._lockOverlay:GetChildren() }
      local regions = { self.bar._lockOverlay:GetRegions() }

      if DB.db.profile._setupComplete then
        -- Subsequent unlocks: dim the background, hide text/button
        for _, region in ipairs(regions) do
          if region:GetObjectType() == "Texture" then
            region:SetVertexColor(0, 1, 0, 0.15)  -- Very subtle green
          elseif region:GetObjectType() == "FontString" then
            region:Hide()  -- Hide "DRAG ME" text
          end
        end
        for _, child in ipairs(children) do
          child:Hide()  -- Hide "Save & Lock" button
        end
      else
        -- First-time setup: show full overlay
        for _, region in ipairs(regions) do
          if region:GetObjectType() == "Texture" then
            region:SetVertexColor(0, 1, 0, 0.4)  -- Bright green
          elseif region:GetObjectType() == "FontString" then
            region:Show()  -- Show "DRAG ME" text
          end
        end
        for _, child in ipairs(children) do
          child:Show()  -- Show "Save & Lock" button
        end
      end
    end
    if not silent then
      DB:Print("|cff00ff00" .. L["Bar UNLOCKED - You can now drag the bar!"] .. "|r")
    end
  end
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
  local DB = DynamicBar
  if not DB.db or not DB.db.profile or not DB.db.profile.enabled then
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
  UI:UpdateLockState(true)  -- Update lock/unlock state (silent - no chat messages during rebuild)
  UI.bar:Show()

  local cfg = UI:GetBarConfig()
  if not cfg then
    DB:Print("Failed to get bar configuration")
    return
  end

  local currentMode = GetCurrentMode()
  local n = cfg.buttons or 10
  local displayMode = cfg.buttonDisplayMode or "SMART"
  local visMode = cfg.visibilityMode or "FADE"

  -- Get current slot order (may be customized by user)
  local SLOT_ORDER = GetSlotOrder()

  -- Clear all currently assigned buttons
  for i = 1, n do
    if UI.buttons[i] then
      UI.Actions:Clear(UI.buttons[i])
    end
  end

  -- Helper: Apply visibility mode for unavailable slots
  local function ApplyVisibilityMode(btn, validForMode)
    if not validForMode then
      -- Unavailable slot - apply user's chosen visibility mode
      if visMode == "FADE" then
        btn:SetAlpha(0.3)  -- Fade to 30%
        btn:EnableMouse(false)
        btn:Show()  -- Ensure visible (might be hidden from previous mode)
      elseif visMode == "HIDE" then
        btn:Hide()  -- Completely hidden
        btn:SetAlpha(1.0)  -- Reset alpha for when it shows again
        btn:EnableMouse(false)
      elseif visMode == "GREY" then
        btn:SetAlpha(0.4)  -- Grey appearance (original behavior)
        btn:EnableMouse(false)
        btn:Show()
      else  -- ALWAYS
        btn:SetAlpha(1.0)  -- Full visibility
        btn:EnableMouse(true)  -- Allow clicks
        btn:Show()
      end
    else
      -- Available slot - always full visibility and clickable
      btn:SetAlpha(1.0)
      btn:EnableMouse(true)
      btn:Show()
    end
  end

  -- =========================================================================
  -- DYNAMIC MODE: Collapse empty slots (breaks keybinds - button positions shift)
  -- =========================================================================
  if displayMode == "DYNAMIC" then
    local btnIdx = 1
    for _, slot in ipairs(SLOT_ORDER) do
      if btnIdx > n then break end

      -- Check if slot is valid for current mode
      local validForMode = false
      for _, mode in ipairs(slot.modes or {"prep"}) do
        if mode == currentMode then
          validForMode = true
          break
        end
      end

      -- CRITICAL: Skip prep-only slots entirely during combat
      -- This prevents macros from being assigned to slots that shouldn't be usable
      -- Contract requirement: prep-only items must NOT be fireable via keybind in combat
      if not validForMode then
        slot.idx = nil
        -- Don't assign anything - slot is completely skipped in combat
      else
        -- Assign slot index and try to resolve item
        slot.idx = btnIdx
        local itemID = AssignResolverSlot(slot)

        if itemID then
          -- Item found - assign button and increment index
          ApplySlotFlyout(slot)
          ApplyVisibilityMode(UI.buttons[btnIdx], validForMode)
          btnIdx = btnIdx + 1
        else
          -- No item - don't increment btnIdx, slot is skipped
          slot.idx = nil
        end
      end
    end

    -- Hide and clear unused buttons
    for i = btnIdx, n do
      if UI.buttons[i] then
        UI.buttons[i]:Hide()
        UI.Actions:Clear(UI.buttons[i])
      end
    end

  -- =========================================================================
  -- SMART MODE: Hide empty buttons but reserve space (stable keybinds)
  -- =========================================================================
  elseif displayMode == "SMART" then
    for i, slot in ipairs(SLOT_ORDER) do
      if i > n then break end

      slot.idx = i

      -- Check if slot is valid for current mode
      local validForMode = false
      for _, mode in ipairs(slot.modes or {"prep"}) do
        if mode == currentMode then
          validForMode = true
          break
        end
      end

      -- CRITICAL: Skip prep-only slots entirely during combat
      -- This prevents macros from being assigned to slots that shouldn't be usable
      -- Contract requirement: prep-only items must NOT be fireable via keybind in combat
      if not validForMode then
        -- Clear any existing macro and hide - NO macro assignment
        UI.Actions:Clear(UI.buttons[i])
        UI.buttons[i]:Hide()
      else
        -- Assign slot and check if item exists
        local itemID = AssignResolverSlot(slot)

        if not itemID then
          -- No item - hide button but keep position reserved
          UI.buttons[i]:Hide()
          UI.Actions:Clear(UI.buttons[i])
        else
          -- Item found - apply normal visibility mode
          ApplySlotFlyout(slot)
          ApplyVisibilityMode(UI.buttons[i], validForMode)
        end
      end
    end

    -- Hide buttons beyond SLOT_ORDER (no categories defined for these slots)
    for i = #SLOT_ORDER + 1, n do
      if UI.buttons[i] then
        UI.buttons[i]:Hide()
        UI.Actions:Clear(UI.buttons[i])
      end
    end

    -- Hide buttons beyond configured count
    for i = n + 1, #UI.buttons do
      if UI.buttons[i] then
        UI.buttons[i]:Hide()
      end
    end

  -- =========================================================================
  -- STATIC MODE: Always show all slots (current/legacy behavior)
  -- =========================================================================
  else  -- STATIC
    for i, slot in ipairs(SLOT_ORDER) do
      if i > n then break end

      slot.idx = i

      -- Check if slot is valid for current mode
      local validForMode = false
      for _, mode in ipairs(slot.modes or {"prep"}) do
        if mode == currentMode then
          validForMode = true
          break
        end
      end

      -- CRITICAL: Skip prep-only slots entirely during combat
      -- This prevents macros from being assigned to slots that shouldn't be usable
      -- Contract requirement: prep-only items must NOT be fireable via keybind in combat
      if not validForMode then
        -- Clear any existing macro - NO macro assignment for prep-only in combat
        UI.Actions:Clear(UI.buttons[i])
        if UI.buttons[i]._dynFlyout then UI.buttons[i]._dynFlyout:Hide() end
        -- Apply visibility (fade/hide/grey) - button has no action
        ApplyVisibilityMode(UI.buttons[i], false)
      else
        -- Assign item regardless of whether it exists
        local itemID = AssignResolverSlot(slot)
        if itemID then
          ApplySlotFlyout(slot)
        else
          -- No item - clear button but keep visible (STATIC mode shows empty slots)
          UI.Actions:Clear(UI.buttons[i])
          if UI.buttons[i]._dynFlyout then UI.buttons[i]._dynFlyout:Hide() end
        end

        -- Always show button (even if empty)
        ApplyVisibilityMode(UI.buttons[i], validForMode)
      end
    end

    -- Show empty placeholder buttons for slots beyond SLOT_ORDER (up to configured count)
    for i = #SLOT_ORDER + 1, n do
      if UI.buttons[i] then
        UI.Actions:Clear(UI.buttons[i])
        UI.buttons[i]:SetAlpha(1.0)
        UI.buttons[i]:EnableMouse(false)  -- No item, so not clickable
        UI.buttons[i]:Show()  -- Show as empty placeholder
      end
    end

    -- Hide buttons beyond configured count
    for i = n + 1, #UI.buttons do
      if UI.buttons[i] then
        UI.buttons[i]:Hide()
        UI.Actions:Clear(UI.buttons[i])
      end
    end
  end
end

