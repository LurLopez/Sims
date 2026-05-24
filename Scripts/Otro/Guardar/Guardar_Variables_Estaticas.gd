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
		# Fallback para saves anteriores que no tenían fecha local: derivar de First_Time_Minute (Unix)
		# usando la zona horaria ACTUAL del dispositivo. Habrá un pequeño desajuste si la zona ha
		# cambiado desde el inicio, pero solo afecta a esta primera carga.
		if game_data.has("First_Time_Year"):
			Variables_Estaticas.First_Time_Year=game_data["First_Time_Year"]
			Variables_Estaticas.First_Time_Month=game_data["First_Time_Month"]
			Variables_Estaticas.First_Time_Day_Of_Month=game_data["First_Time_Day_Of_Month"]
		else:
			var fecha_inicio = Time.get_date_dict_from_unix_time(Variables_Estaticas.First_Time_Minute * 60)
			Variables_Estaticas.First_Time_Year=fecha_inicio["year"]
			Variables_Estaticas.First_Time_Month=fecha_inicio["month"]
			Variables_Estaticas.First_Time_Day_Of_Month=fecha_inicio["day"]
		save_file=null

func game_data_func():
	var game_data : Dictionary = {
	"First_Time" : Variables_Estaticas.First_Time,
	"First_Time_Minute" : Variables_Estaticas.First_Time_Minute,
	"Habilidades" : Variables_Estaticas.Habilidades,
	"Personalidad" : Variables_Estaticas.Personalidad,
	"First_Time_Minute_Day": Variables_Estaticas.First_Time_Minute_Day,
	"First_TIme_Minute_Minute": Variables_Estaticas.First_Time_Minute_Minute,
	"First_Time_Year": Variables_Estaticas.First_Time_Year,
	"First_Time_Month": Variables_Estaticas.First_Time_Month,
	"First_Time_Day_Of_Month": Variables_Estaticas.First_Time_Day_Of_Month
	}
	return game_data
