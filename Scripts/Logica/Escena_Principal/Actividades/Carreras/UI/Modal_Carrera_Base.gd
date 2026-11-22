class_name Modal_Carrera_Base
extends CanvasLayer# ============================================================================
# Base común de los modales de Carreras y Exámenes.
#
# Mantiene la identidad visual del juego (banda roja, tarjetas blancas,
# tipografía Bricolage/DM Sans) y resuelve la disposición móvil de una vez:
# fondo oscurecido, tarjeta a pantalla casi completa, cabecera fija, contenido
# desplazable y pie de acciones siempre visible. Los modales concretos solo
# rellenan `area_fija`, `contenido` y `pie`.
# ============================================================================

signal cerrado

const ANCHO_MAX := 688.0
const MARGEN_LATERAL := 16.0

const COLORES_CARRERA := {
	"Ingenieria_Informatica": Color("#1d7afc"),
	"Derecho": Color("#7c3aed"),
	"Medicina": Color("#d62828"),
	"Bellas_Artes": Color("#db2777"),
}

const ICONOS_CARRERA := {
	"Ingenieria_Informatica": "zap",
	"Derecho": "scale",
	"Medicina": "stethoscope",
	"Bellas_Artes": "palette",
}

const NOMBRES_CARRERA := {
	"Ingenieria_Informatica": "Ingeniería Informática",
	"Derecho": "Derecho",
	"Medicina": "Medicina",
	"Bellas_Artes": "Bellas Artes",
}


static func color_carrera(nombre: String) -> Color:
	return COLORES_CARRERA.get(nombre, Estilos_UI.PRIMARIO)


static func icono_carrera(nombre: String) -> String:
	return str(ICONOS_CARRERA.get(nombre, "graduation-cap"))


static func nombre_carrera(nombre: String) -> String:
	return str(NOMBRES_CARRERA.get(nombre, nombre.replace("_", " ")))

var tarjeta: PanelContainer
var area_fija: VBoxContainer
var contenido: VBoxContainer
var pie: HBoxContainer
var scroll_principal: ScrollContainer

var titulo_modal := "Carrera"
var subtitulo_modal := ""
var eyebrow_modal := ""
var icono_modal := "graduation-cap"
var color_banda := Estilos_UI.ROJO_BIT
var mostrar_cerrar := true
var permitir_cerrar_al_fondo := true

var _raiz: Control
var _velo: ColorRect
var _banda: PanelContainer
var _icono_cabecera: TextureRect
var _lbl_eyebrow: Label
var _lbl_titulo: Label
var _lbl_subtitulo: Label
var _btn_cerrar: Button
var _area_pie: PanelContainer
var _confirmacion: Control
var _cerrando := false


func _ready() -> void:
	layer = 130
	process_mode = Node.PROCESS_MODE_ALWAYS
	_Construir_Base()
	_Al_Listo()
	_Animar_Entrada()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_Solicitar_Cierre()


func _notification(que: int) -> void:
	if que == NOTIFICATION_WM_GO_BACK_REQUEST:
		_Solicitar_Cierre()


# ----------------------------------------------------------------------------
# API para los modales concretos
# ----------------------------------------------------------------------------

# Se llama al terminar de construir la estructura. Los hijos la sobrescriben
# para crear su interfaz inicial.
func _Al_Listo() -> void:
	pass


func actualizar_cabecera(titulo: String, subtitulo: String = "",
		eyebrow: String = "", icono: String = "", color: Color = Color(0, 0, 0, 0)) -> void:
	titulo_modal = titulo
	subtitulo_modal = subtitulo
	eyebrow_modal = eyebrow
	if icono != "":
		icono_modal = icono
	if color.a > 0.0:
		color_banda = color
	if is_node_ready():
		_Refrescar_Cabecera()


func cerrar() -> void:
	if _cerrando:
		return
	_cerrando = true
	cerrado.emit()
	if _raiz == null or not is_instance_valid(_raiz):
		queue_free()
		return
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(tarjeta, "modulate:a", 0.0, 0.12)
	tw.tween_property(_velo, "modulate:a", 0.0, 0.12)
	tw.chain().tween_callback(queue_free)


