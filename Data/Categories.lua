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
  20004, -- Major Troll's Blood Potion (Guardian)
  3826,  -- Mighty Troll's Blood Potion (Guardian)
  3388,  -- Strong Troll's Blood Potion (Guardian)
  3382,  -- Weak Troll's Blood Potion (Guardian)
  9088,  -- Gift of Arthas (Guardian)
}

-- Buff items with their own slot (kept out of the elixir slots), best first
Cats.OtherBuffs = {
  1177,  -- Oil of Olaf (+armor)
  27500, -- Scroll of Protection V
  27498, -- Scroll of Agility V
  27503, -- Scroll of Strength V
  27502, -- Scroll of Stamina V
  27499, -- Scroll of Intellect V
  27501, -- Scroll of Spirit V
  10305, -- Scroll of Protection IV
  10309, -- Scroll of Agility IV
  10310, -- Scroll of Strength IV
  10307, -- Scroll of Stamina IV
  10308, -- Scroll of Intellect IV
  10306, -- Scroll of Spirit IV
  4421,  -- Scroll of Protection III
  4425,  -- Scroll of Agility III
  4426,  -- Scroll of Strength III
  4422,  -- Scroll of Stamina III
  4419,  -- Scroll of Intellect III
  4424,  -- Scroll of Spirit III
  1478,  -- Scroll of Protection II
  1477,  -- Scroll of Agility II
  2289,  -- Scroll of Strength II
  1711,  -- Scroll of Stamina II
  2290,  -- Scroll of Intellect II
  1712,  -- Scroll of Spirit II
  3013,  -- Scroll of Protection
  3012,  -- Scroll of Agility
  954,   -- Scroll of Strength
  1180,  -- Scroll of Stamina
  955,   -- Scroll of Intellect
  1181,  -- Scroll of Spirit
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
