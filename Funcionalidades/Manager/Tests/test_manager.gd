extends GutTest

# Tests de «El Mánager» (Fase 2 — Modo Club Top Eleven).
# Cubren el ecosistema de 16 clubes y 288 futbolistas, calidad/estrellas,
# ascensos y descensos, jubilación y canteranos, mercado, partido de 90
# minutos, sustituciones, cansancio, entrenamiento, economía separada,
# recuperación en modo rápido y persistencia/retrocompatibilidad.

const RUTA_TEST_GUARDADO := "user://test_manager_save.dat"

var _estado_original: Dictionary
var _dinero_original: float
var _mensajes_original: Array
var _carrera_futbol_original: Dictionary
var _minute_original: int
var _day_original: int
var _minute_minute_original: int
var _progreso_original: Array
var _necesidades_originales: Array
var _ruta_guardado_original: String
var _seeded_rng: RandomNumberGenerator


func before_all() -> void:
	_estado_original = Variables_Dinamicas.Manager_Estado
	_dinero_original = Variables_Dinamicas.Dinero
	_mensajes_original = Variables_Dinamicas.Mensajes
	_carrera_futbol_original = Variables_Dinamicas.Carrera_Futbol
	_minute_original = Variables_Dinamicas.Minute
	_day_original = Variables_Dinamicas.Minute_Day
	_minute_minute_original = Variables_Dinamicas.Minute_Minute
	_progreso_original = Variables_Dinamicas.Progreso.duplicate(true)
	_necesidades_originales = Variables_Dinamicas.Necesidades_Basicas.duplicate(true)
	_ruta_guardado_original = Guardar_Variables_Dinamicas.save_path
	_seeded_rng = RandomNumberGenerator.new()
	_seeded_rng.seed = 20261124


func after_all() -> void:
	Variables_Dinamicas.Manager_Estado = _estado_original
	Variables_Dinamicas.Dinero = _dinero_original
	Variables_Dinamicas.Mensajes = _mensajes_original
	Variables_Dinamicas.Carrera_Futbol = _carrera_futbol_original
	Variables_Dinamicas.Minute = _minute_original
	Variables_Dinamicas.Minute_Day = _day_original
	Variables_Dinamicas.Minute_Minute = _minute_minute_original
	Variables_Dinamicas.Progreso = _progreso_original
	Variables_Dinamicas.Necesidades_Basicas = _necesidades_originales
	Guardar_Variables_Dinamicas.save_path = _ruta_guardado_original
	if FileAccess.file_exists(RUTA_TEST_GUARDADO):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(RUTA_TEST_GUARDADO))


func before_each() -> void:
	Variables_Dinamicas.Manager_Estado = Variables_Dinamicas.Manager_Estado_Por_Defecto()
	Variables_Dinamicas.Dinero = 5000
	Variables_Dinamicas.Mensajes = []
	Variables_Dinamicas.Progreso = [30, 30, 30]
	Variables_Dinamicas.Necesidades_Basicas = [70, 70, 70, 70, 70]
	Variables_Dinamicas.Minute = 29925540
	Variables_Dinamicas.Minute_Day = 1
	Variables_Dinamicas.Minute_Minute = 720
	Variables_Dinamicas.Carrera_Futbol = Variables_Dinamicas.Carrera_Futbol_Por_Defecto()


func _fundar_club_prueba() -> Dictionary:
	Variables_Dinamicas.Manager_Estado = Variables_Dinamicas.Manager_Estado_Por_Defecto()
	Variables_Dinamicas.Manager_Estado["Desbloqueado"] = true
	var resultado: Dictionary = Sistema_Manager.Fundar_Club(
		"Club de Prueba", ["#0f766e", "#ffffff"], 1)
	assert_true(bool(resultado.get("ok", false)), "El club de prueba debe fundarse")
	return Variables_Dinamicas.Manager_Estado


# ------------------------------------------------------------------
# 1. Ecosistema
# ------------------------------------------------------------------

func test_ecosistema_crea_16_clubes_y_288_futbolistas() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var eco: Dictionary = Simulador_Manager.Crear_Ecosistema(
		"Club Test", ["#0f766e", "#ffffff"], 1, rng)
	var clubes: Dictionary = eco["Clubes"]
	var divisiones: Dictionary = eco["Divisiones"]
	assert_eq(clubes.size(), 16, "Deben existir 16 clubes")
	assert_eq(divisiones["4"].size(), 4, "La 3ª Regional debe tener 4 clubes")
	assert_true((divisiones["4"] as Array).has("club_usr"), "El club del usuario debe estar en 3ª")
	var total_jugadores: int = 0
	for club_id in clubes.keys():
		var club: Dictionary = clubes[club_id]
		var plantilla: Array = club["plantilla"]
		assert_eq(plantilla.size(), 18, "Cada club debe tener 18 futbolistas")
		total_jugadores += plantilla.size()
		for jugador in plantilla:
			assert_true(jugador is Dictionary, "El jugador debe ser un diccionario")
			for atributo in Datos_Manager.ATRIBUTOS:
				var valor: float = Simulador_Manager._Atributo(jugador, str(atributo))
				assert_between(valor, 1.0, 99.0,
					"El atributo %s debe estar entre 1 y 99" % atributo)
			var edad: int = int(jugador["edad"])
			assert_between(float(edad), float(Datos_Manager.EDAD_MINIMA),
				float(Datos_Manager.EDAD_MAXIMA), "Edad entre 16 y 40")
			assert_between(float(jugador["energia"]), 0.0, 100.0, "Energía válida")
			assert_between(float(jugador["calidad"]), 1.0, 120.0, "Calidad válida")
	assert_eq(total_jugadores, 288, "15 clubes IA + el del usuario = 288 futbolistas")
	for division in range(1, 5):
		assert_eq((divisiones[str(division)] as Array).size(), 4,
			"Cada división debe tener 4 clubes")


