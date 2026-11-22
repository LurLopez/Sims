extends GutTest

# Tests del sistema de cocina, tuppers y alimentación dual.
# Cubre TC-01 a TC-11 de la especificación v5.

const DIA_PRUEBA := 10
const RUTA_SAVE_PRUEBA := "user://test_cocina_alimentacion.dat"

var _save_path_original: String = ""


func before_all() -> void:
	_save_path_original = Guardar_Variables_Dinamicas.save_path
	_Inicializar_Matriz()


func before_each() -> void:
	Variables_Estaticas.Modo_Rapido = false
	Variables_Estaticas.Habilidades = [50, 50, 50, 50, 50, 50, 50]
	Variables_Estaticas.Personalidad = ""
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
	Variables_Dinamicas.Minute_Minute = 0
	Variables_Dinamicas.Minute = DIA_PRUEBA * 1440
	Variables_Dinamicas.Estados_Temporales = {}
	Variables_Dinamicas.Fiesta_Evento_Ocurrido = false
	Variables_Dinamicas.Mensajes = []
	Variables_Dinamicas.Muerto = false
	Variables_Dinamicas.Carrera_Actual = null
	Variables_Dinamicas.Trabajo_Actual = null
	Variables_Dinamicas.Esta_Invirtiendo = false
	Variables_Dinamicas.Ultima_Fecha_Alquiler = -1
	Variables_Dinamicas.Prob_Supervivencia_Acumulada = 1.0
	Variables_Dinamicas.Cooldown_Trabajos = {}
	Variables_Dinamicas.Objetos_Poseidos = {"Cama_Basica": true, "Mesa_Basica": true, "Ducha_Basica": true}
	Variables_Dinamicas.Objeto_Seleccionado = {"Dormir": "Cama_Basica", "Comer": "Mesa_Basica", "Duchar": "Ducha_Basica"}
	_Limpiar_Celdas()


func after_each() -> void:
	Variables_Estaticas.Modo_Rapido = false
	Guardar_Variables_Dinamicas.save_path = _save_path_original
	if FileAccess.file_exists(RUTA_SAVE_PRUEBA):
		DirAccess.remove_absolute(RUTA_SAVE_PRUEBA)


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
		for columna in range(0, 14):
			Variables_Dinamicas.Matriz_Jugador[fila][columna] = ""


func _Crear_Tupper(caducidad_relativa: int = 4320, porcentaje: float = 100.0, calidad: int = 50) -> Dictionary:
	var tupper: Dictionary = {
		"id": Variables_Dinamicas.Tuppers.size() + 1,
		"porcentaje_restante": porcentaje,
		"calidad": calidad,
		"minuto_creacion": Variables_Dinamicas.Minute,
		"minuto_caducidad": Variables_Dinamicas.Minute + caducidad_relativa
	}
	Variables_Dinamicas.Tuppers.append(tupper)
	return tupper


func _Avanzar_Minuto() -> void:
	Variables_Dinamicas.Minute += 1
	Variables_Dinamicas.Minute_Minute += 1
	if Variables_Dinamicas.Minute_Minute >= 1440:
		Variables_Dinamicas.Minute_Minute = 0
		Variables_Dinamicas.Minute_Day += 1


# ---------------------------------------------------------------------------
# TC-01: catálogo, pool aleatorio y mesa premium retirada
# ---------------------------------------------------------------------------

func test_tc01_catalogo_y_sin_comida_gratis() -> void:
	assert_true(Variables_Estaticas.Catalogo_Actividades.has("Cocinar"))
	assert_true(Variables_Estaticas.Catalogo_Actividades.has("Comer_Tupper"))
	assert_true(Variables_Estaticas.Catalogo_Actividades.has("Comer_Basura"))
	assert_false(Variables_Estaticas.Catalogo_Actividades.has("Comer"),
		"La actividad gratuita 'Comer' ya no debe existir")
	for act in Variables_Estaticas.Actividades:
		assert_ne(act.nombre, "Cocinar")
		assert_ne(act.nombre, "Comer_Tupper")
		assert_ne(act.nombre, "Comer_Basura")
	assert_false(Variables_Estaticas.Catalogo_Objetos.has("Mesa_Premium"),
		"Mesa_Premium debe estar retirada del catálogo")
	assert_true(Variables_Estaticas.Catalogo_Objetos.has("Mesa_Basica"))


