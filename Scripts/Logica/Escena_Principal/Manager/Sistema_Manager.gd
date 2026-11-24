extends Node

# Autoload de «El Mánager» (Fase 2 — Modo Club Top Eleven).
# Orquesta el estado persistente de Variables_Dinamicas.Manager_Estado, el
# calendario dominical/diario, el partido en vivo de 90 minutos, el mercado,
# la economía del club y la fachada que consume la interfaz.
# Toda la matemática vive en Simulador_Manager; aquí solo se aplica al estado.

const NOMBRE_ESTADO_LESION := "Lesion_Deportiva"

# QA: deja «El Mánager» desbloqueado desde el inicio para poder probarlo sin
# retirarse ni pagar el título. Poner en false antes de publicar.
const DESBLOQUEO_MANAGER_QA: bool = true

var _partido_en_vivo: Dictionary = {}
var _partido_aplicado: bool = false
var _jornadas_pendientes: Array = []
var _procesando_jornadas_pendientes: bool = false


func _ready() -> void:
	Asegurar_Desbloqueo_QA()


func Asegurar_Desbloqueo_QA() -> void:
	if not DESBLOQUEO_MANAGER_QA:
		return
	var est: Dictionary = Variables_Dinamicas.Manager_Estado
	if est.is_empty():
		est = Variables_Dinamicas.Manager_Estado_Por_Defecto()
	est["Desbloqueado"] = true
	if int(est.get("Reputacion", 0)) < 25:
		est["Reputacion"] = 25
	Variables_Dinamicas.Manager_Estado = est


# ------------------------------------------------------------------
# Consultas de estado
# ------------------------------------------------------------------

func Estado() -> Dictionary:
	return Variables_Dinamicas.Manager_Estado


func Activo() -> bool:
	return bool(Estado().get("Activo", false))


func Desbloqueado() -> bool:
	return bool(Estado().get("Desbloqueado", false))


func Retirado_Como_Jugador() -> bool:
	return bool(Estado().get("Retirado_Como_Jugador", false))


func Obtener_Reputacion() -> int:
	return clampi(int(Estado().get("Reputacion", 0)), 0, 100)


func Obtener_Temporada() -> int:
	return maxi(1, int(Estado().get("Temporada", 1)))


func Obtener_Jornada() -> int:
	return clampi(int(Estado().get("Jornada_Actual", 0)), 0, 4)


func Club_Usuario_Id() -> String:
	return str(Estado().get("Club_Usuario_Id", "club_usr"))


func Obtener_Clubes() -> Dictionary:
	var clubes = Estado().get("Clubes", {})
	if clubes is Dictionary:
		return clubes
	return {}


func Obtener_Club(club_id: String) -> Dictionary:
	var clubes: Dictionary = Obtener_Clubes()
	var club = clubes.get(club_id, null)
	if club is Dictionary:
		return club
	return {}


func Club_Usuario() -> Dictionary:
	return Obtener_Club(Club_Usuario_Id())


func Division_Usuario() -> int:
	var club: Dictionary = Club_Usuario()
	if club.is_empty():
		return 4
	return clampi(int(club.get("division", 4)), 1, 4)


func Obtener_Divisiones() -> Dictionary:
	var divisiones = Estado().get("Divisiones", {})
	if divisiones is Dictionary:
		return divisiones
	return {}


func Obtener_Nombre_Club(club_id: String) -> String:
	var club: Dictionary = Obtener_Club(club_id)
	return str(club.get("nombre", "Club"))


func Buscar_Jugador(jugador_id: String) -> Dictionary:
	var clubes: Dictionary = Obtener_Clubes()
	for club_id in clubes.keys():
		var club = clubes[club_id]
		if not (club is Dictionary):
			continue
		var plantilla = club.get("plantilla", [])
		if not (plantilla is Array):
			continue
		for jugador in plantilla:
			if jugador is Dictionary and str(jugador.get("id", "")) == jugador_id:
				return jugador
	return {}


func Club_De_Jugador(jugador_id: String) -> String:
	var clubes: Dictionary = Obtener_Clubes()
	for club_id in clubes.keys():
		var club = clubes[club_id]
		if not (club is Dictionary):
			continue
		var plantilla = club.get("plantilla", [])
		if not (plantilla is Array):
			continue
		for jugador in plantilla:
			if jugador is Dictionary and str(jugador.get("id", "")) == jugador_id:
				return str(club_id)
	return ""


func Obtener_Jugador_De_Club(club_id: String, jugador_id: String) -> Dictionary:
	var club: Dictionary = Obtener_Club(club_id)
	var plantilla = club.get("plantilla", [])
	if plantilla is Array:
		for jugador in plantilla:
			if jugador is Dictionary and str(jugador.get("id", "")) == jugador_id:
				return jugador
	return {}


# ------------------------------------------------------------------
# Resúmenes para la interfaz
# ------------------------------------------------------------------

func Resumen_Plantilla(club: Dictionary) -> Dictionary:
	var plantilla = club.get("plantilla", [])
	if not (plantilla is Array):
		plantilla = []
	var suma_calidad: float = 0.0
	var valor_total: int = 0
	var nomina: int = 0
	var edad_total: int = 0
	var mejor_calidad: float = 0.0
	for jugador in plantilla:
		if not (jugador is Dictionary):
			continue
		var calidad: float = float(jugador.get("calidad", 0.0))
		suma_calidad += calidad
		mejor_calidad = maxf(mejor_calidad, calidad)
		valor_total += int(jugador.get("valor_mercado", 0))
		nomina += int(jugador.get("salario_semanal", 0))
		edad_total += int(jugador.get("edad", 18))
	var tamano: int = plantilla.size()
	var media: float = suma_calidad / float(maxi(tamano, 1))
	return {
		"tamano": tamano,
		"calidad_media": media,
		"estrellas": Simulador_Manager.Calcular_Estrellas(media),
		"mejor_calidad": mejor_calidad,
		"valor_total": valor_total,
		"nomina": nomina,
		"edad_media": float(edad_total) / float(maxi(tamano, 1)),
		"maximo": Datos_Manager.PLANTILLA_MAXIMA,
		"minimo": Datos_Manager.PLANTILLA_MINIMA
	}


func Obtener_Clasificacion(division: int) -> Array:
	var clubes: Dictionary = Obtener_Clubes()
	var divisiones: Dictionary = Obtener_Divisiones()
	var ids = divisiones.get(str(clampi(division, 1, 4)), [])
	if not (ids is Array):
		ids = []
	var orden: Array = Simulador_Manager.Ordenar_Clasificacion(clubes, ids)
	var resultado: Array = []
	var usuario_id: String = Club_Usuario_Id()
	for i in range(orden.size()):
		var entrada: Dictionary = orden[i]
		var club: Dictionary = Obtener_Club(str(entrada["id"]))
		var resumen: Dictionary = Resumen_Plantilla(club)
		var v_p: int = int(club.get("victorias", 0))
		var e_p: int = int(club.get("empates", 0))
		var d_p: int = int(club.get("derrotas", 0))
		resultado.append({
			"posicion": i + 1,
			"id": str(entrada["id"]),
			"nombre": str(club.get("nombre", "")),
			"ciudad": str(club.get("ciudad", "")),
			"puntos": int(entrada["puntos"]),
			"partidos": v_p + e_p + d_p,
			"victorias": v_p,
			"empates": e_p,
			"derrotas": d_p,
			"racha": club.get("racha", []),
			"goles_favor": int(entrada["goles_favor"]),
			"goles_contra": int(entrada["goles_contra"]),
			"diferencia": int(entrada["diferencia"]),
			"es_usuario": str(entrada["id"]) == usuario_id,
			"calidad": float(resumen.get("calidad_media", 0.0)),
			"estrellas": int(resumen.get("estrellas", 1)),
			"colores": club.get("colores", Datos_Manager.COLORES_POR_DEFECTO),
			"escudo_patron": int(club.get("escudo_patron", 1))
		})
	return resultado


func Obtener_Posicion_Usuario() -> int:
	var clasificacion: Array = Obtener_Clasificacion(Division_Usuario())
	for entrada in clasificacion:
		if bool(entrada.get("es_usuario", false)):
			return int(entrada.get("posicion", 1))
	return 1


func Obtener_Ultimos_Resultados() -> Array:
	var resultados = Estado().get("Ultimos_Resultados", [])
	if resultados is Array:
		return resultados
	return []


func Obtener_Historial() -> Array:
	var historial = Estado().get("Historial", [])
	if historial is Array:
		return historial
	return []


func Obtener_Proximo_Partido_Texto() -> String:
	var est: Dictionary = Estado()
	if bool(est.get("Partido_Pendiente", false)):
		var local_id: String = str(est.get("Partido_Local_Id", ""))
		var visitante_id: String = str(est.get("Partido_Visitante_Id", ""))
		return "Pendiente · %s vs %s · Jornada %d" % [
			Obtener_Nombre_Club(local_id), Obtener_Nombre_Club(visitante_id),
			int(est.get("Partido_Jornada", 0)) + 1]
	if Variables_Estaticas.Modo_Rapido:
		return "Todos los días · %s" % Datos_Manager.Formatear_Hora(
			Datos_Manager.HORA_PARTIDO_RAPIDO)
	var horas: Array[String] = []
	for hora in Datos_Manager.HORAS_PARTIDO_NORMAL:
		horas.append(Datos_Manager.Formatear_Hora(int(hora)))
	return "Domingos · %s" % " · ".join(horas)


func Obtener_Resumen_Calendario() -> String:
	if Variables_Estaticas.Modo_Rapido:
		return "Modo rápido: una jornada cada día a las %s. La temporada dura 4 jornadas." % \
			Datos_Manager.Formatear_Hora(Datos_Manager.HORA_PARTIDO_RAPIDO)
	return "Modo normal: cada domingo se disputan las 4 jornadas (10:00, 13:00, 16:00 y playoff a las 19:00). Si no juegas, el partido se auto-simula a las 23:59."


func Puede_Jugar_Manual() -> bool:
	return Activo() and bool(Estado().get("Partido_Pendiente", false))


func Hay_Novedad() -> bool:
	return Puede_Jugar_Manual() or (Desbloqueado() and not Activo())


func Obtener_Proximo_Rival_Estimado() -> Dictionary:
	if not Activo():
		return {}
	var est: Dictionary = Estado()
	var usuario_id: String = Club_Usuario_Id()
	if bool(est.get("Partido_Pendiente", false)):
		var loc_id: String = str(est.get("Partido_Local_Id", ""))
		var vis_id: String = str(est.get("Partido_Visitante_Id", ""))
		var rival_id: String = vis_id if loc_id == usuario_id else loc_id
		return {
			"local_id": loc_id,
			"visitante_id": vis_id,
			"rival_id": rival_id,
			"es_local": loc_id == usuario_id,
			"jornada": int(est.get("Partido_Jornada", 0)),
			"pendiente": true
		}
	var jornada: int = Obtener_Jornada()
	var parejas: Array = Obtener_Emparejamientos_Division(Division_Usuario(), jornada)
	for par in parejas:
		var l_id: String = str(par.get("local_id", ""))
		var v_id: String = str(par.get("visitante_id", ""))
		if l_id == usuario_id or v_id == usuario_id:
			return {
				"local_id": l_id,
				"visitante_id": v_id,
				"rival_id": v_id if l_id == usuario_id else l_id,
				"es_local": l_id == usuario_id,
				"jornada": jornada,
				"pendiente": false
			}
	return {}


func Obtener_Emparejamientos_Division(division: int, jornada: int = -1) -> Array:
	var clubes: Dictionary = Obtener_Clubes()
	var divisiones: Dictionary = Obtener_Divisiones()
	var ids = divisiones.get(str(clampi(division, 1, 4)), [])
	if not (ids is Array) or ids.size() < 2:
		return []
	var j: int = Obtener_Jornada() if jornada < 0 else clampi(jornada, 0, 3)
	var orden: Array = Simulador_Manager.Ordenar_Clasificacion(clubes, ids)
	var ids_orden: Array = []
	for entrada in orden:
		ids_orden.append(str(entrada["id"]))
	var parejas: Array = Simulador_Manager.Parejas_Jornada_Division(j, ids_orden)
	var salida: Array = []
	for pareja in parejas:
		if pareja.size() >= 2:
			salida.append({
				"local_id": str(pareja[0]),
				"visitante_id": str(pareja[1]),
				"jornada": j
			})
	return salida


