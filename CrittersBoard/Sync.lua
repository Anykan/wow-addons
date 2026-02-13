CrittersBoard = CrittersBoard or {}
local CB = CrittersBoard

CB.Sync = CB.Sync or {}
local SYNC = CB.Sync

SYNC.lastSyncRequestAt = SYNC.lastSyncRequestAt or 0
SYNC.rxCount = 0      
SYNC.newCount = 0     
SYNC.knownSenders = {} 

local MAX_PAYLOAD = 220
local vToken = "V:" .. (CB.REQUIRED_DB_VERSION or 3) 

-- =========================================================
-- HILFSFUNKTIONEN FÜR CHUNKS (Wie in alter Version)
-- =========================================================
local function EncodeRecord(rec)
    local crit = rec.isCrit and "1" or "0"
    return table.concat({
        CB:SafeStr(rec.player or "Unknown"),
        CB:SafeStr(rec.classFile or "UNKNOWN"),
        CB:SafeStr(rec.spell or "Unknown"),
        tostring(rec.amount or 0),
        tostring(rec.ts or time()),
        crit,
        CB:SafeStr(rec.destName or "Unbekannt"),
        tostring(rec.spellId or 0),   -- NEU
        tostring(rec.mapID or 0),     -- NEU
        tostring(rec.coordX or 0),    -- NEU
        tostring(rec.coordY or 0),    -- NEU
    }, ",")
end

local function GetTableByKind(kind)
    if kind == "D" then return CB.DB.damage end
    if kind == "H" then return CB.DB.heal end
    if kind == "O" then return CB.DB.overkill end
    if kind == "S" then return CB.DB.spells end
    if kind == "HS" then return CB.DB.healSpells end
    return nil
end

