class_name Runner_Guardia_3D
extends Node3D

# ============================================================================
# GUARDIA Y PERRO PERSECUTOR (MODELOS BLENDER GLB)
#
# Carga `guardia.glb` y `perro_policia.glb` respetando su jerarquía articulada
# de nodos (`Torso`, `Cabeza`, `Brazo_Izq`, `Brazo_Der`, `Pierna_Izq`,
# `Pierna_Der`, `Linterna`, `Cuerpo`, `Pata_DI/DD/TI/TD`, `Cola`) y aplica
# el contorno de tinta estilizado (#111827).
# ============================================================================

const TINTA := Color("#111827")
const RUTA_GUARDIA_GLB := "res://Modelos/Minijuego_Correr/guardia.glb"
const RUTA_PERRO_GLB := "res://Modelos/Minijuego_Correr/perro_policia.glb"

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
var _perro_pata_di: Node3D
var _perro_pata_dd: Node3D
var _perro_pata_ti: Node3D
var _perro_pata_td: Node3D
var _sombra_guardia: MeshInstance3D
var _sombra_perro: MeshInstance3D
var _linterna: Node3D
var _tiempo: float = 0.0
var _ultima_distancia: float = 70.0


func _init() -> void:
	name = "Runner_Guardia_3D"
	_construir()


static func _cargar_glb(ruta: String) -> Node3D:
	if ResourceLoader.exists(ruta):
		var ps := ResourceLoader.load(ruta) as PackedScene
		if ps != null:
			var inst := ps.instantiate() as Node3D
			if inst != null:
				return inst
	var abs_path := ProjectSettings.globalize_path(ruta)
	if FileAccess.file_exists(abs_path):
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		if doc.append_from_file(abs_path, state) == OK:
			return doc.generate_scene(state) as Node3D
	push_error("No se pudo cargar GLB de personaje: %s" % ruta)
	return Node3D.new()


static func _aplicar_contorno_suave(nodo: Node) -> void:
	var outline := StandardMaterial3D.new()
	outline.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	outline.cull_mode = BaseMaterial3D.CULL_FRONT
	outline.albedo_color = TINTA
	outline.grow = true
	outline.grow_amount = 0.010

	var cola: Array[Node] = [nodo]
	while not cola.is_empty():
		var act: Node = cola.pop_back()
		for ch in act.get_children():
			cola.append(ch)
		if act is MeshInstance3D:
			var mi := act as MeshInstance3D
			if mi.mesh == null:
				continue
			var m_dup: Mesh = mi.mesh.duplicate()
			mi.mesh = m_dup
			for s in range(m_dup.get_surface_count()):
				var orig := m_dup.surface_get_material(s) as StandardMaterial3D
				if orig == null:
					continue
				var cop := orig.duplicate() as StandardMaterial3D
				cop.metallic_specular = 0.12
				if cop.resource_name != "Guardia_Foco" and not (cop.emission_enabled and cop.emission_energy_multiplier > 1.5):
					cop.next_pass = outline
				m_dup.surface_set_material(s, cop)


func _construir() -> void:
	_sombra_guardia = _crear_sombra(0.85)
	_sombra_perro = _crear_sombra(0.55)

	_raiz = _cargar_glb(RUTA_GUARDIA_GLB)
	_raiz.name = "Guardia"
	add_child(_raiz)
	_aplicar_contorno_suave(_raiz)

	_cuerpo = _find_node(_raiz, "Torso")
	_cabeza = _find_node(_raiz, "Cabeza")
	_brazo_izq = _find_node(_raiz, "Brazo_Izq")
	_brazo_der = _find_node(_raiz, "Brazo_Der")
	_pierna_izq = _find_node(_raiz, "Pierna_Izq")
	_pierna_der = _find_node(_raiz, "Pierna_Der")
	_linterna = _find_node(_raiz, "Linterna")

	_perro = _cargar_glb(RUTA_PERRO_GLB)
	_perro.name = "Perro"
	_perro.position = Vector3(0.46, 0.0, -0.34)
	add_child(_perro)
	_aplicar_contorno_suave(_perro)

	_perro_cabeza = _find_node(_perro, "Cabeza")
	_perro_cola = _find_node(_perro, "Cola")
	_perro_pata_di = _find_node(_perro, "Pata_DI")
	_perro_pata_dd = _find_node(_perro, "Pata_DD")
	_perro_pata_ti = _find_node(_perro, "Pata_TI")
	_perro_pata_td = _find_node(_perro, "Pata_TD")

	visible = false


static func _find_node(raiz: Node, nombre: String) -> Node3D:
	if raiz.name == nombre and raiz is Node3D:
		return raiz as Node3D
	var found := raiz.find_child(nombre, true, false) as Node3D
	if found != null:
		return found
	# Fallback seguro si faltase algún subnodo en un entorno parcial
	var dummy := Node3D.new()
	dummy.name = nombre + "_Fallback"
	raiz.add_child(dummy)
	return dummy


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
	_brazo_izq.rotation = Vector3(-zan * 0.62 - 0.15, 0.0, 0.0)
	_brazo_der.rotation = Vector3(zan * 0.62 - 0.35, 0.0, 0.0)
	_cuerpo.rotation.z = zan * 0.04
	_cabeza.rotation = Vector3(0.0, sin(tiempo * 2.2) * 0.10, sin(tiempo * 1.4) * 0.04)

	_perro.position = Vector3(0.46 + sin(ciclo * 0.5) * 0.06, absf(sin(ciclo)) * 0.08, -0.34 + cos(ciclo) * 0.08)
	_perro.rotation.x = -0.08 + cos(ciclo) * 0.06
	_perro_cabeza.rotation.x = sin(ciclo * 2.0) * 0.10
	_perro_cola.rotation.y = sin(tiempo * 9.0) * 0.55
	_perro_pata_di.rotation.x = zan * 0.68 - 0.12
	_perro_pata_dd.rotation.x = zan * 0.68 + 0.10
	_perro_pata_ti.rotation.x = -zan * 0.68 - 0.10
	_perro_pata_td.rotation.x = -zan * 0.68 + 0.12

	if atrapando:
		_raiz.rotation.x = -0.26
		_pierna_izq.rotation.x = 0.30
		_pierna_der.rotation.x = -0.18
		_brazo_izq.rotation = Vector3(-1.45, 0.0, -0.22)
		_brazo_der.rotation = Vector3(-1.45, 0.0, 0.22)
		_cabeza.rotation.x = 0.14
		_perro_cabeza.rotation.x = -0.22
		_perro_cola.rotation.y = sin(tiempo * 18.0) * 0.9

	_linterna.rotation.y = (sin(tiempo * 4.0) * 0.10) if not atrapando else 0.0
	_sombra_guardia.position = Vector3(0.0, 0.025 - rebote, 0.0)
	_sombra_perro.position = Vector3(0.46, 0.025 - rebote, -0.34)

	var escala: float = 1.0 + cerca * 0.06
	_raiz.scale = Vector3.ONE * escala
	_perro.scale = Vector3.ONE * (1.0 + cerca * 0.08)
