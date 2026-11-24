"""
Perro compañero del Inspector estilo Subway Surfers (`enemies.png`: pelaje crema dorado,
orejas y lomo chocolate, gran hocico redondeado expresivo y collar rojo con chapa dorada).
Frente mirando hacia +Y en Blender (= -Z en Godot). Origen en (0, 0, 0).
"""

import math
import os
import sys

import bpy

DIR_ACTUAL = os.path.dirname(os.path.abspath(__file__))
if DIR_ACTUAL not in sys.path:
    sys.path.insert(0, DIR_ACTUAL)

import lib_blender as lb

ESCALA_K9 = 1.15


def _pata(nombre: str, loc, delantera: bool, m_crema, m_marron, m_osc):
    """Pata robusta estilo caricatura con zarpas gruesas (base a Z = 0)."""
    piezas = []
    s = ESCALA_K9
    r_top = (0.076 if delantera else 0.090) * s
    h_piv = 0.34 * s
    piezas.append(lb.esfera("Artic_Sup", r_top, (0.0, 0.0, 0.0), m_crema, subdiv=2))
    piezas.append(lb.revolucion("Muslo", [
        (0.0, -0.18 * s), (0.056 * s, -0.17 * s), (r_top * 0.96, -0.05 * s), (r_top * 0.85, 0.02 * s), (0.0, 0.03 * s)
    ], (0.0, 0.0, 0.0), m_crema, lados=14))
    y_cana = (0.010 if delantera else -0.010) * s
    piezas.append(lb.cilindro("Cana", 0.048 * s, 0.056 * s, 0.145 * s, (0.0, y_cana, -0.22 * s), m_crema, eje="Z", lados=12))
    piezas.append(lb.esfera("Zarpa", 0.066 * s, (0.0, 0.042 * s, -h_piv + 0.042 * s), m_crema, escala=(1.0, 1.32, 0.66), subdiv=2))
    piezas.append(lb.esfera("Almohadilla", 0.052 * s, (0.0, 0.042 * s, -h_piv + 0.020 * s), m_osc, escala=(0.9, 1.18, 0.38), subdiv=1))

    obj = lb.unir(piezas, nombre)
    obj.location = loc
    lb.suavizar_por_angulo(obj, 35.0)
    return obj


def _cuerpo(m_crema, m_marron, m_collar, m_chaleco, m_metal):
    """Cuerpo regordete/musculoso color crema con manto chocolate y collar rojo."""
    piezas = []
    s = ESCALA_K9
    z_eje = 0.43 * s

    perfil_tronco = [
        (0.0, -0.31 * s),
        (0.125 * s, -0.29 * s),
        (0.182 * s, -0.24 * s),
        (0.205 * s, -0.16 * s),
        (0.185 * s, -0.05 * s),
        (0.222 * s, 0.08 * s),
        (0.238 * s, 0.17 * s),
        (0.205 * s, 0.25 * s),
        (0.0, 0.29 * s),
    ]
    piezas.append(lb.revolucion("Tronco_Perro", perfil_tronco, (0.0, 0.02 * s, z_eje), m_crema, lados=18,
                                escala_xy=(0.94, 1.04), rot=(math.radians(-90), 0.0, 0.0)))
    # Cuello cremoso + collar rojo ancho + chapa dorada (sin parche tangente en el lomo)
    piezas.append(lb.revolucion("Cuello", [
        (0.0, -0.09 * s), (0.172 * s, -0.08 * s), (0.155 * s, 0.02 * s), (0.142 * s, 0.10 * s), (0.0, 0.11 * s)
    ], (0.0, 0.22 * s, 0.50 * s), m_crema, lados=16, rot=(math.radians(-24), 0.0, 0.0)))
    piezas.append(lb.toro("Collar_Rojo", 0.160 * s, 0.032 * s, (0.0, 0.24 * s, 0.515 * s), m_collar, eje="Z", segs_mayor=20, segs_menor=8, rot=(math.radians(-24), 0.0, 0.0)))
    piezas.append(lb.esfera("Chapa_Oro", 0.044 * s, (0.0, 0.388 * s, 0.435 * s), m_chaleco, escala=(1.0, 0.45, 1.15), subdiv=1))
    piezas.append(lb.toro("Collar_Anilla", 0.022 * s, 0.006 * s, (0.0, 0.378 * s, 0.468 * s), m_metal, eje="X", segs_mayor=10, segs_menor=5))

    obj = lb.unir(piezas, "Cuerpo")
    obj.location = (0.0, 0.0, 0.0)
    lb.suavizar_por_angulo(obj, 35.0)
    return obj


