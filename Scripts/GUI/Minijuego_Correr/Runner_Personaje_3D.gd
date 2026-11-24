class_name Runner_Personaje_3D
extends Node3D

# ============================================================================
# PERSONAJE 3D ARTICULADO DEL SIM (BASADO 1:1 EN PERSONAJE_VISUAL 2D)
#
# Modelo 3D orgánico, articulado y reutilizable para "Salir a correr" y
# cualquier escena o minijuego 3D futuro del proyecto.
#
# - Mallas 3D esculpidas por revolución/lofting (ArrayMesh con normales suaves,
#   sin cajas rígidas tipo Roblox) y contorno de tinta cómic (#111827) idéntico
#   al renderizador 2D.
# - Texturas vectoriales 2D->3D de alta resolución generadas en tiempo real por
#   Texturas_Personaje_3D con las mismas curvas Catmull-Rom de Personaje_Visual:
#   5 formas de cara, 4 formas de ojos, 10 colores de ojos, pestañas/delineado,
#   5 estilos de cejas, 5 formas de nariz (2D + relieve 3D), 4 formas de boca,
#   6 colores de labios, rubor, pecas, lunar, 6 estilos de vello facial,
#   marcas progresivas de envejecimiento (Envejecimiento_Personaje), 16 peinados
#   esculpidos en 3D, 4 sombreros + gorro de chef/fiesta, 5 tipos de gafas,
#   3 tipos de pendientes, 4 complexiones, 6 prendas superiores, 5 inferiores,
#   3 calzados y los 19 estilos de vestuario (frente y espalda).
# - Esqueleto completo con articulaciones reales de hombro, codo, muñeca,
#   cadera, rodilla y tobillo, más física secundaria de pelo (_hair_sway).
# ============================================================================

const Tex3D := preload("res://Scripts/GUI/Personaje/Texturas_Personaje_3D.gd")
const ESC := 0.0074 # 1 unidad de Personaje_Visual 2D = 0.0074 m en 3D (~1.90 m altura total)
const TINTA := Color("#111827")

var apariencia_actual: Dictionary = {}
var edad_actual: int = Envejecimiento_Personaje.EDAD_MIN
var expresion_actual: String = "feliz"
var pose_general: String = "idle"

var _shadow_disc: MeshInstance3D
var _body_pivot: Node3D
var _torso: Node3D
var _head_group: Node3D
var _head_mesh_inst: MeshInstance3D
var _hair_sway: Node3D

# Brazos articulados (Hombro -> Codo -> Mano)
var _left_arm: Node3D
var _left_forearm: Node3D
var _right_arm: Node3D
var _right_forearm: Node3D

# Piernas articuladas (Cadera -> Rodilla -> Tobillo/Calzado)
var _left_leg: Node3D
var _left_shin: Node3D
var _left_foot: Node3D
var _right_leg: Node3D
var _right_shin: Node3D
var _right_foot: Node3D

var _hoverboard: Node3D
var _jetpack: Node3D
var _jetpack_llamas: Array[Node3D] = []
var _pogo: Node3D
var _sneaker_glow_l: MeshInstance3D
var _sneaker_glow_r: MeshInstance3D
var _magnet_aura: Node3D

var _mat_sombra: StandardMaterial3D
var _mat_rostro: StandardMaterial3D
var _tex_rostro_normal: ImageTexture
var _tex_rostro_parpadeo: ImageTexture
var _tex_rostro_esfuerzo: ImageTexture
var _tex_rostro_choque: ImageTexture
var _estado_rostro_activo: String = "normal"

var _tiempo_general: float = 0.0
var _rot_y_suave: float = 0.0
var _rot_y_inicializado: bool = false


func _init(tex_sombra: Texture2D = null) -> void:
	name = "Runner_Personaje_3D"
	_mat_sombra = StandardMaterial3D.new()
	_mat_sombra.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_sombra.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_sombra.no_depth_test = false
	_mat_sombra.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	_mat_sombra.albedo_color = Color(1, 1, 1, 0.85)
	if tex_sombra != null:
		_mat_sombra.albedo_texture = tex_sombra
	else:
		_mat_sombra.albedo_color = Color(0.05, 0.08, 0.14, 0.45)

	aplicar_apariencia(Apariencia_Personaje.por_defecto(), Envejecimiento_Personaje.EDAD_MIN)


# ----------------------------------------------------------------------------
# Materiales Cómic / Cel-Shaded con contorno de tinta (#111827)
# ----------------------------------------------------------------------------

static func _crear_pass_contorno(grosor_m: float = 0.010, col_tinta: Color = TINTA) -> StandardMaterial3D:
	var outline := StandardMaterial3D.new()
	outline.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	outline.cull_mode = BaseMaterial3D.CULL_FRONT
	outline.albedo_color = col_tinta
	outline.grow = true
	outline.grow_amount = grosor_m
	return outline


static func _mat(col: Color, roughness: float = 0.88, metallic: float = 0.0,
		emission: Color = Color(0, 0, 0), emission_energy: float = 0.0,
		con_contorno: bool = true, grosor_contorno: float = 0.0095) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = roughness
	m.metallic = metallic
	m.metallic_specular = 0.08
	if emission_energy > 0.0:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = emission_energy
	if con_contorno and grosor_contorno > 0.0:
		m.next_pass = _crear_pass_contorno(grosor_contorno)
	return m


static func _mat_textura(tex: Texture2D, roughness: float = 0.90, con_contorno: bool = true, grosor_contorno: float = 0.010) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color.WHITE
	m.albedo_texture = tex
	m.roughness = roughness
	m.metallic = 0.0
	m.metallic_specular = 0.06
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if con_contorno and grosor_contorno > 0.0:
		m.next_pass = _crear_pass_contorno(grosor_contorno)
	return m


static func _inst_malla(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3 = Vector3.ZERO,
		rot: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE, cast_shadow: bool = true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	mi.scale = scl
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


static func _box(parent: Node3D, sz: Vector3, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO, cast_shadow: bool = true) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = sz
	return _inst_malla(parent, mesh, mat, pos, rot, Vector3.ONE, cast_shadow)


static func _sphere(parent: Node3D, radius: float, pos: Vector3, mat: Material, scl: Vector3 = Vector3.ONE, cast_shadow: bool = true, segs: int = 18, rings: int = 12) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = segs
	mesh.rings = rings
	return _inst_malla(parent, mesh, mat, pos, Vector3.ZERO, scl, cast_shadow)


static func _cyl(parent: Node3D, top_r: float, bot_r: float, h: float, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO, segs: int = 16, cast_shadow: bool = true) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_r
	mesh.bottom_radius = bot_r
	mesh.height = h
	mesh.radial_segments = segs
	return _inst_malla(parent, mesh, mat, pos, rot, Vector3.ONE, cast_shadow)


# ----------------------------------------------------------------------------
# Constructores de mallas 3D orgánicas (ArrayMesh con normales suaves)
# ----------------------------------------------------------------------------

## Evalúa el semiancho exacto rx(y_2d) de la silueta facial 2D de Personaje_Visual.
static func _contorno_rostro_2d(es_mujer: bool, forma: String, jaw_w: float) -> PackedVector2Array:
	var pts: PackedVector2Array
	match forma:
		"cuadrada":
			pts = PackedVector2Array([
				Vector2(0.0, -37.0), Vector2(19.5, -33.0), Vector2(28.5, -17.0),
				Vector2(29.0, 3.0), Vector2(25.8, 22.0), Vector2(15.5, 32.0),
				Vector2(0.0, 34.8), Vector2(-15.5, 32.0), Vector2(-25.8, 22.0),
				Vector2(-29.0, 3.0), Vector2(-28.5, -17.0), Vector2(-19.5, -33.0),
			])
		"redonda":
			pts = PackedVector2Array([
				Vector2(0.0, -36.5), Vector2(20.5, -32.0), Vector2(29.5, -15.0),
				Vector2(30.5, 4.0), Vector2(26.5, 20.5), Vector2(14.5, 30.8),
				Vector2(0.0, 33.8), Vector2(-14.5, 30.8), Vector2(-26.5, 20.5),
				Vector2(-30.5, 4.0), Vector2(-29.5, -15.0), Vector2(-20.5, -32.0),
			])
		"alargada":
			pts = PackedVector2Array([
				Vector2(0.0, -38.5), Vector2(18.5, -34.5), Vector2(26.8, -17.0),
				Vector2(27.0, 4.0), Vector2(22.5, 22.5), Vector2(11.8, 34.0),
				Vector2(0.0, 37.5), Vector2(-11.8, 34.0), Vector2(-22.5, 22.5),
				Vector2(-27.0, 4.0), Vector2(-26.8, -17.0), Vector2(-18.5, -34.5),
			])
		"corazon":
			pts = PackedVector2Array([
				Vector2(0.0, -37.0), Vector2(20.0, -32.5), Vector2(29.5, -15.5),
				Vector2(29.2, 2.0), Vector2(22.0, 18.5), Vector2(10.5, 30.5),
				Vector2(0.0, 34.5), Vector2(-10.5, 30.5), Vector2(-22.0, 18.5),
				Vector2(-29.2, 2.0), Vector2(-29.5, -15.5), Vector2(-20.0, -32.5),
			])
		_:
			var jx := 23.2 if es_mujer else 25.0
			var cx := 11.8 if es_mujer else 13.8
			pts = PackedVector2Array([
				Vector2(0.0, -37.2), Vector2(19.5, -33.2), Vector2(28.5, -16.5),
				Vector2(28.8, 2.5), Vector2(jx, 20.0), Vector2(cx, 31.8),
				Vector2(0.0, 35.2), Vector2(-cx, 31.8), Vector2(-jx, 20.0),
				Vector2(-28.8, 2.5), Vector2(-28.5, -16.5), Vector2(-19.5, -33.2),
			])
	var out := PackedVector2Array()
	for p in pts:
		out.append(Vector2(p.x * jaw_w, p.y))
	return Tex3D.suavizar_cerrado(out, 5)


static func _evaluar_semiancho_poligono(poly_suave: PackedVector2Array, y_2d: float) -> float:
	var mejor_x: float = 0.0
	var n: int = poly_suave.size()
	for i in range(n):
		var a: Vector2 = poly_suave[i]
		var b: Vector2 = poly_suave[(i + 1) % n]
		if a.x < -0.5 and b.x < -0.5:
			continue
		if (a.y <= y_2d and b.y >= y_2d) or (b.y <= y_2d and a.y >= y_2d):
			var dy: float = b.y - a.y
			var x: float = a.x if absf(dy) < 0.001 else lerpf(a.x, b.x, clampf((y_2d - a.y) / dy, 0.0, 1.0))
			if x > mejor_x:
				mejor_x = x
	return maxf(0.4, mejor_x)


## Crea la malla 3D esculpida de la cabeza con la forma exacta del rostro 2D
## y mapeo UV planar frontal (1:1 con Personaje_Visual) sin deformación.
static func _crear_malla_cabeza(es_mujer: bool, forma_cara: String, jaw_w: float) -> ArrayMesh:
	var contorno := _contorno_rostro_2d(es_mujer, forma_cara, jaw_w)
	var y_top: float = contorno[0].y
	var y_bot: float = contorno[0].y
	for p in contorno:
		if p.y < y_top:
			y_top = p.y
		if p.y > y_bot:
			y_bot = p.y

	var rings: int = 24
	var half_segs: int = 16 # 16 segmentos frontales + 16 traseros = 32 alrededor
	var pos_grid: Array = []
	var y2d_rings := PackedFloat32Array()

	for r in range(rings + 1):
		var v_t: float = float(r) / float(rings)
		var k: float = 0.5 * (1.0 - cos(v_t * PI))
		var y_2d: float = lerpf(y_top, y_bot, k)
		y2d_rings.append(y_2d)
		var rx_2d: float = 0.0
		if r > 0 and r < rings:
			rx_2d = _evaluar_semiancho_poligono(contorno, y_2d)

		var rz_front_2d: float = rx_2d * 0.84
		var rz_back_2d: float = rx_2d * (0.85 if y_2d < 10.0 else 0.76)
		var y_3d: float = -y_2d * ESC

		var ring_pts: Array[Vector3] = []
		var total_segs: int = half_segs * 2
		for s in range(total_segs):
			# theta = 0 en frente (-Z), PI/2 en +X, PI en espalda (+Z), 3*PI/2 en -X
			var theta: float = TAU * float(s) / float(total_segs)
			var st: float = sin(theta)
			var ct: float = cos(theta)
			var st_shape: float = signf(st) * pow(absf(st), 0.90)
			var ct_shape: float = signf(ct) * pow(absf(ct), 0.84 if ct >= 0.0 else 0.94)
			# En la nuca (+Z, ct < 0) por debajo de las orejas (y_2d > -2), el cráneo se estrecha
			# suavemente hacia el cuello para que de espaldas nunca asome mandíbula a los lados del pelo
			var f_nuca_back: float = clampf(-ct, 0.0, 1.0) * clampf((y_2d + 2.0) / 22.0, 0.0, 1.0)
			var rx_uso: float = lerpf(rx_2d, minf(rx_2d, 10.0 * jaw_w), f_nuca_back * 0.78)
			var rz_uso: float = rz_front_2d if ct >= 0.0 else rz_back_2d
			var x_3d: float = st_shape * rx_uso * ESC
			var z_3d: float = -ct_shape * rz_uso * ESC
			ring_pts.append(Vector3(x_3d, y_3d, z_3d))
		pos_grid.append(ring_pts)

	var total_segs: int = half_segs * 2
	var norm_grid: Array = []
	for r in range(rings + 1):
		var ring_norms: Array[Vector3] = []
		if r == 0:
			for _s in range(total_segs):
				ring_norms.append(Vector3.UP)
		elif r == rings:
			for _s in range(total_segs):
				ring_norms.append(Vector3.DOWN)
		else:
			for s in range(total_segs):
				var p_prev_s: Vector3 = pos_grid[r][(s - 1 + total_segs) % total_segs]
				var p_next_s: Vector3 = pos_grid[r][(s + 1) % total_segs]
				var p_up: Vector3 = pos_grid[r - 1][s]
				var p_dn: Vector3 = pos_grid[r + 1][s]
				var n: Vector3 = (p_up - p_dn).cross(p_next_s - p_prev_s).normalized()
				if n.length_squared() < 0.01:
					n = Vector3(sin(TAU * float(s) / float(total_segs)), 0.0, -cos(TAU * float(s) / float(total_segs))).normalized()
				ring_norms.append(n)
		norm_grid.append(ring_norms)

	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	# 1. Hemisferio frontal (-Z) con UV planar frontal exacto al lienzo 2D de la cara
	var base_idx_front: int = 0
	var cols_half: int = half_segs + 1
	for r in range(rings + 1):
		var y_2d: float = y2d_rings[r]
		for k in range(cols_half):
			var s_idx: int = (total_segs - half_segs / 2 + k) % total_segs
			var pos: Vector3 = pos_grid[r][s_idx]
			var nrm: Vector3 = norm_grid[r][s_idx]
			var x_2d: float = -pos.x / ESC
			verts.append(pos)
			norms.append(nrm)
			uvs.append(Tex3D.uv_cara(x_2d, y_2d))

	for r in range(rings):
		for k in range(half_segs):
			var i00: int = base_idx_front + r * cols_half + k
			var i10: int = base_idx_front + (r + 1) * cols_half + k
			var i01: int = i00 + 1
			var i11: int = i10 + 1
			indices.append_array([i00, i10, i01, i01, i10, i11])

	# 2. Hemisferio trasero (+Z) mapeado a zona limpia de piel (0.04, 0.04)
	var base_idx_back: int = verts.size()
	var uv_piel := Vector2(0.04, 0.04)
	for r in range(rings + 1):
		for k in range(cols_half):
			var s_idx: int = (half_segs / 2 + k) % total_segs
			verts.append(pos_grid[r][s_idx])
			norms.append(norm_grid[r][s_idx])
			uvs.append(uv_piel)

	for r in range(rings):
		for k in range(half_segs):
			var i00: int = base_idx_back + r * cols_half + k
			var i10: int = base_idx_back + (r + 1) * cols_half + k
			var i01: int = i00 + 1
			var i11: int = i10 + 1
			indices.append_array([i00, i10, i01, i01, i10, i11])

	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_INDEX] = indices

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return mesh


