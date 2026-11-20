extends Node

func Ejecutar_Actividad(actividad: Actividad, es_aleatoria: bool = false):
	# El contador de cocina solo sobrevive mientras se cocina de forma continuada.
	if actividad.nombre != Alimentacion.NOMBRE_COCINAR:
		Variables_Dinamicas.Minutos_Cocinando_Actuales = 0

	# Cocina: la producción, el coste y el progreso se resuelven en Alimentacion.
	# Los efectos fisiológicos siguen aplicándose con el motor genérico.
	if actividad.nombre == Alimentacion.NOMBRE_COCINAR:
		var resultado_cocina: Dictionary = Alimentacion.Ejecutar_Minuto_Cocinar()
		if bool(resultado_cocina.get("cancelado", false)):
			return
	# Comer_Tupper y Comer_Basura aplican sus propios efectos modulados.
	elif actividad.nombre == Alimentacion.NOMBRE_TUPPER:
		var resultado_tupper: Dictionary = Alimentacion.Ejecutar_Minuto_Comer_Tupper(es_aleatoria)
		if bool(resultado_tupper.get("cancelado", false)):
			return
		return
	elif actividad.nombre == Alimentacion.NOMBRE_BASURA:
		var resultado_basura: Dictionary = Alimentacion.Ejecutar_Minuto_Comer_Basura()
		if bool(resultado_basura.get("cancelado", false)):
			return
		return

	# Necesidades básicas SIEMPRE se aplican (incluso en actividades aleatorias),
	# así el personaje no se muere si el jugador no entra durante tiempo.
	Actividades_Necesidades_Basicas.Ejecutar_Actividad_Necesidades_Basicas_Array(actividad.efectos_necesidades_basicas, actividad.nombre)
	# Progreso y descubrimiento SOLO si la actividad fue programada por el jugador.
	# Una actividad aleatoria mantiene vivo al personaje pero no le hace avanzar
	# habilidades; el jugador debe estar presente para crecer.
	if not es_aleatoria:
		Actividades_Habilidades.Ejecutar_Actividad_Progreso_Array(actividad.efectos_progreso)
		Actividades_Habilidades.Ejecutar_Actividad_Mostrar_Habilidad_Array(actividad.efectos_progreso)
	# Progreso de carrera activa:
	# - Si es una Actividad_Carrera específica → siempre suma (la actividad existe para eso).
	# - Si es la actividad "Estudiar" genérica y hay carrera activa → también suma
	#   (mientras estudias, también avanzas la carrera; UX-friendly hasta que existan
	#   actividades de carrera programables explícitamente).
	if not es_aleatoria and Variables_Dinamicas.Carrera_Actual != null:
		if actividad is Actividad_Carrera or actividad.nombre == "Estudiar":
			get_node("/root/Sistema_Examenes").Incrementar_Progreso_Carrera(Variables_Dinamicas.Carrera_Actual)
	# Desbloqueo del minijuego de cocina al primer minuto real trabajado en hostelería
	if actividad is Actividad_Fija_Trabajo and not es_aleatoria \
			and Sistema_Cocina.Es_Trabajo_Hosteleria(actividad.nombre):
		Sistema_Cocina.Registrar_Minuto_Trabajo_Hosteleria(actividad.nombre)

	# Pago de salario al cruzar el último minuto del día laboral
	if actividad is Actividad_Fija_Trabajo and Variables_Dinamicas.Minute_Minute == actividad.hora_final - 1:
		var horas_trabajadas: float = float(actividad.hora_final - actividad.hora_inicio) / 60.0
		var salario_jornada: float = Variables_Estaticas.Obtener_Salario_Hora(actividad) * horas_trabajadas
		if Sistema_Cocina.Es_Trabajo_Hosteleria(actividad.nombre):
			var bonus_ropa: float = Sistema_Cocina.Obtener_Bonus_Salario_Hosteleria()
			var plus_turno: bool = bool(Variables_Dinamicas.Cocina_Estado.get("plus_nomina_turno_hoy", false))
			salario_jornada *= Sistema_Cocina.Calcular_Multiplicador_Salario_Hosteleria(bonus_ropa, plus_turno)
			if plus_turno:
				Variables_Dinamicas.Cocina_Estado["plus_nomina_turno_hoy"] = false
		Variables_Dinamicas.Dinero += salario_jornada


func Crear_Actividad_Aleatoria() -> Actividad:
	var necesidad_baja = 100
	var ind_baja = 0
	for i in range(0, Variables_Dinamicas.Necesidades_Basicas.size()):
		if Variables_Dinamicas.Necesidades_Basicas[i] < necesidad_baja:
			necesidad_baja = Variables_Dinamicas.Necesidades_Basicas[i]
			ind_baja = i

	if necesidad_baja < 30:
		return Crear_Actividad_Aleatoria_Debajo_De_30(ind_baja)
	else:
		return Crear_Actividad_Aleatoria_Mas_De_30()

func Crear_Actividad_Aleatoria_Debajo_De_30(indice) -> Actividad:
	match indice:
		0: return Variables_Estaticas.Catalogo_Actividades["Salir_A_Correr"]
		1: return Variables_Estaticas.Catalogo_Actividades["Ver_La_Television"]
		2: return Alimentacion.Elegir_Comida_IA()
		3: return Variables_Estaticas.Catalogo_Actividades["Dormir"]
		4: return Variables_Estaticas.Catalogo_Actividades["Duchar"]
	return Variables_Estaticas.Catalogo_Actividades["Ver_La_Television"]

func Crear_Actividad_Aleatoria_Mas_De_30() -> Actividad:
	var personalidad = Variables_Estaticas.Personalidad
	var valor = Funciones_Globales.Generar_Numero_Aleatorio_Entero(0, Variables_Estaticas.Actividades.size() * 2)
	if valor >= Variables_Estaticas.Actividades.size():
		match personalidad:
			"Trabajador_Compulsivo": return Variables_Estaticas.Catalogo_Actividades["Estudiar"]
			"Deportista":           return Variables_Estaticas.Catalogo_Actividades["Salir_A_Correr"]
			_:                      return Variables_Estaticas.Catalogo_Actividades["Ver_La_Television"]
	else:
		return Variables_Estaticas.Actividades[valor]


func _Calcular_Rango(semana, dia_inicio, dia_final, hora_inicio, hora_final, minuto_inicio, minuto_final) -> Array:
	var celdas = []
	var i = semana * 7 + dia_inicio
	var i_fin = semana * 7 + dia_final
	var j = hora_inicio * 60 + minuto_inicio
	var j_fin = hora_final * 60 + minuto_final
	var seguir = true
	while seguir:
		if j_fin == 0:
			if i + 1 >= i_fin:
				if j >= 1439:
					seguir = false
			elif j >= 1440:
				i += 1
				j = 0
		else:
			if i >= i_fin:
				if j + 1 >= j_fin:
					seguir = false
			elif j >= 1440:
				i += 1
				j = 0
		celdas.append([i, j])
		j += 1
	return celdas

