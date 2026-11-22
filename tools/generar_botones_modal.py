#!/usr/bin/env python3
"""Genera las texturas 9-patch de los botones glossy de los modales de cocina.

Parte de los botones del pack (Boton_Azul/Verde/Naranja.png), los aplana a la
altura de uso y repite una columna central uniforme para que el nine-patch
estire solo el centro sin deformar los remates ni el brillo del lateral.

Salida: Imagenes/Minijuego_Cocina/UI/Boton_Modal_{Azul,Verde,Naranja,Rojo}.png
"""

from __future__ import annotations

import colorsys
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
DIR_UI = RAIZ / "Imagenes" / "Minijuego_Cocina" / "UI"

ALTO = 64
ANCHO = 600
REMACHE = 64  # ancho fijo de cada extremo; el resto es la zona estirable


def _escalar(ruta: Path) -> Image.Image:
    imagen = Image.open(ruta).convert("RGBA")
    ancho = max(1, round(imagen.width * ALTO / imagen.height))
    return imagen.resize((ancho, ALTO), Image.LANCZOS)


def _construir_ninepatch(imagen: Image.Image) -> Image.Image:
    if imagen.width < REMACHE * 2 + 8:
        raise ValueError("La textura de origen es demasiado estrecha")
    salida = Image.new("RGBA", (ANCHO, ALTO), (0, 0, 0, 0))
    # Remate izquierdo (incluye el brillo) y derecho.
    salida.paste(imagen.crop((0, 0, REMACHE, ALTO)), (0, 0))
    salida.paste(
        imagen.crop((imagen.width - REMACHE, 0, imagen.width, ALTO)),
        (ANCHO - REMACHE, 0),
    )
    # Columna central uniforme que el nine-patch puede estirar sin costuras.
    columna = imagen.crop((REMACHE, 0, REMACHE + 1, ALTO))
    columna = columna.resize((ANCHO - REMACHE * 2, ALTO), Image.NEAREST)
    salida.paste(columna, (REMACHE, 0))
    return salida


def _tinte_rojo(imagen: Image.Image) -> Image.Image:
    salida = imagen.copy()
    pixeles = salida.load()
    for y in range(salida.height):
        for x in range(salida.width):
            r, g, b, a = pixeles[x, y]
            if a == 0:
                continue
            h, l, s = colorsys.rgb_to_hls(r / 255.0, g / 255.0, b / 255.0)
            h = (h - 0.085) % 1.0
            s = min(1.0, s * 1.08)
            r, g, b = colorsys.hls_to_rgb(h, l, s)
            pixeles[x, y] = (round(r * 255), round(g * 255), round(b * 255), a)
    return salida


def main() -> None:
    azul = _construir_ninepatch(_escalar(DIR_UI / "Boton_Azul.png"))
    verde = _construir_ninepatch(_escalar(DIR_UI / "Boton_Verde.png"))
    naranja = _construir_ninepatch(_escalar(DIR_UI / "Boton_Naranja.png"))
    rojo = _tinte_rojo(naranja)

    salidas = {
        "Boton_Modal_Azul.png": azul,
        "Boton_Modal_Verde.png": verde,
        "Boton_Modal_Naranja.png": naranja,
        "Boton_Modal_Rojo.png": rojo,
    }
    for nombre, imagen in salidas.items():
        ruta = DIR_UI / nombre
        imagen.save(ruta)
        print(f"Guardado {ruta.relative_to(RAIZ)} ({imagen.width}x{imagen.height})")


if __name__ == "__main__":
    main()
