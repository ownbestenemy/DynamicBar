-- Data/Classifier.lua
-- Cached tooltip classifier (English client).
-- Tags: Food (non-buff), Food (buff/Well Fed), Drink, Bandage, Quest-use.
-- Extracts: health/mana/bandageHeal where possible.

local DB = DynamicBar
DB.Data = DB.Data or {}
DB.Data.Classifier = DB.Data.Classifier or {}
local Classifier = DB.Data.Classifier

Classifier.cache = Classifier.cache or {} -- itemID -> info

local function DBG(msg)
  if DynamicBar and DynamicBar.DPrint then
    DynamicBar.DPrint(msg)
  else
    print(msg)
  end
end

local TIP_NAME = "DynamicBarScanTooltip"
local tip = CreateFrame("GameTooltip", TIP_NAME, UIParent, "GameTooltipTemplate")
tip:SetOwner(UIParent, "ANCHOR_NONE")

local function EmptyInfo()
  return {
    pending = false,

    _final = false,

    isFood = false,
    isFoodBuff = false,
    isDrink = false,
    isBandage = false,
    isQuestUse = false,

    health = 0,
    mana = 0,
    bandageHeal = 0,

    hasUse = false,
    isWellFed = false,
  }
end

local function TooltipLines()
  local lines = {}
  for i = 1, 30 do
    local fs = _G[TIP_NAME .. "TextLeft" .. i]
    if not fs then break end
    local t = fs:GetText()
    if t and t ~= "" then
      lines[#lines + 1] = t
    end
  end
  return lines
end

local function JoinedLower(lines)
  return (table.concat(lines, "\n")):lower()
end

local function Has(j, needle)
  return j:find(needle, 1, true) ~= nil
end

local function ParseRestores(j, kind) -- kind = "health" or "mana"
  local n = j:match("restores%s+(%d+)%s+" .. kind)
  return n and tonumber(n) or 0
end

local function ParseBandageHeal(j)
  local n = j:match("heals%s+(%d+)%s+damage")
  return n and tonumber(n) or 0
end

local function GetTypeInfo(itemID, classID, subClassID)
  -- Prefer GetItemInfo() strings on English client; use instant as fallback.
  local itemType, itemSubType = select(6, GetItemInfo(itemID))

  if not itemType or not itemSubType then
    -- Classic-family fallback: classID 0 = Consumable, subClassID 5 = Food & Drink
    if classID == 0 and subClassID == 5 then
      itemType, itemSubType = "Consumable", "Food & Drink"
    end
  end

  return itemType, itemSubType
end

function Classifier:InspectItem(itemID)
  local cached = self.cache[itemID]
  if cached and not cached.pending and cached._final then
    return cached
  end

  local _, _, _, _, _, classID, subClassID = GetItemInfoInstant(itemID)

  -- Hard exclude: Recipes (prevents false positives)
  if classID == 9 then
    local info = EmptyInfo()

    -- Mark as final once we have any meaningful classification or usable text.
    info._final = (info.isFood or info.isFoodBuff or info.isDrink or info.isBandage or info.isQuestUse
      or info.hasUse or info.isWellFed or info.health > 0 or info.mana > 0 or isEating or isDrinking)

    self.cache[itemID] = info
    return info
  end

  -- Tooltip scan
  tip:ClearLines()
  tip:SetItemByID(itemID)
  local lines = TooltipLines()
  if #lines == 0 then
    GetItemInfo(itemID)
    self.cache[itemID] = cached or {}
    self.cache[itemID].pending = true
    self.cache[itemID].pendingReason = "TooltipLines=0 (tooltip not ready)"
    return self.cache[itemID]
  end


  local j               = JoinedLower(lines)
  local info            = EmptyInfo()

  -- Common flags
  info.hasUse           = Has(j, "use:")
  info.isWellFed        = Has(j, "well fed")
  local isEating        = Has(j, "must remain seated while eating")
  local isDrinking      = Has(j, "must remain seated while drinking")
  info.isBattleElixir   = j:find("battle elixir", 1, true) ~= nil
  info.isGuardianElixir = j:find("guardian elixir", 1, true) ~= nil

  -- Restores parsing
  local restoresHealth  = Has(j, "restores") and Has(j, "health")
  local restoresMana    = Has(j, "restores") and Has(j, "mana")

  if restoresHealth then info.health = ParseRestores(j, "health") end
  if restoresMana then info.mana = ParseRestores(j, "mana") end

  -- Bandage parsing
  if Has(j, "heals") and Has(j, "over") and Has(j, "sec") then
    info.bandageHeal = ParseBandageHeal(j)
    if info.bandageHeal > 0 and Has(j, "damage") then
      info.isBandage = true
    end
  end

  -- Type gating (prevents potions showing as food, etc.)
  local itemType, itemSubType = GetTypeInfo(itemID, classID, subClassID)

  -- Robust pending: on some clients the first tooltip render contains only the item name.
  -- For Food & Drink, if we don't see Use:/restores/seated text yet, treat as pending so we rescan.
  if (classID == 0 and subClassID == 5) then
    if (not info.hasUse) and (not isEating) and (not isDrinking) and (not restoresHealth) and (not restoresMana) and (not info.isWellFed) and (not info.isBandage) then
      info.pending = true
      info.pendingReason = info.pendingReason or "FoodDrink tooltip incomplete (no Use/restores yet)"
      self.cache[itemID] = info
      return info
    end
  end

  -- Never classify potions as food/drink (they can match "restores health")
  if itemType == "Consumable" and itemSubType == "Potion" then
    self.cache[itemID] = info
    return info
  end

  local isFoodDrink = (itemType == "Consumable" and itemSubType == "Food & Drink") or isEating or isDrinking

  if isFoodDrink then
    if info.isWellFed then
      info.isFoodBuff = true
    else
      if restoresHealth and not restoresMana then
        info.isFood = true
      end
    end

    if restoresMana and not info.isWellFed then
      info.isDrink = true
    end
  end

  -- Quest-use: quest item + usable
  if info.hasUse and Has(j, "quest item") then
    info.isQuestUse = true
  end

  -- Mark as final once we've made a determination or captured meaningful tooltip signals.
  if not info.pending then
    if info.isFood or info.isFoodBuff or info.isDrink or info.isBandage or info.isQuestUse or info.hasUse or info.isWellFed or restoresHealth or restoresMana or isEating or isDrinking then
      info._final = true
    end
  end

  -- Finalization: only mark as final once we have meaningful information (prevents caching an empty scan forever).
  info._final = (info.pending ~= true) and
  (info.isFood or info.isFoodBuff or info.isDrink or info.isBandage or info.isQuestUse or info.hasUse or info.isWellFed or restoresHealth or restoresMana or isEating or isDrinking)

  self.cache[itemID] = info
  return info
end

-- Counts how many items currently in the bag cache are still pending classification.
-- Used to drive a bounded retry loop after bag refreshes (no infinite timers).
function Classifier:CountPendingInBagCache(cache)
  local pending = 0
  if not cache or not cache.items then return 0 end
  for i = 1, #cache.items do
    local itemID = cache.items[i]
    if (cache.counts[itemID] or 0) > 0 then
      local info = self:InspectItem(itemID)
      if info and info.pending then
        pending = pending + 1
      end
    end
  end
  return pending
end

function Classifier:DebugDumpPending()
  local n = 0

  for itemID, info in pairs(self.cache or {}) do
    if info and info.pending then
      n = n + 1
      local link = select(2, GetItemInfo(itemID)) or ("item:" .. tostring(itemID))

      DBG(("PENDING #%d: itemID=%s link=%s reason=%s"):format(
        n, tostring(itemID), tostring(link), tostring(info.pendingReason or "unknown")
      ))
    end
  end

  if n == 0 then
    (DB.DPrint or print)("No pending items in Classifier.cache.")
  end
end

function Classifier:Reset()
  for k in pairs(self.cache) do self.cache[k] = nil end
end
