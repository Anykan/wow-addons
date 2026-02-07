CrittersBoard = CrittersBoard or {}
local CB = CrittersBoard

CB.UI = CB.UI or {}
local UI = CB.UI

local WIDTH = 320
local HEIGHT = 500 
local PAD_X = 20

-- =========================================================
-- Bestätigungs-Dialog
-- =========================================================
StaticPopupDialogs["CB_CONFIRM_CLEAR"] = {
  text = "Möchtest du wirklich alle Listen von CrittersBoard löschen?",
  button1 = "Ja",
  button2 = "Nein",
  OnAccept = function()
    CB.DB.damage.records = {}
    CB.DB.heal.records = {}
    CB.DB.overkill.records = {}
    if CB.DB.spells then CB.DB.spells.records = {} end
    if CB.DB.healSpells then CB.DB.healSpells.records = {} end
    print("|cff00ffffCrittersBoard:|r " .. (CB.L["MSG_LIST_CLEARED"] or "Listen gelöscht."))
    if UI.Refresh then UI:Refresh() end
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
}

local function GetModeKey(base, limit)
  return base .. limit
end

function UI:CreateSettings()
  if UI.settingsFrame then return end

  local s = CreateFrame("Frame", "CrittersBoardSettingsFrame", UIParent, "BasicFrameTemplate")
  UI.settingsFrame = s
  s:SetFrameStrata("DIALOG")
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
  s.title:SetText(CB.L["SETTINGS_TITLE"] or "CrittersBoard - Einstellungen")

  local y = 45

  -- Aktuellen Status aus der DB laden
  local mode = CB.DB.ui.mode or "D10"
  local curBase = mode:match("^(%a+)") or "D"
  local curLimit = mode:match("(%d+)$") or "10"

  -- Label für Dropdowns
  local labelList = s:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  labelList:SetPoint("TOPLEFT", PAD_X, -y)
  labelList:SetText(CB.L["LABEL_CHOOSE_LIST"] or "Liste auswählen:")
  y = y + 20

  -- 1. Dropdown: Auswahl der Liste
  local dropList = CreateFrame("Frame", "CB_SettingsDropList", s, "UIDropDownMenuTemplate")
  dropList:SetPoint("TOPLEFT", PAD_X - 15, -y)
  UIDropDownMenu_SetWidth(dropList, 150)

  UIDropDownMenu_Initialize(dropList, function()
    local items = {
      { text = "Schaden", value = "D" },
      { text = "Heilung", value = "H" },
      { text = "Overkill", value = "O" },
      { text = "Angriffe", value = "S" },
      { text = "Heil-Zauber", value = "HS" },
    }
    for _, item in ipairs(items) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = item.text
      info.value = item.value
      info.func = function(self)
        UIDropDownMenu_SetSelectedValue(dropList, self.value)
        curBase = self.value
        CB.DB.ui.mode = GetModeKey(curBase, curLimit)
        UIDropDownMenu_SetText(dropList, item.text)
        if UI.Refresh then UI:Refresh() end
      end
      info.checked = (curBase == item.value)
      UIDropDownMenu_AddButton(info)
    end
  end)

  -- Initialen Text setzen für Liste
  local baseNames = { D="Schaden", H="Heilung", O="Overkill", S="Angriffe", HS="Heil-Zauber" }
  UIDropDownMenu_SetText(dropList, baseNames[curBase] or "Schaden")

  -- 2. Dropdown: Auswahl des Limits (Top 10 / Top 100)
  local dropLimit = CreateFrame("Frame", "CB_SettingsDropLimit", s, "UIDropDownMenuTemplate")
  dropLimit:SetPoint("LEFT", dropList, "RIGHT", -20, 0)
  UIDropDownMenu_SetWidth(dropLimit, 80)

  UIDropDownMenu_Initialize(dropLimit, function()
    local limits = { "10", "100" }
    for _, l in ipairs(limits) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = "Top " .. l
      info.value = l
      info.func = function(self)
        UIDropDownMenu_SetSelectedValue(dropLimit, self.value)
        curLimit = self.value
        CB.DB.ui.mode = GetModeKey(curBase, curLimit)
        UIDropDownMenu_SetText(dropLimit, "Top " .. l)
        if UI.Refresh then UI:Refresh() end
      end
      info.checked = (curLimit == l)
      UIDropDownMenu_AddButton(info)
    end
  end)

  UIDropDownMenu_SetText(dropLimit, "Top " .. curLimit)

  y = y + 45

  -- =========================================================
  -- Checkboxen
  -- =========================================================
  
  -- Fenster fixieren
  local lockCB = CreateFrame("CheckButton", "CrittersBoardLockCB", s, "ChatConfigCheckButtonTemplate")
  lockCB:SetPoint("TOPLEFT", PAD_X, -y)
  lockCB.Text:SetText(CB.L["OPT_LOCK"] or "Fenster fixieren")
  lockCB:SetChecked(CB.DB.ui.locked)
  lockCB:SetScript("OnClick", function(self)
    CB.DB.ui.locked = self:GetChecked()
    if UI.UpdateLock then UI:UpdateLock() end
  end)

  y = y + 35

  -- Skalierung Slider
  local scaleSlider = CreateFrame("Slider", "CrittersBoardScaleSlider", s, "OptionsSliderTemplate")
  scaleSlider:SetPoint("TOPLEFT", PAD_X + 5, -y - 15)
  scaleSlider:SetMinMaxValues(0.5, 2.0)
  scaleSlider:SetValueStep(0.05)
  scaleSlider:SetValue(CB.DB.ui.scale or 1.0)
  _G[scaleSlider:GetName() .. 'Low']:SetText("0.5")
  _G[scaleSlider:GetName() .. 'High']:SetText("2.0")
  _G[scaleSlider:GetName() .. 'Text']:SetText((CB.L["OPT_SCALE"] or "Skalierung") .. ": " .. string.format("%.2f", CB.DB.ui.scale or 1.0))

  scaleSlider:SetScript("OnValueChanged", function(self, value)
    CB.DB.ui.scale = value
    _G[self:GetName() .. 'Text']:SetText((CB.L["OPT_SCALE"] or "Skalierung") .. ": " .. string.format("%.2f", value))
    if UI.frame then UI.frame:SetScale(value) end
  end)

  y = y + 55

  -- Audio Alerts
  local audioCB = CreateFrame("CheckButton", "CrittersBoardAudioCB", s, "ChatConfigCheckButtonTemplate")
  audioCB:SetPoint("TOPLEFT", PAD_X, -y)
  audioCB.Text:SetText(CB.L["OPT_AUDIO"] or "Audio und Warnmeldung")
  audioCB:SetChecked(CB.DB.ui.alertsEnabled)
  audioCB:SetScript("OnClick", function(self)
    CB.DB.ui.alertsEnabled = self:GetChecked()
  end)

  y = y + 35

  -- Sync Deaktivieren (Entwickler-Option)
  local disableSyncCB = CreateFrame("CheckButton", "CrittersBoardDisableSyncCB", s, "ChatConfigCheckButtonTemplate")
  disableSyncCB:SetPoint("TOPLEFT", PAD_X, -y)
  disableSyncCB.Text:SetText("|cffff3333" .. (CB.L["OPT_SYNC_DISABLED"] or "Sync aus") .. "|r")
  disableSyncCB:SetChecked(CB.DB.ui.disableSync)
  disableSyncCB:SetScript("OnClick", function(self)
    CB.DB.ui.disableSync = self:GetChecked()
  end)

  y = y + 55

  -- =========================================================
  -- Buttons
  -- =========================================================
  local btnWidth = (WIDTH - (PAD_X * 2) - 10) / 2

  local btnSync = CreateFrame("Button", nil, s, "UIPanelButtonTemplate")
  btnSync:SetSize(btnWidth, 24)
  btnSync:SetPoint("TOPLEFT", PAD_X, -y)
  btnSync:SetText(CB.L["BTN_SYNC"] or "Sync")
  btnSync:SetScript("OnClick", function()
    if CB.RequestSnapshot then CB:RequestSnapshot(true) end
  end)

  local btnClear = CreateFrame("Button", nil, s, "UIPanelButtonTemplate")
  btnClear:SetSize(btnWidth, 24)
  btnClear:SetPoint("TOPLEFT", PAD_X + btnWidth + 10, -y)
  btnClear:SetText(CB.L["BTN_CLEAR"] or "Liste löschen")
  btnClear:SetScript("OnClick", function()
    StaticPopup_Show("CB_CONFIRM_CLEAR")
  end)
end

function UI:ToggleSettings()
  if not UI.settingsFrame then UI:CreateSettings() end
  if UI.settingsFrame:IsShown() then
    UI.settingsFrame:Hide()
  else
    UI.settingsFrame:Show()
  end
end