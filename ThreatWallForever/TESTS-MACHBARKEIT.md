# ThreatWall Forever — Machbarkeitstests vor dem Programmieren

Stand 2026-10-04 — **alle Tests durchgeführt**, Zusammenfassung unten. Prüft, ob der Forever-Client das hergibt, was die Anforderungen J–M brauchen.
Alle Zeilen ≤ 255 Zeichen (geprüft). Einfach in den Chat kopieren und Enter drücken. Am Ende aufräumen mit `/reload`.

## Vorbereitung
- Gruppe mit mindestens einem Mitspieler (für T6, T7, T10), idealerweise Tank + Heiler.
- Gegner-Nameplates an (V). Für T10 auch freundliche Nameplates an (Shift+V bzw. Optionen → Namen).
- **Schritt 0 (nach jedem `/reload` neu):** Hilfsfunktion laden, sie zeigt geheime Werte als „GEHEIM“:
  ```
  /run S=function(v)return issecretvalue and issecretvalue(v)and"GEHEIM"or tostring(v)end print("S bereit")
  ```

Jeder Test wird **zweimal** gemacht: **A = außerhalb des Kampfs**, **B = im Kampf**. Ergebnis notieren.

## T1 — Blizzard-Nameplate aus- und einblenden (J)
Gegner anvisieren.
```
/run local p=C_NamePlate.GetNamePlateForUnit("target")if p and p.UnitFrame then p.UnitFrame:SetAlpha(0)print("weg")else print("keine Plate")end
```
Erwartet: Nameplate verschwindet. Dann auf die Stelle über dem Gegner klicken → wird er weiter anvisiert?
```
/run local p=C_NamePlate.GetNamePlateForUnit("target")if p and p.UnitFrame then p.UnitFrame:SetAlpha(1)print("da")else print("keine Plate")end
```
Erwartet: Nameplate ist wieder da.

## T2 — Eigene Grafik an der Nameplate (K, L)
Gegner anvisieren.
```
/run local p=C_NamePlate.GetNamePlateForUnit("target")if not p then print("keine Plate")return end local t=p.twfT or p:CreateTexture(nil,"OVERLAY")p.twfT=t t:SetSize(16,16)t:SetColorTexture(1,0,0)t:SetPoint("BOTTOM",p,"TOP",0,5)t:Show()print("ok")
```
Erwartet: rotes Quadrat über dem Gegner, läuft mit ihm mit. Auch zusammen mit T1 (Nameplate ausgeblendet) prüfen: bleibt das Quadrat sichtbar?

## T3 — Leben und Name lesbar? (K)
Gegner anvisieren, im Kampf etwas Schaden machen.
```
/run print("HP",S(UnitHealth("target")),"Max",S(UnitHealthMax("target")),"Name",S(UnitName("target")))
```
Erwartet: Zahlen und Name. Steht „GEHEIM“ → T4 machen.

## T4 — Lebensbalken mit (evtl. geheimem) Wert füllen (K)
```
/run B=B or CreateFrame("StatusBar",nil,UIParent)B:SetSize(150,12)B:SetPoint("CENTER",0,60)B:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")B:SetMinMaxValues(0,UnitHealthMax("target"))B:SetValue(UnitHealth("target"))print("ok")
```
Erwartet: Balken über der Bildschirmmitte, passend gefüllt, und „ok“. Eine Lua-Fehlermeldung = geheime Werte lassen sich nicht anzeigen.

## T5 — Zauberinfo des Ziels (K)
Einen Gegner anvisieren, der **gerade zaubert** (Caster-Mob), Zeile während des Zaubers senden.
```
/run print("Zauber",S((UnitCastingInfo("target"))),"Kanal",S((UnitChannelInfo("target"))))
```
Erwartet: Name des Zaubers (oder nil, wenn gerade nichts gezaubert wird).

