CrittersBoard = CrittersBoard or {}
local CB = CrittersBoard

-- Addon-Version (Anzeige, für Patchnotes-Popup)
CB.VERSION = "0.6.1"

-- Datenbankversion: Bump = Wipe nötig (DB-Struktur geändert)
CB.DB_VERSION = 4

-- Protokollversion: Bump = Sync-Inkompatibilität (neue Felder/Nachrichten)
-- Hinweis: v0.5.6 verwendete DB_VERSION (3) als Token → muss >= 4 sein damit kein falsches Update-Warning ausgelöst wird
CB.PROTOCOL_VERSION = 5

-- Kommunikation
CB.PREFIX = "CB_CRIT"

-- Debug-Modus
CB.DEBUG_MODE = false

--Spam schutz für neue Datenbanktabelle
CB.UpdateWarned = false

-- Einmalige Benachrichtigung wenn neuere Version erkannt wird
CB.NewerVersionWarned = false