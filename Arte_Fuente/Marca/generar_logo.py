#!/usr/bin/env python3
"""Generador de los assets de marca de SIMS LIFE.

Convierte la tipografía a trazados SVG (sin depender de fuentes instaladas) y
compone el icono, los lockups y el gráfico destacado. Rasteriza con rsvg-convert.
"""
from __future__ import annotations

import base64
import math
import subprocess
from pathlib import Path

from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen

ROOT = Path(__file__).resolve().parents[2]
DIR_FUENTES = ROOT / "Fuentes" / "UI"
DIR_MARCA = ROOT / "Imagenes" / "Marca"
DIR_ARTE = ROOT / "Arte_Fuente" / "Marca"

TITAN = DIR_FUENTES / "TitanOne-400.ttf"
MULISH = DIR_FUENTES / "Mulish-800.ttf"
DM = DIR_FUENTES / "DMSans-700.ttf"

# Paleta de marca
ROJO = "#D62828"
ROJO_VIVO = "#E5342B"
ROJO_PROFUNDO = "#9E1622"
ROJO_SOMBRA = "#6E0B16"
GRANA = "#7A1020"
TINTA = "#231318"
CREMA = "#FFF7E8"
CREMA_SUAVE = "#F6E7CC"
ARENA = "#F3DFC0"
ORO = "#F5B942"
ORO_CLARO = "#FFE3A3"
ORO_OSCURO = "#D99A2B"
MELOCOTON = "#FDE3C8"
MELOCOTON_RAYO = "#F8C795"


def cargar_fuente(ruta: Path):
    f = TTFont(str(ruta))
    return f, f.getBestCmap(), f["head"].unitsPerEm, f["hmtx"], f.getGlyphSet()


def ancho_texto(texto: str, ruta: Path, tam: float, tracking: float = 0.0) -> float:
    f, cmap, upem, hmtx, _ = cargar_fuente(ruta)
    esc = tam / upem
    total = 0.0
    for i, ch in enumerate(texto):
        g = cmap.get(ord(ch))
        if g is None:
            continue
        total += hmtx[g][0] * esc
        if i < len(texto) - 1:
            total += tracking
    return total


def texto_svg(texto: str, ruta: Path, tam: float, x: float, y: float,
              tracking: float = 0.0, relleno: str = CREMA, trazo: str = "none",
              grosor_trazo: float = 0.0, extra: str = "") -> str:
    """Devuelve un <g> con el texto convertido a trazados. (x, y) = baseline izquierda."""
    _, cmap, upem, hmtx, glyphset = cargar_fuente(ruta)
    esc = tam / upem
    piezas = []
    cursor = x
    for ch in texto:
        gname = cmap.get(ord(ch))
        if gname is None:
            cursor += tam * 0.4
            continue
        glifo = glyphset[gname]
        pen = SVGPathPen(glyphset)
        glifo.draw(pen)
        d = pen.getCommands()
        piezas.append(
            f'<g transform="translate({cursor:.3f} {y:.3f}) scale({esc:.6f} {-esc:.6f})">'
            f'<path d="{d}" fill="{relleno}" stroke="{trazo}" stroke-width="{grosor_trazo / esc:.3f}" '
            f'stroke-linejoin="round" {extra}/></g>'
        )
        cursor += hmtx[gname][0] * esc + tracking
    return "".join(piezas)


def texto_path_d(texto: str, ruta: Path, tam: float, x: float, y: float,
                 tracking: float = 0.0) -> str:
    """Trazado combinado (sin transform por glifo), útil para clipPath."""
    _, cmap, upem, hmtx, glyphset = cargar_fuente(ruta)
    esc = tam / upem
    partes = []
    cursor = x
    for ch in texto:
        gname = cmap.get(ord(ch))
        if gname is None:
            cursor += tam * 0.4
            continue
        glifo = glyphset[gname]
        pen = SVGPathPen(glyphset)
        glifo.draw(pen)
        d = pen.getCommands()
        # El trazado viene en unidades de fuente con Y hacia arriba. Lo
        # trasladamos y volteamos para poder concatenarlo.
        partes.append(
            f'<path transform="translate({cursor:.3f} {y:.3f}) scale({esc:.6f} {-esc:.6f})" d="{d}"/>'
        )
        cursor += hmtx[gname][0] * esc + tracking
    return "".join(partes)


def estrella(cx: float, cy: float, r: float, relleno: str = ORO,
             trazo: str = ROJO_SOMBRA, grosor: float = 6.0, giro: float = 0.0,
             opacidad: float = 1.0) -> str:
    """Estrella de cuatro puntas con lados cóncavos (destello)."""
    k = 0.18
    p = [
        (0, -1), (k, -k), (1, 0), (k, k),
        (0, 1), (-k, k), (-1, 0), (-k, -k),
    ]
    pts = " ".join(f"{cx + px * r:.2f},{cy + py * r:.2f}" for px, py in p)
    return (f'<polygon points="{pts}" fill="{relleno}" stroke="{trazo}" '
            f'stroke-width="{grosor}" stroke-linejoin="round" opacity="{opacidad}" '
            f'transform="rotate({giro} {cx} {cy})"/>')


