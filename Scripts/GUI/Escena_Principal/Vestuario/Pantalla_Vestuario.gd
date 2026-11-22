class_name Pantalla_Vestuario
extends Control
## Vestuario: pantalla dedicada para probar y equipar los atuendos del Sim.
##
## Sustituye a la antigua pestaña "Ropa" dentro de Apuntes. Muestra una vista
## previa animada del personaje con la prenda seleccionada, sus bonificaciones
## y una colección de tarjetas (con candado para las aún bloqueadas). Al
## equipar, el atuendo se refleja en el escenario de Inicio, el avatar, el
## perfil y el logo.

signal cerrado
signal atuendo_equipado(clave: String)
signal atuendo_comprado(clave: String)

const ANCHO_TARJETA := 196.0
const ALTO_TARJETA := 166.0
const SEPARACION_TARJETAS := 10.0
const ALTO_NAV_INFERIOR := 96.0
const ALTO_BARRA_EQUIPAR := 112.0
const ALTO_BARRA_INFERIOR := ALTO_NAV_INFERIOR + ALTO_BARRA_EQUIPAR
## Tono oscuro del oro para texto sobre fondos claros (mejor contraste).
const ORO_LEGIBLE := Color("#92400e")

var _construido: bool = false
var _apariencia_base: Dictionary = Apariencia_Personaje.por_defecto()
var _clave_equipada: String = "Ropa_Calle"
var _clave_seleccionada: String = "Ropa_Calle"
var _filtro_actual: String = "todo"

var _preview: Personaje_Visual = null
var _card_preview: PanelContainer = null
var _lbl_nombre: Label = null
var _lbl_efecto: Label = null
var _lbl_categoria: Label = null
var _lbl_desbloqueo: Label = null
var _pill_estado: PanelContainer = null
var _chips: HFlowContainer = null
var _scroll: ScrollContainer = null
var _card_maestria: PanelContainer = null
var _lbl_maestria_rango: Label = null
var _lbl_maestria_detalle: Label = null
var _lbl_maestria_texto: Label = null
var _barra_maestria: ProgressBar = null
var _hbox: HBoxContainer = null
var _lbl_cuenta: Label = null
var _lbl_saldo: Label = null
var _btn_equipar: Button = null
var _cards: Dictionary = {}
var _botones_filtro: Dictionary = {}


func _ready() -> void:
	_Construir()
	_Ajustar_Tamano()
	var vp := get_viewport()
	if vp != null and not vp.size_changed.is_connected(_Ajustar_Tamano):
		vp.size_changed.connect(_Ajustar_Tamano)


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and _preview != null and is_instance_valid(_preview):
		_preview.animar_idle = visible


func _exit_tree() -> void:
	var vp := get_viewport()
	if vp != null and vp.size_changed.is_connected(_Ajustar_Tamano):
		vp.size_changed.disconnect(_Ajustar_Tamano)


func _Ajustar_Tamano() -> void:
	var alto := 1280.0
	var vp := get_viewport()
	if vp != null:
		alto = maxf(1280.0, vp.get_visible_rect().size.y)
	position = Vector2.ZERO
	size = Vector2(720.0, alto)
	if _card_preview != null and is_instance_valid(_card_preview):
		_card_preview.custom_minimum_size.y = clampf(alto * 0.34, 390.0, 470.0)


func _Construir() -> void:
	if _construido:
		return
	_construido = true
	# La pantalla ocupa todo el alto, pero no debe tragarse los clics de la
	# barra superior (Perfil, Economía, Horario…): en Godot el picking de GUI
	# usa el orden del árbol, no el z_index, así que un Control STOP añadido
	# después de las pestañas las deja sin respuesta. Los hijos interactivos
	# (tarjetas, filtros y botones) siguen recibiendo sus propios clics.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false

	var fondo := ColorRect.new()
	fondo.name = "Fondo_Vestuario"
	fondo.color = Estilos_UI.FONDO
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)

	Estilos_UI.Crear_Label_Titulo_Panel("Vestuario", self, Estilos_UI.TINTA)
	var subtitulo := Estilos_UI.texto("Prueba tu look, compra prendas y gana otras con Maestría Culinaria", 13,
		Estilos_UI.TINTA_SUAVE, 500)
	subtitulo.name = "Subtitulo_Vestuario"
	subtitulo.set_anchors_preset(Control.PRESET_TOP_WIDE)
	subtitulo.offset_left = 74
	subtitulo.offset_right = -20
	subtitulo.offset_top = 160
	subtitulo.offset_bottom = 184
	subtitulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(subtitulo)

	var volver := Estilos_UI.boton_icono("arrow-left", Estilos_UI.TINTA, 42)
	volver.name = "Boton_Volver_Vestuario"
	volver.position = Vector2(20, 128)
	volver.size = Vector2(42, 42)
	volver.tooltip_text = "Volver"
	volver.pressed.connect(_on_volver_pressed)
	add_child(volver)

	add_child(_Crear_Saldo())

	var contenido := MarginContainer.new()
	contenido.name = "Contenido_Vestuario"
	contenido.set_anchors_preset(Control.PRESET_FULL_RECT)
	contenido.offset_left = 20
	contenido.offset_top = 196
	contenido.offset_right = -20
	contenido.offset_bottom = -ALTO_BARRA_INFERIOR
	add_child(contenido)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	contenido.add_child(col)

	col.add_child(_Crear_Tarjeta_Preview())
	col.add_child(_Crear_Cabecera_Coleccion())
	col.add_child(_Crear_Filtros())

	_scroll = ScrollContainer.new()
	_scroll.name = "Scroll_Atuendos"
	_scroll.custom_minimum_size = Vector2(0, ALTO_TARJETA + 12.0)
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(_scroll)

	_hbox = HBoxContainer.new()
	_hbox.name = "HBox_Atuendos"
	_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hbox.add_theme_constant_override("separation", int(SEPARACION_TARJETAS))
	_scroll.add_child(_hbox)

	col.add_child(_Crear_Tarjeta_Maestria())

	var relleno := Control.new()
	relleno.size_flags_vertical = Control.SIZE_EXPAND_FILL
	relleno.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(relleno)

	_Crear_Barra_Equipar()
	_Reconstruir_Carrusel()


