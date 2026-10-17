# ThreatWall Forever — Anforderungen & Ideen für die nächste Ausbaustufe

Status: **Sammelphase** (seit 2026-10-04). Noch nichts getestet, noch kein Code.

**Regel:** Nur was der Nutzer **klar als Anforderung angibt**, steht in Teil 1. Details, die Claude innerhalb einer Anforderung ergänzt hat, sind mit *(Vorschlag Claude, offen)* markiert, bis der Nutzer sie bestätigt. Alles, worüber wir nur reden oder was Claude vorschlägt, steht in Teil 2 als Idee. Aus einer Idee wird erst dann eine Anforderung, wenn der Nutzer das ausdrücklich sagt.

# Teil 1 — Beschlossene Anforderungen

## F. Einstellungsfenster statt Dropdown-Menü — ✅ umgesetzt 2026-10-04 (im Spiel getestet)
- Das Zahnrad im TWF-Fensterkopf öffnet ein **eigenes Einstellungsfenster (Pop-up)** mit allen Optionen, statt des bisherigen Dropdowns (`showMenu(gear, SETTINGS)`).
- Die Befehle `/twf options` und `/twf config` werden **ersatzlos entfernt** (auch aus der Hilfe `L.HELP`). Das Einstellungsfenster öffnet sich nur über das Zahnrad.
- **Minimap-Button:**
  - Linksklick: TWF-Fenster ein- und ausblenden (ist bereits so)
  - Rechtsklick: Kleines Dropdown wie bisher, aber **nur mit „Fenster fixieren“** (`locked`). Bisher öffnet der Rechtsklick das komplette Menü.
  - Tooltip-Texte (`MM_LEFT`/`MM_RIGHT`) entsprechend anpassen.
- Inhalt: **alle** bisherigen Menüpunkte plus die Optionen neuer Funktionen, sobald sie beschlossen sind. Bisherige Punkte:
  - Rolle (Tank / DD-Heal)
  - Fenster sperren
  - Nur im Kampf
  - Nur in der Gruppe
  - Alle Kämpfe zeigen
  - Aktives Ziel hervorheben
  - Sound
  - ~~Debug-Meldungen~~ (entfällt, siehe H)
  - Hintergrund-Deckkraft (0–100 %)
  - Skalierung (80–150 %)
  - Minimap-Button
  - Testzeilen
  - Position zurücksetzen
- **Optik passend zum TWF-Fenster** (Damage-Meter-Look).
- **Schieberegler** für Deckkraft und Skalierung (statt Durchklicken), Min/Max/Schritt aus `Config.lua`.
- TWF erscheint zusätzlich im Spiel unter **Optionen → AddOns**.
- Aufbau: eine Seite mit Abschnitten **oder** Reiter (z. B. Allgemein / Liste / Debug), wird erst entschieden, wenn feststeht, wie viele Optionen es gibt.
- **Entscheidungen beim Bau (2026-10-04):**
  - Eine Seite mit Abschnitten: Allgemein (Rolle als zwei Knöpfe, Fenster fixieren, Minimap-Button) · Anzeige (Nur im Kampf, Nur in Gruppe, Alle Kämpfe, Ziel hervorheben, Warnton) · Aussehen (Schieberegler) · Werkzeuge (Testzeilen, Position zurücksetzen).
  - Schieberegler in **10-%-Schritten** (Hintergrund 0–100 %, Skalierung 80–150 %).
  - **Jede Option hat einen Tooltip** mit kurzer Erklärung (DE/EN).
  - Optionen → AddOns: Seite mit **Knopf „Einstellungen öffnen“**, keine doppelten Optionen.
  - Das Zahnrad öffnet/schließt das Fenster; Esc und X schließen; verschiebbar; Position wird nicht gespeichert.
  - H (Debug-Befehle) wird im selben Schritt gebaut.

## G. Mehrsprachig DE/EN, seit 0.3 auch ES/FR (gilt für ALLES, was der Spieler sieht)
- Alle sichtbaren Texte gibt es auf Deutsch und Englisch: Fenster, Einstellungsfenster, Dropdown, Tooltips, Chat-Meldungen, Popups, Hilfe.
- Die Sprache richtet sich automatisch nach der Spielsprache (`GetLocale()`): `deDE` = Deutsch, `esES`/`esMX` = Spanisch, `frFR` = Französisch (seit 0.3, Übersetzung ohne Prüfung durch Muttersprachler), alles andere = Englisch (Fallback).
- Ist heute schon so umgesetzt: `Locales.lua` hat 50 Schlüssel, EN und DE sind vollständig.
- Regel für alle neuen Funktionen: **jeder neue Text sofort als Locale-Schlüssel in allen Sprachen (EN, DE, ES, FR)**, kein fest eingetippter Text im Code. Patchnotes ebenfalls in allen Sprachen (REGELN 14).
- **Ausnahme Debug/Entwickler-Ausgaben: nur Deutsch**, unabhängig von der Spielsprache (die sieht nur der Entwickler). Das betrifft:
  - die Debug-Meldungen bei Statuswechseln
  - den Rohdaten-Dump
  - `tracked:`-Zeilen, `/twf mark`, `/twf hint` im Debug-Modus
  - die Log-Einträge
  - die Marker-Methoden-Namen
  Diese Texte stehen nicht in den Locales, sondern direkt auf Deutsch im Code (oder in einer eigenen DE-only-Tabelle).

## H. Debug-Schalter per Befehl — ✅ umgesetzt 2026-10-04 (im Spiel getestet)
- `/twf debug 1`: Debug-Meldungen **an**; `/twf debug 0`: Debug-Meldungen **aus**. Der Wert wird in `db.debug` gespeichert.
- **Automatischer `/reload` nur, wenn nötig** (`ReloadUI()`). Stand heute ist er nicht nötig: `db.debug` wird live abgefragt, der Schalter wirkt sofort (wie bisher die Menü-Checkbox). Falls eine spätere Debug-Funktion beim Laden etwas einrichtet, bekommt sie den Reload.
- Ohne Zahl oder mit ungültigem Wert: kurze Hilfe auf Deutsch („Nutze /twf debug 1 oder 0“) plus aktueller Status, **kein** Reload.
- Der bisherige Rohdaten-Dump (heute `/twf debug`) bekommt den eigenen Befehl **`/twf dump`** (vom Nutzer bestätigt). Er erzeugt eine einmalige Momentaufnahme: eine Zeile pro gefundenem Gegner-Token (`hostile`, `combat`, `engaged`, `tanking`, `status`, `mark`, `markOk`) plus `tracked:`-Zeilen der internen Liste. Ausgabe nur auf Deutsch.
- Die Checkbox „Debug messages“ verschwindet aus dem normalen Menü bzw. Einstellungsfenster (reines Entwickler-Werkzeug), damit Spieler sie nicht sehen.
- Die Hilfe (`L.HELP`) für Spieler erwähnt Debug nicht mehr.

## I. Modularer Aufbau (gilt für ALLES, was wir programmieren)
- Jede Funktion bzw. jedes Feature ist ein eigenes Modul in einer eigenen Datei. Eine Änderung betrifft nur dieses Modul.
- Heute ist alles in **einer** Datei (`ThreatWallForever.lua`, 1415 Zeilen), die nur intern in Abschnitte gegliedert ist: Atlas-Helfer, Erkennung, Zeichnen, Zeilen, Fenster, Nameplate-Hinweis, Menü, Minimap, Slash, Boot.
- Struktur (Lade-Reihenfolge = TOC-Reihenfolge):
  ```
  Config.lua          ALLE festlegbaren Werte + Defaults (Single Source of Truth, REGELN.md Nr. 5)
  Core.lua            Namespace, Event-Verteiler, Modul-Registrierung
  Locales.lua         EN/DE für Spieler-Texte
  Utils.lua           pcall-/secret-Helfer, Atlas-Fallbacks
  Debug.lua           Debug-Meldungen, Log, /twf dump  (nur DE)
  Detection.lua       Gegner finden + Ampel-Status (myStatus, candidateUnits)
  AggroHolder.lua     wer hat Aggro (L)
  List.lua            TWF-Fenster + Zeilen
  Nameplates.lua      Umschalten Blizzard/TWF, TWF-Nameplates mit Balken, Name, % (J, K)
  Symbols.lua         Symbol-Markierung Mob/Spieler/Liste (L)
  GroupFrames.lua     Symbol am Gruppenfenster (nur falls in Instanzen nötig, L)
  Settings.lua        Einstellungsfenster (F)
  Hint.lua            Prüfung der Spiel-Optionen + Hinweis-Popup (M)
  Minimap.lua         Minimap-Button + Rechtsklick-Dropdown (F)
  Slash.lua           /twf-Befehle
  ```
- Regeln:
  - **Gemeinsamer Namespace:** über `local addonName, TWF = ...`, keine globalen Variablen außer der SavedVariable.
  - **Gemeinsame Daten:** Module tauschen sich über eine zentrale Datenquelle aus. `Detection` erzeugt pro Aktualisierung die Gegnerliste, alle Anzeige-Module (Liste, Nameplates, Symbole) lesen nur diese Liste. So hat keine Anzeige eigene Logik zur Erkennung.
  - **Callbacks:** Module melden sich beim Core an, z. B. `TWF:RegisterModule(name, modul)` mit `OnInit`/`OnUpdate(daten)`/`OnSettingChanged(key)`. Neue Funktionen hängen sich ein, ohne andere Dateien zu ändern.
  - **Optionen zentral:** Alle Default-Einstellungen und festen Werte stehen in `Config.lua`, gruppiert pro Modul. Dort steht auch, welche Einträge im Einstellungsfenster erscheinen (Typ, Min/Max/Schritt). Das Einstellungsfenster baut sich daraus **dynamisch** auf. Module bringen keine eigenen Werte mit.
  - **Abschaltbar:** Jedes Anzeige-Modul lässt sich per Option an- und ausschalten. Ist es aus, macht es keine Arbeit (keine Events, keine Updates).
  - **Fehler isolieren:** Ein Fehler in einem Modul darf die anderen nicht mitreißen (Modul-Aufrufe im Core per `pcall`, Fehler ins Debug-Log).
