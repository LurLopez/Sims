extends AcceptDialog

signal tupper_elegido(indice: int)
signal tuppers_cambiados()

var _lista: VBoxContainer
var _sin_tuppers: Label


func _ready() -> void:
	title = "Despensa de tuppers"
	min_size = Vector2(640, 850)
	ok_button_text = "Cerrar"
	_Construir_UI()
	Estilos_UI.estilizar_dialogo(self)
	Estilos_UI.aplicar_estilo_boton(get_ok_button(), "secundario")
	get_ok_button().custom_minimum_size = Vector2(128, 44)
	_Refrescar()
	# El párrafo con autowrap reporta un alto mínimo enorme antes de tener ancho;
	# fijamos el tamaño tras el popup para que el botón Cerrar siga visible.
	Estilos_UI.fijar_tamano_dialogo.call_deferred(self, Vector2i(640, 850))


func _Construir_UI() -> void:
	var margen := MarginContainer.new()
	margen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margen.add_theme_constant_override("margin_left", 8)
	margen.add_theme_constant_override("margin_right", 8)
	margen.add_theme_constant_override("margin_top", 4)
	margen.add_theme_constant_override("margin_bottom", 8)
	add_child(margen)

	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.custom_minimum_size = Vector2(560, 620)
	v.add_theme_constant_override("separation", 10)
	margen.add_child(v)

	v.add_child(Estilos_UI.parrafo(
		"Elige la ración que quieres comer. Un tupper completo aporta 30 minutos de comida; al agotarse se pasa al siguiente y, si no queda ninguno, el bloque continúa como comida rápida.",
		13, Estilos_UI.TINTA_SUAVE))

	var btn_auto := Estilos_UI.boton("Usar el más próximo a caducar (automático)",
		"secundario", "sparkles", Estilos_UI.PRIMARIO, 42)
	btn_auto.set_meta("_estilo_propio", true)
	btn_auto.pressed.connect(_Seleccionar_Automatico)
	v.add_child(btn_auto)

	_sin_tuppers = Estilos_UI.parrafo("No hay tuppers en la nevera. Cocina para preparar raciones.", 14,
		Estilos_UI.TINTA_SUAVE)
	_sin_tuppers.visible = false
	v.add_child(_sin_tuppers)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, 500)
	v.add_child(scroll)

	_lista = VBoxContainer.new()
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lista.add_theme_constant_override("separation", 8)
	scroll.add_child(_lista)


func Refrescar() -> void:
	_Refrescar()


func _Refrescar() -> void:
	if _lista == null:
		return
	for hijo in _lista.get_children():
		_lista.remove_child(hijo)
		hijo.queue_free()

	var hay: bool = not Variables_Dinamicas.Tuppers.is_empty()
	if _sin_tuppers != null:
		_sin_tuppers.visible = not hay
	if not hay:
		return

	for i in range(Variables_Dinamicas.Tuppers.size()):
		var tupper = Variables_Dinamicas.Tuppers[i]
		if not (tupper is Dictionary):
			continue
		var seleccionado: bool = int(Variables_Dinamicas.Tupper_Seleccionado_Idx) == i
		var fila := Tupper_UI.crear_fila(i, tupper, seleccionado,
			_Elegir.bind(i), _Tirar.bind(i))
		_lista.add_child(fila)


func _Elegir(indice: int) -> void:
	if indice < 0 or indice >= Variables_Dinamicas.Tuppers.size():
		return
	Variables_Dinamicas.Tupper_Seleccionado_Idx = indice
	tupper_elegido.emit(indice)
	hide()


func _Seleccionar_Automatico() -> void:
	Variables_Dinamicas.Tupper_Seleccionado_Idx = -1
	tupper_elegido.emit(-1)
	hide()


func _Tirar(indice: int) -> void:
	if indice < 0 or indice >= Variables_Dinamicas.Tuppers.size():
		return
	Variables_Dinamicas.Tuppers.remove_at(indice)
	var seleccionado: int = int(Variables_Dinamicas.Tupper_Seleccionado_Idx)
	if seleccionado == indice:
		Variables_Dinamicas.Tupper_Seleccionado_Idx = -1
	elif seleccionado > indice:
		Variables_Dinamicas.Tupper_Seleccionado_Idx = seleccionado - 1
	tuppers_cambiados.emit()
	_Refrescar()
