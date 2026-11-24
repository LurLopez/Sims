"""
Librería compartida de modelado 3D paramétrico en Blender (4.2+ / bpy)
para el minijuego «Salir a correr / PARK RUSH 3D».

Sigue estrictamente las reglas de la skill `blender-modelado-3d`:
  · Geometría pura por `bmesh` y `from_pydata` (sin `bpy.ops` para mallas).
  · Bisel acotado al 40 % del lado menor (`clamp_overlap=True`).
  · Cuerpo rehundido y apliques creciendo hacia fuera en capas distintas.
  · Subdivisión suficiente en el eje de curvatura del shader (+Y en Blender -> -Z en Godot).
  · Sombreado suave por ángulo de 35° y transformadas aplicadas.
  · UVs completas y materiales Principled BSDF compatibles con glTF / GL Compatibility.
  · Render automático de 4 vistas (costado, frontal, superior y 3/4 con escala 1,80 m).
"""

import argparse
import math
import os
import random
import sys
import tempfile

import bmesh
import bpy
import numpy as np
from mathutils import Euler, Matrix, Vector


# ---------------------------------------------------------------------------
# Colores y materiales
# ---------------------------------------------------------------------------

def hex_rgba(h: str, a: float = 1.0):
    """Convierte hex sRGB '#RRGGBB' a RGBA lineal para Principled BSDF."""
    h = h.lstrip("#")
    srgb = [int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)]
    lin = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in srgb]
    return (lin[0], lin[1], lin[2], a)


def cargar_imagen(ruta: str, colorspace: str = "sRGB"):
    """Carga y empaqueta una imagen PNG/JPG dentro del blend/glb."""
    ruta_abs = os.path.abspath(ruta)
    for img in bpy.data.images:
        if os.path.abspath(bpy.path.abspath(img.filepath)) == ruta_abs:
            return img
    img = bpy.data.images.load(ruta_abs)
    img.colorspace_settings.name = colorspace
    try:
        img.pack()
    except Exception:
        pass
    return img


def material(
    nombre: str,
    color: str = "#ffffff",
    rough: float = 0.55,
    metal: float = 0.0,
    emision: str = None,
    emision_fuerza: float = 0.0,
    tex_albedo: str = None,
    tex_normal: str = None,
    tex_emission: str = None,
    normal_fuerza: float = 1.0,
):
    """Crea o reutiliza un material Principled BSDF limpio exportable a glTF."""
    mat = bpy.data.materials.get(nombre)
    if mat:
        return mat
    mat = bpy.data.materials.new(nombre)
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = hex_rgba(color)
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = metal
    mat.diffuse_color = hex_rgba(color)

    if tex_albedo:
        img = cargar_imagen(tex_albedo, "sRGB")
        tex_n = nt.nodes.new("ShaderNodeTexImage")
        tex_n.image = img
        tex_n.location = (-360, 280)
        nt.links.new(tex_n.outputs["Color"], bsdf.inputs["Base Color"])

    if tex_normal:
        img_n = cargar_imagen(tex_normal, "Non-Color")
        tex_nn = nt.nodes.new("ShaderNodeTexImage")
        tex_nn.image = img_n
        tex_nn.location = (-580, -140)
        nmap = nt.nodes.new("ShaderNodeNormalMap")
        nmap.inputs["Strength"].default_value = normal_fuerza
        nmap.location = (-260, -140)
        nt.links.new(tex_nn.outputs["Color"], nmap.inputs["Color"])
        nt.links.new(nmap.outputs["Normal"], bsdf.inputs["Normal"])

    if emision or tex_emission:
        if emision:
            bsdf.inputs["Emission Color"].default_value = hex_rgba(emision)
        if tex_emission:
            img_e = cargar_imagen(tex_emission, "sRGB")
            tex_en = nt.nodes.new("ShaderNodeTexImage")
            tex_en.image = img_e
            tex_en.location = (-360, 20)
            nt.links.new(tex_en.outputs["Color"], bsdf.inputs["Emission Color"])
        bsdf.inputs["Emission Strength"].default_value = max(emision_fuerza, 1.0)

    return mat


# ---------------------------------------------------------------------------
# Utilidades bmesh y creación de objetos
# ---------------------------------------------------------------------------

def nuevo_objeto(nombre: str, mesh):
    obj = bpy.data.objects.new(nombre, mesh)
    bpy.context.collection.objects.link(obj)
    return obj


def _asignar_uvs_caja_bm(bm, escala_uv: float = 0.5):
    """Asigna UVs por proyección cúbica limpia directamente en bmesh."""
    uv_layer = bm.loops.layers.uv.verify()
    for face in bm.faces:
        n = face.normal
        ax, ay, az = abs(n.x), abs(n.y), abs(n.z)
        for loop in face.loops:
            co = loop.vert.co
            if az >= ax and az >= ay:
                u, v = co.x, co.y
            elif ax >= ay and ax >= az:
                u, v = co.y, co.z
            else:
                u, v = co.x, co.z
            loop[uv_layer].uv = (u * escala_uv + 0.5, v * escala_uv + 0.5)


