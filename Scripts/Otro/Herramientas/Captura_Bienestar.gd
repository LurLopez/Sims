extends Node

# Herramienta de QA visual: abre la escena principal, entra en Tienda >
# Ventajas y guarda capturas del viewport en user://capturas_bienestar.
# No forma parte del juego ni se ejecuta en producción.

const DIR_SALIDA := "user://capturas_bienestar"

var _vp: SubViewport


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR_SALIDA))
	await get_tree().process_frame
	Variables_Estaticas.Tutorial_Completado = true
	Recompensas._ruta_guardado = "user://captura_bienestar.cfg"
	_vp = SubViewport.new()
	_vp.name = "Viewport_Captura"
	_vp.size = Vector2i(720, 1280)
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)
	var escena: Node = load("res://Escenas/Escena_Principal/Escena principal.tscn").instantiate()
	_vp.add_child(escena)
	await get_tree().process_frame
	await get_tree().process_frame
	# Congela el reloj del juego para no alterar la partida del usuario.
	escena.set_process(false)
	escena.set_process_unhandled_input(false)
	escena._on_tienda_button_pressed()
	await get_tree().process_frame
	escena._on_tab_ventajas_pressed()
	await get_tree().create_timer(0.8).timeout
	var bienestar := escena.get_node_or_null("Tienda/Objetos_Ventajas") as Tienda_Bienestar
	if bienestar == null:
		push_error("No se encontró Tienda/Objetos_Ventajas")
		get_tree().quit()
		return
	Variables_Dinamicas.Minute_Day = Variables_Estaticas.First_Time_Minute_Day + 140
	Variables_Dinamicas.Rejuvenecimiento_Anios = 3
	Variables_Dinamicas.Tratamientos_Rejuvenecimiento = 2
	Variables_Dinamicas.Dinero = 2450.0
	bienestar._Sincronizar(false)
	await get_tree().process_frame
	await get_tree().process_frame
	await _Capturar("bienestar_01_hub.png")
	var scroll: ScrollContainer = bienestar._scroll
	if scroll != null:
		scroll.scroll_vertical = 680
		await get_tree().process_frame
		await get_tree().process_frame
		await _Capturar("bienestar_02_hub_abajo.png")
		scroll.scroll_vertical = 0
		await get_tree().process_frame
	bienestar._Seleccionar_Filtro("compras")
	bienestar._Mostrar_Toast("No disponible en esta beta", "info")
	await get_tree().create_timer(0.35).timeout
	await _Capturar("bienestar_03_compras_toast.png")
	bienestar._Seleccionar_Filtro("clinica")
	await get_tree().process_frame
	await get_tree().process_frame
	await _Capturar("bienestar_04_clinica.png")
	bienestar._Abrir_Tratamiento(Recompensas_Catalogo.Obtener_Producto("servicio_spa"))
	await get_tree().create_timer(0.45).timeout
	await _Capturar("bienestar_05_tratamiento.png")
	if bienestar._modal_tratamiento != null and is_instance_valid(bienestar._modal_tratamiento):
		bienestar._modal_tratamiento.queue_free()
		bienestar._modal_tratamiento = null
	print("Capturas de bienestar guardadas en ", ProjectSettings.globalize_path(DIR_SALIDA))
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
