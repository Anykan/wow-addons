CrittersBoard = CrittersBoard or {}
local CB = CrittersBoard

CB.UI = CB.UI or {}
local UI = CB.UI

UI.lines = UI.lines or {}
UI.lineButtons = UI.lineButtons or {}

local MIN_W, MIN_H = 200, 200
local MAX_W, MAX_H = 700, 700

local LINE_H = 14
local LINE_W = 520

local function ClampSize(frame)
  local w = frame:GetWidth()
  local h = frame:GetHeight()

  if w < MIN_W then w = MIN_W end
  if h < MIN_H then h = MIN_H end
  if w > MAX_W then w = MAX_W end
  if h > MAX_H then h = MAX_H end

  frame:SetSize(w, h)
end

local function ModeToText(mode)
  if mode == "D10" then return "Schaden - Top 10" end
  if mode == "D100" then return "Schaden - Top 100" end

  if mode == "H10" then return "Heilung - Top 10" end
  if mode == "H100" then return "Heilung - Top 100" end

  if mode == "O10" then return "Overkill - Top 10" end
  if mode == "O100" then return "Overkill - Top 100" end

  if mode == "S10" then return "Angriffe - Top 10" end
  if mode == "S100" then return "Angriffe - Top 100" end

  if mode == "HS10" then return "Heilungen - Top 10" end
  if mode == "HS100" then return "Heilungen - Top 100" end

  return "Schaden - Top 10"
end

function UI:ApplyScale()
  if not UI.frame then return end
  local s = (CB.DB and CB.DB.ui and CB.DB.ui.scale) or 1.0
  if s < 0.7 then s = 0.7 end
  if s > 1.4 then s = 1.4 end
  UI.frame:SetScale(s)
end

function UI:UpdateLock()
  if not UI.frame then return end
  local locked = CB.DB and CB.DB.ui and CB.DB.ui.locked
  UI.frame:EnableMouse(not locked)
end

local function ShowTooltip(owner, rec, label)
  if not rec then return end

  GameTooltip:SetOwner(owner, "ANCHOR_CURSOR")
  GameTooltip:ClearLines()

  local pr, pg, pb = 1, 1, 1
  if CB.GetClassColorFromClassFile then
    pr, pg, pb = CB.GetClassColorFromClassFile(CB, rec.class)
  end

  GameTooltip:AddLine(rec.player or "Unknown", pr, pg, pb)
  GameTooltip:AddLine(" ")

  GameTooltip:AddDoubleLine("Angriff:", tostring(rec.spell or "-"), 1, 1, 1, 1, 1, 1)

  if rec.weapon and rec.weapon ~= "" then
    GameTooltip:AddDoubleLine("Waffe:", tostring(rec.weapon), 1, 1, 1, 0.9, 0.9, 0.9)
  end

  if rec.target and rec.target ~= "" then
    GameTooltip:AddDoubleLine("Ziel:", tostring(rec.target), 1, 1, 1, 0.9, 0.9, 0.9)
  end

  GameTooltip:AddLine(" ")

  if label == "Heal" then
    GameTooltip:AddDoubleLine("Heal:", tostring(rec.amount or 0), 1, 1, 1, 1, 1, 0)
  elseif label == "Overkill" then
    GameTooltip:AddDoubleLine("Overkill:", tostring(rec.amount or 0), 1, 1, 1, 1, 1, 0)
  else
    GameTooltip:AddDoubleLine("Schaden:", tostring(rec.amount or 0), 1, 1, 1, 1, 1, 0)
  end

  if rec.overkill and tonumber(rec.overkill) and tonumber(rec.overkill) > 0 and label ~= "Overkill" then
    GameTooltip:AddDoubleLine("Overkill:", tostring(rec.overkill), 1, 1, 1, 1, 0.4, 0.4)
  end

  GameTooltip:AddDoubleLine("Crit:", rec.isCrit and "Ja" or "Nein", 1, 1, 1, 0.8, 0.8, 0.8)

  if rec.ts then
    GameTooltip:AddDoubleLine("Datum:", date("%d.%m.%Y %H:%M:%S", rec.ts), 1, 1, 1, 0.8, 0.8, 0.8)
  end

  if rec.region and rec.region ~= "" then
    GameTooltip:AddDoubleLine("Region:", tostring(rec.region), 1, 1, 1, 0.8, 0.8, 0.8)
  end

  GameTooltip:Show()
end

function UI:CreateMain()
  if UI.frame then return end

  local w = (CB.DB and CB.DB.ui and CB.DB.ui.w) or 360
  local h = (CB.DB and CB.DB.ui and CB.DB.ui.h) or 320

  local f = CreateFrame("Frame", "CrittersBoardFrame", UIParent, "BackdropTemplate")
  f:SetSize(w, h)

  local ui = CB.DB and CB.DB.ui
  if ui and ui.point and ui.relPoint and ui.x and ui.y then
    f:SetPoint(ui.point, UIParent, ui.relPoint, ui.x, ui.y)
  else
    f:SetPoint("CENTER")
  end

  f:SetMovable(true)
  f:SetResizable(true)
  f:SetClampedToScreen(true)

  f:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
  })

  f:SetBackdropColor(0, 0, 0, 0.85)

  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function(self)
    if CB.DB and CB.DB.ui and CB.DB.ui.locked then return end
    self:StartMoving()
  end)

  f:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()

    if CB.DB and CB.DB.ui then
      local point, _, relPoint, xOfs, yOfs = self:GetPoint(1)
      CB.DB.ui.point = point
      CB.DB.ui.relPoint = relPoint
      CB.DB.ui.x = math.floor((xOfs or 0) + 0.5)
      CB.DB.ui.y = math.floor((yOfs or 0) + 0.5)
    end
  end)

  local gear = CreateFrame("Button", nil, f)
  gear:SetSize(16, 16)
  gear:SetPoint("TOPLEFT", 12, -12)
  gear:SetNormalTexture("Interface/GossipFrame/HealerGossipIcon")
  gear:SetHighlightTexture("Interface/Buttons/ButtonHilight-Square", "ADD")

  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 32, -10)
  title:SetText("CrittersBoard")
