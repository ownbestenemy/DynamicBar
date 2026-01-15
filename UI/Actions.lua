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

  btn:SetScript("OnEnter", nil)
  btn:SetScript("OnLeave", nil)

  if btn._dynIcon then btn._dynIcon:SetTexture(nil) end
end

function Actions:SetTooltipItem(btn, itemID)
  btn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetItemByID(itemID)
    GameTooltip:Show()
  end)
  btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
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

  if btn._dynIcon then btn._dynIcon:SetTexture(iconTexture) end
  if tooltipItemID then self:SetTooltipItem(btn, tooltipItemID) end
end
