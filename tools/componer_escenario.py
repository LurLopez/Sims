#!/usr/bin/env python3
"""Compose a 1280x720 preview of the casual cooking-game kitchen from the sprite pack.

Not shipped in the game: this is the layout guide used to place the sprites and to
check scale and readability before building the Godot scene.
"""
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
ART = ROOT / "Imagenes" / "Minijuego_Cocina"
OUT = ROOT / "Arte_Fuente" / "Minijuego_Cocina" / "escenario_preview.png"
LAYOUT_PATH = ROOT / "Imagenes" / "Minijuego_Cocina" / "escenario_layout.json"
LAYOUT = []
W, H = 1280, 720

FONT_TIT = ROOT / "Fuentes" / "UI" / "Bricolage-800.ttf"
FONT_UI = ROOT / "Fuentes" / "UI" / "DMSans-700.ttf"


def load(rel: str) -> Image.Image:
    im = Image.open(ART / rel).convert("RGBA")
    im._rel = rel
    return im


def fit(im: Image.Image, max_w: float, max_h: float) -> Image.Image:
    k = min(max_w / im.width, max_h / im.height)
    out = im.resize((max(1, round(im.width * k)), max(1, round(im.height * k))), Image.LANCZOS)
    out._rel = getattr(im, "_rel", "")
    return out


def record(im: Image.Image, x: int, y: int, modo: str) -> None:
    rel = getattr(im, "_rel", "")
    if rel:
        LAYOUT.append({"ruta": rel, "x": int(x), "y": int(y),
                       "w": int(im.width), "h": int(im.height), "modo": modo})


def paste_center(canvas: Image.Image, im: Image.Image, cx: float, cy: float,
                 max_w: float = 1e9, max_h: float = 1e9,
                 shadow: int = 0, shadow_offset: tuple = (0, 8)) -> tuple:
    im = fit(im, max_w, max_h)
    x = round(cx - im.width / 2)
    y = round(cy - im.height / 2)
    if shadow:
        sil = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
        sil.paste((0, 0, 0, shadow), (x + shadow_offset[0], y + shadow_offset[1]), im)
        canvas.alpha_composite(sil.filter(ImageFilter.GaussianBlur(10)))
    canvas.alpha_composite(im, (x, y))
    record(im, x, y, "center")
    return x, y, im.width, im.height


def paste_bottom(canvas: Image.Image, im: Image.Image, cx: float, bottom: float,
                 max_w: float = 1e9, max_h: float = 1e9,
                 shadow: int = 0) -> tuple:
    im = fit(im, max_w, max_h)
    x = round(cx - im.width / 2)
    y = round(bottom - im.height)
    if shadow:
        sil = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
        sil.paste((0, 0, 0, shadow), (x, y + 6), im)
        canvas.alpha_composite(sil.filter(ImageFilter.GaussianBlur(8)))
    canvas.alpha_composite(im, (x, y))
    record(im, x, y, "bottom")
    return x, y, im.width, im.height


def paste_top(canvas: Image.Image, im: Image.Image, x: float, y: float,
              max_w: float = 1e9, max_h: float = 1e9) -> tuple:
    im = fit(im, max_w, max_h)
    canvas.alpha_composite(im, (round(x), round(y)))
    record(im, round(x), round(y), "top")
    return round(x), round(y), im.width, im.height


def text(draw: ImageDraw.ImageDraw, xy, s, size, fill=(255, 255, 255, 255),
         font_path=FONT_TIT, anchor="la", stroke=0, stroke_fill=(0, 0, 0, 180)):
    f = ImageFont.truetype(str(font_path), size)
    draw.text(xy, s, font=f, fill=fill, anchor=anchor,
              stroke_width=stroke, stroke_fill=stroke_fill)


