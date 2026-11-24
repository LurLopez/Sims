"""
Power-up Imán en herradura con puntas polares biseladas, abrazadera central y
anillo energético orbital para PARK RUSH 3D.
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
    m_rojo = lb.material("Iman_Rojo", "#ef4444", rough=0.22, metal=0.42,
                         emision="#dc2626", emision_fuerza=0.45)
    m_punta = lb.material("Iman_Punta", "#e2e8f0", rough=0.16, metal=0.88,
                          emision="#cbd5e1", emision_fuerza=0.25)
    m_osc = lb.material("Iman_Collar", "#1e293b", rough=0.48, metal=0.58)
    m_aura = lb.material("Iman_AuraCian", "#38bdf8", rough=0.16, metal=0.25,
                         emision="#0ea5e9", emision_fuerza=2.2)

    piezas = []
    radio = 0.34
    tubo_r = 0.112

    # 1. Arco rojo en U invertida (arco arriba en +Z, patas hacia -Z)
    pts_arco = [(-radio, 0.0, -0.04)]
    for i in range(15):
        ang = math.pi - i * (math.pi / 14.0)
        pts_arco.append((math.cos(ang) * radio, 0.0, math.sin(ang) * radio))
    pts_arco.append((radio, 0.0, -0.04))
    piezas.append(lb.tubo_ruta("Iman_Arco", pts_arco, tubo_r, m_rojo, lados=14, tapar=True))

    # 2. Puntas polares plateadas con ranura y tapón biselado
    for sx in (-radio, radio):
        piezas.append(lb.cilindro("Iman_Punta", tubo_r * 1.03, tubo_r * 1.03, 0.25,
                                  (sx, 0.0, -0.155), m_punta, eje="Z", lados=14, bisel_tapa=0.018))
        piezas.append(lb.toro("Iman_Separador", tubo_r * 1.05, 0.014,
                              (sx, 0.0, -0.035), m_osc, eje="Z", segs_mayor=14, segs_menor=6))

    # 3. Abrazadera central superior con insignia
    piezas.append(lb.toro("Iman_CollarSup", tubo_r * 1.08, 0.018, (0.0, 0.0, radio), m_osc, eje="X", segs_mayor=14, segs_menor=6))

    # 4. Halo energético inclinado
    piezas.append(lb.toro("Iman_Aura", 0.54, 0.026, (0.0, 0.0, 0.05), m_aura, eje="Z", segs_mayor=26, segs_menor=8, rot=(math.radians(26), math.radians(16), 0.0)))

    obj = lb.unir(piezas, "PowerUp_Iman")
    obj.location = (0.0, 0.0, 0.0)
    lb.suavizar_por_angulo(obj, 35.0)
    return obj


def main():
    args = lb.parsear_args_modelo("Modelos/Minijuego_Correr/powerup_iman.glb")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    obj = construir()
    lb.exportar_glb(obj, args.salida)
    if args.blend:
        lb.guardar_blend(args.blend)
    if args.render and not args.sin_render:
        lb.render_cuatro_vistas(obj, args.render, con_referencia=False)


if __name__ == "__main__":
    main()
