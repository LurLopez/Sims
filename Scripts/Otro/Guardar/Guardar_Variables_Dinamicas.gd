extends Node

var save_path = "user://guardado//variables//Guardar_Variables_Dinamicas.dat"

func save_game():
	Funciones_Globales.Crear_Todas_Las_Carpetas()
	var game_data : Dictionary = game_data_func()
	var save_file = FileAccess.open(save_path, FileAccess.WRITE)
	save_file.store_var(game_data)
	save_file = null

func load_game():
	var game_data : Dictionary = game_data_func()
	if FileAccess.file_exists(save_path):
		var save_file = FileAccess.open(save_path, FileAccess.READ)
		game_data = save_file.get_var()
		Variables_Dinamicas.Matriz_Jugador = _Strings_A_Matriz(game_data["Matriz_Jugador"])
		Variables_Dinamicas.Progreso = game_data["Progreso"]
		Variables_Dinamicas.Necesidades_Basicas = game_data["Necesidades_Basicas"]
		for i in range(Variables_Dinamicas.Necesidades_Basicas.size()):
			Variables_Dinamicas.Necesidades_Basicas[i] = clamp(Variables_Dinamicas.Necesidades_Basicas[i], 1, 100)
		Variables_Dinamicas.Dinero = game_data["Dinero"]
		Variables_Dinamicas.Minute = game_data["Minute"]
		Variables_Dinamicas.Minute_Day = game_data["Minute_Day"]
		Variables_Dinamicas.Minute_Minute = game_data["Minute_Minute"]
		if game_data.has("Habilidades_Mostradas"):
			Variables_Dinamicas.Habilidades_Mostradas = game_data["Habilidades_Mostradas"]
		else:
			Variables_Dinamicas.Habilidades_Mostradas = [0, 0, 0, 0, 0, 0, 0]
		# Fallback para saves antiguos con 6 entradas: añadir entrada para Sangre_Fria.
		while Variables_Dinamicas.Habilidades_Mostradas.size() < 7:
			Variables_Dinamicas.Habilidades_Mostradas.append(0)
		# Alquiler — fallback para saves antiguos: empiezas con casa y 7 días de gracia.
		if game_data.has("En_La_Calle"):
			Variables_Dinamicas.En_La_Calle = game_data["En_La_Calle"]
			Variables_Dinamicas.Ultima_Fecha_Alquiler = game_data["Ultima_Fecha_Alquiler"]
		else:
			Variables_Dinamicas.En_La_Calle = false
			Variables_Dinamicas.Ultima_Fecha_Alquiler = Variables_Dinamicas.Minute_Day * 1440 + Variables_Dinamicas.Minute_Minute
		# Sistema de Objetos — fallback para saves antiguos: solo posee los básicos seleccionados.
		if game_data.has("Objetos_Poseidos"):
			Variables_Dinamicas.Objetos_Poseidos = game_data["Objetos_Poseidos"]
			Variables_Dinamicas.Objeto_Seleccionado = game_data["Objeto_Seleccionado"]
		else:
			_Inicializar_Objetos_Por_Defecto()
		# Sistema de Carreras — fallback para saves antiguos: ninguna carrera activa.
		if game_data.has("Carrera_Actual_Data"):
			Variables_Dinamicas.Carrera_Actual = _Dict_A_Carrera(game_data["Carrera_Actual_Data"])
		else:
			Variables_Dinamicas.Carrera_Actual = null
		if game_data.has("Carreras_Completadas_Data"):
			var lista = []
			for d in game_data["Carreras_Completadas_Data"]:
				var c = _Dict_A_Carrera(d)
				if c != null:
					lista.append(c)
			Variables_Dinamicas.Carreras_Completadas = lista
		else:
			Variables_Dinamicas.Carreras_Completadas = []
		if game_data.has("Inicio_Semana_Carrera"):
			Variables_Dinamicas.Inicio_Semana_Carrera = game_data["Inicio_Semana_Carrera"]
		else:
			Variables_Dinamicas.Inicio_Semana_Carrera = -1
		if game_data.has("Muerto"):
			Variables_Dinamicas.Muerto = game_data["Muerto"]
			Variables_Dinamicas.Edad_Muerte = game_data["Edad_Muerte"]
		else:
			Variables_Dinamicas.Muerto = false
			Variables_Dinamicas.Edad_Muerte = 0
		Variables_Dinamicas.Prob_Supervivencia_Acumulada = game_data.get("Prob_Supervivencia_Acumulada", 1.0)
		if game_data.has("Mensajes"):
			Variables_Dinamicas.Mensajes = _Array_A_Mensajes(game_data["Mensajes"])
		else:
			Variables_Dinamicas.Mensajes = []
		var trabajo_nombre = game_data.get("Trabajo_Actual", "")
		if trabajo_nombre != "" and Variables_Estaticas.Catalogo_Actividades.has(trabajo_nombre):
			Variables_Dinamicas.Trabajo_Actual = Variables_Estaticas.Catalogo_Actividades[trabajo_nombre]
		else:
			Variables_Dinamicas.Trabajo_Actual = null
		# Sistema de Inversiones — fallback para saves antiguos: sin inversión activa.
		Variables_Dinamicas.Esta_Invirtiendo = game_data.get("Esta_Invirtiendo", false)
		Variables_Dinamicas.Dinero_Invertido = game_data.get("Dinero_Invertido", 0.0)
		Variables_Dinamicas.Valor_Inversion = game_data.get("Valor_Inversion", 0.0)
		Variables_Dinamicas.Salud_Mental_Al_Invertir = game_data.get("Salud_Mental_Al_Invertir", 50)
		# Sistema de Eventos Aleatorios — Cooldown de trabajos
		if game_data.has("Cooldown_Trabajos"):
			Variables_Dinamicas.Cooldown_Trabajos = game_data["Cooldown_Trabajos"]
		else:
			Variables_Dinamicas.Cooldown_Trabajos = {}
		get_node("/root/Eventos_Aleatorios").Limpiar_Cooldowns_Expirados()
		save_file = null

