class_name Tienda_Bienestar
extends Control

# ============================================================================
# Pestaña "Ventajas" de la Tienda.
#
# Diseño de tienda móvil moderna, clara y sin saturación visual:
#   1. Barra compacta de estado (edad del Sim y saldo disponible) + filtros.
#   2. Anuncios recompensados (diseño final; en esta beta avisan al pulsar).
#   3. Compras integradas (Sims+ VIP, Sin anuncios y packs; aviso en beta).
#   4. Clínica de rejuvenecimiento y cuidado exprés pagados con euros del juego.
# ============================================================================

const MODAL_TRATAMIENTO := preload("res://Scripts/GUI/Tienda/Modal_Tratamiento.gd")
const MODAL_ANUNCIO := preload("res://Scripts/GUI/Tienda/Modal_Anuncio_Bienestar.gd")
const SFX_COIN := preload("res://Sonidos/SFX/coin.wav")
const SFX_DING := preload("res://Sonidos/SFX/ding.wav")
const SFX_POP := preload("res://Sonidos/SFX/pop.wav")

const TEAL := Color("#0d9488")
const INDIGO := Color("#4f46e5")
const CORAL := Color("#e11d48")
const ORO := Color("#d97706")

const FILTROS := [
	{"id": "todo", "nombre": "Todo"},
	{"id": "anuncios", "nombre": "Anuncios"},
	{"id": "compras", "nombre": "Compras"},
	{"id": "clinica", "nombre": "Clínica"},
]

var _scroll: ScrollContainer
var _contenido: VBoxContainer
var _lbl_edad: Label
var _lbl_edad_rejuvenecida: Label
var _lbl_dinero: Label
var _badge_dinero: PanelContainer
var _lbl_edad_hero: Label
var _lbl_rejuvenecido_hero: Label
var _medidor_edad: Visual_Bienestar.Medidor_Edad

var _filtro_actual: String = "todo"
var _botones_filtro: Dictionary = {}
var _seccion_anuncios: VBoxContainer
var _seccion_compras: VBoxContainer
var _seccion_clinica: VBoxContainer

var _ads_refs: Dictionary = {}
var _compras_refs: Dictionary = {}
var _servicios_refs: Dictionary = {}
var _modal_tratamiento: Modal_Tratamiento = null
var _modal_anuncio: Modal_Anuncio_Bienestar = null

var _toast_raiz: Control
var _toast_panel: PanelContainer
var _toast_label: Label
var _toast_icono: TextureRect
var _toast_timer: Timer
var _toast_tween: Tween
var _toast_mostrando: bool = false
var _sfx_player: AudioStreamPlayer
var _tween_dinero: Tween
var _dinero_mostrado: int = -999999
var _construido: bool = false
var _primera_entrada: bool = true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_Construir_UI()
	_Crear_Reproductor_SFX()
	_toast_timer = Timer.new()
	_toast_timer.name = "Timer_Toast"
	_toast_timer.one_shot = true
	_toast_timer.wait_time = 2.4
	_toast_timer.timeout.connect(_Ocultar_Toast)
	add_child(_toast_timer)
	if not Recompensas.estado_cambiado.is_connected(_On_Estado_Cambiado):
		Recompensas.estado_cambiado.connect(_On_Estado_Cambiado)
	visibility_changed.connect(_On_Visibilidad_Cambiada)
	_construido = true
	_Sincronizar(false)


func _exit_tree() -> void:
	if Recompensas.estado_cambiado.is_connected(_On_Estado_Cambiado):
		Recompensas.estado_cambiado.disconnect(_On_Estado_Cambiado)
	if _modal_anuncio != null and is_instance_valid(_modal_anuncio) and _modal_anuncio.token > 0:
		Recompensas.Cancelar_Anuncio(_modal_anuncio.token)


func _On_Visibilidad_Cambiada() -> void:
	if not visible:
		if _toast_panel != null:
			_toast_mostrando = false
			_toast_panel.visible = false
		if _toast_timer != null:
			_toast_timer.stop()
		return
	_Sincronizar(false)
	if _scroll != null:
		_scroll.scroll_vertical = 0
	if _primera_entrada:
		_primera_entrada = false
		call_deferred("_Animar_Entrada")
	else:
		_Animar_Entrada()


func Refrescar() -> void:
	_Sincronizar(false)


# ----------------------------------------------------------------------------
# Construcción de la interfaz
# ----------------------------------------------------------------------------

func _Construir_UI() -> void:
	_scroll = ScrollContainer.new()
	_scroll.name = "Scroll_Bienestar"
	_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.follow_focus = true
	add_child(_scroll)

	var margen := MarginContainer.new()
	margen.name = "Margen_Bienestar"
	margen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margen.add_theme_constant_override("margin_left", 20)
	margen.add_theme_constant_override("margin_right", 20)
	margen.add_theme_constant_override("margin_top", 12)
	margen.add_theme_constant_override("margin_bottom", 32)
	_scroll.add_child(margen)

	_contenido = VBoxContainer.new()
	_contenido.name = "Contenido_Bienestar"
	_contenido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_contenido.add_theme_constant_override("separation", 18)
	margen.add_child(_contenido)

	_contenido.add_child(_Crear_Barra_Estado())
	_contenido.add_child(_Crear_Barra_Filtros())

	_seccion_anuncios = _Crear_Seccion_Anuncios()
	_contenido.add_child(_seccion_anuncios)

	_seccion_compras = _Crear_Seccion_Compras()
	_contenido.add_child(_seccion_compras)

	_seccion_clinica = _Crear_Seccion_Clinica()
	_contenido.add_child(_seccion_clinica)

	_contenido.add_child(_Crear_Pie_Informacion())
	_Crear_Toast()
	_Aplicar_Filtro("todo")