def corazon(cx: float, cy: float, r: float, relleno: str = GRANA) -> str:
    return (f'<path transform="translate({cx} {cy}) scale({r:.3f})" '
            f'd="M0 0.72 C-0.86 0.06 -0.82 -0.52 -0.36 -0.58 C-0.12 -0.62 0 -0.42 0 -0.32 '
            f'C0 -0.42 0.12 -0.62 0.36 -0.58 C0.82 -0.52 0.86 0.06 0 0.72 Z" '
            f'fill="{relleno}"/>')


def imagen_b64(ruta: Path) -> str:
    return base64.b64encode(ruta.read_bytes()).decode("ascii")


def asegurar_rgba(ruta: Path) -> None:
    """Play Console pide PNG de 32 bits: añade canal alfa si el render es RGB."""
    from PIL import Image
    img = Image.open(ruta).convert("RGBA")
    img.save(ruta)


def svg_a_png(svg: str, salida: Path, ancho: int, alto: int | None = None) -> None:
    salida.parent.mkdir(parents=True, exist_ok=True)
    tmp = salida.with_suffix(".tmp.svg")
    tmp.write_text(svg, encoding="utf-8")
    cmd = ["rsvg-convert", "-w", str(ancho)]
    if alto is not None:
        cmd += ["-h", str(alto)]
    cmd += [str(tmp), "-o", str(salida)]
    subprocess.run(cmd, check=True)
    tmp.unlink(missing_ok=True)
    try:
        etiqueta = salida.relative_to(ROOT)
    except ValueError:
        etiqueta = salida
    print(f"  · {etiqueta}  ({salida.stat().st_size // 1024} KB)")


# ------------------------------------------------------------------ wordmark

W_SIMS = 250.0
TRACKING_SIMS = 4.0
BASE_Y = 292.0


