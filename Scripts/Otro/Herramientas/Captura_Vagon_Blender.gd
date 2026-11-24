extends Node

# Captura de comparación: vagón de metro procedural (código) frente al vagón
# modelado en Blender (Modelos/Minijuego_Correr/vagon_metro.glb).
#
# Los dos reciben el mismo shader curvo del escenario para que la comparación
# sea justa: la única diferencia es la geometría.
#
# Uso:
#   xvfb-run -a godot --path . res://Escenas/Herramientas/Captura_Vagon_Blender.tscn

const DIR_SALIDA := "user://capturas_vagon"
const RUTA_GLB := "res://Modelos/Minijuego_Correr/vagon_metro.glb"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR_SALIDA))
	Variables_Dinamicas.Minute_Minute = 900
	await get_tree().process_frame

	var vp := SubViewport.new()
	vp.size = Vector2i(720, 1280)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	var mini: Control = load("res://Escenas/Minijuego_Correr/Minijuego_Correr.tscn").instantiate()
	vp.add_child(mini)
	await _esperar_frames(8)

	var mundo: Runner_Mundo = mini._mundo
	var sim: Runner_Simulacion = mundo.simulacion
	var escenario: Runner_Escenario_3D = mundo._escenario

	mini._menu.visible = false
	mini._hud.visible = false
	mini._estado = "jugando"
	mundo.iniciar(mini._Apariencia_Actual(), -1, false)
	mundo.pausar(true)

	sim.obstaculos.clear()
	sim.monedas_entidades.clear()
	sim.powerups_entidades.clear()
	sim.distancia = 420.0
	sim.puntuacion = 4200.0
	sim.jugador["carril_objetivo"] = 0
	sim.jugador["x"] = 0.0
	sim.jugador["y"] = 0.0
	sim.jugador["ciclo_carrera"] = 1.2
	mundo.forzar_sincronizacion_visual()

	# --- Izquierda: vagón actual, generado por código -------------------------
	var proc: Node3D = escenario.crear_seto_alto({"largo": 13.5, "altura": 3.05, "librea": 0})
	proc.position = Vector3(-2.7, 0.0, -17.0)
	mundo._raiz_3d.add_child(proc)

	# --- Derecha: vagón de Blender -------------------------------------------
	var escena_glb: PackedScene = load(RUTA_GLB)
	var instancia: Node3D = escena_glb.instantiate()
	var malla: MeshInstance3D = _buscar_malla(instancia)
	if malla == null:
		push_error("No se encontró MeshInstance3D en %s" % RUTA_GLB)
	else:
		_aplicar_shader_curvo(malla, escenario)
	instancia.position = Vector3(2.7, 0.0, -17.0)
	mundo._raiz_3d.add_child(instancia)

	await _esperar_frames(6)
	_Guardar(vp, "01_comparacion.png")

	# Plano corto: solo el de Blender, más cerca y desde el morro
	proc.visible = false
	instancia.position = Vector3(0.0, 0.0, -12.0)
	await _esperar_frames(4)
	_Guardar(vp, "02_blender_cerca.png")

	print("Capturas en ", ProjectSettings.globalize_path(DIR_SALIDA))
	get_tree().quit()


## Sustituye los materiales del .glb por el shader curvo del escenario,
## conservando el color de cada superficie.
func _aplicar_shader_curvo(malla: MeshInstance3D, escenario: Runner_Escenario_3D) -> void:
	var malla_3d: Mesh = malla.mesh
	for i in range(malla_3d.get_surface_count()):
		var original: Material = malla_3d.surface_get_material(i)
		var mat: ShaderMaterial = escenario._convertir_material_glb("vagon_metro", original)
		malla.set_surface_override_material(i, mat)


func _buscar_malla(nodo: Node) -> MeshInstance3D:
	if nodo is MeshInstance3D:
		return nodo
	for hijo in nodo.get_children():
		var encontrada: MeshInstance3D = _buscar_malla(hijo)
		if encontrada != null:
			return encontrada
	return null


func _esperar_frames(n: int) -> void:
	for _i in range(n):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw


func _Guardar(vp: SubViewport, nombre: String) -> void:
	var imagen: Image = vp.get_texture().get_image()
	if imagen == null:
		push_error("No se pudo capturar %s" % nombre)
		return
	imagen.save_png("%s/%s" % [DIR_SALIDA, nombre])
