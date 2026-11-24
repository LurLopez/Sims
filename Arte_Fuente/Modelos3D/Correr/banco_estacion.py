"""
Banco clásico de estación / parque con listones curvos de madera y bastidor
de hierro fundido con reposabrazos en voluta (PARK RUSH 3D).
Origen en el centro de la base (Z = 0). Frente mirando hacia -X.
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
    m_madera = lb.material("Banco_Madera", "#b56c3b", rough=0.74, metal=0.04)
    m_madera_clara = lb.material("Banco_MaderaClara", "#cf834c", rough=0.72, metal=0.04)
    m_hierro = lb.material("Banco_Hierro", "#1f2937", rough=0.48, metal=0.62)
    m_perno = lb.material("Banco_Perno", "#94a3b8", rough=0.36, metal=0.72)

    piezas = []
    largo = 2.34

    # 1. Listones ergonómicos del asiento (4) y del respaldo (3)
    asiento_perfil = [
        (-0.22, 0.44, 0.00),
        (-0.08, 0.43, -0.02),
        (0.06, 0.43, 0.02),
        (0.20, 0.45, 0.08),
    ]
    for i, (px, pz, tilt) in enumerate(asiento_perfil):
        mat_l = m_madera_clara if i % 2 == 0 else m_madera
        piezas.append(lb.caja(f"Asiento_Liston_{i}", (0.115, largo, 0.036), (px, 0.0, pz), mat_l, bisel=0.006, segs_bisel=1, rot=(0.0, tilt, 0.0)))

    respaldo_perfil = [
        (0.243, 0.58),
        (0.273, 0.72),
        (0.302, 0.86),
    ]
    for i, (px, pz) in enumerate(respaldo_perfil):
        mat_l = m_madera if i % 2 == 0 else m_madera_clara
        piezas.append(lb.caja(f"Respaldo_Liston_{i}", (0.038, largo, 0.11), (px, 0.0, pz), mat_l, bisel=0.006, segs_bisel=1, rot=(0.0, math.radians(12), 0.0)))

    # 2. Tres bastidores laterales y central de hierro fundido con reposabrazos curvos
    for iy, fy in enumerate((-1.02, 0.0, 1.02)):
        es_extremo = (iy != 1)
        # Patas delantera y trasera + travesaño bajo asiento
        piezas.append(lb.caja("Marco_Base", (0.56, 0.065, 0.045), (0.02, fy, 0.40), m_hierro, bisel=0.006, segs_bisel=1))
        piezas.append(lb.caja("Pata_Del", (0.065, 0.065, 0.40), (-0.20, fy, 0.20), m_hierro, bisel=0.008, segs_bisel=1, rot=(0.0, math.radians(8), 0.0)))
        piezas.append(lb.caja("Pata_Tras", (0.065, 0.065, 0.42), (0.24, fy, 0.21), m_hierro, bisel=0.008, segs_bisel=1, rot=(0.0, math.radians(-8), 0.0)))
        piezas.append(lb.caja("Montante_Resp", (0.055, 0.055, 0.50), (0.295, fy, 0.65), m_hierro, bisel=0.006, segs_bisel=1, rot=(0.0, math.radians(12), 0.0)))
        # Zapatas en suelo
        for sx in (-0.23, 0.27):
            piezas.append(lb.cilindro("Pata_Zapata", 0.055, 0.045, 0.03, (sx, fy, 0.015), m_hierro, eje="Z", lados=8))

        if es_extremo:
            # Reposabrazos curvado en tubo + voluta decorativa
            pts_brazo = [
                (0.295, fy, 0.65),
                (0.10, fy, 0.64),
                (-0.14, fy, 0.61),
                (-0.22, fy, 0.52),
                (-0.19, fy, 0.42),
            ]
            piezas.append(lb.tubo_ruta("Reposabrazos", pts_brazo, 0.024, m_hierro, lados=8, catmull_subdiv=3))
            # Remache ornamental en extremo
            for rx, rz in ((-0.20, 0.46), (0.243, 0.58), (0.273, 0.72), (0.302, 0.86)):
                piezas.append(lb.esfera("Perno_Banco", 0.014, (rx - 0.018, fy, rz), m_perno, subdiv=1))

    # Tirante inferior longitudinal
    piezas.append(lb.cilindro("Tirante_Inf", 0.020, 0.020, 2.04, (0.02, 0.0, 0.18), m_hierro, eje="Y", lados=8))

    obj = lb.unir(piezas, "Banco_Estacion")
    obj.location = (0.0, 0.0, 0.0)
    lb.suavizar_por_angulo(obj, 35.0)
    return obj


def main():
    args = lb.parsear_args_modelo("Modelos/Minijuego_Correr/banco_estacion.glb")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    obj = construir()
    lb.exportar_glb(obj, args.salida)
    if args.blend:
        lb.guardar_blend(args.blend)
    if args.render and not args.sin_render:
        lb.render_cuatro_vistas(obj, args.render, con_referencia=True)


if __name__ == "__main__":
    main()
