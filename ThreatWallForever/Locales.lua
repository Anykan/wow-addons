-- Locales.lua — alle Texte, die Spieler sehen (EN + DE). Umschaltung über die Spielsprache.
local _, ns = ...
ns.L = ns.L or {}
local L = ns.L

-- =========================================================
-- ENGLISCH (Standard / Rückfall)
-- =========================================================
L["ROLE_TANK"] = "Tank"
L["ROLE_DPS"] = "DD/Heal"

L["TITLE_TANK"] = "TWF"
L["TITLE_DPS"] = "TWF"

L["EMPTY"] = "No aggro problems right now."

L["LOCKED_HINT"] = "the window is locked. Unlock it in the settings (gear) or by right-clicking the minimap button."
L["LOCKED_ON"] = "locked."
L["LOCKED_OFF"] = "unlocked."
L["ROLE_SET"] = "role set to %s."
L["NO_THREAT_API"] = "this client has no threat API, so there is nothing to show."
L["NO_NAMEPLATES"] = "no nameplates exist right now. Target the enemy and stand in melee, then try again."
L["LOADED"] = "%s loaded. Minimap button or /twf. /twf test shows sample rows."
L["HELP"] = "/threatwall or /twf (show or hide) | test | role | mark | lock | reset | clearlog | hint | hint reset"
L["HINT_RESET"] = "nameplate hint re-enabled - it will show again next time nameplates are off."
L["LOG_CLEARED"] = "debug log cleared."

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
L["MM_RIGHT"] = "Right-click: lock window"
L["MM_DRAG"] = "Drag: move this button"

L["MENU_TITLE"] = "ThreatWall Forever"
L["MENU_LOCK"] = "Lock window"
L["MENU_COMBAT_ONLY"] = "Only show in combat"
L["MENU_GROUP_ONLY"] = "Only show in a group"
L["MENU_SHOW_ALL"] = "Show all fights"
L["MENU_HIGHLIGHT"] = "Highlight my target"
L["MENU_SOUND"] = "Warning sound"
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

L["SETTINGS_TITLE"] = "TWF – Settings"
L["SEC_GENERAL"] = "General"
L["SEC_DISPLAY"] = "Display"
L["SEC_LOOK"] = "Appearance"
L["SEC_TOOLS"] = "Tools"
L["OPT_ROLE"] = "Role"
L["TIP_ROLE"] = "Tank: the list shows enemies you are losing aggro on.\nDD/Heal: the list shows enemies you are pulling aggro from."
L["TIP_LOCK"] = "Locks the TWF window so it cannot be moved or resized by accident."
L["TIP_MINIMAP"] = "Shows the TWF button at the minimap (left-click: show/hide, right-click: lock)."
L["TIP_COMBAT_ONLY"] = "Hides the TWF window while you are out of combat."
L["TIP_GROUP_ONLY"] = "Hides the TWF window while you are not in a group or raid."
L["TIP_SHOW_ALL"] = "Also lists enemies without an aggro problem (green) as long as they are in combat."
L["TIP_HIGHLIGHT"] = "Puts a pulsing frame around the row of your current target."
L["TIP_SOUND"] = "Plays a warning sound when an enemy turns red or yellow."
L["TIP_BACKGROUND"] = "Opacity of the TWF window background."
L["TIP_SCALE"] = "Size of the TWF window."
L["TIP_TEST"] = "Shows sample rows so you can arrange the window without a fight."
L["TIP_RESET"] = "Moves the TWF window back to the middle of the screen at its default size."
L["PANEL_TEXT"] = "All settings are in their own window."
L["PANEL_BUTTON"] = "Open TWF settings"

