--[[
  Config.lua — EINZIGE Quelle für alle festlegbaren Werte (REGELN.md Nr. 5).

  Alles, was man einstellen oder austauschen kann (Zeiten, Größen, Abstände,
  Farben, Texturen, Atlanten, Sounds, Grenzen, Standardwerte), steht hier.
  Der übrige Code liest nur aus dieser Tabelle. Texte stehen in Locales.lua.
]]

local _, ns = ...
local C = {}
ns.Config = C

-- Chat ---------------------------------------------------------------------------

-- Präfix vor jeder Chat-Zeile des Addons
C.PREFIX = '|cff33ff99ThreatWall Forever:|r '

-- Jede Chat-Zeile bekommt einen festen Code, damit man "003" melden kann
-- statt den ganzen Satz abzutippen.
C.CODES = {
  SPOTTED = '001',       -- Debug: neuer Problem-Gegner gefunden
  WORSENED = '002',      -- Debug: Zustand eines Gegners hat sich verschlechtert
  CLEARED = '003',       -- Debug: Zeile nach Ablauf der Gnadenfrist entfernt
  NO_NAMEPLATES = '004', -- /twf debug: nichts Sichtbares zum Prüfen
  NO_THREAT_API = '005', -- dieser Client hat gar keine Bedrohungs-API
  LOCKED_HINT = '006',   -- Fenster verschieben versucht, obwohl gesperrt
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

-- Gespeicherte Einstellungen (SavedVariables): Standardwerte -----------------------

C.DEFAULTS = {
  shown = true,
  locked = false,
  scale = 1,
  minimized = false,
  width = 240,               -- Fensterbreite in px
  height = 160,              -- Fensterhöhe in px
  alpha = 0.4,               -- Deckkraft des Hintergrunds (0–1)
  rowHeight = 20,            -- Zeilenhöhe in px
  textScale = 1,
  role = 'tank',             -- 'tank' oder 'dps'
  combatOnly = false,
  groupOnly = true,
  showAll = false,
  highlightTarget = true,    -- pulsierender Rahmen um die Zeile deines aktuellen Ziels
  sound = true,
  minimap = true,
  minimapAngle = 200,        -- Position des Minimap-Buttons in Grad
  debug = false,
  markMethod = 1,            -- Index in Marks.lua (1–3)
  hideNameplateHint = false,
}

-- Takt und Zeiten -------------------------------------------------------------------

C.TICK = 0.2                 -- Sekunden zwischen zwei Prüfungen (5x pro Sekunde reicht für Aggro)
C.GRACE = 1.0                -- Sekunden, die eine Zeile stehen bleibt, nachdem sie grün wurde/verschwand
C.LOCK_HINT_INTERVAL = 10    -- Sekunden Mindestabstand für den Hinweis "Fenster ist gesperrt"
C.MAX_LOG = 100              -- maximale Anzahl Einträge im Debug-Log (älteste fliegen zuerst raus)

-- Erkennung -------------------------------------------------------------------------

C.MAX_NAMEPLATES = 40        -- geprüfte Nameplate-Token (nameplate1..N)

-- Status-Werte von UnitDetailedThreatSituation (vom Spiel vorgegeben)
C.THREAT_STATUS = {
  SECURE = 3,                -- du tankst sicher
  INSECURE = 2,              -- du tankst, aber jemand anderes hat mehr Bedrohung
  HIGH = 1,                  -- du tankst nicht, hast aber mehr Bedrohung als der Tank
}

-- Warnton bei Verschlechterung
C.ALERT_SOUND = 8959         -- Sound-ID
C.ALERT_CHANNEL = 'Master'

-- Farben ----------------------------------------------------------------------------

-- Ampelfarben der Liste (R, G, B)
C.COLOR = {
  red = { 0.82, 0.14, 0.14 },
  yellow = { 0.92, 0.72, 0.12 },
  green = { 0.25, 0.75, 0.25 },
}
-- Rangfolge zum Sortieren (höher = schlimmer)
C.RANK = { red = 2, yellow = 1, green = 0 }

-- Textfarben im Zeilen-Tooltip (R, G, B)
C.TOOLTIP_COLOR = {
  red = { 1, 0.3, 0.3 },
  yellow = { 1, 0.8, 0.2 },
  green = { 0.3, 1, 0.3 },
}

C.TITLE_COLOR = { 1, 0.82, 0 }        -- Gold für Fenstertitel und Menü-Überschrift
C.EMPTY_TEXT_COLOR = { 0.55, 0.55, 0.55 }
C.WHITE = { 1, 1, 1 }

-- Texturen ---------------------------------------------------------------------------

C.TEXTURE = {
  FLAT = 'Interface\\Buttons\\WHITE8X8',
  ROUND_MASK = 'Interface\\CharacterFrame\\TempPortraitAlphaMask',
  ADDON_ICON = 'Interface\\Icons\\Ability_Warrior_Challange',
  TOOLTIP_BORDER = 'Interface\\Tooltips\\UI-Tooltip-Border',
  CHECK = 'Interface\\Buttons\\UI-CheckBox-Check',
  -- Rückfall-Grafiken, falls ein Atlas fehlt
  PLUS = 'Interface\\Buttons\\UI-PlusButton',
  MINUS = 'Interface\\Buttons\\UI-MinusButton',
  PLUS_HILIGHT = 'Interface\\Buttons\\UI-PlusButton-Hilight',
  OPTIONS = 'Interface\\Buttons\\UI-OptionsButton',
  SIZE_GRABBER = 'Interface\\ChatFrame\\UI-ChatIM-SizeGrabber',
  -- Minimap-Button
  MINIMAP_HIGHLIGHT = 'Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight',
  MINIMAP_BACKGROUND = 'Interface\\Minimap\\UI-Minimap-Background',
  MINIMAP_BORDER = 'Interface\\Minimap\\MiniMap-TrackingBorder',
}

-- Atlanten (moderne Grafiken; Rückfall siehe TEXTURE)
C.ATLAS = {
  WINDOW_BG = 'damagemeters-background',
  HEADER_BG = 'ui-damagemeters-header-bar',
  MINIMIZE_PREFIX = 'ui-questtrackerbutton-',      -- + 'expand'/'collapse' + Endung
  MINIMIZE_SUFFIX = '-all',
  MINIMIZE_PRESSED_SUFFIX = '-all-pressed',
  MINIMIZE_HIGHLIGHT = 'ui-questtrackerbutton-red-highlight',
  GEAR = 'common-dropdown-a-button-settings-shadowless',
  GEAR_PRESSED = 'common-dropdown-a-button-settings-pressed-shadowless',
  GEAR_HOVER = 'common-dropdown-a-button-settings-hover-shadowless',
  ROLE = { tank = 'groupfinder-icon-role-large-tank', dps = 'groupfinder-icon-role-large-dps' },
  GRIP = 'damagemeters-scalehandle',
  GRIP_HOVER = 'damagemeters-scalehandle-hover',
  GRIP_PRESSED = 'damagemeters-scalehandle-pressed',
}

-- Raid-Symbole (Marks.lua)
C.RAID_ICONS = {
  SHEET = 'Interface\\TargetingFrame\\UI-RaidTargetingIcons',    -- alle 8 Symbole in einem Bild
  COLUMNS = 4,                                                   -- Symbole pro Zeile im Bild
  ROWS = 2,                                                      -- Zeilen im Bild
  FILE_PREFIX = 'Interface\\TargetingFrame\\UI-RaidTargetingIcon_', -- Einzeldateien _1.._8
}

-- Fenster ----------------------------------------------------------------------------

C.WINDOW = {
  NAME = 'ThreatWallForeverFrame',
  MIN_W = 160, MIN_H = 90,          -- kleinste Größe beim Aufziehen
  MAX_W = 500, MAX_H = 400,         -- größte Größe beim Aufziehen
  BG_FALLBACK = { 0, 0, 0, 1 },     -- Hintergrund, falls der Atlas fehlt (R, G, B, A)
  EMPTY_X = 10,                     -- Rand des "keine Probleme"-Texts
  EMPTY_Y = 6,
  HEADER_H = 30,                    -- Höhe der Kopfleiste
  HEADER_FALLBACK = { 0.12, 0.12, 0.14, 0.95 },
  HEADER_BTN_SIZE = 22,             -- Größe der Kopf-Buttons
  HEADER_BTN_RIGHT = -6,            -- Abstand des rechten Buttons zum Rand
  HEADER_BTN_GAP = -4,              -- Abstand zwischen den Kopf-Buttons
  GEAR_EXTRA = 6,                   -- Zahnrad-Atlas hat mehr Leerraum, deshalb etwas größer
  ROLE_BACKDROP_ALPHA = 0.6,        -- Rollen-Button ohne Atlas: Deckkraft des Rahmens
  ROLE_HIGHLIGHT_ALPHA = 0.15,
  SUBTEXT_GAP = -6,                 -- Abstand der Zähler-Anzeige zum Rollen-Button
  TITLE_X = 16,                     -- linker Rand des Titels
  TITLE_GAP = -6,
  GRIP_LEVEL = 10,                  -- Frame-Ebene des Größen-Griffs über dem Fenster
  GRIP_SIZE = 50,                   -- Griff mit Atlas
  GRIP_X = 9, GRIP_Y = -8,
  GRIP_HIT = { 25, 9, 25, 8 },      -- Klickfläche (links, rechts, oben, unten einrücken)
  GRIP_FALLBACK_SIZE = 16,          -- Griff ohne Atlas
  GRIP_FALLBACK_X = -1, GRIP_FALLBACK_Y = 1,
  GRIP_FADE_SPEED = 4,              -- Ein-/Ausblend-Geschwindigkeit des Griffs
}

-- Zeilen der Liste ----------------------------------------------------------------------

C.ROW = {
  MAX = 10,                    -- maximal sichtbare Zeilen
  PADDING = 4,                 -- Abstand der Zeilen zum Fensterrand
  SPACING = 2,                 -- Abstand zwischen zwei Zeilen
  LIST_VPAD = 8,               -- senkrechter Rand der Liste (oben + unten)
  BG_ALPHA = 0.05,             -- Zeilenhintergrund normal
  BG_ALPHA_TARGET = 0.18,      -- Zeilenhintergrund beim aktuellen Ziel
  DOT_SIZE = 12,               -- Ampelpunkt
  DOT_X = 6,
  MARK_SIZE = 14,              -- Raid-Symbol
  GAP = 4,                     -- Abstand Punkt → Symbol → Name
  NAME_RIGHT = -6,
  TARGET_GLOW = { 0.55, 0.85, 1 }, -- Rahmenfarbe Ziel (hell blau-weiß, hebt sich von der Ampel ab)
  GLOW_EDGE = 2,               -- Rahmenstärke in px
  GLOW_ALPHA_FROM = 1,         -- Pulsieren: Deckkraft von …
  GLOW_ALPHA_TO = 0.4,         -- … bis
  GLOW_DURATION = 0.7,         -- Sekunden pro Pulsschritt
}

-- Testzeilen (/twf test): Name, Farbe, Raid-Symbol
C.TEST_ROWS = {
  { 'Grillmaster', 'red', 8 },
  { 'Adds Rechts', 'yellow', 3 },
  { 'Adds Links', 'yellow', nil },
}

-- Dropdown-Menü ---------------------------------------------------------------------------

C.MENU = {
  NAME = 'ThreatWallForeverMenu',
  BACKDROP_ALPHA = 0.92,
  LINE_H = 18,                 -- Zeilenhöhe
  PADDING = 8,
  CHECK_SIZE = 16,
  TEXT_X = 20,                 -- Textbeginn hinter dem Haken
  HIGHLIGHT_ALPHA = 0.12,
  MIN_WIDTH = 140,
  WIDTH_EXTRA = 44,            -- Platz für Haken und Rand neben dem Text
  ANCHOR_Y = -2,               -- Abstand unter dem auslösenden Button
  ALPHA_STEPS = { 0, 0.2, 0.4, 0.6, 0.8, 1 },       -- Hintergrund-Stufen
  SCALE_STEPS = { 0.8, 0.9, 1, 1.1, 1.25, 1.5 },    -- Skalierungs-Stufen
  PERCENT = 100,               -- Anzeige als Prozent
}

-- Rahmen (Backdrop) für Menü und Rollen-Button
C.BACKDROP = {
  EDGE_SIZE = 12,
  INSET = 3,
  BORDER_COLOR = { 0.45, 0.45, 0.5, 1 },
}

-- Minimap-Button ------------------------------------------------------------------------

C.MINIMAP = {
  NAME = 'ThreatWallForeverMinimapButton',
  SIZE = 31,
  LEVEL = 8,
  BG_SIZE = 20, BG_X = 7, BG_Y = -5,
  ICON_SIZE = 18, ICON_X = 7, ICON_Y = -6,
  ICON_CROP = { 0.08, 0.92, 0.08, 0.92 },   -- Rand des Icons abschneiden
  RING_SIZE = 53,
  RADIUS_EXTRA = 8,            -- Abstand außerhalb des Minimap-Rands
}

-- Hinweis-Popup (Nameplates) --------------------------------------------------------------

C.HINT = {
  NAME = 'ThreatWallForeverHintPopup',
  CHECK_NAME = 'ThreatWallForeverHintCheck',
  CVAR = 'nameplateShowEnemies',  -- geprüfte Spiel-Option
  CVAR_OFF = '0',                 -- Wert, wenn sie aus ist
  OPTIONS_CATEGORY = 'Names',     -- Seite in den Spiel-Optionen
  WIDTH = 460, HEIGHT = 230,
  OFFSET_Y = 100,                 -- über der Bildschirmmitte
  TITLE_Y = -7,
  TITLE_MARGIN = 80,              -- Titelbreite = Fensterbreite minus diesen Wert
  BODY_X = 16, BODY_Y = -40,
  BODY_SPACING = 3,
  BTN_H = 22,
  OK_W = 80,
  SETTINGS_W = 150,
  BTN_GAP = -8,
  EDGE = 16,                      -- Abstand der Buttons/Checkbox zum Rand
  CHECK_SIZE = 20,
}
