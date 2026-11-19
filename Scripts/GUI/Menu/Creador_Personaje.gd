extends CanvasLayer
## Pantalla estilo Los Sims para personalizar el personaje antes de empezar la partida.
## Permite elegir género (hombre/mujer), nombre, color de piel, peinado, color de pelo,
## color de ojos, gafas, vello facial, pecas y color de ropa, además de generar un
## personaje completamente aleatorio con un toque.

signal confirmado(apariencia: Dictionary, origen_boton: Vector2)
signal cancelado

var _apariencia: Dictionary = Apariencia_Personaje.por_defecto()
var _tab_activa: String = "basico"
var _ver_cuerpo: bool = false
var _cerrado: bool = false

var _raiz: Control
var _preview: Personaje_Visual
var _mini_retrato: Personaje_Visual
var _lbl_resumen: Label
var _btn_vista: Button
var _tab_botones: Dictionary = {}
var _panel_contenido: VBoxContainer
var _scroll: ScrollContainer
var _input_nombre: LineEdit
var _tween_pop: Tween


func _init(apariencia_inicial: Dictionary = {}) -> void:
	if apariencia_inicial.is_empty():
		_apariencia = Apariencia_Personaje.por_defecto()
	else:
		_apariencia = Apariencia_Personaje.normalizar(apariencia_inicial)


func _ready() -> void:
	layer = 108
	_construir()
	_animar_entrada()


# ---------------------------------------------------------------- construcción UI

func _construir() -> void:
	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_raiz)

	var fondo := ColorRect.new()
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.color = Estilos_UI.FONDO
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(fondo)

	_construir_header()
	_construir_preview()
	_construir_tabs()
	_construir_area_opciones()
	_construir_barra_inferior()
	_renderizar_tab()


func _construir_header() -> void:
	var banda := Estilos_UI.BannerRayasBitLife.new(Estilos_UI.ROJO_BIT, Estilos_UI.ROJO_BIT_OSCURO, 3.0, 0.065)
	banda.position = Vector2.ZERO
	banda.size = Vector2(720, 74)
	_raiz.add_child(banda)

	var borde := ColorRect.new()
	borde.color = Estilos_UI.ROJO_BIT_OSCURO
	borde.position = Vector2(0, 71)
	borde.size = Vector2(720, 3)
	borde.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(borde)

	var row := HBoxContainer.new()
	row.position = Vector2(18, 12)
	row.size = Vector2(684, 50)
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_raiz.add_child(row)

	var btn_volver := Estilos_UI.boton_icono("arrow-left", Estilos_UI.TINTA, 42)
	btn_volver.tooltip_text = "Volver al menú"
	btn_volver.pressed.connect(_cancelar)
	row.add_child(btn_volver)

	var tit_col := VBoxContainer.new()
	tit_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tit_col.alignment = BoxContainer.ALIGNMENT_CENTER
	tit_col.add_theme_constant_override("separation", 0)
	row.add_child(tit_col)

	var lbl_tit := Estilos_UI.titulo("Crear personaje", 22, Color.WHITE)
	lbl_tit.add_theme_color_override("font_shadow_color", Color(0.35, 0.04, 0.04, 0.45))
	lbl_tit.add_theme_constant_override("shadow_offset_y", 2)
	tit_col.add_child(lbl_tit)

	var lbl_sub := Estilos_UI.texto("Personaliza tu protagonista antes de empezar", 12, Color("#fee2e2"), 500)
	tit_col.add_child(lbl_sub)

	var btn_rand_top := Estilos_UI.boton("Aleatorio", "oro", "sparkles", Estilos_UI.ORO, 40)
	btn_rand_top.custom_minimum_size = Vector2(134, 40)
	btn_rand_top.add_theme_font_size_override("font_size", 14)
	btn_rand_top.pressed.connect(_on_aleatorio)
	row.add_child(btn_rand_top)


