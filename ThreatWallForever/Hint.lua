--[[
  Hint.lua — einmaliger Hinweis, wenn die Gegner-Nameplates aus sind.

  Ohne sie findet das Addon einen Gegner nur, solange du oder ein Mitspieler
  ihn anvisiert hast (siehe candidateUnits() in Detection.lua) – er fällt aus
  der Liste, sobald sich das Ziel ändert. Eigenes Popup aus demselben Grund
  wie das selbstgebaute Menü: Blizzards Popup-Vorlagen sind auf diesem Client
  nicht verlässlich, und dieses braucht außerdem eine Checkbox.
  (Wird später zur Statusliste aller Spiel-Optionen ausgebaut, Anforderung M.)
]]

local _, ns = ...
local C = ns.Config
local L = ns.L
local H = C.HINT

local hintPopup

local function openNameplateSettings()
  local done = false
  if Settings and Settings.OpenToCategory then
    done = pcall(Settings.OpenToCategory, H.OPTIONS_CATEGORY) and true or false
  end
  if not done and InterfaceOptionsFrame_OpenToCategory then
    -- Bekannte Eigenheit des älteren Optionsfensters: Der erste Aufruf öffnet
    -- das Fenster oft ohne die richtige Seite, der zweite behebt das.
    pcall(InterfaceOptionsFrame_OpenToCategory, H.OPTIONS_CATEGORY)
    done = pcall(InterfaceOptionsFrame_OpenToCategory, H.OPTIONS_CATEGORY) and true or false
  end
  if not done then
    pcall(function()
      if SettingsPanel then ShowUIPanel(SettingsPanel)
      elseif InterfaceOptionsFrame then ShowUIPanel(InterfaceOptionsFrame) end
    end)
  end
end

local function buildHintPopup()
  -- Gleicher Fensterrahmen wie das Patchnotes-Popup von CrittersBoard (auf
  -- diesem Client bewährt): ein schlichtes Blizzard-Dialogfenster mit
  -- Titelleiste und eigenem Schließen-Button (X).
  hintPopup = CreateFrame('Frame', H.NAME, UIParent, 'BasicFrameTemplateWithInset')
  hintPopup:SetSize(H.WIDTH, H.HEIGHT)
  hintPopup:SetPoint('CENTER', UIParent, 'CENTER', 0, H.OFFSET_Y)
  hintPopup:SetFrameStrata('DIALOG')
  hintPopup:SetToplevel(true)
  hintPopup:EnableMouse(true)
  hintPopup:Hide()
  if UISpecialFrames then table.insert(UISpecialFrames, H.NAME) end

  -- Eigener Titeltext statt des TitleText-Kinds der Vorlage (dessen Name ist auf
  -- diesem Client nicht sicher). Ein einzelner TOP-Anker mit fester Breite statt
  -- TOPLEFT+TOPRIGHT: mit zwei Ankern ohne Breite wurde hier nicht zentriert.
  -- GameFontNormalLarge war zu hoch für die schmale Titelleiste, daher kleiner.
  local title = hintPopup:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
  title:SetPoint('TOP', hintPopup, 'TOP', 0, H.TITLE_Y)
  title:SetWidth(H.WIDTH - H.TITLE_MARGIN)
  title:SetJustifyH('CENTER')
  title:SetWordWrap(true)
  title:SetText(L.HINT_TITLE)

  local body = hintPopup:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  body:SetPoint('TOPLEFT', H.BODY_X, H.BODY_Y)
  body:SetPoint('TOPRIGHT', -H.BODY_X, H.BODY_Y)
  body:SetJustifyH('LEFT')
  body:SetJustifyV('TOP')
  if body.SetSpacing then body:SetSpacing(H.BODY_SPACING) end
  body:SetText(L.HINT_BODY)

  -- Eine untere Zeile: Checkbox links, beide Buttons rechts.
  local ok = CreateFrame('Button', nil, hintPopup, 'UIPanelButtonTemplate')
  ok:SetSize(H.OK_W, H.BTN_H)
  ok:SetPoint('BOTTOMRIGHT', -H.EDGE, H.EDGE)
  ok:SetText(L.HINT_OK)
  ok:SetScript('OnClick', function() hintPopup:Hide() end)

  local settingsBtn = CreateFrame('Button', nil, hintPopup, 'UIPanelButtonTemplate')
  settingsBtn:SetSize(H.SETTINGS_W, H.BTN_H)
  settingsBtn:SetPoint('RIGHT', ok, 'LEFT', H.BTN_GAP, 0)
  settingsBtn:SetText(L.HINT_OPEN_SETTINGS)
  settingsBtn:SetScript('OnClick', openNameplateSettings)

  local check = CreateFrame('CheckButton', H.CHECK_NAME, hintPopup, 'UICheckButtonTemplate')
  check:SetSize(H.CHECK_SIZE, H.CHECK_SIZE)
  check:SetPoint('BOTTOMLEFT', H.EDGE, H.EDGE)
  local label = _G[check:GetName() .. 'Text']
  if label then
    label:SetText(L.HINT_DONT_SHOW)
    label:SetFontObject('GameFontHighlightSmall')
  end
  check:SetScript('OnClick', function(self) ns.db.hideNameplateHint = self:GetChecked() and true or false end)
  hintPopup.check = check
end

function ns.showHintPopup()
  if not hintPopup then buildHintPopup() end
  hintPopup.check:SetChecked(false)
  hintPopup:Show()
end

function ns.checkNameplateSetting()
  if ns.db.hideNameplateHint then return end
  if ns.getCVar(H.CVAR) == H.CVAR_OFF then
    ns.showHintPopup()
  end
end