func Obtener_Lideres_Division(division: int) -> Dictionary:
	var clubes: Dictionary = Obtener_Clubes()
	var divisiones: Dictionary = Obtener_Divisiones()
	var ids = divisiones.get(str(clampi(division, 1, 4)), [])
	var goleadores: Array = []
	var asistentes: Array = []
	if ids is Array:
		for club_id in ids:
			var club: Dictionary = Obtener_Club(str(club_id))
			if club.is_empty():
				continue
			var nombre_club: String = str(club.get("nombre", ""))
			var colores: Array = club.get("colores", Datos_Manager.COLORES_POR_DEFECTO)
			var patron: int = int(club.get("escudo_patron", 1))
			for jugador in club.get("plantilla", []):
				if not (jugador is Dictionary):
					continue
				if int(jugador.get("goles", 0)) > 0:
					goleadores.append({
						"jugador": jugador,
						"club_id": str(club_id),
						"club_nombre": nombre_club,
						"colores": colores,
						"patron": patron,
						"valor": int(jugador.get("goles", 0))
					})
				if int(jugador.get("asistencias", 0)) > 0:
					asistentes.append({
						"jugador": jugador,
						"club_id": str(club_id),
						"club_nombre": nombre_club,
						"colores": colores,
						"patron": patron,
						"valor": int(jugador.get("asistencias", 0))
					})
	goleadores.sort_custom(func(a, b):
		if int(a["valor"]) != int(b["valor"]):
			return int(a["valor"]) > int(b["valor"])
		return float(a["jugador"].get("calidad", 0.0)) > float(b["jugador"].get("calidad", 0.0)))
	asistentes.sort_custom(func(a, b):
		if int(a["valor"]) != int(b["valor"]):
			return int(a["valor"]) > int(b["valor"])
		return float(a["jugador"].get("calidad", 0.0)) > float(b["jugador"].get("calidad", 0.0)))
	return {
		"goleadores": goleadores.slice(0, 5),
		"asistentes": asistentes.slice(0, 5)
	}


func Texto_Partido_Pendiente() -> String:
	if not Puede_Jugar_Manual():
		return "No hay ningún partido pendiente ahora mismo."
	var est: Dictionary = Estado()
	return "%s vs %s · Jornada %d · Temporada %d" % [
		Obtener_Nombre_Club(str(est.get("Partido_Local_Id", ""))),
		Obtener_Nombre_Club(str(est.get("Partido_Visitante_Id", ""))),
		int(est.get("Partido_Jornada", 0)) + 1,
		Obtener_Temporada()]


# ------------------------------------------------------------------
# Desbloqueo y fundación
# ------------------------------------------------------------------

func Puede_Desbloquear_Por_Retiro() -> bool:
	return not Desbloqueado() and Sistema_Futbol.Puede_Retirarse()


func Coste_Desbloqueo_Titulo() -> int:
	return int(round(float(Datos_Manager.COSTE_DESBLOQUEO_TITULO)
		* Variables_Estaticas.Multiplicador_Precios()))


func _Calcular_Reputacion_Legado() -> int:
	var est: Dictionary = Variables_Dinamicas.Carrera_Futbol
	var reputacion: int = 18
	reputacion += int(est.get("Titulos_Superliga", 0)) * 10
	reputacion += mini(20, int(est.get("Partidos_Jugados", 0)) / 10)
	reputacion += mini(12, int(est.get("Goles_Totales", 0)) / 20)
	if int(est.get("Division", 4)) == 1:
		reputacion += 8
	if str(est.get("Estado_Temporada", "")) == "Campeon":
		reputacion += 6
	return clampi(reputacion, 15, 70)


func Desbloquear_Por_Retiro() -> Dictionary:
	if Desbloqueado():
		return {"ok": false, "motivo": "El modo ya está desbloqueado."}
	if not Sistema_Futbol.Puede_Retirarse():
		return {"ok": false, "motivo": "Aún no puedes retirarte como futbolista."}
	var est: Dictionary = Estado()
	est["Reputacion"] = _Calcular_Reputacion_Legado()
	est["Retirado_Como_Jugador"] = true
	est["Desbloqueado"] = true
	Sistema_Futbol.Retirarse_Como_Jugador()
	_Mensaje("Modo mánager desbloqueado",
		"Tu legado como futbolista te ha abierto las puertas del banquillo. Funda tu propio club en la 3ª Regional.")
	Guardar_Variables_Dinamicas.save_game()
	return {"ok": true, "motivo": "", "reputacion": int(est["Reputacion"])}


func Desbloquear_Por_Titulo() -> Dictionary:
	if Desbloqueado():
		return {"ok": false, "motivo": "El modo ya está desbloqueado."}
	if Sistema_Futbol.Carrera_Activa():
		return {"ok": false, "motivo": "Tienes una carrera de futbolista en activo. Rescinde tu contrato o retírate antes de pagar el título."}
	var coste: int = Coste_Desbloqueo_Titulo()
	if int(Variables_Dinamicas.Dinero) < coste:
		return {"ok": false, "motivo": "Necesitas %d € para obtener el título de entrenador." % coste}
	Variables_Dinamicas.Dinero -= coste
	var est: Dictionary = Estado()
	est["Reputacion"] = Datos_Manager.REPUTACION_INICIAL
	est["Desbloqueado"] = true
	_Mensaje("Título de entrenador",
		"Has pagado %d € por el título oficial de entrenador. Ya puedes fundar tu propio club." % coste)
	Guardar_Variables_Dinamicas.save_game()
	return {"ok": true, "motivo": "", "reputacion": Datos_Manager.REPUTACION_INICIAL}


func Fundar_Club(nombre: String, colores: Array, patron: int, ciudad: String = "") -> Dictionary:
	if not Desbloqueado():
		return {"ok": false, "motivo": "Primero debes desbloquear el modo mánager."}
	if Activo():
		return {"ok": false, "motivo": "Ya tienes un club fundado."}
	var nombre_limpio: String = nombre.strip_edges()
	if nombre_limpio.length() < 2:
		return {"ok": false, "motivo": "El nombre del club debe tener al menos 2 caracteres."}
	if nombre_limpio.length() > 26:
		nombre_limpio = nombre_limpio.substr(0, 26)
	for club_ia in Datos_Manager.CLUBES_IA:
		if str(club_ia.get("nombre", "")).to_lower() == nombre_limpio.to_lower():
			return {"ok": false, "motivo": "Ya existe un club con ese nombre en el ecosistema. Elige otro."}
	var colores_finales: Array = []
	for color in colores:
		var texto: String = str(color)
		if texto.length() == 7 and texto.begins_with("#"):
			colores_finales.append(texto)
	while colores_finales.size() < 2:
		colores_finales.append(str(Datos_Manager.COLORES_POR_DEFECTO[colores_finales.size()]))
	if colores_finales[0] == colores_finales[1]:
		return {"ok": false, "motivo": "Elige dos colores distintos para que el escudo se lea bien."}

	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var ecosistema: Dictionary = Simulador_Manager.Crear_Ecosistema(
		nombre_limpio, colores_finales,
		clampi(patron, 0, Datos_Manager.PATRONES_ESCUDO.size() - 1), rng, ciudad)
	var est: Dictionary = Estado()
	est["Version"] = Datos_Manager.VERSION_ESTADO
	est["Desbloqueado"] = true
	est["Titulo_Entrenador"] = true
	est["Activo"] = true
	est["Temporada"] = 1
	est["Jornada_Actual"] = 0
	est["Semana_Tick"] = -1
	est["Dia_Tick"] = -1
	est["Partido_Pendiente"] = false
	est["Partido_Local_Id"] = ""
	est["Partido_Visitante_Id"] = ""
	est["Partido_Es_Local"] = false
	est["Partido_Jornada"] = 0
	est["Ultima_Jornada_Iniciada"] = -1
	est["Clubes"] = ecosistema["Clubes"]
	est["Divisiones"] = ecosistema["Divisiones"]
	est["Ultimo_Dia_Nomina"] = -1
	est["Ultimos_Resultados"] = []
	est["Historial"] = []
	_partido_en_vivo = {}
	_partido_aplicado = false
	_jornadas_pendientes.clear()

	_Mensaje("Club fundado",
		"Has fundado %s. Empiezas en la 3ª Regional con 18 futbolistas y %d € de presupuesto. ¡Llévalo a la Superliga!" % [
			nombre_limpio, Datos_Manager.PRESUPUESTO_INICIAL_USUARIO])
	Guardar_Variables_Dinamicas.save_game()
	return {"ok": true, "motivo": "", "club_id": Club_Usuario_Id()}


# ------------------------------------------------------------------
# Tick por minuto
# ------------------------------------------------------------------

func Tick_Minuto() -> void:
	var est: Dictionary = Estado()
	if not bool(est.get("Activo", false)):
		return
	if Variables_Dinamicas.Matriz_Jugador.is_empty():
		return

	# Recuperación de energía: cada 10 minutos de juego.
	if Variables_Dinamicas.Minute_Minute % 10 == 0:
		_Recuperar_Energia(10.0)

	# Envejecimiento y nóminas.
	if Variables_Estaticas.Modo_Rapido:
		if Variables_Dinamicas.Minute_Minute == 0:
			_Procesar_Dia_Nuevo()
	else:
		if Variables_Dinamicas.Minute_Day % 7 == 0 and Variables_Dinamicas.Minute_Minute == 0:
			_Procesar_Semana_Nueva()

	# Calendario de partidos.
	if Variables_Estaticas.Modo_Rapido:
		if Variables_Dinamicas.Minute_Minute == Datos_Manager.HORA_PARTIDO_RAPIDO:
			_Iniciar_Jornada(Obtener_Jornada())
	else:
		var indice: int = Datos_Manager.HORAS_PARTIDO_NORMAL.find(Variables_Dinamicas.Minute_Minute)
		if indice >= 0:
			_Iniciar_Jornada(indice)

	# Auto-simulación al cierre de la jornada.
	if Variables_Dinamicas.Minute_Minute == Datos_Manager.HORA_CIERRE_JORNADA \
			and bool(est.get("Partido_Pendiente", false)):
		Auto_Resolver_Partido()


func _Recuperar_Energia(minutos: float) -> void:
	var clubes: Dictionary = Obtener_Clubes()
	var modo_rapido: bool = Variables_Estaticas.Modo_Rapido
	for club_id in clubes.keys():
		var club = clubes[club_id]
		if club is Dictionary:
			var inst = club.get("instalaciones", {})
			var niv_entreno: int = int(inst.get("entrenamiento", 1)) if inst is Dictionary else 1
			var bonus_ciudad: float = 1.0 + 0.15 * float(maxi(0, niv_entreno - 1))
			Simulador_Manager.Recuperar_Energia_Plantilla(
				club.get("plantilla", []), minutos * bonus_ciudad, modo_rapido)


func _Procesar_Dia_Nuevo() -> void:
	var est: Dictionary = Estado()
	if int(est.get("Dia_Tick", -1)) == Variables_Dinamicas.Minute_Day:
		return
	est["Dia_Tick"] = Variables_Dinamicas.Minute_Day
	_Envejecer_Todos()
	_Pagar_Nominas(0.25)
	_Simular_Mercado_IA()
	Guardar_Variables_Dinamicas.save_game()


func _Procesar_Semana_Nueva() -> void:
	var est: Dictionary = Estado()
	var semana: int = int(Variables_Dinamicas.Minute_Day / 7)
	if int(est.get("Semana_Tick", -1)) == semana:
		return
	est["Semana_Tick"] = semana
	_Envejecer_Todos()
	_Pagar_Nominas(1.0)
	_Simular_Mercado_IA()
	Guardar_Variables_Dinamicas.save_game()


func _Envejecer_Todos() -> void:
	var est: Dictionary = Estado()
	var clubes: Dictionary = Obtener_Clubes()
	var usuario_id: String = Club_Usuario_Id()
	var mensajes_retirados: Array[String] = []
	for club_id in clubes.keys():
		var club = clubes[club_id]
		if not (club is Dictionary):
			continue
		var division: int = clampi(int(club.get("division", 4)), 1, 4)
		var resultado: Dictionary = Simulador_Manager.Envejecer_Plantilla(
			club.get("plantilla", []), str(club_id), division)
		club["plantilla"] = resultado.get("plantilla", [])
		club["alineacion"] = Simulador_Manager.Elegir_Alineacion_Automatica(
			club["plantilla"], str(club.get("tactica", {}).get("formacion", "4-4-2")))
		if str(club_id) == usuario_id:
			for retirado in resultado.get("retirados", []):
				mensajes_retirados.append("%s (%s)" % [
					str(retirado.get("nombre", "")), str(retirado.get("rol", ""))])
	for texto in mensajes_retirados:
		_Mensaje("Retirada en tu club",
			"%s ha colgado las botas a los 40 años. Un canterano ocupa su lugar en la plantilla." % texto)
	est["Clubes"] = clubes


func _Pagar_Nominas(factor: float) -> void:
	var est: Dictionary = Estado()
	var clubes: Dictionary = Obtener_Clubes()
	var usuario_id: String = Club_Usuario_Id()
	var deuda_usuario: bool = false
	est["Ultimo_Dia_Nomina"] = Variables_Dinamicas.Minute_Day
	for club_id in clubes.keys():
		var club = clubes[club_id]
		if not (club is Dictionary):
			continue
		var nomina: int = Simulador_Manager.Calcular_Nomina(club.get("plantilla", []))
		var cargo: int = int(round(float(nomina) * factor))
		var presupuesto_antes: int = int(club.get("presupuesto", 0))
		club["presupuesto"] = presupuesto_antes - cargo
		if str(club_id) == usuario_id and presupuesto_antes >= 0 \
				and int(club["presupuesto"]) < 0:
			deuda_usuario = true
	if deuda_usuario:
		_Mensaje("Números rojos",
			"Tu club ha entrado en pérdidas. No podrás fichar hasta que el presupuesto vuelva a ser positivo.")


