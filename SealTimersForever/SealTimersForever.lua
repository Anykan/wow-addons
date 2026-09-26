-- Seal Timers Forever: los sellos de paladin activos en pantalla con su tiempo
-- restante, en un bloque que se mueve y cambia de tamano. Solo WoW Forever.
--
-- Valores secretos: en Forever, con restricciones activas (combate, encuentro,
-- PvP...), los datos de las auras son secretos para los addons, incluido todo
-- el contenido de UNIT_AURA. Con un secreto no se puede ni comparar (tampoco
-- con nil) ni preguntar si es verdadero: da un error de Lua, que el juego no
-- muestra por defecto. Regla de todo el fichero: mirar IsSecret ANTES de tocar
-- un valor que venga de un aura.
--
-- El tiempo:
--   * Sello lanzado por el jugador (via principal): se detecta por su
--     LANZAMIENTO. UNIT_SPELLCAST_* solo es secreto si la unidad no es el
--     jugador ni su mascota, asi que siempre se lee. Cuenta desde el
--     lanzamiento con la duracion aprendida o 30 s (la de todo sello en
--     Forever). En la beta las auras de los sellos no se leen ni fuera de combate.
--   * Sello ya activo sin lanzamiento visto (tras /reload): el tiempo del aura.
--     GetAuraDuration da un objeto de duracion que va tal cual a un Cooldown.
-- El evento del lanzamiento llega antes de que el juego renueve el aura, asi
-- que el tiempo se relee un instante despues. Al salir de combate se relee todo.
--
-- En Forever solo hay un sello activo: al lanzar otro, el anterior se sustituye
-- y deja un "Eco". Si el eco lleva el nombre del sello viejo no debe pasar por
-- el sello activo ni ensenar su duracion corta: el activo es el ultimo lanzado,
-- y la duracion aprendida solo puede crecer. El Juicio ya no consume el sello.
-- Contrastado con Gethe/wow-ui-source, rama "forever".

local _, ns = ...
local L = ns.L

-- Rango 1 de cada sello clasico (Rectitud, Cruzado, Luz, Sabiduria, Justicia y
-- Orden): sirven para pedir al cliente sus nombres en el idioma del jugador y
-- sacar el prefijo comun ("Sello de", "Seal of"...). Los sellos nuevos de
-- Forever (p. ej. Sello de Furia) entran por ese prefijo y por el libro de
-- hechizos, sin saber su ID.
local SEAL_SPELLS = { 21084, 21082, 20165, 20166, 20164, 20375 }

local ICON_SIZE = 40
local SPACING = 4
-- Margen para que un sello recien lanzado no se de por perdido cuando su aura
-- vieja desaparece justo despues de relanzarlo.
local RECAST_GRACE = 1
-- Cuanto esperar tras el lanzamiento para releer el aura ya renovada
local RECAST_REFRESH = 0.2
-- En Forever todos los sellos duran 30 s (datos de habilidades del paladin). Si
-- el aura de un sello se llega a leer, manda su duracion real.
local DEFAULT_DURATION = 30
-- Morado de la marca, el mismo del titulo en todos los addons de Pirson
local BRAND = "|cffd597ff"
-- barY por defecto: justo donde quedaba la barra antes de tener su propio
-- anclaje (2 px bajo el icono, con el icono centrado en y = -150).
local DEFAULTS = {
    locked = true, scale = 1, barWidth = ICON_SIZE,
    point = "CENTER", x = 0, y = -150,
    barPoint = "CENTER", barX = 0, barY = -176,
    -- Numeros sueltos, no una tabla: si no, todos los perfiles sin color
    -- guardado compartirian la MISMA tabla que DEFAULTS y un cambio de color
    -- se colaria en los valores por defecto de todo el mundo.
    barColorR = 0.84, barColorG = 0.59, barColorB = 1,
    showIcon = true, showBar = true,
    -- Estilo de la barra de lanzamiento del juego (marco + fondo + relleno)
    blizzStyle = true,
}
-- Sube cuando cambia como se aprenden las duraciones: las viejas se descartan
-- (la 1: las antiguas podian ser la de un eco, mucho mas corta).
local DURATIONS_VERSION = 1
local EMPTY = {}

local db
local sealNames, sealPrefix = {}, nil
local knownSeals = {}          -- spellID del libro de hechizos -> nombre del sello
local icons, order, pool = {}, {}, {}  -- nombre del sello -> icono
local activeSeal               -- nombre del ultimo sello lanzado (o elegido al releer)
local debugMode = false
local anchor      -- bloque de iconos
local barAnchor   -- bloque de la barra, se mueve por separado