func _Crear_Barra_Estado() -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "Barra_Estado"
	card.set_meta("_tema_aplicado", true)
	card.add_theme_stylebox_override("panel", Estilos_UI.caja_tarjeta(16, 2))

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 14)
	margen.add_theme_constant_override("margin_right", 14)
	margen.add_theme_constant_override("margin_top", 10)
	margen.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margen)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	margen.add_child(fila)

	# Edad del Sim
	var bloque_edad := HBoxContainer.new()
	bloque_edad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bloque_edad.add_theme_constant_override("separation", 10)
	fila.add_child(bloque_edad)
	bloque_edad.add_child(_Icono_Suave("hourglass", 36, 18, TEAL))

	var ve := VBoxContainer.new()
	ve.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ve.alignment = BoxContainer.ALIGNMENT_CENTER
	ve.add_theme_constant_override("separation", 0)
	bloque_edad.add_child(ve)
	ve.add_child(_Etiqueta_Mini("EDAD DEL SIM", Estilos_UI.TINTA_FANTASMA))
	var fila_edad := HBoxContainer.new()
	fila_edad.add_theme_constant_override("separation", 5)
	ve.add_child(fila_edad)
	_lbl_edad = Estilos_UI.titulo("18 años", 17, Estilos_UI.TINTA)
	fila_edad.add_child(_lbl_edad)
	_lbl_edad_rejuvenecida = Estilos_UI.texto("", 10, TEAL, 600)
	_lbl_edad_rejuvenecida.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila_edad.add_child(_lbl_edad_rejuvenecida)

	var divisor := ColorRect.new()
	divisor.color = Estilos_UI.BORDE
	divisor.custom_minimum_size = Vector2(1, 34)
	divisor.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	divisor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(divisor)

	# Saldo de partida
	var bloque_dinero := HBoxContainer.new()
	bloque_dinero.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bloque_dinero.add_theme_constant_override("separation", 10)
	fila.add_child(bloque_dinero)
	_badge_dinero = _Icono_Suave("wallet", 36, 18, Estilos_UI.EXITO)
	bloque_dinero.add_child(_badge_dinero)

	var vd := VBoxContainer.new()
	vd.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vd.alignment = BoxContainer.ALIGNMENT_CENTER
	vd.add_theme_constant_override("separation", 0)
	bloque_dinero.add_child(vd)
	vd.add_child(_Etiqueta_Mini("SALDO EN PARTIDA", Estilos_UI.TINTA_FANTASMA))
	var fila_dinero := HBoxContainer.new()
	fila_dinero.add_theme_constant_override("separation", 5)
	vd.add_child(fila_dinero)
	_lbl_dinero = Estilos_UI.titulo("0 €", 17, Estilos_UI.EXITO)
	fila_dinero.add_child(_lbl_dinero)

	return card


func _Crear_Barra_Filtros() -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.name = "Barra_Filtros"
	fila.add_theme_constant_override("separation", 8)
	for f in FILTROS:
		var id := str(f["id"])
		var btn := Button.new()
		btn.name = "Filtro_%s" % id
		btn.text = str(f["nombre"])
		btn.custom_minimum_size = Vector2(0, 36)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.set_meta("_tema_aplicado", true)
		btn.pressed.connect(_Seleccionar_Filtro.bind(id))
		fila.add_child(btn)
		_botones_filtro[id] = btn
	_Marcar_Filtros()
	return fila


func _Seleccionar_Filtro(id: String) -> void:
	_Aplicar_Filtro(id)
	if _scroll != null:
		_scroll.scroll_vertical = 0
	_Reproducir_SFX("pop")


func _Aplicar_Filtro(id: String) -> void:
	if not _botones_filtro.has(id):
		id = "todo"
	_filtro_actual = id
	_Marcar_Filtros()
	if _seccion_anuncios != null:
		_seccion_anuncios.visible = (id == "todo" or id == "anuncios")
	if _seccion_compras != null:
		_seccion_compras.visible = (id == "todo" or id == "compras")
	if _seccion_clinica != null:
		_seccion_clinica.visible = (id == "todo" or id == "clinica")


func _Marcar_Filtros() -> void:
	for id in _botones_filtro:
		var btn: Button = _botones_filtro[id]
		if btn == null or not is_instance_valid(btn):
			continue
		var on: bool = (str(id) == _filtro_actual)
		var st_n := Estilos_UI.caja(
			Estilos_UI.NAVY if on else Estilos_UI.SUPERFICIE,
			999,
			Estilos_UI.NAVY if on else Estilos_UI.BORDE,
			1,
			0)
		var st_h := st_n.duplicate() as StyleBoxFlat
		if not on:
			st_h.bg_color = Estilos_UI.SUPERFICIE_2
		var st_p := st_n.duplicate() as StyleBoxFlat
		st_p.bg_color = Estilos_UI.NAVY_OSCURO if on else Estilos_UI.FONDO_2
		btn.add_theme_stylebox_override("normal", st_n)
		btn.add_theme_stylebox_override("hover", st_h)
		btn.add_theme_stylebox_override("pressed", st_p)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		btn.add_theme_font_override("font", Estilos_UI.fuente_ui(700 if on else 600))
		btn.add_theme_font_size_override("font_size", 12)
		var fg := Color.WHITE if on else Estilos_UI.TINTA_SUAVE
		for clave in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			btn.add_theme_color_override(clave, fg)


# ----------------------------------------------------------------------------
# Sección 1: Anuncios recompensados
# ----------------------------------------------------------------------------

func _Crear_Seccion_Anuncios() -> VBoxContainer:
	var seccion := VBoxContainer.new()
	seccion.name = "Seccion_Anuncios"
	seccion.add_theme_constant_override("separation", 10)
	seccion.add_child(_Cabecera_Seccion(
		"Anuncios", "Recompensas gratuitas viendo un vídeo breve.",
		"GRATIS", Estilos_UI.EXITO_SUAVE, Estilos_UI.EXITO_OSCURO))

	var grid := GridContainer.new()
	grid.name = "Rejilla_Anuncios"
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	seccion.add_child(grid)

	for producto in Recompensas_Catalogo.Productos_De(Recompensas_Catalogo.SECCION_ANUNCIOS):
		grid.add_child(_Crear_Tarjeta_Anuncio(producto))
	return seccion


