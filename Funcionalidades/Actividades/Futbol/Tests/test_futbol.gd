extends GutTest

# Tests GUT de la Carrera de Futbolista (Fase 1).
# Cubren el motor puro (Simulador_Futbol y Calendario_Futbol) y la
# normalización de saves antiguos sin la clave "Carrera_Futbol".

const SIM = preload("res://Scripts/Logica/Escena_Principal/Actividades/Futbol/Simulador_Futbol.gd")
const CAL = preload("res://Scripts/Logica/Escena_Principal/Actividades/Futbol/Calendario_Futbol.gd")


# ------------------------------------------------------------------
# Condición e innata
# ------------------------------------------------------------------

func test_condicion_fisica_valores_extremos() -> void:
	assert_almost_eq(SIM.Calcular_Condicion_Fisica(100.0, 100.0, 100.0), 100.0, 0.001,
		"Todo al máximo debe dar 100")
	assert_almost_eq(SIM.Calcular_Condicion_Fisica(0.0, 0.0, 0.0), 0.0, 0.001,
		"Todo a cero debe dar 0")
	assert_almost_eq(SIM.Calcular_Condicion_Fisica(105.0, 120.0, 130.0), 100.0, 0.001,
		"Los valores por encima de 100 deben quedar clampeados")


func test_condicion_fisica_ponderada() -> void:
	# 80*0.45 + 60*0.35 + 40*0.20 = 36 + 21 + 8 = 65
	assert_almost_eq(SIM.Calcular_Condicion_Fisica(80.0, 60.0, 40.0), 65.0, 0.001)


func test_innata_futbol_con_habilidades_reales() -> void:
	# [0]=Deporte 100, [4]=Liderazgo 100, [6]=Sangre fría 100.
	var habilidades: Array = [100, 0, 0, 0, 100, 0, 100]
	assert_almost_eq(SIM.Calcular_Innata_Futbol(habilidades), 100.0, 0.001)
	# Los tres pesos: 50 + 25 + 25.
	var solo_deporte: Array = [100, 0, 0, 0, 0, 0, 0]
	assert_almost_eq(SIM.Calcular_Innata_Futbol(solo_deporte), 50.0, 0.001)
	assert_almost_eq(SIM.Calcular_Innata_Futbol([]), 50.0, 0.001,
		"Un array vacío usa 50 por defecto")
	var corto: Array = [100]
	assert_almost_eq(SIM.Calcular_Innata_Futbol(corto), 75.0, 0.001,
		"Los índices ausentes usan 50 por defecto")


# ------------------------------------------------------------------
# Convocatoria
# ------------------------------------------------------------------

func test_evaluar_convocatoria_convocado() -> void:
	var resultado: Dictionary = SIM.Evaluar_Convocatoria(80.0, 80.0, 80.0, 80.0, false)
	assert_true(bool(resultado.get("convocado", false)), "Índice 80 debe convocar")
	assert_almost_eq(float(resultado.get("indice", 0.0)), 80.0, 0.01)
	assert_eq(str(resultado.get("motivo", "")), "")


func test_evaluar_convocatoria_bloqueos_duros() -> void:
	var lesionado: Dictionary = SIM.Evaluar_Convocatoria(100.0, 100.0, 100.0, 100.0, true)
	assert_false(bool(lesionado.get("convocado", true)), "Lesionado nunca es convocado")
	assert_eq(str(lesionado.get("motivo", "")), "lesionado")

	var salud_baja: Dictionary = SIM.Evaluar_Convocatoria(100.0, 100.0, 29.0, 100.0, false)
	assert_false(bool(salud_baja.get("convocado", true)), "Salud < 30 bloquea")
	assert_eq(str(salud_baja.get("motivo", "")), "salud_baja")

	var relacion_baja: Dictionary = SIM.Evaluar_Convocatoria(24.0, 100.0, 100.0, 100.0, false)
	assert_false(bool(relacion_baja.get("convocado", true)), "Relación < 25 bloquea")
	assert_eq(str(relacion_baja.get("motivo", "")), "relacion_baja")


func test_evaluar_convocatoria_indice_bajo() -> void:
	# 40*0.55 + 45*0.30 + 40*0.15 = 22 + 13.5 + 6 = 41.5
	var resultado: Dictionary = SIM.Evaluar_Convocatoria(40.0, 45.0, 80.0, 40.0, false)
	assert_false(bool(resultado.get("convocado", true)), "Índice 41.5 no debe convocar")
	assert_eq(str(resultado.get("motivo", "")), "indice_bajo")


# ------------------------------------------------------------------
# Puntuación y penaltis
# ------------------------------------------------------------------

func test_puntuacion_partido_normal() -> void:
	# 50*0.50 + 50*0.30 + 50*0.20 = 50.
	var valor: float = SIM.Calcular_Puntuacion_Partido(50.0, 50.0, 50.0, 0.0, false)
	assert_almost_eq(valor, 50.0, 0.001)
	var con_variacion: float = SIM.Calcular_Puntuacion_Partido(50.0, 50.0, 50.0, 0.0, false, 7.0)
	assert_almost_eq(con_variacion, 57.0, 0.001)


