--[[
  List.lua — die Zeilen im TWF-Fenster und der regelmäßige Neuaufbau (refresh).

  Zeilen sind einfache, nicht-sichere Buttons: nur Anzeige und Tooltip, kein
  Klick-zum-Anvisieren. Sie werden nach Position wiederverwendet wie in einer
  normalen dynamischen Liste und bei jedem refresh() neu gefüllt und
  positioniert – bei nicht-sicheren Frames ist das auch im Kampf erlaubt.
]]

local _, ns = ...
local C = ns.Config
local L = ns.L
local ROW = C.ROW

ns.rows = {}

-- Farben des Zustands aus der Tabelle im Reiter Nameplates (Anforderung V): Balken und
-- Aggro-%-Text der Zeile sehen aus wie am Nameplate-Balken (Anforderung AG).
local function stateColors(colorName)
  local st = ns.plateState(colorName)
  return (st and st.color) or C.COLOR[colorName] or C.COLOR.yellow, (st and st.threatColor) or C.WHITE
end

local function rowTooltip(row)
  local e = row.entry
  if not e then return end
  local TC = C.TOOLTIP_COLOR
  GameTooltip:SetOwner(row, 'ANCHOR_RIGHT')
  pcall(GameTooltip.AddLine, GameTooltip, e.name or '?')
  if ns.db.role == 'tank' then
    if e.color == 'red' then
      GameTooltip:AddLine(L.TT_TANK_RED, unpack(TC.red))
    elseif e.color == 'yellow' then
      GameTooltip:AddLine(L.TT_TANK_YELLOW, unpack(TC.yellow))
    elseif e.color == 'brown' then
      GameTooltip:AddLine(L.TT_TANK_BROWN, unpack(TC.brown))
    else
      GameTooltip:AddLine(L.TT_TANK_GREEN, unpack(TC.green))
    end
  else
    if e.color == 'red' then
      GameTooltip:AddLine(L.TT_DPS_RED, unpack(TC.red))
    elseif e.color == 'yellow' then
      GameTooltip:AddLine(L.TT_DPS_YELLOW, unpack(TC.yellow))
    else
      GameTooltip:AddLine(L.TT_DPS_GREEN, unpack(TC.green))
    end
  end
  GameTooltip:Show()
end

-- Zeile = Balken wie an den Nameplates (Anforderung AG): Farbe des Zustands, Füllung = Leben
-- des Gegners. Darauf von links: Schlachtzugsymbol, Aggro-% bzw. Vorsprung, Rollensymbol des
-- Aggro-Halters, Name. Blinken übernimmt die Liste nicht (Nutzer 2026-10-18).
local function buildRow(i)
  local frame = ns.frame
  local row = CreateFrame('Button', nil, frame.body)
  row:EnableMouse(true)
  row:SetScript('OnEnter', function(self) rowTooltip(self) end)
  row:SetScript('OnLeave', function() GameTooltip:Hide() end)

  row.bar = ns.makeCastBar(row)
  row.bar:SetPoint('TOPLEFT', ROW.BAR_INSET, -ROW.BAR_INSET)
  row.bar:SetPoint('BOTTOMRIGHT', -ROW.BAR_INSET, ROW.BAR_INSET)
  row.bar:SetMinMaxValues(0, 1)
  row.bar:SetValue(1)

  -- Texte und Symbole über dem Balkenrahmen
  local over = CreateFrame('Frame', nil, row.bar)
  over:SetAllPoints(row.bar)
  over:SetFrameLevel(row.bar:GetFrameLevel() + 2)
  row.over = over

  row.mark = ns.createRaidMark(over, ROW.MARK_SIZE)

  row.pct = over:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  row.pct:SetDrawLayer('OVERLAY', ROW.TEXT_LAYER)
  row.pct:SetWidth(ROW.PCT_W)
  row.pct:SetJustifyH('RIGHT')

  -- Aggro-Ziel (Anforderung L): Rollensymbol des Halters vor dem Mobnamen
  row.sym = over:CreateTexture(nil, 'OVERLAY')
  row.sym:SetSize(C.SYMBOL_LAYOUT.LIST_SIZE, C.SYMBOL_LAYOUT.LIST_SIZE)

  row.name = over:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  row.name:SetDrawLayer('OVERLAY', ROW.TEXT_LAYER)
  row.name:SetPoint('RIGHT', over, 'RIGHT', ROW.NAME_RIGHT, 0)
  row.name:SetJustifyH('LEFT')
  row.name:SetWordWrap(false)

  -- Pulsierender Rahmen um die Zeile deines aktuellen Ziels (gemeinsam mit den Nameplates)
  row.glow = ns.createGlow(row, ROW.GLOW)

  ns.rows[i] = row
  return row
