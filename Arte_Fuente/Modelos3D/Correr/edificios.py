"""
5 estilos arquitectónicos altamente detallados de edificios urbanos para PARK RUSH 3D
(`edificio_0.glb` .. `edificio_4.glb`):
  0: Terracota Brownstone — escalera de incendios zig-zag NYC, torre de agua y antena
  1: Ocre Mansarda — tejado abuhardillado inclinado, contraventanas y toldos en piso visible
  2: Loft Azul Industrial — ventanales con arco, conductos de ventilación y extractor rotativo
  3: Coral Parisino — balcones forjados, jardineras florales, letrero café colgante y buhardillas
  4: Torre Esmeralda Art-Decó — bay-windows salientes, pilastras acanaladas y pináculo retranqueado

Todos los detalles principales nacen por encima de z = 4.65 m (sobre el muro de ladrillo!).
Frente principal +X (hacia las vías), testero -Y (hacia cámara). 8 cortes en Y para curvatura.
"""

import argparse
import math
import os
import random
import sys

import bpy
from mathutils import Vector

DIR_ACTUAL = os.path.dirname(os.path.abspath(__file__))
if DIR_ACTUAL not in sys.path:
    sys.path.insert(0, DIR_ACTUAL)

import lib_blender as lb

ANCHO = 8.40   # X (-4.20..+4.20)
LARGO = 13.60  # Y (-6.80..+6.80)

ESTILOS = [
    # (idx, nombre, pisos, pared, moldura, acento, hierro, madera, techo_azotea, tipo, azotea)
    (0, "Terracota", 4, "#df785d", "#f5eadb", "#2a9d8f", "#27303f", "#a6633c", "#475569", "fire_escape", "torre_agua"),
    (1, "Ocre",      5, "#f0bd4b", "#fff7e2", "#e76f51", "#264653", "#8b5a2b", "#3f4a59", "mansarda",    "tejado_buhardilla"),
    (2, "LoftAzul",  5, "#59a2d6", "#eaf4fc", "#f59e0b", "#1e293b", "#9c623d", "#334155", "loft",        "torre_vent"),
    (3, "Coral",     4, "#e66b80", "#fdecf0", "#38bdf8", "#23293a", "#945b38", "#3b4759", "balcon",      "atico_jardin"),
    (4, "Esmeralda", 5, "#5eb37e", "#edf7ee", "#facc15", "#1e3a2f", "#9c623d", "#374151", "bay_artdeco", "corona_torre"),
]


