-- Debug.lua
-- Centralized debug utilities.

DynamicBar = DynamicBar or {}
DynamicBar.Debug = DynamicBar.Debug or {}
local Debug = DynamicBar.Debug

local function IsDebugOn()
  return DynamicBarDB and DynamicBarDB.profile and DynamicBarDB.profile.debug
end

-- Always-on prefixed print.
function Debug:Print(msg)
  if DynamicBar.Print then
    DynamicBar.Print(msg)
  else
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd200DynamicBar:|r " .. tostring(msg))
  end
end

-- Debug print (gated).
function Debug:DPrint(msg)
  if not IsDebugOn() then return end
  self:Print("|cff99ccffDEBUG:|r " .. tostring(msg))
end

-- Dumps classifier pending items (if any) from Classifier.cache.
function Debug:DumpPending()
  local cls = DynamicBar.Data and DynamicBar.Data.Classifier
  if not cls or type(cls.cache) ~= "table" then
    self:Print("Pending dump unavailable (Classifier not loaded).")
    return
  end

  local n = 0
  for itemID, info in pairs(cls.cache) do
    if info and info.pending then
      n = n + 1
      local link = select(2, GetItemInfo(itemID)) or ("item:" .. tostring(itemID))
      self:DPrint(("PENDING #%d: itemID=%s link=%s reason=%s"):format(
        n,
        tostring(itemID),
        tostring(link),
        tostring(info.pendingReason or "unknown")
      ))
    end
  end

  if n == 0 then
    self:DPrint("No pending items in Classifier.cache.")
  end
end

-- Full dump: BagCache itemIDs + classification flags + resolver picks.
function Debug:Dump()
  local cache = DynamicBar.Data and DynamicBar.Data.BagCache
  local cls   = DynamicBar.Data and DynamicBar.Data.Classifier
  local res   = DynamicBar.Data and DynamicBar.Data.Resolver

  if not cache then self:Print("No BagCache loaded."); return end
  if not cls then self:Print("No Classifier loaded."); return end

  local items = cache.items or {}
  self:Print(("BagCache: %d unique itemIDs"):format(#items))

  for i = 1, #items do
    local itemID = items[i]
    local count = (cache.counts and cache.counts[itemID]) or 0
    local link = select(2, GetItemInfo(itemID)) or ("item:" .. tostring(itemID))

    local info = cls:InspectItem(itemID) or {}
    self:Print(("[%d] %s x%d  food=%s foodBuff=%s drink=%s pending=%s"):format(
      i,
      tostring(link),
      tonumber(count) or 0,
      tostring(info.isFood),
      tostring(info.isFoodBuff),
      tostring(info.isDrink),
      tostring(info.pending)
    ))
  end

  if res and res.ResolveFoodNonBuff and res.ResolveFoodBuff and res.ResolveDrink then
    local foodID = select(1, res:ResolveFoodNonBuff())
    local buffFoodID = select(1, res:ResolveFoodBuff())
    local drinkID = select(1, res:ResolveDrink())
    self:Print(("Resolver picks: food=%s  buffFood=%s  drink=%s"):format(
      tostring(foodID), tostring(buffFoodID), tostring(drinkID)
    ))
  else
    self:Print("No Resolver loaded.")
  end
end

-- Convenience: is debug enabled
function Debug:Enabled()
  return IsDebugOn()
end