- **Reihenfolge:** Erst den bestehenden Code ohne Verhaltensänderung in Module aufteilen (Refactoring) und im Spiel testen, danach die beschlossenen neuen Funktionen (F–M) als eigene Module bauen.

## J. Checkbox „TWF-Nameplates“: Umschalten Blizzard ↔ TWF (vom Nutzer beschlossen 2026-10-04) — ✅ umgesetzt 2026-10-04 (im Spiel getestet)
- Im Einstellungsfenster gibt es eine Checkbox **„TWF-Nameplates“** (EN: „TWF nameplates“). Tooltip erklärt: an = TWF-Nameplates statt Blizzard, aus = Blizzard-Original.
- Ist sie an: Die originalen Gegner-Nameplates **und die freundlichen Nameplates** (siehe L) werden **optisch** ausgeblendet. Sie bleiben im Spiel eingeschaltet, damit TWF weiter die Daten bekommt.
- **Auch der anvisierte Gegner** bekommt im TWF-Modus eine **TWF-Nameplate** (bestätigt), keine Blizzard-Nameplate mehr. Sie hat zusätzlich eine **eigene Zauberleiste** (siehe K).
- **Ist sie aus:**
  - Es gelten **alle originalen Blizzard-Einstellungen**: Die Nameplates sehen aus und verhalten sich wie ohne TWF.
  - Die **TWF-Nameplates sind ausgeblendet**.
  - Die Checkbox schaltet also zwischen zwei Modi um: *Blizzard-Original* ↔ *TWF-Nameplates*.
  - Folge für die Technik: TWF darf beim Ausschalten nichts zurücklassen. Alle ausgeblendeten UnitFrames bekommen wieder `SetAlpha(1)`. Falls TWF jemals CVars ändert, wird der vorherige Wert gespeichert und beim Ausschalten wiederhergestellt.
  - Umschalten im Kampf: Das, was im Kampf erlaubt ist, passiert sofort; der Rest wird nach dem Kampf nachgeholt.
- **Gilt immer** (bestätigt): überall, nicht nur im Kampf oder in Instanzen. Welche Gegner eine TWF-Nameplate bekommen, regelt K (nur Gegner im Kampf).
- **Standard: AN** (Default `true` in `Config.lua`), die Originale sind also von Anfang an ausgeblendet.
- Damit verschwinden auch die Nameplates von Gegnern hinter Wänden bzw. außerhalb des Kampfs, die das Spiel sonst anzeigt (Hinweis des Nutzers).
- Die eigenen **TWF-Nameplates** sind in K beschrieben.
- Technik (Vorschlag):
  - Ausblenden per `nameplate.UnitFrame:SetAlpha(0)` bei `NAME_PLATE_UNIT_ADDED`.
  - **Test-Ergebnis T5h/T5i:** Blizzard setzt die Deckkraft beim Kampfbeginn zurück → zusätzlich `hooksecurefunc(UnitFrame, "SetAlpha", …)`, der jeden Wert ≠ 0 sofort wieder auf 0 setzt (getestet, funktioniert). Beim Zurückschalten auf Blizzard muss der Hook über ein Kennzeichen deaktiviert werden (Hooks lassen sich nicht entfernen).
  - Zauberleiste des Ziels (K): Blizzards eigene Leiste `UnitFrame.CastBarsContainer` mit `SetIgnoreParentAlpha(true)` sichtbar lassen (getestet, funktioniert, keine Fehler). Eigene Leiste geht nicht (`UnitCastingInfo` geheim, Blizzard-Vorlage im Addon-Frame wirft Fehler).
  - Das Ziel (für die Zauberleiste) wird über einen Frame-Vergleich erkannt (`nameplate == C_NamePlate.GetNamePlateForUnit("target")`), also ohne geheime Werte; Wechsel bei `PLAYER_TARGET_CHANGED`.
  - Eigenes Modul `Nameplates.lua`; alle Werte in `Config.lua`.
- Offene Fragen:
  - Was passiert mit Problem-Gegnern (rot/gelb) und den Ideen A/C? (Bleiben Ideen, solange nicht anders entschieden.)
- Vorher testen (Test 2): Funktioniert `SetAlpha(0)`/`(1)` außerhalb und **im Kampf**? Bleibt die ausgeblendete Nameplate anklickbar? (`SetAlpha(1)` wird zum Zurückschalten auf Blizzard gebraucht.)

## K. TWF-Nameplate: Lebensbalken in Ampelfarbe (vom Nutzer beschlossen 2026-10-04) — ✅ umgesetzt 2026-10-04 (im Spiel getestet)
- Die TWF-Nameplate zeigt den **Lebensbalken des Gegners**.
- Die **Farbe des Balkens ist die Ampelfarbe** des Aggro-Status, mit derselben Logik wie die Liste (`classify()`, eine einzige Quelle):

  | Bedrohungs-Status | Tank-Modus | DD/Heal-Modus |
  |---|---|---|
  | 3 = du hast sicher Aggro | grün | rot |
  | 2 = du hast Aggro, verlierst sie aber | **gelb/gold** | **gelb/gold** |
  | 1 = keine Aggro, aber kurz davor | **gelb/gold** | **gelb/gold** |
  | 0 = keine Aggro | rot | grün |

  - Die beiden Zwischenstufen (2 und 1) sind in **beiden** Modi **gelb/gold**, wie heute in der Liste (Nutzer-Entscheid 2026-10-04, statt Orange).
  - **Änderung gegenüber heute:** `classify()` macht Status 1 im Tank-Modus rot und Status 2 im DD/Heal-Modus rot. Weil Liste und Nameplates dieselbe Logik nutzen (Single Source), ändert sich das **auch für die Liste**.
  - Ungelesener Status (nil) wie heute: Tank = rot, DD/Heal = grün (bestätigt).

- **Optik des Balkens: im Stil des Zauberbalkens von SealTimersForever** (Blizzard-Cast-Bar-Look, gefällt dem Nutzer).
  - **Wiederverwenden (Regel 2):** In SealTimersForever gibt es schon `AtlasesAvailable()`, `StyleBar()` und `ApplyBarStyle()` mit den Atlanten `ui-castingbar-filling-standard` (Füllung, gold), `ui-castingbar-background` (±1 px), `ui-castingbar-frame` (±2 px), Höhe 11 px, Fallback auf eine schlichte Leiste, wenn ein Atlas fehlt. Den Ansatz übernehmen und in TWF als eigenes Hilfsmodul aufbauen. Alle Werte (Atlasnamen, Ränder, Höhe) kommen in `Config.lua`.
  - **Gelb/Gold** = die originale Füllung `ui-castingbar-filling-standard`.
  - **Getestet (T8c) ✔:** Grün = `ui-castingbar-filling-channel`, Rot = `ui-castingbar-interrupted`, Gold = `ui-castingbar-filling-standard`; alle drei vorhanden und passend.
  - **Rot und Grün im selben Stil, wenn möglich:** Blizzard hat dafür vermutlich eigene Cast-Bar-Füllungen, z. B. für unterbrochene (rot) und kanalisierte (grün) Zauber. Ob es die auf Forever gibt und wie sie heißen, muss getestet werden (`C_Texture.GetAtlasInfo`).
  - Fallback, falls es keine roten/grünen Atlanten gibt: die goldene Füllung entsättigen und einfärben, oder eine schlichte Leiste in Rot/Grün. Das wird nach dem Test entschieden.
- Umschalten Tank ↔ DD/Heal (Button im TWF-Fenster) wirkt sofort auch auf die Nameplates.
- **Welche Gegner bekommen eine TWF-Nameplate:** alle Gegner, die **im Kampf** sind, also grün, gelb und rot (bestätigt). Gegner außerhalb des Kampfs bekommen keine TWF-Nameplate.
- Die **Liste bleibt wie gehabt**: nur Problem-Gegner, Grün nur mit „Alle Kämpfe zeigen“.
- Gegner **ohne Bedrohungsdaten**: **blau** (bestätigt). Gemeint sind Gegner, die im Kampf sind, aber nicht mit dir bzw. deiner Gruppe, z. B. ein Mob, der gegen einen Fremden kämpft.
- **Inhalt der TWF-Nameplate** (bestätigt):
  - **Name** des Gegners
  - **Leben in %**
  - **Zauberleiste nur beim eigenen Ziel**; alle anderen Gegner bekommen keine Zauberleiste.
  - Das Ziel bekommt eine **TWF-Nameplate mit eigener Zauberleiste** (bestätigt). Bei einem Zielwechsel wandert die Zauberleiste mit.
  - *(Vorschlag Claude, offen)* Die Zauberleiste kommt ebenfalls im Cast-Bar-Stil (gleiches Hilfsmodul wie der Lebensbalken), unter dem Lebensbalken.
  - Technisches Risiko: Name, Leben und Zauberinfo (`UnitCastingInfo`) könnten im Kampf geheim sein. Prüfen, ob sich geheime Werte direkt anzeigen lassen (`SetText`/`SetValue`), ohne sie auszuwerten (Test 3 erweitern).
- Farben kommen aus `Config.lua` und gelten **gleich für Liste und Nameplates**.
- Offene Fragen:
  - Weitere Inhalte (z. B. Symbole): folgen ggf.
