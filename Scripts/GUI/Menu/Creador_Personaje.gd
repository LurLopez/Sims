extends CanvasLayer
## Pantalla de creación de personaje (estilo Crear un Sim).
## Flujo guiado en 6 pasos: Identidad → Cuerpo → Cara → Pelo → Ropa → Extras.
## Incluye vista previa en vivo con cámara Cara/Busto/Cuerpo, prueba de poses,
## valor actual en cada sección y navegación Atrás/Siguiente.

signal confirmado(apariencia: Dictionary, origen_boton: Vector2)
signal cancelado

const PASOS: Array[Dictionary] = [
	{
		"id": "identidad", "nombre": "Identidad", "icono": "user-round",
		"titulo": "Identidad", "ayuda": "Ponle nombre, elige su género y define su carácter.",
		"vista": "busto",
	},
	{
		"id": "cuerpo", "nombre": "Cuerpo", "icono": "person-standing",
		"titulo": "Cuerpo y piel", "ayuda": "Ajusta la complexión y el tono de piel de tu Sim.",
		"vista": "cuerpo_completo",
	},
	{
		"id": "cara", "nombre": "Cara", "icono": "smile",
		"titulo": "Rasgos de la cara", "ayuda": "Da forma a los ojos, la nariz, la boca y las cejas.",
		"vista": "retrato_cercano",
	},
	{
		"id": "pelo", "nombre": "Pelo", "icono": "sparkles",
		"titulo": "Pelo y vello facial", "ayuda": "Elige el peinado, su color y el vello facial.",
		"vista": "retrato_cercano",
	},
	{
		"id": "ropa", "nombre": "Ropa", "icono": "shirt",
		"titulo": "Ropa y calzado", "ayuda": "Combina prendas, colores y zapatillas a tu gusto.",
		"vista": "cuerpo_completo",
	},
	{
		"id": "extras", "nombre": "Extras", "icono": "gem",
		"titulo": "Detalles finales", "ayuda": "Añade accesorios y maquillaje. Pulsa «¡Empezar vida!» cuando estés listo.",
		"vista": "retrato_cercano",
	},
]

## Descripciones breves para las tarjetas de personalidad.
const DESC_PERSONALIDAD_CORTA: Dictionary = {
	"": "Se asigna al azar",
	"Trabajador_Compulsivo": "Estudia y persigue metas",
	"Deportista": "Activo y amante del deporte",
	"Culo_Del_Sofa": "Disfruta de la tele en casa",
}

var _apariencia: Dictionary = Apariencia_Personaje.por_defecto()
var _paso: int = 0
var _modo_vista: String = "busto" # "retrato_cercano", "busto", "cuerpo_completo"
var _pose_preview: String = "idle"
var _expr_preview: String = "feliz"
var _variacion_preview: String = ""
var _cerrado: bool = false

var _raiz: Control
var _card_opciones: PanelContainer
var _dock_inferior: Panel
var _preview: Personaje_Visual
var _mini_retrato: Personaje_Visual
var _lbl_resumen: Label
var _vista_botones: Dictionary = {}
var _pose_botones: Dictionary = {}
var _tab_botones: Dictionary = {}
var _panel_contenido: VBoxContainer
var _scroll: ScrollContainer
var _input_nombre: LineEdit
var _tween_pop: Tween
var _lbl_paso_pill: Label
var _lbl_paso_titulo: Label
var _lbl_paso_ayuda: Label
var _barra_paso: ProgressBar
var _btn_atras: Button
var _btn_siguiente: Button


func _init(apariencia_inicial: Dictionary = {}) -> void:
	if apariencia_inicial.is_empty():
		_apariencia = Apariencia_Personaje.por_defecto()
	else:
		_apariencia = Apariencia_Personaje.normalizar(apariencia_inicial)


func _ready() -> void:
	layer = 108
	_construir()
	get_viewport().size_changed.connect(_reubicar_layout)
	_animar_entrada()


func _alto_pantalla() -> float:
	var alto: float = get_viewport().get_visible_rect().size.y
	return alto if alto >= 1280.0 else 1280.0


func _paso_actual() -> Dictionary:
	return PASOS[clampi(_paso, 0, PASOS.size() - 1)]


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
	_reubicar_layout()
	_actualizar_encabezado_paso(false)
	_actualizar_navegacion()
	_estilizar_tabs()
	_renderizar_paso()


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

	var lbl_sub := Estilos_UI.texto("Diseña a tu Sim en 6 pasos", 12, Color("#fee2e2"), 500)
	tit_col.add_child(lbl_sub)

	var btn_rand_top := Estilos_UI.boton("Aleatorio", "oro", "sparkles", Estilos_UI.ORO, 40)
	btn_rand_top.custom_minimum_size = Vector2(134, 40)
	btn_rand_top.add_theme_font_size_override("font_size", 14)
	btn_rand_top.tooltip_text = "Genera un Sim completo al azar"
	btn_rand_top.pressed.connect(_on_aleatorio)
	row.add_child(btn_rand_top)


