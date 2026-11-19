extends Node

var save_path = "user://guardado//variables//Guardar_Variables_Dinamicas.dat"
var _rle_cache: Dictionary = {}

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
		var matriz_guardada = game_data["Matriz_Jugador"]
		if matriz_guardada is Dictionary and matriz_guardada.get("formato", "") == "rle":
			Variables_Dinamicas.Matriz_Jugador = _RLE_A_Matriz(matriz_guardada)
		else:
			Variables_Dinamicas.Matriz_Jugador = _Strings_A_Matriz(matriz_guardada)
		Variables_Dinamicas.Progreso = game_data["Progreso"]
		Variables_Dinamicas.Necesidades_Basicas = game_data["Necesidades_Basicas"]
		for i in range(Variables_Dinamicas.Necesidades_Basicas.size()):
			Variables_Dinamicas.Necesidades_Basicas[i] = clamp(Variables_Dinamicas.Necesidades_Basicas[i], 1, 100)
		Variables_Dinamicas.Dinero = game_data["Dinero"]
		Variables_Dinamicas.Minute = game_data["Minute"]
		Variables_Dinamicas.Minute_Day = game_data["Minute_Day"]
		Variables_Dinamicas.Minute_Minute = game_data["Minute_Minute"]
		# Cocina y tuppers — fallback limpio para partidas antiguas.
		Variables_Dinamicas.Progreso_Cocina = clampi(int(game_data.get("Progreso_Cocina", 1)), 1, 100)
		Variables_Dinamicas.Tuppers = _Normalizar_Tuppers(game_data.get("Tuppers", []))
		Variables_Dinamicas.Tupper_Seleccionado_Idx = int(game_data.get("Tupper_Seleccionado_Idx", -1))
		if Variables_Dinamicas.Tupper_Seleccionado_Idx < 0 \
				or Variables_Dinamicas.Tupper_Seleccionado_Idx >= Variables_Dinamicas.Tuppers.size():
			Variables_Dinamicas.Tupper_Seleccionado_Idx = -1
		Variables_Dinamicas.Minutos_Cocinando_Actuales = 0
		if game_data.has("Habilidades_Mostradas"):
			Variables_Dinamicas.Habilidades_Mostradas = game_data["Habilidades_Mostradas"]
		else:
			Variables_Dinamicas.Habilidades_Mostradas = [0, 0, 0, 0, 0, 0, 0]
		# Fallback para saves antiguos con 6 entradas: añadir entrada para Sangre_Fria.
		while Variables_Dinamicas.Habilidades_Mostradas.size() < 7:
			Variables_Dinamicas.Habilidades_Mostradas.append(0)
		if game_data.has("Habilidades_Cap_Notificado"):
			Variables_Dinamicas.Habilidades_Cap_Notificado = game_data["Habilidades_Cap_Notificado"]
		else:
			Variables_Dinamicas.Habilidades_Cap_Notificado = [false, false, false, false, false, false, false]
		while Variables_Dinamicas.Habilidades_Cap_Notificado.size() < 7:
			Variables_Dinamicas.Habilidades_Cap_Notificado.append(false)
		Variables_Dinamicas.Ultimo_Uso_Progreso = game_data.get("Ultimo_Uso_Progreso", [-1, -1, -1])
		Variables_Dinamicas.Ultimo_Check_Decadencia = game_data.get("Ultimo_Check_Decadencia", [-1, -1, -1])
		Variables_Dinamicas.Ultimas_Pistas_Progreso = game_data.get("Ultimas_Pistas_Progreso", [])
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
		# Mesa_Premium fue retirada del catálogo: limpiar restos de saves antiguos.
		Variables_Dinamicas.Objetos_Poseidos.erase("Mesa_Premium")
		if str(Variables_Dinamicas.Objeto_Seleccionado.get("Comer", "")) == "Mesa_Premium":
			Variables_Dinamicas.Objeto_Seleccionado["Comer"] = "Mesa_Basica"
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
		Variables_Dinamicas.Carrera_Deportiva_Pendiente = game_data.get(
			"Carrera_Deportiva_Pendiente",
			{
				"inscrito": false, "dia": -1, "hora_inicio": -1,
				"semana_inscripcion": -1, "total_inscritos": 0,
				"resultado_puesto": -1, "resultado_procesado": false
			}
		)
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
		_Cargar_Estados_Temporales(game_data)
		Variables_Dinamicas.Fiesta_Evento_Ocurrido = bool(game_data.get("Fiesta_Evento_Ocurrido", false))
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
		"Matriz_Jugador": _Matriz_A_RLE(),
		"Progreso": Variables_Dinamicas.Progreso,
		"Necesidades_Basicas": Variables_Dinamicas.Necesidades_Basicas,
		"Dinero": Variables_Dinamicas.Dinero,
		"Minute": Variables_Dinamicas.Minute,
		"Minute_Day": Variables_Dinamicas.Minute_Day,
		"Minute_Minute": Variables_Dinamicas.Minute_Minute,
		"Habilidades_Mostradas": Variables_Dinamicas.Habilidades_Mostradas,
		"Habilidades_Cap_Notificado": Variables_Dinamicas.Habilidades_Cap_Notificado,
		"Ultimo_Uso_Progreso": Variables_Dinamicas.Ultimo_Uso_Progreso,
		"Ultimo_Check_Decadencia": Variables_Dinamicas.Ultimo_Check_Decadencia,
		"Ultimas_Pistas_Progreso": Variables_Dinamicas.Ultimas_Pistas_Progreso,
		"En_La_Calle": Variables_Dinamicas.En_La_Calle,
		"Ultima_Fecha_Alquiler": Variables_Dinamicas.Ultima_Fecha_Alquiler,
		"Objetos_Poseidos": Variables_Dinamicas.Objetos_Poseidos,
		"Objeto_Seleccionado": Variables_Dinamicas.Objeto_Seleccionado,
		"Carrera_Actual_Data": _Carrera_A_Dict(Variables_Dinamicas.Carrera_Actual),
		"Carreras_Completadas_Data": _Carreras_Completadas_A_Array(),
		"Inicio_Semana_Carrera": Variables_Dinamicas.Inicio_Semana_Carrera,
		"Carrera_Deportiva_Pendiente": Variables_Dinamicas.Carrera_Deportiva_Pendiente,
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
		"Estados_Temporales": _Estados_Temporales_Serializables(),
		"Fiesta_Evento_Ocurrido": Variables_Dinamicas.Fiesta_Evento_Ocurrido,
		"Progreso_Cocina": Variables_Dinamicas.Progreso_Cocina,
		"Tuppers": Variables_Dinamicas.Tuppers,
		"Tupper_Seleccionado_Idx": Variables_Dinamicas.Tupper_Seleccionado_Idx,
	}
	return game_data