func _Crear_Tarjeta_Preview() -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "Card_Preview"
	card.custom_minimum_size = Vector2(0, 440)
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	card.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Estilos_UI.SUPERFICIE, 18, Estilos_UI.BORDE, 1, 2))
	_card_preview = card

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 0)
	card.add_child(h)

	var escenario := Control.new()
	escenario.name = "Escenario_Preview"
	escenario.custom_minimum_size = Vector2(284, 0)
	escenario.size_flags_vertical = Control.SIZE_EXPAND_FILL
	escenario.clip_contents = true
	h.add_child(escenario)

	var fondo_stage := _FondoVestuario.new()
	fondo_stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	escenario.add_child(fondo_stage)

	_preview = Personaje_Visual.new(_apariencia_base, "cuerpo_completo")
	_preview.name = "Preview_Personaje"
	_preview.set_anchors_preset(Control.PRESET_FULL_RECT)
	_preview.offset_left = 6
	_preview.offset_top = 4
	_preview.offset_right = -6
	_preview.offset_bottom = -4
	_preview.animar_idle = visible
	_preview.expresion = "sonrisa"
	_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	escenario.add_child(_preview)

	var etiqueta := Estilos_UI.pill_estado("VISTA PREVIA", Color(1, 1, 1, 0.88), Estilos_UI.TINTA_SUAVE)
	etiqueta.position = Vector2(12, 12)
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	escenario.add_child(etiqueta)

	var separador := ColorRect.new()
	separador.color = Estilos_UI.BORDE
	separador.custom_minimum_size = Vector2(1, 0)
	separador.size_flags_vertical = Control.SIZE_EXPAND_FILL
	separador.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(separador)

	var margen := MarginContainer.new()
	margen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margen.add_theme_constant_override("margin_left", 20)
	margen.add_theme_constant_override("margin_right", 18)
	margen.add_theme_constant_override("margin_top", 18)
	margen.add_theme_constant_override("margin_bottom", 16)
	h.add_child(margen)

	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 9)
	margen.add_child(info)

	_lbl_categoria = Estilos_UI.texto("ATUENDO SELECCIONADO", 10, Estilos_UI.TINTA_FANTASMA, 700)
	info.add_child(_lbl_categoria)

	_lbl_nombre = Estilos_UI.titulo("Ropa de Calle", 22, Estilos_UI.TINTA)
	_lbl_nombre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_nombre.custom_minimum_size = Vector2(0, 32)
	info.add_child(_lbl_nombre)

	_pill_estado = Estilos_UI.pill_estado("EQUIPADO", Estilos_UI.EXITO_SUAVE, Estilos_UI.EXITO)
	_pill_estado.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	info.add_child(_pill_estado)

	_lbl_efecto = Estilos_UI.parrafo("", 13, Estilos_UI.TINTA_SUAVE)
	_lbl_efecto.custom_minimum_size = Vector2(0, 42)
	info.add_child(_lbl_efecto)

	_chips = HFlowContainer.new()
	_chips.name = "Chips_Bonificaciones"
	_chips.add_theme_constant_override("h_separation", 6)
	_chips.add_theme_constant_override("v_separation", 6)
	info.add_child(_chips)

	_lbl_desbloqueo = Estilos_UI.texto("", 11, Estilos_UI.TINTA_FANTASMA, 600)
	_lbl_desbloqueo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(_lbl_desbloqueo)

	var espaciador := Control.new()
	espaciador.size_flags_vertical = Control.SIZE_EXPAND_FILL
	espaciador.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(espaciador)

	return card


func _Crear_Cabecera_Coleccion() -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)

	var titulo := Estilos_UI.titulo("Tus atuendos", 17, Estilos_UI.TINTA)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(titulo)

	_lbl_cuenta = Estilos_UI.texto("0/0", 12, Estilos_UI.TINTA_FANTASMA, 600)
	_lbl_cuenta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(_lbl_cuenta)

	var izq := Estilos_UI.boton_icono("chevron-left", Estilos_UI.TINTA, 40)
	izq.name = "Boton_Carrusel_Izquierda"
	izq.tooltip_text = "Ver atuendos anteriores"
	izq.pressed.connect(_Desplazar_Carrusel.bind(-1))
	fila.add_child(izq)

	var der := Estilos_UI.boton_icono("chevron-right", Estilos_UI.TINTA, 40)
	der.name = "Boton_Carrusel_Derecha"
	der.tooltip_text = "Ver más atuendos"
	der.pressed.connect(_Desplazar_Carrusel.bind(1))
	fila.add_child(der)

	return fila


func _Crear_Tarjeta_Maestria() -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "Card_Maestria_Cocina"
	card.custom_minimum_size = Vector2(0, 108)
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Color("#fffbeb"), 14, Color(Estilos_UI.ORO, 0.34), 1, 0))
	card.visible = false
	_card_maestria = card

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 14)
	m.add_theme_constant_override("margin_right", 14)
	m.add_theme_constant_override("margin_top", 12)
	m.add_theme_constant_override("margin_bottom", 12)
	card.add_child(m)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	m.add_child(h)
	h.add_child(Estilos_UI.badge_icono("chef-hat", 38, 18, Estilos_UI.ORO, Color.WHITE, 10))

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 5)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	h.add_child(v)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	v.add_child(fila)
	var titulo := Estilos_UI.texto("MAESTRÍA CULINARIA", 10, Estilos_UI.TINTA_FANTASMA, 700)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(titulo)
	_lbl_maestria_rango = Estilos_UI.texto("", 12, ORO_LEGIBLE, 700)
	_lbl_maestria_rango.name = "Lbl_Maestria_Rango"
	_lbl_maestria_rango.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	fila.add_child(_lbl_maestria_rango)

	_barra_maestria = ProgressBar.new()
	_barra_maestria.name = "Barra_Maestria_Cocina"
	_barra_maestria.custom_minimum_size = Vector2(0, 8)
	_barra_maestria.show_percentage = false
	_barra_maestria.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_barra_maestria.add_theme_stylebox_override("background", Estilos_UI.barra_fondo())
	_barra_maestria.add_theme_stylebox_override("fill", Estilos_UI.barra_relleno(Estilos_UI.ORO))
	v.add_child(_barra_maestria)

	var pie := HBoxContainer.new()
	pie.add_theme_constant_override("separation", 8)
	v.add_child(pie)
	_lbl_maestria_detalle = Estilos_UI.texto("", 11, Estilos_UI.TINTA_SUAVE, 600)
	_lbl_maestria_detalle.name = "Lbl_Maestria_Detalle"
	pie.add_child(_lbl_maestria_detalle)
	_lbl_maestria_texto = Estilos_UI.texto(
		"Gana estrellas en el minijuego de Cocina para ascender de rango.", 11, Estilos_UI.TINTA_SUAVE, 600)
	_lbl_maestria_texto.name = "Lbl_Maestria_Texto"
	_lbl_maestria_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_maestria_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_lbl_maestria_texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pie.add_child(_lbl_maestria_texto)

	_Actualizar_Tarjeta_Maestria()
	return card