func _construir_preview() -> void:
	var card := PanelContainer.new()
	card.position = Vector2(20, 86)
	card.size = Vector2(680, 354)
	card.clip_contents = true
	card.add_theme_stylebox_override("panel", Estilos_UI.caja_tarjeta(18, 3))
	_raiz.add_child(card)

	var escenario := Control.new()
	escenario.custom_minimum_size = Vector2(680, 354)
	escenario.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(escenario)

	var fondo_preview := Personaje_Visual.new(_apariencia, _modo_vista)
	fondo_preview.name = "PreviewPersonaje"
	# El escenario del Sim ocupa solo la zona sobre la barra inferior, para que
	# la vista de cuerpo completo muestre también los pies y el calzado.
	fondo_preview.position = Vector2.ZERO
	fondo_preview.size = Vector2(680, 305)
	fondo_preview.expresion = _expr_preview
	fondo_preview.pose = _pose_preview
	fondo_preview.variacion = _variacion_preview
	# El creador siempre muestra al Sim recién creado (18 años), aunque se abra
	# después de una partida larga en la que el personaje anterior era mayor.
	fondo_preview.edad = Envejecimiento_Personaje.EDAD_MIN
	fondo_preview.animar_idle = true
	fondo_preview.dibujar_fondo_sunburst = true
	fondo_preview.color_fondo_base = Color("#e0f2fe")
	fondo_preview.color_fondo_rayo = Color("#bae6fd")
	fondo_preview.margen_retrato = 20.0
	fondo_preview.pivot_offset = Vector2(340, 152)
	escenario.add_child(fondo_preview)
	_preview = fondo_preview

	# Pill superior izquierda: resumen de nombre, género y rasgo.
	var pill_wrap := PanelContainer.new()
	pill_wrap.position = Vector2(14, 12)
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
	_lbl_resumen = Estilos_UI.texto("", 12, Estilos_UI.TINTA, 700)
	pill_row.add_child(_lbl_resumen)

	# Selector de cámara estilo Los Sims (Cara / Busto / Cuerpo).
	var cam_track := PanelContainer.new()
	cam_track.position = Vector2(440, 10)
	var st_cam := Estilos_UI.caja(Color(1, 1, 1, 0.94), 12, Color("#cbd5e1"), 1, 1)
	st_cam.content_margin_left = 4
	st_cam.content_margin_right = 4
	st_cam.content_margin_top = 4
	st_cam.content_margin_bottom = 4
	cam_track.add_theme_stylebox_override("panel", st_cam)
	escenario.add_child(cam_track)

	var cam_row := HBoxContainer.new()
	cam_row.add_theme_constant_override("separation", 4)
	cam_track.add_child(cam_row)
	for v_spec in [
		["retrato_cercano", "Cara"],
		["busto", "Busto"],
		["cuerpo_completo", "Cuerpo"],
	]:
		var vid: String = v_spec[0]
		var btn_v := Button.new()
		btn_v.set_meta("_tema_aplicado", true)
		btn_v.set_meta("_estilo_propio", true)
		btn_v.text = v_spec[1]
		btn_v.custom_minimum_size = Vector2(72, 30)
		btn_v.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn_v.add_theme_font_override("font", Estilos_UI.fuente_ui(700))
		btn_v.add_theme_font_size_override("font_size", 12)
		btn_v.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		btn_v.pressed.connect(func(): _cambiar_vista(vid))
		cam_row.add_child(btn_v)
		_vista_botones[vid] = btn_v
	_estilizar_botones_vista()

	_construir_dock_preview(escenario)
	_actualizar_resumen()


func _construir_dock_preview(escenario: Control) -> void:
	# Barra inferior del escenario: icono en juego + prueba de animaciones.
	var dock := Panel.new()
	dock.position = Vector2(0, 303)
	dock.size = Vector2(680, 60)
	var st := Estilos_UI.caja(Color.WHITE, 0, Color(0, 0, 0, 0), 0, 0)
	st.border_width_top = 1
	st.border_color = Color("#cbd5e1")
	dock.add_theme_stylebox_override("panel", st)
	escenario.add_child(dock)

	var fila := HBoxContainer.new()
	fila.position = Vector2(12, 7)
	fila.size = Vector2(656, 35)
	fila.add_theme_constant_override("separation", 8)
	dock.add_child(fila)

	var avatar_mini := Estilos_UI.avatar_personaje(34, Estilos_UI.ROJO_BIT, 2, _apariencia, false)
	fila.add_child(avatar_mini)
	_mini_retrato = avatar_mini.find_child("Retrato", true, false) as Personaje_Visual
	if _mini_retrato != null:
		_mini_retrato.edad = Envejecimiento_Personaje.EDAD_MIN

	var mini_txt := VBoxContainer.new()
	mini_txt.alignment = BoxContainer.ALIGNMENT_CENTER
	mini_txt.add_theme_constant_override("separation", 0)
	fila.add_child(mini_txt)
	mini_txt.add_child(Estilos_UI.texto("TU ICONO", 9, Estilos_UI.TINTA_FANTASMA, 700))
	mini_txt.add_child(Estilos_UI.texto("En juego", 11, Estilos_UI.TINTA, 600))

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(spacer)

	var lbl_probar := Estilos_UI.texto("PROBAR", 9, Estilos_UI.TINTA_FANTASMA, 800)
	lbl_probar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(lbl_probar)

	var pose_row := HBoxContainer.new()
	pose_row.add_theme_constant_override("separation", 4)
	pose_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(pose_row)
	for p_spec in [
		["feliz", "idle", "", "feliz", "Feliz"],
		["saludar", "idle", "saludar", "feliz", "Saludar"],
		["correr", "correr", "", "concentrado", "Correr"],
		["fiesta", "fiesta", "", "feliz", "Bailar"],
		["sorpresa", "sorpresa", "", "sorpresa", "Sorpresa"],
	]:
		var pid: String = p_spec[0]
		var btn_p := Button.new()
		btn_p.set_meta("_tema_aplicado", true)
		btn_p.set_meta("_estilo_propio", true)
		btn_p.text = p_spec[4]
		btn_p.custom_minimum_size = Vector2(60, 28)
		btn_p.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn_p.add_theme_font_override("font", Estilos_UI.fuente_ui(700))
		btn_p.add_theme_font_size_override("font_size", 10)
		btn_p.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		btn_p.pressed.connect(func(): _cambiar_pose_preview(pid, p_spec[1], p_spec[2], p_spec[3]))
		pose_row.add_child(btn_p)
		_pose_botones[pid] = btn_p
	_estilizar_botones_pose("feliz")


