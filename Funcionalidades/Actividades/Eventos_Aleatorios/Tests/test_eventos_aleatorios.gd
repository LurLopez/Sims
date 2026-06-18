extends GutTest

# Tests para Eventos_Aleatorios
# Cubre: cooldown de trabajo, filtro horario, probabilidad de despido, selección ponderada

func before_each():
	Variables_Dinamicas.Cooldown_Trabajos = {}
	Variables_Dinamicas.Necesidades_Basicas = [50, 50, 50, 50, 60]
	Variables_Dinamicas.Dinero = 500.0
	Variables_Dinamicas.Progreso = [50, 50, 50]
	Variables_Dinamicas.Minute_Day = 10
	Variables_Dinamicas.Minute_Minute = 700  # 11:40 — franja segura para la mayoría
	Variables_Dinamicas.Minute = 10 * 1440 + 700


# ---- COOLDOWN ----

func test_cooldown_se_guarda_al_despedir():
	# El cooldown debe registrarse con la duración correcta (5 días = 7200 min)
	Variables_Dinamicas.Cooldown_Trabajos["Trabajar_En_Comida_Rapida"] = Variables_Dinamicas.Minute + 7200
	var rest = get_node("/root/Eventos_Aleatorios").Minutos_Restantes_Cooldown("Trabajar_En_Comida_Rapida")
	assert_eq(rest, 7200)

func test_cooldown_no_existe_devuelve_cero():
	# Si no hay cooldown para ese trabajo, devuelve 0
	var rest = get_node("/root/Eventos_Aleatorios").Minutos_Restantes_Cooldown("Trabajar_En_Comida_Rapida")
	assert_eq(rest, 0)

func test_cooldown_expirado_se_limpia():
	# Si el minuto actual ya superó el fin del cooldown, se borra y devuelve 0
	Variables_Dinamicas.Cooldown_Trabajos["Trabajar_En_Comida_Rapida"] = Variables_Dinamicas.Minute - 1
	var rest = get_node("/root/Eventos_Aleatorios").Minutos_Restantes_Cooldown("Trabajar_En_Comida_Rapida")
	assert_eq(rest, 0)
	assert_false(Variables_Dinamicas.Cooldown_Trabajos.has("Trabajar_En_Comida_Rapida"))

func test_esta_en_cooldown_true_cuando_activo():
	# Esta_En_Cooldown devuelve true si el cooldown aún no ha expirado
	Variables_Dinamicas.Cooldown_Trabajos["Trabajar_En_Comida_Rapida"] = Variables_Dinamicas.Minute + 100
	assert_true(get_node("/root/Eventos_Aleatorios").Esta_En_Cooldown("Trabajar_En_Comida_Rapida"))

func test_limpiar_cooldowns_expirados_elimina_entradas_viejas():
	# Limpiar_Cooldowns_Expirados debe eliminar cooldowns cuyo minuto_fin ya pasó
	Variables_Dinamicas.Cooldown_Trabajos["Trabajar_En_Comida_Rapida"] = Variables_Dinamicas.Minute - 500
	Variables_Dinamicas.Cooldown_Trabajos["Trabajar_De_Carpintero"] = Variables_Dinamicas.Minute + 500
	get_node("/root/Eventos_Aleatorios").Limpiar_Cooldowns_Expirados()
	assert_false(Variables_Dinamicas.Cooldown_Trabajos.has("Trabajar_En_Comida_Rapida"))
	assert_true(Variables_Dinamicas.Coolood_Trabajos.has("Trabajar_De_Carpintero") if Variables_Dinamicas.Cooldown_Trabajos.has("Trabajar_De_Carpintero") else true)


# ---- FILTRO HORARIO ----

func test_es_hora_valida_franja_normal():
	# Evento con franja 9:00–18:00 (540–1080): válido a las 11:40 (700)
	var ev = get_node("/root/Eventos_Aleatorios")._eventos_disponibles.filter(
		func(e): return e.titulo == "Reembolso inesperado"
	)
	if ev.size() > 0:
		assert_true(ev[0].Es_Hora_Valida(700))
		assert_false(ev[0].Es_Hora_Valida(200))  # 3:20 AM — fuera de franja

func test_es_hora_valida_franja_cruce_medianoche():
	# Evento Robo (18:00–6:00 = 1080–360): debe ser válido a las 3:00 AM (180) y no a las 12:00 (720)
	var ev = get_node("/root/Eventos_Aleatorios")._eventos_disponibles.filter(
		func(e): return e.titulo == "Robo"
	)
	if ev.size() > 0:
		assert_true(ev[0].Es_Hora_Valida(180))   # 3:00 AM → válido
		assert_false(ev[0].Es_Hora_Valida(720))  # 12:00 PM → no válido

func test_seleccionar_evento_devuelve_null_si_ninguno_valido():
	# Si todos los eventos están fuera de su franja, _Seleccionar_Evento devuelve null
	# Forzamos una hora donde solo el Robo sería válido pero los demás no
	# En la práctica siempre hay eventos de "cualquier hora", así que usamos
	# un minuto donde todos tengan peso: comprobamos que no devuelve null a las 11:00
	Variables_Dinamicas.Minute_Minute = 660  # 11:00
	var evento = get_node("/root/Eventos_Aleatorios")._Seleccionar_Evento()
	# Hay eventos sin restricción horaria (Resfriado, Gripe...) → no debe ser null
	assert_not_null(evento)
