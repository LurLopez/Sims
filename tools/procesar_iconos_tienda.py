#!/usr/bin/env python3
"""Convierte los JPG magenta de la tienda en PNG con alfa listos para Godot.

Uso:
  python3 tools/procesar_iconos_tienda.py [--size 512] [--preview preview.png]

- Lee los originales de `Arte_Fuente/Tienda/Fuente/*.jpg` (fondo plano magenta;
  también acepta `Imagenes/Tienda/*.jpg` como respaldo).
- Recorta el fondo por croma, quita el derrame magenta del borde, recorta al
  contenido y lo centra en un lienzo cuadrado transparente.
- Escribe `Imagenes/Tienda/Iconos/<Nombre>.png` con el mismo nombre que la
  clave del catálogo (`Cama_Basica`, `Ducha_Premium`, ...).
"""
import argparse
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
# Los JPG originales viven fuera de res://Imagenes para que Godot no los importe
# al APK; solo los PNG recortados se empaquetan en el juego.
ORIGEN = ROOT / "Arte_Fuente" / "Tienda" / "Fuente"
RESPALDO = ROOT / "Imagenes" / "Tienda"
DESTINO = ROOT / "Imagenes" / "Tienda" / "Iconos"

# Original -> clave del catálogo (Catalogo_Tienda.gd).
# Los JPG llegan con fondo magenta; los PNG de las láminas ya vienen
# recortados con alfa. El script acepta ambos.
NOMBRES = {
    "Cama_Basica": "Cama_Basica",
    "Cama_Premium": "Cama_Premium",
    "Cama_Lujo": "Cama_Lujo",
    "Litera_Compacta": "Litera_Compacta",
    "Cama_Nube": "Cama_Nube",
    "Cama_Imperial": "Cama_Imperial",
    "Mesa_Basica": "Mesa_Basica",
    "Mesa_Familiar": "Mesa_Familiar",
    "Mesa_Roble": "Mesa_Roble",
    "Mesa_Cristal": "Mesa_Cristal",
    "Isla_Desayuno": "Isla_Desayuno",
    "Mesa_Chef": "Mesa_Chef",
    "Ducha_Basica": "Ducha_Basica",
    "Ducha_Premium": "Ducha_Premium",
    "Banera_Clasica": "Banera_Clasica",
    "Ducha_Lluvia": "Ducha_Lluvia",
    "Banera_Jacuzzi": "Banera_Jacuzzi",
    "Cabina_Spa": "Cabina_Spa",
    "Sofa_Basico": "Sofa_Basico",
    "Sofa_Esquinero": "Sofa_Esquinero",
    "Sofa_Chester": "Sofa_Chester",
    "Sofa_Relax": "Sofa_Relax",
    "Sofa_Modular": "Sofa_Modular",
    "Sofa_Imperial": "Sofa_Imperial",
    "Escritorio_Basico": "Escritorio_Basico",
    "Escritorio_Moderno": "Escritorio_Moderno",
    "Escritorio_Ejecutivo": "Escritorio_Ejecutivo",
    "Mesa_Dibujo": "Mesa_Dibujo",
    "Escritorio_Gaming": "Escritorio_Gaming",
    "Biblioteca_Roble": "Biblioteca_Roble",
    "Cocina_Basica": "Cocina_Basica",
    "Cocina_Modular": "Cocina_Modular",
    "Cocina_Isla": "Cocina_Isla",
    "Cocina_Chef": "Cocina_Chef",
    "Cocina_Pro": "Cocina_Pro",
    "Cocina_Industrial": "Cocina_Industrial",
}

# El fondo de las imágenes no es #FF00FF puro (varía entre lotes): se mide la
# diferencia entre el canal verde y el mínimo de rojo/azul. El magenta da
# valores altos (~180-255); crema, teal, madera y metal dan valores negativos.
SCORE_OPACO = 35.0
SCORE_TRANSPARENTE = 160.0


def recortar_magenta(imagen: Image.Image) -> Image.Image:
    rgb = np.asarray(imagen.convert("RGB")).astype(np.float32)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    score = np.clip(np.minimum(r, b) - g, 0, None)
    alfa = np.clip(1.0 - (score - SCORE_OPACO) / (SCORE_TRANSPARENTE - SCORE_OPACO), 0.0, 1.0)
    # Despill: quita el magenta que queda mezclado en los píxeles semitransparentes.
    derrame = score * (1.0 - alfa)
    rgb[..., 0] = np.clip(r - derrame, 0, 255)
    rgb[..., 2] = np.clip(b - derrame, 0, 255)
    return Image.fromarray(np.dstack([rgb, alfa * 255]).astype(np.uint8), "RGBA")


