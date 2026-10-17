--[[
  Nameplates.lua — TWF-Nameplates (Anforderungen J + K).

  Checkbox "TWF-Nameplates" (db.twfNameplates):
    an  – Blizzards Nameplates (Gegner und Spieler) werden unsichtbar (SetAlpha 0).
          Sie bleiben im Spiel aktiv (Daten, Klickfläche). Gegner im Kampf bekommen
          eine TWF-Nameplate: Lebensbalken in Ampelfarbe im Zauberbalken-Stil,
          Name darüber, Leben in % rechts im Balken, eigene Aggro in % links
          (Checkbox "Aggro-% am Balken", Anforderung P). Dein Ziel bekommt zusätzlich Blizzards
          eigene Zauberleiste.
          Farbe, Deckkraft, blinkender Rahmen und "Balken zeigen" kommen pro Zustand
          aus der Tabelle im Reiter Nameplates (PlateStates.lua, Anforderung V).
          Zustände mit "Balken zeigen" aus (Standard: außerhalb des Kampfs) zeigen nur
          den Namen in der Farbe des Spiels (rot feindlich, gelb passiv; Anforderung N).
          Blizzards eigener Namenstext der Nameplate ist grau und wird nicht verwendet.
          Schlachtzugsymbole bleiben sichtbar (Bug B1).
    aus – alles im Blizzard-Original, TWF-Nameplates ausgeblendet.

  Erkenntnisse aus TESTS-MACHBARKEIT.md:
  - Blizzard setzt die Deckkraft beim Kampfbeginn zurück → Hook auf SetAlpha (T5i).
  - Leben ist geheim, lässt sich aber direkt an Balken/Text geben (T4, T4b).
  - Eigene Zauberleiste unmöglich (Zauberdaten geheim) → Blizzards CastBarsContainer
    mit SetIgnoreParentAlpha(true) sichtbar lassen (T5i).
  - Klicks gehen an Blizzards Klickfläche; unsere Elemente nehmen keine Maus an
    und liegen genau auf Blizzards Lebensleiste (T2).
  - Gegnernamen sind in Instanzen geheim → nur anzeigen, nie vergleichen.
]]

local _, ns = ...
local C = ns.Config
local N = C.NAMEPLATES

local fallbackWarned = false   -- Debug-Hinweis "Lebensleiste nicht gefunden" nur einmal
local threatSecretSeen = false -- Debug-Hinweis "Aggro-% geheim" nur einmal
local threatFailWarned = false -- Debug-Hinweis "Aggro-% nicht anzeigbar" nur einmal
local foreignSeen = false      -- Debug-Hinweis "fremder Mob" nur einmal
local atlasOK                  -- nil = noch nicht geprüft

local function active()
  return ns.db and ns.db.twfNameplates
end

local function atlasesAvailable()
  if atlasOK == nil then
    atlasOK = ns.hasAtlas(N.FILL)
      and ns.hasAtlas(N.BAR_BG) and ns.hasAtlas(N.BAR_BORDER)
    if not atlasOK then ns.dbg('NAMEPLATES', 'Zauberbalken-Atlanten fehlen, nutze schlichte Balken') end
  end
  return atlasOK
end

local function unitOf(nameplate)
  return nameplate.namePlateUnitToken or (nameplate.UnitFrame and nameplate.UnitFrame.unit)
end

-- Blizzard-Teil ------------------------------------------------------------------------------

-- Blizzards Nameplate unsichtbar machen. Der Hook hält sie unsichtbar, wenn Blizzard
-- die Deckkraft später zurücksetzt; ist der Modus aus, tut er nichts.
local function hideBlizzard(uf)
  if uf.IsForbidden and uf:IsForbidden() then return end
  if not uf.twfHooked then
    uf.twfHooked = true
    hooksecurefunc(uf, 'SetAlpha', function(self, a)
      if active() and a ~= 0 then self:SetAlpha(0) end
    end)
  end
  uf:SetAlpha(0)
end

local function showBlizzard(uf)
  if uf.IsForbidden and uf:IsForbidden() then return end
  uf:SetAlpha(1)
end

-- Blizzards Zauberleiste sichtbar lassen, obwohl ihre Nameplate unsichtbar ist
local function setCastbar(uf, on)
  local cb = uf and uf.CastBarsContainer
  if cb and cb.SetIgnoreParentAlpha then pcall(cb.SetIgnoreParentAlpha, cb, on) end
end