## Muestra el rango actual de Maestría Culinaria solo cuando el filtro Cocina
## está activo. El ascenso se consigue reuniendo estrellas en el minijuego.
func _Actualizar_Tarjeta_Maestria() -> void:
	if _card_maestria == null or not is_instance_valid(_card_maestria):
		return
	_card_maestria.visible = (_filtro_actual == "cocina")
	if not _card_maestria.visible:
		return
	var p := Sistema_Cocina.Obtener_Progreso_Maestria()
	var rango := int(p.get("rango", 0))
	var estrellas := int(p.get("estrellas", 0))
	var info: Dictionary = p.get("info", {})
	var maximo := bool(p.get("maximo", false))
	if _lbl_maestria_rango != null:
		_lbl_maestria_rango.text = "Rango %d/9 · %s" % [rango, str(info.get("nombre", ""))]
	if maximo:
		if _barra_maestria != null:
			_barra_maestria.value = 100.0
		if _lbl_maestria_detalle != null:
			_lbl_maestria_detalle.text = "%d / %d ★ · Rango máximo" % [
				estrellas, Sistema_Cocina.ESTRELLAS_TOTALES_MAX]
		if _lbl_maestria_texto != null:
			_lbl_maestria_texto.text = "Ya has alcanzado la Estrella Michelin."
		return
	var en_rango := int(p.get("en_rango", 0))
	var necesarios := maxi(1, int(p.get("necesario", 20)))
	if _barra_maestria != null:
		_barra_maestria.value = clampf(
			float(p.get("progreso", 0.0)) * 100.0, 0.0, 100.0)
	if _lbl_maestria_detalle != null:
		_lbl_maestria_detalle.text = "%d/%d ★ para el Rango %d · %d totales" % [
			en_rango, necesarios, rango + 1, estrellas]
	if _lbl_maestria_texto != null:
		_lbl_maestria_texto.text = "Gana estrellas en el minijuego de Cocina para ascender de rango."


func _Crear_Saldo() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "Saldo_Vestuario"
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_left = -170
	panel.offset_top = 128
	panel.offset_right = -20
	panel.offset_bottom = 168
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Estilos_UI.SUPERFICIE, 999, Estilos_UI.BORDE, 1, 0))

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 10)
	margen.add_theme_constant_override("margin_right", 12)
	margen.add_theme_constant_override("margin_top", 4)
	margen.add_theme_constant_override("margin_bottom", 4)
	margen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(margen)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margen.add_child(fila)
	fila.add_child(Estilos_UI.badge_icono("coins", 24, 13, Estilos_UI.ORO, Color.WHITE, 8))
	_lbl_saldo = Estilos_UI.texto("0 €", 14, Estilos_UI.TINTA, 700)
	_lbl_saldo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(_lbl_saldo)
	return panel


func _Crear_Filtros() -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.name = "Filtros_Vestuario"
	fila.add_theme_constant_override("separation", 6)
	for categoria in Sistema_Cocina.CATEGORIAS_ROPA:
		var id := str(categoria.get("id", "todo"))
		var btn := Button.new()
		btn.name = "Filtro_" + id
		btn.text = str(categoria.get("nombre", id))
		btn.custom_minimum_size = Vector2(0, 32)
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.add_theme_font_override("font", Estilos_UI.fuente_ui(700))
		btn.add_theme_font_size_override("font_size", 12)
		btn.pressed.connect(_Cambiar_Filtro.bind(id))
		fila.add_child(btn)
		_botones_filtro[id] = btn
	var relleno := Control.new()
	relleno.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	relleno.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(relleno)
	_Actualizar_Filtros_Estilos()
	return fila


func _Cambiar_Filtro(id: String) -> void:
	if _filtro_actual == id:
		return
	_filtro_actual = id
	var claves := _Claves_Filtradas()
	if not claves.has(_clave_seleccionada) or not _Puede_Seleccionar(_clave_seleccionada):
		var elegida := ""
		for clave in claves:
			if _Puede_Seleccionar(clave):
				elegida = clave
				break
		# Si toda la categoría está bloqueada, mostramos al menos su primera
		# prenda en la vista previa (sin permitir equiparla).
		if elegida == "" and not claves.is_empty():
			elegida = claves[0]
		if elegida != "":
			_clave_seleccionada = elegida
	_Reconstruir_Carrusel()
	_Actualizar_Filtros_Estilos()
	_Actualizar_Tarjeta_Maestria()
	_Actualizar_Preview()
	_Asegurar_Tarjeta_Visible.call_deferred(_clave_seleccionada)


func _Actualizar_Filtros_Estilos() -> void:
	for id in _botones_filtro.keys():
		var btn = _botones_filtro[id]
		if btn == null or not is_instance_valid(btn):
			continue
		_Aplicar_Estilo_Filtro(btn, str(id) == _filtro_actual)


func _Aplicar_Estilo_Filtro(btn: Button, activo: bool) -> void:
	var bg := Estilos_UI.ROJO_BIT if activo else Estilos_UI.SUPERFICIE
	var borde := Estilos_UI.ROJO_BIT if activo else Estilos_UI.BORDE
	var fg := Color.WHITE if activo else Estilos_UI.TINTA_SUAVE
	var normal := Estilos_UI.caja(bg, 999, borde, 1, 0)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 5
	normal.content_margin_bottom = 5
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = bg.darkened(0.06) if activo else Color("#f8fafc")
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Estilos_UI.ROJO_BIT.darkened(0.10)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_color_override("font_color", fg)
	btn.add_theme_color_override("font_hover_color", fg)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)


