extends Node

const COSTO_INSCRIPCION_BASE: float = 50.0


func Obtener_Costo_Inscripcion() -> float:
	return round(COSTO_INSCRIPCION_BASE * Variables_Estaticas.Multiplicador_Precios())


func Puede_Inscribirse_Hoy() -> bool:
	var dia_semana: int = Variables_Dinamicas.Minute_Day % 7
	return dia_semana < 5


func Inscribirse_Carrera(dia: int, hora_inicio: int) -> bool:
	if not Puede_Inscribirse_Hoy():
		return false
	if dia != 5 and dia != 6:
		return false
	if hora_inicio < 420 or hora_inicio > 1020:
		return false
	var costo := Obtener_Costo_Inscripcion()
	if Variables_Dinamicas.Dinero < costo:
		return false
	if Variables_Dinamicas.Carrera_Deportiva_Pendiente.get("inscrito", false):
		return false
	Variables_Dinamicas.Dinero -= costo
	var semana_actual: int = Variables_Dinamicas.Minute_Day / 7
	Variables_Dinamicas.Carrera_Deportiva_Pendiente["inscrito"] = true
	Variables_Dinamicas.Carrera_Deportiva_Pendiente["dia"] = dia
	Variables_Dinamicas.Carrera_Deportiva_Pendiente["hora_inicio"] = hora_inicio
	Variables_Dinamicas.Carrera_Deportiva_Pendiente["semana_inscripcion"] = semana_actual
	Variables_Dinamicas.Carrera_Deportiva_Pendiente["resultado_puesto"] = -1
	Variables_Dinamicas.Carrera_Deportiva_Pendiente["resultado_procesado"] = false
	Escribir_Carrera_En_Matriz()
	Guardar_Variables_Dinamicas.save_game()
	return true


func Escribir_Carrera_En_Matriz() -> void:
	var pendiente: Dictionary = Variables_Dinamicas.Carrera_Deportiva_Pendiente
	var semana: int = int(pendiente.get("semana_inscripcion", -1))
	var dia: int = int(pendiente.get("dia", -1))
	var columna: int = semana * 7 + dia
	if columna < 0 or columna >= 574:
		return
	var actividad = Variables_Estaticas.Catalogo_Actividades.get("Carrera_Deportiva", null)
	if actividad == null:
		return
	var hora_inicio: int = int(pendiente.get("hora_inicio", -1))
	for offset in range(60):
		var fila: int = hora_inicio + offset
		if fila >= 0 and fila < 1440:
			Variables_Dinamicas.Matriz_Jugador[fila][columna] = actividad
	Variables_Dinamicas.Matriz_Sucia = true
	Sistema_Notificaciones.Programar_Notificacion_Actividad("Carrera deportiva", semana, dia, hora_inicio / 60, hora_inicio % 60)


func Calcular_Y_Guardar_Resultado() -> void:
	var deporte: float = float(Variables_Dinamicas.Progreso[0]) if Variables_Dinamicas.Progreso.size() > 0 else 1.0
	var salud_fisica: float = float(Variables_Dinamicas.Necesidades_Basicas[0]) if Variables_Dinamicas.Necesidades_Basicas.size() > 0 else 50.0
	var descanso: float = float(Variables_Dinamicas.Necesidades_Basicas[3]) if Variables_Dinamicas.Necesidades_Basicas.size() > 3 else 50.0
	var hambre: float = float(Variables_Dinamicas.Necesidades_Basicas[2]) if Variables_Dinamicas.Necesidades_Basicas.size() > 2 else 50.0

	var condicion_fisica: float = salud_fisica * 0.50 + descanso * 0.35 + hambre * 0.15
	var puntuacion_base: float = deporte * 0.65 + condicion_fisica * 0.35
	var puntuacion_jugador: float = clamp(randfn(puntuacion_base, 15.0), 0.0, 100.0)

	var total: int = int(Variables_Dinamicas.Carrera_Deportiva_Pendiente.get("total_inscritos", 100))
	if total < 10:
		total = 100
	var mejor_que: int = 0
	for _i in range(total - 1):
		var rival: float = clamp(randfn(50.0, 20.0), 0.0, 100.0)
		if puntuacion_jugador > rival:
			mejor_que += 1

	var puesto: int = total - mejor_que
	Variables_Dinamicas.Carrera_Deportiva_Pendiente["resultado_puesto"] = puesto