# ------------------------------------------------------------------
# Calendario y partidos
# ------------------------------------------------------------------

func _Parejas_Jornada(jornada: int, ids: Array) -> Array:
	return Simulador_Manager.Parejas_Jornada_Division(jornada, ids)


func _Iniciar_Jornada(jornada: int) -> void:
	var est: Dictionary = Estado()
	var jornada_cerrada: int = clampi(jornada, 0, 3)
	var clave_jornada: int = Variables_Dinamicas.Minute_Day * 10 + jornada_cerrada
	if int(est.get("Ultima_Jornada_Iniciada", -1)) == clave_jornada:
		return
	# Si el usuario está jugando un partido en vivo, no se auto-simula su
	# partido pendiente ni se arranca otra jornada por debajo: se encola y se
	# procesa al terminar el partido.
	if not _partido_en_vivo.is_empty() and not bool(_partido_en_vivo.get("finalizado", false)):
		var jornada_live: int = int(_partido_en_vivo.get("jornada", -1))
		if jornada_live == jornada_cerrada:
			return
		if not _jornadas_pendientes.has(jornada_cerrada):
			_jornadas_pendientes.append(jornada_cerrada)
		return
	if bool(est.get("Partido_Pendiente", false)):
		# Si el reloj vuelve a disparar la misma jornada (cambio de hora,
		# duplicado del tick), no se reinicia ni se auto-simula dos veces.
		if int(est.get("Partido_Jornada", -1)) == jornada_cerrada:
			return
		Auto_Resolver_Partido()
	var clubes: Dictionary = Obtener_Clubes()
	if clubes.is_empty():
		return
	var usuario_id: String = Club_Usuario_Id()
	if not clubes.has(usuario_id):
		return
	var divisiones: Dictionary = Obtener_Divisiones()

	for division in range(1, 5):
		var ids = divisiones.get(str(division), [])
		if not (ids is Array) or ids.size() < 2:
			continue
		var orden: Array = Simulador_Manager.Ordenar_Clasificacion(clubes, ids)
		var ids_orden: Array = []
		for entrada in orden:
			ids_orden.append(str(entrada["id"]))
		var parejas: Array = _Parejas_Jornada(jornada_cerrada, ids_orden)
		for pareja in parejas:
			var local_id: String = str(pareja[0])
			var visitante_id: String = str(pareja[1])
			if local_id == usuario_id or visitante_id == usuario_id:
				est["Partido_Pendiente"] = true
				est["Partido_Local_Id"] = local_id
				est["Partido_Visitante_Id"] = visitante_id
				est["Partido_Es_Local"] = local_id == usuario_id
				est["Partido_Jornada"] = jornada_cerrada
				continue
			_Simular_Partido_IA(local_id, visitante_id)

	est["Jornada_Actual"] = jornada_cerrada
	est["Ultima_Jornada_Iniciada"] = clave_jornada
	_Pagar_Salario_Manager()
	est["Clubes"] = clubes
	Guardar_Variables_Dinamicas.save_game()


func _Simular_Partido_IA(local_id: String, visitante_id: String) -> void:
	var local: Dictionary = Obtener_Club(local_id)
	var visitante: Dictionary = Obtener_Club(visitante_id)
	if local.is_empty() or visitante.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var estado: Dictionary = Simulador_Manager.Crear_Estado_Partido(local, visitante)
	Simulador_Manager.Simular_Partido_Completo(estado, rng)
	_Aplicar_Resultado_Clubes(estado, true)


func _Aplicar_Resultado_Clubes(estado: Dictionary, automatico: bool) -> void:
	var est: Dictionary = Estado()
	var clubes: Dictionary = Obtener_Clubes()
	var local_id: String = str(estado.get("local_id", ""))
	var visitante_id: String = str(estado.get("visitante_id", ""))
	var local = clubes.get(local_id, null)
	var visitante = clubes.get(visitante_id, null)
	if not (local is Dictionary) or not (visitante is Dictionary):
		return

	var goles_local: int = int(estado.get("goles_local", 0))
	var goles_visitante: int = int(estado.get("goles_visitante", 0))
	local["goles_favor"] = int(local.get("goles_favor", 0)) + goles_local
	local["goles_contra"] = int(local.get("goles_contra", 0)) + goles_visitante
	visitante["goles_favor"] = int(visitante.get("goles_favor", 0)) + goles_visitante
	visitante["goles_contra"] = int(visitante.get("goles_contra", 0)) + goles_local
	var racha_l: Array = local.get("racha", []) if local.get("racha", []) is Array else []
	var racha_v: Array = visitante.get("racha", []) if visitante.get("racha", []) is Array else []
	if goles_local > goles_visitante:
		local["puntos"] = int(local.get("puntos", 0)) + 3
		local["victorias"] = int(local.get("victorias", 0)) + 1
		visitante["derrotas"] = int(visitante.get("derrotas", 0)) + 1
		racha_l.push_front("V")
		racha_v.push_front("D")
	elif goles_local < goles_visitante:
		visitante["puntos"] = int(visitante.get("puntos", 0)) + 3
		visitante["victorias"] = int(visitante.get("victorias", 0)) + 1
		local["derrotas"] = int(local.get("derrotas", 0)) + 1
		racha_l.push_front("D")
		racha_v.push_front("V")
	else:
		local["puntos"] = int(local.get("puntos", 0)) + 1
		visitante["puntos"] = int(visitante.get("puntos", 0)) + 1
		local["empates"] = int(local.get("empates", 0)) + 1
		visitante["empates"] = int(visitante.get("empates", 0)) + 1
		racha_l.push_front("E")
		racha_v.push_front("E")
	while racha_l.size() > 5:
		racha_l.pop_back()
	while racha_v.size() > 5:
		racha_v.pop_back()
	local["racha"] = racha_l
	visitante["racha"] = racha_v

	var est_l: int = int(local.get("instalaciones", {}).get("estadio", 1)) if local.get("instalaciones", {}) is Dictionary else 1
	var est_v: int = int(visitante.get("instalaciones", {}).get("estadio", 1)) if visitante.get("instalaciones", {}) is Dictionary else 1
	var ing_local: int = Simulador_Manager.Calcular_Ingresos_Partido(
		int(local.get("division", 4)), goles_local, goles_visitante, true,
		int(local.get("aficion", 0)), est_l)
	var ing_visitante: int = Simulador_Manager.Calcular_Ingresos_Partido(
		int(visitante.get("division", 4)), goles_visitante, goles_local, false,
		int(visitante.get("aficion", 0)), est_v)
	local["presupuesto"] = int(local.get("presupuesto", 0)) + ing_local
	visitante["presupuesto"] = int(visitante.get("presupuesto", 0)) + ing_visitante
	estado["ingresos_local"] = ing_local
	estado["ingresos_visitante"] = ing_visitante

	_Aplicar_Energia_Y_Estadisticas(local, estado, "local")
	_Aplicar_Energia_Y_Estadisticas(visitante, estado, "visitante")

	var es_partido_usuario: bool = str(local_id) == Club_Usuario_Id() \
		or str(visitante_id) == Club_Usuario_Id()
	if es_partido_usuario:
		var goles_favor: int = goles_local if str(local_id) == Club_Usuario_Id() else goles_visitante
		var goles_contra: int = goles_visitante if str(local_id) == Club_Usuario_Id() else goles_local
		var rival: String = Obtener_Nombre_Club(visitante_id) if str(local_id) == Club_Usuario_Id() \
			else Obtener_Nombre_Club(local_id)
		var resultado: String = "Empate"
		var club_usuario: Dictionary = local if str(local_id) == Club_Usuario_Id() else visitante
		if goles_favor > goles_contra:
			resultado = "Victoria"
			est["Reputacion"] = clampi(Obtener_Reputacion() + 1, 0, 100)
			club_usuario["confianza_directiva"] = clampf(
				float(club_usuario.get("confianza_directiva", 70.0)) + 3.0, 0.0, 100.0)
		elif goles_favor < goles_contra:
			resultado = "Derrota"
			est["Reputacion"] = clampi(Obtener_Reputacion() - 1, 0, 100)
			club_usuario["confianza_directiva"] = clampf(
				float(club_usuario.get("confianza_directiva", 70.0)) - 2.0, 0.0, 100.0)
		var marcador: String = "%d-%d" % [goles_favor, goles_contra]
		var resultados: Array = Obtener_Ultimos_Resultados()
		resultados.push_front({
			"temporada": Obtener_Temporada(),
			"jornada": int(estado.get("jornada", est.get("Partido_Jornada", 0))) + 1,
			"rival": rival,
			"marcador": marcador,
			"resultado": resultado,
			"auto": automatico
		})
		while resultados.size() > 12:
			resultados.pop_back()
		est["Ultimos_Resultados"] = resultados
		var texto: String = "Jornada %d: %s %s contra %s." % [
			int(est.get("Partido_Jornada", 0)) + 1, resultado, marcador, rival]
		if automatico:
			texto += " El partido se ha auto-simulado al cierre de la jornada."
		_Mensaje("Resultado de tu club", texto)
		if bool(est.get("Partido_Pendiente", false)):
			est["Partido_Pendiente"] = false
			est["Partido_Local_Id"] = ""
			est["Partido_Visitante_Id"] = ""
			est["Partido_Es_Local"] = false
		est["Clubes"] = clubes
		_Comprobar_Fin_Temporada(int(est.get("Partido_Jornada", 0)))

	est["Clubes"] = clubes


func _Aplicar_Energia_Y_Estadisticas(club: Dictionary, estado: Dictionary, lado: String) -> void:
	var energia = estado.get("energia", {})
	var utilizados = estado.get("utilizados_%s" % lado, estado.get("alineacion_%s" % lado, []))
	var goles = estado.get("goleadores_%s" % lado, [])
	var asistencias = estado.get("asistencias_%s" % lado, [])
	var plantilla = club.get("plantilla", [])
	if not (plantilla is Array):
		return
	for jugador in plantilla:
		if not (jugador is Dictionary):
			continue
		var jugador_id: String = str(jugador.get("id", ""))
		if energia is Dictionary and energia.has(jugador_id):
			jugador["energia"] = clampf(float(energia[jugador_id]), 0.0, 100.0)
		if utilizados is Array and utilizados.has(jugador_id):
			jugador["partidos_jugados"] = int(jugador.get("partidos_jugados", 0)) + 1
		if goles is Array:
			for gol in goles:
				if gol is Dictionary and str(gol.get("id", "")) == jugador_id:
					jugador["goles"] = int(jugador.get("goles", 0)) + 1
		if asistencias is Array:
			for asistencia in asistencias:
				if asistencia is Dictionary and str(asistencia.get("id", "")) == jugador_id:
					jugador["asistencias"] = int(jugador.get("asistencias", 0)) + 1


func _Pagar_Salario_Manager() -> void:
	var division: int = Division_Usuario()
	var salario: float = float(Datos_Manager.SALARIO_MANAGER_JORNADA.get(division, 80))
	salario *= Variables_Estaticas.Multiplicador_Precios()
	Variables_Dinamicas.Dinero += round(salario)


func Iniciar_Partido_En_Vivo() -> Dictionary:
	if not Puede_Jugar_Manual():
		return {}
	if not _partido_en_vivo.is_empty() and not bool(_partido_en_vivo.get("finalizado", false)):
		return _partido_en_vivo
	var est: Dictionary = Estado()
	var local: Dictionary = Obtener_Club(str(est.get("Partido_Local_Id", "")))
	var visitante: Dictionary = Obtener_Club(str(est.get("Partido_Visitante_Id", "")))
	if local.is_empty() or visitante.is_empty():
		return {}
	_partido_en_vivo = Simulador_Manager.Crear_Estado_Partido(local, visitante)
	_partido_en_vivo["jornada"] = int(est.get("Partido_Jornada", 0))
	_partido_en_vivo["temporada"] = Obtener_Temporada()
	_partido_en_vivo["lado_usuario"] = "local" if str(est.get("Partido_Local_Id", "")) == Club_Usuario_Id() \
		else "visitante"
	_partido_en_vivo["utilizados_local"] = (_partido_en_vivo.get("alineacion_local", []) as Array).duplicate()
	_partido_en_vivo["utilizados_visitante"] = (_partido_en_vivo.get("alineacion_visitante", []) as Array).duplicate()
	_partido_aplicado = false
	return _partido_en_vivo


func Avanzar_Minuto_Partido() -> Dictionary:
	if _partido_en_vivo.is_empty():
		return {}
	if bool(_partido_en_vivo.get("finalizado", false)):
		return _partido_en_vivo
	Simulador_Manager.Simular_Minuto(_partido_en_vivo)
	if bool(_partido_en_vivo.get("finalizado", false)):
		Finalizar_Partido_En_Vivo()
	return _partido_en_vivo