func _Estados_Temporales_Serializables() -> Dictionary:
	var resultado: Dictionary = {}
	for clave in Variables_Dinamicas.Estados_Temporales:
		resultado[str(clave)] = int(Variables_Dinamicas.Estados_Temporales[clave])
	return resultado


func _Normalizar_Tuppers(datos) -> Array:
	var resultado: Array = []
	if not (datos is Array):
		return resultado
	var ahora: int = int(Variables_Dinamicas.Minute)
	for d in datos:
		if not (d is Dictionary):
			continue
		var valor_pct = d.get("porcentaje_restante", 100.0)
		if typeof(valor_pct) != TYPE_INT and typeof(valor_pct) != TYPE_FLOAT:
			valor_pct = 100.0
		var pct: float = clampf(float(valor_pct), 0.0, 100.0)
		if pct <= 0.01:
			continue
		var valor_calidad = d.get("calidad", 1)
		if typeof(valor_calidad) != TYPE_INT and typeof(valor_calidad) != TYPE_FLOAT:
			valor_calidad = 1
		var calidad: int = clampi(int(valor_calidad), 1, 100)
		var valor_creacion = d.get("minuto_creacion", ahora)
		if typeof(valor_creacion) != TYPE_INT and typeof(valor_creacion) != TYPE_FLOAT:
			valor_creacion = ahora
		var creacion: int = int(valor_creacion)
		var valor_caducidad = d.get("minuto_caducidad", creacion + Variables_Estaticas.Obtener_Minutos_Caducidad_Tupper())
		if typeof(valor_caducidad) != TYPE_INT and typeof(valor_caducidad) != TYPE_FLOAT:
			valor_caducidad = creacion + Variables_Estaticas.Obtener_Minutos_Caducidad_Tupper()
		var valor_id = d.get("id", resultado.size() + 1)
		if typeof(valor_id) != TYPE_INT and typeof(valor_id) != TYPE_FLOAT:
			valor_id = resultado.size() + 1
		resultado.append({
			"id": int(valor_id),
			"porcentaje_restante": pct,
			"calidad": calidad,
			"minuto_creacion": creacion,
			"minuto_caducidad": int(valor_caducidad)
		})
	return resultado


