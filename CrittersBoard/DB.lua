CrittersBoard = CrittersBoard or {}
local CB = CrittersBoard

-- ===== DB Init =====
function CB:InitDB()
  CB.DB = CB.DB or {}

  CB.DB.ui = CB.DB.ui or {}
  if CB.DB.ui.mode == nil then CB.DB.ui.mode = "D10" end
  if CB.DB.ui.locked == nil then CB.DB.ui.locked = false end
  if CB.DB.ui.bgAlpha == nil then CB.DB.ui.bgAlpha = 0.85 end
  if CB.DB.ui.w == nil then CB.DB.ui.w = 360 end
  if CB.DB.ui.h == nil then CB.DB.ui.h = 320 end
  if CB.DB.ui.isOpen == nil then CB.DB.ui.isOpen = false end

  -- Alerts on/off
  if CB.DB.ui.alertsEnabled == nil then
    CB.DB.ui.alertsEnabled = true
  end

  -- NEW: Main window scale
  if CB.DB.ui.scale == nil then
    CB.DB.ui.scale = 1.0
  end

  CB.DB.damage = CB.DB.damage or { records = {}, seen = {}, revision = 0 }
  CB.DB.heal = CB.DB.heal or { records = {}, seen = {}, revision = 0 }
  CB.DB.overkill = CB.DB.overkill or { records = {}, seen = {}, revision = 0 }

  CB.DB.lastTop1 = CB.DB.lastTop1 or { D = 0, H = 0, O = 0 }

  CB._alertQueue = CB._alertQueue or {}
  CB._alertTimerRunning = CB._alertTimerRunning or false
end

-- ===== helpers =====
local function SortDesc(a, b)
  return (a.amount or 0) > (b.amount or 0)
end

function CB:GetCurrentTable()
  local mode = CB.DB.ui.mode or "D10"

  if mode == "D10" or mode == "D100" then
    return CB.DB.damage, "Schaden"
  elseif mode == "H10" or mode == "H100" then
    return CB.DB.heal, "Heal"
  elseif mode == "O10" or mode == "O100" then
    return CB.DB.overkill, "Overkill"
  end

  return CB.DB.damage, "Schaden"
end

function CB:GetCurrentTopN()
  local mode = CB.DB.ui.mode or "D10"
  if mode == "D100" or mode == "H100" or mode == "O100" then
    return 100
  end
  return 10
end

-- ===== Alert Queue =====
local function PlayAlert(alert)
  if not alert then return end
  if not (CB.DB and CB.DB.ui and CB.DB.ui.alertsEnabled) then return end

  if alert.soundPath then
    PlaySoundFile(alert.soundPath, "Master")
  end

  if alert.msg then
    if RaidNotice_AddMessage and RaidWarningFrame then
      RaidNotice_AddMessage(RaidWarningFrame, alert.msg, alert.color or ChatTypeInfo["RAID_WARNING"])
    else
      local c = alert.color or { r = 1, g = 1, b = 0 }
      UIErrorsFrame:AddMessage(alert.msg, c.r or 1, c.g or 1, c.b or 0, 1)
    end
  end
end

function CB:QueueAlert(alert)
  if not alert then return end
  if not (CB.DB and CB.DB.ui and CB.DB.ui.alertsEnabled) then return end

  CB._alertQueue = CB._alertQueue or {}
  table.insert(CB._alertQueue, alert)

  if CB._alertTimerRunning then return end
  CB._alertTimerRunning = true

  local function Next()
    if not CB._alertQueue or #CB._alertQueue == 0 then
      CB._alertTimerRunning = false
      return
    end

    local a = table.remove(CB._alertQueue, 1)
    PlayAlert(a)
    C_Timer.After(1.2, Next)
  end

  Next()
end

function CB:OnNewTop1(listKey, rec)
  if not rec then return end
  if not (CB.DB and CB.DB.ui and CB.DB.ui.alertsEnabled) then return end

  local soundPath, msg
  local color = { r = 1, g = 1, b = 0 }

  if listKey == "D" then
    soundPath = "Interface\\AddOns\\CrittersBoard\\sounds\\dmg.ogg"
    msg = string.format("NEUER #1 SCHADEN!  %s - %s (%d)", rec.player or "?", rec.spell or "?", rec.amount or 0)
    color = { r = 1, g = 0.2, b = 0.2 }
  elseif listKey == "H" then
    soundPath = "Interface\\AddOns\\CrittersBoard\\sounds\\heal.ogg"
    msg = string.format("NEUER #1 HEAL!  %s - %s (%d)", rec.player or "?", rec.spell or "?", rec.amount or 0)
    color = { r = 0.2, g = 1, b = 0.2 }
  elseif listKey == "O" then
    soundPath = "Interface\\AddOns\\CrittersBoard\\sounds\\overkill.ogg"
    msg = string.format("NEUER #1 OVERKILL!  %s - %s (%d)", rec.player or "?", rec.spell or "?", rec.amount or 0)
    color = { r = 1, g = 0.6, b = 0.2 }
  end

  CB:QueueAlert({ soundPath = soundPath, msg = msg, color = color })
end

function CB:AddRecord(tbl, player, spell, amount, ts, isCrit, classFile, source)
  if not tbl then return false end
  tbl.records = tbl.records or {}
  tbl.seen = tbl.seen or {}

  amount = tonumber(amount) or 0
  if amount <= 0 then return false end

  local id = CB:SafeStr(player) .. "|" .. CB:SafeStr(spell) .. "|" .. tostring(amount) .. "|" .. tostring(ts) .. "|" ..
    tostring(isCrit and 1 or 0) .. "|" .. CB:SafeStr(classFile or "")

  if tbl.seen[id] then return false end
  tbl.seen[id] = true

  local rec = {
    id = id,
    player = player,
    spell = spell,
    amount = amount,
    ts = ts,
    isCrit = isCrit and true or false,
    class = classFile,
    source = source or "local",
  }

  table.insert(tbl.records, rec)
  table.sort(tbl.records, SortDesc)

  while #tbl.records > 100 do
    local removed = table.remove(tbl.records)
    if removed and removed.id then
      tbl.seen[removed.id] = nil
    end
  end

  tbl.revision = (tbl.revision or 0) + 1

  local listKey = nil
  if tbl == CB.DB.damage then listKey = "D"
  elseif tbl == CB.DB.heal then listKey = "H"
  elseif tbl == CB.DB.overkill then listKey = "O"
  end

  if listKey then
    local top = tbl.records[1]
    if top and top.amount then
      local last = CB.DB.lastTop1[listKey] or 0
      if top.amount > last then
        CB.DB.lastTop1[listKey] = top.amount
        CB:OnNewTop1(listKey, top)
      end
    end
  end

  return true
end
