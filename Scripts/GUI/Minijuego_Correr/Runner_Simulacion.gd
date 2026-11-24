class_name Runner_Simulacion
extends RefCounted

# ============================================================================
# SIMULACIÓN PURA DEL RUNNER 3D "SALIR A CORRER" (PARK RUSH 3D)
#
# Lógica determinista sin dependencias de nodos 3D ni escena. Port fiel de las
# mecánicas observadas en Subway Surfers Web (Poki) adaptadas a la escala del
# Sim: tres carriles, salto, rodar, tropiezos con segundo aviso, tabla
# hoverboard de 30 s, imán, x2, súper zapatillas, jetpack, pogo, llaves de
# reanimación, trenes en movimiento, rampas a los techos, monedas y retos.
#
# El jugador conserva SIEMPRE el modelo 3D del Sim del proyecto; aquí solo
# vive la física y el estado que consume Runner_Mundo.gd.
# ============================================================================

# Geometría de 3 carriles (en metros)
const ANCHO_CARRIL: float = 2.7
const CARRIL_MIN: int = -1
const CARRIL_MAX: int = 1
const JUGADOR_Z: float = 0.0
const SPAWN_Z: float = -115.0
const DESPAWN_Z: float = 22.0

# Velocidad y progresión (metros/segundo)
const VELOCIDAD_INICIAL: float = 22.0
const VELOCIDAD_MAX: float = 46.0
const METROS_RAMPA_VELOCIDAD: float = 950.0
const VELOCIDAD_EXTRA_CICLISTA: float = 14.0
const VELOCIDAD_RELATIVA_TREN_MIN: float = -8.0
const VELOCIDAD_RELATIVA_TREN_MAX: float = 10.0

# Física del corredor
const SUAVIZADO_CARRIL: float = 17.0
const VELOCIDAD_SALTO: float = 14.2
const VELOCIDAD_SUPER_SALTO: float = 19.6
const GRAVEDAD: float = 42.0
const VELOCIDAD_CAIDA_RAPIDA: float = -28.0
const DURACION_RODAR: float = 0.62
const BUFFER_ENTRADA_SEG: float = 0.15

# Dimensiones (metros)
const ALTURA_JUGADOR_NORMAL: float = 1.75
const ALTURA_JUGADOR_RODAR: float = 0.78
const ALTURA_PLATAFORMA: float = 3.05
const LARGO_PLATAFORMA: float = 13.5
const LARGO_RAMPA: float = 6.2
const ALTURA_CICLISTA: float = 1.95
const LARGO_CICLISTA: float = 2.6
const ALTURA_VALLA: float = 1.15
const HUECO_ARCO_ALTO: float = 1.05
const TECHO_ARCO_ALTO: float = 2.60

# Trenes en movimiento (mismas dimensiones que el vagón aparcado)
const LARGO_TREN_MOVIL: float = 13.5
const ALTURA_TREN_MOVIL: float = 3.05
const VAGONES_TREN_LARGO: int = 3
const LARGO_VAGON: float = 13.5
const LARGO_TREN_LARGO: float = LARGO_VAGON * float(VAGONES_TREN_LARGO)

# Túnel bajo: activa la cámara rasante sin ser un obstáculo sólido
const LARGO_TUNEL: float = 18.0
const ALTURA_TUNEL: float = 5.2

# Power-ups y gracia
const DURACION_IMAN: float = 11.0
const DURACION_ZAPATILLAS: float = 11.0
const DURACION_MULTIPLICADOR: float = 13.0
const DURACION_TABLA: float = 30.0
const DURACION_JETPACK: float = 9.0
const DURACION_POGO: float = 4.6
const ALTURA_VUELO_JETPACK: float = 7.8
const ALTURA_MAXIMA_POGO: float = 8.5
const DISTANCIA_POGO: float = 78.0
const TABLAS_INICIALES: int = 3
const VENTANA_TROPIEZO_SEG: float = 3.0
const DURACION_TROPEZON: float = 3.0
const RALENTI_TROPEZON_SEG: float = 0.85
const FACTOR_RALENTI_TROPEZON: float = 0.62
const INVULNERABLE_TRAS_TABLA_SEG: float = 1.35
const INVULNERABLE_TRAS_REVIVIR_SEG: float = 2.0

# Puntuación y oleadas
const PUNTOS_POR_METRO: float = 10.0
const PUNTOS_POR_MONEDA: int = 0
const PUNTOS_POR_MISION: int = 750
const METROS_APERTURA_SEGURA: float = 42.0
const BRECHA_OLEADA_MIN: float = 22.0
const FACTOR_BRECHA_VELOCIDAD: float = 0.62
const INTERVALO_HITO_METROS: int = 250
const DISTANCIA_GUARDIA_LEJOS: float = 48.0
const DISTANCIA_GUARDIA_CEBO: float = 4.5

const CATALOGO_MISIONES: Array[Dictionary] = [
	{"id": "monedas", "texto": "Recoge 40 monedas", "objetivo": 40},
	{"id": "saltos", "texto": "Salta 10 veces", "objetivo": 10},
	{"id": "rodadas", "texto": "Rueda 6 veces", "objetivo": 6},
	{"id": "carriles", "texto": "Cambia de carril 15 veces", "objetivo": 15},
	{"id": "metros", "texto": "Corre 800 m", "objetivo": 800},
	{"id": "tabla", "texto": "Usa la tabla 1 vez", "objetivo": 1},
]

# Estado global de la carrera
var distancia: float = 0.0
var puntuacion: float = 0.0
var monedas: int = 0
var llaves: int = 0
var velocidad: float = VELOCIDAD_INICIAL
var tablas_restantes: int = TABLAS_INICIALES
var guardia_distancia: float = DISTANCIA_GUARDIA_LEJOS
var misiones: Array[Dictionary] = []

var powerups: Dictionary = {
	"iman": 0.0,
	"zapatillas": 0.0,
	"multiplicador": 0.0,
	"tabla": 0.0,
	"jetpack": 0.0,
	"pogo": 0.0,
}

# Estado del corredor
var jugador: Dictionary = {}

# Entidades activas (Arrays de Dictionary con id único)
var obstaculos: Array[Dictionary] = []
var monedas_entidades: Array[Dictionary] = []
var powerups_entidades: Array[Dictionary] = []