func Simular_Resto_Partido() -> Dictionary:
	if _partido_en_vivo.is_empty():
		return {}
	var estado: Dictionary = _partido_en_vivo
	var seguridad: int = 0
	while not bool(_partido_en_vivo.get("finalizado", false)) and seguridad < 200:
		Simulador_Manager.Simular_Minuto(_partido_en_vivo)
		seguridad += 1
	Finalizar_Partido_En_Vivo()
	return estado


func Finalizar_Partido_En_Vivo() -> Dictionary:
	if _partido_en_vivo.is_empty():
		return {}
	var estado: Dictionary = _partido_en_vivo
	if not _partido_aplicado:
		if bool(estado.get("es_amistoso", false)):
			_Aplicar_Resultado_Amistoso(estado)
		else:
			_Aplicar_Resultado_Clubes(estado, false)
		_partido_aplicado = true
		Guardar_Variables_Dinamicas.save_game()
	_partido_en_vivo = {}
	_Procesar_Jornadas_Pendientes()
	return estado


func Puede_Jugar_Amistoso() -> bool:
	if not Activo() or Puede_Jugar_Manual():
		return false
	var club: Dictionary = Club_Usuario()
	if club.is_empty():
		return false
	return int(club.get("amistoso_dia", -1)) != Variables_Dinamicas.Minute_Day


func Iniciar_Partido_Amistoso(rival_id: String = "") -> Dictionary:
	if not Activo():
		return {}
	if not Puede_Jugar_Amistoso():
		return {}
	if not _partido_en_vivo.is_empty() and not bool(_partido_en_vivo.get("finalizado", false)):
		return _partido_en_vivo
	var club_usr: Dictionary = Club_Usuario()
	if club_usr.is_empty():
		return {}
	var rival: Dictionary = {}
	if rival_id != "" and rival_id != Club_Usuario_Id():
		rival = Obtener_Club(rival_id)
	if rival.is_empty():
		var div_ids = Obtener_Divisiones().get(str(Division_Usuario()), [])
		var candidatos: Array = []
		if div_ids is Array:
			for cid in div_ids:
				if str(cid) != Club_Usuario_Id():
					candidatos.append(str(cid))
		if candidatos.is_empty():
			for cid in Obtener_Clubes().keys():
				if str(cid) != Club_Usuario_Id():
					candidatos.append(str(cid))
		if not candidatos.is_empty():
			var rng := RandomNumberGenerator.new()
			rng.randomize()
			rival = Obtener_Club(str(candidatos[rng.randi_range(0, candidatos.size() - 1)]))
	if rival.is_empty():
		return {}
	_partido_en_vivo = Simulador_Manager.Crear_Estado_Partido(club_usr, rival)
	_partido_en_vivo["es_amistoso"] = true
	_partido_en_vivo["jornada"] = Obtener_Jornada()
	_partido_en_vivo["temporada"] = Obtener_Temporada()
	_partido_en_vivo["lado_usuario"] = "local"
	_partido_en_vivo["utilizados_local"] = (_partido_en_vivo.get("alineacion_local", []) as Array).duplicate()
	_partido_en_vivo["utilizados_visitante"] = (_partido_en_vivo.get("alineacion_visitante", []) as Array).duplicate()
	_partido_aplicado = false
	return _partido_en_vivo


func _Aplicar_Resultado_Amistoso(estado: Dictionary) -> void:
	var club: Dictionary = Club_Usuario()
	if club.is_empty():
		return
	club["amistoso_dia"] = Variables_Dinamicas.Minute_Day
	var goles_f: int = int(estado.get("goles_local", 0))
	var goles_c: int = int(estado.get("goles_visitante", 0))
	var div: int = clampi(int(club.get("division", 4)), 1, 4)
	var est_nv: int = int(club.get("instalaciones", {}).get("estadio", 1)) if club.get("instalaciones", {}) is Dictionary else 1
	var ingreso: int = int(round(float(Simulador_Manager.Calcular_Ingresos_Partido(
		div, goles_f, goles_c, true, int(club.get("aficion", 1500)), est_nv)) * 0.35))
	club["presupuesto"] = int(club.get("presupuesto", 0)) + ingreso
	estado["ingresos_local"] = ingreso
	if goles_f > goles_c:
		club["aficion"] = int(club.get("aficion", 1500)) + 25
		club["confianza_directiva"] = clampf(float(club.get("confianza_directiva", 70.0)) + 1.0, 0.0, 100.0)
	# Desgaste ligero en amistoso (~40% del desgaste de partido oficial).
	var energia_final = estado.get("energia", {})
	var plantilla = club.get("plantilla", [])
	if energia_final is Dictionary and plantilla is Array:
		for jugador in plantilla:
			if jugador is Dictionary:
				var jid: String = str(jugador.get("id", ""))
				if energia_final.has(jid):
					var actual: float = float(jugador.get("energia", 100.0))
					var tras: float = float(energia_final[jid])
					var delta: float = maxf(0.0, actual - tras) * 0.40
					jugador["energia"] = clampf(actual - delta, 0.0, 100.0)


func _Procesar_Jornadas_Pendientes() -> void:
	if _procesando_jornadas_pendientes:
		return
	if not _partido_en_vivo.is_empty():
		return
	if _jornadas_pendientes.is_empty():
		return
	_procesando_jornadas_pendientes = true
	var copia: Array = _jornadas_pendientes.duplicate()
	_jornadas_pendientes.clear()
	for jornada in copia:
		_Iniciar_Jornada(int(jornada))
	_procesando_jornadas_pendientes = false


func Auto_Resolver_Partido() -> void:
	var est: Dictionary = Estado()
	if not bool(est.get("Partido_Pendiente", false)):
		return
	# Si el jugador está disputando un partido en vivo, no se auto-simula por
	# debajo: se resolverá al terminar su partido.
	if not _partido_en_vivo.is_empty() and not bool(_partido_en_vivo.get("finalizado", false)):
		return
	var local: Dictionary = Obtener_Club(str(est.get("Partido_Local_Id", "")))
	var visitante: Dictionary = Obtener_Club(str(est.get("Partido_Visitante_Id", "")))
	if local.is_empty() or visitante.is_empty():
		est["Partido_Pendiente"] = false
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var estado: Dictionary = Simulador_Manager.Crear_Estado_Partido(local, visitante)
	estado["jornada"] = int(est.get("Partido_Jornada", 0))
	estado["temporada"] = Obtener_Temporada()
	estado["lado_usuario"] = "local" if str(est.get("Partido_Local_Id", "")) == Club_Usuario_Id() \
		else "visitante"
	estado["utilizados_local"] = (estado.get("alineacion_local", []) as Array).duplicate()
	estado["utilizados_visitante"] = (estado.get("alineacion_visitante", []) as Array).duplicate()
	Simulador_Manager.Simular_Partido_Completo(estado, rng)
	_Aplicar_Resultado_Clubes(estado, true)
	Guardar_Variables_Dinamicas.save_game()
	_Procesar_Jornadas_Pendientes()


func Sustituir_Jugador_Partido(sale_id: String, entra_id: String) -> Dictionary:
	if _partido_en_vivo.is_empty():
		return {"ok": false, "motivo": "No hay partido en curso."}
	var lado: String = "local" if str(_partido_en_vivo.get("local_id", "")) == Club_Usuario_Id() \
		else "visitante"
	var resultado: Dictionary = Simulador_Manager.Sustituir(
		_partido_en_vivo, lado, sale_id, entra_id)
	if bool(resultado.get("ok", false)):
		var utilizados_key: String = "utilizados_%s" % lado
		var utilizados: Array = _partido_en_vivo.get(utilizados_key, [])
		if not utilizados.has(entra_id):
			utilizados.append(entra_id)
		_partido_en_vivo[utilizados_key] = utilizados
	return resultado


func Cambiar_Mentalidad_Partido(mentalidad: String) -> bool:
	if _partido_en_vivo.is_empty():
		return false
	var lado: String = "local" if str(_partido_en_vivo.get("local_id", "")) == Club_Usuario_Id() \
		else "visitante"
	return Simulador_Manager.Cambiar_Mentalidad(_partido_en_vivo, lado, mentalidad)


func Cambiar_Presion_Partido(presion: String) -> bool:
	if _partido_en_vivo.is_empty() or not Datos_Manager.PRESIONES.has(presion):
		return false
	var lado: String = "local" if str(_partido_en_vivo.get("local_id", "")) == Club_Usuario_Id() \
		else "visitante"
	var clave: String = "tactica_%s" % lado
	var tactica = _partido_en_vivo.get(clave, {})
	if not (tactica is Dictionary):
		tactica = Datos_Manager.TACTICA_BASE.duplicate(true)
	tactica["presion"] = presion
	_partido_en_vivo[clave] = tactica
	Simulador_Manager._Anadir_Evento(_partido_en_vivo, "tactica", lado,
		"%s ajusta la presión a %s." % [str(_partido_en_vivo.get("%s_nombre" % lado, "")), presion])
	return true


func Obtener_Partido_En_Vivo() -> Dictionary:
	return _partido_en_vivo


# ------------------------------------------------------------------
# Táctica y plantilla
# ------------------------------------------------------------------

func Establecer_Tactica(formacion: String, mentalidad: String, presion: String) -> Dictionary:
	var club: Dictionary = Club_Usuario()
	if club.is_empty():
		return {"ok": false, "motivo": "No tienes club."}
	if not Datos_Manager.FORMACIONES.has(formacion):
		return {"ok": false, "motivo": "Formación no válida."}
	if not Datos_Manager.MENTALIDADES.has(mentalidad):
		return {"ok": false, "motivo": "Mentalidad no válida."}
	if not Datos_Manager.PRESIONES.has(presion):
		return {"ok": false, "motivo": "Presión no válida."}
	var tactica = club.get("tactica", {})
	if not (tactica is Dictionary):
		tactica = Datos_Manager.TACTICA_BASE.duplicate(true)
	var formacion_anterior: String = str(tactica.get("formacion", "4-4-2"))
	tactica["formacion"] = formacion
	tactica["mentalidad"] = mentalidad
	tactica["presion"] = presion
	club["tactica"] = tactica
	if formacion_anterior != formacion:
		club["alineacion"] = Simulador_Manager.Elegir_Alineacion_Automatica(
			club.get("plantilla", []), formacion)
	Guardar_Variables_Dinamicas.save_game()
	return {"ok": true, "motivo": ""}


func Alineacion_Automatica() -> void:
	var club: Dictionary = Club_Usuario()
	if club.is_empty():
		return
	var formacion: String = str(club.get("tactica", {}).get("formacion", "4-4-2"))
	club["alineacion"] = Simulador_Manager.Elegir_Alineacion_Automatica(
		club.get("plantilla", []), formacion)
	Guardar_Variables_Dinamicas.save_game()


func Intercambiar_Jugadores(titular_id: String, suplente_id: String) -> Dictionary:
	var club: Dictionary = Club_Usuario()
	if club.is_empty():
		return {"ok": false, "motivo": "No tienes club."}
	var alineacion = club.get("alineacion", [])
	if not (alineacion is Array):
		alineacion = []
	var indice_titular: int = alineacion.find(titular_id)
	if indice_titular < 0:
		return {"ok": false, "motivo": "El jugador no es titular."}
	var plantilla = club.get("plantilla", [])
	var existe: bool = false
	if plantilla is Array:
		for jugador in plantilla:
			if jugador is Dictionary and str(jugador.get("id", "")) == suplente_id:
				existe = true
				break
	if not existe:
		return {"ok": false, "motivo": "El jugador no pertenece a tu plantilla."}
	if alineacion.has(suplente_id):
		return {"ok": false, "motivo": "El jugador ya es titular."}
	alineacion[indice_titular] = suplente_id
	club["alineacion"] = alineacion
	Guardar_Variables_Dinamicas.save_game()
	return {"ok": true, "motivo": ""}


func Intercambiar_Titulares(id_a: String, id_b: String) -> Dictionary:
	var club: Dictionary = Club_Usuario()
	if club.is_empty():
		return {"ok": false, "motivo": "No tienes club."}
	var alineacion = club.get("alineacion", [])
	if not (alineacion is Array):
		return {"ok": false, "motivo": "Alineación no válida."}
	var idx_a: int = alineacion.find(id_a)
	var idx_b: int = alineacion.find(id_b)
	if idx_a < 0 or idx_b < 0:
		return {"ok": false, "motivo": "Ambos jugadores deben estar en el once titular."}
	if idx_a == idx_b:
		return {"ok": true, "motivo": ""}
	var tmp = alineacion[idx_a]
	alineacion[idx_a] = alineacion[idx_b]
	alineacion[idx_b] = tmp
	club["alineacion"] = alineacion
	Guardar_Variables_Dinamicas.save_game()
	return {"ok": true, "motivo": ""}


