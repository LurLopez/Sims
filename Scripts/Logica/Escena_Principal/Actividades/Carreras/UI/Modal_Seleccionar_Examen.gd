extends AcceptDialog

# Solo exámenes en Miércoles (2), Jueves (3) o Viernes (4)
const DIAS_EXAMEN = [2, 3, 4]
const NOMBRES_DIAS_EXAMEN = ["Miércoles", "Jueves", "Viernes"]
const HORA_MIN = 8   # 8 AM
const HORA_MAX = 18  # 6 PM (18:00)

var indice_dia: int = 2  # Viernes por defecto (índice dentro de DIAS_EXAMEN)
var hora_seleccionada: int = 15  # 3 PM por defecto

var dia_display_label: Label = null
var hora_display_label: Label = null
var resumen_label: Label = null

signal examen_programado(dia: int, hora: int)

func _ready():
	title = "Programar Examen"
	min_size = Vector2(600, 500)
	_Construir_UI()

func _Construir_UI():
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)

	var instrucciones = Label.new()
	instrucciones.text = "Elige un día y hora para hacer tu examen.\nSolo disponible: Miércoles, Jueves o Viernes (8:00–18:00)"
	instrucciones.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instrucciones.add_theme_font_size_override("font_size", 14)
	vbox.add_child(instrucciones)

	# Selector de día
	var dia_label = Label.new()
	dia_label.text = "Día:"
	dia_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(dia_label)

	var dia_hbox = HBoxContainer.new()
	dia_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(dia_hbox)

	var boton_dia_anterior = Button.new()
	boton_dia_anterior.text = "◀"
	boton_dia_anterior.custom_minimum_size = Vector2(50, 40)
	boton_dia_anterior.pressed.connect(_on_dia_anterior_pressed)
	dia_hbox.add_child(boton_dia_anterior)

	dia_display_label = Label.new()
	dia_display_label.text = NOMBRES_DIAS_EXAMEN[indice_dia]
	dia_display_label.add_theme_font_size_override("font_size", 20)
	dia_display_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dia_display_label.custom_minimum_size = Vector2(200, 40)
	dia_hbox.add_child(dia_display_label)

	var boton_dia_siguiente = Button.new()
	boton_dia_siguiente.text = "▶"
	boton_dia_siguiente.custom_minimum_size = Vector2(50, 40)
	boton_dia_siguiente.pressed.connect(_on_dia_siguiente_pressed)
	dia_hbox.add_child(boton_dia_siguiente)

	# Selector de hora
	var hora_label = Label.new()
	hora_label.text = "Hora (inicio):"
	hora_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(hora_label)

	var hora_hbox = HBoxContainer.new()
	hora_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(hora_hbox)

	var boton_hora_anterior = Button.new()
	boton_hora_anterior.text = "◀"
	boton_hora_anterior.custom_minimum_size = Vector2(50, 40)
	boton_hora_anterior.pressed.connect(_on_hora_anterior_pressed)
	hora_hbox.add_child(boton_hora_anterior)

	hora_display_label = Label.new()
	hora_display_label.text = "%02d:00" % hora_seleccionada
	hora_display_label.add_theme_font_size_override("font_size", 20)
	hora_display_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hora_display_label.custom_minimum_size = Vector2(200, 40)
	hora_hbox.add_child(hora_display_label)

	var boton_hora_siguiente = Button.new()
	boton_hora_siguiente.text = "▶"
	boton_hora_siguiente.custom_minimum_size = Vector2(50, 40)
	boton_hora_siguiente.pressed.connect(_on_hora_siguiente_pressed)
	hora_hbox.add_child(boton_hora_siguiente)

	resumen_label = Label.new()
	resumen_label.text = _Texto_Resumen()
	resumen_label.add_theme_font_size_override("font_size", 14)
	resumen_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(resumen_label)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)

	var hbox_botones = HBoxContainer.new()
	hbox_botones.add_theme_constant_override("separation", 10)
	hbox_botones.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox_botones)

	var boton_confirmar = Button.new()
	boton_confirmar.text = "Confirmar Horario"
	boton_confirmar.custom_minimum_size = Vector2(150, 40)
	boton_confirmar.pressed.connect(_on_confirmar_pressed)
	hbox_botones.add_child(boton_confirmar)

	var boton_cancelar = Button.new()
	boton_cancelar.text = "Cancelar"
	boton_cancelar.custom_minimum_size = Vector2(150, 40)
	boton_cancelar.pressed.connect(queue_free)
	hbox_botones.add_child(boton_cancelar)

func _on_dia_anterior_pressed():
	indice_dia = (indice_dia - 1 + DIAS_EXAMEN.size()) % DIAS_EXAMEN.size()
	_Actualizar_Display()

func _on_dia_siguiente_pressed():
	indice_dia = (indice_dia + 1) % DIAS_EXAMEN.size()
	_Actualizar_Display()

func _on_hora_anterior_pressed():
	if hora_seleccionada > HORA_MIN:
		hora_seleccionada -= 1
	_Actualizar_Display()

func _on_hora_siguiente_pressed():
	if hora_seleccionada < HORA_MAX - 1:
		hora_seleccionada += 1
	_Actualizar_Display()

func _Texto_Resumen() -> String:
	return "Tu examen será el %s a las %02d:00–%02d:00" % [NOMBRES_DIAS_EXAMEN[indice_dia], hora_seleccionada, hora_seleccionada + 1]

func _Actualizar_Display():
	if dia_display_label != null:
		dia_display_label.text = NOMBRES_DIAS_EXAMEN[indice_dia]
	if hora_display_label != null:
		hora_display_label.text = "%02d:00" % hora_seleccionada
	if resumen_label != null:
		resumen_label.text = _Texto_Resumen()

func _on_confirmar_pressed():
	examen_programado.emit(DIAS_EXAMEN[indice_dia], hora_seleccionada * 60)
	queue_free()