func _construir_preview() -> void:
	var card := PanelContainer.new()
	card.position = Vector2(20, 88)
	card.size = Vector2(680, 344)
	card.clip_contents = true
	card.add_theme_stylebox_override("panel", Estilos_UI.caja_tarjeta(18, 3))
	_raiz.add_child(card)

	var escenario := Control.new()
	escenario.custom_minimum_size = Vector2(680, 344)
	escenario.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(escenario)

	# Fondo sunburst estilo cómic detrás del personaje
	var fondo_preview := Personaje_Visual.new(_apariencia, "busto")
	fondo_preview.name = "PreviewPersonaje"
	fondo_preview.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo_preview.expresion = "feliz"
	fondo_preview.pose = "idle"
	fondo_preview.animar_idle = true
	fondo_preview.dibujar_fondo_sunburst = true
	fondo_preview.color_fondo_base = Color("#e0f2fe")
	fondo_preview.color_fondo_rayo = Color("#bae6fd")
	fondo_preview.pivot_offset = Vector2(340, 172)
	escenario.add_child(fondo_preview)
	_preview = fondo_preview

	# Pill superior izquierda: resumen de género y nombre
	var pill_wrap := PanelContainer.new()
	pill_wrap.position = Vector2(14, 14)
	pill_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st_p := Estilos_UI.caja(Color(1, 1, 1, 0.94), 999, Color("#cbd5e1"), 1, 1)
	st_p.content_margin_left = 12
	st_p.content_margin_right = 12
	st_p.content_margin_top = 6
	st_p.content_margin_bottom = 6
	pill_wrap.add_theme_stylebox_override("panel", st_p)
	escenario.add_child(pill_wrap)

	var pill_row := HBoxContainer.new()
	pill_row.add_theme_constant_override("separation", 6)
	pill_wrap.add_child(pill_row)
	pill_row.add_child(Estilos_UI.icono_rect("user-round", 15, Estilos_UI.ROJO_BIT))
	_lbl_resumen = Estilos_UI.texto("", 13, Estilos_UI.TINTA, 700)
	pill_row.add_child(_lbl_resumen)

	# Botón superior derecho: alternar vista Busto / Cuerpo entero
	_btn_vista = Estilos_UI.boton("Ver cuerpo", "secundario", "person-standing", Estilos_UI.TINTA, 36)
	_btn_vista.position = Vector2(522, 12)
	_btn_vista.size = Vector2(144, 36)
	_btn_vista.add_theme_font_size_override("font_size", 13)
	_btn_vista.pressed.connect(_on_alternar_vista)
	escenario.add_child(_btn_vista)

	# Mini preview inferior izquierda: cómo se verá el icono circular arriba a la izquierda
	var mini_card := PanelContainer.new()
	mini_card.position = Vector2(14, 266)
	mini_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st_mc := Estilos_UI.caja(Color(1, 1, 1, 0.94), 14, Color("#cbd5e1"), 1, 1)
	st_mc.content_margin_left = 8
	st_mc.content_margin_right = 12
	st_mc.content_margin_top = 6
	st_mc.content_margin_bottom = 6
	mini_card.add_theme_stylebox_override("panel", st_mc)
	escenario.add_child(mini_card)

	var mini_row := HBoxContainer.new()
	mini_row.add_theme_constant_override("separation", 8)
	mini_card.add_child(mini_row)

	var avatar_mini := Estilos_UI.avatar_personaje(46, Estilos_UI.ROJO_BIT, 2, _apariencia, false)
	mini_row.add_child(avatar_mini)
	_mini_retrato = avatar_mini.find_child("Retrato", true, false) as Personaje_Visual

	var mini_txt := VBoxContainer.new()
	mini_txt.alignment = BoxContainer.ALIGNMENT_CENTER
	mini_txt.add_theme_constant_override("separation", 0)
	mini_row.add_child(mini_txt)
	mini_txt.add_child(Estilos_UI.texto("TU ICONO", 10, Estilos_UI.TINTA_FANTASMA, 700))
	mini_txt.add_child(Estilos_UI.texto("En pantalla", 12, Estilos_UI.TINTA, 600))

	_actualizar_resumen()