-- Gleicher Trick für weitere Blizzard-Teile der Nameplate (Feldnamen getestet 2026-10-13):
-- Sie bleiben sichtbar, obwohl ihre Nameplate unsichtbar ist. Blizzard zeichnet sie selbst,
-- also stimmen Aussehen und Farben mit dem Original, und TWF liest nichts Geheimes.
local function keepVisible(region, on)
  if region and region.SetIgnoreParentAlpha then pcall(region.SetIgnoreParentAlpha, region, on) end
end

-- Schlachtzugsymbol (Totenkopf, Stern …): im TWF-Modus immer sichtbar lassen (Bug B1)
local function setRaidIcon(uf, on)
  keepVisible(uf and uf.RaidTargetFrame, on)
end

-- Blizzards Schlachtzugsymbol an die TWF-Anzeige setzen: über dem Namen, solange nur der
-- Name zu sehen ist, sonst links vor dem Balken. Die ursprünglichen Anker werden einmal
-- gemerkt, damit das Symbol im Blizzard-Modus wieder an seine alte Stelle kommt.
-- Alles in pcall: Es ist Blizzards Element, und gelesene Anker können geheim sein.
local function placeRaidIcon(uf, p, nameOnly)
  local r = uf and uf.RaidTargetFrame
  if not r then return end
  if not r.twfOrig then
    r.twfOrig = {}
    pcall(function()
      for i = 1, r:GetNumPoints() do r.twfOrig[i] = { r:GetPoint(i) } end
    end)
  end
  pcall(function()
    r:ClearAllPoints()
    if nameOnly then
      r:SetPoint('BOTTOM', p.name, 'TOP', 0, N.RAID_ICON_Y)
    else
      r:SetPoint('RIGHT', p, 'LEFT', -N.RAID_ICON_GAP, 0)
    end
  end)
end

