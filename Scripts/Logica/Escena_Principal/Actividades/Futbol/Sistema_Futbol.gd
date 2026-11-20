extends Node

# Sistema de la Carrera de Futbolista (Fase 1 — Modo Jugador).
# Orquesta el estado persistente, el calendario de bloques en Matriz_Jugador,
# la convocatoria, la liga dominical, los partidos diarios del Modo Rápido,
# las primas, el salario y los conflictos con el trabajo.

const NOMBRE_ENTRENAMIENTO := "Entrenamiento_Futbol"
const NOMBRE_PARTIDO := "Partido_Futbol"
const NOMBRE_LESION := "Lesion_Deportiva"
const NOMBRE_DIVISION_TERCERA := 4

const REQUISITO_DEPORTE := 25
const REQUISITO_EDAD_MAX := 30


# ------------------------------------------------------------------
# Consultas de estado
# ------------------------------------------------------------------

func Carrera_Activa() -> bool:
	return bool(Variables_Dinamicas.Carrera_Futbol.get("Activo", false))


func Obtener_Division() -> int:
	return clampi(int(Variables_Dinamicas.Carrera_Futbol.get("Division", 4)), 1, 4)


func Obtener_Datos_Estado() -> Dictionary:
	return Variables_Dinamicas.Carrera_Futbol


func Obtener_Condicion_Fisica() -> float:
	var salud: float = 50.0
	var descanso: float = 50.0
	var hambre: float = 50.0
	if Variables_Dinamicas.Necesidades_Basicas.size() > 0:
		salud = float(Variables_Dinamicas.Necesidades_Basicas[0])
	if Variables_Dinamicas.Necesidades_Basicas.size() > 3:
		descanso = float(Variables_Dinamicas.Necesidades_Basicas[3])
	if Variables_Dinamicas.Necesidades_Basicas.size() > 2:
		hambre = float(Variables_Dinamicas.Necesidades_Basicas[2])
	return Simulador_Futbol.Calcular_Condicion_Fisica(salud, descanso, hambre)


func Obtener_Salud_Fisica() -> float:
	if Variables_Dinamicas.Necesidades_Basicas.size() > 0:
		return float(Variables_Dinamicas.Necesidades_Basicas[0])
	return 50.0


func Obtener_Progreso_Deporte() -> float:
	if Variables_Dinamicas.Progreso.size() > 0:
		return float(Variables_Dinamicas.Progreso[0])
	return 1.0


func Obtener_Innata_Futbol() -> float:
	return Simulador_Futbol.Calcular_Innata_Futbol(Variables_Estaticas.Habilidades)


func _Leer_Habilidad(indice: int) -> float:
	if indice < 0 or indice >= Variables_Estaticas.Habilidades.size():
		return 50.0
	return float(Variables_Estaticas.Habilidades[indice])


func Esta_Lesionado() -> bool:
	return Variables_Dinamicas.Estados_Temporales.has(NOMBRE_LESION)


func Obtener_Nombre_Division(division: int = -1) -> String:
	var div: int = Obtener_Division() if division < 0 else division
	return Simulador_Futbol.Obtener_Nombre_Division(div)


func Obtener_Salario_Semanal() -> int:
	return int(Variables_Dinamicas.Carrera_Futbol.get(
		"Salario_Semanal", Simulador_Futbol.Obtener_Salario_Division(Obtener_Division())))


func Obtener_Estado_Legible() -> String:
	var estado: String = str(Variables_Dinamicas.Carrera_Futbol.get("Estado_Temporada", "En_Curso"))
	match estado:
		"En_Curso": return "Temporada en curso"
		"Ascendido": return "Ascendido"
		"Mantiene": return "Se mantiene"
		"Descendido": return "Descendido"
		"Campeon": return "Campeón de Superliga"
		"Despedido": return "Despedido"
		"Ascenso_Pendiente": return "Ascenso pendiente"
		"Rescindido": return "Contrato rescindido"
		_: return estado.replace("_", " ")


func Cumple_Requisitos_Fichaje() -> Dictionary:
	var deporte: int = 0
	if Variables_Dinamicas.Progreso.size() > 0:
		deporte = int(Variables_Dinamicas.Progreso[0])
	var edad: int = Variables_Estaticas.Calcular_Edad()
	var cumple_deporte: bool = deporte >= REQUISITO_DEPORTE
	var cumple_edad: bool = edad < REQUISITO_EDAD_MAX
	return {
		"cumple": cumple_deporte and cumple_edad,
		"cumple_deporte": cumple_deporte,
		"cumple_edad": cumple_edad,
		"deporte": deporte,
		"requisito_deporte": REQUISITO_DEPORTE,
		"edad": edad,
		"requisito_edad": REQUISITO_EDAD_MAX
	}


func Obtener_Resumen_Entrenamiento() -> String:
	var horario: Dictionary = Calendario_Futbol.Obtener_Horario_Entrenamiento(
		Obtener_Division(), Variables_Estaticas.Modo_Rapido)
	var dias: Array = horario.get("dias", [])
	var nombres: Array[String] = []
	for d in dias:
		nombres.append(Calendario_Futbol.Nombre_Dia(int(d)))
	var inicio: int = int(horario.get("inicio", 0))
	var fin: int = int(horario.get("fin", inicio))
	var dias_txt: String = "Todos los días" if nombres.size() == 7 else " y ".join(nombres)
	return "%s · %s–%s" % [dias_txt, Calendario_Futbol.Formatear_Hora(inicio),
		Calendario_Futbol.Formatear_Hora(fin)]


func Obtener_Resumen_Partidos() -> String:
	if Variables_Estaticas.Modo_Rapido:
		return "Todos los días · %s" % Calendario_Futbol.Formatear_Hora(Calendario_Futbol.PARTIDO_RAPIDO)
	var horas: Array[String] = []
	for h in Calendario_Futbol.PARTIDOS_DOMINGO:
		horas.append(Calendario_Futbol.Formatear_Hora(int(h)))
	return "Domingos · %s" % ", ".join(horas)


