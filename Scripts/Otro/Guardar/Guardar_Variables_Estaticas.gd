extends Node

const RUTA_GUARDADO_REAL := "user://guardado//variables//Guardar_Variables_Estaticas.dat"

var save_path = RUTA_GUARDADO_REAL

func save_game():
	if _Ejecutando_Tests_Gut() and save_path == RUTA_GUARDADO_REAL:
		push_warning("Guardado estático real bloqueado durante la ejecución de tests GUT")
		return
	Funciones_Globales.Crear_Todas_Las_Carpetas()
	var game_data : Dictionary = game_data_func()
	var ruta_temporal: String = save_path + ".tmp"
	var save_file = FileAccess.open(ruta_temporal, FileAccess.WRITE)
	if save_file == null:
		push_error("No se pudo abrir el guardado estático temporal")
		return
	save_file.store_var(game_data)
	var error_escritura: Error = save_file.get_error()
	save_file = null
	var abs_temporal: String = ProjectSettings.globalize_path(ruta_temporal)
	if error_escritura != OK:
		push_error("Error %d escribiendo el guardado estático temporal" % error_escritura)
		DirAccess.remove_absolute(abs_temporal)
		return
	var abs_principal: String = ProjectSettings.globalize_path(save_path)
	var abs_respaldo: String = ProjectSettings.globalize_path(save_path + ".bak")
	if FileAccess.file_exists(save_path):
		if FileAccess.file_exists(save_path + ".bak"):
			DirAccess.remove_absolute(abs_respaldo)
		DirAccess.copy_absolute(abs_principal, abs_respaldo)
	var error_renombrado := DirAccess.rename_absolute(abs_temporal, abs_principal)
	if error_renombrado != OK:
		push_error("Error %d reemplazando el guardado estático principal" % error_renombrado)
		DirAccess.remove_absolute(abs_temporal)


func _Leer_Guardado(ruta: String) -> Dictionary:
	if not FileAccess.file_exists(ruta):
		return {}
	var save_file = FileAccess.open(ruta, FileAccess.READ)
	if save_file == null:
		return {}
	var datos = save_file.get_var()
	save_file = null
	if datos is Dictionary:
		return datos
	return {}


func load_game():
	
	var game_data : Dictionary = game_data_func()
	var datos_cargados := _Leer_Guardado(save_path)
	if datos_cargados.is_empty() and FileAccess.file_exists(save_path + ".bak"):
		datos_cargados = _Leer_Guardado(save_path + ".bak")
	if not datos_cargados.is_empty():
		game_data = datos_cargados
		Variables_Estaticas.First_Time=game_data["First_Time"]
		Variables_Estaticas.Modo_Rapido = game_data.get("Modo_Rapido", false)
		Variables_Estaticas.Tutorial_Completado = game_data.get("Tutorial_Completado", true)
		Variables_Estaticas.First_Time_Minute=game_data["First_Time_Minute"]
		Variables_Estaticas.Habilidades=game_data["Habilidades"]
		# Saneado: saves corruptos pueden traer más de 7 habilidades duplicadas.
		if Variables_Estaticas.Habilidades.size() > 7:
			Variables_Estaticas.Habilidades = Variables_Estaticas.Habilidades.slice(0, 7)
		# Fallback para saves antiguos con 6 habilidades: añadir Sangre_Fria (índice 6) aleatoriamente.
		while Variables_Estaticas.Habilidades.size() < 7:
			Variables_Estaticas.Habilidades.append(Funciones_Globales.Generar_Numero_Aleatorio_Entero(1,100))
		Variables_Estaticas.Personalidad=game_data["Personalidad"]
		Variables_Estaticas.Apariencia = Apariencia_Personaje.normalizar(game_data.get("Apariencia", {}))
		Variables_Estaticas.First_Time_Minute_Day=game_data["First_Time_Minute_Day"]
		Variables_Estaticas.First_Time_Minute_Minute = game_data.get("First_Time_Minute_Minute", game_data.get("First_TIme_Minute_Minute", 0))
		Variables_Estaticas.Record_Max_Niveles_Cocina = maxi(0, int(game_data.get("Record_Max_Niveles_Cocina", 0)))
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

func game_data_func():
	var game_data : Dictionary = {
	"First_Time" : Variables_Estaticas.First_Time,
	"Modo_Rapido" : Variables_Estaticas.Modo_Rapido,
	"Tutorial_Completado" : Variables_Estaticas.Tutorial_Completado,
	"First_Time_Minute" : Variables_Estaticas.First_Time_Minute,
	"Habilidades" : Variables_Estaticas.Habilidades,
	"Personalidad" : Variables_Estaticas.Personalidad,
	"Apariencia" : Apariencia_Personaje.normalizar(Variables_Estaticas.Apariencia),
	"First_Time_Minute_Day": Variables_Estaticas.First_Time_Minute_Day,
	"First_Time_Minute_Minute": Variables_Estaticas.First_Time_Minute_Minute,
	"First_Time_Year": Variables_Estaticas.First_Time_Year,
	"First_Time_Month": Variables_Estaticas.First_Time_Month,
	"First_Time_Day_Of_Month": Variables_Estaticas.First_Time_Day_Of_Month,
	"Record_Max_Niveles_Cocina": Variables_Estaticas.Record_Max_Niveles_Cocina
	}
	return game_data


func _Ejecutando_Tests_Gut() -> bool:
	for arg in OS.get_cmdline_args():
		if str(arg).contains("gut_cmdln.gd"):
			return true
	return false
