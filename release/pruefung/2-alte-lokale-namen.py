import re
files=[l.strip() for l in open('ThreatWallForever.toc',encoding='utf-8') if l.strip().endswith('.lua')]
old=['frame','db','refresh','applyLook','updateMinimap','say','IsSecret','plain','num','testMode','rows','tracked','collect','classify','worse','engaged','myStatus','candidateUnits','setMark','layoutRow','showMenu','SETTINGS','toggleRole','resetPlace','toggleWindow','savePlace','placeFrame','stopMove','startMove','dbg','roleName','getCVar','backdrop','hasAtlas','setAtlas','header','titleText','subText','gear','roleBtn','minimize','grip','mm','showHintPopup','checkNameplateSetting','cycleMarkMethod','MARK_METHOD_NAMES','toggleDebug','placePending','DEFAULTS','HEADER_H','FLAT','COLOR','RANK','TICK','GRACE','MAX_ROWS','MAX_LOG','CODES','PREFIX','VERSION','TEST','L']
for f in files:
    src=open(f,encoding='utf-8').read()
    code=re.sub(r'--\[\[.*?\]\]','',src,flags=re.S)
    code=re.sub(r'--[^\n]*','',code)
    code=re.sub(r"'[^'\n]*'|\"[^\"\n]*\"",'""',code)
    for nm in old:
        bare=[m.start() for m in re.finditer(r'(?<![\.\:\w])'+nm+r'(?![\w])',code)]
        if not bare: continue
        declared=re.search(r'local\s+(?:function\s+)?[\w,\s]*\b'+nm+r'\b',code) or re.search(r'function\s*\([^)]*\b'+nm+r'\b',code) or re.search(r'for\s+[\w,\s]*\b'+nm+r'\b',code)
        if not declared:
            # key in table constructor "nm =" inside {} is fine
            real=[p for p in bare if not re.match(r'\s*=(?!=)',code[p+len(nm):]) ]
            if real: print(f, nm, len(real))
