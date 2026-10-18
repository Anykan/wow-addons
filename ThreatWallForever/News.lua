--[[
  News.lua — Fenster "Was ist neu?" (Anforderung AF).

  Erscheint einmal nach einem Update (oder als "Willkommen" bei der ersten Installation),
  ein paar Sekunden nach dem Login und nie im Kampf. Inhalt: Kurzfassung aller Versionen,
  die neueste oben, scrollbar; Versionen seit dem letzten Besuch sind als "neu" markiert.
  OK oder X: gesehen, bis zur nächsten Version. /twf news öffnet es jederzeit.
]]

local _, ns = ...
local C = ns.Config
local L = ns.L
local NW = C.NEWS
local D = C.DIALOG
local W = C.WINDOW

local win, content, lines = nil, nil, {}

-- Locale-Schlüssel der Kurzfassung einer Version ("0.5" → NEWS_0_5)
local function newsKey(version) return 'NEWS_' .. version:gsub('%.', '_') end

-- Index einer Version in der Liste (1 = neueste), nil = unbekannt
local function indexOf(version)
  for i, v in ipairs(NW.VERSIONS) do if v == version then return i end end
end

local function hex(c) return string.format('|cff%02x%02x%02x', c[1] * 255, c[2] * 255, c[3] * 255) end

local function addLine(text, font, y, gap)
  local fs = content:CreateFontString(nil, 'OVERLAY', font)
  fs:SetPoint('TOPLEFT', 0, y - (gap or 0))
  fs:SetWidth(content:GetWidth())
  fs:SetJustifyH('LEFT')
  fs:SetWordWrap(true)
  fs:SetSpacing(NW.LINE_SPACING)
  fs:SetText(text)
  lines[#lines + 1] = fs
  return y - (gap or 0) - fs:GetStringHeight()
end

-- Inhalt neu schreiben. lastSeen = zuletzt gesehene Version (nil = unbekannt)
local function fillContent(welcome, lastSeen)
  for _, fs in ipairs(lines) do fs:Hide() end
  wipe(lines)
  local y = 0
  if welcome then
    y = addLine(L.NEWS_WELCOME, 'GameFontHighlight', y)
    y = y - NW.VERSION_GAP
  end
  local seenIdx = lastSeen and indexOf(lastSeen)
  for i, v in ipairs(NW.VERSIONS) do
    local text = L[newsKey(v)]
    if text then
      local isNew = not welcome and (seenIdx and i < seenIdx or (not seenIdx and i == 1))
      local head = hex(C.TITLE_COLOR) .. string.format(L.NEWS_VERSION, v) .. '|r'
      if isNew then head = head .. '  ' .. hex(NW.NEW_COLOR) .. L.NEWS_NEW .. '|r' end
      y = addLine(head, 'GameFontNormal', y, i > 1 and NW.VERSION_GAP or 0)
      y = addLine(text, 'GameFontHighlightSmall', y, NW.HEAD_GAP)
    end
  end
  content:SetHeight(-y + D.PADDING)
end

local function markSeen()
  ns.db.newsSeen = ns.VERSION
  ns.dbg('SETTING', 'Neuigkeiten gesehen: ' .. tostring(ns.VERSION))
end

local function build()
  win = ns.makeDialog(NW.NAME, NW.WIDTH, L.NEWS_TITLE)
  win:SetPoint('CENTER', 0, NW.OFFSET_Y)
  win:SetHeight(NW.HEIGHT)
  win:SetScript('OnHide', markSeen)   -- OK und X zählen gleich

  local top = W.HEADER_H + NW.TOP_GAP
  local bottom = D.PADDING + D.BUTTON_H + NW.BUTTON_GAP
  local okT, scroll = pcall(CreateFrame, 'ScrollFrame', nil, win, 'UIPanelScrollFrameTemplate')
  if not okT then scroll = CreateFrame('ScrollFrame', nil, win) end
  scroll:SetPoint('TOPLEFT', D.PADDING, -top)
  scroll:SetPoint('BOTTOMRIGHT', -(D.PADDING + (okT and NW.SCROLLBAR_W or 0)), bottom)
  -- Mausrad scrollt immer (auch ohne Vorlage mit Schiebeleiste)
  scroll:EnableMouseWheel(true)
  scroll:SetScript('OnMouseWheel', function(self, delta)
    local max = self:GetVerticalScrollRange()
    local v = math.max(0, math.min(max, self:GetVerticalScroll() - delta * NW.WHEEL_STEP))
    self:SetVerticalScroll(v)
  end)
  content = CreateFrame('Frame', nil, scroll)
  content:SetSize(NW.WIDTH - 2 * D.PADDING - (okT and NW.SCROLLBAR_W or 0), 1)
  scroll:SetScrollChild(content)
  win.scroll = scroll

  local ok = ns.makeFlatButton(win, L.NEWS_OK, NW.OK_W)
  ok:SetPoint('BOTTOM', 0, D.PADDING)
  ok:SetScript('OnClick', function() win:Hide() end)
end

-- Fenster zeigen. welcome = erste Installation; lastSeen = zuletzt gesehene Version
function ns.showNews(welcome, lastSeen)
  if not win then build() end
  fillContent(welcome, lastSeen)
  win.scroll:SetVerticalScroll(0)
  win:Show()
end

-- Nach dem Login: warten, bis kein Kampf und kein Hinweis-Popup offen ist
local function showWhenFree(welcome, lastSeen)
  local hint = _G[C.HINT.NAME]
  if InCombatLockdown() or UnitAffectingCombat('player') or (hint and hint:IsShown()) then
    C_Timer.After(NW.RETRY, function() showWhenFree(welcome, lastSeen) end)
    return
  end
  ns.dbg('SETTING', 'Neuigkeiten-Fenster: ' .. (welcome and 'Willkommen' or ('Update seit ' .. tostring(lastSeen))))
  ns.showNews(welcome, lastSeen)
end

ns.RegisterModule('News', {
  OnLogin = function()
    local db = ns.db
    if db.newsSeen == ns.VERSION then return end
    -- Erste Installation: Willkommen. Update von einer Version ohne dieses Fenster (≤ 0.4):
    -- newsSeen fehlt → nur die aktuelle Version als neu markieren.
    local welcome = ns.freshInstall and true or false
    local lastSeen = db.newsSeen
    C_Timer.After(NW.DELAY, function() showWhenFree(welcome, lastSeen) end)
  end,
})
