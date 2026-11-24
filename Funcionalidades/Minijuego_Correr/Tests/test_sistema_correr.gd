extends GutTest

# Tests de la lógica del runner "Salir a correr": recompensas, récords,
# persistencia y aplicación al Sim. Usan una ruta de guardado temporal para
# no tocar la partida real.

const RUTA_TEST := "user://test_minijuego_correr.cfg"

var _ruta_original: String
var _progreso_original: Array
var _necesidades_originales: Array
var _ultimo_uso_original: Array
var _ultimo_check_original: Array
var _minuto_original: int
var _dinero_original: float
var _calle_original: bool
var _estados_originales: Dictionary


func before_all() -> void:
	_ruta_original = Sistema_Correr._ruta_guardado
	_progreso_original = Variables_Dinamicas.Progreso.duplicate(true)
	_necesidades_originales = Variables_Dinamicas.Necesidades_Basicas.duplicate(true)
	_ultimo_uso_original = Variables_Dinamicas.Ultimo_Uso_Progreso.duplicate(true)
	_ultimo_check_original = Variables_Dinamicas.Ultimo_Check_Decadencia.duplicate(true)
	_minuto_original = Variables_Dinamicas.Minute
	_dinero_original = Variables_Dinamicas.Dinero
	_calle_original = Variables_Dinamicas.En_La_Calle
	_estados_originales = Variables_Dinamicas.Estados_Temporales.duplicate(true)
	Sistema_Correr.Configurar_Ruta_Guardado_Pruebas(RUTA_TEST)


func after_all() -> void:
	Variables_Dinamicas.Progreso = _progreso_original
	Variables_Dinamicas.Necesidades_Basicas = _necesidades_originales
	Variables_Dinamicas.Ultimo_Uso_Progreso = _ultimo_uso_original
	Variables_Dinamicas.Ultimo_Check_Decadencia = _ultimo_check_original
	Variables_Dinamicas.Minute = _minuto_original
	Variables_Dinamicas.Dinero = _dinero_original
	Variables_Dinamicas.En_La_Calle = _calle_original
	Variables_Dinamicas.Estados_Temporales = _estados_originales
	Sistema_Correr.Restaurar_Ruta_Guardado_Real()
	if FileAccess.file_exists(RUTA_TEST):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(RUTA_TEST))


func before_each() -> void:
	Sistema_Correr.Reiniciar_Datos_Pruebas()
	Variables_Dinamicas.Progreso = [4, 1, 1]
	Variables_Dinamicas.Necesidades_Basicas = [50, 50, 50, 50, 50]
	Variables_Dinamicas.Ultimo_Uso_Progreso = [-1, -1, -1]
	Variables_Dinamicas.Ultimo_Check_Decadencia = [-1, -1, -1]
	Variables_Dinamicas.Minute = 123456
	Variables_Dinamicas.Dinero = 800.0
	Variables_Dinamicas.En_La_Calle = false
	Variables_Dinamicas.Estados_Temporales.clear()


# ----------------------------------------------------------------------------
# Cálculo de recompensa
# ----------------------------------------------------------------------------

func test_carrera_corta_no_da_recompensa() -> void:
	var r: Dictionary = Sistema_Correr.Calcular_Recompensa(99.0, 200)
	assert_false(bool(r["valida"]))
	assert_eq(int(r["deporte"]), 0)
	assert_eq(int(r["salud_fisica"]), 0)
	assert_eq(int(r["hambre"]), 0)


func test_recompensa_basica_desde_100m() -> void:
	var r: Dictionary = Sistema_Correr.Calcular_Recompensa(100.0, 0)
	assert_true(bool(r["valida"]))
	assert_eq(int(r["deporte"]), 1)
	assert_eq(int(r["salud_fisica"]), 3)
	assert_eq(int(r["salud_mental"]), 2)
	assert_eq(int(r["hambre"]), -2)
	assert_eq(int(r["descanso"]), -2)
	assert_eq(int(r["higiene"]), -3)


