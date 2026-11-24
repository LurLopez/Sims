"""
Vagón de metro Blender fiel al estilo icónico de Subway Surfers (`train_standard` / `train_cargo`)
para PARK RUSH 3D («Salir a correr»).

Rasgos estructurales reales clonados:
  - Sección transversal trapezoidal estrechada hacia arriba (~6° de inclinación lateral)
  - Zócalo/faldón perimetral inferior de acero sobresaliente (ANCHO = 2.28 m) sobre bogies
  - Techo abovedado pizarra azulada con 8 arcos/costillas transversales (altura máxima <= 3.04 m)
  - Ventanales panorámicos y puertas laterales inclinados enrasados al ángulo de la pared
  - Testeros aerodinámicos inclinados con gran marco de cabina, doble parabrisas, faros y letrero LED

Medidas exactas de Runner_Simulacion:
    ANCHO <= 2.28 m (-1.14..+1.14)
    ALTO  <= 3.05 m (ruedas apoyan en z = 0.145 m; bóveda corona <= 3.02 m)
    LARGO <= 13.52 m (-6.76..+6.76)
"""

import math
import os
import subprocess
import sys

import bmesh
import bpy

DIR_ACTUAL = os.path.dirname(os.path.abspath(__file__))
if DIR_ACTUAL not in sys.path:
    sys.path.insert(0, DIR_ACTUAL)

import lib_blender as lb

ANCHO = 2.28
ALTO = 3.05
LARGO = 13.50
Z_RAIL_TOP = 0.145

HW = ANCHO * 0.5          # 1.140 (borde exterior del chasis perimetral)
HL = LARGO * 0.5          # 6.750
Z_CHASIS_BOT = 0.42
Z_WAIST = 0.58            # Inicio de carrocería pintada encima del chasis de acero
Z_EAVES = 2.66            # Aleros superiores donde arranca la bóveda del techo
HW_BOT = 1.075            # Semiancho inferior de carrocería
HW_TOP = 0.850            # Semiancho superior en aleros (inclinación icónica ~6°)
WALL_DZ = Z_EAVES - Z_WAIST
WALL_DX = HW_BOT - HW_TOP
WALL_TILT = math.atan2(WALL_DX, WALL_DZ)   # ~5.98° inclinación hacia dentro
WALL_LEN = math.hypot(WALL_DX, WALL_DZ)
NX_OUT = math.cos(WALL_TILT)
NZ_OUT = math.sin(WALL_TILT)

HL_NOSE = 6.66            # Pie del morro en y
RAKE_ANG = math.radians(7.0)  # Retroceso suave de testeros frontal/trasero

RAIZ_PROYECTO = os.path.abspath(os.path.join(DIR_ACTUAL, "..", "..", ".."))
DIR_TEX = os.path.join(RAIZ_PROYECTO, "Imagenes", "Minijuego_Correr", "Texturas3D")

LIBREAS = [
    ("EXPRESS", "#2f4354", "#c82d1f"),
    ("METRO 1", "#9e1c14", "#a6c624"),
    ("CARGA 7", "#253442", "#9fb8c9"),
    ("CITY EX", "#1c2d42", "#facc15"),
]


def _x_pared(z: float, escala_x: float = 1.0) -> float:
    t = max(0.0, min(1.0, (z - Z_WAIST) / WALL_DZ))
    return (HW_BOT - WALL_DX * t) * escala_x


def _y_cabina(signo: float, z: float) -> float:
    if z <= Z_WAIST:
        return signo * HL_NOSE
    return signo * (HL_NOSE - (z - Z_WAIST) * math.tan(RAKE_ANG))


def _rutas_texturas(idx: int = 0):
    return {
        "carroceria": os.path.join(DIR_TEX, f"vagon_bl_carroceria_{idx}.png"),
        "letrero": os.path.join(DIR_TEX, f"vagon_bl_letrero_{idx}.png"),
        "cristal": os.path.join(DIR_TEX, "vagon_bl_cristal.png"),
        "cristal_em": os.path.join(DIR_TEX, "vagon_bl_cristal_em.png"),
        "techo": os.path.join(DIR_TEX, "vagon_bl_techo.png"),
        "techo_norm": os.path.join(DIR_TEX, "vagon_bl_techo_normal.png"),
    }