func mostrar_confirmacion(titulo: String, mensaje: String,
		texto_confirmar: String, al_confirmar: Callable) -> void:
	if _confirmacion != null or _raiz == null:
		return
	var capa := Control.new()
	capa.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.mouse_filter = Control.MOUSE_FILTER_STOP
	_raiz.add_child(capa)
	_confirmacion = capa

	var velo := ColorRect.new()
	velo.color = Color(0.02, 0.04, 0.09, 0.46)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	velo.mouse_filter = Control.MOUSE_FILTER_STOP
	capa.add_child(velo)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(centro)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(380, 0)
	card.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Estilos_UI.SUPERFICIE, 20, Estilos_UI.BORDE, 1, 7))
	centro.add_child(card)

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 22)
	margen.add_theme_constant_override("margin_right", 22)
	margen.add_theme_constant_override("margin_top", 20)
	margen.add_theme_constant_override("margin_bottom", 18)
	card.add_child(margen)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	margen.add_child(v)
	v.add_child(Estilos_UI.titulo(titulo, 21, Estilos_UI.TINTA))
	var p := Estilos_UI.parrafo(mensaje, 14, Estilos_UI.TINTA_SUAVE)
	v.add_child(p)

	var botones := HBoxContainer.new()
	botones.add_theme_constant_override("separation", 10)
	v.add_child(botones)
	var btn_cancelar := Estilos_UI.boton("Cancelar", "secundario", "", Estilos_UI.TINTA, 46)
	btn_cancelar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_cancelar.pressed.connect(_Cerrar_Confirmacion)
	botones.add_child(btn_cancelar)
	var btn_ok := Estilos_UI.boton(texto_confirmar, "peligro", "check", Estilos_UI.PELIGRO, 46)
	btn_ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_ok.pressed.connect(func():
		_Cerrar_Confirmacion()
		if al_confirmar.is_valid():
			al_confirmar.call()
	)
	botones.add_child(btn_ok)


func _Cerrar_Confirmacion() -> void:
	if _confirmacion != null and is_instance_valid(_confirmacion):
		_confirmacion.queue_free()
	_confirmacion = null


# ----------------------------------------------------------------------------
# Construcción
# ----------------------------------------------------------------------------

