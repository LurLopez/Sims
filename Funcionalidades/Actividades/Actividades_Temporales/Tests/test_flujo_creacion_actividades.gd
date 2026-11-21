extends GutTest

# Tests del orden del flujo de creación de actividades:
# 1) se elige la actividad en el catálogo,
# 2) se abre el selector de horario con una franja propuesta (o la del calendario),
# 3) se confirma y se escribe en la matriz.

const RUTA_ESTUDIAR := "Actividades/Elegir_Actividad/Tipos_De_Actividades/Temporales_Opciones/Progreso_Opciones/Estudiar"
const RUTA_SELECTOR := "Actividades/Seleccionar_Horario"
const RUTA_SAVE_DINAMICAS := "user://test_flujo_creacion_dinamicas.dat"
const RUTA_SAVE_ESTATICAS := "user://test_flujo_creacion_estaticas.dat"

var _save_dinamicas_original := ""
var _save_estaticas_original := ""


func before_all():
	_Inicializar_Matriz()


func before_each():
	_save_dinamicas_original = Guardar_Variables_Dinamicas.save_path
	_save_estaticas_original = Guardar_Variables_Estaticas.save_path
	Guardar_Variables_Dinamicas.save_path = RUTA_SAVE_DINAMICAS
	Guardar_Variables_Estaticas.save_path = RUTA_SAVE_ESTATICAS
	Variables_Dinamicas.Minute_Day = 10
	Variables_Dinamicas.Minute_Minute = 600
	Variables_Dinamicas.Minute = 10 * 1440 + 600
	_Limpiar_Celdas()


func after_each():
	Guardar_Variables_Dinamicas.save_path = _save_dinamicas_original
	Guardar_Variables_Estaticas.save_path = _save_estaticas_original
	for ruta in [RUTA_SAVE_DINAMICAS, RUTA_SAVE_ESTATICAS]:
		if FileAccess.file_exists(ruta):
			DirAccess.remove_absolute(ruta)


func _Inicializar_Matriz() -> void:
	if Variables_Dinamicas.Matriz_Jugador.size() == 1440:
		return
	Variables_Dinamicas.Matriz_Jugador = []
	for i in range(1440):
		var fila: Array = []
		fila.resize(574)
		fila.fill("")
		Variables_Dinamicas.Matriz_Jugador.append(fila)


func _Limpiar_Celdas() -> void:
	for fila in range(1440):
		for columna in range(7, 15):
			Variables_Dinamicas.Matriz_Jugador[fila][columna] = ""


func _Crear_Raiz():
	var raiz = load("res://Escenas/Escena_Principal/Escena principal.tscn").instantiate()
	add_child_autofree(raiz)
	# La escena ejecuta su _ready al entrar en el árbol y puede recargar el estado
	# guardado: fijamos el reloj de prueba después de añadirla.
	Variables_Dinamicas.Minute_Day = 10
	Variables_Dinamicas.Minute_Minute = 600
	Variables_Dinamicas.Minute = 10 * 1440 + 600
	raiz.mirar_semana = 1
	raiz.Inicializar_Otros_Scripts()
	raiz._Redisenar_Actividades()
	raiz._Redisenar_Horario()
	raiz._Redisenar_Seleccionar_Horario()
	return raiz


func _Liberar_Auxiliares(raiz) -> void:
	if raiz.horario_bloque != null and is_instance_valid(raiz.horario_bloque):
		raiz.horario_bloque.free()
		raiz.horario_bloque = null
	if raiz.actividades_reloj_gui != null:
		raiz.actividades_reloj_gui.horariobloque = null
		if is_instance_valid(raiz.actividades_reloj_gui.horario):
			raiz.actividades_reloj_gui.horario.free()
		raiz.actividades_reloj_gui.free()
	if raiz.actividades_bloque_gui != null:
		if is_instance_valid(raiz.actividades_bloque_gui.bloque_columna):
			raiz.actividades_bloque_gui.bloque_columna.free()
		raiz.actividades_bloque_gui.free()
	if raiz.necesidades_basicas_gui != null:
		raiz.necesidades_basicas_gui.free()
	if raiz.first_time_logica != null:
		raiz.first_time_logica.free()


