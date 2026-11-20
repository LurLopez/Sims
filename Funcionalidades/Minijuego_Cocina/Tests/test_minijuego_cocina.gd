extends GutTest

# Tests GUT completos del Minijuego de Cocina (estilo Cooking Fever),
# Apartado Minijuegos, Progresión Hostelería y Ropa Equipable.

const DIA_PRUEBA: int = 12
const RUTA_SAVE_DIN: String = "user://test_minijuego_cocina_din.dat"
const RUTA_SAVE_EST: String = "user://test_minijuego_cocina_est.dat"

var _backup: Dictionary = {}
var _senales_desbloqueo: Array = []


func before_all() -> void:
	_Inicializar_Matriz()


func before_each() -> void:
	_backup = _Backup_Globales()
	_senales_desbloqueo.clear()
	Variables_Estaticas.Modo_Rapido = false
	Variables_Estaticas.Habilidades = [50, 50, 50, 50, 50, 50, 50]
	Variables_Estaticas.Personalidad = ""
	Variables_Estaticas.Record_Max_Niveles_Cocina = 0
	Variables_Dinamicas.Progreso = [50, 50, 50]
	Variables_Dinamicas.Progreso_Cocina = 1
	Variables_Dinamicas.Necesidades_Basicas = [50, 50, 50, 50, 50]
	Variables_Dinamicas.Habilidades_Mostradas = [0, 0, 0, 0, 0, 0, 0]
	Variables_Dinamicas.Habilidades_Cap_Notificado = [false, false, false, false, false, false, false]
	Variables_Dinamicas.Tuppers = []
	Variables_Dinamicas.Tupper_Seleccionado_Idx = -1
	Variables_Dinamicas.Minutos_Cocinando_Actuales = 0
	Variables_Dinamicas.Dinero = 1000.0
	Variables_Dinamicas.En_La_Calle = false
	Variables_Dinamicas.Minute_Day = DIA_PRUEBA
	Variables_Dinamicas.Minute_Minute = 600 # 10:00
	Variables_Dinamicas.Minute = DIA_PRUEBA * 1440 + 600
	Variables_Dinamicas.Estados_Temporales = {}
	Variables_Dinamicas.Mensajes = []
	Variables_Dinamicas.Muerto = false
	Variables_Dinamicas.Carrera_Actual = null
	Variables_Dinamicas.Trabajo_Actual = null
	Variables_Dinamicas.Cooldown_Trabajos = {}
	Variables_Dinamicas.Objetos_Poseidos = {
		"Cama_Basica": true,
		"Mesa_Basica": true,
		"Ducha_Basica": true,
		"Ropa_Calle": true
	}
	Variables_Dinamicas.Objeto_Seleccionado = {
		"Dormir": "Cama_Basica",
		"Comer": "Mesa_Basica",
		"Duchar": "Ducha_Basica",
		"Ropa": "Ropa_Calle"
	}
	Variables_Dinamicas.Cocina_Estado = Variables_Dinamicas.Cocina_Estado_Por_Defecto()
	Guardar_Variables_Dinamicas.save_path = RUTA_SAVE_DIN
	Guardar_Variables_Estaticas.save_path = RUTA_SAVE_EST
	_Limpiar_Celdas()


func after_each() -> void:
	if Sistema_Cocina.restaurante_desbloqueado.is_connected(_on_senal_desbloqueo):
		Sistema_Cocina.restaurante_desbloqueado.disconnect(_on_senal_desbloqueo)
	_Restaurar_Globales(_backup)
	for ruta in [RUTA_SAVE_DIN, RUTA_SAVE_EST]:
		var abs_ruta: String = ProjectSettings.globalize_path(ruta)
		if FileAccess.file_exists(abs_ruta):
			DirAccess.remove_absolute(abs_ruta)


func _on_senal_desbloqueo(rest_id: String, nombre_rest: String) -> void:
	_senales_desbloqueo.append({"id": rest_id, "nombre": nombre_rest})


func _Inicializar_Matriz() -> void:
	if Variables_Dinamicas.Matriz_Jugador.size() == 1440:
		return
	Variables_Dinamicas.Matriz_Jugador = []
	for i in range(1440):
		var fila: Array = []
		fila.resize(574)
		fila.fill("")
		Variables_Dinamicas.Matriz_Jugador.append(fila)


func _Limpiar_Celdas() -> void:
	for fila in range(1440):
		for col in range(0, 21):
			Variables_Dinamicas.Matriz_Jugador[fila][col] = ""


func _Backup_Globales() -> Dictionary:
	return {
		"modo_rapido": Variables_Estaticas.Modo_Rapido,
		"habilidades": Variables_Estaticas.Habilidades.duplicate(),
		"record_cocina": Variables_Estaticas.Record_Max_Niveles_Cocina,
		"progreso": Variables_Dinamicas.Progreso.duplicate(),
		"progreso_cocina": Variables_Dinamicas.Progreso_Cocina,
		"necesidades": Variables_Dinamicas.Necesidades_Basicas.duplicate(),
		"dinero": Variables_Dinamicas.Dinero,
		"en_la_calle": Variables_Dinamicas.En_La_Calle,
		"minute_day": Variables_Dinamicas.Minute_Day,
		"minute_minute": Variables_Dinamicas.Minute_Minute,
		"minute": Variables_Dinamicas.Minute,
		"estados": Variables_Dinamicas.Estados_Temporales.duplicate(true),
		"mensajes": Variables_Dinamicas.Mensajes.duplicate(),
		"carrera_actual": Variables_Dinamicas.Carrera_Actual,
		"trabajo_actual": Variables_Dinamicas.Trabajo_Actual,
		"objetos_poseidos": Variables_Dinamicas.Objetos_Poseidos.duplicate(true),
		"objeto_seleccionado": Variables_Dinamicas.Objeto_Seleccionado.duplicate(true),
		"cocina_estado": Variables_Dinamicas.Cocina_Estado.duplicate(true),
		"save_din": Guardar_Variables_Dinamicas.save_path,
		"save_est": Guardar_Variables_Estaticas.save_path
	}


