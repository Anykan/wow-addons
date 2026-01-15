CrittersBoard = CrittersBoard or {}
local CB = CrittersBoard

CB.PREFIX = "CB_CRIT"

function CB:Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cff66ff66CrittersBoard|r: " .. tostring(msg))
end

function CB:SafeStr(s)
  if not s then return "" end
  return tostring(s):gsub("|", "/")
end

function CB:ColorText(text, r, g, b)
  local rr = math.floor((r or 1) * 255)
  local gg = math.floor((g or 1) * 255)
  local bb = math.floor((b or 1) * 255)
  return string.format("|cff%02x%02x%02x%s|r", rr, gg, bb, text or "")
end

function CB:GetClassColorFromClassFile(classFile)
  if classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile] then
    local c = RAID_CLASS_COLORS[classFile]
    return c.r, c.g, c.b
  end
  return 1, 1, 1
end

function CB:ColorNumberDamage(amount, isCrit)
  if isCrit then
    return string.format("|cffff3333%d|r", amount) -- red
  end
  return string.format("|cffffff66%d|r", amount) -- yellow
end

function CB:ColorNumberHeal(amount, isCrit)
  if isCrit then
    return string.format("|cff33ff33%d|r", amount) -- green
  end
  return string.format("|cffffff66%d|r", amount) -- yellow
end
