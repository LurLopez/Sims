extends GutTest

# Pruebas de los tres mundos nuevos del minijuego de cocina:
#   · Bistró Tradicional  → punto del filete
#   · Cocina de Mercado   → guisos por lotes en la olla
#   · Alta Cocina         → ventana del horno, salsa y maridaje

const DIA_PRUEBA: int = 12
const RUTA_SAVE_DIN: String = "user://test_mundos_cocina_din.dat"
const RUTA_SAVE_EST: String = "user://test_mundos_cocina_est.dat"

var _backup: Dictionary = {}


func before_all() -> void:
	_Inicializar_Matriz()


func before_each() -> void:
	_backup = _Backup_Globales()
	Sistema_Cocina.desbloqueo_total_qa = false
	Variables_Estaticas.Modo_Rapido = false
	Variables_Estaticas.Habilidades = [50, 50, 50, 50, 50, 50, 50]
	Variables_Dinamicas.Progreso = [50, 50, 50]
	Variables_Dinamicas.Progreso_Cocina = 1
	Variables_Dinamicas.Necesidades_Basicas = [80, 80, 80, 80, 80]
	Variables_Dinamicas.Dinero = 1000.0
	Variables_Dinamicas.Minute_Day = DIA_PRUEBA
	Variables_Dinamicas.Minute_Minute = 600
	Variables_Dinamicas.Minute = DIA_PRUEBA * 1440 + 600
	Variables_Dinamicas.Estados_Temporales = {}
	Variables_Dinamicas.Mensajes = []
	Variables_Dinamicas.Cocina_Estado = Variables_Dinamicas.Cocina_Estado_Por_Defecto()
	Variables_Dinamicas.Cocina_Estado["restaurantes_desbloqueados"] = [
		"burger_street", "bistro_tradicional", "cocina_mercado", "alta_cocina"
	]
	Guardar_Variables_Dinamicas.save_path = RUTA_SAVE_DIN
	Guardar_Variables_Estaticas.save_path = RUTA_SAVE_EST


func after_each() -> void:
	_Restaurar_Globales(_backup)
	for ruta in [RUTA_SAVE_DIN, RUTA_SAVE_EST]:
		var abs_ruta: String = ProjectSettings.globalize_path(ruta)
		if FileAccess.file_exists(abs_ruta):
			DirAccess.remove_absolute(abs_ruta)


func _Inicializar_Matriz() -> void:
	if Variables_Dinamicas.Matriz_Jugador.size() == 1440:
		return
	Variables_Dinamicas.Matriz_Jugador = []
	for i in range(1440):
		var fila: Array = []
		fila.resize(574)
		fila.fill("")
		Variables_Dinamicas.Matriz_Jugador.append(fila)


func _Backup_Globales() -> Dictionary:
	return {
		"modo_rapido": Variables_Estaticas.Modo_Rapido,
		"habilidades": Variables_Estaticas.Habilidades.duplicate(),
		"progreso": Variables_Dinamicas.Progreso.duplicate(),
		"progreso_cocina": Variables_Dinamicas.Progreso_Cocina,
		"necesidades": Variables_Dinamicas.Necesidades_Basicas.duplicate(),
		"dinero": Variables_Dinamicas.Dinero,
		"minute_day": Variables_Dinamicas.Minute_Day,
		"minute_minute": Variables_Dinamicas.Minute_Minute,
		"minute": Variables_Dinamicas.Minute,
		"estados": Variables_Dinamicas.Estados_Temporales.duplicate(true),
		"mensajes": Variables_Dinamicas.Mensajes.duplicate(),
		"cocina_estado": Variables_Dinamicas.Cocina_Estado.duplicate(true),
		"qa_desbloqueo": Sistema_Cocina.desbloqueo_total_qa,
		"save_din": Guardar_Variables_Dinamicas.save_path,
		"save_est": Guardar_Variables_Estaticas.save_path,
	}