func _Restaurar_Globales(b: Dictionary) -> void:
	Variables_Estaticas.Modo_Rapido = b["modo_rapido"]
	Variables_Estaticas.Habilidades = b["habilidades"]
	Variables_Estaticas.Record_Max_Niveles_Cocina = b["record_cocina"]
	Variables_Dinamicas.Progreso = b["progreso"]
	Variables_Dinamicas.Progreso_Cocina = b["progreso_cocina"]
	Variables_Dinamicas.Necesidades_Basicas = b["necesidades"]
	Variables_Dinamicas.Dinero = b["dinero"]
	Variables_Dinamicas.En_La_Calle = b["en_la_calle"]
	Variables_Dinamicas.Minute_Day = b["minute_day"]
	Variables_Dinamicas.Minute_Minute = b["minute_minute"]
	Variables_Dinamicas.Minute = b["minute"]
	Variables_Dinamicas.Estados_Temporales = b["estados"]
	Variables_Dinamicas.Mensajes = b["mensajes"]
	Variables_Dinamicas.Carrera_Actual = b["carrera_actual"]
	Variables_Dinamicas.Trabajo_Actual = b["trabajo_actual"]
	Variables_Dinamicas.Objetos_Poseidos = b["objetos_poseidos"]
	Variables_Dinamicas.Objeto_Seleccionado = b["objeto_seleccionado"]
	Variables_Dinamicas.Cocina_Estado = b["cocina_estado"]
	Guardar_Variables_Dinamicas.save_path = b["save_din"]
	Guardar_Variables_Estaticas.save_path = b["save_est"]
	Guardar_Variables_Dinamicas._rle_cache = {}


# ============================================================================
# 1. Estado por defecto, retrocompatibilidad de saves y categoría "Ropa"
# ============================================================================

func test_01_estado_por_defecto_y_catalogo_ropa() -> void:
	var est: Dictionary = Variables_Dinamicas.Cocina_Estado_Por_Defecto()
	assert_eq(est["restaurantes_desbloqueados"], [])
	assert_eq(int(est["fondos_cocina"]), 0)
	assert_eq(int(est["rango_logro"]), 0)
	assert_false(bool(est["plus_nomina_turno_hoy"]))
	for rest_id in ["burger_street", "bistro_tradicional", "alta_cocina"]:
		assert_true((est["mejoras"] as Dictionary).has(rest_id))
		for m_id in ["plancha", "emplatado", "termostato", "ingredientes", "ambiente"]:
			assert_eq(int(est["mejoras"][rest_id][m_id]), 1)

	for prenda in ["Ropa_Calle", "Delantal_Aprendiz", "Chaqueta_Chef", "Atuendo_Chef_Gala", "Traje_Estrella_Michelin"]:
		assert_true(Variables_Estaticas.Catalogo_Objetos.has(prenda), "Debe existir %s" % prenda)
		var obj = Variables_Estaticas.Catalogo_Objetos[prenda]
		assert_true(obj is Objeto_Ropa)
		assert_eq(obj.afecta_a, "Ropa")
		assert_almost_eq(obj.precio, 0.0, 0.001)
		assert_true(obj.es_basico)


