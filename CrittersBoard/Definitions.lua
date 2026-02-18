CrittersBoard = CrittersBoard or {}
local CB = CrittersBoard

-- Zentrale Versionssteuerung
CB.REQUIRED_DB_VERSION = 3 --Sync LUA mir or x anpassen

-- Kommunikation
CB.PREFIX = "CB_CRIT"

-- Debug-Modus
CB.DEBUG_MODE = false

--Spam schutz für neue Datenbanktabelle
CB.UpdateWarned = false