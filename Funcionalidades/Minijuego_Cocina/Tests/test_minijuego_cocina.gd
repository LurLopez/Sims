extends GutTest

# Tests GUT completos del Minijuego de Cocina (gestión de pedidos),
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
	Sistema_Cocina.desbloqueo_total_qa = false
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
		"qa_desbloqueo": Sistema_Cocina.desbloqueo_total_qa,
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
	Sistema_Cocina.desbloqueo_total_qa = b["qa_desbloqueo"]
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
	for rest_id in ["burger_street", "bistro_tradicional", "cocina_mercado", "alta_cocina"]:
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
	f.flush()
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
	fe.flush()
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

	# Cada trabajo de hostelería tiene su propio mundo de cocina
	assert_true(Sistema_Cocina.Registrar_Minuto_Trabajo_Hosteleria("Trabajar_De_Ayudante_Cocina"))
	assert_true(Sistema_Cocina.Esta_Desbloqueado_Restaurante("bistro_tradicional"))
	var desc_bistro: String = str(Variables_Dinamicas.Mensajes.back().descripcion)
	assert_true(desc_bistro.contains("Bistró Tradicional") or desc_bistro.contains("Fase 2"),
		"El desbloqueo de un mundo debe indicar su nombre o avisar de la Fase 2")
	assert_true(Sistema_Cocina.Registrar_Minuto_Trabajo_Hosteleria("Trabajar_De_Cocinero_Partida"))
	assert_true(Sistema_Cocina.Esta_Desbloqueado_Restaurante("cocina_mercado"))
	assert_true(Sistema_Cocina.Registrar_Minuto_Trabajo_Hosteleria("Trabajar_De_Chef_Ejecutivo"))
	assert_true(Sistema_Cocina.Esta_Desbloqueado_Restaurante("alta_cocina"))
	assert_eq(Sistema_Cocina.ORDEN_RESTAURANTES.size(), 4,
		"Deben existir 4 mundos, uno por trabajo de hostelería")


# ============================================================================
# 3. Economía de Caja + costes, paga completa 2/día, modo práctica y Modo Rápido
# ============================================================================

func test_03_economia_caja_costes_y_modo_practica() -> void:
	Sistema_Cocina.Registrar_Minuto_Trabajo_Hosteleria("Trabajar_En_Comida_Rapida")
	Variables_Dinamicas.Dinero = 100.0

	# Servicio 1 (Nivel 1, 3★: 170 € de ticket = 150 € ventas + 20 € propinas)
	var r1: Dictionary = Sistema_Cocina.Procesar_Fin_Nivel("burger_street", 1, 170, 20, false)
	assert_eq(int(r1["estrellas"]), 3)
	assert_eq(int(r1["coste_ingredientes"]), 45)
	assert_eq(int(r1["coste_servicio"]), 8)
	assert_eq(int(r1["costes_totales"]), 53)
	assert_eq(int(r1["beneficio_neto"]), 97)
	assert_eq(int(r1["reparto_sim"]), 5)
	assert_eq(int(r1["caja_ganada"]), 92)
	assert_eq(Sistema_Cocina.Obtener_Caja_Restaurante(), 92)
	# Prima 0→3★ = (55+85+115)*0.10 = 25.50 €; propinas = 20*0.5 = 10 €; parte = 5 €
	assert_almost_eq(float(r1["bono_estrellas_eur"]), 25.5, 0.01)
	assert_almost_eq(float(r1["propinas_eur"]), 10.0, 0.01)
	assert_almost_eq(float(r1["dinero_ganado"]), 40.5, 0.01)
	assert_almost_eq(Variables_Dinamicas.Dinero, 140.5, 0.01)

	# Comprar mejora termostato (90 € de la Caja, no toca el dinero del Sim)
	var compra: Dictionary = Sistema_Cocina.Comprar_Mejora("burger_street", "termostato")
	assert_true(bool(compra["exito"]))
	assert_eq(Sistema_Cocina.Obtener_Nivel_Mejora("burger_street", "termostato"), 2)
	assert_eq(Sistema_Cocina.Obtener_Caja_Restaurante(), 2)
	assert_almost_eq(Variables_Dinamicas.Dinero, 140.5, 0.01,
		"Comprar una mejora NO debe tocar Dinero del Sim")

	# Servicio 2 del mismo día: paga completa y no repite la prima de estrellas
	var r2: Dictionary = Sistema_Cocina.Procesar_Fin_Nivel("burger_street", 1, 170, 20, false)
	assert_almost_eq(float(r2["bono_estrellas_eur"]), 0.0, 0.01)
	assert_almost_eq(float(r2["propinas_eur"]), 10.0, 0.01)
	assert_false(bool(r2["modo_practica"]))
	assert_eq(int(r2["caja_ganada"]), 92)

	# Servicio 3: cuota agotada -> modo práctica (25% para el Sim, Caja al 100%)
	var r3: Dictionary = Sistema_Cocina.Procesar_Fin_Nivel("burger_street", 1, 170, 20, false)
	assert_true(bool(r3["modo_practica"]))
	assert_true(bool(r3["limite_diario_alcanzado"]))
	assert_eq(int(r3["reparto_sim"]), 1)
	assert_almost_eq(float(r3["propinas_eur"]), 2.5, 0.01)
	assert_eq(int(r3["caja_ganada"]), 96,
		"El modo práctica no recorta el beneficio que entra en la Caja")
	assert_eq(Sistema_Cocina.Obtener_Caja_Restaurante(), 2 + 92 + 96)


