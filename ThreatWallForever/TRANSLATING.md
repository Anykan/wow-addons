# ThreatWall Forever – Übersetzen / Translating

🇩🇪 **Deutsch** · 🇬🇧 [English](#-english)

---

## 🇩🇪 Deutsch

Danke, dass du helfen möchtest! Alle Texte, die man im Spiel sieht, stehen in einer Datei pro Sprache:

| Sprache | Datei |
|---|---|
| English (Vorlage) | [`Locales/enUS.lua`](Locales/enUS.lua) |
| Deutsch | [`Locales/deDE.lua`](Locales/deDE.lua) |
| Español (España + Latinoamérica) | [`Locales/esES.lua`](Locales/esES.lua) |
| Français | [`Locales/frFR.lua`](Locales/frFR.lua) |

Die spanische und die französische Übersetzung wurden noch **nicht von Muttersprachlern geprüft** – Verbesserungen sind sehr willkommen.

### Nur einen Fehler melden (ohne GitHub-Kenntnisse)
Öffne ein [Issue „Übersetzung verbessern“](https://github.com/Anykan/wow-addons/issues/new?template=translation.yml) und trage Sprache, Text und deinen Vorschlag ein.

### Selbst übersetzen
1. Öffne die Datei deiner Sprache auf GitHub und klicke auf den **Stift** („Edit this file“). GitHub legt dafür automatisch eine Kopie (Fork) an.
2. Ändere **nur den Text rechts vom `=` in den Anführungszeichen**:
   ```lua
   L["MENU_LOCK"] = "Fenster fixieren"
   --  Schlüssel      ^ nur das hier ändern
   ```
3. Regeln:
   - Den **Schlüssel** links (`MENU_LOCK`) nie ändern.
   - **`%s`**, **`%d`** und **`\n`** (Zeilenumbruch) müssen erhalten bleiben – gleiche Anzahl wie in `enUS.lua`.
   - Keine geraden Anführungszeichen `"` im Text. Stattdessen „…“, “…” oder «…» benutzen.
   - Kurze Texte (Knöpfe, Spaltenköpfe wie `STATE_…`, `TAB_…`, `ROLE_…`) möglichst kurz halten – der Platz im Fenster ist begrenzt.
   - Begriffe so wählen, wie Spieler sie in deiner Sprache benutzen (z. B. „Aggro“, „Tank“, „DPS“).
4. Unten **„Propose changes“** und dann **„Create pull request“** klicken. Fertig – ich prüfe die Änderung und übernehme sie.

### Neue Sprache
Kopiere `Locales/enUS.lua` zu z. B. `Locales/ruRU.lua`, ändere oben die Zeile `if GetLocale() ~= "ruRU" then return end` (siehe `deDE.lua` als Beispiel) und übersetze die Texte. Fehlende Texte erscheinen automatisch auf Englisch. Die Datei muss noch in die `ThreatWallForever.toc` – das übernehme ich gern.

### Testen (optional)
Datei in `World of Warcraft\_classic_beta_\Interface\AddOns\ThreatWallForever\Locales\` ersetzen, Spielsprache einstellen, Spiel starten. Mit `/twf test` erscheinen Beispielzeilen, das Zahnrad öffnet die Einstellungen.

---

## 🇬🇧 English

Thank you for helping! Every text you see in the game lives in one file per language:

| Language | File |
|---|---|
| English (template) | [`Locales/enUS.lua`](Locales/enUS.lua) |
| Deutsch | [`Locales/deDE.lua`](Locales/deDE.lua) |
| Español (Spain + Latin America) | [`Locales/esES.lua`](Locales/esES.lua) |
| Français | [`Locales/frFR.lua`](Locales/frFR.lua) |

The Spanish and French translations have **not been checked by native speakers yet** – improvements are very welcome.

### Just report a mistake (no GitHub knowledge needed)
Open an [issue “Improve translation”](https://github.com/Anykan/wow-addons/issues/new?template=translation.yml) and enter the language, the text and your suggestion.

### Translate yourself
1. Open the file for your language on GitHub and click the **pencil** (“Edit this file”). GitHub creates a copy (fork) for you automatically.
2. Change **only the text on the right of `=` inside the quotes**:
   ```lua
   L["MENU_LOCK"] = "Lock window"
   --  key           ^ only change this
   ```
3. Rules:
   - Never change the **key** on the left (`MENU_LOCK`).
   - **`%s`**, **`%d`** and **`\n`** (line break) must stay – same number as in `enUS.lua`.
   - No straight quotes `"` inside the text. Use “…”, „…“ or «…» instead.
   - Keep short texts short (buttons, column headers like `STATE_…`, `TAB_…`, `ROLE_…`) – space in the window is limited.
   - Use the words players actually use in your language (e.g. “aggro”, “tank”, “DPS”).
4. Click **“Propose changes”** at the bottom, then **“Create pull request”**. Done – I will review and merge it.

### New language
Copy `Locales/enUS.lua` to e.g. `Locales/ruRU.lua`, add the line `if GetLocale() ~= "ruRU" then return end` at the top (see `deDE.lua` as an example) and translate the texts. Missing texts automatically fall back to English. The file also has to be added to `ThreatWallForever.toc` – I am happy to do that.

### Testing (optional)
Replace the file in `World of Warcraft\_classic_beta_\Interface\AddOns\ThreatWallForever\Locales\`, set the game language and start the game. `/twf test` shows sample rows, the gear opens the settings.