- **Technisches Risiko (Test 3):** `UnitHealth`/`UnitHealthMax` könnten im Kampf geheim sein. Prüfen, ob dann wenigstens `StatusBar:SetValue(geheimerWert)` funktioniert. Wenn beides nicht geht, muss eine Alternative besprochen werden.

## L (neu). Aggro-Ziel am Mob (vom Nutzer beschlossen 2026-10-12, ersetzt Version 1)
Die Markierung hängt nur noch am **Mob**, nicht mehr am Spieler. Keine freundlichen Nameplates, kein Gruppenfenster.
- **Tank-Modus:**
  - Greift der Mob **nicht dich** an (Heiler, DD oder ein zweiter Tank hat ihn), steht als **zweite Zeile über dem Mobnamen**: **Rollensymbol + Name des Angegriffenen**.
  - Bei einem zweiten Tank: Tank-Symbol + sein Name.
  - Der **eigene Name steht nie** dort. Greift der Mob dich an, bleibt die Zeile leer.
  - Spielername in **Klassenfarbe** (zum Start).
- **DD/Heal-Modus:**
  - Bei jedem Mob im Kampf **nur das Rollensymbol** dessen, der ihn hält (Tank, DD, Heiler), **mittig über** dem Mobnamen, ohne Name.
  - Hältst du den Mob selbst: **erst mal nichts**.
- **Ohne gesetzte Rolle:** DD-Symbol.
- **Beim blauen Balken keine Anzeige** (Nutzer-Entscheid 2026-10-13): Bist du selbst nicht im Kampf mit dem Mob, erscheinen weder Symbol noch Name. (Kurz eingebaut war ein Weg über das Ziel des Mobs; wieder entfernt, weil er in Instanzen nicht geht und es überall gleich sein soll.)
- **TWF-Liste:** bleibt, wie sie ist; **zusätzlich** das Symbol vor dem Mobnamen (kein Spielername).
- **Ein-/ausschaltbar:** Checkbox „Aggro-Ziel anzeigen“ (`symbolMarks`, Standard an) im Abschnitt Nameplates.
- Symbolsatz und Größen in `Config.lua` (`C.SYMBOLS`, `C.SYMBOL_LAYOUT`), leicht austauschbar.
- Umsetzung: `Symbols.lua` (Zeile über dem Mobnamen), `Detection.lua` (`ns.aggroHolder`), Symbolfeld in `List.lua`.
- Stand: ✅ umgesetzt, im Spiel getestet und committet am 2026-10-13; laut Nutzer auch in der Instanz getestet (2026-10-13).
- Beim Test angepasst: Symbol über dem Mob 20 px, Spielername in normaler Schriftgröße, Symbol in der Liste 18 px mit 5 px Abstand; Schlachtzugsymbol in der Liste abgeschaltet (`C.ROW.SHOW_RAID_MARK = false`), bis forever-bugs#166 behoben ist.

## L (alt, Version 1) — ZURÜCKGENOMMEN 2026-10-12
**Stand:** Version 1 war gebaut und teilgetestet, ist aber wieder aus `master` entfernt. Der Code liegt zur Ansicht im Git-Zweig `archiv/twf-symbole-v1` (Commit `d7687a8`). Alles Folgende beschreibt Version 1 und ist **keine gültige Anforderung mehr**, bis der Nutzer ein neues Konzept festlegt.
Erster Schritt zum Ausprobieren („anfangen und schauen, wie sich das macht“).
- **Szenario:** Ich tanke eine Gruppe Gegner und verliere bei einem Mob die Aggro.
  - Auf der **TWF-Nameplate dieses Mobs** erscheint das **Rollensymbol seines neuen Ziels**, z. B. das Heiler-Kreuz, wenn der Mob zum Heiler läuft.
  - **Gleichzeitig** bekommt der **Heiler dasselbe Symbol über den Kopf**.
- **Symbol über dem Kopf des Spielers** sitzt an seiner **freundlichen Nameplate** (die müssen an sein, siehe M). Ihre Optik hängt an der Checkbox „TWF-Nameplates“ (bestätigt):
  - **an:** Blizzards freundliche Nameplates sind **ausgeblendet**; über einem Spieler erscheint nur das Symbol, wenn ein Mob zu ihm wechselt.
  - **aus:** Die freundlichen Nameplates sind im Blizzard-Original sichtbar; das Symbol kommt zusätzlich darüber (sofern die Symbol-Markierung an ist).
- Das Symbol erscheint **auch in der TWF-Liste** vor dem Gegnernamen (bestätigt).
- Zwei Spieler mit derselben Rolle (z. B. zwei DDs) mit je einem Mob → beide Mobs zeigen dasselbe Symbol. **Für den Anfang okay** (bestätigt).
- **Optionen:** Die Symbol-Markierung ist im Einstellungsfenster **ein- und ausschaltbar** (Checkbox).
- Die Beschreibung oben gilt für den **Tank-Modus**.
- **DD/Heal-Modus** (vom Nutzer beschlossen 2026-10-04):
  - Normalerweise wird **kein Symbol** angezeigt (auch nicht bei Gelb, „kurz davor“).
  - Erst wenn **du selbst Aggro bekommst**, erhält **der Mob, der dich angreift**, ein Symbol auf seiner TWF-Nameplate.
  - Ist die Aggro wieder weg, verschwindet das Symbol.
  - Zweck: Du siehst sofort, **von welchem Mob** du die Aggro hast.
  - Du selbst bekommst im DD/Heal-Modus **kein** Symbol über den Kopf, nur der Mob (bestätigt).
  - Der Mob bekommt das **DD-Rollensymbol** (`ui-lfg-roleicon-dps`), unabhängig von deiner Rolle. (Ursprünglich Kampf-Symbol mit gekreuzten Schwertern; nach Test T8c als „hässlich“ verworfen, Nutzer-Entscheid 2026-10-04.)
    - Steht als eigener Eintrag im Symbolsatz in `Config.lua` (z. B. `AGGRO_SELF`), also genauso austauschbar.
- **Symbole: vorerst Rollensymbole (bestätigt), leicht austauschbar.**
  - Der Symbolsatz steht als **Tabelle in `Config.lua`** (Single Source): Rolle → Grafik, z. B. `TANK = "ui-lfg-roleicon-tank"`, `HEALER = "ui-lfg-roleicon-healer"`, `DAMAGER = "ui-lfg-roleicon-dps"`, plus `NONE` für „keine Rolle gesetzt“ = **DD-Rollensymbol** (statt Kampf-Symbol, nach T8c), also dieselbe Grafik wie `AGGRO_SELF`.
  - Jeder Eintrag darf zusätzlich einen **Bildausschnitt** (TexCoords) haben, für Dateien mit mehreren Symbolen in einem Bild.
  - Jede Grafik darf ein **Atlas-Name oder ein Dateipfad** sein (auch eigene `.tga`/`.blp` im Addon-Ordner); der Code erkennt das selbst (`C_Texture.GetAtlasInfo`). Gibt es einen Atlas nicht, wird automatisch das Ersatzsymbol genommen.
  - Größe, Versatz über der Nameplate bzw. dem Kopf stehen ebenfalls in `Config.lua`.
  - Austauschen = **nur** die Tabelle in `Config.lua` ändern, kein anderer Code. Später ggf. auch andere Sätze (Raid-Marker, Klassensymbole) als weitere Tabelle.
  - Quellen zum Aussuchen: https://wago.tools/db2/UiTextureAtlasMember?filter[CommittedName]=roleicon (Atlas-Namen), https://wago.tools/files (Dateien mit Vorschau). Auf Forever per Test prüfen, was davon existiert.
- Ermittlung des neuen Ziels: pro Gruppenmitglied `UnitDetailedThreatSituation(partyN/raidN, mob)` prüfen, wer `isTanking` ist (nicht geheim, weil Gruppen-Token).
- Offene Fragen:
  - **Instanzen:** Erlaubt Blizzard dort keine freundlichen Nameplates, kommt das Symbol stattdessen ans Gruppenfenster → testen.
  - **Rolle erkennen:** `UnitGroupRolesAssigned` liefert in Classic oft „NONE“, weil keiner eine Rolle gewählt hat. Dann wird das **DD-Rollensymbol** gezeigt (entschieden, nach T8c). Forever 1.60.1 hat laut API-Änderungen Rollenabfrage (Role Poll) eingebaut → testen, was `UnitGroupRolesAssigned` dort liefert.
- **Bekannte Grenze (Blizzard-Sperre, gemessen 2026-10-04):** In Instanzen sind freundliche Nameplates gesperrt (`IsForbidden`). Dort bleiben Mitspieler-Balken im Original sichtbar, und das Symbol über dem Kopf geht nicht. Ersatz: Symbol **immer zusätzlich am Gruppenfenster** (Nutzer-Entscheid „immer“), Modul `GroupFrames.lua`, kompakte Party-/Raidfenster.
- Tests dazu:
  - `UnitDetailedThreatSituation("partyN", mob)` im Kampf (Test 3 der alten Liste)
  - `UnitGroupRolesAssigned("partyN")`
  - Freundliche Nameplates + Symbol über dem Kopf, auch in einer Instanz

