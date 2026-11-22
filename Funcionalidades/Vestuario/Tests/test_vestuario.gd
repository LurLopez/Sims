extends GutTest

# Tests del Vestuario: catálogo de atuendos, transformación de apariencia,
# pantalla dedicada y persistencia al equipar.

const RUTA_SAVE_DIN: String = "user://test_vestuario_din.dat"
const RUTA_SAVE_EST: String = "user://test_vestuario_est.dat"

var _backup: Dictionary = {}


func before_each() -> void:
	_backup = _Backup_Globales()
	Variables_Estaticas.Apariencia = Apariencia_Personaje.por_defecto()
	Variables_Estaticas.Record_Max_Niveles_Cocina = 0
	Variables_Dinamicas.Objetos_Poseidos = {
		"Cama_Basica": true,
		"Mesa_Basica": true,
		"Ducha_Basica": true,
		"Ropa_Calle": true,
	}
	Variables_Dinamicas.Objeto_Seleccionado = {
		"Dormir": "Cama_Basica",
		"Comer": "Mesa_Basica",
		"Duchar": "Ducha_Basica",
		"Ropa": "Ropa_Calle",
	}
	Variables_Dinamicas.Dinero = 1000.0
	Variables_Estaticas.Modo_Rapido = false
	Guardar_Variables_Dinamicas.save_path = RUTA_SAVE_DIN
	Guardar_Variables_Estaticas.save_path = RUTA_SAVE_EST


func after_each() -> void:
	_Restaurar_Globales(_backup)
	for ruta in [RUTA_SAVE_DIN, RUTA_SAVE_EST]:
		var abs_ruta: String = ProjectSettings.globalize_path(ruta)
		if FileAccess.file_exists(abs_ruta):
			DirAccess.remove_absolute(abs_ruta)


func _Backup_Globales() -> Dictionary:
	return {
		"apariencia": Variables_Estaticas.Apariencia.duplicate(true),
		"record_cocina": Variables_Estaticas.Record_Max_Niveles_Cocina,
		"objetos": Variables_Dinamicas.Objetos_Poseidos.duplicate(true),
		"seleccionado": Variables_Dinamicas.Objeto_Seleccionado.duplicate(true),
		"dinero": Variables_Dinamicas.Dinero,
		"modo_rapido": Variables_Estaticas.Modo_Rapido,
		"save_din": Guardar_Variables_Dinamicas.save_path,
		"save_est": Guardar_Variables_Estaticas.save_path,
	}


func _Restaurar_Globales(b: Dictionary) -> void:
	Variables_Estaticas.Apariencia = b["apariencia"]
	Variables_Estaticas.Record_Max_Niveles_Cocina = int(b["record_cocina"])
	Variables_Dinamicas.Objetos_Poseidos = b["objetos"]
	Variables_Dinamicas.Objeto_Seleccionado = b["seleccionado"]
	Variables_Dinamicas.Dinero = float(b["dinero"])
	Variables_Estaticas.Modo_Rapido = bool(b["modo_rapido"])
	Guardar_Variables_Dinamicas.save_path = str(b["save_din"])
	Guardar_Variables_Estaticas.save_path = str(b["save_est"])


# ============================================================================
# 1. Catálogo y datos visuales
# ============================================================================

