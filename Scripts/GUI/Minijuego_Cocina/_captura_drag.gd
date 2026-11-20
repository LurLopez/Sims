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
	mini._Iniciar_Nivel(3)
	# Plato con pan y queso
	mini._platos[0] = {"pan": true, "carnes": 1, "queso": true, "lechuga": false, "tomate": false}
	mini._Actualizar_Plato_UI(0)
	mini._bebidas[0]["estado"] = "listo"
	mini._Actualizar_Bebida_UI(0)
	# Cliente esperando
	mini._clientes[0]["activo"] = true
	mini._clientes[0]["items"] = ["burger_queso", "refresco"]
	mini._clientes[0]["entregados"] = [false, false]
	mini._clientes[0]["paciencia_max"] = 30.0
	mini._clientes[0]["paciencia"] = 22.0
	mini._clientes[0]["precio_total"] = 30
	mini._Actualizar_Cliente_UI(0)
	set_process(true)

func _process(delta: float) -> void:
	t += delta
	if fase == 0 and t > 0.2:
		fase = 1
		var origen: Vector2 = mini._bandeja_items_ui[4]["rect"].get_center()
		var destino: Vector2 = mini._slots_platos_ui[0]["rect"].get_center()
		_Drag(origen, destino)
	if fase == 1 and t > 0.9:
		fase = 2
		var img := get_viewport().get_texture().get_image()
		img.save_png("/tmp/opencode/cocina_drag.png")
		print("CAPTURA DRAG OK")
		_Release()
	if fase == 2 and t > 1.2:
		print("PLATO PAN=", mini._platos[0]["pan"], " QUESO=", mini._platos[0]["queso"], " TOMATE=", mini._platos[0]["tomate"])
		get_tree().quit()

func _Drag(origen: Vector2, destino: Vector2) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = origen
	Input.parse_input_event(ev)
	await get_tree().process_frame
	var mv := InputEventMouseMotion.new()
	mv.position = destino
	mv.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(mv)

func _Release() -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = false
	ev.position = mini._slots_platos_ui[0]["rect"].get_center()
	Input.parse_input_event(ev)