## M. Hinweis-Fenster: alle nötigen Spiel-Optionen (vom Nutzer beschlossen 2026-10-04) — ✅ umgesetzt 2026-10-04 (im Spiel getestet; freundliche Nameplates werden geprüft, sobald L die Einstellung `symbolMarks` bringt; Zurückstellen alter Werte kommt mit L; Knopf „Spiel-Optionen öffnen“ per `C.HINT.SHOW_OPTIONS_BUTTON` abschaltbar, Entscheidung offen)
**Änderung 2026-10-12:** Freundliche Nameplates werden **nicht mehr verlangt** (Nutzer-Entscheid, Schritt zurück zusammen mit L). Geprüft werden derzeit nur die Gegner-Nameplates. Hatte TWF die freundlichen Nameplates eingeschaltet, stellt es einmalig den alten Wert zurück.
- Das bestehende Hinweis-Popup beim Login (heute nur „Gegner-Nameplates an“, CVar `nameplateShowEnemies`) wird erweitert: Es nennt **alle Spiel-Optionen**, die TWF für einen sauberen Betrieb braucht.
- Neu dazu: **Nameplates für Spieler (freundliche Nameplates)** müssen an sein (für L, Symbol über dem Kopf).
- **Vorher genau ermitteln (Analyse + Test auf Forever):** Welche Optionen bzw. CVars braucht TWF wirklich, wofür, und was passiert, wenn eine fehlt? Kandidaten:

  | Option (Spielmenü) | CVar | wofür | Status |
  |---|---|---|---|
  | Gegner-Nameplates | `nameplateShowEnemies` | Erkennung, TWF-Nameplates (J/K) | heute schon im Hinweis |
  | Freundliche Nameplates | `nameplateShowFriendlyPlayers` (Forever, T9); `nameplateShowFriends` gibt es dort nicht | Symbol über dem Spieler (L) | **neu** |
  | Nameplates immer anzeigen (nicht nur im Kampf) | `nameplateShowAll` | Gegner erkennen, bevor sie angreifen? | prüfen, ob nötig |
  | Sichtweite der Nameplates | `nameplateMaxDistance` | wie weit TWF Gegner sieht | prüfen |
  | Nameplates hinter Wänden | `nameplateOccludedAlphaMult` | nur Optik, für TWF evtl. egal | prüfen |
  | Ggf. Gegner-Begleiter/Totems/Minions | `nameplateShowEnemyPets` u. a. | prüfen | prüfen |

- **Robust gegen Umbenennungen (Beta):** Pro Option steht in `Config.lua` eine Liste möglicher CVar-Namen; TWF nimmt den ersten, den es gibt.
- Das Ergebnis der Analyse kommt als **feste Liste in `Config.lua`** (Single Source): CVar, Sollwert, wofür, ab welcher Funktion nötig.
- **Prüfung beim Start (bestätigt):** Bei jedem Login bzw. `/reload` prüft TWF, ob alle Spiel-Optionen so stehen, wie das Addon sie braucht. Das Popup erscheint nur, wenn etwas fehlt.
- **Erneute Prüfung beim Schließen des Einstellungsfensters (bestätigt):** Wurde z. B. eine Funktion eingeschaltet, die eine weitere Spiel-Option braucht, erscheint der Hinweis direkt danach.
- **Nur was gebraucht wird (bestätigt):** Der Hinweis prüft nur, was die **eingeschalteten** Funktionen brauchen (z. B. freundliche Nameplates nur, wenn die Symbol-Markierung aus L an ist).
- **Statusliste mit Knopf (bestätigt):** Das Popup zeigt jede Option als Zeile mit Status ✔/✘ und hat einen Button **„Jetzt einschalten“** (nur außerhalb des Kampfs). TWF merkt sich die alten Werte und stellt sie wieder her, wenn die Funktion ausgeschaltet wird (siehe J).
- **Checkbox „nicht mehr zeigen“ entfällt (bestätigt):** Das Popup kommt nur, wenn etwas nicht passt, deshalb wird die Checkbox nicht mehr gebraucht.
  - Folgen: Der Befehl `/twf hint reset` und die Einstellung `db.hideNameplateHint` sind dann überflüssig. Der alte Key in vorhandenen SavedVariables wird einfach ignoriert (kein Absturz, Regel 10/26).
  - `/twf hint` **bleibt** als Test-Befehl (bestätigt).
  - **(bestätigt)** `/twf hint` öffnet das Popup **immer**, auch wenn alles passt, damit man die Statusliste (✔/✘) zum Testen sieht. Er erscheint nicht in der Spieler-Hilfe.
- Texte im Popup zweisprachig (G).

## N. Name bei Gegnern außerhalb des Kampfs (vom Nutzer beschlossen 2026-10-13)
- Problem: Aus der Ferne zeigt das Spiel den Namen über dem Gegner. Kommt man näher, erscheint die Nameplate (deren Blizzard-Optik TWF ausblendet), und der Name ist weg, bis der Kampf beginnt und die TWF-Nameplate erscheint.
- **Anforderung:** Gegner **außerhalb des Kampfs** zeigen im TWF-Modus **nur ihren Namen** (kein Balken), **so wie im Original**: **rot** für feindliche, **gelb** für passive/neutrale Gegner.
- Sobald der Kampf beginnt, erscheint wie bisher die TWF-Nameplate mit Balken.
- Umsetzung (2026-10-13): TWF zeichnet den Namen **selbst**, in derselben Schrift und an derselben Stelle wie bei der vollen TWF-Nameplate, nur ohne Balken; Farbe über `UnitSelectionColor(unit)` (lesbar getestet: Farbe, Reaktion, Feind). Blizzards eigener Namenstext der Nameplate (`UnitFrame.name`) war ein erster Versuch und ist **grau**, deshalb verworfen.
- Stand: ✅ umgesetzt, im Spiel getestet, Baseline `twf-baseline-2026-10-13`.

## O. Hinter Wänden keine TWF-Nameplates (vom Nutzer beschlossen 2026-10-13)
- **Präzisiert vom Nutzer (2026-10-13):** Hinter Wänden soll nur der **Name der Zwischenebene** verschwinden (Gegner außerhalb des Kampfs, nicht anvisiert). Das **Schlachtzugsymbol bleibt sichtbar**. (Erste Fassung „gar nichts anzeigen“ war zu weit gegriffen.)
- Hintergrund: Blizzard dunkelt Nameplates hinter Wänden nur ab (`nameplateOccludedAlphaMult`, beim Nutzer 0.4). Der TWF-Name im Nur-Name-Zustand ignoriert Blizzards Deckkraft (für kräftiges Rot) und wäre hinter Wänden voll sichtbar.
- Umsetzung (2026-10-13): `nameplate:GetAlpha()` ist lesbar (gemessen: frei 0,6, hinter einem Baum 0,23). `ns.isOccluded()` in `Nameplates.lua` erkennt verdeckte Nameplates an der Deckkraft (Schwelle `C.NAMEPLATES.OCCLUDED_ALPHA = 0.5`); dann blendet TWF den Namen im Nur-Name-Zustand aus. Schlachtzugsymbol, Balken (Kampf/Ziel) und Aggro-Zeile bleiben wie sie sind. Die Spiel-Option wird nicht verändert.
- Stand: ✅ umgesetzt, im Spiel getestet, Baseline `twf-baseline-2026-10-13`. Balken im Kampf/beim Ziel bleiben hinter Wänden sichtbar (vom Nutzer bestätigt).

## P. Aggro in % links im TWF-Balken (vom Nutzer beschlossen 2026-10-16)
- **Anforderung:** Im TWF-Balken steht **links die eigene Aggro in %**, **rechts** wie bisher das **Leben in %**.
- Wert: eigene Bedrohung auf den Mob (`UnitDetailedThreatSituation('player', nameplateN)`, skalierter Prozentwert; 100 % = du hast bzw. ziehst die Aggro). Leer, solange du nicht auf der Bedrohungsliste stehst (blauer/grauer Balken).
- Einstellung: Checkbox **„Aggro-% am Balken“** im Abschnitt Nameplates, Standard **an** (`db.threatPct`).
- Geheime Werte werden nur an den Text weitergereicht (`SetFormattedText`), nie verglichen. Beleg, dass es auf WoW Forever geht: Threat Plates 13.3 und Forever Threat 1.23 zeigen den Wert an (nur angesehen, kein Code übernommen; Threat Plates ist GPL).
- Werte in `C.NAMEPLATES.THREAT_PCT_X` / `THREAT_PCT_FORMAT`; Debug-Meldungen (einmalig): Wert geheim, Anzeige fehlgeschlagen; Umschalten der Checkbox.
- **Getestet 2026-10-17 (draußen, allein):** Über `nameplateN` sind Prozent, Roh-Prozent und Rohwert von `UnitDetailedThreatSituation` **geheim**, aber **live**: Der Rohwert eines **nicht anvisierten** Mobs steigt sichtbar mit (an `SetFormattedText` weitergereicht, Weihe auf zwei Mobs). TWF zeigt also auf allen Nameplates aktuelle Aggro-% – andere Addons (NKThreat, Tiny Threat Plus, ThreatDiff) halten das auf Forever für unmöglich, weil sie mit den Werten rechnen wollen (Abstand zum Zweiten); Rechnen/Vergleichen bleibt verboten.
- **Instanz-Test 2026-10-17:** Aggro-% erscheinen und ändern sich auch in der Instanz, auch bei nicht anvisierten Mobs (Nutzer).
- Stand: ✅ gebaut 2026-10-16, getestet allein, in der Gruppe und in der Instanz (2026-10-17). In 0.3 pro Zustand schaltbar (V).

## Q. Graue Balken auch außerhalb des Kampfs + Leuchtrahmen am Ziel (vom Nutzer beschlossen 2026-10-16, war Idee I7) — **in 0.3 durch Anforderung V ersetzt** (Einstellungen jetzt in der Tabelle im Reiter Nameplates)
- **Checkbox „Balken auch außerhalb des Kampfs“** im Abschnitt Nameplates, Standard **aus** (`db.barsOutOfCombat`). An: Gegner außerhalb des Kampfs bekommen statt nur des Namens (Anforderung N) einen **grauen Balken** wie heute dein Ziel außerhalb des Kampfs. Aus: wie bisher.
- ~~**Dein Ziel außerhalb des Kampfs** (grauer Balken) bekommt einen **hellgelb leuchtenden, pulsierenden Rahmen** (`C.NAMEPLATES.GLOW`). Gleicher Rahmen-Code wie die Ziel-Zeile in der Liste (`ns.createGlow` in `Utils.lua`, aus `List.lua` herausgezogen).~~ **Vom Nutzer wieder herausgenommen (2026-10-16).** Der gemeinsame Rahmen-Code bleibt (Liste, Anforderungen S und T).
- Stand: ✅ gebaut 2026-10-16, getestet. In 0.3 durch V ersetzt („Balken zeigen“ bei „Außer Kampf“).

