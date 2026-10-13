--[[
  Debug.lua — Debug-Meldungen, Debug-Log und Rohdaten-Dump (nur für den Entwickler).

  Laufendes, ereignisbasiertes Debugging: standardmäßig aus, Schalter per
  /twf debug 1|0, schreibt nur, wenn sich wirklich etwas ändert (kein Dauer-Spam).

  Zeilen landen zusätzlich mit Uhrzeit in ThreatWallForeverDB.log, begrenzt auf
  die letzten Config.MAX_LOG Einträge. Der Client kann keine Dateien schreiben;
  SavedVariables sind der einzige Weg auf die Platte, und das Spiel schreibt
  sie nur bei /reload, Logout oder Addon-Deaktivierung.
]]

local _, ns = ...
local C = ns.Config

-- Eine Zeile ins Log schreiben (älteste fliegen raus, wenn das Log voll ist)
function ns.logLine(line)
  local db = ns.db
  db.log = db.log or {}
  table.insert(db.log, { time = date('%H:%M:%S'), msg = line })
  while #db.log > C.MAX_LOG do
    table.remove(db.log, 1)
  end
end

-- Debug-Meldung in den Chat und ins Log (nur wenn Debug an ist)
function ns.dbg(codeKey, msg)
  if not (ns.db and ns.db.debug) then return end
  local line = '[' .. C.CODES[codeKey] .. '] ' .. msg
  ns.say('|cff888888[debug]|r ' .. line)
  ns.logLine(line)
end

-- Debug ein-/ausschalten (/twf debug 1|0). Ohne gültige Zahl: kurze Hilfe + Status.
-- Kein /reload nötig: db.debug wird bei jeder Meldung live abgefragt.
function ns.setDebugFromCommand(arg)
  local db = ns.db
  if arg == '1' or arg == '0' then
    db.debug = (arg == '1')
    ns.say('[' .. C.CODES.DEBUG_SET .. '] Debug-Meldungen ' .. (db.debug and 'AN' or 'AUS') .. '.')
  else
    ns.say('Nutze /twf debug 1 (an) oder /twf debug 0 (aus). Aktuell: ' .. (db.debug and 'AN' or 'AUS')
      .. '. Momentaufnahme: /twf dump')
  end
end

-- Rohdaten-Dump (/twf dump): eine Zeile pro gefundenem Gegner-Token plus die
-- interne Liste der verfolgten Gegner.
function ns.debugDump()
  local any = false
  local shown = {}
  for _, unit in ipairs(ns.candidateUnits()) do
    if UnitExists(unit) and not shown[unit] then
      shown[unit] = true
      any = true
      local okH, hostile = pcall(function() return UnitCanAttack('player', unit) and not UnitIsDead(unit) end)
      local okC, inCombat = pcall(UnitAffectingCombat, unit)
      local isEngaged = ns.engaged(unit)
      local tanking, status = ns.myStatus(unit)
      local okM, idx = pcall(GetRaidTargetIndex, unit)
      local markOk = idx ~= nil and pcall(SetRaidTargetIconTexture, UIParent:CreateTexture(), idx)
      local function show(v) return v == nil and 'nil' or tostring(v) end
      ns.say(unit .. ' feindlich=' .. show(okH and hostile) .. ' kampf=' .. show(okC and inCombat)
        .. ' erfasst=' .. tostring(isEngaged) .. ' tankt=' .. show(tanking) .. ' status=' .. show(status)
        .. ' symbol=' .. show(okM and idx) .. ' symbolOk=' .. tostring(markOk))
    end
  end
  if not any then ns.say('Keine Gegner-Einheit gefunden. Gegner anvisieren oder in Nameplate-Reichweite gehen.', 'NO_NAMEPLATES') end
  local anyTracked = false
  for key, t in pairs(ns.tracked) do
    anyTracked = true
    ns.say('verfolgt: ' .. tostring(not ns.IsSecret(t.name) and t.name or key)
      .. ' einheit=' .. tostring(t.unit) .. ' farbe=' .. tostring(t.shownColor)
      .. ' symbolNr=' .. tostring(t.markIndex) .. ' entfernenUm=' .. tostring(t.removeAt))
  end
  if not anyTracked then ns.say('Die Liste der verfolgten Gegner ist leer.') end
end
