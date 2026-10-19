--[[
  Leiste.lua — Bedrohungs-Leisten "Fokus" und "Ziel" (Anforderung AC, Design = prototyp/).

  Ein Baustein, zweimal verwendet (Quelle 'focus' bzw. 'target'). Senkrechte Leiste in der
  Größe einer Seiten-Aktionsleiste mit deren Knopf-Rahmen; darin ein Burgmauer-Turm:
    oben   Rollensymbol dessen, der den Mob hält, darunter sein Vorsprung in %
    Turm   die Gruppe als Rollen- bzw. Klassensymbole, Höhe = skalierte Aggro (oben = zieht)
    darüber Schlachtzugsymbol des Mobs (außerhalb des Rahmens)
  Geheime Werte (Aggro über nameplate/focus, Symbol-Nummer) werden nie gelesen, sondern an
  unsichtbare Balken gegeben, an deren Füllung die Symbole hängen ("Balken-Trick", getestet
  2026-10-18). Magnetisch an die Seitenleiste bzw. an die andere Leiste andockbar.
]]

local _, ns = ...
local C = ns.Config
local L = ns.L
local B = C.BAR

local bars = {}            -- key -> Leiste
local dims                 -- gemessene Maße (für beide Leisten gleich)
local measured = false

-- Maße der Seitenleiste --------------------------------------------------------------------

-- Breite/Höhe aus Knopf 1 und 12 (die Leisten-Rahmen selbst sind oft anders groß). Rückgabe:
-- Breite, Höhe (UIParent-Einheiten), Knopf 1 der linken sichtbaren Leiste, Abstand der Leisten
-- Nur Seitenleisten zählen, die wirklich SENKRECHT am RECHTEN RAND stehen. Hat ein Spieler sie
-- verschoben (z. B. waagerecht nach unten), nutzt TWF Ersatzmaße und steht selbst am rechten
-- Rand (Fix 0.5.1: sonst waren die Mauern winzig bzw. irgendwo im Bild).
local function sideBar()
  local s = 1 / UIParent:GetEffectiveScale()
  local screenRight = UIParent:GetRight() or 0
  local function measure(prefix)
    local b1, b12 = _G[prefix .. 'Button1'], _G[prefix .. 'Button12']
    if not (b1 and b12 and b1:IsVisible() and b1:GetTop() and b12:GetTop() and b12:GetBottom()) then return nil end
    local es = b1:GetEffectiveScale() * s
    local m = { b1 = b1, w = b1:GetWidth() * es, h = (b1:GetTop() - b12:GetBottom()) * es,
      left = b1:GetLeft() * es, right = b1:GetRight() * es }
    -- senkrecht: Knopf 12 unter Knopf 1 und (fast) in derselben Spalte
    local vertical = b12:GetTop() < b1:GetTop() and math.abs((b12:GetLeft() - b1:GetLeft()) * es) <= B.SIDE_COLUMN_PX
    if not vertical or m.h <= m.w then return nil end
    return m
  end
  local R, Lb = measure('MultiBarRight'), measure('MultiBarLeft')
  local rightOK = R and R.right >= screenRight - B.SIDE_EDGE_PX
  -- linke Seitenleiste: direkt neben der rechten oder (ohne rechte) selbst am Rand
  local leftOK = Lb and ((rightOK and math.abs(R.left - Lb.right) <= B.SIDE_PAIR_PX)
    or (not rightOK and Lb.right >= screenRight - B.SIDE_EDGE_PX))
  local use = (leftOK and Lb) or (rightOK and R)
  if not use then
    -- Keine passende Seitenleiste: trotzdem gleiches Aussehen – Knopfgröße und Rahmen von einer
    -- beliebigen Aktionsleiste, Höhe so, als stünde sie senkrecht (12 Knöpfe samt Abständen).
    for _, prefix in ipairs(B.SKIN_SOURCES) do
      local b1, b2 = _G[prefix .. '1'], _G[prefix .. '2']
      if b1 and b2 and b1:GetWidth() > 0 and b1:GetLeft() and b2:GetLeft() then
        local es = b1:GetEffectiveScale() * s
        local bw = b1:GetWidth() * es
        local dx = math.abs(b2:GetLeft() - b1:GetLeft()) * es
        local dy = math.abs((b2:GetTop() or 0) - (b1:GetTop() or 0)) * es
        local step = math.max(dx, dy)
        if step < bw then step = bw end
        return bw, 11 * step + bw, nil, B.GAP, b1
      end
    end
    return B.FALLBACK_W, B.FALLBACK_H, nil, B.GAP
  end
  local gap = B.GAP
  if rightOK and leftOK then gap = math.max(0, R.left - Lb.right) end
  return use.w, use.h, use.b1, gap, use.b1