func test_recompensa_escala_con_distancia_y_monedas() -> void:
	var r: Dictionary = Sistema_Correr.Calcular_Recompensa(900.0, 30)
	assert_true(bool(r["valida"]))
	# 1 punto base + 2 por 900 m + 1 por 30 monedas = 4 (tope).
	assert_eq(int(r["deporte"]), 4)
	assert_eq(int(r["salud_fisica"]), 4)
	assert_eq(int(r["hambre"]), -3)
	assert_eq(int(r["higiene"]), -4)


func test_recompensa_tope_de_deporte() -> void:
	var r: Dictionary = Sistema_Correr.Calcular_Recompensa(5000.0, 999)
	assert_eq(int(r["deporte"]), Sistema_Correr.MAX_PUNTOS_DEPORTE)
	assert_eq(int(r["salud_fisica"]), 5)
	assert_eq(int(r["hambre"]), -4)


func test_formatear_distancia() -> void:
	assert_eq(Sistema_Correr.Formatear_Distancia(0.0), "0 m")
	assert_eq(Sistema_Correr.Formatear_Distancia(999.4), "999 m")
	assert_eq(Sistema_Correr.Formatear_Distancia(1234.0), "1.234 m")
	assert_eq(Sistema_Correr.Formatear_Distancia(12345.0), "12.345 m")


# ----------------------------------------------------------------------------
# Récords y persistencia
# ----------------------------------------------------------------------------

func test_registrar_carrera_actualiza_estadisticas() -> void:
	var r: Dictionary = Sistema_Correr.Registrar_Carrera(750.0, 20, false)
	assert_true(bool(r["nuevo_record"]))
	assert_eq(int(r["puntuacion"]), 950)
	assert_eq(Sistema_Correr.Obtener_Record_Distancia(), 750)
	assert_eq(Sistema_Correr.Obtener_Carreras(), 1)
	assert_eq(Sistema_Correr.Obtener_Monedas_Totales(), 20)


func test_records_no_bajan_con_una_carrera_peor() -> void:
	Sistema_Correr.Registrar_Carrera(750.0, 20, false)
	var r: Dictionary = Sistema_Correr.Registrar_Carrera(500.0, 5, false)
	assert_false(bool(r["nuevo_record"]))
	assert_eq(Sistema_Correr.Obtener_Record_Distancia(), 750)
	assert_eq(Sistema_Correr.Obtener_Carreras(), 2)
	assert_eq(Sistema_Correr.Obtener_Monedas_Totales(), 25)
	assert_eq(Sistema_Correr.Obtener_Distancia_Total(), 1250)


func test_persistencia_en_archivo() -> void:
	Sistema_Correr.Registrar_Carrera(750.0, 20, false)
	assert_true(FileAccess.file_exists(RUTA_TEST))
	var cfg := ConfigFile.new()
	assert_eq(cfg.load(RUTA_TEST), OK)
	assert_eq(float(cfg.get_value(Sistema_Correr.SECCION, "mejor_distancia")), 750.0)
	assert_eq(int(cfg.get_value(Sistema_Correr.SECCION, "monedas_totales")), 20)


# ----------------------------------------------------------------------------
# Aplicación al Sim
# ----------------------------------------------------------------------------

func test_recompensa_se_aplica_al_progreso_y_las_necesidades() -> void:
	var r: Dictionary = Sistema_Correr.Registrar_Carrera(850.0, 0, true)
	assert_true(bool((r["recompensa"] as Dictionary)["valida"]))
	# 1 base + 2 por 850 m = 3 puntos de Deporte.
	assert_eq(int(Variables_Dinamicas.Progreso[0]), 7)
	# Bonus de necesidades por superar 500 m: +4, +3, -3, -3, -4.
	assert_eq(Variables_Dinamicas.Necesidades_Basicas, [54, 53, 47, 47, 46])
	assert_eq(Variables_Dinamicas.Ultimo_Uso_Progreso[0], 123456)
	assert_eq(Variables_Dinamicas.Ultimo_Check_Decadencia[0], 123456)


func test_carrera_corta_no_modifica_al_sim() -> void:
	Sistema_Correr.Registrar_Carrera(50.0, 0, true)
	assert_eq(Variables_Dinamicas.Progreso[0], 4)
	assert_eq(Variables_Dinamicas.Necesidades_Basicas, [50, 50, 50, 50, 50])
