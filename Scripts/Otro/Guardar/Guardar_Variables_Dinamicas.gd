extends Node

const RUTA_GUARDADO_REAL := "user://guardado//variables//Guardar_Variables_Dinamicas.dat"

var save_path = RUTA_GUARDADO_REAL
var _rle_cache: Dictionary = {}

func save_game():
	# Red de seguridad: una prueba de GUT no debe sobrescribir la partida real
	# si algún test llama a un método de producción que guarda por su cuenta.
	if _Ejecutando_Tests_Gut() and save_path == RUTA_GUARDADO_REAL:
		push_warning("Guardado real bloqueado durante la ejecución de tests GUT")
		return
	Funciones_Globales.Crear_Todas_Las_Carpetas()
	var game_data : Dictionary = game_data_func()
	# Escritura atómica: si el dispositivo se queda sin espacio, la partida
	# anterior permanece intacta. El archivo anterior se conserva como .bak.
	var ruta_temporal: String = save_path + ".tmp"
	var save_file = FileAccess.open(ruta_temporal, FileAccess.WRITE)
	if save_file == null:
		push_error("No se pudo abrir el guardado temporal: %s" % ruta_temporal)
		return
	save_file.store_var(game_data)
	var error_escritura: Error = save_file.get_error()
	save_file = null
	var abs_temporal: String = ProjectSettings.globalize_path(ruta_temporal)
	if error_escritura != OK:
		push_error("Error %d escribiendo el guardado temporal" % error_escritura)
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
		push_error("Error %d reemplazando el guardado principal" % error_renombrado)
		DirAccess.remove_absolute(abs_temporal)