func test_calidad_es_la_media_de_los_15_atributos() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	var jugador: Dictionary = Simulador_Manager.Crear_Jugador(
		"p_test", "MC", 2, rng, 24, 70.0)
	var suma: float = 0.0
	for atributo in Datos_Manager.ATRIBUTOS:
		suma += Simulador_Manager._Atributo(jugador, str(atributo))
	var media: float = suma / float(Datos_Manager.ATRIBUTOS.size())
	assert_almost_eq(Simulador_Manager.Calcular_Calidad(jugador), media, 0.05)
	assert_almost_eq(float(jugador["calidad"]), media, 0.05)


func test_estrellas_de_1_a_7() -> void:
	assert_eq(Simulador_Manager.Calcular_Estrellas(0.0), 1)
	assert_eq(Simulador_Manager.Calcular_Estrellas(19.9), 1)
	assert_eq(Simulador_Manager.Calcular_Estrellas(20.0), 2)
	assert_eq(Simulador_Manager.Calcular_Estrellas(39.9), 2)
	assert_eq(Simulador_Manager.Calcular_Estrellas(99.0), 5)
	assert_eq(Simulador_Manager.Calcular_Estrellas(120.0), 7)
	assert_eq(Simulador_Manager.Calcular_Estrellas(300.0), 7)


# ------------------------------------------------------------------
# 2. Ascensos y descensos Top Eleven
# ------------------------------------------------------------------

func test_ascenso_multiplica_todos_los_atributos_por_080() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 321
	var jugador: Dictionary = Simulador_Manager.Crear_Jugador("p_asc", "DFC", 3, rng, 25, 60.0)
	var antes: Dictionary = {}
	for atributo in Datos_Manager.ATRIBUTOS:
		antes[atributo] = Simulador_Manager._Atributo(jugador, str(atributo))
	var resultado: Array = Simulador_Manager.Aplicar_Ascenso([jugador])
	assert_eq(resultado.size(), 1)
	var ascendido: Dictionary = resultado[0]
	for atributo in Datos_Manager.ATRIBUTOS:
		var esperado: float = round(clampf(float(antes[atributo]) * 0.80,
			float(Datos_Manager.ATRIBUTO_MINIMO), float(Datos_Manager.ATRIBUTO_MAXIMO)))
		var actual: float = Simulador_Manager._Atributo(ascendido, str(atributo))
		assert_almost_eq(actual, esperado, 0.01,
			"El atributo %s debe bajar un 20%%" % atributo)
	assert_lt(float(ascendido["calidad"]), float(jugador["calidad"]),
		"La calidad debe bajar al ascender")


func test_descenso_multiplica_por_120_y_respeta_el_tope_99() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 654
	var jugador: Dictionary = Simulador_Manager.Crear_Jugador("p_desc", "DEL", 2, rng, 27, 80.0)
	for bloque in Datos_Manager.BLOQUES_ATRIBUTOS.keys():
		for atributo in Datos_Manager.BLOQUES_ATRIBUTOS[bloque]:
			jugador[bloque][atributo] = 90
	Simulador_Manager.Recalcular_Jugador(jugador)
	var resultado: Array = Simulador_Manager.Aplicar_Descenso([jugador])
	var descendido: Dictionary = resultado[0]
	for atributo in Datos_Manager.ATRIBUTOS:
		var valor: float = Simulador_Manager._Atributo(descendido, str(atributo))
		assert_almost_eq(valor, 99.0, 0.01,
			"El descenso sube un 20%% pero nunca supera 99")
	assert_gt(float(descendido["calidad"]), float(jugador["calidad"]),
		"La calidad debe subir al descender")


func test_resolver_ascensos_mantiene_4_clubes_por_division() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 999
	var eco: Dictionary = Simulador_Manager.Crear_Ecosistema(
		"Eco", ["#1d4ed8", "#ffffff"], 1, rng)
	var clubes: Dictionary = eco["Clubes"]
	var divisiones: Dictionary = eco["Divisiones"]
	var clasificaciones: Dictionary = {}
	for division in range(1, 5):
		var ids: Array = (divisiones[str(division)] as Array).duplicate()
		clasificaciones[str(division)] = ids
	var resolucion: Dictionary = Simulador_Manager.Resolver_Ascensos_Descensos(
		clubes, clasificaciones)
	var finales: Dictionary = resolucion["divisiones_finales"]
	assert_eq((resolucion["movimientos"] as Array).size(), 12,
		"2 ascensos y 2 descensos en cada una de las 3 fronteras (4 movimientos por frontera)")
	var conteo: Dictionary = {"1": 0, "2": 0, "3": 0, "4": 0}
	for club_id in finales.keys():
		var division: int = int(finales[club_id])
		conteo[str(division)] = int(conteo[str(division)]) + 1
	for division in range(1, 5):
		assert_eq(int(conteo[str(division)]), 4,
			"La división %d debe conservar 4 clubes" % division)


# ------------------------------------------------------------------
# 3. Jubilación y regeneración
# ------------------------------------------------------------------

func test_jubilacion_a_los_40_regenera_canterano_mismo_rol() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var club: Dictionary = Simulador_Manager.Crear_Club(
		"c_test", "Test", "Ciudad", ["#0f766e", "#ffffff"], 1, 4, true, rng)
	var plantilla: Array = club["plantilla"]
	# Edades controladas: solo el primero llega a 40 con este envejecimiento.
	for jugador in plantilla:
		jugador["edad"] = 30
	var veterano: Dictionary = plantilla[0]
	veterano["edad"] = 39
	var rol_veterano: String = str((veterano["roles"] as Array)[0])
	var id_veterano: String = str(veterano["id"])
	var resultado: Dictionary = Simulador_Manager.Envejecer_Plantilla(
		plantilla, "c_test", 4, rng)
	var nueva: Array = resultado["plantilla"]
	assert_eq(nueva.size(), 18, "La plantilla sigue teniendo 18 futbolistas")
	assert_eq((resultado["retirados"] as Array).size(), 1, "El veterano se retira")
	assert_eq((resultado["canteranos"] as Array).size(), 1, "Se genera un canterano")
	var encontrado_retirado: bool = false
	for jugador in nueva:
		if str(jugador.get("id", "")) == id_veterano:
			encontrado_retirado = true
	assert_false(encontrado_retirado, "El jugador retirado desaparece de la plantilla")
	var canterano: Dictionary = resultado["canteranos"][0]
	assert_between(float(canterano["edad"]), 16.0, 22.0, "El canterano tiene 16-22 años")
	assert_eq(str((canterano["roles"] as Array)[0]), rol_veterano,
		"El canterano ocupa el mismo rol posicional")
	assert_eq(int(canterano["edad"]), int(nueva[0]["edad"]),
		"El canterano está integrado en la plantilla")


