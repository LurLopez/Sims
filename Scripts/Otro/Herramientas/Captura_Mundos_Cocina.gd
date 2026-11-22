extends Node

# Capturas de QA de los tres mundos nuevos del minijuego de cocina.
# Uso: xvfb-run -a godot --path . res://Escenas/Herramientas/Captura_Mundos_Cocina.tscn

const DIR_SALIDA := "user://capturas_mundos_cocina"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR_SALIDA))
	await get_tree().process_frame
	await _Capturar_Mundo("bistro_tradicional", "mundo_bistro.png", _Preparar_Bistro)
	await _Capturar_Mundo("cocina_mercado", "mundo_mercado.png", _Preparar_Mercado)
	await _Capturar_Mundo("alta_cocina", "mundo_alta_cocina.png", _Preparar_Alta)
	print("Capturas de mundos guardadas en ", ProjectSettings.globalize_path(DIR_SALIDA))
	get_tree().quit()


func _Capturar_Mundo(restaurante: String, nombre: String, preparar: Callable) -> void:
	Variables_Dinamicas.Cocina_Estado = Variables_Dinamicas.Cocina_Estado_Por_Defecto()
	Variables_Dinamicas.Cocina_Estado["restaurantes_desbloqueados"] = [
		"burger_street", "bistro_tradicional", "cocina_mercado", "alta_cocina"
	]
	Variables_Dinamicas.Necesidades_Basicas = [80, 80, 80, 80, 80]
	Variables_Estaticas.Habilidades = [50, 50, 50, 50, 50, 50, 50]

	var vp := SubViewport.new()
	vp.size = Vector2i(1280, 720)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	var mini: Control = load("res://Escenas/Minijuego_Cocina/Minijuego_Cocina.tscn").instantiate()
	vp.add_child(mini)
	await get_tree().process_frame
	await get_tree().process_frame
	mini._restaurante_actual = restaurante
	mini._restaurante_expandido = restaurante
	mini._Iniciar_Nivel(1)
	await get_tree().process_frame
	mini._spawn_timer = 9999.0
	await preparar.call(mini)
	await get_tree().create_timer(1.2).timeout
	await RenderingServer.frame_post_draw
	_Guardar(vp, nombre)
	# Modal de inicio con el menú y la explicación de la mecánica
	mini._Abrir_Modal_Inicio(1)
	await get_tree().create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	_Guardar(vp, nombre.replace(".png", "_modal.png"))
	# Pantalla de mejoras con el nombre adaptado al mundo
	mini._modal_inicio.visible = false
	mini._Abrir_Modal_Mejoras()
	await get_tree().create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	_Guardar(vp, nombre.replace(".png", "_mejoras.png"))
	# Mapa de niveles del mundo (fondo del local detrás del panel)
	mini._modal_mejoras.visible = false
	mini._Mostrar_Mapa()
	mini._restaurante_expandido = restaurante
	mini._Refrescar_Mapa()
	await get_tree().create_timer(0.7).timeout
	await RenderingServer.frame_post_draw
	_Guardar(vp, nombre.replace(".png", "_mapa.png"))
	vp.queue_free()
	await get_tree().process_frame


func _Preparar_Bistro(mini: Control) -> void:
	_Forzar_Cliente(mini, 0, ["filete_patatas", "cafe"])
	_Forzar_Cliente(mini, 1, ["filete_completo", "tarta_cereza"])
	# Un filete al punto en la parrilla y otro poco hecho
	mini._on_origen_tocado({}, {"datos": {"tipo": "bandeja", "ingrediente": "carne"}})
	mini._on_origen_tocado({}, {"datos": {"tipo": "bandeja", "ingrediente": "carne"}})
	mini._Tick_Slots_Coccion(mini._plancha, mini._slots_plancha_ui,
		mini._tiempo_coccion_carne, "Carne", mini._tiempo_coccion_carne * 0.64)
	# Patatas listas en el pase y salsa
	mini._on_origen_tocado({}, {"datos": {"tipo": "bandeja", "ingrediente": "patatas"}})
	mini._Tick_Slots_Coccion(mini._freidora, mini._slots_freidora_ui,
		mini._tiempo_coccion_patatas, "Patatas", mini._tiempo_coccion_patatas + 0.1)
	mini._on_freidora_pulsada(0)
	mini._Soltar_En_Plato({"tipo": "ingrediente", "id": "salsa"}, 0)
	mini._on_plancha_pulsada(0)
	mini._Soltar_En_Plato({"tipo": "ingrediente", "id": "salsa"}, 0)
	mini._efectos.limpiar()
	await get_tree().process_frame


