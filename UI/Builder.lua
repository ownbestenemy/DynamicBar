-- UI/Builder.lua
-- Bar Builder: drag categories onto the bar, reorder them, drag them off.
-- Plain (insecure) frames only. The window closes when combat starts, since
-- the bar can't be rebuilt in combat anyway.

local DB = DynamicBar
DB.UI = DB.UI or {}
local UI = DB.UI
UI.Builder = UI.Builder or {}
local Builder = UI.Builder
local L = LibStub("AceLocale-3.0"):GetLocale("DynamicBar")

-- Cache global functions (WoW Forever uses the Mainline API, which only has the C_Item versions)
local GetItemInfoInstant = GetItemInfoInstant or (C_Item and C_Item.GetItemInfoInstant)

local BACKDROP_TEMPLATE = BackdropTemplateMixin and "BackdropTemplate" or nil
local ROW_H, ROW_GAP = 30, 2
local STEP = ROW_H + ROW_GAP
local TILE_W = 230
local PAD = 6  -- inset of the first tile inside a panel
local FALLBACK_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

-- Icon shown for a category when you carry none of its items
local ICON_ITEMS = {
  HEALTHSTONE = 22105, HEALTH_POT = 22829, MANA_POT = 22832, REJUV_POT = 22850,
  BANDAGE = 21991, BATTLE_ELIX = 22831, GUARD_ELIX = 22834, FLASK = 22854,
  FOOD_BUFF = 27658, FOOD_OTHER = 27854, DRINK = 27860, HEARTH = 6948,
  OTHER_BUFF = 1177,
}

-- =========================================================
-- Slot list editing
-- =========================================================
local function Cats() return DB.Data.Categories end
local function BarConfig() return DB.db and DB.db.profile and DB.db.profile.bar end

function Builder:GetSlots()
  return Cats():GetSlots(BarConfig())
end

