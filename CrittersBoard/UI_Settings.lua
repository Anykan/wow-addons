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
  -- 1. Dropdown: Kategorie auswählen (D, H, O, S, HS)
  -- =========================================================
  local catLabel = s:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  catLabel:SetPoint("TOPLEFT", PAD_X, -y)
  catLabel:SetText(CB.L["LABEL_CHOOSE_LIST"] or "Kategorie:")
  
  local catDrop = CreateFrame("Frame", "CB_CategoryDrop", s, "UIDropDownMenuTemplate")
  catDrop:SetPoint("TOPLEFT", PAD_X + 90, -y + 8)
  UIDropDownMenu_SetWidth(catDrop, 150)

  UIDropDownMenu_Initialize(catDrop, function()
      local opts = {
          { text = CB.L["CAT_D"] or "Schaden", val = "D" },
          { text = CB.L["CAT_H"] or "Heilung", val = "H" },
          { text = CB.L["CAT_O"] or "Overkill", val = "O" },
          { text = CB.L["CAT_S"] or "Angriffe", val = "S" },
          { text = CB.L["CAT_HS"] or "Heil-Zauber", val = "HS" },
      }
      for _, o in ipairs(opts) do
          local info = UIDropDownMenu_CreateInfo()
          info.text = o.text
          info.value = o.val
          info.func = function(button)
              CB.DB.ui.base = button.value
              UIDropDownMenu_SetSelectedValue(catDrop, button.value)
              UIDropDownMenu_SetText(catDrop, o.text) 
              if UI.scrollFrame then
                  UI.scrollFrame:SetVerticalScroll(0)
              end
              if UI.Refresh then UI:Refresh() end
          end
          info.checked = (CB.DB.ui.base == o.val)
          UIDropDownMenu_AddButton(info)
      end
  end)
  
  -- Initialer Text beim Öffnen der Settings
  local currentBase = CB.DB.ui.base or "D"
  UIDropDownMenu_SetText(catDrop, CB.L["CAT_"..currentBase] or currentBase)

  y = y + 40 

  -- =========================================================
  -- 2. Dropdown: Limit auswählen (10, 100)
  -- =========================================================
  local limLabel = s:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  limLabel:SetPoint("TOPLEFT", PAD_X, -y)
  limLabel:SetText(CB.L["LABEL_CHOOSE_LIMIT"] or "Anzahl:")

  local limDrop = CreateFrame("Frame", "CB_LimitDrop", s, "UIDropDownMenuTemplate")
  limDrop:SetPoint("TOPLEFT", PAD_X + 90, -y + 8)
  UIDropDownMenu_SetWidth(limDrop, 150)

  UIDropDownMenu_Initialize(limDrop, function()
	  local opts = { 
          { text = (CB.L["LABEL_TOP"] or "Top") .. " 10", val = 10 }, 
          { text = (CB.L["LABEL_TOP"] or "Top") .. " 25", val = 25 }, 
          { text = (CB.L["LABEL_TOP"] or "Top") .. " 50", val = 50 }, 
          { text = (CB.L["LABEL_TOP"] or "Top") .. " 100", val = 100 } 
      }
      for _, o in ipairs(opts) do
          local info = UIDropDownMenu_CreateInfo()
          info.text = o.text
          info.value = o.val
          info.func = function(button)
              CB.DB.ui.limit = button.value
              UIDropDownMenu_SetSelectedValue(limDrop, button.value)
              UIDropDownMenu_SetText(limDrop, o.text)
              if UI.scrollFrame then
                  UI.scrollFrame:SetVerticalScroll(0)
              end
              if UI.Refresh then UI:Refresh() end
          end
          info.checked = (CB.DB.ui.limit == o.val)
          UIDropDownMenu_AddButton(info)
      end
  end)
  
  -- Initialer Text beim Öffnen der Settings
  local currentLimit = CB.DB.ui.limit or 10
  UIDropDownMenu_SetText(limDrop, (CB.L["LABEL_TOP"] or "Top") .. " " .. currentLimit)

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
  
-- 5. Slider: Alert Limit (Warteschlange) - JETZT UNTER AUDIO
  local alertSlider = CreateFrame("Slider", "CB_AlertLimitSlider", s, "OptionsSliderTemplate")
  alertSlider:SetPoint("TOPLEFT", PAD_X + 10, -y - 15) -- Kleiner Einzug nach rechts
  alertSlider:SetWidth(WIDTH - 60)
  alertSlider:SetMinMaxValues(1, 20)
  alertSlider:SetValueStep(1)
  alertSlider:SetValue(CB.DB.ui.alertLimit or 5)
  _G[alertSlider:GetName() .. "Low"]:SetText("1")
  _G[alertSlider:GetName() .. "High"]:SetText("20")
  _G[alertSlider:GetName() .. "Text"]:SetText((CB.L["OPT_ALERT_LIMIT"] or "Max. Sounds") .. ": " .. alertSlider:GetValue())
  alertSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value)
    CB.DB.ui.alertLimit = value
    _G[self:GetName() .. "Text"]:SetText((CB.L["OPT_ALERT_LIMIT"] or "Max. Sounds") .. ": " .. value)
  end)
  
  y = y + 45 -- Platz für den Slider-Text
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