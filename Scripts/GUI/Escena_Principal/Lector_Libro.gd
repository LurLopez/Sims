extends CanvasLayer

signal cerrado

var _paginas: Array = []
var _pagina_actual: int = 0
var _carrera_nombre: String = ""
var _año: int = 1
var _busy: bool = false
var _touch_start: Vector2 = Vector2.ZERO
var _touch_active: bool = false

var _book_container: Control = null
var _indicador: Label = null
var _boton_volver: Button = null


func configurar(paginas: Array, carrera_nombre: String, año: int):
	_paginas = paginas
	_carrera_nombre = carrera_nombre
	_año = año
	_pagina_actual = 0
	_Renderizar_Pagina()


func _ready():
	layer = 100

	var base = Control.new()
	base.offset_right = 720.0
	base.offset_bottom = 1280.0
	add_child(base)

	var fondo = ColorRect.new()
	fondo.anchor_right = 1.0; fondo.anchor_bottom = 1.0
	fondo.color = Color(0.094, 0.047, 0.020, 1.0)
	base.add_child(fondo)

	var btn_hover = StyleBoxFlat.new()
	btn_hover.bg_color = Color(0.15, 0.65, 0.85, 1)
	btn_hover.border_width_left = 2; btn_hover.border_width_top = 2
	btn_hover.border_width_right = 2; btn_hover.border_width_bottom = 2
	btn_hover.border_color = Color(0.05, 0.35, 0.55, 1)
	btn_hover.corner_radius_top_left = 12; btn_hover.corner_radius_top_right = 12
	btn_hover.corner_radius_bottom_right = 12; btn_hover.corner_radius_bottom_left = 12
	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.1, 0.55, 0.75, 1)
	btn_normal.border_width_left = 2; btn_normal.border_width_top = 2
	btn_normal.border_width_right = 2; btn_normal.border_width_bottom = 2
	btn_normal.border_color = Color(0.05, 0.35, 0.55, 1)
	btn_normal.corner_radius_top_left = 12; btn_normal.corner_radius_top_right = 12
	btn_normal.corner_radius_bottom_right = 12; btn_normal.corner_radius_bottom_left = 12

	_boton_volver = Button.new()
	_boton_volver.offset_left = 10.0; _boton_volver.offset_top = 10.0
	_boton_volver.offset_right = 165.0; _boton_volver.offset_bottom = 62.0
	_boton_volver.text = "← Volver"
	_boton_volver.add_theme_stylebox_override("hover", btn_hover)
	_boton_volver.add_theme_stylebox_override("normal", btn_normal)
	_boton_volver.pressed.connect(_on_volver)
	base.add_child(_boton_volver)

	_book_container = Control.new()
	_book_container.offset_left = 20.0; _book_container.offset_top = 80.0
	_book_container.offset_right = 700.0; _book_container.offset_bottom = 1195.0
	base.add_child(_book_container)

	_indicador = Label.new()
	_indicador.offset_left = 14.0; _indicador.offset_top = 1205.0
	_indicador.offset_right = 320.0; _indicador.offset_bottom = 1252.0
	_indicador.add_theme_color_override("font_color", Color(1, 1, 1, 0.82))
	_indicador.add_theme_font_size_override("font_size", 22)
	var pill = StyleBoxFlat.new()
	pill.bg_color = Color(0, 0, 0, 0.32)
	pill.corner_radius_top_left = 22; pill.corner_radius_top_right = 22
	pill.corner_radius_bottom_left = 22; pill.corner_radius_bottom_right = 22
	pill.content_margin_left = 18; pill.content_margin_right = 18
	pill.content_margin_top = 7; pill.content_margin_bottom = 7
	_indicador.add_theme_stylebox_override("normal", pill)
	base.add_child(_indicador)


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
	tween.tween_property(_book_container, "modulate:a", 0.1, 0.16).set_ease(Tween.EASE_IN)
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
		_indicador.text = "%d / %d" % [_pagina_actual, _paginas.size() - 1]

	if _paginas.is_empty():
		return

	var sh = ColorRect.new()
	sh.color = Color(0, 0, 0, 0.75)
	sh.anchor_left = 0; sh.anchor_right = 1; sh.anchor_top = 0; sh.anchor_bottom = 1
	sh.offset_left = 6; sh.offset_right = 6; sh.offset_top = 12; sh.offset_bottom = 12
	_book_container.add_child(sh)

	var pagina = _paginas[_pagina_actual]
	if pagina.type == "cover":
		_Renderizar_Cover(pagina)
	else:
		_Renderizar_Contenido(pagina)

	var spine = ColorRect.new()
	spine.color = Color(0.118, 0.024, 0.024)
	spine.anchor_left = 0; spine.anchor_right = 0; spine.anchor_top = 0; spine.anchor_bottom = 1
	spine.offset_left = -20; spine.offset_right = 7; spine.offset_top = 7; spine.offset_bottom = -7
	_book_container.add_child(spine)


