local CB = CrittersBoard
if not CB then return end

local LDB = LibStub:GetLibrary("LibDataBroker-1.1", true)
local LDBIcon = LibStub:GetLibrary("LibDBIcon-1.0", true)

if not LDB then return end

CB.LastGlobalRecord = nil

-- Icons für die verschiedenen Kategorien (für die Leiste)
local modeIcons = {
    ["D"]  = "Interface\\Icons\\Spell_Fire_Fireball02",
    ["H"]  = "Interface\\Icons\\Spell_Holy_HolyBolt",
    ["S"]  = "Interface\\Icons\\Ability_MeleeDamage",
    ["HS"] = "Interface\\Icons\\Spell_Holy_SurgeOfLight",
    ["O"]  = "Interface\\Icons\\Spell_Shadow_DeathPact",
	["DT"] = "Interface\\Icons\\Ability_Warrior_EndlessRage",
}

-- =========================================================
-- LDB OBJEKT ERSTELLUNG
-- =========================================================
CB.LDB_Object = LDB:NewDataObject("CrittersBoard", {
    type = "data source",
    label = "CrittersBoard",
    suffix = "CB",
    text = "CB: " .. (CB.L["LDB_WAITING"] or "Warte..."),
    icon = "Interface\\Icons\\Spell_Fire_Fireball02",
    
    align = "right",
    dockingPos = "right",

    OnClick = function(self, button)
        if button == "LeftButton" then
            if CB.UI and CB.UI.frame then
                -- Check ob Minimap-Icon (über Name oder Parent)
                local parent = self:GetParent()
                local name = self.GetName and self:GetName() or ""
                local isMinimap = (parent == Minimap or name:find("LibDBIcon") or name:find("Minimap"))

                if isMinimap then
                    -- MINIMAP VERHALTEN: Fenster an/aus
                    if CB.UI.frame:IsShown() then
                        CB.UI.frame:Hide()
                        if CB.DB.ui then CB.DB.ui.isOpen = false end
                    else
                        CB.UI.frame:Show()
                        if CB.DB.ui then CB.DB.ui.isOpen = true end
                        CB.UI:Refresh()
                    end
                else
                    -- TITAN PANEL VERHALTEN: Kategorien wechseln
                    if not CB.UI.frame:IsShown() then
                        CB.UI.frame:Show()
                    end
                    local current = CB.DB.ui.base or "D"
                    local nextMode = "D"
                    if current == "D" then nextMode = "H"
					elseif current == "H" then nextMode = "S"
					elseif current == "S" then nextMode = "HS"
					elseif current == "HS" then nextMode = "O"
					elseif current == "O" then nextMode = "DT" -- NEU
					elseif current == "DT" then nextMode = "D" -- NEU
					else nextMode = "D" end
                    
                    CB.DB.ui.base = nextMode
                    CB.LDB_Object.icon = modeIcons[nextMode] or modeIcons["D"]
                    CB.UI:Refresh()
                end
            end
        elseif button == "RightButton" then
            if CB.UI and CB.UI.ToggleSettings then
                CB.UI:ToggleSettings()
            end
        end
    end,

    OnTooltipShow = function(tooltip)
        local parent = tooltip:GetOwner()
        local name = parent and parent.GetName and parent:GetName() or ""
        local isMinimap = (parent == Minimap or name:find("LibDBIcon") or name:find("Minimap"))

        if isMinimap then
            -- === NUR MINIMAP TOOLTIP (3 Zeilen) ===
            tooltip:AddLine(CB.L["MINIMAP_TITLE"] or "|cff66ff66CrittersBoard|r")
            tooltip:AddLine(" ")
            tooltip:AddLine(CB.L["MINIMAP_HINT_L"] or "|cffaaaaaaLinks-Klick: Fenster An/Aus|r")
            tooltip:AddLine(CB.L["MINIMAP_HINT_R"] or "|cffaaaaaaRechts-Klick: Einstellungen|r")
        else
            -- === VOLLER TITAN PANEL TOOLTIP ===
            tooltip:AddLine(CB.L["LDB_TITLE"] or "|cff66ff66CrittersBoard Records|r")
            local rec = CB.LastGlobalRecord
            if rec then
                tooltip:AddLine(" ")
                tooltip:AddLine(CB.L["LDB_LAST_RECORD"] or "Aktueller Leader:", 1, 0.82, 0)
                if CB.UI and CB.UI.ShowTooltip then
                    CB.UI:ShowTooltip(tooltip, rec)
                end
            else
                tooltip:AddLine(" ")
                tooltip:AddLine(CB.L["LDB_NO_DATA"] or "No records logged.", 0.5, 0.5, 0.5)
            end
            tooltip:AddLine(" ")
            tooltip:AddLine(CB.L["LDB_HINT_L"] or "|cffaaaaaaLinks-Klick: Kategorie wechseln|r")
            tooltip:AddLine(CB.L["MINIMAP_HINT_R"] or "|cffaaaaaaRechts-Klick: Einstellungen|r")
        end
    end,
})

-- =========================================================
-- UPDATE LOGIK
-- =========================================================
function CB:UpdateLDB(rec)
    if not CB.LDB_Object or not rec then return end
    CB.LastGlobalRecord = rec

    local sName = "???"
    if rec.spellId and rec.spellId > 0 then
        sName = GetSpellInfo(rec.spellId) or rec.spell or "???"
    elseif rec.spell then
        sName = rec.spell
    end

    local color = rec.isCrit and "ffff3333" or "ffffffff"
    local valStr = "|c" .. color .. (rec.amount or 0) .. "|r"

    CB.LDB_Object.text = string.format("%s: %s %s", 
        rec.player or "Ich", 
        sName, 
        valStr
    )
end