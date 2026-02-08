CrittersBoard = CrittersBoard or {}
local CB = CrittersBoard

-- =========================================================
-- Helpers
-- =========================================================
local function SortDesc(a, b)
  return (a.amount or 0) > (b.amount or 0)
end

-- =========================================================
-- SOUND & ALERT ENGINE (v0.5)
-- =========================================================
function CB:PlayAlert(listKey, rec, isGlobal)
  if not CB.DB or not CB.DB.ui or not CB.DB.ui.alertsEnabled then return end

  local soundPath = "Interface\\AddOns\\CrittersBoard\\sounds\\record.ogg"
  local msg = ""
  local color = { r = 1, g = 1, b = 1 }

  if isGlobal then
    -- Gildenweite Platz #1 Sounds
    if listKey == "D" then
      soundPath = "Interface\\AddOns\\CrittersBoard\\sounds\\dmg.ogg"
      msg = string.format("NEUER #1 SCHADEN! %s - %s (%d)", rec.player or "?", rec.spell or "?", rec.amount or 0)
      color = { r = 1, g = 0.2, b = 0.2 }
    elseif listKey == "H" then
      soundPath = "Interface\\AddOns\\CrittersBoard\\sounds\\heal.ogg"
      msg = string.format("NEUER #1 HEAL! %s - %s (%d)", rec.player or "?", rec.spell or "?", rec.amount or 0)
      color = { r = 0.2, g = 1, b = 0.2 }
    elseif listKey == "O" then
      soundPath = "Interface\\AddOns\\CrittersBoard\\sounds\\overkill.ogg"
      msg = string.format("NEUER #1 OVERKILL! %s - %s (%d)", rec.player or "?", rec.spell or "?", rec.amount or 0)
      color = { r = 1, g = 0.6, b = 0.2 }
    elseif listKey == "S" then
      -- Deine Anforderung: first.ogg bleibt für Angriffs-Zauber Rekorde
      soundPath = "Interface\\AddOns\\CrittersBoard\\sounds\\first.ogg"
      msg = string.format("NEUER #1 ANGRIFF! %s - %s (%d)", rec.player or "?", rec.spell or "?", rec.amount or 0)
      color = { r = 0.6, g = 0.6, b = 1 }
    elseif listKey == "HS" then
      soundPath = "Interface\\AddOns\\CrittersBoard\\sounds\\heal2.ogg"
      msg = string.format("NEUER #1 HEILUNG! %s - %s (%d)", rec.player or "?", rec.spell or "?", rec.amount or 0)
      color = { r = 0.2, g = 0.8, b = 1 }
    end
  else
    -- Lokaler Rekord (Persönliche Verbesserung, kein Platz 1)
    soundPath = "Interface\\AddOns\\CrittersBoard\\sounds\\record.ogg"
    msg = string.format(CB.L["MSG_NEW_RECORD"] .. " %s: %d", rec.spell or "?", rec.amount or 0)
    color = { r = 0.5, g = 1, b = 0.5 }
  end

  CB:QueueAlert({
    soundPath = soundPath,
    msg = msg,
    color = color
  })
end

-- =========================================================
-- Init DB (mit Wipe-Logik für v0.5)
-- =========================================================
function CB:InitDB()
  CrittersBoardDB = CrittersBoardDB or {}
  CB.DB = CrittersBoardDB

  -- ALTE WIPELOGIK ENTFERNT (Das macht jetzt die Core.lua!)

  -- UI Defaults (Diese bleiben hier, das ist gut so)
  CB.DB.ui = CB.DB.ui or {}
  if CB.DB.ui.mode == nil then CB.DB.ui.mode = "D10" end
  if CB.DB.ui.scale == nil then CB.DB.ui.scale = 1.0 end
  if CB.DB.ui.locked == nil then CB.DB.ui.locked = false end
  if CB.DB.ui.isOpen == nil then CB.DB.ui.isOpen = false end
  if CB.DB.ui.alertsEnabled == nil then CB.DB.ui.alertsEnabled = true end
  if CB.DB.ui.shareAfterSync == nil then CB.DB.ui.shareAfterSync = true end
  if CB.DB.ui.disableSync == nil then CB.DB.ui.disableSync = false end

  -- Tabellen Initialisierung (Nur erstellen, falls sie fehlen)
  CB.DB.damage = CB.DB.damage or { records = {}, seen = {}, revision = 0 }
  CB.DB.heal = CB.DB.heal or { records = {}, seen = {}, revision = 0 }
  CB.DB.overkill = CB.DB.overkill or { records = {}, seen = {}, revision = 0 }
  CB.DB.spells = CB.DB.spells or { records = {}, bySpell = {}, revision = 0 }
  CB.DB.healSpells = CB.DB.healSpells or { records = {}, bySpell = {}, revision = 0 }