func _Crear_Divisor_Gradiente(ancho: float = 300.0) -> Control:
	var ctrl = Control.new()
	ctrl.custom_minimum_size = Vector2(ancho, 3)
	ctrl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ctrl.draw.connect(func():
		var w = ctrl.size.x
		var h = 3.0
		var g = Color(0.961, 0.839, 0.541)
		var mid = w * 0.5
		ctrl.draw_polygon(
			PackedVector2Array([Vector2(0,0), Vector2(mid,0), Vector2(mid,h), Vector2(0,h)]),
			PackedColorArray([Color(g.r,g.g,g.b,0), Color(g.r,g.g,g.b,0.55), Color(g.r,g.g,g.b,0.55), Color(g.r,g.g,g.b,0)])
		)
		ctrl.draw_polygon(
			PackedVector2Array([Vector2(mid,0), Vector2(w,0), Vector2(w,h), Vector2(mid,h)]),
			PackedColorArray([Color(g.r,g.g,g.b,0.55), Color(g.r,g.g,g.b,0), Color(g.r,g.g,g.b,0), Color(g.r,g.g,g.b,0.55)])
		)
	)
	ctrl.queue_redraw()
	return ctrl


func _Renderizar_Cover(pagina: Dictionary):
	var c = _book_container

	var cover_bg = ColorRect.new()
	cover_bg.color = Color(0.494, 0.118, 0.118)
	cover_bg.anchor_left = 0; cover_bg.anchor_right = 1; cover_bg.anchor_top = 0; cover_bg.anchor_bottom = 1
	c.add_child(cover_bg)

	var overlay = Control.new()
	overlay.anchor_left = 0; overlay.anchor_right = 1; overlay.anchor_top = 0; overlay.anchor_bottom = 1
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(overlay)
	overlay.draw.connect(func():
		var w = overlay.size.x; var h = overlay.size.y
		var dark = Color(0.118, 0.024, 0.024)
		var mid = Color(0.618, 0.157, 0.157)
		overlay.draw_polygon(
			PackedVector2Array([Vector2(0,0), Vector2(w,0), Vector2(w,h), Vector2(0,h)]),
			PackedColorArray([dark, mid, dark, mid])
		)
	)
	overlay.queue_redraw()

	var bos = StyleBoxFlat.new()
	bos.bg_color = Color(0,0,0,0)
	bos.border_width_left = 3; bos.border_width_top = 3
	bos.border_width_right = 3; bos.border_width_bottom = 3
	bos.border_color = Color(0.961, 0.839, 0.541, 0.32)
	var border_outer = Panel.new()
	border_outer.anchor_left = 0; border_outer.anchor_right = 1; border_outer.anchor_top = 0; border_outer.anchor_bottom = 1
	border_outer.offset_left = 27; border_outer.offset_right = -27; border_outer.offset_top = 27; border_outer.offset_bottom = -27
	border_outer.add_theme_stylebox_override("panel", bos)
	border_outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(border_outer)

	var bis = StyleBoxFlat.new()
	bis.bg_color = Color(0,0,0,0)
	bis.border_width_left = 1; bis.border_width_top = 1
	bis.border_width_right = 1; bis.border_width_bottom = 1
	bis.border_color = Color(0.961, 0.839, 0.541, 0.14)
	var border_inner = Panel.new()
	border_inner.anchor_left = 0; border_inner.anchor_right = 1; border_inner.anchor_top = 0; border_inner.anchor_bottom = 1
	border_inner.offset_left = 39; border_inner.offset_right = -39; border_inner.offset_top = 39; border_inner.offset_bottom = -39
	border_inner.add_theme_stylebox_override("panel", bis)
	border_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(border_inner)

	var vbox = VBoxContainer.new()
	vbox.anchor_left = 0; vbox.anchor_right = 1; vbox.anchor_top = 0; vbox.anchor_bottom = 1
	vbox.offset_left = 50; vbox.offset_right = -50
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 22)
	c.add_child(vbox)

	var eyebrow_raw = _carrera_nombre.to_upper() + " · AÑO " + str(_año)
	var eyebrow_spaced = ""
	for i in range(eyebrow_raw.length()):
		eyebrow_spaced += eyebrow_raw[i]
		if i < eyebrow_raw.length() - 1:
			eyebrow_spaced += " "
	var eyebrow = Label.new()
	eyebrow.text = eyebrow_spaced
	eyebrow.add_theme_font_size_override("font_size", 18)
	eyebrow.add_theme_color_override("font_color", Color(0.961, 0.839, 0.541, 0.55))
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	eyebrow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(eyebrow)

	var emoji_lbl = Label.new()
	emoji_lbl.text = "💻"
	emoji_lbl.add_theme_font_size_override("font_size", 110)
	emoji_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(emoji_lbl)

	vbox.add_child(_Crear_Divisor_Gradiente(300))

	var title_lbl = Label.new()
	title_lbl.text = pagina.title.to_upper()
	title_lbl.add_theme_font_size_override("font_size", 48)
	title_lbl.add_theme_color_override("font_color", Color(0.961, 0.839, 0.541))
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(title_lbl)

	vbox.add_child(_Crear_Divisor_Gradiente(300))

	var subtitle_lbl = Label.new()
	subtitle_lbl.text = "Apuntes del curso"
	subtitle_lbl.add_theme_font_size_override("font_size", 28)
	subtitle_lbl.add_theme_color_override("font_color", Color(0.961, 0.839, 0.541, 0.72))
	subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle_lbl)

	var footer = Label.new()
	footer.text = "UNIDAD " + str(_año)
	footer.add_theme_font_size_override("font_size", 22)
	footer.add_theme_color_override("font_color", Color(0.961, 0.839, 0.541, 0.38))
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.anchor_left = 0; footer.anchor_right = 1; footer.anchor_top = 1; footer.anchor_bottom = 1
	footer.offset_top = -60; footer.offset_bottom = -24
	c.add_child(footer)


