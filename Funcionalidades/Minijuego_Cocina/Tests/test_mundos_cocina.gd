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
		"Cazuelas y Plancha")
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
	assert_eq(Sistema_Cocina.Identificar_Plato_Bistro("filete", "hecho", "", ""),
		"filete_hecho")
	assert_eq(Sistema_Cocina.Identificar_Plato_Bistro("filete", "crudo", "", ""), "")
	assert_eq(Sistema_Cocina.Identificar_Plato_Bistro("filete", "hecho", "", "salsa"), "")


func test_02_olla_combos_y_plato_del_mercado() -> void:
	assert_true(Sistema_Cocina.Olla_Acepta_Ingrediente([], "alubias"))
	assert_false(Sistema_Cocina.Olla_Acepta_Ingrediente(["alubias"], "tomate"),
		"No se puede mezclar alubias con tomate")
	assert_true(Sistema_Cocina.Olla_Acepta_Ingrediente(["tomate"], "arroz"),
		"Tomate + Arroz debe ser combinación cruzada válida")
	assert_true(Sistema_Cocina.Olla_Acepta_Ingrediente(["alubias"], "marisco"))
	assert_true(Sistema_Cocina.Olla_Acepta_Ingrediente(["tomate"], "marisco"))
	assert_true(Sistema_Cocina.Olla_Acepta_Ingrediente(["chorizo"], "pimiento"))
	assert_eq(Sistema_Cocina.Resolver_Receta_Olla(["chorizo", "alubias"]), "fabada")
	assert_eq(Sistema_Cocina.Resolver_Receta_Olla(["marisco", "arroz"]), "arroz")
	assert_eq(Sistema_Cocina.Resolver_Receta_Olla(["tomate", "arroz"]), "arroz_tomate")
	assert_eq(Sistema_Cocina.Resolver_Receta_Olla(["marisco", "alubias"]), "alubias_marisco")
	assert_eq(Sistema_Cocina.Resolver_Receta_Olla(["marisco", "tomate"]), "zarzuela")
	assert_eq(Sistema_Cocina.Resolver_Receta_Olla(["pimiento", "chorizo"]), "fritada")
	assert_eq(Sistema_Cocina.Resolver_Receta_Olla(["tomate"]), "")
	assert_eq(Sistema_Cocina.Identificar_Plato_Mercado("pisto", "huevo"), "pisto_huevo")
	assert_eq(Sistema_Cocina.Identificar_Plato_Mercado("arroz_tomate", "huevo"), "arroz_cubana")
	assert_eq(Sistema_Cocina.Identificar_Plato_Mercado("fabada", "huevo"), "")
	assert_true(Sistema_Cocina.Guiso_Acepta_Huevo("pisto"))
	assert_true(Sistema_Cocina.Guiso_Acepta_Huevo("arroz_tomate"))
	assert_false(Sistema_Cocina.Guiso_Acepta_Huevo("fabada"))
	assert_eq(Sistema_Cocina.Ingrediente_Parejas_Olla("tomate").size(), 3,
		"El tomate debe cruzar con pimiento, arroz y marisco")


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
				assert_not_null(mini._fogones_ctrl)
				assert_true(mini._fogones_ctrl.visible, "Los fogones deben estar visibles")
				assert_eq(mini._plancha.size(), 2, "Debe empezar con 2 cazuelas independientes")
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


func test_11_mercado_cazuelas_paralelas_y_huevo() -> void:
	var mini = await _Crear_Minijuego("cocina_mercado")
	_Forzar_Cliente(mini, ["pisto_huevo", "agua"])
	mini._clientes[1]["activo"] = true
	mini._clientes[1]["items"] = ["fabada"]
	mini._clientes[1]["entregados"] = [false]
	mini._clientes[1]["paciencia_max"] = 90.0
	mini._clientes[1]["paciencia"] = 90.0
	mini._clientes[1]["precio_total"] = 20
	mini._slots_clientes_ui[1]["visible_antes"] = true
	mini._slots_clientes_ui[1]["fase"] = "esperando"
	mini._Actualizar_Cliente_UI(1)

	# Empezar pisto en cazuela 0 y fabada en cazuela 1 en paralelo:
	# al añadir tomate y luego alubias (incompatible con pisto), abre la segunda cazuela.
	mini._Accion_Rapida_Mercado("tomate")
	assert_eq(str(mini._plancha[0]["estado"]), "preparando")
	mini._Accion_Rapida_Mercado("alubias")
	assert_eq(str(mini._plancha[1]["estado"]), "preparando",
		"Un ingrediente de otro guiso debe abrir la segunda cazuela en paralelo")
	# Completar ambos pares automáticamente por toque rápido
	mini._Accion_Rapida_Mercado("pimiento")
	mini._Accion_Rapida_Mercado("chorizo")
	assert_eq(str(mini._plancha[0]["estado"]), "cocinando")
	assert_eq(str(mini._plancha[0]["item"]), "pisto")
	assert_eq(str(mini._plancha[1]["estado"]), "cocinando")
	assert_eq(str(mini._plancha[1]["item"]), "fabada")

	mini._Tick_Slots_Coccion(mini._plancha, mini._slots_plancha_ui,
		mini._tiempo_coccion_carne, "Cazuela", mini._tiempo_coccion_carne + 0.1)
	assert_eq(str(mini._plancha[0]["estado"]), "listo")
	assert_eq(str(mini._plancha[1]["estado"]), "listo")

	# Pasar ambos guisos al pase (platos 0 y 1) sin bloquearse
	mini._on_plancha_pulsada(0)
	mini._on_plancha_pulsada(1)
	assert_eq(str(mini._plancha[0]["estado"]), "vacio")
	assert_eq(str(mini._plancha[1]["estado"]), "vacio")
	assert_eq(str(mini._platos[0]["guiso"]), "pisto")
	assert_eq(str(mini._platos[1]["guiso"]), "fabada")

	# Freír el huevo y añadirlo al pisto
	mini._on_origen_tocado({}, {"datos": {"tipo": "bandeja", "ingrediente": "huevo"}})
	mini._Tick_Slots_Coccion(mini._freidora, mini._slots_freidora_ui,
		mini._tiempo_coccion_b, "Huevo", mini._tiempo_coccion_b + 0.1)
	mini._on_freidora_pulsada(0)
	assert_eq(str(mini._platos[0]["extra"]), "huevo")
	assert_eq(mini._Receta_De_Plato(mini._platos[0]), "pisto_huevo")
	assert_eq(mini._Receta_De_Plato(mini._platos[1]), "fabada")

	assert_true(mini._Soltar_En_Cliente(
		{"tipo": "plato", "indice": 0, "receta": "pisto_huevo"}, 0))
	assert_true(mini._Soltar_En_Cliente(
		{"tipo": "bebida", "indice": 0, "item": "agua"}, 0))
	assert_true(mini._Soltar_En_Cliente(
		{"tipo": "plato", "indice": 1, "receta": "fabada"}, 1))
	assert_false(bool(mini._clientes[0]["activo"]))
	assert_false(bool(mini._clientes[1]["activo"]))
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


func test_22_bistro_alerta_temprana_y_emplatado_en_alerta() -> void:
	var mini = await _Crear_Minijuego("bistro_tradicional")
	mini._Iniciar_Coccion_A(0, "carne")
	mini._Tick_Slots_Coccion(mini._plancha, mini._slots_plancha_ui,
		mini._tiempo_coccion_carne, "Filete", mini._tiempo_coccion_carne + 0.05)
	assert_eq(str(mini._plancha[0]["estado"]), "listo")
	# Avanzar hasta entrar en alerta temprana antes de quemarse
	mini._Tick_Slots_Coccion(mini._plancha, mini._slots_plancha_ui,
		mini._tiempo_coccion_carne, "Filete", mini._tiempo_quemado * 0.72)
	assert_eq(str(mini._plancha[0]["estado"]), "alerta",
		"El filete debe avisar con estado 'alerta' antes de quemarse")
	assert_true(mini._Puede_Anadir_A_Plato(
		{"tipo": "proteina", "proteina": "filete", "punto": "hecho", "estado": "alerta"}, 0),
		"Un filete en alerta temprana todavía es emplatado válido")
	# Pasado el margen restante, pasa a quemado
	mini._Tick_Slots_Coccion(mini._plancha, mini._slots_plancha_ui,
		mini._tiempo_coccion_carne, "Filete", mini._tiempo_quemado * 0.40)
	assert_eq(str(mini._plancha[0]["estado"]), "quemado",
		"Pasado _tiempo_quemado debe marcarse como quemado")
	mini._Salir_Al_Sim()


