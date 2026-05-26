extends Node

func Ejecutar_Actividad(actividad: Actividad, es_aleatoria: bool = false):
	# Necesidades básicas SIEMPRE se aplican (incluso en actividades aleatorias),
	# así el personaje no se muere si el jugador no entra durante tiempo.
	Actividades_Necesidades_Basicas.Ejecutar_Actividad_Necesidades_Basicas_Array(actividad.efectos_necesidades_basicas)
	# Progreso y descubrimiento SOLO si la actividad fue programada por el jugador.
	# Una actividad aleatoria mantiene vivo al personaje pero no le hace avanzar
	# habilidades; el jugador debe estar presente para crecer.
	if not es_aleatoria:
		Actividades_Habilidades.Ejecutar_Actividad_Progreso_Array(actividad.efectos_progreso)
		Actividades_Habilidades.Ejecutar_Actividad_Mostrar_Habilidad_Array(actividad.efectos_progreso)
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


func Actualizar_Horario(minutos_a_procesar: int):
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

		# Cobrar alquiler al cruzar a lunes 00:00.
		# Minute_Day % 7 == 0 ⇒ Lunes (las semanas empiezan en lunes en este modelo).
		# Esto se ejecuta tras avanzar, así que la primera ejecución posible es la
		# transición desde domingo 23:59 al lunes 00:00 de la SIGUIENTE semana —
		# nunca cobra el lunes inicial del personaje recién creado.
		if Variables_Dinamicas.Minute_Minute == 0 and Variables_Dinamicas.Minute_Day % 7 == 0:
			Variables_Dinamicas.Dinero -= Variables_Estaticas.ALQUILER_SEMANAL
			# Si el cobro deja al jugador en bancarrota, capar todas las necesidades
			# a 20 de golpe (no esperar a que la siguiente actividad lo haga).
			if Variables_Dinamicas.Dinero < 0:
				for k in range(Variables_Dinamicas.Necesidades_Basicas.size()):
					if Variables_Dinamicas.Necesidades_Basicas[k] > Variables_Estaticas.BANCARROTA_MAX_NECESIDAD:
						Variables_Dinamicas.Necesidades_Basicas[k] = Variables_Estaticas.BANCARROTA_MAX_NECESIDAD
	Funciones_Globales.Guardar_Matriz()