func _construir_tabs() -> void:
	var track := Panel.new()
	track.position = Vector2(20, 450)
	track.size = Vector2(680, 48)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_theme_stylebox_override("panel", Estilos_UI.caja(Color("#e2e8f0"), 13, Color(0, 0, 0, 0), 0, 0))
	_raiz.add_child(track)

	var bar := HBoxContainer.new()
	bar.position = Vector2(24, 454)
	bar.size = Vector2(672, 40)
	bar.add_theme_constant_override("separation", 4)
	_raiz.add_child(bar)

	for i in PASOS.size():
		var paso: Dictionary = PASOS[i]
		var id_tab: String = paso["id"]
		var btn := Button.new()
		btn.set_meta("_tema_aplicado", true)
		btn.set_meta("_estilo_propio", true)
		btn.text = ""
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 40)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		btn.pressed.connect(func(): _ir_a_paso(i))

		var hb := HBoxContainer.new()
		hb.name = "ContenidoTab"
		hb.set_anchors_preset(Control.PRESET_FULL_RECT)
		hb.alignment = BoxContainer.ALIGNMENT_CENTER
		hb.add_theme_constant_override("separation", 4)
		hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(hb)

		var ic := Estilos_UI.icono_rect(paso["icono"], 13, Estilos_UI.TINTA_SUAVE)
		ic.name = "IconoTab"
		hb.add_child(ic)

		var lbl := Estilos_UI.texto(paso["nombre"], 12, Estilos_UI.TINTA_SUAVE, 700)
		lbl.name = "LabelTab"
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_child(lbl)

		bar.add_child(btn)
		_tab_botones[id_tab] = btn


func _construir_area_opciones() -> void:
	_card_opciones = PanelContainer.new()
	_card_opciones.position = Vector2(20, 508)
	_card_opciones.size = Vector2(680, 664)
	_card_opciones.add_theme_stylebox_override("panel", Estilos_UI.caja_tarjeta(18, 2))
	_raiz.add_child(_card_opciones)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 20)
	m.add_theme_constant_override("margin_right", 20)
	m.add_theme_constant_override("margin_top", 16)
	m.add_theme_constant_override("margin_bottom", 16)
	_card_opciones.add_child(m)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	m.add_child(outer)

	# Encabezado fijo del paso: número, título, ayuda y progreso.
	var cab := VBoxContainer.new()
	cab.add_theme_constant_override("separation", 4)
	outer.add_child(cab)

	var fila_tit := HBoxContainer.new()
	fila_tit.add_theme_constant_override("separation", 10)
	cab.add_child(fila_tit)

	var pill := PanelContainer.new()
	pill.set_meta("_tema_aplicado", true)
	var st_pill := Estilos_UI.caja(Estilos_UI.ROJO_BIT_SUAVE, 999, Color(0, 0, 0, 0), 0, 0)
	st_pill.content_margin_left = 9
	st_pill.content_margin_right = 9
	st_pill.content_margin_top = 3
	st_pill.content_margin_bottom = 3
	pill.add_theme_stylebox_override("panel", st_pill)
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila_tit.add_child(pill)

	_lbl_paso_pill = Estilos_UI.texto("PASO 1 DE 6", 10, Estilos_UI.ROJO_BIT, 800)
	pill.add_child(_lbl_paso_pill)

	_lbl_paso_titulo = Estilos_UI.titulo("Identidad", 21, Estilos_UI.TINTA)
	_lbl_paso_titulo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila_tit.add_child(_lbl_paso_titulo)

	var relleno := Control.new()
	relleno.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	relleno.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila_tit.add_child(relleno)

	_lbl_paso_ayuda = Estilos_UI.texto("", 12, Estilos_UI.TINTA_SUAVE, 500)
	_lbl_paso_ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cab.add_child(_lbl_paso_ayuda)

	_barra_paso = ProgressBar.new()
	_barra_paso.show_percentage = false
	_barra_paso.custom_minimum_size = Vector2(0, 6)
	_barra_paso.max_value = PASOS.size()
	_barra_paso.value = 1
	_barra_paso.add_theme_stylebox_override("background", Estilos_UI.barra_fondo(3))
	_barra_paso.add_theme_stylebox_override("fill", Estilos_UI.barra_relleno(Estilos_UI.ROJO_BIT, 3))
	cab.add_child(_barra_paso)

	outer.add_child(Estilos_UI.divisor_horizontal())

	_scroll = ScrollContainer.new()
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(_scroll)

	_panel_contenido = VBoxContainer.new()
	_panel_contenido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel_contenido.add_theme_constant_override("separation", 12)
	_scroll.add_child(_panel_contenido)


func _construir_barra_inferior() -> void:
	_dock_inferior = Panel.new()
	_dock_inferior.position = Vector2(0, 1184)
	_dock_inferior.size = Vector2(720, 96)
	var st := Estilos_UI.caja(Estilos_UI.SUPERFICIE, 0, Estilos_UI.BORDE, 0, 2)
	st.border_width_top = 2
	_dock_inferior.add_theme_stylebox_override("panel", st)
	_raiz.add_child(_dock_inferior)

	var row := HBoxContainer.new()
	row.position = Vector2(20, 18)
	row.size = Vector2(680, 58)
	row.add_theme_constant_override("separation", 12)
	_dock_inferior.add_child(row)

	_btn_atras = Estilos_UI.boton("Atrás", "secundario", "chevron-left", Estilos_UI.TINTA, 56)
	_btn_atras.custom_minimum_size = Vector2(168, 56)
	_btn_atras.add_theme_font_size_override("font_size", 16)
	_btn_atras.pressed.connect(_paso_anterior)
	row.add_child(_btn_atras)

	_btn_siguiente = Estilos_UI.boton("Siguiente", "primario", "chevron-right", Estilos_UI.ROJO_BIT, 56)
	_btn_siguiente.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_siguiente.pressed.connect(_paso_siguiente)
	row.add_child(_btn_siguiente)


