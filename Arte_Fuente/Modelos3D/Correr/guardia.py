"""
Inspector / Guardia de Subway Surfers clonado en proporciones icónicas para Runner_Guardia_3D.gd:
  - Gran torso en pera/barril con barriga prominente baja y chaqueta verde oliva con solapas,
    charreteras y bolsillos con solapa (fiel a `enemies.png` y `default 7`)
  - Piernas cortas y estrechas en pantalón marrón con raya lateral crema y botas gruesas
  - Cabeza casi sin cuello con gran mandíbula, nariz redonda, enorme bigote negro y gorra plana inclinada

Frente mirando hacia +Y en Blender (= -Z en Godot, persiguiendo al Sim). Origen en (0, 0, 0).
"""

import math
import os
import sys

import bmesh
import bpy
from mathutils import Euler

DIR_ACTUAL = os.path.dirname(os.path.abspath(__file__))
if DIR_ACTUAL not in sys.path:
    sys.path.insert(0, DIR_ACTUAL)

import lib_blender as lb


def _malla_pera_asimetrica(nombre: str, anillos, mat, lados: int = 20):
    """Genera un sólido cerrado orgánico con secciones (rx, y_front, y_back, z)."""
    bm = bmesh.new()
    rings = []
    for rx, yf, yb, z in anillos:
        if rx <= 1e-5:
            rings.append([bm.verts.new((0.0, (yf + yb) * 0.5, z))])
        else:
            yc = (yf - yb) * 0.5
            ry = (yf + yb) * 0.5
            fila = []
            for s in range(lados):
                ang = math.tau * s / lados
                fila.append(bm.verts.new((math.cos(ang) * rx, yc + math.sin(ang) * ry, z)))
            rings.append(fila)

    for i in range(len(rings) - 1):
        a, b = rings[i], rings[i + 1]
        if len(a) == 1:
            for s in range(lados):
                bm.faces.new((a[0], b[s], b[(s + 1) % lados]))
        elif len(b) == 1:
            for s in range(lados):
                bm.faces.new((a[s], b[0], a[(s + 1) % lados]))
        else:
            for s in range(lados):
                sn = (s + 1) % lados
                bm.faces.new((a[s], a[sn], b[sn], b[s]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    lb._asignar_uvs_caja_bm(bm, 0.7)
    return lb.finalizar_bmesh(nombre, bm, mat)


def _visera_inspector_bm(mat):
    """Visera angular ancha inclinada al frente (+Y) clásica del Inspector."""
    bm = bmesh.new()
    segs = 10
    in_r, out_r = [], []
    for i in range(segs + 1):
        ang = -0.45 * math.pi + 0.90 * math.pi * (i / segs)
        sa, ca = math.sin(ang), math.cos(ang)
        r0, r1 = 0.165, 0.305
        dz = 0.036 * (ca ** 1.3)
        in_r.append((bm.verts.new((r0 * sa, r0 * ca + 0.03, 0.115)), bm.verts.new((r0 * sa, r0 * ca + 0.03, 0.095))))
        out_r.append((bm.verts.new((r1 * sa, r1 * ca + 0.03, 0.092 - dz)), bm.verts.new((r1 * sa, r1 * ca + 0.03, 0.074 - dz))))
    for i in range(segs):
        it0, ib0 = in_r[i]
        it1, ib1 = in_r[i + 1]
        ot0, ob0 = out_r[i]
        ot1, ob1 = out_r[i + 1]
        bm.faces.new((it0, ot0, ot1, it1))
        bm.faces.new((ib0, ib1, ob1, ob0))
        bm.faces.new((ot0, ob0, ob1, ot1))
    bm.faces.new((in_r[0][0], in_r[0][1], out_r[0][1], out_r[0][0]))
    bm.faces.new((in_r[-1][0], out_r[-1][0], out_r[-1][1], in_r[-1][1]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    lb._asignar_uvs_caja_bm(bm, 0.7)
    return lb.finalizar_bmesh("Gorra_Visera", bm, mat)


def _pierna(nombre: str, x_pos: float, side: float, m_pant, m_raya, m_cuero):
    """Pierna corta y delgada estilo caricatura Inspector (pivote cadera Z = 0.62 m)."""
    piezas = []
    # Pantalón cónico estrechado hacia el tobillo (de z=0 hasta -0.50 local -> Z=0.62..0.12 m)
    piezas.append(lb.revolucion("Muslo_Pant", [
        (0.0, -0.51), (0.056, -0.50), (0.072, -0.34), (0.096, -0.14), (0.112, 0.02), (0.0, 0.04)
    ], (0.0, 0.0, 0.0), m_pant, lados=12))
    # Raya lateral crema/caqui exterior siguiendo el ángulo hacia adentro de la pierna cónica
    piezas.append(lb.caja("Pant_RayaCrema", (0.022, 0.038, 0.42), (side * 0.084, 0.0, -0.25), m_raya, bisel=0.006,
                          rot=(0.0, side * math.radians(5.8), 0.0)))
    # Bota negra gruesa angular mirando hacia +Y (toca exactamente -0.62 = suelo Z=0)
    piezas.append(lb.cilindro("Bota_Tobillo", 0.068, 0.064, 0.09, (0.0, 0.0, -0.52), m_cuero, eje="Z", lados=10))
    piezas.append(lb.caja("Bota_Pie", (0.145, 0.255, 0.115), (0.0, 0.058, -0.562), m_cuero, bisel=0.022, segs_bisel=2))

    obj = lb.unir(piezas, nombre)
    obj.location = (x_pos, 0.0, 0.62)
    lb.suavizar_por_angulo(obj, 35.0)
    return obj


def _brazo(nombre: str, x_pos: float, side: float, m_oliva, m_oliva_osc, m_piel, m_cuero, m_metal, m_foco):
    """Manga gruesa oliva estrechada hacia la muñeca y mano regordeta (pivote en hombro)."""
    piezas = []
    piezas.append(lb.esfera("Hombro", 0.096, (0.0, 0.0, 0.0), m_oliva, subdiv=2))
    piezas.append(lb.revolucion("Manga", [
        (0.0, -0.37), (0.064, -0.36), (0.088, -0.20), (0.098, -0.02), (0.0, 0.0)
    ], (0.0, 0.0, 0.0), m_oliva, lados=14))
    piezas.append(lb.toro("Puno_Ribete", 0.068, 0.014, (0.0, 0.0, -0.355), m_oliva_osc, eje="Z", segs_mayor=12, segs_menor=6))
    piezas.append(lb.esfera("Mano", 0.072, (0.0, 0.015, -0.42), m_piel, escala=(0.95, 1.10, 0.98), subdiv=2))
    piezas.append(lb.esfera("Pulgar", 0.028, (-side * 0.044, 0.056, -0.405), m_piel, subdiv=1))

    obj_brazo = lb.unir(piezas, nombre)
    # Abrimos suavemente los brazos hacia fuera para librar la barriga grande al balancearse
    rot_mat = Euler((0.0, -side * math.radians(14), 0.0), "XYZ").to_matrix().to_4x4()
    bm_tmp = bmesh.new()
    bm_tmp.from_mesh(obj_brazo.data)
    bmesh.ops.transform(bm_tmp, matrix=rot_mat, verts=bm_tmp.verts)
    bm_tmp.normal_update()
    bm_tmp.to_mesh(obj_brazo.data)
    bm_tmp.free()
    obj_brazo.location = (x_pos, 0.0, 0.50)
    lb.suavizar_por_angulo(obj_brazo, 35.0)

    obj_linterna = None
    if side < 0.0:
        pz_lin = []
        pz_lin.append(lb.cilindro("Linterna_Mango", 0.036, 0.042, 0.22, (0.0, 0.03, 0.0), m_cuero, eje="Y", lados=12, bisel_tapa=0.008))
        pz_lin.append(lb.cilindro("Linterna_Cabezal", 0.045, 0.074, 0.10, (0.0, 0.16, 0.0), m_metal, eje="Y", lados=14, bisel_tapa=0.008))
        pz_lin.append(lb.toro("Linterna_Bisel", 0.072, 0.012, (0.0, 0.21, 0.0), m_cuero, eje="Y", segs_mayor=14, segs_menor=6))
        pz_lin.append(lb.esfera("Linterna_Foco", 0.058, (0.0, 0.21, 0.0), m_foco, escala=(1.0, 0.45, 1.0), subdiv=2))
        obj_linterna = lb.unir(pz_lin, "Linterna")
        obj_linterna.parent = obj_brazo
        obj_linterna.location = (side * math.sin(math.radians(14)) * 0.43, 0.04, -math.cos(math.radians(14)) * 0.43)
        lb.suavizar_por_angulo(obj_linterna, 35.0)

    return obj_brazo, obj_linterna


def _torso(m_oliva, m_oliva_osc, m_pant, m_cuero, m_blanco, m_metal):
    """Gran torso en forma de pera/barril con barriga baja prominente (+Y) y chaqueta de Inspector."""
    piezas = []

    # Pelvis marrón superior (baja un poco sobre caderas a z_world ~0.58 m)
    piezas.append(_malla_pera_asimetrica("Pelvis_Pant", [
        (0.0, 0.10, 0.10, -0.14),
        (0.24, 0.21, 0.15, -0.11),
        (0.29, 0.25, 0.18, -0.02),
        (0.0, 0.15, 0.15, 0.02),
    ], m_pant, lados=18))

    # Gran chaqueta oliva en forma de pera: máxima anchura y panza abajo (z=0.08..0.24), estrecha hacia hombros
    piezas.append(_malla_pera_asimetrica("Chaqueta_Pera", [
        (0.0, 0.12, 0.12, -0.05),
        (0.32, 0.30, 0.20, -0.01),
        (0.39, 0.39, 0.24, 0.11),   # Gran barriga baja icónica
        (0.38, 0.37, 0.23, 0.25),
        (0.34, 0.29, 0.20, 0.40),
        (0.28, 0.21, 0.16, 0.53),   # Hombros más recogidos
        (0.18, 0.15, 0.13, 0.62),
        (0.0, 0.10, 0.10, 0.64),
    ], m_oliva, lados=20))

    # Cinturón ajustado justo bajo la gran curva inferior del abrigo
    piezas.append(_malla_pera_asimetrica("Cinturon", [
        (0.0, 0.10, 0.10, -0.07),
        (0.305, 0.28, 0.195, -0.06),
        (0.312, 0.285, 0.198, -0.005),
        (0.0, 0.10, 0.10, 0.005),
    ], m_cuero, lados=18))
    piezas.append(lb.caja("Hebilla", (0.105, 0.04, 0.075), (0.0, 0.285, -0.032), m_metal, bisel=0.010, segs_bisel=1))

    # Solapas en V de la chaqueta + camisa blanca + corbata oscura en el pecho superior (+Y)
    piezas.append(lb.caja("Camisa_Cuello", (0.17, 0.12, 0.14), (0.0, 0.145, 0.57), m_blanco, bisel=0.015, segs_bisel=1, rot=(math.radians(-18), 0.0, 0.0)))
    piezas.append(lb.caja("Corbata", (0.06, 0.03, 0.16), (0.0, 0.215, 0.50), m_cuero, bisel=0.006, rot=(math.radians(-24), 0.0, 0.0)))
    for sx in (-1.0, 1.0):
        piezas.append(lb.caja("Solapa", (0.075, 0.04, 0.20), (sx * 0.08, 0.21, 0.52), m_oliva_osc, bisel=0.008, rot=(math.radians(-22), 0.0, sx * math.radians(18))))
        # Charreteras de uniforme en los hombros
        piezas.append(lb.caja("Charretera", (0.14, 0.075, 0.025), (sx * 0.21, 0.02, 0.59), m_oliva_osc, bisel=0.006, rot=(0.0, sx * math.radians(14), 0.0)))
        piezas.append(lb.cilindro("Boton_Charretera", 0.012, 0.012, 0.016, (sx * 0.16, 0.02, 0.608), m_metal, eje="Z", lados=8))
        # Bolsillos de pecho abultados en el frente de la barriga/pecho (zoom_guard.png)
        piezas.append(lb.caja("Bolsillo_Pecho", (0.13, 0.045, 0.12), (sx * 0.16, 0.295, 0.34), m_oliva_osc, bisel=0.012, segs_bisel=1, rot=(math.radians(-18), 0.0, 0.0)))
        piezas.append(lb.caja("Bolsillo_Solapa", (0.138, 0.052, 0.045), (sx * 0.16, 0.285, 0.39), m_oliva, bisel=0.008, segs_bisel=1, rot=(math.radians(-18), 0.0, 0.0)))
        piezas.append(lb.cilindro("Bolsillo_Boton", 0.012, 0.012, 0.02, (sx * 0.16, 0.312, 0.382), m_metal, eje="Y", lados=8))

    # Costura central sutil sin sobresalir del abrigo
    piezas.append(lb.caja("Abrigo_Tapeta", (0.028, 0.018, 0.20), (0.0, 0.340, 0.16), m_oliva_osc, bisel=0.005))

    obj = lb.unir(piezas, "Torso")
    obj.location = (0.0, 0.0, 0.68)
    lb.suavizar_por_angulo(obj, 35.0)
    return obj


def _cabeza(m_piel, m_oliva, m_oliva_osc, m_cuero, m_raya):
    """Cabeza sin cuello con gran mandíbula saliente, nariz gorda, enorme bigote y gorra inclinada."""
    piezas = []
    # Cráneo y gran mandíbula ancha adelantada (+Y)
    piezas.append(lb.esfera("Craneo", 0.175, (0.0, 0.01, 0.06), m_piel, escala=(1.04, 1.05, 1.10), subdiv=2))
    piezas.append(_malla_pera_asimetrica("Mandibula_Jowl", [
        (0.0, 0.05, 0.05, -0.10),
        (0.165, 0.22, 0.12, -0.05),
        (0.185, 0.24, 0.14, 0.02),
        (0.165, 0.18, 0.13, 0.09),
        (0.0, 0.10, 0.10, 0.12),
    ], m_piel, lados=16))
    for sx in (-1.0, 1.0):
        piezas.append(lb.esfera("Oreja", 0.044, (sx * 0.178, -0.01, 0.07), m_piel, escala=(0.55, 0.85, 1.15), subdiv=1))

    # Enorme nariz redonda + bigotazo negro en arco grueso (seña del Inspector)
    piezas.append(lb.esfera("Nariz", 0.052, (0.0, 0.245, 0.08), m_piel, escala=(0.95, 1.15, 0.90), subdiv=2))
    pts_big = [
        (-0.155, 0.185, 0.005),
        (-0.085, 0.240, 0.046),
        (0.0, 0.252, 0.056),
        (0.085, 0.240, 0.046),
        (0.155, 0.185, 0.005),
    ]
    piezas.append(lb.tubo_ruta("Bigote_Inspector", pts_big, [0.014, 0.036, 0.042, 0.036, 0.014], m_cuero, lados=8, catmull_subdiv=2))

    # Sombras oscuras de ceño bajo la visera inclinada + pelo corto detrás
    piezas.append(lb.esfera("Pelo_Nuca", 0.168, (0.0, -0.03, 0.11), m_cuero, escala=(1.02, 0.98, 0.66), subdiv=2))
    piezas.append(lb.caja("Ceno_Sombra", (0.24, 0.05, 0.036), (0.0, 0.185, 0.115), m_cuero, bisel=0.010))

    # Gorra plana de Inspector inclinada hacia adelante (+Y) echando sombra sobre los ojos
    piezas.append(lb.revolucion("Gorra_Copa", [
        (0.0, 0.115), (0.182, 0.120), (0.212, 0.180), (0.222, 0.215), (0.165, 0.230), (0.0, 0.232)
    ], (0.0, 0.01, 0.02), m_oliva, lados=18, rot=(math.radians(10), 0.0, 0.0)))
    piezas.append(lb.toro("Gorra_Cinta", 0.186, 0.016, (0.0, 0.02, 0.132), m_oliva_osc, eje="Z", segs_mayor=18, segs_menor=6, rot=(math.radians(10), 0.0, 0.0)))
    piezas.append(lb.toro("Gorra_CordonOro", 0.188, 0.010, (0.0, 0.02, 0.152), m_raya, eje="Z", segs_mayor=18, segs_menor=6, rot=(math.radians(10), 0.0, 0.0)))
    piezas.append(_visera_inspector_bm(m_cuero))

    obj = lb.unir(piezas, "Cabeza")
    obj.location = (0.0, 0.04, 0.66)
    lb.suavizar_por_angulo(obj, 35.0)
    return obj


def construir():
    m_oliva = lb.material("Guardia_Oliva", "#728733", rough=0.64, metal=0.04)
    m_oliva_osc = lb.material("Guardia_OlivaOsc", "#4e5e22", rough=0.68, metal=0.05)
    m_pant = lb.material("Guardia_Pantalon", "#874b2b", rough=0.72, metal=0.02)
    m_raya = lb.material("Guardia_RayaCaqui", "#d9a55b", rough=0.62, metal=0.05)
    m_piel = lb.material("Guardia_Piel", "#e4aa76", rough=0.68, metal=0.0)
    m_cuero = lb.material("Guardia_Cuero", "#1a191c", rough=0.45, metal=0.14)
    m_metal = lb.material("Guardia_Metal", "#cbd5e1", rough=0.25, metal=0.82)
    m_foco = lb.material("Guardia_Foco", "#fff6c2", rough=0.15, metal=0.0,
                         emision="#ffe082", emision_fuerza=4.0)

    raiz = bpy.data.objects.new("Guardia_Root", None)
    bpy.context.collection.objects.link(raiz)

    p_izq = _pierna("Pierna_Izq", -0.145, -1.0, m_pant, m_raya, m_cuero)
    p_der = _pierna("Pierna_Der", 0.145, 1.0, m_pant, m_raya, m_cuero)
    p_izq.parent = raiz
    p_der.parent = raiz

    torso = _torso(m_oliva, m_oliva_osc, m_pant, m_cuero, m_raya, m_metal)
    torso.parent = raiz

    cabeza = _cabeza(m_piel, m_oliva, m_oliva_osc, m_cuero, m_raya)
    cabeza.parent = torso

    b_izq, linterna = _brazo("Brazo_Izq", -0.265, -1.0, m_oliva, m_oliva_osc, m_piel, m_cuero, m_metal, m_foco)
    b_der, _ = _brazo("Brazo_Der", 0.265, 1.0, m_oliva, m_oliva_osc, m_piel, m_cuero, m_metal, m_foco)
    b_izq.parent = torso
    b_der.parent = torso

    bpy.context.view_layer.update()
    todos = [raiz, p_izq, p_der, torso, cabeza, b_izq, b_der, linterna]
    return [o for o in todos if o is not None]


def main():
    args = lb.parsear_args_modelo("Modelos/Minijuego_Correr/guardia.glb")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    objs = construir()
    lb.exportar_glb(objs, args.salida)
    if args.blend:
        lb.guardar_blend(args.blend)
    if args.render and not args.sin_render:
        lb.render_cuatro_vistas(objs, args.render, con_referencia=True)


if __name__ == "__main__":
    main()
