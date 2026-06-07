CrittersBoard = CrittersBoard or {}
local CB = CrittersBoard

local function RefreshUI()
  if CB.UI and CB.UI.Refresh then
    CB.UI:Refresh()
  end
end

local function SendRecord(kind, rec)
  if not CB.SendEvent then return end
  CB:SendEvent(kind, rec)
end

-- EVT nur senden wenn Record in den angezeigten Top 20 liegt
-- S und HS haben kein fixes Limit → immer true (nicht über diese Funktion prüfen)
local function IsInDisplayTop(tbl, rec, limit)
  limit = limit or 20
  if #tbl.records < limit then return true end
  return rec.amount >= tbl.records[limit].amount
end

function CB:OnCombatLog()
  local info = {CombatLogGetCurrentEventInfo()} -- Event-Daten einmal sammeln
  local subevent = info[2]
  local sourceGUID = info[4]
  local sourceName = info[5]
  local destGUID = info[8]
  local destName = info[9]
  
  if not CB.DB then return end

  local ts = time()
  local playerGUID = UnitGUID("player")
  
  -- Standort abrufen
  local mapID, posX, posY = 0, 0, 0
  if CB.GetLocation then
    mapID, posX, posY = CB:GetLocation()
  end

  -- =========================================================
  -- 1. GILDEN-TOP: EIGENER ERHALTENER SCHADEN (DT)
  -- =========================================================
  -- Wir prüfen NUR: Bin ICH das Ziel des Schadens?
  if destGUID == playerGUID and (subevent == "SWING_DAMAGE" or subevent == "SPELL_DAMAGE" or subevent == "RANGE_DAMAGE") then
    local spellId, spellName, amount, critical
    
    if subevent == "SWING_DAMAGE" then
      -- Swing Damage Parameter (Amount ist Index 12)
      amount, _, _, _, _, _, critical = select(12, unpack(info))
      spellName = "Nahkampf"
      spellId = 6603
    else
      -- Spell/Range Damage Parameter (Amount ist Index 15)
      spellId, spellName, _, amount, _, _, _, _, _, critical = select(12, unpack(info))
    end

    -- Nur loggen, wenn Schaden > 0 und ein Verursacher (sourceName) bekannt ist
    local safeSourceName = sourceName or "Unbekannt"
    if amount and amount > 0 then
      local isCrit = critical and true or false
      local _, myClass = UnitClass("player") -- Deine eigene Klasse für das UI
      
      -- Rekord in die DT-Tabelle (Halle des Schmerzes) schreiben
      local added, rec = CB:AddRecord(CB.DB.damageTaken, destName or "Ich", spellName, amount, ts, isCrit, myClass or "UNKNOWN", "local", "DT", safeSourceName, spellId, mapID, posX, posY)

      if added and rec then
        if IsInDisplayTop(CB.DB.damageTaken, rec) then
          SendRecord("DT", rec)
        end
        RefreshUI()
      end
    end
  end

  -- =========================================================
  -- AB HIER: NUR EIGENE AKTIONEN (D, S, O, H, HS)
  -- =========================================================
  -- Dieser Filter sorgt dafür, dass die folgenden Listen nur DICH tracken
  if sourceGUID ~= playerGUID then return end
  local _, classFile = UnitClass("player")
  -- =========================
  -- SCHADEN (Nahkampf & Zauber)
  -- =========================
  if subevent == "SWING_DAMAGE" or subevent == "SPELL_DAMAGE" or subevent == "RANGE_DAMAGE" then
    local spellId, spellName, amount, overkill, critical
    
    if subevent == "SWING_DAMAGE" then
      amount, overkill, _, _, _, _, critical = select(12, unpack(info))
      spellName = "Nahkampf"
      spellId = 6603
    else
      spellId, spellName, _, amount, overkill, _, _, _, _, critical = select(12, unpack(info))
    end

    local isCrit = critical and true or false
    local ok = overkill or 0

    if amount and amount > 0 then
      -- 1. Hauptliste: Schaden (D)
      local added, rec = CB:AddRecord(CB.DB.damage, sourceName, spellName, amount, ts, isCrit, classFile, "local", "D", destName, spellId, mapID, posX,posY)
      if added and rec then
        if IsInDisplayTop(CB.DB.damage, rec) then
          SendRecord("D", rec)
        end
        RefreshUI()
      end

      -- 2. Best-of-Spells: Angriffe (S)
      
      local addedS, recS = CB:AddSpellBest(sourceName, spellName, amount, ts, isCrit, classFile, "local", destName, spellId, mapID, posX, posY)
      if addedS and recS then
        SendRecord("S", recS)
        RefreshUI()
      end
      
    end

    -- 3. Overkill (O)
    if ok and ok > 0 then
      local added, rec = CB:AddRecord(CB.DB.overkill, sourceName, spellName, ok, ts, isCrit, classFile, "local", "O", destName, spellId, mapID, posX,posY)
      if added and rec then
        if IsInDisplayTop(CB.DB.overkill, rec) then
          SendRecord("O", rec)
        end
        RefreshUI()
      end
    end

  -- =========================
  -- HEILUNG
  -- =========================

  elseif subevent == "SPELL_HEAL" then
    local spellId, spellName, _, amount, _, _, critical = select(12, unpack(info))
    local isCrit = critical and true or false

    if amount and amount > 0 then
      -- 1. Hauptliste: Heilung (H) - Top 10/100
      local added, rec = CB:AddRecord(CB.DB.heal, sourceName, spellName, amount, ts, isCrit, classFile, "local", "H", destName, spellId, mapID, posX,posY)
      if added and rec then
        if IsInDisplayTop(CB.DB.heal, rec) then
          SendRecord("H", rec)
        end
        RefreshUI()
      end

      -- 2. Best-of-Spells: Heilung (HS) 
      local addedHS, recHS = CB:AddHealSpellBest(sourceName, spellName, amount, ts, isCrit, classFile, "local", destName, spellId, mapID, posX,posY)
      if addedHS and recHS then
        SendRecord("HS", recHS)
		RefreshUI()
      end
    end
  end
end