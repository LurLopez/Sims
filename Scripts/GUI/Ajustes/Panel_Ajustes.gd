class_name Panel_Ajustes
extends CanvasLayer

# ============================================================================
# Panel modal de ajustes (720x1280).
#
# De momento permite regular el volumen de la música y de los efectos de
# sonido, silenciar cada bus por separado y restablecer los valores por
# defecto. Se puede abrir desde el menú principal y desde la cabecera de la
# escena principal. Los valores los persiste el autoload Ajustes.
# ============================================================================

signal cerrado

const ANCHO_TARJETA := 646.0
const COLOR_MUSICA := Color("#d62828")
const COLOR_SFX := Color("#1d7afc")

var _card: PanelContainer
var _barra_musica: Barra_Volumen
var _barra_sfx: Barra_Volumen
var _lbl_musica: Label
var _lbl_sfx: Label
var _btn_mudo_musica: Button
var _btn_mudo_sfx: Button
var _actualizando := false
var _cerrando := false


func _ready() -> void:
	# Los barridos de visibilidad de las pantallas (cambio de pestaña, volver
	# al inicio, etc.) no deben ocultar un modal abierto.
	add_to_group(Gestionar_Visibilidad.GRUPO_OVERLAY_MODAL)
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	_Construir_UI()
	if not Ajustes.ajustes_cambiados.is_connected(_Sincronizar):
		Ajustes.ajustes_cambiados.connect(_Sincronizar)
	_Sincronizar()
	_Animar_Entrada()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_Cerrar()


func _notification(que: int) -> void:
	if que == NOTIFICATION_WM_GO_BACK_REQUEST:
		_Cerrar()


# ----------------------------------------------------------------------------
# Construcción de la interfaz
# ----------------------------------------------------------------------------

func _Construir_UI() -> void:
	var velo := ColorRect.new()
	velo.name = "Velo"
	velo.color = Color(0.06, 0.09, 0.15, 0.68)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	velo.mouse_filter = Control.MOUSE_FILTER_STOP
	velo.gui_input.connect(_on_velo_gui_input)
	add_child(velo)

	var centro := CenterContainer.new()
	centro.name = "Centro"
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centro)

	_card = PanelContainer.new()
	_card.name = "Card_Ajustes"
	_card.custom_minimum_size = Vector2(ANCHO_TARJETA, 0)
	_card.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	_card.add_theme_stylebox_override("panel", Estilos_UI.caja_tarjeta(20, 3))
	centro.add_child(_card)

	var exterior := VBoxContainer.new()
	exterior.add_theme_constant_override("separation", 0)
	_card.add_child(exterior)

	exterior.add_child(_Crear_Banda())

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 26)
	margen.add_theme_constant_override("margin_right", 26)
	margen.add_theme_constant_override("margin_top", 22)
	margen.add_theme_constant_override("margin_bottom", 24)
	exterior.add_child(margen)

	var contenido := VBoxContainer.new()
	contenido.add_theme_constant_override("separation", 14)
	margen.add_child(contenido)

	contenido.add_child(Estilos_UI.parrafo(
		"Ajusta el volumen del juego. Los cambios se guardan automáticamente.",
		13, Estilos_UI.TINTA_SUAVE))

	contenido.add_child(_Crear_Bloque_Volumen(
		"Música", "Banda sonora del menú y del juego", "volume-2",
		COLOR_MUSICA, false))
	contenido.add_child(Estilos_UI.divisor_horizontal())
	contenido.add_child(_Crear_Bloque_Volumen(
		"Efectos de sonido", "Cocina, avisos y sonidos del juego", "sparkles",
		COLOR_SFX, true))

	contenido.add_child(Estilos_UI.separador(2))

	var botones := HBoxContainer.new()
	botones.add_theme_constant_override("separation", 12)
	contenido.add_child(botones)

	var btn_restablecer := Estilos_UI.boton("Restablecer", "secundario", "arrow-left", Estilos_UI.TINTA, 50)
	btn_restablecer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_restablecer.pressed.connect(_Restablecer)
	botones.add_child(btn_restablecer)

	var btn_hecho := Estilos_UI.boton("Hecho", "primario", "check", Estilos_UI.PRIMARIO, 50)
	btn_hecho.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_hecho.pressed.connect(_Cerrar)
	botones.add_child(btn_hecho)


func _Crear_Banda() -> Control:
	var banda := Estilos_UI.BannerRayasBitLife.new(
		Estilos_UI.ROJO_BIT, Estilos_UI.ROJO_BIT_OSCURO, 3.0, 0.075)
	banda.custom_minimum_size = Vector2(0, 66)

	var fila := HBoxContainer.new()
	fila.set_anchors_preset(Control.PRESET_FULL_RECT)
	fila.offset_left = 22
	fila.offset_right = -22
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 10)
	banda.add_child(fila)

	fila.add_child(Estilos_UI.icono_rect("settings", 22, Color.WHITE))
	fila.add_child(Estilos_UI.titulo("AJUSTES", 19, Color.WHITE))
	return banda


