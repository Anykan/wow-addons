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
  NO_NAMEPLATES = '004', -- /twf dump: nichts Sichtbares zum Prüfen
  NO_THREAT_API = '005', -- dieser Client hat gar keine Bedrohungs-API
  LOCKED_HINT = '006',   -- Fenster verschieben versucht, obwohl gesperrt
  LOCKED_ON = '007',
  LOCKED_OFF = '008',
  ROLE_SET = '009',
  LOG_CLEARED = '010',
  LOADED = '013',
  HELP = '014',
  SETTING = '016',       -- Debug: Einstellung im Einstellungsfenster geändert
  OPTIONS_PANEL = '017', -- Debug: Seite unter Optionen → AddOns angelegt / fehlgeschlagen
  DEBUG_SET = '018',     -- /twf debug 1|0
  GAME_OPTIONS = '019',  -- Debug: Prüfung der Spiel-Optionen
  NAMEPLATES = '020',    -- Debug: TWF-Nameplates
  SYMBOLS = '021',       -- Debug: Aggro-Ziel am Mob (wer hält welchen Mob)
  PLATES = '022',        -- Debug: Aussehen pro Zustand (Tabelle im Reiter Nameplates)
}

-- Gespeicherte Einstellungen (SavedVariables): Standardwerte -----------------------

C.DEFAULTS = {
  shown = true,
  locked = false,
  scale = 1,
  minimized = false,
  width = 240,               -- Fensterbreite in px
  minRows = 5,               -- Fenster mindestens so hoch wie für 5 Zeilen (Anforderung W)
  maxRows = 10,              -- … und wächst mit der Zahl der Gegner bis 10 Zeilen
  alpha = 0.4,               -- Deckkraft des Hintergrunds (0–1)
  rowHeight = 20,            -- Zeilenhöhe in px
  textScale = 1,
  role = 'tank',             -- 'tank', 'dps' oder 'heal' (C.ROLES)
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
  symbolMarks = true,        -- Aggro-Ziel am Mob und in der Liste anzeigen (Anforderung L)
  alphaTarget = 1,           -- Deckkraft der TWF-Balken: dein Ziel (auch hinter Wänden) (Anforderung R)
  alphaOccluded = 0.3,       -- … Gegner hinter Wänden (außer dein Ziel); sonst gilt die Deckkraft des Zustands
  listThreat = true,         -- Live-Aggro-% vorn in jeder Listenzeile (Anforderung X)
  plateShared = true,        -- an = eine Tabelle für alle Modi, aus = je eine für Tank/DD/Heal (Anforderung V)
  -- plates (Aussehen pro Zustand) legt PlateStates.lua an, Standardwerte aus C.PLATE_STATES
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
  brown = { 0.6, 0.38, 0.15 },  -- anderer Tank hält den Mob (Anforderung T)
  foreign = { 0.22, 0.22, 0.22 }, -- Mob gehört einer anderen Gruppe (Anforderung U)
  blue = { 0.35, 0.55, 1 },     -- kämpft, aber nicht mit dir/deiner Gruppe
  grey = { 0.6, 0.6, 0.6 },     -- außerhalb des Kampfs
}
-- Rollen (Anforderung V: DD und Heal getrennt). Reihenfolge = Umschalten im Fensterkopf.
C.ROLES = { 'tank', 'dps', 'heal' }
C.ROLE_SHORT = { tank = 'T', dps = 'D', heal = 'H' }  -- Rollen-Knopf ohne Atlas
-- Rangfolge zum Sortieren (höher = schlimmer); braun zwischen grün und gelb
C.RANK = { red = 2, yellow = 1, brown = 0.5, green = 0 }

-- Textfarben im Zeilen-Tooltip (R, G, B)
C.TOOLTIP_COLOR = {
  red = { 1, 0.3, 0.3 },
  yellow = { 1, 0.8, 0.2 },
  green = { 0.3, 1, 0.3 },
  brown = { 0.85, 0.6, 0.35 },
}