func test_envejecimiento_normal_suma_un_anio() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 111
	var jugador: Dictionary = Simulador_Manager.Crear_Jugador(
		"p_edad", "MC", 4, rng, 22, 50.0)
	var resultado: Dictionary = Simulador_Manager.Envejecer_Plantilla(
		[jugador], "c", 4, rng)
	var envejecido: Dictionary = resultado["plantilla"][0]
	assert_eq(int(envejecido["edad"]), 23)


# ------------------------------------------------------------------
# 4. Mercado
# ------------------------------------------------------------------

func test_compra_bloqueada_con_18_jugadores() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 88
	var comprador: Dictionary = Simulador_Manager.Crear_Club(
		"c_comp", "Comprador", "Ciudad", ["#0f766e", "#ffffff"], 0, 4, true, rng)
	var vendedor: Dictionary = Simulador_Manager.Crear_Club(
		"c_vend", "Vendedor", "Ciudad", ["#d62828", "#ffffff"], 1, 4, false, rng)
	var jugador: Dictionary = vendedor["plantilla"][15]
	comprador["presupuesto"] = 1000000
	var evaluacion: Dictionary = Simulador_Manager.Evaluar_Oferta_Estandar(
		vendedor, jugador, int(jugador["valor_mercado"]) + 1000, comprador)
	assert_false(bool(evaluacion["aceptada"]), "No se puede comprar con 18 jugadores")
	assert_eq(str(evaluacion["motivo"]), "plantilla_completa")


func test_venta_bloqueada_con_14_jugadores() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 89
	var club: Dictionary = Simulador_Manager.Crear_Club(
		"c_venta", "Venta", "Ciudad", ["#0f766e", "#ffffff"], 0, 4, true, rng)
	var plantilla: Array = club["plantilla"]
	while plantilla.size() > 14:
		plantilla.pop_back()
	var resultado: Dictionary = Simulador_Manager.Puede_Vender(club)
	assert_false(bool(resultado["ok"]), "No se puede vender con 14")
	assert_eq(str(resultado["motivo"]), "plantilla_insuficiente")


func test_clausula_obligatoria_ignora_al_especialista_unico() -> void:
	_fundar_club_prueba()
	var club_usuario: Dictionary = Sistema_Manager.Club_Usuario()
	club_usuario["presupuesto"] = 2000000
	# La plantilla inicial ya tiene 18: hay que liberar una plaza para fichar.
	(club_usuario["plantilla"] as Array).pop_back()
	var clubes: Dictionary = Sistema_Manager.Obtener_Clubes()
	var vendedor_id: String = ""
	var portero: Dictionary = {}
	for club_id in clubes.keys():
		if str(club_id) == Sistema_Manager.Club_Usuario_Id():
			continue
		var club: Dictionary = clubes[club_id]
		var plantilla: Array = club["plantilla"]
		# Dejar al vendedor con un único portero para probar la obligatoriedad.
		for i in range(plantilla.size() - 1, -1, -1):
			var jugador: Dictionary = plantilla[i]
			if str((jugador["roles"] as Array)[0]) == "POR" and vendedor_id == "":
				portero = jugador
				vendedor_id = str(club_id)
			elif str((jugador["roles"] as Array)[0]) == "POR":
				plantilla.remove_at(i)
		if vendedor_id != "":
			break
	assert_false(portero.is_empty(), "Debe existir un portero en el mercado")
	var clausula: int = int(portero["clausula_rescision"])
	var presupuesto_antes: int = int(Sistema_Manager.Club_Usuario()["presupuesto"])
	var resultado: Dictionary = Sistema_Manager.Pagar_Clausula(str(portero["id"]))
	assert_true(bool(resultado.get("ok", false)), "La cláusula debe forzar el traspaso")
	assert_true(Sistema_Manager.Club_De_Jugador(str(portero["id"])) ==
		Sistema_Manager.Club_Usuario_Id(), "El jugador llega al club del usuario")
	assert_eq(int(Sistema_Manager.Club_Usuario()["presupuesto"]),
		presupuesto_antes - clausula, "Se paga el importe íntegro de la cláusula")
	assert_eq(int(Variables_Dinamicas.Dinero), 5000,
		"El pago sale de la caja del club, no del dinero personal del Sim")


func test_oferta_estandar_aceptada_si_supera_el_valor() -> void:
	_fundar_club_prueba()
	var club_usuario: Dictionary = Sistema_Manager.Club_Usuario()
	club_usuario["presupuesto"] = 3000000
	(club_usuario["plantilla"] as Array).pop_back()
	var clubes: Dictionary = Sistema_Manager.Obtener_Clubes()
	for club_id in clubes.keys():
		if str(club_id) == Sistema_Manager.Club_Usuario_Id():
			continue
		var club: Dictionary = clubes[club_id]
		for jugador in club["plantilla"]:
			var rol: String = str((jugador["roles"] as Array)[0])
			if Simulador_Manager.Contar_Rol(club["plantilla"], rol) > 1:
				var oferta: int = int(jugador["valor_mercado"]) + 5000
				var resultado: Dictionary = Sistema_Manager.Oferta_Estandar(
					str(jugador["id"]), oferta)
				assert_true(bool(resultado.get("ok", false)),
					"Una oferta por encima del valor debe aceptarse")
				assert_eq(Sistema_Manager.Club_De_Jugador(str(jugador["id"])),
					Sistema_Manager.Club_Usuario_Id(), "El jugador se transfiere")
				return
	fail_test("No se encontró un jugador vendible")