func test_tc01_migracion_de_comer_a_comer_basura() -> void:
	var rle := {
		"formato": "rle",
		"filas": 1,
		"columnas": 1,
		"datos": ["Comer", 1]
	}
	var matriz: Array = Guardar_Variables_Dinamicas._RLE_A_Matriz(rle)
	assert_eq(matriz[0][0], Variables_Estaticas.Catalogo_Actividades["Comer_Basura"])


# ---------------------------------------------------------------------------
# TC-02: validación temporal y vivienda
# ---------------------------------------------------------------------------

func test_tc02_validacion_cocinar() -> void:
	var corto: Dictionary = Actividades.Validar_Horario_Cocinar(14)
	assert_false(corto["valido"])
	assert_true(str(corto["motivo"]).contains("15"))

	var justo: Dictionary = Actividades.Validar_Horario_Cocinar(15)
	assert_true(justo["valido"])

	Variables_Dinamicas.En_La_Calle = true
	var calle: Dictionary = Actividades.Validar_Horario_Cocinar(60)
	assert_false(calle["valido"])
	assert_true(str(calle["motivo"]).to_lower().contains("vivienda"))


func test_tc02_duracion_de_rango() -> void:
	assert_eq(Actividades.Calcular_Duracion_Rango(0, 10, 0, 0, 11, 30), 90)
	assert_eq(Actividades.Calcular_Duracion_Rango(0, 23, 30, 0, 24, 0), 30)
	assert_eq(Actividades.Calcular_Duracion_Rango(0, 23, 30, 0, 0, 30), 60,
		"Un rango que cruza medianoche debe contar 60 minutos")


# ---------------------------------------------------------------------------
# TC-03: producción, calidad y modo rápido
# ---------------------------------------------------------------------------

func test_tc03_treinta_minutos_generan_dos_tuppers() -> void:
	Variables_Dinamicas.Progreso_Cocina = 100
	var dinero_inicial: float = Variables_Dinamicas.Dinero
	for i in range(30):
		var r: Dictionary = Alimentacion.Ejecutar_Minuto_Cocinar()
		assert_false(bool(r.get("cancelado", false)))
		_Avanzar_Minuto()

	assert_eq(Variables_Dinamicas.Tuppers.size(), 2)
	assert_eq(int(Variables_Dinamicas.Tuppers[0]["calidad"]), 100)
	assert_eq(int(Variables_Dinamicas.Tuppers[1]["calidad"]), 100)
	assert_almost_eq(float(Variables_Dinamicas.Tuppers[0]["porcentaje_restante"]), 100.0, 0.001)
	assert_eq(int(Variables_Dinamicas.Tuppers[0]["minuto_caducidad"]),
		int(Variables_Dinamicas.Tuppers[0]["minuto_creacion"]) + 3 * 1440)
	assert_almost_eq(Variables_Dinamicas.Dinero, dinero_inicial - 4.0, 0.001)


func test_tc03_modo_rapido_escala_coste_y_caducidad() -> void:
	Variables_Estaticas.Modo_Rapido = true
	Variables_Dinamicas.Progreso_Cocina = 100
	var dinero_inicial: float = Variables_Dinamicas.Dinero
	for i in range(15):
		Alimentacion.Ejecutar_Minuto_Cocinar()
		_Avanzar_Minuto()

	assert_eq(Variables_Dinamicas.Tuppers.size(), 1)
	assert_almost_eq(Variables_Dinamicas.Dinero, dinero_inicial - 0.2, 0.001)
	assert_eq(int(Variables_Dinamicas.Tuppers[0]["minuto_caducidad"]),
		int(Variables_Dinamicas.Tuppers[0]["minuto_creacion"]) + 1440)


# ---------------------------------------------------------------------------
# TC-04: interrupción voluntaria e insolvencia
# ---------------------------------------------------------------------------

func test_tc04_interrupcion_en_minuto_20() -> void:
	Variables_Dinamicas.Progreso_Cocina = 100
	var dinero_inicial: float = Variables_Dinamicas.Dinero
	for i in range(20):
		Alimentacion.Ejecutar_Minuto_Cocinar()
		_Avanzar_Minuto()
	assert_eq(Variables_Dinamicas.Tuppers.size(), 1, "Solo se entrega al completar 15 min")
	assert_almost_eq(Variables_Dinamicas.Dinero, dinero_inicial - 2.0, 0.001)
	assert_eq(Variables_Dinamicas.Minutos_Cocinando_Actuales, 20)


