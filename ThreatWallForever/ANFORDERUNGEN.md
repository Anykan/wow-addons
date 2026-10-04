# ThreatWall Forever — Anforderungen & Ideen für die nächste Ausbaustufe

Status: **Sammelphase** (seit 2026-10-04). Noch nichts getestet, noch kein Code.

**Regel:** Nur was der Nutzer **klar als Anforderung angibt**, steht in Teil 1. Details, die Claude innerhalb einer Anforderung ergänzt hat, sind mit *(Vorschlag Claude, offen)* markiert, bis der Nutzer sie bestätigt. Alles, worüber wir nur reden oder was Claude vorschlägt, steht in Teil 2 als Idee. Aus einer Idee wird erst dann eine Anforderung, wenn der Nutzer das ausdrücklich sagt.

# Teil 1 — Beschlossene Anforderungen

## F. Einstellungsfenster statt Dropdown-Menü
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

## G. Zweisprachig DE/EN (gilt für ALLES, was der Spieler sieht)
- Alle sichtbaren Texte gibt es auf Deutsch und Englisch: Fenster, Einstellungsfenster, Dropdown, Tooltips, Chat-Meldungen, Popups, Hilfe.
- Die Sprache richtet sich automatisch nach der Spielsprache (`GetLocale()`): `deDE` = Deutsch, alles andere = Englisch (Fallback).
- Ist heute schon so umgesetzt: `Locales.lua` hat 50 Schlüssel, EN und DE sind vollständig.
- Regel für alle neuen Funktionen: **jeder neue Text sofort als Locale-Schlüssel in EN und DE**, kein fest eingetippter Text im Code.
- **Ausnahme Debug/Entwickler-Ausgaben: nur Deutsch**, unabhängig von der Spielsprache (die sieht nur der Entwickler). Das betrifft:
  - die Debug-Meldungen bei Statuswechseln
  - den Rohdaten-Dump
  - `tracked:`-Zeilen, `/twf mark`, `/twf hint` im Debug-Modus
  - die Log-Einträge
  - die Marker-Methoden-Namen
  Diese Texte stehen nicht in den Locales, sondern direkt auf Deutsch im Code (oder in einer eigenen DE-only-Tabelle).

## H. Debug-Schalter per Befehl
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

## J. Checkbox „TWF-Nameplates“: Umschalten Blizzard ↔ TWF (vom Nutzer beschlossen 2026-10-04)
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
  - Das Ziel (für die Zauberleiste) wird über einen Frame-Vergleich erkannt (`nameplate == C_NamePlate.GetNamePlateForUnit("target")`), also ohne geheime Werte; Wechsel bei `PLAYER_TARGET_CHANGED`.
  - Eigenes Modul `Nameplates.lua`; alle Werte in `Config.lua`.
- Offene Fragen:
  - Was passiert mit Problem-Gegnern (rot/gelb) und den Ideen A/C? (Bleiben Ideen, solange nicht anders entschieden.)
- Vorher testen (Test 2): Funktioniert `SetAlpha(0)`/`(1)` außerhalb und **im Kampf**? Bleibt die ausgeblendete Nameplate anklickbar? (`SetAlpha(1)` wird zum Zurückschalten auf Blizzard gebraucht.)

## K. TWF-Nameplate: Lebensbalken in Ampelfarbe (vom Nutzer beschlossen 2026-10-04)
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

## L. Rollensymbol: Mob ↔ neues Aggro-Ziel (vom Nutzer beschlossen 2026-10-04, erste Ausbaustufe von Idee D)
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
  - Der Mob bekommt das **„Kampf“-Symbol mit den zwei gekreuzten Schwertern** (bestätigt), unabhängig von deiner Rolle.
    - Kandidaten: die Datei `Interface\CharacterFrame\UI-StateIcon` (Kampf-Symbol am Spielerporträt, rechte obere Hälfte, Ausschnitt 0.5–1 / 0–0.5) oder der moderne Atlas `UI-HUD-UnitFrame-Player-CombatIcon`. Auf Forever testen, was es gibt.
    - Steht als eigener Eintrag im Symbolsatz in `Config.lua` (z. B. `AGGRO_SELF`), also genauso austauschbar.