C.TITLE_COLOR = { 1, 0.82, 0 }        -- Gold für Fenstertitel und Abschnitts-Überschriften
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
  ROLE = { tank = 'groupfinder-icon-role-large-tank', dps = 'groupfinder-icon-role-large-dps',
           heal = 'groupfinder-icon-role-large-heal' },
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
  MIN_W = 160, MAX_W = 500,         -- kleinste/größte Breite beim Aufziehen (die Höhe folgt den Zeilen, W)
  MIN_H = 0, MAX_H = 4000,          -- Höhe beim Aufziehen nicht begrenzen (wird nicht von Hand gezogen)
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
  PADDING = 4,                 -- Abstand der Zeilen zum Fensterrand
  SPACING = 2,                 -- Abstand zwischen zwei Zeilen
  LIST_VPAD = 8,               -- senkrechter Rand der Liste (oben + unten)
  BG_ALPHA = 0.05,             -- Zeilenhintergrund normal
  BG_ALPHA_TARGET = 0.18,      -- Zeilenhintergrund beim aktuellen Ziel
  DOT_SIZE = 12,               -- Ampelpunkt
  DOT_X = 6,
  PCT_X = 2,                   -- Live-Aggro-% ganz links (Anforderung X): Abstand zum Zeilenrand
  PCT_W = 34,                  -- Breite der Prozentanzeige (rechtsbündig, Platz für "100%")
  MARK_SIZE = 14,              -- Raid-Symbol
  SHOW_RAID_MARK = false,      -- Schlachtzugsymbol in der Liste zeigen. Aus, bis der Client-Bug behoben ist
                               -- (forever-bugs#166: Symbol-Nummer im Kampf geheim). Code bleibt in Marks.lua.
  GAP = 4,                     -- Abstand Punkt → Symbol → Name
  NAME_RIGHT = -6,
  -- Pulsierender Rahmen um die Zeile deines Ziels (ns.createGlow)
  GLOW = {
    COLOR = { 0.55, 0.85, 1 }, -- hell blau-weiß, hebt sich von der Ampel ab
    EDGE = 2,                  -- Rahmenstärke in px
    INSET = 0,                 -- Rahmen liegt auf dem Zeilenrand
    ALPHA_FROM = 1,            -- Pulsieren: Deckkraft von …
    ALPHA_TO = 0.4,            -- … bis
    DURATION = 0.7,            -- Sekunden pro Pulsschritt
  },
}

-- Testzeilen (/twf test): Name, Farbe, Raid-Symbol, Aggro-Symbol (Schlüssel in C.SYMBOLS), Aggro-%
C.TEST_ROWS = {
  { 'Grillmaster', 'red', 8, 'HEALER', 100 },
  { 'Adds Rechts', 'yellow', 3, 'DAMAGER', 87 },
  { 'Adds Links', 'yellow', nil, nil, 64 },
}

-- Dropdown-Menü (Minimap-Rechtsklick) -----------------------------------------------------

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

