-- Core.lua (TBC Classic)
-- Minimal, stable bootstrap for DynamicBar.

local ADDON_NAME = ...
local DB_DEFAULTS = {
  profile = {
    enabled = true,
    debug = false,

    -- v0.1: one bar, 10 buttons by default (change later)
    bar = {
      buttons = 10,
      scale = 1.0,
      spacing = 6,
      padding = 6,
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

DynamicBar.Print = Print
DynamicBar.DPrint = DPrint

-- Combat lockdown handling: queue a rebuild if we can't touch secure attributes right now.
DynamicBar._needsRebuild = false
function DynamicBar:RequestRebuild(reason)
  self._needsRebuild = true
  DPrint("Rebuild requested" .. (reason and (": " .. reason) or ""))
  if not InCombatLockdown() then
    self:Rebuild("request")
  end
end

DynamicBar._bagTimer = nil

-- Some tooltip text for items (notably buff foods) can populate a beat later even
-- when the base item info is cached. We do a bounded retry only when we detect
-- pending items during a bag refresh. This avoids /reload spam without creating
-- infinite rebuild loops.
DynamicBar._pendingRetryCount = 0
DynamicBar._pendingRetryMax = 6

local function RebuildBagCache()
  if DynamicBar.Data and DynamicBar.Data.BagCache then
    DynamicBar.Data.BagCache:Rebuild()
    DPrint("Bag cache rebuilt")
  end
end

local function ScheduleBagRefresh()
  if DynamicBar._bagTimer then return end
  DynamicBar._bagTimer = true
  C_Timer.After(0.15, function()
    DynamicBar._bagTimer = nil
    RebuildBagCache()

    -- If items are still pending classification due to late tooltip text, schedule
    -- a bounded follow-up refresh. This handles "slow Well Fed" tooltips reliably.
    local cls = DynamicBar.Data and DynamicBar.Data.Classifier
    local cache = DynamicBar.Data and DynamicBar.Data.BagCache
    local pending = 0
    if cls and cache and cls.CountPendingInBagCache then
      pending = cls:CountPendingInBagCache(cache)
    end

    if pending > 0 and DynamicBar._pendingRetryCount < DynamicBar._pendingRetryMax then
      DynamicBar._pendingRetryCount = DynamicBar._pendingRetryCount + 1
      C_Timer.After(0.35, function()
        -- Only retry out of combat to avoid secure frame churn.
        if not InCombatLockdown() then
          ScheduleBagRefresh()
        end
      end)
    elseif pending == 0 then
      DynamicBar._pendingRetryCount = 0
    end
    DPrint(("Pending items after scan: %d (retry %d/%d)"):format(
  pending, DynamicBar._pendingRetryCount, DynamicBar._pendingRetryMax
))

    DynamicBar:RequestRebuild("bags")
  end)
end

function DynamicBar:Rebuild(reason)
  if InCombatLockdown() then
    self._needsRebuild = true
    DPrint("Rebuild deferred (combat)" .. (reason and (": " .. reason) or ""))
    return
  end

  self._needsRebuild = false
  DPrint("Rebuild executing" .. (reason and (": " .. reason) or ""))

  -- IMPORTANT: Never schedule a rebuild *from inside* Rebuild().
  -- That creates an out-of-combat infinite rebuild loop.
  -- If you need a one-time "UI settle" delay on login, do it in PLAYER_LOGIN/ENTERING_WORLD.
  -- UI module will exist soon; for now this is a stub.
  if self.UI and self.UI.Rebuild then
    self.UI:Rebuild()
  end
end

-- Event frame
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD") -- helps when bags/spells settle after load
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:RegisterEvent("BAG_UPDATE")            -- Anniversary-safe bag change event
f:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
f:RegisterEvent("BANKFRAME_OPENED")
f:RegisterEvent("BANKFRAME_CLOSED")
f:RegisterEvent("SPELLS_CHANGED")
f:RegisterEvent("GET_ITEM_INFO_RECEIVED") -- item data cache fill-in (important on fresh toons)

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
    RebuildBagCache()
    ScheduleBagRefresh()
  elseif event == "PLAYER_REGEN_ENABLED" then
    -- Leaving combat: apply any queued rebuild
    if DynamicBar._needsRebuild then
      DynamicBar:Rebuild("combat ended")
    end
  elseif event == "PLAYER_ENTERING_WORLD" then
    -- Bags are often fully populated here vs. at PLAYER_LOGIN
    ScheduleBagRefresh()
  elseif event == "BAG_UPDATE" then
    ScheduleBagRefresh()
  elseif event == "PLAYERBANKSLOTS_CHANGED" then
    ScheduleBagRefresh()
  elseif event == "BANKFRAME_OPENED" then
    ScheduleBagRefresh()
  elseif event == "BANKFRAME_CLOSED" then
    ScheduleBagRefresh()
  elseif event == "SPELLS_CHANGED" then
    -- Learned/forgot spells: impacts mount/hearth-like spell picks, etc.
    DynamicBar:RequestRebuild("spells")
    ScheduleBagRefresh()
  elseif event == "GET_ITEM_INFO_RECEIVED" then
    -- When the client asynchronously receives item data, re-scan pending tooltips.
    -- This avoids needing any repeating timers and fixes fresh-toon "missing food" cases.
    ScheduleBagRefresh()
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
    Print("  /dbar dump    - dump bag/classifier/resolver state (debug on)")
    Print("  /dbar pending - list pending items (debug on)")
    Print("  /dbar rebuild - force rebuild (out of combat)")
    return
  end

  if msg == "dump" then
    if DynamicBar.Debug and DynamicBar.Debug.Dump then
      DynamicBar.Debug:Dump()
    else
      Print("Debug module not available.")
    end
    return
  end

  if msg == "pending" then
    if DynamicBar.Debug and DynamicBar.Debug.DumpPending then
      DynamicBar.Debug:DumpPending()
    else
      Print("Debug module not available.")
    end
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
