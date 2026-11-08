--[[
  Detection.lua — Gegner finden und ihren Aggro-Status (Ampel) bestimmen.

  Einzige Datenquelle für alle Anzeigen: collect() pflegt die Tabelle
  ns.tracked, alle anderen Module (Liste usw.) lesen nur daraus.
]]

local _, ns = ...
local C = ns.Config
local S = C.THREAT_STATUS

-- guid (oder Unit-Token, falls die GUID nicht lesbar ist) -> { unit, name, markIndex, shownColor, removeAt }
ns.tracked = {}

-- Wahr, wenn die Einheit ein angreifbarer, lebender Gegner ist, der gerade gegen
-- dich, ein Gruppenmitglied oder deren Begleiter kämpft.
-- Das sind reine Ja/Nein-Prüfungen: Ein "geheimer" Wahrheitswert wird so
-- verwendet (Luas `if` braucht nur wahr/falsch, keinen Vergleich). Nur die
-- Bedrohungszahlen unten brauchen die Sonderbehandlung für geheime Werte.
function ns.engaged(unit)
  local ok, exists = pcall(UnitExists, unit)
  if not ok or not exists then return false end
  local okH, hostile = pcall(function()
    return UnitCanAttack('player', unit) and not UnitIsDead(unit)
  end)
  if not okH or not hostile then return false end

  local okC, inCombat = pcall(UnitAffectingCombat, unit)
  if okC and inCombat then return true end

  local mobTarget = unit .. 'target'
  local okE, hasTarget = pcall(UnitExists, mobTarget)
  if okE and hasTarget then
    local okF, friendly = pcall(function()
      return UnitPlayerControlled(mobTarget) and not UnitCanAttack('player', mobTarget)
    end)
    if okF and friendly then return true end
  end
  return false
end

