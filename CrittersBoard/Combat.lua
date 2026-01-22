CrittersBoard = CrittersBoard or {}
local CB = CrittersBoard

local function GetMainHandName()
  local link = GetInventoryItemLink("player", 16)
  if link then
    local name = GetItemInfo(link)
    return name or link
  end
  return nil
end

local function GetRangedName()
  local link = GetInventoryItemLink("player", 18)
  if link then
    local name = GetItemInfo(link)
    return name or link
  end
  return nil
end

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
  local _, subevent, _, sourceGUID, sourceName, _, _, _, destName = CombatLogGetCurrentEventInfo()
  if sourceGUID ~= UnitGUID("player") then return end

  if not CB.DB then return end
  if not CB.DB.damage or not CB.DB.heal or not CB.DB.overkill then return end

  local ts = time()
  local _, classFile = UnitClass("player")
  local region = GetRealmName()

  local weaponMain = GetMainHandName()
  local weaponRanged = GetRangedName()

  -- =========================
  -- SWING DAMAGE (Melee)
  -- =========================
  if subevent == "SWING_DAMAGE" then
    local amount, overkill, _, _, _, _, critical = select(12, CombatLogGetCurrentEventInfo())
    local isCrit = critical and true or false
    local ok = (overkill and tonumber(overkill) and tonumber(overkill) > 0) and tonumber(overkill) or nil
    local spell = "Melee"

    if amount and amount > 0 then
      local added, rec = CB:AddRecord(CB.DB.damage, sourceName, spell, amount, ts, isCrit, classFile, "local")
      if added and rec then
        -- decorate the REAL record in DB
        rec.target = destName
        rec.region = region
        rec.weapon = weaponMain
        rec.overkill = ok

        -- send normal damage event
        SendRecord("D", rec)

        -- SpellBest
        local changed = false
        if CB.AddSpellBest then
          changed = CB:AddSpellBest(sourceName, spell, amount, ts, isCrit, classFile, "local") and true or false
        end

        if changed then
          SendRecord("S", rec)
        end

        RefreshUI()
      end
    end

    -- Overkill list
    if ok and ok > 0 then
      local added, rec = CB:AddRecord(CB.DB.overkill, sourceName, spell, ok, ts, isCrit, classFile, "local")
      if added and rec then
        rec.target = destName
        rec.region = region
        rec.weapon = weaponMain
        rec.overkill = ok

        SendRecord("O", rec)
        RefreshUI()
      end
    end

  -- =========================
  -- SPELL / RANGE DAMAGE
  -- =========================
  elseif subevent == "SPELL_DAMAGE" or subevent == "RANGE_DAMAGE" then
    local spellId, spellName, _, amount, overkill, _, _, _, _, critical = select(12, CombatLogGetCurrentEventInfo())
    local sName = spellName or ("Spell:" .. tostring(spellId))
    local isCrit = critical and true or false
    local ok = (overkill and tonumber(overkill) and tonumber(overkill) > 0) and tonumber(overkill) or nil

    local weapon = nil
    if subevent == "RANGE_DAMAGE" then
      weapon = weaponRanged
    end

    if amount and amount > 0 then
      local added, rec = CB:AddRecord(CB.DB.damage, sourceName, sName, amount, ts, isCrit, classFile, "local")
      if added and rec then
        rec.target = destName
        rec.region = region
        rec.weapon = weapon
        rec.overkill = ok

        SendRecord("D", rec)

        -- SpellBest
        local changed = false
        if CB.AddSpellBest then
          changed = CB:AddSpellBest(sourceName, sName, amount, ts, isCrit, classFile, "local") and true or false
        end

        if changed then
          SendRecord("S", rec)
        end

        RefreshUI()
      end
    end

    -- Overkill list
    if ok and ok > 0 then
      local added, rec = CB:AddRecord(CB.DB.overkill, sourceName, sName, ok, ts, isCrit, classFile, "local")
      if added and rec then
        rec.target = destName
        rec.region = region
        rec.weapon = weapon
        rec.overkill = ok

        SendRecord("O", rec)
        RefreshUI()
      end
    end

  -- =========================
  -- HEAL
  -- =========================
  elseif subevent == "SPELL_HEAL" then
    local spellId, spellName, _, amount, _, _, critical = select(12, CombatLogGetCurrentEventInfo())
    local sName = spellName or ("Heal:" .. tostring(spellId))
    local isCrit = critical and true or false

    if amount and amount > 0 then
      local added, rec = CB:AddRecord(CB.DB.heal, sourceName, sName, amount, ts, isCrit, classFile, "local")
      if added and rec then
        rec.target = destName
        rec.region = region
        rec.weapon = nil
        rec.overkill = nil

        SendRecord("H", rec)

        -- HealSpellBest
        local changed = false
        if CB.AddHealSpellBest then
          changed = CB:AddHealSpellBest(sourceName, sName, amount, ts, isCrit, classFile, "local") and true or false
        end

        if changed then
          SendRecord("HS", rec)
        end

        RefreshUI()
      end
    end
  end
end
