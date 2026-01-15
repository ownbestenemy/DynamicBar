-- UI/Buttons.lua
local DB = DynamicBar
DB.UI = DB.UI or {}
DB.UI.Buttons = DB.UI.Buttons or {}
local Buttons = DB.UI.Buttons

function Buttons:RegisterSecureClicks(btn)
  btn:RegisterForClicks(
    "LeftButtonDown", "LeftButtonUp",
    "RightButtonDown", "RightButtonUp"
  )
end

function Buttons:CreateSecureButton(name, parent, size)
  local btn = CreateFrame("Button", name, parent, "SecureActionButtonTemplate")
  btn:SetSize(size, size)

  btn:EnableMouse(true)
  self:RegisterSecureClicks(btn)

  -- Background
  local bg = btn:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(btn)
  bg:SetTexture("Interface\\Buttons\\UI-Quickslot2")

  -- Icon
  local icon = btn:CreateTexture(nil, "ARTWORK")
  icon:SetPoint("TOPLEFT", 2, -2)
  icon:SetPoint("BOTTOMRIGHT", -2, 2)
  btn._dynIcon = icon

  -- Highlight
  local hl = btn:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints(btn)
  hl:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
  hl:SetBlendMode("ADD")

  return btn
end
