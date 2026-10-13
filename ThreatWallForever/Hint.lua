--[[
  Hint.lua — Prüfung der Spiel-Optionen, die TWF braucht (Anforderung M).

  Welche Optionen das sind, steht in Config.GAME_OPTIONS. Geprüft wird einmal
  pro Sitzung beim Betreten der Welt und beim Schließen des Einstellungsfensters.
  Fehlt etwas, erscheint ein Popup mit einer Statusliste (✔/✘) und dem Knopf
  "Jetzt einschalten". /twf hint öffnet das Popup immer (zum Testen).

  Ohne Gegner-Nameplates findet TWF einen Gegner nur, solange ihn jemand
  anvisiert (siehe candidateUnits() in Detection.lua).
]]

local _, ns = ...
local C = ns.Config
local L = ns.L
local H = C.HINT
local D = C.DIALOG

local popup, body, applyBtn
local rows = {}
local lastResults = {}

-- Prüfen ------------------------------------------------------------------------------------

-- Ersten vorhandenen CVar-Namen und seinen Wert finden (Namen können sich in der Beta ändern)
local function resolve(opt)
  for _, name in ipairs(opt.names) do
    local v = ns.getCVar(name)
    if v ~= nil then return name, v end
  end
  return nil, nil
end

local function isNeeded(opt)
  return not opt.neededBy or (ns.db[opt.neededBy] and true or false)
end