def aplicar_bisel_bm(bm, bisel: float, min_lado: float, segs: int = 2, angulo_deg: float = 30.0):
    """Bisel acotado al 40 % del lado menor solo sobre aristas vivas (> angulo_deg)."""
    if bisel <= 0.0 or min_lado <= 0.0:
        return
    ancho = min(bisel, min_lado * 0.40)
    if ancho <= 1e-5:
        return
    ang_rad = math.radians(angulo_deg)
    bm.normal_update()
    aristas = []
    for e in bm.edges:
        if len(e.link_faces) == 2:
            if e.calc_face_angle(0.0) > ang_rad:
                aristas.append(e)
        elif len(e.link_faces) == 1:
            aristas.append(e)
    if aristas:
        bmesh.ops.bevel(
            bm,
            geom=aristas,
            offset=ancho,
            offset_type="OFFSET",
            segments=segs,
            profile=0.5,
            affect="EDGES",
            clamp_overlap=True,
        )


def finalizar_bmesh(
    nombre: str,
    bm,
    mat=None,
    centro=(0.0, 0.0, 0.0),
    rot=(0.0, 0.0, 0.0),
    escala_uv: float = 0.5,
):
    """Transforma vértices de bmesh a centro/rotación, genera UVs base y crea objeto."""
    if any(abs(r) > 1e-6 for r in rot):
        m_rot = Euler(rot, "XYZ").to_matrix().to_4x4()
        bmesh.ops.transform(bm, matrix=m_rot, verts=bm.verts)
    if any(abs(c) > 1e-6 for c in centro):
        m_tra = Matrix.Translation(Vector(centro))
        bmesh.ops.transform(bm, matrix=m_tra, verts=bm.verts)

    if not bm.loops.layers.uv:
        _asignar_uvs_caja_bm(bm, escala_uv)

    bm.normal_update()
    ngons = [f for f in bm.faces if len(f.verts) > 4]
    if ngons:
        bmesh.ops.triangulate(bm, faces=ngons)
    mesh = bpy.data.meshes.new(nombre)
    bm.to_mesh(mesh)
    bm.free()
    mesh.validate()
    if mat is not None:
        mesh.materials.append(mat)
    return nuevo_objeto(nombre, mesh)


# ---------------------------------------------------------------------------
# Primitivas paramétricas en puro bmesh
# ---------------------------------------------------------------------------

def caja(
    nombre: str,
    tam,
    centro=(0.0, 0.0, 0.0),
    mat=None,
    bisel: float = 0.0,
    segs_bisel: int = 2,
    subdiv_x: int = 1,
    subdiv_y: int = 1,
    subdiv_z: int = 1,
    rot=(0.0, 0.0, 0.0),
    escala_uv: float = 0.5,
):
    """Caja subdividida en X/Y/Z con bisel acotado, sin usar bpy.ops."""
    sx, sy, sz = float(tam[0]), float(tam[1]), float(tam[2])
    nx = max(1, int(subdiv_x))
    ny = max(1, int(subdiv_y))
    nz = max(1, int(subdiv_z))

    bm = bmesh.new()
    if nx == 1 and ny == 1 and nz == 1:
        bmesh.ops.create_cube(bm, size=1.0)
        bmesh.ops.scale(bm, vec=(sx, sy, sz), verts=bm.verts)
    else:
        hx, hy, hz = sx * 0.5, sy * 0.5, sz * 0.5
        xs = [-hx + sx * i / nx for i in range(nx + 1)]
        ys = [-hy + sy * j / ny for j in range(ny + 1)]
        zs = [-hz + sz * k / nz for k in range(nz + 1)]

        # Rejilla exterior de vértices (sin caras internas)
        grid = {}
        for ix in range(nx + 1):
            for iy in range(ny + 1):
                for iz in range(nz + 1):
                    if ix in (0, nx) or iy in (0, ny) or iz in (0, nz):
                        grid[(ix, iy, iz)] = bm.verts.new((xs[ix], ys[iy], zs[iz]))

        # Caras -Z y +Z
        for ix in range(nx):
            for iy in range(ny):
                bm.faces.new((
                    grid[(ix, iy, 0)], grid[(ix, iy + 1, 0)],
                    grid[(ix + 1, iy + 1, 0)], grid[(ix + 1, iy, 0)],
                ))
                bm.faces.new((
                    grid[(ix, iy, nz)], grid[(ix + 1, iy, nz)],
                    grid[(ix + 1, iy + 1, nz)], grid[(ix, iy + 1, nz)],
                ))
        # Caras -X y +X
        for iy in range(ny):
            for iz in range(nz):
                bm.faces.new((
                    grid[(0, iy, iz)], grid[(0, iy, iz + 1)],
                    grid[(0, iy + 1, iz + 1)], grid[(0, iy + 1, iz)],
                ))
                bm.faces.new((
                    grid[(nx, iy, iz)], grid[(nx, iy + 1, iz)],
                    grid[(nx, iy + 1, iz + 1)], grid[(nx, iy, iz + 1)],
                ))
        # Caras -Y y +Y
        for ix in range(nx):
            for iz in range(nz):
                bm.faces.new((
                    grid[(ix, 0, iz)], grid[(ix + 1, 0, iz)],
                    grid[(ix + 1, 0, iz + 1)], grid[(ix, 0, iz + 1)],
                ))
                bm.faces.new((
                    grid[(ix, ny, iz)], grid[(ix, ny, iz + 1)],
                    grid[(ix + 1, ny, iz + 1)], grid[(ix + 1, ny, iz)],
                ))

    aplicar_bisel_bm(bm, bisel, min(sx, sy, sz), segs_bisel, 30.0)
    _asignar_uvs_caja_bm(bm, escala_uv)
    return finalizar_bmesh(nombre, bm, mat, centro, rot, escala_uv)


