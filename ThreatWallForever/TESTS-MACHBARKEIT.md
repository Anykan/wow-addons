# ThreatWall Forever — Machbarkeitstests vor dem Programmieren

Stand 2026-10-04. Prüft, ob der Forever-Client das hergibt, was die Anforderungen J–M brauchen.
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
| T1 | | | |
| T2 | | | |
| T3 | | | |
| T4 | | | |
| T5 | | | |
| T6 | | | |
| T7 | | | |
| T8 | | – | |
| T9 | | – | |
| T10 | | – | draußen / Instanz |
| T11 | | – | |