def wordmark_svg(relleno: str = CREMA, sombra: str = ROJO_SOMBRA,
                 brillo: bool = True, vida_fondo: str = ORO,
                 vida_texto: str = GRANA) -> tuple[str, float, float]:
    """Devuelve (svg, ancho, alto) del bloque SIMS + LIFE, sin subtítulo."""
    texto = "SIMS"
    ancho_sims = ancho_texto(texto, TITAN, W_SIMS, TRACKING_SIMS)
    # Etiqueta LIFE a la derecha, ligeramente girada y solapando la base.
    vida_tam = 74.0
    vida_tracking = 7.0
    ancho_vida = ancho_texto("LIFE", TITAN, vida_tam, vida_tracking)
    tag_w = ancho_vida + 96
    tag_h = 104
    tag_x = ancho_sims - 4
    tag_y = BASE_Y - 62
    total_w = tag_x + tag_w + 96
    total_h = 360

    defs = f"""
    <defs>
      <linearGradient id="cara" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stop-color="#FFFDF6"/>
        <stop offset="0.55" stop-color="{relleno}"/>
        <stop offset="1" stop-color="#F4DDB8"/>
      </linearGradient>
      <linearGradient id="oro" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stop-color="#FFE9A8"/>
        <stop offset="0.45" stop-color="{vida_fondo}"/>
        <stop offset="1" stop-color="{ORO_OSCURO}"/>
      </linearGradient>
      <linearGradient id="sombra" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stop-color="{sombra}"/>
        <stop offset="1" stop-color="#4C0710"/>
      </linearGradient>
      <clipPath id="recorte_sims">
        {texto_path_d(texto, TITAN, W_SIMS, 0, BASE_Y, TRACKING_SIMS)}
      </clipPath>
    </defs>
    """

    # Extrusión: varias copias del texto descendiendo.
    ext = []
    for i in range(0, 17):
        op = 1.0
        ext.append(texto_svg(texto, TITAN, W_SIMS, 0, BASE_Y + i, TRACKING_SIMS,
                             relleno="#4C0710"))

    # Contorno grueso + cara con degradado.
    contorno = texto_svg(texto, TITAN, W_SIMS, 0, BASE_Y, TRACKING_SIMS,
                         relleno="none", trazo=ROJO_SOMBRA, grosor_trazo=26.0)
    cara = texto_svg(texto, TITAN, W_SIMS, 0, BASE_Y, TRACKING_SIMS,
                     relleno="url(#cara)")

    brillo_svg = ""
    if brillo:
        brillo_svg = f"""
        <g clip-path="url(#recorte_sims)">
          <ellipse cx="{ancho_sims * 0.30:.1f}" cy="{BASE_Y - 196:.1f}"
                   rx="{ancho_sims * 0.48:.1f}" ry="54" fill="#FFFFFF" opacity="0.20"
                   transform="rotate(-12 {ancho_sims * 0.30:.1f} {BASE_Y - 196:.1f})"/>
          <ellipse cx="{ancho_sims * 0.76:.1f}" cy="{BASE_Y - 212:.1f}"
                   rx="{ancho_sims * 0.22:.1f}" ry="22" fill="#FFFFFF" opacity="0.16"
                   transform="rotate(-12 {ancho_sims * 0.76:.1f} {BASE_Y - 212:.1f})"/>
        </g>"""

    vida = f"""
    <g transform="rotate(-7 {tag_x + tag_w * 0.5:.1f} {tag_y + tag_h * 0.5:.1f})">
      <rect x="{tag_x:.1f}" y="{tag_y + 10:.1f}" width="{tag_w:.1f}" height="{tag_h:.1f}"
            rx="30" fill="#4C0710" opacity="0.55"/>
      <rect x="{tag_x:.1f}" y="{tag_y:.1f}" width="{tag_w:.1f}" height="{tag_h:.1f}"
            rx="30" fill="url(#oro)" stroke="{ROJO_SOMBRA}" stroke-width="12"/>
      <rect x="{tag_x + 8:.1f}" y="{tag_y + 8:.1f}" width="{tag_w - 16:.1f}" height="{tag_h - 16:.1f}"
            rx="23" fill="none" stroke="#FFF3D0" stroke-width="3.5" opacity="0.85"/>
      {corazon(tag_x + 36, tag_y + tag_h * 0.5 + 2, 21, vida_texto)}
      {texto_svg("LIFE", TITAN, vida_tam, tag_x + 62, tag_y + tag_h * 0.5 + 26,
                 vida_tracking, relleno=vida_texto)}
      <path d="M {tag_x + 20:.1f} {tag_y + 10:.1f} Q {tag_x + tag_w * 0.5:.1f} {tag_y - 2:.1f} {tag_x + tag_w - 20:.1f} {tag_y + 10:.1f}"
            fill="none" stroke="#FFFFFF" stroke-width="4" stroke-linecap="round" opacity="0.55"/>
    </g>
    """

    destello = f"""
    {estrella(ancho_sims + 40, 88, 42, ORO_CLARO, ROJO_SOMBRA, 6, -8)}
    {estrella(ancho_sims + 82, 44, 15, ORO_CLARO, ROJO_SOMBRA, 4, -8, 0.95)}
    <circle cx="{ancho_sims + 12:.1f}" cy="150" r="7" fill="{ORO_CLARO}" opacity="0.9"/>
    """

    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{total_w:.0f}" height="{total_h}" '
           f'viewBox="0 0 {total_w:.0f} {total_h}">{defs}'
           f'<g>{"".join(ext)}{contorno}{cara}{brillo_svg}</g>{vida}{destello}</svg>')
    return svg, total_w, total_h


# ------------------------------------------------------------------ medallón

