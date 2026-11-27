extends GutTest

# Tests de interfaz de «La Granja» (lienzo libre 24×24 con cámara, huellas
# multi-celda, colocación fantasma, rotación, movimiento gratis, siembra rápida
# en cadena, inspector, modo vender al 50 %, recoger todo y conversión).

const Datos := preload("res://Scripts/Logica/Escena_Principal/Granja/Datos_Granja.gd")


func before_each() -> void:
	Sistema_Granja.Ahora_Forzado = 1760000000
	Variables_Estaticas.Modo_Rapido = false
	Variables_Dinamicas.Dinero = 1000.0
	Variables_Dinamicas.Granja_Estado = Sistema_Granja.Estado_Por_Defecto()
	Sistema_Granja._tabla_conversion.clear()
	Sistema_Granja._tabla_conversion.append(0.0)
	var r: Dictionary = Sistema_Granja.Comprar()
	assert_true(bool(r.get("ok", false)), str(r))


func after_each() -> void:
	Sistema_Granja.Ahora_Forzado = -1
	Variables_Estaticas.Modo_Rapido = false


func test_ui_instancia_mundo_y_modales() -> void:
	var packed := load("res://Escenas/Granja/Granja.tscn") as PackedScene
	assert_not_null(packed)
	var granja = packed.instantiate()
	add_child_autofree(granja)
	await get_tree().process_frame
	await get_tree().process_frame

	assert_not_null(granja.find_child("Mundo_Granja", true, false))
	assert_not_null(granja.find_child("Cabecera", true, false))
	assert_not_null(granja.find_child("Barra_Inferior", true, false))
	assert_not_null(granja.find_child("Controles_Camara", true, false))
	assert_not_null(granja.find_child("Modal_Granja", true, false))
	assert_not_null(granja.find_child("Obj_1", true, false))  # Molino 4×4
	assert_not_null(granja.find_child("Obj_2", true, false))  # Gallina 2×2

	granja.call("_Abrir_Tienda", "todo")
	assert_true(bool(granja.get("_modal").visible))
	granja.call("_Cerrar_Modal")

	granja.call("_Abrir_Almacen")
	assert_true(bool(granja.get("_modal").visible))
	granja.call("_Cerrar_Modal")

	granja.call("_Abrir_Mejoras")
	assert_true(bool(granja.get("_modal").visible))
	granja.call("_Cerrar_Modal")

	granja.call("_Abrir_Conversion")
	assert_true(bool(granja.get("_modal").visible))
	granja.call("_Cerrar_Modal")

	assert_false(bool(granja.get("_cerrado")))


func test_ui_colocacion_fantasma_rotacion_y_movimiento() -> void:
	var packed := load("res://Escenas/Granja/Granja.tscn") as PackedScene
	var granja = packed.instantiate()
	add_child_autofree(granja)
	await get_tree().process_frame
	await get_tree().process_frame

	Sistema_Granja.Estado()["Monedas"] = 2000
	# Iniciar colocación de Panadería (4×3)
	granja.call("_Iniciar_Colocacion", "maquina", "panaderia")
	assert_true(bool(granja.get("_barra_ghost").visible))
	var mundo = granja.get("_mundo")
	assert_true(bool(mundo.call("datos_ghost").get("activo", false)))

	# Girar panadería 4×3 -> 3×4
	granja.call("_Rotar_Ghost")
	assert_true(bool(mundo.call("datos_ghost").get("rotado", false)))

	# Colocar en (12, 12) dentro del terreno desbloqueado
	granja.call("_on_colocar_solicitado", 12, 12)
	assert_eq(Sistema_Granja.Contar_Tipo("panaderia"), 1)
	var pan: Dictionary = Sistema_Granja.Objeto_En(12, 12)
	assert_eq(int(pan.get("ancho", 0)), 3)
	assert_eq(int(pan.get("alto", 0)), 4)

	# Moverla gratis a (8, 13)
	var pan_id: int = int(pan["id"])
	granja.call("_Iniciar_Mover_Objeto", pan_id)
	assert_true(bool(granja.get("_barra_ghost").visible))
	granja.call("_on_colocar_solicitado", 8, 13)
	var movida: Dictionary = Sistema_Granja.Obtener_Objeto(pan_id)
	assert_eq(int(movida["x"]), 8)
	assert_eq(int(movida["y"]), 13)


