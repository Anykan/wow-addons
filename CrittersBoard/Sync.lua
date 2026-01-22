CrittersBoard = CrittersBoard or {}
local CB = CrittersBoard

CB.PREFIX = CB.PREFIX or "CB_CRIT"

CB.Sync = CB.Sync or {}
local SYNC = CB.Sync

local MAX_PAYLOAD = 220
local SNAP_TIMEOUT = 35
local DEBUG = true

-- THROTTLE SETTINGS
local SEND_INTERVAL = 0.10      -- 0.1 sec per addon message
local SHARE_PLAYER_PAUSE = 1.50 -- 1.5 sec pause between share targets (war 1.00)

SYNC.incoming = SYNC.incoming or {}
SYNC.autoSyncDone = SYNC.autoSyncDone or false
SYNC.syncActive = SYNC.syncActive or false
SYNC.syncFinishTimer = SYNC.syncFinishTimer or nil

-- online addon users
SYNC.knownOnline = SYNC.knownOnline or {}

-- loop protection / state
SYNC.lastSyncRequestAt = SYNC.lastSyncRequestAt or 0
SYNC.lastShareAt = SYNC.lastShareAt or 0
SYNC.shareCooldown = 30 -- seconds
SYNC.syncWasPulled = SYNC.syncWasPulled or false

-- notification lock per cycle
SYNC.cycleId = SYNC.cycleId or 0
SYNC.notifiedCycleId = SYNC.notifiedCycleId or 0

-- debug spam guards per cycle
SYNC.pingPongWarnedCycleId = SYNC.pingPongWarnedCycleId or 0
SYNC.finishedDebugCycleId = SYNC.finishedDebugCycleId or 0

-- SEND QUEUE
SYNC.sendQueue = SYNC.sendQueue or {}
SYNC.sendTicker = SYNC.sendTicker or nil

-- SHARE QUEUE
SYNC.shareQueue = SYNC.shareQueue or {}
SYNC.shareRunning = SYNC.shareRunning or false

-- STATS per sync cycle
SYNC.stats = SYNC.stats or {
  cycle = 0,
  tx = 0,
  txGuild = 0,
  txWhisper = 0,
  rx = 0,
  rxEvt = 0,
  rxSnap = 0,
}

local function Now() return time() end

local function PrintDebug(msg)
  if not DEBUG then return end
  if CB.Print then
    CB:Print("|cff00ffff[SYNC]|r " .. msg)
  end
end

-- =========================================================
-- Throttled Send Queue (prevents flood disconnects)
-- =========================================================
local function StartSendTicker()
  if SYNC.sendTicker then return end

  SYNC.sendTicker = C_Timer.NewTicker(SEND_INTERVAL, function()
    if #SYNC.sendQueue == 0 then
      if SYNC.sendTicker then
        SYNC.sendTicker:Cancel()
        SYNC.sendTicker = nil
      end
      return
    end

    local item = table.remove(SYNC.sendQueue, 1)
    if item then
      C_ChatInfo.SendAddonMessage(CB.PREFIX, item.msg, item.channel, item.target)
    end
  end)
end

local function Send(channel, target, msg)
  if not C_ChatInfo or not C_ChatInfo.SendAddonMessage then return end
  if channel == "GUILD" and not IsInGuild() then return end

  -- stats
  SYNC.stats.tx = (SYNC.stats.tx or 0) + 1
  if channel == "GUILD" then
    SYNC.stats.txGuild = (SYNC.stats.txGuild or 0) + 1
  elseif channel == "WHISPER" then
    SYNC.stats.txWhisper = (SYNC.stats.txWhisper or 0) + 1
  end

  table.insert(SYNC.sendQueue, { channel = channel, target = target, msg = msg })
  StartSendTicker()
end

-- =========================================================
-- Helpers
-- =========================================================
local function SplitPipe(msg)
  local t = {}
  for part in string.gmatch(msg, "([^|]+)") do
    table.insert(t, part)
  end
  return t
end

local function SafeNum(x)
  local n = tonumber(x)
  if not n then return 0 end
  return n
end

local function SafeStr(x)
  if not x then return "" end
  x = tostring(x)
  x = string.gsub(x, "[\r\n|]", "")
  return x
end

local function GetTableByKind(kind)
  if kind == "D" then return CB.DB.damage end
  if kind == "H" then return CB.DB.heal end
  if kind == "O" then return CB.DB.overkill end

  -- NEW
  if kind == "S" then return CB.DB.spells end
  if kind == "HS" then return CB.DB.healspells end

  return nil