## T6 — Wen schlägt der Mob? (L)
Im Kampf einen Mob anvisieren, der **nicht dich**, sondern einen Mitspieler schlägt.
```
/run for i=1,4 do local u="party"..i if UnitExists(u)then print(u,UnitName(u),S((UnitDetailedThreatSituation(u,"target"))))end end print("TT",S(select(2,UnitClass("targettarget"))))
```
Erwartet: beim geschlagenen Mitspieler `true`, sonst `false`; „TT“ zeigt seine Klasse.

## T7 — Rollen vorhanden? (L)
Vorher im Gruppenfenster Rollen setzen (Rechtsklick auf das Porträt → Rolle) oder eine Rollenabfrage starten.
```
/run for i=1,4 do local u="party"..i if UnitExists(u)then print(u,S(UnitGroupRolesAssigned(u)))end end print("ich",S(UnitGroupRolesAssigned("player")))
```
Erwartet: TANK / HEALER / DAMAGER (NONE = keine Rolle gesetzt).

## T8 — Grafiken vorhanden? (K, L)
```
/run for _,a in ipairs({"ui-lfg-roleicon-tank","ui-lfg-roleicon-healer","ui-lfg-roleicon-dps","UI-HUD-UnitFrame-Player-CombatIcon","ui-castingbar-filling-channel","ui-castingbar-interrupted"})do print(a,C_Texture.GetAtlasInfo(a)and"JA"or"nein")end
```
Erwartet: JA/nein pro Grafik (Rollen-Icons, Kampf-Icon, grüne/rote Cast-Bar-Füllung).
Kampf-Symbol aus der klassischen Datei anzeigen:
```
/run F=F or CreateFrame("Frame",nil,UIParent)F:SetPoint("CENTER")local t=F:CreateTexture()t:SetSize(48,48)t:SetPoint("CENTER")t:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")t:SetTexCoord(.5,1,0,.5)
```
Erwartet: gekreuzte Schwerter in der Bildschirmmitte.

## T9 — Spiel-Optionen (CVars) vorhanden? (M)
```
/run for _,c in ipairs({"nameplateShowEnemies","nameplateShowFriends","nameplateShowAll","nameplateMaxDistance","nameplateOccludedAlphaMult","nameplateShowEnemyPets"})do print(c,C_CVar.GetCVar(c))end
```
Erwartet: ein Wert pro CVar; `nil` = gibt es auf Forever nicht.

## T10 — Freundliche Nameplates (L, M)
Freundliche Nameplates an, Mitspieler in Sichtweite. **Einmal draußen und einmal in einer Instanz.**
```
/run print("Plate party1:",C_NamePlate.GetNamePlateForUnit("party1")and"JA"or"nein")
```
Erwartet: JA. In der Instanz „nein“ → Symbol muss ans Gruppenfenster.

## T11 — Eintrag unter Optionen → AddOns möglich? (F)
```
/run print("Optionen-API:",Settings and Settings.RegisterCanvasLayoutCategory and"JA"or"nein")
```
Erwartet: JA.

## Aufräumen
```
/reload
```