func load_game():
	var game_data : Dictionary = game_data_func()
	var datos_cargados := _Leer_Guardado(save_path)
	if datos_cargados.is_empty() and FileAccess.file_exists(save_path + ".bak"):
		datos_cargados = _Leer_Guardado(save_path + ".bak")
	if not datos_cargados.is_empty():
		game_data = datos_cargados
		var matriz_guardada = game_data["Matriz_Jugador"]
		if matriz_guardada is Dictionary and matriz_guardada.get("formato", "") == "rle":
			Variables_Dinamicas.Matriz_Jugador = _RLE_A_Matriz(matriz_guardada)
		else:
			Variables_Dinamicas.Matriz_Jugador = _Strings_A_Matriz(matriz_guardada)
		_Sanear_Matriz_Cargada()
		Variables_Dinamicas.Progreso = game_data["Progreso"]
		if Variables_Dinamicas.Progreso.size() > 3:
			Variables_Dinamicas.Progreso = Variables_Dinamicas.Progreso.slice(0, 3)
		while Variables_Dinamicas.Progreso.size() < 3:
			Variables_Dinamicas.Progreso.append(1)
		Variables_Dinamicas.Necesidades_Basicas = game_data["Necesidades_Basicas"]
		if Variables_Dinamicas.Necesidades_Basicas.size() > 5:
			Variables_Dinamicas.Necesidades_Basicas = Variables_Dinamicas.Necesidades_Basicas.slice(0, 5)
		while Variables_Dinamicas.Necesidades_Basicas.size() < 5:
			Variables_Dinamicas.Necesidades_Basicas.append(50)
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
		if Variables_Dinamicas.Habilidades_Mostradas.size() > 7:
			Variables_Dinamicas.Habilidades_Mostradas = Variables_Dinamicas.Habilidades_Mostradas.slice(0, 7)
		while Variables_Dinamicas.Habilidades_Mostradas.size() < 7:
			Variables_Dinamicas.Habilidades_Mostradas.append(0)
		if game_data.has("Habilidades_Cap_Notificado"):
			Variables_Dinamicas.Habilidades_Cap_Notificado = game_data["Habilidades_Cap_Notificado"]
		else:
			Variables_Dinamicas.Habilidades_Cap_Notificado = [false, false, false, false, false, false, false]
		if Variables_Dinamicas.Habilidades_Cap_Notificado.size() > 7:
			Variables_Dinamicas.Habilidades_Cap_Notificado = Variables_Dinamicas.Habilidades_Cap_Notificado.slice(0, 7)
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
		# Catálogo ampliado: entrega los muebles básicos de Salón/Estudio/Cocina
		# a partidas creadas antes de existir esas categorías.
		Variables_Estaticas.Asegurar_Objetos_Basicos()
		# Ropa equipable — fallback seguro para saves antiguos y entrega de las
		# prendas gratuitas del armario ampliado.
		Variables_Dinamicas.Objetos_Poseidos["Ropa_Calle"] = true
		Sistema_Cocina.Asegurar_Prendas_Iniciales()
		var ropa_actual: String = str(Variables_Dinamicas.Objeto_Seleccionado.get("Ropa", ""))
		if ropa_actual == "" or not Variables_Estaticas.Catalogo_Objetos.has(ropa_actual) \
				or not bool(Variables_Dinamicas.Objetos_Poseidos.get(ropa_actual, false)):
			Variables_Dinamicas.Objeto_Seleccionado["Ropa"] = "Ropa_Calle"
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
		# Carrera de futbolista — fallback y normalización para saves antiguos.
		Variables_Dinamicas.Carrera_Futbol = _Normalizar_Carrera_Futbol(
			game_data.get("Carrera_Futbol", {}))
		# «El Mánager» — retrocompatible: los saves antiguos cargan bloqueados.
		Variables_Dinamicas.Manager_Estado = Sistema_Manager.Normalizar_Estado(
			game_data.get("Manager_Estado", {}))
		# Minijuego de cocina — fallback y merge recursivo para saves antiguos.
		Variables_Dinamicas.Cocina_Estado = _Normalizar_Cocina_Estado(
			game_data.get("Cocina_Estado", {}))
		if game_data.has("Muerto"):
			Variables_Dinamicas.Muerto = game_data["Muerto"]
			Variables_Dinamicas.Edad_Muerte = game_data["Edad_Muerte"]
		else:
			Variables_Dinamicas.Muerto = false
			Variables_Dinamicas.Edad_Muerte = 0
		# Rejuvenecimiento de la Tienda. Los saves anteriores no traen las claves.
		Variables_Dinamicas.Rejuvenecimiento_Anios = clampi(
			int(game_data.get("Rejuvenecimiento_Anios", 0)), 0, 200)
		Variables_Dinamicas.Tratamientos_Rejuvenecimiento = maxi(
			0, int(game_data.get("Tratamientos_Rejuvenecimiento", 0)))
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
		# El progreso se guardaba desde la primera versión, pero no se cargaba:
		# sin esta línea la habilidad inversora volvía siempre a 1.
		Variables_Dinamicas.Progreso_Inversion = clampi(
			int(game_data.get("Progreso_Inversion", 1)), 1, 100)
		# Historial y estadísticas de la bolsa (saves nuevos).
		Variables_Dinamicas.Inversion_Historial = game_data.get("Inversion_Historial", [])
		Variables_Dinamicas.Inversion_Operaciones = game_data.get("Inversion_Operaciones", [])
		Variables_Dinamicas.Inversion_Eventos = game_data.get("Inversion_Eventos", [])
		Variables_Dinamicas.Inversion_Tendencia = game_data.get("Inversion_Tendencia", 0.0)
		Variables_Dinamicas.Inversion_Ultimo_Evento_Minuto = game_data.get("Inversion_Ultimo_Evento_Minuto", -1)
		Variables_Dinamicas.Inversion_Minuto_Inicio = game_data.get("Inversion_Minuto_Inicio", -1)
		Variables_Dinamicas.Inversion_Aportado_Total = game_data.get("Inversion_Aportado_Total", 0.0)
		Variables_Dinamicas.Inversion_Retirado_Total = game_data.get("Inversion_Retirado_Total", 0.0)
		Variables_Dinamicas.Inversion_Beneficio_Realizado = game_data.get("Inversion_Beneficio_Realizado", 0.0)
		Variables_Dinamicas.Inversion_Num_Aportes = game_data.get("Inversion_Num_Aportes", 0)
		Variables_Dinamicas.Inversion_Num_Retiradas = game_data.get("Inversion_Num_Retiradas", 0)
		Variables_Dinamicas.Inversion_Cierres_Ganadores = game_data.get("Inversion_Cierres_Ganadores", 0)
		Variables_Dinamicas.Inversion_Cierres_Perdedores = game_data.get("Inversion_Cierres_Perdedores", 0)
		Variables_Dinamicas.Inversion_Mejor_Operacion = game_data.get("Inversion_Mejor_Operacion", 0.0)
		Variables_Dinamicas.Inversion_Peor_Operacion = game_data.get("Inversion_Peor_Operacion", 0.0)
		Variables_Dinamicas.Inversion_Eventos_Subida = game_data.get("Inversion_Eventos_Subida", 0)
		Variables_Dinamicas.Inversion_Eventos_Bajada = game_data.get("Inversion_Eventos_Bajada", 0)
		Variables_Dinamicas.Inversion_Panicos = game_data.get("Inversion_Panicos", 0)
		Variables_Dinamicas.Inversion_Minutos_Activos = game_data.get("Inversion_Minutos_Activos", 0)
		Variables_Dinamicas.Inversion_Racha_Actual = game_data.get("Inversion_Racha_Actual", 0)
		Variables_Dinamicas.Inversion_Mejor_Racha = game_data.get("Inversion_Mejor_Racha", 0)
		Variables_Dinamicas.Inversion_Peor_Racha = game_data.get("Inversion_Peor_Racha", 0)
		Variables_Dinamicas.Inversion_Racha_Operaciones = game_data.get("Inversion_Racha_Operaciones", 0)
		Variables_Dinamicas.Inversion_Mejor_Racha_Operaciones = game_data.get("Inversion_Mejor_Racha_Operaciones", 0)
		Variables_Dinamicas.Inversion_Pico_Beneficio = game_data.get("Inversion_Pico_Beneficio", 0.0)
		Variables_Dinamicas.Inversion_Max_Caida = game_data.get("Inversion_Max_Caida", 0.0)
		Sistema_Bolsa.Asegurar_Estado()
		# Sistema de Eventos Aleatorios — Cooldown de trabajos
		if game_data.has("Cooldown_Trabajos"):
			Variables_Dinamicas.Cooldown_Trabajos = game_data["Cooldown_Trabajos"]
		else:
			Variables_Dinamicas.Cooldown_Trabajos = {}
		get_node("/root/Eventos_Aleatorios").Limpiar_Cooldowns_Expirados()
		# La matriz cargada no coincide con la caché RLE de la sesión anterior.
		_rle_cache = {}
		Variables_Dinamicas.Matriz_Sucia = true

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

