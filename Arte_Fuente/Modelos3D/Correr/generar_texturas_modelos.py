#!/usr/bin/env python3
"""
Generador de texturas UV estilizadas para los modelos Blender de PARK RUSH 3D.
Se ejecuta con el python3 del sistema (Pillow + NumPy) y guarda los PNG en
`Imagenes/Minijuego_Correr/Texturas3D/` para ser embebidos en los .glb y/o
alternados por librea en `Runner_Escenario_3D.gd`.
"""

import math
import os
import random
import numpy as np
from PIL import Image, ImageDraw, ImageFont

DIR_ACTUAL = os.path.dirname(os.path.abspath(__file__))
RAIZ_PROYECTO = os.path.abspath(os.path.join(DIR_ACTUAL, "..", "..", ".."))
DIR_TEX = os.path.join(RAIZ_PROYECTO, "Imagenes", "Minijuego_Correr", "Texturas3D")
os.makedirs(DIR_TEX, exist_ok=True)


def hex_rgb(h: str):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def cargar_fuente(tam: int):
    for f in (
        os.path.join(RAIZ_PROYECTO, "Fuentes", "UI", "TitanOne-400.ttf"),
        os.path.join(RAIZ_PROYECTO, "Fuentes", "UI", "RussoOne-400.ttf"),
        os.path.join(RAIZ_PROYECTO, "Fuentes", "UI", "Bricolage-800.ttf"),
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    ):
        if os.path.exists(f):
            return ImageFont.truetype(f, tam)
    return ImageFont.load_default()


def altura_a_normal(h_arr: np.ndarray, fuerza: float = 2.0) -> Image.Image:
    dx = (np.roll(h_arr, -1, axis=1) - np.roll(h_arr, 1, axis=1)) * 0.5 * fuerza
    dy = (np.roll(h_arr, -1, axis=0) - np.roll(h_arr, 1, axis=0)) * 0.5 * fuerza
    nz = np.ones_like(h_arr)
    ln = np.sqrt(dx * dx + dy * dy + nz * nz) + 1e-6
    r = np.clip((-dx / ln * 0.5 + 0.5) * 255.0, 0, 255).astype(np.uint8)
    g = np.clip((-dy / ln * 0.5 + 0.5) * 255.0, 0, 255).astype(np.uint8)
    b = np.clip((nz / ln * 0.5 + 0.5) * 255.0, 0, 255).astype(np.uint8)
    return Image.fromarray(np.stack([r, g, b], axis=-1), "RGB")