func _Restaurar_Globales(b: Dictionary) -> void:
	Variables_Estaticas.Modo_Rapido = b["modo_rapido"]
	Variables_Estaticas.Habilidades = b["habilidades"]
	Variables_Dinamicas.Progreso = b["progreso"]
	Variables_Dinamicas.Progreso_Cocina = b["progreso_cocina"]
	Variables_Dinamicas.Necesidades_Basicas = b["necesidades"]
	Variables_Dinamicas.Dinero = b["dinero"]
	Variables_Dinamicas.Minute_Day = b["minute_day"]
	Variables_Dinamicas.Minute_Minute = b["minute_minute"]
	Variables_Dinamicas.Minute = b["minute"]
	Variables_Dinamicas.Estados_Temporales = b["estados"]
	Variables_Dinamicas.Mensajes = b["mensajes"]
	Variables_Dinamicas.Cocina_Estado = b["cocina_estado"]
	Sistema_Cocina.desbloqueo_total_qa = b["qa_desbloqueo"]
	Guardar_Variables_Dinamicas.save_path = b["save_din"]
	Guardar_Variables_Estaticas.save_path = b["save_est"]
	Guardar_Variables_Dinamicas._rle_cache = {}


func _Crear_Minijuego(restaurante: String) -> Control:
	var mini = load("res://Escenas/Minijuego_Cocina/Minijuego_Cocina.tscn").instantiate()
	add_child_autofree(mini)
	await get_tree().process_frame
	mini._restaurante_actual = restaurante
	mini._restaurante_expandido = restaurante
	mini._Iniciar_Nivel(1)
	await get_tree().process_frame
	mini._spawn_timer = 9999.0
	return mini


func _Forzar_Cliente(mini: Control, items: Array) -> void:
	mini._clientes[0]["activo"] = true
	mini._clientes[0]["items"] = items.duplicate()
	mini._clientes[0]["entregados"] = []
	for _i in range(items.size()):
		mini._clientes[0]["entregados"].append(false)
	mini._clientes[0]["paciencia_max"] = 90.0
	mini._clientes[0]["paciencia"] = 90.0
	mini._clientes[0]["precio_total"] = 40
	mini._slots_clientes_ui[0]["visible_antes"] = true
	mini._clientes_pendientes = maxi(0, mini._clientes_pendientes - 1)
	mini._Actualizar_Cliente_UI(0)
	# Sin esperar al tween de entrada: el cliente ya está sentado para servir.
	mini._slots_clientes_ui[0]["fase"] = "esperando"


# ============================================================================
# Catálogo y datos
# ============================================================================

func test_00_los_cuatro_mundos_estan_implementados() -> void:
	assert_eq(Sistema_Cocina.ORDEN_RESTAURANTES.size(), 4)
	for rest_id in Sistema_Cocina.ORDEN_RESTAURANTES:
		var cfg: Dictionary = Sistema_Cocina.Obtener_Restaurante(rest_id)
		assert_true(bool(cfg.get("implementado", false)),
			"%s debe estar implementado" % rest_id)
		assert_eq((cfg.get("niveles", []) as Array).size(), 15,
			"%s debe tener 15 niveles" % rest_id)
		var perf: Dictionary = Sistema_Cocina.Obtener_Perfil_Restaurante(rest_id)
		assert_false(perf.is_empty(), "%s debe tener perfil" % rest_id)
		assert_true(FileAccess.file_exists(str(perf.get("fondo", ""))),
			"El fondo de %s debe existir" % rest_id)
		for niv in cfg.get("niveles", []):
			for rec_id in niv.get("menu", []):
				var rec: Dictionary = Sistema_Cocina.Obtener_Receta(rest_id, str(rec_id))
				assert_false(rec.is_empty(),
					"%s: la receta %s debe existir" % [rest_id, rec_id])
	# Los nombres de las mejoras se adaptan a la estación del mundo.
	assert_eq(Sistema_Cocina.Obtener_Nombre_Mejora("alta_cocina", "plancha"),
		"Horno y Sartén")
	assert_eq(Sistema_Cocina.Obtener_Nombre_Mejora("cocina_mercado", "plancha"),
		"Olla y Plancha")
	assert_eq(Sistema_Cocina.Obtener_Nombre_Mejora("bistro_tradicional", "plancha"),
		"Parrilla y Freidora")


func test_01_punto_del_filete_y_recetas_del_bistro() -> void:
	assert_eq(Sistema_Cocina.Calcular_Punto_Filete(0.10), "crudo")
	assert_eq(Sistema_Cocina.Calcular_Punto_Filete(0.40), "poco_hecho")
	assert_eq(Sistema_Cocina.Calcular_Punto_Filete(0.62), "al_punto")
	assert_eq(Sistema_Cocina.Calcular_Punto_Filete(0.90), "hecho")
	assert_eq(Sistema_Cocina.Calcular_Punto_Filete(1.0, 0.50), "quemado")
	assert_eq(Sistema_Cocina.Identificar_Plato_Bistro("filete", "al_punto", "patatas", ""),
		"filete_patatas")
	assert_eq(Sistema_Cocina.Identificar_Plato_Bistro("filete", "poco_hecho", "patatas", "salsa"),
		"solomillo_jugoso")
	assert_eq(Sistema_Cocina.Identificar_Plato_Bistro("filete", "hecho", "", ""), "")


