--[[
  Settings.lua — das Einstellungsfenster (Anforderung F) und die Seite unter
  Optionen → AddOns.

  Das Fenster baut sich automatisch aus Config.OPTIONS auf. Eine neue Option ist
  also nur eine neue Zeile dort (plus Texte in Locales.lua). Jede Änderung wirkt
  sofort, wie früher im Dropdown-Menü.
]]

local _, ns = ...
local C = ns.Config
local L = ns.L
local S = C.SETTINGS
local D = C.DIALOG
local T = C.TEXTURE
local W = C.WINDOW

local win
local updaters = {}     -- pro Option eine Funktion, die die Anzeige an den aktuellen Wert anpasst
local updating = false  -- verhindert, dass das Anpassen der Anzeige selbst als Änderung zählt

-- Werte lesen/schreiben: gespeicherte Einstellung (key) oder Laufzeit-Zustand (state)
local function getValue(opt)
  if opt.state then return ns.state[opt.state] end
  return ns.db[opt.key]
end

local function setValue(opt, v)
  if opt.state then ns.state[opt.state] = v else ns.db[opt.key] = v end
end

-- Nach jeder Änderung: alles neu anwenden (wie früher im Menü)
local function afterChange(opt, v)
  ns.dbg('SETTING', 'Einstellung ' .. tostring(opt.key or opt.state or opt.action) .. ' = ' .. tostring(v))
  -- Testzeilen sollen auch sichtbar sein, wenn das Fenster ausgeblendet war (wie früher)
  if opt.state == 'testMode' then ns.db.shown = true end
  ns.applyLook()
  ns.updateMinimap()
  ns.refresh()
  ns.notifyModules('OnSettingChanged', opt.key or opt.state)
end

local function showTip(owner, opt)
  if not opt.tip then return end
  ns.showTooltip(owner, L[opt.label], L[opt.tip])
end

local function hideTip() GameTooltip:Hide() end

-- Zeilen-Bausteine (jeder gibt die neue Y-Position zurück) ---------------------------------

local function buildSection(parent, opt, y)
  y = y - S.SECTION_GAP
  local fs = parent:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
  fs:SetPoint('TOPLEFT', D.PADDING, y)
  fs:SetText(L[opt.label])
  fs:SetTextColor(unpack(C.TITLE_COLOR))
  local line = parent:CreateTexture(nil, 'ARTWORK')
  line:SetTexture(T.FLAT)
  line:SetVertexColor(1, 1, 1, S.LINE_ALPHA)
  line:SetHeight(1)
  line:SetPoint('TOPLEFT', fs, 'BOTTOMLEFT', 0, -1)
  line:SetPoint('RIGHT', parent, 'RIGHT', -D.PADDING, 0)
  return y - S.SECTION_H
end

local function newRow(parent, y, height)
  local row = CreateFrame('Button', nil, parent)
  row:SetPoint('TOPLEFT', D.PADDING, y)
  row:SetPoint('RIGHT', parent, 'RIGHT', -D.PADDING, 0)
  row:SetHeight(height)
  return row
end

