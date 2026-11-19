extends CanvasLayer

signal cerrado

var _paginas: Array = []
var _pagina_actual: int = 0
var _carrera_nombre: String = ""
var _año: int = 1
var _emoji: String = "📘"
var _busy: bool = false
var _touch_start: Vector2 = Vector2.ZERO
var _touch_active: bool = false

var _base: Control = null
var _book_container: Control = null
var _indicador: Label = null
var _boton_volver: Button = null


func _Alto_Pantalla() -> float:
	var alto: float = get_viewport().get_visible_rect().size.y
	return alto if alto >= 1280.0 else 1280.0


func _Ajustar_Alto() -> void:
	if _base == null:
		return
	var alto := _Alto_Pantalla()
	_base.offset_bottom = alto
	if _book_container != null:
		_book_container.offset_bottom = alto - 84.0
	if _indicador != null:
		_indicador.offset_top = alto - 70.0
		_indicador.offset_bottom = alto - 28.0


func configurar(paginas: Array, carrera_nombre: String, año: int, emoji: String = "📘"):
	_paginas = paginas
	_carrera_nombre = carrera_nombre
	_año = año
	_emoji = emoji
	_pagina_actual = 0
	if _book_container != null:
		_Renderizar_Pagina()


func _ready():
	layer = 100
	var alto := _Alto_Pantalla()

	_base = Control.new()
	_base.offset_right = 720.0
	_base.offset_bottom = alto
	add_child(_base)
	var base := _base

	var fondo = ColorRect.new()
	fondo.anchor_right = 1.0
	fondo.anchor_bottom = 1.0
	fondo.color = Estilos_UI.FONDO
	base.add_child(fondo)

	_boton_volver = Estilos_UI.boton("Volver", "chip", "arrow-left", Estilos_UI.PRIMARIO, 42)
	_boton_volver.offset_left = 20.0
	_boton_volver.offset_top = 24.0
	_boton_volver.offset_right = 136.0
	_boton_volver.offset_bottom = 66.0
	_boton_volver.add_theme_font_size_override("font_size", 14)
	_boton_volver.pressed.connect(_on_volver)
	base.add_child(_boton_volver)

	var ayuda = Estilos_UI.texto("Toca o desliza para pasar de página", 12, Estilos_UI.TINTA_FANTASMA, 500)
	ayuda.offset_left = 156.0
	ayuda.offset_top = 24.0
	ayuda.offset_right = 700.0
	ayuda.offset_bottom = 66.0
	ayuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	base.add_child(ayuda)

	_book_container = Control.new()
	_book_container.offset_left = 24.0
	_book_container.offset_top = 86.0
	_book_container.offset_right = 696.0
	_book_container.offset_bottom = alto - 84.0
	base.add_child(_book_container)

	_indicador = Label.new()
	_indicador.offset_left = 24.0
	_indicador.offset_top = alto - 70.0
	_indicador.offset_right = 210.0
	_indicador.offset_bottom = alto - 28.0
	_indicador.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_indicador.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_indicador.add_theme_font_override("font", Estilos_UI.fuente_ui(600))
	_indicador.add_theme_color_override("font_color", Estilos_UI.TINTA)
	_indicador.add_theme_font_size_override("font_size", 13)
	var pill = Estilos_UI.caja(Estilos_UI.SUPERFICIE, 999, Estilos_UI.BORDE, 1, 0)
	pill.content_margin_left = 16
	pill.content_margin_right = 16
	pill.content_margin_top = 6
	pill.content_margin_bottom = 6
	_indicador.add_theme_stylebox_override("normal", pill)
	base.add_child(_indicador)
	get_viewport().size_changed.connect(_Ajustar_Alto)
	if not _paginas.is_empty():
		_Renderizar_Pagina()


func _on_volver():
	cerrado.emit()
	queue_free()


func _input(event: InputEvent):
	if _busy or _book_container == null:
		return
	var boton_rect = _boton_volver.get_global_rect()
	if event is InputEventScreenTouch:
		if event.pressed:
			if not boton_rect.has_point(event.position):
				_touch_start = event.position
				_touch_active = true
				get_viewport().set_input_as_handled()
		elif _touch_active:
			_touch_active = false
			var dx = event.position.x - _touch_start.x
			var dy = event.position.y - _touch_start.y
			get_viewport().set_input_as_handled()
			if abs(dx) > abs(dy) and abs(dx) > 38:
				_Cambiar_Pagina(1 if dx < 0 else -1)
			elif abs(dx) < 15 and abs(dy) < 15:
				_Cambiar_Pagina(1 if event.position.x > 360.0 else -1)