func test_sangre_fria_pesa_mas_en_partido_decisivo() -> void:
	var normal_fria: float = SIM.Calcular_Puntuacion_Partido(50.0, 50.0, 50.0, 100.0, false)
	var normal_serena: float = SIM.Calcular_Puntuacion_Partido(50.0, 50.0, 50.0, 0.0, false)
	assert_almost_eq(normal_fria, normal_serena, 0.001,
		"En un partido normal la sangre fría no puntúa")

	var decisivo_fria: float = SIM.Calcular_Puntuacion_Partido(50.0, 50.0, 50.0, 100.0, true)
	var decisivo_serena: float = SIM.Calcular_Puntuacion_Partido(50.0, 50.0, 50.0, 0.0, true)
	assert_almost_eq(decisivo_fria - decisivo_serena, 20.0, 0.001,
		"En el decisivo la sangre fría aporta 20 puntos de diferencia")


func test_puntuacion_clampeada() -> void:
	assert_almost_eq(SIM.Calcular_Puntuacion_Partido(100.0, 100.0, 100.0, 100.0, true, 50.0),
		100.0, 0.001)
	assert_almost_eq(SIM.Calcular_Puntuacion_Partido(0.0, 0.0, 0.0, 0.0, false, -50.0),
		0.0, 0.001)


func test_penaltis_sangre_fria_dominante() -> void:
	# Sangre fría 100 + Deporte 100 => probabilidad 0.90.
	assert_true(SIM.Resolver_Tanda_Penaltis(100.0, 100.0, 0.10))
	assert_false(SIM.Resolver_Tanda_Penaltis(100.0, 100.0, 0.95),
		"Con tirada 0.95 pierde incluso el mejor lanzador")
	# Sangre fría 0 + Deporte 0 => probabilidad 0.25.
	assert_true(SIM.Resolver_Tanda_Penaltis(0.0, 0.0, 0.20))
	assert_false(SIM.Resolver_Tanda_Penaltis(0.0, 0.0, 0.30))
	# La misma tirada gana con sangre fría alta y pierde con baja.
	assert_true(SIM.Resolver_Tanda_Penaltis(100.0, 0.0, 0.50))
	assert_false(SIM.Resolver_Tanda_Penaltis(0.0, 0.0, 0.50))


func test_partido_liga_empate_decisivo_resuelve_penaltis() -> void:
	var gana: Dictionary = SIM.Simular_Partido_Liga(50.0, 50.0, true, 100.0, 100.0, 0.10)
	assert_eq(str(gana.get("resultado", "")), "Victoria_Penaltis")
	assert_true(bool(gana.get("gano_penaltis", false)))

	var pierde: Dictionary = SIM.Simular_Partido_Liga(50.0, 50.0, true, 100.0, 100.0, 0.95)
	assert_eq(str(pierde.get("resultado", "")), "Derrota_Penaltis")
	assert_false(bool(pierde.get("gano_penaltis", true)))


func test_partido_liga_victoria_goles_y_primas() -> void:
	var resultado: Dictionary = SIM.Simular_Partido_Liga(80.0, 45.0, false)
	assert_eq(str(resultado.get("resultado", "")), "Victoria")
	# 1 + int((80-45)/12) = 1 + 2 = 3.
	assert_eq(int(resultado.get("goles", 0)), 3)
	assert_eq(float(resultado.get("delta_relacion", 0.0)), 4.0)
	assert_true(int(resultado.get("asistencias", 0)) >= 1)


# ------------------------------------------------------------------
# Playoff y Modo Rápido
# ------------------------------------------------------------------

func test_playoff_primero_asciende() -> void:
	var resultado: Dictionary = SIM.Resolver_Playoff_Domingo(1, true, 4)
	assert_eq(int(resultado.get("cambio_division", 99)), -1)
	assert_false(bool(resultado.get("despedido", true)))
	assert_false(bool(resultado.get("campeon_superliga", true)))


func test_playoff_segundo_mantiene() -> void:
	var resultado: Dictionary = SIM.Resolver_Playoff_Domingo(2, false, 4)
	assert_eq(int(resultado.get("cambio_division", 99)), 0)
	assert_false(bool(resultado.get("despedido", true)))


func test_playoff_tercero_mantiene() -> void:
	var resultado: Dictionary = SIM.Resolver_Playoff_Domingo(3, true, 4)
	assert_eq(int(resultado.get("cambio_division", 99)), 0)
	assert_false(bool(resultado.get("despedido", true)))


