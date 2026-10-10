-- Click bindings use the same secure buttons as the mouse.
BINDING_HEADER_DYNAMICBAR = "DynamicBar"
for i = 1, 12 do
  _G["BINDING_NAME_CLICK DynamicBarMainButton" .. i .. ":LeftButton"] = "Button " .. i
end