func _Prioridad_Celda(celda, _i: int, _j: int) -> int:
	if celda is Actividad:
		return celda.Obtener_Prioridad()
	return 0


func Calcular_Duracion_Rango(dia_inicio: int, hora_inicio: int, minuto_inicio: int,
		dia_final: int, hora_final: int, minuto_final: int) -> int:
	var min_ini: int = hora_inicio * 60 + minuto_inicio
	var min_fin: int = hora_final * 60 + minuto_final
	var duracion: int = (dia_final - dia_inicio) * 1440 + (min_fin - min_ini)
	if duracion < 0:
		duracion += 1440
	return maxi(0, duracion)


func Validar_Horario_Cocinar(duracion_min: int) -> Dictionary:
	return Alimentacion.Validar_Cocinar(duracion_min, Variables_Dinamicas.En_La_Calle)

func Crear_Actividad_Especifica(semana, dia_inicio, dia_final, hora_inicio, hora_final, minuto_inicio, minuto_final, actividad) -> bool:
	var actividad_obj
	if actividad is String:
		if actividad == "":
			actividad_obj = ""
		else:
			actividad_obj = Variables_Estaticas.Catalogo_Actividades[actividad]
	else:
		actividad_obj = actividad

	var celdas = _Calcular_Rango(semana, dia_inicio, dia_final, hora_inicio, hora_final, minuto_inicio, minuto_final)

	# Guarda defensiva: nunca escribir fuera de la matriz 1440x574.
	for par in celdas:
		if par[0] < 0 or par[0] >= 574 or par[1] < 0 or par[1] >= 1440:
			return false

	# Cocinar exige vivienda y un bloque mínimo de 15 minutos (un tupper).
	if actividad_obj is Actividad and actividad_obj.nombre == Alimentacion.NOMBRE_COCINAR:
		var validacion: Dictionary = Alimentacion.Validar_Cocinar(celdas.size(), Variables_Dinamicas.En_La_Calle)
		if not bool(validacion.get("valido", false)):
			return false

	# Actividades de baja prioridad (P1): bloquear toda la operación si alguna celda tiene mayor prioridad
	if actividad_obj is Actividad and actividad_obj.Obtener_Prioridad() == 1:
		for par in celdas:
			var celda_actual = Variables_Dinamicas.Matriz_Jugador[par[1]][par[0]]
			if _Prioridad_Celda(celda_actual, par[0], par[1]) > 1:
				return false

	for par in celdas:
		Crear_Actividad(par[0], par[1], actividad_obj)

	if actividad_obj is String and actividad_obj == "":
		Sistema_Notificaciones.Cancelar_Notificacion_Actividad(semana, dia_inicio, hora_inicio, minuto_inicio)
	elif actividad_obj is Actividad:
		Sistema_Notificaciones.Programar_Notificacion_Actividad(actividad_obj.nombre, semana, dia_inicio, hora_inicio, minuto_inicio)

	Guardar_Variables_Estaticas.save_game()
	Guardar_Variables_Dinamicas.save_game()
	return true

func Crear_Actividad(i, j, actividad) -> bool:
	# Borrar ("") siempre permitido
	if actividad is String:
		Variables_Dinamicas.Matriz_Jugador[j][i] = actividad
		Variables_Dinamicas.Matriz_Sucia = true
		return true
	# Bloquear si la celda existente tiene mayor prioridad
	var celda_actual = Variables_Dinamicas.Matriz_Jugador[j][i]
	if _Prioridad_Celda(celda_actual, i, j) > actividad.Obtener_Prioridad():
		return false
	Variables_Dinamicas.Matriz_Jugador[j][i] = actividad
	Variables_Dinamicas.Matriz_Sucia = true
	return true


func Limpiar_Examen_De_Matriz(carrera: Carrera) -> void:
	if carrera == null or carrera.hora_examen_dia < 0:
		return
	var examen_obj = Variables_Estaticas.Catalogo_Actividades.get("Examen_Carrera", null)
	if examen_obj == null:
		return
	for col in range(574):
		for fila in range(carrera.hora_examen_inicio, mini(1440, carrera.hora_examen_inicio + 60)):
			if Variables_Dinamicas.Matriz_Jugador[fila][col] == examen_obj:
				Variables_Dinamicas.Matriz_Jugador[fila][col] = ""
	Variables_Dinamicas.Matriz_Sucia = true


func Escribir_Examen_En_Matriz(carrera: Carrera):
	Limpiar_Examen_De_Matriz(carrera)
	var columna: int
	if Variables_Estaticas.Modo_Rapido:
		columna = carrera.hora_examen_dia
	else:
		var semana_actual = Variables_Dinamicas.Minute_Day / 7
		var dia_semana_actual = Variables_Dinamicas.Minute_Day % 7
		# Mon/Tue (0-1): el examen es esta semana. Wed-Sun (2-6): la semana que viene.
		var semana_examen = semana_actual if dia_semana_actual <= 1 else semana_actual + 1
		columna = semana_examen * 7 + carrera.hora_examen_dia
	if columna < 0 or columna >= 574:
		return
	var actividad = Variables_Estaticas.Catalogo_Actividades["Examen_Carrera"]
	for offset in range(60):
		var fila = carrera.hora_examen_inicio + offset
		if fila < 1440:
			Variables_Dinamicas.Matriz_Jugador[fila][columna] = actividad
	Variables_Dinamicas.Matriz_Sucia = true
	var sem_ex: int = columna / 7
	var dia_ex: int = columna % 7
	var h_ex: int = carrera.hora_examen_inicio / 60
	var m_ex: int = carrera.hora_examen_inicio % 60
	Sistema_Notificaciones.Programar_Notificacion_Actividad("Examen de " + carrera.nombre, sem_ex, dia_ex, h_ex, m_ex)


func Cobrar_Alquiler():
	var alquiler = Variables_Estaticas.Obtener_Alquiler()
	# Solo cobrar si tienes dinero suficiente
	if Variables_Dinamicas.Dinero >= alquiler:
		Variables_Dinamicas.Dinero -= alquiler
		Variables_Dinamicas.Ultima_Fecha_Alquiler = Variables_Dinamicas.Minute
	else:
		# No tienes dinero suficiente, te vas a la calle automáticamente
		Ir_A_La_Calle()


func Ir_A_La_Calle():
	Variables_Dinamicas.En_La_Calle = true
	Variables_Dinamicas.Ultima_Fecha_Alquiler = -1
	# Capar necesidades básicas a 20 inmediatamente.
	for k in range(Variables_Dinamicas.Necesidades_Basicas.size()):
		if Variables_Dinamicas.Necesidades_Basicas[k] > Variables_Estaticas.BANCARROTA_MAX_NECESIDAD:
			Variables_Dinamicas.Necesidades_Basicas[k] = Variables_Estaticas.BANCARROTA_MAX_NECESIDAD