func test_playoff_cuarto_desciende_o_despide() -> void:
	var desciende: Dictionary = SIM.Resolver_Playoff_Domingo(4, false, 3)
	assert_eq(int(desciende.get("cambio_division", 99)), 1)
	assert_false(bool(desciende.get("despedido", true)))

	var despide: Dictionary = SIM.Resolver_Playoff_Domingo(4, false, 4)
	assert_true(bool(despide.get("despedido", false)), "En 3ª División el 4º queda despedido")
	assert_eq(int(despide.get("cambio_division", 99)), 0)


func test_playoff_superliga_campeon() -> void:
	var resultado: Dictionary = SIM.Resolver_Playoff_Domingo(1, true, 1)
	assert_true(bool(resultado.get("campeon_superliga", false)))
	assert_eq(int(resultado.get("cambio_division", 99)), 0)


func test_partido_rapido_resultados() -> void:
	var asciende: Dictionary = SIM.Simular_Partido_Rapido(50.0, 4)
	assert_eq(str(asciende.get("resultado", "")), "Victoria")
	assert_eq(int(asciende.get("cambio_division", 99)), -1)

	var mantiene: Dictionary = SIM.Simular_Partido_Rapido(40.0, 4)
	assert_eq(str(mantiene.get("resultado", "")), "Empate")
	assert_eq(int(mantiene.get("cambio_division", 99)), 0)

	var despedido: Dictionary = SIM.Simular_Partido_Rapido(20.0, 4)
	assert_eq(str(despedido.get("resultado", "")), "Derrota")
	assert_true(bool(despedido.get("despedido", false)))

	var desciende: Dictionary = SIM.Simular_Partido_Rapido(20.0, 3)
	assert_eq(int(desciende.get("cambio_division", 99)), 1)

	var campeon: Dictionary = SIM.Simular_Partido_Rapido(95.0, 1)
	assert_true(bool(campeon.get("campeon_superliga", false)))


func test_riesgo_lesion() -> void:
	assert_true(SIM.Comprobar_Riesgo_Lesion(20.0, 50.0, 0.10))
	assert_true(SIM.Comprobar_Riesgo_Lesion(50.0, 20.0, 0.10))
	assert_false(SIM.Comprobar_Riesgo_Lesion(20.0, 50.0, 0.30))
	assert_false(SIM.Comprobar_Riesgo_Lesion(80.0, 80.0, 0.0),
		"Con buena condición no hay riesgo")


# ------------------------------------------------------------------
# Calendario
# ------------------------------------------------------------------

func test_calendario_entrenamientos_normal() -> void:
	var tercera: Dictionary = CAL.Obtener_Horario_Entrenamiento(4, false)
	assert_eq(int(tercera.get("inicio", -1)), 19 * 60, "3ª División entrena a las 19:00")
	assert_eq(int(tercera.get("duracion", -1)), 120)
	assert_eq(tercera.get("dias", []), [1, 3], "Martes y Jueves")

	var profesional: Dictionary = CAL.Obtener_Horario_Entrenamiento(2, false)
	assert_eq(int(profesional.get("inicio", -1)), 10 * 60, "División profesional entrena a las 10:00")
	assert_eq(int(profesional.get("duracion", -1)), 120)


func test_calendario_partidos_normal() -> void:
	var horarios: Array = CAL.Obtener_Horarios_Partidos(false)
	assert_eq(horarios, [600, 780, 960, 1140], "Domingos a las 10:00, 13:00, 16:00 y 19:00")
	assert_eq(int(CAL.Obtener_Indice_Jornada(600, false)), 0)
	assert_eq(int(CAL.Obtener_Indice_Jornada(1140, false)), 3)


func test_calendario_modo_rapido() -> void:
	var entreno: Dictionary = CAL.Obtener_Horario_Entrenamiento(4, true)
	assert_eq(int(entreno.get("inicio", -1)), 18 * 60 + 30)
	assert_eq(int(entreno.get("duracion", -1)), 45, "En rápido el entrenamiento dura 45 min")
	var profesional: Dictionary = CAL.Obtener_Horario_Entrenamiento(3, true)
	assert_eq(int(profesional.get("inicio", -1)), 10 * 60)
	assert_eq(int(profesional.get("duracion", -1)), 45)

	var horarios: Array = CAL.Obtener_Horarios_Partidos(true)
	assert_eq(horarios, [20 * 60 + 30], "Partido decisivo diario a las 20:30")


# ------------------------------------------------------------------
# Persistencia
# ------------------------------------------------------------------

func test_game_data_incluye_carrera_futbol() -> void:
	var datos: Dictionary = Guardar_Variables_Dinamicas.game_data_func()
	assert_true(datos.has("Carrera_Futbol"), "El save dinámico debe incluir Carrera_Futbol")
	assert_true(datos["Carrera_Futbol"] is Dictionary)
	assert_true((datos["Carrera_Futbol"] as Dictionary).has("Liga_Domingo"))


