extends Node

# Sistema de Eventos Aleatorios
# ==============================
# Se llama desde Actualizar_Horario() en Actividades.gd cada minuto.
# Contiene dos tipos de eventos:
#   1. Despido por higiene (solo mientras trabajas)
#   2. Eventos generales (enfermedades, bonus, accidentes...)

# ---- CONSTANTES ----

# Probabilidad base para eventos generales: 1/2880 por minuto (~1 cada 2 días de juego)
const PROBABILIDAD_BASE: int = 2880

# Tras este número de minutos sin evento general, la probabilidad empieza a acumularse
const MINUTOS_SIN_EVENTO_BASE: int = 1440  # 1 día

# Duración del cooldown de trabajo en minutos (5 días = 5 * 1440)
const COOLDOWN_TRABAJO_MINUTOS: int = 5 * 1440

# ---- ESTADO ----

# Minutos desde el último evento general (aumenta la probabilidad cuanto más tiempo pase)
var minutos_sin_evento: int = 0

# ---- TIPOS DE EVENTOS GENERALES ----

enum TipoEvento {
	ENFERMEDAD_LEVE,
	ENFERMEDAD_GRAVE,
	BONUS_DINERO,
	BONUS_DINERO_GRANDE,
	ACCIDENTE_LEVE,
	ACCIDENTE_GRAVE,
	EVENTO_SOCIAL_POSITIVO,
	EVENTO_SOCIAL_NEGATIVO,
	HALLAZGO,
	INSPIRACION,
}

# ---- ESTRUCTURA DE EVENTO ----

class Evento:
	var tipo: int
	var titulo: String
	var descripcion: String
	var efectos: Dictionary  # {"necesidades": [0,0,0,0,0], "dinero": 0, "progreso": [0,0,0]}
	var hora_inicio: int  # minuto del día (0-1439), -1 = sin restricción
	var hora_fin: int     # minuto del día (0-1439), -1 = sin restricción

	func _init(p_tipo: int, p_titulo: String, p_descripcion: String, p_efectos: Dictionary, p_hora_inicio: int = -1, p_hora_fin: int = -1):
		tipo = p_tipo
		titulo = p_titulo
		descripcion = p_descripcion
		efectos = p_efectos
		hora_inicio = p_hora_inicio
		hora_fin = p_hora_fin

	func Es_Hora_Valida(minuto: int) -> bool:
		if hora_inicio == -1:
			return true
		# Franja que cruza medianoche (ej. 18:00–6:00)
		if hora_inicio > hora_fin:
			return minuto >= hora_inicio or minuto < hora_fin
		return minuto >= hora_inicio and minuto < hora_fin

# ---- CATÁLOGO DE EVENTOS ----

var _eventos_disponibles: Array = []

func _ready():
	_Inicializar_Eventos()

