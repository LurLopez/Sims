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
		Variables_Dinamicas.Dinero = game_data["Dinero"]
		Variables_Dinamicas.Minute = game_data["Minute"]
		Variables_Dinamicas.Minute_Day = game_data["Minute_Day"]
		Variables_Dinamicas.Minute_Minute = game_data["Minute_Minute"]
		if game_data.has("Habilidades_Mostradas"):
			Variables_Dinamicas.Habilidades_Mostradas = game_data["Habilidades_Mostradas"]
		else:
			Variables_Dinamicas.Habilidades_Mostradas = [0, 0, 0, 0, 0, 0]
		# Alquiler — fallback para saves antiguos: empiezas con casa y 7 días de gracia.
		if game_data.has("En_La_Calle"):
			Variables_Dinamicas.En_La_Calle = game_data["En_La_Calle"]
			Variables_Dinamicas.Ultima_Fecha_Alquiler = game_data["Ultima_Fecha_Alquiler"]
		else:
			Variables_Dinamicas.En_La_Calle = false
			Variables_Dinamicas.Ultima_Fecha_Alquiler = Variables_Dinamicas.Minute_Day * 1440 + Variables_Dinamicas.Minute_Minute
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
		"Ultima_Fecha_Alquiler": Variables_Dinamicas.Ultima_Fecha_Alquiler
	}
	return game_data

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