-- Rahmen (Backdrop) für das Dropdown-Menü und den Rollen-Button
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
  OCCLUDED_ALPHA = 0.5,        -- Nameplate gilt als "hinter einer Wand", wenn Blizzards Deckkraft darunter liegt.
                               -- Gemessen: frei 0.6 (Ziel 1.0), verdeckt 0.24 (Ziel 0.4). Anforderung O.
  NAME_ONLY_FULL_ALPHA = true, -- Nur-Name-Zustand: volle Deckkraft. Blizzard dimmt Nameplates, die nicht dein Ziel
                               -- sind; dadurch wirkte das Rot blasser als der Name aus der Ferne.
  NAME_ONLY_Y = 0,             -- Nur-Name-Zustand: Name sitzt dort, wo sonst der Balken ist (Mitte);
                               -- hier nach oben (+) oder unten (−) nachstellen, bis er zur Fernansicht passt
  PCT_X = -3,                  -- Abstand der Prozentanzeige vom rechten Balkenrand
  RAID_ICON_Y = 2,             -- Schlachtzugsymbol über dem Namen (nur Name sichtbar): Abstand nach oben
  RAID_ICON_GAP = 4,           -- Schlachtzugsymbol links vor dem Balken: Abstand zum Balken
  PCT_LAYER = 7,               -- Zeichen-Unterebene der Prozentzahl (über dem Rahmen)
  PCT_FORMAT = '%.0f%%',       -- Anzeige des Lebens in Prozent
  THREAT_PCT_X = 3,            -- Abstand der Aggro-Prozentanzeige vom linken Balkenrand (Anforderung P)
  THREAT_PCT_FORMAT = '%.0f%%', -- Anzeige der eigenen Aggro in Prozent (100 % = du hast bzw. ziehst die Aggro)
  -- Blinkender Rahmen (Anforderung V): ob und in welcher Farbe, steht pro Zustand in der Tabelle
  -- (C.PLATE_STATES bzw. Einstellungen). Stärke und Tempo gelten für alle Zustände; so gebaut,
  -- dass sie später pro Zustand einstellbar werden können.
  BLINK = {
    COLOR = { 1, 0.1, 0.1 },   -- Startfarbe, wird pro Zustand überschrieben
    EDGE = 3,                  -- Rahmenstärke in px
    INSET = 5,                 -- Rahmen liegt außen um den Balkenrahmen (BORDER_INSET 2 + EDGE)
    ALPHA_FROM = 1,            -- Blinken: Deckkraft von …
    ALPHA_TO = 0.1,            -- … bis fast aus
    DURATION = 0.3,            -- Sekunden pro Blinkschritt
  },
  ADD_DELAY = 0,               -- Sekunden Verzögerung nach "Nameplate erscheint" (0 = nächster Frame; Blizzard richtet sie erst ein)
  WORLD_DELAY = 1,             -- Sekunden nach Betreten der Welt bis zur kompletten Neuprüfung
  -- Füllung im Stil von Blizzards Zauberbalken: entsättigt und in der Farbe des Zustands getönt,
  -- damit jede Farbe frei wählbar ist (Anforderung V; vorher feste Atlanten für Grün/Gelb/Rot)
  FILL = 'ui-castingbar-filling-standard',
  BAR_BG = 'ui-castingbar-background',
  BAR_BORDER = 'ui-castingbar-frame',
  PLAIN_FILL = 'Interface\\TargetingFrame\\UI-StatusBar',  -- Rückfall, falls die Atlanten fehlen
}

-- Aggro-Ziel am Mob (Symbols.lua, Anforderung L) -------------------------------------------

-- Symbolsatz: hier austauschen, sonst nirgends. Jeder Eintrag ist ein Atlas-Name oder ein
-- Dateipfad, oder eine Tabelle { texture = ..., coords = { links, rechts, oben, unten } }
-- für Dateien mit mehreren Symbolen in einem Bild.
C.SYMBOLS = {
  TANK = 'ui-lfg-roleicon-tank',
  HEALER = 'ui-lfg-roleicon-healer',
  DAMAGER = 'ui-lfg-roleicon-dps',
  NONE = 'ui-lfg-roleicon-dps',        -- Halter ohne gesetzte Rolle
}

C.SYMBOL_LAYOUT = {
  ICON_SIZE = 20,              -- Symbol in der Zeile über dem Mobnamen
  LINE_FONT = 'GameFontHighlight',  -- Schrift des Spielernamens (größer: 'GameFontHighlightLarge', kleiner: 'GameFontHighlightSmall')
  ICON_GAP = 3,                -- Abstand Symbol → Spielername
  LINE_Y = 1,                  -- Abstand der Zeile über dem Mobnamen
  LIST_SIZE = 18,              -- Symbol in der TWF-Liste (Zeilenhöhe ist 20)
  LIST_GAP = 5,                -- Abstand Symbol → Mobname in der Liste
  LEVEL = 8,                   -- Frame-Ebene über der Nameplate (über dem TWF-Balken)
  RAID_INTERVAL = 1,           -- Sekunden zwischen Halter-Abfragen im Schlachtzug (gedrosselt)
  NAME_FALLBACK_COLOR = { 1, 1, 1 },  -- Spielername, falls die Klassenfarbe nicht lesbar ist
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
  SHOW_OPTIONS_BUTTON = true,     -- Knopf "Spiel-Optionen öffnen" zeigen (bleibt, Nutzer-Entscheid 2026-10-13)
}

-- Spiel-Optionen, die TWF braucht (Anforderung M).
-- names:    mögliche CVar-Namen; der erste vorhandene zählt (Namen können sich in der Beta ändern)
-- want:     Sollwert
-- label/tip: Schlüssel in Locales.lua
-- neededBy: nur nötig, wenn diese Einstellung (db) an ist; fehlt sie, ist die Option immer nötig
-- (Freundliche Nameplates werden seit 2026-10-12 nicht mehr verlangt. Auf Forever hieße die CVar
--  nameplateShowFriendlyPlayers, siehe TESTS-MACHBARKEIT.md T9.)
C.GAME_OPTIONS = {
  { names = { 'nameplateShowEnemies' }, want = '1',
    label = 'GOPT_ENEMIES', tip = 'GOPT_ENEMIES_TIP' },
}