func _Sanear_Matriz_Cargada() -> void:
	var matriz: Array = Variables_Dinamicas.Matriz_Jugador
	if matriz.size() > 1440:
		matriz = matriz.slice(0, 1440)
	while matriz.size() < 1440:
		var fila_vacia: Array = []
		fila_vacia.resize(574)
		fila_vacia.fill("")
		matriz.append(fila_vacia)
	for i in range(matriz.size()):
		var fila = matriz[i]
		if not (fila is Array):
			var nueva: Array = []
			nueva.resize(574)
			nueva.fill("")
			matriz[i] = nueva
			continue
		if fila.size() > 574:
			fila = fila.slice(0, 574)
			matriz[i] = fila
		while fila.size() < 574:
			fila.append("")
	Variables_Dinamicas.Matriz_Jugador = matriz


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
		"Rejuvenecimiento_Anios": Variables_Dinamicas.Rejuvenecimiento_Anios,
		"Tratamientos_Rejuvenecimiento": Variables_Dinamicas.Tratamientos_Rejuvenecimiento,
		"Prob_Supervivencia_Acumulada": Variables_Dinamicas.Prob_Supervivencia_Acumulada,
		"Mensajes": _Mensajes_A_Array(),
		"Trabajo_Actual": Variables_Dinamicas.Trabajo_Actual.nombre if Variables_Dinamicas.Trabajo_Actual != null else "",
		"Esta_Invirtiendo": Variables_Dinamicas.Esta_Invirtiendo,
		"Dinero_Invertido": Variables_Dinamicas.Dinero_Invertido,
		"Valor_Inversion": Variables_Dinamicas.Valor_Inversion,
		"Salud_Mental_Al_Invertir": Variables_Dinamicas.Salud_Mental_Al_Invertir,
		"Progreso_Inversion": Variables_Dinamicas.Progreso_Inversion,
		"Inversion_Historial": Variables_Dinamicas.Inversion_Historial,
		"Inversion_Operaciones": Variables_Dinamicas.Inversion_Operaciones,
		"Inversion_Eventos": Variables_Dinamicas.Inversion_Eventos,
		"Inversion_Tendencia": Variables_Dinamicas.Inversion_Tendencia,
		"Inversion_Ultimo_Evento_Minuto": Variables_Dinamicas.Inversion_Ultimo_Evento_Minuto,
		"Inversion_Minuto_Inicio": Variables_Dinamicas.Inversion_Minuto_Inicio,
		"Inversion_Aportado_Total": Variables_Dinamicas.Inversion_Aportado_Total,
		"Inversion_Retirado_Total": Variables_Dinamicas.Inversion_Retirado_Total,
		"Inversion_Beneficio_Realizado": Variables_Dinamicas.Inversion_Beneficio_Realizado,
		"Inversion_Num_Aportes": Variables_Dinamicas.Inversion_Num_Aportes,
		"Inversion_Num_Retiradas": Variables_Dinamicas.Inversion_Num_Retiradas,
		"Inversion_Cierres_Ganadores": Variables_Dinamicas.Inversion_Cierres_Ganadores,
		"Inversion_Cierres_Perdedores": Variables_Dinamicas.Inversion_Cierres_Perdedores,
		"Inversion_Mejor_Operacion": Variables_Dinamicas.Inversion_Mejor_Operacion,
		"Inversion_Peor_Operacion": Variables_Dinamicas.Inversion_Peor_Operacion,
		"Inversion_Eventos_Subida": Variables_Dinamicas.Inversion_Eventos_Subida,
		"Inversion_Eventos_Bajada": Variables_Dinamicas.Inversion_Eventos_Bajada,
		"Inversion_Panicos": Variables_Dinamicas.Inversion_Panicos,
		"Inversion_Minutos_Activos": Variables_Dinamicas.Inversion_Minutos_Activos,
		"Inversion_Racha_Actual": Variables_Dinamicas.Inversion_Racha_Actual,
		"Inversion_Mejor_Racha": Variables_Dinamicas.Inversion_Mejor_Racha,
		"Inversion_Peor_Racha": Variables_Dinamicas.Inversion_Peor_Racha,
		"Inversion_Racha_Operaciones": Variables_Dinamicas.Inversion_Racha_Operaciones,
		"Inversion_Mejor_Racha_Operaciones": Variables_Dinamicas.Inversion_Mejor_Racha_Operaciones,
		"Inversion_Pico_Beneficio": Variables_Dinamicas.Inversion_Pico_Beneficio,
		"Inversion_Max_Caida": Variables_Dinamicas.Inversion_Max_Caida,
		"Cooldown_Trabajos": Variables_Dinamicas.Cooldown_Trabajos,
		"Carrera_Futbol": Variables_Dinamicas.Carrera_Futbol.duplicate(true),
		"Manager_Estado": Variables_Dinamicas.Manager_Estado,
		"Estados_Temporales": _Estados_Temporales_Serializables(),
		"Fiesta_Evento_Ocurrido": Variables_Dinamicas.Fiesta_Evento_Ocurrido,
		"Progreso_Cocina": Variables_Dinamicas.Progreso_Cocina,
		"Tuppers": Variables_Dinamicas.Tuppers,
		"Tupper_Seleccionado_Idx": Variables_Dinamicas.Tupper_Seleccionado_Idx,
		"Cocina_Estado": Variables_Dinamicas.Cocina_Estado.duplicate(true),
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