func game_data_func():
	var game_data : Dictionary = {
		"Matriz_Jugador": _Matriz_A_Strings(),
		"Progreso": Variables_Dinamicas.Progreso,
		"Necesidades_Basicas": Variables_Dinamicas.Necesidades_Basicas,
		"Dinero": Variables_Dinamicas.Dinero,
		"Minute": Variables_Dinamicas.Minute,
		"Minute_Day": Variables_Dinamicas.Minute_Day,
		"Minute_Minute": Variables_Dinamicas.Minute_Minute,
		"Habilidades_Mostradas": Variables_Dinamicas.Habilidades_Mostradas,
		"En_La_Calle": Variables_Dinamicas.En_La_Calle,
		"Ultima_Fecha_Alquiler": Variables_Dinamicas.Ultima_Fecha_Alquiler,
		"Objetos_Poseidos": Variables_Dinamicas.Objetos_Poseidos,
		"Objeto_Seleccionado": Variables_Dinamicas.Objeto_Seleccionado,
		"Carrera_Actual_Data": _Carrera_A_Dict(Variables_Dinamicas.Carrera_Actual),
		"Carreras_Completadas_Data": _Carreras_Completadas_A_Array(),
		"Inicio_Semana_Carrera": Variables_Dinamicas.Inicio_Semana_Carrera,
		"Muerto": Variables_Dinamicas.Muerto,
		"Edad_Muerte": Variables_Dinamicas.Edad_Muerte,
		"Prob_Supervivencia_Acumulada": Variables_Dinamicas.Prob_Supervivencia_Acumulada,
		"Mensajes": _Mensajes_A_Array(),
		"Trabajo_Actual": Variables_Dinamicas.Trabajo_Actual.nombre if Variables_Dinamicas.Trabajo_Actual != null else "",
		"Esta_Invirtiendo": Variables_Dinamicas.Esta_Invirtiendo,
		"Dinero_Invertido": Variables_Dinamicas.Dinero_Invertido,
		"Valor_Inversion": Variables_Dinamicas.Valor_Inversion,
		"Salud_Mental_Al_Invertir": Variables_Dinamicas.Salud_Mental_Al_Invertir,
		"Progreso_Inversion": Variables_Dinamicas.Progreso_Inversion,
		"Cooldown_Trabajos": Variables_Dinamicas.Cooldown_Trabajos,
	}
	return game_data


func _Carrera_A_Dict(carrera) -> Dictionary:
	if carrera == null:
		return {}
	var script = carrera.get_script()
	var script_path = script.resource_path if script != null else ""
	return {
		"script_path": script_path,
		"nombre": carrera.nombre,
		"años_totales": carrera.años_totales,
		"costo_matricula_anual": carrera.costo_matricula_anual,
		"año_actual": carrera.año_actual,
		"progreso_actual": carrera.progreso_actual,
		"historial_notas": carrera.historial_notas,
		"num_intentos": carrera.num_intentos,
		"dinero_matricula_gastado": carrera.dinero_matricula_gastado,
		"examen_realizado_esta_semana": carrera.examen_realizado_esta_semana,
		"nota_real_ultima": carrera.nota_real_ultima,
		"libros_desbloqueados": carrera.libros_desbloqueados,
		"completada": carrera.completada,
		"hora_examen_dia": carrera.hora_examen_dia,
		"hora_examen_inicio": carrera.hora_examen_inicio,
		"prematriculado": carrera.prematriculado,
		"matriculado": carrera.matriculado,
		"fin_de_semana_procesado": carrera.fin_de_semana_procesado,
		"ultima_nota_final": carrera.ultima_nota_final,
		"ultimo_resultado_aprobado": carrera.ultimo_resultado_aprobado
	}