var _siguiente_oleada_dist: float = METROS_APERTURA_SEGURA
var _proximo_powerup_dist: float = 140.0
var _proxima_llave_dist: float = 420.0
var _siguiente_id: int = 1
var _ultimo_paso_idx: int = -1
var _proximo_hito: int = INTERVALO_HITO_METROS
var _rng := RandomNumberGenerator.new()
var _mision_pendiente: String = ""
var _ralenti_tropiezo: float = 0.0
var _ultimo_metro_mision: int = 0


func _init() -> void:
	_rng.randomize()
	reiniciar()


func configurar_semilla(semilla: int) -> void:
	_rng.seed = semilla


func reiniciar(sembrar_inicio: bool = true) -> void:
	distancia = 0.0
	puntuacion = 0.0
	monedas = 0
	llaves = 0
	velocidad = VELOCIDAD_INICIAL
	tablas_restantes = TABLAS_INICIALES
	guardia_distancia = DISTANCIA_GUARDIA_LEJOS
	powerups = {
		"iman": 0.0,
		"zapatillas": 0.0,
		"multiplicador": 0.0,
		"tabla": 0.0,
		"jetpack": 0.0,
		"pogo": 0.0,
	}
	jugador = _crear_estado_jugador()
	obstaculos.clear()
	monedas_entidades.clear()
	powerups_entidades.clear()
	_siguiente_oleada_dist = METROS_APERTURA_SEGURA
	_proximo_powerup_dist = 140.0
	_proxima_llave_dist = 420.0
	_siguiente_id = 1
	_ultimo_paso_idx = -1
	_proximo_hito = INTERVALO_HITO_METROS
	_mision_pendiente = ""
	_ralenti_tropiezo = 0.0
	_ultimo_metro_mision = 0
	_crear_misiones()
	if sembrar_inicio:
		sembrar_pista_inicial()


static func carril_a_x(carril: int) -> float:
	return float(carril) * ANCHO_CARRIL


static func calcular_velocidad(dist: float) -> float:
	var d: float = maxf(0.0, dist)
	var t: float = 1.0 - exp(-d / METROS_RAMPA_VELOCIDAD)
	return VELOCIDAD_INICIAL + (VELOCIDAD_MAX - VELOCIDAD_INICIAL) * t


func obtener_progreso_velocidad() -> float:
	return clampf((velocidad - VELOCIDAD_INICIAL) / (VELOCIDAD_MAX - VELOCIDAD_INICIAL), 0.0, 1.0)


func obtener_multiplicador() -> int:
	return 2 if float(powerups["multiplicador"]) > 0.0 else 1


func esta_vivo() -> bool:
	var estado: String = str(jugador.get("estado", "CORRIENDO"))
	return estado != "CHOCADO" and estado != "CAIDO"


func esta_reanimable() -> bool:
	return str(jugador.get("estado", "CORRIENDO")) == "CAIDO"


func _crear_estado_jugador() -> Dictionary:
	return {
		"estado": "CORRIENDO", # CORRIENDO | SALTANDO | RODANDO | TROPEZANDO | VOLANDO | POGO | CAIDO | CHOCADO
		"carril_objetivo": 0,
		"x": 0.0,
		"y": 0.0,
		"vy": 0.0,
		"suelo_y": 0.0,
		"en_techo": false,
		"inclinacion_z": 0.0,
		"tiempo_rodar": 0.0,
		"duracion_rodar": DURACION_RODAR,
		"tiempo_tropiezo": 0.0,
		"anim_tropiezo": 0.0,
		"ciclo_carrera": 0.0,
		"squash_x": 1.0,
		"squash_y": 1.0,
		"buffer_accion": "",
		"buffer_tiempo": 0.0,
		"invulnerable": 0.0,
		"tunel": false,
		"vuelo_t": 0.0,
		"pogo_z0": 0.0,
		"pogo_y0": 0.0,
		"pogo_progreso": 0.0,
		"tipo_caida": "",
	}


func _crear_misiones() -> void:
	misiones.clear()
	var disponibles: Array[Dictionary] = CATALOGO_MISIONES.duplicate(true)
	for i in range(3):
		var idx: int = _rng.randi_range(0, disponibles.size() - 1)
		var m: Dictionary = disponibles[idx].duplicate(true)
		m["progreso"] = 0
		m["completada"] = false
		m["recompensa"] = PUNTOS_POR_MISION
		misiones.append(m)
		disponibles.remove_at(idx)


## Coloca la pista inicial acogedora: monedas por el centro, vagón aparcado
## a la izquierda y pasarela elevada con rampa a la derecha con monedas arriba.
func sembrar_pista_inicial() -> void:
	for i in range(7):
		var z: float = -15.0 - float(i) * 2.8
		anadir_moneda(0, 0.95, z, float(i) * 0.45)

	anadir_obstaculo("SETO_ALTO", -1, -36.0, 0)
	anadir_obstaculo("PASARELA_RAMPA", 1, -48.0, 1)

	for i in range(6):
		var z: float = -38.5 - float(i) * 2.9
		var en_techo: bool = i >= 2
		var base_y: float = (ALTURA_PLATAFORMA + 0.95) if en_techo else (1.0 + float(i) * 1.05)
		anadir_moneda(1, base_y, z, float(i) * 0.4)


func anadir_obstaculo(tipo: String, carril: int, z: float, librea: int = -1, velocidad_relativa: float = 0.0) -> Dictionary:
	var l: int = librea if librea >= 0 else _rng.randi_range(0, 3)
	var largo: float = 0.7
	var altura: float = ALTURA_VALLA
	var vel_extra: float = 0.0
	var tiene_rampa: bool = false
	var largo_rampa: float = 0.0

	match tipo:
		"SETO_ALTO":
			largo = LARGO_PLATAFORMA
			altura = ALTURA_PLATAFORMA
		"PASARELA_RAMPA":
			largo = LARGO_PLATAFORMA
			altura = ALTURA_PLATAFORMA
			tiene_rampa = true
			largo_rampa = LARGO_RAMPA
		"CICLISTA":
			largo = LARGO_CICLISTA
			altura = ALTURA_CICLISTA
			vel_extra = VELOCIDAD_EXTRA_CICLISTA
		"TREN_MOVIL":
			largo = LARGO_TREN_MOVIL
			altura = ALTURA_TREN_MOVIL
			vel_extra = velocidad_relativa
		"TREN_LARGO":
			largo = LARGO_TREN_LARGO
			altura = ALTURA_PLATAFORMA
		"TREN_LARGO_RAMPA":
			largo = LARGO_TREN_LARGO
			altura = ALTURA_PLATAFORMA
			tiene_rampa = true
			largo_rampa = LARGO_RAMPA
		"VALLA_BAJA":
			largo = 0.7
			altura = ALTURA_VALLA
		"ARCO_ALTO":
			largo = 0.7
			altura = TECHO_ARCO_ALTO
		"TUNEL":
			largo = LARGO_TUNEL
			altura = ALTURA_TUNEL

	var obs := {
		"id": _siguiente_id,
		"tipo": tipo,
		"carril": clampi(carril, CARRIL_MIN, CARRIL_MAX),
		"z": z,
		"largo": largo,
		"altura": altura,
		"velocidad": vel_extra,
		"librea": l,
		"tiene_rampa": tiene_rampa,
		"largo_rampa": largo_rampa,
		"golpeado": false,
	}
	_siguiente_id += 1
	obstaculos.append(obs)
	return obs


