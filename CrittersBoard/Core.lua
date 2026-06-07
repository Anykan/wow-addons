CrittersBoard = CrittersBoard or {}
local CB = CrittersBoard

-- 1. Slash-Befehl registrieren (Damit /cb funktioniert)
SLASH_CRITTERSBOARD1 = "/cb"
SlashCmdList["CRITTERSBOARD"] = function(msg)
    if CB.UI and CB.UI.frame then
        if CB.UI.frame:IsShown() then
            CB.UI.frame:Hide()
            if CB.DB and CB.DB.ui then CB.DB.ui.isOpen = false end
        else
            CB.UI.frame:Show()
            if CB.DB and CB.DB.ui then CB.DB.ui.isOpen = true end
            CB.UI:Refresh()
        end
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_LOGOUT")


function CB:WipeDatabase()
    -- 1. UI-Daten retten
    local savedUI = {}
    if CrittersBoardDB and CrittersBoardDB.ui then
        savedUI = CrittersBoardDB.ui
    end

    -- 2. Die Variable komplett "resetten"
    CrittersBoardDB = {}

    -- 3. Jedes Feld einzeln zuweisen (das zwingt WoW zum Hinsehen)
    CrittersBoardDB.formatVersion = CB.DB_VERSION
    CrittersBoardDB.damage = { records = {}, seen = {}, revision = 0 }
    CrittersBoardDB.heal = { records = {}, seen = {}, revision = 0 }
    CrittersBoardDB.overkill = { records = {}, seen = {}, revision = 0 }
    CrittersBoardDB.spells = { records = {}, bySpell = {}, revision = 0 }
    CrittersBoardDB.healSpells = { records = {}, bySpell = {}, revision = 0 }
	CrittersBoardDB.damageTaken = { records = {}, seen = {}, revision = 0 }
    CrittersBoardDB.ui = savedUI

    -- 4. WICHTIG: Die globale Variable nochmal explizit setzen
    -- Damit sagst du dem System: "Speichere genau das hier!"
    _G["CrittersBoardDB"] = CrittersBoardDB
    CB.DB = CrittersBoardDB

    print("|cff66ff66CrittersBoard:|r Wipe abgeschlossen. DB-Version " .. CB.DB_VERSION .. " gesetzt.")
end

frame:SetScript("OnEvent", function(self, event, arg1, ...)
    if event == "ADDON_LOADED" then
        if arg1 ~= "CrittersBoard" then return end

        CrittersBoardDB = CrittersBoardDB or {}
		local currentVersion = CrittersBoardDB.formatVersion
		CB.DB = CrittersBoardDB

		-- NEU: Sicherstellen, dass damageTaken existiert, auch ohne Wipe
		CB.DB.damageTaken = CB.DB.damageTaken or { records = {}, seen = {}, revision = 0 }

		if CB.InitDB then CB:InitDB() end
        -- =========================================================
		
        CB:Print("DB: " .. tostring(CB.DB_VERSION) .. " | Protokoll: " .. tostring(CB.PROTOCOL_VERSION) .. " | Gespeichert: " .. tostring(currentVersion or 0))

        -- 3. VERSIONSPRÜFUNG
        local needsUpdate = (currentVersion ~= nil and currentVersion < CB.DB_VERSION)
        local isNewVersion = (CB.DB.ui.lastSeenVersion ~= CB.VERSION)

        if needsUpdate then
            if CB.DEBUG_MODE then CB:Print("DEBUG: Core - Update benötigt. Zeige Patchnotes+Wipe Popup.") end
            -- Patchnotes mit Wipe-Button anzeigen (nach UI-Init, daher C_Timer)
            C_Timer.After(0.5, function()
                if CB.UI and CB.UI.ShowPatchNotes then
                    CB.UI:ShowPatchNotes(true)
                end
            end)
        elseif isNewVersion then
            if CB.DEBUG_MODE then CB:Print("DEBUG: Core - Neue Version erkannt. Zeige Patchnotes.") end
            CB.DB.ui.lastSeenVersion = CB.VERSION
            C_Timer.After(0.5, function()
                if CB.UI and CB.UI.ShowPatchNotes then
                    CB.UI:ShowPatchNotes(false)
                end
            end)
        end

        -- 4. UI INITIALISIEREN
        if CB.UI then
            if CB.UI.CreateMain then CB.UI:CreateMain() end
            if CB.UI.CreateSettings then CB.UI:CreateSettings() end
            if CB.DB.ui and CB.DB.ui.isOpen then CB.UI.frame:Show() end
            if CB.UI.Refresh then CB.UI:Refresh() end
        end
        
        -- 5. SYNC-START (Nur wenn kein Wipe ansteht!)
        if not needsUpdate then
            if CB.DEBUG_MODE then CB:Print("DEBUG: Core - Datenbank okay. Starte 5s Timer für Gilden-Sync...") end
            C_Timer.After(5, function()
                if CB.RequestSnapshot then
                    if CB.DEBUG_MODE then CB:Print("DEBUG: Core - Timer abgelaufen. Rufe RequestSnapshot auf.") end
                    CB:RequestSnapshot(false)
                else
                    if CB.DEBUG_MODE then CB:DLog(2,0,0) end
                end
            end)
        else
            if CB.DEBUG_MODE then CB:Print("DEBUG: Core - Sync wurde NICHT gestartet (Wipe steht aus).") end
        end

    -- NEU: Debug für Kampf-Events
    elseif event == "PLAYER_LOGIN" then
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        if CB.DEBUG_MODE then CB:Print("DEBUG: Combat Log Listener aktiv.") end

    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        if CB.OnCombatLog then CB:OnCombatLog() end

    elseif event == "PLAYER_LOGOUT" then
        -- seen-Tabelle bereinigen: nur Einträge der aktuellen Top 100 behalten
        if CB.DB then
            local lists = {
                CB.DB.damage,
                CB.DB.heal,
                CB.DB.overkill,
                CB.DB.damageTaken,
            }
            for _, tbl in ipairs(lists) do
                if tbl and tbl.records then
                    local newSeen = {}
                    for _, rec in ipairs(tbl.records) do
                        local key = string.format("%s_%d_%d", rec.player, rec.amount, rec.ts)
                        newSeen[key] = rec.ts
                    end
                    tbl.seen = newSeen
                end
            end
        end
    end
end)