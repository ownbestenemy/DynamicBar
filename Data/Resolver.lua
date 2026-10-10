-- Data/Resolver.lua
-- Resolvers return: bestItemID, flyoutList (best -> worst)

local DB = DynamicBar
DB.Data = DB.Data or {}
DB.Data.Resolver = DB.Data.Resolver or {}
local Resolver = DB.Data.Resolver

local function GetDeps()
  local cache = DB.Data and DB.Data.BagCache
  local cls   = DB.Data and DB.Data.Classifier
  if not cache or not cls then return nil, nil end
  return cache, cls
end
local function ResolveByPriorityList(list)
  local cache, cls = GetDeps()
  if not cache then return nil, {} end

  local have = {}
  for i = 1, #list do
    local id = list[i]
    if (cache.counts[id] or 0) > 0 then
      have[#have + 1] = id
    end
  end

  if #have == 0 then
    return nil, {}
  end

  return have[1], have
end

-- Resolver for a fixed priority list in Categories (best first)
local function FromCategory(listName)
  return function()
    local cats = DB.Data and DB.Data.Categories
    return ResolveByPriorityList((cats and cats[listName]) or {})
  end
end

Resolver.ResolveHearth       = FromCategory("Hearth")
Resolver.ResolveOtherBuff    = FromCategory("OtherBuffs")

local function Collect(cache, cls, predicate)
  local out = {}
  for i = 1, #cache.items do
    local itemID = cache.items[i]
    if (cache.counts[itemID] or 0) > 0 then
      local info = cls:InspectItem(itemID)
      if info and not info.pending and predicate(info) then
        out[#out + 1] = itemID
      end
    end
  end
  return out
end

-- Strongest first by `field`; item level breaks ties and ranks items whose
-- amounts couldn't be read (non-English tooltips)
local function SortByFieldDesc(list, cls, field)
  table.sort(list, function(a, b)
    local ia, ib = cls.cache[a] or {}, cls.cache[b] or {}
    local fa, fb = ia[field] or 0, ib[field] or 0
    if fa ~= fb then return fa > fb end
    local la, lb = ia.level or 0, ib.level or 0
    if la ~= lb then return la > lb end
    return a < b
  end)
end

-- Listed items first, in list order; then bag items the list doesn't know
-- that the classifier tags for this slot (WoW Forever's modern items, new
-- TBC items), strongest first
local function ListThenTagged(listName, predicate, sortField)
  return function()
    local cache, cls = GetDeps()
    if not cache then return nil, {} end
    local cats = DB.Data.Categories or {}
    local list = cats[listName] or {}
    local _, have = ResolveByPriorityList(list)

    -- Items with a slot of their own never fill this one
    local skip = {}
    for _, name in ipairs({ listName, "AllElixirs", "OtherBuffs", "RejuvenationPotions" }) do
      for _, id in ipairs(cats[name] or {}) do skip[id] = true end
    end
    local extra = Collect(cache, cls, function(info)
      return not skip[info.itemID] and predicate(info)
    end)
    SortByFieldDesc(extra, cls, sortField)
    for _, id in ipairs(extra) do have[#have + 1] = id end

    return have[1], have
  end
end

Resolver.ResolveHealthPotion = ListThenTagged("HealthPotions", function(info)
  return info.isPotion and not info.isRejuvenationPotion and (info.health or 0) > 0 and (info.mana or 0) == 0
end, "health")
Resolver.ResolveManaPotion = ListThenTagged("ManaPotions", function(info)
  return info.isPotion and not info.isRejuvenationPotion and (info.mana or 0) > 0 and (info.health or 0) == 0
end, "mana")
Resolver.ResolveFlask = ListThenTagged("Flasks", function(info)
  return info.isFlask
end, "level")

local function Resolve(predicate, sortField)
  local cache, cls = GetDeps()
  if not cache or not cls then return nil, {} end

  local list = Collect(cache, cls, predicate)
  if #list == 0 then
    return nil, {}
  end

  SortByFieldDesc(list, cls, sortField)
  return list[1], list
end

-- Any bag item whose tooltip carries the tag counts, so elixirs missing from
-- AllElixirs still show up; listed elixirs keep their list order and come first.
-- Items with their own Other Buffs slot are left out even when tagged.
function Resolver:_ResolveElixirByTag(isTagFn)
  local cache, cls = GetDeps()
  if not cache then return nil, {} end
  local cats = DB.Data.Categories or {}
  local known = cats.AllElixirs or {}

  local rank, otherBuff = {}, {}
  for i = 1, #known do rank[known[i]] = i end
  for _, id in ipairs(cats.OtherBuffs or {}) do otherBuff[id] = true end

  local have = Collect(cache, cls, function(info)
    return isTagFn(info) and not info.isFlask and not otherBuff[info.itemID]
  end)
  if #have == 0 then return nil, {} end

  local unknown = #known + 1
  table.sort(have, function(a, b)
    local ra, rb = rank[a] or unknown, rank[b] or unknown
    if ra ~= rb then return ra < rb end
    return a < b
  end)
  return have[1], have
end

function Resolver:ResolveBattleElixir()
  return self:_ResolveElixirByTag(function(info) return info.isBattleElixir end)
end

function Resolver:ResolveGuardianElixir()
  return self:_ResolveElixirByTag(function(info) return info.isGuardianElixir end)
end

function Resolver:ResolveDrink()
  return Resolve(function(info) return info.isDrink end, "mana")
end


function Resolver:ResolveRejuvenationPotion()
  return Resolve(function(info) return info.isRejuvenationPotion end, "health")
end

function Resolver:ResolveFoodNonBuff()
  return Resolve(function(info) return info.isFood end, "health")
end

function Resolver:ResolveFoodBuff()
  return Resolve(function(info) return info.isFoodBuff end, "health")
end

-- Emergency Conversion: Healthstones + Dark Runes
-- Healthstones are prioritized over Dark Runes (runes cost HP)
-- Flyout shows all available emergency items
function Resolver:ResolveHealthstone()
  local cats = DB.Data and DB.Data.Categories
  local cache = DB.Data and DB.Data.BagCache
  if not cats or not cache then return nil, {} end

  -- Build combined priority list: Healthstones first, then Dark Runes
  local combined = {}

  -- Add Healthstones (prioritized - free healing)
  if cats.Healthstones then
    for i = 1, #cats.Healthstones do
      combined[#combined + 1] = cats.Healthstones[i]
    end
  end

  -- Add Dark Runes (secondary - costs HP for mana)
  if cats.DarkRunes then
    for i = 1, #cats.DarkRunes do
      combined[#combined + 1] = cats.DarkRunes[i]
    end
  end

  return ResolveByPriorityList(combined)
end

function Resolver:ResolveBandage()
  return Resolve(function(info) return info.isBandage end, "bandageHeal")
end