func test_23_bistro_despensa_parrilla_y_cafetera_nv3_sin_solapes() -> void:
	Variables_Dinamicas.Cocina_Estado["mejoras"]["bistro_tradicional"] = {
		"plancha": 3, "emplatado": 3, "termostato": 3,
		"ingredientes": 3, "ambiente": 3
	}
	var mini = await _Crear_Minijuego("bistro_tradicional")
	# Los 5 puestos útiles (carne, patatas, salsa, perejil, tarta) dentro del estante
	assert_eq(mini._bandeja_items_ui.size(), 5)
	var cajas: Array[Rect2] = []
	for item in mini._bandeja_items_ui:
		var r: Rect2 = item["rect"]
		assert_true(r.position.x >= 0.0 and r.end.x <= 1280.0,
			"Puesto Bistró fuera horizontalmente: %s" % str(item["ingrediente"]))
		assert_true(r.position.y >= 620.0 and r.end.y <= 720.0,
			"Puesto Bistró fuera del estante: %s" % str(item["ingrediente"]))
		for otra in cajas:
			assert_false(r.intersects(otra), "Los puestos Bistró no deben solaparse")
		cajas.append(r)
	if mini._despensa_pila != null:
		assert_false(mini._despensa_pila.visible, "Bistró no debe mostrar adornos sin uso")

	# 3 tazas de café centradas en la cafetera sin solape
	assert_eq(mini._slots_bebidas_ui.size(), 3)
	var beb_rects: Array[Rect2] = []
	for bslot in mini._slots_bebidas_ui:
		var br: Rect2 = bslot["rect"]
		assert_true(br.position.x >= 432.0 and br.end.x <= 582.0,
			"Tazas de café deben quedar dentro de la cafetera")
		for otra in beb_rects:
			assert_false(br.intersects(otra), "Las 3 tazas no deben solaparse entre sí")
		beb_rects.append(br)

	# 4 fogones de la parrilla sin pisarse entre filas
	assert_eq(mini._slots_plancha_ui.size(), 4)
	for i in range(4):
		var sr: Rect2 = mini._slots_plancha_ui[i]["rect"]
		for j in range(i + 1, 4):
			assert_false(sr.intersects(mini._slots_plancha_ui[j]["rect"]),
				"Los 4 fogones de la parrilla no deben solaparse")
	mini._Salir_Al_Sim()


func test_24_bistro_tutorial_nivel_1_guia_pasos_sin_errores() -> void:
	var mini = await _Crear_Minijuego("bistro_tradicional")
	_Forzar_Cliente(mini, ["filete_punto", "cafe"])
	mini._Actualizar_Tutorial()
	assert_true(mini._tutorial_foco.visible, "Nivel 1 Bistró sin superar debe mostrar tutorial")
	assert_true(mini._tutorial_foco.focos.size() >= 1)
	assert_ne(mini._tutorial_label.text, "")
	mini._Salir_Al_Sim()


func test_25_bistro_tolerancia_punto_perejil_y_variedad_niveles() -> void:
	# 1) Variedad desde el nivel 1: poco hecho, al punto y hecho en el menú
	var cfg_1: Dictionary = Sistema_Cocina.Obtener_Config_Nivel("bistro_tradicional", 1)
	var menu_1: Array = cfg_1.get("menu", [])
	assert_has(menu_1, "filete_poco_hecho")
	assert_has(menu_1, "filete_punto")
	assert_has(menu_1, "filete_hecho")
	var cfg_2: Dictionary = Sistema_Cocina.Obtener_Config_Nivel("bistro_tradicional", 2)
	assert_has(cfg_2.get("menu", []), "filete_salsa")
	assert_has(cfg_2.get("menu", []), "filete_perejil")
	var cfg_7: Dictionary = Sistema_Cocina.Obtener_Config_Nivel("bistro_tradicional", 7)
	assert_has(cfg_7.get("menu", []), "tarta_cereza")
	assert_has(cfg_7.get("menu", []), "solomillo_gourmet")

	# 2) Reglas de tolerancia y rechazo por diferencia de punto o falta de perejil
	var coin_ok: Dictionary = Sistema_Cocina.Buscar_Coincidencia_Plato_Bistro(
		["filete_poco_hecho"], [false],
		{"proteina": "filete", "punto": "al_punto", "guarnicion": "", "salsa": "", "perejil": false})
	assert_true(bool(coin_ok["ok"]), "Poco hecho <-> al punto se acepta")
	assert_eq(int(coin_ok["distancia"]), 1)
	assert_lt(float(coin_ok["factor_pago"]), 1.0, "1 salto de punto paga menos")

	var coin_sin_perejil: Dictionary = Sistema_Cocina.Buscar_Coincidencia_Plato_Bistro(
		["filete_perejil"], [false],
		{"proteina": "filete", "punto": "al_punto", "guarnicion": "", "salsa": "", "perejil": false})
	assert_false(bool(coin_sin_perejil["ok"]),
		"El perejil es obligatorio cuando el pedido lo incluye")

	var coin_extremo: Dictionary = Sistema_Cocina.Buscar_Coincidencia_Plato_Bistro(
		["filete_poco_hecho"], [false],
		{"proteina": "filete", "punto": "hecho", "guarnicion": "", "salsa": "", "perejil": false})
	assert_false(bool(coin_extremo["ok"]), "Poco hecho <-> hecho NO se acepta")
	assert_eq(str(coin_extremo["motivo"]), "punto_muy_distinto")

	var coin_crudo: Dictionary = Sistema_Cocina.Buscar_Coincidencia_Plato_Bistro(
		["filete_punto"], [false],
		{"proteina": "filete", "punto": "crudo", "guarnicion": "", "salsa": "", "perejil": false})
	assert_false(bool(coin_crudo["ok"]), "Crudo nunca se acepta")

	# 3) Entrega con 1 salto paga menos y el perejil funciona como ingrediente obligatorio igual que salsa
	var mini = await _Crear_Minijuego("bistro_tradicional")
	_Forzar_Cliente(mini, ["filete_perejil"])
	mini._clientes[0]["precio_total"] = 17
	assert_true(mini._Soltar_En_Plato({"tipo": "proteina", "proteina": "filete", "punto": "al_punto"}, 0))
	assert_false(mini._Puede_Servir_A_Cliente({"tipo": "plato", "indice": 0, "receta": "filete_punto"}, 0),
		"No se puede entregar sin perejil si el cliente pidió con perejil")
	mini._Accion_Rapida_Bistro("perejil")
	assert_true(bool(mini._platos[0]["perejil"]))
	assert_eq(mini._Receta_De_Plato(mini._platos[0]), "filete_perejil")
	assert_true(mini._Puede_Servir_A_Cliente({"tipo": "plato", "indice": 0, "receta": "filete_perejil"}, 0))
	assert_true(mini._Soltar_En_Cliente({"tipo": "plato", "indice": 0, "receta": "filete_perejil"}, 0))

	# 4) Tolerancia de 1 salto sobre pedido de poco hecho cobrando menos
	_Forzar_Cliente(mini, ["filete_poco_hecho"])
	mini._clientes[0]["precio_total"] = 14
	assert_true(mini._Soltar_En_Plato({"tipo": "proteina", "proteina": "filete", "punto": "al_punto"}, 0))
	assert_true(mini._Soltar_En_Cliente({"tipo": "plato", "indice": 0, "receta": "filete_punto"}, 0))
	assert_lt(mini._recaudacion - mini._propinas_servicio, 17 + 14,
		"Servir un punto aproximado debe cobrar menos dinero base")

	# Piden hecho y servimos poco_hecho -> rechazado (2 pasos)
	_Forzar_Cliente(mini, ["entrecot_hecho"])
	assert_false(mini._Puede_Servir_A_Cliente({"tipo": "plato", "indice": 1, "receta": ""}, 0))
	assert_true(mini._Soltar_En_Plato({"tipo": "proteina", "proteina": "filete", "punto": "poco_hecho"}, 1))
	assert_true(mini._Soltar_En_Plato({"tipo": "patatas_listas"}, 1))
	assert_false(mini._Puede_Servir_A_Cliente({"tipo": "plato", "indice": 1, "receta": ""}, 0),
		"Poco hecho no sirve para entrecot hecho (2 pasos de diferencia)")
	mini._Salir_Al_Sim()


