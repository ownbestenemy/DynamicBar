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
    _setupComplete = false,  -- Track if first-time setup has been shown

    -- one bar, 11 buttons by default (matches current SLOT_ORDER count with Flask)
    bar = {
      buttons = 11,
      scale = 1.0,
      spacing = 2,  -- Tighter spacing like Blizzard default
      padding = 2,  -- Tighter padding like Blizzard default
      point = "CENTER",
      relPoint = "CENTER",
      x = 0,
      y = -180,
      visibilityMode = "FADE",  -- How to display unavailable items: FADE, HIDE, GREY, ALWAYS
      buttonDisplayMode = "SMART",  -- How to handle empty slots: STATIC, SMART, DYNAMIC
      inheritElvUI = true,  -- Automatically use ElvUI spacing if available
      locked = true,  -- Bar is locked (not draggable) by default
    },
  },

  -- Global (non-profile) debug log (shared across characters for easier support)
  global = {
    debugLog = {},  -- Array of {timestamp, message} entries
    debugLogMaxEntries = 100,  -- Keep last 100 entries
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
    local message = tostring(msg)
    self:Print("|cff99ccffDEBUG:|r " .. message)

    -- Log to SavedVariables for persistent debugging
    self:LogDebugMessage(message)
  end
end

-- Log debug message to SavedVariables (persistent across sessions)
function DynamicBar:LogDebugMessage(msg)
  if not self.db or not self.db.global then return end

  local log = self.db.global.debugLog
  local maxEntries = self.db.global.debugLogMaxEntries or 100

  -- Add timestamp
  local timestamp = date("%Y-%m-%d %H:%M:%S")
  local entry = {
    time = timestamp,
    message = tostring(msg),
  }

  -- Append to log
  table.insert(log, entry)

  -- Trim to max size (keep last N entries)
  while #log > maxEntries do
    table.remove(log, 1)
  end
end

-- Show debug log to chat
function DynamicBar:ShowDebugLog()
  if not self.db or not self.db.global then
    self:Print("Debug log not available.")
    return
  end

  local log = self.db.global.debugLog or {}
  if #log == 0 then
    self:Print("Debug log is empty. Enable debug mode with /dbar debug")
    return
  end

  self:Print(("=== Debug Log (%d entries) ==="):format(#log))
  for i, entry in ipairs(log) do
    self:Print(("[%d] %s - %s"):format(i, entry.time or "??:??:??", entry.message or ""))
  end
  self:Print("=== End Debug Log ===")
  self:Print("To share with addon author: Copy messages above or check SavedVariables/DynamicBarDB.lua")
end

-- Clear debug log
function DynamicBar:ClearDebugLog()
  if not self.db or not self.db.global then
    self:Print("Debug log not available.")
    return
  end

  local count = #(self.db.global.debugLog or {})
  self.db.global.debugLog = {}
  self:Print(("Debug log cleared (%d entries removed)."):format(count))
end

--
-- Combat state tracking
--
DynamicBar._inCombat = false

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

  -- Force character-specific profile (fixes "Default" profile issue)
  local charKey = UnitName("player") .. " - " .. GetRealmName()
  if self.db:GetCurrentProfile() == "Default" then
    -- If using Default profile, switch to character-specific profile
    -- This ensures each character gets their own _setupComplete flag
    self.db:SetProfile(charKey)
  end

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
-- First-time setup popup
--
function DynamicBar:ShowFirstTimeSetup()
  self:DPrint("ShowFirstTimeSetup called, _setupComplete = " .. tostring(self.db.profile._setupComplete))
  if not self.db.profile._setupComplete then
    self:DPrint("Scheduling popup in 8 seconds...")
    -- Delay popup to avoid conflicts with other addon popups (like ElvUI)
    -- Longer delay (8 seconds) to allow ElvUI setup to complete
    C_Timer.After(8, function()
      -- Check again in case user logged out during delay
      if not self.db.profile._setupComplete then
        StaticPopupDialogs["DYNAMICBAR_FIRST_TIME_SETUP"] = {
          text = "Welcome to DynamicBar!\n\nWould you like to position your consumable bar now?\n\n(You can reposition it anytime via /dbar config)",
          button1 = "Position Now",
          button2 = "Use Default",
          OnAccept = function()
            -- Unlock the bar for positioning
            self.db.profile.bar.locked = false
            if self.UI and self.UI.UpdateLockState then
              self.UI:UpdateLockState()
            end
            self:Print("Bar unlocked! Drag it to your preferred position, then click 'Save & Lock'")
            -- Mark setup complete after user clicks "Position Now"
            self.db.profile._setupComplete = true
          end,
          OnCancel = function()
            self:Print("Using default position. Use /dbar config to reposition later.")
            -- Mark setup complete after user clicks "Use Default"
            self.db.profile._setupComplete = true
          end,
          timeout = 0,
          whileDead = true,
          hideOnEscape = true,
          preferredIndex = 3,
        }
        StaticPopup_Show("DYNAMICBAR_FIRST_TIME_SETUP")
      end
    end)
  end
end

--
-- Event handlers
--
function DynamicBar:OnPlayerEnteringWorld()
  ScheduleBagRefresh()

  -- Show first-time setup on initial login (delayed to avoid ElvUI popup conflicts)
  self:DPrint("PLAYER_ENTERING_WORLD fired, _setupComplete = " .. tostring(self.db.profile._setupComplete))
  self:ShowFirstTimeSetup()
end

function DynamicBar:OnPlayerRegenEnabled()
  -- Set flag BEFORE rebuild to avoid race condition
  self._inCombat = false
  self:DPrint("Entering prep mode (combat ended)")

  -- Rebuild to show prep mode slots
  self:RequestRebuild("combat_leave")

  -- Also process any pending rebuilds from config changes during combat
  if self._needsRebuild then
    self:DPrint("Processing pending rebuild from combat")
    self._needsRebuild = false
    self:RequestRebuild("pending_from_combat")
  end
end

function DynamicBar:OnPlayerRegenDisabled()
  -- Set flag BEFORE rebuild to avoid race condition with InCombatLockdown()
  self._inCombat = true
  self:DPrint("Entering battle mode (combat started)")

  -- Combat started - hide all flyouts for clean combat UX
  if self.UI and self.UI.Flyouts and self.UI.Flyouts.HideAllImmediate then
    self.UI.Flyouts:HideAllImmediate(self.UI)
  end

  -- Rebuild to show battle mode slots only
  self:RequestRebuild("combat_enter")
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
    self:Print("  /dbar profileinfo - show current profile name and setup status")
    self:Print("  /dbar dump    - dump bag/classifier/resolver state (debug on)")
    self:Print("  /dbar pending - list pending items (debug on)")
    self:Print("  /dbar debuglog - show persistent debug log (last 100 entries)")
    self:Print("  /dbar clearlog - clear persistent debug log")
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

  if msg == "resetsetup" then
    self.db.profile._setupComplete = false
    self:Print("First-time setup flag reset. Popup will show in 8 seconds...")
    self:ShowFirstTimeSetup()
    return
  end

  if msg == "profileinfo" or msg == "pinfo" then
    local profileName = self.db:GetCurrentProfile()
    local setupComplete = self.db.profile._setupComplete
    local playerName = UnitName("player")
    local realmName = GetRealmName()
    local expectedProfile = playerName .. " - " .. realmName

    self:Print("Current profile: " .. tostring(profileName))
    self:Print("Expected profile: " .. expectedProfile)
    self:Print("Setup complete: " .. tostring(setupComplete))

    if profileName ~= expectedProfile then
      self:Print("|cffff0000WARNING: Profile mismatch!|r")
    end
    return
  end

  if msg == "debuglog" then
    self:ShowDebugLog()
    return
  end

  if msg == "clearlog" then
    self:ClearDebugLog()
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
