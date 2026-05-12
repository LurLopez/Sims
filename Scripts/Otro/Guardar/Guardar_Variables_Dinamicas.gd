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
		var save_file = FileAccess.open(save_path,FileAccess.READ)
		game_data=save_file.get_var()
		Variables_Dinamicas.Matriz_Jugador=game_data["Matriz_Jugador"]
		Variables_Dinamicas.Progreso=game_data["Progreso"]
		Variables_Dinamicas.Necesidades_Basicas=game_data["Necesidades_Basicas"]
		Variables_Dinamicas.Dinero=game_data["Dinero"]
		Variables_Dinamicas.Minute=game_data["Minute"]
		Variables_Dinamicas.Minute_Day=game_data["Minute_Day"]
		Variables_Dinamicas.Minute_Minute=game_data["Minute_Minute"]
		save_file=null




func game_data_func():
	var game_data : Dictionary = {
	"Matriz_Jugador":Variables_Dinamicas.Matriz_Jugador,
	"Progreso":Variables_Dinamicas.Progreso,
	"Necesidades_Basicas":Variables_Dinamicas.Necesidades_Basicas,
	"Dinero":Variables_Dinamicas.Dinero,
	"Minute":Variables_Dinamicas.Minute,
	"Minute_Day":Variables_Dinamicas.Minute_Day,
	"Minute_Minute":Variables_Dinamicas.Minute_Minute
	}
	return game_data