func Volver_A_Alquiler():
	var alquiler = Variables_Estaticas.Obtener_Alquiler()
	if Variables_Dinamicas.Dinero >= alquiler:
		Variables_Dinamicas.En_La_Calle = false
		Variables_Dinamicas.Dinero -= alquiler
		Variables_Dinamicas.Ultima_Fecha_Alquiler = Variables_Dinamicas.Minute
	else:
		# No tienes dinero suficiente, permaneces en la calle
		pass


var _ultima_prob_muerte_minuto: float = 0.0

func Comprobar_Muerte() -> bool:
	if Variables_Dinamicas.Minute_Day >= 573 and Variables_Dinamicas.Minute_Minute >= 1439:
		_ultima_prob_muerte_minuto = 1.0
		Variables_Dinamicas.Prob_Supervivencia_Acumulada = 0.0
		return true
	var edad = Variables_Estaticas.Calcular_Edad()
	var media_nec = 0.0
	for n in Variables_Dinamicas.Necesidades_Basicas:
		media_nec += n
	media_nec /= Variables_Dinamicas.Necesidades_Basicas.size()
	var factor_edad = pow(2.0, (edad - 18) / 10.0)
	var factor_nec = pow(35.0, media_nec / 100.0)
	var factor_modo = 7.0 if Variables_Estaticas.Modo_Rapido else 1.0
	var max_valor = max(1, int((1_875_000.0 * factor_nec / factor_edad) / factor_modo))
	_ultima_prob_muerte_minuto = 1.0 / float(max_valor)
	Variables_Dinamicas.Prob_Supervivencia_Acumulada *= (1.0 - _ultima_prob_muerte_minuto)
	return randi() % max_valor == 0


func _Guardar_Log_Muerte() -> void:
	if not OS.is_debug_build():
		return
	var edad = Variables_Estaticas.Calcular_Edad()
	var prob_acum = (1.0 - Variables_Dinamicas.Prob_Supervivencia_Acumulada) * 100.0
	var prob_min = _ultima_prob_muerte_minuto * 100.0
	var uno_en = 0
	if _ultima_prob_muerte_minuto > 0.0:
		uno_en = int(1.0 / _ultima_prob_muerte_minuto)
	print("[Muerte] Edad: %d | P.minuto: %.8f%% (1 en %d) | P.acumulada: %.4f%%" % [edad, prob_min, uno_en, prob_acum])


# ============================================================================
# Salir de fiesta: ventana horaria, probabilidades, Euforia y Resacón
# ============================================================================

const FIESTA_NOMBRE := "Salir_De_Fiesta"
const FIESTA_ESTADO_EUFORIA := "Euforia"
const FIESTA_ESTADO_RESACON := "Resacon"
const FIESTA_DURACION_ESTADO := 1440
const FIESTA_MESETA_ESTADO := 480
const FIESTA_VENTANA_BAJADA := FIESTA_DURACION_ESTADO - FIESTA_MESETA_ESTADO
const FIESTA_MATRIZ_MAX_DIA := 573


func _Resultado_Horario_Fiesta(valido: bool, duracion_min: int, motivo: String) -> Dictionary:
	return {
		"valido": valido,
		"duracion_min": duracion_min,
		"motivo": motivo
	}


func Calcular_Mod_Edad_Fiesta(edad: int) -> float:
	return clampf(10.0 - float(edad - 20) * 0.625, -25.0, 12.0)


func _Obtener_Mod_Personalidad_Fiesta(personalidad: String) -> float:
	match personalidad:
		"Deportista":
			return 10.0
		"Culo_Del_Sofa":
			return -10.0
		"Trabajador_Compulsivo":
			return -5.0
		_:
			return 0.0


# La noche de fiesta pertenece al día en que empezó. El límite son las 06:00:
# un domingo a las 06:00 todavía cuenta como noche del sábado.
func Obtener_Dia_Semana_Noche(dia: int, hora: int) -> int:
	var dia_noche: int = dia - 1 if hora <= 6 else dia
	return posmod(dia_noche, 7)


func Obtener_Mult_Dia_Fiesta(dia_semana_noche: int) -> float:
	match dia_semana_noche:
		0, 1, 2:
			return 0.70  # Lunes, Martes, Miércoles
		3:
			return 1.00  # Jueves
		4:
			return 1.25  # Viernes
		5:
			return 1.45  # Sábado
		6:
			return 0.80  # Domingo
		_:
			return 1.00


func Calcular_Puntaje_Ligar(nb: Array, progreso: Array, personalidad: String, edad: int = 36) -> float:
	var mod_pers: float = _Obtener_Mod_Personalidad_Fiesta(personalidad)
	var mod_edad: float = Calcular_Mod_Edad_Fiesta(edad)
	var raw: float = (50.0
		+ 0.30 * (float(nb[1]) - 50.0)
		+ 0.25 * (float(nb[4]) - 50.0)
		+ 0.20 * (float(progreso[0]) - 50.0)
		+ 0.15 * (float(progreso[1]) - 50.0)
		+ 0.10 * (float(nb[3]) - 50.0)
		+ mod_pers
		+ mod_edad)
	return clampf(raw, 0.0, 100.0)


func Calcular_Prob_Ligar_Min(puntaje_ligar: float, dia_semana_noche: int = 3) -> float:
	var base: float = 0.00001 + 0.00099 * (puntaje_ligar / 100.0)
	return base * Obtener_Mult_Dia_Fiesta(dia_semana_noche)


func Calcular_Aguante_Resacon(nb: Array, progreso: Array, edad: int = 36) -> float:
	var mod_edad: float = Calcular_Mod_Edad_Fiesta(edad)
	var raw: float = (50.0
		+ 0.40 * (float(nb[2]) - 50.0)
		+ 0.30 * (float(nb[3]) - 50.0)
		+ 0.20 * (float(nb[0]) - 50.0)
		+ 0.10 * (float(progreso[0]) - 50.0)
		+ mod_edad)
	return clampf(raw, 0.0, 100.0)


func Calcular_Prob_Resacon_Min(aguante_resacon: float) -> float:
	var riesgo: float = (100.0 - aguante_resacon) / 100.0
	return 0.00001 + 0.00099 * riesgo


