--[[
  Window.lua — das TWF-Hauptfenster: Aufbau, Kopfleiste, Verschieben,
  Größe ändern, Position speichern, Aussehen anwenden und Fenster-Aktionen
  (Rolle wechseln, Position zurücksetzen, ein-/ausblenden).
]]

local _, ns = ...
local C = ns.Config
local L = ns.L
local W = C.WINDOW
local A = C.ATLAS
local T = C.TEXTURE

-- Position -----------------------------------------------------------------------------

function ns.placeFrame()
  local db, frame = ns.db, ns.frame
  if not (ns.num(db.left) and ns.num(db.top)) then return false end
  local scale = db.scale or 1
  frame:ClearAllPoints()
  frame:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', db.left / scale, db.top / scale)
  return true
end

function ns.savePlace()
  local db, frame = ns.db, ns.frame
  local left, top, w, h = frame:GetLeft(), frame:GetTop(), frame:GetWidth(), frame:GetHeight()
  if not (ns.num(left) and ns.num(top)) then
    ns.state.placePending = true
    return
  end
  ns.state.placePending = false
  local scale = frame:GetScale()
  if not ns.num(scale) then scale = db.scale or 1 end
  db.left, db.top = left * scale, top * scale
  if ns.num(w) and ns.num(h) then db.width, db.height = w, h end
  ns.placeFrame()
end

-- Verschieben ------------------------------------------------------------------------------

local lockHintAt = 0
local function startMove(_, button)
  if button and button ~= 'LeftButton' then return end
  if ns.db.locked then
    if GetTime() - lockHintAt > C.LOCK_HINT_INTERVAL then
      lockHintAt = GetTime()
      ns.say(L.LOCKED_HINT, 'LOCKED_HINT')
    end
    return
  end
  local frame = ns.frame
  frame.moving = true
  frame:StartMoving()
end

function ns.stopMove()
  local frame = ns.frame
  if not frame.moving then return end
  frame:StopMovingOrSizing()
  if frame.SetUserPlaced then pcall(frame.SetUserPlaced, frame, true) end
  frame.moving = false
  ns.savePlace()
  ns.refresh()
end

-- Aussehen -------------------------------------------------------------------------------

local function updateRoleLook()
  local ui = ns.ui
  if ui.roleBtn.setArt then ui.roleBtn.setArt() end
  if ns.db.role == 'tank' then
    ui.titleText:SetText(L.TITLE_TANK .. ' ' .. ns.VERSION)
  else
    ui.titleText:SetText(L.TITLE_DPS .. ' ' .. ns.VERSION)
  end
end

function ns.applyLook()
  local db, frame, ui = ns.db, ns.frame, ns.ui
  frame:SetScale(db.scale)
  ns.placeFrame()
  frame.bg:SetAlpha(db.alpha)
  frame.body:SetShown(not db.minimized)
  updateRoleLook()
  if db.locked or db.minimized then ui.grip:Hide() else ui.grip:Show() end
  for i, row in ipairs(ns.rows) do ns.layoutRow(row, i) end
end

-- Aktionen (Menü, Befehle, Kopf-Buttons) ---------------------------------------------------

function ns.toggleWindow()
  ns.db.shown = not ns.db.shown
  ns.refresh()
end

function ns.toggleRole()
  ns.db.role = (ns.db.role == 'tank') and 'dps' or 'tank'
  ns.applyLook()
  ns.refresh()
end

function ns.resetPlace()
  local frame = ns.frame
  frame:ClearAllPoints()
  frame:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
  frame:SetSize(C.DEFAULTS.width, C.DEFAULTS.height)
  ns.db.shown = true
  ns.savePlace()
  ns.refresh()
end

-- Aufbau -----------------------------------------------------------------------------------

