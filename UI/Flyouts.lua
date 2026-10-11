-- UI/Flyouts.lua
-- Flyouts: direction UP, max default 6 per page; longer lists page with Previous/Next.
-- Buttons are secure; combat hiding is handled by a secure state driver.
-- Keeps flyout open while hovering child flyout buttons.

local DB = DynamicBar
DB.UI = DB.UI or {}
DB.UI.Flyouts = DB.UI.Flyouts or {}
local Flyouts = DB.UI.Flyouts

Flyouts.MAX_DEFAULT = 6
Flyouts.SPACING = 0
Flyouts.HIDE_DELAY = 0.05

-- Direction constants
Flyouts.DIR_UP = "UP"
Flyouts.DIR_DOWN = "DOWN"
Flyouts.DIR_LEFT = "LEFT"
Flyouts.DIR_RIGHT = "RIGHT"

-- Determine optimal flyout direction based on button position and layout mode
-- Returns: "UP", "DOWN", "LEFT", or "RIGHT"
function Flyouts:GetOptimalDirection(anchorBtn, buttonCount, buttonSize)
  if not anchorBtn then return self.DIR_UP end

  -- Get button's screen position (accounting for scale)
  local scale = anchorBtn:GetEffectiveScale()
  local btnLeft, btnBottom, btnWidth, btnHeight = anchorBtn:GetRect()
  if not btnLeft then return self.DIR_UP end

  -- Get screen dimensions
  local screenWidth = GetScreenWidth() * UIParent:GetEffectiveScale()
  local screenHeight = GetScreenHeight() * UIParent:GetEffectiveScale()

  -- Calculate flyout size
  local flyoutLength = (buttonSize * buttonCount) + (self.SPACING * (buttonCount - 1))
  local flyoutLengthScaled = flyoutLength * scale

  -- Get layout mode from config
  local layoutMode = "HORIZONTAL"
  local cfg = DB and DB.UI and DB.UI:GetBarConfig()
  if cfg then
    layoutMode = cfg.layoutMode or "HORIZONTAL"
  end

  -- For VERTICAL layout, prefer horizontal flyout directions
  if layoutMode == "VERTICAL" then
    local spaceRight = screenWidth - (btnLeft + btnWidth) * scale
    local spaceLeft = btnLeft * scale

    -- Check if flyout fits on right side
    if spaceRight >= flyoutLengthScaled then
      return self.DIR_RIGHT
    -- Check if flyout fits on left side
    elseif spaceLeft >= flyoutLengthScaled then
      return self.DIR_LEFT
    -- Default to whichever side has more space
    elseif spaceRight >= spaceLeft then
      return self.DIR_RIGHT
    else
      return self.DIR_LEFT
    end
  end

  -- For HORIZONTAL and GRID layouts, prefer vertical flyout directions
  local spaceAbove = screenHeight - (btnBottom + btnHeight) * scale
  local spaceBelow = btnBottom * scale

  -- Check if flyout fits above
  if spaceAbove >= flyoutLengthScaled then
    return self.DIR_UP
  -- Check if flyout fits below
  elseif spaceBelow >= flyoutLengthScaled then
    return self.DIR_DOWN
  -- Default to whichever side has more space
  elseif spaceAbove >= spaceBelow then
    return self.DIR_UP
  else
    return self.DIR_DOWN
  end
end

-- Per-direction anchoring: the flyout grows away from the anchor button.
-- point/relPoint pin each button to the previous one; dx/dy is the spacing direction.
local LAYOUTS = {
  UP    = { point = "BOTTOM", relPoint = "TOP",    dx = 0,  dy = 1,  vertical = true },
  DOWN  = { point = "TOP",    relPoint = "BOTTOM", dx = 0,  dy = -1, vertical = true },
  RIGHT = { point = "LEFT",   relPoint = "RIGHT",  dx = 1,  dy = 0 },
  LEFT  = { point = "RIGHT",  relPoint = "LEFT",   dx = -1, dy = 0 },
}