func Simular_Preview_Fiesta(nb_inicial: Array, progreso: Array, personalidad: String,
		duracion_min: int, edad: int = 36, dia_semana_noche: int = 3) -> Dictionary:
	var nb: Array[float] = []
	for valor in nb_inicial:
		nb.append(clampf(float(valor), 1.0, 100.0))
	var frecuencias: Array[float] = [30.0, 30.0, 12.0, 15.0, 20.0]
	var efectos: Array[float] = [0.0, 9.0, -3.0, -4.0, -2.0]

	var p_ligar: float = 0.0
	var p_resacon: float = 0.0
	var supervivencia: float = 1.0
	var pl_inicio: float = 0.0
	var pr_inicio: float = 0.0
	var pl_fin: float = 0.0
	var pr_fin: float = 0.0

	for minuto in range(maxi(0, duracion_min)):
		for k in range(5):
			if is_equal_approx(efectos[k], 0.0):
				continue
			var delta: float = signf(efectos[k]) * minf(1.0, absf(efectos[k]) / frecuencias[k])
			nb[k] = clampf(nb[k] + delta, 1.0, 100.0)

		var pl: float = Calcular_Prob_Ligar_Min(
			Calcular_Puntaje_Ligar(nb, progreso, personalidad, edad), dia_semana_noche)
		var pr: float = Calcular_Prob_Resacon_Min(
			Calcular_Aguante_Resacon(nb, progreso, edad))
		if minuto == 0:
			pl_inicio = pl
			pr_inicio = pr
		pl_fin = pl
		pr_fin = pr

		p_ligar += supervivencia * pl
		p_resacon += supervivencia * pr * (1.0 - pl)
		supervivencia *= (1.0 - pl) * (1.0 - pr)

	return {
		"duracion_min": maxi(0, duracion_min),
		"pl_inicio": pl_inicio,
		"pl_fin": pl_fin,
		"pr_inicio": pr_inicio,
		"pr_fin": pr_fin,
		"p_ligar": p_ligar,
		"p_resacon": p_resacon,
		"p_nada": supervivencia
	}


# Validación pura de la ventana de fiesta. `semana` es opcional (-1 = no comprobar
# límites de matriz); la UI pasa `mirar_semana` para no escribir fuera de la matriz.
func Validar_Horario_Fiesta(dia_inicio: int, hora_inicio: int, minuto_inicio: int,
		dia_final: int, hora_final: int, minuto_final: int, semana: int = -1) -> Dictionary:
	if hora_inicio < 0 or hora_inicio > 23 or minuto_inicio < 0 or minuto_inicio > 59:
		return _Resultado_Horario_Fiesta(false, 0, "La fiesta debe empezar entre las 18:00 y las 04:00")
	if hora_final < 0 or hora_final > 24 or minuto_final < 0 or minuto_final > 59:
		return _Resultado_Horario_Fiesta(false, 0, "La fiesta debe terminar como máximo a las 06:00")
	if hora_final == 24 and minuto_final != 0:
		return _Resultado_Horario_Fiesta(false, 0, "La fiesta debe terminar como máximo a las 06:00")
	if dia_inicio < 0 or dia_inicio > 6:
		return _Resultado_Horario_Fiesta(false, 0, "El horario de fin debe ser posterior al de inicio")

	var m_ini: int = hora_inicio * 60 + minuto_inicio
	var m_fin_bruto: int = hora_final * 60 + minuto_final
	var fin_es_24: bool = m_fin_bruto == 1440
	var m_fin: int = 0 if fin_es_24 else m_fin_bruto

	# Inicio permitido: 18:00-04:00 inclusive.
	if not (m_ini >= 1080 or m_ini <= 240):
		return _Resultado_Horario_Fiesta(false, 0, "La fiesta debe empezar entre las 18:00 y las 04:00")

	# Una hora de fin idéntica al inicio nunca es un bloque válido.
	if not fin_es_24 and m_fin == m_ini:
		return _Resultado_Horario_Fiesta(false, 0, "El horario de fin debe ser posterior al de inicio")

	var cruce: bool = (not fin_es_24) and m_ini >= 1080 and m_fin <= 360
	var fin_en_ventana: bool = fin_es_24 or m_fin >= 1200 or m_fin <= 360
	if not fin_en_ventana:
		# Caso 18:00-19:59: el fin aún no está en la ventana, pero el motivo
		# prioritario es la duración mínima (AC-04).
		if not cruce and m_fin > m_ini and (m_fin - m_ini) < 120:
			return _Resultado_Horario_Fiesta(false, 0, "La fiesta debe durar al menos 2 horas")
		return _Resultado_Horario_Fiesta(false, 0, "La fiesta debe terminar como máximo a las 06:00")

	var duracion: int = 0
	if fin_es_24:
		# 24:00 solo tiene sentido como final del mismo día seleccionado.
		if dia_final != dia_inicio:
			return _Resultado_Horario_Fiesta(false, 0, "El horario de fin debe ser posterior al de inicio")
		duracion = 1440 - m_ini
	elif cruce:
		duracion = (1440 - m_ini) + m_fin
	else:
		if m_fin <= m_ini:
			return _Resultado_Horario_Fiesta(false, 0, "El horario de fin debe ser posterior al de inicio")
		duracion = m_fin - m_ini

	# Coherencia de días. En un cruce se acepta el mismo día (se normaliza al
	# siguiente) o el día siguiente, incluido el salto domingo(6)->lunes(0).
	if fin_es_24:
		pass
	elif cruce:
		var dia_siguiente: int = (dia_inicio + 1) % 7
		if dia_final != dia_inicio and dia_final != dia_siguiente and dia_final != dia_inicio + 1:
			return _Resultado_Horario_Fiesta(false, 0, "El horario de fin debe ser posterior al de inicio")
	else:
		if dia_final != dia_inicio:
			return _Resultado_Horario_Fiesta(false, 0, "El horario de fin debe ser posterior al de inicio")

	if duracion < 120:
		return _Resultado_Horario_Fiesta(false, 0, "La fiesta debe durar al menos 2 horas")
	if duracion > 720:
		return _Resultado_Horario_Fiesta(false, 0, "La fiesta no puede durar más de 12 horas")

	if semana >= 0:
		if semana > 81:
			return _Resultado_Horario_Fiesta(false, 0, "El bloque se sale del calendario")
		var dia_ini_abs: int = semana * 7 + dia_inicio
		var dia_fin_abs: int = dia_ini_abs + (1 if (cruce or fin_es_24) else 0)
		if dia_ini_abs < 0 or dia_ini_abs > FIESTA_MATRIZ_MAX_DIA or dia_fin_abs > FIESTA_MATRIZ_MAX_DIA:
			return _Resultado_Horario_Fiesta(false, 0, "El bloque se sale del calendario")

	return _Resultado_Horario_Fiesta(true, duracion, "")


