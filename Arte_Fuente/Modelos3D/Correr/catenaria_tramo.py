"""
Tramo de catenaria ferroviaria de 32 m con hilo de contacto, cable sustentador y péndolas.
Origen en el hilo inferior de contacto (Z = 0), sustentador arriba en Z = 0.58 m.
"""

import os
import sys

import bpy

DIR_ACTUAL = os.path.dirname(os.path.abspath(__file__))
if DIR_ACTUAL not in sys.path:
    sys.path.insert(0, DIR_ACTUAL)

import lib_blender as lb

LARGO = 32.0


def construir():
    m_cable = lb.material("Catenaria_Cable", "#5b6d85", rough=0.52, metal=0.45)
    m_aislador = lb.material("Catenaria_Pinza", "#94a3b8", rough=0.38, metal=0.65)

    piezas = []
    # Hilo inferior de contacto + cable sustentador superior (16 cortes en Y)
    piezas.append(lb.caja("Hilo_Contacto", (0.026, LARGO, 0.026), (0.0, 0.0, 0.013), m_cable, subdiv_y=16))
    piezas.append(lb.caja("Cable_Sustentador", (0.024, LARGO, 0.024), (0.0, 0.0, 0.56), m_cable, subdiv_y=16))

    # Péndolas verticales con pinzas cada 4 m
    for py in (-14.0, -10.0, -6.0, -2.0, 2.0, 6.0, 10.0, 14.0):
        piezas.append(lb.caja("Pendola", (0.016, 0.016, 0.54), (0.0, py, 0.285), m_cable))
        piezas.append(lb.caja("Pinza_Sup", (0.036, 0.055, 0.045), (0.0, py, 0.56), m_aislador))
        piezas.append(lb.caja("Pinza_Inf", (0.036, 0.055, 0.045), (0.0, py, 0.022), m_aislador))

    obj = lb.unir(piezas, "Catenaria_Tramo")
    obj.location = (0.0, 0.0, 0.0)
    lb.suavizar_por_angulo(obj, 35.0)
    return obj


def main():
    args = lb.parsear_args_modelo("Modelos/Minijuego_Correr/catenaria_tramo.glb")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    obj = construir()
    lb.exportar_glb(obj, args.salida)
    if args.blend:
        lb.guardar_blend(args.blend)
    if args.render and not args.sin_render:
        lb.render_cuatro_vistas(obj, args.render, con_referencia=False)


if __name__ == "__main__":
    main()
