"""
Vagoneta / Speeder ferroviario diésel con capó curvado, calandra cromada,
faros salientes de gran formato, arado frontal, bocinas, baca con barra de
luces ámbar y operario cartoon al volante (CICLISTA en PARK RUSH 3D).
Frente mirando hacia -Y en Blender (+Z hacia el corredor en Godot).
"""

import math
import os
import sys

import bpy

DIR_ACTUAL = os.path.dirname(os.path.abspath(__file__))
if DIR_ACTUAL not in sys.path:
    sys.path.insert(0, DIR_ACTUAL)

import lib_blender as lb

Z_RAIL_TOP = 0.145


def _construir_rueda(nombre, centro, mat_osc, mat_metal):
    r_flange = 0.255
    r_tread = 0.230
    perfil = [
        (0.0, -0.072), (r_flange, -0.072), (r_flange, -0.050),
        (r_tread, -0.042), (r_tread, 0.062), (r_tread - 0.02, 0.072),
        (0.095, 0.066), (0.095, 0.076), (0.0, 0.076),
    ]
    sx = 1.0 if centro[0] >= 0 else -1.0
    ry = math.radians(90) if sx > 0 else math.radians(-90)
    r = lb.revolucion(nombre, perfil, centro, mat_osc, lados=16, rot=(0.0, ry, 0.0))
    b = lb.cilindro(
        nombre + "_Buje", 0.080, 0.090, 0.042,
        (centro[0] + sx * 0.074, centro[1], centro[2]),
        mat_metal, eje="X", lados=12, bisel_tapa=0.009,
    )
    return [r, b]


