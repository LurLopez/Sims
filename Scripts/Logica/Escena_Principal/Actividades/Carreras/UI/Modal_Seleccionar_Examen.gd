extends AcceptDialog

const DIAS_EXAMEN = [2, 3, 4]
const NOMBRES_DIAS_EXAMEN = ["Miércoles", "Jueves", "Viernes"]
const HORA_MIN = 8
const HORA_MAX = 18

var indice_dia: int = 2
var hora_seleccionada: int = 15
var _dias_opciones: Array = DIAS_EXAMEN
var _nombres_opciones: Array = NOMBRES_DIAS_EXAMEN

var dia_display_label: Label = null
var hora_display_label: Label = null
var resumen_label: Label = null

signal examen_programado(dia: int, hora: int)


func _ready():
	if Variables_Estaticas.Modo_Rapido:
		var hoy: int = int(Variables_Dinamicas.Minute_Day)
		var hora_actual: int = int(Variables_Dinamicas.Minute_Minute / 60)
		if hora_actual < HORA_MAX - 1:
			_dias_opciones = [hoy, hoy + 1]
			_nombres_opciones = ["Hoy", "Mañana"]
			indice_dia = 0
			hora_seleccionada = maxi(HORA_MIN, hora_actual + 1)
		else:
			_dias_opciones = [hoy + 1]
			_nombres_opciones = ["Mañana"]
			indice_dia = 0
			hora_seleccionada = 15
	else:
		_dias_opciones = DIAS_EXAMEN
		_nombres_opciones = NOMBRES_DIAS_EXAMEN
		indice_dia = 2
		hora_seleccionada = 15
	title = "Programar examen"
	min_size = Vector2(600, 520)
	ok_button_text = "Confirmar horario"
	get_ok_button().pressed.connect(_on_confirmar_pressed)
	var cancel := add_cancel_button("Cancelar")
	cancel.pressed.connect(queue_free)
	_Construir_UI()
	Estilos_UI.estilizar_dialogo(self)
	# Evita que el autowrap del texto infle el alto inicial del diálogo y
	# empuje los botones fuera de la pantalla.
	Estilos_UI.fijar_tamano_dialogo.call_deferred(self, Vector2i(600, 520))


func _Construir_UI():
	var margen := MarginContainer.new()
	margen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margen.add_theme_constant_override("margin_left", 8)
	margen.add_theme_constant_override("margin_right", 8)
	margen.add_theme_constant_override("margin_top", 8)
	margen.add_theme_constant_override("margin_bottom", 8)
	add_child(margen)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margen.add_child(vbox)

	var texto_inst := "Elige si hacer el examen hoy o mañana (de 08:00 a 18:00)." if Variables_Estaticas.Modo_Rapido else "Elige el día y la hora de inicio para tu examen (Miércoles a Viernes, de 08:00 a 18:00)."
	var instrucciones = Estilos_UI.parrafo(texto_inst, 14, Estilos_UI.TINTA_SUAVE)
	vbox.add_child(instrucciones)

	# Selector de día
	var card_dia := _Crear_Selector_Fila("Día del examen", _nombres_opciones[indice_dia],
		_on_dia_anterior_pressed, _on_dia_siguiente_pressed, true)
	vbox.add_child(card_dia)

	# Selector de hora
	var card_hora := _Crear_Selector_Fila("Hora de inicio", "%02d:00" % hora_seleccionada,
		_on_hora_anterior_pressed, _on_hora_siguiente_pressed, false)
	vbox.add_child(card_hora)

	var resumen_panel := PanelContainer.new()
	resumen_panel.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Estilos_UI.PRIMARIO_SUAVE, 12, Color(0, 0, 0, 0), 0, 0))
	var rm := MarginContainer.new()
	rm.add_theme_constant_override("margin_left", 14)
	rm.add_theme_constant_override("margin_right", 14)
	rm.add_theme_constant_override("margin_top", 12)
	rm.add_theme_constant_override("margin_bottom", 12)
	resumen_panel.add_child(rm)

	resumen_label = Estilos_UI.texto(_Texto_Resumen(), 14, Estilos_UI.PRIMARIO_OSCURO, 600)
	resumen_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	resumen_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rm.add_child(resumen_label)
	vbox.add_child(resumen_panel)


func _Crear_Selector_Fila(titulo_txt: String, valor_inicial: String,
		cb_ant: Callable, cb_sig: Callable, es_dia: bool) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Estilos_UI.SUPERFICIE_2, 12, Estilos_UI.BORDE, 1, 0))

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 14)
	m.add_theme_constant_override("margin_right", 14)
	m.add_theme_constant_override("margin_top", 10)
	m.add_theme_constant_override("margin_bottom", 10)
	card.add_child(m)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	m.add_child(v)

	v.add_child(Estilos_UI.texto(titulo_txt, 12, Estilos_UI.TINTA_FANTASMA, 700))

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	v.add_child(h)

	var btn_ant := Estilos_UI.boton_icono("chevron-left", Estilos_UI.TINTA, 44)
	btn_ant.set_meta("_estilo_propio", true)
	btn_ant.pressed.connect(cb_ant)
	h.add_child(btn_ant)

	var lbl := Estilos_UI.texto(valor_inicial, 18, Estilos_UI.TINTA, 700)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(lbl)

	if es_dia:
		dia_display_label = lbl
	else:
		hora_display_label = lbl

	var btn_sig := Estilos_UI.boton_icono("chevron-right", Estilos_UI.TINTA, 44)
	btn_sig.set_meta("_estilo_propio", true)
	btn_sig.pressed.connect(cb_sig)
	h.add_child(btn_sig)

	return card


func _on_dia_anterior_pressed():
	indice_dia = (indice_dia - 1 + _dias_opciones.size()) % _dias_opciones.size()
	_Actualizar_Display()


func _on_dia_siguiente_pressed():
	indice_dia = (indice_dia + 1) % _dias_opciones.size()
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
	return "Tu examen será %s de %02d:00 a %02d:00" % [
		_nombres_opciones[indice_dia], hora_seleccionada, hora_seleccionada + 1]


func _Actualizar_Display():
	if dia_display_label != null:
		dia_display_label.text = _nombres_opciones[indice_dia]
	if hora_display_label != null:
		hora_display_label.text = "%02d:00" % hora_seleccionada
	if resumen_label != null:
		resumen_label.text = _Texto_Resumen()


func _on_confirmar_pressed():
	examen_programado.emit(_dias_opciones[indice_dia], hora_seleccionada * 60)
	queue_free()
