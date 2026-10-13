# Entwicklungsregeln — gelten für ALLE Addons in diesem Repo

Stand 2026-10-04. Addon-spezifische Anforderungen stehen im jeweiligen Addon-Ordner (z. B. `ThreatWallForever/ANFORDERUNGEN.md`), der Gesamtstand in `PROJEKTSTAND.md`.

## Teil 1 — Allgemeine Grundsätze

### Saubere Struktur
1. **Eine Aufgabe pro Funktion bzw. Modul.** Eine Änderung betrifft nur das zuständige Modul.
2. **Nichts doppelt bauen: erst suchen, dann schreiben.**
   - Vor jeder neuen Funktion im **eigenen Addon** suchen, ob es so etwas schon gibt oder ob sich Vorhandenes nutzen oder erweitern lässt.
   - Auch in den **anderen Addons im Repo** nachsehen, z. B. Cast-Bar-Look und Atlas-Fallback aus SealTimersForever, Sync/Coordinator aus CrittersBoard, pcall-/secret-Helfer aus ThreatWall.
   - Taucht derselbe Code zweimal auf, kommt er in eine gemeinsame Funktion (bzw. in `Utils.lua`).
   - Im Entwurf (Stichpunkte) steht immer, was wiederverwendet wird und was neu entsteht.
3. **So einfach wie möglich.** Keine Funktionen auf Vorrat, die noch niemand braucht.
4. **Sprechende Namen.** `isTanking` statt `t2`; Funktionen heißen nach dem, was sie tun.
5. **Single Source of Truth (PFLICHT): Jeder einstellbare Wert existiert genau einmal, in `Config.lua`.**
   - Jedes Addon hat eine eigene Datei `Config.lua`, die als erste Code-Datei nach den Libs geladen wird.
   - Dort stehen **alle** festlegbaren Werte als benannte Variablen, gruppiert nach Abschnitten bzw. Modulen:
     - Zeiten und Intervalle (Update-Takt, Timeouts, Grace-Perioden)
     - Größen, Abstände, Versätze, Schriftgrößen
     - Farben (Ampel rot/gelb/grün, Rahmen, Hintergrund)
     - Texturen, Atlanten, Sounds (Pfade)
     - Grenzen (max. Zeilen, max. Log-Einträge, Slider-Min/Max/Schritt)
     - Versionen (Addon, DB, Protokoll), Präfixe, Slash-Befehle
     - **Defaults der Spieler-Einstellungen** (SavedVariables)
   - Im restlichen Code steht **keine nackte Zahl, kein Farbwert, kein Pfad**. Erlaubt sind nur 0, 1 und -1 in offensichtlicher Bedeutung; alles andere wird aus der Config gelesen.
   - Jede Variable bekommt einen kurzen deutschen Kommentar: wofür sie da ist, Einheit, sinnvoller Bereich.
   - Texte sind die einzige Ausnahme, sie liegen in `Locales.lua` (ebenfalls eine einzige Quelle).
   - Gleiches gilt für Logik-Informationen: Jede Information wird an genau einer Stelle ermittelt (z. B. findet nur `Detection` Gegner, alle anderen lesen deren Ergebnis).
6. **Einheitlicher Stil.** Gleiche Einrückung, gleiche Schreibweise für Namen, gleicher Datei-Aufbau.