func _Dict_A_Carrera(dict: Dictionary):
	if dict.is_empty():
		return null
	var script_path = dict.get("script_path", "")
	if script_path == "":
		return null
	var script_resource = load(script_path)
	if script_resource == null:
		return null
	var carrera = script_resource.new()
	carrera.nombre = dict.get("nombre", carrera.nombre)
	carrera.años_totales = dict.get("años_totales", carrera.años_totales)
	carrera.costo_matricula_anual = dict.get("costo_matricula_anual", carrera.costo_matricula_anual)
	carrera.año_actual = dict.get("año_actual", carrera.año_actual)
	carrera.progreso_actual = dict.get("progreso_actual", carrera.progreso_actual)
	carrera.historial_notas = dict.get("historial_notas", carrera.historial_notas)
	carrera.num_intentos = dict.get("num_intentos", carrera.num_intentos)
	carrera.dinero_matricula_gastado = dict.get("dinero_matricula_gastado", carrera.dinero_matricula_gastado)
	carrera.examen_realizado_esta_semana = dict.get("examen_realizado_esta_semana", carrera.examen_realizado_esta_semana)
	carrera.nota_real_ultima = dict.get("nota_real_ultima", carrera.nota_real_ultima)
	carrera.libros_desbloqueados = dict.get("libros_desbloqueados", carrera.libros_desbloqueados)
	carrera.completada = dict.get("completada", carrera.completada)
	carrera.hora_examen_dia = dict.get("hora_examen_dia", carrera.hora_examen_dia)
	carrera.hora_examen_inicio = dict.get("hora_examen_inicio", carrera.hora_examen_inicio)
	carrera.prematriculado = dict.get("prematriculado", false)
	carrera.matriculado = dict.get("matriculado", false)
	carrera.fin_de_semana_procesado = dict.get("fin_de_semana_procesado", carrera.fin_de_semana_procesado)
	carrera.ultima_nota_final = dict.get("ultima_nota_final", carrera.ultima_nota_final)
	carrera.ultimo_resultado_aprobado = dict.get("ultimo_resultado_aprobado", carrera.ultimo_resultado_aprobado)
	return carrera


func _Carreras_Completadas_A_Array() -> Array:
	var resultado = []
	for c in Variables_Dinamicas.Carreras_Completadas:
		resultado.append(_Carrera_A_Dict(c))
	return resultado


func _Inicializar_Objetos_Por_Defecto():
	Variables_Dinamicas.Objetos_Poseidos = {
		"Cama_Basica": true,
		"Mesa_Basica": true,
		"Ducha_Basica": true
	}
	Variables_Dinamicas.Objeto_Seleccionado = {
		"Dormir": "Cama_Basica",
		"Comer": "Mesa_Basica",
		"Duchar": "Ducha_Basica"
	}

func _Matriz_A_Strings() -> Array:
	var resultado = []
	for fila in Variables_Dinamicas.Matriz_Jugador:
		var nueva_fila = []
		for celda in fila:
			if celda is Actividad:
				nueva_fila.append(celda.nombre)
			else:
				nueva_fila.append(celda)
		resultado.append(nueva_fila)
	return resultado

func _Mensajes_A_Array() -> Array:
	var resultado = []
	for m in Variables_Dinamicas.Mensajes:
		resultado.append({
			"titulo": m.titulo,
			"descripcion": m.descripcion,
			"leido": m.leido,
			"minuto": m.minuto
		})
	return resultado

func _Array_A_Mensajes(lista: Array) -> Array:
	var resultado = []
	for d in lista:
		var m = Mensaje.new()
		m.titulo = d.get("titulo", "")
		m.descripcion = d.get("descripcion", "")
		m.leido = d.get("leido", false)
		m.minuto = d.get("minuto", 0)
		resultado.append(m)
	return resultado

func _Strings_A_Matriz(matriz_guardada: Array) -> Array:
	var catalogo = Variables_Estaticas.Catalogo_Actividades
	var resultado = []
	for fila in matriz_guardada:
		var nueva_fila = []
		for celda in fila:
			if celda is String and celda != "" and celda != "Actividad_Aleatoria":
				nueva_fila.append(catalogo.get(celda, null))
			else:
				nueva_fila.append(celda)
		resultado.append(nueva_fila)
	return resultado