func _Crear_Tarjeta_Anuncio(producto: Dictionary) -> PanelContainer:
	var id := str(producto.get("id", ""))
	var color := _Color(producto.get("color", INDIGO))
	var card := PanelContainer.new()
	card.name = "Anuncio_%s" % id
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.set_meta("_tema_aplicado", true)
	card.add_theme_stylebox_override("panel", Estilos_UI.caja_tarjeta(16, 2))

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 14)
	margen.add_theme_constant_override("margin_right", 14)
	margen.add_theme_constant_override("margin_top", 13)
	margen.add_theme_constant_override("margin_bottom", 13)
	card.add_child(margen)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 9)
	margen.add_child(v)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	v.add_child(top)
	top.add_child(_Icono_Suave(str(producto.get("icono", "gift")), 38, 19, color))

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(spacer)

	var duracion := int(round(float(producto.get("duracion_simulada", 5.0))))
	var pill_dur := _Crear_Mini_Pill("%d s" % duracion, Estilos_UI.SUPERFICIE_2, Estilos_UI.TINTA_SUAVE)
	pill_dur.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(pill_dur)

	var textos := VBoxContainer.new()
	textos.add_theme_constant_override("separation", 2)
	v.add_child(textos)

	var recompensa := Estilos_UI.titulo(str(producto.get("recompensa_texto", "")), 16, Estilos_UI.TINTA)
	recompensa.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	recompensa.custom_minimum_size = Vector2(0, 22)
	textos.add_child(recompensa)

	var titulo := Estilos_UI.texto(str(producto.get("titulo", "")), 12, Estilos_UI.TINTA_SUAVE, 500)
	titulo.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	textos.add_child(titulo)

	var btn := Estilos_UI.boton("Ver anuncio", "suave", "play", color, 36)
	btn.name = "Ver_%s" % id
	btn.add_theme_font_size_override("font_size", 12)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.pressed.connect(_On_Pulsar_Anuncio.bind(producto))
	v.add_child(btn)

	_ads_refs[id] = {
		"producto": producto,
		"card": card,
		"btn": btn,
		"color": color,
	}
	return card


# ----------------------------------------------------------------------------
# Sección 2: Compras integradas (VIP, Sin anuncios y Packs)
# ----------------------------------------------------------------------------

func _Crear_Seccion_Compras() -> VBoxContainer:
	var seccion := VBoxContainer.new()
	seccion.name = "Seccion_Compras"
	seccion.add_theme_constant_override("separation", 10)
	seccion.add_child(_Cabecera_Seccion(
		"Ventajas y packs", "Mejoras opcionales, sin suscripciones ocultas."))

	var productos := Recompensas_Catalogo.Productos_De(Recompensas_Catalogo.SECCION_COMPRAS)
	var packs := HBoxContainer.new()
	packs.name = "Fila_Packs"
	packs.add_theme_constant_override("separation", 12)

	for producto in productos:
		var id := str(producto.get("id", ""))
		if bool(producto.get("destacado", false)):
			seccion.add_child(_Crear_Tarjeta_VIP(producto))
		elif id == "compra_sin_anuncios":
			seccion.add_child(_Crear_Tarjeta_Compra_Horizontal(producto))
		else:
			var card_pack := _Crear_Tarjeta_Pack(producto)
			card_pack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			packs.add_child(card_pack)

	if packs.get_child_count() > 0:
		seccion.add_child(packs)
	return seccion


func _Crear_Tarjeta_VIP(producto: Dictionary) -> PanelContainer:
	var id := str(producto.get("id", ""))
	var color := _Color(producto.get("color", ORO))
	var card := PanelContainer.new()
	card.name = "Compra_%s" % id
	card.set_meta("_tema_aplicado", true)
	card.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Color("#151e30"), 18, Color(1, 1, 1, 0.08), 1, 3))

	var fondo := Visual_Bienestar.Fondo_Tarjeta_VIP.new()
	fondo.radio = 18.0
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.add_child(fondo)

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 16)
	margen.add_theme_constant_override("margin_right", 16)
	margen.add_theme_constant_override("margin_top", 15)
	margen.add_theme_constant_override("margin_bottom", 15)
	card.add_child(margen)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	margen.add_child(v)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	v.add_child(fila)

	var icono := PanelContainer.new()
	icono.set_meta("_tema_aplicado", true)
	icono.custom_minimum_size = Vector2(44, 44)
	icono.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icono.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Color(0.96, 0.62, 0.04, 0.16), 12, Color(0.96, 0.62, 0.04, 0.35), 1, 0))
	var c_ic := CenterContainer.new()
	c_ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c_ic.add_child(Estilos_UI.icono_rect(str(producto.get("icono", "crown")), 22, Color("#fbbf24")))
	icono.add_child(c_ic)
	fila.add_child(icono)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 1)
	fila.add_child(info)

	var tit_row := HBoxContainer.new()
	tit_row.add_theme_constant_override("separation", 8)
	info.add_child(tit_row)
	tit_row.add_child(Estilos_UI.titulo(str(producto.get("titulo", "Sims+ VIP")), 18, Color.WHITE))
	var chip := _Crear_Mini_Pill(
		str(producto.get("etiqueta", "PERMANENTE")),
		Color(0.96, 0.62, 0.04, 0.16), Color("#fcd34d"))
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tit_row.add_child(chip)

	info.add_child(Estilos_UI.texto(
		str(producto.get("subtitulo", "")), 11, Color("#94a3b8"), 500))

	var btn := _Boton_Precio_Claro(str(producto.get("precio_real", "4,99 €")), color)
	btn.name = "Comprar_%s" % id
	btn.pressed.connect(_On_Pulsar_Compra_IAP.bind(producto))
	fila.add_child(btn)

	var desc := Estilos_UI.texto(str(producto.get("descripcion", "")), 12, Color("#cbd5e1"), 400)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(desc)

	var beneficios: Array = producto.get("beneficios", [])
	if not beneficios.is_empty():
		var fila_ben := HBoxContainer.new()
		fila_ben.add_theme_constant_override("separation", 6)
		v.add_child(fila_ben)
		for b in beneficios:
			fila_ben.add_child(_Crear_Mini_Pill(
				str(b), Color(1.0, 1.0, 1.0, 0.08), Color("#e2e8f0")))

	_compras_refs[id] = {"producto": producto, "card": card, "btn": btn}
	return card