func _reubicar_layout() -> void:
	var alto := _alto_pantalla()
	if _dock_inferior != null:
		_dock_inferior.position = Vector2(0, alto - 96.0)
	if _card_opciones != null:
		_card_opciones.size = Vector2(680, maxf(320.0, alto - 508.0 - 108.0))


# ---------------------------------------------------------------- navegación de pasos

func _ir_a_paso(indice: int) -> void:
	indice = clampi(indice, 0, PASOS.size() - 1)
	if indice == _paso and _panel_contenido.get_child_count() > 0:
		return
	_paso = indice
	_estilizar_tabs()
	_actualizar_encabezado_paso(true)
	_actualizar_navegacion()
	_renderizar_paso()
	_scroll.scroll_vertical = 0
	_sugerir_vista_paso()


## Compatibilidad con herramientas de captura: permite saltar por id de paso.
func _cambiar_tab(id_tab: String) -> void:
	for i in PASOS.size():
		if str(PASOS[i]["id"]) == id_tab:
			_ir_a_paso(i)
			return


func _paso_anterior() -> void:
	if _paso > 0:
		_ir_a_paso(_paso - 1)


func _paso_siguiente() -> void:
	if _paso < PASOS.size() - 1:
		_ir_a_paso(_paso + 1)
	else:
		var centro := _btn_siguiente.get_global_rect().get_center() if _btn_siguiente != null else Vector2.ZERO
		_confirmar(centro)


func _actualizar_encabezado_paso(animar: bool) -> void:
	var paso := _paso_actual()
	_lbl_paso_pill.text = "PASO %d DE %d" % [_paso + 1, PASOS.size()]
	_lbl_paso_titulo.text = str(paso["titulo"])
	_lbl_paso_ayuda.text = str(paso["ayuda"])
	if animar:
		Estilos_UI.animar_barra(_barra_paso, float(_paso + 1), Estilos_UI.ROJO_BIT)
	else:
		_barra_paso.value = float(_paso + 1)


func _actualizar_navegacion() -> void:
	if _btn_atras == null or _btn_siguiente == null:
		return
	_btn_atras.disabled = (_paso == 0)
	var ultimo := (_paso == PASOS.size() - 1)
	if ultimo:
		_btn_siguiente.text = "¡Empezar vida!"
		Estilos_UI.aplicar_estilo_boton(_btn_siguiente, "exito", Estilos_UI.EXITO, "play")
		_btn_siguiente.add_theme_font_override("font", Estilos_UI.fuente_titulo(700))
		_btn_siguiente.add_theme_font_size_override("font_size", 19)
	else:
		_btn_siguiente.text = "Siguiente"
		Estilos_UI.aplicar_estilo_boton(_btn_siguiente, "primario", Estilos_UI.ROJO_BIT, "chevron-right")
		_btn_siguiente.add_theme_font_override("font", Estilos_UI.fuente_ui(700))
		_btn_siguiente.add_theme_font_size_override("font_size", 16)


func _estilizar_tabs() -> void:
	for i in PASOS.size():
		var id_tab: String = PASOS[i]["id"]
		if not _tab_botones.has(id_tab):
			continue
		var btn: Button = _tab_botones[id_tab]
		var activo: bool = (i == _paso)
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
		var ic := btn.get_node_or_null("ContenidoTab/IconoTab") as TextureRect
		if ic != null:
			ic.modulate = col
		var lbl := btn.get_node_or_null("ContenidoTab/LabelTab") as Label
		if lbl != null:
			lbl.add_theme_color_override("font_color", col)


func _sugerir_vista_paso() -> void:
	var vista := str(_paso_actual().get("vista", _modo_vista))
	if vista != "" and vista != _modo_vista:
		_cambiar_vista(vista)


# ---------------------------------------------------------------- render de pasos

func _renderizar_paso(conservar_scroll: bool = false) -> void:
	var scroll_y := _scroll.scroll_vertical if (conservar_scroll and _panel_contenido.get_child_count() > 0) else 0
	for hijo in _panel_contenido.get_children():
		_panel_contenido.remove_child(hijo)
		hijo.queue_free()
	_input_nombre = null

	match str(_paso_actual()["id"]):
		"identidad":
			_construir_paso_identidad()
		"cuerpo":
			_construir_paso_cuerpo()
		"cara":
			_construir_paso_cara()
		"pelo":
			_construir_paso_pelo()
		"ropa":
			_construir_paso_ropa()
		"extras":
			_construir_paso_extras()

	if conservar_scroll and scroll_y > 0:
		_scroll.call_deferred("set", "scroll_vertical", scroll_y)


