class_name Transicion_Minijuego
extends CanvasLayer

# ============================================================================
# Transición de "telón de cocina" entre la escena principal y el minijuego.
#
# El telón sube desde el borde inferior para cubrir la pantalla mientras se
# prepara la siguiente vista y, cuando ya está lista, continúa subiendo hasta
# salir por arriba para descubrirla. Mientras está visible muestra al chef, el
# título del destino y unos puntos animados, así el cambio nunca se siente
# instantáneo. El color de fondo coincide con el del mapa del minijuego
# (#0b1220) para que el relevo hacia la cocina sea continuo.
#
# Uso:
#   var trans := Transicion_Minijuego.new()
#   add_child(trans)
#   await trans.Cubrir("Cocina", "Preparando los fogones…")
#   ... preparar la nueva vista ...
#   await trans.Descubrir("¡A cocinar!")
# ============================================================================

const DURACION_CUBRIR: float = 0.34
const DURACION_DESCUBRIR: float = 0.40
const ALTO_EXTRA: float = 72.0

const COLOR_TELON := Color("#0b1220")
const COLOR_ACENTO := Color("#ea580c")
const COLOR_SUBTITULO := Color("#fde68a")

const TEX_CHEF := preload("res://Imagenes/Minijuego_Cocina/Chef/Poses/Chef_Pulgar_Arriba.png")

var _raiz: Control
var _cortina: Panel
var _rayos: Control
var _centro: CenterContainer
var _contenido: VBoxContainer
var _chef: TextureRect
var _lbl_titulo: Label
var _lbl_sub: Label
var _puntos: Control
var _tween: Tween
var _ancho: float = 720.0
var _alto: float = 1280.0
var _animando: bool = false
# Mantiene el telón cubriendo aunque cambie el tamaño del viewport entre
# Cubrir() y Descubrir() (p. ej. al fijar la orientación del minijuego).
var _cubierta: bool = false


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	_Construir()
	_Ajustar_Al_Viewport()
	if get_viewport() != null:
		get_viewport().size_changed.connect(_Ajustar_Al_Viewport)


# ----------------------------------------------------------------------------
# API pública
# ----------------------------------------------------------------------------

## Baja el telón hasta cubrir la pantalla. Espera a que termine la animación.
func Cubrir(titulo: String, subtitulo: String) -> void:
	if not is_inside_tree():
		return
	_lbl_titulo.text = titulo
	_lbl_sub.text = subtitulo
	_animando = true
	_cubierta = true
	_raiz.visible = true
	_Ajustar_Al_Viewport()
	_Detener_Tween()

	# El telón arranca justo debajo de la pantalla y sube hasta cubrirla.
	_cortina.position = Vector2(0.0, _alto + 8.0)
	_contenido.modulate.a = 0.0
	_puntos.modulate.a = 0.0
	_chef.scale = Vector2(0.82, 0.82)

	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(_cortina, "position:y", 0.0, DURACION_CUBRIR) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_contenido, "modulate:a", 1.0, 0.18) \
		.set_delay(DURACION_CUBRIR * 0.30)
	_tween.tween_property(_chef, "scale", Vector2.ONE, 0.22) \
		.set_delay(DURACION_CUBRIR * 0.32) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_puntos, "modulate:a", 1.0, 0.17) \
		.set_delay(DURACION_CUBRIR * 0.50)
	await _tween.finished
	_animando = false
	_Iniciar_Balanceo_Chef()


## Retira el telón hacia arriba para descubrir la vista preparada. Se libera solo.
func Descubrir(subtitulo_nuevo: String = "") -> void:
	if not is_inside_tree():
		return
	if subtitulo_nuevo != "":
		_lbl_sub.text = subtitulo_nuevo
	_animando = true
	_Detener_Tween()

	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(_cortina, "position:y", -(_alto + ALTO_EXTRA), DURACION_DESCUBRIR) \
		.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(_contenido, "modulate:a", 0.0, 0.18)
	await _tween.finished
	_animando = false
	_cubierta = false
	_raiz.visible = false
	queue_free()


# ----------------------------------------------------------------------------
# Construcción de la capa
# ----------------------------------------------------------------------------