func test_01_catalogo_de_atuendos_completo() -> void:
	assert_eq(Sistema_Cocina.ORDEN_ROPA.size(), 25)
	for clave in Sistema_Cocina.ORDEN_ROPA:
		var obj = Variables_Estaticas.Catalogo_Objetos.get(clave, null)
		assert_true(obj is Objeto_Ropa, "%s debe ser un Objeto_Ropa" % clave)
		if obj is Objeto_Ropa:
			var ropa := obj as Objeto_Ropa
			assert_eq(str(ropa.afecta_a), "Ropa")
			assert_true(Apariencia_Personaje.ESTILOS_ROPA.has(ropa.estilo_visual),
				"%s tiene un estilo visual válido" % clave)
			assert_false(str(ropa.descripcion_efecto).is_empty())
			assert_true(str(ropa.desbloqueo) in ["inicio", "tienda", "rango"],
				"%s tiene un desbloqueo válido" % clave)
			assert_true(str(ropa.categoria) in ["diario", "deporte", "elegante", "trabajo", "fiesta", "cocina"],
				"%s tiene una categoría válida" % clave)

	assert_eq((Variables_Estaticas.Catalogo_Objetos["Ropa_Calle"] as Objeto_Ropa).estilo_visual, "base")
	assert_eq((Variables_Estaticas.Catalogo_Objetos["Ropa_Calle"] as Objeto_Ropa).color_principal, "",
		"La ropa de calle conserva el color elegido en el creador")
	assert_eq((Variables_Estaticas.Catalogo_Objetos["Delantal_Aprendiz"] as Objeto_Ropa).estilo_visual, "delantal")
	assert_eq((Variables_Estaticas.Catalogo_Objetos["Chaqueta_Chef"] as Objeto_Ropa).estilo_visual, "chef")
	assert_eq((Variables_Estaticas.Catalogo_Objetos["Atuendo_Chef_Gala"] as Objeto_Ropa).estilo_visual, "gala")
	assert_eq((Variables_Estaticas.Catalogo_Objetos["Traje_Estrella_Michelin"] as Objeto_Ropa).estilo_visual, "michelin")
	assert_eq((Variables_Estaticas.Catalogo_Objetos["Conjunto_Deportivo"] as Objeto_Ropa).estilo_visual, "deportivo")
	assert_eq((Variables_Estaticas.Catalogo_Objetos["Vestido_Gala"] as Objeto_Ropa).estilo_visual, "vestido")
	assert_eq((Variables_Estaticas.Catalogo_Objetos["Traje_Ejecutivo"] as Objeto_Ropa).estilo_visual, "traje")


func test_01b_inicio_tienda_y_rango() -> void:
	var inicio := Sistema_Cocina.Obtener_Prendas_Iniciales()
	assert_eq(inicio.size(), 10, "Hay diez prendas gratuitas de inicio")
	assert_true(inicio.has("Ropa_Calle"))
	assert_true(inicio.has("Camiseta_Blanca"))
	assert_true(inicio.has("Equipacion_Futbol"))

	var tienda := 0
	var rango := 0
	for clave in Sistema_Cocina.ORDEN_ROPA:
		var ropa := Variables_Estaticas.Catalogo_Objetos[clave] as Objeto_Ropa
		if ropa.desbloqueo == "tienda":
			tienda += 1
			assert_true(ropa.precio > 0.0, "%s debe tener precio" % clave)
		elif ropa.desbloqueo == "rango":
			rango += 1
			assert_eq(ropa.precio, 0.0, "%s se gana por rango, no se compra" % clave)
	assert_eq(tienda, 11, "Hay once prendas de tienda")
	assert_eq(rango, 4, "Se mantienen las cuatro prendas de rango")


func test_02_rangos_de_desbloqueo() -> void:
	assert_eq(Sistema_Cocina.Obtener_Rango_Requerido_Ropa("Ropa_Calle"), 0)
	assert_eq(Sistema_Cocina.Obtener_Rango_Requerido_Ropa("Delantal_Aprendiz"), 1)
	assert_eq(Sistema_Cocina.Obtener_Rango_Requerido_Ropa("Chaqueta_Chef"), 3)
	assert_eq(Sistema_Cocina.Obtener_Rango_Requerido_Ropa("Atuendo_Chef_Gala"), 6)
	assert_eq(Sistema_Cocina.Obtener_Rango_Requerido_Ropa("Traje_Estrella_Michelin"), 9)
	assert_eq(Sistema_Cocina.Obtener_Rango_Requerido_Ropa("Traje_Ejecutivo"), 0,
		"Una prenda de tienda no exige rango")