func _construir_paso_identidad() -> void:
	_agregar_titulo_seccion("Nombre", "", "Así se llamará tu Sim. Puedes dejarlo vacío y usar «Sugerir».")
	var row_nom := HBoxContainer.new()
	row_nom.add_theme_constant_override("separation", 10)
	_panel_contenido.add_child(row_nom)

	_input_nombre = LineEdit.new()
	_input_nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input_nombre.custom_minimum_size = Vector2(0, 46)
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

	var btn_nom_rand := Estilos_UI.boton("Sugerir", "secundario", "sparkles", Estilos_UI.TINTA, 46)
	btn_nom_rand.custom_minimum_size = Vector2(124, 46)
	btn_nom_rand.add_theme_font_size_override("font_size", 14)
	btn_nom_rand.pressed.connect(func():
		var nom := Apariencia_Personaje.nombre_aleatorio(_apariencia["genero"])
		_apariencia["nombre"] = nom
		if _input_nombre != null and is_instance_valid(_input_nombre):
			_input_nombre.text = nom
		_actualizar_resumen())
	row_nom.add_child(btn_nom_rand)

	_agregar_titulo_seccion("Género", Apariencia_Personaje.etiqueta_genero(_apariencia),
		"Ajusta el peinado y el vello facial.")
	var row_gen := HBoxContainer.new()
	row_gen.add_theme_constant_override("separation", 12)
	_panel_contenido.add_child(row_gen)
	for g in Apariencia_Personaje.GENEROS:
		var id_g: String = g["id"]
		var activo: bool = (_apariencia["genero"] == id_g)
		var btn := _crear_boton_opcion(g["nombre"], activo, 50)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func(): _on_seleccionar_genero(id_g))
		row_gen.add_child(btn)

	_agregar_titulo_seccion("Personalidad", Apariencia_Personaje.etiqueta_personalidad(str(_apariencia.get("personalidad", ""))),
		"Define qué actividades preferirá hacer por su cuenta.")
	var grid_p := GridContainer.new()
	grid_p.columns = 2
	grid_p.add_theme_constant_override("h_separation", 10)
	grid_p.add_theme_constant_override("v_separation", 8)
	_panel_contenido.add_child(grid_p)
	var pers_act := str(_apariencia.get("personalidad", ""))
	for item in Apariencia_Personaje.PERSONALIDADES:
		var id_p: String = item["id"]
		var desc_corta := str(DESC_PERSONALIDAD_CORTA.get(id_p, item["desc"]))
		var btn_p := _crear_boton_tarjeta(item["nombre"], desc_corta, pers_act == id_p, 58)
		btn_p.pressed.connect(func():
			_apariencia["personalidad"] = id_p
			_aplicar_cambio(true))
		grid_p.add_child(btn_p)

	_agregar_titulo_seccion("Estilos rápidos (opcional)", "",
		"Aplica pelo y ropa de golpe. Después puedes ajustar cada detalle en los siguientes pasos.")
	var row_arq := HBoxContainer.new()
	row_arq.add_theme_constant_override("separation", 8)
	_panel_contenido.add_child(row_arq)
	for arq in Apariencia_Personaje.ARQUETIPOS:
		var id_arq: String = arq["id"]
		var btn_a := _crear_boton_opcion(arq["nombre"], false, 40)
		btn_a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_a.add_theme_font_size_override("font_size", 12)
		btn_a.pressed.connect(func():
			_apariencia = Apariencia_Personaje.aplicar_arquetipo(_apariencia, id_arq)
			_aplicar_cambio(true))
		row_arq.add_child(btn_a)


func _construir_paso_cuerpo() -> void:
	_agregar_titulo_seccion("Complexión", _nombre_opcion(Apariencia_Personaje.COMPLEXIONES, "complexion"),
		"Cambia la forma del cuerpo y de los brazos.")
	_agregar_grid_opciones(Apariencia_Personaje.COMPLEXIONES, "complexion", 4, 44, true)

	_agregar_titulo_seccion("Tono de piel", _nombre_color(Apariencia_Personaje.COLORES_PIEL, "color_piel"),
		"Se aplica a la cara y al cuerpo.")
	_agregar_paleta_colores(Apariencia_Personaje.COLORES_PIEL, "color_piel", 4)


func _construir_paso_cara() -> void:
	_agregar_titulo_seccion("Forma de la cara", _nombre_opcion(Apariencia_Personaje.FORMAS_CARA, "forma_cara"))
	_agregar_grid_opciones(Apariencia_Personaje.FORMAS_CARA, "forma_cara", 3, 44)

	_agregar_titulo_seccion("Forma de los ojos", _nombre_opcion(Apariencia_Personaje.FORMAS_OJOS, "forma_ojos"))
	_agregar_grid_opciones(Apariencia_Personaje.FORMAS_OJOS, "forma_ojos", 2, 44)

	_agregar_titulo_seccion("Color de ojos", _nombre_color(Apariencia_Personaje.COLORES_OJOS, "color_ojos"))
	_agregar_paleta_colores(Apariencia_Personaje.COLORES_OJOS, "color_ojos", 5)

	_agregar_titulo_seccion("Cejas", _nombre_opcion(Apariencia_Personaje.ESTILOS_CEJAS, "estilo_cejas"))
	_agregar_grid_opciones(Apariencia_Personaje.ESTILOS_CEJAS, "estilo_cejas", 3, 42)

	_agregar_titulo_seccion("Nariz", _nombre_opcion(Apariencia_Personaje.FORMAS_NARIZ, "forma_nariz"))
	_agregar_grid_opciones(Apariencia_Personaje.FORMAS_NARIZ, "forma_nariz", 3, 42)

	_agregar_titulo_seccion("Boca", _nombre_opcion(Apariencia_Personaje.FORMAS_BOCA, "forma_boca"))
	_agregar_grid_opciones(Apariencia_Personaje.FORMAS_BOCA, "forma_boca", 2, 42)

	_agregar_titulo_seccion("Tono de labios", _nombre_opcion(Apariencia_Personaje.COLORES_LABIOS, "color_labios"))
	var grid_lab := GridContainer.new()
	grid_lab.columns = 3
	grid_lab.add_theme_constant_override("h_separation", 10)
	grid_lab.add_theme_constant_override("v_separation", 8)
	_panel_contenido.add_child(grid_lab)
	var lab_act := str(_apariencia.get("color_labios", "natural"))
	for item in Apariencia_Personaje.COLORES_LABIOS:
		var id_l: String = item["id"]
		var btn := _crear_boton_opcion(item["nombre"], lab_act == id_l, 40)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func():
			_apariencia["color_labios"] = id_l
			_aplicar_cambio(true))
		grid_lab.add_child(btn)