func test_26_mercado_quemados_cazuela_parcial_y_mejoras_nv3() -> void:
	# 1) Cazuela parcial se vacía en basura; arrastrar ingredientes a cazuela cocina el guiso
	var mini = await _Crear_Minijuego("cocina_mercado")
	mini._Accion_Rapida_Mercado("alubias")
	var pay_parcial: Dictionary = mini._Obtener_Payload_Plancha({"indice": 0})
	assert_eq(str(pay_parcial.get("payload", {}).get("tipo", "")), "cazuela_parcial")
	assert_true(mini._Soltar_En_Papelera(pay_parcial["payload"]))
	assert_eq(str(mini._plancha[0]["estado"]), "vacio",
		"Tirar la cazuela parcial a la basura debe vaciar el fogón")
	assert_eq((mini._plancha[0].get("ingredientes", []) as Array).size(), 0)

	# 2) Arrastrar ingredientes a la misma cazuela vía _Aplicar_Soltar cocina el guiso;
	# si se deja demasiado tiempo se quema y se retira por toque o basura.
	assert_true(mini._Aplicar_Soltar({"tipo": "ingrediente", "id": "alubias"},
		{"aceptado": true, "datos": {"tipo": "plancha", "indice": 0}}))
	assert_true(mini._Aplicar_Soltar({"tipo": "ingrediente", "id": "chorizo"},
		{"aceptado": true, "datos": {"tipo": "plancha", "indice": 0}}))
	assert_eq(str(mini._plancha[0]["estado"]), "cocinando")
	assert_eq(str(mini._plancha[0]["item"]), "fabada")
	mini._Tick_Slots_Coccion(mini._plancha, mini._slots_plancha_ui,
		mini._tiempo_coccion_carne, "Cazuela", mini._tiempo_coccion_carne + 0.1)
	assert_eq(str(mini._plancha[0]["estado"]), "listo")
	mini._Tick_Slots_Coccion(mini._plancha, mini._slots_plancha_ui,
		mini._tiempo_coccion_carne, "Cazuela", mini._tiempo_quemado + 0.5)
	assert_eq(str(mini._plancha[0]["estado"]), "quemado")
	var pay_guiso_q: Dictionary = mini._Obtener_Payload_Plancha({"indice": 0})
	assert_eq(str(pay_guiso_q.get("payload", {}).get("tipo", "")), "guiso_quemado")
	assert_false(mini._Puede_Anadir_A_Plato(pay_guiso_q["payload"], 0),
		"Un guiso quemado no debe poder emplatarse")
	mini._on_plancha_pulsada(0)
	assert_eq(str(mini._plancha[0]["estado"]), "vacio",
		"Tocar una cazuela quemada debe descartarla")

	# 3) Huevo quemado queda marcado como huevo_quemado y no entra en pisto
	assert_true(mini._Soltar_En_Plato({"tipo": "guiso", "guiso": "pisto"}, 0))
	mini._Accion_Rapida_Mercado("huevo")
	mini._Tick_Slots_Coccion(mini._freidora, mini._slots_freidora_ui,
		mini._tiempo_coccion_b, "Huevo", mini._tiempo_coccion_b + 0.1)
	mini._Tick_Slots_Coccion(mini._freidora, mini._slots_freidora_ui,
		mini._tiempo_coccion_b, "Huevo", mini._tiempo_quemado + 0.5)
	assert_eq(str(mini._freidora[0]["estado"]), "quemado")
	var pay_huevo: Dictionary = mini._Obtener_Payload_Freidora({"indice": 0})
	assert_eq(str(pay_huevo.get("payload", {}).get("tipo", "")), "huevo_quemado")
	assert_false(mini._Puede_Anadir_A_Plato(pay_huevo["payload"], 0),
		"Un huevo quemado jamás debe emplatarse en el pisto")
	assert_true(mini._Soltar_En_Papelera(pay_huevo["payload"]))
	assert_eq(str(mini._freidora[0]["estado"]), "vacio")
	mini._Salir_Al_Sim()

	# 4) Mejoras Nv.3 en Mercado: 4 cazuelas sin solapes, 4 huecos huevo, 4 platos, 3 bebidas, 7 despensa sin solapes
	Variables_Dinamicas.Cocina_Estado["mejoras"]["cocina_mercado"] = {
		"plancha": 3, "emplatado": 3, "termostato": 3,
		"ingredientes": 3, "ambiente": 3
	}
	var mini3 = await _Crear_Minijuego("cocina_mercado")
	assert_eq(mini3._plancha.size(), 4, "Cazuelas y Plancha Nv.3 abre 4 cazuelas")
	assert_eq(mini3._freidora.size(), 4, "Cazuelas y Plancha Nv.3 abre 4 huecos de huevo")
	assert_eq(mini3._slots_platos_ui.size(), 4)
	assert_eq(mini3._bebidas.size(), 3)
	assert_eq(mini3._bandeja_items_ui.size(), 7, "Despensa de mercado tiene sus 7 ingredientes útiles")
	for i in range(4):
		var rc: Rect2 = mini3._slots_plancha_ui[i]["rect"]
		assert_true(mini3.ZONA_PLANCHA.encloses(rc), "Cada cazuela debe caber en ZONA_PLANCHA")
		for j in range(i + 1, 4):
			assert_false(rc.intersects(mini3._slots_plancha_ui[j]["rect"]),
				"Las 4 cazuelas no deben solaparse")
	for i in range(4):
		var rh: Rect2 = mini3._slots_freidora_ui[i]["rect"]
		for j in range(i + 1, 4):
			assert_false(rh.intersects(mini3._slots_freidora_ui[j]["rect"]),
				"Los 4 huevos de la plancha no deben solaparse")
	var cajas_m: Array[Rect2] = []
	for item in mini3._bandeja_items_ui:
		var rm: Rect2 = item["rect"]
		assert_true(rm.position.x >= 0.0 and rm.end.x <= 1280.0)
		assert_true(rm.position.y >= 620.0 and rm.end.y <= 720.0)
		for otra in cajas_m:
			assert_false(rm.intersects(otra), "Los puestos de Mercado no deben solaparse")
		cajas_m.append(rm)
	mini3._Salir_Al_Sim()


func test_27_mercado_tutorial_menus_y_variedad() -> void:
	var cfg_1: Dictionary = Sistema_Cocina.Obtener_Config_Nivel("cocina_mercado", 1)
	var menu_1: Array = cfg_1.get("menu", [])
	assert_has(menu_1, "fabada")
	assert_has(menu_1, "pisto")
	assert_has(menu_1, "agua")
	var cfg_2: Dictionary = Sistema_Cocina.Obtener_Config_Nivel("cocina_mercado", 2)
	assert_has(cfg_2.get("menu", []), "pisto_huevo")
	assert_has(cfg_2.get("menu", []), "sangria")
	var cfg_3: Dictionary = Sistema_Cocina.Obtener_Config_Nivel("cocina_mercado", 3)
	assert_has(cfg_3.get("menu", []), "arroz_senyoret")

	var mini = await _Crear_Minijuego("cocina_mercado")
	_Forzar_Cliente(mini, ["pisto_huevo", "agua"])
	mini._Actualizar_Tutorial()
	assert_true(mini._tutorial_foco.visible, "Nivel 1 Mercado sin superar debe mostrar tutorial")
	assert_true(mini._tutorial_foco.focos.size() >= 1)
	assert_true(mini._tutorial_label.text.contains("AGUA"),
		"Si el cliente pide bebida ya lista en barra, el tutorial indica servirla")
	_Forzar_Cliente(mini, ["pisto_huevo"])
	mini._Actualizar_Tutorial()
	assert_true(mini._tutorial_label.text.contains("TOMATE") \
		or mini._tutorial_label.text.contains("PIMIENTO"),
		"Debe guiar al primer ingrediente del pisto")
	mini._Accion_Rapida_Mercado("tomate")
	mini._Actualizar_Tutorial()
	assert_true(mini._tutorial_label.text.contains("PIMIENTO"),
		"El tutorial debe pedir el segundo ingrediente del pisto")
	mini._Salir_Al_Sim()


