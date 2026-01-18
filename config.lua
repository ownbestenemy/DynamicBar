local ADDON_NAME = ...
local DynamicBar = LibStub("AceAddon-3.0"):GetAddon("DynamicBar")

function DynamicBar:InitConfig()
  local AceConfig = LibStub("AceConfig-3.0", true)
  local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)

  if not AceConfig or not AceConfigDialog then
    self:Print("AceConfig libs not loaded.")
    return
  end

  local options = {
    type = "group",
    name = "DynamicBar",
    args = {
      general = {
        type = "group",
        name = "General",
        order = 1,
        args = {
          enabled = {
            type = "toggle",
            name = "Enabled",
            order = 1,
            get = function() return self.db.profile.enabled end,
            set = function(_, v) self.db.profile.enabled = v end,
          },
          debug = {
            type = "toggle",
            name = "Debug",
            order = 2,
            get = function() return self.db.profile.debug end,
            set = function(_, v) self.db.profile.debug = v end,
          },
        },
      },
    },
  }

  -- Register FIRST. If this doesn't happen, /dbar config must not open.
  AceConfig:RegisterOptionsTable("DynamicBar", options)

  -- Only after registration, add it to Blizzard options.
  AceConfigDialog:AddToBlizOptions("DynamicBar", "DynamicBar")
  -- Profiles page (separate top-level entry; avoids Classic/TBC parent-category quirks)
  local AceDBOptions = LibStub("AceDBOptions-3.0", true)
  if AceDBOptions then
    local profiles = AceDBOptions:GetOptionsTable(self.db)
    AceConfig:RegisterOptionsTable("DynamicBar_Profiles", profiles)
    AceConfigDialog:AddToBlizOptions("DynamicBar_Profiles", "DynamicBar - Profiles")
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
end
-- End of Config.lua
