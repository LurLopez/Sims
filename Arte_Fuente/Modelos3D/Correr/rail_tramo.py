"""
Tramo de raíl ferroviario Vignoles de 32 m con perfil en I, cabeza pulida y eclisas atornilladas.
Subdividido en 16 tramos a lo largo de Y para la curvatura del horizonte.
"""

import os
import sys

import bpy

DIR_ACTUAL = os.path.dirname(os.path.abspath(__file__))
if DIR_ACTUAL not in sys.path:
    sys.path.insert(0, DIR_ACTUAL)

import lib_blender as lb

LARGO = 32.0


def construir():
    m_cabeza = lb.material("Rail_Cabeza", "#a8b5c4", rough=0.30, metal=0.68)
    m_base = lb.material("Rail_Base", "#46403c", rough=0.68, metal=0.45)

    piezas = []

    # Patín + alma del raíl Vignoles (Z = 0.00..0.085)
    perfil_base = [
        (-0.078, 0.000),
        (0.078, 0.000),
        (0.075, 0.018),
        (0.024, 0.028),
        (0.022, 0.076),
        (-0.022, 0.076),
        (-0.024, 0.028),
        (-0.075, 0.018),
    ]
    piezas.append(lb.extruir_perfil("Rail_PerfilBase", perfil_base, LARGO, m_base, segs_y=16))

    # Cabeza redondeada de acero pulido (Z = 0.076..0.118)
    perfil_cabeza = [
        (-0.044, 0.076),
        (0.044, 0.076),
        (0.046, 0.104),
        (0.032, 0.118),
        (-0.032, 0.118),
        (-0.046, 0.104),
    ]
    piezas.append(lb.extruir_perfil("Rail_PerfilCabeza", perfil_cabeza, LARGO, m_cabeza, segs_y=16))

    # Eclisas de unión atornilladas cada 8 m en el alma del raíl
    for ey in (-12.0, -4.0, 4.0, 12.0):
        for sx in (-0.032, 0.032):
            piezas.append(lb.caja("Rail_Eclisa", (0.020, 0.44, 0.042), (sx, ey, 0.052), m_base))
            for by in (-0.14, -0.05, 0.05, 0.14):
                piezas.append(lb.cilindro("Rail_Perno", 0.012, 0.012, 0.018, (sx + (0.010 if sx > 0 else -0.010), ey + by, 0.052), m_cabeza, eje="X", lados=6))

    obj = lb.unir(piezas, "Rail_Tramo")
    obj.location = (0.0, 0.0, 0.0)
    lb.suavizar_por_angulo(obj, 35.0)
    return obj


def main():
    args = lb.parsear_args_modelo("Modelos/Minijuego_Correr/rail_tramo.glb")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    obj = construir()
    lb.exportar_glb(obj, args.salida)
    if args.blend:
        lb.guardar_blend(args.blend)
    if args.render and not args.sin_render:
        lb.render_cuatro_vistas(obj, args.render, con_referencia=False)


if __name__ == "__main__":
    main()
