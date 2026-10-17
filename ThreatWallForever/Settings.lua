--[[
  Settings.lua — das Einstellungsfenster (Anforderung F) und die Seite unter
  Optionen → AddOns.

  Das Fenster baut sich automatisch aus Config.OPTIONS auf. Eine neue Option ist
  also nur eine neue Zeile dort (plus Texte in Locales.lua). Jede Änderung wirkt
  sofort.
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

-- Nach jeder Änderung: alles neu anwenden
local function afterChange(opt, v)
  ns.dbg('SETTING', 'Einstellung ' .. tostring(opt.key or opt.state or opt.action) .. ' = ' .. tostring(v))
  -- Testzeilen sollen auch sichtbar sein, wenn das Fenster ausgeblendet war
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

-- Reiter "Nameplates": Tabelle der Zustände (0.3, Schritt 1: nur Platzhalter) --------------

local PT = C.PLATE_TABLE

-- Farbfeld mit dünnem Rahmen; color = nil zeigt den Platzhalter für "nichts"
local function swatch(parent, color)
  if not color then
    local fs = parent:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
    fs:SetPoint('CENTER')
    fs:SetText(PT.EMPTY)
    return
  end
  local border = parent:CreateTexture(nil, 'ARTWORK', nil, 1)
  border:SetSize(PT.SWATCH, PT.SWATCH)
  border:SetPoint('CENTER')
  border:SetTexture(T.FLAT)
  border:SetVertexColor(unpack(C.BACKDROP.BORDER_COLOR))
  local fill = parent:CreateTexture(nil, 'ARTWORK', nil, 2)
  fill:SetPoint('TOPLEFT', border, 'TOPLEFT', PT.SWATCH_BORDER, -PT.SWATCH_BORDER)
  fill:SetPoint('BOTTOMRIGHT', border, 'BOTTOMRIGHT', -PT.SWATCH_BORDER, PT.SWATCH_BORDER)
  fill:SetTexture(T.FLAT)
  fill:SetVertexColor(color[1], color[2], color[3])
end

local function cellText(parent, text)
  local fs = parent:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  fs:SetPoint('CENTER')
  fs:SetText(text)
end

-- Inhalt einer Zelle (Zeile rowKey, Zustand st) – zeigt den heutigen festen Wert
local CELLS = {
  ROW_COLOR = function(cell, st) swatch(cell, st.color) end,
  ROW_ALPHA = function(cell) cellText(cell, PT.EMPTY) end,  -- Deckkraft pro Zustand gibt es noch nicht
  ROW_FRAME = function(cell, st) swatch(cell, st.frame) end,
  ROW_BLINK = function(cell, st) cellText(cell, st.blink and L.VALUE_ON or L.VALUE_OFF) end,
}

-- Baut die Tabelle in page; gibt die benötigte Höhe zurück
local function buildPlateTable(page)
  local note = page:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
  note:SetPoint('TOPLEFT', D.PADDING, 0)
  note:SetPoint('RIGHT', page, 'RIGHT', -D.PADDING, 0)
  note:SetJustifyH('LEFT')
  note:SetText(L.PLATE_NOTE)

  local top = -PT.NOTE_H
  local x0 = D.PADDING + PT.LABEL_W
  for i, st in ipairs(C.PLATE_STATES) do
    local head = page:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
    head:SetPoint('TOPLEFT', x0 + (i - 1) * PT.COL_W, top)
    head:SetSize(PT.COL_W, PT.HEAD_H)
    head:SetJustifyH('CENTER')
    head:SetJustifyV('MIDDLE')
    head:SetWordWrap(true)
    head:SetText(L[st.label])
    head:SetTextColor(unpack(C.TITLE_COLOR))
  end

  local y = top - PT.HEAD_H
  for r, rowKey in ipairs(C.PLATE_ROWS) do
    if r % 2 == 1 then
      local stripe = page:CreateTexture(nil, 'BACKGROUND', nil, 1)
      stripe:SetPoint('TOPLEFT', D.PADDING, y)
      stripe:SetPoint('RIGHT', page, 'RIGHT', -D.PADDING, 0)
      stripe:SetHeight(PT.ROW_H)
      stripe:SetTexture(T.FLAT)
      stripe:SetVertexColor(1, 1, 1, PT.STRIPE_ALPHA)
    end
    local label = page:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    label:SetPoint('TOPLEFT', D.PADDING + S.TEXT_GAP, y)
    label:SetHeight(PT.ROW_H)
    label:SetJustifyV('MIDDLE')
    label:SetText(L[rowKey])
    for i, st in ipairs(C.PLATE_STATES) do
      local cell = CreateFrame('Frame', nil, page)
      cell:SetSize(PT.COL_W, PT.ROW_H)
      cell:SetPoint('TOPLEFT', x0 + (i - 1) * PT.COL_W, y)
      CELLS[rowKey](cell, st)
    end
    y = y - PT.ROW_H
  end
  return -y
end

-- Reiter "Allgemein": die Optionen aus Config.OPTIONS, in Spalten nebeneinander
-- ({ type = 'column' } beginnt eine neue). Gibt die Höhe der längsten Spalte zurück.
local function buildGeneral(page)
  local nCols = 1
  for _, opt in ipairs(C.OPTIONS) do
    if opt.type == 'column' then nCols = nCols + 1 end
  end
  local colW = S.WIDTH / nCols
  local col, y, maxH, index = nil, 0, 0, 0
  local function newColumn()
    index = index + 1
    col = CreateFrame('Frame', nil, page)
    col:SetPoint('TOPLEFT', (index - 1) * colW, 0)
    col:SetSize(colW, 1)
    y = 0
  end
  newColumn()
  for _, opt in ipairs(C.OPTIONS) do
    if opt.type == 'column' then
      newColumn()
    else
      local builder = BUILDERS[opt.type]
      if builder then
        y = builder(col, opt, y)
        maxH = math.max(maxH, -y)
      else
        ns.dbg('SETTING', 'Unbekannter Optionstyp in Config.OPTIONS: ' .. tostring(opt.type))
      end
    end
  end
  return maxH
end

local PAGE_BUILDERS = { general = buildGeneral, nameplates = buildPlateTable }

-- Fenster ----------------------------------------------------------------------------------

local function updateAll()
  for _, fn in ipairs(updaters) do fn() end
end

local tabs = {}         -- key -> { button, page }
local currentTab

local function selectTab(key)
  currentTab = key
  for k, t in pairs(tabs) do
    local active = k == key
    t.page:SetShown(active)
    t.button.bg:SetVertexColor(unpack(active and D.BUTTON_BG_ACTIVE or D.BUTTON_BG))
  end
  ns.dbg('SETTING', 'Reiter ' .. key)
end

local function build()
  win = ns.makeDialog(S.NAME, S.WIDTH, L.SETTINGS_TITLE)
  win:SetPoint('CENTER')

  -- Reiterleiste unter der Kopfleiste, darunter je Reiter eine Seite
  local tabY = -(W.HEADER_H + S.TOP_GAP)
  win.pageTop = -tabY + D.BUTTON_H + S.TAB_BOTTOM_GAP
  local maxH = 0
  for i, tab in ipairs(S.TABS) do
    local btn = ns.makeFlatButton(win, L[tab.label], S.TAB_W)
    btn:SetPoint('TOPLEFT', D.PADDING + (i - 1) * (S.TAB_W + S.TAB_GAP), tabY)
    btn:SetScript('OnClick', function() selectTab(tab.key) end)
    local page = CreateFrame('Frame', nil, win)
    page:SetPoint('TOPLEFT', 0, -win.pageTop)
    page:SetPoint('RIGHT', win, 'RIGHT')
    page:SetHeight(1)
    maxH = math.max(maxH, PAGE_BUILDERS[tab.key](page))
    tabs[tab.key] = { button = btn, page = page }
  end
  -- Ein Fenster für alle Reiter: so hoch wie der längste Inhalt
  win:SetHeight(win.pageTop + maxH + D.PADDING)
  selectTab(S.TABS[1].key)
  win:SetScript('OnShow', updateAll)
  -- Nach dem Schließen prüfen, ob eingeschaltete Funktionen weitere Spiel-Optionen brauchen (M)
  win:SetScript('OnHide', function() ns.checkGameOptions(false) end)
  ns.dbg('SETTING', 'Einstellungsfenster aufgebaut (' .. #C.OPTIONS .. ' Einträge, '
    .. #S.TABS .. ' Reiter, ' .. #C.PLATE_STATES .. ' Zustände)')
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
