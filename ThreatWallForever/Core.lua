--[[
  ThreatWall Forever — Core.lua

  Kompakter Aggro-Warner. Zeigt standardmäßig keine komplette Bedrohungsliste,
  sondern nur Gegner, die gerade ein Problem sind: eine Zeile pro Gegner,
  das Schlimmste zuerst. Mit "Alle Kämpfe zeigen" kommen alle Gegner im Kampf
  dazu, auch grüne ohne Problem.

  Zwei Modi (Button im Fensterkopf oder Menü):
    Tank-Modus    - Gegner, bei denen du die Aggro VERLIERST (oder nie hattest).
    DD/Heal-Modus - Gegner, bei denen DU zu viel Aggro ziehst.
  Beide lesen denselben Wert (UnitDetailedThreatSituation, Status 0–3);
  nur die Farbzuordnung ist umgedreht.

  Zeilen sind einfache, nicht-sichere Buttons: nur Anzeige und Tooltip, kein
  Klick-zum-Anvisieren (siehe ANFORDERUNGEN.md / Memory: nameplateN-Token sind
  nicht anvisierbar; frühere Ursache war Client-Bug forever-bugs#74).

  Dieser Client liefert im Kampf teils "geheime" Werte, die man anzeigen, aber
  nicht vergleichen darf. Ist ein Wert geheim, wird der Gegner in diesem
  Durchlauf übersprungen statt geraten.

  Aufbau: siehe ANFORDERUNGEN.md, Anforderung I. Dieses Modul enthält den
  gemeinsamen Namespace, die Modul-Anmeldung und den Start/Takt.
]]

local ADDON, ns = ...
local C = ns.Config
local L = ns.L

ns.ADDON = ADDON

-- Version kommt aus der .toc (## Version) – einzige Stelle, die bei jedem
-- Release erhöht wird; Titelleiste und Startmeldung können so nie abweichen.
ns.VERSION = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(ADDON, 'Version'))
  or (GetAddOnMetadata and GetAddOnMetadata(ADDON, 'Version')) or '?'

-- Laufzeit-Zustand, den mehrere Module teilen
ns.state = {
  testMode = false,          -- Testzeilen statt echter Gegner
  placePending = false,      -- Position konnte noch nicht gespeichert werden (wird gesetzt, aber derzeit nirgends gelesen)
  scroll = 0,                -- derzeit ungenutzt (aus dem Original übernommen)
  nameplateChecked = false,  -- Spiel-Optionen in dieser Sitzung schon geprüft (Hint.lua)
}

-- Fenster-Elemente, die mehrere Module brauchen (werden in Window.lua/Minimap.lua gesetzt)
ns.ui = {}

-- Modul-Anmeldung ------------------------------------------------------------------
-- Module melden sich mit ns.RegisterModule(name, modul) an. Beim Login ruft der
-- Core OnLogin() jedes Moduls in Lade-Reihenfolge (= TOC-Reihenfolge) auf.
-- Ein Fehler in einem Modul wird wie üblich angezeigt, hält die anderen aber
-- nicht auf. Weitere Rückrufe (z. B. OnSettingChanged) kommen dazu, sobald ein
-- Modul sie braucht.
ns.modules = {}

function ns.RegisterModule(name, module)
  ns.modules[#ns.modules + 1] = { name = name, module = module }
end

local function callModules(hook)
  for _, entry in ipairs(ns.modules) do
    local fn = entry.module[hook]
    if fn then
      local ok, err = pcall(fn)
      if not ok then geterrorhandler()(err) end
    end
  end
end

-- Gespeicherte Einstellungen laden und fehlende Werte mit Standardwerten füllen
local function loadDB()
  if type(ThreatWallForeverDB) ~= 'table' then ThreatWallForeverDB = {} end
  ns.db = ThreatWallForeverDB
  for k, v in pairs(C.DEFAULTS) do if ns.db[k] == nil then ns.db[k] = v end end
end

-- Start und Takt --------------------------------------------------------------------

local driver = CreateFrame('Frame')
driver:RegisterEvent('ADDON_LOADED')
driver:RegisterEvent('PLAYER_LOGIN')
driver:RegisterEvent('PLAYER_LOGOUT')
driver:SetScript('OnEvent', function(self, event, arg1)
  if event == 'ADDON_LOADED' then return end
  if event == 'PLAYER_LOGOUT' then
    if ns.frame then ns.savePlace() end
    return
  end
  if event ~= 'PLAYER_LOGIN' then
    local db = ns.db
    if db and type(ThreatWallForeverDB) == 'table' and ThreatWallForeverDB ~= db then
      db = ThreatWallForeverDB
      ns.db = db
      for k, v in pairs(C.DEFAULTS) do if db[k] == nil then db[k] = v end end
      if ns.frame then
        ns.state.placePending = not ns.placeFrame()
        ns.applyLook()
        ns.updateMinimap()
      end
    end
    -- CVars sind bei PLAYER_LOGIN nicht immer zuverlässig lesbar; das erste
    -- PLAYER_ENTERING_WORLD ist der übliche sichere Zeitpunkt. Einmal pro Sitzung.
    if event == 'PLAYER_ENTERING_WORLD' and ns.db and not ns.state.nameplateChecked then
      ns.state.nameplateChecked = true
      ns.checkGameOptions(false)
    end
    ns.refresh()
    return
  end

  loadDB()

  SLASH_THREATWALL1 = '/threatwall'
  SLASH_THREATWALL2 = '/twall'
  SLASH_THREATWALL3 = '/twf'

  if type(UnitDetailedThreatSituation) ~= 'function' then
    SlashCmdList.THREATWALL = function() ns.say(L.NO_THREAT_API, 'NO_THREAT_API') end
    ns.say(L.NO_THREAT_API, 'NO_THREAT_API')
    return
  end

  -- Fenster, Minimap-Button und Befehle aufbauen (in TOC-Reihenfolge)
  callModules('OnLogin')

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
    if since >= C.TICK then
      since = 0
      local frame = ns.frame
      if frame and frame.moving and IsMouseButtonDown and not IsMouseButtonDown('LeftButton') then
        ns.stopMove()
      end
      ns.refresh()
    end
  end)

  ns.refresh()
  ns.say(string.format(L.LOADED, ns.VERSION), 'LOADED')
end)