func test_tc04_insolvencia_cancela_y_limpia_bloque() -> void:
	# Bloque de 10 minutos de Cocinar desde el minuto actual.
	var actividad = Variables_Estaticas.Catalogo_Actividades["Cocinar"]
	for i in range(10):
		Variables_Dinamicas.Matriz_Jugador[i][DIA_PRUEBA] = actividad
	Variables_Dinamicas.Dinero = 0.0
	Variables_Dinamicas.Minutos_Cocinando_Actuales = 5

	var r: Dictionary = Alimentacion.Ejecutar_Minuto_Cocinar()
	assert_true(bool(r.get("cancelado", false)))
	assert_eq(Variables_Dinamicas.Dinero, 0.0)
	assert_eq(Variables_Dinamicas.Minutos_Cocinando_Actuales, 0)
	for i in range(10):
		assert_eq(Variables_Dinamicas.Matriz_Jugador[i][DIA_PRUEBA], "",
			"La celda %d del bloque debe quedar limpia" % i)
	assert_eq(Variables_Dinamicas.Tuppers.size(), 0)


# ---------------------------------------------------------------------------
# TC-05: consumo parcial de tuppers
# ---------------------------------------------------------------------------

func test_tc05_quince_minutos_consumen_la_mitad() -> void:
	_Crear_Tupper(4320, 100.0, 50)
	Variables_Dinamicas.Tupper_Seleccionado_Idx = 0
	for i in range(15):
		var r: Dictionary = Alimentacion.Ejecutar_Minuto_Comer_Tupper(false)
		assert_false(bool(r.get("cancelado", false)))
		_Avanzar_Minuto()
	assert_eq(Variables_Dinamicas.Tuppers.size(), 1)
	assert_almost_eq(float(Variables_Dinamicas.Tuppers[0]["porcentaje_restante"]), 50.0, 0.05)


func test_tc05_treinta_minutos_agotan_y_eliminan() -> void:
	_Crear_Tupper(4320, 100.0, 50)
	Variables_Dinamicas.Tupper_Seleccionado_Idx = 0
	for i in range(30):
		Alimentacion.Ejecutar_Minuto_Comer_Tupper(false)
		_Avanzar_Minuto()
	assert_eq(Variables_Dinamicas.Tuppers.size(), 0)
	assert_eq(Variables_Dinamicas.Tupper_Seleccionado_Idx, -1)


# ---------------------------------------------------------------------------
# TC-06: selección manual vs automática y encadenado
# ---------------------------------------------------------------------------

func test_tc06_seleccion_manual_consume_el_elegido() -> void:
	var t0 := _Crear_Tupper(4000, 100.0, 10)
	var t1 := _Crear_Tupper(5000, 100.0, 90)
	Variables_Dinamicas.Tupper_Seleccionado_Idx = 1
	Alimentacion.Ejecutar_Minuto_Comer_Tupper(false)
	assert_lt(float(t1["porcentaje_restante"]), 100.0)
	assert_almost_eq(float(t0["porcentaje_restante"]), 100.0, 0.001)


func test_tc06_seleccion_automatica_prefiere_vigente_y_caducidad_cercana() -> void:
	var t0 := _Crear_Tupper(1000, 100.0, 10)
	_Crear_Tupper(5000, 100.0, 90)
	Variables_Dinamicas.Tupper_Seleccionado_Idx = -1
	assert_eq(Alimentacion.Obtener_Indice_Tupper_Activo(false), 0,
		"Debe elegir el tupper vigente que caduca antes")
	Alimentacion.Ejecutar_Minuto_Comer_Tupper(false)
	assert_lt(float(t0["porcentaje_restante"]), 100.0)


func test_tc06_encadena_al_siguiente_y_luego_pasa_a_basura() -> void:
	# Dos tuppers al 50 % = 15 minutos cada uno. Bloque de 60 min de tupper.
	var actividad_tupper = Variables_Estaticas.Catalogo_Actividades["Comer_Tupper"]
	for i in range(60):
		Variables_Dinamicas.Matriz_Jugador[i][DIA_PRUEBA] = actividad_tupper
	_Crear_Tupper(4320, 50.0, 50)
	_Crear_Tupper(4320, 50.0, 50)
	Variables_Dinamicas.Tupper_Seleccionado_Idx = 0

	for i in range(30):
		Alimentacion.Ejecutar_Minuto_Comer_Tupper(false)
		_Avanzar_Minuto()

	assert_eq(Variables_Dinamicas.Tuppers.size(), 0)
	assert_eq(Variables_Dinamicas.Matriz_Jugador[30][DIA_PRUEBA],
		Variables_Estaticas.Catalogo_Actividades["Comer_Basura"],
		"Al agotar todos los tuppers, el resto del bloque pasa a comida rápida")