func Obtener_Tabla_Liga() -> Array:
	var liga: Dictionary = Variables_Dinamicas.Carrera_Futbol.get("Liga_Domingo", {})
	var puntos_jugador: int = int(liga.get("Puntos_Jugador", 0))
	var puntos_rivales: Array = liga.get("Puntos_Rivales", [0, 0, 0])
	var medias: Array = liga.get("Medias_Rivales", [45.0, 45.0, 45.0])
	var entradas: Array = [{
		"nombre": "Tú",
		"puntos": puntos_jugador,
		"media": Obtener_Progreso_Deporte(),
		"es_jugador": true
	}]
	for i in range(3):
		var p: int = int(puntos_rivales[i]) if i < puntos_rivales.size() else 0
		var m: float = float(medias[i]) if i < medias.size() else 45.0
		entradas.append({
			"nombre": "Rival %d" % (i + 1),
			"puntos": p,
			"media": m,
			"es_jugador": false
		})
	entradas.sort_custom(func(a, b):
		if int(a["puntos"]) != int(b["puntos"]):
			return int(a["puntos"]) > int(b["puntos"])
		if bool(a["es_jugador"]) != bool(b["es_jugador"]):
			return bool(a["es_jugador"])
		return float(a["media"]) > float(b["media"]))
	return entradas


# ------------------------------------------------------------------
# Fichaje y rescisión
# ------------------------------------------------------------------

func Hay_Conflicto_Fichaje() -> bool:
	return Trabajo_Solapa_Con_Futbol(Variables_Dinamicas.Trabajo_Actual, NOMBRE_DIVISION_TERCERA)


func Fichar(despedir_trabajo: bool = false) -> Dictionary:
	if Carrera_Activa():
		return {"fichado": false, "requiere_conflicto": false, "motivo": "Ya tienes un contrato en vigor."}

	var requisitos: Dictionary = Cumple_Requisitos_Fichaje()
	if not bool(requisitos.get("cumple", false)):
		return {
			"fichado": false,
			"requiere_conflicto": false,
			"motivo": "No cumples los requisitos: necesitas Deporte %d o más y menos de %d años." % [
				REQUISITO_DEPORTE, REQUISITO_EDAD_MAX]
		}

	if Hay_Conflicto_Fichaje():
		if not despedir_trabajo:
			return {"fichado": false, "requiere_conflicto": true, "motivo": "conflicto_trabajo"}
		var trabajo_actual: Actividad_Fija_Trabajo = Variables_Dinamicas.Trabajo_Actual
		if trabajo_actual != null:
			Trabajo.Dejar_Trabajo(trabajo_actual)
			Variables_Dinamicas.Trabajo_Actual = null

	Variables_Dinamicas.Carrera_Futbol = Variables_Dinamicas.Carrera_Futbol_Por_Defecto()
	var est: Dictionary = Variables_Dinamicas.Carrera_Futbol
	est["Activo"] = true
	est["Division"] = NOMBRE_DIVISION_TERCERA
	est["Relacion_Entrenador"] = 50.0
	est["Salario_Semanal"] = Simulador_Futbol.Obtener_Salario_Division(NOMBRE_DIVISION_TERCERA)
	est["Estado_Temporada"] = "En_Curso"
	est["Liga_Domingo"] = _Liga_Base(NOMBRE_DIVISION_TERCERA)

	var forzar_siguiente_dia: bool = false
	var dia_semana: int = Variables_Dinamicas.Minute_Day % 7
	if Variables_Estaticas.Modo_Rapido:
		forzar_siguiente_dia = Variables_Dinamicas.Minute_Minute >= Calendario_Futbol.PARTIDO_RAPIDO
	else:
		forzar_siguiente_dia = dia_semana == 6 \
			and Variables_Dinamicas.Minute_Minute >= int(Calendario_Futbol.PARTIDOS_DOMINGO[0])
	_Programar_Calendario(forzar_siguiente_dia)

	_Mensaje("Fichaje por la 3ª División",
		"Has firmado tu primer contrato como futbolista. Entrena martes y jueves y compite los domingos para ascender.")
	Guardar_Variables_Dinamicas.save_game()
	return {"fichado": true, "requiere_conflicto": false, "motivo": ""}


func Rescindir_Contrato(descripcion: String = "") -> void:
	if not Carrera_Activa():
		return
	_Limpiar_Bloques_Futbol(_Minuto_Abs())
	var est: Dictionary = Variables_Dinamicas.Carrera_Futbol
	est["Activo"] = false
	est["Estado_Temporada"] = "Rescindido"
	est["Entrenamiento_En_Curso"] = false
	est["Entrenamiento_Fin_Abs"] = -1
	est["Partido_En_Curso"] = false
	est["Partido_Jornada"] = -1
	est["Conflicto_Ascenso_Pendiente"] = false
	est["Division_Ascenso_Pendiente"] = 0
	var texto: String = descripcion
	if texto == "":
		texto = "Has rescindido tu contrato como futbolista. Ya no tendrás entrenamientos ni partidos."
	_Mensaje("Contrato rescindido", texto)
	Guardar_Variables_Dinamicas.save_game()


func Rescindir_Por_Trabajo() -> void:
	Rescindir_Contrato("Has dejado el fútbol para centrarte en tu nuevo empleo.")


func Cambiar_Asistencia(clave: String, valor: bool) -> bool:
	if clave != "Martes" and clave != "Jueves" and clave != "Diario":
		return false
	var est: Dictionary = Variables_Dinamicas.Carrera_Futbol
	var asistencia: Dictionary = est.get("Entrenamientos_Asistencia", {})
	if not (asistencia is Dictionary):
		asistencia = {}
	asistencia[clave] = valor
	est["Entrenamientos_Asistencia"] = asistencia
	if Carrera_Activa():
		_Programar_Calendario(false)
	Guardar_Variables_Dinamicas.save_game()
	return true


# ------------------------------------------------------------------
# Conflictos con el trabajo
# ------------------------------------------------------------------

func Trabajo_Solapa_Con_Futbol(trabajo: Actividad_Fija_Trabajo, division: int = -1) -> bool:
	if trabajo == null:
		return false
	var div: int = Obtener_Division() if division < 0 else division
	var horario: Dictionary = Calendario_Futbol.Obtener_Horario_Entrenamiento(
		div, Variables_Estaticas.Modo_Rapido)
	var inicio_entreno: int = int(horario.get("inicio", 0))
	var fin_entreno: int = int(horario.get("fin", inicio_entreno))
	var dias_entreno: Array = horario.get("dias", [])
	var dias_trabajo: Array = [0, 1, 2, 3, 4, 5, 6] if Variables_Estaticas.Modo_Rapido \
		else trabajo.dias_laborales
	for dia in dias_entreno:
		if not dias_trabajo.has(int(dia)):
			continue
		var solapa: bool = maxi(inicio_entreno, trabajo.hora_inicio) < mini(fin_entreno, trabajo.hora_final)
		if solapa:
			return true

	# Los partidos también son una obligación fija. En Modo Normal caen en domingo
	# (fuera de los días laborales habituales); en Modo Rápido son diarios a las 20:30.
	var dias_partido: Array = [0, 1, 2, 3, 4, 5, 6] if Variables_Estaticas.Modo_Rapido \
		else [Calendario_Futbol.DIA_PARTIDO_NORMAL]
	var horarios_partido: Array = Calendario_Futbol.Obtener_Horarios_Partidos(
		Variables_Estaticas.Modo_Rapido)
	for dia in dias_partido:
		if not dias_trabajo.has(int(dia)):
			continue
		for hora in horarios_partido:
			var inicio_partido: int = int(hora)
			var fin_partido: int = inicio_partido + Calendario_Futbol.DURACION_PARTIDO
			if maxi(inicio_partido, trabajo.hora_inicio) < mini(fin_partido, trabajo.hora_final):
				return true
	return false


