"""
Barrera tope ferroviaria saltable (VALLA_BAJA) fiel al estilo Subway Surfers (`blocker_standard` / `blocker_jump`).
Base pesada oscura en vía, postes rojo ladrillo y acero arriostrados en A hacia atrás (+Y),
topes frontales salientes y travesaño rojo/crema a 1.15 m de altura.
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
    p = os.path.join(DIR_TEX, "valla_bl_albedo.png")
    if not os.path.exists(p):
        subprocess.run(["python3", os.path.join(DIR_ACTUAL, "generar_texturas_modelos.py")], check=True)
    return p


def construir():
    tex_valla = _asegurar_tex()
    m_tablero = lb.material("Valla_Tablero", "#ffffff", rough=0.40, metal=0.10, tex_albedo=tex_valla)
    m_rojo = lb.material("Valla_Rojo", "#a82d24", rough=0.48, metal=0.22)
    m_acero_osc = lb.material("Valla_AceroOsc", "#2c292b", rough=0.58, metal=0.45)
    m_ambar = lb.material("Valla_BalizaAmbar", "#fde047", rough=0.14, metal=0.0,
                          emision="#f59e0b", emision_fuerza=4.5)
    m_verde = lb.material("Valla_BaseVerde", "#7ea838", rough=0.55, metal=0.05)

    piezas = []

    # 1. Plataforma pesada inferior trapezoidal sobre la vía (blocker_standard_0)
    piezas.append(lb.caja("Valla_Plataforma", (2.22, 1.38, 0.14), (0.0, 0.18, 0.07), m_acero_osc, bisel=0.020, segs_bisel=1))
    piezas.append(lb.caja("Valla_PlataformaCentro", (1.56, 0.92, 0.025), (0.0, 0.22, 0.142), m_verde, bisel=0.008))

    # 2. Dos postes frontales rojo ladrillo + marco de acero y riostras diagonales en A hacia atrás (+Y)
    for sx in (-0.86, 0.86):
        # Pilar vertical robusto
        piezas.append(lb.caja("Valla_PilarOsc", (0.20, 0.22, 1.08), (sx, -0.26, 0.62), m_acero_osc, bisel=0.016, segs_bisel=1))
        piezas.append(lb.caja("Valla_PilarRojo", (0.14, 0.245, 1.02), (sx, -0.26, 0.62), m_rojo, bisel=0.012, segs_bisel=1))
        # Riostra inclinada en A desde arriba del pilar (-0.26, z=1.00) hasta zapata trasera (+0.74, z=0.14)
        p_top = Vector((sx, -0.24, 0.98))
        p_bot = Vector((sx, 0.72, 0.14))
        mid = (p_top + p_bot) * 0.5
        ang_diag = math.atan2(p_top.z - p_bot.z, p_bot.y - p_top.y)
        dist_d = (p_top - p_bot).length
        piezas.append(lb.caja("Valla_DiagOsc", (0.16, dist_d, 0.16), mid, m_acero_osc, bisel=0.014, segs_bisel=1, rot=(-ang_diag, 0.0, 0.0)))
        piezas.append(lb.caja("Valla_DiagRojo", (0.10, dist_d - 0.06, 0.176), mid, m_rojo, bisel=0.010, segs_bisel=1, rot=(-ang_diag, 0.0, 0.0)))
        # Topes frontales salientes (rail buffer stops) en los extremos del tablón (-Y)
        piezas.append(lb.caja("Valla_TopeBase", (0.24, 0.26, 0.28), (sx, -0.38, 0.90), m_acero_osc, bisel=0.018, segs_bisel=1))
        piezas.append(lb.cilindro("Valla_TopeDisco", 0.11, 0.11, 0.08, (sx, -0.52, 0.90), m_rojo, eje="Y", lados=12, bisel_tapa=0.012))

    # 3. Gran travesaño de peligro rayado (top <= 1.16 m para salto limpio) + balizas
    piezas.append(lb.panel_uv("Valla_Tablero", (2.18, 0.16, 0.44), (0.0, -0.26, 0.89), m_tablero, cara_uv="-Y"))
    piezas.append(lb.caja("Valla_VigaSup", (2.26, 0.24, 0.085), (0.0, -0.26, 1.13), m_acero_osc, bisel=0.012, segs_bisel=1))
    piezas.append(lb.caja("Valla_VigaInf", (2.26, 0.24, 0.085), (0.0, -0.26, 0.65), m_acero_osc, bisel=0.012, segs_bisel=1))
    piezas.append(lb.caja("Valla_TravesanoInf", (1.60, 0.12, 0.08), (0.0, 0.68, 0.18), m_acero_osc, bisel=0.010, segs_bisel=1))

    for bx in (-0.64, 0.64):
        piezas.append(lb.caja("Baliza_Soporte", (0.16, 0.16, 0.06), (bx, -0.26, 1.18), m_acero_osc, bisel=0.01, segs_bisel=1))
        piezas.append(lb.cilindro("Baliza_Domo", 0.075, 0.060, 0.11, (bx, -0.26, 1.25), m_ambar, eje="Z", lados=12, bisel_tapa=0.015))
        piezas.append(lb.toro("Baliza_Jaula", 0.090, 0.011, (bx, -0.26, 1.25), m_acero_osc, eje="Z", segs_mayor=14, segs_menor=6))

    obj = lb.unir(piezas, "Valla_Baja")
    obj.location = (0.0, 0.0, 0.0)
    lb.suavizar_por_angulo(obj, 35.0)
    return obj


def main():
    args = lb.parsear_args_modelo("Modelos/Minijuego_Correr/valla_baja.glb")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    obj = construir()
    lb.exportar_glb(obj, args.salida)
    if args.blend:
        lb.guardar_blend(args.blend)
    if args.render and not args.sin_render:
        lb.render_cuatro_vistas(obj, args.render, con_referencia=True)


if __name__ == "__main__":
    main()