func test_02b_prendas_iniciales_y_compra() -> void:
	Sistema_Cocina.Asegurar_Prendas_Iniciales()
	assert_true(bool(Variables_Dinamicas.Objetos_Poseidos.get("Camiseta_Blanca", false)))
	assert_true(bool(Variables_Dinamicas.Objetos_Poseidos.get("Conjunto_Deportivo", false)))
	assert_false(bool(Variables_Dinamicas.Objetos_Poseidos.get("Traje_Ejecutivo", false)))

	assert_true(Sistema_Cocina.Es_Ropa_Comprable("Traje_Ejecutivo"))
	var precio := Sistema_Cocina.Obtener_Precio_Ropa("Traje_Ejecutivo")
	assert_eq(precio, 420.0)
	Variables_Dinamicas.Dinero = 1000.0
	assert_true(Sistema_Cocina.Comprar_Ropa("Traje_Ejecutivo"))
	assert_true(bool(Variables_Dinamicas.Objetos_Poseidos.get("Traje_Ejecutivo", false)))
	assert_eq(Variables_Dinamicas.Dinero, 580.0)
	assert_false(Sistema_Cocina.Es_Ropa_Comprable("Traje_Ejecutivo"))
	assert_false(Sistema_Cocina.Comprar_Ropa("Traje_Ejecutivo"), "No se compra dos veces")

	# Sin saldo no se puede comprar otra prenda de tienda.
	Variables_Dinamicas.Dinero = 10.0
	assert_false(Sistema_Cocina.Comprar_Ropa("Esmoquin_Noir"))
	assert_false(bool(Variables_Dinamicas.Objetos_Poseidos.get("Esmoquin_Noir", false)))


# ============================================================================
# 2. Transformación de apariencia
# ============================================================================

func test_03_aplicar_atuendo_sobre_apariencia() -> void:
	var base := Apariencia_Personaje.normalizar(Variables_Estaticas.Apariencia)
	var calle := Sistema_Cocina.Obtener_Apariencia_Con_Ropa(base, "Ropa_Calle")
	assert_eq(str(calle["estilo_ropa"]), "base")
	assert_eq(str(calle["color_ropa"]), str(base["color_ropa"]))
	assert_eq(str(calle["ropa_superior"]), str(base["ropa_superior"]))
	assert_eq(str(calle["ropa_inferior"]), str(base["ropa_inferior"]))

	var delantal := Sistema_Cocina.Obtener_Apariencia_Con_Ropa(base, "Delantal_Aprendiz")
	assert_eq(str(delantal["estilo_ropa"]), "delantal")
	assert_eq(str(delantal["ropa_superior"]), "camiseta")
	assert_eq(str(delantal["color_ropa"]), "#bfdbfe")
	assert_eq(str(delantal["color_ropa_secundario"]), "#f6eeda")
	assert_eq(str(delantal["calzado"]), "zapatillas")

	var chef := Sistema_Cocina.Obtener_Apariencia_Con_Ropa(base, "Chaqueta_Chef")
	assert_eq(str(chef["estilo_ropa"]), "chef")
	assert_eq(str(chef["ropa_superior"]), "chaqueta")
	assert_eq(str(chef["calzado"]), "zapatos")
	assert_eq(str(chef["color_ropa"]), "#f8fafc")
	assert_eq(str(chef["color_pantalon"]), "#334155")

	var gala := Sistema_Cocina.Obtener_Apariencia_Con_Ropa(base, "Atuendo_Chef_Gala")
	assert_eq(str(gala["estilo_ropa"]), "gala")
	assert_eq(str(gala["color_ropa_detalle"]), "#fbbf24")

	var michelin := Sistema_Cocina.Obtener_Apariencia_Con_Ropa(base, "Traje_Estrella_Michelin")
	assert_eq(str(michelin["estilo_ropa"]), "michelin")
	assert_eq(str(michelin["color_ropa"]), "#1f2937")
	assert_eq(str(michelin["color_ropa_detalle"]), "#fbbf24")

	var traje := Sistema_Cocina.Obtener_Apariencia_Con_Ropa(base, "Traje_Ejecutivo")
	assert_eq(str(traje["estilo_ropa"]), "traje")
	assert_eq(str(traje["ropa_superior"]), "camisa")
	assert_eq(str(traje["detalle_ropa"]), "corbata")
	assert_eq(str(traje["color_ropa_secundario"]), "#1e3a5f")

	var vestido := Sistema_Cocina.Obtener_Apariencia_Con_Ropa(base, "Vestido_Gala")
	assert_eq(str(vestido["estilo_ropa"]), "vestido")
	assert_eq(str(vestido["ropa_inferior"]), "falda")
	assert_eq(str(vestido["detalle_ropa"]), "largo")

	var deportivo := Sistema_Cocina.Obtener_Apariencia_Con_Ropa(base, "Conjunto_Deportivo")
	assert_eq(str(deportivo["estilo_ropa"]), "deportivo")
	assert_eq(str(deportivo["ropa_inferior"]), "chandal")
	assert_eq(str(deportivo["detalle_ropa"]), "rayas")


