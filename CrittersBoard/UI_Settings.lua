CrittersBoard = CrittersBoard or {}
local CB = CrittersBoard

CB.UI = CB.UI or {}
local UI = CB.UI

local WIDTH = 320
local HEIGHT = 410 -- Höhe etwas angepasst für neue Checkbox
local PAD_X = 20

function UI:CreateSettings()
  if UI.settingsFrame then return end

  local s = CreateFrame("Frame", "CrittersBoardSettingsFrame", UIParent, "BasicFrameTemplateWithInset")
  UI.settingsFrame = s

  -- ESC schließt das Fenster
  tinsert(UISpecialFrames, s:GetName())

  s:SetSize(WIDTH, HEIGHT)
  s:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  s:SetMovable(true)
  s:EnableMouse(true)
  s:RegisterForDrag("LeftButton")
  s:SetScript("OnDragStart", s.StartMoving)
  s:SetScript("OnDragStop", s.StopMovingOrSizing)

  s.title = s:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  s.title:SetPoint("TOP", 0, -6)
  s.title:SetText("CrittersBoard - Einstellungen")

  local y = 40

  -- Ensure DB defaults
  CB.DB.ui = CB.DB.ui or {}
  CB.DB.ui.mode = CB.DB.ui.mode or "D10"
  CB.DB.ui.scale = CB.DB.ui.scale or 1.0
  CB.DB.ui.locked = CB.DB.ui.locked or false
  CB.DB.ui.disableSync = CB.DB.ui.disableSync or false

  -- Default: Sync AN
  CB.DB.ui.shareAfterSync = (CB.DB.ui.shareAfterSync ~= false)

  -- Default: Audio AN
  CB.DB.ui.alertsEnabled = (CB.DB.ui.alertsEnabled ~= false)

  -- =========================================================
  -- Mode label
  -- =========================================================
  UI.modeText = s:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  UI.modeText:SetPoint("TOPLEFT", PAD_X, -y)
  UI.modeText:SetText("Liste auswählen")
  y = y + 18

  -- =========================================================
  -- Dropdown Split: LISTE + TOP
  -- =========================================================
  local function GetModeParts(mode)
    if not mode or mode == "" then
      return "D", 10
    end

    if mode == "D10" then return "D", 10 end
    if mode == "D100" then return "D", 100 end

    if mode == "H10" then return "H", 10 end
    if mode == "H100" then return "H", 100 end

    if mode == "O10" then return "O", 10 end
    if mode == "O100" then return "O", 100 end

    if mode == "S10" then return "S", 10 end
    if mode == "S100" then return "S", 100 end

    if mode == "HS10" then return "HS", 10 end
    if mode == "HS100" then return "HS", 100 end

    return "D", 10
  end

  local function MakeMode(listKey, topN)
    topN = tonumber(topN) or 10
    if topN ~= 10 and topN ~= 100 then topN = 10 end
    return tostring(listKey) .. tostring(topN)
  end

  local function ListKeyToText(listKey)
    if listKey == "D" then return "Schaden" end
    if listKey == "H" then return "Heilung" end
    if listKey == "O" then return "Overkill" end
    if listKey == "S" then return "Angriffe" end
    if listKey == "HS" then return "Heilungen" end
    return "Schaden"
  end

  local function TopNToText(topN)
    if tonumber(topN) == 100 then return "Top 100" end
    return "Top 10"
  end

  local function ApplyMode(listKey, topN)
    CB.DB.ui.mode = MakeMode(listKey, topN)

    if UI.modeText then
      UI.modeText:SetText(ListKeyToText(listKey) .. " - " .. TopNToText(topN))
    end

    if UI.Refresh then
      UI:Refresh()
    end
  end

  local currentListKey, currentTopN = GetModeParts(CB.DB.ui.mode)
  UI.modeText:SetText(ListKeyToText(currentListKey) .. " - " .. TopNToText(currentTopN))

  -- Dropdown 1: LISTE
  local listDrop = CreateFrame("Frame", "CrittersBoardListDrop", s, "UIDropDownMenuTemplate")
  listDrop:SetPoint("TOPLEFT", PAD_X - 12, -y)
  UIDropDownMenu_SetWidth(listDrop, 130)
  UIDropDownMenu_SetText(listDrop, ListKeyToText(currentListKey))

  UIDropDownMenu_Initialize(listDrop, function(self, level)
    local info = UIDropDownMenu_CreateInfo()
    info.notCheckable = false

    local function AddListOption(key)
      info.text = ListKeyToText(key)
      info.checked = (currentListKey == key)
      info.func = function()
        currentListKey = key
        UIDropDownMenu_SetText(listDrop, ListKeyToText(currentListKey))
        ApplyMode(currentListKey, currentTopN)
        CloseDropDownMenus()
      end
      UIDropDownMenu_AddButton(info, level)
    end

    AddListOption("D")
    AddListOption("H")
    AddListOption("O")
    AddListOption("S")
    AddListOption("HS")
  end)

  -- Dropdown 2: TOP
  local topDrop = CreateFrame("Frame", "CrittersBoardTopDrop", s, "UIDropDownMenuTemplate")
  topDrop:SetPoint("TOPLEFT", PAD_X + 155, -y)
  UIDropDownMenu_SetWidth(topDrop, 90)
  UIDropDownMenu_SetText(topDrop, TopNToText(currentTopN))

  UIDropDownMenu_Initialize(topDrop, function(self, level)
    local info = UIDropDownMenu_CreateInfo()
    info.notCheckable = false

    local function AddTopOption(n)
      info.text = TopNToText(n)
      info.checked = (currentTopN == n)
      info.func = function()
        currentTopN = n
        UIDropDownMenu_SetText(topDrop, TopNToText(currentTopN))
        ApplyMode(currentListKey, currentTopN)
        CloseDropDownMenus()
      end
      UIDropDownMenu_AddButton(info, level)
    end

    AddTopOption(10)
    AddTopOption(100)
  end)

  y = y + 55

  -- =========================================================
  -- Scale Slider
  -- =========================================================
  local scaleLabel = s:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  scaleLabel:SetPoint("TOPLEFT", PAD_X, -y)
  scaleLabel:SetText("Skalierung")
  y = y + 18

  local scaleSlider = CreateFrame("Slider", "CrittersBoardScaleSlider", s, "OptionsSliderTemplate")
  scaleSlider:SetPoint("TOPLEFT", PAD_X, -y)
  scaleSlider:SetWidth(WIDTH - 60)
  scaleSlider:SetMinMaxValues(0.7, 1.5)
  scaleSlider:SetValueStep(0.05)
  scaleSlider:SetObeyStepOnDrag(true)
  scaleSlider:SetValue(CB.DB.ui.scale or 1.0)

  _G[scaleSlider:GetName() .. "Low"]:SetText("0.7")
  _G[scaleSlider:GetName() .. "High"]:SetText("1.5")
  _G[scaleSlider:GetName() .. "Text"]:SetText(string.format("%.2f", CB.DB.ui.scale or 1.0))

  scaleSlider:SetScript("OnValueChanged", function(self, val)
    val = tonumber(val) or 1.0
    CB.DB.ui.scale = val
    _G[self:GetName() .. "Text"]:SetText(string.format("%.2f", val))
    if UI.ApplyScale then UI:ApplyScale() end
  end)

  y = y + 55

  -- =========================================================
  -- Lock Checkbox
  -- =========================================================
  local lockCB = CreateFrame("CheckButton", "CrittersBoardLockCB", s, "ChatConfigCheckButtonTemplate")
  lockCB:SetPoint("TOPLEFT", PAD_X, -y)
  lockCB.Text:SetText("Fenster fixieren")
  lockCB:SetChecked(CB.DB.ui.locked and true or false)
  lockCB:SetScript("OnClick", function(self)
    CB.DB.ui.locked = self:GetChecked() and true or false
    if UI.UpdateLock then UI:UpdateLock() end
  end)

  y = y + 35

  -- =========================================================
  -- Share After Sync Checkbox
  -- =========================================================
  local shareCB = CreateFrame("CheckButton", "CrittersBoardShareAfterSyncCB", s, "ChatConfigCheckButtonTemplate")
  shareCB:SetPoint("TOPLEFT", PAD_X, -y)
  shareCB.Text:SetText("Nach Sync an Online-Spieler teilen")
  shareCB:SetChecked(CB.DB.ui.shareAfterSync and true or false)
  shareCB:SetScript("OnClick", function(self)
    CB.DB.ui.shareAfterSync = self:GetChecked() and true or false
  end)

  y = y + 30

  -- =========================================================
  -- Audio Checkbox
  -- =========================================================
  local audioCB = CreateFrame("CheckButton", "CrittersBoardAudioCB", s, "ChatConfigCheckButtonTemplate")
  audioCB:SetPoint("TOPLEFT", PAD_X, -y)
  audioCB.Text:SetText("Audio und Warnmeldung")
  audioCB:SetChecked(CB.DB.ui.alertsEnabled and true or false)
  audioCB:SetScript("OnClick", function(self)
    CB.DB.ui.alertsEnabled = self:GetChecked() and true or false
  end)

  y = y + 30

  -- =========================================================
  -- NEU: Disable Sync Checkbox (Dev Tool)
  -- =========================================================
  local disableSyncCB = CreateFrame("CheckButton", "CrittersBoardDisableSyncCB", s, "ChatConfigCheckButtonTemplate")
  disableSyncCB:SetPoint("TOPLEFT", PAD_X, -y)
  disableSyncCB.Text:SetText("|cffff0000Synchronisierung deaktivieren|r")
  disableSyncCB:SetChecked(CB.DB.ui.disableSync and true or false)
  disableSyncCB:SetScript("OnClick", function(self)
    CB.DB.ui.disableSync = self:GetChecked() and true or false
    if CB.DB.ui.disableSync then
        print("|cff00ffffCrittersBoard:|r Sync wurde global deaktiviert.")
    else
        print("|cff00ffffCrittersBoard:|r Sync wurde aktiviert.")
    end
  end)

  y = y + 45

  -- =========================================================
  -- Buttons
  -- =========================================================
local btnWidth = (WIDTH - (PAD_X * 2) - 10) / 2

  local btnSync = CreateFrame("Button", nil, s, "UIPanelButtonTemplate")
  btnSync:SetSize(btnWidth, 24)
  btnSync:SetPoint("TOPLEFT", PAD_X, -y)
  btnSync:SetText("Sync")
  btnSync:SetScript("OnClick", function()
    if CB.RequestSnapshot then CB:RequestSnapshot(true) end
  end)

  local btnClear = CreateFrame("Button", nil, s, "UIPanelButtonTemplate")
  btnClear:SetSize(btnWidth, 24)
  btnClear:SetPoint("TOPLEFT", PAD_X + btnWidth + 10, -y)
  btnClear:SetText("Liste löschen")
  btnClear:SetScript("OnClick", function()
    if CB.ClearCurrentList then CB:ClearCurrentList() end
    if UI.Refresh then UI:Refresh() end
  end)

  s:Hide()
end

function UI:ToggleSettings()
  if not UI.settingsFrame then
    UI:CreateSettings()
  end

  if UI.settingsFrame:IsShown() then
    UI.settingsFrame:Hide()
  else
    UI.settingsFrame:Show()
  end
end