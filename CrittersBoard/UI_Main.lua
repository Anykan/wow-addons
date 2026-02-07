CrittersBoard = CrittersBoard or {}
local CB = CrittersBoard

CB.UI = CB.UI or {}
local UI = CB.UI

UI.lines = UI.lines or {}
UI.lineButtons = UI.lineButtons or {}

local MIN_W, MIN_H = 250, 200
local MAX_W, MAX_H = 700, 800

local LINE_H = 16
local LINE_W = 500

-- Hilfsfunktion: Modus-String in Text umwandeln (für den Header)
local function ModeToText(mode)
  local base = mode:match("^(%a+)")
  local limit = mode:match("(%d+)$") or "10"
  
  local name = "Unbekannt"
  if base == "D" then name = "Schaden"
  elseif base == "H" then name = "Heilung"
  elseif base == "O" then name = "Overkill"
  elseif base == "S" then name = "Angriffe"
  elseif base == "HS" then name = "Heil-Zauber"
  end
  
  return string.format("%s (Top %s)", name, limit)
end

function UI:Refresh()
  if not CB.DB or not UI.frame or not UI.frame:IsShown() then return end

  local mode = CB.DB.ui.mode or "D10"
  local base = mode:match("^(%a+)")
  local limit = tonumber(mode:match("(%d+)$")) or 10

  -- Header Text aktualisieren
  UI.title:SetText("CrittersBoard - " .. ModeToText(mode))

  -- Datenquelle bestimmen
  local data, isHeal, label
  if base == "D" then data = CB.DB.damage; label = "Damage"
  elseif base == "H" then data = CB.DB.heal; isHeal = true; label = "Heal"
  elseif base == "O" then data = CB.DB.overkill; label = "Overkill"
  elseif base == "S" then data = CB.DB.spells; label = "Spells"
  elseif base == "HS" then data = CB.DB.healSpells; isHeal = true; label = "HealSpells"
  end

  if not data or not data.records then return end

  -- Zeilen füllen
  for i = 1, 100 do
    if i <= limit then
      local rec = data.records[i]
      if rec then
        local pCol = CB:ColorText(rec.player or "??", CB:GetClassColorFromClassFile(rec.classFile))
        local val = isHeal and CB:ColorNumberHeal(rec.amount, rec.isCrit) or CB:ColorNumberDamage(rec.amount, rec.isCrit)
        
        UI.lines[i]:SetText(string.format("#%d  %s - %s - %s", i, pCol, rec.spell or "??", val))
        UI.lineButtons[i].rec = rec
        UI.lineButtons[i].label = label
        UI.lineButtons[i]:Show()
      else
        UI.lines[i]:SetText(string.format("#%d  -", i))
        UI.lineButtons[i].rec = nil
        UI.lineButtons[i]:Hide()
      end
      UI.lines[i]:Show()
    else
      -- Zeilen außerhalb des gewählten Limits (z.B. 11-100 bei Top 10) komplett ausblenden
      UI.lines[i]:Hide()
      UI.lineButtons[i]:Hide()
    end
  end

  -- Scroll-Bereich an das Limit anpassen
  UI.scrollContent:SetHeight(limit * LINE_H + 10)
end

function UI:UpdateLock()
  if not UI.frame then return end
  if CB.DB.ui.locked then
    UI.frame:SetMovable(false)
    UI.frame:EnableMouse(not CB.DB.ui.locked) -- Verhindert Drag, lässt aber Scrollen zu wenn nötig
    UI.resizeBtn:Hide()
  else
    UI.frame:SetMovable(true)
    UI.frame:EnableMouse(true)
    UI.resizeBtn:Show()
  end
end

function UI:CreateMain()
  if UI.frame then return end

  local f = CreateFrame("Frame", "CrittersBoardMainFrame", UIParent, "BasicFrameTemplate")
  UI.frame = f
  local savedW = CB.DB.ui.width or 400
  local savedH = CB.DB.ui.height or 300
  f:SetSize(savedW, savedH)
  if CB.DB.ui and CB.DB.ui.xOfs then
    f:SetPoint(CB.DB.ui.point or "CENTER", UIParent, CB.DB.ui.relativePoint or "CENTER", CB.DB.ui.xOfs, CB.DB.ui.yOfs)
  else
    f:SetPoint("CENTER")
  end
  f:SetMovable(true)
  f:SetResizable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetClampedToScreen(true)
  f:SetResizeBounds(MIN_W, MIN_H, MAX_W, MAX_H)

  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    -- Neue Position in der DB speichern
    if CB.DB and CB.DB.ui then
      local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
      CB.DB.ui.point = point
      CB.DB.ui.relativePoint = relativePoint
      CB.DB.ui.xOfs = xOfs
      CB.DB.ui.yOfs = yOfs
    end
  end)
  f:SetScript("OnSizeChanged", function(self, width, height)
    if CB.DB and CB.DB.ui then
      CB.DB.ui.width = width
      CB.DB.ui.height = height
    end
  end)
  
  f:SetScript("OnShow", function() UI:Refresh() end)

  -- Titel
  UI.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  UI.title:SetPoint("TOP", 0, -4)
  UI.title:SetText("CrittersBoard")

  -- Zahnrad Button für Settings
  local gear = CreateFrame("Button", nil, f)
  gear:SetSize(12, 12)
  gear:SetPoint("TOPRIGHT", -30, -6)
  gear:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
  gear:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
  UI.gearBtn = gear

  -- ScrollFrame Setup
  local scrollFrame = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", 10, -30)
  scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

  local content = CreateFrame("Frame", nil, scrollFrame)
  content:SetSize(LINE_W, 100 * LINE_H)
  scrollFrame:SetScrollChild(content)
  UI.scrollContent = content

  -- 100 Zeilen im Voraus erstellen
  for i = 1, 100 do
    local row = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row:SetPoint("TOPLEFT", 5, -(i-1) * LINE_H - 5)
    row:SetHeight(LINE_H)
    row:SetJustifyH("LEFT")
    UI.lines[i] = row

    local btn = CreateFrame("Button", nil, content)
    btn:SetAllPoints(row)
    btn:SetScript("OnEnter", function(self)
      if self.rec then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
 --       CB:ShowTooltip(GameTooltip, self.rec, self.label)
      end
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    UI.lineButtons[i] = btn
  end

  -- Resize Button
  local rb = CreateFrame("Button", nil, f)
  rb:SetSize(16, 16)
  rb:SetPoint("BOTTOMRIGHT", -2, 2)
  rb:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
  rb:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
  rb:SetScript("OnMouseDown", function() f:StartSizing() end)
  rb:SetScript("OnMouseUp", function() f:StopMovingOrSizing() end)
  UI.resizeBtn = rb

  -- Initiale Skalierung
  if CB.DB.ui.scale then f:SetScale(CB.DB.ui.scale) end
  
  UI:UpdateLock()
end

function UI:ToggleMain()
  if not UI.frame then UI:CreateMain() end
  if UI.frame:IsShown() then
    UI.frame:Hide()
    CB.DB.ui.isOpen = false
  else
    UI.frame:Show()
    CB.DB.ui.isOpen = true
    UI:Refresh()
  end
end