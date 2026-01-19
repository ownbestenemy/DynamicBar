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
  if tooltipItemID then
  UpdateCountText(btn, tooltipItemID)
else
  if btn._dynCountText then btn._dynCountText:Hide() end
end

  if tooltipItemID then self:SetTooltipItem(btn, tooltipItemID) end
end