func test_normalizar_carrera_futbol_save_antiguo() -> void:
	var normalizado: Dictionary = Guardar_Variables_Dinamicas._Normalizar_Carrera_Futbol({})
	assert_false(bool(normalizado.get("Activo", true)))
	assert_eq(int(normalizado.get("Division", 0)), 4)
	assert_true(normalizado.has("Entrenamientos_Asistencia"))
	assert_true(normalizado.has("Liga_Domingo"))
	var liga: Dictionary = normalizado.get("Liga_Domingo", {})
	assert_eq(int(liga.get("Jornada_Actual", -1)), 0)
	assert_eq((liga.get("Puntos_Rivales", []) as Array).size(), 3)
	assert_eq((liga.get("Medias_Rivales", []) as Array).size(), 3)


func test_normalizar_carrera_futbol_datos_parciales() -> void:
	var parcial: Dictionary = {
		"Activo": true,
		"Division": 2,
		"Relacion_Entrenador": 77.5,
		"Liga_Domingo": {
			"Jornada_Actual": 2,
			"Puntos_Jugador": 6,
			"Puntos_Rivales": [3, 1]
		}
	}
	var normalizado: Dictionary = Guardar_Variables_Dinamicas._Normalizar_Carrera_Futbol(parcial)
	assert_true(bool(normalizado.get("Activo", false)))
	assert_eq(int(normalizado.get("Division", 0)), 2)
	assert_almost_eq(float(normalizado.get("Relacion_Entrenador", 0.0)), 77.5, 0.001)
	var liga: Dictionary = normalizado.get("Liga_Domingo", {})
	assert_eq(int(liga.get("Jornada_Actual", -1)), 2)
	assert_eq(liga.get("Puntos_Rivales", []), [3, 1, 0],
		"Los arrays incompletos se completan con ceros")


func test_cargar_save_antiguo_sin_carrera_futbol() -> void:
	var backup: Dictionary = _Backup_Globales()
	var ruta: String = "user://test_futbol_save_antiguo.dat"
	Guardar_Variables_Dinamicas.save_path = ruta
	var save_file := FileAccess.open(ruta, FileAccess.WRITE)
	assert_not_null(save_file, "Debe poder crearse el save de prueba")
	if save_file == null:
		_Restaurar_Globales(backup)
		return
	save_file.store_var({
		"Matriz_Jugador": [["", ""], ["", ""]],
		"Progreso": [10, 20, 30],
		"Necesidades_Basicas": [50, 50, 50, 50, 50],
		"Dinero": 100,
		"Minute": 0,
		"Minute_Day": 0,
		"Minute_Minute": 0
	})
	save_file = null

	Guardar_Variables_Dinamicas.load_game()
	var activo: bool = bool(Variables_Dinamicas.Carrera_Futbol.get("Activo", true))
	var tiene_liga: bool = Variables_Dinamicas.Carrera_Futbol.get("Liga_Domingo", {}) is Dictionary

	_Restaurar_Globales(backup)
	if FileAccess.file_exists(ProjectSettings.globalize_path(ruta)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))

	assert_false(activo, "Un save antiguo sin Carrera_Futbol debe cargar la carrera inactiva")
	assert_true(tiene_liga, "La normalización debe crear Liga_Domingo con valores por defecto")


# ------------------------------------------------------------------
# Catálogo y prioridades
# ------------------------------------------------------------------

func test_catalogo_futbol_prioridades_y_pool() -> void:
	var entreno = Variables_Estaticas.Catalogo_Actividades.get("Entrenamiento_Futbol", null)
	var partido = Variables_Estaticas.Catalogo_Actividades.get("Partido_Futbol", null)
	assert_not_null(entreno)
	assert_not_null(partido)
	assert_true(entreno is Actividad_Fija, "El entrenamiento debe ser P2")
	assert_eq(entreno.Obtener_Prioridad(), 2)
	assert_true(partido is Actividad_Partido, "El partido debe usar Actividad_Partido")
	assert_eq(partido.Obtener_Prioridad(), 3)
	assert_false(Variables_Estaticas.Actividades.has(entreno),
		"El entrenamiento no pertenece al pool aleatorio")
	assert_false(Variables_Estaticas.Actividades.has(partido),
		"El partido no pertenece al pool aleatorio")
	assert_true(Variables_Estaticas.Estados_Temporales.has("Lesion_Deportiva"))


# ------------------------------------------------------------------
# Integración: fichaje, programación en matriz y ticks
# ------------------------------------------------------------------

