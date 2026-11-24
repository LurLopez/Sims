"""
Andén de estación de 32 m con voladizo, ménsulas de apoyo, cenefa táctil amarilla
y rejillas de drenaje. Simétrico en X para colocarse en ambos lados sin espejar.
"""

import os
import sys

import bmesh
import bpy

DIR_ACTUAL = os.path.dirname(os.path.abspath(__file__))
if DIR_ACTUAL not in sys.path:
    sys.path.insert(0, DIR_ACTUAL)

import lib_blender as lb

RAIZ_PROYECTO = os.path.abspath(os.path.join(DIR_ACTUAL, "..", "..", ".."))
DIR_TEX = os.path.join(RAIZ_PROYECTO, "Imagenes", "Minijuego_Correr", "Texturas3D")

LARGO = 32.0
ANCHO_TOP = 3.64
ALTO_TOTAL = 0.80


def construir():
    tex_alb = os.path.join(DIR_TEX, "anden_albedo.png")
    tex_nrm = os.path.join(DIR_TEX, "anden_normal.png")
    m_anden = lb.material(
        "Anden_Superficie", "#ffffff", rough=0.76, metal=0.04,
        tex_albedo=tex_alb if os.path.exists(tex_alb) else None,
        tex_normal=tex_nrm if os.path.exists(tex_nrm) else None,
        normal_fuerza=0.95,
    )
    m_bajo = lb.material("Anden_MuroBajo", "#464d59", rough=0.88, metal=0.04)
    m_amarillo = lb.material("Anden_TactilAmarillo", "#f4c41c", rough=0.68, metal=0.02)
    m_rejilla = lb.material("Anden_Rejilla", "#2b3544", rough=0.52, metal=0.60)

    piezas = []

    # 1. Murete inferior retranqueado para crear sombra bajo el voladizo (16 cortes en Y)
    piezas.append(lb.caja("Anden_Bajo", (3.12, LARGO, 0.58), (0.0, 0.0, 0.29), m_bajo, subdiv_y=16))

    # 2. Losa superior con UV calibrado [0..1, 0..4] (16 cortes en Y)
    bm = bmesh.new()
    hw = ANCHO_TOP * 0.5
    segs_y = 16
    perfil = [
        (-hw + 0.04, 0.58),
        (hw - 0.04, 0.58),
        (hw, 0.62),
        (hw, ALTO_TOTAL),
        (-hw, ALTO_TOTAL),
        (-hw, 0.62),
    ]
    capas = []
    for i in range(segs_y + 1):
        y = -LARGO * 0.5 + LARGO * (i / segs_y)
        capas.append([bm.verts.new((x, y, z)) for x, z in perfil])
    n = len(perfil)
    for i in range(segs_y):
        a, b = capas[i], capas[i + 1]
        for j in range(n):
            k = (j + 1) % n
            bm.faces.new((a[j], a[k], b[k], b[j]))
    bm.faces.new(tuple(reversed(capas[0])))
    bm.faces.new(tuple(capas[-1]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)

    uv_layer = bm.loops.layers.uv.verify()
    for f in bm.faces:
        for lp in f.loops:
            co = lp.vert.co
            u = (co.x + hw) / ANCHO_TOP
            v = ((co.y + LARGO * 0.5) / LARGO) * 4.0
            lp[uv_layer].uv = (u, v)
    piezas.append(lb.finalizar_bmesh("Anden_Losa", bm, m_anden))

    # 3. Ménsulas de soporte bajo el voladizo en ambos costados cada 4 m
    for my in (-14.0, -10.0, -6.0, -2.0, 2.0, 6.0, 10.0, 14.0):
        for sx in (-1, 1):
            piezas.append(lb.caja("Anden_Mensula", (0.24, 0.22, 0.28), (sx * 1.66, my, 0.45), m_bajo, bisel=0.02, segs_bisel=1))

    # 4. Bordillos táctiles en relieve y rejillas metálicas de drenaje en losa
    for sx in (-1, 1):
        piezas.append(lb.caja("Anden_BordeTactil", (0.14, LARGO, 0.016), (sx * (hw - 0.09), 0.0, ALTO_TOTAL + 0.008), m_amarillo, subdiv_y=16))
        for dy in (-12.0, -4.0, 4.0, 12.0):
            piezas.append(lb.caja("Anden_Drenaje", (0.24, 0.64, 0.018), (sx * (hw - 0.54), dy, ALTO_TOTAL + 0.006), m_rejilla))

    obj = lb.unir(piezas, "Anden_Tramo")
    obj.location = (0.0, 0.0, 0.0)
    lb.suavizar_por_angulo(obj, 35.0)
    return obj


def main():
    args = lb.parsear_args_modelo("Modelos/Minijuego_Correr/anden_tramo.glb")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    obj = construir()
    lb.exportar_glb(obj, args.salida)
    if args.blend:
        lb.guardar_blend(args.blend)
    if args.render and not args.sin_render:
        lb.render_cuatro_vistas(obj, args.render, con_referencia=False)


if __name__ == "__main__":
    main()
