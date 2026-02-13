CrittersBoard = CrittersBoard or {}
local CB = CrittersBoard

CB.UI = CB.UI or {}
local UI = CB.UI

UI.lines = UI.lines or {}
UI.lineButtons = UI.lineButtons or {}

-- Design-Konstanten aus v0.4.3.1
local MIN_W, MIN_H = 50, 50
local MAX_W, MAX_H = 700, 1200
local LINE_H = 16

-- =========================================================
-- TOOLTIP ENGINE (v0.5 Logik)
-- =========================================================
function UI:ShowTooltip(tooltip, rec)
  if not rec then return end
  tooltip:ClearLines()
  
  -- Zaubername live über ID auflösen (Spielsprache)
  local sName = "???"
  if rec.spellId then
    local infoName = GetSpellInfo(rec.spellId)
    if infoName then sName = infoName else sName = "ID: "..rec.spellId end
  end

  -- 1. Zaubername
  tooltip:AddDoubleLine(CB.L["TOOLTIP_SPELL"] or "Zauber:", "|cffffffff" .. sName .. "|r")
  
  -- 2. Spieler & Klasse
  local r, g, b = CB:GetClassColorFromClassFile(rec.classFile)
  tooltip:AddDoubleLine("Spieler:", CB:ColorText(rec.player or "???", r, g, b))

  -- 3. NEU: Ziel (Target)
  -- Wir prüfen ob destName vorhanden ist, sonst "Unbekannt"
  local targetName = rec.destName or "Unbekannt"
  tooltip:AddDoubleLine("Ziel:", "|cffffffff" .. targetName .. "|r")
  
  -- 4. Betrag
  local color = rec.isCrit and "|cffff3333" or "|cffffffff"
  tooltip:AddDoubleLine("Betrag:", color .. (rec.amount or 0) .. (rec.isCrit and " (Kritisch!)" or "") .. "|r")

  -- Standort-Info (v0.5)
  if rec.mapID and rec.mapID ~= 0 then
    local mapInfo = C_Map.GetMapInfo(rec.mapID)
    local mapName = mapInfo and mapInfo.name or "Unbekannt"
    local coords = ""
    if rec.coordX and rec.coordY and (rec.coordX ~= 0 or rec.coordY ~= 0) then
        coords = string.format(" (%.1f, %.1f)", rec.coordX, rec.coordY)
    end
    tooltip:AddDoubleLine("Ort:", "|cff00ffff" .. mapName .. coords .. "|r")
  end

  -- Zeitstempel
  if rec.ts then
    tooltip:AddDoubleLine("Datum:", "|cff888888" .. date("%d.%m.%Y %H:%M", rec.ts) .. "|r")
  end

  tooltip:Show()
end