6a. **Pfadfinder-Regel (Boy Scout Rule), mit strengen Sicherungen.** Kleinigkeiten in Dateien, die wir *ohnehin* bearbeiten, dürfen nebenbei aufgeräumt werden, aber nur, wenn sie **zu 200 % korrekt** sind:
   - **Erst vorschlagen:** Jede Aufräum-Änderung steht einzeln im Entwurf (Stichpunkte) und wird nur nach Zustimmung gemacht. Nichts heimlich nebenbei.
   - **Vollständig suchen:** Vor jedem Umbenennen, Verschieben oder Löschen werden **alle** Verwendungen im ganzen Addon gesucht (auch Strings, Locales, XML, TOC, SavedVariables, Slash-Befehle) und die Fundstellen im Entwurf aufgelistet.
   - **Tabu ohne eigene Aufgabe:**
     - SavedVariable-Keys und Sync-Nachrichten (würden alte Einstellungen bzw. ältere Versionen bei Mitspielern brechen)
     - öffentliche Befehle
     - Frame-Namen (andere Addons und Layouts verweisen darauf)
   - **Kein Verhalten ändern:** Aufräumen ändert nur Form, nie Funktion. Ist das nicht sicher, wird nicht aufgeräumt.
   - **Getrennt festhalten:** Aufräumen kommt in einen eigenen Commit (`refactor:`), getrennt von der eigentlichen Änderung, damit es einzeln zurückgenommen werden kann.
   - **Mittesten:** Die aufgeräumten Stellen kommen mit in die Testliste.
   - **Im Zweifel nicht:** Was nicht zu 200 % sicher ist, wird nicht angefasst, sondern nur als TODO notiert.

### Zuverlässigkeit
7. **Mit Fehlern rechnen.** Ungültige Eingaben und fehlende Daten abfangen; lieber nichts anzeigen als abstürzen.
8. **Kleine Schritte.** Eine Änderung nach der anderen, jede einzeln testbar.
9. **Erst testen, dann weiter.** Im Spiel, außerhalb UND im Kampf.
10. **Abwärtskompatibel.** Alte SavedVariables und ältere Versionen bei Mitspielern dürfen nichts kaputt machen.

### Nachvollziehbarkeit
11. **Versionskontrolle:** kleine Commits mit klarer Nachricht (was + warum); Tags für Meilensteine und Rückwege.
12. **Kommentare erklären das Warum**, nicht das Was.
13. **Versionierung:** Haupt.Neben.Fix (0.2.0 = neues Feature, 0.2.1 = Bugfix).
14. **Patchnotes** für jede veröffentlichte Version:
    - **Als HTML** wie bei CrittersBoard, damit sie sauber in CurseForge eingefügt werden können: `<h2>` für die Version, `<h3>` für Abschnitte (z. B. Neu / Behoben / Geändert), `<ul><li>` für die Punkte.
    - **Reihenfolge: immer erst Deutsch, dann Englisch.**
    - Inhaltlich identisch mit den Ingame-Patchnotes (falls das Addon ein Patchnotes-Popup hat).
    - Pro Version in eine Datei im Addon-Ordner legen: `PATCHNOTES.html`, die neueste Version oben.
15. **Doku aktuell halten:** Anforderungen, Projektstand, Hilfe-Texte.

### Ablauf
16. **Erst planen, dann bauen:** Anforderungen → Entwurf als Stichpunkte → Zustimmung → Code → Test.
17. **Erst umbauen, dann erweitern:** Ein Umbau (Refactoring) ändert kein Verhalten; neue Funktionen kommen erst danach.
18. **Review vor dem Commit:** Den Diff vor jedem Commit noch einmal durchgehen.

## Teil 2 — WoW-spezifisch

19. **Jede Spiel-API in `pcall`** (vor allem auf WoW Forever). Werte mit `issecretvalue` prüfen, bevor sie verglichen, gerechnet oder angezeigt werden.
20. **Nichts Geheimes auswerten:** Frames vergleichen statt Units (`nameplate == C_NamePlate.GetNamePlateForUnit("target")`), Werte wie Symbol-Nummern selbst vergeben.
20a. **An Nameplates nie messen.** Größen und Positionen von Elementen, die an einer Nameplate hängen (`GetStringWidth`, `GetWidth`, `GetSize` …), können geheim sein, auch bei eigenen Elementen und vor allem in Instanzen. Mit ihnen zu rechnen wirft einen Fehler. Layout dort nur über Anker und feste Werte aus `Config.lua` lösen. (Lehre aus ThreatWall Forever, 2026-10-13: draußen lief es, in der Instanz Absturz.)