func _construir_tabs() -> void:
	var track := Panel.new()
	track.position = Vector2(20, 446)
	track.size = Vector2(680, 48)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_theme_stylebox_override("panel", Estilos_UI.caja(Color("#e2e8f0"), 13, Color(0, 0, 0, 0), 0, 0))
	_raiz.add_child(track)

	var bar := HBoxContainer.new()
	bar.position = Vector2(24, 450)
	bar.size = Vector2(672, 40)
	bar.add_theme_constant_override("separation", 5)
	_raiz.add_child(bar)

	var specs := [
		["basico", "Básico", "user-round"],
		["pelo", "Pelo", "sparkles"],
		["cara", "Cara", "smile"],
		["ropa", "Ropa", "shirt"],
	]
	for s in specs:
		var id_tab: String = s[0]
		var btn := Button.new()
		btn.set_meta("_tema_aplicado", true)
		btn.set_meta("_estilo_propio", true)
		btn.text = s[1]
		btn.icon = Estilos_UI.icono(s[2])
		btn.expand_icon = false
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 40)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.add_theme_font_override("font", Estilos_UI.fuente_ui(700))
		btn.add_theme_font_size_override("font_size", 14)
		btn.add_theme_constant_override("icon_max_width", 16)
		btn.add_theme_constant_override("h_separation", 6)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		btn.pressed.connect(func(): _cambiar_tab(id_tab))
		bar.add_child(btn)
		_tab_botones[id_tab] = btn

	_estilizar_tabs()


func _construir_area_opciones() -> void:
	var card := PanelContainer.new()
	card.position = Vector2(20, 506)
	card.size = Vector2(680, 666)
	card.add_theme_stylebox_override("panel", Estilos_UI.caja_tarjeta(18, 2))
	_raiz.add_child(card)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 20)
	m.add_theme_constant_override("margin_right", 20)
	m.add_theme_constant_override("margin_top", 18)
	m.add_theme_constant_override("margin_bottom", 18)
	card.add_child(m)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	m.add_child(_scroll)

	_panel_contenido = VBoxContainer.new()
	_panel_contenido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel_contenido.add_theme_constant_override("separation", 18)
	_scroll.add_child(_panel_contenido)


func _construir_barra_inferior() -> void:
	var dock := Panel.new()
	dock.position = Vector2(0, 1184)
	dock.size = Vector2(720, 96)
	var st := Estilos_UI.caja(Estilos_UI.SUPERFICIE, 0, Estilos_UI.BORDE, 0, 2)
	st.border_width_top = 2
	dock.add_theme_stylebox_override("panel", st)
	_raiz.add_child(dock)

	var row := HBoxContainer.new()
	row.position = Vector2(20, 18)
	row.size = Vector2(680, 58)
	row.add_theme_constant_override("separation", 12)
	dock.add_child(row)

	var btn_rand := Estilos_UI.boton("Aleatorio", "secundario", "sparkles", Estilos_UI.TINTA, 56)
	btn_rand.custom_minimum_size = Vector2(210, 56)
	btn_rand.add_theme_font_size_override("font_size", 16)
	btn_rand.pressed.connect(_on_aleatorio)
	row.add_child(btn_rand)

	var btn_empezar := Estilos_UI.boton("¡Empezar vida!", "exito", "play", Estilos_UI.EXITO, 56)
	btn_empezar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_empezar.add_theme_font_override("font", Estilos_UI.fuente_titulo(700))
	btn_empezar.add_theme_font_size_override("font_size", 19)
	btn_empezar.pressed.connect(func():
		var centro := btn_empezar.get_global_rect().get_center()
		_confirmar(centro))
	row.add_child(btn_empezar)


# ---------------------------------------------------------------- render de pestañas

func _cambiar_tab(id_tab: String) -> void:
	if _tab_activa == id_tab:
		return
	_tab_activa = id_tab
	_estilizar_tabs()
	_renderizar_tab()
	_scroll.scroll_vertical = 0