func _Backup_Globales() -> Dictionary:
	return {
		"matriz": Variables_Dinamicas.Matriz_Jugador,
		"matriz_sucia": Variables_Dinamicas.Matriz_Sucia,
		"progreso": Variables_Dinamicas.Progreso,
		"necesidades": Variables_Dinamicas.Necesidades_Basicas,
		"carrera": Variables_Dinamicas.Carrera_Futbol,
		"mensajes": Variables_Dinamicas.Mensajes,
		"minute_day": Variables_Dinamicas.Minute_Day,
		"minute_minute": Variables_Dinamicas.Minute_Minute,
		"minute": Variables_Dinamicas.Minute,
		"estados": Variables_Dinamicas.Estados_Temporales,
		"dinero": Variables_Dinamicas.Dinero,
		"trabajo": Variables_Dinamicas.Trabajo_Actual,
		"save_path": Guardar_Variables_Dinamicas.save_path,
		"modo_rapido": Variables_Estaticas.Modo_Rapido,
		"habilidades": Variables_Estaticas.Habilidades
	}


func _Restaurar_Globales(backup: Dictionary) -> void:
	Variables_Dinamicas.Matriz_Jugador = backup["matriz"]
	Variables_Dinamicas.Matriz_Sucia = backup["matriz_sucia"]
	Variables_Dinamicas.Progreso = backup["progreso"]
	Variables_Dinamicas.Necesidades_Basicas = backup["necesidades"]
	Variables_Dinamicas.Carrera_Futbol = backup["carrera"]
	Variables_Dinamicas.Mensajes = backup["mensajes"]
	Variables_Dinamicas.Minute_Day = backup["minute_day"]
	Variables_Dinamicas.Minute_Minute = backup["minute_minute"]
	Variables_Dinamicas.Minute = backup["minute"]
	Variables_Dinamicas.Estados_Temporales = backup["estados"]
	Variables_Dinamicas.Dinero = backup["dinero"]
	Variables_Dinamicas.Trabajo_Actual = backup["trabajo"]
	Guardar_Variables_Dinamicas.save_path = backup["save_path"]
	Guardar_Variables_Dinamicas._rle_cache = {}
	Variables_Estaticas.Modo_Rapido = backup["modo_rapido"]
	Variables_Estaticas.Habilidades = backup["habilidades"]


func _Matriz_Vacia() -> Array:
	var matriz: Array = []
	for i in range(1440):
		var fila: Array = []
		fila.resize(574)
		fila.fill("")
		matriz.append(fila)
	return matriz


func test_integracion_fichaje_entrenamiento_y_partido() -> void:
	var backup: Dictionary = _Backup_Globales()
	Guardar_Variables_Dinamicas.save_path = "user://test_futbol_tmp.dat"
	Variables_Dinamicas.Matriz_Jugador = _Matriz_Vacia()
	Variables_Dinamicas.Progreso = [30, 1, 1]
	Variables_Dinamicas.Necesidades_Basicas = [100, 100, 100, 100, 100]
	Variables_Dinamicas.Estados_Temporales = {}
	Variables_Dinamicas.Carrera_Futbol = Variables_Dinamicas.Carrera_Futbol_Por_Defecto()
	Variables_Dinamicas.Minute_Day = 0
	Variables_Dinamicas.Minute_Minute = 0
	Variables_Dinamicas.Minute = 0
	Variables_Dinamicas.Dinero = 0
	Variables_Dinamicas.Mensajes = []
	Variables_Dinamicas.Trabajo_Actual = null
	Variables_Estaticas.Modo_Rapido = false

	var fichaje: Dictionary = Sistema_Futbol.Fichar(false)
	var activo: bool = bool(fichaje.get("fichado", false)) and Sistema_Futbol.Carrera_Activa()
	var celda_entreno = Variables_Dinamicas.Matriz_Jugador[1140][1]
	var celda_partido = Variables_Dinamicas.Matriz_Jugador[600][6]
	var entreno_programado: bool = celda_entreno is Actividad \
		and celda_entreno.nombre == "Entrenamiento_Futbol"
	var partido_programado: bool = celda_partido is Actividad \
		and celda_partido.nombre == "Partido_Futbol"

	Variables_Dinamicas.Minute_Day = 1
	Variables_Dinamicas.Minute_Minute = 1140
	Sistema_Futbol.Tick_Minuto()
	var entreno_en_curso: bool = bool(
		Variables_Dinamicas.Carrera_Futbol.get("Entrenamiento_En_Curso", false))
	Variables_Dinamicas.Minute_Minute = 1260
	Sistema_Futbol.Tick_Minuto()
	var relacion_tras_entreno: float = float(
		Variables_Dinamicas.Carrera_Futbol.get("Relacion_Entrenador", 0.0))

	Variables_Dinamicas.Minute_Day = 6
	Variables_Dinamicas.Minute_Minute = 600
	Sistema_Futbol.Tick_Minuto()
	var partido_en_curso: bool = bool(
		Variables_Dinamicas.Carrera_Futbol.get("Partido_En_Curso", false))
	Variables_Dinamicas.Minute_Minute = 660
	Sistema_Futbol.Tick_Minuto()
	var partidos_jugados: int = int(
		Variables_Dinamicas.Carrera_Futbol.get("Partidos_Jugados", 0))

	_Restaurar_Globales(backup)
	var ruta_tmp: String = ProjectSettings.globalize_path("user://test_futbol_tmp.dat")
	if FileAccess.file_exists(ruta_tmp):
		DirAccess.remove_absolute(ruta_tmp)

	assert_true(activo, "Fichar debe activar la carrera")
	assert_true(entreno_programado, "El entrenamiento del martes debe estar en la matriz (19:00)")
	assert_true(partido_programado, "El partido del domingo debe estar en la matriz (10:00)")
	assert_true(entreno_en_curso, "El tick del inicio del entrenamiento debe marcarlo en curso")
	assert_almost_eq(relacion_tras_entreno, 55.0, 0.1,
		"Entrenar con condición 100 suma +5 de relación")
	assert_true(partido_en_curso, "El tick del inicio del partido debe marcarlo en curso")
	assert_eq(partidos_jugados, 1, "El partido debe contabilizarse al terminar")