func test_28_mercado_gestos_reales_arrastre_y_toque() -> void:
	var mini = await _Crear_Minijuego("cocina_mercado")
	_Forzar_Cliente(mini, ["fabada"])

	var pos_puesto := func(ing_id: String) -> Vector2:
		for item in mini._bandeja_items_ui:
			if str(item["ingrediente"]) == ing_id:
				return (item["rect"] as Rect2).get_center()
		return Vector2.ZERO

	var caz0: Vector2 = (mini._slots_plancha_ui[0]["rect"] as Rect2).get_center()
	var caz1: Vector2 = (mini._slots_plancha_ui[1]["rect"] as Rect2).get_center()
	var plato0: Vector2 = (mini._slots_platos_ui[0]["rect"] as Rect2).get_center()
	var basura: Vector2 = mini._papelera_rect.get_center()

	# 1) Arrastrar alubias -> cazuela 0 y tomate -> cazuela 1 en paralelo
	mini._arrastre._Iniciar_Pulsacion(pos_puesto.call("alubias"))
	mini._arrastre._Mover(caz0)
	mini._arrastre._Soltar(caz0)
	assert_eq(str(mini._plancha[0]["estado"]), "preparando")

	mini._arrastre._Iniciar_Pulsacion(pos_puesto.call("tomate"))
	mini._arrastre._Mover(caz1)
	mini._arrastre._Soltar(caz1)
	assert_eq(str(mini._plancha[1]["estado"]), "preparando")

	# 2) Arrastrar cazuela 1 parcial (tomate) a la basura para vaciarla
	mini._arrastre._Iniciar_Pulsacion(caz1)
	mini._arrastre._Mover(basura)
	mini._arrastre._Soltar(basura)
	assert_eq(str(mini._plancha[1]["estado"]), "vacio")

	# 3) Completar fabada arrastrando chorizo a cazuela 0, cocer y arrastrar guiso al plato 0
	mini._arrastre._Iniciar_Pulsacion(pos_puesto.call("chorizo"))
	mini._arrastre._Mover(caz0)
	mini._arrastre._Soltar(caz0)
	assert_eq(str(mini._plancha[0]["estado"]), "cocinando")
	assert_eq(str(mini._plancha[0]["item"]), "fabada")

	mini._Tick_Slots_Coccion(mini._plancha, mini._slots_plancha_ui,
		mini._tiempo_coccion_carne, "Cazuela", mini._tiempo_coccion_carne + 0.1)
	assert_eq(str(mini._plancha[0]["estado"]), "listo")

	mini._arrastre._Iniciar_Pulsacion(caz0)
	mini._arrastre._Mover(plato0)
	mini._arrastre._Soltar(plato0)
	assert_eq(str(mini._plancha[0]["estado"]), "vacio")
	assert_eq(str(mini._platos[0]["guiso"]), "fabada")
	assert_eq(mini._Receta_De_Plato(mini._platos[0]), "fabada")
	mini._Salir_Al_Sim()


func test_29_mercado_sprites_y_estaciones() -> void:
	var texturas: Array[Texture2D] = [
		Arte_Cocina.TEX_MERCADO_FOGONES,
		Arte_Cocina.TEX_MERCADO_CAZUELA_VACIA,
		Arte_Cocina.TEX_MERCADO_FABADA,
		Arte_Cocina.TEX_MERCADO_PISTO,
		Arte_Cocina.TEX_MERCADO_PISTO_HUEVO,
		Arte_Cocina.TEX_MERCADO_ARROZ,
		Arte_Cocina.TEX_MERCADO_CAZUELA_QUEMADA,
		Arte_Cocina.TEX_MERCADO_PUESTO_ALUBIAS,
		Arte_Cocina.TEX_MERCADO_PUESTO_CHORIZO,
		Arte_Cocina.TEX_MERCADO_PUESTO_PIMIENTO,
		Arte_Cocina.TEX_MERCADO_PUESTO_ARROZ,
		Arte_Cocina.TEX_MERCADO_PUESTO_MARISCO,
		Arte_Cocina.TEX_MERCADO_PUESTO_HUEVO,
		Arte_Cocina.TEX_MERCADO_ING_ALUBIAS,
		Arte_Cocina.TEX_MERCADO_ING_CHORIZO,
		Arte_Cocina.TEX_MERCADO_ING_PIMIENTO,
		Arte_Cocina.TEX_MERCADO_ING_ARROZ,
		Arte_Cocina.TEX_MERCADO_ING_MARISCO,
		Arte_Cocina.TEX_MERCADO_ING_HUEVO,
		Arte_Cocina.TEX_MERCADO_HUEVO_FRITO,
		Arte_Cocina.TEX_MERCADO_HUEVO_QUEMADO,
		Arte_Cocina.TEX_MERCADO_SANGRIA,
		Arte_Cocina.TEX_MERCADO_BARRA,
	]
	assert_eq(texturas.size(), 23, "Deben existir los 23 sprites propios de Cocina de Mercado")
	for tex in texturas:
		assert_not_null(tex, "Cada textura de Cocina de Mercado debe cargarse sin nulos")
		assert_gte(tex.get_width(), 120, "Cada sprite debe conservar buena resolución")

	for item_id in ["fabada", "pisto", "pisto_huevo", "arroz_senyoret", "sangria",
			"alubias", "chorizo", "pimiento", "arroz", "marisco", "huevo", "huevo_frito"]:
		assert_ne(Arte_Cocina.textura_item(item_id), Arte_Cocina.TEX_PLATO,
			"%s debe resolver a su textura dedicada" % item_id)

	var beb := Arte_Cocina.Bebida.new()
	beb.tipo = "sangria"
	assert_eq(beb._textura(), Arte_Cocina.TEX_MERCADO_SANGRIA,
		"La sangría en barra debe usar su textura dedicada")
	beb.free()


