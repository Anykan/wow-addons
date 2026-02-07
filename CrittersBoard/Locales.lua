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
L["MODE_S_BEST"] = "Attack Records"
L["MODE_HS_BEST"] = "Heal Spell Records"

L["LABEL_CHOOSE_LIST"] = "Select List:"
L["OPT_AUDIO"] = "Audio and Alerts"
L["OPT_LOCK"] = "Lock Window"
L["OPT_SCALE"] = "UI Scale"
L["BTN_SYNC"] = "Sync"
L["BTN_CLEAR"] = "Clear List"

L["TOOLTIP_SPELL"] = "Spell:"
L["TOOLTIP_WEAPON"] = "Weapon:"
L["TOOLTIP_TARGET"] = "Target:"
L["TOOLTIP_DATE"] = "Date:"
L["TOOLTIP_REGION"] = "Region:"
L["TOOLTIP_CRIT"] = "Crit:"
L["YES"] = "Yes"
L["NO"] = "No"

L["MSG_NEW_RECORD"] = "NEW RECORD!"
L["MSG_DB_NOT_READY"] = "Database not ready"
L["MSG_LIST_CLEARED"] = "All lists cleared."

L["OPT_SYNC_DISABLED"] = "Disable Sync (Global)"

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
    L["MODE_S_BEST"] = "Angriffe"
    L["MODE_HS_BEST"] = "Heil-Zauber Rekorde"

    L["LABEL_CHOOSE_LIST"] = "Liste auswählen:"
    L["OPT_AUDIO"] = "Audio und Warnmeldung"
    L["OPT_LOCK"] = "Fenster fixieren"
    L["OPT_SCALE"] = "Skalierung"
    L["BTN_SYNC"] = "Sync"
    L["BTN_CLEAR"] = "Liste löschen"

    L["TOOLTIP_SPELL"] = "Angriff:"
    L["TOOLTIP_WEAPON"] = "Waffe:"
    L["TOOLTIP_TARGET"] = "Ziel:"
    L["TOOLTIP_DATE"] = "Datum:"
    L["TOOLTIP_REGION"] = "Region:"
    L["TOOLTIP_CRIT"] = "Crit:"
    L["YES"] = "Ja"
    L["NO"] = "Nein"

    L["MSG_NEW_RECORD"] = "NEUER REKORD!"
    L["MSG_DB_NOT_READY"] = "Datenbank nicht bereit"
    L["MSG_LIST_CLEARED"] = "Alle Listen wurden geleert."
	
	L["OPT_SYNC_DISABLED"] = "Sync global deaktivieren"
end

CB.L = L