--------------------------------------------------
-- VALORES SECRETOS
--------------------------------------------------
local function IsSecret(value)
    return issecretvalue ~= nil and issecretvalue(value)
end

-- Se puede usar: ni secreto ni nil. IsSecret va primero: comparar un secreto
-- con nil ya es un error.
local function Readable(value)
    if IsSecret(value) then return false end
    return value ~= nil
end

-- Una lista del evento, o vacia si es secreta o no hay
local function List(value)
    if not Readable(value) then return EMPTY end
    return value
end

local function Debug(msg)
    if debugMode then print(BRAND .. "STF|r " .. msg) end
end

--------------------------------------------------
-- QUE ES UN SELLO
--------------------------------------------------
local function CommonPrefix(a, b)
    local i = 0
    while i < #a and i < #b and a:byte(i + 1) == b:byte(i + 1) do i = i + 1 end
    return a:sub(1, i)
end

local function BuildSealNames()
    local count = 0
    for _, spellID in ipairs(SEAL_SPELLS) do
        local name = C_Spell.GetSpellName(spellID)
        if name then
            sealNames[name] = true
            sealPrefix = sealPrefix and CommonPrefix(sealPrefix, name) or name
            count = count + 1
        end
    end
    -- Con un solo nombre, o un prefijo tan corto que casaria con cualquier cosa,
    -- solo valen los nombres exactos.
    if count < 2 or #sealPrefix < 4 then sealPrefix = nil end
end