def panel_uv(
    nombre: str,
    tam,
    centro=(0.0, 0.0, 0.0),
    mat=None,
    cara_uv: str = "-Y",
    subdiv_u: int = 1,
    subdiv_v: int = 1,
    rot=(0.0, 0.0, 0.0),
    u_rango=(0.0, 1.0),
    v_rango=(0.0, 1.0),
    espejo_u: bool = False,
):
    """Caja fina/panel con UV exacto [u0..u1, v0..v1] sobre la cara indicada."""
    sx, sy, sz = float(tam[0]), float(tam[1]), float(tam[2])
    nx = subdiv_u if cara_uv in ("-Y", "+Y", "-Z", "+Z") else 1
    ny = subdiv_u if cara_uv in ("-X", "+X") else (subdiv_v if cara_uv in ("-Z", "+Z") else 1)
    nz = subdiv_v if cara_uv in ("-X", "+X", "-Y", "+Y") else 1

    obj = caja(nombre, (sx, sy, sz), (0, 0, 0), mat, bisel=0.0,
               subdiv_x=nx, subdiv_y=ny, subdiv_z=nz, rot=(0, 0, 0))
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    uv_layer = bm.loops.layers.uv.verify()

    hx, hy, hz = sx * 0.5, sy * 0.5, sz * 0.5
    u0, u1 = u_rango
    v0, v1 = v_rango

    for face in bm.faces:
        for loop in face.loops:
            co = loop.vert.co
            if cara_uv in ("-Y", "+Y"):
                fu = (co.x + hx) / max(sx, 1e-6)
                if cara_uv == "+Y":
                    fu = 1.0 - fu
                fv = (co.z + hz) / max(sz, 1e-6)
            elif cara_uv in ("-X", "+X"):
                fu = (co.y + hy) / max(sy, 1e-6)
                if cara_uv == "-X":
                    fu = 1.0 - fu
                fv = (co.z + hz) / max(sz, 1e-6)
            else:  # +Z / -Z
                fu = (co.x + hx) / max(sx, 1e-6)
                fv = (co.y + hy) / max(sy, 1e-6)
            if espejo_u:
                fu = 1.0 - fu
            loop[uv_layer].uv = (u0 + fu * (u1 - u0), v0 + fv * (v1 - v0))

    if any(abs(r) > 1e-6 for r in rot):
        bmesh.ops.transform(bm, matrix=Euler(rot, "XYZ").to_matrix().to_4x4(), verts=bm.verts)
    if any(abs(c) > 1e-6 for c in centro):
        bmesh.ops.transform(bm, matrix=Matrix.Translation(Vector(centro)), verts=bm.verts)
    bm.normal_update()
    bm.to_mesh(obj.data)
    bm.free()
    obj.data.validate()
    return obj


