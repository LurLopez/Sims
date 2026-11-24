#!/usr/bin/env python3
"""
Generador de texturas PBR estilizadas (estilo Subway Surfers) para Minijuego_Correr.
Produce texturas Albedo, Normal y Emission de alta resolución (512x512 y 1024x512)
con acabado pintado a mano, oclusión ambiental horneada, reflejos de cristal,
grafitis vibrantes y ventanas iluminadas para el modo nocturno.

Salida: Imagenes/Minijuego_Correr/Texturas3D/*.png
"""

import math
import os
import random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont


def gaussian_filter(arr: np.ndarray, sigma) -> np.ndarray:
    """Filtro gaussiano periódico 2D en puro NumPy (100% tileable, sin SciPy)."""
    if isinstance(sigma, (tuple, list)):
        sy, sx = float(sigma[0]), float(sigma[1])
    else:
        sy = sx = float(sigma)
    out = arr.astype(np.float32, copy=True)
    for axis, s in ((0, sy), (1, sx)):
        if s <= 0.05:
            continue
        rad = max(1, int(math.ceil(s * 3.0)))
        xs = np.arange(-rad, rad + 1, dtype=np.float32)
        k = np.exp(-0.5 * (xs / s) ** 2)
        k /= k.sum()
        res = np.zeros_like(out)
        for i, w in enumerate(k):
            res += np.roll(out, i - rad, axis=axis) * w
        out = res
    return out

OUT_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "Imagenes", "Minijuego_Correr", "Texturas3D"
)
os.makedirs(OUT_DIR, exist_ok=True)


# ---------------------------------------------------------------------------
# Utilidades de ruido, normal map y pintura estilizada
# ---------------------------------------------------------------------------

def tileable_noise(h: int, w: int, scale: int, seed: int = 0) -> np.ndarray:
    """Ruido suave perfectamente tileable en [0, 1]."""
    rng = np.random.default_rng(seed)
    gh = max(2, h // scale)
    gw = max(2, w // scale)
    grid = rng.random((gh, gw), dtype=np.float32)
    # Upsample bilineal periodico
    yy = np.linspace(0, gh, h, endpoint=False)
    xx = np.linspace(0, gw, w, endpoint=False)
    y0 = np.floor(yy).astype(int) % gh
    y1 = (y0 + 1) % gh
    fy = (yy - np.floor(yy))[:, None]
    x0 = np.floor(xx).astype(int) % gw
    x1 = (x0 + 1) % gw
    fx = (xx - np.floor(xx))[None, :]
    # Smoothstep
    fy = fy * fy * (3.0 - 2.0 * fy)
    fx = fx * fx * (3.0 - 2.0 * fx)
    v00 = grid[np.ix_(y0, x0)]
    v01 = grid[np.ix_(y0, x1)]
    v10 = grid[np.ix_(y1, x0)]
    v11 = grid[np.ix_(y1, x1)]
    top = v00 * (1.0 - fx) + v01 * fx
    bot = v10 * (1.0 - fx) + v11 * fx
    return (top * (1.0 - fy) + bot * fy).astype(np.float32)


def fbm_tileable(h: int, w: int, scales=(64, 32, 16, 8), weights=(0.45, 0.30, 0.17, 0.08), seed=42) -> np.ndarray:
    acc = np.zeros((h, w), dtype=np.float32)
    wsum = sum(weights)
    for i, (sc, wt) in enumerate(zip(scales, weights)):
        acc += tileable_noise(h, w, sc, seed + i * 131) * (wt / wsum)
    return acc


def height_to_normal(height: np.ndarray, strength: float = 3.0) -> Image.Image:
    """Convierte un mapa de alturas [0, 1] tileable a mapa de normales tangent-space."""
    dx = (np.roll(height, -1, axis=1) - np.roll(height, 1, axis=1)) * 0.5 * strength
    dy = (np.roll(height, -1, axis=0) - np.roll(height, 1, axis=0)) * 0.5 * strength
    nz = np.ones_like(height)
    nx = -dx
    ny = -dy
    length = np.sqrt(nx * nx + ny * ny + nz * nz) + 1e-6
    r = np.clip((nx / length * 0.5 + 0.5) * 255.0, 0, 255).astype(np.uint8)
    g = np.clip((ny / length * 0.5 + 0.5) * 255.0, 0, 255).astype(np.uint8)
    b = np.clip((nz / length * 0.5 + 0.5) * 255.0, 0, 255).astype(np.uint8)
    return Image.fromarray(np.stack([r, g, b], axis=-1), mode="RGB")


def hex_rgb(s: str):
    s = s.lstrip("#")
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))


def load_font(size: int):
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    candidates = [
        os.path.join(project_root, "Fuentes", "UI", "TitanOne-400.ttf"),
        os.path.join(project_root, "Fuentes", "UI", "RussoOne-400.ttf"),
        os.path.join(project_root, "Fuentes", "UI", "Bricolage-800.ttf"),
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    ]
    for path in candidates:
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def save_img(img: Image.Image, name: str):
    path = os.path.join(OUT_DIR, name)
    img.save(path, "PNG", optimize=True)
    print(f"  [OK] {name} ({img.size[0]}x{img.size[1]})")


# ---------------------------------------------------------------------------
# 1. Balasto ferroviario (grava rica de 3 carriles con surcos y piedritas)
# ---------------------------------------------------------------------------

