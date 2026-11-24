"""
Mochila Jetpack doble propulsor estilizada (usable en power-up y en la espalda
del Sim en Runner_Personaje_3D.gd). Incluye placa dorsal, doble depósito
presurizado, manómetro, colectores de combustible, asa superior y toberas.
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
    m_chasis = lb.material("Jetpack_Chasis", "#1e293b", rough=0.45, metal=0.58)
    m_metal = lb.material("Jetpack_Metal", "#94a3b8", rough=0.32, metal=0.78)
    m_coral = lb.material("Jetpack_Tanque", "#fb3868", rough=0.24, metal=0.28,
                          emision="#e11d48", emision_fuerza=0.45)
    m_cian = lb.material("Jetpack_AcentoCian", "#38bdf8", rough=0.20, metal=0.25,
                         emision="#0ea5e9", emision_fuerza=1.8)
    m_amber = lb.material("Jetpack_Nucleo", "#fde047", rough=0.16, metal=0.0,
                          emision="#fb923c", emision_fuerza=3.0)

    piezas = []

    # 1. Placa dorsal ergonómica y núcleo central con manómetro (-Y en Blender = +Z espalda visible hacia cámara)
    piezas.append(lb.caja("Jet_Placa", (0.48, 0.18, 0.58), (0.0, 0.0, 0.0), m_chasis, bisel=0.035, segs_bisel=2))
    piezas.append(lb.caja("Jet_CubiertaTrasera", (0.34, 0.08, 0.42), (0.0, -0.11, 0.02), m_metal, bisel=0.02, segs_bisel=1))
    piezas.append(lb.cilindro("Jet_Manometro", 0.075, 0.075, 0.045, (0.0, -0.15, 0.08), m_chasis, eje="Y", lados=14, bisel_tapa=0.008))
    piezas.append(lb.cilindro("Jet_EsferaMano", 0.055, 0.055, 0.02, (0.0, -0.175, 0.08), m_cian, eje="Y", lados=12))

    # Asa / barra antivuelco superior
    pts_asa = [(-0.22, -0.04, 0.24), (-0.18, -0.08, 0.36), (0.18, -0.08, 0.36), (0.22, -0.04, 0.24)]
    piezas.append(lb.tubo_ruta("Jet_Asa", pts_asa, 0.026, m_metal, lados=8, catmull_subdiv=2))

    # 2. Dos depósitos presurizados laterales con cúpula, abrazaderas, tubería y tobera
    for side in (-1.0, 1.0):
        tx, ty = side * 0.25, -0.09
        # Botella principal
        piezas.append(lb.cilindro("Jet_Botella", 0.125, 0.125, 0.48, (tx, ty, -0.02), m_coral, eje="Z", lados=16, bisel_tapa=0.015))
        # Cúpula superior y collarín cian
        piezas.append(lb.esfera("Jet_Cupula", 0.122, (tx, ty, 0.22), m_cian, escala=(1.0, 1.0, 0.72), subdiv=2))
        for rz in (-0.14, 0.10):
            piezas.append(lb.toro("Jet_Abrazadera", 0.130, 0.016, (tx, ty, rz), m_chasis, eje="Z", segs_mayor=16, segs_menor=6))

        # Tubo colector de combustible hacia el núcleo central
        pts_tubo = [(tx * 0.45, ty + 0.02, 0.16), (tx * 0.72, ty - 0.08, 0.18), (tx, ty, 0.14)]
        piezas.append(lb.tubo_ruta("Jet_Tubo", pts_tubo, 0.022, m_metal, lados=8))

        # Tobera acampanada inferior + anillo de refrigeración + núcleo incandescente
        piezas.append(lb.cilindro("Jet_Tobera", 0.118, 0.072, 0.17, (tx, ty, -0.34), m_chasis, eje="Z", lados=14, bisel_tapa=0.008))
        piezas.append(lb.toro("Jet_AroTobera", 0.108, 0.012, (tx, ty, -0.39), m_metal, eje="Z", segs_mayor=14, segs_menor=6))
        piezas.append(lb.cilindro("Jet_NucleoLuz", 0.082, 0.052, 0.04, (tx, ty, -0.42), m_amber, eje="Z", lados=12))

        # Tirantes frontales del arnés (+Y hacia el pecho / -Z en Godot)
        piezas.append(lb.caja("Jet_Arnes", (0.065, 0.08, 0.48), (side * 0.15, 0.10, 0.04), m_chasis, bisel=0.01, segs_bisel=1))

    obj = lb.unir(piezas, "Jetpack")
    obj.location = (0.0, 0.0, 0.0)
    lb.suavizar_por_angulo(obj, 35.0)
    return obj


def main():
    args = lb.parsear_args_modelo("Modelos/Minijuego_Correr/jetpack.glb")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    obj = construir()
    lb.exportar_glb(obj, args.salida)
    if args.blend:
        lb.guardar_blend(args.blend)
    if args.render and not args.sin_render:
        lb.render_cuatro_vistas(obj, args.render, con_referencia=False)


if __name__ == "__main__":
    main()
