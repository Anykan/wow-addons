--[[
  Debug.lua — Debug-Meldungen, Debug-Log und Rohdaten-Dump (nur für den Entwickler).

  Laufendes, ereignisbasiertes Debugging: standardmäßig aus, eine Checkbox im
  Menü, schreibt nur, wenn sich wirklich etwas ändert (kein Dauer-Spam).

  Zeilen landen zusätzlich mit Uhrzeit in ThreatWallForeverDB.log, begrenzt auf
  die letzten Config.MAX_LOG Einträge. Der Client kann keine Dateien schreiben;
  SavedVariables sind der einzige Weg auf die Platte, und das Spiel schreibt
  sie nur bei /reload, Logout oder Addon-Deaktivierung.
]]

local _, ns = ...
local C = ns.Config
local L = ns.L

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

-- Menüpunkt "Debug-Meldungen"
function ns.toggleDebug()
  local db = ns.db
  db.debug = not db.debug
  ns.say(db.debug and L.DEBUG_ON or L.DEBUG_OFF, db.debug and 'DEBUG_ON' or 'DEBUG_OFF')
  ns.applyLook()
  ns.updateMinimap()
  ns.refresh()
end

-- Rohdaten-Dump (/twf debug): eine Zeile pro gefundenem Gegner-Token plus die
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
      ns.say(unit .. ' hostile=' .. show(okH and hostile) .. ' combat=' .. show(okC and inCombat)
        .. ' engaged=' .. tostring(isEngaged) .. ' tanking=' .. show(tanking) .. ' status=' .. show(status)
        .. ' mark=' .. show(okM and idx) .. ' markOk=' .. tostring(markOk))
    end
  end
  if not any then ns.say(L.NO_NAMEPLATES, 'NO_NAMEPLATES') end
  local anyTracked = false
  for key, t in pairs(ns.tracked) do
    anyTracked = true
    ns.say('tracked: ' .. tostring(not ns.IsSecret(t.name) and t.name or key)
      .. ' unit=' .. tostring(t.unit) .. ' shownColor=' .. tostring(t.shownColor)
      .. ' markIndex=' .. tostring(t.markIndex) .. ' removeAt=' .. tostring(t.removeAt))
  end
  if not anyTracked then ns.say('tracked table is empty.') end
end
