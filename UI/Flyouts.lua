-- UI/Flyouts.lua
-- Flyouts: direction UP, max default 6.
-- Buttons are secure; show/hide is handled out of combat.
-- Keeps flyout open while hovering child flyout buttons.

local DB = DynamicBar
DB.UI = DB.UI or {}
DB.UI.Flyouts = DB.UI.Flyouts or {}
local Flyouts = DB.UI.Flyouts

Flyouts.MAX_DEFAULT = 6
Flyouts.SPACING = 0
Flyouts.HIDE_DELAY = 0.05

-- Internal: ensure a flyout container exists for a given anchor button
function Flyouts:_EnsureContainer(anchorBtn)
  if anchorBtn._dynFlyout then return anchorBtn._dynFlyout end

  local f = CreateFrame("Frame", nil, UIParent)
  f:Hide()
  f:SetFrameStrata(anchorBtn:GetFrameStrata() or "DIALOG")
  f:SetFrameLevel((anchorBtn:GetFrameLevel() or 100) + 20)
  f:EnableMouse(true)

  f._anchor = anchorBtn
  f._buttons = {}
  f._count = 0
  f._wantHide = false
  f._hideTimer = nil
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

-- Internal: position flyout buttons upward
function Flyouts:_LayoutUp(flyoutFrame, buttonCount, buttonSize)
  local anchor = flyoutFrame._anchor

  flyoutFrame:ClearAllPoints()
  flyoutFrame:SetPoint("BOTTOM", anchor, "TOP", 0, Flyouts.SPACING)
  flyoutFrame:SetSize(
    buttonSize,
    (buttonSize * buttonCount) + (Flyouts.SPACING * (buttonCount - 1))
  )

  for i = 1, buttonCount do
    local btn = flyoutFrame._buttons[i]
    btn:ClearAllPoints()
    if i == 1 then
      btn:SetPoint("BOTTOM", flyoutFrame, "BOTTOM", 0, 0)
    else
      btn:SetPoint("BOTTOM", flyoutFrame._buttons[i - 1], "TOP", 0, Flyouts.SPACING)
    end
  end
end

-- Internal: helper show/hide
function Flyouts:_Show(flyoutFrame)
  if InCombatLockdown() then return end
  if flyoutFrame._count and flyoutFrame._count > 0 then
    local a = flyoutFrame._anchor
    flyoutFrame:SetFrameStrata(a:GetFrameStrata() or "DIALOG")
    flyoutFrame:SetFrameLevel((a:GetFrameLevel() or 100) + 20)
    flyoutFrame:Show()
  end
end

function Flyouts:_HideLater(flyoutFrame)
  flyoutFrame._wantHide = true
  if flyoutFrame._hideTimer then return end

  flyoutFrame._hideTimer = true
  C_Timer.After(Flyouts.HIDE_DELAY, function()
    flyoutFrame._hideTimer = nil
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

  local flyout = self:_EnsureContainer(anchorBtn)
  self:_BindHover(anchorBtn, flyout)

  -- Combat-safe: cannot modify flyouts during combat
  if InCombatLockdown() then
    -- Just mark as wanting to hide, don't actually hide (protected in combat)
    flyout._wantHide = true
    return
  end

  itemIDs = itemIDs or {}
  maxButtons = maxButtons or self.MAX_DEFAULT

  local count = math.min(#itemIDs, maxButtons)
  flyout._count = count

  if count == 0 then
    flyout:Hide()
    return
  end

  self:_EnsureButtons(flyout, count, buttonFactory, buttonSize)
  self:_LayoutUp(flyout, count, buttonSize)

  -- IMPORTANT: assign each flyout button (this is what makes icons/actions appear)
  for i = 1, count do
    local btn = flyout._buttons[i]
    assignFn(btn, itemIDs[i])
    btn:Show()
  end

  -- Hide any extra pre-created buttons
  if flyout._buttons then
    for i = count + 1, #flyout._buttons do
      flyout._buttons[i]:Hide()
    end
  end

  -- Keep flyout open while hovering flyout buttons.
  -- Parent frame OnEnter doesn't always fire when entering child buttons.
  for i = 1, count do
    local btn = flyout._buttons[i]
    if not btn._dynFlyoutHoverBound then
      btn._dynFlyoutHoverBound = true

      btn:HookScript("OnEnter", function()
        flyout._wantHide = false
        self:_Show(flyout)
      end)

      btn:HookScript("OnLeave", function()
        self:_HideLater(flyout)
      end)
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

-- Hide all flyouts immediately, even during combat (flyout containers are non-secure frames)
function Flyouts:HideAllImmediate(UI)
  if not UI or not UI.buttons then return end
  for i = 1, #UI.buttons do
    local b = UI.buttons[i]
    if b and b._dynFlyout then
      -- Flyout container is a regular Frame (not secure), safe to hide in combat
      b._dynFlyout:Hide()
      b._dynFlyout._wantHide = false  -- Clear pending hide requests
      b._dynFlyout._combatHideScheduled = false  -- Cancel any scheduled cleanup
    end
  end
end