func test_03b_formulas_de_costes_primas_y_propinas() -> void:
	# Costes: 30% de ingredientes + gasto fijo por nivel + 30% de la merma
	assert_eq(Sistema_Cocina.Calcular_Coste_Ingredientes(150), 45)
	assert_eq(Sistema_Cocina.Calcular_Coste_Servicio(1), 8)
	assert_eq(Sistema_Cocina.Calcular_Coste_Servicio(15), 36)
	assert_eq(Sistema_Cocina.Calcular_Coste_Merma(100), 30)
	assert_eq(Sistema_Cocina.Calcular_Beneficio_Neto(150, 1, 100), 67)
	assert_eq(Sistema_Cocina.Calcular_Reparto_Sim(67, false), 3)
	assert_eq(Sistema_Cocina.Calcular_Reparto_Sim(67, true), 1)
	assert_eq(Sistema_Cocina.Calcular_Caja_Ganada(67, 3), 64)
	assert_eq(Sistema_Cocina.Calcular_Estrellas(114, 55, 85, 115), 2)
	assert_eq(Sistema_Cocina.Calcular_Estrellas(115, 55, 85, 115), 3)

	# La prima escala con los umbrales del nivel (no es plana)
	assert_almost_eq(Sistema_Cocina.Calcular_Bono_Estrellas_Eur(0, 3, 55, 85, 115, 1.0), 25.5, 0.01)
	assert_almost_eq(Sistema_Cocina.Calcular_Bono_Estrellas_Eur(1, 3, 55, 85, 115, 1.0), 20.0, 0.01)
	assert_almost_eq(Sistema_Cocina.Calcular_Bono_Estrellas_Eur(3, 3, 55, 85, 115, 1.0), 0.0, 0.01)
	assert_almost_eq(Sistema_Cocina.Calcular_Bono_Estrellas_Eur(0, 1, 295, 415, 535, 1.0), 29.5, 0.01)

	# Propinas: 50% del bote; práctica x0.25; turno x1.5
	assert_almost_eq(Sistema_Cocina.Calcular_Propinas_Netas_Eur(20, 3, false, 1.0, 0.0, false), 10.0, 0.01)
	assert_almost_eq(Sistema_Cocina.Calcular_Propinas_Netas_Eur(20, 3, false, 1.0, 0.0, true), 2.5, 0.01)
	assert_almost_eq(Sistema_Cocina.Calcular_Propinas_Netas_Eur(20, 3, true, 1.0, 0.0, false), 15.0, 0.01)

	# Integración de la merma en el cierre de nivel: 100 € ventas, 40 € descartados
	var res_merma: Dictionary = Sistema_Cocina.Procesar_Fin_Nivel("burger_street", 1, 100, 0, false, 40)
	assert_eq(int(res_merma["estrellas"]), 2)
	assert_eq(int(res_merma["coste_ingredientes"]), 30)
	assert_eq(int(res_merma["coste_servicio"]), 8)
	assert_eq(int(res_merma["coste_merma"]), 12)
	assert_eq(int(res_merma["beneficio_neto"]), 50)
	assert_eq(int(res_merma["reparto_sim"]), 3)
	assert_eq(int(res_merma["caja_ganada"]), 47)