func test_ui_siembra_rapida_en_cadena_y_venta_50() -> void:
	var packed := load("res://Escenas/Granja/Granja.tscn") as PackedScene
	var granja = packed.instantiate()
	add_child_autofree(granja)
	await get_tree().process_frame
	await get_tree().process_frame

	# Tocar parcela vacía id=3 abre la barra rápida de siembra
	granja.call("_Accion_Objeto", 3)
	assert_true(bool(granja.get("_barra_siembra").visible))
	# Elegir Trigo planta en id=3 y mantiene siembra rápida activa sin deformar la barra
	granja.call("_Seleccionar_Semilla_Rapida", "trigo")
	await get_tree().process_frame
	var bs: Control = granja.get("_barra_siembra")
	assert_lte(bs.size.y, 100.0, "La barra de siembra no debe estirarse verticalmente tras elegir semilla")
	assert_eq(str(Sistema_Granja.Obtener_Objeto(3).get("cultivo", "")), "trigo")
	assert_eq(str(granja.get("_modo")), "sembrar")
	# Tocar parcela id=4 planta trigo en 1 solo toque!
	granja.call("_Accion_Objeto", 4)
	assert_eq(str(Sistema_Granja.Obtener_Objeto(4).get("cultivo", "")), "trigo")
	granja.call("_Establecer_Modo", "normal")

	# Ingresar 100 € -> +100 MG (1:1) desde el modal
	var mg_pre_ing: int = int(Sistema_Granja.Estado()["Monedas"])
	var eur_pre_ing: float = Variables_Dinamicas.Dinero
	granja.call("_Abrir_Conversion", "ingresar")
	var spin_ing = granja.get("_spin_cambio")
	assert_not_null(spin_ing)
	spin_ing.value = 100
	granja.call("_Confirmar_Ingreso")
	assert_eq(int(Sistema_Granja.Estado()["Monedas"]), mg_pre_ing + 100)
	assert_almost_eq(Variables_Dinamicas.Dinero, eur_pre_ing - 100.0, 0.01)

	# Modo vender: vender la gallina (id=2 -> 50% de 150 = 75 MG)
	var mg_antes: int = int(Sistema_Granja.Estado()["Monedas"])
	granja.call("_Establecer_Modo_Vender", true)
	granja.call("_Accion_Objeto", 2)
	assert_true(bool(granja.get("_modal").visible))
	granja.call("_Confirmar_Venta_Objeto", 2)
	assert_eq(Sistema_Granja.Contar_Categoria("animal"), 0)
	assert_eq(int(Sistema_Granja.Estado()["Monedas"]), mg_antes + 75)


func test_ui_produccion_recoger_todo_y_conversion() -> void:
	var packed := load("res://Escenas/Granja/Granja.tscn") as PackedScene
	var granja = packed.instantiate()
	add_child_autofree(granja)
	await get_tree().process_frame
	await get_tree().process_frame

	granja.call("_Plantar", 3, "trigo", false)
	granja.call("_Plantar", 4, "zanahoria", false)
	granja.call("_Accion_Objeto", 2)  # Alimentar gallina
	granja.call("_Accion_Objeto", 1)  # Cargar molino

	Sistema_Granja.Ahora_Forzado += 8 * 3600
	granja.call("_Actualizar_Todo")
	var btn_recoger: Button = granja.get("_btn_recoger_todo")
	assert_true(btn_recoger.visible, "Con >=2 elementos listos aparece Recoger todo")

	granja.call("_Recoger_Todo")
	assert_eq(Sistema_Granja.Cantidad_Almacen("trigo"), 1)
	assert_eq(Sistema_Granja.Cantidad_Almacen("zanahoria"), 1)
	assert_eq(Sistema_Granja.Cantidad_Almacen("huevo"), 2)
	assert_eq(Sistema_Granja.Cantidad_Almacen("harina"), 1)
	assert_false(btn_recoger.visible)

	granja.call("_Abrir_Conversion")
	var spin = granja.get("_spin_cambio")
	assert_not_null(spin)
	spin.value = 10
	granja.call("_Confirmar_Cambio")
	assert_almost_eq(Variables_Dinamicas.Dinero, 1010.0, 0.02)


func test_ui_proyeccion_isometrica_inversa_exacta() -> void:
	var packed := load("res://Escenas/Granja/Granja.tscn") as PackedScene
	var granja = packed.instantiate()
	add_child_autofree(granja)
	await get_tree().process_frame
	await get_tree().process_frame

	var mundo = granja.get("_mundo")
	var p_mundo: Vector2 = mundo.call("grid_a_mundo", 12.5, 9.25)
	var back: Vector2 = mundo.call("mundo_a_grid", p_mundo)
	assert_almost_eq(back.x, 12.5, 0.001)
	assert_almost_eq(back.y, 9.25, 0.001)


