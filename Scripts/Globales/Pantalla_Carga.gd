extends CanvasLayer
## Pantalla de carga a pantalla completa para entrar al juego sin mostrar el fondo
## gris de Godot mientras se carga e inicializa la escena principal.
##
## La precarga (lectura del PackedScene) se hace en un hilo aparte y la barra
## muestra el progreso real. La capa vive como autoload, así que se mantiene por
## encima del cambio de escena y solo se retira cuando el juego ya está listo.

const RUTA_ESCENA_PRINCIPAL := "res://Escenas/Escena_Principal/Escena principal.tscn"

const FUENTE_TITULO := preload("res://Fuentes/UI/Bricolage-800.ttf")
const FUENTE_TEXTO := preload("res://Fuentes/UI/DMSans-700.ttf")

const TINTA := Color("#111827")
const AMARILLO := Color("#fde047")
const CREMA := Color("#fef3c7")
const PAPEL_BARRA := Color("#f3ead6")

const TITULO_NUEVA_VIDA := "Tu nueva vida\nempieza ahora"
const SUB_NUEVA_VIDA := "¡Mucha suerte ahí fuera!"
const PILL_NUEVA_VIDA := "18 AÑOS · 1.000 € EN EL BOLSILLO"

var _raiz: Control
var _centro: CenterContainer
var _vbox_textos: VBoxContainer
var _pill: PanelContainer
var _lbl_pill: Label
var _lbl_titulo: Label
var _lbl_sub: Label
var _bloque_barra: Control
var _lbl_estado: Label
var _lbl_pct: Label
var _barra: ProgressBar

var _ruta := ""
var _cargando := false
var _packed: PackedScene
var _progreso := 0.0
var _transicion_en_curso := false

# Vigilante de la carga en segundo plano. Si el hilo no avanza (drivers
# lentos, poca memoria o un recurso problemático), se cierra la espera y se
# intenta la carga en primer plano en lugar de dejar la barra congelada.
const TIEMPO_MAX_SIN_AVANCE := 8.0
const TIEMPO_MAX_CARGA := 30.0
var _tiempo_carga := 0.0
var _sin_avance := 0.0
var _ultimo_pct := -1.0
var _carga_forzada := false


func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS


# ---------------------------------------------------------------- API pública

## Lanza la precarga en segundo plano. Es idempotente y no bloquea.
func Precargar(ruta: String = RUTA_ESCENA_PRINCIPAL) -> void:
	if ruta.is_empty():
		return
	if _ruta == ruta and (_cargando or _packed != null):
		return
	if _cargando:
		# ResourceLoader no permite cancelar una petición: se reutiliza la actual.
		return
	_ruta = ruta
	_packed = null
	_progreso = 0.0
	_tiempo_carga = 0.0
	_sin_avance = 0.0
	_ultimo_pct = -1.0
	_carga_forzada = false
	if _barra != null:
		_barra.value = 0.0
		_lbl_pct.text = "0 %"
	var err := ResourceLoader.load_threaded_request(ruta)
	_cargando = err == OK


## Muestra la pantalla de carga y cambia a la escena principal cuando está lista.
## No se retira hasta que la nueva escena ha terminado su _ready, de modo que el
## jugador nunca ve el fondo gris del cambio de escena.
## Con `fundido_entrada = false` el relevo desde el remate del cómic es instantáneo.
func Ir_A_Escena_Principal(titulo: String = TITULO_NUEVA_VIDA,
		subtitulo: String = SUB_NUEVA_VIDA,
		pildora: String = PILL_NUEVA_VIDA,
		fundido_entrada: bool = true) -> void:
	if _transicion_en_curso:
		return
	_transicion_en_curso = true
	Precargar(RUTA_ESCENA_PRINCIPAL)
	_Mostrar(titulo, subtitulo, pildora, fundido_entrada)

	if not _cargando and _packed == null:
		_packed = load(RUTA_ESCENA_PRINCIPAL) as PackedScene
		_Marcar_Listo()

	while _cargando:
		await get_tree().process_frame

	if _packed == null:
		_packed = load(RUTA_ESCENA_PRINCIPAL) as PackedScene
	_Marcar_Listo()
	await get_tree().create_timer(0.35).timeout

	var escena_anterior := get_tree().current_scene
	if _packed != null:
		get_tree().change_scene_to_packed(_packed)
	else:
		get_tree().change_scene_to_file(RUTA_ESCENA_PRINCIPAL)

	# Espera a que la escena nueva esté instanciada y su _ready haya terminado.
	var esperas := 0
	while get_tree().current_scene == escena_anterior and esperas < 900:
		await get_tree().process_frame
		esperas += 1

	_packed = null
	_ruta = ""
	# Deja que el juego pinte sus primeros frames debajo antes de descubrirlo.
	await get_tree().process_frame
	await get_tree().process_frame
	await _Ocultar_Con_Fundido()
	_progreso = 0.0
	_transicion_en_curso = false


# ---------------------------------------------------------------- progreso

