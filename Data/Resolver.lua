-- Data/Resolver.lua
-- Chooses the best itemID for a given “smart” category.

local DB = DynamicBar
DB.Data = DB.Data or {}
DB.Data.Resolver = DB.Data.Resolver or {}
local Resolver = DB.Data.Resolver

function Resolver:FindBestPlainFood()
  local cache = DB.Data and DB.Data.BagCache
  local cls = DB.Data and DB.Data.Classifier
  if not cache or not cls then return nil end

  local bestID = nil
  local bestHealth = -1

  for i = 1, #cache.items do
    local itemID = cache.items[i]
    if (cache.counts[itemID] or 0) > 0 then
      local info = cls:InspectItem(itemID)

      -- If pending (item tooltip not ready), skip now; it will resolve after cache warms up.
      if info and info.isFood and not info.pending then
        if info.health > bestHealth then
          bestHealth = info.health
          bestID = itemID
        end
      end
    end
  end

  return bestID
end