func test_01_retrocompatibilidad_save_antiguo_y_merge_recursivo() -> void:
	var save_antiguo: Dictionary = {
		"Matriz_Jugador": Guardar_Variables_Dinamicas._Matriz_A_RLE(),
		"Progreso": [10, 20, 30],
		"Necesidades_Basicas": [50, 50, 50, 50, 50],
		"Dinero": 250.0,
		"Minute": 100,
		"Minute_Day": 0,
		"Minute_Minute": 100,
		"Objetos_Poseidos": {"Cama_Basica": true, "Mesa_Basica": true, "Ducha_Basica": true},
		"Objeto_Seleccionado": {"Dormir": "Cama_Basica", "Comer": "Mesa_Basica", "Duchar": "Ducha_Basica"},
		"Cocina_Estado": {
			"restaurantes_desbloqueados": ["burger_street"],
			"fondos_cocina": 150,
			"mejoras": {"burger_street": {"plancha": 2}}
		}
	}
	var f := FileAccess.open(RUTA_SAVE_DIN, FileAccess.WRITE)
	f.store_var(save_antiguo)
	f = null

	Guardar_Variables_Dinamicas.load_game()
	assert_true(bool(Variables_Dinamicas.Objetos_Poseidos.get("Ropa_Calle", false)),
		"Un save antiguo debe recibir Ropa_Calle automáticamente")
	assert_eq(str(Variables_Dinamicas.Objeto_Seleccionado.get("Ropa", "")), "Ropa_Calle",
		"Objeto_Seleccionado['Ropa'] debe hacer fallback a Ropa_Calle")
	assert_eq(Variables_Dinamicas.Cocina_Estado["restaurantes_desbloqueados"], ["burger_street"])
	assert_eq(int(Variables_Dinamicas.Cocina_Estado["fondos_cocina"]), 150)
	assert_eq(int(Variables_Dinamicas.Cocina_Estado["mejoras"]["burger_street"]["plancha"]), 2)
	assert_eq(int(Variables_Dinamicas.Cocina_Estado["mejoras"]["burger_street"]["termostato"]), 1,
		"Las mejoras faltantes deben rellenarse con 1")
	assert_eq(int(Variables_Dinamicas.Cocina_Estado["mejoras"]["alta_cocina"]["ambiente"]), 1)

	# Save estático antiguo sin Record_Max_Niveles_Cocina
	var est_antiguo: Dictionary = {
		"First_Time": false,
		"First_Time_Minute": 0,
		"Habilidades": [50, 50, 50, 50, 50, 50, 50],
		"Personalidad": "Deportista",
		"First_Time_Minute_Day": 0,
		"First_Time_Minute_Minute": 0
	}
	var fe := FileAccess.open(RUTA_SAVE_EST, FileAccess.WRITE)
	fe.store_var(est_antiguo)
	fe = null
	Variables_Estaticas.Record_Max_Niveles_Cocina = 99
	Guardar_Variables_Estaticas.load_game()
	assert_eq(Variables_Estaticas.Record_Max_Niveles_Cocina, 0,
		"Save estático antiguo debe hacer fallback a 0")


# ============================================================================
# 2. Desbloqueo solo tras primer minuto trabajado (nunca al programar bloque)
# ============================================================================

func test_02_programar_trabajo_no_desbloquea_pero_primer_minuto_si() -> void:
	Sistema_Cocina.restaurante_desbloqueado.connect(_on_senal_desbloqueo)
	var act_cr: Actividad_Fija_Trabajo = Variables_Estaticas.Catalogo_Actividades["Trabajar_En_Comida_Rapida"]

	# Programar el empleo en el calendario NO debe desbloquear nada
	Trabajo.Trabajar(act_cr)
	assert_false(Sistema_Cocina.Esta_Desbloqueado_Minijuego(),
		"Programar el bloque de trabajo NO debe desbloquear el minijuego")
	assert_eq(_senales_desbloqueo.size(), 0)
	assert_eq(Variables_Dinamicas.Mensajes.size(), 0)

	# Al ejecutar un minuto real de ese trabajo sí debe desbloquear
	Actividades.Ejecutar_Actividad(act_cr, false)
	assert_true(Sistema_Cocina.Esta_Desbloqueado_Restaurante("burger_street"),
		"El primer minuto trabajado debe desbloquear burger_street")
	assert_eq(_senales_desbloqueo.size(), 1, "Debe emitir restaurante_desbloqueado exactamente una vez")
	assert_eq(str(_senales_desbloqueo[0]["id"]), "burger_street")
	assert_eq(Variables_Dinamicas.Mensajes.size(), 1, "Debe añadir un mensaje al buzón")
	assert_true(str(Variables_Dinamicas.Mensajes[0].descripcion).contains("Minijuegos"))

	# Un segundo minuto NO vuelve a emitir ni duplicar mensaje
	Actividades.Ejecutar_Actividad(act_cr, false)
	assert_eq(_senales_desbloqueo.size(), 1)
	assert_eq(Variables_Dinamicas.Mensajes.size(), 1)

	# Verificar los otros dos restaurantes con sus trabajos correspondientes
	assert_true(Sistema_Cocina.Registrar_Minuto_Trabajo_Hosteleria("Trabajar_De_Ayudante_Cocina"))
	assert_true(Sistema_Cocina.Esta_Desbloqueado_Restaurante("bistro_tradicional"))
	assert_false(Sistema_Cocina.Registrar_Minuto_Trabajo_Hosteleria("Trabajar_De_Cocinero_Partida"),
		"bistro_tradicional ya estaba desbloqueado")
	assert_true(Sistema_Cocina.Registrar_Minuto_Trabajo_Hosteleria("Trabajar_De_Chef_Ejecutivo"))
	assert_true(Sistema_Cocina.Esta_Desbloqueado_Restaurante("alta_cocina"))


# ============================================================================
# 3. Doble moneda, mejoras, tope 2 servicios/día, micro-propinas y Modo Rápido
# ============================================================================

