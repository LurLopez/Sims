extends Node

func Ejecutar_Actividad(actividad: Actividad, es_aleatoria: bool = false):
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
	# Pago de salario al cruzar el último minuto del día laboral
	if actividad is Actividad_Fija_Trabajo and Variables_Dinamicas.Minute_Minute == actividad.hora_final - 1:
		var horas_trabajadas = (actividad.hora_final - actividad.hora_inicio) / 60.0
		Variables_Dinamicas.Dinero += actividad.salario * horas_trabajadas


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
		2: return Variables_Estaticas.Catalogo_Actividades["Comer"]
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


func Crear_Actividad_Especifica(semana, dia_inicio, dia_final, hora_inicio, hora_final, minuto_inicio, minuto_final, actividad):
	var actividad_obj
	if actividad is String:
		if actividad == "":
			actividad_obj = ""
		else:
			actividad_obj = Variables_Estaticas.Catalogo_Actividades[actividad]
	else:
		actividad_obj = actividad

	var i_inicio = semana * 7 + dia_inicio
	var i_final = semana * 7 + dia_final
	var j_inicio = hora_inicio * 60 + minuto_inicio
	var j_final = hora_final * 60 + minuto_final
	var seguir = true
	while seguir:
		if j_final == 0:
			if i_inicio + 1 >= i_final:
				if j_inicio >= 1439:
					seguir = false
			elif j_inicio >= 1440:
				i_inicio += 1
				j_inicio = 0
		else:
			if i_inicio >= i_final:
				if j_inicio + 1 >= j_final:
					seguir = false
			elif j_inicio >= 1440:
				i_inicio += 1
				j_inicio = 0
		Crear_Actividad(i_inicio, j_inicio, actividad_obj)
		j_inicio += 1
	Guardar_Variables_Estaticas.save_game()
	Guardar_Variables_Dinamicas.save_game()

func Crear_Actividad(i, j, actividad):
	Variables_Dinamicas.Matriz_Jugador[j][i] = actividad


func Cobrar_Alquiler():
	# Solo cobrar si tienes dinero suficiente
	if Variables_Dinamicas.Dinero >= Variables_Estaticas.ALQUILER_SEMANAL:
		Variables_Dinamicas.Dinero -= Variables_Estaticas.ALQUILER_SEMANAL
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
	if Variables_Dinamicas.Dinero >= Variables_Estaticas.ALQUILER_SEMANAL:
		Variables_Dinamicas.En_La_Calle = false
		Variables_Dinamicas.Dinero -= Variables_Estaticas.ALQUILER_SEMANAL
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
	var edad = 18 + int(Variables_Dinamicas.Minute_Day / 7.0)
	var media_nec = 0.0
	for n in Variables_Dinamicas.Necesidades_Basicas:
		media_nec += n
	media_nec /= Variables_Dinamicas.Necesidades_Basicas.size()
	var factor_edad = pow(2.0, (edad - 18) / 10.0)
	var factor_nec = pow(35.0, media_nec / 100.0)
	var max_valor = max(1, int(1_875_000.0 * factor_nec / factor_edad))
	_ultima_prob_muerte_minuto = 1.0 / float(max_valor)
	Variables_Dinamicas.Prob_Supervivencia_Acumulada *= (1.0 - _ultima_prob_muerte_minuto)
	return randi() % max_valor == 0


func _Guardar_Log_Muerte() -> void:
	var edad = 18 + int(Variables_Dinamicas.Minute_Day / 7.0)
	var prob_acum = (1.0 - Variables_Dinamicas.Prob_Supervivencia_Acumulada) * 100.0
	var prob_min = _ultima_prob_muerte_minuto * 100.0
	var uno_en = 0
	if _ultima_prob_muerte_minuto > 0.0:
		uno_en = int(1.0 / _ultima_prob_muerte_minuto)
	print("[Muerte] Edad: %d | P.minuto: %.8f%% (1 en %d) | P.acumulada: %.4f%%" % [edad, prob_min, uno_en, prob_acum])


