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

local function updateAll()
  for _, fn in ipairs(updaters) do fn() end
end

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
  -- Zwei Regler, die zusammengehören (Min./Max. Zeilen): den anderen mitziehen, damit min ≤ max bleibt
  local db = ns.db
  if opt.keepBelow and v > db[opt.keepBelow] then db[opt.keepBelow] = v end
  if opt.keepAbove and v < db[opt.keepAbove] then db[opt.keepAbove] = v end
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

-- Kästchen: heller Rahmen, dunkle Innenfläche, Haken darüber. Nimmt keine Maus an
-- (der Klick gehört der Zeile bzw. Zelle). box.setChecked(v) zeigt/versteckt den Haken.
local function makeCheckBox(parent)
  local box = CreateFrame('Frame', nil, parent)
  box:SetSize(S.CHECK_SIZE, S.CHECK_SIZE)
  local border = box:CreateTexture(nil, 'ARTWORK', nil, 1)
  border:SetAllPoints()
  border:SetTexture(T.FLAT)
  border:SetVertexColor(unpack(C.BACKDROP.BORDER_COLOR))
  local inner = box:CreateTexture(nil, 'ARTWORK', nil, 2)
  inner:SetPoint('TOPLEFT', S.CHECK_BORDER, -S.CHECK_BORDER)
  inner:SetPoint('BOTTOMRIGHT', -S.CHECK_BORDER, S.CHECK_BORDER)
  inner:SetTexture(T.FLAT)
  inner:SetVertexColor(unpack(S.CHECK_BG))
  local check = box:CreateTexture(nil, 'OVERLAY')
  check:SetAllPoints()
  check:SetTexture(T.CHECK)
  function box.setChecked(v) check:SetShown(v and true or false) end
  return box
end

local function percentText(v)
  return math.floor(v * S.PERCENT + 0.5) .. '%'
end

-- Schieberegler im TWF-Look. onChange(v) bekommt den auf ganze Prozent gerundeten Wert;
-- slider.setQuiet(v) stellt den Regler ein, ohne onChange auszulösen.
local function makeSlider(parent, min, max, step, onChange)
  local slider = CreateFrame('Slider', nil, parent)
  slider:SetOrientation('HORIZONTAL')
  slider:SetHeight(S.THUMB_H)
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
  slider:SetMinMaxValues(min, max)
  slider:SetValueStep(step)
  if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end

  local quiet = false
  function slider.setQuiet(v)
    quiet = true
    slider:SetValue(v)
    quiet = false
  end
  slider:SetScript('OnValueChanged', function(_, v)
    if quiet then return end
    -- auf ganze Prozent runden (vermeidet 0.30000000004 usw.)
    onChange(math.floor(v * S.PERCENT + 0.5) / S.PERCENT)
  end)
  return slider
end

local function buildCheck(parent, opt, y)
  local row = newRow(parent, y, S.ROW_H)
  local hl = row:CreateTexture(nil, 'HIGHLIGHT')
  hl:SetAllPoints()
  hl:SetTexture(T.FLAT)
  hl:SetVertexColor(1, 1, 1, D.ROW_HIGHLIGHT_ALPHA)

  local box = makeCheckBox(row)
  box:SetPoint('LEFT')
  local label = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  label:SetPoint('LEFT', box, 'RIGHT', S.TEXT_GAP, 0)
  label:SetText(L[opt.label])

  local function update() box.setChecked(getValue(opt)) end
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