func Cambiar_Capitan(jugador_id: String) -> Dictionary:
	var club: Dictionary = Club_Usuario()
	if club.is_empty():
		return {"ok": false, "motivo": "No tienes club."}
	var jugador: Dictionary = Obtener_Jugador_De_Club(Club_Usuario_Id(), jugador_id)
	if jugador.is_empty():
		return {"ok": false, "motivo": "Jugador no encontrado."}
	club["capitan_id"] = jugador_id
	Guardar_Variables_Dinamicas.save_game()
	return {"ok": true, "motivo": ""}


func Cambiar_Dorsal(jugador_id: String, dorsal: int) -> Dictionary:
	var club: Dictionary = Club_Usuario()
	if club.is_empty():
		return {"ok": false, "motivo": "No tienes club."}
	var nuevo_dorsal: int = clampi(dorsal, 1, 99)
	var plantilla = club.get("plantilla", [])
	var objetivo: Dictionary = {}
	var otro_con_dorsal: Dictionary = {}
	if plantilla is Array:
		for j in plantilla:
			if not (j is Dictionary):
				continue
			if str(j.get("id", "")) == jugador_id:
				objetivo = j
			elif int(j.get("dorsal", 0)) == nuevo_dorsal:
				otro_con_dorsal = j
	if objetivo.is_empty():
		return {"ok": false, "motivo": "Jugador no encontrado."}
	var anterior: int = int(objetivo.get("dorsal", 1))
	objetivo["dorsal"] = nuevo_dorsal
	if not otro_con_dorsal.is_empty():
		otro_con_dorsal["dorsal"] = anterior
	Guardar_Variables_Dinamicas.save_game()
	return {"ok": true, "motivo": "", "dorsal": nuevo_dorsal}


func Renovar_Contrato(jugador_id: String) -> Dictionary:
	var club: Dictionary = Club_Usuario()
	if club.is_empty():
		return {"ok": false, "motivo": "No tienes club."}
	var jugador: Dictionary = Obtener_Jugador_De_Club(Club_Usuario_Id(), jugador_id)
	if jugador.is_empty():
		return {"ok": false, "motivo": "Jugador no encontrado."}
	var actual: int = int(jugador.get("contrato_temporadas", 1))
	if actual >= 5:
		return {"ok": false, "motivo": "El jugador ya tiene el contrato máximo de 5 temporadas."}
	var prima: int = maxi(200, int(jugador.get("salario_semanal", 100)) * 2)
	if int(club.get("presupuesto", 0)) < prima:
		return {"ok": false, "motivo": "Necesitas %d € en la caja del club para la prima de renovación." % prima}
	club["presupuesto"] = int(club.get("presupuesto", 0)) - prima
	jugador["contrato_temporadas"] = mini(5, actual + 2)
	Guardar_Variables_Dinamicas.save_game()
	return {"ok": true, "motivo": "", "prima": prima, "contrato": int(jugador["contrato_temporadas"])}


func Entrenar_Jugador(jugador_id: String, atributo: String) -> Dictionary:
	var club: Dictionary = Club_Usuario()
	if club.is_empty():
		return {"ok": false, "motivo": "No tienes club."}
	var jugador: Dictionary = Obtener_Jugador_De_Club(Club_Usuario_Id(), jugador_id)
	if jugador.is_empty():
		return {"ok": false, "motivo": "Jugador no encontrado."}
	if int(jugador.get("entrenado_dia", -1)) == Variables_Dinamicas.Minute_Day:
		return {"ok": false, "motivo": "Este jugador ya ha entrenado hoy."}
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var resultado: Dictionary = Simulador_Manager.Entrenar_Jugador(jugador, atributo, rng)
	if bool(resultado.get("ok", false)):
		# Ciudad Deportiva avanzada da una opción extra de +1 adicional.
		var inst = club.get("instalaciones", {})
		var niv: int = int(inst.get("entrenamiento", 1)) if inst is Dictionary else 1
		if niv > 1 and rng.randf() < 0.14 * float(niv - 1):
			var bloque: String = str(Simulador_Manager.BLOQUE_DE_ATRIBUTO.get(atributo, "defensa"))
			var val_act: int = int(jugador.get(bloque, {}).get(atributo, 50))
			if val_act < Datos_Manager.ATRIBUTO_MAXIMO:
				jugador[bloque][atributo] = val_act + 1
				Simulador_Manager.Recalcular_Jugador(jugador)
				resultado["valor"] = val_act + 1
				resultado["mejora"] = int(resultado.get("mejora", 0)) + 1
		jugador["entrenado_dia"] = Variables_Dinamicas.Minute_Day
		Guardar_Variables_Dinamicas.save_game()
	return resultado


func Entrenar_Linea_Equipo(linea: String) -> Dictionary:
	var club: Dictionary = Club_Usuario()
	if club.is_empty():
		return {"ok": false, "motivo": "No tienes club."}
	if int(club.get("entreno_grupal_dia", -1)) == Variables_Dinamicas.Minute_Day:
		return {"ok": false, "motivo": "El equipo ya ha completado la sesión grupal de hoy."}
	var attrs_linea: Dictionary = {
		"defensa": ["entradas", "marcaje", "posicion"],
		"medio": ["pase", "creatividad", "condicion"],
		"ataque": ["disparo", "definicion", "regate"],
		"fisico": ["condicion", "velocidad", "fuerza"]
	}
	if not attrs_linea.has(linea):
		return {"ok": false, "motivo": "Sesión no válida."}
	var plantilla = club.get("plantilla", [])
	if not (plantilla is Array):
		return {"ok": false, "motivo": "Plantilla no disponible."}
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var candidatos_attrs: Array = attrs_linea[linea]
	var entrenados: int = 0
	var mejoras_totales: int = 0
	for jugador in plantilla:
		if not (jugador is Dictionary):
			continue
		var rol_p: String = Simulador_Manager._Rol_Principal(jugador)
		var linea_j: String = Datos_Manager.Linea_De_Rol(rol_p)
		var coincide: bool = (linea == "fisico") \
			or (linea == "defensa" and (linea_j == "DEF" or linea_j == "POR")) \
			or (linea == "medio" and linea_j == "MED") \
			or (linea == "ataque" and linea_j == "ATA")
		if not coincide:
			continue
		var energia: float = float(jugador.get("energia", 100.0))
		if energia < Datos_Manager.COSTE_ENERGIA_ENTRENAMIENTO_LINEA:
			continue
		jugador["energia"] = maxf(0.0, energia - Datos_Manager.COSTE_ENERGIA_ENTRENAMIENTO_LINEA)
		var attr: String = str(candidatos_attrs[rng.randi_range(0, candidatos_attrs.size() - 1)])
		var bloque: String = str(Simulador_Manager.BLOQUE_DE_ATRIBUTO.get(attr, "defensa"))
		var actual: int = int(jugador.get(bloque, {}).get(attr, 50))
		if actual < Datos_Manager.ATRIBUTO_MAXIMO and rng.randf() < 0.72:
			jugador[bloque][attr] = actual + 1
			Simulador_Manager.Recalcular_Jugador(jugador)
			mejoras_totales += 1
		entrenados += 1
	if entrenados == 0:
		return {"ok": false, "motivo": "Ningún jugador de esa línea tiene energía suficiente."}
	club["entreno_grupal_dia"] = Variables_Dinamicas.Minute_Day
	Guardar_Variables_Dinamicas.save_game()
	return {"ok": true, "motivo": "", "entrenados": entrenados, "mejoras": mejoras_totales}


func Mejorar_Instalacion(tipo: String) -> Dictionary:
	var club: Dictionary = Club_Usuario()
	if club.is_empty():
		return {"ok": false, "motivo": "No tienes club."}
	if not Datos_Manager.INSTALACIONES_BASE.has(tipo):
		return {"ok": false, "motivo": "Instalación no válida."}
	var inst = club.get("instalaciones", {})
	if not (inst is Dictionary):
		inst = Datos_Manager.INSTALACIONES_BASE.duplicate(true)
	var nivel_actual: int = clampi(int(inst.get(tipo, 1)), 1, Datos_Manager.INSTALACIONES_NIVEL_MAX)
	if nivel_actual >= Datos_Manager.INSTALACIONES_NIVEL_MAX:
		return {"ok": false, "motivo": "Esta instalación ya está al nivel máximo."}
	var coste: int = int(Datos_Manager.INSTALACIONES_COSTES.get(nivel_actual, 50000))
	if int(club.get("presupuesto", 0)) < coste:
		return {"ok": false, "motivo": "Necesitas %d € en la caja del club para mejorar." % coste}
	club["presupuesto"] = int(club.get("presupuesto", 0)) - coste
	inst[tipo] = nivel_actual + 1
	club["instalaciones"] = inst
	if tipo == "estadio":
		club["aficion"] = int(club.get("aficion", 1500)) + 400 * nivel_actual
	_Mensaje("Instalación mejorada",
		"Has mejorado %s al nivel %d en %s." % [
			str(Datos_Manager.INSTALACIONES_NOMBRES.get(tipo, tipo)),
			nivel_actual + 1, str(club.get("nombre", "tu club"))])
	Guardar_Variables_Dinamicas.save_game()
	return {"ok": true, "motivo": "", "nivel": nivel_actual + 1, "coste": coste}


func Ojear_Cantera() -> Dictionary:
	var club: Dictionary = Club_Usuario()
	if club.is_empty():
		return {"ok": false, "motivo": "No tienes club."}
	if int(club.get("cantera_dia", -1)) == Variables_Dinamicas.Minute_Day \
			and not (club.get("cantera_candidatos", []) as Array).is_empty():
		return {"ok": true, "motivo": "", "candidatos": club["cantera_candidatos"]}
	var div: int = clampi(int(club.get("division", 4)), 1, 4)
	var coste: int = int(Datos_Manager.COSTE_OJEAR_CANTERA.get(div, 1800))
	if int(club.get("presupuesto", 0)) < coste:
		return {"ok": false, "motivo": "Necesitas %d € en la caja del club para enviar ojeadores." % coste}
	club["presupuesto"] = int(club.get("presupuesto", 0)) - coste
	var inst = club.get("instalaciones", {})
	var nivel_cantera: int = int(inst.get("cantera", 1)) if inst is Dictionary else 1
	var usados: Dictionary = {}
	var dorsales: Dictionary = {}
	for j in club.get("plantilla", []):
		if j is Dictionary:
			usados[str(j.get("nombre", ""))] = true
			dorsales[int(j.get("dorsal", 0))] = true
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var candidatos: Array = Simulador_Manager.Generar_Canteranos_Ojeo(
		Club_Usuario_Id(), div, nivel_cantera, rng, usados, dorsales)
	club["cantera_dia"] = Variables_Dinamicas.Minute_Day
	club["cantera_candidatos"] = candidatos
	Guardar_Variables_Dinamicas.save_game()
	return {"ok": true, "motivo": "", "candidatos": candidatos, "coste": coste}


func Fichar_Canterano(indice: int) -> Dictionary:
	var club: Dictionary = Club_Usuario()
	if club.is_empty():
		return {"ok": false, "motivo": "No tienes club."}
	var puede: Dictionary = Simulador_Manager.Puede_Comprar(club)
	if not bool(puede.get("ok", false)):
		return {"ok": false, "motivo": str(puede.get("texto", ""))}
	var candidatos = club.get("cantera_candidatos", [])
	if not (candidatos is Array) or indice < 0 or indice >= candidatos.size():
		return {"ok": false, "motivo": "Promesa no disponible."}
	var elegido: Dictionary = candidatos[indice]
	candidatos.remove_at(indice)
	club["cantera_candidatos"] = candidatos
	var plantilla: Array = club.get("plantilla", [])
	var dorsales: Dictionary = {}
	for j in plantilla:
		if j is Dictionary:
			dorsales[int(j.get("dorsal", 0))] = true
	if dorsales.has(int(elegido.get("dorsal", 0))):
		elegido["dorsal"] = Simulador_Manager._Dorsal_Libre(plantilla)
	plantilla.append(elegido)
	club["plantilla"] = plantilla
	_Mensaje("Alta desde la cantera",
		"%s (%s, %d años) sube al primer equipo." % [
			str(elegido.get("nombre", "")),
			Simulador_Manager._Rol_Principal(elegido),
			int(elegido.get("edad", 18))])
	Guardar_Variables_Dinamicas.save_game()
	return {"ok": true, "motivo": "", "jugador": elegido}


func Evaluar_Oferta_Preview(jugador_id: String, oferta: int) -> Dictionary:
	var club_usuario: Dictionary = Club_Usuario()
	if club_usuario.is_empty():
		return {"aceptada": false, "motivo": "sin_club", "texto": "No tienes club."}
	var club_origen_id: String = Club_De_Jugador(jugador_id)
	if club_origen_id == "" or club_origen_id == Club_Usuario_Id():
		return {"aceptada": false, "motivo": "no_disponible", "texto": "Jugador no disponible."}
	var club_origen: Dictionary = Obtener_Club(club_origen_id)
	var jugador: Dictionary = Obtener_Jugador_De_Club(club_origen_id, jugador_id)
	if jugador.is_empty():
		return {"aceptada": false, "motivo": "no_encontrado", "texto": "Jugador no encontrado."}
	return Simulador_Manager.Evaluar_Oferta_Estandar(club_origen, jugador, oferta, club_usuario)