end

local function setTargetHighlight(row, on)
  if on then ns.setGlowColor(row.glow, ns.db.highlightColor or ROW.GLOW.COLOR) end
  ns.setGlow(row.glow, on)
end

function ns.layoutRow(row, i)
  local db, frame = ns.db, ns.frame
  local h = db.rowHeight
  row:ClearAllPoints()
  row:SetHeight(h)
  row:SetPoint('TOPLEFT', frame, 'TOPLEFT', ROW.PADDING, -(C.WINDOW.HEADER_H + ROW.PADDING + (i - 1) * (h + ROW.SPACING)))
  row:SetPoint('RIGHT', frame, 'RIGHT', -ROW.PADDING, 0)
  if row.name.SetTextScale then row.name:SetTextScale(db.textScale) end
end

-- Live-Aggro-% der Zeile (Anforderung X). Der Wert ist über nameplateN geheim, aber live:
-- nur an den Text weiterreichen, nie vergleichen. Kein Wert → Feld leer, die Zeile bleibt.
-- Hat der Gegner gerade keine Nameplate (e.fresh = false), zeigt der Token evtl. auf einen
-- anderen Gegner: dann den zuletzt gemerkten Wert behalten.
local function threatValue(e)
  if e.testPct ~= nil then return e.testPct end
  local tr = e.track
  if tr and not e.fresh then return tr.lastPct end
  local pct
  -- Tank-Modus mit "Vorsprung in der Liste": Vorsprung vor Platz 2 (Anforderung Z)
  if ns.db.listLead then pct = ns.leadValue(e.unit) end
  if pct == nil and e.unit then
    local ok, _, _, value = pcall(UnitDetailedThreatSituation, 'player', e.unit)
    if ok then pct = value end
  end
  if tr then tr.lastPct = pct end
  return pct
end

-- Balken + Inhalt einer Zeile. Abgeschaltete bzw. leere Felder nehmen keinen Platz weg.
local function drawRow(row, e)
  row.entry = e
  local barColor, textColor = stateColors(e.color)
  ns.tintCastBar(row.bar, barColor)

  -- Füllung = Leben (geheim, nur weitergereicht); Testzeilen mit Beispielwert
  if e.testHealth then
    row.bar:SetMinMaxValues(0, 100)
    row.bar:SetValue(e.testHealth)
  elseif not pcall(function()
      row.bar:SetMinMaxValues(0, e.hpMax)
      row.bar:SetValue(e.hp)
    end) then
    row.bar:SetMinMaxValues(0, 1)
    row.bar:SetValue(1)
  end

  local over, left, leftPoint = row.over, row.over, 'LEFT'
  local x = ROW.TEXT_X
  local function place(region)
    region:ClearAllPoints()
    region:SetPoint('LEFT', left, leftPoint, x, 0)
    left, leftPoint, x = region, 'RIGHT', ROW.GAP
  end

  -- 1. Schlachtzugsymbol (Balken-Trick; ohne Symbol kein Platz)
  if ns.setRaidMark(row.mark, e.markIndex) then place(row.mark) end

  -- 2. Aggro-% bzw. Vorsprung in der Aggro-%-Farbe des Zustands
  if ns.db.listThreat then
    row.pct:SetTextColor(textColor[1], textColor[2], textColor[3])
    local pct = threatValue(e)
    -- erst auf "geheim" prüfen: einen geheimen Wert mit nil zu vergleichen ist verboten
    local shown = (ns.IsSecret(pct) or pct ~= nil)
      and pcall(row.pct.SetFormattedText, row.pct, C.NAMEPLATES.THREAT_PCT_FORMAT, pct)
    if not shown then row.pct:SetText('') end
    row.pct:Show()
    place(row.pct)
  else
    row.pct:Hide()
  end

  -- 3. Rollensymbol des Aggro-Halters
  if ns.db.symbolMarks and e.symbol and ns.setSymbolTexture(row.sym, e.symbol) then
    row.sym:Show()
    place(row.sym)
  else
    row.sym:Hide()
  end

  -- 4. Name
  place(row.name)
  row.name:SetPoint('RIGHT', over, 'RIGHT', ROW.NAME_RIGHT, 0)
  if not pcall(row.name.SetText, row.name, e.name or '?') then row.name:SetText('?') end

  -- Dein Ziel: über UnitIsUnit erkannt (der Schlüssel ist bei geheimer GUID der
  -- Nameplate-Token, nicht mehr `target`; Bug B2)
  setTargetHighlight(row, ns.db.highlightTarget and e.isTarget)
  row:Show()