func _estilizar_tabs() -> void:
	for id_tab in _tab_botones.keys():
		var btn: Button = _tab_botones[id_tab]
		var activo: bool = (id_tab == _tab_activa)
		var st_n := Estilos_UI.caja(
			Estilos_UI.SUPERFICIE if activo else Color(0, 0, 0, 0),
			10,
			Estilos_UI.BORDE if activo else Color(0, 0, 0, 0),
			1 if activo else 0,
			1 if activo else 0
		)
		var st_h := Estilos_UI.caja(
			Estilos_UI.SUPERFICIE if activo else Color(1, 1, 1, 0.55),
			10, Color(0, 0, 0, 0), 0, 0
		)
		var col := Estilos_UI.ROJO_BIT if activo else Estilos_UI.TINTA_SUAVE
		btn.add_theme_stylebox_override("normal", st_n)
		btn.add_theme_stylebox_override("hover", st_h)
		btn.add_theme_stylebox_override("pressed", st_n)
		for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color",
				"icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
			btn.add_theme_color_override(k, col)


func _renderizar_tab() -> void:
	for hijo in _panel_contenido.get_children():
		hijo.queue_free()
	_input_nombre = null

	match _tab_activa:
		"basico":
			_construir_tab_basico()
		"pelo":
			_construir_tab_pelo()
		"cara":
			_construir_tab_cara()
		"ropa":
			_construir_tab_ropa()


func _construir_tab_basico() -> void:
	_agregar_titulo_seccion("Género")
	var row_gen := HBoxContainer.new()
	row_gen.add_theme_constant_override("separation", 12)
	_panel_contenido.add_child(row_gen)

	for g in Apariencia_Personaje.GENEROS:
		var id_g: String = g["id"]
		var activo: bool = (_apariencia["genero"] == id_g)
		var btn := _crear_boton_opcion(g["nombre"], activo, 56)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func(): _on_seleccionar_genero(id_g))
		row_gen.add_child(btn)

	_agregar_titulo_seccion("Nombre (opcional)")
	var row_nom := HBoxContainer.new()
	row_nom.add_theme_constant_override("separation", 10)
	_panel_contenido.add_child(row_nom)

	_input_nombre = LineEdit.new()
	_input_nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input_nombre.custom_minimum_size = Vector2(0, 48)
	_input_nombre.max_length = 20
	_input_nombre.placeholder_text = "Ej. Alex, Lucía, Mateo..."
	_input_nombre.text = str(_apariencia.get("nombre", ""))
	_input_nombre.add_theme_font_override("font", Estilos_UI.fuente_ui(600))
	_input_nombre.add_theme_font_size_override("font_size", 15)
	_input_nombre.add_theme_color_override("font_color", Estilos_UI.TINTA)
	_input_nombre.add_theme_color_override("font_placeholder_color", Estilos_UI.TINTA_FANTASMA)
	var st_le := Estilos_UI.caja(Estilos_UI.SUPERFICIE_2, 12, Estilos_UI.BORDE_FUERTE, 1, 0)
	st_le.content_margin_left = 14
	st_le.content_margin_right = 14
	var st_le_f := Estilos_UI.caja(Estilos_UI.SUPERFICIE, 12, Estilos_UI.ROJO_BIT, 2, 0)
	st_le_f.content_margin_left = 14
	st_le_f.content_margin_right = 14
	_input_nombre.add_theme_stylebox_override("normal", st_le)
	_input_nombre.add_theme_stylebox_override("focus", st_le_f)
	_input_nombre.text_changed.connect(func(nuevo: String):
		_apariencia["nombre"] = nuevo.strip_edges().left(20)
		_actualizar_resumen())
	row_nom.add_child(_input_nombre)

	var btn_nom_rand := Estilos_UI.boton("Sugerir", "secundario", "sparkles", Estilos_UI.TINTA, 48)
	btn_nom_rand.custom_minimum_size = Vector2(128, 48)
	btn_nom_rand.add_theme_font_size_override("font_size", 14)
	btn_nom_rand.pressed.connect(func():
		var nom := Apariencia_Personaje.nombre_aleatorio(_apariencia["genero"])
		_apariencia["nombre"] = nom
		if _input_nombre != null and is_instance_valid(_input_nombre):
			_input_nombre.text = nom
		_actualizar_resumen())
	row_nom.add_child(btn_nom_rand)

	_agregar_titulo_seccion("Tono de piel")
	_agregar_paleta_colores(Apariencia_Personaje.COLORES_PIEL, "color_piel", 4)


