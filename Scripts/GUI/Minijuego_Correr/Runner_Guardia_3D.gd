class_name Runner_Guardia_3D
extends Node3D

# ============================================================================
# GUARDIA Y PERRO PERSECUTOR (ESTILO SUBWAY SURFERS)
#
# La silueta icónica que aparece detrás del corredor cuando tropieza o cae.
# Modelo 3D estilizado con primitivas biseladas y contorno de tinta, coherente
# con Runner_Personaje_3D. No interviene en la simulación: Runner_Mundo le pasa
# la distancia de persecución calculada por Runner_Simulacion.
# ============================================================================

const TINTA := Color("#111827")

var _raiz: Node3D
var _cuerpo: Node3D
var _cabeza: Node3D
var _brazo_izq: Node3D
var _brazo_der: Node3D
var _pierna_izq: Node3D
var _pierna_der: Node3D
var _perro: Node3D
var _perro_cabeza: Node3D
var _perro_cola: Node3D
var _sombra_guardia: MeshInstance3D
var _sombra_perro: MeshInstance3D
var _linterna: Node3D
var _tiempo: float = 0.0
var _ultima_distancia: float = 70.0


func _init() -> void:
	name = "Runner_Guardia_3D"
	_construir()


static func _mat(col: Color, rough: float = 0.86, emision: Color = Color(0, 0, 0), em_energy: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = 0.0
	m.metallic_specular = 0.08
	if em_energy > 0.0:
		m.emission_enabled = true
		m.emission = emision
		m.emission_energy_multiplier = em_energy
	var outline := StandardMaterial3D.new()
	outline.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	outline.cull_mode = BaseMaterial3D.CULL_FRONT
	outline.albedo_color = TINTA
	outline.grow = true
	outline.grow_amount = 0.012
	m.next_pass = outline
	return m


static func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi


static func _sphere(parent: Node3D, radius: float, pos: Vector3, mat: Material, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 10
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.scale = scl
	parent.add_child(mi)
	return mi


static func _cyl(parent: Node3D, r0: float, r1: float, h: float, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = r0
	mesh.bottom_radius = r1
	mesh.height = h
	mesh.radial_segments = 14
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi


func _construir() -> void:
	var mat_azul := _mat(Color("#1e3a8a"))
	var mat_azul_oscuro := _mat(Color("#172554"))
	var mat_amarillo := _mat(Color("#facc15"), 0.7, Color("#facc15"), 0.15)
	var mat_piel := _mat(Color("#d9a066"))
	var mat_pelo := _mat(Color("#3f2a1d"))
	var mat_bota := _mat(Color("#111827"))
	var mat_perro := _mat(Color("#9a5b32"))
	var mat_perro_claro := _mat(Color("#c98a58"))
	var mat_blanco := _mat(Color("#f8fafc"))
	var mat_metal := _mat(Color("#94a3b8"), 0.35)

	# Sombra de contacto compartida (se coloca a nivel del suelo)
	_sombra_guardia = _crear_sombra(0.85)
	_sombra_perro = _crear_sombra(0.55)

	_raiz = Node3D.new()
	_raiz.name = "Guardia"
	add_child(_raiz)

	# Piernas articuladas
	_pierna_izq = Node3D.new()
	_pierna_izq.position = Vector3(-0.16, 0.86, 0.0)
	_raiz.add_child(_pierna_izq)
	_box(_pierna_izq, Vector3(0.22, 0.52, 0.24), Vector3(0.0, -0.26, 0.0), mat_azul_oscuro)
	_box(_pierna_izq, Vector3(0.24, 0.26, 0.40), Vector3(0.0, -0.60, 0.08), mat_bota)

	_pierna_der = Node3D.new()
	_pierna_der.position = Vector3(0.16, 0.86, 0.0)
	_raiz.add_child(_pierna_der)
	_box(_pierna_der, Vector3(0.22, 0.52, 0.24), Vector3(0.0, -0.26, 0.0), mat_azul_oscuro)
	_box(_pierna_der, Vector3(0.24, 0.26, 0.40), Vector3(0.0, -0.60, 0.08), mat_bota)

	# Torso con chaleco reflectante y placa
	_cuerpo = Node3D.new()
	_cuerpo.position = Vector3(0.0, 1.08, 0.0)
	_raiz.add_child(_cuerpo)
	_box(_cuerpo, Vector3(0.54, 0.56, 0.34), Vector3(0.0, 0.10, 0.0), mat_azul)
	_box(_cuerpo, Vector3(0.60, 0.22, 0.37), Vector3(0.0, 0.12, -0.01), mat_amarillo)
	_box(_cuerpo, Vector3(0.13, 0.08, 0.03), Vector3(-0.16, 0.20, -0.19), mat_blanco)
	_box(_cuerpo, Vector3(0.13, 0.08, 0.03), Vector3(0.16, 0.20, -0.19), mat_blanco)
	_box(_cuerpo, Vector3(0.28, 0.20, 0.10), Vector3(0.0, 0.38, 0.0), mat_amarillo)

	# Brazos (hombro -> codo simplificado)
	_brazo_izq = Node3D.new()
	_brazo_izq.position = Vector3(-0.34, 0.28, 0.0)
	_cuerpo.add_child(_brazo_izq)
	_box(_brazo_izq, Vector3(0.16, 0.42, 0.18), Vector3(0.0, -0.18, 0.0), mat_azul)
	_box(_brazo_izq, Vector3(0.14, 0.20, 0.16), Vector3(0.0, -0.46, 0.0), mat_piel)

	_brazo_der = Node3D.new()
	_brazo_der.position = Vector3(0.34, 0.28, 0.0)
	_cuerpo.add_child(_brazo_der)
	_box(_brazo_der, Vector3(0.16, 0.42, 0.18), Vector3(0.0, -0.18, 0.0), mat_azul)
	_box(_brazo_der, Vector3(0.14, 0.20, 0.16), Vector3(0.0, -0.46, 0.0), mat_piel)

	# Cabeza con gorra de plato y linterna frontal
	_cabeza = Node3D.new()
	_cabeza.position = Vector3(0.0, 0.48, 0.0)
	_cuerpo.add_child(_cabeza)
	_sphere(_cabeza, 0.175, Vector3(0.0, 0.02, 0.0), mat_piel)
	_box(_cabeza, Vector3(0.34, 0.13, 0.32), Vector3(0.0, 0.17, 0.02), mat_azul_oscuro)
	_box(_cabeza, Vector3(0.40, 0.045, 0.22), Vector3(0.0, 0.11, -0.16), mat_azul_oscuro)
	_box(_cabeza, Vector3(0.10, 0.05, 0.03), Vector3(0.0, 0.12, -0.20), mat_metal)
	# Bigote y ceño de guardia malhumorado
	_box(_cabeza, Vector3(0.12, 0.035, 0.03), Vector3(0.0, -0.03, -0.17), mat_pelo)

	_linterna = Node3D.new()
	_linterna.position = Vector3(-0.34, 1.36, 0.0)
	_raiz.add_child(_linterna)
	_cyl(_linterna, 0.06, 0.08, 0.18, Vector3.ZERO, mat_metal, Vector3(PI * 0.5, 0.0, 0.0))
	_sphere(_linterna, 0.075, Vector3(0.0, 0.0, -0.10), _mat(Color("#fff6c2"), 0.2, Color("#ffe082"), 4.0))

	# Perro policía estilizado, corriendo junto al guardia
	_perro = Node3D.new()
	_perro.name = "Perro"
	_perro.position = Vector3(0.62, 0.0, 0.25)
	add_child(_perro)
	_sphere(_perro, 0.20, Vector3(0.0, 0.42, 0.0), mat_perro, Vector3(1.15, 0.85, 1.5))
	_perro_cabeza = Node3D.new()
	_perro_cabeza.position = Vector3(0.0, 0.58, -0.34)
	_perro.add_child(_perro_cabeza)
	_sphere(_perro_cabeza, 0.17, Vector3.ZERO, mat_perro)
	_sphere(_perro_cabeza, 0.10, Vector3(0.0, 0.02, -0.15), mat_perro_claro, Vector3(0.9, 0.8, 1.1))
	_box(_perro_cabeza, Vector3(0.08, 0.10, 0.06), Vector3(-0.08, 0.16, 0.0), mat_perro)
	_box(_perro_cabeza, Vector3(0.08, 0.10, 0.06), Vector3(0.08, 0.16, 0.0), mat_perro)
	_perro_cola = Node3D.new()
	_perro_cola.position = Vector3(0.0, 0.48, 0.30)
	_perro.add_child(_perro_cola)
	_box(_perro_cola, Vector3(0.06, 0.06, 0.26), Vector3(0.0, 0.06, 0.10), mat_perro, Vector3(-0.5, 0.0, 0.0))
	for lx in [-0.12, 0.12]:
		_box(_perro, Vector3(0.09, 0.28, 0.10), Vector3(lx, 0.14, -0.16), mat_perro_claro)
		_box(_perro, Vector3(0.09, 0.28, 0.10), Vector3(lx, 0.14, 0.18), mat_perro_claro)

	visible = false


func _crear_sombra(escala: float) -> MeshInstance3D:
	var pl := PlaneMesh.new()
	pl.size = Vector2(1.2, 1.2)
	var mi := MeshInstance3D.new()
	mi.mesh = pl
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.02, 0.05, 0.12, 0.35)
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mi.material_override = mat
	mi.scale = Vector3(escala, 1.0, escala)
	mi.position = Vector3(0.0, 0.02, 0.0)
	add_child(mi)
	return mi


## Actualiza la persecución. `distancia` es la separación en metros (+Z).
func actualizar(distancia: float, tiempo: float, jugador_x: float, suelo_y: float, corriendo: bool, atrapando: bool = false) -> void:
	_tiempo = tiempo
	_ultima_distancia = distancia
	visible = distancia < 55.0 or atrapando
	if not visible:
		return

	var cerca: float = clampf(1.0 - (distancia - 10.0) / 60.0, 0.0, 1.0)
	var cadencia: float = 10.5 if corriendo else 2.0
	if cerca > 0.55:
		cadencia = 13.5
	var ciclo: float = tiempo * cadencia
	var zan: float = sin(ciclo)
	var rebote: float = absf(cos(ciclo)) * 0.055

	position = Vector3(jugador_x * 0.78, suelo_y + rebote, distancia)
	rotation.y = 0.0 if not atrapando else 0.35

	_raiz.position = Vector3.ZERO
	_raiz.rotation.x = -0.16 if corriendo else 0.0
	_pierna_izq.rotation.x = zan * 0.78
	_pierna_der.rotation.x = -zan * 0.78
	_brazo_izq.rotation.x = -zan * 0.62 + 0.15
	_brazo_der.rotation.x = zan * 0.62 - 0.35
	_cuerpo.rotation.z = zan * 0.04
	_cabeza.rotation.y = sin(tiempo * 2.2) * 0.10
	_cabeza.rotation.z = sin(tiempo * 1.4) * 0.04

	_perro.position = Vector3(0.62 + sin(ciclo * 0.5) * 0.06, 0.0, 0.25 + cos(ciclo) * 0.08)
	_perro.rotation.x = -0.10
	_perro_cabeza.rotation.x = sin(ciclo * 2.0) * 0.10
	_perro_cola.rotation.y = sin(tiempo * 9.0) * 0.55
	_perro.position.y = absf(sin(ciclo)) * 0.08

	if atrapando:
		_raiz.rotation.x = -0.34
		_pierna_izq.rotation.x = 0.30
		_pierna_der.rotation.x = -0.18
		_brazo_izq.rotation = Vector3(-1.55, 0.0, -0.30)
		_brazo_der.rotation = Vector3(-1.55, 0.0, 0.30)
		_cabeza.rotation.x = 0.18
		_perro_cabeza.rotation.x = -0.25
		_perro_cola.rotation.y = sin(tiempo * 18.0) * 0.9

	_linterna.rotation.z = (-0.25 + sin(tiempo * 4.0) * 0.08) if not atrapando else -0.55
	_sombra_guardia.position = Vector3(0.0, 0.025 - rebote, 0.0)
	_sombra_perro.position = Vector3(0.62, 0.025 - rebote, 0.25)

	# Al acercarse, el guardia agranda su zancada y el perro ladra en silencio.
	var escala: float = 1.0 + cerca * 0.06
	_raiz.scale = Vector3.ONE * escala
	_perro.scale = Vector3.ONE * (1.0 + cerca * 0.08)
