ThreatWallForeverLocale = ThreatWallForeverLocale or {}
local L = ThreatWallForeverLocale

-- =========================================================
-- ENGLISH (default / fallback)
-- =========================================================
L["ROLE_TANK"] = "Tank"
L["ROLE_DPS"] = "DD/Heal"

L["TITLE_TANK"] = "TWF"
L["TITLE_DPS"] = "TWF"

L["EMPTY"] = "No aggro problems right now."

L["LOCKED_HINT"] = "the window is locked. Gear menu, then Lock window."
L["LOCKED_ON"] = "locked."
L["LOCKED_OFF"] = "unlocked."
L["ROLE_SET"] = "role set to %s."
L["NO_THREAT_API"] = "this client has no threat API, so there is nothing to show."
L["NO_NAMEPLATES"] = "no nameplates exist right now. Target the enemy and stand in melee, then try again."
L["LOADED"] = "%s loaded. Minimap button or /twf. /twf test shows sample rows."
L["HELP"] = "/threatwall or /twf (show or hide) | test | role | mark | lock | reset | options | debug | clearlog | hint | hint reset"
L["HINT_RESET"] = "nameplate hint re-enabled - it will show again next time nameplates are off."
L["LOG_CLEARED"] = "debug log cleared."
L["DEBUG_ON"] = "debug messages on: you'll see a chat line whenever an enemy's status changes."
L["DEBUG_OFF"] = "debug messages off."

L["TT_ROLE_TITLE"] = "Switch role"
L["TT_ROLE_TANK"] = "Tank: shows enemies you are losing aggro on."
L["TT_ROLE_DPS"] = "DD/Heal: shows enemies where you are pulling aggro."

L["TT_TANK_RED"] = "You have little or no threat on this one."
L["TT_TANK_YELLOW"] = "Someone is closing in on your threat here."
L["TT_TANK_GREEN"] = "You have solid aggro here. No action needed."
L["TT_DPS_RED"] = "You are holding aggro on this one. Back off."
L["TT_DPS_YELLOW"] = "Your threat is climbing toward the tank's."
L["TT_DPS_GREEN"] = "Your threat is safely below the tank's."
L["TT_CLICK"] = "Click to target it."

L["MM_TITLE"] = "ThreatWall Forever"
L["MM_LEFT"] = "Left-click: show or hide"
L["MM_RIGHT"] = "Right-click: settings"
L["MM_DRAG"] = "Drag: move this button"

L["MENU_TITLE"] = "ThreatWall Forever"
L["MENU_ROLE"] = "Role: %s"
L["MENU_LOCK"] = "Lock window"
L["MENU_COMBAT_ONLY"] = "Only show in combat"
L["MENU_GROUP_ONLY"] = "Only show in a group"
L["MENU_SHOW_ALL"] = "Show all fights"
L["MENU_HIGHLIGHT"] = "Highlight my target"
L["MENU_SOUND"] = "Warning sound"
L["MENU_DEBUG"] = "Debug messages"
L["MENU_BACKGROUND"] = "Background"
L["MENU_SCALE"] = "Scale"
L["MENU_MINIMAP"] = "Minimap button"
L["MENU_TEST"] = "Test rows"
L["MENU_RESET"] = "Reset position"

L["HINT_TITLE"] = "Enemy Nameplates are off"
L["HINT_BODY"] = "With nameplates ON, ThreatWall Forever can find every enemy actually fighting your group - even ones nobody has targeted.\n\nWith nameplates OFF, it can only see an enemy while you or a group member currently has it targeted. It drops off the list the moment the target changes.\n\nTurning them on (Interface Options > Names > Enemy Nameplates) gets you the most complete list. Quick toggle: the V key (default binding)."
L["HINT_DONT_SHOW"] = "Don't show again"
L["HINT_OK"] = "OK"
L["HINT_OPEN_SETTINGS"] = "Open settings"