func _Construir_Base() -> void:
	_raiz = Control.new()
	_raiz.name = "Modal_Carrera"
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_raiz)

	_velo = ColorRect.new()
	_velo.name = "Velo"
	_velo.color = Color(0.03, 0.05, 0.10, 0.62)
	_velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_velo.mouse_filter = Control.MOUSE_FILTER_STOP
	_velo.gui_input.connect(_on_velo_gui_input)
	_raiz.add_child(_velo)

	tarjeta = PanelContainer.new()
	tarjeta.name = "Tarjeta"
	tarjeta.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	var st_tarjeta := Estilos_UI.caja(Estilos_UI.SUPERFICIE, 24, Estilos_UI.BORDE, 1)
	st_tarjeta.shadow_color = Color(0.02, 0.04, 0.10, 0.34)
	st_tarjeta.shadow_size = 18
	st_tarjeta.shadow_offset = Vector2(0, 9)
	tarjeta.add_theme_stylebox_override("panel", st_tarjeta)
	_raiz.add_child(tarjeta)
	_raiz.resized.connect(_Ajustar_Tarjeta)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	tarjeta.add_child(v)

	_banda = PanelContainer.new()
	_banda.name = "Banda"
	_banda.custom_minimum_size = Vector2(0, 86)
	_banda.add_theme_stylebox_override("panel", _Estilo_Banda(color_banda))
	v.add_child(_banda)

	var banda_margen := MarginContainer.new()
	banda_margen.add_theme_constant_override("margin_left", 18)
	banda_margen.add_theme_constant_override("margin_right", 12)
	banda_margen.add_theme_constant_override("margin_top", 13)
	banda_margen.add_theme_constant_override("margin_bottom", 13)
	_banda.add_child(banda_margen)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 13)
	banda_margen.add_child(fila)

	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(46, 46)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var st_badge := Estilos_UI.caja(Color(1, 1, 1, 0.16), 13, Color(1, 1, 1, 0.22), 1, 0)
	badge.add_theme_stylebox_override("panel", st_badge)
	fila.add_child(badge)
	_icono_cabecera = Estilos_UI.icono_rect(icono_modal, 23, Color.WHITE)
	_icono_cabecera.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_icono_cabecera.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.add_child(_icono_cabecera)

	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.alignment = BoxContainer.ALIGNMENT_CENTER
	textos.add_theme_constant_override("separation", 1)
	fila.add_child(textos)

	_lbl_eyebrow = Estilos_UI.texto("", 10, Color(1, 1, 1, 0.72), 700)
	textos.add_child(_lbl_eyebrow)

	_lbl_titulo = Estilos_UI.titulo("", 22, Color.WHITE)
	_lbl_titulo.add_theme_font_size_override("font_size", 22)
	textos.add_child(_lbl_titulo)

	_lbl_subtitulo = Estilos_UI.texto("", 12, Color(1, 1, 1, 0.80), 500)
	_lbl_subtitulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_subtitulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.add_child(_lbl_subtitulo)

	_btn_cerrar = Button.new()
	_btn_cerrar.name = "Cerrar_Modal"
	_btn_cerrar.custom_minimum_size = Vector2(46, 46)
	_btn_cerrar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_btn_cerrar.tooltip_text = "Cerrar"
	_btn_cerrar.icon = Estilos_UI.icono("x")
	_btn_cerrar.expand_icon = false
	_btn_cerrar.add_theme_constant_override("icon_max_width", 20)
	_btn_cerrar.add_theme_stylebox_override("normal", _Estilo_Boton_Banda(false))
	_btn_cerrar.add_theme_stylebox_override("hover", _Estilo_Boton_Banda(true))
	_btn_cerrar.add_theme_stylebox_override("pressed", _Estilo_Boton_Banda(true))
	_btn_cerrar.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_btn_cerrar.add_theme_color_override("icon_normal_color", Color.WHITE)
	_btn_cerrar.add_theme_color_override("icon_hover_color", Color.WHITE)
	_btn_cerrar.add_theme_color_override("icon_pressed_color", Color.WHITE)
	_btn_cerrar.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_btn_cerrar.pressed.connect(_Solicitar_Cierre)
	fila.add_child(_btn_cerrar)
	Estilos_UI.animar_presion(_btn_cerrar)

	area_fija = VBoxContainer.new()
	area_fija.name = "Area_Fija"
	area_fija.add_theme_constant_override("separation", 10)
	var margen_fijo := MarginContainer.new()
	margen_fijo.add_theme_constant_override("margin_left", 18)
	margen_fijo.add_theme_constant_override("margin_right", 18)
	margen_fijo.add_theme_constant_override("margin_top", 14)
	margen_fijo.add_theme_constant_override("margin_bottom", 0)
	margen_fijo.add_child(area_fija)
	v.add_child(margen_fijo)

	scroll_principal = ScrollContainer.new()
	scroll_principal.name = "Scroll_Principal"
	scroll_principal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_principal.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_principal.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_principal.follow_focus = true
	scroll_principal.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	v.add_child(scroll_principal)
	_Estilizar_Scroll(scroll_principal)

	var margen_scroll := MarginContainer.new()
	margen_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margen_scroll.add_theme_constant_override("margin_left", 18)
	margen_scroll.add_theme_constant_override("margin_right", 18)
	margen_scroll.add_theme_constant_override("margin_top", 14)
	margen_scroll.add_theme_constant_override("margin_bottom", 16)
	scroll_principal.add_child(margen_scroll)

	contenido = VBoxContainer.new()
	contenido.name = "Contenido"
	contenido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contenido.add_theme_constant_override("separation", 14)
	margen_scroll.add_child(contenido)

	_area_pie = PanelContainer.new()
	_area_pie.name = "Pie"
	var st_pie := StyleBoxFlat.new()
	st_pie.bg_color = Estilos_UI.SUPERFICIE
	st_pie.border_width_top = 1
	st_pie.border_color = Estilos_UI.BORDE
	st_pie.content_margin_left = 18
	st_pie.content_margin_right = 18
	st_pie.content_margin_top = 12
	st_pie.content_margin_bottom = 14
	_area_pie.add_theme_stylebox_override("panel", st_pie)
	v.add_child(_area_pie)

	pie = HBoxContainer.new()
	pie.name = "Acciones"
	pie.add_theme_constant_override("separation", 10)
	_area_pie.add_child(pie)

	_Ajustar_Tarjeta()
	_Refrescar_Cabecera()


