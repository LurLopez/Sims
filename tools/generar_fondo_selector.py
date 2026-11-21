#!/usr/bin/env python3
"""Genera el fondo desenfocado del selector de niveles de la cocina.

Toma la foto del restaurante usada en la cocina (`Fondo_Restaurante.png`),
la recorta a vertical 9:16, la desenfoca y le aplica un tinte azul nocturno.
El resultado se usa como fondo del panel cartoon de `Selector_Niveles_Arte`.

Uso:
    python3 tools/generar_fondo_selector.py
"""

from pathlib import Path

from PIL import Image, ImageEnhance, ImageFilter

RAIZ = Path(__file__).resolve().parent.parent
ORIGEN = RAIZ / "Imagenes" / "Minijuego_Cocina" / "Fondo_Restaurante.png"
DESTINO = RAIZ / "Imagenes" / "Minijuego_Cocina" / "Fondo_Restaurante_Selector.png"
ANCHO = 720
ALTO = 1280


def main() -> None:
    if not ORIGEN.exists():
        raise SystemExit(f"No existe el fondo de origen: {ORIGEN}")

    src = Image.open(ORIGEN).convert("RGB")
    # Rellenar 720x1280 recortando el centro de la foto horizontal.
    escala = ALTO / float(src.height)
    ancho_escalado = int(round(src.width * escala))
    img = src.resize((ancho_escalado, ALTO), Image.LANCZOS)
    izquierda = max(0, (ancho_escalado - ANCHO) // 2)
    img = img.crop((izquierda, 0, izquierda + ANCHO, ALTO))

    # El desenfoque oculta la pérdida de detalle al ampliar y separa el panel.
    img = img.filter(ImageFilter.GaussianBlur(13))
    img = ImageEnhance.Color(img).enhance(1.18)
    img = ImageEnhance.Brightness(img).enhance(0.92)

    tinte = Image.new("RGBA", img.size, (12, 38, 78, 74))
    img = Image.alpha_composite(img.convert("RGBA"), tinte)
    img = img.resize((ANCHO // 2, ALTO // 2), Image.LANCZOS)

    DESTINO.parent.mkdir(parents=True, exist_ok=True)
    img.save(DESTINO, optimize=True)
    print(f"Generado {DESTINO.relative_to(RAIZ)} ({img.width}x{img.height})")


if __name__ == "__main__":
    main()
