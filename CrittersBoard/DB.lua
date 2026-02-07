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

  if CB.DB.ui.mode == nil then CB.DB.ui.mode = "D10" end
  if CB.DB.ui.scale == nil then CB.DB.ui.scale = 1.0 end
  if CB.DB.ui.locked == nil then CB.DB.ui.locked = false end
  if CB.DB.ui.isOpen == nil then CB.DB.ui.isOpen = false end
  if CB.DB.ui.alertsEnabled == nil then CB.DB.ui.alertsEnabled = true end
  if CB.DB.ui.shareAfterSync == nil then CB.DB.ui.shareAfterSync = true end

  CB.DB.damage = CB.DB.damage or { records = {}, seen = {}, revision = 0 }
  CB.DB.heal = CB.DB.heal or { records = {}, seen = {}, revision = 0 }
  CB.DB.overkill = CB.DB.overkill or { records = {}, seen = {}, revision = 0 }
  CB.DB.spells = CB.DB.spells or { records = {}, bySpell = {}, revision = 0 }
  CB.DB.healspells = CB.DB.healspells or { records = {}, bySpell = {}, revision = 0 }
end

-- =========================================================
-- Clear Data (Neu hinzugefügt)
-- =========================================================
function CB:ClearCurrentList()
  -- Alle Listen komplett leeren
  CB.DB.damage = { records = {}, seen = {}, revision = 0 }
  CB.DB.heal = { records = {}, seen = {}, revision = 0 }
  CB.DB.overkill = { records = {}, seen = {}, revision = 0 }
  CB.DB.spells = { records = {}, bySpell = {}, revision = 0 }
  CB.DB.healspells = { records = {}, bySpell = {}, revision = 0 }

  -- Verhindert, dass der automatische Share/Sync sofort wieder alles füllt
  if CB.Sync then
    CB.Sync.syncWasPulled = false
    CB.Sync.shareRunning = false
    -- Optional: Timer abbrechen, falls einer läuft
    if CB.Sync.syncFinishTimer then
        CB.Sync.syncFinishTimer:Cancel()
        CB.Sync.syncFinishTimer = nil
    end
  end

  print("|cFF00FF00CrittersBoard: Alle Listen wurden geleert. Sync pausiert bis zum nächsten Login oder manuellem Sync.|r")
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
  if mode:find("100") then return 100 end
  return 10
end

-- =========================================================
-- Alerts (mit Queue-Limit)
-- =========================================================
local function PlayAlert(alert)
  if not alert then return end
  if CB.DB.ui.alertsEnabled == false then return end

  if alert.soundPath then
    PlaySoundFile(alert.soundPath, "Master")
  end

  if alert.msg then
    if RaidNotice_AddMessage and RaidWarningFrame then
      RaidNotice_AddMessage(
        RaidWarningFrame,
        alert.msg,
        alert.color or ChatTypeInfo["RAID_WARNING"]
      )
    else
      UIErrorsFrame:AddMessage(
        alert.msg,
        alert.color.r,
        alert.color.g,
        alert.color.b,
        1
      )
    end
  end
end

function CB:QueueAlert(alert)
  if CB.DB.ui.alertsEnabled == false then return end

  CB._alertQueue = CB._alertQueue or {}

  -- NEU: Limit auf maximal 10 wartende Meldungen
  if #CB._alertQueue >= 10 then 
    return 
  end

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
    C_Timer.After(1.5, Next)
  end

  Next()
end

function CB:OnNewTop1(listKey, rec)
  if CB.DB.ui.alertsEnabled == false then return end

  local soundPath, msg, color

  if listKey == "D" then
    soundPath = "Interface\\AddOns\\CrittersBoard\\sounds\\dmg.ogg"
    msg = string.format("NEUER #1 SCHADEN!  %s - %s (%d)", rec.player, rec.spell, rec.amount)
    color = { r = 1, g = 0.2, b = 0.2 }

  elseif listKey == "H" then
    soundPath = "Interface\\AddOns\\CrittersBoard\\sounds\\heal.ogg"
    msg = string.format("NEUER #1 HEAL!  %s - %s (%d)", rec.player, rec.spell, rec.amount)
    color = { r = 0.2, g = 1, b = 0.2 }

  elseif listKey == "O" then
    soundPath = "Interface\\AddOns\\CrittersBoard\\sounds\\overkill.ogg"
    msg = string.format("NEUER #1 OVERKILL!  %s - %s (%d)", rec.player, rec.spell, rec.amount)
    color = { r = 1, g = 0.6, b = 0.2 }

  elseif listKey == "S" then
    soundPath = "Interface\\AddOns\\CrittersBoard\\sounds\\first.ogg"
    msg = string.format("NEUER #1 ANGRIFF!  %s - %s (%d)", rec.player, rec.spell, rec.amount)
    color = { r = 0.6, g = 0.6, b = 1 }

  elseif listKey == "HS" then
    soundPath = "Interface\\AddOns\\CrittersBoard\\sounds\\heal2.ogg"
    msg = string.format("NEUER #1 HEILUNG!  %s - %s (%d)", rec.player, rec.spell, rec.amount)
    color = { r = 0.2, g = 0.8, b = 1 }
  end

  CB:QueueAlert({ soundPath = soundPath, msg = msg, color = color })
