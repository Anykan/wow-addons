CrittersBoard = CrittersBoard or {}
local CB = CrittersBoard

local L = setmetatable({}, {
    __index = function(t, k)
        return k -- Falls ein Key fehlt, zeige den Key-Namen an
    end
})

-- =========================================================
-- ENGLISCH (Standard / Fallback)
-- =========================================================
L["ADDON_NAME"] = "CrittersBoard"
L["SETTINGS_TITLE"] = "CrittersBoard - Settings"
L["MODE_D10"] = "Damage - Top 10"
L["MODE_D100"] = "Damage - Top 100"
L["MODE_H10"] = "Heal - Top 10"
L["MODE_H100"] = "Heal - Top 100"
L["MODE_O10"] = "Overkill - Top 10"
L["MODE_O100"] = "Overkill - Top 100"
L["MODE_S10"] = "Attack - Top 10"
L["MODE_HS10"] = "Heal Spell Top 100"
L["MODE_S100"] = "Attack - Top 100"
L["MODE_HS100"] = "Heal Spell - Top 100"

L["LABEL_CHOOSE_LIST"] = "Select List:"
L["OPT_AUDIO"] = "Audio and Alerts"
L["OPT_LOCK"] = "Lock Window"
L["OPT_SCALE"] = "UI Scale"
L["BTN_SYNC"] = "Sync"
L["BTN_CLEAR"] = "Clear List"

L["TOOLTIP_SPELL"] = "Spell"
L["TOOLTIP_TARGET"] = "Target"
L["TOOLTIP_DATE"] = "Date"
L["TOOLTIP_CRIT"] = "Critical"
L["TOOLTIP_MAP"] = "Location"
L["TOOLTIP_COORDS"] = "Coordinates"

L["YES"] = "Yes"
L["NO"] = "No"

L["MSG_NEW_RECORD"] = "NEW RECORD!"
L["MSG_DB_NOT_READY"] = "Database not ready"
L["MSG_LIST_CLEARED"] = "All lists cleared."

L["OPT_SYNC_DISABLED"] = "Disable Sync (Global)"

-- NEU für v0.5 (Wipe Popup)
L["WIPE_TITLE"] = "CrittersBoard Update v0.5"
L["WIPE_TEXT"] = "|cff66ff66CrittersBoard v0.5|r\n\nThe database was updated with the latest version and needs to be reset; unfortunately, all data will be lost.."
L["CONFIRM"] = "OK"

-- =========================================================
-- DEUTSCH
-- =========================================================
if GetLocale() == "deDE" then
    L["SETTINGS_TITLE"] = "CrittersBoard - Einstellungen"
    L["MODE_D10"] = "Schaden - Top 10"
    L["MODE_D100"] = "Schaden - Top 100"
    L["MODE_H10"] = "Heilung - Top 10"
    L["MODE_H100"] = "Heilung - Top 100"
    L["MODE_O10"] = "Overkill - Top 10"
    L["MODE_O100"] = "Overkill - Top 100"
	L["MODE_S10"] = "Angriffe - Top 10"
	L["MODE_HS10"] = "Heilungen Top 100"
	L["MODE_S100"] = "Angriffe - Top 100"
	L["MODE_HS100"] = "Heilungen - Top 100"
    L["LABEL_CHOOSE_LIST"] = "Liste auswählen:"
    L["OPT_AUDIO"] = "Audio und Warnmeldung"
    L["OPT_LOCK"] = "Fenster fixieren"
    L["OPT_SCALE"] = "Skalierung"
    L["BTN_SYNC"] = "Sync"
    L["BTN_CLEAR"] = "Liste löschen"

    L["TOOLTIP_SPELL"] = "Zauber"
    L["TOOLTIP_TARGET"] = "Ziel"
    L["TOOLTIP_DATE"] = "Datum"
    L["TOOLTIP_CRIT"] = "Kritisch"
    L["TOOLTIP_MAP"] = "Ort"
    L["TOOLTIP_COORDS"] = "Koordinaten"

    L["YES"] = "Ja"
    L["NO"] = "Nein"

    L["MSG_NEW_RECORD"] = "NEUER REKORD!"
    L["MSG_DB_NOT_READY"] = "Datenbank nicht bereit"
    L["MSG_LIST_CLEARED"] = "Alle Listen wurden geleert."

    L["OPT_SYNC_DISABLED"] = "Sync deaktivieren (Global)"
    
    -- NEU für v0.5 (Wipe Popup)
    L["WIPE_TITLE"] = "CrittersBoard Update v0.5"
	L["WIPE_TITLE"] = "CrittersBoard Update v0.5"
	L["WIPE_TEXT"] = "|cff66ff66CrittersBoard v0.5|r\n\nDie Datenbank wurde auf die neueste Version aktualisiert und muss zurückgesetzt werden; dabei gehen leider alle Daten verloren."
end

CB.L = L