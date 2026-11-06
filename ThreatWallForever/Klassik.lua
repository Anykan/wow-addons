--[[
  Klassik.lua — Klassik-Fenster für Ziel und Fokus (Anforderung AI, Änderung 2026-11-06).

  Im Reiter Ansicht wählt man in den Spalten Ziel und Fokus "Mauer | Klassisch". Bei
  "Klassisch" ist die Mauer aus (Leiste.lua) und stattdessen zeigt dieses Fenster im Design
  der TWF-Liste: im Kopf den Gegner (Schlachtzugsymbol + Name), darunter pro Gruppenmitglied
  (auf Wunsch mit Begleitern) eine Zeile: Rollensymbol, Name in Klassenfarbe, Balken = Aggro,
  Aggro-% rechts. Der Aggro-Halter steht oben und ist markiert (Rahmen, roter Balken).

  Sortierung (Solo-Test 2026-11-06: eigene Werte gegen Ziel und Fokus lesbar):
    alle Werte lesbar → echt nach Aggro (Halter zuerst);
    sonst (z. B. Boss)  → Halter, dann nach Stufe (UnitThreatSituation, lesbar), dann fest
                          Tank, Heiler, DD. Geheime Werte gehen nur an Balken und Text.
  Jedes Fenster hat eigene Zeilen, Deckkraft, Skalierung, Breite (Ziehen) und Position;
  die Zeilenhöhe ist die der Liste. Sichtbarkeit ("Nur im Kampf", "Nur in Gruppe") wie bei der Mauer.
]]

local _, ns = ...
local C = ns.Config
local L = ns.L
local K = C.CLASSIC
local W = C.WINDOW
local A = C.ATLAS
local T = C.TEXTURE
local ROW = C.ROW
local S = C.THREAT_STATUS

local wins = {}              -- key ('target'/'focus') -> Fenster
local ORDER = { 'target', 'focus' }

-- Einstellungen ----------------------------------------------------------------------------------

-- Einstellung eines Fensters, z. B. get(win, 'Alpha') = db.targetClassicAlpha
local function get(win, name)
  return ns.db[win.key .. 'Classic' .. name]
end

-- Position und Breite je Fenster (db.classicPos.target / .focus)
local function pos(key)
  if type(ns.db.classicPos) ~= 'table' then ns.db.classicPos = {} end
  local p = ns.db.classicPos[key]
  if type(p) ~= 'table' then
    p = {}
    ns.db.classicPos[key] = p
  end
  return p
end

-- Checkbox "Testzeilen" (Laufzeit-Zustand, nicht gespeichert)
local function testMode(win)
  return ns.state[win.key .. 'ClassicTest'] and true or false
end

-- Bei "Klassisch": sichtbar wie die Mauer (an, Kampf, Gruppe) oder solange Testzeilen an sind
local function wanted(win)
  if ns.db[win.key .. 'Style'] ~= 'classic' then return false end
  return testMode(win) or ns.barWanted(win.key)
end

-- Position -------------------------------------------------------------------------------------

local function place(win)
  local f, p = win.frame, pos(win.key)
  local scale = f:GetScale()
  f:ClearAllPoints()
  if ns.num(p.left) and ns.num(p.top) then
    f:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', p.left / scale, p.top / scale)
  else
    local d = K.DEFAULT_POS[win.key]
    f:SetPoint('TOPLEFT', UIParent, 'CENTER', d[1] / scale, d[2] / scale)
  end
  f:SetWidth(ns.num(p.width) and p.width or K.WIDTH)
end

local function save(win)
  local f, p = win.frame, pos(win.key)
  local left, top, w = f:GetLeft(), f:GetTop(), f:GetWidth()
  if not (ns.num(left) and ns.num(top)) then return end
  local scale = f:GetScale()
  p.left, p.top = left * scale, top * scale
  if ns.num(w) then p.width = w end
  place(win)
end

local function startMove(win, button)
  if button and button ~= 'LeftButton' then return end
  if ns.db.locked then return end   -- "Alles fixieren"
  win.frame.moving = true
  win.frame:StartMoving()
end

local function stopMove(win)
  local f = win.frame
  if not f.moving then return end
  f:StopMovingOrSizing()
  f.moving = false
  save(win)
  ns.dbg('BAR', win.key .. '-Klassik-Fenster verschoben')
