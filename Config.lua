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

  -- Rebuild after a setting change (out of combat; combat rebuilds are deferred)
  local function Changed(reason)
    self:RequestRebuild(reason)
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

    Changed("preset_changed")
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

  -- Default get/set for options whose key matches a db.profile.bar field.
  -- AceDB fills in DB_DEFAULTS, so no fallbacks are needed here.
  -- Options with special handling define their own get/set.
  local function BarGet(info) return self.db.profile.bar[info[#info]] end
  local function BarSet(info, v)
    self.db.profile.bar[info[#info]] = v
    Changed(info[#info])
  end

  local ANCHOR_POINTS = {
    TOPLEFT = L["Top Left"], TOP = L["Top"], TOPRIGHT = L["Top Right"],
    LEFT = L["Left"], CENTER = L["Center"], RIGHT = L["Right"],
    BOTTOMLEFT = L["Bottom Left"], BOTTOM = L["Bottom"], BOTTOMRIGHT = L["Bottom Right"],
  }
  local ANCHOR_SORTING = { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }

  local function HideManualPosition()
    return GetCurrentPreset() ~= "CUSTOM" and not self.db.profile._showAdvancedPosition
  end

  local function HideAdvancedPadding()
    return not self.db.profile._showAdvancedPadding
  end

  local function IsNotGrid()
    return self.db.profile.bar.layoutMode ~= "GRID"
  end

  -- =========================================================
  -- BUILD OPTIONS TABLE WITH TABS
  -- =========================================================
  local options = {
    type = "group",
    name = L["DynamicBar"],
    childGroups = "tab",
    get = BarGet,
    set = BarSet,
    args = {
      -- =====================================================
      -- TAB 1: GENERAL
      -- =====================================================
      general = {
        type = "group",
        name = L["General"],
        order = 1,
        args = {
          enabled = {
            type = "toggle",
            name = L["Enabled"],
            desc = L["Enable or disable the DynamicBar addon. Changes apply after combat."],
            order = 1,
            width = "full",
            get = function() return self.db.profile.enabled end,
            set = function(_, v)
              self:SetEnabled(v)
            end,
          },
          debug = {
            type = "toggle",
            name = L["Debug Mode"],
            desc = L["Enable debug logging to chat frame"],
            order = 2,
            width = "full",
            get = function() return self.db.profile.debug end,
            set = function(_, v) self.db.profile.debug = v end,
          },
          locked = {
            type = "toggle",
            name = L["Lock Bar Position"],
            desc = L["Lock the bar to prevent accidental dragging. Uncheck to drag the bar to a new position."],
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
            name = L["Bar Position"],
            order = 10,
          },
          positionDesc = {
            type = "description",
            name = L["Choose a preset position or customize manually. Changes apply out of combat."],
            order = 11,
            fontSize = "medium",
          },
          positionPreset = {
            type = "select",
            name = L["Position Preset"],
            desc = L["Choose a common position or select Custom for manual control"],
            order = 12,
            values = {
              BOTTOM_CENTER = L["Bottom Center (Default)"],
              TOP_CENTER = L["Top Center"],
              CENTER = L["Screen Center"],
              CUSTOM = L["Custom Position"],
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
            name = L["Show Advanced Controls"],
            desc = L["Display manual position adjustment controls"],
            order = 13,
            width = "full",
            hidden = function() return GetCurrentPreset() == "CUSTOM" end,
            get = function() return self.db.profile._showAdvancedPosition end,
            set = function(_, v) self.db.profile._showAdvancedPosition = v end,
          },
          point = {
            type = "select",
            name = L["Anchor Point"],
            desc = L["Which corner/edge of the bar to anchor"],
            order = 14,
            values = ANCHOR_POINTS,
            sorting = ANCHOR_SORTING,
            width = "normal",
            hidden = HideManualPosition,
          },
          relPoint = {
            type = "select",
            name = L["Relative To"],
            desc = L["Which corner/edge of the screen to anchor to"],
            order = 15,
            values = ANCHOR_POINTS,
            sorting = ANCHOR_SORTING,
            width = "normal",
            hidden = HideManualPosition,
          },
          xOffset = {
            type = "input",
            name = L["X Offset"],
            desc = L["Horizontal offset in pixels (negative = left, positive = right)"],
            order = 16,
            pattern = "^-?%d+$",
            usage = L["Enter a number (e.g., -100, 0, 200)"],
            width = "normal",
            hidden = HideManualPosition,
            get = function() return tostring(self.db.profile.bar.x) end,
            set = function(_, v)
              local num = tonumber(v)
              if num then
                self.db.profile.bar.x = num
                Changed("position")
              end
            end,
          },
          yOffset = {
            type = "input",
            name = L["Y Offset"],
            desc = L["Vertical offset in pixels (negative = down, positive = up)"],
            order = 17,
            pattern = "^-?%d+$",
            usage = L["Enter a number (e.g., -180, 0, 100)"],
            width = "normal",
            hidden = HideManualPosition,
            get = function() return tostring(self.db.profile.bar.y) end,
            set = function(_, v)
              local num = tonumber(v)
              if num then
                self.db.profile.bar.y = num
                Changed("position")
              end
            end,
          },
          resetPosition = {
            type = "execute",
            name = L["Reset Position"],
            desc = L["Reset position to Bottom Center default"],
            order = 20,
            confirm = true,
            confirmText = L["Reset bar position to Bottom Center?"],
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
        name = L["Appearance"],
        order = 2,
        args = {
          layoutHeader = {
            type = "header",
            name = L["Layout"],
            order = 1,
          },
          layoutMode = {
            type = "select",
            name = L["Bar Layout"],
            desc = L["Choose how buttons are arranged"],
            order = 2,
            values = {
              HORIZONTAL = L["Horizontal (Default)"],
              VERTICAL = L["Vertical"],
              GRID = L["Grid"],
            },
            sorting = { "HORIZONTAL", "VERTICAL", "GRID" },
            width = "full",
          },
          gridRows = {
            type = "range",
            name = L["Grid Rows"],
            desc = L["Number of rows in grid layout. Rows expand automatically if needed to fit every button."],
            order = 3,
            min = 1,
            max = 12,
            step = 1,
            width = "normal",
            hidden = IsNotGrid,
          },
          gridCols = {
            type = "range",
            name = L["Grid Columns"],
            desc = L["Number of columns in grid layout"],
            order = 4,
            min = 1,
            max = 12,
            step = 1,
            width = "normal",
            hidden = IsNotGrid,
          },
          scale = {
            type = "range",
            name = L["Bar Scale"],
            desc = L["Overall scale of the bar and all buttons"],
            order = 5,
            min = 0.5,
            max = 2.0,
            step = 0.05,
            isPercent = true,
            width = "full",
          },

          spacingHeader = {
            type = "header",
            name = L["Spacing"],
            order = 10,
          },
          spacingH = {
            type = "range",
            name = function()
              local mode = self.db.profile.bar.layoutMode or "HORIZONTAL"
              if mode == "VERTICAL" then return L["Spacing"]
              else return L["Horizontal Spacing"] end
            end,
            desc = L["Horizontal space between buttons (pixels)"],
            order = 11,
            min = 0,
            max = 20,
            step = 1,
            width = "normal",
          },
          spacingV = {
            type = "range",
            name = L["Vertical Spacing"],
            desc = L["Vertical space between buttons (pixels)"],
            order = 12,
            min = 0,
            max = 20,
            step = 1,
            width = "normal",
            hidden = function()
              return (self.db.profile.bar.layoutMode or "HORIZONTAL") == "HORIZONTAL"
            end,
          },

          paddingHeader = {
            type = "header",
            name = L["Padding"],
            order = 20,
          },
          padding = {
            type = "range",
            name = L["Edge Padding"],
            desc = L["Space on edges of the bar (pixels) - use Advanced Padding for per-edge control"],
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
              Changed("padding")
            end,
          },
          showAdvancedPadding = {
            type = "toggle",
            name = L["Show Advanced Padding"],
            desc = L["Adjust padding for each edge separately"],
            order = 22,
            width = "full",
            get = function() return self.db.profile._showAdvancedPadding end,
            set = function(_, v) self.db.profile._showAdvancedPadding = v end,
          },
          padLeft = {
            type = "range",
            name = L["Left Padding"],
            desc = L["Space on left edge (pixels)"],
            order = 23,
            min = 0,
            max = 20,
            step = 1,
            width = "half",
            hidden = HideAdvancedPadding,
          },
          padRight = {
            type = "range",
            name = L["Right Padding"],
            desc = L["Space on right edge (pixels)"],
            order = 24,
            min = 0,
            max = 20,
            step = 1,
            width = "half",
            hidden = HideAdvancedPadding,
          },
          padTop = {
            type = "range",
            name = L["Top Padding"],
            desc = L["Space on top edge (pixels)"],
            order = 25,
            min = 0,
            max = 20,
            step = 1,
            width = "half",
            hidden = HideAdvancedPadding,
          },
          padBottom = {
            type = "range",
            name = L["Bottom Padding"],
            desc = L["Space on bottom edge (pixels)"],
            order = 26,
            min = 0,
            max = 20,
            step = 1,
            width = "half",
            hidden = HideAdvancedPadding,
          },

          skinsHeader = {
            type = "header",
            name = L["Skinning"],
            order = 30,
          },
          inheritElvUI = {
            type = "toggle",
            name = L["Use ElvUI Spacing"],
            desc = L["Automatically inherit button spacing and padding from ElvUI (horizontal mode only)"],
            order = 31,
            width = "full",
            disabled = function()
              local mode = self.db.profile.bar.layoutMode or "HORIZONTAL"
              return (mode ~= "HORIZONTAL") or not (IsAddOnLoaded("ElvUI") and ElvUI and ElvUI[1])
            end,
          },
          buttonSkinInfo = {
            type = "description",
            name = function()
              local skinName = L["Unknown"]
              if self.UI and self.UI.Skins then
                skinName = self.UI.Skins:GetActiveSkinName() or L["Unknown"]
              end
              local elvInfo = ""
              if self.db.profile.bar.inheritElvUI and IsAddOnLoaded("ElvUI") then
                elvInfo = " | " .. L["ElvUI spacing active"]
              end
              return "|cff00ff00" .. L["Button Style:"] .. "|r " .. skinName .. " " .. L["(auto-detected)"] .. elvInfo
            end,
            order = 32,
            fontSize = "medium",
          },

          resetAppearance = {
            type = "execute",
            name = L["Reset Appearance"],
            desc = L["Reset all appearance settings to default values"],
            order = 100,
            confirm = true,
            confirmText = L["Reset scale, layout mode, spacing, and padding to defaults?"],
            func = function()
              local defaults = self.DB_DEFAULTS.profile.bar
              for _, key in ipairs({
                "scale", "layoutMode", "gridRows", "gridCols", "spacingH", "spacingV",
                "padLeft", "padRight", "padTop", "padBottom", "spacing", "padding",
              }) do
                self.db.profile.bar[key] = defaults[key]
              end
              Changed("reset_appearance")
            end,
          },
        },
      },

      -- =====================================================
      -- TAB 3: BEHAVIOR
      -- =====================================================
      behavior = {
        type = "group",
        name = L["Behavior"],
        order = 3,
        args = {
          displayHeader = {
            type = "header",
            name = L["Display Behavior"],
            order = 10,
          },
          visibilityMode = {
            type = "select",
            name = L["Prep-Only Slots During Combat"],
            desc = L["How to display prep-mode items when you enter combat"] .. "\n\n" ..
                   L["Prep-only items: Elixirs, Flasks, Food, Drink (not usable in combat)"] .. "\n" ..
                   L["Battle items always visible: Health/Mana Potions, Healthstone, Bandages"],
            order = 11,
            values = {
              FADE = L["Fade Out (Recommended)"],
              HIDE = L["Hide Completely"],
              GREY = L["Grey Out (Disabled)"],
              ALWAYS = L["Keep Visible (Always)"],
            },
            sorting = { "FADE", "HIDE", "GREY", "ALWAYS" },
            width = "full",
          },
          buttonDisplayMode = {
            type = "select",
            name = L["Empty Button Slots"],
            desc = L["How to handle buttons with no items assigned"] .. "\n\n" ..
                   "|cff00ff00" .. L["Smart (Recommended)"] .. "|r - " .. L["Empty buttons are invisible but space is reserved"] .. "\n" ..
                   "  • " .. L["Keybinds remain stable (button 1 is always button 1)"] .. "\n" ..
                   "  • " .. L["Clean appearance without clutter"] .. "\n\n" ..
                   L["Static"] .. " - " .. L["All buttons always visible, including empty slots"] .. "\n" ..
                   "  • " .. L["Shows empty placeholders for unused slots"] .. "\n" ..
                   "  • " .. L["Keybinds remain stable"] .. "\n\n" ..
                   "|cffff0000" .. L["Dynamic (Advanced)"] .. "|r - " .. L["Bar shrinks/grows with items"] .. "\n" ..
                   "  • ⚠️ " .. L["WARNING: Button positions shift as items appear/disappear"] .. "\n" ..
                   "  • ⚠️ " .. L["Keybinds will break (button 1 may become button 3 on next rebuild)"] .. "\n" ..
                   "  • " .. L["Not recommended unless you never use keybinds"],
            order = 12,
            values = {
              SMART = L["Smart - Binding Safe (Recommended)"],
              STATIC = L["Static - Show All Slots"],
              DYNAMIC = L["⚠️ EXPERT: Dynamic (Breaks Keybinds)"],
            },
            sorting = { "SMART", "STATIC", "DYNAMIC" },
            width = "full",
            confirm = function(_, v)
              if v == "DYNAMIC" and self.db.profile.bar.buttonDisplayMode ~= "DYNAMIC" then
                return "⚠️ " .. L["WARNING: Dynamic mode shifts button positions on every rebuild."] .. "\n\n" ..
                       L["This WILL break your keybinds - the item assigned to a keybind will change as your inventory changes."] .. "\n\n" ..
                       L["Recommended: Use Smart mode instead (binding-safe, same visual cleanup)."] .. "\n\n" ..
                       L["Continue with Dynamic mode?"]
              end
              return false
            end,
            confirmText = L["Enable Dynamic Mode (Breaks Keybinds)?"],
          },

          slotsHeader = {
            type = "header",
            name = L["Bar Slots"],
            order = 20,
          },
          slotsDesc = {
            type = "description",
            name = function()
              local n = #self.Data.Categories:GetSlots(self.db.profile.bar)
              return (L["Your bar has %d buttons, one per category. Use the Bar Builder to choose categories and their order (also /dbar builder)."]):format(n)
            end,
            order = 21,
            fontSize = "medium",
          },
          openBuilder = {
            type = "execute",
            name = L["Open Bar Builder"],
            order = 22,
            width = "double",
            func = function()
              -- Close settings so the builder isn't hidden behind them
              local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)
              if AceConfigDialog then AceConfigDialog:Close("DynamicBar") end
              self.UI.Builder:Open()
            end,
          },
        },
      },

      -- =====================================================
      -- TAB 4: PROFILES (placeholder, replaced below)
      -- =====================================================
      profiles = {
        type = "group",
        name = L["Profiles"],
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
    self:Print(L["AceDBOptions not loaded (Profiles UI unavailable)."])
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
