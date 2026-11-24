"""
Papelera metálica urbana de estación con pedestal, cuerpo estriado, cenefa amarilla,
capucha curva antilluvia y boca interior oscura (PARK RUSH 3D).
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
    m_cuerpo = lb.material("Papelera_Acero", "#3b495c", rough=0.44, metal=0.62)
    m_osc = lb.material("Papelera_Oscuro", "#18202c", rough=0.58, metal=0.45)
    m_acento = lb.material("Papelera_Acento", "#eab308", rough=0.38, metal=0.12)

    piezas = []

    # 1. Pedestal escalonado con pernos
    piezas.append(lb.cilindro("Papelera_Base", 0.22, 0.19, 0.06, (0.0, 0.0, 0.03), m_osc, eje="Z", lados=12, bisel_tapa=0.01))
    piezas.append(lb.cilindro("Papelera_Poste", 0.12, 0.12, 0.12, (0.0, 0.0, 0.11), m_cuerpo, eje="Z", lados=12))

    # 2. Tambor cónico con aros y 12 listones verticales en relieve
    piezas.append(lb.cilindro("Papelera_Tambor", 0.20, 0.24, 0.56, (0.0, 0.0, 0.44), m_osc, eje="Z", lados=16, bisel_tapa=0.01))
    for k in range(12):
        ang = math.tau * k / 12
        rx, ry = math.cos(ang) * 0.225, math.sin(ang) * 0.225
        piezas.append(lb.caja("Papelera_Liston", (0.032, 0.055, 0.50), (rx, ry, 0.44), m_cuerpo, bisel=0.004, segs_bisel=1, rot=(0.0, 0.0, ang)))

    # Aros superior, inferior y franja de reciclaje
    piezas.append(lb.toro("Papelera_AroInf", 0.21, 0.022, (0.0, 0.0, 0.20), m_cuerpo, eje="Z", segs_mayor=18, segs_menor=8))
    piezas.append(lb.toro("Papelera_AroSup", 0.245, 0.024, (0.0, 0.0, 0.70), m_cuerpo, eje="Z", segs_mayor=18, segs_menor=8))
    piezas.append(lb.toro("Papelera_Franja", 0.240, 0.014, (0.0, 0.0, 0.62), m_acento, eje="Z", segs_mayor=18, segs_menor=6))

    # 3. Soportes laterales y capucha cupular superior
    for sx in (-0.23, 0.23):
        piezas.append(lb.caja("Papelera_Soporte", (0.04, 0.06, 0.22), (sx, 0.0, 0.80), m_cuerpo, bisel=0.006, segs_bisel=1))
    perfil_tapa = [
        (0.255, 0.87),
        (0.255, 0.90),
        (0.210, 0.96),
        (0.110, 0.995),
        (0.0, 1.005),
    ]
    piezas.append(lb.revolucion("Papelera_Capucha", perfil_tapa, (0.0, 0.0, 0.0), m_cuerpo, lados=16))
    piezas.append(lb.cilindro("Papelera_Remate", 0.05, 0.04, 0.03, (0.0, 0.0, 1.015), m_osc, eje="Z", lados=12))

    obj = lb.unir(piezas, "Papelera_Urbana")
    obj.location = (0.0, 0.0, 0.0)
    lb.suavizar_por_angulo(obj, 35.0)
    return obj


def main():
    args = lb.parsear_args_modelo("Modelos/Minijuego_Correr/papelera_urbana.glb")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    obj = construir()
    lb.exportar_glb(obj, args.salida)
    if args.blend:
        lb.guardar_blend(args.blend)
    if args.render and not args.sin_render:
        lb.render_cuatro_vistas(obj, args.render, con_referencia=True)


if __name__ == "__main__":
    main()
