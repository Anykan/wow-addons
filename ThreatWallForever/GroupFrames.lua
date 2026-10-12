--[[
  GroupFrames.lua — Symbol-Markierung am Gruppenfenster (Anforderung L).

  Der Aggro-Halter bekommt sein Symbol immer zusätzlich an seinem Gruppenfenster
  (Blizzards kompakte Party-/Raidfenster). Grund: In Instanzen sind freundliche
  Nameplates gesperrt, dort geht das Symbol über dem Kopf nicht.

  TWF verändert Blizzards Gruppenfenster nicht: Ein eigener kleiner Frame wird nur
  daran ausgerichtet. Das ist auch im Kampf erlaubt. Welches Fenster zu wem gehört,
  entscheidet die GUID seiner Einheit (nicht geheim bei Mitspielern, T10c).
]]

local _, ns = ...
local C = ns.Config
local Y = C.SYMBOL_LAYOUT

local symbols = {}     -- Gruppenfenster -> unser Symbol-Frame
local lastMissing = '' -- Debug: Halter ohne Gruppenfenster, nur bei Änderung melden

-- Alle möglichen Gruppenfenster (Namen je nach Einstellung und Gruppengröße)
local function groupFrames()
  local list = {}
  local function add(f) if f then list[#list + 1] = f end end
  for i = 1, Y.PARTY_FRAMES do add(_G['CompactPartyFrameMember' .. i]) end
  for i = 1, Y.RAID_FRAMES do add(_G['CompactRaidFrame' .. i]) end
  for g = 1, Y.RAID_GROUPS do
    for m = 1, Y.RAID_GROUP_SIZE do add(_G['CompactRaidGroup' .. g .. 'Member' .. m]) end
  end
  if PartyFrame then
    for i = 1, Y.PARTY_MEMBERS do add(PartyFrame['MemberFrame' .. i]) end
  end
  return list
end

local function plainGUID(unit)
  local ok, guid = pcall(UnitGUID, unit)
  return ok and ns.plain(guid) or nil
end

local function symbolFor(frame)
  local s = symbols[frame]
  if s then return s end
  s = CreateFrame('Frame', nil, UIParent)
  s:SetSize(Y.GROUP_SIZE, Y.GROUP_SIZE)
  s.tex = s:CreateTexture(nil, 'OVERLAY')
  s.tex:SetAllPoints()
  symbols[frame] = s
  return s
end

-- marks: GUID des Halters -> Symbol-Schlüssel (leer = alle ausblenden)
function ns.updateGroupSymbols(marks)
  local found = {}
  for _, frame in ipairs(groupFrames()) do
    local okV, visible = pcall(frame.IsVisible, frame)
    local unit = frame.unit or frame.displayedUnit
    local guid = okV and visible and unit and plainGUID(unit)
    local key = guid and marks[guid]
    local s = symbols[frame]
    if key then
      found[guid] = true
      s = symbolFor(frame)
      s:SetFrameStrata(frame:GetFrameStrata())
      s:SetFrameLevel(frame:GetFrameLevel() + Y.GROUP_LEVEL)
      s:ClearAllPoints()
      s:SetPoint('RIGHT', frame, 'RIGHT', Y.GROUP_X, 0)
      if ns.setSymbolTexture(s.tex, key) then s:Show() else s:Hide() end
    elseif s then
      s:Hide()
    end
  end

  -- Debug: Halter ohne sichtbares Gruppenfenster (nur bei Änderung)
  local missing = {}
  for guid in pairs(marks) do if not found[guid] then missing[#missing + 1] = guid end end
  table.sort(missing)
  local text = table.concat(missing, ', ')
  if text ~= lastMissing then
    lastMissing = text
    if text ~= '' then ns.dbg('SYMBOLS', 'Kein Gruppenfenster für Halter: ' .. text) end
  end
end