func test_03_economia_doble_moneda_mejoras_y_limite_diario() -> void:
	Sistema_Cocina.Registrar_Minuto_Trabajo_Hosteleria("Trabajar_En_Comida_Rapida")
	Variables_Dinamicas.Dinero = 100.0

	# Servicio 1 (Nivel 1, 3 estrellas: 115 monedas, 20 propinas)
	var r1: Dictionary = Sistema_Cocina.Procesar_Fin_Nivel("burger_street", 1, 115, 20, false)
	assert_eq(int(r1["estrellas"]), 3)
	assert_eq(int(r1["fondos_ganados"]), 115)
	assert_eq(Sistema_Cocina.Obtener_Fondos_Cocina(), 115)
	# Bono 1ª vez 3★ = 15 + 15 + 20 = 50 €; propinas = 20 * 0.5 = 10 €
	assert_almost_eq(float(r1["bono_estrellas_eur"]), 50.0, 0.01)
	assert_almost_eq(float(r1["propinas_eur"]), 10.0, 0.01)
	assert_almost_eq(Variables_Dinamicas.Dinero, 160.0, 0.01)

	# Comprar mejora termostato (cuesta 90 Fondos_Cocina, no toca Dinero)
	var compra: Dictionary = Sistema_Cocina.Comprar_Mejora("burger_street", "termostato")
	assert_true(bool(compra["exito"]))
	assert_eq(Sistema_Cocina.Obtener_Nivel_Mejora("burger_street", "termostato"), 2)
	assert_eq(Sistema_Cocina.Obtener_Fondos_Cocina(), 25)
	assert_almost_eq(Variables_Dinamicas.Dinero, 160.0, 0.01, "Comprar mejora NO debe tocar Dinero del Sim")

	# Servicio 2 del mismo día (repetir Nivel 1: 0 bono 1ª vez, sí paga propinas)
	var r2: Dictionary = Sistema_Cocina.Procesar_Fin_Nivel("burger_street", 1, 115, 20, false)
	assert_almost_eq(float(r2["bono_estrellas_eur"]), 0.0, 0.01)
	assert_almost_eq(float(r2["propinas_eur"]), 10.0, 0.01)
	assert_false(bool(r2["limite_diario_alcanzado"]))

	# Servicio 3 del mismo día en modo libre: tope diario de 2 alcanzado -> 0 € propinas
	var r3: Dictionary = Sistema_Cocina.Procesar_Fin_Nivel("burger_street", 1, 115, 20, false)
	assert_almost_eq(float(r3["propinas_eur"]), 0.0, 0.01)
	assert_true(bool(r3["limite_diario_alcanzado"]))


func test_03_tope_micro_propinas_y_modo_rapido_precios() -> void:
	# Normal: tope 15 €
	var acum: float = 0.0
	for _i in range(10):
		var m: Dictionary = Sistema_Cocina.Procesar_Micro_Recompensa_Cliente(
			false, acum, {"cocina": 0.99, "manualidades": 0.99, "necesidad": 0.99, "propina": 0.01, "propina_base": 5.0})
		acum += float(m["micro_propina_eur"])
	assert_almost_eq(acum, 15.0, 0.01, "Las micro-propinas deben respetar el tope de 15 €")

	# Modo Rápido (Multiplicador_Precios = 0.1): tope 1.50 € y bono 1ª vez x0.1
	Variables_Estaticas.Modo_Rapido = true
	var acum_r: float = 0.0
	for _i in range(10):
		var mr: Dictionary = Sistema_Cocina.Procesar_Micro_Recompensa_Cliente(
			false, acum_r, {"cocina": 0.99, "manualidades": 0.99, "necesidad": 0.99, "propina": 0.01, "propina_base": 5.0})
		acum_r += float(mr["micro_propina_eur"])
	assert_almost_eq(acum_r, 1.50, 0.01, "En Modo Rápido el tope de micro-propinas debe ser 1.50 €")

	var res_r: Dictionary = Sistema_Cocina.Procesar_Fin_Nivel("burger_street", 2, 140, 20, false)
	assert_almost_eq(float(res_r["bono_estrellas_eur"]), 5.0, 0.01, "50 € * 0.1 = 5.0 €")
	assert_almost_eq(float(res_r["propinas_eur"]), 1.0, 0.01, "10 € * 0.1 = 1.0 €")


# ============================================================================
# 4. Bonus Esta_En_Turno_Activo (x1.5 dinero/fondos, x2.0 progreso, +10% nómina)
# ============================================================================

func test_04_bonus_en_turno_activo_y_plus_nomina() -> void:
	var act_cr: Actividad_Fija_Trabajo = Variables_Estaticas.Catalogo_Actividades["Trabajar_En_Comida_Rapida"]
	Variables_Dinamicas.Matriz_Jugador[600][DIA_PRUEBA] = act_cr
	assert_true(Sistema_Cocina.Esta_En_Turno_Activo("burger_street"))
	assert_false(Sistema_Cocina.Esta_En_Turno_Activo("alta_cocina"))

	# Agotar primero los 2 servicios libres del día; en turno sigue siendo ilimitado
	Variables_Dinamicas.Cocina_Estado["servicios_remunerados_hoy"] = 2
	Variables_Dinamicas.Cocina_Estado["ultimo_dia_remunerado"] = DIA_PRUEBA

	var res: Dictionary = Sistema_Cocina.Procesar_Fin_Nivel("burger_street", 1, 100, 20, true)
	assert_eq(int(res["fondos_ganados"]), 150, "En turno Fondos_Cocina x1.5")
	assert_almost_eq(float(res["propinas_eur"]), 15.0, 0.01, "En turno propinas ilimitadas y x1.5 (20*0.5*1.5)")
	assert_true(bool(res["plus_nomina_activado"]))
	assert_true(bool(Variables_Dinamicas.Cocina_Estado["plus_nomina_turno_hoy"]))

	# Drop de progreso cocina x2.0 en turno
	assert_almost_eq(Sistema_Cocina.Calcular_Tasa_Drop_Cocina(false, false), 0.15, 0.0001)
	assert_almost_eq(Sistema_Cocina.Calcular_Tasa_Drop_Cocina(true, false), 0.30, 0.0001)

	# Al llegar al último minuto del turno, cobra +10% nómina y resetea el flag
	Variables_Dinamicas.Dinero = 0.0
	Variables_Dinamicas.Minute_Minute = act_cr.hora_final - 1
	Actividades.Ejecutar_Actividad(act_cr, false)
	# 8 horas * 10 €/h * 1.10 = 88.0 €
	assert_almost_eq(Variables_Dinamicas.Dinero, 88.0, 0.01, "Debe cobrar 80 € + 10% = 88 €")
	assert_false(bool(Variables_Dinamicas.Cocina_Estado["plus_nomina_turno_hoy"]),
		"plus_nomina_turno_hoy debe resetearse tras cobrar la nómina")


