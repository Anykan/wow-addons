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
C.PREFIX = '|cff33ff99Threat Wall Forever:|r '

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
  MERGED = '023',        -- Debug: doppelte Listenzeile zusammengeführt (Bug B2)
  BAR = '024',           -- Debug: Fokus-/Ziel-Leiste (andocken, Symbole)
  VERSION = '025',       -- Debug: Versionscheck (gesendet)
}

-- Gespeicherte Einstellungen (SavedVariables): Standardwerte -----------------------

C.DEFAULTS = {
  shown = true,
  locked = false,
  focusBar = false,          -- Fokus-Mauer (Leiste.lua, Anforderung AC); Standard aus seit 0.5.2
  targetBar = true,          -- Ziel-Mauer (Leiste.lua, Anforderung AC)
  focusBarCombat = false,    -- Fokus-Mauer nur im Kampf sichtbar
  targetBarCombat = false,   -- Ziel-Mauer nur im Kampf sichtbar
  focusBarGroup = false,     -- Fokus-Mauer nur in Gruppe/Schlachtzug sichtbar
  targetBarGroup = false,    -- Ziel-Mauer nur in Gruppe/Schlachtzug sichtbar
  focusBarInstance = false,  -- Fokus (Mauer/Klassik) nur in Instanzen (I11)
  targetBarInstance = false, -- Ziel (Mauer/Klassik) nur in Instanzen (I11)
  highlightColor = { 0.55, 0.85, 1 },  -- Farbe des pulsierenden Rahmens um die Zeile deines Ziels
  focusBarAlpha = 1,         -- Deckkraft der Fokus-Mauer
  targetBarAlpha = 1,        -- Deckkraft der Ziel-Mauer
  barClassIcons = false,     -- Leisten: Klassen- statt Rollensymbole auf dem Turm (Klick auf den Halter)
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
  instanceOnly = false,      -- Liste nur in Instanzen (Dungeon/Schlachtzug, I11)
  groupOnly = false,         -- aus: Liste nach Neuinstallation auch solo sichtbar (0.5.2)
  showAll = false,
  highlightTarget = true,    -- pulsierender Rahmen um die Zeile deines aktuellen Ziels
  sound = true,
  soundId = 8959,            -- Warnton (eine Nummer aus C.ALERT_SOUNDS)
  soundChannel = 'SFX',      -- Kanal des Warntons: 'SFX' (Effekte) oder 'Master' (C.SOUND_CHANNELS)
  edgeFlash = false,         -- Bildschirmrand blitzt einmal auf, zusammen mit dem Warnton (I10)
  edgeColor = { 1, 0.1, 0.1 },
  edgeAlpha = 0.8,
  alertGroupOnly = false,    -- Warnton und Bildschirmrand nur in einer Gruppe (I10, Nutzer 2026-11-08)
  paladinRF = 'on',          -- Paladin im Tank-Modus: Zorn der Gerechtigkeit überwachen (I24): 'on'/'off'
  minimap = true,
  minimapAngle = 200,        -- Position des Minimap-Buttons in Grad
  debug = false,
  twfNameplates = true,      -- an = TWF-Nameplates statt Blizzard (Anforderung J)
  symbolMarks = true,        -- Aggro-Ziel am Mob und in der Liste anzeigen (Anforderung L)
  alphaTarget = 1,           -- Deckkraft der TWF-Balken: dein Ziel (auch hinter Wänden) (Anforderung R)
  alphaOccluded = 0.3,       -- … Gegner hinter Wänden (außer dein Ziel); sonst gilt die Deckkraft des Zustands
  listThreat = true,         -- Live-Aggro-% vorn in jeder Listenzeile (Anforderung X)
  roleSync = false,          -- an = TWF-Rolle folgt der Gruppenrolle (Anforderung AB)
  healthPct = true,          -- an = Leben in % rechts im Balken, aus = Restleben als Zahl (Anforderung AA)
  plateLead = false,         -- Tank-Modus: Vorsprung vor Platz 2 statt Aggro-% im Balken (Anforderung Z)
  listLead = true,           -- Tank-Modus: Vorsprung statt Aggro-% in der Liste (Anforderung Z); Standard an seit 0.5.2
  plateShared = true,        -- an = eine Tabelle für alle Modi, aus = je eine für Tank/DD/Heal (Anforderung V)
  plateDebuffs = 'off',      -- Debuffleiste an TWF-Nameplates: 'off', 'on' (C.DEBUFF_MODES, I23)
  plateDebuffPos = 'above',  -- Debuffleiste über oder unter dem Balken: 'above', 'below' (I25)
  plateDebuffScale = 1,      -- Größe der Debuff-Symbole (I25)
  -- Ziel/Fokus: Mauer oder Klassik-Fenster (Anforderung AI, Klassik.lua); je Fenster eigene Werte
  targetStyle = 'wall',      -- 'wall' oder 'classic' (C.BAR_STYLES)
  focusStyle = 'wall',
  targetClassicMinRows = 1,  focusClassicMinRows = 1,     -- Nutzer 2026-11-06
  targetClassicMaxRows = 5,  focusClassicMaxRows = 5,
  targetClassicAlpha = 0.4,  focusClassicAlpha = 0.4,    -- Deckkraft des Hintergrunds
  targetClassicScale = 1,    focusClassicScale = 1,
  targetClassicThreat = true, focusClassicThreat = true,  -- Aggro-% rechts in der Zeile
  targetClassicLead = true,  focusClassicLead = true,     -- Halter: Vorsprung statt Aggro-%
  targetClassicPets = false, focusClassicPets = false,    -- Begleiter als eigene Zeilen
  -- classicPos (Position/Breite je Fenster) legt Klassik.lua an
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

-- Warnton bei Verschlechterung: Auswahl im Reiter Allgemein (Nutzer 2026-11-08, im Spiel
-- probegehört). Reihenfolge = Blättern mit < >; label = Name in Locales.
C.ALERT_SOUNDS = {
  { id = 8959, label = 'SOUND_RAID_WARNING' },
  { id = 12867, label = 'SOUND_ALARM_1' },
  { id = 12889, label = 'SOUND_ALARM_2' },
  { id = 12197, label = 'SOUND_BOSS_EMOTE' },
  { id = 15273, label = 'SOUND_GM' },
  { id = 44292, label = 'SOUND_HORN' },
  { id = 73280, label = 'SOUND_FANFARE_1' },
  { id = 73281, label = 'SOUND_FANFARE_2' },
}
C.SOUND_CHANNELS = { 'SFX', 'Master' }
C.SOUND_CHANNEL_LABEL = { SFX = 'CHANNEL_SFX', Master = 'CHANNEL_MASTER' }
C.SOUND_PICKER = { ARROW_W = 20, NAME_W = 112 }
-- Bildschirmrand (I10, Nutzer 2026-11-08 im Test-Addon ausgesucht): vier Farbverläufe an den
-- Kanten, blitzt einmal auf (ein- und ausblenden in DURATION Sekunden)
C.EDGE_FLASH = { WIDTH = 120, DURATION = 1, STRATA = 'FULLSCREEN' }

-- Klassenfähigkeiten (I24, Nutzer 2026-11-08): Paladin-Tank, Zorn der Gerechtigkeit.
-- Im Kampf sind die eigenen Auren für Addons gesperrt (getestet 2026-11-08) → außerhalb des
-- Kampfs lesen, Ablaufzeit merken, im Kampf nach der Uhr weiterzählen.
C.ONOFF = { 'off', 'on' }
C.ONOFF_LABEL = { off = 'DEBUFFS_OFF', on = 'DEBUFFS_ON' }   -- "Aus" / "An"
C.CLASS_ABILITIES = {
  RF_IDS = { 25780 },            -- Zorn der Gerechtigkeit (Forever, Test 2026-11-08)
  MARKS = { 20, 10, 5, 4, 3, 2, 1 },   -- Meldung bei so vielen Minuten Rest (je einmal)
  INTERVAL = 1,                  -- Sekunden zwischen zwei Prüfungen
  REBUFF_TOLERANCE = 5,          -- Ablaufzeit springt um mehr als so viele Sekunden → neu gebufft
  COLOR = { r = 1, g = 0.6, b = 0.1 },   -- Farbe der Meldung in der Bildschirmmitte
  RF_SOUND = 36609,              -- Ton zu jeder Zorn-Meldung (PvP-Alarm, vom Nutzer gewählt 2026-11-08)
}

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
-- Gruppenrolle des Spiels → TWF-Rolle (Rollen-Sync, Anforderung AB)
C.ROLE_FROM_GROUP = { TANK = 'tank', HEALER = 'heal', DAMAGER = 'dps' }
-- Rangfolge zum Sortieren (höher = schlimmer); braun zwischen grün und gelb
C.RANK = { red = 2, yellow = 1, brown = 0.5, green = 0 }
-- Debuffleiste an TWF-Nameplates (I23). Reihenfolge = Knöpfe im Reiter Nameplates.
-- Nur Aus/An (Nutzer 2026-11-06): Blizzards Liste zeigt nur eigene Effekte, "Alle" ging nicht.
C.DEBUFF_MODES = { 'off', 'on' }
C.DEBUFF_MODE_LABEL = { off = 'DEBUFFS_OFF', on = 'DEBUFFS_ON' }
-- Position der Debuffleiste (I25, Spieler-Anfrage 2026-11-08)
C.DEBUFF_POS = { 'above', 'below' }
C.DEBUFF_POS_LABEL = { above = 'DEBUFF_POS_ABOVE', below = 'DEBUFF_POS_BELOW' }
-- Blizzard setzt Position und Größe seiner Leiste nach dem Kampf zurück (Test 2026-11-08) →
-- TWF setzt beides in jedem Takt neu. GetPoint ist auf Nameplates gesperrt, deshalb kann TWF
-- Blizzards Platz nicht auslesen; "Über" nach einem Verschieben = über dem Namen (wie Blizzard).
C.DEBUFF_BAR = {
  GAP = 2,                     -- Abstand zum Balken bzw. Namen
  BELOW_Y = 8,                 -- "Unter": so viel tiefer, damit Blizzards Zauberleiste des Gegners frei bleibt (Nutzer 2026-11-08)
  PREVIEW_ICONS = {            -- Beispiel-Symbole in der Vorschau (Rüstung zerreißen, Richturteil, Fluch)
    'Interface/Icons/Ability_Warrior_Sunder',
    'Interface/Icons/Spell_Holy_HolySmite',
    'Interface/Icons/Spell_Shadow_CurseOfSargeras',
  },
  PREVIEW_SIZE = 18,           -- Symbolgröße in der Vorschau bei 100 %
  PREVIEW_SPACING = 2,         -- Abstand zwischen den Symbolen
}
-- Darstellung Ziel/Fokus (Anforderung AI). Reihenfolge = Knöpfe im Reiter Ansicht.
C.BAR_STYLES = { 'wall', 'classic' }
C.BAR_STYLE_LABEL = { wall = 'STYLE_WALL', classic = 'STYLE_CLASSIC' }

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
  FILE_PREFIX = 'Interface\\TargetingFrame\\UI-RaidTargetingIcon_', -- Einzeldateien _1.._8 (Utils.createRaidMark)
}