func _Renderizar_Contenido(pagina: Dictionary):
	var c = _book_container

	var page_bg = ColorRect.new()
	page_bg.color = Color(0.996, 0.973, 0.933)
	page_bg.anchor_left = 0; page_bg.anchor_right = 1; page_bg.anchor_top = 0; page_bg.anchor_bottom = 1
	c.add_child(page_bg)

	var ruled = Control.new()
	ruled.anchor_left = 0; ruled.anchor_right = 1; ruled.anchor_top = 0; ruled.anchor_bottom = 1
	ruled.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(ruled)
	ruled.draw.connect(func():
		var w = ruled.size.x
		var line_color = Color(0.314, 0.471, 0.784, 0.065)
		var y = 127.0
		while y < ruled.size.y:
			ruled.draw_line(Vector2(0, y), Vector2(w, y), line_color, 2.0)
			y += 61.0
	)
	ruled.queue_redraw()

	var margin_line = ColorRect.new()
	margin_line.color = Color(0.824, 0.275, 0.275, 0.18)
	margin_line.anchor_left = 0; margin_line.anchor_right = 0; margin_line.anchor_top = 0; margin_line.anchor_bottom = 1
	margin_line.offset_left = 91; margin_line.offset_right = 93
	c.add_child(margin_line)

	var vbox = VBoxContainer.new()
	vbox.anchor_left = 0; vbox.anchor_right = 1; vbox.anchor_top = 0; vbox.anchor_bottom = 1
	vbox.offset_left = 110; vbox.offset_right = -18; vbox.offset_bottom = -18
	c.add_child(vbox)

	var header_style = StyleBoxFlat.new()
	header_style.bg_color = Color(0, 0, 0, 0)
	header_style.border_width_bottom = 2
	header_style.border_color = Color(0.667, 0.471, 0.235, 0.18)
	header_style.content_margin_left = 0; header_style.content_margin_top = 18
	header_style.content_margin_right = 0; header_style.content_margin_bottom = 18
	var header_panel = PanelContainer.new()
	header_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_panel.add_theme_stylebox_override("panel", header_style)
	vbox.add_child(header_panel)

	var header_vbox = VBoxContainer.new()
	header_vbox.add_theme_constant_override("separation", 4)
	header_panel.add_child(header_vbox)

	var chapter_lbl = Label.new()
	chapter_lbl.text = pagina.chapter.to_upper()
	chapter_lbl.add_theme_font_size_override("font_size", 23)
	chapter_lbl.add_theme_color_override("font_color", Color(0.431, 0.235, 0.059, 0.5))
	header_vbox.add_child(chapter_lbl)

	var section_lbl = Label.new()
	section_lbl.text = pagina.title
	section_lbl.add_theme_font_size_override("font_size", 36)
	section_lbl.add_theme_color_override("font_color", Color(0.416, 0.165, 0.031))
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
	body_lbl.add_theme_font_size_override("normal_font_size", 28)
	body_lbl.add_theme_color_override("default_color", Color(0.157, 0.094, 0.031))
	body_lbl.add_theme_constant_override("line_separation", 8)
	scroll.add_child(body_lbl)

	var curl_size = 50.0
	var curl = Control.new()
	curl.anchor_left = 1; curl.anchor_right = 1; curl.anchor_top = 1; curl.anchor_bottom = 1
	curl.offset_left = -curl_size; curl.offset_right = 0; curl.offset_top = -curl_size; curl.offset_bottom = 0
	curl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(curl)
	curl.draw.connect(func():
		var s = curl_size
		curl.draw_polygon(
			PackedVector2Array([Vector2(s,0), Vector2(0,s), Vector2(s,s)]),
			PackedColorArray([Color(0.910,0.835,0.690), Color(0.910,0.835,0.690), Color(0.910,0.835,0.690)])
		)
		curl.draw_polygon(
			PackedVector2Array([Vector2(s,0), Vector2(0,s), Vector2(s,s)]),
			PackedColorArray([Color(0,0,0,0.12), Color(0,0,0,0), Color(0,0,0,0)])
		)
	)
	curl.queue_redraw()