func _Construir() -> void:
	_raiz = Control.new()
	_raiz.name = "Raiz_Transicion"
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_STOP
	_raiz.focus_mode = Control.FOCUS_NONE
	_raiz.visible = false
	add_child(_raiz)

	_cortina = Panel.new()
	_cortina.name = "Telon"
	_cortina.mouse_filter = Control.MOUSE_FILTER_STOP
	var st := StyleBoxFlat.new()
	st.bg_color = COLOR_TELON
	st.border_color = COLOR_ACENTO
	st.border_width_top = 4
	st.border_width_bottom = 5
	st.corner_radius_bottom_left = 38
	st.corner_radius_bottom_right = 38
	st.anti_aliasing = true
	_cortina.add_theme_stylebox_override("panel", st)
	_raiz.add_child(_cortina)

	_rayos = Rayos_Telon.new()
	_rayos.name = "Rayos"
	_rayos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cortina.add_child(_rayos)

	_centro = CenterContainer.new()
	_centro.name = "Centro"
	_centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cortina.add_child(_centro)

	_contenido = VBoxContainer.new()
	_contenido.name = "Contenido"
	_contenido.alignment = BoxContainer.ALIGNMENT_CENTER
	_contenido.add_theme_constant_override("separation", 6)
	_contenido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_centro.add_child(_contenido)

	_chef = TextureRect.new()
	_chef.name = "Chef"
	_chef.texture = TEX_CHEF
	_chef.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_chef.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_chef.custom_minimum_size = Vector2(126.0, 200.0)
	_chef.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_chef.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chef.pivot_offset = _chef.custom_minimum_size * 0.5
	_contenido.add_child(_chef)

	_lbl_titulo = Estilos_UI.titulo("Cocina", 34, Color.WHITE)
	_lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_contenido.add_child(_lbl_titulo)

	_lbl_sub = Estilos_UI.texto("Preparando los fogones…", 15, COLOR_SUBTITULO, 600)
	_lbl_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_contenido.add_child(_lbl_sub)

	_puntos = Puntos_Carga.new()
	_puntos.name = "Puntos"
	_puntos.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_contenido.add_child(_puntos)


func _Ajustar_Al_Viewport() -> void:
	if not is_inside_tree():
		return
	var vp := get_viewport()
	if vp == null:
		return
	var tam: Vector2 = vp.get_visible_rect().size
	_ancho = maxf(720.0, tam.x)
	_alto = maxf(1280.0, tam.y)

	if _cortina != null and is_instance_valid(_cortina):
		_cortina.size = Vector2(_ancho, _alto + ALTO_EXTRA)
		if not _animando and not _cubierta:
			_cortina.position = Vector2(0.0, _alto + 8.0)
	if _centro != null and is_instance_valid(_centro):
		_centro.position = Vector2.ZERO
		_centro.size = Vector2(_ancho, _alto)
	if _rayos != null and is_instance_valid(_rayos):
		_rayos.position = Vector2.ZERO
		_rayos.size = Vector2(_ancho, _alto)


func _Detener_Tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null


func _Iniciar_Balanceo_Chef() -> void:
	if _chef == null or not is_instance_valid(_chef):
		return
	_chef.scale = Vector2.ONE
	_chef.rotation = 0.0
	var tw := _chef.create_tween().set_loops()
	tw.tween_property(_chef, "rotation", deg_to_rad(-2.5), 0.55) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_chef, "rotation", deg_to_rad(2.5), 0.65) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_chef, "rotation", 0.0, 0.55) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# ----------------------------------------------------------------------------
# Dibujo animado de fondo y puntos de carga
# ----------------------------------------------------------------------------

class Rayos_Telon extends Control:
	var _t: float = 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		if not is_visible_in_tree():
			return
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var centro: Vector2 = size * 0.5
		var radio: float = size.length() * 0.9
		var cantidad: int = 16
		for i in range(cantidad):
			var a: float = _t * 0.22 + TAU * float(i) / float(cantidad)
			var ancho: float = 0.055
			draw_colored_polygon(PackedVector2Array([
				centro,
				centro + Vector2(cos(a - ancho), sin(a - ancho)) * radio,
				centro + Vector2(cos(a + ancho), sin(a + ancho)) * radio,
			]), Color(0.98, 0.62, 0.15, 0.055))


class Puntos_Carga extends Control:
	const COLOR_PUNTO := Color(0.984, 0.749, 0.141)
	var _t: float = 0.0

	func _init() -> void:
		custom_minimum_size = Vector2(76.0, 24.0)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		if not is_visible_in_tree():
			return
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var radio: float = 5.0
		var separacion: float = 20.0
		var centro: Vector2 = size * 0.5
		for i in range(3):
			var fase: float = _t * 4.6 - float(i) * 0.85
			var onda: float = maxf(0.0, sin(fase))
			var color_punto := Color(COLOR_PUNTO, 0.35 + 0.65 * onda)
			draw_circle(Vector2(
				centro.x + (float(i) - 1.0) * separacion,
				centro.y - onda * 5.0), radio, color_punto)
