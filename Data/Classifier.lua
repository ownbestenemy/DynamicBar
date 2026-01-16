-- Data/Classifier.lua
-- Tooltip classifier (cached per itemID)
-- Detects "plain food": restores health, not mana, not "Well Fed"

local DB = DynamicBar
DB.Data = DB.Data or {}
DB.Data.Classifier = DB.Data.Classifier or {}
local Classifier = DB.Data.Classifier

Classifier.cache = Classifier.cache or {} -- itemID -> { isFood=true/false, health=number }

local tip = CreateFrame("GameTooltip", "DynamicBarScanTooltip", UIParent, "GameTooltipTemplate")
tip:SetOwner(UIParent, "ANCHOR_NONE")

local function GetTooltipLines()
  local lines = {}
  for i = 1, 30 do
    local fs = _G["DynamicBarScanTooltipTextLeft" .. i]
    if not fs then break end
    local text = fs:GetText()
    if text and text ~= "" then
      lines[#lines + 1] = text
    end
  end
  return lines
end

local function ParseHealthRestored(linesLower)
  -- Typical: "Restores 61 health over 21 sec."
  -- Return first number following "restores"
  for _, line in ipairs(linesLower) do
    local restoresPos = string.find(line, "restores", 1, true)
    if restoresPos then
      local n = string.match(line, "restores%s+(%d+)")
      if n then return tonumber(n) end
    end
  end
  return 0
end

function Classifier:InspectItem(itemID)
  local cached = self.cache[itemID]
  -- If it was pending, try again (tooltips may be ready now)
  if cached and not cached.pending then
    return cached
end


  -- Some items won't be in local cache yet; SetItemByID may show empty initially.
  tip:ClearLines()
  tip:SetItemByID(itemID)

  local lines = GetTooltipLines()
  if #lines == 0 then
    -- Cache not ready; mark as unknown and retry later (don't hard-fail forever).
    self.cache[itemID] = { isFood = false, health = 0, pending = true }
    return self.cache[itemID]
  end

  local joined = table.concat(lines, "\n"):lower()

  -- Exclusions first
  if string.find(joined, "well fed", 1, true) then
    self.cache[itemID] = { isFood = false, health = 0 }
    return self.cache[itemID]
  end

  -- If it restores mana, it's either drink or mixed consumable (exclude)
  if string.find(joined, "mana", 1, true) then
    self.cache[itemID] = { isFood = false, health = 0 }
    return self.cache[itemID]
  end

  -- Must restore health
  if not (string.find(joined, "restores", 1, true) and string.find(joined, "health", 1, true)) then
    self.cache[itemID] = { isFood = false, health = 0 }
    return self.cache[itemID]
  end

  local health = ParseHealthRestored({ joined })
  -- Some tooltips might not match exact pattern; fall back to 1 if it passed the text test
  if not health or health <= 0 then health = 1 end

  self.cache[itemID] = { isFood = true, health = health }
  return self.cache[itemID]
end
