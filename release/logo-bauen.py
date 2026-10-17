"""Zeichnet das ThreatWall-Forever-Logo (quadratisch, für CurseForge).

Aufruf (im Ordner wow-addons):  python release/logo-bauen.py
Ergebnis: ThreatWallForever/logo/twf-logo-mauer-<größe>.png (1024, 400, 64)

Motiv (Nutzer-Entscheid 2026-10-17): "TWF" als Burgmauer aus Stein mit Zinnen,
rotes Warnglühen dahinter, ein glühender Riss im W ("Aggro bricht durch").
Bewusst kein Schild, keine Ampelbalken und kein Gold auf Navy: Das nutzen schon
ForeverThreatPlate und Forever: Threat. Das alte Schild-Logo steht in der Git-Historie
(Commit b0a6bd4) und als PNG unter logo/twf-logo-schild-*.
"""
import os
import random
from PIL import Image, ImageDraw, ImageFilter, ImageChops

S = 4
N = 1024
W = N * S
OUT_DIR = 'ThreatWallForever/logo'


def p(*pts):
    return [(x * S, y * S) for x, y in pts]


def rect(x0, y0, x1, y1):
    return p((x0, y0), (x1, y0), (x1, y1), (x0, y1))


# Hintergrund: Anthrazit, zur Mitte etwas heller
bg = Image.new('RGB', (W, W))
d = ImageDraw.Draw(bg)
for i in range(256):
    t = i / 255
    c = tuple(int(a + (b - a) * t) for a, b in zip((7, 7, 9), (30, 28, 32)))
    r = int(W * 0.75 * (1 - t))
    d.ellipse((W / 2 - r, W * 0.47 - r, W / 2 + r, W * 0.47 + r), fill=c)

# Rotes Warnglühen hinter der Mauer
glow = Image.new('L', (W, W), 0)
gd = ImageDraw.Draw(glow)
gd.ellipse((200 * S, 230 * S, 824 * S, 720 * S), fill=255)
glow = glow.filter(ImageFilter.GaussianBlur(110 * S))
red = Image.new('RGB', (W, W), (230, 50, 25))
bg = Image.composite(red, bg, glow.point(lambda v: int(v * 0.85)))

# Buchstabenform (Maske) -------------------------------------------------------
mask = Image.new('L', (W, W), 0)
md = ImageDraw.Draw(mask)
TOP = 330
def merlons(x0, x1, n=4, w=40):
    """n Zinnen gleichmäßig von x0 bis x1, erste bündig links, letzte bündig rechts."""
    for i in range(n):
        x = x0 + i * (x1 - x0 - w) / (n - 1)
        md.polygon(rect(x, TOP - 52, x + w, TOP), fill=255)

# T
md.polygon(rect(80, TOP, 320, TOP + 105), fill=255)
md.polygon(rect(150, TOP + 105, 250, 790), fill=255)
merlons(80, 320)
# W (Form aus dem ersten Entwurf, schmaler gesetzt)
WX0, WK = 356, 0.74
def wx(x): return WX0 + (x - 505) * WK
md.polygon(p(*[(wx(x), y) for x, y in ((505, TOP), (600, TOP), (645, 600), (685, 430), (745, 430), (785, 600),
             (830, TOP), (925, TOP), (845, 790), (750, 790), (715, 650), (680, 790), (585, 790))]), fill=255)
for x0 in (505, 562, 830, 887):               # Zinnen auf den W-Spitzen
    md.polygon(rect(wx(x0), TOP - 52, wx(x0 + 38), TOP + 2), fill=255)
md.polygon(rect(wx(690), 378, wx(740), 432), fill=255)  # Zinne auf der W-Mitte
# F
md.polygon(rect(702, TOP, 942, TOP + 105), fill=255)
md.polygon(rect(702, TOP + 105, 802, 790), fill=255)
md.polygon(rect(802, 520, 902, 610), fill=255)
merlons(702, 942)

