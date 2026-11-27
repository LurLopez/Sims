extends Node

# Captura QA del hub de Minijuegos con la tarjeta de La Granja y de la apertura
# real del minijuego desde la escena principal.

const DIR_SALIDA := "user://capturas_granja"
const SAVE_DIN := "user://test_captura_granja_din.dat"
const SAVE_EST := "user://test_captura_granja_est.dat"

var _vp: SubViewport
var _main: Node


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR_SALIDA))
	await get_tree().process_frame

	Guardar_Variables_Dinamicas.save_path = SAVE_DIN
	Guardar_Variables_Estaticas.save_path = SAVE_EST
	Variables_Estaticas.First_Time = false
	Variables_Estaticas.Tutorial_Completado = true
	Variables_Estaticas.Habilidades = [50, 50, 50, 50, 50, 50, 50]
	Variables_Estaticas.Personalidad = ""
	Variables_Estaticas.Apariencia = Apariencia_Personaje.por_defecto()
	var fecha := Time.get_date_dict_from_system()
	var hora := Time.get_time_dict_from_system()
	Variables_Estaticas.First_Time_Minute_Day = (int(fecha.get("weekday", 1)) + 6) % 7
	Variables_Estaticas.First_Time_Minute_Minute = int(hora.get("hour", 0)) * 60 + int(hora.get("minute", 0))
	Variables_Estaticas.First_Time_Minute = int(Time.get_unix_time_from_system() / 60)
	Variables_Estaticas.First_Time_Year = int(fecha.get("year", 2026))
	Variables_Estaticas.First_Time_Month = int(fecha.get("month", 1))
	Variables_Estaticas.First_Time_Day_Of_Month = int(fecha.get("day", 1))
	Variables_Dinamicas.Progreso = [50, 50, 50]
	Variables_Dinamicas.Necesidades_Basicas = [70, 70, 70, 70, 70]
	Variables_Dinamicas.Dinero = 1000.0
	Variables_Dinamicas.Minute_Day = Variables_Estaticas.First_Time_Minute_Day
	Variables_Dinamicas.Minute_Minute = Variables_Estaticas.First_Time_Minute_Minute
	Variables_Dinamicas.Minute = Variables_Estaticas.First_Time_Minute
	Variables_Dinamicas.Matriz_Jugador = []
	for i in range(1440):
		var fila: Array = []
		fila.resize(574)
		fila.fill("")
		Variables_Dinamicas.Matriz_Jugador.append(fila)
	Variables_Dinamicas.Habilidades_Mostradas = [0, 0, 0, 0, 0, 0, 0]
	Variables_Dinamicas.Habilidades_Cap_Notificado = [false, false, false, false, false, false, false]
	Variables_Dinamicas.Estados_Temporales = {}
	Variables_Dinamicas.Mensajes = []
	Variables_Dinamicas.En_La_Calle = false
	Variables_Dinamicas.Ultima_Fecha_Alquiler = Variables_Dinamicas.Minute_Day * 1440 + Variables_Dinamicas.Minute_Minute
	Variables_Dinamicas.Muerto = false
	Variables_Dinamicas.Carrera_Actual = null
	Variables_Dinamicas.Trabajo_Actual = null
	Variables_Dinamicas.Cooldown_Trabajos = {}
	Variables_Dinamicas.Objetos_Poseidos = {
		"Cama_Basica": true, "Mesa_Basica": true, "Ducha_Basica": true, "Ropa_Calle": true
	}
	Variables_Dinamicas.Objeto_Seleccionado = {
		"Dormir": "Cama_Basica", "Comer": "Mesa_Basica",
		"Duchar": "Ducha_Basica", "Ropa": "Ropa_Calle"
	}
	Variables_Dinamicas.Cocina_Estado = Variables_Dinamicas.Cocina_Estado_Por_Defecto()
	Variables_Dinamicas.Granja_Estado = Sistema_Granja.Estado_Por_Defecto()

	_vp = SubViewport.new()
	_vp.size = Vector2i(720, 1280)
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)
	_main = load("res://Escenas/Escena_Principal/Escena principal.tscn").instantiate()
	_vp.add_child(_main)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout

	_main.call("_on_minijuegos_button_pressed")
	await get_tree().create_timer(0.4).timeout
	var scroll = _main.get("_minijuegos_scroll")
	if scroll != null:
		scroll.scroll_vertical = 100000
	await get_tree().create_timer(0.3).timeout
	await _Capturar("granja_06_hub.png")

	_vp.size = Vector2i(1280, 720)
	_main.call("_Confirmar_Compra_Granja")
	await get_tree().create_timer(2.2).timeout
	await _Capturar("granja_07_desde_hub.png")

	var granja = _main.get("_granja")
	if granja != null:
		granja.call("_Cerrar")
		await get_tree().create_timer(2.0).timeout
		_vp.size = Vector2i(720, 1280)
		await get_tree().create_timer(0.4).timeout
		await _Capturar("granja_08_header.png")

	print("Capturas de granja/hub en ", ProjectSettings.globalize_path(DIR_SALIDA))
	get_tree().quit()


func _Capturar(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	var imagen := _vp.get_texture().get_image()
	if imagen == null or imagen.is_empty():
		push_error("No se pudo capturar %s" % nombre)
		return
	var ruta := DIR_SALIDA.path_join(nombre)
	var error := imagen.save_png(ruta)
	if error != OK:
		push_error("Error %d guardando %s" % [error, ruta])
	else:
		print("Captura: ", ruta)
