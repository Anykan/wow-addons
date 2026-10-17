import re, sys, glob
from luaparser import ast
from luaparser.astnodes import *
files=[l.strip().replace(chr(92),'/') for l in open('ThreatWallForever.toc',encoding='utf-8') if l.strip().endswith('.lua')]  # Unterordner: \ -> /
defs=set(); uses={}
glob_uses={}
for f in files:
    src=open(f,encoding='utf-8').read()
    try:
        tree=ast.parse(src)
    except Exception as e:
        print("SYNTAX", f, e); continue
    declared=set()
    for n in ast.walk(tree):
        if isinstance(n,(LocalAssign,)):
            for t in n.targets: declared.add(t.id)
        elif isinstance(n,LocalFunction): declared.add(n.name.id)
        elif isinstance(n,(Function,LocalFunction,Method,AnonymousFunction)):
            for a in n.args:
                if isinstance(a,Name): declared.add(a.id)
        elif isinstance(n,Forin):
            for t in n.targets: declared.add(t.id)
        elif isinstance(n,Fornum): declared.add(n.target.id)
    for n in ast.walk(tree):
        if isinstance(n,Index) and isinstance(n.value,Name) and n.value.id=='ns' and isinstance(n.idx,Name) and n.notation==IndexNotation.DOT:
            uses.setdefault(n.idx.id,set()).add(f)
    # definitions: ns.X = ... or function ns.X
    for m in re.finditer(r'(?:^|\n)\s*(?:function\s+ns\.(\w+)|ns\.(\w+)\s*=)',src):
        defs.add(m.group(1) or m.group(2))
    names=set()
    for n in ast.walk(tree):
        if isinstance(n,Name): names.add(n.id)
    # remove index field names: crude: names that appear only after '.' or ':'
    free=set()
    for nm in names-declared:
        if re.search(r'(?<![\.\:\w])'+re.escape(nm)+r'(?!\w)', re.sub(r'--[^\n]*','',src)):
            free.add(nm)
    glob_uses[f]=free
print("ns used but never defined:", sorted(k for k in uses if k not in defs))
print("ns defined but never used:", sorted(k for k in defs if k not in uses))
wow=set("""ns ADDON _ C_AddOns GetAddOnMetadata CreateFrame UIParent ThreatWallForeverDB SLASH_THREATWALL1 SLASH_THREATWALL2 SLASH_THREATWALL3 SlashCmdList
UnitDetailedThreatSituation UnitThreatSituation pairs ipairs type pcall geterrorhandler IsMouseButtonDown string table math tostring tonumber unpack date GetTime
C_Texture issecretvalue DEFAULT_CHAT_FRAME C_CVar GetCVar UnitExists UnitCanAttack UnitIsDead UnitAffectingCombat UnitPlayerControlled IsInRaid IsInGroup
GetNumGroupMembers GetNumSubgroupMembers UnitGUID UnitName GetRaidTargetIndex PlaySound SetRaidTargetIconTexture GameTooltip BackdropTemplateMixin
Minimap GetCursorPosition UISpecialFrames Settings InterfaceOptionsFrame_OpenToCategory SettingsPanel ShowUIPanel InterfaceOptionsFrame _G GetLocale true false nil self""".split())
for f,fr in glob_uses.items():
    unk=sorted(fr-wow)
    if unk: print(f,"unknown free names:",unk)