end

-- =========================================================
-- AddRecord (Damage / Heal / Overkill)
-- =========================================================
function CB:AddRecord(tbl, player, spell, amount, ts, isCrit, classFile, source)
  if not tbl then return false end

  tbl.records = tbl.records or {}
  tbl.seen = tbl.seen or {}

  amount = tonumber(amount) or 0
  if amount <= 0 then return false end

  local id = CB:SafeStr(player) .. "|" .. CB:SafeStr(spell) .. "|" .. amount .. "|" .. ts
  if tbl.seen[id] then return false end
  tbl.seen[id] = true

  local rec = {
    id = id,
    player = player,
    spell = spell,
    amount = amount,
    ts = ts,
    isCrit = isCrit,
    class = classFile,
    source = source or "local",
  }

  table.insert(tbl.records, rec)
  table.sort(tbl.records, SortDesc)

  if tbl.records[1] == rec then
    local kind = "D"
    if tbl == CB.DB.heal then kind = "H" 
    elseif tbl == CB.DB.overkill then kind = "O" end
    CB:OnNewTop1(kind, rec)
  end

  while #tbl.records > 100 do
    local r = table.remove(tbl.records)
    tbl.seen[r.id] = nil
  end

  tbl.revision = tbl.revision + 1
  return true, rec
end

-- =========================================================
-- Spell Records (Angriffe / Heilungen Best-of)
-- =========================================================
function CB:AddSpellRecord(tbl, player, spell, amount, ts, isCrit, classFile, source)
  tbl.records = tbl.records or {}
  tbl.bySpell = tbl.bySpell or {}

  amount = tonumber(amount) or 0
  if amount <= 0 then return false end

  local key = CB:SafeStr(spell)
  local old = tbl.bySpell[key]
  if old and old.amount >= amount then return false end

  local rec = {
    player = player,
    spell = spell,
    amount = amount,
    ts = ts,
    isCrit = isCrit,
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

  tbl.revision = tbl.revision + 1
  return true, rec
end

function CB:AddSpellBest(player, spell, amount, ts, isCrit, classFile, source)
  if not CB.DB or not CB.DB.spells then return false end

  local key = CB:SafeStr(spell)
  CB.DB.spells.bySpell = CB.DB.spells.bySpell or {}
  local oldBest = CB.DB.spells.bySpell[key]

  local added, rec = CB:AddSpellRecord(CB.DB.spells, player, spell, amount, ts, isCrit, classFile, source)
  if not added or not rec then return false end

  if not oldBest or rec.amount > (oldBest.amount or 0) then
    CB:QueueAlert({
      soundPath = "Interface\\AddOns\\CrittersBoard\\sounds\\first.ogg",
      msg = string.format("NEUER SPELL-REKORD! %s - %s (%d)", rec.player or "?", rec.spell or "?", rec.amount or 0),
      color = { r = 0.6, g = 0.6, b = 1 }
    })
  end

  if CB.DB.spells.records and CB.DB.spells.records[1] == rec then
    CB:OnNewTop1("S", rec)
  end

  return true, rec
end

function CB:AddHealSpellBest(player, spell, amount, ts, isCrit, classFile, source)
  if not CB.DB or not CB.DB.healspells then return false end

  local added, rec = CB:AddSpellRecord(CB.DB.healspells, player, spell, amount, ts, isCrit, classFile, source)
  if not added then return false end

  if CB.DB.healspells.records and CB.DB.healspells.records[1] == rec then
    CB:OnNewTop1("HS", rec)
  end

  return true, rec
end