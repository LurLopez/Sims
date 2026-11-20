extends Node

var mini = null
var t := 0.0
var fase := 0

func _ready() -> void:
	Variables_Dinamicas.Cocina_Estado["restaurantes_desbloqueados"] = ["burger_street"]
	Variables_Dinamicas.Cocina_Estado["mejoras"]["burger_street"] = {
		"plancha": 2, "emplatado": 2, "termostato": 2, "ingredientes": 2, "ambiente": 2
	}
	Variables_Estaticas.Habilidades = [70, 60, 75, 55, 50, 65, 60]
	Variables_Dinamicas.Necesidades_Basicas = [80, 70, 65, 75, 60]
	Variables_Dinamicas.Minute_Day = 3
	Variables_Dinamicas.Minute_Minute = 720
	mini = load("res://Escenas/Minijuego_Cocina/Minijuego_Cocina.tscn").instantiate()
	add_child(mini)
	await get_tree().process_frame
	mini._Iniciar_Nivel(5)

	# Cliente 1: pedido completo, paciencia media
	mini._clientes[0]["activo"] = true
	mini._clientes[0]["items"] = ["burger_completa", "refresco"]
	mini._clientes[0]["entregados"] = [false, false]
	mini._clientes[0]["paciencia_max"] = 30.0
	mini._clientes[0]["paciencia"] = 18.0
	mini._clientes[0]["precio_total"] = 28
	mini._clientes[0]["variante"] = 1
	mini._Actualizar_Cliente_UI(0)

	# Cliente 2: patatas, poca paciencia
	mini._clientes[1]["activo"] = true
	mini._clientes[1]["items"] = ["patatas"]
	mini._clientes[1]["entregados"] = [false]
	mini._clientes[1]["paciencia_max"] = 22.0
	mini._clientes[1]["paciencia"] = 5.0
	mini._clientes[1]["precio_total"] = 10
	mini._clientes[1]["variante"] = 4
	mini._Actualizar_Cliente_UI(1)

	# Cliente 3: hamburguesa doble
	mini._clientes[2]["activo"] = true
	mini._clientes[2]["items"] = ["burger_doble", "patatas", "refresco"]
	mini._clientes[2]["entregados"] = [false, true, false]
	mini._clientes[2]["paciencia_max"] = 34.0
	mini._clientes[2]["paciencia"] = 26.0
	mini._clientes[2]["precio_total"] = 44
	mini._clientes[2]["variante"] = 2
	mini._Actualizar_Cliente_UI(2)

	# Cocina: carne en distintos estados, patatas listas, platos montados
	mini._plancha[0]["estado"] = "listo"
	mini._plancha[1]["estado"] = "cocinando"
	mini._plancha[1]["progreso"] = 0.55
	mini._plancha[2]["estado"] = "alerta"
	mini._plancha[2]["quemado"] = 0.7
	for i in range(3):
		mini._Actualizar_Slot_Coccion_UI(mini._plancha[i], mini._slots_plancha_ui[i], "Carne")

	mini._freidora[0]["estado"] = "listo"
	mini._freidora[1]["estado"] = "cocinando"
	mini._freidora[1]["progreso"] = 0.4
	for i in range(2):
		mini._Actualizar_Slot_Coccion_UI(mini._freidora[i], mini._slots_freidora_ui[i], "Patatas")

	mini._platos[0] = {"pan": true, "carnes": 1, "queso": true, "lechuga": true, "tomate": true}
	mini._platos[1] = {"pan": true, "carnes": 2, "queso": true, "lechuga": false, "tomate": false}
	mini._platos[2] = {"pan": true, "carnes": 0, "queso": false, "lechuga": false, "tomate": false}
	mini._Actualizar_Todos_Los_Platos_UI()

	mini._bebidas[0]["estado"] = "listo"
	mini._bebidas[1]["estado"] = "llenando"
	mini._bebidas[1]["progreso"] = 0.55
	for i in range(2):
		mini._Actualizar_Bebida_UI(i)

	mini._recaudacion = 96
	mini._propinas_servicio = 14
	mini._combo_actual = 3
	mini._combo_timer = 2.0
	mini._Actualizar_HUD_Cocina()
	mini._Mostrar_Banner("¡A COCINAR!", Color("#fef08a"))
	set_process(true)

func _process(delta: float) -> void:
	t += delta
	if fase == 0 and t > 0.35:
		fase = 1
		mini._Mostrar_Chef("pulgar", "¡BUEN TRABAJO!", Color("#15803d"), 5.0)
	if fase == 1 and t > 0.9:
		fase = 2
		var img := get_viewport().get_texture().get_image()
		img.save_png("/tmp/opencode/cocina_captura.png")
		print("CAPTURA OK")
		get_tree().quit()