func _Cargar_Estados_Temporales(game_data: Dictionary) -> void:
	Variables_Dinamicas.Estados_Temporales = {}
	if not game_data.has("Estados_Temporales"):
		return
	var datos = game_data["Estados_Temporales"]
	if not (datos is Dictionary):
		return
	# Filtrar claves desconocidas y valores corruptos; aceptar solo estados del catálogo.
	for clave in datos:
		var nombre := str(clave)
		if not Variables_Estaticas.Estados_Temporales.has(nombre):
			continue
		var valor = datos[clave]
		if typeof(valor) != TYPE_INT and typeof(valor) != TYPE_FLOAT:
			continue
		Variables_Dinamicas.Estados_Temporales[nombre] = clampi(int(valor), 0, 1440)
	# Compatibilidad defensiva: Euforia y Resacon son mutuamente excluyentes.
	# Si un save antiguo/corrupto trae ambos, conservar el que tenga más tiempo restante.
	if Variables_Dinamicas.Estados_Temporales.has("Euforia") and Variables_Dinamicas.Estados_Temporales.has("Resacon"):
		var rest_euforia: int = int(Variables_Dinamicas.Estados_Temporales["Euforia"])
		var rest_resacon: int = int(Variables_Dinamicas.Estados_Temporales["Resacon"])
		if rest_euforia > rest_resacon:
			Variables_Dinamicas.Estados_Temporales.erase("Resacon")
		else:
			Variables_Dinamicas.Estados_Temporales.erase("Euforia")


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
		"ajuste_dificultad": carrera.ajuste_dificultad,
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
	carrera.ajuste_dificultad = dict.get("ajuste_dificultad", carrera.ajuste_dificultad)
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

func _Matriz_A_RLE() -> Dictionary:
	if not Variables_Dinamicas.Matriz_Sucia and not _rle_cache.is_empty():
		return _rle_cache
	var filas: int = Variables_Dinamicas.Matriz_Jugador.size()
	var columnas: int = Variables_Dinamicas.Matriz_Jugador[0].size() if filas > 0 else 0
	var datos: Array = []
	var tiene_actual := false
	var actual = null
	var actual_str: String = ""
	var contador: int = 0
	for fila in Variables_Dinamicas.Matriz_Jugador:
		for celda in fila:
			if tiene_actual and typeof(celda) == typeof(actual) and celda == actual:
				contador += 1
			else:
				if tiene_actual:
					datos.append(actual_str)
					datos.append(contador)
				actual = celda
				tiene_actual = true
				contador = 1
				if celda is Actividad:
					actual_str = celda.nombre
				elif celda is String:
					actual_str = celda
				else:
					actual_str = ""
	if tiene_actual:
		datos.append(actual_str)
		datos.append(contador)
	_rle_cache = {
		"formato": "rle",
		"filas": filas,
		"columnas": columnas,
		"datos": datos
	}
	Variables_Dinamicas.Matriz_Sucia = false
	return _rle_cache


func _RLE_A_Matriz(rle: Dictionary) -> Array:
	var filas: int = rle.get("filas", 1440)
	var columnas: int = rle.get("columnas", 574)
	var datos: Array = rle.get("datos", [])
	var catalogo = Variables_Estaticas.Catalogo_Actividades
	var resultado: Array = []
	resultado.resize(filas)
	for f in range(filas):
		var nueva_fila: Array = []
		nueva_fila.resize(columnas)
		resultado[f] = nueva_fila

	var idx_celda: int = 0
	var total_celdas: int = filas * columnas
	var i: int = 0
	while i + 1 < datos.size() and idx_celda < total_celdas:
		var val_str: String = datos[i]
		var count: int = datos[i + 1]
		i += 2
		var valor
		if val_str != "" and val_str != "Actividad_Aleatoria":
			# Compatibilidad: la antigua actividad gratuita "Comer" ahora es comida rápida.
			var clave_catalogo: String = "Comer_Basura" if val_str == "Comer" else val_str
			valor = catalogo.get(clave_catalogo, null)
		else:
			valor = val_str
		for _k in range(count):
			if idx_celda >= total_celdas:
				break
			var f: int = idx_celda / columnas
			var c: int = idx_celda % columnas
			resultado[f][c] = valor
			idx_celda += 1
	return resultado


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
				var clave_catalogo: String = "Comer_Basura" if celda == "Comer" else celda
				nueva_fila.append(catalogo.get(clave_catalogo, null))
			else:
				nueva_fila.append(celda)
		resultado.append(nueva_fila)
	return resultado