func _Crear_Tarjeta_Compra_Horizontal(producto: Dictionary) -> PanelContainer:
	var id := str(producto.get("id", ""))
	var color := _Color(producto.get("color", INDIGO))
	var card := PanelContainer.new()
	card.name = "Compra_%s" % id
	card.set_meta("_tema_aplicado", true)
	card.add_theme_stylebox_override("panel", Estilos_UI.caja_tarjeta(16, 2))

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 14)
	margen.add_theme_constant_override("margin_right", 14)
	margen.add_theme_constant_override("margin_top", 12)
	margen.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margen)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	margen.add_child(fila)

	fila.add_child(_Icono_Suave(str(producto.get("icono", "zap")), 42, 20, color))

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 2)
	fila.add_child(info)

	var tit := HBoxContainer.new()
	tit.add_theme_constant_override("separation", 7)
	info.add_child(tit)
	tit.add_child(Estilos_UI.texto(str(producto.get("titulo", "")), 15, Estilos_UI.TINTA, 700))
	tit.add_child(_Crear_Mini_Pill(
		str(producto.get("subtitulo", "Pago único")), Color(color, 0.10), color))

	var desc := Estilos_UI.texto(str(producto.get("descripcion", "")), 11, Estilos_UI.TINTA_SUAVE, 500)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(desc)

	var btn := _Boton_Precio_Oscuro(str(producto.get("precio_real", "2,99 €")))
	btn.name = "Comprar_%s" % id
	btn.pressed.connect(_On_Pulsar_Compra_IAP.bind(producto))
	fila.add_child(btn)

	_compras_refs[id] = {"producto": producto, "card": card, "btn": btn}
	return card


func _Crear_Tarjeta_Pack(producto: Dictionary) -> PanelContainer:
	var id := str(producto.get("id", ""))
	var color := _Color(producto.get("color", TEAL))
	var card := PanelContainer.new()
	card.name = "Compra_%s" % id
	card.set_meta("_tema_aplicado", true)
	card.add_theme_stylebox_override("panel", Estilos_UI.caja_tarjeta(16, 2))

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 14)
	margen.add_theme_constant_override("margin_right", 14)
	margen.add_theme_constant_override("margin_top", 13)
	margen.add_theme_constant_override("margin_bottom", 13)
	card.add_child(margen)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 7)
	margen.add_child(v)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	v.add_child(top)
	top.add_child(_Icono_Suave(str(producto.get("icono", "package")), 36, 18, color))
	var info_top := VBoxContainer.new()
	info_top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_top.alignment = BoxContainer.ALIGNMENT_CENTER
	info_top.add_theme_constant_override("separation", 0)
	top.add_child(info_top)
	info_top.add_child(Estilos_UI.texto(str(producto.get("titulo", "")), 14, Estilos_UI.TINTA, 700))
	info_top.add_child(Estilos_UI.texto(str(producto.get("subtitulo", "")), 10, color, 600))

	var desc := Estilos_UI.texto(str(producto.get("descripcion", "")), 11, Estilos_UI.TINTA_SUAVE, 500)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(0, 32)
	v.add_child(desc)

	var btn := Estilos_UI.boton(str(producto.get("precio_real", "1,99 €")), "suave", "", color, 36)
	btn.name = "Comprar_%s" % id
	btn.add_theme_font_size_override("font_size", 13)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.pressed.connect(_On_Pulsar_Compra_IAP.bind(producto))
	v.add_child(btn)

	_compras_refs[id] = {"producto": producto, "card": card, "btn": btn}
	return card


# ----------------------------------------------------------------------------
# Sección 3: Clínica de rejuvenecimiento y cuidado exprés (euros de partida)
# ----------------------------------------------------------------------------

func _Crear_Seccion_Clinica() -> VBoxContainer:
	var seccion := VBoxContainer.new()
	seccion.name = "Seccion_Clinica"
	seccion.add_theme_constant_override("separation", 11)
	seccion.add_child(_Cabecera_Seccion(
		"Clínica y cuidado", "Servicios pagados con euros de tu partida.",
		"EUROS DEL JUEGO", Color(TEAL, 0.12), TEAL))

	seccion.add_child(_Crear_Tarjeta_Edad_Biologica())

	var lista_rej := VBoxContainer.new()
	lista_rej.name = "Lista_Rejuvenecimiento"
	lista_rej.add_theme_constant_override("separation", 9)
	seccion.add_child(lista_rej)
	for producto in Recompensas_Catalogo.Servicios_De_Grupo(
			Recompensas_Catalogo.GRUPO_REJUVENECIMIENTO):
		lista_rej.add_child(_Crear_Tarjeta_Servicio(producto))

	var fila_cuidado := HBoxContainer.new()
	fila_cuidado.name = "Fila_Cuidado"
	fila_cuidado.add_theme_constant_override("separation", 12)
	seccion.add_child(fila_cuidado)
	for producto in Recompensas_Catalogo.Servicios_De_Grupo(Recompensas_Catalogo.GRUPO_CUIDADO):
		var card := _Crear_Tarjeta_Cuidado(producto)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila_cuidado.add_child(card)

	return seccion


func _Crear_Tarjeta_Edad_Biologica() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "Tarjeta_Edad_Biologica"
	panel.set_meta("_tema_aplicado", true)
	panel.add_theme_stylebox_override("panel", Estilos_UI.caja_tarjeta(16, 2))

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 15)
	margen.add_theme_constant_override("margin_right", 15)
	margen.add_theme_constant_override("margin_top", 12)
	margen.add_theme_constant_override("margin_bottom", 11)
	panel.add_child(margen)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	margen.add_child(v)

	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 8)
	v.add_child(cab)
	cab.add_child(Estilos_UI.texto("Edad biológica", 13, Estilos_UI.TINTA, 700))
	var relleno := Control.new()
	relleno.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	relleno.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cab.add_child(relleno)
	_lbl_edad_hero = Estilos_UI.titulo("18 años", 16, TEAL)
	cab.add_child(_lbl_edad_hero)
	_lbl_rejuvenecido_hero = Estilos_UI.texto("mínimo 18", 11, Estilos_UI.TINTA_FANTASMA, 600)
	_lbl_rejuvenecido_hero.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cab.add_child(_lbl_rejuvenecido_hero)

	_medidor_edad = Visual_Bienestar.Medidor_Edad.new()
	_medidor_edad.fondo_oscuro = false
	_medidor_edad.custom_minimum_size = Vector2(0, 24)
	v.add_child(_medidor_edad)

	var pie := HBoxContainer.new()
	pie.add_theme_constant_override("separation", 8)
	v.add_child(pie)
	pie.add_child(Estilos_UI.texto("18", 9, Estilos_UI.TINTA_FANTASMA, 600))
	var nota := Estilos_UI.texto(
		"Cada sesión sube el precio de la siguiente", 10, Estilos_UI.TINTA_FANTASMA, 500)
	nota.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nota.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pie.add_child(nota)
	pie.add_child(Estilos_UI.texto("100", 9, Estilos_UI.TINTA_FANTASMA, 600))

	return panel


