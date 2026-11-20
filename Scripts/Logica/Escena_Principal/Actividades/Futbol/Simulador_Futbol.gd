class_name Simulador_Futbol
extends RefCounted

# Motor matemático puro de la carrera de futbolista.
# Ninguna función de este script lee Variables_Dinamicas ni modifica la matriz:
# recibe todos los datos por parámetro para poder testearse en GUT.

const DIVISIONES: Dictionary = {
	4: "3ª División Regional",
	3: "2ª División Nacional",
	2: "1ª División Élite",
	1: "Superliga Internacional"
}

const UMBRALES_DIVISION: Dictionary = {
	4: 45.0,
	3: 62.0,
	2: 78.0,
	1: 90.0
}

const SALARIOS_DIVISION: Dictionary = {
	4: 150,
	3: 600,
	2: 2500,
	1: 10000
}

const PRIMAS_VICTORIA: Dictionary = {4: 50, 3: 200, 2: 800, 1: 3000}
const PRIMAS_GOL: Dictionary = {4: 15, 3: 50, 2: 150, 1: 500}


static func Obtener_Nombre_Division(division: int) -> String:
	return str(DIVISIONES.get(division, "División desconocida"))


static func Obtener_Umbral_Division(division: int) -> float:
	return float(UMBRALES_DIVISION.get(division, 45.0))


static func Obtener_Salario_Division(division: int) -> int:
	return int(SALARIOS_DIVISION.get(division, 150))


static func Calcular_Condicion_Fisica(salud_fisica: float, descanso: float, hambre: float) -> float:
	return clampf((salud_fisica * 0.45) + (descanso * 0.35) + (hambre * 0.20), 0.0, 100.0)


static func _Leer_Habilidad(habilidades: Array, indice: int) -> float:
	if indice < 0 or indice >= habilidades.size():
		return 50.0
	var valor: Variant = habilidades[indice]
	if typeof(valor) != TYPE_INT and typeof(valor) != TYPE_FLOAT:
		return 50.0
	return float(valor)


static func Calcular_Innata_Futbol(habilidades: Array) -> float:
	var deporte: float = _Leer_Habilidad(habilidades, 0)
	var liderazgo: float = _Leer_Habilidad(habilidades, 4)
	var sangre_fria: float = _Leer_Habilidad(habilidades, 6)
	return clampf((deporte * 0.50) + (liderazgo * 0.25) + (sangre_fria * 0.25), 0.0, 100.0)


static func Evaluar_Convocatoria(relacion_entrenador: float, condicion_fisica: float,
		salud_fisica: float, liderazgo: float, lesionado: bool) -> Dictionary:
	var indice: float = (relacion_entrenador * 0.55) + (condicion_fisica * 0.30) + (liderazgo * 0.15)
	var resultado: Dictionary = {
		"convocado": false,
		"motivo": "",
		"indice": clampf(indice, 0.0, 100.0)
	}
	if lesionado:
		resultado["motivo"] = "lesionado"
		return resultado
	if salud_fisica < 30.0:
		resultado["motivo"] = "salud_baja"
		return resultado
	if relacion_entrenador < 25.0:
		resultado["motivo"] = "relacion_baja"
		return resultado
	if indice < 45.0:
		resultado["motivo"] = "indice_bajo"
		return resultado
	resultado["convocado"] = true
	return resultado


static func Calcular_Puntuacion_Partido(progreso_deporte: float, condicion_fisica: float,
		innata_futbol: float, sangre_fria: float, es_partido_decisivo: bool,
		variacion_aleatoria: float = 0.0) -> float:
	var puntuacion: float
	if es_partido_decisivo:
		puntuacion = (progreso_deporte * 0.42) + (condicion_fisica * 0.25) \
			+ (innata_futbol * 0.13) + (sangre_fria * 0.20) + variacion_aleatoria
	else:
		puntuacion = (progreso_deporte * 0.50) + (condicion_fisica * 0.30) \
			+ (innata_futbol * 0.20) + variacion_aleatoria
	return clampf(puntuacion, 0.0, 100.0)


static func Resolver_Tanda_Penaltis(sangre_fria: float, progreso_deporte: float, tirada_azar: float) -> bool:
	var probabilidad: float = clampf(
		0.25 + (sangre_fria / 100.0) * 0.55 + (progreso_deporte / 100.0) * 0.20,
		0.15,
		0.90)
	return tirada_azar < probabilidad