-- Position the flyout container and the given frames (item buttons, then the
-- page controls if any) for the given direction (default UP)
function Flyouts:_ApplyLayout(flyoutFrame, frames, buttonSize, direction)
  local L = LAYOUTS[direction] or LAYOUTS.UP
  local gap = Flyouts.SPACING
  local buttonCount = #frames
  local length = (buttonSize * buttonCount) + (gap * (buttonCount - 1))

  flyoutFrame:ClearAllPoints()
  flyoutFrame:SetPoint(L.point, flyoutFrame._anchor, L.relPoint, L.dx * gap, L.dy * gap)
  if L.vertical then
    flyoutFrame:SetSize(buttonSize, length)
  else
    flyoutFrame:SetSize(length, buttonSize)
  end

  for i = 1, buttonCount do
    local btn = frames[i]
    btn:ClearAllPoints()
    if i == 1 then
      btn:SetPoint(L.point, flyoutFrame, L.point, 0, 0)
    else
      btn:SetPoint(L.point, frames[i - 1], L.relPoint, L.dx * gap, L.dy * gap)
    end
  end
end

-- Internal: keep the flyout open while the pointer is over one of its frames
function Flyouts:_KeepOpenOnHover(flyoutFrame, frame)
  frame:HookScript("OnEnter", function()
    flyoutFrame._wantHide = false
    self:_Show(flyoutFrame)
  end)
  frame:HookScript("OnLeave", function()
    self:_HideLater(flyoutFrame)
  end)
end

-- Internal: one button-sized cell holding Previous (left half) and Next (right half).
-- Plain buttons: paging reassigns secure item buttons, so it only runs out of combat.
function Flyouts:_EnsurePager(flyoutFrame, buttonSize)
  local pager = flyoutFrame._pager
  if not pager then
    pager = CreateFrame("Frame", nil, flyoutFrame)
    pager:SetFrameLevel(flyoutFrame:GetFrameLevel() + 1)

    local function MakeArrow(label, delta, tip)
      local b = CreateFrame("Button", nil, pager)
      b:SetNormalFontObject("GameFontNormal")
      b:SetHighlightFontObject("GameFontHighlight")
      b:SetDisabledFontObject("GameFontDisable")
      b:SetText(label)
      b:SetScript("OnClick", function()
        self:_SetPage(flyoutFrame, flyoutFrame._page + delta)
      end)
      b:SetScript("OnEnter", function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
        GameTooltip:SetText(("%s (page %d of %d)"):format(tip, flyoutFrame._page, flyoutFrame._pages))
        GameTooltip:Show()
      end)
      b:SetScript("OnLeave", function() GameTooltip:Hide() end)
      self:_KeepOpenOnHover(flyoutFrame, b)
      return b
    end

    pager._prev = MakeArrow("<", -1, "Previous")
    pager._next = MakeArrow(">", 1, "Next")
    flyoutFrame._pager = pager
  end

  pager:SetSize(buttonSize, buttonSize)
  pager._prev:SetSize(buttonSize / 2, buttonSize)
  pager._prev:SetPoint("LEFT", pager, "LEFT", 0, 0)
  pager._next:SetSize(buttonSize / 2, buttonSize)
  pager._next:SetPoint("RIGHT", pager, "RIGHT", 0, 0)
  return pager
end

-- Internal: show another page of the flyout's items (out of combat only)
function Flyouts:_SetPage(flyoutFrame, page)
  if InCombatLockdown() then return end
  flyoutFrame._page = page
  self:_Render(flyoutFrame)
end

-- Internal: ensure a flyout container exists for a given anchor button
function Flyouts:_EnsureContainer(anchorBtn)
  if anchorBtn._dynFlyout then return anchorBtn._dynFlyout end

  local f = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")
  f:SetAttribute("_onstate-combat", [[
    if newstate == "battle" then self:Hide() end
  ]])
  RegisterStateDriver(f, "combat", "[combat] battle; prep")
  f:Hide()
  f:SetFrameStrata(anchorBtn:GetFrameStrata() or "DIALOG")
  f:SetFrameLevel((anchorBtn:GetFrameLevel() or 100) + 20)
  f:EnableMouse(true)

  f._anchor = anchorBtn
  f._buttons = {}
  f._count = 0
  f._wantHide = false
  f._hideTimer = false
  f._dynBound = false

  anchorBtn._dynFlyout = f
  return f