def gen_balasto():
    """Balasto ferroviario cálido estilo Subway Surfers (1024x1024): grava fina nítida arena/tierra soleada."""
    w, h = 1024, 1024
    n_macro = fbm_tileable(h, w, (128, 64, 32), (0.45, 0.35, 0.20), seed=101)
    n_med = fbm_tileable(h, w, (32, 16, 8), (0.40, 0.35, 0.25), seed=102)
    rng_np = np.random.default_rng(107)
    n_grain = rng_np.random((h, w), dtype=np.float32)
    n_grain_s = gaussian_filter(n_grain, 0.85)
    n_speck = (n_grain > 0.86).astype(np.float32) - (n_grain < 0.14).astype(np.float32)
    n_speck = gaussian_filter(n_speck, 0.7)

    # Paleta Subway Surfers: grava cálida arena-terracota/tierra soleada (contraste rico con raíles y traviesas)
    c_dark = np.array([124, 98, 74], dtype=np.float32)
    c_mid = np.array([166, 138, 108], dtype=np.float32)
    c_light = np.array([202, 174, 140], dtype=np.float32)

    t = np.clip(n_macro * 0.38 + n_med * 0.38 + n_grain_s * 0.24 + n_speck * 0.16, 0.0, 1.0)
    rgb = np.zeros((h, w, 3), dtype=np.float32)
    for c in range(3):
        rgb[:, :, c] = np.where(
            t < 0.5,
            c_dark[c] + (c_mid[c] - c_dark[c]) * (t * 2.0),
            c_mid[c] + (c_light[c] - c_mid[c]) * ((t - 0.5) * 2.0)
        )

    # Sutil variación de gravilla fina orgánica (sin rectángulos pixelados)
    img = Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8), mode="RGB")
    draw = ImageDraw.Draw(img)
    rng = random.Random(309)
    stone_pal = [
        (194, 168, 136), (174, 148, 118), (144, 120, 96),
        (210, 186, 156), (126, 106, 86), (156, 138, 118),
    ]
    for _ in range(9500):
        px = rng.randint(0, w - 1)
        py = rng.randint(0, h - 1)
        rx = rng.randint(1, 3)
        ry = rng.randint(1, 2)
        col = rng.choice(stone_pal)
        draw.ellipse([px - rx, py - ry, px + rx, py + ry], fill=col)

    arr = np.array(img, dtype=np.float32)
    h_arr = t.copy()
    xs = np.linspace(0.0, 1.0, w, endpoint=False)[None, :]
    # Surcos sombreados cálidos entre las 3 vías + ligera huella de aceite en el eje de cada vía
    lane_shade = np.ones((1, w), dtype=np.float32)
    for div in (0.0, 1.0 / 3.0, 2.0 / 3.0, 1.0):
        dist = np.abs(xs - div)
        dist = np.minimum(dist, 1.0 - dist)
        lane_shade *= (0.62 + 0.38 * np.clip(dist / 0.055, 0.0, 1.0))
    for center in (1.0 / 6.0, 3.0 / 6.0, 5.0 / 6.0):
        dist = np.abs(xs - center)
        oil = 1.0 - 0.16 * np.exp(-((dist / 0.055) ** 2))
        lane_shade *= oil

    arr *= lane_shade[:, :, None]
    h_arr = h_arr * 0.78 + lane_shade * 0.22

    save_img(Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), mode="RGB"), "balasto_albedo.png")
    save_img(height_to_normal(gaussian_filter(h_arr, sigma=0.8), strength=2.2), "balasto_normal.png")


# ---------------------------------------------------------------------------
# 2. Traviesa de madera ferroviaria (weathered timber sleeper)
# ---------------------------------------------------------------------------

def gen_traviesa():
    w, h = 256, 128
    grain = fbm_tileable(h, w, (64, 16, 8), (0.35, 0.40, 0.25), seed=404)
    # Estirar la veta horizontalmente
    streaks = tileable_noise(h, w, 8, seed=405)
    streaks = gaussian_filter(streaks, sigma=(0.6, 8.0))
    t = np.clip(grain * 0.55 + streaks * 0.45, 0.0, 1.0)

    c_dark = np.array([86, 54, 34], dtype=np.float32)
    c_light = np.array([146, 98, 62], dtype=np.float32)
    rgb = c_dark[None, None, :] + (c_light - c_dark)[None, None, :] * t[:, :, None]

    # Bisel oscuro en bordes
    img = Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8), mode="RGB")
    draw = ImageDraw.Draw(img)
    draw.rectangle([0, 0, w - 1, 6], fill=(64, 38, 22))
    draw.rectangle([0, h - 7, w - 1, h - 1], fill=(56, 33, 19))
    draw.rectangle([0, 6, w - 1, 10], fill=(166, 118, 78))
    # Grietas sutiles
    rng = random.Random(406)
    for _ in range(18):
        y = rng.randint(14, h - 14)
        x0 = rng.randint(0, w - 50)
        x1 = x0 + rng.randint(25, 90)
        draw.line([(x0, y), (x1, y)], fill=(54, 32, 18), width=2)

    save_img(img, "traviesa_albedo.png")
    save_img(height_to_normal(t, strength=2.2), "traviesa_normal.png")


# ---------------------------------------------------------------------------
# 3. Andén / Acera de estación (concreto soleado + banda táctil amarilla)
# ---------------------------------------------------------------------------

def gen_anden():
    w, h = 512, 512
    n = fbm_tileable(h, w, (64, 32, 16, 8), (0.4, 0.3, 0.2, 0.1), seed=505)
    # Concreto cálido soleado arenisca (cero tinte azulado!)
    base = np.zeros((h, w, 3), dtype=np.float32)
    c1 = np.array([172, 160, 144], dtype=np.float32)
    c2 = np.array([202, 189, 170], dtype=np.float32)
    base = c1[None, None, :] + (c2 - c1)[None, None, :] * n[:, :, None]

    img = Image.fromarray(np.clip(base, 0, 255).astype(np.uint8), mode="RGB")
    h_arr = np.full((h, w), 0.65, dtype=np.float32) + (n - 0.5) * 0.15
    draw = ImageDraw.Draw(img)

    # Juntas de losas de andén con bisel claro + ranura oscura
    for y in range(0, h, 128):
        draw.rectangle([0, y, w, y + 4], fill=(98, 94, 89))
        draw.rectangle([0, y + 5, w, y + 7], fill=(208, 202, 192))
        h_arr[y:min(h, y + 5), :] = 0.25
    for x in range(0, w, 128):
        draw.rectangle([x, 0, x + 4, h], fill=(98, 94, 89))
        draw.rectangle([x + 5, 0, x + 7, h], fill=(208, 202, 192))
        h_arr[:, x:min(w, x + 5)] = 0.25

    # Franja táctil de seguridad amarilla Subway Surfers en ambos bordes (X=0..56 y X=w-56..w)
    for x0 in (0, w - 58):
        # Borde de hormigón del labio
        draw.rectangle([x0, 0, x0 + 58, h], fill=(242, 194, 30))
        # Línea oscura separadora
        sep_x = x0 + 56 if x0 == 0 else x0
        draw.rectangle([sep_x, 0, sep_x + 3, h], fill=(115, 86, 18))
        # Puntos táctiles en relieve
        for ty in range(12, h, 24):
            for tx in (x0 + 14, x0 + 30, x0 + 44):
                draw.ellipse([tx - 5, ty - 4, tx + 5, ty + 6], fill=(196, 138, 14))
                draw.ellipse([tx - 5, ty - 5, tx + 5, ty + 5], fill=(255, 224, 72))
                h_arr[max(0, ty - 5):min(h, ty + 5), max(0, tx - 5):min(w, tx + 5)] = 0.92

    # Sombra suave cerca del muro exterior (centro interior)
    save_img(img, "anden_albedo.png")
    save_img(height_to_normal(gaussian_filter(h_arr, 0.8), strength=2.6), "anden_normal.png")


