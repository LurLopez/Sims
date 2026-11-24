"""
Power-up Multiplicador 2x: estrella 3D biselada de oro con emblema '2X' y anillo cian.
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
    m_oro = lb.material("Estrella2X_Oro", "#f59e0b", rough=0.14, metal=0.88,
                        emision="#d97706", emision_fuerza=0.35)
    m_estrella = lb.material("Estrella2X_Brillo", "#ffe45e", rough=0.12, metal=0.78,
                             emision="#facc15", emision_fuerza=0.55)
    m_cian = lb.material("Estrella2X_HaloCian", "#38bdf8", rough=0.16, metal=0.25,
                         emision="#0ea5e9", emision_fuerza=2.4)
    m_osc = lb.material("Estrella2X_Centro", "#1e293b", rough=0.35, metal=0.45)

    piezas = []

    # 1. Estrella principal biselada (grosor menor que el medallón para evitar z-fighting/cortes)
    piezas.append(lb.estrella_3d("Estrella_Base", 0.50, 0.225, 0.14, (0.0, 0.0, 0.0), m_oro, puntas=5, bisel_cara=0.45))
    # Medallón central sobreelevado con emblema '2X' legible por ambas caras
    piezas.append(lb.cilindro("Medallon_Fondo", 0.185, 0.185, 0.20, (0.0, 0.0, 0.0), m_osc, eje="Y", lados=20, bisel_tapa=0.015))
    for sy_a in (-0.095, 0.095):
        piezas.append(lb.toro("Medallon_Aro", 0.182, 0.018, (0.0, sy_a, 0.0), m_estrella, eje="Y", segs_mayor=20, segs_menor=6))

    # '2X' legible de frente en ambas caras al girar el power-up
    for sy_f, s_x in ((-0.112, 1.0), (0.112, -1.0)):
        # 'X' en lado derecho relativo
        for ang in (math.radians(36), math.radians(-36)):
            piezas.append(lb.caja("Emblema_X", (0.026, 0.022, 0.13), (s_x * 0.068, sy_f, 0.0), m_estrella, rot=(0.0, ang, 0.0)))
        # '2' bloque arcade nítido en lado izquierdo relativo
        x2 = s_x * -0.062
        piezas.append(lb.caja("Emblema_2T", (0.088, 0.022, 0.022), (x2, sy_f, 0.048), m_estrella))
        piezas.append(lb.caja("Emblema_2R", (0.024, 0.022, 0.056), (x2 + s_x * 0.032, sy_f, 0.024), m_estrella))
        piezas.append(lb.caja("Emblema_2M", (0.088, 0.022, 0.022), (x2, sy_f, 0.0), m_estrella))
        piezas.append(lb.caja("Emblema_2L", (0.024, 0.022, 0.056), (x2 - s_x * 0.032, sy_f, -0.024), m_estrella))
        piezas.append(lb.caja("Emblema_2B", (0.088, 0.022, 0.022), (x2, sy_f, -0.048), m_estrella))

    # 2. Anillo orbital cian inclinado
    piezas.append(lb.toro("Estrella_Halo", 0.59, 0.030, (0.0, 0.0, 0.0), m_cian, eje="Z", segs_mayor=26, segs_menor=8, rot=(math.radians(68), math.radians(14), 0.0)))

    obj = lb.unir(piezas, "PowerUp_Estrella2X")
    obj.location = (0.0, 0.0, 0.0)
    lb.suavizar_por_angulo(obj, 35.0)
    return obj


def main():
    args = lb.parsear_args_modelo("Modelos/Minijuego_Correr/powerup_estrella_2x.glb")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    obj = construir()
    lb.exportar_glb(obj, args.salida)
    if args.blend:
        lb.guardar_blend(args.blend)
    if args.render and not args.sin_render:
        lb.render_cuatro_vistas(obj, args.render, con_referencia=False)


if __name__ == "__main__":
    main()