-- =========================================================
-- DEUTSCH
-- =========================================================
if GetLocale() == "deDE" then
  L["ROLE_TANK"] = "Tank"
  L["ROLE_DPS"] = "DD/Heal"

  L["TITLE_TANK"] = "TWF"
  L["TITLE_DPS"] = "TWF"

  L["EMPTY"] = "Aktuell keine Aggro-Probleme."

  L["LOCKED_HINT"] = "Das Fenster ist gesperrt. Zahnrad-Menü, dann 'Fenster sperren'."
  L["LOCKED_ON"] = "gesperrt."
  L["LOCKED_OFF"] = "entsperrt."
  L["ROLE_SET"] = "Rolle auf %s gestellt."
  L["NO_THREAT_API"] = "Dieser Client hat keine Threat-API, es gibt also nichts anzuzeigen."
  L["NO_NAMEPLATES"] = "Aktuell sind keine Namensschilder sichtbar. Ziel anvisieren, in den Kampf gehen und erneut versuchen."
  L["LOADED"] = "%s geladen. Minimap-Button oder /twf. /twf test zeigt Beispielzeilen."
  L["HELP"] = "/threatwall oder /twf (ein/aus) | test | role | mark | lock | reset | options | debug | clearlog | hint | hint reset"
  L["HINT_RESET"] = "Nameplate-Hinweis wieder aktiviert - er kommt nächstes Mal wieder, wenn Nameplates aus sind."
  L["LOG_CLEARED"] = "Debug-Log gelöscht."
  L["DEBUG_ON"] = "Debug-Meldungen an: du siehst eine Chat-Zeile, sobald sich der Status eines Gegners ändert."
  L["DEBUG_OFF"] = "Debug-Meldungen aus."

  L["TT_ROLE_TITLE"] = "Rolle wechseln"
  L["TT_ROLE_TANK"] = "Tank: zeigt Gegner, bei denen du die Aggro verlierst."
  L["TT_ROLE_DPS"] = "DD/Heal: zeigt Gegner, bei denen du Aggro ziehst."

  L["TT_TANK_RED"] = "Du hast kaum oder keine Bedrohung auf diesem Ziel."
  L["TT_TANK_YELLOW"] = "Jemand kommt dir hier bei der Bedrohung näher."
  L["TT_TANK_GREEN"] = "Du hast hier sicheren Aggro. Kein Handlungsbedarf."
  L["TT_DPS_RED"] = "Du hast hier die Aggro. Geh runter mit dem Schaden."
  L["TT_DPS_YELLOW"] = "Deine Bedrohung nähert sich der des Tanks."
  L["TT_DPS_GREEN"] = "Deine Bedrohung liegt sicher unter der des Tanks."
  L["TT_CLICK"] = "Klicken, um es anzuvisieren."

  L["MM_TITLE"] = "ThreatWall Forever"
  L["MM_LEFT"] = "Linksklick: ein-/ausblenden"
  L["MM_RIGHT"] = "Rechtsklick: Einstellungen"
  L["MM_DRAG"] = "Ziehen: diesen Button verschieben"

  L["MENU_TITLE"] = "ThreatWall Forever"
  L["MENU_ROLE"] = "Rolle: %s"
  L["MENU_LOCK"] = "Fenster sperren"
  L["MENU_COMBAT_ONLY"] = "Nur im Kampf zeigen"
  L["MENU_GROUP_ONLY"] = "Nur in einer Gruppe zeigen"
  L["MENU_SHOW_ALL"] = "Alle Kämpfe zeigen"
  L["MENU_HIGHLIGHT"] = "Aktives Ziel hervorheben"
  L["MENU_SOUND"] = "Warnton"
  L["MENU_DEBUG"] = "Debug-Meldungen"
  L["MENU_BACKGROUND"] = "Hintergrund"
  L["MENU_SCALE"] = "Skalierung"
  L["MENU_MINIMAP"] = "Minimap-Button"
  L["MENU_TEST"] = "Testzeilen"
  L["MENU_RESET"] = "Position zurücksetzen"

  L["HINT_TITLE"] = "Gegner-Namensschilder sind aus"
  L["HINT_BODY"] = "Mit Namensschildern AN findet ThreatWall Forever jeden Gegner, der wirklich mit deiner Gruppe kämpft - auch wenn ihn gerade niemand anvisiert.\n\nMit Namensschildern AUS sieht es einen Gegner nur, solange du oder ein Gruppenmitglied ihn gerade als Ziel hast. Er fällt sofort aus der Liste, sobald sich das Ziel ändert.\n\nSchalte sie ein (Interface-Optionen > Namen > Gegner-Namensschilder) für die vollständigste Liste. Schnell-Umschalter: Taste V (Standardbelegung)."
  L["HINT_DONT_SHOW"] = "Nicht mehr anzeigen"
  L["HINT_OK"] = "OK"
  L["HINT_OPEN_SETTINGS"] = "Einstellungen öffnen"
end