func _Crear_Barra_Equipar() -> void:
	var barra := Panel.new()
	barra.name = "Barra_Equipar"
	barra.set_meta("_tema_aplicado", true)
	barra.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	barra.offset_top = -ALTO_BARRA_INFERIOR
	barra.offset_bottom = -ALTO_NAV_INFERIOR
	var st := Estilos_UI.caja(Estilos_UI.SUPERFICIE, 0, Estilos_UI.BORDE, 0, 2)
	st.border_width_top = 2
	barra.add_theme_stylebox_override("panel", st)
	barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(barra)

	_btn_equipar = Estilos_UI.boton("Equipar atuendo", "primario", "shirt", Estilos_UI.ROJO_BIT, 56)
	_btn_equipar.name = "Boton_Equipar_Atuendo"
	_btn_equipar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_btn_equipar.offset_left = 20
	_btn_equipar.offset_right = -20
	_btn_equipar.offset_top = -(ALTO_NAV_INFERIOR + 84.0)
	_btn_equipar.offset_bottom = -(ALTO_NAV_INFERIOR + 28.0)
	_btn_equipar.add_theme_font_override("font", Estilos_UI.fuente_titulo(700))
	_btn_equipar.add_theme_font_size_override("font_size", 18)
	_btn_equipar.pressed.connect(_Accion_Principal)
	add_child(_btn_equipar)


func _Reconstruir_Carrusel() -> void:
	if _hbox == null:
		return
	Sistema_Cocina.Asegurar_Prendas_Iniciales()
	for hijo in _hbox.get_children():
		_hbox.remove_child(hijo)
		hijo.queue_free()
	_cards.clear()

	var claves := _Claves_Filtradas()
	for clave in claves:
		var poseida := bool(Variables_Dinamicas.Objetos_Poseidos.get(clave, false))
		var card := _Crear_Tarjeta_Atuendo(clave, poseida)
		_hbox.add_child(card)
		_cards[clave] = card
	_Actualizar_Cuenta()


func _Claves_Filtradas() -> Array[String]:
	var claves: Array[String] = []
	for clave in Sistema_Cocina.ORDEN_ROPA:
		var coincide := _filtro_actual == "todo" \
			or Sistema_Cocina.Obtener_Categoria_Ropa(clave) == _filtro_actual
		if _filtro_actual == "tienda":
			coincide = Sistema_Cocina.Obtener_Desbloqueo_Ropa(clave) == "tienda"
		if coincide:
			claves.append(clave)
	return claves


func _Actualizar_Cuenta() -> void:
	if _lbl_cuenta == null:
		return
	var claves := _Claves_Filtradas()
	var desbloqueados := 0
	for clave in claves:
		if bool(Variables_Dinamicas.Objetos_Poseidos.get(clave, false)):
			desbloqueados += 1
	_lbl_cuenta.text = "%d/%d en tu armario" % [desbloqueados, claves.size()]


func _Puede_Seleccionar(clave: String) -> bool:
	return bool(Variables_Dinamicas.Objetos_Poseidos.get(clave, false)) \
		or Sistema_Cocina.Es_Ropa_Comprable(clave)


func _Crear_Tarjeta_Atuendo(clave: String, poseida: bool) -> Button:
	var comprable := Sistema_Cocina.Es_Ropa_Comprable(clave)
	var btn := Button.new()
	btn.name = "Atuendo_" + clave
	btn.set_meta("_tema_aplicado", true)
	btn.custom_minimum_size = Vector2(ANCHO_TARJETA, ALTO_TARJETA)
	btn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	btn.text = ""
	btn.clip_contents = true
	btn.disabled = false
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.tooltip_text = _Tooltip_Atuendo(clave, poseida)
	btn.set_meta("clave_atuendo", clave)
	btn.set_meta("poseida", poseida)
	btn.set_meta("comprable", comprable)
	btn.pressed.connect(_Seleccionar_Atuendo.bind(clave))

	var margen := MarginContainer.new()
	margen.name = "Contenido"
	margen.set_anchors_preset(Control.PRESET_FULL_RECT)
	margen.offset_left = 10
	margen.offset_right = -10
	margen.offset_top = 10
	margen.offset_bottom = -8
	margen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(margen)

	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 4)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margen.add_child(col)

	var avatar := _Crear_Miniatura_Atuendo(clave)
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(avatar)

	var nombre := Estilos_UI.texto(Sistema_Cocina.Obtener_Nombre_Legible_Ropa(clave), 12,
		Estilos_UI.TINTA, 700)
	nombre.name = "Nombre"
	nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nombre.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nombre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nombre.max_lines_visible = 2
	nombre.custom_minimum_size = Vector2(0, 30)
	nombre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(nombre)

	var estado := Estilos_UI.texto("", 10, Estilos_UI.TINTA_SUAVE, 700)
	estado.name = "Estado"
	estado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	estado.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(estado)

	var check := Estilos_UI.badge_icono("check", 24, 13, Estilos_UI.EXITO, Color.WHITE, 8)
	check.name = "Badge_Equipado"
	check.position = Vector2(ANCHO_TARJETA - 32, 8)
	check.mouse_filter = Control.MOUSE_FILTER_IGNORE
	check.visible = (clave == _clave_equipada)
	btn.add_child(check)

	var candado := Estilos_UI.badge_icono("lock", 24, 12, Color("#64748b"), Color.WHITE, 8)
	candado.name = "Badge_Candado"
	candado.position = Vector2(ANCHO_TARJETA - 32, 8)
	candado.mouse_filter = Control.MOUSE_FILTER_IGNORE
	candado.visible = not poseida and not comprable
	btn.add_child(candado)

	if comprable:
		var precio := int(round(Sistema_Cocina.Obtener_Precio_Ropa(clave)))
		var pill := Estilos_UI.pill_estado("%d €" % precio, Estilos_UI.ORO_SUAVE, ORO_LEGIBLE)
		pill.name = "Pill_Precio"
		pill.position = Vector2(8, 8)
		pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(pill)

	_Aplicar_Estilo_Tarjeta(btn, clave, poseida)
	return btn


