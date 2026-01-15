-- UI/UI.lua
local DB = DynamicBar
DB.UI = DB.UI or {}
local UI = DB.UI

UI.buttons = UI.buttons or {}

local BAR_NAME = "DynamicBarMain"
local BUTTON_SIZE = 36

local function GetCfg()
  return DynamicBarDB and DynamicBarDB.profile and DynamicBarDB.profile.bar
end

local function EnsureBar()
  if UI.bar then return UI.bar end

  local cfg = GetCfg()
  local bar = CreateFrame("Frame", BAR_NAME, UIParent)
  bar:SetScale(cfg.scale or 1.0)
  bar:SetPoint(cfg.point or "CENTER", UIParent, cfg.relPoint or "CENTER", cfg.x or 0, cfg.y or 0)

  bar:EnableMouse(false)
  bar:SetClampedToScreen(true)
  bar:SetFrameStrata("DIALOG")
  bar:SetFrameLevel(100)

  UI.bar = bar
  return bar
end

local function LayoutBar()
  local cfg = GetCfg()
  local buttons = cfg.buttons or 8
  local spacing = cfg.spacing or 4

  UI.bar:SetSize((BUTTON_SIZE * buttons) + (spacing * (buttons - 1)), BUTTON_SIZE)

  for i = 1, buttons do
    local btn = UI.buttons[i]
    if not btn then break end

    btn:ClearAllPoints()
    if i == 1 then
      btn:SetPoint("LEFT", UI.bar, "LEFT", 0, 0)
    else
      btn:SetPoint("LEFT", UI.buttons[i - 1], "RIGHT", spacing, 0)
    end
  end
end

local function EnsureButtons()
  local cfg = GetCfg()
  local buttons = cfg.buttons or 8

  for i = 1, buttons do
    if not UI.buttons[i] then
      local name = BAR_NAME .. "Button" .. i
      local btn = UI.Buttons:CreateSecureButton(name, UI.bar, BUTTON_SIZE)
      btn:SetFrameStrata("DIALOG")
      btn:SetFrameLevel(110 + i)
      UI.buttons[i] = btn
    end
  end
end

local function AssignHearthstone()
  if not UI.buttons[1] then return end
  if InCombatLockdown() then return end

  local _, _, _, _, _, _, _, _, _, tex = GetItemInfo(6948)
  if not tex then
    if C_Timer and C_Timer.After then
      C_Timer.After(0.5, function()
        if not InCombatLockdown() then AssignHearthstone() end
      end)
    end
    return
  end

  UI.Actions:AssignMacro(UI.buttons[1], "/use item:6948", tex, 6948)
end

function UI:Rebuild()
  if not DynamicBarDB.profile.enabled then
    if self.bar then self.bar:Hide() end
    return
  end

  EnsureBar()
  EnsureButtons()
  LayoutBar()
  UI.bar:Show()

  local cfg = GetCfg()
  local n = cfg.buttons or 8
  for i = 1, n do
    UI.Actions:Clear(UI.buttons[i])
  end

  AssignHearthstone()
end