21. **Keine globalen Variablen** außer den SavedVariables; alles läuft über den Namespace `local addonName, ns = ...`.
22. **Kein Text fest im Code:** Spielertexte in die Locale-Datei (EN + DE, Umschaltung über `GetLocale()`), Debug-Texte nur Deutsch.
23. **Kampfsperre beachten:** Secure-Attribute, geschützte Frames und CVars nur außerhalb des Kampfs ändern, sonst vormerken und nachholen.
24. **Frame-Ebenen bewusst setzen:** Kind-Frames zeichnen über allem, was dem Eltern-Frame gehört.
25. **Sparsam aktualisieren:** Events bündeln und drosseln (`C_Timer.After(0)`), keine Arbeit pro Frame ohne Grund; abgeschaltete Module tun nichts.
26. **Defaults für jede Einstellung:** Fehlende Keys in alten SavedVariables werden ergänzt, nie vorausgesetzt.
26a. **Debug-Meldungen gehören zu jeder Funktion.** Jede neue Funktion bzw. jedes neue Modul bringt von Anfang an passende Debug-Ausgaben mit (wichtige Zustandswechsel, Fehlschläge, geheime/fehlende Werte), über das zentrale Debug-System des Addons (`ns.dbg`, Log in SavedVariables). Sie erscheinen nur bei eingeschaltetem Debug, sind nur Deutsch und spammen nicht (nur bei Änderungen). Ein- und ausschalten per Befehl (bei TWF `/twf debug 1|0`).

27. **Code-Kommentare auf Deutsch.** Bestehende englische Kommentare werden übersetzt, sobald die jeweilige Datei bzw. das Modul ohnehin bearbeitet wird (z. B. beim modularen Umbau). Keine reine Übersetzungsrunde über alle Addons. Variablen- und Funktionsnamen bleiben Englisch (wie die WoW-API).
28. **Fremde Addons:** Ohne Lizenz (bzw. „All Rights Reserved“) nur Ideen übernehmen, keinen Code. Bei MIT den Code nur mit Lizenzhinweis übernehmen.

## Teil 3 — Arbeitsablauf

28a. **Gespräch ≠ Anforderung.** Was wir über ein Addon besprechen, ist nicht automatisch eine Anforderung.
    - Eine Anforderung entsteht nur, wenn der Nutzer sie **klar als Anforderung angibt**.
    - Ist das unklar, **fragt Claude nach**: „Ist das eine Anforderung?“
    - Ideen und Vorschläge kommen in den Ideen-Teil der `ANFORDERUNGEN.md`. Claudes eigene Ergänzungen werden als *(Vorschlag Claude, offen)* markiert, bis der Nutzer sie bestätigt.
    - Gebaut wird nur, was in Teil 1 (Beschlossene Anforderungen) steht.

29. **Entwurf vor dem Code:** Änderungen erst als Stichpunkte vorschlagen; erst nach Zustimmung programmieren.
30. **Jede Änderung umkehrbar:** Git-Tag vor größeren Umbauten; im Spiel möglichst ein Schalter zum Abschalten.
31. **Tests:**
    - Alle Schritte komplett auflisten.
    - Chat- und Makrozeilen höchstens 255 Zeichen, vor dem Senden prüfen.
    - Zwei Durchgänge: außerhalb und im Kampf.
32. **Ablauf pro Änderung:** im Repo entwickeln → in den Spielordner kopieren → `/reload` → testen → Commit.
33. **Commits:** Es wird nur der Ordner des Addons gestaged, an dem gerade gearbeitet wird.
34. **Veröffentlichung:** Version in TOC und Code erhöhen, Patchnotes (EN + DE), Debug aus, dann Push und CurseForge.
