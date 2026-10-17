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

-- Punkt in der Farbe, die der Zustand an der Nameplate hat (Tabelle im Reiter Nameplates,
-- Anforderung V); so passen Liste und Balken auch bei eigenen Farben zusammen.
local function setDot(tex, colorName)
  local st = ns.plateState(colorName)
  local c = st and st.color or C.COLOR[colorName] or C.COLOR.yellow
  tex:SetVertexColor(c[1], c[2], c[3])
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

local function buildRow(i)
  local frame = ns.frame
  local row = CreateFrame('Button', nil, frame.body)
  row:EnableMouse(true)
  row:SetScript('OnEnter', function(self) rowTooltip(self) end)
  row:SetScript('OnLeave', function() GameTooltip:Hide() end)

  row.bg = row:CreateTexture(nil, 'BACKGROUND')
  row.bg:SetAllPoints()
  row.bg:SetTexture(C.TEXTURE.FLAT)
  row.bg:SetVertexColor(1, 1, 1, ROW.BG_ALPHA)

  -- Live-Aggro-% ganz links (Anforderung X); der Ampelpunkt rückt dahinter (drawRow)
  row.pct = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  row.pct:SetPoint('LEFT', ROW.PCT_X, 0)
  row.pct:SetWidth(ROW.PCT_W)
  row.pct:SetJustifyH('RIGHT')

  row.dot = row:CreateTexture(nil, 'ARTWORK')
  row.dot:SetSize(ROW.DOT_SIZE, ROW.DOT_SIZE)
  row.dot:SetPoint('LEFT', ROW.DOT_X, 0)
  row.dot:SetTexture(C.TEXTURE.FLAT)
  if row.CreateMaskTexture then
    local mask = row:CreateMaskTexture()
    mask:SetTexture(C.TEXTURE.ROUND_MASK, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
    mask:SetAllPoints(row.dot)
    row.dot:AddMaskTexture(mask)
  end

  row.mark = row:CreateTexture(nil, 'ARTWORK')
  row.mark:SetSize(ROW.MARK_SIZE, ROW.MARK_SIZE)
  row.mark:SetPoint('LEFT', row.dot, 'RIGHT', ROW.GAP, 0)

  -- Aggro-Ziel (Anforderung L): Rollensymbol des Halters vor dem Mobnamen.
  -- Die genaue Position setzt drawRow (abhängig von den eingeschalteten Feldern).
  row.sym = row:CreateTexture(nil, 'ARTWORK')
  row.sym:SetSize(C.SYMBOL_LAYOUT.LIST_SIZE, C.SYMBOL_LAYOUT.LIST_SIZE)
  row.sym:SetPoint('LEFT', row.mark, 'RIGHT', ROW.GAP, 0)

  row.name = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  row.name:SetPoint('LEFT', row.sym, 'RIGHT', C.SYMBOL_LAYOUT.LIST_GAP, 0)
  row.name:SetPoint('RIGHT', ROW.NAME_RIGHT, 0)
  row.name:SetJustifyH('LEFT')
  row.name:SetWordWrap(false)

  -- Pulsierender Rahmen um die Zeile deines aktuellen Ziels (gemeinsam mit den Nameplates)
  row.glow = ns.createGlow(row, ROW.GLOW)

  ns.rows[i] = row
  return row
end

-- An: pulsierender Rahmen + etwas hellere Zeile. Aus: normale Zeile.
local function setTargetHighlight(row, on)
  ns.setGlow(row.glow, on)
  row.bg:SetVertexColor(1, 1, 1, on and ROW.BG_ALPHA_TARGET or ROW.BG_ALPHA)
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
-- Textfarbe = "Aggro-%-Farbe" des Zustands aus der Tabelle im Reiter Nameplates.
local function fillPct(row, e)
  row.dot:ClearAllPoints()
  if not ns.db.listThreat then
    row.pct:Hide()
    row.dot:SetPoint('LEFT', ROW.DOT_X, 0)
    return
  end
  row.dot:SetPoint('LEFT', row.pct, 'RIGHT', ROW.GAP, 0)
  local st = ns.plateState(e.color)
  local c = st and st.threatColor or C.WHITE
  row.pct:SetTextColor(c[1], c[2], c[3])
  local pct = e.testPct
  if pct == nil and e.unit then
    local ok, _, _, value = pcall(UnitDetailedThreatSituation, 'player', e.unit)
    if ok then pct = value end
  end
  -- erst auf "geheim" prüfen: einen geheimen Wert mit nil zu vergleichen ist verboten
  local shown = (ns.IsSecret(pct) or pct ~= nil)
    and pcall(row.pct.SetFormattedText, row.pct, C.NAMEPLATES.THREAT_PCT_FORMAT, pct)
  if not shown then row.pct:SetText('') end
  row.pct:Show()
end

local function drawRow(row, e)
  row.entry = e
  setDot(row.dot, e.color)
  fillPct(row, e)
  -- Reihenfolge: Ampelpunkt → (Schlachtzugsymbol) → (Rollensymbol) → Name.
  -- Felder, die abgeschaltet sind, nehmen keinen Platz weg.
  local left = row.dot
  if ROW.SHOW_RAID_MARK then
    ns.setMark(row.mark, e.markIndex)
    left = row.mark
  else
    row.mark:Hide()
  end
  if ns.db.symbolMarks then
    row.sym:SetPoint('LEFT', left, 'RIGHT', ROW.GAP, 0)
    row.sym:SetShown(e.symbol and ns.setSymbolTexture(row.sym, e.symbol) or false)
    row.name:SetPoint('LEFT', row.sym, 'RIGHT', C.SYMBOL_LAYOUT.LIST_GAP, 0)
  else
    row.sym:Hide()
    row.name:SetPoint('LEFT', left, 'RIGHT', ROW.GAP, 0)
  end
  if not pcall(row.name.SetText, row.name, e.name or '?') then row.name:SetText('?') end
  -- Dein eigenes Ziel wird immer zuerst über den Token `target` gelesen (er
  -- steht in candidateUnits() vorn), also ist die Zeile mit unit == 'target' deins.
  setTargetHighlight(row, ns.db.highlightTarget and e.unit == 'target')
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
        symbol = t[4], testPct = t[5] }
    end
  else
    for _, t in pairs(ns.tracked) do
      if t.shownColor then
        list[#list + 1] = { name = t.name, color = t.shownColor, markIndex = t.markIndex, unit = t.unit,
          symbol = ns.symbolFor(t.unit) }
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
  if frame:GetHeight() ~= height then
    frame:SetHeight(height)
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
