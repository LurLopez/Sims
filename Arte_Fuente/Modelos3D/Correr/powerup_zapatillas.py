"""
Power-up Súper Zapatillas con alas aerodinámicas esculpidas, suela con cámara
de aire neón, puntera y cordones cruzados (PARK RUSH 3D).
"""

import math
import os
import sys

import bpy

DIR_ACTUAL = os.path.dirname(os.path.abspath(__file__))
if DIR_ACTUAL not in sys.path:
    sys.path.insert(0, DIR_ACTUAL)

import lib_blender as lb


def _una_zapatilla(side: float, m_verde, m_blanco, m_osc, m_glow):
    piezas = []
    x_off = side * 0.27
    rz = -0.18 if side < 0 else 0.18
    cr, sr = math.cos(rz), math.sin(rz)

    def _p(lx, ly, lz):
        return (x_off + lx * cr - ly * sr, lx * sr + ly * cr, lz)

    # 1. Suela blanca gruesa + banda de rodadura inferior oscura + cámara de aire neón
    piezas.append(lb.caja("Suela_Base", (0.30, 0.62, 0.10), _p(0.0, 0.0, -0.14), m_blanco, bisel=0.035, segs_bisel=2, rot=(0.0, 0.0, rz)))
    piezas.append(lb.caja("Suela_Taco", (0.29, 0.60, 0.035), _p(0.0, 0.0, -0.20), m_osc, bisel=0.01, segs_bisel=1, rot=(0.0, 0.0, rz)))
    piezas.append(lb.caja("Suela_CamaraAire", (0.31, 0.16, 0.055), _p(0.0, 0.16, -0.14), m_glow, bisel=0.015, segs_bisel=1, rot=(0.0, 0.0, rz)))

    # 2. Empeine verde neón + caña alta acolchada + puntera blanca redondeada (frente = -Y)
    piezas.append(lb.caja("Empeine", (0.28, 0.46, 0.22), _p(0.0, 0.05, 0.01), m_verde, bisel=0.045, segs_bisel=2, rot=(0.0, 0.0, rz)))
    piezas.append(lb.esfera("Puntera", 0.155, _p(0.0, -0.18, -0.03), m_blanco, escala=(0.94, 1.05, 0.68), subdiv=2, rot=(0.0, 0.0, rz)))
    piezas.append(lb.caja("Cana_Alta", (0.27, 0.24, 0.20), _p(0.0, 0.15, 0.19), m_verde, bisel=0.04, segs_bisel=2, rot=(0.0, 0.0, rz)))
    piezas.append(lb.caja("Lengueta", (0.18, 0.08, 0.22), _p(0.0, 0.03, 0.22), m_blanco, bisel=0.02, segs_bisel=1, rot=(math.radians(20), 0.0, rz)))

    # 3. Cordones cruzados blancos en el empeine
    for ly, lz in ((-0.09, 0.12), (-0.02, 0.15), (0.04, 0.18)):
        piezas.append(lb.cilindro("Cordon", 0.014, 0.014, 0.18, _p(0.0, ly, lz), m_blanco, eje="X", lados=6, rot=(0.0, 0.0, rz)))

    # 4. Ala estilizada de 3 plumas esculpidas en el costado exterior
    for i_p, (pl_len, pz_off, ang_y) in enumerate(((0.38, 0.20, 0.35), (0.31, 0.10, 0.22), (0.24, 0.01, 0.08))):
        pts_pluma = [
            _p(side * 0.14, 0.12, pz_off),
            _p(side * 0.22, 0.12 + pl_len * 0.55, pz_off + 0.06 - i_p * 0.02),
            _p(side * 0.25, 0.12 + pl_len, pz_off + 0.12 - i_p * 0.03),
        ]
        piezas.append(lb.tubo_ruta(f"Ala_Pluma_{i_p}", pts_pluma, [0.035, 0.045, 0.014], m_blanco, lados=8, escala_ab=(0.55, 1.35)))

    return piezas


def construir():
    m_verde = lb.material("Zap_VerdeNeon", "#22ee74", rough=0.26, metal=0.15,
                          emision="#16a34a", emision_fuerza=0.65)
    m_blanco = lb.material("Zap_Blanco", "#f8fafc", rough=0.34, metal=0.05)
    m_osc = lb.material("Zap_SuelaOsc", "#1e293b", rough=0.58, metal=0.10)
    m_glow = lb.material("Zap_Glow", "#4ade80", rough=0.15, metal=0.0,
                         emision="#22c55e", emision_fuerza=2.0)

    piezas = []
    piezas.extend(_una_zapatilla(-1.0, m_verde, m_blanco, m_osc, m_glow))
    piezas.extend(_una_zapatilla(1.0, m_verde, m_blanco, m_osc, m_glow))

    obj = lb.unir(piezas, "PowerUp_Zapatillas")
    obj.location = (0.0, 0.0, 0.0)
    lb.suavizar_por_angulo(obj, 35.0)
    return obj


def main():
    args = lb.parsear_args_modelo("Modelos/Minijuego_Correr/powerup_zapatillas.glb")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    obj = construir()
    lb.exportar_glb(obj, args.salida)
    if args.blend:
        lb.guardar_blend(args.blend)
    if args.render and not args.sin_render:
        lb.render_cuatro_vistas(obj, args.render, con_referencia=False)


if __name__ == "__main__":
    main()
