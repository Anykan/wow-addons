CrittersBoard = CrittersBoard or {}
local CB = CrittersBoard

-- =========================================================
-- PATCHNOTES TEXTE (pro Version, EN + DE)
-- =========================================================

CB.PATCHNOTES = {}

CB.PATCHNOTES["0.6.2"] = {
    en = {
        title = "CrittersBoard v0.6.2 — Hotfix",
        lines = {
            "|cffFF4444Sync Bugfixes (Hotfix)|r",
            "• Fixed: New player joining while a coordinator was online sometimes got 'Sync paused' and received no data — caused by a race condition where the 3-second election timer fired before the coordinator's reply arrived.",
            "• Fixed: When the coordinator logged out and back in, other players already knew them as coordinator and stayed silent — so no new election happened and the returning player claimed coordinator again without a proper vote.",
        },
    },
    de = {
        title = "CrittersBoard v0.6.2 — Hotfix",
        lines = {
            "|cffFF4444Sync-Bugfixes (Hotfix)|r",
            "• Behoben: Ein neu beitretender Spieler bekam manchmal 'Sync pausiert' und erhielt keine Daten — verursacht durch eine Race-Condition bei der der 3-Sekunden-Timer vor der Antwort des Coordinators auslöste.",
            "• Behoben: Wenn der Coordinator aus- und wieder einloggte, kannten ihn andere Spieler noch als Coordinator und schwiegen — dadurch fand keine neue Wahl statt und der zurückkehrende Spieler übernahm ohne korrekte Abstimmung wieder die Rolle.",
        },
    },
}

CB.PATCHNOTES["0.6.1"] = {
    en = {
        title = "CrittersBoard v0.6.1 — Hotfix",
        lines = {
            "|cffFF4444Sync Bugfixes (Hotfix)|r",
            "• Fixed: Coordinator and sync-complete messages appeared in an endless loop.",
            "• Fixed: Alerts and sounds (e.g. Holy Fire) were permanently silenced after login.",
            "• Fixed: 'Coordinator: X' was shown again for every new player joining — now only shown when the coordinator actually changes.",
            "• Fixed: When logging in alone, isSyncActive was never reset — now correctly cleared so alerts work immediately.",
            "• Fixed: After the coordinator logs out, the remaining players now automatically elect a new coordinator.",
            "• Fixed: SNAP_BUSY retry no longer bypasses the cooldown guard.",
            "• Fixed: Coordinator now properly resets sync state after sending the full snapshot.",
        },
    },
    de = {
        title = "CrittersBoard v0.6.1 — Hotfix",
        lines = {
            "|cffFF4444Sync-Bugfixes (Hotfix)|r",
            "• Behoben: Coordinator- und Sync-Meldungen erschienen in einer Endlosschleife.",
            "• Behoben: Alerts und Sounds (z.B. Heiliges Feuer) wurden nach dem Einloggen dauerhaft unterdrückt.",
            "• Behoben: 'Coordinator: X' wurde bei jedem neu beitretenden Spieler erneut angezeigt — erscheint jetzt nur noch wenn sich der Coordinator wirklich ändert.",
            "• Behoben: Beim Einloggen alleine blieb isSyncActive dauerhaft aktiv — wird jetzt korrekt zurückgesetzt damit Alerts sofort funktionieren.",
            "• Behoben: Wenn der Coordinator ausloggt, starten die verbleibenden Spieler jetzt automatisch eine neue Wahl.",
            "• Behoben: SNAP_BUSY-Retry umging bisher den Cooldown-Schutz.",
            "• Behoben: Coordinator setzt seinen Sync-Status nach dem Senden des Snapshots nun korrekt zurück.",
        },
    },
}