# ------------------------------------------------------------------
# 5. Partido de 90 minutos
# ------------------------------------------------------------------

func _crear_estado_partido() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	var local: Dictionary = Simulador_Manager.Crear_Club(
		"c_local", "Local", "Ciudad", ["#0f766e", "#ffffff"], 1, 3, false, rng)
	var visitante: Dictionary = Simulador_Manager.Crear_Club(
		"c_visit", "Visitante", "Ciudad", ["#d62828", "#ffffff"], 0, 3, false, rng)
	var estado: Dictionary = Simulador_Manager.Crear_Estado_Partido(local, visitante)
	estado["lado_usuario"] = "local"
	return estado


func test_partido_avanza_90_minutos_y_genera_eventos() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2027
	var estado: Dictionary = _crear_estado_partido()
	var seguridad: int = 0
	while not bool(estado["finalizado"]) and seguridad < 120:
		Simulador_Manager.Simular_Minuto(estado, rng)
		seguridad += 1
	assert_eq(int(estado["minuto"]), 90, "El cronómetro llega al minuto 90")
	assert_true(bool(estado["finalizado"]), "El partido finaliza")
	assert_gt((estado["eventos"] as Array).size(), 0, "Hay eventos en el teletipo")
	var posesion: float = Simulador_Manager.Posesion_Local(estado)
	assert_between(posesion, 0.0, 100.0, "La posesión es un porcentaje")
	assert_eq((estado["alineacion_local"] as Array).size(), 11, "Once titular local")
	assert_eq((estado["banquillo_local"] as Array).size(), 7, "Siete suplentes")


func test_hasta_cinco_sustituciones() -> void:
	var estado: Dictionary = _crear_estado_partido()
	for i in range(5):
		var alineacion: Array = estado["alineacion_local"]
		var banquillo: Array = estado["banquillo_local"]
		var resultado: Dictionary = Simulador_Manager.Sustituir(
			estado, "local", str(alineacion[10 - i]), str(banquillo[0]))
		assert_true(bool(resultado.get("ok", false)),
			"El cambio %d debe realizarse" % (i + 1))
	assert_eq(int(estado["cambios_local"]), 5)
	var alineacion2: Array = estado["alineacion_local"]
	var banquillo2: Array = estado["banquillo_local"]
	var sexto: Dictionary = Simulador_Manager.Sustituir(
		estado, "local", str(alineacion2[0]), str(banquillo2[0]))
	assert_false(bool(sexto.get("ok", false)), "El sexto cambio debe rechazarse")


func test_cansancio_de_los_titulares_entre_20_y_35() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2028
	var estado: Dictionary = _crear_estado_partido()
	var titulares: Array = (estado["alineacion_local"] as Array).duplicate()
	Simulador_Manager.Simular_Partido_Completo(estado, rng)
	var energia: Dictionary = estado["energia"]
	for jugador_id in titulares:
		var restante: float = float(energia.get(str(jugador_id), 100.0))
		var gastado: float = 100.0 - restante
		assert_between(gastado, 20.0, 35.0,
			"Cada titular debe perder entre un 20%% y un 35%% de energía")


func test_entrenamiento_sube_atributo_y_gasta_energia() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 555
	var jugador: Dictionary = Simulador_Manager.Crear_Jugador(
		"p_entreno", "MC", 3, rng, 18, 55.0)
	var antes: int = int(jugador["ataque"]["pase"])
	var resultado: Dictionary = Simulador_Manager.Entrenar_Jugador(jugador, "pase", rng)
	assert_true(bool(resultado.get("ok", false)), "El entrenamiento se realiza")
	assert_almost_eq(float(jugador["energia"]), 88.0, 0.01,
		"El entrenamiento consume un 12 %% de energía")
	assert_true(int(jugador["ataque"]["pase"]) >= antes, "El atributo no baja")


# ------------------------------------------------------------------
# 6. Recuperación de energía
# ------------------------------------------------------------------

func test_recuperacion_rapida_es_siete_veces_mas_rapida() -> void:
	var normal: float = Simulador_Manager.Recuperacion_Por_Minuto(false)
	var rapida: float = Simulador_Manager.Recuperacion_Por_Minuto(true)
	assert_almost_eq(rapida / normal, 7.0, 0.001,
		"El modo rápido recupera ×7 respecto al normal")
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var jugador: Dictionary = Simulador_Manager.Crear_Jugador(
		"p_energia", "DEL", 4, rng, 20, 50.0)
	jugador["energia"] = 0.0
	Simulador_Manager.Recuperar_Energia_Plantilla([jugador], 100.0, false)
	var recuperado_normal: float = float(jugador["energia"])
	jugador["energia"] = 0.0
	Simulador_Manager.Recuperar_Energia_Plantilla([jugador], 100.0, true)
	var recuperado_rapido: float = float(jugador["energia"])
	assert_almost_eq(recuperado_rapido / maxf(recuperado_normal, 0.001), 7.0, 0.001)


# ------------------------------------------------------------------
# 7. Alineación y táctica
# ------------------------------------------------------------------

func test_alineacion_automatica_11_para_las_4_formaciones() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	var club: Dictionary = Simulador_Manager.Crear_Club(
		"c_tac", "Táctica", "Ciudad", ["#0f766e", "#ffffff"], 1, 3, false, rng)
	for formacion in Datos_Manager.FORMACIONES:
		var alineacion: Array = Simulador_Manager.Elegir_Alineacion_Automatica(
			club["plantilla"], str(formacion))
		assert_eq(alineacion.size(), 11,
			"La formación %s debe alinear 11 jugadores" % formacion)
		var unicos: Dictionary = {}
		for jugador_id in alineacion:
			unicos[str(jugador_id)] = true
		assert_eq(unicos.size(), 11, "No puede haber jugadores repetidos")


