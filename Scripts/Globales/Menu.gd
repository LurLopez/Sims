extends Node2D


func _ready():
	Guardar_Variables_Estaticas.load_game()
	Guardar_Variables_Dinamicas.load_game()

	if Variables_Dinamicas.Muerto:
		_Mostrar_Game_Over()


func _Mostrar_Game_Over():
	var layer = CanvasLayer.new()
	add_child(layer)

	var fondo = ColorRect.new()
	fondo.color = Color(0.06, 0.04, 0.08, 1.0)
	fondo.position = Vector2.ZERO
	fondo.size = Vector2(720, 1280)
	layer.add_child(fondo)

	var scroll = ScrollContainer.new()
	scroll.position = Vector2.ZERO
	scroll.size = Vector2(720, 1280)
	layer.add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(720, 0)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 28)
	scroll.add_child(vbox)

	_Spacer(vbox, 80)
	_Label(vbox, "HAS MUERTO", 64, Color(0.9, 0.15, 0.15))
	_Label(vbox, "A los %d años" % Variables_Dinamicas.Edad_Muerte, 40, Color(0.85, 0.85, 0.85))

	_Separador(vbox)

	_Label(vbox, "PROGRESO FINAL", 30, Color(0.65, 0.65, 1.0))
	var nombres_prog = ["Deporte", "Académico", "Manualidades"]
	for i in range(3):
		_Label(vbox, "%s: %d/100" % [nombres_prog[i], Variables_Dinamicas.Progreso[i]], 28, Color(0.8, 0.8, 0.8))

	_Label(vbox, "Dinero: %d€" % int(Variables_Dinamicas.Dinero), 28, Color(1.0, 0.88, 0.25))

	if Variables_Dinamicas.Carreras_Completadas.size() > 0:
		_Separador(vbox)
		_Label(vbox, "CARRERAS COMPLETADAS", 30, Color(0.65, 0.65, 1.0))
		for c in Variables_Dinamicas.Carreras_Completadas:
			_Label(vbox, c.nombre.replace("_", " "), 28, Color(0.4, 1.0, 0.55))
	elif Variables_Dinamicas.Carrera_Actual != null and Variables_Dinamicas.Carrera_Actual.año_actual > 1:
		_Separador(vbox)
		_Label(vbox, "CARRERA SIN TERMINAR", 30, Color(0.65, 0.65, 1.0))
		var c = Variables_Dinamicas.Carrera_Actual
		_Label(vbox, "%s\nAño %d de %d" % [c.nombre.replace("_", " "), c.año_actual - 1, c.años_totales], 26, Color(0.75, 0.75, 0.6))


func _Label(parent: Node, texto: String, tam: int, color: Color) -> void:
	var lbl = Label.new()
	lbl.text = texto
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", tam)
	lbl.add_theme_color_override("font_color", color)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(lbl)


func _Separador(parent: Node) -> void:
	var sep = HSeparator.new()
	sep.add_theme_color_override("color", Color(0.35, 0.35, 0.45))
	parent.add_child(sep)


func _Spacer(parent: Node, altura: int) -> void:
	var s = Control.new()
	s.custom_minimum_size = Vector2(0, altura)
	parent.add_child(s)