func Trabajo_Solapa_Con_Division(division: int) -> bool:
	return Trabajo_Solapa_Con_Futbol(Variables_Dinamicas.Trabajo_Actual, division)


func Hay_Conflicto_Ascenso_Pendiente() -> bool:
	return bool(Variables_Dinamicas.Carrera_Futbol.get("Conflicto_Ascenso_Pendiente", false))


func Obtener_Datos_Conflicto_Ascenso() -> Dictionary:
	var est: Dictionary = Variables_Dinamicas.Carrera_Futbol
	var trabajo: Actividad_Fija_Trabajo = Variables_Dinamicas.Trabajo_Actual
	var nombre_trabajo: String = ""
	if trabajo != null:
		nombre_trabajo = trabajo.nombre.replace("Trabajar_En_", "").replace("Trabajar_De_", "").replace("_", " ")
	return {
		"pendiente": bool(est.get("Conflicto_Ascenso_Pendiente", false)),
		"division_actual": Obtener_Division(),
		"division_destino": int(est.get("Division_Ascenso_Pendiente", 0)),
		"nombre_destino": Simulador_Futbol.Obtener_Nombre_Division(
			int(est.get("Division_Ascenso_Pendiente", 0))),
		"trabajo": nombre_trabajo
	}


func Resolver_Conflicto_Ascenso(seguir_con_futbol: bool) -> void:
	var est: Dictionary = Variables_Dinamicas.Carrera_Futbol
	if not bool(est.get("Conflicto_Ascenso_Pendiente", false)):
		return
	var division_destino: int = int(est.get("Division_Ascenso_Pendiente", 0))
	est["Conflicto_Ascenso_Pendiente"] = false
	est["Division_Ascenso_Pendiente"] = 0
	if division_destino <= 0 or division_destino >= Obtener_Division():
		if str(est.get("Estado_Temporada", "")) == "Ascenso_Pendiente":
			est["Estado_Temporada"] = "Mantiene"
		return
	if seguir_con_futbol:
		var trabajo_actual: Actividad_Fija_Trabajo = Variables_Dinamicas.Trabajo_Actual
		var dejo_trabajo: bool = false
		if trabajo_actual != null and Trabajo_Solapa_Con_Futbol(trabajo_actual, division_destino):
			Trabajo.Dejar_Trabajo(trabajo_actual)
			Variables_Dinamicas.Trabajo_Actual = null
			dejo_trabajo = true
		_Cambiar_Division(division_destino, "Ascendido")
		var texto: String = "Has ascendido a %s." % Simulador_Futbol.Obtener_Nombre_Division(
			division_destino)
		if dejo_trabajo:
			texto += " Has dejado tu empleo para entrenar a tiempo completo."
		_Mensaje("Ascenso a " + Simulador_Futbol.Obtener_Nombre_Division(division_destino), texto)
	else:
		est["Estado_Temporada"] = "Mantiene"
		_Mensaje("Ascenso rechazado",
			"Has decidido mantener tu empleo. El club mantiene tu ficha en la división actual.")
	Guardar_Variables_Dinamicas.save_game()


# ------------------------------------------------------------------
# Tick por minuto (llamado desde Actividades.Actualizar_Horario)
# ------------------------------------------------------------------

func Tick_Minuto() -> void:
	if not Carrera_Activa():
		return
	if Variables_Dinamicas.Matriz_Jugador.is_empty():
		return
	if Variables_Dinamicas.Minute_Minute < 0 \
			or Variables_Dinamicas.Minute_Minute >= Variables_Dinamicas.Matriz_Jugador.size() \
			or Variables_Dinamicas.Minute_Day < 0 \
			or Variables_Dinamicas.Minute_Day >= Variables_Dinamicas.Matriz_Jugador[0].size():
		return
	var est: Dictionary = Variables_Dinamicas.Carrera_Futbol
	var abs_now: int = _Minuto_Abs()

	# Cierre de bloques iniciados en minutos anteriores.
	if bool(est.get("Entrenamiento_En_Curso", false)) \
			and abs_now >= int(est.get("Entrenamiento_Fin_Abs", -1)):
		_Finalizar_Entrenamiento()
	if bool(est.get("Partido_En_Curso", false)) \
			and abs_now >= int(est.get("Partido_Fin_Abs", -1)):
		_Finalizar_Partido()

	# Inicios de bloque.
	if _Es_Inicio_Entrenamiento():
		_Procesar_Inicio_Entrenamiento()
	if _Es_Inicio_Partido():
		_Procesar_Inicio_Partido()

	# Salario y cambio de temporada.
	if _Toca_Pagar_Salario():
		_Pagar_Salario()
	var dia_semana: int = Variables_Dinamicas.Minute_Day % 7
	if Variables_Estaticas.Modo_Rapido:
		if Variables_Dinamicas.Minute_Minute == 0:
			_Iniciar_Nueva_Temporada_Rapida()
	elif dia_semana == 6 and Variables_Dinamicas.Minute_Minute == 0:
		_Iniciar_Nueva_Temporada_Normal()

	# Si el conflicto ha desaparecido (sin trabajo o con otro que ya no solapa),
	# el ascenso pendiente se confirma solo.
	if Hay_Conflicto_Ascenso_Pendiente():
		var destino: int = int(est.get("Division_Ascenso_Pendiente", 0))
		if destino > 0 and not Trabajo_Solapa_Con_Division(destino):
			Resolver_Conflicto_Ascenso(true)


# ------------------------------------------------------------------
# Entrenamientos
# ------------------------------------------------------------------

