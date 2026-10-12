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

local function setDot(tex, colorName)
  local c = C.COLOR[colorName] or C.COLOR.yellow
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
  -- L.TT_CLICK ("Klicken zum Anvisieren") bewusst weggelassen: Klicken tut
  -- derzeit nichts, ein Tooltip, der es verspricht, wäre irreführend.
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

  -- Symbol-Markierung (Anforderung L): Rollensymbol des Aggro-Halters
  row.sym = row:CreateTexture(nil, 'ARTWORK')
  row.sym:SetSize(C.SYMBOL_LAYOUT.LIST_SIZE, C.SYMBOL_LAYOUT.LIST_SIZE)
  row.sym:SetPoint('LEFT', row.dot, 'RIGHT', ROW.GAP, 0)

  row.mark = row:CreateTexture(nil, 'ARTWORK')
  row.mark:SetSize(ROW.MARK_SIZE, ROW.MARK_SIZE)
  row.mark:SetPoint('LEFT', row.sym, 'RIGHT', ROW.GAP, 0)

  row.name = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  row.name:SetPoint('LEFT', row.mark, 'RIGHT', ROW.GAP, 0)
  row.name:SetPoint('RIGHT', ROW.NAME_RIGHT, 0)
  row.name:SetJustifyH('LEFT')
  row.name:SetWordWrap(false)

  -- Rahmen um die Zeile deines aktuellen Ziels. Nur flache Texturen (kein
  -- Atlas), in einem Kind-Frame, damit eine Animation alle vier Kanten pulsieren lässt.
  local edgeSize = ROW.GLOW_EDGE
  local glowColor = ROW.TARGET_GLOW
  row.glow = CreateFrame('Frame', nil, row)
  row.glow:SetAllPoints()
  for _, edge in ipairs({
    { 'TOPLEFT', 'TOPRIGHT', nil, edgeSize },
    { 'BOTTOMLEFT', 'BOTTOMRIGHT', nil, edgeSize },
    { 'TOPLEFT', 'BOTTOMLEFT', edgeSize, nil },
    { 'TOPRIGHT', 'BOTTOMRIGHT', edgeSize, nil },
  }) do
    local line = row.glow:CreateTexture(nil, 'OVERLAY')
    line:SetTexture(C.TEXTURE.FLAT)
    line:SetVertexColor(glowColor[1], glowColor[2], glowColor[3], 1)
    line:SetPoint(edge[1])
    line:SetPoint(edge[2])
    if edge[3] then line:SetWidth(edge[3]) end
    if edge[4] then line:SetHeight(edge[4]) end
  end
  row.glow:Hide()
  -- Das Pulsieren ist nur Optik: Weicht die Animations-API dieses Clients ab,
  -- bleibt der Rahmen einfach ruhig stehen, statt einen Fehler zu werfen.
  pcall(function()
    local anim = row.glow:CreateAnimationGroup()
    local alpha = anim:CreateAnimation('Alpha')
    alpha:SetFromAlpha(ROW.GLOW_ALPHA_FROM)
    alpha:SetToAlpha(ROW.GLOW_ALPHA_TO)
    alpha:SetDuration(ROW.GLOW_DURATION)
    alpha:SetSmoothing('IN_OUT')
    anim:SetLooping('BOUNCE')
    row.glowAnim = anim
  end)

  ns.rows[i] = row
  return row
end

-- An: pulsierender Rahmen + etwas hellere Zeile. Aus: normale Zeile.
local function setTargetHighlight(row, on)
  if on then
    if not row.glow:IsShown() then
      row.glow:Show()
      if row.glowAnim then pcall(row.glowAnim.Play, row.glowAnim) end
    end
    row.bg:SetVertexColor(1, 1, 1, ROW.BG_ALPHA_TARGET)
  else
    if row.glow:IsShown() then
      if row.glowAnim then pcall(row.glowAnim.Stop, row.glowAnim) end
      row.glow:Hide()
    end
    row.bg:SetVertexColor(1, 1, 1, ROW.BG_ALPHA)
  end
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

local function drawRow(row, e)
  row.entry = e
  setDot(row.dot, e.color)
  ns.setMark(row.mark, e.markIndex)
  -- Symbolfeld: bei ausgeschalteter Markierung ohne Breite, damit die Zeile wie früher aussieht
  if ns.db.symbolMarks then
    row.sym:SetWidth(C.SYMBOL_LAYOUT.LIST_SIZE)
    row.sym:SetShown(e.symbol and ns.setSymbolTexture(row.sym, e.symbol) or false)
  else
    row.sym:SetWidth(0)
    row.sym:Hide()
  end
  if not pcall(row.name.SetText, row.name, e.name or '?') then row.name:SetText('?') end
  -- Dein eigenes Ziel wird immer zuerst über den Token `target` gelesen (er
  -- steht in candidateUnits() vorn), also ist die Zeile mit unit == 'target' deins.
  setTargetHighlight(row, ns.db.highlightTarget and e.unit == 'target')
  row:Show()
end

local function visibleRows()
  local space = ns.frame:GetHeight() - C.WINDOW.HEADER_H - ROW.LIST_VPAD
  local n = math.floor(space / (ns.db.rowHeight + ROW.SPACING))
  if n < 1 then n = 1 end
  if n > ROW.MAX then n = ROW.MAX end
  return n
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
    for i, t in ipairs(C.TEST_ROWS) do
      -- Die erste Testzeile spielt "dein Ziel", damit man die Hervorhebung sieht
      list[#list + 1] = { name = t[1], color = t[2], markIndex = t[3], unit = (i == 1) and 'target' or nil, symbol = t[4] }
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

  local rows = ns.rows
  local max = visibleRows()
  local shown = math.min(#list, max)
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
