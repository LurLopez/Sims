"""
Árbol urbano estilizado de parque con tronco retorcido multi-rama, raíces de
contrafuerte, alcorque y 20 cúmulos facetados de copa orgánica en 3 verdes
(sin esferas primitivas lisas) para PARK RUSH 3D.
"""

import math
import os
import random
import sys

import bmesh
import bpy
from mathutils import Euler, Vector

DIR_ACTUAL = os.path.dirname(os.path.abspath(__file__))
if DIR_ACTUAL not in sys.path:
    sys.path.insert(0, DIR_ACTUAL)

import lib_blender as lb


def _cúmulo_facetado(nombre: str, radio: float, centro, mat, escala, rot):
    """Puff orgánico de follaje estilizado low-poly facetado (subdiv=1 + ligera perturbación)."""
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=1, radius=radio)
    rng = random.Random(hash((round(centro[0], 2), round(centro[1], 2), round(centro[2], 2))))
    for v in bm.verts:
        k = rng.uniform(0.86, 1.14)
        v.co.x *= escala[0] * k
        v.co.y *= escala[1] * k
        v.co.z *= escala[2] * k
    bmesh.ops.transform(bm, matrix=Euler(rot, "XYZ").to_matrix().to_4x4(), verts=bm.verts)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return lb.finalizar_bmesh(nombre, bm, mat, centro)


def construir():
    m_tronco = lb.material("Arbol_Tronco", "#6b4428", rough=0.88, metal=0.02)
    m_osc = lb.material("Arbol_HojaOscura", "#176e3b", rough=0.72, metal=0.02)
    m_med = lb.material("Arbol_HojaMedia", "#29a34c", rough=0.68, metal=0.02)
    m_clara = lb.material("Arbol_HojaClara", "#6de04f", rough=0.62, metal=0.02)

    piezas = []

    # 1. Raíces de contrafuerte agarradas al suelo + tronco principal sinuoso
    for i_r in range(5):
        ang = i_r * (math.tau / 5.0) + 0.3
        ca, sa = math.cos(ang), math.sin(ang)
        pts_r = [
            (ca * 0.24, sa * 0.24, 0.72),
            (ca * 0.48, sa * 0.48, 0.22),
            (ca * 0.76, sa * 0.76, 0.04),
        ]
        piezas.append(lb.tubo_ruta("Raiz", pts_r, [0.16, 0.11, 0.05], m_tronco, lados=6, catmull_subdiv=2))

    pts_tronco = [
        (0.0, 0.0, 0.0),
        (-0.08, 0.05, 1.35),
        (0.10, -0.06, 2.75),
        (0.04, 0.02, 4.05),
    ]
    piezas.append(lb.tubo_ruta("Tronco", pts_tronco, [0.38, 0.31, 0.26, 0.20], m_tronco, lados=10, catmull_subdiv=2))

    # 4 ramas estructurales en Y abriéndose dentro de la copa
    ramas = [
        [(0.06, 0.0, 3.35), (-0.65, 0.42, 4.30), (-1.15, 0.65, 4.95)],
        [(0.06, 0.0, 3.45), (0.72, -0.38, 4.42), (1.20, -0.60, 5.05)],
        [(0.05, 0.0, 3.60), (0.45, 0.68, 4.55), (0.75, 1.15, 5.20)],
        [(0.04, 0.0, 3.70), (-0.42, -0.62, 4.65), (-0.70, -1.05, 5.30)],
    ]
    for pts_rm in ramas:
        piezas.append(lb.tubo_ruta("Rama", pts_rm, [0.15, 0.11, 0.06], m_tronco, lados=7, catmull_subdiv=2))

    # 2. Copa frondosa con 18 cúmulos facetados asimétricos (nuca inferior oscura -> brotes lima arriba)
    clusters = [
        # Capa sombra inferior
        ((-0.85, 0.50, 4.45), 1.02, (1.1, 1.0, 0.82), m_osc, (0.2, 0.1, 0.4)),
        ((0.88, -0.45, 4.42), 1.00, (1.05, 1.1, 0.80), m_osc, (-0.1, 0.2, 1.1)),
        ((-0.45, -0.78, 4.55), 0.96, (1.0, 1.0, 0.85), m_osc, (0.1, -0.2, 2.0)),
        ((0.48, 0.82, 4.52), 0.98, (1.08, 0.95, 0.82), m_osc, (-0.2, 0.1, 0.8)),
        ((0.0, 0.0, 4.35), 1.18, (1.15, 1.15, 0.85), m_osc, (0.0, 0.0, 0.3)),
        # Cuerpo medio vibrante
        ((-1.22, 0.22, 5.05), 0.88, (1.05, 1.0, 0.90), m_med, (0.3, 0.1, 0.7)),
        ((1.22, -0.18, 5.02), 0.90, (1.0, 1.05, 0.88), m_med, (-0.2, 0.3, 1.5)),
        ((-0.18, 1.18, 5.15), 0.86, (1.0, 1.0, 0.88), m_med, (0.1, -0.2, 2.3)),
        ((0.15, -1.16, 5.12), 0.88, (1.05, 0.96, 0.88), m_med, (-0.1, 0.2, 0.5)),
        ((-0.65, -0.62, 5.38), 0.94, (1.05, 1.0, 0.92), m_med, (0.2, 0.2, 1.8)),
        ((0.70, 0.60, 5.35), 0.92, (1.0, 1.06, 0.90), m_med, (-0.2, -0.1, 2.7)),
        # Brote soleado superior (lima vibrante)
        ((-0.55, 0.35, 5.88), 0.82, (1.05, 1.0, 0.88), m_clara, (0.1, 0.3, 0.9)),
        ((0.52, -0.30, 5.84), 0.80, (1.0, 1.05, 0.86), m_clara, (-0.2, 0.1, 1.4)),
        ((0.02, 0.04, 6.26), 0.95, (1.12, 1.08, 0.85), m_clara, (0.0, 0.2, 2.1)),
        ((-0.05, 0.62, 5.95), 0.70, (1.0, 1.0, 0.88), m_clara, (0.2, -0.1, 0.4)),
        ((0.08, -0.58, 5.90), 0.68, (1.0, 1.0, 0.88), m_clara, (-0.1, 0.2, 1.9)),
    ]
    for i, (pos, r, esc, mat, rot) in enumerate(clusters):
        piezas.append(_cúmulo_facetado(f"Follaje_{i}", r, pos, mat, esc, rot))

    obj = lb.unir(piezas, "Arbol_Parque")
    obj.location = (0.0, 0.0, 0.0)
    # Sombrear suave tronco pero mantener ligero carácter facetado en hojas (30°)
    lb.suavizar_por_angulo(obj, 30.0)
    return obj


def main():
    args = lb.parsear_args_modelo("Modelos/Minijuego_Correr/arbol_parque.glb")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    obj = construir()
    lb.exportar_glb(obj, args.salida)
    if args.blend:
        lb.guardar_blend(args.blend)
    if args.render and not args.sin_render:
        lb.render_cuatro_vistas(obj, args.render, con_referencia=True)


if __name__ == "__main__":
    main()
