"""
Kit de morro activo para tren en movimiento (TREN_MOVIL) de PARK RUSH 3D.
Se acopla sobre el vagón base: quitanieves de peligro, faros intensos,
letrero luminoso y balizas rojas de techo.
"""

import math
import os
import sys

import bpy

DIR_ACTUAL = os.path.dirname(os.path.abspath(__file__))
if DIR_ACTUAL not in sys.path:
    sys.path.insert(0, DIR_ACTUAL)

import lib_blender as lb

HL = 6.75
ALTO = 3.05


def construir():
    m_metal_osc = lb.material("Movil_MetalOsc", "#1e293b", rough=0.50, metal=0.55)
    m_rojo = lb.material("Movil_Rojo", "#dc2626", rough=0.35, metal=0.10)
    m_blanco = lb.material("Movil_Blanco", "#f8fafc", rough=0.32, metal=0.05)
    m_faro = lb.material("Movil_Faro", "#fffbe0", rough=0.10, metal=0.0,
                         emision="#ffe88a", emision_fuerza=6.5)
    m_piloto = lb.material("Movil_PilotoRojo", "#ff4d4d", rough=0.12, metal=0.0,
                           emision="#ef4444", emision_fuerza=5.5)

    piezas = []

    # 1. Quitanieves / faldón en V de peligro frontal (-Y en Blender -> +Z en Godot)
    ang_v = math.radians(14)
    tan_v = math.tan(ang_v)
    off_frente = 0.124 / math.cos(ang_v)
    for side in (-1.0, 1.0):
        piezas.append(lb.caja("Quitanieves_Ala", (1.12, 0.24, 0.28), (side * 0.54, -HL - 0.14, 0.36), m_metal_osc, bisel=0.022, segs_bisel=1, rot=(0.0, 0.0, side * ang_v)))
    # Cuña central de unión en el vértice de la V para sellar la punta delantera (sin coplanaridad)
    piezas.append(lb.caja("Quitanieves_Vertice", (0.14, 0.14, 0.296), (0.0, -HL - 0.282, 0.36), m_metal_osc, bisel=0.014, segs_bisel=1, rot=(0.0, 0.0, math.radians(45))))
    for i, sx in enumerate((-0.84, -0.56, -0.28, 0.0, 0.28, 0.56, 0.84)):
        mat_r = m_rojo if i % 2 == 0 else m_blanco
        y_ala = -HL - 0.14 + (abs(sx) - 0.54) * tan_v - off_frente
        ang_z = ang_v if sx > 0 else (-ang_v if sx < 0 else 0.0)
        ry_raya = 0.0 if sx == 0.0 else math.radians(18 if sx > 0 else -18)
        piezas.append(lb.caja("Quitanieves_Raya", (0.16, 0.032, 0.22), (sx, y_ala, 0.36), mat_r, rot=(0.0, ry_raya, ang_z)))

    # 2. Aro luminoso ampliado en ambos faros frontales (alineados a -6.75 m, z = 0.90 m)
    for lx in (-0.68, 0.68):
        piezas.append(lb.cilindro("Movil_Faro_Base", 0.215, 0.195, 0.10, (lx, -HL - 0.04, 0.90), m_metal_osc, eje="Y", lados=16, bisel_tapa=0.012))
        piezas.append(lb.esfera("Movil_Faro_Glow", 0.160, (lx, -HL - 0.09, 0.90), m_faro, escala=(1.0, 0.55, 1.0), subdiv=2))

    # 3. Barra luminosa superior sobre el faldón bajo el parabrisas (z = 1.38 m, y = -6.72 m)
    piezas.append(lb.caja("Movil_Barra_Marco", (1.52, 0.10, 0.15), (0.0, -HL + 0.02, 1.38), m_metal_osc, bisel=0.014, segs_bisel=1))
    piezas.append(lb.caja("Movil_Barra_Luz", (1.38, 0.045, 0.09), (0.0, -HL - 0.03, 1.38), m_faro))

    # 4. Doble baliza roja rotativa sobre el techo delantero (TREN_MOVIL no tiene rampa)
    for bx in (-0.52, 0.52):
        piezas.append(lb.cilindro("Baliza_Base", 0.14, 0.12, 0.08, (bx, -HL + 1.25, ALTO + 0.04), m_metal_osc, eje="Z", lados=14, bisel_tapa=0.01))
        piezas.append(lb.cilindro("Baliza_Domo", 0.105, 0.085, 0.16, (bx, -HL + 1.25, ALTO + 0.15), m_piloto, eje="Z", lados=14, bisel_tapa=0.02))
        piezas.append(lb.toro("Baliza_Jaula", 0.12, 0.012, (bx, -HL + 1.25, ALTO + 0.16), m_metal_osc, eje="Z", segs_mayor=14, segs_menor=6))

    obj = lb.unir(piezas, "Tren_Movil_Extra")
    obj.location = (0.0, 0.0, 0.0)
    lb.suavizar_por_angulo(obj, 35.0)
    return obj


def main():
    args = lb.parsear_args_modelo("Modelos/Minijuego_Correr/tren_movil_extra.glb")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    obj = construir()
    lb.exportar_glb(obj, args.salida)
    if args.blend:
        lb.guardar_blend(args.blend)
    if args.render and not args.sin_render:
        lb.render_cuatro_vistas(obj, args.render, con_referencia=False)


if __name__ == "__main__":
    main()