func _Es_Inicio_Entrenamiento() -> bool:
	var horario: Dictionary = Calendario_Futbol.Obtener_Horario_Entrenamiento(
		Obtener_Division(), Variables_Estaticas.Modo_Rapido)
	var dia_semana: int = Variables_Dinamicas.Minute_Day % 7
	if not (horario.get("dias", []) as Array).has(dia_semana):
		return false
	return Variables_Dinamicas.Minute_Minute == int(horario.get("inicio", -1))


func _Asistencia_Para_Dia(dia_semana: int) -> bool:
	var asistencia: Dictionary = Variables_Dinamicas.Carrera_Futbol.get("Entrenamientos_Asistencia", {})
	if Variables_Estaticas.Modo_Rapido:
		return bool(asistencia.get("Diario", true))
	match dia_semana:
		1: return bool(asistencia.get("Martes", true))
		3: return bool(asistencia.get("Jueves", true))
	return false


func _Procesar_Inicio_Entrenamiento() -> void:
	var est: Dictionary = Variables_Dinamicas.Carrera_Futbol
	var horario: Dictionary = Calendario_Futbol.Obtener_Horario_Entrenamiento(
		Obtener_Division(), Variables_Estaticas.Modo_Rapido)
	var duracion: int = int(horario.get("duracion", 120))
	var inicio: int = int(horario.get("inicio", 0))

	if not _Asistencia_Para_Dia(Variables_Dinamicas.Minute_Day % 7):
		_Registrar_Falta_Entrenamiento()
		_Borrar_Bloque_Futbol(Variables_Dinamicas.Minute_Day, inicio, duracion, NOMBRE_ENTRENAMIENTO)
		return

	var actividad_entreno: Actividad = Variables_Estaticas.Catalogo_Actividades.get(
		NOMBRE_ENTRENAMIENTO, null)
	if actividad_entreno == null:
		return
	var celda_actual = Variables_Dinamicas.Matriz_Jugador[Variables_Dinamicas.Minute_Minute][
		Variables_Dinamicas.Minute_Day]
	if celda_actual is Actividad_Fija_Trabajo:
		_Registrar_Falta_Entrenamiento()
		_Borrar_Bloque_Futbol(Variables_Dinamicas.Minute_Day, inicio, duracion, NOMBRE_ENTRENAMIENTO)
		return
	if not _Celda_Es_Actividad(Variables_Dinamicas.Minute_Minute, Variables_Dinamicas.Minute_Day,
			NOMBRE_ENTRENAMIENTO):
		_Escribir_Bloque(Variables_Dinamicas.Minute_Day, Variables_Dinamicas.Minute_Minute,
			duracion, actividad_entreno)
	if not _Celda_Es_Actividad(Variables_Dinamicas.Minute_Minute, Variables_Dinamicas.Minute_Day,
			NOMBRE_ENTRENAMIENTO):
		# Un examen P3 u otra actividad superior impide el entrenamiento.
		return
	est["Entrenamiento_En_Curso"] = true
	est["Entrenamiento_Fin_Abs"] = _Minuto_Abs() + duracion


func _Finalizar_Entrenamiento() -> void:
	var est: Dictionary = Variables_Dinamicas.Carrera_Futbol
	var condicion: float = Obtener_Condicion_Fisica()
	var incremento: float = 5.0 if condicion >= 70.0 else 3.0
	est["Relacion_Entrenador"] = clampf(
		float(est.get("Relacion_Entrenador", 50.0)) + incremento, 0.0, 100.0)
	est["Entrenamientos_Cancelados_Seguidos"] = 0
	est["Entrenamiento_En_Curso"] = false
	est["Entrenamiento_Fin_Abs"] = -1


func _Registrar_Falta_Entrenamiento() -> void:
	var est: Dictionary = Variables_Dinamicas.Carrera_Futbol
	var relacion: float = clampf(float(est.get("Relacion_Entrenador", 50.0)) - 12.0, 0.0, 100.0)
	est["Relacion_Entrenador"] = relacion
	est["Entrenamientos_Cancelados_Seguidos"] = int(
		est.get("Entrenamientos_Cancelados_Seguidos", 0)) + 1
	var texto: String = "Has faltado al entrenamiento. El entrenador no está nada contento (−12 de relación)."
	if relacion < 25.0:
		texto += "\nTu relación con el entrenador es tan baja que no te convocará."
	_Mensaje("Falta al entrenamiento", texto)


# ------------------------------------------------------------------
# Partidos (liga dominical y Modo Rápido)
# ------------------------------------------------------------------

func _Es_Inicio_Partido() -> bool:
	var dia_semana: int = Variables_Dinamicas.Minute_Day % 7
	if not Calendario_Futbol.Es_Dia_Partido(dia_semana, Variables_Estaticas.Modo_Rapido):
		return false
	return Calendario_Futbol.Obtener_Horarios_Partidos(
		Variables_Estaticas.Modo_Rapido).has(Variables_Dinamicas.Minute_Minute)


func _Procesar_Inicio_Partido() -> void:
	var est: Dictionary = Variables_Dinamicas.Carrera_Futbol
	var modo_rapido: bool = Variables_Estaticas.Modo_Rapido
	var jornada: int = 0
	var es_decisivo: bool = modo_rapido
	if not modo_rapido:
		_Asegurar_Liga()
		var liga: Dictionary = est.get("Liga_Domingo", {})
		jornada = clampi(int(liga.get("Jornada_Actual", 0)), 0, 3)
		var indice_hora: int = Calendario_Futbol.Obtener_Indice_Jornada(
			Variables_Dinamicas.Minute_Minute, false)
		if indice_hora >= 0 and indice_hora != jornada:
			jornada = indice_hora
			liga["Jornada_Actual"] = jornada
		es_decisivo = jornada >= 3

	var evaluacion: Dictionary = Simulador_Futbol.Evaluar_Convocatoria(
		float(est.get("Relacion_Entrenador", 50.0)),
		Obtener_Condicion_Fisica(),
		Obtener_Salud_Fisica(),
		_Leer_Habilidad(4),
		Esta_Lesionado())
	var convocado: bool = bool(evaluacion.get("convocado", false))

	est["Partido_En_Curso"] = true
	est["Partido_Jornada"] = jornada
	est["Partido_Convocado"] = convocado
	est["Partido_Decisivo"] = es_decisivo
	est["Partido_Fin_Abs"] = _Minuto_Abs() + Calendario_Futbol.DURACION_PARTIDO

	if convocado:
		var partido: Actividad = Variables_Estaticas.Catalogo_Actividades.get(NOMBRE_PARTIDO, null)
		if partido != null and not _Celda_Es_Actividad(Variables_Dinamicas.Minute_Minute,
				Variables_Dinamicas.Minute_Day, NOMBRE_PARTIDO):
			_Escribir_Bloque(Variables_Dinamicas.Minute_Day, Variables_Dinamicas.Minute_Minute,
				Calendario_Futbol.DURACION_PARTIDO, partido)
	else:
		_Borrar_Bloque_Futbol(Variables_Dinamicas.Minute_Day, Variables_Dinamicas.Minute_Minute,
			Calendario_Futbol.DURACION_PARTIDO, NOMBRE_PARTIDO)
		_Mensaje("No convocado", _Texto_Motivo_No_Convocado(str(evaluacion.get("motivo", ""))))


