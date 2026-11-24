class_name Runner_Mallas_3D
extends RefCounted

# ============================================================================
# GENERADOR DE MALLAS 3D ESCULPIDAS (ESTILO SUBWAY SURFERS)
#
# Construye ArrayMesh limpios con biseles, normales precisas, UVs calibrados
# y subdivisión en Z para que cada tren, rampa, moneda, imán y estrella se
# curve suavemente con el horizonte sin ángulos rígidos.
# ============================================================================


static func _add_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		uva: Vector2, uvb: Vector2, uvc: Vector2, uvd: Vector2, n: Vector3) -> void:
	# En Godot 4 las caras frontales tienen devanado horario (CW) vistas desde +normal.
	# Para (a=izq-abajo, b=der-abajo, c=der-arriba, d=izq-arriba): (a, d, c) y (a, c, b) son CW!
	st.set_normal(n)
	st.set_uv(uva)
	st.add_vertex(a)
	st.set_normal(n)
	st.set_uv(uvd)
	st.add_vertex(d)
	st.set_normal(n)
	st.set_uv(uvc)
	st.add_vertex(c)

	st.set_normal(n)
	st.set_uv(uva)
	st.add_vertex(a)
	st.set_normal(n)
	st.set_uv(uvc)
	st.add_vertex(c)
	st.set_normal(n)
	st.set_uv(uvb)
	st.add_vertex(b)