def limpiar_polvo(imagen: Image.Image, area_minima: int = 96) -> Image.Image:
    """Elimina motas opacas sueltas que hayan sobrevivido al recorte.

    Solo borra fragmentos pequeños que además estén lejos de la silueta
    principal, para no perder detalles separados a propósito (gotas, brillos).
    """
    try:
        import cv2
    except ImportError:
        return imagen
    arr = np.asarray(imagen).copy()
    mascara = (arr[..., 3] > 8).astype(np.uint8)
    num, etiquetas, stats, _ = cv2.connectedComponentsWithStats(mascara, connectivity=8)
    if num <= 2:
        return imagen
    principal = 1 + int(np.argmax(stats[1:, cv2.CC_STAT_AREA]))
    area_principal = float(stats[principal, cv2.CC_STAT_AREA])
    mx0, my0 = stats[principal, cv2.CC_STAT_LEFT], stats[principal, cv2.CC_STAT_TOP]
    mx1 = mx0 + stats[principal, cv2.CC_STAT_WIDTH]
    my1 = my0 + stats[principal, cv2.CC_STAT_HEIGHT]
    for i in range(1, num):
        if i == principal:
            continue
        x0, y0 = stats[i, cv2.CC_STAT_LEFT], stats[i, cv2.CC_STAT_TOP]
        x1 = x0 + stats[i, cv2.CC_STAT_WIDTH]
        y1 = y0 + stats[i, cv2.CC_STAT_HEIGHT]
        separacion = max(mx0 - x1, 0, x0 - mx1) + max(my0 - y1, 0, y0 - my1)
        if separacion > 12 and float(stats[i, cv2.CC_STAT_AREA]) < max(area_minima, area_principal * 0.002):
            arr[etiquetas == i, 3] = 0
    return Image.fromarray(arr, "RGBA")


def centrar_cuadrado(imagen: Image.Image, tamano: int, margen: float) -> Image.Image:
    alfa = np.asarray(imagen)[..., 3]
    ys, xs = np.where(alfa > 8)
    if len(xs) == 0:
        raise SystemExit("El recorte quedó vacío: revisa el umbral de croma")
    imagen = imagen.crop((int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1))
    util = max(1, round(tamano * (1.0 - 2.0 * margen)))
    escala = min(util / imagen.width, util / imagen.height)
    imagen = imagen.resize(
        (max(1, round(imagen.width * escala)), max(1, round(imagen.height * escala))),
        Image.LANCZOS,
    )
    lienzo = Image.new("RGBA", (tamano, tamano), (0, 0, 0, 0))
    lienzo.paste(imagen, ((tamano - imagen.width) // 2, (tamano - imagen.height) // 2), imagen)
    return lienzo


def crear_preview(iconos: list, ruta: Path, tamano: int) -> None:
    columnas = 3
    filas = (len(iconos) + columnas - 1) // columnas
    prev = Image.new("RGB", (tamano * columnas, tamano * filas), (250, 250, 252))
    dibujo = ImageDraw.Draw(prev)
    for i, (nombre, icono) in enumerate(iconos):
        x0, y0 = (i % columnas) * tamano, (i // columnas) * tamano
        for y in range(0, tamano, 32):
            for x in range(0, tamano, 32):
                if ((x + y) // 32) % 2 == 0:
                    dibujo.rectangle([x0 + x, y0 + y, x0 + x + 31, y0 + y + 31], fill=(224, 228, 234))
        prev.paste(icono, (x0, y0), icono)
        dibujo.text((x0 + 10, y0 + 10), nombre, fill=(17, 24, 39))
    prev.save(ruta)


def tiene_alfa_util(imagen: Image.Image) -> bool:
    """Las láminas ya recortadas traen alfa real; no hay que buscar magenta."""
    if imagen.mode not in ("RGBA", "LA"):
        return False
    alfa = np.asarray(imagen.convert("RGBA"))[..., 3]
    return float((alfa < 16).mean()) > 0.02


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--size", type=int, default=512, help="lado del lienzo final en píxeles")
    ap.add_argument("--margin", type=float, default=0.05, help="margen transparente por lado (0-0.2)")
    ap.add_argument("--preview", default="", help="ruta opcional para una hoja de control")
    args = ap.parse_args()

    DESTINO.mkdir(parents=True, exist_ok=True)
    procesados = []
    for nombre_fuente, clave in NOMBRES.items():
        ruta = None
        for carpeta in (ORIGEN, RESPALDO):
            for extension in (".jpg", ".jpeg", ".png"):
                candidata = carpeta / (nombre_fuente + extension)
                if candidata.exists():
                    ruta = candidata
                    break
            if ruta is not None:
                break
        if ruta is None:
            print(f"aviso: falta {nombre_fuente} en {ORIGEN} ni en {RESPALDO}")
            continue
        original = Image.open(ruta)
        if tiene_alfa_util(original):
            recortado = limpiar_polvo(original.convert("RGBA"))
        else:
            recortado = limpiar_polvo(recortar_magenta(original))
        icono = centrar_cuadrado(recortado, args.size, args.margin)
        salida = DESTINO / (clave + ".png")
        icono.save(salida, optimize=True)
        procesados.append((clave, icono))
        print(f"{ruta.name} -> {salida.relative_to(ROOT)}  {icono.width}x{icono.height}")

    if args.preview:
        crear_preview(procesados, Path(args.preview), args.size)
        print(f"preview -> {args.preview}")
    print(f"{len(procesados)} iconos de tienda listos en {DESTINO.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
