"""
Fuelle flexible de intercirculación entre vagones del tren largo (PARK RUSH 3D).
"""

import math
import os
import sys

import bpy

DIR_ACTUAL = os.path.dirname(os.path.abspath(__file__))
if DIR_ACTUAL not in sys.path:
    sys.path.insert(0, DIR_ACTUAL)

import lib_blender as lb


def construir():
    m_goma = lb.material("Fuelle_Goma", "#222936", rough=0.88, metal=0.05)
    m_metal = lb.material("Fuelle_Metal", "#7c8999", rough=0.45, metal=0.65)
    m_amarillo = lb.material("Fuelle_Aviso", "#facc15", rough=0.38, metal=0.10)

    piezas = []

    # 7 pliegues acordeón del fuelle (Z = 0.56..2.94, nunca > 3.05 m)
    perfil_ext = [
        (-0.88, 0.62), (-0.94, 0.78), (-0.94, 2.70), (-0.82, 2.86),
        (-0.56, 2.94), (0.56, 2.94), (0.82, 2.86), (0.94, 2.70),
        (0.94, 0.78), (0.88, 0.62),
    ]
    n_pliegues = 7
    largo = 0.88
    for i in range(n_pliegues):
        yc = -largo * 0.5 + (i + 0.5) * (largo / n_pliegues)
        escala = 1.0 if i % 2 == 0 else 0.92
        perfil_p = [(x * escala, z) for (x, z) in perfil_ext]
        piezas.append(lb.extruir_perfil(
            f"Fuelle_Pliegue_{i}", perfil_p, largo / n_pliegues * 0.86,
            m_goma, segs_y=1, centro_y=yc, bisel=0.010, segs_bisel=1,
        ))

    # Marcos metálicos extremos y puente pasarela inferior con franja amarilla
    for sy in (-0.42, 0.42):
        piezas.append(lb.caja("Fuelle_Marco", (1.92, 0.06, 2.34), (0.0, sy, 1.78), m_metal, bisel=0.010, segs_bisel=1))
    piezas.append(lb.caja("Fuelle_Puente", (1.76, 0.92, 0.10), (0.0, 0.0, 0.54), m_metal, bisel=0.010, segs_bisel=1))
    piezas.append(lb.caja("Fuelle_Franja", (1.42, 0.24, 0.05), (0.0, 0.0, 0.58), m_amarillo, bisel=0.008, segs_bisel=1))

    # Barra de enganche y cadenas de seguridad
    piezas.append(lb.caja("Acoplamiento_Barra", (0.28, 0.96, 0.14), (0.0, 0.0, 0.36), m_metal, bisel=0.012, segs_bisel=1))
    for lx in (-0.46, 0.46):
        pts = [(lx, -0.45, 0.46), (lx * 0.95, 0.0, 0.34), (lx, 0.45, 0.46)]
        piezas.append(lb.tubo_ruta("Cadena_Seguridad", pts, 0.018, m_metal, lados=8))

    obj = lb.unir(piezas, "Fuelle_Vagon")
    obj.location = (0.0, 0.0, 0.0)
    lb.suavizar_por_angulo(obj, 35.0)
    return obj


def main():
    args = lb.parsear_args_modelo("Modelos/Minijuego_Correr/fuelle_vagon.glb")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    obj = construir()
    lb.exportar_glb(obj, args.salida)
    if args.blend:
        lb.guardar_blend(args.blend)
    if args.render and not args.sin_render:
        lb.render_cuatro_vistas(obj, args.render, con_referencia=False)


if __name__ == "__main__":
    main()