func test_02_olla_combos_y_plato_del_mercado() -> void:
	assert_true(Sistema_Cocina.Olla_Acepta_Ingrediente([], "alubias"))
	assert_false(Sistema_Cocina.Olla_Acepta_Ingrediente(["alubias"], "tomate"),
		"No se puede mezclar alubias con tomate")
	assert_eq(Sistema_Cocina.Resolver_Receta_Olla(["chorizo", "alubias"]), "fabada")
	assert_eq(Sistema_Cocina.Resolver_Receta_Olla(["marisco", "arroz"]), "arroz")
	assert_eq(Sistema_Cocina.Resolver_Receta_Olla(["tomate"]), "")
	assert_eq(Sistema_Cocina.Identificar_Plato_Mercado("pisto", "huevo"), "pisto_huevo")
	assert_eq(Sistema_Cocina.Identificar_Plato_Mercado("fabada", "huevo"), "")


func test_03_ventana_del_horno_y_plato_de_alta_cocina() -> void:
	assert_eq(Sistema_Cocina.Estado_Proteina_Alta(0.40), "crudo")
	assert_eq(Sistema_Cocina.Estado_Proteina_Alta(0.70), "listo")
	assert_eq(Sistema_Cocina.Estado_Proteina_Alta(0.95), "pasado")
	assert_eq(Sistema_Cocina.Identificar_Plato_Alta("solomillo", "reduccion", "pure"),
		"solomillo_tinto")
	assert_eq(Sistema_Cocina.Identificar_Plato_Alta("lubina", "reduccion", "esparragos"),
		"lubina_blanca")
	assert_eq(Sistema_Cocina.Identificar_Plato_Alta("solomillo", "", "pure"), "")


func test_04_superar_un_mundo_desbloquea_el_siguiente() -> void:
	Variables_Dinamicas.Cocina_Estado["restaurantes_desbloqueados"] = ["burger_street"]
	Variables_Dinamicas.Cocina_Estado["estrellas_nivel"] = {}
	assert_false(Sistema_Cocina.Esta_Desbloqueado_Restaurante("bistro_tradicional"))
	Variables_Dinamicas.Cocina_Estado["estrellas_nivel"]["burger_street_1"] = 1
	assert_true(Sistema_Cocina.Esta_Desbloqueado_Restaurante("bistro_tradicional"),
		"Superar Burger Street debe abrir el Bistró")
	assert_false(Sistema_Cocina.Esta_Desbloqueado_Restaurante("cocina_mercado"))
	Variables_Dinamicas.Cocina_Estado["estrellas_nivel"]["bistro_tradicional_1"] = 1
	assert_true(Sistema_Cocina.Esta_Desbloqueado_Restaurante("cocina_mercado"))
	Variables_Dinamicas.Cocina_Estado["estrellas_nivel"]["cocina_mercado_1"] = 1
	assert_true(Sistema_Cocina.Esta_Desbloqueado_Restaurante("alta_cocina"))


func test_05_los_60_niveles_arrancan_sin_errores() -> void:
	for rest_id in ["bistro_tradicional", "cocina_mercado", "alta_cocina"]:
		var mini = await _Crear_Minijuego(rest_id)
		for nivel in range(1, 16):
			mini._Iniciar_Nivel(nivel)
			await get_tree().process_frame
			assert_eq(mini._nivel_actual, nivel)
			assert_false(mini._perfil_actual.is_empty(),
				"%s nivel %d debe tener perfil" % [rest_id, nivel])
			assert_false((mini._cfg_nivel_actual.get("menu", []) as Array).is_empty(),
				"%s nivel %d debe tener menú" % [rest_id, nivel])
			assert_gt(mini._bebida_items_actuales.size(), 0,
				"%s nivel %d debe tener bebidas" % [rest_id, nivel])
			if rest_id == "cocina_mercado":
				assert_not_null(mini._olla_ctrl)
				assert_true(mini._olla_ctrl.visible, "La olla debe estar visible")
		mini._Salir_Al_Sim()


