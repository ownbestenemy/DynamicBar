-- Data/Categories.lua
local DB = DynamicBar
DB.Data = DB.Data or {}
DB.Data.Categories = DB.Data.Categories or {}
local Cats = DB.Data.Categories

Cats.HealthPotions = {
  22829, -- Super Healing Potion
  13446, -- Major Healing Potion
  3928,  -- Superior Healing Potion
  1710,  -- Greater Healing Potion
  929,   -- Healing Potion
  858,   -- Lesser Healing Potion
  118,   -- Minor Healing Potion
}

Cats.AllElixirs = {
  2454, 2457, 6662, 6373, 3390, 3391, 8949, 17708, 9155, 9206, 9187, 21546, 9264,
  9224, 13453, 13452, 13454, 28103, 28102, 22825, 22824, 28104, 22833, 22827, 22831,
  31679, 34537, 22835, 5996, 3828, 10592, 18294, 8529, 9154, 9197, 9233, 22823, 22830,
  5997, 2458, 3383, 3389, 3825, 8951, 9179, 8827, 13445, 13447, 32062, 32063, 32067,
  32068, 22834, 22840, 22848,
  3382,  -- Weak Troll's Blood Potion (Guardian)
}

Cats.Flasks = {
  -- TBC Flasks (Battle - attack power, spell damage, mana regen)
  22861, -- Flask of Blinding Light (+80 Arcane/Holy spell damage, 2hr)
  22866, -- Flask of Pure Death (+80 Shadow/Fire spell damage, 2hr)
  22854, -- Flask of Relentless Assault (+120 Attack Power, 2hr)
  22853, -- Flask of Mighty Restoration (+25 MP5, 2hr)

  -- TBC Flasks (Guardian - stamina, defense, resistances)
  22851, -- Flask of Fortification (+500 HP, 1500 Armor, 2hr)
  22849, -- Flask of Chromatic Wonder (+35 all resist, 2hr)

  -- Classic Flasks (still usable in TBC)
  13510, -- Flask of the Titans (+400 HP, 2hr)
  13511, -- Flask of Distilled Wisdom (+2000 Mana, 2hr)
  13512, -- Flask of Supreme Power (+70 spell damage, 2hr)
  13513, -- Flask of Chromatic Resistance (+25 all resist, 2hr)
}

Cats.Healthstones = {
  22105, -- Master Healthstone
  22104, -- Major Healthstone
  22103, -- Greater Healthstone
  22102, -- Healthstone
  5512,  -- Minor Healthstone
}

-- Emergency Conversion items (mana -> health at a cost)
Cats.DarkRunes = {
  20520, -- Dark Rune (TBC: ~1200 mana, 1000 HP damage to self)
  12662, -- Demonic Rune (Classic: 900-1500 mana, 600-1000 HP damage to self)
}

Cats.ManaPotions = {
  22832, -- Super Mana Potion
  13444, -- Major Mana Potion
  13443, -- Superior Mana Potion
  6149,  -- Greater Mana Potion
  3827,  -- Mana Potion
  3385,  -- Lesser Mana Potion
  2455,  -- Minor Mana Potion
}

Cats.RejuvenationPotions = {
  22850, -- Super Rejuvenation Potion (TBC: 1440-1760 HP + 1440-1760 Mana)
  18253, -- Major Rejuvenation Potion (Classic: 900-1500 HP + 900-1500 Mana)
  2456,  -- Minor Rejuvenation Potion (Classic: 90-150 HP + 90-150 Mana)
}

-- ordered highest priority first
Cats.Hearth = {
  6948, -- Hearthstone
}

-- =========================================================
-- Category registry: every slot type the bar can show.
-- The bar, the settings panel and (later) the Bar Builder all read this.
--   resolver: method name on DB.Data.Resolver
--   battle:   usable in combat (prep-only slots are cleared in combat)
-- =========================================================
local L = LibStub("AceLocale-3.0"):GetLocale("DynamicBar")

Cats.Registry = {
  HEALTHSTONE = { key = "HEALTHSTONE", resolver = "ResolveHealthstone",        battle = true, name = L["Healthstone"] },
  HEALTH_POT  = { key = "HEALTH_POT",  resolver = "ResolveHealthPotion",       battle = true, name = L["Health Potion"] },
  MANA_POT    = { key = "MANA_POT",    resolver = "ResolveManaPotion",         battle = true, name = L["Mana Potion"] },
  REJUV_POT   = { key = "REJUV_POT",   resolver = "ResolveRejuvenationPotion", battle = true, name = L["Rejuv Potion"] },
  BANDAGE     = { key = "BANDAGE",     resolver = "ResolveBandage",            battle = true, name = L["Bandage"] },
  BATTLE_ELIX = { key = "BATTLE_ELIX", resolver = "ResolveBattleElixir",                      name = L["Battle Elixir"] },
  GUARD_ELIX  = { key = "GUARD_ELIX",  resolver = "ResolveGuardianElixir",                    name = L["Guardian Elixir"] },
  FLASK       = { key = "FLASK",       resolver = "ResolveFlask",                             name = L["Flask"] },
  FOOD_BUFF   = { key = "FOOD_BUFF",   resolver = "ResolveFoodBuff",                          name = L["Food (Buff)"] },
  FOOD_OTHER  = { key = "FOOD_OTHER",  resolver = "ResolveFoodNonBuff",                       name = L["Food (Other)"] },
  DRINK       = { key = "DRINK",       resolver = "ResolveDrink",                             name = L["Drink"] },
  HEARTH      = { key = "HEARTH",      resolver = "ResolveHearth",             battle = true, name = L["Hearthstone"] },
}

-- Default bar: every category, urgency first
Cats.DEFAULT_ORDER = {
  "HEALTHSTONE", "HEALTH_POT", "MANA_POT", "REJUV_POT", "BANDAGE",
  "BATTLE_ELIX", "GUARD_ELIX", "FLASK", "FOOD_BUFF", "FOOD_OTHER", "DRINK",
  "HEARTH",
}

-- Copy the valid, non-duplicate keys of `source` (at most `limit` of them)
local function CleanKeys(source, limit)
  local out, seen = {}, {}
  if type(source) ~= "table" then return out end
  for _, key in ipairs(source) do
    if limit and #out >= limit then break end
    if Cats.Registry[key] and not seen[key] then
      seen[key] = true
      out[#out + 1] = key
    end
  end
  return out
end

-- The bar's slots: an ordered list of category keys, one button each.
-- Profiles from 1.x have no `slots`; they used `slotOrder` (or the default
-- order) trimmed to `buttons`, so build the same bar from those once.
-- The old keys are left in SavedVariables untouched.
function Cats:GetSlots(bar)
  if type(bar) ~= "table" then return CleanKeys(self.DEFAULT_ORDER) end

  local slots
  if type(bar.slots) == "table" then
    slots = CleanKeys(bar.slots)
  else
    local source = bar.slotOrder
    if type(source) ~= "table" or #CleanKeys(source) == 0 then
      source = self.DEFAULT_ORDER
    end
    slots = CleanKeys(source, tonumber(bar.buttons) or #self.DEFAULT_ORDER)
  end

  if #slots == 0 then slots = CleanKeys(self.DEFAULT_ORDER) end
  bar.slots = slots
  return slots
end
