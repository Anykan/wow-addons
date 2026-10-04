# WoW-Addons — Projektstand (Stand 2026-10-04)

Zentrale Übersicht über alle gemeinsam entwickelten Addons. Detailnotizen liegen zusätzlich im Claude-Memory. **Entwicklungsregeln: `REGELN.md`** (gelten für alle Addons). TWF-Ausbau: `ThreatWallForever/ANFORDERUNGEN.md`.

- **Repo:** `X:\Claude Workspace\wow-addons\` → https://github.com/Anykan/wow-addons
- **Workflow:** im Repo entwickeln → Dateien in den Spielordner kopieren → `/reload` testen → commit/push.
- **Arbeitsweise:** Änderungen erst als Stichpunkte vorschlagen, erst nach Zustimmung coden. Test-Schritte immer komplett auflisten, Chat-/Makrozeilen max. 255 Zeichen.
- **Beim Committen:** immer nur den Ordner des Addons stagen, an dem gerade gearbeitet wird (es liegen Änderungen mehrerer Addons gleichzeitig offen).

## Git-Gesamtstand

| | |
|---|---|
| `master` lokal | `60779cb`, **2 Commits vor `origin/master`** (ThreatWall `649679a`, `60779cb`), nicht gepusht |
| `origin/master` | `51b8560` (SealTimers Cast-Bar-Look) |
| `dev/v0.6` | `6407506` (CrittersBoard v0.6.1, bereits in master gemergt) |
| Tags | `sealtimers-vor-blizzard-balken` (`fa59047`), `threatwall-baseline-vor-highlight` (`60779cb`, nur lokal) |
| Uncommittet | CrittersBoard v0.6.4 (8 Dateien), SealTimersForever pcall-Fixes, ThreatWall Ziel-Highlight |

---

## 1. CrittersBoard — WoW Classic Era (Interface 11508)

Top Hits & Heals Board mit Gildensync. Auf CurseForge veröffentlicht.

- **Spielordner:** `E:\World of Warcraft\_classic_era_\Interface\AddOns\CrittersBoard\`
- **SavedVariables:** `E:\World of Warcraft\_classic_era_\WTF\Account\DARKANGEL80\SavedVariables\CrittersBoard.lua`

### Versionen
| Version | Stand |
|---|---|
| 0.5.6 | alte CurseForge-Version |
| 0.6 | Coordinator-Sync, Patchnotes-Popup, Top-20-Fix, Spell-Gruppierung nach Name, Info-Tooltip |
| 0.6.1 | Hotfix: Sync-Endlosschleife, Alerts/Sounds nach Login stumm, neue Wahl nach Coordinator-Logout, SNAP_BUSY-Cooldown |
| 0.6.2 | Hotfix: Race-Condition (3-s-Timer vor Coordinator-Antwort), Coordinator-Re-Login ohne Neuwahl. Commit `8c8dcda` |
| **0.6.4** | **uncommittet im Repo**: Absturz/Endlosschleife beim Login (Print-Funktion rief sich rekursiv auf), falsche "Du bist Coordinator"/"Keine Spieler online"-Meldungen, Statusmeldungen an Debug-Level gebunden, neues Dropdown Debug-Level 0/1/2 + Sync-Log-Schalter in den Einstellungen. Patchnotes EN+DE sind fertig. |

Konstanten (Definitions.lua): `VERSION "0.6.4"`, `DB_VERSION 4` (Erhöhen = DB-Wipe), `PROTOCOL_VERSION 5` (Erhöhen = Sync inkompatibel, muss ≥ 4 bleiben), `DEBUG_MODE 0` (jetzt Level statt Boolean), Präfix `CB_CRIT`.

### Sync-Konzept (v0.6)
- Coordinator-Wahl: `ELECT_REQ` → alle `ELECT_BID` → nach 3 s gewinnt die längste Session-Zeit (bei Gleichstand alphabetisch) → `ELECT_WIN` + Snapshot. `ELECT_LOST` beim Logout.
- Nach `SNAP_DONE` schickt jeder Empfänger nur die eigenen Rekorde als EVT zurück (Delta-Push); der Coordinator überspringt das.
- EVT nur, wenn der Rekord in den Top 20 liegt (D/H/O/DT); bei S/HS jeder neue Spell-Best.
- Self-Filter: `ShortName()` entfernt das Realm-Suffix, `SYNC.myName` wird bei `PLAYER_LOGIN` gecacht.
- Erkennt das Addon eine neuere Version, stoppt es den ausgehenden Sync (`NewerVersionWarned`).

### Offen
- [ ] v0.6.4 im Spiel testen → committen → pushen → auf CurseForge hochladen
- [ ] prüfen, ob es eine v0.6.3 gab (in den Patchnotes fehlt sie)
- [ ] EVT-Threshold für S/HS prüfen (v0.6.x)
- [ ] Twink-Sync-Bug: Twink-Daten werden beim Login des Hauptcharakters mitgesynct (v0.7)
- [ ] Sound-Einstellungen pro Kategorie und pro Zauber (v0.7)

---

## 2. SealTimersForever — WoW Forever (Ordner `_classic_beta_`, Interface 16001)

Fork von Pirsons Paladin-Siegel-Addon v1.00 (MIT, https://github.com/Pirson-s-Addons/SealTimersForever, Basis-Commit `ea5e769`).

- **Spielordner:** `E:\World of Warcraft\_classic_beta_\Interface\AddOns\SealTimersForever\`
- Im Ordner: `CHANGES.md` + `upstream-v1.00-to-local.patch` (Diff gegen v1.00, mit `git apply` einspielbar)

### Unsere Änderungen
1. Timer-Leiste unter dem Icon, synchron zum Kreis-Cooldown (`SyncBar`, `GetCooldownTimes()`)
2. Eigener, separat verschiebbarer Anker für die Leiste (`barPoint/barX/barY`)
3. Optionen: Show icon, Show bar, Bar width (20–400), Leistenfarbe (`/stf color`)
4. Blizzard-Cast-Bar-Look (Atlanten `ui-castingbar-*`, Option `blizzStyle`, `/stf check`), Commit `51b8560`
5. **Uncommittet:** 5 Abstürze bei "secret"-Auren behoben (`C_UnitAuras.*` in `pcall`)

**Zurück vor den Blizzard-Look:** Häkchen bei "Game cast bar style" entfernen, oder
`git checkout sealtimers-vor-blizzard-balken -- SealTimersForever/SealTimersForever.lua SealTimersForever/Locales.lua`

### Offen
- [ ] pcall-Fixes committen und pushen
- [ ] Upstream ist bei v1.01+ (Swing-Timer, 20 Sprachen, neue Ordnerstruktur). Ein Update überschreibt unsere Leiste, dann muss sie portiert werden.

---

## 3. ThreatWall Forever — WoW Forever (Interface 16001, v0.1)

Eigenes Addon (MIT): Es zeigt nur Gegner mit einem Aggro-Problem. Im Tank-Modus sind das Gegner, bei denen du die Aggro verlierst; im DD/Heal-Modus Gegner, bei denen du zu viel ziehst. Befehl `/twf` (Aliase `/threatwall`, `/twall`). Die Optik ist an ForeverThreat angelehnt, der Code ist aber eigener. Geplant: Veröffentlichung auf CurseForge.

- **Spielordner:** `E:\World of Warcraft\_classic_beta_\Interface\AddOns\ThreatWallForever\`
- Erkennung über `target`, `pettarget`, Gruppenziele und `nameplate1..40`. Dafür müssen die Gegner-Nameplates an sein; beim Login erscheint ein Hinweis-Popup (`/twf hint reset`).
- Anzeige: dynamische Liste, Rot vor Gelb. Option "Alle Kämpfe zeigen" (`showAll`). Debug über `/twf debug`, der Log landet in SavedVariables.
- **Uncommittet (Experiment vom 03.10.):** Die Zeile des aktuellen Ziels bekommt einen pulsierenden Rahmen (`db.highlightTarget`). Im Kampf noch nicht getestet. Rückweg: `git checkout threatwall-baseline-vor-highlight -- ThreatWallForever`

### Blockiert durch den Client
- **Klicken zum Anvisieren:** `nameplateN`-Token lassen sich nicht anvisieren (Spielregel). Bug #74 ist auf Build 70205 nicht mehr das Hindernis. Gruppenziel-Slots wurden verworfen. Mögliche Alternative: die Nameplate beim Hovern über die Zeile hervorheben.
- **Schlachtzug-Symbole:** `GetRaidTargetIndex` ist im Kampf "secret". Gemeldet als [forever-bugs#166](https://github.com/ClassicWoWCommunity/forever-bugs/issues/166), Status offen. Drei Varianten sind im Code und per `/twf mark` umschaltbar.
- **Threat-Prozent-Balken:** verworfen, weil `percent` im Kampf `nil` liefert.

### Offen
- [ ] Highlight im Kampf testen, danach committen oder verwerfen
- [ ] die 2 lokalen Commits und den Tag pushen
- [ ] Issue #166 auf eine Antwort prüfen
- [ ] vor Veröffentlichung: TOC-Beschreibung + CurseForge-Text überarbeiten (Klick zum Zielwechsel stimmt nicht mehr)

**Lehre für den Forever-Client:** *jeden* API-Aufruf in `pcall` packen, denn viele Werte sind "secret".

---

## 4. GuildAchievements — WoW Classic Era (nur Konzept, noch kein Code)

Gilden-Erfolge für ~404 Rares und ~200 Dungeon-/Raid-Bosse. Ein vergleichbares Addon gibt es nicht.

- **Datenquellen:** `SilverDragon\Data_Classic\Classic\module.lua`, `AtlasLootClassic_DungeonsAndRaids\data.lua`
- **3 Layer:**
  1. statische Mob-Datenbank
  2. Gilden-Erstkill (Name und Zeitpunkt, wird nie überschrieben)
  3. Bitmaske pro Mob: wer hat ihn getötet (76 Bytes)
- **Sync:** `SendAddonMessage` über den GUILD-Kanal (max. 255 Bytes), nur Deltas; sparse Encoding vs. Bitmaske mit Break-Even bei ~300 Kills.
- **Neuer Spieler:** fragt beim Login "Wer hat Daten?". Antwort mit zufälligem Delay von 0–5 s, der kompletten Stand per WHISPER, die höchste DB-Version gewinnt.
- **Coordinator nach Raft:**
  - Election-Timeout 1–5 s, Wahl über `VOTE_REQ` mit Term+1
  - Heartbeat alle 30 s (~14 Bytes), Neuwahl nach 45 s ohne Heartbeat
  - Bei einer höheren Term-Nummer tritt der alte Coordinator ab

### Offen
- [ ] Grundgerüst anlegen (TOC, Datenbank-Import aus SilverDragon/AtlasLoot)