func _Ajustar_Tarjeta() -> void:
	if _raiz == null or tarjeta == null:
		return
	var vp := get_viewport().get_visible_rect().size
	if vp.x <= 1.0 or vp.y <= 1.0:
		return
	var ancho := minf(ANCHO_MAX, maxf(vp.x - MARGEN_LATERAL * 2.0, 280.0))
	var lado := maxf((vp.x - ancho) * 0.5, 0.0)
	var arriba := 18.0 if vp.y >= 720.0 else 8.0
	var abajo := 18.0 if vp.y >= 720.0 else 8.0
	tarjeta.position = Vector2(lado, arriba)
	tarjeta.size = Vector2(ancho, vp.y - arriba - abajo)


func _Refrescar_Cabecera() -> void:
	if _lbl_titulo == null:
		return
	_lbl_titulo.text = titulo_modal
	_lbl_subtitulo.text = subtitulo_modal
	_lbl_subtitulo.visible = subtitulo_modal != ""
	_lbl_eyebrow.text = eyebrow_modal
	_lbl_eyebrow.visible = eyebrow_modal != ""
	_icono_cabecera.texture = Estilos_UI.icono(icono_modal)
	_banda.add_theme_stylebox_override("panel", _Estilo_Banda(color_banda))
	_btn_cerrar.visible = mostrar_cerrar


func _Estilo_Banda(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = 23
	s.corner_radius_top_right = 23
	s.corner_radius_bottom_left = 0
	s.corner_radius_bottom_right = 0
	s.border_width_bottom = 3
	s.border_color = color.darkened(0.26)
	s.anti_aliasing = true
	return s


func _Estilo_Boton_Banda(hover: bool) -> StyleBoxFlat:
	var s := Estilos_UI.caja(
		Color(1, 1, 1, 0.22 if hover else 0.13), 12, Color(1, 1, 1, 0.20), 1, 0)
	s.content_margin_left = 7
	s.content_margin_right = 7
	s.content_margin_top = 7
	s.content_margin_bottom = 7
	return s


func _Estilizar_Scroll(scroll: ScrollContainer) -> void:
	var vbar := scroll.get_v_scroll_bar()
	vbar.custom_minimum_size = Vector2(6, 0)
	var fondo := Estilos_UI.caja(Color(0, 0, 0, 0), 999, Color(0, 0, 0, 0), 0, 0)
	var grabber := Estilos_UI.caja(Color("#c4cdd9"), 999, Color(0, 0, 0, 0), 0, 0)
	var grabber_hover := Estilos_UI.caja(Color("#9ba8b9"), 999, Color(0, 0, 0, 0), 0, 0)
	vbar.add_theme_stylebox_override("scroll", fondo)
	vbar.add_theme_stylebox_override("grabber", grabber)
	vbar.add_theme_stylebox_override("grabber_highlight", grabber_hover)
	vbar.add_theme_stylebox_override("grabber_pressed", grabber_hover)


func _Animar_Entrada() -> void:
	if _raiz == null:
		return
	_velo.modulate.a = 0.0
	tarjeta.modulate.a = 0.0
	tarjeta.scale = Vector2(0.975, 0.975)
	tarjeta.pivot_offset = tarjeta.size * 0.5
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_velo, "modulate:a", 1.0, 0.16)
	tw.tween_property(tarjeta, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(tarjeta, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ----------------------------------------------------------------------------
# Cierre
# ----------------------------------------------------------------------------

# El modal concreto puede interceptar el cierre (por ejemplo, un examen con
# respuestas sin enviar) y mostrar una confirmación antes de salir.
func _Solicitar_Cierre() -> void:
	if _confirmacion != null:
		_Cerrar_Confirmacion()
		return
	cerrar()


func _on_velo_gui_input(event: InputEvent) -> void:
	if not permitir_cerrar_al_fondo:
		return
	var pulsado := false
	if event is InputEventMouseButton:
		pulsado = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventScreenTouch:
		pulsado = event.pressed
	if pulsado:
		_Solicitar_Cierre()


# Compatibilidad con el código existente, que llamaba a popup_centered() al
# abrir estos modales AcceptDialog. Ahora se muestran solos al entrar al árbol.
func popup_centered(_tam: Vector2i = Vector2i.ZERO) -> void:
	pass