-- Liefert pro nötiger Option { opt, name, value, ok } und ob etwas fehlt
local function evaluate()
  local results, missing = {}, false
  for _, opt in ipairs(C.GAME_OPTIONS) do
    if isNeeded(opt) then
      local name, value = resolve(opt)
      if name then
        local ok = (value == opt.want)
        if not ok then missing = true end
        results[#results + 1] = { opt = opt, name = name, value = value, ok = ok }
        ns.dbg('GAME_OPTIONS', 'Option ' .. name .. ' = ' .. tostring(value) .. (ok and ' (ok)' or (' (soll ' .. opt.want .. ')')))
      else
        -- Gibt es keinen der Namen, können wir die Option weder prüfen noch setzen
        ns.dbg('GAME_OPTIONS', 'Keiner der Namen gefunden: ' .. table.concat(opt.names, ', '))
      end
    end
  end
  return results, missing
end

-- Popup -------------------------------------------------------------------------------------

local function openGameOptions()
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

local function getRow(i)
  if rows[i] then return rows[i] end
  local row = CreateFrame('Frame', nil, popup)
  row:SetHeight(H.ROW_H)
  row:EnableMouse(true)
  row.icon = row:CreateTexture(nil, 'ARTWORK')
  row.icon:SetSize(H.ICON_SIZE, H.ICON_SIZE)
  row.icon:SetPoint('LEFT')
  row.text = row:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  row.text:SetPoint('LEFT', row.icon, 'RIGHT', D.BUTTON_GAP, 0)
  row:SetScript('OnEnter', function(self)
    if self.opt then ns.showTooltip(self, L[self.opt.label], L[self.opt.tip]) end
  end)
  row:SetScript('OnLeave', function() GameTooltip:Hide() end)
  rows[i] = row
  return row
end

-- Statusliste neu zeichnen und Fensterhöhe anpassen
local function layout(results)
  local y = -(C.WINDOW.HEADER_H + H.TOP_GAP)
  body:ClearAllPoints()
  body:SetPoint('TOPLEFT', D.PADDING, y)
  body:SetPoint('TOPRIGHT', -D.PADDING, y)
  y = y - body:GetStringHeight() - H.LIST_GAP

  for i, r in ipairs(results) do
    local row = getRow(i)
    row.opt = r.opt
    row:ClearAllPoints()
    row:SetPoint('TOPLEFT', D.PADDING, y)
    row:SetPoint('RIGHT', popup, 'RIGHT', -D.PADDING, 0)
    row.icon:SetTexture(r.ok and H.ICON_OK or H.ICON_BAD)
    row.text:SetText(L[r.opt.label])
    row:Show()
    y = y - H.ROW_H
  end
  for i = #results + 1, #rows do rows[i]:Hide() end
  if #results == 0 then y = y - H.ROW_H end  -- Platz für "alles eingestellt"

  local missing = false
  for _, r in ipairs(results) do if not r.ok then missing = true end end
  applyBtn:SetShown(missing)

  y = y - H.BUTTON_GAP_Y - D.BUTTON_H - D.PADDING
  popup:SetHeight(-y)
end

local function showPopup(results, missing)
  lastResults = results
  body:SetText(missing and L.HINT_BODY or L.HINT_ALL_OK)
  layout(results)
  popup:Show()
end

-- Alle ✘-Optionen auf den Sollwert setzen. Alte Werte von Optionen, die nur eine
-- bestimmte Funktion braucht, werden gemerkt, damit sie beim Abschalten dieser
-- Funktion zurückgestellt werden können (kommt mit der ersten solchen Funktion, L).
local function applyMissing()
  if InCombatLockdown() then
    ns.say(L.HINT_IN_COMBAT)
    ns.dbg('GAME_OPTIONS', 'Einschalten im Kampf verweigert')
    return
  end
  local db = ns.db
  for _, r in ipairs(lastResults) do
    if not r.ok then
      if r.opt.neededBy then
        db.savedCVars = db.savedCVars or {}
        if db.savedCVars[r.name] == nil then db.savedCVars[r.name] = r.value end
      end
      local ok = ns.setCVar(r.name, r.opt.want)
      ns.dbg('GAME_OPTIONS', 'Setze ' .. r.name .. ' = ' .. r.opt.want .. (ok and '' or ' (FEHLGESCHLAGEN)'))
    end
  end
  local results, missing = evaluate()
  if missing then
    showPopup(results, missing)
  else
    popup:Hide()
    ns.say(L.HINT_DONE)
  end
end

local function buildPopup()
  popup = ns.makeDialog(H.NAME, H.WIDTH, L.HINT_TITLE)
  popup:SetPoint('CENTER', UIParent, 'CENTER', 0, H.OFFSET_Y)

  body = popup:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  body:SetWidth(H.WIDTH - 2 * D.PADDING)  -- feste Breite, damit die Texthöhe stimmt
  body:SetJustifyH('LEFT')
  body:SetJustifyV('TOP')
  if body.SetSpacing then body:SetSpacing(H.BODY_SPACING) end

  -- Knöpfe unten rechts: [Jetzt einschalten] [Spiel-Optionen öffnen] [OK]
  local ok = ns.makeFlatButton(popup, L.HINT_OK)
  ok:SetPoint('BOTTOMRIGHT', -D.PADDING, D.PADDING)
  ok:SetScript('OnClick', function() popup:Hide() end)
  local anchor = ok

  if H.SHOW_OPTIONS_BUTTON then
    local optionsBtn = ns.makeFlatButton(popup, L.HINT_OPEN_SETTINGS)
    optionsBtn:SetPoint('RIGHT', anchor, 'LEFT', -D.BUTTON_GAP, 0)
    optionsBtn:SetScript('OnClick', openGameOptions)
    anchor = optionsBtn
  end

  applyBtn = ns.makeFlatButton(popup, L.HINT_APPLY)
  applyBtn.bg:SetVertexColor(unpack(D.BUTTON_BG_ACTIVE))
  applyBtn:SetPoint('RIGHT', anchor, 'LEFT', -D.BUTTON_GAP, 0)
  applyBtn:SetScript('OnClick', applyMissing)
end

-- Aufräumen ---------------------------------------------------------------------------------

-- Spiel-Optionen, die TWF früher für eine Funktion eingeschaltet hat, die es nicht mehr
-- gibt oder die gerade aus ist, auf den gemerkten alten Wert zurückstellen. TWF soll
-- nichts zurücklassen. Im Kampf nicht möglich → beim nächsten Prüfen erneut versuchen.
local function restoreOrphaned()
  local saved = ns.db.savedCVars
  if not saved or InCombatLockdown() then return end
  local stillNeeded = {}
  for _, opt in ipairs(C.GAME_OPTIONS) do
    if isNeeded(opt) then
      for _, name in ipairs(opt.names) do stillNeeded[name] = true end
    end
  end
  for name, old in pairs(saved) do
    if not stillNeeded[name] then
      local ok = ns.setCVar(name, old)
      ns.dbg('GAME_OPTIONS', 'Zurückgestellt: ' .. name .. ' = ' .. tostring(old) .. (ok and '' or ' (FEHLGESCHLAGEN)'))
      saved[name] = nil
    end
  end
end

-- Öffentlich ------------------------------------------------------------------------------

-- Prüfen und bei Bedarf das Popup zeigen. force = true zeigt es immer (/twf hint).
function ns.checkGameOptions(force)
  if not ns.db then return end
  restoreOrphaned()
  local results, missing = evaluate()
  ns.dbg('GAME_OPTIONS', 'Prüfung: ' .. (missing and 'es fehlt etwas' or 'alles ok') .. (force and ' (erzwungen)' or ''))
  if missing or force then
    if not popup then buildPopup() end
    showPopup(results, missing)
  end
end
