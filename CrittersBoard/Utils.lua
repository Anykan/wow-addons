CrittersBoard = CrittersBoard or {}
local CB = CrittersBoard

-- =========================================================
-- ALLGEMEINE HELFER
-- =========================================================
function CB:Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cff66ff66CrittersBoard|r: " .. tostring(msg))
end

function CB:SafeStr(s)
  if not s then return "" end
  -- Entfernt Trennzeichen, um den Sync-String nicht zu brechen
  return tostring(s):gsub("|", "/")
end

function CB:DLog(id, val1, val2, val3)
    local logs = {
        [1] = "|cffffff00DEBUG Swing 1:|r Schaden: " .. tostring(val1 or "0"),
        [2] = "DEBUG: Core - FEHLER 2: RequestSnapshot Funktion fehlt!",
		[3] = "|cff00ff00DEBUG Spell: 3|r " .. tostring(arg13) .. " (ID: " .. tostring(arg12) .. ") -> Schaden: " .. tostring(arg15),
		[4] = "|cff00ffffDEBUG Queue: 4|r Aktuelle Warteschlange: " .. tostring(val1 or "0") .. " Einträge.",
		[5] = "|cff00ff00DEBUG Sync: 5|r Daten empfangen von: " .. tostring(val1 or "Unbekannt") .. " (Kanal: " .. tostring(val2 or "??") .. ")",
		[7] = "|cffff0000DEBUG Sync-OUT 7:|r Sende Daten-Typ: " .. tostring(val1 or "??"),
		[8] = "|cff0000ffDEBUG Sync-DETAIL 8:|r Inhalt: " .. tostring(val1 or "leer"),
		[9] = "|cffffa500DEBUG Sync-STSTOP 9:|r " .. tostring(val1 or "Aktion")
    }
    
    if logs[id] then 
        self:Print(logs[id]) 
    end
end
-- =========================================================
-- STANDORT-ENGINE (NEU in v0.5)
-- =========================================================
function CB:GetLocation()
  local mapID = C_Map.GetBestMapForUnit("player")
  local x, y = 0, 0
  
  if mapID then
    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    if pos then
      -- Wir speichern 1 Dezimalstelle (z.B. 45.2)
      x = math.floor(pos.x * 1000) / 10
      y = math.floor(pos.y * 1000) / 10
    end
  end
  
  return mapID or 0, x, y
end

-- =========================================================
-- FARB-HELFER
-- =========================================================
function CB:ColorText(text, r, g, b)
  local rr = math.floor((r or 1) * 255)
  local gg = math.floor((g or 1) * 255)
  local bb = math.floor((b or 1) * 255)
  return string.format("|cff%02x%02x%02x%s|r", rr, gg, bb, text or "")
end

function CB:GetClassColorFromClassFile(classFile)
  if classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile] then
    local c = RAID_CLASS_COLORS[classFile]
    return c.r, c.g, c.b
  end
  return 1, 1, 1
end

-- =========================================================
-- ALERT-QUEUE (Management für Sound & Text)
-- =========================================================
CB.alertQueue = CB.alertQueue or {}
local isProcessing = false

function CB:QueueAlert(data)
  -- 1. Sync-Schutz (Keine Sounds beim Einloggen/Abgleich)
  if CB.Sync and CB.Sync.isSyncActive then 
    return 
  end
  
  -- 2. Limit vom Slider laden (Standard 5)
  local maxAlerts = (CB.DB and CB.DB.ui and CB.DB.ui.alertLimit) or 5
  
  -- 3. Berechnung: Wie viele sind gerade aktiv?
  -- Warteschlange + 1 (falls gerade ein Sound abgespielt wird)
  local currentActive = #CB.alertQueue
  if isProcessing then 
    currentActive = currentActive + 1 
  end
  
  -- 4. STRENGE PRÜFUNG:
  -- Wenn currentActive schon das Limit erreicht hat, darf nichts Neues rein.
  -- Bei Slider auf 1: Wenn einer spielt (currentActive = 1), wird 1 >= 1 wahr -> ABBRUCH.
  if currentActive >= maxAlerts then 
    return 
  end
  
  -- 5. Alert in die Schlange aufnehmen
  table.insert(CB.alertQueue, data)
  
  if CB.DEBUG_MODE then 
    CB:DLog(4, #CB.alertQueue) 
  end
  
  -- 6. Abarbeitung starten, falls sie noch nicht läuft
  if not isProcessing then
    CB:ProcessNextAlert()
  end
end

function CB:ProcessNextAlert()
  if #CB.alertQueue == 0 then
    isProcessing = false
    return
  end

  isProcessing = true
  local data = table.remove(CB.alertQueue, 1)

  -- 1. Sound abspielen
  if data.soundPath then
    PlaySoundFile(data.soundPath, "Master")
  end

  -- 2. Text-Meldung
  if data.msg then
    RaidNotice_AddMessage(RaidWarningFrame, data.msg, data.color or {r=1, g=1, b=1})
  end

  -- 3. NEU: Titan Panel nur aktualisieren, wenn dieser Alert dran ist
  -- Wir nehmen die Daten aus dem Rekord, der den Alert ausgelöst hat
  if data.rec and CB.UpdateLDB then
    CB:UpdateLDB(data.rec)
  end

  C_Timer.After(1.5, function()
    CB:ProcessNextAlert()
  end)
end