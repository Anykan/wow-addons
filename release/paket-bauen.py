"""Baut das Release-Paket eines Addons aus diesem Repo.

Aufruf (im Ordner wow-addons):  python release/paket-bauen.py ThreatWallForever

Ins Paket kommen nur die Dateien, die das Spiel braucht: alle in der TOC gelisteten
Lua-Dateien, die TOC selbst und die LICENSE. Doku (.md, .html) bleibt draußen.
Die Version kommt aus der TOC (## Version).
"""
import glob
import os
import re
import sys
import zipfile

addon = sys.argv[1] if len(sys.argv) > 1 else 'ThreatWallForever'
toc_path = f'{addon}/{addon}.toc'
toc = open(toc_path, encoding='utf-8').read()
version = re.search(r'^## Version:\s*(\S+)', toc, re.M).group(1)
lua = [line.strip().replace(chr(92), '/') for line in toc.splitlines() if line.strip().endswith('.lua')]  # Unterordner: \ -> /

missing = [f for f in lua if not os.path.exists(f'{addon}/{f}')]
if missing:
    sys.exit(f'FEHLER: in der TOC gelistet, aber nicht vorhanden: {missing}')
# auch Unterordner (z. B. Locales/) prüfen
found = [os.path.relpath(f, addon).replace(os.sep, '/') for f in glob.glob(f'{addon}/**/*.lua', recursive=True)]
extra = [f for f in found if f not in lua]
if extra:
    sys.exit(f'FEHLER: Lua-Dateien im Ordner, die nicht in der TOC stehen: {extra}')

files = [f'{addon}/{f}' for f in lua] + [toc_path]
if os.path.exists(f'{addon}/LICENSE'):
    files.append(f'{addon}/LICENSE')

out = f'release/{addon}-{version}.zip'
with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as z:
    for f in files:
        z.write(f, f)

print(f'{out}: {len(files)} Dateien, {os.path.getsize(out)} Bytes')
for name in zipfile.ZipFile(out).namelist():
    print('  ' + name)
