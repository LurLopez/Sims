"""
Traviesa de madera ferroviaria biselada con placas de asiento de acero y clips Pandrol.
Pensada para MultiMesh (96 por chunk): ~180 triángulos, 2 materiales.
"""

import os
import sys

import bpy

DIR_ACTUAL = os.path.dirname(os.path.abspath(__file__))
if DIR_ACTUAL not in sys.path:
    sys.path.insert(0, DIR_ACTUAL)

import lib_blender as lb

RAIZ_PROYECTO = os.path.abspath(os.path.join(DIR_ACTUAL, "..", "..", ".."))
DIR_TEX = os.path.join(RAIZ_PROYECTO, "Imagenes", "Minijuego_Correr", "Texturas3D")


def construir():
    tex_alb = os.path.join(DIR_TEX, "traviesa_albedo.png")
    tex_nrm = os.path.join(DIR_TEX, "traviesa_normal.png")
    m_madera = lb.material(
        "Traviesa_Madera", "#ffffff", rough=0.86, metal=0.02,
        tex_albedo=tex_alb if os.path.exists(tex_alb) else None,
        tex_normal=tex_nrm if os.path.exists(tex_nrm) else None,
        normal_fuerza=0.85,
    )
    m_placa = lb.material("Traviesa_Placa", "#374151", rough=0.48, metal=0.65)

    piezas = []
    # Madero biselado (Z = 0.00..0.10 m)
    piezas.append(lb.caja("Traviesa_Madero", (2.16, 0.28, 0.10), (0.0, 0.0, 0.05), m_madera, bisel=0.015, segs_bisel=1))

    # Placas de asiento metálicas y clips de sujeción bajo los dos raíles (±0.72 m)
    for rx in (-0.72, 0.72):
        piezas.append(lb.caja("Traviesa_Placa", (0.24, 0.27, 0.020), (rx, 0.0, 0.106), m_placa, bisel=0.004, segs_bisel=1))
        for cx in (-0.085, 0.085):
            piezas.append(lb.caja("Traviesa_Clip", (0.032, 0.075, 0.022), (rx + cx, 0.0, 0.122), m_placa))

    obj = lb.unir(piezas, "Traviesa")
    obj.location = (0.0, 0.0, 0.0)
    lb.suavizar_por_angulo(obj, 35.0)
    return obj


def main():
    args = lb.parsear_args_modelo("Modelos/Minijuego_Correr/traviesa.glb")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    obj = construir()
    lb.exportar_glb(obj, args.salida)
    if args.blend:
        lb.guardar_blend(args.blend)
    if args.render and not args.sin_render:
        lb.render_cuatro_vistas(obj, args.render, con_referencia=False)


if __name__ == "__main__":
    main()