# ============================================================================
# 5. Modo_Rapido: drops de Progreso_Cocina y Manualidades x7.0
# ============================================================================

func test_05_modo_rapido_multiplica_drops_por_siete() -> void:
	assert_almost_eq(Sistema_Cocina.Calcular_Tasa_Drop_Cocina(false, true), 0.15 * 7.0, 0.0001)
	assert_almost_eq(Sistema_Cocina.Calcular_Tasa_Drop_Cocina(true, true), 0.15 * 2.0 * 7.0, 0.0001)
	assert_almost_eq(Sistema_Cocina.Calcular_Tasa_Drop_Manualidades(false), 0.05, 0.0001)
	assert_almost_eq(Sistema_Cocina.Calcular_Tasa_Drop_Manualidades(true), 0.05 * 7.0, 0.0001)

	Variables_Estaticas.Modo_Rapido = true
	Variables_Dinamicas.Progreso_Cocina = 10
	Variables_Dinamicas.Progreso[2] = 10
	# Tasa cocina = 1.05 (garantiza +1 incluso con roll alto 0.99); tasa manualidades = 0.35 (sube con roll 0.30)
	var m: Dictionary = Sistema_Cocina.Procesar_Micro_Recompensa_Cliente(
		false, 0.0, {"cocina": 0.99, "manualidades": 0.30, "necesidad": 0.99, "propina": 0.99})
	assert_eq(int(m["cocina_ganada"]), 1)
	assert_eq(Variables_Dinamicas.Progreso_Cocina, 11)
	assert_eq(int(m["manualidades_ganadas"]), 1)
	assert_eq(int(Variables_Dinamicas.Progreso[2]), 11)


# ============================================================================
# 6. Fórmulas puras de habilidades, necesidades, resacón y bloqueos de entrada
# ============================================================================

func test_06_formulas_puras_y_bloqueos_de_entrada() -> void:
	# Destreza reduce hasta -15% tiempo de cocción
	var t_d0: float = Sistema_Cocina.Calcular_Tiempo_Coccion(4.0, 1, 0.0)
	var t_d100: float = Sistema_Cocina.Calcular_Tiempo_Coccion(4.0, 1, 100.0)
	assert_almost_eq(t_d0, 4.0, 0.001)
	assert_almost_eq(t_d100, 3.4, 0.001, "Destreza 100 debe reducir -15% (4.0 -> 3.4)")
	assert_almost_eq(Sistema_Cocina.Calcular_Tiempo_Coccion(4.0, 3, 0.0), 2.6, 0.001, "Plancha Nv3 x0.65")

	# Termostato + Paciencia (+15%) + Resacón (x0.85)
	var q_base: float = Sistema_Cocina.Calcular_Tiempo_Quemado(1, 0.0, false)
	var q_pac: float = Sistema_Cocina.Calcular_Tiempo_Quemado(1, 100.0, false)
	var q_res: float = Sistema_Cocina.Calcular_Tiempo_Quemado(1, 0.0, true)
	assert_almost_eq(q_base, 6.0, 0.001)
	assert_almost_eq(q_pac, 6.9, 0.001, "Paciencia 100 suma +15% (6.0 -> 6.9)")
	assert_almost_eq(q_res, 5.1, 0.001, "Resacón aplica x0.85 (6.0 -> 5.1)")
	assert_almost_eq(Sistema_Cocina.Calcular_Tiempo_Quemado(3, 0.0, false), 10.5, 0.001)
	assert_true(Sistema_Cocina.Tiene_Aviso_Temprano_Termostato(3))

	# Velocidad de paciencia: Ambiente, Paciencia, Sangre Fría, Descanso < 25, Salud Mental < 25
	var v_norm: float = Sistema_Cocina.Calcular_Velocidad_Paciencia(1, 0.0, 0.0, 60.0, 60.0)
	var v_hab: float = Sistema_Cocina.Calcular_Velocidad_Paciencia(1, 100.0, 100.0, 60.0, 60.0)
	var v_cansado: float = Sistema_Cocina.Calcular_Velocidad_Paciencia(1, 0.0, 0.0, 20.0, 60.0)
	var v_estres: float = Sistema_Cocina.Calcular_Velocidad_Paciencia(1, 0.0, 0.0, 60.0, 20.0)
	var v_amb3: float = Sistema_Cocina.Calcular_Velocidad_Paciencia(3, 0.0, 0.0, 60.0, 60.0)
	assert_almost_eq(v_norm, 1.0, 0.001)
	assert_lt(v_hab, v_norm, "Paciencia y Sangre Fría reducen el desgaste de paciencia")
	assert_almost_eq(v_cansado, 1.20, 0.001, "Descanso < 25 aplica x1.20")
	assert_almost_eq(v_estres, 1.20, 0.001, "Salud Mental < 25 aplica x1.20")
	assert_lt(v_amb3, v_norm, "Ambiente Nv3 reduce desgaste de paciencia")

	# Bloqueos de entrada: vacío -> Descanso <= 5 -> Examen en <= 5 min
	var c_bloq: Dictionary = Sistema_Cocina.Puede_Entrar_Minijuego()
	assert_false(bool(c_bloq["permitido"]))
	assert_eq(str(c_bloq["motivo"]), "bloqueado")

	Sistema_Cocina.Registrar_Minuto_Trabajo_Hosteleria("Trabajar_En_Comida_Rapida")
	Variables_Dinamicas.Necesidades_Basicas[3] = 5
	var c_desc: Dictionary = Sistema_Cocina.Puede_Entrar_Minijuego()
	assert_false(bool(c_desc["permitido"]))
	assert_eq(str(c_desc["motivo"]), "descanso_bajo")

	Variables_Dinamicas.Necesidades_Basicas[3] = 50
	Variables_Dinamicas.Matriz_Jugador[604][DIA_PRUEBA] = Variables_Estaticas.Catalogo_Actividades["Examen_Carrera"]
	var c_ex: Dictionary = Sistema_Cocina.Puede_Entrar_Minijuego()
	assert_false(bool(c_ex["permitido"]))
	assert_eq(str(c_ex["motivo"]), "examen_inminente")

	# Identificador de recetas de hamburguesa
	assert_eq(Sistema_Cocina.Identificar_Hamburguesa(true, 1, false, false, false), "burger_sola")
	assert_eq(Sistema_Cocina.Identificar_Hamburguesa(true, 1, true, false, false), "burger_queso")
	assert_eq(Sistema_Cocina.Identificar_Hamburguesa(true, 1, true, true, true), "burger_completa")
	assert_eq(Sistema_Cocina.Identificar_Hamburguesa(true, 2, true, false, false), "burger_doble")