func _Normalizar_Carrera_Futbol(datos) -> Dictionary:
	# Base completa: cualquier save antiguo (o sin la clave) arranca sin nulls.
	var resultado: Dictionary = Variables_Dinamicas.Carrera_Futbol_Por_Defecto()
	if not (datos is Dictionary):
		return resultado

	resultado["Activo"] = bool(datos.get("Activo", false))
	resultado["Division"] = clampi(int(datos.get("Division", 4)), 1, 4)
	resultado["Relacion_Entrenador"] = clampf(float(datos.get("Relacion_Entrenador", 50.0)), 0.0, 100.0)
	resultado["Entrenamientos_Cancelados_Seguidos"] = maxi(0, int(
		datos.get("Entrenamientos_Cancelados_Seguidos", 0)))
	resultado["Partidos_Jugados"] = maxi(0, int(datos.get("Partidos_Jugados", 0)))
	resultado["Goles_Totales"] = maxi(0, int(datos.get("Goles_Totales", 0)))
	resultado["Asistencias_Totales"] = maxi(0, int(datos.get("Asistencias_Totales", 0)))
	resultado["Temporadas_Jugadas"] = maxi(0, int(datos.get("Temporadas_Jugadas", 0)))
	resultado["Titulos_Superliga"] = maxi(0, int(datos.get("Titulos_Superliga", 0)))
	resultado["Salario_Semanal"] = maxi(0, int(datos.get("Salario_Semanal", 150)))
	resultado["Estado_Temporada"] = str(datos.get("Estado_Temporada", "En_Curso"))
	resultado["Entrenamiento_En_Curso"] = bool(datos.get("Entrenamiento_En_Curso", false))
	resultado["Entrenamiento_Fin_Abs"] = int(datos.get("Entrenamiento_Fin_Abs", -1))
	resultado["Partido_En_Curso"] = bool(datos.get("Partido_En_Curso", false))
	resultado["Partido_Jornada"] = clampi(int(datos.get("Partido_Jornada", -1)), -1, 4)
	resultado["Partido_Convocado"] = bool(datos.get("Partido_Convocado", false))
	resultado["Partido_Decisivo"] = bool(datos.get("Partido_Decisivo", false))
	resultado["Partido_Fin_Abs"] = int(datos.get("Partido_Fin_Abs", -1))
	resultado["Ultimo_Dia_Salario"] = int(datos.get("Ultimo_Dia_Salario", -1))
	resultado["Conflicto_Ascenso_Pendiente"] = bool(datos.get("Conflicto_Ascenso_Pendiente", false))
	resultado["Division_Ascenso_Pendiente"] = clampi(int(
		datos.get("Division_Ascenso_Pendiente", 0)), 0, 4)

	var asistencia = datos.get("Entrenamientos_Asistencia", {})
	if asistencia is Dictionary:
		var base_asistencia: Dictionary = resultado["Entrenamientos_Asistencia"]
		for clave in ["Martes", "Jueves", "Diario"]:
			base_asistencia[clave] = bool(asistencia.get(clave, base_asistencia.get(clave, true)))
		resultado["Entrenamientos_Asistencia"] = base_asistencia

	var liga = datos.get("Liga_Domingo", {})
	if liga is Dictionary:
		var liga_base: Dictionary = resultado["Liga_Domingo"]
		liga_base["Jornada_Actual"] = clampi(int(liga.get("Jornada_Actual", 0)), 0, 4)
		liga_base["Puntos_Jugador"] = maxi(0, int(liga.get("Puntos_Jugador", 0)))
		liga_base["Posicion_Regular"] = clampi(int(liga.get("Posicion_Regular", 1)), 1, 4)

		var puntos = liga.get("Puntos_Rivales", [])
		var puntos_norm: Array = [0, 0, 0]
		if puntos is Array:
			for i in range(3):
				if i < puntos.size():
					puntos_norm[i] = maxi(0, int(puntos[i]))
		liga_base["Puntos_Rivales"] = puntos_norm

		var medias = liga.get("Medias_Rivales", [])
		var medias_norm: Array = [45.0, 45.0, 45.0]
		if medias is Array:
			for i in range(3):
				if i < medias.size():
					medias_norm[i] = clampf(float(medias[i]), 0.0, 100.0)
		liga_base["Medias_Rivales"] = medias_norm
		resultado["Liga_Domingo"] = liga_base

	return resultado