# ---------------------------------------------------------------------------
# 4. Muros de ladrillo con grafiti Subway Surfers (2 murales 1024x512 + Normal)
# ---------------------------------------------------------------------------

def _draw_brick_base(w: int, h: int, seed: int):
    n = fbm_tileable(h, w, (64, 32, 16), (0.45, 0.35, 0.20), seed=seed)
    img = Image.new("RGB", (w, h), (118, 72, 58))
    h_img = Image.new("L", (w, h), 85)
    draw = ImageDraw.Draw(img)
    hdraw = ImageDraw.Draw(h_img)
    rng = random.Random(seed)

    # Mortero cálido
    draw.rectangle([0, 0, w, h], fill=(104, 88, 78))

    brick_h = 24
    brick_w = 64
    rows = h // brick_h
    for row in range(rows):
        y0 = row * brick_h
        offset = (row % 2) * (brick_w // 2)
        for col in range(-1, w // brick_w + 2):
            x0 = col * brick_w + offset
            # Variación rica terracota/ladrillo urbano
            r = rng.randint(152, 198)
            g = rng.randint(76, 108)
            b = rng.randint(58, 80)
            # Sutil sombreado por fila
            if rng.random() < 0.15:
                r = int(r * 0.84)
                g = int(g * 0.82)
                b = int(b * 0.82)
            # Sombra inferior del ladrillo y brillo superior
            draw.rectangle([x0 + 3, y0 + 3, x0 + brick_w - 3, y0 + brick_h - 3], fill=(r, g, b))
            draw.rectangle([x0 + 3, y0 + 3, x0 + brick_w - 3, y0 + 6], fill=(min(255, r + 22), min(255, g + 16), min(255, b + 12)))
            draw.rectangle([x0 + 3, y0 + brick_h - 6, x0 + brick_w - 3, y0 + brick_h - 3], fill=(max(0, r - 28), max(0, g - 22), max(0, b - 18)))
            hdraw.rectangle([x0 + 3, y0 + 3, x0 + brick_w - 3, y0 + brick_h - 3], fill=rng.randint(180, 235))

    # Mezclar variación painterly y AO inferior/superior
    arr = np.array(img, dtype=np.float32)
    arr *= (0.88 + 0.22 * n[:, :, None])

    # Zócalo oscuro de hormigón abajo + sombra AO de contacto
    ys = np.linspace(0.0, 1.0, h)[:, None]
    ao_bot = np.where(ys > 0.78, 0.65 + 0.35 * ((1.0 - ys) / 0.22), 1.0)
    arr *= ao_bot[:, :, None]

    img = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), mode="RGB")
    draw = ImageDraw.Draw(img)

    # Remate superior de piedra / cornisa de hormigón
    draw.rectangle([0, 0, w, 40], fill=(184, 178, 168))
    draw.rectangle([0, 0, w, 10], fill=(218, 212, 202))
    draw.rectangle([0, 36, w, 46], fill=(82, 74, 68))
    hdraw.rectangle([0, 0, w, 40], fill=245)
    hdraw.rectangle([0, 40, w, 48], fill=60)

    # Zócalo inferior de concreto gris cálido
    draw.rectangle([0, h - 56, w, h], fill=(116, 114, 112))
    draw.rectangle([0, h - 58, w, h - 52], fill=(154, 150, 144))
    draw.rectangle([0, h - 18, w, h], fill=(76, 74, 76))

    return img, np.array(h_img, dtype=np.float32) / 255.0