func test_06_modo_qa_desbloquea_todos_los_mundos_y_niveles() -> void:
	Variables_Dinamicas.Cocina_Estado["restaurantes_desbloqueados"] = []
	Variables_Dinamicas.Cocina_Estado["estrellas_nivel"] = {}
	Sistema_Cocina.desbloqueo_total_qa = true
	assert_true(Sistema_Cocina.Esta_Desbloqueado_Minijuego(),
		"El modo QA debe abrir el minijuego sin trabajar")
	for rest_id in Sistema_Cocina.ORDEN_RESTAURANTES:
		assert_true(Sistema_Cocina.Esta_Desbloqueado_Restaurante(rest_id),
			"%s debe estar abierto en modo QA" % rest_id)
		for nivel in range(1, 16):
			assert_true(Sistema_Cocina.Esta_Nivel_Desbloqueado(rest_id, nivel),
				"%s nivel %d debe estar abierto en modo QA" % [rest_id, nivel])
	Sistema_Cocina.desbloqueo_total_qa = false
	assert_false(Sistema_Cocina.Esta_Desbloqueado_Restaurante("bistro_tradicional"),
		"Al desactivar QA vuelve el desbloqueo normal")


# ============================================================================
# Gameplay de cada mundo
# ============================================================================

func test_10_bistro_punto_patatas_y_cafe() -> void:
	var mini = await _Crear_Minijuego("bistro_tradicional")
	_Forzar_Cliente(mini, ["filete_patatas", "cafe"])

	# Filete a la parrilla
	mini._on_origen_tocado({}, {"datos": {"tipo": "bandeja", "ingrediente": "carne"}})
	assert_eq(str(mini._plancha[0]["estado"]), "cocinando")
	assert_eq((mini._slots_plancha_ui[0]["nodo"] as Control).get("tipo"), "filete")
	# Avanzar hasta al punto (~62% del tiempo total)
	mini._Tick_Slots_Coccion(mini._plancha, mini._slots_plancha_ui,
		mini._tiempo_coccion_carne, "Carne", mini._tiempo_coccion_carne * 0.64)
	assert_eq(str(mini._plancha[0]["punto"]), "al_punto",
		"El filete debe estar al punto")
	mini._on_plancha_pulsada(0)
	assert_eq(str(mini._plancha[0]["estado"]), "vacio")
	assert_eq(str(mini._platos[0]["proteina"]), "filete")
	assert_eq(str(mini._platos[0]["punto"]), "al_punto")

	# Patatas a la freidora y al pase
	mini._on_origen_tocado({}, {"datos": {"tipo": "bandeja", "ingrediente": "patatas"}})
	mini._Tick_Slots_Coccion(mini._freidora, mini._slots_freidora_ui,
		mini._tiempo_coccion_patatas, "Patatas", mini._tiempo_coccion_patatas + 0.1)
	mini._on_freidora_pulsada(0)
	assert_eq(str(mini._platos[0]["guarnicion"]), "patatas")
	assert_eq(mini._Receta_De_Plato(mini._platos[0]), "filete_patatas")

	# Servir plato y café arrastrando al cliente
	assert_true(mini._Soltar_En_Cliente(
		{"tipo": "plato", "indice": 0, "receta": "filete_patatas"}, 0))
	assert_true(bool(mini._clientes[0]["entregados"][0]))
	assert_true(mini._Soltar_En_Cliente(
		{"tipo": "bebida", "indice": 0, "item": "cafe"}, 0))
	assert_false(bool(mini._clientes[0]["activo"]),
		"El café debe completar el pedido")
	assert_gt(mini._recaudacion, 0)
	assert_eq(str(mini._bebidas[0].get("item", "")), "cafe")
	mini._Salir_Al_Sim()


