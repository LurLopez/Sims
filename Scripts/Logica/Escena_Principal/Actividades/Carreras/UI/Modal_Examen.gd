extends AcceptDialog

const PREGUNTAS_PATH_BASE: String = "res://Scripts/Logica/Escena_Principal/Actividades/Carreras/Contenido/preguntas_%s.json"

var preguntas_seleccionadas: Array = []
var respuestas_seleccionadas: Array = []
var grupos_botones: Array = []
var carrera: Carrera = null

signal examen_enviado(nota_real: int)


func _ready():
	title = "Examen"
	min_size = Vector2(640, 880)
	ok_button_text = "Enviar respuestas"
	get_ok_button().pressed.connect(_on_enviar_pressed)
	Estilos_UI.estilizar_dialogo(self)
	Estilos_UI.aplicar_estilo_boton(get_ok_button(), "primario")
	get_ok_button().custom_minimum_size = Vector2(180, 46)


func Configurar(_carrera: Carrera):
	carrera = _carrera
	title = "Examen %s · Año %d de %d" % [carrera.nombre.replace("_", " "), carrera.año_actual, carrera.años_totales]

	if not _Verificar_Horario_Correcto():
		push_error("No es la hora del examen")
		queue_free()
		return

	_Cargar_Preguntas()
	_Construir_UI()
	Estilos_UI.estilizar_dialogo(self)


func _Verificar_Horario_Correcto() -> bool:
	if carrera.hora_examen_dia < 0:
		return false

	var minuto_del_dia = Variables_Dinamicas.Minute_Minute
	var es_dia_examen: bool
	if Variables_Estaticas.Modo_Rapido:
		es_dia_examen = (Variables_Dinamicas.Minute_Day == carrera.hora_examen_dia)
	else:
		var dia_semana_actual = Variables_Dinamicas.Minute_Day % 7
		es_dia_examen = (dia_semana_actual == carrera.hora_examen_dia)

	if not es_dia_examen:
		return false

	var hora_inicio = carrera.hora_examen_inicio
	var hora_fin = hora_inicio + 60

	return minuto_del_dia >= hora_inicio and minuto_del_dia < hora_fin


func _Cargar_Preguntas():
	var ruta = PREGUNTAS_PATH_BASE % carrera.slug_contenido
	var contenido = FileAccess.get_file_as_string(ruta)
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
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(vbox)

	grupos_botones.clear()
	for i in range(preguntas_seleccionadas.size()):
		var pregunta = preguntas_seleccionadas[i]
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel",
			Estilos_UI.caja(Estilos_UI.SUPERFICIE_2, 12, Estilos_UI.BORDE, 1, 0))
		vbox.add_child(card)

		var m := MarginContainer.new()
		m.add_theme_constant_override("margin_left", 14)
		m.add_theme_constant_override("margin_right", 14)
		m.add_theme_constant_override("margin_top", 12)
		m.add_theme_constant_override("margin_bottom", 12)
		card.add_child(m)

		var contenedor_pregunta = VBoxContainer.new()
		contenedor_pregunta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		contenedor_pregunta.add_theme_constant_override("separation", 6)
		m.add_child(contenedor_pregunta)

		var label = Estilos_UI.texto("%d. %s" % [i + 1, pregunta["pregunta"]], 15, Estilos_UI.TINTA, 700)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		contenedor_pregunta.add_child(label)

		var grupo = ButtonGroup.new()
		grupos_botones.append(grupo)
		for j in range(pregunta["opciones"].size()):
			var opcion: String = pregunta["opciones"][j]
			var radio = CheckBox.new()
			radio.text = "%s) %s" % [["A", "B", "C", "D"][j], opcion]
			radio.button_group = grupo
			radio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			radio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			radio.add_theme_font_override("font", Estilos_UI.fuente_ui(400))
			radio.add_theme_font_size_override("font_size", 14)
			radio.add_theme_color_override("font_color", Estilos_UI.TINTA_SUAVE)
			radio.add_theme_color_override("font_hover_color", Estilos_UI.TINTA)
			radio.add_theme_color_override("font_pressed_color", Estilos_UI.PRIMARIO)
			radio.add_theme_color_override("font_hover_pressed_color", Estilos_UI.PRIMARIO)
			radio.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
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

	_Mostrar_Resultado(nota_real, correctas, preguntas_seleccionadas.size())
	examen_enviado.emit(nota_real)


func _Mostrar_Resultado(nota: int, correctas: int, total: int):
	for hijo in get_children():
		if hijo is VBoxContainer or hijo is ScrollContainer:
			hijo.queue_free()

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(vbox)

	var aprobado := nota >= 50
	var badge := Estilos_UI.pill_estado(
		"Aprobado" if aprobado else "Suspendido",
		Estilos_UI.EXITO_SUAVE if aprobado else Estilos_UI.PELIGRO_SUAVE,
		Estilos_UI.EXITO if aprobado else Estilos_UI.PELIGRO)
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(badge)

	var titulo = Estilos_UI.titulo("Resultado del examen", 24, Estilos_UI.TINTA)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(titulo)

	var nota_label = Estilos_UI.titulo("%d / 100" % nota, 42, Estilos_UI.EXITO if aprobado else Estilos_UI.PELIGRO)
	nota_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(nota_label)

	var correctas_label = Estilos_UI.texto("Respuestas correctas: %d de %d" % [correctas, total], 16, Estilos_UI.TINTA_SUAVE, 500)
	correctas_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(correctas_label)

	ok_button_text = "Cerrar"
	if get_ok_button().pressed.is_connected(_on_enviar_pressed):
		get_ok_button().pressed.disconnect(_on_enviar_pressed)
	get_ok_button().pressed.connect(func(): queue_free())