func test_integracion_modo_rapido_asciende() -> void:
	var backup: Dictionary = _Backup_Globales()
	Guardar_Variables_Dinamicas.save_path = "user://test_futbol_rapido_tmp.dat"
	Variables_Dinamicas.Matriz_Jugador = _Matriz_Vacia()
	Variables_Dinamicas.Progreso = [100, 1, 1]
	Variables_Dinamicas.Necesidades_Basicas = [100, 100, 100, 100, 100]
	Variables_Dinamicas.Estados_Temporales = {}
	Variables_Dinamicas.Carrera_Futbol = Variables_Dinamicas.Carrera_Futbol_Por_Defecto()
	Variables_Dinamicas.Minute_Day = 0
	Variables_Dinamicas.Minute_Minute = 0
	Variables_Dinamicas.Minute = 0
	Variables_Dinamicas.Dinero = 0
	Variables_Dinamicas.Mensajes = []
	Variables_Dinamicas.Trabajo_Actual = null
	Variables_Estaticas.Habilidades = [100, 0, 0, 0, 100, 0, 100]
	Variables_Estaticas.Modo_Rapido = true

	var fichaje: Dictionary = Sistema_Futbol.Fichar(false)
	var activo: bool = bool(fichaje.get("fichado", false)) and Sistema_Futbol.Carrera_Activa()
	var celda_entreno = Variables_Dinamicas.Matriz_Jugador[1110][0]
	var celda_partido = Variables_Dinamicas.Matriz_Jugador[1230][0]
	var entreno_programado: bool = celda_entreno is Actividad \
		and celda_entreno.nombre == "Entrenamiento_Futbol"
	var partido_programado: bool = celda_partido is Actividad \
		and celda_partido.nombre == "Partido_Futbol"

	Variables_Dinamicas.Carrera_Futbol["Relacion_Entrenador"] = 100.0
	Variables_Dinamicas.Minute_Minute = 1230
	Sistema_Futbol.Tick_Minuto()
	var partido_en_curso: bool = bool(
		Variables_Dinamicas.Carrera_Futbol.get("Partido_En_Curso", false))
	Variables_Dinamicas.Minute_Minute = 1290
	Sistema_Futbol.Tick_Minuto()
	var division_final: int = int(Variables_Dinamicas.Carrera_Futbol.get("Division", 0))
	var salario_final: int = int(Variables_Dinamicas.Carrera_Futbol.get("Salario_Semanal", 0))
	var temporadas: int = int(Variables_Dinamicas.Carrera_Futbol.get("Temporadas_Jugadas", 0))

	_Restaurar_Globales(backup)
	var ruta_tmp: String = ProjectSettings.globalize_path("user://test_futbol_rapido_tmp.dat")
	if FileAccess.file_exists(ruta_tmp):
		DirAccess.remove_absolute(ruta_tmp)

	assert_true(activo, "Fichar debe activar la carrera en Modo Rápido")
	assert_true(entreno_programado, "En rápido el entreno de 3ª debe estar a las 18:30")
	assert_true(partido_programado, "En rápido el partido debe estar a las 20:30")
	assert_true(partido_en_curso, "El partido diario debe iniciarse a las 20:30")
	assert_eq(division_final, 3, "Ganar en 3ª División debe ascender a 2ª")
	assert_eq(salario_final, 600, "El salario debe actualizarse al de 2ª División")
	assert_eq(temporadas, 1, "Cada partido diario cuenta como una temporada")


