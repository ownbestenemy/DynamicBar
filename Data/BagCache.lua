-- Data/BagCache.lua
-- Minimal bag cache: itemID -> totalCount

local DB = DynamicBar
DB.Data = DB.Data or {}
DB.Data.BagCache = DB.Data.BagCache or {}
local BagCache = DB.Data.BagCache

BagCache.counts = BagCache.counts or {}

local function Clear(t)
  for k in pairs(t) do t[k] = nil end
end

function BagCache:Rebuild()
  Clear(self.counts)

  -- Bags 0..4 are backpack + bags (Classic-family)
  for bag = 0, 4 do
    local slots = GetContainerNumSlots(bag)
    for slot = 1, slots do
      local link = GetContainerItemLink(bag, slot)
      if link then
        local itemID = tonumber(string.match(link, "item:(%d+)"))
        if itemID then
          local _, itemCount = GetContainerItemInfo(bag, slot)
          itemCount = itemCount or 1
          self.counts[itemID] = (self.counts[itemID] or 0) + itemCount
        end
      end
    end
  end
end

function BagCache:GetCount(itemID)
  return self.counts[itemID] or 0
end

function BagCache:Has(itemID)
  return (self.counts[itemID] or 0) > 0
end
