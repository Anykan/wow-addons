--[[
  Menu.lua — das kleine selbstgebaute Dropdown-Menü (heute nur Minimap-Rechtsklick).

  Selbstgebaut aus demselben Grund wie bei anderen Forever-Addons: Die
  eingebauten Dropdown-Elemente sind auf den Builds dieses Clients nicht
  einheitlich. Alle Optionen stehen im Einstellungsfenster (Settings.lua).
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

-- Einträge -------------------------------------------------------------------------------

-- Minimap-Rechtsklick: nur "Fenster fixieren" (Anforderung F)
ns.MINIMAP_MENU = {
  { text = function() return L.MENU_LOCK end, checked = function() return ns.db.locked end,
    click = function()
      ns.db.locked = not ns.db.locked
      ns.dbg('SETTING', 'Fenster fixieren = ' .. tostring(ns.db.locked) .. ' (Minimap-Menü)')
      ns.applyLook() ns.updateMinimap() ns.refresh()
    end },
}