func Aplicar_Premio_Y_Notificar() -> void:
	var pendiente: Dictionary = Variables_Dinamicas.Carrera_Deportiva_Pendiente
	var puesto: int = int(pendiente.get("resultado_puesto", 99))
	var total: int = int(pendiente.get("total_inscritos", 100))

	var mult: float = Variables_Estaticas.Multiplicador_Precios()
	var costo: float = Obtener_Costo_Inscripcion()
	var premio: float = round(_Calcular_Premio(puesto) * mult)
	var bonus_min: int = _Calcular_Bonus_Minutos(puesto)

	Variables_Dinamicas.Dinero += premio
	if bonus_min > 0:
		_Aplicar_Bonus_Correr(bonus_min)

	var msg := Mensaje.new()
	msg.titulo = "Carrera completada"
	msg.descripcion = "Has quedado %dº de %d participantes.\n" % [puesto, total]
	if premio > costo:
		msg.descripcion += "Premio: +%.0f€ (neto +%.0f€).\n" % [premio, premio - costo]
	elif is_equal_approx(premio, costo):
		msg.descripcion += "Recuperas la inscripción (%.0f€). Sin ganancias.\n" % costo
	else:
		msg.descripcion += "Sin premio. Pierdes los %.0f€ de inscripción.\n" % costo
	if bonus_min > 0:
		msg.descripcion += "Bonus Deporte: equivalente a %d min corriendo." % bonus_min
	msg.leido = false
	msg.minuto = Variables_Dinamicas.Minute_Day * 1440 + Variables_Dinamicas.Minute_Minute
	Variables_Dinamicas.Mensajes.append(msg)

	pendiente["resultado_procesado"] = true
	pendiente["inscrito"] = false
	Guardar_Variables_Dinamicas.save_game()


func _Calcular_Premio(puesto: int) -> float:
	if puesto == 1:
		return 550.0
	elif puesto == 2:
		return 350.0
	elif puesto == 3:
		return 250.0
	elif puesto <= 10:
		var t: float = float(puesto - 4) / 6.0
		return lerp(200.0, 130.0, t)
	elif puesto <= 20:
		var t: float = float(puesto - 11) / 9.0
		return lerp(80.0, 60.0, t)
	elif puesto <= 50:
		return 50.0
	else:
		return 0.0


func _Calcular_Bonus_Minutos(puesto: int) -> int:
	if puesto == 1:
		return 200
	elif puesto == 2:
		return 150
	elif puesto == 3:
		return 100
	elif puesto <= 10:
		return 80
	elif puesto <= 20:
		return 50
	elif puesto <= 50:
		return 20
	else:
		return 0


func _Aplicar_Bonus_Correr(minutos: int) -> void:
	for _i in range(minutos):
		Actividades_Habilidades.Ejecutar_Actividad_Progreso_Array([4, 0, 0])


func Calcular_Inscritos_Visibles() -> int:
	var total: int = int(Variables_Dinamicas.Carrera_Deportiva_Pendiente.get("total_inscritos", 0))
	if total <= 0:
		total = int(clamp(randfn(100.0, 15.0), 60.0, 140.0))
		Variables_Dinamicas.Carrera_Deportiva_Pendiente["total_inscritos"] = total
	var dia_semana: int = Variables_Dinamicas.Minute_Day % 7
	var factor := {0: 0.10, 1: 0.25, 2: 0.45, 3: 0.70, 4: 0.90, 5: 1.0, 6: 1.0}
	return int(total * factor.get(dia_semana, 1.0))