func test_03c_tope_micro_propinas_y_modo_rapido_precios() -> void:
	# Normal: tope 6 €
	var acum: float = 0.0
	for _i in range(10):
		var m: Dictionary = Sistema_Cocina.Procesar_Micro_Recompensa_Cliente(
			false, acum, {"cocina": 0.99, "manualidades": 0.99, "necesidad": 0.99, "propina": 0.01, "propina_base": 3.0})
		acum += float(m["micro_propina_eur"])
	assert_almost_eq(acum, 6.0, 0.01, "Las micro-propinas deben respetar el tope de 6 €")

	# Modo práctica: tope 1.50 € (6 € * 0.25)
	var acum_p: float = 0.0
	for _i in range(10):
		var mp: Dictionary = Sistema_Cocina.Procesar_Micro_Recompensa_Cliente(
			false, acum_p, {"cocina": 0.99, "manualidades": 0.99, "necesidad": 0.99, "propina": 0.01, "propina_base": 3.0}, true)
		acum_p += float(mp["micro_propina_eur"])
	assert_almost_eq(acum_p, 1.50, 0.01, "En práctica el tope de micro-propinas debe ser 1.50 €")

	# Modo Rápido (Multiplicador_Precios = 0.1): tope 0.60 € y primas x0.1
	Variables_Estaticas.Modo_Rapido = true
	var acum_r: float = 0.0
	for _i in range(10):
		var mr: Dictionary = Sistema_Cocina.Procesar_Micro_Recompensa_Cliente(
			false, acum_r, {"cocina": 0.99, "manualidades": 0.99, "necesidad": 0.99, "propina": 0.01, "propina_base": 3.0})
		acum_r += float(mr["micro_propina_eur"])
	assert_almost_eq(acum_r, 0.60, 0.01, "En Modo Rápido el tope de micro-propinas debe ser 0.60 €")

	var res_r: Dictionary = Sistema_Cocina.Procesar_Fin_Nivel("burger_street", 2, 140, 20, false)
	assert_almost_eq(float(res_r["bono_estrellas_eur"]), 3.15, 0.01,
		"(70+105+140) * 0.10 * 0.1 = 3.15 €")
	assert_almost_eq(float(res_r["propinas_eur"]), 1.0, 0.01, "10 € * 0.1 = 1.0 €")


# ============================================================================
# 4. Bonus Esta_En_Turno_Activo (propinas x1.5, paga ilimitada, +10% nómina)
# ============================================================================

func test_04_bonus_en_turno_activo_y_plus_nomina() -> void:
	var act_cr: Actividad_Fija_Trabajo = Variables_Estaticas.Catalogo_Actividades["Trabajar_En_Comida_Rapida"]
	Variables_Dinamicas.Matriz_Jugador[600][DIA_PRUEBA] = act_cr
	assert_true(Sistema_Cocina.Esta_En_Turno_Activo("burger_street"))
	assert_false(Sistema_Cocina.Esta_En_Turno_Activo("alta_cocina"))

	# La cuota libre está agotada, pero en turno la paga es completa e ilimitada
	Variables_Dinamicas.Cocina_Estado["servicios_remunerados_hoy"] = 2
	Variables_Dinamicas.Cocina_Estado["ultimo_dia_remunerado"] = DIA_PRUEBA

	var res: Dictionary = Sistema_Cocina.Procesar_Fin_Nivel("burger_street", 1, 170, 20, true)
	assert_eq(int(res["caja_ganada"]), 92, "La Caja cobra beneficio neto, sin x1.5 artificial")
	assert_almost_eq(float(res["propinas_eur"]), 15.0, 0.01, "En turno propinas x1.5 (20*0.5*1.5)")
	assert_eq(int(res["reparto_sim"]), 5)
	assert_false(bool(res["modo_practica"]))
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
# 7. Logros cada 20 estrellas (Rangos 1-9), prendas, Alimentacion e Inmunidad
# ============================================================================

