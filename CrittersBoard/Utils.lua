CrittersBoard = CrittersBoard or {}
local CB = CrittersBoard

CB.PREFIX = "CB_CRIT"

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
  table.insert(CB.alertQueue, data)
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

  -- Sound abspielen
  if data.soundPath then
    PlaySoundFile(data.soundPath, "Master")
  end

  -- Text-Meldung (Raid Warning Style)
  if data.msg then
    RaidNotice_AddMessage(RaidWarningFrame, data.msg, data.color or {r=1, g=1, b=1})
  --  CB:Print(data.msg)
  end

  -- Kleiner Delay zwischen mehreren Alerts (1.5 Sek)
  C_Timer.After(1.5, function()
    CB:ProcessNextAlert()
  end)
end