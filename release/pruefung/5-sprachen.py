"""Prüft die Sprachdateien eines Addons (Locales/*.lua) gegen die englische Vorlage.

Aufruf (im Ordner des Addons):  python ../release/pruefung/5-sprachen.py
Auch für eingereichte Übersetzungen (Pull Requests) gedacht.

Fehler (Exit-Code 1):
  - Zeile im Textteil, die nicht wie  L["SCHLÜSSEL"] = "Text"  aussieht (z. B. " im Text)
  - Schlüssel, die es in enUS.lua nicht gibt (Tippfehler im Schlüssel)
  - doppelte Schlüssel
  - Platzhalter (%s, %d) oder Zeilenumbrüche (\\n) anders als in der Vorlage
  - Code-Texte (L.X / L["X"] in den Lua-Dateien, label/tip in Config.lua), die in enUS.lua fehlen
Hinweise (kein Fehler, das Spiel zeigt dann Englisch):
  - Texte, die in einer Sprache fehlen
"""
import glob
import os
import re
import sys

LINE = re.compile(r'^L\["(\w+)"\] = "([^"]*)"$')
PLACEHOLDER = re.compile(r'%[sd]|\\n')


def read(path):
    entries, errors = {}, []
    for no, raw in enumerate(open(path, encoding='utf-8'), 1):
        line = raw.rstrip('\n')
        if not line.startswith('L["'):
            continue
        m = LINE.match(line)
        if not m:
            errors.append(f'{path}:{no}: Zeile ungültig (Anführungszeichen im Text?): {line[:80]}')
            continue
        key, text = m.groups()
        if key in entries:
            errors.append(f'{path}:{no}: Schlüssel doppelt: {key}')
        entries[key] = text
    return entries, errors


base_path = os.path.join('Locales', 'enUS.lua')
if not os.path.exists(base_path):
    sys.exit('Keine Locales/enUS.lua gefunden – im Ordner des Addons aufrufen.')
base, errors = read(base_path)
warnings = []

for path in sorted(glob.glob(os.path.join('Locales', '*.lua'))):
    if os.path.basename(path) == 'enUS.lua':
        continue
    entries, errs = read(path)
    errors += errs
    name = os.path.basename(path)
    for key in sorted(set(entries) - set(base)):
        errors.append(f'{name}: Schlüssel gibt es in enUS.lua nicht: {key}')
    missing = sorted(set(base) - set(entries))
    if missing:
        warnings.append(f'{name}: {len(missing)} Text(e) fehlen, im Spiel erscheint Englisch: {", ".join(missing)}')
    for key, text in entries.items():
        if key in base and sorted(PLACEHOLDER.findall(text)) != sorted(PLACEHOLDER.findall(base[key])):
            errors.append(f'{name}: {key}: Platzhalter/Zeilenumbrüche anders als in enUS ({PLACEHOLDER.findall(base[key])})')

# Benutzte Texte im Code müssen in der Vorlage stehen
used = set()
for path in glob.glob('**/*.lua', recursive=True):
    if path.replace(os.sep, '/').startswith('Locales/'):
        continue
    src = open(path, encoding='utf-8').read()
    used |= set(re.findall(r'\bL\.([A-Z][A-Z0-9_]+)', src))
    used |= set(re.findall(r"\bL\[['\"]([A-Z][A-Z0-9_]+)['\"]\]", src))
    used |= set(re.findall(r"(?:label|tip)\s*=\s*'([A-Z][A-Z0-9_]+)'", src))
for key in sorted(used - set(base)):
    errors.append(f'Code benutzt {key}, aber enUS.lua hat den Text nicht')

for w in warnings:
    print('HINWEIS', w)
for e in errors:
    print('FEHLER ', e)
print(f'{len(base)} Texte in enUS.lua, {len(errors)} Fehler, {len(warnings)} Hinweise')
sys.exit(1 if errors else 0)