-- Einstellungsfenster (Settings.lua) ------------------------------------------------------

C.SETTINGS = {
  NAME = 'ThreatWallForeverSettings',
  WIDTH = 760,                 -- Fensterbreite (gleich für alle Reiter; Höhe = höchster Reiter)
  TOP_GAP = 8,                 -- Abstand unter der Kopfleiste
  ROW_H = 22,                  -- Höhe einer Optionszeile
  SECTION_H = 24,              -- Höhe einer Abschnitts-Überschrift
  SECTION_GAP = 6,             -- zusätzlicher Abstand vor einer Überschrift
  CHECK_SIZE = 16,             -- Kästchen der Checkbox
  CHECK_BORDER = 1,            -- Rahmenstärke des Kästchens in px
  CHECK_BG = { 0, 0, 0, 0.6 }, -- Innenfarbe des Kästchens
  LINE_ALPHA = 0.15,           -- Trennlinie unter Abschnitts-Überschriften
  ROLE_BUTTON_W = 54,          -- Breite der Rollen-Knöpfe (drei nebeneinander)
  TEXT_GAP = 8,                -- Abstand Kästchen → Text
  SLIDER_ROW_H = 38,           -- Höhe einer Schieberegler-Zeile (Text oben, Regler unten)
  SLIDER_H = 6,                -- Höhe der Bahn
  THUMB_W = 10, THUMB_H = 16,  -- Griff des Schiebereglers
  TRACK_COLOR = { 0.25, 0.25, 0.28, 1 },
  VALUE_W = 44,                -- Breite der Prozentanzeige
  PERCENT = 100,               -- Schieberegler-Wert ×100 = Prozentanzeige
  -- Reiter (0.3): alle Reiter in derselben Fenstergröße, nur der Inhalt wechselt
  TABS = {
    { key = 'general', label = 'TAB_GENERAL' },
    { key = 'nameplates', label = 'TAB_NAMEPLATES' },
  },
  TAB_W = 110,                 -- Breite eines Reiter-Knopfs
  TAB_GAP = 4,                 -- Abstand zwischen den Reitern
  TAB_BOTTOM_GAP = 6,          -- Abstand unter der Reiterleiste
}