func Actualizar_Horario(minutos_a_procesar: int) -> bool:
	for i in range(minutos_a_procesar):
		var celda = Variables_Dinamicas.Matriz_Jugador[Variables_Dinamicas.Minute_Minute][Variables_Dinamicas.Minute_Day]
		if celda == null or (celda is String and celda == ""):
			Variables_Dinamicas.Matriz_Jugador[Variables_Dinamicas.Minute_Minute][Variables_Dinamicas.Minute_Day] = "Actividad_Aleatoria"
			Ejecutar_Actividad(Crear_Actividad_Aleatoria(), true)
		elif celda is String and celda == "Actividad_Aleatoria":
			Ejecutar_Actividad(Crear_Actividad_Aleatoria(), true)
		else:
			Ejecutar_Actividad(celda)

		if Variables_Dinamicas.Minute_Minute == 1439:
			Variables_Dinamicas.Minute_Day = Variables_Dinamicas.Minute_Day + 1
			Variables_Dinamicas.Minute_Minute = 0
		else:
			Variables_Dinamicas.Minute_Minute = Variables_Dinamicas.Minute_Minute + 1

		Variables_Dinamicas.Minute = Variables_Dinamicas.Minute + 1

		# Cobrar alquiler timer-based (7 días = 7*1440 minutos desde Ultima_Fecha_Alquiler).
		# Solo se cobra si estás en alquiler (En_La_Calle == false).
		if not Variables_Dinamicas.En_La_Calle and Variables_Dinamicas.Ultima_Fecha_Alquiler >= 0:
			var minutos_desde_alquiler = Variables_Dinamicas.Minute - Variables_Dinamicas.Ultima_Fecha_Alquiler
			if minutos_desde_alquiler >= 7 * 1440:
				Cobrar_Alquiler()

		# Sistema de carreras: conversión prematrícula → matrícula el Lunes 00:00
		# y disparo del examen automático al terminar la hora programada.
		if Variables_Dinamicas.Carrera_Actual != null:
			var c = Variables_Dinamicas.Carrera_Actual
			var dia_semana_actual = Variables_Dinamicas.Minute_Day % 7
			var minuto_del_dia = Variables_Dinamicas.Minute_Minute

			# Lunes 00:00: convertir prematrícula en matrícula
			if dia_semana_actual == 0 and minuto_del_dia == 0 and c.prematriculado:
				if Variables_Dinamicas.Dinero >= c.costo_matricula_anual:
					Variables_Dinamicas.Dinero -= c.costo_matricula_anual
					c.dinero_matricula_gastado += c.costo_matricula_anual
					c.matriculado = true
					c.prematriculado = false
				else:
					# Sin dinero: cancelar prematrícula silenciosamente
					c.prematriculado = false
					c.hora_examen_dia = -1

			# Fin del examen: cuando termina la hora del examen programado
			# Solo dispara si hay matrícula confirmada (500€ pagados)
			if c.hora_examen_dia >= 0 and not c.completada and c.matriculado:
				var hora_fin_examen = c.hora_examen_inicio + 60
				if dia_semana_actual == c.hora_examen_dia and minuto_del_dia >= hora_fin_examen and not c.fin_de_semana_procesado:
					Procesar_Fin_De_Semana_Carrera()

		if Comprobar_Muerte():
			Variables_Dinamicas.Muerto = true
			Variables_Dinamicas.Edad_Muerte = 18 + int(Variables_Dinamicas.Minute_Day / 7.0)
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


# ---------------- Sistema de Objetos/Muebles ----------------

func Comprar_Objeto(clave: String) -> bool:
	if not Variables_Estaticas.Catalogo_Objetos.has(clave):
		return false
	if Variables_Dinamicas.Objetos_Poseidos.get(clave, false):
		return false
	var objeto: Objeto = Variables_Estaticas.Catalogo_Objetos[clave]
	if Variables_Dinamicas.Dinero < objeto.precio:
		return false
	Variables_Dinamicas.Dinero -= objeto.precio
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
	Variables_Dinamicas.Dinero += objeto.precio * 0.5
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
