local ADDON_NAME = ...
local DynamicBar = LibStub("AceAddon-3.0"):GetAddon("DynamicBar")

-- Cache global function (TBC/Vanilla compatibility)
local IsAddOnLoaded = IsAddOnLoaded or (C_AddOns and C_AddOns.IsAddOnLoaded)

function DynamicBar:InitConfig()
  local AceConfig = LibStub("AceConfig-3.0", true)
  local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)

  if not AceConfig or not AceConfigDialog then
    self:Print("AceConfig libs not loaded.")
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

  local options = {
    type = "group",
    name = "DynamicBar",
    args = {
      -- ========================================
      -- General Settings
      -- ========================================
      generalHeader = {
        type = "header",
        name = "General Settings",
        order = 10,
      },
      enabled = {
        type = "toggle",
        name = "Enabled",
        desc = "Enable or disable the DynamicBar addon",
        order = 11,
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
        order = 12,
        width = "full",
        get = function() return self.db.profile.debug end,
        set = function(_, v) self.db.profile.debug = v end,
      },

      -- ========================================
      -- Bar Layout
      -- ========================================
      layoutHeader = {
        type = "header",
        name = "Bar Layout",
        order = 20,
      },
      layoutDesc = {
        type = "description",
        name = "Configure the size and appearance of the action bar. Changes apply out of combat.",
        order = 21,
        fontSize = "medium",
      },
      buttons = {
        type = "range",
        name = "Button Count",
        desc = "Number of buttons to display on the bar",
        order = 22,
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
      scale = {
        type = "range",
        name = "Bar Scale",
        desc = "Overall scale of the bar and all buttons",
        order = 23,
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
      spacing = {
        type = "range",
        name = "Button Spacing",
        desc = "Horizontal space between buttons (pixels)",
        order = 24,
        min = 0,
        max = 20,
        step = 1,
        width = "full",
        get = function() return self.db.profile.bar.spacing end,
        set = function(_, v)
          self.db.profile.bar.spacing = math.max(0, math.min(20, v))
          if not InCombatLockdown() then
            self:RequestRebuild("spacing")
          end
        end,
      },
      padding = {
        type = "range",
        name = "Edge Padding",
        desc = "Space on left and right edges of the bar (pixels)",
        order = 25,
        min = 0,
        max = 20,
        step = 1,
        width = "full",
        get = function() return self.db.profile.bar.padding end,
        set = function(_, v)
          self.db.profile.bar.padding = math.max(0, math.min(20, v))
          if not InCombatLockdown() then
            self:RequestRebuild("padding")
          end
        end,
      },
      inheritElvUI = {
        type = "toggle",
        name = "Use ElvUI Spacing",
        desc = "Automatically inherit button spacing and padding from ElvUI (if installed)",
        order = 27,
        width = "full",
        disabled = function()
          -- Disable if ElvUI not installed
          return not (IsAddOnLoaded("ElvUI") and ElvUI and ElvUI[1])
        end,
        get = function() return self.db.profile.bar.inheritElvUI end,
        set = function(_, v)
          self.db.profile.bar.inheritElvUI = v
          if not InCombatLockdown() then
            self:RequestRebuild("inherit_elvui")
          end
        end,
      },
      locked = {
        type = "toggle",
        name = "Lock Bar Position",
        desc = "Lock the bar to prevent accidental dragging. Uncheck to drag the bar to a new position.",
        order = 27.5,
        width = "full",
        get = function() return self.db.profile.bar.locked ~= false end,
        set = function(_, v)
          self.db.profile.bar.locked = v
          if self.UI and self.UI.UpdateLockState then
            self.UI:UpdateLockState()
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
          local lockInfo = ""
          if self.db.profile.bar.locked == false then
            lockInfo = " | |cffff0000UNLOCKED - Drag to move|r"
          end
          return "|cff00ff00Button Style:|r " .. skinName .. " (auto-detected)" .. elvInfo .. lockInfo
        end,
        order = 28,
        fontSize = "medium",
      },
      resetLayout = {
        type = "execute",
        name = "Reset Layout",
        desc = "Reset all layout settings to default values",
        order = 29,
        confirm = true,
        confirmText = "Reset button count, scale, spacing, and padding to defaults?",
        func = function()
          local DB_DEFAULTS = self.DB_DEFAULTS or {
            profile = {
              bar = { buttons = 10, scale = 1.0, spacing = 2, padding = 2 }
            }
          }
          local defaults = DB_DEFAULTS.profile.bar
          self.db.profile.bar.buttons = defaults.buttons
          self.db.profile.bar.scale = defaults.scale
          self.db.profile.bar.spacing = defaults.spacing
          self.db.profile.bar.padding = defaults.padding
          if not InCombatLockdown() then
            self:RequestRebuild("reset_layout")
          end
        end,
      },

      -- ========================================
      -- Bar Position
      -- ========================================
      positionHeader = {
        type = "header",
        name = "Bar Position",
        order = 30,
      },
      positionDesc = {
        type = "description",
        name = "Choose a preset position or customize manually. Changes apply out of combat.",
        order = 31,
        fontSize = "medium",
      },
      positionPreset = {
        type = "select",
        name = "Position Preset",
        desc = "Choose a common position or select Custom for manual control",
        order = 32,
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
        order = 33,
        width = "full",
        hidden = function() return GetCurrentPreset() == "CUSTOM" end,
        get = function() return self.db.profile._showAdvancedPosition end,
        set = function(_, v) self.db.profile._showAdvancedPosition = v end,
      },
      point = {
        type = "select",
        name = "Anchor Point",
        desc = "Which corner/edge of the bar to anchor",
        order = 34,
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
        order = 35,
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
        order = 36,
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
        order = 37,
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
        order = 39,
        confirm = true,
        confirmText = "Reset bar position to Bottom Center?",
        func = function()
          ApplyPositionPreset("BOTTOM_CENTER")
        end,
      },
    },
  }

  -- Register main options table
  AceConfig:RegisterOptionsTable("DynamicBar", options)

  -- Add main panel to Blizzard options
  AceConfigDialog:AddToBlizOptions("DynamicBar", "DynamicBar")

  -- Add AceDBOptions profiles as a separate child page
  local AceDBOptions = LibStub("AceDBOptions-3.0", true)
  if AceDBOptions then
    local profileOptions = AceDBOptions:GetOptionsTable(self.db)
    AceConfig:RegisterOptionsTable("DynamicBar_Profiles", profileOptions)
    -- Add as child page under main DynamicBar panel
    AceConfigDialog:AddToBlizOptions("DynamicBar_Profiles", "Profiles", "DynamicBar")
  else
    self:Print("AceDBOptions not loaded (Profiles UI unavailable).")
  end

  self.options = options
end

function DynamicBar:OpenConfig()
  local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)
  if not AceConfigDialog then
    self:Print("AceConfigDialog not loaded.")
    return
  end
  AceConfigDialog:Open("DynamicBar")

  -- Make config window movable
  local frame = AceConfigDialog.OpenFrames["DynamicBar"]
  if frame and frame.frame then
    local configFrame = frame.frame
    configFrame:SetMovable(true)
    configFrame:EnableMouse(true)
    configFrame:RegisterForDrag("LeftButton")
    configFrame:SetScript("OnDragStart", function(self)
      self:StartMoving()
    end)
    configFrame:SetScript("OnDragStop", function(self)
      self:StopMovingOrSizing()
    end)
  end
end
-- End of Config.lua