def _draw_graffiti_piece(img: Image.Image, cx: int, cy: int, text: str, col_top, col_bot, col_accent, col_outline=(18, 22, 36), seed=1):
    """Pinta una pieza de arte urbano Subway Surfers (salpicaduras, sombra 3D, texto degradado con contorno grueso y brillos)."""
    rng = random.Random(seed)
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)

    # 1. Nube / salpicadura de spray de fondo
    for _ in range(18):
        ox = rng.randint(-190, 190)
        oy = rng.randint(-75, 75)
        rr = rng.randint(18, 56)
        c = col_accent if rng.random() < 0.65 else col_top
        d.ellipse([cx + ox - rr, cy + oy - rr, cx + ox + rr, cy + oy + rr], fill=(*c, rng.randint(165, 225)))

    # Gotas / drips de pintura spray
    for _ in range(28):
        dx = rng.randint(-210, 210)
        dy = rng.randint(-55, 85)
        r = rng.randint(3, 10)
        c = rng.choice([col_accent, col_top, col_bot, (255, 255, 255)])
        d.ellipse([cx + dx - r, cy + dy - r, cx + dx + r, cy + dy + r], fill=(*c, 220))
        if rng.random() < 0.45:
            drip_len = rng.randint(12, 38)
            d.rectangle([cx + dx - 2, cy + dy, cx + dx + 2, cy + dy + drip_len], fill=(*c, 200))

    # Estrellas y rayos decorativos
    for sx, sy, sr, sc in [
        (cx - 195, cy - 55, 22, (255, 238, 66)),
        (cx + 195, cy + 48, 20, col_accent),
        (cx + 160, cy - 68, 16, (255, 255, 255)),
    ]:
        pts = []
        for k in range(10):
            ang = -math.pi * 0.5 + k * math.pi / 5.0
            rad = sr if k % 2 == 0 else sr * 0.45
            pts.append((sx + math.cos(ang) * rad, sy + math.sin(ang) * rad))
        d.polygon(pts, fill=(*sc, 245), outline=(*col_outline, 255))

    # 2. Texto wildstyle inclinado con extrusión 3D, borde grueso y degradado
    txt_layer = Image.new("RGBA", (540, 220), (0, 0, 0, 0))
    td = ImageDraw.Draw(txt_layer)
    font = load_font(104)
    bbox = td.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    tx = (540 - tw) // 2 - bbox[0]
    ty = (220 - th) // 2 - bbox[1]

    # Extrusión 3D diagonal
    for depth in range(16, 0, -2):
        td.text((tx + depth, ty + depth), text, font=font, fill=(*col_outline, 255), stroke_width=10, stroke_fill=(*col_outline, 255))

    # Contorno exterior brillante (halo graffiti)
    td.text((tx, ty), text, font=font, fill=(255, 255, 255, 255), stroke_width=13, stroke_fill=(255, 255, 255, 240))
    td.text((tx, ty), text, font=font, fill=(*col_outline, 255), stroke_width=9, stroke_fill=(*col_outline, 255))

    # Relleno con degradado vertical usando máscara
    mask = Image.new("L", (540, 220), 0)
    md = ImageDraw.Draw(mask)
    md.text((tx, ty), text, font=font, fill=255)
    grad = Image.new("RGBA", (540, 220), (0, 0, 0, 0))
    g_arr = np.zeros((220, 540, 4), dtype=np.uint8)
    for y in range(220):
        u = np.clip((y - 45) / 120.0, 0.0, 1.0)
        for ch in range(3):
            g_arr[y, :, ch] = int(col_top[ch] * (1.0 - u) + col_bot[ch] * u)
        g_arr[y, :, 3] = 255
    grad = Image.fromarray(g_arr, mode="RGBA")
    txt_layer.paste(grad, (0, 0), mask)

    # Brillo especular blanco arriba de las letras
    hl = Image.new("RGBA", (540, 220), (0, 0, 0, 0))
    hd = ImageDraw.Draw(hl)
    hd.text((tx - 2, ty - 4), text, font=font, fill=(255, 255, 255, 115))
    hl_arr = np.array(hl)
    hl_arr[108:, :, 3] = 0
    txt_layer = Image.alpha_composite(txt_layer, Image.fromarray(hl_arr))

    # Rotar ligeramente para dinamismo callejero
    rot = txt_layer.rotate(rng.uniform(-7.0, 7.0), resample=Image.BICUBIC, expand=True)
    overlay.alpha_composite(rot, (cx - rot.width // 2, cy - rot.height // 2))

    # Componer suavemente sobre ladrillo dejando ver un 12% de textura de ladrillo debajo
    base_rgba = img.convert("RGBA")
    ov_arr = np.array(overlay, dtype=np.float32)
    ov_arr[:, :, 3] *= 0.90
    res = Image.alpha_composite(base_rgba, Image.fromarray(ov_arr.astype(np.uint8), mode="RGBA"))
    img.paste(res.convert("RGB"))


def gen_muros():
    w, h = 1024, 512
    img_a, h_arr = _draw_brick_base(w, h, seed=601)
    _draw_graffiti_piece(img_a, 270, 255, "RUSH!", (255, 232, 48), (255, 108, 22), (40, 212, 255), seed=11)
    _draw_graffiti_piece(img_a, 770, 260, "SURF", (74, 245, 138), (14, 168, 212), (255, 76, 148), seed=22)
    save_img(img_a, "muro_graffiti_a_albedo.png")

    img_b, _ = _draw_brick_base(w, h, seed=602)
    _draw_graffiti_piece(img_b, 260, 250, "DASH", (56, 224, 255), (54, 108, 255), (255, 212, 36), seed=33)
    _draw_graffiti_piece(img_b, 760, 255, "CITY!", (255, 92, 138), (186, 42, 218), (94, 242, 112), seed=44)
    save_img(img_b, "muro_graffiti_b_albedo.png")

    save_img(height_to_normal(gaussian_filter(h_arr, 0.7), strength=3.0), "muro_graffiti_normal.png")


# ---------------------------------------------------------------------------
# 5. Vagones de Metro (Subway Surfers Trains: 4 libreas + Normal + Emission)
# ---------------------------------------------------------------------------

def gen_trenes():
    # 4 libreas icónicas estilo Subway Surfers
    liveries = [
        # (nombre, cuerpo_top, cuerpo_bot, franja, acento, texto_grafiti, graf_c1, graf_c2, graf_acc, ruta_led)
        (0, hex_rgb("#1c7ed6"), hex_rgb("#145da0"), hex_rgb("#ffd43b"), hex_rgb("#f8fafc"), "RUSH", (255, 224, 48), (255, 96, 38), (56, 224, 255), "EXPRESS"),
        (1, hex_rgb("#e03131"), hex_rgb("#a61e22"), hex_rgb("#f8fafc"), hex_rgb("#ffd43b"), "BOOM", (94, 248, 128), (24, 178, 104), (255, 222, 48), "METRO 1"),
        (2, hex_rgb("#0ca678"), hex_rgb("#087f5b"), hex_rgb("#ffec99"), hex_rgb("#ff922b"), "WILD", (255, 98, 168), (156, 54, 218), (255, 232, 64), "CENTRAL"),
        (3, hex_rgb("#f76707"), hex_rgb("#c94a00"), hex_rgb("#1e293b"), hex_rgb("#38bdf8"), "FAST", (56, 224, 255), (36, 122, 255), (255, 228, 56), "CITY EX"),
    ]

    w, h = 1024, 512
    # Normal map y emission compartidos para el lateral del tren
    norm_h = np.full((h, w), 0.55, dtype=np.float32)
    em_side = Image.new("RGB", (w, h), (0, 0, 0))
    em_sd = ImageDraw.Draw(em_side)

    for idx, c_top, c_bot, c_stripe, c_acc, g_txt, gc1, gc2, gacc, ruta in liveries:
        img = Image.new("RGB", (w, h), c_top)
        arr = np.array(img, dtype=np.float32)
        # Degradado vertical rico + sutil brillo metálico
        for y in range(h):
            u = y / float(h)
            for ch in range(3):
                arr[y, :, ch] = c_top[ch] * (1.0 - u) + c_bot[ch] * u
        noise = fbm_tileable(h, w, (64, 32, 16), (0.5, 0.3, 0.2), seed=700 + idx)
        arr *= (0.93 + 0.14 * noise[:, :, None])
        img = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), mode="RGB")
        draw = ImageDraw.Draw(img)

        # Banda superior metálica bajo el techo
        draw.rectangle([0, 0, w, 34], fill=(224, 232, 240))
        draw.rectangle([0, 34, w, 42], fill=(28, 36, 52))

        # Faldón inferior de acero corrugado estriado (típico vagón NYC / Subway Surfers)
        skirt_y = 338
        draw.rectangle([0, skirt_y, w, h], fill=(172, 182, 194))
        for ry in range(skirt_y + 8, h - 18, 16):
            draw.rectangle([0, ry, w, ry + 5], fill=(124, 134, 148))
            draw.rectangle([0, ry + 6, w, ry + 10], fill=(214, 222, 232))
            if idx == 0:
                norm_h[ry:ry + 6, :] = 0.28
                norm_h[ry + 6:ry + 11, :] = 0.85

        # Franja racing vibrante recorriendo el costado
        draw.rectangle([0, 286, w, 336], fill=c_stripe)
        draw.rectangle([0, 282, w, 288], fill=(24, 30, 44))
        draw.rectangle([0, 334, w, 340], fill=(24, 30, 44))
        draw.rectangle([0, 294, w, 302], fill=c_acc)

        # Puertas dobles correderas (3 conjuntos a lo largo del vagón)
        door_xs = [110, 466, 822]
        for dx in door_xs:
            # Marco de puerta metálico
            draw.rectangle([dx - 4, 52, dx + 96, h - 16], fill=(32, 42, 58))
            draw.rectangle([dx, 56, dx + 92, h - 20], fill=(198, 208, 220))
            # Sello central vertical de goma
            draw.rectangle([dx + 43, 56, dx + 49, h - 20], fill=(24, 30, 42))
            # Ventanas altas de puerta con reflejo brillante
            for wx in (dx + 7, dx + 53):
                draw.rounded_rectangle([wx, 78, wx + 32, 250], radius=8, fill=(24, 42, 68), outline=(38, 48, 66), width=3)
                draw.polygon([(wx + 4, 128), (wx + 28, 84), (wx + 28, 108), (wx + 4, 152)], fill=(126, 206, 255))
                draw.polygon([(wx + 4, 164), (wx + 28, 120), (wx + 28, 132), (wx + 4, 176)], fill=(186, 234, 255))
                if idx == 0:
                    norm_h[78:250, wx:wx + 32] = 0.20
                    em_sd.rounded_rectangle([wx + 3, 81, wx + 29, 247], radius=6, fill=(255, 224, 148))

        # Ventanas panorámicas de pasajeros entre puertas
        win_spans = [(222, 444), (578, 800)]
        for x0, x1 in win_spans:
            mid = (x0 + x1) // 2
            for wx0, wx1 in [(x0, mid - 6), (mid + 6, x1)]:
                draw.rounded_rectangle([wx0 - 4, 84, wx1 + 4, 248], radius=12, fill=(28, 36, 52))
                draw.rounded_rectangle([wx0, 88, wx1, 244], radius=10, fill=(26, 48, 78), outline=(202, 214, 228), width=4)
                # Interior cálido sutil + reflejos diagonales celestes
                draw.polygon([(wx0 + 8, 236), (wx0 + 52, 92), (wx0 + 74, 92), (wx0 + 30, 236)], fill=(104, 196, 252))
                draw.polygon([(wx0 + 44, 236), (wx0 + 88, 92), (wx0 + 96, 92), (wx0 + 52, 236)], fill=(176, 230, 255))
                if idx == 0:
                    norm_h[88:244, wx0:wx1] = 0.20
                    em_sd.rounded_rectangle([wx0 + 4, 92, wx1 - 4, 240], radius=8, fill=(255, 214, 130))

        # Remaches metálicos y líneas de panel
        for px in (20, 212, 454, 568, 810, 996):
            draw.line([(px, 44), (px, h - 14)], fill=(24, 32, 46), width=3)
            for ry in range(60, h - 24, 36):
                draw.ellipse([px - 5, ry - 2, px - 1, ry + 2], fill=(220, 230, 240))

        # Grafiti callejero vibrante pintado en la zona baja/media del vagón (firma Subway Surfers!)
        _draw_graffiti_piece(img, 330 if idx % 2 == 0 else 685, 345, g_txt, gc1, gc2, gacc, seed=800 + idx)

        # Sombra AO inferior (bajos del vagón)
        arr2 = np.array(img, dtype=np.float32)
        ys = np.linspace(0.0, 1.0, h)[:, None]
        ao = np.where(ys > 0.84, 0.58 + 0.42 * ((1.0 - ys) / 0.16), 1.0)
        arr2 *= ao[:, :, None]
        save_img(Image.fromarray(np.clip(arr2, 0, 255).astype(np.uint8), mode="RGB"), f"tren_lateral_{idx}.png")

        # --- FRENTE DE CABINA DEL TREN (512x512) ---
        fw, fh = 512, 512
        fimg = Image.new("RGB", (fw, fh), c_top)
        farr = np.array(fimg, dtype=np.float32)
        for y in range(fh):
            u = y / float(fh)
            for ch in range(3):
                farr[y, :, ch] = c_top[ch] * (1.0 - u) + c_bot[ch] * u
        fimg = Image.fromarray(np.clip(farr, 0, 255).astype(np.uint8), mode="RGB")
        fd = ImageDraw.Draw(fimg)

        fem = Image.new("RGB", (fw, fh), (0, 0, 0))
        fed = ImageDraw.Draw(fem)

        # Banda superior metálica y luces de gálibo rojas
        fd.rectangle([0, 0, fw, 44], fill=(216, 224, 236))
        fd.rectangle([0, 44, fw, 52], fill=(22, 28, 42))
        for lx in (82, fw - 82):
            fd.ellipse([lx - 18, 12, lx + 18, 36], fill=(255, 72, 72), outline=(28, 34, 48), width=4)
            fed.ellipse([lx - 14, 15, lx + 14, 33], fill=(255, 65, 65))

        # Letrero LED de destino arriba del parabrisas
        fd.rounded_rectangle([126, 62, fw - 126, 118], radius=10, fill=(18, 24, 36), outline=(188, 200, 214), width=4)
        f_led = load_font(34)
        bb = fd.textbbox((0, 0), ruta, font=f_led)
        rw, rh = bb[2] - bb[0], bb[3] - bb[1]
        fd.text(((fw - rw) // 2 - bb[0], 88 - rh // 2 - bb[1]), ruta, font=f_led, fill=(255, 224, 72))
        fed.text(((fw - rw) // 2 - bb[0], 88 - rh // 2 - bb[1]), ruta, font=f_led, fill=(255, 208, 48))

        # Parabrisas doble ancho con reflejos azules brillantes y puerta de cabina central
        fd.rounded_rectangle([38, 134, fw - 38, 296], radius=18, fill=(22, 30, 44))
        for wx0, wx1 in [(48, 242), (270, fw - 48)]:
            fd.rounded_rectangle([wx0, 144, wx1, 286], radius=12, fill=(24, 44, 74), outline=(196, 210, 226), width=4)
            fd.polygon([(wx0 + 14, 276), (wx0 + 78, 150), (wx0 + 116, 150), (wx0 + 52, 276)], fill=(116, 204, 255))
            fd.polygon([(wx0 + 78, 276), (wx0 + 142, 150), (wx0 + 158, 150), (wx0 + 94, 276)], fill=(192, 236, 255))
            # Limpiaparabrisas
            fd.line([(wx0 + 28, 280), (wx0 + 102, 212)], fill=(18, 24, 34), width=6)

        # Franja frontal + parrilla metálica + número de unidad
        fd.rectangle([0, 312, fw, 358], fill=c_stripe)
        fd.rectangle([0, 308, fw, 314], fill=(22, 28, 40))
        fd.rectangle([0, 356, fw, 362], fill=(22, 28, 40))

        # Parachoques inferior rayado amarillo/negro industrial
        fd.rectangle([0, 446, fw, fh], fill=(34, 42, 56))
        for sx in range(-64, fw + 64, 48):
            fd.polygon([(sx, 456), (sx + 24, 456), (sx + 4, 504), (sx - 20, 504)], fill=(250, 204, 21))
        fd.rectangle([0, 446, fw, 456], fill=(22, 28, 38))

        # Faros redondos luminosos frontales (enormes y expresivos)
        for hx in (104, fw - 104):
            fd.ellipse([hx - 44, 368, hx + 44, 442], fill=(42, 52, 68), outline=(218, 228, 240), width=5)
            fd.ellipse([hx - 32, 378, hx + 32, 432], fill=(255, 250, 210))
            fd.ellipse([hx - 18, 388, hx + 18, 418], fill=(255, 255, 255))
            fed.ellipse([hx - 34, 376, hx + 34, 434], fill=(255, 242, 168))

        # Rejilla central entre faros
        fd.rounded_rectangle([188, 374, fw - 188, 436], radius=8, fill=(38, 48, 62), outline=(168, 180, 196), width=3)
        for gy in range(384, 432, 10):
            fd.line([(198, gy), (fw - 198, gy)], fill=(18, 24, 34), width=4)

        save_img(fimg, f"tren_frente_{idx}.png")
        if idx == 0:
            save_img(fem, "tren_frente_emission.png")

    save_img(height_to_normal(gaussian_filter(norm_h, 0.7), strength=2.6), "tren_lateral_normal.png")
    save_img(em_side, "tren_lateral_emission.png")


# ---------------------------------------------------------------------------
# 6. Techo corrugado de vagón (para correr "¡POR LOS TECHOS!")
# ---------------------------------------------------------------------------

def gen_tren_techo():
    w, h = 512, 512
    n = fbm_tileable(h, w, (64, 32, 16), (0.45, 0.35, 0.20), seed=750)
    # Metal gris-azulado soleado y limpio con costillas longitudinales
    base = np.zeros((h, w, 3), dtype=np.float32)
    c1 = np.array([176, 188, 202], dtype=np.float32)
    c2 = np.array([216, 226, 238], dtype=np.float32)
    base = c1[None, None, :] + (c2 - c1)[None, None, :] * n[:, :, None]
    h_arr = np.full((h, w), 0.55, dtype=np.float32)

    img = Image.fromarray(np.clip(base, 0, 255).astype(np.uint8), mode="RGB")
    draw = ImageDraw.Draw(img)

    # Costillas longitudinales metálicas (X)
    for rx in range(28, w - 28, 32):
        draw.rectangle([rx, 0, rx + 6, h], fill=(134, 146, 162))
        draw.rectangle([rx + 6, 0, rx + 11, h], fill=(234, 242, 250))
        h_arr[:, rx:rx + 6] = 0.25
        h_arr[:, rx + 6:rx + 12] = 0.85

    # Pasillo antideslizante central oscuro (guía visual perfecta para el corredor!)
    draw.rectangle([w // 2 - 76, 0, w // 2 + 76, h], fill=(104, 116, 134))
    draw.rectangle([w // 2 - 80, 0, w // 2 - 74, h], fill=(242, 198, 42))
    draw.rectangle([w // 2 + 74, 0, w // 2 + 80, h], fill=(242, 198, 42))
    for gy in range(0, h, 32):
        draw.rectangle([w // 2 - 68, gy, w // 2 + 68, gy + 4], fill=(82, 92, 108))
        h_arr[gy:gy + 4, w // 2 - 68:w // 2 + 68] = 0.35

    # Juntas transversales de paneles del techo y tornillos
    for jy in (0, 128, 256, 384):
        draw.rectangle([0, jy, w, jy + 5], fill=(86, 98, 114))
        h_arr[jy:jy + 5, :] = 0.20

    # Bordes laterales biselados más oscuros
    draw.rectangle([0, 0, 18, h], fill=(122, 134, 150))
    draw.rectangle([w - 18, 0, w, h], fill=(122, 134, 150))

    save_img(img, "tren_techo_albedo.png")
    save_img(height_to_normal(gaussian_filter(h_arr, 0.7), strength=2.6), "tren_techo_normal.png")


# ---------------------------------------------------------------------------
# 7. Rampa industrial amarilla con flechas chevrón brillantes
# ---------------------------------------------------------------------------

def gen_rampa():
    w, h = 512, 512
    img = Image.new("RGB", (w, h), (235, 162, 16))
    em = Image.new("RGB", (w, h), (0, 0, 0))
    draw = ImageDraw.Draw(img)
    ed = ImageDraw.Draw(em)

    # Plancha metálica amarilla con ligera textura antideslizante
    n = fbm_tileable(h, w, (32, 16, 8), (0.5, 0.3, 0.2), seed=810)
    arr = np.array(img, dtype=np.float32) * (0.92 + 0.14 * n[:, :, None])
    img = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), mode="RGB")
    draw = ImageDraw.Draw(img)

    # Trama metálica sutil
    for y in range(0, h, 24):
        draw.line([(48, y), (w - 48, y)], fill=(198, 124, 10), width=2)

    # Bordes laterales industriales con rayas negras/amarillas
    for x0 in (0, w - 48):
        draw.rectangle([x0, 0, x0 + 48, h], fill=(32, 40, 54))
        for sy in range(-48, h + 48, 48):
            draw.polygon([(x0 + 6, sy), (x0 + 42, sy + 20), (x0 + 42, sy + 40), (x0 + 6, sy + 20)], fill=(250, 204, 21))

    # Grandes flechas chevrón luminosas apuntando hacia arriba (-Z)
    for cy in (96, 224, 352, 480):
        pts_out = [
            (w // 2, cy - 58), (w - 64, cy + 16), (w - 64, cy + 62),
            (w // 2, cy - 12), (64, cy + 62), (64, cy + 16)
        ]
        draw.polygon(pts_out, fill=(28, 34, 48))
        pts_in = [
            (w // 2, cy - 48), (w - 74, cy + 20), (w - 74, cy + 50),
            (w // 2, cy - 22), (74, cy + 50), (74, cy + 20)
        ]
        draw.polygon(pts_in, fill=(255, 248, 124))
        ed.polygon(pts_in, fill=(255, 218, 60))

    save_img(img, "rampa_albedo.png")
    save_img(em, "rampa_emission.png")


# ---------------------------------------------------------------------------
# 8. Valla de peligro (roja y blanca Subway Surfers) y Arco alto (rodar abajo)
# ---------------------------------------------------------------------------

def gen_vallas():
    # Valla baja (512x128)
    w, h = 512, 128
    img = Image.new("RGB", (w, h), (248, 250, 252))
    draw = ImageDraw.Draw(img)
    for sx in range(-h, w + h, 88):
        draw.polygon([(sx, 0), (sx + 44, 0), (sx + 44 - 56, h), (sx - 56, h)], fill=(228, 38, 44))
    # Marco metálico grueso con bisel y remaches
    draw.rectangle([0, 0, w - 1, h - 1], outline=(24, 32, 46), width=10)
    draw.rectangle([10, 10, w - 11, 16], fill=(255, 255, 255))
    draw.rectangle([10, h - 18, w - 11, h - 11], fill=(140, 24, 28))
    for rx in (32, 160, 352, w - 32):
        for ry in (26, h - 26):
            draw.ellipse([rx - 7, ry - 7, rx + 7, ry + 7], fill=(42, 52, 68), outline=(218, 226, 236), width=2)
    save_img(img, "valla_peligro_albedo.png")

    # Arco alto de señalización ferroviaria para rodar por debajo (512x256)
    w2, h2 = 512, 256
    img2 = Image.new("RGB", (w2, h2), (30, 88, 198))
    d2 = ImageDraw.Draw(img2)
    # Franja superior e inferior de peligro rojo/blanco
    for band_y in (0, h2 - 52):
        d2.rectangle([0, band_y, w2, band_y + 52], fill=(248, 250, 252))
        for sx in range(-64, w2 + 64, 72):
            d2.polygon([(sx, band_y), (sx + 36, band_y), (sx + 10, band_y + 52), (sx - 26, band_y + 52)], fill=(228, 38, 44))
    # Panel central azul vibrante con 3 flechas blancas hacia abajo (indica "RODAR POR DEBAJO"!)
    d2.rectangle([0, 52, w2, h2 - 52], fill=(24, 98, 214))
    d2.line([(0, 52), (w2, 52)], fill=(18, 26, 42), width=6)
    d2.line([(0, h2 - 52), (w2, h2 - 52)], fill=(18, 26, 42), width=6)
    for ax in (112, 256, 400):
        pts = [
            (ax - 24, 74), (ax + 24, 74), (ax + 24, 126),
            (ax + 48, 126), (ax, 184), (ax - 48, 126), (ax - 24, 126)
        ]
        d2.polygon([(x + 3, y + 4) for x, y in pts], fill=(12, 34, 82))
        d2.polygon(pts, fill=(255, 240, 88), outline=(18, 28, 48), width=5)
    d2.rectangle([0, 0, w2 - 1, h2 - 1], outline=(20, 28, 44), width=10)
    save_img(img2, "arco_paso_albedo.png")


# ---------------------------------------------------------------------------
# 9. Edificios coloridos Subway Surfers (5 estilos únicos + Normal + Emission)
# ---------------------------------------------------------------------------

def gen_edificios():
    styles = [
        # (idx, pared_top, pared_bot, moldura, marco_win, toldo_a, toldo_b, tipo_win)
        (0, hex_rgb("#e07a5f"), hex_rgb("#c45c42"), hex_rgb("#f4e8d8"), hex_rgb("#3d2c28"), hex_rgb("#2a9d8f"), hex_rgb("#f8fafc"), "arco"),
        (1, hex_rgb("#f4c452"), hex_rgb("#d99c32"), hex_rgb("#fff6e0"), hex_rgb("#264653"), hex_rgb("#e76f51"), hex_rgb("#fff3d6"), "contraventana"),
        (2, hex_rgb("#5ea6d8"), hex_rgb("#3d7fb2"), hex_rgb("#e8f4fc"), hex_rgb("#1d3557"), hex_rgb("#f4a261"), hex_rgb("#ffffff"), "loft"),
        (3, hex_rgb("#e86d82"), hex_rgb("#c24c62"), hex_rgb("#fdebf0"), hex_rgb("#2b2d42"), hex_rgb("#38bdf8"), hex_rgb("#ffffff"), "balcon"),
        (4, hex_rgb("#68b984"), hex_rgb("#499464"), hex_rgb("#edf7ee"), hex_rgb("#1e3a2f"), hex_rgb("#facc15"), hex_rgb("#ffffff"), "clasico"),
    ]

    w, h = 512, 512
    h_map = np.full((h, w), 0.65, dtype=np.float32)
    em_img = Image.new("RGB", (w, h), (0, 0, 0))
    ed = ImageDraw.Draw(em_img)
    rng_em = random.Random(909)

    for idx, c_top, c_bot, c_trim, c_frame, c_awn_a, c_awn_b, tipo in styles:
        n = fbm_tileable(h, w, (64, 32, 16), (0.5, 0.3, 0.2), seed=900 + idx)
        arr = np.zeros((h, w, 3), dtype=np.float32)
        for y in range(h):
            u = y / float(h)
            for ch in range(3):
                arr[y, :, ch] = c_top[ch] * (1.0 - u) + c_bot[ch] * u
        arr *= (0.91 + 0.16 * n[:, :, None])
        img = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), mode="RGB")
        draw = ImageDraw.Draw(img)

        # Textura sutil de ladrillo / estuco horizontal
        for fy in range(0, h, 16):
            draw.line([(0, fy), (w, fy)], fill=(int(c_bot[0] * 0.88), int(c_bot[1] * 0.88), int(c_bot[2] * 0.88)), width=1)

        # 4 plantas x 4 columnas de ventanas con detalles arquitectónicos ricos
        for row in range(4):
            y_floor = row * 128
            # Cornisa horizontal de planta
            draw.rectangle([0, y_floor, w, y_floor + 12], fill=c_trim)
            draw.rectangle([0, y_floor + 12, w, y_floor + 17], fill=(int(c_bot[0] * 0.65), int(c_bot[1] * 0.65), int(c_bot[2] * 0.65)))
            if idx == 0:
                h_map[y_floor:y_floor + 12, :] = 0.90
                h_map[y_floor + 12:y_floor + 17, :] = 0.35

            for col in range(4):
                wx = 24 + col * 124
                wy = y_floor + 32
                ww, wh = 76, 78

                # Sombra proyectada bajo la ventana
                draw.rectangle([wx - 6, wy + wh + 6, wx + ww + 8, wy + wh + 14], fill=(int(c_bot[0] * 0.65), int(c_bot[1] * 0.65), int(c_bot[2] * 0.65)))

                # Contraventanas coloridas si aplica
                if tipo == "contraventana":
                    draw.rectangle([wx - 16, wy, wx - 2, wy + wh], fill=c_awn_a, outline=c_frame, width=2)
                    draw.rectangle([wx + ww + 2, wy, wx + ww + 16, wy + wh], fill=c_awn_a, outline=c_frame, width=2)

                # Marco y cristal con reflejo de cielo
                if tipo == "arco":
                    draw.rounded_rectangle([wx - 5, wy - 5, wx + ww + 5, wy + wh + 5], radius=24, fill=c_trim, outline=c_frame, width=2)
                    draw.rounded_rectangle([wx, wy, wx + ww, wy + wh], radius=20, fill=(38, 66, 102), outline=c_frame, width=3)
                else:
                    draw.rectangle([wx - 5, wy - 5, wx + ww + 5, wy + wh + 5], fill=c_trim, outline=c_frame, width=2)
                    draw.rectangle([wx, wy, wx + ww, wy + wh], fill=(38, 68, 106), outline=c_frame, width=3)

                # Reflejo brillante diagonal en el cristal
                draw.polygon([(wx + 8, wy + wh - 6), (wx + 34, wy + 8), (wx + 50, wy + 8), (wx + 24, wy + wh - 6)], fill=(128, 206, 250))
                draw.polygon([(wx + 44, wy + wh - 6), (wx + 66, wy + 8), (wx + 72, wy + 8), (wx + 50, wy + wh - 6)], fill=(190, 234, 255))

                # Parteluces de ventana
                draw.rectangle([wx, wy + wh // 2 - 2, wx + ww, wy + wh // 2 + 2], fill=c_trim)
                draw.rectangle([wx + ww // 2 - 2, wy, wx + ww // 2 + 2, wy + wh], fill=c_trim)

                # Repisa inferior
                draw.rectangle([wx - 9, wy + wh + 1, wx + ww + 9, wy + wh + 9], fill=c_trim, outline=c_frame, width=2)

                # Balcón de hierro forjado o toldo a rayas en plantas alternas
                if tipo == "balcon" and row % 2 == 1:
                    draw.rectangle([wx - 8, wy + wh - 22, wx + ww + 8, wy + wh - 17], fill=(28, 36, 52))
                    for bx in range(wx - 4, wx + ww + 6, 12):
                        draw.line([(bx, wy + wh - 20), (bx, wy + wh + 2)], fill=(28, 36, 52), width=3)
                elif row == 3 and (tipo in ("arco", "loft", "clasico")):
                    # Toldo colorido rayado en planta baja
                    for s_i, sx in enumerate(range(wx - 8, wx + ww + 8, 16)):
                        sc = c_awn_a if s_i % 2 == 0 else c_awn_b
                        draw.rectangle([sx, wy - 4, min(wx + ww + 8, sx + 16), wy + 20], fill=sc)
                    draw.rectangle([wx - 8, wy - 4, wx + ww + 8, wy + 20], outline=c_frame, width=2)

                if idx == 0:
                    h_map[wy:wy + wh, wx:wx + ww] = 0.25
                    # Ventanas encendidas de noche (65% encendidas en tonos ámbar/oro acogedores)
                    if rng_em.random() < 0.68:
                        warm = rng_em.choice([(255, 212, 108), (255, 190, 82), (255, 232, 152), (242, 178, 92)])
                        ed.rectangle([wx + 4, wy + 4, wx + ww - 4, wy + wh - 4], fill=warm)

        save_img(img, f"edificio_{idx}.png")

    save_img(height_to_normal(gaussian_filter(h_map, 0.7), strength=2.6), "edificio_normal.png")
    save_img(em_img, "edificio_emission.png")


# ---------------------------------------------------------------------------
# 10. Carteles / Billboards vibrantes para puentes elevados (3 variantes)
# ---------------------------------------------------------------------------

def gen_carteles():
    specs = [
        (0, "SUBWAY RUSH!", (18, 98, 224), (255, 224, 48), (255, 78, 118)),
        (1, "CITY EXPRESS", (226, 44, 72), (255, 255, 255), (56, 214, 255)),
        (2, "TURBO RUN!", (16, 168, 116), (255, 232, 64), (255, 128, 34)),
    ]
    w, h = 512, 192
    font = load_font(62)
    for idx, txt, bg, c_txt, c_acc in specs:
        img = Image.new("RGB", (w, h), bg)
        d = ImageDraw.Draw(img)
        # Rayos diagonales pop-art
        for sx in range(-h, w + h, 76):
            d.polygon([(sx, 0), (sx + 34, 0), (sx - 24, h), (sx - 58, h)], fill=tuple(min(255, int(v * 1.15)) for v in bg))
        # Marco blanco y oscuro
        d.rectangle([0, 0, w - 1, h - 1], outline=(24, 32, 48), width=12)
        d.rectangle([12, 12, w - 13, h - 13], outline=c_acc, width=6)
        bb = d.textbbox((0, 0), txt, font=font)
        tw, th = bb[2] - bb[0], bb[3] - bb[1]
        tx = (w - tw) // 2 - bb[0]
        ty = (h - th) // 2 - bb[1]
        d.text((tx + 5, ty + 6), txt, font=font, fill=(14, 20, 34), stroke_width=8, stroke_fill=(14, 20, 34))
        d.text((tx, ty), txt, font=font, fill=c_txt, stroke_width=7, stroke_fill=(18, 24, 38))
        save_img(img, f"cartel_puente_{idx}.png")


# ---------------------------------------------------------------------------
# 11. Sombra de contacto suave
# ---------------------------------------------------------------------------

def gen_sombra():
    w, h = 128, 128
    yy, xx = np.mgrid[0:h, 0:w]
    dx = (xx - w * 0.5) / (w * 0.46)
    dy = (yy - h * 0.5) / (h * 0.46)
    d = np.sqrt(dx * dx + dy * dy)
    a = np.clip(1.0 - d * d, 0.0, 1.0)
    a = (a * a * 0.68 * 255.0).astype(np.uint8)
    rgba = np.zeros((h, w, 4), dtype=np.uint8)
    rgba[:, :, 0] = 14
    rgba[:, :, 1] = 20
    rgba[:, :, 2] = 42
    rgba[:, :, 3] = a
    save_img(Image.fromarray(rgba, mode="RGBA"), "sombra_contacto.png")


if __name__ == "__main__":
    print(f"Generando texturas PBR estilizadas en {OUT_DIR}...")
    gen_balasto()
    gen_traviesa()
    gen_anden()
    gen_muros()
    gen_trenes()
    gen_tren_techo()
    gen_rampa()
    gen_vallas()
    gen_edificios()
    gen_carteles()
    gen_sombra()
    print("¡Todas las texturas generadas correctamente!")