func _Crear_Tarjeta_Servicio(producto: Dictionary) -> PanelContainer:
	var id := str(producto.get("id", ""))
	var color := _Color(producto.get("color", TEAL))
	var card := PanelContainer.new()
	card.name = "Servicio_%s" % id
	card.set_meta("_tema_aplicado", true)
	card.add_theme_stylebox_override("panel", Estilos_UI.caja_tarjeta(15, 2))

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 13)
	margen.add_theme_constant_override("margin_right", 13)
	margen.add_theme_constant_override("margin_top", 11)
	margen.add_theme_constant_override("margin_bottom", 11)
	card.add_child(margen)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	margen.add_child(fila)

	fila.add_child(_Icono_Suave(str(producto.get("icono", "sparkles")), 42, 20, color))

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 2)
	fila.add_child(info)

	var fila_titulo := HBoxContainer.new()
	fila_titulo.add_theme_constant_override("separation", 7)
	info.add_child(fila_titulo)
	fila_titulo.add_child(Estilos_UI.texto(str(producto.get("titulo", "")), 14, Estilos_UI.TINTA, 700))
	fila_titulo.add_child(_Crear_Mini_Pill(str(producto.get("subtitulo", "")),
		Color(color, 0.10), color))

	var desc := Estilos_UI.texto(str(producto.get("descripcion", "")), 11, Estilos_UI.TINTA_SUAVE, 500)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(desc)

	var estado := Estilos_UI.texto("", 10, Estilos_UI.TINTA_FANTASMA, 600)
	info.add_child(estado)

	var derecha := VBoxContainer.new()
	derecha.alignment = BoxContainer.ALIGNMENT_CENTER
	derecha.custom_minimum_size = Vector2(102, 0)
	derecha.add_theme_constant_override("separation", 4)
	fila.add_child(derecha)

	var precio := Estilos_UI.titulo("0 €", 16, Estilos_UI.TINTA)
	precio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	derecha.add_child(precio)

	var btn := Estilos_UI.boton("Reservar", "primario", "", color, 34)
	btn.name = "Reservar_%s" % id
	btn.add_theme_font_size_override("font_size", 11)
	btn.custom_minimum_size = Vector2(98, 34)
	_Aplicar_Estilo_Deshabilitado(btn, color)
	btn.pressed.connect(_Abrir_Tratamiento.bind(producto))
	derecha.add_child(btn)

	_servicios_refs[id] = {
		"producto": producto,
		"btn": btn,
		"precio": precio,
		"estado": estado,
		"color": color,
		"rejuvenece": _Es_Rejuvenecimiento(producto),
	}
	return card


func _Crear_Tarjeta_Cuidado(producto: Dictionary) -> PanelContainer:
	var id := str(producto.get("id", ""))
	var color := _Color(producto.get("color", CORAL))
	var card := PanelContainer.new()
	card.name = "Servicio_%s" % id
	card.set_meta("_tema_aplicado", true)
	card.add_theme_stylebox_override("panel", Estilos_UI.caja_tarjeta(15, 2))

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 13)
	margen.add_theme_constant_override("margin_right", 13)
	margen.add_theme_constant_override("margin_top", 12)
	margen.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margen)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	margen.add_child(v)

	var cabecera := HBoxContainer.new()
	cabecera.add_theme_constant_override("separation", 9)
	v.add_child(cabecera)
	cabecera.add_child(_Icono_Suave(str(producto.get("icono", "heart-pulse")), 36, 18, color))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 0)
	cabecera.add_child(info)
	info.add_child(Estilos_UI.texto(str(producto.get("titulo", "")), 14, Estilos_UI.TINTA, 700))
	info.add_child(Estilos_UI.texto(str(producto.get("subtitulo", "")), 10, color, 600))

	var desc := Estilos_UI.texto(str(producto.get("descripcion", "")), 11, Estilos_UI.TINTA_SUAVE, 500)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(0, 32)
	v.add_child(desc)

	var estado := Estilos_UI.texto("", 10, Estilos_UI.TINTA_FANTASMA, 600)
	v.add_child(estado)

	var pie := HBoxContainer.new()
	pie.add_theme_constant_override("separation", 8)
	v.add_child(pie)
	var precio := Estilos_UI.titulo("0 €", 16, Estilos_UI.TINTA)
	precio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	precio.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pie.add_child(precio)

	var btn := Estilos_UI.boton("Comprar", "primario", "", color, 34)
	btn.name = "Comprar_%s" % id
	btn.add_theme_font_size_override("font_size", 11)
	btn.custom_minimum_size = Vector2(96, 34)
	_Aplicar_Estilo_Deshabilitado(btn, color)
	btn.pressed.connect(_Abrir_Tratamiento.bind(producto))
	pie.add_child(btn)

	_servicios_refs[id] = {
		"producto": producto,
		"btn": btn,
		"precio": precio,
		"estado": estado,
		"color": color,
		"rejuvenece": false,
	}
	return card


func _Crear_Pie_Informacion() -> MarginContainer:
	var margen := MarginContainer.new()
	margen.name = "Pie_Informacion"
	margen.add_theme_constant_override("margin_left", 8)
	margen.add_theme_constant_override("margin_right", 8)
	margen.add_theme_constant_override("margin_top", 2)
	margen.add_theme_constant_override("margin_bottom", 6)

	var texto := Estilos_UI.parrafo(
		"Las compras integradas se gestionan de forma segura. " +
		"Los servicios de clínica y cuidado usan euros de tu partida.",
		11, Estilos_UI.TINTA_FANTASMA)
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	margen.add_child(texto)
	return margen


# ----------------------------------------------------------------------------
# Helpers visuales
# ----------------------------------------------------------------------------

