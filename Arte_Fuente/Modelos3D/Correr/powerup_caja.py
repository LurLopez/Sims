"""
Power-up Caja Misteriosa estilo Subway Surfers con marcos biselados, cantoneras
roblonadas, lazos luminosos, emblema '?' en relieve y halo cian (PARK RUSH 3D).
"""

import math
import os
import sys

import bpy

DIR_ACTUAL = os.path.dirname(os.path.abspath(__file__))
if DIR_ACTUAL not in sys.path:
    sys.path.insert(0, DIR_ACTUAL)

import lib_blender as lb


def _emblema_interrogacion(centro, rot_z, m_estrella):
    piezas = []
    cx, cy, cz = centro
    cr, sr = math.cos(rot_z), math.sin(rot_z)

    def _p(lx, ly, lz):
        return (cx + lx * cr - ly * sr, cy + lx * sr + ly * cr, cz + lz)

    pts = [
        (-0.07, 0.0, 0.13),
        (0.0, 0.0, 0.17),
        (0.08, 0.0, 0.13),
        (0.08, 0.0, 0.04),
        (0.0, 0.0, -0.02),
        (0.0, 0.0, -0.07),
    ]
    pts_w = [_p(x, y, z) for x, y, z in pts]
    piezas.append(lb.tubo_ruta("Interrogacion_Arco", pts_w, 0.032, m_estrella, lados=8))
    piezas.append(lb.esfera("Interrogacion_Punto", 0.036, _p(0.0, 0.0, -0.145), m_estrella, subdiv=1))
    return piezas


def construir():
    m_oro = lb.material("Caja_Oro", "#f59e0b", rough=0.22, metal=0.72,
                        emision="#d97706", emision_fuerza=0.35)
    m_estrella = lb.material("Caja_Estrella", "#ffe45e", rough=0.14, metal=0.75,
                             emision="#facc15", emision_fuerza=0.75)
    m_coral = lb.material("Caja_LazoCoral", "#fb3868", rough=0.20, metal=0.28,
                          emision="#e11d48", emision_fuerza=1.2)
    m_cian = lb.material("Caja_HaloCian", "#38bdf8", rough=0.16, metal=0.25,
                         emision="#0ea5e9", emision_fuerza=2.2)
    m_osc = lb.material("Caja_Herraje", "#1e293b", rough=0.46, metal=0.62)

    piezas = []
    tam = 0.78
    h = tam * 0.5

    # 1. Cuerpo principal rehundido + tapa superior + marcos y cantoneras
    piezas.append(lb.caja("Caja_Cuerpo", (tam, tam, tam), (0.0, 0.0, 0.0), m_oro, bisel=0.04, segs_bisel=2))
    piezas.append(lb.caja("Caja_Tapa", (tam + 0.06, tam + 0.06, 0.14), (0.0, 0.0, h - 0.05), m_coral, bisel=0.03, segs_bisel=2))

    # Cintas de regalo cruzadas
    piezas.append(lb.caja("Cinta_X", (tam + 0.07, 0.13, tam + 0.04), (0.0, 0.0, 0.0), m_cian, bisel=0.015, segs_bisel=1))
    piezas.append(lb.caja("Cinta_Y", (0.13, tam + 0.07, tam + 0.04), (0.0, 0.0, 0.0), m_coral, bisel=0.015, segs_bisel=1))

    # 8 Cantoneras metálicas en esquinas
    for sx in (-1, 1):
        for sy in (-1, 1):
            for sz in (-1, 1):
                piezas.append(lb.caja("Caja_Cantonera", (0.14, 0.14, 0.14), (sx * (h - 0.04), sy * (h - 0.04), sz * (h - 0.04)), m_osc, bisel=0.015, segs_bisel=1))

    # Lazo superior / broche estrella
    for side in (-1, 1):
        piezas.append(lb.toro("Caja_Lazo", 0.12, 0.032, (side * 0.13, 0.0, h + 0.09), m_coral, eje="Y", segs_mayor=16, segs_menor=6, rot=(0.0, side * math.radians(25), 0.0)))
    piezas.append(lb.estrella_3d("Caja_Broche", 0.16, 0.075, 0.09, (0.0, 0.0, h + 0.08), m_estrella, rot=(math.radians(90), 0.0, 0.0)))

    # 2. Signos '?' en las 4 caras laterales
    for ang_z, pos_c in ((0.0, (0.0, -h - 0.03, -0.02)), (math.pi, (0.0, h + 0.03, -0.02)),
                         (math.pi * 0.5, (h + 0.03, 0.0, -0.02)), (-math.pi * 0.5, (-h - 0.03, 0.0, -0.02))):
        piezas.extend(_emblema_interrogacion(pos_c, ang_z, m_estrella))

    # 3. Halo cian inclinado
    piezas.append(lb.toro("Caja_Halo", 0.68, 0.028, (0.0, 0.0, 0.0), m_cian, eje="Z", segs_mayor=26, segs_menor=8, rot=(math.radians(66), math.radians(16), 0.0)))

    obj = lb.unir(piezas, "PowerUp_Caja")
    obj.location = (0.0, 0.0, 0.0)
    lb.suavizar_por_angulo(obj, 35.0)
    return obj


def main():
    args = lb.parsear_args_modelo("Modelos/Minijuego_Correr/powerup_caja.glb")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    obj = construir()
    lb.exportar_glb(obj, args.salida)
    if args.blend:
        lb.guardar_blend(args.blend)
    if args.render and not args.sin_render:
        lb.render_cuatro_vistas(obj, args.render, con_referencia=False)


if __name__ == "__main__":
    main()
