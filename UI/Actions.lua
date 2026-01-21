-- UI/Actions.lua
local DB = DynamicBar
DB.UI = DB.UI or {}
DB.UI.Actions = DB.UI.Actions or {}
local Actions = DB.UI.Actions

local function EnsureCountText(btn)
  local fs = btn._dynCountText
  if fs then return fs end

  fs = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
  fs:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)
  fs:SetJustifyH("RIGHT")
  fs:Hide()

  btn._dynCountText = fs
  return fs
end

-- Ensure cooldown frame exists on button
local function EnsureCooldown(btn)
  if btn._dynCooldown then return btn._dynCooldown end

  local cd = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
  cd:SetAllPoints(btn)
  cd:SetDrawEdge(true)
  cd:SetDrawBling(true)
  cd:SetDrawSwipe(true)

  btn._dynCooldown = cd
  return cd
end

-- Update cooldown display for an item
local function UpdateCooldown(btn, itemID)
  if not itemID then return end

  local cd = EnsureCooldown(btn)
  local start, duration, enable = GetItemCooldown(itemID)

  if start and duration and duration > 0 and enable == 1 then
    cd:SetCooldown(start, duration)
    cd:Show()
  else
    cd:Hide()
  end
end

local function UpdateCountText(btn, itemID)
  local fs = EnsureCountText(btn)
  local cache = DynamicBar and DynamicBar.Data and DynamicBar.Data.BagCache
  local count = (cache and itemID and cache:GetCount(itemID)) or 0

  if count and count > 1 then
    fs:SetText(count)
    fs:Show()
  else
    fs:SetText("")
    fs:Hide()
  end
end

function Actions:Clear(btn)
  if InCombatLockdown() then return end

  btn:SetAttribute("type", nil)
  btn:SetAttribute("item", nil)
  btn:SetAttribute("spell", nil)
  btn:SetAttribute("macrotext", nil)

  btn:SetAttribute("type1", nil)
  btn:SetAttribute("item1", nil)
  btn:SetAttribute("spell1", nil)
  btn:SetAttribute("macrotext1", nil)

  btn:SetAttribute("type2", nil)
  btn:SetAttribute("macrotext2", nil)

  -- Clear tooltip item so hidden buttons don't show tooltips on hover
  btn._dynTooltipItemID = nil

  -- DO NOT wipe OnEnter/OnLeave here.
  -- Flyouts bind hover behavior; tooltips are set during AssignMacro().
  -- If you nil these, you will intermittently kill flyouts on rebuild.
  if btn._dynCountText then
    btn._dynCountText:SetText("")
    btn._dynCountText:Hide()
  end

  if btn._dynIcon then btn._dynIcon:SetTexture(nil) end
end

function Actions:SetTooltipItem(btn, itemID)
  -- Store itemID on button so we can update it without re-wrapping handlers
  btn._dynTooltipItemID = itemID

  -- Only wrap handlers ONCE per button - check if already bound
  if btn._dynTooltipBound then return end
  btn._dynTooltipBound = true

  -- Preserve whatever OnEnter/OnLeave is already on the button (e.g., Flyouts)
  local prevEnter = btn:GetScript("OnEnter")
  btn:SetScript("OnEnter", function(self, ...)
    if prevEnter then prevEnter(self, ...) end
    if self._dynTooltipItemID then
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetItemByID(self._dynTooltipItemID)
      GameTooltip:Show()
    end
  end)

  local prevLeave = btn:GetScript("OnLeave")
  btn:SetScript("OnLeave", function(self, ...)
    if prevLeave then prevLeave(self, ...) end
    GameTooltip:Hide()
  end)
end



function Actions:AssignMacro(btn, macroText, iconTexture, tooltipItemID)
  if InCombatLockdown() then return end

  -- robust mapping
  btn:SetAttribute("type", "macro")
  btn:SetAttribute("macrotext", macroText)

  btn:SetAttribute("type1", "macro")
  btn:SetAttribute("macrotext1", macroText)

  btn:SetAttribute("type2", "macro")
  btn:SetAttribute("macrotext2", macroText)

    -- Ensure the button has an icon texture we can set.
  local icon = btn._dynIcon or btn.icon
  if not icon then
    icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 2, -2)
    icon:SetPoint("BOTTOMRIGHT", -2, 2)
    btn._dynIcon = icon
    btn.icon = icon
  end

  icon:SetTexture(iconTexture)
  UpdateCountText(btn, tooltipItemID)
  UpdateCooldown(btn, tooltipItemID)

  -- Store itemID for in-combat count checks
  btn._dynItemID = tooltipItemID

  if tooltipItemID then self:SetTooltipItem(btn, tooltipItemID) end
end

-- Update all button cooldowns (called periodically and on events)
function Actions:UpdateAllCooldowns()
  local UI = DB.UI
  if not UI or not UI.buttons then return end

  for _, btn in ipairs(UI.buttons) do
    if btn and btn._dynItemID and btn:IsShown() then
      UpdateCooldown(btn, btn._dynItemID)
    end
  end
end

-- Update button visuals during combat when item count changes
-- Called from BAG_UPDATE - only updates visual state, not secure attributes
function Actions:UpdateInCombat(btn)
  if not btn._dynItemID then return end

  local cache = DynamicBar and DynamicBar.Data and DynamicBar.Data.BagCache
  local count = cache and cache:GetCount(btn._dynItemID) or 0

  -- Update count text (always safe, not a secure attribute)
  UpdateCountText(btn, btn._dynItemID)

  -- If item ran out, grey/fade the button to indicate it's unavailable
  -- The macro still exists but will do nothing when clicked
  if count == 0 then
    btn:SetAlpha(0.3)
    -- Note: Can't call EnableMouse(false) on SecureActionButton in combat
    -- but the macro will simply fail gracefully when item is gone
  end
end