# ------------------------------------------------------------------
# 8. Persistencia y retrocompatibilidad
# ------------------------------------------------------------------

func test_normalizacion_save_antiguo_carga_bloqueado() -> void:
	var normalizado: Dictionary = Sistema_Manager.Normalizar_Estado({})
	if Sistema_Manager.DESBLOQUEO_MANAGER_QA:
		assert_true(bool(normalizado["Desbloqueado"]),
			"Con el flag QA el modo se desbloquea al cargar")
	else:
		assert_false(bool(normalizado["Desbloqueado"]), "Sin datos el modo está bloqueado")
	assert_false(bool(normalizado["Activo"]), "Sin datos no hay club activo")
	assert_eq((normalizado["Clubes"] as Dictionary).size(), 0)
	assert_eq(str(normalizado["Club_Usuario_Id"]), "club_usr")


func test_normalizacion_repara_plantilla_corta_y_divisiones() -> void:
	_fundar_club_prueba()
	var estado: Dictionary = Variables_Dinamicas.Manager_Estado
	var club: Dictionary = Sistema_Manager.Club_Usuario()
	# Simular un save corrupto: plantilla de 5 y división incoherente.
	var plantilla: Array = club["plantilla"]
	while plantilla.size() > 5:
		plantilla.pop_back()
	estado["Divisiones"] = {"1": [], "2": [], "3": [], "4": []}
	var normalizado: Dictionary = Sistema_Manager.Normalizar_Estado(estado)
	assert_eq((normalizado["Clubes"] as Dictionary).size(), 16,
		"El ecosistema se conserva")
	var club_norm: Dictionary = normalizado["Clubes"]["club_usr"]
	assert_true((club_norm["plantilla"] as Array).size() >= Datos_Manager.PLANTILLA_MINIMA,
		"La plantilla se repara hasta el mínimo")
	for division in range(1, 5):
		assert_eq(((normalizado["Divisiones"] as Dictionary)[str(division)] as Array).size(),
			4, "Cada división vuelve a tener 4 clubes")


func test_desbloqueo_por_titulo_cobra_y_desbloquea() -> void:
	Variables_Dinamicas.Manager_Estado = Variables_Dinamicas.Manager_Estado_Por_Defecto()
	Variables_Dinamicas.Dinero = 2000
	var resultado: Dictionary = Sistema_Manager.Desbloquear_Por_Titulo()
	assert_true(bool(resultado.get("ok", false)), "El título debe desbloquear el modo")
	assert_eq(int(Variables_Dinamicas.Dinero), 500,
		"El título cuesta 1.500 € en modo normal")
	assert_true(Sistema_Manager.Desbloqueado())
	assert_eq(Sistema_Manager.Obtener_Reputacion(), 25,
		"La reputación inicial por título es 25")


func test_desbloqueo_por_titulo_bloqueado_con_carrera_activa() -> void:
	Variables_Dinamicas.Manager_Estado = Variables_Dinamicas.Manager_Estado_Por_Defecto()
	Variables_Dinamicas.Dinero = 2000
	Variables_Dinamicas.Carrera_Futbol["Activo"] = true
	var resultado: Dictionary = Sistema_Manager.Desbloquear_Por_Titulo()
	assert_false(bool(resultado.get("ok", false)),
		"No se puede pagar el título con un contrato de futbolista activo")
	assert_eq(int(Variables_Dinamicas.Dinero), 2000, "No se cobra nada")
	assert_false(Sistema_Manager.Desbloqueado())


func test_calendario_completa_las_4_jornadas_y_cierra_temporada() -> void:
	_fundar_club_prueba()
	var matriz_original = Variables_Dinamicas.Matriz_Jugador
	var modo_original: bool = Variables_Estaticas.Modo_Rapido
	Variables_Dinamicas.Matriz_Jugador = [[""]]
	Variables_Estaticas.Modo_Rapido = false
	Variables_Dinamicas.Minute_Day = 6 # Domingo
	var horas: Array = [600, 780, 960, 1140]
	for indice in range(horas.size()):
		Variables_Dinamicas.Minute_Minute = int(horas[indice])
		Sistema_Manager.Tick_Minuto()
		assert_true(Sistema_Manager.Puede_Jugar_Manual(),
			"La jornada %d debe quedar pendiente" % (indice + 1))
		Sistema_Manager.Auto_Resolver_Partido()
		assert_false(Sistema_Manager.Puede_Jugar_Manual(),
			"La jornada %d se resuelve al auto-simular" % (indice + 1))
	assert_eq(Sistema_Manager.Obtener_Temporada(), 2,
		"Al cerrar la jornada 4 empieza la temporada 2")
	assert_eq(Sistema_Manager.Obtener_Jornada(), 0, "La jornada vuelve a 0")
	assert_eq((Sistema_Manager.Obtener_Historial() as Array).size(), 1,
		"Se registra el histórico de la temporada")
	Variables_Dinamicas.Matriz_Jugador = matriz_original
	Variables_Estaticas.Modo_Rapido = modo_original