def _construir_ventana(piezas, px, py, pz, normal_eje, tipo, es_visible_comercio, mat_ventana, m_moldura, m_acento, m_hierro, rng):
    """Ventana 3D con recercado profundo, alféizar con ménsulas, dintel y ornamentos."""
    vw, vh = 1.46, 1.90
    if normal_eje == "+X":
        sx = 1.0
        def p(du, dv, d_out):
            return (px + d_out * sx, py + du, pz + dv)
        def tam(w_u, h_v, prof):
            return (prof, w_u, h_v)
    else:
        sy = 1.0 if normal_eje == "+Y" else -1.0
        def p(du, dv, d_out):
            return (px + du, py + d_out * sy, pz + dv)
        def tam(w_u, h_v, prof):
            return (w_u, prof, h_v)

    # Marco saliente profundo (14 cm) + cristal rehundido respecto al dintel + parteluz grueso
    piezas.append(lb.caja("V_Marco", tam(vw + 0.28, vh + 0.24, 0.14), p(0, 0, 0.06), m_moldura, bisel=0.015, segs_bisel=1))
    piezas.append(lb.caja("V_Alfeizar", tam(vw + 0.44, 0.16, 0.28), p(0, -vh * 0.5 - 0.10, 0.13), m_moldura, bisel=0.02, segs_bisel=1))
    for cx_m in (-vw * 0.42, vw * 0.42):
        piezas.append(lb.caja("V_Mensula", tam(0.14, 0.18, 0.20), p(cx_m, -vh * 0.5 - 0.24, 0.09), m_moldura))
    piezas.append(lb.caja("V_Cristal", tam(vw - 0.04, vh - 0.04, 0.04), p(0, 0, 0.125), mat_ventana))
    piezas.append(lb.caja("V_ParteluzV", tam(0.09, vh - 0.02, 0.05), p(0, 0, 0.148), m_moldura))
    piezas.append(lb.caja("V_ParteluzH", tam(vw - 0.02, 0.09, 0.05), p(0, 0.14, 0.148), m_moldura))

    # Dintel coronado saliente con frontón o clave
    piezas.append(lb.caja("V_Dintel", tam(vw + 0.40, 0.26, 0.24), p(0, vh * 0.5 + 0.16, 0.11), m_moldura, bisel=0.025, segs_bisel=1))
    if tipo in ("fire_escape", "loft", "bay_artdeco"):
        piezas.append(lb.caja("V_Clave", tam(0.28, 0.36, 0.28), p(0, vh * 0.5 + 0.20, 0.13), m_acento if tipo == "bay_artdeco" else m_moldura, bisel=0.02, segs_bisel=1))

    # Contraventanas coloridas o balcones forjados o jardineras florales
    if tipo == "mansarda":
        for side in (-1, 1):
            piezas.append(lb.caja("V_Contraventana", tam(0.38, vh - 0.04, 0.10), p(side * (vw * 0.5 + 0.30), 0, 0.09), m_acento, bisel=0.015, segs_bisel=1))
    elif tipo == "balcon":
        piezas.append(lb.caja("Balcon_Base", tam(vw + 0.50, 0.14, 0.72), p(0, -vh * 0.5 - 0.04, 0.36), m_moldura, bisel=0.02, segs_bisel=1))
        piezas.append(lb.caja("Balcon_Pasamano", tam(vw + 0.54, 0.08, 0.08), p(0, -vh * 0.5 + 0.68, 0.68), m_hierro, bisel=0.01, segs_bisel=1))
        for bu in (-0.82, -0.41, 0.0, 0.41, 0.82):
            piezas.append(lb.caja("Balcon_Barrote", tam(0.055, 0.68, 0.055), p(bu, -vh * 0.5 + 0.34, 0.68), m_hierro))
        if rng.random() < 0.55:
            # Jardinera con maceta en barandilla
            piezas.append(lb.caja("Jardinera", tam(0.90, 0.22, 0.24), p(0, -vh * 0.5 + 0.14, 0.56), m_acento, bisel=0.02, segs_bisel=1))
    elif tipo == "bay_artdeco" and normal_eje == "+X" and abs(py) < 2.5:
        # Bay window prismática trapezoidal saliente (+0.52 m)
        piezas.append(lb.caja("Bay_Cuerpo", (0.52, vw + 0.35, vh + 0.48), p(0, 0, 0.28), m_moldura, bisel=0.04, segs_bisel=1))
        piezas.append(lb.caja("Bay_CristalF", (0.04, vw - 0.06, vh - 0.08), p(0, 0, 0.55), mat_ventana))

    # Unidad AC saliente en ventana (aleatoria en plantas altas)
    if not es_visible_comercio and rng.random() < 0.24 and tipo != "balcon":
        piezas.append(lb.caja("AC_Ventana", tam(0.68, 0.44, 0.46), p(-0.22, -vh * 0.5 + 0.24, 0.30), m_moldura, bisel=0.02, segs_bisel=1))
        piezas.append(lb.caja("AC_Rejilla", tam(0.56, 0.32, 0.05), p(-0.22, -vh * 0.5 + 0.24, 0.54), m_hierro))

    # Toldo rayado visible sobre el muro (en planta 1, z ~ 5.5 m!)
    if es_visible_comercio and normal_eje == "+X":
        for s_i in range(4):
            u_s = -0.66 + s_i * 0.44
            mat_t = m_acento if s_i % 2 == 0 else m_moldura
            piezas.append(lb.caja(
                "Toldo_Franja", (1.05, 0.44, 0.14),
                (px + 0.52, py + u_s, pz - vh * 0.42),
                mat_t, bisel=0.012, segs_bisel=1, rot=(0.0, math.radians(24), 0.0),
            ))