func _Cabecera_Seccion(titulo: String, subtitulo: String, pill: String = "",
		pill_fondo: Color = Color.TRANSPARENT, pill_color: Color = Color.TRANSPARENT) -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 1)
	fila.add_child(v)
	v.add_child(Estilos_UI.titulo(titulo, 18, Estilos_UI.TINTA))
	v.add_child(Estilos_UI.texto(subtitulo, 11, Estilos_UI.TINTA_SUAVE, 500))
	if pill != "":
		var p := _Crear_Mini_Pill(pill, pill_fondo, pill_color)
		p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(p)
	return fila


func _Icono_Suave(nombre: String, tam_caja: int, tam_icono: int, color: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.set_meta("_tema_aplicado", true)
	p.custom_minimum_size = Vector2(tam_caja, tam_caja)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Color(color, 0.11), 11, Color(color, 0.18), 1, 0))
	var c := CenterContainer.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(Estilos_UI.icono_rect(nombre, tam_icono, color))
	p.add_child(c)
	return p


func _Boton_Precio_Claro(texto_precio: String, color_acento: Color) -> Button:
	var btn := Button.new()
	btn.text = texto_precio
	btn.custom_minimum_size = Vector2(88, 38)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.set_meta("_tema_aplicado", true)
	btn.set_meta("_estilo_propio", true)
	btn.add_theme_font_override("font", Estilos_UI.fuente_ui(700))
	btn.add_theme_font_size_override("font_size", 13)
	var bg := Color("#fbbf24")
	var st_n := Estilos_UI.caja(bg, 10, color_acento, 0, 0)
	st_n.border_width_bottom = 3
	st_n.content_margin_left = 14
	st_n.content_margin_right = 14
	var st_h := st_n.duplicate() as StyleBoxFlat
	st_h.bg_color = bg.lightened(0.08)
	var st_p := st_n.duplicate() as StyleBoxFlat
	st_p.bg_color = bg.darkened(0.08)
	st_p.border_width_bottom = 1
	btn.add_theme_stylebox_override("normal", st_n)
	btn.add_theme_stylebox_override("hover", st_h)
	btn.add_theme_stylebox_override("pressed", st_p)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		btn.add_theme_color_override(c, Estilos_UI.NAVY_OSCURO)
	Estilos_UI.animar_presion(btn)
	return btn


func _Boton_Precio_Oscuro(texto_precio: String) -> Button:
	var btn := Estilos_UI.boton(texto_precio, "primario", "", Estilos_UI.NAVY, 38)
	btn.custom_minimum_size = Vector2(88, 38)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 13)
	return btn


func _Crear_Mini_Pill(texto: String, fondo: Color, color_texto: Color) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.set_meta("_tema_aplicado", true)
	var estilo := Estilos_UI.caja(fondo, 999, Color(color_texto, 0.16), 1, 0)
	estilo.content_margin_left = 8
	estilo.content_margin_right = 8
	estilo.content_margin_top = 3
	estilo.content_margin_bottom = 3
	pill.add_theme_stylebox_override("panel", estilo)
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lbl := Estilos_UI.texto(texto, 9, color_texto, 700)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(lbl)
	return pill


func _Etiqueta_Mini(texto: String, color: Color) -> Label:
	var lbl := Estilos_UI.texto(texto, 9, color, 700)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl


func _Color(valor) -> Color:
	if valor is Color:
		return valor
	return Color(str(valor))


func _Formatear_Numero(numero: int) -> String:
	var negativo := numero < 0
	var s := str(absi(numero))
	var salida := ""
	var contador := 0
	for i in range(s.length() - 1, -1, -1):
		salida = s[i] + salida
		contador += 1
		if contador % 3 == 0 and i > 0:
			salida = "." + salida
	return ("-" if negativo else "") + salida


func _Formatear_Euros(valor: int) -> String:
	return "%s €" % _Formatear_Numero(valor)


func _Aplicar_Estilo_Deshabilitado(btn: Button, color: Color) -> void:
	var st := Estilos_UI.caja(Color(color, 0.09), 10, Color(color, 0.20), 1, 0)
	btn.add_theme_stylebox_override("disabled", st)
	btn.add_theme_color_override("font_disabled_color", color)
	btn.add_theme_color_override("icon_disabled_color", color)


func _Es_Rejuvenecimiento(producto: Dictionary) -> bool:
	for recompensa in Recompensas_Catalogo.Obtener_Recompensas(producto):
		if recompensa is Dictionary and str(recompensa.get("tipo", "")) == "rejuvenecer":
			return true
	return false


# ----------------------------------------------------------------------------
# Sincronización de estado
# ----------------------------------------------------------------------------

func _On_Estado_Cambiado() -> void:
	_Sincronizar()


func _Sincronizar(animar: bool = true) -> void:
	if not _construido:
		return
	_Aplicar_Filtro(_filtro_actual)
	_Actualizar_Edad()
	_Actualizar_Dinero(animar)
	_Actualizar_Servicios()


func _Actualizar_Edad() -> void:
	var edad := Recompensas.Obtener_Edad_Actual()
	var rejuvenecidos := Recompensas.Obtener_Anios_Rejuvenecidos()
	if _lbl_edad != null:
		_lbl_edad.text = "%d años" % edad
	if _lbl_edad_rejuvenecida != null:
		_lbl_edad_rejuvenecida.text = ("−%d" % rejuvenecidos) if rejuvenecidos > 0 else ""
		_lbl_edad_rejuvenecida.visible = rejuvenecidos > 0
	if _lbl_edad_hero != null:
		_lbl_edad_hero.text = "%d años" % edad
	if _lbl_rejuvenecido_hero != null:
		if rejuvenecidos > 0:
			_lbl_rejuvenecido_hero.text = "· −%d recuperados" % rejuvenecidos
			_lbl_rejuvenecido_hero.add_theme_color_override("font_color", TEAL)
		else:
			_lbl_rejuvenecido_hero.text = "· mínimo 18"
			_lbl_rejuvenecido_hero.add_theme_color_override("font_color", Estilos_UI.TINTA_FANTASMA)
	if _medidor_edad != null and is_instance_valid(_medidor_edad):
		_medidor_edad.Establecer(edad, edad + rejuvenecidos, false)