func anadir_moneda(carril: int, base_y: float, z: float, fase: float = 0.0) -> Dictionary:
	var c := clampi(carril, CARRIL_MIN, CARRIL_MAX)
	var m := {
		"id": _siguiente_id,
		"carril": c,
		"x": carril_a_x(c),
		"y": base_y,
		"z": z,
		"base_y": base_y,
		"fase": fase,
		"recogida": false,
		"magnetizada": false,
	}
	_siguiente_id += 1
	monedas_entidades.append(m)
	return m


func anadir_powerup(tipo: String, carril: int, y: float, z: float) -> Dictionary:
	var pu := {
		"id": _siguiente_id,
		"tipo": tipo,
		"carril": clampi(carril, CARRIL_MIN, CARRIL_MAX),
		"y": y,
		"z": z,
		"fase": _rng.randf() * TAU,
		"recogido": false,
	}
	_siguiente_id += 1
	powerups_entidades.append(pu)
	return pu


# ----------------------------------------------------------------------------
# Comandos del jugador
# ----------------------------------------------------------------------------

## Aplica un comando: "IZQUIERDA", "DERECHA", "SALTAR", "RODAR", "TABLA".
## Devuelve el resultado inmediato o "" si no aplicó.
func aplicar_comando(comando: String) -> String:
	var estado: String = str(jugador["estado"])
	if estado == "CAIDO" or estado == "CHOCADO":
		return ""

	if comando == "IZQUIERDA" or comando == "DERECHA":
		var dir: int = -1 if comando == "IZQUIERDA" else 1
		var siguiente_carril: int = int(jugador["carril_objetivo"]) + dir
		if siguiente_carril < CARRIL_MIN or siguiente_carril > CARRIL_MAX:
			return ""

		if _carril_bloqueado_lateralmente(siguiente_carril, float(jugador["y"])):
			if float(jugador["tiempo_tropiezo"]) > 0.0 and float(powerups["tabla"]) <= 0.0:
				_caer("lateral")
				return "TROPIEZO_CAIDA"
			if float(jugador["invulnerable"]) <= 0.0:
				_tropezar("lateral")
				jugador["inclinacion_z"] = float(-dir) * 0.32
			return "TROPIEZO"

		jugador["carril_objetivo"] = siguiente_carril
		_progreso_mision("carriles", 1)
		return "CARRIL"

	if comando == "TABLA":
		if estado == "VOLANDO" or estado == "POGO":
			return ""
		if float(powerups["tabla"]) <= 0.0 and tablas_restantes > 0:
			tablas_restantes -= 1
			powerups["tabla"] = DURACION_TABLA
			jugador["squash_x"] = 1.18
			jugador["squash_y"] = 0.86
			jugador["tiempo_tropiezo"] = 0.0
			jugador["anim_tropiezo"] = 0.0
			if str(jugador["estado"]) == "TROPEZANDO":
				jugador["estado"] = "CORRIENDO"
			_progreso_mision("tabla", 1)
			return "TABLA"
		return ""

	if estado == "VOLANDO" or estado == "POGO":
		return ""

	if comando == "SALTAR":
		var en_suelo: bool = float(jugador["y"]) <= float(jugador["suelo_y"]) + 0.08 and float(jugador["vy"]) <= 0.5
		if en_suelo:
			var vel_salto: float = VELOCIDAD_SUPER_SALTO if float(powerups["zapatillas"]) > 0.0 else VELOCIDAD_SALTO
			jugador["vy"] = vel_salto
			jugador["estado"] = "SALTANDO"
			jugador["tiempo_rodar"] = 0.0
			jugador["squash_x"] = 0.84
			jugador["squash_y"] = 1.22
			jugador["buffer_accion"] = ""
			jugador["buffer_tiempo"] = 0.0
			_progreso_mision("saltos", 1)
			return "SALTAR"
		jugador["buffer_accion"] = "SALTAR"
		jugador["buffer_tiempo"] = BUFFER_ENTRADA_SEG
		return ""

	if comando == "RODAR":
		var en_aire: bool = float(jugador["y"]) > float(jugador["suelo_y"]) + 0.10
		jugador["estado"] = "RODANDO"
		jugador["tiempo_rodar"] = DURACION_RODAR
		jugador["duracion_rodar"] = DURACION_RODAR
		jugador["buffer_accion"] = ""
		jugador["buffer_tiempo"] = 0.0
		_progreso_mision("rodadas", 1)
		if en_aire:
			jugador["vy"] = minf(float(jugador["vy"]), VELOCIDAD_CAIDA_RAPIDA)
			jugador["squash_x"] = 1.24
			jugador["squash_y"] = 0.72
			return "CAIDA_RODAR"
		jugador["squash_x"] = 1.20
		jugador["squash_y"] = 0.76
		return "RODAR"

	return ""


func _es_tipo_plataforma(tipo: String) -> bool:
	return tipo == "SETO_ALTO" or tipo == "PASARELA_RAMPA" or tipo == "TREN_LARGO" or tipo == "TREN_LARGO_RAMPA"


func _bloquea_carril(tipo: String) -> bool:
	return _es_tipo_plataforma(tipo) or tipo == "CICLISTA" or tipo == "TREN_MOVIL"