def _construir_escalera_incendios(piezas, hx, hy, pisos, m_hierro, m_acento):
    """Escalera de incendios metálica estilo NYC visible sobre fachada +X y testero -Y."""
    # En fachada principal +X (entre columnas centrales) y en cara hacia cámara -Y!
    for eje, x_b, y_b, dx_n, dy_n in (
        ("+X", hx + 0.62, 0.0, 1.0, 0.0),
        ("-Y", 0.0, -hy - 0.62, 0.0, -1.0),
    ):
        w_bal = 3.80
        d_bal = 1.15
        for p_idx in range(1, pisos):
            zp = 0.80 + p_idx * 3.85 + 0.15
            # Plataforma de hierro rejada + barandilla superior
            sz = (d_bal, w_bal, 0.12) if eje == "+X" else (w_bal, d_bal, 0.12)
            pos_plat = (x_b, y_b, zp)
            piezas.append(lb.caja("Fire_Plataforma", sz, pos_plat, m_hierro, bisel=0.015, segs_bisel=1))
            # Pasamano exterior
            sz_bar = (0.07, w_bal, 0.07) if eje == "+X" else (w_bal, 0.07, 0.07)
            px_b = x_b + dx_n * (d_bal * 0.46)
            py_b = y_b + dy_n * (d_bal * 0.46)
            piezas.append(lb.caja("Fire_Pasamano", sz_bar, (px_b, py_b, zp + 0.88), m_hierro))
            for k in (-1.75, -0.88, 0.0, 0.88, 1.75):
                bx = px_b if eje == "+X" else x_b + k
                by = y_b + k if eje == "+X" else py_b
                piezas.append(lb.caja("Fire_Poste", (0.06, 0.06, 0.88), (bx, by, zp + 0.44), m_hierro))
            # Tramo de escalera diagonal hacia piso siguiente (alternando zig-zag!)
            if p_idx < pisos - 1:
                zp_sig = 0.80 + (p_idx + 1) * 3.85 + 0.15
                dir_zig = 1.0 if p_idx % 2 == 0 else -1.0
                if eje == "+X":
                    p0 = Vector((x_b + 0.10, y_b - dir_zig * 1.15, zp + 0.06))
                    p1 = Vector((x_b + 0.10, y_b + dir_zig * 1.15, zp_sig + 0.06))
                else:
                    p0 = Vector((x_b - dir_zig * 1.15, y_b - 0.10, zp + 0.06))
                    p1 = Vector((x_b + dir_zig * 1.15, y_b - 0.10, zp_sig + 0.06))
                piezas.append(lb.tubo_ruta("Fire_Zanca", [p0, p1], 0.065, m_hierro, lados=6))
                for r_k in range(5):
                    ft = (r_k + 0.5) / 5.0
                    pm = p0.lerp(p1, ft)
                    piezas.append(lb.caja("Fire_Peldano", (0.28, 0.14, 0.04) if eje == "+X" else (0.14, 0.28, 0.04), pm, m_hierro))
        # Letrero neón/cartel sobresaliente junto a la esquina frontal (-Y/+X, z = 6.6 m -> bien visible!)
        if eje == "-Y":
            piezas.append(lb.caja("Cartel_Soporte", (1.20, 0.10, 0.10), (3.10, -hy - 0.52, 6.90), m_hierro))
            piezas.append(lb.caja("Cartel_Caja", (0.26, 0.85, 1.35), (3.65, -hy - 0.52, 6.60), m_acento, bisel=0.04, segs_bisel=2))


