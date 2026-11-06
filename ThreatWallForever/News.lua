--[[
  News.lua — Fenster "Was ist neu?" (Anforderung AF).

  Erscheint einmal nach einem Update (oder als "Willkommen" bei der ersten Installation),
  ein paar Sekunden nach dem Login und nie im Kampf. Das Hinweis-Popup zu den Spiel-Optionen
  (Hint.lua) kommt erst nach OK. Inhalt: Kurzfassung aller Versionen,
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

-- Locale-Schlüssel eines Abschnitts einer Version ("0.5", "NEW" → NEWS_0_5_NEW)
local function newsKey(version, section) return 'NEWS_' .. version:gsub('%.', '_') .. '_' .. section end

-- Index einer Version in der Liste (1 = neueste), nil = unbekannt
local function indexOf(version)
  for i, v in ipairs(NW.VERSIONS) do if v == version then return i end end
end

local function hex(c) return string.format('|cff%02x%02x%02x', c[1] * 255, c[2] * 255, c[3] * 255) end

local function addLine(text, font, y, gap, indent)
  local fs = content:CreateFontString(nil, 'OVERLAY', font)
  fs:SetPoint('TOPLEFT', indent or 0, y - (gap or 0))
  fs:SetWidth(content:GetWidth() - (indent or 0))
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
    -- Allgemein gehalten (Nutzer 2026-10-18): Dank → was TWF kann → So geht's los → Ideen
    local gold = hex(C.TITLE_COLOR)
    y = addLine(gold .. L.NEWS_W_TITLE .. '|r', 'GameFontNormalLarge', y)
    y = addLine(L.NEWS_W_THANKS, 'GameFontHighlight', y, NW.HEAD_GAP)
    y = addLine(L.NEWS_W_INTRO, 'GameFontHighlight', y, NW.SECTION_GAP)
    for i, c in ipairs(NW.WELCOME_COLORS) do
      local text = hex(c) .. L['NEWS_W_P' .. i .. '_T'] .. '|r – ' .. L['NEWS_W_P' .. i]
      y = addLine(text, 'GameFontHighlightSmall', y, i == 1 and NW.SECTION_GAP or NW.HEAD_GAP)
    end
    y = addLine(gold .. L.NEWS_W_START .. '|r', 'GameFontNormal', y, NW.SECTION_GAP)
    local function icon(atlas) return string.format('|A:%s:%d:%d|a', atlas, NW.ICON_SIZE, NW.ICON_SIZE) end
    local s1 = string.format(L.NEWS_W_S1, icon(C.SYMBOLS.TANK), icon(C.SYMBOLS.DAMAGER), icon(C.SYMBOLS.HEALER))
    for _, s in ipairs({ s1, L.NEWS_W_S2 }) do
      y = addLine(NW.BULLET .. s, 'GameFontHighlightSmall', y, NW.HEAD_GAP)
    end
    -- Rückmeldung über CurseForge
    y = addLine(gold .. L.NEWS_W_IDEAS .. '|r', 'GameFontNormal', y, NW.SECTION_GAP)
    y = addLine(L.NEWS_W_IDEAS_TEXT, 'GameFontHighlightSmall', y, NW.HEAD_GAP)
    -- Erste Installation: nur die Beschreibung, keine Versionsliste (Nutzer 2026-10-18)
    content:SetHeight(-y + D.PADDING)
    return
  end
  -- Changelog je Version: Kopf (Gold, ggf. "NEU"), Abschnitte Neu/Geändert/Behoben in ihren
  -- Farben, Punkte "Stichwort – Erklärung" (Stichwort weiß, Erklärung grau), Trennlinie dazwischen
  local seenIdx = lastSeen and indexOf(lastSeen)
  local kw, txt = hex(NW.KEYWORD_COLOR), hex(NW.TEXT_COLOR)
  for i, v in ipairs(NW.VERSIONS) do
    if i > 1 then
      y = y - NW.VERSION_GAP / 2
      local rule = content:CreateTexture(nil, 'ARTWORK')
      rule:SetColorTexture(1, 1, 1, NW.RULE_ALPHA)
      rule:SetHeight(1)
      rule:SetPoint('TOPLEFT', 0, y)
      rule:SetPoint('TOPRIGHT', 0, y)
      lines[#lines + 1] = rule
      y = y - NW.VERSION_GAP / 2
    end
    local isNew = not welcome and (seenIdx and i < seenIdx or (not seenIdx and i == 1))
    local head = hex(C.TITLE_COLOR) .. string.format(L.NEWS_VERSION, v) .. '|r'
    if isNew then head = head .. '  ' .. hex(NW.NEW_COLOR) .. L.NEWS_NEW .. '|r' end
    y = addLine(head, 'GameFontNormal', y)
    -- Hinweis direkt unter dem Kopf, auffällig (z. B. "Spiel komplett neu starten" bei 0.6)
    local note = L[newsKey(v, 'NOTE')]
    if note then y = addLine(hex(NW.NOTE_COLOR) .. note .. '|r', 'GameFontHighlightSmall', y, NW.HEAD_GAP) end
    for _, sec in ipairs(NW.SECTIONS) do
      local text = L[newsKey(v, sec.key)]
      if text then
        y = addLine(hex(sec.color) .. L['NEWS_SEC_' .. sec.key] .. '|r', 'GameFontNormalSmall', y, NW.HEAD_GAP, NW.SECTION_INDENT)
        for item in (text .. '\n'):gmatch('(.-)\n') do
          local a, b = item:match('^(.-)' .. NW.DASH .. '(.*)$')
          local line = a and (kw .. a .. '|r' .. txt .. NW.DASH .. b .. '|r') or (txt .. item .. '|r')
          y = addLine(NW.BULLET .. line, 'GameFontHighlightSmall', y, NW.HEAD_GAP / 2, NW.ITEM_INDENT)
        end
      end
    end
  end
  content:SetHeight(-y + D.PADDING)
end

local function markSeen()
  ns.db.newsSeen = ns.VERSION
  ns.dbg('SETTING', 'Neuigkeiten gesehen: ' .. tostring(ns.VERSION))
  -- Hinweis zu den Spiel-Optionen erst jetzt (beim Login zurückgehalten, Core.lua)
  if ns.newsPending then
    ns.newsPending = false
    ns.checkGameOptions(false)
  end
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
  win.padTop, win.padBottom = top, bottom

  local ok = ns.makeFlatButton(win, L.NEWS_OK, NW.OK_W)
  ok:SetPoint('BOTTOM', 0, D.PADDING)
  ok:SetScript('OnClick', function() win:Hide() end)
end

-- Fenster zeigen. welcome = erste Installation; lastSeen = zuletzt gesehene Version
function ns.showNews(welcome, lastSeen)
  if not win then build() end
  win.titleText:SetText(welcome and L.NEWS_TITLE_WELCOME or L.NEWS_TITLE)
  fillContent(welcome, lastSeen)
  win.scroll:SetVerticalScroll(0)
  -- Willkommen: kurzer Text ohne Schiebeleiste, Fenster so hoch wie der Inhalt.
  -- Changelog: feste Höhe, scrollbar.
  local bar = win.scroll.ScrollBar
  if bar then bar:SetShown(not welcome) end
  if welcome then
    win:SetHeight(win.padTop + content:GetHeight() + win.padBottom)
  else
    win:SetHeight(NW.HEIGHT)
  end
  win:Show()
end

-- Nach dem Login: warten, bis kein Kampf ist (das Hinweis-Popup kommt erst nach OK)
local function showWhenFree(welcome, lastSeen)
  if InCombatLockdown() or UnitAffectingCombat('player') then
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
    ns.newsPending = true   -- Hinweis-Popup (Spiel-Optionen) bis nach OK zurückhalten
    C_Timer.After(NW.DELAY, function() showWhenFree(welcome, lastSeen) end)
  end,
})