func test_ui_input_real_click_arrastre_y_zoom() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 60
	add_child_autofree(cl)
	var packed := load("res://Escenas/Granja/Granja.tscn") as PackedScene
	var granja = packed.instantiate()
	cl.add_child(granja)
	await get_tree().process_frame
	await get_tree().process_frame

	var mundo: Control = granja.get("_mundo")
	assert_gt(mundo.size.x, 500.0, "Mundo_Granja debe ocupar todo el ancho del viewport para recibir input")
	assert_gt(mundo.size.y, 500.0, "Mundo_Granja debe ocupar todo el alto del viewport para recibir input")
	assert_eq(mundo.mouse_filter, Control.MOUSE_FILTER_STOP)

	# 1. Arrastrar con ratón mueve la cámara sin disparar click
	var cam_antes: Vector2 = mundo.get("_cam_centro_mundo")
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(300, 300)
	mundo.call("_gui_input", press)

	var drag := InputEventMouseMotion.new()
	drag.position = Vector2(460, 380)
	drag.relative = Vector2(160, 80)
	drag.button_mask = MOUSE_BUTTON_MASK_LEFT
	mundo.call("_gui_input", drag)

	var rel := InputEventMouseButton.new()
	rel.button_index = MOUSE_BUTTON_LEFT
	rel.pressed = false
	rel.position = Vector2(460, 380)
	mundo.call("_gui_input", rel)

	var cam_despues: Vector2 = mundo.get("_cam_centro_mundo")
	assert_gt(cam_antes.distance_to(cam_despues), 50.0, "Arrastrar en el mapa debe mover la cámara")
	assert_false(bool(granja.get("_modal").visible), "Arrastrar no debe abrir la tienda por error")

	# 2. Click sobre parcela vacía id=3 (centro en 12.0, 8.0) abre Barra_Siembra
	var pos_p3: Vector2 = mundo.call("mundo_a_pantalla", mundo.call("grid_a_mundo", 12.0, 8.0))
	var cp := InputEventMouseButton.new()
	cp.button_index = MOUSE_BUTTON_LEFT
	cp.pressed = true
	cp.position = pos_p3
	mundo.call("_gui_input", cp)
	var cr := InputEventMouseButton.new()
	cr.button_index = MOUSE_BUTTON_LEFT
	cr.pressed = false
	cr.position = pos_p3
	mundo.call("_gui_input", cr)
	assert_true(bool(granja.get("_barra_siembra").visible), "Click en parcela vacía debe abrir la barra de siembra")
	granja.call("_Establecer_Modo", "normal")

	# 3. Rueda del ratón cambia el zoom
	var zoom_antes: float = float(mundo.get("_cam_zoom_objetivo"))
	var wh := InputEventMouseButton.new()
	wh.button_index = MOUSE_BUTTON_WHEEL_UP
	wh.pressed = true
	wh.position = Vector2(400, 360)
	mundo.call("_gui_input", wh)
	assert_gt(float(mundo.get("_cam_zoom_objetivo")), zoom_antes, "Rueda arriba debe acercar el zoom")

	# 4. Arrastrar sobre el ghost en modo colocación desplaza el ghost
	Sistema_Granja.Estado()["Monedas"] = 1000
	granja.call("_Iniciar_Colocacion", "tierra", "tierra")
	var g0: Dictionary = mundo.call("datos_ghost")
	var pos_g0: Vector2 = mundo.call("mundo_a_pantalla", mundo.call("grid_a_mundo", float(g0["gx"]) + 1.0, float(g0["gy"]) + 1.0))
	var gp := InputEventMouseButton.new()
	gp.button_index = MOUSE_BUTTON_LEFT
	gp.pressed = true
	gp.position = pos_g0
	mundo.call("_gui_input", gp)
	var gm := InputEventMouseMotion.new()
	gm.position = pos_g0 + Vector2(140, 60)
	gm.relative = Vector2(140, 60)
	gm.button_mask = MOUSE_BUTTON_MASK_LEFT
	mundo.call("_gui_input", gm)
	var gr := InputEventMouseButton.new()
	gr.button_index = MOUSE_BUTTON_LEFT
	gr.pressed = false
	gr.position = pos_g0 + Vector2(140, 60)
	mundo.call("_gui_input", gr)
	var g1: Dictionary = mundo.call("datos_ghost")
	assert_true(int(g1["gx"]) != int(g0["gx"]) or int(g1["gy"]) != int(g0["gy"]), "Arrastrar sobre el ghost debe deslizarlo por el mapa")
