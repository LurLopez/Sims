"""
Moneda dorada estilizada estilo Subway Surfers para PARK RUSH 3D.
Canto estriado, doble cara rehundida con aro biselado y estrella 3D en relieve.
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
    m_oro = lb.material("Moneda_Oro", "#f59e0b", rough=0.16, metal=0.88,
                        emision="#d97706", emision_fuerza=0.25)
    m_estrella = lb.material("Moneda_Estrella", "#ffe45e", rough=0.12, metal=0.80,
                             emision="#facc15", emision_fuerza=0.45)

    piezas = []

    # 1. Disco torneado con bisel en canto y caras rehundidas (eje Y = normal de la moneda)
    # Perfil (r, z) en torno a Z y luego rotado 90° en X para mirar a ±Y
    perfil_disco = [
        (0.0, 0.044),
        (0.32, 0.044),
        (0.35, 0.072),
        (0.42, 0.072),
        (0.445, 0.052),
        (0.445, -0.052),
        (0.42, -0.072),
        (0.35, -0.072),
        (0.32, -0.044),
        (0.0, -0.044),
    ]
    piezas.append(lb.revolucion("Moneda_Disco", perfil_disco, (0.0, 0.0, 0.0), m_oro, lados=24, rot=(math.radians(90), 0.0, 0.0)))

    # 2. Estriado sutil del canto (16 muescas alrededor del borde)
    for k in range(16):
        ang = math.tau * k / 16
        px = math.cos(ang) * 0.444
        pz = math.sin(ang) * 0.444
        piezas.append(lb.caja("Moneda_Estria", (0.022, 0.088, 0.024), (px, 0.0, pz), m_oro, rot=(0.0, -ang, 0.0)))

    # 3. Estrella 3D en relieve por ambas caras
    piezas.append(lb.estrella_3d("Moneda_Estrella", 0.255, 0.112, 0.145, (0.0, 0.0, 0.0), m_estrella, puntas=5, bisel_cara=0.42))

    obj = lb.unir(piezas, "Moneda")
    obj.location = (0.0, 0.0, 0.0)
    lb.suavizar_por_angulo(obj, 35.0)
    return obj


def main():
    args = lb.parsear_args_modelo("Modelos/Minijuego_Correr/moneda.glb")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    obj = construir()
    lb.exportar_glb(obj, args.salida)
    if args.blend:
        lb.guardar_blend(args.blend)
    if args.render and not args.sin_render:
        lb.render_cuatro_vistas(obj, args.render, con_referencia=False)


if __name__ == "__main__":
    main()
