-- Minimap.lua — Minimap-Button: Linksklick ein-/ausblenden, Rechtsklick Menü, Ziehen verschiebt.

local _, ns = ...
local C = ns.Config
local L = ns.L
local MM = C.MINIMAP
local T = C.TEXTURE

function ns.updateMinimap()
  local mm = ns.ui.mm
  if not mm then return end
  if ns.db.minimap then
    local a = math.rad(ns.db.minimapAngle)
    local r = Minimap:GetWidth() / 2 + MM.RADIUS_EXTRA
    mm:ClearAllPoints()
    mm:SetPoint('CENTER', Minimap, 'CENTER', math.cos(a) * r, math.sin(a) * r)
    mm:Show()
  else
    mm:Hide()
  end
end

local function buildMinimapButton()
  local mm = CreateFrame('Button', MM.NAME, Minimap)
  ns.ui.mm = mm
  mm:SetSize(MM.SIZE, MM.SIZE)
  mm:SetFrameStrata('MEDIUM')
  mm:SetFrameLevel(MM.LEVEL)
  mm:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
  mm:RegisterForDrag('LeftButton')
  mm:SetHighlightTexture(T.MINIMAP_HIGHLIGHT)

  local back = mm:CreateTexture(nil, 'BACKGROUND')
  back:SetTexture(T.MINIMAP_BACKGROUND)
  back:SetSize(MM.BG_SIZE, MM.BG_SIZE)
  back:SetPoint('TOPLEFT', MM.BG_X, MM.BG_Y)

  local icon = mm:CreateTexture(nil, 'ARTWORK')
  icon:SetTexture(T.ADDON_ICON)
  icon:SetSize(MM.ICON_SIZE, MM.ICON_SIZE)
  icon:SetPoint('TOPLEFT', MM.ICON_X, MM.ICON_Y)
  icon:SetTexCoord(unpack(MM.ICON_CROP))
  if mm.CreateMaskTexture then
    local mask = mm:CreateMaskTexture()
    mask:SetTexture(T.ROUND_MASK, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
    mask:SetAllPoints(icon)
    icon:AddMaskTexture(mask)
  end

  local ring = mm:CreateTexture(nil, 'OVERLAY')
  ring:SetTexture(T.MINIMAP_BORDER)
  ring:SetSize(MM.RING_SIZE, MM.RING_SIZE)
  ring:SetPoint('TOPLEFT')

  mm:SetScript('OnDragStart', function(self)
    self:SetScript('OnUpdate', function()
      local mx, my = Minimap:GetCenter()
      local cx, cy = GetCursorPosition()
      local s = Minimap:GetEffectiveScale()
      ns.db.minimapAngle = math.deg(math.atan2(cy / s - my, cx / s - mx))
      ns.updateMinimap()
    end)
  end)
  mm:SetScript('OnDragStop', function(self) self:SetScript('OnUpdate', nil) end)
  mm:SetScript('OnClick', function(self, button)
    if button == 'RightButton' then ns.showMenu(self, ns.SETTINGS) else ns.toggleWindow() end
  end)
  mm:SetScript('OnEnter', function(self)
    GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
    GameTooltip:AddLine(L.MM_TITLE)
    GameTooltip:AddLine(L.MM_LEFT, unpack(C.WHITE))
    GameTooltip:AddLine(L.MM_RIGHT, unpack(C.WHITE))
    GameTooltip:AddLine(L.MM_DRAG, unpack(C.WHITE))
    GameTooltip:Show()
  end)
  mm:SetScript('OnLeave', function() GameTooltip:Hide() end)
  ns.updateMinimap()
end

ns.RegisterModule('Minimap', { OnLogin = buildMinimapButton })
