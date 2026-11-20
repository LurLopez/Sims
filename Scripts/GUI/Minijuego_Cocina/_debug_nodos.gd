extends Node

func _ready() -> void:
	var mini = load("res://Escenas/Minijuego_Cocina/Minijuego_Cocina.tscn").instantiate()
	add_child(mini)
	await get_tree().process_frame
	mini._Iniciar_Nivel(5)
	mini._clientes[0]["activo"] = true
	mini._clientes[0]["items"] = ["burger_completa", "refresco"]
	mini._clientes[0]["entregados"] = [false, false]
	mini._clientes[0]["paciencia_max"] = 30.0
	mini._clientes[0]["paciencia"] = 18.0
	mini._clientes[0]["precio_total"] = 28
	mini._clientes[0]["variante"] = 1
	mini._Actualizar_Cliente_UI(0)
	await get_tree().process_frame
	await get_tree().process_frame
	print("=== TICKET 0 ===")
	var t = mini._slots_clientes_ui[0]["ticket"]
	print("pos ", t.position, " size ", t.size, " global ", t.get_global_rect())
	print("items ", t.items, " entregados ", t.entregados)
	var p = Vector2(390.0, 80.0)
	print("=== CONTROLES EN ", p, " ===")
	_Dump(mini, p)

func _Dump(nodo: Node, p: Vector2) -> void:
	for c in nodo.get_children():
		if c is Control:
			var ctrl: Control = c
			var r: Rect2 = ctrl.get_global_rect()
			if r.has_point(p) and ctrl.visible:
				print("  ", ctrl.get_path(), " type=", ctrl.get_class(), " script=", ctrl.get_script().resource_path if ctrl.get_script() else "", " rect=", r, " size=", ctrl.size, " pos=", ctrl.position)
		_Dump(c, p)
