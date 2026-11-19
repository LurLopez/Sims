extends Node

# ============================================================================
# Sistema de cocina, tuppers y alimentación dual.
# Toda la lógica "pura" de negocio vive aquí para poder probarla con GUT sin
# depender de la escena principal. Actividades.gd delega en este autoload.
# ============================================================================

const NOMBRE_COCINAR := "Cocinar"
const NOMBRE_TUPPER := "Comer_Tupper"
const NOMBRE_BASURA := "Comer_Basura"
const ESTADO_INTOXICACION := "Intoxicacion"

# Número de minutos que aporta un tupper completo (100 %).
const MINUTOS_COMIDOS_POR_TUPPER: int = 30
const PORCENTAJE_POR_MINUTO: float = 100.0 / float(MINUTOS_COMIDOS_POR_TUPPER)
const UMBRAL_TUPPER_AGOTADO: float = 0.01


func Coste_Cocinar() -> float:
	return Variables_Estaticas.Obtener_Coste_Cocinar()


func Coste_Comida_Basura() -> float:
	return Variables_Estaticas.Obtener_Coste_Comida_Basura()


func Validar_Cocinar(duracion_min: int, en_la_calle: bool) -> Dictionary:
	if en_la_calle:
		return {"valido": false, "motivo": "No puedes cocinar sin una vivienda."}
	if duracion_min < Variables_Estaticas.MINUTOS_POR_TUPPER:
		return {
			"valido": false,
			"motivo": "Cocinar requiere al menos %d minutos." % Variables_Estaticas.MINUTOS_POR_TUPPER
		}
	return {"valido": true, "motivo": ""}


# ============================================================================
# Cocina
# ============================================================================

func Ejecutar_Minuto_Cocinar() -> Dictionary:
	if Variables_Dinamicas.En_La_Calle:
		Cancelar_Bloque_Actual(NOMBRE_COCINAR)
		Variables_Dinamicas.Minutos_Cocinando_Actuales = 0
		Añadir_Mensaje("Cocina cancelada",
			"No puedes cocinar sin una vivienda. Se ha cancelado la actividad de cocinar.")
		return {"cancelado": true, "producido": false, "motivo": "sin_vivienda"}

	var coste: float = Coste_Cocinar()
	if Variables_Dinamicas.Dinero < coste:
		Cancelar_Bloque_Actual(NOMBRE_COCINAR)
		Variables_Dinamicas.Minutos_Cocinando_Actuales = 0
		Añadir_Mensaje("Sin ingredientes",
			"No tienes dinero suficiente para comprar ingredientes. Se ha cancelado la actividad de cocinar.")
		return {"cancelado": true, "producido": false, "motivo": "sin_dinero"}

	# Progreso de cocina y descubrimiento de habilidades innatas.
	Actividades_Habilidades.Ejecutar_Progreso_Cocina()
	Actividades_Habilidades.Ejecutar_Descubrimiento_Cocina()

	Variables_Dinamicas.Minutos_Cocinando_Actuales += 1
	var producido: bool = false
	if Variables_Dinamicas.Minutos_Cocinando_Actuales % Variables_Estaticas.MINUTOS_POR_TUPPER == 0:
		Variables_Dinamicas.Dinero -= coste
		Crear_Tupper()
		producido = true

	return {"cancelado": false, "producido": producido, "coste": coste}


func Crear_Tupper() -> Dictionary:
	var nuevo_id: int = _Siguiente_Id_Tupper()
	var tupper: Dictionary = {
		"id": nuevo_id,
		"porcentaje_restante": 100.0,
		"calidad": clampi(Variables_Dinamicas.Progreso_Cocina, 1, 100),
		"minuto_creacion": int(Variables_Dinamicas.Minute),
		"minuto_caducidad": int(Variables_Dinamicas.Minute) + Variables_Estaticas.Obtener_Minutos_Caducidad_Tupper()
	}
	Variables_Dinamicas.Tuppers.append(tupper)
	return tupper