def medallon_svg(lado: int = 1024, con_mascota: bool = True) -> str:
    """Insignia circular. El centro queda transparente si no se incrusta la mascota."""
    c = lado * 0.5
    R = lado * 0.452
    r_crema = R * 0.951
    r_rojo = R * 0.886
    r_oro = R * 0.837
    r_hueco = R * 0.790

    defs = f"""
    <defs>
      <linearGradient id="med_oro" x1="0" y1="0" x2="0.35" y2="1">
        <stop offset="0" stop-color="#FFF0BF"/>
        <stop offset="0.42" stop-color="{ORO}"/>
        <stop offset="1" stop-color="{ORO_OSCURO}"/>
      </linearGradient>
      <linearGradient id="med_crema" x1="0.1" y1="0" x2="0.9" y2="1">
        <stop offset="0" stop-color="#FFFDF7"/>
        <stop offset="0.55" stop-color="{CREMA}"/>
        <stop offset="1" stop-color="#EBD3AE"/>
      </linearGradient>
      <linearGradient id="med_rojo" x1="0" y1="0" x2="0.55" y2="1">
        <stop offset="0" stop-color="#F04A3A"/>
        <stop offset="0.45" stop-color="{ROJO}"/>
        <stop offset="1" stop-color="{ROJO_PROFUNDO}"/>
      </linearGradient>
      <radialGradient id="med_luz" cx="0.34" cy="0.22" r="0.75">
        <stop offset="0" stop-color="#FFFFFF" stop-opacity="0.22"/>
        <stop offset="0.55" stop-color="#FFFFFF" stop-opacity="0.05"/>
        <stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/>
      </radialGradient>
      <clipPath id="med_cara"><circle cx="{c}" cy="{c}" r="{r_hueco}"/></clipPath>
      <mask id="med_hueco" maskUnits="userSpaceOnUse" x="0" y="0" width="{lado}" height="{lado}">
        <rect x="0" y="0" width="{lado}" height="{lado}" fill="#FFFFFF"/>
        <circle cx="{c}" cy="{c}" r="{r_hueco}" fill="#000000"/>
      </mask>
      <filter id="med_sombra" x="-25%" y="-25%" width="150%" height="160%">
        <feDropShadow dx="0" dy="{lado * 0.018:.1f}" stdDeviation="{lado * 0.020:.1f}"
                      flood-color="#3A0710" flood-opacity="0.42"/>
      </filter>
      <filter id="med_suave" x="-30%" y="-30%" width="160%" height="160%">
        <feGaussianBlur stdDeviation="{lado * 0.006:.1f}"/>
      </filter>
    </defs>
    """

    mascota = ""
    if con_mascota:
        b64 = imagen_b64(DIR_ARTE / "mascota_logo.png")
        d = r_hueco * 2
        mascota = (f'<g clip-path="url(#med_cara)">'
                   f'<image x="{c - r_hueco:.2f}" y="{c - r_hueco:.2f}" width="{d:.2f}" height="{d:.2f}" '
                   f'preserveAspectRatio="xMidYMid slice" '
                   f'xlink:href="data:image/png;base64,{b64}" '
                   f'xmlns:xlink="http://www.w3.org/1999/xlink"/></g>')

    brillo_aro = (
        f'<path d="M {c - r_crema * 0.94:.1f} {c - r_crema * 0.34:.1f} '
        f'A {r_crema:.1f} {r_crema:.1f} 0 0 1 {c - r_crema * 0.30:.1f} {c - r_crema * 0.95:.1f}" '
        f'fill="none" stroke="#FFFFFF" stroke-width="{lado * 0.011:.1f}" '
        f'stroke-linecap="round" opacity="0.55" filter="url(#med_suave)"/>'
    )

    remaches = []
    for i in range(8):
        a = math.radians(-68 + i * 45)
        rr = (r_crema + r_rojo) * 0.5
        remaches.append(f'<circle cx="{c + math.cos(a) * rr:.2f}" cy="{c + math.sin(a) * rr:.2f}" '
                        f'r="{lado * 0.0052:.1f}" fill="{ORO_OSCURO}" opacity="0.55"/>')

    destello = (
        estrella(c + R * 0.660, c - R * 0.700, R * 0.205, ORO_CLARO, ROJO_SOMBRA, lado * 0.008, -9)
        + estrella(c + R * 0.865, c - R * 0.905, R * 0.070, "#FFFFFF", "none", 0, -9, 0.95)
        + f'<circle cx="{c + R * 0.470:.1f}" cy="{c - R * 0.910:.1f}" r="{lado * 0.008:.1f}" fill="{ORO_CLARO}" opacity="0.95"/>'
        + f'<circle cx="{c + R * 0.900:.1f}" cy="{c - R * 0.540:.1f}" r="{lado * 0.005:.1f}" fill="#FFFFFF" opacity="0.75"/>'
    )

    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{lado}" height="{lado}"
      viewBox="0 0 {lado} {lado}">{defs}
      <g filter="url(#med_sombra)" mask="url(#med_hueco)">
        <circle cx="{c}" cy="{c}" r="{R}" fill="url(#med_oro)" stroke="{ROJO_SOMBRA}" stroke-width="{lado * 0.011:.1f}"/>
        <circle cx="{c}" cy="{c}" r="{r_crema}" fill="url(#med_crema)" stroke="{ROJO_SOMBRA}" stroke-width="{lado * 0.0065:.1f}"/>
        <circle cx="{c}" cy="{c}" r="{r_rojo}" fill="url(#med_rojo)" stroke="{ROJO_SOMBRA}" stroke-width="{lado * 0.0065:.1f}"/>
        <circle cx="{c}" cy="{c}" r="{r_oro}" fill="none" stroke="#FFDC93" stroke-width="{lado * 0.0035:.1f}" opacity="0.95"/>
        <circle cx="{c}" cy="{c}" r="{R * 0.995}" fill="url(#med_luz)" pointer-events="none"/>
      </g>
      {mascota}
      <circle cx="{c}" cy="{c}" r="{r_hueco + lado * 0.004:.1f}" fill="none" stroke="#FFF9EC" stroke-width="{lado * 0.007:.1f}"/>
      <circle cx="{c}" cy="{c}" r="{r_hueco + lado * 0.007:.1f}" fill="none" stroke="{ROJO_SOMBRA}" stroke-width="{lado * 0.0035:.1f}" opacity="0.85"/>
      <circle cx="{c}" cy="{c}" r="{r_crema}" fill="none" stroke="#FFFDF4" stroke-width="{lado * 0.0045:.1f}" opacity="0.55"/>
      {brillo_aro}
      {"".join(remaches)}
      {destello}
    </svg>"""


# ------------------------------------------------------------------ fondos

def fondo_svg(ancho: int, alto: int, tipo: str = "rojo") -> str:
    if tipo == "claro":
        base = CREMA
        return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{ancho}" height="{alto}" viewBox="0 0 {ancho} {alto}">
        <rect width="{ancho}" height="{alto}" fill="{base}"/>
        <g fill="{ORO_OSCURO}" opacity="0.10">
          <circle cx="{ancho*0.08:.1f}" cy="{alto*0.16:.1f}" r="1.7"/>
          <circle cx="{ancho*0.16:.1f}" cy="{alto*0.82:.1f}" r="1.4"/>
          <circle cx="{ancho*0.93:.1f}" cy="{alto*0.26:.1f}" r="1.6"/>
          <circle cx="{ancho*0.88:.1f}" cy="{alto*0.88:.1f}" r="1.4"/>
        </g>
        <rect x="10" y="10" width="{ancho-20}" height="{alto-20}" rx="14" fill="none" stroke="{ORO_OSCURO}" stroke-width="1.5" opacity="0.22"/>
        </svg>"""

    if tipo == "oscuro":
        estrellas = []
        for fx, fy, fr in [(0.09, 0.22, 2.0), (0.17, 0.76, 1.4), (0.31, 0.12, 1.2),
                           (0.63, 0.86, 1.5), (0.82, 0.18, 1.8), (0.93, 0.68, 1.3),
                           (0.73, 0.32, 1.1), (0.48, 0.08, 1.2)]:
            estrellas.append(f'<circle cx="{ancho*fx:.1f}" cy="{alto*fy:.1f}" r="{fr}" fill="#FFF2D6" opacity="0.55"/>')
        return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{ancho}" height="{alto}" viewBox="0 0 {ancho} {alto}">
          <defs>
            <linearGradient id="fondo_osc" x1="0" y1="0" x2="1" y2="1">
              <stop offset="0" stop-color="#2A1730"/>
              <stop offset="0.52" stop-color="#1B1324"/>
              <stop offset="1" stop-color="#120D19"/>
            </linearGradient>
            <radialGradient id="fondo_osc_luz" cx="0.22" cy="0.25" r="0.72">
              <stop offset="0" stop-color="#D62828" stop-opacity="0.34"/>
              <stop offset="0.55" stop-color="#8E1220" stop-opacity="0.10"/>
              <stop offset="1" stop-color="#120D19" stop-opacity="0"/>
            </radialGradient>
          </defs>
          <rect width="{ancho}" height="{alto}" fill="url(#fondo_osc)"/>
          <rect width="{ancho}" height="{alto}" fill="url(#fondo_osc_luz)"/>
          {"".join(estrellas)}
          <rect x="10" y="10" width="{ancho-20}" height="{alto-20}" rx="14" fill="none" stroke="{CREMA}" stroke-width="1.2" opacity="0.14"/>
        </svg>"""

    # Rojo: degradado cálido + franjas diagonales + viñeta
    franjas = []
    paso = ancho * 0.075
    ancho_f = ancho * 0.028
    sesgo = alto * 0.9
    x = -sesgo
    while x < ancho + paso:
        franjas.append(f"M {x:.1f} {alto} L {x + ancho_f:.1f} {alto} "
                       f"L {x + ancho_f + sesgo:.1f} 0 L {x + sesgo:.1f} 0 Z")
        x += paso
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{ancho}" height="{alto}" viewBox="0 0 {ancho} {alto}">
      <defs>
        <linearGradient id="fondo_rojo" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stop-color="#ED4133"/>
          <stop offset="0.48" stop-color="{ROJO}"/>
          <stop offset="1" stop-color="#A81420"/>
        </linearGradient>
        <radialGradient id="fondo_luz" cx="0.24" cy="0.12" r="0.85">
          <stop offset="0" stop-color="#FF8A5C" stop-opacity="0.52"/>
          <stop offset="0.5" stop-color="#FF6A4A" stop-opacity="0.12"/>
          <stop offset="1" stop-color="#5C0714" stop-opacity="0.28"/>
        </radialGradient>
      </defs>
      <rect width="{ancho}" height="{alto}" fill="url(#fondo_rojo)"/>
      <path d="{' '.join(franjas)}" fill="#FFFFFF" opacity="0.045"/>
      <rect width="{ancho}" height="{alto}" fill="url(#fondo_luz)"/>
    </svg>"""