## S. Rot blinkender Rahmen bei Aggro-Problem (vom Nutzer beschlossen 2026-10-16) — **in 0.3 durch Anforderung V ersetzt** (Einstellungen jetzt in der Tabelle im Reiter Nameplates)
- **Gelbe und rote** TWF-Balken bekommen einen **rot blinkenden Rahmen** (`C.NAMEPLATES.ALARM`: rot, 3 px, 0,3 s, Deckkraft 1 → 0,1). Gleicher Rahmen-Code wie der Ziel-Rahmen (`ns.createGlow`).
- Gilt für **alle Mobs** (nicht nur das Ziel) und in **beiden Modi**: Tank = du verlierst die Aggro, DD/Heal = du ziehst Aggro.
- Checkbox **„Rot blinkender Rahmen“** im Abschnitt Nameplates, Standard **an** (`db.alarmFrame`).
- Der Rahmen erbt die Deckkraft des Balkens (Anforderung R), ist bei anderen Gegnern also etwas blasser als beim Ziel.
- Stand: ✅ gebaut 2026-10-16, getestet inkl. DD/Heal-Modus und in der Instanz (2026-10-17). In 0.3 durch V ersetzt.

## T. Anderer Tank hält den Mob: braun (vom Nutzer beschlossen 2026-10-16, war Idee I5)
- **Nur Tank-Modus.** Hält ein **anderer Spieler mit der Rolle Tank** (`UnitGroupRolesAssigned`) den Mob, wird aus **Rot → Braun**, an der Nameplate **und in der Liste** (braune Zeile, eigener Tooltip). **Kein Blinkrahmen** bei braun. **Warnton bleibt** (braun zählt wie eine Verschlechterung von grün).
- Ziehst du dem anderen Tank gleich die Aggro ab (Stufe 1 → gelb), bleibt der Balken **gelb** und bekommt einen **gelb blinkenden** Rahmen (`C.NAMEPLATES.ALARM_PULL`) statt des roten.
- Hält ihn ein DD/Heiler oder hat der andere Tank keine Rolle zugewiesen: unverändert rot. **DD/Heal-Modus unverändert.**
- Umsetzung: `ns.withOtherTank` + `ns.groupRole` in `Detection.lua` (eine Quelle für Liste und Nameplates; Rollenabfrage aus `Symbols.lua` dorthin verschoben), Halter über das vorhandene `ns.aggroHolder`. Farbe `C.COLOR.brown`, Füllung entsättigt + getönt wie Blau/Grau.
- Stand: ✅ gebaut 2026-10-16, in der Gruppe (braun + gelb blinkend beim Abziehen) und in der Instanz (braun) getestet (Nutzer, 2026-10-17).

## U. Fremde Mobs dunkelgrau (vom Nutzer beschlossen 2026-10-16, war Idee I2)
- Mobs, die einer **anderen Gruppe gehören** (keine EP, keine Beute; im Original ausgegraut), bekommen einen **dunkelgrauen Balken** (`C.COLOR.foreign`), **ohne Ampelfarbe und ohne Blinkrahmen** (Variante a).
- Sie erscheinen **nicht in der Problem-Liste** und lösen keinen Warnton aus, auch wenn du auf ihrer Bedrohungsliste stehst.
- Erkennung: `ns.isForeign` (`UnitIsTapDenied`) in `Detection.lua`; lesbar über Nameplate-Token, auch im Kampf (getestet 2026-10-16). Geheim/unlesbar gilt als „nicht fremd“.
- Debug: einmalige Meldung „Fremder Mob erkannt“. Tooltip „TWF-Nameplates“ erklärt den dunkelgrauen Balken (DE/EN).
- Stand: ✅ gebaut 2026-10-16, draußen getestet („passt“). In Instanzen nicht relevant (keine fremden Gruppen).

## Y. Übersetzungen über GitHub verbessern (vom Nutzer beschlossen 2026-10-17, Version 0.3)
- **Eine Datei pro Sprache:** `Locales/enUS.lua` (Vorlage, immer geladen = Rückfall), `deDE.lua`, `esES.lua` (esES + esMX), `frFR.lua`; gleiche Reihenfolge der Schlüssel, Kopf mit Regeln für Übersetzer. Vorher eine `Locales.lua`.
- **`TRANSLATING.md`** (DE/EN): Dateien, Regeln (Schlüssel nie ändern, `%s`/`%d`/`\n` behalten, keine `"`), Einreichen per „Edit this file“ → Pull Request, neue Sprache anlegen, Testen.
- **GitHub-Issue-Vorlage** „Übersetzung verbessern / Improve translation“ (`.github/ISSUE_TEMPLATE/translation.yml` im Repo).
- **Prüfskript 5** (`release/pruefung/5-sprachen.py`): Sprachdateien gegen die Vorlage, auch für eingereichte Übersetzungen.
- Patchnotes 0.3 verlinken die Anleitung in allen vier Sprachen. Skripte (Prüfung, Paket) können jetzt Unterordner.
- Stand: gebaut 2026-10-17. Test im Spiel: Sprache bleibt richtig (Deutsch), keine Lua-Fehler – offen.

## X. Live-Aggro-% in der Liste (vom Nutzer beschlossen 2026-10-17, Version 0.3)
- Jede Listenzeile zeigt **ganz links** deine **Live-Aggro in %**, dahinter Ampelpunkt, Symbol, Name.
- Checkbox **„Aggro-% in der Liste“** unter Allgemein → Anzeige, Standard **an**. Textfarbe = „Aggro-%-Farbe“ des Zustands aus der Tabelle (Reiter Nameplates).
- Wert aus `UnitDetailedThreatSituation('player', token der Zeile)`, geheim → nur an `SetFormattedText` weitergereicht (vor dem nil-Vergleich auf „geheim“ prüfen). Kein Wert → Feld leer, Zeile bleibt. Sortierung unverändert (nach Ampel).
- Testzeilen zeigen Beispielwerte (100/87/64 %).
- Offen/ungetestet: Zeilen, deren Token kein Nameplate ist (z. B. `party1target`, Mob ohne Nameplate) – liefern evtl. keinen Wert; Instanz.
- Stand: ✅ gebaut 2026-10-17, im Spiel getestet, auch in der Instanz (Nutzer: Aggro-% live auch bei nicht anvisierten Mobs, Ampel/Blinken, Liste/Fensterhöhe, keine Lua-Fehler). Teil von 0.3.

## W. Fensterhöhe wächst mit der Zahl der Gegner (vom Nutzer beschlossen 2026-10-17, Version 0.3)
- Unter „Allgemein“ Abschnitt **„Fenster“** mit zwei Reglern (Anzahl, nicht %): **Min. Zeilen** (1–15, Standard 5) und **Max. Zeilen** (1–30, Standard 10). Die Regler ziehen sich gegenseitig mit, damit Min. ≤ Max. bleibt.
- Das TWF-Fenster ist mindestens so hoch wie für „Min. Zeilen“ und wächst **nach unten** mit der Zahl der Gegner bis „Max. Zeilen“; darüber wird abgeschnitten (Gesamtzahl im Kopf).
- **Testzeilen an:** Das Fenster zeigt immer „Max. Zeilen“ (Beispielzeilen werden wiederholt).
- Von Hand nur noch die **Breite** ziehbar; die gespeicherte Höhe (`db.height`) und die feste Grenze `C.ROW.MAX` entfallen.
- Umsetzung: `ns.heightForRows` (Window.lua), Höhe in `ns.refresh` (List.lua), Regler mit `count`/`keepBelow`/`keepAbove` (Config/Settings).
- Stand: ✅ gebaut und im Spiel getestet 2026-10-17, auch in der Instanz. Teil von 0.3.