func _construir_tab_pelo() -> void:
	_agregar_titulo_seccion("Estilo de peinado")
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	_panel_contenido.add_child(grid)

	for item in Apariencia_Personaje.ESTILOS_PELO:
		var id_pelo: String = item["id"]
		var activo: bool = (_apariencia["estilo_pelo"] == id_pelo)
		var btn := _crear_boton_opcion(item["nombre"], activo, 48)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func():
			_apariencia["estilo_pelo"] = id_pelo
			_aplicar_cambio(true))
		grid.add_child(btn)

	_agregar_titulo_seccion("Color de pelo")
	_agregar_paleta_colores(Apariencia_Personaje.COLORES_PELO, "color_pelo", 5)


func _construir_tab_cara() -> void:
	_agregar_titulo_seccion("Color de ojos")
	_agregar_paleta_colores(Apariencia_Personaje.COLORES_OJOS, "color_ojos", 4)

	_agregar_titulo_seccion("Gafas")
	var row_g := HBoxContainer.new()
	row_g.add_theme_constant_override("separation", 10)
	_panel_contenido.add_child(row_g)
	for item in Apariencia_Personaje.ESTILOS_GAFAS:
		var id_g: String = item["id"]
		var activo: bool = (_apariencia["gafas"] == id_g)
		var btn := _crear_boton_opcion(item["nombre"], activo, 46)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func():
			_apariencia["gafas"] = id_g
			_aplicar_cambio(true))
		row_g.add_child(btn)

	if _apariencia["genero"] == "hombre":
		_agregar_titulo_seccion("Vello facial")
		var grid_v := GridContainer.new()
		grid_v.columns = 2
		grid_v.add_theme_constant_override("h_separation", 10)
		grid_v.add_theme_constant_override("v_separation", 10)
		_panel_contenido.add_child(grid_v)
		for item in Apariencia_Personaje.ESTILOS_VELLO:
			var id_v: String = item["id"]
			var activo: bool = (_apariencia["vello_facial"] == id_v)
			var btn := _crear_boton_opcion(item["nombre"], activo, 44)
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.pressed.connect(func():
				_apariencia["vello_facial"] = id_v
				_aplicar_cambio(true))
			grid_v.add_child(btn)

	_agregar_titulo_seccion("Detalles")
	var pecas_activas := bool(_apariencia.get("pecas", false))
	var row_p := HBoxContainer.new()
	row_p.add_theme_constant_override("separation", 10)
	_panel_contenido.add_child(row_p)

	var btn_sin := _crear_boton_opcion("Sin pecas", not pecas_activas, 46)
	btn_sin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_sin.pressed.connect(func():
		_apariencia["pecas"] = false
		_aplicar_cambio(true))
	row_p.add_child(btn_sin)

	var btn_con := _crear_boton_opcion("Con pecas", pecas_activas, 46)
	btn_con.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_con.pressed.connect(func():
		_apariencia["pecas"] = true
		_aplicar_cambio(true))
	row_p.add_child(btn_con)