CB.PATCHNOTES["0.6"] = {
    en = {
        title = "CrittersBoard v0.6 — What's New",
        lines = {
            "|cffFFD700Coordinator-Sync (completely new)|r",
            "• Automatic coordinator election — the player with the longest active session takes the lead.",
            "• On login the coordinator sends a full snapshot to all guild members.",
            "• After receiving the snapshot, you send back your own records (delta push) — no more data loss when players were offline.",
            "• Coordinator role is handed off gracefully on logout.",
            "• No more manual sync button needed.",
            " ",
            "|cffFFD700Version System|r",
            "• Two separate version numbers: DB version (format/wipe) and protocol version (sync).",
            "• When a newer protocol version is detected, outgoing sync stops immediately and an update notice is shown.",
            " ",
            "|cffFFD700Lists & Display|r",
            "• Hall of Destruction, Divine Miracles, Overkill, Hall of Pain: fixed |cffFFFFFFTop 20|r limit.",
            "• Masterful Strikes & Sacred Records: dynamic, grows with every new spell best.",
            "• Limit dropdown removed from settings.",
            " ",
            "|cffFFD700Sync Efficiency|r",
            "• EVT (live record) is only sent when the hit actually enters the Top 20.",
            "• No snapshot sent when you are the only player online.",
            "• Spell name is no longer transmitted — reconstructed client-side via GetSpellInfo.",
            " ",
            "|cffFFD700Spell Grouping|r",
            "• Spells are grouped by name — Fireball Rank 1–8 appears as one entry with the highest value ever hit.",
            " ",
            "|cffFFD700UI Cleanup|r",
            "• Sync checkbox and sync button removed from settings.",
            "• Dead code cleaned up.",
            " ",
            "|cffFFD700Info Tooltip|r",
            "• New ? button shows a description for the active category (EN + DE).",
        },
    },
    de = {
        title = "CrittersBoard v0.6 — Was ist neu",
        lines = {
            "|cffFFD700Coordinator-Sync (komplett neu)|r",
            "• Automatische Coordinator-Wahl — der Spieler mit der längsten aktiven Session übernimmt die Leitung.",
            "• Beim Einloggen sendet der Coordinator automatisch einen Snapshot an alle Gildenmitglieder.",
            "• Nach dem Snapshot sendest du deine eigenen Rekorde zurück (Delta-Push) — kein Datenverlust mehr wenn Spieler offline waren.",
            "• Coordinator-Rolle wird beim Ausloggen sauber weitergegeben.",
            "• Kein manueller Sync-Button mehr nötig.",
            " ",
            "|cffFFD700Versionssystem|r",
            "• Zwei getrennte Versionsnummern: DB-Version (Format/Wipe) und Protokoll-Version (Sync).",
            "• Wird eine neuere Protokollversion erkannt, stoppt der ausgehende Sync sofort und eine Update-Meldung erscheint.",
            " ",
            "|cffFFD700Listen & Anzeige|r",
            "• Halle der Zerstörung, Göttliche Wunder, Gnadenstoß, Halle des Schmerzes: fest auf |cffFFFFFFTop 20|r begrenzt.",
            "• Meisterhafte Schläge & Heilige Rekorde: dynamisch, wächst mit jedem neuen Zauber-Best.",
            "• Limit-Dropdown aus den Einstellungen entfernt.",
            " ",
            "|cffFFD700Sync-Effizienz|r",
            "• EVT (Echtzeit-Rekord) wird nur noch gesendet wenn der Treffer wirklich in die Top 20 kommt.",
            "• Kein Snapshot-Versand wenn du alleine online bist.",
            "• Zaubername wird nicht mehr übertragen — wird clientseitig per GetSpellInfo rekonstruiert.",
            " ",
            "|cffFFD700Spell-Gruppierung|r",
            "• Zauber werden nach Namen gruppiert — Feuerball Rang 1–8 erscheint als ein Eintrag mit dem höchsten je erreichten Wert.",
            " ",
            "|cffFFD700UI-Bereinigung|r",
            "• Sync-Checkbox und Sync-Button aus den Einstellungen entfernt.",
            "• Toter Code aufgeräumt.",
            " ",
            "|cffFFD700Info-Tooltip|r",
            "• Neuer ?-Button zeigt eine Beschreibung der aktuellen Kategorie (EN + DE).",
        },
    },
}
