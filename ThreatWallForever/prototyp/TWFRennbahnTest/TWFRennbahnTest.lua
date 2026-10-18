-- TWF Rennbahn-Test: reiner Optik-Test der Fokus-Rennbahn (Idee I4), Demo mit erfundener Gruppe.
-- Wegwerf-Addon, nicht Teil von ThreatWall Forever. Befehle: /rbt (ein/aus), /rbt vert, /rbt flip,
-- /rbt pct, /rbt icon, /rbt pause, /rbt neu

local ROLE_ATLAS = { tank = 'ui-lfg-roleicon-tank', dps = 'ui-lfg-roleicon-dps', heal = 'ui-lfg-roleicon-healer' }

local H = { w = 580, h = 200, len = 480, x = 50, y = 46 }   -- waagerecht
local V = { w = 28, h = 460, len = 380, x = 14, y = 76, yFlip = 18 }   -- senkrecht, eng um den Turm (w/x nach Titelbreite gesetzt)
local HEAD = 46   -- senkrecht: Abstand Turm-Ende → Mitte Halter-Symbol (wird in fitToBar berechnet)
local SIZE_ME, SIZE_OTHER = 34, 26   -- Symbolgrößen (senkrecht nach Leistenbreite berechnet)
local FALLBACK_W, FALLBACK_H = 42, 480   -- falls keine Seitenleiste da ist
local SKIN_DX = 0   -- waagerechter Versatz der Mitte des sichtbaren Knopf-Rahmens (aus dem Knopf abgelesen)
local NUDGE_X = -3  -- Feinjustierung (im Spiel ermittelt 18.10.: Rahmengrafik ist ungleich dick); per /rbt x <px> änderbar
local TITLE_H, PCT_H, MERLON_H, FRAME_PAD = 18, 14, 11, 9   -- FRAME_PAD: Knopf-Rand (~7 px) + 2 px Luft

local STONE, GAP, THICK = 26, 2, 14
local TOWER_W, BRICK_W, BRICK_H = 34, 11, 7   -- senkrecht: Turm aus liegenden Ziegeln
local STONE_A = { 0.42, 0.35, 0.28 }
local STONE_B = { 0.47, 0.39, 0.31 }
local MORTAR = { 0.14, 0.11, 0.09 }
local CAP = { 0.58, 0.49, 0.39 }
local GLOW = { 1, 0.27, 0.16 }
local ROLE_ICON_VISIBLE = 0.74          -- sichtbarer Kreis des Rollensymbols im Verhältnis zum Feld (Rest durchsichtig)
local HALO_PX = { 6, 4, 2 }              -- Ring: 3/2/1 px über den sichtbaren Kreis, außen blass, innen kräftig
local HALO_ALPHA = { 0.35, 0.55, 0.85 }
local MARK_COLOR = { 1, 0.82, 0.2 }     -- eigenes Symbol: gold
local ALARM_COLOR = { 1, 0.15, 0.1 }    -- eigenes Symbol bei Alarm (blinkend): rot

-- Tooltip am Symbol: Name in Klassenfarbe, darunter die % (Halter: Vorsprung); läuft live mit.
-- Hinweis für TWF: echte Werte können geheim sein → dann die Tooltip-Zeile per SetFormattedText füllen.
local function showTip(p)
  GameTooltip:ClearLines()
  GameTooltip:AddLine(p.name:GetText(), p.name:GetTextColor())
  GameTooltip:AddLine(p.pct:GetText() or '', 1, 1, 1)
  GameTooltip:Show()
end
local layout   -- weiter unten definiert; hier bekannt gemacht, damit Klick-Funktionen es aufrufen können
local opt = { vert = true, flip = false, pct = false, classIcon = false, paused = false, meTank = false }