## V. Aussehen pro Zustand einstellbar, Reiter im Einstellungsfenster, Rolle Tank/DD/Heal (vom Nutzer beschlossen 2026-10-17, Version 0.3)
- **Einstellungsfenster mit Reitern** „Allgemein“ und „Nameplates“, beide gleich groß (760 px breit, Höhe = längster Inhalt, springt beim Reiterwechsel nicht). Die Höhe passt sich an „Farben gleich“ an: an = eine Tabelle (niedriger), aus = drei Tabellen (Nutzer, 2026-10-17). „Allgemein“ in drei Spalten (`{ type = 'column' }` in `C.OPTIONS`).
- **Reiter Nameplates:** Tabelle mit **einer Spalte pro Zustand** (Sicher, Unsicher, Problem, Anderer Tank, Ziehst vom Tank, Nicht mit dir, Außer Kampf, Fremde Gruppe) und den Zeilen **Farbe** (Klick → Blizzards Farbwähler, auf Forever getestet), **Deckkraft** (Anzeige in %, Klick → Popup mit Schieberegler 0–100 %), **Blinken** (Checkbox), **Rahmenfarbe** (nur sichtbar, wenn Blinken an; Farbwähler), **Balken zeigen** (Checkbox; aus = nur der Name).
- **Checkbox „Farben für alle Modi gleich“** (Standard an): eine Tabelle für alle Modi, Farben wie bisher an die Ampel-Bedeutung gebunden (Tank: Rot = Aggro verloren; DD/Heal: Rot = Aggro gezogen). **Aus:** drei Tabellen untereinander (Tank, DD, Heal), jede mit eigenen Werten; in DD/Heal sind „Anderer Tank“ und „Ziehst vom Tank“ ausgegraut. Die gespielte Rolle ist mit „(aktiv)“ markiert.
- **Knopf „Farben zurücksetzen“** im Reiter Nameplates: alle Tabellen auf Standard (= Aussehen wie 0.2).
- **Deckkraft:** Ziel und hinter Wänden weiter als Regler unter „Allgemein“ (Ziel gilt auch hinter Wänden); sonst die Deckkraft des Zustands. Regler „andere Gegner“ entfernt.
- **Entfernt:** Checkbox „Rot blinkender Rahmen“ (S) und „Balken auch außerhalb des Kampfs“ (Q) – beides steckt jetzt in der Tabelle (Blinken pro Zustand, „Balken zeigen“ bei „Außer Kampf“). Feste Rahmen `ALARM`/`ALARM_PULL` und feste Füllungen ersetzt: alle Balken entsättigt + getönt (`C.NAMEPLATES.FILL`), Blinkstärke/-tempo in `C.NAMEPLATES.BLINK` (vorbereitet, später pro Zustand einstellbar).
- **Dein Ziel bekommt immer einen Balken**, auch wenn „Balken zeigen“ für seinen Zustand aus ist (wie bisher beim grauen Ziel).
- **Rolle dreiteilig** Tank / DD / Heal: Einstellungsfenster (drei Knöpfe), Knopf im TWF-Fenster schaltet reihum, `/twf role` ebenso. DD und Heal verhalten sich bei der Aggro gleich, nur die Farben können getrennt sein.
- **Liste:** Punktfarbe folgt der Balkenfarbe des Zustands.
- **Umstieg von 0.2** (einmalig, `PlateStates.lua`): Deckkraft „andere Gegner“ → Deckkraft aller Zustände, „Rot blinkender Rahmen“ aus → Blinken aus, „Balken außerhalb des Kampfs“ an → „Balken zeigen“ bei „Außer Kampf“.
- Umsetzung: neue Datei `PlateStates.lua` (Daten, Standardwerte, Umstieg), `Settings.lua` (Reiter, Tabelle, Farbwähler, Deckkraft-Popup), `Nameplates.lua` (Zustand → Aussehen), Debug-Code `PLATES` (022).
- **Ergänzt 2026-10-17:** Zeilen **„Aggro-%“** (Checkbox pro Zustand, Standard an) und **„Aggro-%-Farbe“** (Textfarbe pro Zustand, Farbwähler, nur sichtbar wenn Aggro-% an; Standard weiß). Checkbox „Aggro-% am Balken“ unter Allgemein entfernt; Umstieg: war sie aus, ist Aggro-% in allen Zuständen aus (`C.PLATE_VERSION` = 2). Zellen-Arten in `C.PLATE_ROWS` (`kind`, `field`, `needs`).
- Stand: ✅ gebaut und im Spiel getestet 2026-10-17: Tests 1–4 (Fenster/Bedienung, Wirkung am Balken, Modi, Umstieg von 0.2) und Instanz-Test (Ampel, Blinken, Aggro-%) i. O. (Nutzer). Veröffentlicht als 0.3.

## R. Deckkraft der TWF-Balken als Regler (vom Nutzer beschlossen 2026-10-16) — **in 0.3 teilweise durch V ersetzt:** Regler „andere Gegner“ entfällt (Deckkraft pro Zustand); „Ziel“ und „hinter Wänden“ bleiben unter „Allgemein“
- Drei Schieberegler im Abschnitt Nameplates, 10-%-Schritte: **Ziel** (`alphaTarget`, Standard 100 %), **andere Gegner** (`alphaOther`, 60 %), **hinter Wänden** (`alphaOccluded`, 30 %).
- TWF setzt die Deckkraft selbst (`SetIgnoreParentAlpha(true)`), Blizzards Abdunkeln zählt für die Balken nicht mehr. Dein **Ziel** behält den Ziel-Wert auch **hinter Wänden** (Nutzer-Entscheid).
- Die Aggro-Ziel-Zeile über dem Mob (Anforderung L) übernimmt die Deckkraft des Balkens. Zauberleiste und Schlachtzugsymbol bleiben voll sichtbar. Nur-Name-Zustand unverändert (voll sichtbar, hinter Wänden ausgeblendet).
- Stand: ✅ gebaut 2026-10-16, getestet. In 0.3 teilweise durch V ersetzt; Ziel/Wand-Regler bleiben.

## TODO (nächste Sitzung)
- ✅ Test 18 aus `TESTS-L-AGGROZIEL.md` (Debug-Zeilen) bestanden (2026-10-17). Keine offenen Tests mehr.
- ✅ Die Neuerungen vom 13.10. (Name außerhalb des Kampfs, Schlachtzugsymbol, Name hinter Wänden) wurden laut Nutzer **auch in der Instanz getestet** (bestätigt 2026-10-13).
- Siehe auch „TODO vor Veröffentlichung“.

## Ideen (keine Anforderungen)
**Alles hier ist nur besprochen** (Nutzer, 2026-10-13: „alles, was wir gerade reden, ist Ideen“). Eine Idee wird erst zur Anforderung, wenn der Nutzer das ausdrücklich sagt. Einiges muss vorher im Spiel getestet werden.

- **I1 Farbverlauf des Lebensbalkens nach Bedrohung** (Idee des Nutzers, 2026-10-13; **keine Anforderung**, erst testen): Statt der festen Ampelstufen ein Verlauf grün → gelb/orange → rot nach dem Bedrohungs-Prozentwert (den zeigt Blizzards Tooltip am Gegner). Rechnen mit geheimen Werten ist verboten; möglicher Weg: **Farbkurve** (`C_CurveUtil.CreateColorCurve`, Punkte 0/50/100 %), das Spiel wertet den geheimen Wert aus (`K:Evaluate(prozent):GetRGB()`), TWF reicht nur die Farbe an den Balken. Braucht eine neutrale, einfärbbare Füllung (wie heute Blau/Grau). Vorher im Kampf testen (Zeilen stehen im Chat-Verlauf vom 2026-10-13 und hier):
  1. `/run S=function(v)return issecretvalue and issecretvalue(v)and"GEHEIM"or tostring(v)end print("S bereit")`
  2. `/run local a,b,c,d,e=UnitDetailedThreatSituation("player","target")print("tankt",S(a),"status",S(b),"prozent",S(c),"roh%",S(d),"wert",S(e))` → „prozent“ GEHEIM/Zahl = weiter, nil = Idee tot
  3. `/run print("Kurve:",C_CurveUtil and C_CurveUtil.CreateColorCurve and"JA"or"nein")`
  4. `/run K=C_CurveUtil.CreateColorCurve()K:AddPoint(0,CreateColor(0,1,0))K:AddPoint(50,CreateColor(1,.8,0))K:AddPoint(100,CreateColor(1,0,0))Q=Q or UIParent:CreateTexture()Q:SetSize(40,40)Q:SetPoint("CENTER",0,120)Q:SetColorTexture(1,1,1)print("bereit")`
  5. `/run local _,_,p=UnitDetailedThreatSituation("player","target")print("Ergebnis:",pcall(function()Q:SetVertexColor(K:Evaluate(p):GetRGB())end))` → true + Quadrat ändert die Farbe = machbar

- **I2 Fremde Gegner erkennbar machen** — ✅ **zur Anforderung U geworden (2026-10-16, dunkelgrau)**. (Idee des Nutzers für den nächsten Fix, 2026-10-13; **noch keine Anforderung**): Im Blizzard-Original sieht man an der Nameplate, ob ein kämpfender Gegner der eigenen Gruppe „gehört“ (EP/Beute) oder jemand anderem; fremde Gegner sind dort meist **grau**. Bei den TWF-Nameplates fehlt diese Information. Technik-Idee: `UnitIsTapDenied(unit)` (wahr = gehört anderen); vorher im Kampf testen, ob der Wert über `nameplateN` lesbar oder geheim ist. Zu klären: TWF nutzt Grau heute für „dein Ziel außerhalb des Kampfs“ und Blau für „kämpft, aber nicht mit dir“ → Farbbelegung neu ordnen.
  - **Getestet 2026-10-16 (draußen):** `UnitIsTapDenied` ist über `target` **und über den Nameplate-Token lesbar**, auch wenn du selbst im Kampf bist (Ausgabe `true`/`false`, nicht geheim). Hinweis: Die Nameplate hat evtl. kein `namePlateUnitToken`, Token über `UnitFrame.unit` holen. Ausweichweg falls später geheim: Blizzards Balkenfarbe (grau 0.9/0.9/0.9) lesen, wie ForeverThreatPlate.
  - Alte Testzeile (fremden Gegner im Kampf anvisieren): `/run S=function(v)return issecretvalue and issecretvalue(v)and"GEHEIM"or tostring(v)end print("fremd (target):",S(UnitIsTapDenied("target")))` und für alle Nameplates: `/run for _,p in ipairs(C_NamePlate.GetNamePlates())do local u=p.namePlateUnitToken print(u,S(UnitIsTapDenied(u)))end`

- **I3 Weitere Sprachen** (Idee des Nutzers, 2026-10-13; **keine Anforderung**, Details werden erst geklärt, wenn es umgesetzt wird): Spielertexte zusätzlich auf **Spanisch, Französisch, Russisch und Chinesisch**. Umschaltung wie bisher über die Spielsprache, Englisch bleibt der Rückfall, Debug-Texte bleiben Deutsch. — **Spanisch und Französisch umgesetzt in 0.3 (2026-10-17)**; Russisch und Chinesisch weiter Idee.

