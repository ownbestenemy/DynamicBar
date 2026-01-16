-- UI/Actions.lua
local DB = DynamicBar
DB.UI = DB.UI or {}
DB.UI.Actions = DB.UI.Actions or {}
local Actions = DB.UI.Actions

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

  -- DO NOT wipe OnEnter/OnLeave here.
  -- Flyouts bind hover behavior; tooltips are set during AssignMacro().
  -- If you nil these, you will intermittently kill flyouts on rebuild.

  if btn._dynIcon then btn._dynIcon:SetTexture(nil) end
end

function Actions:SetTooltipItem(btn, itemID)
  -- Preserve whatever OnEnter/OnLeave is already on the button (e.g., Flyouts)
  local prevEnter = btn:GetScript("OnEnter")
  btn:SetScript("OnEnter", function(self, ...)
    if prevEnter then prevEnter(self, ...) end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetItemByID(itemID)
    GameTooltip:Show()
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

  if tooltipItemID then self:SetTooltipItem(btn, tooltipItemID) end
end
