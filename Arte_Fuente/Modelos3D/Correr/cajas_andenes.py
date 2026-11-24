"""
Grupo de cajas de carga de madera con marcos, listones diagonales, refuerzos
metálicos y etiqueta de envío para los andenes de estación (PARK RUSH 3D).
"""

import math
import os
import sys

import bpy

DIR_ACTUAL = os.path.dirname(os.path.abspath(__file__))
if DIR_ACTUAL not in sys.path:
    sys.path.insert(0, DIR_ACTUAL)

import lib_blender as lb


def _crear_caja_carga(tam: float, centro, rot_z: float, m_panel, m_marco, m_metal, m_etiqueta):
    piezas = []
    h = tam * 0.5
    cx, cy, cz = centro
    cr, sr = math.cos(rot_z), math.sin(rot_z)

    def _p(lx, ly, lz):
        return (cx + lx * cr - ly * sr, cy + lx * sr + ly * cr, cz + lz)

    # Núcleo rehundido de tablones
    piezas.append(lb.caja("Caja_Nucleo", (tam - 0.06, tam - 0.06, tam - 0.06), centro, m_panel, rot=(0.0, 0.0, rot_z)))

    # 12 listones perimetrales del marco exterior
    g = 0.075
    for sz in (-h + g * 0.5, h - g * 0.5):
        for sx in (-h + g * 0.5, h - g * 0.5):
            piezas.append(lb.caja("Marco_Y", (g, tam, g), _p(sx, 0.0, sz), m_marco, bisel=0.005, segs_bisel=1, rot=(0.0, 0.0, rot_z)))
        for sy in (-h + g * 0.5, h - g * 0.5):
            piezas.append(lb.caja("Marco_X", (tam - g * 1.9, g, g), _p(0.0, sy, sz), m_marco, bisel=0.005, segs_bisel=1, rot=(0.0, 0.0, rot_z)))
    for sx in (-h + g * 0.5, h - g * 0.5):
        for sy in (-h + g * 0.5, h - g * 0.5):
            piezas.append(lb.caja("Marco_Z", (g, g, tam - g * 1.9), _p(sx, sy, 0.0), m_marco, bisel=0.005, segs_bisel=1, rot=(0.0, 0.0, rot_z)))
            # Cantonera metálica con remaches
            for sz_c in (-h + 0.06, h - 0.06):
                piezas.append(lb.caja("Cantonera", (0.09, 0.09, 0.12), _p(sx, sy, sz_c), m_metal, rot=(0.0, 0.0, rot_z)))

    # Riostras diagonales en las 4 caras verticales
    diag_l = math.hypot(tam - g * 2.0, tam - g * 2.0) * 0.92
    for sy_f in (-h + 0.028, h - 0.028):
        piezas.append(lb.caja("Diag_Y", (diag_l, 0.025, 0.065), _p(0.0, sy_f, 0.0), m_marco, rot=(0.0, math.radians(45), rot_z)))
    for sx_f in (-h + 0.028, h - 0.028):
        piezas.append(lb.caja("Diag_X", (0.025, diag_l, 0.065), _p(sx_f, 0.0, 0.0), m_marco, rot=(math.radians(45), 0.0, rot_z)))

    # Etiqueta de envío en el frente
    piezas.append(lb.caja("Etiqueta_Envio", (tam * 0.28, 0.014, tam * 0.18), _p(0.12, -h + 0.022, 0.08), m_etiqueta, rot=(0.0, 0.0, rot_z)))
    return piezas


def construir():
    m_panel = lb.material("Caja_Tablon", "#c47d41", rough=0.82, metal=0.02)
    m_marco = lb.material("Caja_Marco", "#de9952", rough=0.76, metal=0.02)
    m_metal = lb.material("Caja_Herraje", "#334155", rough=0.48, metal=0.65)
    m_etiqueta = lb.material("Caja_Etiqueta", "#f8fafc", rough=0.72, metal=0.0)

    piezas = []
    # Caja grande inferior
    piezas.extend(_crear_caja_carga(0.88, (0.0, 0.18, 0.44), 0.16, m_panel, m_marco, m_metal, m_etiqueta))
    # Caja mediana al lado
    piezas.extend(_crear_caja_carga(0.66, (0.08, -0.70, 0.33), -0.14, m_panel, m_marco, m_metal, m_etiqueta))
    # Caja pequeña apilada encima
    piezas.extend(_crear_caja_carga(0.58, (-0.02, 0.14, 0.88 + 0.29), 0.38, m_panel, m_marco, m_metal, m_etiqueta))

    obj = lb.unir(piezas, "Cajas_Andenes")
    obj.location = (0.0, 0.0, 0.0)
    lb.suavizar_por_angulo(obj, 35.0)
    return obj


def main():
    args = lb.parsear_args_modelo("Modelos/Minijuego_Correr/cajas_andenes.glb")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    obj = construir()
    lb.exportar_glb(obj, args.salida)
    if args.blend:
        lb.guardar_blend(args.blend)
    if args.render and not args.sin_render:
        lb.render_cuatro_vistas(obj, args.render, con_referencia=True)


if __name__ == "__main__":
    main()