# ------------------------------------------------------------------ lockups

def _renombrar_ids(fragmento: str, prefijo: str) -> str:
    for nombre in ["med_oro", "med_crema", "med_rojo", "med_luz", "med_cara",
                   "med_sombra", "med_suave", "cara", "oro", "sombra", "recorte_sims"]:
        fragmento = fragmento.replace(f'id="{nombre}"', f'id="{prefijo}_{nombre}"')
        fragmento = fragmento.replace(f'url(#{nombre})', f'url(#{prefijo}_{nombre})')
    return fragmento


def _interior_svg(svg: str) -> str:
    return svg.split(">", 1)[1].rsplit("</svg>", 1)[0]


def lockup_svg(ancho: int = 1024, alto: int = 240, tipo: str = "rojo",
               subtitulo: bool = True) -> str:
    wm_svg, wm_w, wm_h = wordmark_svg(
        relleno=CREMA if tipo != "claro" else "#C9202C",
        sombra=ROJO_SOMBRA if tipo != "claro" else "#6E0B16",
        vida_fondo=ORO,
        vida_texto=GRANA,
    )
    interior = _renombrar_ids(_interior_svg(wm_svg), "wm")
    med_int = _renombrar_ids(_interior_svg(medallon_svg(1024)), "lk")

    badge = 200.0
    badge_x = 172.0
    badge_y = (alto - badge) * 0.5
    esc_med = badge / 1024.0
    texto_x = badge_x + badge + 34.0
    wm_h_px = 142.0
    esc_wm = wm_h_px / wm_h
    wm_y = 34.0

    sub = ""
    if subtitulo:
        sub_tam = 24.0
        sub_y = 211.0
        color = "#FFF0D6" if tipo != "claro" else "#5C2A2F"
        sub = (f'<rect x="{texto_x:.1f}" y="{sub_y - 26:.1f}" width="42" height="4.5" rx="2.25" '
               f'fill="{ORO if tipo != "claro" else ORO_OSCURO}"/>'
               f'{texto_svg("Simulador de vida en tiempo real", MULISH, sub_tam, texto_x + 56, sub_y, 0.4, relleno=color)}')

    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{ancho}" height="{alto}" viewBox="0 0 {ancho} {alto}">
      {fondo_svg(ancho, alto, tipo)}
      <g transform="translate({badge_x:.1f} {badge_y:.1f}) scale({esc_med:.6f})">{med_int}</g>
      <g transform="translate({texto_x:.1f} {wm_y:.1f}) scale({esc_wm:.6f})">{interior}</g>
      {sub}
    </svg>"""


# ------------------------------------------------------------------ icono y piezas

def icono_svg(lado: int = 1024) -> str:
    fondo_int = _interior_svg(fondo_svg(lado, lado, "rojo"))
    med_int = _renombrar_ids(_interior_svg(medallon_svg(1024)), "ic")
    badge = lado * 0.825
    esc = badge / 1024.0
    x = (lado - badge) * 0.5
    y = (lado - badge) * 0.5 - lado * 0.008
    halo = f"""<circle cx="{lado*0.5}" cy="{lado*0.5}" r="{badge*0.47:.1f}"
                 fill="{CREMA}" opacity="0.10" filter="url(#ic_blur)"/>"""
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{lado}" height="{lado}" viewBox="0 0 {lado} {lado}">
      <defs>
        <filter id="ic_blur" x="-40%" y="-40%" width="180%" height="180%">
          <feGaussianBlur stdDeviation="{lado*0.035:.1f}"/>
        </filter>
        <radialGradient id="ic_vineta" cx="0.5" cy="0.42" r="0.72">
          <stop offset="0.55" stop-color="#5C0714" stop-opacity="0"/>
          <stop offset="1" stop-color="#5C0714" stop-opacity="0.34"/>
        </radialGradient>
      </defs>
      {fondo_int}
      {halo}
      <g transform="translate({x:.1f} {y:.1f}) scale({esc:.6f})">{med_int}</g>
      <rect width="{lado}" height="{lado}" fill="url(#ic_vineta)"/>
    </svg>"""


