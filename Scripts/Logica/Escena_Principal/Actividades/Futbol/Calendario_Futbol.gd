class_name Calendario_Futbol
extends RefCounted

# Calendario puro de la carrera de futbolista (Fase 1 — Modo Jugador).
# Todas las horas se expresan en minutos desde las 00:00 y son estáticas
# para poder testearlas en GUT sin depender del estado de la partida.

const DURACION_ENTRENAMIENTO_NORMAL: int = 120
const DURACION_ENTRENAMIENTO_RAPIDO: int = 45
const DURACION_PARTIDO: int = 60

const ENTRENO_TERCERA_NORMAL: int = 19 * 60          # 19:00
const ENTRENO_PROFESIONAL_NORMAL: int = 10 * 60      # 10:00
const ENTRENO_TERCERA_RAPIDO: int = 18 * 60 + 30     # 18:30
const ENTRENO_PROFESIONAL_RAPIDO: int = 10 * 60      # 10:00

const PARTIDOS_DOMINGO: Array = [10 * 60, 13 * 60, 16 * 60, 19 * 60]
const PARTIDO_RAPIDO: int = 20 * 60 + 30             # 20:30

const DIAS_ENTRENAMIENTO_NORMAL: Array = [1, 3]      # Martes y Jueves
const DIA_PARTIDO_NORMAL: int = 6                    # Domingo
const DIAS_ENTRENAMIENTO_RAPIDO: Array = [0, 1, 2, 3, 4, 5, 6]


static func Obtener_Dias_Entrenamiento(modo_rapido: bool) -> Array:
	if modo_rapido:
		return DIAS_ENTRENAMIENTO_RAPIDO.duplicate()
	return DIAS_ENTRENAMIENTO_NORMAL.duplicate()


static func Obtener_Horario_Entrenamiento(division: int, modo_rapido: bool) -> Dictionary:
	var inicio: int = ENTRENO_PROFESIONAL_NORMAL
	var duracion: int = DURACION_ENTRENAMIENTO_NORMAL
	if modo_rapido:
		duracion = DURACION_ENTRENAMIENTO_RAPIDO
		inicio = ENTRENO_TERCERA_RAPIDO if division >= 4 else ENTRENO_PROFESIONAL_RAPIDO
	else:
		inicio = ENTRENO_TERCERA_NORMAL if division >= 4 else ENTRENO_PROFESIONAL_NORMAL
	return {
		"dias": Obtener_Dias_Entrenamiento(modo_rapido),
		"inicio": inicio,
		"duracion": duracion,
		"fin": inicio + duracion
	}


static func Obtener_Horarios_Partidos(modo_rapido: bool) -> Array:
	if modo_rapido:
		return [PARTIDO_RAPIDO]
	return PARTIDOS_DOMINGO.duplicate()


static func Obtener_Hora_Inicio_Partido(indice: int, modo_rapido: bool) -> int:
	var horarios: Array = Obtener_Horarios_Partidos(modo_rapido)
	if indice < 0 or indice >= horarios.size():
		return -1
	return int(horarios[indice])


static func Obtener_Indice_Jornada(hora_inicio: int, modo_rapido: bool) -> int:
	if modo_rapido:
		return 0
	return PARTIDOS_DOMINGO.find(hora_inicio)


static func Es_Dia_Partido(dia_semana: int, modo_rapido: bool) -> bool:
	if modo_rapido:
		return true
	return dia_semana == DIA_PARTIDO_NORMAL


static func Es_Dia_Entrenamiento(dia_semana: int, modo_rapido: bool) -> bool:
	return Obtener_Dias_Entrenamiento(modo_rapido).has(dia_semana)


static func Obtener_Fin_Bloque(inicio: int, duracion: int) -> int:
	return inicio + maxi(0, duracion)


static func Formatear_Hora(minuto_dia: int) -> String:
	var minuto: int = clampi(minuto_dia, 0, 1439)
	return "%02d:%02d" % [minuto / 60, minuto % 60]


static func Nombre_Dia(dia_semana: int) -> String:
	var nombres: Array = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]
	if dia_semana < 0 or dia_semana >= nombres.size():
		return "?"
	return str(nombres[dia_semana])