func _carril_bloqueado_lateralmente(carril_objetivo: int, jugador_y: float) -> bool:
	for obs in obstaculos:
		if bool(obs.get("golpeado", false)):
			continue
		if int(obs["carril"]) != carril_objetivo:
			continue
		if not _bloquea_carril(str(obs["tipo"])):
			continue
		var medio_largo: float = float(obs["largo"]) * 0.5
		var frente_z: float = float(obs["z"]) + medio_largo
		var atras_z: float = float(obs["z"]) - medio_largo
		if frente_z > -0.60 and atras_z < 0.60:
			if jugador_y < float(obs["altura"]) - 0.55:
				return true
	return false


## Calcula la altura de soporte bajo el corredor (suelo 0, rampa o pasarela elevada).
func calcular_suelo_soporte(jugador_x: float, jugador_y: float) -> Dictionary:
	var estado: String = str(jugador["estado"])
	if estado == "VOLANDO" or estado == "POGO" or estado == "CAIDO" or estado == "CHOCADO":
		return {"suelo_y": 0.0, "en_techo": false}

	var mejor_suelo: float = 0.0
	var en_techo: bool = false

	for obs in obstaculos:
		if bool(obs.get("golpeado", false)):
			continue
		if not _es_tipo_plataforma(str(obs["tipo"])):
			continue
		var obs_x: float = carril_a_x(int(obs["carril"]))
		if absf(jugador_x - obs_x) > ANCHO_CARRIL * 0.44:
			continue

		var medio_largo: float = float(obs["largo"]) * 0.5
		var frente_z: float = float(obs["z"]) + medio_largo
		var atras_z: float = float(obs["z"]) - medio_largo
		var altura_obs: float = float(obs["altura"])

		# 1. Rampa inclinada delante de la pasarela
		if bool(obs["tiene_rampa"]) and float(obs["largo_rampa"]) > 0.0:
			var inicio_rampa_z: float = frente_z + float(obs["largo_rampa"])
			if 0.0 <= inicio_rampa_z + 0.35 and 0.0 >= frente_z - 0.25:
				var progreso: float = clampf(inicio_rampa_z / float(obs["largo_rampa"]), 0.0, 1.0)
				var altura_rampa: float = progreso * altura_obs
				if jugador_y >= altura_rampa - 1.10 and altura_rampa > mejor_suelo:
					mejor_suelo = altura_rampa
					en_techo = progreso > 0.72

		# 2. Cubierta plana de la pasarela / seto
		if 0.0 <= frente_z + 0.55 and 0.0 >= atras_z - 0.55:
			if jugador_y >= altura_obs - 0.75 and altura_obs > mejor_suelo:
				mejor_suelo = altura_obs
				en_techo = true

	return {"suelo_y": mejor_suelo, "en_techo": en_techo}


# ----------------------------------------------------------------------------
# Generador de oleadas justas (inspirado en las secciones b-s-b / s-s-s-s)
# ----------------------------------------------------------------------------

func generar_oleada(spawn_z: float = SPAWN_Z) -> void:
	var orden: Array[int] = [-1, 0, 1]
	for i in range(orden.size() - 1, 0, -1):
		var j: int = _rng.randi_range(0, i)
		var tmp: int = orden[i]
		orden[i] = orden[j]
		orden[j] = tmp

	# Túnel ocasional: no bloquea, baja la cámara y deja una línea de monedas.
	if distancia > 520.0 and _rng.randf() < 0.08:
		anadir_obstaculo("TUNEL", 0, spawn_z)
		for k in range(6):
			anadir_moneda(0, 0.95, spawn_z + 4.0 - float(k) * 2.6, float(k) * 0.4)
		return

	var dificultad: float = minf(1.0, distancia / 800.0)
	var carril_seguro: int = orden[0]
	var carriles_peligro: Array[int] = [orden[1], orden[2]]
	var usar_dos_peligros: bool = _rng.randf() < (0.45 + dificultad * 0.40)
	var peligros_activos: Array[int] = [carriles_peligro[0]]
	if usar_dos_peligros:
		peligros_activos.append(carriles_peligro[1])

	var carril_rampa: int = -99
	var largo_rampa_actual: float = LARGO_PLATAFORMA
	var carril_valla: int = -99
	var carril_arco: int = -99

	var tirada: float = _rng.randf()
	if tirada < 0.24:
		carril_rampa = carril_seguro
		largo_rampa_actual = LARGO_PLATAFORMA
		anadir_obstaculo("PASARELA_RAMPA", carril_seguro, spawn_z)
	elif tirada < 0.33 and distancia > 450.0:
		carril_rampa = carril_seguro
		largo_rampa_actual = LARGO_TREN_LARGO
		anadir_obstaculo("TREN_LARGO_RAMPA", carril_seguro, spawn_z)
	elif tirada < 0.52:
		carril_valla = carril_seguro
		anadir_obstaculo("VALLA_BAJA", carril_seguro, spawn_z + 3.0)
	elif tirada < 0.70:
		carril_arco = carril_seguro
		anadir_obstaculo("ARCO_ALTO", carril_seguro, spawn_z + 3.0)
	# Resto 30%: carril_seguro completamente libre.

	for i in range(peligros_activos.size()):
		var carril: int = peligros_activos[i]
		var r: float = _rng.randf()
		if r < 0.32:
			anadir_obstaculo("SETO_ALTO", carril, spawn_z - float(i) * 3.5)
		elif r < 0.42 and distancia > 300.0:
			anadir_obstaculo("TREN_LARGO", carril, spawn_z - 10.0)
		elif r < 0.50 and distancia > 70.0:
			anadir_obstaculo("CICLISTA", carril, spawn_z - 18.0)
		elif r < 0.66 and distancia > 120.0:
			var es_express: bool = _rng.randf() < 0.35
			var vel_rel: float = _rng.randf_range(11.0, 19.0) if es_express else _rng.randf_range(VELOCIDAD_RELATIVA_TREN_MIN, 6.0)
			anadir_obstaculo("TREN_MOVIL", carril, spawn_z - 6.0, -1, vel_rel)
		elif r < 0.82:
			if carril_valla == -99:
				carril_valla = carril
			anadir_obstaculo("VALLA_BAJA", carril, spawn_z + 2.0)
		else:
			if carril_arco == -99:
				carril_arco = carril
			anadir_obstaculo("ARCO_ALTO", carril, spawn_z + 2.0)

	# Líneas y arcos de monedas guiando la mejor trayectoria
	if carril_rampa != -99:
		var num_monedas_rampa: int = 12 if largo_rampa_actual > LARGO_PLATAFORMA else 6
		for k in range(num_monedas_rampa):
			var cz: float = spawn_z + largo_rampa_actual * 0.5 + 3.8 - float(k) * 2.8
			var base_y: float = (1.1 + float(k) * 1.1) if k < 2 else (ALTURA_PLATAFORMA + 0.95)
			anadir_moneda(carril_rampa, base_y, cz, float(k) * 0.4)
	elif carril_valla != -99 and _rng.randf() < 0.75:
		for k in range(-2, 3):
			var t: float = float(k + 2) / 4.0
			var base_y: float = 0.95 + sin(t * PI) * 2.15
			anadir_moneda(carril_valla, base_y, spawn_z + 2.0 + float(k) * 2.4, float(k) * 0.45)
	else:
		var carril_monedas: int = carril_arco if carril_arco != -99 else carril_seguro
		var y_monedas: float = 0.65 if carril_arco != -99 else 0.95
		for k in range(5):
			anadir_moneda(carril_monedas, y_monedas, spawn_z + 8.0 - float(k) * 2.7, float(k) * 0.4)

	# Power-up con cadencia similar a las secciones de Subway Surfers (cada
	# ~220-360 m), no en cada oleada.
	if distancia >= _proximo_powerup_dist and _rng.randf() < 0.55:
		var tipo_pu: String = _elegir_powerup()
		var pu_y: float = (ALTURA_PLATAFORMA + 1.2) if carril_rampa != -99 else 1.15
		anadir_powerup(tipo_pu, carril_seguro, pu_y, spawn_z - 4.5)
		_proximo_powerup_dist = distancia + _rng.randf_range(220.0, 360.0)

	# Llave de reanimación garantizada cada ~700 m (en el carril seguro).
	if distancia >= _proxima_llave_dist:
		anadir_powerup("LLAVE", carril_seguro, 1.30, spawn_z - 12.0)
		_proxima_llave_dist = distancia + 700.0