def _construir_azotea(piezas, b_h, azotea, m_pared, m_moldura, m_acento, m_hierro, m_madera, m_techo, m_win_luz):
    z_top = b_h + 0.92

    # Ménsulas ornamentales bajo la cornisa superior alrededor de todo el edificio
    for my in (-5.4, -3.6, -1.8, 0.0, 1.8, 3.6, 5.4):
        piezas.append(lb.caja("Cornisa_CanecilloX", (0.34, 0.22, 0.42), (ANCHO * 0.5 + 0.12, my, b_h - 0.05), m_moldura))
    for mx in (-2.8, 0.0, 2.8):
        piezas.append(lb.caja("Cornisa_CanecilloY", (0.22, 0.34, 0.42), (mx, -LARGO * 0.5 - 0.12, b_h - 0.05), m_moldura))

    if azotea in ("torre_agua", "torre_vent"):
        tx, ty = -1.10, -1.80
        for px in (-0.82, 0.82):
            for py in (-0.82, 0.82):
                piezas.append(lb.caja("Torre_Pata", (0.16, 0.16, 2.30), (tx + px, ty + py, z_top + 1.15), m_hierro))
        # Arrostramientos en X
        for s_face in (-0.82, 0.82):
            piezas.append(lb.tubo_ruta("Torre_Diag", [Vector((tx - 0.78, ty + s_face, z_top + 0.2)), Vector((tx + 0.78, ty + s_face, z_top + 1.9))], 0.055, m_hierro, lados=6))
            piezas.append(lb.tubo_ruta("Torre_Diag2", [Vector((tx + 0.78, ty + s_face, z_top + 0.2)), Vector((tx - 0.78, ty + s_face, z_top + 1.9))], 0.055, m_hierro, lados=6))
        piezas.append(lb.caja("Torre_Plataforma", (2.45, 2.45, 0.18), (tx, ty, z_top + 2.25), m_hierro, bisel=0.02, segs_bisel=1))
        piezas.append(lb.cilindro("Torre_Cuba", 1.32, 1.26, 2.45, (tx, ty, z_top + 3.45), m_madera, eje="Z", lados=16))
        for hz in (z_top + 2.65, z_top + 3.45, z_top + 4.25):
            piezas.append(lb.toro("Torre_Aro", 1.32, 0.036, (tx, ty, hz), m_hierro, eje="Z", segs_mayor=18, segs_menor=6))
        piezas.append(lb.cilindro("Torre_Tejado", 1.52, 0.08, 1.18, (tx, ty, z_top + 5.20), m_hierro, eje="Z", lados=16))

    if azotea == "tejado_buhardilla":
        # Tejado inclinado en mansarda trapezoidal de pizarra oscura + 3 buhardillas sobresalientes!
        # Cuerpo piramidal de mansarda (8 cortes en Y)
        piezas.append(lb.caja("Mansarda_Nivel1", (ANCHO - 0.4, LARGO - 0.4, 1.50), (0.0, 0.0, z_top + 0.75), m_techo, bisel=0.25, segs_bisel=2, subdiv_y=8))
        piezas.append(lb.caja("Mansarda_Nivel2", (ANCHO - 1.5, LARGO - 1.5, 1.45), (0.0, 0.0, z_top + 2.15), m_techo, bisel=0.25, segs_bisel=2, subdiv_y=8))
        piezas.append(lb.caja("Mansarda_Cresta", (ANCHO - 2.6, LARGO - 2.6, 0.25), (0.0, 0.0, z_top + 2.95), m_hierro, bisel=0.04, segs_bisel=1))
        # Buhardillas con ventana luminosa en +X y en -Y
        for by in (-3.6, 0.0, 3.6):
            piezas.append(lb.caja("Buhardilla", (1.60, 1.65, 1.65), (ANCHO * 0.5 - 0.45, by, z_top + 1.05), m_moldura, bisel=0.05, segs_bisel=1))
            piezas.append(lb.caja("Buhardilla_Tapa", (1.85, 1.85, 0.38), (ANCHO * 0.5 - 0.40, by, z_top + 2.02), m_techo, bisel=0.08, segs_bisel=1))
            piezas.append(lb.caja("Buhardilla_Win", (0.08, 1.05, 1.05), (ANCHO * 0.5 + 0.36, by, z_top + 1.05), m_win_luz))
        for bx in (-1.8, 1.8):
            piezas.append(lb.caja("Buhardilla_Y", (1.65, 1.55, 1.65), (bx, -LARGO * 0.5 + 0.45, z_top + 1.05), m_moldura, bisel=0.05, segs_bisel=1))
            piezas.append(lb.caja("Buhardilla_WinY", (1.05, 0.08, 1.05), (bx, -LARGO * 0.5 - 0.34, z_top + 1.05), m_win_luz))

    if azotea in ("torre_vent", "atico_jardin"):
        piezas.append(lb.caja("Atico_Caseta", (3.30, 4.10, 2.25), (0.90, 2.30, z_top + 1.12), m_pared, bisel=0.05, segs_bisel=1))
        piezas.append(lb.caja("Atico_Tapa", (3.70, 4.50, 0.32), (0.90, 2.30, z_top + 2.36), m_techo, bisel=0.04, segs_bisel=1))
        piezas.append(lb.caja("AC_Unidad", (1.65, 1.65, 1.15), (1.40, -2.50, z_top + 0.58), m_techo, bisel=0.04, segs_bisel=1))
        piezas.append(lb.cilindro("AC_Ventilador", 0.56, 0.56, 0.14, (1.40, -2.50, z_top + 1.18), m_hierro, eje="Z", lados=14))
        # Conductos cilíndricos metálicos sobre azotea
        piezas.append(lb.tubo_ruta("Conducto_Azotea", [Vector((1.40, -1.60, z_top + 0.45)), Vector((1.40, 0.60, z_top + 0.45)), Vector((0.90, 0.60, z_top + 1.30))], 0.24, m_techo, lados=10))

    if azotea == "corona_torre":
        # Corona Art-Decó escalonada con pináculo y antena + parabólica
        piezas.append(lb.caja("Corona_Nivel1", (ANCHO - 1.6, LARGO - 2.6, 2.60), (0.0, 0.0, z_top + 1.30), m_pared, bisel=0.06, segs_bisel=1, subdiv_y=6))
        piezas.append(lb.caja("Corona_Mold1", (ANCHO - 1.1, LARGO - 2.1, 0.36), (0.0, 0.0, z_top + 2.75), m_moldura, bisel=0.04, segs_bisel=1))
        piezas.append(lb.caja("Corona_Nivel2", (3.80, 4.40, 2.10), (0.0, -1.20, z_top + 3.90), m_acento, bisel=0.08, segs_bisel=2))
        piezas.append(lb.cilindro("Mastil_Antena", 0.12, 0.03, 3.60, (0.0, -1.20, z_top + 6.70), m_hierro, eje="Z", lados=10))
        piezas.append(lb.cilindro("Chimenea_ArtDeco", 0.44, 0.44, 2.40, (2.20, 2.80, z_top + 1.20), m_moldura, eje="Z", lados=10))


