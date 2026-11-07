-- Titan-Panel-Plugin: zeigt die Waffenfähigkeit der Hauptwaffe in der Titan-Leiste
local TITAN_WF_ID = "WaffenFaehigkeit"
local TITAN_WF_BUTTON = "TitanPanel" .. TITAN_WF_ID .. "Button"
local WF_ICON = "Interface\\Icons\\INV_Sword_04"

-- Alle Fähigkeiten aus dem Skill-Fenster (C_SkillInfo, in Forever vorhanden)
local function GetSkillList()
    local list = {}
    if not (C_SkillInfo and C_SkillInfo.GetSkillLineInfo) then return list end
    for i = 1, 300 do
        local s = C_SkillInfo.GetSkillLineInfo(i)
        if not s or not s.name then break end
        if not s.isHeader then
            list[#list + 1] = {
                name = s.name,
                rank = s.rank or s.skillRank or 0,
                mod = s.modifier or s.skillModifier or 0,
                max = s.maxRank or s.skillMaxRank or 0,
            }
        end
    end
    return list
end

-- Name ohne Präfix "Einhand"/"Zweihand", z. B. "Einhandschwerter" -> "schwerter"
local function Base(name)
    name = (name or ""):lower()
    return (name:gsub("^einhand", ""):gsub("^zweihand", ""))
end

-- Wert und Maximum der Hauptwaffe, nil wenn keine Waffe oder keine Fähigkeit passt
local function GetWeaponSkill()
    local itemID = GetInventoryItemID("player", 16)
    if not itemID then return nil end

    local getItemInfo = GetItemInfo or (C_Item and C_Item.GetItemInfo)
    if not getItemInfo then return nil end
    local info = { getItemInfo(itemID) }
    local itemSubType, classID, subclassID = info[7], info[12], info[13]
    if classID ~= 2 then return nil end -- keine Waffe

    local localizedName = GetItemSubClassInfo and subclassID and GetItemSubClassInfo(2, subclassID)
    local skills = GetSkillList()

    -- zuerst exakter Name, danach ohne Präfix
    for _, s in ipairs(skills) do
        if s.name == localizedName or s.name == itemSubType then
            return s.rank + s.mod, s.max
        end
    end
    local target = Base(itemSubType)
    if target ~= "" then
        for _, s in ipairs(skills) do
            if Base(s.name) == target then
                return s.rank + s.mod, s.max
            end
        end
    end
    return nil
end

-- Titan-Callbacks
local function GetButtonText()
    local value, maxRank = GetWeaponSkill()
    if value then
        return "Waffe", value .. "/" .. maxRank
    end
    return "Waffe", "–"
end

local function GetTooltipText()
    local value, maxRank = GetWeaponSkill()
    if value then
        return "Waffenfähigkeit: " .. value .. " / " .. maxRank
    end
    return "Keine Waffe in der Hand oder keine passende Fähigkeit gefunden."
end

local function Create()
    if _G[TITAN_WF_BUTTON] then return end

    local container = CreateFrame("Frame", nil, UIParent)
    local button = CreateFrame("Button", TITAN_WF_BUTTON, container, "TitanPanelComboTemplate")
    button:SetFrameStrata("FULLSCREEN")

    button.registry = {
        id = TITAN_WF_ID,
        category = "Information",
        version = "0.1.0",
        menuText = "Waffenfähigkeit",
        buttonTextFunction = GetButtonText,
        tooltipTitle = "Waffenfähigkeit",
        tooltipTextFunction = GetTooltipText,
        iconWidth = 16,
        notes = "Zeigt die Waffenfähigkeit der Hauptwaffe.",
        controlVariables = {
            ShowIcon = true,
            ShowLabelText = true,
            ShowColoredText = false,
            DisplayOnRightSide = true,
        },
        savedVariables = {
            ShowIcon = 1,
            ShowLabelText = 1,
            DisplayOnRightSide = false,
        },
    }

    button:RegisterEvent("PLAYER_LOGIN")
    button:RegisterEvent("PLAYER_ENTERING_WORLD")
    button:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    button:RegisterEvent("SKILL_LINES_CHANGED")

    button:SetScript("OnShow", function(self)
        local icon = _G[TITAN_WF_BUTTON .. "Icon"]
        if icon then icon:SetTexture(WF_ICON) end
        if Titan_G and Titan_G.plugins then Titan_G.plugins.OnShow(self) end
    end)
    button:SetScript("OnEvent", function()
        if Titan_G and Titan_G.plugins then Titan_G.plugins.UpdateButton(TITAN_WF_ID) end
    end)
end

-- Nur bauen, wenn Titan Panel geladen ist
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, _, name)
    if name ~= "WaffenFaehigkeit" then return end
    if TITAN_ID then
        Create()
    end
    self:UnregisterEvent("ADDON_LOADED")
end)
