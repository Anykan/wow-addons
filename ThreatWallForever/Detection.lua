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

local function playAlert()
  if ns.db.sound then pcall(PlaySound, C.ALERT_SOUND, C.ALERT_CHANNEL) end
end

-- Durchsucht alle Kandidaten und aktualisiert ns.tracked. Gibt nichts zurück:
-- refresh() zeichnet direkt aus ns.tracked.
function ns.collect()
  local db = ns.db
  local tracked = ns.tracked
  local IsSecret = ns.IsSecret
  local now = GetTime()
  local seen = {}

  for _, unit in ipairs(ns.candidateUnits()) do
    -- Fremde Mobs (andere Gruppe) sind kein Problem für dich: nicht in die Liste (Anforderung U)
    if ns.engaged(unit) and not ns.isForeign(unit) then
      local okG, guid = pcall(UnitGUID, unit)
      if okG and IsSecret(guid) then guid = nil end
      -- Die GUID ist der normale Schlüssel. Sie kann aber selbst nil oder
      -- "geheim" sein (live bestätigt in einem Gruppen-Dungeon), dann dient der
      -- Unit-Token als Schlüssel. Wird eine Nameplate mitten im Kampf einem
      -- anderen Gegner zugewiesen, kann eine Zeile kurz doppelt erscheinen; sie
      -- läuft über die Gnadenfrist unten normal aus. Besser als den Gegner gar
      -- nicht zu verfolgen.
      local key = (okG and guid) or unit
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
          if db and db.debug and t.unit and t.unit ~= unit then
            ns.say('|cff888888[debug]|r Einheiten-Token gewechselt ' .. tostring(t.unit) .. ' -> ' .. tostring(unit)
              .. ' bei ' .. tostring(not IsSecret(t.name) and t.name or key))
          end
          t.unit = unit
          local okN, name = pcall(UnitName, unit)
          -- Ein geheimer Name kann trotzdem direkt an SetText gehen; er kann
          -- nur nicht verglichen oder mit anderen Texten verbunden werden.
          t.name = okN and name or nil
          local okM, idx = pcall(GetRaidTargetIndex, unit)
          t.markIndex = okM and idx or nil
          seen[key] = true

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
            -- zu Rot/Gelb löst den Warnton aus – grün werden ist eine gute Nachricht.
            if color ~= 'green' and ns.worse(color, t.shownColor) then
              if not isNew then
                ns.dbg('WORSENED', (not IsSecret(t.name) and t.name or unit) .. ' verschlechtert '
                  .. tostring(t.shownColor) .. ' -> ' .. color)
              end
              playAlert()
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
