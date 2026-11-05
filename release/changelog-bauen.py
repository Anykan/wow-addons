"""Baut den kompletten Changelog (alle Versionen, neueste oben, DE/EN/ES/FR) für CurseForge.

Quelle sind dieselben Texte wie im Neuigkeiten-Fenster im Spiel (Locales/*.lua:
NEWS_<Version>_NEW|CHANGED|FIXED, Punkte "Stichwort – Erklärung", Zeilen mit \\n getrennt)
und die Versionsliste C.NEWS.VERSIONS in Config.lua. Spiel und CurseForge sind so immer gleich.

Aufruf (im Repo-Ordner):  python release/changelog-bauen.py [Addon-Ordner]
Ergebnis: release/<Addon>-CHANGELOG.html  → bei CurseForge komplett als Changelog einsetzen.
"""
import os
import re
import sys

addon = sys.argv[1] if len(sys.argv) > 1 else 'ThreatWallForever'
NAME = 'Threat Wall Forever'
# Veröffentlichungsdatum je Version (für die Überschrift)
DATES = {'0.1': '13.10.2026', '0.2': '17.10.2026', '0.3': '17.10.2026', '0.4': '18.10.2026',
         '0.5': '19.10.2026', '0.5.1': '19.10.2026',
         '0.5.2': '05.11.2026'}
LANGS = [('enUS', '🇬🇧', 'English', 'en'), ('deDE', '🇩🇪', 'Deutsch', 'de'),
         ('esES', '🇪🇸', 'Español', 'es'), ('frFR', '🇫🇷', 'Français', 'fr')]
SECTIONS = [('NEW', '#5fd35f', '✨'), ('CHANGED', '#6cb6ff', '🔧'), ('FIXED', '#f0a040', '🐞')]
GOLD = '#f0c040'
DASH = ' – '

cfg = open(os.path.join(addon, 'Config.lua'), encoding='utf-8').read()
versions = re.findall(r"'([\d.]+)'", re.search(r'VERSIONS = \{([^}]*)\}', cfg).group(1))


def texts(code):
    t = open(os.path.join(addon, 'Locales', code + '.lua'), encoding='utf-8').read()
    return {k: v for k, v in re.findall(r'^L\["(\w+)"\] = "(.*)"$', t, re.M)}


def esc(s):
    return s.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')


out = [f'<h1 style="text-align:center;"><span style="color:{GOLD};">🛡️ {NAME} – Changelog</span></h1>',
       '<p style="text-align:center;"><span style="font-size:28px;">'
       + ' &nbsp; '.join(f'<a href="#{a}">{flag}</a>' for _, flag, _, a in LANGS) + '</span></p>',
       '<p style="text-align:center;"><span style="color:#5fd35f;">█████</span> <span style="color:#f0c040;">█████</span> '
       '<span style="color:#e8503f;">█████</span> <span style="color:#b07a3c;">█████</span> <span style="color:#5a9bff;">█████</span></p>']
for code, flag, lang, anchor in LANGS:
    L = texts(code)
    en = texts('enUS')
    get = lambda k: L.get(k) or en.get(k)
    out.append('<hr>')
    out.append(f'<h2 id="{anchor}"><a name="{anchor}"></a><span style="color:{GOLD};">{flag} {lang}</span></h2>')
    for v in versions:
        key = 'NEWS_' + v.replace('.', '_')
        head = esc(get('NEWS_VERSION').replace('%s', v))
        date = DATES.get(v)
        out.append(f'<h3><span style="color:{GOLD};">{head}</span>'
                   + (f' <span style="color:#8a94a6;font-size:13px;">({date})</span>' if date else '') + '</h3>')
        for sec, color, icon in SECTIONS:
            body = get(f'{key}_{sec}')
            if not body:
                continue
            out.append(f'<p><strong><span style="color:{color};">{icon} {esc(get("NEWS_SEC_" + sec))}</span></strong></p>')
            out.append('<ul>')
            for item in body.split('\\n'):
                # Stichwort fett, Erklärung normal – ohne feste Textfarbe, damit es auf hellem und
                # dunklem CurseForge-Hintergrund lesbar bleibt
                if DASH in item:
                    a, b = item.split(DASH, 1)
                    out.append(f'  <li><strong>{esc(a)}</strong>{DASH}{esc(b)}</li>')
                else:
                    out.append(f'  <li>{esc(item)}</li>')
            out.append('</ul>')

path = os.path.join('release', addon + '-CHANGELOG.html')
open(path, 'w', encoding='utf-8').write('\n'.join(out) + '\n')
print(path, '–', len(versions), 'Versionen,', len(LANGS), 'Sprachen')
