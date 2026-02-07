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
  if CB.DB.ui.disableSync == nil then CB.DB.ui.disableSync = false end

  CB.DB.damage = CB.DB.damage or { records = {}, seen = {}, revision = 0 }
  CB.DB.heal = CB.DB.heal or { records = {}, seen = {}, revision = 0 }
  CB.DB.overkill = CB.DB.overkill or { records = {}, seen = {}, revision = 0 }
  
  -- Spell Listen mit bySpell Mapping für effizientes Update
  CB.DB.spells = CB.DB.spells or { records = {}, bySpell = {}, revision = 0 }
  CB.DB.healSpells = CB.DB.healSpells or { records = {}, bySpell = {}, revision = 0 }
end

-- =========================================================
-- Alert System (Queue)
-- =========================================================
CB.alertQueue = {}
local isDisplayingAlert = false

function CB:QueueAlert(data)
  if not CB.DB.ui.alertsEnabled then return end
  table.insert(CB.alertQueue, data)
  CB:ProcessNextAlert()
end

function CB:ProcessNextAlert()
  if isDisplayingAlert or #CB.alertQueue == 0 then return end
  isDisplayingAlert = true
  
  local data = table.remove(CB.alertQueue, 1)
  if data.soundPath then
    PlaySoundFile(data.soundPath, "Master")
  end
  
  if data.msg then
    RaidNotice_AddMessage(RaidWarningFrame, data.msg, data.color or { r=1, g=1, b=1 })
  end
  
  C_Timer.After(2.0, function()
    isDisplayingAlert = false
    CB:ProcessNextAlert()
  end)
end

-- =========================================================
-- Core Add Functions
-- =========================================================

function CB:AddRecord(tbl, player, spell, amount, ts, isCrit, classFile, source)
  if not tbl or not tbl.records then return false end
  
  -- Dubletten-Check (Sync / Combat Log Überschneidung)
  local sig = string.format("%s-%s-%d", player, spell, amount)
  if tbl.seen and tbl.seen[sig] and (ts - tbl.seen[sig] < 2) then
    return false
  end
  if tbl.seen then tbl.seen[sig] = ts end

  local rec = {
    player = player,
    spell = spell,
    amount = amount,
    ts = ts,
    isCrit = isCrit,
    classFile = classFile,
    source = source
  }

  table.insert(tbl.records, rec)
  table.sort(tbl.records, SortDesc)

  -- WICHTIG: Auf 100 erhöhen für das neue UI
  while #tbl.records > 100 do
    table.remove(tbl.records)
  end

  tbl.revision = tbl.revision + 1

  -- Alert bei Platz 1 (nur Lokal)
  if source == "local" and tbl.records[1] == rec then
    CB:QueueAlert({
      soundPath = "Interface\\AddOns\\CrittersBoard\\sounds\\first.ogg",
      msg = "|cff00ffffNEUER PLATZ 1!|r " .. player .. " - " .. amount,
      color = { r=0, g=1, b=1 }
    })
  end

  return true, rec
end

function CB:AddSpellRecord(tbl, player, spell, amount, ts, isCrit, classFile, source)
  if not tbl or not tbl.records then return false end

  local key = CB:SafeStr(spell)
  tbl.bySpell = tbl.bySpell or {}
  local oldBest = tbl.bySpell[key]

  -- Wenn neu oder besserer Wert
  if not oldBest or amount > (oldBest.amount or 0) then
    local rec = nil
    if oldBest then
      -- Suche den existierenden Eintrag in der Liste zum Updaten
      for _, r in ipairs(tbl.records) do
        if r.spell == spell then
          rec = r
          break
        end
      end
    end

    if not rec then
      rec = { spell = spell }
      table.insert(tbl.records, rec)
    end

    rec.player = player
    rec.amount = amount
    rec.ts = ts
    rec.isCrit = isCrit
    rec.classFile = classFile
    rec.source = source
    
    tbl.bySpell[key] = rec
    
    table.sort(tbl.records, SortDesc)

    -- Auch hier: Erlaube Top 100 verschiedene Zauber
    while #tbl.records > 100 do
      local removed = table.remove(tbl.records)
      if removed then
        tbl.bySpell[CB:SafeStr(removed.spell)] = nil
      end
    end

    tbl.revision = tbl.revision + 1
    return true, rec
  end

  return false
end

function CB:AddSpellBest(player, spell, amount, ts, isCrit, classFile, source)
  if not CB.DB or not CB.DB.spells then return false end

  local key = CB:SafeStr(spell)
  CB.DB.spells.bySpell = CB.DB.spells.bySpell or {}
  local oldBest = CB.DB.spells.bySpell[key]

  local added, rec = CB:AddSpellRecord(CB.DB.spells, player, spell, amount, ts, isCrit, classFile, source)
  if not added or not rec then return false end

  -- Alarm nur wenn es ein echter neuer persönlicher Bestwert für diesen Spell ist
  if source == "local" then
    if not oldBest or rec.amount > (oldBest.amount or 0) then
      CB:QueueAlert({
        soundPath = "Interface\\AddOns\\CrittersBoard\\sounds\\first.ogg",
        msg = string.format(CB.L["MSG_NEW_RECORD"] .. " %s - %s (%d)", rec.player or "?", rec.spell or "?", rec.amount or 0),
        color = { r = 0.6, g = 0.6, b = 1 }
      })
    end
  end

  return true, rec
end

function CB:AddHealSpellBest(player, spell, amount, ts, isCrit, classFile, source)
  return CB:AddSpellRecord(CB.DB.healSpells, player, spell, amount, ts, isCrit, classFile, source)
end