end

-- Internal: create or fetch flyout buttons
function Flyouts:_EnsureButtons(flyoutFrame, count, buttonFactory, buttonSize)
  flyoutFrame._buttons = flyoutFrame._buttons or {}

  for i = 1, count do
    if not flyoutFrame._buttons[i] then
      local base = flyoutFrame._anchor:GetName() or "DynamicBarBtn"
      local name = base .. "Flyout" .. i
      local btn = buttonFactory(name, flyoutFrame, buttonSize)

      btn:SetFrameStrata(flyoutFrame:GetFrameStrata())
      btn:SetFrameLevel(flyoutFrame:GetFrameLevel() + i)

      flyoutFrame._buttons[i] = btn
    end
  end
end

-- Internal: helper show/hide
function Flyouts:_Show(flyoutFrame)
  if InCombatLockdown() then return end
  if flyoutFrame._count and flyoutFrame._count > 0 then
    -- Frame strata/level already set in _EnsureContainer() - no need to set on every hover
    flyoutFrame:Show()
  end
end

function Flyouts:_HideLater(flyoutFrame)
  flyoutFrame._wantHide = true
  if flyoutFrame._hideTimer then return end

  flyoutFrame._hideTimer = true
  C_Timer.After(Flyouts.HIDE_DELAY, function()
    flyoutFrame._hideTimer = false
    if flyoutFrame._wantHide then
      -- Combat-safe hide: only hide if not in combat
      if not InCombatLockdown() then
        flyoutFrame:Hide()
        flyoutFrame._wantHide = false
      else
        -- Still in combat - retry after combat ends
        -- Don't clear _wantHide so we remember to hide later
        Flyouts:_ScheduleHideAfterCombat(flyoutFrame)
      end
    end
  end)
end

-- Internal: schedule a hide for when combat ends
function Flyouts:_ScheduleHideAfterCombat(flyoutFrame)
  if flyoutFrame._combatHideScheduled then return end
  flyoutFrame._combatHideScheduled = true

  -- Poll for combat end (lightweight check every 0.5s)
  local function checkCombat()
    if not InCombatLockdown() and flyoutFrame._wantHide then
      flyoutFrame:Hide()
      flyoutFrame._wantHide = false
      flyoutFrame._combatHideScheduled = false
    elseif InCombatLockdown() and flyoutFrame._wantHide then
      -- Still in combat, check again soon
      C_Timer.After(0.5, checkCombat)
    else
      -- No longer want to hide, cancel
      flyoutFrame._combatHideScheduled = false
    end
  end

  C_Timer.After(0.5, checkCombat)
end

-- Internal: bind hover handlers to anchor + flyout frame once
function Flyouts:_BindHover(anchorBtn, flyoutFrame)
  if flyoutFrame._dynBound then return end
  flyoutFrame._dynBound = true

  -- Preserve hover access while making the documented right-click safe.
  anchorBtn:HookScript("OnClick", function(_, button, down)
    if button == "RightButton" and not down then
      flyoutFrame._wantHide = false
      self:_Show(flyoutFrame)
    end
  end)

  -- Anchor enter/leave
  local prevEnter = anchorBtn:GetScript("OnEnter")
  anchorBtn:SetScript("OnEnter", function(btn, ...)
    if prevEnter then prevEnter(btn, ...) end
    flyoutFrame._wantHide = false
    self:_Show(flyoutFrame)
  end)

  local prevLeave = anchorBtn:GetScript("OnLeave")
  anchorBtn:SetScript("OnLeave", function(btn, ...)
    if prevLeave then prevLeave(btn, ...) end
    self:_HideLater(flyoutFrame)
  end)

  -- Flyout frame enter/leave (may not fire when entering child buttons, but still useful)
  flyoutFrame:HookScript("OnEnter", function()
    flyoutFrame._wantHide = false
    self:_Show(flyoutFrame)
  end)

  flyoutFrame:HookScript("OnLeave", function()
    self:_HideLater(flyoutFrame)
  end)
