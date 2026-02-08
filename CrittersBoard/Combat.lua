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

function CB:OnCombatLog()
  local _, subevent, _, sourceGUID, sourceName, _, _, destGUID, destName = CombatLogGetCurrentEventInfo()
  
  -- Nur eigene Aktionen tracken
  if sourceGUID ~= UnitGUID("player") then return end
  if not CB.DB then return end

  local ts = time()
  local _, classFile = UnitClass("player")
  
  -- Standort abrufen
  local mapID, posX, posY = 0, 0, 0
  if CB.GetLocation then
    mapID, posX, posY = CB:GetLocation()
  end

  -- =========================
  -- SCHADEN (Nahkampf & Zauber)
  -- =========================
  if subevent == "SWING_DAMAGE" or subevent == "SPELL_DAMAGE" or subevent == "RANGE_DAMAGE" then
    local spellId, spellName, amount, overkill, critical
    
    if subevent == "SWING_DAMAGE" then
      amount, overkill, _, _, _, _, critical = select(12, CombatLogGetCurrentEventInfo())
      spellName = "Nahkampf"
      spellId = 6603
    else
      spellId, spellName, _, amount, overkill, _, _, _, _, critical = select(12, CombatLogGetCurrentEventInfo())
    end

    local isCrit = critical and true or false
    local ok = overkill or 0

    if amount and amount > 0 then
      -- 1. Hauptliste: Schaden (D)
      local added, rec = CB:AddRecord(CB.DB.damage, sourceName, spellName, amount, ts, isCrit, classFile, "local", "D", destName)
      if added and rec then
        rec.spellId = spellId
        rec.mapID = mapID
        rec.coordX = posX
        rec.coordY = posY
        rec.destGUID = destGUID
		rec.destName = destName
        SendRecord("D", rec)
        RefreshUI()
      end

      -- 2. Best-of-Spells: Angriffe (S)
      
      local addedS, recS = CB:AddSpellBest(sourceName, spellName, amount, ts, isCrit, classFile, "local", destName)
      if addedS and recS then
        recS.spellId = spellId
        recS.mapID = mapID
        recS.coordX = posX
        recS.coordY = posY
	    recS.destGUID = destGUID
        recS.destName = destName
        SendRecord("S", recS)
        RefreshUI()
      end
      
    end

    -- 3. Overkill (O)
    if ok and ok > 0 then
      local added, rec = CB:AddRecord(CB.DB.overkill, sourceName, spellName, ok, ts, isCrit, classFile, "local", "O", destName)
      if added and rec then
        rec.spellId = spellId
        rec.mapID = mapID
        rec.coordX = posX
        rec.coordY = posY
        rec.destGUID = destGUID
		rec.destName = destName
        SendRecord("O", rec)
        RefreshUI()
      end
    end

  -- =========================
  -- HEILUNG
  -- =========================

  elseif subevent == "SPELL_HEAL" then
    local spellId, spellName, _, amount, overkill, _, critical = select(12, CombatLogGetCurrentEventInfo())
    local isCrit = critical and true or false

    if amount and amount > 0 then
      -- 1. Hauptliste: Heilung (H) - Top 10/100
      local added, rec = CB:AddRecord(CB.DB.heal, sourceName, spellName, amount, ts, isCrit, classFile, "local", "H", destName)
      if added and rec then
        rec.spellId = spellId
        rec.mapID = mapID
        rec.coordX = posX
        rec.coordY = posY
        rec.destGUID = destGUID
		rec.destName = destName
        SendRecord("H", rec)
      end

      -- 2. Best-of-Spells: Heilung (HS) 
      -- ENTFERNT: "if isCrit then" -> Wir wollen JEDEN Bestwert pro Zauber, egal ob Crit oder nicht
      local addedHS, recHS = CB:AddHealSpellBest(sourceName, spellName, amount, ts, isCrit, classFile, "local", destName)
      if addedHS and recHS then
        recHS.spellId = spellId
        recHS.mapID = mapID
        recHS.coordX = posX
        recHS.coordY = posY
        recHS.destGUID = destGUID
		recHS.destName = destName
        SendRecord("HS", recHS)
      end
      
      -- UI immer aktualisieren, wenn eine Heilung verarbeitet wurde
      RefreshUI()
    end
  end
end