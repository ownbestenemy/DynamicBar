-- Core.lua (TBC Classic)
-- Minimal, stable bootstrap for DynamicBar.

local ADDON_NAME = ...
local DB_DEFAULTS = {
  profile = {
    enabled = true,
    debug = false,

    -- v0.1: one bar, 8 buttons by default (change later)
    bar = {
      buttons = 8,
      scale = 1.0,
      spacing = 4,
      point = "CENTER",
      relPoint = "CENTER",
      x = 0,
      y = -180,
    },
  },
}

DynamicBar = DynamicBar or {} -- global table for future modules
DynamicBar.name = ADDON_NAME

local function DeepCopyDefaults(dst, src)
  if type(dst) ~= "table" then dst = {} end
  for k, v in pairs(src) do
    if type(v) == "table" then
      dst[k] = DeepCopyDefaults(dst[k], v)
    elseif dst[k] == nil then
      dst[k] = v
    end
  end
  return dst
end

local function Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cffffd200DynamicBar:|r " .. tostring(msg))
end

local function DPrint(msg)
  if DynamicBarDB and DynamicBarDB.profile and DynamicBarDB.profile.debug then
    Print("|cff99ccffDEBUG:|r " .. tostring(msg))
  end
end

-- Combat lockdown handling: queue a rebuild if we can't touch secure attributes right now.
DynamicBar._needsRebuild = false
function DynamicBar:RequestRebuild(reason)
  self._needsRebuild = true
  DPrint("Rebuild requested" .. (reason and (": " .. reason) or ""))
  if not InCombatLockdown() then
    self:Rebuild("request")
  end
end

function DynamicBar:Rebuild(reason)
  if InCombatLockdown() then
    self._needsRebuild = true
    DPrint("Rebuild deferred (combat)" .. (reason and (": " .. reason) or ""))
    return
  end

  self._needsRebuild = false
  DPrint("Rebuild executing" .. (reason and (": " .. reason) or ""))

  -- UI module will exist soon; for now this is a stub.
  if self.UI and self.UI.Rebuild then
    self.UI:Rebuild()
  end
end

-- Event frame
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:RegisterEvent("BAG_UPDATE_DELAYED")
f:RegisterEvent("SPELLS_CHANGED")

f:SetScript("OnEvent", function(_, event, ...)
  if event == "PLAYER_LOGIN" then
    -- SavedVariables init
    DynamicBarDB = DeepCopyDefaults(DynamicBarDB or {}, DB_DEFAULTS)

    if DynamicBarDB.profile.enabled then
      Print("Loaded. (/dbar)")
    else
      Print("Loaded (disabled). (/dbar enable)")
    end

    -- Build once on login
    DynamicBar:RequestRebuild("login")

  elseif event == "PLAYER_REGEN_ENABLED" then
    -- Leaving combat: apply any queued rebuild
    if DynamicBar._needsRebuild then
      DynamicBar:Rebuild("combat ended")
    end

  elseif event == "BAG_UPDATE_DELAYED" then
    -- Bag contents changed: later this will rebuild cache, then refresh buttons
    DynamicBar:RequestRebuild("bags")

  elseif event == "SPELLS_CHANGED" then
    -- Learned/forgot spells: impacts mount/hearth-like spell picks, etc.
    DynamicBar:RequestRebuild("spells")
  end
end)

-- Slash commands
SLASH_DYNAMICBAR1 = "/dbar"
SLASH_DYNAMICBAR2 = "/dynamicbar"
SlashCmdList.DYNAMICBAR = function(msg)
  msg = (msg or ""):lower()

  if msg == "" or msg == "help" then
    Print("Commands:")
    Print("  /dbar enable  - enable the addon")
    Print("  /dbar disable - disable the addon")
    Print("  /dbar debug   - toggle debug logging")
    Print("  /dbar rebuild - force rebuild (out of combat)")
    return
  end

  if msg == "enable" then
    DynamicBarDB.profile.enabled = true
    Print("Enabled.")
    DynamicBar:RequestRebuild("enabled")
    return
  end

  if msg == "disable" then
    DynamicBarDB.profile.enabled = false
    Print("Disabled (UI hiding comes later).")
    return
  end

  if msg == "debug" then
    DynamicBarDB.profile.debug = not DynamicBarDB.profile.debug
    Print("Debug " .. (DynamicBarDB.profile.debug and "ON" or "OFF"))
    return
  end

  if msg == "rebuild" then
    DynamicBar:Rebuild("slash")
    return
  end

  Print("Unknown command. Use /dbar help")
end
