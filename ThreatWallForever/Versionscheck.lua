--[[
  Versionscheck.lua — Hinweis auf neuere TWF-Versionen (Anforderung AH).

  Unsichtbare Addon-Nachricht mit der eigenen Version: einmal nach dem Einloggen an die
  Gilde, einmal beim Beitritt zu Gruppe/Schlachtzug dorthin. Jedes TWF vergleicht; hört es
  eine neuere Version, steht einmal pro Sitzung ein Hinweis im Chat. Hört ein neueres TWF
  eine ältere Version, antwortet es einmal (gedrosselt, mit Zufallsverzögerung), damit auch
  der Ältere davon erfährt. Kein realm-weiter Kanal (Nutzer 2026-10-18).
]]

local _, ns = ...
local C = ns.Config
local L = ns.L
local VC = C.VERSIONCHECK

local notified = false          -- Hinweis "neuere Version" schon gezeigt (einmal pro Sitzung)
local lastSent = {}             -- Kanal -> Zeitpunkt der letzten Nachricht (Drosselung)
local wasInGroup = false

-- "0.5" → { 0, 5 }; nil, wenn es keine Versionsnummer ist
local function parse(v)
  if type(v) ~= 'string' or not v:match('^%d+[%.%d]*$') then return nil end
  local t = {}
  for n in v:gmatch('%d+') do t[#t + 1] = tonumber(n) end
  return t
end

-- -1 = a älter, 0 = gleich, 1 = a neuer
local function compare(a, b)
  for i = 1, math.max(#a, #b) do
    local x, y = a[i] or 0, b[i] or 0
    if x ~= y then return x < y and -1 or 1 end
  end
  return 0
end

local function send(channel)
  local now = GetTime()
  if lastSent[channel] and now - lastSent[channel] < VC.THROTTLE then return end
  -- in Instanzen im Kampf sind Addon-Nachrichten gesperrt (laut NKThreat) → später
  if InCombatLockdown() then return end
  local ok = pcall(C_ChatInfo.SendAddonMessage, VC.PREFIX, VC.TAG .. ns.VERSION, channel)
  if ok then
    lastSent[channel] = now
    ns.dbg('VERSION', 'Version ' .. ns.VERSION .. ' an ' .. channel .. ' gesendet')
  end
end

local function groupChannel()
  if IsInRaid() then return 'RAID' end
  if IsInGroup() then return 'PARTY' end
end

local function onMessage(prefix, msg, channel, sender)
  if prefix ~= VC.PREFIX or type(msg) ~= 'string' then return end
  local other = msg:match('^' .. VC.TAG .. '(.+)$')
  local theirs, mine = parse(other), parse(ns.VERSION)
  if not (theirs and mine) then return end
  -- eigene Nachricht (Name mit oder ohne Realm)
  local me = UnitName('player')
  if sender == me or (type(sender) == 'string' and sender:match('^([^%-]+)') == me) then return end
  local c = compare(theirs, mine)
  if c > 0 and not notified then
    notified = true
    ns.say(string.format(L.VERSION_NEWER, other, ns.VERSION))
  elseif c < 0 then
    -- der andere hat eine ältere Version: einmal antworten, verzögert, damit nicht alle gleichzeitig
    C_Timer.After(VC.REPLY_MIN + math.random() * (VC.REPLY_MAX - VC.REPLY_MIN), function() send(channel) end)
  end
end

local events = CreateFrame('Frame')
events:RegisterEvent('CHAT_MSG_ADDON')
events:RegisterEvent('GROUP_ROSTER_UPDATE')
events:RegisterEvent('PLAYER_REGEN_ENABLED')
events:SetScript('OnEvent', function(_, event, ...)
  if event == 'CHAT_MSG_ADDON' then
    onMessage(...)
  elseif event == 'GROUP_ROSTER_UPDATE' or event == 'PLAYER_REGEN_ENABLED' then
    -- frisch einer Gruppe beigetreten (oder nach dem Kampf nachholen)
    local ch = groupChannel()
    if ch and (not wasInGroup or event == 'PLAYER_REGEN_ENABLED') then send(ch) end
    wasInGroup = ch ~= nil
  end
end)

ns.RegisterModule('Versionscheck', {
  OnLogin = function()
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
      C_ChatInfo.RegisterAddonMessagePrefix(VC.PREFIX)
    end
    wasInGroup = groupChannel() ~= nil
    C_Timer.After(VC.LOGIN_DELAY, function()
      if IsInGuild() then send('GUILD') end
      local ch = groupChannel()
      if ch then send(ch) end
    end)
  end,
})
