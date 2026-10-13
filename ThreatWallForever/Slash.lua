-- Slash.lua — alle /twf-Befehle (Aliase: /threatwall, /twall).

local _, ns = ...
local C = ns.Config
local L = ns.L

local function slash(msg)
  local db = ns.db
  local cmd, arg = (msg or ''):lower():match('^%s*(%S*)%s*(%S*)')
  if cmd == 'test' then
    ns.state.testMode = not ns.state.testMode
    db.shown = true
  elseif cmd == 'role' then
    ns.toggleRole()
    ns.say(string.format(L.ROLE_SET, ns.roleName()), 'ROLE_SET')
  elseif cmd == 'lock' then
    db.locked = not db.locked
    ns.say(db.locked and L.LOCKED_ON or L.LOCKED_OFF, db.locked and 'LOCKED_ON' or 'LOCKED_OFF')
  elseif cmd == 'reset' then
    ns.resetPlace()
  elseif cmd == 'debug' then
    ns.setDebugFromCommand(arg)
  elseif cmd == 'dump' then
    ns.debugDump()
  elseif cmd == 'mark' then
    ns.cycleMarkMethod()
    local names = ns.MARK_METHOD_NAMES
    ns.say('Symbol-Methode: ' .. names[db.markMethod] .. ' (' .. db.markMethod .. '/' .. #names .. ')')
  elseif cmd == 'clearlog' then
    db.log = {}
    ns.say(L.LOG_CLEARED, 'LOG_CLEARED')
  elseif cmd == 'hint' then
    ns.checkGameOptions(true)
  elseif cmd == '' then
    ns.toggleWindow()
  else
    ns.say(L.HELP, 'HELP')
  end
  ns.applyLook()
  ns.updateMinimap()
  ns.refresh()
end

ns.RegisterModule('Slash', { OnLogin = function() SlashCmdList.THREATWALL = slash end })