func test_11_mercado_olla_por_lotes_y_huevo() -> void:
	var mini = await _Crear_Minijuego("cocina_mercado")
	_Forzar_Cliente(mini, ["pisto_huevo", "agua"])

	# Preparar pisto en la olla
	mini._Anadir_Ingrediente_Olla("tomate")
	mini._Anadir_Ingrediente_Olla("pimiento")
	assert_eq(str(mini._olla["estado"]), "cocinando")
	mini._olla["progreso"] = 0.99
	mini._process(0.2)
	assert_eq(str(mini._olla["estado"]), "listo")
	assert_eq(int(mini._olla["raciones"]), 4, "La olla rinde 4 raciones")

	# Servir una ración al pase
	mini._Servir_Racion_Olla()
	assert_eq(str(mini._platos[0]["guiso"]), "pisto")
	assert_eq(int(mini._olla["raciones"]), 3)

	# Freír el huevo y añadirlo al pisto
	mini._on_origen_tocado({}, {"datos": {"tipo": "bandeja", "ingrediente": "huevo"}})
	mini._Tick_Slots_Coccion(mini._freidora, mini._slots_freidora_ui,
		mini._tiempo_coccion_b, "Huevo", mini._tiempo_coccion_b + 0.1)
	mini._on_freidora_pulsada(0)
	assert_eq(str(mini._platos[0]["extra"]), "huevo")
	assert_eq(mini._Receta_De_Plato(mini._platos[0]), "pisto_huevo")

	assert_true(mini._Soltar_En_Cliente(
		{"tipo": "plato", "indice": 0, "receta": "pisto_huevo"}, 0))
	assert_true(mini._Soltar_En_Cliente(
		{"tipo": "bebida", "indice": 0, "item": "agua"}, 0))
	assert_false(bool(mini._clientes[0]["activo"]))
	assert_eq(str(mini._bebidas[0].get("item", "")), "agua")
	mini._Salir_Al_Sim()


func test_12_alta_cocina_horno_salsa_y_maridaje() -> void:
	var mini = await _Crear_Minijuego("alta_cocina")
	_Forzar_Cliente(mini, ["solomillo_tinto", "vino_tinto"])

	# Proteína al horno: retirar dentro de la ventana dorada
	mini._on_origen_tocado({}, {"datos": {"tipo": "bandeja", "ingrediente": "solomillo"}})
	assert_eq(str(mini._plancha[0]["estado"]), "cocinando")
	mini._Tick_Slots_Coccion(mini._plancha, mini._slots_plancha_ui,
		mini._tiempo_coccion_carne, "Solomillo", mini._tiempo_coccion_carne * 0.72)
	assert_eq(str(mini._plancha[0]["estado"]), "listo")
	mini._on_plancha_pulsada(0)
	assert_eq(str(mini._platos[0]["proteina"]), "solomillo")

	# Salsa y puré
	assert_true(mini._Soltar_En_Plato({"tipo": "salsa"}, 0))
	assert_true(mini._Soltar_En_Plato({"tipo": "ingrediente", "id": "pure"}, 0))
	assert_eq(mini._Receta_De_Plato(mini._platos[0]), "solomillo_tinto")

	# Servir primero el vino correcto y luego el plato arrastrando
	assert_true(mini._Soltar_En_Cliente(
		{"tipo": "bebida", "indice": 0, "item": "vino_tinto"}, 0))
	assert_true(bool(mini._clientes[0]["entregados"][1]),
		"La copa de tinto debe servirse")
	assert_true(mini._Soltar_En_Cliente(
		{"tipo": "plato", "indice": 0, "receta": "solomillo_tinto"}, 0))
	assert_false(bool(mini._clientes[0]["activo"]))
	assert_gt(mini._recaudacion, 0)
	assert_eq(str(mini._bebidas[0].get("item", "")), "vino_tinto")
	mini._Salir_Al_Sim()


func test_13_salsa_se_quema_y_se_remueve() -> void:
	var mini = await _Crear_Minijuego("alta_cocina")
	mini._sarten["quemado"] = 0.999
	mini._sarten["estado"] = "lista"
	mini._process(0.2)
	assert_eq(str(mini._sarten["estado"]), "arruinada",
		"La salsa debe quemarse si no se remueve")
	mini._Remover_Salsa()
	assert_eq(str(mini._sarten["estado"]), "lista")
	assert_lt(float(mini._sarten["quemado"]), 0.5)
	mini._Salir_Al_Sim()


func test_14_pedidos_de_alta_cocina_llevan_maridaje() -> void:
	var mini = await _Crear_Minijuego("alta_cocina")
	for _i in range(3):
		mini._Intentar_Spawnear_Cliente()
	for cl in mini._clientes:
		if not bool(cl["activo"]):
			continue
		var items: Array = cl["items"]
		assert_eq(items.size(), 2, "Plato + vino")
		var rec: Dictionary = Sistema_Cocina.Obtener_Receta("alta_cocina", str(items[0]))
		assert_eq(str(items[1]), str(rec.get("maridaje", "")),
			"El vino debe ser el maridaje del plato")
	mini._Salir_Al_Sim()