## Ergebnisse
| Test | A (außerhalb) | B (im Kampf) | Bemerkung |
|---|---|---|---|
| T1 | ✔ ausgeblendet, wieder eingeblendet, Stelle anklickbar (2026-10-04) | ✔ ebenso im Kampf | J ist machbar |
| T2 | ✔ Quadrat erscheint und bleibt sichtbar, auch bei ausgeblendeter Nameplate. ✘ Klick auf das Quadrat visiert NICHT an | ✔ im Kampf: Quadrat mittig, Nameplate ausgeblendet, sichtbar + anklickbar | Quadrat lag ÜBER der Nameplate (außerhalb ihrer Klickfläche). Gegenprobe: Quadrat MITTEN auf der (ausgeblendeten) Nameplate → Klick visiert an ✔. Folge: TWF-Elemente, die anklickbar sein sollen, müssen innerhalb der Klickfläche der Nameplate liegen |
| T3 | HP **GEHEIM**, Max **GEHEIM** (schon außerhalb des Kampfs!), Name lesbar („Moonrage“) | Name auch im Kampf lesbar |  Leben nicht direkt nutzbar → T4 entscheidet |
| T4 | ✔ StatusBar nimmt geheime Werte (SetMinMaxValues/SetValue) ohne Fehler, Balken voll | ✔ im Kampf: Balken schrumpft passend zum Leben | **Lebensbalken (K) ist machbar**, obwohl HP geheim sind |
| T4b | ✔ `UnitHealthPercent` + `CurveConstants.ScaleTo100` vorhanden; `FontString:SetFormattedText("%.0f%%", UnitHealthPercent("target", true, CurveConstants.ScaleTo100))` zeigt Prozent über dem Balken, kein Fehler | | **Leben in % (K) ist machbar** |
| T5b | `nameplate.UnitFrame.castBar/CastBar` **nicht vorhanden** (Feldname anders oder keine) · `UnitCastingDuration` **vorhanden** | – | Weg B (Dauer-API) weiter testen |
| T5c | `StatusBar:SetTimerDuration` vorhanden | `pcall(Z.SetTimerDuration, Z, UnitCastingDuration("target"))` → true, oranger Balken erscheint, **steht still und bleibt voll orange** (auch nach dem Zauber) | unklar; Alternative T5d (Blizzards Zauberleisten-Vorlage) |
| T5d | `CastingBarMixin.SetUnit` vorhanden, altes `CastingBarFrame_SetUnit` nicht | | Weg C (Blizzard-Vorlage) möglich → T5e |
| T5e | Vorlage `SmallCastingBarFrameTemplate` + `SetUnit("target")` lässt sich anlegen | ✘ Lua-Fehler beim Zauberstart: `CastingBarFrame.lua:344 attempt to perform boolean test on local 'notInterruptible' (a secret boolean value, while execution tainted…)` | Blizzards Code läuft in einem Addon-Frame „tainted“ → geheime Werte verboten. **Weg C scheidet aus.** Weiter mit Weg A (Zauberleiste der Blizzard-Nameplate) → T5f |
| T5f | Zauberleiste der Nameplate gefunden unter `UnitFrame.CastBarsContainer` (dazu `UnitFrame.hideCastbar`, `UnitFrame.UpdateCastBarDisplay`) | – | Inhalt des Containers → T5g |
| T5g | `hideCastbar` = false; `CastBarsContainer` hat 1 Kind, Feld `castBar` (die eigentliche Zauberleiste) | – | Weg A testen → T5h |
| T5h | Nameplate per `SetAlpha(0)` weg, Container mit `SetIgnoreParentAlpha(true)` → true | ✘ **Sobald der Gegner angreift, kommt die komplette Nameplate zurück** (Blizzard setzt die Deckkraft beim Kampfbeginn neu) | Ausblenden muss gegen Blizzards Zurücksetzen abgesichert werden → T5i (Hook auf SetAlpha). Gilt auch für Anforderung J! |
| T5i | Hook: `hooksecurefunc(UnitFrame, "SetAlpha", …)` setzt bei jedem Blizzard-Aufruf ≠ 0 sofort wieder 0; `CastBarsContainer:SetIgnoreParentAlpha(true)` | ✔ **Nameplate bleibt im Kampf weg, nur Blizzards Zauberleiste ist sichtbar, läuft normal ab, kein Fehler** | **Zauberleiste fürs Ziel (K) machbar über Weg A.** Der Hook ist auch für J nötig. (Vorher: Fehler „index a nil value“, weil das Ziel gerade keine sichtbare Nameplate hatte → im Code immer auf nil prüfen.) |
| T5 | – | `UnitCastingInfo` → **GEHEIM** (Kanal nil, weil normaler Zauber) | Eigene Zauberleiste nicht direkt aus den Zauberdaten baubar → Alternativen T5b/c/d |
| T6 | – | ✔ Mob (Magier) schlägt Mitspieler (Schurke): `UnitDetailedThreatSituation("party1","target")` = true, `targettarget` = ROGUE, nicht geheim (Ausgabe laut Nutzer wie erwartet). Erster Versuch war Mitspieler statt Mob anvisiert → nil/MAGE | **Aggro-Ziel ermitteln (L) ist machbar** |
| T7 | ✔ Rollen über Porträt-Rechtsklick setzbar; `UnitGroupRolesAssigned` liefert TANK/DAMAGER wie gesetzt, nicht geheim (laut Nutzer wie erwartet) | – | **Rollensymbole (L) machbar**; ohne Rolle → NONE → Kampf-Symbol |
| T8 | ✔ Atlanten vorhanden: `ui-lfg-roleicon-tank/-healer/-dps`, `UI-HUD-UnitFrame-Player-CombatIcon`, `ui-castingbar-filling-channel`, `ui-castingbar-interrupted` | – | **T8c:** Rollensymbole ✔ gut; Kampf-Symbol (`UI-HUD-UnitFrame-Player-CombatIcon`) „hässlich“ → wird durch DD-Rollensymbol ersetzt; Balkenfüllungen standard/channel/interrupted ✔ (gold/grün/rot) |
| T9 | `nameplateShowFriends` = **nil** (gibt es nicht). Suche: `C_Console` fehlt. Kandidaten: **`nameplateShowFriendlyPlayers` = 1 bei an, 0 nach Umschalt+V → bestätigt der richtige**, `nameplateShowFriendlyNPCs` = 0, `…FriendlyPets`, `…FriendlyMinions`, `nameplateShowOnlyNames`, `ShowFriendlyNameplates` = nil. Übrige CVars vorhanden: `nameplateShowEnemies` 1, `nameplateShowAll` 1, `nameplateMaxDistance` 45, `nameplateOccludedAlphaMult` 0.4, `nameplateShowEnemyPets` 0 | – | In Config.lua pro Option eine Liste möglicher CVar-Namen (Beta kann sich ändern) |
| T10 | ✘ `C_NamePlate.GetNamePlateForUnit("party1")` → Fehler: „Raid<n>/Party<n> unit tokens are not allowed for this call“ | – | Gruppen-Token sind für Nameplates verboten → Nameplate des Mitspielers über `nameplateN` + `UnitIsUnit` oder über `target` suchen (T10b) — **T10b:** Freundliche Nameplate des Mitspielers existiert (`nameplate1` = Nightwalker, Name lesbar). `UnitIsUnit("nameplate1","party1")` liefert aber **nil** statt true. Über `target`: Plate JA, UnitFrame JA. → **T10c ✔:** `UnitGUID("nameplate1")` = `UnitGUID("party1")` = `Player-4618-00929A23`, beide lesbar (nicht geheim); `UnitIsUnit` bleibt nil. **Zuordnung per GUID-Vergleich ist machbar.** **Instanz ✔:** freundliche Nameplate von Nightwalker vorhanden (`nameplate9`), Name + GUID lesbar. **Aber:** In der Instanz sind bei den Gegner-Nameplates (`nameplate3–8`) **Name UND GUID GEHEIM** → TWF-Code muss geheime Namen/GUIDs überall vertragen (Anzeige per SetText ok, kein Vergleich/Sortieren) |
| T11 | ✔ `Settings.RegisterCanvasLayoutCategory` vorhanden | – | **Eintrag unter Optionen → AddOns (F) machbar** |

