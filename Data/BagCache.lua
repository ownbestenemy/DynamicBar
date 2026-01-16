-- Data/BagCache.lua
-- Bag cache: counts[itemID] and ordered items[]

local DB = DynamicBar
DB.Data = DB.Data or {}
DB.Data.BagCache = DB.Data.BagCache or {}
local BagCache = DB.Data.BagCache

BagCache.counts = BagCache.counts or {}
BagCache.items  = BagCache.items  or {}

local Container = C_Container

local function ClearMap(t)
  for k in pairs(t) do t[k] = nil end
end

local function ClearArray(t)
  for i = #t, 1, -1 do t[i] = nil end
end

local function GetNumSlots(bag)
  return (Container and Container.GetContainerNumSlots(bag)) or 0
end

local function GetItemLink(bag, slot)
  return Container and Container.GetContainerItemLink(bag, slot)
end

local function GetStackCount(bag, slot)
  local info = Container and Container.GetContainerItemInfo(bag, slot)
  return (info and info.stackCount) or 1
end

function BagCache:Rebuild()
  ClearMap(self.counts)
  ClearArray(self.items)

  local seen = {}

  for bag = 0, 4 do
    local slots = GetNumSlots(bag)
    for slot = 1, slots do
      local link = GetItemLink(bag, slot)
      if link then
        local itemID = tonumber(link:match("item:(%d+)"))
        if itemID then
          local count = GetStackCount(bag, slot)
          self.counts[itemID] = (self.counts[itemID] or 0) + count

          if not seen[itemID] then
            seen[itemID] = true
            self.items[#self.items + 1] = itemID
          end
        end
      end
    end
  end
end

function BagCache:FindFirst(candidates)
  for i = 1, #candidates do
    local id = candidates[i]
    if (self.counts[id] or 0) > 0 then
      return id, self.counts[id]
    end
  end
  return nil, 0
end

function BagCache:GetCount(itemID)
  return self.counts[itemID] or 0
end

function BagCache:Has(itemID)
  return (self.counts[itemID] or 0) > 0
end

function BagCache:RebuildIfPossible()
  self:Rebuild()
end
