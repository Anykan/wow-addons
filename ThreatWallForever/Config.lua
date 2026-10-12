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
  SETTING = '016',       -- Debug: Einstellung im Einstellungsfenster geändert
  OPTIONS_PANEL = '017', -- Debug: Seite unter Optionen → AddOns angelegt / fehlgeschlagen
  DEBUG_SET = '018',     -- /twf debug 1|0
  GAME_OPTIONS = '019',  -- Debug: Prüfung der Spiel-Optionen
  NAMEPLATES = '020',    -- Debug: TWF-Nameplates
  SYMBOLS = '021',       -- Debug: Symbol-Markierung (Aggro-Halter)
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
  twfNameplates = true,      -- an = TWF-Nameplates statt Blizzard (Anforderung J)
  symbolMarks = true,        -- Symbol-Markierung Mob ↔ Aggro-Halter (Anforderung L)
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

-- Testzeilen (/twf test): Name, Farbe, Raid-Symbol, Symbol-Markierung (Schlüssel in C.SYMBOLS)
C.TEST_ROWS = {
  { 'Grillmaster', 'red', 8, 'HEALER' },
  { 'Adds Rechts', 'yellow', 3, 'DAMAGER' },
  { 'Adds Links', 'yellow', nil, nil },
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

-- TWF-Nameplates (Nameplates.lua, Anforderungen J + K) --------------------------------------

C.NAMEPLATES = {
  LEVEL = 5,                   -- Frame-Ebene über der Blizzard-Nameplate
  WIDTH = 110, HEIGHT = 10,    -- Rückfallgröße, falls Blizzards Lebensleiste nicht gefunden wird
  BG_INSET = 1,                -- Hintergrund ragt so viele px über den Balken (wie Blizzards Zauberbalken)
  BORDER_INSET = 2,            -- Rahmen ragt so viele px über den Balken
  NAME_Y = 2,                  -- Abstand des Namens über dem Balken
  PCT_X = -3,                  -- Abstand der Prozentanzeige vom rechten Balkenrand
  PCT_LAYER = 7,               -- Zeichen-Unterebene der Prozentzahl (über dem Rahmen)
  PCT_FORMAT = '%.0f%%',       -- Anzeige des Lebens in Prozent
  ADD_DELAY = 0,               -- Sekunden Verzögerung nach "Nameplate erscheint" (0 = nächster Frame; Blizzard richtet sie erst ein)
  WORLD_DELAY = 1,             -- Sekunden nach Betreten der Welt bis zur kompletten Neuprüfung
  -- Füllung je Ampelfarbe (Atlanten im Stil von Blizzards Zauberbalken, getestet in T8c)
  FILL = {
    green = 'ui-castingbar-filling-channel',
    yellow = 'ui-castingbar-filling-standard',
    red = 'ui-castingbar-interrupted',
    blue = 'ui-castingbar-filling-standard',   -- entsättigt + blau getönt (siehe TINT)
    grey = 'ui-castingbar-filling-standard',   -- entsättigt + grau getönt
  },
  -- Farben ohne eigene Blizzard-Füllung: goldene Füllung entsättigen und tönen (R, G, B)
  TINT = {
    blue = { 0.35, 0.55, 1 },  -- im Kampf, aber nicht mit dir/deiner Gruppe
    grey = { 0.6, 0.6, 0.6 },  -- dein Ziel außerhalb des Kampfs
  },
  BAR_BG = 'ui-castingbar-background',
  BAR_BORDER = 'ui-castingbar-frame',
  PLAIN_FILL = 'Interface\\TargetingFrame\\UI-StatusBar',  -- Rückfall, falls die Atlanten fehlen
}

-- Symbol-Markierung (Symbols.lua, Anforderung L) -------------------------------------------

-- Symbolsatz: hier austauschen, sonst nirgends. Jeder Eintrag ist ein Atlas-Name oder ein
-- Dateipfad, oder eine Tabelle { texture = ..., coords = { links, rechts, oben, unten } }
-- für Dateien mit mehreren Symbolen in einem Bild.
C.SYMBOLS = {
  TANK = 'ui-lfg-roleicon-tank',
  HEALER = 'ui-lfg-roleicon-healer',
  DAMAGER = 'ui-lfg-roleicon-dps',
  NONE = 'ui-lfg-roleicon-dps',        -- Halter ohne gesetzte Rolle (Kampf-Symbol nach T8c verworfen)
  AGGRO_SELF = 'ui-lfg-roleicon-dps',  -- DD/Heal-Modus: Mob, von dem du die Aggro hast
}

C.SYMBOL_LAYOUT = {
  MOB_SIZE = 16,               -- Symbol am Mob (links neben dem Balken)
  MOB_GAP = 4,                 -- Abstand Symbol → Balken
  PLAYER_SIZE = 24,            -- Symbol über dem Kopf des Mitspielers
  PLAYER_Y = 4,                -- Höhe über der freundlichen Nameplate
  LIST_SIZE = 14,              -- Symbol in der TWF-Liste
  LEVEL = 8,                   -- Frame-Ebene über der Nameplate (über dem TWF-Balken)
  RAID_INTERVAL = 1,           -- Sekunden zwischen Halter-Abfragen im Schlachtzug (gedrosselt)
  GROUP_SIZE = 20,             -- Symbol am Gruppenfenster des Mitspielers (immer zusätzlich)
  GROUP_X = -4,                -- Abstand vom rechten Rand des Gruppenfensters
  GROUP_LEVEL = 10,            -- Frame-Ebene über dem Gruppenfenster
  PARTY_FRAMES = 5,            -- CompactPartyFrameMember1..N
  RAID_FRAMES = 40,            -- CompactRaidFrame1..N (Schlachtzug, ohne Gruppen-Sortierung)
  RAID_GROUPS = 8,             -- CompactRaidGroupXMemberY (Schlachtzug, nach Gruppen sortiert)
  RAID_GROUP_SIZE = 5,
  PARTY_MEMBERS = 4,           -- PartyFrame.MemberFrame1..N (Rückfall, falls Blizzard umstellt)
}

-- Gemeinsamer Fensterstil (Einstellungsfenster + Hinweis-Popup) -------------------------

C.DIALOG = {
  PADDING = 12,                -- Innenabstand links/rechts/unten
  BG_ALPHA = 0.95,             -- Deckkraft des Fensterhintergrunds
  ROW_HIGHLIGHT_ALPHA = 0.08,  -- Aufhellen beim Drüberfahren
  BUTTON_H = 20,
  BUTTON_BG = { 0.2, 0.2, 0.22, 0.9 },
  BUTTON_BG_ACTIVE = { 0.45, 0.35, 0.05, 0.95 },  -- gewählter Knopf (z. B. Rolle)
  BUTTON_GAP = 6,
  CLOSE_SIZE = 24,             -- Schließen-Button (X)
  CLOSE_X = 2,                 -- Versatz des X nach rechts
  TOOLTIP_TEXT = { 1, 1, 1 },  -- Farbe des Erklärtexts im Tooltip
}

-- Hinweis-Popup: Prüfung der Spiel-Optionen (Hint.lua, Anforderung M) ----------------------

C.HINT = {
  NAME = 'ThreatWallForeverHintPopup',
  WIDTH = 380,
  OFFSET_Y = 100,                 -- über der Bildschirmmitte
  TOP_GAP = 10,                   -- Abstand unter der Kopfleiste
  BODY_SPACING = 3,               -- Zeilenabstand im Erklärtext
  LIST_GAP = 10,                  -- Abstand Erklärtext → Statusliste
  ROW_H = 20,                     -- Höhe einer Statuszeile
  ICON_SIZE = 16,                 -- ✔/✘-Symbol
  ICON_OK = 'Interface\\RaidFrame\\ReadyCheck-Ready',
  ICON_BAD = 'Interface\\RaidFrame\\ReadyCheck-NotReady',
  BUTTON_GAP_Y = 14,              -- Abstand Statusliste → Knöpfe
  OPTIONS_CATEGORY = 'Names',     -- Seite in den Spiel-Optionen
  SHOW_OPTIONS_BUTTON = true,     -- Knopf "Spiel-Optionen öffnen" zeigen (Entscheidung noch offen)
}

-- Spiel-Optionen, die TWF braucht (Anforderung M).
-- names:    mögliche CVar-Namen; der erste vorhandene zählt (Namen können sich in der Beta ändern)
-- want:     Sollwert
-- label/tip: Schlüssel in Locales.lua
-- neededBy: nur nötig, wenn diese Einstellung (db) an ist; fehlt sie, ist die Option immer nötig
C.GAME_OPTIONS = {
  { names = { 'nameplateShowEnemies' }, want = '1',
    label = 'GOPT_ENEMIES', tip = 'GOPT_ENEMIES_TIP' },
  { names = { 'nameplateShowFriendlyPlayers', 'nameplateShowFriends' }, want = '1',
    label = 'GOPT_FRIENDS', tip = 'GOPT_FRIENDS_TIP', neededBy = 'symbolMarks' },  -- Symbol-Markierung (Anforderung L)
}

-- Einstellungsfenster (Settings.lua) ------------------------------------------------------

C.SETTINGS = {
  NAME = 'ThreatWallForeverSettings',
  WIDTH = 300,                 -- Fensterbreite
  TOP_GAP = 8,                 -- Abstand unter der Kopfleiste
  ROW_H = 22,                  -- Höhe einer Optionszeile
  SECTION_H = 24,              -- Höhe einer Abschnitts-Überschrift
  SECTION_GAP = 6,             -- zusätzlicher Abstand vor einer Überschrift
  CHECK_SIZE = 16,             -- Kästchen der Checkbox
  CHECK_BORDER = 1,            -- Rahmenstärke des Kästchens in px
  CHECK_BG = { 0, 0, 0, 0.6 }, -- Innenfarbe des Kästchens
  LINE_ALPHA = 0.15,           -- Trennlinie unter Abschnitts-Überschriften
  ROLE_BUTTON_W = 70,          -- Breite der Rollen-Knöpfe
  TEXT_GAP = 8,                -- Abstand Kästchen → Text
  SLIDER_ROW_H = 38,           -- Höhe einer Schieberegler-Zeile (Text oben, Regler unten)
  SLIDER_H = 6,                -- Höhe der Bahn
  THUMB_W = 10, THUMB_H = 16,  -- Griff des Schiebereglers
  TRACK_COLOR = { 0.25, 0.25, 0.28, 1 },
  VALUE_W = 44,                -- Breite der Prozentanzeige
  PERCENT = 100,               -- Schieberegler-Wert ×100 = Prozentanzeige
}

-- Optionen im Einstellungsfenster (Reihenfolge = Anzeige-Reihenfolge).
-- type:   'section' Überschrift · 'role' zwei Rollen-Knöpfe · 'check' Checkbox ·
--         'slider' Schieberegler · 'button' Knopf
-- key:    gespeicherte Einstellung (db) · state: Laufzeit-Zustand (ns.state) statt db
-- label/tip: Schlüssel in Locales.lua · action: Funktion in ns, die der Knopf aufruft
-- min/max/step: Schieberegler-Bereich (Anzeige ×100 als Prozent)
C.OPTIONS = {
  { type = 'section', label = 'SEC_GENERAL' },
  { type = 'role', label = 'OPT_ROLE', tip = 'TIP_ROLE' },
  { type = 'check', key = 'locked', label = 'MENU_LOCK', tip = 'TIP_LOCK' },
  { type = 'check', key = 'minimap', label = 'MENU_MINIMAP', tip = 'TIP_MINIMAP' },

  { type = 'section', label = 'SEC_DISPLAY' },
  { type = 'check', key = 'combatOnly', label = 'MENU_COMBAT_ONLY', tip = 'TIP_COMBAT_ONLY' },
  { type = 'check', key = 'groupOnly', label = 'MENU_GROUP_ONLY', tip = 'TIP_GROUP_ONLY' },
  { type = 'check', key = 'showAll', label = 'MENU_SHOW_ALL', tip = 'TIP_SHOW_ALL' },
  { type = 'check', key = 'highlightTarget', label = 'MENU_HIGHLIGHT', tip = 'TIP_HIGHLIGHT' },
  { type = 'check', key = 'sound', label = 'MENU_SOUND', tip = 'TIP_SOUND' },

  { type = 'section', label = 'SEC_NAMEPLATES' },
  { type = 'check', key = 'twfNameplates', label = 'OPT_TWF_NAMEPLATES', tip = 'TIP_TWF_NAMEPLATES' },
  { type = 'check', key = 'symbolMarks', label = 'OPT_SYMBOL_MARKS', tip = 'TIP_SYMBOL_MARKS' },

  { type = 'section', label = 'SEC_LOOK' },
  { type = 'slider', key = 'alpha', label = 'MENU_BACKGROUND', tip = 'TIP_BACKGROUND', min = 0, max = 1, step = 0.1 },
  { type = 'slider', key = 'scale', label = 'MENU_SCALE', tip = 'TIP_SCALE', min = 0.8, max = 1.5, step = 0.1 },

  { type = 'section', label = 'SEC_TOOLS' },
  { type = 'check', state = 'testMode', label = 'MENU_TEST', tip = 'TIP_TEST' },
  { type = 'button', action = 'resetPlace', label = 'MENU_RESET', tip = 'TIP_RESET' },
}

-- Seite unter Optionen → AddOns
C.OPTIONS_PANEL = {
  TITLE_X = 16, TITLE_Y = -16,
  TEXT_Y = -12,                -- Abstand Text unter dem Titel
  BUTTON_W = 180, BUTTON_H = 24,
  BUTTON_Y = -16,              -- Abstand Knopf unter dem Text
}