end

-- Turm-Maße: symmetrischer Verband (Ziegelbreite ungerade, Turm = 2 Ziegel + Fuge), Symbole
-- passen in den Turm, Turm endet auf einer ganzen Ziegelreihe.
local function computeDims()
  local w, h, anchor, gap, skin = sideBar()
  w, h = math.floor(w + 0.5), math.floor(h + 0.5)
  local bw = math.floor((w - 2 * B.FRAME_PAD - 1) / 2)
  if bw % 2 == 0 then bw = bw - 1 end
  local d = { w = w, h = h, anchor = anchor, gap = gap, skin = skin, brickW = bw, towerW = 2 * bw + 1 }
  d.size = math.floor((d.towerW - 2 - B.HALO_PX[1]) / B.ROLE_ICON_VISIBLE)
  local wallTop = B.TITLE_H + d.size + 2 + B.PCT_H + B.MERLON_H + 2
  d.side = math.floor((w - d.towerW) / 2)
  local rowH = B.BRICK_H + 1
  local rows = math.floor((h - wallTop - d.side + 1) / rowH)
  d.len = rows * rowH - 1
  d.wallY = h - d.side - d.len
  d.head = d.wallY - (B.TITLE_H + d.size / 2)
  return d
end

-- Rahmen wie die Leistenknöpfe: deren Rand-Grafik auf die Leistengröße ziehen ---------------

local function applySkin(bar, btn)
  local f = bar.frame
  bar.skinDX = 0
  bar.skin = bar.skin or f:CreateTexture(nil, 'BORDER')
  local tx = bar.skin
  local nt = btn and btn.GetNormalTexture and btn:GetNormalTexture()
  local atlas = nt and nt.GetAtlas and nt:GetAtlas()
  local file = nt and nt:GetTexture()
  if not (atlas or file) or not tx.SetTextureSliceMargins then
    -- keine Seitenleiste bzw. keine Neun-Teile-Ränder: runder Tooltip-Rahmen mit Hintergrund
    tx:Hide()
    f:SetBackdropColor(unpack(B.FALLBACK_BG))
    f:SetBackdropBorderColor(unpack(B.FALLBACK_BORDER))
    return
  end
  if atlas then tx:SetAtlas(atlas, false) else tx:SetTexture(file) tx:SetTexCoord(nt:GetTexCoord()) end
  tx:SetVertexColor(nt:GetVertexColor())
  local k = btn:GetEffectiveScale() / f:GetEffectiveScale()
  local dl = (nt:GetLeft() - btn:GetLeft()) * k
  local dr = (nt:GetRight() - btn:GetRight()) * k
  local dt = (nt:GetTop() - btn:GetTop()) * k
  local db = (nt:GetBottom() - btn:GetBottom()) * k
  tx:ClearAllPoints()
  tx:SetPoint('TOPLEFT', f, 'TOPLEFT', dl, dt)
  tx:SetPoint('BOTTOMRIGHT', f, 'BOTTOMRIGHT', dr, db)
  tx:SetTextureSliceMargins(B.SKIN_SLICE, B.SKIN_SLICE, B.SKIN_SLICE, B.SKIN_SLICE)
  if tx.SetTextureSliceMode and Enum and Enum.UITextureSliceMode then
    tx:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
  end
  tx:Show()
  bar.skinDX = (dl + dr) / 2
  f:SetBackdropColor(0, 0, 0, 0)
  f:SetBackdropBorderColor(0, 0, 0, 0)
end

-- Turm ---------------------------------------------------------------------------------------

