# Dibuja el ícono de MisPendientes (1024x1024, RGB sin canal alfa, como lo pide App Store Connect).
# Uso: uv run --with pillow python herramientas/generar_icono.py
import os
from PIL import Image, ImageDraw

AQUI = os.path.dirname(os.path.abspath(__file__))
DESTINO = os.path.join(AQUI, "..", "MisPendientes", "Assets.xcassets", "AppIcon.appiconset", "icono-1024.png")
S = 4  # supermuestreo para bordes suaves
N = 1024 * S

img = Image.new("RGB", (N, N))
d = ImageDraw.Draw(img)
arriba, abajo = (76, 110, 245), (54, 79, 199)  # degradado índigo
for y in range(N):
    t = y / (N - 1)
    d.line([(0, y), (N, y)], fill=tuple(round(a + (b - a) * t) for a, b in zip(arriba, abajo)))

# Tarjeta blanca
x0, y0, x1, y1 = 232 * S, 196 * S, 792 * S, 828 * S
d.rounded_rectangle([x0 + 10 * S, y0 + 22 * S, x1 + 10 * S, y1 + 22 * S], radius=84 * S, fill=(40, 58, 160))  # sombra
d.rounded_rectangle([x0, y0, x1, y1], radius=84 * S, fill=(255, 255, 255))

verde, gris, linea = (47, 158, 68), (173, 181, 189), (222, 226, 230)
filas = [(330, True, 300), (512, True, 250), (694, False, 280)]
for cy, hecha, largo in filas:
    cx, r = 352 * S, 58 * S
    cy *= S
    if hecha:
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=verde)
        w = 22 * S
        d.line([(cx - 28 * S, cy + 2 * S), (cx - 6 * S, cy + 24 * S), (cx + 32 * S, cy - 22 * S)], fill="white", width=w, joint="curve")
        for px, py in [(cx - 28 * S, cy + 2 * S), (cx + 32 * S, cy - 22 * S), (cx - 6 * S, cy + 24 * S)]:
            d.ellipse([px - w // 2, py - w // 2, px + w // 2, py + w // 2], fill="white")
    else:
        d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=gris, width=16 * S)
    lx = 450 * S
    d.rounded_rectangle([lx, cy - 22 * S, lx + largo * S, cy + 22 * S], radius=22 * S, fill=linea if hecha else (73, 80, 87))

img = img.resize((1024, 1024), Image.LANCZOS)
img.save(DESTINO)
print("Ícono:", os.path.normpath(DESTINO), img.size, img.mode)
