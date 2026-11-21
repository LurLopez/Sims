#!/usr/bin/env python3
"""Genera los 15 sprites de la pantalla de Mejoras de Cocina.

Cada hoja maestra de `Arte_Fuente/Minijuego_Cocina/Mejoras/` contiene las tres
variantes de una mejora (básica, mejorada y profesional) sobre fondo magenta.
Este script:

1. Recorta cada variante con la misma detección de blobs que `cortar_sprites.py`.
2. Limpia el halo blanco de las hojas generadas por IA.
3. Aplica un despill de magenta más agresivo que el estándar: los píxeles
   semitransparentes (vapor, brillos) quedan grises en vez de rosados.
4. Guarda los PNG finales en `Imagenes/Minijuego_Cocina/Mejoras/`.
5. Compone un catálogo de control en `Arte_Fuente/Minijuego_Cocina/Mejoras/`.

Uso:
  python3 tools/procesar_mejoras_cocina.py
  python3 tools/procesar_mejoras_cocina.py --solo plancha
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.dont_write_bytecode = True
import cortar_sprites as cs  # noqa: E402

RAIZ = Path(__file__).resolve().parent.parent
ORIGEN = RAIZ / "Arte_Fuente" / "Minijuego_Cocina" / "Mejoras"
DESTINO = RAIZ / "Imagenes" / "Minijuego_Cocina" / "Mejoras"
CATALOGO = ORIGEN / "catalogo_mejoras.png"

FAMILIAS: list[tuple[str, str]] = [
    ("plancha", "Plancha y Freidora"),
    ("emplatado", "Emplatado y Bebidas"),
    ("termostato", "Termostato"),
    ("ingredientes", "Calidad de Ingredientes"),
    ("ambiente", "Ambiente del Local"),
]
NIVELES = (1, 2, 3)
PAD = 6
MIN_AREA = 400
JOIN = 40
MAX_LADO = 640


def despill_magenta(imagen: Image.Image) -> Image.Image:
    """Elimina el resto de magenta sin tocar rojos, naranjas ni amarillos.

    En los píxeles de vapor/brillo el keying deja R y B por encima de G. Al
    restar todo el exceso (no solo una fracción) el halo rosa pasa a gris
    neutro y sigue conservando su alfa.
    """
    arr = np.asarray(imagen.convert("RGBA")).astype(np.float32).copy()
    rgb = arr[..., :3]
    rojo, verde, azul = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    exceso = np.clip(np.minimum(rojo, azul) - verde, 0.0, None)
    mascara = exceso > 6.0
    rgb[..., 0] = np.where(mascara, rojo - exceso, rojo)
    rgb[..., 2] = np.where(mascara, azul - exceso, azul)
    arr[..., :3] = np.clip(rgb, 0.0, 255.0)
    return Image.fromarray(arr.astype(np.uint8), "RGBA")


def recortar_hoja(ruta: Path, clave: str) -> list[Path]:
    if not ruta.exists():
        raise FileNotFoundError(f"Falta la hoja maestra: {ruta}")

    original = Image.open(ruta)
    keyed = original.convert("RGBA") if cs.has_alpha(original) else cs.key_magenta(original)
    keyed = cs.trim_white_halo(keyed)

    alpha = np.asarray(keyed)[..., 3]
    rects = cs.reading_order(cs.find_sprites(alpha, MIN_AREA, JOIN), 1)
    if len(rects) != len(NIVELES):
        raise RuntimeError(
            f"{ruta.name}: se esperaban {len(NIVELES)} sprites y se han encontrado {len(rects)}"
        )

    salidas: list[Path] = []
    for nivel, (x0, y0, x1, y1) in zip(NIVELES, rects):
        caja = (
            max(0, x0 - PAD),
            max(0, y0 - PAD),
            min(keyed.width, x1 + PAD),
            min(keyed.height, y1 + PAD),
        )
        sprite = cs.clean_specks(keyed.crop(caja))
        sprite = despill_magenta(sprite)
        if max(sprite.width, sprite.height) > MAX_LADO:
            factor = MAX_LADO / float(max(sprite.width, sprite.height))
            sprite = sprite.resize(
                (max(1, round(sprite.width * factor)), max(1, round(sprite.height * factor))),
                Image.LANCZOS,
            )
        destino = DESTINO / f"{clave}_nv{nivel}.png"
        destino.parent.mkdir(parents=True, exist_ok=True)
        sprite.save(destino, optimize=True)
        salidas.append(destino)
        print(f"  {destino.relative_to(RAIZ)}  {sprite.width}x{sprite.height}")
    return salidas


def generar_catalogo() -> None:
    ancho, alto = 420, 300
    lienzo = Image.new("RGB", (ancho * 3, alto * len(FAMILIAS)), (15, 23, 42))
    dibujo = ImageDraw.Draw(lienzo)
    for fila, (clave, titulo) in enumerate(FAMILIAS):
        for columna, nivel in enumerate(NIVELES):
            ruta = DESTINO / f"{clave}_nv{nivel}.png"
            if not ruta.exists():
                continue
            sprite = Image.open(ruta)
            sprite.thumbnail((ancho - 28, alto - 40), Image.LANCZOS)
            x = ancho * columna + (ancho - sprite.width) // 2
            y = alto * fila + (alto - sprite.height) // 2 + 6
            lienzo.paste(sprite, (x, y), sprite)
            dibujo.text(
                (ancho * columna + 10, alto * fila + 8),
                f"{titulo} · Nv.{nivel}",
                fill=(226, 232, 240),
            )
    lienzo.save(CATALOGO)
    print(f"Catálogo: {CATALOGO.relative_to(RAIZ)}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--solo", default="", help="procesa una sola familia (plancha, emplatado...)")
    args = parser.parse_args()

    familias = FAMILIAS
    if args.solo:
        familias = [f for f in FAMILIAS if f[0] == args.solo]
        if not familias:
            raise SystemExit(f"Familia desconocida: {args.solo}")

    print("Procesando mejoras de cocina...")
    for clave, titulo in familias:
        print(f"{titulo} ({clave})")
        recortar_hoja(ORIGEN / f"hoja_{clave}.png", clave)

    if not args.solo:
        generar_catalogo()
    print("Listo.")


if __name__ == "__main__":
    main()
