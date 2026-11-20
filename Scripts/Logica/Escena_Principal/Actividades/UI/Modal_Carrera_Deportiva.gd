extends AcceptDialog

signal inscripcion_confirmada(dia: int, hora_inicio: int)

var _dia_seleccionado: int = 5
var _hora_seleccionada: int = 540  # 09:00
var _btn_sabado: Button
var _btn_domingo: Button
var _option_hora: OptionButton


func _ready() -> void:
	title = "Inscripción — Carrera deportiva"
	min_size = Vector2(600, 480)
	ok_button_text = "Inscribirse"
	var cancel := add_cancel_button("Cancelar")
	cancel.pressed.connect(queue_free)
	_Construir_UI()
	Estilos_UI.estilizar_dialogo(self)
	Estilos_UI.aplicar_estilo_boton(get_ok_button(), "primario")
	get_ok_button().custom_minimum_size = Vector2(140, 44)
	confirmed.connect(_on_confirmed)
	canceled.connect(queue_free)
	close_requested.connect(queue_free)

	var costo: float = get_node("/root/Sistema_Carreras_Deportivas").Obtener_Costo_Inscripcion()
	if Variables_Dinamicas.Dinero < costo:
		get_ok_button().disabled = true
	# El texto con autowrap aún no tiene ancho cuando Godot calcula el tamaño
	# inicial del diálogo y reporta una altura enorme; fijamos un tamaño tras el
	# popup para que los botones OK/Cancelar queden siempre dentro de la pantalla.
	Estilos_UI.fijar_tamano_dialogo.call_deferred(self, Vector2i(600, 480))


func _Construir_UI() -> void:
	var margen := MarginContainer.new()
	margen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margen.add_theme_constant_override("margin_left", 10)
	margen.add_theme_constant_override("margin_right", 10)
	margen.add_theme_constant_override("margin_top", 8)
	margen.add_theme_constant_override("margin_bottom", 8)
	add_child(margen)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 14)
	margen.add_child(vbox)

	var sys = get_node("/root/Sistema_Carreras_Deportivas")
	var inscritos: int = sys.Calcular_Inscritos_Visibles()
	var costo: int = int(sys.Obtener_Costo_Inscripcion())

	var info := Estilos_UI.parrafo(
		"Compite en la carrera popular del fin de semana (1 hora). Cuanto mayor sea tu Deporte y mejor tu estado físico al inicio, mejor puesto lograrás.",
		13, Estilos_UI.TINTA_SUAVE)
	vbox.add_child(info)

	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 10)
	vbox.add_child(stats_row)
	stats_row.add_child(Estilos_UI.pill_estado("Inscritos actuales: %d" % inscritos, Estilos_UI.AZUL_SUAVE, Estilos_UI.AZUL))
	stats_row.add_child(Estilos_UI.pill_estado("Coste: %d€" % costo,
		Estilos_UI.EXITO_SUAVE if Variables_Dinamicas.Dinero >= costo else Estilos_UI.PELIGRO_SUAVE,
		Estilos_UI.EXITO if Variables_Dinamicas.Dinero >= costo else Estilos_UI.PELIGRO))

	var lbl_dia := Estilos_UI.texto("Día de la carrera", 14, Estilos_UI.TINTA, 700)
	vbox.add_child(lbl_dia)

	var dias_row := HBoxContainer.new()
	dias_row.add_theme_constant_override("separation", 10)
	vbox.add_child(dias_row)

	_btn_sabado = Button.new()
	_btn_sabado.text = "Sábado"
	_btn_sabado.custom_minimum_size = Vector2(0, 44)
	_btn_sabado.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_sabado.pressed.connect(_Seleccionar_Dia.bind(5))
	dias_row.add_child(_btn_sabado)

	_btn_domingo = Button.new()
	_btn_domingo.text = "Domingo"
	_btn_domingo.custom_minimum_size = Vector2(0, 44)
	_btn_domingo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_domingo.pressed.connect(_Seleccionar_Dia.bind(6))
	dias_row.add_child(_btn_domingo)

	var lbl_hora := Estilos_UI.texto("Hora de salida (07:00 – 17:00)", 14, Estilos_UI.TINTA, 700)
	vbox.add_child(lbl_hora)

	_option_hora = OptionButton.new()
	_option_hora.custom_minimum_size = Vector2(0, 44)
	var idx := 0
	var def_idx := 0
	for m in range(420, 1021, 30):
		var h: int = m / 60
		var mm: int = m % 60
		_option_hora.add_item("%02d:%02d" % [h, mm], m)
		if m == _hora_seleccionada:
			def_idx = idx
		idx += 1
	_option_hora.select(def_idx)
	vbox.add_child(_option_hora)

	_Actualizar_Botones_Dia()


func _Seleccionar_Dia(dia: int) -> void:
	_dia_seleccionado = dia
	_Actualizar_Botones_Dia()


func _Actualizar_Botones_Dia() -> void:
	Estilos_UI.aplicar_estilo_boton(_btn_sabado, "primario" if _dia_seleccionado == 5 else "secundario")
	Estilos_UI.aplicar_estilo_boton(_btn_domingo, "primario" if _dia_seleccionado == 6 else "secundario")


func _on_confirmed() -> void:
	var sel_idx: int = _option_hora.selected
	var hora_min: int = _option_hora.get_item_id(sel_idx) if sel_idx >= 0 else 540
	inscripcion_confirmada.emit(_dia_seleccionado, hora_min)
	queue_free()
