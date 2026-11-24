class_name Runner_Escenario_3D
extends RefCounted

# ============================================================================
# MATERIALES, CHUNKS FERROVIARIOS URBANOS Y OBSTÁCULOS 3D (ESTILO SUBWAY SURFERS)
#
# - Shader curvo estilizado (Runner_Curvo.gdshader) en toda la escena para
#   lograr la icónica curvatura de horizonte, iluminación vibrante cálida/fría,
#   mapas de normales y ventanas/faros luminosos de noche.
# - 3 vías ferroviarias completas: balasto de grava con normales, 96 traviesas
#   de madera por chunk (MultiMesh), 6 raíles de acero brillante subdivididos,
#   andenes de estación con franja táctil amarilla, muros de ladrillo con
#   murales de grafiti, pórticos catenarios con cables y semáforos, puentes
#   elevados con carteles, árboles frondosos y edificios urbanos variados.
# - Obstáculos: vagones de metro biselados en 4 libreas con grafitis y unidades
#   HVAC en el techo, vagones con rampa amarilla industrial, vagoneta/speeder
#   ferroviario en sentido contrario, vallas bajas rojas/blancas y arcos altos
#   de gálibo para rodar por debajo.
# - Coleccionables esculpidos: monedas con estrella 3D, imán en herradura,
#   súper zapatillas con alas, estrella 2x facetada y tabla hoverboard curva.
# ============================================================================

const LARGO_CHUNK: float = 32.0
const Mallas := preload("res://Scripts/GUI/Minijuego_Correr/Runner_Mallas_3D.gd")
const SHADER_CURVO: Shader = preload("res://Shaders/Runner_Curvo.gdshader")
const SHADER_SOMBRA: Shader = preload("res://Shaders/Runner_Sombra_Curva.gdshader")

var texturas: Runner_Texturas_3D
var mats: Dictionary = {}
var meshes: Dictionary = {}
var _mats_curvos: Array[ShaderMaterial] = []
var _mat_sombra: ShaderMaterial
var _mat_cono_luz: ShaderMaterial


func _init(tex: Runner_Texturas_3D) -> void:
	texturas = tex
	_construir_materiales()
	_construir_mallas_compartidas()


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
		m.set_shader_parameter("emission_color", Vector3(em_col.r, em_col.g, em_col.b))
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