-- Drei Rollen-Knöpfe Tank / DD / Heal (C.ROLES), rechtsbündig
local function buildRole(parent, opt, y)
  local row = newRow(parent, y, S.ROW_H)
  local label = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  label:SetPoint('LEFT')
  label:SetText(L[opt.label])

  local buttons, prev = {}, nil
  for i = #C.ROLES, 1, -1 do
    local role = C.ROLES[i]
    local btn = ns.makeFlatButton(row, ns.roleName(role), S.ROLE_BUTTON_W)
    if prev then btn:SetPoint('RIGHT', prev, 'LEFT', -D.BUTTON_GAP, 0) else btn:SetPoint('RIGHT') end
    prev = btn
    buttons[role] = btn
  end

  local function update()
    for role, btn in pairs(buttons) do
      btn.bg:SetVertexColor(unpack(ns.db.role == role and D.BUTTON_BG_ACTIVE or D.BUTTON_BG))
    end
  end
  for role, btn in pairs(buttons) do
    btn:SetScript('OnClick', function()
      if ns.db.role ~= role then
        ns.setRole(role)
        ns.dbg('SETTING', 'Einstellung role = ' .. role)
      end
      update()
    end)
  end
  row:SetScript('OnEnter', function(self) showTip(self, opt) end)
  row:SetScript('OnLeave', hideTip)
  for _, btn in pairs(buttons) do
    btn:SetScript('OnEnter', function(self) showTip(self, opt) end)
    btn:SetScript('OnLeave', hideTip)
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

  -- Prozent (×100) oder, bei count = true, die Zahl selbst (z. B. Zeilen)
  local function valueText(v) return opt.count and tostring(v) or percentText(v) end
  local slider = makeSlider(row, opt.min, opt.max, opt.step, function(v)
    if v == getValue(opt) then return end
    setValue(opt, v)
    value:SetText(valueText(v))
    afterChange(opt, v)
  end)
  slider:SetPoint('BOTTOMLEFT')
  slider:SetPoint('BOTTOMRIGHT')

  local function update()
    local v = getValue(opt)
    slider.setQuiet(v)
    value:SetText(valueText(v))
  end
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

-- Reiter "Nameplates": Aussehen pro Zustand (Anforderung V) ---------------------------------

local PT = C.PLATE_TABLE
local AP = C.ALPHA_POPUP

-- Nach jeder Änderung in der Tabelle: Nameplates und Liste (Punktfarben) neu zeichnen
local function platesChanged(what)
  ns.dbg('PLATES', what)
  ns.notifyModules('OnSettingChanged', 'plates')
  ns.refresh()
  updateAll()
end

-- Blizzards Farbwähler (Farbkreis). color wird direkt geändert, onChange nach jeder Änderung;
-- "Abbrechen" stellt die alte Farbe wieder her.
local function pickColor(color, onChange)
  local old = { color[1], color[2], color[3] }
  local function apply(r, g, b)
    color[1], color[2], color[3] = r, g, b
    onChange()
  end
  local function fromPicker() apply(ColorPickerFrame:GetColorRGB()) end
  local function cancel() apply(old[1], old[2], old[3]) end
  if ColorPickerFrame.SetupColorPickerAndShow then
    ColorPickerFrame:SetupColorPickerAndShow({
      r = old[1], g = old[2], b = old[3], hasOpacity = false,
      swatchFunc = fromPicker, cancelFunc = cancel,
    })
  else
    -- ältere Fassung des Farbwählers
    ColorPickerFrame.hasOpacity = false
    ColorPickerFrame.func = fromPicker
    ColorPickerFrame.cancelFunc = cancel
    ColorPickerFrame:SetColorRGB(old[1], old[2], old[3])
    ColorPickerFrame:Hide()
    ColorPickerFrame:Show()
  end
  -- über unserem Einstellungsfenster anzeigen
  pcall(ColorPickerFrame.SetFrameStrata, ColorPickerFrame, 'FULLSCREEN_DIALOG')
end

-- Kleines Popup mit Schieberegler 0–100 % für die Deckkraft einer Zelle
local popup
local function openAlphaPopup(anchor, title, getCfg, onChange)
  if not popup then
    popup = CreateFrame('Frame', AP.NAME, UIParent, BackdropTemplateMixin and 'BackdropTemplate' or nil)
    popup:SetSize(AP.WIDTH, AP.HEIGHT)
    popup:SetFrameStrata('FULLSCREEN_DIALOG')
    popup:SetClampedToScreen(true)
    popup:EnableMouse(true)
    ns.backdrop(popup, D.BG_ALPHA)
    if UISpecialFrames then table.insert(UISpecialFrames, AP.NAME) end   -- Esc schließt
    popup.title = popup:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
    popup.title:SetPoint('TOPLEFT', D.PADDING, -D.PADDING)
    popup.value = popup:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    popup.value:SetPoint('TOPRIGHT', -D.PADDING, -D.PADDING)
    popup.slider = makeSlider(popup, AP.MIN, AP.MAX, AP.STEP, function(v) popup.onValue(v) end)
    popup.slider:SetPoint('LEFT', D.PADDING, 0)
    popup.slider:SetPoint('RIGHT', -D.PADDING, 0)
    local ok = ns.makeFlatButton(popup, L.BTN_OK, AP.OK_W)
    ok:SetPoint('BOTTOMRIGHT', -D.PADDING, D.PADDING / 2)
    ok:SetScript('OnClick', function() popup:Hide() end)
  end
  popup.title:SetText(title)
  popup.onValue = function(v)
    getCfg().alpha = v
    popup.value:SetText(percentText(v))
    onChange()
  end
  popup.slider.setQuiet(getCfg().alpha)
  popup.value:SetText(percentText(getCfg().alpha))
  popup:ClearAllPoints()
  popup:SetPoint('TOP', anchor, 'BOTTOM', 0, -2)
  popup:Show()
