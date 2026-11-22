extends Node

# Captura de QA visual: abre la Tienda y guarda sus pestañas de muebles y Bienestar.
# No forma parte del juego ni se ejecuta en producción.
#
# Uso:
#   godot --headless --path . res://Escenas/Herramientas/Captura_Tienda.tscn

const DIR_SALIDA := "user://capturas_tienda"

var _vp: SubViewport


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR_SALIDA))
	await get_tree().process_frame
	Variables_Estaticas.Tutorial_Completado = true
	_vp = SubViewport.new()
	_vp.size = Vector2i(720, 1280)
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)
	var escena: Node = load("res://Escenas/Escena_Principal/Escena principal.tscn").instantiate()
	_vp.add_child(escena)
	await get_tree().process_frame
	await get_tree().process_frame
	escena.set_process(false)
	escena.set_process_unhandled_input(false)
	escena._on_tienda_button_pressed()
	await get_tree().create_timer(0.7).timeout
	await _Capturar("tienda_01_dormir.png")
	escena._on_tab_comer_pressed()
	await get_tree().create_timer(0.4).timeout
	await _Capturar("tienda_02_comer.png")
	escena._on_tab_duchar_pressed()
	await get_tree().create_timer(0.4).timeout
	await _Capturar("tienda_03_duchar.png")
	escena._on_tab_salon_pressed()
	await get_tree().create_timer(0.4).timeout
	await _Capturar("tienda_04_salon.png")
	escena._on_tab_estudio_pressed()
	await get_tree().create_timer(0.4).timeout
	await _Capturar("tienda_05_estudio.png")
	escena._on_tab_cocina_pressed()
	await get_tree().create_timer(0.4).timeout
	await _Capturar("tienda_06_cocina.png")
	escena._on_tab_ventajas_pressed()
	await get_tree().create_timer(0.9).timeout
	await _Capturar("tienda_07_ventajas.png")
	# Estado de muestra: un mueble equipado y varios en propiedad para revisar
	# los botones Equipar/Vender y los estados de las tarjetas. No se guarda.
	Variables_Dinamicas.Objetos_Poseidos["Cama_Nube"] = true
	Variables_Dinamicas.Objetos_Poseidos["Cama_Imperial"] = true
	Variables_Dinamicas.Objeto_Seleccionado["Dormir"] = "Cama_Nube"
	escena._on_tab_dormir_pressed()
	await get_tree().create_timer(0.4).timeout
	await _Capturar("tienda_08_estados.png")
	print("Capturas de tienda guardadas en ", ProjectSettings.globalize_path(DIR_SALIDA))
	get_tree().quit()


func _Capturar(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	var imagen := _vp.get_texture().get_image()
	if imagen == null or imagen.is_empty():
		push_error("No se pudo capturar %s" % nombre)
		return
	var ruta := DIR_SALIDA.path_join(nombre)
	var error := imagen.save_png(ruta)
	if error != OK:
		push_error("Error %d guardando %s" % [error, ruta])
	else:
		print("Captura: ", ruta)