func Renunciar_Al_Club() -> Dictionary:
	if not Activo():
		return {"ok": false, "motivo": "No diriges ningún club."}
	var nombre_previo: String = str(Club_Usuario().get("nombre", "tu club"))
	var est: Dictionary = Estado()
	est["Activo"] = false
	est["Partido_Pendiente"] = false
	est["Partido_Local_Id"] = ""
	est["Partido_Visitante_Id"] = ""
	est["Clubes"] = {}
	est["Divisiones"] = {"1": [], "2": [], "3": [], "4": []}
	est["Ultimos_Resultados"] = []
	est["Jornada_Actual"] = 0
	est["Reputacion"] = clampi(Obtener_Reputacion() - 2, 10, 100)
	_partido_en_vivo = {}
	_jornadas_pendientes.clear()
	_Mensaje("Dimisión presentada",
		"Has dejado tu puesto en %s. Ya puedes fundar un nuevo club cuando quieras." % nombre_previo)
	Guardar_Variables_Dinamicas.save_game()
	return {"ok": true, "motivo": ""}


# ------------------------------------------------------------------
# Mercado
# ------------------------------------------------------------------

func Oferta_Estandar(jugador_id: String, oferta: int) -> Dictionary:
	var club_usuario: Dictionary = Club_Usuario()
	if club_usuario.is_empty():
		return {"ok": false, "motivo": "No tienes club."}
	if int(club_usuario.get("presupuesto", 0)) < 0:
		return {"ok": false, "motivo": "Tu club está en números rojos. No puedes fichar."}
	var club_origen_id: String = Club_De_Jugador(jugador_id)
	if club_origen_id == "" or club_origen_id == Club_Usuario_Id():
		return {"ok": false, "motivo": "Jugador no disponible."}
	var club_origen: Dictionary = Obtener_Club(club_origen_id)
	var jugador: Dictionary = Obtener_Jugador_De_Club(club_origen_id, jugador_id)
	if jugador.is_empty():
		return {"ok": false, "motivo": "Jugador no encontrado."}
	var evaluacion: Dictionary = Simulador_Manager.Evaluar_Oferta_Estandar(
		club_origen, jugador, oferta, club_usuario)
	if not bool(evaluacion.get("aceptada", false)):
		return {"ok": false, "motivo": str(evaluacion.get("texto", "")),
			"codigo": str(evaluacion.get("motivo", ""))}
	_Transferir(club_origen_id, Club_Usuario_Id(), jugador_id, oferta)
	_Mensaje("Fichaje completado",
		"Has fichado a %s por %d €. El club vendedor ha aceptado la oferta." % [
			str(jugador.get("nombre", "")), oferta])
	Guardar_Variables_Dinamicas.save_game()
	return {"ok": true, "motivo": "", "jugador": jugador}


func Pagar_Clausula(jugador_id: String) -> Dictionary:
	var club_usuario: Dictionary = Club_Usuario()
	if club_usuario.is_empty():
		return {"ok": false, "motivo": "No tienes club."}
	if int(club_usuario.get("presupuesto", 0)) < 0:
		return {"ok": false, "motivo": "Tu club está en números rojos. No puedes fichar."}
	var club_origen_id: String = Club_De_Jugador(jugador_id)
	if club_origen_id == "" or club_origen_id == Club_Usuario_Id():
		return {"ok": false, "motivo": "Jugador no disponible."}
	var plantilla_usuario = club_usuario.get("plantilla", [])
	if plantilla_usuario is Array and plantilla_usuario.size() >= Datos_Manager.PLANTILLA_MAXIMA:
		return {"ok": false, "motivo": "Tu plantilla ya tiene %d futbolistas." % Datos_Manager.PLANTILLA_MAXIMA}
	var jugador: Dictionary = Obtener_Jugador_De_Club(club_origen_id, jugador_id)
	if jugador.is_empty():
		return {"ok": false, "motivo": "Jugador no encontrado."}
	var clausula: int = maxi(0, int(jugador.get("clausula_rescision", 0)))
	if clausula <= 0:
		clausula = int(round(float(jugador.get("valor_mercado", 0)) * 1.75))
	if int(club_usuario.get("presupuesto", 0)) < clausula:
		return {"ok": false, "motivo": "Necesitas %d € para pagar la cláusula." % clausula}
	_Transferir(club_origen_id, Club_Usuario_Id(), jugador_id, clausula)
	_Mensaje("Cláusula pagada",
		"Has pagado la cláusula de %d € por %s. El traspaso es inmediato y el club vendedor no ha podido negarse." % [
			clausula, str(jugador.get("nombre", ""))])
	Guardar_Variables_Dinamicas.save_game()
	return {"ok": true, "motivo": "", "jugador": jugador, "importe": clausula}


func Vender_Jugador(jugador_id: String) -> Dictionary:
	var club_usuario: Dictionary = Club_Usuario()
	if club_usuario.is_empty():
		return {"ok": false, "motivo": "No tienes club."}
	var venta: Dictionary = Simulador_Manager.Puede_Vender(club_usuario)
	if not bool(venta.get("ok", false)):
		return {"ok": false, "motivo": str(venta.get("texto", ""))}
	var jugador: Dictionary = Obtener_Jugador_De_Club(Club_Usuario_Id(), jugador_id)
	if jugador.is_empty():
		return {"ok": false, "motivo": "Jugador no encontrado."}
	var roles_j = jugador.get("roles", ["MC"])
	var rol_j: String = "MC"
	if roles_j is Array and not roles_j.is_empty():
		rol_j = str(roles_j[0])
	if rol_j == "POR" \
			and Simulador_Manager.Contar_Rol(club_usuario.get("plantilla", []), "POR") <= 1:
		return {"ok": false, "motivo": "No puedes vender a tu único portero."}

	var clubes: Dictionary = Obtener_Clubes()
	var candidatos: Array = []
	for club_id in clubes.keys():
		if str(club_id) == Club_Usuario_Id():
			continue
		var club = clubes[club_id]
		if not (club is Dictionary) or bool(club.get("es_usuario", false)):
			continue
		var plantilla = club.get("plantilla", [])
		if not (plantilla is Array) or plantilla.size() >= Datos_Manager.PLANTILLA_MAXIMA:
			continue
		if int(club.get("presupuesto", 0)) < int(
				round(float(jugador.get("valor_mercado", 0)) * 1.20)):
			continue
		candidatos.append(str(club_id))
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var valor: int = int(jugador.get("valor_mercado", 0))
	var precio: int = maxi(500, int(round(float(valor) * rng.randf_range(0.9, 1.1))))
	if candidatos.is_empty():
		# Si los clubes locales están llenos (p. ej. 18/18 al inicio), traspaso al extranjero.
		var clubs_dict: Dictionary = Obtener_Clubes()
		var usr_c: Dictionary = Club_Usuario()
		var pl_u = usr_c.get("plantilla", [])
		if not (pl_u is Array):
			return {"ok": false, "motivo": "Plantilla no disponible."}
		var idx_u: int = -1
		for i in range(pl_u.size()):
			if pl_u[i] is Dictionary and str(pl_u[i].get("id", "")) == jugador_id:
				idx_u = i
				break
		if idx_u < 0:
			return {"ok": false, "motivo": "Jugador no encontrado."}
		pl_u.remove_at(idx_u)
		usr_c["plantilla"] = pl_u
		usr_c["presupuesto"] = int(usr_c.get("presupuesto", 0)) + precio
		usr_c["alineacion"] = Simulador_Manager.Elegir_Alineacion_Automatica(
			pl_u, str(usr_c.get("tactica", {}).get("formacion", "4-4-2")))
		if str(usr_c.get("capitan_id", "")) == jugador_id:
			usr_c["capitan_id"] = Simulador_Manager.Elegir_Capitan_Automatico(
				pl_u, usr_c["alineacion"])
		clubs_dict[Club_Usuario_Id()] = usr_c
		_Mensaje("Venta internacional",
			"Has traspasado a %s a un club extranjero por %d €." % [
				str(jugador.get("nombre", "")), precio])
		Guardar_Variables_Dinamicas.save_game()
		return {"ok": true, "motivo": "", "importe": precio, "comprador": "Club extranjero"}
	var comprador_id: String = str(candidatos[rng.randi_range(0, candidatos.size() - 1)])
	_Transferir(Club_Usuario_Id(), comprador_id, jugador_id, precio)
	_Mensaje("Venta completada",
		"Has vendido a %s al %s por %d €." % [
			str(jugador.get("nombre", "")), Obtener_Nombre_Club(comprador_id), precio])
	Guardar_Variables_Dinamicas.save_game()
	return {"ok": true, "motivo": "", "importe": precio,
		"comprador": Obtener_Nombre_Club(comprador_id)}


func _Transferir(origen_id: String, destino_id: String, jugador_id: String, importe: int) -> bool:
	var clubes: Dictionary = Obtener_Clubes()
	var origen = clubes.get(origen_id, null)
	var destino = clubes.get(destino_id, null)
	if not (origen is Dictionary) or not (destino is Dictionary):
		return false
	var plantilla_origen = origen.get("plantilla", [])
	var plantilla_destino = destino.get("plantilla", [])
	if not (plantilla_origen is Array) or not (plantilla_destino is Array):
		return false
	var indice: int = -1
	for i in range(plantilla_origen.size()):
		var jugador = plantilla_origen[i]
		if jugador is Dictionary and str(jugador.get("id", "")) == jugador_id:
			indice = i
			break
	if indice < 0:
		return false
	var jugador: Dictionary = plantilla_origen[indice]
	plantilla_origen.remove_at(indice)
	# Dorsal libre en el destino.
	var dorsales: Dictionary = {}
	for j in plantilla_destino:
		if j is Dictionary:
			dorsales[int(j.get("dorsal", 0))] = true
	if dorsales.has(int(jugador.get("dorsal", 0))):
		for dorsal in range(1, 40):
			if not dorsales.has(dorsal):
				jugador["dorsal"] = dorsal
				break
	jugador["entrenado_dia"] = -1
	plantilla_destino.append(jugador)
	origen["plantilla"] = plantilla_origen
	destino["plantilla"] = plantilla_destino
	origen["presupuesto"] = int(origen.get("presupuesto", 0)) + importe
	destino["presupuesto"] = int(destino.get("presupuesto", 0)) - importe
	origen["alineacion"] = Simulador_Manager.Elegir_Alineacion_Automatica(
		plantilla_origen, str(origen.get("tactica", {}).get("formacion", "4-4-2")))
	destino["alineacion"] = Simulador_Manager.Elegir_Alineacion_Automatica(
		plantilla_destino, str(destino.get("tactica", {}).get("formacion", "4-4-2")))
	if str(origen.get("capitan_id", "")) == jugador_id:
		origen["capitan_id"] = Simulador_Manager.Elegir_Capitan_Automatico(
			plantilla_origen, origen["alineacion"])
	if plantilla_origen.size() < 15 and not bool(origen.get("es_usuario", false)):
		_Promocionar_Canterano(origen)
	clubes[origen_id] = origen
	clubes[destino_id] = destino
	return true


func _Promocionar_Canterano(club: Dictionary) -> void:
	var plantilla = club.get("plantilla", [])
	if not (plantilla is Array):
		plantilla = []
	var conteo: Dictionary = {}
	for rol in Datos_Manager.PLANTILLA_ROLES:
		conteo[str(rol)] = 0
	for jugador in plantilla:
		if jugador is Dictionary:
			var rol_j: String = str((jugador.get("roles", ["MC"]) as Array)[0])
			if conteo.has(rol_j):
				conteo[rol_j] = int(conteo[rol_j]) + 1
	var rol_objetivo: String = "MC"
	var mayor_deficit: int = -999
	for rol in Datos_Manager.PLANTILLA_ROLES:
		var necesario: int = 0
		for r in Datos_Manager.PLANTILLA_ROLES:
			if r == rol:
				necesario += 1
		var deficit: int = necesario - int(conteo.get(str(rol), 0))
		if deficit > mayor_deficit:
			mayor_deficit = deficit
			rol_objetivo = str(rol)
	var dorsales: Dictionary = {}
	for jugador in plantilla:
		if jugador is Dictionary:
			dorsales[int(jugador.get("dorsal", 0))] = true
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var canterano: Dictionary = Simulador_Manager.Generar_Canterano(
		str(club.get("id", "")), rol_objetivo, int(club.get("division", 4)),
		rng, {}, dorsales)
	plantilla.append(canterano)
	club["plantilla"] = plantilla
	club["alineacion"] = Simulador_Manager.Elegir_Alineacion_Automatica(
		plantilla, str(club.get("tactica", {}).get("formacion", "4-4-2")))


