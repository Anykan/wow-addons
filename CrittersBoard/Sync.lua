CrittersBoard = CrittersBoard or {}
local CB = CrittersBoard

CB.Sync = CB.Sync or {}
local SYNC = CB.Sync

-- =========================================================
-- STATE
-- =========================================================
SYNC.lastSyncRequestAt = SYNC.lastSyncRequestAt or 0
SYNC.newCount          = 0
SYNC.knownSenders      = {}
SYNC.isSyncActive      = false

-- Coordinator-Sync
SYNC.coordinator       = nil    -- Name des aktuellen Coordinators
SYNC.isCoordinator     = false  -- Bin ich der Coordinator?
SYNC.sessionStart      = 0      -- GetTime() beim PLAYER_LOGIN
SYNC.electionBids      = {}     -- Gesammelte Bids während der Wahl
SYNC.electionTimer     = nil    -- Timer für Bid-Sammlung / Coordinator-Timeout
SYNC.isSending         = false  -- Coordinator sendet gerade (SNAP_BUSY Schutz)
SYNC.awaitingSync      = false  -- Wir erwarten einen Snapshot (für Race-Condition-Fix)

local MAX_PAYLOAD = 220
local vToken = "V:" .. (CB.PROTOCOL_VERSION or 1)

-- Realm-Suffix aus Spielernamen entfernen ("Kuhmpresse-Lakeshire" → "Kuhmpresse")
local function ShortName(name)
    if not name then return "" end
    return name:match("^([^%-]+)") or name
end

-- Klassen-Kodierung: spart bis zu 8 Zeichen pro Datensatz
local classEncode = {
    WARRIOR=1, PALADIN=2, HUNTER=3, ROGUE=4, PRIEST=5,
    SHAMAN=6, MAGE=7, WARLOCK=8, DRUID=9,
}
local classDecode = {
    [1]="WARRIOR",[2]="PALADIN",[3]="HUNTER",[4]="ROGUE",[5]="PRIEST",
    [6]="SHAMAN",[7]="MAGE",[8]="WARLOCK",[9]="DRUID",
}

-- =========================================================
-- HILFSFUNKTIONEN FÜR CHUNKS
-- =========================================================
-- Felder: player,classCode,amount,ts,isCrit,destName,spellId,mapID,coordX,coordY
-- Zaubername entfällt — wird per GetSpellInfo(spellId) rekonstruiert
local function EncodeRecord(rec)
    local crit = rec.isCrit and "1" or "0"
    local classCode = classEncode[rec.classFile or ""] or 0
    return table.concat({
        CB:SafeStr(rec.player or "Unknown"),
        tostring(classCode),
        tostring(rec.amount or 0),
        tostring(rec.ts or time()),
        crit,
        CB:SafeStr(rec.destName or "Unbekannt"),
        tostring(rec.spellId or 0),
        tostring(rec.mapID or 0),
        tostring(rec.coordX or 0),
        tostring(rec.coordY or 0),
    }, ",")
end

local function GetTableByKind(kind)
    if kind == "D"  then return CB.DB.damage end
    if kind == "H"  then return CB.DB.heal end
    if kind == "O"  then return CB.DB.overkill end
    if kind == "S"  then return CB.DB.spells end
    if kind == "HS" then return CB.DB.healSpells end
    if kind == "DT" then return CB.DB.damageTaken end
    return nil
end

