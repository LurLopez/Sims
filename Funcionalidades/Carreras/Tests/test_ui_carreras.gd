extends GutTest

# Pruebas de humo de la interfaz de Carreras y Exámenes.
# Comprueban que los modales se construyen, responden a los toques y emiten
# las mismas señales que consumía la lógica anterior.

const RUTA_SELECTOR := "res://Scripts/Logica/Escena_Principal/Actividades/Carreras/UI/Modal_Seleccionar_Carrera.gd"
const RUTA_HORARIO := "res://Scripts/Logica/Escena_Principal/Actividades/Carreras/UI/Modal_Seleccionar_Examen.gd"
const RUTA_EXAMEN := "res://Scripts/Logica/Escena_Principal/Actividades/Carreras/UI/Modal_Examen.gd"
const RUTA_APUNTES := "res://Scripts/Logica/Escena_Principal/Actividades/Carreras/UI/Lector_Libros.gd"

var _modo_rapido_previo := false
var _minute_day_previo := 0
var _minute_minute_previo := 0
var _completadas_previas: Array = []


func before_each() -> void:
	_modo_rapido_previo = Variables_Estaticas.Modo_Rapido
	_minute_day_previo = Variables_Dinamicas.Minute_Day
	_minute_minute_previo = Variables_Dinamicas.Minute_Minute
	_completadas_previas = Variables_Dinamicas.Carreras_Completadas
	Variables_Estaticas.Modo_Rapido = false
	Variables_Dinamicas.Minute_Day = 4
	Variables_Dinamicas.Minute_Minute = 15 * 60 + 5
	Variables_Dinamicas.Carreras_Completadas = []


func after_each() -> void:
	Variables_Estaticas.Modo_Rapido = _modo_rapido_previo
	Variables_Dinamicas.Minute_Day = _minute_day_previo
	Variables_Dinamicas.Minute_Minute = _minute_minute_previo
	Variables_Dinamicas.Carreras_Completadas = _completadas_previas


func test_selector_de_carrera_emite_la_titulacion_elegida() -> void:
	var modal = load(RUTA_SELECTOR).new()
	add_child_autofree(modal)
	await wait_process_frames(2)
	watch_signals(modal)

	var tarjeta: Button = null
	for boton in modal.find_children("*", "Button", true, false):
		if boton is Button and boton.custom_minimum_size.y >= 80.0:
			tarjeta = boton
			break
	assert_not_null(tarjeta, "Debe existir al menos una tarjeta de carrera")
	if tarjeta == null:
		return
	tarjeta.pressed.emit()
	assert_signal_emitted_with_parameters(modal, "carrera_elegida",
		["res://Scripts/Logica/Escena_Principal/Actividades/Carreras/Carrera_Ingenieria_Informatica.gd"])
	await _Limpiar_Modal(modal)


func test_horario_emite_dia_y_hora_seleccionados() -> void:
	var modal = load(RUTA_HORARIO).new()
	add_child_autofree(modal)
	await wait_process_frames(2)
	var carrera := Carrera_Bellas_Artes.new()
	modal.Configurar(carrera, false)
	await wait_process_frames(2)
	watch_signals(modal)

	var boton_dia: Button = modal._fila_dias.get_child(0)
	assert_not_null(boton_dia, "Debe existir el botón del primer día")
	if boton_dia == null:
		return
	boton_dia.pressed.emit()
	await wait_process_frames(2)

	var boton_hora: Button = null
	for fila in modal._contenedor_horas.get_children():
		for hijo in fila.get_children():
			if hijo is Button and hijo.get_meta("hora", -1) == 9:
				boton_hora = hijo
				break
		if boton_hora != null:
			break
	assert_not_null(boton_hora, "Debe existir la franja de las 09:00")
	if boton_hora == null:
		return
	boton_hora.pressed.emit()
	modal._btn_confirmar.pressed.emit()

	assert_signal_emitted_with_parameters(modal, "examen_programado", [2, 9 * 60])
	assert_eq(modal.indice_dia, 0)
	assert_eq(modal.hora_seleccionada, 9)
	await _Limpiar_Modal(modal)


func test_examen_envia_la_nota_del_test() -> void:
	var carrera := Carrera_Bellas_Artes.new()
	carrera.año_actual = 1
	carrera.hora_examen_dia = 4
	carrera.hora_examen_inicio = 15 * 60
	var modal = load(RUTA_EXAMEN).new()
	add_child_autofree(modal)
	await wait_process_frames(2)
	modal.Configurar(carrera)
	await wait_process_frames(2)
	watch_signals(modal)

	assert_gt(modal.preguntas_seleccionadas.size(), 0, "Debe cargar preguntas del año 1")
	for i in range(modal.respuestas_seleccionadas.size()):
		modal.respuestas_seleccionadas[i] = int(modal.preguntas_seleccionadas[i]["respuesta_correcta"])
	modal._Al_Pulsar_Enviar()

	assert_signal_emitted_with_parameters(modal, "examen_enviado", [100])
	assert_eq(carrera.nota_real_ultima, 100)
	assert_true(carrera.examen_realizado_esta_semana)
	await _Limpiar_Modal(modal)


func test_apuntes_muestra_el_temario_y_cambia_de_anio() -> void:
	var carrera := Carrera_Bellas_Artes.new()
	carrera.año_actual = 2
	carrera.libros_desbloqueados = ["Anio_1", "Anio_2"]
	var modal = load(RUTA_APUNTES).new()
	add_child_autofree(modal)
	await wait_process_frames(2)
	modal.Configurar(carrera)
	await wait_process_frames(2)

	assert_eq(modal._chips_anio.get_child_count(), 2, "Debe mostrar un chip por año desbloqueado")
	assert_eq(modal._titulo_tema, "Técnicas de Pintura", "Debe cargar el temario del Año 2")
	var chip_anio_1: Button = modal._chips_anio.get_child(0)
	chip_anio_1.pressed.emit()
	await wait_process_frames(2)
	assert_eq(modal.año_actual_lectura, 1)
	assert_eq(modal._titulo_tema, "Color y Dibujo", "Debe cargar el temario del Año 1")
	await _Limpiar_Modal(modal)


func _Limpiar_Modal(modal: Node) -> void:
	if is_instance_valid(modal):
		modal.queue_free()
	await wait_process_frames(2)
