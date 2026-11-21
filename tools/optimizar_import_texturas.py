#!/usr/bin/env python3
"""Marca las texturas de runtime como VRAM comprimidas (ETC2/ASTC en Android).

Godot guarda por defecto los PNG en lossless (compress/mode=0): ocupan 4 bytes
por píxel en RAM/VRAM. En un móvil modesto, las ~150 texturas de la cocina y
las viñetas del cómic suman más de 90 MB descomprimidas. Con compress/mode=2
se codifican una sola vez al importar y se quedan en ~1/8 de memoria.

Uso:
    python3 tools/optimizar_import_texturas.py
    godot --headless --path . --import

No toca Arte_Fuente (material de trabajo) ni los SVG (iconos vectoriales).
"""
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
# Solo las texturas grandes que se cargan en pantalla completa o en el
# minijuego. Los iconos pequeños y los assets de marca se quedan en lossless:
# en PNG plano pesan menos que un ASTC de bloque fijo.
CARPETAS = [
    RAIZ / "Imagenes" / "Minijuego_Cocina",
    RAIZ / "Imagenes" / "UI" / "Comic",
]


def optimizar(import_file: Path) -> bool:
    lineas = import_file.read_text(encoding="utf-8").splitlines()
    cambios = False
    salida = []
    for linea in lineas:
        if linea.startswith("compress/mode=") and linea != "compress/mode=2":
            salida.append("compress/mode=2")
            cambios = True
        elif linea.startswith("compress/high_quality=") and linea != "compress/high_quality=false":
            salida.append("compress/high_quality=false")
            cambios = True
        else:
            salida.append(linea)
    if cambios:
        import_file.write_text("\n".join(salida) + "\n", encoding="utf-8")
    return cambios


def main() -> None:
    total = 0
    cambiados = 0
    for carpeta in CARPETAS:
        for import_file in carpeta.rglob("*.png.import"):
            total += 1
            if optimizar(import_file):
                cambiados += 1
    print(f"Texturas PNG revisadas: {total}")
    print(f"Marcadas como VRAM comprimida: {cambiados}")
    print("Ahora ejecuta: godot --headless --path . --import")


if __name__ == "__main__":
    main()