local function MakeChunks(kind)
    local tbl = GetTableByKind(kind)
    if not tbl or not tbl.records then return {} end

    local chunks = {}
    local current = ""

    -- Geht durch ALLE Datensätze (kein Limit, wie besprochen)
    for i = 1, #tbl.records do
        local line = EncodeRecord(tbl.records[i])
        local add = (current == "") and line or (";" .. line)

        -- Prüft die 220 Zeichen Grenze (minus Puffer für Header)
        if (#current + #add) > (MAX_PAYLOAD - 40) then
            table.insert(chunks, current)
            current = line
        else
            current = current .. add
        end
    end

    if current ~= "" then
        table.insert(chunks, current)
    end
    return chunks
end

-- =========================================================
-- HILFSFUNKTION: Sync-Abschlussbericht
-- =========================================================
local function FinishSync()
    if not SYNC.isSyncActive then return end
    SYNC.isSyncActive = false

    local senderCount = 0
    for _ in pairs(SYNC.knownSenders) do senderCount = senderCount + 1 end

    local msg = string.format("GildenSync abgeschlossen: %d Spieler | %d neue Rekorde", senderCount, SYNC.newCount)
    if RaidNotice_AddMessage and RaidWarningFrame then
        RaidNotice_AddMessage(RaidWarningFrame, "|cffffff00" .. msg .. "|r", ChatTypeInfo["RAID_WARNING"])
    end
    
    PlaySoundFile("Interface\\AddOns\\CrittersBoard\\sounds\\sync.ogg", "Master")
    CB:Print(msg)
end

local function ArmSyncFinished()
    if SYNC.finishTimer then SYNC.finishTimer:Cancel() end
    SYNC.finishTimer = C_Timer.NewTimer(3, FinishSync) 
end

-- =========================================================
-- SEND ENGINE
-- =========================================================
function CB:SendEvent(kind, rec, priority)
    if not CB.DB or (CB.DB.ui and CB.DB.ui.disableSync) then return end
    if not rec then return end

    local prio = priority or "NORMAL"
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
    local cmd = parts[1]

    -- A) SNAP_REQ: Antwortet mit Chunks (Alle Daten)
    if cmd == "SNAP_REQ" then
        if CB.DEBUG_MODE then CB:DLog(9, "SNAP_REQ empfangen - starte Chunk-Antwort") end
        if CB.DB then
            local types = {"D", "H", "O", "S", "HS"}
            for _, t in ipairs(types) do
                local chunks = MakeChunks(t)
                for _, payload in ipairs(chunks) do
                    local msg = "CHUNK|" .. vToken .. "|" .. t .. "|" .. payload
                    ChatThrottleLib:SendAddonMessage("BULK", CB.PREFIX, msg, "GUILD")
                end
            end
        end
        return
    end
	
	local receivedToken = parts[2]
		if receivedToken ~= vToken then
			if CB.DEBUG_MODE then print("Ignoriere Nachricht mit falscher Version: " .. tostring(receivedToken)) end
		return 
    end
	
    -- B) CHUNK/EVT Verarbeitung
    local listKind, payload
    if cmd == "CHUNK" then
        listKind = parts[3]
        payload = parts[4]
    elseif cmd == "EVT" then
        listKind = parts[3]
        payload = parts[4]
    else
        return
    end

    if SYNC.isSyncActive then
        SYNC.knownSenders[sender] = true
        ArmSyncFinished() 
    end

    local tbl = GetTableByKind(listKind)
    if not tbl or not payload then return end

    -- Zerlegen der Chunks (Semikolon trennt Rekorde)
    for recStr in string.gmatch(payload, "([^;]+)") do
        local r = {}
        -- Komma trennt Felder
        for p in string.gmatch(recStr, "([^,]+)") do table.insert(r, p) end
        
        if #r >= 11 then
            local pName, pClass, pSpell = r[1], r[2], r[3]
            local pAmount, pTS = tonumber(r[4]) or 0, tonumber(r[5]) or 0
            local pCrit, pDest = (r[6] == "1"), r[7] or "Unbekannt"

			local pSpellId = tonumber(r[8]) or 0
            local pMapID   = tonumber(r[9]) or 0
            local pCoordX  = tonumber(r[10]) or 0
            local pCoordY  = tonumber(r[11]) or 0
			
            local added, newRec = false, nil
			
            if listKind == "S" or listKind == "HS" then
                if listKind == "S" then
                    added, newRec= CB:AddSpellBest(pName, pSpell, pAmount, pTS, pCrit, pClass, "guild", pDest, pSpellId, pMapID, pCoordX, pCoordY)
                else
                    added, newRec = CB:AddHealSpellBest(pName, pSpell, pAmount, pTS, pCrit, pClass, "guild", pDest, pSpellId, pMapID, pCoordX, pCoordY)
                end
            else
                added, newRec = CB:AddRecord(tbl, pName, pSpell, pAmount, pTS, pCrit, pClass, "guild", listKind, pDest, pSpellId, pMapID, pCoordX, pCoordY)
            end
			if added and newRec then
                newRec.spellId = pSpellId
                newRec.mapID   = pMapID
                newRec.coordX  = pCoordX
                newRec.coordY  = pCoordY
                SYNC.newCount = SYNC.newCount + 1
            end
        end
    end

    if CB.UI and CB.UI.Refresh then CB.UI:Refresh() end
end

-- =========================================================
-- START-FUNKTION
-- =========================================================
function CB:RequestSnapshot(manual)
    if not IsInGuild() or (CB.DB.ui and CB.DB.ui.disableSync) then return end

    local now = time()
    if not manual and (now - SYNC.lastSyncRequestAt < 300) then return end
    
    SYNC.lastSyncRequestAt = now
    SYNC.isSyncActive = true
    SYNC.newCount = 0
    SYNC.knownSenders = {}
    
    CB:Print(CB.L["MSG_SYNC_START"] or "Synchronisierung gestartet...")
    ChatThrottleLib:SendAddonMessage("NORMAL", CB.PREFIX, "SNAP_REQ", "GUILD")
    
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
        if sender ~= UnitName("player") then
            if CB.DEBUG_MODE then
                local displaySafeText = string.gsub(text, "|", "  ") 
                CB:DLog(5, sender, channel)
                CB:Print("|cff00ffffDEBUG 8 (Volltext):|r " .. string.sub(displaySafeText, 1, 150))
            end
            OnAddonMessage(prefix, text, channel, sender)
        end
    end
end)