func test_retirada_desbloquea_el_modo_manager() -> void:
	Variables_Dinamicas.Manager_Estado = Variables_Dinamicas.Manager_Estado_Por_Defecto()
	Variables_Dinamicas.Carrera_Futbol = Variables_Dinamicas.Carrera_Futbol_Por_Defecto()
	Variables_Dinamicas.Carrera_Futbol["Activo"] = true
	Variables_Dinamicas.Carrera_Futbol["Temporadas_Jugadas"] = 3
	Variables_Dinamicas.Carrera_Futbol["Partidos_Jugados"] = 40
	Variables_Dinamicas.Carrera_Futbol["Goles_Totales"] = 25
	var matriz_original = Variables_Dinamicas.Matriz_Jugador
	Variables_Dinamicas.Matriz_Jugador = [[""]]
	assert_true(Sistema_Futbol.Puede_Retirarse(), "3 temporadas permiten retirarse")
	var resultado: Dictionary = Sistema_Manager.Desbloquear_Por_Retiro()
	assert_true(bool(resultado.get("ok", false)), "La retirada desbloquea el modo")
	assert_true(Sistema_Manager.Desbloqueado(), "El modo queda desbloqueado")
	assert_true(Sistema_Manager.Retirado_Como_Jugador(), "Se marca la retirada")
	assert_false(Sistema_Futbol.Carrera_Activa(), "La carrera de futbolista se cierra")
	assert_true(Sistema_Manager.Obtener_Reputacion() >= 15,
		"La reputación inicial es válida")
	Variables_Dinamicas.Matriz_Jugador = matriz_original


func test_partido_en_vivo_bloquea_el_auto_simulado_y_encola_la_siguiente_jornada() -> void:
	_fundar_club_prueba()
	var matriz_original = Variables_Dinamicas.Matriz_Jugador
	var modo_original: bool = Variables_Estaticas.Modo_Rapido
	Variables_Dinamicas.Matriz_Jugador = [[""]]
	Variables_Estaticas.Modo_Rapido = false
	Variables_Dinamicas.Minute_Day = 6
	Variables_Dinamicas.Minute_Minute = 600
	Sistema_Manager.Tick_Minuto()
	assert_true(Sistema_Manager.Puede_Jugar_Manual(), "Hay partido pendiente a las 10:00")
	var estado: Dictionary = Sistema_Manager.Iniciar_Partido_En_Vivo()
	assert_false(estado.is_empty(), "El partido en vivo arranca")
	# El reloj llega a las 13:00 mientras el usuario sigue jugando.
	Variables_Dinamicas.Minute_Minute = 780
	Sistema_Manager.Tick_Minuto()
	assert_true(Sistema_Manager._jornadas_pendientes.has(1),
		"La jornada 2 se encola en vez de auto-simular el partido en vivo")
	assert_true(Sistema_Manager.Puede_Jugar_Manual(),
		"El partido en vivo sigue pendiente y no se ha cancelado")
	Sistema_Manager.Simular_Resto_Partido()
	assert_eq(int(Variables_Dinamicas.Manager_Estado["Partido_Jornada"]), 1,
		"Al terminar el partido en vivo arranca la jornada encolada")
	assert_true(Sistema_Manager.Puede_Jugar_Manual(),
		"La jornada encolada queda disponible para jugar")
	Variables_Dinamicas.Matriz_Jugador = matriz_original
	Variables_Estaticas.Modo_Rapido = modo_original


func test_guardado_y_carga_completa_del_manager() -> void:
	_fundar_club_prueba()
	Variables_Dinamicas.Manager_Estado["Reputacion"] = 73
	Variables_Dinamicas.Manager_Estado["Temporada"] = 4
	Guardar_Variables_Dinamicas.save_path = RUTA_TEST_GUARDADO
	Guardar_Variables_Dinamicas.save_game()
	assert_true(FileAccess.file_exists(RUTA_TEST_GUARDADO), "El guardado se escribe")

	Variables_Dinamicas.Manager_Estado = Variables_Dinamicas.Manager_Estado_Por_Defecto()
	Guardar_Variables_Dinamicas.load_game()

	assert_true(Sistema_Manager.Activo(), "El modo se carga activo")
	assert_eq(Sistema_Manager.Obtener_Reputacion(), 73, "La reputación se conserva")
	assert_eq(Sistema_Manager.Obtener_Temporada(), 4, "La temporada se conserva")
	assert_eq((Sistema_Manager.Obtener_Clubes() as Dictionary).size(), 16,
		"Se cargan los 16 clubes")
	assert_eq((Sistema_Manager.Club_Usuario()["plantilla"] as Array).size(), 18,
		"El club del usuario conserva sus 18 futbolistas")
	Guardar_Variables_Dinamicas.save_path = _ruta_guardado_original
	if FileAccess.file_exists(RUTA_TEST_GUARDADO):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(RUTA_TEST_GUARDADO))


# ------------------------------------------------------------------
# 8. Nuevos sistemas de vestuario, instalaciones, cantera y UI
# ------------------------------------------------------------------

func test_intercambiar_titulares_cambia_slots_en_alineacion() -> void:
	_fundar_club_prueba()
	var club: Dictionary = Sistema_Manager.Club_Usuario()
	var al: Array = club["alineacion"]
	var id_0: String = str(al[0])
	var id_1: String = str(al[1])
	var res: Dictionary = Sistema_Manager.Intercambiar_Titulares(id_0, id_1)
	assert_true(bool(res.get("ok", false)), "Permite intercambiar dos titulares en la pizarra")
	var al_nueva: Array = Sistema_Manager.Club_Usuario()["alineacion"]
	assert_eq(str(al_nueva[0]), id_1, "El segundo jugador ocupa ahora la ranura 0")
	assert_eq(str(al_nueva[1]), id_0, "El primero ocupa la ranura 1")
	var fallo: Dictionary = Sistema_Manager.Intercambiar_Titulares(id_0, "inexistente")
	assert_false(bool(fallo.get("ok", true)), "Rechaza intercambiar con un jugador fuera del XI")


