# ThreatWall Forever — Test: Aggro-Ziel am Mob (Anforderung L neu)

Stand 2026-10-13: im Spiel getestet (1, 3–15 ✔), committet (`0170e72`). Offen: 2 (nicht ausdrücklich bestätigt), 16 (Blizzard-Original), 17 (Instanz), 18 (Debug-Zeilen).
Mitgetestet wird die Rücknahme der freundlichen Nameplates (M) und das einmalige Zurückstellen.

**Vor dem Test:** Spiel **komplett neu starten** (die TOC hat sich geändert, `/reload` reicht nicht).
Debug bei Bedarf: `/twf debug 1` (aus: `/twf debug 0`), Momentaufnahme: `/twf dump`.

## Teil 1 — allein

| Nr. | Schritt | Erwartet | Ergebnis |
|---|---|---|---|
| 1 | Spiel neu starten, einloggen | keine Lua-Fehler, kein Popup „Spiel-Optionen“ | ✔ |
| 2 | Auf Mitspieler/andere Spieler schauen | freundliche Nameplates sind **aus** (TWF hat den alten Wert zurückgestellt); Umschalt+V schaltet sie weiter von Hand | offen |
| 3 | Zahnrad → Einstellungen, Abschnitt „Nameplates“ | zwei Checkboxen: „TWF-Nameplates“ und „Aggro-Ziel anzeigen“ (beide an), Tooltips vorhanden | ✔ |
| 4 | `/twf hint` | nur noch die Zeile „Gegner-Nameplates“ mit ✔ | ✔ |
| 5 | `/twf test` | Liste: Heiler-Symbol vor „Grillmaster“, DD-Symbol vor „Adds Rechts“, keins vor „Adds Links“; nochmal `/twf test` = aus | ✔ nach Anpassung: Symbol 18 px, Abstand 5 px, Schlachtzugsymbol in der Liste abgeschaltet |
| 6 | Tank-Modus, Mob allein angreifen | TWF-Nameplate wie bisher, **keine** Zusatzzeile über dem Mobnamen | ✔ |
| 7 | DD/Heal-Modus (Rollen-Knopf), Mob allein angreifen | **keine** Zusatzzeile (du hältst ihn selbst) | ✔ |

## Teil 2 — mit Mitspieler (Rollen setzen: Rechtsklick aufs eigene Porträt → Rolle)

| Nr. | Schritt | Erwartet | Ergebnis |
|---|---|---|---|
| 8 | **Tank-Modus:** Mitspieler zieht einem Mob die Aggro ab | über dem Mobnamen eine zweite Zeile: **Rollensymbol + sein Name in Klassenfarbe** | ✔ nach Korrektur: Halter über `UnitThreatSituation` (ausführliche Abfrage ist über Nameplates geheim); Symbol 20 px, Schrift größer |
| 9 | wie 8, Blick in die TWF-Liste | vor dem Mobnamen steht **sein Rollensymbol** (kein Name); Liste sonst wie immer | ✔ |
| 10 | Mob zurückholen (du hast wieder Aggro) | Zeile über dem Mob und Symbol in der Liste **verschwinden** | ✔ |
| 11 | Mob, der **dich** schlägt | **nie** dein eigener Name, keine Zeile | ✔ |
| 12 | **DD/Heal-Modus:** Mitspieler hält einen Mob | über dem Mobnamen **nur sein Rollensymbol**, mittig, **ohne Name** | ✔ |
| 13 | DD/Heal-Modus: Mob, den **du** hältst | nichts | ✔ |
| 14 | Mitspieler setzt seine Rolle zurück (keine Rolle) | **DD-Symbol** statt Rollen-Symbol | ✔ |
| 15 | Checkbox „Aggro-Ziel anzeigen“ **aus** | Zeile über Mobs und Symbole in der Liste sofort weg; **an** = wieder da | ✔ |
| 16 | Checkbox „TWF-Nameplates“ **aus** (Blizzard-Original) | Zeile erscheint über Blizzards Nameplate (Position ggf. unschön → notieren) | offen |
| 17 | **In einer Instanz** | 8–13 funktionieren gleich; über Mitspielern **keine** Blizzard-Balken mehr | offen |
| 18 | `/twf debug 1`, Mitspieler zieht Aggro | Zeile „[021] Halter von nameplateN: party1“, beim Zurückholen „… : player“ | offen |

## Optik (nur Geschmack, alles Werte in `Config.lua` → `C.SYMBOL_LAYOUT`)
- Symbolgröße über dem Mob (`ICON_SIZE`, 14 px), Abstand zum Namen (`ICON_GAP`), Höhe über dem Mobnamen (`LINE_Y`), Symbolgröße in der Liste (`LIST_SIZE`).

## Danach
- Passt alles → Claude committet (nur Ordner ThreatWallForever).
- Offen bleiben: Bug B1 (Schlachtzugsymbole bei TWF-Nameplates), „TODO vor Veröffentlichung“ in `ANFORDERUNGEN.md`.