-- Categories not on the bar, in default order
function Builder:GetAvailable()
  local onBar = {}
  for _, key in ipairs(self:GetSlots()) do onBar[key] = true end
  local out = {}
  for _, key in ipairs(Cats().DEFAULT_ORDER) do
    if not onBar[key] then out[#out + 1] = key end
  end
  return out
end

function Builder:IndexOf(key)
  for i, k in ipairs(self:GetSlots()) do
    if k == key then return i end
  end
end

function Builder:Save(slots)
  BarConfig().slots = slots
  DB:RequestRebuild("builder")
  self:Refresh()
end

-- Drop `key` into the gap before slot `index` (1 .. #slots + 1, counted on the
-- current bar), adding it if it isn't on the bar yet. No index appends.
function Builder:Place(key, index)
  if not Cats().Registry[key] then return end
  local current = self:GetSlots()
  local old = self:IndexOf(key)
  index = index or #current + 1
  if old and index > old then index = index - 1 end

  local slots = {}
  for _, k in ipairs(current) do
    if k ~= key then slots[#slots + 1] = k end
  end
  index = math.max(1, math.min(index, #slots + 1))
  table.insert(slots, index, key)
  self:Save(slots)
end

-- The bar keeps at least one slot
function Builder:Remove(key)
  local slots = {}
  for _, k in ipairs(self:GetSlots()) do
    if k ~= key then slots[#slots + 1] = k end
  end
  if #slots == 0 or #slots == #self:GetSlots() then return false end
  self:Save(slots)
  return true
end

function Builder:Move(key, delta)
  local i = self:IndexOf(key)
  if not i then return end
  local j = i + delta
  if j < 1 or j > #self:GetSlots() then return end
  self:Place(key, delta > 0 and j + 1 or j)
end

function Builder:Reset()
  local slots = {}
  for i, k in ipairs(Cats().DEFAULT_ORDER) do slots[i] = k end
  self:Save(slots)
end

-- =========================================================
-- Tiles
-- =========================================================
-- Best carried item for a category, or nil
local function BestItem(def)
  local resolver = DB.Data and DB.Data.Resolver
  local fn = resolver and resolver[def.resolver]
  if type(fn) ~= "function" then return nil end
  local ok, itemID = pcall(fn, resolver)
  return ok and itemID or nil
end

local function ItemIcon(itemID)
  if not itemID or not GetItemInfoInstant then return nil end
  return select(5, GetItemInfoInstant(itemID))
end

local function SetPanelBackdrop(frame)
  if not frame.SetBackdrop then return end
  frame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
  })
  frame:SetBackdropColor(0, 0, 0, 0.6)
  frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
end

local function ShowTileTooltip(tile)
  local def = Cats().Registry[tile.key]
  if not def or not GameTooltip then return end
  GameTooltip:SetOwner(tile, "ANCHOR_RIGHT")
  GameTooltip:AddLine(def.name)
  if tile.onBar then
    GameTooltip:AddLine(L["Drag to reorder, or drag off the bar to remove."], 1, 1, 1, true)
    GameTooltip:AddLine(L["Right-click to remove."], 1, 1, 1, true)
  else
    GameTooltip:AddLine(L["Drag onto the bar, or click to add it at the end."], 1, 1, 1, true)
  end
  GameTooltip:Show()
end

local function CreateArrow(tile, direction)
  local b = CreateFrame("Button", nil, tile)
  b:SetSize(18, 18)
  local base = "Interface\\ChatFrame\\UI-ChatIcon-Scroll" .. direction
  b:SetNormalTexture(base .. "-Up")
  b:SetPushedTexture(base .. "-Down")
  b:SetDisabledTexture(base .. "-Disabled")
  b:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
  b:SetScript("OnClick", function()
    Builder:Move(tile.key, direction == "Up" and -1 or 1)
  end)
  return b
end

local function CreateTile(panel, i)
  local tile = CreateFrame("Button", nil, panel)
  tile:SetSize(TILE_W, ROW_H)
  tile:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD + 2, -PAD - (i - 1) * STEP)
  tile:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  tile:RegisterForDrag("LeftButton")
  tile:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")

  tile.icon = tile:CreateTexture(nil, "ARTWORK")
  tile.icon:SetSize(ROW_H - 4, ROW_H - 4)
  tile.icon:SetPoint("LEFT", tile, "LEFT", 2, 0)

  tile.label = tile:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  tile.label:SetPoint("LEFT", tile.icon, "RIGHT", 6, 0)
  tile.label:SetJustifyH("LEFT")

  tile.note = tile:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  tile.note:SetPoint("RIGHT", tile, "RIGHT", -42, 0)
  tile.note:SetJustifyH("RIGHT")

  tile.down = CreateArrow(tile, "Down")
  tile.down:SetPoint("RIGHT", tile, "RIGHT", -2, 0)
  tile.up = CreateArrow(tile, "Up")
  tile.up:SetPoint("RIGHT", tile.down, "LEFT", 0, 0)

  tile:SetScript("OnClick", function(self, button)
    if self.onBar then
      if button == "RightButton" then Builder:Remove(self.key) end
    elseif button == "LeftButton" then
      Builder:Place(self.key)
    end
  end)
  tile:SetScript("OnDragStart", function(self) Builder:StartDrag(self) end)
  tile:SetScript("OnDragStop", function() Builder:EndDrag() end)
  tile:SetScript("OnEnter", ShowTileTooltip)
  tile:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
  return tile
end

local function FillPanel(panel, keys, onBar)
  local count = #keys
  for i, key in ipairs(keys) do
    local tile = panel.tiles[i] or CreateTile(panel, i)
    panel.tiles[i] = tile
    local def = Cats().Registry[key]
    local itemID = BestItem(def)
    tile.key, tile.onBar = key, onBar
    tile.icon:SetTexture(ItemIcon(itemID) or ItemIcon(ICON_ITEMS[key]) or FALLBACK_ICON)
    tile.icon:SetDesaturated(not itemID)
    tile.label:SetText(onBar and ("%d. %s"):format(i, def.name) or def.name)
    tile.note:SetText(itemID and "" or L["None in bags"])
    tile.up:SetShown(onBar)
    tile.down:SetShown(onBar)
    if onBar then
      tile.up:SetEnabled(i > 1)
      tile.down:SetEnabled(i < count)
    end
    tile:Show()
  end
  for i = count + 1, #panel.tiles do
    panel.tiles[i]:Hide()
  end
end

-- =========================================================
-- Dragging
-- =========================================================
local function CursorPosition(region)
  local x, y = GetCursorPosition()
  local scale = region:GetEffectiveScale()
  return x / scale, y / scale
end

-- Gap index under the cursor when it is over the bar panel, else nil
function Builder:DropIndex()
  local panel = self.frame and self.frame.barPanel
  if not panel or not panel:IsMouseOver() then return nil end
  local _, y = CursorPosition(panel)
  local i = math.floor((panel:GetTop() - PAD - y) / STEP + 0.5) + 1
  return math.max(1, math.min(i, #self:GetSlots() + 1))
end

function Builder:StartDrag(tile)
  local f = self.frame
  self.drag = { key = tile.key, fromBar = tile.onBar }
  f.ghost.icon:SetTexture(tile.icon:GetTexture())
  f.ghost.label:SetText(Cats().Registry[tile.key].name)
  f.ghost:Show()
  if GameTooltip then GameTooltip:Hide() end
  f:SetScript("OnUpdate", function() Builder:UpdateDrag() end)
end

function Builder:UpdateDrag()
  local f, drag = self.frame, self.drag
  if not drag then return end
  local x, y = CursorPosition(UIParent)
  f.ghost:ClearAllPoints()
  f.ghost:SetPoint("LEFT", UIParent, "BOTTOMLEFT", x + 12, y)

  local index = self:DropIndex()
  if index then
    f.dropLine:ClearAllPoints()
    f.dropLine:SetPoint("TOPLEFT", f.barPanel, "TOPLEFT", PAD + 2, -PAD - (index - 1) * STEP + ROW_GAP / 2 + 1)
    f.dropLine:Show()
  else
    f.dropLine:Hide()
  end
  -- Red ghost: letting go here takes the slot off the bar
  local removing = drag.fromBar and not index and #self:GetSlots() > 1
  f.ghost.label:SetTextColor(1, removing and 0.3 or 1, removing and 0.3 or 1)
end

function Builder:CancelDrag()
  self.drag = nil
  local f = self.frame
  if not f then return end
  f:SetScript("OnUpdate", nil)
  f.ghost:Hide()
  f.dropLine:Hide()
end

function Builder:EndDrag()
  local drag = self.drag
  if not drag then return end
  local index = self:DropIndex()
  self:CancelDrag()
  if index then
    self:Place(drag.key, index)
  elseif drag.fromBar then
    self:Remove(drag.key)
  end
end

-- =========================================================
-- Window
-- =========================================================
local function CreatePanel(parent, x, height)
  local panel = CreateFrame("Frame", nil, parent, BACKDROP_TEMPLATE)
  panel:SetSize(TILE_W + 2 * PAD + 4, height)
  panel:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -64)
  SetPanelBackdrop(panel)
  panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  panel.title:SetPoint("BOTTOMLEFT", panel, "TOPLEFT", 4, 4)
  panel.tiles = {}
  return panel
end

local function CreateButton(parent, text, width)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(width, 22)
  b:SetText(text)
  return b
end

function Builder:CreateWindow()
  if self.frame then return self.frame end

  local panelW = TILE_W + 2 * PAD + 4
  local panelH = #Cats().DEFAULT_ORDER * STEP + 2 * PAD
  local f = CreateFrame("Frame", "DynamicBarBuilderFrame", UIParent, BACKDROP_TEMPLATE)
  f:SetSize(2 * panelW + 48, panelH + 160)
  f:SetPoint("CENTER")
  f:SetFrameStrata("FULLSCREEN_DIALOG")  -- same layer as the settings window
  f:SetToplevel(true)
  f:SetClampedToScreen(true)
  f:EnableMouse(true)
  f:SetMovable(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function(self) self:StartMoving() end)
  f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
  if f.SetBackdrop then
    f:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
      tile = true, tileSize = 32, edgeSize = 32,
      insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
  end
  if UISpecialFrames then table.insert(UISpecialFrames, "DynamicBarBuilderFrame") end

  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", f, "TOP", 0, -18)
  title:SetText(L["DynamicBar - Bar Builder"])

  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -6)

  f.availPanel = CreatePanel(f, 20, panelH)
  f.availPanel.title:SetText(L["Categories"])
  f.availPanel.empty = f.availPanel:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  f.availPanel.empty:SetPoint("TOP", f.availPanel, "TOP", 0, -16)
  f.availPanel.empty:SetText(L["Every category is on your bar."])

  f.barPanel = CreatePanel(f, 28 + panelW, panelH)

  local hint = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  hint:SetPoint("TOPLEFT", f.availPanel, "BOTTOMLEFT", 2, -10)
  hint:SetPoint("RIGHT", f, "RIGHT", -20, 0)
  hint:SetJustifyH("LEFT")
  hint:SetText(L["Drag categories onto your bar, or click one to add it. Drag a slot to reorder it, or drag it off the bar (or right-click it) to remove it. Each slot is one button; its number is its keybinding."])

  local done = CreateButton(f, L["Done"], 100)
  done:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -20, 18)
  done:SetScript("OnClick", function() f:Hide() end)

  local reset = CreateButton(f, L["Reset to Default Slots"], 170)
  reset:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 20, 18)
  reset:SetScript("OnClick", function() Builder:Reset() end)

  -- Drag feedback
  f.dropLine = f.barPanel:CreateTexture(nil, "OVERLAY")
  f.dropLine:SetSize(TILE_W, 2)
  f.dropLine:SetColorTexture(1, 0.82, 0, 1)
  f.dropLine:Hide()

  f.ghost = CreateFrame("Frame", nil, UIParent)
  f.ghost:SetSize(TILE_W, ROW_H)
  f.ghost:SetFrameStrata("TOOLTIP")
  f.ghost:SetAlpha(0.85)
  f.ghost:EnableMouse(false)
  f.ghost.icon = f.ghost:CreateTexture(nil, "ARTWORK")
  f.ghost.icon:SetSize(ROW_H - 4, ROW_H - 4)
  f.ghost.icon:SetPoint("LEFT", f.ghost, "LEFT", 2, 0)
  f.ghost.label = f.ghost:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  f.ghost.label:SetPoint("LEFT", f.ghost.icon, "RIGHT", 6, 0)
  f.ghost:Hide()

  f:RegisterEvent("PLAYER_REGEN_DISABLED")
  f:SetScript("OnEvent", function(self) self:Hide() end)
  f:SetScript("OnHide", function() Builder:CancelDrag() end)
  f:Hide()

  self.frame = f
  return f
end

function Builder:Refresh()
  local f = self.frame
  if not f or not f:IsShown() then return end
  local slots, available = self:GetSlots(), self:GetAvailable()
  FillPanel(f.barPanel, slots, true)
  FillPanel(f.availPanel, available, false)
  f.barPanel.title:SetText((L["Your bar (%d buttons)"]):format(#slots))
  f.availPanel.empty:SetShown(#available == 0)
end

function Builder:Open()
  if InCombatLockdown() then
    DB:Print(L["The Bar Builder can't be opened in combat."])
    return
  end
  local f = self:CreateWindow()
  f:Show()
  f:Raise()
  self:Refresh()
end

function Builder:Toggle()
  if self.frame and self.frame:IsShown() then
    self.frame:Hide()
  else
    self:Open()
  end
end