func _construir_paso_pelo() -> void:
	_agregar_titulo_seccion("Peinado", _nombre_opcion(Apariencia_Personaje.ESTILOS_PELO, "estilo_pelo"))
	_agregar_grid_opciones(Apariencia_Personaje.ESTILOS_PELO, "estilo_pelo", 2, 44)

	_agregar_titulo_seccion("Color de pelo", _nombre_color(Apariencia_Personaje.COLORES_PELO, "color_pelo"))
	_agregar_paleta_colores(Apariencia_Personaje.COLORES_PELO, "color_pelo", 5)

	if _apariencia["genero"] == "hombre":
		_agregar_titulo_seccion("Vello facial", _nombre_opcion(Apariencia_Personaje.ESTILOS_VELLO, "vello_facial"),
			"Elige barba, bigote, perilla o ninguno.")
		_agregar_grid_opciones(Apariencia_Personaje.ESTILOS_VELLO, "vello_facial", 2, 42)
	else:
		_agregar_titulo_seccion("Vello facial", "Solo Hombre",
			"Cambia el género a Hombre para elegir barba, bigote o perilla.")
		var btn_hombre := _crear_boton_opcion("Cambiar a Hombre", false, 42)
		btn_hombre.pressed.connect(func(): _on_seleccionar_genero("hombre"))
		_panel_contenido.add_child(btn_hombre)


func _construir_paso_ropa() -> void:
	_agregar_titulo_seccion("Prenda superior", _nombre_opcion(Apariencia_Personaje.ROPA_SUPERIOR, "ropa_superior"))
	_agregar_grid_opciones(Apariencia_Personaje.ROPA_SUPERIOR, "ropa_superior", 3, 44)

	_agregar_titulo_seccion("Color superior", _nombre_color(Apariencia_Personaje.COLORES_ROPA, "color_ropa"))
	_agregar_paleta_colores(Apariencia_Personaje.COLORES_ROPA, "color_ropa", 4)

	_agregar_titulo_seccion("Prenda inferior", _nombre_opcion(Apariencia_Personaje.ROPA_INFERIOR, "ropa_inferior"),
		"La cámara cambia al cuerpo para que veas la prenda completa.")
	_agregar_grid_opciones(Apariencia_Personaje.ROPA_INFERIOR, "ropa_inferior", 3, 44, true)

	_agregar_titulo_seccion("Color inferior", _nombre_color(Apariencia_Personaje.COLORES_PANTALON, "color_pantalon"))
	_agregar_paleta_colores(Apariencia_Personaje.COLORES_PANTALON, "color_pantalon", 4, true)

	_agregar_titulo_seccion("Calzado", _nombre_opcion(Apariencia_Personaje.ESTILOS_CALZADO, "calzado"))
	_agregar_grid_opciones(Apariencia_Personaje.ESTILOS_CALZADO, "calzado", 3, 44, true)

	_agregar_titulo_seccion("Color del calzado", _nombre_color(Apariencia_Personaje.COLORES_CALZADO, "color_calzado"))
	_agregar_paleta_colores(Apariencia_Personaje.COLORES_CALZADO, "color_calzado", 3, true)


func _construir_paso_extras() -> void:
	_agregar_grupo("Accesorios", "gem")

	_agregar_titulo_seccion("Gafas", _nombre_opcion(Apariencia_Personaje.ESTILOS_GAFAS, "gafas"))
	_agregar_grid_opciones(Apariencia_Personaje.ESTILOS_GAFAS, "gafas", 3, 44)

	_agregar_titulo_seccion("Sombrero", _nombre_opcion(Apariencia_Personaje.ESTILOS_SOMBRERO, "sombrero"))
	_agregar_grid_opciones(Apariencia_Personaje.ESTILOS_SOMBRERO, "sombrero", 3, 44)

	_agregar_titulo_seccion("Pendientes", _nombre_opcion(Apariencia_Personaje.ESTILOS_PENDIENTES, "pendientes"))
	_agregar_grid_opciones(Apariencia_Personaje.ESTILOS_PENDIENTES, "pendientes", 2, 42)

	_agregar_grupo("Maquillaje y rostro", "palette")

	_agregar_titulo_seccion("Rubor", _nombre_opcion(Apariencia_Personaje.NIVELES_RUBOR, "rubor"))
	_agregar_grid_opciones(Apariencia_Personaje.NIVELES_RUBOR, "rubor", 3, 42)

	_agregar_titulo_seccion("Delineado de ojos", "Con delineado" if bool(_apariencia.get("delineado", false)) else "Sin delineado")
	var row_del := HBoxContainer.new()
	row_del.add_theme_constant_override("separation", 10)
	_panel_contenido.add_child(row_del)
	var btn_del_no := _crear_boton_opcion("Sin delineado", not bool(_apariencia.get("delineado", false)), 42)
	btn_del_no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_del_no.pressed.connect(func():
		_apariencia["delineado"] = false
		_aplicar_cambio(true))
	row_del.add_child(btn_del_no)
	var btn_del_si := _crear_boton_opcion("Con delineado", bool(_apariencia.get("delineado", false)), 42)
	btn_del_si.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_del_si.pressed.connect(func():
		_apariencia["delineado"] = true
		_aplicar_cambio(true))
	row_del.add_child(btn_del_si)

	_agregar_titulo_seccion("Pecas", "Con pecas" if bool(_apariencia.get("pecas", false)) else "Sin pecas")
	var row_p := HBoxContainer.new()
	row_p.add_theme_constant_override("separation", 10)
	_panel_contenido.add_child(row_p)
	var pecas_activas := bool(_apariencia.get("pecas", false))
	var btn_sin := _crear_boton_opcion("Sin pecas", not pecas_activas, 42)
	btn_sin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_sin.pressed.connect(func():
		_apariencia["pecas"] = false
		_aplicar_cambio(true))
	row_p.add_child(btn_sin)
	var btn_con := _crear_boton_opcion("Con pecas", pecas_activas, 42)
	btn_con.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_con.pressed.connect(func():
		_apariencia["pecas"] = true
		_aplicar_cambio(true))
	row_p.add_child(btn_con)

	_agregar_titulo_seccion("Lunar", _nombre_opcion(Apariencia_Personaje.ESTILOS_LUNAR, "lunar"))
	_agregar_grid_opciones(Apariencia_Personaje.ESTILOS_LUNAR, "lunar", 2, 42)


