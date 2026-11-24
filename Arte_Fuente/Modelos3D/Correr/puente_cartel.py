"""
Puente ferroviario de celosía metálica en arco con valla publicitaria iluminada,
pasarelas, barandillas, focos orientables y pilas laterales (PARK RUSH 3D).
Se coloca centrado en Y=8.40 m en Godot; cara del cartel mirando a -Y Blender (= +Z Godot).
"""

import math
import os
import sys

import bpy
from mathutils import Vector

DIR_ACTUAL = os.path.dirname(os.path.abspath(__file__))
if DIR_ACTUAL not in sys.path:
    sys.path.insert(0, DIR_ACTUAL)

import lib_blender as lb

SPAN = 23.60
ANCHO_PUENTE = 5.40
RAIZ_PROYECTO = os.path.abspath(os.path.join(DIR_ACTUAL, "..", "..", ".."))
DIR_TEX = os.path.join(RAIZ_PROYECTO, "Imagenes", "Minijuego_Correr", "Texturas3D")


def construir():
    tex_cartel = os.path.join(DIR_TEX, "cartel_puente_0.png")

    m_hormigon = lb.material("Puente_Hormigon", "#94a3b8", rough=0.80, metal=0.08)
    m_acero = lb.material("Puente_Acero", "#354457", rough=0.44, metal=0.64)
    m_oscuro = lb.material("Puente_Oscuro", "#1e293b", rough=0.52, metal=0.52)
    m_cartel = lb.material(
        "Puente_Cartel", "#ffffff", rough=0.34, metal=0.06,
        tex_albedo=tex_cartel if os.path.exists(tex_cartel) else None,
        tex_emission=tex_cartel if os.path.exists(tex_cartel) else None,
        emision_fuerza=1.2,
    )
    m_foco = lb.material("Puente_FocoLuz", "#fff8d6", rough=0.14, metal=0.0,
                         emision="#ffd166", emision_fuerza=4.0)

    piezas = []

    # 1. Tablero de hormigón con vigas I inferiores transversales
    piezas.append(lb.caja("Puente_Tablero", (SPAN, ANCHO_PUENTE, 0.85), (0.0, 0.0, -0.35), m_hormigon, bisel=0.04, segs_bisel=1))
    piezas.append(lb.caja("Puente_VigaInf", (SPAN + 0.30, ANCHO_PUENTE + 0.30, 0.32), (0.0, 0.0, -0.82), m_acero, bisel=0.02, segs_bisel=1))
    for vx in range(-10, 11, 2):
        piezas.append(lb.caja("Puente_Costilla", (0.28, ANCHO_PUENTE + 0.16, 0.34), (float(vx), 0.0, -0.98), m_acero))

    # 2. Vigas de celosía metálica Warren de gran altura en ambos bordes (±2.55 m)
    for dy in (-2.55, 2.55):
        # Cordón inferior y cordón superior escalonado
        piezas.append(lb.caja("Cordon_Inf", (SPAN, 0.24, 0.28), (0.0, dy, 0.18), m_acero, bisel=0.02, segs_bisel=1))
        piezas.append(lb.caja("Cordon_Sup", (SPAN - 1.6, 0.24, 0.26), (0.0, dy, 1.85), m_acero, bisel=0.02, segs_bisel=1))
        # Rampas inclinadas de celosía en extremos
        for sx in (-1.0, 1.0):
            p0 = Vector((sx * (SPAN * 0.5 - 0.1), dy, 0.18))
            p1 = Vector((sx * (SPAN * 0.5 - 0.8), dy, 1.85))
            piezas.append(lb.tubo_ruta("Extremo_Inclinado", [p0, p1], 0.13, m_acero, lados=6))
        # Montantes verticales y diagonales Warren de acero
        for ix in range(-9, 10):
            dx = ix * 1.15
            piezas.append(lb.caja("Celosia_Montante", (0.14, 0.14, 1.65), (dx, dy, 1.02), m_acero))
            if ix < 9:
                ang = math.radians(34 if ix % 2 == 0 else -34)
                piezas.append(lb.caja("Celosia_Diag", (0.12, 0.12, 1.98), (dx + 0.575, dy, 1.02), m_acero, rot=(0.0, ang, 0.0)))

    # 3. Estribos laterales de hormigón / pilastras en ambos extremos (x = ±10.8 m)
    for sx in (-1.0, 1.0):
        px = sx * 11.2
        piezas.append(lb.caja("Estribo_Pilar", (1.65, ANCHO_PUENTE + 0.55, 4.40), (px, 0.0, 0.25), m_hormigon, bisel=0.06, segs_bisel=2))
        piezas.append(lb.caja("Estribo_Capitel", (1.85, ANCHO_PUENTE + 0.75, 0.34), (px, 0.0, 2.52), m_acero, bisel=0.03, segs_bisel=1))

    # 4. Valla publicitaria luminosa estilo Broadway / Subway Surfers mirando a -Y (+Z Godot)
    cartel_y = -2.85
    piezas.append(lb.caja("Cartel_MarcoExt", (8.60, 0.42, 3.20), (0.0, cartel_y + 0.14, 1.35), m_oscuro, bisel=0.05, segs_bisel=2))
    piezas.append(lb.caja("Cartel_Moldura", (8.10, 0.20, 2.85), (0.0, cartel_y + 0.02, 1.35), m_acero, bisel=0.03, segs_bisel=1))
    piezas.append(lb.panel_uv(
        "Cartel_Lienzo", (7.65, 0.04, 2.52),
        (0.0, cartel_y - 0.10, 1.35),
        m_cartel, cara_uv="-Y",
    ))

    # 4 brazos articulados tipo cuello de cisne con reflectores iluminando el cartel
    for fx in (-2.90, -0.95, 0.95, 2.90):
        pts_b = [(fx, cartel_y + 0.20, 2.85), (fx, cartel_y - 0.42, 3.22), (fx, cartel_y - 0.78, 2.92)]
        piezas.append(lb.tubo_ruta("Cartel_BrazoFoco", pts_b, 0.038, m_oscuro, lados=8, catmull_subdiv=2))
        piezas.append(lb.cilindro("Cartel_Pantalla", 0.095, 0.165, 0.18, (fx, cartel_y - 0.80, 2.82), m_oscuro, eje="Z", lados=12, rot=(math.radians(-26), 0.0, 0.0)))
        piezas.append(lb.esfera("Cartel_Bombilla", 0.085, (fx, cartel_y - 0.76, 2.74), m_foco, subdiv=1))

    obj = lb.unir(piezas, "Puente_Cartel")
    obj.location = (0.0, 0.0, 0.0)
    lb.suavizar_por_angulo(obj, 35.0)
    return obj


def main():
    args = lb.parsear_args_modelo("Modelos/Minijuego_Correr/puente_cartel.glb")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    obj = construir()
    lb.exportar_glb(obj, args.salida)
    if args.blend:
        lb.guardar_blend(args.blend)
    if args.render and not args.sin_render:
        lb.render_cuatro_vistas(obj, args.render, con_referencia=False)


if __name__ == "__main__":
    main()