func test_30_mercado_nivel1_guia_y_flujo_completo() -> void:
	var mini = await _Crear_Minijuego("cocina_mercado")
	assert_true(mini._btn_cocina_guia.visible, "El botón ? GUÍA debe verse en Cocina de Mercado")
	assert_false(mini._modal_guia.visible, "Iniciar directo desde _Iniciar_Nivel no bloquea tests")

	# Flujo real del jugador entrando al Nivel 1: tras carga abre automáticamente la guía y pausa el servicio.
	mini._Comenzar_Carga_Nivel(1)
	mini._Finalizar_Carga()
	assert_true(mini._modal_guia.visible, "Nivel 1 de Mercado debe mostrar automáticamente la guía visual")
	assert_false(mini._jugando, "Mientras la guía está abierta la partida queda en pausa")
	assert_true(mini._pausado_por_guia)

	var btn_cerrar = mini._modal_guia.find_child("Boton_Cerrar_Guia", true, false)
	assert_not_null(btn_cerrar, "La guía debe incluir botón explícito de cierre")
	btn_cerrar.pressed.emit()
	assert_false(mini._modal_guia.visible)
	assert_true(mini._jugando, "Cerrar la guía debe reanudar el servicio")
	assert_false(mini._pausado_por_guia)

	# Botón ? GUÍA en el HUD permite reabrirla y Escape / _Volver_Atras la cierra sin salir del nivel.
	mini._btn_cocina_guia.pressed.emit()
	assert_true(mini._modal_guia.visible)
	assert_false(mini._jugando)
	mini._Volver_Atras()
	assert_false(mini._modal_guia.visible)
	assert_true(mini._jugando)

	# En Nivel 2 no se abre sola automáticamente al terminar la carga.
	mini._Comenzar_Carga_Nivel(2)
	mini._Finalizar_Carga()
	assert_false(mini._modal_guia.visible, "Nivel 2 entra directo sin interrumpir con el modal automático")
	assert_true(mini._jugando)

	# Volver a Nivel 1 y completar un servicio variado en paralelo (Pisto c/huevo + Fabada + Agua + Sangría).
	mini._Iniciar_Nivel(1)
	_Forzar_Cliente(mini, ["pisto_huevo", "agua"])
	mini._clientes[1]["activo"] = true
	mini._clientes[1]["items"] = ["fabada", "sangria"]
	mini._clientes[1]["entregados"] = [false, false]
	mini._clientes[1]["paciencia_max"] = 90.0
	mini._clientes[1]["paciencia"] = 90.0
	mini._clientes[1]["precio_total"] = 45
	mini._slots_clientes_ui[1]["visible_antes"] = true
	mini._clientes_pendientes = maxi(0, mini._clientes_pendientes - 1)

	mini._Accion_Rapida_Mercado("tomate")
	mini._Accion_Rapida_Mercado("pimiento")
	mini._Accion_Rapida_Mercado("alubias")
	mini._Accion_Rapida_Mercado("chorizo")
	mini._on_origen_tocado({}, {"datos": {"tipo": "bandeja", "ingrediente": "huevo"}})
	mini._Tick_Slots_Coccion(mini._plancha, mini._slots_plancha_ui,
		mini._tiempo_coccion_carne, "Cazuela", mini._tiempo_coccion_carne + 0.1)
	mini._Tick_Slots_Coccion(mini._freidora, mini._slots_freidora_ui,
		mini._tiempo_coccion_b, "Huevo", mini._tiempo_coccion_b + 0.1)
	mini._on_plancha_pulsada(0)
	mini._on_plancha_pulsada(1)
	mini._on_freidora_pulsada(0)

	assert_eq(mini._Receta_De_Plato(mini._platos[0]), "pisto_huevo")
	assert_eq(mini._Receta_De_Plato(mini._platos[1]), "fabada")

	mini._Soltar_En_Cliente(mini._Obtener_Payload_Plato({"indice": 0})["payload"], 0)
	mini._Soltar_En_Cliente(mini._Obtener_Payload_Bebida({"indice": 0})["payload"], 0)
	mini._Soltar_En_Cliente(mini._Obtener_Payload_Plato({"indice": 1})["payload"], 1)
	mini._Soltar_En_Cliente(mini._Obtener_Payload_Bebida({"indice": 1})["payload"], 1)
	assert_gt(mini._recaudacion, 0, "Debe contabilizar las ventas de ambos menús")

	# En otros mundos el botón ? GUÍA de Mercado permanece oculto.
	var mini_burger = await _Crear_Minijuego("burger_street")
	assert_false(mini_burger._btn_cocina_guia.visible)
	mini_burger._Salir_Al_Sim()
	mini._Salir_Al_Sim()


func test_31_mercado_combos_cruzados_y_progresion() -> void:
	# Nuevos sprites y mapeo de los 5 platos cruzados
	for tex in [
		Arte_Cocina.TEX_MERCADO_ARROZ_TOMATE,
		Arte_Cocina.TEX_MERCADO_ARROZ_CUBANA,
		Arte_Cocina.TEX_MERCADO_ALUBIAS_MARISCO,
		Arte_Cocina.TEX_MERCADO_ZARZUELA,
		Arte_Cocina.TEX_MERCADO_FRITADA,
	]:
		assert_not_null(tex)
		assert_gte(tex.get_width(), 200)
	for rec_id in ["arroz_tomate", "arroz_cubana", "alubias_marisco", "zarzuela", "fritada"]:
		assert_ne(Arte_Cocina.textura_item(rec_id), Arte_Cocina.TEX_PLATO,
			"%s debe resolver a su sprite propio" % rec_id)

	# Progresión gradual en los 15 niveles (Nv.1-3 básicos -> Nv.4-8 cruces nuevos)
	assert_has(Sistema_Cocina.Obtener_Config_Nivel("cocina_mercado", 4).get("menu", []), "arroz_tomate")
	assert_has(Sistema_Cocina.Obtener_Config_Nivel("cocina_mercado", 5).get("menu", []), "arroz_cubana")
	assert_has(Sistema_Cocina.Obtener_Config_Nivel("cocina_mercado", 6).get("menu", []), "fritada")
	assert_has(Sistema_Cocina.Obtener_Config_Nivel("cocina_mercado", 7).get("menu", []), "alubias_marisco")
	assert_has(Sistema_Cocina.Obtener_Config_Nivel("cocina_mercado", 8).get("menu", []), "zarzuela")

	# Flujo en vivo: priorización inteligente del toque según pedido activo + Arroz a la cubana con huevo
	var mini = await _Crear_Minijuego("cocina_mercado")
	mini._Iniciar_Nivel(5)
	mini._spawn_timer = 9999.0
	_Forzar_Cliente(mini, ["arroz_cubana"])
	mini._clientes[1]["activo"] = true
	mini._clientes[1]["items"] = ["alubias_marisco"]
	mini._clientes[1]["entregados"] = [false]
	mini._clientes[1]["paciencia_max"] = 90.0
	mini._clientes[1]["paciencia"] = 90.0
	mini._clientes[1]["precio_total"] = 21
	mini._slots_clientes_ui[1]["visible_antes"] = true

	# Con tomate en cazuela 0 y marisco en cazuela 1, tocar arroz debe cerrar la cazuela 0
	# para arroz_tomate (base de arroz_cubana) o comprobar que tomate+arroz + huevo da arroz_cubana:
	mini._Accion_Rapida_Mercado("tomate")
	assert_eq(str(mini._plancha[0]["ingredientes"][0]), "tomate")
	mini._Accion_Rapida_Mercado("alubias")
	assert_eq(str(mini._plancha[1]["ingredientes"][0]), "alubias")

	# Ambos aceptan arroz o marisco respectivamente; tocar arroz completa cazuela 0 (tomate+arroz)
	mini._Accion_Rapida_Mercado("arroz")
	assert_eq(str(mini._plancha[0]["estado"]), "cocinando")
	assert_eq(str(mini._plancha[0]["item"]), "arroz_tomate")

	# Completar alubias + marisco en cazuela 1 y freír huevo
	mini._Accion_Rapida_Mercado("marisco")
	assert_eq(str(mini._plancha[1]["estado"]), "cocinando")
	assert_eq(str(mini._plancha[1]["item"]), "alubias_marisco")

	mini._on_origen_tocado({}, {"datos": {"tipo": "bandeja", "ingrediente": "huevo"}})
	mini._Tick_Slots_Coccion(mini._plancha, mini._slots_plancha_ui,
		mini._tiempo_coccion_carne, "Cazuela", mini._tiempo_coccion_carne + 0.1)
	mini._Tick_Slots_Coccion(mini._freidora, mini._slots_freidora_ui,
		mini._tiempo_coccion_b, "Huevo", mini._tiempo_coccion_b + 0.1)

	mini._on_plancha_pulsada(0)
	mini._on_plancha_pulsada(1)
	assert_eq(mini._Receta_De_Plato(mini._platos[0]), "arroz_tomate")
	assert_eq(mini._Receta_De_Plato(mini._platos[1]), "alubias_marisco")

	# Poner huevo encima del arroz con tomate -> arroz_cubana y entregar a ambos clientes
	mini._on_freidora_pulsada(0)
	assert_eq(mini._Receta_De_Plato(mini._platos[0]), "arroz_cubana")

	mini._Soltar_En_Cliente(mini._Obtener_Payload_Plato({"indice": 0})["payload"], 0)
	mini._Soltar_En_Cliente(mini._Obtener_Payload_Plato({"indice": 1})["payload"], 1)
	assert_gt(mini._recaudacion, 0, "Los cruces nuevos deben cobrarse correctamente")
	mini._Salir_Al_Sim()


