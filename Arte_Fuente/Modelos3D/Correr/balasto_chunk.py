"""
Lecho de balasto ferroviario 3D con 3 bancadas trapezoidales y cunetas de drenaje
para cada chunk de 32 m (16 cortes en Y para curvatura del horizonte).
"""

import os
import random
import sys

import bmesh
import bpy

DIR_ACTUAL = os.path.dirname(os.path.abspath(__file__))
if DIR_ACTUAL not in sys.path:
    sys.path.insert(0, DIR_ACTUAL)

import lib_blender as lb

RAIZ_PROYECTO = os.path.abspath(os.path.join(DIR_ACTUAL, "..", "..", ".."))
DIR_TEX = os.path.join(RAIZ_PROYECTO, "Imagenes", "Minijuego_Correr", "Texturas3D")

ANCHO = 9.60   # 3 * 2.70 + 1.50
LARGO = 32.0


def construir():
    tex_alb = os.path.join(DIR_TEX, "balasto_albedo.png")
    tex_nrm = os.path.join(DIR_TEX, "balasto_normal.png")
    m_balasto = lb.material(
        "Balasto_Grava", "#ffffff", rough=0.92, metal=0.02,
        tex_albedo=tex_alb if os.path.exists(tex_alb) else None,
        tex_normal=tex_nrm if os.path.exists(tex_nrm) else None,
        normal_fuerza=0.95,
    )

    # Perfil transversal cerrado X -> Z: 3 hombros de balasto + faldón inferior (-0.05 m)
    # Al ser un sólido cerrado 100 % manifold, todas las normales apuntan hacia +Z (arriba en Godot).
    hw = ANCHO * 0.5  # 4.80
    xs_zs = [
        (-hw, 0.00),
        (-3.95, 0.00),
        (-3.65, 0.045),
        (-1.75, 0.045),
        (-1.45, 0.00),
        (-1.25, 0.00),
        (-0.95, 0.045),
        (0.95, 0.045),
        (1.25, 0.00),
        (1.45, 0.00),
        (1.75, 0.045),
        (3.65, 0.045),
        (3.95, 0.00),
        (hw, 0.00),
        (hw, -0.05),
        (-hw, -0.05),
    ]

    segs_y = 16
    bm = bmesh.new()
    filas = []
    for iy in range(segs_y + 1):
        y = -LARGO * 0.5 + LARGO * (iy / segs_y)
        filas.append([bm.verts.new((x, y, z)) for x, z in xs_zs])

    n_pts = len(xs_zs)
    for iy in range(segs_y):
        a, b = filas[iy], filas[iy + 1]
        for j in range(n_pts):
            k = (j + 1) % n_pts
            bm.faces.new((a[j], b[j], b[k], a[k]))

    # Tapas frontal y trasera para cerrar completamente el sólido
    bm.faces.new(tuple(filas[0]))
    bm.faces.new(tuple(reversed(filas[-1])))

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    uv_layer = bm.loops.layers.uv.verify()
    for f in bm.faces:
        for lp in f.loops:
            co = lp.vert.co
            u = (co.x + hw) / ANCHO
            v = ((co.y + LARGO * 0.5) / LARGO) * 4.0
            lp[uv_layer].uv = (u, v)

    obj = lb.finalizar_bmesh("Balasto_Chunk", bm, m_balasto)

    # Piedras y gravilla 3D dispersas en las cunetas y hombros de balasto
    rng = random.Random(42)
    piedras = [obj]
    for i_s in range(72):
        sy = -LARGO * 0.48 + LARGO * 0.96 * (i_s / 71.0)
        zona_x = rng.choice((-3.88, -1.35, 1.35, 3.88, -4.22, 4.22))
        sx = zona_x + rng.uniform(-0.20, 0.20)
        bm_p = bmesh.new()
        bmesh.ops.create_icosphere(bm_p, subdivisions=1, radius=rng.uniform(0.082, 0.132))
        for v in bm_p.verts:
            v.co.z *= 0.58
            v.co.x *= rng.uniform(0.85, 1.32)
        bmesh.ops.recalc_face_normals(bm_p, faces=bm_p.faces)
        uv_p = bm_p.loops.layers.uv.verify()
        u_base, v_base = rng.uniform(0.1, 0.9), rng.uniform(0.1, 0.9)
        for f in bm_p.faces:
            for lp in f.loops:
                lp[uv_p].uv = (u_base + lp.vert.co.x * 1.4, v_base + lp.vert.co.y * 1.4)
        piedras.append(lb.finalizar_bmesh(f"Balasto_Roca_{i_s}", bm_p, m_balasto, (sx, sy, 0.042), (rng.uniform(0, 0.6), rng.uniform(0, 0.6), rng.uniform(0, 3.1))))
    obj = lb.unir(piedras, "Balasto_Chunk")
    lb.suavizar_por_angulo(obj, 35.0)
    return obj


def main():
    args = lb.parsear_args_modelo("Modelos/Minijuego_Correr/balasto_chunk.glb")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    obj = construir()
    lb.exportar_glb(obj, args.salida)
    if args.blend:
        lb.guardar_blend(args.blend)
    if args.render and not args.sin_render:
        lb.render_cuatro_vistas(obj, args.render, con_referencia=False)


if __name__ == "__main__":
    main()