func _Inicializar_Eventos():
	# ---- ENFERMEDADES ----
	_eventos_disponibles.append(Evento.new(
		TipoEvento.ENFERMEDAD_LEVE,
		"Resfriado",
		"Te has resfriado. Has estado estornudando todo el día y te sientes débil.",
		{"necesidades": [-2, -3, 0, -2, 0], "dinero": -20, "progreso": [0, 0, 0]}
	))
	_eventos_disponibles.append(Evento.new(
		TipoEvento.ENFERMEDAD_LEVE,
		"Dolor de cabeza",
		"Un fuerte dolor de cabeza te impide concentrarte.",
		{"necesidades": [0, -4, 0, -3, 0], "dinero": -10, "progreso": [0, 0, 0]}
	))
	_eventos_disponibles.append(Evento.new(
		TipoEvento.ENFERMEDAD_LEVE,
		"Intoxicación alimentaria",
		"Algo que comiste no sentó bien. Has pasado la noche despierto.",
		{"necesidades": [-3, -2, -5, -4, -2], "dinero": -15, "progreso": [0, 0, 0]},
		480, 1320  # 8:00–22:00
	))
	_eventos_disponibles.append(Evento.new(
		TipoEvento.ENFERMEDAD_GRAVE,
		"Gripe",
		"Has cogido una gripe fuerte. Estarás varios días sin poder rendir al máximo.",
		{"necesidades": [-5, -6, 0, -5, -3], "dinero": -50, "progreso": [0, 0, 0]}
	))
	_eventos_disponibles.append(Evento.new(
		TipoEvento.ENFERMEDAD_GRAVE,
		"Lesión deportiva",
		"Te has lesionado haciendo ejercicio. Necesitarás descansar.",
		{"necesidades": [-6, -3, -2, -2, -2], "dinero": -80, "progreso": [-3, 0, 0]},
		360, 1080  # 6:00–18:00
	))

	# ---- BONUS DE DINERO ----
	_eventos_disponibles.append(Evento.new(
		TipoEvento.BONUS_DINERO,
		"Reembolso inesperado",
		"Te han devuelto un dinero que no esperabas. ¡Suerte!",
		{"necesidades": [0, 0, 0, 0, 0], "dinero": 100, "progreso": [0, 0, 0]},
		540, 1080  # 9:00–18:00
	))
	_eventos_disponibles.append(Evento.new(
		TipoEvento.BONUS_DINERO,
		"Trabajo extra",
		"Te han ofrecido un trabajo extra puntual y lo has aceptado.",
		{"necesidades": [-1, -1, 0, -2, 0], "dinero": 150, "progreso": [0, 0, 0]},
		540, 1080  # 9:00–18:00
	))
	_eventos_disponibles.append(Evento.new(
		TipoEvento.BONUS_DINERO_GRANDE,
		"Herencia",
		"Un familiar lejano te ha dejado una pequeña herencia.",
		{"necesidades": [0, 0, 0, 0, 0], "dinero": 500, "progreso": [0, 0, 0]}
	))
	_eventos_disponibles.append(Evento.new(
		TipoEvento.BONUS_DINERO_GRANDE,
		"Premio de lotería",
		"¡Has ganado un premio en la lotería! No es el gordo, pero algo es algo.",
		{"necesidades": [0, 0, 0, 0, 0], "dinero": 1000, "progreso": [0, 0, 0]}
	))

	# ---- ACCIDENTES ----
	_eventos_disponibles.append(Evento.new(
		TipoEvento.ACCIDENTE_LEVE,
		"Multa de tráfico",
		"Has recibido una multa por aparcar mal. Tendrás que pagarla.",
		{"necesidades": [0, -2, 0, 0, -1], "dinero": -60, "progreso": [0, 0, 0]},
		480, 1320  # 8:00–22:00
	))
	_eventos_disponibles.append(Evento.new(
		TipoEvento.ACCIDENTE_LEVE,
		"Se ha estropeado la lavadora",
		"La lavadora ha dejado de funcionar. Toca reparación.",
		{"necesidades": [0, -1, 0, -2, -3], "dinero": -80, "progreso": [0, 0, 0]},
		480, 1320  # 8:00–22:00
	))
	_eventos_disponibles.append(Evento.new(
		TipoEvento.ACCIDENTE_GRAVE,
		"Accidente de coche",
		"Has tenido un pequeño accidente de coche. Estás bien, pero el coche no tanto.",
		{"necesidades": [-4, -5, 0, -3, -2], "dinero": -300, "progreso": [0, 0, 0]},
		420, 1380  # 7:00–23:00
	))
	_eventos_disponibles.append(Evento.new(
		TipoEvento.ACCIDENTE_GRAVE,
		"Robo",
		"Te han robado la cartera. Has perdido dinero y documentos.",
		{"necesidades": [0, -4, 0, -2, -3], "dinero": -200, "progreso": [0, 0, 0]},
		1080, 360  # 18:00–6:00 (cruza medianoche)
	))

	# ---- EVENTOS SOCIALES ----
	_eventos_disponibles.append(Evento.new(
		TipoEvento.EVENTO_SOCIAL_POSITIVO,
		"Quedada con amigos",
		"Has quedado con amigos y lo has pasado genial. Te sientes renovado.",
		{"necesidades": [2, 5, 0, 0, 2], "dinero": -30, "progreso": [0, 0, 0]},
		960, 1380  # 16:00–23:00
	))
	_eventos_disponibles.append(Evento.new(
		TipoEvento.EVENTO_SOCIAL_POSITIVO,
		"Cena familiar",
		"Has ido a cenar con tu familia. Comida casera y buen ambiente.",
		{"necesidades": [1, 4, 5, 2, 1], "dinero": 0, "progreso": [0, 0, 0]},
		1080, 1320  # 18:00–22:00
	))
	_eventos_disponibles.append(Evento.new(
		TipoEvento.EVENTO_SOCIAL_NEGATIVO,
		"Discusión con un amigo",
		"Has tenido una discusión tonta con un amigo. Te sientes mal.",
		{"necesidades": [0, -5, 0, -1, -2], "dinero": 0, "progreso": [0, 0, 0]}
	))
	_eventos_disponibles.append(Evento.new(
		TipoEvento.EVENTO_SOCIAL_NEGATIVO,
		"Mal día en el trabajo/estudios",
		"Todo lo que podía salir mal, salió mal. Llegas a casa agotado.",
		{"necesidades": [-2, -4, 0, -3, -3], "dinero": 0, "progreso": [0, 0, 0]},
		480, 1200  # 8:00–20:00
	))

	# ---- HALLAZGOS ----
	_eventos_disponibles.append(Evento.new(
		TipoEvento.HALLAZGO,
		"Libro interesante",
		"Has encontrado un libro fascinante en una librería de segunda mano. Aprender algo nuevo siempre es bueno.",
		{"necesidades": [0, 2, 0, 3, 0], "dinero": -15, "progreso": [0, 2, 0]},
		600, 1200  # 10:00–20:00
	))
	_eventos_disponibles.append(Evento.new(
		TipoEvento.HALLAZGO,
		"Material de manualidades",
		"Has encontrado material de manualidades tirado. ¡Puedes usarlo!",
		{"necesidades": [0, 0, 0, 0, 1], "dinero": 0, "progreso": [0, 0, 3]},
		540, 1080  # 9:00–18:00
	))

	# ---- INSPIRACIÓN ----
	_eventos_disponibles.append(Evento.new(
		TipoEvento.INSPIRACION,
		"Chispa de creatividad",
		"De repente te ha venido una idea genial. Te sientes inspirado.",
		{"necesidades": [0, 3, 0, 2, 0], "dinero": 0, "progreso": [0, 3, 2]}
	))
	_eventos_disponibles.append(Evento.new(
		TipoEvento.INSPIRACION,
		"Motivación repentina",
		"Te has levantado con una energía increíble. ¡Hoy puedes con todo!",
		{"necesidades": [3, 3, 0, 2, 2], "dinero": 0, "progreso": [2, 2, 2]},
		300, 600  # 5:00–10:00
	))


