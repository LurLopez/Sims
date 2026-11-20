extends GutTest

# Tests de la mecánica de arrastrar y soltar del Minijuego de Cocina:
# bandeja -> plato, carne -> plancha -> plato, plato -> cliente,
# rechazos de destinos inválidos y papelera.

const DIA_PRUEBA: int = 12
const RUTA_SAVE_DIN: String = "user://test_arrastre_cocina_din.dat"
const RUTA_SAVE_EST: String = "user://test_arrastre_cocina_est.dat"

var _backup: Dictionary = {}


func before_all() -> void:
	_Inicializar_Matriz()


func before_each() -> void:
	_backup = _Backup_Globales()
	Variables_Estaticas.Modo_Rapido = false
	Variables_Estaticas.Habilidades = [50, 50, 50, 50, 50, 50, 50]
	Variables_Dinamicas.Progreso = [50, 50, 50]
	Variables_Dinamicas.Progreso_Cocina = 1
	Variables_Dinamicas.Necesidades_Basicas = [50, 50, 50, 50, 50]
	Variables_Dinamicas.Dinero = 1000.0
	Variables_Dinamicas.Minute_Day = DIA_PRUEBA
	Variables_Dinamicas.Minute_Minute = 600
	Variables_Dinamicas.Minute = DIA_PRUEBA * 1440 + 600
	Variables_Dinamicas.Estados_Temporales = {}
	Variables_Dinamicas.Mensajes = []
	Variables_Dinamicas.Cocina_Estado = Variables_Dinamicas.Cocina_Estado_Por_Defecto()
	Variables_Dinamicas.Cocina_Estado["restaurantes_desbloqueados"] = ["burger_street"]
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
	Guardar_Variables_Dinamicas.save_path = b["save_din"]
	Guardar_Variables_Estaticas.save_path = b["save_est"]
	Guardar_Variables_Dinamicas._rle_cache = {}


func _Crear_Minijuego() -> Control:
	var mini = load("res://Escenas/Minijuego_Cocina/Minijuego_Cocina.tscn").instantiate()
	add_child_autofree(mini)
	await get_tree().process_frame
	mini._Iniciar_Nivel(1)
	await get_tree().process_frame
	return mini


func _Cliente_Con_Pedido(mini: Control, indice: int, items: Array) -> void:
	mini._clientes[indice]["activo"] = true
	mini._clientes[indice]["items"] = items
	mini._clientes[indice]["entregados"] = []
	for _i in range(items.size()):
		mini._clientes[indice]["entregados"].append(false)
	mini._clientes[indice]["paciencia_max"] = 30.0
	mini._clientes[indice]["paciencia"] = 30.0
	mini._clientes[indice]["precio_total"] = 20
	mini._clientes[indice]["variante"] = indice
	mini._Actualizar_Cliente_UI(indice)


# ============================================================================
# 1. Gesto real de arrastre desde la bandeja hasta un plato
# ============================================================================

func test_01_gesto_arrastre_pan_de_bandeja_a_plato() -> void:
	var mini = await _Crear_Minijuego()
	var item_pan: Dictionary = mini._bandeja_items_ui[0]
	assert_eq(str(item_pan["ingrediente"]), "pan")
	var destino: Vector2 = mini._slots_platos_ui[0]["rect"].get_center()

	mini._arrastre._Iniciar_Pulsacion(item_pan["rect"].get_center())
	mini._arrastre._Mover(destino)
	assert_true(mini._arrastre.esta_arrastrando(), "El gesto debe activar el arrastre")
	mini._arrastre._Soltar(destino)

	assert_true(bool(mini._platos[0]["pan"]), "Al soltar el pan en el plato debe colocarse")
	mini._Salir_Al_Sim()


# ============================================================================
# 2. Carne cruda -> plancha -> plato -> cliente (flujo completo)
# ============================================================================

