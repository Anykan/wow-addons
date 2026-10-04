--[[
  Menu.lua — das kleine selbstgebaute Dropdown-Menü (Zahnrad, Minimap-Rechtsklick).

  Selbstgebaut aus demselben Grund wie bei anderen Forever-Addons: Die
  eingebauten Dropdown-Elemente sind auf den Builds dieses Clients nicht
  einheitlich. (Wird später durch das Einstellungsfenster ersetzt, Anforderung F.)
]]

local _, ns = ...
local C = ns.Config
local L = ns.L
local M = C.MENU

local menu, catcher
local menuLines = {}

local function buildMenu()
  catcher = CreateFrame('Button', nil, UIParent)
  catcher:SetAllPoints(UIParent)
  catcher:SetFrameStrata('FULLSCREEN')
  catcher:RegisterForClicks('AnyUp')
  catcher:SetScript('OnClick', function() menu:Hide() end)
  catcher:Hide()

  menu = CreateFrame('Frame', M.NAME, UIParent, BackdropTemplateMixin and 'BackdropTemplate' or nil)
  menu:SetFrameStrata('FULLSCREEN_DIALOG')
  menu:SetClampedToScreen(true)
  ns.backdrop(menu, M.BACKDROP_ALPHA)
  menu:SetScript('OnHide', function() catcher:Hide() end)
  menu:Hide()
  if UISpecialFrames then table.insert(UISpecialFrames, M.NAME) end
end

local function menuLine(i)
  local line = menuLines[i]
  if line then return line end
  line = CreateFrame('Button', nil, menu)
  line:SetHeight(M.LINE_H)
  line:SetPoint('TOPLEFT', M.PADDING, -M.PADDING - (i - 1) * M.LINE_H)
  line:SetPoint('RIGHT', -M.PADDING, 0)
  line.check = line:CreateTexture(nil, 'ARTWORK')
  line.check:SetTexture(C.TEXTURE.CHECK)
  line.check:SetSize(M.CHECK_SIZE, M.CHECK_SIZE)
  line.check:SetPoint('LEFT')
  line.text = line:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  line.text:SetPoint('LEFT', M.TEXT_X, 0)
  local hl = line:CreateTexture(nil, 'HIGHLIGHT')
  hl:SetAllPoints()
  hl:SetTexture(C.TEXTURE.FLAT)
  hl:SetVertexColor(1, 1, 1, M.HIGHLIGHT_ALPHA)
  menuLines[i] = line
  return line
end

function ns.showMenu(anchor, items)
  if not menu then buildMenu() end
  if menu:IsShown() and menu.anchor == anchor then menu:Hide() return end
  menu.anchor = anchor

  local function fill()
    local width = M.MIN_WIDTH
    for i, item in ipairs(items) do
      local line = menuLine(i)
      local text = type(item.text) == 'function' and item.text() or item.text
      line.text:SetText(text)
      if item.title then
        line.text:SetTextColor(unpack(C.TITLE_COLOR))
        line:Disable()
      else
        line.text:SetTextColor(unpack(C.WHITE))
        line:Enable()
      end
      if item.checked and item.checked() then line.check:Show() else line.check:Hide() end
      line:SetScript('OnClick', function()
        item.click()
        if item.close then menu:Hide() else fill() end
      end)
      line:Show()
      local w = line.text:GetStringWidth() + M.WIDTH_EXTRA
      if w > width then width = w end
    end
    for i = #items + 1, #menuLines do menuLines[i]:Hide() end
    menu:SetSize(width, #items * M.LINE_H + 2 * M.PADDING)
  end

  fill()
  menu:ClearAllPoints()
  menu:SetPoint('TOPLEFT', anchor, 'BOTTOMLEFT', 0, M.ANCHOR_Y)
  catcher:Show()
  menu:Show()
end

-- Bausteine für Menüeinträge -------------------------------------------------------------

local function toggle(key)
  return function() ns.db[key] = not ns.db[key] ns.applyLook() ns.updateMinimap() ns.refresh() end
end
local function checked(key)
  return function() return ns.db[key] end
end
local function cycle(key, values)
  local db = ns.db
  local at = 1
  for i, v in ipairs(values) do if db[key] == v then at = i break end end
  db[key] = values[at % #values + 1]
end
local function cycler(label, key, values, suffix, mult)
  return {
    text = function() return label .. ': ' .. math.floor(ns.db[key] * (mult or 1) + 0.5) .. (suffix or '') end,
    click = function() cycle(key, values) ns.applyLook() ns.refresh() end,
  }
end

-- Einträge des Einstellungsmenüs
ns.SETTINGS = {
  { text = function() return L.MENU_TITLE end, title = true, click = function() end },
  { text = function() return string.format(L.MENU_ROLE, ns.roleName()) end, click = function() ns.toggleRole() end },
  { text = function() return L.MENU_LOCK end, checked = checked('locked'), click = toggle('locked') },
  { text = function() return L.MENU_COMBAT_ONLY end, checked = checked('combatOnly'), click = toggle('combatOnly') },
  { text = function() return L.MENU_GROUP_ONLY end, checked = checked('groupOnly'), click = toggle('groupOnly') },
  { text = function() return L.MENU_SHOW_ALL end, checked = checked('showAll'), click = toggle('showAll') },
  { text = function() return L.MENU_HIGHLIGHT end, checked = checked('highlightTarget'), click = toggle('highlightTarget') },
  { text = function() return L.MENU_SOUND end, checked = checked('sound'), click = toggle('sound') },
  { text = function() return L.MENU_DEBUG end, checked = checked('debug'), click = function() ns.toggleDebug() end },
  cycler(L.MENU_BACKGROUND, 'alpha', M.ALPHA_STEPS, '%', M.PERCENT),
  cycler(L.MENU_SCALE, 'scale', M.SCALE_STEPS, '%', M.PERCENT),
  { text = function() return L.MENU_MINIMAP end, checked = checked('minimap'), click = toggle('minimap') },
  { text = function() return L.MENU_TEST end, checked = function() return ns.state.testMode end,
    click = function() ns.state.testMode = not ns.state.testMode ns.db.shown = true ns.refresh() end },
  { text = function() return L.MENU_RESET end, click = function() ns.resetPlace() end, close = true },
}
