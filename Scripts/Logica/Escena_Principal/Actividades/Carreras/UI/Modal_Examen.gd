extends AcceptDialog

const PREGUNTAS_PATH: String = "res://Scripts/Logica/Escena_Principal/Actividades/Carreras/Contenido/preguntas_ing_informatica.json"

var preguntas_seleccionadas: Array = []
var respuestas_seleccionadas: Array = []
var grupos_botones: Array = []
var carrera: Carrera = null

signal examen_enviado(nota_real: int)

func _ready():
	title = "Examen"
	min_size = Vector2(640, 880)
	ok_button_text = "Enviar Respuestas"
	get_ok_button().pressed.connect(_on_enviar_pressed)

func Configurar(_carrera: Carrera):
	carrera = _carrera
	title = "Examen %s - Año %d de %d" % [carrera.nombre, carrera.año_actual, carrera.años_totales]

	# Verificar horario
	if not _Verificar_Horario_Correcto():
		push_error("No es la hora del examen")
		queue_free()
		return

	_Cargar_Preguntas()
	_Construir_UI()

func _Verificar_Horario_Correcto() -> bool:
	if carrera.hora_examen_dia < 0:
		return false

	var dia_semana_actual = Variables_Dinamicas.Minute_Day % 7
	var minuto_del_dia = Variables_Dinamicas.Minute_Minute

	if dia_semana_actual != carrera.hora_examen_dia:
		return false

	var hora_inicio = carrera.hora_examen_inicio
	var hora_fin = hora_inicio + 60

	return minuto_del_dia >= hora_inicio and minuto_del_dia < hora_fin

func _Cargar_Preguntas():
	var contenido = FileAccess.get_file_as_string(PREGUNTAS_PATH)
	if contenido == "":
		push_error("No se pudo leer el JSON de preguntas")
		return
	var json = JSON.new()
	var error = json.parse(contenido)
	if error != OK:
		push_error("Error al parsear JSON: %s" % json.get_error_message())
		return
	var datos = json.data
	var clave = "Anio_%d" % carrera.año_actual
	if not datos.has(clave):
		push_error("No hay preguntas para %s" % clave)
		return
	var todas = datos[clave].duplicate()
	todas.shuffle()
	preguntas_seleccionadas = todas.slice(0, min(10, todas.size()))
	respuestas_seleccionadas.resize(preguntas_seleccionadas.size())
	for i in range(respuestas_seleccionadas.size()):
		respuestas_seleccionadas[i] = -1

func _Construir_UI():
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(600, 700)
	add_child(scroll)
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 16)
	scroll.add_child(vbox)
	grupos_botones.clear()
	for i in range(preguntas_seleccionadas.size()):
		var pregunta = preguntas_seleccionadas[i]
		var contenedor_pregunta = VBoxContainer.new()
		contenedor_pregunta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_child(contenedor_pregunta)
		var label = Label.new()
		label.text = "%d. %s" % [i + 1, pregunta["pregunta"]]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 16)
		contenedor_pregunta.add_child(label)
		var grupo = ButtonGroup.new()
		grupos_botones.append(grupo)
		for j in range(pregunta["opciones"].size()):
			var opcion: String = pregunta["opciones"][j]
			var radio = CheckBox.new()
			radio.text = "%s) %s" % [["A", "B", "C", "D"][j], opcion]
			radio.button_group = grupo
			radio.set_meta("pregunta_idx", i)
			radio.set_meta("opcion_idx", j)
			radio.toggled.connect(_on_opcion_toggled.bind(i, j))
			contenedor_pregunta.add_child(radio)

func _on_opcion_toggled(presionado: bool, pregunta_idx: int, opcion_idx: int):
	if presionado:
		respuestas_seleccionadas[pregunta_idx] = opcion_idx

func _on_enviar_pressed():
	var correctas = 0
	for i in range(preguntas_seleccionadas.size()):
		var correcta = preguntas_seleccionadas[i]["respuesta_correcta"]
		if respuestas_seleccionadas[i] == correcta:
			correctas += 1
	var nota_real = int(round(correctas * 100.0 / preguntas_seleccionadas.size()))
	if carrera != null:
		carrera.nota_real_ultima = nota_real
		carrera.examen_realizado_esta_semana = true

	# Mostrar resultado antes de cerrar
	_Mostrar_Resultado(nota_real, correctas, preguntas_seleccionadas.size())
	examen_enviado.emit(nota_real)

func _Mostrar_Resultado(nota: int, correctas: int, total: int):
	# Limpiar UI anterior
	for hijo in get_children():
		if hijo is VBoxContainer or hijo is ScrollContainer:
			hijo.queue_free()

	# Crear panel de resultado
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(vbox)

	# Título
	var titulo = Label.new()
	titulo.text = "Resultado del Examen"
	titulo.add_theme_font_size_override("font_size", 24)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(titulo)

	# Nota
	var nota_label = Label.new()
	nota_label.text = "Nota: %d/100" % nota
	nota_label.add_theme_font_size_override("font_size", 40)
	nota_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(nota_label)

	# Respuestas correctas
	var correctas_label = Label.new()
	correctas_label.text = "Respuestas correctas: %d/%d" % [correctas, total]
	correctas_label.add_theme_font_size_override("font_size", 18)
	correctas_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(correctas_label)

	# Estado (aprobado/suspendido)
	var estado_label = Label.new()
	if nota >= 50:
		estado_label.text = "✓ APROBADO"
		estado_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		estado_label.text = "✗ SUSPENDIDO"
		estado_label.add_theme_color_override("font_color", Color.RED)
	estado_label.add_theme_font_size_override("font_size", 28)
	estado_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(estado_label)

	# Espaciador
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Cambiar botón OK a "Cerrar"
	ok_button_text = "Cerrar"
	get_ok_button().pressed.disconnect(_on_enviar_pressed)
	get_ok_button().pressed.connect(func(): queue_free())