func test_32_bocadillo_hover_muestra_elaboracion() -> void:
	# 1) Catálogo de elaboración transversal a los 4 mundos
	var d_cubana: Dictionary = Sistema_Cocina.Describir_Elaboracion_Receta("cocina_mercado", "arroz_cubana")
	assert_eq(str(d_cubana.get("titulo", "")), "Arroz a la cubana")
	assert_eq(d_cubana.get("ingredientes", []), ["tomate", "arroz", "huevo_frito"])
	assert_true(str(d_cubana.get("pasos", "")).contains("Huevo"))

	var d_zarzuela: Dictionary = Sistema_Cocina.Describir_Elaboracion_Receta("cocina_mercado", "zarzuela")
	assert_eq(d_zarzuela.get("ingredientes", []), ["tomate", "marisco"])

	var d_bistro: Dictionary = Sistema_Cocina.Describir_Elaboracion_Receta("bistro_tradicional", "filete_completo")
	assert_has(d_bistro.get("ingredientes", []), "patatas")
	assert_has(d_bistro.get("ingredientes", []), "salsa")

	var d_burger: Dictionary = Sistema_Cocina.Describir_Elaboracion_Receta("burger_street", "burger_completa")
	assert_eq((d_burger.get("ingredientes", []) as Array).size(), 5)

	var d_alta: Dictionary = Sistema_Cocina.Describir_Elaboracion_Receta("alta_cocina", "lubina_blanca")
	assert_eq(d_alta.get("ingredientes", []), ["lubina", "salsa", "esparragos"])

	# 2) En escena viva: pasar por encima de cada icono del bocadillo muestra cómo hacer ese plato exacto
	var mini = await _Crear_Minijuego("cocina_mercado")
	mini._Iniciar_Nivel(8)
	mini._spawn_timer = 9999.0
	_Forzar_Cliente(mini, ["zarzuela", "sangria"])
	mini._slots_clientes_ui[0]["fase"] = "esperando"
	var ticket: Arte_Cocina.Ticket = mini._slots_clientes_ui[0]["ticket"]
	ticket.items = ["zarzuela", "sangria"]
	ticket.entregados = [false, false]
	ticket.visible = true

	var r_buf := Arte_Cocina.rect_ajustado(Arte_Cocina.TEX_BURBUJA, Rect2(Vector2.ZERO, ticket.size))
	var entradas := ticket._rects_items(r_buf)
	assert_eq(entradas.size(), 2)
	var pos_zarzuela: Vector2 = ticket.position + (entradas[0]["centro"] as Vector2)
	var pos_sangria: Vector2 = ticket.position + (entradas[1]["centro"] as Vector2)

	mini._Actualizar_Hover_Bocadillos(pos_zarzuela)
	assert_true(mini._panel_tip_receta.visible, "Debe mostrarse el tooltip de elaboración al apuntar al plato")
	assert_eq(ticket.item_hover, 0)
	assert_true(mini._tip_receta_clave.ends_with(":zarzuela"))
	assert_gte(mini._panel_tip_receta.position.x, 0.0)
	assert_lte(mini._panel_tip_receta.position.x + mini._panel_tip_receta.size.x, 1280.0)

	# Mover al segundo icono (Sangría) cambia automáticamente al detalle de bebida
	mini._Actualizar_Hover_Bocadillos(pos_sangria)
	assert_eq(ticket.item_hover, 1)
	assert_true(mini._tip_receta_clave.ends_with(":sangria"))

	# Salir del bocadillo u ocultar al iniciar un arrastre limpia el tooltip
	mini._Actualizar_Hover_Bocadillos(Vector2(20.0, 20.0))
	assert_false(mini._panel_tip_receta.visible)
	assert_eq(ticket.item_hover, -1)

	mini._Actualizar_Hover_Bocadillos(pos_zarzuela)
	assert_true(mini._panel_tip_receta.visible)
	mini._on_arrastre_iniciado({}, {})
	assert_false(mini._panel_tip_receta.visible)
	mini._Salir_Al_Sim()


# ============================================================================
# Alta Cocina mejorada: pescado entero a clicks + fritura, horno, salsa, bodega y guía
# ============================================================================

func test_33_alta_cocina_pescado_cortar_a_clicks_y_freir() -> void:
	var mini = await _Crear_Minijuego("alta_cocina")
	mini._Iniciar_Nivel(5)
	mini._spawn_timer = 9999.0
	_Forzar_Cliente(mini, ["lubina_blanca", "vino_blanco"])

	# No debe aceptar pescado entero directo en horno, sartén ni plato sin cortar antes
	assert_false(mini._Soltar_En_Plancha({"tipo": "ingrediente", "id": "lubina"}, 0),
		"El horno no debe aceptar pescado entero")
	assert_false(mini._Soltar_En_Freidora({"tipo": "ingrediente", "id": "lubina"}, 0),
		"La sartén no debe aceptar pescado entero sin filetear")

	# Colocar lubina entera en la tabla de corte y cortar haciendo clicks repetidos
	mini._Accion_Rapida_Alta("lubina")
	assert_eq(str(mini._tabla_corte[0]["estado"]), "entero")
	assert_eq(int(mini._tabla_corte[0]["cortes"]), 0)
	var req: int = int(mini._tabla_corte[0]["cortes_req"])
	assert_eq(req, 4, "En Nv.1 requiere 4 clicks de corte")
	for c in range(req - 1):
		mini._on_tabla_corte_pulsada(0)
		assert_eq(str(mini._tabla_corte[0]["estado"]), "entero")
		assert_eq(int(mini._tabla_corte[0]["cortes"]), c + 1)
		assert_eq(str(mini._freidora[0]["estado"]), "vacio")
	# Último click lo deja fileteado
	mini._on_tabla_corte_pulsada(0)
	assert_eq(str(mini._tabla_corte[0]["estado"]), "cortado")

	# Tocar el pescado cortado lo pasa a la sartén de fritura
	mini._on_tabla_corte_pulsada(0)
	assert_eq(str(mini._tabla_corte[0]["estado"]), "vacio")
	assert_eq(str(mini._freidora[0]["estado"]), "cocinando")
	assert_eq(str(mini._freidora[0]["item"]), "lubina")

	# No puede servirse antes de freír
	mini._Tick_Slots_Coccion(mini._freidora, mini._slots_freidora_ui,
		mini._tiempo_coccion_b, "Lubina", mini._tiempo_coccion_b + 0.1)
	assert_eq(str(mini._freidora[0]["estado"]), "listo")

	# Llevar lubina frita al plato, sumar salsa y espárragos, servir con vino blanco
	mini._on_freidora_pulsada(0)
	assert_eq(str(mini._platos[0]["proteina"]), "lubina")
	assert_eq(str(mini._freidora[0]["estado"]), "vacio")
	assert_true(mini._Soltar_En_Plato({"tipo": "salsa"}, 0))
	assert_true(mini._Soltar_En_Plato({"tipo": "ingrediente", "id": "esparragos"}, 0))
	assert_eq(mini._Receta_De_Plato(mini._platos[0]), "lubina_blanca")
	assert_true(mini._Soltar_En_Cliente({"tipo": "plato", "indice": 0, "receta": "lubina_blanca"}, 0))
	assert_true(mini._Soltar_En_Cliente({"tipo": "bebida", "indice": 1, "item": "vino_blanco"}, 0))
	assert_false(bool(mini._clientes[0]["activo"]))

	# También si el pescado en sartén se quema por descuido se descarta penalizando
	var rec_antes_salmon: int = mini._recaudacion
	mini._Accion_Rapida_Alta("salmon")
	for _i in range(req + 1):
		mini._on_tabla_corte_pulsada(0)
	mini._Tick_Slots_Coccion(mini._freidora, mini._slots_freidora_ui,
		mini._tiempo_coccion_b, "Salmon", mini._tiempo_coccion_b + 0.1)
	mini._Tick_Slots_Coccion(mini._freidora, mini._slots_freidora_ui,
		mini._tiempo_coccion_b, "Salmon", mini._tiempo_quemado + 0.5)
	assert_eq(str(mini._freidora[0]["estado"]), "quemado")
	mini._on_freidora_pulsada(0)
	assert_eq(str(mini._freidora[0]["estado"]), "vacio")
	assert_gt(mini._penalizacion_quemados, 0)
	assert_eq(mini._recaudacion, maxi(0, rec_antes_salmon - 13),
		"Descartar salmón quemado debe restar 13 € (acotado a 0 €)")
	mini._Salir_Al_Sim()