end

-- =========================================================
-- Core Save Functions
-- =========================================================

function CB:AddRecord(tbl, player, spell, amount, ts, isCrit, classFile, source, listKey, destName)
  if not tbl or not tbl.records then return false end
  
  local oldTop1Amount = (tbl.records[1] and tbl.records[1].amount) or 0

  local recordId = string.format("%s_%d_%d", player, amount, ts)
  tbl.seen = tbl.seen or {}
  if tbl.seen[recordId] then return false end
  tbl.seen[recordId] = true

  local rec = {
    player = player,
    spell = spell,
    amount = amount,
    ts = ts,
    isCrit = isCrit,
    classFile = classFile,
    destName = destName
  }

  table.insert(tbl.records, rec)
  table.sort(tbl.records, SortDesc)

  while #tbl.records > 100 do
    table.remove(tbl.records)
  end

  tbl.revision = (tbl.revision or 0) + 1

  -- SOUND LOGIK: Nur wenn der neue Wert den alten Platz 1 schlägt
  if amount > oldTop1Amount then
    CB:PlayAlert(listKey, rec, true)
  end
  -- Der "elseif source == local" Teil wurde entfernt!

  return true, rec
end

function CB:AddSpellBest(player, spell, amount, ts, isCrit, classFile, source, destName)
  if not CB.DB or not CB.DB.spells then return false end
  
  local key = tostring(spell)
  CB.DB.spells.bySpell = CB.DB.spells.bySpell or {}
  local oldBest = CB.DB.spells.bySpell[key]
  local oldAmount = oldBest and oldBest.amount or 0

  -- Wir prüfen: Ist der neue Schlag besser als der alte Rekord DIESES Zaubers?
  if amount > oldAmount then
    local rec = {
      player = player,
      spell = spell,
      amount = amount,
      ts = ts,
      isCrit = isCrit,
      classFile = classFile,
      destName = destName -- Ziel speichern für Tooltip
    }
    CB.DB.spells.bySpell[key] = rec
    
    -- Sync-Liste (die Top-Liste der Zauber) aktualisieren
    local found = false
    for i, r in ipairs(CB.DB.spells.records) do
        if r.spell == spell then
            CB.DB.spells.records[i] = rec
            found = true
            break
        end
    end
    if not found then table.insert(CB.DB.spells.records, rec) end
    
    -- Sortieren, damit wir wissen, wer Platz 1 ist
    table.sort(CB.DB.spells.records, SortDesc)
    CB.DB.spells.revision = CB.DB.spells.revision + 1

    -- =========================================================
    -- ALERT LOGIK für S (Angriffe)
    -- =========================================================
    -- 1. Prüfen, ob dieser Rekord jetzt Platz 1 der gesamten S-Liste ist
    CB:PlayAlert("S", rec, true)
    return true, rec
  end
  return false
end

function CB:AddHealSpellBest(player, spell, amount, ts, isCrit, classFile, source, destName)
  if not CB.DB or not CB.DB.healSpells then return false end
  
  local tbl = CB.DB.healSpells
  tbl.records = tbl.records or {}
  tbl.bySpell = tbl.bySpell or {}
  
  local key = tostring(spell)
  local oldBest = tbl.bySpell[key]
  local oldAmount = oldBest and oldBest.amount or 0

  if amount > oldAmount then
    local rec = {
      player = player,
      spell = spell,
      amount = amount,
      ts = ts,
      isCrit = isCrit,
      classFile = classFile,
	  destName = destName
    }
    tbl.bySpell[key] = rec
    
    -- Bestehenden Eintrag in der Anzeige-Liste suchen und ersetzen
    local found = false
    for i, r in ipairs(tbl.records) do
        if r.spell == spell then
            tbl.records[i] = rec
            found = true
            break
        end
    end
    
    if not found then 
        table.insert(tbl.records, rec) 
    end
    
    -- Sortieren nach Amount
    table.sort(tbl.records, function(a, b) return (a.amount or 0) > (b.amount or 0) end)
    
    -- Alarm auslösen (Sound/Text)
    local isNewTop1 = (tbl.records[1] and tbl.records[1].amount == amount)
    
    if isNewTop1 then
        CB:PlayAlert("HS", rec, true) -- Globaler Alarm für alle
    end
    
    return true, rec
  end
  return false
end