# ---------------------------------------------------------------------------
# TC-07: caducidad e intoxicación
# ---------------------------------------------------------------------------

func test_tc07_el_tupper_caducado_permanece_en_inventario() -> void:
	_Crear_Tupper(-60, 100.0, 50)
	Variables_Dinamicas.Tupper_Seleccionado_Idx = 0
	Alimentacion.Ejecutar_Minuto_Comer_Tupper(false)
	assert_eq(Variables_Dinamicas.Tuppers.size(), 1, "Un tupper caducado no se borra solo")


func test_tc07_probabilidad_creciente() -> void:
	var p1: float = Alimentacion.Calcular_Prob_Intoxicacion_Minuto(60)
	var p2: float = Alimentacion.Calcular_Prob_Intoxicacion_Minuto(1440)
	var p3: float = Alimentacion.Calcular_Prob_Intoxicacion_Minuto(2880)
	assert_lt(p1, p2)
	assert_lt(p2, p3)
	assert_almost_eq(p3, 1.0, 0.0001, "A partir de 48 h la probabilidad debe ser 100 %")


func test_tc07_intoxicacion_garantizada_y_techo() -> void:
	_Crear_Tupper(-2880, 100.0, 50)
	Variables_Dinamicas.Tupper_Seleccionado_Idx = 0
	Variables_Dinamicas.Necesidades_Basicas = [80, 80, 50, 50, 50]
	Alimentacion.Ejecutar_Minuto_Comer_Tupper(false)
	assert_true(Variables_Dinamicas.Estados_Temporales.has("Intoxicacion"))
	assert_eq(Variables_Dinamicas.Estados_Temporales["Intoxicacion"], 1440)
	assert_eq(Variables_Dinamicas.Necesidades_Basicas[0], 30)
	assert_eq(Variables_Dinamicas.Necesidades_Basicas[1], 30)
	assert_eq(Actividades.Obtener_Cap_Estado("Intoxicacion"), 30)


# ---------------------------------------------------------------------------
# TC-08: comida rápida e insolvencia
# ---------------------------------------------------------------------------

func test_tc08_cobra_cada_cinco_minutos() -> void:
	Variables_Dinamicas.Dinero = 100.0
	Variables_Dinamicas.Minute_Minute = 0
	var r0: Dictionary = Alimentacion.Ejecutar_Minuto_Comer_Basura()
	assert_true(bool(r0["cobrado"]))
	assert_almost_eq(Variables_Dinamicas.Dinero, 98.0, 0.001)
	for i in range(4):
		_Avanzar_Minuto()
		var r: Dictionary = Alimentacion.Ejecutar_Minuto_Comer_Basura()
		assert_false(bool(r["cobrado"]), "No debe cobrar de nuevo hasta el minuto 5")
	assert_almost_eq(Variables_Dinamicas.Dinero, 98.0, 0.001)
	_Avanzar_Minuto()
	var r5: Dictionary = Alimentacion.Ejecutar_Minuto_Comer_Basura()
	assert_true(bool(r5["cobrado"]))
	assert_almost_eq(Variables_Dinamicas.Dinero, 96.0, 0.001)


func test_tc08_penaliza_salud_fisica() -> void:
	Variables_Dinamicas.Necesidades_Basicas = [100, 50, 50, 50, 50]
	Variables_Dinamicas.Dinero = 100000.0
	for i in range(600):
		Alimentacion.Ejecutar_Minuto_Comer_Basura()
		_Avanzar_Minuto()
	assert_lt(Variables_Dinamicas.Necesidades_Basicas[0], 100,
		"La comida rápida debe reducir la salud física con el tiempo")


func test_tc08_insolvencia_cancela_y_limpia() -> void:
	var actividad = Variables_Estaticas.Catalogo_Actividades["Comer_Basura"]
	for i in range(10):
		Variables_Dinamicas.Matriz_Jugador[i][DIA_PRUEBA] = actividad
	Variables_Dinamicas.Dinero = 0.0
	Variables_Dinamicas.Minute_Minute = 0
	var r: Dictionary = Alimentacion.Ejecutar_Minuto_Comer_Basura()
	assert_true(bool(r.get("cancelado", false)))
	for i in range(10):
		assert_eq(Variables_Dinamicas.Matriz_Jugador[i][DIA_PRUEBA], "")