local function buildWall(bar)
  local wall, d = bar.wall, dims
  for _, t in ipairs(bar.wallTex) do t:Hide() end
  wipe(bar.wallTex)
  local function tex(layer, sub, c, a)
    local t = wall:CreateTexture(nil, layer, nil, sub or 0)
    t:SetColorTexture(c[1], c[2], c[3], a or 1)
    bar.wallTex[#bar.wallTex + 1] = t
    return t
  end
  wall:ClearAllPoints()
  wall:SetSize(d.towerW, d.len)
  wall:SetPoint('TOPLEFT', bar.frame, 'TOPLEFT', math.floor(d.side + bar.skinDX + B.NUDGE_X + 0.5), -d.wallY)
  tex('BACKGROUND', 0, B.MORTAR):SetAllPoints(wall)
  -- symmetrischer Verband: gerade Reihen 2 ganze Ziegel, ungerade halb | ganz | halb
  local bw, rows, half = d.brickW, math.floor((d.len + 1) / (B.BRICK_H + 1)), (d.brickW - 1) / 2
  for r = 0, rows - 1 do
    local pieces = (r % 2 == 0) and { { 0, bw }, { bw + 1, bw } }
      or { { 0, half }, { half + 1, bw }, { half + bw + 2, half } }
    for k, pc in ipairs(pieces) do
      local s = tex('BORDER', 0, ((r + k) % 2 == 0) and B.STONE_A or B.STONE_B)
      s:SetSize(pc[2], B.BRICK_H)
      s:SetPoint('TOPLEFT', wall, 'TOPLEFT', pc[1], -(r * (B.BRICK_H + 1)))
    end
  end
  -- Turmspitze: Sims + Zinnen
  local ledge = tex('BORDER', 2, B.CAP)
  ledge:SetSize(d.towerW + 6, 4)
  ledge:SetPoint('BOTTOM', wall, 'TOP')
  local mw = (d.towerW + 6) / 5
  for i = 0, 2 do
    local z = tex('BORDER', 2, B.CAP)
    z:SetSize(mw, 7)
    z:SetPoint('BOTTOMLEFT', ledge, 'TOPLEFT', i * 2 * mw, 0)
  end
  -- Glühen am oberen Ende (beim Halter)
  local reach = d.len * B.GLOW_REACH
  for i = 0, B.GLOW_STEPS - 1 do
    local g = tex('ARTWORK', 0, B.GLOW, B.GLOW_ALPHA * (1 - i / B.GLOW_STEPS))
    g:SetBlendMode('ADD')
    g:SetSize(d.towerW + 6, reach / B.GLOW_STEPS)
    g:SetPoint('TOP', wall, 'TOP', 0, -i * reach / B.GLOW_STEPS)
  end
end

-- Symbole ------------------------------------------------------------------------------------

-- Atlas des Rollensymbols einer Einheit (ohne Gruppenrolle: du mit deiner TWF-Rolle)
local TWF_TO_GROUP = { tank = 'TANK', heal = 'HEALER', dps = 'DAMAGER' }
local function roleAtlas(unit)
  local ok, r = pcall(UnitGroupRolesAssigned, unit)
  r = ok and ns.plain(r) or nil
  if (not r or r == 'NONE') and UnitIsUnit(unit, 'player') then r = TWF_TO_GROUP[ns.db.role] end
  return C.SYMBOLS[r or 'NONE'] or C.SYMBOLS.NONE
end

local function setIcon(sym, unit, onTower)
  local _, class = UnitClass(unit)
  local useClass = onTower and ns.db.barClassIcons and CLASS_ICON_TCOORDS and class and CLASS_ICON_TCOORDS[class]
  local size = dims.size * (useClass and B.CLASS_ICON_SCALE or 1)
  sym:SetSize(size, size)
  sym.glow:SetSize(size * 1.9, size * 1.9)
  sym.useClass = useClass and true or false
  for i, h in ipairs(sym.halo) do
    local s = 2 * math.floor((dims.size * B.ROLE_ICON_VISIBLE + B.HALO_PX[i]) / 2 + 0.5)
    h:SetSize(s, s)
  end
  if useClass then
    sym.icon:SetTexture(B.CLASS_SHEET)
    sym.icon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[class]))
  else
    sym.icon:SetTexCoord(0, 1, 0, 1)
    sym.icon:SetAtlas(roleAtlas(unit), false)
  end
  local cc = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
  sym.nameColor = cc and { cc.r, cc.g, cc.b } or C.WHITE
end

