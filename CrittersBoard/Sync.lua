CrittersBoard = CrittersBoard or {}
local CB = CrittersBoard

CB.PREFIX = "CB_CRIT"
CB.Sync = CB.Sync or {}
local SYNC = CB.Sync

-- Statistik-Variablen für den Bericht
SYNC.lastSyncRequestAt = SYNC.lastSyncRequestAt or 0
SYNC.rxCount = 0      -- Empfangene Rekorde
SYNC.newCount = 0     -- Tatsächlich neue (hinzugefügte) Rekorde
SYNC.knownSenders = {} -- Wer hat geantwortet?

-- =========================================================
-- HILFSFUNKTION: Sync-Abschlussbericht
-- =========================================================
local function FinishSync()
    if not SYNC.isSyncActive then return end
    SYNC.isSyncActive = false

    local senderCount = 0
    for _ in pairs(SYNC.knownSenders) do senderCount = senderCount + 1 end

    -- Die gelbe Meldung in der Bildschirmmitte (wie in v0.4)
    local msg = string.format("GildenSync abgeschlossen: %d Spieler | %d neue Rekorde", senderCount, SYNC.newCount)
    RaidNotice_AddMessage(RaidWarningFrame, "|cffffff00" .. msg .. "|r", ChatTypeInfo["RAID_WARNING"])
    
    -- Sound abspielen
    PlaySoundFile("Interface\\AddOns\\CrittersBoard\\sounds\\sync.ogg", "Master")
    
    -- Chat-Zusammenfassung
    CB:Print(msg)
end

-- Timer für das Ende (startet neu, sobald Daten reinkommen)
local function ArmSyncFinished()
    if SYNC.finishTimer then SYNC.finishTimer:Cancel() end
    SYNC.finishTimer = C_Timer.NewTimer(3, FinishSync) -- 3 Sek. nach dem letzten Paket ist Ende
end

-- =========================================================
-- SEND ENGINE (v0.5 Format)
-- =========================================================
function CB:SendEvent(kind, rec)
    if not CB.DB or (CB.DB.ui and CB.DB.ui.disableSync) then return end
    if not rec then return end

    -- Format v0.5: kind|version|player|spell|amount|ts|isCrit|class|spellId|mapID|x|y
    local payload = string.format("%s|%d|%s|%s|%d|%d|%d|%s|%d|%d|%.1f|%.1f",
        kind,
        CB.REQUIRED_DB_VERSION or 1,
        CB:SafeStr(rec.player or "Unknown"),
        CB:SafeStr(rec.spell or "Unknown"),
        rec.amount or 0,
        rec.ts or 0,
        rec.isCrit and 1 or 0,
        CB:SafeStr(rec.classFile or "UNKNOWN"),
        rec.spellId or 0,
        rec.mapID or 0,
        rec.coordX or 0,
        rec.coordY or 0
    )

    if IsInGuild() then
        ChatThrottleLib:SendAddonMessage("NORMAL", CB.PREFIX, payload, "GUILD")
    end
end

-- =========================================================
-- EMPFANGS ENGINE (Mit v0.5 Sicherheits-Check)
-- =========================================================
local function OnAddonMessage(prefix, text, channel, sender)
    if prefix ~= CB.PREFIX or sender == UnitName("player") then return end

    local parts = {}
    for v in string.gmatch(text, "([^|]+)") do table.insert(parts, v) end
    local kind = parts[1]

    -- A) SNAP_REQ: Andere fragen uns
    if kind == "SNAP_REQ" then
        if CB.DB then
            for _, r in ipairs(CB.DB.damage.records or {}) do CB:SendEvent("D", r) end
            for _, r in ipairs(CB.DB.heal.records or {}) do CB:SendEvent("H", r) end
            for _, r in ipairs(CB.DB.overkill.records or {}) do CB:SendEvent("O", r) end
            for _, r in ipairs(CB.DB.spells.records or {}) do CB:SendEvent("S", r) end
            for _, r in ipairs(CB.DB.healSpells.records or {}) do CB:SendEvent("HS", r) end
        end
        return
    end

    -- B) DATEN-PAKET: Versionsprüfung (Sicherheit v0.5)
    local incomingVersion = tonumber(parts[2])
    if incomingVersion ~= CB.REQUIRED_DB_VERSION then return end

    -- Wenn wir hier sind, läuft ein Sync
    if SYNC.isSyncActive then
        SYNC.knownSenders[sender] = true
        ArmSyncFinished() -- Timer verlängern
    end

    -- Daten auslesen (v0.5 Mapping)
    local player, spell = parts[3], parts[4]
    local amount, ts = tonumber(parts[5]) or 0, tonumber(parts[6]) or 0
    local isCrit, classFile = (parts[7] == "1"), parts[8]
    local spellId, mapID = tonumber(parts[9]) or 0, tonumber(parts[10]) or 0
    local x, y = tonumber(parts[11]) or 0, tonumber(parts[12]) or 0

    local tbl = (kind == "D" and CB.DB.damage) or (kind == "H" and CB.DB.heal) or 
                (kind == "O" and CB.DB.overkill) or (kind == "S" and CB.DB.spells) or 
                (kind == "HS" and CB.DB.healSpells)
    
    if not tbl then return end

    local added, newRec = false, nil
    if kind == "D" or kind == "H" or kind == "O" then
        added, newRec = CB:AddRecord(tbl, player, spell, amount, ts, isCrit, classFile, "guild", kind)
    elseif kind == "S" then
        added, newRec = CB:AddSpellBest(player, spell, amount, ts, isCrit, classFile, "guild")
    elseif kind == "HS" then
        added, newRec = CB:AddHealSpellBest(player, spell, amount, ts, isCrit, classFile, "guild")
    end

    if added then
        SYNC.newCount = SYNC.newCount + 1
        if newRec then
            newRec.spellId, newRec.mapID, newRec.coordX, newRec.coordY = spellId, mapID, x, y
        end
        if CB.UI and CB.UI.Refresh then CB.UI:Refresh() end
    end
end

-- =========================================================
-- START-FUNKTION
-- =========================================================
function CB:RequestSnapshot(manual)
    if not IsInGuild() or (CB.DB.ui and CB.DB.ui.disableSync) then return end

    local now = time()
    if not manual and (now - SYNC.lastSyncRequestAt < 300) then return end
    
    -- Sync-Status initialisieren
    SYNC.lastSyncRequestAt = now
    SYNC.isSyncActive = true
    SYNC.newCount = 0
    SYNC.knownSenders = {}
    
    CB:Print(CB.L["MSG_SYNC_START"] or "Synchronisierung gestartet...")
    ChatThrottleLib:SendAddonMessage("NORMAL", CB.PREFIX, "SNAP_REQ", "GUILD")
    
    -- Falls niemand antwortet, nach 10 Sek trotzdem Bericht zeigen
    C_Timer.After(10, function()
        if SYNC.isSyncActive and SYNC.newCount == 0 then FinishSync() end
    end)
end

-- Event Register
local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_ADDON")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function(_, event, prefix, text, channel, sender)
    if event == "PLAYER_ENTERING_WORLD" then
        C_ChatInfo.RegisterAddonMessagePrefix(CB.PREFIX)
    elseif event == "CHAT_MSG_ADDON" and prefix == CB.PREFIX then
        OnAddonMessage(prefix, text, channel, sender)
    end
end)