end

-- Farbfeld mit dünnem Rahmen; gibt eine Funktion zurück, die die Farbe setzt
local function makeSwatch(parent)
  local border = parent:CreateTexture(nil, 'ARTWORK', nil, 1)
  border:SetSize(PT.SWATCH, PT.SWATCH)
  border:SetPoint('CENTER')
  border:SetTexture(T.FLAT)
  border:SetVertexColor(unpack(C.BACKDROP.BORDER_COLOR))
  local fill = parent:CreateTexture(nil, 'ARTWORK', nil, 2)
  fill:SetPoint('TOPLEFT', border, 'TOPLEFT', PT.SWATCH_BORDER, -PT.SWATCH_BORDER)
  fill:SetPoint('BOTTOMRIGHT', border, 'BOTTOMRIGHT', -PT.SWATCH_BORDER, PT.SWATCH_BORDER)
  fill:SetTexture(T.FLAT)
  return function(c) fill:SetVertexColor(c[1], c[2], c[3]) end
end

local function cellButton(parent, x, y)
  local cell = CreateFrame('Button', nil, parent)
  cell:SetSize(PT.COL_W, PT.ROW_H)
  cell:SetPoint('TOPLEFT', x, y)
  local hl = cell:CreateTexture(nil, 'HIGHLIGHT')
  hl:SetAllPoints()
  hl:SetTexture(T.FLAT)
  hl:SetVertexColor(1, 1, 1, D.ROW_HIGHLIGHT_ALPHA)
  return cell
end

-- Zellen-Arten (Zeile kind in C.PLATE_ROWS): (cell, set, st, row, getCfg, changed) richtet die
-- Zelle ein und gibt eine Update-Funktion zurück (Anzeige an den gespeicherten Wert anpassen).
-- row.field = Wert im Zustand; row.needs = Zelle nur sichtbar, wenn dieser Wert an ist.
local function describe(set, st, row) return set .. '/' .. st.key .. ' ' .. row.key end

local CELLS = {
  color = function(cell, set, st, row, getCfg, changed)
    local setSwatch = makeSwatch(cell)
    local content = { cell:GetRegions() }
    local function visible() return not row.needs or getCfg()[row.needs] end
    cell:SetScript('OnClick', function()
      if not visible() then return end
      pickColor(getCfg()[row.field], function() changed(describe(set, st, row)) end)
    end)
    return function()
      local on = visible() and true or false
      setSwatch(getCfg()[row.field])
      for _, region in ipairs(content) do
        if region:GetDrawLayer() ~= 'HIGHLIGHT' then region:SetShown(on) end
      end
      cell:EnableMouse(on)
    end
  end,
  alpha = function(cell, set, st, row, getCfg, changed)
    local fs = cell:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    fs:SetPoint('CENTER')
    cell:SetScript('OnClick', function()
      openAlphaPopup(cell, L[st.label] .. ' – ' .. L[row.label], getCfg,
        function() changed(describe(set, st, row) .. ' ' .. percentText(getCfg().alpha)) end)
    end)
    return function() fs:SetText(percentText(getCfg().alpha)) end
  end,
  check = function(cell, set, st, row, getCfg, changed)
    local box = makeCheckBox(cell)
    box:SetPoint('CENTER')
    cell:SetScript('OnClick', function()
      local cfg = getCfg()
      cfg[row.field] = not cfg[row.field]
      changed(describe(set, st, row) .. ' ' .. tostring(cfg[row.field]))
    end)
    return function() box.setChecked(getCfg()[row.field]) end
  end,
}