end

-- record encoding: player,class,spell,amount,ts,crit,target,region,weapon,overkill
local function EncodeRecord(rec)
  local crit = rec.isCrit and "1" or "0"
  return table.concat({
    SafeStr(rec.player),
    SafeStr(rec.class),
    SafeStr(rec.spell),
    tostring(rec.amount or 0),
    tostring(rec.ts or Now()),
    crit,
    SafeStr(rec.target),
    SafeStr(rec.region),
    SafeStr(rec.weapon),
    tostring(rec.overkill or 0),
  }, ",")
end

local function DecodeRecord(s)
  local parts = {}
  for p in string.gmatch(s, "([^,]+)") do
    table.insert(parts, p)
  end
  if #parts < 6 then return nil end

  return {
    player = parts[1],
    class = parts[2],
    spell = parts[3],
    amount = SafeNum(parts[4]),
    ts = SafeNum(parts[5]),
    isCrit = (parts[6] == "1"),
    target = parts[7] or "",
    region = parts[8] or "",
    weapon = parts[9] or "",
    overkill = SafeNum(parts[10] or 0),
  }
end

local function MakeChunks(kind)
  local tbl = GetTableByKind(kind)
  if not tbl or not tbl.records then return { "" } end

  local chunks = {}
  local current = ""

  for i = 1, math.min(#tbl.records, 100) do
    local line = EncodeRecord(tbl.records[i])
    local add = line
    if current ~= "" then add = ";" .. line end

    if (#current + #add) > (MAX_PAYLOAD - 40) then
      table.insert(chunks, current)
      current = line
    else
      current = current .. add
    end
  end

  if current ~= "" then
    table.insert(chunks, current)
  end

  if #chunks == 0 then chunks = { "" } end
  return chunks
end

local function CleanupIncoming()
  local now = Now()
  for snapId, snap in pairs(SYNC.incoming) do
    for kind, data in pairs(snap) do
      if data.t0 and (now - data.t0) > SNAP_TIMEOUT then
        PrintDebug("Timeout snapshot " .. snapId .. " kind " .. tostring(kind))
        snap[kind] = nil
      end
    end
    if not next(snap) then
      SYNC.incoming[snapId] = nil
    end
  end
end

local function ApplyPayload(kind, payload)
  if not payload or payload == "" then return end
  local tbl = GetTableByKind(kind)
  if not tbl then return end

  for recStr in string.gmatch(payload, "([^;]+)") do
    local rec = DecodeRecord(recStr)
    if rec and rec.player and rec.amount and rec.amount > 0 then

      local added = false

      -- D/H/O normal
      if kind == "D" or kind == "H" or kind == "O" then
        added = CB:AddRecord(tbl, rec.player, rec.spell, rec.amount, rec.ts, rec.isCrit, rec.class, "guild")

      -- NEW: S best-of
      elseif kind == "S" then
        if CB.AddSpellBest then
          added = CB:AddSpellBest(rec.player, rec.spell, rec.amount, rec.ts, rec.isCrit, rec.class, "guild")
        end

      -- NEW: HS best-of
      elseif kind == "HS" then
        if CB.AddHealSpellBest then
          added = CB:AddHealSpellBest(rec.player, rec.spell, rec.amount, rec.ts, rec.isCrit, rec.class, "guild")
        end
      end

      if added then
        -- decorate only for normal lists
        if kind == "D" or kind == "H" or kind == "O" then
          local id = CB:SafeStr(rec.player) .. "|" .. CB:SafeStr(rec.spell) .. "|" .. tostring(rec.amount) .. "|" .. tostring(rec.ts) .. "|" ..
            tostring(rec.isCrit and 1 or 0) .. "|" .. CB:SafeStr(rec.class or "")

          for i = 1, #tbl.records do
            local r = tbl.records[i]
            if r and r.id == id then
              r.target = rec.target
              r.region = rec.region
              r.weapon = rec.weapon
              if kind ~= "O" and rec.overkill and rec.overkill > 0 then
                r.overkill = rec.overkill
              end
              break
            end
          end
        end
      end
    end
  end
end

local function RememberOnline(sender)
  if not sender or sender == "" then return end
  SYNC.knownOnline[sender] = Now()
end

-- FIX: exclude self from list (no sending to yourself)
local function GetKnownOnlinePlayers()
  local list = {}
  local now = Now()
  local me = UnitName("player")

  for name, t0 in pairs(SYNC.knownOnline) do
    if name ~= me and (now - t0) <= 120 then
      table.insert(list, name)
    end
  end

  return list
end

local function AlertsEnabled()
  if not CB.DB or not CB.DB.ui then return true end
  return (CB.DB.ui.alertsEnabled ~= false)
end

local function NotifySyncCompleteOnce()
  if SYNC.notifiedCycleId == SYNC.cycleId then
    return
  end
  SYNC.notifiedCycleId = SYNC.cycleId

  if not AlertsEnabled() then return end

  local count = #GetKnownOnlinePlayers()
  local text = "GildenSync complete (" .. count .. " Spieler)"

  if RaidNotice_AddMessage and RaidWarningFrame then
    RaidNotice_AddMessage(RaidWarningFrame, text, ChatTypeInfo["RAID_WARNING"])
  end

  local path = "Interface\\AddOns\\CrittersBoard\\sounds\\sync.ogg"
  local ok = PlaySoundFile(path, "Master")
  if not ok then
    PlaySoundFile(path)
  end

  -- stats output (debug only)
  if DEBUG then
    local s = SYNC.stats or {}
    PrintDebug(string.format(
      "Cycle #%d STATS: TX=%d (G=%d W=%d) RX=%d (EVT=%d SNAP=%d)",
      s.cycle or 0,
      s.tx or 0,
      s.txGuild or 0,
      s.txWhisper or 0,
      s.rx or 0,
      s.rxEvt or 0,
      s.rxSnap or 0
    ))
  end
end

local function ArmSyncFinished()
  SYNC.syncActive = true

  if SYNC.syncFinishTimer then
    SYNC.syncFinishTimer:Cancel()
    SYNC.syncFinishTimer = nil
  end

  SYNC.syncFinishTimer = C_Timer.NewTimer(2.0, function()
    SYNC.syncFinishTimer = nil
    if SYNC.syncActive then
      SYNC.syncActive = false
      CB:OnSyncFinished()
    end
  end)
end

local function TryFinalize(snapId, kind)
  local snap = SYNC.incoming[snapId]
  if not snap or not snap[kind] then return end

  local data = snap[kind]
  local total = data.total or 0
  if total <= 0 then return end

  for i = 1, total do
    if not data.chunks[i] then
      return
    end
  end

  local merged = ""
  for i = 1, total do
    local c = data.chunks[i]
    if c and c ~= "" then
      if merged ~= "" then merged = merged .. ";" end
      merged = merged .. c
    end
  end

  ApplyPayload(kind, merged)

  snap[kind] = nil
  if not next(snap) then
    SYNC.incoming[snapId] = nil
  end

  if CB.UI and CB.UI.Refresh then CB.UI:Refresh() end
  ArmSyncFinished()
end

-- =========================================================
-- ShareAfterSync: send to players sequentially (1.5 sec pause)
-- =========================================================
local function ShareToPlayer(who)
  local from = UnitName("player") or "?"
  local snapId = tostring(Now()) .. "-" .. tostring(math.random(1000, 9999))

  local function SendKindTo(kind)
    local chunks = MakeChunks(kind)
    Send("WHISPER", who, table.concat({ "SNAPBEGIN", from, kind, tostring(#chunks), snapId }, "|"))
    for i = 1, #chunks do
      Send("WHISPER", who, table.concat({ "SNAPCHUNK", from, kind, tostring(i), snapId, chunks[i] or "" }, "|"))
    end
    Send("WHISPER", who, table.concat({ "SNAPEND", from, kind, snapId }, "|"))
  end

  SendKindTo("D")
  SendKindTo("H")
  SendKindTo("O")

  -- NEW
  SendKindTo("S")
  SendKindTo("HS")
end

local function ShareNext()
  if #SYNC.shareQueue == 0 then
    SYNC.shareRunning = false
    NotifySyncCompleteOnce()
    return
  end

  local who = table.remove(SYNC.shareQueue, 1)
  if not who or who == "" then
    C_Timer.After(SHARE_PLAYER_PAUSE, ShareNext)
    return
  end

  PrintDebug("ShareAfterSync -> sending snapshot to " .. who)
  ShareToPlayer(who)

  C_Timer.After(SHARE_PLAYER_PAUSE, ShareNext)
end

-- =========================================================
-- Public API
-- =========================================================
function CB:RequestSnapshot(manual)
  if not IsInGuild() then
    if CB.Print then CB:Print("Du bist nicht in einer Gilde.") end
    return
  end

  SYNC.cycleId = (SYNC.cycleId or 0) + 1
  PrintDebug("New sync cycle: " .. tostring(SYNC.cycleId))

  -- reset stats for this cycle
  SYNC.stats.cycle = SYNC.cycleId
  SYNC.stats.tx = 0
  SYNC.stats.txGuild = 0
  SYNC.stats.txWhisper = 0
  SYNC.stats.rx = 0
  SYNC.stats.rxEvt = 0
  SYNC.stats.rxSnap = 0

  local me = UnitName("player") or "?"
  PrintDebug("RequestSnapshot by " .. me)

  SYNC.lastSyncRequestAt = Now()
  SYNC.syncWasPulled = true

  Send("GUILD", nil, "SNAPREQ|" .. me)

  if manual and CB.Print then
    CB:Print("Sync angefragt…")
  end
end

function CB:AutoSync()
  if SYNC.autoSyncDone then return end
  SYNC.autoSyncDone = true

  C_Timer.After(3, function()
    CB:RequestSnapshot(false)
  end)
end

function CB:OnSyncFinished()
  -- Debug only once per cycle
  if SYNC.finishedDebugCycleId ~= SYNC.cycleId then
    SYNC.finishedDebugCycleId = SYNC.cycleId
    PrintDebug("Sync finished")
  end

  if not CB.DB or not CB.DB.ui then
    NotifySyncCompleteOnce()
    return
  end

  if not CB.DB.ui.shareAfterSync then
    NotifySyncCompleteOnce()
    return
  end

  if not SYNC.syncWasPulled then
    if SYNC.pingPongWarnedCycleId ~= SYNC.cycleId then
      SYNC.pingPongWarnedCycleId = SYNC.cycleId
      PrintDebug("Not sharing (syncWasPulled=false) -> prevents ping pong")
    end
    NotifySyncCompleteOnce()
    return
  end
  SYNC.syncWasPulled = false

  local now = Now()
  if (now - (SYNC.lastShareAt or 0)) < SYNC.shareCooldown then
    PrintDebug("Share cooldown active -> skip share")
    NotifySyncCompleteOnce()
    return
  end
  SYNC.lastShareAt = now

  local targets = GetKnownOnlinePlayers()
  if #targets == 0 then
    PrintDebug("ShareAfterSync enabled but no known online addon users yet.")
    NotifySyncCompleteOnce()
    return
  end

  -- sequential share
  SYNC.shareQueue = targets
  if SYNC.shareRunning then
    PrintDebug("Share already running -> skip starting new one")
    NotifySyncCompleteOnce()
    return
  end

  SYNC.shareRunning = true
  PrintDebug("ShareAfterSync -> queue size " .. tostring(#targets))
  ShareNext()
end

function CB:SendEvent(kind, rec)
  if not IsInGuild() then return end
  if not rec or not kind then return end

  local msg = table.concat({
    "EVT",
    kind,
    SafeStr(rec.player),
    SafeStr(rec.class),
    SafeStr(rec.spell),
    tostring(rec.amount or 0),
    tostring(rec.ts or Now()),
    rec.isCrit and "1" or "0",
    SafeStr(rec.target),
    SafeStr(rec.region),
    SafeStr(rec.weapon),
    tostring(rec.overkill or 0),
  }, "|")

  Send("GUILD", nil, msg)
end

-- =========================================================
-- Receiver
-- =========================================================
local recvFrame = CreateFrame("Frame")
recvFrame:RegisterEvent("PLAYER_LOGIN")
recvFrame:RegisterEvent("CHAT_MSG_ADDON")

recvFrame:SetScript("OnEvent", function(self, event, prefix, msg, channel, sender)
  if event == "PLAYER_LOGIN" then
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
      C_ChatInfo.RegisterAddonMessagePrefix(CB.PREFIX)
    end
    if CB.AutoSync then CB:AutoSync() end
    return
  end

  if prefix ~= CB.PREFIX then return end
  if not msg then return end

  -- stats rx
  SYNC.stats.rx = (SYNC.stats.rx or 0) + 1

  CleanupIncoming()

  local parts = SplitPipe(msg)
  local cmd = parts[1]

  if cmd == "SNAPREQ" then
    local requester = parts[2]
    if not requester or requester == "" then return end

    RememberOnline(requester)

    -- count as snap traffic
    SYNC.stats.rxSnap = (SYNC.stats.rxSnap or 0) + 1

    local from = UnitName("player") or "?"
    local snapId = tostring(Now()) .. "-" .. tostring(math.random(1000, 9999))

    local function SendKind(kind)
      local chunks = MakeChunks(kind)
      Send("WHISPER", requester, table.concat({ "SNAPBEGIN", from, kind, tostring(#chunks), snapId }, "|"))
      for i = 1, #chunks do
        Send("WHISPER", requester, table.concat({ "SNAPCHUNK", from, kind, tostring(i), snapId, chunks[i] or "" }, "|"))
      end
      Send("WHISPER", requester, table.concat({ "SNAPEND", from, kind, snapId }, "|"))
    end

    SendKind("D")
    SendKind("H")
    SendKind("O")

    -- NEW
    SendKind("S")
    SendKind("HS")
    return
  end

  if cmd == "SNAPBEGIN" then
    SYNC.stats.rxSnap = (SYNC.stats.rxSnap or 0) + 1

    local from = parts[2] or sender or "?"
    local kind = parts[3]
    local total = SafeNum(parts[4])
    local snapId = parts[5]
    if not snapId or snapId == "" then return end
    if total <= 0 then return end

    RememberOnline(from)

    SYNC.incoming[snapId] = SYNC.incoming[snapId] or {}
    SYNC.incoming[snapId][kind] = {
      from = from,
      total = total,
      chunks = {},
      t0 = Now(),
    }
    return
  end

  if cmd == "SNAPCHUNK" then
    SYNC.stats.rxSnap = (SYNC.stats.rxSnap or 0) + 1

    local kind = parts[3]
    local idx = SafeNum(parts[4])
    local snapId = parts[5]
    local payload = parts[6] or ""

    if not snapId or not kind then return end
    if idx <= 0 then return end

    local snap = SYNC.incoming[snapId]
    if not snap or not snap[kind] then return end

    snap[kind].chunks[idx] = payload
    TryFinalize(snapId, kind)
    return
  end

  if cmd == "SNAPEND" then
    SYNC.stats.rxSnap = (SYNC.stats.rxSnap or 0) + 1

    local kind = parts[3]
    local snapId = parts[4]
    if snapId and kind then
      TryFinalize(snapId, kind)
    end
    return
  end

  if cmd == "EVT" then
    SYNC.stats.rxEvt = (SYNC.stats.rxEvt or 0) + 1

    local kind = parts[2]
    local player = parts[3]
    local classFile = parts[4]
    local spell = parts[5]
    local amount = SafeNum(parts[6])
    local ts = SafeNum(parts[7])
    local isCrit = (parts[8] == "1")
    local target = parts[9]
    local region = parts[10]
    local weapon = parts[11]
    local overkill = SafeNum(parts[12])

    local tbl = GetTableByKind(kind)
    if not tbl then return end
    if not player or player == "" then return end
    if amount <= 0 then return end

    RememberOnline(sender)

    local added = false

    -- normal lists
    if kind == "D" or kind == "H" or kind == "O" then
      added = CB:AddRecord(tbl, player, spell, amount, ts, isCrit, classFile, "guild")

    -- NEW: SpellBest
    elseif kind == "S" then
      if CB.AddSpellBest then
        added = CB:AddSpellBest(player, spell, amount, ts, isCrit, classFile, "guild")
      end

    -- NEW: HealSpellBest
    elseif kind == "HS" then
      if CB.AddHealSpellBest then
        added = CB:AddHealSpellBest(player, spell, amount, ts, isCrit, classFile, "guild")
      end
    end

    if not added then return end

    -- decorate only for normal lists
    if kind == "D" or kind == "H" or kind == "O" then
      local id = CB:SafeStr(player) .. "|" .. CB:SafeStr(spell) .. "|" .. tostring(amount) .. "|" .. tostring(ts) .. "|" ..
        tostring(isCrit and 1 or 0) .. "|" .. CB:SafeStr(classFile or "")

      for i = 1, #tbl.records do
        local r = tbl.records[i]
        if r and r.id == id then
          r.target = target
          r.region = region
          r.weapon = weapon
          if kind ~= "O" and overkill and overkill > 0 then
            r.overkill = overkill
          end
          break
        end
      end
    end

    if CB.UI and CB.UI.Refresh then CB.UI:Refresh() end
    return
  end
end)