func test_34_alta_cocina_recetas_y_bodega_sommelier() -> void:
	var mini = await _Crear_Minijuego("alta_cocina")
	mini._Iniciar_Nivel(8)
	mini._spawn_timer = 9999.0
	_Forzar_Cliente(mini, ["salmon_crujiente", "vino_blanco"])

	# Cortar salmón, freírlo, emplatado con salsa y espárragos completa Salmón crujiente
	mini._Accion_Rapida_Alta("salmon")
	for _i in range(int(mini._tabla_corte[0]["cortes_req"]) + 1):
		mini._on_tabla_corte_pulsada(0)
	mini._Tick_Slots_Coccion(mini._freidora, mini._slots_freidora_ui,
		mini._tiempo_coccion_b, "Salmon", mini._tiempo_coccion_b + 0.1)
	mini._on_freidora_pulsada(0)
	assert_true(mini._Soltar_En_Plato({"tipo": "salsa"}, 0))
	assert_true(mini._Soltar_En_Plato({"tipo": "ingrediente", "id": "esparragos"}, 0))
	assert_eq(mini._Receta_De_Plato(mini._platos[0]), "salmon_crujiente")

	# Magret con espárragos identifica sus 3 componentes y no existen soplete ni flor
	assert_eq(Sistema_Cocina.Identificar_Plato_Alta("pato", "reduccion", "esparragos"),
		"pato_esparragos")
	var d_sal: Dictionary = Sistema_Cocina.Describir_Elaboracion_Receta("alta_cocina", "salmon_crujiente")
	assert_has(d_sal.get("ingredientes", []), "salmon")
	assert_has(d_sal.get("ingredientes", []), "esparragos")
	assert_does_not_have(d_sal.get("ingredientes", []), "soplete")

	# Sommelier: al servir una copa pasa a llenando y tocarla acelera su decantado
	assert_true(mini._Soltar_En_Cliente({"tipo": "bebida", "indice": 1, "item": "vino_blanco"}, 0))
	assert_eq(str(mini._bebidas[1]["estado"]), "llenando")
	mini._on_bebida_pulsada(1)
	assert_gte(float(mini._bebidas[1]["progreso"]), 0.50)
	mini._on_bebida_pulsada(1)
	assert_eq(str(mini._bebidas[1]["estado"]), "listo")

	assert_true(mini._Soltar_En_Cliente({"tipo": "plato", "indice": 0, "receta": "salmon_crujiente"}, 0))
	mini._Salir_Al_Sim()


func test_35_alta_cocina_mejoras_nv3_estaciones_sin_solapes() -> void:
	# 1) Mejoras propias de Alta Cocina
	assert_true(Sistema_Cocina.MEJORAS_UI_POR_RESTAURANTE.has("alta_cocina"))
	var overrides: Dictionary = Sistema_Cocina.MEJORAS_UI_POR_RESTAURANTE["alta_cocina"]
	for mejora_id in Sistema_Cocina.ORDEN_MEJORAS:
		assert_true(overrides.has(mejora_id), "Alta Cocina debe definir %s" % mejora_id)
		for nivel in range(1, 4):
			assert_ne(
				Sistema_Cocina.Obtener_Beneficios_Nivel_Mejora(mejora_id, nivel, "alta_cocina"),
				Sistema_Cocina.Obtener_Beneficios_Nivel_Mejora(mejora_id, nivel, "burger_street"))
	assert_eq(Sistema_Cocina.Cortes_Necesarios_Pescado(1), 4)
	assert_eq(Sistema_Cocina.Cortes_Necesarios_Pescado(2), 3)
	assert_eq(Sistema_Cocina.Cortes_Necesarios_Pescado(3), 2)

	# 2) Estaciones, puestos de despensa, bodega, tablas y pases sin solapes ni salidas de 1280x720 en Nv.3
	Variables_Dinamicas.Cocina_Estado["mejoras"]["alta_cocina"] = {
		"plancha": 3, "emplatado": 3, "termostato": 3, "ingredientes": 3, "ambiente": 3
	}
	var mini = await _Crear_Minijuego("alta_cocina")
	assert_eq(mini._plancha.size(), 4)
	assert_eq(mini._tabla_corte.size(), 2)
	assert_eq(mini._freidora.size(), 2)
	assert_eq(mini._bebidas.size(), 3)
	assert_eq(mini._platos.size(), 4)
	assert_eq(mini._bandeja_items_ui.size(), 6)

	var pantalla := Rect2(0.0, 0.0, 1280.0, 720.0)
	var zonas_counter: Array[Rect2] = [
		mini.ZONA_ALTA_HORNO, mini.ZONA_ALTA_TABLA, mini.ZONA_ALTA_SARTEN,
		mini.ZONA_ALTA_SALSA, mini.ZONA_ALTA_BODEGA, mini.ZONA_PLATOS,
	]
	for i in range(zonas_counter.size()):
		assert_true(pantalla.encloses(zonas_counter[i]))
		for j in range(i + 1, zonas_counter.size()):
			assert_false(zonas_counter[i].intersects(zonas_counter[j]),
				"Las estaciones %d y %d no deben solaparse" % [i, j])
	for ui_c in mini._slots_corte_ui:
		assert_true(mini.ZONA_ALTA_TABLA.encloses(ui_c["rect"]))
	for ui_f in mini._slots_freidora_ui:
		assert_true(mini.ZONA_ALTA_SARTEN.encloses(ui_f["rect"]))
	for ui_b in mini._slots_bebidas_ui:
		assert_true(mini.ZONA_ALTA_BODEGA.encloses(ui_b["rect"]))
	for i in range(mini._bandeja_items_ui.size()):
		var r_i: Rect2 = mini._bandeja_items_ui[i]["rect"]
		assert_true(pantalla.encloses(r_i))
		for j in range(i + 1, mini._bandeja_items_ui.size()):
			assert_false(r_i.intersects(mini._bandeja_items_ui[j]["rect"]))
	mini._Salir_Al_Sim()


func test_36_alta_cocina_tutorial_y_guia_nivel_1() -> void:
	var mini = await _Crear_Minijuego("alta_cocina")
	_Forzar_Cliente(mini, ["lubina_blanca", "vino_blanco"])

	# Guía visual de Alta Cocina
	assert_true(mini._btn_cocina_guia.visible, "El botón ? GUÍA debe verse en Alta Cocina")
	mini._Abrir_Modal_Guia(true)
	assert_true(mini._modal_guia.visible)
	mini._Cerrar_Modal_Guia()
	assert_false(mini._modal_guia.visible)

	# Tutorial en vivo paso a paso para lubina entera -> cortar -> freír -> plato -> servir
	var p1: Dictionary = mini._Siguiente_Paso_Tutorial_Alta()
	assert_true(str(p1.get("texto", "")).contains("TABLA"))

	mini._Accion_Rapida_Alta("lubina")
	var p2: Dictionary = mini._Siguiente_Paso_Tutorial_Alta()
	assert_true(str(p2.get("texto", "")).contains("clicks"))
	for _c in range(int(mini._tabla_corte[0]["cortes_req"])):
		mini._on_tabla_corte_pulsada(0)
	var p3: Dictionary = mini._Siguiente_Paso_Tutorial_Alta()
	assert_true(str(p3.get("texto", "")).contains("SARTÉN"))

	mini._on_tabla_corte_pulsada(0)
	mini._Tick_Slots_Coccion(mini._freidora, mini._slots_freidora_ui,
		mini._tiempo_coccion_b, "Lubina", mini._tiempo_coccion_b + 0.1)
	var p4: Dictionary = mini._Siguiente_Paso_Tutorial_Alta()
	assert_true(str(p4.get("texto", "")).contains("crujiente"))

	mini._on_freidora_pulsada(0)
	var p5: Dictionary = mini._Siguiente_Paso_Tutorial_Alta()
	assert_true(str(p5.get("texto", "")).contains("SALSA"))
	mini._Soltar_En_Plato({"tipo": "salsa"}, 0)
	var p6: Dictionary = mini._Siguiente_Paso_Tutorial_Alta()
	assert_true(str(p6.get("texto", "")).contains("ESPÁRRAGOS"))
	mini._Soltar_En_Plato({"tipo": "ingrediente", "id": "esparragos"}, 0)
	var p7: Dictionary = mini._Siguiente_Paso_Tutorial_Alta()
	assert_true(str(p7.get("texto", "")).contains("cliente"))
	mini._Salir_Al_Sim()