-- =========================================================
-- HAUPTFENSTER (v0.4.3.1 Design)
-- =========================================================
function UI:CreateMain()
  if UI.frame then return end

  local f = CreateFrame("Frame", "CrittersBoardFrame", UIParent, "BasicFrameTemplate")
  UI.frame = f
  local pos = (CB.DB and CB.DB.ui) and CB.DB.ui.pos or nil
  
  if pos then
    f:ClearAllPoints()
    f:SetPoint(pos.point or "CENTER", UIParent, pos.relativePoint or "CENTER", pos.x or 0, pos.y or 0)
    f:SetSize(pos.w or 300, pos.h or 400)
  else
    -- Standardwerte falls DB frisch gelöscht wurde
    f:SetSize(300, 400)
    f:SetPoint("CENTER")
  end
  f:SetMovable(true)
  f:SetResizable(true)
  f:SetClampedToScreen(true)
  f:EnableMouse(true)
  
  -- Fix für Resize-API (v0.5 Kompatibilität)
  if f.SetResizeBounds then
    f:SetResizeBounds(MIN_W, MIN_H, MAX_W, MAX_H)
  else
    f:SetMinResize(MIN_W, MIN_H)
    f:SetMaxResize(MAX_W, MAX_H)
  end

  -- Header / Drag
  local header = CreateFrame("Frame", nil, f)
  header:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
  header:SetPoint("TOPRIGHT", f, "TOPRIGHT", -25, 0) -- Platz für Gear Button
  header:SetHeight(25)
  header:EnableMouse(true)
  header:RegisterForDrag("LeftButton")
  header:SetScript("OnDragStart", function() if not CB.DB.ui.locked then f:StartMoving() end end)
  header:SetScript("OnDragStop", function()
    f:StopMovingOrSizing()
    local point, _, relPoint, x, y = f:GetPoint()
    CB.DB.ui.pos = CB.DB.ui.pos or {}
    CB.DB.ui.pos.point = point
    CB.DB.ui.pos.relativePoint = relPoint
    CB.DB.ui.pos.x = x
    CB.DB.ui.pos.y = y
  end)
  
  -- Titel v0.4.3.1 (Zentriert)
  UI.titleText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  UI.titleText:SetPoint("TOP", 0, -6)
  UI.titleText:SetText(CB.L["ADDON_NAME"] or "CrittersBoard")

  -- Gear Button
  local gear = CreateFrame("Button", nil, f)
  gear:SetSize(14, 14)
  gear:SetPoint("TOPRIGHT", f, "TOPRIGHT", -28, -4)
  gear:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
  gear:SetFrameLevel(f:GetFrameLevel() + 10)
  gear:EnableMouse(true)
  gear:RegisterForClicks("LeftButtonUp")
  gear:SetScript("OnClick", function()
    if UI.ToggleSettings then UI:ToggleSettings() end
  end)
  UI.gearBtn = gear

  -- ScrollFrame
  local sf = CreateFrame("ScrollFrame", "CrittersBoardScrollFrame", f, "UIPanelScrollFrameTemplate")
  sf:SetPoint("TOPLEFT", 10, -30)
  sf:SetPoint("BOTTOMRIGHT", -30, 10)
  UI.scrollFrame = sf

  local content = CreateFrame("Frame", nil, sf)
  content:SetSize(260, 1600)
  sf:SetScrollChild(content)

  -- Zeilen-Erstellung (v0.4.3.1 Look & Feel)
  for i = 1, 100 do
    local row = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row:SetPoint("TOPLEFT", 5, -(i-1) * LINE_H - 5)
    row:SetHeight(LINE_H)
    row:SetJustifyH("LEFT")
    UI.lines[i] = row

    local btn = CreateFrame("Button", nil, content)
    btn:SetSize(300, LINE_H)
    btn:SetPoint("TOPLEFT", row)
    btn:SetScript("OnEnter", function(self)
      if self.rec then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        UI:ShowTooltip(GameTooltip, self.rec)
      end
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    UI.lineButtons[i] = btn
  end

  -- Resize Grip
  local rb = CreateFrame("Button", nil, f)
    rb:SetSize(16, 16)
    rb:SetPoint("BOTTOMRIGHT", -2, 2)
    rb:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    rb:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
  
    rb:SetScript("OnMouseDown", function() 
      if not CB.DB.ui.locked then f:StartSizing() end 
    end)

    rb:SetScript("OnMouseUp", function() 
      f:StopMovingOrSizing()
      -- NEU: Breite und Höhe in die Datenbank schreiben
      CB.DB.ui.pos = CB.DB.ui.pos or {}
      CB.DB.ui.pos.w = f:GetWidth()
      CB.DB.ui.pos.h = f:GetHeight()
    end)

  f:SetScript("OnSizeChanged", function() 
    content:SetWidth(f:GetWidth() - 40)
  end)

  -- =========================================================
  -- FIX: Skalierung sofort beim Erstellen anwenden
  -- =========================================================
  if CB.DB and CB.DB.ui and CB.DB.ui.scale then
    f:SetScale(CB.DB.ui.scale)
  end

end

-- =========================================================
-- REFRESH LOGIK (v0.5 Funktionalität)
-- =========================================================
function UI:Refresh()
  if not CB.DB or not UI.frame or not UI.frame:IsShown() then return end

  local base = CB.DB.ui.base or "D"
  local limit = CB.DB.ui.limit or 10
  local modeKey = base .. limit -- Nur für die Überschrift aus den Locales
  -- Liste bestimmen
  local tbl = CB.DB.damage
  if base == "H" then tbl = CB.DB.heal
  elseif base == "O" then tbl = CB.DB.overkill
  elseif base == "S" then tbl = CB.DB.spells
  elseif base == "HS" then tbl = CB.DB.healSpells
  end

-- TITEL DYNAMISCH ZUSAMMENBAUEN
  local catName = CB.L["CAT_" .. base] or base
  local topLabel = CB.L["LABEL_TOP"] or "Top"
  UI.titleText:SetText(string.format("%s - %s %d", catName, topLabel, limit))

  -- Zeilen füllen
  for i = 1, 100 do
      local rec = (tbl and tbl.records) and tbl.records[i] or nil
      if rec and i <= limit then
        local r, g, b = CB:GetClassColorFromClassFile(rec.classFile)
        local nameColor = CB:ColorText(rec.player or "???", r, g, b)
      
      -- Formatierung des Wertes
        local valStr = rec.amount or 0
        if rec.isCrit then valStr = "|cffff3333" .. valStr .. "|r" end

      -- Zaubername live über ID abrufen (Spielsprache)
        local sName = "???"
        if rec.spellId then
          local infoName = GetSpellInfo(rec.spellId)
          if infoName then
            sName = infoName
          else
            sName = "ID: " .. rec.spellId
          end
        end

      -- Anzeige: Platz. Name (Zaubername) - Wert
        UI.lines[i]:SetText(string.format("%d. %s (%s) - %s", i, nameColor, sName, valStr))
        UI.lineButtons[i].rec = rec
        UI.lines[i]:Show()
      else
        UI.lines[i]:Hide()
        UI.lineButtons[i].rec = nil
      end
    end
  end

function UI:UpdateLock()
  if not UI.frame then return end
  if CB.DB.ui.locked then
    UI.frame:SetMovable(false)
    UI.frame:SetResizable(false)
  else
    UI.frame:SetMovable(true)
    UI.frame:SetResizable(true)
  end
end