local f = CreateFrame('Frame', 'TWFRennbahnTestFrame', UIParent, 'BackdropTemplate')
f:SetPoint('CENTER', 0, 150)
f:SetBackdrop({ bgFile = 'Interface\\Buttons\\WHITE8x8', edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border',
  edgeSize = 8, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
f:SetBackdropColor(0.06, 0.07, 0.09, 0.85)
f:SetBackdropBorderColor(0.5, 0.42, 0.33, 1)
f:SetMovable(true)
f:EnableMouse(true)
f:RegisterForDrag('LeftButton')
f:SetScript('OnDragStart', f.StartMoving)
f:SetScript('OnDragStop', f.StopMovingOrSizing)
f:SetClampedToScreen(true)

-- Griff unten rechts: ziehen skaliert das ganze Fenster (oben links bleibt stehen)
local MIN_SCALE, MAX_SCALE = 0.4, 2
local function addGrip(frame)
  local grip = CreateFrame('Button', nil, frame)
  grip:SetSize(12, 12)
  grip:SetPoint('CENTER', frame, 'BOTTOMRIGHT', 2, -2)
  grip:SetFrameLevel(frame:GetFrameLevel() + 20)
  grip:SetNormalTexture('Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up')
  grip:SetHighlightTexture('Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight')
  grip:SetPushedTexture('Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down')
  grip:SetScript('OnMouseDown', function(self)
    local ui = UIParent:GetEffectiveScale()
    local s = frame:GetScale()
    local left, top = frame:GetLeft() * s, frame:GetTop() * s
    local startX = GetCursorPosition() / ui
    local startW = frame:GetWidth() * s
    self:SetScript('OnUpdate', function()
      local x = GetCursorPosition() / ui
      local ns = math.max(MIN_SCALE, math.min(MAX_SCALE, s * (startW + x - startX) / startW))
      frame:SetScale(ns)
      frame:ClearAllPoints()
      frame:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', left / ns, top / ns)
    end)
  end)
  grip:SetScript('OnMouseUp', function(self) self:SetScript('OnUpdate', nil) end)
end
-- kein Skalier-Griff mehr: Größe kommt von der Seitenleiste

local title = f:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
title:SetPoint('TOP', 0, -3)
title:SetText('Fokus')

local wall = CreateFrame('Frame', nil, f)
local wallTex = {}

local function tex(layer, sub, c, a)
  local t = wall:CreateTexture(nil, layer, nil, sub or 0)
  t:SetColorTexture(c[1], c[2], c[3], a or 1)
  wallTex[#wallTex + 1] = t
  return t
end

-- Senkrecht: Fenster so groß wie die rechte Aktionsleiste (Breite eines Knopfes, Höhe der Leiste);
-- Turm füllt die Breite, Symbole passen hinein (eigenes samt Ring), Kopf mit Halter + Vorsprung
local fitToBar
-- Maße einer Seitenleiste aus ihren Knöpfen 1 und 12 (Leisten-Rahmen selbst sind oft anders groß).
-- Rückgabe: Breite, Höhe (in UIParent-Einheiten), Knopf 1 der linken der sichtbaren Leisten, Abstand
-- zwischen den Leisten
local function barSize()
  local s = 1 / UIParent:GetEffectiveScale()
  local function measure(prefix)
    local b1, b12 = _G[prefix .. 'Button1'], _G[prefix .. 'Button12']
    if not (b1 and b12 and b1:IsVisible() and b1:GetTop() and b12:GetBottom()) then return nil end
    local es = b1:GetEffectiveScale() * s
    return b1:GetWidth() * es, (b1:GetTop() - b12:GetBottom()) * es, b1, b1:GetLeft() * es
  end
  local wR, hR, bR, lR = measure('MultiBarRight')
  local wL, hL, bL, lL = measure('MultiBarLeft')
  local w, h, anchor = wR or wL, hR or hL, bL or bR
  if not w then return FALLBACK_W, FALLBACK_H, nil, 6 end
  local gap = 6
  if lR and lL and wL then gap = math.max(0, lR - lL - wL) end
  return w, h, anchor, gap
end

fitToBar = function()
  local w, h = barSize()
  w, h = math.floor(w + 0.5), math.floor(h + 0.5)
  -- Symmetrischer Verband: Ziegelbreite ungerade, Turm = 2 Ziegel + 1 Fuge
  local bw = math.floor((w - 2 * FRAME_PAD - 1) / 2)
  if bw % 2 == 0 then bw = bw - 1 end
  BRICK_W = bw
  TOWER_W = 2 * bw + 1
  SIZE_ME = math.floor((TOWER_W - 2 - HALO_PX[1]) / ROLE_ICON_VISIBLE)   -- eigener Ring passt mit 1 px Luft in den Turm
  SIZE_OTHER = SIZE_ME   -- andere gleich groß wie das eigene (das erkennt man am Ring)
  local wallTop = TITLE_H + SIZE_OTHER + 2 + PCT_H + MERLON_H + 2
  HEAD = wallTop - (TITLE_H + SIZE_OTHER / 2)
  -- Turm endet genau auf einer Ziegelreihe; unten gleicher Abstand zum Rahmen wie an den Seiten,
  -- Rest geht in den Kopf
  local side = math.floor((w - TOWER_W) / 2)
  local rowH = BRICK_H + 1
  local rows = math.floor((h - wallTop - side + 1) / rowH)
  V.len = rows * rowH - 1
  V.w, V.h, V.x = w, h, side + TOWER_W / 2
  V.y = h - side - V.len
  HEAD = HEAD + (V.y - wallTop)
  V.yFlip = TITLE_H + MERLON_H + 2
end

-- Burgmauer: Mörtel-Grund, Steine im Wechsel, Kappe mit Zinnen, rotes Glühen am Tank-Ende
local function buildWall()
  for _, t in ipairs(wallTex) do t:Hide() end
  wipe(wallTex)
  local L = opt.vert and V or H
  if opt.vert then fitToBar() end
  wall:ClearAllPoints()
  local thick = opt.vert and TOWER_W or THICK
  if opt.vert then
    wall:SetSize(thick, L.len)
    wall:SetPoint('TOPLEFT', f, 'TOPLEFT', math.floor(L.x + SKIN_DX + NUDGE_X - thick / 2 + 0.5), -(opt.flip and L.yFlip or L.y))
    title:ClearAllPoints()
    title:SetPoint('TOP', f, 'TOP', math.floor(SKIN_DX + NUDGE_X + 0.5), -3)
  else
    wall:SetSize(L.len, thick)
    wall:SetPoint('BOTTOMLEFT', f, 'BOTTOMLEFT', L.x, L.y - thick / 2)
  end
  local base = tex('BACKGROUND', 0, MORTAR)
  base:SetAllPoints(wall)

  if opt.vert then
    -- Turm: symmetrischer Verband – gerade Reihen 2 ganze Ziegel, ungerade Reihen halb | ganz | halb
    local rows = math.floor((L.len + 1) / (BRICK_H + 1))
    local half = (BRICK_W - 1) / 2
    for r = 0, rows - 1 do
      local pieces
      if r % 2 == 0 then
        pieces = { { 0, BRICK_W }, { BRICK_W + 1, BRICK_W } }
      else
        pieces = { { 0, half }, { half + 1, BRICK_W }, { half + BRICK_W + 2, half } }
      end
      for k, pc in ipairs(pieces) do
        local s = tex('BORDER', 0, ((r + k) % 2 == 0) and STONE_A or STONE_B)
        s:SetSize(pc[2], BRICK_H)
        s:SetPoint('TOPLEFT', wall, 'TOPLEFT', pc[1], -(r * (BRICK_H + 1)))
      end
    end
    -- Turmspitze: Sims + Zinnen oben
    local ledge = tex('BORDER', 2, CAP)
    ledge:SetSize(thick + 6, 4)
    ledge:SetPoint('BOTTOM', wall, 'TOP', 0, 0)
    local n = 3
    local mw = (thick + 6) / (2 * n - 1)
    for i = 0, n - 1 do
      local z = tex('BORDER', 2, CAP)
      z:SetSize(mw, 7)
      z:SetPoint('BOTTOMLEFT', ledge, 'TOPLEFT', i * 2 * mw, 0)
    end
  else
    local n = math.floor(L.len / (STONE + GAP))
    for i = 0, n - 1 do
      local s = tex('BORDER', 0, (i % 2 == 0) and STONE_A or STONE_B)
      s:SetSize(STONE, thick)
      s:SetPoint('LEFT', wall, 'LEFT', i * (STONE + GAP), 0)
      -- Zinne auf jedem zweiten Stein
      if i % 2 == 0 then
        local z = tex('BORDER', 1, CAP)
        z:SetSize(STONE - 8, 6)
        z:SetPoint('BOTTOM', s, 'TOP', 0, 0)
      end
    end
    local cap = tex('BORDER', 2, CAP)
    cap:SetPoint('TOPLEFT', wall, 'TOPLEFT')
    cap:SetPoint('TOPRIGHT', wall, 'TOPRIGHT')
    cap:SetHeight(3)
  end

  -- Glühen: Streifen mit abnehmender Deckkraft vom Tank-Ende aus
  local steps, reach = 14, L.len * 0.4
  for i = 0, steps - 1 do
    local g = tex('ARTWORK', 0, GLOW, 0.55 * (1 - i / steps))
    g:SetBlendMode('ADD')
    local seg = reach / steps
    local off = i * seg
    if opt.vert then
      g:SetSize(thick + 6, seg)
      if opt.flip then g:SetPoint('BOTTOM', wall, 'BOTTOM', 0, off) else g:SetPoint('TOP', wall, 'TOP', 0, -off) end
    else
      g:SetSize(seg, thick + 6)
      if opt.flip then g:SetPoint('RIGHT', wall, 'RIGHT', -off, 0) else g:SetPoint('LEFT', wall, 'LEFT', off, 0) end
    end
  end
  for _, t in ipairs(wallTex) do t:Show() end
  f:SetSize(L.w, L.h)
end

-- Erfundene Gruppe; "Du" mit echtem Namen/Klasse, Rolle aus TWF
local function myRole()
  local db = ThreatWallForeverDB
  return db and ROLE_ATLAS[db.role or ''] and db.role or 'dps'
end

local players = {}

local function addPlayer(name, class, role, rate, me)
  local p = CreateFrame('Frame', nil, f)
  p:SetFrameLevel(wall:GetFrameLevel() + (me and 10 or 5))   -- eigenes Symbol samt Schein immer vorn
  local size = me and SIZE_ME or SIZE_OTHER
  p:SetSize(size, size)
  p.glow = p:CreateTexture(nil, 'BACKGROUND')
  p.glow:SetTexture('Interface\\Buttons\\UI-ActionButton-Border')
  p.glow:SetBlendMode('ADD')
  p.glow:SetPoint('CENTER')
  p.glow:SetSize(size * 1.9, size * 1.9)
  p.glow:SetVertexColor(1, 0.82, 0.2)   -- goldener Schein: eigenes Symbol auf der Mauer
  p.warn = p:CreateTexture(nil, 'BACKGROUND', nil, 1)
  p.warn:SetTexture('Interface\\Buttons\\UI-ActionButton-Border')
  p.warn:SetBlendMode('ADD')
  p.warn:SetPoint('CENTER')
  p.warn:SetSize(size * 1.9, size * 1.9)
  p.warn:Hide()
  p.icon = p:CreateTexture(nil, 'ARTWORK')
  p.halo = {}
  for i = 1, #HALO_PX do
    local d = p:CreateTexture(nil, 'BACKGROUND', nil, i)
    d:SetTexture('Interface\\CharacterFrame\\TempPortraitAlphaMask')
    d:SetPoint('CENTER')
    d:SetAlpha(HALO_ALPHA[i])
    d:Hide()
    p.halo[i] = d
  end
  p.icon:SetAllPoints()
  p.name = p:CreateFontString(nil, 'OVERLAY', me and 'GameFontNormal' or 'GameFontNormalSmall')
  p.name:SetText(me and (name .. ' (Du)') or name)
  local cc = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
  if cc then p.name:SetTextColor(cc.r, cc.g, cc.b) end
  p.name:Hide()
  p.pct = p:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  p:EnableMouse(true)
  p:SetScript('OnEnter', function(self)
    GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
    showTip(self)
  end)
  p:SetScript('OnLeave', function() GameTooltip:Hide() end)
  -- Klick auf den Halter oben: Symbole auf der Mauer zwischen Rolle und Klasse umschalten
  p:SetScript('OnMouseUp', function(self, button)
    if button == 'LeftButton' and self == players[1] then
      opt.classIcon = not opt.classIcon
      layout()
    end
  end)
  p.class, p.role, p.rate, p.me, p.th, p.cur = class, role, rate, me, 0, 0
  players[#players + 1] = p
  return p
end

local CLASS_ICON_SCALE = 0.75   -- Klassenwappen wirken größer als Rollensymbole → etwas kleiner

local function setIcon(p)
  local useClass = p ~= players[1] and opt.classIcon and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[p.class]
  local size = ((p.me and p ~= players[1]) and SIZE_ME or SIZE_OTHER) * (useClass and CLASS_ICON_SCALE or 1)
  p:SetSize(size, size)
  p.glow:SetSize(size * 1.9, size * 1.9)
  p.warn:SetSize(size * 1.9, size * 1.9)
  -- Eigenes Symbol auf der Mauer: rundes Rollensymbol → runder goldener Schein, eckiges Wappen → eckiger Schein
  p.useClass = useClass and true or false
  local mark = p.me and p ~= players[1]
  p.glow:SetShown(mark and useClass and true or false)
  for i, d in ipairs(p.halo) do
    d:SetShown(mark and not useClass)
    local s = 2 * math.floor((size * ROLE_ICON_VISIBLE + HALO_PX[i]) / 2 + 0.5)   -- gerade ganze Zahl: Mitte liegt auf dem Pixel
    d:SetSize(s, s)
  end
  if useClass then
    p.icon:SetTexture('Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES')
    p.icon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[p.class]))
  else
    p.icon:SetTexCoord(0, 1, 0, 1)
    p.icon:SetAtlas(ROLE_ATLAS[p.role], false)
  end
end

local function placeLabels(p)
  p.name:ClearAllPoints()
  p.pct:ClearAllPoints()
  if p.name.SetRotation then p.name:SetRotation(0) end
  if opt.vert and p == players[1] then
    -- Kopf: Rollensymbol des Halters, darunter Vorsprung-%, dann der Turm (bei flip gespiegelt); Name als Tooltip
    if opt.flip then
      p.pct:SetPoint('BOTTOM', p, 'TOP', 0, 2)
    else
      p.pct:SetPoint('TOP', p, 'BOTTOM', 0, -2)
    end
  elseif opt.vert then
    p.name:SetPoint('LEFT', p, 'RIGHT', 6, 0)
    p.pct:SetPoint('RIGHT', p, 'LEFT', -12, 0)
  else
    local w = p.name:GetStringWidth() or 0
    if p.name.SetRotation then
      p.name:SetRotation(math.pi / 2)
      p.name:SetPoint('CENTER', p, 'TOP', 0, 6 + w / 2)
    else
      p.name:SetPoint('BOTTOM', p, 'TOP', 0, 6)
    end
    p.pct:SetPoint('TOP', p, 'BOTTOM', 0, -4)
  end
end

local function setup()
  local myName = UnitName('player') or 'Du'
  local _, myClass = UnitClass('player')
  local role = myRole()
  if role == 'tank' and not opt.meTank then role = 'dps' end
  if opt.meTank then role = 'tank' end
  if role == 'tank' then
    addPlayer(myName, myClass, 'tank', 30, true)
    addPlayer('Messerjo', 'ROGUE', 'dps', 27)
  else
    addPlayer('Tankhorst', 'WARRIOR', 'tank', 30)
    addPlayer(myName, myClass, role, 27, true)
  end
  addPlayer('Feuermagier', 'MAGE', 'dps', 24)
  addPlayer('Jägerin', 'HUNTER', 'dps', 21)
  addPlayer('Heilibert', 'PRIEST', 'heal', 13)
end

function layout()
  buildWall()
  for _, p in ipairs(players) do setIcon(p) placeLabels(p) end
end

-- Position: Tank fest am Ende, die anderen nach Anteil an der Tank-Bedrohung (Demo-Werte)
local t, acc = 0, 0
local function positions(elapsed)
  local L = opt.vert and V or H
  local tank = players[1]
  local second = 0
  for i = 2, #players do second = math.max(second, players[i].th) end
  for _, p in ipairs(players) do
    local frac = (p == tank) and 1 or (tank.th > 0 and math.min(p.th / tank.th, 1) or 0)
    p.cur = p.cur + (frac - p.cur) * math.min(1, elapsed * 6)
    local d = (1 - p.cur) * L.len
    if opt.flip then d = L.len - d end
    d = math.floor(d + 0.5)   -- auf ganze Pixel: verhindert Flackern von Schein und Maske beim Verschieben
    p:ClearAllPoints()
    if opt.vert and p == tank then
      if opt.flip then p:SetPoint('CENTER', wall, 'BOTTOM', 0, -HEAD) else p:SetPoint('CENTER', wall, 'TOP', 0, HEAD) end
    elseif opt.vert then p:SetPoint('CENTER', wall, 'TOP', 0, -d)
    else p:SetPoint('CENTER', wall, 'LEFT', d, 0) end
    if p == tank then
      -- Vorsprung des Tanks vor dem Nächsten (Demo-Werte, wie Blizzards Tooltip)
      p.pct:SetShown(opt.vert)
      if second > 0 then p.pct:SetFormattedText('%d %%', math.floor(tank.th / second * 100 + 0.5)) else p.pct:SetText('–') end
    else
      p.pct:SetShown(opt.pct)
      p.pct:SetFormattedText('%d %%', math.floor(frac * 100 + 0.5))
    end
    if GameTooltip:IsOwned(p) then showTip(p) end
    local alarm = p ~= tank and frac >= 0.85
    local blinkOn = (GetTime() % 0.5) < 0.25
    if p.me and p ~= tank then
      -- Eigenes Symbol: goldener Schein blinkt bei Alarm rot (rund bei Rolle, eckig bei Klasse)
      local c = (alarm and blinkOn) and ALARM_COLOR or MARK_COLOR
      p.glow:SetVertexColor(c[1], c[2], c[3])
      for _, d in ipairs(p.halo) do d:SetVertexColor(c[1], c[2], c[3]) end
      p.warn:Hide()
    else
      -- Andere: Warn-Blinken (eckig) nur bei Klassenwappen; bei runden Rollensymbolen stört es
      p.warn:SetShown(alarm and p.useClass and blinkOn)
    end
  end
end

f:SetScript('OnUpdate', function(_, elapsed)
  if not opt.paused then
    acc = acc + elapsed
    while acc >= 0.25 do
      acc = acc - 0.25
      t = t + 0.25
      for i, p in ipairs(players) do
        local slow = (i == 1 and t > 14 and t < 20) and 0.2 or 1
        -- Eigener Wert in Phasen: erst ruhig (~55 %), dann Aufholen bis Alarm (~17–23 s), dann Pause → fällt wieder ab
        if p.me and i ~= 1 then slow = (t < 12) and 0.6 or (t < 20) and 1.2 or 0 end
        p.th = p.th + p.rate * (0.6 + math.random() * 0.8) * slow
      end
      if t > 30 then
        t = 0
        for _, p in ipairs(players) do p.th = 0 end
      end
    end
  end
  positions(elapsed)
end)

local dock   -- unten definiert (braucht layout und barSize)
SLASH_TWFRBT1 = '/rbt'
SlashCmdList.TWFRBT = function(msg)
  msg = strtrim((msg or ''):lower())
  if msg == 'vert' then opt.vert = not opt.vert layout()
  elseif msg == 'flip' then opt.flip = not opt.flip layout()
  elseif msg == 'pct' then opt.pct = not opt.pct
  elseif msg == 'icon' then opt.classIcon = not opt.classIcon layout()
  elseif msg == 'tank' then
    opt.meTank = not opt.meTank
    for _, p in ipairs(players) do p:Hide() end
    wipe(players)
    setup()
    layout()
  elseif msg == 'dock' then dock()
  elseif msg:match('^x ') then
    local v = tonumber(msg:match('^x (%-?%d+)$'))
    if v then
      NUDGE_X = NUDGE_X + v
      layout()
      print(('|cfff0c040Rennbahn-Test:|r Verschiebung jetzt %d px (Rahmen-Versatz %.1f)'):format(NUDGE_X, SKIN_DX))
    else
      print('|cfff0c040Rennbahn-Test:|r Beispiel: /rbt x 1 (nach rechts) oder /rbt x -1 (nach links)')
    end
  elseif msg == 'pause' then opt.paused = not opt.paused
  elseif msg == 'neu' then t = 0 for _, p in ipairs(players) do p.th = 0 end
  elseif msg == '' then f:SetShown(not f:IsShown())
  else
    -- Unbekannter Befehl: nichts umschalten, nur Hilfe zeigen
    print('|cfff0c040Rennbahn-Test:|r unbekannt: "' .. msg .. '". Befehle: /rbt (ein/aus), vert, flip, pct, icon, tank, pause, neu, dock, x <px>')
  end
end

local ev = CreateFrame('Frame')
ev:RegisterEvent('PLAYER_LOGIN')
-- Rahmen im Stil der Leistenknöpfe: deren Rand-Grafik (Atlas oder Datei) übernehmen und per
-- Neun-Teile-Ränder auf die Fenstergröße ziehen. Geht das nicht, bleibt der runde Tooltip-Rahmen.
local SKIN_SLICE = 14   -- Randbreite der Knopf-Grafik in Pixeln der Datei (geschätzt, ggf. anpassen)
local skinTex
local function applyBarSkin(btn)
  local nt = btn and btn.GetNormalTexture and btn:GetNormalTexture()
  if not nt then return false end
  local atlas = nt.GetAtlas and nt:GetAtlas()
  local file = nt:GetTexture()
  print(('|cfff0c040Rennbahn-Test:|r Knopf-Rand: Atlas %s, Datei %s'):format(tostring(atlas), tostring(file)))
  if not (atlas or file) then return false end
  skinTex = skinTex or f:CreateTexture(nil, 'BORDER')
  if atlas then skinTex:SetAtlas(atlas, false) else skinTex:SetTexture(file) skinTex:SetTexCoord(nt:GetTexCoord()) end
  skinTex:SetVertexColor(nt:GetVertexColor())
  -- Rahmen genauso über das Fenster legen, wie der Knopf seinen Rahmen über sich legt
  local k = btn:GetEffectiveScale() / f:GetEffectiveScale()
  local dl = (nt:GetLeft() - btn:GetLeft()) * k
  local dr = (nt:GetRight() - btn:GetRight()) * k
  local dt = (nt:GetTop() - btn:GetTop()) * k
  local db = (nt:GetBottom() - btn:GetBottom()) * k
  print(('|cfff0c040Rennbahn-Test:|r Rahmen-Versatz links %.1f, rechts %.1f, oben %.1f, unten %.1f'):format(dl, dr, dt, db))
  skinTex:ClearAllPoints()
  skinTex:SetPoint('TOPLEFT', f, 'TOPLEFT', dl, dt)
  skinTex:SetPoint('BOTTOMRIGHT', f, 'BOTTOMRIGHT', dr, db)
  SKIN_DX = (dl + dr) / 2
  if not skinTex.SetTextureSliceMargins then
    print('|cfff0c040Rennbahn-Test:|r Neun-Teile-Ränder gibt es hier nicht – Tooltip-Rahmen bleibt.')
    skinTex:Hide()
    return false
  end
  skinTex:SetTextureSliceMargins(SKIN_SLICE, SKIN_SLICE, SKIN_SLICE, SKIN_SLICE)
  if skinTex.SetTextureSliceMode and Enum and Enum.UITextureSliceMode then
    skinTex:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
  end
  skinTex:Show()
  -- Mit Knopf-Rahmen kein eigener Hintergrund und kein eigener Rand mehr: nur Rahmen + Mauer
  f:SetBackdropBorderColor(0, 0, 0, 0)
  f:SetBackdropColor(0, 0, 0, 0)
  return true
end

-- Andocken: links neben die linke sichtbare Seitenleiste, gleicher Abstand wie zwischen den Leisten
local SNAP_PX = 15   -- magnetisch: so nah an der Leiste rastet das Fenster ein
local db             -- gespeichert: docked (true/false), x/y (freie Position, oben links)

-- An die linke sichtbare Seitenleiste hängen (wandert mit, wenn die Leiste verschoben wird)
local function attach(anchor, gap)
  f:SetScale(1)
  f:ClearAllPoints()
  f:SetPoint('TOPRIGHT', anchor, 'TOPLEFT', -gap, 0)
end

function dock()
  local w, h, anchor, gap = barSize()
  if anchor then applyBarSkin(anchor) end
  layout()
  if db.docked and anchor and opt.vert then
    attach(anchor, gap)
  else
    f:ClearAllPoints()
    if db.x then f:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', db.x, db.y) else f:SetPoint('CENTER', 0, 150) end
  end
end

-- Ziehen: erst vom Anker lösen, beim Loslassen prüfen, ob es nah genug an der Leiste ist
f:SetScript('OnDragStart', function(self)
  local l, tp = self:GetLeft(), self:GetTop()
  self:ClearAllPoints()
  self:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', l, tp)
  self:StartMoving()
end)
f:SetScript('OnDragStop', function(self)
  self:StopMovingOrSizing()
  local _, _, anchor, gap = barSize()
  local snapped = false
  if anchor and opt.vert then
    local k = anchor:GetEffectiveScale() / UIParent:GetEffectiveScale()
    local dx = (anchor:GetLeft() * k - gap) - self:GetRight()
    local aTop = anchor:GetTop() * k
    local overlap = self:GetBottom() < aTop and self:GetTop() > aTop - self:GetHeight()
    snapped = math.abs(dx) <= SNAP_PX and overlap
  end
  db.docked = snapped
  if snapped then
    attach(anchor, gap)
    print('|cfff0c040Rennbahn-Test:|r an die Leiste angedockt')
  else
    db.x, db.y = self:GetLeft(), self:GetTop()
    print('|cfff0c040Rennbahn-Test:|r frei – zum Andocken nah an die Leiste ziehen')
  end
end)

-- Leisten ein-/ausgeblendet, Bearbeitungsmodus gespeichert, UI-Skalierung: kurz warten, neu messen
local pending = false
local function refreshSoon()
  if pending then return end
  pending = true
  C_Timer.After(0.3, function()
    pending = false
    dock()
  end)
end

ev:RegisterEvent('UI_SCALE_CHANGED')
ev:RegisterEvent('DISPLAY_SIZE_CHANGED')
if C_EditMode then ev:RegisterEvent('EDIT_MODE_LAYOUTS_UPDATED') end
ev:SetScript('OnEvent', function(_, event)
  if event ~= 'PLAYER_LOGIN' then
    if db then refreshSoon() end
    return
  end
  TWFRennbahnTestDB = TWFRennbahnTestDB or { docked = true }
  db = TWFRennbahnTestDB
  for _, name in ipairs({ 'MultiBarLeft', 'MultiBarRight' }) do
    local bar = _G[name]
    if bar then
      bar:HookScript('OnShow', refreshSoon)
      bar:HookScript('OnHide', refreshSoon)
    end
  end
  setup()
  layout()
  -- Leisten stehen beim Einloggen evtl. noch nicht fertig → kurz warten, dann messen und andocken.
  -- Bis dahin unsichtbar, damit die Größe nicht sichtbar springt.
  f:SetAlpha(0)
  C_Timer.After(1, function()
    dock()
    f:SetAlpha(1)
  end)
  print('|cfff0c040Rennbahn-Test:|r /rbt ein/aus, /rbt vert, /rbt flip, /rbt pct, /rbt icon, /rbt pause, /rbt neu, /rbt tank, /rbt dock')
end)