local function tableHeight()
  return PT.TITLE_H + PT.HEAD_H + #C.PLATE_ROWS * PT.ROW_H
end

-- Eine Tabelle (Satz 'shared', 'tank', 'dps' oder 'heal') ab Höhe top; gibt ihren Rahmen zurück
local function buildStateTable(page, set, top)
  local tbl = CreateFrame('Frame', nil, page)
  tbl:SetPoint('TOPLEFT', 0, top)
  tbl:SetPoint('RIGHT', page, 'RIGHT')
  tbl:SetHeight(tableHeight())

  local title = tbl:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
  title:SetPoint('TOPLEFT', D.PADDING, 0)
  title:SetTextColor(unpack(C.TITLE_COLOR))
  local ac = PT.ACTIVE_COLOR
  local activeMark = string.format(' |cff%02x%02x%02x%s|r', ac[1] * 255, ac[2] * 255, ac[3] * 255, L.ACTIVE_MARK)
  updaters[#updaters + 1] = function()
    local text = L[C.PLATE_SET_LABEL[set]]
    if set ~= 'shared' and ns.db.role == set then text = text .. activeMark end
    title:SetText(text)
  end

  local x0 = D.PADDING + PT.LABEL_W
  local headY = -PT.TITLE_H
  for i, st in ipairs(C.PLATE_STATES) do
    local head = CreateFrame('Button', nil, tbl)
    head:SetSize(PT.COL_W, PT.HEAD_H)
    head:SetPoint('TOPLEFT', x0 + (i - 1) * PT.COL_W, headY)
    local fs = head:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
    fs:SetAllPoints()
    fs:SetJustifyH('CENTER')
    fs:SetJustifyV('MIDDLE')
    fs:SetWordWrap(true)
    fs:SetText(L[st.label])
    fs:SetTextColor(unpack(C.TITLE_COLOR))
    if not ns.stateUsed(set, st) then head:SetAlpha(PT.DISABLED_ALPHA) end
    head:SetScript('OnEnter', function(self) ns.showTooltip(self, L[st.label], L[st.tip]) end)
    head:SetScript('OnLeave', hideTip)
  end

  local y = headY - PT.HEAD_H
  local function changed(what) platesChanged(what) end
  for r, row in ipairs(C.PLATE_ROWS) do
    if r % 2 == 1 then
      local stripe = tbl:CreateTexture(nil, 'BACKGROUND', nil, 1)
      stripe:SetPoint('TOPLEFT', D.PADDING, y)
      stripe:SetPoint('RIGHT', tbl, 'RIGHT', -D.PADDING, 0)
      stripe:SetHeight(PT.ROW_H)
      stripe:SetTexture(T.FLAT)
      stripe:SetVertexColor(1, 1, 1, PT.STRIPE_ALPHA)
    end
    local labelBtn = CreateFrame('Button', nil, tbl)
    labelBtn:SetSize(PT.LABEL_W, PT.ROW_H)
    labelBtn:SetPoint('TOPLEFT', D.PADDING, y)
    local label = labelBtn:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    label:SetPoint('LEFT', S.TEXT_GAP, 0)
    label:SetText(L[row.label])
    labelBtn:SetScript('OnEnter', function(self) ns.showTooltip(self, L[row.label], L[row.tip]) end)
    labelBtn:SetScript('OnLeave', hideTip)

    for i, st in ipairs(C.PLATE_STATES) do
      local x = x0 + (i - 1) * PT.COL_W
      if ns.cellUsed(set, st, row) then
        local cell = cellButton(tbl, x, y)
        local function getCfg() return ns.db.plates[set][st.key] end
        updaters[#updaters + 1] = CELLS[row.kind](cell, set, st, row, getCfg, changed)
      else
        -- Zustand gibt es in diesem Modus nicht bzw. Zeile passt nicht dazu: ausgegraut, ohne Bedienung
        local fs = tbl:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
        fs:SetPoint('CENTER', tbl, 'TOPLEFT', x + PT.COL_W / 2, y - PT.ROW_H / 2)
        fs:SetText(PT.EMPTY)
      end
    end
    y = y - PT.ROW_H
  end
  return tbl
end

-- Reiter "Nameplates": oben "Farben für alle Modi gleich" + "Farben zurücksetzen", darunter
-- die gemeinsame Tabelle oder die drei Tabellen Tank/DD/Heal. Gibt eine Funktion zurück, die
-- die nötige Höhe liefert (eine bzw. drei Tabellen).
local function buildNameplates(page)
  local topLeft = CreateFrame('Frame', nil, page)
  topLeft:SetPoint('TOPLEFT')
  topLeft:SetSize(S.WIDTH / 2, PT.TOP_H)
  buildCheck(topLeft, { key = 'plateShared', label = 'OPT_PLATE_SHARED', tip = 'TIP_PLATE_SHARED' }, 0)

  local reset = ns.makeFlatButton(page, L.BTN_RESET_COLORS, PT.RESET_W)
  reset:SetPoint('TOPRIGHT', -D.PADDING, 0)
  reset:SetScript('OnClick', function()
    ns.resetPlates()
    platesChanged('Farben zurückgesetzt')
  end)
  reset:SetScript('OnEnter', function(self) ns.showTooltip(self, L.BTN_RESET_COLORS, L.TIP_RESET_COLORS) end)
  reset:SetScript('OnLeave', hideTip)

  local top = -PT.TOP_H
  local step = tableHeight() + PT.TABLE_GAP
  local shared = buildStateTable(page, 'shared', top)
  local perRole = {}
  for i, role in ipairs(C.ROLES) do
    perRole[#perRole + 1] = buildStateTable(page, role, top - (i - 1) * step)
  end
  updaters[#updaters + 1] = function()
    local on = ns.db.plateShared
    shared:SetShown(on)
    for _, tbl in ipairs(perRole) do tbl:SetShown(not on) end
  end
  -- Höhe hängt von "Farben gleich" ab: eine Tabelle oder drei untereinander
  return function()
    if ns.db.plateShared then return PT.TOP_H + tableHeight() end
    return PT.TOP_H + #C.ROLES * step - PT.TABLE_GAP
  end
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

local PAGE_BUILDERS = { general = buildGeneral, nameplates = buildNameplates }

-- Fenster ----------------------------------------------------------------------------------

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
  local heights = {}     -- je Reiter: feste Höhe oder Funktion (Nameplates: eine/drei Tabellen)
  for i, tab in ipairs(S.TABS) do
    local btn = ns.makeFlatButton(win, L[tab.label], S.TAB_W)
    btn:SetPoint('TOPLEFT', D.PADDING + (i - 1) * (S.TAB_W + S.TAB_GAP), tabY)
    btn:SetScript('OnClick', function() selectTab(tab.key) end)
    local page = CreateFrame('Frame', nil, win)
    page:SetPoint('TOPLEFT', 0, -win.pageTop)
    page:SetPoint('RIGHT', win, 'RIGHT')
    page:SetHeight(1)
    heights[#heights + 1] = PAGE_BUILDERS[tab.key](page)
    tabs[tab.key] = { button = btn, page = page }
  end
  -- Ein Fenster für alle Reiter: so hoch wie der längste Inhalt
  -- Alle Reiter gleich groß: so hoch wie der längste Inhalt. Ändert sich nur, wenn
  -- "Farben gleich" umgeschaltet wird (Updater läuft nach jeder Änderung).
  local function fitHeight()
    local maxH = 0
    for _, h in ipairs(heights) do
      maxH = math.max(maxH, type(h) == 'function' and h() or h)
    end
    win:SetHeight(win.pageTop + maxH + D.PADDING)
  end
  updaters[#updaters + 1] = fitHeight
  fitHeight()
  selectTab(S.TABS[1].key)
  win:SetScript('OnShow', updateAll)
  -- Nach dem Schließen prüfen, ob eingeschaltete Funktionen weitere Spiel-Optionen brauchen (M)
  win:SetScript('OnHide', function()
    if popup then popup:Hide() end
    ns.checkGameOptions(false)
  end)
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