# ---------------------------------------------------------------- componentes reutilizables

func _agregar_titulo_seccion(texto_sec: String, valor_actual: String = "", ayuda: String = "") -> void:
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 2)
	_panel_contenido.add_child(caja)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	caja.add_child(fila)

	var barra := ColorRect.new()
	barra.color = Estilos_UI.ROJO_BIT
	barra.custom_minimum_size = Vector2(4, 14)
	barra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(barra)

	var lbl := Estilos_UI.texto(texto_sec.to_upper(), 12, Estilos_UI.TINTA_SUAVE, 700)
	fila.add_child(lbl)

	if valor_actual != "":
		var relleno := Control.new()
		relleno.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		relleno.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fila.add_child(relleno)

		var lbl_valor := Estilos_UI.texto(valor_actual, 12, Estilos_UI.ROJO_BIT, 700)
		lbl_valor.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl_valor.size_flags_horizontal = Control.SIZE_SHRINK_END
		fila.add_child(lbl_valor)

	if ayuda != "":
		var lbl_ayuda := Estilos_UI.texto(ayuda, 11, Estilos_UI.TINTA_FANTASMA, 500)
		lbl_ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		caja.add_child(lbl_ayuda)


func _agregar_grupo(texto_grupo: String, icono: String) -> void:
	_panel_contenido.add_child(Estilos_UI.separador(2))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	_panel_contenido.add_child(fila)

	fila.add_child(Estilos_UI.icono_rect(icono, 16, Estilos_UI.ROJO_BIT))
	var lbl := Estilos_UI.texto(texto_grupo, 14, Estilos_UI.TINTA, 800)
	lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(lbl)

	var linea := ColorRect.new()
	linea.color = Estilos_UI.BORDE
	linea.custom_minimum_size = Vector2(0, 1)
	linea.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linea.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	linea.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(linea)


func _nombre_opcion(lista: Array[Dictionary], clave: String) -> String:
	var actual := str(_apariencia.get(clave, ""))
	for item in lista:
		if str(item["id"]) == actual:
			return str(item["nombre"])
	return ""


func _nombre_color(paleta: Array[Dictionary], clave: String) -> String:
	var actual := str(_apariencia.get(clave, "")).to_lower()
	for item in paleta:
		if str(item["hex"]).to_lower() == actual:
			return str(item["nombre"])
	return ""


func _agregar_grid_opciones(lista: Array[Dictionary], clave: String, columnas: int, alto: int = 44, auto_cuerpo: bool = false) -> void:
	var grid := GridContainer.new()
	grid.columns = columnas
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	_panel_contenido.add_child(grid)

	var actual := str(_apariencia.get(clave, ""))
	for item in lista:
		var id_v: String = item["id"]
		var activo: bool = (actual == id_v)
		var btn := _crear_boton_opcion(item["nombre"], activo, alto)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func():
			_apariencia[clave] = id_v
			if auto_cuerpo and _modo_vista != "cuerpo_completo":
				_cambiar_vista("cuerpo_completo")
			_aplicar_cambio(true))
		grid.add_child(btn)


func _agregar_paleta_colores(paleta: Array[Dictionary], clave: String, columnas: int, auto_cuerpo: bool = false) -> void:
	var grid := GridContainer.new()
	grid.columns = columnas
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
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
		celda.add_theme_constant_override("separation", 4)
		grid.add_child(celda)

		var btn := Button.new()
		btn.set_meta("_tema_aplicado", true)
		btn.set_meta("_estilo_propio", true)
		btn.custom_minimum_size = Vector2(50, 50)
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
			btn.add_theme_constant_override("icon_max_width", 20)
			var col_check := Estilos_UI.TINTA if col.get_luminance() > 0.62 else Color.WHITE
			for k in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
				btn.add_theme_color_override(k, col_check)

		Estilos_UI.animar_presion(btn)
		btn.pressed.connect(func():
			_apariencia[clave] = hex
			if auto_cuerpo and _modo_vista != "cuerpo_completo":
				_cambiar_vista("cuerpo_completo")
			_aplicar_cambio(true))
		celda.add_child(btn)

		var lbl := Estilos_UI.texto(nombre, 11, Estilos_UI.ROJO_BIT if activo else Estilos_UI.TINTA_SUAVE, 700 if activo else 500)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		celda.add_child(lbl)


func _crear_boton_opcion(etiqueta: String, activo: bool, alto: int = 46) -> Button:
	var btn := Button.new()
	btn.set_meta("_tema_aplicado", true)
	btn.set_meta("_estilo_propio", true)
	btn.text = etiqueta
	btn.custom_minimum_size = Vector2(0, alto)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_override("font", Estilos_UI.fuente_ui(700 if activo else 600))
	btn.add_theme_font_size_override("font_size", 13)
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
		btn.add_theme_constant_override("icon_max_width", 15)
		btn.add_theme_constant_override("h_separation", 6)
		for k in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
			btn.add_theme_color_override(k, Estilos_UI.ROJO_BIT)

	Estilos_UI.animar_presion(btn)
	return btn