func test_mejorar_instalaciones_sube_nivel_y_taquilla() -> void:
	_fundar_club_prueba()
	var club: Dictionary = Sistema_Manager.Club_Usuario()
	var caja_ini: int = int(club["presupuesto"])
	var afi_ini: int = int(club["aficion"])
	var res: Dictionary = Sistema_Manager.Mejorar_Instalacion("estadio")
	assert_true(bool(res.get("ok", false)), "Mejora estadio a nivel 2")
	assert_eq(int(Sistema_Manager.Club_Usuario()["instalaciones"]["estadio"]), 2,
		"El estadio queda en nivel 2")
	assert_eq(int(Sistema_Manager.Club_Usuario()["presupuesto"]),
		caja_ini - int(Datos_Manager.INSTALACIONES_COSTES[1]),
		"Descuenta el coste exacto del nivel 1")
	assert_gt(int(Sistema_Manager.Club_Usuario()["aficion"]), afi_ini,
		"Ampliar el estadio hace crecer la afición")
	var base_nv1: int = Simulador_Manager.Calcular_Ingresos_Partido(4, 1, 0, true, afi_ini, 1)
	var base_nv2: int = Simulador_Manager.Calcular_Ingresos_Partido(4, 1, 0, true, afi_ini, 2)
	assert_gt(base_nv2, base_nv1, "El estadio de nivel 2 genera mayor taquilla local")


func test_entrenamiento_grupal_por_linea_limita_a_uno_por_dia() -> void:
	_fundar_club_prueba()
	var res: Dictionary = Sistema_Manager.Entrenar_Linea_Equipo("ataque")
	assert_true(bool(res.get("ok", false)), "La sesión colectiva de ataque funciona")
	assert_gt(int(res.get("entrenados", 0)), 0, "Entrena al menos a un delantero")
	var res_rep: Dictionary = Sistema_Manager.Entrenar_Linea_Equipo("defensa")
	assert_false(bool(res_rep.get("ok", true)), "No permite dos sesiones colectivas el mismo día")


func test_cantera_ojear_y_fichar_canterano() -> void:
	_fundar_club_prueba()
	var club: Dictionary = Sistema_Manager.Club_Usuario()
	var id_vendible: String = ""
	var menor_valor: int = 999999999
	for j in (club["plantilla"] as Array):
		if Simulador_Manager._Rol_Principal(j) != "POR" and int(j.get("valor_mercado", 0)) < menor_valor:
			menor_valor = int(j.get("valor_mercado", 0))
			id_vendible = str(j["id"])
	var v_res: Dictionary = Sistema_Manager.Vender_Jugador(id_vendible)
	assert_true(bool(v_res.get("ok", false)), "Vender un jugador de campo deja hueco en plantilla")
	var ojeo: Dictionary = Sistema_Manager.Ojear_Cantera()
	assert_true(bool(ojeo.get("ok", false)), "Ojear cantera devuelve candidatos")
	assert_eq((ojeo["candidatos"] as Array).size(), 3, "El informe trae 3 promesas")
	var ficha: Dictionary = Sistema_Manager.Fichar_Canterano(0)
	assert_true(bool(ficha.get("ok", false)), "Permite incorporar al canterano elegido")
	assert_eq((Sistema_Manager.Club_Usuario()["plantilla"] as Array).size(), 18,
		"La plantilla vuelve a 18 jugadores tras fichar de cantera")


func test_partido_amistoso_y_bloqueo_diario() -> void:
	_fundar_club_prueba()
	assert_true(Sistema_Manager.Puede_Jugar_Amistoso(), "Amistoso diario disponible al inicio")
	var estado: Dictionary = Sistema_Manager.Iniciar_Partido_Amistoso()
	assert_false(estado.is_empty(), "Inicia el amistoso")
	assert_true(bool(estado.get("es_amistoso", false)), "El partido queda marcado como amistoso")
	Sistema_Manager.Simular_Resto_Partido()
	assert_eq(int(Sistema_Manager.Club_Usuario()["puntos"]), 0,
		"El amistoso no suma puntos en la clasificación liguera")
	assert_false(Sistema_Manager.Puede_Jugar_Amistoso(),
		"Solo se puede jugar un amistoso por día")


func test_capitania_dorsal_y_renovacion_contrato() -> void:
	_fundar_club_prueba()
	var club: Dictionary = Sistema_Manager.Club_Usuario()
	var plantilla: Array = club["plantilla"]
	var jid: String = str(plantilla[1]["id"])
	var jid_0: String = str(plantilla[0]["id"])
	var dorsal_0_ini: int = int(plantilla[0]["dorsal"])
	var dorsal_1_ini: int = int(plantilla[1]["dorsal"])
	var contrato_ini: int = int(plantilla[1].get("contrato_temporadas", 1))
	var c_res: Dictionary = Sistema_Manager.Cambiar_Capitan(jid)
	assert_true(bool(c_res.get("ok", false)), "Cambia el capitán del vestuario")
	assert_eq(str(Sistema_Manager.Club_Usuario()["capitan_id"]), jid, "Capitanía actualizada")
	var d_swap: Dictionary = Sistema_Manager.Cambiar_Dorsal(jid, dorsal_0_ini)
	assert_true(bool(d_swap.get("ok", false)), "Intercambia dorsales con el compañero")
	assert_eq(int(Sistema_Manager.Obtener_Jugador_De_Club(Sistema_Manager.Club_Usuario_Id(), jid_0)["dorsal"]),
		dorsal_1_ini, "El compañero hereda el dorsal previo manteniendo unicidad")
	var d_ok: Dictionary = Sistema_Manager.Cambiar_Dorsal(jid, 99)
	assert_true(bool(d_ok.get("ok", false)), "Asigna dorsal libre")
	assert_eq(int(d_ok.get("dorsal", 0)), 99, "Dorsal actualizado a 99")
	var r_ok: Dictionary = Sistema_Manager.Renovar_Contrato(jid)
	assert_true(bool(r_ok.get("ok", false)), "Renueva el contrato del jugador")
	assert_eq(int(r_ok.get("contrato", 0)), mini(5, contrato_ini + 2),
		"La renovación amplía el contrato hasta el tope de 5")