func test_04_equipada_afecta_a_la_apariencia_global() -> void:
	Variables_Dinamicas.Objetos_Poseidos["Chaqueta_Chef"] = true
	assert_true(Sistema_Cocina.Equipar_Ropa("Chaqueta_Chef"))
	var ap := Sistema_Cocina.Obtener_Apariencia_Con_Ropa_Equipada(Variables_Estaticas.Apariencia)
	assert_eq(str(ap["estilo_ropa"]), "chef")
	assert_eq(str(Sistema_Cocina.Obtener_Clave_Ropa_Equipada()), "Chaqueta_Chef")


func test_04b_bonificaciones_de_las_prendas() -> void:
	for clave in ["Traje_Ejecutivo", "Bata_Laboratorio", "Abrigo_Invierno", "Chaqueta_Chef"]:
		Variables_Dinamicas.Objetos_Poseidos[clave] = true

	assert_true(Sistema_Cocina.Equipar_Ropa("Traje_Ejecutivo"))
	assert_almost_eq(Sistema_Cocina.Obtener_Bonus_Salario_General(), 0.05, 0.0001)

	assert_true(Sistema_Cocina.Equipar_Ropa("Bata_Laboratorio"))
	assert_almost_eq(Sistema_Cocina.Obtener_Bonus_Progreso(1), 0.08, 0.0001)

	assert_true(Sistema_Cocina.Equipar_Ropa("Abrigo_Invierno"))
	assert_almost_eq(Sistema_Cocina.Obtener_Reduccion_Higiene_Para_Trabajo("Trabajar_De_Carpintero"),
		0.10, 0.0001)

	assert_true(Sistema_Cocina.Equipar_Ropa("Chaqueta_Chef"))
	assert_almost_eq(Sistema_Cocina.Obtener_Reduccion_Higiene_Para_Trabajo("Trabajar_De_Cocinero_Partida"),
		0.05, 0.0001)


# ============================================================================
# 3. Pantalla de Vestuario
# ============================================================================

