"""
Pórtico de catenaria industrial con celosía Warren 3D, protecciones amarillas,
aisladores cerámicos y 3 semáforos ferroviarios colgantes con viseras (PARK RUSH 3D).
"""

import math
import os
import sys

import bpy

DIR_ACTUAL = os.path.dirname(os.path.abspath(__file__))
if DIR_ACTUAL not in sys.path:
    sys.path.insert(0, DIR_ACTUAL)

import lib_blender as lb

SPAN = 13.80
ARCO_Z = 8.25


def construir():
    m_acero = lb.material("Portico_Acero", "#3b495c", rough=0.44, metal=0.64)
    m_osc = lb.material("Portico_Oscuro", "#1e293b", rough=0.52, metal=0.52)
    m_amarillo = lb.material("Portico_Amarillo", "#facc15", rough=0.38, metal=0.14)
    m_hormigon = lb.material("Portico_Hormigon", "#b5afa5", rough=0.84, metal=0.04)
    m_rojo = lb.material("Portico_LuzRoja", "#ff5252", rough=0.14, metal=0.0,
                         emision="#ef4444", emision_fuerza=4.0)
    m_ambar = lb.material("Portico_LuzAmbar", "#fde047", rough=0.14, metal=0.0,
                          emision="#f59e0b", emision_fuerza=4.0)
    m_verde = lb.material("Portico_LuzVerde", "#4ade80", rough=0.14, metal=0.0,
                          emision="#22c55e", emision_fuerza=4.2)

    piezas = []
    hx = SPAN * 0.5  # 6.90 m

    # 1. Columnas laterales en celosía/H con plintos, placas base y collar amarillo
    for side in (-1, 1):
        cx = side * hx
        piezas.append(lb.caja("Plinto", (0.78, 0.78, 0.30), (cx, 0.0, 0.15), m_hormigon, bisel=0.03, segs_bisel=1))
        piezas.append(lb.caja("PlacaBase", (0.60, 0.60, 0.06), (cx, 0.0, 0.33), m_osc, bisel=0.01, segs_bisel=1))
        # Protector de seguridad amarillo en parte baja
        piezas.append(lb.caja("GuardiaAmarilla", (0.56, 0.56, 1.15), (cx, 0.0, 0.96), m_amarillo, bisel=0.02, segs_bisel=1))
        # Columna principal perfil H
        piezas.append(lb.caja("Columna_Alma", (0.14, 0.38, ARCO_Z + 0.15), (cx, 0.0, (ARCO_Z + 0.70) * 0.5), m_acero))
        for sx_a in (-0.15, 0.15):
            piezas.append(lb.caja("Columna_Ala", (0.08, 0.42, ARCO_Z + 0.15), (cx + sx_a, 0.0, (ARCO_Z + 0.70) * 0.5), m_acero))
        # Cartela angular superior hacia el puente de celosía
        piezas.append(lb.caja("Cartela_Esquina", (0.95, 0.22, 0.14), (cx - side * 0.48, 0.0, ARCO_Z - 0.68), m_acero, rot=(0.0, side * math.radians(42), 0.0)))

    # 2. Viga de celosía superior (cordón sup/inf + caras en X/Y + diagonales Warren)
    for dy in (-0.18, 0.18):
        piezas.append(lb.caja("Cordon_Sup", (SPAN + 0.45, 0.14, 0.18), (0.0, dy, ARCO_Z + 0.34), m_acero, bisel=0.01, segs_bisel=1))
        piezas.append(lb.caja("Cordon_Inf", (SPAN + 0.45, 0.14, 0.18), (0.0, dy, ARCO_Z - 0.34), m_acero, bisel=0.01, segs_bisel=1))
        for ix in range(-6, 7):
            dx = ix * 1.04
            piezas.append(lb.caja("Montante_Cel", (0.08, 0.08, 0.68), (dx, dy, ARCO_Z), m_acero))
            if ix < 6:
                ang_d = math.radians(48 if ix % 2 == 0 else -48)
                piezas.append(lb.caja("Diagonal_Cel", (0.08, 0.07, 0.92), (dx + 0.52, dy, ARCO_Z), m_acero, rot=(0.0, ang_d, 0.0)))

    # Travesaños superiores/inferiores entre los dos planos de celosía
    for ix in range(-6, 7):
        dx = ix * 1.04
        piezas.append(lb.caja("Travesano_Sup", (0.09, 0.40, 0.09), (dx, 0.0, ARCO_Z + 0.34), m_acero))
        piezas.append(lb.caja("Travesano_Inf", (0.09, 0.40, 0.09), (dx, 0.0, ARCO_Z - 0.34), m_acero))

    # 3. Aisladores cerámicos y ménsulas de catenaria sobre vías laterales (±2.70 m)
    for cx_cat in (-2.70, 2.70):
        piezas.append(lb.cilindro("Aislador_V", 0.075, 0.075, 0.24, (cx_cat, 0.0, ARCO_Z - 0.50), m_hormigon, eje="Z", lados=10))
        piezas.append(lb.caja("Pinza_Cat", (0.12, 0.18, 0.08), (cx_cat, 0.0, ARCO_Z - 0.64), m_osc))

    # 4. Tres semáforos colgantes ferroviarios con placa trasera, viseras y focos
    for carril_x, es_centro in ((-2.70, False), (0.0, True), (2.70, False)):
        sz = ARCO_Z - 0.92
        # Soporte colgante desde la celosía
        piezas.append(lb.caja("Semaforo_Mastil", (0.09, 0.09, 0.55), (carril_x, 0.14, ARCO_Z - 0.56), m_osc))
        # Placa trasera redondeada y caja del semáforo
        piezas.append(lb.caja("Semaforo_Placa", (0.64, 0.06, 1.12), (carril_x, 0.10, sz), m_osc, bisel=0.05, segs_bisel=2))
        piezas.append(lb.caja("Semaforo_Cuerpo", (0.44, 0.34, 0.94), (carril_x, 0.0, sz), m_osc, bisel=0.03, segs_bisel=1))
        # Dos aspectos luminosos + viseras parasol
        focos = [
            (sz + 0.22, m_ambar if es_centro else m_rojo),
            (sz - 0.22, m_verde),
        ]
        for fz, mat_f in focos:
            # Lente frontal (-Y mirando al corredor)
            piezas.append(lb.esfera("Semaforo_Lente", 0.135, (carril_x, -0.17, fz), mat_f, escala=(1.0, 0.45, 1.0), subdiv=2))
            # Visera superior curva
            piezas.append(lb.cilindro("Semaforo_Visera", 0.16, 0.15, 0.18, (carril_x, -0.22, fz + 0.04), m_osc, eje="Y", lados=12))

    obj = lb.unir(piezas, "Portico_Catenaria")
    obj.location = (0.0, 0.0, 0.0)
    lb.suavizar_por_angulo(obj, 35.0)
    return obj


def main():
    args = lb.parsear_args_modelo("Modelos/Minijuego_Correr/portico_catenaria.glb")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    obj = construir()
    lb.exportar_glb(obj, args.salida)
    if args.blend:
        lb.guardar_blend(args.blend)
    if args.render and not args.sin_render:
        lb.render_cuatro_vistas(obj, args.render, con_referencia=True)


if __name__ == "__main__":
    main()
