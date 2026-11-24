"""
Accesorio de Súper Zapatillas acoplable al pie del Sim en Runner_Personaje_3D.gd:
suela propulsora neón + tobillera luminosa + par de alas estilizadas laterales.
Reemplaza las cajas verdes de _sneaker_glow en el personaje jugable.
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
    m_verde = lb.material("AlasZap_Verde", "#22ee74", rough=0.24, metal=0.18,
                          emision="#16a34a", emision_fuerza=1.2)
    m_blanco = lb.material("AlasZap_Blanco", "#f8fafc", rough=0.30, metal=0.06,
                           emision="#d1fae5", emision_fuerza=0.45)
    m_osc = lb.material("AlasZap_Borde", "#1e293b", rough=0.52, metal=0.35)

    piezas = []

    # 1. Plataforma propulsora envolvente bajo la zapatilla del Sim (+Y en Blender = -Z puntera en Godot)
    piezas.append(lb.caja("Booster_Suela", (0.22, 0.34, 0.055), (0.0, 0.03, -0.055), m_verde, bisel=0.018, segs_bisel=2))
    piezas.append(lb.caja("Booster_Marco", (0.23, 0.35, 0.025), (0.0, 0.03, -0.032), m_osc, bisel=0.008, segs_bisel=1))

    # 2. Collarín de tobillo con estabilizadores laterales conectados a la suela
    piezas.append(lb.toro("Booster_Tobillera", 0.115, 0.024, (0.0, -0.02, 0.08), m_verde, eje="Z", segs_mayor=18, segs_menor=8))
    for side in (-1.0, 1.0):
        piezas.append(lb.caja("Booster_Tirante", (0.024, 0.045, 0.12), (side * 0.105, -0.02, 0.025), m_osc, bisel=0.006, segs_bisel=1))

    # 3. Par de alas de 3 plumas proyectándose hacia atrás (-Y en Blender = +Z detrás del pie en Godot)
    for side in (-1.0, 1.0):
        for i_p, (largo, dz, spread) in enumerate(((0.28, 0.12, 0.09), (0.22, 0.05, 0.08), (0.16, -0.01, 0.06))):
            pts = [
                (side * 0.105, -0.02, 0.05 + dz * 0.25),
                (side * (0.105 + spread * 0.7), -0.02 - largo * 0.55, 0.06 + dz * 0.65),
                (side * (0.105 + spread), -0.02 - largo, 0.08 + dz),
            ]
            piezas.append(lb.tubo_ruta(f"Ala_{i_p}", pts, [0.022, 0.028, 0.008], m_blanco, lados=8, escala_ab=(0.45, 1.35)))

    obj = lb.unir(piezas, "Alas_Zapatilla")
    obj.location = (0.0, 0.0, 0.0)
    lb.suavizar_por_angulo(obj, 35.0)
    return obj


def main():
    args = lb.parsear_args_modelo("Modelos/Minijuego_Correr/alas_zapatilla.glb")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    obj = construir()
    lb.exportar_glb(obj, args.salida)
    if args.blend:
        lb.guardar_blend(args.blend)
    if args.render and not args.sin_render:
        lb.render_cuatro_vistas(obj, args.render, con_referencia=False)


if __name__ == "__main__":
    main()