- **I4 Drei Fenster: Problem-Liste, Fokus-Liste, Ziel-Liste** (Idee des Nutzers, 2026-10-13; **keine Anforderung**):
  - **Fenster 1, wie heute:** das TWF-Fenster mit den Problem-Gegnern. Bleibt unverändert.
  - **Fenster 2, Fokus (neu, per Option einschaltbar):** klassische Bedrohungsliste für das **Fokus-Ziel**. Das Fokus-Ziel wird dafür als Quelle aufgenommen.
  - **Fenster 3, Ziel (neu, per Option einschaltbar):** klassische Bedrohungsliste für das **aktuelle Ziel**, ein Single-Target-Fenster analog Omen.
  - „Klassische Liste“ = pro Gruppenmitglied eine Zeile bzw. ein Balken für **einen** Gegner, sortiert nach Bedrohung.
  - Beide neuen Fenster sind **einzeln schaltbar**, Standard: aus.
  - Zu klären mit dem Nutzer: Was steht in einer Zeile (Name in Klassenfarbe, Balken, Prozent, Kennzeichen für den Tank)? Wie viele Zeilen (z. B. Top 5/10 im Schlachtzug)? Gleicher Look wie das TWF-Fenster? Jedes Fenster einzeln verschiebbar/skalierbar/fixierbar, mit eigener gespeicherter Position? Was zeigt ein Fenster, wenn es kein Fokus bzw. kein Ziel gibt (ausblenden)? Gelten „Nur im Kampf“ / „Nur in Gruppe“ auch für die neuen Fenster?
  - Vorher testen: Welche Werte gibt der Client über `focus` und `target` für die **einzelnen Gruppenmitglieder** heraus? Über `target` war „tankt ja/nein“ lesbar, über `nameplateN` nur die einfache Stufe. Sind **Bedrohungs-Prozent** der Gruppenmitglieder lesbar oder geheim? (Die Mitbewerber melden, dass Werte z. B. bei Bossen geheim sind und die Liste dann unsortiert bleibt.) Geheime Werte lassen sich evtl. direkt an Balken/Text weiterreichen (wie beim Leben), dann aber ohne Sortierung.
  - Aufbau: **ein** Modul für die klassische Liste (z. B. `ThreatList.lua`), das zweimal verwendet wird (Quelle `focus` bzw. `target`), kein doppelter Code (Regel 2). Fenster-Rahmen vom bestehenden TWF-Fenster wiederverwenden. Werte in `Config.lua`, Texte in allen Sprachen, abgeschaltete Fenster kosten keine Leistung.

- **I5 Eigene Balkenfarbe, wenn ein anderer Tank den Mob hält** — ✅ **zur Anforderung T geworden (2026-10-16, Farbe braun)**. (Idee aus der Konkurrenzanalyse, vom Nutzer als „sehr gute Idee“ bewertet, 2026-10-13; **keine Anforderung**):
  - Heute ist ein Mob im Tank-Modus **rot**, sobald du ihn nicht hältst, auch wenn ihn der zweite Tank sicher hat. Das ist ein Fehlalarm, vor allem in Schlachtzügen mit zwei Tanks.
  - Neu: Hält ein **anderer Spieler mit der Rolle Tank** den Mob, bekommt der Balken eine eigene Farbe (Vorschlag: Lila, wie bei „Forever: Threat (Plates & Bar)“).
  - Technik ist vorhanden: `ns.aggroHolder` + `UnitGroupRolesAssigned` (wie beim Aggro-Ziel). Eine Quelle für Liste und Nameplate.
  - Zu klären: genaue Farbe; ob der Mob dann in der **Liste** überhaupt erscheint (kein Problem → eher nicht, außer bei „Alle Kämpfe zeigen“); ob der Warnton ausbleibt; Verhalten im DD/Heal-Modus (dort ist „Tank hält ihn“ schon grün); Füllung im Zauberbalken-Stil (lila gibt es nicht als Atlas → entsättigt + getönt wie Blau/Grau).

