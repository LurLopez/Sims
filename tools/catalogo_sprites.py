#!/usr/bin/env python3
"""Build visual contact sheets for the Minijuego_Cocina sprite pack."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
ART = ROOT / "Imagenes" / "Minijuego_Cocina"
OUT = ROOT / "Arte_Fuente" / "Minijuego_Cocina" / "Catalogo"
FONT_TIT = ROOT / "Fuentes" / "UI" / "Bricolage-800.ttf"
FONT_UI = ROOT / "Fuentes" / "UI" / "DMSans-700.ttf"

PAGES = [
    ("COMIDA", "Platos, ingredientes y recetas", [
        ("Platos", ART / "Comida" / "Platos"),
        ("Ingredientes", ART / "Comida" / "Ingredientes"),
        ("Extras", ART / "Comida" / "Extras"),
    ]),
    ("PERSONAJES", "Chef protagonista, poses y clientes", [
        ("Chef", ART / "Chef", False),
        ("Poses", ART / "Chef" / "Poses"),
        ("Clientes", ART / "Clientes", False),
        ("Clientes enojados", ART / "Clientes" / "Enojados"),
    ]),
    ("COCINA", "Estaciones, mostrador, emplatado y props", [
        ("Estaciones", ART / "Estaciones"),
        ("Mostrador", ART / "Mostrador"),
        ("Emplatado y props", ART / "Emplatado"),
    ]),
    ("UI Y AMBIENTE", "HUD, decoración y efectos", [
        ("UI", ART / "UI"),
        ("Decoración", ART / "Decoracion"),
        ("Efectos", ART / "Efectos"),
    ]),
]


def rounded(draw, box, radius, fill, outline):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=2)


def fit(im, w, h):
    k = min(w / im.width, h / im.height)
    return im.resize((max(1, round(im.width * k)), max(1, round(im.height * k))), Image.LANCZOS)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for page_i, (title, subtitle, groups) in enumerate(PAGES, start=1):
        files = []
        for group_name, folder, *rest in groups:
            recursive = rest[0] if rest else True
            if folder.exists():
                paths = sorted(folder.rglob("*.png") if recursive else folder.glob("*.png"))
                files += [(group_name, p) for p in paths]
        cols = 6
        cell_w, cell_h = 262, 282
        margin = 40
        header = 110
        rows = (len(files) + cols - 1) // cols
        W = margin * 2 + cols * cell_w
        H = header + rows * cell_h + margin
        canvas = Image.new("RGB", (W, H), (16, 22, 33))
        d = ImageDraw.Draw(canvas)
        # background texture: subtle grid
        for x in range(0, W, 40):
            d.line((x, 0, x, H), fill=(22, 30, 43), width=1)
        for y in range(0, H, 40):
            d.line((0, y, W, y), fill=(22, 30, 43), width=1)
        d.text((margin, 28), title, font=ImageFont.truetype(str(FONT_TIT), 44), fill=(255, 210, 120))
        d.text((margin, 78), subtitle, font=ImageFont.truetype(str(FONT_UI), 18), fill=(170, 188, 210))
        d.text((W - margin - 170, 38), f"{len(files)} sprites", font=ImageFont.truetype(str(FONT_UI), 20),
               fill=(120, 200, 240))
        for i, (group_name, path) in enumerate(files):
            r, c = divmod(i, cols)
            x = margin + c * cell_w
            y = header + r * cell_h
            rounded(d, (x, y, x + cell_w - 16, y + cell_h - 16), 18, (28, 38, 54), (55, 74, 98))
            # checkerboard inside the cell
            for cy in range(y + 8, y + cell_h - 24, 12):
                for cx in range(x + 8, x + cell_w - 24, 12):
                    if ((cx - x) // 12 + (cy - y) // 12) % 2 == 0:
                        d.rectangle((cx, cy, cx + 11, cy + 11), fill=(32, 43, 60))
            try:
                im = Image.open(path).convert("RGBA")
            except Exception:
                continue
            im = fit(im, cell_w - 56, cell_h - 86)
            px = x + (cell_w - 16 - im.width) // 2
            py = y + 14 + (cell_h - 86 - im.height) // 2
            canvas.paste(im, (px, py), im)
            label = path.stem.replace("_", " ")
            font = ImageFont.truetype(str(FONT_UI), 16 if len(label) < 22 else 13)
            tw = d.textlength(label, font=font)
            d.text((x + (cell_w - 16 - tw) / 2, y + cell_h - 58), label, font=font, fill=(232, 240, 250))
            small = ImageFont.truetype(str(FONT_UI), 12)
            tw2 = d.textlength(group_name, font=small)
            d.text((x + (cell_w - 16 - tw2) / 2, y + cell_h - 36), group_name, font=small, fill=(120, 150, 180))
        d.text((margin, H - 30), "SIMS · Minijuego de Cocina · pack de sprites", font=ImageFont.truetype(str(FONT_UI), 13),
               fill=(90, 110, 135))
        d.text((W - margin - 60, H - 30), f"{page_i}/{len(PAGES)}", font=ImageFont.truetype(str(FONT_UI), 13),
               fill=(90, 110, 135))
        out = OUT / f"catalogo_{page_i}_{title.lower().replace(' ', '_').replace('í', 'i')}.jpg"
        canvas.save(out, quality=90)
        print(out, canvas.size, len(files))


if __name__ == "__main__":
    main()