# Curva pura de un techo gradual: meseta al mínimo y subida lineal hasta el máximo.
func Calcular_Cap_Gradual_Puro(minutos_restantes: int, duracion: int, meseta: int,
		cap_inicial: int, cap_final: int, en_la_calle: bool, dinero: float) -> int:
	var duracion_estado: int = maxi(1, duracion)
	var ventana_bajada: int = maxi(1, duracion_estado - meseta)
	var minutos: int = clampi(minutos_restantes, 0, duracion_estado)
	var cap: int = cap_inicial
	if minutos <= ventana_bajada:
		var progreso_bajada: float = float(ventana_bajada - minutos) / float(ventana_bajada)
		cap = cap_inicial + int(floor(progreso_bajada * float(cap_final - cap_inicial)))
	cap = clampi(cap, cap_inicial, cap_final)
	if en_la_calle or dinero < 0.0:
		return mini(cap, Variables_Estaticas.BANCARROTA_MAX_NECESIDAD)
	return cap


# Curva pura del techo de Resacón: 8 h a 30 y 16 h de subida gradual hasta 100.
func Calcular_Cap_Resacon_Puro(minutos_restantes: int, en_la_calle: bool, dinero: float) -> int:
	return Calcular_Cap_Gradual_Puro(minutos_restantes, FIESTA_DURACION_ESTADO,
		FIESTA_MESETA_ESTADO, 30, 100, en_la_calle, dinero)


# Curva pura del suelo de Euforia: 8 h a 100 y 16 h de bajada gradual hasta 50.
func Calcular_Suelo_Euforia_Puro(minutos_restantes: int, en_la_calle: bool, dinero: float) -> int:
	var minutos: int = clampi(minutos_restantes, 0, FIESTA_DURACION_ESTADO)
	var suelo: int = 100
	if minutos <= FIESTA_VENTANA_BAJADA:
		var progreso_bajada: float = float(FIESTA_VENTANA_BAJADA - minutos) / float(FIESTA_VENTANA_BAJADA)
		suelo = int(floor(100.0 - progreso_bajada * 50.0))
	suelo = clampi(suelo, 50, 100)
	if en_la_calle or dinero < 0.0:
		return mini(suelo, Variables_Estaticas.BANCARROTA_MAX_NECESIDAD)
	return suelo


# Techo genérico para cualquier estado de tipo "cap_gradual" (Resacón, Intoxicación).
func Obtener_Cap_Estado(nombre_estado: String = "Resacon") -> int:
	var def: Dictionary = Variables_Estaticas.Estados_Temporales.get(nombre_estado, {})
	if def.is_empty():
		return 100
	if not Variables_Dinamicas.Estados_Temporales.has(nombre_estado):
		if Variables_Dinamicas.En_La_Calle or Variables_Dinamicas.Dinero < 0:
			return Variables_Estaticas.BANCARROTA_MAX_NECESIDAD
		return 100
	var minutos: int = int(Variables_Dinamicas.Estados_Temporales[nombre_estado])
	return Calcular_Cap_Gradual_Puro(
		minutos,
		int(def.get("duracion", FIESTA_DURACION_ESTADO)),
		int(def.get("meseta", FIESTA_MESETA_ESTADO)),
		int(def.get("cap_inicial", 30)),
		int(def.get("cap_final", 100)),
		Variables_Dinamicas.En_La_Calle,
		Variables_Dinamicas.Dinero)


func Obtener_Cap_Resacon() -> int:
	return Obtener_Cap_Estado(FIESTA_ESTADO_RESACON)


func Obtener_Suelo_Euforia() -> int:
	if not Variables_Dinamicas.Estados_Temporales.has(FIESTA_ESTADO_EUFORIA):
		return 1
	var minutos: int = int(Variables_Dinamicas.Estados_Temporales[FIESTA_ESTADO_EUFORIA])
	return Calcular_Suelo_Euforia_Puro(minutos, Variables_Dinamicas.En_La_Calle, Variables_Dinamicas.Dinero)


func _Añadir_Mensaje_Estado(titulo: String, descripcion: String) -> void:
	var msg = Mensaje.new()
	msg.titulo = titulo
	msg.descripcion = descripcion
	msg.leido = false
	msg.minuto = Variables_Dinamicas.Minute_Day * 1440 + Variables_Dinamicas.Minute_Minute
	Variables_Dinamicas.Mensajes.append(msg)


func Activar_Estado(nombre_estado: String) -> void:
	if not Variables_Estaticas.Estados_Temporales.has(nombre_estado):
		return
	if Variables_Dinamicas.Necesidades_Basicas.size() < 5:
		return
	var def: Dictionary = Variables_Estaticas.Estados_Temporales[nombre_estado]

	# Euforia y Resacón son mutuamente excluyentes: el último sustituye al anterior.
	# Intoxicación es independiente y puede convivir con cualquiera de ellos.
	if nombre_estado == FIESTA_ESTADO_EUFORIA:
		Variables_Dinamicas.Estados_Temporales.erase(FIESTA_ESTADO_RESACON)
	elif nombre_estado == FIESTA_ESTADO_RESACON:
		Variables_Dinamicas.Estados_Temporales.erase(FIESTA_ESTADO_EUFORIA)
	Variables_Dinamicas.Estados_Temporales[nombre_estado] = int(def.get("duracion", FIESTA_DURACION_ESTADO))

	var tipo: String = str(def.get("tipo", ""))
	if tipo == "suelo_gradual":
		var suelo: int = Obtener_Suelo_Euforia()
		var indice_suelo: int = int(def.get("indice", 1))
		if Variables_Dinamicas.En_La_Calle or Variables_Dinamicas.Dinero < 0:
			Variables_Dinamicas.Necesidades_Basicas[indice_suelo] = mini(
				Variables_Estaticas.BANCARROTA_MAX_NECESIDAD,
				maxi(Variables_Dinamicas.Necesidades_Basicas[indice_suelo], suelo))
		else:
			Variables_Dinamicas.Necesidades_Basicas[indice_suelo] = maxi(
				Variables_Dinamicas.Necesidades_Basicas[indice_suelo], suelo)
	elif tipo == "cap_gradual":
		var cap: int = Obtener_Cap_Estado(nombre_estado)
		for indice in def.get("indices", []):
			if int(indice) >= 0 and int(indice) < Variables_Dinamicas.Necesidades_Basicas.size():
				Variables_Dinamicas.Necesidades_Basicas[int(indice)] = mini(
					Variables_Dinamicas.Necesidades_Basicas[int(indice)], cap)

	var titulo: String = str(def.get("titulo_inicio", nombre_estado))
	_Añadir_Mensaje_Estado(titulo, str(def.get("mensaje_inicio", "")))


