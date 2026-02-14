local CB = CrittersBoard
if not CB then return end

local LDB = LibStub:GetLibrary("LibDataBroker-1.1", true)
local icon = LibStub:GetLibrary("LibDBIcon-1.0", true)

if not LDB then return end

CB.LastGlobalRecord = nil

-- =========================================================
-- LDB OBJEKT ERSTELLUNG
-- =========================================================
CB.LDB_Object = LDB:NewDataObject("CrittersBoard", {
    type = "data source",
    label = "CrittersBoard",
    suffix = "CB",
    -- Nutzt CB.L für die Lokalisierung
    text = "CB: " .. (CB.L["LDB_WAITING"] or "Warte..."),
    icon = "Interface\\Icons\\Spell_Fire_Fireball02",
    
    -- Titan Panel Ausrichtung
    align = "right",
    dockingPos = "right",

    OnClick = function(self, button)
        if button == "LeftButton" then
            if CB.UI and CB.UI.frame then
                -- Logik-Check: Woher kommt der Klick?
                local isMinimap = (self:GetParent() == Minimap or (self.GetName and self:GetName():find("LibDBIcon")))

                if isMinimap then
                    -- MINIMAP VERHALTEN: Fenster an/aus (Toggle)
                    if CB.UI.frame:IsShown() then
                        CB.UI.frame:Hide()
                        if CB.DB.ui then CB.DB.ui.isOpen = false end
                    else
                        CB.UI.frame:Show()
                        if CB.DB.ui then CB.DB.ui.isOpen = true end
                        CB.UI:Refresh()
                    end
                else
                    -- TITAN PANEL VERHALTEN: Listen durchtogglen (D > H > S > HS > O)
                    if not CB.UI.frame:IsShown() then
                        CB.UI.frame:Show()
                        if CB.DB.ui then CB.DB.ui.isOpen = true end
                    end

                    -- Umschalten der Kategorie in der Datenbank
                    local current = CB.DB.ui.base or "D"
                    local nextMode = "D"
                    
                    if current == "D" then nextMode = "H"
                    elseif current == "H" then nextMode = "S"
                    elseif current == "S" then nextMode = "HS"
                    elseif current == "HS" then nextMode = "O"
                    else nextMode = "D" end
                    
                    CB.DB.ui.base = nextMode
                    CB.UI:Refresh() -- Hauptfenster sofort aktualisieren
                end
            end
        elseif button == "RightButton" then
            -- RECHTSKLICK: Immer Einstellungen
            if CB.UI and CB.UI.ToggleSettings then
                CB.UI:ToggleSettings()
            elseif CB.UI and CB.UI.CreateSettings then
                CB.UI:CreateSettings()
            end
        end
    end,

    OnTooltipShow = function(tooltip)
        tooltip:AddLine("|cff66ff66CrittersBoard|r")
        local rec = CB.LastGlobalRecord
        if rec then
            tooltip:AddLine(" ")
            tooltip:AddLine(CB.L["LDB_LAST_RECORD"] or "Letzter Rekord:", 1, 0.82, 0)
            if CB.UI and CB.UI.ShowTooltip then
                CB.UI:ShowTooltip(tooltip, rec)
            end
        else
            tooltip:AddLine(" ")
            tooltip:AddLine(CB.L["LDB_NO_DATA"] or "Keine Daten.", 0.5, 0.5, 0.5)
        end
        
        -- Hilfe-Texte aus Locales am Ende des Tooltips
        tooltip:AddLine(" ")
        tooltip:AddLine("|cffaaaaaa" .. (CB.L["LDB_TOOLTIP_L_BAR"] or "Links (Leiste): Wechseln") .. "|r")
        tooltip:AddLine("|cffaaaaaa" .. (CB.L["LDB_TOOLTIP_L_ICON"] or "Links (Icon): An/Aus") .. "|r")
        tooltip:AddLine("|cffaaaaaa" .. (CB.L["LDB_TOOLTIP_R"] or "Rechts: Optionen") .. "|r")
    end,
})

-- =========================================================
-- INITIALISIERUNG
-- =========================================================
function CB:InitLDB()
    if icon and CB.DB then
        CB.DB.ui = CB.DB.ui or {}
        CB.DB.ui.minimap = CB.DB.ui.minimap or { hide = false, minimapPos = 220 }
        
        if not icon:IsRegistered("CrittersBoard") then
            icon:Register("CrittersBoard", CB.LDB_Object, CB.DB.ui.minimap)
        end
        
        -- Icon setzen
        local current = CB.DB.ui.base or "D"
        if modeIcons then
            CB.LDB_Object.icon = modeIcons[current] or modeIcons["D"]
        end

        -- INITIALISIERUNG: Suche den zeitlich LETZTEN Rekord
        local lastRec = nil
        local latestTS = 0

        -- Wir gehen durch alle Kategorien, um den absolut neuesten Rekord zu finden
        local categories = {CB.DB.damage, CB.DB.heal, CB.DB.overkill, CB.DB.spells, CB.DB.healSpells}
        
        for _, cat in ipairs(categories) do
            if cat and cat.records then
                for _, rec in ipairs(cat.records) do
                    if rec.ts and rec.ts > latestTS then
                        latestTS = rec.ts
                        lastRec = rec
                    end
                end
            end
        end

        if lastRec then
            CB:UpdateLDB(lastRec)
        else
            CB.LDB_Object.text = "CB: " .. (CB.L["LDB_NO_DATA"] or "Keine Daten")
        end
    end
end

-- =========================================================
-- UPDATE LOGIK (Wird von Combat.lua aufgerufen)
-- =========================================================
function CB:UpdateLDB(rec)
    if not CB.LDB_Object or not rec then return end
    
    CB.LastGlobalRecord = rec

    -- 1. Zaubername lokalisieren (via ID)
    local sName = "???"
    if rec.spellId then
        local name = GetSpellInfo(rec.spellId)
        sName = name or rec.spell or "???"
    elseif rec.spell then
        sName = rec.spell
    end

    -- 2. Farbe festlegen (Rot bei Crit, Weiß sonst)
    local color = rec.isCrit and "ffff0000" or "ffffffff"
    local valStr = "|c" .. color .. (rec.amount or 0) .. "|r"

    -- 3. Text in die Leiste schreiben
    -- Format: "Spieler: Zauber Wert"
    CB.LDB_Object.text = string.format("%s: %s %s", 
        rec.player or "Ich", 
        sName, 
        valStr
    )
end