# ============================================================
# FUNCIÓN PRINCIPAL: se llama desde Actualizar_Horario() cada minuto
# ============================================================
func Tick_Eventos(celda_actual) -> void:
	# 1. Comprobar despido por higiene (solo si la celda actual es un trabajo)
	_Comprobar_Despido_Por_Higiene(celda_actual)

	# 2. Comprobar eventos generales
	_Comprobar_Evento_General()


# ============================================================
# DESPIDO POR HIGIENE
# ============================================================
func _Comprobar_Despido_Por_Higiene(celda_actual) -> void:
	# Solo aplica si la celda actual es un trabajo
	if not (celda_actual is Actividad_Fija_Trabajo):
		return

	# Solo si hay trabajo actual
	if Variables_Dinamicas.Trabajo_Actual == null:
		return

	# Solo si la higiene es ≤ 50
	var higiene = Variables_Dinamicas.Necesidades_Basicas[4]
	if higiene > 50:
		return

	# Fórmula: probabilidad = (50 - higiene) / 25000
	# (5 veces menor que la original /5000, como pediste)
	# higiene=50 → 0%, higiene=40 → 1/2500, higiene=20 → 1/833, higiene=1 → 1/510
	var divisor = int(25000.0 / max(1, 50 - higiene))
	if divisor < 2:
		divisor = 2

	if randi() % divisor != 0:
		return

	# ¡Te han despedido!
	_Despedir_Del_Trabajo()