# Steinfüllung mit Mauerfugen ----------------------------------------------------
stone = Image.new('RGB', (W, W))
sd = ImageDraw.Draw(stone)
for y in range(W):
    t = y / W
    c = tuple(int(a + (b - a) * t) for a, b in zip((176, 168, 152), (92, 86, 78)))
    sd.line((0, y, W, y), fill=c)
random.seed(7)
ROW_H, BRICK_W, JOINT = 52, 96, 5
for row, y in enumerate(range(TOP - 60, 800, ROW_H)):
    # leichte Farbschwankung pro Stein
    off = (row % 2) * BRICK_W // 2
    for x in range(20 - off, 1010, BRICK_W):
        k = random.randint(-14, 10)
        sd.rectangle((x * S, y * S, (x + BRICK_W) * S, (y + ROW_H) * S),
                     fill=None)
        tint = Image.new('RGB', (BRICK_W * S, ROW_H * S), (128 + k, 128 + k, 128 + k))
        box = (x * S, y * S)
        region = stone.crop((box[0], box[1], box[0] + BRICK_W * S, box[1] + ROW_H * S))
        region = ImageChops.multiply(region, tint.point(lambda v: min(255, v * 2)))
        stone.paste(region, box)
        sd.line((x * S, y * S, x * S, (y + ROW_H) * S), fill=(46, 42, 40), width=JOINT * S)
    sd.line((0, y * S, W, y * S), fill=(46, 42, 40), width=JOINT * S)

# Riss mit rotem Licht im W
crack = p(*[(wx(x), y) for x, y in ((715, 470), (705, 520), (722, 560), (708, 615), (716, 650))])
cd = ImageDraw.Draw(stone)
cd.line(crack, fill=(255, 120, 60), width=7 * S, joint='curve')

# Schatten, Kanten, Zusammensetzen ------------------------------------------------
shadow = mask.filter(ImageFilter.GaussianBlur(14 * S))
sh = Image.new('L', (W, W), 0)
sh.paste(shadow, (6 * S, 14 * S))
bg = Image.composite(Image.new('RGB', (W, W), (0, 0, 0)), bg, sh.point(lambda v: int(v * 0.8)))

# Rote Lichtkante (Glühen von hinten an den Rändern)
rim = mask.filter(ImageFilter.MaxFilter(13)).filter(ImageFilter.GaussianBlur(10 * S))
bg = Image.composite(Image.new('RGB', (W, W), (255, 90, 40)), bg, ImageChops.subtract(rim, mask).point(lambda v: int(v * 0.9)))

bg.paste(stone, (0, 0), mask)

# Lichtkante oben links / dunkle Kante unten rechts (Steinrelief)
edge = ImageChops.subtract(mask, mask.transform(mask.size, Image.AFFINE, (1, 0, 4 * S, 0, 1, 4 * S)))
bg = Image.composite(Image.new('RGB', (W, W), (215, 205, 185)), bg, edge.point(lambda v: int(v * 0.7)))
edge2 = ImageChops.subtract(mask, mask.transform(mask.size, Image.AFFINE, (1, 0, -4 * S, 0, 1, -4 * S)))
bg = Image.composite(Image.new('RGB', (W, W), (30, 26, 24)), bg, edge2.point(lambda v: int(v * 0.8)))

# Glühen aus dem Riss
cg = Image.new('L', (W, W), 0)
ImageDraw.Draw(cg).line(crack, fill=255, width=26 * S)
cg = ImageChops.multiply(cg.filter(ImageFilter.GaussianBlur(9 * S)), mask)
bg = Image.composite(Image.new('RGB', (W, W), (255, 110, 50)), bg, cg.point(lambda v: int(v * 0.75)))
ImageDraw.Draw(bg).line(crack, fill=(255, 225, 160), width=3 * S, joint='curve')

bg = bg.resize((N, N), Image.LANCZOS)
os.makedirs(OUT_DIR, exist_ok=True)
for size in (1024, 400, 64):
    path = f'{OUT_DIR}/twf-logo-mauer-{size}.png'
    bg.resize((size, size), Image.LANCZOS).save(path)
    print(path)