# ============================================================================
# 7. Logros cada 5 niveles (Rangos 1-9), prendas, Alimentacion e Inmunidad
# ============================================================================

func test_07_logros_prendas_efectos_alimentacion_e_inmunidad() -> void:
	Sistema_Cocina.Registrar_Minuto_Trabajo_Hosteleria("Trabajar_En_Comida_Rapida")

	# Superar 5 niveles -> Rango 1 y Delantal_Aprendiz
	for n in range(1, 6):
		Sistema_Cocina.Procesar_Fin_Nivel("burger_street", n, 200, 10, false)
	assert_eq(Sistema_Cocina.Obtener_Rango_Logro(), 1)
	assert_true(bool(Variables_Dinamicas.Objetos_Poseidos.get("Delantal_Aprendiz", false)))
	assert_eq(Variables_Estaticas.Record_Max_Niveles_Cocina, 5)
	assert_true(Sistema_Cocina.Equipar_Ropa("Delantal_Aprendiz"))
	assert_almost_eq(Sistema_Cocina.Obtener_Reduccion_Higiene_Hosteleria(), 0.05, 0.0001)
	assert_almost_eq(Sistema_Cocina.Calcular_Probabilidad_Desgaste_Higiene(0.05, 0.05), 0.0475, 0.0001)

	# Superar hasta 15 niveles -> Rango 3 y Chaqueta_Chef (+10% salario)
	for n in range(6, 16):
		Sistema_Cocina.Procesar_Fin_Nivel("burger_street", n, 600, 10, false)
	assert_eq(Sistema_Cocina.Obtener_Rango_Logro(), 3)
	assert_true(bool(Variables_Dinamicas.Objetos_Poseidos.get("Chaqueta_Chef", false)))
	assert_true(Sistema_Cocina.Equipar_Ropa("Chaqueta_Chef"))
	assert_almost_eq(Sistema_Cocina.Obtener_Bonus_Salario_Hosteleria(), 0.10, 0.0001)

	# Verificar salario real con Chaqueta_Chef (+10%) sin plus turno
	var act_cr: Actividad_Fija_Trabajo = Variables_Estaticas.Catalogo_Actividades["Trabajar_En_Comida_Rapida"]
	Variables_Dinamicas.Dinero = 0.0
	Variables_Dinamicas.Minute_Minute = act_cr.hora_final - 1
	Actividades.Ejecutar_Actividad(act_cr, false)
	assert_almost_eq(Variables_Dinamicas.Dinero, 88.0, 0.01)

	# Simular niveles hasta 45 (Rango 9) -> Atuendo_Chef_Gala (30) y Traje_Estrella_Michelin (45)
	for n in range(1, 16):
		Variables_Dinamicas.Cocina_Estado["estrellas_nivel"]["bistro_tradicional_%d" % n] = 1
		Variables_Dinamicas.Cocina_Estado["estrellas_nivel"]["alta_cocina_%d" % n] = 1
	var res45: Dictionary = Sistema_Cocina.Procesar_Fin_Nivel("burger_street", 15, 600, 40, true)
	assert_eq(int(res45["rango_nuevo"]), 9)
	assert_true(bool(Variables_Dinamicas.Objetos_Poseidos.get("Atuendo_Chef_Gala", false)))
	assert_true(bool(Variables_Dinamicas.Objetos_Poseidos.get("Traje_Estrella_Michelin", false)))
	assert_true(Sistema_Cocina.Equipar_Ropa("Traje_Estrella_Michelin"))
	assert_almost_eq(Sistema_Cocina.Obtener_Bonus_Salario_Hosteleria(), 0.30, 0.0001)
	assert_almost_eq(Sistema_Cocina.Obtener_Bonus_Propinas_Ropa(), 0.25, 0.0001)
	# Propinas con Traje_Estrella_Michelin (+25%)
	assert_almost_eq(
		Sistema_Cocina.Calcular_Propinas_Netas_Eur(20, 1, false, 1.0, 0.25),
		12.5, 0.01, "10 € base + 25% = 12.50 €")

	# Alimentacion.gd por rangos: 0 vs 2 vs 4 vs 7
	Variables_Dinamicas.Cocina_Estado["rango_logro"] = 0
	var ef_t0: Array = Alimentacion.Obtener_Efectos_Comer_Tupper(50)
	var ef_b0: Array = Alimentacion.Obtener_Efectos_Comer_Basura()
	var coste_b0: float = Alimentacion.Coste_Comida_Basura()

	Variables_Dinamicas.Cocina_Estado["rango_logro"] = 2
	var ef_t2: Array = Alimentacion.Obtener_Efectos_Comer_Tupper(50)
	var ef_b2: Array = Alimentacion.Obtener_Efectos_Comer_Basura()
	assert_eq(int(ef_t2[1]), int(ef_t0[1]) + 2, "Rango >= 2: +2 Salud Mental en Comer_Tupper")
	assert_eq(int(ef_b2[1]), int(ef_b0[1]) + 2, "Rango >= 2: +2 Salud Mental en Comer_Basura")

	Variables_Dinamicas.Cocina_Estado["rango_logro"] = 4
	assert_almost_eq(Alimentacion.Coste_Comida_Basura(), coste_b0 * 0.80, 0.01, "Rango >= 4: -20% coste Comer_Basura")
	var ef_t4: Array = Alimentacion.Obtener_Efectos_Comer_Tupper(50)
	assert_gt(int(ef_t4[2]), int(ef_t0[2]), "Rango >= 4: +15% saciedad en Comer_Tupper")

	# Rango >= 5: +15% eficiencia en Progreso_Cocina
	Variables_Dinamicas.Progreso_Cocina = 20
	Variables_Dinamicas.Cocina_Estado["rango_logro"] = 0
	var max_c0: int = Actividades_Habilidades.Calcular_Max_Progreso_Cocina()
	Variables_Dinamicas.Cocina_Estado["rango_logro"] = 5
	var max_c5: int = Actividades_Habilidades.Calcular_Max_Progreso_Cocina()
	assert_lt(max_c5, max_c0, "Rango >= 5 debe reducir el máximo aleatorio de Progreso_Cocina (+15% eficiencia)")

	Variables_Dinamicas.Cocina_Estado["rango_logro"] = 7
	var ef_t7: Array = Alimentacion.Obtener_Efectos_Comer_Tupper(50)
	var ef_b7: Array = Alimentacion.Obtener_Efectos_Comer_Basura()
	assert_eq(int(ef_t7[0]), int(ef_t0[0]) + 1, "Rango >= 7: +1 Salud Física en Comer_Tupper")
	assert_eq(int(ef_b7[0]), int(ef_b0[0]) + 1, "Rango >= 7: +1 Salud Física en Comer_Basura")
	assert_gt(int(ef_t7[2]), int(ef_t4[2]), "Rango >= 7: +15% adicional recuperación Hambre")
	assert_gt(int(ef_b7[2]), int(ef_b0[2]), "Rango >= 7: +15% recuperación Hambre en Comer_Basura")

	# Rango >= 8: Inmunidad total a "Intoxicación alimentaria" en Eventos_Aleatorios.gd
	Variables_Dinamicas.Cocina_Estado["rango_logro"] = 8
	assert_true(Sistema_Cocina.Es_Inmune_Intoxicacion())
	Variables_Dinamicas.Minute_Minute = 700 # Dentro de franja 8:00-22:00
	var ev_mgr = get_node("/root/Eventos_Aleatorios")
	for _k in range(150):
		var ev = ev_mgr._Seleccionar_Evento()
		if ev != null:
			assert_ne(ev.titulo, "Intoxicación alimentaria",
				"Con Rango >= 8 nunca debe salir Intoxicación alimentaria")