func _Despedir_Del_Trabajo() -> void:
	var trabajo = Variables_Dinamicas.Trabajo_Actual
	if trabajo == null:
		return

	var nombre_trabajo = trabajo.nombre

	# Guardar el nombre del trabajo para el cooldown
	var minuto_actual = Variables_Dinamicas.Minute_Day * 1440 + Variables_Dinamicas.Minute_Minute
	Variables_Dinamicas.Cooldown_Trabajos[nombre_trabajo] = minuto_actual + COOLDOWN_TRABAJO_MINUTOS

	# Dejar el trabajo (borra todas las celdas futuras)
	Trabajo.Dejar_Trabajo(trabajo)

	# Enviar mensaje al jugador
	var msg = Mensaje.new()
	var nombre_legible = nombre_trabajo.replace("Trabajar_En_", "").replace("Trabajar_De_", "").replace("_", " ")
	msg.titulo = "¡Despedido!"
	msg.descripcion = "Te han despedido de tu trabajo como %s por falta de higiene.\n\nNo podrás volver a trabajar en %s durante 5 días." % [nombre_legible, nombre_legible]
	msg.leido = false
	msg.minuto = Variables_Dinamicas.Minute_Day * 1440 + Variables_Dinamicas.Minute_Minute
	Variables_Dinamicas.Mensajes.append(msg)

	Guardar_Variables_Dinamicas.save_game()


# ============================================================
# EVENTOS GENERALES
# ============================================================
func _Comprobar_Evento_General() -> void:
	minutos_sin_evento += 1

	# Calcular probabilidad: aumenta cuanto más tiempo sin evento
	var prob_actual = PROBABILIDAD_BASE
	if minutos_sin_evento > MINUTOS_SIN_EVENTO_BASE:
		var exceso = minutos_sin_evento - MINUTOS_SIN_EVENTO_BASE
		prob_actual = max(60, PROBABILIDAD_BASE - exceso)

	# 1/prob_actual de probabilidad por minuto
	if randi() % prob_actual != 0:
		return

	# ¡Evento! Seleccionar uno aleatorio
	var evento = _Seleccionar_Evento()
	if evento == null:
		return

	_Aplicar_Evento(evento)
	minutos_sin_evento = 0


func _Seleccionar_Evento() -> Evento:
	if _eventos_disponibles.size() == 0:
		return null

	var minuto_actual = Variables_Dinamicas.Minute_Minute

	# Media de necesidades para sesgos (calculada una sola vez)
	var media_necesidades = 0.0
	for n in Variables_Dinamicas.Necesidades_Basicas:
		media_necesidades += n
	media_necesidades /= Variables_Dinamicas.Necesidades_Basicas.size()

	# Pesos: 0 si el evento está fuera de su franja horaria
	var pesos = []
	for i in range(_eventos_disponibles.size()):
		var evento = _eventos_disponibles[i]

		if not evento.Es_Hora_Valida(minuto_actual):
			pesos.append(0.0)
			continue

		var peso_base = 1.0
		match evento.tipo:
			TipoEvento.ENFERMEDAD_LEVE, TipoEvento.ENFERMEDAD_GRAVE:
				if media_necesidades < 40:
					peso_base *= 2.0
				if media_necesidades < 20:
					peso_base *= 3.0

			TipoEvento.BONUS_DINERO, TipoEvento.BONUS_DINERO_GRANDE:
				if Variables_Dinamicas.Dinero < 100:
					peso_base *= 1.5

			TipoEvento.ACCIDENTE_LEVE, TipoEvento.ACCIDENTE_GRAVE:
				if Variables_Dinamicas.Necesidades_Basicas[0] < 30:
					peso_base *= 1.8

		pesos.append(peso_base)

	# Selección ponderada
	var suma_pesos = 0.0
	for p in pesos:
		suma_pesos += p

	# Si no hay ningún evento válido para esta hora, no ocurre nada
	if suma_pesos == 0.0:
		return null

	var r = randf() * suma_pesos
	var acum = 0.0
	for i in range(_eventos_disponibles.size()):
		acum += pesos[i]
		if r <= acum:
			return _eventos_disponibles[i]

	return null