func _Cambiar_Pagina(dir: int):
	if _busy:
		return
	var next = _pagina_actual + dir
	if next < 0 or next >= _paginas.size():
		return
	_busy = true
	var tween = create_tween()
	tween.tween_property(_book_container, "modulate:a", 0.15, 0.14).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		_pagina_actual = next
		_Renderizar_Pagina()
	)
	tween.tween_property(_book_container, "modulate:a", 1.0, 0.16).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): _busy = false)


func _Renderizar_Pagina():
	for hijo in _book_container.get_children():
		hijo.queue_free()

	if _pagina_actual == 0:
		_indicador.text = "Portada"
	else:
		_indicador.text = "Página %d de %d" % [_pagina_actual, _paginas.size() - 1]

	if _paginas.is_empty():
		return

	var sh = Panel.new()
	sh.anchor_left = 0; sh.anchor_right = 1; sh.anchor_top = 0; sh.anchor_bottom = 1
	sh.offset_left = 4; sh.offset_right = 6; sh.offset_top = 8; sh.offset_bottom = 10
	sh.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sh.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Color(0.06, 0.09, 0.16, 0.12), 14, Color(0, 0, 0, 0), 0, 0))
	_book_container.add_child(sh)

	var pagina = _paginas[_pagina_actual]
	var tipo := str(pagina.get("type", ""))
	if tipo == "cover":
		_Renderizar_Cover(pagina)
	elif tipo == "diploma":
		_Renderizar_Diploma(pagina)
	else:
		_Renderizar_Contenido(pagina)

	var spine = ColorRect.new()
	spine.color = Color("#0f172a") if tipo == "cover" else (Color("#422006") if tipo == "diploma" else Color("#cbd5e1"))
	spine.anchor_left = 0; spine.anchor_right = 0; spine.anchor_top = 0; spine.anchor_bottom = 1
	spine.offset_left = -8; spine.offset_right = 6; spine.offset_top = 8; spine.offset_bottom = -8
	spine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_book_container.add_child(spine)


func _Crear_Divisor_Gradiente(ancho: float = 280.0, color_base: Color = Color(0.85, 0.69, 0.35)) -> Control:
	var ctrl = Control.new()
	ctrl.custom_minimum_size = Vector2(ancho, 2)
	ctrl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ctrl.draw.connect(func():
		var w = ctrl.size.x
		var h = 2.0
		var mid = w * 0.5
		ctrl.draw_polygon(
			PackedVector2Array([Vector2(0,0), Vector2(mid,0), Vector2(mid,h), Vector2(0,h)]),
			PackedColorArray([Color(color_base, 0), Color(color_base, 0.65), Color(color_base, 0.65), Color(color_base, 0)])
		)
		ctrl.draw_polygon(
			PackedVector2Array([Vector2(mid,0), Vector2(w,0), Vector2(w,h), Vector2(mid,h)]),
			PackedColorArray([Color(color_base, 0.65), Color(color_base, 0), Color(color_base, 0), Color(color_base, 0.65)])
		)
	)
	ctrl.queue_redraw()
	return ctrl