-- Reiter "Nameplates": Aussehen pro Zustand (Anforderung V) -----------------------------------
-- Eine Spalte pro Zustand der TWF-Nameplate. Hier stehen die Standardwerte ("Farben zurücksetzen").
-- color = Balkenfarbe · alpha = Deckkraft (Ziel und hinter Wänden: Regler unter "Allgemein") ·
-- blink = blinkender Rahmen · frame = Rahmenfarbe · show = Balken zeigen (aus = nur der Name) ·
-- threat = eigene Aggro in % links im Balken (Anforderung P) · threatColor = Textfarbe der Aggro-% ·
-- tankOnly = Zustand gibt es nur im Tank-Modus (in den Tabellen DD/Heal ausgegraut) ·
-- noThreat = Zustand hat keine Bedrohung (außerhalb des Kampfs): Zeilen mit threatRow ausgegraut
local ALARM_RED = { 1, 0.1, 0.1 }
local ALARM_YELLOW = { 1, 0.85, 0.1 }
local WHITE = { 1, 1, 1 }
C.PLATE_STATES = {
  { key = 'green', label = 'STATE_GREEN', tip = 'TIP_STATE_GREEN', color = C.COLOR.green, alpha = 0.6, frame = ALARM_RED, show = true, threat = true, threatColor = WHITE },
  { key = 'yellow', label = 'STATE_YELLOW', tip = 'TIP_STATE_YELLOW', color = C.COLOR.yellow, alpha = 0.6, blink = true, frame = ALARM_RED, show = true, threat = true, threatColor = WHITE },
  { key = 'red', label = 'STATE_RED', tip = 'TIP_STATE_RED', color = C.COLOR.red, alpha = 0.6, blink = true, frame = ALARM_RED, show = true, threat = true, threatColor = WHITE },
  { key = 'brown', label = 'STATE_BROWN', tip = 'TIP_STATE_BROWN', color = C.COLOR.brown, alpha = 0.6, frame = ALARM_RED, show = true, tankOnly = true, threat = true, threatColor = WHITE },
  { key = 'pull', label = 'STATE_PULL', tip = 'TIP_STATE_PULL', color = C.COLOR.yellow, alpha = 0.6, blink = true, frame = ALARM_YELLOW, show = true, tankOnly = true, threat = true, threatColor = WHITE },
  { key = 'blue', label = 'STATE_BLUE', tip = 'TIP_STATE_BLUE', color = C.COLOR.blue, alpha = 0.6, frame = ALARM_RED, show = true, threat = true, threatColor = WHITE },
  { key = 'grey', label = 'STATE_GREY', tip = 'TIP_STATE_GREY', color = C.COLOR.grey, alpha = 0.6, frame = ALARM_RED, show = false, threat = false, threatColor = WHITE, noThreat = true },
  { key = 'foreign', label = 'STATE_FOREIGN', tip = 'TIP_STATE_FOREIGN', color = C.COLOR.foreign, alpha = 0.6, frame = ALARM_RED, show = true, threat = true, threatColor = WHITE },
}
-- Sätze: 'shared' = eine Tabelle für alle Modi, sonst je Rolle (C.ROLES)
C.PLATE_SETS = { 'shared', 'tank', 'dps', 'heal' }
C.PLATE_SET_LABEL = { shared = 'SET_SHARED', tank = 'ROLE_TANK', dps = 'ROLE_DPS', heal = 'ROLE_HEAL' }
C.PLATE_VERSION = 2          -- Stand der gespeicherten Tabelle (Umstieg von 0.2; 2 = Aggro-% pro Zustand)
-- Zeilen der Tabelle (Reihenfolge = Anzeige); Rahmenfarbe nur sichtbar, wenn Blinken an ist
C.PLATE_ROWS = {
  -- kind: 'color' Farbfeld · 'alpha' Deckkraft · 'check' Checkbox; field = Wert im Zustand;
  -- needs = Zeile nur sichtbar, wenn dieser Wert an ist (z. B. Rahmenfarbe nur bei Blinken)
  { key = 'color', kind = 'color', field = 'color', label = 'ROW_COLOR', tip = 'TIP_ROW_COLOR' },
  { key = 'alpha', kind = 'alpha', field = 'alpha', label = 'ROW_ALPHA', tip = 'TIP_ROW_ALPHA' },
  { key = 'blink', kind = 'check', field = 'blink', label = 'ROW_BLINK', tip = 'TIP_ROW_BLINK' },
  { key = 'frame', kind = 'color', field = 'frame', needs = 'blink', label = 'ROW_FRAME', tip = 'TIP_ROW_FRAME' },
  { key = 'threat', kind = 'check', field = 'threat', threatRow = true, label = 'ROW_THREAT', tip = 'TIP_ROW_THREAT' },
  { key = 'threatColor', kind = 'color', field = 'threatColor', needs = 'threat', threatRow = true, label = 'ROW_THREAT_COLOR', tip = 'TIP_ROW_THREAT_COLOR' },
  { key = 'show', kind = 'check', field = 'show', label = 'ROW_SHOW', tip = 'TIP_ROW_SHOW' },
}
C.PLATE_TABLE = {
  LABEL_W = 100,               -- Breite der linken Spalte mit den Zeilennamen
  COL_W = 78,                  -- Breite einer Zustands-Spalte
  TOP_H = 28,                  -- Zeile mit Checkbox "Farben gleich" und Knopf "Farben zurücksetzen"
  RESET_W = 150,               -- Breite des Knopfs "Farben zurücksetzen"
  TITLE_H = 20,                -- Überschrift einer Tabelle (Alle Modi / Tank / DD / Heal)
  HEAD_H = 30,                 -- Kopfzeile (Zustandsname, bis zwei Zeilen)
  ROW_H = 22,                  -- Höhe einer Tabellenzeile
  TABLE_GAP = 6,               -- Abstand zwischen zwei Tabellen
  SWATCH = 16,                 -- Größe eines Farbfelds
  SWATCH_BORDER = 1,           -- Rahmen ums Farbfeld
  STRIPE_ALPHA = 0.05,         -- jede zweite Zeile leicht aufgehellt
  DISABLED_ALPHA = 0.3,        -- ausgegraute Spalte (Zustand gibt es in diesem Modus nicht)
  EMPTY = '–',                 -- Anzeige "nichts"
  ACTIVE_COLOR = { 0.4, 1, 0.4 }, -- Hinweis "(aktiv)" an der Tabelle der gespielten Rolle
}
-- Popup mit Schieberegler für die Deckkraft einer Zelle
C.ALPHA_POPUP = {
  NAME = 'ThreatWallForeverAlphaPopup',
  WIDTH = 200,
  HEIGHT = 74,
  MIN = 0, MAX = 1, STEP = 0.05,  -- 0–100 % in 5-%-Schritten
  OK_W = 50,
}