func _Crear_Miniatura_Atuendo(clave: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "Miniatura"
	panel.custom_minimum_size = Vector2(76, 76)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ap := Sistema_Cocina.Obtener_Apariencia_Con_Ropa(_apariencia_base, clave)
	var acento := _Color_Atuendo(clave)
	var st := Estilos_UI.caja(Color("#eef2ff"), 999, acento, 2, 2)
	st.content_margin_left = 2
	st.content_margin_right = 2
	st.content_margin_top = 2
	st.content_margin_bottom = 2
	panel.add_theme_stylebox_override("panel", st)

	var mascara := Panel.new()
	mascara.set_meta("_tema_aplicado", true)
	mascara.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	mascara.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mascara.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mascara.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var st_clip := StyleBoxFlat.new()
	st_clip.bg_color = Color("#eef2ff")
	st_clip.set_corner_radius_all(999)
	st_clip.anti_aliasing = true
	mascara.add_theme_stylebox_override("panel", st_clip)
	panel.add_child(mascara)

	var retrato := Personaje_Visual.new(ap, "busto")
	retrato.name = "Retrato"
	retrato.set_anchors_preset(Control.PRESET_FULL_RECT)
	retrato.expresion = "sonrisa"
	retrato.animar_idle = false
	retrato.dibujar_fondo_sunburst = false
	retrato.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mascara.add_child(retrato)
	# Las miniaturas son retratos estáticos: no necesitan repintarse cada frame.
	retrato.set_process(false)
	return panel


func _Tooltip_Atuendo(clave: String, poseida: bool) -> String:
	var nombre := Sistema_Cocina.Obtener_Nombre_Legible_Ropa(clave)
	if poseida:
		return nombre
	if Sistema_Cocina.Es_Ropa_Comprable(clave):
		return "%s · En tienda por %d €" % [nombre, int(round(Sistema_Cocina.Obtener_Precio_Ropa(clave)))]
	var rango := Sistema_Cocina.Obtener_Rango_Requerido_Ropa(clave)
	if rango > 0:
		var info := Sistema_Cocina.Obtener_Info_Rango(rango)
		return "%s · Se desbloquea en el Rango %d (%s)" % [nombre, rango, str(info.get("nombre", ""))]
	return "%s · Bloqueado" % nombre


func _Color_Atuendo(clave: String) -> Color:
	if clave == "Ropa_Calle":
		return Apariencia_Personaje.color_de(_apariencia_base, "color_ropa", Estilos_UI.BORDE_FUERTE)
	var obj = Variables_Estaticas.Catalogo_Objetos.get(clave, null)
	if obj is Objeto_Ropa:
		var ropa := obj as Objeto_Ropa
		var hex := ropa.color_detalle if ropa.color_detalle != "" else ropa.color_principal
		if hex != "" and Color.html_is_valid(hex):
			return Color.html(hex)
	return Estilos_UI.BORDE_FUERTE


func _Aplicar_Estilo_Tarjeta(btn: Button, clave: String, poseida: bool) -> void:
	var equipada := (clave == _clave_equipada)
	var seleccionada := (clave == _clave_seleccionada)
	var comprable := Sistema_Cocina.Es_Ropa_Comprable(clave)
	var acento := _Color_Atuendo(clave)
	var bg := Estilos_UI.SUPERFICIE
	var borde := Estilos_UI.BORDE
	var grosor := 1
	var fondo_inf := 2

	if not poseida and not comprable:
		bg = Color("#f1f3f7")
		borde = Color("#e2e6ee")
		fondo_inf = 0
		if seleccionada:
			borde = Estilos_UI.TINTA_FANTASMA
			grosor = 2
			fondo_inf = 1
	elif comprable:
		bg = Color("#fffbeb")
		borde = Color(Estilos_UI.ORO, 0.45)
		if seleccionada:
			bg = Color("#fef3c7")
			borde = Estilos_UI.ORO
			grosor = 2
			fondo_inf = 3
	elif seleccionada:
		bg = Color("#fff5f5") if not equipada else Estilos_UI.EXITO_SUAVE
		borde = Estilos_UI.ROJO_BIT if not equipada else Estilos_UI.EXITO
		grosor = 2
		fondo_inf = 3
	elif equipada:
		bg = Estilos_UI.EXITO_SUAVE
		borde = Estilos_UI.EXITO
		grosor = 1
		fondo_inf = 2
	else:
		borde = Color(acento, 0.42)

	var normal := Estilos_UI.caja(bg, 14, borde, grosor, 1)
	normal.border_width_bottom = fondo_inf
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = bg.darkened(0.02) if poseida else bg.lightened(0.02)
	hover.border_color = Estilos_UI.ROJO_BIT if poseida else borde
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("#ffe4e6") if poseida else bg.darkened(0.04)
	pressed.border_color = Estilos_UI.ROJO_BIT if poseida else borde
	pressed.border_width_bottom = 1
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = bg
	disabled.border_color = borde

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	var miniatura := btn.find_child("Miniatura", true, false) as Control
	if miniatura != null and not poseida and not comprable:
		miniatura.modulate = Color(0.72, 0.76, 0.84, 0.9)
	elif miniatura != null:
		miniatura.modulate = Color.WHITE

	var check := btn.find_child("Badge_Equipado", true, false) as Control
	if check != null:
		check.visible = equipada
	var candado := btn.find_child("Badge_Candado", true, false) as Control
	if candado != null:
		candado.visible = not poseida and not comprable
	var pill_precio := btn.find_child("Pill_Precio", true, false) as Control
	if pill_precio != null:
		pill_precio.visible = comprable

	var nombre := btn.find_child("Nombre", true, false) as Label
	if nombre != null:
		nombre.add_theme_color_override("font_color",
			Estilos_UI.TINTA if (poseida or comprable) else Estilos_UI.TINTA_FANTASMA)

	var estado := btn.find_child("Estado", true, false) as Label
	if estado != null:
		if equipada:
			estado.text = "Equipado"
			estado.add_theme_color_override("font_color", Estilos_UI.EXITO)
		elif comprable:
			estado.text = "En tienda"
			estado.add_theme_color_override("font_color", ORO_LEGIBLE)
		elif poseida:
			estado.text = "Disponible"
			estado.add_theme_color_override("font_color", Estilos_UI.TINTA_SUAVE)
		else:
			var rango := Sistema_Cocina.Obtener_Rango_Requerido_Ropa(clave)
			estado.text = "Rango %d" % rango if rango > 0 else "Bloqueado"
			estado.add_theme_color_override("font_color", Estilos_UI.TINTA_FANTASMA)


func _Actualizar_Estilos_Tarjetas() -> void:
	for clave in _cards.keys():
		var btn = _cards[clave]
		if btn == null or not is_instance_valid(btn):
			continue
		_Aplicar_Estilo_Tarjeta(btn, str(clave), bool(btn.get_meta("poseida", false)))


func _Seleccionar_Atuendo(clave: String) -> void:
	# Las tarjetas bloqueadas también se pueden previsualizar; el CTA y la
	# píldora BLOQUEADO explican que no se pueden equipar todavía.
	if not _cards.has(clave):
		return
	_clave_seleccionada = clave
	_Actualizar_Preview()
	_Actualizar_Estilos_Tarjetas()
	_Asegurar_Tarjeta_Visible.call_deferred(clave)


func _Asegurar_Tarjeta_Visible(clave: String) -> void:
	if _scroll == null or _hbox == null:
		return
	var card = _cards.get(clave)
	if card == null or not is_instance_valid(card):
		return
	var x: float = card.position.x
	var w: float = card.size.x
	var vista: float = _scroll.size.x
	var actual: float = float(_scroll.scroll_horizontal)
	var destino := actual
	if x < actual:
		destino = x
	elif x + w > actual + vista:
		destino = x + w - vista
	var maximo := maxf(0.0, _hbox.size.x - vista)
	_scroll.scroll_horizontal = int(clampf(destino, 0.0, maximo))


func _Actualizar_Preview() -> void:
	if _preview == null or not is_instance_valid(_preview):
		return
	var ap := Sistema_Cocina.Obtener_Apariencia_Con_Ropa(_apariencia_base, _clave_seleccionada)
	_preview.apariencia = ap
	_preview.establecer_actividad("")
	_preview.expresion = "sonrisa"

	var obj = Variables_Estaticas.Catalogo_Objetos.get(_clave_seleccionada, null)
	var ropa: Objeto_Ropa = obj as Objeto_Ropa if obj is Objeto_Ropa else null
	var nombre := Sistema_Cocina.Obtener_Nombre_Legible_Ropa(_clave_seleccionada)
	var equipada := (_clave_seleccionada == _clave_equipada)
	var poseida := bool(Variables_Dinamicas.Objetos_Poseidos.get(_clave_seleccionada, false))
	var comprable := Sistema_Cocina.Es_Ropa_Comprable(_clave_seleccionada)
	if _lbl_nombre != null:
		_lbl_nombre.text = nombre
	if _lbl_categoria != null:
		_lbl_categoria.text = "ATUENDO · %s" % Sistema_Cocina.Obtener_Categoria_Ropa(_clave_seleccionada).to_upper()
	if _lbl_efecto != null:
		_lbl_efecto.text = ropa.descripcion_efecto if ropa != null else ""
	if _lbl_desbloqueo != null:
		var rango_req := Sistema_Cocina.Obtener_Rango_Requerido_Ropa(_clave_seleccionada)
		var tipo_desbloqueo := str(ropa.desbloqueo) if ropa != null else "inicio"
		if poseida and rango_req > 0:
			var info_r := Sistema_Cocina.Obtener_Info_Rango(rango_req)
			_lbl_desbloqueo.text = "Conseguido en el Rango %d · %s" % [rango_req, str(info_r.get("nombre", ""))]
		elif comprable:
			_lbl_desbloqueo.text = "En tienda · %d € · Se guarda en tu armario al comprarla." % int(round(Sistema_Cocina.Obtener_Precio_Ropa(_clave_seleccionada)))
		elif rango_req > 0:
			var info_r := Sistema_Cocina.Obtener_Info_Rango(rango_req)
			_lbl_desbloqueo.text = "Se desbloquea en el Rango %d · %s" % [rango_req, str(info_r.get("nombre", ""))]
		elif poseida and tipo_desbloqueo == "tienda":
			_lbl_desbloqueo.text = "Comprada · En tu armario"
		else:
			_lbl_desbloqueo.text = "Disponible desde el inicio"

	if _pill_estado != null:
		if equipada:
			_Actualizar_Pill(_pill_estado, "EQUIPADO", Estilos_UI.EXITO_SUAVE, Estilos_UI.EXITO)
		elif comprable:
			_Actualizar_Pill(_pill_estado, "EN TIENDA", Estilos_UI.ORO_SUAVE, ORO_LEGIBLE)
		elif not poseida:
			_Actualizar_Pill(_pill_estado, "BLOQUEADO", Color("#f1f5f9"), Estilos_UI.TINTA_FANTASMA)
		else:
			_Actualizar_Pill(_pill_estado, "EN PRUEBA", Estilos_UI.AZUL_SUAVE, Estilos_UI.AZUL)

	_Actualizar_Chips(ropa)
	_Actualizar_Boton_Accion(equipada, poseida, comprable)
	_Actualizar_Saldo()


func _Actualizar_Pill(pill: PanelContainer, texto: String, fondo: Color, texto_col: Color) -> void:
	var st := Estilos_UI.caja(fondo, 999, Color(texto_col, 0.18), 1, 0)
	st.content_margin_left = 10
	st.content_margin_right = 10
	st.content_margin_top = 4
	st.content_margin_bottom = 4
	pill.add_theme_stylebox_override("panel", st)
	var lbl := pill.get_child(0) as Label
	if lbl != null:
		lbl.text = texto
		lbl.add_theme_font_override("font", Estilos_UI.fuente_ui(700))
		lbl.add_theme_color_override("font_color", texto_col)


func _Actualizar_Chips(ropa: Objeto_Ropa) -> void:
	if _chips == null:
		return
	for hijo in _chips.get_children():
		_chips.remove_child(hijo)
		hijo.queue_free()
	if ropa == null:
		return
	var hay := false
	if ropa.bonus_salario_general > 0.0:
		hay = true
		_chips.add_child(Estilos_UI.pill_estado("Salario +%d%%" % int(round(ropa.bonus_salario_general * 100.0)),
			Estilos_UI.EXITO_SUAVE, Estilos_UI.EXITO))
	if ropa.bonus_salario_hosteleria > 0.0:
		hay = true
		_chips.add_child(Estilos_UI.pill_estado("Salario hostelería +%d%%" % int(round(ropa.bonus_salario_hosteleria * 100.0)),
			Estilos_UI.EXITO_SUAVE, Estilos_UI.EXITO))
	if ropa.bonus_progreso_deporte > 0.0:
		hay = true
		_chips.add_child(Estilos_UI.pill_estado("Deporte +%d%%" % int(round(ropa.bonus_progreso_deporte * 100.0)),
			Estilos_UI.AZUL_SUAVE, Estilos_UI.AZUL))
	if ropa.bonus_progreso_academico > 0.0:
		hay = true
		_chips.add_child(Estilos_UI.pill_estado("Académico +%d%%" % int(round(ropa.bonus_progreso_academico * 100.0)),
			Estilos_UI.INDIGO_SUAVE, Estilos_UI.INDIGO))
	if ropa.bonus_progreso_manualidades > 0.0:
		hay = true
		_chips.add_child(Estilos_UI.pill_estado("Manualidades +%d%%" % int(round(ropa.bonus_progreso_manualidades * 100.0)),
			Estilos_UI.ORO_SUAVE, ORO_LEGIBLE))
	if ropa.reduccion_higiene_trabajo > 0.0:
		hay = true
		_chips.add_child(Estilos_UI.pill_estado("Higiene hostelería -%d%%" % int(round(ropa.reduccion_higiene_trabajo * 100.0)),
			Estilos_UI.CIAN_SUAVE, Estilos_UI.CIAN))
	if ropa.reduccion_higiene_cualquier_trabajo > 0.0:
		hay = true
		_chips.add_child(Estilos_UI.pill_estado("Higiene trabajo -%d%%" % int(round(ropa.reduccion_higiene_cualquier_trabajo * 100.0)),
			Estilos_UI.CIAN_SUAVE, Estilos_UI.CIAN))
	if ropa.bonus_propinas_minijuego > 0.0:
		hay = true
		_chips.add_child(Estilos_UI.pill_estado("Propinas +%d%%" % int(round(ropa.bonus_propinas_minijuego * 100.0)),
			Estilos_UI.ORO_SUAVE, ORO_LEGIBLE))
	if not hay:
		_chips.add_child(Estilos_UI.pill_estado("Sin bonificaciones", Color("#f1f5f9"), Estilos_UI.TINTA_SUAVE))


func _Actualizar_Boton_Accion(equipada: bool, poseida: bool, comprable: bool) -> void:
	if _btn_equipar == null:
		return
	if equipada:
		_btn_equipar.disabled = true
		_btn_equipar.text = "Atuendo equipado"
		Estilos_UI.aplicar_estilo_boton(_btn_equipar, "suave", Estilos_UI.EXITO, "check")
		var st_ok := Estilos_UI.caja(Estilos_UI.EXITO_SUAVE, 12, Color(Estilos_UI.EXITO, 0.55), 1, 0)
		_btn_equipar.add_theme_stylebox_override("disabled", st_ok)
		_btn_equipar.add_theme_color_override("font_disabled_color", Estilos_UI.EXITO_OSCURO)
		_btn_equipar.add_theme_color_override("icon_disabled_color", Estilos_UI.EXITO_OSCURO)
	elif comprable:
		var precio := Sistema_Cocina.Obtener_Precio_Ropa(_clave_seleccionada)
		if Variables_Dinamicas.Dinero >= precio:
			_btn_equipar.disabled = false
			_btn_equipar.text = "Comprar por %d €" % int(round(precio))
			Estilos_UI.aplicar_estilo_boton(_btn_equipar, "primario", Estilos_UI.ORO, "coins")
		else:
			var faltan := int(ceil(precio - Variables_Dinamicas.Dinero))
			_btn_equipar.disabled = true
			_btn_equipar.text = "Faltan %d €" % faltan
			Estilos_UI.aplicar_estilo_boton(_btn_equipar, "suave", Estilos_UI.ORO, "coins")
			var st_sin_saldo := Estilos_UI.caja(Estilos_UI.ORO_SUAVE, 12,
				Color(Estilos_UI.ORO, 0.42), 1, 0)
			_btn_equipar.add_theme_stylebox_override("disabled", st_sin_saldo)
			_btn_equipar.add_theme_color_override("font_disabled_color", ORO_LEGIBLE)
			_btn_equipar.add_theme_color_override("icon_disabled_color", ORO_LEGIBLE)
	elif poseida:
		_btn_equipar.disabled = false
		_btn_equipar.text = "Equipar atuendo"
		Estilos_UI.aplicar_estilo_boton(_btn_equipar, "primario", Estilos_UI.ROJO_BIT, "shirt")
	else:
		_btn_equipar.disabled = true
		_btn_equipar.text = "Atuendo bloqueado"
		Estilos_UI.aplicar_estilo_boton(_btn_equipar, "suave", Estilos_UI.TINTA_FANTASMA, "lock")
	_btn_equipar.add_theme_font_override("font", Estilos_UI.fuente_titulo(700))
	_btn_equipar.add_theme_font_size_override("font_size", 18)


func _Accion_Principal() -> void:
	if _clave_seleccionada == "":
		return
	if Sistema_Cocina.Es_Ropa_Comprable(_clave_seleccionada):
		if comprar_seleccionado():
			equipar_seleccionado()
		return
	equipar_seleccionado()


func _Actualizar_Saldo() -> void:
	if _lbl_saldo == null:
		return
	_lbl_saldo.text = "%d €" % int(Variables_Dinamicas.Dinero)


func _Desplazar_Carrusel(direccion: int) -> void:
	if _scroll == null:
		return
	var paso := (ANCHO_TARJETA + SEPARACION_TARJETAS) * 2.0
	var maximo := maxf(0.0, _hbox.size.x - _scroll.size.x)
	_scroll.scroll_horizontal = int(clampf(_scroll.scroll_horizontal + direccion * paso, 0.0, maximo))


func _on_volver_pressed() -> void:
	cerrado.emit()


# ------------------------------------------------------------------ API pública

func abrir() -> void:
	if not _construido:
		_Construir()
	_Ajustar_Tamano()
	Sistema_Cocina.Asegurar_Prendas_Iniciales()
	_apariencia_base = Apariencia_Personaje.normalizar(Variables_Estaticas.Apariencia)
	_clave_equipada = Sistema_Cocina.Obtener_Clave_Ropa_Equipada()
	_clave_seleccionada = _clave_equipada
	if not _Puede_Seleccionar(_clave_seleccionada):
		_clave_seleccionada = "Ropa_Calle"
	if not _Claves_Filtradas().has(_clave_seleccionada):
		_filtro_actual = "todo"
	_Reconstruir_Carrusel()
	_Actualizar_Preview()
	_Actualizar_Filtros_Estilos()
	_Actualizar_Tarjeta_Maestria()
	_Actualizar_Saldo()
	_Aplicar_Estilos_Tarjetas_Todas()
	_Asegurar_Tarjeta_Visible.call_deferred(_clave_seleccionada)
	if _preview != null and is_instance_valid(_preview):
		_preview.animar_idle = true
	visible = true


func obtener_clave_seleccionada() -> String:
	return _clave_seleccionada


func obtener_clave_equipada() -> String:
	return _clave_equipada


func obtener_apariencia_preview() -> Dictionary:
	if _preview == null or not is_instance_valid(_preview):
		return {}
	return _preview.apariencia.duplicate(true)


func obtener_tarjetas() -> Dictionary:
	return _cards.duplicate()


func seleccionar_atuendo(clave: String) -> bool:
	if not _cards.has(clave):
		return false
	if not _Puede_Seleccionar(clave):
		return false
	_Seleccionar_Atuendo(clave)
	return true


func comprar_seleccionado() -> bool:
	if not Sistema_Cocina.Es_Ropa_Comprable(_clave_seleccionada):
		return false
	if not Sistema_Cocina.Comprar_Ropa(_clave_seleccionada):
		_Actualizar_Preview()
		return false
	_Reconstruir_Carrusel()
	_Actualizar_Preview()
	_Actualizar_Estilos_Tarjetas()
	_Asegurar_Tarjeta_Visible.call_deferred(_clave_seleccionada)
	atuendo_comprado.emit(_clave_seleccionada)
	return true


func equipar_seleccionado() -> bool:
	if _clave_seleccionada == "":
		return false
	if _clave_seleccionada == _clave_equipada:
		return false
	if not Sistema_Cocina.Equipar_Ropa(_clave_seleccionada):
		return false
	_clave_equipada = _clave_seleccionada
	_Actualizar_Preview()
	_Actualizar_Estilos_Tarjetas()
	_Asegurar_Tarjeta_Visible.call_deferred(_clave_equipada)
	atuendo_equipado.emit(_clave_equipada)
	return true


func _Aplicar_Estilos_Tarjetas_Todas() -> void:
	_Actualizar_Cuenta()
	_Actualizar_Estilos_Tarjetas()


# ------------------------------------------------------------------ fondo del escenario

class _FondoVestuario:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		var w := size.x
		var h := size.y
		if w <= 1.0 or h <= 1.0:
			return

		# Degradado vertical suave (azul lavanda → casi blanco).
		var franjas := 24
		for i in range(franjas):
			var t := float(i) / float(maxi(1, franjas - 1))
			var col := Color("#e8edff").lerp(Color("#f7f9ff"), t)
			draw_rect(Rect2(0.0, h * t, w, h / float(franjas) + 1.0), col)

		# Rayos de foco desde la parte alta.
		var centro := Vector2(w * 0.5, h * 0.38)
		var radio := maxf(w, h) * 1.3
		for i in range(12):
			var a0 := TAU * float(i) / 12.0
			var a1 := a0 + TAU / 24.0
			draw_colored_polygon(PackedVector2Array([
				centro,
				centro + Vector2(cos(a0), sin(a0)) * radio,
				centro + Vector2(cos(a1), sin(a1)) * radio,
			]), Color(1.0, 1.0, 1.0, 0.16))

		# Halo central.
		for i in range(6):
			var r := w * (0.18 + float(i) * 0.06)
			draw_circle(centro, r, Color(1.0, 1.0, 1.0, 0.035), true, -1.0, true)

		# Destellos decorativos.
		var puntos := [
			Vector2(0.12, 0.20), Vector2(0.86, 0.16), Vector2(0.78, 0.52),
			Vector2(0.18, 0.62), Vector2(0.90, 0.74), Vector2(0.10, 0.84),
		]
		for i in range(puntos.size()):
			var p: Vector2 = puntos[i]
			var a := 0.14 + 0.08 * float(i % 3)
			draw_circle(Vector2(w * p.x, h * p.y), 2.6, Color(1, 1, 1, a), true, -1.0, true)
			draw_circle(Vector2(w * p.x, h * p.y), 1.3, Color(Estilos_UI.INDIGO, 0.20), true, -1.0, true)

		# Sombra elíptica en el suelo.
		var suelo := _elipse(Vector2(w * 0.5, h * 0.895), w * 0.30, h * 0.026, 30)
		draw_colored_polygon(suelo, Color(0.12, 0.18, 0.32, 0.13))
		var plataforma := _elipse(Vector2(w * 0.5, h * 0.895), w * 0.22, h * 0.017, 30)
		draw_colored_polygon(plataforma, Color(1.0, 1.0, 1.0, 0.55))

	func _elipse(centro: Vector2, rx: float, ry: float, pasos: int) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in range(pasos):
			var a := TAU * float(i) / float(pasos)
			pts.append(centro + Vector2(cos(a) * rx, sin(a) * ry))
		return pts