# ---------------------------------------------------------------------------
# TC-09: IA pasiva sin comida gratis
# ---------------------------------------------------------------------------

func test_tc09_ia_elige_tupper_vigente() -> void:
	Variables_Dinamicas.Necesidades_Basicas = [50, 50, 10, 50, 50]
	_Crear_Tupper(4320, 100.0, 50)
	Variables_Dinamicas.Dinero = 0.0
	var act = Actividades.Crear_Actividad_Aleatoria_Debajo_De_30(2)
	assert_eq(act.nombre, "Comer_Tupper")


func test_tc09_ia_elige_basura_si_no_hay_tuppers_y_hay_dinero() -> void:
	Variables_Dinamicas.Necesidades_Basicas = [50, 50, 10, 50, 50]
	Variables_Dinamicas.Dinero = 10.0
	var act = Actividades.Crear_Actividad_Aleatoria_Debajo_De_30(2)
	assert_eq(act.nombre, "Comer_Basura")


func test_tc09_ia_no_come_gratis_sin_tuppers_ni_dinero() -> void:
	Variables_Dinamicas.Necesidades_Basicas = [50, 50, 10, 50, 50]
	Variables_Dinamicas.Dinero = 0.0
	var act = Actividades.Crear_Actividad_Aleatoria_Debajo_De_30(2)
	assert_ne(act.nombre, "Comer_Tupper")
	assert_ne(act.nombre, "Comer_Basura")
	assert_true(int(act.efectos_necesidades_basicas[2]) <= 0,
		"La actividad ociosa no debe recuperar Hambre gratis")


# ---------------------------------------------------------------------------
# TC-10: fórmula de progreso y requisitos de hostelería
# ---------------------------------------------------------------------------

func test_tc10_habilidades_altas_aceleran_progreso() -> void:
	Variables_Dinamicas.Progreso_Cocina = 1
	Variables_Estaticas.Habilidades = [50, 50, 20, 20, 50, 20, 20]
	var max_bajo: int = Actividades_Habilidades.Calcular_Max_Progreso_Cocina()
	Variables_Estaticas.Habilidades = [50, 50, 100, 100, 50, 100, 100]
	var max_alto: int = Actividades_Habilidades.Calcular_Max_Progreso_Cocina()
	assert_lt(max_alto, max_bajo,
		"Un máximo menor implica más probabilidad de subir Progreso_Cocina")


func test_tc10_hosteleria_solo_exige_cocina() -> void:
	var puestos := {
		"Trabajar_De_Ayudante_Cocina": [30, 17.0, 660, 1140],
		"Trabajar_De_Cocinero_Partida": [60, 24.0, 720, 1200],
		"Trabajar_De_Chef_Ejecutivo": [85, 36.0, 780, 1260],
	}
	for nombre in puestos:
		var act: Actividad_Fija_Trabajo = Variables_Estaticas.Catalogo_Actividades[nombre]
		assert_eq(act.requisito_cocina, puestos[nombre][0])
		assert_eq(act.requisito_progreso, [0, 0, 0], "No debe exigir progreso general")
		assert_eq(act.requisito_carrera, [], "No debe exigir carrera")
		assert_almost_eq(act.salario, puestos[nombre][1], 0.001)
		assert_eq(act.hora_inicio, puestos[nombre][2])
		assert_eq(act.hora_final, puestos[nombre][3])


# ---------------------------------------------------------------------------
# TC-11: persistencia
# ---------------------------------------------------------------------------

func test_tc11_guardar_y_cargar_cocina_y_tuppers() -> void:
	Guardar_Variables_Dinamicas.save_path = RUTA_SAVE_PRUEBA
	Variables_Dinamicas.Progreso_Cocina = 42
	_Crear_Tupper(4320, 66.6, 42)
	Variables_Dinamicas.Tupper_Seleccionado_Idx = 0
	Guardar_Variables_Dinamicas.save_game()

	Variables_Dinamicas.Progreso_Cocina = 1
	Variables_Dinamicas.Tuppers = []
	Variables_Dinamicas.Tupper_Seleccionado_Idx = -1
	Guardar_Variables_Dinamicas.load_game()

	assert_eq(Variables_Dinamicas.Progreso_Cocina, 42)
	assert_eq(Variables_Dinamicas.Tuppers.size(), 1)
	assert_eq(int(Variables_Dinamicas.Tuppers[0]["calidad"]), 42)
	assert_eq(Variables_Dinamicas.Tupper_Seleccionado_Idx, 0)
	assert_eq(Variables_Dinamicas.Minutos_Cocinando_Actuales, 0)


