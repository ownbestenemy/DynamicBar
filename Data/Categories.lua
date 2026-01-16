-- Data/Categories.lua
local DB = DynamicBar
DB.Data = DB.Data or {}
DB.Data.Categories = DB.Data.Categories or {}
local Cats = DB.Data.Categories

Cats.HealthPotions = {
  22829, -- Super Healing Potion (TBC)
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
  32068, 22834, 22840, 22848
}


Cats.ManaPotions = {
  22832, -- Super Mana Potion (TBC)
  13444, -- Major Mana Potion
  13443, -- Superior Mana Potion
  6149,  -- Greater Mana Potion
  3827,  -- Mana Potion
  3385,  -- Lesser Mana Potion
  2455,  -- Minor Mana Potion
}

-- ordered highest priority first
Cats.Hearth = {
  6948, -- Hearthstone
}
