class_name Runner_Escenario_3D
extends RefCounted

# ============================================================================
# ESCENARIO, VÍAS, EDIFICIOS, OBSTÁCULOS Y POWER-UPS 3D (MODELOS BLENDER GLB)
#
# - Carga todos los modelos .glb de `res://Modelos/Minijuego_Correr/` creados en
#   Blender, conserva sus múltiples superficies PBR/UV y sustituye cada material
#   por `Runner_Curvo.gdshader` para curvar el horizonte, soportar normales y
#   iluminar ventanas/faros/carteles durante el ciclo día/noche.
# ============================================================================

const LARGO_CHUNK: float = 32.0
const DIR_MODELOS: String = "res://Modelos/Minijuego_Correr/"
const SHADER_CURVO: Shader = preload("res://Shaders/Runner_Curvo.gdshader")
const SHADER_SOMBRA: Shader = preload("res://Shaders/Runner_Sombra_Curva.gdshader")

const MODELOS_ESCENARIO: Array[String] = [
	"vagon_metro",
	"fuelle_vagon",
	"tren_movil_extra",
	"rampa_tren",
	"vagoneta_speeder",
	"valla_baja",
	"arco_galibo",
	"tunel_ferroviario",
	"balasto_chunk",
	"traviesa",
	"rail_tramo",
	"catenaria_tramo",
	"anden_tramo",
	"muro_corredor",
	"banco_estacion",
	"cajas_andenes",
	"papelera_urbana",
	"farola_estacion",
	"arbol_parque",
	"portico_catenaria",
	"puente_cartel",
	"edificio_0",
	"edificio_1",
	"edificio_2",
	"edificio_3",
	"edificio_4",
	"moneda",
	"powerup_iman",
	"powerup_zapatillas",
	"powerup_estrella_2x",
	"powerup_llave",
	"powerup_caja",
	"hoverboard",
	"jetpack",
	"pogo",
]

var texturas: Runner_Texturas_3D
var mats: Dictionary = {}
var meshes: Dictionary = {}
var _surf_idx: Dictionary = {}
var _mats_glb: Dictionary = {}
var _mats_curvos: Array[ShaderMaterial] = []
var _mat_sombra: ShaderMaterial


func _init(tex: Runner_Texturas_3D) -> void:
	texturas = tex
	_construir_materiales_base()
	_cargar_mallas_blender()


