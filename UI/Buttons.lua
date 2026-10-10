-- UI/Buttons.lua
local DB = DynamicBar
DB.UI = DB.UI or {}
DB.UI.Buttons = DB.UI.Buttons or {}
local Buttons = DB.UI.Buttons

-- Combat changes run in Blizzard's restricted environment. Item assignment and
-- button positions remain frozen; only prep-slot actions and visibility change.
local COMBAT_STATE = [[
  local unavailable = newstate == "battle" and self:GetAttribute("prep-only")
  if self:GetAttribute("assigned") and not unavailable then
    self:SetAttribute("type1", "macro")
  else
    self:SetAttribute("type1", nil)
  end

  local shown = self:GetAttribute("prep-shown")
  local alpha = self:GetAttribute("prep-alpha") or 1
  local clickable = self:GetAttribute("prep-clickable")
  if unavailable then
    local mode = self:GetAttribute("combat-visibility")
    clickable = false
    if mode == "HIDE" then
      shown = false
    elseif mode == "FADE" then
      alpha = 0.3
    elseif mode == "GREY" then
      alpha = 0.4
    end
  end
  self:SetAlpha(alpha)
  self:EnableMouse(clickable)
  if shown then self:Show() else self:Hide() end
]]

function Buttons:ConfigureCombat(btn, prepOnly, visibilityMode)
  if InCombatLockdown() then return end
  btn:SetAttribute("prep-only", prepOnly or false)
  btn:SetAttribute("combat-visibility", visibilityMode)
  btn:SetAttribute("prep-shown", btn:IsShown())
  btn:SetAttribute("prep-alpha", btn:GetAlpha())
  btn:SetAttribute("prep-clickable", btn:IsMouseEnabled())
  btn:SetAttribute("_onstate-combat", COMBAT_STATE)
  RegisterStateDriver(btn, "combat", "[combat] battle; prep")
  -- Reapply when settings change without a combat-state transition.
  btn:Execute('local newstate = self:GetAttribute("state-combat") or "prep"\n' .. COMBAT_STATE)
end

function Buttons:RegisterSecureClicks(btn)
  btn:RegisterForClicks(
    "LeftButtonDown", "LeftButtonUp",
    "RightButtonDown", "RightButtonUp"
  )
end

function Buttons:CreateSecureButton(name, parent, size)
  local btn = CreateFrame("Button", name, parent, "SecureActionButtonTemplate,SecureHandlerStateTemplate")
  btn:SetSize(size, size)

  btn:EnableMouse(true)
  self:RegisterSecureClicks(btn)

  -- Icon (created first, preserved by skins)
  local icon = btn:CreateTexture(nil, "ARTWORK")
  icon:SetPoint("TOPLEFT", 2, -2)
  icon:SetPoint("BOTTOMRIGHT", -2, 2)
  btn._dynIcon = icon
  btn.icon = icon

  -- Apply skin (creates background, highlight, pushed, disabled textures)
  if DB.UI.Skins then
    DB.UI.Skins:ApplyButtonSkin(btn)
  end

  return btn
end
