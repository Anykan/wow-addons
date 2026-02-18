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
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

local function ShowUpdatePopup()
    StaticPopupDialogs["CB_UPDATE_WIPE"] = {
        text = CB.L["WIPE_TEXT"] or "Database Wipe needed.",
        button1 = CB.L["CONFIRM"] or "OK",
        OnAccept = function()
            -- Erst beim Klick auf OK wird gelöscht...
            CB:WipeDatabase()
            -- ...und sofort gespeichert/neu geladen
            ReloadUI()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = false,
    }
    StaticPopup_Show("CB_UPDATE_WIPE")
end

local function SafeInitUI()
  if not CB.UI then return false end
  
  -- UI Frames erstellen falls noch nicht geschehen
  if CB.UI.CreateMain then CB.UI:CreateMain() end
  if CB.UI.CreateSettings then CB.UI:CreateSettings() end

  -- Zahnrad-Button verknüpfen
  if CB.UI.gearBtn and not CB.UI.gearBtn._cbHooked then
    CB.UI.gearBtn._cbHooked = true
    CB.UI.gearBtn:SetScript("OnClick", function()
      if CB.UI.ToggleSettings then CB.UI:ToggleSettings() end
    end)
  end

  -- Fenster-Status (Sichtbarkeit & Skalierung)
  if CB.DB and CB.DB.ui then
    if CB.DB.ui.isOpen then CB.UI.frame:Show() else CB.UI.frame:Hide() end
    if CB.DB.ui.scale then CB.UI.frame:SetScale(CB.DB.ui.scale) end
  end

  if CB.UI.Refresh then CB.UI:Refresh() end

  -- Wipe Popup anzeigen
  if CB.ShowWipePopup then
    ShowUpdatePopup()
    CB.ShowWipePopup = nil 
  end
  return true
end

function CB:WipeDatabase()
    -- 1. UI-Daten retten
    local savedUI = {}
    if CrittersBoardDB and CrittersBoardDB.ui then
        savedUI = CrittersBoardDB.ui
    end

    -- 2. Die Variable komplett "resetten"
    CrittersBoardDB = {}

    -- 3. Jedes Feld einzeln zuweisen (das zwingt WoW zum Hinsehen)
    CrittersBoardDB.formatVersion = CB.REQUIRED_DB_VERSION
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

    print("|cff66ff66CrittersBoard:|r Wipe abgeschlossen. Version " .. CB.REQUIRED_DB_VERSION .. " gesetzt.")
end

frame:SetScript("OnEvent", function(self, event, arg1, ...)
    if event == "ADDON_LOADED" then
        if arg1 ~= "CrittersBoard" then return end

        CrittersBoardDB = CrittersBoardDB or {}
		local currentVersion = CrittersBoardDB.formatVersion
		CB.DB = CrittersBoardDB

		-- NEU: Sicherstellen, dass damageTaken existiert, auch ohne Wipe
		if CB.DB then
			CB.DB.damageTaken = CB.DB.damageTaken or { records = {}, seen = {}, revision = 0 }
		end

		if CB.InitDB then CB:InitDB() end
        -- =========================================================
		
        -- Debug: Versionsstand
        CB:Print("DEBUG: Core - Eigene Version: " .. tostring(CB.REQUIRED_DB_VERSION) .. " | DB Version: " .. tostring(currentVersion or 0))

        -- 3. VERSIONSPRÜFUNG
        local needsUpdate = (not currentVersion or currentVersion < CB.REQUIRED_DB_VERSION)
        
        if needsUpdate then
            CB:Print("DEBUG: Core - Update benötigt. Zeige Popup, stoppe automatischen Sync.")
            ShowUpdatePopup()
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
            CB:Print("DEBUG: Core - Datenbank okay. Starte 5s Timer für Gilden-Sync...")
            C_Timer.After(5, function()
                if CB.RequestSnapshot then
                    CB:Print("DEBUG: Core - Timer abgelaufen. Rufe RequestSnapshot auf.")
                    CB:RequestSnapshot(false)
                else
                    if CB.DEBUG_MODE then CB:DLog(2,0,0) end
                end
            end)
        else
            CB:Print("DEBUG: Core - Sync wurde NICHT gestartet (Wipe steht aus).")
        end

    -- NEU: Debug für Kampf-Events
    elseif event == "PLAYER_LOGIN" then
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        CB:Print("DEBUG: Combat Log Listener aktiv.")

    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subevent, _, sourceGUID, _, _, _, _, _, _, _, arg12, arg13, _, arg15 = CombatLogGetCurrentEventInfo()
        
        if sourceGUID == UnitGUID("player") then
            if subevent == "SPELL_DAMAGE" or subevent == "SPELL_CRIT" then
                if CB.DEBUG_MODE then CB:DLog(3, arg13, arg12, arg15) end
            elseif subevent == "SWING_DAMAGE" then
                if CB.DEBUG_MODE then CB:DLog(1, arg12) end
            end
        end

        -- Den originalen Kampf-Code aufrufen
        if CB.OnCombatLog then CB:OnCombatLog() end
    end
end)