-- Utils.lua — kleine Hilfsfunktionen, die mehrere Module nutzen.

local _, ns = ...
local C = ns.Config
local L = ns.L

-- Atlas / Rückfall --------------------------------------------------------------------

function ns.hasAtlas(name)
  return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name) ~= nil
end

-- Setzt einen Atlas; fehlt er, wird (falls angegeben) die Rückfall-Textur gesetzt.
function ns.setAtlas(tex, name, fallback, useSize)
  if ns.hasAtlas(name) then
    tex:SetAtlas(name, useSize or false)
    return true
  end
  if fallback then tex:SetTexture(fallback) end
  return false
end

-- Pulsierender Rahmen ---------------------------------------------------------------------

-- Rahmen aus vier flachen Kanten (kein Atlas) in einem Kind-Frame, damit eine Animation
-- alle Kanten gemeinsam pulsieren lässt. G = Config-Tabelle mit COLOR, EDGE, INSET,
-- ALPHA_FROM, ALPHA_TO, DURATION. Genutzt von der Liste (Ziel-Zeile) und den Nameplates.
function ns.createGlow(parent, G)
  local glow = CreateFrame('Frame', nil, parent)
  glow:SetPoint('TOPLEFT', -G.INSET, G.INSET)
  glow:SetPoint('BOTTOMRIGHT', G.INSET, -G.INSET)
  for _, edge in ipairs({
    { 'TOPLEFT', 'TOPRIGHT', nil, G.EDGE },
    { 'BOTTOMLEFT', 'BOTTOMRIGHT', nil, G.EDGE },
    { 'TOPLEFT', 'BOTTOMLEFT', G.EDGE, nil },
    { 'TOPRIGHT', 'BOTTOMRIGHT', G.EDGE, nil },
  }) do
    local line = glow:CreateTexture(nil, 'OVERLAY')
    line:SetTexture(C.TEXTURE.FLAT)
    line:SetVertexColor(G.COLOR[1], G.COLOR[2], G.COLOR[3], 1)
    line:SetPoint(edge[1])
    line:SetPoint(edge[2])
    if edge[3] then line:SetWidth(edge[3]) end
    if edge[4] then line:SetHeight(edge[4]) end
  end
  glow:Hide()
  -- Das Pulsieren ist nur Optik: Weicht die Animations-API dieses Clients ab,
  -- bleibt der Rahmen einfach ruhig stehen, statt einen Fehler zu werfen.
  pcall(function()
    local anim = glow:CreateAnimationGroup()
    local alpha = anim:CreateAnimation('Alpha')
    alpha:SetFromAlpha(G.ALPHA_FROM)
    alpha:SetToAlpha(G.ALPHA_TO)
    alpha:SetDuration(G.DURATION)
    alpha:SetSmoothing('IN_OUT')
    anim:SetLooping('BOUNCE')
    glow.anim = anim
  end)
  return glow
end

-- Rahmen ein- oder ausschalten (startet bzw. stoppt das Pulsieren nur beim Wechsel)
function ns.setGlow(glow, on)
  on = on and true or false
  if on == glow:IsShown() then return end
  if on then
    glow:Show()
    if glow.anim then pcall(glow.anim.Play, glow.anim) end
  else
    if glow.anim then pcall(glow.anim.Stop, glow.anim) end
    glow:Hide()
  end
end

-- Geheime Werte -----------------------------------------------------------------------

function ns.IsSecret(v)
  return issecretvalue ~= nil and issecretvalue(v) or false
end

-- Liefert den Wert nur, wenn er nicht geheim ist, sonst nil.
function ns.plain(v)
  if ns.IsSecret(v) then return nil end
  return v
end

-- Echte, nicht geheime Zahl?
function ns.num(v)
  return type(v) == 'number' and not ns.IsSecret(v)
end

-- Chat und Spiel-Optionen -----------------------------------------------------------------

-- Chat-Zeile mit Addon-Präfix und optionalem Code (siehe Config.CODES)
function ns.say(msg, codeKey)
  local tag = codeKey and ('[' .. C.CODES[codeKey] .. '] ') or ''
  DEFAULT_CHAT_FRAME:AddMessage(C.PREFIX .. tag .. msg)
end

function ns.roleName()
  return ns.db.role == 'tank' and L.ROLE_TANK or L.ROLE_DPS
end

function ns.getCVar(name)
  local ok, v = pcall(function()
    if C_CVar and C_CVar.GetCVar then return C_CVar.GetCVar(name) end
    return GetCVar(name)
  end)
  return ok and v or nil
end

-- Spiel-Option setzen; gibt true zurück, wenn es geklappt hat
function ns.setCVar(name, value)
  local ok = pcall(function()
    if C_CVar and C_CVar.SetCVar then C_CVar.SetCVar(name, value) else SetCVar(name, value) end
  end)
  return ok
end