## Vagón de metro biselado (3 superficies: 0=Laterales, 1=Techo, 2=Frente/Trasera).
## Perfil redondeado estilo Subway Surfers (faldón inferior + costados + bisel + techo).
## Subdividido en Z (segs_z) para curvarse como seda sobre el horizonte.
static func crear_malla_vagon(ancho: float, alto: float, largo: float, y_base: float = 0.42, segs_z: int = 8) -> ArrayMesh:
	var hw: float = ancho * 0.5
	var hw_skirt: float = hw * 0.90
	var hw_roof: float = hw * 0.84
	var y_skirt: float = y_base + 0.26
	var y_eave: float = alto - 0.24
	var hl: float = largo * 0.5

	var mesh := ArrayMesh.new()

	# --- Superficie 0: Costados izquierdo y derecho ---
	var st_side := SurfaceTool.new()
	st_side.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Perfil derecho de abajo a arriba: (x, y, v_uv)
	var prof: Array[Vector3] = [
		Vector3(hw_skirt, y_base, 1.0),
		Vector3(hw, y_skirt, 0.88),
		Vector3(hw, y_eave, 0.08),
		Vector3(hw_roof, alto, 0.0),
	]

	for iz in range(segs_z):
		var t0: float = float(iz) / float(segs_z)
		var t1: float = float(iz + 1) / float(segs_z)
		var z0: float = lerpf(-hl, hl, t0)
		var z1: float = lerpf(-hl, hl, t1)

		for ip in range(prof.size() - 1):
			var p0: Vector3 = prof[ip]
			var p1: Vector3 = prof[ip + 1]
			var tang_r := Vector2(p1.x - p0.x, p1.y - p0.y).normalized()
			var n_r := Vector3(tang_r.y, -tang_r.x, 0.0).normalized()

			# Costado derecho (+X)
			var a := Vector3(p0.x, p0.y, z1)
			var b := Vector3(p0.x, p0.y, z0)
			var c := Vector3(p1.x, p1.y, z0)
			var d := Vector3(p1.x, p1.y, z1)
			_add_quad(st_side, a, b, c, d,
				Vector2(t1, p0.z), Vector2(t0, p0.z), Vector2(t0, p1.z), Vector2(t1, p1.z), n_r)

			# Costado izquierdo (-X)
			var n_l := Vector3(-n_r.x, n_r.y, 0.0).normalized()
			var la := Vector3(-p0.x, p0.y, z0)
			var lb := Vector3(-p0.x, p0.y, z1)
			var lc := Vector3(-p1.x, p1.y, z1)
			var ld := Vector3(-p1.x, p1.y, z0)
			_add_quad(st_side, la, lb, lc, ld,
				Vector2(t0, p0.z), Vector2(t1, p0.z), Vector2(t1, p1.z), Vector2(t0, p1.z), n_l)

	st_side.generate_tangents()
	st_side.commit(mesh)

	# --- Superficie 1: Techo plano transitable (y = alto) + fondo inferior ---
	var st_roof := SurfaceTool.new()
	st_roof.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in range(segs_z):
		var t0: float = float(iz) / float(segs_z)
		var t1: float = float(iz + 1) / float(segs_z)
		var z0: float = lerpf(-hl, hl, t0)
		var z1: float = lerpf(-hl, hl, t1)
		var v0: float = t0 * 3.0
		var v1: float = t1 * 3.0
		_add_quad(st_roof,
			Vector3(-hw_roof, alto, z1),
			Vector3(hw_roof, alto, z1),
			Vector3(hw_roof, alto, z0),
			Vector3(-hw_roof, alto, z0),
			Vector2(0.0, v1), Vector2(1.0, v1), Vector2(1.0, v0), Vector2(0.0, v0),
			Vector3.UP)
		# Base inferior cerrada
		_add_quad(st_roof,
			Vector3(-hw_skirt, y_base, z0),
			Vector3(hw_skirt, y_base, z0),
			Vector3(hw_skirt, y_base, z1),
			Vector3(-hw_skirt, y_base, z1),
			Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(1.0, 1.0), Vector2(0.0, 1.0),
			Vector3.DOWN)
	st_roof.generate_tangents()
	st_roof.commit(mesh)

	# --- Superficie 2: Cabina frontal (+Z) y trasera (-Z) ---
	var st_cap := SurfaceTool.new()
	st_cap.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Construimos la tapa frontal en 3 bandas horizontales siguiendo el perfil biselado
	var bandas: Array[Array] = [
		[hw_skirt, y_base, 1.0, hw, y_skirt, 0.88],
		[hw, y_skirt, 0.88, hw, y_eave, 0.08],
		[hw, y_eave, 0.08, hw_roof, alto, 0.0],
	]
	for band in bandas:
		var x_b: float = band[0]
		var y_b: float = band[1]
		var v_b: float = band[2]
		var x_t: float = band[3]
		var y_t: float = band[4]
		var v_t: float = band[5]
		var ub_l: float = 0.5 - (x_b / (hw * 2.0))
		var ub_r: float = 0.5 + (x_b / (hw * 2.0))
		var ut_l: float = 0.5 - (x_t / (hw * 2.0))
		var ut_r: float = 0.5 + (x_t / (hw * 2.0))
		# Frente (+Z mirando al corredor)
		_add_quad(st_cap,
			Vector3(-x_b, y_b, hl), Vector3(x_b, y_b, hl),
			Vector3(x_t, y_t, hl), Vector3(-x_t, y_t, hl),
			Vector2(ub_l, v_b), Vector2(ub_r, v_b), Vector2(ut_r, v_t), Vector2(ut_l, v_t),
			Vector3(0.0, 0.0, 1.0))
		# Trasera (-Z)
		_add_quad(st_cap,
			Vector3(x_b, y_b, -hl), Vector3(-x_b, y_b, -hl),
			Vector3(-x_t, y_t, -hl), Vector3(x_t, y_t, -hl),
			Vector2(ub_l, v_b), Vector2(ub_r, v_b), Vector2(ut_r, v_t), Vector2(ut_l, v_t),
			Vector3(0.0, 0.0, -1.0))
	st_cap.generate_tangents()
	st_cap.commit(mesh)

	return mesh