func Tick_Estados() -> void:
	if Variables_Dinamicas.Estados_Temporales.is_empty():
		return
	if Variables_Dinamicas.Necesidades_Basicas.size() < 5:
		return
	for nombre in Variables_Dinamicas.Estados_Temporales.keys():
		var minutos: int = int(Variables_Dinamicas.Estados_Temporales[nombre])
		var def: Dictionary = Variables_Estaticas.Estados_Temporales.get(nombre, {})
		var tipo: String = str(def.get("tipo", ""))
		if tipo == "suelo_gradual":
			var suelo: int = Obtener_Suelo_Euforia()
			var indice_suelo: int = int(def.get("indice", 1))
			if Variables_Dinamicas.Necesidades_Basicas[indice_suelo] < suelo:
				Variables_Dinamicas.Necesidades_Basicas[indice_suelo] = suelo
		elif tipo == "cap_gradual":
			var cap: int = Obtener_Cap_Estado(nombre)
			for indice in def.get("indices", []):
				if int(indice) >= 0 and int(indice) < Variables_Dinamicas.Necesidades_Basicas.size():
					if Variables_Dinamicas.Necesidades_Basicas[int(indice)] > cap:
						Variables_Dinamicas.Necesidades_Basicas[int(indice)] = cap

		minutos -= 1
		if minutos <= 0:
			Variables_Dinamicas.Estados_Temporales.erase(nombre)
			var titulo_fin: String = str(def.get("titulo_fin", "Fin de " + nombre))
			_Añadir_Mensaje_Estado(titulo_fin, str(def.get("mensaje_fin", "")))
		else:
			Variables_Dinamicas.Estados_Temporales[nombre] = minutos


func _Es_Fiesta(celda) -> bool:
	return celda is Actividad and celda.nombre == FIESTA_NOMBRE


func Es_Primer_Minuto_Del_Bloque(i: int, j: int) -> bool:
	var matriz = Variables_Dinamicas.Matriz_Jugador
	if matriz.is_empty() or matriz[0].is_empty():
		return true
	var i_prev: int = i
	var j_prev: int = j - 1
	if j_prev < 0:
		j_prev = 1439
		i_prev -= 1
	if i_prev < 0 or i_prev >= matriz[0].size() or j_prev < 0 or j_prev >= matriz.size():
		return true
	return not _Es_Fiesta(matriz[j_prev][i_prev])


func Es_Ultimo_Minuto_Del_Bloque(i: int, j: int, actividad: Actividad) -> bool:
	var matriz = Variables_Dinamicas.Matriz_Jugador
	if matriz.is_empty() or matriz[0].is_empty() or actividad == null:
		return false
	var i_next: int = i
	var j_next: int = j + 1
	if j_next >= 1440:
		j_next = 0
		i_next += 1
	if i_next < 0 or i_next >= matriz[0].size() or j_next < 0 or j_next >= matriz.size():
		return true
	var celda_next = matriz[j_next][i_next]
	return not (celda_next is Actividad and celda_next.nombre == actividad.nombre)


func Resolver_Evento_Fiesta() -> void:
	if Variables_Dinamicas.Fiesta_Evento_Ocurrido:
		return
	if Variables_Dinamicas.Necesidades_Basicas.size() < 5 or Variables_Dinamicas.Progreso.size() < 3:
		return
	var edad: int = Variables_Estaticas.Calcular_Edad(Variables_Dinamicas.Minute_Day)
	var personalidad: String = Variables_Estaticas.Personalidad
	var hora: int = int(Variables_Dinamicas.Minute_Minute / 60)
	var dia_noche: int = Obtener_Dia_Semana_Noche(Variables_Dinamicas.Minute_Day, hora)
	var pl: float = Calcular_Prob_Ligar_Min(
		Calcular_Puntaje_Ligar(Variables_Dinamicas.Necesidades_Basicas, Variables_Dinamicas.Progreso, personalidad, edad),
		dia_noche)
	var pr: float = Calcular_Prob_Resacon_Min(
		Calcular_Aguante_Resacon(Variables_Dinamicas.Necesidades_Basicas, Variables_Dinamicas.Progreso, edad))
	# Dos tiradas independientes; ligar se resuelve primero. Máximo un evento por fiesta.
	if randf() < pl:
		Variables_Dinamicas.Fiesta_Evento_Ocurrido = true
		Activar_Estado(FIESTA_ESTADO_EUFORIA)
	elif randf() < pr:
		Variables_Dinamicas.Fiesta_Evento_Ocurrido = true
		Activar_Estado(FIESTA_ESTADO_RESACON)


