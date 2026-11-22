extends Node
## QA visual de integración: captura la tarjeta real del Home con cada pose
## forzada, para comprobar encuadre, tamaño y legibilidad en el juego.
## Uso:
##   godot --path . --resolution 720x1280 res://Escenas/Herramientas/Captura_Home_Poses.tscn

const DIR_SALIDA := "user://capturas_home_poses"
const POSES := ["idle", "correr", "dormir", "comer", "duchar", "estudiar", "tv", "manualidades", "cocinar", "fiesta", "futbol", "trabajar"]


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR_SALIDA))
	Variables_Estaticas.Tutorial_Completado = true
	var vp := SubViewport.new()
	vp.size = Vector2i(720, 1280)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var escena: Node = load("res://Escenas/Escena_Principal/Escena principal.tscn").instantiate()
	vp.add_child(escena)
	await get_tree().process_frame
	await get_tree().process_frame
	escena.set_process(false)
	var tutorial: Node = escena.get_node_or_null("Tutorial_Inicial")
	if tutorial != null:
		tutorial.queue_free()
		await get_tree().process_frame
	var escenario: Escenario_Actividad = escena.get("_home_escenario")
	if escenario == null:
		push_error("No se encontró el escenario del Home")
		get_tree().quit()
		return
	for pose in POSES:
		Debug_Pose_Inicio.POSE_FORZADA = pose
		escenario.actualizar_estado("", false, Apariencia_Personaje.por_defecto(), 780, "Mesa_Premium", "Deportista")
		await get_tree().create_timer(0.7).timeout
		await RenderingServer.frame_post_draw
		var imagen := vp.get_texture().get_image()
		if imagen != null and not imagen.is_empty():
			imagen.save_png(DIR_SALIDA.path_join("home_%s.png" % pose))
			print("Captura: ", DIR_SALIDA.path_join("home_%s.png" % pose))
	Debug_Pose_Inicio.POSE_FORZADA = "0"
	print("Capturas del Home guardadas en ", ProjectSettings.globalize_path(DIR_SALIDA))
	get_tree().quit()