# ============================================================================
# 8. Integración de UI (Minijuego_Cocina 1280x720 + Escena principal + Perfil)
# ============================================================================

func test_08_ui_minijuego_cocina_y_escena_principal() -> void:
	Sistema_Cocina.Registrar_Minuto_Trabajo_Hosteleria("Trabajar_En_Comida_Rapida")

	var escena_mini = load("res://Escenas/Minijuego_Cocina/Minijuego_Cocina.tscn")
	assert_not_null(escena_mini, "Minijuego_Cocina.tscn debe existir")
	var mini = escena_mini.instantiate()
	add_child_autofree(mini)
	await get_tree().process_frame
	assert_eq(get_window().content_scale_size, Vector2i(1280, 720),
		"Al abrir el minijuego la resolución debe pasar a 1280x720 horizontal")
	assert_not_null(mini.get_node_or_null("Vista_Mapa"))
	assert_not_null(mini.get_node_or_null("Vista_Cocina"))
	assert_not_null(mini.get_node_or_null("Modal_Mejoras"))
	assert_not_null(mini.get_node_or_null("Modal_Resultados"))
	mini._Iniciar_Nivel(1)
	assert_true(mini.get_node("Vista_Cocina").visible)
	mini._Salir_Al_Sim()
	assert_eq(get_window().content_scale_size, Vector2i(720, 1280),
		"Al salir del minijuego debe restaurarse 720x1280 vertical")

	# Escena principal: Minijuegos_Button, Pantalla_Minijuegos y SubTab Apuntes|Ropa
	var raiz = load("res://Escenas/Escena_Principal/Escena principal.tscn").instantiate()
	assert_not_null(raiz.get_node_or_null("Minijuegos_Button"))
	assert_not_null(raiz.get_node_or_null("Pantalla_Mensajes/Panel_Apuntes/SubTab_Bar/SubTab_Ropa"))
	assert_not_null(raiz.get_node_or_null("Pantalla_Mensajes/Panel_Apuntes/Scroll_Ropa/VBox_Ropa"))
	raiz._Crear_Pantalla_Minijuegos()
	raiz._Redisenar_Superior()
	raiz._Redisenar_Perfil()
	raiz._Renderizar_Info()
	raiz._on_subtab_ropa_pressed()
	assert_true(raiz.get_node("Pantalla_Mensajes/Panel_Apuntes/Scroll_Ropa").visible)
	assert_not_null(raiz.get_node_or_null("Pantalla_Minijuegos"))
	raiz.free()