func test_fichaje_conflicto_con_trabajo() -> void:
	var backup: Dictionary = _Backup_Globales()
	Guardar_Variables_Dinamicas.save_path = "user://test_futbol_conflicto_fichaje.dat"
	Variables_Dinamicas.Matriz_Jugador = _Matriz_Vacia()
	Variables_Dinamicas.Progreso = [30, 1, 1]
	Variables_Dinamicas.Necesidades_Basicas = [100, 100, 100, 100, 100]
	Variables_Dinamicas.Carrera_Futbol = Variables_Dinamicas.Carrera_Futbol_Por_Defecto()
	Variables_Dinamicas.Minute_Day = 0
	Variables_Dinamicas.Minute_Minute = 0
	Variables_Dinamicas.Minute = 0
	Variables_Dinamicas.Dinero = 0
	Variables_Dinamicas.Mensajes = []
	Variables_Estaticas.Habilidades = [70, 50, 40, 60, 65, 50, 55]
	Variables_Estaticas.Modo_Rapido = false
	Variables_Dinamicas.Trabajo_Actual = Variables_Estaticas.Catalogo_Actividades[
		"Trabajar_De_Cocinero_Partida"]

	var sin_forzar: Dictionary = Sistema_Futbol.Fichar(false)
	var bloqueado: bool = not bool(sin_forzar.get("fichado", true)) \
		and bool(sin_forzar.get("requiere_conflicto", false)) \
		and Variables_Dinamicas.Trabajo_Actual != null \
		and not Sistema_Futbol.Carrera_Activa()

	var forzado: Dictionary = Sistema_Futbol.Fichar(true)
	var fichado: bool = bool(forzado.get("fichado", false)) \
		and Variables_Dinamicas.Trabajo_Actual == null \
		and Sistema_Futbol.Carrera_Activa()

	_Restaurar_Globales(backup)
	var ruta_tmp: String = ProjectSettings.globalize_path("user://test_futbol_conflicto_fichaje.dat")
	if FileAccess.file_exists(ruta_tmp):
		DirAccess.remove_absolute(ruta_tmp)

	assert_true(bloqueado, "Fichar con un trabajo solapado debe pedir confirmación")
	assert_true(fichado, "Aceptar el fútbol debe dejar el trabajo y activar la carrera")


func test_resolver_conflicto_ascenso() -> void:
	var backup: Dictionary = _Backup_Globales()
	Guardar_Variables_Dinamicas.save_path = "user://test_futbol_conflicto_ascenso.dat"
	Variables_Dinamicas.Matriz_Jugador = _Matriz_Vacia()
	Variables_Dinamicas.Progreso = [40, 1, 1]
	Variables_Dinamicas.Necesidades_Basicas = [100, 100, 100, 100, 100]
	Variables_Dinamicas.Carrera_Futbol = Variables_Dinamicas.Carrera_Futbol_Por_Defecto()
	Variables_Dinamicas.Minute_Day = 0
	Variables_Dinamicas.Minute_Minute = 0
	Variables_Dinamicas.Minute = 0
	Variables_Dinamicas.Trabajo_Actual = Variables_Estaticas.Catalogo_Actividades[
		"Trabajar_En_Comida_Rapida"]
	Variables_Estaticas.Modo_Rapido = false
	var est: Dictionary = Variables_Dinamicas.Carrera_Futbol
	est["Activo"] = true
	est["Division"] = 4
	est["Salario_Semanal"] = 150
	est["Relacion_Entrenador"] = 50.0
	est["Estado_Temporada"] = "Ascenso_Pendiente"
	est["Conflicto_Ascenso_Pendiente"] = true
	est["Division_Ascenso_Pendiente"] = 3

	Sistema_Futbol.Resolver_Conflicto_Ascenso(false)
	var rechazo: bool = int(est.get("Division", 0)) == 4 \
		and int(est.get("Salario_Semanal", 0)) == 150 \
		and Variables_Dinamicas.Trabajo_Actual != null \
		and not bool(est.get("Conflicto_Ascenso_Pendiente", true)) \
		and str(est.get("Estado_Temporada", "")) == "Mantiene"

	est["Conflicto_Ascenso_Pendiente"] = true
	est["Division_Ascenso_Pendiente"] = 3
	Sistema_Futbol.Resolver_Conflicto_Ascenso(true)
	var aceptado: bool = int(est.get("Division", 0)) == 3 \
		and int(est.get("Salario_Semanal", 0)) == 600 \
		and Variables_Dinamicas.Trabajo_Actual == null \
		and str(est.get("Estado_Temporada", "")) == "Ascendido"

	_Restaurar_Globales(backup)
	var ruta_tmp: String = ProjectSettings.globalize_path("user://test_futbol_conflicto_ascenso.dat")
	if FileAccess.file_exists(ruta_tmp):
		DirAccess.remove_absolute(ruta_tmp)

	assert_true(rechazo, "Mantener el trabajo debe rechazar el ascenso y conservar la división")
	assert_true(aceptado, "Seguir con el fútbol debe dejar el trabajo y ascender con nuevo salario")


# ------------------------------------------------------------------
# Jerarquía de prioridades y conflictos horarios
# ------------------------------------------------------------------