func test_tc11_partida_antigua_sin_claves_usa_defaults() -> void:
	Guardar_Variables_Dinamicas.save_path = RUTA_SAVE_PRUEBA
	var datos := {
		"Matriz_Jugador": Guardar_Variables_Dinamicas._Matriz_A_RLE(),
		"Progreso": [1, 1, 1],
		"Necesidades_Basicas": [50, 50, 50, 50, 50],
		"Dinero": 100,
		"Minute": 0,
		"Minute_Day": 0,
		"Minute_Minute": 0
	}
	var archivo := FileAccess.open(RUTA_SAVE_PRUEBA, FileAccess.WRITE)
	archivo.store_var(datos)
	archivo = null

	Variables_Dinamicas.Progreso_Cocina = 99
	Variables_Dinamicas.Tuppers = [{"id": 99}]
	Variables_Dinamicas.Tupper_Seleccionado_Idx = 0
	Guardar_Variables_Dinamicas.load_game()

	assert_eq(Variables_Dinamicas.Progreso_Cocina, 1)
	assert_eq(Variables_Dinamicas.Tuppers, [])
	assert_eq(Variables_Dinamicas.Tupper_Seleccionado_Idx, -1)
	assert_eq(Variables_Dinamicas.Minutos_Cocinando_Actuales, 0)


# ---------------------------------------------------------------------------
# Integración de UI mínima
# ---------------------------------------------------------------------------

func test_ui_pantalla_mensajes_tiene_pestana_y_panel_despensa() -> void:
	var packed = load("res://Escenas/Escena_Principal/Pantalla_Mensajes.tscn")
	var raiz = packed.instantiate()
	assert_not_null(raiz.get_node_or_null("Tab_Bar/Tab_Despensa"))
	assert_not_null(raiz.get_node_or_null("Panel_Despensa/Scroll_Tuppers/VBox_Tuppers"))
	raiz.free()


func test_ui_escena_principal_tiene_boton_cocinar_y_hosteleria() -> void:
	var packed = load("res://Escenas/Escena_Principal/Escena principal.tscn")
	var raiz = packed.instantiate()
	var cocinar = raiz.get_node_or_null(
		"Actividades/Elegir_Actividad/Tipos_De_Actividades/Temporales_Opciones/Necesidades_Basicas_Opciones/Cocinar")
	assert_not_null(cocinar)
	assert_true(cocinar.pressed.is_connected(Callable(raiz, "Actividad_Terminada_Cocinar")))
	assert_not_null(raiz.get_node_or_null(
		"Actividades/Elegir_Actividad/Tipos_De_Actividades/Fijas_Opciones/Trabajo_Opciones/Cocinero"))
	for nombre in ["Comida_Rapida", "Ayudante_Cocina", "Cocinero_Partida", "Chef_Ejecutivo"]:
		assert_not_null(raiz.get_node_or_null(
			"Actividades/Elegir_Actividad/Tipos_De_Actividades/Fijas_Opciones/Trabajo_Opciones/Cocinero_Opciones/" + nombre))
	# Ejercita los rediseños que tocan las nuevas barras/pestañas.
	raiz._Redisenar_Perfil()
	raiz._Redisenar_Progreso()
	raiz._Renderizar_Despensa()
	raiz._Renderizar_Info()
	assert_not_null(raiz.get_node_or_null("Progreso/Progreso_Barra/Cocina"))
	raiz.free()


func test_ui_fila_tupper_y_modal_se_construyen() -> void:
	_Crear_Tupper(4320, 50.0, 60)
	var fila = Tupper_UI.crear_fila(0, Variables_Dinamicas.Tuppers[0], false,
		func(): pass, func(): pass)
	assert_not_null(fila)
	fila.free()

	var modal = load("res://Scripts/GUI/Escena_Principal/Tuppers/Modal_Tuppers.gd").new()
	add_child_autofree(modal)
	assert_not_null(modal)


