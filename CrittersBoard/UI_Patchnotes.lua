CrittersBoard = CrittersBoard or {}
local CB = CrittersBoard
CB.UI = CB.UI or {}

-- =========================================================
-- PATCHNOTES POPUP
-- Zeigt einmalig beim ersten Login nach einem Update die Patchnotes.
-- Bei gleichzeitigem DB-Wipe: Warnhinweis + Wipe-Button statt Schließen-Button.
-- =========================================================

local FRAME_WIDTH  = 500
local FRAME_HEIGHT = 520
local SCROLL_HEIGHT = 360

function CB.UI:ShowPatchNotes(needsWipe)
    -- Sprache ermitteln
    local locale = GetLocale()
    local version = CB.VERSION or "0.6"
    local notes = CB.PATCHNOTES and CB.PATCHNOTES[version]
    if not notes then return end

    local data = (locale == "deDE") and notes.de or notes.en
    if not data then return end

    -- Frame nur einmal erstellen
    if not CB.UI.patchFrame then
        local f = CreateFrame("Frame", "CrittersBoardPatchFrame", UIParent, "BasicFrameTemplateWithInset")
        f:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
        f:SetPoint("CENTER")
        f:SetFrameStrata("DIALOG")
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)

        -- Titel
        f.titleText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        f.titleText:SetPoint("TOP", f, "TOP", 0, -8)
        f.titleText:SetWidth(FRAME_WIDTH - 60)
        f.titleText:SetJustifyH("CENTER")

        -- ScrollFrame
        local sf = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
        sf:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -40)
        sf:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -30, 80)

        local content = CreateFrame("Frame", nil, sf)
        content:SetWidth(FRAME_WIDTH - 50)
        content:SetHeight(1) -- wird dynamisch gesetzt
        sf:SetScrollChild(content)

        f.scrollContent = content

        -- Warntext (nur bei Wipe)
        f.wipeWarning = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        f.wipeWarning:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 16, 52)
        f.wipeWarning:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -16, 52)
        f.wipeWarning:SetJustifyH("CENTER")
        f.wipeWarning:SetTextColor(1, 0.2, 0.2)

        -- Wipe-Button
        local btnWipe = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        btnWipe:SetSize(200, 28)
        btnWipe:SetPoint("BOTTOM", f, "BOTTOM", 0, 16)
        btnWipe:SetText("")
        btnWipe:SetScript("OnClick", function()
            CB:WipeDatabase()
            ReloadUI()
        end)
        f.btnWipe = btnWipe

        -- Schließen-Button
        local btnClose = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        btnClose:SetSize(160, 28)
        btnClose:SetPoint("BOTTOM", f, "BOTTOM", 0, 16)
        btnClose:SetText(locale == "deDE" and "Schließen" or "Close")
        btnClose:SetScript("OnClick", function() f:Hide() end)
        f.btnClose = btnClose

        CB.UI.patchFrame = f
    end

    local f = CB.UI.patchFrame

    -- Titel setzen
    f.titleText:SetText(data.title)

    -- Zeileninhalt aufbauen
    local content = f.scrollContent
    -- Alte Zeilen entfernen
    for _, child in ipairs({content:GetChildren()}) do child:Hide() end
    -- FontStrings können nicht entfernt werden, also neu aufbauen via Regions
    -- Stattdessen: vorhandene FontStrings recyceln oder neu erstellen
    if not content.lines then content.lines = {} end
    for _, fs in ipairs(content.lines) do fs:Hide() end

    local yOffset = -6
    for i, line in ipairs(data.lines) do
        local fs = content.lines[i]
        if not fs then
            fs = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            fs:SetWidth(FRAME_WIDTH - 60)
            fs:SetJustifyH("LEFT")
            fs:SetWordWrap(true)
            content.lines[i] = fs
        end
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", content, "TOPLEFT", 8, yOffset)
        fs:SetText(line)
        fs:Show()
        yOffset = yOffset - fs:GetStringHeight() - 4
    end
    content:SetHeight(math.abs(yOffset) + 10)

    -- Wipe-Modus
    if needsWipe then
        local wipeText = (locale == "deDE")
            and "|cffff4444Datenbank wird zurückgesetzt — alle Rekorde gehen verloren.|r"
            or  "|cffff4444Database will be reset — all records will be lost.|r"
        local btnText = (locale == "deDE") and "OK — Wipe & Neu laden" or "OK — Wipe & Reload"
        f.wipeWarning:SetText(wipeText)
        f.wipeWarning:Show()
        f.btnWipe:SetText(btnText)
        f.btnWipe:Show()
        f.btnClose:Hide()
    else
        f.wipeWarning:Hide()
        f.btnWipe:Hide()
        f.btnClose:Show()
    end

    f:Show()
end
