"""
Regenera todas las texturas UV y los 38 modelos .glb de Minijuego_Correr en Blender,
y valida cada .glb generado con verificar_glb.py.

Uso:
  python3 Arte_Fuente/Modelos3D/Correr/generar_todo.py [--con-render]
"""

import argparse
import os
import shutil
import subprocess
import sys

DIR_ACTUAL = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.abspath(os.path.join(DIR_ACTUAL, "..", "..", ".."))
DIR_SALIDA = os.path.join(RAIZ, "Modelos", "Minijuego_Correr")
RUTA_VERIFICADOR = "/home/lur/.gemini/config/skills/blender-modelado-3d/scripts/verificar_glb.py"

SCRIPTS_MODELOS = [
    ("vagon_metro.py", ["vagon_metro.glb"]),
    ("fuelle_vagon.py", ["fuelle_vagon.glb"]),
    ("tren_movil_extra.py", ["tren_movil_extra.glb"]),
    ("rampa_tren.py", ["rampa_tren.glb"]),
    ("vagoneta_speeder.py", ["vagoneta_speeder.glb"]),
    ("valla_baja.py", ["valla_baja.glb"]),
    ("arco_galibo.py", ["arco_galibo.glb"]),
    ("tunel_ferroviario.py", ["tunel_ferroviario.glb"]),
    ("balasto_chunk.py", ["balasto_chunk.glb"]),
    ("traviesa.py", ["traviesa.glb"]),
    ("rail_tramo.py", ["rail_tramo.glb"]),
    ("catenaria_tramo.py", ["catenaria_tramo.glb"]),
    ("anden_tramo.py", ["anden_tramo.glb"]),
    ("muro_corredor.py", ["muro_corredor.glb"]),
    ("banco_estacion.py", ["banco_estacion.glb"]),
    ("cajas_andenes.py", ["cajas_andenes.glb"]),
    ("papelera_urbana.py", ["papelera_urbana.glb"]),
    ("farola_estacion.py", ["farola_estacion.glb"]),
    ("arbol_parque.py", ["arbol_parque.glb"]),
    ("portico_catenaria.py", ["portico_catenaria.glb"]),
    ("puente_cartel.py", ["puente_cartel.glb"]),
    ("edificios.py", [f"edificio_{i}.glb" for i in range(5)]),
    ("moneda.py", ["moneda.glb"]),
    ("powerup_iman.py", ["powerup_iman.glb"]),
    ("powerup_zapatillas.py", ["powerup_zapatillas.glb"]),
    ("alas_zapatilla.py", ["alas_zapatilla.glb"]),
    ("powerup_estrella_2x.py", ["powerup_estrella_2x.glb"]),
    ("powerup_llave.py", ["powerup_llave.glb"]),
    ("powerup_caja.py", ["powerup_caja.glb"]),
    ("hoverboard.py", ["hoverboard.glb"]),
    ("jetpack.py", ["jetpack.glb"]),
    ("pogo.py", ["pogo.glb"]),
    ("guardia.py", ["guardia.glb"]),
    ("perro_policia.py", ["perro_policia.glb"]),
]


def _buscar_blender() -> str:
    for cand in ("/home/lur/.local/bin/blender", shutil.which("blender") or ""):
        if cand and os.path.isfile(cand):
            return cand
    raise FileNotFoundError("No se encontró el ejecutable de Blender.")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--con-render", action="store_true", help="Renderiza hojas 4-vistas *_preview.png")
    ap.add_argument("--blender", default="")
    args = ap.parse_args()

    blender = args.blender or _buscar_blender()
    print(f"Usando Blender: {blender}")

    # 1. Texturas UV con PIL
    subprocess.run([sys.executable, os.path.join(DIR_ACTUAL, "generar_texturas_modelos.py")], check=True, cwd=RAIZ)

    # 2. Generación de los 38 modelos .glb en Blender
    total_ok = 0
    for script, salidas in SCRIPTS_MODELOS:
        ruta_script = os.path.join(DIR_ACTUAL, script)
        extra_args = []
        if not args.con_render:
            extra_args.append("--sin-render")
        elif script != "edificios.py":
            nombre_base = script[:-3]
            extra_args.extend(["--render", os.path.join(DIR_ACTUAL, f"{nombre_base}_preview.png")])

        cmd = [blender, "--background", "--python-exit-code", "1", "--python", ruta_script, "--", *extra_args]
        print(f"-> Ejecutando {script}...")
        res = subprocess.run(cmd, cwd=RAIZ, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        if res.returncode != 0:
            print(res.stdout)
            sys.exit(res.returncode)

        for glb in salidas:
            ruta_glb = os.path.join(DIR_SALIDA, glb)
            if os.path.isfile(RUTA_VERIFICADOR):
                v = subprocess.run([sys.executable, RUTA_VERIFICADOR, ruta_glb], capture_output=True, text=True)
                if v.returncode != 0 or "RESULTADO: OK" not in v.stdout:
                    print(v.stdout)
                    print(v.stderr)
                    sys.exit(1)
            total_ok += 1
            print(f"   OK: {glb}")

    print(f"\nGeneración y validación completadas: {total_ok} modelos .glb verificados.")


if __name__ == "__main__":
    main()