def _asegurar_texturas(idx: int = 0):
    rutas = _rutas_texturas(idx)
    if not all(os.path.exists(p) for p in rutas.values()):
        subprocess.run(["python3", os.path.join(DIR_ACTUAL, "generar_texturas_modelos.py")], check=True)
    return rutas


def _construir_casco_trapezoidal(mat_carroceria):
    """Casco trapezoidal característico de Subway Surfers (ancho abajo -> estrecho en aleros) con 18 cortes en Y."""
    anillos = [
        (-HL_NOSE, 0.94, 1.0),
        (-6.48,    0.98, 0.55),
        (-6.12,    1.00, 0.0),
    ]
    n_med = 14
    for i in range(1, n_med):
        anillos.append((-6.12 + 12.24 * i / n_med, 1.00, 0.0))
    anillos.extend([
        (6.12,    1.00, 0.0),
        (6.48,    0.98, 0.55),
        (HL_NOSE, 0.94, 1.0),
    ])

    zs_sec = (Z_WAIST, 1.15, 1.85, Z_EAVES)
    bm = bmesh.new()
    capas = []
    for y_base, esc_x, peso_m in anillos:
        signo_y = -1.0 if y_base < 0 else 1.0
        pts = []
        # Lado izquierdo (-X) subiendo hacia alero izquierdo
        for z in zs_sec:
            pts.append((-_x_pared(z, esc_x), z))
        # Techo base plano bajo bóveda
        # Lado derecho (+X) bajando hasta cintura
        for z in reversed(zs_sec):
            pts.append((_x_pared(z, esc_x), z))

        anillo_v = []
        for px, pz in pts:
            yv = y_base
            if peso_m > 0.0 and pz > Z_WAIST:
                yv -= signo_y * (pz - Z_WAIST) * math.tan(RAKE_ANG) * peso_m
            anillo_v.append(bm.verts.new((px, yv, pz)))
        capas.append(anillo_v)

    n = len(capas[0])
    for i in range(len(capas) - 1):
        a, b = capas[i], capas[i + 1]
        for j in range(n):
            k = (j + 1) % n
            bm.faces.new((a[j], a[k], b[k], b[j]))
    bm.faces.new(tuple(reversed(capas[0])))
    bm.faces.new(tuple(capas[-1]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)

    uv_layer = bm.loops.layers.uv.verify()
    for face in bm.faces:
        nrm = face.normal
        for loop in face.loops:
            co = loop.vert.co
            v_h = max(0.0, min(1.0, (co.z - Z_WAIST) / WALL_DZ))
            if abs(nrm.x) > 0.35:
                u = (co.y + HL_NOSE) / (2.0 * HL_NOSE)
                if nrm.x < 0:
                    u = 1.0 - u
                loop[uv_layer].uv = (u, v_h)
            else:
                # Testers frente/atrás sobre franja limpia de color lateral sin grafiti
                u_c = 0.015 + 0.03 * ((co.x + HW) / (2.0 * HW))
                loop[uv_layer].uv = (u_c, v_h)

    return lb.finalizar_bmesh("Carroceria_Trapezoidal", bm, mat_carroceria)


def _construir_boveda_techo(mat_techo, mat_acero_osc):
    """Techo abovedado clásico de Subway Surfers + 8 arcos oscuros transversales (altura <= 3.03 m)."""
    piezas = []
    segs_y = 18
    # Perfil curvo de bóveda (de -HW_TOP a +HW_TOP, corona central a z = 2.97 m <= 3.05 m)
    perfil_techo = []
    n_arc = 8
    for i in range(n_arc + 1):
        u_a = -1.0 + 2.0 * (i / n_arc)
        px = u_a * (HW_TOP + 0.025)
        pz = (Z_EAVES - 0.02) + 0.31 * (1.0 - u_a * u_a)
        perfil_techo.append((px, pz))
    # Cierre plano inferior del perfil abovedado
    for i in range(n_arc, -1, -1):
        u_a = -1.0 + 2.0 * (i / n_arc)
        perfil_techo.append((u_a * (HW_TOP - 0.02), Z_EAVES - 0.05))

    bm = bmesh.new()
    capas = []
    y_ini, y_fin = -6.34, 6.34
    for iy in range(segs_y + 1):
        y = y_ini + (y_fin - y_ini) * (iy / segs_y)
        peso = max(0.0, (abs(y) - 6.08) / 0.26) if abs(y) > 6.08 else 0.0
        esc_x = 1.0 - 0.045 * peso
        capa = [bm.verts.new((px * esc_x, y, pz - 0.015 * peso)) for px, pz in perfil_techo]
        capas.append(capa)

    n = len(capas[0])
    for i in range(segs_y):
        a, b = capas[i], capas[i + 1]
        for j in range(n):
            k = (j + 1) % n
            bm.faces.new((a[j], a[k], b[k], b[j]))
    bm.faces.new(tuple(reversed(capas[0])))
    bm.faces.new(tuple(capas[-1]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)

    uv_layer = bm.loops.layers.uv.verify()
    for face in bm.faces:
        for lp in face.loops:
            co = lp.vert.co
            u = (co.x + HW_TOP) / (2.0 * HW_TOP)
            v = ((co.y - y_ini) / (y_fin - y_ini)) * 3.0
            lp[uv_layer].uv = (u, v)
    piezas.append(lb.finalizar_bmesh("Techo_Boveda", bm, mat_techo))

    # 8 Costillas/arcos estructurales oscuros sobre la bóveda (z <= 3.015 m, seña de Subway Surfers!)
    for ay in (-5.50, -3.92, -2.35, -0.78, 0.78, 2.35, 3.92, 5.50):
        pts_arc = []
        for i in range(n_arc + 1):
            u_a = -1.0 + 2.0 * (i / n_arc)
            px = u_a * (HW_TOP + 0.008)
            pz = (Z_EAVES - 0.018) + 0.312 * (1.0 - u_a * u_a) + 0.022
            pts_arc.append((px, ay, pz))
        piezas.append(lb.tubo_ruta("Techo_ArcoCostilla", pts_arc, 0.034, mat_acero_osc,
                                   lados=6, escala_ab=(1.35, 0.72)))

    # Pasarela central delgada antideslizante <= 3.035 m (sin estorbar al corredor)
    for ay in (-3.15, 3.15):
        piezas.append(lb.caja("Techo_Respiradero", (0.76, 1.15, 0.036), (0.0, ay, 2.985),
                              mat_acero_osc, bisel=0.008, segs_bisel=1))

    return piezas


def _construir_zocalo_perimetral(mat_acero, mat_acero_osc, mat_franja):
    """Chasis/faldón inferior sobresaliente (ANCHO = 2.28 m) que envuelve el vagón entero como en Subway Surfers."""
    piezas = []
    # Bandas laterales completas (18 cortes) sobresaliendo hasta ±HW = ±1.14 m
    piezas.append(lb.caja("Chasis_Cuerpo", (ANCHO - 0.04, HL * 2.0 - 0.06, 0.16),
                          (0.0, 0.0, Z_CHASIS_BOT + 0.08), mat_acero_osc,
                          bisel=0.018, segs_bisel=1, subdiv_y=18))
    piezas.append(lb.caja("Chasis_BordeAcero", (ANCHO, HL * 2.0 - 0.04, 0.08),
                          (0.0, 0.0, Z_WAIST - 0.01), mat_acero,
                          bisel=0.014, segs_bisel=1, subdiv_y=18))
    # Ribetes inferiores en los testeros
    for signo in (-1, 1):
        piezas.append(lb.caja("Parachoques_Franja", (ANCHO - 0.18, 0.08, 0.095),
                              (0.0, signo * (HL - 0.02), Z_CHASIS_BOT + 0.10), mat_franja,
                              bisel=0.010, segs_bisel=1))
    return piezas


def _construir_rueda(nombre, centro, mat_osc, mat_metal):
    r_flange = 0.285
    r_tread = 0.258
    perfil = [
        (0.0, -0.075), (r_flange, -0.075), (r_flange, -0.052),
        (r_tread, -0.042), (r_tread, 0.064), (r_tread - 0.025, 0.074),
        (0.11, 0.066), (0.11, 0.078), (0.0, 0.078),
    ]
    sx = 1.0 if centro[0] >= 0 else -1.0
    ry = math.radians(90) if sx > 0 else math.radians(-90)
    rueda = lb.revolucion(nombre, perfil, centro, mat_osc, lados=16, rot=(0.0, ry, 0.0))
    buje = lb.cilindro(
        nombre + "_Buje", 0.085, 0.100, 0.048,
        (centro[0] + sx * 0.080, centro[1], centro[2]),
        mat_metal, eje="X", lados=12, bisel_tapa=0.010,
    )
    return [rueda, buje]


def construir(librea_idx: int = 0):
    rutas = _asegurar_texturas(librea_idx)
    _, c_cab, c_franja = LIBREAS[librea_idx]

    m_carroceria = lb.material("Vagon_Carroceria", "#ffffff", rough=0.40, metal=0.10,
                               tex_albedo=rutas["carroceria"])
    m_franja = lb.material("Vagon_Franja", c_franja, rough=0.38, metal=0.08)
    m_acero = lb.material("Vagon_Metal", "#7d9db5", rough=0.34, metal=0.58)
    m_acero_osc = lb.material("Vagon_MetalOsc", "#283847", rough=0.50, metal=0.48)
    m_techo = lb.material("Vagon_Techo", "#ffffff", rough=0.48, metal=0.32,
                          tex_albedo=rutas["techo"], tex_normal=rutas["techo_norm"], normal_fuerza=0.95)
    m_cristal = lb.material("Vagon_Cristal", "#ffffff", rough=0.12, metal=0.22,
                            tex_albedo=rutas["cristal"])
    m_letrero = lb.material("Vagon_LetreroLED", "#ffffff", rough=0.18, metal=0.05,
                            tex_albedo=rutas["letrero"], tex_emission=rutas["letrero"], emision_fuerza=1.9)
    m_faro = lb.material("Vagon_Faro", "#fff8d6", rough=0.12, metal=0.0,
                         emision="#ffe88a", emision_fuerza=4.8)

    piezas = []

    # 1. Casco principal trapezoidal (~6° estrechamiento superior) + zócalo perimetral saliente
    piezas.append(_construir_casco_trapezoidal(m_carroceria))
    piezas.extend(_construir_zocalo_perimetral(m_acero, m_acero_osc, m_franja))

    # 2. Costados inclinados exactos enrasados a la pared (~5.98°): 2 puertas extremas + 4 ventanas grandes
    puertas_y = (-4.95, 4.95)
    ventanas_y = (-2.85, -0.95, 0.95, 2.85)

    for lado in (-1, 1):
        rot_w = (0.0, -lado * WALL_TILT, 0.0)

        # Vierteaguas superior saliente bajo la bóveda del techo
        zw_top = Z_EAVES - 0.04
        xw_top = _x_pared(zw_top)
        piezas.append(lb.caja("Vierteaguas", (0.080, HL * 2.0 - 1.0, 0.075),
                              (lado * (xw_top + 0.025), 0.0, zw_top), m_acero_osc,
                              bisel=0.012, segs_bisel=1, subdiv_y=18))

        # 4 Ventanas panorámicas Subway Surfers con marco robusto moldeado + cristal celeste glaciar
        zw = 1.98
        xw = _x_pared(zw)
        for vy in ventanas_y:
            piezas.append(lb.caja("Ventana_Marco", (0.065, 1.32, 0.92),
                                  (lado * (xw + 0.010 * NX_OUT), vy, zw + 0.010 * NZ_OUT),
                                  m_acero_osc, bisel=0.018, segs_bisel=2, rot=rot_w))
            piezas.append(lb.panel_uv("Ventana_Cristal", (0.024, 1.18, 0.78),
                                      (lado * (xw + 0.032 * NX_OUT), vy, zw + 0.032 * NZ_OUT),
                                      m_cristal, cara_uv="+X" if lado > 0 else "-X", rot=rot_w))
            piezas.append(lb.caja("Ventana_Alfeizar", (0.085, 1.36, 0.055),
                                  (lado * (_x_pared(1.50) + 0.024), vy, 1.50),
                                  m_acero, bisel=0.010, segs_bisel=1, rot=rot_w))

        # 2 Puertas de pasajeros extremas con marco rehundido, hoja y ventanilla alta
        zp = 1.56
        xp = _x_pared(zp)
        for py in puertas_y:
            piezas.append(lb.caja("Puerta_Marco", (0.060, 1.18, 1.88),
                                  (lado * (xp + 0.008 * NX_OUT), py, zp + 0.008 * NZ_OUT),
                                  m_acero_osc, bisel=0.014, segs_bisel=2, rot=rot_w))
            piezas.append(lb.caja("Puerta_Hoja", (0.052, 1.04, 1.76),
                                  (lado * (xp + 0.022 * NX_OUT), py, zp + 0.022 * NZ_OUT),
                                  m_acero, bisel=0.012, segs_bisel=1, rot=rot_w))
            zpv = 2.04
            xpv = _x_pared(zpv)
            piezas.append(lb.caja("Puerta_VentanaMarco", (0.045, 0.68, 0.56),
                                  (lado * (xpv + 0.038 * NX_OUT), py, zpv + 0.038 * NZ_OUT),
                                  m_acero_osc, bisel=0.010, segs_bisel=1, rot=rot_w))
            piezas.append(lb.panel_uv("Puerta_Cristal", (0.022, 0.56, 0.44),
                                      (lado * (xpv + 0.052 * NX_OUT), py, zpv + 0.052 * NZ_OUT),
                                      m_cristal, cara_uv="+X" if lado > 0 else "-X", rot=rot_w))

        # Costillas/pilastras estructurales inclinadas junto a las puertas extremas (sin tapar el grafiti central)
        for py in (-5.78, -4.12, 4.12, 5.78):
            zc = 1.62
            xc = _x_pared(zc)
            piezas.append(lb.caja("Pilastra_Inclinada", (0.068, 0.14, 1.98),
                                  (lado * (xc + 0.016 * NX_OUT), py, zc + 0.016 * NZ_OUT),
                                  m_acero, bisel=0.012, segs_bisel=1, rot=rot_w))

    # 3. Techo abovedado pizarra con 8 arcos oscuros (<= 3.04 m)
    piezas.extend(_construir_boveda_techo(m_techo, m_acero_osc))

    # 4. Morros frontal y trasero inclinados 7° estilo Subway Surfers (trains.png top-left!)
    for signo in (-1, 1):
        cara_uv_f = "-Y" if signo < 0 else "+Y"
        tilt_x = signo * RAKE_ANG

        # Marco azul pizarra vertical característico de testero frontal Subway Surfers
        z_cab = 1.64
        y_cab = _y_cabina(signo, z_cab)
        piezas.append(lb.caja("Cabina_MarcoFrontal", (1.42, 0.12, 1.92),
                              (0.0, y_cab + signo * 0.015, z_cab),
                              m_acero_osc, bisel=0.022, segs_bisel=2, rot=(tilt_x, 0.0, 0.0)))
        piezas.append(lb.caja("Cabina_PanelInterno", (1.24, 0.10, 1.76),
                              (0.0, y_cab + signo * 0.032, z_cab),
                              m_acero, bisel=0.014, segs_bisel=1, rot=(tilt_x, 0.0, 0.0)))
        # Parteluz vertical central grueso entre los 2 parabrisas altos
        piezas.append(lb.caja("Cabina_Parteluz", (0.12, 0.10, 1.76),
                              (0.0, y_cab + signo * 0.055, z_cab),
                              m_acero_osc, bisel=0.010, segs_bisel=1, rot=(tilt_x, 0.0, 0.0)))
        for lado in (-1, 1):
            z_w = 2.02
            y_w = _y_cabina(signo, z_w)
            piezas.append(lb.caja("Cabina_GomaVent", (0.50, 0.06, 0.86),
                                  (lado * 0.34, y_w + signo * 0.055, z_w),
                                  m_acero_osc, bisel=0.010, segs_bisel=1, rot=(tilt_x, 0.0, 0.0)))
            piezas.append(lb.panel_uv("Cabina_Cristal", (0.42, 0.022, 0.76),
                                      (lado * 0.34, y_w + signo * 0.072, z_w),
                                      m_cristal, cara_uv=cara_uv_f, rot=(tilt_x, 0.0, 0.0)))

        # Letrero LED EXPRESS bajo visera curva de bóveda frontal
        z_let = 2.74
        y_let = _y_cabina(signo, z_let) + signo * 0.04
        piezas.append(lb.caja("Letrero_Pod", (1.22, 0.14, 0.32),
                              (0.0, y_let, z_let), m_acero_osc, bisel=0.018, segs_bisel=1,
                              rot=(tilt_x, 0.0, 0.0)))
        piezas.append(lb.panel_uv("Letrero_LED", (1.02, 0.02, 0.22),
                                  (0.0, y_let + signo * 0.072, z_let), m_letrero, cara_uv=cara_uv_f,
                                  rot=(tilt_x, 0.0, 0.0)))

        # Dos grandes faros circulares en esquinas bajas + parrilla frontal + enganche
        z_faro = 0.90
        y_faro = _y_cabina(signo, z_faro)
        for lado in (-1, 1):
            piezas.append(lb.cilindro("Faro_Carcasa", 0.175, 0.155, 0.10,
                                      (lado * 0.68, y_faro + signo * 0.035, z_faro),
                                      m_acero_osc, eje="Y", lados=16, bisel_tapa=0.012))
            piezas.append(lb.esfera("Faro_Lente", 0.135, (lado * 0.68, y_faro + signo * 0.080, z_faro),
                                    m_faro, escala=(1.0, 0.45, 1.0), subdiv=2))

        piezas.append(lb.caja("Parachoques_Cebra", (1.96, 0.16, 0.20),
                              (0.0, signo * (HL - 0.10), Z_CHASIS_BOT + 0.06),
                              m_acero_osc, bisel=0.020, segs_bisel=1))
        for sx in (-0.70, -0.42, -0.14, 0.14, 0.42, 0.70):
            piezas.append(lb.caja("Parachoques_Taco", (0.11, 0.025, 0.14),
                                  (sx, signo * (HL - 0.01), Z_CHASIS_BOT + 0.06),
                                  m_franja, bisel=0.004, rot=(0.0, math.radians(20), 0.0)))
        piezas.append(lb.caja("Enganche", (0.32, 0.20, 0.14),
                              (0.0, signo * (HL - 0.06), Z_CHASIS_BOT - 0.06),
                              m_acero_osc, bisel=0.015, segs_bisel=1))

    # 5. Bogies y ruedas ferroviarias (z = 0.145 m sobre el raíl)
    z_eje_rueda = Z_RAIL_TOP + 0.258
    for by in (-4.60, 4.60):
        piezas.append(lb.caja("Bogie_Travesano", (1.58, 2.28, 0.16),
                              (0.0, by, Z_CHASIS_BOT - 0.08), m_acero_osc, bisel=0.02, segs_bisel=1))
        for lado in (-1, 1):
            piezas.append(lb.caja("Bogie_Larguero", (0.14, 2.20, 0.16),
                                  (lado * 0.86, by, z_eje_rueda + 0.04), m_acero_osc, bisel=0.015, segs_bisel=1))
        for dy in (-0.78, 0.78):
            piezas.append(lb.cilindro("Bogie_Eje", 0.055, 0.055, 1.46,
                                      (0.0, by + dy, z_eje_rueda), m_acero_osc, eje="X", lados=10))
            for lado in (-1, 1):
                piezas.extend(_construir_rueda("Rueda", (lado * 0.70, by + dy, z_eje_rueda), m_acero_osc, m_acero))

    obj = lb.unir(piezas, "Vagon_Metro")
    obj.location = (0.0, 0.0, 0.0)
    lb.suavizar_por_angulo(obj, 35.0)
    return obj


def main():
    args = lb.parsear_args_modelo("Modelos/Minijuego_Correr/vagon_metro.glb")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    obj = construir(0)
    lb.exportar_glb(obj, args.salida)
    if args.blend:
        lb.guardar_blend(args.blend)
    if args.render and not args.sin_render:
        lb.render_cuatro_vistas(obj, args.render, con_referencia=True)


if __name__ == "__main__":
    main()
