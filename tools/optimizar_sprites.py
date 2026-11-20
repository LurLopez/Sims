#!/usr/bin/env python3
"""Copy full-resolution masters out of res:// and downscale the runtime PNGs."""
import shutil
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "Imagenes" / "Minijuego_Cocina"
MASTERS = ROOT / "Arte_Fuente" / "Minijuego_Cocina" / "Sprites_Full"

LIMITS = {
    "Chef": 900,
    "Chef/Poses": 650,
    "Clientes": 320,
    "Comida/Platos": 320,
    "Comida/Ingredientes": 260,
    "Comida/Extras": 320,
    "Estaciones": 420,
    "Mostrador": 800,
    "Emplatado": 300,
    "UI": 300,
    "Decoracion": 420,
    "Efectos": 280,
}
SPECIAL = {
    "Mostrador/Frente_Mostrador.png": (1600, 400),
    "Mostrador/Encimera_Larga.png": (1600, 400),
    "Fondo_Restaurante.png": (1280, 720),
}


def limit_for(rel: Path) -> tuple:
    key = str(rel).replace("\\", "/")
    if key in SPECIAL:
        return SPECIAL[key]
    parts = rel.parts
    if len(parts) >= 2:
        sub = f"{parts[0]}/{parts[1]}"
        if sub in LIMITS:
            return (LIMITS[sub], LIMITS[sub])
    if parts[0] in LIMITS:
        n = LIMITS[parts[0]]
        return (n, n)
    return (0, 0)


def main():
    before = sum(p.stat().st_size for p in SRC.rglob("*.png"))
    if not MASTERS.exists():
        for p in SRC.rglob("*.png"):
            dst = MASTERS / p.relative_to(SRC)
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(p, dst)
        print("masters:", MASTERS)
    for p in sorted(SRC.rglob("*.png")):
        rel = p.relative_to(SRC)
        max_w, max_h = limit_for(rel)
        if max_w <= 0:
            continue
        im = Image.open(p).convert("RGBA")
        if rel.name == "Fondo_Restaurante.png":
            im = im.resize((max_w, max_h), Image.LANCZOS)
        else:
            k = min(max_w / im.width, max_h / im.height, 1.0)
            if k < 1.0:
                im = im.resize((max(1, round(im.width * k)), max(1, round(im.height * k))), Image.LANCZOS)
        im.save(p, optimize=True)
    after = sum(p.stat().st_size for p in SRC.rglob("*.png"))
    print(f"{before/1e6:.2f} MB -> {after/1e6:.2f} MB")


if __name__ == "__main__":
    main()