func _Texto_Motivo_No_Convocado(motivo: String) -> String:
	match motivo:
		"lesionado":
			return "El entrenador no te ha convocado porque sigues lesionado."
		"salud_baja":
			return "El entrenador no te ha convocado: tu salud física está por debajo de 30."
		"relacion_baja":
			return "El entrenador no te ha convocado: vuestra relación está por debajo de 25."
		_:
			return "El entrenador no te ha convocado: tu índice de convocatoria no llega a 45."


func _Finalizar_Partido() -> void:
	var est: Dictionary = Variables_Dinamicas.Carrera_Futbol
	var jornada: int = int(est.get("Partido_Jornada", 0))
	var convocado: bool = bool(est.get("Partido_Convocado", false))
	est["Partido_En_Curso"] = false
	est["Partido_Jornada"] = -1
	est["Partido_Convocado"] = false
	est["Partido_Decisivo"] = false
	est["Partido_Fin_Abs"] = -1

	if Variables_Estaticas.Modo_Rapido:
		_Resolver_Partido_Rapido(convocado)
	elif jornada >= 3:
		_Resolver_Playoff(convocado)
	else:
		_Resolver_Jornada_Regular(jornada, convocado)


func _Resultado_No_Convocado() -> Dictionary:
	return {
		"resultado": "Derrota",
		"goles": 0,
		"asistencias": 0,
		"delta_relacion": 0.0,
		"gano_penaltis": false
	}


func _Resolver_Jornada_Regular(jornada: int, convocado: bool) -> void:
	var est: Dictionary = Variables_Dinamicas.Carrera_Futbol
	var liga: Dictionary = est.get("Liga_Domingo", {})
	var medias: Array = liga.get("Medias_Rivales", [45.0, 45.0, 45.0])
	var media_rival: float = float(medias[jornada]) if jornada < medias.size() else 45.0
	var resultado: Dictionary = _Resultado_No_Convocado()
	if convocado:
		var puntuacion: float = Simulador_Futbol.Calcular_Puntuacion_Partido(
			Obtener_Progreso_Deporte(),
			Obtener_Condicion_Fisica(),
			Obtener_Innata_Futbol(),
			_Leer_Habilidad(6),
			false,
			randfn(0.0, 10.0))
		resultado = Simulador_Futbol.Simular_Partido_Liga(
			puntuacion, media_rival, false, _Leer_Habilidad(6), Obtener_Progreso_Deporte())
		_Aplicar_Resultado_Jugador(resultado)

	var puntos: int = 0
	match str(resultado.get("resultado", "Derrota")):
		"Victoria":
			puntos = 3
		"Empate":
			puntos = 1
	liga["Puntos_Jugador"] = int(liga.get("Puntos_Jugador", 0)) + puntos

	_Simular_Cruce_Rivales(jornada)
	liga["Jornada_Actual"] = mini(4, jornada + 1)
	if jornada >= 2:
		liga["Posicion_Regular"] = _Calcular_Posicion_Regular()
	est["Liga_Domingo"] = liga

	var texto: String = _Texto_Resultado(resultado, convocado)
	texto += "\nPuntos de la jornada: %d." % puntos
	if jornada >= 2:
		texto += "\nClasificación regular: %dº de 4." % int(liga.get("Posicion_Regular", 1))
	if convocado:
		var primas: float = _Calcular_Primas(resultado)
		if primas > 0.0:
			texto += "\nPrimas cobradas: +%.0f€." % primas
	_Mensaje("Jornada %d de la liga" % (jornada + 1), texto)


func _Resolver_Playoff(convocado: bool) -> void:
	var est: Dictionary = Variables_Dinamicas.Carrera_Futbol
	var liga: Dictionary = est.get("Liga_Domingo", {})
	var posicion: int = clampi(int(liga.get("Posicion_Regular", 1)), 1, 4)
	if int(liga.get("Jornada_Actual", 0)) < 3:
		liga["Posicion_Regular"] = _Calcular_Posicion_Regular()
		posicion = int(liga["Posicion_Regular"])
	var media_rival: float = _Media_Rival_Playoff(posicion)
	var resultado: Dictionary = _Resultado_No_Convocado()
	if convocado:
		var puntuacion: float = Simulador_Futbol.Calcular_Puntuacion_Partido(
			Obtener_Progreso_Deporte(),
			Obtener_Condicion_Fisica(),
			Obtener_Innata_Futbol(),
			_Leer_Habilidad(6),
			true,
			randfn(0.0, 10.0))
		resultado = Simulador_Futbol.Simular_Partido_Liga(
			puntuacion, media_rival, true, _Leer_Habilidad(6),
			Obtener_Progreso_Deporte(), randf())
		_Aplicar_Resultado_Jugador(resultado)

	var gano: bool = str(resultado.get("resultado", "")) == "Victoria" \
		or str(resultado.get("resultado", "")) == "Victoria_Penaltis"
	var resolucion: Dictionary = Simulador_Futbol.Resolver_Playoff_Domingo(
		posicion, gano, Obtener_Division())
	liga["Jornada_Actual"] = 4
	est["Liga_Domingo"] = liga
	est["Temporadas_Jugadas"] = int(est.get("Temporadas_Jugadas", 0)) + 1

	var texto: String = _Texto_Resultado(resultado, convocado)
	texto += "\nPlayoff por %s." % ("el ascenso" if posicion <= 2 else "la permanencia")
	if convocado:
		var primas: float = _Calcular_Primas(resultado)
		if primas > 0.0:
			texto += "\nPrimas cobradas: +%.0f€." % primas
	var aplicado: String = _Aplicar_Fin_De_Temporada(resolucion)
	texto += "\n" + aplicado
	_Mensaje("Final de temporada — %dº" % posicion, texto)