def main():
    bg = fit(load("Fondo_Restaurante.png"), W, H)
    canvas = Image.new("RGBA", (W, H), (18, 24, 36, 255))
    canvas.alpha_composite(bg, (0, 0))

    # Warm wash + vignette so the foreground reads against the backdrop.
    warm = Image.new("RGBA", (W, H), (255, 190, 110, 0))
    warm.putalpha(16)
    canvas.alpha_composite(warm)
    vign = Image.new("L", (W, H), 0)
    vd = ImageDraw.Draw(vign)
    vd.ellipse((-240, -180, W + 240, H + 260), fill=70)
    black = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    black.putalpha(Image.eval(vign, lambda v: 70 - v))
    canvas.alpha_composite(black)

    # ---------------------------------------------------------------- customers
    customers = [
        ("Clientes/Cliente_01_Nino.png", 402, 392, 200),
        ("Clientes/Cliente_02_Mujer.png", 636, 392, 205),
        ("Clientes/Cliente_03_Mayor.png", 870, 392, 200),
        ("Clientes/Cliente_04_Nina.png", 1104, 392, 196),
    ]
    for path, cx, bottom, h in customers:
        paste_bottom(canvas, load(path), cx, bottom, max_h=h, shadow=70)

    # ------------------------------------------------------- glass display case
    vitrina = load("Mostrador/Vitrina_Exposicion.png")
    vx, vy, vw, vh = paste_center(canvas, vitrina, 760, 430, max_w=760, max_h=205, shadow=90)
    paste_center(canvas, load("Comida/Platos/Hamburguesa_Sola.png"), vx + vw * 0.24, vy + vh * 0.55, max_h=58)
    paste_center(canvas, load("Comida/Platos/Perrito_Caliente.png"), vx + vw * 0.50, vy + vh * 0.54, max_h=52)
    paste_center(canvas, load("Comida/Platos/Cupcake.png"), vx + vw * 0.74, vy + vh * 0.58, max_h=54)
    paste_center(canvas, load("Comida/Platos/Refresco_Cola.png"), vx + vw * 0.88, vy + vh * 0.57, max_h=58)

    # -------------------------------------------------------------------- chef
    paste_bottom(canvas, load("Chef/Chef_Michelle.png"), 128, 660, max_h=545, shadow=100)

    # ------------------------------------------------- order tickets (4 clients)
    tickets = [
        ("UI/Ticket_Verde.png", "Comida/Platos/Hamburguesa_Sola.png", 402, 64, "12"),
        ("UI/Ticket_Verde.png", "Comida/Platos/Perrito_Caliente.png", 636, 64, "10"),
        ("UI/Ticket_Rojo.png", "Comida/Platos/Patatas_Fritas.png", 870, 64, "8"),
        ("UI/Ticket_Verde.png", "Comida/Platos/Refresco_Cola.png", 1104, 64, "6"),
    ]
    for ticket_path, food_path, cx, top, price in tickets:
        t = fit(load(ticket_path), 130, 168)
        tx, ty = round(cx - t.width / 2), top
        sil = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
        sil.paste((0, 0, 0, 95), (tx + 5, ty + 9), t)
        canvas.alpha_composite(sil.filter(ImageFilter.GaussianBlur(8)))
        canvas.alpha_composite(t, (tx, ty))
        LAYOUT.append({"ruta": ticket_path, "x": tx, "y": ty, "w": t.width, "h": t.height, "modo": "stretch"})
        paste_center(canvas, load(food_path), cx, ty + t.height * 0.46, max_h=48)
        d = ImageDraw.Draw(canvas)
        text(d, (cx, ty + t.height * 0.85), price, 19, (255, 255, 255, 255), FONT_UI, "mm")

    # ------------------------------------------------------- counter foreground
    mod = load("Mostrador/Modulo_Recto.png")
    for cx in (210, 640, 1070):
        paste_center(canvas, mod, cx, 550, max_w=460, max_h=220, shadow=80)

    frente = load("Mostrador/Frente_Mostrador.png")
    frente = frente.resize((W, 200), Image.LANCZOS)
    canvas.alpha_composite(frente, (0, 520))
    LAYOUT.append({"ruta": "Mostrador/Frente_Mostrador.png", "x": 0, "y": 520, "w": W, "h": 200, "modo": "stretch"})

    # ---------------------------------------------------------------- stations
    paste_bottom(canvas, load("Estaciones/Plancha.png"), 320, 520, max_w=260, max_h=185, shadow=65)
    paste_bottom(canvas, load("Estaciones/Freidora.png"), 520, 520, max_w=210, max_h=175, shadow=65)
    paste_bottom(canvas, load("Estaciones/Dispensador_Refrescos.png"), 700, 495, max_w=125, max_h=210, shadow=60)
    paste_bottom(canvas, load("Estaciones/Calentador_Comida.png"), 855, 520, max_w=215, max_h=165, shadow=65)
    paste_bottom(canvas, load("Estaciones/Tostador_Panes.png"), 1015, 520, max_w=150, max_h=150, shadow=55)
    paste_bottom(canvas, load("Mostrador/Caja_Registradora.png"), 1175, 530, max_w=185, max_h=155, shadow=60)

    # ------------------------------------------------------------ prepared food
    paste_center(canvas, load("Emplatado/Pila_Platos.png"), 245, 483, max_w=120, max_h=70, shadow=45)
    paste_center(canvas, load("Comida/Platos/Hamburguesa_Doble.png"), 245, 447, max_h=66, shadow=40)
    paste_center(canvas, load("Emplatado/Plato_Vacio.png"), 350, 492, max_w=90, max_h=60, shadow=35)
    paste_center(canvas, load("Comida/Platos/Perrito_Caliente.png"), 350, 461, max_h=50, shadow=35)
    paste_center(canvas, load("Comida/Platos/Patatas_Fritas.png"), 700, 481, max_h=76, shadow=45)
    paste_center(canvas, load("Comida/Platos/Refresco_Cola.png"), 900, 479, max_h=72, shadow=40)
    paste_center(canvas, load("Comida/Platos/Batido.png"), 960, 464, max_h=80, shadow=40)
    paste_center(canvas, load("Comida/Platos/Cupcake.png"), 1045, 490, max_h=54, shadow=35)

    # --------------------------------------------------------------- small props
    paste_center(canvas, load("Emplatado/Mostaza.png"), 450, 447, max_h=76, shadow=35)
    paste_center(canvas, load("Emplatado/Ketchup.png"), 485, 450, max_h=76, shadow=35)
    paste_center(canvas, load("Emplatado/Sal_Pimienta.png"), 630, 458, max_h=44, shadow=30)
    paste_center(canvas, load("Emplatado/Servilletero.png"), 1120, 484, max_h=70, shadow=35)
    paste_center(canvas, load("Emplatado/Bol_Lechuga.png"), 1155, 434, max_h=54, shadow=30)

    # lower shelf line on the counter front
    shelf = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shelf)
    sd.rectangle((0, 628, W, 636), fill=(18, 22, 30, 255))
    sd.rectangle((0, 636, W, 642), fill=(180, 190, 205, 255))
    sd.rectangle((0, 642, W, 648), fill=(70, 78, 92, 180))
    canvas.alpha_composite(shelf)
    paste_center(canvas, load("Emplatado/Bandejas_Apiladas.png"), 100, 600, max_h=54, shadow=35)
    paste_center(canvas, load("Emplatado/Pila_Platos.png"), 195, 600, max_h=52, shadow=35)
    paste_center(canvas, load("Emplatado/Servilletero.png"), 1115, 600, max_h=55, shadow=35)
    paste_center(canvas, load("UI/Bote_Propinas.png"), 1045, 605, max_h=50, shadow=35)

    # --------------------------------------------------------- coins and effects
    paste_center(canvas, load("UI/Pila_Monedas.png"), 1205, 605, max_h=78, shadow=55)
    paste_center(canvas, load("UI/Moneda.png"), 1240, 632, max_h=42, shadow=40)
    steam = load("Efectos/Vapor.png")
    for cx, cy, s in ((300, 370, 100), (500, 370, 90), (700, 405, 80)):
        e = fit(steam, s, s)
        e.putalpha(e.getchannel("A").point(lambda v: int(v * 0.5)))
        canvas.alpha_composite(e, (round(cx - e.width / 2), round(cy - e.height / 2)))
        record(e, round(cx - e.width / 2), round(cy - e.height / 2), "stretch")
    spark = load("Efectos/Chispas.png")
    sp = fit(spark, 88, 88)
    sp.putalpha(sp.getchannel("A").point(lambda v: int(v * 0.8)))
    canvas.alpha_composite(sp, (1180, 555))
    record(sp, 1180, 555, "stretch")

    # ------------------------------------------------------------------ top HUD
    hud = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    hd = ImageDraw.Draw(hud)
    hd.rectangle((0, 0, W, 58), fill=(14, 25, 42, 240))
    hd.rectangle((0, 58, W, 62), fill=(245, 158, 11, 255))
    canvas.alpha_composite(hud)

    banner = load("Decoracion/Toldo_Verde.png")
    b = fit(banner, 330, 150)
    canvas.alpha_composite(b, (-24, -18))
    LAYOUT.append({"ruta": "Decoracion/Toldo_Verde.png", "x": -24, "y": -18, "w": b.width, "h": b.height, "modo": "stretch"})
    d = ImageDraw.Draw(canvas)
    text(d, (28, 24), "BURGER", 34, (255, 255, 255, 255), FONT_TIT, "la", 2, (30, 70, 45, 220))
    text(d, (28, 58), "STREET", 24, (255, 243, 170, 255), FONT_TIT, "la", 2, (30, 70, 45, 220))

    paste_center(canvas, load("UI/Moneda.png"), 946, 30, max_h=32)
    text(d, (966, 31), "1.250", 19, (255, 236, 179, 255), FONT_UI, "lm")
    paste_center(canvas, load("UI/Gema.png"), 1072, 30, max_h=32)
    text(d, (1092, 31), "12", 19, (190, 250, 255, 255), FONT_UI, "lm")
    paste_center(canvas, load("UI/Reloj.png"), 1146, 30, max_h=32)
    text(d, (1166, 31), "00:45", 19, (255, 255, 255, 255), FONT_UI, "lm")
    paste_center(canvas, load("UI/Estrella_Dorada.png"), 1244, 30, max_h=28)

    paste_center(canvas, load("UI/Engranaje.png"), 36, 675, max_h=54, shadow=45)
    paste_center(canvas, load("UI/Flecha.png"), 1238, 674, max_h=52, shadow=45)

    final = canvas.convert("RGB")
    final.save(OUT, quality=94)
    LAYOUT_PATH.write_text(json.dumps(LAYOUT, indent=2, ensure_ascii=False), encoding="utf-8")
    print(OUT)
    print(LAYOUT_PATH, len(LAYOUT), "sprites")


if __name__ == "__main__":
    main()
