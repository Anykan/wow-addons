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

-- Rahmen (Backdrop) für Menü und Rollen-Button
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
