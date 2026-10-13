"""Zeichnet das ThreatWall-Forever-Logo (quadratisch, für CurseForge).

Aufruf (im Ordner wow-addons):  python release/logo-bauen.py
Ergebnis: ThreatWallForever/logo/twf-logo-<variante>-<größe>.png

Motiv: ein Schild ("Wall") aus drei Balken in den Ampelfarben des Addons
(grün, gold, rot), im Glanz-Look der TWF-Lebensbalken.
"""
import math
import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

S = 4                     # Überabtastung für glatte Kanten
N = 1024                  # Zielgröße in Pixel
W = N * S

BG_INNER = (30, 38, 54)
BG_OUTER = (6, 8, 12)
STEEL_LIGHT = (232, 205, 120)   # goldener Rand, hell
STEEL_DARK = (120, 86, 28)      # goldener Rand, dunkel
INSIDE = (14, 17, 24)
BAR_FIRST = 0.115               # Abstand des ersten Balkens von der Schildoberkante (Anteil der Höhe)
BAR_HEIGHT = 0.175              # Höhe eines Balkens (Anteil der Schildhöhe)
BAR_GAP = 0.045                 # Abstand zwischen den Balken
BARS = [                        # (Farbe hell, Farbe dunkel)
    ((112, 224, 96), (30, 120, 40)),     # grün
    ((255, 214, 92), (176, 112, 14)),    # gold
    ((240, 84, 70), (140, 22, 22)),      # rot
]


def shield(cx, top, width, height, inset=0.0):
    """Punkte eines Wappenschilds (oben gerade, unten spitz zulaufend)."""
    half = width / 2 - inset
    t = top + inset
    straight = top + height * 0.42          # bis hier senkrechte Seiten
    tip = top + height - inset * 1.35
    pts = [(cx - half, t), (cx + half, t), (cx + half, straight)]
    steps = 48
    for i in range(1, steps + 1):           # rechte Seite: läuft spitz zur Mitte
        a = i / steps
        pts.append((cx + half * (1 - a ** 2.1), straight + (tip - straight) * a))
    for i in range(steps - 1, -1, -1):      # linke Seite zurück nach oben
        a = i / steps
        pts.append((cx - half * (1 - a ** 2.1), straight + (tip - straight) * a))
    return pts


def vertical_gradient(size, top_color, bottom_color, y0, y1):
    img = Image.new('RGB', size, top_color)
    px = img.load()
    for y in range(size[1]):
        a = min(1.0, max(0.0, (y - y0) / max(1, (y1 - y0))))
        c = tuple(int(top_color[i] + (bottom_color[i] - top_color[i]) * a) for i in range(3))
        for x in range(size[0]):
            px[x, y] = c
    return img


def background():
    img = Image.new('RGB', (N, N), BG_OUTER)
    px = img.load()
    cx, cy, r = N / 2, N * 0.46, N * 0.78
    for y in range(N):
        for x in range(N):
            d = min(1.0, math.hypot(x - cx, y - cy) / r)
            a = d ** 1.6
            px[x, y] = tuple(int(BG_INNER[i] + (BG_OUTER[i] - BG_INNER[i]) * a) for i in range(3))
    return img.resize((W, W), Image.BICUBIC)


def mask_of(points):
    m = Image.new('L', (W, W), 0)
    ImageDraw.Draw(m).polygon(points, fill=255)
    return m


