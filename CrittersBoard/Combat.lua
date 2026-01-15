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

local function MakeEventId(player, spell, amount, ts, isCrit, classFile)
  return CB:SafeStr(player) .. "|" .. CB:SafeStr(spell) .. "|" .. tostring(amount) .. "|" .. tostring(ts) .. "|" ..
    tostring(isCrit and 1 or 0) .. "|" .. CB:SafeStr(classFile or "")
end

local function DecorateById(tbl, id, destName, region, weapon, overkill)
  if not tbl or not tbl.records or not id then return false end
  for i = 1, #tbl.records do
    local rec = tbl.records[i]
    if rec and rec.id == id then
      rec.target = destName
      rec.region = region
      rec.weapon = weapon
      rec.overkill = overkill
      return true
    end
  end
  return false
end

local function RefreshUI()
  if CB.UI and CB.UI.Refresh then
    CB.UI:Refresh()
  end
end

local function SendRecord(kind, rec)
  if not CB.SendEvent then return end
  -- NEW signature: SendEvent(kind, recTable)
  CB:SendEvent(kind, rec)
end

function CB:OnCombatLog()
  local _, subevent, _, sourceGUID, sourceName, _, _, _, destName = CombatLogGetCurrentEventInfo()
  if sourceGUID ~= UnitGUID("player") then return end

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
      if CB:AddRecord(CB.DB.damage, sourceName, spell, amount, ts, isCrit, classFile, "local") then
        local id = MakeEventId(sourceName, spell, amount, ts, isCrit, classFile)

        local rec = {
          player = sourceName,
          class = classFile,
          spell = spell,
          amount = amount,
          ts = ts,
          isCrit = isCrit,
          target = destName,
          region = region,
          weapon = weaponMain,
          overkill = ok,
        }

        DecorateById(CB.DB.damage, id, destName, region, weaponMain, ok)
        RefreshUI()
        SendRecord("D", rec)
      end
    end

    if ok and ok > 0 then
      if CB:AddRecord(CB.DB.overkill, sourceName, spell, ok, ts, isCrit, classFile, "local") then
        local id = MakeEventId(sourceName, spell, ok, ts, isCrit, classFile)

        local rec = {
          player = sourceName,
          class = classFile,
          spell = spell,
          amount = ok,
          ts = ts,
          isCrit = isCrit,
          target = destName,
          region = region,
          weapon = weaponMain,
          overkill = ok,
        }

        DecorateById(CB.DB.overkill, id, destName, region, weaponMain, ok)
        RefreshUI()
        SendRecord("O", rec)
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
      if CB:AddRecord(CB.DB.damage, sourceName, sName, amount, ts, isCrit, classFile, "local") then
        local id = MakeEventId(sourceName, sName, amount, ts, isCrit, classFile)

        local rec = {
          player = sourceName,
          class = classFile,
          spell = sName,
          amount = amount,
          ts = ts,
          isCrit = isCrit,
          target = destName,
          region = region,
          weapon = weapon,
          overkill = ok,
        }

        DecorateById(CB.DB.damage, id, destName, region, weapon, ok)
        RefreshUI()
        SendRecord("D", rec)
      end
    end

    if ok and ok > 0 then
      if CB:AddRecord(CB.DB.overkill, sourceName, sName, ok, ts, isCrit, classFile, "local") then
        local id = MakeEventId(sourceName, sName, ok, ts, isCrit, classFile)

        local rec = {
          player = sourceName,
          class = classFile,
          spell = sName,
          amount = ok,
          ts = ts,
          isCrit = isCrit,
          target = destName,
          region = region,
          weapon = weapon,
          overkill = ok,
        }

        DecorateById(CB.DB.overkill, id, destName, region, weapon, ok)
        RefreshUI()
        SendRecord("O", rec)
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
      if CB:AddRecord(CB.DB.heal, sourceName, sName, amount, ts, isCrit, classFile, "local") then
        local id = MakeEventId(sourceName, sName, amount, ts, isCrit, classFile)

        local rec = {
          player = sourceName,
          class = classFile,
          spell = sName,
          amount = amount,
          ts = ts,
          isCrit = isCrit,
          target = destName,
          region = region,
          weapon = nil,
          overkill = nil,
        }

        DecorateById(CB.DB.heal, id, destName, region, nil, nil)
        RefreshUI()
        SendRecord("H", rec)
      end
    end
  end
end