local function IsSeal(name)
    if not Readable(name) then return false end
    return sealNames[name] or (sealPrefix ~= nil and name:sub(1, #sealPrefix) == sealPrefix)
end

-- Todos los sellos que conoce el jugador, tambien los nuevos de Forever
local function ScanSpellBook()
    for line = 1, C_SpellBook.GetNumSpellBookSkillLines() do
        local info = C_SpellBook.GetSpellBookSkillLineInfo(line)
        for slot = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
            local item = C_SpellBook.GetSpellBookItemInfo(slot, Enum.SpellBookSpellBank.Player)
            if item and item.spellID and IsSeal(item.name) then
                knownSeals[item.spellID] = item.name
                sealNames[item.name] = true
            end
        end
    end
end

local function SealNameForSpell(spellID)
    if not Readable(spellID) then return nil end
    if knownSeals[spellID] then return knownSeals[spellID] end
    local name = C_Spell.GetSpellName(spellID)
    return IsSeal(name) and name or nil
end

--------------------------------------------------
-- ICONOS (uno por sello, por nombre)
--------------------------------------------------
local HideSeal

-- Estilo de la barra de lanzamiento del juego: mismos atlas que usa el
-- CastingBarFrame de Blizzard (relleno, fondo y marco). Si el cliente no los
-- tiene, se cae a la barra lisa de antes.
local BLIZZ_FILL, BLIZZ_BG, BLIZZ_BORDER =
    "ui-castingbar-filling-standard", "ui-castingbar-background", "ui-castingbar-frame"
local PLAIN_FILL = "Interface\\TargetingFrame\\UI-StatusBar"
local PLAIN_HEIGHT, BLIZZ_HEIGHT = 8, 11
local blizzAtlasOK   -- nil = aun sin comprobar

local function AtlasExists(name)
    local getInfo = (C_Texture and C_Texture.GetAtlasInfo) or GetAtlasInfo
    return getInfo ~= nil and getInfo(name) ~= nil
end

local function AtlasesAvailable()
    if blizzAtlasOK == nil then
        blizzAtlasOK = AtlasExists(BLIZZ_FILL) and AtlasExists(BLIZZ_BG) and AtlasExists(BLIZZ_BORDER)
    end
    return blizzAtlasOK
end

local function BlizzStyleActive()
    return db.blizzStyle and AtlasesAvailable()
end

-- Pone una barra en el estilo activo. Se llama al crearla y cada vez que
-- cambia la opcion, tambien para las del pool (se reusan tal cual).
local function StyleBar(bar)
    if BlizzStyleActive() then
        bar:SetStatusBarTexture(BLIZZ_FILL)
        bar:SetHeight(BLIZZ_HEIGHT)
        bar:SetStatusBarColor(1, 1, 1)   -- el relleno ya trae su color, sin tintar
        bar.bg:Hide()
        bar.blizzBg:Show()
        bar.border:Show()
    else
        bar:SetStatusBarTexture(PLAIN_FILL)
        bar:SetHeight(PLAIN_HEIGHT)
        bar:SetStatusBarColor(db.barColorR, db.barColorG, db.barColorB)
        bar.bg:Show()
        bar.blizzBg:Hide()
        bar.border:Hide()
    end
end

local function AcquireIcon()
    local icon = table.remove(pool)
    if not icon then
        icon = CreateFrame("Frame", nil, anchor)
        icon:SetSize(ICON_SIZE, ICON_SIZE)
        icon.texture = icon:CreateTexture(nil, "ARTWORK")
        icon.texture:SetAllPoints()
        icon.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        icon.texture:SetShown(db.showIcon)
        icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
        icon.cooldown:SetAllPoints()
        icon.cooldown:SetReverse(true)
        icon.cooldown:SetDrawEdge(false)
        icon.cooldown:SetHideCountdownNumbers(false)
        icon.cooldown:SetShown(db.showIcon)
        -- Se acabo el tiempo: el sello expiro (tambien cubre retiradas que
        -- llegaron secretas y no se pudieron leer).
        icon.cooldown:SetScript("OnCooldownDone", function(self)
            local parent = self:GetParent()
            if parent.hasTimer and parent.sealName then HideSeal(parent.sealName) end
        end)
        -- Barra con su propio anclaje (barAnchor), no colgada del icono: asi
        -- se puede mover a cualquier parte de la pantalla por separado. Se
        -- llena/vacia con el mismo tiempo que el swipe circular. Solo se
        -- muestra si el tiempo del Cooldown es legible (ver SyncBar): con
        -- valores secretos no hay numeros que ponerle a una barra.
        icon.bar = CreateFrame("StatusBar", nil, barAnchor)
        icon.bar:SetSize(db.barWidth, PLAIN_HEIGHT)
        icon.bar:SetPoint("CENTER", barAnchor, "CENTER", 0, 0)
        icon.bar:SetMinMaxValues(0, 1)
        -- Barra lisa (estilo antiguo)
        icon.bar.bg = icon.bar:CreateTexture(nil, "BACKGROUND")
        icon.bar.bg:SetAllPoints()
        icon.bar.bg:SetColorTexture(0, 0, 0, 0.6)
        -- Estilo del juego: fondo 1 px mas grande y marco 2 px mas grande que la
        -- barra, como el CastingBarFrame de Blizzard.
        icon.bar.blizzBg = icon.bar:CreateTexture(nil, "BACKGROUND", nil, -1)
        icon.bar.blizzBg:SetPoint("TOPLEFT", icon.bar, "TOPLEFT", -1, 1)
        icon.bar.blizzBg:SetPoint("BOTTOMRIGHT", icon.bar, "BOTTOMRIGHT", 1, -1)
        icon.bar.border = icon.bar:CreateTexture(nil, "OVERLAY", nil, 1)
        -- Solo con atlas que existan: SetAtlas con un nombre desconocido no debe pasar
        if AtlasesAvailable() then
            icon.bar.blizzBg:SetAtlas(BLIZZ_BG)
            icon.bar.border:SetAtlas(BLIZZ_BORDER)
        end
        icon.bar.border:SetPoint("TOPLEFT", icon.bar, "TOPLEFT", -2, 2)
        icon.bar.border:SetPoint("BOTTOMRIGHT", icon.bar, "BOTTOMRIGHT", 2, -2)
        icon.bar.text = icon.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall", 2)
        icon.bar.text:SetPoint("CENTER")
        StyleBar(icon.bar)
        icon.bar:Hide()
    end
    icon:Show()
    return icon
end

local function Layout()
    for i, name in ipairs(order) do
        local icon = icons[name]
        icon:ClearAllPoints()
        icon:SetPoint("LEFT", anchor, "LEFT", (i - 1) * (ICON_SIZE + SPACING), 0)
    end
end

-- Un solo OnUpdate para todas las barras (como mucho hay un par de sellos a
-- la vez, asi que recorrer 'order' cada frame no cuesta nada).
local function UpdateBars()
    local now = GetTime()
    for _, name in ipairs(order) do
        local icon = icons[name]
        if icon.barStart and icon.barDuration then
            local remaining = icon.barDuration - (now - icon.barStart)
            if remaining < 0 then remaining = 0 end
            icon.bar:SetValue(remaining / icon.barDuration)
            icon.bar.text:SetText(remaining < 5 and ("%.1f"):format(remaining) or ("%.0f"):format(remaining))
        end
    end
end

local function ShowSeal(name, texture)
    local icon = icons[name]
    if not icon then
        icon = AcquireIcon()
        icon.sealName = name
        icons[name] = icon
        order[#order + 1] = name
    end
    if Readable(texture) then icon.texture:SetTexture(texture) end
    return icon
end

HideSeal = function(name)
    local icon = icons[name]
    if not icon then return end
    icon:Hide()
    -- El temporizador se para antes de volver al pool: un OnCooldownDone tardio
    -- no debe quitar el sello que reutilice este icono.
    icon.hasTimer = false
    icon.cooldown:Clear()
    icon.bar:Hide()
    icon.barStart, icon.barDuration = nil, nil
    icon.sealName, icon.auraInstanceID, icon.castAt = nil, nil, nil
    if activeSeal == name then activeSeal = nil end
    pool[#pool + 1] = icon
    icons[name] = nil
    for i = #order, 1, -1 do
        if order[i] == name then table.remove(order, i) end
    end
end

-- Solo un sello activo a la vez
local function HideOtherSeals(name)
    for i = #order, 1, -1 do
        if order[i] ~= name then HideSeal(order[i]) end
    end
end

local function AuraExists(id)
    local data = C_UnitAuras.GetAuraDataByAuraInstanceID("player", id)
    if IsSecret(data) then return true end
    return data ~= nil
end

-- La duracion de un sello es fija: solo crece. Asi un eco corto con el mismo
-- nombre, o un aura a medias, no la estropea.
local function Learn(name, total)
    if Readable(total) and total > (db.durations[name] or 0) then
        db.durations[name] = total
        Debug(("aprendido %s = %.1f s"):format(name, total))
    end
end

local function SealDuration(name)
    return db.durations[name] or DEFAULT_DURATION
end

-- Si el aura es legible, aprende de paso su duracion real
local function LearnFromAura(name, id)
    local duration = C_UnitAuras.GetAuraDuration("player", id)
    if duration:HasSecretValues() or duration:IsZero() then return end
    Learn(name, duration:GetTotalDuration())
end

-- Lee start/duracion (segundos) del propio Cooldown tras fijarlo, en vez de
-- llevar la cuenta por separado: un solo sitio decide si son legibles. Con
-- valores secretos (IsSecret) la barra simplemente no se muestra; el swipe
-- circular del Cooldown si sigue funcionando, eso lo gestiona el widget.
local function SyncBar(icon)
    if not icon.hasTimer then
        icon.bar:Hide()
        icon.barStart, icon.barDuration = nil, nil
        return
    end
    local start, duration = icon.cooldown:GetCooldownTimes()
    if IsSecret(start) or IsSecret(duration) or not Readable(start) or not Readable(duration) or duration == 0 then
        icon.bar:Hide()
        icon.barStart, icon.barDuration = nil, nil
        return
    end
    icon.barStart = start / 1000
    icon.barDuration = duration / 1000
    icon.bar:SetShown(db.showBar)
end

local function StartTimer(name)
    local icon = icons[name]
    if not icon then return end
    local cooldown = icon.cooldown
    if icon.castAt then
        -- Lanzado por el jugador: su duracion desde el lanzamiento. Relanzar un
        -- sello lo renueva entero, asi que es exacto y no depende de nada secreto.
        if icon.auraInstanceID then LearnFromAura(name, icon.auraInstanceID) end
        cooldown:SetCooldown(icon.castAt, SealDuration(name))
        icon.hasTimer = true
        Debug(("%s: %.1f s desde el lanzamiento"):format(name, SealDuration(name)))
    elseif icon.auraInstanceID then
        -- Sin lanzamiento visto (p. ej. tras /reload): el tiempo del aura
        local duration = C_UnitAuras.GetAuraDuration("player", icon.auraInstanceID)
        -- HasSecretValues nunca es secreto (ReturnsNeverSecret). Con valores
        -- secretos el objeto solo se le pasa al Cooldown, sin preguntarle nada.
        if duration:HasSecretValues() then
            cooldown:SetCooldownFromDurationObject(duration)
            icon.hasTimer = true
            Debug(name .. ": tiempo del aura (secreto)")
        elseif duration:IsZero() then
            -- Sello permanente: sin temporizador (uno de 0 s acabaria al momento)
            icon.hasTimer = false
            cooldown:Clear()
            Debug(name .. ": sin duracion")
        else
            cooldown:SetCooldownFromDurationObject(duration)
            icon.hasTimer = true
            Learn(name, duration:GetTotalDuration())
            Debug(name .. ": tiempo del aura")
        end
    else
        icon.hasTimer = false
        cooldown:Clear()
        Debug(name .. ": sin tiempo")
    end
    SyncBar(icon)
end

-- El aura que seguiamos ya no esta. Si el sello se acaba de relanzar, sigue con
-- el tiempo del lanzamiento; si no, se fue (expiro o se sustituyo).
local function LoseAura(name)
    local icon = icons[name]
    if icon.castAt and GetTime() - icon.castAt < RECAST_GRACE then
        icon.auraInstanceID = nil
        StartTimer(name)
    else
        Debug(name .. ": su aura ya no esta")
        HideSeal(name)
    end
end

-- Un aura con nombre de sello. Si no es el sello activo (el ultimo lanzado) es
-- un eco o un resto del cambio: se ignora.
local function TrackAura(aura)
    local name = aura.name
    if not IsSeal(name) then return end
    if activeSeal and name ~= activeSeal then
        Debug(name .. ": ignorada (el sello activo es " .. activeSeal .. ")")
        return
    end
    activeSeal = name
    local icon = ShowSeal(name, aura.icon)
    local id = aura.auraInstanceID
    if Readable(id) then icon.auraInstanceID = id end
    HideOtherSeals(name)
    StartTimer(name)
end

--------------------------------------------------
-- EVENTOS
--------------------------------------------------
-- Relee las auras (fuera de combate son legibles). Si hay varias con nombre de
-- sello, gana el activo; si no se sabe cual es, la de mas duracion (un eco dura
-- menos que el sello).
local function FullScan()
    -- HideSeal borra el sello activo y cuando se lanzo: se guardan antes
    local wanted = activeSeal
    local wantedCastAt = wanted and icons[wanted] and icons[wanted].castAt
    for i = #order, 1, -1 do HideSeal(order[i]) end
    local best, bestTotal
    for _, aura in ipairs(List(C_UnitAuras.GetUnitAuras("player", "HELPFUL"))) do
        local name, id = aura.name, aura.auraInstanceID
        if IsSeal(name) and Readable(id) then
            if name == wanted then
                best = aura
                break
            end
            local total = C_UnitAuras.GetAuraDuration("player", id):GetTotalDuration()
            total = Readable(total) and total or 0
            if not best or total > bestTotal then best, bestTotal = aura, total end
        end
    end
    activeSeal = nil
    if best then
        TrackAura(best)
        local icon = icons[best.name]
        if icon and best.name == wanted and wantedCastAt then
            icon.castAt = wantedCastAt
            StartTimer(best.name)
        end
    end
    Layout()
end

-- Repasa los sellos seguidos por su aura: sigue ahi -> tiempo al dia; no -> fuera
local function RefreshTracked()
    for i = #order, 1, -1 do
        local name = order[i]
        local icon = icons[name]
        if icon.auraInstanceID then
            if AuraExists(icon.auraInstanceID) then StartTimer(name) else LoseAura(name) end
        end
    end
end

local function OnUnitAura(info)
    if not Readable(info) then
        Debug("UNIT_AURA sin datos legibles")
        RefreshTracked()
        Layout()
        return
    end
    local full = info.isFullUpdate
    if IsSecret(full) then
        Debug("UNIT_AURA con datos secretos")
    elseif full then
        -- En combate, con las auras secretas, releer todo borraria los sellos
        -- que no se pueden reconocer: solo se refresca lo que ya se sigue.
        if C_Secrets.ShouldAurasBeSecret() then RefreshTracked() else FullScan() end
        Layout()
        return
    end
    for _, aura in ipairs(List(info.addedAuras)) do TrackAura(aura) end
    for _, id in ipairs(List(info.removedAuraInstanceIDs)) do
        if Readable(id) then
            for _, name in ipairs(order) do
                if icons[name].auraInstanceID == id then LoseAura(name) break end
            end
        end
    end
    RefreshTracked()
    Layout()
end

local function OnSealCast(spellID)
    local name = SealNameForSpell(spellID)
    if not name then return end
    Debug(("lanzado %s (%s)"):format(name, tostring(spellID)))
    activeSeal = name
    local icon = ShowSeal(name, C_Spell.GetSpellTexture(spellID))
    icon.castAt = GetTime()
    HideOtherSeals(name)
    -- En combate no devuelve nada (el aura es secreta). Ojo: nada de "x and y"
    -- aqui, que con x = nil deja un false que pasaria por un ID valido.
    local aura = C_UnitAuras.GetPlayerAuraBySpellID(spellID)
    local id
    if Readable(aura) then id = aura.auraInstanceID end
    if Readable(id) then
        icon.auraInstanceID = id
    elseif icon.auraInstanceID and not AuraExists(icon.auraInstanceID) then
        icon.auraInstanceID = nil
    end
    StartTimer(name)
    Layout()
    -- El aura se renueva justo despues del lanzamiento: se relee entonces
    C_Timer.After(RECAST_REFRESH, function()
        if icons[name] then
            RefreshTracked()
            Layout()
        end
    end)
end

--------------------------------------------------
-- BLOQUE MOVIL
--------------------------------------------------
local function ApplyLock()
    anchor:EnableMouse(not db.locked)
    anchor.bg:SetShown(not db.locked)
    anchor.label:SetShown(not db.locked)
    barAnchor:EnableMouse(not db.locked)
    barAnchor.bg:SetShown(not db.locked)
    barAnchor.label:SetShown(not db.locked)
end

local function ApplyScale()
    anchor:SetScale(db.scale)
    barAnchor:SetScale(db.scale)
end

-- Tambien hay que tocar los iconos del pool: se reusan tal cual al volver a
-- mostrarse, asi que si se quedan con el ancho viejo no se corrige solos.
-- barAnchor tambien cambia de tamano: asi el fondo (visible al desbloquear)
-- marca el hueco real que ocupa la barra.
local function ApplyBarWidth()
    barAnchor:SetWidth(db.barWidth)
    for _, icon in pairs(icons) do icon.bar:SetWidth(db.barWidth) end
    for _, icon in ipairs(pool) do icon.bar:SetWidth(db.barWidth) end
end

-- En el estilo del juego el relleno no se tinta (el color viene del atlas)
local function ApplyBarColor()
    local r, g, b = 1, 1, 1
    if not BlizzStyleActive() then r, g, b = db.barColorR, db.barColorG, db.barColorB end
    for _, icon in pairs(icons) do icon.bar:SetStatusBarColor(r, g, b) end
    for _, icon in ipairs(pool) do icon.bar:SetStatusBarColor(r, g, b) end
end

-- Cambia entre el estilo del juego y la barra lisa; barAnchor toma la altura
-- de la barra para que el fondo de arrastre siga marcando su hueco.
local function ApplyBarStyle()
    barAnchor:SetHeight(BlizzStyleActive() and BLIZZ_HEIGHT or PLAIN_HEIGHT)
    for _, icon in pairs(icons) do StyleBar(icon.bar) end
    for _, icon in ipairs(pool) do StyleBar(icon.bar) end
end

-- El icono (textura + swipe circular) y la barra se pueden apagar cada uno
-- por su lado. La barra solo vuelve a aparecer si ademas hay tiempo que
-- mostrar (icon.barStart): eso ya lo decide SyncBar, aqui solo se respeta.
local function ApplyVisibility()
    for _, icon in pairs(icons) do
        icon.texture:SetShown(db.showIcon)
        icon.cooldown:SetShown(db.showIcon)
        icon.bar:SetShown(db.showBar and icon.barStart ~= nil)
    end
    for _, icon in ipairs(pool) do
        icon.texture:SetShown(db.showIcon)
        icon.cooldown:SetShown(db.showIcon)
    end
end

local function CreateAnchor()
    anchor = CreateFrame("Frame", "SealTimersForeverAnchor", UIParent)
    anchor:SetSize(ICON_SIZE, ICON_SIZE)
    anchor:SetPoint(db.point, UIParent, db.point, db.x, db.y)
    anchor:SetMovable(true)
    anchor:SetClampedToScreen(true)
    anchor:RegisterForDrag("LeftButton")
    anchor:SetScript("OnDragStart", anchor.StartMoving)
    anchor:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        db.point, db.x, db.y = point, x, y
    end)

    -- Solo se ven desbloqueado: marcan donde va el bloque aunque no haya sellos
    anchor.bg = anchor:CreateTexture(nil, "BACKGROUND")
    anchor.bg:SetAllPoints()
    anchor.bg:SetColorTexture(0.84, 0.59, 1, 0.35)
    anchor.label = anchor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    anchor.label:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 2)
    anchor.label:SetText(BRAND .. L.TITLE .. "|r - " .. L.DRAG_HINT)
    anchor:SetScript("OnUpdate", UpdateBars)
end

-- Bloque de la barra, independiente del de los iconos: se arrastra y se
-- guarda por separado (db.barPoint/barX/barY), igual que CreateAnchor.
local function CreateBarAnchor()
    barAnchor = CreateFrame("Frame", "SealTimersForeverBarAnchor", UIParent)
    barAnchor:SetSize(db.barWidth, 8)
    barAnchor:SetPoint(db.barPoint, UIParent, db.barPoint, db.barX, db.barY)
    barAnchor:SetMovable(true)
    barAnchor:SetClampedToScreen(true)
    barAnchor:RegisterForDrag("LeftButton")
    barAnchor:SetScript("OnDragStart", barAnchor.StartMoving)
    barAnchor:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        db.barPoint, db.barX, db.barY = point, x, y
    end)

    barAnchor.bg = barAnchor:CreateTexture(nil, "BACKGROUND")
    barAnchor.bg:SetAllPoints()
    barAnchor.bg:SetColorTexture(0.84, 0.59, 1, 0.35)
    barAnchor.label = barAnchor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    barAnchor.label:SetPoint("BOTTOMLEFT", barAnchor, "TOPLEFT", 0, 2)
    barAnchor.label:SetText(BRAND .. L.TITLE .. "|r - " .. L.DRAG_HINT)
end

--------------------------------------------------
-- OPCIONES
--------------------------------------------------
local function Check()
    print(BRAND .. "Seal Timers Forever|r: " .. L.CHECK_HEADER)
    local any = false
    for spellID, name in pairs(knownSeals) do
        any = true
        if C_Secrets.ShouldUnitSpellCastBeSecret("player", spellID) then
            print("  " .. L.CHECK_CAST_SECRET:format(name))
        elseif C_Secrets.ShouldSpellAuraBeSecret(spellID) then
            local seen = db.durations[name]
            print("  " .. L.CHECK_SECRET:format(name, seen and (seen .. " s") or L.NOT_SEEN))
        else
            print("  " .. L.CHECK_OPEN:format(name))
        end
    end
    if not any then print("  " .. L.CHECK_NONE) end
    print("  " .. (AtlasesAvailable() and L.CHECK_BLIZZ_OK or L.CHECK_BLIZZ_MISSING))
end

-- Abre el selector de color de Blizzard para el color de la barra. Hay dos
-- APIs segun el cliente: la nueva (SetupColorPickerAndShow, Dragonflight+) y
-- la vieja (func/cancelFunc/SetColorRGB a mano). Forever comparte API con
-- retail, pero se comprueba por si acaso en vez de asumir.
local function OpenColorPicker()
    local startR, startG, startB = db.barColorR, db.barColorG, db.barColorB
    local function OnColorChanged()
        db.barColorR, db.barColorG, db.barColorB = ColorPickerFrame:GetColorRGB()
        ApplyBarColor()
    end
    local function OnCancel(previousValues)
        db.barColorR = previousValues and previousValues.r or startR
        db.barColorG = previousValues and previousValues.g or startG
        db.barColorB = previousValues and previousValues.b or startB
        ApplyBarColor()
    end
    if ColorPickerFrame.SetupColorPickerAndShow then
        ColorPickerFrame:SetupColorPickerAndShow({
            swatchFunc = OnColorChanged,
            cancelFunc = OnCancel,
            hasOpacity = false,
            r = startR, g = startG, b = startB,
        })
    else
        ColorPickerFrame.func = OnColorChanged
        ColorPickerFrame.cancelFunc = OnCancel
        ColorPickerFrame.hasOpacity = false
        ColorPickerFrame:SetColorRGB(startR, startG, startB)
        ColorPickerFrame:Hide()
        ColorPickerFrame:Show()
    end
end

local function CreateOptions()
    -- En morado tambien en Opciones > AddOns, como en la lista de addons
    local category = Settings.RegisterVerticalLayoutCategory(BRAND .. "Seal Timers Forever|r")

    local lock = Settings.RegisterAddOnSetting(category, "SealTimersForever_Locked", "locked",
        db, Settings.VarType.Boolean, L.LOCK, DEFAULTS.locked)
    lock:SetValueChangedCallback(ApplyLock)
    Settings.CreateCheckbox(category, lock, L.LOCK_TOOLTIP)

    local showIcon = Settings.RegisterAddOnSetting(category, "SealTimersForever_ShowIcon", "showIcon",
        db, Settings.VarType.Boolean, L.SHOW_ICON, DEFAULTS.showIcon)
    showIcon:SetValueChangedCallback(ApplyVisibility)
    Settings.CreateCheckbox(category, showIcon, L.SHOW_ICON_TOOLTIP)

    local showBar = Settings.RegisterAddOnSetting(category, "SealTimersForever_ShowBar", "showBar",
        db, Settings.VarType.Boolean, L.SHOW_BAR, DEFAULTS.showBar)
    showBar:SetValueChangedCallback(ApplyVisibility)
    Settings.CreateCheckbox(category, showBar, L.SHOW_BAR_TOOLTIP)

    local blizzStyle = Settings.RegisterAddOnSetting(category, "SealTimersForever_BlizzStyle", "blizzStyle",
        db, Settings.VarType.Boolean, L.BLIZZ_STYLE, DEFAULTS.blizzStyle)
    blizzStyle:SetValueChangedCallback(ApplyBarStyle)
    Settings.CreateCheckbox(category, blizzStyle, L.BLIZZ_STYLE_TOOLTIP)

    local scale = Settings.RegisterAddOnSetting(category, "SealTimersForever_Scale", "scale",
        db, Settings.VarType.Number, L.SIZE, DEFAULTS.scale)
    scale:SetValueChangedCallback(ApplyScale)
    local options = Settings.CreateSliderOptions(0.5, 3, 0.1)
    options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
        return string.format("%d%%", math.floor(value * 100 + 0.5))
    end)
    Settings.CreateSlider(category, scale, options, L.SIZE_TOOLTIP)

    local barWidth = Settings.RegisterAddOnSetting(category, "SealTimersForever_BarWidth", "barWidth",
        db, Settings.VarType.Number, L.BAR_WIDTH, DEFAULTS.barWidth)
    barWidth:SetValueChangedCallback(ApplyBarWidth)
    local widthOptions = Settings.CreateSliderOptions(20, 400, 10)
    widthOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
        return string.format("%dpx", math.floor(value + 0.5))
    end)
    Settings.CreateSlider(category, barWidth, widthOptions, L.BAR_WIDTH_TOOLTIP)

    Settings.RegisterAddOnCategory(category)

    SLASH_SEALTIMERSFOREVER1 = "/stf"
    SlashCmdList.SEALTIMERSFOREVER = function(msg)
        local command = (msg or ""):lower():match("^%s*(%S*)")
        if command == "check" then return Check() end
        if command == "color" then return OpenColorPicker() end
        if command == "debug" then
            debugMode = not debugMode
            print(BRAND .. "Seal Timers Forever|r: " .. (debugMode and L.DEBUG_ON or L.DEBUG_OFF))
            return
        end
        if command == "reset" then
            wipe(db.durations)
            print(BRAND .. "Seal Timers Forever|r: " .. L.RESET_DONE)
            return
        end
        Settings.OpenToCategory(category:GetID())
    end
