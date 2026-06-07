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
L["CAT_DT"] = "Hall of Pain"

-- Descriptions for the info tooltip
L["DESC_D"] = "The archive of pure violence. We log every single hit by guild members – but only the 20 most painful ones make it onto this wall of shame for our enemies."
L["DESC_H"] = "Who needs hazard pay with friends like these? The archive of the guild's 20 most massive life-saving moments. Those listed here don't just heal wounds – they reassemble entire skeletons in passing."
L["DESC_O"] = "The archive for atomized enemies. Here we list the 20 cases where we did the undertaker's job for him, because after the hit, there was simply nothing left to bury. Better safe than sorry!"
L["DESC_S"] = "Welcome to the Hall of Ego! Become the undisputed champion of your craft. Make sure everyone in the guild sees your name when they look up how to ACTUALLY use an ability!"
L["DESC_HS"] = "The official register for life-extenders. This is where we ruthlessly compare who holds the patent for the perfect save and who is just hoping the tank survives. Set a record for your favorite heal that the guild must live up to!"
L["DESC_DT"] = "The official archive for floor-kissing. Here we honor the 20 moments a guild member decided to stop a charging boss with their face. Painful proof that dodging is completely overrated!"

L["LABEL_TOP"] = "Top"
L["LABEL_CHOOSE_LIST"] = "Select List:"
L["OPT_AUDIO"] = "Audio and Alerts"
L["OPT_LOCK"] = "Lock Window"
L["OPT_SCALE"] = "UI Scale"
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

L["MSG_SYNC_START"] = "Synchronization started..."
L["MSG_I_AM_COORDINATOR"] = "You are the Coordinator."
L["MSG_COORDINATOR_IS"] = "Coordinator: %s"
L["MSG_NO_PLAYERS_ONLINE"] = "No other players online — sync paused."

-- NEU für v0.5 (Wipe Popup)
L["WIPE_TEXT"] = "|cff66ff66CrittersBoard v0.6|r\n\nThe database was updated to version 4 and needs to be reset; unfortunately, all data will be lost."

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

L["ALERT_MSG_DT"] = "|TInterface\\Icons\\Ability_Warrior_EndlessRage:0|t OUCH! %s took a massive %d hit from %s!"
L["UPDATE_NEEDED"] = "|cffff3333Update Required:|r You are receiving data for a new category (%s). Please update CrittersBoard!"
L["UPDATE_AVAILABLE"] = "|cffff9900Update available:|r A newer version of CrittersBoard was detected. Please update!"

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
	L["CAT_DT"] = "Halle des Schmerzes"
	
	-- Beschreibungen für den Info-Tooltip
	L["DESC_D"] = "Das Archiv der puren Gewalt. Wir protokollieren jeden einzelnen Treffer der Gildenmitglieder – aber nur die 20 schmerzhaftesten schaffen es an diese Wand der Schande für unsere Gegner."
	L["DESC_H"] = "Wieso Schmerzensgeld, wenn man solche Freunde hat? Das Archiv der 20 gewaltigsten Rettungsaktionen der Gilde. Wer hier steht, heilt nicht nur Wunden – er baut ganze Skelette im Vorbeigehen wieder zusammen."
	L["DESC_O"] = "Das Archiv für atomisierte Gegner. Hier landen die 20 Fälle, in denen wir dem Bestatter die Arbeit abgenommen haben, weil nach dem Schlag schlichtweg nichts mehr zum Beerdigen übrig war. Sicher ist sicher!"
	L["DESC_S"] = "Willkommen in der Hall of Ego! Werde zum unangefochtenen Champion deines Fachs. Sorge dafür, dass jeder in der Gilde deinen Namen sieht, wenn er nachschlägt, wie man eine Fähigkeit WIRKLICH benutzt!"
	L["DESC_HS"] = "Das offizielle Register für Lebensverlängerer. Hier wird gnadenlos verglichen, wer das Patent auf die perfekte Rettung hält und wer nur hofft, dass der Tank überlebt. Setz eine Marke für deine Lieblingsheilung, an der sich die Gilde orientieren muss!"
	L["DESC_DT"] = "Das offizielle Archiv für Bodenküsse. Hier ehren wir die 20 Momente, in denen ein Gildenmitglied beschlossen hat, einen Boss mit dem Gesicht zu bremsen. Ein schmerzhafter Beweis dafür, dass Ausweichen völlig überbewertet wird!"
	
	L["LABEL_TOP"] = "Top"
    L["LABEL_CHOOSE_LIST"] = "Liste auswählen:"
    L["OPT_AUDIO"] = "Audio und Warnmeldung"
    L["OPT_LOCK"] = "Fenster fixieren"
    L["OPT_SCALE"] = "Skalierung"
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

    L["MSG_SYNC_START"] = "Synchronisierung gestartet..."
    L["MSG_I_AM_COORDINATOR"] = "Du bist der Coordinator."
    L["MSG_COORDINATOR_IS"] = "Coordinator: %s"
    L["MSG_NO_PLAYERS_ONLINE"] = "Keine anderen Spieler online — Sync pausiert."
    
    -- NEU für v0.5 (Wipe Popup)
		L["WIPE_TEXT"] = "|cff66ff66CrittersBoard v0.6|r\n\nDie Datenbank wurde auf Version 4 aktualisiert und muss zurückgesetzt werden; dabei gehen leider alle Daten verloren."

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
	
	L["ALERT_MSG_DT"] = "|TInterface\\Icons\\Ability_Warrior_EndlessRage:0|t AUTSCH! %s hat %d Schaden von %s kassiert!"
	L["UPDATE_NEEDED"] = "|cffff3333Update benötigt:|r Du empfängst Daten für eine neue Kategorie (%s). Bitte aktualisiere CrittersBoard!"
	L["UPDATE_AVAILABLE"] = "|cffff9900Update verfügbar:|r Eine neuere Version von CrittersBoard wurde erkannt. Bitte aktualisieren!"
end

CB.L = L