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