## Rampa en cuña sólida (2 superficies: 0=Superficie inclinada con flechas, 1=Laterales de acero).
## Empieza en z = +largo_rampa (y = 0.04) y sube hasta z = 0 (y = alto).
static func crear_malla_rampa_cuna(ancho: float, alto: float, largo_rampa: float, segs_z: int = 6) -> ArrayMesh:
	var hw: float = ancho * 0.5
	var mesh := ArrayMesh.new()
	var n_slope := Vector3(0.0, largo_rampa, alto).normalized()

	# Superficie 0: Cara inclinada superior
	var st_top := SurfaceTool.new()
	st_top.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in range(segs_z):
		var t0: float = float(iz) / float(segs_z)
		var t1: float = float(iz + 1) / float(segs_z)
		var z0: float = lerpf(0.0, largo_rampa, t0)
		var z1: float = lerpf(0.0, largo_rampa, t1)
		var y0: float = lerpf(alto, 0.04, t0)
		var y1: float = lerpf(alto, 0.04, t1)
		_add_quad(st_top,
			Vector3(-hw, y1, z1), Vector3(hw, y1, z1),
			Vector3(hw, y0, z0), Vector3(-hw, y0, z0),
			Vector2(0.0, t1), Vector2(1.0, t1), Vector2(1.0, t0), Vector2(0.0, t0),
			n_slope)
	st_top.generate_tangents()
	st_top.commit(mesh)

	# Superficie 1: Caras laterales sólidas de la cuña
	var st_side := SurfaceTool.new()
	st_side.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in range(segs_z):
		var t0: float = float(iz) / float(segs_z)
		var t1: float = float(iz + 1) / float(segs_z)
		var z0: float = lerpf(0.0, largo_rampa, t0)
		var z1: float = lerpf(0.0, largo_rampa, t1)
		var y0: float = lerpf(alto, 0.04, t0)
		var y1: float = lerpf(alto, 0.04, t1)
		# Derecha (+X)
		_add_quad(st_side,
			Vector3(hw, 0.0, z1), Vector3(hw, 0.0, z0),
			Vector3(hw, y0, z0), Vector3(hw, y1, z1),
			Vector2(t1, 1.0), Vector2(t0, 1.0), Vector2(t0, 1.0 - y0 / alto), Vector2(t1, 1.0 - y1 / alto),
			Vector3.RIGHT)
		# Izquierda (-X)
		_add_quad(st_side,
			Vector3(-hw, 0.0, z0), Vector3(-hw, 0.0, z1),
			Vector3(-hw, y1, z1), Vector3(-hw, y0, z0),
			Vector2(t0, 1.0), Vector2(t1, 1.0), Vector2(t1, 1.0 - y1 / alto), Vector2(t0, 1.0 - y0 / alto),
			Vector3.LEFT)
	st_side.commit(mesh)
	return mesh


## Caja subdividida a lo largo de Z (clave para raíles, andenes y muros curvos sin quiebres!).
static func crear_caja_subdividida_z(tam: Vector3, segs_z: int = 16) -> ArrayMesh:
	var bm := BoxMesh.new()
	bm.size = tam
	bm.subdivide_depth = segs_z
	var arr := ArrayMesh.new()
	arr.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, bm.get_mesh_arrays())
	return arr