func _Siguiente_Id_Tupper() -> int:
	var maximo: int = 0
	for t in Variables_Dinamicas.Tuppers:
		if t is Dictionary:
			maximo = maxi(maximo, int(t.get("id", 0)))
	return maximo + 1


# ============================================================================
# Tuppers: caducidad, selección y consumo
# ============================================================================

func Es_Tupper_Caducado(tupper: Dictionary) -> bool:
	return int(Variables_Dinamicas.Minute) > int(tupper.get("minuto_caducidad", 0))


func Tiene_Tupper_Vigente() -> bool:
	for t in Variables_Dinamicas.Tuppers:
		if t is Dictionary and not Es_Tupper_Caducado(t):
			return true
	return false


func Contar_Tuppers_Vigentes() -> int:
	var total: int = 0
	for t in Variables_Dinamicas.Tuppers:
		if t is Dictionary and not Es_Tupper_Caducado(t):
			total += 1
	return total


# Selección automática: primero los vigentes, priorizando los ya empezados y
# los que caducan antes. Si solo quedan caducados, el menos caducado.
func Obtener_Indice_Tupper_Auto() -> int:
	if Variables_Dinamicas.Tuppers.is_empty():
		return -1

	var mejor_vigente: int = -1
	var mejor_vigente_prioridad: int = 999
	var mejor_vigente_caducidad: int = 0

	var mejor_caducado: int = -1
	var mejor_caducado_caducidad: int = -1

	for i in range(Variables_Dinamicas.Tuppers.size()):
		var t = Variables_Dinamicas.Tuppers[i]
		if not (t is Dictionary):
			continue
		var caducidad: int = int(t.get("minuto_caducidad", 0))
		var caducado: bool = Es_Tupper_Caducado(t)
		if caducado:
			# El menos caducado es el que tiene la caducidad más lejana.
			if mejor_caducado == -1 or caducidad > mejor_caducado_caducidad:
				mejor_caducado = i
				mejor_caducado_caducidad = caducidad
		else:
			var restante: float = float(t.get("porcentaje_restante", 100.0))
			var prioridad: int = 0 if restante < 99.99 else 1
			if mejor_vigente == -1 \
					or prioridad < mejor_vigente_prioridad \
					or (prioridad == mejor_vigente_prioridad and caducidad < mejor_vigente_caducidad):
				mejor_vigente = i
				mejor_vigente_prioridad = prioridad
				mejor_vigente_caducidad = caducidad

	if mejor_vigente != -1:
		return mejor_vigente
	return mejor_caducado


func Obtener_Indice_Tupper_Activo(es_aleatoria: bool = false) -> int:
	if es_aleatoria:
		return Obtener_Indice_Tupper_Auto()
	var idx: int = Variables_Dinamicas.Tupper_Seleccionado_Idx
	if idx >= 0 and idx < Variables_Dinamicas.Tuppers.size():
		return idx
	return Obtener_Indice_Tupper_Auto()


func Obtener_Efectos_Comer_Tupper(calidad: int) -> Array:
	var fisico: int = 1
	if calidad >= 71:
		fisico = 3
	elif calidad >= 31:
		fisico = 2
	var mental: int = 3 if calidad > 60 else 2
	return [fisico, mental, 20, -1, -1]