func test_37_penalizacion_quemados_en_bistro_mercado_y_alta_cocina() -> void:
	# 1) Bistró: filete quemado (-7 €), patatas (-3 €) y tope 0 €
	var bistro = await _Crear_Minijuego("bistro_tradicional")
	bistro._recaudacion = 20
	bistro._Iniciar_Coccion_A(0, "carne")
	bistro._plancha[0]["progreso"] = 1.0
	bistro._plancha[0]["quemado"] = 0.9
	bistro._Tick_Slots_Coccion(bistro._plancha, bistro._slots_plancha_ui,
		bistro._tiempo_coccion_carne, "Filete", 0.02)
	var pay_filete: Dictionary = bistro._Obtener_Payload_Plancha({"indice": 0})
	assert_true(bistro._Soltar_En_Papelera(pay_filete["payload"]))
	assert_eq(bistro._recaudacion, 13, "Filete quemado en Bistró debe quitar 7 €")

	bistro._Accion_Rapida_Bistro("patatas")
	bistro._Tick_Slots_Coccion(bistro._freidora, bistro._slots_freidora_ui,
		bistro._tiempo_coccion_b, "Patatas", bistro._tiempo_coccion_b + 0.1)
	bistro._Tick_Slots_Coccion(bistro._freidora, bistro._slots_freidora_ui,
		bistro._tiempo_coccion_b, "Patatas", bistro._tiempo_quemado + 0.5)
	var pay_pat_b: Dictionary = bistro._Obtener_Payload_Freidora({"indice": 0})
	assert_true(bistro._Soltar_En_Papelera(pay_pat_b["payload"]))
	assert_eq(bistro._recaudacion, 10, "Patatas quemadas en Bistró deben quitar 3 €")
	bistro._Salir_Al_Sim()

	# 2) Mercado: huevo (-2 €), pisto (-7 €) y zarzuela (-11 €) con tope 0 €
	var mercado = await _Crear_Minijuego("cocina_mercado")
	mercado._Iniciar_Nivel(8)
	mercado._spawn_timer = 9999.0
	mercado._recaudacion = 15
	mercado._Accion_Rapida_Mercado("huevo")
	mercado._Tick_Slots_Coccion(mercado._freidora, mercado._slots_freidora_ui,
		mercado._tiempo_coccion_b, "Huevo", mercado._tiempo_coccion_b + 0.1)
	mercado._Tick_Slots_Coccion(mercado._freidora, mercado._slots_freidora_ui,
		mercado._tiempo_coccion_b, "Huevo", mercado._tiempo_quemado + 0.5)
	assert_true(mercado._Soltar_En_Papelera(mercado._Obtener_Payload_Freidora({"indice": 0})["payload"]))
	assert_eq(mercado._recaudacion, 13, "Huevo quemado debe quitar 2 €")

	assert_true(mercado._Soltar_En_Plancha({"tipo": "ingrediente", "id": "tomate"}, 0))
	assert_true(mercado._Soltar_En_Plancha({"tipo": "ingrediente", "id": "pimiento"}, 0))
	mercado._Tick_Slots_Coccion(mercado._plancha, mercado._slots_plancha_ui,
		mercado._tiempo_coccion_carne, "Cazuela", mercado._tiempo_coccion_carne + 0.1)
	mercado._Tick_Slots_Coccion(mercado._plancha, mercado._slots_plancha_ui,
		mercado._tiempo_coccion_carne, "Cazuela", mercado._tiempo_quemado + 0.5)
	assert_true(mercado._Soltar_En_Papelera(mercado._Obtener_Payload_Plancha({"indice": 0})["payload"]))
	assert_eq(mercado._recaudacion, 6, "Pisto quemado debe quitar 7 €")

	assert_true(mercado._Soltar_En_Plancha({"tipo": "ingrediente", "id": "tomate"}, 0))
	assert_true(mercado._Soltar_En_Plancha({"tipo": "ingrediente", "id": "marisco"}, 0))
	mercado._Tick_Slots_Coccion(mercado._plancha, mercado._slots_plancha_ui,
		mercado._tiempo_coccion_carne, "Cazuela", mercado._tiempo_coccion_carne + 0.1)
	mercado._Tick_Slots_Coccion(mercado._plancha, mercado._slots_plancha_ui,
		mercado._tiempo_coccion_carne, "Cazuela", mercado._tiempo_quemado + 0.5)
	mercado._on_plancha_pulsada(0)
	assert_eq(mercado._recaudacion, 0, "6 € - 11 € (zarzuela) debe bajar hasta 0 € sin quedar en negativo")
	mercado._Salir_Al_Sim()

	# 3) Alta Cocina: solomillo pasado (-11 €), pato pasado (-13 €), lubina (-12 €) y salsa (-5 €)
	var alta = await _Crear_Minijuego("alta_cocina")
	alta._recaudacion = 50
	alta._Accion_Rapida_Alta("solomillo")
	alta._Tick_Slots_Coccion(alta._plancha, alta._slots_plancha_ui,
		alta._tiempo_coccion_carne, "Horno", alta._tiempo_coccion_carne * 1.1)
	assert_eq(str(alta._plancha[0]["estado"]), "pasado")
	assert_true(alta._Soltar_En_Papelera(alta._Obtener_Payload_Plancha({"indice": 0})["payload"]))
	assert_eq(alta._recaudacion, 39, "Solomillo pasado debe quitar 11 €")

	alta._Accion_Rapida_Alta("pato")
	alta._Tick_Slots_Coccion(alta._plancha, alta._slots_plancha_ui,
		alta._tiempo_coccion_carne, "Horno", alta._tiempo_coccion_carne * 1.1)
	assert_eq(str(alta._plancha[0]["estado"]), "pasado")
	alta._on_plancha_pulsada(0)
	assert_eq(alta._recaudacion, 26, "Pato pasado debe quitar 13 €")

	alta._Accion_Rapida_Alta("lubina")
	for _c in range(int(alta._tabla_corte[0]["cortes_req"]) + 1):
		alta._on_tabla_corte_pulsada(0)
	alta._Tick_Slots_Coccion(alta._freidora, alta._slots_freidora_ui,
		alta._tiempo_coccion_b, "Lubina", alta._tiempo_coccion_b + 0.1)
	alta._Tick_Slots_Coccion(alta._freidora, alta._slots_freidora_ui,
		alta._tiempo_coccion_b, "Lubina", alta._tiempo_quemado + 0.5)
	assert_true(alta._Soltar_En_Papelera(alta._Obtener_Payload_Freidora({"indice": 0})["payload"]))
	assert_eq(alta._recaudacion, 14, "Lubina quemada debe quitar 12 €")

	alta._sarten["quemado"] = 0.999
	alta._sarten["estado"] = "lista"
	alta._process(0.2)
	assert_eq(str(alta._sarten["estado"]), "arruinada")
	var pay_salsa: Dictionary = alta._Obtener_Payload_Sarten({})
	assert_eq(str(pay_salsa.get("payload", {}).get("tipo", "")), "salsa_quemada")
	assert_true(alta._Soltar_En_Papelera(pay_salsa["payload"]))
	assert_eq(alta._recaudacion, 9, "Arrastrar salsa quemada a la basura debe quitar 5 €")

	alta._sarten["estado"] = "arruinada"
	alta._sarten["quemado"] = 1.0
	alta._Remover_Salsa()
	assert_eq(alta._recaudacion, 4, "Descartar salsa quemada al tocar también quita 5 €")
	alta._sarten["estado"] = "arruinada"
	alta._Remover_Salsa()
	assert_eq(alta._recaudacion, 0, "4 € - 5 € de salsa debe bajar hasta 0 €")
	alta._Salir_Al_Sim()
