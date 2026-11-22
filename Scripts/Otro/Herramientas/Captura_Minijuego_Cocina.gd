extends Node

# Herramienta de QA visual del Minijuego de Cocina.
# Uso:
#   godot --headless --path . res://Escenas/Herramientas/Captura_Minijuego_Cocina.tscn

const DIR_SALIDA := "user://capturas_minijuego_cocina"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR_SALIDA))
	await get_tree().process_frame
	await _Capturar_Partida("minijuego_cocina_nivel1.png")
	print("Capturas del minijuego guardadas en ", ProjectSettings.globalize_path(DIR_SALIDA))
	get_tree().quit()


func _Capturar_Partida(nombre: String) -> void:
	Variables_Dinamicas.Cocina_Estado = Variables_Dinamicas.Cocina_Estado_Por_Defecto()
	Variables_Dinamicas.Cocina_Estado["restaurantes_desbloqueados"] = ["burger_street"]
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
	mini._Iniciar_Nivel(1)
	await get_tree().process_frame
	mini._spawn_timer = 9999.0
	# Cliente de ejemplo para que la captura muestre un pedido y el tutorial útil.
	mini._clientes[0]["activo"] = true
	mini._clientes[0]["items"] = ["burger_sola", "refresco"]
	mini._clientes[0]["entregados"] = [false, false]
	mini._clientes[0]["paciencia_max"] = 60.0
	mini._clientes[0]["paciencia"] = 60.0
	mini._clientes[0]["precio_total"] = 18
	mini._slots_clientes_ui[0]["fase"] = "esperando"
	mini._clientes_pendientes = maxi(0, mini._clientes_pendientes - 1)
	mini._Actualizar_Cliente_UI(0)
	await get_tree().create_timer(3.0).timeout
	await RenderingServer.frame_post_draw
	_Guardar(vp, nombre)

	# Flujo rápido: tocar carne -> plancha, pan -> plato, queso/lechuga/tomate
	# y arrastrar la carne lista al pan.
	mini._on_origen_tocado({}, {"datos": {"tipo": "bandeja", "ingrediente": "carne"}})
	mini._on_origen_tocado({}, {"datos": {"tipo": "bandeja", "ingrediente": "carne"}})
	mini._on_origen_tocado({}, {"datos": {"tipo": "bandeja", "ingrediente": "pan"}})
	mini._on_origen_tocado({}, {"datos": {"tipo": "bandeja", "ingrediente": "pan"}})
	mini._Tick_Slots_Coccion(mini._plancha, mini._slots_plancha_ui,
		mini._tiempo_coccion_carne, "Carne", mini._tiempo_coccion_carne + 0.1)
	mini._Soltar_En_Plato({"tipo": "carne_lista", "indice": 0}, 0)
	mini._on_origen_tocado({}, {"datos": {"tipo": "bandeja", "ingrediente": "queso"}})
	mini._on_origen_tocado({}, {"datos": {"tipo": "bandeja", "ingrediente": "lechuga"}})
	mini._on_origen_tocado({}, {"datos": {"tipo": "bandeja", "ingrediente": "tomate"}})
	await get_tree().create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	_Guardar(vp, "minijuego_cocina_tap.png")

	# Captura limpia del pase (sin textos flotantes) con la mejora básica.
	await get_tree().create_timer(1.6).timeout
	await RenderingServer.frame_post_draw
	_Guardar(vp, "minijuego_cocina_pase.png")

	# Captura del pase con los cuatro huecos desbloqueados (Emplatado Nv.3).
	Variables_Dinamicas.Cocina_Estado["mejoras"]["burger_street"]["emplatado"] = 3
	mini._Iniciar_Nivel(1)
	mini._spawn_timer = 9999.0
	await get_tree().process_frame
	for _i in range(4):
		mini._on_origen_tocado({}, {"datos": {"tipo": "bandeja", "ingrediente": "pan"}})
	await get_tree().create_timer(1.6).timeout
	await RenderingServer.frame_post_draw
	_Guardar(vp, "minijuego_cocina_pase_nv3.png")

	# Modales cartoon (pausa, confirmación de salida y ficha de nivel).
	mini._Abrir_Modal_Pausa()
	await get_tree().create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	_Guardar(vp, "modal_pausa.png")
	mini._Reanudar_Partida()
	await get_tree().process_frame

	mini._Intentar_Volver_Al_Mapa()
	await get_tree().create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	_Guardar(vp, "modal_confirmar_salida.png")
	mini._Cancelar_Salida_Partida()
	await get_tree().process_frame

	mini._Abrir_Modal_Inicio(2)
	await get_tree().create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	_Guardar(vp, "modal_nivel.png")
	mini._modal_inicio.visible = false

	# Modal de resultados con un resumen de ejemplo.
	mini._Mostrar_Modal_Resultados({
		"estrellas": 3,
		"superado": true,
		"ventas": 128,
		"propinas_servicio": 14,
		"coste_ingredientes": 32,
		"coste_servicio": 12,
		"coste_merma": 3,
		"costes_totales": 47,
		"beneficio_neto": 95,
		"caja_ganada": 95,
		"reparto_sim": 4.75,
		"dinero_ganado": 11.4,
		"recaudacion": 142,
		"propinas_eur": 7.0,
		"bono_estrellas_eur": 4.4,
		"modo_practica": false,
		"plus_nomina_activado": true,
		"subio_rango": false
	})
	await get_tree().create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	_Guardar(vp, "modal_resultados.png")
	mini._modal_resultados.visible = false
	vp.queue_free()


func _Guardar(vp: SubViewport, nombre: String) -> void:
	var imagen := vp.get_texture().get_image()
	if imagen != null and not imagen.is_empty():
		var ruta := DIR_SALIDA.path_join(nombre)
		imagen.save_png(ruta)
		print("Captura: ", ruta, " (", imagen.get_width(), "x", imagen.get_height(), ")")