func test_07_logros_prendas_efectos_alimentacion_e_inmunidad() -> void:
	Sistema_Cocina.Registrar_Minuto_Trabajo_Hosteleria("Trabajar_En_Comida_Rapida")

	# 19 ★ + una actuación de 3 ★ = 21 ★ -> Rango 1 y Delantal_Aprendiz
	_Fijar_Estrellas_Totales(19)
	Sistema_Cocina.Procesar_Fin_Nivel("burger_street", 7, 999, 10, false)
	assert_eq(Sistema_Cocina.Contar_Estrellas_Totales(), 21)
	assert_eq(Sistema_Cocina.Obtener_Rango_Logro(), 1)
	assert_true(bool(Variables_Dinamicas.Objetos_Poseidos.get("Delantal_Aprendiz", false)))
	assert_eq(Variables_Estaticas.Record_Max_Niveles_Cocina, 7)
	assert_true(Sistema_Cocina.Equipar_Ropa("Delantal_Aprendiz"))
	assert_almost_eq(Sistema_Cocina.Obtener_Reduccion_Higiene_Hosteleria(), 0.05, 0.0001)
	assert_almost_eq(Sistema_Cocina.Calcular_Probabilidad_Desgaste_Higiene(0.05, 0.05), 0.0475, 0.0001)

	# 59 ★ + una actuación de 3 ★ = 62 ★ -> Rango 3 y Chaqueta_Chef (+10% salario)
	_Fijar_Estrellas_Totales(59)
	Sistema_Cocina.Procesar_Fin_Nivel("alta_cocina", 15, 99999, 40, false)
	assert_eq(Sistema_Cocina.Contar_Estrellas_Totales(), 62)
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

	# 179 ★ + 1 ★ = 180 ★ (todas las estrellas del juego) -> Rango 9 y todas las prendas
	_Fijar_Estrellas_Totales(179)
	var res_rank9: Dictionary = Sistema_Cocina.Procesar_Fin_Nivel(
		"alta_cocina", 15, 99999, 40, true)
	assert_eq(int(res_rank9["rango_nuevo"]), 9)
	assert_eq(Sistema_Cocina.Contar_Estrellas_Totales(), Sistema_Cocina.ESTRELLAS_TOTALES_MAX)
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
	_Fijar_Estrellas_Totales(0)
	var ef_t0: Array = Alimentacion.Obtener_Efectos_Comer_Tupper(50)
	var ef_b0: Array = Alimentacion.Obtener_Efectos_Comer_Basura()
	var coste_b0: float = Alimentacion.Coste_Comida_Basura()

	_Fijar_Estrellas_Totales(40)
	var ef_t2: Array = Alimentacion.Obtener_Efectos_Comer_Tupper(50)
	var ef_b2: Array = Alimentacion.Obtener_Efectos_Comer_Basura()
	assert_eq(int(ef_t2[1]), int(ef_t0[1]) + 2, "Rango >= 2: +2 Salud Mental en Comer_Tupper")
	assert_eq(int(ef_b2[1]), int(ef_b0[1]) + 2, "Rango >= 2: +2 Salud Mental en Comer_Basura")

	_Fijar_Estrellas_Totales(80)
	assert_almost_eq(Alimentacion.Coste_Comida_Basura(), coste_b0 * 0.80, 0.01, "Rango >= 4: -20% coste Comer_Basura")
	var ef_t4: Array = Alimentacion.Obtener_Efectos_Comer_Tupper(50)
	assert_gt(int(ef_t4[2]), int(ef_t0[2]), "Rango >= 4: +15% saciedad en Comer_Tupper")

	# Rango >= 5: +15% eficiencia en Progreso_Cocina
	Variables_Dinamicas.Progreso_Cocina = 20
	_Fijar_Estrellas_Totales(0)
	var max_c0: int = Actividades_Habilidades.Calcular_Max_Progreso_Cocina()
	_Fijar_Estrellas_Totales(100)
	var max_c5: int = Actividades_Habilidades.Calcular_Max_Progreso_Cocina()
	assert_lt(max_c5, max_c0, "Rango >= 5 debe reducir el máximo aleatorio de Progreso_Cocina (+15% eficiencia)")

	_Fijar_Estrellas_Totales(140)
	var ef_t7: Array = Alimentacion.Obtener_Efectos_Comer_Tupper(50)
	var ef_b7: Array = Alimentacion.Obtener_Efectos_Comer_Basura()
	assert_eq(int(ef_t7[0]), int(ef_t0[0]) + 1, "Rango >= 7: +1 Salud Física en Comer_Tupper")
	assert_eq(int(ef_b7[0]), int(ef_b0[0]) + 1, "Rango >= 7: +1 Salud Física en Comer_Basura")
	assert_gt(int(ef_t7[2]), int(ef_t4[2]), "Rango >= 7: +15% adicional recuperación Hambre")
	assert_gt(int(ef_b7[2]), int(ef_b0[2]), "Rango >= 7: +15% recuperación Hambre en Comer_Basura")

	# Rango >= 8: Inmunidad total a "Intoxicación alimentaria" en Eventos_Aleatorios.gd
	_Fijar_Estrellas_Totales(160)
	assert_true(Sistema_Cocina.Es_Inmune_Intoxicacion())
	Variables_Dinamicas.Minute_Minute = 700 # Dentro de franja 8:00-22:00
	var ev_mgr = get_node("/root/Eventos_Aleatorios")
	for _k in range(150):
		var ev = ev_mgr._Seleccionar_Evento()
		if ev != null:
			assert_ne(ev.titulo, "Intoxicación alimentaria",
				"Con Rango >= 8 nunca debe salir Intoxicación alimentaria")


# ============================================================================
# 8. Integración de UI (Minijuego_Cocina: selector y partida horizontales)
# ============================================================================