func test_elegir_actividad_abre_selector_y_crea_bloque() -> void:
	var raiz = _Crear_Raiz()
	raiz._on_boton_actividades_pressed()
	assert_true(raiz.get_node("Actividades/Elegir_Actividad").visible,
		"El catálogo debe mostrarse al entrar en Actividades")

	var boton = raiz.get_node_or_null(RUTA_ESTUDIAR)
	assert_not_null(boton)
	boton.pressed.emit()

	assert_eq(raiz.actividad_seleccionada, "Estudiar")
	assert_true(raiz.get_node(RUTA_SELECTOR).visible, "Tras elegir la actividad se abre el horario")
	assert_false(raiz.get_node("Actividades/Elegir_Actividad").visible)
	assert_not_null(raiz.horario_bloque, "Debe proponerse una franja horaria")

	var horario = raiz.actividades_reloj_gui.horario
	assert_eq(horario.hora_inicio_texto.text, "10", "La franja propuesta empieza a la hora actual")
	assert_eq(horario.minuto_inicio_texto.text, "00")
	assert_eq(horario.hora_final_texto.text, "12", "Estudiar propone 2 horas")

	# La sugerencia es solo el punto de partida: el selector permite ampliar
	# el bloque a cualquier franja libre de la semana.
	raiz.Final_Hora_Arriba()
	raiz.Final_Hora_Arriba()
	assert_eq(horario.hora_final_texto.text, "14", "Se puede ampliar más allá de la duración sugerida")

	raiz._on_crear_actividad_pressed()

	# Semana 1, día 3 (jueves) → columna 10. La actividad final dura 4 horas.
	var act = Variables_Dinamicas.Matriz_Jugador[600][10]
	assert_true(act is Actividad)
	assert_eq(act.nombre, "Estudiar")
	assert_eq(Variables_Dinamicas.Matriz_Jugador[719][10].nombre, "Estudiar")
	assert_eq(Variables_Dinamicas.Matriz_Jugador[839][10].nombre, "Estudiar")
	assert_eq(raiz.actividad_seleccionada, "")
	assert_true(raiz.get_node("Actividades/Elegir_Actividad").visible,
		"Al crear se vuelve al catálogo de actividades")
	assert_false(raiz.get_node(RUTA_SELECTOR).visible)
	_Liberar_Auxiliares(raiz)


func test_cancelar_selector_vuelve_al_submenu_de_origen() -> void:
	var raiz = _Crear_Raiz()
	raiz._on_boton_actividades_pressed()
	raiz.get_node("Actividades/Elegir_Actividad/Tipos_De_Actividades/Temporales").pressed.emit()
	raiz.get_node("Actividades/Elegir_Actividad/Tipos_De_Actividades/Temporales_Opciones/Progreso").pressed.emit()
	raiz.get_node(RUTA_ESTUDIAR).pressed.emit()

	assert_true(raiz.get_node(RUTA_SELECTOR).visible)
	raiz._on_cancelar_pressed()

	assert_eq(raiz.actividad_seleccionada, "")
	assert_eq(Gestionar_Visibilidad.raiz_path,
		"Actividades/Elegir_Actividad/Tipos_De_Actividades/Temporales_Opciones/Progreso_Opciones")
	assert_true(raiz.get_node("Actividades/Elegir_Actividad").visible)
	assert_false(raiz.get_node(RUTA_SELECTOR).visible)
	assert_true(raiz.get_node(RUTA_ESTUDIAR).visible,
		"Debe volver al submenú exacto donde se eligió la actividad")
	_Liberar_Auxiliares(raiz)


func test_bloque_del_calendario_se_usa_como_franja_propuesta() -> void:
	var raiz = _Crear_Raiz()
	var bloque = HorarioDesdeBloque.new()
	bloque.Inicializar("Lunes", 16, 0, "Lunes", 17, 30)
	raiz.horario_bloque = bloque

	raiz._Mostrar_Catalogo_Actividades()
	raiz.get_node(RUTA_ESTUDIAR).pressed.emit()

	var horario = raiz.actividades_reloj_gui.horario
	assert_eq(horario.dia_inicio_texto.text, "L")
	assert_eq(horario.hora_inicio_texto.text, "16")
	assert_eq(horario.minuto_inicio_texto.text, "00")
	assert_eq(horario.hora_final_texto.text, "17")
	assert_eq(horario.minuto_final_texto.text, "30")

	# El bloque del calendario es una sugerencia: también se puede ampliar.
	raiz.Final_Hora_Arriba()
	assert_eq(horario.hora_final_texto.text, "18")
	assert_eq(horario.minuto_final_texto.text, "30")
	_Liberar_Auxiliares(raiz)
