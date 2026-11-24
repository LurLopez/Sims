extends Node

# ============================================================================
# SISTEMA DEL MINIJUEGO "SALIR A CORRER"
#
# Runner infinito de 3 carriles. Este autoload guarda los récords y estadísticas
# del jugador, calcula la recompensa de cada carrera y la aplica al Sim.
#
# La recompensa es intencionadamente sencilla:
# - Progreso de Deporte (1 punto por carrera válida + 1 cada 400 m, máx. 4).
# - Necesidades: salud física/mental suben; hambre, descanso e higiene bajan.
# - Las monedas del runner son puntuación arcade, no dinero del Sim.
#
# El archivo de guardado es independiente de la partida (user://), igual que
# las estadísticas de bienestar.
# ============================================================================

signal records_actualizados
signal carrera_registrada(resumen: Dictionary)

const RUTA_GUARDADO := "user://minijuego_correr.cfg"
const SECCION := "correr"
const VERSION_DATOS := 1
const DISTANCIA_MINIMA_RECOMPENSA := 100.0
const DISTANCIA_POR_PUNTO_DEPORTE := 400.0
const MAX_PUNTOS_DEPORTE := 4
const DISTANCIA_POR_BONUS_NECESIDADES := 500.0
const MONEDAS_POR_PUNTO_PUNTUACION := 10

var _ruta_guardado: String = RUTA_GUARDADO
var _datos: Dictionary = _Datos_Defecto()


func _ready() -> void:
	_Cargar()


func _notification(que: int) -> void:
	match que:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_PREDELETE:
			_Guardar()


# ----------------------------------------------------------------------------
# API pública
# ----------------------------------------------------------------------------

func Obtener_Datos() -> Dictionary:
	return _datos.duplicate(true)


func Obtener_Record_Distancia() -> int:
	return int(floor(float(_datos.get("mejor_distancia", 0.0))))


func Obtener_Record_Puntuacion() -> int:
	return int(_datos.get("mejor_puntuacion", 0))


func Obtener_Monedas_Totales() -> int:
	return int(_datos.get("monedas_totales", 0))


func Obtener_Carreras() -> int:
	return int(_datos.get("carreras", 0))


func Obtener_Distancia_Total() -> int:
	return int(floor(float(_datos.get("distancia_total", 0.0))))


## Calcula el resumen de recompensa sin aplicarlo al Sim. Es una función pura
## para poder probarla con GUT y para enseñar la previsión antes de terminar.
func Calcular_Recompensa(distancia: float, monedas: int) -> Dictionary:
	var metros: float = maxf(0.0, distancia)
	var monedas_validas: int = maxi(0, monedas)
	var valida: bool = metros >= DISTANCIA_MINIMA_RECOMPENSA

	var puntos_deporte: int = 0
	var bonus_necesidades: int = 0
	if valida:
		puntos_deporte = 1 + int(floor(metros / DISTANCIA_POR_PUNTO_DEPORTE))
		puntos_deporte = mini(MAX_PUNTOS_DEPORTE, puntos_deporte)
		bonus_necesidades = int(floor(metros / DISTANCIA_POR_BONUS_NECESIDADES))
		bonus_necesidades = clampi(bonus_necesidades, 0, 2)
		# Las monedas premian la ruta limpia sin convertirse en dinero.
		if monedas_validas >= 30:
			puntos_deporte = mini(MAX_PUNTOS_DEPORTE, puntos_deporte + 1)

	return {
		"valida": valida,
		"distancia": metros,
		"monedas": monedas_validas,
		"deporte": puntos_deporte,
		"salud_fisica": (3 + bonus_necesidades) if valida else 0,
		"salud_mental": (2 + bonus_necesidades) if valida else 0,
		"hambre": -(2 + bonus_necesidades) if valida else 0,
		"descanso": -(2 + bonus_necesidades) if valida else 0,
		"higiene": -(3 + bonus_necesidades) if valida else 0,
	}


## Registra una carrera, actualiza récords y (opcionalmente) aplica la
## recompensa al Sim. Devuelve el resumen completo que consume la UI.
func Registrar_Carrera(distancia: float, monedas: int, aplicar_recompensa: bool = true, puntuacion_final: int = -1) -> Dictionary:
	var metros: float = maxf(0.0, distancia)
	var monedas_validas: int = maxi(0, monedas)
	var puntuacion: int = puntuacion_final if puntuacion_final >= 0 else (int(floor(metros)) + monedas_validas * MONEDAS_POR_PUNTO_PUNTUACION)
	var record_anterior: float = float(_datos.get("mejor_distancia", 0.0))
	var nuevo_record: bool = metros > record_anterior
	var recompensa: Dictionary = Calcular_Recompensa(metros, monedas_validas)

	_datos["carreras"] = int(_datos.get("carreras", 0)) + 1
	_datos["monedas_totales"] = int(_datos.get("monedas_totales", 0)) + monedas_validas
	_datos["distancia_total"] = float(_datos.get("distancia_total", 0.0)) + metros
	_datos["ultima_distancia"] = metros
	_datos["ultima_puntuacion"] = puntuacion
	_datos["ultima_monedas"] = monedas_validas
	if nuevo_record:
		_datos["mejor_distancia"] = metros
	if puntuacion > int(_datos.get("mejor_puntuacion", 0)):
		_datos["mejor_puntuacion"] = puntuacion

	if aplicar_recompensa and bool(recompensa.get("valida", false)):
		_Aplicar_Recompensa(recompensa)
		_datos["recompensas_aplicadas"] = int(_datos.get("recompensas_aplicadas", 0)) + 1

	_Guardar()
	records_actualizados.emit()

	var resumen: Dictionary = {
		"distancia": metros,
		"monedas": monedas_validas,
		"puntuacion": puntuacion,
		"nuevo_record": nuevo_record,
		"record_anterior": record_anterior,
		"mejor_distancia": float(_datos.get("mejor_distancia", 0.0)),
		"mejor_puntuacion": int(_datos.get("mejor_puntuacion", 0)),
		"carreras": int(_datos.get("carreras", 0)),
		"monedas_totales": int(_datos.get("monedas_totales", 0)),
		"recompensa": recompensa,
	}
	carrera_registrada.emit(resumen)
	return resumen