local function MakeChunks(kind)
    local tbl = GetTableByKind(kind)
    if not tbl or not tbl.records then return {} end

    local chunks  = {}
    local current = ""

    for i = 1, #tbl.records do
        local line = EncodeRecord(tbl.records[i])
        local add  = (current == "") and line or (";" .. line)

        if (#current + #add) > (MAX_PAYLOAD - 40) then
            table.insert(chunks, current)
            current = line
        else
            current = current .. add
        end
    end

    if current ~= "" then table.insert(chunks, current) end
    return chunks
end

-- =========================================================
-- COORDINATOR: VOLLSTÄNDIGEN SNAPSHOT SENDEN
-- =========================================================
local function SendSnapshot()
    if not CB.DB then return end
    if CB.NewerVersionWarned then return end
    SYNC.isSending = true

    local types       = {"D", "H", "O", "S", "HS", "DT"}
    local totalChunks = 0

    for _, t in ipairs(types) do
        local chunks = MakeChunks(t)
        totalChunks  = totalChunks + #chunks
        for _, payload in ipairs(chunks) do
            ChatThrottleLib:SendAddonMessage("BULK", CB.PREFIX,
                "CHUNK|" .. vToken .. "|" .. t .. "|" .. payload, "GUILD")
        end
    end

    -- SNAP_DONE als BULK → landet nach allen Chunks in der Queue
    ChatThrottleLib:SendAddonMessage("BULK", CB.PREFIX, "SNAP_DONE|" .. vToken, "GUILD")

    -- isSending nach geschätzter Sendezeit freigeben (1s/Chunk + 5s Puffer)
    -- FIX 3: Coordinator beendet Sync nach dem Senden (inkl. Delta-Push-Fenster)
    C_Timer.After(totalChunks + 5, function()
        SYNC.isSending = false
        FinishSync()  -- Coordinator resettet isSyncActive und gibt Alerts frei
    end)
end

-- =========================================================
-- COORDINATOR-WAHL AUSWERTEN (läuft bei ALLEN nach 3s)
-- Determinismus: alle haben die gleichen Bids → alle bestimmen den gleichen Gewinner
-- Nur der Gewinner sendet ELECT_WIN + Snapshot
-- =========================================================
local function DetermineCoordinator()
    SYNC.electionTimer = nil
    if CB.NewerVersionWarned then return end
    local myName   = UnitName("player")
    local bestName = myName
    local bestTime = SYNC.electionBids[myName] or 0

    -- Bids auswerten
    if CB.DEBUG_MODE then
        CB:Print("|cffffff00DEBUG Wahl:|r Auswertung startet. Eigene Bids gesammelt:")
        for name, t in pairs(SYNC.electionBids) do
            CB:Print("  • " .. name .. " (Session: " .. t .. "s)")
        end
    end

    for name, sessionTime in pairs(SYNC.electionBids) do
        if sessionTime > bestTime or (sessionTime == bestTime and name < bestName) then
            bestTime = sessionTime
            bestName = name
        end
    end

    SYNC.coordinator   = bestName
    SYNC.isCoordinator = (bestName == myName)

    -- Andere Teilnehmer zählen (nur echte — nicht eigener Name)
    local otherBids = 0
    local otherNames = {}
    for name, _ in pairs(SYNC.electionBids) do
        if name ~= myName then
            otherBids = otherBids + 1
            table.insert(otherNames, name)
        end
    end

    if CB.DEBUG_MODE then
        if otherBids == 0 then
            CB:Print("|cffffff00DEBUG Wahl:|r Keine anderen Spieler online.")
        else
            CB:Print("|cffffff00DEBUG Wahl:|r Andere Teilnehmer: " .. table.concat(otherNames, ", "))
        end

        if SYNC.isCoordinator then
            CB:Print("|cffffff00DEBUG Wahl:|r Ergebnis: ICH bin Coordinator (" .. myName .. ")")
        else
            CB:Print("|cffffff00DEBUG Wahl:|r Ergebnis: Coordinator ist " .. tostring(bestName))
        end
    end

    if SYNC.isCoordinator then
        CB:Print(CB.L["MSG_I_AM_COORDINATOR"] or "Du bist der Coordinator.")
        if otherBids > 0 then
            if CB.DEBUG_MODE then
                CB:Print("|cffffff00DEBUG Wahl:|r Sende ELECT_WIN + Snapshot an " .. otherBids .. " Spieler.")
            end
            SYNC.awaitingSync = false  -- Coordinator sendet selbst, erwartet keinen Snapshot
            ChatThrottleLib:SendAddonMessage("NORMAL", CB.PREFIX,
                "ELECT_WIN|" .. vToken .. "|" .. myName, "GUILD")
            SendSnapshot()
        else
            CB:Print(CB.L["MSG_NO_PLAYERS_ONLINE"] or "Keine anderen Spieler online — Sync pausiert.")
            SYNC.awaitingSync = false  -- Alleine, kein Snapshot erwartet
            SYNC.isSyncActive = false  -- FIX 1: Alleine online → kein Sync aktiv, Alerts freigeben
            if CB.DEBUG_MODE then
                CB:Print("|cffffff00DEBUG Wahl:|r Alleine online — kein Snapshot gesendet. isSyncActive → false")
            end
        end
    end
    -- Verlierer: warten auf ELECT_WIN und Chunks vom Gewinner
end

-- =========================================================
-- SYNC-ABSCHLUSSBERICHT (ausgelöst durch SNAP_DONE)
-- =========================================================
local function FinishSync()
    if not SYNC.isSyncActive then return end
    SYNC.isSyncActive  = false
    SYNC.awaitingSync  = false

    local senderCount = 0
    for _ in pairs(SYNC.knownSenders) do senderCount = senderCount + 1 end

    local msg = string.format("GildenSync abgeschlossen: %d Spieler | %d neue Rekorde", senderCount, SYNC.newCount)
    if RaidNotice_AddMessage and RaidWarningFrame then
        RaidNotice_AddMessage(RaidWarningFrame, "|cffffff00" .. msg .. "|r", ChatTypeInfo["RAID_WARNING"])
    end
    PlaySoundFile("Interface\\AddOns\\CrittersBoard\\sounds\\sync.ogg", "Master")
    CB:Print(msg)

    -- Delta-Push: eigene Records zurück an die Gilde senden
    -- Nur wenn wir NICHT Coordinator sind — Coordinator hat bereits einen vollen Snapshot gesendet
    if SYNC.isCoordinator then
        if CB.DEBUG_MODE then CB:Print("|cffffff00DEBUG Delta-Push:|r Übersprungen — ich bin Coordinator.") end
        return
    end
    if IsInGuild() and not CB.NewerVersionWarned then
        local myName = UnitName("player")
        local kinds = {"D", "H", "O", "DT", "S", "HS"}
        local sentCount = 0
        for _, kind in ipairs(kinds) do
            local tbl = GetTableByKind(kind)
            if tbl and tbl.records then
                for _, rec in ipairs(tbl.records) do
                    if rec.player == myName then
                        CB:SendEvent(kind, rec)
                        sentCount = sentCount + 1
                    end
                end
            end
        end
        if CB.DEBUG_MODE then
            CB:Print("|cffffff00DEBUG Delta-Push:|r " .. sentCount .. " eigene Records zurückgesendet.")
        end
    end
end

-- =========================================================
-- SEND ENGINE (Echtzeit-EVT bei neuem Rekord)
-- =========================================================
function CB:SendEvent(kind, rec, priority)
    if not CB.DB then return end
    if CB.NewerVersionWarned then return end
    if not rec then return end

    local prio    = priority or "NORMAL"
    local payload = string.format("EVT|%s|%s|%s", vToken, kind, EncodeRecord(rec))

    if IsInGuild() then
        ChatThrottleLib:SendAddonMessage(prio, CB.PREFIX, payload, "GUILD")
    end
end

-- =========================================================
-- EMPFANGS ENGINE
-- =========================================================
local function OnAddonMessage(prefix, text, channel, sender)
    if prefix ~= CB.PREFIX or sender == UnitName("player") then return end

    local parts = {}
    for v in string.gmatch(text, "([^|]+)") do table.insert(parts, v) end
    local cmd    = parts[1]
    local myName = UnitName("player")

    -- -------------------------------------------------------
    -- ELECT_REQ: Spieler kommt online / startet Coordinator-Wahl
    -- Format: ELECT_REQ|vToken|sessionTime
    -- -------------------------------------------------------
    if cmd == "ELECT_REQ" then
        if CB.NewerVersionWarned then return end
        local reqToken   = parts[2]
        local reqSessTime = tonumber(parts[3]) or 0
        if reqToken ~= vToken then return end  -- Falsche Version ignorieren

        if CB.DEBUG_MODE then
            CB:Print("|cffffff00DEBUG Wahl:|r ELECT_REQ von '" .. sender .. "' (Session: " .. reqSessTime .. "s) | Ich bin Coordinator: " .. tostring(SYNC.isCoordinator))
        end

        if SYNC.isCoordinator then
            -- Ich bin Coordinator → sofort antworten + Daten senden
            if CB.DEBUG_MODE then
                CB:Print("|cffffff00DEBUG Wahl:|r Ich bin Coordinator → sende ELECT_WIN + Snapshot an " .. sender)
            end
            ChatThrottleLib:SendAddonMessage("NORMAL", CB.PREFIX,
                "ELECT_WIN|" .. vToken .. "|" .. myName, "GUILD")
            if SYNC.isSending then
                ChatThrottleLib:SendAddonMessage("NORMAL", CB.PREFIX, "SNAP_BUSY|" .. vToken, "GUILD")
            else
                SendSnapshot()
            end

        elseif SYNC.coordinator then
            if sender == SYNC.coordinator then
                -- Coordinator hat sich neu eingeloggt (ELECT_LOST evtl. nicht empfangen)
                -- Coordinator-Info löschen und an der neuen Wahl teilnehmen
                if CB.DEBUG_MODE then
                    CB:Print("|cffffff00DEBUG Wahl:|r Bekannter Coordinator '" .. sender .. "' hat sich neu eingeloggt — nehme an neuer Wahl teil.")
                end
                SYNC.coordinator   = nil
                SYNC.isCoordinator = false
                SYNC.electionBids[sender] = reqSessTime
                local mySessionTime = math.floor(GetTime() - SYNC.sessionStart)
                SYNC.electionBids[myName] = mySessionTime
                ChatThrottleLib:SendAddonMessage("NORMAL", CB.PREFIX,
                    string.format("ELECT_BID|%s|%s|%d", vToken, myName, mySessionTime), "GUILD")
                if not SYNC.electionTimer then
                    SYNC.electionTimer = C_Timer.NewTimer(3, function()
                        DetermineCoordinator()
                    end)
                end
            else
                -- Ich kenne den Coordinator, bin es aber nicht → still (er antwortet)
                if CB.DEBUG_MODE then
                    CB:Print("|cffffff00DEBUG Wahl:|r Coordinator bekannt (" .. SYNC.coordinator .. ") — warte auf seine Antwort.")
                end
            end

        else
            -- Kein Coordinator bekannt → an der Wahl teilnehmen
            -- Requester-Bid aus der ELECT_REQ Nachricht übernehmen
            SYNC.electionBids[sender] = reqSessTime

            -- Eigenes Bid senden
            local mySessionTime = math.floor(GetTime() - SYNC.sessionStart)
            SYNC.electionBids[myName] = mySessionTime
            if CB.DEBUG_MODE then
                CB:Print("|cffffff00DEBUG Wahl:|r Nehme an Wahl teil. Sende Bid: " .. myName .. " (" .. mySessionTime .. "s)")
            end
            ChatThrottleLib:SendAddonMessage("NORMAL", CB.PREFIX,
                string.format("ELECT_BID|%s|%s|%d", vToken, myName, mySessionTime), "GUILD")

            -- Lokalen DetermineCoordinator-Timer starten (falls noch keiner läuft)
            if not SYNC.electionTimer then
                SYNC.electionTimer = C_Timer.NewTimer(3, function()
                    DetermineCoordinator()
                end)
            end
        end
        return
    end

    -- -------------------------------------------------------
    -- Versions-Check für alle weiteren Nachrichten
    -- -------------------------------------------------------
    local receivedToken = parts[2]
    if receivedToken ~= vToken then
        local receivedVersion = tonumber(string.match(receivedToken or "", "V:(%d+)"))
        local ownVersion      = CB.PROTOCOL_VERSION or 1
        if receivedVersion and receivedVersion > ownVersion and not CB.NewerVersionWarned then
            CB:Print(CB.L["UPDATE_AVAILABLE"] or "|cffff9900Update verfügbar:|r Bitte aktualisieren!")
            CB.NewerVersionWarned = true
            -- Sync sofort stoppen: Coordinator-Rolle abgeben, laufende Wahl abbrechen
            SYNC.isCoordinator = false
            SYNC.coordinator   = nil
            if SYNC.electionTimer then SYNC.electionTimer:Cancel() SYNC.electionTimer = nil end
        end
        if CB.DEBUG_MODE then print("Ignoriere Nachricht mit falscher Version: " .. tostring(receivedToken)) end
        return
    end

    -- -------------------------------------------------------
    -- ELECT_BID: Bid für Coordinator-Wahl empfangen
    -- Format: ELECT_BID|vToken|name|sessionTime
    -- -------------------------------------------------------
    if cmd == "ELECT_BID" then
        local bidName = parts[3]
        local bidTime = tonumber(parts[4]) or 0
        if bidName then SYNC.electionBids[bidName] = bidTime end
        return
    end

    -- -------------------------------------------------------
    -- ELECT_WIN: Coordinator steht fest
    -- Format: ELECT_WIN|vToken|winnerName
    -- -------------------------------------------------------
    if cmd == "ELECT_WIN" then
        local winnerName = parts[3]
        -- Laufenden Wahl-Timer stoppen (Coordinator hat geantwortet)
        if SYNC.electionTimer then SYNC.electionTimer:Cancel() SYNC.electionTimer = nil end
        -- FIX 2: "Coordinator: X" nur anzeigen wenn sich der Coordinator geändert hat
        local coordinatorChanged = (SYNC.coordinator ~= winnerName)
        SYNC.coordinator   = winnerName
        SYNC.isCoordinator = (winnerName == myName)
        if not SYNC.isCoordinator then
            -- Race-Condition-Fix: isSyncActive wiederherstellen falls DetermineCoordinator
            -- es bereits zurückgesetzt hat, bevor ELECT_WIN ankam
            if SYNC.awaitingSync and not SYNC.isSyncActive then
                SYNC.isSyncActive = true
                if CB.DEBUG_MODE then
                    CB:Print("|cffffff00DEBUG Wahl:|r Race-Condition erkannt — isSyncActive wiederhergestellt für SNAP_DONE.")
                end
            end
            if coordinatorChanged then
                CB:Print(string.format(CB.L["MSG_COORDINATOR_IS"] or "Coordinator: %s", winnerName))
            end
        end
        if CB.DEBUG_MODE then
            CB:Print("|cffffff00DEBUG Coordinator:|r ELECT_WIN empfangen — Coordinator: " .. tostring(winnerName) .. (coordinatorChanged and " (neu)" or " (unverändert)"))
        end
        return
    end

    -- -------------------------------------------------------
    -- ELECT_LOST: Coordinator hat die Gilde verlassen
    -- Format: ELECT_LOST|vToken|coordinatorName
    -- -------------------------------------------------------
    if cmd == "ELECT_LOST" then
        local lostName = parts[3]
        if lostName == SYNC.coordinator then
            SYNC.coordinator   = nil
            SYNC.isCoordinator = false
            -- FIX 4: Neue Wahl starten, da Coordinator nicht mehr online
            C_Timer.After(1, function()
                CB:RequestSnapshot(true)
            end)
        end
        return
    end

    -- -------------------------------------------------------
    -- SNAP_BUSY: Coordinator sendet gerade, bitte warten
    -- -------------------------------------------------------
    if cmd == "SNAP_BUSY" then
        -- FIX 5: 15s warten, dann über RequestSnapshot erneut versuchen (mit Cooldown-Bypass)
        C_Timer.After(15, function()
            CB:RequestSnapshot(true)
        end)
        return
    end

    -- -------------------------------------------------------
    -- SNAP_DONE: Coordinator hat alle Daten gesendet
    -- -------------------------------------------------------
    if cmd == "SNAP_DONE" then
        SYNC.knownSenders[sender] = true
        FinishSync()
        return
    end

    -- -------------------------------------------------------
    -- CHUNK / EVT: Datenpakete verarbeiten
    -- -------------------------------------------------------
    local listKind, payload
    if cmd == "CHUNK" then
        listKind = parts[3]
        payload  = parts[4]
    elseif cmd == "EVT" then
        listKind = parts[3]
        payload  = parts[4]
    else
        return
    end

    if SYNC.isSyncActive then
        SYNC.knownSenders[sender] = true
    end

    local tbl = GetTableByKind(listKind)
    if not tbl then
        if not CB.UpdateWarned then
            CB:Print(string.format(CB.L["UPDATE_NEEDED"], tostring(listKind)))
            CB.UpdateWarned = true
        end
        return
    end

    -- Datensätze dekodieren und eintragen
    for recStr in string.gmatch(payload, "([^;]+)") do
        local r = {}
        for p in string.gmatch(recStr, "([^,]+)") do table.insert(r, p) end

        if #r >= 10 then
            local pName    = r[1]
            local pClass   = classDecode[tonumber(r[2]) or 0] or "UNKNOWN"
            local pAmount  = tonumber(r[3]) or 0
            local pTS      = tonumber(r[4]) or 0
            local pCrit    = (r[5] == "1")
            local pDest    = r[6] or "Unbekannt"
            local pSpellId = tonumber(r[7]) or 0
            local pMapID   = tonumber(r[8]) or 0
            local pCoordX  = tonumber(r[9]) or 0
            local pCoordY  = tonumber(r[10]) or 0
            local pSpell   = (pSpellId > 0) and (GetSpellInfo(pSpellId) or tostring(pSpellId)) or "Unknown"

            local added, newRec = false, nil

            if listKind == "S" then
                added, newRec = CB:AddSpellBest(pName, pSpell, pAmount, pTS, pCrit, pClass, "guild", pDest, pSpellId, pMapID, pCoordX, pCoordY)
            elseif listKind == "HS" then
                added, newRec = CB:AddHealSpellBest(pName, pSpell, pAmount, pTS, pCrit, pClass, "guild", pDest, pSpellId, pMapID, pCoordX, pCoordY)
            else
                added, newRec = CB:AddRecord(tbl, pName, pSpell, pAmount, pTS, pCrit, pClass, "guild", listKind, pDest, pSpellId, pMapID, pCoordX, pCoordY)
            end

            if added and newRec then
                SYNC.newCount = SYNC.newCount + 1
            end
        end
    end

    if CB.UI and CB.UI.Refresh then CB.UI:Refresh() end
end

-- =========================================================
-- COORDINATOR-WAHL STARTEN (öffentlich)
-- =========================================================
function CB:StartElection()
    if not IsInGuild() then return end
    if CB.NewerVersionWarned then return end

    SYNC.isSyncActive = true
    SYNC.awaitingSync = true  -- Wir erwarten einen Snapshot vom Coordinator
    SYNC.newCount     = 0
    SYNC.knownSenders = {}
    SYNC.electionBids = {}

    local myName      = UnitName("player")
    local sessionTime = math.floor(GetTime() - SYNC.sessionStart)
    SYNC.electionBids[myName] = sessionTime  -- Eigenes Bid vormerken

    if CB.DEBUG_MODE then
        CB:Print("|cffffff00DEBUG Wahl:|r Starte Coordinator-Wahl. Mein Name: '" .. myName .. "' | Session: " .. sessionTime .. "s | Bekannter Coordinator: " .. tostring(SYNC.coordinator))
    end

    if CB.DEBUG_MODE then CB:Print(CB.L["MSG_SYNC_START"] or "Synchronisierung gestartet...") end

    -- ELECT_REQ enthält eigene Session-Zeit → andere können sie in ihre Bids aufnehmen
    ChatThrottleLib:SendAddonMessage("NORMAL", CB.PREFIX,
        string.format("ELECT_REQ|%s|%d", vToken, sessionTime), "GUILD")

    if SYNC.electionTimer then SYNC.electionTimer:Cancel() end

    if SYNC.coordinator then
        -- Coordinator bekannt → 10s Timeout falls er nicht antwortet
        SYNC.electionTimer = C_Timer.NewTimer(10, function()
            if SYNC.isSyncActive then
                -- Coordinator hat nicht reagiert → Coordinator zurücksetzen + neu wählen
                SYNC.coordinator   = nil
                SYNC.isCoordinator = false
                SYNC.electionBids  = { [myName] = sessionTime }
                SYNC.electionTimer = C_Timer.NewTimer(3, function()
                    DetermineCoordinator()
                end)
            end
        end)
    else
        -- Kein Coordinator bekannt → 3s Bids sammeln, dann auswerten
        SYNC.electionTimer = C_Timer.NewTimer(3, function()
            DetermineCoordinator()
        end)
    end
end

-- Wrapper: Rückwärtskompatibilität für Core.lua (5s Timer) + Settings-Button
function CB:RequestSnapshot(manual)
    if not manual then
        local now = time()
        if now - SYNC.lastSyncRequestAt < 300 then return end
        SYNC.lastSyncRequestAt = now
    end
    CB:StartElection()
end

-- =========================================================
-- EVENT REGISTER
-- =========================================================
local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_ADDON")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_LOGOUT")

