--[[
  PlateStates.lua — Aussehen der TWF-Nameplates pro Zustand (Anforderung V, 0.3).

  Gespeichert in db.plates[satz][zustand] = { color, alpha, blink, frame, show }.
  Sätze (C.PLATE_SETS): 'shared' gilt, solange "Farben für alle Modi gleich" an ist
  (db.plateShared); sonst der Satz der gespielten Rolle ('tank', 'dps', 'heal').
  Standardwerte stehen in C.PLATE_STATES ("Farben zurücksetzen" stellt sie wieder her).

  Einmaliger Umstieg von 0.2: Deckkraft "andere Gegner", Checkbox "Rot blinkender Rahmen"
  und "Balken auch außerhalb des Kampfs" werden in die Tabellen übernommen und dann gelöscht.
]]

local _, ns = ...
local C = ns.Config

local function copyColor(c) return { c[1], c[2], c[3] } end

local function defaultState(st)
  return {
    color = copyColor(st.color),
    alpha = st.alpha,
    blink = st.blink and true or false,
    frame = copyColor(st.frame),
    show = st.show and true or false,
  }
end

-- Fehlende Sätze, Zustände und Felder mit Standardwerten auffüllen
local function fill(db)
  db.plates = type(db.plates) == 'table' and db.plates or {}
  for _, set in ipairs(C.PLATE_SETS) do
    local tbl = type(db.plates[set]) == 'table' and db.plates[set] or {}
    db.plates[set] = tbl
    for _, st in ipairs(C.PLATE_STATES) do
      local def = defaultState(st)
      local cur = tbl[st.key]
      if type(cur) ~= 'table' then
        tbl[st.key] = def
      else
        for field, value in pairs(def) do
          if cur[field] == nil then cur[field] = value end
        end
      end
    end
  end
end

-- Werte aus 0.2 einmalig übernehmen (alle Sätze), danach die alten Schlüssel löschen
local function migrate(db)
  local moved = {}
  for _, set in ipairs(C.PLATE_SETS) do
    for _, st in ipairs(C.PLATE_STATES) do
      local s = db.plates[set][st.key]
      if type(db.alphaOther) == 'number' then s.alpha = db.alphaOther end
      if db.alarmFrame == false then s.blink = false end
      if st.key == 'grey' and db.barsOutOfCombat == true then s.show = true end
    end
  end
  if db.alphaOther ~= nil then moved[#moved + 1] = 'alphaOther=' .. tostring(db.alphaOther) end
  if db.alarmFrame ~= nil then moved[#moved + 1] = 'alarmFrame=' .. tostring(db.alarmFrame) end
  if db.barsOutOfCombat ~= nil then moved[#moved + 1] = 'barsOutOfCombat=' .. tostring(db.barsOutOfCombat) end
  db.alphaOther, db.alarmFrame, db.barsOutOfCombat = nil, nil, nil
  db.plateVersion = C.PLATE_VERSION
  if #moved > 0 then
    ns.dbg('PLATES', 'Werte aus 0.2 übernommen: ' .. table.concat(moved, ', '))
  end
end

-- Von Core.lua nach dem Laden der Einstellungen aufgerufen
function ns.ensurePlates(db)
  fill(db)
  if db.plateVersion ~= C.PLATE_VERSION then migrate(db) end
end

-- Satz, der gerade gilt
function ns.plateSet()
  local db = ns.db
  if db.plateShared then return 'shared' end
  return db.role
end

-- Einstellungen eines Zustands im gerade gültigen Satz
function ns.plateState(key)
  local set = ns.db.plates[ns.plateSet()] or ns.db.plates.shared
  return set[key]
end

-- Gibt es den Zustand in diesem Satz? ("Anderer Tank" und "Ziehst vom Tank" nur bei Tank)
function ns.stateUsed(set, st)
  return not (st.tankOnly and (set == 'dps' or set == 'heal'))
end

-- "Farben zurücksetzen": alle Sätze auf die Standardwerte (Checkbox "Farben gleich" bleibt)
function ns.resetPlates()
  ns.db.plates = nil
  fill(ns.db)
  ns.dbg('PLATES', 'Alle Farben auf Standard zurückgesetzt')
end
