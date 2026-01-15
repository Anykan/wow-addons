CrittersBoard = CrittersBoard or {}
local CB = CrittersBoard

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

local function SafeInitUI()
  if not CB.UI then return false end
  if not CB.UI.CreateMain then return false end
  if not CB.UI.CreateSettings then return false end

  if not CB.UI.frame then
    CB.UI:CreateMain()
  end

  if not CB.UI.settingsFrame then
    CB.UI:CreateSettings()
  end

  -- Gear click => Settings
  if CB.UI.gearBtn and not CB.UI.gearBtn._cbHooked then
    CB.UI.gearBtn._cbHooked = true
    CB.UI.gearBtn:SetScript("OnClick", function()
      if CB.UI.ToggleSettings then
        CB.UI:ToggleSettings()
      end
    end)
  end

  -- Restore open state
  if CB.DB and CB.DB.ui and CB.DB.ui.isOpen then
    CB.UI.frame:Show()
  else
    CB.UI.frame:Hide()
  end

  CB.UI:ApplyMainAlpha()
  CB.UI:UpdateLock()
  CB.UI:Refresh()

  return true
end

frame:SetScript("OnEvent", function(self, event, name, ...)
  if event == "ADDON_LOADED" then
    if name ~= "CrittersBoard" then return end

    -- SavedVariables
    CrittersBoardDB = CrittersBoardDB or {}
    CB.DB = CrittersBoardDB

    if CB.InitDB then
      CB:InitDB()
    end

    -- wir initialisieren UI NICHT hier, weil Reihenfolge nicht garantiert ist
    -- UI kommt sicher bei PLAYER_LOGIN

    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
      C_ChatInfo.RegisterAddonMessagePrefix(CB.PREFIX)
    end

  elseif event == "PLAYER_LOGIN" then
    SafeInitUI()

  elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
    if CB.OnCombatLog then
      CB:OnCombatLog()
    end
  end
end)

-- Slash command
SLASH_CRITTERSBOARD1 = "/cb"
SlashCmdList["CRITTERSBOARD"] = function(msg)
  msg = (msg or ""):lower()

  if not CB.UI or not CB.UI.ToggleMain then
    CB:Print("UI ist noch nicht bereit. Bitte kurz warten /reload.")
    return
  end

  if msg == "settings" then
    if CB.UI.ToggleSettings then
      CB.UI:ToggleSettings()
    end
    return
  end

  CB.UI:ToggleMain()
end