func Actualizar_Horario(minutos_a_procesar: int) -> bool:
	for i in range(minutos_a_procesar):
		if Variables_Dinamicas.Minute_Day >= 574:
			Variables_Dinamicas.Muerto = true
			Variables_Dinamicas.Edad_Muerte = Variables_Estaticas.Calcular_Edad(573)
			_Guardar_Log_Muerte()
			Funciones_Globales.Guardar_Matriz()
			return true
		# Carrera de futbolista: inicios/fines de entrenamiento y partido,
		# salario y cambio de temporada. Se resuelve antes de ejecutar la celda
		# para que el bloque recién programado ya sea el que se ejecute.
		Sistema_Futbol.Tick_Minuto()
		var celda = Variables_Dinamicas.Matriz_Jugador[Variables_Dinamicas.Minute_Minute][Variables_Dinamicas.Minute_Day]
		var cd_pendiente: Dictionary = Variables_Dinamicas.Carrera_Deportiva_Pendiente
		if cd_pendiente.get("inscrito", false) and cd_pendiente.get("resultado_puesto", -1) == -1:
			if int(Variables_Dinamicas.Minute_Day / 7) == int(cd_pendiente.get("semana_inscripcion", -1)) \
			and (Variables_Dinamicas.Minute_Day % 7) == int(cd_pendiente.get("dia", -1)) \
			and Variables_Dinamicas.Minute_Minute == int(cd_pendiente.get("hora_inicio", -1)):
				get_node("/root/Sistema_Carreras_Deportivas").Calcular_Y_Guardar_Resultado()
		var es_fiesta: bool = _Es_Fiesta(celda)
		if es_fiesta and Es_Primer_Minuto_Del_Bloque(Variables_Dinamicas.Minute_Day, Variables_Dinamicas.Minute_Minute):
			Variables_Dinamicas.Fiesta_Evento_Ocurrido = false
		if celda == null or (celda is String and celda == ""):
			Variables_Dinamicas.Matriz_Jugador[Variables_Dinamicas.Minute_Minute][Variables_Dinamicas.Minute_Day] = "Actividad_Aleatoria"
			Variables_Dinamicas.Matriz_Sucia = true
			Ejecutar_Actividad(Crear_Actividad_Aleatoria(), true)
		elif celda is String and celda == "Actividad_Aleatoria":
			Ejecutar_Actividad(Crear_Actividad_Aleatoria(), true)
		else:
			Ejecutar_Actividad(celda)
			if celda is Actividad and Es_Ultimo_Minuto_Del_Bloque(Variables_Dinamicas.Minute_Day, Variables_Dinamicas.Minute_Minute, celda):
				Actividades_Habilidades.Registrar_Pista_Contextual(celda)

		# Evento especial de fiesta: como máximo uno por bloque (ligar o resacón).
		if es_fiesta and not Variables_Dinamicas.Fiesta_Evento_Ocurrido:
			Resolver_Evento_Fiesta()

		# Tick de eventos aleatorios (despido por higiene, eventos generales)
		get_node("/root/Eventos_Aleatorios").Tick_Eventos(celda)

		# Tick de estados temporales: Euforia/Resacón cuentan sus 24 h siempre.
		Tick_Estados()

		if Variables_Dinamicas.Minute_Minute == 1439:
			Variables_Dinamicas.Minute_Day = Variables_Dinamicas.Minute_Day + 1
			Variables_Dinamicas.Minute_Minute = 0
		else:
			Variables_Dinamicas.Minute_Minute = Variables_Dinamicas.Minute_Minute + 1

		Variables_Dinamicas.Minute = Variables_Dinamicas.Minute + 1

		# Decadencia del progreso por desuso (>5 días sin práctica relacionada)
		Actividades_Habilidades.Comprobar_Decadencia_Progreso()

		# Carrera deportiva: generación semanal el lunes 00:00 y premio al finalizar
		var cd_semana_actual: int = Variables_Dinamicas.Minute_Day / 7
		var cd_dia_semana: int = Variables_Dinamicas.Minute_Day % 7
		var cd_minuto_dia: int = Variables_Dinamicas.Minute_Minute
		if cd_dia_semana == 0 and cd_minuto_dia == 0:
			if not Variables_Dinamicas.Carrera_Deportiva_Pendiente.get("inscrito", false):
				var total_inscritos: int = int(clamp(randfn(100.0, 15.0), 60.0, 140.0))
				Variables_Dinamicas.Carrera_Deportiva_Pendiente["total_inscritos"] = total_inscritos
				Variables_Dinamicas.Carrera_Deportiva_Pendiente["resultado_puesto"] = -1
				Variables_Dinamicas.Carrera_Deportiva_Pendiente["resultado_procesado"] = false
		var cd_pend: Dictionary = Variables_Dinamicas.Carrera_Deportiva_Pendiente
		if cd_pend.get("inscrito", false) \
		and int(cd_pend.get("resultado_puesto", -1)) != -1 \
		and not cd_pend.get("resultado_procesado", false):
			var cd_hora_fin: int = int(cd_pend.get("hora_inicio", -1)) + 60
			if cd_semana_actual == int(cd_pend.get("semana_inscripcion", -1)) \
			and cd_dia_semana == int(cd_pend.get("dia", -1)) \
			and cd_minuto_dia >= cd_hora_fin:
				get_node("/root/Sistema_Carreras_Deportivas").Aplicar_Premio_Y_Notificar()

		# Tick de inversión: fluctúa el valor cada ~480 min (8 horas de juego).
		if Variables_Dinamicas.Esta_Invirtiendo:
			_Tick_Inversion()

		# Cobrar alquiler timer-based (7 días en normal, 1 día en rápido desde Ultima_Fecha_Alquiler).
		# Solo se cobra si estás en alquiler (En_La_Calle == false).
		if not Variables_Dinamicas.En_La_Calle and Variables_Dinamicas.Ultima_Fecha_Alquiler >= 0:
			var minutos_desde_alquiler = Variables_Dinamicas.Minute - Variables_Dinamicas.Ultima_Fecha_Alquiler
			if minutos_desde_alquiler >= Variables_Estaticas.Dias_Por_Anio() * 1440:
				Cobrar_Alquiler()

		# Sistema de carreras: conversión prematrícula → matrícula
		# y disparo del examen automático al terminar la hora programada.
		if Variables_Dinamicas.Carrera_Actual != null:
			var c = Variables_Dinamicas.Carrera_Actual
			var dia_semana_actual = Variables_Dinamicas.Minute_Day % 7
			var minuto_del_dia = Variables_Dinamicas.Minute_Minute

			# Conversión prematrícula → matrícula: Lunes 00:00 (normal) o 00:00 del día elegido (rápido)
			var toca_convertir_prematricula: bool = false
			if c.prematriculado and minuto_del_dia == 0:
				if Variables_Estaticas.Modo_Rapido:
					toca_convertir_prematricula = (Variables_Dinamicas.Minute_Day == c.hora_examen_dia)
				else:
					toca_convertir_prematricula = (dia_semana_actual == 0)

			if toca_convertir_prematricula:
				var costo_matricula = Variables_Estaticas.Obtener_Costo_Matricula(c)
				if Variables_Dinamicas.Dinero >= costo_matricula:
					Variables_Dinamicas.Dinero -= costo_matricula
					c.dinero_matricula_gastado += costo_matricula
					c.matriculado = true
					c.prematriculado = false
					Escribir_Examen_En_Matriz(c)
				else:
					# Sin dinero: cancelar prematrícula silenciosamente
					Limpiar_Examen_De_Matriz(c)
					c.prematriculado = false
					c.hora_examen_dia = -1

			# Fin del examen: cuando termina la hora del examen programado
			# Solo dispara si hay matrícula confirmada
			if c.hora_examen_dia >= 0 and not c.completada and c.matriculado:
				var hora_fin_examen = c.hora_examen_inicio + 60
				var es_dia_examen = (Variables_Dinamicas.Minute_Day == c.hora_examen_dia) if Variables_Estaticas.Modo_Rapido else (dia_semana_actual == c.hora_examen_dia)
				if es_dia_examen and minuto_del_dia >= hora_fin_examen and not c.fin_de_semana_procesado:
					Procesar_Fin_De_Semana_Carrera()

		if Comprobar_Muerte():
			Variables_Dinamicas.Muerto = true
			Variables_Dinamicas.Edad_Muerte = Variables_Estaticas.Calcular_Edad()
			_Guardar_Log_Muerte()
			Funciones_Globales.Guardar_Matriz()
			return true

	_Guardar_Log_Muerte()
	Funciones_Globales.Guardar_Matriz()
	return false


func Procesar_Fin_De_Semana_Carrera():
	var carrera = Variables_Dinamicas.Carrera_Actual
	if carrera == null:
		return
	get_node("/root/Sistema_Examenes").Procesar_Fin_De_Semana(carrera)
	# Marcar como pendiente de ver resultado.
	# El jugador debe pulsar "Ver Resultado" para continuar.
	# La hora del examen y el estado completada NO se tocan aquí:
	# se limpian en Script_Principal cuando el jugador confirma haber visto el resultado.
	carrera.fin_de_semana_procesado = true
	carrera.matriculado = false
	carrera.prematriculado = false

	var msg = Mensaje.new()
	var nota = carrera.ultima_nota_final
	var aprobado = carrera.ultimo_resultado_aprobado
	var estado = "APROBADO" if aprobado else "SUSPENDIDO"
	msg.titulo = "Nota del examen — " + estado
	if carrera.completada:
		var bonus = Variables_Estaticas.Obtener_Bonus_Carrera(get_node("/root/Sistema_Examenes").BONUS_DINERO_CARRERA_COMPLETADA)
		msg.descripcion = "Has sacado un %.1f/100 en %s.\nCarrera completada. Bonus: +%.0f€." % [nota, carrera.nombre, bonus]
	elif aprobado:
		msg.descripcion = "Has sacado un %.1f/100 en %s.\nAvanzas al Año %d." % [nota, carrera.nombre, carrera.año_actual]
	else:
		var costo_mat = Variables_Estaticas.Obtener_Costo_Matricula(carrera)
		msg.descripcion = "Has sacado un %.1f/100 en %s.\nPuedes volver a intentarlo (%.0f€)." % [nota, carrera.nombre, costo_mat]
	msg.leido = false
	msg.minuto = Variables_Dinamicas.Minute_Day * 1440 + Variables_Dinamicas.Minute_Minute
	Variables_Dinamicas.Mensajes.append(msg)


