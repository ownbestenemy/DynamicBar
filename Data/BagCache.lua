-- Data/BagCache.lua
-- Minimal bag cache: itemID -> totalCount

local DB = DynamicBar
DB.Data = DB.Data or {}
DB.Data.BagCache = DB.Data.BagCache or {}
local BagCache = DB.Data.BagCache

BagCache.counts = BagCache.counts or {}
BagCache.items = BagCache.items or {}

local function Clear(t)
  for k in pairs(t) do t[k] = nil end
end

-- Container API compatibility (Anniversary uses C_Container)
local Container = C_Container

local function ClearArray(t)
  for i = #t, 1, -1 do t[i] = nil end
end

local function GetNumSlots(bag)
  if Container and Container.GetContainerNumSlots then
    return Container.GetContainerNumSlots(bag) or 0
  end
  return GetContainerNumSlots and GetContainerNumSlots(bag) or 0
end

local function GetItemLink(bag, slot)
  if Container and Container.GetContainerItemLink then
    return Container.GetContainerItemLink(bag, slot)
  end
  return GetContainerItemLink and GetContainerItemLink(bag, slot) or nil
end

local function GetItemInfo(bag, slot)
  -- Returns table in C_Container world; older API returns (texture, count, locked, quality, readable, lootable, link)
  if Container and Container.GetContainerItemInfo then
    return Container.GetContainerItemInfo(bag, slot) -- table or nil
  end
  if GetContainerItemInfo then
    local texture, count = GetContainerItemInfo(bag, slot)
    return { iconFileID = texture, stackCount = count }
  end
  return nil
end


function BagCache:FindFirst(candidates)
  -- candidates is an ordered list of itemIDs (highest priority first)
  -- Returns: itemIDFound, countFound
  for i = 1, #candidates do
    local id = candidates[i]
    local c = self.counts[id] or 0
    if c > 0 then return id, c end
  end
  return nil, 0
end



function BagCache:Rebuild()
  Clear(self.counts)
  ClearArray(self.items)

  local seen = {} -- temp set to avoid duplicates in items[]

  for bag = 0, 4 do
    local slots = GetNumSlots and GetNumSlots(bag) or (C_Container and C_Container.GetContainerNumSlots(bag)) or 0
    for slot = 1, slots do
      local link = GetItemLink and GetItemLink(bag, slot) or (C_Container and C_Container.GetContainerItemLink(bag, slot))
      if link then
        local itemID = tonumber(string.match(link, "item:(%d+)"))
        if itemID then
          local info = GetItemInfo and GetItemInfo(bag, slot) or (C_Container and C_Container.GetContainerItemInfo(bag, slot))
          local count = 1

          if type(info) == "table" and info.stackCount then
            count = info.stackCount
          elseif type(info) ~= "table" then
            -- older API shape fallback (rare on your client now)
            count = select(2, info) or 1
          end

          self.counts[itemID] = (self.counts[itemID] or 0) + (count or 1)

          if not seen[itemID] then
            seen[itemID] = true
            self.items[#self.items + 1] = itemID
          end
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

function BagCache:RebuildIfPossible()
  -- Bag APIs are safe in combat, but this gives you a hook if you ever change policy
  self:Rebuild()
end