-- =========================================================
-- DEUTSCH
-- =========================================================
if GetLocale() == "deDE" then
  L["ROLE_TANK"] = "Tank"
  L["ROLE_DPS"] = "DD/Heal"

  L["TITLE_TANK"] = "TWF"
  L["TITLE_DPS"] = "TWF"

  L["EMPTY"] = "Aktuell keine Aggro-Probleme."

  L["LOCKED_HINT"] = "Das Fenster ist fixiert. Lösen in den Einstellungen (Zahnrad) oder per Rechtsklick auf den Minimap-Button."
  L["LOCKED_ON"] = "gesperrt."
  L["LOCKED_OFF"] = "entsperrt."
  L["ROLE_SET"] = "Rolle auf %s gestellt."
  L["NO_THREAT_API"] = "Dieser Client hat keine Threat-API, es gibt also nichts anzuzeigen."
  L["NO_NAMEPLATES"] = "Aktuell sind keine Namensschilder sichtbar. Ziel anvisieren, in den Kampf gehen und erneut versuchen."
  L["LOADED"] = "%s geladen. Minimap-Button oder /twf. /twf test zeigt Beispielzeilen."
  L["HELP"] = "/threatwall oder /twf (ein/aus) | test | role | mark | lock | reset | clearlog | hint | hint reset"
  L["HINT_RESET"] = "Nameplate-Hinweis wieder aktiviert - er kommt nächstes Mal wieder, wenn Nameplates aus sind."
  L["LOG_CLEARED"] = "Debug-Log gelöscht."

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
  L["MM_RIGHT"] = "Rechtsklick: Fenster fixieren"
  L["MM_DRAG"] = "Ziehen: diesen Button verschieben"

  L["MENU_TITLE"] = "ThreatWall Forever"
  L["MENU_LOCK"] = "Fenster fixieren"
  L["MENU_COMBAT_ONLY"] = "Nur im Kampf zeigen"
  L["MENU_GROUP_ONLY"] = "Nur in einer Gruppe zeigen"
  L["MENU_SHOW_ALL"] = "Alle Kämpfe zeigen"
  L["MENU_HIGHLIGHT"] = "Aktives Ziel hervorheben"
  L["MENU_SOUND"] = "Warnton"
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

  L["SETTINGS_TITLE"] = "TWF – Einstellungen"
  L["SEC_GENERAL"] = "Allgemein"
  L["SEC_DISPLAY"] = "Anzeige"
  L["SEC_LOOK"] = "Aussehen"
  L["SEC_TOOLS"] = "Werkzeuge"
  L["OPT_ROLE"] = "Rolle"
  L["TIP_ROLE"] = "Tank: Die Liste zeigt Gegner, bei denen du die Aggro verlierst.\nDD/Heal: Die Liste zeigt Gegner, bei denen du Aggro ziehst."
  L["TIP_LOCK"] = "Fixiert das TWF-Fenster, damit es nicht versehentlich verschoben oder in der Größe geändert wird."
  L["TIP_MINIMAP"] = "Zeigt den TWF-Button an der Minimap (Linksklick: ein/aus, Rechtsklick: fixieren)."
  L["TIP_COMBAT_ONLY"] = "Blendet das TWF-Fenster außerhalb des Kampfs aus."
  L["TIP_GROUP_ONLY"] = "Blendet das TWF-Fenster aus, solange du in keiner Gruppe oder keinem Schlachtzug bist."
  L["TIP_SHOW_ALL"] = "Zeigt auch Gegner ohne Aggro-Problem (grün), solange sie im Kampf sind."
  L["TIP_HIGHLIGHT"] = "Legt einen pulsierenden Rahmen um die Zeile deines aktuellen Ziels."
  L["TIP_SOUND"] = "Spielt einen Warnton, wenn ein Gegner rot oder gelb wird."
  L["TIP_BACKGROUND"] = "Deckkraft des Hintergrunds vom TWF-Fenster."
  L["TIP_SCALE"] = "Größe des TWF-Fensters."
  L["TIP_TEST"] = "Zeigt Beispielzeilen, damit du das Fenster ohne Kampf einrichten kannst."
  L["TIP_RESET"] = "Setzt das TWF-Fenster in die Bildschirmmitte und auf die Standardgröße zurück."
  L["PANEL_TEXT"] = "Alle Einstellungen findest du in einem eigenen Fenster."
  L["PANEL_BUTTON"] = "TWF-Einstellungen öffnen"
end
