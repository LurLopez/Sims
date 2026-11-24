"""
Tabla Hoverboard freestyle esculpida con proa/popa curvada, almohadilla de agarre,
rieles laterales neón y turbinas repulsoras inferiores (PARK RUSH 3D).
Se usa tanto como power-up flotante como bajo los pies del Sim.
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


def _tabla_curva_deck(mat_cuerpo, mat_grip):
    """Cubierta esculpida en forma de surf/skate con rocker en proa (-Y) y popa (+Y)."""
    # Secciones a lo largo de Y (-0.74 proa .. +0.74 popa): (y, ancho_x, z_centro, grosor)
    secciones = [
        (-0.74, 0.08, 0.075, 0.036),
        (-0.64, 0.34, 0.045, 0.052),
        (-0.46, 0.50, 0.012, 0.068),
        (-0.20, 0.54, 0.000, 0.072),
        (0.00,  0.54, 0.000, 0.072),
        (0.20,  0.54, 0.000, 0.072),
        (0.46,  0.50, 0.012, 0.068),
        (0.64,  0.34, 0.045, 0.052),
        (0.74,  0.08, 0.075, 0.036),
    ]
    bm = bmesh.new()
    anillos = []
    for y, w, zc, g in secciones:
        hw = w * 0.5
        hz = g * 0.5
        pts = [
            (-hw * 0.72, y, zc - hz),
            (hw * 0.72, y, zc - hz),
            (hw, y, zc),
            (hw * 0.76, y, zc + hz),
            (-hw * 0.76, y, zc + hz),
            (-hw, y, zc),
        ]
        anillos.append([bm.verts.new(p) for p in pts])

    n = 6
    for i in range(len(anillos) - 1):
        a, b = anillos[i], anillos[i + 1]
        for j in range(n):
            k = (j + 1) % n
            f = bm.faces.new((a[j], a[k], b[k], b[j]))
            # La cara superior (j == 3) usa el material grip antideslizante
            f.material_index = 1 if j == 3 else 0

    f_f = bm.faces.new(tuple(reversed(anillos[0])))
    f_f.material_index = 0
    f_b = bm.faces.new(tuple(anillos[-1]))
    f_b.material_index = 0
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)

    obj = lb.finalizar_bmesh("Hoverboard_Deck", bm)
    obj.data.materials.append(mat_cuerpo)
    obj.data.materials.append(mat_grip)
    return obj


def construir():
    m_cuerpo = lb.material("Hover_Cuerpo", "#1e293b", rough=0.38, metal=0.35)
    m_grip = lb.material("Hover_Grip", "#0f172a", rough=0.86, metal=0.05)
    m_cian = lb.material("Hover_NeonCian", "#38bdf8", rough=0.18, metal=0.25,
                         emision="#0ea5e9", emision_fuerza=2.2)
    m_coral = lb.material("Hover_NeonCoral", "#fb3868", rough=0.18, metal=0.25,
                          emision="#e11d48", emision_fuerza=2.0)
    m_metal = lb.material("Hover_Metal", "#94a3b8", rough=0.32, metal=0.72)

    piezas = []
    piezas.append(_tabla_curva_deck(m_cuerpo, m_grip))

    # 1. Rieles laterales luminosos cian (izquierda) y coral (derecha)
    pts_l = [(-0.20, -0.62, 0.042), (-0.275, -0.35, 0.008), (-0.28, 0.0, 0.0), (-0.275, 0.35, 0.008), (-0.20, 0.62, 0.042)]
    pts_r = [(0.20, -0.62, 0.042), (0.275, -0.35, 0.008), (0.28, 0.0, 0.0), (0.275, 0.35, 0.008), (0.20, 0.62, 0.042)]
    piezas.append(lb.tubo_ruta("Riel_Cian", pts_l, 0.026, m_cian, lados=8, catmull_subdiv=3))
    piezas.append(lb.tubo_ruta("Riel_Coral", pts_r, 0.026, m_coral, lados=8, catmull_subdiv=3))

    # 2. Franja gráfica central y pads de pie en cubierta
    piezas.append(lb.caja("Deck_Franja", (0.10, 1.05, 0.012), (0.0, 0.0, 0.038), m_coral, bisel=0.004, segs_bisel=1))
    piezas.append(lb.caja("Deck_Emblema", (0.22, 0.22, 0.015), (0.0, 0.0, 0.040), m_cian, bisel=0.004, segs_bisel=1, rot=(0.0, 0.0, math.radians(45))))

    # 3. Dos turbinas repulsoras bajo la tabla (proa +Y y popa -Y en Blender = -Z..+Z en Godot)
    for ty, mat_t in ((0.42, m_cian), (-0.42, m_coral)):
        piezas.append(lb.cilindro("Turbina_Carcasa", 0.145, 0.165, 0.055, (0.0, ty, -0.048), m_metal, eje="Z", lados=16, bisel_tapa=0.008))
        piezas.append(lb.toro("Turbina_AroLuz", 0.135, 0.020, (0.0, ty, -0.070), mat_t, eje="Z", segs_mayor=16, segs_menor=6))
        piezas.append(lb.cilindro("Turbina_Nucleo", 0.055, 0.055, 0.045, (0.0, ty, -0.058), m_cuerpo, eje="Z", lados=10))

    # Aletas traseras estabilizadoras en popa (-Y en Blender = +Z detrás en Godot)
    for ax in (-0.14, 0.14):
        piezas.append(lb.caja("Aleta_Trasera", (0.022, 0.18, 0.075), (ax, -0.56, -0.05), m_metal, rot=(-math.radians(15), 0.0, 0.0)))

    obj = lb.unir(piezas, "Hoverboard")
    obj.location = (0.0, 0.0, 0.0)
    lb.suavizar_por_angulo(obj, 35.0)
    return obj


def main():
    args = lb.parsear_args_modelo("Modelos/Minijuego_Correr/hoverboard.glb")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    obj = construir()
    lb.exportar_glb(obj, args.salida)
    if args.blend:
        lb.guardar_blend(args.blend)
    if args.render and not args.sin_render:
        lb.render_cuatro_vistas(obj, args.render, con_referencia=False)


if __name__ == "__main__":
    main()
