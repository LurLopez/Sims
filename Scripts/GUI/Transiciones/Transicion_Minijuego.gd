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
var _rayos: Rayos_Telon
var _centro: CenterContainer
var _contenido: VBoxContainer
var _hero_manager: HBoxContainer
var _chef: TextureRect
var _lbl_titulo: Label
var _lbl_sub: Label
var _puntos: Puntos_Carga
var _tween: Tween
var _ancho: float = 720.0
var _alto: float = 1280.0
var _animando: bool = false
var _tema: String = "cocina"
var _club_tema: Dictionary = {}
# Mantiene el telón cubriendo aunque cambie el tamaño del viewport entre
# Cubrir() y Descubrir() (p. ej. al fijar la orientación del minijuego).
var _cubierta: bool = false


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	_Construir()
	_Aplicar_Tema()
	_Ajustar_Al_Viewport()
	if get_viewport() != null:
		get_viewport().size_changed.connect(_Ajustar_Al_Viewport)


func configurar_tema(modo: String = "cocina", club: Dictionary = {}) -> void:
	_tema = modo
	_club_tema = club.duplicate(true) if not club.is_empty() else {}
	if is_inside_tree() and _cortina != null:
		_Aplicar_Tema()


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
	var figura: Control = _hero_manager if _tema == "manager" else _chef
	figura.scale = Vector2(0.82, 0.82)

	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(_cortina, "position:y", 0.0, DURACION_CUBRIR) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_contenido, "modulate:a", 1.0, 0.18) \
		.set_delay(DURACION_CUBRIR * 0.30)
	_tween.tween_property(figura, "scale", Vector2.ONE, 0.22) \
		.set_delay(DURACION_CUBRIR * 0.32) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_puntos, "modulate:a", 1.0, 0.17) \
		.set_delay(DURACION_CUBRIR * 0.50)
	await _tween.finished
	_animando = false
	_Iniciar_Balanceo_Figura()


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

	_hero_manager = HBoxContainer.new()
	_hero_manager.name = "Hero_Manager"
	_hero_manager.alignment = BoxContainer.ALIGNMENT_CENTER
	_hero_manager.add_theme_constant_override("separation", 14)
	_hero_manager.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_hero_manager.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hero_manager.visible = false
	_contenido.add_child(_hero_manager)

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
	_ancho = maxf(320.0, tam.x)
	_alto = maxf(320.0, tam.y)

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


func _Aplicar_Tema() -> void:
	var es_mgr: bool = _tema == "manager"
	_chef.visible = not es_mgr
	_hero_manager.visible = es_mgr
	var acento: Color = Color("#10b981") if es_mgr else COLOR_ACENTO
	var sub_col: Color = Color("#a7f3d0") if es_mgr else COLOR_SUBTITULO
	var st := _cortina.get_theme_stylebox("panel") as StyleBoxFlat
	if st != null:
		st.border_color = acento
	_lbl_sub.add_theme_color_override("font_color", sub_col)
	_rayos.color_rayo = Color(0.06, 0.72, 0.50, 0.08) if es_mgr else Color(0.98, 0.62, 0.15, 0.055)
	_puntos.color_punto = Color("#34d399") if es_mgr else Color(0.984, 0.749, 0.141)

	if not es_mgr:
		return
	for c in _hero_manager.get_children():
		c.queue_free()
	var cols: Array = _club_tema.get("colores", ["#0f766e", "#ffffff"]) if not _club_tema.is_empty() else ["#0f766e", "#ffffff"]
	if not _club_tema.is_empty():
		var escudo := Cresta_Manager.new()
		escudo.custom_minimum_size = Vector2(92, 106)
		escudo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		escudo.configurar(str(_club_tema.get("nombre", "MGR")), cols, int(_club_tema.get("escudo_patron", 1)), 0.0)
		_hero_manager.add_child(escudo)
	var coach := Estilo_Manager.crear_retrato_manager(120, cols, "feliz", false, "medio_cuerpo")
	_hero_manager.add_child(coach)
	_hero_manager.pivot_offset = Vector2(105.0 if not _club_tema.is_empty() else 60.0, 60.0)


func _Detener_Tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null


func _Iniciar_Balanceo_Figura() -> void:
	var figura: Control = _hero_manager if _tema == "manager" else _chef
	if figura == null or not is_instance_valid(figura):
		return
	figura.scale = Vector2.ONE
	figura.rotation = 0.0
	var tw := figura.create_tween().set_loops()
	tw.tween_property(figura, "rotation", deg_to_rad(-2.5), 0.55) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(figura, "rotation", deg_to_rad(2.5), 0.65) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(figura, "rotation", 0.0, 0.55) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# ----------------------------------------------------------------------------
# Dibujo animado de fondo y puntos de carga
# ----------------------------------------------------------------------------

class Rayos_Telon extends Control:
	var _t: float = 0.0
	var color_rayo := Color(0.98, 0.62, 0.15, 0.055)

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
			]), color_rayo)


class Puntos_Carga extends Control:
	var color_punto := Color(0.984, 0.749, 0.141)
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
			var col := Color(color_punto, 0.35 + 0.65 * onda)
			draw_circle(Vector2(
				centro.x + (float(i) - 1.0) * separacion,
				centro.y - onda * 5.0), radio, col)
