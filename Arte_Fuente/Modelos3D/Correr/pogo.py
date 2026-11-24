"""
Pogo-Cohete con muelle helicoidal 3D, estribos estriados, manillar curvo y
tobera propulsora en la base (PARK RUSH 3D).
Origen Z = 0 en los estribos (donde apoyan los pies del Sim).
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
    m_chasis = lb.material("Pogo_Chasis", "#1e293b", rough=0.45, metal=0.58)
    m_cromo = lb.material("Pogo_Cromo", "#cbd5e1", rough=0.22, metal=0.85)
    m_cian = lb.material("Pogo_Cian", "#38bdf8", rough=0.20, metal=0.28,
                         emision="#0ea5e9", emision_fuerza=1.8)
    m_coral = lb.material("Pogo_Coral", "#fb3868", rough=0.22, metal=0.25,
                          emision="#e11d48", emision_fuerza=1.6)
    m_oro = lb.material("Pogo_Insignia", "#ffe45e", rough=0.14, metal=0.78,
                        emision="#facc15", emision_fuerza=0.6)

    piezas = []

    # 1. Vástago inferior, muelle helicoidal 3D real y pie propulsor cohete (Z = -0.94..0.0)
    piezas.append(lb.cilindro("Pogo_Piston", 0.036, 0.044, 0.90, (0.0, 0.0, -0.45), m_cromo, eje="Z", lados=12))
    piezas.append(lb.cilindro("Pogo_Camisa", 0.064, 0.068, 0.34, (0.0, 0.0, -0.22), m_chasis, eje="Z", lados=12, bisel_tapa=0.01))
    piezas.append(lb.muelle_helicoidal("Pogo_Muelle", 0.088, 0.022, 0.36, 5.0, (0.0, 0.0, -0.56), m_coral, segs_por_vuelta=14, segs_alambre=7))
    # Tobera cohete inferior con aletas y núcleo brillante
    piezas.append(lb.cilindro("Pogo_BotaCohete", 0.135, 0.085, 0.18, (0.0, 0.0, -0.84), m_coral, eje="Z", lados=14, bisel_tapa=0.012))
    piezas.append(lb.esfera("Pogo_NucleoLuz", 0.090, (0.0, 0.0, -0.94), m_cian, escala=(1.0, 1.0, 0.75), subdiv=2))
    for k in range(3):
        ang = k * (math.tau / 3.0)
        piezas.append(lb.caja("Pogo_Aleta", (0.022, 0.11, 0.16), (math.cos(ang) * 0.12, math.sin(ang) * 0.12, -0.82), m_chasis, rot=(0.0, 0.0, ang)))

    # 2. Puente de estribos a Z = 0.0 (pies del Sim)
    piezas.append(lb.caja("Pogo_Puente", (0.48, 0.10, 0.06), (0.0, 0.0, 0.01), m_cian, bisel=0.012, segs_bisel=1))
    for side in (-1.0, 1.0):
        piezas.append(lb.caja("Pogo_Estribo", (0.14, 0.30, 0.055), (side * 0.21, 0.02, 0.02), m_chasis, bisel=0.010, segs_bisel=1))
        for ry in (-0.10, -0.03, 0.04, 0.11):
            piezas.append(lb.caja("Pogo_EstriaPie", (0.12, 0.022, 0.016), (side * 0.21, ry, 0.052), m_cromo))

    # 3. Cuello adelantado (+Y en Blender = -Z delante del torso en Godot) + manillar en T + insignia
    pts_cuello = [(0.0, 0.0, 0.02), (0.0, 0.18, 0.24), (0.0, 0.24, 0.62)]
    piezas.append(lb.tubo_ruta("Pogo_Cuello", pts_cuello, 0.036, m_cromo, lados=10, catmull_subdiv=3))
    piezas.append(lb.cilindro("Pogo_Manillar", 0.026, 0.026, 0.50, (0.0, 0.24, 0.62), m_chasis, eje="X", lados=10))
    for side in (-1.0, 1.0):
        piezas.append(lb.cilindro("Pogo_Puno", 0.038, 0.036, 0.14, (side * 0.22, 0.24, 0.62), m_coral, eje="X", lados=10, bisel_tapa=0.008))
    piezas.append(lb.estrella_3d("Pogo_Estrella", 0.14, 0.065, 0.06, (0.0, 0.28, 0.62), m_oro))

    obj = lb.unir(piezas, "Pogo_Cohete")
    obj.location = (0.0, 0.0, 0.0)
    lb.suavizar_por_angulo(obj, 35.0)
    return obj


def main():
    args = lb.parsear_args_modelo("Modelos/Minijuego_Correr/pogo.glb")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    obj = construir()
    lb.exportar_glb(obj, args.salida)
    if args.blend:
        lb.guardar_blend(args.blend)
    if args.render and not args.sin_render:
        lb.render_cuatro_vistas(obj, args.render, con_referencia=False)


if __name__ == "__main__":
    main()
