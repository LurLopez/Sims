extends Node

# Herramienta de QA visual para el escenario de tiempo libre.
# Uso:
#   godot --headless --path . res://Escenas/Herramientas/Captura_Tiempo_Libre.tscn

const DIR_SALIDA := "user://capturas_tiempo_libre"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR_SALIDA))
	await get_tree().process_frame
	await _Capturar_Escenario("tiempo_libre_home.png", Vector2(640.0, 219.0), 600, false, "Deportista")
	await _Capturar_Escenario("tiempo_libre_menu.png", Vector2(450.0, 184.0), 600, false, "")
	await _Capturar_Escenario("tiempo_libre_calle.png", Vector2(640.0, 219.0), 600, true, "Deportista")
	await _Capturar_Home_Real()
	print("Capturas de tiempo libre guardadas en ", ProjectSettings.globalize_path(DIR_SALIDA))
	get_tree().quit()


func _Capturar_Home_Real() -> void:
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
	if escenario != null:
		escenario.actualizar_estado("", false, Apariencia_Personaje.por_defecto(), 600, "Mesa_Basica", "Deportista")
		await get_tree().create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		var imagen := vp.get_texture().get_image()
		if imagen != null and not imagen.is_empty():
			imagen.save_png(DIR_SALIDA.path_join("tiempo_libre_home_real.png"))
			print("Captura: ", DIR_SALIDA.path_join("tiempo_libre_home_real.png"))
	vp.queue_free()


func _Capturar_Escenario(nombre: String, tam: Vector2, minuto: int, calle: bool, personalidad: String) -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(int(tam.x) + 40, int(tam.y) + 40)
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	var fondo := ColorRect.new()
	fondo.color = Color("#dbe4ee")
	fondo.size = Vector2(vp.size)
	vp.add_child(fondo)

	var escenario := Escenario_Actividad.new()
	escenario.position = Vector2(20.0, 20.0)
	escenario.size = tam
	escenario.custom_minimum_size = tam
	vp.add_child(escenario)
	escenario.actualizar_estado("", calle, Apariencia_Personaje.por_defecto(), minuto, "Mesa_Basica", personalidad)
	await get_tree().process_frame
	await get_tree().process_frame
	escenario._disparar_variacion_aleatoria()
	await get_tree().create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	var imagen := vp.get_texture().get_image()
	if imagen != null and not imagen.is_empty():
		var ruta := DIR_SALIDA.path_join(nombre)
		imagen.save_png(ruta)
		print("Captura: ", ruta)
	vp.queue_free()