- **Symbole: vorerst Rollensymbole (bestätigt), leicht austauschbar.**
  - Der Symbolsatz steht als **Tabelle in `Config.lua`** (Single Source): Rolle → Grafik, z. B. `TANK = "ui-lfg-roleicon-tank"`, `HEALER = "ui-lfg-roleicon-healer"`, `DAMAGER = "ui-lfg-roleicon-dps"`, plus `NONE` für „keine Rolle gesetzt“ = **das Kampf-Symbol (gekreuzte Schwerter)** (bestätigt), also dieselbe Grafik wie `AGGRO_SELF`.
  - Jeder Eintrag darf zusätzlich einen **Bildausschnitt** (TexCoords) haben, für Dateien mit mehreren Symbolen in einem Bild.
  - Jede Grafik darf ein **Atlas-Name oder ein Dateipfad** sein (auch eigene `.tga`/`.blp` im Addon-Ordner); der Code erkennt das selbst (`C_Texture.GetAtlasInfo`). Gibt es einen Atlas nicht, wird automatisch das Ersatzsymbol genommen.
  - Größe, Versatz über der Nameplate bzw. dem Kopf stehen ebenfalls in `Config.lua`.
  - Austauschen = **nur** die Tabelle in `Config.lua` ändern, kein anderer Code. Später ggf. auch andere Sätze (Raid-Marker, Klassensymbole) als weitere Tabelle.
  - Quellen zum Aussuchen: https://wago.tools/db2/UiTextureAtlasMember?filter[CommittedName]=roleicon (Atlas-Namen), https://wago.tools/files (Dateien mit Vorschau). Auf Forever per Test prüfen, was davon existiert.
- Ermittlung des neuen Ziels: pro Gruppenmitglied `UnitDetailedThreatSituation(partyN/raidN, mob)` prüfen, wer `isTanking` ist (nicht geheim, weil Gruppen-Token).
- Offene Fragen:
  - **Instanzen:** Erlaubt Blizzard dort keine freundlichen Nameplates, kommt das Symbol stattdessen ans Gruppenfenster → testen.
  - **Rolle erkennen:** `UnitGroupRolesAssigned` liefert in Classic oft „NONE“, weil keiner eine Rolle gewählt hat. Dann wird das **Kampf-Symbol** gezeigt (entschieden). Forever 1.60.1 hat laut API-Änderungen Rollenabfrage (Role Poll) eingebaut → testen, was `UnitGroupRolesAssigned` dort liefert.
- Tests dazu:
  - `UnitDetailedThreatSituation("partyN", mob)` im Kampf (Test 3 der alten Liste)
  - `UnitGroupRolesAssigned("partyN")`
  - Freundliche Nameplates + Symbol über dem Kopf, auch in einer Instanz

## M. Hinweis-Fenster: alle nötigen Spiel-Optionen (vom Nutzer beschlossen 2026-10-04)
- Das bestehende Hinweis-Popup beim Login (heute nur „Gegner-Nameplates an“, CVar `nameplateShowEnemies`) wird erweitert: Es nennt **alle Spiel-Optionen**, die TWF für einen sauberen Betrieb braucht.
- Neu dazu: **Nameplates für Spieler (freundliche Nameplates)** müssen an sein (für L, Symbol über dem Kopf).
- **Vorher genau ermitteln (Analyse + Test auf Forever):** Welche Optionen bzw. CVars braucht TWF wirklich, wofür, und was passiert, wenn eine fehlt? Kandidaten:

  | Option (Spielmenü) | CVar | wofür | Status |
  |---|---|---|---|
  | Gegner-Nameplates | `nameplateShowEnemies` | Erkennung, TWF-Nameplates (J/K) | heute schon im Hinweis |
  | Freundliche Nameplates | `nameplateShowFriends` | Symbol über dem Spieler (L) | **neu** |
  | Nameplates immer anzeigen (nicht nur im Kampf) | `nameplateShowAll` | Gegner erkennen, bevor sie angreifen? | prüfen, ob nötig |
  | Sichtweite der Nameplates | `nameplateMaxDistance` | wie weit TWF Gegner sieht | prüfen |
  | Nameplates hinter Wänden | `nameplateOccludedAlphaMult` | nur Optik, für TWF evtl. egal | prüfen |
  | Ggf. Gegner-Begleiter/Totems/Minions | `nameplateShowEnemyPets` u. a. | prüfen | prüfen |

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

## TODO vor Veröffentlichung
- Beschreibung überarbeiten: TOC-Notes (EN + DE) versprechen noch „Klick zum Zielwechsel“, das stimmt nicht mehr. Dazu die CurseForge-Beschreibung neu schreiben.

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