func _Resolver_Partido_Rapido(convocado: bool) -> void:
	var est: Dictionary = Variables_Dinamicas.Carrera_Futbol
	var division: int = Obtener_Division()
	var resultado: Dictionary
	if convocado:
		var puntuacion: float = Simulador_Futbol.Calcular_Puntuacion_Partido(
			Obtener_Progreso_Deporte(),
			Obtener_Condicion_Fisica(),
			Obtener_Innata_Futbol(),
			_Leer_Habilidad(6),
			true,
			randfn(0.0, 10.0))
		resultado = Simulador_Futbol.Simular_Partido_Rapido(puntuacion, division)
		_Aplicar_Resultado_Jugador(resultado)
	else:
		# Derrota 0-3 sin goles ni primas: mismas consecuencias que un partido perdido.
		resultado = Simulador_Futbol.Simular_Partido_Rapido(0.0, division)
	est["Temporadas_Jugadas"] = int(est.get("Temporadas_Jugadas", 0)) + 1

	var resolucion: Dictionary = {
		"posicion_final": 0,
		"cambio_division": int(resultado.get("cambio_division", 0)),
		"campeon_superliga": bool(resultado.get("campeon_superliga", false)),
		"despedido": bool(resultado.get("despedido", false))
	}
	var texto: String = _Texto_Resultado(resultado, convocado)
	if convocado:
		var primas: float = _Calcular_Primas(resultado)
		if primas > 0.0:
			texto += "\nPrimas cobradas: +%.0f€." % primas
	var aplicado: String = _Aplicar_Fin_De_Temporada(resolucion)
	texto += "\n" + aplicado
	_Mensaje("Partido decisivo diario", texto)


func _Texto_Resultado(resultado: Dictionary, convocado: bool) -> String:
	if not convocado:
		return "No fuiste convocado. Derrota por 0-3."
	var nombre: String = str(resultado.get("resultado", "Derrota"))
	var goles: int = int(resultado.get("goles", 0))
	var asistencias: int = int(resultado.get("asistencias", 0))
	match nombre:
		"Victoria":
			return "Victoria con %d gol(es) y %d asistencia(s)." % [goles, asistencias]
		"Victoria_Penaltis":
			return "Empate y victoria en la tanda de penaltis."
		"Derrota_Penaltis":
			return "Empate y derrota en la tanda de penaltis."
		"Empate":
			return "Empate sin goles."
		_:
			return "Derrota."


func _Aplicar_Resultado_Jugador(resultado: Dictionary) -> void:
	var est: Dictionary = Variables_Dinamicas.Carrera_Futbol
	est["Partidos_Jugados"] = int(est.get("Partidos_Jugados", 0)) + 1
	est["Goles_Totales"] = int(est.get("Goles_Totales", 0)) + int(resultado.get("goles", 0))
	est["Asistencias_Totales"] = int(est.get("Asistencias_Totales", 0)) \
		+ int(resultado.get("asistencias", 0))
	est["Relacion_Entrenador"] = clampf(
		float(est.get("Relacion_Entrenador", 50.0)) + float(resultado.get("delta_relacion", 0.0)),
		0.0, 100.0)

	var primas: float = _Calcular_Primas(resultado)
	if primas > 0.0:
		Variables_Dinamicas.Dinero += primas

	if Simulador_Futbol.Comprobar_Riesgo_Lesion(
			Obtener_Condicion_Fisica(), Obtener_Salud_Fisica(), randf()):
		Actividades.Activar_Estado(NOMBRE_LESION)


func _Calcular_Primas(resultado: Dictionary) -> float:
	var division: int = Obtener_Division()
	var nombre: String = str(resultado.get("resultado", ""))
	var gana: bool = nombre == "Victoria" or nombre == "Victoria_Penaltis"
	var total: float = 0.0
	if gana:
		total += float(Simulador_Futbol.PRIMAS_VICTORIA.get(division, 50))
	total += float(Simulador_Futbol.PRIMAS_GOL.get(division, 15)) * int(resultado.get("goles", 0))
	return round(total * Variables_Estaticas.Multiplicador_Precios())


# ------------------------------------------------------------------
# Liga dominical
# ------------------------------------------------------------------

func _Liga_Base(division: int) -> Dictionary:
	return {
		"Jornada_Actual": 0,
		"Puntos_Jugador": 0,
		"Puntos_Rivales": [0, 0, 0],
		"Medias_Rivales": _Generar_Medias_Rivales(division),
		"Posicion_Regular": 1
	}


func _Generar_Medias_Rivales(division: int) -> Array:
	var umbral: float = Simulador_Futbol.Obtener_Umbral_Division(division)
	var medias: Array = []
	for _i in range(3):
		medias.append(clampf(umbral + randf_range(-5.0, 5.0), 20.0, 100.0))
	return medias


func _Asegurar_Liga() -> void:
	if Variables_Estaticas.Modo_Rapido:
		return
	var est: Dictionary = Variables_Dinamicas.Carrera_Futbol
	var liga = est.get("Liga_Domingo", {})
	if not (liga is Dictionary):
		liga = _Liga_Base(Obtener_Division())
		est["Liga_Domingo"] = liga
	var medias = liga.get("Medias_Rivales", [])
	var necesita_medias: bool = not (medias is Array) or medias.size() < 3
	if not necesita_medias:
		necesita_medias = true
		for m in medias:
			if float(m) > 0.0:
				necesita_medias = false
				break
	if necesita_medias:
		liga["Medias_Rivales"] = _Generar_Medias_Rivales(Obtener_Division())
	liga["Jornada_Actual"] = clampi(int(liga.get("Jornada_Actual", 0)), 0, 4)
	est["Liga_Domingo"] = liga


func _Simular_Cruce_Rivales(jornada: int) -> void:
	var liga: Dictionary = Variables_Dinamicas.Carrera_Futbol.get("Liga_Domingo", {})
	var puntos: Array = liga.get("Puntos_Rivales", [0, 0, 0])
	var medias: Array = liga.get("Medias_Rivales", [45.0, 45.0, 45.0])
	var a: int = 1
	var b: int = 2
	match jornada:
		0:
			a = 1
			b = 2
		1:
			a = 0
			b = 2
		2:
			a = 0
			b = 1
	if puntos.size() < 3 or medias.size() < 3:
		return
	var media_a: float = float(medias[a])
	var media_b: float = float(medias[b])
	var puntuacion_a: float = clampf(media_a + randfn(0.0, 8.0), 0.0, 100.0)
	var resultado: Dictionary = Simulador_Futbol.Simular_Partido_Liga(
		puntuacion_a, media_b, false)
	match str(resultado.get("resultado", "Derrota")):
		"Victoria":
			puntos[a] = int(puntos[a]) + 3
		"Empate":
			puntos[a] = int(puntos[a]) + 1
			puntos[b] = int(puntos[b]) + 1
		_:
			puntos[b] = int(puntos[b]) + 3
	liga["Puntos_Rivales"] = puntos
	Variables_Dinamicas.Carrera_Futbol["Liga_Domingo"] = liga