func _elegir_powerup() -> String:
	var tirada: float = _rng.randf() * 132.0
	if tirada < 26.0:
		return "IMAN"
	if tirada < 52.0:
		return "MULTIPLICADOR"
	if tirada < 75.0:
		return "ZAPATILLAS"
	if tirada < 88.0:
		return "JETPACK"
	if tirada < 101.0:
		return "POGO"
	if tirada < 118.0:
		return "TABLA"
	if tirada < 122.0:
		return "LLAVE"
	return "CAJA"


# ----------------------------------------------------------------------------
# Paso de simulación
# ----------------------------------------------------------------------------

func avanzar(dt: float, generar_oleadas: bool = true) -> Dictionary:
	var eventos := {
		"aterrizo": false,
		"paso": false,
		"monedas_recogidas": [] as Array[Vector3],
		"powerup_recogido": "",
		"tabla_salvo": false,
		"tropiezo": false,
		"caido": false,
		"choco": false,
		"tipo_choque": "",
		"buffer_disparado": "",
		"hito": 0,
		"dz": 0.0,
		"jetpack_fin": false,
		"pogo_fin": false,
		"llave": 0,
		"caja_recompensa": "",
		"mision_completada": "",
	}

	var estado: String = str(jugador["estado"])
	if estado == "CAIDO" or estado == "CHOCADO":
		return eventos

	# Actualizar temporizadores (jetpack/pogo mandan sobre el resto)
	for clave in ["iman", "zapatillas", "multiplicador", "tabla", "jetpack", "pogo"]:
		if float(powerups[clave]) > 0.0:
			powerups[clave] = maxf(0.0, float(powerups[clave]) - dt)
	if float(jugador["tiempo_tropiezo"]) > 0.0:
		jugador["tiempo_tropiezo"] = maxf(0.0, float(jugador["tiempo_tropiezo"]) - dt)
		if float(jugador["tiempo_tropiezo"]) <= 0.0 and str(jugador["estado"]) == "TROPEZANDO":
			jugador["estado"] = "CORRIENDO"
	if float(jugador["anim_tropiezo"]) > 0.0:
		jugador["anim_tropiezo"] = maxf(0.0, float(jugador["anim_tropiezo"]) - dt)
	if float(jugador["invulnerable"]) > 0.0:
		jugador["invulnerable"] = maxf(0.0, float(jugador["invulnerable"]) - dt)
	if _ralenti_tropiezo > 0.0:
		_ralenti_tropiezo = maxf(0.0, _ralenti_tropiezo - dt)

	# Velocidad, distancia y puntuación (estilo Subway: la puntuación crece
	# con la distancia y el multiplicador; las monedas van aparte).
	velocidad = calcular_velocidad(distancia)
	var factor_ralenti: float = FACTOR_RALENTI_TROPEZON if _ralenti_tropiezo > 0.0 else 1.0
	var dz: float = velocidad * factor_ralenti * dt
	eventos["dz"] = dz
	distancia += dz
	var mult: int = obtener_multiplicador()
	puntuacion += dz * PUNTOS_POR_METRO * float(mult)
	var metro_actual: int = int(floor(distancia))
	_progreso_mision("metros", metro_actual - _ultimo_metro_mision)
	_ultimo_metro_mision = metro_actual

	if int(floor(distancia)) >= _proximo_hito:
		eventos["hito"] = _proximo_hito
		_proximo_hito += INTERVALO_HITO_METROS

	# Cambio suave de carril + inclinación lateral
	var x_objetivo: float = carril_a_x(int(jugador["carril_objetivo"]))
	var x_prev: float = float(jugador["x"])
	var alfa_x: float = 1.0 - exp(-SUAVIZADO_CARRIL * dt)
	var x_actual: float = x_prev + (x_objetivo - x_prev) * alfa_x
	if absf(x_objetivo - x_actual) < 0.004:
		x_actual = x_objetivo
	jugador["x"] = x_actual

	var vx: float = (x_actual - x_prev) / dt if dt > 0.0 else 0.0
	var inclinacion_obj: float = clampf(-vx * 0.018, -0.28, 0.28)
	jugador["inclinacion_z"] = float(jugador["inclinacion_z"]) + (inclinacion_obj - float(jugador["inclinacion_z"])) * (1.0 - exp(-16.0 * dt))

	# Recuperación de squash & stretch
	var sq_decay: float = 1.0 - exp(-15.0 * dt)
	jugador["squash_x"] = float(jugador["squash_x"]) + (1.0 - float(jugador["squash_x"])) * sq_decay
	jugador["squash_y"] = float(jugador["squash_y"]) + (1.0 - float(jugador["squash_y"])) * sq_decay

	# Buffer de entrada
	if float(jugador["buffer_tiempo"]) > 0.0:
		jugador["buffer_tiempo"] = maxf(0.0, float(jugador["buffer_tiempo"]) - dt)
		if float(jugador["buffer_tiempo"]) <= 0.0:
			jugador["buffer_accion"] = ""

	# Avanzar obstáculos hacia el jugador (+Z). Los trenes en movimiento suman
	# su velocidad relativa: positivos se acercan, negativos se alejan.
	for i in range(obstaculos.size() - 1, -1, -1):
		var obs: Dictionary = obstaculos[i]
		obs["z"] = float(obs["z"]) + dz + float(obs["velocidad"]) * dt
		if float(obs["z"]) - float(obs["largo"]) * 0.5 > DESPAWN_Z:
			obstaculos.remove_at(i)

	# ¿Está el corredor dentro de un túnel? (solo afecta a la cámara)
	var en_tunel: bool = false
	for obs in obstaculos:
		if str(obs["tipo"]) == "TUNEL" and absf(float(obs["z"])) < float(obs["largo"]) * 0.5 + 2.0:
			en_tunel = true
			break
	jugador["tunel"] = en_tunel

	# Vuelo de jetpack: ignora suelo y obstáculos, y recoge monedas en el aire.
	if str(jugador["estado"]) == "VOLANDO" or float(powerups["jetpack"]) > 0.0:
		estado = "VOLANDO"
		jugador["estado"] = estado
		jugador["vy"] = 0.0
		jugador["suelo_y"] = 0.0
		jugador["en_techo"] = false
		jugador["vuelo_t"] = float(jugador["vuelo_t"]) + dt
		var alfa_vuelo: float = 1.0 - exp(-3.0 * dt)
		jugador["y"] = lerpf(float(jugador["y"]), ALTURA_VUELO_JETPACK, alfa_vuelo)
		if float(powerups["jetpack"]) <= 0.0:
			jugador["estado"] = "SALTANDO"
			jugador["invulnerable"] = maxf(float(jugador["invulnerable"]), 1.4)
			jugador["vy"] = 0.0
			_limpiar_obstaculos_zona(-42.0, 16.0)
			eventos["jetpack_fin"] = true
	elif str(jugador["estado"]) == "POGO" or float(powerups["pogo"]) > 0.0:
		estado = "POGO"
		jugador["estado"] = estado
		jugador["vy"] = 0.0
		jugador["suelo_y"] = 0.0
		jugador["en_techo"] = false
		var recorrido: float = maxf(0.001, distancia - float(jugador["pogo_z0"]))
		var progreso: float = clampf(recorrido / DISTANCIA_POGO, 0.0, 1.0)
		jugador["pogo_progreso"] = progreso
		jugador["y"] = float(jugador["pogo_y0"]) + sin(progreso * PI) * ALTURA_MAXIMA_POGO
		if progreso >= 1.0:
			jugador["estado"] = "SALTANDO"
			jugador["y"] = 0.0
			jugador["invulnerable"] = maxf(float(jugador["invulnerable"]), 1.2)
			_limpiar_obstaculos_zona(-38.0, 16.0)
			eventos["pogo_fin"] = true

	# Soporte vertical, gravedad y aterrizaje (solo si corre, salta o rueda)
	estado = str(jugador["estado"])
	if estado != "VOLANDO" and estado != "POGO":
		var soporte: Dictionary = calcular_suelo_soporte(float(jugador["x"]), float(jugador["y"]))
		var suelo_y: float = float(soporte["suelo_y"])
		jugador["suelo_y"] = suelo_y
		jugador["en_techo"] = bool(soporte["en_techo"])

		var estaba_en_aire: bool = float(jugador["y"]) > suelo_y + 0.08
		if float(jugador["y"]) > suelo_y or float(jugador["vy"]) > 0.0:
			jugador["vy"] = float(jugador["vy"]) - GRAVEDAD * dt
			jugador["y"] = float(jugador["y"]) + float(jugador["vy"]) * dt
			if float(jugador["y"]) <= suelo_y:
				jugador["y"] = suelo_y
				jugador["vy"] = 0.0
				if estaba_en_aire:
					eventos["aterrizo"] = true
					jugador["squash_x"] = 1.22
					jugador["squash_y"] = 0.78
					if str(jugador["estado"]) == "SALTANDO":
						jugador["estado"] = "CORRIENDO"
					if str(jugador["buffer_accion"]) != "":
						var acc: String = str(jugador["buffer_accion"])
						jugador["buffer_accion"] = ""
						jugador["buffer_tiempo"] = 0.0
						var res: String = aplicar_comando(acc)
						if res == "SALTAR" or res == "RODAR":
							eventos["buffer_disparado"] = res
		else:
			jugador["y"] = suelo_y
			jugador["vy"] = 0.0

	# Temporizador de rodar
	if str(jugador["estado"]) == "RODANDO":
		jugador["tiempo_rodar"] = float(jugador["tiempo_rodar"]) - dt
		if float(jugador["tiempo_rodar"]) <= 0.0:
			jugador["tiempo_rodar"] = 0.0
			jugador["estado"] = "SALTANDO" if float(jugador["y"]) > float(jugador["suelo_y"]) + 0.10 else "CORRIENDO"
			if str(jugador["buffer_accion"]) == "SALTAR":
				jugador["buffer_accion"] = ""
				jugador["buffer_tiempo"] = 0.0
				if aplicar_comando("SALTAR") == "SALTAR":
					eventos["buffer_disparado"] = "SALTAR"

	# Ciclo de zancada
	if str(jugador["estado"]) == "CORRIENDO" and float(jugador["y"]) <= float(jugador["suelo_y"]) + 0.08 and float(powerups["tabla"]) <= 0.0:
		jugador["ciclo_carrera"] = float(jugador["ciclo_carrera"]) + velocidad * factor_ralenti * dt * 0.54
		var paso_idx: int = int(floor(float(jugador["ciclo_carrera"]) / PI))
		if paso_idx != _ultimo_paso_idx:
			_ultimo_paso_idx = paso_idx
			eventos["paso"] = true

	# Colisiones con obstáculos
	estado = str(jugador["estado"])
	if float(jugador["invulnerable"]) <= 0.0 and estado != "VOLANDO" and estado != "POGO":
		var obs_hit: Dictionary = buscar_obstaculo_colision()
		if not obs_hit.is_empty():
			var tipo_choque: String = str(obs_hit["tipo"])
			if float(powerups["tabla"]) > 0.0:
				powerups["tabla"] = 0.0
				jugador["invulnerable"] = INVULNERABLE_TRAS_TABLA_SEG
				jugador["tiempo_tropiezo"] = 0.0
				jugador["anim_tropiezo"] = 0.0
				if str(jugador["estado"]) == "TROPEZANDO":
					jugador["estado"] = "CORRIENDO"
				_limpiar_obstaculos_zona(-30.0, 10.0)
				eventos["tabla_salvo"] = true
			elif float(jugador["tiempo_tropiezo"]) > 0.0 or estado == "TROPEZANDO":
				_caer(tipo_choque)
				eventos["caido"] = true
				eventos["choco"] = true
				eventos["tipo_choque"] = tipo_choque
				return eventos
			else:
				obs_hit["golpeado"] = true
				_tropezar(tipo_choque)
				eventos["tropiezo"] = true
				eventos["tipo_choque"] = tipo_choque

	# Avanzar y recoger monedas (con atracción de imán 3D o vuelo)
	var iman_activo: bool = float(powerups["iman"]) > 0.0
	var volando: bool = str(jugador["estado"]) == "VOLANDO" or str(jugador["estado"]) == "POGO"
	var jx: float = float(jugador["x"])
	var jy: float = float(jugador["y"])
	for i in range(monedas_entidades.size() - 1, -1, -1):
		var c: Dictionary = monedas_entidades[i]
		c["z"] = float(c["z"]) + dz
		if not bool(c["recogida"]):
			var cz: float = float(c["z"])
			if (iman_activo or volando) and cz > -22.0 and cz < 3.5:
				c["magnetizada"] = true
			if bool(c["magnetizada"]):
				var pull: float = 1.0 - exp(-15.0 * dt)
				c["x"] = float(c["x"]) + (jx - float(c["x"])) * pull
				c["y"] = float(c["y"]) + (jy + 1.05 - float(c["y"])) * pull
				c["z"] = float(c["z"]) + (0.0 - float(c["z"])) * (1.0 - exp(-10.0 * dt))
			else:
				c["x"] = carril_a_x(int(c["carril"]))

			var dx: float = absf(float(c["x"]) - jx)
			var dy: float = absf(float(c["y"]) - (jy + 0.95))
			var d_z: float = absf(float(c["z"]) - JUGADOR_Z)
			var radio_y: float = 2.0 if volando else 1.25
			if dx < 1.05 and dy < radio_y and d_z < 1.35:
				c["recogida"] = true
				monedas += 1
				if PUNTOS_POR_MONEDA > 0:
					puntuacion += float(PUNTOS_POR_MONEDA * mult)
				_progreso_mision("monedas", 1)
				(eventos["monedas_recogidas"] as Array[Vector3]).append(Vector3(float(c["x"]), float(c["y"]), float(c["z"])))

		if bool(c["recogida"]) or float(c["z"]) > DESPAWN_Z:
			monedas_entidades.remove_at(i)

	# Avanzar y recoger power-ups
	for i in range(powerups_entidades.size() - 1, -1, -1):
		var pu: Dictionary = powerups_entidades[i]
		pu["z"] = float(pu["z"]) + dz
		if not bool(pu["recogido"]):
			var dx: float = absf(carril_a_x(int(pu["carril"])) - jx)
			var dy: float = absf(float(pu["y"]) - (jy + 1.0))
			var d_z: float = absf(float(pu["z"]) - JUGADOR_Z)
			if dx < 1.15 and dy < 1.80 and d_z < 1.50:
				pu["recogido"] = true
				var tipo: String = str(pu["tipo"])
				eventos["powerup_recogido"] = tipo
				match tipo:
					"IMAN":
						powerups["iman"] = DURACION_IMAN
					"ZAPATILLAS":
						powerups["zapatillas"] = DURACION_ZAPATILLAS
					"MULTIPLICADOR":
						powerups["multiplicador"] = DURACION_MULTIPLICADOR
					"TABLA":
						tablas_restantes += 1
					"JETPACK":
						_activar_jetpack()
					"POGO":
						_activar_pogo()
					"LLAVE":
						llaves += 1
						eventos["llave"] = 1
					"CAJA":
						var tirada_caja: int = _rng.randi_range(0, 3)
						match tirada_caja:
							0:
								monedas += 12
								_progreso_mision("monedas", 12)
								eventos["caja_recompensa"] = "+12 MONEDAS"
							1:
								llaves += 1
								eventos["caja_recompensa"] = "+1 LLAVE"
							2:
								tablas_restantes += 1
								eventos["caja_recompensa"] = "+1 TABLA"
							_:
								puntuacion += 1000.0
								eventos["caja_recompensa"] = "+1.000 PTS"
		if bool(pu["recogido"]) or float(pu["z"]) > DESPAWN_Z:
			powerups_entidades.remove_at(i)

	# Generar siguiente oleada
	if generar_oleadas and distancia >= _siguiente_oleada_dist:
		generar_oleada(SPAWN_Z)
		var brecha: float = maxf(BRECHA_OLEADA_MIN, velocidad * FACTOR_BRECHA_VELOCIDAD + 8.0)
		_siguiente_oleada_dist = distancia + brecha

	_actualizar_guardia(dt)

	if _mision_pendiente != "":
		eventos["mision_completada"] = _mision_pendiente
		_mision_pendiente = ""

	return eventos