func test_05_pantalla_vestuario_muestra_y_equipa() -> void:
	for clave in Sistema_Cocina.ORDEN_ROPA:
		Variables_Dinamicas.Objetos_Poseidos[clave] = true

	var pantalla := Pantalla_Vestuario.new()
	add_child_autofree(pantalla)
	await get_tree().process_frame
	pantalla.abrir()
	await get_tree().process_frame

	assert_eq(pantalla.obtener_tarjetas().size(), Sistema_Cocina.ORDEN_ROPA.size())
	assert_eq(pantalla.obtener_clave_equipada(), "Ropa_Calle")
	assert_eq(pantalla.obtener_clave_seleccionada(), "Ropa_Calle")
	assert_not_null(pantalla.find_child("Card_Preview", true, false))
	assert_not_null(pantalla.find_child("HBox_Atuendos", true, false))
	assert_not_null(pantalla.find_child("Boton_Equipar_Atuendo", true, false))

	assert_true(pantalla.seleccionar_atuendo("Delantal_Aprendiz"))
	assert_eq(pantalla.obtener_clave_seleccionada(), "Delantal_Aprendiz")
	var ap_prev := pantalla.obtener_apariencia_preview()
	assert_eq(str(ap_prev.get("estilo_ropa", "")), "delantal")

	# El botón de equipar queda activo al probar otro atuendo.
	var btn := pantalla.get_node("Boton_Equipar_Atuendo") as Button
	assert_false(btn.disabled)
	assert_true(pantalla.equipar_seleccionado())
	assert_eq(pantalla.obtener_clave_equipada(), "Delantal_Aprendiz")
	assert_eq(str(Variables_Dinamicas.Objeto_Seleccionado.get("Ropa", "")), "Delantal_Aprendiz")
	assert_true(btn.disabled, "Tras equipar, el botón queda desactivado")


func test_05b_la_pantalla_no_bloquea_la_barra_superior() -> void:
	var pantalla := Pantalla_Vestuario.new()
	add_child_autofree(pantalla)
	await get_tree().process_frame
	pantalla.abrir()
	await get_tree().process_frame

	# La raíz ocupa toda la pantalla: si usa MOUSE_FILTER_STOP se come los clics
	# de las pestañas superiores (Perfil, Economía, Minijuegos…), porque Godot
	# resuelve el picking por orden del árbol y no por z_index.
	assert_eq(pantalla.mouse_filter, Control.MOUSE_FILTER_IGNORE,
		"La raíz del Vestuario no debe capturar los clics de la barra superior")
	var tarjeta := pantalla.obtener_tarjetas().get("Ropa_Calle") as Button
	assert_not_null(tarjeta)
	assert_ne(tarjeta.mouse_filter, Control.MOUSE_FILTER_IGNORE,
		"Las tarjetas del armario deben seguir recibiendo clics")
	var filtro := pantalla.find_child("Filtro_deporte", true, false) as Button
	assert_not_null(filtro)
	assert_ne(filtro.mouse_filter, Control.MOUSE_FILTER_IGNORE,
		"Los filtros deben seguir recibiendo clics")


func test_06_pantalla_no_permite_equipar_bloqueados() -> void:
	var pantalla := Pantalla_Vestuario.new()
	add_child_autofree(pantalla)
	await get_tree().process_frame
	pantalla.abrir()
	await get_tree().process_frame
	assert_false(pantalla.seleccionar_atuendo("Chaqueta_Chef"),
		"Una prenda no poseída no se puede seleccionar desde la API")
	assert_eq(pantalla.obtener_clave_seleccionada(), "Ropa_Calle")

	# La tarjeta bloqueada sí se puede tocar para previsualizarla, pero no equiparla.
	var card := pantalla.obtener_tarjetas().get("Chaqueta_Chef", null) as Button
	assert_not_null(card)
	card.pressed.emit()
	await get_tree().process_frame
	assert_eq(pantalla.obtener_clave_seleccionada(), "Chaqueta_Chef")
	assert_false(pantalla.equipar_seleccionado())


