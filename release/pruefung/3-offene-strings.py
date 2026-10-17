import re, sys
# Findet Lua-Strings, die über das Zeilenende hinausgehen (luaparser verzeiht das, WoW nicht).
files = [l.strip().replace(chr(92), '/') for l in open('ThreatWallForever.toc', encoding='utf-8') if l.strip().endswith('.lua')]  # Unterordner: \ -> /
STR = re.compile(r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'')
bad = 0
for f in files:
    for n, line in enumerate(open(f, encoding='utf-8').read().split('\n'), 1):
        code = STR.sub('""', line)
        code = re.sub(r'--.*$', '', code)
        if code.count('"') % 2 or code.count("'") % 2:
            print('OFFENER STRING', f, n, line[:80])
            bad += 1
print('Strings ok' if bad == 0 else f'{bad} Problem(e)')