-- Alle Einheiten, deren AKTUELLES ZIEL ein möglicher Gegner ist: du, dein
-- Begleiter und (in einer Gruppe) alle anderen und deren Begleiter. Das ist der
-- Hauptweg, Gegner zu finden – er braucht keine Nameplates. Nameplates sind nur
-- eine zusätzliche Quelle für Gegner, die gerade niemand anvisiert.
-- `target` steht bewusst an erster Stelle (siehe collect()).
function ns.candidateUnits()
  local list = { 'target', 'pettarget' }
  if IsInRaid() then
    local okN, n = pcall(GetNumGroupMembers)
    n = (okN and not ns.IsSecret(n)) and n or 0
    for i = 1, n do
      list[#list + 1] = 'raid' .. i .. 'target'
      list[#list + 1] = 'raidpet' .. i .. 'target'
    end
  elseif IsInGroup() then
    local okN, n = pcall(GetNumSubgroupMembers)
    n = (okN and not ns.IsSecret(n)) and n or 0
    for i = 1, n do
      list[#list + 1] = 'party' .. i .. 'target'
      list[#list + 1] = 'partypet' .. i .. 'target'
    end
  end
  for i = 1, C.MAX_NAMEPLATES do list[#list + 1] = 'nameplate' .. i end
  return list
end

-- Deine eigene Bedrohung auf einem Gegner, vorsichtig gelesen: Der Client kann
-- jeden dieser Werte im Kampf verstecken; ein versteckter Wert gilt als
-- unbekannt statt geraten.
function ns.myStatus(unit)
  local ok, tanking, status = pcall(UnitDetailedThreatSituation, 'player', unit)
  if not ok then return nil, nil end
  tanking = ns.plain(tanking)
  status = ns.plain(status)
  if tanking == nil and status == nil then
    -- Vor dem Aufgeben die einfachere API versuchen.
    local ok2, st2 = pcall(UnitThreatSituation, 'player', unit)
    if ok2 then status = ns.plain(st2) end
  end
  return tanking, status
end

-- Tank-Modus: das Problem ist, die Aggro zu verlieren. DD/Heal-Modus: das
-- Problem ist, zu viel davon zu ziehen. Beide lesen denselben Statuswert, nur
-- umgedreht. Beide Zwischenstufen (INSECURE, HIGH) sind in beiden Modi gelb
-- (Anforderung K, gilt für Liste und Nameplates).
function ns.classify(tanking, status)
  if ns.db.role == 'tank' then
    if status == S.SECURE then return 'green' end
    if status == S.INSECURE or status == S.HIGH then return 'yellow' end
    return 'red' -- 0 oder unlesbar: du hast kaum oder keine Kontrolle über ihn
  else
    if status == S.SECURE then return 'red' end
    if status == S.INSECURE or status == S.HIGH then return 'yellow' end
    if tanking then return 'red' end -- Status unlesbar, aber du tankst
    return 'green'
  end
end

-- Gehört der Mob einer anderen Gruppe (keine EP, keine Beute; im Original ausgegraut)?
-- Anforderung U. Über Nameplate-Token auch im Kampf lesbar (getestet 2026-10-16);
-- ein geheimer oder unlesbarer Wert gilt als "nicht fremd".
function ns.isForeign(unit)
  local ok, tapped = pcall(UnitIsTapDenied, unit)
  return ok and ns.plain(tapped) == true
end

-- Vorsprung vor Platz 2 (Anforderung Z): Blizzards Tooltip-Wert, vom Spiel fertig berechnet
-- (UnitThreatPercentageOfLead). Nur im Tank-Modus, nur wenn du den Mob hältst (Stufe lesbar)
-- und nicht allein bist (allein gibt es keinen Platz 2, der Wert wäre 0). Über das Ziel lesbar,
-- über Nameplates geheim: nur weiterreichen. nil = stattdessen die normalen Aggro-% zeigen.
function ns.leadValue(unit)
  if ns.db.role ~= 'tank' or not unit or not (IsInGroup() or IsInRaid()) then return nil end
  local okS, status = pcall(UnitThreatSituation, 'player', unit)
  status = okS and ns.plain(status) or nil
  if not status or status < S.INSECURE then return nil end
  local ok, lead = pcall(UnitThreatPercentageOfLead, 'player', unit)
  if not ok then return nil end
  if not ns.IsSecret(lead) and (lead == nil or lead <= 0) then return nil end
  return lead
end

-- Gruppenrolle einer Einheit: 'TANK', 'HEALER', 'DAMAGER' oder 'NONE' (nicht zugewiesen/unlesbar)
function ns.groupRole(unit)
  local ok, role = pcall(UnitGroupRolesAssigned, unit)
  role = ok and ns.plain(role)
  if role == 'TANK' or role == 'HEALER' or role == 'DAMAGER' then return role end
  return 'NONE'
end

-- Anderer Tank hält den Mob (Anforderung T, nur Tank-Modus): Rot wird braun (kein
-- Problem, ihr tankt zu zweit). Gelb bleibt gelb, zweiter Rückgabewert true = du ziehst
-- ihm gleich die Aggro ab (gelb blinkender Rahmen statt rot). Hält ihn ein DD/Heiler
-- oder hat der andere Tank keine Rolle, bleibt alles wie es ist.
function ns.withOtherTank(unit, color)
  if ns.db.role ~= 'tank' or (color ~= 'red' and color ~= 'yellow') then return color, false end
  local holder = ns.aggroHolder(unit)
  if not holder or holder == 'player' or ns.groupRole(holder) ~= 'TANK' then return color, false end
  if color == 'red' then return 'brown', false end
  return color, true
end

-- Ampelfarbe für eine Einheit (gemeinsam für Liste und Nameplates).
-- nil = keine Bedrohungsdaten (z. B. Gegner kämpft nicht mit dir/deiner Gruppe).
-- Zweiter Rückgabewert: siehe ns.withOtherTank.
function ns.unitColor(unit)
  local tanking, status = ns.myStatus(unit)
  if tanking == nil and status == nil then return nil end
  return ns.withOtherTank(unit, ns.classify(tanking, status))
end

-- Alle Gruppen-Token, du selbst zuerst (party1..4 bzw. raid1..40)
function ns.groupUnits()
  local list = { 'player' }
  if IsInRaid() then
    local okN, n = pcall(GetNumGroupMembers)
    n = (okN and not ns.IsSecret(n)) and n or 0
    for i = 1, n do list[#list + 1] = 'raid' .. i end
  elseif IsInGroup() then
    local okN, n = pcall(GetNumSubgroupMembers)
    n = (okN and not ns.IsSecret(n)) and n or 0
    for i = 1, n do list[#list + 1] = 'party' .. i end
  end
  return list
end

-- Wer hält diesen Mob? Gibt den Gruppen-Token zurück ('player', 'party2', …) oder nil.
-- Im Schlachtzug steht 'player' vorn, deshalb wirst du nicht als raidN zurückgegeben.
--
-- Zwei Wege, weil der Client je nach Mob-Token unterschiedlich viel verrät (getestet 2026-10-13):
--  1. UnitDetailedThreatSituation → "tankt ja/nein". Über `target` lesbar (T6), über
--     `nameplateN` geheim.
--  2. UnitThreatSituation → Stufe 0–3, auch über `nameplateN` lesbar. Ab Stufe INSECURE (2)
--     tankt die Einheit den Mob; SECURE (3) hat Vorrang.
-- (Ein dritter Weg über das Ziel des Mobs war kurz eingebaut und ist wieder entfernt:
--  in Instanzen ist das Ziel komplett geheim, siehe TESTS-MACHBARKEIT.md, 2026-10-13.)
function ns.aggroHolder(mob)
  local insecure
  for _, u in ipairs(ns.groupUnits()) do
    local ok, tanking = pcall(UnitDetailedThreatSituation, u, mob)
    if ok and ns.plain(tanking) then return u end
    local ok2, st = pcall(UnitThreatSituation, u, mob)
    st = ok2 and ns.plain(st) or nil
    if st == S.SECURE then return u end
    if st == S.INSECURE and not insecure then insecure = u end
  end
  return insecure
end

-- Ist Farbe a schlimmer als Farbe b?
function ns.worse(a, b)
  return (C.RANK[a] or 0) > (C.RANK[b] or 0)
end

-- Gewählten Warnton spielen (auch für den Test-Knopf in den Einstellungen: force = true)
function ns.playAlert(force)
  local db = ns.db
  if not (force or db.sound) then return end
  pcall(PlaySound, db.soundId or C.ALERT_SOUNDS[1].id, db.soundChannel or C.SOUND_CHANNELS[1])
end

-- Bildschirmrand (I10): vier Farbverläufe an den Kanten (außen Farbe, nach innen durchsichtig),
-- blitzt einmal auf. Wird beim ersten Mal gebaut. force = true: auch wenn ausgeschaltet (Test).
local EF = C.EDGE_FLASH
local edge
local function buildEdge()
  edge = CreateFrame('Frame', nil, UIParent)
  edge:SetAllPoints(UIParent)
  edge:SetFrameStrata(EF.STRATA)
  edge:Hide()
  edge.parts = {}
  -- p1/p2 = Kante, outerFirst = erste Verlaufsfarbe (links bzw. unten) liegt außen
  for _, e in ipairs({
    { 'TOPLEFT', 'BOTTOMLEFT', 'HORIZONTAL', true, true },
    { 'TOPRIGHT', 'BOTTOMRIGHT', 'HORIZONTAL', false, true },
    { 'TOPLEFT', 'TOPRIGHT', 'VERTICAL', false, false },
    { 'BOTTOMLEFT', 'BOTTOMRIGHT', 'VERTICAL', true, false },
  }) do
    local t = edge:CreateTexture(nil, 'BACKGROUND')
    t:SetPoint(e[1])
    t:SetPoint(e[2])
    if e[5] then t:SetWidth(EF.WIDTH) else t:SetHeight(EF.WIDTH) end
    t:SetTexture(C.TEXTURE.FLAT)
    t.dir, t.outerFirst = e[3], e[4]
    edge.parts[#edge.parts + 1] = t
  end
  edge:SetScript('OnUpdate', function(self)
    local t = GetTime() - self.start
    if t >= EF.DURATION then self:Hide() return end
    self:SetAlpha(math.sin(math.pi * t / EF.DURATION) * self.maxAlpha)
  end)
end

function ns.flashEdge(force)
  local db = ns.db
  if not (force or db.edgeFlash) then return end
  if not edge then buildEdge() end
  local c = db.edgeColor or C.DEFAULTS.edgeColor
  local ok = pcall(function()
    local solid, clear = CreateColor(c[1], c[2], c[3], 1), CreateColor(c[1], c[2], c[3], 0)
    for _, t in ipairs(edge.parts) do
      if t.outerFirst then t:SetGradient(t.dir, solid, clear) else t:SetGradient(t.dir, clear, solid) end
    end
  end)
  if not ok then return end
  edge.maxAlpha = db.edgeAlpha or C.DEFAULTS.edgeAlpha
  edge.start = GetTime()
  edge:SetAlpha(0)
  edge:Show()
end

-- Vorschau beim Ändern in den Einstellungen: läuft der Rand schon, bleibt er voll sichtbar
-- (Start auf die Mitte gesetzt) und blendet erst nach der letzten Änderung aus – so kann man
-- Regler und Farbwähler live verfolgen
function ns.previewEdge()
  if edge and edge:IsShown() then
    edge.maxAlpha = ns.db.edgeAlpha or C.DEFAULTS.edgeAlpha
    local c = ns.db.edgeColor or C.DEFAULTS.edgeColor
    pcall(function()
      local solid, clear = CreateColor(c[1], c[2], c[3], 1), CreateColor(c[1], c[2], c[3], 0)
      for _, t in ipairs(edge.parts) do
        if t.outerFirst then t:SetGradient(t.dir, solid, clear) else t:SetGradient(t.dir, clear, solid) end
      end
    end)
    edge.start = GetTime() - EF.DURATION / 2
    return
  end
  ns.flashEdge(true)
end

-- Gemeinsamer Test-Knopf in den Einstellungen: zeigt die Warnung so, wie sie im Kampf käme –
-- nur was eingeschaltet ist (Nutzer 2026-11-08: Rand aus = beim Testen kein Rand)
function ns.testAlert()
  ns.playAlert()
  ns.flashEdge()
end

-- Durchsucht alle Kandidaten und aktualisiert ns.tracked. Gibt nichts zurück:
-- refresh() zeichnet direkt aus ns.tracked.
-- Bug B2: In Instanzen ist die GUID geheim, dann war der Token der Schlüssel und derselbe
-- Mob stand doppelt in der Liste (z. B. als `target` und als `nameplate3`). UnitIsUnit ist
-- auch dort lesbar (getestet 2026-10-17): Damit bekommt jeder Mob einen stabilen Schlüssel,
-- den Token seiner Nameplate, und weitere Token desselben Mobs werden übersprungen.
local function sameUnit(a, b)
  local ok, same = pcall(UnitIsUnit, a, b)
  return ok and ns.plain(same) == true
end

local function plateTokens()
  local list = {}
  for _, plate in ipairs(C_NamePlate.GetNamePlates(false) or {}) do
    local tok = plate.namePlateUnitToken or (plate.UnitFrame and plate.UnitFrame.unit)
    if tok then list[#list + 1] = tok end
  end
  return list
end

-- Schlüssel ohne lesbare GUID: Nameplate-Token desselben Mobs, sonst der Token selbst
local function tokenKey(unit, plates)
  if unit:find('^nameplate') then return unit end
  for _, tok in ipairs(plates) do
    if sameUnit(tok, unit) then return tok end
  end
  return unit
end

local mergeReported = false

function ns.collect()
  local db = ns.db
  local tracked = ns.tracked
  local IsSecret = ns.IsSecret
  local now = GetTime()
  local seen = {}
  local seenUnits = {}   -- Token der schon aufgenommenen Gegner ohne lesbare GUID (B2)
  local plates           -- Nameplate-Token, erst bei Bedarf ermittelt

  for _, unit in ipairs(ns.candidateUnits()) do
    -- Fremde Mobs (andere Gruppe) sind kein Problem für dich: nicht in die Liste (Anforderung U)
    if ns.engaged(unit) and not ns.isForeign(unit) then
      local okG, guid = pcall(UnitGUID, unit)
      if okG and IsSecret(guid) then guid = nil end
      -- Die GUID ist der normale Schlüssel. Sie kann aber selbst nil oder
      -- "geheim" sein (live bestätigt in einem Gruppen-Dungeon), dann dient der
      -- Nameplate-Token desselben Mobs als Schlüssel (tokenKey, Bug B2). Wird eine
      -- Nameplate mitten im Kampf einem anderen Gegner zugewiesen, kann eine Zeile
      -- kurz doppelt erscheinen; sie läuft über die Gnadenfrist unten normal aus.
      local key = okG and guid or nil
      if not key then
        plates = plates or plateTokens()
        key = tokenKey(unit, plates)
        -- Mob ohne Nameplate, aber schon über einen anderen Token aufgenommen?
        if not seen[key] then
          for _, other in ipairs(seenUnits) do
            if sameUnit(other, unit) then key = other break end
          end
        end
        if seen[key] and not mergeReported then
          mergeReported = true
          ns.dbg('MERGED', 'Doppelte Zeile zusammengeführt: ' .. unit .. ' = ' .. key)
        end
      end
      -- Mehrere Token (dein Ziel, eine Nameplate, das Ziel eines Mitspielers …)
      -- können auf denselben Gegner zeigen. Nur der erste in diesem Durchlauf
      -- zählt, damit ein späterer, unvollständigerer Wert keinen guten
      -- überschreibt – deshalb steht `target` in candidateUnits() vorn.
      if not seen[key] then
        local tanking, status = ns.myStatus(unit)
        if tanking ~= nil or status ~= nil then
          local color = ns.withOtherTank(unit, ns.classify(tanking, status))
          local t = tracked[key]
          local isNew = not t
          if not t then
            t = {}
            tracked[key] = t
          end
          -- Seit B2 wechselt der Token bei jedem Zielwechsel (target <-> nameplateN):
          -- nur ins Log, nicht in den Chat
          if db and db.debug and t.unit and t.unit ~= unit then
            ns.logLine('Einheiten-Token gewechselt ' .. tostring(t.unit) .. ' -> ' .. tostring(unit)
              .. ' bei ' .. tostring(not IsSecret(t.name) and t.name or key))
          end
          t.unit = unit
          local okN, name = pcall(UnitName, unit)
          -- Ein geheimer Name kann trotzdem direkt an SetText gehen; er kann
          -- nur nicht verglichen oder mit anderen Texten verbunden werden.
          t.name = okN and name or nil
          local okM, idx = pcall(GetRaidTargetIndex, unit)
          t.markIndex = okM and idx or nil
          -- Leben für den Listenbalken (geheim, nur weitergereicht); gemerkt, damit die Zeile
          -- es behält, solange der Gegner keine Nameplate hat (Token ist dann ungültig)
          local okH, hp, hpMax = pcall(function() return UnitHealth(unit), UnitHealthMax(unit) end)
          if okH then t.hp, t.hpMax = hp, hpMax end
          seen[key] = true
          t.fresh = true
          if not guid then seenUnits[#seenUnits + 1] = unit end

          if isNew then
            ns.dbg('SPOTTED', (not IsSecret(t.name) and t.name or unit) .. ' entdeckt, tankt='
              .. tostring(tanking) .. ' status=' .. tostring(status) .. ' -> ' .. color)
          end

          if not db.showAll and color == 'green' then
            -- Normal: ein gelöstes Problem bekommt eine kurze Gnadenfrist und
            -- fällt dann ganz aus der Liste.
            if t.shownColor then t.removeAt = t.removeAt or (now + C.GRACE) end
          else
            -- "Alle Kämpfe zeigen": jeder Gegner im Kampf (auch grün) bleibt,
            -- bis er aus candidateUnits() verschwindet. Nur eine Verschlechterung
            -- zu Rot/Gelb löst den Warnton aus – grün werden ist eine gute Nachricht,
            -- braun (anderer Tank hält ihn, Anforderung T) ist kein Problem.
            if color ~= 'green' and color ~= 'brown' and ns.worse(color, t.shownColor) then
              if not isNew then
                ns.dbg('WORSENED', (not IsSecret(t.name) and t.name or unit) .. ' verschlechtert '
                  .. tostring(t.shownColor) .. ' -> ' .. color)
              end
              -- "Nur in einer Gruppe": solo keine Warnung (der Test-Knopf zeigt sie trotzdem)
              if not ns.db.alertGroupOnly or IsInGroup() or IsInRaid() then
                ns.playAlert()
                ns.flashEdge()
              end
            end
            t.shownColor = color
            t.removeAt = nil
          end
        end
      end
    end
  end

  for key, t in pairs(tracked) do
    if not seen[key] then
      t.fresh = false       -- Token zeigt evtl. auf einen anderen Gegner: Werte nicht auffrischen
      if t.shownColor then
        t.removeAt = t.removeAt or (now + C.GRACE)
      else
        tracked[key] = nil
      end
    end
  end
  for key, t in pairs(tracked) do
    if t.removeAt and now >= t.removeAt then
      -- Bewusst leiser als SPOTTED/WORSENED: Das Entfernen einer Zeile ist
      -- Routine und passiert oft (z. B. beim Zielwechsel), deshalb nur ins Log,
      -- nicht in den Chat.
      if db and db.debug then
        ns.logLine('[' .. C.CODES.CLEARED .. '] ' .. (not IsSecret(t.name) and t.name or key) .. ' entfernt, war ' .. tostring(t.shownColor))
      end
      tracked[key] = nil
    end
  end
end

-- Klassenfähigkeiten (I24): Paladin-Tank, Zorn der Gerechtigkeit ------------------------------
-- Im Kampf sind die eigenen Auren für Addons gesperrt (getestet 2026-11-08). Deshalb: außerhalb
-- des Kampfs lesen und die Ablaufzeit merken; im Kampf nach der Uhr weiterzählen.
-- Meldungen in der Bildschirmmitte bei 20, 10, 5, 4, 3, 2, 1 Min. Rest (je einmal), bei 0 "fehlt".
-- Neu gebufft (Ablaufzeit springt) → alles zurücksetzen. Nur Paladin + TWF-Rolle Tank.
local CA = C.CLASS_ABILITIES
local L = ns.L
local rf = { exp = nil, done = {}, missingShown = false }
local rfNext = 0

-- Meldung in der Bildschirmmitte; sound = Ton-ID dazu (über den Kanal des Warntons)
local function rfShow(text, sound)
  pcall(RaidNotice_AddMessage, RaidWarningFrame, text, CA.COLOR)
  ns.dbg('SETTING', 'Klassenfähigkeit: ' .. text)
  if sound then pcall(PlaySound, sound, ns.db.soundChannel or C.SOUND_CHANNELS[1]) end
end

local function rfName()
  local ok, name = pcall(function()
    if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(CA.RF_IDS[1]) end
    return (GetSpellInfo(CA.RF_IDS[1]))
  end)
  return ok and name or L.RF_FALLBACK
end

-- Außerhalb des Kampfs: Ablaufzeit lesen. Rückgabe: Zeitpunkt, false (fehlt) oder nil (unlesbar)
local function rfRead()
  for _, id in ipairs(CA.RF_IDS) do
    local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, id)
    if not ok then return nil end
    if aura then
      local okE, exp = pcall(function() return aura.expirationTime + 0 end)
      if not okE then return nil end
      return exp
    end
  end
  return false
end

-- Kennt der Charakter Zorn der Gerechtigkeit? (Nutzer 2026-11-08: auf Stufe 1 hat man ihn
-- noch nicht; auf Forever ab Stufe 10 beim Lehrer.) Prüft das Zauberbuch statt der Stufe –
-- so zählt auch ein Paladin über 10, der ihn noch nicht gelernt hat.
local function rfKnown()
  for _, id in ipairs(CA.RF_IDS) do
    local ok, known = pcall(function()
      if IsPlayerSpell then return IsPlayerSpell(id) end
      if C_SpellBook and C_SpellBook.IsSpellKnown then return C_SpellBook.IsSpellKnown(id) end
      return IsSpellKnown(id)
    end)
    if ok and known == true then return true end
  end
  return false
end

local function rfActive()
  local _, class = UnitClass('player')
  return ns.db.paladinRF == 'on' and ns.db.role == 'tank' and class == 'PALADIN' and rfKnown()
end

local function rfCheck()
  if not rfActive() then
    rf.exp, rf.done, rf.missingShown = nil, {}, false
    return
  end
  local now = GetTime()
  local inCombat = InCombatLockdown() or UnitAffectingCombat('player')
  if not inCombat then
    local exp = rfRead()
    if exp == nil then return end                 -- unlesbar: nichts tun
    if exp == false then
      rf.exp = nil
      if not rf.missingShown then
        rf.missingShown = true
        rfShow(string.format(L.RF_MISSING, rfName()), CA.RF_SOUND)
      end
      return
    end
    if not rf.exp or math.abs(exp - rf.exp) > CA.REBUFF_TOLERANCE then
      -- (neu) gebufft: Stufen über dem aktuellen Rest gelten als erledigt, damit nach dem Buffen
      -- oder einem Ladebildschirm kein Meldungs-Gewitter kommt
      rf.done, rf.missingShown = {}, false
      local rest = exp - now
      for _, m in ipairs(CA.MARKS) do
        if m * 60 < rest then break end
        rf.done[m] = true
      end
      -- schon unter 5 Min.: einmal sofort melden (Nutzer: beim Verlassen des Kampfs prüfen)
      if rest <= 5 * 60 then
        rfShow(string.format(L.RF_REMAINING, rfName(), math.ceil(rest / 60)), CA.RF_SOUND)
      end
      rf.exp = exp
    end
  end
  if not rf.exp then return end
  local rest = rf.exp - now
  if rest <= 0 then
    if not rf.missingShown then
      rf.missingShown = true
      rfShow(string.format(L.RF_MISSING, rfName()), CA.RF_SOUND)
    end
    return
  end
  for _, m in ipairs(CA.MARKS) do
    if not rf.done[m] and rest <= m * 60 then
      -- alle größeren Stufen mit erledigen, nur die aktuelle melden
      for _, m2 in ipairs(CA.MARKS) do if m2 >= m then rf.done[m2] = true end end
      rfShow(string.format(L.RF_REMAINING, rfName(), m), CA.RF_SOUND)
      break
    end
  end
end

local rfEvents = CreateFrame('Frame')
rfEvents:RegisterEvent('PLAYER_REGEN_ENABLED')
rfEvents:SetScript('OnEvent', function()
  -- Kampf vorbei: fehlt Zorn noch, erneut melden
  rf.missingShown = false
  rfNext = 0
end)

ns.RegisterModule('Klassenfaehigkeiten', {
  OnTick = function()
    local now = GetTime()
    if now < rfNext then return end
    rfNext = now + CA.INTERVAL
    rfCheck()
  end,
  OnSettingChanged = function(key)
    if key == 'paladinRF' or key == 'role' then rf.exp, rf.done, rf.missingShown = nil, {}, false end
  end,
})