func test_08_ui_minijuego_cocina_y_escena_principal() -> void:
	Sistema_Cocina.Registrar_Minuto_Trabajo_Hosteleria("Trabajar_En_Comida_Rapida")

	var escena_mini = load("res://Escenas/Minijuego_Cocina/Minijuego_Cocina.tscn")
	assert_not_null(escena_mini, "Minijuego_Cocina.tscn debe existir")
	var mini = escena_mini.instantiate()
	add_child_autofree(mini)
	await get_tree().process_frame
	assert_eq(get_window().content_scale_size, Vector2i(1280, 720),
		"El selector de niveles debe abrirse en horizontal 1280x720")
	assert_true(mini.get_node("Vista_Mapa").visible, "El mapa de niveles debe verse al abrir")
	assert_not_null(mini.get_node_or_null("Modal_Maestria"))
	assert_not_null(mini.find_child("Panel_Maestria_Mapa", true, false),
		"El selector de mundos debe mostrar el progreso de Maestría")
	assert_not_null(mini.find_child("Boton_Maestria_Mapa", true, false),
		"La cabecera debe abrir el detalle de Maestría")
	assert_not_null(mini.get_node_or_null("Vista_Cocina"))
	assert_not_null(mini.get_node_or_null("Vista_Carga"))
	assert_not_null(mini.get_node_or_null("Modal_Mejoras"))
	assert_not_null(mini.get_node_or_null("Modal_Resultados"))

	mini._Comenzar_Carga_Nivel(1)
	assert_eq(get_window().content_scale_size, Vector2i(1280, 720),
		"Al entrar a una partida la pantalla de carga debe pasar a 1280x720 horizontal")
	assert_true(mini.get_node("Vista_Carga").visible, "La barra de progreso debe mostrarse al cargar")

	mini._Finalizar_Carga()
	await get_tree().process_frame
	assert_true(mini.get_node("Vista_Cocina").visible, "Tras la carga debe verse la cocina")

	mini._Mostrar_Mapa()
	assert_eq(get_window().content_scale_size, Vector2i(1280, 720),
		"Al volver al mapa debe mantenerse 1280x720 horizontal")
	assert_false(mini.get_node("Vista_Carga").visible, "La pantalla de carga debe ocultarse al volver")

	mini._Salir_Al_Sim()
	assert_eq(get_window().content_scale_size, Vector2i(720, 1280),
		"Al salir del minijuego debe restaurarse 720x1280 vertical")

	# Escena principal: Vestuario como sección propia (ya no dentro de Apuntes)
	var raiz = load("res://Escenas/Escena_Principal/Escena principal.tscn").instantiate()
	assert_not_null(raiz.get_node_or_null("Minijuegos_Button"))
	assert_not_null(raiz.get_node_or_null("Vestuario_Button"), "El Vestuario debe tener su propia pestaña superior")
	assert_null(raiz.get_node_or_null("Pantalla_Mensajes/Panel_Apuntes/SubTab_Bar/SubTab_Ropa"),
		"Ropa ya no debe estar dentro de Apuntes")
	assert_null(raiz.get_node_or_null("Pantalla_Mensajes/Panel_Apuntes/Scroll_Ropa"))
	raiz._Crear_Pantalla_Minijuegos()
	raiz._Crear_Pantalla_Vestuario()
	raiz._Redisenar_Superior()
	raiz._Redisenar_Perfil()
	raiz._Renderizar_Info()
	assert_not_null(raiz.get_node_or_null("Pantalla_Minijuegos"))
	assert_not_null(raiz.get_node_or_null("Pantalla_Vestuario"))
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
	# El cliente entra caminando con un tween; para probar el servicio sin
	# depender del reloj de animación lo dejamos ya sentado en la mesa.
	mini._slots_clientes_ui[0]["visible_antes"] = true
	mini._slots_clientes_ui[0]["fase"] = "esperando"

	# 1. Poner pan en plato 0 y carne en plancha 0
	mini._on_ingrediente_pan()
	assert_true(bool(mini._platos[0]["pan"]))
	mini._on_ingrediente_carne()
	assert_eq(str(mini._plancha[0]["estado"]), "cocinando")

	# 2. Avanzar cocción hasta "listo"
	mini._Tick_Slots_Coccion(mini._plancha, mini._slots_plancha_ui, mini._tiempo_coccion_carne, "Carne", mini._tiempo_coccion_carne + 0.1)
	assert_eq(str(mini._plancha[0]["estado"]), "listo")

	# 3. Tocar plancha NO mueve la carne; arrastrarla al plato 0 forma burger_sola
	mini._on_plancha_pulsada(0)
	assert_eq(str(mini._plancha[0]["estado"]), "listo", "Tocar carne lista no debe moverla automáticamente")
	assert_true(mini._Soltar_En_Plato({"tipo": "carne_lista", "indice": 0}, 0))
	assert_eq(str(mini._plancha[0]["estado"]), "vacio")
	assert_eq(mini._Receta_De_Plato(mini._platos[0]), "burger_sola")

	# 4. Tocar plato NO sirve; arrastrarlo al cliente 0 entrega burger_sola
	mini._on_plato_pulsado(0)
	assert_false(bool(mini._clientes[0]["entregados"][0]), "Tocar el plato no debe entregarlo")
	assert_true(mini._Soltar_En_Cliente({"tipo": "plato", "indice": 0, "receta": "burger_sola"}, 0))
	assert_true(bool(mini._clientes[0]["entregados"][0]))
	assert_false(bool(mini._platos[0]["pan"]))

	# 5. Tocar bebida NO sirve; arrastrarla al cliente completa el pedido y suma propina
	mini._on_bebida_pulsada(0)
	assert_true(bool(mini._clientes[0]["activo"]), "Tocar la bebida no debe entregarla")
	assert_true(mini._Soltar_En_Cliente({"tipo": "bebida", "indice": 0, "item": "refresco"}, 0))
	assert_false(bool(mini._clientes[0]["activo"]), "El pedido completo debe liberar al cliente")
	assert_eq(mini._clientes_atendidos, 1)
	assert_gt(mini._recaudacion, 18, "Debe sumar precio + propina")
	assert_gt(mini._propinas_servicio, 0, "La propina se contabiliza aparte")
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