func _Simular_Mercado_IA() -> void:
	var clubes: Dictionary = Obtener_Clubes()
	if clubes.size() < 4:
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var intentos: int = 2
	for _i in range(intentos):
		var compradores: Array = []
		var vendedores: Array = []
		for club_id in clubes.keys():
			var club = clubes[club_id]
			if not (club is Dictionary) or bool(club.get("es_usuario", false)):
				continue
			var plantilla = club.get("plantilla", [])
			if not (plantilla is Array):
				continue
			if plantilla.size() < Datos_Manager.PLANTILLA_MAXIMA \
					and int(club.get("presupuesto", 0)) > 5000:
				compradores.append(str(club_id))
			if plantilla.size() > 15:
				vendedores.append(str(club_id))
		if compradores.is_empty() or vendedores.is_empty():
			return
		var comprador_id: String = str(compradores[rng.randi_range(0, compradores.size() - 1)])
		var vendedor_id: String = str(vendedores[rng.randi_range(0, vendedores.size() - 1)])
		if comprador_id == vendedor_id:
			continue
		var vendedor: Dictionary = Obtener_Club(vendedor_id)
		var comprador: Dictionary = Obtener_Club(comprador_id)
		var plantilla_vendedor = vendedor.get("plantilla", [])
		if not (plantilla_vendedor is Array) or plantilla_vendedor.is_empty():
			continue
		var jugador: Dictionary = plantilla_vendedor[
			rng.randi_range(0, plantilla_vendedor.size() - 1)]
		var roles_j = jugador.get("roles", ["MC"])
		var rol: String = "MC"
		if roles_j is Array and not roles_j.is_empty():
			rol = str(roles_j[0])
		if Simulador_Manager.Contar_Rol(plantilla_vendedor, rol) <= 1:
			continue
		var valor: int = int(jugador.get("valor_mercado", 0))
		var clausula: int = int(jugador.get("clausula_rescision", int(valor * 1.75)))
		var importe: int = clausula if rng.randf() < 0.35 else int(round(valor * rng.randf_range(1.02, 1.18)))
		if int(comprador.get("presupuesto", 0)) < importe:
			continue
		_Transferir(vendedor_id, comprador_id, str(jugador.get("id", "")), importe)


# ------------------------------------------------------------------
# Cierre de temporada
# ------------------------------------------------------------------

func _Comprobar_Fin_Temporada(jornada: int) -> void:
	var est: Dictionary = Estado()
	if jornada < Datos_Manager.JORNADAS_POR_TEMPORADA - 1:
		return
	if bool(est.get("Partido_Pendiente", false)):
		return
	_Cerrar_Temporada()


func _Cerrar_Temporada() -> void:
	var est: Dictionary = Estado()
	var clubes: Dictionary = Obtener_Clubes()
	var divisiones: Dictionary = Obtener_Divisiones()
	if clubes.is_empty():
		return
	var clasificaciones: Dictionary = {}
	for division in range(1, 5):
		var ids = divisiones.get(str(division), [])
		if not (ids is Array):
			ids = []
		var orden: Array = Simulador_Manager.Ordenar_Clasificacion(clubes, ids)
		var ids_orden: Array = []
		for entrada in orden:
			ids_orden.append(str(entrada["id"]))
		clasificaciones[str(division)] = ids_orden

	var resolucion: Dictionary = Simulador_Manager.Resolver_Ascensos_Descensos(
		clubes, clasificaciones)
	var divisiones_finales: Dictionary = resolucion.get("divisiones_finales", {})
	var usuario_id: String = Club_Usuario_Id()
	var club_usuario: Dictionary = Obtener_Club(usuario_id)
	var division_anterior: int = clampi(int(club_usuario.get("division", 4)), 1, 4)
	var posicion_anterior: int = Obtener_Posicion_Usuario()
	var puntos_anteriores: int = int(club_usuario.get("puntos", 0))
	var gf_anteriores: int = int(club_usuario.get("goles_favor", 0))
	var gc_anteriores: int = int(club_usuario.get("goles_contra", 0))

	# Movimientos + multiplicadores Top Eleven.
	for movimiento in resolucion.get("movimientos", []):
		var club_id: String = str(movimiento.get("club_id", ""))
		var club = clubes.get(club_id, null)
		if not (club is Dictionary):
			continue
		var nueva_division: int = clampi(int(divisiones_finales.get(club_id,
			club.get("division", 4))), 1, 4)
		var anterior: int = int(club.get("division", 4))
		club["division"] = nueva_division
		if nueva_division < anterior:
			club["plantilla"] = Simulador_Manager.Aplicar_Ascenso(club.get("plantilla", []))
		elif nueva_division > anterior:
			club["plantilla"] = Simulador_Manager.Aplicar_Descenso(club.get("plantilla", []))
		club["alineacion"] = Simulador_Manager.Elegir_Alineacion_Automatica(
			club.get("plantilla", []), str(club.get("tactica", {}).get("formacion", "4-4-2")))
		club["aficion"] = int(round(float(club.get("aficion", 1500)) * (
			1.15 if nueva_division < anterior else 0.9)))
		clubes[club_id] = club

	# Premios por título y ascenso.
	var campeones: Dictionary = resolucion.get("campeones", {})
	for division in range(1, 5):
		var campeon_id: String = str(campeones.get(str(division), ""))
		if campeon_id != "" and clubes.has(campeon_id):
			var club_campeon = clubes[campeon_id]
			club_campeon["presupuesto"] = int(club_campeon.get("presupuesto", 0)) + int(
				Datos_Manager.PREMIO_TITULO.get(division, 0))
			if campeon_id == usuario_id:
				var prima: float = float(Datos_Manager.PRIMA_MANAGER_TITULO.get(division, 0)) \
					* Variables_Estaticas.Multiplicador_Precios()
				Variables_Dinamicas.Dinero += round(prima)
				est["Reputacion"] = clampi(Obtener_Reputacion() + 4, 0, 100)
	for movimiento in resolucion.get("movimientos", []):
		if str(movimiento.get("tipo", "")) != "ascenso":
			continue
		var club_asc = clubes.get(str(movimiento.get("club_id", "")), null)
		if club_asc is Dictionary:
			club_asc["presupuesto"] = int(club_asc.get("presupuesto", 0)) + int(
				Datos_Manager.PREMIO_ASCENSO.get(int(movimiento.get("de", 4)), 0))

	# Reconstruir el mapa de divisiones.
	var nuevas_divisiones: Dictionary = {"1": [], "2": [], "3": [], "4": []}
	for club_id in clubes.keys():
		var club = clubes[club_id]
		if club is Dictionary:
			var div: int = clampi(int(club.get("division", 4)), 1, 4)
			nuevas_divisiones[str(div)].append(str(club_id))

	# Reset de la temporada.
	for club_id in clubes.keys():
		var club = clubes[club_id]
		if club is Dictionary:
			club["puntos"] = 0
			club["victorias"] = 0
			club["empates"] = 0
			club["derrotas"] = 0
			club["racha"] = []
			club["goles_favor"] = 0
			club["goles_contra"] = 0

	var club_usuario_final: Dictionary = Obtener_Club(usuario_id)
	var division_final: int = clampi(int(club_usuario_final.get("division", 4)), 1, 4)
	var campeon_usuario: bool = str(campeones.get(str(division_anterior), "")) == usuario_id
	var movimiento: String = "mantiene"
	if division_final < division_anterior:
		movimiento = "asciende"
	elif division_final > division_anterior:
		movimiento = "desciende"

	var historial: Array = Obtener_Historial()
	historial.push_front({
		"temporada": Obtener_Temporada(),
		"division": division_anterior,
		"posicion": posicion_anterior,
		"puntos": puntos_anteriores,
		"goles_favor": gf_anteriores,
		"goles_contra": gc_anteriores,
		"campeon": campeon_usuario,
		"movimiento": movimiento
	})
	while historial.size() > 20:
		historial.pop_back()
	est["Historial"] = historial

	est["Clubes"] = clubes
	est["Divisiones"] = nuevas_divisiones
	est["Temporada"] = Obtener_Temporada() + 1
	est["Jornada_Actual"] = 0
	_jornadas_pendientes.clear()
	est["Partido_Pendiente"] = false
	est["Partido_Local_Id"] = ""
	est["Partido_Visitante_Id"] = ""
	est["Partido_Es_Local"] = false
	est["Partido_Jornada"] = 0

	var texto: String = "Temporada %d cerrada: %dº con %d puntos en %s." % [
		Obtener_Temporada() - 1, posicion_anterior, puntos_anteriores,
		Datos_Manager.Nombre_Division(division_anterior)]
	if campeon_usuario:
		texto += " ¡Te has proclamado campeón!"
	match movimiento:
		"asciende":
			texto += " El club asciende a %s. La plantilla pierde un 20 %% de calidad (−1 estrella)." % \
				Datos_Manager.Nombre_Division(division_final)
		"desciende":
			texto += " El club desciende a %s. La plantilla gana un 20 %% de calidad relativa (+1 estrella)." % \
				Datos_Manager.Nombre_Division(division_final)
		_:
			texto += " El club se mantiene en %s." % Datos_Manager.Nombre_Division(division_final)
	_Mensaje("Fin de temporada", texto)
	Guardar_Variables_Dinamicas.save_game()


# ------------------------------------------------------------------
# Normalización y retrocompatibilidad
# ------------------------------------------------------------------

func Normalizar_Estado(datos) -> Dictionary:
	var base: Dictionary = Variables_Dinamicas.Manager_Estado_Por_Defecto()
	if not (datos is Dictionary):
		return base

	base["Version"] = Datos_Manager.VERSION_ESTADO
	base["Desbloqueado"] = bool(datos.get("Desbloqueado", false))
	base["Titulo_Entrenador"] = bool(datos.get("Titulo_Entrenador", false))
	base["Retirado_Como_Jugador"] = bool(datos.get("Retirado_Como_Jugador", false))
	base["Activo"] = bool(datos.get("Activo", false))
	base["Reputacion"] = clampi(int(datos.get("Reputacion", 0)), 0, 100)
	base["Club_Usuario_Id"] = str(datos.get("Club_Usuario_Id", "club_usr"))
	base["Temporada"] = maxi(1, int(datos.get("Temporada", 1)))
	base["Semana_Tick"] = int(datos.get("Semana_Tick", -1))
	base["Dia_Tick"] = int(datos.get("Dia_Tick", -1))
	base["Partido_Pendiente"] = bool(datos.get("Partido_Pendiente", false))
	base["Jornada_Actual"] = clampi(int(datos.get("Jornada_Actual", 0)), 0, 4)
	base["Partido_Local_Id"] = str(datos.get("Partido_Local_Id", ""))
	base["Partido_Visitante_Id"] = str(datos.get("Partido_Visitante_Id", ""))
	base["Partido_Es_Local"] = bool(datos.get("Partido_Es_Local", false))
	base["Partido_Jornada"] = clampi(int(datos.get("Partido_Jornada", 0)), 0, 3)
	base["Ultima_Jornada_Iniciada"] = int(datos.get("Ultima_Jornada_Iniciada", -1))
	base["Ultimo_Dia_Nomina"] = int(datos.get("Ultimo_Dia_Nomina", -1))
	var resultados = datos.get("Ultimos_Resultados", [])
	base["Ultimos_Resultados"] = resultados if resultados is Array else []
	var historial = datos.get("Historial", [])
	base["Historial"] = historial if historial is Array else []

	var clubes_raw = datos.get("Clubes", {})
	var clubes: Dictionary = {}
	if clubes_raw is Dictionary:
		for club_id in clubes_raw.keys():
			var club = clubes_raw[club_id]
			if club is Dictionary:
				clubes[str(club_id)] = _Normalizar_Club(str(club_id), club)

	# Si el estado está activo pero el ecosistema no es válido, se regenera
	# conservando la identidad visual del club del usuario.
	if bool(base["Activo"]) and clubes.size() != Datos_Manager.TOTAL_CLUBES:
		var usuario_previo = clubes.get(str(base["Club_Usuario_Id"]), {})
		var nombre: String = str(usuario_previo.get("nombre", Datos_Manager.NOMBRE_CLUB_POR_DEFECTO))
		var colores = usuario_previo.get("colores", Datos_Manager.COLORES_POR_DEFECTO)
		var patron: int = int(usuario_previo.get("escudo_patron", Datos_Manager.PATRON_POR_DEFECTO))
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		var ecosistema: Dictionary = Simulador_Manager.Crear_Ecosistema(
			nombre, colores, patron, rng)
		clubes = ecosistema["Clubes"]
		base["Club_Usuario_Id"] = "club_usr"
		base["Clubes"] = clubes
		base["Divisiones"] = ecosistema["Divisiones"]
	else:
		base["Clubes"] = clubes
		base["Divisiones"] = _Reconstruir_Divisiones(clubes, datos.get("Divisiones", {}))

	# Validar el club del usuario y el partido pendiente.
	if not clubes.is_empty():
		# La IA nunca debe quedarse con menos de 15 efectivos.
		for club_id in clubes.keys():
			var club_ia = clubes[club_id]
			if not (club_ia is Dictionary) or bool(club_ia.get("es_usuario", false)):
				continue
			var guardia: int = 0
			while (club_ia.get("plantilla", []) as Array).size() < 15 and guardia < 6:
				_Promocionar_Canterano(club_ia)
				guardia += 1
		if not clubes.has(str(base["Club_Usuario_Id"])):
			var encontrado_usuario: bool = false
			for club_id in clubes.keys():
				if bool(clubes[club_id].get("es_usuario", false)):
					base["Club_Usuario_Id"] = str(club_id)
					encontrado_usuario = true
					break
			if not encontrado_usuario:
				if clubes.has("club_usr"):
					base["Club_Usuario_Id"] = "club_usr"
				else:
					base["Club_Usuario_Id"] = str(clubes.keys()[0])
		# Garantizar que haya exactamente un club marcado como usuario.
		var club_usuario: Dictionary = clubes.get(str(base["Club_Usuario_Id"]), {})
		if not club_usuario.is_empty() and not bool(club_usuario.get("es_usuario", false)):
			club_usuario["es_usuario"] = true
			clubes[str(base["Club_Usuario_Id"])] = club_usuario
		var resultados_ok = base.get("Ultimos_Resultados", [])
		if resultados_ok is Array and resultados_ok.size() > 12:
			base["Ultimos_Resultados"] = resultados_ok.slice(0, 12)
		var historial_ok = base.get("Historial", [])
		if historial_ok is Array and historial_ok.size() > 20:
			base["Historial"] = historial_ok.slice(0, 20)
		if bool(base["Partido_Pendiente"]):
			var local_id: String = str(base["Partido_Local_Id"])
			var visitante_id: String = str(base["Partido_Visitante_Id"])
			if not clubes.has(local_id) or not clubes.has(visitante_id) \
					or (local_id != str(base["Club_Usuario_Id"]) \
					and visitante_id != str(base["Club_Usuario_Id"])):
				base["Partido_Pendiente"] = false
				base["Partido_Local_Id"] = ""
				base["Partido_Visitante_Id"] = ""
	else:
		base["Activo"] = false
		base["Partido_Pendiente"] = false
		base["Divisiones"] = {"1": [], "2": [], "3": [], "4": []}

	if DESBLOQUEO_MANAGER_QA:
		base["Desbloqueado"] = true
		if int(base.get("Reputacion", 0)) < 25:
			base["Reputacion"] = 25

	return base


