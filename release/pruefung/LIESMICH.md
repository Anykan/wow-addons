# Prüfskripte für die Addons (vor jedem Kopieren ins Spiel ausführen)

Entstanden bei ThreatWall Forever (Oktober 2026). Sie fangen Fehler ab, die das Spiel
erst beim Laden meldet, und laufen ohne Lua-Installation (nur Python).

**Aufruf:** im Ordner des Addons, z. B.

```bash
cd "X:/Claude Workspace/wow-addons/ThreatWallForever"
python ../release/pruefung/1-syntax-und-verweise.py
python ../release/pruefung/3-offene-strings.py
python ../release/pruefung/4-ungueltige-escapes.py
```

| Skript | Prüft | Braucht |
|---|---|---|
| `1-syntax-und-verweise.py` | Syntax aller in der TOC gelisteten Lua-Dateien; `ns.X` benutzt, aber nirgends definiert (und umgekehrt). Die Zeilen „unknown free names“ sind Rauschen (Tabellenschlüssel, Parameter) und können ignoriert werden. | Python-Paket `luaparser` |
| `2-alte-lokale-namen.py` | Reste aus dem Modul-Umbau: alte lokale Namen (`frame`, `db`, `refresh` …), die jetzt über `ns.` laufen müssen. Meldet `Utils.lua titleText` fälschlich (Funktionsparameter). | – |
| `3-offene-strings.py` | Lua-Strings, die über das Zeilenende hinausgehen. **Wichtig:** `luaparser` verzeiht das, WoW nicht (Fehler „unfinished string“ am 2026-10-04). | – |
| `4-ungueltige-escapes.py` | Ungültige Backslashes in Strings, z. B. `'Interface\RaidFrame'` statt `'Interface\\RaidFrame'`. | – |

Die Skripte 1 und 2 lesen die Dateiliste aus `ThreatWallForever.toc` (Name im Skript fest);
für ein anderes Addon dort den TOC-Namen anpassen.

## Weitere Prüfungen, die bisher von Hand (als Einzeiler) liefen
- Jeder benutzte Text (`L.X`, `label`/`tip` in `Config.lua`) ist in **jeder** Sprache vorhanden, und es gibt keine ungenutzten Texte.
- Jeder benutzte Config-Schlüssel (`C.TABELLE.SCHLUESSEL`) ist in `Config.lua` definiert.
- Keine versehentlichen globalen Funktionen (`^function name(`) und keine globalen Zuweisungen.
- Spielordner und Repo sind identisch (`cmp` über alle Lua-Dateien und die TOC).

## Lehre für das Schreiben von Dateien per Skript
Backslashes und `\n` gehen in Shell-Heredocs leicht verloren oder werden zu echten
Zeilenumbrüchen. Texte mit Backslash deshalb mit dem Editor schreiben oder im Skript
`chr(92)` verwenden, und danach immer Skript 3 und 4 laufen lassen.