func _process(delta: float) -> void:
	if not _cargando:
		return
	_tiempo_carga += delta
	var progreso: Array = []
	var estado := ResourceLoader.load_threaded_get_status(_ruta, progreso)
	match estado:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			var pct: float = float(progreso[0]) if not progreso.is_empty() else _ultimo_pct
			if pct >= 0.0 and absf(pct - _ultimo_pct) > 0.001:
				_ultimo_pct = pct
				_sin_avance = 0.0
				_Actualizar_Progreso(pct)
			else:
				_sin_avance += delta
			if not _carga_forzada and (_sin_avance >= TIEMPO_MAX_SIN_AVANCE
					or _tiempo_carga >= TIEMPO_MAX_CARGA):
				_Forzar_Carga_Sincrona()
		ResourceLoader.THREAD_LOAD_LOADED:
			_packed = ResourceLoader.load_threaded_get(_ruta) as PackedScene
			_cargando = false
			_Marcar_Listo()
		_:
			_cargando = false
			_Marcar_Listo()


## El hilo no avanza: se deja de esperar y la carga se resuelve en primer plano.
## Es preferible un tirón puntual a una pantalla de carga infinita.
func _Forzar_Carga_Sincrona() -> void:
	_carga_forzada = true
	_cargando = false
	if _lbl_estado != null:
		_lbl_estado.text = "OPTIMIZANDO LA CARGA…"


func _Actualizar_Progreso(valor: float) -> void:
	_progreso = clampf(valor, 0.0, 1.0)
	if _barra == null:
		return
	_barra.value = _progreso * 100.0
	_lbl_pct.text = "%d %%" % int(round(_progreso * 100.0))
	if _progreso < 0.999:
		_lbl_estado.text = "CARGANDO EL JUEGO…"


func _Marcar_Listo() -> void:
	_Actualizar_Progreso(1.0)
	if _lbl_estado != null:
		_lbl_estado.text = "¡CARGADO! PREPARANDO TU VIDA…"


# ---------------------------------------------------------------- mostrar/ocultar

func _Mostrar(titulo: String, subtitulo: String, pildora: String,
		fundido_entrada: bool = true) -> void:
	if _raiz == null:
		_Construir()

	_lbl_titulo.text = titulo
	_lbl_sub.text = subtitulo
	_pill.visible = not pildora.strip_edges().is_empty()
	_lbl_pill.text = pildora
	_Actualizar_Progreso(_progreso)
	if _progreso >= 0.999:
		_Marcar_Listo()
	else:
		_lbl_estado.text = "CARGANDO EL JUEGO…"

	_raiz.visible = true
	_bloque_barra.modulate.a = 0.0
	if fundido_entrada:
		_raiz.modulate.a = 0.0
		var tw := create_tween().set_parallel(true)
		tw.tween_property(_raiz, "modulate:a", 1.0, 0.22)
		tw.tween_property(_bloque_barra, "modulate:a", 1.0, 0.28).set_delay(0.12)
	else:
		# Relevo directo desde el remate del cómic: mismo fondo y mismos textos.
		_raiz.modulate.a = 1.0
		var tw_barra := create_tween()
		tw_barra.tween_property(_bloque_barra, "modulate:a", 1.0, 0.30).set_delay(0.10)


func _Ocultar_Con_Fundido() -> void:
	if _raiz == null:
		return
	var tw := create_tween()
	tw.tween_property(_raiz, "modulate:a", 0.0, 0.38) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	_raiz.visible = false


# ---------------------------------------------------------------- construcción UI