## Nachtrag beim Bau von L (2026-10-04)
- In einer Instanz: `C_NamePlate.GetNamePlates(true)` → 6 Nameplates, davon **4 gesperrt** (`IsForbidden`). Betroffen sind die **freundlichen** Nameplates (Mitspieler-Balken blieben sichtbar, Gegner funktionierten).
- Folge: Freundliche Nameplates können in Instanzen weder ausgeblendet werden noch ein Symbol tragen → Ersatz für das Symbol über dem Kopf: Gruppenfenster.

## Nachtrag beim Test von L neu (2026-10-13)
- `UnitDetailedThreatSituation(einheit, "nameplateN")`: **alle Rückgaben GEHEIM** (für `party1` und für `player`). Über `"target"` war „tankt“ lesbar (T6).
- `UnitThreatSituation("party1", "nameplateN")` → **3, lesbar**. Die einfache Status-Stufe (0–3) ist also auch über Nameplate-Token nutzbar.
- Folge: `ns.aggroHolder` nutzt zuerst die ausführliche Abfrage, sonst die Stufe (≥ 2 = tankt, 3 hat Vorrang).
- Ist man selbst **nicht im Kampf** mit dem Mob (blauer Balken), liefert `UnitThreatSituation("party1", "nameplateN")` **nil**. `UnitGUID("nameplateN" .. "target")` ist dann lesbar und gleich `UnitGUID("party1")` → dritter Weg in `ns.aggroHolder`: Ziel des Mobs per GUID mit den Gruppenmitgliedern vergleichen (draußen getestet, Instanz offen).

