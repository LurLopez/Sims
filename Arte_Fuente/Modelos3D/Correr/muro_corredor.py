"""
Muro de corredor ferroviario con paños rehundidos en arcada entre pilastras de
piedra, albardilla gruesa, verja superior de hierro forjado con picas y tubería
técnica adosada (PARK RUSH 3D). Subdividido en 16 cortes en Y para curvatura.
Mantiene el slot `Muro_Ladrillo` para alternar grafiti A / B en Godot.
"""

import math
import os
import sys

import bmesh
import bpy

DIR_ACTUAL = os.path.dirname(os.path.abspath(__file__))
if DIR_ACTUAL not in sys.path:
    sys.path.insert(0, DIR_ACTUAL)

import lib_blender as lb

LARGO = 32.0
RAIZ_PROYECTO = os.path.abspath(os.path.join(DIR_ACTUAL, "..", "..", ".."))
DIR_TEX = os.path.join(RAIZ_PROYECTO, "Imagenes", "Minijuego_Correr", "Texturas3D")


def construir():
    tex_alb = os.path.join(DIR_TEX, "muro_graffiti_a_albedo.png")
    tex_nrm = os.path.join(DIR_TEX, "muro_graffiti_normal.png")
    m_muro = lb.material(
        "Muro_Ladrillo", "#ffffff", rough=0.80, metal=0.03,
        tex_albedo=tex_alb if os.path.exists(tex_alb) else None,
        tex_normal=tex_nrm if os.path.exists(tex_nrm) else None,
        normal_fuerza=1.0,
    )
    m_hormigon = lb.material("Muro_Hormigon", "#c4beb4", rough=0.82, metal=0.04)
    m_hierro = lb.material("Muro_Barandilla", "#2d394a", rough=0.44, metal=0.64)

    piezas = []

    # 1. Paño principal de ladrillo con grafiti (UV calibrado para leer de izquierda a derecha)
    alto_muro = 3.80
    base_z = 0.52
    bm = bmesh.new()
    hx = 0.36  # Ligeramente más fino que las pilastras (±0.60) para profundidad arquitectónica real!
    segs_y = 16
    xs = (-hx, hx)
    zs = (base_z, base_z + alto_muro)
    grid = {}
    for iy in range(segs_y + 1):
        y = -LARGO * 0.5 + LARGO * (iy / segs_y)
        for ix in (0, 1):
            for iz in (0, 1):
                grid[(iy, ix, iz)] = bm.verts.new((xs[ix], y, zs[iz]))
    for iy in range(segs_y):
        bm.faces.new((grid[(iy, 0, 0)], grid[(iy, 0, 1)], grid[(iy + 1, 0, 1)], grid[(iy + 1, 0, 0)]))
        bm.faces.new((grid[(iy, 1, 0)], grid[(iy + 1, 1, 0)], grid[(iy + 1, 1, 1)], grid[(iy, 1, 1)]))
        bm.faces.new((grid[(iy, 0, 1)], grid[(iy, 1, 1)], grid[(iy + 1, 1, 1)], grid[(iy + 1, 0, 1)]))
        bm.faces.new((grid[(iy, 0, 0)], grid[(iy + 1, 0, 0)], grid[(iy + 1, 1, 0)], grid[(iy, 1, 0)]))
    bm.faces.new((grid[(0, 0, 0)], grid[(0, 1, 0)], grid[(0, 1, 1)], grid[(0, 0, 1)]))
    bm.faces.new((grid[(segs_y, 0, 0)], grid[(segs_y, 0, 1)], grid[(segs_y, 1, 1)], grid[(segs_y, 1, 0)]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    uv_layer = bm.loops.layers.uv.verify()
    for f in bm.faces:
        hacia_pos_x = f.normal.x > 0.0
        for lp in f.loops:
            co = lp.vert.co
            u = ((co.y + LARGO * 0.5) / LARGO) * 2.0 if hacia_pos_x else ((LARGO * 0.5 - co.y) / LARGO) * 2.0
            v = (co.z - base_z) / alto_muro
            lp[uv_layer].uv = (u, v)
    piezas.append(lb.finalizar_bmesh("Muro_LadrilloPanel", bm, m_muro))

    # 2. Zócalo de granito y cornisa volada escalonada (16 cortes en Y)
    piezas.append(lb.caja("Muro_Zocalo", (1.00, LARGO, 0.56), (0.0, 0.0, 0.28), m_hormigon, bisel=0.03, segs_bisel=1, subdiv_y=16))
    piezas.append(lb.caja("Muro_Cornisa", (1.06, LARGO, 0.26), (0.0, 0.0, base_z + alto_muro + 0.08), m_hormigon, bisel=0.03, segs_bisel=1, subdiv_y=16))

    # 3. 3 Pilastras salientes robustas (cada 10.6 m -> -10.67, 0, +10.67) + contrafuertes + capitel
    for pz in (-10.67, 0.0, 10.67):
        piezas.append(lb.caja("Pilastra_Cuerpo", (1.22, 1.04, 4.35), (0.0, pz, 2.25), m_hormigon, bisel=0.05, segs_bisel=1))
        piezas.append(lb.caja("Pilastra_Banda", (1.30, 1.12, 0.20), (0.0, pz, 1.25), m_hormigon, bisel=0.02, segs_bisel=1))
        piezas.append(lb.caja("Pilastra_Capitel", (1.36, 1.20, 0.28), (0.0, pz, 4.52), m_hormigon, bisel=0.04, segs_bisel=1))
        piezas.append(lb.caja("Pilastra_Remate", (0.86, 0.86, 0.24), (0.0, pz, 4.76), m_hormigon, bisel=0.06, segs_bisel=1))

    # 4. Tubería eléctrica adosada en el lado hacia vías (-X) + cajas de registro y bajantes
    piezas.append(lb.caja("Muro_TuboElec", (0.07, LARGO, 0.07), (-0.39, 0.0, base_z + alto_muro - 0.34), m_hierro, subdiv_y=16))
    for cy in (-5.33, 5.33):
        piezas.append(lb.caja("Muro_CajaRegistro", (0.14, 0.42, 0.56), (-0.42, cy, base_z + alto_muro - 0.38), m_hierro, bisel=0.02, segs_bisel=1))
        piezas.append(lb.cilindro("Muro_Bajante", 0.06, 0.06, alto_muro, (-0.39, cy - 0.28, base_z + alto_muro * 0.5), m_hierro, eje="Z", lados=8))

    # 5. Verja superior de hierro forjado con barrotes verticales y picas (16 cortes en barras)
    for bz in (4.58, 5.02):
        piezas.append(lb.caja("Verja_Travesano", (0.08, LARGO, 0.07), (-0.10, 0.0, bz), m_hierro, subdiv_y=16))
    for iy in range(-28, 29):
        vy = iy * 0.55
        if any(abs(vy - pz) < 0.58 for pz in (-10.67, 0.0, 10.67)):
            continue
        es_poste = (iy % 4 == 0)
        w_b = 0.075 if es_poste else 0.042
        piezas.append(lb.caja("Verja_Barrote", (w_b, w_b, 0.66), (-0.10, vy, 4.82), m_hierro))
        if es_poste:
            piezas.append(lb.esfera("Verja_Remate", 0.055, (-0.10, vy, 5.18), m_hierro, subdiv=1))

    obj = lb.unir(piezas, "Muro_Corredor")
    obj.location = (0.0, 0.0, 0.0)
    lb.suavizar_por_angulo(obj, 35.0)
    return obj


def main():
    args = lb.parsear_args_modelo("Modelos/Minijuego_Correr/muro_corredor.glb")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    obj = construir()
    lb.exportar_glb(obj, args.salida)
    if args.blend:
        lb.guardar_blend(args.blend)
    if args.render and not args.sin_render:
        lb.render_cuatro_vistas(obj, args.render, con_referencia=True)


if __name__ == "__main__":
    main()
