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

local function SortByFieldDesc(list, cls, field)
  table.sort(list, function(a, b)
    local ia = cls.cache[a]
    local ib = cls.cache[b]
    return ((ia and ia[field]) or 0) > ((ib and ib[field]) or 0)
  end)
end

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

function Resolver:_ResolveElixirByTag(isTagFn)
  local cache = DB.Data and DB.Data.BagCache
  local cls   = DB.Data and DB.Data.Classifier
  local cats  = DB.Data and DB.Data.Categories
  if not cache or not cls or not cats or not cats.AllElixirs then return nil, {} end

  local have = {}
  for i = 1, #cats.AllElixirs do
    local id = cats.AllElixirs[i]
    if (cache.counts[id] or 0) > 0 then
      local info = cls:InspectItem(id)
      if info and not info.pending and isTagFn(info) then
        have[#have + 1] = id
      end
    end
  end

  if #have == 0 then return nil, {} end
  return have[1], have  -- order is Wowhead order unless you later add a priority list
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


function Resolver:ResolveHealthPotion()
  local cats = DB.Data and DB.Data.Categories
  if not cats or not cats.HealthPotions then return nil, {} end
  return ResolveByPriorityList(cats.HealthPotions)
end

function Resolver:ResolveManaPotion()
  local cats = DB.Data and DB.Data.Categories
  if not cats or not cats.ManaPotions then return nil, {} end
  return ResolveByPriorityList(cats.ManaPotions)
end

function Resolver:ResolveFoodNonBuff()
  return Resolve(function(info) return info.isFood end, "health")
end

function Resolver:ResolveFoodBuff()
  return Resolve(function(info) return info.isFoodBuff end, "health")
end

function Resolver:ResolveHealthstone()
  local cats = DB.Data and DB.Data.Categories
  if not cats or not cats.Healthstones then return nil, {} end
  return ResolveByPriorityList(cats.Healthstones)
end

function Resolver:ResolveBandage()
  return Resolve(function(info) return info.isBandage end, "bandageHeal")
end

