"""
Rampa ferroviaria estilo Subway Surfers (`train_ramp_0`) de acceso exacto al techo (3.05 m alto, 6.20 m largo).
Clona la silueta trapezoidal de paredes laterales pizarra acanaladas (~6° inclinación) y zócalo de acero
saliente para ensamblarse de forma continua con el vagón, con tablero oro-arena y chevrones luminosos.
Origen (0, 0, 0) en el borde superior que encaja con el vagón (Y de -6.20 a +0.06).
"""

import math
import os
import subprocess
import sys

import bmesh
import bpy
from mathutils import Vector

DIR_ACTUAL = os.path.dirname(os.path.abspath(__file__))
if DIR_ACTUAL not in sys.path:
    sys.path.insert(0, DIR_ACTUAL)

import lib_blender as lb

ANCHO = 2.28
ALTO = 3.05
LARGO = 6.20
Y_BASE = 0.145
HW = ANCHO * 0.5         # 1.14
HW_BOT = 1.075           # Coincide con Vagon_Metro
HW_TOP = 0.850
Z_WAIST = 0.56
Z_EAVES = 2.66
WALL_DZ = Z_EAVES - Z_WAIST
WALL_DX = HW_BOT - HW_TOP
WALL_TILT = math.atan2(WALL_DX, WALL_DZ)

RAIZ_PROYECTO = os.path.abspath(os.path.join(DIR_ACTUAL, "..", "..", ".."))
DIR_TEX = os.path.join(RAIZ_PROYECTO, "Imagenes", "Minijuego_Correr", "Texturas3D")


def _x_pared(z: float) -> float:
    t = max(0.0, min(1.0, (z - Z_WAIST) / WALL_DZ))
    return HW_BOT - WALL_DX * t


def _asegurar_texturas():
    alb = os.path.join(DIR_TEX, "rampa_bl_albedo.png")
    em = os.path.join(DIR_TEX, "rampa_bl_emission.png")
    if not (os.path.exists(alb) and os.path.exists(em)):
        subprocess.run(["python3", os.path.join(DIR_ACTUAL, "generar_texturas_modelos.py")], check=True)
    return alb, em


def _cuna_trapezoidal(mat_top, mat_lado, mat_acero, segs_y: int = 12):
    """Cuña principal con paredes laterales inclinadas ~6° exactamente igual que el vagón."""
    bm = bmesh.new()
    anillos = []
    for i in range(segs_y + 1):
        t = i / segs_y
        y = -LARGO * (1.0 - t)
        z_top = Y_BASE + (ALTO - 0.02 - Y_BASE) * t
        x_t = _x_pared(max(z_top, Z_WAIST))
        x_b = HW_BOT if z_top >= Z_WAIST else x_t + 0.04
        z_b = 0.36 if t > 0.12 else 0.04
        v_bl = bm.verts.new((-x_b, y, z_b))
        v_br = bm.verts.new((x_b, y, z_b))
        v_tr = bm.verts.new((x_t, y, z_top))
        v_tl = bm.verts.new((-x_t, y, z_top))
        anillos.append((v_bl, v_br, v_tr, v_tl))

    for i in range(segs_y):
        a0, a1, a2, a3 = anillos[i]
        b0, b1, b2, b3 = anillos[i + 1]
        ft = bm.faces.new((a3, a2, b2, b3))
        ft.material_index = 0
        for quad in ((a1, b1, b2, a2), (a0, a3, b3, b0)):
            bm.faces.new(quad).material_index = 1
        bm.faces.new((a0, b0, b1, a1)).material_index = 2

    bm.faces.new((anillos[-1][0], anillos[-1][1], anillos[-1][2], anillos[-1][3])).material_index = 2
    bm.faces.new((anillos[0][3], anillos[0][2], anillos[0][1], anillos[0][0])).material_index = 2

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    uv_layer = bm.loops.layers.uv.verify()
    for f in bm.faces:
        for lp in f.loops:
            co = lp.vert.co
            u = (co.x + HW_BOT) / (2.0 * HW_BOT)
            v = (co.y + LARGO) / LARGO
            lp[uv_layer].uv = (u, v)

    mesh = bpy.data.meshes.new("Rampa_Cuna")
    bm.to_mesh(mesh)
    bm.free()
    mesh.validate()
    mesh.materials.append(mat_top)
    mesh.materials.append(mat_lado)
    mesh.materials.append(mat_acero)
    return lb.nuevo_objeto("Rampa_Cuna", mesh)