func _Normalizar_Cocina_Estado(datos) -> Dictionary:
	var resultado: Dictionary = Variables_Dinamicas.Cocina_Estado_Por_Defecto()
	if not (datos is Dictionary):
		return resultado

	var restaurantes_validos: Array = Sistema_Cocina.ORDEN_RESTAURANTES.duplicate()
	var desbl_raw = datos.get("restaurantes_desbloqueados", [])
	var desbl_norm: Array = []
	if desbl_raw is Array:
		for r in desbl_raw:
			var rid: String = str(r)
			if restaurantes_validos.has(rid) and not desbl_norm.has(rid):
				desbl_norm.append(rid)
	resultado["restaurantes_desbloqueados"] = desbl_norm

	resultado["fondos_cocina"] = maxi(0, int(datos.get("fondos_cocina", 0)))

	var estrellas_raw = datos.get("estrellas_nivel", {})
	var estrellas_norm: Dictionary = {}
	if estrellas_raw is Dictionary:
		for k in estrellas_raw.keys():
			var clave: String = str(k)
			var val: int = clampi(int(estrellas_raw[k]), 0, 3)
			if clave != "" and val > 0:
				estrellas_norm[clave] = val
	resultado["estrellas_nivel"] = estrellas_norm

	var mejoras_raw = datos.get("mejoras", {})
	if mejoras_raw is Dictionary:
		var mejoras_base: Dictionary = resultado["mejoras"]
		for rest_id in restaurantes_validos:
			var rest_raw = mejoras_raw.get(rest_id, {})
			if rest_raw is Dictionary:
				var rest_base: Dictionary = mejoras_base[rest_id]
				for mejora_id in ["plancha", "emplatado", "termostato", "ingredientes", "ambiente"]:
					rest_base[mejora_id] = clampi(int(rest_raw.get(mejora_id, 1)), 1, 3)
				mejoras_base[rest_id] = rest_base
		resultado["mejoras"] = mejoras_base

	# El rango se deriva de las estrellas: cada 20 ★ asciende un rango.
	var estrellas_totales: int = 0
	for valor in estrellas_norm.values():
		estrellas_totales += int(valor)
	resultado["rango_logro"] = Sistema_Cocina.Calcular_Rango_Logro(estrellas_totales)
	resultado["servicios_remunerados_hoy"] = maxi(0, int(datos.get("servicios_remunerados_hoy", 0)))
	resultado["ultimo_dia_remunerado"] = int(datos.get("ultimo_dia_remunerado", -1))
	resultado["plus_nomina_turno_hoy"] = bool(datos.get("plus_nomina_turno_hoy", false))
	return resultado


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
		"Ducha_Basica": true,
		"Ropa_Calle": true
	}
	Variables_Dinamicas.Objeto_Seleccionado = {
		"Dormir": "Cama_Basica",
		"Comer": "Mesa_Basica",
		"Duchar": "Ducha_Basica",
		"Ropa": "Ropa_Calle"
	}
	Sistema_Cocina.Asegurar_Prendas_Iniciales()
	Variables_Estaticas.Asegurar_Objetos_Basicos()

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
	# Atajo para las filas completamente vacías (la mayoría del calendario):
	# se comparan en C++ y se añaden 574 celdas de golpe, sin recorrerlas una a una.
	var fila_vacia: Array = []
	fila_vacia.resize(columnas)
	fila_vacia.fill("")
	for fila in Variables_Dinamicas.Matriz_Jugador:
		if fila == fila_vacia:
			if tiene_actual and actual is String and actual == "":
				contador += columnas
			else:
				if tiene_actual:
					datos.append(actual_str)
					datos.append(contador)
				actual = ""
				actual_str = ""
				contador = columnas
				tiene_actual = true
			continue
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
	var fila_vacia: Array = []
	fila_vacia.resize(columnas)
	fila_vacia.fill("")
	for f in range(filas):
		resultado[f] = fila_vacia.duplicate()

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
		# Las filas ya vienen rellenas con "": no hace falta escribir las celdas
		# de los tramos vacíos, que son la inmensa mayoría del calendario.
		if valor is String and valor == "":
			idx_celda += mini(count, total_celdas - idx_celda)
			continue
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


func _Ejecutando_Tests_Gut() -> bool:
	for arg in OS.get_cmdline_args():
		if str(arg).contains("gut_cmdln.gd"):
			return true
	return false