func test_ui_preview_alimentacion_se_construye_en_los_tres_modos() -> void:
	var raiz = load("res://Escenas/Escena_Principal/Escena principal.tscn").instantiate()
	raiz.Inicializar_Otros_Scripts()
	raiz._Redisenar_Seleccionar_Horario()
	var bloque = HorarioDesdeBloque.new()
	bloque.Inicializar("Lunes", 10, 0, "Lunes", 11, 0)
	raiz.actividades_reloj_gui.Comprobar_Visibilidad(raiz, bloque)

	for modo in ["Comer_Basura", "Comer_Tupper", "Cocinar"]:
		raiz.actividad_seleccionada = modo
		raiz._Mostrar_Preview_Alimentacion()
		var panel = raiz.get_node_or_null("Actividades/Seleccionar_Horario/Preview_Alimentacion")
		assert_not_null(panel, "Debe crearse la vista previa para %s" % modo)
		if panel != null:
			assert_not_null(panel.find_child("Preview_Alim_Coste", true, false))
	if raiz.actividades_reloj_gui != null and is_instance_valid(raiz.actividades_reloj_gui.horario):
		raiz.actividades_reloj_gui.horario.free()
	for auxiliar in [raiz.actividades_reloj_gui, raiz.actividades_bloque_gui,
			raiz.necesidades_basicas_gui, raiz.first_time_logica, bloque]:
		if auxiliar != null and is_instance_valid(auxiliar):
			auxiliar.free()
	raiz.free()


func test_ui_escena_principal_ready_y_pestanas_del_perfil() -> void:
	# La escena completa se instancia sin árbol para no disparar el dibujado
	# del escenario en headless; se ejercitan los rediseños y las pestañas.
	var raiz = load("res://Escenas/Escena_Principal/Escena principal.tscn").instantiate()
	raiz._Redisenar_Perfil()
	raiz._on_perfil_tab_despensa_pressed()
	assert_true(raiz.get_node("Pantalla_Mensajes/Panel_Despensa").visible)
	raiz._on_perfil_tab_info_pressed()
	raiz._on_perfil_tab_apuntes_pressed()
	raiz._on_perfil_tab_mensajes_pressed()
	assert_false(raiz.get_node("Pantalla_Mensajes/Panel_Despensa").visible)
	raiz.free()