func test_10_selector_restaurantes_y_confirmacion_salida() -> void:
	Sistema_Cocina.Registrar_Minuto_Trabajo_Hosteleria("Trabajar_En_Comida_Rapida")
	var mini = load("res://Escenas/Minijuego_Cocina/Minijuego_Cocina.tscn").instantiate()
	add_child_autofree(mini)
	await get_tree().process_frame

	assert_null(mini._contenedor_niveles.get_node_or_null("Grid_Niveles"),
		"Los niveles deben estar ocultos hasta que se toque un restaurante")
	assert_not_null(mini.get_node_or_null("Modal_Confirmar_Salida"),
		"Debe existir el modal de confirmación de salida")
	assert_eq(mini._lista_restaurantes.get_child_count(), 4,
		"Deben mostrarse los 4 mundos de cocina")
	assert_true(mini._lista_restaurantes is GridContainer,
		"El selector horizontal debe colocar los mundos en cuadrícula")
	assert_eq((mini._lista_restaurantes as GridContainer).columns, 2,
		"Los 4 mundos deben repartirse en 2 columnas")
	for i in range(1, 4):
		assert_true(mini._lista_restaurantes.get_child(i).disabled,
			"Los mundos de Fase 2 deben estar bloqueados")

	# Tocar la tarjeta de Burger & Street Food revela sus 15 niveles.
	mini._lista_restaurantes.get_child(0).emit_signal("pressed")
	await get_tree().process_frame
	var grid = mini._contenedor_niveles.find_child("Grid_Niveles", true, false)
	assert_not_null(grid, "Al tocar Burger & Street Food deben aparecer los niveles")
	assert_eq(grid.get_child_count(), 15, "Burger & Street Food debe mostrar sus 15 niveles")
	assert_eq((grid as GridContainer).columns, 5,
		"Los 15 niveles deben verse en 5 columnas × 3 filas")
	assert_not_null(mini.find_child("Marco_Selector_Niveles", true, false),
		"El selector debe usar el marco celeste cartoon")
	assert_not_null(mini._contenedor_niveles.find_child("Barra_Scroll_Niveles", true, false),
		"El tablero debe incluir la barra de desplazamiento lateral")
	var primer_nivel = grid.get_child(0)
	assert_not_null(primer_nivel.get_node_or_null("Numero_Nivel"),
		"Cada moneda de nivel debe mostrar su número sobre la placa verde")
	assert_eq(primer_nivel.get_node("Numero_Nivel").text, "1",
		"La primera moneda debe rotularse como nivel 1")
	for i in range(grid.get_child_count()):
		var moneda = grid.get_child(i)
		assert_eq(moneda.name, "Nivel_%d" % (i + 1),
			"Las monedas deben conservar el orden de los niveles")
		assert_eq(moneda.get_node("Numero_Nivel").text, str(i + 1),
			"Cada moneda debe rotular su nivel correctamente")
	assert_true(mini._contenedor_niveles.visible, "El mapa de niveles debe mostrarse al entrar")
	assert_false(mini._lista_restaurantes.visible, "El selector debe ocultarse al entrar en un mundo")

	# «Volver» dentro de un mundo regresa al selector sin cerrar el minijuego.
	mini._Volver_Mapa()
	assert_false(mini._contenedor_niveles.visible,
		"El mapa de niveles debe ocultarse al volver al selector")
	assert_true(mini._lista_restaurantes.visible, "El selector de mundos debe reaparecer")
	assert_null(mini._contenedor_niveles.find_child("Grid_Niveles", true, false),
		"El selector no debe conservar los niveles al volver")
	assert_eq(mini._lista_restaurantes.get_child_count(), 4,
		"Volver debe restaurar los 4 mundos")
	assert_eq(mini._lbl_mapa_titulo.text, "Cocina · Mundos")

	# Volver a entrar en Burger & Street Food para el resto de la prueba.
	mini._lista_restaurantes.get_child(0).emit_signal("pressed")
	await get_tree().process_frame
	assert_true(mini._contenedor_niveles.visible)

	# La flecha verde del panel abre el siguiente nivel pendiente.
	mini._Abrir_Siguiente_Nivel()
	assert_true(mini._modal_inicio.visible,
		"La flecha verde debe abrir la ficha del siguiente nivel")
	assert_eq(mini._nivel_seleccionado, 1,
		"Sin estrellas previas, el siguiente nivel pendiente es el 1")
	assert_not_null(mini._modal_inicio.find_child("Marco_Modal", true, false),
		"La ficha de nivel debe usar el marco cartoon azul")
	assert_not_null(mini._modal_inicio.find_child("Boton_Empezar_Servicio", true, false),
		"La ficha de nivel debe conservar el botón de empezar servicio")
	mini._modal_inicio.visible = false

	# Dentro de una partida, volver al mapa exige confirmación y pausa el nivel.
	mini._Iniciar_Nivel(1)
	assert_true(mini._jugando)
	mini._Intentar_Volver_Al_Mapa()
	assert_true(mini.get_node("Modal_Confirmar_Salida").visible,
		"Volver al mapa en plena partida debe abrir la confirmación")
	assert_not_null(mini._modal_salida.find_child("Marco_Modal", true, false),
		"La confirmación de salida debe usar el marco cartoon azul")
	assert_not_null(mini._modal_salida.find_child("Boton_Confirmar_Salida", true, false),
		"La confirmación de salida debe conservar el botón de salir")
	assert_false(mini._jugando, "La partida debe pausarse mientras se decide")

	# Seguir cocinando reanuda la partida.
	mini._Cancelar_Salida_Partida()
	assert_true(mini._jugando, "Cancelar la salida debe reanudar la partida")
	assert_false(mini.get_node("Modal_Confirmar_Salida").visible)

	# Salir y perder progreso vuelve al mapa sin otorgar recompensas.
	var estrellas_antes: int = Sistema_Cocina.Obtener_Estrellas_Nivel("burger_street", 1)
	mini._Intentar_Volver_Al_Mapa()
	mini._Confirmar_Salida_Partida()
	assert_true(mini.get_node("Vista_Mapa").visible, "Confirmar la salida debe volver al mapa")
	assert_false(mini.get_node("Vista_Cocina").visible)
	assert_eq(Sistema_Cocina.Obtener_Estrellas_Nivel("burger_street", 1), estrellas_antes,
		"Abandonar el nivel no debe guardar estrellas")
	mini._Salir_Al_Sim()