func test_jerarquia_futbol_en_matriz() -> void:
	var backup: Dictionary = _Backup_Globales()
	Variables_Dinamicas.Matriz_Jugador = _Matriz_Vacia()
	var entreno = Variables_Estaticas.Catalogo_Actividades["Entrenamiento_Futbol"]
	var partido = Variables_Estaticas.Catalogo_Actividades["Partido_Futbol"]
	var temporal = Variables_Estaticas.Catalogo_Actividades["Dormir"]

	Variables_Dinamicas.Matriz_Jugador[500][0] = temporal
	var p2_sobre_p1: bool = Actividades.Crear_Actividad(0, 500, entreno)

	Variables_Dinamicas.Matriz_Jugador[501][0] = entreno
	var p1_sobre_p2: bool = Actividades.Crear_Actividad(0, 501, temporal)
	var celda_501 = Variables_Dinamicas.Matriz_Jugador[501][0]

	Variables_Dinamicas.Matriz_Jugador[502][0] = partido
	var p2_sobre_p3: bool = Actividades.Crear_Actividad(0, 502, entreno)
	var celda_502 = Variables_Dinamicas.Matriz_Jugador[502][0]

	Variables_Dinamicas.Matriz_Jugador[503][0] = entreno
	var p3_sobre_p2: bool = Actividades.Crear_Actividad(0, 503, partido)

	_Restaurar_Globales(backup)

	assert_true(p2_sobre_p1, "P2 debe poder sustituir una actividad temporal P1")
	assert_false(p1_sobre_p2, "P1 no debe poder pisar un entrenamiento P2")
	assert_eq(celda_501, entreno, "La celda P2 debe conservarse")
	assert_false(p2_sobre_p3, "P2 no debe poder pisar un partido P3")
	assert_eq(celda_502, partido, "La celda P3 debe conservarse")
	assert_true(p3_sobre_p2, "P3 sí puede sustituir un entrenamiento P2")


func test_conflicto_horario_trabajo_futbol() -> void:
	var backup: Dictionary = _Backup_Globales()
	var comida_rapida = Variables_Estaticas.Catalogo_Actividades["Trabajar_En_Comida_Rapida"]
	var cocinero = Variables_Estaticas.Catalogo_Actividades["Trabajar_De_Cocinero_Partida"]

	Variables_Estaticas.Modo_Rapido = false
	var tercera_sin_conflicto: bool = not Sistema_Futbol.Trabajo_Solapa_Con_Futbol(comida_rapida, 4)
	var tercera_conflicto: bool = Sistema_Futbol.Trabajo_Solapa_Con_Futbol(cocinero, 4)
	var profesional_conflicto: bool = Sistema_Futbol.Trabajo_Solapa_Con_Futbol(comida_rapida, 3)

	Variables_Estaticas.Modo_Rapido = true
	var rapido_tercera_conflicto: bool = Sistema_Futbol.Trabajo_Solapa_Con_Futbol(cocinero, 4)
	var rapido_tercera_sin_conflicto: bool = not Sistema_Futbol.Trabajo_Solapa_Con_Futbol(comida_rapida, 4)
	var rapido_profesional_conflicto: bool = Sistema_Futbol.Trabajo_Solapa_Con_Futbol(comida_rapida, 3)
	var rapido_profesional_sin_conflicto: bool = not Sistema_Futbol.Trabajo_Solapa_Con_Futbol(cocinero, 3)

	_Restaurar_Globales(backup)

	assert_true(tercera_sin_conflicto, "8-16 no solapa con el entreno de 3ª a las 19:00")
	assert_true(tercera_conflicto, "12-20 solapa con el entreno de 3ª a las 19:00")
	assert_true(profesional_conflicto, "8-16 solapa con el entreno profesional a las 10:00")
	assert_true(rapido_tercera_conflicto, "12-20 solapa con el entreno rápido de 3ª a las 18:30")
	assert_true(rapido_tercera_sin_conflicto, "8-16 no solapa con el entreno rápido de 3ª")
	assert_true(rapido_profesional_conflicto, "8-16 solapa con el entreno rápido profesional")
	assert_true(rapido_profesional_sin_conflicto, "12-20 no solapa con el entreno rápido profesional")


# ------------------------------------------------------------------
# UI
# ------------------------------------------------------------------

func test_panel_futbol_se_instancia_y_construye() -> void:
	var escena = load("res://Escenas/Escena_Principal/Panel_Futbol.tscn")
	assert_not_null(escena, "La escena Panel_Futbol.tscn debe existir")
	# Se monta igual que en Script_Principal: dentro de un CanvasLayer. Un
	# Control anclado directamente a un Node2D mide 0x0 en Godot.
	var capa := CanvasLayer.new()
	add_child_autofree(capa)
	var panel = escena.instantiate()
	capa.add_child(panel)
	await get_tree().process_frame
	assert_true(panel.is_inside_tree())
	assert_true(panel.get_child_count() > 0, "El panel debe construir su UI en _ready")
	assert_true(panel.size.x >= 700.0, "El panel debe ocupar el ancho de 720 px")
	assert_true(panel.size.y >= 1200.0, "El panel debe ocupar el alto visible")
