"""
Túnel ferroviario abovedado en arco con dovelas de sillería, cerchas interiores
curvas, extractores de ventilación cenitales, bolardos y letrero luminoso
`METRO LINEA 1` (PARK RUSH 3D). 12 cortes en Y para curvatura suave del horizonte.
"""

import math
import os
import sys

import bpy

DIR_ACTUAL = os.path.dirname(os.path.abspath(__file__))
if DIR_ACTUAL not in sys.path:
    sys.path.insert(0, DIR_ACTUAL)

import lib_blender as lb

LARGO = 18.0
ANCHO_INT = 10.60
ALTO_INT = 5.20
ESPESOR = 0.62

RAIZ_PROYECTO = os.path.abspath(os.path.join(DIR_ACTUAL, "..", "..", ".."))
DIR_TEX = os.path.join(RAIZ_PROYECTO, "Imagenes", "Minijuego_Correr", "Texturas3D")


def _perfil_boveda():
    """Sección en herradura / arco poligonal abovedado (más orgánico e industrial)."""
    hw = ANCHO_INT * 0.5
    hwa = hw + ESPESOR
    # Semiperfil derecho x>=0: base -> alzado recto -> chaflán de bóveda -> clave -> simétrico
    int_pts = [
        (hw, 0.0),
        (hw, 3.15),
        (hw - 0.72, 4.35),
        (hw - 2.10, 5.05),
        (0.0, ALTO_INT + 0.12),
    ]
    ext_pts = [
        (hwa, 0.0),
        (hwa, 3.40),
        (hwa - 0.85, 4.78),
        (hwa - 2.25, ALTO_INT + ESPESOR + 0.12),
        (0.0, ALTO_INT + ESPESOR + 0.18),
    ]
    return int_pts, ext_pts


