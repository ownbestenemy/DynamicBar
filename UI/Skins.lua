-- UI/Skins.lua
-- Button skinning system with auto-detection for ElvUI, Masque, Dominos, Bartender4
local DB = DynamicBar
DB.UI = DB.UI or {}
DB.UI.Skins = DB.UI.Skins or {}
local Skins = DB.UI.Skins

-- Cache global function (TBC/Vanilla compatibility)
local IsAddOnLoaded = IsAddOnLoaded or (C_AddOns and C_AddOns.IsAddOnLoaded)

-- Skin detection state
Skins.skinSource = nil       -- "ElvUI", "Masque", or "Blizzard"
Skins.applyElvUI = false     -- ElvUI S:HandleButton available
Skins.masqueGroup = nil      -- Masque group instance
Skins.initialized = false    -- Initialize only once

--
-- Initialize: Detect available skinning systems
--
function Skins:Initialize()
  if self.initialized then return end
  self.initialized = true

  -- Priority 1: ElvUI (most invasive, takes precedence)
  if self:DetectElvUI() then
    self.skinSource = "ElvUI"
    DB:DPrint("Button skin: ElvUI detected")
    return
  end

  -- Priority 2: Masque (covers Dominos, Bartender4, custom skins)
  if self:DetectMasque() then
    self.skinSource = "Masque"
    DB:DPrint("Button skin: Masque detected")
    return
  end

  -- Priority 3: Enhanced Blizzard default
  self.skinSource = "Blizzard"
  DB:DPrint("Button skin: Blizzard (default)")
end

--
-- Detect ElvUI
--
function Skins:DetectElvUI()
  if not IsAddOnLoaded or not IsAddOnLoaded("ElvUI") then return false end

  local E = ElvUI and ElvUI[1]
  if not E then return false end

  local S = E:GetModule("Skins", true)
  if not S or not S.HandleButton then return false end

  self.applyElvUI = true
  return true
end

--
-- Detect Masque (LibMasque-1.0)
--
function Skins:DetectMasque()
  local Masque = LibStub and LibStub("Masque", true)
  if not Masque then return false end

  -- Create DynamicBar button group
  self.masqueGroup = Masque:Group("DynamicBar")
  return true
end

--
-- Get active skin source name
--
function Skins:GetActiveSkinName()
  return self.skinSource or "Unknown"
end

--
-- Get ElvUI action bar settings (spacing, padding, size)
--
function Skins:GetElvUIBarSettings()
  if not IsAddOnLoaded or not IsAddOnLoaded("ElvUI") then return nil end

  local E = ElvUI and ElvUI[1]
  if not E or not E.db or not E.db.actionbar then return nil end

  -- Use bar1 settings as reference (most common)
  local bar1 = E.db.actionbar.bar1
  if not bar1 then return nil end

  return {
    buttonsize = bar1.buttonsize or 32,
    buttonspacing = bar1.buttonspacing or 2,
    backdropSpacing = bar1.backdropSpacing or 2,
  }
end

--
-- Apply skin to a button
--
function Skins:ApplyButtonSkin(button)
  if not button then return end

  -- Create button texture regions if needed
  self:EnsureButtonRegions(button)

  -- Apply skin based on detected source
  if self.skinSource == "ElvUI" then
    self:ApplyElvUISkin(button)
  elseif self.skinSource == "Masque" then
    self:ApplyMasqueSkin(button)
  else
    self:ApplyBlizzardSkin(button)
  end
end

--
-- Ensure button has all required texture regions
--
function Skins:EnsureButtonRegions(button)
  -- Normal texture (background/border)
  if not button._dynNormal then
    local normal = button:CreateTexture(nil, "BACKGROUND")
    normal:SetAllPoints(button)
    button._dynNormal = normal
    button:SetNormalTexture(normal)
  end

  -- Highlight texture (hover)
  if not button._dynHighlight then
    local hl = button:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(button)
    hl:SetBlendMode("ADD")
    button._dynHighlight = hl
    button:SetHighlightTexture(hl)
  end

  -- Pushed texture (click state)
  if not button._dynPushed then
    local pushed = button:CreateTexture(nil, "ARTWORK")
    pushed:SetAllPoints(button)
    button._dynPushed = pushed
    button:SetPushedTexture(pushed)
  end

  -- Disabled texture (disabled state)
  if not button._dynDisabled then
    local disabled = button:CreateTexture(nil, "BACKGROUND", nil, 1)
    disabled:SetAllPoints(button)
    button._dynDisabled = disabled
    button:SetDisabledTexture(disabled)
  end

  -- Icon texture should already exist from Buttons.lua
  -- We preserve existing _dynIcon and don't override it

  -- Create cooldown frame if it doesn't exist (standard for action buttons)
  if not button._dynCooldown then
    local cd = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    cd:SetAllPoints(button)
    cd:SetDrawEdge(true)
    button._dynCooldown = cd
  end
end

--
-- Apply ElvUI skin
--
function Skins:ApplyElvUISkin(button)
  if not self.applyElvUI then return end

  local E = ElvUI[1]
  local S = E:GetModule("Skins", true)
  if not S or not S.HandleButton then return end

  -- Let ElvUI handle all button styling
  S:HandleButton(button)
end

--
-- Apply Masque skin
--
function Skins:ApplyMasqueSkin(button)
  if not self.masqueGroup then return end

  -- Register button with Masque
  -- Masque will automatically apply the active skin
  self.masqueGroup:AddButton(button, {
    Normal = button._dynNormal,
    Icon = button._dynIcon,
    Highlight = button._dynHighlight,
    Pushed = button._dynPushed,
    Disabled = button._dynDisabled,
  })
end

--
-- Apply enhanced Blizzard default skin
--
function Skins:ApplyBlizzardSkin(button)
  if not button._dynNormal then return end

  -- Normal (background) - use proper action button texture
  button._dynNormal:SetTexture("Interface\\Buttons\\UI-Quickslot2")
  button._dynNormal:SetTexCoord(0, 0, 0, 1, 1, 0, 1, 1)  -- Standard tex coords
  button._dynNormal:ClearAllPoints()
  button._dynNormal:SetAllPoints(button)

  -- Highlight (hover) - bright white overlay
  if button._dynHighlight then
    button._dynHighlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    button._dynHighlight:SetTexCoord(0, 1, 0, 1)
    button._dynHighlight:ClearAllPoints()
    button._dynHighlight:SetAllPoints(button)
  end

  -- Pushed (click) - darker overlay when clicking
  if button._dynPushed then
    button._dynPushed:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    button._dynPushed:SetTexCoord(0, 1, 0, 1)
    button._dynPushed:ClearAllPoints()
    button._dynPushed:SetAllPoints(button)
  end

  -- Disabled - grayed out look
  if button._dynDisabled then
    button._dynDisabled:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    button._dynDisabled:SetTexCoord(0, 1, 0, 1)
    button._dynDisabled:SetVertexColor(0.5, 0.5, 0.5, 1)
    button._dynDisabled:ClearAllPoints()
    button._dynDisabled:SetAllPoints(button)
  end

  -- Ensure icon stays on top
  if button._dynIcon then
    button._dynIcon:SetDrawLayer("ARTWORK", 1)
  end
end