## Formatea metros con separador de miles para la UI: 1234 -> "1.234 m".
func Formatear_Distancia(metros: float) -> String:
	var entero: int = maxi(0, int(floor(metros)))
	var texto: String = str(entero)
	var resultado: String = ""
	var contador: int = 0
	for i in range(texto.length() - 1, -1, -1):
		resultado = texto[i] + resultado
		contador += 1
		if contador == 3 and i > 0:
			resultado = "." + resultado
			contador = 0
	return resultado + " m"


# ----------------------------------------------------------------------------
# Recompensas al Sim
# ----------------------------------------------------------------------------

func _Aplicar_Recompensa(recompensa: Dictionary) -> void:
	var puntos: int = int(recompensa.get("deporte", 0))
	for i in range(puntos):
		if Variables_Dinamicas.Progreso.is_empty():
			break
		Actividades_Habilidades.Cambiar_Progreso(0)

	if not Variables_Dinamicas.Progreso.is_empty():
		while Variables_Dinamicas.Ultimo_Uso_Progreso.size() < 1:
			Variables_Dinamicas.Ultimo_Uso_Progreso.append(-1)
		while Variables_Dinamicas.Ultimo_Check_Decadencia.size() < 1:
			Variables_Dinamicas.Ultimo_Check_Decadencia.append(-1)
		Variables_Dinamicas.Ultimo_Uso_Progreso[0] = Variables_Dinamicas.Minute
		Variables_Dinamicas.Ultimo_Check_Decadencia[0] = Variables_Dinamicas.Minute

	var efectos: Array = [
		["salud_fisica", 0],
		["salud_mental", 1],
		["hambre", 2],
		["descanso", 3],
		["higiene", 4],
	]
	for efecto in efectos:
		var clave: String = str(efecto[0])
		var indice: int = int(efecto[1])
		var valor: int = int(recompensa.get(clave, 0))
		for i in range(abs(valor)):
			if indice >= Variables_Dinamicas.Necesidades_Basicas.size():
				break
			Actividades_Necesidades_Basicas.Cambiar_Necesidades_Basicas(1 if valor > 0 else -1, indice)


# ----------------------------------------------------------------------------
# Guardado / carga
# ----------------------------------------------------------------------------

func _Datos_Defecto() -> Dictionary:
	return {
		"version": VERSION_DATOS,
		"mejor_distancia": 0.0,
		"mejor_puntuacion": 0,
		"monedas_totales": 0,
		"carreras": 0,
		"distancia_total": 0.0,
		"ultima_distancia": 0.0,
		"ultima_puntuacion": 0,
		"ultima_monedas": 0,
		"recompensas_aplicadas": 0,
	}


func _Cargar() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(_ruta_guardado) != OK:
		return
	for clave in _datos.keys():
		if cfg.has_section_key(SECCION, clave):
			_datos[clave] = cfg.get_value(SECCION, clave)
	_Normalizar_Datos()


func _Guardar() -> void:
	if _ruta_guardado == RUTA_GUARDADO and _Ejecutando_Tests_Gut():
		return
	var cfg := ConfigFile.new()
	for clave in _datos.keys():
		cfg.set_value(SECCION, clave, _datos[clave])
	cfg.save(_ruta_guardado)


func _Normalizar_Datos() -> void:
	_datos["version"] = VERSION_DATOS
	_datos["mejor_distancia"] = maxf(0.0, float(_datos.get("mejor_distancia", 0.0)))
	_datos["mejor_puntuacion"] = maxi(0, int(_datos.get("mejor_puntuacion", 0)))
	_datos["monedas_totales"] = maxi(0, int(_datos.get("monedas_totales", 0)))
	_datos["carreras"] = maxi(0, int(_datos.get("carreras", 0)))
	_datos["distancia_total"] = maxf(0.0, float(_datos.get("distancia_total", 0.0)))
	_datos["ultima_distancia"] = maxf(0.0, float(_datos.get("ultima_distancia", 0.0)))
	_datos["ultima_puntuacion"] = maxi(0, int(_datos.get("ultima_puntuacion", 0)))
	_datos["ultima_monedas"] = maxi(0, int(_datos.get("ultima_monedas", 0)))
	_datos["recompensas_aplicadas"] = maxi(0, int(_datos.get("recompensas_aplicadas", 0)))


func _Ejecutando_Tests_Gut() -> bool:
	for arg in OS.get_cmdline_args():
		if str(arg).contains("gut_cmdln.gd"):
			return true
	return false


# ----------------------------------------------------------------------------
# Utilidades para tests (no las usa la UI)
# ----------------------------------------------------------------------------

func Configurar_Ruta_Guardado_Pruebas(ruta: String) -> void:
	_ruta_guardado = ruta
	_datos = _Datos_Defecto()


func Reiniciar_Datos_Pruebas() -> void:
	_datos = _Datos_Defecto()


func Restaurar_Ruta_Guardado_Real() -> void:
	_ruta_guardado = RUTA_GUARDADO
	_Cargar()