-- Tooltip: Name in Klassenfarbe, darunter die % (live; geheime Werte per SetFormattedText)
local function showTip(sym)
  if not sym.unit then return end
  GameTooltip:SetOwner(sym, 'ANCHOR_RIGHT')
  local okN, name = pcall(UnitName, sym.unit)
  GameTooltip:AddLine(okN and name or '?', unpack(sym.nameColor or C.WHITE))
  GameTooltip:AddLine(' ', 1, 1, 1)
  local line = _G.GameTooltipTextLeft2
  if line and sym.value ~= nil then pcall(line.SetFormattedText, line, B.PCT_FORMAT, sym.value) end
  GameTooltip:Show()
end

local function makeSymbol(bar, parent)
  local sym = CreateFrame('Frame', nil, parent)
  sym.icon = sym:CreateTexture(nil, 'ARTWORK')
  sym.icon:SetAllPoints()
  sym.halo = {}
  for i, a in ipairs(B.HALO_ALPHA) do
    local h = sym:CreateTexture(nil, 'BACKGROUND', nil, i)
    h:SetTexture(B.HALO_TEX)
    h:SetPoint('CENTER')
    h:SetAlpha(a)
    h:Hide()
    sym.halo[i] = h
  end
  sym.glow = sym:CreateTexture(nil, 'BACKGROUND')
  sym.glow:SetTexture(B.GLOW_TEX)
  sym.glow:SetBlendMode('ADD')
  sym.glow:SetPoint('CENTER')
  sym.glow:Hide()
  sym:EnableMouse(true)
  sym:SetScript('OnEnter', showTip)
  sym:SetScript('OnLeave', function() GameTooltip:Hide() end)
  return sym
end

-- Eigenes Symbol: Goldring (Rolle) bzw. eckiger Goldschein (Klasse); bei Alarm rot blinkend
local function markSelf(sym, isMe, alarm)
  local blinkOn = (GetTime() % B.BLINK) < B.BLINK / 2
  local c = (alarm and blinkOn) and B.ALARM_COLOR or B.MARK_COLOR
  for _, h in ipairs(sym.halo) do
    h:SetShown(isMe and not sym.useClass)
    h:SetVertexColor(c[1], c[2], c[3])
  end
  sym.glow:SetShown(isMe and sym.useClass)
  sym.glow:SetVertexColor(c[1], c[2], c[3])
end

-- Andocken -------------------------------------------------------------------------------------

local function state(key)
  ns.db.bars = type(ns.db.bars) == 'table' and ns.db.bars or {}
  local s = ns.db.bars[key]
  if type(s) ~= 'table' then
    s = { dock = B.DEFAULT_DOCK[key] }
    ns.db.bars[key] = s
  end
  return s
end

-- Platz neben dem Andock-Partner: 'side' = linke Seitenleiste, 'bar' = andere Leiste
local function attach(bar)
  local f, s = bar.frame, state(bar.key)
  f:ClearAllPoints()
  local other = bars[bar.other]
  if s.dock == 'bar' and other and other.frame:IsShown() and other.frame ~= f then
    f:SetPoint('TOPRIGHT', other.frame, 'TOPLEFT', -dims.gap, 0)
  elseif (s.dock == 'side' or s.dock == 'bar') and dims.anchor then
    f:SetPoint('TOPRIGHT', dims.anchor, 'TOPLEFT', -dims.gap, 0)
  elseif s.dock == 'side' or s.dock == 'bar' then
    -- keine Seitenleiste am rechten Rand: selbst an den rechten Rand, senkrecht mittig, aber
    -- unterhalb der Minikarte (Nutzer 2026-10-19: oben überdeckten sie die Koordinaten) und
    -- unten nicht aus dem Bild
    local uiH, h = UIParent:GetHeight(), f:GetHeight()
    local top = (uiH - h) / 2
    local mm = _G.MinimapCluster or _G.Minimap
    if mm and mm:IsShown() and mm:GetBottom() then
      local mmBottom = mm:GetBottom() * mm:GetEffectiveScale() / UIParent:GetEffectiveScale()
      top = math.max(top, uiH - mmBottom + B.MINIMAP_GAP)
    end
    top = math.min(top, uiH - h - B.EDGE_X)
    f:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', -B.EDGE_X, -math.max(0, top))
  elseif s.x then
    f:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', s.x, s.y)
  else
    f:SetPoint('CENTER', UIParent, 'CENTER', B.FREE_X[bar.key], 0)
  end