- **I6 Schlachtzugsymbol auch in der Liste anzeigen** (Idee des Nutzers, 2026-10-13; **keine Anforderung**): An der TWF-Nameplate ist das Symbol jetzt sichtbar, in der Liste fehlt es noch (dort per `C.ROW.SHOW_RAID_MARK = false` abgeschaltet).
  - Hürde: An der Nameplate zeichnet **Blizzard** das Symbol selbst (`UnitFrame.RaidTargetFrame`), dort muss TWF nichts lesen. Für die Liste braucht TWF die **Symbol-Nummer** (`GetRaidTargetIndex`), und die war im Kampf geheim (forever-bugs#166, Stand 13.10. offen). Blizzards Element lässt sich nicht einfach in die Liste kopieren.
  - Wege zum Testen: (1) erneut prüfen, ob die Nummer inzwischen lesbar ist; (2) Nummer **merken, solange sie lesbar ist** (außerhalb des Kampfs bzw. beim Ereignis `RAID_TARGET_UPDATE`) und im Kampf aus dem Merkzettel anzeigen, Zuordnung über GUID bzw. Token (in Instanzen ist die Gegner-GUID geheim → dort evtl. nur über den Token); (3) prüfen, ob sich ein geheimer Index direkt an eine Textur weiterreichen lässt (bisher nein, siehe `Marks.lua`).

- **I7 Schalter „Balken auch außerhalb des Kampfs zeigen“** — ✅ **zur Anforderung Q geworden (2026-10-16)**. (Wunsch eines Spielers, vom Nutzer als „gute Idee, zum Einschalten“ bewertet, 2026-10-16; **keine Anforderung**): Heute zeigt TWF bei Mobs außerhalb des Kampfs nur den Namen (Anforderung N), auch wenn die Blizzard-Nameplate schon sichtbar ist. Mit dem Schalter bekämen diese Mobs schon vorher einen Balken.
  - Gedacht als Einstellung, **Standard aus**; dann ändert sich für bisherige Nutzer nichts.
  - Offene Punkte (erst klären, wenn es umgesetzt wird): Farbe des Balkens vor dem Kampf (neutral grau wie beim Ziel?), Verhalten hinter Wänden (wie Anforderung O).
  - Verwandt: Die **Reichweite** der Nameplates bestimmt allein Blizzard (`nameplateMaxDistance`, Classic Era Standard 20 m, max. 41 m); ob WoW Forever mehr zulässt, ist noch ungetestet. TWF prüft selbst keine Entfernung.

- **I8 Vorschau im Einstellungsfenster** (Idee des Nutzers, 2026-10-16; **keine Anforderung**): Beispiel-Balken mit festen Testwerten (Ziel grün, anderer Gegner rot mit Blinkrahmen, hinter Wand gelb, anderer Tank braun, außerhalb des Kampfs grau), die sich sofort mit Reglern und Checkboxen ändern (Deckkraft, Aggro-%, Blinkrahmen, graue Balken, Rolle).
  - Aufbau: Bau-Code des TWF-Balkens aus `Nameplates.lua` in eine gemeinsame Funktion ziehen, die auch die Vorschau nutzt (kein doppelter Code). Liest keine Spielwerte.
  - Zu klären, wenn es umgesetzt wird: im Fenster (300 px breit, wird länger), weniger Balken, oder eigenes kleines Fenster daneben; Deckkraft wirkt auf dem dunklen Fensterhintergrund anders als vor der Spielwelt.

- **I9 Leuchtender bzw. pulsierender Rahmen statt Blinken** (Idee des Nutzers, 2026-10-17; **keine Anforderung**, „haut mich noch nicht um“): In der Tabelle statt Checkbox „Blinken“ eine Auswahl „Rahmen: aus / leuchten / pulsieren / blinken“ (evtl. „laufende Punkte“ wie LibCustomGlow).
  - Getestet 2026-10-17: Atlanten `UI-HUD-ActionBar-Proc-Loop-Flipbook`, `UI-HUD-ActionBar-IconFrame-Flash`, `bags-glow-white` vorhanden, `Nameplates-SelectionHighlight` nicht. `bags-glow-white` gestreckt um den Balken gefiel nicht.
  - Besser: weicher Schein aus vier Verlaufsstreifen (`SetGradient`, Farbe → transparent nach außen) + runde Ecken aus Vierteln von `Interface\GLUES\MODELS\UI_Draenei\GenericGlow64` (`SetTexCoord`). Ecken wirkten kleiner als die Streifen → Streifenbreite/Eckengröße/Zuschnitt abstimmen.
  - **Wichtig:** Alpha-Animation direkt auf Verlaufs-Texturen macht sie weiß → Schein in einen eigenen Rahmen legen und nur den Rahmen pulsieren lassen.
  - Testskripte (Probebalken, Regler `G(Streifen, Zuschnitt, Ecke, Helligkeit)`) stehen im Chatverlauf vom 2026-10-17.

## Offene Bugs
- **B2 Gegner doppelt in der Liste (gemeldet 2026-10-17, Instanz) — ✅ BEHOBEN 2026-10-17, in der Instanz getestet (Nutzer: kein Doppeleintrag mehr):** In Instanzen ist die GUID geheim; der Token war dann der Schlüssel, derselbe Mob stand als `target` und als `nameplateN` doppelt in der Liste. `UnitIsUnit` ist dort lesbar (getestet: Nameplate vs. target = true). Fix in `Detection.lua`: Schlüssel = Nameplate-Token desselben Mobs (`tokenKey`), weitere Token desselben Mobs (auch `partyNtarget` ohne Nameplate) werden per `UnitIsUnit` übersprungen; Ziel-Hervorhebung in der Liste über `UnitIsUnit(…, 'target')`. Debug-Code `MERGED` (023).

- **B1 Schlachtzugsymbole fehlen bei TWF-Nameplates (gemeldet 2026-10-04) — ✅ BEHOBEN 2026-10-13:** Blizzards Symbol wird zusätzlich umgesetzt (über dem Namen bzw. links vor dem Balken, `placeRaidIcon`). Blizzards `UnitFrame.RaidTargetFrame` bleibt per `SetIgnoreParentAlpha(true)` sichtbar (Symbol erscheint laut Nutzer wieder; Optik/Position noch zu beurteilen). Ursprüngliche Beschreibung: Sind die TWF-Nameplates an, sieht man Blizzards Schlachtzugsymbole (Totenkopf, Stern …) nicht mehr, sobald man nah dran ist. Ursache (vermutet): Nah dran zeigt Blizzard das Symbol an der Nameplate, deren Optik TWF ausblendet (aus der Ferne zeichnet das Spiel es selbst über dem Kopf). Lösungsidee: Blizzards Symbol-Element der Nameplate (vermutlich `UnitFrame.RaidTargetFrame`) per `SetIgnoreParentAlpha(true)` sichtbar lassen, wie bei der Zauberleiste (T5i), Position am TWF-Balken. Vorher testen: Feldname + ob es im Kampf und in Instanzen sichtbar bleibt.

## Veröffentlichung 0.3 — vorbereitet 2026-10-17
- Inhalt: Anforderungen **V**, **W** (Fensterhöhe wächst mit, Min./Max. Zeilen), **X** (Live-Aggro-% in der Liste), Sprachen **Español/Français** (G/I3) und Fix **B2** (doppelte Zeilen in Instanzen). V: (Reiter Allgemein/Nameplates, Tabelle pro Zustand mit Farbe, Deckkraft, Blinken, Rahmenfarbe, Balken zeigen; „Farben gleich“ oder je Tank/DD/Heal; Rolle dreiteilig). Tests 1–4 und Instanz-Test bestanden.
- Paket `release/ThreatWallForever-0.3.zip`, Changelog `release/ThreatWallForever-0.3-patchnotes.html`, Gesamtprotokoll `PATCHNOTES.html`.
- Achtung: neue Datei `PlateStates.lua` → TOC geändert, nach dem Update ist ein kompletter Neustart des Spiels nötig (steht in den Patchnotes).

## Veröffentlichung 0.2 — 2026-10-17 bei CurseForge veröffentlicht
- Inhalt: Anforderungen **P–U** (Aggro-% im Balken, graue Balken außerhalb des Kampfs, Deckkraft-Regler, rot blinkender Rahmen, zweiter Tank braun, fremde Mobs dunkelgrau). Allein und (T) in der Gruppe getestet; offen: Instanz-Test.
- Paket `release/ThreatWallForever-0.2.zip`, Changelog `release/ThreatWallForever-0.2-patchnotes.html` (nur 0.2), Gesamtprotokoll `PATCHNOTES.html`.
- Neues Logo „TWF als Burgmauer“ (`logo/twf-logo-mauer-*`, `release/logo-bauen.py`); das Schild-Logo war zu nah an ForeverThreatPlate.
- Offen: CurseForge-Beschreibung auf 0.2 bringen; Projektname/Kurzbeschreibung/Kategorien für die Suche (Vorschlag: „ThreatWall Forever – Aggro Warning & Threat Nameplates“). ✅ Screenshots bei CurseForge hochgeladen (Nutzer, 2026-10-17). Instanz-Test folgt.

## Veröffentlichung 0.1 — vorbereitet 2026-10-13
- ✅ Code bereinigt (eigener Commit): tote Variablen (`placePending`, `scroll`, `ns.ADDON`), ungenutzte Texte/Codes (`TT_CLICK`, `NO_NAMEPLATES`, `DEBUG_ON/OFF`), veraltete Kommentare; Debug-Texte komplett Deutsch (Dump, laufende Meldungen, `/twf mark`); Spieler-Hilfe ohne Entwickler-Befehle.
- ✅ TOC-Beschreibung (EN + DE) neu, ohne „Klick zum Zielwechsel“.
- ✅ `PATCHNOTES.html` (HTML, erst Deutsch, dann Englisch).
- ✅ `CURSEFORGE-BESCHREIBUNG.html` (erst Deutsch, dann Englisch), inkl. Bedeutung der Balkenfarben (Blau = noch nicht erfasst, aktiv eingreifen).
- ✅ Release-Paket `wow-addons/release/ThreatWallForever-0.1.zip` (nur Lua-Dateien, TOC, LICENSE; ohne Doku).
- ✅ Abschlusstest bestanden, `master` + Baseline-Tag gepusht, **Upload bei CurseForge durch den Nutzer am 2026-10-13** (wartet auf Freischaltung).
- ✅ Logo (`logo/`, gebaut mit `release/logo-bauen.py`; ab 0.2 neues Motiv „TWF als Burgmauer“ `twf-logo-mauer-*`, das Schild war zu nah an ForeverThreatPlate), Beschreibung und Patchnotes farbig gestaltet. KI-Hinweis: CurseForge verlangt keine Kennzeichnung von KI-Code (nur bei irreführenden Vorschaubildern); freiwilliger Satz in der Beschreibung wurde vorgeschlagen, Entscheidung offen.
- ✅ Entschieden: Der Knopf „Spiel-Optionen öffnen“ im Hinweis-Popup **bleibt** (`C.HINT.SHOW_OPTIONS_BUTTON = true`). Regel 5: Rechenschritte (`+ 0.5`, `/ 2`, `2 *`) sind erlaubt.

## Weitere Anforderungen
- (hier sammeln)

# Teil 2 — Ideen (NICHT beschlossen, nur besprochen)

Angeregt durch die Analyse von MiniMarkers (Verz, keine Lizenz → nur Ideen übernehmen, keinen Code). Wie das Ergebnis aussehen soll, ist noch offen.

## Grundprinzip
- Gegner-Nameplates bleiben im Spiel **an**, weil TWF die Daten braucht (sonst sieht TWF nur anvisierte Gegner).
- TWF liest **nichts Geheimes**. Es befestigt eigene Texturen an der Nameplate (`C_NamePlate.GetNamePlateForUnit(token)`) und vergibt Symbole selbst.

## Idee A. Ampel über dem Gegner
- Der Aggro-Status (rot/gelb/grün wie in der Liste) wird zusätzlich über dem Gegner angezeigt.
- Darstellung wählbar: Punkt / Rahmen oder Leuchten / Pfeil (nur bei Rot).
- Gleiche Logik wie die Liste: Tank- bzw. DD/Heal-Modus, nur Problem-Gegner, Grün nur mit „Alle Kämpfe zeigen“.
- Optionen: an/aus, Größe, Höhe (Versatz).
- Blizzards Lebensleiste nicht umfärben, weil das Spiel die Farbe zurücksetzt und die Leiste dann flackert.

## Idee B. Blizzard-Nameplates optisch ausblenden
- `UnitFrame:SetAlpha(0)`, sobald die Nameplate erscheint; der Basis-Rahmen bleibt (Position + Klickfläche).
- Die Ampel und die Symbole hängen am Basis-Rahmen und bleiben deshalb sichtbar.
- Option: immer / nur außerhalb von Instanzen / nie.
- Nebenwirkung: Leben, Zauberleiste und Debuffs sind weg; die unsichtbare Klickfläche über dem Kopf bleibt.

## Idee C. Lebensleiste gezielt wieder einblenden
- Weg 1 (bevorzugt): Blizzards UnitFrame für ausgewählte Mobs wieder auf `SetAlpha(1)` setzen. Dann ist das komplette Original zurück und es gibt kein Problem mit geheimen Werten.
- Weg 2 (optional): eigene Leiste. Nur möglich, wenn `UnitHealth` im Kampf nicht geheim ist.
- Auswahl: Problem-Gegner / aktuelles Ziel / alle im Kampf / keine.

## Idee D. Gleiche Symbole für Mob und Aggro-Spieler
- Bekommt ein Spieler (nicht der Tank) Aggro, vergibt TWF ihm ein Symbol (Raid-Grafiken `UI-RaidTargetingIcon_1..8`, selbst vergebene Nummer, also nicht geheim).
- Alle Mobs, die diesen Spieler schlagen, bekommen dasselbe Symbol. Wechselt der Mob das Ziel, wechselt auch das Symbol.
- Wenn der Spieler keine Aggro mehr hat, wird das Symbol nach ein paar Sekunden wieder frei.
- Wo die Symbole angezeigt werden:
  - TWF-Liste
  - über der Gegner-Nameplate
  - an Blizzards Gruppen- bzw. Raidfenster (eigener Frame, der dort angehängt wird)
- **Keine echten Raid-Marker** (`SetRaidTarget`): Die überschreiben die Marker des Tanks, brauchen Leiter-Rechte und springen ständig um.

## Idee E. Aggro-Halter in der Liste
- Klassen- oder Rollensymbol des Spielers mit Aggro vor dem Gegnernamen; Name im Tooltip; bei eigener Aggro „DU“.
- Option: Klasse / Rolle / aus.

## Gemeinsame Voraussetzung: Wen schlägt der Mob?
- Weg 1: `UnitDetailedThreatSituation(gruppenmitglied, mob)` für jedes Gruppenmitglied. Ist `isTanking` wahr, hat dieses Mitglied die Aggro. Klasse und Name stammen vom Gruppen-Token, sind also nicht geheim. Im Raid drosseln.
- Weg 2 (Fallback): `mobtarget` (z. B. `nameplate3target`), wahrscheinlich eher geheim.

## Offene Tests
Alle Machbarkeitstests stehen vollständig in `TESTS-MACHBARKEIT.md` (T1–T11).