def feature_svg(ancho: int = 1024, alto: int = 500) -> str:
    wm_svg, wm_w, wm_h = wordmark_svg()
    interior = _renombrar_ids(_interior_svg(wm_svg), "ft")
    med_int = _renombrar_ids(_interior_svg(medallon_svg(1024)), "ftm")

    badge = 300.0
    badge_x, badge_y = 52.0, 100.0
    esc_med = badge / 1024.0
    texto_x = badge_x + badge + 48.0
    wm_h_px = 200.0
    esc_wm = wm_h_px / wm_h
    wm_y = 100.0
    sub_y = 390.0
    sub = (f'<rect x="{texto_x:.1f}" y="{sub_y - 32:.1f}" width="58" height="5" rx="2.5" fill="{ORO}"/>'
           f'{texto_svg("Simulador de vida en tiempo real", MULISH, 31.0, texto_x + 76, sub_y, 0.6, relleno="#FFF0D6")}')
    deco = (estrella(ancho - 96, 86, 28, ORO_CLARO, ROJO_SOMBRA, 5, -12)
            + estrella(ancho - 48, 132, 11, "#FFF6DF", "none", 0, -12, 0.85)
            + f'<circle cx="{ancho - 132:.1f}" cy="140" r="5" fill="{ORO_CLARO}" opacity="0.9"/>')
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{ancho}" height="{alto}" viewBox="0 0 {ancho} {alto}">
      {fondo_svg(ancho, alto, "rojo")}
      <g transform="translate({badge_x:.1f} {badge_y:.1f}) scale({esc_med:.6f})">{med_int}</g>
      <g transform="translate({texto_x:.1f} {wm_y:.1f}) scale({esc_wm:.6f})">{interior}</g>
      {sub}
      {deco}
    </svg>"""


def vertical_svg(lado: int = 1024) -> str:
    wm_svg, wm_w, wm_h = wordmark_svg()
    interior = _renombrar_ids(_interior_svg(wm_svg), "vt")
    med_int = _renombrar_ids(_interior_svg(medallon_svg(1024)), "vtm")
    badge = lado * 0.46
    esc_med = badge / 1024.0
    badge_x = (lado - badge) * 0.5
    badge_y = lado * 0.115
    wm_h_px = lado * 0.205
    esc_wm = wm_h_px / wm_h
    wm_w_px = wm_w * esc_wm
    wm_x = (lado - wm_w_px) * 0.5
    wm_y = lado * 0.615
    sub_y = lado * 0.885
    sub = texto_svg("Simulador de vida en tiempo real", MULISH, lado * 0.027, lado * 0.5,
                    sub_y, 0.7, relleno="#FFF0D6")
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{lado}" height="{lado}" viewBox="0 0 {lado} {lado}">
      {fondo_svg(lado, lado, "rojo")}
      <g transform="translate({badge_x:.1f} {badge_y:.1f}) scale({esc_med:.6f})">{med_int}</g>
      <g transform="translate({wm_x:.1f} {wm_y:.1f}) scale({esc_wm:.6f})">{interior}</g>
      <g transform="translate({lado*0.5:.1f} {sub_y:.1f})">{sub}</g>
    </svg>"""


