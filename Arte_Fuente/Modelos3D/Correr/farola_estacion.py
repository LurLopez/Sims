"""
Farola clásica de estación de hierro fundido con pedestal octogonal, fuste estriado,
brazo curvo en cuello de cisne, voluta forjada y linterna hexagonal brillante.
El brazo apunta hacia -X (se gira 180° en Godot según el andén).
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
    m_poste = lb.material("Farola_Poste", "#334155", rough=0.44, metal=0.62)
    m_osc = lb.material("Farola_Base", "#1a222f", rough=0.52, metal=0.55)
    m_luz = lb.material("Farola_Luz", "#fff8dc", rough=0.12, metal=0.0,
                        emision="#ffd166", emision_fuerza=4.5)

    piezas = []

    # 1. Pedestal octogonal escalonado con collarines
    perfil_base = [
        (0.28, 0.00), (0.28, 0.14), (0.22, 0.22), (0.22, 0.62),
        (0.25, 0.68), (0.17, 0.78), (0.14, 1.05), (0.12, 1.12),
        (0.0, 1.12),
    ]
    piezas.append(lb.revolucion("Farola_Pedestal", perfil_base, (0.0, 0.0, 0.0), m_osc, lados=8))

    # 2. Fuste troncocónico estriado con anillos decorativos
    piezas.append(lb.cilindro("Farola_Fuste", 0.115, 0.078, 4.10, (0.0, 0.0, 3.15), m_poste, eje="Z", lados=12))
    for rz, rr in ((2.40, 0.125), (3.85, 0.110), (5.16, 0.105)):
        piezas.append(lb.toro("Farola_Anillo", rr, 0.022, (0.0, 0.0, rz), m_osc, eje="Z", segs_mayor=14, segs_menor=6))

    # 3. Brazo curvo en cuello de cisne hacia -X + ménsula de refuerzo forjada
    pts_brazo = [
        (0.0, 0.0, 5.15),
        (-0.18, 0.0, 5.60),
        (-0.62, 0.0, 5.95),
        (-1.12, 0.0, 6.02),
        (-1.42, 0.0, 5.82),
        (-1.46, 0.0, 5.66),
    ]
    piezas.append(lb.tubo_ruta("Farola_Brazo", pts_brazo, [0.075, 0.068, 0.058, 0.050, 0.045, 0.045], m_poste, lados=10, catmull_subdiv=4))

    pts_voluta = [
        (0.0, 0.0, 4.68),
        (-0.32, 0.0, 5.02),
        (-0.56, 0.0, 5.42),
        (-0.74, 0.0, 5.94),
    ]
    piezas.append(lb.tubo_ruta("Farola_Voluta", pts_voluta, 0.028, m_osc, lados=8, catmull_subdiv=3))

    # 4. Linterna hexagonal acristalada colgante en (-1.46, 0.0, 5.66)
    lx, lz = -1.46, 5.38
    # Cúpula superior y pináculo
    perfil_linterna_top = [
        (0.0, lz + 0.36), (0.04, lz + 0.28), (0.28, lz + 0.16), (0.31, lz + 0.12), (0.0, lz + 0.12),
    ]
    piezas.append(lb.revolucion("Linterna_Techo", perfil_linterna_top, (0.0, 0.0, 0.0), m_osc, lados=6))
    # Cuerpo luminoso hexagonal
    piezas.append(lb.cilindro("Linterna_Cristal", 0.16, 0.22, 0.30, (lx, 0.0, lz - 0.02), m_luz, eje="Z", lados=6))
    # 6 nervios exteriores de la jaula
    for k in range(6):
        ang = math.tau * k / 6
        px = lx + math.cos(ang) * 0.21
        py = math.sin(ang) * 0.21
        piezas.append(lb.caja("Linterna_Nervio", (0.025, 0.025, 0.32), (px, py, lz - 0.02), m_osc, rot=(0.0, -0.18 * math.cos(ang), 0.18 * math.sin(ang))))
    # Remate inferior
    piezas.append(lb.cilindro("Linterna_Base", 0.05, 0.17, 0.10, (lx, 0.0, lz - 0.21), m_osc, eje="Z", lados=6))
    # Ajustar centro de revolución del techo de linterna al X correcto
    for p in piezas:
        if p.name == "Linterna_Techo":
            p.location.x = lx
            bpy.context.view_layer.objects.active = p
            p.select_set(True)
            bpy.ops.object.transform_apply(location=True, rotation=False, scale=False)
            p.select_set(False)

    obj = lb.unir(piezas, "Farola_Estacion")
    obj.location = (0.0, 0.0, 0.0)
    lb.suavizar_por_angulo(obj, 35.0)
    return obj


def main():
    args = lb.parsear_args_modelo("Modelos/Minijuego_Correr/farola_estacion.glb")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    obj = construir()
    lb.exportar_glb(obj, args.salida)
    if args.blend:
        lb.guardar_blend(args.blend)
    if args.render and not args.sin_render:
        lb.render_cuatro_vistas(obj, args.render, con_referencia=True)


if __name__ == "__main__":
    main()
