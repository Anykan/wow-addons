--[[
  Symbols.lua — Aggro-Ziel am Mob (Anforderung L, neues Konzept vom 2026-10-12).

  Zeigt an der Nameplate des Mobs, wen er angreift. Nichts am Spieler selbst, keine
  freundlichen Nameplates (die sind in Instanzen gesperrt).

  Tank-Modus:    Greift der Mob NICHT dich an, steht als zweite Zeile über dem
                 Mobnamen: Rollensymbol + Name des Angegriffenen (Klassenfarbe).
                 Auch bei einem zweiten Tank (Tank-Symbol + Name). Dein eigener
                 Name steht nie dort.
  DD/Heal-Modus: Nur das Rollensymbol dessen, der den Mob hält (Tank, DD, Heiler),
                 mittig über dem Mobnamen. Hältst du ihn selbst: nichts.
  Liste:         bleibt wie sie ist, zusätzlich das Symbol vor dem Mobnamen.

  Wer einen Mob hält, ermittelt Detection.lua (ns.aggroHolder), eine Quelle für
  Liste und Nameplates. Symbolsatz und Größen stehen in Config.lua.
]]

local _, ns = ...
local C = ns.Config
local Y = C.SYMBOL_LAYOUT

local cache = {}        -- Mob-Token -> { at = Zeitpunkt, holder = Gruppen-Token oder nil }
local lastHolder = {}   -- Mob-Token -> letzter Halter (Debug nur bei Wechsel)

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

-- Symbol für einen Mob (Schlüssel in C.SYMBOLS) und sein Halter (Gruppen-Token).
-- nil, wenn die Anzeige aus ist, niemand aus der Gruppe ihn hält oder du selbst ihn hältst.
function ns.symbolFor(mob)
  if not active() or not mob then return nil end
  local holder = holderOf(mob)
  if not holder or holder == 'player' then return nil end
  return roleKey(holder), holder
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

-- Name und Klassenfarbe des Halters (Gruppen-Token sind nicht geheim, trotzdem absichern)
local function holderNameAndColor(holder)
  local okN, name = pcall(UnitName, holder)
  name = okN and ns.plain(name) or nil
  local color = Y.NAME_FALLBACK_COLOR
  local okC, _, classFile = pcall(UnitClass, holder)
  classFile = okC and ns.plain(classFile) or nil
  local cc = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
  if cc then color = { cc.r, cc.g, cc.b } end
  return name, color
end

-- Zeile über dem Mobnamen ----------------------------------------------------------------

-- Ein kleiner Frame pro Nameplate: Symbol links, Name rechts daneben. Nimmt keine
-- Maus an (Klick geht an Blizzard).
local function lineFrame(nameplate)
  local f = nameplate.twfAggroLine
  if f then return f end
  f = CreateFrame('Frame', nil, nameplate)
  f:SetFrameLevel(nameplate:GetFrameLevel() + Y.LEVEL)
  f:SetSize(Y.ICON_SIZE, Y.ICON_SIZE)
  f.icon = f:CreateTexture(nil, 'OVERLAY')
  f.icon:SetSize(Y.ICON_SIZE, Y.ICON_SIZE)
  f.text = f:CreateFontString(nil, 'OVERLAY', Y.LINE_FONT)
  nameplate.twfAggroLine = f
  return f
end

local function hideLine(nameplate)
  if nameplate.twfAggroLine then nameplate.twfAggroLine:Hide() end
end

-- showName = true: Symbol + Name (Tank-Modus); false: nur Symbol (DD/Heal-Modus).
-- Die Zeile wird als Ganzes mittig über dem Mobnamen ausgerichtet.
local function showLine(nameplate, key, holder, showName)
  local f = lineFrame(nameplate)
  if not ns.setSymbolTexture(f.icon, key) then f:Hide() return end

  -- Ausrichten ohne zu messen: Größen von Elementen an Nameplates können geheim sein
  -- (GetStringWidth lieferte in der Instanz einen geheimen Wert → Rechenfehler).
  -- Deshalb sitzt der Name mittig, um ein halbes Symbol nach rechts versetzt, und das
  -- Symbol hängt links am Namen. So steht die Zeile als Ganzes mittig.
  local name, color
  if showName then name, color = holderNameAndColor(holder) end
  f.icon:ClearAllPoints()
  if name then
    f.text:SetText(name)
    f.text:SetTextColor(unpack(color))
    f.text:ClearAllPoints()
    f.text:SetPoint('CENTER', f, 'CENTER', (Y.ICON_SIZE + Y.ICON_GAP) / 2, 0)
    f.text:Show()
    f.icon:SetPoint('RIGHT', f.text, 'LEFT', -Y.ICON_GAP, 0)
  else
    f.text:Hide()
    f.icon:SetPoint('CENTER', f, 'CENTER')
  end

  -- Über dem Mobnamen der TWF-Nameplate. Ohne TWF-Nameplate über Blizzards Mobnamen,
  -- sonst über Blizzards Lebensleiste (die Nameplate selbst sitzt leicht versetzt).
  local plate = nameplate.twfPlate
  local uf = nameplate.UnitFrame
  local anchor = (plate and plate:IsShown() and plate.name)
    or (uf and (uf.name or uf.healthBar or uf.HealthBar)) or nameplate
  f:ClearAllPoints()
  f:SetPoint('BOTTOM', anchor, 'TOP', 0, Y.LINE_Y)
  f:Show()
end

local function unitOf(nameplate)
  return nameplate.namePlateUnitToken or (nameplate.UnitFrame and nameplate.UnitFrame.unit)
end

-- Ein Durchlauf über alle sichtbaren Nameplates
local function updateAll()
  local plates = C_NamePlate.GetNamePlates(false) or {}
  if not active() then
    for _, nameplate in ipairs(plates) do hideLine(nameplate) end
    return
  end
  local showName = ns.db.role == 'tank'
  for _, nameplate in ipairs(plates) do
    local unit = unitOf(nameplate)
    local key, holder
    -- Nur bei Mobs, zu denen du selbst Bedrohungsdaten hast. Beim blauen Balken (du bist
    -- nicht im Kampf mit ihm) wird nichts angezeigt (Nutzer-Entscheid 2026-10-13).
    if unit and ns.engaged(unit) and ns.unitColor(unit) then key, holder = ns.symbolFor(unit) end
    if key then
      showLine(nameplate, key, holder, showName)
    else
      hideLine(nameplate)
    end
  end
end

local function onSettingChanged(key)
  if key ~= 'symbolMarks' then return end
  ns.dbg('SYMBOLS', 'Aggro-Ziel anzeigen: ' .. (active() and 'an' or 'aus'))
  updateAll()
end

ns.RegisterModule('Symbols', {
  OnTick = updateAll,
  OnSettingChanged = onSettingChanged,
})