# ------------------------------------------------------------------ iconos android

def adaptativo_frente_svg(lado: int = 432) -> str:
    """Primer plano adaptativo: insignia centrada al 60 % (zona segura)."""
    med_int = _renombrar_ids(_interior_svg(medallon_svg(1024)), "af")
    badge = lado * 0.60
    esc = badge / 1024.0
    x = (lado - badge) * 0.5
    y = (lado - badge) * 0.5
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{lado}" height="{lado}" viewBox="0 0 {lado} {lado}">
      <g transform="translate({x:.1f} {y:.1f}) scale({esc:.6f})">{med_int}</g>
    </svg>"""


def splash_svg(lado: int = 512, escala: float = 0.72) -> str:
    """Medallón sobre lienzo transparente para el splash de Android 12+."""
    med_int = _renombrar_ids(_interior_svg(medallon_svg(1024)), "sp")
    badge = lado * escala
    esc = badge / 1024.0
    x = (lado - badge) * 0.5
    y = (lado - badge) * 0.5
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{lado}" height="{lado}" viewBox="0 0 {lado} {lado}">
      <g transform="translate({x:.1f} {y:.1f}) scale({esc:.6f})">{med_int}</g>
    </svg>"""


def monocromo_svg(lado: int = 432) -> str:
    c = lado * 0.5
    R = lado * 0.30
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{lado}" height="{lado}" viewBox="0 0 {lado} {lado}">
      <g fill="#FFFFFF">
        <path fill-rule="evenodd" d="M {c} {c-R} a {R} {R} 0 1 0 0.01 0 Z
          M {c-R*0.78:.1f} {c-R*0.44:.1f} L {c-R*0.62:.1f} {c-R*0.72:.1f} L {c-R*0.34:.1f} {c-R*0.60:.1f}
          L {c-R*0.10:.1f} {c-R*0.78:.1f} L {c+R*0.12:.1f} {c-R*0.62:.1f} L {c+R*0.38:.1f} {c-R*0.76:.1f}
          L {c+R*0.62:.1f} {c-R*0.58:.1f} L {c+R*0.82:.1f} {c-R*0.72:.1f} L {c+R*0.92:.1f} {c-R*0.34:.1f}
          C {c+R*0.55:.1f} {c-R*0.52:.1f} {c-R*0.55:.1f} {c-R*0.52:.1f} {c-R*0.92:.1f} {c-R*0.34:.1f} Z
          M {c-R*0.46:.1f} {c-R*0.10:.1f} a {R*0.16:.1f} {R*0.20:.1f} 0 1 0 0.01 0 Z
          M {c+R*0.46:.1f} {c-R*0.10:.1f} a {R*0.16:.1f} {R*0.20:.1f} 0 1 0 0.01 0 Z
          M {c-R*0.44:.1f} {c+R*0.18:.1f} Q {c} {c+R*0.58:.1f} {c+R*0.44:.1f} {c+R*0.18:.1f}
          Q {c} {c+R*0.40:.1f} {c-R*0.44:.1f} {c+R*0.18:.1f} Z" />
      </g>
    </svg>"""



# ------------------------------------------------------------------ salida final

def generar_todo() -> None:
    DIR_MARCA.mkdir(parents=True, exist_ok=True)
    DIR_ARTE.mkdir(parents=True, exist_ok=True)

    # Wordmark transparente para el logo in-game. El maestro se guarda a tamaño
    # completo en Arte_Fuente; la copia de runtime se reduce a 512 px de ancho
    # (se dibuja a ~180 px) para no cargar 4 MB de textura en cada arranque.
    wm, ww, wh = wordmark_svg()
    svg_a_png(wm, DIR_ARTE / "wordmark_claro_1013.png", int(ww), int(wh))
    svg_a_png(wm, DIR_MARCA / "wordmark_claro.png", 512, 182)
    wm2, ww2, wh2 = wordmark_svg(relleno="#C9202C", sombra="#6E0B16")
    svg_a_png(wm2, DIR_ARTE / "wordmark_oscuro_1013.png", int(ww2), int(wh2))
    svg_a_png(wm2, DIR_MARCA / "wordmark_oscuro.png", 512, 182)

    # Marco del medallón (centro transparente) y medallón completo. El marco
    # de runtime se dibuja a 104 px: 256 px sobran y ahorran 3,75 MB de RAM.
    marco = medallon_svg(1024, con_mascota=False)
    svg_a_png(marco, DIR_ARTE / "medallon_marco_1024.png", 1024, 1024)
    svg_a_png(marco, DIR_MARCA / "medallon_marco.png", 256, 256)
    completo = medallon_svg(1024, con_mascota=True)
    svg_a_png(completo, DIR_ARTE / "medallon_completo.png", 1024, 1024)

    # Icono de tienda / lanzador
    icono = icono_svg(1024)
    svg_a_png(icono, DIR_MARCA / "logo_play_store_1024.png", 1024, 1024)
    svg_a_png(icono, DIR_MARCA / "logo_play_store_512.png", 512, 512)
    asegurar_rgba(DIR_MARCA / "logo_play_store_1024.png")
    asegurar_rgba(DIR_MARCA / "logo_play_store_512.png")

    # Lockups horizontales
    svg_a_png(lockup_svg(1024, 240, "rojo"),
              DIR_MARCA / "logo_horizontal_1024x240.png", 1024, 240)
    svg_a_png(lockup_svg(1024, 240, "claro"),
              DIR_MARCA / "logo_horizontal_claro_1024x240.png", 1024, 240)
    svg_a_png(lockup_svg(1024, 240, "oscuro"),
              DIR_MARCA / "logo_horizontal_oscuro_1024x240.png", 1024, 240)

    # Piezas de campaña
    svg_a_png(feature_svg(1024, 500), DIR_MARCA / "feature_graphic_1024x500.png", 1024, 500)
    svg_a_png(vertical_svg(1024), DIR_MARCA / "logo_vertical_1024.png", 1024, 1024)

    # Iconos Android
    iconos = ROOT / "Iconos_Android"
    iconos.mkdir(parents=True, exist_ok=True)
    svg_a_png(icono, iconos / "icono_192.png", 192, 192)
    svg_a_png(splash_svg(512, 0.72), iconos / "splash_icon_512.png", 512, 512)
    svg_a_png(adaptativo_frente_svg(432), iconos / "icono_adaptativo_frente_432.png", 432, 432)
    svg_a_png(monocromo_svg(432), iconos / "icono_monocromo_432.png", 432, 432)

    fondo = fondo_svg(432, 432, "rojo")
    svg_a_png(fondo, iconos / "icono_adaptativo_fondo_432.png", 432, 432)

    # Fondos para variantes personalizadas (dentro de res:// para que Godot los importe)
    fondos = DIR_MARCA / "Fondos"
    fondos.mkdir(parents=True, exist_ok=True)
    for tipo in ["rojo", "claro", "oscuro"]:
        svg_a_png(fondo_svg(1024, 240, tipo),
                  fondos / f"fondo_{tipo}_1024x240.png", 1024, 240)
    svg_a_png(fondo_svg(1024, 500, "rojo"),
              fondos / "fondo_rojo_1024x500.png", 1024, 500)
    svg_a_png(fondo_svg(432, 432, "rojo"),
              fondos / "fondo_rojo_432.png", 432, 432)

    # Fuentes SVG para documentación / futuras regeneraciones
    (DIR_ARTE / "icono.svg").write_text(icono, encoding="utf-8")
    (DIR_ARTE / "monocromo.svg").write_text(monocromo_svg(432), encoding="utf-8")
    (DIR_ARTE / "lockup_rojo.svg").write_text(lockup_svg(1024, 240, "rojo"), encoding="utf-8")
    (DIR_ARTE / "lockup_claro.svg").write_text(lockup_svg(1024, 240, "claro"), encoding="utf-8")
    (DIR_ARTE / "lockup_oscuro.svg").write_text(lockup_svg(1024, 240, "oscuro"), encoding="utf-8")


if __name__ == "__main__":
    generar_todo()
