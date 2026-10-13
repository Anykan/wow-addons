import re, glob
# Findet ungültige Lua-Escapes in Strings (z. B. 'Interface\RaidFrame' statt 'Interface\\RaidFrame').
VALID = set('\\nt"\'0123456789abfrv\n')
bad = 0
for f in glob.glob('*.lua'):
    for n, line in enumerate(open(f, encoding='utf-8'), 1):
        for m in re.finditer(r"'(?:\\.|[^'\\\n])*'|\"(?:\\.|[^\"\\\n])*\"", line):
            s = m.group(0)[1:-1]
            i = 0
            while i < len(s):
                if s[i] == '\\':
                    if i + 1 >= len(s) or s[i + 1] not in VALID:
                        print('UNGUELTIGES ESCAPE', f, n, m.group(0)); bad += 1
                        break
                    i += 2
                else:
                    i += 1
print('Escapes ok' if bad == 0 else f'{bad} Problem(e)')