def dibujar_grafiti(img: Image.Image, cx: int, cy: int, texto: str, c1, c2, c_acc, semilla: int):
    rng = random.Random(semilla)
    capa = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(capa)

    for _ in range(18):
        ox = rng.randint(-150, 150)
        oy = rng.randint(-55, 55)
        r = rng.randint(16, 46)
        col = c_acc if rng.random() < 0.55 else c1
        d.ellipse([cx + ox - r, cy + oy - r, cx + ox + r, cy + oy + r], fill=(*col, rng.randint(160, 225)))

    for _ in range(24):
        dx = rng.randint(-170, 170)
        dy = rng.randint(-35, 65)
        r = rng.randint(3, 8)
        col = rng.choice([c1, c2, c_acc, (255, 255, 255)])
        d.ellipse([cx + dx - r, cy + dy - r, cx + dx + r, cy + dy + r], fill=(*col, 220))
        if rng.random() < 0.45:
            d.rectangle([cx + dx - 2, cy + dy, cx + dx + 2, cy + dy + rng.randint(10, 30)], fill=(*col, 200))

    txt_img = Image.new("RGBA", (420, 180), (0, 0, 0, 0))
    td = ImageDraw.Draw(txt_img)
    fuente = cargar_fuente(88)
    bb = td.textbbox((0, 0), texto, font=fuente)
    tw, th = bb[2] - bb[0], bb[3] - bb[1]
    tx = (420 - tw) // 2 - bb[0]
    ty = (180 - th) // 2 - bb[1]

    for dep in range(12, 0, -2):
        td.text((tx + dep, ty + dep), texto, font=fuente, fill=(18, 22, 36, 255), stroke_width=8, stroke_fill=(18, 22, 36, 255))
    td.text((tx, ty), texto, font=fuente, fill=(255, 255, 255, 255), stroke_width=11, stroke_fill=(255, 255, 255, 240))
    td.text((tx, ty), texto, font=fuente, fill=(18, 22, 36, 255), stroke_width=7, stroke_fill=(18, 22, 36, 255))

    mask = Image.new("L", (420, 180), 0)
    ImageDraw.Draw(mask).text((tx, ty), texto, font=fuente, fill=255)
    grad = Image.new("RGBA", (420, 180), (0, 0, 0, 0))
    gd = ImageDraw.Draw(grad)
    for y in range(180):
        u = max(0.0, min(1.0, (y - 35) / 100.0))
        rc = tuple(int(c1[k] * (1.0 - u) + c2[k] * u) for k in range(3)) + (255,)
        gd.line([(0, y), (420, y)], fill=rc)
    txt_img.paste(grad, (0, 0), mask)

    rot = txt_img.rotate(rng.uniform(-7.0, 7.0), resample=Image.BICUBIC, expand=True)
    capa.alpha_composite(rot, (cx - rot.width // 2, cy - rot.height // 2))
    res = Image.alpha_composite(img.convert("RGBA"), capa)
    img.paste(res.convert("RGB"))


def generar_texturas_vagon():
    # Paleta fiel a Subway Surfers (trains.png): amarillo oro + franja roja, naranja + frente lima,
    # acero pizarra acanalado (carga) y azul metro expreso con remates pintados con AO.
    libreas = [
        ("EXPRESS", "#f3c330", "#c98412", "#c82d1f", "#2f4354", "RUSH", "#fde047", "#fb923c", "#38bdf8", False),
        ("METRO 1", "#ea491c", "#b82d10", "#a6c624", "#9e1c14", "BOOM", "#bef264", "#22c55e", "#fde047", False),
        ("CARGA 7", "#769cb5", "#3b5264", "#253442", "#9fb8c9", "WILD", "#f97316", "#ea580c", "#fde047", True),
        ("CITY EX", "#257be8", "#134aa1", "#facc15", "#1c2d42", "SURF", "#38bdf8", "#facc15", "#f472b6", False),
    ]

    # Cristal estilo Subway Surfers (degradado celeste glaciar + reflejo diagonal + marco oscuro AO)
    cw, ch = 256, 256
    c_arr = np.zeros((ch, cw, 3), dtype=np.float32)
    c_top_g = np.array([118.0, 174.0, 208.0])
    c_bot_g = np.array([204.0, 232.0, 246.0])
    for y in range(ch):
        t = y / float(ch - 1)
        c_arr[y, :] = c_top_g * (1.0 - t) + c_bot_g * t
    c_img = Image.fromarray(c_arr.astype(np.uint8), "RGB")
    cd = ImageDraw.Draw(c_img)
    cd.polygon([(18, ch), (94, 0), (144, 0), (68, ch)], fill=(214, 240, 252))
    cd.polygon([(148, ch), (186, 0), (206, 0), (168, ch)], fill=(238, 250, 255))
    cd.rectangle([0, 0, cw - 1, ch - 1], outline=(28, 38, 52), width=10)
    c_img.save(os.path.join(DIR_TEX, "vagon_bl_cristal.png"), "PNG", optimize=True)

    cem = Image.new("RGB", (cw, ch), (255, 212, 122))
    ImageDraw.Draw(cem).rectangle([0, 0, cw - 1, ch - 1], outline=(0, 0, 0), width=16)
    cem.save(os.path.join(DIR_TEX, "vagon_bl_cristal_em.png"), "PNG", optimize=True)

    # Techo abovedado pizarra azulada con costillas pintadas + AO (trains.png)
    tw, th = 512, 512
    t_arr = np.zeros((th, tw, 3), dtype=np.float32)
    for x in range(tw):
        # Bóveda más luminosa en el centro y más oscura hacia los aleros
        d_c = abs(x - tw * 0.5) / (tw * 0.5)
        shade = 1.0 - 0.34 * (d_c ** 1.6)
        t_arr[:, x, 0] = 124.0 * shade
        t_arr[:, x, 1] = 148.0 * shade
        t_arr[:, x, 2] = 172.0 * shade
    t_img = Image.fromarray(t_arr.astype(np.uint8), "RGB")
    td = ImageDraw.Draw(t_img)
    h_arr = np.full((th, tw), 0.55, dtype=np.float32)
    for rx in range(28, tw - 28, 36):
        td.rectangle([rx, 0, rx + 5, th], fill=(82, 100, 118))
        td.rectangle([rx + 5, 0, rx + 10, th], fill=(166, 188, 208))
        h_arr[:, rx:rx + 5] = 0.28
        h_arr[:, rx + 5:rx + 10] = 0.82
    for jy in range(0, th, 64):
        td.rectangle([0, jy, tw, jy + 8], fill=(60, 74, 92))
        h_arr[jy:jy + 8, :] = 0.22
    t_img.save(os.path.join(DIR_TEX, "vagon_bl_techo.png"), "PNG", optimize=True)
    altura_a_normal(h_arr, 2.2).save(os.path.join(DIR_TEX, "vagon_bl_techo_normal.png"), "PNG", optimize=True)

    f_led = cargar_fuente(64)
    for idx, (ruta, c_top_h, c_bot_h, c_stripe_h, c_cab_h, g_txt, gc1_h, gc2_h, gacc_h, es_carga) in enumerate(libreas):
        c_top = hex_rgb(c_top_h)
        c_bot = hex_rgb(c_bot_h)
        c_stripe = hex_rgb(c_stripe_h)
        c_cab = hex_rgb(c_cab_h)
        w, h = 1024, 512
        arr = np.zeros((h, w, 3), dtype=np.float32)
        for y in range(h):
            u = y / float(h)
            for ch_i in range(3):
                arr[y, :, ch_i] = c_top[ch_i] * (1.0 - u) + c_bot[ch_i] * u
        img = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGB")
        d = ImageDraw.Draw(img)

        # Banda superior bajo techo con sombra AO y franja característica inferior
        d.rectangle([0, 0, w, 30], fill=c_cab)
        d.rectangle([0, 30, w, 38], fill=(22, 30, 42))

        if es_carga:
            # Vagón de carga de acero acanalado verticalmente (train_cargo_0 de trains.png)
            for sx in range(32, w - 32, 64):
                d.rectangle([sx, 38, sx + 18, h - 18], fill=c_stripe)
                d.rectangle([sx + 18, 38, sx + 30, h - 18], fill=c_cab)
                d.rectangle([sx + 30, 38, sx + 48, h - 18], fill=(74, 102, 122))
        else:
            # Franja horizontal Subway Surfers en la mitad inferior + línea de sombra
            d.rectangle([0, 286, w, 344], fill=c_stripe)
            d.rectangle([0, 282, w, 286], fill=(32, 24, 20))
            d.rectangle([0, 344, w, 350], fill=(32, 24, 20))
            # Juntas verticales de chapa + remaches (fuera del rango u<0.07 usado en frente cabina)
            for px in (110, 240, 390, 512, 634, 784, 914):
                d.line([(px, 38), (px, h - 10)], fill=(40, 32, 26), width=2)

        # Sombreado AO inferior junto al zócalo de acero
        for y in range(h - 36, h):
            alpha = (y - (h - 36)) / 36.0
            factor = 1.0 - 0.38 * alpha
            d.line([(0, y), (w, y)], fill=None)
            row = np.array(img.crop((0, y, w, y + 1)), dtype=np.float32) * factor
            img.paste(Image.fromarray(np.clip(row, 0, 255).astype(np.uint8), "RGB"), (0, y))

        dibujar_grafiti(img, 330 if idx % 2 == 0 else 690, 328, g_txt,
                        hex_rgb(gc1_h), hex_rgb(gc2_h), hex_rgb(gacc_h), 700 + idx)
        img.save(os.path.join(DIR_TEX, f"vagon_bl_carroceria_{idx}.png"), "PNG", optimize=True)

        lw, lh = 512, 128
        l_img = Image.new("RGB", (lw, lh), (16, 22, 34))
        ld = ImageDraw.Draw(l_img)
        ld.rounded_rectangle([8, 8, lw - 9, lh - 9], radius=14, fill=(14, 20, 32), outline=(140, 156, 176), width=6)
        bb = ld.textbbox((0, 0), ruta, font=f_led)
        rw, rh = bb[2] - bb[0], bb[3] - bb[1]
        ld.text(((lw - rw) // 2 - bb[0], (lh - rh) // 2 - bb[1] - 4), ruta, font=f_led, fill=(255, 226, 72))
        l_img.save(os.path.join(DIR_TEX, f"vagon_bl_letrero_{idx}.png"), "PNG", optimize=True)

    print("[OK] Texturas UV del vagón generadas.")


def generar_texturas_obstaculos():
    # 1. Rampa ferroviaria oro-arena (train_ramp_0 de trains.png) con chevrón luminoso
    w, h = 512, 512
    img = Image.new("RGB", (w, h), (206, 152, 46))
    em = Image.new("RGB", (w, h), (0, 0, 0))
    d = ImageDraw.Draw(img)
    ed = ImageDraw.Draw(em)
    # Sombreado AO en los bordes laterales del tablero de carga
    for bx in range(44, 90):
        fac = 0.72 + 0.28 * ((bx - 44) / 46.0)
        col_s = (int(206 * fac), int(152 * fac), int(46 * fac))
        d.line([(bx, 0), (bx, h)], fill=col_s)
        d.line([(w - 1 - bx, 0), (w - 1 - bx, h)], fill=col_s)
    for y in range(0, h, 24):
        d.line([(44, y), (w - 44, y)], fill=(154, 108, 24), width=3)
    for x0 in (0, w - 44):
        d.rectangle([x0, 0, x0 + 44, h], fill=(54, 78, 98))
        for sy in range(-48, h + 48, 44):
            d.polygon([(x0 + 6, sy), (x0 + 38, sy + 18), (x0 + 38, sy + 36), (x0 + 6, sy + 18)], fill=(142, 174, 198))
    for cy in (80, 204, 328, 452):
        pts_o = [(w // 2, cy - 50), (w - 64, cy + 16), (w - 64, cy + 54), (w // 2, cy - 10), (64, cy + 54), (64, cy + 16)]
        pts_i = [(w // 2, cy - 40), (w - 76, cy + 18), (w - 76, cy + 42), (w // 2, cy - 20), (76, cy + 42), (76, cy + 18)]
        d.polygon(pts_o, fill=(44, 32, 18))
        d.polygon(pts_i, fill=(254, 244, 118))
        ed.polygon(pts_i, fill=(255, 224, 68))
    img.save(os.path.join(DIR_TEX, "rampa_bl_albedo.png"), "PNG", optimize=True)
    em.save(os.path.join(DIR_TEX, "rampa_bl_emission.png"), "PNG", optimize=True)

    # 2. Valla baja estilo Subway Surfers (rayas diagonales rojo ladrillo / crema cálido con remaches)
    vw, vh = 512, 128
    v_img = Image.new("RGB", (vw, vh), (242, 236, 224))
    vd = ImageDraw.Draw(v_img)
    for sx in range(-vh, vw + vh, 86):
        vd.polygon([(sx, 0), (sx + 44, 0), (sx - 12, vh), (sx - 56, vh)], fill=(208, 44, 34))
    vd.rectangle([0, 0, vw - 1, vh - 1], outline=(38, 32, 34), width=10)
    for rx in (28, 160, 352, vw - 28):
        for ry in (22, vh - 22):
            vd.ellipse([rx - 6, ry - 6, rx + 6, ry + 6], fill=(56, 48, 48), outline=(218, 226, 236), width=2)
    v_img.save(os.path.join(DIR_TEX, "valla_bl_albedo.png"), "PNG", optimize=True)

    # 3. Arco de gálibo estilo Subway Surfers (blocker_roll_0: panel pizarra oscura + halo lima + cenefas rojo ladrillo)
    aw, ah = 512, 256
    a_img = Image.new("RGB", (aw, ah), (34, 42, 46))
    ad = ImageDraw.Draw(a_img)
    for rad, col in ((150, (66, 94, 42)), (110, (112, 152, 46)), (72, (162, 206, 56))):
        ad.ellipse([aw // 2 - rad, ah - rad + 26, aw // 2 + rad, ah + rad + 26], fill=col)
    for by in (0, ah - 40):
        ad.rectangle([0, by, aw, by + 40], fill=(208, 44, 34))
        for sx in range(-64, aw + 64, 68):
            ad.polygon([(sx, by), (sx + 34, by), (sx + 10, by + 40), (sx - 24, by + 40)], fill=(242, 236, 224))
    ad.line([(0, 40), (aw, 40)], fill=(24, 24, 28), width=6)
    ad.line([(0, ah - 40), (aw, ah - 40)], fill=(24, 24, 28), width=6)
    ad.rectangle([0, 0, aw - 1, ah - 1], outline=(24, 24, 28), width=10)
    a_img.save(os.path.join(DIR_TEX, "arco_bl_albedo.png"), "PNG", optimize=True)

    # 4. Placa luminosa del túnel
    tw, th = 512, 128
    t_img = Image.new("RGB", (tw, th), (18, 32, 64))
    td = ImageDraw.Draw(t_img)
    td.rounded_rectangle([6, 6, tw - 7, th - 7], radius=14, fill=(18, 44, 96), outline=(250, 204, 21), width=8)
    f_t = cargar_fuente(56)
    txt = "METRO  LINEA 1"
    bb = td.textbbox((0, 0), txt, font=f_t)
    td.text(((tw - (bb[2] - bb[0])) // 2 - bb[0], (th - (bb[3] - bb[1])) // 2 - bb[1] - 2),
            txt, font=f_t, fill=(255, 240, 120))
    t_img.save(os.path.join(DIR_TEX, "tunel_bl_letrero.png"), "PNG", optimize=True)

    print("[OK] Texturas UV de obstáculos generadas.")


if __name__ == "__main__":
    generar_texturas_vagon()
    generar_texturas_obstaculos()
