extends Node
## QA de variantes de escena: comedor básico/premium, calle y tiempo libre
## en la calle, a tamaño de tarjeta grande y de Home.
## Uso:
##   godot --path . --resolution 720x1280 res://Escenas/Herramientas/Captura_Variantes_Inicio.tscn

const DIR_SALIDA := "user://capturas_variantes_inicio"
const TAM_GRANDE := Vector2(640.0, 219.0)
const TAM_HOME := Vector2(664.0, 184.0)


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR_SALIDA))
	await get_tree().process_frame
	var casos := [
		{"nombre": "comer_basica", "act": "Comer_Tupper", "calle": false, "objeto": "Mesa_Basica"},
		{"nombre": "comer_premium", "act": "Comer_Tupper", "calle": false, "objeto": "Mesa_Premium"},
		{"nombre": "comer_calle", "act": "Comer_Basura", "calle": true, "objeto": "Mesa_Basica"},
		{"nombre": "idle_calle", "act": "", "calle": true, "objeto": "Mesa_Basica"},
	]
	for tam in [TAM_GRANDE, TAM_HOME]:
		var sufijo := "grande" if tam == TAM_GRANDE else "home"
		for caso in casos:
			await _capturar("%s_%s.png" % [caso["nombre"], sufijo], tam, str(caso["act"]), bool(caso["calle"]), str(caso["objeto"]))
	print("Variantes guardadas en ", ProjectSettings.globalize_path(DIR_SALIDA))
	get_tree().quit()


func _capturar(nombre: String, tam: Vector2, actividad: String, calle: bool, objeto: String) -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(int(tam.x) + 32, int(tam.y) + 32)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var fondo := ColorRect.new()
	fondo.color = Color("#dbe4ee")
	fondo.size = Vector2(vp.size)
	vp.add_child(fondo)
	var escenario := Escenario_Actividad.new()
	escenario.position = Vector2(16.0, 16.0)
	escenario.size = tam
	escenario.custom_minimum_size = tam
	vp.add_child(escenario)
	escenario.actualizar_estado(actividad, calle, Apariencia_Personaje.por_defecto(), 1080, objeto, "Deportista")
	await get_tree().create_timer(0.7).timeout
	await RenderingServer.frame_post_draw
	var imagen := vp.get_texture().get_image()
	if imagen != null and not imagen.is_empty():
		imagen.save_png(DIR_SALIDA.path_join(nombre))
		print("Captura: ", DIR_SALIDA.path_join(nombre))
	vp.queue_free()
	await get_tree().process_frame