func _Calcular_Posicion_Regular() -> int:
	var liga: Dictionary = Variables_Dinamicas.Carrera_Futbol.get("Liga_Domingo", {})
	var puntos_jugador: int = int(liga.get("Puntos_Jugador", 0))
	var puntos_rivales: Array = liga.get("Puntos_Rivales", [0, 0, 0])
	var posicion: int = 1
	for p in puntos_rivales:
		if int(p) > puntos_jugador:
			posicion += 1
	return clampi(posicion, 1, 4)


func _Media_Rival_Playoff(posicion: int) -> float:
	var liga: Dictionary = Variables_Dinamicas.Carrera_Futbol.get("Liga_Domingo", {})
	var medias: Array = liga.get("Medias_Rivales", [45.0, 45.0, 45.0])
	var media: float = 45.0
	if medias.size() >= 3:
		media = float(medias.max()) if posicion <= 2 else float(medias.min())
	return clampf(media, 20.0, 100.0)


# ------------------------------------------------------------------
# Cierre de temporada, división y salario
# ------------------------------------------------------------------

func _Aplicar_Fin_De_Temporada(resolucion: Dictionary) -> String:
	var est: Dictionary = Variables_Dinamicas.Carrera_Futbol
	# Una oferta de ascenso que el jugador dejó pasar una temporada completa caduca.
	if bool(est.get("Conflicto_Ascenso_Pendiente", false)):
		est["Conflicto_Ascenso_Pendiente"] = false
		est["Division_Ascenso_Pendiente"] = 0
	if bool(resolucion.get("despedido", false)):
		_Limpiar_Bloques_Futbol(_Minuto_Abs())
		est["Activo"] = false
		est["Estado_Temporada"] = "Despedido"
		est["Entrenamiento_En_Curso"] = false
		est["Partido_En_Curso"] = false
		est["Conflicto_Ascenso_Pendiente"] = false
		est["Division_Ascenso_Pendiente"] = 0
		return "El club ha rescindido tu contrato: quedas despedido."

	if bool(resolucion.get("campeon_superliga", false)):
		est["Titulos_Superliga"] = int(est.get("Titulos_Superliga", 0)) + 1
		est["Estado_Temporada"] = "Campeon"
		est["Conflicto_Ascenso_Pendiente"] = false
		est["Division_Ascenso_Pendiente"] = 0
		return "¡Te has proclamado campeón de la Superliga!"

	var cambio: int = int(resolucion.get("cambio_division", 0))
	if cambio < 0:
		var destino: int = maxi(1, Obtener_Division() - 1)
		if Trabajo_Solapa_Con_Division(destino):
			est["Conflicto_Ascenso_Pendiente"] = true
			est["Division_Ascenso_Pendiente"] = destino
			est["Estado_Temporada"] = "Ascenso_Pendiente"
			return "Ascenso a %s pendiente: tu trabajo choca con el nuevo horario de entrenamientos." \
				% Simulador_Futbol.Obtener_Nombre_Division(destino)
		_Cambiar_Division(destino, "Ascendido")
		return "¡Ascenso a %s!" % Simulador_Futbol.Obtener_Nombre_Division(destino)

	if cambio > 0:
		var destino: int = mini(4, Obtener_Division() + 1)
		_Cambiar_Division(destino, "Descendido")
		return "Desciendes a %s." % Simulador_Futbol.Obtener_Nombre_Division(destino)

	est["Estado_Temporada"] = "Mantiene"
	return "Te mantienes en %s." % Obtener_Nombre_Division()


func _Cambiar_Division(nueva_division: int, estado: String) -> void:
	var est: Dictionary = Variables_Dinamicas.Carrera_Futbol
	est["Division"] = clampi(nueva_division, 1, 4)
	est["Salario_Semanal"] = Simulador_Futbol.Obtener_Salario_Division(int(est["Division"]))
	est["Estado_Temporada"] = estado
	_Programar_Calendario(false)


func _Iniciar_Nueva_Temporada_Normal() -> void:
	var est: Dictionary = Variables_Dinamicas.Carrera_Futbol
	if not bool(est.get("Conflicto_Ascenso_Pendiente", false)):
		est["Estado_Temporada"] = "En_Curso"
	est["Liga_Domingo"] = _Liga_Base(Obtener_Division())


func _Iniciar_Nueva_Temporada_Rapida() -> void:
	var est: Dictionary = Variables_Dinamicas.Carrera_Futbol
	if not bool(est.get("Conflicto_Ascenso_Pendiente", false)):
		est["Estado_Temporada"] = "En_Curso"


func _Toca_Pagar_Salario() -> bool:
	if Variables_Dinamicas.Minute_Minute != 1439:
		return false
	if not Variables_Estaticas.Modo_Rapido and Variables_Dinamicas.Minute_Day % 7 != 6:
		return false
	return int(Variables_Dinamicas.Carrera_Futbol.get("Ultimo_Dia_Salario", -1)) != Variables_Dinamicas.Minute_Day


func _Pagar_Salario() -> void:
	var est: Dictionary = Variables_Dinamicas.Carrera_Futbol
	var cantidad: float = round(float(Obtener_Salario_Semanal())
		* Variables_Estaticas.Multiplicador_Precios())
	Variables_Dinamicas.Dinero += cantidad
	est["Ultimo_Dia_Salario"] = Variables_Dinamicas.Minute_Day


# ------------------------------------------------------------------
# Programación y limpieza de bloques en Matriz_Jugador
# ------------------------------------------------------------------