# ============================================================================
# Bistró: mejoras propias, retirada de quemados, servicio por toque y pase
# ============================================================================

func test_15_mejoras_del_bistro_tienen_texto_y_beneficios_propios() -> void:
	assert_true(Sistema_Cocina.MEJORAS_UI_POR_RESTAURANTE.has("bistro_tradicional"))
	var overrides: Dictionary = Sistema_Cocina.MEJORAS_UI_POR_RESTAURANTE["bistro_tradicional"]
	for mejora_id in Sistema_Cocina.ORDEN_MEJORAS:
		assert_true(overrides.has(mejora_id),
			"El Bistró debe definir el texto de la mejora %s" % mejora_id)
		for nivel in range(1, 4):
			var benef_bistro: Array = Sistema_Cocina.Obtener_Beneficios_Nivel_Mejora(
				mejora_id, nivel, "bistro_tradicional")
			var benef_burger: Array = Sistema_Cocina.Obtener_Beneficios_Nivel_Mejora(
				mejora_id, nivel, "burger_street")
			assert_false(benef_bistro.is_empty(),
				"%s Nv.%d debe tener beneficios" % [mejora_id, nivel])
			assert_ne(benef_bistro, benef_burger,
				"%s Nv.%d no debe repetir el texto de Burger Street" % [mejora_id, nivel])
			assert_ne(Sistema_Cocina.Obtener_Frase_Nivel_Mejora(mejora_id, nivel, "bistro_tradicional"),
				Sistema_Cocina.Obtener_Frase_Nivel_Mejora(mejora_id, nivel, "burger_street"),
				"%s Nv.%d debe tener una frase propia del Bistró" % [mejora_id, nivel])
	assert_eq(Sistema_Cocina.Obtener_Nombre_Mejora("bistro_tradicional", "emplatado"),
		"Pase y Cafetera")
	var benef_emplatado: Array = Sistema_Cocina.Obtener_Beneficios_Nivel_Mejora(
		"emplatado", 1, "bistro_tradicional")
	assert_true(" ".join(benef_emplatado).to_lower().contains("taza"),
		"El pase del Bistró habla de tazas de café, no de vasos de refresco")
	assert_true(" ".join(benef_emplatado).to_lower().contains("café"),
		"El pase del Bistró debe nombrar el café")


func test_16_bistro_quemado_se_retira_por_toque_y_arrastre() -> void:
	var mini = await _Crear_Minijuego("bistro_tradicional")
	mini._Iniciar_Coccion_A(0, "carne")
	mini._plancha[0]["progreso"] = 1.0
	mini._plancha[0]["quemado"] = 0.9
	mini._Tick_Slots_Coccion(mini._plancha, mini._slots_plancha_ui,
		mini._tiempo_coccion_carne, "Filete", 0.02)
	assert_eq(str(mini._plancha[0]["estado"]), "quemado")

	# El quemado se puede arrastrar (a la basura) aunque no se pueda emplatar.
	var payload: Dictionary = mini._Obtener_Payload_Plancha({"indice": 0})
	assert_false(payload.is_empty(), "El filete quemado debe poder cogerse")
	assert_eq(str(payload.get("payload", {}).get("tipo", "")), "carne_quemada")
	assert_true(mini._Soltar_En_Papelera(payload.get("payload", {})),
		"Arrastrar el quemado a la basura debe descartarlo")
	assert_eq(str(mini._plancha[0]["estado"]), "vacio")

	# Tocar el siguiente quemado también lo retira.
	mini._Iniciar_Coccion_A(0, "carne")
	mini._plancha[0]["progreso"] = 1.0
	mini._plancha[0]["quemado"] = 0.9
	mini._Tick_Slots_Coccion(mini._plancha, mini._slots_plancha_ui,
		mini._tiempo_coccion_carne, "Filete", 0.02)
	mini._on_plancha_pulsada(0)
	assert_eq(str(mini._plancha[0]["estado"]), "vacio",
		"Tocar un filete quemado debe limpiar la parrilla")
	mini._Salir_Al_Sim()