-- Optionen im Reiter "Allgemein" (Reihenfolge = Anzeige-Reihenfolge).
-- type:   'section' Überschrift · 'role' drei Rollen-Knöpfe · 'check' Checkbox ·
--         'slider' Schieberegler · 'button' Knopf · 'column' beginnt eine neue Spalte
--         (Spalten teilen die Fensterbreite gleich auf)
-- key:    gespeicherte Einstellung (db) · state: Laufzeit-Zustand (ns.state) statt db
-- label/tip: Schlüssel in Locales.lua · action: Funktion in ns, die der Knopf aufruft
-- min/max/step: Schieberegler-Bereich (Anzeige ×100 als Prozent; count = true zeigt die Zahl selbst)
-- keepBelow/keepAbove: anderer Schlüssel, der mitgezogen wird, damit min ≤ max bleibt
C.OPTIONS = {
  { type = 'section', label = 'SEC_GENERAL' },
  { type = 'role', label = 'OPT_ROLE', tip = 'TIP_ROLE' },
  { type = 'check', key = 'locked', label = 'MENU_LOCK', tip = 'TIP_LOCK' },
  { type = 'check', key = 'minimap', label = 'MENU_MINIMAP', tip = 'TIP_MINIMAP' },

  { type = 'section', label = 'SEC_DISPLAY' },
  { type = 'check', key = 'combatOnly', label = 'MENU_COMBAT_ONLY', tip = 'TIP_COMBAT_ONLY' },
  { type = 'check', key = 'groupOnly', label = 'MENU_GROUP_ONLY', tip = 'TIP_GROUP_ONLY' },
  { type = 'check', key = 'showAll', label = 'MENU_SHOW_ALL', tip = 'TIP_SHOW_ALL' },
  { type = 'check', key = 'listThreat', label = 'OPT_LIST_THREAT', tip = 'TIP_LIST_THREAT' },
  { type = 'check', key = 'highlightTarget', label = 'MENU_HIGHLIGHT', tip = 'TIP_HIGHLIGHT' },
  { type = 'check', key = 'sound', label = 'MENU_SOUND', tip = 'TIP_SOUND' },

  { type = 'column' },
  { type = 'section', label = 'SEC_NAMEPLATES' },
  { type = 'check', key = 'twfNameplates', label = 'OPT_TWF_NAMEPLATES', tip = 'TIP_TWF_NAMEPLATES' },
  { type = 'check', key = 'symbolMarks', label = 'OPT_SYMBOL_MARKS', tip = 'TIP_SYMBOL_MARKS' },
  { type = 'slider', key = 'alphaTarget', label = 'OPT_ALPHA_TARGET', tip = 'TIP_ALPHA_TARGET', min = 0.1, max = 1, step = 0.1 },
  { type = 'slider', key = 'alphaOccluded', label = 'OPT_ALPHA_OCCLUDED', tip = 'TIP_ALPHA_OCCLUDED', min = 0, max = 1, step = 0.1 },

  { type = 'column' },
  { type = 'section', label = 'SEC_WINDOW' },
  { type = 'slider', key = 'minRows', label = 'OPT_MIN_ROWS', tip = 'TIP_MIN_ROWS', min = 1, max = 15, step = 1,
    count = true, keepBelow = 'maxRows' },
  { type = 'slider', key = 'maxRows', label = 'OPT_MAX_ROWS', tip = 'TIP_MAX_ROWS', min = 1, max = 30, step = 1,
    count = true, keepAbove = 'minRows' },
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
