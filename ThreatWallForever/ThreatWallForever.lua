--[[
  ThreatWall Forever 0.1

  A compact aggro-leak watcher. By default it does not show a full threat
  list — only enemies that are currently a problem for you, one row each,
  sorted worst first. An optional "Show all fights" setting adds every
  engaged enemy to the list, including a green row for ones you have no
  problem with right now.

  Two modes, switched with the header button or the settings menu:
    Tank mode    - shows enemies you are LOSING aggro on (or never had).
    DD/Heal mode - shows enemies where YOU are pulling too much aggro.

  Both modes read the same number from the game: UnitDetailedThreatSituation
  status (0-3) for your own threat on that enemy. Only the color mapping
  flips between the two modes.

  Rows are plain, non-secure buttons - display and tooltip only, no
  click-to-target for now. Confirmed with a live test AND an external,
  tracked bug report (ClassicWoWCommunity/forever-bugs#74): this WoW Forever
  beta build's secure-snippet compiler is broken client-side
  (loadstring_untainted gets wiped before RestrictedExecution.lua can use
  it, a load-order bug in Blizzard_EnvironmentCleanup.toc), so
  SecureActionButtonTemplate cannot execute a protected action at all right
  now - not just in this addon, this breaks click-casting in general
  (Clique is named in the same report). No addon-side workaround exists.
  Revisit click-to-target once a Forever build fixes this upstream.

  This client can also hand addons "secret" values in combat that may be
  shown but not compared. Where that happens, the affected enemy is simply
  skipped for that refresh rather than guessed at.
]]

local ADDON = ...
local PREFIX = '|cff33ff99ThreatWall Forever:|r '
local L = ThreatWallForeverLocale

-- Single source of truth for the version string: the .toc's ## Version
-- line - the one place already bumped on every release, so the title bar
-- and the boot message never drift apart or need updating twice.
local VERSION = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(ADDON, 'Version'))
  or (GetAddOnMetadata and GetAddOnMetadata(ADDON, 'Version')) or '?'

local DEFAULTS = {
  shown = true,
  locked = false,
  scale = 1,
  minimized = false,
  width = 240,
  height = 160,
  alpha = 0.4,
  rowHeight = 20,
  textScale = 1,
  role = 'tank',            -- 'tank' or 'dps'
  combatOnly = false,
  groupOnly = true,
  showAll = false,
  sound = true,
  minimap = true,
  minimapAngle = 200,
  debug = false,
  markMethod = 1,
  hideNameplateHint = false,
}

local MAX_ROWS = 10
local GRACE = 1.0              -- seconds a row stays up after it turns green/vanishes
local TICK = 0.2               -- 5 checks a second is plenty for aggro state
local HEADER_H = 30
local FLAT = 'Interface\\Buttons\\WHITE8X8'
local RAID_ICONS_ATLAS = 'Interface\\TargetingFrame\\UI-RaidTargetingIcons'
local ADDON_ICON = 'Interface\\Icons\\Ability_Warrior_Challange'

local COLOR = {
  red = { 0.82, 0.14, 0.14 },
  yellow = { 0.92, 0.72, 0.12 },
  green = { 0.25, 0.75, 0.25 },
}
local RANK = { red = 2, yellow = 1, green = 0 }

-- Atlas / fallback helpers -----------------------------------------------------

local function hasAtlas(name)
  return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name) ~= nil
end

local function setAtlas(tex, name, fallback, useSize)
  if hasAtlas(name) then
    tex:SetAtlas(name, useSize or false)
    return true
  end
  if fallback then tex:SetTexture(fallback) end
  return false
end

local function IsSecret(v)
  return issecretvalue ~= nil and issecretvalue(v) or false
end

local function plain(v)
  if IsSecret(v) then return nil end
  return v
end

local db
local frame, header, titleText, subText, gear, roleBtn, minimize, grip, mm
local rows = {}
local tracked = {}             -- guid (or unit token, if the guid is unreadable) -> { unit, name, markIndex, shownColor, removeAt }
local testMode = false
local placePending = false
local scroll = 0
local refresh

-- Every chat line ThreatWallForever prints gets a stable numeric code, so you can
-- report "003" instead of retyping the whole sentence.
local CODES = {
  SPOTTED = '001',       -- debug: new problem enemy found
  WORSENED = '002',      -- debug: an enemy's state got worse
  CLEARED = '003',       -- debug: a row was removed after its grace period
  NO_NAMEPLATES = '004', -- /threatwall debug: nothing visible to check
  NO_THREAT_API = '005', -- this client build has no threat API at all
  LOCKED_HINT = '006',   -- tried to drag the window while it is locked
  LOCKED_ON = '007',
  LOCKED_OFF = '008',
  ROLE_SET = '009',
  LOG_CLEARED = '010',
  DEBUG_ON = '011',
  DEBUG_OFF = '012',
  LOADED = '013',
  HELP = '014',
  HINT_RESET = '015',
}

local function say(msg, codeKey)
  local tag = codeKey and ('[' .. CODES[codeKey] .. '] ') or ''
  DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. tag .. msg)
end

local function roleName()
  return db.role == 'tank' and L.ROLE_TANK or L.ROLE_DPS
end

local function getCVar(name)
  local ok, v = pcall(function()
    if C_CVar and C_CVar.GetCVar then return C_CVar.GetCVar(name) end
    return GetCVar(name)
  end)
  return ok and v or nil
end

-- Continuous, event-driven debug logging (same idea as CrittersBoard's
-- DEBUG_MODE): off by default, one settings checkbox, only prints when
-- something actually changes rather than spamming every tick.
--
-- Lines also go into ThreatWallForeverDB.log with a timestamp, capped to the last
-- MAX_LOG entries (oldest dropped first). This client cannot write a file
-- directly - SavedVariables is the only way an addon's data reaches disk,
-- and the game only writes it out on /reload, logout, or addon disable.
local MAX_LOG = 100

local function dbg(codeKey, msg)
  if not (db and db.debug) then return end
  local line = '[' .. CODES[codeKey] .. '] ' .. msg
  say('|cff888888[debug]|r ' .. line)
  db.log = db.log or {}
  table.insert(db.log, { time = date('%H:%M:%S'), msg = line })
  while #db.log > MAX_LOG do
    table.remove(db.log, 1)
  end
end

-- Detection ---------------------------------------------------------------------

-- True when a nameplate unit is a hostile, living enemy currently fighting
-- you, a group member, or one of their pets.
-- These are plain yes/no gates, not numbers we compare or add up, so a
-- "secret" boolean is used as-is (Lua's `if` only needs truthiness, not a
-- real comparison). Only the actual threat numbers below need the
-- secret-aware handling.
local function engaged(unit)
  local ok, exists = pcall(UnitExists, unit)
  if not ok or not exists then return false end
  local okH, hostile = pcall(function()
    return UnitCanAttack('player', unit) and not UnitIsDead(unit)
  end)
  if not okH or not hostile then return false end

  local okC, inCombat = pcall(UnitAffectingCombat, unit)
  if okC and inCombat then return true end

  local mobTarget = unit .. 'target'
  local okE, hasTarget = pcall(UnitExists, mobTarget)
  if okE and hasTarget then
    local okF, friendly = pcall(function()
      return UnitPlayerControlled(mobTarget) and not UnitCanAttack('player', mobTarget)
    end)
    if okF and friendly then return true end
  end
  return false