def construir():
    tex_letrero = os.path.join(DIR_TEX, "tunel_bl_letrero.png")
    m_hormigon = lb.material("Tunel_Hormigon", "#8a94a4", rough=0.80, metal=0.06)
    m_claro = lb.material("Tunel_HormigonClaro", "#c4beb4", rough=0.82, metal=0.04)
    m_amarillo = lb.material("Tunel_Amarillo", "#facc15", rough=0.38, metal=0.14)
    m_acero = lb.material("Tunel_Acero", "#2b3648", rough=0.46, metal=0.60)
    m_rojo = lb.material("Tunel_PeligroRojo", "#dc2626", rough=0.40, metal=0.10)
    m_letrero = lb.material(
        "Tunel_Letrero", "#ffffff", rough=0.25, metal=0.08,
        tex_albedo=tex_letrero if os.path.exists(tex_letrero) else None,
        tex_emission=tex_letrero if os.path.exists(tex_letrero) else None,
        emision_fuerza=1.1,
    )
    m_luz = lb.material("Tunel_LuzLED", "#fff8d6", rough=0.12, metal=0.0,
                        emision="#ffd166", emision_fuerza=4.5)

    piezas = []
    hw = ANCHO_INT * 0.5   # 5.30 m
    hwa = hw + ESPESOR     # 5.92 m

    # 1. Cuerpo abovedado del túnel construido con paños largos y bóveda inclinada (12 cortes en Y)
    for lado in (-1, 1):
        # Muro lateral vertical inferior + arranque inclinado de bóveda
        piezas.append(lb.caja("Tunel_MuroLat", (ESPESOR, LARGO, 3.45), (lado * (hw + ESPESOR * 0.5), 0.0, 1.725), m_claro, subdiv_y=12))
        piezas.append(lb.caja("Tunel_Boveda", (2.60, LARGO, 0.65), (lado * (hw - 0.80), 0.0, 4.45), m_hormigon, rot=(0.0, lado * math.radians(38), 0.0), subdiv_y=12))
        # Zócalo de seguridad amarillo + banda roja rayada inferior
        piezas.append(lb.caja("Tunel_Zocalo", (0.20, LARGO, 0.36), (lado * (hw - 0.10), 0.0, 0.18), m_amarillo, subdiv_y=12))
        # Bandeja lateral portacables y conducto de ventilación interior
        for cz in (1.75, 2.35):
            piezas.append(lb.caja("Tunel_Conducto", (0.14, LARGO - 0.8, 0.09), (lado * (hw - 0.07), 0.0, cz), m_acero, subdiv_y=12))
        # Contrafuertes exteriores
        for py in (-6.8, -3.4, 0.0, 3.4, 6.8):
            piezas.append(lb.caja("Tunel_Contrafuerte", (0.42, 0.54, 3.60), (lado * (hwa + 0.18), py, 1.80), m_claro, bisel=0.04, segs_bisel=1))

    # Losa clave superior del túnel
    piezas.append(lb.caja("Tunel_LosaTecho", (ANCHO_INT - 2.6, LARGO, 0.70), (0.0, 0.0, ALTO_INT + 0.35), m_hormigon, subdiv_y=12))

    # 2. Cerchas metálicas interiores en arco + 2 grupos de ventiladores extractores en techo
    for cy in (-6.0, -3.0, 0.0, 3.0, 6.0):
        for lado in (-1, 1):
            piezas.append(lb.caja("Tunel_CerchaLat", (0.24, 0.32, 3.30), (lado * (hw - 0.12), cy, 1.65), m_acero, bisel=0.02, segs_bisel=1))
            piezas.append(lb.caja("Tunel_CerchaDia", (2.45, 0.30, 0.24), (lado * (hw - 0.85), cy, 4.30), m_acero, rot=(0.0, lado * math.radians(38), 0.0)))
        piezas.append(lb.caja("Tunel_CerchaTecho", (ANCHO_INT - 3.2, 0.32, 0.24), (0.0, cy, ALTO_INT - 0.12), m_acero))

    # Grandes extractores de aire cilíndricos en bóveda (a y = -4.5 y +4.5 m)
    for vy in (-4.5, 4.5):
        for vx in (-2.4, 2.4):
            piezas.append(lb.cilindro("Vent_Tambor", 0.42, 0.42, 1.25, (vx, vy, ALTO_INT - 0.42), m_acero, eje="Y", lados=14, bisel_tapa=0.02))
            piezas.append(lb.toro("Vent_Boca", 0.40, 0.04, (vx, vy - 0.62, ALTO_INT - 0.42), m_amarillo, eje="Y", segs_mayor=14, segs_menor=6))

    # 3. Portadas monumentalizadas en entrada (-Y) y salida (+Y) con dovelas de arco + letrero
    for signo in (-1, 1):
        py = signo * (LARGO * 0.5 + 0.18)
        for lado in (-1, 1):
            piezas.append(lb.caja("Portal_Pilar", (0.98, 0.72, ALTO_INT + 0.50), (lado * (hw + 0.38), py, (ALTO_INT + 0.50) * 0.5), m_hormigon, bisel=0.05, segs_bisel=2))
            for k in range(4):
                mat_b = m_rojo if k % 2 == 0 else m_amarillo
                piezas.append(lb.caja("Portal_Chevron", (1.06, 0.78, 0.24), (lado * (hw + 0.38), py, 0.24 + k * 0.26), mat_b, bisel=0.015, segs_bisel=1))
            # Bolardo de protección metálico amarillo junto al pilar
            piezas.append(lb.cilindro("Portal_Bolardo", 0.16, 0.16, 0.96, (lado * (hw - 0.28), py + signo * 0.52, 0.48), m_amarillo, eje="Z", lados=12, bisel_tapa=0.02))

        # Gran dintel de arco + clave central con dovelas sobresalientes
        piezas.append(lb.caja("Portal_Dintel", (ANCHO_INT + 1.85, 0.78, 0.92), (0.0, py, ALTO_INT + 0.44), m_hormigon, bisel=0.06, segs_bisel=2))
        piezas.append(lb.caja("Portal_BandaAma", (ANCHO_INT + 1.92, 0.82, 0.20), (0.0, py, ALTO_INT + 0.04), m_amarillo, bisel=0.02, segs_bisel=1))
        for dx_d in (-3.6, -2.4, -1.2, 0.0, 1.2, 2.4, 3.6):
            piezas.append(lb.caja("Portal_Dovela", (0.64, 0.86, 0.54 if abs(dx_d) > 0.1 else 0.78), (dx_d, py, ALTO_INT + 0.96), m_claro, bisel=0.03, segs_bisel=1))

        # Letrero 'METRO LINEA 1' en portada + iluminación LED en túnel
        cara_l = "-Y" if signo < 0 else "+Y"
        piezas.append(lb.caja("Portal_LetreroMarco", (4.10, 0.20, 0.96), (0.0, py + signo * 0.36, ALTO_INT + 0.48), m_acero, bisel=0.03, segs_bisel=1))
        piezas.append(lb.panel_uv("Portal_Letrero", (3.85, 0.04, 0.76), (0.0, py + signo * 0.46, ALTO_INT + 0.48), m_letrero, cara_uv=cara_l))

    # 4. Pantallas LED en el techo a lo largo del túnel
    for lz in (-7.2, -4.4, -1.6, 1.6, 4.4, 7.2):
        for lx in (-2.5, 0.0, 2.5):
            piezas.append(lb.caja("Luz_Techo_Marco", (0.70, 0.42, 0.09), (lx, lz, ALTO_INT - 0.06), m_acero))
            piezas.append(lb.caja("Luz_Techo_LED", (0.58, 0.30, 0.04), (lx, lz, ALTO_INT - 0.10), m_luz))

    obj = lb.unir(piezas, "Tunel_Ferroviario")
    obj.location = (0.0, 0.0, 0.0)
    lb.suavizar_por_angulo(obj, 35.0)
    return obj


def main():
    args = lb.parsear_args_modelo("Modelos/Minijuego_Correr/tunel_ferroviario.glb")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    obj = construir()
    lb.exportar_glb(obj, args.salida)
    if args.blend:
        lb.guardar_blend(args.blend)
    if args.render and not args.sin_render:
        lb.render_cuatro_vistas(obj, args.render, con_referencia=True)


if __name__ == "__main__":
    main()
