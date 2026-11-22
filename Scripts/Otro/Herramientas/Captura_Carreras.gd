extends Node

# Captura de QA visual del bloque de Carreras y Exámenes.
# No forma parte del juego ni se ejecuta en producción.
#
# Uso:
#   godot --headless --path . res://Escenas/Herramientas/Captura_Carreras.tscn

const DIR_SALIDA := "user://capturas_carreras"
const RUTA_SAVE_DIN_TMP := "user://captura_carreras_din.dat"
const RUTA_SAVE_EST_TMP := "user://captura_carreras_est.dat"

var _vp: SubViewport
var _escena: Node


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR_SALIDA))
	await get_tree().process_frame
	_Preparar_Estado_Estatico()
	await _Preparar_Escena()
	_Preparar_Carrera_Falsa()
	await _Capturar_Pantalla_Carrera()
	await _Capturar_Pantalla_Sin_Carrera()
	await _Capturar_Pantalla_Con_Titulos()
	await _Capturar_Selector_Carrera()
	await _Capturar_Horario()
	await _Capturar_Apuntes()
	await _Capturar_Examen()
	await _Capturar_Resultado()
	await _Capturar_Resultado_Suspendido()
	await _Capturar_Resultado_Completado()
	print("Capturas de carreras guardadas en ", ProjectSettings.globalize_path(DIR_SALIDA))
	_Limpiar_Saves_Temporales()
	get_tree().quit()


func _Limpiar_Saves_Temporales() -> void:
	for ruta in [RUTA_SAVE_DIN_TMP, RUTA_SAVE_EST_TMP, RUTA_SAVE_DIN_TMP + ".bak", RUTA_SAVE_EST_TMP + ".bak"]:
		if FileAccess.file_exists(ruta):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))


func _Preparar_Estado_Estatico() -> void:
	Variables_Estaticas.Tutorial_Completado = true
	Variables_Estaticas.Modo_Rapido = false


func _Preparar_Carrera_Falsa() -> void:
	Variables_Dinamicas.Minute_Day = 4
	Variables_Dinamicas.Minute_Minute = 15 * 60 + 5
	Variables_Dinamicas.Dinero = 1250
	Variables_Dinamicas.Carreras_Completadas = []

	var carrera := Carrera_Bellas_Artes.new()
	carrera.año_actual = 2
	carrera.progreso_actual = 64.0
	carrera.libros_desbloqueados = ["Anio_1", "Anio_2"]
	carrera.historial_notas = [
		{"año": 1, "nota_final": 74.5, "aprobado": true, "nota_real_jugador": 80},
	]
	carrera.matriculado = true
	carrera.hora_examen_dia = 4
	carrera.hora_examen_inicio = 15 * 60
	Variables_Dinamicas.Carrera_Actual = carrera


func _Preparar_Escena() -> void:
	# Aísla los guardados: esta herramienta de QA nunca debe escribir sobre la
	# partida real del jugador al instanciar la escena principal.
	Guardar_Variables_Dinamicas.save_path = RUTA_SAVE_DIN_TMP
	Guardar_Variables_Estaticas.save_path = RUTA_SAVE_EST_TMP
	_vp = SubViewport.new()
	_vp.size = Vector2i(720, 1280)
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)
	_vp.add_child(load("res://Escenas/Escena_Principal/Escena principal.tscn").instantiate())
	_escena = _vp.get_child(0)
	await get_tree().process_frame
	await get_tree().process_frame
	_escena.set_process(false)
	_escena.set_process_unhandled_input(false)
	var tutorial: Node = _escena.get_node_or_null("Tutorial_Inicial")
	if tutorial != null:
		tutorial.queue_free()
		await get_tree().process_frame


func _Capturar_Pantalla_Carrera() -> void:
	_escena._on_carrera_tab_pressed()
	await _Esperar(0.45)
	await _Guardar("01_pantalla_carrera.png")


func _Capturar_Pantalla_Sin_Carrera() -> void:
	var carrera_guardada = Variables_Dinamicas.Carrera_Actual
	Variables_Dinamicas.Carrera_Actual = null
	_escena._Actualizar_Pantalla_Carrera()
	await _Esperar(0.25)
	await _Guardar("01b_pantalla_sin_carrera.png")
	Variables_Dinamicas.Carrera_Actual = carrera_guardada
	_escena._Actualizar_Pantalla_Carrera()
	await _Esperar(0.15)


func _Capturar_Pantalla_Con_Titulos() -> void:
	var carrera_guardada = Variables_Dinamicas.Carrera_Actual
	var completadas_guardadas = Variables_Dinamicas.Carreras_Completadas
	var derecho = Carrera_Derecho.new()
	derecho.completada = true
	derecho.año_actual = derecho.años_totales + 1
	derecho.historial_notas = [
		{"año": 1, "nota_final": 68.2, "aprobado": true},
		{"año": 2, "nota_final": 74.1, "aprobado": true},
		{"año": 3, "nota_final": 81.5, "aprobado": true},
		{"año": 4, "nota_final": 79.8, "aprobado": true},
	]
	Variables_Dinamicas.Carrera_Actual = null
	Variables_Dinamicas.Carreras_Completadas = [derecho]
	_escena._Actualizar_Pantalla_Carrera()
	await _Esperar(0.25)
	await _Guardar("01c_pantalla_con_titulos.png")
	Variables_Dinamicas.Carrera_Actual = carrera_guardada
	Variables_Dinamicas.Carreras_Completadas = completadas_guardadas
	_escena._Actualizar_Pantalla_Carrera()
	await _Esperar(0.15)


