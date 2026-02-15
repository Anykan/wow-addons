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
L["OPT_ALERT_LIMIT"] = "Max. Alerts"

L["CAT_D"] = "Hall of Destruction"
L["CAT_H"] = "Divine Miracles"
L["CAT_O"] = "Overkill"
L["CAT_S"] = "Masterful Strikes"
L["CAT_HS"] = "Sacred Records"
L["LABEL_TOP"] = "Top"
L["LABEL_CHOOSE_LIMIT"] = "Anzahl:"
	
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
L["CONFIRM"] = "OK"

L["MSG_DB_NOT_READY"] = "Database not ready"
L["MSG_LIST_CLEARED"] = "All lists cleared."

L["OPT_SYNC_DISABLED"] = "Disable Sync (Global)"

-- NEU für v0.5 (Wipe Popup)
L["WIPE_TITLE"] = "CrittersBoard Update v0.5.4.2"
L["WIPE_TEXT"] = "|cff66ff66CrittersBoard v0.5.4.2|r\n\nThe database was updated with the latest version 3 and needs to be reset; unfortunately, all data will be lost.."

-- Alert Nachrichten
L["ALERT_MSG_D"]  = "|TInterface\\Icons\\Spell_Fire_Fireball02:0|t UNBELIEVABLE! %s smashed the record with %s (%d Damage)!"
L["ALERT_MSG_H"]  = "|TInterface\\Icons\\Spell_Holy_HolyBolt:0|t DIVINE! %s saved everyone with %s for %d Healing!"
L["ALERT_MSG_O"]  = "|TInterface\\Icons\\Ability_Creature_Isle_05:0|t OBLITERATED! %s destroyed the target with %s by %d!"
L["ALERT_MSG_S"]  = "|TInterface\\Icons\\Ability_MeleeDamage:0|t MASTERFUL! %s landed a %s hit for %d!"
L["ALERT_MSG_HS"] = "|TInterface\\Icons\\Spell_Holy_SurgeOfLight:0|t HOLY SPELL! %s broke the record: %s healed for %d!"
-- Local Records
L["MSG_NEW_RECORD"] = "|TInterface\\Icons\\Ability_Hibernating:0|t New Personal Record! %s: %d"

-- LDB / Titan Panel Tooltip
L["LDB_TITLE"] = "|cff66ff66CrittersBoard Records|r"
L["LDB_WAITING"] = "Waiting for data..."
L["LDB_NO_DATA"] = "No records logged."
L["LDB_LAST_RECORD"] = "Current Leader:"
L["LDB_HINT_L"] = "|cffaaaaaaLeft-Click: Switch Category|r"

-- Minimap Tooltip
L["MINIMAP_TITLE"] = "|cff66ff66CrittersBoard|r"
L["MINIMAP_HINT_L"] = "|cffaaaaaaLeft-Click: Toggle Window|r"
L["MINIMAP_HINT_R"] = "|cffaaaaaaRight-Click: Settings|r"

-- =========================================================
-- DEUTSCH
-- =========================================================
if GetLocale() == "deDE" then
    L["SETTINGS_TITLE"] = "CrittersBoard - Einstellungen"
	L["OPT_ALERT_LIMIT"] = "Max. Alerts"
	L["CAT_D"] = "Halle der Zerstörung"
	L["CAT_H"] = "Göttliche Wunder"
	L["CAT_O"] = "Gnadenstoß"
	L["CAT_S"] = "Meisterhafte Schläge"
	L["CAT_HS"] = "Heilige Rekorde"

	L["LABEL_TOP"] = "Top"
    L["LABEL_CHOOSE_LIMIT"] = "Anzahl:"

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

    L["MSG_DB_NOT_READY"] = "Datenbank nicht bereit"
    L["MSG_LIST_CLEARED"] = "Alle Listen wurden geleert."

    L["OPT_SYNC_DISABLED"] = "Sync deaktivieren (Global)"
    
    -- NEU für v0.5 (Wipe Popup)
	L["WIPE_TITLE"] = "CrittersBoard Update v0.5.4.2"
	L["WIPE_TEXT"] = "|cff66ff66CrittersBoard v0.5.4.2|r\n\nDie Datenbank wurde auf die neueste Version 3 aktualisiert und muss zurückgesetzt werden; dabei gehen leider alle Daten verloren."

	-- Alert Nachrichten
	L["ALERT_MSG_D"]  = "|TInterface\\Icons\\Spell_Fire_Fireball02:0|t UNGLAUBLICH! %s zertrümmert den Rekord mit %s (%d Schaden)!"
	L["ALERT_MSG_H"]  = "|TInterface\\Icons\\Spell_Holy_HolyBolt:0|t GÖTTLICH! %s rettet alle mit %s für %d Heilung!"
	L["ALERT_MSG_O"]  = "|TInterface\\Icons\\Ability_Creature_Isle_05:0|t OVERKILL! %s hat das Ziel mit %s um %d vernichtet!"
	L["ALERT_MSG_S"]  = "|TInterface\\Icons\\Ability_MeleeDamage:0|t MEISTERHAFT! %s landet einen %s Treffer von %d!"
	L["ALERT_MSG_HS"] = "|TInterface\\Icons\\Spell_Holy_SurgeOfLight:0|t HEIL-ZAUBER! %s bricht den Rekord: %s heilte %d!"
	L["MSG_NEW_RECORD"] = "Neuer persönlicher Rekord! %s: %d"
	
	-- LDB / Titan Panel Tooltip
    L["LDB_TITLE"] = "|cff66ff66CrittersBoard Rekorde|r"
    L["LDB_WAITING"] = "Warte auf Daten..."
    L["LDB_NO_DATA"] = "Kein Rekord geloggt."
    L["LDB_LAST_RECORD"] = "Aktueller Spitzenreiter:"
    L["LDB_HINT_L"] = "|cffaaaaaaLinks-Klick: Kategorie wechseln|r"

    -- Minimap Tooltip
    L["MINIMAP_TITLE"] = "|cff66ff66CrittersBoard|r"
    L["MINIMAP_HINT_L"] = "|cffaaaaaaLinks-Klick: Fenster An/Aus|r"
    L["MINIMAP_HINT_R"] = "|cffaaaaaaRechts-Klick: Einstellungen|r"
end

CB.L = L