end

-- Public: Build/update a flyout for an anchor.
-- itemIDs: list (best -> worst). maxButtons: default 6.
-- buttonFactory: function(name, parent, size) -> secure button
-- assignFn: function(button, itemID) -- MUST assign action+icon
function Flyouts:ApplyItemFlyout(anchorBtn, itemIDs, maxButtons, buttonFactory, buttonSize, assignFn)
  if not anchorBtn then return end
  if InCombatLockdown() then return end

  local flyout = self:_EnsureContainer(anchorBtn)
  self:_BindHover(anchorBtn, flyout)

  flyout._items = itemIDs or {}
  flyout._perPage = maxButtons or self.MAX_DEFAULT
  flyout._factory, flyout._size, flyout._assign = buttonFactory, buttonSize, assignFn
  -- Keep the current page across bag updates (clamped in _Render)
  flyout._page = flyout._page or 1
  self:_Render(flyout)
end

-- Internal: lay out and assign the current page of the flyout's items
function Flyouts:_Render(flyout)
  local itemIDs, perPage = flyout._items, flyout._perPage
  local buttonSize = flyout._size

  local pages = math.max(1, math.ceil(#itemIDs / perPage))
  local page = math.max(1, math.min(flyout._page or 1, pages))
  flyout._page, flyout._pages = page, pages
  local first = (page - 1) * perPage

  local count = math.max(0, math.min(perPage, #itemIDs - first))
  flyout._count = count

  if count == 0 then
    -- Clear all flyout buttons before hiding (prevents stale items)
    local Actions = DB.UI and DB.UI.Actions
    if Actions and flyout._buttons then
      for i = 1, #flyout._buttons do
        Actions:Clear(flyout._buttons[i])
      end
    end
    if flyout._pager then flyout._pager:Hide() end
    flyout:Hide()
    return
  end

  self:_EnsureButtons(flyout, count, flyout._factory, buttonSize)

  local frames = {}
  for i = 1, count do frames[i] = flyout._buttons[i] end

  if pages > 1 then
    local pager = self:_EnsurePager(flyout, buttonSize)
    pager._prev:SetEnabled(page > 1)
    pager._next:SetEnabled(page < pages)
    pager:Show()
    frames[#frames + 1] = pager
  elseif flyout._pager then
    flyout._pager:Hide()
  end

  -- Determine optimal flyout direction based on button position and layout mode
  local direction = self:GetOptimalDirection(flyout._anchor, #frames, buttonSize)
  self:_ApplyLayout(flyout, frames, buttonSize, direction)

  -- IMPORTANT: assign each flyout button (this is what makes icons/actions appear)
  for i = 1, count do
    local btn = flyout._buttons[i]
    flyout._assign(btn, itemIDs[first + i])
    btn:Show()
  end

  -- Hide and clear any extra pre-created buttons (prevents stale items)
  local Actions = DB.UI and DB.UI.Actions
  if flyout._buttons then
    for i = count + 1, #flyout._buttons do
      if Actions then Actions:Clear(flyout._buttons[i]) end
      flyout._buttons[i]:Hide()
    end
  end

  -- Keep flyout open while hovering flyout buttons.
  -- Parent frame OnEnter doesn't always fire when entering child buttons.
  for i = 1, count do
    local btn = flyout._buttons[i]
    if not btn._dynFlyoutHoverBound then
      btn._dynFlyoutHoverBound = true

      btn:HookScript("OnClick", function(_, button, down)
        if button == "LeftButton" and not down and not InCombatLockdown() then
          flyout:Hide()
          flyout._wantHide = false
        end
      end)

      self:_KeepOpenOnHover(flyout, btn)
    end
  end
end

function Flyouts:HideAll(UI)
  if InCombatLockdown() then return end
  if not UI or not UI.buttons then return end
  for i = 1, #UI.buttons do
    local b = UI.buttons[i]
    if b and b._dynFlyout then
      b._dynFlyout:Hide()
    end
  end
end

-- Compatibility entry point: secure state drivers handle combat entry.
function Flyouts:HideAllImmediate(UI)
  self:HideAll(UI)
end