func _Capturar_Selector_Carrera() -> void:
	var completadas_guardadas = Variables_Dinamicas.Carreras_Completadas
	var derecho = Carrera_Derecho.new()
	derecho.completada = true
	Variables_Dinamicas.Carreras_Completadas = [derecho]
	_escena._Abrir_Modal_Seleccionar_Carrera()
	await _Esperar(0.45)
	await _Guardar("02_selector_carrera.png")
	_Cerrar_Modal_Actual()
	Variables_Dinamicas.Carreras_Completadas = completadas_guardadas


func _Capturar_Horario() -> void:
	var carrera: Carrera = Variables_Dinamicas.Carrera_Actual
	_escena._Abrir_Modal_Horario(carrera, false)
	await _Esperar(0.45)
	await _Guardar("03_programar_examen.png")
	_Cerrar_Modal_Actual()


func _Capturar_Apuntes() -> void:
	var carrera: Carrera = Variables_Dinamicas.Carrera_Actual
	_escena._on_libros_button_pressed()
	await _Esperar(0.5)
	await _Guardar("04_apuntes_anio_2.png")
	var modal := _Modal_Actual()
	if modal != null and modal.has_method("_Mostrar_Año"):
		modal._Mostrar_Año(1)
		await _Esperar(0.35)
		await _Guardar("04b_apuntes_anio_1.png")
	_Cerrar_Modal_Actual()


func _Capturar_Examen() -> void:
	var carrera: Carrera = Variables_Dinamicas.Carrera_Actual
	_escena._Abrir_Modal_Examen(carrera)
	await _Esperar(0.55)
	await _Guardar("05_examen.png")

	var modal := _Modal_Actual()
	if modal != null and "_opciones_preguntas" in modal:
		for i in range(mini(3, modal._opciones_preguntas.size())):
			var refs: Array = modal._opciones_preguntas[i]
			if not refs.is_empty():
				refs[1]["btn"].button_pressed = true
		await _Esperar(0.35)
		await _Guardar("05b_examen_respondido.png")
		if modal.has_method("_Solicitar_Cierre"):
			modal._Solicitar_Cierre()
			await _Esperar(0.35)
			await _Guardar("05c_confirmar_salida.png")
			if "_confirmacion" in modal and modal._confirmacion != null:
				modal._Cerrar_Confirmacion()
		if modal.has_method("_Al_Pulsar_Enviar"):
			modal._Al_Pulsar_Enviar()
			await _Esperar(0.35)
			await _Guardar("05d_aviso_respuestas.png")
		if modal.has_method("_Mostrar_Resultado"):
			modal._Mostrar_Resultado(70, 7, 10)
			await _Esperar(0.45)
			await _Guardar("06_resultado_test.png")
	_Cerrar_Modal_Actual()


func _Capturar_Resultado() -> void:
	var carrera: Carrera = Variables_Dinamicas.Carrera_Actual
	carrera.fin_de_semana_procesado = true
	carrera.ultimo_resultado_aprobado = true
	carrera.ultima_nota_final = 78.4
	_escena._Mostrar_Resultado_Examen(carrera)
	await _Esperar(0.5)
	await _Guardar("07_resultado_examen.png")
	_Cerrar_Modal_Actual()
	await _Esperar(0.2)


func _Capturar_Resultado_Suspendido() -> void:
	var carrera: Carrera = Variables_Dinamicas.Carrera_Actual
	carrera.completada = false
	carrera.año_actual = 2
	carrera.fin_de_semana_procesado = true
	carrera.ultimo_resultado_aprobado = false
	carrera.ultima_nota_final = 42.3
	_escena._Mostrar_Resultado_Examen(carrera)
	await _Esperar(0.5)
	await _Guardar("07b_resultado_suspendido.png")
	_Cerrar_Modal_Actual()
	await _Esperar(0.2)


func _Capturar_Resultado_Completado() -> void:
	var carrera: Carrera = Variables_Dinamicas.Carrera_Actual
	carrera.completada = true
	carrera.año_actual = carrera.años_totales + 1
	carrera.fin_de_semana_procesado = true
	carrera.ultimo_resultado_aprobado = true
	carrera.ultima_nota_final = 91.2
	carrera.historial_notas.append({
		"año": carrera.años_totales,
		"nota_final": 91.2,
		"aprobado": true,
		"nota_real_jugador": 80,
	})
	_escena._Mostrar_Resultado_Examen(carrera)
	await _Esperar(0.5)
	await _Guardar("08_resultado_carrera_completada.png")


func _Modal_Actual() -> Node:
	for i in range(_escena.get_child_count() - 1, -1, -1):
		var hijo: Node = _escena.get_child(i)
		if hijo is Window:
			return hijo
		if hijo is CanvasLayer and hijo.has_method("cerrar"):
			return hijo
	return null


func _Cerrar_Modal_Actual() -> void:
	var modal := _Modal_Actual()
	if modal != null:
		modal.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame


func _Esperar(segundos: float) -> void:
	await get_tree().create_timer(segundos).timeout


func _Guardar(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	var imagen := _vp.get_texture().get_image()
	if imagen == null or imagen.is_empty():
		push_error("No se pudo capturar %s" % nombre)
		return
	var ruta := DIR_SALIDA.path_join(nombre)
	var error := imagen.save_png(ruta)
	if error != OK:
		push_error("Error %d guardando %s" % [error, ruta])
	else:
		print("Captura: ", ruta)
