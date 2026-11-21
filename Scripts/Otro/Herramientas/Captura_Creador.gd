extends Node

# Herramienta de QA visual: abre el creador de personaje en un SubViewport
# 720x1280 y guarda capturas de cada pestaña en user://capturas_creador.
#
# Uso:
#   godot --path . res://Escenas/Herramientas/Captura_Creador.tscn

const DIR_SALIDA := "user://capturas_creador"
const CREADOR := preload("res://Scripts/GUI/Menu/Creador_Personaje.gd")

var _vp: SubViewport


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR_SALIDA))
	await get_tree().process_frame
	_vp = SubViewport.new()
	_vp.size = Vector2i(720, 1280)
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)
	var creador := CREADOR.new()
	_vp.add_child(creador)
	await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	for tab in ["identidad", "cuerpo", "cara", "pelo", "ropa", "extras"]:
		creador._cambiar_tab(tab)
		await get_tree().process_frame
		await get_tree().process_frame
		await _Capturar("creador_%s.png" % tab)
		var scroll: ScrollContainer = creador._scroll
		if scroll != null:
			scroll.scroll_vertical = 500
			await get_tree().process_frame
			await get_tree().process_frame
			await _Capturar("creador_%s_scroll.png" % tab)
			scroll.scroll_vertical = 0
	# Variante mujer: vello facial no disponible y botón para cambiar de género.
	creador._on_seleccionar_genero("mujer")
	await get_tree().process_frame
	creador._ir_a_paso(3)
	await get_tree().process_frame
	await get_tree().process_frame
	await _Capturar("creador_pelo_mujer.png")
	var scroll_m: ScrollContainer = creador._scroll
	if scroll_m != null:
		scroll_m.scroll_vertical = 800
		await get_tree().process_frame
		await get_tree().process_frame
		await _Capturar("creador_pelo_mujer_scroll.png")
	print("Capturas guardadas en ", ProjectSettings.globalize_path(DIR_SALIDA))
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
		push_error("Error guardando %s: %s" % [ruta, error_string(error)])
	else:
		print("Captura: ", ruta, " (", imagen.get_width(), "x", imagen.get_height(), ")")
