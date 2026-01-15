CrittersBoard = CrittersBoard or {}
local CB = CrittersBoard

CB.UI = CB.UI or {}
local UI = CB.UI

function UI:CreateSettings()
  local s = CreateFrame("Frame", "CrittersBoardSettingsFrame", UIParent, "BackdropTemplate")

  -- immer im Vordergrund
  s:SetFrameStrata("DIALOG")
  s:SetFrameLevel(200)

  -- Default Position
  s:ClearAllPoints()
  s:SetPoint("CENTER", UIParent, "CENTER", 40, -40)

  s:SetMovable(true)
  s:EnableMouse(true)
  s:RegisterForDrag("LeftButton")
  s:SetScript("OnDragStart", s.StartMoving)
  s:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

  s:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
  })
  s:SetBackdropColor(0, 0, 0, 0.98)

  local PAD_X, PAD_TOP, PAD_BOTTOM = 12, 10, 16
  local WIDTH = 380
  s:SetWidth(WIDTH)

  local title = s:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", PAD_X, -PAD_TOP)
  title:SetText("Einstellungen")

  local btnClose = CreateFrame("Button", nil, s, "UIPanelCloseButton")
  btnClose:SetPoint("TOPRIGHT", 2, 2)

  local y = PAD_TOP + 28
  local function NextRow(px) y = y + (px or 26) end

  -- Dropdown Label
  local ddLabel = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  ddLabel:SetPoint("TOPLEFT", PAD_X, -y)
  ddLabel:SetText("Anzeige:")
  NextRow(18)

  -- Dropdown
  local dd = CreateFrame("Frame", "CrittersBoardModeDropdown", s, "UIDropDownMenuTemplate")
  dd:SetPoint("TOPLEFT", PAD_X - 16, -y)

  local function SetMode(modeKey, text)
    if not CB.DB or not CB.DB.ui then return end
    CB.DB.ui.mode = modeKey
    UIDropDownMenu_SetText(dd, text)
    if UI.Refresh then UI:Refresh() end
  end

  UIDropDownMenu_Initialize(dd, function(self, level)
    local info = UIDropDownMenu_CreateInfo()

    info.text = "TOP 10 Schaden"
    info.func = function() SetMode("D10", "TOP 10 Schaden") end
    UIDropDownMenu_AddButton(info, level)

    info.text = "TOP 100 Schaden"
    info.func = function() SetMode("D100", "TOP 100 Schaden") end
    UIDropDownMenu_AddButton(info, level)

    info.text = "TOP 10 Heal"
    info.func = function() SetMode("H10", "TOP 10 Heal") end
    UIDropDownMenu_AddButton(info, level)

    info.text = "TOP 100 Heal"
    info.func = function() SetMode("H100", "TOP 100 Heal") end
    UIDropDownMenu_AddButton(info, level)

    info.text = "TOP 10 Overkill"
    info.func = function() SetMode("O10", "TOP 10 Overkill") end
    UIDropDownMenu_AddButton(info, level)

    info.text = "TOP 100 Overkill"
    info.func = function() SetMode("O100", "TOP 100 Overkill") end
    UIDropDownMenu_AddButton(info, level)
  end)

  UIDropDownMenu_SetWidth(dd, 220)

  local currentText = "TOP 10 Schaden"
  if CB.DB and CB.DB.ui then
    if CB.DB.ui.mode == "D100" then currentText = "TOP 100 Schaden"
    elseif CB.DB.ui.mode == "H10" then currentText = "TOP 10 Heal"
    elseif CB.DB.ui.mode == "H100" then currentText = "TOP 100 Heal"
    elseif CB.DB.ui.mode == "O10" then currentText = "TOP 10 Overkill"
    elseif CB.DB.ui.mode == "O100" then currentText = "TOP 100 Overkill"
    end
  end
  UIDropDownMenu_SetText(dd, currentText)
  NextRow(40)

  -- Checkbox: Lock
  local lock = CreateFrame("CheckButton", nil, s, "ChatConfigCheckButtonTemplate")
  lock:SetPoint("TOPLEFT", PAD_X, -y)
  lock.Text:SetText("Fenster fixiert")
  lock:SetChecked(CB.DB and CB.DB.ui and CB.DB.ui.locked and true or false)
  lock:SetScript("OnClick", function(self)
    if not CB.DB or not CB.DB.ui then return end
    CB.DB.ui.locked = self:GetChecked() and true or false
    if UI.UpdateLock then UI:UpdateLock() end
  end)
  NextRow()

  -- Checkbox: Alerts on/off
  local alerts = CreateFrame("CheckButton", nil, s, "ChatConfigCheckButtonTemplate")
  alerts:SetPoint("TOPLEFT", PAD_X, -y)
  alerts.Text:SetText("Alerts aktivieren (Sound + Meldung)")
  alerts:SetChecked(CB.DB and CB.DB.ui and CB.DB.ui.alertsEnabled ~= false)
  alerts:SetScript("OnClick", function(self)
    if not CB.DB or not CB.DB.ui then return end
    CB.DB.ui.alertsEnabled = self:GetChecked() and true or false
    if CB.Print then CB:Print("Alerts: " .. (CB.DB.ui.alertsEnabled and "AN" or "AUS")) end
  end)
  NextRow()

  -- NEW: Share after sync
  local share = CreateFrame("CheckButton", nil, s, "ChatConfigCheckButtonTemplate")
  share:SetPoint("TOPLEFT", PAD_X, -y)
  share.Text:SetText("Nach Sync meine Liste an alle senden")
  share:SetChecked(CB.DB and CB.DB.ui and CB.DB.ui.shareAfterSync == true)
  share:SetScript("OnClick", function(self)
    if not CB.DB or not CB.DB.ui then return end
    CB.DB.ui.shareAfterSync = self:GetChecked() and true or false
    if CB.Print then
      CB:Print("Share After Sync: " .. (CB.DB.ui.shareAfterSync and "AN" or "AUS"))
    end
  end)
  NextRow()

  -- Slider: Background Transparency
  local sliderLabel = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  sliderLabel:SetPoint("TOPLEFT", PAD_X, -y)
  sliderLabel:SetText("Transparenz Hintergrund:")
  NextRow(18)

  local slider = CreateFrame("Slider", "CrittersBoardAlphaSlider", s, "OptionsSliderTemplate")
  slider:SetPoint("TOPLEFT", PAD_X, -y)
  slider:SetWidth(WIDTH - (PAD_X * 2))
  slider:SetMinMaxValues(0, 100)
  slider:SetValueStep(1)
  slider:SetObeyStepOnDrag(true)

  local currentPercent = 15
  if CB.DB and CB.DB.ui then
    currentPercent = math.floor((1 - (CB.DB.ui.bgAlpha or 0.85)) * 100 + 0.5)
  end
  slider:SetValue(currentPercent)

  _G[slider:GetName() .. "Low"]:SetText("0%")
  _G[slider:GetName() .. "High"]:SetText("100%")
  _G[slider:GetName() .. "Text"]:SetText(currentPercent .. "%")

  slider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value + 0.5)
    _G[self:GetName() .. "Text"]:SetText(value .. "%")
    if not CB.DB or not CB.DB.ui then return end
    CB.DB.ui.alpha = 1 - (value / 100)
    if UI.ApplyMainAlpha then UI:ApplyMainAlpha() end
  end)
  NextRow(44)

  -- Scale Slider
  local scaleLabel = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  scaleLabel:SetPoint("TOPLEFT", PAD_X, -y)
  scaleLabel:SetText("Hauptfenster Skalierung:")
  NextRow(18)

  local scale = CreateFrame("Slider", "CrittersBoardScaleSlider", s, "OptionsSliderTemplate")
  scale:SetPoint("TOPLEFT", PAD_X, -y)
  scale:SetWidth(WIDTH - (PAD_X * 2))
  scale:SetMinMaxValues(70, 140)
  scale:SetValueStep(1)
  scale:SetObeyStepOnDrag(true)

  local curScale = 100
  if CB.DB and CB.DB.ui and CB.DB.ui.scale then
    curScale = math.floor((CB.DB.ui.scale * 100) + 0.5)
  end
  scale:SetValue(curScale)

  _G[scale:GetName() .. "Low"]:SetText("70%")
  _G[scale:GetName() .. "High"]:SetText("140%")
  _G[scale:GetName() .. "Text"]:SetText(curScale .. "%")

  scale:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value + 0.5)
    _G[self:GetName() .. "Text"]:SetText(value .. "%")
    if not CB.DB or not CB.DB.ui then return end
    CB.DB.ui.scale = value / 100
    if UI.ApplyScale then UI:ApplyScale() end
  end)
  NextRow(44)

  -- Delete Button
  local btnDelete = CreateFrame("Button", nil, s, "UIPanelButtonTemplate")
  btnDelete:SetSize(WIDTH - 40, 24)
  btnDelete:SetPoint("TOPLEFT", PAD_X + 8, -y)
  btnDelete:SetText("Eigene Liste löschen")
  btnDelete:SetScript("OnClick", function()
    if not CB.DB then return end

    wipe(CB.DB.damage.records); wipe(CB.DB.damage.seen); CB.DB.damage.revision = 0
    wipe(CB.DB.heal.records); wipe(CB.DB.heal.seen); CB.DB.heal.revision = 0
    wipe(CB.DB.overkill.records); wipe(CB.DB.overkill.seen); CB.DB.overkill.revision = 0

    if UI.Refresh then UI:Refresh() end
    if CB.Print then CB:Print("Deine Listen wurden gelöscht.") end
  end)
  NextRow(30)

  -- Sync Button
  local btnSync = CreateFrame("Button", nil, s, "UIPanelButtonTemplate")
  btnSync:SetSize(WIDTH - 40, 24)
  btnSync:SetPoint("TOPLEFT", PAD_X + 8, -y)
  btnSync:SetText("Manueller Sync (Online-Spieler)")
  btnSync:SetScript("OnClick", function()
    if CB.RequestSnapshot then
      CB:RequestSnapshot(true)
    end
  end)
  NextRow(30)

  UI.settingsFrame = s
  UI.btnSync = btnSync

  s:SetHeight(y + PAD_BOTTOM + 10)
  s:Hide()
end

function UI:ToggleSettings()
  if not UI.settingsFrame then return end
  UI.settingsFrame:SetShown(not UI.settingsFrame:IsShown())
end