def extruir_perfil(
    nombre: str,
    perfil_xz,
    largo_y: float,
    mat=None,
    segs_y: int = 8,
    centro_y: float = 0.0,
    escala_fn=None,
    bisel: float = 0.0,
    segs_bisel: int = 2,
    rot=(0.0, 0.0, 0.0),
    centro=(0.0, 0.0, 0.0),
):
    """Extruye un perfil cerrado (x, z) a lo largo de Y con N cortes para curvatura."""
    bm = bmesh.new()
    hl = largo_y * 0.5
    n = len(perfil_xz)
    capas = []
    for i in range(segs_y + 1):
        t = i / segs_y
        y = centro_y - hl + largo_y * t
        if escala_fn is not None:
            res = escala_fn(t)
            if isinstance(res, tuple):
                sx, sz = res[0], res[1]
                dz = res[2] if len(res) > 2 else 0.0
            else:
                sx, sz, dz = res, 1.0, 0.0
        else:
            sx, sz, dz = 1.0, 1.0, 0.0
        capas.append([bm.verts.new((x * sx, y, z * sz + dz)) for (x, z) in perfil_xz])

    bm.verts.ensure_lookup_table()
    for i in range(segs_y):
        a, b = capas[i], capas[i + 1]
        for j in range(n):
            k = (j + 1) % n
            bm.faces.new((a[j], a[k], b[k], b[j]))

    # Tapas con orientación consistente
    bm.faces.new(tuple(reversed(capas[0])))
    bm.faces.new(tuple(capas[-1]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)

    xs = [p[0] for p in perfil_xz]
    zs = [p[1] for p in perfil_xz]
    min_dim = min(max(xs) - min(xs), max(zs) - min(zs), largo_y)
    aplicar_bisel_bm(bm, bisel, min_dim, segs_bisel, 32.0)
    _asignar_uvs_caja_bm(bm, 0.5)
    return finalizar_bmesh(nombre, bm, mat, centro, rot)


def cilindro(
    nombre: str,
    r_bot: float,
    r_top: float,
    largo: float,
    centro=(0.0, 0.0, 0.0),
    mat=None,
    eje: str = "Z",
    lados: int = 20,
    bisel_tapa: float = 0.0,
    segs_bisel: int = 2,
    segs_largo: int = 1,
    rot=(0.0, 0.0, 0.0),
):
    """Cilindro o cono truncado en bmesh con chaflán opcional en las tapas."""
    bm = bmesh.new()
    nz = max(1, int(segs_largo))
    hz = largo * 0.5

    if bisel_tapa > 0.0:
        b = min(bisel_tapa, min(r_bot, r_top, largo * 0.45) * 0.40)
    else:
        b = 0.0

    anillos = []
    if b > 1e-5:
        zs_r = [(-hz, max(0.001, r_bot - b))]
        zs_r.append((-hz + b, r_bot))
        for k in range(1, nz):
            t = k / nz
            zs_r.append(((-hz + b) + (largo - 2 * b) * t, r_bot + (r_top - r_bot) * t))
        zs_r.append((hz - b, r_top))
        zs_r.append((hz, max(0.001, r_top - b)))
    else:
        zs_r = []
        for k in range(nz + 1):
            t = k / nz
            zs_r.append((-hz + largo * t, r_bot + (r_top - r_bot) * t))

    for z_val, rad in zs_r:
        if rad <= 1e-5:
            anillos.append([bm.verts.new((0.0, 0.0, z_val))])
        else:
            fila = []
            for s in range(lados):
                ang = math.tau * s / lados
                fila.append(bm.verts.new((math.cos(ang) * rad, math.sin(ang) * rad, z_val)))
            anillos.append(fila)

    for i in range(len(anillos) - 1):
        a, b_ring = anillos[i], anillos[i + 1]
        if len(a) == 1:
            v0 = a[0]
            for s in range(lados):
                bm.faces.new((v0, b_ring[s], b_ring[(s + 1) % lados]))
        elif len(b_ring) == 1:
            v1 = b_ring[0]
            for s in range(lados):
                bm.faces.new((a[s], v1, a[(s + 1) % lados]))
        else:
            for s in range(lados):
                sn = (s + 1) % lados
                bm.faces.new((a[s], a[sn], b_ring[sn], b_ring[s]))

    if len(anillos[0]) > 2:
        bm.faces.new(tuple(reversed(anillos[0])))
    if len(anillos[-1]) > 2:
        bm.faces.new(tuple(anillos[-1]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)

    if eje == "X":
        bmesh.ops.transform(bm, matrix=Euler((0.0, math.radians(90), 0.0), "XYZ").to_matrix().to_4x4(), verts=bm.verts)
    elif eje == "Y":
        bmesh.ops.transform(bm, matrix=Euler((math.radians(90), 0.0, 0.0), "XYZ").to_matrix().to_4x4(), verts=bm.verts)

    _asignar_uvs_caja_bm(bm, 0.6)
    return finalizar_bmesh(nombre, bm, mat, centro, rot)


def revolucion(
    nombre: str,
    perfil_rz,
    centro=(0.0, 0.0, 0.0),
    mat=None,
    lados: int = 20,
    escala_xy=(1.0, 1.0),
    rot=(0.0, 0.0, 0.0),
):
    """Torno/revolución de una lista de puntos (radio, z) alrededor del eje Z."""
    bm = bmesh.new()
    anillos = []
    for r, z in perfil_rz:
        if r <= 1e-5:
            anillos.append([bm.verts.new((0.0, 0.0, z))])
        else:
            fila = []
            for s in range(lados):
                ang = math.tau * s / lados
                fila.append(bm.verts.new((
                    math.cos(ang) * r * escala_xy[0],
                    math.sin(ang) * r * escala_xy[1],
                    z,
                )))
            anillos.append(fila)

    for i in range(len(anillos) - 1):
        a, b_ring = anillos[i], anillos[i + 1]
        if len(a) == 1 and len(b_ring) == 1:
            continue
        elif len(a) == 1:
            v0 = a[0]
            for s in range(lados):
                bm.faces.new((v0, b_ring[s], b_ring[(s + 1) % lados]))
        elif len(b_ring) == 1:
            v1 = b_ring[0]
            for s in range(lados):
                bm.faces.new((a[s], v1, a[(s + 1) % lados]))
        else:
            for s in range(lados):
                sn = (s + 1) % lados
                bm.faces.new((a[s], a[sn], b_ring[sn], b_ring[s]))

    if len(anillos[0]) > 2:
        bm.faces.new(tuple(reversed(anillos[0])))
    if len(anillos[-1]) > 2:
        bm.faces.new(tuple(anillos[-1]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    _asignar_uvs_caja_bm(bm, 0.7)
    return finalizar_bmesh(nombre, bm, mat, centro, rot)


def esfera(
    nombre: str,
    radio: float,
    centro=(0.0, 0.0, 0.0),
    mat=None,
    escala=(1.0, 1.0, 1.0),
    subdiv: int = 2,
    ruido: float = 0.0,
    semilla: int = 0,
    rot=(0.0, 0.0, 0.0),
):
    """Icosfera subdividida (topología uniforme) con desplazamiento orgánico opcional."""
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=radio)
    if ruido > 0.0:
        for v in bm.verts:
            d = v.co.normalized()
            n1 = math.sin(d.x * 4.3 + semilla * 1.7) * math.cos(d.y * 3.9 + semilla * 0.9)
            n2 = math.sin(d.z * 5.1 - semilla * 2.3)
            factor = 1.0 + ruido * (0.65 * n1 + 0.35 * n2)
            v.co *= factor
    bmesh.ops.scale(bm, vec=escala, verts=bm.verts)
    _asignar_uvs_caja_bm(bm, 0.5)
    return finalizar_bmesh(nombre, bm, mat, centro, rot)


def toro(
    nombre: str,
    r_mayor: float,
    r_menor: float,
    centro=(0.0, 0.0, 0.0),
    mat=None,
    eje: str = "Z",
    segs_mayor: int = 24,
    segs_menor: int = 10,
    arco: float = math.tau,
    rot=(0, 0, 0),
):
    """Toro o arco toroidal cerrado en bmesh."""
    cerrado = abs(arco - math.tau) < 1e-4
    bm = bmesh.new()
    anillos = []
    pasos = segs_mayor if cerrado else segs_mayor + 1
    for i in range(pasos):
        theta = arco * (i / segs_mayor)
        ct, st = math.cos(theta), math.sin(theta)
        cx, cy = ct * r_mayor, st * r_mayor
        fila = []
        for j in range(segs_menor):
            phi = math.tau * j / segs_menor
            cp, sp = math.cos(phi), math.sin(phi)
            px = (r_mayor + r_menor * cp) * ct
            py = (r_mayor + r_menor * cp) * st
            pz = r_menor * sp
            fila.append(bm.verts.new((px, py, pz)))
        anillos.append(fila)

    n_an = len(anillos)
    limite = n_an if cerrado else n_an - 1
    for i in range(limite):
        a = anillos[i]
        b = anillos[(i + 1) % n_an]
        for j in range(segs_menor):
            jn = (j + 1) % segs_menor
            bm.faces.new((a[j], b[j], b[jn], a[jn]))

    if not cerrado:
        bm.faces.new(tuple(reversed(anillos[0])))
        bm.faces.new(tuple(anillos[-1]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)

    if eje == "X":
        bmesh.ops.transform(bm, matrix=Euler((0.0, math.radians(90), 0.0), "XYZ").to_matrix().to_4x4(), verts=bm.verts)
    elif eje == "Y":
        bmesh.ops.transform(bm, matrix=Euler((math.radians(90), 0.0, 0.0), "XYZ").to_matrix().to_4x4(), verts=bm.verts)

    _asignar_uvs_caja_bm(bm, 0.7)
    return finalizar_bmesh(nombre, bm, mat, centro, rot)


def _catmull_rom_3d(pts, subdiv: int):
    if len(pts) < 2 or subdiv <= 1:
        return [Vector(p) for p in pts]
    vpts = [Vector(p) for p in pts]
    ext = [vpts[0]] + vpts + [vpts[-1]]
    out = []
    for i in range(1, len(ext) - 2):
        p0, p1, p2, p3 = ext[i - 1], ext[i], ext[i + 1], ext[i + 2]
        for s in range(subdiv):
            t = s / subdiv
            t2, t3 = t * t, t * t * t
            out.append(0.5 * (
                (2.0 * p1)
                + (-p0 + p2) * t
                + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
                + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
            ))
    out.append(vpts[-1])
    return out


def tubo_ruta(
    nombre: str,
    puntos,
    radios,
    mat=None,
    lados: int = 12,
    cerrado: bool = False,
    tapar: bool = True,
    escala_ab=(1.0, 1.0),
    catmull_subdiv: int = 0,
    centro=(0.0, 0.0, 0.0),
    rot=(0.0, 0.0, 0.0),
):
    """Barre una sección elíptica con transporte paralelo (sin giros bruscos) sobre una ruta 3D."""
    pts = _catmull_rom_3d(puntos, catmull_subdiv) if catmull_subdiv > 1 else [Vector(p) for p in puntos]
    n = len(pts)
    if isinstance(radios, (int, float)):
        rads = [float(radios)] * n
    else:
        r_orig = list(radios)
        rads = [
            r_orig[0] + (r_orig[-1] - r_orig[0]) * (i / max(1, n - 1))
            if len(r_orig) != n else float(r_orig[i])
            for i in range(n)
        ]

    # Tangentes y marco inicial ortogonal
    tangs = []
    for i in range(n):
        if cerrado:
            t = (pts[(i + 1) % n] - pts[(i - 1) % n]).normalized()
        elif i == 0:
            t = (pts[1] - pts[0]).normalized()
        elif i == n - 1:
            t = (pts[-1] - pts[-2]).normalized()
        else:
            t = (pts[i + 1] - pts[i - 1]).normalized()
        if t.length_squared < 1e-8:
            t = Vector((0, 0, 1))
        tangs.append(t)

    up_ref = Vector((0, 0, 1)) if abs(tangs[0].z) < 0.92 else Vector((1, 0, 0))
    ej_x = tangs[0].cross(up_ref).normalized()
    ej_y = tangs[0].cross(ej_x).normalized()

    bm = bmesh.new()
    anillos = []
    for i in range(n):
        if i > 0:
            q = tangs[i - 1].rotation_difference(tangs[i])
            ej_x = (q @ ej_x).normalized()
            ej_y = tangs[i].cross(ej_x).normalized()
        r = max(1e-5, rads[i])
        fila = []
        for s in range(lados):
            ang = math.tau * s / lados
            off = ej_x * (math.cos(ang) * r * escala_ab[0]) + ej_y * (math.sin(ang) * r * escala_ab[1])
            fila.append(bm.verts.new(pts[i] + off))
        anillos.append(fila)

    limite = n if cerrado else n - 1
    for i in range(limite):
        a = anillos[i]
        b = anillos[(i + 1) % n]
        for s in range(lados):
            sn = (s + 1) % lados
            bm.faces.new((a[s], b[s], b[sn], a[sn]))

    if not cerrado and tapar:
        bm.faces.new(tuple(reversed(anillos[0])))
        bm.faces.new(tuple(anillos[-1]))

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    _asignar_uvs_caja_bm(bm, 0.8)
    return finalizar_bmesh(nombre, bm, mat, centro, rot)


def muelle_helicoidal(
    nombre: str,
    r_helice: float,
    r_alambre: float,
    altura: float,
    vueltas: float,
    centro=(0.0, 0.0, 0.0),
    mat=None,
    segs_por_vuelta: int = 16,
    segs_alambre: int = 8,
    rot=(0.0, 0.0, 0.0),
):
    """Muelle helicoidal 3D real para bogies ferroviarios y pogo cohete."""
    pasos = max(8, int(round(vueltas * segs_por_vuelta)))
    pts = []
    hz = altura * 0.5
    for i in range(pasos + 1):
        t = i / pasos
        ang = t * vueltas * math.tau
        z = -hz + altura * t
        pts.append((math.cos(ang) * r_helice, math.sin(ang) * r_helice, z))
    return tubo_ruta(nombre, pts, r_alambre, mat, lados=segs_alambre,
                     cerrado=False, tapar=True, centro=centro, rot=rot)


def estrella_3d(
    nombre: str,
    r_ext: float,
    r_int: float,
    grosor: float,
    centro=(0.0, 0.0, 0.0),
    mat=None,
    puntas: int = 5,
    bisel_cara: float = 0.45,
    rot=(0.0, 0.0, 0.0),
):
    """Estrella 3D facetada y biselada en el eje Y (cara frontal mirando -Y/+Y)."""
    bm = bmesh.new()
    hy = grosor * 0.5
    hy_borde = hy * (1.0 - bisel_cara)
    c_f = bm.verts.new((0.0, -hy, 0.0))
    c_b = bm.verts.new((0.0, hy, 0.0))

    n_pts = puntas * 2
    vf = []
    vb = []
    for i in range(n_pts):
        ang = math.pi * 0.5 + i * (math.tau / n_pts)
        r = r_ext if i % 2 == 0 else r_int
        px, pz = math.cos(ang) * r, math.sin(ang) * r
        vf.append(bm.verts.new((px, -hy_borde, pz)))
        vb.append(bm.verts.new((px, hy_borde, pz)))

    for i in range(n_pts):
        inext = (i + 1) % n_pts
        bm.faces.new((c_f, vf[i], vf[inext]))
        bm.faces.new((c_b, vb[inext], vb[i]))
        bm.faces.new((vf[i], vb[i], vb[inext], vf[inext]))

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    _asignar_uvs_caja_bm(bm, 1.0)
    return finalizar_bmesh(nombre, bm, mat, centro, rot)


# ---------------------------------------------------------------------------
# Unión, sombreado, UVs, exportación y render de 4 vistas
# ---------------------------------------------------------------------------

def unir(objetos, nombre: str):
    """Une una lista de objetos de malla en un único objeto limpio."""
    objetos = [o for o in objetos if o is not None]
    for o in bpy.context.selected_objects:
        o.select_set(False)
    for o in objetos:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objetos[0]
    bpy.ops.object.join()
    obj = bpy.context.object
    obj.name = nombre
    return obj


def suavizar_por_angulo(obj, grados: float = 35.0):
    """Aplica sombreado suave solo en ángulos menores a `grados`."""
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.shade_smooth_by_angle(angle=math.radians(grados))
    obj.select_set(False)


def proyectar_uv_smart(obj, angulo_deg: float = 66.0, margen: float = 0.02):
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(angulo_deg), island_margin=margen)
    bpy.ops.object.mode_set(mode="OBJECT")
    obj.select_set(False)


def asegurar_uv(obj, escala_uv: float = 0.5):
    """Garantiza que todas las caras tengan capa UV válida sin sobrescribir UVs ya trazadas."""
    if not obj.data.uv_layers:
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        _asignar_uvs_caja_bm(bm, escala_uv)
        bm.to_mesh(obj.data)
        bm.free()


def bbox_objetos(objetos):
    """Calcula (min_vec, max_vec) global en coordenadas de mundo de uno o varios objetos."""
    mn = Vector((float("inf"), float("inf"), float("inf")))
    mx = Vector((float("-inf"), float("-inf"), float("-inf")))
    for obj in objetos:
        if obj.type != "MESH":
            continue
        for c in obj.bound_box:
            w = obj.matrix_world @ Vector(c)
            for k in range(3):
                mn[k] = min(mn[k], w[k])
                mx[k] = max(mx[k], w[k])
    return mn, mx


def exportar_glb(raiz_o_objetos, ruta_glb: str):
    """Exporta un objeto único o una jerarquía articulada a GLB limpio."""
    salida = os.path.abspath(ruta_glb)
    os.makedirs(os.path.dirname(salida), exist_ok=True)

    objs = raiz_o_objetos if isinstance(raiz_o_objetos, (list, tuple)) else [raiz_o_objetos]
    for o in bpy.context.scene.objects:
        o.select_set(o in objs)
    bpy.context.view_layer.objects.active = objs[0]

    bpy.ops.export_scene.gltf(
        filepath=salida,
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_yup=True,
        export_normals=True,
        export_tangents=True,
        export_texcoords=True,
        export_materials="EXPORT",
        export_cameras=False,
        export_lights=False,
    )
    tris = sum(
        sum(max(0, len(p.vertices) - 2) for p in o.data.polygons)
        for o in objs if o.type == "MESH"
    )
    print(f"GLB: {salida} ({os.path.getsize(salida)} bytes, {tris} tris)")
    return salida


def montar_entorno_render(tam_escena: float = 40.0):
    """Configura iluminación solar + relleno + mundo neutro para renders de comprobación."""
    bpy.ops.object.light_add(type="SUN", location=(8, -10, 14))
    sol = bpy.context.object
    sol.name = "_Render_Sol"
    sol.data.energy = 3.2
    sol.data.angle = math.radians(10)
    sol.rotation_euler = (math.radians(48), math.radians(8), math.radians(32))

    bpy.ops.object.light_add(type="AREA", location=(-10, -8, 6))
    relleno = bpy.context.object
    relleno.name = "_Render_Relleno"
    relleno.data.energy = 900.0
    relleno.data.size = 10.0
    relleno.rotation_euler = (math.radians(65), 0.0, math.radians(-52))

    mundo = bpy.data.worlds.new("_Render_Mundo")
    mundo.use_nodes = True
    mundo.node_tree.nodes["Background"].inputs[0].default_value = hex_rgba("#d8e6f3")
    mundo.node_tree.nodes["Background"].inputs[1].default_value = 0.85
    bpy.context.scene.world = mundo
    return [sol, relleno]


def render_cuatro_vistas(
    objetos,
    ruta_png: str,
    con_referencia: bool = True,
    tam_panel=(560, 420),
    muestras: int = 20,
):
    """Genera hoja 2x2 de verificación: Costado (ortho), Frente (ortho), Superior (ortho) y 3/4 (persp)."""
    objs = objetos if isinstance(objetos, (list, tuple)) else [objetos]
    mn, mx = bbox_objetos(objs)
    centro = (mn + mx) * 0.5
    dims = mx - mn
    max_dim = max(dims.x, dims.y, dims.z, 0.5)

    temporales = montar_entorno_render(max_dim * 4.0)

    # Suelo sutil en mn.z - 0.005 para sombras de contacto
    suelo = caja(
        "_Render_Suelo",
        (max(12.0, max_dim * 3.0), max(12.0, max_dim * 3.0), 0.02),
        (centro.x, centro.y, mn.z - 0.012),
        material("_Mat_Render_Suelo", "#b8c4d0", rough=0.88),
    )
    temporales.append(suelo)

    # Figura humana de referencia de 1,80 m al costado (solo en la vista 3/4)
    ref = None
    if con_referencia and max_dim >= 0.9:
        ref = caja(
            "_Render_Ref180",
            (0.42, 0.26, 1.80),
            (mx.x + max(0.7, dims.x * 0.35), centro.y, mn.z + 0.90),
            material("_Mat_Render_Ref", "#64748b", rough=0.85),
            bisel=0.04,
        )
        temporales.append(ref)

    bpy.ops.object.camera_add()
    cam = bpy.context.object
    cam.name = "_Render_Cam"
    temporales.append(cam)
    escena = bpy.context.scene
    escena.camera = cam
    escena.render.engine = "CYCLES"
    escena.cycles.device = "CPU"
    escena.cycles.samples = muestras
    escena.cycles.use_denoising = True
    escena.render.resolution_x = tam_panel[0]
    escena.render.resolution_y = tam_panel[1]
    escena.render.image_settings.file_format = "PNG"

    dist = max_dim * 2.2 + 2.5
    aspect = tam_panel[0] / tam_panel[1]

    def _fit_ortho(w_span, h_span):
        return max(w_span, h_span * aspect) * 1.18

    vistas = [
        # (nombre, ortho, ortho_scale, loc, mostrar_ref)
        ("side", True, _fit_ortho(dims.y, dims.z), Vector((centro.x + dist, centro.y, centro.z)), False),
        ("front", True, _fit_ortho(dims.x, dims.z), Vector((centro.x, centro.y - dist, centro.z)), False),
        ("top", True, _fit_ortho(dims.x, dims.y), Vector((centro.x, centro.y, centro.z + dist)), False),
        ("p34", False, 50.0, Vector((centro.x + max_dim * 1.15 + 1.1, centro.y - max_dim * 1.35 - 1.2, centro.z + max_dim * 0.58 + 0.7)), True),
    ]

    paneles = []
    tmpdir = tempfile.mkdtemp(prefix="vistas_")
    try:
        for v_nom, es_ortho, scale_o, loc, show_ref in vistas:
            if ref is not None:
                ref.hide_render = not show_ref
            # Ocultar suelo en vista superior/frontal si estorba poco, mantener en 3/4 y side
            suelo.hide_render = (v_nom == "top")
            cam.location = loc
            cam.rotation_euler = (centro - cam.location).to_track_quat("-Z", "Y").to_euler()
            if es_ortho:
                cam.data.type = "ORTHO"
                cam.data.ortho_scale = scale_o
            else:
                cam.data.type = "PERSP"
                cam.data.lens = 50.0
            cam.data.clip_start = 0.05
            cam.data.clip_end = max(300.0, dist * 4.0)

            ruta_tmp = os.path.join(tmpdir, f"{v_nom}.png")
            escena.render.filepath = ruta_tmp
            bpy.ops.render.render(write_still=True)

            img = bpy.data.images.load(ruta_tmp)
            arr = np.array(img.pixels[:], dtype=np.float32).reshape((tam_panel[1], tam_panel[0], 4))
            # Blender almacena de abajo arriba
            arr = np.flipud(arr)
            paneles.append(arr)
            bpy.data.images.remove(img)

        # Componer cuadrícula 2x2 con separador fino oscuro
        w, h = tam_panel
        grid = np.zeros((h * 2, w * 2, 4), dtype=np.float32)
        grid[0:h, 0:w] = paneles[0]
        grid[0:h, w:2 * w] = paneles[1]
        grid[h:2 * h, 0:w] = paneles[2]
        grid[h:2 * h, w:2 * w] = paneles[3]
        grid[h - 1:h + 1, :, :3] = 0.15
        grid[:, w - 1:w + 1, :3] = 0.15

        ruta_abs = os.path.abspath(ruta_png)
        os.makedirs(os.path.dirname(ruta_abs), exist_ok=True)
        out_img = bpy.data.images.new("_Out_4Vistas", width=w * 2, height=h * 2, alpha=True)
        out_img.pixels[:] = np.flipud(grid).ravel().tolist()
        out_img.filepath_raw = ruta_abs
        out_img.file_format = "PNG"
        out_img.save()
        bpy.data.images.remove(out_img)
        print("Render 4 vistas:", ruta_abs)
    finally:
        for t in temporales:
            if t and t.name in bpy.data.objects:
                bpy.data.objects.remove(t, do_unlink=True)
        for f in os.listdir(tmpdir):
            os.remove(os.path.join(tmpdir, f))
        os.rmdir(tmpdir)


def parsear_args_modelo(salida_default: str):
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--salida", default=salida_default)
    ap.add_argument("--blend", default="")
    ap.add_argument("--render", default="")
    ap.add_argument("--sin-render", action="store_true")
    return ap.parse_args(argv)


def guardar_blend(ruta_blend: str):
    if not ruta_blend:
        return
    ruta_abs = os.path.abspath(ruta_blend)
    os.makedirs(os.path.dirname(ruta_abs), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=ruta_abs)
    print("BLEND:", ruta_abs)