func test_02_carne_a_plancha_plato_y_servicio_al_cliente() -> void:
	var mini = await _Crear_Minijuego()
	_Cliente_Con_Pedido(mini, 0, ["burger_sola"])

	var plato: Vector2 = mini._slots_platos_ui[0]["rect"].get_center()
	var plancha: Vector2 = mini._slots_plancha_ui[0]["rect"].get_center()
	var cliente: Vector2 = Vector2(CENTROS_PRUEBA[0], 300.0)

	assert_true(mini._Depositar_Payload({"tipo": "ingrediente", "id": "pan"}, plato))
	assert_true(bool(mini._platos[0]["pan"]))

	assert_true(mini._Depositar_Payload({"tipo": "ingrediente", "id": "carne"}, plancha))
	assert_eq(str(mini._plancha[0]["estado"]), "cocinando")

	mini._Tick_Slots_Coccion(mini._plancha, mini._slots_plancha_ui,
		mini._tiempo_coccion_carne, "Carne", mini._tiempo_coccion_carne + 0.1)
	assert_eq(str(mini._plancha[0]["estado"]), "listo")

	assert_true(mini._Depositar_Payload({"tipo": "carne_lista", "indice": 0}, plato))
	assert_eq(int(mini._platos[0]["carnes"]), 1)
	assert_eq(str(mini._plancha[0]["estado"]), "vacio")
	assert_eq(mini._Receta_De_Plato(mini._platos[0]), "burger_sola")

	var receta: String = mini._Receta_De_Plato(mini._platos[0])
	assert_true(mini._Depositar_Payload(
		{"tipo": "plato", "indice": 0, "receta": receta}, cliente))
	assert_true(bool(mini._clientes[0]["entregados"][0]), "El cliente debe recibir la hamburguesa")
	assert_false(bool(mini._platos[0]["pan"]), "El plato debe quedar limpio tras servir")
	assert_false(bool(mini._clientes[0]["activo"]), "El pedido completo libera al cliente")
	assert_gt(mini._recaudacion, 0)
	mini._Salir_Al_Sim()


# ============================================================================
# 3. Rechazos: queso sin pan, cliente equivocado y destino sin sentido
# ============================================================================

func test_03_rechazos_de_destinos_invalidos() -> void:
	var mini = await _Crear_Minijuego()
	var plato: Vector2 = mini._slots_platos_ui[0]["rect"].get_center()

	assert_false(mini._Depositar_Payload({"tipo": "ingrediente", "id": "queso"}, plato),
		"No se puede poner queso sin pan")
	assert_false(bool(mini._platos[0]["queso"]))

	_Cliente_Con_Pedido(mini, 0, ["burger_sola"])
	_Cliente_Con_Pedido(mini, 1, ["refresco"])
	var cliente_1: Vector2 = Vector2(CENTROS_PRUEBA[1], 300.0)
	var plato_lleno: Dictionary = {"tipo": "plato", "indice": 0, "receta": "burger_sola"}
	var destino_erroneo: Dictionary = mini._arrastre.resolver_destino(cliente_1, plato_lleno)
	assert_false(bool(destino_erroneo.get("aceptado", false)),
		"El cliente que pidió refresco no acepta una hamburguesa")
	mini._Salir_Al_Sim()


# ============================================================================
# 4. Papelera: arrastrar un plato montado lo vacía
# ============================================================================

func test_04_papelera_vacia_plato() -> void:
	var mini = await _Crear_Minijuego()
	var plato: Vector2 = mini._slots_platos_ui[0]["rect"].get_center()
	mini._Depositar_Payload({"tipo": "ingrediente", "id": "pan"}, plato)
	mini._on_ingrediente_queso()
	assert_true(bool(mini._platos[0]["pan"]))
	assert_true(bool(mini._platos[0]["queso"]))

	var papelera: Vector2 = mini._papelera_rect.get_center()
	assert_true(mini._Depositar_Payload(
		{"tipo": "plato", "indice": 0, "receta": ""}, papelera))
	assert_false(bool(mini._platos[0]["pan"]), "La papelera debe vaciar el plato")
	mini._Salir_Al_Sim()


# ============================================================================
# 5. Bebida: llenado, arrastre al cliente y recarga automática
# ============================================================================

func test_05_bebida_se_sirve_arrastrando_y_se_recarga() -> void:
	var mini = await _Crear_Minijuego()
	_Cliente_Con_Pedido(mini, 0, ["refresco"])
	assert_eq(str(mini._bebidas[0]["estado"]), "listo")

	var cliente: Vector2 = Vector2(CENTROS_PRUEBA[0], 300.0)
	assert_true(mini._Depositar_Payload({"tipo": "bebida", "indice": 0}, cliente))
	assert_false(bool(mini._clientes[0]["activo"]))
	assert_eq(str(mini._bebidas[0]["estado"]), "llenando")
	mini._Salir_Al_Sim()


# ============================================================================
# Utilidad: centros reales de los clientes del layout
# ============================================================================

const CENTROS_PRUEBA: Array[float] = [402.0, 636.0, 870.0, 1104.0]