end

local function dragStop(bar)
  local f, s = bar.frame, state(bar.key)
  f:StopMovingOrSizing()
  local function near(leftEdge, top)
    local dx = leftEdge - f:GetRight()
    local overlap = f:GetBottom() < top and f:GetTop() > top - f:GetHeight()
    return math.abs(dx) <= B.SNAP_PX and overlap
  end
  local other = bars[bar.other]
  local k = UIParent:GetEffectiveScale()
  if other and other.frame:IsShown() and state(bar.other).dock ~= 'bar'
      and near(other.frame:GetLeft() - dims.gap, other.frame:GetTop()) then
    s.dock = 'bar'
  elseif dims.anchor and near(dims.anchor:GetLeft() * dims.anchor:GetEffectiveScale() / k - dims.gap,
      dims.anchor:GetTop() * dims.anchor:GetEffectiveScale() / k) then
    -- Platz an der Seitenleiste schon belegt? Dann neben die andere Leiste
    local otherSide = other and other.frame:IsShown() and state(bar.other).dock == 'side'
    s.dock = otherSide and 'bar' or 'side'
  else
    s.dock = false
    s.x, s.y = f:GetLeft(), f:GetTop()
  end
  ns.dbg('BAR', bar.key .. '-Leiste: ' .. tostring(s.dock or 'frei'))
  attach(bar)
end

-- Aufbau ----------------------------------------------------------------------------------------

local function newBar(key, unit, titleKey, other)
  local bar = { key = key, unit = unit, other = other, wallTex = {}, syms = {}, skinDX = 0 }
  local f = CreateFrame('Frame', 'ThreatWallForever' .. key .. 'Bar', UIParent, 'BackdropTemplate')
  f:SetBackdrop({ bgFile = C.TEXTURE.FLAT, edgeFile = C.TEXTURE.TOOLTIP_BORDER, edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 } })
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag('LeftButton')
  f:SetClampedToScreen(true)
  f:SetScript('OnDragStart', function(self)
    if ns.db.locked then return end   -- "Alles fixieren"
    local l, t = self:GetLeft(), self:GetTop()
    self:ClearAllPoints()
    self:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', l, t)
    self:StartMoving()
  end)
  f:SetScript('OnDragStop', function() if not ns.db.locked then dragStop(bar) end end)
  f:Hide()
  bar.frame = f

  bar.title = f:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
  bar.title:SetText(L[titleKey])
  bar.wall = CreateFrame('Frame', nil, f)
  -- Schlachtzugsymbol außerhalb über der Leiste (unten verdeckt es der Spiel-Tooltip)
  bar.marker = ns.createRaidMark(f, B.MARK)

  -- Halter oben (Rollensymbol) + Vorsprung; Klick schaltet Rolle/Klasse auf dem Turm
  bar.holder = makeSymbol(bar, f)
  bar.holder:SetFrameLevel(bar.wall:GetFrameLevel() + 5)
  bar.holder:SetScript('OnMouseUp', function(_, button)
    if button == 'LeftButton' then
      ns.db.barClassIcons = not ns.db.barClassIcons
      ns.dbg('BAR', 'Symbole auf dem Turm: ' .. (ns.db.barClassIcons and 'Klasse' or 'Rolle'))
    end
  end)
  bar.lead = f:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  bar.lead:SetPoint('TOP', bar.holder, 'BOTTOM', 0, -2)

  -- je Gruppenmitglied: unsichtbarer senkrechter Balken über die Turmhöhe, Symbol an der Füllung
  for i, u in ipairs(B.UNITS) do
    local sb = CreateFrame('StatusBar', nil, bar.wall)
    sb:SetAllPoints(bar.wall)
    sb:SetOrientation('VERTICAL')
    sb:SetMinMaxValues(0, 100)
    sb:SetStatusBarTexture(C.TEXTURE.FLAT)
    sb:GetStatusBarTexture():SetVertexColor(1, 1, 1, 0)
    local sym = makeSymbol(bar, bar.wall)
    sym:SetFrameLevel(bar.wall:GetFrameLevel() + (u == 'player' and 10 or 5))   -- eigenes vorn
    sym:SetPoint('CENTER', sb:GetStatusBarTexture(), 'TOP', 0, 0)
    sym.sbar, sym.unitKey = sb, u
    sym:Hide()
    bar.syms[i] = sym
  end
  bars[key] = bar
  return bar