func _construir_materiales() -> void:
	# Vías, balasto, traviesas, raíles y andenes
	mats["balasto"] = _mat(Color.WHITE, 0.92, 0.02, texturas.balasto_albedo, Vector2(1.0, 4.0), texturas.balasto_normal, 0.95, null, Color.WHITE, 0.0, 0.0, 0.22, 0.03, 0.0)
	mats["traviesa"] = _mat(Color.WHITE, 0.86, 0.02, texturas.traviesa_albedo, Vector2.ONE, texturas.traviesa_normal, 0.9, null, Color.WHITE, 0.0, 0.0, 0.28, 0.06, 0.0)
	mats["rail_cabeza"] = _mat(Color("#dce6f2"), 0.20, 0.90, null, Vector2.ONE, null, 0.0, null, Color.WHITE, 0.0, 0.0, 0.15, 0.28, 0.0)
	mats["rail_base"] = _mat(Color("#524844"), 0.65, 0.55, null, Vector2.ONE, null, 0.0, null, Color.WHITE, 0.0, 0.0, 0.25, 0.08, 0.0)
	mats["anden"] = _mat(Color.WHITE, 0.78, 0.04, texturas.anden_albedo, Vector2(1.0, 4.0), texturas.anden_normal, 0.95, null, Color.WHITE, 0.0, 0.0, 0.25, 0.06, 0.0)
	mats["anden_bajo"] = _mat(Color("#474d59"), 0.88, 0.05, null, Vector2.ONE, null, 0.0, null, Color.WHITE, 0.0, 0.0, 0.30, 0.04, 0.35)
	mats["suelo_ciudad"] = _mat(Color("#6b7a60"), 0.92, 0.0, null, Vector2.ONE, null, 0.0, null, Color.WHITE, 0.0, 0.0, 0.20, 0.0, 0.0)

	# Muros de ladrillo con grafiti Subway Surfers
	mats["muro_a"] = _mat(Color.WHITE, 0.80, 0.03, texturas.muro_graffiti_a, Vector2(2.0, 1.0), texturas.muro_normal, 1.0, null, Color.WHITE, 0.0, 0.0, 0.28, 0.06, 0.18)
	mats["muro_b"] = _mat(Color.WHITE, 0.80, 0.03, texturas.muro_graffiti_b, Vector2(2.0, 1.0), texturas.muro_normal, 1.0, null, Color.WHITE, 0.0, 0.0, 0.28, 0.06, 0.18)
	mats["hormigon_claro"] = _mat(Color("#c4beb4"), 0.82, 0.04, null, Vector2.ONE, null, 0.0, null, Color.WHITE, 0.0, 0.0, 0.30, 0.08, 0.22)
	mats["hormigon_puente"] = _mat(Color("#8c96a4"), 0.78, 0.08, null, Vector2.ONE, null, 0.0, null, Color.WHITE, 0.0, 0.0, 0.30, 0.10, 0.0)

	# Acero estructural, pórticos, farolas y muebles urbanos
	mats["acero_portico"] = _mat(Color("#3b495c"), 0.44, 0.62, null, Vector2.ONE, null, 0.0, null, Color.WHITE, 0.0, 0.0, 0.28, 0.18, 0.15)
	mats["acero_oscuro"] = _mat(Color("#1f2937"), 0.48, 0.55, null, Vector2.ONE, null, 0.0, null, Color.WHITE, 0.0, 0.0, 0.30, 0.14, 0.10)
	mats["cable_catenaria"] = _mat(Color("#5c6e85"), 0.55, 0.35, null, Vector2.ONE, null, 0.0, null, Color.WHITE, 0.0, 0.0, 0.20, 0.05, 0.0)
	mats["farola_luz"] = _mat(Color("#fff6d6"), 0.12, 0.0, null, Vector2.ONE, null, 0.0, null, Color("#ffd166"), 0.95, 4.4, 0.10, 0.0, 0.0)
	mats["madera_calida"] = _mat(Color("#b56c3b"), 0.76, 0.04, null, Vector2.ONE, null, 0.0, null, Color.WHITE, 0.0, 0.0, 0.32, 0.10, 0.12)
	mats["madera_caja"] = _mat(Color("#d4924c"), 0.80, 0.02, null, Vector2.ONE, null, 0.0, null, Color.WHITE, 0.0, 0.0, 0.34, 0.10, 0.18)
	mats["tanque_agua"] = _mat(Color("#9c623d"), 0.82, 0.04, null, Vector2.ONE, null, 0.0, null, Color.WHITE, 0.0, 0.0, 0.34, 0.10, 0.0)

	# Vegetación estilizada rica (esmeralda profunda -> verde vibrante -> lima soleada)
	mats["tronco"] = _mat(Color("#6b4428"), 0.88, 0.02, null, Vector2.ONE, null, 0.0, null, Color.WHITE, 0.0, 0.0, 0.36, 0.06, 0.20)
	mats["hoja_oscura"] = _mat(Color("#1e7e46"), 0.72, 0.02, null, Vector2.ONE, null, 0.0, null, Color.WHITE, 0.0, 0.0, 0.42, 0.14, 0.0)
	mats["hoja_media"] = _mat(Color("#2ea853"), 0.68, 0.02, null, Vector2.ONE, null, 0.0, null, Color.WHITE, 0.0, 0.0, 0.42, 0.18, 0.0)
	mats["hoja_clara"] = _mat(Color("#66cf52"), 0.64, 0.02, null, Vector2.ONE, null, 0.0, null, Color.WHITE, 0.0, 0.0, 0.40, 0.22, 0.0)

	# Trenes Subway Surfers (4 libreas: costado, frente, techo corrugado, HVAC, ruedas)
	for i in range(4):
		mats["tren_lat_%d" % i] = _mat(
			Color.WHITE, 0.42, 0.18, texturas.tren_lateral[i], Vector2.ONE,
			texturas.tren_lateral_normal, 0.90,
			texturas.tren_lateral_emission, Color("#ffdf99"), 0.0, 1.35,
			0.30, 0.20, 0.20
		)
		mats["tren_frente_%d" % i] = _mat(
			Color.WHITE, 0.38, 0.20, texturas.tren_frente[i], Vector2.ONE,
			null, 0.0,
			texturas.tren_frente_emission, Color("#fff2b8"), 0.45, 2.20,
			0.30, 0.22, 0.18
		)
	mats["tren_techo"] = _mat(
		Color.WHITE, 0.56, 0.32, texturas.tren_techo_albedo, Vector2.ONE,
		texturas.tren_techo_normal, 0.95, null, Color.WHITE, 0.0, 0.0,
		0.25, 0.16, 0.0
	)
	mats["tren_hvac"] = _mat(Color("#aebbc9"), 0.50, 0.35, null, Vector2.ONE, null, 0.0, null, Color.WHITE, 0.0, 0.0, 0.32, 0.16, 0.0)
	mats["rueda_acero"] = _mat(Color("#2a323e"), 0.34, 0.72, null, Vector2.ONE, null, 0.0, null, Color.WHITE, 0.0, 0.0, 0.24, 0.20, 0.0)
	mats["faro_tren"] = _mat(Color("#fffbe0"), 0.12, 0.0, null, Vector2.ONE, null, 0.0, null, Color("#ffe88a"), 1.35, 3.20, 0.10, 0.0, 0.0)
	mats["faro_ambar"] = _mat(Color("#fef08a"), 0.18, 0.0, null, Vector2.ONE, null, 0.0, null, Color("#f59e0b"), 1.10, 2.60, 0.12, 0.0, 0.0)
	mats["piloto_rojo"] = _mat(Color("#ff5252"), 0.18, 0.0, null, Vector2.ONE, null, 0.0, null, Color("#ef4444"), 1.05, 2.50, 0.12, 0.0, 0.0)
	mats["semaforo_verde"] = _mat(Color("#4ade80"), 0.18, 0.0, null, Vector2.ONE, null, 0.0, null, Color("#22c55e"), 1.15, 2.60, 0.12, 0.0, 0.0)

	# Rampa industrial y vallas Subway Surfers
	mats["rampa_top"] = _mat(
		Color.WHITE, 0.44, 0.18, texturas.rampa_albedo, Vector2.ONE,
		null, 0.0, texturas.rampa_emission, Color("#fde047"), 0.22, 1.35,
		0.28, 0.18, 0.08
	)
	mats["rampa_lado"] = _mat(Color("#2b3648"), 0.50, 0.48, null, Vector2.ONE, null, 0.0, null, Color.WHITE, 0.0, 0.0, 0.30, 0.14, 0.22)
	mats["valla_peligro"] = _mat(Color.WHITE, 0.40, 0.14, texturas.valla_peligro_albedo, Vector2.ONE, null, 0.0, null, Color.WHITE, 0.0, 0.0, 0.30, 0.18, 0.0)
	mats["arco_paso"] = _mat(Color.WHITE, 0.38, 0.14, texturas.arco_paso_albedo, Vector2.ONE, null, 0.0, null, Color.WHITE, 0.0, 0.0, 0.30, 0.20, 0.0)
	mats["amarillo_seguridad"] = _mat(Color("#facc15"), 0.40, 0.15, null, Vector2.ONE, null, 0.0, null, Color.WHITE, 0.0, 0.0, 0.34, 0.18, 0.12)

	# Vagoneta ferroviaria / Speeder en sentido contrario (4 colores vibrantes)
	var col_cart: Array[Color] = [Color("#facc15"), Color("#ef4444"), Color("#2563eb"), Color("#0d9488")]
	for i in range(col_cart.size()):
		mats["speeder_%d" % i] = _mat(col_cart[i], 0.34, 0.28, null, Vector2.ONE, null, 0.0, null, Color.WHITE, 0.0, 0.0, 0.35, 0.24, 0.15)
	mats["cristal_cabina"] = _mat(Color("#4cb8ff"), 0.12, 0.38, null, Vector2.ONE, null, 0.0, null, Color("#7dd3fc"), 0.15, 0.45, 0.20, 0.40, 0.0)
	mats["chaleco_obra"] = _mat(Color("#ff6b1a"), 0.55, 0.05, null, Vector2.ONE, null, 0.0, null, Color("#fb923c"), 0.15, 0.65, 0.35, 0.18, 0.0)
	mats["piel_piloto"] = _mat(Color("#f1c27d"), 0.65, 0.02, null, Vector2.ONE, null, 0.0, null, Color.WHITE, 0.0, 0.0, 0.36, 0.12, 0.0)

	# 5 estilos arquitectónicos de edificios con ventanas nocturnas luminosas!
	for i in range(5):
		mats["edif_%d" % i] = _mat(
			Color.WHITE, 0.72, 0.05, texturas.edificios[i], Vector2(1.0, 2.0),
			texturas.edificio_normal, 0.85,
			texturas.edificio_emission, Color("#ffd166"), 0.0, 1.85,
			0.30, 0.12, 0.16
		)

	# Carteles vibrantes de puentes elevados
	for i in range(3):
		mats["cartel_%d" % i] = _mat(
			Color.WHITE, 0.36, 0.08, texturas.carteles[i], Vector2.ONE,
			null, 0.0, texturas.carteles[i], Color.WHITE, 0.15, 1.15,
			0.22, 0.16, 0.0
		)

	# Coleccionables y power-ups brillantes (oro 24k metálico con alto relieve!)
	mats["moneda_oro"] = _mat(Color("#f59e0b"), 0.14, 0.85, null, Vector2.ONE, null, 0.0, null, Color("#d97706"), 0.12, 0.45, 0.24, 0.36, 0.0)
	mats["moneda_estrella"] = _mat(Color("#ffe45e"), 0.12, 0.78, null, Vector2.ONE, null, 0.0, null, Color("#facc15"), 0.26, 0.65, 0.20, 0.42, 0.0)
	mats["iman_rojo"] = _mat(Color("#ef4444"), 0.22, 0.45, null, Vector2.ONE, null, 0.0, null, Color("#dc2626"), 0.35, 0.75, 0.28, 0.35, 0.0)
	mats["iman_punta"] = _mat(Color("#e2e8f0"), 0.16, 0.90, null, Vector2.ONE, null, 0.0, null, Color("#cbd5e1"), 0.18, 0.45, 0.20, 0.40, 0.0)
	mats["neon_verde"] = _mat(Color("#22ee74"), 0.24, 0.18, null, Vector2.ONE, null, 0.0, null, Color("#16a34a"), 0.55, 1.15, 0.26, 0.35, 0.0)
	mats["suela_blanca"] = _mat(Color("#f8fafc"), 0.35, 0.06, null, Vector2.ONE, null, 0.0, null, Color("#e2e8f0"), 0.12, 0.30, 0.28, 0.24, 0.0)
	mats["cian_glow"] = _mat(Color("#38bdf8"), 0.18, 0.32, null, Vector2.ONE, null, 0.0, null, Color("#0ea5e9"), 0.95, 1.65, 0.18, 0.42, 0.0)
	mats["coral_glow"] = _mat(Color("#fb3868"), 0.20, 0.30, null, Vector2.ONE, null, 0.0, null, Color("#e11d48"), 0.78, 1.45, 0.20, 0.38, 0.0)

	# Sombra de contacto curva
	_mat_sombra = ShaderMaterial.new()
	_mat_sombra.shader = SHADER_SOMBRA
	_mat_sombra.set_shader_parameter("sombra_tex", texturas.sombra_contacto)
	_mat_sombra.set_shader_parameter("opacidad", 0.76)
	_mat_sombra.set_shader_parameter("curva_x", 0.0)
	_mat_sombra.set_shader_parameter("curva_y", 0.0022)
	mats["sombra"] = _mat_sombra