def construir():
    alb, em = _asegurar_texturas()
    m_top = lb.material("Rampa_Top", "#ffffff", rough=0.42, metal=0.14,
                        tex_albedo=alb, tex_emission=em, emision_fuerza=0.65)
    m_acero = lb.material("Rampa_Acero", "#6d92ad", rough=0.38, metal=0.52)
    m_acero_osc = lb.material("Rampa_AceroOsc", "#283847", rough=0.50, metal=0.46)
    m_luz = lb.material("Rampa_FlechaLuz", "#fef08a", rough=0.16, metal=0.0,
                        emision="#fde047", emision_fuerza=2.2)

    piezas = [_cuna_trapezoidal(m_top, m_acero, m_acero_osc, segs_y=12)]

    ang_subida = math.atan2(ALTO - 0.02 - Y_BASE, LARGO)
    hip = math.hypot(LARGO, ALTO - 0.02 - Y_BASE)

    # 1. Zócalo/chasis perimetral saliente igual al del vagón + bogie trasero
    piezas.append(lb.caja("Rampa_Chasis", (ANCHO - 0.04, LARGO - 0.85, 0.16),
                          (0.0, -LARGO * 0.5 + 0.42, 0.46), m_acero_osc,
                          bisel=0.018, segs_bisel=1, subdiv_y=10))
    piezas.append(lb.caja("Rampa_ChasisBorde", (ANCHO, LARGO - 0.85, 0.075),
                          (0.0, -LARGO * 0.5 + 0.42, 0.56), m_acero,
                          bisel=0.012, segs_bisel=1, subdiv_y=10))
    # Ruedas en el extremo alto (-0.85 m)
    for dy in (-1.45, -0.55):
        piezas.append(lb.cilindro("Rampa_Eje", 0.055, 0.055, 1.44, (0.0, dy, 0.40), m_acero_osc, eje="X", lados=8))
        for lado in (-1, 1):
            piezas.append(lb.cilindro("Rampa_Rueda", 0.25, 0.25, 0.12, (lado * 0.70, dy, 0.40), m_acero_osc, eje="X", lados=12))

    # 2. Costillas verticales acanaladas inclinadas a ~6° en los costados (look train_cargo_0 + train_ramp_0)
    for lado in (-1, 1):
        rot_w = (0.0, -lado * WALL_TILT, 0.0)
        for t in (0.20, 0.34, 0.48, 0.62, 0.76, 0.90):
            yc = -LARGO * (1.0 - t)
            z_lim = Y_BASE + (ALTO - 0.02 - Y_BASE) * t
            h_rib = max(0.24, z_lim - Z_WAIST)
            zc = Z_WAIST + h_rib * 0.5
            xc = _x_pared(zc)
            piezas.append(lb.caja("Rampa_CostillaLat", (0.065, 0.13, h_rib),
                                  (lado * (xc + 0.02), yc, zc), m_acero_osc, bisel=0.010, segs_bisel=1, rot=rot_w))
        # Bordillo superior diagonal siguiendo exactamente la arista inclinada de la cuña (top <= 3.04 m)
        p_b0 = Vector((lado * (HW_BOT + 0.010), -LARGO + 0.06, Y_BASE - 0.01))
        p_b1 = Vector((lado * (HW_TOP + 0.010), -0.02, ALTO - 0.08))
        piezas.append(lb.tubo_ruta("Rampa_BordeSup", [p_b0, p_b1], 0.056, m_acero,
                                   lados=6, escala_ab=(0.80, 1.15)))

    # 3. 4 flechas chevrón luminosas y peldaños antideslizantes solo en el borde exterior
    for k in range(4):
        t = (0.5 + k) / 4.0
        y_c = -LARGO * (1.0 - t)
        z_c = Y_BASE + (ALTO - 0.02 - Y_BASE) * t + 0.012
        ancho_rel = (_x_pared(max(z_c, Z_WAIST)) - 0.14) * 0.76
        for sx in (-1.0, 1.0):
            p_punta = Vector((0.0, y_c + 0.40 * math.cos(ang_subida), z_c + 0.40 * math.sin(ang_subida)))
            p_ala = Vector((sx * ancho_rel, y_c - 0.20 * math.cos(ang_subida), z_c - 0.20 * math.sin(ang_subida)))
            piezas.append(lb.tubo_ruta("Rampa_Chevron3D", [p_ala, p_punta], 0.036, m_luz,
                                       lados=6, escala_ab=(1.0, 0.52)))
    for k_t in range(10):
        t = (k_t + 0.45) / 10.0
        yt = -LARGO * (1.0 - t)
        zt = Y_BASE + (ALTO - 0.02 - Y_BASE) * t + 0.004
        x_lim = _x_pared(max(zt, Z_WAIST)) - 0.14
        for side_t in (-1.0, 1.0):
            piezas.append(lb.caja("Rampa_Taco", (0.14, 0.055, 0.016), (side_t * x_lim, yt, zt),
                                  m_acero_osc, bisel=0.004, segs_bisel=1, rot=(ang_subida, 0.0, 0.0)))

    # 4. Labio delantero sobre raíles + puente superior al vagón
    piezas.append(lb.caja("Rampa_Labio", (ANCHO - 0.08, 0.24, 0.155), (0.0, -LARGO + 0.10, 0.078), m_acero_osc, bisel=0.012, segs_bisel=1))
    piezas.append(lb.caja("Rampa_PuenteTecho", (1.68, 0.24, 0.045), (0.0, 0.02, ALTO - 0.024), m_acero_osc, bisel=0.010, segs_bisel=1))

    obj = lb.unir(piezas, "Rampa_Tren")
    obj.location = (0.0, 0.0, 0.0)
    lb.suavizar_por_angulo(obj, 35.0)
    return obj


def main():
    args = lb.parsear_args_modelo("Modelos/Minijuego_Correr/rampa_tren.glb")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    obj = construir()
    lb.exportar_glb(obj, args.salida)
    if args.blend:
        lb.guardar_blend(args.blend)
    if args.render and not args.sin_render:
        lb.render_cuatro_vistas(obj, args.render, con_referencia=True)


if __name__ == "__main__":
    main()