## Crea la malla 3D anatómica del torso con las medidas exactas de Personaje_Visual
## (hombros, pecho, cintura y cadera) y mapeo UV frontal/trasero 1:1.
static func _crear_malla_torso(es_mujer: bool, met: Dictionary, ap: Dictionary) -> ArrayMesh:
	var sh_x: float = met["sh_x"]
	var waist_x: float = met["waist_x"]
	var hip_x: float = met["hip_x"]

	var torso_ctrl := PackedVector2Array([
		Vector2(-15.5, 43.0), Vector2(15.5, 43.0), Vector2(sh_x, 51.5),
		Vector2(sh_x + 1.5, 69.0), Vector2(waist_x, 99.0), Vector2(hip_x, 124.0),
		Vector2(0.0, 128.5), Vector2(-hip_x, 124.0), Vector2(-waist_x, 99.0),
		Vector2(-sh_x - 1.5, 69.0), Vector2(-sh_x, 51.5),
	])
	var contorno := Tex3D.suavizar_cerrado(torso_ctrl, 4)

	var comp := str(ap.get("complexion", "normal"))
	var chest_f := 16.0 if es_mujer else 16.8
	var waist_f := 12.2 if es_mujer else 13.8
	var hip_f := 14.8 if es_mujer else 15.0
	var back_b := 15.2 if es_mujer else 16.0
	var waist_b := 12.4 if es_mujer else 13.8
	var hip_b := 15.6 if es_mujer else 15.2
	match comp:
		"delgado":
			chest_f -= 2.2
			waist_f -= 2.0
			hip_f -= 1.8
			back_b -= 1.8
			waist_b -= 1.8
			hip_b -= 1.8
		"atletico":
			chest_f += 2.2
			back_b += 1.6
		"robusto":
			chest_f += 4.2
			waist_f += 6.2
			hip_f += 4.5
			back_b += 3.0
			waist_b += 3.2
			hip_b += 3.5

	var y_top: float = 42.5
	var y_bot: float = 128.5
	var rings: int = 20
	var half_segs: int = 14
	var total_segs: int = half_segs * 2

	var pos_grid: Array = []
	var y2d_rings := PackedFloat32Array()

	for r in range(rings + 1):
		var t: float = float(r) / float(rings)
		var y_2d: float = lerpf(y_top, y_bot, t)
		y2d_rings.append(y_2d)

		var rx_2d: float = 0.0
		var rz_f_2d: float = 0.0
		var rz_b_2d: float = 0.0
		if r > 0 and r < rings:
			rx_2d = _evaluar_semiancho_poligono(contorno, y_2d)
			if y_2d < 52.0:
				var kt: float = clampf((y_2d - y_top) / (52.0 - y_top), 0.0, 1.0)
				rz_f_2d = lerpf(11.0, chest_f * 0.94, sqrt(kt))
				rz_b_2d = lerpf(11.0, back_b * 0.94, sqrt(kt))
			elif y_2d < 68.0:
				var kt: float = (y_2d - 52.0) / 16.0
				rz_f_2d = lerpf(chest_f * 0.94, chest_f, kt)
				rz_b_2d = lerpf(back_b * 0.94, back_b, kt)
			elif y_2d < 99.0:
				var kt: float = (y_2d - 68.0) / 31.0
				rz_f_2d = lerpf(chest_f, waist_f, kt)
				rz_b_2d = lerpf(back_b, waist_b, kt)
			elif y_2d < 123.0:
				var kt: float = (y_2d - 99.0) / 24.0
				rz_f_2d = lerpf(waist_f, hip_f, kt)
				rz_b_2d = lerpf(waist_b, hip_b, kt)
			else:
				var kt: float = clampf((y_bot - y_2d) / (y_bot - 123.0), 0.0, 1.0)
				rz_f_2d = hip_f * sqrt(kt)
				rz_b_2d = hip_b * sqrt(kt)

		# En el nodo _torso, el origen Y local está en la cadera (y_2d = 124.0)
		var y_3d: float = (124.0 - y_2d) * ESC
		var ring_pts: Array[Vector3] = []
		for s in range(total_segs):
			var theta: float = TAU * float(s) / float(total_segs)
			var st: float = sin(theta)
			var ct: float = cos(theta)
			var st_s: float = signf(st) * pow(absf(st), 0.86)
			var ct_s: float = signf(ct) * pow(absf(ct), 0.78)
			var rz_uso: float = rz_f_2d if ct >= 0.0 else rz_b_2d
			ring_pts.append(Vector3(st_s * rx_2d * ESC, y_3d, -ct_s * rz_uso * ESC))
		pos_grid.append(ring_pts)

	var norm_grid: Array = []
	for r in range(rings + 1):
		var ring_norms: Array[Vector3] = []
		if r == 0:
			for _s in range(total_segs):
				ring_norms.append(Vector3.UP)
		elif r == rings:
			for _s in range(total_segs):
				ring_norms.append(Vector3.DOWN)
		else:
			for s in range(total_segs):
				var p_prev_s: Vector3 = pos_grid[r][(s - 1 + total_segs) % total_segs]
				var p_next_s: Vector3 = pos_grid[r][(s + 1) % total_segs]
				var p_up: Vector3 = pos_grid[r - 1][s]
				var p_dn: Vector3 = pos_grid[r + 1][s]
				var n: Vector3 = (p_up - p_dn).cross(p_next_s - p_prev_s).normalized()
				if n.length_squared() < 0.01:
					n = Vector3(sin(TAU * float(s) / float(total_segs)), 0.0, -cos(TAU * float(s) / float(total_segs))).normalized()
				ring_norms.append(n)
		norm_grid.append(ring_norms)

	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var cols_half: int = half_segs + 1

	# Frente del torso (-Z)
	var base_f: int = 0
	for r in range(rings + 1):
		var y_2d: float = y2d_rings[r]
		for k in range(cols_half):
			var s_idx: int = (total_segs - half_segs / 2 + k) % total_segs
			var pos: Vector3 = pos_grid[r][s_idx]
			verts.append(pos)
			norms.append(norm_grid[r][s_idx])
			uvs.append(Tex3D.uv_torso_frente(-pos.x / ESC, y_2d))

	for r in range(rings):
		for k in range(half_segs):
			var i00: int = base_f + r * cols_half + k
			var i10: int = base_f + (r + 1) * cols_half + k
			var i01: int = i00 + 1
			var i11: int = i10 + 1
			indices.append_array([i00, i10, i01, i01, i10, i11])

	# Espalda del torso (+Z)
	var base_b: int = verts.size()
	for r in range(rings + 1):
		var y_2d: float = y2d_rings[r]
		for k in range(cols_half):
			var s_idx: int = (half_segs / 2 + k) % total_segs
			var pos: Vector3 = pos_grid[r][s_idx]
			verts.append(pos)
			norms.append(norm_grid[r][s_idx])
			uvs.append(Tex3D.uv_torso_espalda(pos.x / ESC, y_2d))

	for r in range(rings):
		for k in range(half_segs):
			var i00: int = base_b + r * cols_half + k
			var i10: int = base_b + (r + 1) * cols_half + k
			var i01: int = i00 + 1
			var i11: int = i10 + 1
			indices.append_array([i00, i10, i01, i01, i10, i11])

	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_INDEX] = indices

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return mesh


## Crea una extremidad / cápsula cónica orgánica suave desde y0 hasta y1 con tapas semiesféricas.
static func _crear_malla_extremidad(y0: float, y1: float, r0: float, r1: float, segs: int = 14, rings_tapa: int = 3) -> ArrayMesh:
	var y_top: float = maxf(y0, y1)
	var y_bot: float = minf(y0, y1)
	var r_top: float = r0 if y0 >= y1 else r1
	var r_bot: float = r1 if y0 >= y1 else r0

	var perfiles: Array[Vector2] = [] # (y, r)
	for i in range(rings_tapa + 1):
		var a: float = (PI * 0.5) * float(i) / float(rings_tapa)
		perfiles.append(Vector2(y_top + cos(a) * r_top * 0.55, sin(a) * r_top))
	var pasos_cuerpo: int = 4
	for i in range(1, pasos_cuerpo):
		var t: float = float(i) / float(pasos_cuerpo)
		perfiles.append(Vector2(lerpf(y_top, y_bot, t), lerpf(r_top, r_bot, t)))
	for i in range(rings_tapa + 1):
		var a: float = (PI * 0.5) * float(i) / float(rings_tapa)
		perfiles.append(Vector2(y_bot - sin(a) * r_bot * 0.55, cos(a) * r_bot))

	return _crear_malla_revolucion(perfiles, segs)


static func _crear_malla_revolucion(perfiles: Array[Vector2], segs: int = 16, escala_xz: Vector2 = Vector2.ONE, con_uv_falda: bool = false) -> ArrayMesh:
	var rings: int = perfiles.size() - 1
	var pos_grid: Array = []
	for r in range(rings + 1):
		var py: float = perfiles[r].x
		var pr: float = maxf(0.0, perfiles[r].y)
		var fila: Array[Vector3] = []
		for s in range(segs):
			var a: float = TAU * float(s) / float(segs)
			fila.append(Vector3(sin(a) * pr * escala_xz.x, py, -cos(a) * pr * escala_xz.y))
		pos_grid.append(fila)

	var norm_grid: Array = []
	for r in range(rings + 1):
		var fila_n: Array[Vector3] = []
		if r == 0 and perfiles[0].y <= 0.0001:
			for _s in range(segs):
				fila_n.append(Vector3.UP)
		elif r == rings and perfiles[rings].y <= 0.0001:
			for _s in range(segs):
				fila_n.append(Vector3.DOWN)
		else:
			for s in range(segs):
				var p_l: Vector3 = pos_grid[r][(s - 1 + segs) % segs]
				var p_r: Vector3 = pos_grid[r][(s + 1) % segs]
				var p_u: Vector3 = pos_grid[maxi(0, r - 1)][s]
				var p_d: Vector3 = pos_grid[mini(rings, r + 1)][s]
				var n: Vector3 = (p_u - p_d).cross(p_r - p_l).normalized()
				if n.length_squared() < 0.01:
					var a: float = TAU * float(s) / float(segs)
					n = Vector3(sin(a), 0.0, -cos(a)).normalized()
				fila_n.append(n)
		norm_grid.append(fila_n)

	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var cols: int = segs + 1

	var r_denom: float = float(maxi(1, rings - 1)) if con_uv_falda else float(maxi(1, rings))
	for r in range(rings + 1):
		var v_uv: float = clampf(float(r) / r_denom, 0.0, 1.0)
		for s in range(cols):
			var si: int = s % segs
			verts.append(pos_grid[r][si])
			norms.append(norm_grid[r][si])
			if con_uv_falda:
				var a: float = TAU * float(s) / float(segs)
				var u_uv: float = clampf(0.5 - 0.44 * sin(a), 0.04, 0.96)
				uvs.append(Vector2(u_uv, v_uv))

	for r in range(rings):
		for s in range(segs):
			var i00: int = r * cols + s
			var i10: int = (r + 1) * cols + s
			var i01: int = i00 + 1
			var i11: int = i10 + 1
			indices.append_array([i00, i10, i01, i01, i10, i11])

	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	if con_uv_falda:
		arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return mesh