end

-- Höhe für n Zeilen: Kopf + Rand + Zeilen (wie die Liste)
local function heightFor(win, n)
  return W.HEADER_H + ROW.LIST_VPAD + n * (ns.db.rowHeight + ROW.SPACING)
end

-- Zeilen ---------------------------------------------------------------------------------------

local function buildRow(win, i)
  local row = CreateFrame('Frame', nil, win.frame.body)
  row.bar = ns.makeCastBar(row)
  row.bar:SetPoint('TOPLEFT', ROW.BAR_INSET, -ROW.BAR_INSET)
  row.bar:SetPoint('BOTTOMRIGHT', -ROW.BAR_INSET, ROW.BAR_INSET)
  row.bar:SetMinMaxValues(0, 100)

  -- Texte und Symbol über dem Balkenrahmen
  local over = CreateFrame('Frame', nil, row.bar)
  over:SetAllPoints(row.bar)
  over:SetFrameLevel(row.bar:GetFrameLevel() + 2)

  row.icon = over:CreateTexture(nil, 'OVERLAY')
  row.icon:SetPoint('LEFT', over, 'LEFT', ROW.TEXT_X, 0)

  row.pct = over:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  row.pct:SetDrawLayer('OVERLAY', ROW.TEXT_LAYER)
  row.pct:SetPoint('RIGHT', over, 'RIGHT', K.PCT_RIGHT, 0)
  row.pct:SetWidth(K.PCT_W)
  row.pct:SetJustifyH('RIGHT')

  row.name = over:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  row.name:SetDrawLayer('OVERLAY', ROW.TEXT_LAYER)
  row.name:SetPoint('LEFT', row.icon, 'RIGHT', ROW.GAP, 0)
  row.name:SetPoint('RIGHT', row.pct, 'LEFT', -ROW.GAP, 0)
  row.name:SetJustifyH('LEFT')
  row.name:SetWordWrap(false)

  row.glow = ns.createGlow(row, K.HOLDER_GLOW)
  win.rows[i] = row
  return row
end

local function layoutRow(win, row, i)
  local h = ns.db.rowHeight
  row:ClearAllPoints()
  row:SetHeight(h)
  row:SetPoint('TOPLEFT', win.frame, 'TOPLEFT', ROW.PADDING, -(W.HEADER_H + ROW.PADDING + (i - 1) * (h + ROW.SPACING)))
  row:SetPoint('RIGHT', win.frame, 'RIGHT', -ROW.PADDING, 0)
  local s = h - 2 * ROW.BAR_INSET - K.ICON_PAD
  row.icon:SetSize(s, s)
  row.laidOutH = h
end

-- Werte ----------------------------------------------------------------------------------------