func _Normalizar_Club(club_id: String, datos: Dictionary) -> Dictionary:
	var colores_raw = datos.get("colores", Datos_Manager.COLORES_POR_DEFECTO)
	var colores: Array = []
	if colores_raw is Array:
		for color in colores_raw:
			colores.append(str(color))
	while colores.size() < 2:
		colores.append(str(Datos_Manager.COLORES_POR_DEFECTO[colores.size()]))
	var tactica_raw = datos.get("tactica", {})
	var tactica: Dictionary = Datos_Manager.TACTICA_BASE.duplicate(true)
	if tactica_raw is Dictionary:
		var formacion: String = str(tactica_raw.get("formacion", "4-4-2"))
		if not Datos_Manager.FORMACIONES.has(formacion):
			formacion = "4-4-2"
		var mentalidad: String = str(tactica_raw.get("mentalidad", "equilibrada"))
		if not Datos_Manager.MENTALIDADES.has(mentalidad):
			mentalidad = "equilibrada"
		var presion: String = str(tactica_raw.get("presion", "media"))
		if not Datos_Manager.PRESIONES.has(presion):
			presion = "media"
		tactica["formacion"] = formacion
		tactica["mentalidad"] = mentalidad
		tactica["presion"] = presion

	var plantilla_raw = datos.get("plantilla", [])
	var plantilla: Array = []
	if plantilla_raw is Array:
		for jugador in plantilla_raw:
			if jugador is Dictionary:
				plantilla.append(_Normalizar_Jugador(jugador))
	while plantilla.size() < Datos_Manager.PLANTILLA_MINIMA:
		var rol_extra: String = str(Datos_Manager.PLANTILLA_ROLES[
			plantilla.size() % Datos_Manager.PLANTILLA_ROLES.size()])
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		plantilla.append(Simulador_Manager.Generar_Canterano(
			club_id, rol_extra, clampi(int(datos.get("division", 4)), 1, 4), rng))
	while plantilla.size() > Datos_Manager.PLANTILLA_MAXIMA:
		plantilla.pop_back()

	var inst_raw = datos.get("instalaciones", {})
	var inst: Dictionary = Datos_Manager.INSTALACIONES_BASE.duplicate(true)
	if inst_raw is Dictionary:
		for k in Datos_Manager.INSTALACIONES_BASE.keys():
			inst[k] = clampi(int(inst_raw.get(k, 1)), 1, Datos_Manager.INSTALACIONES_NIVEL_MAX)

	var racha_raw = datos.get("racha", [])
	var racha: Array = racha_raw.slice(0, 5) if racha_raw is Array else []
	var cantera_cand_raw = datos.get("cantera_candidatos", [])
	var cantera_cand: Array = []
	if cantera_cand_raw is Array:
		for c in cantera_cand_raw:
			if c is Dictionary:
				cantera_cand.append(_Normalizar_Jugador(c))

	var club: Dictionary = {
		"id": club_id,
		"nombre": str(datos.get("nombre", "Club")),
		"ciudad": str(datos.get("ciudad", "Ciudad")),
		"es_usuario": bool(datos.get("es_usuario", club_id == "club_usr")),
		"division": clampi(int(datos.get("division", 4)), 1, 4),
		"colores": colores,
		"escudo_patron": clampi(int(datos.get("escudo_patron", 1)), 0, Datos_Manager.PATRONES_ESCUDO.size() - 1),
		"presupuesto": int(datos.get("presupuesto", 0)),
		"aficion": maxi(0, int(datos.get("aficion", 1500))),
		"confianza_directiva": clampf(float(datos.get("confianza_directiva", 70.0)), 0.0, 100.0),
		"tactica": tactica,
		"instalaciones": inst,
		"capitan_id": str(datos.get("capitan_id", "")),
		"plantilla": plantilla,
		"alineacion": [],
		"puntos": maxi(0, int(datos.get("puntos", 0))),
		"victorias": maxi(0, int(datos.get("victorias", 0))),
		"empates": maxi(0, int(datos.get("empates", 0))),
		"derrotas": maxi(0, int(datos.get("derrotas", 0))),
		"racha": racha,
		"goles_favor": maxi(0, int(datos.get("goles_favor", 0))),
		"goles_contra": maxi(0, int(datos.get("goles_contra", 0))),
		"entreno_grupal_dia": int(datos.get("entreno_grupal_dia", -1)),
		"cantera_dia": int(datos.get("cantera_dia", -1)),
		"cantera_candidatos": cantera_cand,
		"amistoso_dia": int(datos.get("amistoso_dia", -1))
	}
	var alineacion_raw = datos.get("alineacion", [])
	var alineacion: Array = []
	if alineacion_raw is Array:
		for jugador_id in alineacion_raw:
			alineacion.append(str(jugador_id))
	club["alineacion"] = alineacion
	# Validar que la alineación tenga 11 ids reales y sin duplicados; si no, auto.
	var valida: bool = alineacion.size() == 11
	if valida:
		var ids: Dictionary = {}
		for jugador in plantilla:
			ids[str(jugador.get("id", ""))] = true
		var usados: Dictionary = {}
		for jugador_id in alineacion:
			if not ids.has(jugador_id) or usados.has(jugador_id):
				valida = false
				break
			usados[jugador_id] = true
	if not valida:
		club["alineacion"] = Simulador_Manager.Elegir_Alineacion_Automatica(
			plantilla, str(tactica["formacion"]))
	var cap_id: String = str(club.get("capitan_id", ""))
	var cap_valido: bool = false
	for jugador in plantilla:
		if jugador is Dictionary and str(jugador.get("id", "")) == cap_id:
			cap_valido = true
			break
	if not cap_valido:
		club["capitan_id"] = Simulador_Manager.Elegir_Capitan_Automatico(
			plantilla, club["alineacion"])
	return club


func _Normalizar_Jugador(datos: Dictionary) -> Dictionary:
	var planos: Dictionary = Datos_Manager.Atributos_Planos(datos)
	var atributos: Dictionary = Datos_Manager.Construir_Atributos(planos)
	var roles_raw = datos.get("roles", ["MC"])
	var roles: Array = []
	if roles_raw is Array:
		for rol in roles_raw:
			var texto: String = str(rol)
			if Datos_Manager.ROLES.has(texto) and not roles.has(texto):
				roles.append(texto)
	if roles.is_empty():
		roles = ["MC"]
	var id_jugador: String = str(datos.get("id", ""))
	if id_jugador == "":
		id_jugador = "p_%06d" % randi_range(100000, 999999)
	var jugador: Dictionary = {
		"id": id_jugador,
		"nombre": str(datos.get("nombre", "Jugador")),
		"dorsal": clampi(int(datos.get("dorsal", 1)), 1, 99),
		"edad": clampi(int(datos.get("edad", 18)), Datos_Manager.EDAD_MINIMA,
			Datos_Manager.EDAD_MAXIMA),
		"roles": roles,
		"pie": str(datos.get("pie", "derecho")),
		"altura": clampi(int(datos.get("altura", 180)), 150, 210),
		"peso": clampi(int(datos.get("peso", 75)), 50, 120),
		"calidad": float(datos.get("calidad", 50.0)),
		"estrellas": clampi(int(datos.get("estrellas", 3)), 1, 7),
		"defensa": atributos["defensa"],
		"ataque": atributos["ataque"],
		"fisico_mental": atributos["fisico_mental"],
		"energia": clampf(float(datos.get("energia", 100.0)), 0.0, 100.0),
		"salario_semanal": maxi(0, int(datos.get("salario_semanal", 100))),
		"valor_mercado": maxi(0, int(datos.get("valor_mercado", 1000))),
		"clausula_rescision": maxi(0, int(datos.get("clausula_rescision", 0))),
		"contrato_temporadas": maxi(0, int(datos.get("contrato_temporadas", 1))),
		"partidos_jugados": maxi(0, int(datos.get("partidos_jugados", 0))),
		"goles": maxi(0, int(datos.get("goles", 0))),
		"asistencias": maxi(0, int(datos.get("asistencias", 0))),
		"entrenado_dia": int(datos.get("entrenado_dia", -1))
	}
	Simulador_Manager.Recalcular_Jugador(jugador)
	if int(jugador["clausula_rescision"]) <= 0:
		jugador["clausula_rescision"] = maxi(1000, int(round(
			float(jugador["valor_mercado"]) * 1.75 / 100.0)) * 100)
	return jugador


func _Reconstruir_Divisiones(clubes: Dictionary, divisiones_guardadas) -> Dictionary:
	var resultado: Dictionary = {"1": [], "2": [], "3": [], "4": []}
	if clubes.is_empty():
		return resultado
	# Si el mapa guardado es coherente (4 clubes por división), se conserva.
	if divisiones_guardadas is Dictionary:
		var coherente: bool = true
		for division in range(1, 5):
			var ids = divisiones_guardadas.get(str(division), [])
			if not (ids is Array) or ids.size() != Datos_Manager.CLUBES_POR_DIVISION:
				coherente = false
				break
			for club_id in ids:
				if not clubes.has(str(club_id)):
					coherente = false
					break
			if not coherente:
				break
		if coherente:
			return divisiones_guardadas.duplicate(true)

	# Reasignación determinista: ordenar por división declarada y repartir en
	# bloques de 4. Solo ocurre con saves corruptos o de versiones antiguas.
	var entradas: Array = []
	for club_id in clubes.keys():
		var club = clubes[club_id]
		if club is Dictionary:
			entradas.append({
				"id": str(club_id),
				"division": clampi(int(club.get("division", 4)), 1, 4),
				"puntos": int(club.get("puntos", 0))
			})
	entradas.sort_custom(func(a, b):
		if int(a["division"]) != int(b["division"]):
			return int(a["division"]) < int(b["division"])
		if int(a["puntos"]) != int(b["puntos"]):
			return int(a["puntos"]) > int(b["puntos"])
		return str(a["id"]) < str(b["id"]))
	for i in range(entradas.size()):
		var division_destino: int = clampi(1 + int(i / Datos_Manager.CLUBES_POR_DIVISION), 1, 4)
		var club_id: String = str(entradas[i]["id"])
		var club = clubes.get(club_id, null)
		if club is Dictionary:
			club["division"] = division_destino
		resultado[str(division_destino)].append(club_id)
	return resultado


# ------------------------------------------------------------------
# Mensajes
# ------------------------------------------------------------------

func _Mensaje(titulo: String, descripcion: String) -> void:
	var msg: Mensaje = Mensaje.new()
	msg.titulo = titulo
	msg.descripcion = descripcion
	msg.leido = false
	msg.minuto = Variables_Dinamicas.Minute_Day * 1440 + Variables_Dinamicas.Minute_Minute
	Variables_Dinamicas.Mensajes.append(msg)