def construir():
    m_carroceria = lb.material("Speeder_Carroceria", "#facc15", rough=0.32, metal=0.22)
    m_chasis = lb.material("Speeder_Chasis", "#1f2937", rough=0.50, metal=0.55)
    m_metal = lb.material("Speeder_Metal", "#b8c4d2", rough=0.32, metal=0.72)
    m_cristal = lb.material("Speeder_Cristal", "#38bdf8", rough=0.10, metal=0.35)
    m_faro = lb.material("Speeder_Faro", "#fffbe0", rough=0.12, metal=0.0,
                         emision="#ffe88a", emision_fuerza=5.0)
    m_ambar = lb.material("Speeder_Ambar", "#fbbf24", rough=0.14, metal=0.0,
                          emision="#f59e0b", emision_fuerza=4.5)
    m_piloto_chaleco = lb.material("Speeder_Chaleco", "#ff6b1a", rough=0.55, metal=0.05)
    m_piloto_piel = lb.material("Speeder_Piel", "#f1c27d", rough=0.65, metal=0.02)

    piezas = []

    # 1. Bastidor pesado, 4 ruedas ferroviarias con muelles y cajas de herramientas
    z_eje = Z_RAIL_TOP + 0.230
    piezas.append(lb.caja("Chasis", (1.92, 2.52, 0.22), (0.0, 0.0, 0.44), m_chasis, bisel=0.028, segs_bisel=2))
    for by in (-0.80, 0.80):
        piezas.append(lb.cilindro("Eje", 0.055, 0.055, 1.50, (0.0, by, z_eje), m_chasis, eje="X", lados=10))
        for side in (-1, 1):
            piezas.extend(_construir_rueda("Rueda", (side * 0.72, by, z_eje), m_chasis, m_metal))
            piezas.append(lb.caja("Axlebox", (0.14, 0.26, 0.18), (side * 0.90, by, z_eje + 0.05), m_metal, bisel=0.018, segs_bisel=1))
            piezas.append(lb.muelle_helicoidal("Muelle_Susp", 0.048, 0.013, 0.14, 2.2, (side * 0.90, by, z_eje + 0.18), m_metal, segs_por_vuelta=8, segs_alambre=5))

    # 2. Cuerpo aerodinámico diésel + morro capó abombado con rejilla cromada vertical
    piezas.append(lb.caja("Cuerpo_Base", (1.88, 2.18, 0.54), (0.0, 0.08, 0.80), m_carroceria, bisel=0.055, segs_bisel=2))
    # Capó delantero inclinado y abombado (-Y)
    piezas.append(lb.caja("Capo_Motor", (1.42, 0.96, 0.42), (0.0, -0.68, 1.06), m_carroceria, bisel=0.085, segs_bisel=3, rot=(math.radians(-6), 0.0, 0.0)))
    # Calandra frontal cromada vertical + 6 lamas verticales + emblema delantero
    piezas.append(lb.caja("Radiador_Marco", (0.88, 0.09, 0.46), (0.0, -1.14, 0.92), m_metal, bisel=0.020, segs_bisel=2))
    piezas.append(lb.caja("Radiador_Fondo", (0.76, 0.04, 0.36), (0.0, -1.16, 0.92), m_chasis, bisel=0.008, segs_bisel=1))
    for rx in (-0.28, -0.17, -0.06, 0.06, 0.17, 0.28):
        piezas.append(lb.caja("Radiador_LamaV", (0.032, 0.04, 0.34), (rx, -1.18, 0.92), m_metal, bisel=0.006, segs_bisel=1))
    # Insignia rombo/barra en el centro del capó
    piezas.append(lb.caja("Morro_Insignia", (0.20, 0.03, 0.09), (0.0, -1.19, 1.12), m_ambar, bisel=0.008, segs_bisel=1))

    # Rejillas de ventilación, estribos y tubo de escape cromado con silencioso perforado
    for side in (-1, 1):
        for ly in (-0.86, -0.70, -0.54):
            piezas.append(lb.caja("Ventilacion_Capo", (0.04, 0.08, 0.24), (side * 0.72, ly, 1.08), m_chasis, bisel=0.006, segs_bisel=1))
        piezas.append(lb.caja("Estribo", (0.16, 0.74, 0.06), (side * 1.00, 0.25, 0.48), m_metal, bisel=0.012, segs_bisel=1))
        # Cofre lateral de herramientas tras cabina
        piezas.append(lb.caja("Cofre_Herramientas", (0.24, 0.56, 0.34), (side * 0.88, 0.92, 1.18), m_chasis, bisel=0.018, segs_bisel=1))
    pts_esc = [(0.68, -0.38, 1.04), (0.86, -0.34, 1.32), (0.86, -0.32, 1.78), (0.90, -0.22, 1.90)]
    piezas.append(lb.tubo_ruta("Tubo_Escape", pts_esc, 0.046, m_metal, lados=10))
    piezas.append(lb.cilindro("Silencioso", 0.082, 0.082, 0.36, (0.86, -0.32, 1.56), m_chasis, eje="Z", lados=12, bisel_tapa=0.012))

    # 3. Parachoques con arado frontal en V + bandas de peligro + 2 grandes focos con visera
    piezas.append(lb.caja("Parachoques_Del", (2.08, 0.22, 0.28), (0.0, -1.24, 0.52), m_chasis, bisel=0.025, segs_bisel=2))
    for side in (-1, 1):
        piezas.append(lb.caja("Arado_Ala", (0.98, 0.14, 0.24), (side * 0.50, -1.30, 0.36), m_chasis, bisel=0.015, segs_bisel=1, rot=(0.0, 0.0, side * math.radians(-16))))
    for bx in (-0.75, -0.38, 0.0, 0.38, 0.75):
        piezas.append(lb.caja("Parachoques_Raya", (0.14, 0.03, 0.20), (bx, -1.35, 0.52), m_ambar, bisel=0.005, segs_bisel=1, rot=(0.0, math.radians(22), 0.0)))
    # Defensa trasera
    piezas.append(lb.caja("Parachoques_Tras", (2.02, 0.16, 0.24), (0.0, 1.24, 0.54), m_chasis, bisel=0.02, segs_bisel=1))

    # Grandes faros delanteros independientes montados sobre soportes al costado del radiador
    for hx in (-0.70, 0.70):
        piezas.append(lb.cilindro("Faro_Soporte", 0.045, 0.055, 0.14, (hx, -1.04, 0.88), m_chasis, eje="Z", lados=8))
        piezas.append(lb.cilindro("Faro_Carcasa", 0.185, 0.165, 0.18, (hx, -1.10, 0.98), m_chasis, eje="Y", lados=16, bisel_tapa=0.016))
        piezas.append(lb.toro("Faro_Aro", 0.165, 0.028, (hx, -1.18, 0.98), m_metal, eje="Y", segs_mayor=18, segs_menor=8))
        piezas.append(lb.esfera("Faro_Lente", 0.140, (hx, -1.18, 0.98), m_faro, escala=(1.0, 0.45, 1.0), subdiv=2))

    # 4. Cabina ferroviaria acristalada con inclinación frontal, espejos, bocinas y puente de luces
    cab_y = 0.28
    for px in (-0.78, 0.78):
        piezas.append(lb.caja("Pilar_Del", (0.10, 0.10, 0.76), (px, -0.28, 1.46), m_chasis, bisel=0.014, segs_bisel=1, rot=(math.radians(-10), 0.0, 0.0)))
        piezas.append(lb.caja("Pilar_Tras", (0.11, 0.12, 0.74), (px, 0.86, 1.46), m_chasis, bisel=0.014, segs_bisel=1))
        piezas.append(lb.caja("Espejo_Brazo", (0.16, 0.03, 0.03), (px + (0.11 if px > 0 else -0.11), -0.34, 1.56), m_metal))
        piezas.append(lb.caja("Espejo_Carcasa", (0.045, 0.09, 0.20), (px + (0.19 if px > 0 else -0.19), -0.34, 1.56), m_chasis, bisel=0.010, segs_bisel=1))
    piezas.append(lb.caja("Cabina_Trasera", (1.60, 0.12, 0.72), (0.0, 0.86, 1.44), m_carroceria, bisel=0.02, segs_bisel=1))
    piezas.append(lb.caja("Parabrisas_Cristal", (1.46, 0.045, 0.66), (0.0, -0.28, 1.46), m_cristal, bisel=0.008, segs_bisel=1, rot=(math.radians(-10), 0.0, 0.0)))
    for wx in (-0.34, 0.34):
        piezas.append(lb.caja("Limpiaparabrisas", (0.34, 0.025, 0.028), (wx, -0.31, 1.32), m_chasis, rot=(math.radians(-10), math.radians(32), 0.0)))

    # Techo cabina + barra de luces ámbar de puente + doble bocina neumática cromada
    piezas.append(lb.caja("Cabina_Techo", (1.84, 1.38, 0.14), (0.0, cab_y, 1.85), m_carroceria, bisel=0.040, segs_bisel=2))
    piezas.append(lb.caja("Barra_Puente", (1.16, 0.28, 0.08), (0.0, cab_y - 0.32, 1.94), m_chasis, bisel=0.016, segs_bisel=1))
    for lx, r_luz in ((-0.40, 0.105), (0.0, 0.115), (0.40, 0.105)):
        piezas.append(lb.cilindro("Baliza_Domo", r_luz, r_luz * 0.82, 0.16, (lx, cab_y - 0.32, 2.04), m_ambar, eje="Z", lados=14, bisel_tapa=0.02))
    for hx in (-0.64, 0.64):
        piezas.append(lb.cilindro("Bocina_Aire", 0.026, 0.052, 0.28, (hx, cab_y - 0.18, 1.96), m_metal, eje="Y", lados=12))

    # 5. Operario ferroviario cartoon visible tras el cristal
    op_y = 0.24
    piezas.append(lb.caja("Operario_Torso", (0.46, 0.28, 0.44), (0.0, op_y, 1.34), m_piloto_chaleco, bisel=0.05, segs_bisel=2))
    for sx in (-0.13, 0.13):
        piezas.append(lb.caja("Operario_Banda", (0.075, 0.30, 0.42), (sx, op_y, 1.34), m_ambar, bisel=0.01, segs_bisel=1))
        piezas.append(lb.cilindro("Operario_Brazo", 0.058, 0.052, 0.32, (sx * 1.9, op_y - 0.14, 1.34), m_piloto_chaleco, eje="Y", lados=8, rot=(math.radians(-18), 0.0, 0.0)))
        piezas.append(lb.esfera("Operario_Mano", 0.058, (sx * 1.6, op_y - 0.30, 1.28), m_piloto_piel, subdiv=1))
    piezas.append(lb.toro("Volante", 0.15, 0.024, (0.0, op_y - 0.32, 1.26), m_chasis, eje="Y", segs_mayor=14, segs_menor=6, rot=(math.radians(35), 0.0, 0.0)))
    piezas.append(lb.esfera("Operario_Cabeza", 0.160, (0.0, op_y - 0.02, 1.64), m_piloto_piel, escala=(0.95, 0.95, 1.05), subdiv=2))
    piezas.append(lb.esfera("Operario_Casco", 0.180, (0.0, op_y - 0.01, 1.70), m_carroceria, escala=(1.02, 1.08, 0.72), subdiv=2))
    piezas.append(lb.caja("Operario_ViseraCasco", (0.29, 0.14, 0.032), (0.0, op_y - 0.18, 1.69), m_carroceria, bisel=0.008, segs_bisel=1))
    piezas.append(lb.caja("Operario_Gafas", (0.25, 0.08, 0.075), (0.0, op_y - 0.15, 1.63), m_chasis, bisel=0.012, segs_bisel=1))

    obj = lb.unir(piezas, "Vagoneta_Speeder")
    obj.location = (0.0, 0.0, 0.0)
    lb.suavizar_por_angulo(obj, 35.0)
    return obj


def main():
    args = lb.parsear_args_modelo("Modelos/Minijuego_Correr/vagoneta_speeder.glb")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    obj = construir()
    lb.exportar_glb(obj, args.salida)
    if args.blend:
        lb.guardar_blend(args.blend)
    if args.render and not args.sin_render:
        lb.render_cuatro_vistas(obj, args.render, con_referencia=True)


if __name__ == "__main__":
    main()
