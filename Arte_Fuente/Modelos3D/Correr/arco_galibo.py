"""
Pórtico alto de gálibo ferroviario fiel a Subway Surfers (`blocker_roll_0`) para rodar o supersaltar.
Base pesada con plataforma en vía, altas columnas en A rojo ladrillo arriostradas hacia atrás (+Y),
cartel pizarra con flechas descendentes en relieve y hueco libre inferior >= 1.32 m.
"""

import math
import os
import subprocess
import sys

import bpy
from mathutils import Vector

DIR_ACTUAL = os.path.dirname(os.path.abspath(__file__))
if DIR_ACTUAL not in sys.path:
    sys.path.insert(0, DIR_ACTUAL)

import lib_blender as lb

RAIZ_PROYECTO = os.path.abspath(os.path.join(DIR_ACTUAL, "..", "..", ".."))
DIR_TEX = os.path.join(RAIZ_PROYECTO, "Imagenes", "Minijuego_Correr", "Texturas3D")


def _asegurar_tex():
    p = os.path.join(DIR_TEX, "arco_bl_albedo.png")
    if not os.path.exists(p):
        subprocess.run(["python3", os.path.join(DIR_ACTUAL, "generar_texturas_modelos.py")], check=True)
    return p


def construir():
    tex_arco = _asegurar_tex()
    m_cartel = lb.material("Arco_Cartel", "#ffffff", rough=0.38, metal=0.12, tex_albedo=tex_arco)
    m_rojo = lb.material("Arco_Rojo", "#a82d24", rough=0.48, metal=0.22)
    m_acero_osc = lb.material("Arco_AceroOsc", "#2c292b", rough=0.58, metal=0.45)
    m_amarillo = lb.material("Arco_Amarillo", "#b8e044", rough=0.36, metal=0.10,
                             emision="#a3e635", emision_fuerza=0.45)
    m_piloto = lb.material("Arco_PilotoRojo", "#ff4d4d", rough=0.14, metal=0.0,
                           emision="#ef4444", emision_fuerza=4.8)

    piezas = []

    # 1. Plataforma pesada de base sobre la vía + zapatas traseras
    piezas.append(lb.caja("Arco_Plataforma", (2.38, 1.48, 0.14), (0.0, 0.22, 0.07), m_acero_osc, bisel=0.020, segs_bisel=1))
    piezas.append(lb.caja("Arco_TravesanoInf", (1.84, 0.14, 0.08), (0.0, 0.78, 0.17), m_acero_osc, bisel=0.010, segs_bisel=1))

    # 2. Dos pilares altos rojo ladrillo y acero + riostras traseras en A (~45° hacia +Y)
    for sx in (-1.04, 1.04):
        piezas.append(lb.caja("Arco_PilarOsc", (0.22, 0.24, 2.48), (sx, -0.30, 1.32), m_acero_osc, bisel=0.018, segs_bisel=1))
        piezas.append(lb.caja("Arco_PilarRojo", (0.15, 0.265, 2.42), (sx, -0.30, 1.32), m_rojo, bisel=0.012, segs_bisel=1))
        # Riostra inclinada en A desde altura media-alta (z=1.54) a zapata trasera (y=+0.78, z=0.14)
        p_top = Vector((sx, -0.26, 1.54))
        p_bot = Vector((sx, 0.78, 0.14))
        mid = (p_top + p_bot) * 0.5
        ang_diag = math.atan2(p_top.z - p_bot.z, p_bot.y - p_top.y)
        dist_d = (p_top - p_bot).length
        piezas.append(lb.caja("Arco_DiagOsc", (0.16, dist_d, 0.16), mid, m_acero_osc, bisel=0.014, segs_bisel=1, rot=(-ang_diag, 0.0, 0.0)))
        piezas.append(lb.caja("Arco_DiagRojo", (0.10, dist_d - 0.06, 0.176), mid, m_rojo, bisel=0.010, segs_bisel=1, rot=(-ang_diag, 0.0, 0.0)))
        # Topes frontales en las esquinas medias del cartel (-Y)
        piezas.append(lb.caja("Arco_TopeLateral", (0.24, 0.18, 0.28), (sx, -0.44, 1.48), m_acero_osc, bisel=0.014, segs_bisel=1))

    # 3. Gran cartel colgante de paso bajo (hueco libre >= 1.34 m debajo!) + flechas chevrón verde/lima
    piezas.append(lb.panel_uv("Arco_Panel", (2.06, 0.22, 1.06), (0.0, -0.30, 1.94), m_cartel, cara_uv="-Y"))
    piezas.append(lb.caja("Arco_VigaSup", (2.44, 0.28, 0.14), (0.0, -0.30, 2.52), m_acero_osc, bisel=0.016, segs_bisel=1))
    piezas.append(lb.caja("Arco_VigaSupRoja", (2.40, 0.30, 0.08), (0.0, -0.30, 2.52), m_rojo, bisel=0.010, segs_bisel=1))
    piezas.append(lb.caja("Arco_VigaInf", (2.36, 0.26, 0.11), (0.0, -0.30, 1.39), m_acero_osc, bisel=0.014, segs_bisel=1))

    # Flechas 3D luminosas apuntando hacia abajo (rodar) a ambos lados del cartel
    for sy_f, s_dir in ((-0.415, -1.0), (-0.185, 1.0)):
        for ax in (-0.60, 0.0, 0.60):
            piezas.append(lb.caja("Arco_FlechaFondoV", (0.17, 0.016, 0.34), (ax, sy_f, 2.08), m_acero_osc))
            piezas.append(lb.cilindro("Arco_FlechaFondoP", 0.001, 0.23, 0.28, (ax, sy_f, 1.82), m_acero_osc, eje="Z", lados=4, rot=(0.0, math.radians(180), math.radians(45))))
            sy_top = sy_f + s_dir * 0.014
            piezas.append(lb.caja("Arco_FlechaVastago", (0.11, 0.018, 0.30), (ax, sy_top, 2.08), m_amarillo))
            piezas.append(lb.cilindro("Arco_FlechaPunta", 0.001, 0.18, 0.22, (ax, sy_top, 1.84), m_amarillo, eje="Z", lados=4, rot=(0.0, math.radians(180), math.radians(45))))

    # Pilotos rojos en la cima
    for lx in (-0.78, 0.78):
        piezas.append(lb.caja("Baliza_Base", (0.16, 0.16, 0.06), (lx, -0.30, 2.61), m_acero_osc, bisel=0.01, segs_bisel=1))
        piezas.append(lb.cilindro("Baliza_Domo", 0.075, 0.065, 0.12, (lx, -0.30, 2.68), m_piloto, eje="Z", lados=12, bisel_tapa=0.015))
        piezas.append(lb.toro("Baliza_Aro", 0.092, 0.012, (lx, -0.30, 2.69), m_acero_osc, eje="Z", segs_mayor=14, segs_menor=6))

    obj = lb.unir(piezas, "Arco_Galibo")
    obj.location = (0.0, 0.0, 0.0)
    lb.suavizar_por_angulo(obj, 35.0)
    return obj


def main():
    args = lb.parsear_args_modelo("Modelos/Minijuego_Correr/arco_galibo.glb")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    obj = construir()
    lb.exportar_glb(obj, args.salida)
    if args.blend:
        lb.guardar_blend(args.blend)
    if args.render and not args.sin_render:
        lb.render_cuatro_vistas(obj, args.render, con_referencia=True)


if __name__ == "__main__":
    main()