func _Construir() -> void:
	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_STOP
	_raiz.focus_mode = Control.FOCUS_NONE
	_raiz.visible = false
	add_child(_raiz)

	var fondo := ColorRect.new()
	fondo.color = Estilos_UI.ROJO_BIT
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(fondo)

	var rayos := RayosCarga.new()
	rayos.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.add_child(rayos)

	# Mismos textos y composición que el remate final del cómic para que el
	# relevo entre la intro y la pantalla de carga sea imperceptible.
	_centro = CenterContainer.new()
	_centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(_centro)

	_vbox_textos = VBoxContainer.new()
	_vbox_textos.alignment = BoxContainer.ALIGNMENT_CENTER
	_vbox_textos.add_theme_constant_override("separation", 14)
	_vbox_textos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_centro.add_child(_vbox_textos)

	_pill = PanelContainer.new()
	_pill.add_theme_stylebox_override("panel", _caja_comic(AMARILLO, TINTA, 3, 999))
	_pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vbox_textos.add_child(_pill)

	var pm := MarginContainer.new()
	pm.add_theme_constant_override("margin_left", 16)
	pm.add_theme_constant_override("margin_right", 16)
	pm.add_theme_constant_override("margin_top", 6)
	pm.add_theme_constant_override("margin_bottom", 6)
	_pill.add_child(pm)

	_lbl_pill = _texto_comic(PILL_NUEVA_VIDA, 14, TINTA, FUENTE_TITULO)
	pm.add_child(_lbl_pill)

	_lbl_titulo = Label.new()
	_lbl_titulo.text = TITULO_NUEVA_VIDA
	_lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_titulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_lbl_titulo.add_theme_font_override("font", Estilos_UI.fuente_editorial(700))
	_lbl_titulo.add_theme_font_size_override("font_size", 56)
	_lbl_titulo.add_theme_color_override("font_color", Color.WHITE)
	_aplicar_contorno(_lbl_titulo, Estilos_UI.ROJO_BIT_OSCURO, 6, Vector2(0, 4), Color(0, 0, 0, 0.35))
	_lbl_titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vbox_textos.add_child(_lbl_titulo)

	_lbl_sub = _texto_comic(SUB_NUEVA_VIDA, 20, CREMA, FUENTE_TITULO)
	_lbl_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vbox_textos.add_child(_lbl_sub)

	# Barra de carga en una zona aparte para no desplazar el bloque central.
	var zona_barra := CenterContainer.new()
	zona_barra.set_anchors_preset(Control.PRESET_FULL_RECT)
	zona_barra.anchor_top = 0.64
	zona_barra.offset_top = 0.0
	zona_barra.offset_bottom = -46.0
	zona_barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(zona_barra)

	_bloque_barra = zona_barra
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(576, 0)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st_card := _caja_comic(PAPEL_BARRA, TINTA, 3, 16)
	st_card.shadow_color = TINTA
	st_card.shadow_size = 0
	st_card.shadow_offset = Vector2(5, 6)
	card.add_theme_stylebox_override("panel", st_card)
	zona_barra.add_child(card)

	var cm := MarginContainer.new()
	cm.add_theme_constant_override("margin_left", 22)
	cm.add_theme_constant_override("margin_right", 22)
	cm.add_theme_constant_override("margin_top", 16)
	cm.add_theme_constant_override("margin_bottom", 18)
	card.add_child(cm)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	cm.add_child(col)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	col.add_child(fila)

	var icono := Estilos_UI.icono_rect("sparkles", 20, Estilos_UI.ROJO_BIT)
	fila.add_child(icono)

	_lbl_estado = _texto_comic("CARGANDO EL JUEGO…", 14, TINTA, FUENTE_TITULO)
	_lbl_estado.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(_lbl_estado)

	_lbl_pct = _texto_comic("0 %", 16, Estilos_UI.ROJO_BIT, FUENTE_TITULO)
	_lbl_pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	fila.add_child(_lbl_pct)

	_barra = ProgressBar.new()
	_barra.custom_minimum_size = Vector2(0, 28)
	_barra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_barra.show_percentage = false
	_barra.min_value = 0.0
	_barra.max_value = 100.0
	_barra.value = 0.0
	_barra.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var st_fondo := StyleBoxFlat.new()
	st_fondo.bg_color = Color("#e3d6ba")
	st_fondo.border_color = TINTA
	st_fondo.set_border_width_all(3)
	st_fondo.set_corner_radius_all(14)
	st_fondo.anti_aliasing = true
	_barra.add_theme_stylebox_override("background", st_fondo)

	var st_relleno := StyleBoxFlat.new()
	st_relleno.bg_color = AMARILLO
	st_relleno.set_corner_radius_all(9)
	st_relleno.anti_aliasing = true
	_barra.add_theme_stylebox_override("fill", st_relleno)
	col.add_child(_barra)

	var pie := _texto_comic("Tu progreso se guarda automáticamente", 11, Color(TINTA, 0.62), FUENTE_TEXTO)
	pie.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(pie)


func _caja_comic(fondo: Color, borde: Color, grosor: int, radio: int) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = fondo
	st.border_color = borde
	st.set_border_width_all(grosor)
	st.set_corner_radius_all(radio)
	st.anti_aliasing = true
	return st


func _texto_comic(contenido: String, tam: int, color: Color, fuente: FontFile) -> Label:
	var lbl := Label.new()
	lbl.set_meta("_tema_aplicado", true)
	lbl.text = contenido
	lbl.add_theme_font_override("font", fuente)
	lbl.add_theme_font_size_override("font_size", tam)
	lbl.add_theme_color_override("font_color", color)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl


func _aplicar_contorno(lbl: Label, color_borde: Color, grosor: int,
		sombra_off: Vector2, color_sombra: Color) -> void:
	lbl.add_theme_constant_override("outline_size", grosor)
	lbl.add_theme_color_override("font_outline_color", color_borde)
	lbl.add_theme_color_override("font_shadow_color", color_sombra)
	lbl.add_theme_constant_override("shadow_offset_x", int(sombra_off.x))
	lbl.add_theme_constant_override("shadow_offset_y", int(sombra_off.y))


# ---------------------------------------------------------------- fondo animado

class RayosCarga extends Control:
	var _t := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		if not is_visible_in_tree():
			return
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var centro := size * 0.5
		var r := size.length() * 1.2
		var cantidad := 14
		var ancho := 0.09
		for i in range(cantidad):
			var a := _t * 0.18 + TAU * float(i) / float(cantidad)
			draw_colored_polygon(PackedVector2Array([
				centro,
				centro + Vector2(cos(a - ancho), sin(a - ancho)) * r,
				centro + Vector2(cos(a + ancho), sin(a + ancho)) * r,
			]), Color(1.0, 1.0, 1.0, 0.07))