func _mat(col: Color, rough: float = 0.68, metal: float = 0.05,
		tex: Texture2D = null, uv_scale: Vector2 = Vector2.ONE,
		norm: Texture2D = null, norm_scale: float = 0.85,
		em_tex: Texture2D = null, em_col: Color = Color.WHITE,
		em_dia: float = 0.0, em_noche: float = 0.0,
		estilizado: float = 0.32, rim: float = 0.14, ao_suelo: float = 0.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SHADER_CURVO
	m.set_shader_parameter("albedo_color", col)
	m.set_shader_parameter("roughness_val", rough)
	m.set_shader_parameter("metallic_val", metal)
	m.set_shader_parameter("uv_escala", uv_scale)
	m.set_shader_parameter("estilizado", estilizado)
	m.set_shader_parameter("rim_fuerza", rim)
	m.set_shader_parameter("ao_suelo", ao_suelo)
	if tex != null:
		m.set_shader_parameter("usar_albedo_tex", true)
		m.set_shader_parameter("albedo_tex", tex)
	if norm != null:
		m.set_shader_parameter("usar_normal_tex", true)
		m.set_shader_parameter("normal_tex", norm)
		m.set_shader_parameter("normal_escala", norm_scale)
	if em_dia > 0.0 or em_noche > 0.0:
		var em_lin: Color = em_col.srgb_to_linear()
		m.set_shader_parameter("emission_color", Vector3(em_lin.r, em_lin.g, em_lin.b))
		m.set_shader_parameter("emission_energia_dia", em_dia)
		m.set_shader_parameter("emission_energia_noche", em_noche)
		if em_tex != null:
			m.set_shader_parameter("usar_emission_tex", true)
			m.set_shader_parameter("emission_tex", em_tex)
	m.set_shader_parameter("curva_x", 0.0)
	m.set_shader_parameter("curva_y", 0.0022)
	m.set_shader_parameter("noche_factor", 0.0)
	_mats_curvos.append(m)
	return m


func _construir_materiales_base() -> void:
	mats["suelo_ciudad"] = _mat(Color("#6b7a60"), 0.92, 0.0, null, Vector2.ONE, null, 0.0, null, Color.WHITE, 0.0, 0.0, 0.20, 0.0, 0.0)
	mats["muro_a"] = _mat(Color.WHITE, 0.80, 0.03, texturas.muro_graffiti_a, Vector2.ONE, texturas.muro_normal, 1.0, null, Color.WHITE, 0.0, 0.0, 0.28, 0.06, 0.18)
	mats["muro_b"] = _mat(Color.WHITE, 0.80, 0.03, texturas.muro_graffiti_b, Vector2.ONE, texturas.muro_normal, 1.0, null, Color.WHITE, 0.0, 0.0, 0.28, 0.06, 0.18)

	for i in range(3):
		mats["cartel_%d" % i] = _mat(
			Color.WHITE, 0.36, 0.08, texturas.carteles[i], Vector2.ONE,
			null, 0.0, texturas.carteles[i], Color.WHITE, 0.18, 1.15,
			0.22, 0.16, 0.0
		)

	for i in range(4):
		mats["vagon_carr_%d" % i] = _mat(
			Color.WHITE, 0.40, 0.10, texturas.vagon_bl_carroceria[i], Vector2.ONE,
			null, 0.0, null, Color.WHITE, 0.0, 0.0, 0.22, 0.18, 0.18
		)
		mats["vagon_let_%d" % i] = _mat(
			Color.WHITE, 0.22, 0.0, texturas.vagon_bl_letrero[i], Vector2.ONE,
			null, 0.0, texturas.vagon_bl_letrero[i], Color.WHITE, 0.55, 2.15,
			0.18, 0.10, 0.0
		)

	var col_cart: Array[Color] = [Color("#facc15"), Color("#ef4444"), Color("#2563eb"), Color("#0d9488")]
	for i in range(col_cart.size()):
		mats["speeder_%d" % i] = _mat(col_cart[i], 0.34, 0.28, null, Vector2.ONE, null, 0.0, null, Color.WHITE, 0.0, 0.0, 0.35, 0.24, 0.15)

	_mat_sombra = ShaderMaterial.new()
	_mat_sombra.shader = SHADER_SOMBRA
	_mat_sombra.set_shader_parameter("sombra_tex", texturas.sombra_contacto)
	_mat_sombra.set_shader_parameter("opacidad", 0.76)
	_mat_sombra.set_shader_parameter("curva_x", 0.0)
	_mat_sombra.set_shader_parameter("curva_y", 0.0022)
	mats["sombra"] = _mat_sombra


func _cargar_mallas_blender() -> void:
	for nombre in MODELOS_ESCENARIO:
		_cargar_malla_glb(nombre)

	var suelo_pl := PlaneMesh.new()
	suelo_pl.size = Vector2(120.0, LARGO_CHUNK)
	suelo_pl.subdivide_depth = 16
	meshes["suelo_ext"] = suelo_pl

	var sh_pl := PlaneMesh.new()
	sh_pl.size = Vector2(1.45, 1.45)
	sh_pl.subdivide_depth = 4
	meshes["sombra"] = sh_pl


static func _cargar_escena_glb(nombre: String) -> Node:
	var ruta: String = DIR_MODELOS + nombre + ".glb"
	if ResourceLoader.exists(ruta):
		var res := ResourceLoader.load(ruta) as PackedScene
		if res != null:
			return res.instantiate()
	var abs_path: String = ProjectSettings.globalize_path(ruta)
	if FileAccess.file_exists(abs_path):
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		if doc.append_from_file(abs_path, state) == OK:
			return doc.generate_scene(state)
	push_error("No se pudo cargar el modelo Blender: %s" % ruta)
	return null


static func _buscar_mesh_inst(nodo: Node) -> MeshInstance3D:
	if nodo is MeshInstance3D:
		return nodo as MeshInstance3D
	for c in nodo.get_children():
		var hallado := _buscar_mesh_inst(c)
		if hallado != null:
			return hallado
	return null


func _convertir_material_glb(nombre_glb: String, std_raw: Material) -> ShaderMaterial:
	var std := std_raw as StandardMaterial3D
	if std == null:
		return _mat(Color(0.8, 0.8, 0.8))

	var mat_name: String = std.resource_name
	var cache_key: String = "%s:%s" % [nombre_glb, mat_name]
	if _mats_glb.has(cache_key):
		return _mats_glb[cache_key]

	var smat: ShaderMaterial = null
	var col: Color = std.albedo_color
	var rough: float = clampf(std.roughness, 0.08, 0.96)
	var metal: float = clampf(std.metallic, 0.0, 0.95)
	var alb_tex: Texture2D = std.albedo_texture
	var nrm_tex: Texture2D = std.normal_texture
	var em_tex: Texture2D = std.emission_texture

	if mat_name == "Muro_Ladrillo":
		smat = mats["muro_a"]
	elif mat_name == "Puente_Cartel":
		smat = mats["cartel_0"]
	elif mat_name == "Vagon_Carroceria":
		smat = mats["vagon_carr_0"]
	elif mat_name == "Vagon_LetreroLED":
		smat = mats["vagon_let_0"]
	elif mat_name == "Vagon_Cristal":
		smat = _mat(col, 0.12, 0.28, alb_tex, Vector2.ONE, null, 0.0,
			texturas.vagon_bl_cristal_em, Color("#ffa818"), 0.0, 1.35, 0.25, 0.30, 0.0)
	elif mat_name == "Vagon_Techo":
		smat = _mat(Color.WHITE if alb_tex != null else col, rough, metal, alb_tex, Vector2.ONE,
			nrm_tex, 0.95, null, Color.WHITE, 0.0, 0.0, 0.26, 0.16, 0.0)
	elif mat_name.contains("VentanaLuz"):
		smat = _mat(col, 0.18, 0.26, alb_tex, Vector2.ONE, null, 0.0,
			null, Color("#ff9810"), 0.0, 1.18, 0.24, 0.24, 0.0)
	elif mat_name == "Farola_Luz" or mat_name == "Tunel_LuzLED" or mat_name == "Puente_FocoLuz":
		smat = _mat(Color("#ffe599"), 0.12, 0.0, alb_tex, Vector2.ONE, null, 0.0,
			null, Color("#ffbf24"), 0.55, 1.25, 0.12, 0.0, 0.0)
	elif mat_name == "Moneda_Oro" or mat_name == "Estrella2X_Oro" or mat_name == "Llave_Oro" or mat_name == "Caja_Oro":
		smat = _mat(col, 0.14, 0.84, null, Vector2.ONE, null, 0.0,
			null, Color("#ffcf40"), 0.22, 0.78, 0.22, 0.36, 0.0)
	elif mat_name == "Moneda_Estrella" or mat_name == "Estrella2X_Brillo" or mat_name == "Llave_OroClaro" or mat_name == "Caja_Estrella":
		smat = _mat(col, 0.12, 0.78, null, Vector2.ONE, null, 0.0,
			null, Color("#ffe86b"), 0.32, 0.95, 0.20, 0.42, 0.0)
	elif mat_name == "Vagon_Faro" or mat_name == "Movil_Faro" or mat_name == "Speeder_Faro":
		smat = _mat(col, 0.12, 0.0, alb_tex, Vector2.ONE, null, 0.0,
			null, Color("#ffe066"), 1.05, 1.95, 0.10, 0.0, 0.0)
	elif mat_name == "Rampa_Top":
		smat = _mat(Color.WHITE if alb_tex != null else col, rough, metal, alb_tex, Vector2.ONE,
			nrm_tex, 0.90, em_tex, Color("#fde047"), 0.22, 1.35, 0.28, 0.18, 0.08)
	elif mat_name == "Balasto_Grava":
		smat = _mat(Color("#cfc8be"), 0.92, 0.02, alb_tex, Vector2.ONE,
			nrm_tex, 0.90, null, Color.WHITE, 0.0, 0.0, 0.18, 0.02, 0.0)
	else:
		var em_col: Color = std.emission if std.emission_enabled else Color.WHITE
		var em_dia: float = 0.0
		var em_noche: float = 0.0
		if std.emission_enabled and std.emission_energy_multiplier > 0.01:
			var e_raw: float = std.emission_energy_multiplier
			em_dia = clampf(e_raw * 0.45, 0.15, 1.45)
			em_noche = clampf(e_raw * 0.95, 0.45, 2.80)
		var est: float = 0.34 if mat_name.begins_with("Arbol_Hoja") else 0.18
		var rim_f: float = 0.20 if mat_name.begins_with("Arbol_Hoja") else 0.14
		var ao_f: float = 0.18 if (mat_name.contains("Pared") or mat_name.begins_with("Vagon_") or mat_name.begins_with("Muro_")) else 0.0
		smat = _mat(col, rough, metal, alb_tex, Vector2.ONE, nrm_tex, 0.92,
			em_tex, em_col, em_dia, em_noche, est, rim_f, ao_f)

	_mats_glb[cache_key] = smat
	return smat


func _cargar_malla_glb(nombre: String) -> void:
	var escena := _cargar_escena_glb(nombre)
	if escena == null:
		return
	var mi := _buscar_mesh_inst(escena)
	if mi == null or mi.mesh == null:
		push_error("El .glb %s no contiene malla." % nombre)
		escena.free()
		return

	var malla: Mesh = mi.mesh.duplicate()
	escena.free()

	var mapa_surf: Dictionary = {}
	for s in range(malla.get_surface_count()):
		var orig := malla.surface_get_material(s)
		var m_name: String = orig.resource_name if orig != null else ("Surf_%d" % s)
		mapa_surf[m_name] = s
		var smat := _convertir_material_glb(nombre, orig)
		malla.surface_set_material(s, smat)

	_surf_idx[nombre] = mapa_surf
	meshes[nombre] = malla


func _add_glb(parent: Node3D, nombre: String, pos: Vector3, rot_y: float = 0.0,
		scl: Vector3 = Vector3.ONE, shadow: bool = false, cull_margin: float = 14.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nombre
	var malla: Mesh = meshes.get(nombre)
	if malla != null:
		mi.mesh = malla
	mi.position = pos
	mi.rotation.y = rot_y
	mi.scale = scl
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = cull_margin
	parent.add_child(mi)
	return mi


func _set_surf(mi: MeshInstance3D, nombre_glb: String, mat_slot: String, mat: Material) -> void:
	var mapa: Dictionary = _surf_idx.get(nombre_glb, {})
	if mapa.has(mat_slot):
		mi.set_surface_override_material(int(mapa[mat_slot]), mat)


static func _add_mesh(parent: Node3D, mesh: Mesh, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO,
		scl: Vector3 = Vector3.ONE, shadow: bool = false, cull_margin: float = 14.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	mi.scale = scl
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = cull_margin
	parent.add_child(mi)
	return mi


## Sincroniza curvatura del horizonte y factor noche en todos los shaders del escenario.
func actualizar_curva_y_clima(curva_x: float, curva_y: float, factor_noche: float) -> void:
	for m in _mats_curvos:
		m.set_shader_parameter("curva_x", curva_x)
		m.set_shader_parameter("curva_y", curva_y)
		m.set_shader_parameter("noche_factor", factor_noche)
	if _mat_sombra != null:
		_mat_sombra.set_shader_parameter("curva_x", curva_x)
		_mat_sombra.set_shader_parameter("curva_y", curva_y)


## Compatibilidad con llamadas previas.
func actualizar_brillo_farolas(factor_noche: float) -> void:
	actualizar_curva_y_clima(0.0, 0.0022, factor_noche)


# ----------------------------------------------------------------------------
# Chunks repetibles del Corredor Ferroviario Urbano (32 m)
# ----------------------------------------------------------------------------

func crear_chunk_parque(variante: int) -> Node3D:
	var chunk := Node3D.new()
	chunk.name = "Chunk_%d" % variante

	var ancho_vias: float = Runner_Simulacion.ANCHO_CARRIL * 3.0 + 1.5
	var borde_x: float = ancho_vias * 0.5  # 4.80 m

	# 1. Balasto ferroviario perfilado con normales y canales entre vías
	_add_glb(chunk, "balasto_chunk", Vector3.ZERO, 0.0, Vector3.ONE, false, 18.0)

	# 2. Terreno urbano exterior (evita ver horizonte vacío tras edificios)
	_add_mesh(chunk, meshes["suelo_ext"], Vector3(0.0, -0.06, 0.0), mats["suelo_ciudad"], Vector3.ZERO, Vector3.ONE, false, 18.0)

	# 3. 96 Traviesas con placas metálicas y tirafondos en 1 MultiMesh
	var mm_trav := MultiMesh.new()
	mm_trav.transform_format = MultiMesh.TRANSFORM_3D
	mm_trav.mesh = meshes.get("traviesa")
	var num_filas: int = 32
	mm_trav.instance_count = num_filas * 3
	var idx_t: int = 0
	var paso_z: float = LARGO_CHUNK / float(num_filas)
	for carril in [-1, 0, 1]:
		var cx: float = Runner_Simulacion.carril_a_x(carril)
		for f in range(num_filas):
			var tz: float = -LARGO_CHUNK * 0.5 + (float(f) + 0.5) * paso_z
			mm_trav.set_instance_transform(idx_t, Transform3D(Basis.IDENTITY, Vector3(cx, 0.005, tz)))
			idx_t += 1
	var mmi_trav := MultiMeshInstance3D.new()
	mmi_trav.name = "Traviesas_MM"
	mmi_trav.multimesh = mm_trav
	mmi_trav.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi_trav.extra_cull_margin = 18.0
	chunk.add_child(mmi_trav)

	# 4. 6 Raíles perfil Vignoles (2 por vía) + 2 cables de catenaria con péndolas
	for carril in [-1, 0, 1]:
		var cx: float = Runner_Simulacion.carril_a_x(carril)
		for side_r in [-0.72, 0.72]:
			_add_glb(chunk, "rail_tramo", Vector3(cx + side_r, 0.015, 0.0), 0.0, Vector3.ONE, false, 18.0)
		if carril != 0:
			_add_glb(chunk, "catenaria_tramo", Vector3(cx, 7.05, 0.0), 0.0, Vector3.ONE, false, 18.0)

	# 5. Andenes, muros con grafiti, bancos/cajas, papeleras, farolas, árboles y edificios
	var mat_muro_l: Material = mats["muro_a"] if variante % 2 == 0 else mats["muro_b"]
	var mat_muro_r: Material = mats["muro_b"] if variante % 2 == 0 else mats["muro_a"]

	for lado in [-1.0, 1.0]:
		var rot_hacia_via: float = PI if lado < 0.0 else 0.0
		var rot_edif: float = 0.0 if lado < 0.0 else PI

		# Andén elevado con ménsulas, losa táctil y drenajes
		_add_glb(chunk, "anden_tramo", Vector3(lado * (borde_x + 1.82), 0.0, 0.0), 0.0, Vector3.ONE, false, 18.0)

		# Muro de ladrillo con pilastras, albardilla y barandilla superior
		var muro_x: float = lado * (borde_x + 3.92)
		var mi_muro := _add_glb(chunk, "muro_corredor", Vector3(muro_x, 0.0, 0.0), rot_hacia_via, Vector3.ONE, false, 18.0)
		_set_surf(mi_muro, "muro_corredor", "Muro_Ladrillo", mat_muro_l if lado < 0.0 else mat_muro_r)

		# Banco clásico o cajas de carga sobre el andén (y = 0.80 m)
		var ax: float = lado * (borde_x + 2.75)
		if (variante + (1 if lado > 0.0 else 0)) % 2 == 0:
			_add_glb(chunk, "banco_estacion", Vector3(ax, 0.80, -6.5), rot_hacia_via)
		else:
			_add_glb(chunk, "cajas_andenes", Vector3(ax, 0.80, -6.5), rot_hacia_via)

		# Papelera urbana y farola clásica mirando a las vías
		_add_glb(chunk, "papelera_urbana", Vector3(lado * (borde_x + 2.95), 0.80, 2.2), rot_hacia_via)
		_add_glb(chunk, "farola_estacion", Vector3(lado * (borde_x + 2.35), 0.80, 0.0), rot_hacia_via)

		# Árboles del parque tras el muro de ladrillo
		for t_idx in range(2):
			var tz: float = -9.5 if t_idx == 0 else 7.8
			var rot_a: float = float(t_idx) * 2.1 + float(variante) * 0.75 + (0.9 if lado > 0.0 else 0.0)
			_add_glb(chunk, "arbol_parque", Vector3(lado * (borde_x + 5.75), 0.35, tz), rot_a, Vector3.ONE, false, 18.0)

		# Edificios urbanos detallados (5 arquitecturas diferentes) detrás de los árboles
		for b in range(2):
			var seed_b: int = variante * 11 + b * 7 + (5 if lado > 0.0 else 1)
			var edif_idx: int = seed_b % 5
			var bz: float = -8.0 if b == 0 else 8.0
			var bx: float = lado * (borde_x + 11.4 + float((seed_b >> 1) % 2) * 0.9)
			_add_glb(chunk, "edificio_%d" % edif_idx, Vector3(bx, 0.0, bz), rot_edif, Vector3.ONE, false, 24.0)

	# 6. Pórtico de catenaria con celosía y semáforos cada 2 chunks
	if variante % 2 == 0:
		_add_glb(chunk, "portico_catenaria", Vector3(0.0, 0.0, -LARGO_CHUNK * 0.25), 0.0, Vector3.ONE, false, 18.0)

	# 7. Puente elevado con valla publicitaria iluminada cada 3 chunks
	if variante % 3 == 2:
		var cartel_idx: int = (variante / 3) % 3
		var mi_puente := _add_glb(chunk, "puente_cartel", Vector3(0.0, 8.4, 2.0), 0.0, Vector3.ONE, false, 20.0)
		_set_surf(mi_puente, "puente_cartel", "Puente_Cartel", mats["cartel_%d" % cartel_idx])

	return chunk


# ----------------------------------------------------------------------------
# Obstáculos 3D (Modelos Blender GLB)
# ----------------------------------------------------------------------------

func _construir_vagon_metro(obs: Dictionary) -> Node3D:
	var g := Node3D.new()
	var largo: float = float(obs["largo"])
	var librea: int = int(obs["librea"]) % 4

	_add_mesh(g, meshes["sombra"], Vector3(0.0, 0.03, 0.0), mats["sombra"], Vector3.ZERO, Vector3(2.15, 1.0, (largo + 1.8) / 1.45))

	var mi := _add_glb(g, "vagon_metro", Vector3.ZERO, 0.0, Vector3.ONE, true, 14.0)
	_set_surf(mi, "vagon_metro", "Vagon_Carroceria", mats["vagon_carr_%d" % librea])
	_set_surf(mi, "vagon_metro", "Vagon_LetreroLED", mats["vagon_let_%d" % librea])
	return g


func crear_seto_alto(obs: Dictionary) -> Node3D:
	return _construir_vagon_metro(obs)


func crear_tren_movil(obs: Dictionary) -> Node3D:
	var g: Node3D = _construir_vagon_metro(obs)
	_add_glb(g, "tren_movil_extra", Vector3.ZERO, 0.0, Vector3.ONE, false, 14.0)
	return g


func crear_tren_largo(obs: Dictionary) -> Node3D:
	var g := Node3D.new()
	var total: float = float(obs["largo"])
	var separacion: float = total / 3.0
	for i in range(3):
		var fake: Dictionary = obs.duplicate()
		fake["largo"] = separacion
		var vagon: Node3D = _construir_vagon_metro(fake)
		vagon.position.z = (float(i) - 1.0) * separacion
		g.add_child(vagon)
		if i < 2:
			_add_glb(g, "fuelle_vagon", Vector3(0.0, 0.0, (float(i) - 0.5) * separacion), 0.0, Vector3.ONE, false, 14.0)

	if bool(obs["tiene_rampa"]) and float(obs["largo_rampa"]) > 0.0:
		var r_len: float = float(obs["largo_rampa"])
		var r_z: float = total * 0.5
		_add_glb(g, "rampa_tren", Vector3(0.0, 0.0, r_z), 0.0, Vector3.ONE, true, 14.0)
		_add_mesh(g, meshes["sombra"], Vector3(0.0, 0.03, r_z + r_len * 0.5), mats["sombra"], Vector3.ZERO, Vector3(1.9, 1.0, r_len / 1.45))
	return g


func crear_pasarela_rampa(obs: Dictionary) -> Node3D:
	var g: Node3D = _construir_vagon_metro(obs)
	var largo: float = float(obs["largo"])
	if bool(obs["tiene_rampa"]) and float(obs["largo_rampa"]) > 0.0:
		var r_len: float = float(obs["largo_rampa"])
		var r_z: float = largo * 0.5
		_add_glb(g, "rampa_tren", Vector3(0.0, 0.0, r_z), 0.0, Vector3.ONE, true, 14.0)
		_add_mesh(g, meshes["sombra"], Vector3(0.0, 0.03, r_z + r_len * 0.5), mats["sombra"], Vector3.ZERO, Vector3(1.9, 1.0, r_len / 1.45))
	return g


func crear_ciclista(obs: Dictionary) -> Node3D:
	var g := Node3D.new()
	var librea: int = int(obs["librea"]) % 4
	_add_mesh(g, meshes["sombra"], Vector3(0.0, 0.03, 0.0), mats["sombra"], Vector3.ZERO, Vector3(1.65, 1.0, 2.25))
	var mi := _add_glb(g, "vagoneta_speeder", Vector3.ZERO, 0.0, Vector3.ONE, true, 12.0)
	_set_surf(mi, "vagoneta_speeder", "Speeder_Carroceria", mats["speeder_%d" % librea])
	return g


func crear_valla_baja() -> Node3D:
	var g := Node3D.new()
	_add_mesh(g, meshes["sombra"], Vector3(0.0, 0.03, 0.0), mats["sombra"], Vector3.ZERO, Vector3(1.85, 1.0, 0.85))
	_add_glb(g, "valla_baja", Vector3.ZERO, 0.0, Vector3.ONE, true, 10.0)
	return g


func crear_arco_alto() -> Node3D:
	var g := Node3D.new()
	_add_mesh(g, meshes["sombra"], Vector3(0.0, 0.03, 0.0), mats["sombra"], Vector3.ZERO, Vector3(2.1, 1.0, 0.80))
	_add_glb(g, "arco_galibo", Vector3.ZERO, 0.0, Vector3.ONE, true, 10.0)
	return g


func crear_tunel(_obs: Dictionary) -> Node3D:
	var g := Node3D.new()
	_add_glb(g, "tunel_ferroviario", Vector3.ZERO, 0.0, Vector3.ONE, false, 18.0)
	return g


# ----------------------------------------------------------------------------
# Coleccionables y Power-ups 3D (Modelos Blender GLB)
# ----------------------------------------------------------------------------

func crear_moneda() -> Node3D:
	var g := Node3D.new()
	_add_glb(g, "moneda", Vector3.ZERO, 0.0, Vector3.ONE, false, 6.0)
	return g


func crear_powerup(tipo: String) -> Node3D:
	var g := Node3D.new()
	match tipo:
		"IMAN":
			_add_glb(g, "powerup_iman", Vector3(0.0, 0.08, 0.0), 0.0, Vector3.ONE, false, 6.0)
		"ZAPATILLAS":
			_add_glb(g, "powerup_zapatillas", Vector3(0.0, 0.05, 0.0), 0.0, Vector3.ONE, false, 6.0)
		"MULTIPLICADOR":
			_add_glb(g, "powerup_estrella_2x", Vector3.ZERO, 0.0, Vector3.ONE, false, 6.0)
		"JETPACK":
			_add_glb(g, "jetpack", Vector3.ZERO, 0.0, Vector3(1.12, 1.12, 1.12), false, 6.0)
		"POGO":
			_add_glb(g, "pogo", Vector3(0.0, 0.14, 0.0), 0.0, Vector3(0.76, 0.76, 0.76), false, 6.0)
		"LLAVE":
			_add_glb(g, "powerup_llave", Vector3(0.0, 0.05, 0.0), 0.0, Vector3.ONE, false, 6.0)
		"CAJA":
			_add_glb(g, "powerup_caja", Vector3.ZERO, 0.35, Vector3.ONE, false, 6.0)
		_:
			var mi := _add_glb(g, "hoverboard", Vector3.ZERO, 0.0, Vector3.ONE, false, 6.0)
			mi.rotation = Vector3(0.28, 0.0, 0.14)
	return g