def construir(idx: int):
    _, nombre, pisos, c_pared, c_mol, c_acc, c_hierro, c_mad, c_techo, tipo, azotea = ESTILOS[idx]
    b_h = pisos * 3.85 + 0.80  # 16.2 m .. 20.05 m

    m_pared = lb.material(f"Edif_{idx}_Pared", c_pared, rough=0.74, metal=0.04)
    m_moldura = lb.material(f"Edif_{idx}_Moldura", c_mol, rough=0.68, metal=0.05)
    m_acento = lb.material(f"Edif_{idx}_Acento", c_acc, rough=0.44, metal=0.12)
    m_hierro = lb.material(f"Edif_{idx}_Hierro", c_hierro, rough=0.45, metal=0.62)
    m_madera = lb.material(f"Edif_{idx}_Madera", c_mad, rough=0.80, metal=0.04)
    m_techo = lb.material(f"Edif_{idx}_Techo", c_techo, rough=0.64, metal=0.24)
    m_win_luz = lb.material(f"Edif_{idx}_VentanaLuz", "#3469a6", rough=0.10, metal=0.32)
    m_win_osc = lb.material(f"Edif_{idx}_VentanaOsc", "#204068", rough=0.12, metal=0.35)

    piezas = []
    rng = random.Random(900 + idx * 31)

    # 1. Bloque principal con zócalo de granito saliente y cadenas de esquina
    piezas.append(lb.caja("Edif_Cuerpo", (ANCHO, LARGO, b_h), (0.0, 0.0, b_h * 0.5), m_pared, subdiv_y=8))
    piezas.append(lb.caja("Edif_Zocalo", (ANCHO + 0.32, LARGO + 0.32, 1.10), (0.0, 0.0, 0.55), m_moldura, subdiv_y=8))

    # Pilastras de esquina acanaladas en todos los edificios (rompen la silueta de caja lisa!)
    hx = ANCHO * 0.5
    hy = LARGO * 0.5
    for sx in (-1.0, 1.0):
        for sy in (-1.0, 1.0):
            piezas.append(lb.caja("Pilastra_Esquina", (0.48, 0.48, b_h), (sx * (hx - 0.12), sy * (hy - 0.12), b_h * 0.5), m_moldura, bisel=0.03, segs_bisel=1))

    if tipo == "bay_artdeco":
        for py in (-3.25, 3.25):
            piezas.append(lb.caja("Edif_PilastraArt", (0.36, 0.44, b_h - 0.80), (hx + 0.12, py, b_h * 0.5 + 0.3), m_moldura, bisel=0.02, segs_bisel=1))

    # 2. Plantas + ventanas 3D profundas + toldos visibles arriba de 4.65 m
    for piso in range(pisos):
        z_suelo = 0.80 + piso * 3.85
        z_win = z_suelo + 1.95
        es_visible_comercio = (piso == 1)  # Piso 1 queda justo sobre el muro de ladrillo!

        if piso > 0:
            piezas.append(lb.caja("Edif_Imposta", (ANCHO + 0.38, LARGO + 0.38, 0.28), (0.0, 0.0, z_suelo), m_moldura, bisel=0.02, segs_bisel=1, subdiv_y=8))

        for wy in (-4.60, -1.55, 1.55, 4.60):
            mat_w = m_win_luz if rng.random() < 0.64 else m_win_osc
            _construir_ventana(piezas, hx, wy, z_win, "+X", tipo, es_visible_comercio, mat_w, m_moldura, m_acento, m_hierro, rng)

        for end_eje, end_y in (("-Y", -hy), ("+Y", hy)):
            for wx in (-2.05, 2.05):
                mat_w = m_win_luz if rng.random() < 0.64 else m_win_osc
                _construir_ventana(piezas, wx, end_y, z_win, end_eje, tipo, False, mat_w, m_moldura, m_acento, m_hierro, rng)

    # Escalera de incendios 3D NYC en Terracota y Coral
    if tipo in ("fire_escape", "balcon"):
        _construir_escalera_incendios(piezas, hx, hy, pisos, m_hierro, m_acento)

    # 3. Cornisa saliente dentada, pretil y arquitectura rica de azotea
    piezas.append(lb.caja("Cornisa_Moldura", (ANCHO + 0.80, LARGO + 0.80, 0.60), (0.0, 0.0, b_h + 0.26), m_moldura, bisel=0.04, segs_bisel=1, subdiv_y=8))
    piezas.append(lb.caja("Cornisa_Parapeto", (ANCHO + 0.42, LARGO + 0.42, 0.46), (0.0, 0.0, b_h + 0.78), m_techo, bisel=0.03, segs_bisel=1, subdiv_y=8))

    _construir_azotea(piezas, b_h, azotea, m_pared, m_moldura, m_acento, m_hierro, m_madera, m_techo, m_win_luz)

    obj = lb.unir(piezas, f"Edificio_{idx}_{nombre}")
    obj.location = (0.0, 0.0, 0.0)
    lb.suavizar_por_angulo(obj, 35.0)
    return obj


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--indice", type=int, default=-1, help="0..4 o -1 para generar los 5")
    ap.add_argument("--sin-render", action="store_true")
    args = ap.parse_args(argv)

    indices = list(range(5)) if args.indice < 0 else [args.indice]
    for idx in indices:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        obj = construir(idx)
        lb.exportar_glb(obj, f"Modelos/Minijuego_Correr/edificio_{idx}.glb")
        if idx == 0:
            lb.guardar_blend(f"Arte_Fuente/Modelos3D/Correr/edificio_{idx}.blend")
        if not args.sin_render:
            lb.render_cuatro_vistas(obj, f"Arte_Fuente/Modelos3D/Correr/edificio_{idx}_preview.png", con_referencia=False)


if __name__ == "__main__":
    main()