## Tarjeta de dos líneas (título + descripción) usada por las personalidades.
func _crear_boton_tarjeta(titulo: String, descripcion: String, activo: bool, alto: int = 58) -> Button:
	var btn := Button.new()
	btn.set_meta("_tema_aplicado", true)
	btn.set_meta("_estilo_propio", true)
	btn.text = ""
	btn.custom_minimum_size = Vector2(0, alto)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.set_meta("titulo", titulo)
	btn.tooltip_text = "%s: %s" % [titulo, descripcion]
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
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
	btn.add_theme_stylebox_override("normal", st_n)
	btn.add_theme_stylebox_override("hover", st_h)
	btn.add_theme_stylebox_override("pressed", st_n)

	var margen := MarginContainer.new()
	margen.set_anchors_preset(Control.PRESET_FULL_RECT)
	margen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margen.add_theme_constant_override("margin_left", 12)
	margen.add_theme_constant_override("margin_right", 10)
	margen.add_theme_constant_override("margin_top", 6)
	margen.add_theme_constant_override("margin_bottom", 6)
	btn.add_child(margen)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margen.add_child(fila)

	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.alignment = BoxContainer.ALIGNMENT_CENTER
	textos.add_theme_constant_override("separation", 0)
	textos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(textos)

	var lbl_titulo := Estilos_UI.texto(titulo, 13, Estilos_UI.ROJO_BIT if activo else Estilos_UI.TINTA, 700)
	lbl_titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	textos.add_child(lbl_titulo)

	var lbl_desc := Estilos_UI.texto(descripcion, 10, Estilos_UI.TINTA_FANTASMA, 500)
	lbl_desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	textos.add_child(lbl_desc)

	if activo:
		fila.add_child(Estilos_UI.icono_rect("check", 16, Estilos_UI.ROJO_BIT))

	Estilos_UI.animar_presion(btn)
	return btn


# ---------------------------------------------------------------- acciones y animaciones

func _on_seleccionar_genero(nuevo_genero: String) -> void:
	if _apariencia["genero"] == nuevo_genero:
		return
	_apariencia["genero"] = nuevo_genero
	if nuevo_genero == "mujer":
		_apariencia["vello_facial"] = "ninguno"
		_apariencia["delineado"] = true
		if _apariencia["estilo_pelo"] in ["alborotado", "tupe", "corto", "degradado", "rapado", "calvo"]:
			_apariencia["estilo_pelo"] = "largo"
	else:
		_apariencia["delineado"] = false
		if _apariencia["estilo_pelo"] in ["largo", "ondulado", "media_melena", "bob", "coleta", "dos_coletas", "mono"]:
			_apariencia["estilo_pelo"] = "alborotado"
	_aplicar_cambio(true)


func _on_aleatorio() -> void:
	var pers_actual := str(_apariencia.get("personalidad", ""))
	_apariencia = Apariencia_Personaje.aleatoria()
	_apariencia["personalidad"] = pers_actual
	_aplicar_cambio(true)


func _cambiar_vista(nueva_vista: String) -> void:
	if _modo_vista == nueva_vista:
		return
	_modo_vista = nueva_vista
	if _preview != null:
		_preview.modo = nueva_vista
	_estilizar_botones_vista()
	_animar_pop_preview()


func _estilizar_botones_vista() -> void:
	for vid in _vista_botones.keys():
		var btn: Button = _vista_botones[vid]
		var act: bool = (vid == _modo_vista)
		var st := Estilos_UI.caja(
			Estilos_UI.ROJO_BIT if act else Color(0, 0, 0, 0),
			8, Color(0, 0, 0, 0), 0, 0
		)
		var col := Color.WHITE if act else Estilos_UI.TINTA_SUAVE
		btn.add_theme_stylebox_override("normal", st)
		btn.add_theme_stylebox_override("hover", st)
		btn.add_theme_stylebox_override("pressed", st)
		for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			btn.add_theme_color_override(k, col)


func _cambiar_pose_preview(id_p: String, nueva_pose: String, nueva_var: String, nueva_expr: String) -> void:
	_pose_preview = nueva_pose
	_variacion_preview = nueva_var
	_expr_preview = nueva_expr
	if _preview != null:
		_preview.pose = nueva_pose
		_preview.variacion = nueva_var
		_preview.expresion = nueva_expr
		if nueva_pose in ["correr", "fiesta"] and _modo_vista == "retrato_cercano":
			_cambiar_vista("cuerpo_completo")
	_estilizar_botones_pose(id_p)
	_animar_pop_preview()


func _estilizar_botones_pose(id_activo: String) -> void:
	for pid in _pose_botones.keys():
		var btn: Button = _pose_botones[pid]
		var act: bool = (pid == id_activo)
		var st := Estilos_UI.caja(
			Estilos_UI.AZUL if act else Color(0, 0, 0, 0),
			999, Color(0, 0, 0, 0), 0, 0
		)
		var col := Color.WHITE if act else Estilos_UI.TINTA_SUAVE
		btn.add_theme_stylebox_override("normal", st)
		btn.add_theme_stylebox_override("hover", st)
		btn.add_theme_stylebox_override("pressed", st)
		for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			btn.add_theme_color_override(k, col)


func _aplicar_cambio(reconstruir_paso: bool) -> void:
	_apariencia = Apariencia_Personaje.normalizar(_apariencia)
	if _preview != null:
		_preview.apariencia = _apariencia
	if _mini_retrato != null and is_instance_valid(_mini_retrato):
		_mini_retrato.apariencia = _apariencia
	_actualizar_resumen()
	_animar_pop_preview()
	if reconstruir_paso:
		_renderizar_paso(true)


func _actualizar_resumen() -> void:
	if _lbl_resumen == null:
		return
	var nom := str(_apariencia.get("nombre", "")).strip_edges()
	var gen := Apariencia_Personaje.etiqueta_genero(_apariencia)
	var pers := str(_apariencia.get("personalidad", ""))
	var partes: Array[String] = []
	partes.append(nom if nom != "" else "Tu Sim")
	partes.append(gen)
	partes.append(Apariencia_Personaje.etiqueta_personalidad(pers))
	_lbl_resumen.text = " · ".join(partes)


func _animar_pop_preview() -> void:
	if _preview == null:
		return
	if _tween_pop != null and _tween_pop.is_valid():
		_tween_pop.kill()
	_preview.pivot_offset = _preview.size * 0.5
	_preview.scale = Vector2(0.95, 0.95)
	_tween_pop = create_tween()
	_tween_pop.tween_property(_preview, "scale", Vector2.ONE, 0.22) \
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