# ---------------- Sistema de Objetos/Muebles ----------------

func Comprar_Objeto(clave: String) -> bool:
	if not Variables_Estaticas.Catalogo_Objetos.has(clave):
		return false
	if Variables_Dinamicas.Objetos_Poseidos.get(clave, false):
		return false
	var objeto: Objeto = Variables_Estaticas.Catalogo_Objetos[clave]
	var precio_actual: float = Variables_Estaticas.Obtener_Precio_Objeto(objeto)
	if Variables_Dinamicas.Dinero < precio_actual:
		return false
	Variables_Dinamicas.Dinero -= precio_actual
	Variables_Dinamicas.Objetos_Poseidos[clave] = true
	Guardar_Variables_Dinamicas.save_game()
	return true


func Vender_Objeto(clave: String) -> bool:
	if not Variables_Dinamicas.Objetos_Poseidos.get(clave, false):
		return false
	var objeto: Objeto = Variables_Estaticas.Catalogo_Objetos[clave]
	# Restricción 1: si es el único objeto que posee de su categoría, no se puede vender.
	if _Es_Unico_De_Categoria(objeto.afecta_a, clave):
		return false
	# Restricción 2: si es el objeto seleccionado, hay que cambiarlo antes.
	if Variables_Dinamicas.Objeto_Seleccionado.get(objeto.afecta_a, "") == clave:
		return false
	var precio_actual: float = Variables_Estaticas.Obtener_Precio_Objeto(objeto)
	Variables_Dinamicas.Dinero += precio_actual * 0.5
	Variables_Dinamicas.Objetos_Poseidos[clave] = false
	Guardar_Variables_Dinamicas.save_game()
	return true


func Seleccionar_Objeto(categoria: String, clave: String) -> bool:
	if not Variables_Dinamicas.Objetos_Poseidos.get(clave, false):
		return false
	var objeto: Objeto = Variables_Estaticas.Catalogo_Objetos[clave]
	if objeto.afecta_a != categoria:
		return false
	Variables_Dinamicas.Objeto_Seleccionado[categoria] = clave
	Guardar_Variables_Dinamicas.save_game()
	return true


func _Es_Unico_De_Categoria(categoria: String, clave: String) -> bool:
	for c in Variables_Dinamicas.Objetos_Poseidos.keys():
		if c == clave:
			continue
		if not Variables_Dinamicas.Objetos_Poseidos[c]:
			continue
		var obj: Objeto = Variables_Estaticas.Catalogo_Objetos.get(c, null)
		if obj != null and obj.afecta_a == categoria:
			return false
	return true


# ---------------- Sistema de Inversiones ----------------
# Evento de mercado: ocurre con probabilidad 1/480 por minuto (~1 vez cada 8 horas).
# Dirección determinada por Progreso_Inversion y Salud_Mental_Al_Invertir (snapshot).
# Auto-venta si Sangre_Fría < 30 y pérdida > 15%.

func _Tick_Inversion():
	if randi() % 480 != 0:
		return
	var progreso = Variables_Dinamicas.Progreso_Inversion
	var mental = Variables_Dinamicas.Salud_Mental_Al_Invertir
	# prob_subida: 0.15 en progreso=1, 0.50 en progreso=50, 0.85 en progreso=100.
	# La salud mental ajusta hasta ±10 puntos porcentuales.
	var tendencia = (progreso - 1.0) / 99.0
	var factor_mental = (mental - 50.0) / 300.0
	var prob_subida = clamp(0.15 + tendencia * 0.70 + factor_mental, 0.05, 0.95)
	var cambio_pct = (randi() % 26 + 5) / 1000.0  # 0.5% a 3.0%
	if randf() < prob_subida:
		Variables_Dinamicas.Valor_Inversion += Variables_Dinamicas.Valor_Inversion * cambio_pct
	else:
		Variables_Dinamicas.Valor_Inversion -= Variables_Dinamicas.Valor_Inversion * cambio_pct
		Variables_Dinamicas.Valor_Inversion = max(0.0, Variables_Dinamicas.Valor_Inversion)

	# Auto-venta por pánico: Sangre_Fría muy baja + pérdida > 15%.
	var sangre_fria = Variables_Estaticas.Habilidades[6]
	if sangre_fria < 30 and Variables_Dinamicas.Dinero_Invertido > 0:
		var pct_cambio = (Variables_Dinamicas.Valor_Inversion - Variables_Dinamicas.Dinero_Invertido) / Variables_Dinamicas.Dinero_Invertido
		if pct_cambio < -0.15:
			_Auto_Vender_Inversion()
			return

	# Mejora de progreso de inversión: 1/20 de probabilidad por evento de mercado.
	if Variables_Dinamicas.Progreso_Inversion < 100:
		if randi() % 20 == 0:
			Variables_Dinamicas.Progreso_Inversion += 1


func _Auto_Vender_Inversion():
	var invertido = Variables_Dinamicas.Dinero_Invertido
	var valor_actual = Variables_Dinamicas.Valor_Inversion
	var pct_perdida = 0.0
	if invertido > 0:
		pct_perdida = (invertido - valor_actual) / invertido * 100.0
	Variables_Dinamicas.Dinero += valor_actual
	Variables_Dinamicas.Esta_Invirtiendo = false
	Variables_Dinamicas.Valor_Inversion = 0.0
	Variables_Dinamicas.Dinero_Invertido = 0.0
	var msg = Mensaje.new()
	msg.titulo = "Inversión retirada automáticamente"
	msg.descripcion = "Tu sangre fría es baja. Al alcanzar un %.0f%% de pérdidas has entrado en pánico y has retirado la inversión (%.0f€ recuperados)." % [pct_perdida, valor_actual]
	msg.leido = false
	msg.minuto = Variables_Dinamicas.Minute_Day * 1440 + Variables_Dinamicas.Minute_Minute
	Variables_Dinamicas.Mensajes.append(msg)