-- Einheiten der Gruppe (du zuerst, party bzw. raid), auf Wunsch je mit Begleiter dahinter
local function units(win)
  local list = {}
  for _, u in ipairs(ns.groupUnits()) do
    list[#list + 1] = u
    if get(win, 'Pets') then
      local pet = (u == 'player') and 'pet' or u:gsub('^party', 'partypet'):gsub('^raid', 'raidpet')
      list[#list + 1] = pet
    end
  end
  return list
end

-- Einträge sammeln: nur Einheiten auf der Bedrohungsliste (Stufe lesbar, sonst nil)
local function collect(win, mob)
  local list, allPlain = {}, true
  local holder, holderStatus
  for _, u in ipairs(units(win)) do
    if UnitExists(u) then
      local okS, st = pcall(UnitThreatSituation, u, mob)
      st = okS and ns.plain(st) or nil
      if st then
        local ok, _, _, scaled = pcall(UnitDetailedThreatSituation, u, mob)
        if not ok then scaled = nil end
        if ns.IsSecret(scaled) then allPlain = false end
        local e = { unit = u, status = st, pct = scaled, holder = false, role = ns.groupRole(u) }
        list[#list + 1] = e
        if st >= S.INSECURE and (not holderStatus or st > holderStatus) then holder, holderStatus = e, st end
      end
    end
  end
  if holder then holder.holder = true end

  table.sort(list, function(a, b)
    if a.holder ~= b.holder then return a.holder end
    if allPlain then
      local pa, pb = a.pct or 0, b.pct or 0
      if pa ~= pb then return pa > pb end
    elseif a.status ~= b.status then
      return a.status > b.status
    end
    local ra, rb = K.ROLE_ORDER[a.role] or 9, K.ROLE_ORDER[b.role] or 9
    if ra ~= rb then return ra < rb end
    return a.unit < b.unit
  end)
  return list, allPlain
end

-- Testzeilen aus C.CLASSIC.TEST_ROWS, so viele wie "Max. Zeilen" (wie die Liste)
local function testList(win)
  local list, n, i = {}, #K.TEST_ROWS, 0
  while #list < get(win, 'MaxRows') and i < 2 * get(win, 'MaxRows') + n do
    i = i + 1
    local t = K.TEST_ROWS[(i - 1) % n + 1]
    if not t[7] or get(win, 'Pets') then
      local name = i > n and (t[1] .. ' ' .. i) or t[1]
      list[#list + 1] = { test = true, name = name, class = t[2], role = t[3], pct = t[4],
        holder = (i == 1) and t[5] or false, lead = t[6] }
    end
  end
  return list
end

-- Wert rechts in der Zeile: Halter mit "Vorsprung" = Vorsprung vor Platz 2 (vom Spiel
-- berechnet, evtl. geheim), sonst die skalierte Aggro. nil = nichts anzeigen.
local function shownValue(win, e, mob)
  if e.test then return (e.holder and get(win, 'Lead') and e.lead) or e.pct end
  if e.holder and get(win, 'Lead') then
    local ok, lead = pcall(UnitThreatPercentageOfLead, e.unit, mob)
    if ok and (ns.IsSecret(lead) or (lead and lead > 0)) then return lead end
  end
  return e.pct
end

local function drawRow(win, row, e, mob)
  local h = ns.db.rowHeight
  if row.laidOutH ~= h then layoutRow(win, row, row.index) end

  ns.tintCastBar(row.bar, e.holder and K.HOLDER_COLOR or K.BAR_COLOR)
  -- Füllung = skalierte Aggro (geheim → nur weiterreichen)
  if not pcall(row.bar.SetValue, row.bar, e.pct or 0) then row.bar:SetValue(0) end

  row.icon:SetAtlas(e.test and (C.SYMBOLS[e.role] or C.SYMBOLS.NONE) or ns.roleAtlas(e.unit), false)

  local class
  if e.test then
    row.name:SetText(e.name)
    class = e.class
  else
    local okN, name = pcall(UnitName, e.unit)
    if not (okN and pcall(row.name.SetText, row.name, name or '?')) then row.name:SetText('?') end
    local okC, _, c = pcall(UnitClass, e.unit)
    class = okC and ns.plain(c) or nil
  end
  local cc = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
  if cc then row.name:SetTextColor(cc.r, cc.g, cc.b) else row.name:SetTextColor(unpack(K.PET_COLOR)) end

  if get(win, 'Threat') then
    local v = shownValue(win, e, mob)
    -- erst auf "geheim" prüfen: einen geheimen Wert mit nil zu vergleichen ist verboten
    local shown = (ns.IsSecret(v) or v ~= nil)
      and pcall(row.pct.SetFormattedText, row.pct, C.NAMEPLATES.THREAT_PCT_FORMAT, v)
    if not shown then row.pct:SetText('') end
    row.pct:Show()
  else
    row.pct:SetText('')
    row.pct:Hide()
  end

  ns.setGlow(row.glow, e.holder)
  row:Show()
end

-- Fenster füllen ---------------------------------------------------------------------------------

local function update(win)
  local f, mob = win.frame, win.key
  local okE, exists = pcall(UnitExists, mob)
  local okA, hostile = pcall(UnitCanAttack, 'player', mob)
  local list = {}
  if testMode(win) then
    list = testList(win)
    win.name:SetText(L.PREVIEW_NAME)
    win.mark:Hide()
    win.empty:SetText('')
  elseif okE and exists and okA and hostile then
    list = collect(win, mob)
    if not pcall(win.name.SetText, win.name, UnitName(mob)) then win.name:SetText('') end
    local okM, idx = pcall(GetRaidTargetIndex, mob)
    if not (okM and ns.setRaidMark(win.mark, idx)) then win.mark:Hide() end
    win.empty:SetText(#list == 0 and L.CLASSIC_NO_THREAT or '')
  else
    win.name:SetText('')
    win.mark:Hide()
    win.empty:SetText(win.key == 'focus' and L.CLASSIC_NO_FOCUS or L.CLASSIC_NO_TARGET)
  end
  -- Name hinter das Symbol bzw. direkt hinter den Titel
  win.name:ClearAllPoints()
  win.name:SetPoint('LEFT', win.mark:IsShown() and win.mark or win.title, 'RIGHT', K.MARK_GAP, 0)
  win.name:SetPoint('RIGHT', win.header, 'RIGHT', -K.MARK_GAP, 0)

  local minR, maxR = get(win, 'MinRows'), get(win, 'MaxRows')
  local wantedRows = math.max(minR, math.min(#list, maxR))
  local height = heightFor(win, wantedRows)
  if math.abs(f:GetHeight() - height) > W.HEIGHT_TOLERANCE then f:SetHeight(height) end

  local shown = math.min(#list, maxR)
  for i = 1, shown do
    local row = win.rows[i] or buildRow(win, i)
    row.index = i
    drawRow(win, row, list[i], mob)
  end
  for i = shown + 1, #win.rows do win.rows[i]:Hide() end
end

-- Aussehen anwenden (Skalierung, Deckkraft, Zeilenhöhe, Griff)
local function applyLook(win)
  local f = win.frame
  f:SetScale(get(win, 'Scale'))
  place(win)
  f.bg:SetAlpha(get(win, 'Alpha'))
  win.grip:SetShown(not ns.db.locked)
  for i, row in ipairs(win.rows) do layoutRow(win, row, i) end
end

-- Aufbau ----------------------------------------------------------------------------------------

local function newWindow(key)
  local win = { key = key, rows = {} }
  local f = CreateFrame('Frame', K.NAME[key], UIParent)
  win.frame = f
  f:SetFrameStrata('MEDIUM')
  f:SetClampedToScreen(true)
  f:SetMovable(true)
  f:SetResizable(true)
  f:EnableMouse(true)
  if f.SetResizeBounds then
    f:SetResizeBounds(W.MIN_W, W.MIN_H, W.MAX_W, W.MAX_H)
  elseif f.SetMinResize then
    f:SetMinResize(W.MIN_W, W.MIN_H)
    f:SetMaxResize(W.MAX_W, W.MAX_H)
  end
  f:SetSize(K.WIDTH, heightFor(win, get(win, 'MinRows')))
  f:SetScript('OnMouseDown', function(_, button) startMove(win, button) end)
  f:SetScript('OnMouseUp', function() stopMove(win) end)
  f:SetScript('OnHide', function() stopMove(win) end)

  f.body = CreateFrame('Frame', nil, f)
  f.body:SetAllPoints()
  f.bg = f.body:CreateTexture(nil, 'BACKGROUND')
  f.bg:SetAllPoints()
  if not ns.setAtlas(f.bg, A.WINDOW_BG) then f.bg:SetColorTexture(unpack(W.BG_FALLBACK)) end

  win.empty = f.body:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
  win.empty:SetPoint('TOPLEFT', W.EMPTY_X, -W.HEADER_H - W.EMPTY_Y)
  win.empty:SetPoint('BOTTOMRIGHT', -W.EMPTY_X, W.EMPTY_Y)
  win.empty:SetJustifyH('CENTER')
  win.empty:SetJustifyV('TOP')
  win.empty:SetTextColor(unpack(C.EMPTY_TEXT_COLOR))

  -- Kopf: "Ziel"/"Fokus" in Gold, Schlachtzugsymbol, Gegnername
  local header = CreateFrame('Frame', nil, f)
  win.header = header
  header:SetPoint('TOPLEFT')
  header:SetPoint('TOPRIGHT')
  header:SetHeight(W.HEADER_H)
  header:EnableMouse(true)
  header:SetScript('OnMouseDown', function(_, button) startMove(win, button) end)
  header:SetScript('OnMouseUp', function() stopMove(win) end)
  header.bg = header:CreateTexture(nil, 'BACKGROUND', nil, 1)
  header.bg:SetAllPoints()
  if not ns.setAtlas(header.bg, A.HEADER_BG, T.FLAT) then header.bg:SetColorTexture(unpack(W.HEADER_FALLBACK)) end

  win.title = header:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
  win.title:SetPoint('LEFT', W.TITLE_X, 0)
  win.title:SetText(L[K.TITLE[key]])
  win.title:SetTextColor(unpack(C.TITLE_COLOR))

  win.mark = ns.createRaidMark(header, K.MARK_SIZE)
  win.mark:SetPoint('LEFT', win.title, 'RIGHT', K.MARK_GAP, 0)

  win.name = header:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  win.name:SetJustifyH('LEFT')
  win.name:SetWordWrap(false)
  win.name:SetTextColor(unpack(K.NAME_COLOR))

  -- Griff unten rechts: nur die Breite ziehen, die Höhe folgt den Zeilen (wie die Liste)
  local grip = CreateFrame('Button', nil, f.body)
  win.grip = grip
  grip:SetFrameLevel(f:GetFrameLevel() + W.GRIP_LEVEL)
  if ns.hasAtlas(A.GRIP) then
    grip:SetSize(W.GRIP_SIZE, W.GRIP_SIZE)
    grip:SetPoint('BOTTOMRIGHT', W.GRIP_X, W.GRIP_Y)
    grip:SetNormalAtlas(A.GRIP)
    grip:SetHighlightAtlas(A.GRIP_HOVER)
    grip:SetPushedAtlas(A.GRIP_PRESSED)
    grip:SetHitRectInsets(unpack(W.GRIP_HIT))
  else
    grip:SetSize(W.GRIP_FALLBACK_SIZE, W.GRIP_FALLBACK_SIZE)
    grip:SetPoint('BOTTOMRIGHT', W.GRIP_FALLBACK_X, W.GRIP_FALLBACK_Y)
    grip:SetNormalTexture(T.SIZE_GRABBER .. '-Up')
    grip:SetHighlightTexture(T.SIZE_GRABBER .. '-Highlight')
    grip:SetPushedTexture(T.SIZE_GRABBER .. '-Down')
  end
  grip:SetAlpha(0)
  grip:SetScript('OnMouseDown', function()
    if ns.db.locked then return end
    f.moving = true
    f:StartSizing('RIGHT')
  end)
  grip:SetScript('OnMouseUp', function() stopMove(win) end)

  -- Griff nur zeigen, solange die Maus über dem Fenster ist (weich ein-/ausblenden)
  local watcher = CreateFrame('Frame', nil, f)
  watcher:Hide()
  watcher:SetScript('OnUpdate', function(self, elapsed)
    local over = f:IsMouseOver() or grip:IsMouseOver() or f.moving
    local alpha = grip:GetAlpha() + (over and elapsed or -elapsed) * W.GRIP_FADE_SPEED
    if alpha >= 1 then alpha = 1 elseif alpha <= 0 then alpha = 0 end
    grip:SetAlpha(alpha)
    if not over and alpha == 0 then self:Hide() end
  end)
  local function hover() watcher:Show() end
  f:SetScript('OnEnter', hover)
  grip:SetScript('OnEnter', hover)
  header:SetScript('OnEnter', hover)

  f:Hide()
  wins[key] = win
  return win
end

-- Modul ------------------------------------------------------------------------------------------

local function refreshAll()
  for _, key in ipairs(ORDER) do
    local win = wins[key]
    if win then
      local on = wanted(win)
      if on and not win.frame:IsShown() then
        applyLook(win)
        ns.dbg('BAR', key .. '-Klassik-Fenster an')
      end
      win.frame:SetShown(on)
      if on then update(win) end
    end
  end
end

ns.RegisterModule('Klassik', {
  OnLogin = function()
    for _, key in ipairs(ORDER) do applyLook(newWindow(key)) end
    refreshAll()
  end,
  OnTick = refreshAll,
  OnSettingChanged = function(key)
    for _, win in pairs(wins) do
      local k = key or ''
      if k == 'locked' or k:find('^' .. win.key .. 'Classic') or k:find('^' .. win.key .. 'Bar')
          or k == win.key .. 'Style' then
        applyLook(win)
      end
    end
    refreshAll()
  end,
})
