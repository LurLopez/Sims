extends Node

var save_path = "user://guardado//variables//Guardar_Variables_Estaticas.dat"

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
		Variables_Estaticas.First_Time=game_data["First_Time"]
		Variables_Estaticas.First_Time_Minute=game_data["First_Time_Minute"]
		Variables_Estaticas.Habilidades=game_data["Habilidades"]
		Variables_Estaticas.Personalidad=game_data["Personalidad"]
		Variables_Estaticas.First_Time_Minute_Day=game_data["First_Time_Minute_Day"]
		Variables_Estaticas.First_Time_Minute_Minute=game_data["First_TIme_Minute_Minute"]
		save_file=null

func game_data_func():
	var game_data : Dictionary = {
	"First_Time" : Variables_Estaticas.First_Time,
	"First_Time_Minute" : Variables_Estaticas.First_Time_Minute,
	"Habilidades" : Variables_Estaticas.Habilidades,
	"Personalidad" : Variables_Estaticas.Personalidad,
	"First_Time_Minute_Day": Variables_Estaticas.First_Time_Minute_Day,
	"First_TIme_Minute_Minute": Variables_Estaticas.First_Time_Minute_Minute
	}
	return game_data