end

local function layout(bar)
  local f = bar.frame
  f:SetScale(1)
  f:SetSize(dims.w, dims.h)
  applySkin(bar, dims.skin)   -- Knopf-Rahmen auch ohne Andock-Leiste (Fix 0.5.1)
  bar.title:ClearAllPoints()
  bar.title:SetPoint('TOP', f, 'TOP', math.floor(bar.skinDX + B.NUDGE_X + 0.5), -3)
  bar.marker:ClearAllPoints()
  bar.marker:SetPoint('BOTTOM', f, 'TOP', math.floor(bar.skinDX + B.NUDGE_X + 0.5), B.MARK_GAP)
  buildWall(bar)
  bar.holder:SetSize(dims.size, dims.size)
  bar.holder:ClearAllPoints()
  bar.holder:SetPoint('CENTER', bar.wall, 'TOP', 0, dims.head)
end

-- Werte --------------------------------------------------------------------------------------

local function update(bar)
  local unit = bar.unit
  local okE, exists = pcall(UnitExists, unit)
  local okA, hostile = pcall(UnitCanAttack, 'player', unit)
  if not (okE and exists and okA and hostile) then
    bar.holder:Hide()
    bar.lead:SetText('')
    bar.marker:Hide()
    for _, sym in ipairs(bar.syms) do sym:Hide() end
    return
  end

  -- Wer hält den Mob? Stufe ist lesbar (3 = sicher, 2 = knapp)
  local holderUnit, holderStatus
  local status = {}
  for i, u in ipairs(B.UNITS) do
    if UnitExists(u) then
      local ok, st = pcall(UnitThreatSituation, u, unit)
      st = ok and ns.plain(st) or nil
      status[i] = st
      if st and st >= 2 and (not holderStatus or st > holderStatus) then holderUnit, holderStatus = u, st end
    end
  end

  -- Kopf: Rollensymbol des Halters + Vorsprung (vom Spiel berechnet, evtl. geheim)
  if holderUnit then
    bar.holder.unit = holderUnit
    setIcon(bar.holder, holderUnit, false)
    markSelf(bar.holder, false, false)
    bar.holder:Show()
    local ok, lead = pcall(UnitThreatPercentageOfLead, holderUnit, unit)
    bar.holder.value = ok and lead or nil
    local shown = ok and (ns.IsSecret(lead) or (lead and lead > 0))
    if shown then shown = pcall(bar.lead.SetFormattedText, bar.lead, B.PCT_FORMAT, lead) end
    if not shown then bar.lead:SetText('') end
  else
    bar.holder:Hide()
    bar.lead:SetText('')
  end

  -- Turm: alle anderen nach skalierter Aggro (Balken-Trick, auch bei geheimen Werten)
  for i, sym in ipairs(bar.syms) do
    local u = sym.unitKey
    if status[i] and u ~= holderUnit then
      local ok, _, _, scaled = pcall(UnitDetailedThreatSituation, u, unit)
      local secret = ok and ns.IsSecret(scaled)
      if ok and (secret or scaled ~= nil) and pcall(sym.sbar.SetValue, sym.sbar, scaled) then
        sym.unit, sym.value = u, scaled
        setIcon(sym, u, true)
        local alarm = not secret and scaled >= B.ALARM_PCT
        markSelf(sym, u == 'player', alarm)
        sym:Show()
        if GameTooltip:IsOwned(sym) then showTip(sym) end
      else
        sym:Hide()
      end
    else
      sym:Hide()
    end
  end
  if GameTooltip:IsOwned(bar.holder) then showTip(bar.holder) end

  -- Schlachtzugsymbol unten: ohne Symbol lesbar nil, mit Symbol geheim → nur weiterreichen
  local okM, idx = pcall(GetRaidTargetIndex, unit)
  if okM then ns.setRaidMark(bar.marker, idx) else bar.marker:Hide() end
end

-- Sichtbarkeit / Andocken neu ------------------------------------------------------------------

local SETTING = { focus = 'focusBar', target = 'targetBar' }
local COMBAT_ONLY = { focus = 'focusBarCombat', target = 'targetBarCombat' }
local ALPHA = { focus = 'focusBarAlpha', target = 'targetBarAlpha' }
local GROUP_ONLY = { focus = 'focusBarGroup', target = 'targetBarGroup' }