f:SetScript("OnEvent", function(_, event, prefix, text, channel, sender)
    if event == "PLAYER_ENTERING_WORLD" then
        C_ChatInfo.RegisterAddonMessagePrefix(CB.PREFIX)

    elseif event == "PLAYER_LOGIN" then
        -- Session-Startzeit festhalten (Basis für Coordinator-Wahl)
        SYNC.sessionStart = GetTime()
        -- Spielername cachen für zuverlässigen Self-Filter
        SYNC.myName = UnitName("player")

    elseif event == "PLAYER_LOGOUT" then
        -- Coordinator-Nachfolge einleiten wenn ich Coordinator bin (best effort)
        if SYNC.isCoordinator then
            ChatThrottleLib:SendAddonMessage("NORMAL", CB.PREFIX,
                "ELECT_LOST|" .. vToken .. "|" .. (UnitName("player") or ""), "GUILD")
        end

    elseif event == "CHAT_MSG_ADDON" and prefix == CB.PREFIX then
        local myName = SYNC.myName or UnitName("player")
        -- ShortName: Realm-Suffix entfernen bevor verglichen wird
        if ShortName(sender) ~= myName then
            if CB.DEBUG_MODE then
                local displaySafeText = string.gsub(text, "|", "  ")
                CB:DLog(5, sender, channel)
                CB:Print("|cff00ffffDEBUG 8 (Volltext):|r " .. string.sub(displaySafeText, 1, 150))
            end
            OnAddonMessage(prefix, text, channel, ShortName(sender))
        end
    end
end)