--[[
  local modeText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  modeText:SetPoint("TOPLEFT", 12, -34)
  modeText:SetText(ModeToText(CB.DB and CB.DB.ui and CB.DB.ui.mode))
]]
  local btnClose = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  btnClose:SetPoint("TOPRIGHT", 2, 2)

  local scrollFrame = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", 12, -60)
  scrollFrame:SetPoint("BOTTOMRIGHT", -30, 12)

  local content = CreateFrame("Frame", nil, scrollFrame)
  content:SetSize(LINE_W, 1)
  scrollFrame:SetScrollChild(content)

  for i = 1, 100 do
    local yOff = -((i - 1) * LINE_H)

    local btn = CreateFrame("Button", nil, content)
    btn:SetSize(LINE_W, LINE_H)
    btn:SetPoint("TOPLEFT", 0, yOff)
    btn:EnableMouse(true)
    btn:SetFrameLevel(f:GetFrameLevel() + 10)

    btn:SetScript("OnEnter", function(self)
      if not self.rec then return end
      ShowTooltip(self, self.rec, self.label)
    end)

    btn:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)

    local line = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    line:SetPoint("TOPLEFT", 0, yOff)

    UI.lines[i] = line
    UI.lineButtons[i] = btn
  end

  content:SetHeight(100 * LINE_H)

  local resizer = CreateFrame("Frame", nil, f)
  resizer:SetSize(16, 16)
  resizer:SetPoint("BOTTOMRIGHT", -4, 4)
  resizer:EnableMouse(true)

  local tex = resizer:CreateTexture(nil, "OVERLAY")
  tex:SetAllPoints()
  tex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")

  resizer:SetScript("OnMouseDown", function()
    if CB.DB and CB.DB.ui and CB.DB.ui.locked then return end
    f:StartSizing("BOTTOMRIGHT")
  end)

  resizer:SetScript("OnMouseUp", function()
    f:StopMovingOrSizing()
    ClampSize(f)

    if CB.DB and CB.DB.ui then
      CB.DB.ui.w = math.floor(f:GetWidth() + 0.5)
      CB.DB.ui.h = math.floor(f:GetHeight() + 0.5)
    end
  end)

  f:SetScript("OnSizeChanged", function(self)
    ClampSize(self)
  end)

  UI.frame = f
  UI.modeText = modeText
  UI.gearBtn = gear

  ClampSize(f)
  UI:ApplyScale()
  UI:UpdateLock()

  f:Hide()
end

function UI:Refresh()
  if not CB.DB or not CB.DB.ui then return end

  -- wenn UI noch nicht gebaut ist: einfach raus
  if not UI.frame then return end

  -- Überschrift immer updaten
  if UI.modeText then
    UI.modeText:SetText(ModeToText(CB.DB.ui.mode))
  end

  local tbl, label = CB:GetCurrentTable()
  local n = CB:GetCurrentTopN()

  if not tbl or not tbl.records then return end

  for i = 1, 100 do
    local rec = tbl.records[i]

    if i <= n and rec then
      local pr, pg, pb = 1, 1, 1
      if CB.GetClassColorFromClassFile then
        pr, pg, pb = CB.GetClassColorFromClassFile(CB, rec.class)
      end

      local playerName = rec.player or "Unknown"
      local playerColored = playerName
      if CB.ColorText then
        playerColored = CB.ColorText(CB, playerName, pr, pg, pb)
      end

      local numberText = tostring(rec.amount or 0)
      if label == "Heal" then
        if CB.ColorNumberHeal then
          numberText = CB.ColorNumberHeal(CB, rec.amount or 0, rec.isCrit)
        end
      else
        if CB.ColorNumberDamage then
          numberText = CB.ColorNumberDamage(CB, rec.amount or 0, rec.isCrit)
        end
      end

      UI.lines[i]:SetText(string.format("#%d  %s - %s - %s", i, playerColored, rec.spell or "Unknown", numberText))
      UI.lines[i]:Show()

      UI.lineButtons[i].rec = rec
      UI.lineButtons[i].label = label
      UI.lineButtons[i]:Show()

    elseif i <= n then
      UI.lines[i]:SetText(string.format("#%d  -", i))
      UI.lines[i]:Show()

      UI.lineButtons[i].rec = nil
      UI.lineButtons[i].label = label
      UI.lineButtons[i]:Hide()
    else
      UI.lines[i]:Hide()
      UI.lineButtons[i].rec = nil
      UI.lineButtons[i].label = label
      UI.lineButtons[i]:Hide()
    end
  end
end

function UI:ToggleMain()
  if not CB.DB then
    if CB.Print then CB:Print("DB nicht bereit") end
    return
  end

  -- Fenster notfalls erzeugen
  if not UI.frame then
    if UI.CreateMain then
      UI:CreateMain()
    end
  end

  if not UI.frame then
    if CB.Print then CB:Print("UI nicht bereit") end
    return
  end

  if UI.frame:IsShown() then
    UI.frame:Hide()
    CB.DB.ui.isOpen = false
  else
    UI.frame:Show()
    UI:Refresh()
    CB.DB.ui.isOpen = true
  end
end

UI.ToggleMainUI = UI.ToggleMain
UI.Toggle = UI.ToggleMain