# ============================================================================
# 11. HUD superior inspirado en la referencia: menú, clientes y dinero
# ============================================================================

func test_11_hud_superior_menu_clientes_y_dinero() -> void:
	Sistema_Cocina.Registrar_Minuto_Trabajo_Hosteleria("Trabajar_En_Comida_Rapida")
	var mini = load("res://Escenas/Minijuego_Cocina/Minijuego_Cocina.tscn").instantiate()
	add_child_autofree(mini)
	await get_tree().process_frame
	mini._Iniciar_Nivel(1)

	var btn_menu: Button = mini.find_child("Boton_Menu", true, false)
	assert_not_null(btn_menu, "El HUD debe tener un botón de menú azul")
	assert_not_null(mini.find_child("Pill_Clientes", true, false),
		"El HUD debe tener la píldora de clientes restantes")
	assert_eq(mini._lbl_cocina_clientes.text, "11",
		"El contador de clientes debe mostrar solo el número, como la referencia")
	assert_true(mini._lbl_cocina_recaudacion.text.ends_with("€"),
		"El contador de dinero debe mostrar el importe con moneda")

	btn_menu.emit_signal("pressed")
	assert_true(mini._modal_pausa.visible,
		"El botón Menú debe abrir el menú de pausa (seguir, repetir, al mapa)")
	assert_not_null(mini._modal_pausa.find_child("Marco_Modal", true, false),
		"El menú de pausa debe usar el marco cartoon azul")
	assert_not_null(mini._modal_pausa.find_child("Boton_Seguir", true, false),
		"El menú de pausa debe conservar el botón Seguir cocinando")
	mini._Reanudar_Partida()
	assert_false(mini._modal_pausa.visible)
	mini._Salir_Al_Sim()


# ============================================================================
# 12. Pantalla de Mejoras: datos de presentación, compra y estado máximo
# ============================================================================