func _Preparar_Mercado(mini: Control) -> void:
	_Forzar_Cliente(mini, 0, ["pisto_huevo", "agua"])
	_Forzar_Cliente(mini, 1, ["fabada", "sangria"])
	mini._Anadir_Ingrediente_Olla("tomate")
	mini._Anadir_Ingrediente_Olla("pimiento")
	mini._olla["progreso"] = 0.99
	mini._process(0.25)
	mini._Servir_Racion_Olla()
	mini._on_origen_tocado({}, {"datos": {"tipo": "bandeja", "ingrediente": "huevo"}})
	mini._Tick_Slots_Coccion(mini._freidora, mini._slots_freidora_ui,
		mini._tiempo_coccion_b, "Huevo", mini._tiempo_coccion_b + 0.1)
	mini._on_freidora_pulsada(0)
	mini._efectos.limpiar()
	await get_tree().process_frame


func _Preparar_Alta(mini: Control) -> void:
	_Forzar_Cliente(mini, 0, ["solomillo_tinto", "vino_tinto"])
	_Forzar_Cliente(mini, 1, ["lubina_blanca", "vino_blanco"])
	mini._on_origen_tocado({}, {"datos": {"tipo": "bandeja", "ingrediente": "solomillo"}})
	mini._on_origen_tocado({}, {"datos": {"tipo": "bandeja", "ingrediente": "lubina"}})
	mini._Tick_Slots_Coccion(mini._plancha, mini._slots_plancha_ui,
		mini._tiempo_coccion_carne, "Solomillo", mini._tiempo_coccion_carne * 0.24)
	mini._Tick_Slots_Coccion(mini._plancha, mini._slots_plancha_ui,
		mini._tiempo_coccion_carne, "Solomillo", mini._tiempo_coccion_carne * 0.52)
	mini._on_plancha_pulsada(0)
	mini._Soltar_En_Plato({"tipo": "salsa"}, 0)
	mini._Soltar_En_Plato({"tipo": "ingrediente", "id": "pure"}, 0)
	mini._Soltar_En_Plato({"tipo": "ingrediente", "id": "flor"}, 0)
	mini._sarten["quemado"] = 0.42
	mini._efectos.limpiar()
	await get_tree().process_frame


func _Forzar_Cliente(mini: Control, indice: int, items: Array) -> void:
	mini._clientes[indice]["activo"] = true
	mini._clientes[indice]["items"] = items.duplicate()
	var entregados: Array = []
	for _i in range(items.size()):
		entregados.append(false)
	mini._clientes[indice]["entregados"] = entregados
	mini._clientes[indice]["paciencia_max"] = 180.0
	mini._clientes[indice]["paciencia"] = 180.0
	mini._clientes[indice]["precio_total"] = 40
	mini._slots_clientes_ui[indice]["fase"] = "esperando"
	mini._clientes_pendientes = maxi(0, mini._clientes_pendientes - 1)
	mini._Actualizar_Cliente_UI(indice)


func _Guardar(vp: SubViewport, nombre: String) -> void:
	var imagen := vp.get_texture().get_image()
	if imagen != null and not imagen.is_empty():
		var ruta := DIR_SALIDA.path_join(nombre)
		imagen.save_png(ruta)
		print("Captura: ", ruta, " (", imagen.get_width(), "x", imagen.get_height(), ")")