func test_17_bistro_servir_exige_arrastre_al_cliente() -> void:
	var mini = await _Crear_Minijuego("bistro_tradicional")
	_Forzar_Cliente(mini, ["filete_punto"])
	assert_true(mini._Soltar_En_Plato(
		{"tipo": "proteina", "proteina": "filete", "punto": "al_punto"}, 0))
	assert_eq(mini._Receta_De_Plato(mini._platos[0]), "filete_punto")
	# Tocar el plato o al cliente NO debe entregar el pedido automáticamente.
	mini._on_plato_pulsado(0)
	mini._on_cliente_pulsado(0)
	assert_false(bool(mini._clientes[0]["entregados"][0]),
		"Tocar el plato o al cliente no debe servir sin arrastrar")
	assert_true(bool(mini._clientes[0]["activo"]))
	assert_true(mini._Soltar_En_Cliente(
		{"tipo": "plato", "indice": 0, "receta": "filete_punto"}, 0))
	assert_true(bool(mini._clientes[0]["entregados"][0]),
		"Arrastrar el plato debe servirlo al cliente que lo pide")
	assert_false(bool(mini._clientes[0]["activo"]))

	# Cliente con plato + café: ambos se entregan arrastrando.
	_Forzar_Cliente(mini, ["filete_punto", "cafe"])
	assert_true(mini._Soltar_En_Plato(
		{"tipo": "proteina", "proteina": "filete", "punto": "al_punto"}, 1))
	assert_true(mini._Soltar_En_Cliente(
		{"tipo": "plato", "indice": 1, "receta": "filete_punto"}, 0))
	assert_true(bool(mini._clientes[0]["entregados"][0]),
		"Arrastrar el plato debe entregarlo")
	# El pedido sigue abierto hasta servir el café.
	assert_true(bool(mini._clientes[0]["activo"]))
	assert_true(mini._Soltar_En_Cliente(
		{"tipo": "bebida", "indice": 0, "item": "cafe"}, 0))
	assert_false(bool(mini._clientes[0]["activo"]),
		"Arrastrar el café debe completar el pedido")
	assert_true(bool(mini._clientes[0]["entregados"][1]))
	mini._Salir_Al_Sim()


func test_18_pase_del_bistro_alineado_en_sus_cuatro_huecos() -> void:
	var mini = await _Crear_Minijuego("bistro_tradicional")
	var caja := Rect2(Vector2.ZERO, mini._bandeja_emplatado.size)
	var celdas: Array[Rect2] = Arte_Cocina.celdas_emplatado(caja)
	assert_eq(celdas.size(), 4)
	for i in range(mini._slots_platos_ui.size()):
		var celda: Rect2 = mini._slots_platos_ui[i]["rect"]
		var esperada := Rect2(mini._bandeja_emplatado.position + celdas[i].position,
			celdas[i].size)
		assert_almost_eq(celda.position.x, esperada.position.x, 0.01)
		assert_almost_eq(celda.position.y, esperada.position.y, 0.01)
		assert_almost_eq(celda.size.x, esperada.size.x, 0.01)
		assert_almost_eq(celda.size.y, esperada.size.y, 0.01)
		var plato_rect := Arte_Cocina.rect_plato_visible(celda, "bistro_tradicional")
		assert_almost_eq(plato_rect.get_center().x, celda.get_center().x, 0.01,
			"El plato %d debe estar centrado horizontalmente" % i)
		assert_true(plato_rect.size.x <= celda.size.x - 2.0,
			"El plato %d no debe invadir la celda vecina" % i)
		assert_between(plato_rect.get_center().y,
			celda.position.y + celda.size.y * 0.42,
			celda.position.y + celda.size.y * 0.72,
			"El plato %d debe compartir la línea del pase" % i)
		if i > 0:
			assert_gt(celdas[i].position.x - celdas[i - 1].end.x, 0.0,
				"Los huecos del pase no pueden solaparse")
	mini._Salir_Al_Sim()