func _Programar_Calendario(forzar_siguiente_dia: bool = false) -> void:
	if not Carrera_Activa():
		return
	if Variables_Dinamicas.Matriz_Jugador.is_empty() or Variables_Dinamicas.Matriz_Jugador[0].is_empty():
		return
	var columnas: int = Variables_Dinamicas.Matriz_Jugador[0].size()
	var modo_rapido: bool = Variables_Estaticas.Modo_Rapido
	var dia_ini: int = Variables_Dinamicas.Minute_Day
	var min_ini: int = Variables_Dinamicas.Minute_Minute
	if forzar_siguiente_dia:
		dia_ini += 1
		min_ini = 0
	dia_ini = mini(dia_ini, 573)
	if dia_ini >= columnas:
		return

	_Limpiar_Bloques_Futbol(_Minuto_Abs())

	var horario: Dictionary = Calendario_Futbol.Obtener_Horario_Entrenamiento(
		Obtener_Division(), modo_rapido)
	var actividad_entreno: Actividad = Variables_Estaticas.Catalogo_Actividades.get(
		NOMBRE_ENTRENAMIENTO, null)
	var actividad_partido: Actividad = Variables_Estaticas.Catalogo_Actividades.get(
		NOMBRE_PARTIDO, null)
	if actividad_entreno == null or actividad_partido == null:
		return
	var dias_entreno: Array = horario.get("dias", [])
	var inicio_entreno: int = int(horario.get("inicio", 0))
	var duracion_entreno: int = int(horario.get("duracion", 120))
	var horarios_partido: Array = Calendario_Futbol.Obtener_Horarios_Partidos(modo_rapido)

	for dia in range(dia_ini, mini(574, columnas)):
		var base: int = min_ini if dia == dia_ini else 0
		var dia_semana: int = dia % 7
		if dias_entreno.has(dia_semana) and _Asistencia_Para_Dia(dia_semana):
			if inicio_entreno >= base:
				_Escribir_Bloque(dia, inicio_entreno, duracion_entreno, actividad_entreno)
		if Calendario_Futbol.Es_Dia_Partido(dia_semana, modo_rapido):
			for hora in horarios_partido:
				if int(hora) >= base:
					_Escribir_Bloque(dia, int(hora), Calendario_Futbol.DURACION_PARTIDO,
						actividad_partido)
	Variables_Dinamicas.Matriz_Sucia = true


func _Escribir_Bloque(dia_abs: int, minuto_inicio: int, duracion: int, actividad: Actividad) -> void:
	if actividad == null or Variables_Dinamicas.Matriz_Jugador.is_empty():
		return
	if dia_abs < 0 or dia_abs >= Variables_Dinamicas.Matriz_Jugador[0].size():
		return
	for offset in range(maxi(0, duracion)):
		var fila: int = minuto_inicio + offset
		if fila < 0 or fila >= Variables_Dinamicas.Matriz_Jugador.size():
			break
		var actual = Variables_Dinamicas.Matriz_Jugador[fila][dia_abs]
		# Nunca pisar un examen: es el único bloque P3 que debe prevalecer.
		if actual is Actividad_Examen:
			continue
		# Un descenso puede devolver el entrenamiento a una franja ocupada por
		# un empleo que antes no solapaba. No borrar el trabajo en silencio.
		if actual is Actividad_Fija_Trabajo:
			continue
		Actividades.Crear_Actividad(dia_abs, fila, actividad)
	Variables_Dinamicas.Matriz_Sucia = true


func _Borrar_Bloque_Futbol(dia_abs: int, minuto_inicio: int, duracion: int, nombre: String) -> void:
	if Variables_Dinamicas.Matriz_Jugador.is_empty():
		return
	if dia_abs < 0 or dia_abs >= Variables_Dinamicas.Matriz_Jugador[0].size():
		return
	for offset in range(maxi(0, duracion)):
		var fila: int = minuto_inicio + offset
		if fila < 0 or fila >= Variables_Dinamicas.Matriz_Jugador.size():
			break
		var celda = Variables_Dinamicas.Matriz_Jugador[fila][dia_abs]
		if celda is Actividad and celda.nombre == nombre:
			Variables_Dinamicas.Matriz_Jugador[fila][dia_abs] = ""
			Variables_Dinamicas.Matriz_Sucia = true


func _Limpiar_Bloques_Futbol(desde_abs: int) -> void:
	if Variables_Dinamicas.Matriz_Jugador.is_empty() or Variables_Dinamicas.Matriz_Jugador[0].is_empty():
		return
	var columnas: int = Variables_Dinamicas.Matriz_Jugador[0].size()
	var dia_ini: int = desde_abs / 1440
	var min_ini: int = desde_abs % 1440
	var est: Dictionary = Variables_Dinamicas.Carrera_Futbol
	var proteger_entreno_hasta: int = int(est.get("Entrenamiento_Fin_Abs", -1)) \
		if bool(est.get("Entrenamiento_En_Curso", false)) else -1
	var proteger_partido_hasta: int = int(est.get("Partido_Fin_Abs", -1)) \
		if bool(est.get("Partido_En_Curso", false)) else -1

	for col in range(maxi(0, dia_ini), mini(574, columnas)):
		var fila_ini: int = min_ini + 1 if col == dia_ini else 0
		for fila in range(fila_ini, Variables_Dinamicas.Matriz_Jugador.size()):
			var celda = Variables_Dinamicas.Matriz_Jugador[fila][col]
			if not (celda is Actividad):
				continue
			if celda.nombre != NOMBRE_ENTRENAMIENTO and celda.nombre != NOMBRE_PARTIDO:
				continue
			var abs_celda: int = col * 1440 + fila
			if celda.nombre == NOMBRE_ENTRENAMIENTO and proteger_entreno_hasta >= abs_celda:
				continue
			if celda.nombre == NOMBRE_PARTIDO and proteger_partido_hasta >= abs_celda:
				continue
			Variables_Dinamicas.Matriz_Jugador[fila][col] = ""
			Variables_Dinamicas.Matriz_Sucia = true


func _Celda_Es_Actividad(fila: int, columna: int, nombre: String) -> bool:
	if Variables_Dinamicas.Matriz_Jugador.is_empty():
		return false
	if fila < 0 or fila >= Variables_Dinamicas.Matriz_Jugador.size():
		return false
	if columna < 0 or columna >= Variables_Dinamicas.Matriz_Jugador[0].size():
		return false
	var celda = Variables_Dinamicas.Matriz_Jugador[fila][columna]
	return celda is Actividad and celda.nombre == nombre


func _Minuto_Abs() -> int:
	return Variables_Dinamicas.Minute_Day * 1440 + Variables_Dinamicas.Minute_Minute


func _Mensaje(titulo: String, descripcion: String) -> void:
	var msg: Mensaje = Mensaje.new()
	msg.titulo = titulo
	msg.descripcion = descripcion
	msg.leido = false
	msg.minuto = _Minuto_Abs()
	Variables_Dinamicas.Mensajes.append(msg)