func test_ui_calendario_y_reloj_sin_bugs() -> void:
	Variables_Dinamicas.Minute_Day = 0
	Variables_Dinamicas.Minute_Minute = 603
	for m in range(603):
		Variables_Dinamicas.Matriz_Jugador[m][0] = "Actividad_Aleatoria"
	var act_cocinar = Variables_Estaticas.Catalogo_Actividades["Cocinar"]
	for m in range(615, 630):
		Variables_Dinamicas.Matriz_Jugador[m][0] = act_cocinar
	var act_estudiar = Variables_Estaticas.Catalogo_Actividades["Estudiar"]
	for m in range(870, 960):
		Variables_Dinamicas.Matriz_Jugador[m][1] = act_estudiar

	var raiz = load("res://Escenas/Escena_Principal/Escena principal.tscn").instantiate()
	raiz.mirar_semana = 0
	raiz.Inicializar_Otros_Scripts()
	raiz._Redisenar_Horario()
	raiz._Redisenar_Seleccionar_Horario()
	raiz.Iniciar_Bloques_Actividad()

	var col_horas = raiz.get_node("Actividades/Horario_Semanal/Mover_Vertical/Todo calendario/Horario")
	assert_eq(col_horas.get_child_count(), 48, "48 filas de media hora en la columna de horas")
	(col_horas.get_child(0) as Button).pressed.emit()

	var btn_ant: Button = raiz.get_node("Actividades/Horario_Semanal/OPCIONES_CALENDARIO/ANTERIOR SEMANA")
	assert_false(btn_ant.visible, "En semana 0 ANTERIOR SEMANA debe estar oculto")

	var col_lunes = raiz.get_node("Actividades/Horario_Semanal/Mover_Vertical/Todo calendario/Dias/Lunes")
	assert_eq(col_lunes.get_child_count(), 4, "Lunes debe dividirse en 4 bloques (pasado, libre 10m, cocinar 15m, libre resto)")

	var b_pasado: Button = col_lunes.get_child(0)
	var b_cocinar_15m: Button = col_lunes.get_child(2)
	assert_eq(b_pasado.get_meta("estado"), "pasado", "El slot en curso con Actividad_Aleatoria debe ser pasado")
	assert_eq(b_cocinar_15m.get_meta("estado"), "ocupado", "El bloque de Cocinar debe ser ocupado")

	raiz.actividades_bloque_gui.click_bloque(b_cocinar_15m, raiz)
	assert_true(raiz.actividades_bloque_gui.comprobar_seleccionado())
	var hb_cocinar = raiz.actividades_bloque_gui.devolver_hora_desde_posiciones()
	assert_eq(hb_cocinar.dia_inicio, "Lunes")
	assert_eq(hb_cocinar.hora_inicio, 10)
	assert_eq(hb_cocinar.minuto_inicio, 15)
	assert_eq(hb_cocinar.hora_final, 10)
	assert_eq(hb_cocinar.minuto_final, 30)
	hb_cocinar.free()

	# Eliminar actividad debe refrescar el calendario al instante y ocultar el botón Eliminar
	raiz._on_eliminar_actividad_pressed()
	assert_eq(col_lunes.get_child_count(), 2, "Tras eliminar Cocinar, los bloques libres se fusionan")
	var btn_elim: Button = raiz.get_node("Actividades/Horario_Semanal/OPCIONES_CALENDARIO/ELIMINAR_ACTIVIDAD")
	assert_false(btn_elim.visible)
	if raiz.horario_bloque != null and is_instance_valid(raiz.horario_bloque):
		raiz.horario_bloque.free()
		raiz.horario_bloque = null

	# Selector de horario: bloque de 1h (10:00-11:00), bajar y subir minutos desde :00
	var bloque_1h = HorarioDesdeBloque.new()
	bloque_1h.Inicializar("Lunes", 10, 0, "Lunes", 11, 0)
	raiz.horario_bloque = bloque_1h
	raiz.actividades_reloj_gui.Comprobar_Visibilidad(raiz, bloque_1h)
	var h = raiz.actividades_reloj_gui.horario
	assert_eq(h.hora_inicio_texto.text, "10")
	assert_eq(h.minuto_inicio_texto.text, "00")
	assert_eq(h.hora_final_texto.text, "11")
	assert_eq(h.minuto_final_texto.text, "00")

	raiz.Final_Minuto_Abajo()
	assert_eq(h.hora_final_texto.text, "10")
	assert_eq(h.minuto_final_texto.text, "55")

	raiz.Final_Minuto_Arriba()
	assert_eq(h.hora_final_texto.text, "11")
	assert_eq(h.minuto_final_texto.text, "00")

	# Selector de horario: bloque de 2h (10:00-12:00), reactivación de botones cuando minuto_final == 0
	var bloque_2h = HorarioDesdeBloque.new()
	bloque_2h.Inicializar("Lunes", 10, 0, "Lunes", 12, 0)
	raiz.horario_bloque = bloque_2h
	raiz.actividades_reloj_gui.Comprobar_Visibilidad(raiz, bloque_2h)
	assert_false(h.hora_inicio_arriba.disabled)
	raiz.Inicio_Hora_Arriba()
	assert_eq(h.hora_inicio_texto.text, "11")
	assert_true(h.hora_inicio_arriba.disabled)
	raiz.Inicio_Hora_Abajo()
	assert_eq(h.hora_inicio_texto.text, "10")
	assert_false(h.hora_inicio_arriba.disabled)
	assert_false(h.hora_final_abajo.disabled)

	# MiniCalendarioPreview detecta actividad en :30 (Martes 14:30-16:00)
	var mini = MiniCalendarioPreview.new()
	mini.crear(raiz, 0)
	mini.actualizar_rango(0, 10, 0, 0, 12, 0)
	mini.aplicar_blink(true)
	assert_ne(mini._colores_base[1][14], MiniCalendarioPreview.COLOR_LIBRE)
	mini.limpiar()
	mini.free()

	if raiz.horario_bloque != null and raiz.horario_bloque != bloque_1h and raiz.horario_bloque != bloque_2h:
		raiz.horario_bloque.free()
	bloque_1h.free()
	bloque_2h.free()
	if raiz.actividades_reloj_gui != null and is_instance_valid(raiz.actividades_reloj_gui.horario):
		raiz.actividades_reloj_gui.horario.free()
	if raiz.actividades_bloque_gui != null and is_instance_valid(raiz.actividades_bloque_gui.bloque_columna):
		raiz.actividades_bloque_gui.bloque_columna.free()
	for auxiliar in [raiz.actividades_reloj_gui, raiz.actividades_bloque_gui,
			raiz.necesidades_basicas_gui, raiz.first_time_logica]:
		if auxiliar != null and is_instance_valid(auxiliar):
			auxiliar.free()
	raiz.free()