func _activar_jetpack() -> void:
	powerups["jetpack"] = DURACION_JETPACK
	powerups["pogo"] = 0.0
	jugador["estado"] = "VOLANDO"
	jugador["vuelo_t"] = 0.0
	jugador["vy"] = 0.0
	jugador["tiempo_rodar"] = 0.0
	jugador["tiempo_tropiezo"] = 0.0
	jugador["anim_tropiezo"] = 0.0

	# Estela de monedas en el aire para que el vuelo se lea como en Subway Surfers.
	for k in range(22):
		var z: float = -16.0 - float(k) * 3.2
		var carril: int = 0
		if k % 7 > 3:
			carril = -1 if (k / 7) % 2 == 0 else 1
		anadir_moneda(carril, ALTURA_VUELO_JETPACK + 0.95, z, float(k) * 0.35)


func _activar_pogo() -> void:
	powerups["pogo"] = DURACION_POGO
	powerups["jetpack"] = 0.0
	jugador["estado"] = "POGO"
	jugador["pogo_z0"] = distancia
	jugador["pogo_y0"] = float(jugador["y"])
	jugador["pogo_progreso"] = 0.0
	jugador["vy"] = 0.0
	jugador["tiempo_rodar"] = 0.0
	jugador["tiempo_tropiezo"] = 0.0
	jugador["anim_tropiezo"] = 0.0

	# Arco de monedas y un power-up al final, como el pogo original.
	for k in range(1, 15):
		var u: float = float(k) / 15.0
		var y: float = float(jugador["pogo_y0"]) + sin(u * PI) * ALTURA_MAXIMA_POGO + 0.95
		var z: float = -DISTANCIA_POGO * (1.0 - u) - 4.0
		for carril in [-1, 0, 1]:
			anadir_moneda(carril, y, z, float(k) * 0.3 + float(carril) * 0.2)
	var tipos: Array[String] = ["IMAN", "ZAPATILLAS", "MULTIPLICADOR", "JETPACK"]
	anadir_powerup(tipos[_rng.randi_range(0, tipos.size() - 1)], 0, ALTURA_MAXIMA_POGO + 0.95, -DISTANCIA_POGO - 6.0)