## Estrella 3D facetada de 5 puntas (para el multiplicador 2x y emblema de moneda).
static func crear_estrella_3d(radio_ext: float, radio_int: float, grosor: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: Array[Vector2] = []
	for i in range(10):
		var ang: float = PI * 0.5 + float(i) * (TAU / 10.0)
		var r: float = radio_ext if i % 2 == 0 else radio_int
		pts.append(Vector2(cos(ang) * r, sin(ang) * r))

	var hz: float = grosor * 0.5
	var c_front := Vector3(0.0, 0.0, hz * 1.45)
	var c_back := Vector3(0.0, 0.0, -hz * 1.45)

	for i in range(10):
		var p0: Vector2 = pts[i]
		var p1: Vector2 = pts[(i + 1) % 10]
		var vf0 := Vector3(p0.x, p0.y, hz * 0.45)
		var vf1 := Vector3(p1.x, p1.y, hz * 0.45)
		var vb0 := Vector3(p0.x, p0.y, -hz * 0.45)
		var vb1 := Vector3(p1.x, p1.y, -hz * 0.45)

		# Cara frontal facetada (+Z, CW)
		var nf := (vf0 - c_front).cross(vf1 - c_front).normalized()
		if nf.z < 0.0:
			nf = -nf
		st.set_normal(nf); st.set_uv(Vector2(0.5, 0.5)); st.add_vertex(c_front)
		st.set_normal(nf); st.set_uv(Vector2(1.0, 0.5)); st.add_vertex(vf1)
		st.set_normal(nf); st.set_uv(Vector2(0.5, 1.0)); st.add_vertex(vf0)

		# Cara trasera facetada (-Z, CW vista desde -Z)
		var nb := (vb1 - c_back).cross(vb0 - c_back).normalized()
		if nb.z > 0.0:
			nb = -nb
		st.set_normal(nb); st.set_uv(Vector2(0.5, 0.5)); st.add_vertex(c_back)
		st.set_normal(nb); st.set_uv(Vector2(0.5, 1.0)); st.add_vertex(vb0)
		st.set_normal(nb); st.set_uv(Vector2(1.0, 0.5)); st.add_vertex(vb1)

		# Borde lateral
		var ns := Vector3((p0.x + p1.x) * 0.5, (p0.y + p1.y) * 0.5, 0.0).normalized()
		_add_quad(st, vb0, vf0, vf1, vb1, Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, Vector2.DOWN, ns)

	return st.commit()


## Imán en herradura (verdadera forma de U abierta estilo Subway Surfers).
## 2 superficies: 0=Arco rojo esmaltado, 1=Puntas plateadas magnéticas.
static func crear_iman_herradura(radio: float = 0.34, tubo_r: float = 0.115, largo_pata: float = 0.24) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var segs_u: int = 16
	var segs_r: int = 10

	# Construir puntos de la columna vertebral en forma de U invertida (arco arriba, patas abajo)
	var spine: Array[Vector3] = []
	var tangs: Array[Vector3] = []
	var is_tip: Array[bool] = []

	# Pata izquierda (de abajo hacia el arco)
	spine.append(Vector3(-radio, -largo_pata, 0.0)); tangs.append(Vector3.UP); is_tip.append(true)
	spine.append(Vector3(-radio, -largo_pata * 0.25, 0.0)); tangs.append(Vector3.UP); is_tip.append(true)
	spine.append(Vector3(-radio, 0.0, 0.0)); tangs.append(Vector3.UP); is_tip.append(false)

	# Semicírculo superior
	for i in range(1, segs_u):
		var ang: float = PI - float(i) * (PI / float(segs_u))
		spine.append(Vector3(cos(ang) * radio, sin(ang) * radio, 0.0))
		tangs.append(Vector3(sin(ang), -cos(ang), 0.0).normalized())
		is_tip.append(false)

	# Pata derecha (del arco hacia abajo)
	spine.append(Vector3(radio, 0.0, 0.0)); tangs.append(Vector3.DOWN); is_tip.append(false)
	spine.append(Vector3(radio, -largo_pata * 0.25, 0.0)); tangs.append(Vector3.DOWN); is_tip.append(true)
	spine.append(Vector3(radio, -largo_pata, 0.0)); tangs.append(Vector3.DOWN); is_tip.append(true)

	var st_red := SurfaceTool.new()
	st_red.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st_tip := SurfaceTool.new()
	st_tip.begin(Mesh.PRIMITIVE_TRIANGLES)

	for s in range(spine.size() - 1):
		var p0: Vector3 = spine[s]
		var p1: Vector3 = spine[s + 1]
		var t0: Vector3 = tangs[s]
		var t1: Vector3 = tangs[s + 1]
		var side0: Vector3 = t0.cross(Vector3.BACK).normalized()
		var side1: Vector3 = t1.cross(Vector3.BACK).normalized()
		var use_tip: bool = is_tip[s] and is_tip[s + 1]
		var st: SurfaceTool = st_tip if use_tip else st_red

		for r in range(segs_r):
			var a0: float = float(r) * TAU / float(segs_r)
			var a1: float = float(r + 1) * TAU / float(segs_r)
			var n00: Vector3 = (side0 * cos(a0) + Vector3.BACK * sin(a0)).normalized()
			var n01: Vector3 = (side0 * cos(a1) + Vector3.BACK * sin(a1)).normalized()
			var n10: Vector3 = (side1 * cos(a0) + Vector3.BACK * sin(a0)).normalized()
			var n11: Vector3 = (side1 * cos(a1) + Vector3.BACK * sin(a1)).normalized()

			var v00: Vector3 = p0 + n00 * tubo_r
			var v01: Vector3 = p0 + n01 * tubo_r
			var v10: Vector3 = p1 + n10 * tubo_r
			var v11: Vector3 = p1 + n11 * tubo_r

			st.set_normal(n00); st.add_vertex(v00)
			st.set_normal(n11); st.add_vertex(v11)
			st.set_normal(n10); st.add_vertex(v10)

			st.set_normal(n00); st.add_vertex(v00)
			st.set_normal(n01); st.add_vertex(v01)
			st.set_normal(n11); st.add_vertex(v11)

	# Tapas planas en los extremos de las patas
	for idx_end in [0, spine.size() - 1]:
		var pe: Vector3 = spine[idx_end]
		var n_end := Vector3.DOWN
		for r in range(segs_r):
			var a0: float = float(r) * TAU / float(segs_r)
			var a1: float = float(r + 1) * TAU / float(segs_r)
			var u0 := pe + Vector3(cos(a0) * tubo_r, 0.0, sin(a0) * tubo_r)
			var u1 := pe + Vector3(cos(a1) * tubo_r, 0.0, sin(a1) * tubo_r)
			st_tip.set_normal(n_end); st_tip.add_vertex(pe)
			st_tip.set_normal(n_end); st_tip.add_vertex(u0)
			st_tip.set_normal(n_end); st_tip.add_vertex(u1)

	st_red.commit(mesh)
	st_tip.commit(mesh)
	return mesh


## Tabla hoverboard esculpida con proa/popa redondeada (estilo Subway Surfers).
static func crear_hoverboard_malla(ancho: float = 0.56, largo: float = 1.42, grosor: float = 0.085) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var perfil: Array[Vector2] = [
		Vector2(0.0, -0.50),
		Vector2(0.32, -0.44),
		Vector2(0.49, -0.26),
		Vector2(0.50, 0.0),
		Vector2(0.47, 0.28),
		Vector2(0.30, 0.45),
		Vector2(0.0, 0.50),
		Vector2(-0.30, 0.45),
		Vector2(-0.47, 0.28),
		Vector2(-0.50, 0.0),
		Vector2(-0.49, -0.26),
		Vector2(-0.32, -0.44),
	]
	var hy: float = grosor * 0.5
	var n_pts: int = perfil.size()
	for i in range(n_pts):
		var p0: Vector2 = perfil[i]
		var p1: Vector2 = perfil[(i + 1) % n_pts]
		var x0: float = p0.x * ancho
		var z0: float = p0.y * largo
		var x1: float = p1.x * ancho
		var z1: float = p1.y * largo
		# Cara superior (+Y, CW vista desde arriba)
		st.set_normal(Vector3.UP); st.set_uv(Vector2(0.5, 0.5)); st.add_vertex(Vector3(0.0, hy, 0.0))
		st.set_normal(Vector3.UP); st.set_uv(p0 + Vector2(0.5, 0.5)); st.add_vertex(Vector3(x0, hy, z0))
		st.set_normal(Vector3.UP); st.set_uv(p1 + Vector2(0.5, 0.5)); st.add_vertex(Vector3(x1, hy, z1))
		# Cara inferior (-Y, CW vista desde abajo)
		st.set_normal(Vector3.DOWN); st.set_uv(Vector2(0.5, 0.5)); st.add_vertex(Vector3(0.0, -hy, 0.0))
		st.set_normal(Vector3.DOWN); st.set_uv(p1 + Vector2(0.5, 0.5)); st.add_vertex(Vector3(x1, -hy, z1))
		st.set_normal(Vector3.DOWN); st.set_uv(p0 + Vector2(0.5, 0.5)); st.add_vertex(Vector3(x0, -hy, z0))
		# Canto lateral
		var ns := Vector3((x0 + x1) * 0.5, 0.0, (z0 + z1) * 0.5).normalized()
		_add_quad(st,
			Vector3(x1, -hy, z1), Vector3(x0, -hy, z0),
			Vector3(x0, hy, z0), Vector3(x1, hy, z1),
			Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, Vector2.DOWN, ns)
	return st.commit()
