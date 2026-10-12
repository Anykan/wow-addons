--[[
  Symbols.lua — Symbol-Markierung Mob ↔ Aggro-Halter (Anforderung L).

  Tank-Modus:    Ein Mob im Kampf, den NICHT du hältst, bekommt das Rollensymbol
                 seines Halters (Heiler-Kreuz, DD-Schwert, Tank-Schild). Der Halter
                 bekommt dasselbe Symbol über den Kopf (an seiner freundlichen
                 Nameplate, gefunden per GUID-Vergleich, getestet in T10c).
  DD/Heal-Modus: Nur ein Mob, der DICH schlägt, bekommt das DD-Symbol. Über deinem
                 Kopf erscheint nichts.

  Wer einen Mob hält, ermittelt Detection.lua (ns.aggroHolder), eine Quelle für
  Liste, Nameplates und Symbole. Symbolsatz und Größen stehen in Config.lua.
]]

local _, ns = ...
local C = ns.Config
local Y = C.SYMBOL_LAYOUT

local cache = {}        -- Mob-Token -> { at = Zeitpunkt, holder = Gruppen-Token oder nil }
local lastHolder = {}   -- Mob-Token -> letzter Halter (Debug nur bei Wechsel)
local lastMissing = ''  -- Debug: Halter ohne sichtbare Nameplate, nur bei Änderung melden

local function active()
  return ns.db and ns.db.symbolMarks
end

-- Halter mit Zwischenspeicher: pro Takt nur einmal fragen (Liste und Nameplates
-- teilen sich das Ergebnis), im Schlachtzug gedrosselt (viele Abfragen pro Mob).
local function holderOf(mob)
  local now = GetTime()
  local interval = IsInRaid() and Y.RAID_INTERVAL or C.TICK
  local e = cache[mob]
  if e and now - e.at < interval then return e.holder end
  local holder = ns.aggroHolder(mob)
  cache[mob] = { at = now, holder = holder }
  if lastHolder[mob] ~= holder then
    lastHolder[mob] = holder
    ns.dbg('SYMBOLS', 'Halter von ' .. mob .. ': ' .. tostring(holder))
  end
  return holder
end

local function roleKey(holder)
  local ok, role = pcall(UnitGroupRolesAssigned, holder)
  role = ok and ns.plain(role)
  if role == 'TANK' or role == 'HEALER' or role == 'DAMAGER' then return role end
  return 'NONE'
end

-- Symbol für einen Mob (Schlüssel in C.SYMBOLS) und der Halter, oder nil
function ns.symbolFor(mob)
  if not active() or not mob then return nil end
  local holder = holderOf(mob)
  if ns.db.role == 'tank' then
    if holder and holder ~= 'player' then return roleKey(holder), holder end
  elseif holder == 'player' then
    return 'AGGRO_SELF', holder
  end
  return nil
end

-- Grafik setzen: Atlas oder Datei, optional mit Bildausschnitt
function ns.setSymbolTexture(tex, key)
  local entry = C.SYMBOLS[key]
  if not entry then return false end
  local texture, coords = entry, nil
  if type(entry) == 'table' then texture, coords = entry.texture, entry.coords end
  if ns.hasAtlas(texture) then
    tex:SetAtlas(texture, false)
  else
    tex:SetTexture(texture)
    if coords then tex:SetTexCoord(unpack(coords)) else tex:SetTexCoord(0, 1, 0, 1) end
  end
  return true
end

-- Symbol-Frames an Nameplates --------------------------------------------------------------

-- Ein kleiner Frame pro Nameplate und Zweck; nimmt keine Maus an (Klick geht an Blizzard)
local function symbolFrame(nameplate, field, size)
  local f = nameplate[field]
  if f then return f end
  f = CreateFrame('Frame', nil, nameplate)
  f:SetFrameLevel(nameplate:GetFrameLevel() + Y.LEVEL)
  f:SetSize(size, size)
  f.tex = f:CreateTexture(nil, 'OVERLAY')
  f.tex:SetAllPoints()
  nameplate[field] = f
  return f
end

local function hideSymbols(nameplate)
  if nameplate.twfMobSymbol then nameplate.twfMobSymbol:Hide() end
  if nameplate.twfPlayerSymbol then nameplate.twfPlayerSymbol:Hide() end
end