local function restoreRaidIcon(uf)
  local r = uf and uf.RaidTargetFrame
  if not (r and r.twfOrig and #r.twfOrig > 0) then return end
  pcall(function()
    r:ClearAllPoints()
    for _, point in ipairs(r.twfOrig) do r:SetPoint(unpack(point)) end
  end)
end


-- TWF-Nameplate ------------------------------------------------------------------------------

-- Pro Blizzard-Nameplate einmal anlegen; das Spiel verwendet Nameplates wieder.
local function getPlate(nameplate)
  local p = nameplate.twfPlate
  if p then return p end

  p = CreateFrame('Frame', nil, nameplate)   -- nimmt keine Maus an → Klick geht an Blizzard
  p:SetFrameLevel(nameplate:GetFrameLevel() + N.LEVEL)

  -- Balken im Stil von Blizzards Zauberbalken (übernommen aus SealTimersForever):
  -- Hintergrund 1 px und Rahmen 2 px größer als der Balken
  local bar = CreateFrame('StatusBar', nil, p)
  bar:SetAllPoints()
  bar.bg = bar:CreateTexture(nil, 'BACKGROUND', nil, -1)
  bar.bg:SetPoint('TOPLEFT', -N.BG_INSET, N.BG_INSET)
  bar.bg:SetPoint('BOTTOMRIGHT', N.BG_INSET, -N.BG_INSET)
  bar.border = bar:CreateTexture(nil, 'OVERLAY', nil, 1)
  bar.border:SetPoint('TOPLEFT', -N.BORDER_INSET, N.BORDER_INSET)
  bar.border:SetPoint('BOTTOMRIGHT', N.BORDER_INSET, -N.BORDER_INSET)
  if atlasesAvailable() then
    bar.bg:SetAtlas(N.BAR_BG)
    bar.border:SetAtlas(N.BAR_BORDER)
  else
    bar.bg:SetColorTexture(unpack(C.WINDOW.BG_FALLBACK))
    bar.border:Hide()
  end
  p.bar = bar

  -- Prozent im Balken, über dem Rahmen (eigene Unterebene, Lehre aus dem Threat-Balken)
  p.pct = bar:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  p.pct:SetDrawLayer('OVERLAY', N.PCT_LAYER)
  p.pct:SetPoint('RIGHT', bar, 'RIGHT', N.PCT_X, 0)

  -- Eigene Aggro in Prozent, links im Balken (Anforderung P)
  p.threat = bar:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  p.threat:SetDrawLayer('OVERLAY', N.PCT_LAYER)
  p.threat:SetPoint('LEFT', bar, 'LEFT', N.THREAT_PCT_X, 0)

  -- Blinkender Rahmen; ob und in welcher Farbe, steht pro Zustand in der Tabelle (Anforderung V)
  p.alarm = ns.createGlow(bar, N.BLINK)

  -- Name über dem Balken
  p.name = p:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  p.name:SetPoint('BOTTOM', p, 'TOP', 0, N.NAME_Y)

  nameplate.twfPlate = p
  return p
end

-- Auf Blizzards Lebensleiste legen (Klickfläche + Zauberleiste sitzt darunter)
local function place(p, nameplate, uf)
  p:ClearAllPoints()
  local hb = uf and (uf.healthBar or uf.HealthBar)
  if hb then
    p:SetAllPoints(hb)
  else
    p:SetPoint('CENTER', nameplate, 'CENTER')
    p:SetSize(N.WIDTH, N.HEIGHT)
    if not fallbackWarned then
      fallbackWarned = true
      ns.dbg('NAMEPLATES', 'Blizzards Lebensleiste nicht gefunden, nutze Rückfallgröße')
    end
  end
end

-- Balkenfarbe (Anforderung V): Zauberbalken-Füllung entsättigt und in der Farbe des
-- Zustands getönt, damit jede Farbe frei wählbar ist. Die Füllung wird nur einmal gesetzt.
local function setColor(p, color)
  local bar = p.bar
  if not p.fillSet then
    p.fillSet = true
    if atlasesAvailable() then
      bar:SetStatusBarTexture(N.FILL)
      bar:GetStatusBarTexture():SetDesaturated(true)
    else
      bar:SetStatusBarTexture(N.PLAIN_FILL)
    end
  end
  bar:SetStatusBarColor(color[1], color[2], color[3])
end

-- Werte setzen. Leben und Name können geheim sein: nur weiterreichen, nie auswerten.
local function fill(p, unit)
  pcall(function()
    p.bar:SetMinMaxValues(0, UnitHealthMax(unit))
    p.bar:SetValue(UnitHealth(unit))
  end)
  local okP = UnitHealthPercent and CurveConstants and CurveConstants.ScaleTo100
    and pcall(function()
      p.pct:SetFormattedText(N.PCT_FORMAT, UnitHealthPercent(unit, true, CurveConstants.ScaleTo100))
    end)
  p.pct:SetShown(okP and true or false)
end

-- Eigene Aggro in % (Anforderung P). Über nameplateN ist der Wert evtl. geheim:
-- dann nur an den Text weiterreichen, nie vergleichen. nil = nicht auf der Bedrohungsliste.
local function fillThreat(p, unit)
  if not (ns.db and ns.db.threatPct) then p.threat:Hide() return end
  local ok, _, _, pct = pcall(UnitDetailedThreatSituation, 'player', unit)
  local secret = ok and ns.IsSecret(pct)
  if not ok or (not secret and pct == nil) then p.threat:Hide() return end
  if secret and not threatSecretSeen then
    threatSecretSeen = true
    ns.dbg('NAMEPLATES', 'Aggro-% ist geheim, wird nur an den Text weitergereicht')
  end
  local okF, err = pcall(p.threat.SetFormattedText, p.threat, N.THREAT_PCT_FORMAT, pct)
  if not okF and not threatFailWarned then
    threatFailWarned = true
    ns.dbg('NAMEPLATES', 'Aggro-% lässt sich nicht anzeigen: ' .. tostring(err))
  end
  p.threat:SetShown(okF)
end

-- Position des Namens: über dem Balken, oder (wenn nur der Name zu sehen ist) an der
-- Stelle des Balkens, damit er nicht höher schwebt als der Name aus der Ferne.
local function placeName(p, nameOnly)
  p.name:ClearAllPoints()
  if nameOnly then
    p.name:SetPoint('CENTER', p, 'CENTER', 0, N.NAME_ONLY_Y)
  else
    p.name:SetPoint('BOTTOM', p, 'TOP', 0, N.NAME_Y)
  end
end

-- Name setzen (kann geheim sein: nur weiterreichen). reactionColor = true färbt ihn so,
-- wie das Spiel den Gegner einfärbt (rot feindlich, gelb passiv), sonst weiß.
local function fillName(p, unit, reactionColor)
  if not pcall(function() p.name:SetText(UnitName(unit)) end) then p.name:SetText('') end
  local colored = reactionColor and pcall(function()
    p.name:SetTextColor(UnitSelectionColor(unit))
  end)
  if not colored then p.name:SetTextColor(unpack(C.WHITE)) end
end

local function hidePlate(nameplate)
  if nameplate.twfPlate then nameplate.twfPlate:Hide() end
  setCastbar(nameplate.UnitFrame, false)
end

-- Liegt die Nameplate hinter einer Wand? Blizzard dunkelt verdeckte Nameplates ab; die
-- Deckkraft ist lesbar (getestet 2026-10-13). Ist sie einmal geheim, gilt "nicht verdeckt".
function ns.isOccluded(nameplate)
  local ok, alpha = pcall(nameplate.GetAlpha, nameplate)
  alpha = ok and ns.plain(alpha) or nil
  return alpha ~= nil and alpha < N.OCCLUDED_ALPHA
end

-- Deckkraft eines TWF-Balkens: Ziel immer mit dem Ziel-Wert (auch hinter Wänden), hinter
-- Wänden der Wand-Wert (beide Regler unter "Allgemein"), sonst die Deckkraft des Zustands (V).
local function barAlpha(nameplate, isTarget, cfg)
  local db = ns.db
  if isTarget then return db.alphaTarget end
  if ns.isOccluded(nameplate) then return db.alphaOccluded end
  return cfg.alpha
end

-- Zustand der Nameplate (Schlüssel in C.PLATE_STATES)
local function stateOf(unit)
  if ns.engaged(unit) and ns.isForeign(unit) then
    if not foreignSeen then
      foreignSeen = true
      ns.dbg('NAMEPLATES', 'Fremder Mob erkannt (andere Gruppe)')
    end
    return 'foreign'       -- gehört einer anderen Gruppe (Anforderung U)
  end
  if ns.engaged(unit) then
    local c, pullFromTank = ns.unitColor(unit)
    if c == 'yellow' and pullFromTank then return 'pull' end  -- du ziehst dem anderen Tank ab (T)
    return c or 'blue'     -- blau: kämpft, aber nicht mit dir
  end
  return 'grey'            -- außerhalb des Kampfs
end

-- Eine Nameplate aktualisieren
local function update(nameplate, targetPlate)
  local unit = unitOf(nameplate)
  local uf = nameplate.UnitFrame
  if not unit or not uf then return end
  if not active() then return end

  hideBlizzard(uf)

  local okH, hostile = pcall(UnitCanAttack, 'player', unit)
  if not (okH and hostile) then
    -- Spieler und freundliche Einheiten: Blizzard unsichtbar, keine TWF-Nameplate
    hidePlate(nameplate)
    setRaidIcon(uf, false)
    restoreRaidIcon(uf)
    return
  end
  setRaidIcon(uf, true)

  -- Ziel per Frame-Vergleich erkennen: liest keinen geheimen Wert
  local isTarget = (nameplate == targetPlate)
  local cfg = ns.plateState(stateOf(unit))

  local p = getPlate(nameplate)
  place(p, nameplate, uf)
  -- "Balken zeigen" aus (Standard bei "Außer Kampf", Anforderung N/V): nur der Name.
  -- Dein Ziel bekommt immer einen Balken.
  if not (cfg.show or isTarget) then
    -- Gleiche Schrift und Stelle wie bei der vollen TWF-Nameplate, Farbe wie im Spiel.
    p.bar:Hide()
    p:SetAlpha(1)
    p:SetIgnoreParentAlpha(N.NAME_ONLY_FULL_ALPHA)
    placeName(p, true)
    fillName(p, unit, true)
    -- Hinter Wänden wird nur dieser Name ausgeblendet (Anforderung O). Das
    -- Schlachtzugsymbol bleibt sichtbar und behält seinen Platz über dem Namen.
    p.name:SetShown(not ns.isOccluded(nameplate))
    p:Show()
    setCastbar(uf, false)
    placeRaidIcon(uf, p, true)
    return
  end
  p.bar:Show()
  -- Deckkraft setzt TWF selbst, Blizzards Abdunkeln zählt nicht
  p:SetIgnoreParentAlpha(true)
  p:SetAlpha(barAlpha(nameplate, isTarget, cfg))
  ns.setGlowColor(p.alarm, cfg.frame)
  ns.setGlow(p.alarm, cfg.blink)
  setColor(p, cfg.color)
  fill(p, unit)
  fillThreat(p, unit)
  placeName(p, false)
  fillName(p, unit, false)
  p.name:Show()
  p:Show()
  setCastbar(uf, isTarget)
  placeRaidIcon(uf, p, false)
end

local function currentTargetPlate()
  local ok, plate = pcall(C_NamePlate.GetNamePlateForUnit, 'target')
  return ok and plate or nil
end

local lastForbidden = 0         -- für die Debug-Meldung zu gesperrten Nameplates

local function updateAll()
  if not active() then return end
  local targetPlate = currentTargetPlate()
  local plates = C_NamePlate.GetNamePlates(false) or {}
  for _, nameplate in ipairs(plates) do
    update(nameplate, targetPlate)
  end
  -- Gesperrte ("forbidden") Nameplates kann TWF nicht ausblenden. Nur bei Änderung melden.
  local ok, all = pcall(C_NamePlate.GetNamePlates, true)
  local forbidden = (ok and all) and (#all - #plates) or 0
  if forbidden ~= lastForbidden then
    lastForbidden = forbidden
    ns.dbg('NAMEPLATES', 'Gesperrte Nameplates (nicht ausblendbar): ' .. forbidden)
  end
end

-- Modus aus: alles zurück auf Blizzard-Original
local function restoreAll()
  for _, nameplate in ipairs(C_NamePlate.GetNamePlates(false) or {}) do
    hidePlate(nameplate)
    local uf = nameplate.UnitFrame
    if uf then
      setRaidIcon(uf, false)
      restoreRaidIcon(uf)
      showBlizzard(uf)
    end
  end
end

-- Ereignisse --------------------------------------------------------------------------------

local events = CreateFrame('Frame')
events:SetScript('OnEvent', function(_, event, unit)
  if not active() then return end
  if event == 'NAME_PLATE_UNIT_ADDED' then
    -- Einen Moment warten: Blizzard richtet die Nameplate erst nach diesem Ereignis
    -- fertig ein (gleiches Vorgehen wie MiniMarkers). Sonst greift TWF zu früh zu.
    C_Timer.After(N.ADD_DELAY, function()
      if not active() then return end
      local ok, nameplate = pcall(C_NamePlate.GetNamePlateForUnit, unit)
      if ok and nameplate then update(nameplate, currentTargetPlate()) end
    end)
  elseif event == 'NAME_PLATE_UNIT_REMOVED' then
    local ok, nameplate = pcall(C_NamePlate.GetNamePlateForUnit, unit)
    if ok and nameplate then
      -- Nameplates werden wiederverwendet: sauber zurücklassen
      hidePlate(nameplate)
      setRaidIcon(nameplate.UnitFrame, false)
      restoreRaidIcon(nameplate.UnitFrame)
    end
  elseif event == 'PLAYER_ENTERING_WORLD' then
    -- Nach Login/Ladebildschirm alles noch einmal prüfen, wenn Blizzard fertig ist
    C_Timer.After(N.WORLD_DELAY, function()
      ns.dbg('NAMEPLATES', 'Neuprüfung nach Betreten der Welt')
      updateAll()
    end)
  elseif event == 'PLAYER_TARGET_CHANGED' then
    ns.dbg('NAMEPLATES', 'Zielwechsel: ' .. (currentTargetPlate() and 'Ziel hat eine Nameplate' or 'Ziel ohne Nameplate'))
    updateAll()
  end
end)

local function onLogin()
  if not (C_NamePlate and C_NamePlate.GetNamePlates and C_NamePlate.GetNamePlateForUnit) then
    ns.dbg('NAMEPLATES', 'Nameplate-API fehlt, TWF-Nameplates nicht verfügbar')
    return
  end
  events:RegisterEvent('NAME_PLATE_UNIT_ADDED')
  events:RegisterEvent('NAME_PLATE_UNIT_REMOVED')
  events:RegisterEvent('PLAYER_TARGET_CHANGED')
  events:RegisterEvent('PLAYER_ENTERING_WORLD')
  ns.dbg('NAMEPLATES', 'TWF-Nameplates ' .. (active() and 'an' or 'aus'))
  updateAll()
end

local function onSettingChanged(key)
  if key == 'threatPct' then
    ns.dbg('NAMEPLATES', key .. ' ' .. (ns.db[key] and 'an' or 'aus'))
    if active() then updateAll() end
    return
  end
  if key == 'alphaTarget' or key == 'alphaOccluded' then
    ns.dbg('NAMEPLATES', 'Deckkraft ' .. key .. ' = ' .. ns.db[key])
    if active() then updateAll() end
    return
  end
  -- Tabelle im Reiter Nameplates oder Rolle geändert (Anforderung V)
  if key == 'plates' or key == 'plateShared' or key == 'role' then
    if active() then updateAll() end
    return
  end
  if key ~= 'twfNameplates' then return end
  ns.dbg('NAMEPLATES', 'Modus gewechselt: ' .. (active() and 'TWF-Nameplates' or 'Blizzard-Original'))
  if active() then updateAll() else restoreAll() end
end

ns.RegisterModule('Nameplates', {
  OnLogin = onLogin,
  OnTick = updateAll,
  OnSettingChanged = onSettingChanged,
})