func _Renderizar_Cover(pagina: Dictionary):
	var c = _book_container

	var cover_bg = Panel.new()
	cover_bg.anchor_left = 0; cover_bg.anchor_right = 1; cover_bg.anchor_top = 0; cover_bg.anchor_bottom = 1
	cover_bg.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Color("#1e293b"), 14, Color("#0f172a"), 1, 0))
	c.add_child(cover_bg)

	var bos = StyleBoxFlat.new()
	bos.bg_color = Color(0, 0, 0, 0)
	bos.set_corner_radius_all(8)
	bos.set_border_width_all(2)
	bos.border_color = Color(0.86, 0.72, 0.42, 0.35)
	var border_outer = Panel.new()
	border_outer.anchor_left = 0; border_outer.anchor_right = 1; border_outer.anchor_top = 0; border_outer.anchor_bottom = 1
	border_outer.offset_left = 28; border_outer.offset_right = -28; border_outer.offset_top = 28; border_outer.offset_bottom = -28
	border_outer.add_theme_stylebox_override("panel", bos)
	border_outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(border_outer)

	var vbox = VBoxContainer.new()
	vbox.anchor_left = 0; vbox.anchor_right = 1; vbox.anchor_top = 0; vbox.anchor_bottom = 1
	vbox.offset_left = 54; vbox.offset_right = -54
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 22)
	c.add_child(vbox)

	var eyebrow = Label.new()
	eyebrow.text = (_carrera_nombre.replace("_", " ") + " · AÑO " + str(_año)).to_upper()
	eyebrow.add_theme_font_override("font", Estilos_UI.fuente_ui(600))
	eyebrow.add_theme_font_size_override("font_size", 13)
	eyebrow.add_theme_color_override("font_color", Color(0.88, 0.76, 0.50, 0.75))
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	eyebrow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(eyebrow)

	var icono_libro := Estilos_UI.icono_rect("book-open", 52, Color(0.95, 0.87, 0.68, 0.92))
	icono_libro.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(icono_libro)

	vbox.add_child(_Crear_Divisor_Gradiente(240))

	var title_lbl = Label.new()
	title_lbl.text = pagina.title
	title_lbl.add_theme_font_override("font", Estilos_UI.fuente_editorial(700))
	title_lbl.add_theme_font_size_override("font_size", 36)
	title_lbl.add_theme_color_override("font_color", Color("#f8ecd1"))
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(title_lbl)

	vbox.add_child(_Crear_Divisor_Gradiente(240))

	var subtitle_lbl = Label.new()
	subtitle_lbl.text = "Apuntes del curso"
	subtitle_lbl.add_theme_font_override("font", Estilos_UI.fuente_ui(500))
	subtitle_lbl.add_theme_font_size_override("font_size", 16)
	subtitle_lbl.add_theme_color_override("font_color", Color(0.94, 0.87, 0.71, 0.72))
	subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle_lbl)

	var footer = Label.new()
	footer.text = "UNIDAD %d" % _año
	footer.add_theme_font_override("font", Estilos_UI.fuente_ui(600))
	footer.add_theme_font_size_override("font_size", 12)
	footer.add_theme_color_override("font_color", Color(0.94, 0.87, 0.71, 0.45))
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.anchor_left = 0; footer.anchor_right = 1; footer.anchor_top = 1; footer.anchor_bottom = 1
	footer.offset_top = -54; footer.offset_bottom = -28
	c.add_child(footer)


func _Renderizar_Diploma(pagina: Dictionary):
	var c = _book_container

	var cover_bg = Panel.new()
	cover_bg.anchor_left = 0; cover_bg.anchor_right = 1; cover_bg.anchor_top = 0; cover_bg.anchor_bottom = 1
	cover_bg.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Color("#fcf9f2"), 14, Color("#d4b46c"), 2, 0))
	c.add_child(cover_bg)

	var bos = StyleBoxFlat.new()
	bos.bg_color = Color(0, 0, 0, 0)
	bos.set_corner_radius_all(8)
	bos.set_border_width_all(2)
	bos.border_color = Color("#b8913b")
	var border_outer = Panel.new()
	border_outer.anchor_left = 0; border_outer.anchor_right = 1; border_outer.anchor_top = 0; border_outer.anchor_bottom = 1
	border_outer.offset_left = 26; border_outer.offset_right = -26; border_outer.offset_top = 26; border_outer.offset_bottom = -26
	border_outer.add_theme_stylebox_override("panel", bos)
	border_outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(border_outer)

	var vbox = VBoxContainer.new()
	vbox.anchor_left = 0; vbox.anchor_right = 1; vbox.anchor_top = 0; vbox.anchor_bottom = 1
	vbox.offset_left = 52; vbox.offset_right = -52
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	c.add_child(vbox)

	var eyebrow = Label.new()
	eyebrow.text = "TÍTULO UNIVERSITARIO OFICIAL"
	eyebrow.add_theme_font_override("font", Estilos_UI.fuente_ui(700))
	eyebrow.add_theme_font_size_override("font_size", 12)
	eyebrow.add_theme_color_override("font_color", Color("#926b1d"))
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(eyebrow)

	var sello := PanelContainer.new()
	sello.custom_minimum_size = Vector2(76, 76)
	sello.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	sello.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Color("#fef3c7"), 38, Color("#d4b46c"), 2, 0))
	var sello_ic := Estilos_UI.icono_rect("graduation-cap", 36, Color("#926b1d"))
	sello_ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	sello_ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sello.add_child(sello_ic)
	vbox.add_child(sello)

	vbox.add_child(_Crear_Divisor_Gradiente(240, Color("#b8913b")))

	var title_lbl = Label.new()
	title_lbl.text = str(pagina.get("carrera_nombre", "")).replace("_", " ")
	title_lbl.add_theme_font_override("font", Estilos_UI.fuente_editorial(700))
	title_lbl.add_theme_font_size_override("font_size", 36)
	title_lbl.add_theme_color_override("font_color", Estilos_UI.TINTA)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(title_lbl)

	vbox.add_child(_Crear_Divisor_Gradiente(240, Color("#b8913b")))

	var subtitle_lbl = Label.new()
	subtitle_lbl.text = "Nota media final: %.1f / 100" % float(pagina.get("nota_media", 0.0))
	subtitle_lbl.add_theme_font_override("font", Estilos_UI.fuente_ui(600))
	subtitle_lbl.add_theme_font_size_override("font_size", 18)
	subtitle_lbl.add_theme_color_override("font_color", Estilos_UI.TINTA_SUAVE)
	subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle_lbl)