func _construir_mallas_compartidas() -> void:
	# Vagón biselado subdividido en Z
	meshes["vagon"] = Mallas.crear_malla_vagon(2.28, Runner_Simulacion.ALTURA_PLATAFORMA, Runner_Simulacion.LARGO_PLATAFORMA, 0.42, 8)
	meshes["rampa"] = Mallas.crear_malla_rampa_cuna(2.14, Runner_Simulacion.ALTURA_PLATAFORMA, Runner_Simulacion.LARGO_RAMPA, 6)

	# Geometría subdividida para el chunk de 32m (curvatura sin quiebres!)
	var ancho_vias: float = Runner_Simulacion.ANCHO_CARRIL * 3.0 + 1.5
	var pista_pl := PlaneMesh.new()
	pista_pl.size = Vector2(ancho_vias, LARGO_CHUNK)
	pista_pl.subdivide_depth = 16
	pista_pl.subdivide_width = 4
	meshes["balasto_plano"] = pista_pl

	var suelo_pl := PlaneMesh.new()
	suelo_pl.size = Vector2(120.0, LARGO_CHUNK)
	suelo_pl.subdivide_depth = 16
	meshes["suelo_ext"] = suelo_pl

	meshes["rail_cabeza"] = Mallas.crear_caja_subdividida_z(Vector3(0.09, 0.06, LARGO_CHUNK), 16)
	meshes["rail_base"] = Mallas.crear_caja_subdividida_z(Vector3(0.15, 0.05, LARGO_CHUNK), 16)
	meshes["cable_catenaria"] = Mallas.crear_caja_subdividida_z(Vector3(0.024, 0.024, LARGO_CHUNK), 16)
	meshes["anden_top"] = Mallas.crear_caja_subdividida_z(Vector3(3.6, 0.24, LARGO_CHUNK), 16)
	meshes["anden_bajo"] = Mallas.crear_caja_subdividida_z(Vector3(3.15, 0.56, LARGO_CHUNK), 16)
	meshes["muro_ladrillo"] = Mallas.crear_caja_subdividida_z(Vector3(0.85, 3.8, LARGO_CHUNK), 16)
	meshes["baranda_muro"] = Mallas.crear_caja_subdividida_z(Vector3(0.08, 0.08, LARGO_CHUNK), 16)

	var trav := BoxMesh.new()
	trav.size = Vector3(2.15, 0.10, 0.26)
	meshes["traviesa"] = trav

	# Sombra de contacto subdividida
	var sh_pl := PlaneMesh.new()
	sh_pl.size = Vector2(1.45, 1.45)
	sh_pl.subdivide_depth = 4
	meshes["sombra"] = sh_pl

	# Rueda ferroviaria
	var wheel := CylinderMesh.new()
	wheel.top_radius = 0.34
	wheel.bottom_radius = 0.34
	wheel.height = 0.16
	wheel.radial_segments = 14
	meshes["rueda"] = wheel

	# Copas de árbol frondosas
	var c_big := SphereMesh.new()
	c_big.radius = 1.65
	c_big.height = 2.9
	c_big.radial_segments = 10
	c_big.rings = 6
	meshes["copa_grande"] = c_big

	var c_med := SphereMesh.new()
	c_med.radius = 1.25
	c_med.height = 2.2
	c_med.radial_segments = 10
	c_med.rings = 6
	meshes["copa_media"] = c_med

	var c_sm := SphereMesh.new()
	c_sm.radius = 0.92
	c_sm.height = 1.65
	c_sm.radial_segments = 8
	c_sm.rings = 5
	meshes["copa_pequena"] = c_sm

	# Coleccionables esculpidos
	var coin_disc := CylinderMesh.new()
	coin_disc.top_radius = 0.44
	coin_disc.bottom_radius = 0.44
	coin_disc.height = 0.13
	coin_disc.radial_segments = 20
	meshes["moneda_disco"] = coin_disc

	var coin_rim := TorusMesh.new()
	coin_rim.inner_radius = 0.35
	coin_rim.outer_radius = 0.46
	coin_rim.rings = 20
	coin_rim.ring_segments = 8
	meshes["moneda_aro"] = coin_rim

	meshes["moneda_estrella"] = Mallas.crear_estrella_3d(0.26, 0.115, 0.155)
	meshes["estrella_2x"] = Mallas.crear_estrella_3d(0.50, 0.22, 0.24)
	meshes["iman_herradura"] = Mallas.crear_iman_herradura(0.32, 0.11, 0.24)
	meshes["hoverboard"] = Mallas.crear_hoverboard_malla(0.58, 1.44, 0.085)


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