end

--------------------------------------------------
-- ARRANQUE
--------------------------------------------------
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event, arg1, arg2, arg3)
    if event == "PLAYER_LOGIN" then
        -- Solo tiene sentido para paladines: en el resto no se crea nada.
        if select(2, UnitClass("player")) ~= "PALADIN" then
            self:UnregisterAllEvents()
            return
        end
        SealTimersForeverDB = SealTimersForeverDB or {}
        db = SealTimersForeverDB
        for key, value in pairs(DEFAULTS) do
            if db[key] == nil then db[key] = value end
        end
        if db.durationsVersion ~= DURATIONS_VERSION then
            db.durations, db.durationsVersion = {}, DURATIONS_VERSION
        end
        BuildSealNames()
        ScanSpellBook()
        CreateAnchor()
        CreateBarAnchor()
        ApplyLock()
        ApplyScale()
        ApplyBarWidth()
        ApplyBarStyle()
        ApplyBarColor()
        ApplyVisibility()
        CreateOptions()
        self:RegisterUnitEvent("UNIT_AURA", "player")
        self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        self:RegisterEvent("SPELLS_CHANGED")
        FullScan()
    elseif event == "UNIT_AURA" then
        OnUnitAura(arg2)
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        OnSealCast(arg3)
    elseif event == "PLAYER_REGEN_ENABLED" then
        FullScan()
    elseif event == "SPELLS_CHANGED" then
        ScanSpellBook()
    end
end)