## Nachtrag Instanz-Test (2026-10-13)
- **Blauer Balken in der Instanz:** kein Aggro-Ziel, die GUID des Mob-Ziels ist dort offenbar geheim (draußen lesbar). Sobald man selbst im Kampf ist, greift die Bedrohungsstufe.
- **Ziel des Mobs in der Instanz, man selbst nicht im Kampf:** `UnitGUID("nameplateN" .. "target")` GEHEIM, `UnitName(…)` GEHEIM, `UnitIsUnit(…, "party1")` nil, `C_NamePlate.GetNamePlateForUnit("party1target")` verboten (Party-Token). → **Kein lesbarer Weg**; beim blauen Balken gibt es in Instanzen kein Aggro-Ziel.
- **Lua-Fehler in der Instanz:** `Symbols.lua:127 attempt to perform arithmetic on a secret number value` → `FontString:GetStringWidth()` eines eigenen Textes an der Nameplate ist in der Instanz **geheim**. Behoben: Ausrichtung nur über Anker, nichts messen (REGELN.md 20a).

## Zusammenfassung (2026-10-04)
| Anforderung | Ergebnis | Weg |
|---|---|---|
| J Blizzard-Nameplates aus/ein | ✔ machbar | `UnitFrame:SetAlpha(0/1)` + **Hook auf SetAlpha** (Blizzard setzt beim Kampfbeginn zurück) |
| K TWF-Nameplate anklickbar | ✔ | eigene Elemente **innerhalb** der Nameplate-Fläche |
| K Lebensbalken | ✔ | StatusBar mit geheimen Werten (`SetMinMaxValues/SetValue`) |
| K Leben in % | ✔ | `SetFormattedText("%.0f%%", UnitHealthPercent(unit, true, CurveConstants.ScaleTo100))` |
| K Name | ✔ | draußen lesbar, in Instanzen **geheim** → nur anzeigen (SetText), nie vergleichen |
| K Ampelfarben im Cast-Bar-Stil | ✔ | `ui-castingbar-filling-standard` / `-filling-channel` / `-interrupted` |
| K Zauberleiste des Ziels | ✔ | Blizzards `UnitFrame.CastBarsContainer` mit `SetIgnoreParentAlpha(true)`; eigene Leiste geht NICHT |
| L Wer hat Aggro | ✔ | `UnitDetailedThreatSituation(partyN, mob)` |
| L Rollen | ✔ | `UnitGroupRolesAssigned`, Rollensymbole `ui-lfg-roleicon-*`; Kampf-Symbol verworfen → DD-Symbol |
| L Symbol über Mitspieler | ✔ | freundliche Nameplates, Zuordnung per **GUID-Vergleich** (Party-Token bei Nameplate-API verboten, `UnitIsUnit` = nil); geht auch in Instanzen |
| M Spiel-Optionen | ✔ | freundliche = `nameplateShowFriendlyPlayers`; weitere CVars vorhanden |
| F Optionen → AddOns | ✔ | `Settings.RegisterCanvasLayoutCategory` |

Allgemeine Lehren: Nameplate-API immer auf nil prüfen (Ziel ohne sichtbare Nameplate); Gegner-GUIDs/Namen in Instanzen geheim; Blizzard-Vorlagen in Addon-Frames laufen „tainted“ und scheitern an geheimen Werten.