-- Am Mob: links neben dem TWF-Balken, sonst neben Blizzards Lebensleiste
local function showMobSymbol(nameplate, key)
  local f = symbolFrame(nameplate, 'twfMobSymbol', Y.MOB_SIZE)
  local uf = nameplate.UnitFrame
  local anchor = (nameplate.twfPlate and nameplate.twfPlate:IsShown() and nameplate.twfPlate)
    or (uf and (uf.healthBar or uf.HealthBar)) or nameplate
  f:ClearAllPoints()
  f:SetPoint('RIGHT', anchor, 'LEFT', -Y.MOB_GAP, 0)
  if ns.setSymbolTexture(f.tex, key) then f:Show() else f:Hide() end
end

-- Über dem Mitspieler
local function showPlayerSymbol(nameplate, key)
  local f = symbolFrame(nameplate, 'twfPlayerSymbol', Y.PLAYER_SIZE)
  f:ClearAllPoints()
  f:SetPoint('BOTTOM', nameplate, 'TOP', 0, Y.PLAYER_Y)
  if ns.setSymbolTexture(f.tex, key) then f:Show() else f:Hide() end
end

local function plainGUID(unit)
  local ok, guid = pcall(UnitGUID, unit)
  return ok and ns.plain(guid) or nil
end

local function unitOf(nameplate)
  return nameplate.namePlateUnitToken or (nameplate.UnitFrame and nameplate.UnitFrame.unit)
end

-- Ein Durchlauf: Symbole an Mobs setzen, Halter sammeln, Symbole über Mitspielern setzen
local function updateAll()
  local plates = C_NamePlate.GetNamePlates(false) or {}
  if not active() then
    for _, nameplate in ipairs(plates) do hideSymbols(nameplate) end
    ns.updateGroupSymbols({})
    return
  end

  local playerMarks = {}   -- GUID des Halters -> Symbol (nur Tank-Modus)
  local function remember(key, holder)
    if ns.db.role == 'tank' and holder then
      local guid = plainGUID(holder)
      if guid then playerMarks[guid] = key end
    end
  end

  -- 1. Mobs mit Nameplate
  for _, nameplate in ipairs(plates) do
    local unit = unitOf(nameplate)
    local key, holder
    if unit and ns.engaged(unit) then key, holder = ns.symbolFor(unit) end
    if key then
      showMobSymbol(nameplate, key)
      remember(key, holder)
    elseif nameplate.twfMobSymbol then
      nameplate.twfMobSymbol:Hide()
    end
  end
  -- 2. Mobs aus der Liste ohne eigene Nameplate (z. B. nur über das Ziel eines Mitspielers bekannt)
  for _, t in pairs(ns.tracked) do
    if t.shownColor and t.unit and not t.unit:find('^nameplate') then
      local key, holder = ns.symbolFor(t.unit)
      if key then remember(key, holder) end
    end
  end

  -- 3. Mitspieler: Symbol über dem Kopf, wenn ein Mob zu ihnen läuft
  local found = {}
  for _, nameplate in ipairs(plates) do
    local unit = unitOf(nameplate)
    local okP, isPlayer = pcall(UnitIsPlayer, unit or '')
    local guid = unit and okP and isPlayer and plainGUID(unit)
    local key = guid and playerMarks[guid]
    if key then
      found[guid] = true
      showPlayerSymbol(nameplate, key)
    elseif nameplate.twfPlayerSymbol then
      nameplate.twfPlayerSymbol:Hide()
    end
  end

  -- 4. Immer zusätzlich: Symbol am Gruppenfenster (in Instanzen sind freundliche
  --    Nameplates gesperrt, siehe TESTS-MACHBARKEIT.md)
  ns.updateGroupSymbols(playerMarks)

  -- Debug: Halter ohne sichtbare freundliche Nameplate (nur bei Änderung)
  local missing = {}
  for guid in pairs(playerMarks) do if not found[guid] then missing[#missing + 1] = guid end end
  table.sort(missing)
  local text = table.concat(missing, ', ')
  if text ~= lastMissing then
    lastMissing = text
    if text ~= '' then ns.dbg('SYMBOLS', 'Keine freundliche Nameplate für Halter: ' .. text) end
  end
end

local function onSettingChanged(key)
  if key ~= 'symbolMarks' then return end
  ns.dbg('SYMBOLS', 'Symbol-Markierung ' .. (active() and 'an' or 'aus'))
  updateAll()
  -- Ausgeschaltet: freundliche Nameplates auf den alten Wert zurück, falls TWF sie eingeschaltet hat
  if not active() then ns.restoreGameOptions('symbolMarks') end
end

ns.RegisterModule('Symbols', {
  OnTick = updateAll,
  OnSettingChanged = onSettingChanged,
})