func _construir_tab_ropa() -> void:
	_agregar_titulo_seccion("Color de sudadera")
	_agregar_paleta_colores(Apariencia_Personaje.COLORES_ROPA, "color_ropa", 4)

	var nota_card := PanelContainer.new()
	var st := Estilos_UI.caja(Estilos_UI.AZUL_SUAVE, 14, Color(Estilos_UI.AZUL, 0.22), 1, 0)
	st.content_margin_left = 14
	st.content_margin_right = 14
	st.content_margin_top = 12
	st.content_margin_bottom = 12
	nota_card.add_theme_stylebox_override("panel", st)
	_panel_contenido.add_child(nota_card)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	nota_card.add_child(row)
	row.add_child(Estilos_UI.icono_rect("sparkles", 20, Estilos_UI.AZUL))
	var txt := Estilos_UI.parrafo(
		"Este será el aspecto con el que aparecerás en la historia inicial y en tu icono de la barra superior.",
		13, Estilos_UI.TINTA_SUAVE)
	txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(txt)


# ---------------------------------------------------------------- componentes reutilizables

func _agregar_titulo_seccion(texto_sec: String) -> void:
	var lbl := Estilos_UI.texto(texto_sec.to_upper(), 12, Estilos_UI.TINTA_FANTASMA, 700)
	_panel_contenido.add_child(lbl)


func _agregar_paleta_colores(paleta: Array[Dictionary], clave: String, columnas: int) -> void:
	var grid := GridContainer.new()
	grid.columns = columnas
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	_panel_contenido.add_child(grid)

	var hex_actual := str(_apariencia.get(clave, "")).to_lower()
	for item in paleta:
		var hex: String = item["hex"]
		var nombre: String = item["nombre"]
		var col := Color.html(hex)
		var activo := (hex.to_lower() == hex_actual)

		var celda := VBoxContainer.new()
		celda.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		celda.alignment = BoxContainer.ALIGNMENT_CENTER
		celda.add_theme_constant_override("separation", 5)
		grid.add_child(celda)

		var btn := Button.new()
		btn.set_meta("_tema_aplicado", true)
		btn.set_meta("_estilo_propio", true)
		btn.custom_minimum_size = Vector2(54, 54)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.tooltip_text = nombre
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER

		var st := StyleBoxFlat.new()
		st.bg_color = col
		st.set_corner_radius_all(999)
		st.anti_aliasing = true
		if activo:
			st.border_color = Estilos_UI.ROJO_BIT
			st.set_border_width_all(4)
			st.shadow_color = Color(Estilos_UI.ROJO_BIT, 0.30)
			st.shadow_size = 5
		else:
			st.border_color = Color("#cbd5e1")
			st.set_border_width_all(2)

		var st_hov := st.duplicate() as StyleBoxFlat
		st_hov.border_color = Estilos_UI.TINTA if not activo else Estilos_UI.ROJO_BIT

		btn.add_theme_stylebox_override("normal", st)
		btn.add_theme_stylebox_override("hover", st_hov)
		btn.add_theme_stylebox_override("pressed", st)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

		if activo:
			btn.icon = Estilos_UI.icono("check")
			btn.expand_icon = false
			btn.add_theme_constant_override("icon_max_width", 22)
			var col_check := Estilos_UI.TINTA if col.get_luminance() > 0.62 else Color.WHITE
			for k in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
				btn.add_theme_color_override(k, col_check)

		Estilos_UI.animar_presion(btn)
		btn.pressed.connect(func():
			_apariencia[clave] = hex
			_aplicar_cambio(true))
		celda.add_child(btn)

		var lbl := Estilos_UI.texto(nombre, 11, Estilos_UI.ROJO_BIT if activo else Estilos_UI.TINTA_SUAVE, 700 if activo else 500)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		celda.add_child(lbl)