end

function ns.refresh()
  local frame = ns.frame
  if not frame then return end
  local db = ns.db
  local testMode = ns.state.testMode
  local IsSecret = ns.IsSecret

  if testMode then
    -- ns.tracked in Ruhe lassen; unten direkt aus den Testzeilen zeichnen
  else
    ns.collect()
  end

  local hide = not db.shown
  if not testMode and not frame.moving then
    if db.combatOnly and not UnitAffectingCombat('player') then hide = true end
    if db.groupOnly and not IsInGroup() and not IsInRaid() then hide = true end
    if db.instanceOnly and not ns.inInstance() then hide = true end
  end
  if hide then frame:Hide() return end
  frame:Show()

  local list = {}
  if testMode then
    -- So viele Testzeilen wie "Max. Zeilen", damit man die volle Fenstergröße sieht (W);
    -- die Beispiele aus C.TEST_ROWS wiederholen sich dabei
    local n = #C.TEST_ROWS
    for i = 1, db.maxRows do
      local t = C.TEST_ROWS[(i - 1) % n + 1]
      local name = i > n and (t[1] .. ' ' .. i) or t[1]
      -- Die erste Testzeile spielt "dein Ziel", damit man die Hervorhebung sieht
      list[#list + 1] = { name = name, color = t[2], markIndex = t[3], unit = (i == 1) and 'target' or nil,
        isTarget = (i == 1), symbol = t[4], testPct = t[5], testHealth = t[6] }
    end
  else
    for _, t in pairs(ns.tracked) do
      if t.shownColor then
        local okT, isTarget = pcall(UnitIsUnit, t.unit, 'target')
        list[#list + 1] = { name = t.name, color = t.shownColor, markIndex = t.markIndex, unit = t.unit,
          isTarget = t.fresh and okT and ns.plain(isTarget) == true,
          symbol = ns.symbolFor(t.unit), hp = t.hp, hpMax = t.hpMax, fresh = t.fresh, track = t }
      end
    end
    table.sort(list, function(a, b)
      if a.color ~= b.color then return ns.worse(a.color, b.color) end
      -- Sortieren vergleicht Texte, was der Client bei geheimen Namen nicht
      -- erlaubt; ein geheimer Name behält einfach seine Position.
      if IsSecret(a.name) or IsSecret(b.name) then return false end
      return (a.name or '') < (b.name or '')
    end)
  end

  ns.ui.subText:SetText(#list > 0 and tostring(#list) or '')

  -- Höhe nach Zahl der Gegner, zwischen Min. und Max. Zeilen; wächst nach unten (Anforderung W)
  local wanted = math.max(db.minRows, math.min(#list, db.maxRows))
  local height = ns.heightForRows(wanted)
  -- Das Spiel rundet die Höhe auf Bildpunkte: nur bei echter Abweichung neu setzen, und
  -- die Debug-Meldung nur, wenn sich die Zeilenzahl ändert (sonst 5x pro Sekunde)
  if math.abs(frame:GetHeight() - height) > C.WINDOW.HEIGHT_TOLERANCE then frame:SetHeight(height) end
  if frame.twfRows ~= wanted then
    frame.twfRows = wanted
    ns.dbg('SETTING', 'Fensterhöhe für ' .. wanted .. ' Zeilen')
  end

  local rows = ns.rows
  local shown = math.min(#list, db.maxRows)
  for i = 1, shown do
    local row = rows[i] or buildRow(i)
    if not row.laidOut then ns.layoutRow(row, i) row.laidOut = true end
    drawRow(row, list[i])
  end
  for i = shown + 1, #rows do
    rows[i].entry = nil
    rows[i]:Hide()
  end

  frame.empty:SetText(#list == 0 and (testMode and '' or L.EMPTY) or '')
end