func test_12_mejoras_presentacion_y_compra_en_modal() -> void:
	# Cada mejora tiene tres escalones completos para la pantalla.
	for mejora_id in Sistema_Cocina.ORDEN_MEJORAS:
		var def: Dictionary = Sistema_Cocina.MEJORAS_DEF[mejora_id]
		assert_true(def.has("nombre_corto"), "%s debe tener nombre corto de lista" % mejora_id)
		assert_eq((def.get("costes", []) as Array).size(), 3,
			"%s debe tener tres costes" % mejora_id)
		var niveles: Array = def.get("niveles", [])
		assert_eq(niveles.size(), 3, "%s debe tener tres niveles descritos" % mejora_id)
		for i in range(niveles.size()):
			var info: Dictionary = niveles[i]
			assert_true(str(info.get("nombre", "")) != "",
				"%s Nv.%d debe tener nombre de nivel" % [mejora_id, i + 1])
			assert_gte((info.get("beneficios", []) as Array).size(), 2,
				"%s Nv.%d debe listar al menos dos beneficios" % [mejora_id, i + 1])
			assert_true(Sistema_Cocina.Obtener_Frase_Nivel_Mejora(mejora_id, i + 1) != "",
				"%s Nv.%d debe tener frase de mejora" % [mejora_id, i + 1])
			if i == 0:
				assert_true((info.get("ganancias", []) as Array).is_empty(),
					"El nivel básico no tiene ganancias previas")
			else:
				assert_gte((info.get("ganancias", []) as Array).size(), 1,
					"%s Nv.%d debe indicar qué gana" % [mejora_id, i + 1])
		assert_not_null(Arte_Cocina.textura_mejora(mejora_id, 1))
		assert_not_null(Arte_Cocina.textura_mejora(mejora_id, 3))

	Sistema_Cocina.Registrar_Minuto_Trabajo_Hosteleria("Trabajar_En_Comida_Rapida")
	Variables_Dinamicas.Cocina_Estado["fondos_cocina"] = 0

	var mini = load("res://Escenas/Minijuego_Cocina/Minijuego_Cocina.tscn").instantiate()
	add_child_autofree(mini)
	await get_tree().process_frame
	mini._Mostrar_Mapa()
	await get_tree().process_frame
	mini._lista_restaurantes.get_child(0).emit_signal("pressed")
	await get_tree().process_frame
	assert_false(mini._btn_mapa_mejoras.disabled,
		"Con un mundo jugable abierto, el botón Mejoras debe estar habilitado")
	mini._btn_mapa_mejoras.emit_signal("pressed")
	await get_tree().process_frame

	var modal: Control = mini._modal_mejoras
	assert_true(modal.visible, "El botón Mejoras debe abrir la pantalla nueva")
	var cta := modal.find_child("Boton_Comprar_Mejora", true, false) as Button
	assert_not_null(cta, "La pantalla debe tener un botón de compra")
	assert_true(cta.text.contains("FALTAN"), "Sin Caja debe invitar a servir otro turno")
	cta.emit_signal("pressed")
	await get_tree().process_frame
	assert_eq(Sistema_Cocina.Obtener_Nivel_Mejora("burger_street", "plancha"), 1,
		"Sin Caja suficiente no se compra la mejora")

	Variables_Dinamicas.Cocina_Estado["fondos_cocina"] = 500
	modal.call("abrir", "burger_street")
	modal.call("seleccionar_mejora", "plancha")
	await get_tree().process_frame
	assert_true(cta.text.contains("120 €"), "Nv.1 debe ofrecer la mejora por 120 €")
	cta.emit_signal("pressed")
	await get_tree().process_frame
	assert_eq(Sistema_Cocina.Obtener_Nivel_Mejora("burger_street", "plancha"), 2,
		"La compra debe subir la plancha a Nv.2")
	assert_true(cta.text.contains("NV. 3"), "Tras comprar debe ofrecer el Nv.3")

	Variables_Dinamicas.Cocina_Estado["mejoras"]["burger_street"]["plancha"] = 3
	modal.call("abrir", "burger_street")
	await get_tree().process_frame
	assert_true(cta.disabled, "En Nv.3 el botón de compra debe estar desactivado")
	assert_true(cta.text.contains("NIVEL MÁXIMO"), "En Nv.3 debe mostrar el estado máximo")
	modal.call("cerrar")
	await get_tree().process_frame
	assert_false(modal.visible, "Cerrar la pantalla de mejoras debe ocultarla")
	mini._Salir_Al_Sim()


## Coloca el progreso del minijuego en un total exacto de estrellas repartidas
## entre todos los restaurantes. Sirve para probar los umbrales de Maestría.
func _Fijar_Estrellas_Totales(total: int) -> void:
	var restante: int = clampi(total, 0, Sistema_Cocina.ESTRELLAS_TOTALES_MAX)
	var dict: Dictionary = {}
	for rest_id in Sistema_Cocina.ORDEN_RESTAURANTES:
		for n in range(1, 16):
			if restante <= 0:
				break
			var valor: int = mini(3, restante)
			dict["%s_%d" % [rest_id, n]] = valor
			restante -= valor
		if restante <= 0:
			break
	Variables_Dinamicas.Cocina_Estado["estrellas_nivel"] = dict