func _Actualizar_Dinero(animar: bool = true) -> void:
	if _lbl_dinero == null:
		return
	var objetivo := int(round(Variables_Dinamicas.Dinero))
	_lbl_dinero.add_theme_color_override("font_color",
		Estilos_UI.EXITO if objetivo >= 0 else Estilos_UI.PELIGRO)
	if _tween_dinero != null and _tween_dinero.is_valid():
		_tween_dinero.kill()
	if not animar or _dinero_mostrado == -999999 or not is_inside_tree():
		_dinero_mostrado = objetivo
		_lbl_dinero.text = _Formatear_Euros(objetivo)
		return
	if _dinero_mostrado == objetivo:
		_lbl_dinero.text = _Formatear_Euros(objetivo)
		return
	var desde := _dinero_mostrado
	_dinero_mostrado = objetivo
	_tween_dinero = create_tween()
	_tween_dinero.tween_method(Callable(self, "_Poner_Dinero_Animado"),
		float(desde), float(objetivo), 0.40).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if _badge_dinero != null and is_instance_valid(_badge_dinero):
		_badge_dinero.pivot_offset = _badge_dinero.size * 0.5
		var tw := create_tween()
		tw.tween_property(_badge_dinero, "scale", Vector2(1.08, 1.08), 0.10)
		tw.tween_property(_badge_dinero, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _Poner_Dinero_Animado(valor: float) -> void:
	if _lbl_dinero != null and is_instance_valid(_lbl_dinero):
		_lbl_dinero.text = _Formatear_Euros(int(round(valor)))


func _Actualizar_Servicios() -> void:
	var dinero := int(round(Variables_Dinamicas.Dinero))
	var edad := Recompensas.Obtener_Edad_Actual()
	for id in _servicios_refs:
		var ref: Dictionary = _servicios_refs[id]
		var btn: Button = ref["btn"]
		var precio: Label = ref["precio"]
		var estado: Label = ref["estado"]
		if not is_instance_valid(btn) or not is_instance_valid(precio) or not is_instance_valid(estado):
			continue
		var coste := int(round(Recompensas.Obtener_Coste_Servicio(id)))
		var rejuvenece := bool(ref.get("rejuvenece", false))
		var bloqueado_edad := rejuvenece and edad <= 18
		var sin_dinero := dinero < coste
		precio.text = _Formatear_Euros(coste)
		precio.add_theme_color_override("font_color",
			Estilos_UI.PELIGRO if sin_dinero and not bloqueado_edad else Estilos_UI.TINTA)
		if bloqueado_edad:
			estado.text = "Edad mínima alcanzada"
			estado.add_theme_color_override("font_color", Estilos_UI.TINTA_FANTASMA)
			btn.disabled = true
			btn.text = "Al máximo"
		elif sin_dinero:
			estado.text = "Te faltan %s" % _Formatear_Euros(coste - dinero)
			estado.add_theme_color_override("font_color", Estilos_UI.PELIGRO)
			btn.disabled = true
			btn.text = "Sin saldo"
		else:
			estado.text = "Disponible" if not rejuvenece else "Sesión disponible"
			estado.add_theme_color_override("font_color", Estilos_UI.TINTA_FANTASMA)
			btn.disabled = false
			btn.text = "Reservar" if rejuvenece else "Comprar"


# ----------------------------------------------------------------------------
# Flujos: beta (anuncios y compras IAP) + servicios en partida
# ----------------------------------------------------------------------------

func _On_Pulsar_Anuncio(_producto: Dictionary) -> void:
	_Reproducir_SFX("pop")
	_Mostrar_Toast("No disponible en esta beta", "info")


func _On_Pulsar_Compra_IAP(_producto: Dictionary) -> void:
	_Reproducir_SFX("pop")
	_Mostrar_Toast("No disponible en esta beta", "info")


func _Abrir_Tratamiento(producto: Dictionary) -> void:
	if _modal_tratamiento != null and is_instance_valid(_modal_tratamiento):
		return
	var id := str(producto.get("id", ""))
	var coste := Recompensas.Obtener_Coste_Servicio(id)
	var dinero := float(Variables_Dinamicas.Dinero)
	if dinero < coste:
		_Mostrar_Toast("Te faltan %s." % _Formatear_Euros(int(ceil(coste - dinero))), "error")
		return
	var rejuvenece := _Es_Rejuvenecimiento(producto)
	var edad_actual := Recompensas.Obtener_Edad_Actual()
	if rejuvenece and edad_actual <= 18:
		_Mostrar_Toast("Tu Sim ya tiene 18 años: no puede rejuvenecer más.", "info")
		return

	var modal := MODAL_TRATAMIENTO.new()
	modal.servicio = producto
	modal.coste = coste
	modal.dinero_disponible = dinero
	modal.edad_actual = edad_actual
	modal.edad_objetivo = maxi(18, edad_actual - _Anios_Del_Servicio(producto)) if rejuvenece else edad_actual
	modal.es_rejuvenecimiento = rejuvenece
	modal.confirmado.connect(_Procesar_Tratamiento.bind(modal, producto))
	modal.cerrado.connect(func() -> void: _modal_tratamiento = null)
	_modal_tratamiento = modal
	add_child(modal)
	_Reproducir_SFX("pop")


func _Procesar_Tratamiento(modal: Modal_Tratamiento, producto: Dictionary) -> void:
	if not is_instance_valid(modal):
		return
	modal.Mostrar_Procesando()
	var resultado: Dictionary = await Recompensas.Comprar_Servicio(str(producto.get("id", "")))
	if not is_instance_valid(modal):
		return
	if bool(resultado.get("ok", false)):
		modal.Mostrar_Exito(resultado)
		_Reproducir_SFX("coin")
	else:
		modal.Mostrar_Error(str(resultado.get("mensaje", "No se pudo completar el tratamiento.")))
		_Reproducir_SFX("pop")


func _Anios_Del_Servicio(producto: Dictionary) -> int:
	for recompensa in Recompensas_Catalogo.Obtener_Recompensas(producto):
		if recompensa is Dictionary and str(recompensa.get("tipo", "")) == "rejuvenecer":
			return maxi(1, int(recompensa.get("cantidad", 1)))
	return 0


func _Ver_Anuncio(producto: Dictionary) -> void:
	if _modal_anuncio != null and is_instance_valid(_modal_anuncio):
		return
	var solicitud: Dictionary = Recompensas.Solicitar_Anuncio(str(producto.get("id", "")))
	if not bool(solicitud.get("ok", false)):
		_Mostrar_Toast(str(solicitud.get("mensaje", "No se pudo abrir el anuncio.")), "info")
		return

	var modal := MODAL_ANUNCIO.new()
	modal.anuncio = producto
	modal.token = int(solicitud.get("token", 0))
	modal.visto.connect(_Completar_Anuncio.bind(modal))
	modal.cancelado.connect(_Cancelar_Anuncio)
	modal.cerrado.connect(func() -> void: _modal_anuncio = null)
	_modal_anuncio = modal
	add_child(modal)
	_Reproducir_SFX("pop")


func _Completar_Anuncio(token: int, modal: Modal_Anuncio_Bienestar) -> void:
	var resultado: Dictionary = await Recompensas.Completar_Anuncio(token)
	if not is_instance_valid(modal):
		return
	if bool(resultado.get("ok", false)):
		modal.Mostrar_Recompensa(resultado)
		_Reproducir_SFX("coin")
	else:
		modal.Mostrar_Error(str(resultado.get("mensaje", "No se pudo verificar la recompensa.")))
		_Reproducir_SFX("pop")


func _Cancelar_Anuncio(token: int) -> void:
	Recompensas.Cancelar_Anuncio(token)
	_Mostrar_Toast("Anuncio cerrado. No se ha concedido la recompensa.", "info")


# ----------------------------------------------------------------------------
# Toasts y sonido
# ----------------------------------------------------------------------------

func _Crear_Toast() -> void:
	_toast_raiz = Control.new()
	_toast_raiz.name = "Toasts_Bienestar"
	_toast_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_toast_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_raiz.z_index = 90
	add_child(_toast_raiz)

	var margen := MarginContainer.new()
	margen.set_anchors_preset(Control.PRESET_FULL_RECT)
	margen.add_theme_constant_override("margin_left", 48)
	margen.add_theme_constant_override("margin_right", 48)
	margen.add_theme_constant_override("margin_bottom", 24)
	margen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_raiz.add_child(margen)

	var columna := VBoxContainer.new()
	columna.alignment = BoxContainer.ALIGNMENT_END
	columna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margen.add_child(columna)

	_toast_panel = PanelContainer.new()
	_toast_panel.name = "Toast"
	_toast_panel.visible = false
	_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := Estilos_UI.caja(Color("#111927"), 14, Color(1, 1, 1, 0.12), 1, 3)
	st.content_margin_left = 14
	st.content_margin_right = 14
	st.content_margin_top = 10
	st.content_margin_bottom = 10
	_toast_panel.add_theme_stylebox_override("panel", st)
	columna.add_child(_toast_panel)
	_toast_panel.visibility_changed.connect(_On_Toast_Visibility_Changed)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	_toast_panel.add_child(h)
	var acento := ColorRect.new()
	acento.name = "Acento"
	acento.custom_minimum_size = Vector2(4, 24)
	acento.color = Estilos_UI.AZUL_CLARO
	acento.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(acento)
	_toast_icono = Estilos_UI.icono_rect("info", 18, Estilos_UI.AZUL_CLARO)
	h.add_child(_toast_icono)
	_toast_label = Estilos_UI.texto("", 13, Color.WHITE, 600)
	_toast_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_label.custom_minimum_size = Vector2(0, 24)
	h.add_child(_toast_label)


func _On_Toast_Visibility_Changed() -> void:
	if _toast_panel != null and _toast_panel.visible and not _toast_mostrando:
		_toast_panel.visible = false


func _Mostrar_Toast(mensaje: String, tipo: String = "info") -> void:
	if _toast_panel == null:
		return
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	var color := Estilos_UI.AZUL_CLARO
	var icono := "info"
	if tipo == "exito":
		color = Estilos_UI.EXITO
		icono = "circle-check"
	elif tipo == "error":
		color = Estilos_UI.PELIGRO
		icono = "triangle-alert"
	_toast_icono.texture = Estilos_UI.icono(icono)
	_toast_icono.self_modulate = color
	var acento := _toast_panel.find_child("Acento", true, false) as ColorRect
	if acento != null:
		acento.color = color
	_toast_label.text = mensaje
	_toast_label.add_theme_color_override("font_color", Color.WHITE)
	_toast_mostrando = true
	_toast_panel.visible = true
	_toast_panel.modulate.a = 0.0
	_toast_panel.scale = Vector2(0.97, 0.97)
	if is_inside_tree():
		await get_tree().process_frame
	if not is_instance_valid(_toast_panel):
		return
	_toast_panel.pivot_offset = _toast_panel.size * 0.5
	_toast_tween = create_tween()
	_toast_tween.set_parallel(true)
	_toast_tween.tween_property(_toast_panel, "modulate:a", 1.0, 0.16)
	_toast_tween.tween_property(_toast_panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if _toast_timer != null:
		_toast_timer.start()


func _Ocultar_Toast() -> void:
	if _toast_panel == null or not is_instance_valid(_toast_panel):
		return
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast_panel, "modulate:a", 0.0, 0.18)
	_toast_tween.tween_callback(func() -> void:
		_toast_mostrando = false
		if is_instance_valid(_toast_panel):
			_toast_panel.visible = false
	)


func _Crear_Reproductor_SFX() -> void:
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.name = "SFX_Bienestar"
	_sfx_player.bus = Ajustes.BUS_SFX
	add_child(_sfx_player)


func _Reproducir_SFX(nombre: String) -> void:
	if _sfx_player == null:
		return
	match nombre:
		"coin": _sfx_player.stream = SFX_COIN
		"ding": _sfx_player.stream = SFX_DING
		_: _sfx_player.stream = SFX_POP
	_sfx_player.play()


# ----------------------------------------------------------------------------
# Animación de entrada
# ----------------------------------------------------------------------------

func _Animar_Entrada() -> void:
	if _contenido == null:
		return
	var hijos := _contenido.get_children()
	for i in range(hijos.size()):
		var hijo := hijos[i] as Control
		if hijo == null or not hijo.visible:
			continue
		hijo.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_interval(float(i) * 0.03)
		tw.tween_property(hijo, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
