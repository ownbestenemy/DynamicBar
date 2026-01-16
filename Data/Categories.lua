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