func _tropezar(tipo: String) -> void:
	if str(jugador["estado"]) == "CAIDO" or str(jugador["estado"]) == "CHOCADO":
		return
	jugador["estado"] = "TROPEZANDO"
	jugador["tiempo_tropiezo"] = DURACION_TROPEZON
	jugador["anim_tropiezo"] = 0.55
	jugador["invulnerable"] = maxf(float(jugador["invulnerable"]), 0.45)
	_ralenti_tropiezo = RALENTI_TROPEZON_SEG
	jugador["squash_x"] = 1.15
	jugador["squash_y"] = 0.88
	jugador["tipo_caida"] = tipo
	if float(jugador["y"]) > 0.2:
		jugador["vy"] = minf(float(jugador["vy"]), 0.0)


func _caer(tipo: String) -> void:
	jugador["estado"] = "CAIDO"
	jugador["tiempo_tropiezo"] = 0.0
	jugador["anim_tropiezo"] = 0.0
	jugador["tipo_caida"] = tipo
	jugador["vy"] = 0.0
	powerups["jetpack"] = 0.0
	powerups["pogo"] = 0.0


## Reanima al corredor tras una caída (llave o reanimación gratuita).
func revivir() -> bool:
	var estado: String = str(jugador["estado"])
	if estado != "CAIDO" and estado != "CHOCADO":
		return false
	jugador["estado"] = "CORRIENDO"
	jugador["tiempo_tropiezo"] = 0.0
	jugador["anim_tropiezo"] = 0.0
	jugador["y"] = 0.0
	jugador["vy"] = 0.0
	jugador["suelo_y"] = 0.0
	jugador["en_techo"] = false
	jugador["invulnerable"] = INVULNERABLE_TRAS_REVIVIR_SEG
	jugador["tipo_caida"] = ""
	for clave in ["jetpack", "pogo"]:
		powerups[clave] = 0.0
	_limpiar_obstaculos_zona(-60.0, 20.0)
	guardia_distancia = DISTANCIA_GUARDIA_LEJOS
	_ralenti_tropiezo = 0.0
	return true


