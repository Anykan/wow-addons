CrittersBoard = CrittersBoard or {}
local CB = CrittersBoard

CB.UI = CB.UI or {}
local UI = CB.UI

local WIDTH = 320
local HEIGHT = 400
local PAD_X = 20

-- =========================================================
-- Bestätigungs-Dialog für das Löschen
-- =========================================================
StaticPopupDialogs["CB_CONFIRM_CLEAR"] = {
  text = "Möchtest du wirklich alle Listen von CrittersBoard löschen?",
  button1 = CB.L["YES"] or "Ja",
  button2 = CB.L["NO"] or "Nein",
  OnAccept = function()
    if CB.DB then
      CB.DB.damage.records = {}
      CB.DB.heal.records = {}
      CB.DB.overkill.records = {}
      if CB.DB.spells then CB.DB.spells.records = {} end
      if CB.DB.healSpells then CB.DB.healSpells.records = {} end
      CB:Print(CB.L["MSG_LIST_CLEARED"] or "Listen gelöscht.")
      if UI.Refresh then UI:Refresh() end
    end
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
}

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
  s.title:SetText(CB.L["SETTINGS_TITLE"] or "Einstellungen")

  local y = 45

  -- =========================================================
  -- Dropdown: Liste auswählen
  -- =========================================================
  local label = s:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  label:SetPoint("TOPLEFT", PAD_X, -y)
  label:SetText(CB.L["LABEL_CHOOSE_LIST"] or "Liste wählen:")
  y = y + 20

  local dropdown = CreateFrame("Frame", "CB_ModeDropdown", s, "UIDropDownMenuTemplate")
  dropdown:SetPoint("TOPLEFT", PAD_X - 15, -y)
  UIDropDownMenu_SetWidth(dropdown, 200)

  local modes = {"D10", "D100", "H10", "H100", "O10", "O100", "S_BEST", "HS_BEST"}
  
  UIDropDownMenu_Initialize(dropdown, function()
    for _, m in ipairs(modes) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = CB.L["MODE_" .. m] or m
      info.func = function()
        CB.DB.ui.mode = m
        UIDropDownMenu_SetText(dropdown, info.text)
        if UI.Refresh then UI:Refresh() end
      end
      UIDropDownMenu_AddButton(info)
    end
  end)
  UIDropDownMenu_SetText(dropdown, CB.L["MODE_" .. (CB.DB.ui.mode or "D10")])

  y = y + 45

  -- =========================================================
  -- Slider: Skalierung
  -- =========================================================
  local scaleSlider = CreateFrame("Slider", "CB_ScaleSlider", s, "OptionsSliderTemplate")
  scaleSlider:SetPoint("TOPLEFT", PAD_X, -y)
  scaleSlider:SetWidth(WIDTH - 40)
  scaleSlider:SetMinMaxValues(0.5, 2.0)
  scaleSlider:SetValueStep(0.1)
  scaleSlider:SetValue(CB.DB.ui.scale or 1.0)
  _G[scaleSlider:GetName() .. "Low"]:SetText("0.5")
  _G[scaleSlider:GetName() .. "High"]:SetText("2.0")
  _G[scaleSlider:GetName() .. "Text"]:SetText((CB.L["OPT_SCALE"] or "Skalierung") .. ": " .. string.format("%.1f", scaleSlider:GetValue()))

  scaleSlider:SetScript("OnValueChanged", function(self, value)
    CB.DB.ui.scale = value
    _G[self:GetName() .. "Text"]:SetText((CB.L["OPT_SCALE"] or "Skalierung") .. ": " .. string.format("%.1f", value))
    if UI.frame then UI.frame:SetScale(value) end
  end)

  y = y + 50

  -- =========================================================
  -- Checkboxen
  -- =========================================================
  
  -- Audio
  local audioCB = CreateFrame("CheckButton", "CB_AudioCB", s, "ChatConfigCheckButtonTemplate")
  audioCB:SetPoint("TOPLEFT", PAD_X, -y)
  audioCB.Text:SetText(CB.L["OPT_AUDIO"] or "Audio")
  audioCB:SetChecked(CB.DB.ui.alertsEnabled)
  audioCB:SetScript("OnClick", function(self) CB.DB.ui.alertsEnabled = self:GetChecked() end)
  y = y + 35

  -- Lock
  local lockCB = CreateFrame("CheckButton", "CB_LockCB", s, "ChatConfigCheckButtonTemplate")
  lockCB:SetPoint("TOPLEFT", PAD_X, -y)
  lockCB.Text:SetText(CB.L["OPT_LOCK"] or "Fixieren")
  lockCB:SetChecked(CB.DB.ui.locked)
  lockCB:SetScript("OnClick", function(self) 
    CB.DB.ui.locked = self:GetChecked()
    if UI.UpdateLock then UI:UpdateLock() end
  end)
  y = y + 35

  -- Disable Sync
  local syncOffCB = CreateFrame("CheckButton", "CB_SyncOffCB", s, "ChatConfigCheckButtonTemplate")
  syncOffCB:SetPoint("TOPLEFT", PAD_X, -y)
  syncOffCB.Text:SetText("|cffff3333" .. (CB.L["OPT_SYNC_DISABLED"] or "Sync aus") .. "|r")
  syncOffCB:SetChecked(CB.DB.ui.disableSync)
  syncOffCB:SetScript("OnClick", function(self) CB.DB.ui.disableSync = self:GetChecked() end)
  y = y + 55

  -- =========================================================
  -- Buttons
  -- =========================================================
  local btnWidth = (WIDTH - (PAD_X * 2) - 10) / 2

  local btnSync = CreateFrame("Button", nil, s, "UIPanelButtonTemplate")
  btnSync:SetSize(btnWidth, 26)
  btnSync:SetPoint("TOPLEFT", PAD_X, -y)
  btnSync:SetText(CB.L["BTN_SYNC"] or "Sync")
  btnSync:SetScript("OnClick", function()
    if CB.RequestSnapshot then CB:RequestSnapshot(true) end
  end)
--[[
  local btnClear = CreateFrame("Button", nil, s, "UIPanelButtonTemplate")
  btnClear:SetSize(btnWidth, 26)
  btnClear:SetPoint("TOPLEFT", PAD_X + btnWidth + 10, -y)
  btnClear:SetText(CB.L["BTN_CLEAR"] or "Löschen")
  btnClear:SetScript("OnClick", function() StaticPopup_Show("CB_CONFIRM_CLEAR") end)
]]--
  s:Hide()
end

function UI:ToggleSettings()
  if not UI.settingsFrame then UI:CreateSettings() end
  if UI.settingsFrame:IsShown() then
    UI.settingsFrame:Hide()
  else
    UI.settingsFrame:Show()
  end
end