static func Simular_Partido_Liga(puntuacion_final: float, media_rival: float, es_decisivo: bool,
		sangre_fria: float = 50.0, progreso_deporte: float = 50.0,
		azar_penaltis: float = 0.5) -> Dictionary:
	var resultado: Dictionary = {
		"resultado": "Derrota",
		"goles": 0,
		"asistencias": 0,
		"delta_relacion": -3.0,
		"gano_penaltis": false,
		"es_decisivo": es_decisivo
	}

	if puntuacion_final >= media_rival + 4.0:
		resultado["resultado"] = "Victoria"
		resultado["goles"] = 1 + int(maxf(0.0, puntuacion_final - media_rival) / 12.0)
		resultado["delta_relacion"] = 4.0
		resultado["asistencias"] = _Calcular_Asistencias(puntuacion_final, media_rival, int(resultado["goles"]))
	elif puntuacion_final >= media_rival - 4.0:
		resultado["resultado"] = "Empate"
		resultado["goles"] = 0
		resultado["asistencias"] = 0
		resultado["delta_relacion"] = 1.0
		if es_decisivo:
			var gana: bool = Resolver_Tanda_Penaltis(sangre_fria, progreso_deporte, azar_penaltis)
			resultado["gano_penaltis"] = gana
			resultado["resultado"] = "Victoria_Penaltis" if gana else "Derrota_Penaltis"
			resultado["delta_relacion"] = 4.0 if gana else -3.0
	else:
		resultado["resultado"] = "Derrota"
		resultado["goles"] = 0
		resultado["asistencias"] = 0
		resultado["delta_relacion"] = -3.0

	return resultado


static func _Calcular_Asistencias(puntuacion_final: float, media_rival: float, goles: int) -> int:
	if goles <= 0 or puntuacion_final < media_rival:
		return 0
	var asistencias: int = 1
	if puntuacion_final >= media_rival + 14.0:
		asistencias += 1
	return clampi(asistencias, 0, 3)


static func Resolver_Playoff_Domingo(posicion_regular: int, gano_partido_4: bool,
		division_actual: int) -> Dictionary:
	var resultado: Dictionary = {
		"posicion_final": clampi(posicion_regular, 1, 4),
		"cambio_division": 0,
		"campeon_superliga": false,
		"despedido": false
	}

	if posicion_regular <= 2:
		if gano_partido_4:
			resultado["posicion_final"] = 1
			if division_actual > 1:
				resultado["cambio_division"] = -1
			else:
				resultado["campeon_superliga"] = true
		else:
			resultado["posicion_final"] = 2
	else:
		if gano_partido_4:
			resultado["posicion_final"] = 3
		else:
			resultado["posicion_final"] = 4
			if division_actual >= 4:
				resultado["despedido"] = true
			elif division_actual < 4:
				resultado["cambio_division"] = 1

	return resultado


static func Simular_Partido_Rapido(puntuacion_final: float, division_actual: int) -> Dictionary:
	var umbral: float = Obtener_Umbral_Division(division_actual)
	var resultado: Dictionary = {
		"resultado": "Derrota",
		"goles": 0,
		"asistencias": 0,
		"delta_relacion": -3.0,
		"cambio_division": 0,
		"campeon_superliga": false,
		"despedido": false,
		"media_rival": umbral
	}

	if puntuacion_final >= umbral:
		resultado["resultado"] = "Victoria"
		resultado["goles"] = 1 + int(maxf(0.0, puntuacion_final - umbral) / 12.0)
		resultado["asistencias"] = _Calcular_Asistencias(puntuacion_final, umbral, int(resultado["goles"]))
		resultado["delta_relacion"] = 4.0
		if division_actual > 1:
			resultado["cambio_division"] = -1
		else:
			resultado["campeon_superliga"] = true
	elif puntuacion_final >= umbral - 8.0:
		resultado["resultado"] = "Empate"
		resultado["delta_relacion"] = 1.0
	else:
		resultado["resultado"] = "Derrota"
		if division_actual >= 4:
			resultado["despedido"] = true
		else:
			resultado["cambio_division"] = 1

	return resultado


static func Comprobar_Riesgo_Lesion(condicion_fisica: float, salud_fisica: float, tirada_azar: float) -> bool:
	if condicion_fisica < 30.0 or salud_fisica < 25.0:
		return tirada_azar < 0.25
	return false
