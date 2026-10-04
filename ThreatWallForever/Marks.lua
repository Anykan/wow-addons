--[[
  Marks.lua — Raid-Symbole in der Liste: DREI austauschbare Varianten.

  Auf diesem Client (WoW Forever, Beta, Stand 2026-09) ist die Symbol-Nummer im
  Kampf "geheim" – genau dann, wenn sie wichtig wäre – und alle drei bekannten
  Wege, daraus eine Grafik zu machen, scheitern, jeder auf andere Art. Keiner
  zeichnet derzeit etwas, aber der Versuch ist sicher (pcall) und kostet nichts.
  Deshalb bleiben alle drei drin, umschaltbar mit /twf mark, für den Fall, dass
  ein Client-Update das ändert (gemeldet: forever-bugs#166). Sobald eine Variante
  im echten Kampf zeichnet: die anderen beiden samt Einträgen in MARK_METHODS /
  MARK_METHOD_NAMES löschen und die funktionierende direkt als setMark nutzen.
]]

local _, ns = ...
local C = ns.Config
local R = C.RAID_ICONS

-- VARIANTE 1 – eigene Koordinatenrechnung auf dem Symbol-Bild. Der übliche Weg
-- der meisten Addons. Status: Fehler, weil die Rechnung (index - 1 usw.) eine
-- normale Zahl braucht, keine geheime.
local function setMark_Manual(tex, index)
  return pcall(function()
    tex:SetTexture(R.SHEET)
    local w, h = 1 / R.COLUMNS, 1 / R.ROWS
    local col = (index - 1) % R.COLUMNS
    local row = math.floor((index - 1) / R.COLUMNS)
    tex:SetTexCoord(col * w, col * w + w, row * h, row * h + h)
  end)
end

-- VARIANTE 2 – Blizzards eigene Hilfsfunktion SetRaidTargetIconTexture, die
-- dieselbe Rechnung in Blizzards vertrauenswürdigem Code macht. Status: kein
-- Fehler, zeichnet aber nichts – sie verweigert still, sobald der Index geheim ist.
local function setMark_Blizzard(tex, index)
  return pcall(SetRaidTargetIconTexture, tex, index)
end

-- VARIANTE 3 – einzelne Bilddateien pro Symbol, per Dateiname statt Rechnung.
-- Status: tostring() auf einen geheimen Index ist erlaubt (die Debug-Zeilen
-- zeigen das), aber der entstehende Text wird von SetTexture trotzdem als
-- "aus Geheimem abgeleitet" abgelehnt.
local function setMark_IconFiles(tex, index)
  return pcall(function()
    tex:SetTexture(R.FILE_PREFIX .. tostring(index))
    tex:SetTexCoord(0, 1, 0, 1)
  end)
end

local MARK_METHODS = { setMark_Manual, setMark_Blizzard, setMark_IconFiles }
-- Namen nur für die Entwickler-Ausgabe von /twf mark
ns.MARK_METHOD_NAMES = { 'Manual math', 'Blizzard API', 'Icon files' }

function ns.setMark(tex, index)
  if not index then
    tex:Hide()
    return
  end
  local fn = MARK_METHODS[ns.db.markMethod] or MARK_METHODS[1]
  local ok = fn(tex, index)
  if ok then tex:Show() else tex:Hide() end
end

-- Nächste Variante (/twf mark)
function ns.cycleMarkMethod()
  local db = ns.db
  db.markMethod = (db.markMethod % #ns.MARK_METHOD_NAMES) + 1
  ns.refresh()
end