func _Aplicar_Evento(evento: Evento) -> void:
	var efectos = evento.efectos

	# Aplicar efectos a necesidades básicas
	if efectos.has("necesidades"):
		var nec = efectos["necesidades"]
		for i in range(min(nec.size(), Variables_Dinamicas.Necesidades_Basicas.size())):
			if nec[i] != 0:
				var cambio = nec[i]
				if cambio > 0:
					Variables_Dinamicas.Necesidades_Basicas[i] = min(100, Variables_Dinamicas.Necesidades_Basicas[i] + cambio)
				else:
					Variables_Dinamicas.Necesidades_Basicas[i] = max(1, Variables_Dinamicas.Necesidades_Basicas[i] + cambio)
				# Respetar el cap de calle/bancarrota (igual que Cambiar_Necesidades_Basicas)
				if Variables_Dinamicas.En_La_Calle or Variables_Dinamicas.Dinero < 0:
					if Variables_Dinamicas.Necesidades_Basicas[i] > Variables_Estaticas.BANCARROTA_MAX_NECESIDAD:
						Variables_Dinamicas.Necesidades_Basicas[i] = Variables_Estaticas.BANCARROTA_MAX_NECESIDAD

	# Aplicar efectos a dinero
	if efectos.has("dinero"):
		var cantidad = efectos["dinero"]
		Variables_Dinamicas.Dinero = max(0, Variables_Dinamicas.Dinero + cantidad)

	# Aplicar efectos a progreso
	if efectos.has("progreso"):
		var prog = efectos["progreso"]
		for i in range(min(prog.size(), Variables_Dinamicas.Progreso.size())):
			if prog[i] != 0:
				Variables_Dinamicas.Progreso[i] = clamp(Variables_Dinamicas.Progreso[i] + prog[i], 0, 100)

	# Crear mensaje para el jugador
	var msg = Mensaje.new()
	msg.titulo = evento.titulo
	msg.descripcion = evento.descripcion + "\n\n" + _Generar_Resumen_Efectos(evento)
	msg.leido = false
	msg.minuto = Variables_Dinamicas.Minute_Day * 1440 + Variables_Dinamicas.Minute_Minute
	Variables_Dinamicas.Mensajes.append(msg)

	Guardar_Variables_Dinamicas.save_game()


func _Generar_Resumen_Efectos(evento: Evento) -> String:
	var lineas: Array = []
	var efectos = evento.efectos

	if efectos.has("necesidades"):
		var nec = efectos["necesidades"]
		var nombres_nec = ["Salud física", "Salud mental", "Hambre", "Energía", "Higiene"]
		for i in range(nec.size()):
			if nec[i] != 0:
				var signo = "+" if nec[i] > 0 else ""
				lineas.append("%s%d %s" % [signo, nec[i], nombres_nec[i]])

	if efectos.has("dinero"):
		var cant = efectos["dinero"]
		var signo = "+" if cant > 0 else ""
		lineas.append("%s%.0f €" % [signo, cant])

	if efectos.has("progreso"):
		var prog = efectos["progreso"]
		var nombres_prog = ["Deporte", "Académico", "Manualidades"]
		for i in range(prog.size()):
			if prog[i] != 0:
				var signo = "+" if prog[i] > 0 else ""
				lineas.append("%s%d %s" % [signo, prog[i], nombres_prog[i]])

	if lineas.size() == 0:
		return ""

	return "Efectos:\n" + "\n".join(lineas)


# ============================================================
# COMPROBACIÓN DE COOLDOWN (para usar desde Script_Principal)
# ============================================================

# Devuelve los minutos restantes de cooldown para un trabajo (0 si no está en cooldown)
func Minutos_Restantes_Cooldown(nombre_trabajo: String) -> int:
	if not Variables_Dinamicas.Cooldown_Trabajos.has(nombre_trabajo):
		return 0

	var minuto_actual = Variables_Dinamicas.Minute_Day * 1440 + Variables_Dinamicas.Minute_Minute
	var fin_cooldown = Variables_Dinamicas.Cooldown_Trabajos[nombre_trabajo]

	if minuto_actual >= fin_cooldown:
		# Cooldown expirado, limpiar
		Variables_Dinamicas.Cooldown_Trabajos.erase(nombre_trabajo)
		Guardar_Variables_Dinamicas.save_game()
		return 0

	return fin_cooldown - minuto_actual


# Comprueba si un trabajo está en cooldown y devuelve true si lo está
func Esta_En_Cooldown(nombre_trabajo: String) -> bool:
	return Minutos_Restantes_Cooldown(nombre_trabajo) > 0


# Limpia cooldowns expirados (se llama al cargar partida)
func Limpiar_Cooldowns_Expirados() -> void:
	var minuto_actual = Variables_Dinamicas.Minute_Day * 1440 + Variables_Dinamicas.Minute_Minute
	var cambios = false
	for trabajo in Variables_Dinamicas.Cooldown_Trabajos.keys():
		if minuto_actual >= Variables_Dinamicas.Cooldown_Trabajos[trabajo]:
			Variables_Dinamicas.Cooldown_Trabajos.erase(trabajo)
			cambios = true
	if cambios:
		Guardar_Variables_Dinamicas.save_game()