end

-- Every unit whose CURRENT TARGET is worth checking as a possible enemy:
-- yourself, your pet, and (in a group) everyone else and their pets. This is
-- the main way enemies are found - it needs no nameplate at all, just the
-- normal "who is that unit targeting" chain, so it works the same whether
-- or not enemy nameplates are shown. Nameplates are only a bonus source for
-- enemies nobody currently has targeted.
local function candidateUnits()
  local list = { 'target', 'pettarget' }
  if IsInRaid() then
    local okN, n = pcall(GetNumGroupMembers)
    n = (okN and not IsSecret(n)) and n or 0
    for i = 1, n do
      list[#list + 1] = 'raid' .. i .. 'target'
      list[#list + 1] = 'raidpet' .. i .. 'target'
    end
  elseif IsInGroup() then
    local okN, n = pcall(GetNumSubgroupMembers)
    n = (okN and not IsSecret(n)) and n or 0
    for i = 1, n do
      list[#list + 1] = 'party' .. i .. 'target'
      list[#list + 1] = 'partypet' .. i .. 'target'
    end
  end
  for i = 1, 40 do list[#list + 1] = 'nameplate' .. i end
  return list
end

-- Your own threat status on one enemy, read defensively: this client can hide
-- any of these values in combat, and a hidden value is treated as unknown
-- rather than guessed at.
local function myStatus(unit)
  local ok, tanking, status = pcall(UnitDetailedThreatSituation, 'player', unit)
  if not ok then return nil, nil end
  tanking = plain(tanking)
  status = plain(status)
  if tanking == nil and status == nil then
    -- Fall back to the plainer API before giving up.
    local ok2, st2 = pcall(UnitThreatSituation, 'player', unit)
    if ok2 then status = plain(st2) end
  end
  return tanking, status
end

-- Tank mode: the problem is losing your grip. DD/Heal mode: the problem is
-- taking too much of it. Both read the same status number, just flipped.
local function classify(tanking, status)
  if db.role == 'tank' then
    if status == 3 then return 'green' end
    if status == 2 then return 'yellow' end
    return 'red' -- 0, 1, or unreadable: you have little or no grip on it
  else
    if tanking or status == 3 or status == 2 then return 'red' end
    if status == 1 then return 'yellow' end
    return 'green'
  end
end

local function worse(a, b)
  return (RANK[a] or 0) > (RANK[b] or 0)
end

local function playAlert()
  if db.sound then pcall(PlaySound, 8959, 'Master') end
end

-- Scans nameplates, updates the tracked table, and returns nothing: the
-- tracked table itself is what refresh() draws from.
local function collect()
  local now = GetTime()
  local seen = {}

  for _, unit in ipairs(candidateUnits()) do
    if engaged(unit) then
      local okG, guid = pcall(UnitGUID, unit)
      if okG and IsSecret(guid) then guid = nil end
      -- GUID is the normal tracking key. It can also come back nil or
      -- "secret" itself - confirmed live in a group dungeon pull, a further
      -- case of this client hiding info in combat - so fall back to the
      -- unit token as the key when that happens. A token-keyed row can end
      -- up briefly duplicated if a nameplate gets reassigned to a different
      -- enemy mid-fight (the known nameplate-token instability), but it
      -- still ages out normally via the grace period below once it stops
      -- appearing, so that's a short cosmetic flicker at worst - much better
      -- than not tracking the enemy at all.
      local key = (okG and guid) or unit
      -- Several tokens (your target, a nameplate, a party member's target...)
      -- can all point at the same enemy. Only the first one this tick gets to
      -- speak for it, so a later, less complete read never overwrites a good
      -- one - candidateUnits() puts your own `target` first for exactly this.
      if not seen[key] then
        local tanking, status = myStatus(unit)
        if tanking ~= nil or status ~= nil then
          local color = classify(tanking, status)
          local t = tracked[key]
          local isNew = not t
          if not t then
            t = {}
            tracked[key] = t
          end
          if db and db.debug and t.unit and t.unit ~= unit then
            say('|cff888888[debug]|r unit token changed ' .. tostring(t.unit) .. ' -> ' .. tostring(unit)
              .. ' for ' .. tostring(not IsSecret(t.name) and t.name or key))
          end
          t.unit = unit
          local okN, name = pcall(UnitName, unit)
          -- A secret name can still be handed straight to SetText; it just
          -- cannot be compared or joined with other strings.
          t.name = okN and name or nil
          local okM, idx = pcall(GetRaidTargetIndex, unit)
          t.markIndex = okM and idx or nil
          seen[key] = true

          if isNew then
            dbg('SPOTTED', (not IsSecret(t.name) and t.name or unit) .. ' spotted, tanking='
              .. tostring(tanking) .. ' status=' .. tostring(status) .. ' -> ' .. color)
          end

          if not db.showAll and color == 'green' then
            -- Normal mode: a resolved problem gets a short grace period,
            -- then drops off the list entirely - it's not tracked further.
            if t.shownColor then t.removeAt = t.removeAt or (now + GRACE) end
          else
            -- Show-all mode: every engaged enemy (including green ones)
            -- stays shown until it actually leaves candidateUnits() below.
            -- Only a worsening red/yellow triggers the alert - turning
            -- green is good news, not something to sound off about.
            if color ~= 'green' and worse(color, t.shownColor) then
              if not isNew then
                dbg('WORSENED', (not IsSecret(t.name) and t.name or unit) .. ' worsened '
                  .. tostring(t.shownColor) .. ' -> ' .. color)
              end
              playAlert()
            end
            t.shownColor = color
            t.removeAt = nil
          end
        end
      end
    end
  end

  for key, t in pairs(tracked) do
    if not seen[key] then
      if t.shownColor then
        t.removeAt = t.removeAt or (now + GRACE)
      else
        tracked[key] = nil
      end
    end
  end
  for key, t in pairs(tracked) do
    if t.removeAt and now >= t.removeAt then
      -- Quieter than SPOTTED/WORSENED on purpose: a row clearing is routine
      -- and can happen a lot (e.g. switching targets), so it only goes to
      -- the log file, not the chat window.
      if db and db.debug then
        db.log = db.log or {}
        table.insert(db.log, { time = date('%H:%M:%S'),
          msg = '[' .. CODES.CLEARED .. '] ' .. (not IsSecret(t.name) and t.name or key) .. ' cleared, was ' .. tostring(t.shownColor) })
        while #db.log > MAX_LOG do table.remove(db.log, 1) end
      end
      tracked[key] = nil
    end
  end
end

local TEST = {
  { 'Grillmaster', 'red', 8 },
  { 'Adds Rechts', 'yellow', 3 },
  { 'Adds Links', 'yellow', nil },
}

-- Drawing -------------------------------------------------------------------

local function setDot(tex, colorName)
  local c = COLOR[colorName] or COLOR.yellow
  tex:SetVertexColor(c[1], c[2], c[3])
end

-- ===========================================================================
-- Raid-target-marker rendering: THREE interchangeable ways to try it.
--
-- On this client (WoW Forever, still in beta as of 2026-09), the mark index
-- comes back "secret" during combat - exactly when it would matter here -
-- and all three known ways to turn that into a texture fail, each a
-- different way. None currently draws anything, but the attempt is safe
-- (wrapped in pcall) and costs nothing, so all three stay in, switchable
-- from the settings menu ("Marker method"), for whenever a Forever client
-- update changes this. Once one of them actually draws something in a real
-- fight, delete this whole block's other two variants, the MARK_METHODS /
-- MARK_METHOD_NAMES entries for them, and the "Marker method" menu line -
-- keep only the one that works, called directly as `setMark`.
-- ===========================================================================

-- VARIANT 1 - manual coordinate math on the raid-icon sprite sheet. The
-- standard, most common way addons do this. Status: throws, because the
-- math itself (index - 1, etc.) needs a plain number, not a secret one.
local function setMark_Manual(tex, index)
  return pcall(function()
    tex:SetTexture(RAID_ICONS_ATLAS)
    local col = (index - 1) % 4
    local row = math.floor((index - 1) / 4)
    tex:SetTexCoord(col * 0.25, col * 0.25 + 0.25, row * 0.5, row * 0.5 + 0.5)
  end)
end

-- VARIANT 2 - Blizzard's own SetRaidTargetIconTexture helper, which does the
-- exact same coordinate math but inside Blizzard's own trusted code, not
-- ours. Status: does not throw, but also does not draw anything - it
-- quietly declines once the index is secret.
local function setMark_Blizzard(tex, index)
  return pcall(SetRaidTargetIconTexture, tex, index)
end

-- VARIANT 3 - individual per-icon texture files, picked by file name instead
-- of by sprite-sheet math. Status: tostring() on a secret index is allowed
-- (the debug chat lines prove that), but handing the resulting string to
-- SetTexture is not - it is still treated as secret-derived and refused.
local function setMark_IconFiles(tex, index)
  return pcall(function()
    tex:SetTexture('Interface\\TargetingFrame\\UI-RaidTargetingIcon_' .. tostring(index))
    tex:SetTexCoord(0, 1, 0, 1)
  end)
end

local MARK_METHODS = { setMark_Manual, setMark_Blizzard, setMark_IconFiles }
local MARK_METHOD_NAMES = { 'Manual math', 'Blizzard API', 'Icon files' }

local function setMark(tex, index)
  if not index then
    tex:Hide()
    return
  end
  local fn = MARK_METHODS[db.markMethod] or MARK_METHODS[1]
  local ok = fn(tex, index)
  if ok then tex:Show() else tex:Hide() end
end

local function rowTooltip(row)
  local e = row.entry
  if not e then return end
  GameTooltip:SetOwner(row, 'ANCHOR_RIGHT')
  pcall(GameTooltip.AddLine, GameTooltip, e.name or '?')
  if db.role == 'tank' then
    if e.color == 'red' then
      GameTooltip:AddLine(L.TT_TANK_RED, 1, 0.3, 0.3)
    elseif e.color == 'yellow' then
      GameTooltip:AddLine(L.TT_TANK_YELLOW, 1, 0.8, 0.2)
    else
      GameTooltip:AddLine(L.TT_TANK_GREEN, 0.3, 1, 0.3)
    end
  else
    if e.color == 'red' then
      GameTooltip:AddLine(L.TT_DPS_RED, 1, 0.3, 0.3)
    elseif e.color == 'yellow' then
      GameTooltip:AddLine(L.TT_DPS_YELLOW, 1, 0.8, 0.2)
    else
      GameTooltip:AddLine(L.TT_DPS_GREEN, 0.3, 1, 0.3)
    end
  end
  -- L.TT_CLICK ("Click to target it") left out on purpose for now: clicking
  -- does not do anything currently (see the file header comment), and a
  -- tooltip promising it would just be misleading.
  GameTooltip:Show()
end

-- Row building --------------------------------------------------------------
--
-- Plain, non-secure buttons - display and tooltip only, no click-to-target
-- for now (see the file header comment for why: a client-side bug in this
-- WoW Forever beta build, confirmed live and by a tracked external bug
-- report, breaks SecureActionButtonTemplate entirely, for every addon).
-- Pooled by row position, exactly like a normal dynamic list - rebuilt and
-- repositioned every refresh() tick, since none of that is restricted for a
-- plain (non-secure) frame, in or out of combat.

local function buildRow(i)
  local row = CreateFrame('Button', nil, frame.body)
  row:EnableMouse(true)
  row:SetScript('OnEnter', function(self) rowTooltip(self) end)
  row:SetScript('OnLeave', function() GameTooltip:Hide() end)

  row.bg = row:CreateTexture(nil, 'BACKGROUND')
  row.bg:SetAllPoints()
  row.bg:SetTexture(FLAT)
  row.bg:SetVertexColor(1, 1, 1, 0.05)

  row.dot = row:CreateTexture(nil, 'ARTWORK')
  row.dot:SetSize(12, 12)
  row.dot:SetPoint('LEFT', 6, 0)
  row.dot:SetTexture(FLAT)
  if row.CreateMaskTexture then
    local mask = row:CreateMaskTexture()
    mask:SetTexture('Interface\\CharacterFrame\\TempPortraitAlphaMask', 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
    mask:SetAllPoints(row.dot)
    row.dot:AddMaskTexture(mask)
  end

  row.mark = row:CreateTexture(nil, 'ARTWORK')
  row.mark:SetSize(14, 14)
  row.mark:SetPoint('LEFT', row.dot, 'RIGHT', 4, 0)

  row.name = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  row.name:SetPoint('LEFT', row.mark, 'RIGHT', 4, 0)
  row.name:SetPoint('RIGHT', -6, 0)
  row.name:SetJustifyH('LEFT')
  row.name:SetWordWrap(false)

  rows[i] = row
  return row
end

local function layoutRow(row, i)
  local h = db.rowHeight
  row:ClearAllPoints()
  row:SetHeight(h)
  row:SetPoint('TOPLEFT', frame, 'TOPLEFT', 4, -(HEADER_H + 4 + (i - 1) * (h + 2)))
  row:SetPoint('RIGHT', frame, 'RIGHT', -4, 0)
  if row.name.SetTextScale then row.name:SetTextScale(db.textScale) end
end

local function drawRow(row, e)
  row.entry = e
  setDot(row.dot, e.color)
  setMark(row.mark, e.markIndex)
  if not pcall(row.name.SetText, row.name, e.name or '?') then row.name:SetText('?') end
  row:Show()
end

local function visibleRows()
  local space = frame:GetHeight() - HEADER_H - 8
  local n = math.floor(space / (db.rowHeight + 2))
  if n < 1 then n = 1 end
  if n > MAX_ROWS then n = MAX_ROWS end
  return n
end

refresh = function()
  if not frame then return end

  if testMode then
    -- leave `tracked` alone; draw straight from TEST below
  else
    collect()
  end

  local hide = not db.shown
  if not testMode and not frame.moving then
    if db.combatOnly and not UnitAffectingCombat('player') then hide = true end
    if db.groupOnly and not IsInGroup() and not IsInRaid() then hide = true end
  end
  if hide then frame:Hide() return end
  frame:Show()

  local list = {}
  if testMode then
    for _, t in ipairs(TEST) do
      list[#list + 1] = { name = t[1], color = t[2], markIndex = t[3] }
    end
  else
    for _, t in pairs(tracked) do
      if t.shownColor then
        list[#list + 1] = { name = t.name, color = t.shownColor, markIndex = t.markIndex }
      end
    end
    table.sort(list, function(a, b)
      if a.color ~= b.color then return worse(a.color, b.color) end
      -- Sorting compares strings, which this client will not allow on a
      -- secret name, so a secret name just keeps whatever order it lands in.
      if IsSecret(a.name) or IsSecret(b.name) then return false end
      return (a.name or '') < (b.name or '')
    end)
  end

  subText:SetText(#list > 0 and tostring(#list) or '')

  local max = visibleRows()
  local shown = math.min(#list, max)
  for i = 1, shown do
    local row = rows[i] or buildRow(i)
    if not row.laidOut then layoutRow(row, i) row.laidOut = true end
    drawRow(row, list[i])
  end
  for i = shown + 1, #rows do
    rows[i].entry = nil
    rows[i]:Hide()
  end

  frame.empty:SetText(#list == 0 and (testMode and '' or L.EMPTY) or '')
end

-- Window ----------------------------------------------------------------------

local function num(v)
  return type(v) == 'number' and not IsSecret(v)
end

local function placeFrame()
  if not (num(db.left) and num(db.top)) then return false end
  local scale = db.scale or 1
  frame:ClearAllPoints()
  frame:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', db.left / scale, db.top / scale)
  return true
end

local function savePlace()
  local left, top, w, h = frame:GetLeft(), frame:GetTop(), frame:GetWidth(), frame:GetHeight()
  if not (num(left) and num(top)) then
    placePending = true
    return
  end
  placePending = false
  local scale = frame:GetScale()
  if not num(scale) then scale = db.scale or 1 end
  db.left, db.top = left * scale, top * scale
  if num(w) and num(h) then db.width, db.height = w, h end
  placeFrame()
end

local lockHintAt = 0
local function startMove(_, button)
  if button and button ~= 'LeftButton' then return end
  if db.locked then
    if GetTime() - lockHintAt > 10 then
      lockHintAt = GetTime()
      say(L.LOCKED_HINT, 'LOCKED_HINT')
    end
    return
  end
  frame.moving = true
  frame:StartMoving()
end

local function stopMove()
  if not frame.moving then return end
  frame:StopMovingOrSizing()
  if frame.SetUserPlaced then pcall(frame.SetUserPlaced, frame, true) end
  frame.moving = false
  savePlace()
  refresh()
end

local function updateRoleLook()
  if roleBtn.setArt then roleBtn.setArt() end
  if db.role == 'tank' then
    titleText:SetText(L.TITLE_TANK .. ' ' .. VERSION)
  else
    titleText:SetText(L.TITLE_DPS .. ' ' .. VERSION)
  end
end

local function applyLook()
  frame:SetScale(db.scale)
  placeFrame()
  frame.bg:SetAlpha(db.alpha)
  frame.body:SetShown(not db.minimized)
  updateRoleLook()
  if db.locked or db.minimized then grip:Hide() else grip:Show() end
  for i, row in ipairs(rows) do layoutRow(row, i) end
end

local function updateMinimap()
  if not mm then return end
  if db.minimap then
    local a = math.rad(db.minimapAngle)
    local r = Minimap:GetWidth() / 2 + 8
    mm:ClearAllPoints()
    mm:SetPoint('CENTER', Minimap, 'CENTER', math.cos(a) * r, math.sin(a) * r)
    mm:Show()
  else
    mm:Hide()
  end
end

-- Small homemade dropdown, same trick as other Forever addons use: the
-- built-in dropdown widgets are not consistent across this client's builds.
local menu, catcher
local menuLines = {}

local function backdrop(f, alpha)
  if not f.SetBackdrop then return end
  f:SetBackdrop({
    bgFile = FLAT, edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border',
    edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 },
  })
  f:SetBackdropColor(0, 0, 0, alpha)
  f:SetBackdropBorderColor(0.45, 0.45, 0.5, 1)
end

-- One-time heads-up about enemy nameplates -------------------------------------
--
-- Without them, this addon can only find an enemy while you or a group
-- member currently has it targeted (see candidateUnits() above) - it drops
-- off the list the moment the target changes. A custom popup is used here
-- for the same reason the dropdown menu is homemade: Blizzard's own popup
-- templates are not reliable across this client's builds, and this one also
-- needs a checkbox, which the standard StaticPopup does not support well
-- everywhere.

local hintPopup

local function openNameplateSettings()
  local done = false
  if Settings and Settings.OpenToCategory then
    done = pcall(Settings.OpenToCategory, 'Names') and true or false
  end
  if not done and InterfaceOptionsFrame_OpenToCategory then
    -- Known Blizzard quirk on the older options frame: the first call can
    -- open the window without rendering the right page, the second fixes it.
    pcall(InterfaceOptionsFrame_OpenToCategory, 'Names')
    done = pcall(InterfaceOptionsFrame_OpenToCategory, 'Names') and true or false
  end
  if not done then
    pcall(function()
      if SettingsPanel then ShowUIPanel(SettingsPanel)
      elseif InterfaceOptionsFrame then ShowUIPanel(InterfaceOptionsFrame) end
    end)
  end
end

local function buildHintPopup()
  -- Same frame chrome as CrittersBoard's patch-notes popup (a proven
  -- template on this client), rather than a homemade backdrop: a plain
  -- Blizzard dialog frame with a title bar and its own close (X) button.
  hintPopup = CreateFrame('Frame', 'ThreatWallForeverHintPopup', UIParent, 'BasicFrameTemplateWithInset')
  hintPopup:SetSize(460, 230)
  hintPopup:SetPoint('CENTER', UIParent, 'CENTER', 0, 100)
  hintPopup:SetFrameStrata('DIALOG')
  hintPopup:SetToplevel(true)
  hintPopup:EnableMouse(true)
  hintPopup:Hide()
  if UISpecialFrames then table.insert(UISpecialFrames, 'ThreatWallForeverHintPopup') end

  -- Not trusting the template's own TitleText child to exist under that
  -- exact name on this client - CrittersBoard's patch-notes popup avoids it
  -- the same way, with its own FontString instead. Anchored left+right
  -- (not a fixed width) so it wraps within the frame instead of overflowing.
  -- A single TOP anchor plus an explicit width, not a TOPLEFT+TOPRIGHT pair:
  -- on this client, centering inside a dual-anchor box without a set width
  -- did not actually center - the text rendered flush left instead.
  -- GameFontNormalLarge was too tall for the template's thin header strip
  -- and spilled down into the inset panel below it - a smaller font fits.
  local title = hintPopup:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
  title:SetPoint('TOP', hintPopup, 'TOP', 0, -7)
  title:SetWidth(460 - 80)
  title:SetJustifyH('CENTER')
  title:SetWordWrap(true)
  title:SetText(L.HINT_TITLE)

  local body = hintPopup:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  body:SetPoint('TOPLEFT', 16, -40)
  body:SetPoint('TOPRIGHT', -16, -40)
  body:SetJustifyH('LEFT')
  body:SetJustifyV('TOP')
  if body.SetSpacing then body:SetSpacing(3) end
  body:SetText(L.HINT_BODY)

  -- One bottom row: checkbox on the left, both buttons on the right. The
  -- shorter "Nicht mehr anzeigen"/"Don't show again" wording and the wider
  -- 460px window leave enough room for all three side by side.
  local ok = CreateFrame('Button', nil, hintPopup, 'UIPanelButtonTemplate')
  ok:SetSize(80, 22)
  ok:SetPoint('BOTTOMRIGHT', -16, 16)
  ok:SetText(L.HINT_OK)
  ok:SetScript('OnClick', function() hintPopup:Hide() end)

  local settingsBtn = CreateFrame('Button', nil, hintPopup, 'UIPanelButtonTemplate')
  settingsBtn:SetSize(150, 22)
  settingsBtn:SetPoint('RIGHT', ok, 'LEFT', -8, 0)
  settingsBtn:SetText(L.HINT_OPEN_SETTINGS)
  settingsBtn:SetScript('OnClick', openNameplateSettings)

  local check = CreateFrame('CheckButton', 'ThreatWallForeverHintCheck', hintPopup, 'UICheckButtonTemplate')
  check:SetSize(20, 20)
  check:SetPoint('BOTTOMLEFT', 16, 16)
  local label = _G[check:GetName() .. 'Text']
  if label then
    label:SetText(L.HINT_DONT_SHOW)
    label:SetFontObject('GameFontHighlightSmall')
  end
  check:SetScript('OnClick', function(self) db.hideNameplateHint = self:GetChecked() and true or false end)
  hintPopup.check = check
end

local function showHintPopup()
  if not hintPopup then buildHintPopup() end
  hintPopup.check:SetChecked(false)
  hintPopup:Show()
end

local nameplateChecked = false

local function checkNameplateSetting()
  if db.hideNameplateHint then return end
  if getCVar('nameplateShowEnemies') == '0' then
    showHintPopup()
  end
end

local function buildMenu()
  catcher = CreateFrame('Button', nil, UIParent)
  catcher:SetAllPoints(UIParent)
  catcher:SetFrameStrata('FULLSCREEN')
  catcher:RegisterForClicks('AnyUp')
  catcher:SetScript('OnClick', function() menu:Hide() end)
  catcher:Hide()

  menu = CreateFrame('Frame', 'ThreatWallForeverMenu', UIParent, BackdropTemplateMixin and 'BackdropTemplate' or nil)
  menu:SetFrameStrata('FULLSCREEN_DIALOG')
  menu:SetClampedToScreen(true)
  backdrop(menu, 0.92)
  menu:SetScript('OnHide', function() catcher:Hide() end)
  menu:Hide()
  if UISpecialFrames then table.insert(UISpecialFrames, 'ThreatWallForeverMenu') end
end

local function menuLine(i)
  local line = menuLines[i]
  if line then return line end
  line = CreateFrame('Button', nil, menu)
  line:SetHeight(18)
  line:SetPoint('TOPLEFT', 8, -8 - (i - 1) * 18)
  line:SetPoint('RIGHT', -8, 0)
  line.check = line:CreateTexture(nil, 'ARTWORK')
  line.check:SetTexture('Interface\\Buttons\\UI-CheckBox-Check')
  line.check:SetSize(16, 16)
  line.check:SetPoint('LEFT')
  line.text = line:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  line.text:SetPoint('LEFT', 20, 0)
  local hl = line:CreateTexture(nil, 'HIGHLIGHT')
  hl:SetAllPoints()
  hl:SetTexture(FLAT)
  hl:SetVertexColor(1, 1, 1, 0.12)
  menuLines[i] = line
  return line
end

local function showMenu(anchor, items)
  if not menu then buildMenu() end
  if menu:IsShown() and menu.anchor == anchor then menu:Hide() return end
  menu.anchor = anchor

  local function fill()
    local width = 140
    for i, item in ipairs(items) do
      local line = menuLine(i)
      local text = type(item.text) == 'function' and item.text() or item.text
      line.text:SetText(text)
      if item.title then
        line.text:SetTextColor(1, 0.82, 0)
        line:Disable()
      else
        line.text:SetTextColor(1, 1, 1)
        line:Enable()
      end
      if item.checked and item.checked() then line.check:Show() else line.check:Hide() end
      line:SetScript('OnClick', function()
        item.click()
        if item.close then menu:Hide() else fill() end
      end)
      line:Show()
      local w = line.text:GetStringWidth() + 44
      if w > width then width = w end
    end
    for i = #items + 1, #menuLines do menuLines[i]:Hide() end
    menu:SetSize(width, #items * 18 + 16)
  end

  fill()
  menu:ClearAllPoints()
  menu:SetPoint('TOPLEFT', anchor, 'BOTTOMLEFT', 0, -2)
  catcher:Show()
  menu:Show()
end

local function toggle(key)
  return function() db[key] = not db[key] applyLook() updateMinimap() refresh() end
end
local function checked(key)
  return function() return db[key] end
end
local function cycle(key, values)
  local at = 1
  for i, v in ipairs(values) do if db[key] == v then at = i break end end
  db[key] = values[at % #values + 1]
end
local function cycler(label, key, values, suffix, mult)
  return {
    text = function() return label .. ': ' .. math.floor(db[key] * (mult or 1) + 0.5) .. (suffix or '') end,
    click = function() cycle(key, values) applyLook() refresh() end,
  }
end

local function toggleDebug()
  db.debug = not db.debug
  say(db.debug and L.DEBUG_ON or L.DEBUG_OFF, db.debug and 'DEBUG_ON' or 'DEBUG_OFF')
  applyLook()
  updateMinimap()
  refresh()
end

local function cycleMarkMethod()
  db.markMethod = (db.markMethod % #MARK_METHOD_NAMES) + 1
  refresh()
end

local function toggleRole()
  db.role = (db.role == 'tank') and 'dps' or 'tank'
  applyLook()
  refresh()
end

local function resetPlace()
  frame:ClearAllPoints()
  frame:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
  frame:SetSize(DEFAULTS.width, DEFAULTS.height)
  db.shown = true
  savePlace()
  refresh()
end

local SETTINGS = {
  { text = function() return L.MENU_TITLE end, title = true, click = function() end },
  { text = function() return string.format(L.MENU_ROLE, roleName()) end, click = toggleRole },
  { text = function() return L.MENU_LOCK end, checked = checked('locked'), click = toggle('locked') },
  { text = function() return L.MENU_COMBAT_ONLY end, checked = checked('combatOnly'), click = toggle('combatOnly') },
  { text = function() return L.MENU_GROUP_ONLY end, checked = checked('groupOnly'), click = toggle('groupOnly') },
  { text = function() return L.MENU_SHOW_ALL end, checked = checked('showAll'), click = toggle('showAll') },
  { text = function() return L.MENU_SOUND end, checked = checked('sound'), click = toggle('sound') },
  { text = function() return L.MENU_DEBUG end, checked = checked('debug'), click = toggleDebug },
  cycler(L.MENU_BACKGROUND, 'alpha', { 0, 0.2, 0.4, 0.6, 0.8, 1 }, '%', 100),
  cycler(L.MENU_SCALE, 'scale', { 0.8, 0.9, 1, 1.1, 1.25, 1.5 }, '%', 100),
  { text = function() return L.MENU_MINIMAP end, checked = checked('minimap'), click = toggle('minimap') },
  { text = function() return L.MENU_TEST end, checked = function() return testMode end,
    click = function() testMode = not testMode db.shown = true refresh() end },
  { text = function() return L.MENU_RESET end, click = resetPlace, close = true },
}

local function buildFrame()
  frame = frame or CreateFrame('Frame', 'ThreatWallForeverFrame', UIParent)
  local restored = frame:GetNumPoints() > 0
  if placeFrame() then
    frame:SetSize(db.width, db.height)
  elseif not restored then
    frame:SetSize(db.width, db.height)
    frame:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
    placePending = true
  else
    placePending = true
  end
  frame:SetFrameStrata('MEDIUM')
  frame:SetClampedToScreen(true)
  frame:SetMovable(true)
  if frame.SetUserPlaced then pcall(frame.SetUserPlaced, frame, true) end
  frame:SetResizable(true)
  frame:EnableMouse(true)
  if frame.SetResizeBounds then
    frame:SetResizeBounds(160, 90, 500, 400)
  elseif frame.SetMinResize then
    frame:SetMinResize(160, 90)
    frame:SetMaxResize(500, 400)
  end

  frame:SetScript('OnMouseDown', startMove)
  frame:SetScript('OnMouseUp', stopMove)
  frame:SetScript('OnHide', stopMove)

  frame.body = CreateFrame('Frame', nil, frame)
  frame.body:SetAllPoints()

  frame.bg = frame.body:CreateTexture(nil, 'BACKGROUND')
  frame.bg:SetAllPoints()
  if not setAtlas(frame.bg, 'damagemeters-background') then
    frame.bg:SetColorTexture(0, 0, 0, 1)
  end

  frame.empty = frame.body:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
  frame.empty:SetPoint('TOPLEFT', 10, -HEADER_H - 6)
  frame.empty:SetPoint('BOTTOMRIGHT', -10, 6)
  frame.empty:SetJustifyH('CENTER')
  frame.empty:SetJustifyV('TOP')
  frame.empty:SetTextColor(0.55, 0.55, 0.55)

  header = CreateFrame('Frame', nil, frame)
  header:SetPoint('TOPLEFT')
  header:SetPoint('TOPRIGHT')
  header:SetHeight(HEADER_H)
  header:EnableMouse(true)
  header:SetScript('OnMouseDown', startMove)
  header:SetScript('OnMouseUp', stopMove)
  header.bg = header:CreateTexture(nil, 'BACKGROUND', nil, 1)
  header.bg:SetAllPoints()
  if not setAtlas(header.bg, 'ui-damagemeters-header-bar', FLAT) then
    header.bg:SetColorTexture(0.12, 0.12, 0.14, 0.95)
  end

  -- All three header buttons share one size and one vertical anchor point
  -- (RIGHT, chained to each other) so they line up exactly instead of each
  -- keeping its own native art size.
  local HEADER_BTN_SIZE = 22
  minimize = CreateFrame('Button', nil, header)
  minimize:SetSize(HEADER_BTN_SIZE, HEADER_BTN_SIZE)
  minimize:SetPoint('RIGHT', header, 'RIGHT', -6, 0)
  local function setMinimizeArt()
    local kind = db.minimized and 'expand' or 'collapse'
    if hasAtlas('ui-questtrackerbutton-' .. kind .. '-all') then
      minimize:SetNormalAtlas('ui-questtrackerbutton-' .. kind .. '-all')
      minimize:SetPushedAtlas('ui-questtrackerbutton-' .. kind .. '-all-pressed')
      minimize:SetHighlightAtlas('ui-questtrackerbutton-red-highlight', 'ADD')
    else
      local art = db.minimized and 'Interface\\Buttons\\UI-PlusButton' or 'Interface\\Buttons\\UI-MinusButton'
      minimize:SetNormalTexture(art .. '-Up')
      minimize:SetPushedTexture(art .. '-Down')
      minimize:SetHighlightTexture('Interface\\Buttons\\UI-PlusButton-Hilight', 'ADD')
    end
  end
  minimize:SetScript('OnClick', function()
    db.minimized = not db.minimized
    setMinimizeArt()
    applyLook()
    refresh()
  end)
  setMinimizeArt()

  gear = CreateFrame('Button', nil, header)
  -- This atlas has more empty padding baked around the gear glyph than the
  -- role icons do around theirs, so it needs a bit more than the shared
  -- size to look the same on-screen.
  gear:SetSize(HEADER_BTN_SIZE + 6, HEADER_BTN_SIZE + 6)
  gear:SetPoint('RIGHT', minimize, 'LEFT', -4, 0)
  if hasAtlas('common-dropdown-a-button-settings-shadowless') then
    gear:SetNormalAtlas('common-dropdown-a-button-settings-shadowless')
    gear:SetPushedAtlas('common-dropdown-a-button-settings-pressed-shadowless')
    gear:SetHighlightAtlas('common-dropdown-a-button-settings-hover-shadowless')
  else
    gear:SetNormalTexture('Interface\\Buttons\\UI-OptionsButton')
    gear:SetHighlightTexture('Interface\\Buttons\\UI-OptionsButton', 'ADD')
  end
  gear:SetScript('OnClick', function(self) showMenu(self, SETTINGS) end)

  -- Role toggle: gear and minimize are complete baked icon+border graphics,
  -- which a hand-built border can only approximate, not match. Try the
  -- matching Blizzard role-icon atlases first (same bordered-square family,
  -- used for tank/dps in the group finder) - if this client has them, the
  -- style is identical by construction, not by approximation. Falls back to
  -- the plain bordered letter if it does not.
  roleBtn = CreateFrame('Button', nil, header, BackdropTemplateMixin and 'BackdropTemplate' or nil)
  roleBtn:SetSize(HEADER_BTN_SIZE, HEADER_BTN_SIZE)
  roleBtn:SetPoint('RIGHT', gear, 'LEFT', -4, 0)

  roleBtn.icon = roleBtn:CreateTexture(nil, 'ARTWORK')
  roleBtn.icon:SetAllPoints()

  roleBtn.text = roleBtn:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
  roleBtn.text:SetAllPoints()
  roleBtn.text:SetJustifyH('CENTER')
  roleBtn.text:SetJustifyV('MIDDLE')

  local roleHL = roleBtn:CreateTexture(nil, 'HIGHLIGHT')
  roleHL:SetAllPoints()
  roleHL:SetTexture(FLAT)
  roleHL:SetVertexColor(1, 1, 1, 0.15)

  local ROLE_ATLAS = { tank = 'groupfinder-icon-role-large-tank', dps = 'groupfinder-icon-role-large-dps' }
  local function setRoleArt()
    local atlas = ROLE_ATLAS[db.role]
    if atlas and hasAtlas(atlas) then
      roleBtn.icon:Show()
      roleBtn.icon:SetAtlas(atlas, false)
      roleBtn.text:Hide()
      roleBtn:SetBackdrop(nil)
    else
      roleBtn.icon:Hide()
      roleBtn.text:Show()
      roleBtn.text:SetText(db.role == 'tank' and 'T' or 'D')
      backdrop(roleBtn, 0.6)
    end
  end
  roleBtn.setArt = setRoleArt
  setRoleArt()

  roleBtn:SetScript('OnClick', toggleRole)
  roleBtn:SetScript('OnEnter', function(self)
    GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
    GameTooltip:AddLine(L.TT_ROLE_TITLE)
    GameTooltip:AddLine(L.TT_ROLE_TANK, 1, 1, 1)
    GameTooltip:AddLine(L.TT_ROLE_DPS, 1, 1, 1)
    GameTooltip:Show()
  end)
  roleBtn:SetScript('OnLeave', function() GameTooltip:Hide() end)

  subText = header:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  subText:SetPoint('RIGHT', roleBtn, 'LEFT', -6, 0)
  subText:SetTextColor(1, 1, 1)

  titleText = header:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
  titleText:SetPoint('LEFT', 16, 0)
  titleText:SetPoint('RIGHT', subText, 'LEFT', -6, 0)
  titleText:SetJustifyH('LEFT')
  titleText:SetWordWrap(false)
  titleText:SetTextColor(1, 0.82, 0)

  grip = CreateFrame('Button', nil, frame.body)
  grip:SetFrameLevel(frame:GetFrameLevel() + 10)
  if hasAtlas('damagemeters-scalehandle') then
    grip:SetSize(50, 50)
    grip:SetPoint('BOTTOMRIGHT', 9, -8)
    grip:SetNormalAtlas('damagemeters-scalehandle')
    grip:SetHighlightAtlas('damagemeters-scalehandle-hover')
    grip:SetPushedAtlas('damagemeters-scalehandle-pressed')
    grip:SetHitRectInsets(25, 9, 25, 8)
  else
    grip:SetSize(16, 16)
    grip:SetPoint('BOTTOMRIGHT', -1, 1)
    grip:SetNormalTexture('Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up')
    grip:SetHighlightTexture('Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight')
    grip:SetPushedTexture('Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down')
  end
  grip:SetAlpha(0)
  grip:SetScript('OnMouseDown', function()
    frame.moving = true
    frame:StartSizing('BOTTOMRIGHT')
  end)
  grip:SetScript('OnMouseUp', stopMove)
  frame:SetScript('OnSizeChanged', function() if frame.moving then refresh() end end)

  local watcher = CreateFrame('Frame', nil, frame)
  watcher:Hide()
  watcher:SetScript('OnUpdate', function(self, elapsed)
    local over = frame:IsMouseOver() or grip:IsMouseOver() or frame.moving
    local alpha = grip:GetAlpha() + (over and elapsed or -elapsed) * 4
    if alpha >= 1 then alpha = 1 elseif alpha <= 0 then alpha = 0 end
    grip:SetAlpha(alpha)
    if not over and alpha == 0 then self:Hide() end
  end)
  local function hover() watcher:Show() end
  frame:SetScript('OnEnter', hover)
  grip:SetScript('OnEnter', hover)
  header:SetScript('OnEnter', hover)

  applyLook()
end

local function toggleWindow()
  db.shown = not db.shown
  refresh()
end

local function buildMinimapButton()
  mm = CreateFrame('Button', 'ThreatWallForeverMinimapButton', Minimap)
  mm:SetSize(31, 31)
  mm:SetFrameStrata('MEDIUM')
  mm:SetFrameLevel(8)
  mm:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
  mm:RegisterForDrag('LeftButton')
  mm:SetHighlightTexture('Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight')

  local back = mm:CreateTexture(nil, 'BACKGROUND')
  back:SetTexture('Interface\\Minimap\\UI-Minimap-Background')
  back:SetSize(20, 20)
  back:SetPoint('TOPLEFT', 7, -5)

  local icon = mm:CreateTexture(nil, 'ARTWORK')
  icon:SetTexture(ADDON_ICON)
  icon:SetSize(18, 18)
  icon:SetPoint('TOPLEFT', 7, -6)
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  if mm.CreateMaskTexture then
    local mask = mm:CreateMaskTexture()
    mask:SetTexture('Interface\\CharacterFrame\\TempPortraitAlphaMask', 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
    mask:SetAllPoints(icon)
    icon:AddMaskTexture(mask)
  end

  local ring = mm:CreateTexture(nil, 'OVERLAY')
  ring:SetTexture('Interface\\Minimap\\MiniMap-TrackingBorder')
  ring:SetSize(53, 53)
  ring:SetPoint('TOPLEFT')

  mm:SetScript('OnDragStart', function(self)
    self:SetScript('OnUpdate', function()
      local mx, my = Minimap:GetCenter()
      local cx, cy = GetCursorPosition()
      local s = Minimap:GetEffectiveScale()
      db.minimapAngle = math.deg(math.atan2(cy / s - my, cx / s - mx))
      updateMinimap()
    end)
  end)
  mm:SetScript('OnDragStop', function(self) self:SetScript('OnUpdate', nil) end)
  mm:SetScript('OnClick', function(self, button)
    if button == 'RightButton' then showMenu(self, SETTINGS) else toggleWindow() end
  end)
  mm:SetScript('OnEnter', function(self)
    GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
    GameTooltip:AddLine(L.MM_TITLE)
    GameTooltip:AddLine(L.MM_LEFT, 1, 1, 1)
    GameTooltip:AddLine(L.MM_RIGHT, 1, 1, 1)
    GameTooltip:AddLine(L.MM_DRAG, 1, 1, 1)
    GameTooltip:Show()
  end)
  mm:SetScript('OnLeave', function() GameTooltip:Hide() end)
  updateMinimap()
end

-- Slash -------------------------------------------------------------------------

local function slash(msg)
  local cmd, arg = (msg or ''):lower():match('^%s*(%S*)%s*(%S*)')
  if cmd == 'test' then
    testMode = not testMode
    db.shown = true
  elseif cmd == 'role' then
    toggleRole()
    say(string.format(L.ROLE_SET, roleName()), 'ROLE_SET')
  elseif cmd == 'lock' then
    db.locked = not db.locked
    say(db.locked and L.LOCKED_ON or L.LOCKED_OFF, db.locked and 'LOCKED_ON' or 'LOCKED_OFF')
  elseif cmd == 'reset' then
    resetPlace()
  elseif cmd == 'options' or cmd == 'config' then
    showMenu(frame:IsShown() and gear or mm, SETTINGS)
  elseif cmd == 'debug' then
    local any = false
    local shown = {}
    for _, unit in ipairs(candidateUnits()) do
      if UnitExists(unit) and not shown[unit] then
        shown[unit] = true
        any = true
        local okH, hostile = pcall(function() return UnitCanAttack('player', unit) and not UnitIsDead(unit) end)
        local okC, inCombat = pcall(UnitAffectingCombat, unit)
        local isEngaged = engaged(unit)
        local tanking, status = myStatus(unit)
        local okM, idx = pcall(GetRaidTargetIndex, unit)
        local markOk = idx ~= nil and pcall(SetRaidTargetIconTexture, UIParent:CreateTexture(), idx)
        local function show(v) return v == nil and 'nil' or tostring(v) end
        say(unit .. ' hostile=' .. show(okH and hostile) .. ' combat=' .. show(okC and inCombat)
          .. ' engaged=' .. tostring(isEngaged) .. ' tanking=' .. show(tanking) .. ' status=' .. show(status)
          .. ' mark=' .. show(okM and idx) .. ' markOk=' .. tostring(markOk))
      end
    end
    if not any then say(L.NO_NAMEPLATES, 'NO_NAMEPLATES') end
    local anyTracked = false
    for key, t in pairs(tracked) do
      anyTracked = true
      say('tracked: ' .. tostring(not IsSecret(t.name) and t.name or key)
        .. ' unit=' .. tostring(t.unit) .. ' shownColor=' .. tostring(t.shownColor)
        .. ' markIndex=' .. tostring(t.markIndex) .. ' removeAt=' .. tostring(t.removeAt))
    end
    if not anyTracked then say('tracked table is empty.') end
  elseif cmd == 'mark' then
    cycleMarkMethod()
    say('marker method: ' .. MARK_METHOD_NAMES[db.markMethod] .. ' (' .. db.markMethod .. '/' .. #MARK_METHOD_NAMES .. ')')
  elseif cmd == 'clearlog' then
    db.log = {}
    say(L.LOG_CLEARED, 'LOG_CLEARED')
  elseif cmd == 'hint' and arg == 'reset' then
    db.hideNameplateHint = false
    say(L.HINT_RESET, 'HINT_RESET')
  elseif cmd == 'hint' then
    if db.debug then
      say('cvar nameplateShowEnemies=' .. tostring(getCVar('nameplateShowEnemies'))
        .. ' hideNameplateHint=' .. tostring(db.hideNameplateHint))
    end
    local okS, errS = pcall(showHintPopup)
    if db.debug then say('showHintPopup ok=' .. tostring(okS) .. ' err=' .. tostring(errS)) end
  elseif cmd == '' then
    toggleWindow()
  else
    say(L.HELP, 'HELP')
  end
  applyLook()
  updateMinimap()
  refresh()
end

-- Boot ----------------------------------------------------------------------

frame = CreateFrame('Frame', 'ThreatWallForeverFrame', UIParent)
frame:SetSize(DEFAULTS.width, DEFAULTS.height)
frame:SetMovable(true)
frame:SetResizable(true)
if frame.SetUserPlaced then pcall(frame.SetUserPlaced, frame, true) end
frame:Hide()

local driver = CreateFrame('Frame')
driver:RegisterEvent('ADDON_LOADED')
driver:RegisterEvent('PLAYER_LOGIN')
driver:RegisterEvent('PLAYER_LOGOUT')
driver:SetScript('OnEvent', function(self, event, arg1)
  if event == 'ADDON_LOADED' then return end
  if event == 'PLAYER_LOGOUT' then
    if frame then savePlace() end
    return
  end
  if event ~= 'PLAYER_LOGIN' then
    if db and type(ThreatWallForeverDB) == 'table' and ThreatWallForeverDB ~= db then
      db = ThreatWallForeverDB
      for k, v in pairs(DEFAULTS) do if db[k] == nil then db[k] = v end end
      if frame then
        placePending = not placeFrame()
        applyLook()
        updateMinimap()
      end
    end
    -- CVars are not always reliable read at PLAYER_LOGIN yet; the first
    -- PLAYER_ENTERING_WORLD is the usual safe point, and this only needs to
    -- happen once per session.
    if event == 'PLAYER_ENTERING_WORLD' and db and not nameplateChecked then
      nameplateChecked = true
      checkNameplateSetting()
    end
    refresh()
    return
  end

  if type(ThreatWallForeverDB) ~= 'table' then ThreatWallForeverDB = {} end
  db = ThreatWallForeverDB
  for k, v in pairs(DEFAULTS) do if db[k] == nil then db[k] = v end end

  SLASH_THREATWALL1 = '/threatwall'
  SLASH_THREATWALL2 = '/twall'
  SLASH_THREATWALL3 = '/twf'

  if type(UnitDetailedThreatSituation) ~= 'function' then
    SlashCmdList.THREATWALL = function() say(L.NO_THREAT_API, 'NO_THREAT_API') end
    say(L.NO_THREAT_API, 'NO_THREAT_API')
    return
  end

  buildFrame()
  buildMinimapButton()
  SlashCmdList.THREATWALL = slash

  for _, e in ipairs({
    'PLAYER_ENTERING_WORLD', 'PLAYER_TARGET_CHANGED', 'GROUP_ROSTER_UPDATE',
    'PLAYER_REGEN_DISABLED', 'PLAYER_REGEN_ENABLED',
    'UNIT_THREAT_LIST_UPDATE', 'UNIT_THREAT_SITUATION_UPDATE',
  }) do
    pcall(self.RegisterEvent, self, e)
  end

  local since = 0
  self:SetScript('OnUpdate', function(_, elapsed)
    since = since + elapsed
    if since >= TICK then
      since = 0
      if frame and frame.moving and IsMouseButtonDown and not IsMouseButtonDown('LeftButton') then
        stopMove()
      end
      refresh()
    end
  end)

  refresh()
  say(string.format(L.LOADED, VERSION), 'LOADED')
end)
