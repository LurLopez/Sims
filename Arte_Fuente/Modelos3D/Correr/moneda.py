"""
Moneda dorada grande y muy amarilla estilo Subway Surfers para PARK RUSH 3D.
Aro exterior biselado grueso, cara interior rehundida en amarillo oro intenso
y estrella 3D en relieve pronunciado para máxima visibilidad en carrera.
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
    # Amarillos intensos y saturados (sin emisión forzada que lave el color en Blender)
    m_oro = lb.material("Moneda_Oro", "#ffd800", rough=0.20, metal=0.24)
    m_fondo = lb.material("Moneda_Fondo", "#d99b00", rough=0.26, metal=0.20)
    m_estrella = lb.material("Moneda_Estrella", "#ffef2e", rough=0.14, metal=0.18)

    piezas = []

    # 1. Aro exterior torneado grueso y redondeado (radio 0.58 m -> 1.16 m de diámetro)
    perfil_aro = [
        (0.38, 0.044),
        (0.415, 0.094),
        (0.45, 0.106),
        (0.54, 0.106),
        (0.575, 0.076),
        (0.585, 0.034),
        (0.585, -0.034),
        (0.575, -0.076),
        (0.54, -0.106),
        (0.45, -0.106),
        (0.415, -0.094),
        (0.38, -0.044),
    ]
    piezas.append(lb.revolucion(
        "Moneda_Aro", perfil_aro, (0.0, 0.0, 0.0), m_oro,
        lados=32, rot=(math.radians(90), 0.0, 0.0)
    ))

    # 2. Disco interior rehundido para dar profundidad real al relieve
    perfil_fondo = [
        (0.0, 0.046),
        (0.39, 0.046),
        (0.39, -0.046),
        (0.0, -0.046),
    ]
    piezas.append(lb.revolucion(
        "Moneda_Fondo", perfil_fondo, (0.0, 0.0, 0.0), m_fondo,
        lados=32, rot=(math.radians(90), 0.0, 0.0)
    ))

    # 3. Estrella 3D gruesa y con relieve pronunciado por ambas caras
    piezas.append(lb.estrella_3d(
        "Moneda_Estrella", 0.34, 0.155, 0.25,
        (0.0, 0.0, 0.0), m_estrella, puntas=5, bisel_cara=0.28
    ))

    obj = lb.unir(piezas, "Moneda")
    obj.location = (0.0, 0.0, 0.0)
    lb.suavizar_por_angulo(obj, 35.0)
    return obj


def main():
    args = lb.parsear_args_modelo("Modelos/Minijuego_Correr/moneda.glb")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    obj = construir()
    lb.exportar_glb(obj, args.salida)
    if args.blend:
        lb.guardar_blend(args.blend)
    if args.render and not args.sin_render:
        lb.render_cuatro_vistas(obj, args.render, con_referencia=False)


if __name__ == "__main__":
    main()