def _cabeza(m_crema, m_marron, m_osc, m_blanco):
    """Cabeza grande caricaturesca con gran hocico redondeado, trufa gorda y orejas chocolate."""
    piezas = []
    s = ESCALA_K9
    piezas.append(lb.esfera("Craneo", 0.178 * s, (0.0, 0.0, 0.0), m_crema, escala=(1.02, 1.05, 0.98), subdiv=2))
    # Hocico ancho y gordo estilizado (enemies.png arriba izq)
    piezas.append(lb.esfera("Hocico_Bozal", 0.115 * s, (0.0, 0.165 * s, -0.025 * s), m_crema, escala=(0.98, 1.18, 0.78), subdiv=2))
    piezas.append(lb.caja("Mandibula", (0.125 * s, 0.145 * s, 0.052 * s), (0.0, 0.135 * s, -0.095 * s), m_crema, bisel=0.022 * s, segs_bisel=2, rot=(math.radians(8), 0.0, 0.0)))
    for sx in (-1.0, 1.0):
        piezas.append(lb.cilindro("Colmillo_Sup", 0.002, 0.011 * s, 0.030 * s, (sx * 0.042 * s, 0.210 * s, -0.068 * s), m_blanco, eje="Z", lados=6))

    piezas.append(lb.esfera("Trufa_Gorda", 0.055 * s, (0.0, 0.275 * s, 0.002 * s), m_osc, escala=(1.12, 0.92, 0.85), subdiv=2))
    for sx in (-1.0, 1.0):
        piezas.append(lb.esfera("Ojo_Blanco", 0.040 * s, (sx * 0.076 * s, 0.135 * s, 0.062 * s), m_blanco, escala=(0.95, 0.58, 1.05), subdiv=2))
        piezas.append(lb.esfera("Ojo_Pupila", 0.024 * s, (sx * 0.078 * s, 0.155 * s, 0.062 * s), m_osc, escala=(0.9, 0.55, 0.95), subdiv=1))
        piezas.append(lb.caja("Ceja", (0.068 * s, 0.040 * s, 0.028 * s), (sx * 0.076 * s, 0.130 * s, 0.105 * s), m_marron, bisel=0.010 * s, segs_bisel=1, rot=(0.0, sx * math.radians(-14), 0.0)))
        piezas.append(lb.cilindro("Oreja_Chocolate", 0.066 * s, 0.018 * s, 0.175 * s, (sx * 0.115 * s, -0.020 * s, 0.165 * s), m_marron, eje="Z", lados=10, rot=(math.radians(-8), sx * math.radians(22), 0.0)))

    obj = lb.unir(piezas, "Cabeza")
    obj.location = (0.0, 0.29 * s, 0.57 * s)
    lb.suavizar_por_angulo(obj, 35.0)
    return obj


def _cola(m_crema, m_marron):
    s = ESCALA_K9
    pts = [
        (0.0, 0.0, 0.0),
        (0.0, -0.14 * s, 0.07 * s),
        (0.0, -0.25 * s, 0.18 * s),
    ]
    t1 = lb.tubo_ruta("Cola_Base", pts, [0.055 * s, 0.046 * s, 0.028 * s], m_marron, lados=10, catmull_subdiv=2)
    t2 = lb.esfera("Cola_Punta", 0.032 * s, (0.0, -0.25 * s, 0.18 * s), m_crema, subdiv=1)
    obj = lb.unir([t1, t2], "Cola")
    obj.location = (0.0, -0.24 * s, 0.46 * s)
    lb.suavizar_por_angulo(obj, 35.0)
    return obj


def construir():
    m_crema = lb.material("Perro_Crema", "#e0be91", rough=0.76, metal=0.0)
    m_marron = lb.material("Perro_Chocolate", "#5e361c", rough=0.72, metal=0.0)
    m_osc = lb.material("Perro_Oscuro", "#1d1613", rough=0.38, metal=0.05)
    m_collar = lb.material("Perro_Collar", "#d63022", rough=0.45, metal=0.05)
    m_chaleco = lb.material("Perro_Chapa", "#facc15", rough=0.30, metal=0.65,
                            emision="#facc15", emision_fuerza=0.25)
    m_blanco = lb.material("Perro_Blanco", "#f8fafc", rough=0.32, metal=0.0)
    m_metal = lb.material("Perro_Metal", "#cbd5e1", rough=0.28, metal=0.80)

    raiz = bpy.data.objects.new("Perro_Root", None)
    bpy.context.collection.objects.link(raiz)

    s = ESCALA_K9
    cuerpo = _cuerpo(m_crema, m_marron, m_collar, m_chaleco, m_metal)
    cabeza = _cabeza(m_crema, m_marron, m_osc, m_blanco)
    cola = _cola(m_crema, m_marron)
    pata_di = _pata("Pata_DI", (-0.125 * s, 0.16 * s, 0.34 * s), True, m_crema, m_marron, m_osc)
    pata_dd = _pata("Pata_DD", (0.125 * s, 0.16 * s, 0.34 * s), True, m_crema, m_marron, m_osc)
    pata_ti = _pata("Pata_TI", (-0.125 * s, -0.18 * s, 0.34 * s), False, m_crema, m_marron, m_osc)
    pata_td = _pata("Pata_TD", (0.125 * s, -0.18 * s, 0.34 * s), False, m_crema, m_marron, m_osc)

    for p in (cuerpo, cabeza, cola, pata_di, pata_dd, pata_ti, pata_td):
        p.parent = raiz

    bpy.context.view_layer.update()
    return [raiz, cuerpo, cabeza, cola, pata_di, pata_dd, pata_ti, pata_td]


def main():
    args = lb.parsear_args_modelo("Modelos/Minijuego_Correr/perro_policia.glb")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    objs = construir()
    lb.exportar_glb(objs, args.salida)
    if args.blend:
        lb.guardar_blend(args.blend)
    if args.render and not args.sin_render:
        lb.render_cuatro_vistas(objs, args.render, con_referencia=False)


if __name__ == "__main__":
    main()