func Ejecutar_Minuto_Comer_Tupper(es_aleatoria: bool = false) -> Dictionary:
	var idx: int = Obtener_Indice_Tupper_Activo(es_aleatoria)
	if idx < 0 or idx >= Variables_Dinamicas.Tuppers.size():
		# Sin tuppers: el bloque continúa como comida rápida (cobrando).
		var convertidas: int = Convertir_Bloque_Actual_A(NOMBRE_BASURA)
		if convertidas > 0:
			return Ejecutar_Minuto_Comer_Basura()
		return {"cancelado": true, "motivo": "sin_tuppers", "convertido": false}

	var tupper: Dictionary = Variables_Dinamicas.Tuppers[idx]
	var calidad: int = clampi(int(tupper.get("calidad", 1)), 1, 100)
	var efectos: Array = Obtener_Efectos_Comer_Tupper(calidad)
	Actividades_Necesidades_Basicas.Ejecutar_Actividad_Necesidades_Basicas_Array(efectos, NOMBRE_TUPPER)

	var restante: float = float(tupper.get("porcentaje_restante", 100.0)) - PORCENTAJE_POR_MINUTO
	tupper["porcentaje_restante"] = maxf(0.0, restante)

	var intoxicado: bool = false
	var caducidad: int = int(tupper.get("minuto_caducidad", 0))
	if int(Variables_Dinamicas.Minute) > caducidad:
		intoxicado = _Intentar_Intoxicacion(int(Variables_Dinamicas.Minute) - caducidad)

	var agotado: bool = false
	if float(tupper.get("porcentaje_restante", 0.0)) <= UMBRAL_TUPPER_AGOTADO:
		agotado = true
		Variables_Dinamicas.Tuppers.remove_at(idx)
		Variables_Dinamicas.Tupper_Seleccionado_Idx = -1
		# Si ya no queda ningún tupper, el resto del bloque pasa a comida rápida.
		if Variables_Dinamicas.Tuppers.is_empty():
			Convertir_Bloque_Siguiente_A(NOMBRE_BASURA)

	return {
		"cancelado": false,
		"agotado": agotado,
		"intoxicado": intoxicado,
		"calidad": calidad,
		"indice": idx
	}


# ============================================================================
# Comida rápida / basura
# ============================================================================

func Ejecutar_Minuto_Comer_Basura() -> Dictionary:
	var coste: float = Coste_Comida_Basura()
	var debe_cobrar: bool = int(Variables_Dinamicas.Minute_Minute) % 5 == 0

	if debe_cobrar:
		if Variables_Dinamicas.Dinero < coste:
			Cancelar_Bloque_Actual(NOMBRE_BASURA)
			Variables_Dinamicas.Minutos_Cocinando_Actuales = 0
			Añadir_Mensaje("Sin dinero para comer",
				"No tienes dinero para continuar pagando la comida rápida. Te has quedado sin comer.")
			return {"cancelado": true, "cobrado": false, "coste": coste}
		Variables_Dinamicas.Dinero -= coste

	Actividades_Necesidades_Basicas.Ejecutar_Actividad_Necesidades_Basicas_Array(
		[-2, 2, 20, -1, -1], NOMBRE_BASURA)
	return {"cancelado": false, "cobrado": debe_cobrar, "coste": coste}


# ============================================================================
# IA pasiva: nunca come gratis. Prioriza tupper vigente; si no hay, basura si
# puede pagarla; si solo quedan caducados y no hay dinero, usa el menos malo.
# ============================================================================

func Elegir_Comida_IA() -> Actividad:
	if Tiene_Tupper_Vigente():
		return Variables_Estaticas.Catalogo_Actividades[NOMBRE_TUPPER]
	if Variables_Dinamicas.Dinero >= Coste_Comida_Basura():
		return Variables_Estaticas.Catalogo_Actividades[NOMBRE_BASURA]
	if not Variables_Dinamicas.Tuppers.is_empty():
		return Variables_Estaticas.Catalogo_Actividades[NOMBRE_TUPPER]
	return Variables_Estaticas.Catalogo_Actividades["Ver_La_Television"]


# ============================================================================
# Intoxicación
# ============================================================================

func Calcular_Prob_Intoxicacion_30min(minutos_caducado: int) -> float:
	var horas: float = maxf(0.0, float(minutos_caducado)) / 60.0
	return clampf(horas / 48.0, 0.05, 1.0)


func Calcular_Prob_Intoxicacion_Minuto(minutos_caducado: int) -> float:
	var p30: float = Calcular_Prob_Intoxicacion_30min(minutos_caducado)
	if p30 >= 1.0:
		return 1.0
	return 1.0 - pow(1.0 - p30, 1.0 / 30.0)