static func _add_box(parent: Node3D, sz: Vector3, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO, shadow: bool = true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = sz
	mi.mesh = m
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


static func _add_mesh(parent: Node3D, mesh: Mesh, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE, shadow: bool = false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	mi.scale = scl
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


# ----------------------------------------------------------------------------
# Chunks repetibles del Corredor Ferroviario Urbano (32 m)
# ----------------------------------------------------------------------------

func crear_chunk_parque(variante: int) -> Node3D:
	var chunk := Node3D.new()
	chunk.name = "Chunk_%d" % variante

	var ancho_vias: float = Runner_Simulacion.ANCHO_CARRIL * 3.0 + 1.5
	var borde_x: float = ancho_vias * 0.5

	# 1. Lecho de balasto ferroviario (grava con mapa de normales y canales entre vías)
	_add_mesh(chunk, meshes["balasto_plano"], Vector3(0.0, 0.0, 0.0), mats["balasto"])

	# 2. Terreno urbano exterior (nunca aparece vacío tras los muros)
	_add_mesh(chunk, meshes["suelo_ext"], Vector3(0.0, -0.06, 0.0), mats["suelo_ciudad"])

	# 3. 96 Traviesas de madera en 1 solo MultiMesh (32 por vía x 3 vías)
	var mm_trav := MultiMesh.new()
	mm_trav.transform_format = MultiMesh.TRANSFORM_3D
	mm_trav.mesh = meshes["traviesa"]
	var num_filas: int = 32
	mm_trav.instance_count = num_filas * 3
	var idx_t: int = 0
	var paso_z: float = LARGO_CHUNK / float(num_filas)
	for carril in [-1, 0, 1]:
		var cx: float = Runner_Simulacion.carril_a_x(carril)
		for f in range(num_filas):
			var tz: float = -LARGO_CHUNK * 0.5 + (float(f) + 0.5) * paso_z
			mm_trav.set_instance_transform(idx_t, Transform3D(Basis.IDENTITY, Vector3(cx, 0.035, tz)))
			idx_t += 1
	var mmi_trav := MultiMeshInstance3D.new()
	mmi_trav.name = "Traviesas_MM"
	mmi_trav.multimesh = mm_trav
	mmi_trav.material_override = mats["traviesa"]
	mmi_trav.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi_trav.extra_cull_margin = 18.0
	chunk.add_child(mmi_trav)

	# 4. 6 Raíles metálicos 3D brillantes (2 por vía) + 2 cables catenarios laterales (dejan cielo y carteles limpios!)
	for carril in [-1, 0, 1]:
		var cx: float = Runner_Simulacion.carril_a_x(carril)
		for side_r in [-0.72, 0.72]:
			_add_mesh(chunk, meshes["rail_base"], Vector3(cx + side_r, 0.095, 0.0), mats["rail_base"])
			_add_mesh(chunk, meshes["rail_cabeza"], Vector3(cx + side_r, 0.145, 0.0), mats["rail_cabeza"])
		if carril != 0:
			_add_mesh(chunk, meshes["cable_catenaria"], Vector3(cx, 6.45, 0.0), mats["cable_catenaria"])

	# 5. Andenes de estación, muros de ladrillo con grafitis, mobiliario, árboles y edificios
	var mat_muro_l: Material = mats["muro_a"] if variante % 2 == 0 else mats["muro_b"]
	var mat_muro_r: Material = mats["muro_b"] if variante % 2 == 0 else mats["muro_a"]

	for lado in [-1.0, 1.0]:
		var mat_muro: Material = mat_muro_l if lado < 0.0 else mat_muro_r

		# Andén elevado con voladizo sombreado (clásico foso de Subway Surfers)
		_add_mesh(chunk, meshes["anden_bajo"], Vector3(lado * (borde_x + 1.98), 0.28, 0.0), mats["anden_bajo"])
		_add_mesh(chunk, meshes["anden_top"], Vector3(lado * (borde_x + 1.80), 0.68, 0.0), mats["anden"])

		# Muro de ladrillo con grafiti Subway Surfers
		var muro_x: float = lado * (borde_x + 3.92)
		_add_mesh(chunk, meshes["muro_ladrillo"], Vector3(muro_x, 2.38, 0.0), mat_muro)

		# Pilastras arquitectónicas cada 16 m + barandilla superior de hierro
		for pz in [-8.0, 8.0]:
			_add_box(chunk, Vector3(1.12, 4.15, 0.92), Vector3(muro_x - lado * 0.05, 2.45, pz), mats["hormigon_claro"], Vector3.ZERO, false)
			_add_box(chunk, Vector3(1.26, 0.22, 1.08), Vector3(muro_x - lado * 0.05, 4.58, pz), mats["hormigon_claro"], Vector3.ZERO, false)
		_add_mesh(chunk, meshes["baranda_muro"], Vector3(muro_x - lado * 0.15, 4.92, 0.0), mats["acero_portico"])
		_add_mesh(chunk, meshes["baranda_muro"], Vector3(muro_x - lado * 0.15, 4.56, 0.0), mats["acero_portico"])
		for rz in [-12.0, -4.0, 4.0, 12.0]:
			_add_box(chunk, Vector3(0.08, 0.72, 0.08), Vector3(muro_x - lado * 0.15, 4.62, rz), mats["acero_portico"], Vector3.ZERO, false)

		# Mobiliario de estación sobre el andén (bancos, cajas, papeleras)
		var ax: float = lado * (borde_x + 2.80)
		if (variante + (1 if lado > 0.0 else 0)) % 2 == 0:
			# Banco de estación
			_add_box(chunk, Vector3(0.60, 0.11, 2.3), Vector3(ax, 1.24, -6.5), mats["madera_calida"], Vector3.ZERO, false)
			_add_box(chunk, Vector3(0.10, 0.48, 2.3), Vector3(ax + lado * 0.27, 1.50, -6.5), mats["madera_calida"], Vector3.ZERO, false)
			for lz in [-7.4, -5.6]:
				_add_box(chunk, Vector3(0.54, 0.44, 0.10), Vector3(ax, 1.02, lz), mats["acero_oscuro"], Vector3.ZERO, false)
		else:
			# Cajas de madera industriales en esquina del andén
			_add_box(chunk, Vector3(0.88, 0.88, 0.88), Vector3(ax + lado * 0.15, 1.24, -6.2), mats["madera_caja"], Vector3(0.0, 0.18, 0.0), false)
			_add_box(chunk, Vector3(0.68, 0.68, 0.68), Vector3(ax + lado * 0.18, 1.14, -7.2), mats["madera_calida"], Vector3(0.0, -0.14, 0.0), false)
			_add_box(chunk, Vector3(0.62, 0.62, 0.62), Vector3(ax + lado * 0.16, 1.98, -6.3), mats["madera_caja"], Vector3(0.0, 0.35, 0.0), false)

		# Papelera metálica urbana junto a la farola
		var bin_m := CylinderMesh.new()
		bin_m.top_radius = 0.25
		bin_m.bottom_radius = 0.21
		bin_m.height = 0.72
		bin_m.radial_segments = 10
		_add_mesh(chunk, bin_m, Vector3(lado * (borde_x + 2.95), 1.16, 2.2), mats["acero_portico"])

		# Farola clásica curva estilo metro/ciudad con linterna cálida
		var fx: float = lado * (borde_x + 2.35)
		var poste := CylinderMesh.new()
		poste.top_radius = 0.09
		poste.bottom_radius = 0.14
		poste.height = 5.4
		poste.radial_segments = 8
		_add_mesh(chunk, poste, Vector3(fx, 3.45, 0.0), mats["acero_portico"])
		_add_box(chunk, Vector3(0.36, 0.34, 0.36), Vector3(fx, 0.96, 0.0), mats["acero_oscuro"], Vector3.ZERO, false)
		# Brazo curvo inclinado hacia las vías
		_add_box(chunk, Vector3(1.65, 0.11, 0.11), Vector3(fx - lado * 0.78, 6.22, 0.0), mats["acero_portico"], Vector3(0.0, 0.0, lado * -0.14), false)
		_add_box(chunk, Vector3(0.58, 0.14, 0.34), Vector3(fx - lado * 1.48, 6.32, 0.0), mats["acero_oscuro"], Vector3.ZERO, false)
		_add_box(chunk, Vector3(0.46, 0.18, 0.26), Vector3(fx - lado * 1.48, 6.18, 0.0), mats["farola_luz"], Vector3.ZERO, false)

		# Árboles frondosos multicapa asomando sobre el muro de ladrillo
		for t_idx in range(2):
			var tz: float = -9.5 if t_idx == 0 else 7.8
			var arbol := Node3D.new()
			arbol.position = Vector3(lado * (borde_x + 5.75), 0.4, tz)
			var tr := CylinderMesh.new()
			tr.top_radius = 0.28
			tr.bottom_radius = 0.42
			tr.height = 4.2
			tr.radial_segments = 8
			_add_mesh(arbol, tr, Vector3(0.0, 2.1, 0.0), mats["tronco"])
			# 4 grupos de follaje en 3 tonos ricos de verde (sombra -> cuerpo -> cima soleada)
			_add_mesh(arbol, meshes["copa_grande"], Vector3(0.0, 4.45, 0.0), mats["hoja_oscura"])
			_add_mesh(arbol, meshes["copa_media"], Vector3(lado * -0.75, 4.95, 0.65), mats["hoja_media"])
			_add_mesh(arbol, meshes["copa_media"], Vector3(lado * 0.65, 4.85, -0.70), mats["hoja_media"])
			_add_mesh(arbol, meshes["copa_pequena"], Vector3(lado * -0.18, 5.85, 0.12), mats["hoja_clara"])
			chunk.add_child(arbol)

		# Edificios urbanos vibrantes con cornisas 3D, parapetos, depósitos de agua y AC
		for b in range(2):
			var seed_b: int = variante * 11 + b * 7 + (5 if lado > 0.0 else 1)
			var b_h: float = 13.5 + float(seed_b % 11) * 1.25
			var b_w: float = 8.4
			var b_d: float = 13.6
			var mat_idx: int = seed_b % 5
			var bz: float = -8.0 if b == 0 else 8.0
			var bx: float = lado * (borde_x + 11.4 + float((seed_b >> 1) % 2) * 0.9)

			# Cuerpo principal
			_add_box(chunk, Vector3(b_w, b_h, b_d), Vector3(bx, b_h * 0.5, bz), mats["edif_%d" % mat_idx], Vector3.ZERO, false)
			# Cornisa superior sobresaliente + franja intermedia
			_add_box(chunk, Vector3(b_w + 0.68, 0.65, b_d + 0.68), Vector3(bx, b_h + 0.30, bz), mats["hormigon_claro"], Vector3.ZERO, false)
			_add_box(chunk, Vector3(b_w + 0.36, 0.45, b_d + 0.36), Vector3(bx, b_h + 0.82, bz), mats["acero_portico"], Vector3.ZERO, false)

			# Detalles icónicos de azotea NYC / Subway Surfers
			if seed_b % 3 == 0:
				# Depósito de agua clásico de madera sobre patas de acero!
				var wt_x: float = bx - lado * 1.8
				var wt_y: float = b_h + 1.05
				for px in [-0.75, 0.75]:
					for pz in [-0.75, 0.75]:
						_add_box(chunk, Vector3(0.14, 1.5, 0.14), Vector3(wt_x + px, wt_y + 0.75, bz + pz), mats["acero_oscuro"], Vector3.ZERO, false)
				var tank := CylinderMesh.new()
				tank.top_radius = 1.28
				tank.bottom_radius = 1.32
				tank.height = 2.4
				tank.radial_segments = 12
				_add_mesh(chunk, tank, Vector3(wt_x, wt_y + 2.6, bz), mats["tanque_agua"])
				var roof_c := CylinderMesh.new()
				roof_c.top_radius = 0.08
				roof_c.bottom_radius = 1.48
				roof_c.height = 1.05
				roof_c.radial_segments = 12
				_add_mesh(chunk, roof_c, Vector3(wt_x, wt_y + 4.3, bz), mats["acero_oscuro"])
			elif seed_b % 3 == 1:
				# Ático / caseta de escalera + unidad de aire acondicionado
				_add_box(chunk, Vector3(3.6, 2.2, 4.4), Vector3(bx - lado * 1.2, b_h + 1.9, bz), mats["hormigon_claro"], Vector3.ZERO, false)
				_add_box(chunk, Vector3(1.5, 1.0, 1.5), Vector3(bx - lado * 2.2, b_h + 1.4, bz + 3.4), mats["tren_hvac"], Vector3.ZERO, false)

	# 6. Pórtico industrial de catenaria con celosía y semáforos ferroviarios (cada 2 chunks)
	if variante % 2 == 0:
		var arco_y: float = 6.95
		var span: float = ancho_vias + 4.2
		var arco_z: float = -LARGO_CHUNK * 0.25
		# Doble viga superior de celosía metálica
		_add_box(chunk, Vector3(span, 0.22, 0.34), Vector3(0.0, arco_y + 0.32, arco_z), mats["acero_portico"], Vector3.ZERO, false)
		_add_box(chunk, Vector3(span, 0.22, 0.34), Vector3(0.0, arco_y - 0.32, arco_z), mats["acero_portico"], Vector3.ZERO, false)
		# Diagonales de celosía industrial
		for ix in range(-5, 6):
			var dx: float = float(ix) * 1.15
			_add_box(chunk, Vector3(0.10, 0.82, 0.16), Vector3(dx, arco_y, arco_z), mats["acero_portico"], Vector3(0.0, 0.0, 0.55 if ix % 2 == 0 else -0.55), false)
		# Columnas laterales robustas con base amarilla de seguridad
		for lado in [-1.0, 1.0]:
			_add_box(chunk, Vector3(0.42, arco_y + 0.4, 0.42), Vector3(lado * (span * 0.5), (arco_y + 0.4) * 0.5, arco_z), mats["acero_portico"], Vector3.ZERO, false)
			_add_box(chunk, Vector3(0.56, 1.05, 0.56), Vector3(lado * (span * 0.5), 1.25, arco_z), mats["amarillo_seguridad"], Vector3.ZERO, false)

		# Semáforos colgantes ferroviarios sobre cada vía
		var sig_sp := SphereMesh.new()
		sig_sp.radius = 0.15
		sig_sp.height = 0.30
		sig_sp.radial_segments = 10
		sig_sp.rings = 6
		for carril in [-1, 0, 1]:
			var cx: float = Runner_Simulacion.carril_a_x(carril)
			_add_box(chunk, Vector3(0.56, 1.08, 0.36), Vector3(cx, arco_y - 0.88, arco_z + 0.20), mats["acero_oscuro"], Vector3.ZERO, false)
			_add_mesh(chunk, sig_sp, Vector3(cx, arco_y - 0.62, arco_z + 0.38), mats["faro_ambar"] if carril == 0 else mats["piloto_rojo"])
			_add_mesh(chunk, sig_sp, Vector3(cx, arco_y - 1.06, arco_z + 0.38), mats["semaforo_verde"])

	# 7. Puente urbano elevado con cartel publicitario colorido (en variante 2 y 5 -> cielo despejado en menú!)
	if variante % 3 == 2:
		var pu_y: float = 8.4
		var pu_z: float = 2.0
		var pu_span: float = ancho_vias + 14.0
		_add_box(chunk, Vector3(pu_span, 1.55, 5.2), Vector3(0.0, pu_y, pu_z), mats["hormigon_puente"], Vector3.ZERO, false)
		_add_box(chunk, Vector3(pu_span, 0.28, 5.5), Vector3(0.0, pu_y - 0.78, pu_z), mats["acero_portico"], Vector3.ZERO, false)
		_add_box(chunk, Vector3(pu_span, 0.95, 0.22), Vector3(0.0, pu_y + 1.20, pu_z + 2.55), mats["acero_oscuro"], Vector3.ZERO, false)
		# Valla publicitaria luminosa estilo Subway Surfers en la cara del puente
		var cartel_idx: int = (variante / 3) % 3
		_add_box(chunk, Vector3(7.8, 2.75, 0.26), Vector3(0.0, pu_y + 0.55, pu_z + 2.72), mats["acero_oscuro"], Vector3.ZERO, false)
		var pl_cartel := PlaneMesh.new()
		pl_cartel.size = Vector2(7.4, 2.45)
		_add_mesh(chunk, pl_cartel, Vector3(0.0, pu_y + 0.55, pu_z + 2.88), mats["cartel_%d" % cartel_idx], Vector3(PI * 0.5, 0.0, 0.0))

	return chunk


# ----------------------------------------------------------------------------
# Obstáculos 3D (Auténticos Trenes de Metro, Rampas, Vagonetas y Vallas)
# ----------------------------------------------------------------------------

## Construye la base compartida de un Vagón de Metro Subway Surfers (13.5 m x 3.05 m).
func _construir_vagon_metro(obs: Dictionary) -> Node3D:
	var g := Node3D.new()
	var largo: float = float(obs["largo"])
	var h: float = float(obs["altura"])
	var librea: int = int(obs["librea"]) % 4

	# Sombra de contacto curva bajo todo el vagón
	_add_mesh(g, meshes["sombra"], Vector3(0.0, 0.03, 0.0), mats["sombra"], Vector3.ZERO, Vector3(2.15, 1.0, (largo + 1.8) / 1.45))

	# Cuerpo biselado del vagón (3 superficies con UVs exactos)
	var body := MeshInstance3D.new()
	body.mesh = meshes["vagon"]
	body.set_surface_override_material(0, mats["tren_lat_%d" % librea])
	body.set_surface_override_material(1, mats["tren_techo"])
	body.set_surface_override_material(2, mats["tren_frente_%d" % librea])
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	g.add_child(body)

	# Bogies y ruedas de acero apoyadas sobre los raíles (x = ±0.72)
	for bogie_z in [-largo * 0.34, largo * 0.34]:
		_add_box(g, Vector3(1.88, 0.32, 2.45), Vector3(0.0, 0.30, bogie_z), mats["acero_oscuro"], Vector3.ZERO, false)
		for wz in [-0.72, 0.72]:
			for wx in [-0.74, 0.74]:
				_add_mesh(g, meshes["rueda"], Vector3(wx, 0.32, bogie_z + wz), mats["rueda_acero"], Vector3(0.0, 0.0, PI * 0.5))

	# Parachoques delantero y enganche central (+Z mirando al jugador)
	_add_box(g, Vector3(2.16, 0.24, 0.28), Vector3(0.0, 0.50, largo * 0.5 + 0.10), mats["acero_oscuro"], Vector3.ZERO, false)
	_add_box(g, Vector3(0.44, 0.24, 0.42), Vector3(0.0, 0.46, largo * 0.5 + 0.24), mats["acero_portico"], Vector3.ZERO, false)

	# Faros redondos 3D sobresalientes (brillan intensamente de noche!)
	var faro_m := CylinderMesh.new()
	faro_m.top_radius = 0.17
	faro_m.bottom_radius = 0.19
	faro_m.height = 0.12
	faro_m.radial_segments = 12
	for fx in [-0.68, 0.68]:
		_add_mesh(g, faro_m, Vector3(fx, 0.96, largo * 0.5 + 0.04), mats["faro_tren"], Vector3(PI * 0.5, 0.0, 0.0))

	# Unidades HVAC metálicas estilizadas con rejillas en los extremos del techo + barras laterales
	for hz in [-largo * 0.34, largo * 0.34]:
		_add_box(g, Vector3(1.18, 0.12, 1.55), Vector3(0.0, h + 0.055, hz), mats["tren_hvac"], Vector3.ZERO, false)
		for slat_z in [-0.46, 0.0, 0.46]:
			_add_box(g, Vector3(0.92, 0.035, 0.24), Vector3(0.0, h + 0.12, hz + slat_z), mats["acero_portico"], Vector3.ZERO, false)
	for rx in [-0.88, 0.88]:
		_add_box(g, Vector3(0.05, 0.07, largo - 1.2), Vector3(rx, h + 0.04, 0.0), mats["acero_portico"], Vector3.ZERO, false)

	return g


## Vagón de Metro estacionado (SETO_ALTO — mantiene contrato de simulación 13.5m x 3.05m)
func crear_seto_alto(obs: Dictionary) -> Node3D:
	return _construir_vagon_metro(obs)


## Tren en movimiento: mismo vagón con morro de peligro, focos encendidos y
## una franja roja/blanca que avisa de que la vía está activa (TREN_MOVIL).
func crear_tren_movil(obs: Dictionary) -> Node3D:
	var g: Node3D = _construir_vagon_metro(obs)
	var largo: float = float(obs["largo"])

	# Parachoques de peligro y matrícula luminosa en el morro (+Z)
	_add_box(g, Vector3(2.18, 0.20, 0.12), Vector3(0.0, 0.62, largo * 0.5 + 0.19), mats["valla_peligro"], Vector3.ZERO, false)
	_add_box(g, Vector3(1.40, 0.22, 0.05), Vector3(0.0, 1.32, largo * 0.5 + 0.06), mats["farola_luz"], Vector3.ZERO, false)
	for fx in [-0.68, 0.68]:
		var glow := SphereMesh.new()
		glow.radius = 0.24
		glow.height = 0.48
		glow.radial_segments = 12
		glow.rings = 8
		_add_mesh(g, glow, Vector3(fx, 0.96, largo * 0.5 + 0.12), mats["faro_tren"], Vector3.ZERO, Vector3.ONE, false)
	# Baliza roja superior para distinguirlo del tren aparcado
	var baliza := SphereMesh.new()
	baliza.radius = 0.14
	baliza.height = 0.28
	baliza.radial_segments = 10
	baliza.rings = 6
	_add_mesh(g, baliza, Vector3(0.0, float(obs["altura"]) + 0.20, -largo * 0.28), mats["piloto_rojo"], Vector3.ZERO, Vector3.ONE, false)
	return g


## Tren largo de 3 vagones (TREN_LARGO / TREN_LARGO_RAMPA): el obstáculo
## icónico de Subway Surfers que ocupa un carril durante decenas de metros.
func crear_tren_largo(obs: Dictionary) -> Node3D:
	var g := Node3D.new()
	var total: float = float(obs["largo"])
	var librea: int = int(obs["librea"]) % 4
	var separacion: float = total / 3.0
	for i in range(3):
		var fake: Dictionary = obs.duplicate()
		fake["largo"] = separacion
		var vagon: Node3D = _construir_vagon_metro(fake)
		vagon.position.z = (float(i) - 1.0) * separacion
		g.add_child(vagon)
		if i < 2:
			_add_box(g, Vector3(0.44, 0.32, 1.1), Vector3(0.0, 0.64, (float(i) - 0.5) * separacion), mats["acero_oscuro"], Vector3.ZERO, false)
			_add_box(g, Vector3(1.4, 0.10, 0.24), Vector3(0.0, 0.52, (float(i) - 0.5) * separacion), mats["valla_peligro"], Vector3.ZERO, false)

	if bool(obs["tiene_rampa"]) and float(obs["largo_rampa"]) > 0.0:
		var r_len: float = float(obs["largo_rampa"])
		var h: float = float(obs["altura"])
		var r_z: float = total * 0.5
		var rampa_mi := MeshInstance3D.new()
		rampa_mi.mesh = meshes["rampa"]
		rampa_mi.position = Vector3(0.0, 0.0, r_z)
		rampa_mi.set_surface_override_material(0, mats["rampa_top"])
		rampa_mi.set_surface_override_material(1, mats["rampa_lado"])
		rampa_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		g.add_child(rampa_mi)
		var hip: float = sqrt(r_len * r_len + h * h)
		var ang: float = atan2(h, r_len)
		for sx in [-1.09, 1.09]:
			_add_box(g, Vector3(0.11, 0.20, hip), Vector3(sx, h * 0.5 + 0.08, r_z + r_len * 0.5), mats["acero_oscuro"], Vector3(ang, 0.0, 0.0), false)
			_add_box(g, Vector3(0.07, 0.09, hip), Vector3(sx, h * 0.5 + 0.22, r_z + r_len * 0.5), mats["amarillo_seguridad"], Vector3(ang, 0.0, 0.0), false)
		_add_mesh(g, meshes["sombra"], Vector3(0.0, 0.03, r_z + r_len * 0.5), mats["sombra"], Vector3.ZERO, Vector3(1.9, 1.0, r_len / 1.45))
	return g


## Vagón de Metro con Rampa de abordaje amarilla (PASARELA_RAMPA — para correr por los techos!)
func crear_pasarela_rampa(obs: Dictionary) -> Node3D:
	var g: Node3D = _construir_vagon_metro(obs)
	var largo: float = float(obs["largo"])
	var h: float = float(obs["altura"])

	if bool(obs["tiene_rampa"]) and float(obs["largo_rampa"]) > 0.0:
		var r_len: float = float(obs["largo_rampa"])
		var r_z: float = largo * 0.5

		# Cuña sólida industrial con flechas chevrón luminosas
		var rampa_mi := MeshInstance3D.new()
		rampa_mi.mesh = meshes["rampa"]
		rampa_mi.position = Vector3(0.0, 0.0, r_z)
		rampa_mi.set_surface_override_material(0, mats["rampa_top"])
		rampa_mi.set_surface_override_material(1, mats["rampa_lado"])
		rampa_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		g.add_child(rampa_mi)

		# Barandillas metálicas inclinadas a ambos lados de la rampa
		var hip: float = sqrt(r_len * r_len + h * h)
		var ang: float = atan2(h, r_len)
		for sx in [-1.09, 1.09]:
			_add_box(g, Vector3(0.11, 0.20, hip), Vector3(sx, h * 0.5 + 0.08, r_z + r_len * 0.5), mats["acero_oscuro"], Vector3(ang, 0.0, 0.0), false)
			_add_box(g, Vector3(0.07, 0.09, hip), Vector3(sx, h * 0.5 + 0.22, r_z + r_len * 0.5), mats["amarillo_seguridad"], Vector3(ang, 0.0, 0.0), false)

		# Sombra bajo la rampa
		_add_mesh(g, meshes["sombra"], Vector3(0.0, 0.03, r_z + r_len * 0.5), mats["sombra"], Vector3.ZERO, Vector3(1.9, 1.0, r_len / 1.45))

	return g


## Vagoneta ferroviaria / Rail-Speeder en sentido contrario (CICLISTA — hitbox 2.6m x 1.95m)
func crear_ciclista(obs: Dictionary) -> Node3D:
	var g := Node3D.new()
	var librea: int = int(obs["librea"]) % 4
	var mat_cuerpo: Material = mats["speeder_%d" % librea]

	_add_mesh(g, meshes["sombra"], Vector3(0.0, 0.03, 0.0), mats["sombra"], Vector3.ZERO, Vector3(1.65, 1.0, 2.25))

	# Chasis ferroviario y 4 ruedas de acero sobre los raíles
	_add_box(g, Vector3(1.86, 0.28, 2.45), Vector3(0.0, 0.42, 0.0), mats["acero_oscuro"])
	for wz in [-0.76, 0.76]:
		for wx in [-0.74, 0.74]:
			_add_mesh(g, meshes["rueda"], Vector3(wx, 0.30, wz), mats["rueda_acero"], Vector3(0.0, 0.0, PI * 0.5))

	# Morro frontal robusto + parachoques de peligro rayado
	_add_box(g, Vector3(1.92, 0.72, 2.24), Vector3(0.0, 0.88, -0.04), mat_cuerpo)
	_add_box(g, Vector3(2.04, 0.34, 0.24), Vector3(0.0, 0.56, 1.24), mats["valla_peligro"])

	# Cabina acristalada + techo + baliza ámbar brillante arriba!
	_add_box(g, Vector3(1.64, 0.68, 1.18), Vector3(0.0, 1.46, -0.22), mats["cristal_cabina"])
	_add_box(g, Vector3(1.78, 0.14, 1.38), Vector3(0.0, 1.84, -0.22), mat_cuerpo)
	# Pilares de cabina
	for px in [-0.78, 0.78]:
		for pz in [-0.76, 0.32]:
			_add_box(g, Vector3(0.11, 0.68, 0.11), Vector3(px, 1.46, pz), mats["acero_oscuro"], Vector3.ZERO, false)

	# Baliza rotativa ámbar en el techo (lectura instantánea de obstáculo móvil!)
	var beacon := CylinderMesh.new()
	beacon.top_radius = 0.14
	beacon.bottom_radius = 0.17
	beacon.height = 0.24
	beacon.radial_segments = 12
	_add_mesh(g, beacon, Vector3(0.0, 2.02, -0.18), mats["faro_ambar"])

	# Dos grandes faros frontales encendidos (+Z hacia el corredor)
	var hl := SphereMesh.new()
	hl.radius = 0.19
	hl.height = 0.38
	hl.radial_segments = 12
	hl.rings = 8
	for hx in [-0.58, 0.58]:
		_add_mesh(g, hl, Vector3(hx, 0.96, 1.12), mats["faro_tren"])

	# Operario cartoon visible tras el cristal (chaleco reflectante y casco)
	_add_box(g, Vector3(0.46, 0.44, 0.26), Vector3(0.0, 1.32, -0.24), mats["chaleco_obra"], Vector3.ZERO, false)
	var head := SphereMesh.new()
	head.radius = 0.16
	head.height = 0.32
	head.radial_segments = 10
	head.rings = 8
	_add_mesh(g, head, Vector3(0.0, 1.62, -0.22), mats["piel_piloto"])
	_add_box(g, Vector3(0.36, 0.14, 0.38), Vector3(0.0, 1.74, -0.22), mats["amarillo_seguridad"], Vector3.ZERO, false)

	return g


## Valla baja saltable icónica de Subway Surfers (rayas rojas/blancas + caballete metálico)
func crear_valla_baja() -> Node3D:
	var g := Node3D.new()
	_add_mesh(g, meshes["sombra"], Vector3(0.0, 0.03, 0.0), mats["sombra"], Vector3.ZERO, Vector3(1.85, 1.0, 0.85))

	# Tablón grueso rojo/blanco reflectante con marco oscuro
	_add_box(g, Vector3(2.34, 0.56, 0.20), Vector3(0.0, 0.88, 0.0), mats["valla_peligro"])
	_add_box(g, Vector3(2.40, 0.09, 0.24), Vector3(0.0, 1.18, 0.0), mats["acero_oscuro"], Vector3.ZERO, false)
	_add_box(g, Vector3(2.40, 0.09, 0.24), Vector3(0.0, 0.58, 0.0), mats["acero_oscuro"], Vector3.ZERO, false)

	# Caballetes en A de acero tubular con bases atornilladas
	for sx in [-0.90, 0.90]:
		_add_box(g, Vector3(0.14, 1.18, 0.14), Vector3(sx, 0.56, 0.20), mats["acero_portico"], Vector3(-0.26, 0.0, 0.0))
		_add_box(g, Vector3(0.14, 1.18, 0.14), Vector3(sx, 0.56, -0.20), mats["acero_portico"], Vector3(0.26, 0.0, 0.0))
		_add_box(g, Vector3(0.28, 0.10, 0.78), Vector3(sx, 0.06, 0.0), mats["acero_oscuro"], Vector3.ZERO, false)

	# Dos balizas ámbar encendidas en las esquinas superiores
	var b_sp := SphereMesh.new()
	b_sp.radius = 0.13
	b_sp.height = 0.26
	b_sp.radial_segments = 10
	b_sp.rings = 8
	for bx in [-0.76, 0.76]:
		_add_box(g, Vector3(0.20, 0.12, 0.20), Vector3(bx, 1.24, 0.0), mats["acero_oscuro"], Vector3.ZERO, false)
		_add_mesh(g, b_sp, Vector3(bx, 1.38, 0.0), mats["faro_ambar"])

	return g


## Arco alto ferroviario para rodar por debajo (flechas amarillas hacia abajo + postes industriales)
func crear_arco_alto() -> Node3D:
	var g := Node3D.new()
	_add_mesh(g, meshes["sombra"], Vector3(0.0, 0.03, 0.0), mats["sombra"], Vector3.ZERO, Vector3(2.1, 1.0, 0.80))

	# Postes laterales metálicos con zapatas de hormigón y banda amarilla
	for sx in [-1.14, 1.14]:
		_add_box(g, Vector3(0.20, 2.66, 0.20), Vector3(sx, 1.33, 0.0), mats["acero_portico"])
		_add_box(g, Vector3(0.26, 0.54, 0.26), Vector3(sx, 0.42, 0.0), mats["amarillo_seguridad"], Vector3.ZERO, false)
		_add_box(g, Vector3(0.42, 0.18, 0.62), Vector3(sx, 0.09, 0.0), mats["hormigon_claro"], Vector3.ZERO, false)

	# Gran letrero superior de gálibo (y = 1.98m -> hueco limpio de ~1.50m para rodar!)
	_add_box(g, Vector3(2.48, 0.98, 0.24), Vector3(0.0, 1.98, 0.0), mats["arco_paso"])
	_add_box(g, Vector3(2.56, 0.11, 0.28), Vector3(0.0, 2.50, 0.0), mats["acero_oscuro"], Vector3.ZERO, false)
	_add_box(g, Vector3(2.56, 0.11, 0.28), Vector3(0.0, 1.46, 0.0), mats["acero_oscuro"], Vector3.ZERO, false)

	# Luces rojas de advertencia en la cima
	var l_sp := SphereMesh.new()
	l_sp.radius = 0.14
	l_sp.height = 0.28
	l_sp.radial_segments = 10
	l_sp.rings = 8
	for sx in [-0.82, 0.82]:
		_add_mesh(g, l_sp, Vector3(sx, 2.64, 0.0), mats["piloto_rojo"])
	return g


# ----------------------------------------------------------------------------
# Coleccionables y Power-ups 3D Esculpidos
# ----------------------------------------------------------------------------

## Túnel ferroviario bajo que cruza las tres vías y activa la cámara rasante.
func crear_tunel(obs: Dictionary) -> Node3D:
	var g := Node3D.new()
	var largo: float = float(obs["largo"])
	var alto: float = float(obs["altura"])
	var ancho: float = 11.2
	var z_entrada: float = largo * 0.5

	# Muros, techo y zócalo de hormigón
	for lado in [-1.0, 1.0]:
		_add_box(g, Vector3(0.55, alto, largo), Vector3(lado * (ancho * 0.5), alto * 0.5, 0.0), mats["hormigon_claro"], Vector3.ZERO, false)
		_add_box(g, Vector3(0.10, 0.35, largo), Vector3(lado * (ancho * 0.5 - 0.34), 0.18, 0.0), mats["valla_peligro"], Vector3.ZERO, false)
	_add_box(g, Vector3(ancho + 1.1, 0.32, largo), Vector3(0.0, alto + 0.16, 0.0), mats["hormigon_puente"], Vector3.ZERO, false)

	# Marco de entrada con franjas de peligro
	for lado in [-1.0, 1.0]:
		_add_box(g, Vector3(0.62, alto + 0.5, 0.55), Vector3(lado * (ancho * 0.5), (alto + 0.5) * 0.5, z_entrada), mats["hormigon_puente"], Vector3.ZERO, false)
		_add_box(g, Vector3(0.70, 0.22, 0.62), Vector3(lado * (ancho * 0.5), 0.22, z_entrada), mats["valla_peligro"], Vector3.ZERO, false)
	_add_box(g, Vector3(ancho + 1.3, 0.62, 0.55), Vector3(0.0, alto + 0.52, z_entrada), mats["hormigon_puente"], Vector3.ZERO, false)
	_add_box(g, Vector3(ancho + 1.3, 0.16, 0.60), Vector3(0.0, alto + 0.20, z_entrada), mats["valla_peligro"], Vector3.ZERO, false)

	# Lámparas longitudinales en el techo (lectura clara de túnel)
	var lamp := BoxMesh.new()
	lamp.size = Vector3(0.55, 0.08, 0.28)
	for lz in range(-int(largo * 0.5) + 3, int(largo * 0.5), 4):
		_add_mesh(g, lamp, Vector3(0.0, alto - 0.05, float(lz)), mats["farola_luz"], Vector3.ZERO, Vector3.ONE, false)
		_add_mesh(g, lamp, Vector3(-2.4, alto - 0.05, float(lz) + 1.2), mats["farola_luz"], Vector3.ZERO, Vector3.ONE, false)
		_add_mesh(g, lamp, Vector3(2.4, alto - 0.05, float(lz) + 1.2), mats["farola_luz"], Vector3.ZERO, Vector3.ONE, false)
	return g


## Moneda dorada 3D gruesa con aro biselado y estrella en relieve (estilo Subway Surfers!)
func crear_moneda() -> Node3D:
	var g := Node3D.new()
	_add_mesh(g, meshes["moneda_disco"], Vector3.ZERO, mats["moneda_oro"], Vector3(PI * 0.5, 0.0, 0.0))
	_add_mesh(g, meshes["moneda_aro"], Vector3.ZERO, mats["moneda_oro"], Vector3(PI * 0.5, 0.0, 0.0))
	_add_mesh(g, meshes["moneda_estrella"], Vector3.ZERO, mats["moneda_estrella"])
	return g


## Power-ups 3D esculpidos: IMAN (herradura), ZAPATILLAS (con alas), MULTIPLICADOR (estrella 3D), TABLA (hoverboard)
func crear_powerup(tipo: String) -> Node3D:
	var g := Node3D.new()
	match tipo:
		"IMAN":
			var im := MeshInstance3D.new()
			im.mesh = meshes["iman_herradura"]
			im.set_surface_override_material(0, mats["iman_rojo"])
			im.set_surface_override_material(1, mats["iman_punta"])
			im.position = Vector3(0.0, 0.08, 0.0)
			im.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			g.add_child(im)
			var aura := TorusMesh.new()
			aura.inner_radius = 0.52
			aura.outer_radius = 0.57
			aura.rings = 22
			aura.ring_segments = 8
			_add_mesh(g, aura, Vector3(0.0, 0.05, 0.0), mats["cian_glow"], Vector3(0.45, 0.0, 0.25))
		"ZAPATILLAS":
			for sx in [-0.28, 0.28]:
				var z := Node3D.new()
				z.position = Vector3(sx, -0.02, 0.0)
				z.rotation.y = 0.14 if sx < 0.0 else -0.14
				# Suela blanca gruesa + cuerpo verde neón + puntera redondeada + collar alto
				_add_box(z, Vector3(0.32, 0.11, 0.62), Vector3(0.0, -0.14, 0.0), mats["suela_blanca"], Vector3.ZERO, false)
				_add_box(z, Vector3(0.30, 0.24, 0.50), Vector3(0.0, 0.02, -0.04), mats["neon_verde"], Vector3.ZERO, false)
				_add_box(z, Vector3(0.28, 0.18, 0.26), Vector3(0.0, 0.18, -0.15), mats["neon_verde"], Vector3.ZERO, false)
				var toe := SphereMesh.new()
				toe.radius = 0.15
				toe.height = 0.26
				toe.radial_segments = 10
				toe.rings = 6
				_add_mesh(z, toe, Vector3(0.0, -0.02, 0.20), mats["suela_blanca"])
				# Ala estilizada blanca en el costado exterior
				var wing_dir: float = -1.0 if sx < 0.0 else 1.0
				_add_box(z, Vector3(0.05, 0.14, 0.34), Vector3(wing_dir * 0.18, 0.16, -0.16), mats["suela_blanca"], Vector3(0.32, 0.0, wing_dir * -0.25), false)
				_add_box(z, Vector3(0.04, 0.10, 0.26), Vector3(wing_dir * 0.20, 0.05, -0.22), mats["suela_blanca"], Vector3(0.22, 0.0, wing_dir * -0.18), false)
				g.add_child(z)
		"MULTIPLICADOR":
			_add_mesh(g, meshes["estrella_2x"], Vector3.ZERO, mats["moneda_oro"])
			var halo := TorusMesh.new()
			halo.inner_radius = 0.56
			halo.outer_radius = 0.63
			halo.rings = 24
			halo.ring_segments = 8
			_add_mesh(g, halo, Vector3.ZERO, mats["cian_glow"], Vector3(PI * 0.38, 0.0, 0.24))
		"JETPACK":
			_add_box(g, Vector3(0.42, 0.50, 0.30), Vector3(0.0, 0.0, 0.0), mats["acero_oscuro"])
			for lado in [-1.0, 1.0]:
				var botella := CylinderMesh.new()
				botella.top_radius = 0.09
				botella.bottom_radius = 0.12
				botella.height = 0.42
				botella.radial_segments = 12
				_add_mesh(g, botella, Vector3(lado * 0.16, -0.02, 0.02), mats["cian_glow"])
				var llama := CylinderMesh.new()
				llama.top_radius = 0.02
				llama.bottom_radius = 0.10
				llama.height = 0.30
				llama.radial_segments = 10
				_add_mesh(g, llama, Vector3(lado * 0.16, -0.36, 0.02), mats["coral_glow"])
			_add_box(g, Vector3(0.36, 0.08, 0.32), Vector3(0.0, 0.26, 0.0), mats["neon_verde"], Vector3.ZERO, false)
		"POGO":
			var barra := CylinderMesh.new()
			barra.top_radius = 0.035
			barra.bottom_radius = 0.045
			barra.height = 0.95
			barra.radial_segments = 10
			_add_mesh(g, barra, Vector3(0.0, -0.42, 0.0), mats["acero_oscuro"])
			var muelle := TorusMesh.new()
			muelle.inner_radius = 0.10
			muelle.outer_radius = 0.14
			muelle.rings = 16
			muelle.ring_segments = 6
			_add_mesh(g, muelle, Vector3(0.0, -0.84, 0.0), mats["coral_glow"])
			_add_box(g, Vector3(0.42, 0.05, 0.08), Vector3(0.0, 0.05, 0.0), mats["cian_glow"], Vector3.ZERO, false)
			for lado in [-1.0, 1.0]:
				_add_box(g, Vector3(0.05, 0.05, 0.30), Vector3(lado * 0.20, 0.03, 0.0), mats["cian_glow"], Vector3.ZERO, false)
			_add_mesh(g, meshes["estrella_2x"], Vector3(0.0, 0.32, 0.0), mats["moneda_oro"], Vector3.ZERO, Vector3(0.55, 0.55, 0.55))
		"LLAVE":
			_add_mesh(g, meshes["moneda_disco"], Vector3(0.0, 0.20, 0.0), mats["moneda_oro"], Vector3(PI * 0.5, 0.0, 0.0), Vector3(0.72, 0.72, 0.72))
			var anillo := TorusMesh.new()
			anillo.inner_radius = 0.20
			anillo.outer_radius = 0.30
			anillo.rings = 18
			anillo.ring_segments = 8
			_add_mesh(g, anillo, Vector3(0.0, 0.20, 0.0), mats["moneda_oro"], Vector3(PI * 0.5, 0.0, 0.0))
			_add_box(g, Vector3(0.09, 0.44, 0.07), Vector3(0.0, -0.16, 0.0), mats["moneda_oro"])
			_add_box(g, Vector3(0.22, 0.08, 0.07), Vector3(0.07, -0.36, 0.0), mats["moneda_oro"], Vector3.ZERO, false)
			_add_box(g, Vector3(0.16, 0.08, 0.07), Vector3(0.04, -0.24, 0.0), mats["moneda_oro"], Vector3.ZERO, false)
		"CAJA":
			_add_box(g, Vector3(0.82, 0.82, 0.82), Vector3.ZERO, mats["moneda_oro"], Vector3(0.10, 0.35, 0.0))
			_add_box(g, Vector3(0.88, 0.14, 0.88), Vector3(0.0, 0.34, 0.0), mats["coral_glow"], Vector3(0.10, 0.35, 0.0), false)
			_add_box(g, Vector3(0.14, 0.88, 0.88), Vector3(0.0, 0.0, 0.0), mats["cian_glow"], Vector3(0.10, 0.35, 0.0), false)
			_add_mesh(g, meshes["estrella_2x"], Vector3(0.0, 0.05, 0.44), mats["moneda_estrella"], Vector3.ZERO, Vector3(0.72, 0.72, 0.72), false)
			var halo_caja := TorusMesh.new()
			halo_caja.inner_radius = 0.66
			halo_caja.outer_radius = 0.73
			halo_caja.rings = 24
			halo_caja.ring_segments = 8
			_add_mesh(g, halo_caja, Vector3.ZERO, mats["cian_glow"], Vector3(PI * 0.38, 0.0, 0.24))
		_:
			# TABLA Hoverboard esculpida
			_add_mesh(g, meshes["hoverboard"], Vector3.ZERO, mats["coral_glow"], Vector3(0.28, 0.0, 0.14))
			_add_mesh(g, meshes["hoverboard"], Vector3(0.0, -0.025, 0.0), mats["cian_glow"], Vector3(0.28, 0.0, 0.14), Vector3(1.06, 0.55, 0.94))
	return g