# ----------------------------------------------------------------------------
# Bloque de volumen (música o efectos)
# ----------------------------------------------------------------------------

func _Crear_Bloque_Volumen(titulo: String, subtitulo: String, icono: String,
		color: Color, es_sfx: bool) -> VBoxContainer:
	var bloque := VBoxContainer.new()
	bloque.add_theme_constant_override("separation", 8)

	var cabecera := HBoxContainer.new()
	cabecera.add_theme_constant_override("separation", 12)
	bloque.add_child(cabecera)

	cabecera.add_child(Estilos_UI.badge_icono(icono, 42, 20, color, Color.WHITE, 11))

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 1)
	cabecera.add_child(info)
	info.add_child(Estilos_UI.texto(titulo, 16, Estilos_UI.TINTA, 700))
	info.add_child(Estilos_UI.texto(subtitulo, 12, Estilos_UI.TINTA_SUAVE, 500))

	var porcentaje := Estilos_UI.titulo("0%", 17, color)
	porcentaje.custom_minimum_size = Vector2(48, 0)
	porcentaje.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cabecera.add_child(porcentaje)

	var btn_mudo := Estilos_UI.boton_icono("volume-2", color, 38)
	btn_mudo.name = "Boton_Mudo_%s" % ("SFX" if es_sfx else "Musica")
	btn_mudo.pressed.connect(func(): _Alternar_Silencio(es_sfx))
	cabecera.add_child(btn_mudo)

	var barra := Barra_Volumen.new()
	barra.name = "Barra_%s" % ("SFX" if es_sfx else "Musica")
	barra.color = color
	barra.tooltip_text = "Volumen de los efectos de sonido" if es_sfx else "Volumen de la música"
	barra.valor_cambiado.connect(func(valor: float): _on_volumen_cambiado(es_sfx, valor))
	barra.arrastre_terminado.connect(func(): _on_arrastre_terminado(es_sfx))
	bloque.add_child(barra)

	if es_sfx:
		var fila_prueba := HBoxContainer.new()
		fila_prueba.alignment = BoxContainer.ALIGNMENT_END
		var btn_probar := Estilos_UI.boton("Probar sonido", "secundario", "play", color, 36)
		btn_probar.custom_minimum_size = Vector2(168, 36)
		btn_probar.add_theme_font_size_override("font_size", 13)
		btn_probar.pressed.connect(func():
			if Ajustes.Esta_Silenciado_SFX():
				Ajustes.Establecer_Silencio_SFX(false)
			Ajustes.Probar_Efecto_Sonido())
		fila_prueba.add_child(btn_probar)
		bloque.add_child(fila_prueba)

	if es_sfx:
		_barra_sfx = barra
		_lbl_sfx = porcentaje
		_btn_mudo_sfx = btn_mudo
	else:
		_barra_musica = barra
		_lbl_musica = porcentaje
		_btn_mudo_musica = btn_mudo
	return bloque


# ----------------------------------------------------------------------------
# Estado de los controles
# ----------------------------------------------------------------------------

func _Sincronizar() -> void:
	if _barra_musica == null or _barra_sfx == null:
		return
	_actualizando = true
	_barra_musica.Establecer_Valor(Ajustes.Obtener_Volumen_Musica())
	_barra_sfx.Establecer_Valor(Ajustes.Obtener_Volumen_SFX())
	_actualizando = false
	_Actualizar_Textos()


func _Actualizar_Textos() -> void:
	if _lbl_musica == null or _lbl_sfx == null:
		return
	_lbl_musica.text = "%d%%" % int(round(Ajustes.Obtener_Volumen_Musica() * 100.0))
	_lbl_sfx.text = "%d%%" % int(round(Ajustes.Obtener_Volumen_SFX() * 100.0))

	var mudo_musica := Ajustes.Esta_Silenciado_Musica()
	var mudo_sfx := Ajustes.Esta_Silenciado_SFX()
	_btn_mudo_musica.icon = Estilos_UI.icono("x" if mudo_musica else "volume-2")
	_btn_mudo_musica.tooltip_text = "Activar la música" if mudo_musica else "Silenciar la música"
	_btn_mudo_sfx.icon = Estilos_UI.icono("x" if mudo_sfx else "volume-2")
	_btn_mudo_sfx.tooltip_text = "Activar los efectos" if mudo_sfx else "Silenciar los efectos"


func _on_volumen_cambiado(es_sfx: bool, valor: float) -> void:
	if _actualizando:
		return
	if es_sfx:
		Ajustes.Establecer_Volumen_SFX(valor)
		if valor > 0.001 and Ajustes.Esta_Silenciado_SFX():
			Ajustes.Establecer_Silencio_SFX(false)
	else:
		Ajustes.Establecer_Volumen_Musica(valor)
		if valor > 0.001 and Ajustes.Esta_Silenciado_Musica():
			Ajustes.Establecer_Silencio_Musica(false)
	_Actualizar_Textos()