func test_fuerza_club_apariencia_determinista_y_hay_novedad() -> void:
	Variables_Dinamicas.Manager_Estado = Variables_Dinamicas.Manager_Estado_Por_Defecto()
	assert_false(Sistema_Manager.Hay_Novedad(), "Sin desbloquear ni partido no hay novedad")
	Variables_Dinamicas.Manager_Estado["Desbloqueado"] = true
	assert_true(Sistema_Manager.Hay_Novedad(), "Desbloqueado sin club sí avisa para fundar")

	_fundar_club_prueba()
	assert_false(Sistema_Manager.Hay_Novedad(), "Con club recién fundado y sin partido no hay novedad")
	Variables_Dinamicas.Manager_Estado["Partido_Pendiente"] = true
	assert_true(Sistema_Manager.Hay_Novedad(), "Partido pendiente activa Hay_Novedad()")

	var club: Dictionary = Sistema_Manager.Club_Usuario()
	var fuerza: Dictionary = Simulador_Manager.Calcular_Fuerza_Club(club, true)
	assert_gt(float(fuerza.get("media", 0.0)), 10.0, "Calcula media del XI")
	assert_gt(float(fuerza.get("quimica", 0.0)), 40.0, "Calcula química de posiciones")
	var j: Dictionary = club["plantilla"][2]
	var ap1: Dictionary = Simulador_Manager.Apariencia_De_Jugador(j, ["#dc2626", "#ffffff"], 2)
	var ap2: Dictionary = Simulador_Manager.Apariencia_De_Jugador(j, ["#dc2626", "#ffffff"], 2)
	assert_eq(ap1, ap2, "La apariencia generada por id es completamente determinista")
	assert_eq(str(ap1.get("detalle_ropa", "")), "club_2_%d" % int(j.get("dorsal", 1)),
		"Genera el detalle de equipación y dorsal del club")


func test_ui_panel_manager_y_partido_smoke() -> void:
	# 1. Pantalla de bloqueo y fundación.
	Variables_Dinamicas.Manager_Estado = Variables_Dinamicas.Manager_Estado_Por_Defecto()
	var panel := Panel_Manager.new()
	add_child_autofree(panel)
	assert_gt(panel._contenido.get_child_count(), 0, "Renderiza pantalla de desbloqueo")

	Variables_Dinamicas.Manager_Estado["Desbloqueado"] = true
	panel._Refrescar(true)
	assert_gt(panel._contenido.get_child_count(), 0, "Renderiza pantalla de fundación")

	# 2. Club activo y 5 pestañas + ficha + oferta.
	_fundar_club_prueba()
	for tab in ["club", "plantilla", "tactica", "mercado", "liga"]:
		panel._tab_actual = tab
		panel._Refrescar(true)
		assert_gt(panel._contenido.get_child_count(), 0,
			"La pestaña %s se construye correctamente" % tab)

	var club: Dictionary = Sistema_Manager.Club_Usuario()
	var jug_id: String = str((club["plantilla"] as Array)[0]["id"])
	panel._Abrir_Ficha_Jugador(jug_id)
	assert_true(is_instance_valid(panel._modal_ficha), "Abre ficha humana del jugador")
	panel._Cerrar_Ficha()

	var otro_jug_id: String = ""
	for cid in Sistema_Manager.Obtener_Clubes().keys():
		if str(cid) != Sistema_Manager.Club_Usuario_Id():
			otro_jug_id = str((Sistema_Manager.Obtener_Club(str(cid))["plantilla"] as Array)[0]["id"])
			break
	if not otro_jug_id.is_empty():
		panel._Abrir_Modal_Oferta(otro_jug_id)
		assert_true(is_instance_valid(panel._modal_oferta), "Abre modal de oferta económica")
		panel._Cerrar_Modal_Oferta()

	# 3. Partido en vivo: controles, pausa, cambios y salto al final.
	var estado_p: Dictionary = Sistema_Manager.Iniciar_Partido_Amistoso()
	assert_false(estado_p.is_empty(), "Amistoso listo para abrir en vivo")
	var p_partido := Panel_Manager_Partido.new()
	add_child_autofree(p_partido)
	p_partido.abrir(estado_p)
	p_partido._Cambiar_Mentalidad("ofensiva")
	p_partido._Cambiar_Presion("alta")
	p_partido._Alternar_Pausa()
	assert_true(p_partido._pausado, "Permite pausar el partido en vivo")
	p_partido._Abrir_Modal_Cambios()
	p_partido._Cerrar_Modal_Cambios()
	p_partido._Saltar_Al_Final()
	assert_true(bool(estado_p.get("finalizado", false)),
		"El botón Saltar finaliza el partido sin errores")
	assert_true(Sistema_Manager.Obtener_Partido_En_Vivo().is_empty(),
		"El partido en vivo queda cerrado en Sistema_Manager")
	panel.queue_free()
	p_partido.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func test_transicion_y_orientacion_horizontal_manager() -> void:
	_fundar_club_prueba()
	assert_eq(Panel_Manager.TAMANO_HORIZONTAL, Vector2i(1280, 720),
		"El Mánager define tamaño horizontal 1280x720")
	assert_eq(Panel_Manager.TAMANO_VERTICAL, Vector2i(720, 1280),
		"El Mánager define retorno vertical 720x1280")

	var trans := Transicion_Minijuego.new()
	add_child_autofree(trans)
	trans.configurar_tema("manager", Sistema_Manager.Club_Usuario())
	assert_eq(trans._tema, "manager", "La transición adopta tema de El Mánager")
	assert_true(trans._hero_manager.visible, "Muestra el escudo y el entrenador en el telón")
	assert_false(trans._chef.visible, "Oculta al chef de cocina en el telón de Mánager")

	var panel := Panel_Manager.new()
	add_child_autofree(panel)
	watch_signals(panel)
	panel._Solicitar_Salida()
	panel._Solicitar_Salida()
	assert_signal_emit_count(panel, "cerrado", 1,
		"La petición de salida emite cerrado una sola vez")
	trans.queue_free()
	panel.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