## Crea un mechón 3D orgánico curvo a lo largo de una curva Catmull-Rom 3D con punta afilada.
static func _crear_malla_mechon_3d(puntos_ctrl: Array, radio_base: float, escala_ancho: float = 1.0, segs_tubo: int = 10, subdiv: int = 3) -> ArrayMesh:
	var n_ctrl: int = puntos_ctrl.size()
	if n_ctrl < 2:
		return ArrayMesh.new()

	var ext: Array[Vector3] = []
	ext.append(puntos_ctrl[0])
	for p in puntos_ctrl:
		ext.append(p)
	ext.append(puntos_ctrl[n_ctrl - 1])

	var curva: Array[Vector3] = []
	for i in range(1, ext.size() - 2):
		var p0: Vector3 = ext[i - 1]
		var p1: Vector3 = ext[i]
		var p2: Vector3 = ext[i + 1]
		var p3: Vector3 = ext[i + 2]
		for s in range(subdiv):
			var t: float = float(s) / float(subdiv)
			var t2: float = t * t
			var t3: float = t2 * t
			curva.append(0.5 * (
				(2.0 * p1) +
				(-p0 + p2) * t +
				(2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 +
				(-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
			))
	curva.append(puntos_ctrl[n_ctrl - 1])

	var rings: int = curva.size() - 1
	var pos_grid: Array = []
	var norm_grid: Array = []
	var up_ref := Vector3.UP

	for r in range(rings + 1):
		var u: float = float(r) / float(rings)
		var factor_r: float = sin(pow(u, 0.65) * PI)
		if r == 0 or r == rings:
			factor_r = 0.0
		var rad: float = radio_base * factor_r

		var tang: Vector3
		if r == 0:
			tang = (curva[1] - curva[0]).normalized()
		elif r == rings:
			tang = (curva[rings] - curva[rings - 1]).normalized()
		else:
			tang = (curva[r + 1] - curva[r - 1]).normalized()
		if tang.length_squared() < 0.001:
			tang = Vector3.DOWN

		if absf(tang.dot(up_ref)) > 0.92:
			up_ref = Vector3.FORWARD
		var eje_x: Vector3 = tang.cross(up_ref).normalized()
		var eje_y: Vector3 = eje_x.cross(tang).normalized()

		var fila_p: Array[Vector3] = []
		var fila_n: Array[Vector3] = []
		for s in range(segs_tubo):
			var a: float = TAU * float(s) / float(segs_tubo)
			var ca: float = cos(a)
			var sa: float = sin(a)
			var dir_n: Vector3 = (eje_x * (ca * escala_ancho) + eje_y * sa).normalized()
			if r == 0:
				fila_p.append(curva[r])
				fila_n.append(-tang)
			elif r == rings:
				fila_p.append(curva[r])
				fila_n.append(tang)
			else:
				fila_p.append(curva[r] + eje_x * (ca * rad * escala_ancho) + eje_y * (sa * rad))
				fila_n.append(dir_n)
		pos_grid.append(fila_p)
		norm_grid.append(fila_n)

	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var indices := PackedInt32Array()
	var cols: int = segs_tubo + 1

	for r in range(rings + 1):
		for s in range(cols):
			var si: int = s % segs_tubo
			verts.append(pos_grid[r][si])
			norms.append(norm_grid[r][si])

	for r in range(rings):
		for s in range(segs_tubo):
			var i00: int = r * cols + s
			var i10: int = (r + 1) * cols + s
			var i01: int = i00 + 1
			var i11: int = i10 + 1
			indices.append_array([i00, i01, i10, i01, i11, i10])

	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return mesh


## Crea un volumen 3D cerrado cuya silueta ecuatorial en el plano XY es exactamente el polígono
## 2D del peinado de Personaje_Visual (alborotado, tupé, corto, raya_lado, rizado, afro, degradado).
static func _crear_malla_peinado_silueta_3d(pts_silueta_2d: PackedVector2Array, jaw_w: float,
		y_frente_corte_2d: float = -26.0, z_frente_max_2d: float = 27.2, z_atras_max_2d: float = 30.0) -> ArrayMesh:
	var pts_esc := PackedVector2Array()
	for p in pts_silueta_2d:
		pts_esc.append(Vector2(p.x * jaw_w, p.y))
	var silueta := Tex3D.suavizar_cerrado(pts_esc, 3)
	var segs: int = silueta.size()
	var centro_2d := Vector2(0.0, -13.0)
	var r_eq: int = 8
	var rings: int = 16

	var pos_grid: Array = []
	for r in range(rings + 1):
		var fila: Array[Vector3] = []
		if r == 0:
			var p_front := Vector3(0.0, -centro_2d.y * ESC, -7.0 * jaw_w * ESC)
			for _s in range(segs):
				fila.append(p_front)
		elif r == rings:
			var p_back := Vector3(0.0, -centro_2d.y * ESC, z_atras_max_2d * jaw_w * ESC)
			for _s in range(segs):
				fila.append(p_back)
		elif r < r_eq:
			var t_f: float = float(r) / float(r_eq)
			var u_xy: float = pow(sin(t_f * PI * 0.5), 0.88)
			var dome_z: float = pow(cos(t_f * PI * 0.5), 0.68)
			for s in range(segs):
				var p_sil: Vector2 = silueta[s]
				var p_2d: Vector2 = centro_2d.lerp(p_sil, u_xy)
				var f_nuca: float = clampf((p_sil.y + 2.0) / 22.0, 0.0, 1.0)
				var z_eq_2d: float = 11.5 * f_nuca
				var f_cara: float = clampf((p_2d.y - y_frente_corte_2d) / 9.5, 0.0, 1.0)
				var z_alcance_2d: float = lerpf(z_frente_max_2d * jaw_w, 6.0 * jaw_w, f_cara * f_cara)
				var z_2d: float = lerpf(z_eq_2d, -z_alcance_2d, dome_z)
				var x_uso: float = p_2d.x * lerpf(1.0, 0.72, f_nuca * dome_z)
				fila.append(Vector3(-x_uso * ESC, -p_2d.y * ESC, z_2d * ESC))
		elif r == r_eq:
			for s in range(segs):
				var p_sil: Vector2 = silueta[s]
				var f_nuca: float = clampf((p_sil.y + 2.0) / 22.0, 0.0, 1.0)
				var z_eq_2d: float = 11.5 * f_nuca
				fila.append(Vector3(-p_sil.x * ESC, -p_sil.y * ESC, z_eq_2d * ESC))
		else:
			var t_b: float = float(r - r_eq) / float(rings - r_eq)
			var u_xy: float = pow(cos(t_b * PI * 0.5), 0.84)
			var dome_z: float = pow(sin(t_b * PI * 0.5), 0.65)
			for s in range(segs):
				var p_sil: Vector2 = silueta[s]
				var p_2d: Vector2 = centro_2d.lerp(p_sil, u_xy)
				var f_nuca: float = clampf((p_sil.y + 2.0) / 22.0, 0.0, 1.0)
				var z_eq_2d: float = 11.5 * f_nuca
				var z_2d: float = lerpf(z_eq_2d, z_atras_max_2d * jaw_w, dome_z)
				fila.append(Vector3(-p_2d.x * ESC, -p_2d.y * ESC, z_2d * ESC))
		pos_grid.append(fila)

	var centro_3d := Vector3(0.0, -centro_2d.y * ESC, 4.0 * ESC)
	var norm_grid: Array = []
	for r in range(rings + 1):
		var fila_n: Array[Vector3] = []
		if r == 0:
			for _s in range(segs):
				fila_n.append(Vector3.FORWARD)
		elif r == rings:
			for _s in range(segs):
				fila_n.append(Vector3.BACK)
		else:
			for s in range(segs):
				var p_l: Vector3 = pos_grid[r][(s - 1 + segs) % segs]
				var p_r: Vector3 = pos_grid[r][(s + 1) % segs]
				var p_u: Vector3 = pos_grid[r - 1][s]
				var p_d: Vector3 = pos_grid[r + 1][s]
				var n_geom: Vector3 = (p_d - p_u).cross(p_l - p_r).normalized()
				var n_rad: Vector3 = (pos_grid[r][s] - centro_3d).normalized()
				if n_geom.dot(n_rad) < 0.0:
					n_geom = -n_geom
				var n: Vector3 = (n_geom * 0.65 + n_rad * 0.35).normalized()
				if n.length_squared() < 0.01:
					n = n_rad
				fila_n.append(n)
		norm_grid.append(fila_n)

	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var indices := PackedInt32Array()
	var cols: int = segs + 1

	for r in range(rings + 1):
		for s in range(cols):
			var si: int = s % segs
			verts.append(pos_grid[r][si])
			norms.append(norm_grid[r][si])

	for r in range(rings):
		for s in range(segs):
			var i00: int = r * cols + s
			var i10: int = (r + 1) * cols + s
			var i01: int = i00 + 1
			var i11: int = i10 + 1
			indices.append_array([i00, i10, i01, i01, i10, i11])

	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return mesh


## Crea un volumen 3D CERRADO para el casquete del pelo que cubre coronilla, sienes y nuca.
## En la frente (-Z) pasa por detrás de la superficie facial por debajo de y_frente_2d
## para que el flequillo 2D dibujado en la textura del rostro se vea 100% limpio y sin líneas negras.
static func _crear_malla_casquete_pelo(es_mujer: bool, forma_cara: String, jaw_w: float,
		y_frente_2d: float = -26.5, y_nuca_2d: float = 28.0, escala_vol: float = 1.07,
		y_top_2d: float = -41.0, ondulacion: float = 0.0) -> ArrayMesh:
	var contorno := _contorno_rostro_2d(es_mujer, forma_cara, jaw_w)
	var rings: int = 18
	var segs: int = 32

	var pos_grid: Array = []
	for r in range(rings + 1):
		var t: float = float(r) / float(rings)
		var k: float = 0.5 * (1.0 - cos(t * PI))
		var y_2d: float = lerpf(y_top_2d, y_nuca_2d, k)
		var fila: Array[Vector3] = []

		for s in range(segs):
			var theta: float = TAU * float(s) / float(segs)
			var st: float = sin(theta)
			var ct: float = cos(theta) # ct > 0 frente (-Z), ct < 0 nuca (+Z)

			if r == 0 or r == rings:
				var z_pole: float = 2.0 * ESC if r == rings else -1.0 * ESC
				fila.append(Vector3(0.0, -y_2d * ESC, z_pole))
				continue

			var rx_head: float = _evaluar_semiancho_poligono(contorno, clampf(y_2d, -36.5, 32.0))
			var env_top: float = clampf((y_2d - y_top_2d) / 10.0, 0.0, 1.0)
			var env_bot: float = clampf((y_nuca_2d - y_2d) / 7.5, 0.0, 1.0)
			var env: float = pow(sin(clampf(env_top, 0.0, 1.0) * PI * 0.5), 0.75) * pow(sin(clampf(env_bot, 0.0, 1.0) * PI * 0.5), 0.65)

			# Ondulación orgánica de silueta para peinados con volumen (alborotado, rizado, tupé)
			var onda: float = 0.0
			if ondulacion > 0.0:
				var peso_onda: float = clampf(1.0 - (y_2d + 28.0) / 36.0, 0.0, 1.0)
				onda = ondulacion * peso_onda * (0.045 * sin(theta * 3.0 - 0.5) + 0.032 * cos(theta * 5.0 + 0.4))

			var vol_actual: float = (escala_vol + onda) * env
			var rx_2d: float = rx_head * vol_actual
			var rz_back_2d: float = rx_head * 0.96 * (escala_vol + 0.03 + onda) * env
			var rz_front_2d: float = rx_head * 0.84 * vol_actual

			# Por debajo de la línea de coronilla frontal (y_2d > y_frente_2d), el casquete
			# se retrae suavemente hacia el interior de la cabeza en el frente (ct > 0)
			if y_2d > y_frente_2d and ct > -0.10:
				var f_frente: float = clampf((ct + 0.10) / 0.85, 0.0, 1.0)
				var f_bajo: float = clampf((y_2d - y_frente_2d) / 10.0, 0.0, 1.0)
				var retraccion: float = f_frente * f_frente * f_bajo
				rz_front_2d *= lerpf(1.0, 0.45, retraccion)
				rx_2d *= lerpf(1.0, 0.72, retraccion * f_frente)

			var st_s: float = signf(st) * pow(absf(st), 0.90)
			var ct_s: float = signf(ct) * pow(absf(ct), 0.86 if ct >= 0.0 else 0.92)
			var rz_uso: float = rz_front_2d if ct >= 0.0 else rz_back_2d
			fila.append(Vector3(st_s * rx_2d * ESC, -y_2d * ESC, -ct_s * rz_uso * ESC))
		pos_grid.append(fila)

	var norm_grid: Array = []
	var centro_craneo := Vector3(0.0, 6.0 * ESC, 2.0 * ESC)
	for r in range(rings + 1):
		var fila_n: Array[Vector3] = []
		if r == 0:
			for _s in range(segs):
				fila_n.append(Vector3.UP)
		elif r == rings:
			for _s in range(segs):
				fila_n.append(Vector3.DOWN)
		else:
			for s in range(segs):
				var p_l: Vector3 = pos_grid[r][(s - 1 + segs) % segs]
				var p_r: Vector3 = pos_grid[r][(s + 1) % segs]
				var p_u: Vector3 = pos_grid[r - 1][s]
				var p_d: Vector3 = pos_grid[r + 1][s]
				var n_geom: Vector3 = (p_u - p_d).cross(p_r - p_l).normalized()
				var n_rad: Vector3 = (pos_grid[r][s] - centro_craneo).normalized()
				var n: Vector3 = (n_geom * 0.65 + n_rad * 0.35).normalized()
				if n.length_squared() < 0.01:
					n = n_rad
				fila_n.append(n)
		norm_grid.append(fila_n)

	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var indices := PackedInt32Array()
	var cols: int = segs + 1

	for r in range(rings + 1):
		for s in range(cols):
			var si: int = s % segs
			verts.append(pos_grid[r][si])
			norms.append(norm_grid[r][si])

	for r in range(rings):
		for s in range(segs):
			var i00: int = r * cols + s
			var i10: int = (r + 1) * cols + s
			var i01: int = i00 + 1
			var i11: int = i10 + 1
			indices.append_array([i00, i10, i01, i01, i10, i11])

	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return mesh


## Crea una malla de calzado 3D redondeada y estilizada (zapatilla, bota o zapato).
static func _crear_malla_zapato_base(alto_cana: float, largo_punta: float, ancho: float) -> ArrayMesh:
	var perfiles: Array[Vector2] = [
		Vector2(alto_cana, 0.0),
		Vector2(alto_cana * 0.96, ancho * 0.72),
		Vector2(alto_cana * 0.55, ancho * 0.88),
		Vector2(0.02, ancho * 1.0),
		Vector2(-0.02, ancho * 0.96),
		Vector2(-0.03, 0.0),
	]
	return _crear_malla_revolucion(perfiles, 16, Vector2(1.0, largo_punta / maxf(0.01, ancho)))


# ----------------------------------------------------------------------------
# Construcción completa del Sim 3D desde su diccionario de Apariencia
# ----------------------------------------------------------------------------

func aplicar_apariencia(datos: Dictionary, edad: int = -1) -> void:
	_jetpack_llamas.clear()
	_hoverboard = null
	_jetpack = null
	_pogo = null
	_magnet_aura = null
	for hijo in get_children():
		remove_child(hijo)
		hijo.free()

	var ap: Dictionary = Apariencia_Personaje.normalizar(datos)
	apariencia_actual = ap
	var edad_ef: int = edad if edad >= 0 else _obtener_edad_partida()
	edad_actual = edad_ef
	var rasgos_edad: Dictionary = Envejecimiento_Personaje.rasgos(edad_ef)

	var es_mujer: bool = Apariencia_Personaje.es_mujer(ap)
	var met: Dictionary = Tex3D.metricas_cuerpo(es_mujer, ap)
	var jaw_w: float = float(met["jaw_w"])
	var sh_x: float = float(met["sh_x"])
	var waist_x: float = float(met["waist_x"])
	var hip_x: float = float(met["hip_x"])
	var hip_leg_x: float = float(met["hip_leg_x"])
	var nw: float = float(met["nw"])
	var arm_scale: float = float(met["arm_scale"])
	var leg_scale: float = float(met["leg_scale"])

	var estilo_ropa: String = Apariencia_Personaje.estilo_ropa_de(ap)
	var detalle_ropa: String = str(ap.get("detalle_ropa", ""))
	var ropa_sup: String = str(ap.get("ropa_superior", "sudadera"))
	var ropa_inf: String = str(ap.get("ropa_inferior", "vaqueros"))
	var calzado: String = str(ap.get("calzado", "zapatillas"))
	var estilo_pelo: String = str(ap.get("estilo_pelo", "alborotado"))
	var forma_cara: String = str(ap.get("forma_cara", "ovalada"))
	var forma_nariz: String = str(ap.get("forma_nariz", "normal"))
	var sombrero: String = str(ap.get("sombrero", "ninguno"))
	var gafas: String = str(ap.get("gafas", "ninguna"))
	var vello: String = str(ap.get("vello_facial", "ninguno"))
	var pendientes: String = str(ap.get("pendientes", "ninguno"))

	# Paleta canónica del Sim calibrada para iluminación 3D (1:1 con Texturas_Personaje_3D)
	var col_piel: Color = Tex3D.calibrar_color_3d(Envejecimiento_Personaje.color_piel(
		Apariencia_Personaje.color_de(ap, "color_piel", Color("#f8cfb4")),
		float(rasgos_edad.get("piel_apagada", 0.0))))
	var col_pelo: Color = Tex3D.calibrar_color_3d(Envejecimiento_Personaje.color_pelo(
		Apariencia_Personaje.color_de(ap, "color_pelo", Color("#7c4728")),
		float(rasgos_edad.get("canas", 0.0))))
	var col_ropa: Color = Tex3D.calibrar_color_3d(Apariencia_Personaje.color_de(ap, "color_ropa", Color("#2563eb")))
	var col_ropa_sec: Color = Tex3D.calibrar_color_3d(Apariencia_Personaje.color_de(ap, "color_ropa_secundario", Color("#f8fafc")))
	var col_ropa_det: Color = Tex3D.calibrar_color_3d(Apariencia_Personaje.color_de(ap, "color_ropa_detalle", col_ropa.lightened(0.25)))
	var col_pant: Color = Tex3D.calibrar_color_3d(Apariencia_Personaje.color_de(ap, "color_pantalon", Color("#3b6ea5")))
	var col_calz: Color = Tex3D.calibrar_color_3d(Apariencia_Personaje.color_de(ap, "color_calzado", Color("#2563eb")))

	# Capas de manga según atuendo (igual que Personaje_Visual._draw líneas 1265-1278)
	var ropa_sup_brazos := ropa_sup
	var col_ropa_brazos := col_ropa
	match estilo_ropa:
		"traje", "bata", "cuero", "fiesta":
			ropa_sup_brazos = "chaqueta"
			col_ropa_brazos = col_ropa_sec
		"invierno":
			if detalle_ropa == "abrigo":
				ropa_sup_brazos = "chaqueta"
				col_ropa_brazos = col_ropa_sec
		"astronauta":
			ropa_sup_brazos = "chaqueta"
			col_ropa_brazos = col_ropa

	var mat_piel := _mat(col_piel, 0.88, 0.0)
	var mat_piel_sin_borde := _mat(col_piel, 0.88, 0.0, Color.BLACK, 0.0, false)
	var mat_piel_sombra := _mat(Tex3D.sombra_piel(col_piel), 0.90, 0.0, Color.BLACK, 0.0, false)
	var mat_pelo := _mat(col_pelo, 0.86, 0.0)
	var mat_pelo_relieve := _mat(col_pelo.lightened(0.05), 0.86, 0.0, Color.BLACK, 0.0, false)
	var mat_pelo_osc := _mat(col_pelo.darkened(0.16), 0.88, 0.0, Color.BLACK, 0.0, false)
	var mat_ropa := _mat(col_ropa, 0.86, 0.0)
	var mat_ropa_sombra := _mat(col_ropa.darkened(0.18), 0.88, 0.0)
	var mat_ropa_brazos := _mat(col_ropa_brazos, 0.86, 0.0)
	var mat_ropa_sec := _mat(col_ropa_sec, 0.84, 0.0)
	var mat_ropa_det := _mat(col_ropa_det, 0.80, 0.04)
	var mat_pant := _mat(col_pant, 0.88, 0.0)
	var mat_calz := _mat(col_calz, 0.78, 0.02)
	var mat_blanco := _mat(Tex3D.calibrar_color_3d(Color("#f8fafc"), 0.10), 0.82, 0.0)
	var mat_oscuro := _mat(Color("#1e293b"), 0.75, 0.05)
	var mat_neon_verde := _mat(Color("#39ff88"), 0.28, 0.20, Color("#16a34a"), 0.75, false)
	var mat_cian := _mat(Color("#38bdf8"), 0.22, 0.35, Color("#0284c7"), 1.0, false)
	var mat_coral := _mat(Color("#f43f5e"), 0.22, 0.35, Color("#e11d48"), 1.0, false)

	# Texturas 2D->3D de rostro (normal, parpadeo, concentrado y sorpresa/choque) y torso
	_tex_rostro_normal = Tex3D.generar_textura_rostro(ap, edad_ef, expresion_actual, Vector2.ZERO, false)
	_tex_rostro_parpadeo = Tex3D.generar_textura_rostro(ap, edad_ef, expresion_actual, Vector2.ZERO, true)
	_tex_rostro_esfuerzo = Tex3D.generar_textura_rostro(ap, edad_ef, "concentrado", Vector2(0.0, -0.2), false)
	_tex_rostro_choque = Tex3D.generar_textura_rostro(ap, edad_ef, "sorpresa", Vector2.ZERO, false)
	_mat_rostro = _mat_textura(_tex_rostro_normal, 0.90, true, 0.010)
	_estado_rostro_activo = "normal"

	var tex_torso: ImageTexture = Tex3D.generar_textura_torso(ap, edad_ef)
	var mat_torso_tex := _mat_textura(tex_torso, 0.90, true, 0.010)

	# 1. Sombra de contacto en el suelo
	_shadow_disc = MeshInstance3D.new()
	var sh_mesh := PlaneMesh.new()
	sh_mesh.size = Vector2(1.45, 1.45)
	_shadow_disc.mesh = sh_mesh
	_shadow_disc.material_override = _mat_sombra
	_shadow_disc.position = Vector3(0.0, 0.03, 0.0)
	_shadow_disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_shadow_disc)

	# 2. Pivote corporal
	_body_pivot = Node3D.new()
	_body_pivot.name = "BodyPivot"
	add_child(_body_pivot)

	# 3. Torso anatómico 3D (origen en cadera y_2d = 124 -> y_3d = 0.707 m)
	var hip_y_3d: float = (219.5 - 124.0) * ESC # 0.7067 m
	_torso = Node3D.new()
	_torso.name = "Torso"
	_torso.position = Vector3(0.0, hip_y_3d, 0.0)
	_body_pivot.add_child(_torso)

	var malla_torso := _crear_malla_torso(es_mujer, met, ap)
	_inst_malla(_torso, malla_torso, mat_torso_tex)

	# Detalles 3D volumétricos sobre el torso (capucha, bufanda, faldones, falda texturizada, pelvis...)
	_construir_accesorios_torso_3d(_torso, es_mujer, met, ap, ropa_sup, ropa_inf, estilo_ropa, detalle_ropa,
		mat_piel, mat_ropa, mat_ropa_sombra, mat_ropa_sec, mat_ropa_det, mat_pant, mat_blanco, mat_cian)

	# 4. Cuello y Cabeza 3D esculpida (centro cabeza y_2d = 0 -> dy desde cadera = 124 * ESC = 0.9176 m)
	var head_y_desde_cadera: float = 124.0 * ESC
	var neck_bot_y: float = (124.0 - 48.0) * ESC
	var neck_top_y: float = (124.0 - 27.0) * ESC
	var malla_cuello := _crear_malla_extremidad(neck_bot_y, neck_top_y, (nw + 1.0) * ESC, nw * ESC, 14, 1)
	_inst_malla(_torso, malla_cuello, mat_piel)

	_head_group = Node3D.new()
	_head_group.name = "HeadGroup"
	_head_group.position = Vector3(0.0, head_y_desde_cadera, 0.0)
	_torso.add_child(_head_group)

	var malla_cabeza := _crear_malla_cabeza(es_mujer, forma_cara, jaw_w)
	_head_mesh_inst = _inst_malla(_head_group, malla_cabeza, _mat_rostro)

	# Nariz 3D esculpida en relieve en el frente (-Z) sin borde de tinta adicional
	_construir_nariz_3d(_head_group, forma_nariz, jaw_w, mat_piel_sin_borde)

	# Orejas 3D y pendientes (aros, perlas, colgantes)
	_construir_orejas_y_pendientes_3d(_head_group, jaw_w, pendientes, mat_piel, mat_piel_sombra)

	# Relieve 3D adicional del vello facial
	if not es_mujer and vello != "ninguno":
		_construir_vello_facial_3d(_head_group, vello, jaw_w, mat_pelo_relieve)

	# Gafas 3D (las lentes y reflejos 2D están en la textura facial; aquí añadimos patillas 3D hacia las orejas)
	if gafas != "ninguna":
		_construir_gafas_3d(_head_group, gafas, jaw_w)

	# Peinado 3D esculpido (los 16 estilos) + subnodo de vaivén para coletas/melena
	_hair_sway = Node3D.new()
	_hair_sway.name = "HairSway"
	_hair_sway.position = Vector3(0.0, 14.0 * ESC, 20.0 * ESC)
	_head_group.add_child(_hair_sway)
	_construir_pelo_3d(_head_group, _hair_sway, es_mujer, forma_cara, jaw_w, estilo_pelo,
		mat_pelo, mat_pelo_relieve, mat_pelo_osc)

	# Sombrero / gorra / gorro / boina / diadema / toque de chef
	if estilo_ropa == "chef" or estilo_ropa == "michelin":
		_construir_gorro_chef_3d(_head_group, jaw_w, mat_blanco)
	elif sombrero != "ninguno":
		_construir_sombrero_3d(_head_group, sombrero, jaw_w, col_ropa)

	# 5. Brazos articulados (Hombro -> Codo -> Mano)
	var res_arm_l := _construir_brazo_articulado(-1.0, sh_x, arm_scale, ropa_sup_brazos, estilo_ropa, detalle_ropa,
		mat_ropa_brazos, mat_piel, mat_piel_sin_borde, mat_ropa_sec, col_ropa_brazos)
	var res_arm_r := _construir_brazo_articulado(1.0, sh_x, arm_scale, ropa_sup_brazos, estilo_ropa, detalle_ropa,
		mat_ropa_brazos, mat_piel, mat_piel_sin_borde, mat_ropa_sec, col_ropa_brazos)
	_left_arm = res_arm_l["arm"]
	_left_forearm = res_arm_l["forearm"]
	_right_arm = res_arm_r["arm"]
	_right_forearm = res_arm_r["forearm"]

	# 6. Piernas articuladas (Cadera -> Rodilla -> Tobillo/Calzado)
	var res_leg_l := _construir_pierna_articulada(-1.0, hip_leg_x, leg_scale, ropa_inf, estilo_ropa, calzado,
		mat_pant, mat_piel, mat_calz, mat_ropa_sec, mat_ropa_det, mat_neon_verde, col_calz)
	var res_leg_r := _construir_pierna_articulada(1.0, hip_leg_x, leg_scale, ropa_inf, estilo_ropa, calzado,
		mat_pant, mat_piel, mat_calz, mat_ropa_sec, mat_ropa_det, mat_neon_verde, col_calz)
	_left_leg = res_leg_l["hip"]
	_left_shin = res_leg_l["knee"]
	_left_foot = res_leg_l["foot"]
	_sneaker_glow_l = res_leg_l["glow"]

	_right_leg = res_leg_r["hip"]
	_right_shin = res_leg_r["knee"]
	_right_foot = res_leg_r["foot"]
	_sneaker_glow_r = res_leg_r["glow"]

	# 7. Hover-Longboard (Tabla urbana luminosa bajo los pies cuando está activa)
	_hoverboard = Node3D.new()
	_hoverboard.name = "Hoverboard"
	_hoverboard.position = Vector3(0.0, 0.14, 0.0)
	_hoverboard.visible = false
	_body_pivot.add_child(_hoverboard)
	_box(_hoverboard, Vector3(0.56, 0.08, 1.56), Vector3.ZERO, mat_oscuro)
	_box(_hoverboard, Vector3(0.08, 0.09, 1.48), Vector3(-0.27, 0.0, 0.0), mat_cian, Vector3.ZERO, false)
	_box(_hoverboard, Vector3(0.08, 0.09, 1.48), Vector3(0.27, 0.0, 0.0), mat_coral, Vector3.ZERO, false)
	_cyl(_hoverboard, 0.18, 0.24, 0.08, Vector3(0.0, -0.06, 0.56), mat_cian, Vector3.ZERO, 12, false)

	# 7b. Mochila jetpack (dos botellas cian + llamas) y pogo-cohete
	_jetpack = Node3D.new()
	_jetpack.name = "Jetpack"
	_jetpack.position = Vector3(0.0, 0.86, 0.24)
	_jetpack.visible = false
	_body_pivot.add_child(_jetpack)
	_box(_jetpack, Vector3(0.52, 0.60, 0.24), Vector3.ZERO, mat_oscuro)
	_box(_jetpack, Vector3(0.44, 0.10, 0.27), Vector3(0.0, 0.20, -0.01), mat_coral, Vector3.ZERO, false)
	_box(_jetpack, Vector3(0.34, 0.18, 0.06), Vector3(0.0, 0.00, 0.14), mat_cian, Vector3.ZERO, false)
	for lado in [-1.0, 1.0]:
		_cyl(_jetpack, 0.13, 0.15, 0.58, Vector3(lado * 0.29, -0.06, 0.20), mat_coral, Vector3.ZERO, 12, false)
		_cyl(_jetpack, 0.10, 0.13, 0.10, Vector3(lado * 0.29, 0.20, 0.20), mat_cian, Vector3.ZERO, 12, false)
		_cyl(_jetpack, 0.075, 0.11, 0.18, Vector3(lado * 0.29, -0.40, 0.20), mat_oscuro, Vector3.ZERO, 12, false)
		var llama := Node3D.new()
		llama.position = Vector3(lado * 0.29, -0.50, 0.20)
		_jetpack.add_child(llama)
		var cono := CylinderMesh.new()
		cono.top_radius = 0.02
		cono.bottom_radius = 0.125
		cono.height = 0.62
		cono.radial_segments = 10
		var mi_con := MeshInstance3D.new()
		mi_con.mesh = cono
		var mat_llama := _mat(Color("#fb923c"), 0.25, 0.0, Color("#f97316"), 2.6, false)
		mi_con.material_override = mat_llama
		mi_con.position.y = -0.28
		llama.add_child(mi_con)
		var nucleo := _sphere(llama, 0.10, Vector3(0.0, -0.06, 0.0), _mat(Color("#fef08a"), 0.2, 0.0, Color("#fde047"), 3.2, false), Vector3(1.0, 1.8, 1.0))
		nucleo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_jetpack_llamas.append(llama)
	_cyl(_jetpack, 0.24, 0.28, 0.06, Vector3(0.0, 0.32, 0.0), mat_coral, Vector3.ZERO, 14, false)
	var luz_jet := OmniLight3D.new()
	luz_jet.name = "LuzJetpack"
	luz_jet.light_color = Color("#fb923c")
	luz_jet.light_energy = 1.6
	luz_jet.omni_range = 2.4
	luz_jet.position = Vector3(0.0, -0.45, 0.10)
	_jetpack.add_child(luz_jet)

	_pogo = Node3D.new()
	_pogo.name = "PogoCohete"
	_pogo.position = Vector3(0.0, 0.08, 0.0)
	_pogo.visible = false
	_body_pivot.add_child(_pogo)
	_cyl(_pogo, 0.035, 0.045, 0.92, Vector3(0.0, -0.44, 0.0), mat_oscuro, Vector3.ZERO, 10, false)
	_cyl(_pogo, 0.11, 0.13, 0.22, Vector3(0.0, -0.86, 0.0), mat_coral, Vector3.ZERO, 12, false)
	_box(_pogo, Vector3(0.46, 0.05, 0.08), Vector3(0.0, 0.04, 0.0), mat_cian, Vector3.ZERO, false)
	for lado in [-1.0, 1.0]:
		_box(_pogo, Vector3(0.05, 0.05, 0.34), Vector3(lado * 0.22, 0.02, 0.0), mat_cian, Vector3.ZERO, false)
	_sphere(_pogo, 0.10, Vector3(0.0, -0.98, 0.0), _mat(Color("#38bdf8"), 0.2, 0.0, Color("#38bdf8"), 2.2, false))

	# 8. Aura energética del Imán
	_magnet_aura = Node3D.new()
	_magnet_aura.name = "MagnetAura"
	_magnet_aura.position = Vector3(0.0, 1.05, 0.0)
	_magnet_aura.visible = false
	_body_pivot.add_child(_magnet_aura)
	var mat_aura := StandardMaterial3D.new()
	mat_aura.albedo_color = Color(0.22, 0.74, 0.97, 0.45)
	mat_aura.emission_enabled = true
	mat_aura.emission = Color("#38bdf8")
	mat_aura.emission_energy_multiplier = 1.4
	mat_aura.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for rot_aura in [Vector3(0.35, 0.0, 0.2), Vector3(-0.55, 0.8, 0.7)]:
		var mi_a := MeshInstance3D.new()
		var toro := TorusMesh.new()
		toro.inner_radius = 0.88
		toro.outer_radius = 0.95
		toro.rings = 24
		toro.ring_segments = 10
		mi_a.mesh = toro
		mi_a.material_override = mat_aura
		mi_a.rotation = rot_aura
		mi_a.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_magnet_aura.add_child(mi_a)


# ----------------------------------------------------------------------------
# Detalles 3D del rostro, pelo, sombreros, gafas, torso y extremidades
# ----------------------------------------------------------------------------

func _construir_nariz_3d(head: Node3D, forma_nariz: String, jaw_w: float, mat_piel_sin_borde: Material) -> void:
	var z_frente: float = -22.8 * jaw_w * ESC
	var y_nariz: float = -7.8 * ESC
	var scl := Vector3(0.75, 1.15, 0.95)
	var radio: float = 3.0 * ESC
	match forma_nariz:
		"respingona":
			y_nariz = -7.2 * ESC
			scl = Vector3(0.78, 1.0, 1.10)
		"recta":
			scl = Vector3(0.68, 1.35, 1.02)
		"ancha":
			scl = Vector3(1.10, 0.95, 0.90)
		"fina":
			scl = Vector3(0.56, 1.22, 0.92)
	_sphere(head, radio, Vector3(0.0, y_nariz, z_frente), mat_piel_sin_borde, scl, false, 12, 8)


func _construir_orejas_y_pendientes_3d(head: Node3D, jaw_w: float, pendientes: String,
		mat_piel: Material, mat_piel_sombra: Material) -> void:
	var ear_x: float = 29.4 * jaw_w * ESC
	var ear_y: float = -2.5 * ESC
	var mat_oro := _mat(Color("#f59e0b"), 0.35, 0.65)
	var mat_plata := _mat(Color("#cbd5e1"), 0.35, 0.68)
	var mat_perla := _mat(Color("#f8fafc"), 0.30, 0.10)

	for lado: float in [-1.0, 1.0]:
		var pos_o := Vector3(lado * ear_x, ear_y, -2.0 * ESC)
		_sphere(head, 5.8 * ESC, pos_o, mat_piel, Vector3(0.68, 1.25, 0.65), false, 14, 10)
		_sphere(head, 3.2 * ESC, pos_o + Vector3(lado * 0.4 * ESC, 0.0, -1.6 * ESC), mat_piel_sombra, Vector3(0.52, 1.05, 0.48), false, 10, 8)

		if pendientes != "ninguno":
			var pos_p := pos_o + Vector3(lado * 0.8 * ESC, -7.6 * ESC, -0.5 * ESC)
			match pendientes:
				"aros":
					var mi := MeshInstance3D.new()
					var toro := TorusMesh.new()
					toro.inner_radius = 2.4 * ESC
					toro.outer_radius = 3.8 * ESC
					toro.rings = 14
					toro.ring_segments = 8
					mi.mesh = toro
					mi.material_override = mat_oro
					mi.position = pos_p + Vector3(0.0, -3.2 * ESC, 0.0)
					mi.rotation = Vector3(PI * 0.5, 0.2 * lado, 0.0)
					head.add_child(mi)
				"perlas":
					_sphere(head, 2.7 * ESC, pos_p, mat_perla, Vector3.ONE, false, 12, 8)
				"cruz":
					_sphere(head, 1.6 * ESC, pos_p, mat_oro, Vector3.ONE, false, 10, 6)
					_box(head, Vector3(1.5 * ESC, 7.2 * ESC, 1.5 * ESC), pos_p + Vector3(0.0, -4.2 * ESC, 0.0), mat_plata, Vector3.ZERO, false)
					_box(head, Vector3(4.6 * ESC, 1.5 * ESC, 1.5 * ESC), pos_p + Vector3(0.0, -3.2 * ESC, 0.0), mat_plata, Vector3.ZERO, false)


func _construir_vello_facial_3d(head: Node3D, tipo: String, jaw_w: float, mat_pelo_relieve: Material) -> void:
	var z_f: float = -22.2 * jaw_w * ESC
	match tipo:
		"bigote":
			var pts_b: Array[Vector3] = [
				Vector3(-12.0 * ESC, -16.0 * ESC, z_f + 2.0 * ESC),
				Vector3(-5.5 * ESC, -13.4 * ESC, z_f - 1.0 * ESC),
				Vector3(0.0, -14.2 * ESC, z_f - 1.2 * ESC),
				Vector3(5.5 * ESC, -13.4 * ESC, z_f - 1.0 * ESC),
				Vector3(12.0 * ESC, -16.0 * ESC, z_f + 2.0 * ESC),
			]
			_inst_malla(head, _crear_malla_mechon_3d(pts_b, 2.4 * ESC, 1.1, 8, 3), mat_pelo_relieve, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, false)
		"perilla", "candado":
			_sphere(head, 5.8 * ESC, Vector3(0.0, -31.5 * ESC, z_f + 2.5 * ESC), mat_pelo_relieve, Vector3(1.12, 1.02, 0.72), false, 12, 8)
		"barba_completa":
			var pts_bf: Array[Vector3] = [
				Vector3(-24.5 * jaw_w * ESC, -12.0 * ESC, -8.0 * ESC),
				Vector3(-15.5 * jaw_w * ESC, -32.0 * ESC, z_f + 3.0 * ESC),
				Vector3(0.0, -38.5 * ESC, z_f + 1.2 * ESC),
				Vector3(15.5 * jaw_w * ESC, -32.0 * ESC, z_f + 3.0 * ESC),
				Vector3(24.5 * jaw_w * ESC, -12.0 * ESC, -8.0 * ESC),
			]
			_inst_malla(head, _crear_malla_mechon_3d(pts_bf, 6.8 * ESC, 1.15, 10, 3), mat_pelo_relieve, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, false)


func _construir_gafas_3d(head: Node3D, tipo: String, jaw_w: float) -> void:
	# El frontal de las gafas (montura, cristales y brillo diagonal cómic) se dibuja con
	# precisión 2D en Texturas_Personaje_3D._dibujar_gafas_2d; aquí añadimos las patillas 3D laterales.
	var col_montura := Color("#1e293b")
	if tipo == "aviador":
		col_montura = Color("#b45309")
	elif tipo == "cateye":
		col_montura = Color("#7f1d1d")
	var mat_marco := _mat(col_montura, 0.45, 0.30, Color.BLACK, 0.0, false)
	var z_g: float = -19.5 * jaw_w * ESC
	var y_g: float = 1.5 * ESC
	for lado: float in [-1.0, 1.0]:
		_box(head, Vector3(1.6 * ESC, 2.0 * ESC, 20.0 * ESC),
			Vector3(lado * (25.5 * jaw_w * ESC), y_g, z_g + 9.5 * ESC),
			mat_marco, Vector3(0.0, lado * -0.10, 0.0), false)


func _construir_pelo_3d(head: Node3D, sway: Node3D, es_mujer: bool, forma_cara: String,
		jaw_w: float, estilo: String, mat_pelo: Material, mat_pelo_relieve: Material, mat_pelo_osc: Material) -> void:
	if estilo == "calvo":
		return

	if estilo == "rapado":
		var cap_rap := _crear_malla_casquete_pelo(es_mujer, forma_cara, jaw_w, -25.0, 18.0, 1.025, -38.5, 0.0)
		_inst_malla(head, cap_rap, mat_pelo)
		return

	if estilo == "degradado":
		var cap_fade := _crear_malla_casquete_pelo(es_mujer, forma_cara, jaw_w, -25.5, 22.0, 1.03, -38.5, 0.0)
		_inst_malla(head, cap_fade, mat_pelo_osc)
		var sil_deg := PackedVector2Array([
			Vector2(-24.5, -24.5), Vector2(-23.0, -35.5), Vector2(-13.5, -42.5),
			Vector2(0.0, -45.0), Vector2(13.5, -42.5), Vector2(23.0, -35.5),
			Vector2(24.5, -24.5), Vector2(18.0, 4.0), Vector2(0.0, 12.0), Vector2(-18.0, 4.0),
		])
		_inst_malla(head, _crear_malla_peinado_silueta_3d(sil_deg, jaw_w, -24.5, 27.0, 28.0), mat_pelo)
		return

	# Casquete interior de respaldo (con contorno en la nuca) para cubrir el cráneo al 100%
	var cap_interno := _crear_malla_casquete_pelo(es_mujer, forma_cara, jaw_w, -27.5, 29.0, 1.075, -40.5, 0.0)
	_inst_malla(head, cap_interno, mat_pelo)

	match estilo:
		"alborotado":
			# Silueta 2D->3D exacta de Personaje_Visual.gd (líneas 2576-2585)
			var sil_alb := PackedVector2Array([
				Vector2(-30.0, -2.0), Vector2(-33.5, -13.0), Vector2(-30.5, -18.0),
				Vector2(-35.0, -23.0), Vector2(-29.5, -26.0), Vector2(-33.0, -34.5),
				Vector2(-25.5, -34.5), Vector2(-22.5, -42.5), Vector2(-15.0, -38.5),
				Vector2(-6.5, -47.5), Vector2(-1.5, -41.0), Vector2(5.5, -50.5),
				Vector2(11.5, -41.5), Vector2(21.5, -47.0), Vector2(22.5, -39.0),
				Vector2(30.0, -40.5), Vector2(28.0, -33.5), Vector2(34.5, -34.0),
				Vector2(30.5, -27.0), Vector2(36.5, -26.0), Vector2(31.5, -18.0),
				Vector2(33.5, -11.5), Vector2(30.0, -2.0),
				Vector2(29.2, 9.0), Vector2(25.2, 21.0), Vector2(14.0, 28.0),
				Vector2(0.0, 29.5), Vector2(-14.0, 28.0), Vector2(-25.2, 21.0), Vector2(-29.2, 9.0),
			])
			_inst_malla(head, _crear_malla_peinado_silueta_3d(sil_alb, jaw_w, -26.0, 27.5, 30.5), mat_pelo)

		"tupe":
			var sil_tupe := PackedVector2Array([
				Vector2(-29.5, -2.0), Vector2(-32.0, -14.0), Vector2(-32.5, -26.0),
				Vector2(-29.5, -35.5), Vector2(-20.0, -43.5), Vector2(-6.0, -49.5),
				Vector2(9.0, -52.5), Vector2(23.5, -49.5), Vector2(32.0, -42.5),
				Vector2(28.0, -34.5), Vector2(32.5, -27.0), Vector2(32.0, -14.0),
				Vector2(29.5, -2.0),
				Vector2(29.2, 9.0), Vector2(25.2, 21.0), Vector2(14.0, 28.0),
				Vector2(0.0, 29.5), Vector2(-14.0, 28.0), Vector2(-25.2, 21.0), Vector2(-29.2, 9.0),
			])
			_inst_malla(head, _crear_malla_peinado_silueta_3d(sil_tupe, jaw_w, -25.5, 28.5, 30.0), mat_pelo)

		"corto":
			var sil_corto := PackedVector2Array([
				Vector2(-29.5, -2.5), Vector2(-31.5, -14.0), Vector2(-31.5, -26.5),
				Vector2(-26.5, -35.5), Vector2(-15.0, -41.0), Vector2(0.0, -42.5),
				Vector2(15.0, -41.0), Vector2(26.5, -35.5), Vector2(31.5, -26.5),
				Vector2(31.5, -14.0), Vector2(29.5, -2.5),
				Vector2(29.2, 9.0), Vector2(25.2, 21.0), Vector2(14.0, 28.0),
				Vector2(0.0, 29.5), Vector2(-14.0, 28.0), Vector2(-25.2, 21.0), Vector2(-29.2, 9.0),
			])
			_inst_malla(head, _crear_malla_peinado_silueta_3d(sil_corto, jaw_w, -26.0, 27.0, 29.5), mat_pelo)

		"raya_lado":
			var sil_rl := PackedVector2Array([
				Vector2(-29.5, -2.0), Vector2(-32.0, -14.0), Vector2(-32.0, -27.0),
				Vector2(-26.0, -37.0), Vector2(-14.0, -42.5), Vector2(1.0, -44.5),
				Vector2(16.0, -43.5), Vector2(27.5, -38.0), Vector2(33.0, -28.0),
				Vector2(32.5, -14.0), Vector2(29.5, -2.0),
				Vector2(29.2, 9.0), Vector2(25.2, 21.0), Vector2(14.0, 28.0),
				Vector2(0.0, 29.5), Vector2(-14.0, 28.0), Vector2(-25.2, 21.0), Vector2(-29.2, 9.0),
			])
			_inst_malla(head, _crear_malla_peinado_silueta_3d(sil_rl, jaw_w, -26.0, 27.5, 29.8), mat_pelo)

		"rizado":
			var sil_riz := PackedVector2Array([
				Vector2(-31.0, -2.0), Vector2(-36.5, -9.0), Vector2(-33.5, -16.0),
				Vector2(-38.0, -23.0), Vector2(-34.0, -30.0), Vector2(-36.5, -37.5),
				Vector2(-28.5, -40.5), Vector2(-24.0, -47.5), Vector2(-15.5, -45.0),
				Vector2(-8.0, -50.5), Vector2(0.0, -46.5), Vector2(8.0, -50.5),
				Vector2(15.5, -45.0), Vector2(24.0, -47.5), Vector2(28.5, -40.5),
				Vector2(36.5, -37.5), Vector2(34.0, -30.0), Vector2(38.0, -23.0),
				Vector2(33.5, -16.0), Vector2(36.5, -9.0), Vector2(31.0, -2.0),
				Vector2(29.8, 9.0), Vector2(25.8, 21.5), Vector2(14.0, 28.5),
				Vector2(0.0, 29.8), Vector2(-14.0, 28.5), Vector2(-25.8, 21.5), Vector2(-29.8, 9.0),
			])
			_inst_malla(head, _crear_malla_peinado_silueta_3d(sil_riz, jaw_w, -26.0, 28.5, 31.5), mat_pelo)

		"afro":
			var sil_afro := PackedVector2Array([
				Vector2(-32.0, 2.0), Vector2(-41.0, -5.0), Vector2(-44.5, -16.0),
				Vector2(-45.5, -28.0), Vector2(-42.0, -39.5), Vector2(-34.0, -48.5),
				Vector2(-22.5, -54.5), Vector2(-11.0, -57.5), Vector2(0.0, -58.5),
				Vector2(11.0, -57.5), Vector2(22.5, -54.5), Vector2(34.0, -48.5),
				Vector2(42.0, -39.5), Vector2(45.5, -28.0), Vector2(44.5, -16.0),
				Vector2(41.0, -5.0), Vector2(32.0, 2.0),
				Vector2(30.0, 14.0), Vector2(23.0, 24.5), Vector2(12.0, 30.0),
				Vector2(0.0, 31.0), Vector2(-12.0, 30.0), Vector2(-23.0, 24.5), Vector2(-30.0, 14.0),
			])
			_inst_malla(head, _crear_malla_peinado_silueta_3d(sil_afro, jaw_w, -26.0, 34.0, 38.0), mat_pelo)

		"largo", "ondulado", "media_melena", "bob", "coleta", "dos_coletas", "mono":
			var cap_base := _crear_malla_casquete_pelo(es_mujer, forma_cara, jaw_w, -26.5, 28.5, 1.075, -41.5, 0.0)
			_inst_malla(head, cap_base, mat_pelo)

	match estilo:
		"largo", "ondulado":
			var es_ond: bool = (estilo == "ondulado")
			for lado: float in [-1.0, 1.0]:
				var m_front: Array[Vector3] = [
					Vector3(lado * 23.5 * jaw_w * ESC, 20.0 * ESC, -10.0 * ESC),
					Vector3(lado * (31.5 + (2.5 if es_ond else 0.0)) * jaw_w * ESC, 2.0 * ESC, -7.0 * ESC),
					Vector3(lado * (29.0 - (2.0 if es_ond else 0.0)) * jaw_w * ESC, -15.0 * ESC, -6.5 * ESC),
					Vector3(lado * 30.5 * jaw_w * ESC, -27.0 * ESC, -5.0 * ESC),
				]
				_inst_malla(head, _crear_malla_mechon_3d(m_front, 8.0 * ESC, 1.15, 10, 4), mat_pelo)

			for idx_m in range(-2, 3):
				var fx: float = float(idx_m) * 11.0 * jaw_w * ESC
				var onda_x: float = (sin(float(idx_m) * 1.4) * 3.2 * ESC) if es_ond else 0.0
				var m_back: Array[Vector3] = [
					Vector3(fx * 0.75, 14.0 * ESC, -2.0 * ESC),
					Vector3(fx + onda_x, -12.0 * ESC, 6.0 * ESC),
					Vector3(fx * 1.05 - onda_x, -44.0 * ESC, 8.0 * ESC),
					Vector3(fx * 0.92 + onda_x, -75.0 * ESC, 5.5 * ESC),
					Vector3(fx * 0.72, -95.0 * ESC, 3.0 * ESC),
				]
				var mat_m: Material = mat_pelo if abs(idx_m) == 2 else mat_pelo_relieve
				_inst_malla(sway, _crear_malla_mechon_3d(m_back, 13.5 * ESC, 1.35, 10, 4), mat_m)

		"media_melena":
			for lado: float in [-1.0, 1.0]:
				var m_front: Array[Vector3] = [
					Vector3(lado * 23.5 * jaw_w * ESC, 20.0 * ESC, -10.0 * ESC),
					Vector3(lado * 31.0 * jaw_w * ESC, 1.0 * ESC, -6.5 * ESC),
					Vector3(lado * 28.5 * jaw_w * ESC, -23.0 * ESC, -5.0 * ESC),
				]
				_inst_malla(head, _crear_malla_mechon_3d(m_front, 7.8 * ESC, 1.15, 10, 3), mat_pelo)
			for idx_m in range(-2, 3):
				var fx: float = float(idx_m) * 10.5 * jaw_w * ESC
				var m_back: Array[Vector3] = [
					Vector3(fx * 0.75, 12.0 * ESC, -2.0 * ESC),
					Vector3(fx, -18.0 * ESC, 5.5 * ESC),
					Vector3(fx * 0.92, -48.0 * ESC, 5.0 * ESC),
					Vector3(fx * 0.75, -62.0 * ESC, 2.5 * ESC),
				]
				var mat_m: Material = mat_pelo if abs(idx_m) == 2 else mat_pelo_relieve
				_inst_malla(sway, _crear_malla_mechon_3d(m_back, 13.0 * ESC, 1.35, 10, 3), mat_m)

		"bob":
			for lado: float in [-1.0, 1.0]:
				var m_bob: Array[Vector3] = [
					Vector3(lado * 24.0 * jaw_w * ESC, 18.0 * ESC, -8.0 * ESC),
					Vector3(lado * 32.5 * jaw_w * ESC, -2.0 * ESC, -3.5 * ESC),
					Vector3(lado * 26.0 * jaw_w * ESC, -22.0 * ESC, -4.5 * ESC),
				]
				_inst_malla(head, _crear_malla_mechon_3d(m_bob, 9.2 * ESC, 1.2, 10, 3), mat_pelo)
			for idx_m in range(-1, 2):
				var fx: float = float(idx_m) * 13.5 * jaw_w * ESC
				var b_bob: Array[Vector3] = [
					Vector3(fx * 0.8, 12.0 * ESC, -1.0 * ESC),
					Vector3(fx, -16.0 * ESC, 4.5 * ESC),
					Vector3(fx * 0.85, -42.0 * ESC, 2.0 * ESC),
				]
				_inst_malla(sway, _crear_malla_mechon_3d(b_bob, 13.5 * ESC, 1.35, 10, 3), mat_pelo)

		"coleta":
			var mat_goma_roja := _mat(Color("#ef4444"), 0.65, 0.02)
			_sphere(sway, 6.8 * ESC, Vector3(0.0, 6.0 * ESC, 3.0 * ESC), mat_goma_roja, Vector3(1.15, 0.95, 0.95), false, 12, 8)
			var pts_cola: Array[Vector3] = [
				Vector3(0.0, 6.0 * ESC, 4.0 * ESC),
				Vector3(0.0, 15.0 * ESC, 18.0 * ESC),
				Vector3(0.0, -4.0 * ESC, 31.0 * ESC),
				Vector3(0.0, -34.0 * ESC, 29.0 * ESC),
				Vector3(0.0, -56.0 * ESC, 22.0 * ESC),
			]
			_inst_malla(sway, _crear_malla_mechon_3d(pts_cola, 13.5 * ESC, 1.15, 12, 4), mat_pelo)

		"dos_coletas":
			var mat_goma_rosa := _mat(Color("#f43f5e"), 0.65, 0.02)
			for lado: float in [-1.0, 1.0]:
				var raiz_c := Vector3(lado * 25.0 * jaw_w * ESC, 4.0 * ESC, -4.0 * ESC)
				_sphere(sway, 5.8 * ESC, raiz_c, mat_goma_rosa, Vector3.ONE, false, 12, 8)
				var pts_c2: Array[Vector3] = [
					raiz_c,
					raiz_c + Vector3(lado * 12.0 * ESC, 6.0 * ESC, 8.0 * ESC),
					raiz_c + Vector3(lado * 18.0 * ESC, -16.0 * ESC, 12.0 * ESC),
					raiz_c + Vector3(lado * 14.0 * ESC, -44.0 * ESC, 10.0 * ESC),
					raiz_c + Vector3(lado * 9.0 * ESC, -62.0 * ESC, 6.0 * ESC),
				]
				_inst_malla(sway, _crear_malla_mechon_3d(pts_c2, 11.0 * ESC, 1.1, 10, 4), mat_pelo)

		"mono":
			var mat_goma_roja := _mat(Color("#ef4444"), 0.65, 0.02)
			_cyl(head, 11.5 * ESC, 11.5 * ESC, 5.2 * ESC, Vector3(0.0, 36.5 * ESC, 4.0 * ESC), mat_goma_roja)
			_sphere(head, 16.0 * ESC, Vector3(0.0, 47.0 * ESC, 5.0 * ESC), mat_pelo, Vector3(1.04, 0.88, 1.04), true, 16, 12)


func _construir_gorro_chef_3d(head: Node3D, jaw_w: float, mat_blanco: Material) -> void:
	_cyl(head, 27.0 * jaw_w * ESC, 25.0 * jaw_w * ESC, 26.0 * ESC, Vector3(0.0, 38.0 * ESC, 0.0), mat_blanco)
	_sphere(head, 29.5 * jaw_w * ESC, Vector3(0.0, 52.0 * ESC, 0.0), mat_blanco, Vector3(1.06, 0.68, 1.06), true, 18, 12)


func _construir_sombrero_3d(head: Node3D, sombrero: String, jaw_w: float, col_ropa: Color) -> void:
	var mat_s := _mat(col_ropa.darkened(0.08), 0.78)
	var mat_s_dark := _mat(col_ropa.darkened(0.26), 0.82)
	match sombrero:
		"gorra":
			_sphere(head, 30.0 * jaw_w * ESC, Vector3(0.0, 22.0 * ESC, 1.0 * ESC), mat_s, Vector3(1.02, 0.88, 1.05), true, 18, 12)
			_sphere(head, 3.0 * ESC, Vector3(0.0, 48.5 * ESC, 1.0 * ESC), mat_s_dark, Vector3.ONE, false, 10, 6)
			var pts_vis: Array[Vector3] = [
				Vector3(-24.0 * jaw_w * ESC, 19.5 * ESC, -18.0 * ESC),
				Vector3(0.0, 18.5 * ESC, -36.0 * ESC),
				Vector3(24.0 * jaw_w * ESC, 19.5 * ESC, -18.0 * ESC),
			]
			_inst_malla(head, _crear_malla_mechon_3d(pts_vis, 11.0 * ESC, 0.35, 10, 3), mat_s_dark)
		"gorro":
			_sphere(head, 31.0 * jaw_w * ESC, Vector3(0.0, 24.0 * ESC, 1.0 * ESC), mat_s, Vector3(1.02, 0.94, 1.04), true, 18, 12)
			_cyl(head, 31.8 * jaw_w * ESC, 31.2 * jaw_w * ESC, 10.5 * ESC, Vector3(0.0, 20.0 * ESC, 1.0 * ESC), mat_s_dark)
			_sphere(head, 7.2 * ESC, Vector3(0.0, 54.0 * ESC, 1.0 * ESC), mat_s_dark, Vector3.ONE, true, 12, 8)
		"boina":
			_sphere(head, 33.5 * jaw_w * ESC, Vector3(-4.0 * ESC, 34.0 * ESC, 1.0 * ESC), mat_s, Vector3(1.08, 0.44, 1.06), true, 18, 12)
			_cyl(head, 1.4 * ESC, 1.4 * ESC, 6.0 * ESC, Vector3(-2.0 * ESC, 49.0 * ESC, 1.0 * ESC), _mat(TINTA, 0.5, 0.0, Color.BLACK, 0.0, false))
		"diadema":
			var mi := MeshInstance3D.new()
			var toro := TorusMesh.new()
			toro.inner_radius = 27.5 * jaw_w * ESC
			toro.outer_radius = 32.0 * jaw_w * ESC
			toro.rings = 20
			toro.ring_segments = 10
			mi.mesh = toro
			mi.material_override = _mat(col_ropa.lightened(0.15), 0.72)
			mi.position = Vector3(0.0, 15.0 * ESC, -1.0 * ESC)
			mi.rotation = Vector3(0.28, 0.0, 0.0)
			head.add_child(mi)


func _construir_accesorios_torso_3d(torso: Node3D, es_mujer: bool, met: Dictionary, ap: Dictionary,
		ropa_sup: String, ropa_inf: String, estilo_ropa: String, detalle_ropa: String,
		mat_piel: Material, mat_ropa: Material, mat_ropa_sombra: Material, mat_ropa_sec: Material,
		mat_ropa_det: Material, mat_pant: Material, mat_blanco: Material, mat_cian: Material) -> void:
	var sh_x: float = float(met["sh_x"])
	var waist_x: float = float(met["waist_x"])
	var hip_x: float = float(met["hip_x"])
	var nw: float = float(met["nw"])

	# 0. Puente pélvico 3D entre torso y piernas para que nunca haya hueco al correr
	var es_falda: bool = (ropa_inf == "falda") or (estilo_ropa == "vestido")
	var mat_pelvis: Material = mat_piel if es_falda else mat_pant
	_sphere(torso, hip_x * 0.84 * ESC, Vector3(0.0, -2.5 * ESC, 0.0), mat_pelvis, Vector3(1.0, 0.48, 0.76), true, 16, 10)

	# 1. Capucha 3D acolchada sobre la parte alta de la espalda (sudadera / chándal deportivo)
	if ropa_sup == "sudadera" or estilo_ropa == "deportivo":
		_sphere(torso, 18.0 * ESC, Vector3(0.0, (124.0 - 52.5) * ESC, 12.0 * ESC),
			mat_ropa_sombra, Vector3(1.12, 0.56, 0.65), true, 16, 10)

	# 2. Bufanda 3D con colas para invierno
	if estilo_ropa == "invierno":
		var mat_buf: Material = mat_ropa_det if detalle_ropa == "abrigo" else mat_ropa_sec
		var mi_b := MeshInstance3D.new()
		var toro_b := TorusMesh.new()
		toro_b.inner_radius = (nw + 1.0) * ESC
		toro_b.outer_radius = (nw + 8.5) * ESC
		toro_b.rings = 18
		toro_b.ring_segments = 10
		mi_b.mesh = toro_b
		mi_b.material_override = mat_buf
		mi_b.position = Vector3(0.0, (124.0 - 47.0) * ESC, 0.0)
		torso.add_child(mi_b)
		var cola_b: Array[Vector3] = [
			Vector3(8.0 * ESC, (124.0 - 49.0) * ESC, 14.0 * ESC),
			Vector3(12.0 * ESC, (124.0 - 66.0) * ESC, 18.0 * ESC),
			Vector3(14.0 * ESC, (124.0 - 84.0) * ESC, 17.5 * ESC),
		]
		_inst_malla(torso, _crear_malla_mechon_3d(cola_b, 5.5 * ESC, 1.3, 8, 3), mat_buf)

	# 3. Faldón largo 3D para Bata de laboratorio o Abrigo de invierno
	if estilo_ropa == "bata" or (estilo_ropa == "invierno" and detalle_ropa == "abrigo"):
		var y_fin_2d: float = 166.0 if estilo_ropa == "bata" else 156.0
		var h_faldon: float = (y_fin_2d - 118.0) * ESC
		var y_centro: float = (124.0 - (118.0 + y_fin_2d) * 0.5) * ESC
		_cyl(torso, (hip_x + 2.0) * ESC, (hip_x + 5.5) * ESC, h_faldon, Vector3(0.0, y_centro, 0.0), mat_ropa_sec)

	# 4. Hombreras doradas 3D para Chef de Gala
	if estilo_ropa == "gala":
		for lado: float in [-1.0, 1.0]:
			_sphere(torso, 5.5 * ESC, Vector3(lado * (sh_x - 3.5) * ESC, (124.0 - 53.5) * ESC, 0.0),
				mat_ropa_det, Vector3(1.2, 0.45, 0.85))

	# 5. Mochila espacial 3D para Traje de Astronauta
	if estilo_ropa == "astronauta":
		var z_moch: float = (20.0 if not es_mujer else 19.0) * ESC
		var y_moch: float = (124.0 - 82.0) * ESC
		_box(torso, Vector3(36.0 * ESC, 48.0 * ESC, 18.0 * ESC), Vector3(0.0, y_moch, z_moch), mat_blanco)
		for lado: float in [-1.0, 1.0]:
			_cyl(torso, 6.5 * ESC, 6.5 * ESC, 50.0 * ESC, Vector3(lado * 12.0 * ESC, y_moch, z_moch + 4.0 * ESC), mat_blanco)
		_box(torso, Vector3(24.0 * ESC, 6.0 * ESC, 3.0 * ESC), Vector3(0.0, y_moch + 12.0 * ESC, z_moch + 9.5 * ESC), mat_cian, Vector3.ZERO, false)
		_box(torso, Vector3(24.0 * ESC, 4.5 * ESC, 3.0 * ESC), Vector3(0.0, y_moch - 10.0 * ESC, z_moch + 9.5 * ESC), mat_ropa_sec, Vector3.ZERO, false)

	# 6. Falda 3D acampanada o Vestido con textura 2D->3D de pliegues, flores o lentejuelas
	if es_falda:
		var es_largo: bool = (estilo_ropa == "vestido" and detalle_ropa == "largo")
		var y_top_f: float = 99.0 if estilo_ropa == "vestido" else 120.0
		var y_bot_f: float = 198.0 if es_largo else 164.0
		var r_top_f: float = (waist_x + 1.5) * ESC if estilo_ropa == "vestido" else (hip_x + 1.0) * ESC
		var r_bot_f: float = hip_x * (1.52 if es_largo else 1.34) * ESC
		var perfiles_f: Array[Vector2] = [
			Vector2((124.0 - y_top_f) * ESC, r_top_f),
			Vector2((124.0 - lerpf(y_top_f, y_bot_f, 0.35)) * ESC, lerpf(r_top_f, r_bot_f, 0.40)),
			Vector2((124.0 - lerpf(y_top_f, y_bot_f, 0.70)) * ESC, lerpf(r_top_f, r_bot_f, 0.76)),
			Vector2((124.0 - y_bot_f) * ESC, r_bot_f),
			Vector2((124.0 - y_bot_f - 1.2) * ESC, 0.0),
		]
		var tex_falda: ImageTexture = Tex3D.generar_textura_falda(ap)
		var mat_falda_tex := _mat_textura(tex_falda, 0.90, true, 0.010)
		var malla_f := _crear_malla_revolucion(perfiles_f, 24, Vector2(1.0, 0.80), true)
		_inst_malla(torso, malla_f, mat_falda_tex)


func _construir_brazo_articulado(lado: float, sh_x: float, arm_scale: float, ropa_sup: String,
		estilo_ropa: String, detalle_ropa: String, mat_ropa: Material, mat_piel: Material,
		mat_piel_sin_borde: Material, mat_sec: Material, col_ropa: Color) -> Dictionary:
	var arm_sh_x: float = (sh_x - 1.8) * ESC
	var sh_y_desde_cadera: float = (124.0 - 57.5) * ESC

	var piv_arm := Node3D.new()
	piv_arm.name = "LeftArm" if lado < 0.0 else "RightArm"
	piv_arm.position = Vector3(lado * arm_sh_x, sh_y_desde_cadera, 0.0)
	_torso.add_child(piv_arm)

	var l_up: float = 31.0 * ESC
	var l_fore: float = 30.0 * ESC
	var r_sh: float = 9.2 * arm_scale * ESC
	var r_el: float = 8.2 * arm_scale * ESC
	var r_wr: float = 6.9 * arm_scale * ESC

	var sin_manga: bool = (ropa_sup == "top")
	var manga_corta: bool = (not sin_manga) and (ropa_sup == "camiseta")
	var manga_remangada: bool = (not sin_manga) and (ropa_sup == "camisa")

	# 1. Brazo superior (hombro -> codo)
	if sin_manga:
		_inst_malla(piv_arm, _crear_malla_extremidad(0.0, -l_up, r_sh * 0.92, r_el * 0.90), mat_piel)
	elif manga_corta:
		var y_corte: float = -l_up * 0.72
		_inst_malla(piv_arm, _crear_malla_extremidad(0.0, y_corte, r_sh, r_el * 1.02), mat_ropa)
		_inst_malla(piv_arm, _crear_malla_extremidad(y_corte, -l_up, r_el * 0.90, r_el * 0.88), mat_piel)
	else:
		_inst_malla(piv_arm, _crear_malla_extremidad(0.0, -l_up, r_sh, r_el), mat_ropa)
		if estilo_ropa == "deportivo":
			_box(piv_arm, Vector3(2.2 * ESC, l_up * 0.85, 3.8 * ESC), Vector3(lado * r_sh * 0.88, -l_up * 0.48, 0.0), mat_sec, Vector3.ZERO, false)
		elif estilo_ropa == "astronauta":
			_cyl(piv_arm, r_sh * 1.02, r_sh * 1.00, 4.5 * ESC, Vector3(0.0, -l_up * 0.36, 0.0), mat_sec)

	# 2. Pivote de codo y antebrazo (codo -> muñeca -> mano)
	var piv_fore := Node3D.new()
	piv_fore.name = "Forearm"
	piv_fore.position = Vector3(0.0, -l_up, 0.0)
	piv_arm.add_child(piv_fore)

	if sin_manga or manga_corta:
		_inst_malla(piv_fore, _crear_malla_extremidad(0.0, -l_fore, r_el * 0.88, r_wr * 0.86), mat_piel)
	elif manga_remangada:
		var y_rem: float = -l_fore * 0.38
		_inst_malla(piv_fore, _crear_malla_extremidad(0.0, y_rem, r_el * 0.98, r_el * 0.94), mat_ropa)
		var mat_doblez := _mat(col_ropa.lightened(0.14), 0.84)
		_cyl(piv_fore, r_el * 1.06, r_el * 1.04, 5.2 * ESC, Vector3(0.0, y_rem, 0.0), mat_doblez)
		_inst_malla(piv_fore, _crear_malla_extremidad(y_rem, -l_fore, r_el * 0.86, r_wr * 0.86), mat_piel)
	else:
		_inst_malla(piv_fore, _crear_malla_extremidad(0.0, -l_fore, r_el, r_wr), mat_ropa)
		var mat_puno := _mat(col_ropa.darkened(0.20), 0.86)
		_cyl(piv_fore, r_wr * 1.06, r_wr * 1.02, 5.0 * ESC, Vector3(0.0, -l_fore + 2.5 * ESC, 0.0), mat_puno)

	# 3. Mano esculpida 3D (palma redondeada + pulgar sin línea negra interna)
	var pos_mano := Vector3(0.0, -l_fore - 4.5 * ESC, 0.0)
	_sphere(piv_fore, 8.6 * arm_scale * ESC, pos_mano, mat_piel, Vector3(0.84, 1.05, 0.92), true, 14, 10)
	_sphere(piv_fore, 3.5 * arm_scale * ESC, pos_mano + Vector3(-lado * 5.6 * ESC, 1.2 * ESC, -3.4 * ESC), mat_piel_sin_borde, Vector3.ONE, false, 10, 8)

	return {"arm": piv_arm, "forearm": piv_fore}


func _construir_pierna_articulada(lado: float, hip_leg_x: float, leg_scale: float,
		ropa_inf: String, estilo_ropa: String, calzado: String,
		mat_pant: Material, mat_piel: Material, mat_calz: Material,
		mat_sec: Material, mat_det: Material, mat_glow: Material, col_calz: Color) -> Dictionary:
	var hip_y_3d: float = (219.5 - 124.0) * ESC
	var l_thigh: float = (165.0 - 124.0) * ESC
	var l_shin: float = (203.0 - 165.0) * ESC
	var h_foot: float = (219.5 - 203.0) * ESC

	var r_hip: float = 12.6 * leg_scale * ESC
	var r_knee: float = 10.2 * leg_scale * ESC
	var r_ankle: float = 8.2 * leg_scale * ESC

	var piv_hip := Node3D.new()
	piv_hip.name = "LeftLeg" if lado < 0.0 else "RightLeg"
	piv_hip.position = Vector3(lado * hip_leg_x * ESC, hip_y_3d, 0.0)
	_body_pivot.add_child(piv_hip)

	var es_falda: bool = (ropa_inf == "falda") or (estilo_ropa == "vestido")
	var es_shorts: bool = (ropa_inf == "shorts")
	var es_chandal: bool = (ropa_inf == "chandal") or (estilo_ropa == "deportivo")
	var es_gala_pant: bool = estilo_ropa in ["gala", "michelin"]

	# 1. Muslo (cadera -> rodilla)
	if es_falda:
		_inst_malla(piv_hip, _crear_malla_extremidad(0.0, -l_thigh, r_hip * 0.90, r_knee * 0.88), mat_piel)
	elif es_shorts:
		var y_sh: float = -l_thigh * 0.65
		_inst_malla(piv_hip, _crear_malla_extremidad(0.0, y_sh, r_hip, r_knee * 1.06), mat_pant)
		_inst_malla(piv_hip, _crear_malla_extremidad(y_sh, -l_thigh, r_knee * 0.92, r_knee * 0.88), mat_piel)
	else:
		_inst_malla(piv_hip, _crear_malla_extremidad(0.0, -l_thigh, r_hip, r_knee), mat_pant)
		if es_chandal or es_gala_pant or estilo_ropa == "pijama":
			var mat_raya: Material = mat_det if es_gala_pant else mat_sec
			_box(piv_hip, Vector3(2.2 * ESC, l_thigh * 0.92, 3.6 * ESC),
				Vector3(lado * r_hip * 0.86, -l_thigh * 0.50, 0.0), mat_raya, Vector3.ZERO, false)

	# 2. Pivote de rodilla y espinilla/pantorrilla (rodilla -> tobillo)
	var piv_knee := Node3D.new()
	piv_knee.name = "Shin"
	piv_knee.position = Vector3(0.0, -l_thigh, 0.0)
	piv_hip.add_child(piv_knee)

	if estilo_ropa == "futbol":
		var y_media: float = -l_shin * 0.16
		_inst_malla(piv_knee, _crear_malla_extremidad(0.0, y_media, r_knee * 0.88, r_knee * 0.86), mat_piel)
		_inst_malla(piv_knee, _crear_malla_extremidad(y_media, -l_shin, r_knee * 0.92, r_ankle * 0.88), mat_sec)
		_cyl(piv_knee, r_knee * 0.94, r_knee * 0.92, 4.0 * ESC, Vector3(0.0, -l_shin * 0.34, 0.0), mat_det)
	elif es_falda or es_shorts:
		_inst_malla(piv_knee, _crear_malla_extremidad(0.0, -l_shin, r_knee * 0.88, r_ankle * 0.82), mat_piel)
	else:
		_inst_malla(piv_knee, _crear_malla_extremidad(0.0, -l_shin, r_knee, r_ankle), mat_pant)
		if es_chandal or es_gala_pant or estilo_ropa == "pijama":
			var mat_raya2: Material = mat_det if es_gala_pant else mat_sec
			_box(piv_knee, Vector3(2.2 * ESC, l_shin * 0.88, 3.4 * ESC),
				Vector3(lado * r_knee * 0.86, -l_shin * 0.48, 0.0), mat_raya2, Vector3.ZERO, false)

	# 3. Pivote de tobillo y calzado 3D esculpido (fiel a Personaje_Visual._dibujar_calzado)
	var piv_foot := Node3D.new()
	piv_foot.name = "Foot"
	piv_foot.position = Vector3(0.0, -l_shin, 0.0)
	piv_knee.add_child(piv_foot)

	var mat_blanco := _mat(Tex3D.calibrar_color_3d(Color("#f8fafc"), 0.10), 0.82, 0.0)
	var mat_suela_osc := _mat(Color("#1e293b") if calzado == "botas" else col_calz.darkened(0.45), 0.86, 0.0)

	if calzado == "botas":
		var malla_bota := _crear_malla_zapato_base(22.0 * ESC, 19.0 * ESC, 11.8 * ESC)
		_inst_malla(piv_foot, malla_bota, mat_calz, Vector3(0.0, -h_foot + 4.5 * ESC, -3.5 * ESC))
		_cyl(piv_foot, 11.5 * ESC, 12.2 * ESC, 4.8 * ESC, Vector3(0.0, -h_foot + 2.4 * ESC, -3.5 * ESC), mat_suela_osc)
	elif calzado == "zapatos":
		var malla_zap := _crear_malla_zapato_base(13.5 * ESC, 18.8 * ESC, 11.2 * ESC)
		_inst_malla(piv_foot, malla_zap, mat_calz, Vector3(0.0, -h_foot + 3.8 * ESC, -3.5 * ESC))
		_cyl(piv_foot, 11.0 * ESC, 11.5 * ESC, 4.0 * ESC, Vector3(0.0, -h_foot + 2.0 * ESC, -3.5 * ESC), mat_suela_osc)
	else:
		# Zapatillas deportivas modernas con puntera blanca, entresuela blanca, suela oscura y cordones
		var malla_sneaker := _crear_malla_zapato_base(15.0 * ESC, 19.2 * ESC, 11.8 * ESC)
		_inst_malla(piv_foot, malla_sneaker, mat_calz, Vector3(0.0, -h_foot + 4.8 * ESC, -3.5 * ESC))
		_sphere(piv_foot, 9.0 * ESC, Vector3(0.0, -h_foot + 5.8 * ESC, -12.2 * ESC), mat_blanco, Vector3(1.06, 0.62, 0.90))
		var malla_suela := _crear_malla_zapato_base(5.2 * ESC, 20.2 * ESC, 12.5 * ESC)
		_inst_malla(piv_foot, malla_suela, mat_blanco, Vector3(0.0, -h_foot + 2.2 * ESC, -3.5 * ESC))
		var malla_taco := _crear_malla_zapato_base(2.4 * ESC, 19.5 * ESC, 11.8 * ESC)
		_inst_malla(piv_foot, malla_taco, mat_suela_osc, Vector3(0.0, -h_foot + 0.4 * ESC, -3.5 * ESC))
		for lz: float in [-7.5 * ESC, -10.5 * ESC]:
			_box(piv_foot, Vector3(9.2 * ESC, 1.8 * ESC, 1.8 * ESC), Vector3(0.0, -h_foot + 12.5 * ESC, lz), mat_blanco, Vector3.ZERO, false)

	var glow := _box(piv_foot, Vector3(0.28, 0.20, 0.42), Vector3(0.0, -h_foot * 0.5, -0.03), mat_glow, Vector3.ZERO, false)
	glow.visible = false

	return {"hip": piv_hip, "knee": piv_knee, "foot": piv_foot, "glow": glow}


func _obtener_edad_partida() -> int:
	var arbol := Engine.get_main_loop() as SceneTree
	if arbol != null and arbol.root != null:
		var est := arbol.root.get_node_or_null("Variables_Estaticas")
		if est != null and est.has_method("Calcular_Edad"):
			return int(est.call("Calcular_Edad"))
	return Envejecimiento_Personaje.EDAD_MIN


func _actualizar_textura_rostro_dinamica(estado_objetivo: String, tiempo: float) -> void:
	if _mat_rostro == null:
		return
	var estado_ef: String = estado_objetivo
	if estado_ef == "normal":
		var ciclo_p: float = fmod(tiempo + 1.2, 3.8)
		if ciclo_p > 3.64:
			estado_ef = "parpadeo"
	if estado_ef == _estado_rostro_activo:
		return
	_estado_rostro_activo = estado_ef
	match estado_ef:
		"parpadeo":
			_mat_rostro.albedo_texture = _tex_rostro_parpadeo
		"esfuerzo":
			_mat_rostro.albedo_texture = _tex_rostro_esfuerzo
		"choque":
			_mat_rostro.albedo_texture = _tex_rostro_choque
		_:
			_mat_rostro.albedo_texture = _tex_rostro_normal


# ----------------------------------------------------------------------------
# API general de poses 3D (para reutilizar el modelo 3D en otras escenas)
# ----------------------------------------------------------------------------

func establecer_pose(nueva_pose: String, nueva_expresion: String = "") -> void:
	pose_general = nueva_pose
	if nueva_expresion != "" and nueva_expresion != expresion_actual:
		expresion_actual = nueva_expresion
		if not apariencia_actual.is_empty():
			_tex_rostro_normal = Tex3D.generar_textura_rostro(apariencia_actual, edad_actual, expresion_actual, Vector2.ZERO, false)
			_tex_rostro_parpadeo = Tex3D.generar_textura_rostro(apariencia_actual, edad_actual, expresion_actual, Vector2.ZERO, true)
			if _mat_rostro != null:
				_estado_rostro_activo = ""
				_actualizar_textura_rostro_dinamica("normal", _tiempo_general)


func establecer_actividad(nombre_actividad: String) -> void:
	var p := Apariencia_Personaje.pose_para_actividad(nombre_actividad)
	if p == "idle" and nombre_actividad.to_lower().find("correr") >= 0:
		p = "correr"
	var expr := "feliz"
	match p:
		"correr", "futbol", "estudiar", "manualidades", "trabajar":
			expr = "concentrado"
		"dormir":
			expr = "dormido"
		"tv":
			expr = "sonrisa"
	establecer_pose(p, expr)


func actualizar_pose_general(tiempo: float, mirar_camara: bool = true) -> void:
	_tiempo_general = tiempo
	if _body_pivot == null:
		return
	var jugador_dummy := {
		"estado": "CORRIENDO" if pose_general in ["correr", "sprint"] else "IDLE",
		"x": position.x,
		"y": position.y,
		"suelo_y": position.y,
		"inclinacion_z": 0.0,
		"squash_x": 1.0,
		"squash_y": 1.0,
		"invulnerable": 0.0,
		"ciclo_carrera": tiempo * (13.8 if pose_general == "sprint" else 9.6),
		"anim_tropiezo": 0.0,
	}
	var powerups_dummy := {"tabla": 0.0, "zapatillas": 0.0, "iman": 0.0}
	actualizar_animacion(jugador_dummy, powerups_dummy, tiempo, mirar_camara and pose_general not in ["correr", "sprint"])


# ----------------------------------------------------------------------------
# Animación biomecánica en tiempo real (Menú 3/4 Frontal + Runner 3D)
# ----------------------------------------------------------------------------

func _resetear_articulaciones() -> void:
	_torso.rotation = Vector3.ZERO
	_head_group.rotation = Vector3.ZERO
	_hair_sway.rotation = Vector3.ZERO
	_left_arm.rotation = Vector3.ZERO
	_left_forearm.rotation = Vector3.ZERO
	_right_arm.rotation = Vector3.ZERO
	_right_forearm.rotation = Vector3.ZERO
	_left_leg.rotation = Vector3.ZERO
	_left_shin.rotation = Vector3.ZERO
	_left_foot.rotation = Vector3.ZERO
	_right_leg.rotation = Vector3.ZERO
	_right_shin.rotation = Vector3.ZERO
	_right_foot.rotation = Vector3.ZERO


func actualizar_animacion(jugador: Dictionary, powerups: Dictionary, tiempo: float, modo_titulo: bool) -> void:
	if _body_pivot == null:
		return

	_tiempo_general = tiempo
	var estado: String = str(jugador.get("estado", "CORRIENDO"))
	var x: float = float(jugador.get("x", 0.0))
	var y: float = float(jugador.get("y", 0.0))
	var suelo_y: float = float(jugador.get("suelo_y", 0.0))
	var inclinacion_z: float = float(jugador.get("inclinacion_z", 0.0))
	var squash_x: float = float(jugador.get("squash_x", 1.0))
	var squash_y: float = float(jugador.get("squash_y", 1.0))
	var invuln: float = float(jugador.get("invulnerable", 0.0))
	var ciclo: float = float(jugador.get("ciclo_carrera", 0.0))
	var anim_tropiezo: float = float(jugador.get("anim_tropiezo", 0.0))

	var volando: bool = estado == "VOLANDO" or float(powerups.get("jetpack", 0.0)) > 0.0
	var en_pogo: bool = estado == "POGO" or float(powerups.get("pogo", 0.0)) > 0.0
	var surfeando: bool = float(powerups.get("tabla", 0.0)) > 0.0 and estado != "CHOCADO" and estado != "CAIDO" and not volando and not en_pogo
	var super_zap: bool = float(powerups.get("zapatillas", 0.0)) > 0.0
	var iman_on: bool = float(powerups.get("iman", 0.0)) > 0.0

	_hoverboard.visible = surfeando
	_jetpack.visible = volando
	_pogo.visible = en_pogo
	_sneaker_glow_l.visible = super_zap
	_sneaker_glow_r.visible = super_zap
	_magnet_aura.visible = iman_on
	if iman_on:
		_magnet_aura.rotation = Vector3(tiempo * 1.1, tiempo * 2.6, 0.0)
	if volando:
		for i in range(_jetpack_llamas.size()):
			var llama: Node3D = _jetpack_llamas[i]
			var pulso: float = 0.82 + sin(tiempo * 24.0 + float(i) * 1.7) * 0.20
			llama.scale = Vector3(0.85 + pulso * 0.25, pulso * 1.45, 0.85 + pulso * 0.25)
			llama.rotation.z = sin(tiempo * 18.0 + float(i)) * 0.10

	position = Vector3(x, y, Runner_Simulacion.JUGADOR_Z)

	# Sombra pegada al suelo de soporte bajo los pies
	var altura_sobre_suelo: float = maxf(0.0, y - suelo_y)
	_shadow_disc.position.y = -altura_sobre_suelo + 0.035
	var sh_sc: float = maxf(0.38, 1.0 - altura_sobre_suelo * 0.14)
	_shadow_disc.scale = Vector3(sh_sc, 1.0, sh_sc)

	var postura: float = Envejecimiento_Personaje.factor(edad_actual, "postura")

	_body_pivot.position = Vector3.ZERO
	_body_pivot.scale = Vector3(squash_x, squash_y, squash_x)
	_resetear_articulaciones()

	if invuln > 0.0:
		_body_pivot.visible = (int(floor(tiempo * 22.0)) % 2) == 0
	else:
		_body_pivot.visible = true

	if modo_titulo:
		_actualizar_textura_rostro_dinamica("normal", tiempo)
		var respiracion: float = sin(tiempo * 2.6) * 0.022 * (1.0 - 0.35 * postura)
		_body_pivot.position.y = respiracion
		# El frente del personaje es -Z y la cámara del menú está en +Z/+X:
		# rotamos cerca de PI - 0.28 para que mire directamente a la cámara en 3/4 frontal!
		var yaw_menu: float = (PI - 0.28) + sin(tiempo * 0.85) * 0.22
		_body_pivot.rotation = Vector3(0.0, yaw_menu, 0.0)
		_rot_y_suave = yaw_menu
		_rot_y_inicializado = true

		_torso.rotation = Vector3(0.03 + 0.05 * postura, sin(tiempo * 0.85) * 0.06, sin(tiempo * 1.3) * 0.02)
		_head_group.rotation = Vector3(sin(tiempo * 1.5) * 0.04, 0.10 + sin(tiempo * 1.1) * 0.14, sin(tiempo * 0.9) * 0.04)
		_hair_sway.rotation.x = 0.06 + sin(tiempo * 2.4) * 0.06

		var sway_b: float = sin(tiempo * 1.8) * 0.06
		_left_arm.rotation = Vector3(0.10 + sway_b, 0.0, -0.14)
		_left_forearm.rotation = Vector3(0.32, 0.0, 0.08)
		_right_arm.rotation = Vector3(-0.12 - sway_b, 0.0, 0.14)
		_right_forearm.rotation = Vector3(0.36, 0.0, -0.08)

		_left_leg.rotation = Vector3(-0.06, 0.0, -0.04)
		_left_shin.rotation = Vector3(-0.08, 0.0, 0.0)
		_left_foot.rotation = Vector3(0.06, 0.0, 0.0)
		_right_leg.rotation = Vector3(0.08, 0.0, 0.04)
		_right_shin.rotation = Vector3(-0.10, 0.0, 0.0)
		_right_foot.rotation = Vector3(0.02, 0.0, 0.0)
		return

	_rot_y_suave = 0.0
	_body_pivot.rotation = Vector3(0.0, 0.0, inclinacion_z)

	if estado == "CHOCADO" or estado == "CAIDO":
		_actualizar_textura_rostro_dinamica("choque", tiempo)
		_body_pivot.position.y = 0.24
		_body_pivot.rotation = Vector3(-0.95, 0.25, 0.35)
		_left_arm.rotation = Vector3(0.95, 0.0, -0.75)
		_left_forearm.rotation = Vector3(0.45, 0.0, 0.0)
		_right_arm.rotation = Vector3(0.85, 0.0, 0.75)
		_right_forearm.rotation = Vector3(0.45, 0.0, 0.0)
		_left_leg.rotation = Vector3(0.55, 0.0, -0.18)
		_left_shin.rotation = Vector3(-0.45, 0.0, 0.0)
		_right_leg.rotation = Vector3(-0.35, 0.0, 0.18)
		_right_shin.rotation = Vector3(-0.35, 0.0, 0.0)
		return

	if estado == "RODANDO":
		_actualizar_textura_rostro_dinamica("esfuerzo", tiempo)
		var t_rodar: float = float(jugador.get("tiempo_rodar", 0.0))
		var dur_rodar: float = maxf(0.01, float(jugador.get("duracion_rodar", 0.62)))
		var prog: float = 1.0 - t_rodar / dur_rodar
		_body_pivot.position.y = 0.48
		_body_pivot.rotation.x = -prog * TAU
		_left_leg.rotation = Vector3(1.15, 0.0, 0.0)
		_left_shin.rotation = Vector3(-1.35, 0.0, 0.0)
		_right_leg.rotation = Vector3(1.15, 0.0, 0.0)
		_right_shin.rotation = Vector3(-1.35, 0.0, 0.0)
		_left_arm.rotation = Vector3(1.05, 0.0, -0.22)
		_left_forearm.rotation = Vector3(1.10, 0.0, 0.0)
		_right_arm.rotation = Vector3(1.05, 0.0, 0.22)
		_right_forearm.rotation = Vector3(1.10, 0.0, 0.0)
		return

	if volando:
		_actualizar_textura_rostro_dinamica("normal", tiempo)
		_body_pivot.position.y = sin(tiempo * 5.0) * 0.06
		_body_pivot.rotation = Vector3(-0.22, 0.0, inclinacion_z * 1.2)
		_torso.rotation = Vector3(-0.24, 0.0, 0.0)
		_head_group.rotation = Vector3(0.18, 0.0, 0.0)
		_left_leg.rotation = Vector3(0.32, 0.0, -0.10)
		_left_shin.rotation = Vector3(-0.42, 0.0, 0.0)
		_right_leg.rotation = Vector3(0.18, 0.0, 0.10)
		_right_shin.rotation = Vector3(-0.34, 0.0, 0.0)
		_left_arm.rotation = Vector3(-0.65, 0.0, -0.42)
		_left_forearm.rotation = Vector3(0.55, 0.0, 0.0)
		_right_arm.rotation = Vector3(-0.65, 0.0, 0.42)
		_right_forearm.rotation = Vector3(0.55, 0.0, 0.0)
		_hair_sway.rotation.x = 0.30 + sin(tiempo * 10.0) * 0.12
		return

	if en_pogo:
		_actualizar_textura_rostro_dinamica("esfuerzo", tiempo)
		var progreso_pogo: float = float(jugador.get("pogo_progreso", 0.0))
		_body_pivot.position.y = 0.04 + sin(tiempo * 12.0) * 0.03
		_body_pivot.rotation = Vector3(-0.12 + progreso_pogo * 0.12, 0.0, inclinacion_z * 1.1)
		_torso.rotation = Vector3(0.12, 0.0, 0.0)
		_head_group.rotation = Vector3(-0.06, 0.0, 0.0)
		_left_leg.rotation = Vector3(0.18, 0.0, -0.12)
		_left_shin.rotation = Vector3(-0.55, 0.0, 0.0)
		_right_leg.rotation = Vector3(0.18, 0.0, 0.12)
		_right_shin.rotation = Vector3(-0.55, 0.0, 0.0)
		_left_arm.rotation = Vector3(0.10, 0.0, -0.82)
		_left_forearm.rotation = Vector3(0.35, 0.0, 0.0)
		_right_arm.rotation = Vector3(0.10, 0.0, 0.82)
		_right_forearm.rotation = Vector3(0.35, 0.0, 0.0)
		_pogo.rotation.z = inclinacion_z * 0.9
		_hair_sway.rotation.x = 0.34
		return

	if surfeando:
		_actualizar_textura_rostro_dinamica("normal", tiempo)
		var flotar: float = 0.18 + sin(tiempo * 7.5) * 0.05
		_body_pivot.position.y = flotar
		_hoverboard.position.y = -0.02
		_hoverboard.rotation.z = inclinacion_z * 1.4
		_torso.rotation = Vector3(-0.12, 0.52, 0.0)
		_head_group.rotation = Vector3(0.05, -0.38, 0.0)
		_left_leg.rotation = Vector3(0.28, 0.32, -0.14)
		_left_shin.rotation = Vector3(-0.36, 0.0, 0.0)
		_right_leg.rotation = Vector3(-0.18, 0.32, 0.14)
		_right_shin.rotation = Vector3(-0.32, 0.0, 0.0)
		_left_arm.rotation = Vector3(0.18, 0.0, -0.68)
		_left_forearm.rotation = Vector3(0.45, 0.0, 0.0)
		_right_arm.rotation = Vector3(-0.18, 0.0, 0.68)
		_right_forearm.rotation = Vector3(0.45, 0.0, 0.0)
		_hair_sway.rotation.x = 0.28 + sin(tiempo * 8.0) * 0.10
		return

	if estado == "SALTANDO" or altura_sobre_suelo > 0.15:
		_actualizar_textura_rostro_dinamica("normal", tiempo)
		_torso.rotation.x = -0.20
		_head_group.rotation.x = 0.12
		_left_leg.rotation = Vector3(0.88, 0.0, -0.05)
		_left_shin.rotation = Vector3(-1.05, 0.0, 0.0)
		_left_foot.rotation = Vector3(0.25, 0.0, 0.0)
		_right_leg.rotation = Vector3(-0.52, 0.0, 0.05)
		_right_shin.rotation = Vector3(-0.42, 0.0, 0.0)
		_right_foot.rotation = Vector3(-0.25, 0.0, 0.0)
		_left_arm.rotation = Vector3(0.95, 0.0, -0.32)
		_left_forearm.rotation = Vector3(0.85, 0.0, 0.0)
		_right_arm.rotation = Vector3(-0.55, 0.0, 0.32)
		_right_forearm.rotation = Vector3(0.75, 0.0, 0.0)
		_hair_sway.rotation.x = 0.35
		return

	# Zancada biomecánica de carrera con flexión real de rodillas, tobillos y codos
	_actualizar_textura_rostro_dinamica("choque" if anim_tropiezo > 0.0 else "esfuerzo", tiempo)
	var p_l: float = ciclo
	var p_r: float = ciclo + PI
	var zancada: float = sin(ciclo)
	var rebote: float = absf(cos(ciclo)) * 0.095
	_body_pivot.position.y = rebote

	var extra_tropiezo: float = (sin(tiempo * 32.0) * 0.18) if anim_tropiezo > 0.0 else 0.0
	_torso.rotation.x = -0.18 - 0.05 * postura + extra_tropiezo
	_torso.rotation.y = -zancada * 0.16
	_head_group.rotation.x = 0.12
	_head_group.rotation.y = zancada * 0.08

	var th_l: float = cos(p_l) * 0.78 + 0.06
	var bend_l: float = 0.20 + 0.95 * maxf(0.0, -sin(p_l + 0.25))
	_left_leg.rotation = Vector3(th_l, 0.0, -0.02)
	_left_shin.rotation = Vector3(-bend_l, 0.0, 0.0)
	_left_foot.rotation = Vector3(0.18 * cos(p_l), 0.0, 0.0)

	var th_r: float = cos(p_r) * 0.78 + 0.06
	var bend_r: float = 0.20 + 0.95 * maxf(0.0, -sin(p_r + 0.25))
	_right_leg.rotation = Vector3(th_r, 0.0, 0.02)
	_right_shin.rotation = Vector3(-bend_r, 0.0, 0.0)
	_right_foot.rotation = Vector3(0.18 * cos(p_r), 0.0, 0.0)

	var arm_ang_l: float = -cos(p_l) * 0.74
	var arm_ang_r: float = -cos(p_r) * 0.74
	_left_arm.rotation = Vector3(arm_ang_l, 0.0, -0.12)
	_left_forearm.rotation = Vector3(1.15 + maxf(0.0, arm_ang_l) * 0.28, 0.0, 0.08)
	_right_arm.rotation = Vector3(arm_ang_r, 0.0, 0.12)
	_right_forearm.rotation = Vector3(1.15 + maxf(0.0, arm_ang_r) * 0.28, 0.0, -0.08)

	_hair_sway.rotation = Vector3(0.22 + rebote * 1.4, zancada * 0.18, 0.0)