func _Renderizar_Contenido(pagina: Dictionary):
	var c = _book_container

	var page_bg = Panel.new()
	page_bg.anchor_left = 0; page_bg.anchor_right = 1; page_bg.anchor_top = 0; page_bg.anchor_bottom = 1
	page_bg.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Color("#fdfbf7"), 14, Estilos_UI.BORDE, 1, 0))
	c.add_child(page_bg)

	var ruled = Control.new()
	ruled.anchor_left = 0; ruled.anchor_right = 1; ruled.anchor_top = 0; ruled.anchor_bottom = 1
	ruled.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(ruled)
	ruled.draw.connect(func():
		var w = ruled.size.x
		var line_color = Color(0.20, 0.35, 0.65, 0.06)
		var y = 132.0
		while y < ruled.size.y - 24.0:
			ruled.draw_line(Vector2(24, y), Vector2(w - 24, y), line_color, 1.0)
			y += 42.0
	)
	ruled.queue_redraw()

	var margin_line = ColorRect.new()
	margin_line.color = Color(0.85, 0.32, 0.32, 0.16)
	margin_line.anchor_left = 0; margin_line.anchor_right = 0; margin_line.anchor_top = 0; margin_line.anchor_bottom = 1
	margin_line.offset_left = 56; margin_line.offset_right = 58
	margin_line.offset_top = 18; margin_line.offset_bottom = -18
	c.add_child(margin_line)

	var vbox = VBoxContainer.new()
	vbox.anchor_left = 0; vbox.anchor_right = 1; vbox.anchor_top = 0; vbox.anchor_bottom = 1
	vbox.offset_left = 78; vbox.offset_right = -26; vbox.offset_bottom = -20
	c.add_child(vbox)

	var header_style = StyleBoxFlat.new()
	header_style.bg_color = Color(0, 0, 0, 0)
	header_style.border_width_bottom = 1
	header_style.border_color = Color("#e5dfd3")
	header_style.content_margin_left = 0; header_style.content_margin_top = 22
	header_style.content_margin_right = 0; header_style.content_margin_bottom = 16
	var header_panel = PanelContainer.new()
	header_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_panel.add_theme_stylebox_override("panel", header_style)
	vbox.add_child(header_panel)

	var header_vbox = VBoxContainer.new()
	header_vbox.add_theme_constant_override("separation", 4)
	header_panel.add_child(header_vbox)

	var chapter_lbl = Label.new()
	chapter_lbl.text = pagina.chapter.to_upper()
	chapter_lbl.add_theme_font_override("font", Estilos_UI.fuente_ui(700))
	chapter_lbl.add_theme_font_size_override("font_size", 11)
	chapter_lbl.add_theme_color_override("font_color", Estilos_UI.PRIMARIO)
	header_vbox.add_child(chapter_lbl)

	var section_lbl = Label.new()
	section_lbl.text = pagina.title
	section_lbl.add_theme_font_override("font", Estilos_UI.fuente_editorial(600))
	section_lbl.add_theme_font_size_override("font_size", 26)
	section_lbl.add_theme_color_override("font_color", Estilos_UI.TINTA)
	section_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	section_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_vbox.add_child(section_lbl)

	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var body_lbl = RichTextLabel.new()
	body_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_lbl.fit_content = true
	body_lbl.bbcode_enabled = false
	body_lbl.text = pagina.body
	body_lbl.add_theme_font_override("normal_font", Estilos_UI.fuente_ui(400))
	body_lbl.add_theme_font_size_override("normal_font_size", 17)
	body_lbl.add_theme_color_override("default_color", Estilos_UI.TINTA)
	body_lbl.add_theme_constant_override("line_separation", 8)
	scroll.add_child(body_lbl)
