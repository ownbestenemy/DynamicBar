local ADDON_NAME = ...
local DynamicBar = LibStub("AceAddon-3.0"):GetAddon("DynamicBar")
local L = LibStub("AceLocale-3.0"):GetLocale("DynamicBar")

-- Cache global function (TBC/Vanilla compatibility)
local IsAddOnLoaded = IsAddOnLoaded or (C_AddOns and C_AddOns.IsAddOnLoaded)

function DynamicBar:InitConfig()
  local AceConfig = LibStub("AceConfig-3.0", true)
  local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)

  if not AceConfig or not AceConfigDialog then
    self:Print(L["AceConfig libs not loaded."])
    return
  end

  -- Position preset definitions
  local POSITION_PRESETS = {
    BOTTOM_CENTER = { point = "CENTER", relPoint = "CENTER", x = 0, y = -180 },
    TOP_CENTER = { point = "TOP", relPoint = "TOP", x = 0, y = -50 },
    CENTER = { point = "CENTER", relPoint = "CENTER", x = 0, y = 0 },
    CUSTOM = nil,
  }

  -- Helper: Apply a position preset
  local function ApplyPositionPreset(preset)
    if preset == "CUSTOM" then return end
    local p = POSITION_PRESETS[preset]
    if not p then return end

    self.db.profile.bar.point = p.point
    self.db.profile.bar.relPoint = p.relPoint
    self.db.profile.bar.x = p.x
    self.db.profile.bar.y = p.y

    if not InCombatLockdown() then
      self:RequestRebuild("preset_changed")
    end
  end

  -- Helper: Detect if current position matches a preset
  local function GetCurrentPreset()
    for preset, values in pairs(POSITION_PRESETS) do
      if values and
         self.db.profile.bar.point == values.point and
         self.db.profile.bar.relPoint == values.relPoint and
         self.db.profile.bar.x == values.x and
         self.db.profile.bar.y == values.y then
        return preset
      end
    end
    return "CUSTOM"
  end

  -- =========================================================
  -- BUILD OPTIONS TABLE WITH TABS
  -- =========================================================
  local options = {
    type = "group",
    name = "DynamicBar",
    childGroups = "tab",
    args = {
      -- =====================================================
      -- TAB 1: GENERAL
      -- =====================================================
      general = {
        type = "group",
        name = "General",
        order = 1,
        args = {
          enabled = {
            type = "toggle",
            name = "Enabled",
            desc = "Enable or disable the DynamicBar addon",
            order = 1,
            width = "full",
            get = function() return self.db.profile.enabled end,
            set = function(_, v)
              self.db.profile.enabled = v
              if v then
                self:RequestRebuild("enabled")
              elseif self.UI and self.UI.bar then
                self.UI.bar:Hide()
              end
            end,
          },
          debug = {
            type = "toggle",
            name = "Debug Mode",
            desc = "Enable debug logging to chat frame",
            order = 2,
            width = "full",
            get = function() return self.db.profile.debug end,
            set = function(_, v) self.db.profile.debug = v end,
          },
          locked = {
            type = "toggle",
            name = "Lock Bar Position",
            desc = "Lock the bar to prevent accidental dragging. Uncheck to drag the bar to a new position.",
            order = 3,
            width = "full",
            get = function() return self.db.profile.bar.locked ~= false end,
            set = function(_, v)
              self.db.profile.bar.locked = v
              if self.UI and self.UI.UpdateLockState then
                self.UI:UpdateLockState()
              end
            end,
          },

          -- Position Section
          positionHeader = {
            type = "header",
            name = "Bar Position",
            order = 10,
          },
          positionDesc = {
            type = "description",
            name = "Choose a preset position or customize manually. Changes apply out of combat.",
            order = 11,
            fontSize = "medium",
          },
          positionPreset = {
            type = "select",
            name = "Position Preset",
            desc = "Choose a common position or select Custom for manual control",
            order = 12,
            values = {
              BOTTOM_CENTER = "Bottom Center (Default)",
              TOP_CENTER = "Top Center",
              CENTER = "Screen Center",
              CUSTOM = "Custom Position",
            },
            sorting = { "BOTTOM_CENTER", "TOP_CENTER", "CENTER", "CUSTOM" },
            width = "full",
            get = function() return GetCurrentPreset() end,
            set = function(_, v)
              if v ~= "CUSTOM" then
                ApplyPositionPreset(v)
              end
            end,
          },
          showAdvanced = {
            type = "toggle",
            name = "Show Advanced Controls",
            desc = "Display manual position adjustment controls",
            order = 13,
            width = "full",
            hidden = function() return GetCurrentPreset() == "CUSTOM" end,
            get = function() return self.db.profile._showAdvancedPosition end,
            set = function(_, v) self.db.profile._showAdvancedPosition = v end,
          },
          point = {
            type = "select",
            name = "Anchor Point",
            desc = "Which corner/edge of the bar to anchor",
            order = 14,
            values = {
              TOPLEFT = "Top Left", TOP = "Top", TOPRIGHT = "Top Right",
              LEFT = "Left", CENTER = "Center", RIGHT = "Right",
              BOTTOMLEFT = "Bottom Left", BOTTOM = "Bottom", BOTTOMRIGHT = "Bottom Right",
            },
            sorting = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" },
            width = "normal",
            hidden = function()
              return GetCurrentPreset() ~= "CUSTOM" and not self.db.profile._showAdvancedPosition
            end,
            get = function() return self.db.profile.bar.point end,
            set = function(_, v)
              self.db.profile.bar.point = v
              if not InCombatLockdown() then
                self:RequestRebuild("position")
              end
            end,
          },
          relPoint = {
            type = "select",
            name = "Relative To",
            desc = "Which corner/edge of the screen to anchor to",
            order = 15,
            values = {
              TOPLEFT = "Top Left", TOP = "Top", TOPRIGHT = "Top Right",
              LEFT = "Left", CENTER = "Center", RIGHT = "Right",
              BOTTOMLEFT = "Bottom Left", BOTTOM = "Bottom", BOTTOMRIGHT = "Bottom Right",
            },
            sorting = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" },
            width = "normal",
            hidden = function()
              return GetCurrentPreset() ~= "CUSTOM" and not self.db.profile._showAdvancedPosition
            end,
            get = function() return self.db.profile.bar.relPoint end,
            set = function(_, v)
              self.db.profile.bar.relPoint = v
              if not InCombatLockdown() then
                self:RequestRebuild("position")
              end
            end,
          },
          xOffset = {
            type = "input",
            name = "X Offset",
            desc = "Horizontal offset in pixels (negative = left, positive = right)",
            order = 16,
            pattern = "^-?%d+$",
            usage = "Enter a number (e.g., -100, 0, 200)",
            width = "normal",
            hidden = function()
              return GetCurrentPreset() ~= "CUSTOM" and not self.db.profile._showAdvancedPosition
            end,
            get = function() return tostring(self.db.profile.bar.x) end,
            set = function(_, v)
              local num = tonumber(v)
              if num then
                self.db.profile.bar.x = num
                if not InCombatLockdown() then
                  self:RequestRebuild("position")
                end
              end
            end,
          },
          yOffset = {
            type = "input",
            name = "Y Offset",
            desc = "Vertical offset in pixels (negative = down, positive = up)",
            order = 17,
            pattern = "^-?%d+$",
            usage = "Enter a number (e.g., -180, 0, 100)",
            width = "normal",
            hidden = function()
              return GetCurrentPreset() ~= "CUSTOM" and not self.db.profile._showAdvancedPosition
            end,
            get = function() return tostring(self.db.profile.bar.y) end,
            set = function(_, v)
              local num = tonumber(v)
              if num then
                self.db.profile.bar.y = num
                if not InCombatLockdown() then
                  self:RequestRebuild("position")
                end
              end
            end,
          },
          resetPosition = {
            type = "execute",
            name = "Reset Position",
            desc = "Reset position to Bottom Center default",
            order = 20,
            confirm = true,
            confirmText = "Reset bar position to Bottom Center?",
            func = function()
              ApplyPositionPreset("BOTTOM_CENTER")
            end,
          },
        },
      },

      -- =====================================================
      -- TAB 2: APPEARANCE
      -- =====================================================
      appearance = {
        type = "group",
        name = "Appearance",
        order = 2,
        args = {
          layoutHeader = {
            type = "header",
            name = "Layout",
            order = 1,
          },
          layoutMode = {
            type = "select",
            name = "Bar Layout",
            desc = "Choose how buttons are arranged",
            order = 2,
            values = {
              HORIZONTAL = "Horizontal (Default)",
              VERTICAL = "Vertical",
              GRID = "Grid",
            },
            sorting = { "HORIZONTAL", "VERTICAL", "GRID" },
            width = "full",
            get = function() return self.db.profile.bar.layoutMode or "HORIZONTAL" end,
            set = function(_, v)
              self.db.profile.bar.layoutMode = v

              -- Auto-calculate grid dimensions when switching to GRID mode
              if v == "GRID" and not self.db.profile.bar.gridRows then
                local buttons = self.db.profile.bar.buttons or 12
                self.db.profile.bar.gridRows = 2
                self.db.profile.bar.gridCols = math.ceil(buttons / 2)
              end

              if not InCombatLockdown() then
                self:RequestRebuild("layout_mode")
              end
            end,
          },
          gridRows = {
            type = "range",
            name = "Grid Rows",
            desc = "Number of rows in grid layout",
            order = 3,
            min = 1,
            max = 12,
            step = 1,
            width = "normal",
            hidden = function()
              return (self.db.profile.bar.layoutMode or "HORIZONTAL") ~= "GRID"
            end,
            get = function() return self.db.profile.bar.gridRows or 2 end,
            set = function(_, v)
              self.db.profile.bar.gridRows = v
              if not InCombatLockdown() then
                self:RequestRebuild("grid_rows")
              end
            end,
          },
          gridCols = {
            type = "range",
            name = "Grid Columns",
            desc = "Number of columns in grid layout",
            order = 4,
            min = 1,
            max = 12,
            step = 1,
            width = "normal",
            hidden = function()
              return (self.db.profile.bar.layoutMode or "HORIZONTAL") ~= "GRID"
            end,
            get = function() return self.db.profile.bar.gridCols or 6 end,
            set = function(_, v)
              self.db.profile.bar.gridCols = v
              if not InCombatLockdown() then
                self:RequestRebuild("grid_cols")
              end
            end,
          },
          scale = {
            type = "range",
            name = "Bar Scale",
            desc = "Overall scale of the bar and all buttons",
            order = 5,
            min = 0.5,
            max = 2.0,
            step = 0.05,
            isPercent = true,
            width = "full",
            get = function() return self.db.profile.bar.scale end,
            set = function(_, v)
              self.db.profile.bar.scale = math.max(0.5, math.min(2.0, v))
              if not InCombatLockdown() then
                self:RequestRebuild("scale")
              end
            end,
          },

          spacingHeader = {
            type = "header",
            name = "Spacing",
            order = 10,
          },
          spacingH = {
            type = "range",
            name = function()
              local mode = self.db.profile.bar.layoutMode or "HORIZONTAL"
              if mode == "VERTICAL" then return "Spacing"
              else return "Horizontal Spacing" end
            end,
            desc = "Horizontal space between buttons (pixels)",
            order = 11,
            min = 0,
            max = 20,
            step = 1,
            width = "normal",
            get = function() return self.db.profile.bar.spacingH or self.db.profile.bar.spacing or 2 end,
            set = function(_, v)
              self.db.profile.bar.spacingH = v
              if not InCombatLockdown() then
                self:RequestRebuild("spacing_h")
              end
            end,
          },
          spacingV = {
            type = "range",
            name = "Vertical Spacing",
            desc = "Vertical space between buttons (pixels)",
            order = 12,
            min = 0,
            max = 20,
            step = 1,
            width = "normal",
            hidden = function()
              return (self.db.profile.bar.layoutMode or "HORIZONTAL") == "HORIZONTAL"
            end,
            get = function() return self.db.profile.bar.spacingV or 2 end,
            set = function(_, v)
              self.db.profile.bar.spacingV = v
              if not InCombatLockdown() then
                self:RequestRebuild("spacing_v")
              end
            end,
          },

          paddingHeader = {
            type = "header",
            name = "Padding",
            order = 20,
          },
          padding = {
            type = "range",
            name = "Edge Padding",
            desc = "Space on edges of the bar (pixels) - use Advanced Padding for per-edge control",
            order = 21,
            min = 0,
            max = 20,
            step = 1,
            width = "full",
            get = function() return self.db.profile.bar.padding end,
            set = function(_, v)
              self.db.profile.bar.padding = v
              -- Also update new pad* fields for backward compatibility
              self.db.profile.bar.padLeft = v
              self.db.profile.bar.padRight = v
              self.db.profile.bar.padTop = v
              self.db.profile.bar.padBottom = v
              if not InCombatLockdown() then
                self:RequestRebuild("padding")
              end
            end,
          },
          showAdvancedPadding = {
            type = "toggle",
            name = "Show Advanced Padding",
            desc = "Adjust padding for each edge separately",
            order = 22,
            width = "full",
            get = function() return self.db.profile._showAdvancedPadding end,
            set = function(_, v) self.db.profile._showAdvancedPadding = v end,
          },
          padLeft = {
            type = "range",
            name = "Left Padding",
            desc = "Space on left edge (pixels)",
            order = 23,
            min = 0,
            max = 20,
            step = 1,
            width = "half",
            hidden = function() return not self.db.profile._showAdvancedPadding end,
            get = function() return self.db.profile.bar.padLeft or self.db.profile.bar.padding or 2 end,
            set = function(_, v)
              self.db.profile.bar.padLeft = v
              if not InCombatLockdown() then
                self:RequestRebuild("pad_left")
              end
            end,
          },
          padRight = {
            type = "range",
            name = "Right Padding",
            desc = "Space on right edge (pixels)",
            order = 24,
            min = 0,
            max = 20,
            step = 1,
            width = "half",
            hidden = function() return not self.db.profile._showAdvancedPadding end,
            get = function() return self.db.profile.bar.padRight or self.db.profile.bar.padding or 2 end,
            set = function(_, v)
              self.db.profile.bar.padRight = v
              if not InCombatLockdown() then
                self:RequestRebuild("pad_right")
              end
            end,
          },
          padTop = {
            type = "range",
            name = "Top Padding",
            desc = "Space on top edge (pixels)",
            order = 25,
            min = 0,
            max = 20,
            step = 1,
            width = "half",
            hidden = function() return not self.db.profile._showAdvancedPadding end,
            get = function() return self.db.profile.bar.padTop or self.db.profile.bar.padding or 2 end,
            set = function(_, v)
              self.db.profile.bar.padTop = v
              if not InCombatLockdown() then
                self:RequestRebuild("pad_top")
              end
            end,
          },
          padBottom = {
            type = "range",
            name = "Bottom Padding",
            desc = "Space on bottom edge (pixels)",
            order = 26,
            min = 0,
            max = 20,
            step = 1,
            width = "half",
            hidden = function() return not self.db.profile._showAdvancedPadding end,
            get = function() return self.db.profile.bar.padBottom or self.db.profile.bar.padding or 2 end,
            set = function(_, v)
              self.db.profile.bar.padBottom = v
              if not InCombatLockdown() then
                self:RequestRebuild("pad_bottom")
              end
            end,
          },

          skinsHeader = {
            type = "header",
            name = "Skinning",
            order = 30,
          },
          inheritElvUI = {
            type = "toggle",
            name = "Use ElvUI Spacing",
            desc = "Automatically inherit button spacing and padding from ElvUI (horizontal mode only)",
            order = 31,
            width = "full",
            disabled = function()
              local mode = self.db.profile.bar.layoutMode or "HORIZONTAL"
              return (mode ~= "HORIZONTAL") or not (IsAddOnLoaded("ElvUI") and ElvUI and ElvUI[1])
            end,
            get = function() return self.db.profile.bar.inheritElvUI end,
            set = function(_, v)
              self.db.profile.bar.inheritElvUI = v
              if not InCombatLockdown() then
                self:RequestRebuild("inherit_elvui")
              end
            end,
          },
          buttonSkinInfo = {
            type = "description",
            name = function()
              local skinName = "Unknown"
              if self.UI and self.UI.Skins then
                skinName = self.UI.Skins:GetActiveSkinName() or "Unknown"
              end
              local elvInfo = ""
              if self.db.profile.bar.inheritElvUI and IsAddOnLoaded("ElvUI") then
                elvInfo = " | ElvUI spacing active"
              end
              return "|cff00ff00Button Style:|r " .. skinName .. " (auto-detected)" .. elvInfo
            end,
            order = 32,
            fontSize = "medium",
          },

          resetAppearance = {
            type = "execute",
            name = "Reset Appearance",
            desc = "Reset all appearance settings to default values",
            order = 100,
            confirm = true,
            confirmText = "Reset scale, layout mode, spacing, and padding to defaults?",
            func = function()
              local DB_DEFAULTS = self.DB_DEFAULTS or {
                profile = {
                  bar = {
                    scale = 1.0,
                    layoutMode = "HORIZONTAL",
                    gridRows = 2,
                    gridCols = 6,
                    spacingH = 2,
                    spacingV = 2,
                    padLeft = 2,
                    padRight = 2,
                    padTop = 2,
                    padBottom = 2,
                    spacing = 2,
                    padding = 2,
                  }
                }
              }
              local defaults = DB_DEFAULTS.profile.bar
              self.db.profile.bar.scale = defaults.scale
              self.db.profile.bar.layoutMode = defaults.layoutMode
              self.db.profile.bar.gridRows = defaults.gridRows
              self.db.profile.bar.gridCols = defaults.gridCols
              self.db.profile.bar.spacingH = defaults.spacingH
              self.db.profile.bar.spacingV = defaults.spacingV
              self.db.profile.bar.padLeft = defaults.padLeft
              self.db.profile.bar.padRight = defaults.padRight
              self.db.profile.bar.padTop = defaults.padTop
              self.db.profile.bar.padBottom = defaults.padBottom
              self.db.profile.bar.spacing = defaults.spacing
              self.db.profile.bar.padding = defaults.padding
              if not InCombatLockdown() then
                self:RequestRebuild("reset_appearance")
              end
            end,
          },
        },
      },

      -- =====================================================
      -- TAB 3: BEHAVIOR
      -- =====================================================
      behavior = {
        type = "group",
        name = "Behavior",
        order = 3,
        args = {
          buttonsHeader = {
            type = "header",
            name = "Button Configuration",
            order = 1,
          },
          buttons = {
            type = "range",
            name = "Button Count",
            desc = "Number of buttons to display on the bar",
            order = 2,
            min = 1,
            max = 12,
            step = 1,
            width = "full",
            get = function() return self.db.profile.bar.buttons end,
            set = function(_, v)
              self.db.profile.bar.buttons = math.max(1, math.min(12, v))
              if not InCombatLockdown() then
                self:RequestRebuild("button_count")
              end
            end,
          },

          displayHeader = {
            type = "header",
            name = "Display Behavior",
            order = 10,
          },
          visibilityMode = {
            type = "select",
            name = "Prep-Only Slots During Combat",
            desc = "How to display prep-mode items when you enter combat\n\n" ..
                   "Prep-only items: Elixirs, Flasks, Food, Drink (not usable in combat)\n" ..
                   "Battle items always visible: Health/Mana Potions, Healthstone, Bandages",
            order = 11,
            values = {
              FADE = "Fade Out (Recommended)",
              HIDE = "Hide Completely",
              GREY = "Grey Out (Disabled)",
              ALWAYS = "Keep Visible (Always)",
            },
            sorting = { "FADE", "HIDE", "GREY", "ALWAYS" },
            width = "full",
            get = function() return self.db.profile.bar.visibilityMode or "FADE" end,
            set = function(_, v)
              self.db.profile.bar.visibilityMode = v
              if not InCombatLockdown() then
                self:RequestRebuild("visibility_mode")
              end
            end,
          },
          buttonDisplayMode = {
            type = "select",
            name = "Empty Button Slots",
            desc = "How to handle buttons with no items assigned\n\n" ..
                   "|cff00ff00Smart (Recommended)|r - Empty buttons are invisible but space is reserved\n" ..
                   "  • Keybinds remain stable (button 1 is always button 1)\n" ..
                   "  • Clean appearance without clutter\n\n" ..
                   "Static - All buttons always visible, including empty slots\n" ..
                   "  • Shows empty placeholders for unused slots\n" ..
                   "  • Keybinds remain stable\n\n" ..
                   "|cffff0000Dynamic (Advanced)|r - Bar shrinks/grows with items\n" ..
                   "  • ⚠️ WARNING: Button positions shift as items appear/disappear\n" ..
                   "  • ⚠️ Keybinds will break (button 1 may become button 3 on next rebuild)\n" ..
                   "  • Not recommended unless you never use keybinds",
            order = 12,
            values = {
              SMART = "Smart - Binding Safe (Recommended)",
              STATIC = "Static - Show All Slots",
              DYNAMIC = "⚠️ EXPERT: Dynamic (Breaks Keybinds)",
            },
            sorting = { "SMART", "STATIC", "DYNAMIC" },
            width = "full",
            confirm = function(_, v)
              if v == "DYNAMIC" and self.db.profile.bar.buttonDisplayMode ~= "DYNAMIC" then
                return "⚠️ WARNING: Dynamic mode shifts button positions on every rebuild.\n\n" ..
                       "This WILL break your keybinds - the item assigned to a keybind will change as your inventory changes.\n\n" ..
                       "Recommended: Use Smart mode instead (binding-safe, same visual cleanup).\n\n" ..
                       "Continue with Dynamic mode?"
              end
              return false
            end,
            confirmText = "Enable Dynamic Mode (Breaks Keybinds)?",
            get = function() return self.db.profile.bar.buttonDisplayMode or "SMART" end,
            set = function(_, v)
              self.db.profile.bar.buttonDisplayMode = v
              if not InCombatLockdown() then
                self:RequestRebuild("button_display_mode")
              end
            end,
          },

          slotOrderHeader = {
            type = "header",
            name = "Slot Priority",
            order = 20,
            hidden = function()
              local buttons = self.db.profile.bar.buttons or 12
              local customEnabled = self.db.profile.bar.enableCustomSlotOrder
              return buttons >= 12 and not customEnabled
            end,
          },
          enableCustomSlotOrder = {
            type = "toggle",
            name = "Enable Custom Slot Order",
            desc = "Show slot reorder controls even at 12 buttons. Allows you to customize which consumables appear in which position.",
            order = 21,
            width = "full",
            get = function() return self.db.profile.bar.enableCustomSlotOrder end,
            set = function(_, v)
              self.db.profile.bar.enableCustomSlotOrder = v
            end,
          },
          slotPriorityDesc = {
            type = "description",
            name = function()
              local n = self.db.profile.bar.buttons or 12
              return ("You have %d buttons. Use the buttons below to reorder which slots appear on your bar. Top %d slots will be shown."):format(n, n)
            end,
            order = 22,
            fontSize = "medium",
            hidden = function()
              local buttons = self.db.profile.bar.buttons or 12
              local customEnabled = self.db.profile.bar.enableCustomSlotOrder
              return buttons >= 12 and not customEnabled
            end,
          },
          slotPriorityList = {
            type = "group",
            name = "Slot Order",
            order = 23,
            inline = true,
            hidden = function()
              local buttons = self.db.profile.bar.buttons or 12
              local customEnabled = self.db.profile.bar.enableCustomSlotOrder
              return buttons >= 12 and not customEnabled
            end,
            args = (function()
              -- Build slot priority controls dynamically
              local slotArgs = {}
              local UI = self.UI
              local SLOT_DEFS = UI and UI.SLOT_DEFS
              local DEFAULT_ORDER = UI and UI.DEFAULT_SLOT_ORDER

              if not SLOT_DEFS or not DEFAULT_ORDER then
                return { noUI = { type = "description", name = "UI not loaded yet.", order = 1 } }
              end

              -- Helper to get current slot order (always returns a fresh copy)
              local function GetCurrentOrder()
                local source = self.db.profile.bar.slotOrder
                if not (source and type(source) == "table" and #source > 0) then
                  source = DEFAULT_ORDER
                end
                local order = {}
                for i, key in ipairs(source) do
                  order[i] = key
                end
                return order
              end

              -- Helper to save slot order
              local function SaveOrder(order)
                self.db.profile.bar.slotOrder = order
                if not InCombatLockdown() then
                  self:RequestRebuild("slot_order")
                end
              end

              -- Helper to move slot up
              local function MoveUp(key)
                local order = GetCurrentOrder()
                for i, k in ipairs(order) do
                  if k == key and i > 1 then
                    order[i], order[i-1] = order[i-1], order[i]
                    break
                  end
                end
                SaveOrder(order)
              end

              -- Helper to move slot down
              local function MoveDown(key)
                local order = GetCurrentOrder()
                for i, k in ipairs(order) do
                  if k == key and i < #order then
                    order[i], order[i+1] = order[i+1], order[i]
                    break
                  end
                end
                SaveOrder(order)
              end

              -- Create controls for each slot
              for idx, key in ipairs(DEFAULT_ORDER) do
                local def = SLOT_DEFS[key]
                if def then
                  -- Slot name with position indicator
                  slotArgs["slot_" .. key .. "_name"] = {
                    type = "description",
                    name = function()
                      local order = GetCurrentOrder()
                      local pos = 1
                      for i, k in ipairs(order) do
                        if k == key then pos = i break end
                      end
                      local n = self.db.profile.bar.buttons or 12
                      local visible = pos <= n
                      local color = visible and "|cff00ff00" or "|cff666666"
                      return ("%s%d. %s|r"):format(color, pos, def.name)
                    end,
                    order = idx * 10,
                    width = 1.0,
                  }
                  -- Move up button
                  slotArgs["slot_" .. key .. "_up"] = {
                    type = "execute",
                    name = "^",
                    desc = "Move up",
                    order = idx * 10 + 1,
                    width = 0.25,
                    func = function() MoveUp(key) end,
                    disabled = function()
                      local order = GetCurrentOrder()
                      return order[1] == key
                    end,
                  }
                  -- Move down button
                  slotArgs["slot_" .. key .. "_down"] = {
                    type = "execute",
                    name = "v",
                    desc = "Move down",
                    order = idx * 10 + 2,
                    width = 0.25,
                    func = function() MoveDown(key) end,
                    disabled = function()
                      local order = GetCurrentOrder()
                      return order[#order] == key
                    end,
                  }
                end
              end

              -- Reset button
              slotArgs["resetOrder"] = {
                type = "execute",
                name = "Reset to Default Order",
                order = 200,
                width = "full",
                func = function()
                  self.db.profile.bar.slotOrder = nil
                  if not InCombatLockdown() then
                    self:RequestRebuild("slot_order_reset")
                  end
                end,
              }

              return slotArgs
            end)(),
          },
        },
      },

      -- =====================================================
      -- TAB 4: PROFILES (placeholder, replaced below)
      -- =====================================================
      profiles = {
        type = "group",
        name = "Profiles",
        order = 4,
        args = {},
      },
    },
  }

  -- Embed AceDBOptions as the profiles tab (use full table to preserve handler)
  local AceDBOptions = LibStub("AceDBOptions-3.0", true)
  if AceDBOptions then
    local profileOptions = AceDBOptions:GetOptionsTable(self.db)
    profileOptions.order = 4  -- Keep it as 4th tab
    options.args.profiles = profileOptions
  else
    self:Print("AceDBOptions not loaded (Profiles UI unavailable).")
  end

  -- Register main options table
  AceConfig:RegisterOptionsTable("DynamicBar", options)

  -- Add main panel to Blizzard options
  AceConfigDialog:AddToBlizOptions("DynamicBar", "DynamicBar")

  self.options = options
end

function DynamicBar:OpenConfig()
  local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)
  if not AceConfigDialog then
    self:Print(L["AceConfigDialog not loaded."])
    return
  end
  AceConfigDialog:Open("DynamicBar")

  -- Make config window movable and save/restore position
  local frame = AceConfigDialog.OpenFrames["DynamicBar"]
  if frame and frame.frame then
    local configFrame = frame.frame
    local db = self.db.profile

    -- Initialize config window position storage
    db._configWindowPos = db._configWindowPos or {}

    configFrame:SetMovable(true)
    configFrame:EnableMouse(true)
    configFrame:RegisterForDrag("LeftButton")
    configFrame:SetClampedToScreen(true)

    configFrame:SetScript("OnDragStart", function(f)
      f:StartMoving()
    end)

    configFrame:SetScript("OnDragStop", function(f)
      f:StopMovingOrSizing()
      -- Save position
      local point, _, relPoint, x, y = f:GetPoint()
      db._configWindowPos.point = point
      db._configWindowPos.relPoint = relPoint
      db._configWindowPos.x = x
      db._configWindowPos.y = y
    end)

    -- Restore saved position if available
    if db._configWindowPos.point then
      configFrame:ClearAllPoints()
      configFrame:SetPoint(
        db._configWindowPos.point,
        UIParent,
        db._configWindowPos.relPoint,
        db._configWindowPos.x,
        db._configWindowPos.y
      )
    end
  end
end
-- End of Config.lua