local function buildFrame()
  local db, ui = ns.db, ns.ui
  local frame = ns.frame or CreateFrame('Frame', W.NAME, UIParent)
  ns.frame = frame
  local restored = frame:GetNumPoints() > 0
  if ns.placeFrame() then
    frame:SetSize(db.width, db.height)
  elseif not restored then
    frame:SetSize(db.width, db.height)
    frame:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
    ns.state.placePending = true
  else
    ns.state.placePending = true
  end
  frame:SetFrameStrata('MEDIUM')
  frame:SetClampedToScreen(true)
  frame:SetMovable(true)
  if frame.SetUserPlaced then pcall(frame.SetUserPlaced, frame, true) end
  frame:SetResizable(true)
  frame:EnableMouse(true)
  if frame.SetResizeBounds then
    frame:SetResizeBounds(W.MIN_W, W.MIN_H, W.MAX_W, W.MAX_H)
  elseif frame.SetMinResize then
    frame:SetMinResize(W.MIN_W, W.MIN_H)
    frame:SetMaxResize(W.MAX_W, W.MAX_H)
  end

  frame:SetScript('OnMouseDown', startMove)
  frame:SetScript('OnMouseUp', ns.stopMove)
  frame:SetScript('OnHide', ns.stopMove)

  frame.body = CreateFrame('Frame', nil, frame)
  frame.body:SetAllPoints()

  frame.bg = frame.body:CreateTexture(nil, 'BACKGROUND')
  frame.bg:SetAllPoints()
  if not ns.setAtlas(frame.bg, A.WINDOW_BG) then
    frame.bg:SetColorTexture(unpack(W.BG_FALLBACK))
  end

  frame.empty = frame.body:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
  frame.empty:SetPoint('TOPLEFT', W.EMPTY_X, -W.HEADER_H - W.EMPTY_Y)
  frame.empty:SetPoint('BOTTOMRIGHT', -W.EMPTY_X, W.EMPTY_Y)
  frame.empty:SetJustifyH('CENTER')
  frame.empty:SetJustifyV('TOP')
  frame.empty:SetTextColor(unpack(C.EMPTY_TEXT_COLOR))

  local header = CreateFrame('Frame', nil, frame)
  ui.header = header
  header:SetPoint('TOPLEFT')
  header:SetPoint('TOPRIGHT')
  header:SetHeight(W.HEADER_H)
  header:EnableMouse(true)
  header:SetScript('OnMouseDown', startMove)
  header:SetScript('OnMouseUp', ns.stopMove)
  header.bg = header:CreateTexture(nil, 'BACKGROUND', nil, 1)
  header.bg:SetAllPoints()
  if not ns.setAtlas(header.bg, A.HEADER_BG, T.FLAT) then
    header.bg:SetColorTexture(unpack(W.HEADER_FALLBACK))
  end

  -- Alle drei Kopf-Buttons haben dieselbe Größe und denselben senkrechten
  -- Ankerpunkt (RIGHT, aneinandergekettet), damit sie exakt in einer Linie stehen.
  local btnSize = W.HEADER_BTN_SIZE
  local minimize = CreateFrame('Button', nil, header)
  ui.minimize = minimize
  minimize:SetSize(btnSize, btnSize)
  minimize:SetPoint('RIGHT', header, 'RIGHT', W.HEADER_BTN_RIGHT, 0)
  local function setMinimizeArt()
    local db = ns.db
    local kind = db.minimized and 'expand' or 'collapse'
    local base = A.MINIMIZE_PREFIX .. kind
    if ns.hasAtlas(base .. A.MINIMIZE_SUFFIX) then
      minimize:SetNormalAtlas(base .. A.MINIMIZE_SUFFIX)
      minimize:SetPushedAtlas(base .. A.MINIMIZE_PRESSED_SUFFIX)
      minimize:SetHighlightAtlas(A.MINIMIZE_HIGHLIGHT, 'ADD')
    else
      local art = db.minimized and T.PLUS or T.MINUS
      minimize:SetNormalTexture(art .. '-Up')
      minimize:SetPushedTexture(art .. '-Down')
      minimize:SetHighlightTexture(T.PLUS_HILIGHT, 'ADD')
    end
  end
  minimize:SetScript('OnClick', function()
    ns.db.minimized = not ns.db.minimized
    setMinimizeArt()
    ns.applyLook()
    ns.refresh()
  end)
  setMinimizeArt()

  local gear = CreateFrame('Button', nil, header)
  ui.gear = gear
  -- Dieser Atlas hat mehr Leerraum um das Zahnrad als die Rollen-Icons, deshalb
  -- etwas größer, damit es auf dem Bildschirm gleich groß wirkt.
  gear:SetSize(btnSize + W.GEAR_EXTRA, btnSize + W.GEAR_EXTRA)
  gear:SetPoint('RIGHT', minimize, 'LEFT', W.HEADER_BTN_GAP, 0)
  if ns.hasAtlas(A.GEAR) then
    gear:SetNormalAtlas(A.GEAR)
    gear:SetPushedAtlas(A.GEAR_PRESSED)
    gear:SetHighlightAtlas(A.GEAR_HOVER)
  else
    gear:SetNormalTexture(T.OPTIONS)
    gear:SetHighlightTexture(T.OPTIONS, 'ADD')
  end
  gear:SetScript('OnClick', function(self) ns.showMenu(self, ns.SETTINGS) end)

  -- Rollen-Button: Zahnrad und Minimieren sind fertige Grafiken mit Rahmen, die
  -- ein selbstgebauter Rahmen nur annähern kann. Deshalb zuerst die passenden
  -- Blizzard-Rollen-Atlanten (gleiche Familie, Gruppensuche) versuchen; gibt es
  -- sie nicht, Rückfall auf einen Buchstaben mit Rahmen.
  local roleBtn = CreateFrame('Button', nil, header, BackdropTemplateMixin and 'BackdropTemplate' or nil)
  ui.roleBtn = roleBtn
  roleBtn:SetSize(btnSize, btnSize)
  roleBtn:SetPoint('RIGHT', gear, 'LEFT', W.HEADER_BTN_GAP, 0)

  roleBtn.icon = roleBtn:CreateTexture(nil, 'ARTWORK')
  roleBtn.icon:SetAllPoints()

  roleBtn.text = roleBtn:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
  roleBtn.text:SetAllPoints()
  roleBtn.text:SetJustifyH('CENTER')
  roleBtn.text:SetJustifyV('MIDDLE')

  local roleHL = roleBtn:CreateTexture(nil, 'HIGHLIGHT')
  roleHL:SetAllPoints()
  roleHL:SetTexture(T.FLAT)
  roleHL:SetVertexColor(1, 1, 1, W.ROLE_HIGHLIGHT_ALPHA)

  local function setRoleArt()
    local db = ns.db
    local atlas = A.ROLE[db.role]
    if atlas and ns.hasAtlas(atlas) then
      roleBtn.icon:Show()
      roleBtn.icon:SetAtlas(atlas, false)
      roleBtn.text:Hide()
      roleBtn:SetBackdrop(nil)
    else
      roleBtn.icon:Hide()
      roleBtn.text:Show()
      roleBtn.text:SetText(db.role == 'tank' and 'T' or 'D')
      ns.backdrop(roleBtn, W.ROLE_BACKDROP_ALPHA)
    end
  end
  roleBtn.setArt = setRoleArt
  setRoleArt()

  roleBtn:SetScript('OnClick', ns.toggleRole)
  roleBtn:SetScript('OnEnter', function(self)
    GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
    GameTooltip:AddLine(L.TT_ROLE_TITLE)
    GameTooltip:AddLine(L.TT_ROLE_TANK, unpack(C.WHITE))
    GameTooltip:AddLine(L.TT_ROLE_DPS, unpack(C.WHITE))
    GameTooltip:Show()
  end)
  roleBtn:SetScript('OnLeave', function() GameTooltip:Hide() end)

  local subText = header:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  ui.subText = subText
  subText:SetPoint('RIGHT', roleBtn, 'LEFT', W.SUBTEXT_GAP, 0)
  subText:SetTextColor(unpack(C.WHITE))

  local titleText = header:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
  ui.titleText = titleText
  titleText:SetPoint('LEFT', W.TITLE_X, 0)
  titleText:SetPoint('RIGHT', subText, 'LEFT', W.TITLE_GAP, 0)
  titleText:SetJustifyH('LEFT')
  titleText:SetWordWrap(false)
  titleText:SetTextColor(unpack(C.TITLE_COLOR))

  local grip = CreateFrame('Button', nil, frame.body)
  ui.grip = grip
  grip:SetFrameLevel(frame:GetFrameLevel() + W.GRIP_LEVEL)
  if ns.hasAtlas(A.GRIP) then
    grip:SetSize(W.GRIP_SIZE, W.GRIP_SIZE)
    grip:SetPoint('BOTTOMRIGHT', W.GRIP_X, W.GRIP_Y)
    grip:SetNormalAtlas(A.GRIP)
    grip:SetHighlightAtlas(A.GRIP_HOVER)
    grip:SetPushedAtlas(A.GRIP_PRESSED)
    grip:SetHitRectInsets(unpack(W.GRIP_HIT))
  else
    grip:SetSize(W.GRIP_FALLBACK_SIZE, W.GRIP_FALLBACK_SIZE)
    grip:SetPoint('BOTTOMRIGHT', W.GRIP_FALLBACK_X, W.GRIP_FALLBACK_Y)
    grip:SetNormalTexture(T.SIZE_GRABBER .. '-Up')
    grip:SetHighlightTexture(T.SIZE_GRABBER .. '-Highlight')
    grip:SetPushedTexture(T.SIZE_GRABBER .. '-Down')
  end
  grip:SetAlpha(0)
  grip:SetScript('OnMouseDown', function()
    frame.moving = true
    frame:StartSizing('BOTTOMRIGHT')
  end)
  grip:SetScript('OnMouseUp', ns.stopMove)
  frame:SetScript('OnSizeChanged', function() if frame.moving then ns.refresh() end end)

  -- Griff nur zeigen, solange die Maus über dem Fenster ist (weich ein-/ausblenden)
  local watcher = CreateFrame('Frame', nil, frame)
  watcher:Hide()
  watcher:SetScript('OnUpdate', function(self, elapsed)
    local over = frame:IsMouseOver() or grip:IsMouseOver() or frame.moving
    local alpha = grip:GetAlpha() + (over and elapsed or -elapsed) * W.GRIP_FADE_SPEED
    if alpha >= 1 then alpha = 1 elseif alpha <= 0 then alpha = 0 end
    grip:SetAlpha(alpha)
    if not over and alpha == 0 then self:Hide() end
  end)
  local function hover() watcher:Show() end
  frame:SetScript('OnEnter', hover)
  grip:SetScript('OnEnter', hover)
  header:SetScript('OnEnter', hover)

  ns.applyLook()
end

ns.RegisterModule('Window', { OnLogin = buildFrame })

-- Das Fenster existiert schon vor dem Login (versteckt), damit das Spiel eine
-- gespeicherte Position daran wiederherstellen kann.
do
  local frame = CreateFrame('Frame', W.NAME, UIParent)
  ns.frame = frame
  frame:SetSize(C.DEFAULTS.width, C.DEFAULTS.height)
  frame:SetMovable(true)
  frame:SetResizable(true)
  if frame.SetUserPlaced then pcall(frame.SetUserPlaced, frame, true) end
  frame:Hide()
end