local function buildCheck(parent, opt, y)
  local row = newRow(parent, y, S.ROW_H)
  local hl = row:CreateTexture(nil, 'HIGHLIGHT')
  hl:SetAllPoints()
  hl:SetTexture(T.FLAT)
  hl:SetVertexColor(1, 1, 1, D.ROW_HIGHLIGHT_ALPHA)

  -- Kästchen: heller Rahmen, dunkle Innenfläche, Haken darüber
  local border = row:CreateTexture(nil, 'ARTWORK', nil, 1)
  border:SetSize(S.CHECK_SIZE, S.CHECK_SIZE)
  border:SetPoint('LEFT')
  border:SetTexture(T.FLAT)
  border:SetVertexColor(unpack(C.BACKDROP.BORDER_COLOR))
  local inner = row:CreateTexture(nil, 'ARTWORK', nil, 2)
  inner:SetPoint('TOPLEFT', border, 'TOPLEFT', S.CHECK_BORDER, -S.CHECK_BORDER)
  inner:SetPoint('BOTTOMRIGHT', border, 'BOTTOMRIGHT', -S.CHECK_BORDER, S.CHECK_BORDER)
  inner:SetTexture(T.FLAT)
  inner:SetVertexColor(unpack(S.CHECK_BG))
  local check = row:CreateTexture(nil, 'OVERLAY')
  check:SetSize(S.CHECK_SIZE, S.CHECK_SIZE)
  check:SetPoint('CENTER', border, 'CENTER')
  check:SetTexture(T.CHECK)

  local label = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  label:SetPoint('LEFT', border, 'RIGHT', S.TEXT_GAP, 0)
  label:SetText(L[opt.label])

  local function update() check:SetShown(getValue(opt) and true or false) end
  row:SetScript('OnClick', function()
    local v = not getValue(opt)
    setValue(opt, v)
    update()
    afterChange(opt, v)
  end)
  row:SetScript('OnEnter', function(self) showTip(self, opt) end)
  row:SetScript('OnLeave', hideTip)
  updaters[#updaters + 1] = update
  return y - S.ROW_H
end

local function buildRole(parent, opt, y)
  local row = newRow(parent, y, S.ROW_H)
  local label = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  label:SetPoint('LEFT')
  label:SetText(L[opt.label])

  local dps = ns.makeFlatButton(row, L.ROLE_DPS, S.ROLE_BUTTON_W)
  dps:SetPoint('RIGHT')
  local tank = ns.makeFlatButton(row, L.ROLE_TANK, S.ROLE_BUTTON_W)
  tank:SetPoint('RIGHT', dps, 'LEFT', -D.BUTTON_GAP, 0)

  local function update()
    local isTank = ns.db.role == 'tank'
    tank.bg:SetVertexColor(unpack(isTank and D.BUTTON_BG_ACTIVE or D.BUTTON_BG))
    dps.bg:SetVertexColor(unpack(isTank and D.BUTTON_BG or D.BUTTON_BG_ACTIVE))
  end
  local function pick(role)
    if ns.db.role ~= role then
      ns.toggleRole()
      ns.dbg('SETTING', 'Einstellung role = ' .. role)
    end
    update()
  end
  tank:SetScript('OnClick', function() pick('tank') end)
  dps:SetScript('OnClick', function() pick('dps') end)
  for _, f in ipairs({ row, tank, dps }) do
    f:SetScript('OnEnter', function(self) showTip(self, opt) end)
    f:SetScript('OnLeave', hideTip)
  end
  updaters[#updaters + 1] = update
  return y - S.ROW_H
end

local function buildSlider(parent, opt, y)
  local row = newRow(parent, y, S.SLIDER_ROW_H)
  local label = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  label:SetPoint('TOPLEFT')
  label:SetText(L[opt.label])
  local value = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  value:SetPoint('TOPRIGHT')
  value:SetWidth(S.VALUE_W)
  value:SetJustifyH('RIGHT')

  local slider = CreateFrame('Slider', nil, row)
  slider:SetOrientation('HORIZONTAL')
  slider:SetHeight(S.THUMB_H)
  slider:SetPoint('BOTTOMLEFT')
  slider:SetPoint('BOTTOMRIGHT')
  slider:EnableMouse(true)
  local track = slider:CreateTexture(nil, 'BACKGROUND')
  track:SetTexture(T.FLAT)
  track:SetVertexColor(unpack(S.TRACK_COLOR))
  track:SetHeight(S.SLIDER_H)
  track:SetPoint('LEFT')
  track:SetPoint('RIGHT')
  slider:SetThumbTexture(T.FLAT)
  local thumb = slider:GetThumbTexture()
  thumb:SetSize(S.THUMB_W, S.THUMB_H)
  thumb:SetVertexColor(unpack(C.TITLE_COLOR))
  slider:SetMinMaxValues(opt.min, opt.max)
  slider:SetValueStep(opt.step)
  if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end

  local function showValue(v)
    value:SetText(math.floor(v * S.PERCENT + 0.5) .. '%')
  end
  local function update()
    local v = getValue(opt)
    updating = true
    slider:SetValue(v)
    updating = false
    showValue(v)
  end
  slider:SetScript('OnValueChanged', function(_, v)
    if updating then return end
    -- auf ganze Prozent runden (vermeidet 0.30000000004 usw.)
    v = math.floor(v * S.PERCENT + 0.5) / S.PERCENT
    if v == getValue(opt) then return end
    setValue(opt, v)
    showValue(v)
    afterChange(opt, v)
  end)
  for _, f in ipairs({ row, slider }) do
    f:SetScript('OnEnter', function(self) showTip(self, opt) end)
    f:SetScript('OnLeave', hideTip)
  end
  updaters[#updaters + 1] = update
  return y - S.SLIDER_ROW_H
end

local function buildButton(parent, opt, y)
  local btn = ns.makeFlatButton(parent, L[opt.label])
  btn:SetPoint('TOPLEFT', D.PADDING, y)
  btn:SetScript('OnClick', function()
    ns.dbg('SETTING', 'Knopf ' .. opt.action)
    ns[opt.action]()
  end)
  btn:SetScript('OnEnter', function(self) showTip(self, opt) end)
  btn:SetScript('OnLeave', hideTip)
  return y - S.ROW_H
end

local BUILDERS = {
  section = buildSection,
  check = buildCheck,
  role = buildRole,
  slider = buildSlider,
  button = buildButton,
}

-- Fenster ----------------------------------------------------------------------------------

local function updateAll()
  for _, fn in ipairs(updaters) do fn() end
end

local function build()
  win = ns.makeDialog(S.NAME, S.WIDTH, L.SETTINGS_TITLE)
  win:SetPoint('CENTER')

  local y = -(W.HEADER_H + S.TOP_GAP)
  for _, opt in ipairs(C.OPTIONS) do
    local builder = BUILDERS[opt.type]
    if builder then
      y = builder(win, opt, y)
    else
      ns.dbg('SETTING', 'Unbekannter Optionstyp in Config.OPTIONS: ' .. tostring(opt.type))
    end
  end
  win:SetHeight(-y + D.PADDING)
  win:SetScript('OnShow', updateAll)
  -- Nach dem Schließen prüfen, ob eingeschaltete Funktionen weitere Spiel-Optionen brauchen (M)
  win:SetScript('OnHide', function() ns.checkGameOptions(false) end)
  ns.dbg('SETTING', 'Einstellungsfenster aufgebaut (' .. #C.OPTIONS .. ' Einträge)')
end

-- Anzeige an aktuelle Werte anpassen, falls sich etwas außerhalb des Fensters ändert
-- (z. B. /twf lock, Minimap-Menü, Rollen-Button im Fensterkopf). Wird von applyLook aufgerufen.
function ns.updateSettingsWindow()
  if win and win:IsShown() then updateAll() end
end

-- Zahnrad: Fenster öffnen/schließen
function ns.toggleSettings()
  if not win then build() end
  if win:IsShown() then win:Hide() else win:Show() end
end

-- Seite unter Optionen → AddOns ------------------------------------------------------------

local function registerOptionsPanel()
  if not (Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then
    ns.dbg('OPTIONS_PANEL', 'Optionen-API fehlt, keine Seite unter Optionen → AddOns angelegt')
    return
  end
  local P = C.OPTIONS_PANEL
  local panel = CreateFrame('Frame')

  local title = panel:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')
  title:SetPoint('TOPLEFT', P.TITLE_X, P.TITLE_Y)
  title:SetText(L.MENU_TITLE)

  local text = panel:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
  text:SetPoint('TOPLEFT', title, 'BOTTOMLEFT', 0, P.TEXT_Y)
  text:SetText(L.PANEL_TEXT)

  local btn = CreateFrame('Button', nil, panel, 'UIPanelButtonTemplate')
  btn:SetSize(P.BUTTON_W, P.BUTTON_H)
  btn:SetPoint('TOPLEFT', text, 'BOTTOMLEFT', 0, P.BUTTON_Y)
  btn:SetText(L.PANEL_BUTTON)
  btn:SetScript('OnClick', function()
    -- Spiel-Optionen schließen, damit unser Fenster nicht dahinter liegt
    if SettingsPanel and SettingsPanel:IsShown() then pcall(HideUIPanel, SettingsPanel) end
    if not (win and win:IsShown()) then ns.toggleSettings() end
  end)

  local ok, err = pcall(function()
    local category = Settings.RegisterCanvasLayoutCategory(panel, L.MENU_TITLE)
    Settings.RegisterAddOnCategory(category)
  end)
  if ok then
    ns.dbg('OPTIONS_PANEL', 'Seite unter Optionen → AddOns angelegt')
  else
    ns.dbg('OPTIONS_PANEL', 'Seite unter Optionen → AddOns fehlgeschlagen: ' .. tostring(err))
  end
end

ns.RegisterModule('Settings', { OnLogin = registerOptionsPanel })
