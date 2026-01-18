-- Core.lua (TBC Classic)
-- Ace3 bootstrap for DynamicBar.

local ADDON_NAME = ...

-- Ace3 addon instance (object)
local AceAddon = LibStub("AceAddon-3.0")
DynamicBar = AceAddon:NewAddon("DynamicBar", "AceEvent-3.0", "AceConsole-3.0")

DynamicBar.name = ADDON_NAME

-- Standarized constants
DynamicBar.CONST = {
  BAG_DEBOUNCE_SEC = 0.15,
  RETRY_DELAY_SEC = 0.35,
  MAX_PENDING_RETRIES = 6,

  BUTTON_SIZE = 36,
  FLYOUT_BASE_LEVEL = 20,
  BAR_BASE_LEVEL = 100,
}

-- AceDB defaults (SavedVariables: DynamicBarDB)
local DB_DEFAULTS = {
  profile = {
    enabled = true,
    debug = false,

    -- UI state for config panel
    _showAdvancedPosition = false,

    -- one bar, 10 buttons by default
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

--
-- Printing helpers
--
-- NOTE: These are intentionally tolerant of both `DynamicBar:Print("x")` and
-- `DynamicBar.Print("x")` (dot-call) because some modules call them with dot.
function DynamicBar:Print(msg)
  if msg == nil then msg = self end
  DEFAULT_CHAT_FRAME:AddMessage("|cffffd200DynamicBar:|r " .. tostring(msg))
end

function DynamicBar:DPrint(msg)
  if msg == nil then msg = self end
  if self.db and self.db.profile and self.db.profile.debug then
    self:Print("|cff99ccffDEBUG:|r " .. tostring(msg))
  end
end

--
-- Rebuild orchestration
--
DynamicBar._needsRebuild = false
function DynamicBar:RequestRebuild(reason)
  self._needsRebuild = true
  self:DPrint("Rebuild requested" .. (reason and (": " .. reason) or ""))
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
    DynamicBar:DPrint("Bag cache rebuilt")
  end
end

local function ScheduleBagRefresh()
  if not (DynamicBar.db and DynamicBar.db.profile and DynamicBar.db.profile.enabled) then
    return
  end

  if DynamicBar._bagTimer then return end
  DynamicBar._bagTimer = true

  C_Timer.After(0.15, function()
    DynamicBar._bagTimer = nil

    RebuildBagCache()

    -- If items are still pending classification due to late tooltip text, schedule
    -- a bounded follow-up refresh.
    local cls = DynamicBar.Data and DynamicBar.Data.Classifier
    local cache = DynamicBar.Data and DynamicBar.Data.BagCache
    local pending = 0

    if cls and cache and cls.CountPendingInBagCache then
      pending = cls:CountPendingInBagCache(cache)
    end

    DynamicBar:DPrint(("Pending items after scan: %d (retry %d/%d)"):format(
      pending,
      DynamicBar._pendingRetryCount,
      DynamicBar._pendingRetryMax
    ))

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

    DynamicBar:RequestRebuild("bags")
  end)
end

function DynamicBar:Rebuild(reason)
  if not (self.db and self.db.profile and self.db.profile.enabled) then
    return
  end

  if InCombatLockdown() then
    self._needsRebuild = true
    self:DPrint("Rebuild deferred (combat)" .. (reason and (": " .. reason) or ""))
    return
  end

  self._needsRebuild = false
  self:DPrint("Rebuild executing" .. (reason and (": " .. reason) or ""))

  -- IMPORTANT: Never schedule a rebuild *from inside* Rebuild().
  -- That creates an out-of-combat infinite rebuild loop.
  if self.UI and self.UI.Rebuild then
    self.UI:Rebuild()
  end
end

--
-- Ace lifecycle
--
function DynamicBar:OnInitialize()
  -- SavedVariables: DynamicBarDB
  self.db = LibStub("AceDB-3.0"):New("DynamicBarDB", DB_DEFAULTS, true)

  -- Expose DB_DEFAULTS for config panel reset functions
  self.DB_DEFAULTS = DB_DEFAULTS

  -- TEMP COMPAT: legacy code expects DynamicBarDB.profile.*
  self:ApplyProfileCompat()

  -- Profile callbacks (Step 4)
  self:InitProfileCallbacks()

  -- Commands
  self:RegisterChatCommand("dbar", "HandleSlash")
  self:RegisterChatCommand("dynamicbar", "HandleSlash")

  if self.db.profile.enabled then
    self:Print("Loaded. (/dbar)")
  else
    self:Print("Loaded (disabled). (/dbar enable)")
  end

  if self.InitConfig then
    self:InitConfig()
  end
end


function DynamicBar:OnEnable()
  -- Events
  self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnPlayerEnteringWorld")
  self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnPlayerRegenEnabled")
  self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnPlayerRegenDisabled")
  self:RegisterEvent("BAG_UPDATE", "OnBagUpdate")
  self:RegisterEvent("PLAYERBANKSLOTS_CHANGED", "OnBagUpdate")
  self:RegisterEvent("BANKFRAME_OPENED", "OnBagUpdate")
  self:RegisterEvent("BANKFRAME_CLOSED", "OnBagUpdate")
  self:RegisterEvent("SPELLS_CHANGED", "OnSpellsChanged")
  self:RegisterEvent("GET_ITEM_INFO_RECEIVED", "OnItemInfoReceived")

  -- Initialize button skinning system
  if self.UI and self.UI.Skins then
    self.UI.Skins:Initialize()
    self:DPrint("Button skin: " .. (self.UI.Skins:GetActiveSkinName() or "Unknown"))
  end

  -- Initial build
  RebuildBagCache()
  ScheduleBagRefresh()
end

--
-- Event handlers
--
function DynamicBar:OnPlayerEnteringWorld()
  ScheduleBagRefresh()
end

function DynamicBar:OnPlayerRegenEnabled()
  if self._needsRebuild then
    self:Rebuild("combat ended")
  end
end

function DynamicBar:OnPlayerRegenDisabled()
  -- Combat started - hide all flyouts for clean combat UX
  if self.UI and self.UI.Flyouts and self.UI.Flyouts.HideAllImmediate then
    self.UI.Flyouts:HideAllImmediate(self.UI)
  end
end

function DynamicBar:OnBagUpdate()
  local ok, err = pcall(ScheduleBagRefresh)
  if not ok then
    self:Print("Error scheduling bag refresh: " .. tostring(err))
  end
end

function DynamicBar:OnSpellsChanged()
  self:RequestRebuild("spells")
  ScheduleBagRefresh()
end

function DynamicBar:OnItemInfoReceived()
  ScheduleBagRefresh()
end

--
-- AceConsole slash handler
--
function DynamicBar:HandleSlash(input)
  local msg = (input or ""):lower()

  if msg == "" or msg == "help" then
    self:Print("Commands:")
    self:Print("  /dbar enable  - enable the addon")
    self:Print("  /dbar disable - disable the addon")
    self:Print("  /dbar debug   - toggle debug logging")
    self:Print("  /dbar config  - open general settings")
    self:Print("  /dbar profiles - open profile management")
    self:Print("  /dbar dump    - dump bag/classifier/resolver state (debug on)")
    self:Print("  /dbar pending - list pending items (debug on)")
    self:Print("  /dbar rebuild - force rebuild (out of combat)")
    return
  end
  if msg == "config" or msg == "options" then
    if self.OpenConfig then
      self:OpenConfig()
    else
      self:Print("Config UI not loaded.")
    end
    return
  end
  if msg == "profiles" or msg == "profile" then
    local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)
    if AceConfigDialog then
      AceConfigDialog:Open("DynamicBar_Profiles")
    else
      self:Print("AceConfigDialog not loaded.")
    end
    return
  end

  if msg == "dump" then
    if self.Debug and self.Debug.Dump then
      self.Debug:Dump()
    else
      self:Print("Debug module not available.")
    end
    return
  end

  if msg == "pending" then
    if self.Debug and self.Debug.DumpPending then
      self.Debug:DumpPending()
    else
      self:Print("Debug module not available.")
    end
    return
  end

  if msg == "enable" then
    self.db.profile.enabled = true
    self:Print("Enabled.")
    ScheduleBagRefresh()
    self:RequestRebuild("enabled")
    return
  end

  if msg == "disable" then
    self.db.profile.enabled = false
    self:Print("Disabled (UI hiding comes later).")
    return
  end

  if msg == "debug" then
    self.db.profile.debug = not self.db.profile.debug
    self:Print("Debug " .. (self.db.profile.debug and "ON" or "OFF"))
    return
  end

  if msg == "rebuild" then
    self:Rebuild("slash")
    return
  end

  self:Print("Unknown command. Use /dbar help")
end

function DynamicBar:ApplyProfileCompat()
  -- Keep legacy reads working: DynamicBarDB.profile.*
  if type(_G.DynamicBarDB) == "table" then
    _G.DynamicBarDB.profile = self.db.profile
  end
end

--[[
  DEPRECATED-REMOVE: QueueRebuildOutOfCombat() and OnRegenEnabled_Rebuild()

  These functions create a duplicate PLAYER_REGEN_ENABLED event handler that conflicts
  with the existing OnPlayerRegenEnabled() handler (line 195). This causes double rebuilds
  when exiting combat and introduces complexity with _waitingForRegen flag management.

  The existing OnPlayerRegenEnabled() + _needsRebuild flag pattern already handles
  combat-deferred rebuilds correctly. Use RequestRebuild() directly instead, which
  automatically defers rebuilds during combat via the _needsRebuild flag.

  Search for "DEPRECATED-REMOVE" to find all marked code for future deletion.
]]--

--[[
function DynamicBar:QueueRebuildOutOfCombat(reason)
  if InCombatLockdown and InCombatLockdown() then
    self._deferredRebuildReason = reason or "deferred"
    -- one-shot: register if not already registered
    if not self._waitingForRegen then
      self._waitingForRegen = true
      self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnRegenEnabled_Rebuild")
    end
    if self.db and self.db.profile and self.db.profile.debug then
      self:Print("Rebuild deferred until out of combat.")
    end
    return
  end

  -- out of combat: do it now
  if ScheduleBagRefresh then ScheduleBagRefresh() end
  if self.RequestRebuild then
    self:RequestRebuild(reason or "rebuild")
  else
    -- fallback if RequestRebuild is not present (should be present in your project)
    if self.Rebuild then self:Rebuild(reason or "rebuild") end
  end
end

function DynamicBar:OnRegenEnabled_Rebuild()
  self:UnregisterEvent("PLAYER_REGEN_ENABLED")
  self._waitingForRegen = false

  local reason = self._deferredRebuildReason or "regen"
  self._deferredRebuildReason = nil

  self:QueueRebuildOutOfCombat(reason)
end
]]--

function DynamicBar:InitProfileCallbacks()
  -- AceDB callbacks fire on profile swap/copy/reset
  self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileEvent")
  self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileEvent")
  self.db.RegisterCallback(self, "OnProfileReset", "OnProfileEvent")
end

function DynamicBar:OnProfileEvent()
  self:ApplyProfileCompat()
  ScheduleBagRefresh()
  self:RequestRebuild("profile")
end


-- End of Core.lua