func test_19_zona_de_toque_del_arrastre_dispara_accion_sin_arrastrar() -> void:
	var arrastre = load("res://Scripts/GUI/Minijuego_Cocina/Arrastre_Cocina.gd").new()
	add_child_autofree(arrastre)
	var recibidos: Array = []
	arrastre.zona_tocada.connect(func(datos: Dictionary): recibidos.append(datos))
	arrastre.registrar_toque(Rect2(10.0, 10.0, 120.0, 120.0),
		{"tipo": "cliente", "indice": 2})

	arrastre._Iniciar_Pulsacion(Vector2(50.0, 50.0))
	assert_true(arrastre._presionando, "La zona de toque debe registrar la pulsación")
	arrastre._Soltar(Vector2(50.0, 50.0))
	assert_eq(recibidos.size(), 1, "Un toque corto debe disparar la acción")
	assert_eq(int(recibidos[0].get("indice", -1)), 2)

	# Un movimiento mayor que el umbral cancela el toque y no sirve nada.
	arrastre._Iniciar_Pulsacion(Vector2(50.0, 50.0))
	arrastre._Mover(Vector2(90.0, 50.0))
	assert_false(arrastre._presionando, "Arrastrar debe cancelar la acción de toque")
	arrastre._Soltar(Vector2(90.0, 50.0))
	assert_eq(recibidos.size(), 1, "El gesto de arrastre no debe disparar el toque")


func test_20_bistro_con_mejoras_maximas_llena_el_pase_sin_solapes() -> void:
	Variables_Dinamicas.Cocina_Estado["mejoras"]["bistro_tradicional"] = {
		"plancha": 3, "emplatado": 3, "termostato": 3,
		"ingredientes": 3, "ambiente": 3
	}
	var mini = await _Crear_Minijuego("bistro_tradicional")
	assert_eq(mini._slots_platos_ui.size(), 4, "Emplatado Nv.3 abre los 4 platos")
	assert_eq(mini._bebidas.size(), 3, "Emplatado Nv.3 abre 3 tazas de café")
	assert_eq(mini._plancha.size(), 4, "Parrilla Nv.3 tiene 4 huecos")
	assert_eq(mini._freidora.size(), 2, "Parrilla Nv.3 tiene 2 cestas")
	assert_eq(mini._bandeja_emplatado.desbloqueados, 4)
	var rects: Array[Rect2] = []
	for slot in mini._slots_platos_ui:
		var r: Rect2 = slot["rect"]
		for otro in rects:
			assert_false(r.intersects(otro), "Los platos del pase no deben solaparse")
		rects.append(r)
		var plato_rect := Arte_Cocina.rect_plato_visible(r, "bistro_tradicional")
		assert_true(plato_rect.size.x <= r.size.x - 2.0,
			"El plato debe dejar margen dentro de su celda")
	mini._Salir_Al_Sim()


func test_21_bistro_toque_rapido_elige_el_plato_que_completa_el_pedido() -> void:
	var mini = await _Crear_Minijuego("bistro_tradicional")
	_Forzar_Cliente(mini, ["filete_patatas"])
	# Plato 0: solo patatas. Plato 1: vacío. El filete debe ir al plato 0
	# porque con las patatas forma justo la receta pedida.
	assert_true(mini._Soltar_En_Plato({"tipo": "patatas_listas"}, 0))
	mini._Iniciar_Coccion_A(0, "carne")
	mini._Tick_Slots_Coccion(mini._plancha, mini._slots_plancha_ui,
		mini._tiempo_coccion_carne, "Filete", mini._tiempo_coccion_carne * 0.64)
	mini._on_plancha_pulsada(0)
	assert_eq(str(mini._platos[0].get("proteina", "")), "filete",
		"El toque rápido debe poner el filete en el plato con patatas")
	assert_eq(str(mini._platos[1].get("proteina", "")), "",
		"No debe usar el plato vacío si otro completa el pedido")
	assert_eq(mini._Receta_De_Plato(mini._platos[0]), "filete_patatas")

	# Salsa para un filete completo: solo debe ir al plato que ya tiene
	# filete + patatas, no al plato vacío.
	_Forzar_Cliente(mini, ["filete_completo"])
	mini._Limpiar_Plato(0)
	mini._Limpiar_Plato(1)
	mini._Soltar_En_Plato({"tipo": "proteina", "proteina": "filete",
		"punto": "al_punto"}, 1)
	mini._Soltar_En_Plato({"tipo": "patatas_listas"}, 1)
	mini._Accion_Rapida_Bistro("salsa")
	assert_eq(mini._Receta_De_Plato(mini._platos[1]), "filete_completo",
		"La salsa del toque rápido debe completar el plato correcto")
	assert_eq(str(mini._platos[0].get("salsa", "")), "",
		"La salsa no debe ir a un plato vacío")
	mini._Salir_Al_Sim()
