-- Data/Classifier.lua
-- Cached item classifier.
-- Tags: Food (non-buff), Food (buff/Well Fed), Drink, Bandage, Quest-use, elixirs, flasks.
-- Extracts: health/mana/bandageHeal where possible, and item level for ranking.
--
-- Signals that don't depend on the client's language come first: item
-- class/subclass IDs, the item's use spell compared with the client's own
-- Food/Drink spell names, Blizzard's localized tooltip strings, and ID lists.
-- The remaining tooltip phrases come from the locale table (Locales/*.lua),
-- so translators can supply them; they default to English.

local DB = DynamicBar
DB.Data = DB.Data or {}
DB.Data.Classifier = DB.Data.Classifier or {}
local Classifier = DB.Data.Classifier

Classifier.cache = Classifier.cache or {} -- itemID -> info

-- Cache global functions (WoW Forever uses the Mainline API, which only has the C_Item versions)
local GetItemInfo = GetItemInfo or (C_Item and C_Item.GetItemInfo)
local GetItemInfoInstant = GetItemInfoInstant or (C_Item and C_Item.GetItemInfoInstant)
local GetItemSpell = GetItemSpell or (C_Item and C_Item.GetItemSpell)
local GetSpellName = (C_Spell and C_Spell.GetSpellName) or function(spellID)
  return GetSpellInfo and (GetSpellInfo(spellID)) or nil
end

local L = LibStub("AceLocale-3.0"):GetLocale("DynamicBar")

-- Consumable subclasses (item class 0), the same numbers on TBC and Mainline
local CONSUMABLE = 0
local SUB_POTION, SUB_ELIXIR, SUB_FLASK, SUB_FOOD_DRINK, SUB_BANDAGE = 1, 2, 3, 5, 7
local CLASS_RECIPE = 9

local ENGLISH = (GetLocale and GetLocale() or "enUS"):match("^en") ~= nil

-- Spells whose localized names identify eating, drinking and the Well Fed buff
local FOOD_SPELLS = { 433, 1127, 1129 }             -- "Food"
local DRINK_SPELLS = { 430, 431, 432, 1133, 1135 }   -- "Drink"
local WELL_FED_SPELLS = { 19705, 33257 }             -- "Well Fed"

local function SpellNameSet(ids)
  local names = {}
  for _, id in ipairs(ids) do
    local name = GetSpellName(id)
    if type(name) == "string" and name ~= "" then names[name] = true end
  end
  return names
end

-- Built on first use: spell names may not be available while the addon loads
local needles
local function Needles()
  if needles then return needles end
  local wellFed = {}
  for name in pairs(SpellNameSet(WELL_FED_SPELLS)) do wellFed[#wellFed + 1] = name:lower() end
  needles = {
    use = (ITEM_SPELL_TRIGGER_ONUSE or "Use:"):lower(),
    quest = (ITEM_BIND_QUEST or "Quest Item"):lower(),
    wellFed = wellFed,
    foodSpells = SpellNameSet(FOOD_SPELLS),
    drinkSpells = SpellNameSet(DRINK_SPELLS),
  }
  return needles
end

local TIP_NAME = "DynamicBarScanTooltip"
local tip = CreateFrame("GameTooltip", TIP_NAME, UIParent, "GameTooltipTemplate")
tip:SetOwner(UIParent, "ANCHOR_NONE")

local function EmptyInfo()
  return {
    itemID = 0,
    pending = false,

    _final = false,

    isFood = false,
    isFoodBuff = false,
    isDrink = false,
    isBandage = false,
    isQuestUse = false,
    isFlask = false,
    isRejuvenationPotion = false,

    health = 0,
    mana = 0,
    bandageHeal = 0,

    hasUse = false,
    isWellFed = false,
  }
end

local function TooltipLines(itemID)
  local lines = {}

  -- Mainline clients (WoW Forever) expose tooltip data directly; no hidden tooltip needed.
  if C_TooltipInfo and C_TooltipInfo.GetItemByID then
    local data = C_TooltipInfo.GetItemByID(itemID)
    if data and data.lines then
      for _, line in ipairs(data.lines) do
        local t = line.leftText
        if type(t) == "string" and t ~= "" then
          lines[#lines + 1] = t
        end
      end
      if #lines > 0 then return lines end
    end
  end

  -- Classic clients: scan the hidden tooltip
  tip:ClearLines()
  tip:SetItemByID(itemID)
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
  local j = (table.concat(lines, "\n")):lower()
  -- Drop thousands separators ("3,500,000" -> "3500000") so amounts parse
  local prev
  repeat
    prev = j
    j = j:gsub("(%d),(%d%d%d)", "%1%2")
  until j == prev
  return j
end

local function Has(j, needle)
  return j:find(needle, 1, true) ~= nil
end

-- A translatable tooltip phrase, lowercased (English when untranslated)
local function Phrase(key)
  return (L[key] or key):lower()
end

-- Escape a phrase for use inside a Lua pattern
local function Literal(text)
  return (text:gsub("%p", "%%%0"))
end

local function ParseRestores(j, kind) -- kind = "health" or "mana"
  local restores, word = Literal(Phrase("restores")), Literal(Phrase(kind))
  -- Match "restores X to Y kind" (range format)
  local _, hi = j:match(restores .. "%s+(%d+)%s+to%s+(%d+)%s+" .. word)
  if hi then return tonumber(hi) end

  -- Match "and X to Y kind" (second resource in rejuv potions)
  _, hi = j:match("and%s+(%d+)%s+to%s+(%d+)%s+" .. word)
  if hi then return tonumber(hi) end

  -- Match "restores X kind" (simple format)
  local n = j:match(restores .. "%s+(%d+)%s+" .. word)
  if n then return tonumber(n) end

  -- Match "and X kind" (simple format for second resource)
  n = j:match("and%s+(%d+)%s+" .. word)
  return n and tonumber(n) or 0
end

local function ParseBandageHeal(j)
  local n = j:match("heals%s+(%d+)%s+damage")
  return n and tonumber(n) or 0
end

-- Is the item's use spell one of these localized spell names?
local function UseSpellIn(itemID, names)
  if not GetItemSpell then return false end
  local spellName = GetItemSpell(itemID)
  return spellName ~= nil and names[spellName] == true
end

local function InList(list, itemID)
  for _, id in ipairs(list or {}) do
    if id == itemID then return true end
  end
  return false
end

function Classifier:InspectItem(itemID)
  local cached = self.cache[itemID]
  if cached and not cached.pending and cached._final then
    return cached
  end

  local classID, subClassID = select(6, GetItemInfoInstant(itemID))
  local consumable = classID == CONSUMABLE

  -- Hard exclude: Recipes (prevents false positives)
  if classID == CLASS_RECIPE then
    local info = EmptyInfo()
    info.itemID = itemID
    info._final = true  -- Recipes are always final (nothing to classify)
    self.cache[itemID] = info
    return info
  end

  -- Tooltip scan. A consumable whose tooltip shows only its name has not loaded
  -- yet (its Use:/elixir lines are missing), so retry it like an empty tooltip.
  local lines = TooltipLines(itemID)
  if #lines == 0 or (consumable and #lines == 1) then
    GetItemInfo(itemID)
    self.cache[itemID] = cached or {}
    self.cache[itemID].itemID = itemID
    self.cache[itemID].pending = true
    self.cache[itemID].pendingReason = "tooltip not ready (" .. #lines .. " lines)"
    return self.cache[itemID]
  end

  local n               = Needles()
  local cats            = DB.Data.Categories or {}
  local j               = JoinedLower(lines)
  local info            = EmptyInfo()
  info.itemID           = itemID
  info.level            = select(4, GetItemInfo(itemID)) or 0

  local isPotion        = consumable and subClassID == SUB_POTION
  local isFoodDrinkType = consumable and subClassID == SUB_FOOD_DRINK

  -- Common flags
  info.hasUse           = Has(j, n.use)
  for _, name in ipairs(n.wellFed) do
    if Has(j, name) then info.isWellFed = true end
  end
  info.isWellFed        = info.isWellFed or Has(j, Phrase("well fed"))
  local isEating        = UseSpellIn(itemID, n.foodSpells) or Has(j, Phrase("must remain seated while eating"))
  local isDrinking      = UseSpellIn(itemID, n.drinkSpells) or Has(j, Phrase("must remain seated while drinking"))
  info.isBattleElixir   = Has(j, Phrase("battle elixir"))
  info.isGuardianElixir = Has(j, Phrase("guardian elixir"))
  info.isFlask          = (consumable and subClassID == SUB_FLASK) or InList(cats.Flasks, itemID) or Has(j, Phrase("flask"))

  -- Restores parsing
  local restores        = Has(j, Phrase("restores"))
  local restoresHealth  = restores and Has(j, Phrase("health"))
  local restoresMana    = restores and Has(j, Phrase("mana"))

  if restoresHealth then info.health = ParseRestores(j, "health") end
  if restoresMana then info.mana = ParseRestores(j, "mana") end

  -- Bandages: the item subclass says so in any language; the heal amount
  -- (English tooltips) only ranks them
  if Has(j, "heals") and Has(j, "over") and Has(j, "sec") then
    info.bandageHeal = ParseBandageHeal(j)
  end
  -- English tooltips also rule out first-aid items that heal nothing (Anti-Venom)
  local bandageText = info.bandageHeal > 0 and Has(j, "damage")
  info.isBandage = bandageText or (consumable and subClassID == SUB_BANDAGE and not ENGLISH)

  -- Robust pending: on some clients the first tooltip render contains only the item name.
  -- For Food & Drink, if we don't see Use:/restores/seated text yet, treat as pending so we rescan.
  if isFoodDrinkType then
    if (not info.hasUse) and (not isEating) and (not isDrinking) and (not restoresHealth) and (not restoresMana) and (not info.isWellFed) and (not info.isBandage) then
      info.pending = true
      info.pendingReason = info.pendingReason or "FoodDrink tooltip incomplete (no Use/restores yet)"
      self.cache[itemID] = info
      return info
    end
  end

  -- Potions: rejuvenation (health AND mana) is a slot of its own; other potions
  -- are never food or drink (they can match "restores health")
  if isPotion then
    info.isPotion = true
    if InList(cats.RejuvenationPotions, itemID) or (restoresHealth and restoresMana) then
      info.isRejuvenationPotion = true
    end
    -- Keep rescanning potions until their Use: line has loaded
    info._final = info.isRejuvenationPotion or info.hasUse
    self.cache[itemID] = info
    return info
  end

  if isFoodDrinkType or isEating or isDrinking then
    if info.isWellFed then
      info.isFoodBuff = true
    elseif (isEating or restoresHealth) and not restoresMana and not isDrinking then
      info.isFood = true
    end

    if (isDrinking or restoresMana) and not info.isWellFed then
      info.isDrink = true
    end
  end

  -- Quest-use: quest item + usable
  if info.hasUse and Has(j, n.quest) then
    info.isQuestUse = true
  end

  -- Mark as final once we have meaningful information (prevents caching an empty scan forever).
  -- Only consumables fill tagged slots, so anything else is done once its tooltip
  -- has loaded; that keeps gear from being rescanned on every resolve.
  info._final = (not info.pending) and ((classID ~= nil and not consumable) or
    info.isFood or info.isFoodBuff or info.isDrink or info.isBandage or info.isQuestUse or
     info.isFlask or info.hasUse or info.isWellFed or restoresHealth or restoresMana or
     isEating or isDrinking)

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

function Classifier:Reset()
  for k in pairs(self.cache) do self.cache[k] = nil end
end