func _crear_boton_opcion(etiqueta: String, activo: bool, alto: int = 48) -> Button:
	var btn := Button.new()
	btn.set_meta("_tema_aplicado", true)
	btn.set_meta("_estilo_propio", true)
	btn.text = etiqueta
	btn.custom_minimum_size = Vector2(0, alto)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_override("font", Estilos_UI.fuente_ui(700 if activo else 600))
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	var st_n := Estilos_UI.caja(
		Estilos_UI.ROJO_BIT_SUAVE if activo else Estilos_UI.SUPERFICIE_2,
		12,
		Estilos_UI.ROJO_BIT if activo else Estilos_UI.BORDE,
		2 if activo else 1,
		0
	)
	var st_h := Estilos_UI.caja(
		Estilos_UI.ROJO_BIT_SUAVE if activo else Estilos_UI.SUPERFICIE,
		12,
		Estilos_UI.ROJO_BIT if activo else Estilos_UI.BORDE_FUERTE,
		2 if activo else 1,
		0
	)
	var col_txt := Estilos_UI.ROJO_BIT if activo else Estilos_UI.TINTA
	btn.add_theme_stylebox_override("normal", st_n)
	btn.add_theme_stylebox_override("hover", st_h)
	btn.add_theme_stylebox_override("pressed", st_n)
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		btn.add_theme_color_override(k, col_txt)

	if activo:
		btn.icon = Estilos_UI.icono("check")
		btn.expand_icon = false
		btn.add_theme_constant_override("icon_max_width", 16)
		btn.add_theme_constant_override("h_separation", 8)
		for k in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
			btn.add_theme_color_override(k, Estilos_UI.ROJO_BIT)

	Estilos_UI.animar_presion(btn)
	return btn


# ---------------------------------------------------------------- acciones y animaciones

func _on_seleccionar_genero(nuevo_genero: String) -> void:
	if _apariencia["genero"] == nuevo_genero:
		return
	_apariencia["genero"] = nuevo_genero
	if nuevo_genero == "mujer":
		_apariencia["vello_facial"] = "ninguno"
		if _apariencia["estilo_pelo"] in ["alborotado", "corto", "rapado"]:
			_apariencia["estilo_pelo"] = "largo"
	else:
		if _apariencia["estilo_pelo"] in ["largo", "media_melena", "coleta", "mono"]:
			_apariencia["estilo_pelo"] = "alborotado"
	_aplicar_cambio(true)


func _on_aleatorio() -> void:
	_apariencia = Apariencia_Personaje.aleatoria()
	_aplicar_cambio(true)


func _on_alternar_vista() -> void:
	_ver_cuerpo = not _ver_cuerpo
	_preview.modo = "cuerpo_completo" if _ver_cuerpo else "busto"
	_btn_vista.text = "Ver cara" if _ver_cuerpo else "Ver cuerpo"
	_animar_pop_preview()


func _aplicar_cambio(reconstruir_tab: bool) -> void:
	_apariencia = Apariencia_Personaje.normalizar(_apariencia)
	_preview.apariencia = _apariencia
	if _mini_retrato != null and is_instance_valid(_mini_retrato):
		_mini_retrato.apariencia = _apariencia
	_actualizar_resumen()
	_animar_pop_preview()
	if reconstruir_tab:
		var scroll_y := _scroll.scroll_vertical
		_renderizar_tab()
		_scroll.call_deferred("set", "scroll_vertical", scroll_y)


func _actualizar_resumen() -> void:
	if _lbl_resumen == null:
		return
	var nom := str(_apariencia.get("nombre", "")).strip_edges()
	var gen := Apariencia_Personaje.etiqueta_genero(_apariencia)
	_lbl_resumen.text = ("%s · %s" % [nom, gen]) if nom != "" else gen


func _animar_pop_preview() -> void:
	if _preview == null:
		return
	if _tween_pop != null and _tween_pop.is_valid():
		_tween_pop.kill()
	_preview.pivot_offset = _preview.size * 0.5
	_preview.scale = Vector2(0.93, 0.93)
	_tween_pop = create_tween()
	_tween_pop.tween_property(_preview, "scale", Vector2.ONE, 0.24) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _animar_entrada() -> void:
	_raiz.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_raiz, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _confirmar(origen_boton: Vector2) -> void:
	if _cerrado:
		return
	_cerrado = true
	var final_ap := Apariencia_Personaje.normalizar(_apariencia)
	confirmado.emit(final_ap, origen_boton)
	queue_free()


func _cancelar() -> void:
	if _cerrado:
		return
	_cerrado = true
	cancelado.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if _cerrado:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_cancelar()
