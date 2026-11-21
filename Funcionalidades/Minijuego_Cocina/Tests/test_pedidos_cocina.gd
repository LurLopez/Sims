extends GutTest

# Comprueba que cada nivel genera la misma secuencia de pedidos en cada partida
# (diseño memorizable), usando el RNG sembrado por nivel.

const DIA_PRUEBA: int = 12
const RUTA_SAVE_DIN: String = "user://test_pedidos_cocina_din.dat"
const RUTA_SAVE_EST: String = "user://test_pedidos_cocina_est.dat"

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


func _Primeros_Pedidos(mini: Control, cuantos: int) -> Array:
	var pedidos: Array = []
	for _k in range(cuantos):
		mini._Intentar_Spawnear_Cliente()
		var activos: Array = []
		for cl in mini._clientes:
			if bool(cl["activo"]):
				activos.append((cl["items"] as Array).duplicate())
		pedidos.append(activos.duplicate(true))
	return pedidos


func test_01_misma_secuencia_de_pedidos_en_dos_partidas() -> void:
	var mini_a = await _Crear_Minijuego()
	var pedidos_a: Array = _Primeros_Pedidos(mini_a, 3)
	mini_a._Salir_Al_Sim()

	var mini_b = await _Crear_Minijuego()
	var pedidos_b: Array = _Primeros_Pedidos(mini_b, 3)
	mini_b._Salir_Al_Sim()

	assert_eq(pedidos_a, pedidos_b,
		"El mismo nivel debe repetir la misma secuencia de clientes y pedidos")
	assert_eq(pedidos_a.size(), 3)
	assert_false((pedidos_a[0] as Array).is_empty(), "Debe aparecer al menos un cliente")
