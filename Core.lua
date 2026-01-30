-- Core.lua (TBC Classic)
-- Ace3 bootstrap for DynamicBar.

local ADDON_NAME = ...

-- Ace3 addon instance (object)
local AceAddon = LibStub("AceAddon-3.0")
DynamicBar = AceAddon:NewAddon("DynamicBar", "AceEvent-3.0", "AceConsole-3.0")

-- Localization
local L = LibStub("AceLocale-3.0"):GetLocale("DynamicBar")

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

    -- one bar, 12 buttons by default (matches current SLOT_ORDER count with Flask + Rejuvenation Potion)
    bar = {
      buttons = 12,
      scale = 1.0,

      -- Custom slot priority order (used when buttons < 12, or when enableCustomSlotOrder = true)
      -- nil = use default SLOT_ORDER; array of slot keys = user's priority
      slotOrder = nil,
      enableCustomSlotOrder = false,  -- Show reorder UI even at 12 buttons

      -- Layout mode selection
      layoutMode = "HORIZONTAL",  -- HORIZONTAL | VERTICAL | GRID

      -- Grid dimensions (only used when layoutMode = "GRID")
      gridRows = 2,
      gridCols = 5,

      -- Spacing (separate horizontal/vertical for grid layouts)
      spacingH = 2,  -- Horizontal spacing between buttons
      spacingV = 2,  -- Vertical spacing between buttons (grid/vertical modes)

      -- Per-edge padding
      padLeft = 2,
      padRight = 2,
      padTop = 2,
      padBottom = 2,

      -- Backward compatibility (deprecated, use spacingH and pad* instead)
      spacing = 2,   -- Maps to spacingH
      padding = 2,   -- Maps to padLeft/padRight

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
  self:DPrint("Rebuild scheduled" .. (reason and (": " .. reason) or ""))
  -- Use _inCombat flag instead of InCombatLockdown() to avoid race condition
  -- where InCombatLockdown() may still return false briefly after PLAYER_REGEN_DISABLED fires
  if not self._inCombat then
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
    DynamicBar:DPrint("ScheduleBagRefresh: skipped (addon disabled)")
    return
  end

  if DynamicBar._bagTimer then
    DynamicBar:DPrint("ScheduleBagRefresh: skipped (_bagTimer already set)")
    return
  end
  DynamicBar._bagTimer = true
  DynamicBar:DPrint("ScheduleBagRefresh: timer started")

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
    self:DPrint("Rebuild queued (in combat)" .. (reason and (": " .. reason) or ""))
    return
  end

  self._needsRebuild = false
  self:DPrint("Bar updated" .. (reason and (": " .. reason) or ""))

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
    self:Print(L["Loaded. (/dbar)"])
  else
    self:Print(L["Loaded (disabled). (/dbar enable)"])
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
  self:RegisterEvent("SPELL_UPDATE_COOLDOWN", "OnCooldownUpdate")
  self:RegisterEvent("BAG_UPDATE_COOLDOWN", "OnCooldownUpdate")

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
            self:Print(L["Bar unlocked! Drag it to your preferred position, then click 'Save & Lock'"])
            -- Mark setup complete after user clicks "Position Now"
            self.db.profile._setupComplete = true
          end,
          OnCancel = function()
            self:Print(L["Using default position. Use /dbar config to reposition later."])
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
    self:DPrint("Rebuild triggered (combat ended)")
    self._needsRebuild = false
    self:RequestRebuild("pending_from_combat")
  end
end

function DynamicBar:OnPlayerRegenDisabled()
  self:DPrint("Entering battle mode (combat started)")

  -- Combat started - hide all flyouts for clean combat UX
  if self.UI and self.UI.Flyouts and self.UI.Flyouts.HideAllImmediate then
    self.UI.Flyouts:HideAllImmediate(self.UI)
  end

  -- Set _inCombat BEFORE rebuild so GetCurrentMode() returns "battle"
  -- This must happen before Rebuild() reads the mode
  self._inCombat = true

  -- Request rebuild to apply battle mode visibility
  -- Use InCombatLockdown() here since it may still be false briefly
  if not InCombatLockdown() then
    self:Rebuild("combat_enter")
  else
    self._needsRebuild = true
    self:DPrint("Rebuild queued (combat already locked)")
  end
end

function DynamicBar:OnBagUpdate()
  self:DPrint("BAG_UPDATE fired, _bagTimer=" .. tostring(self._bagTimer))

  -- In-combat: rebuild cache synchronously, then update visuals
  -- Must rebuild BEFORE visual update so counts are current
  if InCombatLockdown() then
    if self.Data and self.Data.BagCache then
      self.Data.BagCache:Rebuild()
    end
    if self.UI and self.UI.UpdateButtonsInCombat then
      self.UI:UpdateButtonsInCombat()
    end
    return  -- Skip scheduled refresh, we just did a sync rebuild
  end

  -- Out of combat: use throttled refresh + full UI rebuild
  -- Reset retry counter on fresh BAG_UPDATE (not retries) so new items get classified
  self._pendingRetryCount = 0

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

function DynamicBar:OnCooldownUpdate()
  -- Update cooldown displays on all buttons
  if self.UI and self.UI.Actions and self.UI.Actions.UpdateAllCooldowns then
    self.UI.Actions:UpdateAllCooldowns()
  end
end

--
-- AceConsole slash handler
--
function DynamicBar:HandleSlash(input)
  local msg = (input or ""):lower()

  if msg == "" or msg == "help" then
    self:Print(L["Commands:"])
    self:Print(L["  /dbar enable  - enable the addon"])
    self:Print(L["  /dbar disable - disable the addon"])
    self:Print(L["  /dbar debug   - toggle debug logging"])
    self:Print(L["  /dbar config  - open general settings"])
    self:Print(L["  /dbar profiles - open profile management"])
    self:Print(L["  /dbar profileinfo - show current profile name and setup status"])
    self:Print(L["  /dbar dump    - dump bag/classifier/resolver state (debug on)"])
    self:Print(L["  /dbar pending - list pending items (debug on)"])
    self:Print(L["  /dbar debuglog - show persistent debug log (last 100 entries)"])
    self:Print(L["  /dbar clearlog - clear persistent debug log"])
    self:Print(L["  /dbar rebuild - force rebuild (out of combat)"])
    return
  end
  if msg == "config" or msg == "options" then
    if self.OpenConfig then
      self:OpenConfig()
    else
      self:Print(L["Config UI not loaded."])
    end
    return
  end
  if msg == "profiles" or msg == "profile" then
    local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)
    if AceConfigDialog then
      AceConfigDialog:Open("DynamicBar_Profiles")
    else
      self:Print(L["AceConfigDialog not loaded."])
    end
    return
  end

  if msg == "dump" then
    if self.Debug and self.Debug.Dump then
      self.Debug:Dump()
    else
      self:Print(L["Debug module not available."])
    end
    return
  end

  if msg == "pending" then
    if self.Debug and self.Debug.DumpPending then
      self.Debug:DumpPending()
    else
      self:Print(L["Debug module not available."])
    end
    return
  end

  if msg == "enable" then
    self.db.profile.enabled = true
    self:Print(L["Enabled."])
    ScheduleBagRefresh()
    self:RequestRebuild("enabled")
    return
  end

  if msg == "disable" then
    self.db.profile.enabled = false
    self:Print(L["Disabled (UI hiding comes later)."])
    return
  end

  if msg == "debug" then
    self.db.profile.debug = not self.db.profile.debug
    self:Print("Debug " .. (self.db.profile.debug and L["Debug ON"] or L["Debug OFF"]))
    return
  end

  if msg == "rebuild" then
    self:Rebuild("slash")
    return
  end

  if msg == "resetsetup" then
    self.db.profile._setupComplete = false
    self:Print(L["First-time setup flag reset. Popup will show in 8 seconds..."])
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

  self:Print(L["Unknown command. Use /dbar help"])
end

function DynamicBar:ApplyProfileCompat()
  -- Keep legacy reads working: DynamicBarDB.profile.*
  if type(_G.DynamicBarDB) == "table" then
    _G.DynamicBarDB.profile = self.db.profile
  end
end

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