-- Soll die Leiste gerade zu sehen sein? An, dazu bei "Nur im Kampf sichtbar" nur im Kampf und
-- bei "Nur in einer Gruppe sichtbar" nur in Gruppe oder Schlachtzug.
local function wanted(key)
  local db = ns.db
  if not db[SETTING[key]] then return false end
  if db[COMBAT_ONLY[key]] and not UnitAffectingCombat('player') then return false end
  if db[GROUP_ONLY[key]] and not (IsInGroup() or IsInRaid()) then return false end
  return true
end

local function refreshAll()
  if not measured then return end
  dims = computeDims()
  for _, key in ipairs(B.ORDER) do
    local bar = bars[key]
    local on = wanted(key)
    bar.frame:SetShown(on)
    bar.frame:SetAlpha(ns.db[ALPHA[key]] or 1)
    if on then layout(bar) end
  end
  -- erst alle zeigen, dann andocken (die zweite hängt evtl. an der ersten)
  for _, key in ipairs(B.ORDER) do
    if bars[key].frame:IsShown() then attach(bars[key]) end
  end
end

local pending = false
local function refreshSoon()
  if pending then return end
  pending = true
  C_Timer.After(B.REFRESH_DELAY, function()
    pending = false
    refreshAll()
  end)
end

local events = CreateFrame('Frame')
events:RegisterEvent('UI_SCALE_CHANGED')
events:RegisterEvent('DISPLAY_SIZE_CHANGED')
if C_EditMode then events:RegisterEvent('EDIT_MODE_LAYOUTS_UPDATED') end
events:SetScript('OnEvent', refreshSoon)

ns.RegisterModule('Leiste', {
  OnLogin = function()
    newBar('focus', 'focus', 'SEC_FOCUS', 'target')
    newBar('target', 'target', 'SEC_TARGET', 'focus')
    for _, name in ipairs({ 'MultiBarLeft', 'MultiBarRight' }) do
      local sb = _G[name]
      if sb then
        sb:HookScript('OnShow', refreshSoon)
        sb:HookScript('OnHide', refreshSoon)
      end
      -- Knopfgröße ändert sich, wenn das Spiel Skalierung/Layout spät anwendet → neu messen
      local b1 = _G[name .. 'Button1']
      if b1 then b1:HookScript('OnSizeChanged', refreshSoon) end
    end
    -- Seitenleisten stehen beim Einloggen evtl. noch nicht fertig → kurz warten, dann messen.
    -- Nach einem echten Spielstart (langsamer als /reload) waren die Maße beim ersten Messen
    -- teils noch falsch (Leisten zu groß, Nutzer 2026-10-19) → später noch einmal prüfen und
    -- nur neu aufbauen, wenn sich etwas geändert hat.
    C_Timer.After(B.MEASURE_DELAY, function()
      measured = true
      refreshAll()
    end)
    -- Immer komplett neu aufbauen (auch den Knopf-Rahmen): beim Spielstart stimmte teils nur der
    -- Rahmen nicht, Größe und Position schon (Nutzer 2026-10-19) – ein Vergleich der Maße reicht nicht.
    for _, s in ipairs(B.REMEASURE) do
      C_Timer.After(s, function()
        refreshAll()
        if dims then ns.dbg('BAR', ('Leisten neu aufgebaut nach %d s: %d x %d'):format(s, dims.w, dims.h)) end
      end)
    end
  end,
  OnTick = function()
    if not measured then return end
    -- Kampf beginnt/endet: Leisten mit "Nur im Kampf sichtbar" ein-/ausblenden und neu andocken
    for key, bar in pairs(bars) do
      if wanted(key) ~= bar.frame:IsShown() then
        refreshAll()
        break
      end
    end
    for _, bar in pairs(bars) do
      if bar.frame:IsShown() then update(bar) end
    end
  end,
  OnSettingChanged = function(key)
    for _, t in ipairs({ SETTING, COMBAT_ONLY, GROUP_ONLY }) do
      if t.focus == key or t.target == key then refreshAll() end
    end
    if key == 'role' then refreshAll() end
    for k, bar in pairs(bars) do
      if ALPHA[k] == key then bar.frame:SetAlpha(ns.db[key] or 1) end
    end
  end,
})
