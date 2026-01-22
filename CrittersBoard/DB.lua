CrittersBoard = CrittersBoard or {}
local CB = CrittersBoard

-- =========================================================
-- Helpers
-- =========================================================
local function SortDesc(a, b)
  return (a.amount or 0) > (b.amount or 0)
end

local function Now()
  return time()
end

-- =========================================================
-- Init DB
-- =========================================================
function CB:InitDB()
  CB.DB = CB.DB or {}
  CB.DB.ui = CB.DB.ui or {}

  -- Main UI defaults
  if CB.DB.ui.mode == nil then
    CB.DB.ui.mode = "D10"
  end

  if CB.DB.ui.scale == nil then
    CB.DB.ui.scale = 1.0
  end

  if CB.DB.ui.locked == nil then
    CB.DB.ui.locked = false
  end

  if CB.DB.ui.isOpen == nil then
    CB.DB.ui.isOpen = false
  end

  -- Alerts default (Audio + Warnmeldung)
  if CB.DB.ui.alertsEnabled == nil then
    CB.DB.ui.alertsEnabled = true
  end

  -- Share after sync (Default: AN)
  if CB.DB.ui.shareAfterSync == nil then
    CB.DB.ui.shareAfterSync = true
  end

  -- Tables
  CB.DB.damage = CB.DB.damage or { records = {}, seen = {}, revision = 0 }
  CB.DB.heal = CB.DB.heal or { records = {}, seen = {}, revision = 0 }
  CB.DB.overkill = CB.DB.overkill or { records = {}, seen = {}, revision = 0 }

  -- Angriffe (Best pro Spell)
  CB.DB.spells = CB.DB.spells or { records = {}, bySpell = {}, revision = 0 }

  -- Heilungen (Best pro Spell)
  CB.DB.healspells = CB.DB.healspells or { records = {}, bySpell = {}, revision = 0 }
end

-- =========================================================
-- Current Table + TopN
-- =========================================================
function CB:GetCurrentTable()
  local mode = CB.DB.ui.mode or "D10"

  if mode == "D10" or mode == "D100" then
    return CB.DB.damage, "Schaden"
  elseif mode == "H10" or mode == "H100" then
    return CB.DB.heal, "Heal"
  elseif mode == "O10" or mode == "O100" then
    return CB.DB.overkill, "Overkill"
  elseif mode == "S10" or mode == "S100" then
    return CB.DB.spells, "Angriffe"
  elseif mode == "HS10" or mode == "HS100" then
    return CB.DB.healspells, "Heilungen"
  end

  return CB.DB.damage, "Schaden"
end

function CB:GetCurrentTopN()
  local mode = CB.DB.ui.mode or "D10"

  if mode == "D100" or mode == "H100" or mode == "O100" or mode == "S100" or mode == "HS100" then
    return 100
  end

  return 10
end

-- =========================================================
-- Alerts (Sound + RaidWarning/UIErrors)
-- =========================================================
local function PlayAlert(alert)
  if not alert then return end

  -- nur AUS wenn wirklich false
  if CB.DB and CB.DB.ui and CB.DB.ui.alertsEnabled == false then
    return
  end

  if alert.soundPath and alert.soundPath ~= "" then
    PlaySoundFile(alert.soundPath, "Master")
  end

  if alert.msg and alert.msg ~= "" then
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

  if CB.DB and CB.DB.ui and CB.DB.ui.alertsEnabled == false then
    return
  end

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

    -- 1.5 Sekunden Pause
    C_Timer.After(1.5, Next)
  end

  Next()
end

function CB:OnNewTop1(listKey, rec)
  if not rec then return end
  if CB.DB and CB.DB.ui and CB.DB.ui.alertsEnabled == false then return end

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

  elseif listKey == "S" then
    soundPath = "Interface\\AddOns\\CrittersBoard\\sounds\\first.ogg"
    msg = string.format("NEUER #1 ANGRIFF!  %s - %s (%d)", rec.player or "?", rec.spell or "?", rec.amount or 0)
    color = { r = 0.6, g = 0.6, b = 1 }

  elseif listKey == "HS" then
    soundPath = "Interface\\AddOns\\CrittersBoard\\sounds\\heal2.ogg"
    msg = string.format("NEUER #1 HEILUNG!  %s - %s (%d)", rec.player or "?", rec.spell or "?", rec.amount or 0)
    color = { r = 0.2, g = 0.8, b = 1 }
  end

  CB:QueueAlert({ soundPath = soundPath, msg = msg, color = color })
end

-- =========================================================
-- AddRecord (Top Hits / Heals / Overkill)
-- =========================================================
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
  return true, rec
end

-- =========================================================
-- Best-of per Spell (Angriffe / Heilungen)
-- =========================================================
function CB:AddSpellRecord(tbl, player, spell, amount, ts, isCrit, classFile, source)
  if not tbl then return false end
  tbl.records = tbl.records or {}
  tbl.bySpell = tbl.bySpell or {}

  amount = tonumber(amount) or 0
  if amount <= 0 then return false end

  local key = CB:SafeStr(spell)
  if key == "" then return false end

  local old = tbl.bySpell[key]
  if old and (old.amount or 0) >= amount then
    return false
  end

  local rec = {
    player = player,
    spell = spell,
    amount = amount,
    ts = ts,
    isCrit = isCrit and true or false,
    class = classFile,
    source = source or "local",
  }

  tbl.bySpell[key] = rec

  wipe(tbl.records)
  for _, r in pairs(tbl.bySpell) do
    table.insert(tbl.records, r)
  end
  table.sort(tbl.records, SortDesc)

  while #tbl.records > 100 do
    table.remove(tbl.records)
  end

  tbl.revision = (tbl.revision or 0) + 1
  return true, rec
end

-- =========================================================
-- MISSING FUNCTIONS (FIX!)
-- Combat.lua calls these -> without them lists stay empty
-- =========================================================
function CB:AddSpellBest(player, spell, amount, ts, isCrit, classFile, source)
  if not CB.DB or not CB.DB.spells then return false end

  local oldTop1 = (CB.DB.spells.records and CB.DB.spells.records[1]) or nil
  local added, rec = CB:AddSpellRecord(CB.DB.spells, player, spell, amount, ts, isCrit, classFile, source)
  if not added or not rec then return false end

  local newTop1 = (CB.DB.spells.records and CB.DB.spells.records[1]) or nil
  if newTop1 and newTop1 ~= oldTop1 and newTop1 == rec then
    CB:OnNewTop1("S", rec)
  end

  return true, rec
end

function CB:AddHealSpellBest(player, spell, amount, ts, isCrit, classFile, source)
  if not CB.DB or not CB.DB.healspells then return false end

  local oldTop1 = (CB.DB.healspells.records and CB.DB.healspells.records[1]) or nil
  local added, rec = CB:AddSpellRecord(CB.DB.healspells, player, spell, amount, ts, isCrit, classFile, source)
  if not added or not rec then return false end

  local newTop1 = (CB.DB.healspells.records and CB.DB.healspells.records[1]) or nil
  if newTop1 and newTop1 ~= oldTop1 and newTop1 == rec then
    CB:OnNewTop1("HS", rec)
  end

  return true, rec
end