func test_06b_pantalla_permite_probar_y_comprar_ropa_de_tienda() -> void:
	Variables_Dinamicas.Dinero = 1000.0
	var pantalla := Pantalla_Vestuario.new()
	add_child_autofree(pantalla)
	await get_tree().process_frame
	pantalla.abrir()
	await get_tree().process_frame

	assert_true(pantalla.seleccionar_atuendo("Traje_Ejecutivo"),
		"Las prendas de tienda se pueden probar antes de comprar")
	assert_eq(pantalla.obtener_clave_seleccionada(), "Traje_Ejecutivo")
	var ap_prev := pantalla.obtener_apariencia_preview()
	assert_eq(str(ap_prev.get("estilo_ropa", "")), "traje")
	assert_false(pantalla.equipar_seleccionado(), "No se equipa una prenda sin comprarla")

	watch_signals(pantalla)
	assert_true(pantalla.comprar_seleccionado())
	assert_signal_emitted_with_parameters(pantalla, "atuendo_comprado", ["Traje_Ejecutivo"])
	assert_true(bool(Variables_Dinamicas.Objetos_Poseidos.get("Traje_Ejecutivo", false)))
	assert_eq(Variables_Dinamicas.Dinero, 580.0)
	assert_true(pantalla.equipar_seleccionado())
	assert_eq(pantalla.obtener_clave_equipada(), "Traje_Ejecutivo")
	assert_eq(str(Variables_Dinamicas.Objeto_Seleccionado.get("Ropa", "")), "Traje_Ejecutivo")


func test_06c_filtros_por_categoria() -> void:
	var pantalla := Pantalla_Vestuario.new()
	add_child_autofree(pantalla)
	await get_tree().process_frame
	pantalla.abrir()
	await get_tree().process_frame

	var card_maestria := pantalla.find_child("Card_Maestria_Cocina", true, false) as PanelContainer
	assert_not_null(card_maestria, "Existe la tarjeta de Maestría Culinaria")
	assert_false(card_maestria.visible, "La maestría solo se muestra en el filtro Cocina")

	assert_eq(pantalla.obtener_tarjetas().size(), Sistema_Cocina.ORDEN_ROPA.size())
	pantalla._Cambiar_Filtro("deporte")
	await get_tree().process_frame
	assert_eq(pantalla.obtener_tarjetas().size(), 2)
	assert_true(pantalla.obtener_tarjetas().has("Conjunto_Deportivo"))
	assert_true(pantalla.obtener_tarjetas().has("Equipacion_Futbol"))
	pantalla._Cambiar_Filtro("tienda")
	await get_tree().process_frame
	assert_eq(pantalla.obtener_tarjetas().size(), 11)
	assert_true(pantalla.obtener_tarjetas().has("Traje_Ejecutivo"))
	assert_false(pantalla.obtener_tarjetas().has("Ropa_Calle"))
	pantalla._Cambiar_Filtro("cocina")
	await get_tree().process_frame
	assert_eq(pantalla.obtener_tarjetas().size(), 4)

	assert_true(card_maestria.visible, "El filtro Cocina muestra el rango de maestría")
	var lbl_rango := pantalla.find_child("Lbl_Maestria_Rango", true, false) as Label
	assert_not_null(lbl_rango)
	assert_true(lbl_rango.text.begins_with("Rango "), "Se indica el rango actual")
	var lbl_texto := pantalla.find_child("Lbl_Maestria_Texto", true, false) as Label
	assert_not_null(lbl_texto)
	assert_string_contains(lbl_texto.text.to_lower(), "minijuego",
		"Se invita a jugar el minijuego para ascender")

	pantalla._Cambiar_Filtro("todo")
	await get_tree().process_frame
	assert_false(card_maestria.visible, "Al salir de Cocina se oculta la maestría")


func test_07_escena_principal_sin_ropa_en_apuntes() -> void:
	var raiz = load("res://Escenas/Escena_Principal/Escena principal.tscn").instantiate()
	assert_not_null(raiz.get_node_or_null("Vestuario_Button"), "Debe existir la pestaña Vestuario")
	assert_null(raiz.get_node_or_null("Pantalla_Mensajes/Panel_Apuntes/SubTab_Bar/SubTab_Ropa"))
	assert_null(raiz.get_node_or_null("Pantalla_Mensajes/Panel_Apuntes/Scroll_Ropa"))
	raiz.free()