-- Gemeinsamer Fensterstil (Einstellungsfenster, Hinweis-Popup) -----------------------------

-- Flacher Knopf im TWF-Stil. Ohne Breite richtet er sich nach dem Text.
function ns.makeFlatButton(parent, text, width)
  local D = C.DIALOG
  local btn = CreateFrame('Button', nil, parent)
  btn:SetHeight(D.BUTTON_H)
  btn.bg = btn:CreateTexture(nil, 'BACKGROUND')
  btn.bg:SetAllPoints()
  btn.bg:SetTexture(C.TEXTURE.FLAT)
  btn.bg:SetVertexColor(unpack(D.BUTTON_BG))
  local hl = btn:CreateTexture(nil, 'HIGHLIGHT')
  hl:SetAllPoints()
  hl:SetTexture(C.TEXTURE.FLAT)
  hl:SetVertexColor(1, 1, 1, D.ROW_HIGHLIGHT_ALPHA)
  btn.text = btn:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  btn.text:SetPoint('CENTER')
  btn.text:SetText(text)
  btn:SetWidth(width or (btn.text:GetStringWidth() + 2 * D.PADDING))
  return btn
end

-- Fenster im TWF-Look: Hintergrund und Kopfleiste wie das Hauptfenster, goldener Titel,
-- Schließen-Button, an der Kopfleiste verschiebbar, Esc schließt. Höhe setzt der Aufrufer.
function ns.makeDialog(name, width, titleText)
  local D, W, A, T = C.DIALOG, C.WINDOW, C.ATLAS, C.TEXTURE
  local win = CreateFrame('Frame', name, UIParent)
  win:SetWidth(width)
  win:SetFrameStrata('DIALOG')
  win:SetToplevel(true)
  win:SetClampedToScreen(true)
  win:SetMovable(true)
  win:EnableMouse(true)
  if UISpecialFrames then table.insert(UISpecialFrames, name) end

  local bg = win:CreateTexture(nil, 'BACKGROUND')
  bg:SetAllPoints()
  if not ns.setAtlas(bg, A.WINDOW_BG) then bg:SetColorTexture(unpack(W.BG_FALLBACK)) end
  bg:SetAlpha(D.BG_ALPHA)

  local header = CreateFrame('Frame', nil, win)
  header:SetPoint('TOPLEFT')
  header:SetPoint('TOPRIGHT')
  header:SetHeight(W.HEADER_H)
  header:EnableMouse(true)
  header:SetScript('OnMouseDown', function() win:StartMoving() end)
  header:SetScript('OnMouseUp', function() win:StopMovingOrSizing() end)
  local hbg = header:CreateTexture(nil, 'BACKGROUND', nil, 1)
  hbg:SetAllPoints()
  if not ns.setAtlas(hbg, A.HEADER_BG, T.FLAT) then hbg:SetColorTexture(unpack(W.HEADER_FALLBACK)) end

  local title = header:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
  title:SetPoint('LEFT', W.TITLE_X, 0)
  title:SetText(titleText)
  title:SetTextColor(unpack(C.TITLE_COLOR))

  local okClose, close = pcall(CreateFrame, 'Button', nil, header, 'UIPanelCloseButton')
  if not okClose then
    -- Rückfall, falls es die Vorlage auf diesem Client nicht gibt
    ns.dbg('SETTING', 'Vorlage UIPanelCloseButton fehlt, nutze einfaches X')
    close = ns.makeFlatButton(header, 'X', D.CLOSE_SIZE)
  end
  close:SetSize(D.CLOSE_SIZE, D.CLOSE_SIZE)
  close:SetPoint('RIGHT', header, 'RIGHT', D.CLOSE_X, 0)
  close:SetScript('OnClick', function() win:Hide() end)

  win:Hide()
  return win, header
end

-- Tooltip mit Titel und Erklärtext (umgebrochen)
function ns.showTooltip(owner, titleText, bodyText)
  local D = C.DIALOG
  GameTooltip:SetOwner(owner, 'ANCHOR_RIGHT')
  GameTooltip:AddLine(titleText)
  GameTooltip:AddLine(bodyText, D.TOOLTIP_TEXT[1], D.TOOLTIP_TEXT[2], D.TOOLTIP_TEXT[3], true)
  GameTooltip:Show()
end

-- Rahmen (Backdrop) für das Dropdown-Menü und den Rollen-Button
function ns.backdrop(f, alpha)
  if not f.SetBackdrop then return end
  local B = C.BACKDROP
  f:SetBackdrop({
    bgFile = C.TEXTURE.FLAT, edgeFile = C.TEXTURE.TOOLTIP_BORDER,
    edgeSize = B.EDGE_SIZE, insets = { left = B.INSET, right = B.INSET, top = B.INSET, bottom = B.INSET },
  })
  f:SetBackdropColor(0, 0, 0, alpha)
  f:SetBackdropBorderColor(unpack(B.BORDER_COLOR))
end