-- Fenster ----------------------------------------------------------------------------

C.WINDOW = {
  NAME = 'ThreatWallForeverFrame',
  -- Startposition (Neuinstallation, "Alles zurücksetzen", /twf reset): obere linke Ecke relativ
  -- zur Bildschirmmitte. Vom Nutzer 2026-11-06 festgelegt (Liste, Ziel, Fokus nebeneinander auf
  -- einer Höhe; gemessen bei 2100 x 1181), siehe C.CLASSIC.DEFAULT_POS.
  DEFAULT_X = -433, DEFAULT_Y = -134,
  MIN_W = 160, MAX_W = 500,         -- kleinste/größte Breite beim Aufziehen (die Höhe folgt den Zeilen, W)
  MIN_H = 0, MAX_H = 4000,          -- Höhe beim Aufziehen nicht begrenzen (wird nicht von Hand gezogen)
  HEIGHT_TOLERANCE = 0.5,           -- Abweichung in px, ab der die Fensterhöhe neu gesetzt wird (Rundung)
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
  -- Zeile = Balken wie an den Nameplates (Anforderung AG): Farbe des Zustands, Füllung = Leben
  BAR_INSET = 3,               -- Balken liegt so weit innerhalb der Zeile (Platz für den Rahmen)
  TEXT_X = 3,                  -- Abstand des ersten Elements zum Balkenanfang
  PCT_W = 40,                  -- Breite der Prozentanzeige (rechtsbündig, Platz für "1000%")
  MARK_SIZE = 14,              -- Schlachtzugsymbol (Balken-Trick, Utils.lua)
  GAP = 4,                     -- Abstand Symbol → % → Rollensymbol → Name
  NAME_RIGHT = -4,
  TEXT_LAYER = 7,              -- Zeichen-Unterebene der Texte (über dem Balkenrahmen)
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

-- Testzeilen (/twf test): Name, Farbe, Raid-Symbol, Aggro-Symbol (Schlüssel in C.SYMBOLS), Aggro-%, Leben-%
C.TEST_ROWS = {
  { 'Grillmaster', 'red', 8, 'HEALER', 100, 72 },
  { 'Adds Rechts', 'yellow', 3, 'DAMAGER', 87, 45 },
  { 'Adds Links', 'yellow', nil, nil, 64, 90 },
}

-- Rahmen (Backdrop) für den Rollen-Button
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
  HEALTH_NUM_FORMAT = '%d',    -- Anzeige des Restlebens als Zahl (geheim → nur weitergereicht, nicht kürzbar)
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

-- Bedrohungs-Leisten Fokus / Ziel (Leiste.lua, Anforderung AC; Design = prototyp/) ----------

C.BAR = {
  ORDER = { 'focus', 'target' },     -- Aufbau- und Andock-Reihenfolge
  DEFAULT_DOCK = { focus = 'side', target = 'bar' },  -- Fokus an der Seitenleiste, Ziel daneben
  FREE_X = { focus = 300, target = 240 },             -- ohne Seitenleiste: Startposition (x zur Mitte)
  UNITS = { 'player', 'party1', 'party2', 'party3', 'party4', 'pet' },
  FALLBACK_W = 42, FALLBACK_H = 480, -- ohne Seitenleiste
  FALLBACK_BG = { 0.06, 0.07, 0.09, 0.85 },
  FALLBACK_BORDER = { 0.5, 0.42, 0.33, 1 },
  GAP = 6,                           -- Abstand zur Leiste, falls keiner messbar ist
  SIDE_EDGE_PX = 150,                -- Seitenleiste zählt nur, wenn ihre rechte Kante so nah am rechten Rand ist (Fix 0.5.1)
  SIDE_PAIR_PX = 30,                 -- linke Seitenleiste zählt, wenn sie so nah neben der rechten steht
  SIDE_COLUMN_PX = 4,                -- Knopf 1 und 12 in derselben Spalte (= senkrechte Leiste)
  EDGE_X = 4,                        -- ohne Seitenleiste: Abstand der Mauer zum rechten Rand
  MINIMAP_GAP = 8,                   -- ohne Seitenleiste: Abstand unter der Minikarte
  -- ohne passende Seitenleiste: Knopfgröße und Rahmen von hier (erste vorhandene Aktionsleiste)
  SKIN_SOURCES = { 'MultiBarRightButton', 'MultiBarLeftButton', 'MultiBarBottomLeftButton', 'MultiBarBottomRightButton', 'ActionButton' },
  SNAP_PX = 15,                      -- magnetisch: so nah rastet eine Leiste ein
  MEASURE_DELAY = 1,                 -- s nach dem Login messen (Seitenleisten stehen dann)
  REMEASURE = { 3, 8, 15 },          -- s nach dem Login neu aufbauen (echter Spielstart ist langsamer als /reload)
  REFRESH_DELAY = 0.3,               -- s warten nach Leiste ein/aus, Bearbeitungsmodus, UI-Skalierung
  SKIN_SLICE = 14,                   -- Randbreite der Knopf-Grafik (Neun-Teile-Ränder)
  NUDGE_X = -3,                      -- Inhalt mittig im Knopf-Rahmen (Grafik rechts dicker, getestet)
  FRAME_PAD = 9,                     -- Knopf-Rand (~7 px) + 2 px Luft zum Turm
  TITLE_H = 18, PCT_H = 14, MERLON_H = 11,
  BRICK_H = 7,
  STONE_A = { 0.42, 0.35, 0.28 }, STONE_B = { 0.47, 0.39, 0.31 },
  MORTAR = { 0.14, 0.11, 0.09 }, CAP = { 0.58, 0.49, 0.39 },
  GLOW = { 1, 0.27, 0.16 }, GLOW_ALPHA = 0.55, GLOW_REACH = 0.4, GLOW_STEPS = 14,
  ROLE_ICON_VISIBLE = 0.74,          -- sichtbarer Kreis des Rollensymbols im Feld
  HALO_PX = { 6, 4, 2 }, HALO_ALPHA = { 0.35, 0.55, 0.85 },   -- Goldring 3/2/1 px
  HALO_TEX = 'Interface\\CharacterFrame\\TempPortraitAlphaMask',   -- weißer Kreis (ohne Maske: kein Nachhinken)
  GLOW_TEX = 'Interface\\Buttons\\UI-ActionButton-Border',        -- eckiger Schein (Klassenwappen)
  MARK_COLOR = { 1, 0.82, 0.2 }, ALARM_COLOR = { 1, 0.15, 0.1 },
  ALARM_PCT = 85,                    -- eigene skalierte Aggro ab hier: Ring blinkt rot (nur wenn lesbar)
  BLINK = 0.5,                       -- s pro Blink-Takt
  CLASS_ICON_SCALE = 0.75,
  CLASS_SHEET = 'Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES',
  MARK = 24,                         -- Schlachtzugsymbol über der Leiste
  MARK_GAP = 2,                      -- Abstand Symbol → Oberkante der Leiste
  PCT_FORMAT = '%.0f %%',
}

-- Versionscheck über Gilde/Gruppe/Schlachtzug (Versionscheck.lua, Anforderung AH) ------------

C.VERSIONCHECK = {
  PREFIX = 'TWF',                -- Addon-Nachrichten-Präfix (max. 16 Zeichen)
  TAG = 'V:',                    -- Nachricht = TAG .. Version, z. B. "V:0.5"
  LOGIN_DELAY = 10,              -- s nach dem Login an Gilde/Gruppe senden
  THROTTLE = 60,                 -- s: pro Kanal höchstens eine Nachricht
  REPLY_MIN = 1, REPLY_MAX = 5,  -- s: Antwort an ältere Versionen zufällig verzögert
}

-- Fenster "Was ist neu?" (News.lua, Anforderung AF) ------------------------------------------

C.NEWS = {
  NAME = 'ThreatWallForeverNews',
  WIDTH = 440, HEIGHT = 380,
  OFFSET_Y = 60,                  -- über der Bildschirmmitte
  -- Versionen mit Kurzfassung (Texte NEWS_<Version> in den Locales), neueste zuerst
  HELP_ICON = 'Interface/Common/help-i',   -- Info-Symbol (blaues i) oben rechts (Tooltip: Entwickler)
  HELP_SIZE = 22, HELP_GAP = 0,
  VERSIONS = { '0.7', '0.6', '0.5.2', '0.5.1', '0.5', '0.4', '0.3', '0.2', '0.1' },
  NOTE_COLOR = { 1, 0.45, 0.2 },  -- Hinweis einer Version (NEWS_<Version>_NOTE), z. B. "Spiel neu starten"
  DELAY = 2,                      -- Sekunden nach dem Login
  RETRY = 2,                      -- im Kampf / bei offenem Hinweis-Popup: erneut prüfen nach … s
  TOP_GAP = 10,                   -- Abstand unter der Kopfleiste
  BUTTON_GAP = 10,                -- Abstand Text → OK-Knopf
  OK_W = 90,
  SCROLLBAR_W = 22,               -- Platz für die Schiebeleiste
  WHEEL_STEP = 40,                -- Mausrad: Pixel pro Schritt
  LINE_SPACING = 3,
  HEAD_GAP = 4,                   -- Versions-Überschrift → Stichpunkte
  VERSION_GAP = 12,               -- Abstand zwischen zwei Versionen
  NEW_COLOR = { 0.37, 0.83, 0.37 },  -- Markierung "neu"
  -- Changelog-Abschnitte je Version (Texte NEWS_<Version>_<Abschnitt>, Punkte "Stichwort – Erklärung")
  SECTIONS = {
    { key = 'NEW', color = { 0.37, 0.83, 0.37 } },       -- Neu: grün
    { key = 'CHANGED', color = { 0.42, 0.71, 1 } },      -- Geändert: blau
    { key = 'FIXED', color = { 1, 0.6, 0.25 } },         -- Behoben: orange
  },
  KEYWORD_COLOR = { 1, 1, 1 },          -- Stichwort eines Punkts
  TEXT_COLOR = { 0.8, 0.8, 0.8 },       -- Erklärung eines Punkts
  BULLET = '• ',
  DASH = ' – ',                          -- Trenner Stichwort – Erklärung in den Texten
  SECTION_INDENT = 0, ITEM_INDENT = 10,  -- Einrückung der Punkte
  RULE_ALPHA = 0.15,                     -- Trennlinie zwischen Versionen
  -- Willkommen (erste Installation): Stichwort-Farben der fünf Punkte, wie die TWF-Ampel
  WELCOME_COLORS = { C.COLOR.green, C.COLOR.yellow, C.COLOR.blue },
  ICON_SIZE = 18,                 -- Rollensymbole im Text
  SECTION_GAP = 10,               -- Abstand vor "So geht's los" und vor der Versionsliste
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
  CHOICE_SHIFT = 8,            -- Auswahl-Knöpfe ('choice') so weit nach rechts in den Rand (Platz zum Text)
  TEXT_GAP = 8,                -- Abstand Kästchen → Text
  SPELL_ICON = 16,             -- Zaubersymbol hinter dem Text (Klassenfähigkeiten)
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
    { key = 'view', label = 'TAB_VIEW' },
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
-- healthColor = Textfarbe des Lebens rechts im Balken (% oder Zahl) ·
-- tankOnly = Zustand gibt es nur im Tank-Modus (in den Tabellen DD/Heal ausgegraut) ·
-- noThreat = Zustand hat keine Bedrohung (außerhalb des Kampfs): Zeilen mit threatRow ausgegraut
local ALARM_RED = { 1, 0.1, 0.1 }
local ALARM_YELLOW = { 1, 0.85, 0.1 }
local WHITE = { 1, 1, 1 }
C.PLATE_STATES = {
  { key = 'green', label = 'STATE_GREEN', tip = 'TIP_STATE_GREEN', color = C.COLOR.green, alpha = 0.6, frame = ALARM_RED, show = true, threat = true, threatColor = WHITE, healthColor = WHITE },
  { key = 'yellow', label = 'STATE_YELLOW', tip = 'TIP_STATE_YELLOW', color = C.COLOR.yellow, alpha = 0.6, blink = true, frame = ALARM_RED, show = true, threat = true, threatColor = WHITE, healthColor = WHITE },
  { key = 'red', label = 'STATE_RED', tip = 'TIP_STATE_RED', color = C.COLOR.red, alpha = 0.6, blink = true, frame = ALARM_RED, show = true, threat = true, threatColor = WHITE, healthColor = WHITE },
  { key = 'brown', label = 'STATE_BROWN', tip = 'TIP_STATE_BROWN', color = C.COLOR.brown, alpha = 0.6, frame = ALARM_RED, show = true, tankOnly = true, threat = true, threatColor = WHITE, healthColor = WHITE },
  { key = 'pull', label = 'STATE_PULL', tip = 'TIP_STATE_PULL', color = C.COLOR.yellow, alpha = 0.6, blink = true, frame = ALARM_YELLOW, show = true, tankOnly = true, threat = true, threatColor = WHITE, healthColor = WHITE },
  { key = 'blue', label = 'STATE_BLUE', tip = 'TIP_STATE_BLUE', color = C.COLOR.blue, alpha = 0.6, frame = ALARM_RED, show = true, threat = true, threatColor = WHITE, healthColor = WHITE },
  { key = 'grey', label = 'STATE_GREY', tip = 'TIP_STATE_GREY', color = C.COLOR.grey, alpha = 0.6, frame = ALARM_RED, show = false, threat = false, threatColor = WHITE, healthColor = WHITE, noThreat = true },
  { key = 'foreign', label = 'STATE_FOREIGN', tip = 'TIP_STATE_FOREIGN', color = C.COLOR.foreign, alpha = 0.6, frame = ALARM_RED, show = true, threat = true, threatColor = WHITE, healthColor = WHITE },
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
  { key = 'healthColor', kind = 'color', field = 'healthColor', needs = 'show', label = 'ROW_HEALTH_COLOR', tip = 'TIP_ROW_HEALTH_COLOR' },
  { key = 'show', kind = 'check', field = 'show', label = 'ROW_SHOW', tip = 'TIP_ROW_SHOW' },
}
C.PLATE_TABLE = {
  LABEL_W = 100,               -- Breite der linken Spalte mit den Zeilennamen
  COL_W = 78,                  -- Breite einer Zustands-Spalte
  TOP_H = 28,                  -- Zeile mit dem Knopf "Farben zurücksetzen" über der Tabelle
  RESET_W = 150,               -- Breite des Knopfs "Farben zurücksetzen"
  TITLE_H = 20,                -- Überschrift einer Tabelle (Alle Modi / Tank / DD / Heal)
  HEAD_H = 30,                 -- Kopfzeile (Zustandsname, bis zwei Zeilen)
  ROW_H = 22,                  -- Höhe einer Tabellenzeile
  TABLE_GAP = 6,               -- Abstand zwischen zwei Tabellen
  OPTIONS_GAP = 10,            -- Abstand zwischen den Schaltern oben und der Tabelle
  -- Vorschau-Balken oben in der Mitte: zeigt den zuletzt geänderten bzw. überfahrenen Zustand
  PREVIEW = {
    START = 'green',           -- beim Öffnen gezeigter Zustand ("Sicher")
    Y = -44,                   -- Abstand des Balkens unter der Spalten-Oberkante (Platz für den Namen)
    LABEL_GAP = 6,             -- Abstand Zustandsname unter dem Balken
    LABEL_H = 14,              -- Höhe des Zustandsnamens
    HEALTH = 72,               -- Beispiel-Leben in % (Balkenfüllung und Text)
    HEALTH_NUM = 8240,         -- Beispiel-Restleben als Zahl ("Leben in %" aus)
    THREAT = { green = 100, yellow = 92, red = 45, brown = 60, pull = 104, blue = 0, foreign = 80, grey = 0 },
    LEAD = 250,                -- Beispiel-Vorsprung (Tank: Vorsprung statt Aggro-%)
    NAME_COLOR = { 1, 0.25, 0.2 },  -- Name im Nur-Name-Zustand (feindlich, wie im Spiel)
  },
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

-- Optionen je Reiter (Reihenfolge = Anzeige-Reihenfolge). Reiter "Nameplates": diese Optionen
-- stehen oben, darunter die Farbtabelle(n).
-- type:   'section' Überschrift · 'role' drei Rollen-Knöpfe · 'check' Checkbox ·
--         'choice' Knöpfe wie bei der Rolle (choices = Werte, choiceLabels = Wert → Text) ·
--         'spacer' leerer Platz in Höhe einer Optionszeile ·
--         'color' Farbfeld (öffnet den Farbwähler) ·
--         'slider' Schieberegler · 'button' Knopf · 'column' beginnt eine neue Spalte
--         (Spalten teilen die Fensterbreite gleich auf)
-- key:    gespeicherte Einstellung (db) · state: Laufzeit-Zustand (ns.state) statt db
-- label/tip: Schlüssel in Locales.lua · action: Funktion in ns, die der Knopf aufruft
-- min/max/step: Schieberegler-Bereich (Anzeige ×100 als Prozent; count = true zeigt die Zahl selbst)
-- keepBelow/keepAbove: anderer Schlüssel, der mitgezogen wird, damit min ≤ max bleibt
C.OPTIONS = {
  -- Reiter "Allgemein": was für ganz TWF gilt
  general = {
    { type = 'section', label = 'SEC_GENERAL' },
    { type = 'role', label = 'OPT_ROLE', tip = 'TIP_ROLE' },
    { type = 'check', key = 'roleSync', label = 'OPT_ROLE_SYNC', tip = 'TIP_ROLE_SYNC' },
    { type = 'check', key = 'minimap', label = 'MENU_MINIMAP', tip = 'TIP_MINIMAP' },
    -- "Alles fixieren": sperrt das TWF-Fenster (später auch Fokus-/Ziel-Leiste, Anforderung AC)
    { type = 'check', key = 'locked', label = 'MENU_LOCK', tip = 'TIP_LOCK' },
    { type = 'section', label = 'SEC_ALERT' },
    { type = 'check', key = 'alertGroupOnly', label = 'OPT_ALERT_GROUP_ONLY', tip = 'TIP_ALERT_GROUP_ONLY' },
    { type = 'check', key = 'sound', label = 'MENU_SOUND', tip = 'TIP_SOUND' },
    { type = 'sound', key = 'soundId', label = 'OPT_SOUND_PICK', tip = 'TIP_SOUND_PICK' },
    { type = 'choice', key = 'soundChannel', label = 'OPT_SOUND_CHANNEL', tip = 'TIP_SOUND_CHANNEL',
      choices = C.SOUND_CHANNELS, choiceLabels = C.SOUND_CHANNEL_LABEL },
    { type = 'check', key = 'edgeFlash', label = 'OPT_EDGE_FLASH', tip = 'TIP_EDGE_FLASH' },
    { type = 'color', key = 'edgeColor', label = 'OPT_EDGE_COLOR', tip = 'TIP_EDGE_COLOR' },
    { type = 'slider', key = 'edgeAlpha', label = 'MENU_BACKGROUND', tip = 'TIP_EDGE_ALPHA', min = 0.1, max = 1, step = 0.05 },
    { type = 'button', action = 'testAlert', label = 'BTN_ALERT_TEST', tip = 'TIP_ALERT_TEST' },

    { type = 'column' },
    { type = 'section', label = 'SEC_DISPLAY' },
    { type = 'check', key = 'twfNameplates', label = 'OPT_TWF_NAMEPLATES', tip = 'TIP_TWF_NAMEPLATES' },
    { type = 'check', key = 'symbolMarks', label = 'OPT_SYMBOL_MARKS', tip = 'TIP_SYMBOL_MARKS' },
    { type = 'check', key = 'showAll', label = 'MENU_SHOW_ALL', tip = 'TIP_SHOW_ALL' },

    { type = 'column' },
    { type = 'section', label = 'SEC_TOOLS' },
    { type = 'button', action = 'resetAll', label = 'MENU_RESET_ALL', tip = 'TIP_RESET_ALL' },
    { type = 'section', label = 'SEC_CLASS' },
    -- shift = 0: letzte Spalte, sonst ragen die Knöpfe bis an den Fensterrand (Nutzer 2026-11-08);
    -- class: Name in der Klassenfarbe – so auch für spätere Klassen
    { type = 'choice', key = 'paladinRF', label = 'OPT_PALADIN_RF', tip = 'TIP_PALADIN_RF',
      choices = C.ONOFF, choiceLabels = C.ONOFF_LABEL, shift = 0, class = 'PALADIN', spell = 25780,
      tipTitle = 'RF_FALLBACK' },
  },

  -- Reiter "Nameplates": Schalter und Deckkraft (darunter die Farbtabelle)
  nameplates = {
    { type = 'section', label = 'SEC_OPTIONS' },
    { type = 'check', key = 'healthPct', label = 'OPT_HEALTH_PCT', tip = 'TIP_HEALTH_PCT' },
    { type = 'check', key = 'plateLead', label = 'OPT_PLATE_LEAD', tip = 'TIP_PLATE_LEAD' },
    { type = 'check', key = 'plateShared', label = 'OPT_PLATE_SHARED', tip = 'TIP_PLATE_SHARED' },
    { type = 'choice', key = 'plateDebuffs', label = 'OPT_PLATE_DEBUFFS', tip = 'TIP_PLATE_DEBUFFS',
      choices = C.DEBUFF_MODES, choiceLabels = C.DEBUFF_MODE_LABEL },
    { type = 'choice', key = 'plateDebuffPos', label = 'OPT_DEBUFF_POS', tip = 'TIP_DEBUFF_POS',
      choices = C.DEBUFF_POS, choiceLabels = C.DEBUFF_POS_LABEL },
    { type = 'slider', key = 'plateDebuffScale', label = 'OPT_DEBUFF_SCALE', tip = 'TIP_DEBUFF_SCALE',
      min = 0.5, max = 2, step = 0.1 },

    { type = 'column' },   -- Mitte: Vorschau-Balken (Settings.lua, Anforderung AE)
    { type = 'column' },
    { type = 'section', label = 'SEC_OPACITY' },
    { type = 'slider', key = 'alphaTarget', label = 'OPT_ALPHA_TARGET', tip = 'TIP_ALPHA_TARGET', min = 0.1, max = 1, step = 0.1 },
    { type = 'slider', key = 'alphaOccluded', label = 'OPT_ALPHA_OCCLUDED', tip = 'TIP_ALPHA_OCCLUDED', min = 0, max = 1, step = 0.1 },
  },

  -- Reiter "Ansicht": Liste (das TWF-Fenster) | Ziel | Fokus (Leisten, Anforderung AC)
  view = {
    { type = 'section', label = 'SEC_LIST' },
    { type = 'check', key = 'shown', label = 'OPT_SHOW_LIST', tip = 'TIP_SHOW_LIST' },
    -- Platz der Zeile "Darstellung" bei Ziel/Fokus: "Nur im Kampf" steht in allen drei Spalten gleich hoch
    { type = 'spacer' },
    -- blenden nur die Liste aus (List.lua), nicht Nameplates oder Leisten
    { type = 'check', key = 'combatOnly', label = 'MENU_COMBAT_ONLY', tip = 'TIP_COMBAT_ONLY' },
    { type = 'check', key = 'groupOnly', label = 'MENU_GROUP_ONLY', tip = 'TIP_GROUP_ONLY' },
    { type = 'check', key = 'instanceOnly', label = 'MENU_INSTANCE_ONLY', tip = 'TIP_INSTANCE_ONLY' },
    { type = 'check', key = 'listThreat', label = 'OPT_LIST_THREAT', tip = 'TIP_LIST_THREAT' },
    { type = 'check', key = 'listLead', label = 'OPT_LIST_LEAD', tip = 'TIP_LIST_LEAD' },
    { type = 'check', key = 'highlightTarget', label = 'MENU_HIGHLIGHT', tip = 'TIP_HIGHLIGHT' },
    { type = 'color', key = 'highlightColor', label = 'OPT_HIGHLIGHT_COLOR', tip = 'TIP_HIGHLIGHT_COLOR' },
    { type = 'slider', key = 'minRows', label = 'OPT_MIN_ROWS', tip = 'TIP_MIN_ROWS', min = 1, max = 15, step = 1,
      count = true, keepBelow = 'maxRows' },
    { type = 'slider', key = 'maxRows', label = 'OPT_MAX_ROWS', tip = 'TIP_MAX_ROWS', min = 1, max = 30, step = 1,
      count = true, keepAbove = 'minRows' },
    { type = 'slider', key = 'alpha', label = 'MENU_BACKGROUND', tip = 'TIP_BACKGROUND', min = 0, max = 1, step = 0.1 },
    { type = 'slider', key = 'scale', label = 'MENU_SCALE', tip = 'TIP_SCALE', min = 0.8, max = 1.5, step = 0.1 },
    { type = 'check', state = 'testMode', label = 'MENU_TEST', tip = 'TIP_TEST' },
    -- Spalten Ziel und Fokus hängt barColumn unten an
  },
}

-- Spalte Ziel bzw. Fokus im Reiter Ansicht (key = 'target'/'focus'): Mauer oder Klassik-Fenster.
-- "Nur im Kampf" und "Nur in Gruppe" gelten für beide; die Fenster-Einstellungen
-- erscheinen nur bei "Klassisch" (showIf, Anforderung AI). Reihenfolge wie bei der Liste:
-- Checkboxen, darunter die Schieberegler, zuletzt die Testzeilen.
local function barColumn(key, section, barLabel, barTip)
  local p = key .. 'Classic'
  local classic = { key = key .. 'Style', value = 'classic' }
  return {
    { type = 'column' },
    { type = 'section', label = section },
    { type = 'check', key = key .. 'Bar', label = barLabel, tip = barTip },
    { type = 'choice', key = key .. 'Style', label = 'OPT_BAR_STYLE', tip = 'TIP_BAR_STYLE',
      choices = C.BAR_STYLES, choiceLabels = C.BAR_STYLE_LABEL },
    { type = 'check', key = key .. 'BarCombat', label = 'OPT_BAR_COMBAT', tip = 'TIP_BAR_COMBAT' },
    { type = 'check', key = key .. 'BarGroup', label = 'OPT_BAR_GROUP', tip = 'TIP_BAR_GROUP' },
    { type = 'check', key = key .. 'BarInstance', label = 'OPT_BAR_INSTANCE', tip = 'TIP_BAR_INSTANCE' },
    { type = 'check', key = p .. 'Threat', label = 'OPT_CLASSIC_THREAT', tip = 'TIP_CLASSIC_THREAT', showIf = classic },
    { type = 'check', key = p .. 'Lead', label = 'OPT_CLASSIC_LEAD', tip = 'TIP_CLASSIC_LEAD', showIf = classic },
    { type = 'check', key = p .. 'Pets', label = 'OPT_CLASSIC_PETS', tip = 'TIP_CLASSIC_PETS', showIf = classic },
    -- Platz der Zeile "Rahmenfarbe" der Liste: "Min. Zeilen" steht auf derselben Höhe wie dort
    { type = 'spacer', showIf = classic },
    -- Schieberegler in der Reihenfolge der Liste (Min./Max. Zeilen, Deckkraft, Skalierung)
    { type = 'slider', key = p .. 'MinRows', label = 'OPT_MIN_ROWS', tip = 'TIP_CLASSIC_MIN_ROWS', min = 1, max = 15, step = 1,
      count = true, keepBelow = p .. 'MaxRows', showIf = classic },
    { type = 'slider', key = p .. 'MaxRows', label = 'OPT_MAX_ROWS', tip = 'TIP_CLASSIC_MAX_ROWS', min = 1, max = 15, step = 1,
      count = true, keepAbove = p .. 'MinRows', showIf = classic },
    { type = 'slider', key = p .. 'Alpha', label = 'MENU_BACKGROUND', tip = 'TIP_CLASSIC_BG', min = 0, max = 1, step = 0.1, showIf = classic },
    { type = 'slider', key = p .. 'Scale', label = 'MENU_SCALE', tip = 'TIP_CLASSIC_SCALE', min = 0.8, max = 1.5, step = 0.1, showIf = classic },
    -- Deckkraft der Mauer; bei "Klassisch" gilt stattdessen die Deckkraft des Fensters (oben)
    { type = 'slider', key = key .. 'BarAlpha', label = 'OPT_BAR_ALPHA', tip = 'TIP_BAR_ALPHA', min = 0.1, max = 1, step = 0.1,
      showIf = { key = key .. 'Style', value = 'wall' } },
    -- Testzeilen: Laufzeit-Zustand wie bei der Liste (nicht gespeichert)
    { type = 'check', state = p .. 'Test', label = 'MENU_TEST', tip = 'TIP_TEST', showIf = classic },
  }
end
for _, k in ipairs({ { 'target', 'SEC_TARGET', 'OPT_TARGET_BAR', 'TIP_TARGET_BAR' },
                     { 'focus', 'SEC_FOCUS', 'OPT_FOCUS_BAR', 'TIP_FOCUS_BAR' } }) do
  for _, opt in ipairs(barColumn(k[1], k[2], k[3], k[4])) do table.insert(C.OPTIONS.view, opt) end
end

-- Sicherheitsabfrage "Alles zurücksetzen" (Window.lua, ns.resetAll) ------------------------
C.RESET_DIALOG = {
  NAME = 'ThreatWallForeverResetDialog',
  WIDTH = 360,
  OFFSET_Y = 100,                 -- über der Bildschirmmitte
  TOP_GAP = 12,                   -- Abstand unter der Kopfleiste
  BUTTON_W = 130,
  BUTTON_GAP_Y = 14,              -- Abstand Text → Knöpfe
}

-- Klassik-Fenster für Ziel und Fokus (Klassik.lua, Anforderung AI) --------------------------
C.CLASSIC = {
  NAME = { target = 'ThreatWallForeverTargetClassic', focus = 'ThreatWallForeverFocusClassic' },
  TITLE = { target = 'CLASSIC_TITLE_TARGET', focus = 'CLASSIC_TITLE_FOCUS' },   -- Text vor dem Gegnernamen im Kopf (Nutzer 2026-11-08)
  WIDTH = 220,                       -- Startbreite (danach per Ziehen, gespeichert)
  -- Startposition: obere linke Ecke relativ zur Bildschirmmitte (rechts neben der Liste, gleiche
  -- Höhe; Nutzer 2026-11-06, siehe C.WINDOW.DEFAULT_X/Y)
  DEFAULT_POS = { target = { -107, -134 }, focus = { 190, -134 } },
  MARK_SIZE = 16,                    -- Schlachtzugsymbol im Kopf
  MARK_GAP = 4,                      -- Abstand Titel → Symbol → Gegnername
  NAME_COLOR = { 1, 1, 1 },          -- Gegnername im Kopf
  BAR_COLOR = { 0.45, 0.45, 0.5 },   -- Aggro-Balken (Name steht in Klassenfarbe darauf)
  HOLDER_COLOR = { 0.82, 0.14, 0.14 },  -- Balken des Aggro-Halters
  PET_COLOR = { 0.8, 0.8, 0.8 },     -- Name ohne Klassenfarbe (Begleiter)
  ICON_PAD = 2,                      -- Rollensymbol: so viel kleiner als die Zeile (oben + unten)
  PCT_W = 44,                        -- Breite der Prozentanzeige rechts
  PCT_RIGHT = -4,
  ROLE_ORDER = { TANK = 1, HEALER = 2, DAMAGER = 3, NONE = 4 },  -- feste Reihenfolge bei geheimen Werten
  -- Markierung des Aggro-Halters (ns.createGlow)
  HOLDER_GLOW = { COLOR = { 1, 0.82, 0.2 }, EDGE = 2, INSET = 0, ALPHA_FROM = 1, ALPHA_TO = 0.5, DURATION = 0.8 },
  -- Testzeilen (Checkbox "Testzeilen"): Name, Klasse, Rolle (C.SYMBOLS), Aggro-%, Halter, Vorsprung, Begleiter.
  -- Wiederholen sich bis "Max. Zeilen"; Begleiter-Zeilen nur mit "Begleiter auflisten".
  TEST_ROWS = {
    { 'Tankadin', 'PALADIN', 'TANK', 100, true, 135 },
    { 'Wildwut', 'WARRIOR', 'DAMAGER', 92 },
    { 'Feuerfaust', 'MAGE', 'DAMAGER', 78 },
    { 'Wuffi', nil, 'NONE', 61, false, nil, true },
    { 'Lichtblick', 'PRIEST', 'HEALER', 55 },
    { 'Schattenpfeil', 'HUNTER', 'DAMAGER', 40 },
  },
}

-- Seite unter Optionen → AddOns
C.OPTIONS_PANEL = {
  TITLE_X = 16, TITLE_Y = -16,
  TEXT_Y = -12,                -- Abstand Text unter dem Titel
  BUTTON_W = 180, BUTTON_H = 24,
  BUTTON_Y = -16,              -- Abstand Knopf unter dem Text
}