def build(with_text):
    img = background().convert('RGBA')
    cx = W / 2
    top = W * (0.105 if with_text else 0.14)
    width = W * (0.60 if with_text else 0.66)
    height = W * (0.66 if with_text else 0.73)

    outer = shield(cx, top, width, height)
    border = W * 0.030
    inner = shield(cx, top, width, height, inset=border)

    # Schlagschatten und leichter roter Schein hinter dem Schild
    glow = Image.new('RGBA', (W, W), (0, 0, 0, 0))
    ImageDraw.Draw(glow).polygon(shield(cx, top + W * 0.012, width * 1.05, height * 1.04), fill=(220, 60, 40, 120))
    img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(W * 0.05)))
    shadow = Image.new('RGBA', (W, W), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).polygon([(x, y + W * 0.018) for x, y in outer], fill=(0, 0, 0, 200))
    img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(W * 0.018)))

    # Goldener Rand mit Verlauf
    rim = vertical_gradient((W, W), STEEL_LIGHT, STEEL_DARK, int(top), int(top + height)).convert('RGBA')
    img.paste(rim, (0, 0), mask_of(outer))

    # Dunkle Innenfläche
    inner_mask = mask_of(inner)
    img.paste(Image.new('RGBA', (W, W), INSIDE + (255,)), (0, 0), inner_mask)

    # Drei Balken, am Schild beschnitten, mit Glanz wie die TWF-Lebensbalken
    for i, (light, dark) in enumerate(BARS):
        a = top + height * (BAR_FIRST + i * (BAR_HEIGHT + BAR_GAP))
        b = a + height * BAR_HEIGHT
        bar = vertical_gradient((W, W), light, dark, int(a), int(b)).convert('RGBA')
        bar_mask = Image.new('L', (W, W), 0)
        ImageDraw.Draw(bar_mask).rectangle([0, a, W, b], fill=255)
        clip = Image.composite(bar_mask, Image.new('L', (W, W), 0), inner_mask)
        img.paste(bar, (0, 0), clip)
        # Glanzstreifen oben
        gloss_mask = Image.new('L', (W, W), 0)
        ImageDraw.Draw(gloss_mask).rectangle([0, a + (b - a) * 0.10, W, a + (b - a) * 0.42], fill=70)
        gloss_clip = Image.composite(gloss_mask, Image.new('L', (W, W), 0), inner_mask)
        img.paste(Image.new('RGBA', (W, W), (255, 255, 255, 255)), (0, 0), gloss_clip)
        # dunkle Unterkante
        edge_mask = Image.new('L', (W, W), 0)
        ImageDraw.Draw(edge_mask).rectangle([0, b - (b - a) * 0.10, W, b], fill=90)
        edge_clip = Image.composite(edge_mask, Image.new('L', (W, W), 0), inner_mask)
        img.paste(Image.new('RGBA', (W, W), (0, 0, 0, 255)), (0, 0), edge_clip)

    # Feine helle Innenkante am Rand
    line = Image.new('RGBA', (W, W), (0, 0, 0, 0))
    ImageDraw.Draw(line).line(inner + [inner[0]], fill=(255, 240, 190, 110), width=int(W * 0.004))
    img.alpha_composite(line)

    if with_text:
        font = ImageFont.truetype('C:/Windows/Fonts/impact.ttf', int(W * 0.155))
        text = 'TWF'
        d = ImageDraw.Draw(img)
        box = d.textbbox((0, 0), text, font=font)
        tw = box[2] - box[0]
        x = cx - tw / 2 - box[0]
        y = W * 0.800
        sh = Image.new('RGBA', (W, W), (0, 0, 0, 0))
        ImageDraw.Draw(sh).text((x, y + W * 0.008), text, font=font, fill=(0, 0, 0, 230))
        img.alpha_composite(sh.filter(ImageFilter.GaussianBlur(W * 0.008)))
        grad = vertical_gradient((W, W), (255, 232, 150), (200, 132, 24), int(y + W * 0.02), int(y + W * 0.17)).convert('RGBA')
        tmask = Image.new('L', (W, W), 0)
        ImageDraw.Draw(tmask).text((x, y), text, font=font, fill=255)
        img.paste(grad, (0, 0), tmask)

    return img.resize((N, N), Image.LANCZOS)


out_dir = 'ThreatWallForever/logo'
os.makedirs(out_dir, exist_ok=True)
for name, with_text in (('schild', False), ('schild-twf', True)):
    logo = build(with_text)
    for size in (1024, 400, 64):
        path = f'{out_dir}/twf-logo-{name}-{size}.png'
        logo.resize((size, size), Image.LANCZOS).convert('RGB').save(path)
        print(path)