func _Intentar_Intoxicacion(minutos_caducado: int) -> bool:
	if Variables_Dinamicas.Estados_Temporales.has(ESTADO_INTOXICACION):
		return false
	if randf() < Calcular_Prob_Intoxicacion_Minuto(minutos_caducado):
		Actividades.Activar_Estado(ESTADO_INTOXICACION)
		return true
	return false


# ============================================================================
# Gestión de bloques en la matriz
# ============================================================================

# Limpia la celda actual y todas las contiguas hacia adelante que pertenezcan
# al mismo bloque de la actividad indicada.
func Cancelar_Bloque_Actual(nombre_actividad: String) -> int:
	return _Modificar_Bloque(nombre_actividad, "", false)


# Convierte la celda actual y las contiguas del bloque a otra actividad.
func Convertir_Bloque_Actual_A(nombre_nuevo: String) -> int:
	return _Modificar_Bloque(NOMBRE_TUPPER, nombre_nuevo, false)


# Convierte solo las celdas futuras del bloque (deja intacta la actual).
func Convertir_Bloque_Siguiente_A(nombre_nuevo: String) -> int:
	return _Modificar_Bloque(NOMBRE_TUPPER, nombre_nuevo, true)


func _Modificar_Bloque(nombre_actual: String, nombre_nuevo: String, desde_siguiente: bool) -> int:
	if nombre_actual == "":
		return 0
	if Variables_Dinamicas.Matriz_Jugador.size() < 1440:
		return 0
	var valor_nuevo
	if nombre_nuevo == "":
		valor_nuevo = ""
	elif Variables_Estaticas.Catalogo_Actividades.has(nombre_nuevo):
		valor_nuevo = Variables_Estaticas.Catalogo_Actividades[nombre_nuevo]
	else:
		return 0

	var dia: int = int(Variables_Dinamicas.Minute_Day)
	var minuto: int = int(Variables_Dinamicas.Minute_Minute)
	if desde_siguiente:
		minuto += 1
		if minuto >= 1440:
			minuto = 0
			dia += 1

	var cambiadas: int = 0
	while dia < 574:
		var celda = Variables_Dinamicas.Matriz_Jugador[minuto][dia]
		if not (celda is Actividad) or celda.nombre != nombre_actual:
			break
		Variables_Dinamicas.Matriz_Jugador[minuto][dia] = valor_nuevo
		cambiadas += 1
		minuto += 1
		if minuto >= 1440:
			minuto = 0
			dia += 1

	if cambiadas > 0:
		Variables_Dinamicas.Matriz_Sucia = true
	return cambiadas


# ============================================================================
# Utilidades de formato y mensajes
# ============================================================================

func Formatear_Porcentaje(valor: float) -> String:
	if valor >= 99.95:
		return "100%"
	return String.num(valor, 1).replace(".", ",") + "%"


func Formatear_Caducidad(tupper: Dictionary) -> String:
	var restante: int = int(tupper.get("minuto_caducidad", 0)) - int(Variables_Dinamicas.Minute)
	if restante >= 0:
		var dias: int = restante / 1440
		var horas: int = (restante % 1440) / 60
		var minutos: int = restante % 60
		if dias > 0:
			return "Caduca en %dd %dh" % [dias, horas]
		if horas > 0:
			return "Caduca en %dh %02dm" % [horas, minutos]
		return "Caduca en %d min" % minutos

	var pasados: int = -restante
	var dias_p: int = pasados / 1440
	var horas_p: int = (pasados % 1440) / 60
	var minutos_p: int = pasados % 60
	if dias_p > 0:
		return "CADUCADO hace %dd %dh" % [dias_p, horas_p]
	if horas_p > 0:
		return "CADUCADO hace %dh %02dm" % [horas_p, minutos_p]
	return "CADUCADO hace %d min" % minutos_p


func Añadir_Mensaje(titulo: String, descripcion: String) -> void:
	var msg = Mensaje.new()
	msg.titulo = titulo
	msg.descripcion = descripcion
	msg.leido = false
	msg.minuto = Variables_Dinamicas.Minute_Day * 1440 + Variables_Dinamicas.Minute_Minute
	Variables_Dinamicas.Mensajes.append(msg)
