extends Node

# Herramienta de QA visual: abre la escena principal, entra en Tienda >
# Bienestar y guarda capturas del viewport en user://capturas_bienestar.
# No forma parte del juego ni se ejecuta en producción.
#
# Uso:
#   godot --path . --resolution 540x960 res://Escenas/Herramientas/Captura_Bienestar.tscn

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
	await get_tree().create_timer(1.0).timeout
	var bienestar := escena.get_node_or_null("Tienda/Objetos_Ventajas") as Tienda_Bienestar
	if bienestar == null:
		push_error("No se encontró Tienda/Objetos_Ventajas")
		get_tree().quit()
		return
	# Estado de muestra para que la clínica no salga bloqueada por tener 18 años.
	Variables_Dinamicas.Minute_Day = Variables_Estaticas.First_Time_Minute_Day + 140
	Variables_Dinamicas.Rejuvenecimiento_Anios = 3
	Variables_Dinamicas.Tratamientos_Rejuvenecimiento = 2
	Variables_Dinamicas.Dinero = 2450.0
	bienestar._Sincronizar(false)
	await get_tree().process_frame
	await _Capturar("bienestar_01_hub.png")
	var scroll: ScrollContainer = bienestar._scroll
	if scroll != null:
		scroll.scroll_vertical = 720
		await get_tree().process_frame
		await get_tree().process_frame
		await _Capturar("bienestar_02_hub_abajo.png")
		scroll.scroll_vertical = 0
		await get_tree().process_frame
	bienestar._Abrir_Tratamiento(Recompensas_Catalogo.Obtener_Producto("servicio_spa"))
	await get_tree().create_timer(0.55).timeout
	await _Capturar("bienestar_03_tratamiento.png")
	if bienestar._modal_tratamiento != null and is_instance_valid(bienestar._modal_tratamiento):
		bienestar._modal_tratamiento.Mostrar_Procesando()
		await get_tree().create_timer(0.3).timeout
		await _Capturar("bienestar_04_tratamiento_procesando.png")
		bienestar._modal_tratamiento.Mostrar_Exito({
			"ok": true, "dinero": 600.0, "edad": Variables_Estaticas.Calcular_Edad() - 1,
			"recompensas": [{"tipo": "rejuvenecer", "cantidad": 1}],
		})
		await get_tree().create_timer(0.45).timeout
		await _Capturar("bienestar_05_tratamiento_exito.png")
		bienestar._modal_tratamiento.queue_free()
		bienestar._modal_tratamiento = null
	await get_tree().process_frame
	bienestar._Ver_Anuncio(Recompensas_Catalogo.Obtener_Producto("anuncio_dinero"))
	await get_tree().create_timer(2.2).timeout
	await _Capturar("bienestar_06_anuncio.png")
	if bienestar._modal_anuncio != null and is_instance_valid(bienestar._modal_anuncio):
		bienestar._modal_anuncio.Mostrar_Recompensa({
			"ok": true, "dinero": Variables_Dinamicas.Dinero + 150.0,
			"recompensas": [{"tipo": "euros", "cantidad": 150}],
		})
		await get_tree().create_timer(1.0).timeout
		await _Capturar("bienestar_07_recompensa.png")
		var token: int = bienestar._modal_anuncio.token
		if token > 0:
			Recompensas.Cancelar_Anuncio(token)
		bienestar._modal_anuncio.queue_free()
		bienestar._modal_anuncio = null
	Recompensas._cooldowns["anuncio_dinero"] = int(Time.get_unix_time_from_system()) + 46
	Recompensas._cooldowns["anuncio_bienestar"] = int(Time.get_unix_time_from_system()) + 185
	bienestar._Sincronizar(false)
	if scroll != null:
		scroll.scroll_vertical = 520
	await get_tree().create_timer(0.35).timeout
	await _Capturar("bienestar_08_cooldown.png")
	bienestar._Mostrar_Toast("Tratamiento aplicado · −1 año", "exito")
	await get_tree().create_timer(0.35).timeout
	await _Capturar("bienestar_09_toast.png")
	Recompensas.Reiniciar_Esperas()
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
