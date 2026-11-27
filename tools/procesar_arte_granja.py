#!/usr/bin/env python3
"""Procesa el arte de La Granja: quita el magenta de los sprites y prepara
el fondo horizontal y el banner del hub.

Uso:
  python3 tools/procesar_arte_granja.py
"""
from pathlib import Path
from PIL import Image

from procesar_iconos_tienda import recortar_magenta, limpiar_polvo, centrar_cuadrado

ROOT = Path(__file__).resolve().parent.parent
ORIGEN = ROOT / "Arte_Fuente" / "Granja" / "Fuente"
DESTINO = ROOT / "Imagenes" / "Granja"

SPRITES = [
    "Gallina",
    "Vaca",
    "Molino",
    "Panaderia",
    "Queseria",
    "Trigo",
    "Zanahoria",
    "Maiz",
    "Espantapajaros",
]


def _fuente(nombre: str) -> Path:
    for ext in (".png", ".jpg", ".jpeg", ".webp"):
        ruta = ORIGEN / (nombre + ext)
        if ruta.exists():
            return ruta
    raise FileNotFoundError(nombre)


def main() -> None:
    DESTINO.mkdir(parents=True, exist_ok=True)

    for nombre in SPRITES:
        original = Image.open(_fuente(nombre))
        recortado = limpiar_polvo(recortar_magenta(original.convert("RGB")))
        icono = centrar_cuadrado(recortado, 512, 0.04)
        salida = DESTINO / (nombre + ".png")
        icono.save(salida, optimize=True)
        print(f"{nombre}: {salida.relative_to(ROOT)}")

    fondo = Image.open(_fuente("Fondo_Granja")).convert("RGB")
    # Fondo 16:9 exacto para la pantalla horizontal.
    ancho, alto = fondo.size
    objetivo = 1280.0 / 720.0
    if ancho / alto > objetivo:
        nuevo_ancho = int(round(alto * objetivo))
        x0 = (ancho - nuevo_ancho) // 2
        fondo = fondo.crop((x0, 0, x0 + nuevo_ancho, alto))
    else:
        nuevo_alto = int(round(ancho / objetivo))
        y0 = max(0, (alto - nuevo_alto) // 2)
        fondo = fondo.crop((0, y0, ancho, y0 + nuevo_alto))
    fondo = fondo.resize((1280, 720), Image.LANCZOS)
    fondo.save(DESTINO / "Fondo_Granja.png", optimize=True)
    print("Fondo_Granja.png")

    # Banner del hub: usa Banner_Granja_Fuente si existe (escena panorámica),
    # o en su defecto la banda superior de Fondo_Granja.
    fuente_banner = ORIGEN / "Banner_Granja_Fuente.png"
    banner = Image.open(fuente_banner if fuente_banner.exists() else _fuente("Fondo_Granja")).convert("RGB")
    ancho, alto = banner.size
    banda_alto = min(alto, int(ancho * 0.30))
    banner = banner.crop((0, 0, ancho, banda_alto))
    banner = banner.resize((1280, 360), Image.LANCZOS)
    banner.save(DESTINO / "Banner_Granja.png", optimize=True)
    print("Banner_Granja.png")


if __name__ == "__main__":
    main()
