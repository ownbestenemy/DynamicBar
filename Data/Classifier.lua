-- Data/Classifier.lua
-- Cached tooltip classifier (English client).
-- Tags: Food (non-buff), Food (buff/Well Fed), Drink, Bandage, Quest-use.
-- Extracts: health/mana/bandageHeal where possible.

local DB = DynamicBar
DB.Data = DB.Data or {}
DB.Data.Classifier = DB.Data.Classifier or {}
local Classifier = DB.Data.Classifier

Classifier.cache = Classifier.cache or {} -- itemID -> info

local TIP_NAME = "DynamicBarScanTooltip"
local tip = CreateFrame("GameTooltip", TIP_NAME, UIParent, "GameTooltipTemplate")
tip:SetOwner(UIParent, "ANCHOR_NONE")

local function EmptyInfo()
  return {
    pending = false,

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
  if cached and not cached.pending then
    return cached
  end

  local _, _, _, _, _, classID, subClassID = GetItemInfoInstant(itemID)

  -- Hard exclude: Recipes (prevents false positives)
  if classID == 9 then
    local info = EmptyInfo()
    self.cache[itemID] = info
    return info
  end

  -- Tooltip scan
  tip:ClearLines()
  tip:SetItemByID(itemID)

  local lines = TooltipLines()
  if #lines == 0 then
    self.cache[itemID] = cached or { pending = true }
    self.cache[itemID].pending = true
    return self.cache[itemID]
  end

  local j = JoinedLower(lines)
  local info = EmptyInfo()

  -- Common flags
  info.hasUse = Has(j, "use:")
  info.isWellFed = Has(j, "well fed")

  -- Restores parsing
  local restoresHealth = Has(j, "restores") and Has(j, "health")
  local restoresMana   = Has(j, "restores") and Has(j, "mana")

  if restoresHealth then info.health = ParseRestores(j, "health") end
  if restoresMana   then info.mana   = ParseRestores(j, "mana") end

  -- Bandage parsing
  if Has(j, "heals") and Has(j, "over") and Has(j, "sec") then
    info.bandageHeal = ParseBandageHeal(j)
    if info.bandageHeal > 0 and Has(j, "damage") then
      info.isBandage = true
    end
  end

  -- Type gating (prevents potions showing as food, etc.)
  local itemType, itemSubType = GetTypeInfo(itemID, classID, subClassID)

  -- Never classify potions as food/drink (they can match "restores health")
  if itemType == "Consumable" and itemSubType == "Potion" then
    self.cache[itemID] = info
    return info
  end

  local isFoodDrink = (itemType == "Consumable" and itemSubType == "Food & Drink")

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

  self.cache[itemID] = info
  return info
end

function Classifier:Reset()
  for k in pairs(self.cache) do self.cache[k] = nil end
end