func _on_arrastre_terminado(es_sfx: bool) -> void:
	if es_sfx and not Ajustes.Esta_Silenciado_SFX() and Ajustes.Obtener_Volumen_SFX() > 0.001:
		Ajustes.Probar_Efecto_Sonido()


func _Alternar_Silencio(es_sfx: bool) -> void:
	if es_sfx:
		Ajustes.Alternar_Silencio_SFX()
		if not Ajustes.Esta_Silenciado_SFX():
			Ajustes.Probar_Efecto_Sonido()
	else:
		Ajustes.Alternar_Silencio_Musica()
	_Actualizar_Textos()


func _Restablecer() -> void:
	Ajustes.Restablecer_Audio()
	Ajustes.Probar_Efecto_Sonido()


# ----------------------------------------------------------------------------
# Cierre
# ----------------------------------------------------------------------------

func _on_velo_gui_input(event: InputEvent) -> void:
	var pulsado := false
	if event is InputEventMouseButton:
		pulsado = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventScreenTouch:
		pulsado = event.pressed
	if pulsado:
		_Cerrar()


func _Cerrar() -> void:
	if _cerrando:
		return
	_cerrando = true
	cerrado.emit()
	queue_free()


func _Animar_Entrada() -> void:
	if _card == null:
		return
	_card.modulate.a = 0.0
	_card.scale = Vector2(0.96, 0.96)
	_card.pivot_offset = Vector2(ANCHO_TARJETA * 0.5, 260)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_card, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_card, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ============================================================================
# Barra de volumen táctil (control propio, sin depender del tema del HSlider)
# ============================================================================

class Barra_Volumen:
	extends Control

	signal valor_cambiado(valor: float)
	signal arrastre_terminado

	const MARGEN_X := 16.0
	const ALTO_BARRA := 12.0
	const RADIO_PERILLA := 12.0

	var valor: float = 0.85
	var color: Color = Color("#d62828")

	var _arrastrando := false
	var _estilo_fondo: StyleBoxFlat
	var _estilo_relleno: StyleBoxFlat


	func _ready() -> void:
		custom_minimum_size = Vector2(0, 44)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		focus_mode = Control.FOCUS_ALL
		_estilo_fondo = Estilos_UI.barra_fondo()
		_estilo_relleno = Estilos_UI.barra_relleno(color)


	func Establecer_Valor(nuevo: float, emitir: bool = false) -> void:
		valor = clampf(nuevo, 0.0, 1.0)
		queue_redraw()
		if emitir:
			valor_cambiado.emit(valor)


	func _draw() -> void:
		var ancho_util := maxf(size.x - MARGEN_X * 2.0, 1.0)
		var centro_y := size.y * 0.5
		var rect := Rect2(MARGEN_X, centro_y - ALTO_BARRA * 0.5, ancho_util, ALTO_BARRA)
		draw_style_box(_estilo_fondo, rect)
		if valor > 0.001:
			draw_style_box(_estilo_relleno, Rect2(rect.position, Vector2(ancho_util * valor, ALTO_BARRA)))

		var centro := Vector2(MARGEN_X + ancho_util * valor, centro_y)
		draw_circle(centro + Vector2(0, 2), RADIO_PERILLA + 1.0, Color(0.06, 0.09, 0.15, 0.16))
		draw_circle(centro, RADIO_PERILLA, Color.WHITE)
		draw_arc(centro, RADIO_PERILLA - 1.5, 0.0, TAU, 40, color, 3.0, true)
		if has_focus():
			draw_arc(centro, RADIO_PERILLA + 4.0, 0.0, TAU, 40, Color(color, 0.4), 2.0, true)


	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_arrastrando = true
				grab_focus()
				_Actualizar_Desde_X(event.position.x, true)
				accept_event()
			elif _arrastrando:
				_Finalizar_Arrastre(event.position.x)
				accept_event()
		elif event is InputEventScreenTouch:
			if event.pressed:
				_arrastrando = true
				grab_focus()
				_Actualizar_Desde_X(event.position.x, true)
				accept_event()
			elif _arrastrando:
				_Finalizar_Arrastre(event.position.x)
				accept_event()
		elif event is InputEventMouseMotion and _arrastrando:
			_Actualizar_Desde_X(event.position.x, true)
			accept_event()
		elif event is InputEventScreenDrag and _arrastrando:
			_Actualizar_Desde_X(event.position.x, true)
			accept_event()
		elif event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_LEFT:
				Establecer_Valor(valor - 0.05, true)
				accept_event()
			elif event.keycode == KEY_RIGHT:
				Establecer_Valor(valor + 0.05, true)
				accept_event()


	func _Actualizar_Desde_X(x: float, emitir: bool) -> void:
		var ancho_util := maxf(size.x - MARGEN_X * 2.0, 1.0)
		Establecer_Valor((x - MARGEN_X) / ancho_util, emitir)


	func _Finalizar_Arrastre(x: float) -> void:
		if not _arrastrando:
			return
		_arrastrando = false
		_Actualizar_Desde_X(x, true)
		arrastre_terminado.emit()