func _limpiar_obstaculos_zona(z_min: float, z_max: float) -> void:
	var filtrados: Array[Dictionary] = []
	for o in obstaculos:
		var z: float = float(o["z"])
		if z < z_min or z > z_max:
			filtrados.append(o)
	obstaculos = filtrados


func _actualizar_guardia(dt: float) -> void:
	var objetivo: float = DISTANCIA_GUARDIA_LEJOS
	if str(jugador["estado"]) == "CAIDO" or str(jugador["estado"]) == "CHOCADO":
		objetivo = 0.0
	elif float(jugador["tiempo_tropiezo"]) > 0.0 or str(jugador["estado"]) == "TROPEZANDO":
		objetivo = DISTANCIA_GUARDIA_CEBO
	var rapidez: float = 70.0 if objetivo < guardia_distancia else 22.0
	guardia_distancia = move_toward(guardia_distancia, objetivo, rapidez * dt)


func _progreso_mision(id: String, cantidad: int) -> void:
	if cantidad <= 0:
		return
	for m in misiones:
		if str(m["id"]) != id or bool(m["completada"]):
			continue
		m["progreso"] = int(m["progreso"]) + cantidad
		if int(m["progreso"]) >= int(m["objetivo"]):
			m["progreso"] = int(m["objetivo"])
			m["completada"] = true
			puntuacion += float(m["recompensa"])
			_mision_pendiente = str(m["texto"])
		return


## Devuelve el obstáculo con el que colisiona el corredor, o {} si no hay colisión.
func buscar_obstaculo_colision() -> Dictionary:
	var estado: String = str(jugador["estado"])
	if estado == "VOLANDO" or estado == "POGO" or estado == "CAIDO" or estado == "CHOCADO":
		return {}

	var altura_pj: float = ALTURA_JUGADOR_RODAR if estado == "RODANDO" else ALTURA_JUGADOR_NORMAL
	var jx: float = float(jugador["x"])
	var jy: float = float(jugador["y"])
	var techo_pj: float = jy + altura_pj

	for obs in obstaculos:
		if bool(obs.get("golpeado", false)):
			continue
		if str(obs["tipo"]) == "TUNEL":
			continue
		var obs_x: float = carril_a_x(int(obs["carril"]))
		if absf(jx - obs_x) > ANCHO_CARRIL * 0.38:
			continue

		var medio_largo: float = float(obs["largo"]) * 0.5
		var frente_z: float = float(obs["z"]) + medio_largo
		var atras_z: float = float(obs["z"]) - medio_largo
		if not (frente_z > -0.55 and atras_z < 0.55):
			continue

		var tipo: String = str(obs["tipo"])
		var altura_obs: float = float(obs["altura"])
		if tipo == "VALLA_BAJA":
			if jy < altura_obs - 0.18:
				return obs
		elif tipo == "ARCO_ALTO":
			var paso_debajo: bool = techo_pj <= HUECO_ARCO_ALTO
			var salto_encima: bool = jy >= altura_obs - 0.15
			if not paso_debajo and not salto_encima:
				return obs
		else:
			var altura_segura: float = (altura_obs - 1.05) if bool(obs["tiene_rampa"]) else (altura_obs - 0.55)
			if jy < altura_segura:
				return obs

	return {}