func test_09_gameplay_tap_to_move_y_fin_servicio() -> void:
	Sistema_Cocina.Registrar_Minuto_Trabajo_Hosteleria("Trabajar_En_Comida_Rapida")
	var mini = load("res://Escenas/Minijuego_Cocina/Minijuego_Cocina.tscn").instantiate()
	add_child_autofree(mini)
	await get_tree().process_frame

	mini._Iniciar_Nivel(1)
	# Forzar un cliente con pedido conocido: Hamburguesa sola + Refresco
	mini._clientes[0]["activo"] = true
	mini._clientes[0]["items"] = ["burger_sola", "refresco"]
	mini._clientes[0]["entregados"] = [false, false]
	mini._clientes[0]["paciencia_max"] = 30.0
	mini._clientes[0]["paciencia"] = 30.0
	mini._clientes[0]["precio_total"] = 18
	mini._Actualizar_Cliente_UI(0)

	# 1. Poner pan en plato 0 y carne en plancha 0
	mini._on_ingrediente_pan()
	assert_true(bool(mini._platos[0]["pan"]))
	mini._on_ingrediente_carne()
	assert_eq(str(mini._plancha[0]["estado"]), "cocinando")

	# 2. Avanzar cocción hasta "listo"
	mini._Tick_Slots_Coccion(mini._plancha, mini._slots_plancha_ui, mini._tiempo_coccion_carne, "Carne", mini._tiempo_coccion_carne + 0.1)
	assert_eq(str(mini._plancha[0]["estado"]), "listo")

	# 3. Tocar plancha -> pasa carne al plato 0 -> forma burger_sola
	mini._on_plancha_pulsada(0)
	assert_eq(str(mini._plancha[0]["estado"]), "vacio")
	assert_eq(mini._Receta_De_Plato(mini._platos[0]), "burger_sola")

	# 4. Tocar plato -> sirve burger_sola al cliente 0
	mini._on_plato_pulsado(0)
	assert_true(bool(mini._clientes[0]["entregados"][0]))
	assert_false(bool(mini._platos[0]["pan"]))

	# 5. Tocar bebida -> sirve refresco -> completa pedido y suma recaudación + propina
	mini._on_bebida_pulsada(0)
	assert_false(bool(mini._clientes[0]["activo"]), "El pedido completo debe liberar al cliente")
	assert_eq(mini._clientes_atendidos, 1)
	assert_gt(mini._recaudacion, 18, "Debe sumar precio + propina")
	assert_eq(str(mini._bebidas[0]["estado"]), "llenando")

	# 6. Verificar estado quemado y papelera
	mini._on_ingrediente_carne()
	mini._Tick_Slots_Coccion(mini._plancha, mini._slots_plancha_ui, mini._tiempo_coccion_carne, "Carne", mini._tiempo_coccion_carne + 0.1)
	mini._Tick_Slots_Coccion(mini._plancha, mini._slots_plancha_ui, mini._tiempo_coccion_carne, "Carne", mini._tiempo_quemado + 0.1)
	assert_eq(str(mini._plancha[0]["estado"]), "quemado")
	mini._on_plancha_pulsada(0)
	assert_eq(str(mini._plancha[0]["estado"]), "vacio", "Tocar carne quemada debe tirarla")

	# 7. Finalizar servicio y abrir Modal de Resultados
	mini._recaudacion = 60
	mini._Finalizar_Servicio()
	assert_true(mini.get_node("Modal_Resultados").visible)
	assert_eq(Sistema_Cocina.Obtener_Estrellas_Nivel("burger_street", 1), 1)
	mini._Salir_Al_Sim()
