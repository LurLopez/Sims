"""
Power-up Llave maestra dorada con ojo en trébol, gema central cian, collar
moldurado, caña estriada y paletón dentado para PARK RUSH 3D.
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
    m_oro = lb.material("Llave_Oro", "#f59e0b", rough=0.15, metal=0.88,
                        emision="#d97706", emision_fuerza=0.35)
    m_brillo = lb.material("Llave_OroClaro", "#ffe45e", rough=0.12, metal=0.85,
                           emision="#facc15", emision_fuerza=0.50)
    m_gema = lb.material("Llave_GemaCian", "#38bdf8", rough=0.10, metal=0.30,
                         emision="#0ea5e9", emision_fuerza=2.2)

    piezas = []

    # 1. Cabeza / ojo ornamental de la llave (en Z = +0.24 m)
    piezas.append(lb.toro("Llave_Anillo", 0.24, 0.055, (0.0, 0.0, 0.24), m_oro, eje="Y", segs_mayor=24, segs_menor=10))
    # Lóbulos en trébol y gema central engastada
    for ang in (math.radians(35), math.radians(145), math.radians(90)):
        lx = math.cos(ang) * 0.24
        lz = 0.24 + math.sin(ang) * 0.24
        piezas.append(lb.esfera("Llave_Lobulo", 0.072, (lx, 0.0, lz), m_brillo, subdiv=2))
    piezas.append(lb.esfera("Llave_Gema", 0.095, (0.0, 0.0, 0.24), m_gema, escala=(1.0, 0.65, 1.0), subdiv=2))
    piezas.append(lb.toro("Llave_Engaste", 0.095, 0.022, (0.0, 0.0, 0.24), m_brillo, eje="Y", segs_mayor=16, segs_menor=6))
    for ang_r in (math.radians(45), math.radians(135), math.radians(225), math.radians(315)):
        rx = math.cos(ang_r) * 0.165
        rz = 0.24 + math.sin(ang_r) * 0.165
        piezas.append(lb.cilindro("Llave_Radio", 0.018, 0.018, 0.16, (rx, 0.0, rz), m_brillo, eje="Z", lados=8, rot=(0.0, math.pi * 0.5 - ang_r, 0.0)))

    # 2. Collarines y caña central estriada
    piezas.append(lb.toro("Llave_CollarSup", 0.078, 0.026, (0.0, 0.0, -0.02), m_brillo, eje="Z", segs_mayor=16, segs_menor=6))
    piezas.append(lb.cilindro("Llave_Cana", 0.055, 0.058, 0.48, (0.0, 0.0, -0.24), m_oro, eje="Z", lados=12, bisel_tapa=0.015))
    piezas.append(lb.esfera("Llave_Punta", 0.064, (0.0, 0.0, -0.49), m_brillo, subdiv=2))

    # 3. Paletón escalonado con dientes
    piezas.append(lb.caja("Llave_PaletonBase", (0.16, 0.068, 0.085), (0.09, 0.0, -0.40), m_oro, bisel=0.012, segs_bisel=1))
    piezas.append(lb.caja("Llave_Diente2", (0.12, 0.068, 0.075), (0.07, 0.0, -0.28), m_brillo, bisel=0.012, segs_bisel=1))
    piezas.append(lb.caja("Llave_Diente3", (0.08, 0.068, 0.050), (0.05, 0.0, -0.19), m_oro, bisel=0.010, segs_bisel=1))

    obj = lb.unir(piezas, "PowerUp_Llave")
    obj.location = (0.0, 0.0, 0.0)
    lb.suavizar_por_angulo(obj, 35.0)
    return obj


def main():
    args = lb.parsear_args_modelo("Modelos/Minijuego_Correr/powerup_llave.glb")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    obj = construir()
    lb.exportar_glb(obj, args.salida)
    if args.blend:
        lb.guardar_blend(args.blend)
    if args.render and not args.sin_render:
        lb.render_cuatro_vistas(obj, args.render, con_referencia=False)


if __name__ == "__main__":
    main()
