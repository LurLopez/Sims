extends CanvasLayer
## Tutorial interactivo con spotlight que aparece una sola vez al iniciar partida
## para presentar las mecánicas principales del juego señalando sus controles reales.

signal terminado

const ANCHO_TARJETA := 656.0
const MARGEN_X := 32.0
const PADDING_FOCO := 8.0
const RADIO_FOCO := 14.0

const SHADER_SPOTLIGHT := """
shader_type canvas_item;
uniform vec2 viewport_size = vec2(720.0, 1280.0);
uniform vec4 hole_rect = vec4(16.0, 16.0, 688.0, 64.0);
uniform float corner_radius = 14.0;
uniform vec4 overlay_color : source_color = vec4(0.067, 0.094, 0.165, 0.74);

float sd_round_box(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + vec2(r);
	return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

void fragment() {
	vec2 px = UV * viewport_size;
	vec2 half_size = hole_rect.zw * 0.5;
	vec2 center = hole_rect.xy + half_size;
	float d = sd_round_box(px - center, half_size, corner_radius);
	float mask = smoothstep(-1.5, 2.5, d);
	COLOR = vec4(overlay_color.rgb, overlay_color.a * mask);
}
"""

var escena_principal: Node = null

var _raiz: Control
var _velo: ColorRect
var _mat_velo: ShaderMaterial
var _anillo: AnilloSpotlight
var _flecha: FlechaTarjeta
var _tarjeta: PanelContainer
var _badge_ic: PanelContainer
var _badge_ic_rect: TextureRect
var _pill_categoria: PanelContainer
var _lbl_categoria: Label
var _lbl_paso: Label
var _lbl_titulo: Label
var _lbl_cuerpo: Label
var _lbl_consejo: Label
var _pips: Array[Panel] = []
var _btn_anterior: Button
var _btn_siguiente: Button

var _pasos: Array[Dictionary] = []
var _indice := 0
var _rect_foco: Rect2 = Rect2(16, 8, 688, 60)
var _tween_foco: Tween
var _cerrado := false


func _ready() -> void:
	layer = 105
	_definir_pasos()
	_construir()
	call_deferred("_iniciar")


func _definir_pasos() -> void:
	_pasos = [
		{
			"categoria": "TIEMPO REAL",
			"icono": "clock",
			"color": Estilos_UI.ROJO_BIT,
			"fondo_suave": Estilos_UI.ROJO_BIT_SUAVE,
			"titulo": "Tu vida avanza en tiempo real",
			"cuerpo": "Empiezas a los 18 años con 1.000 €. El juego sigue el reloj real de tu dispositivo: cada semana real equivale a 1 año de vida para tu personaje.",
			"consejo": "Arriba verás siempre la fecha actual, tu edad y tu saldo.",
			"target": "header",
			"fallback": Rect2(6, 4, 708, 62),
		},
		{
			"categoria": "INICIO Y NECESIDADES",
			"icono": "heart-pulse",
			"color": Estilos_UI.CORAL,
			"fondo_suave": Estilos_UI.CORAL_SUAVE,
			"titulo": "Cuida tus necesidades y actúa rápido",
			"cuerpo": "Vigila Salud, Hambre, Descanso e Higiene: si descuidas alguna barra tu salud bajará. Usa las Acciones rápidas para comer, dormir, ducharte o estudiar al instante.",
			"consejo": "En la pantalla Inicio también verás lo que haces ahora y tus mensajes.",
			"target": "home_necesidades_acciones",
			"fallback": Rect2(20, 390, 680, 410),
		},
		{
			"categoria": "AGENDA Y EMPLEO",
			"icono": "calendar-days",
			"color": Estilos_UI.AZUL,
			"fondo_suave": Estilos_UI.AZUL_SUAVE,
			"titulo": "Organiza tu horario y busca trabajo",
			"cuerpo": "Desde Actividades puedes buscar empleo para ganar dinero por hora o planificar tu semana en el calendario. En el botón Horario de arriba consultas toda la semana.",
			"consejo": "Las horas que dejes vacías se rellenarán con eventos espontáneos.",
			"target": "nav_actividades",
			"fallback": Rect2(430, 1192, 138, 72),
		},
		{
			"categoria": "EVOLUCIÓN",
			"icono": "trending-up",
			"color": Color("#7c3aed"),
			"fondo_suave": Color("#ede9fe"),
			"titulo": "Habilidades innatas y Progreso",
			"cuerpo": "Tu personaje nace con 7 habilidades únicas que multiplican tu entrenamiento. Sube Deporte, Académico y Manualidades para desbloquear mejores empleos.",
			"consejo": "En Perfil (arriba a la izquierda) puedes consultar tu personalidad e historial.",
			"target": "nav_hab_progreso",
			"fallback": Rect2(148, 1192, 280, 72),
		},
		{
			"categoria": "UNIVERSIDAD",
			"icono": "graduation-cap",
			"color": Estilos_UI.AZUL,
			"fondo_suave": Estilos_UI.AZUL_SUAVE,
			"titulo": "Estudia una carrera y examínate",
			"cuerpo": "En Carrera puedes matricularte en Bellas Artes, Derecho o Medicina, leer apuntes reales del curso y presentarte a exámenes semanales para obtener tu título.",
			"consejo": "Completar una carrera da un bonus económico y acceso a empleos top.",
			"target": "top_carrera",
			"fallback": Rect2(536, 73, 170, 36),
		},
		{
			"categoria": "FINANZAS Y HOGAR",
			"icono": "wallet",
			"color": Estilos_UI.EXITO,
			"fondo_suave": Estilos_UI.EXITO_SUAVE,
			"titulo": "Alquiler, Bolsa y Tienda",
			"cuerpo": "Cada 7 días pagarás 200 € de alquiler. En Economía puedes revisar tu vivienda, invertir en Bolsa o entrar a la Tienda para comprar mejor cama, mesa o ducha.",
			"consejo": "Mejorar los muebles del hogar hace más efectivas tus actividades.",
			"target": "top_economia",
			"fallback": Rect2(188, 73, 170, 36),
		},
	]


func _construir() -> void:
	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_STOP
	_raiz.gui_input.connect(_on_raiz_gui_input)
	add_child(_raiz)

	_velo = ColorRect.new()
	_velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = SHADER_SPOTLIGHT
	_mat_velo = ShaderMaterial.new()
	_mat_velo.shader = sh
	_velo.material = _mat_velo
	_raiz.add_child(_velo)

	_anillo = AnilloSpotlight.new()
	_anillo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.add_child(_anillo)

	_construir_tarjeta()

	_flecha = FlechaTarjeta.new(_tarjeta)
	_flecha.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.add_child(_flecha)


func _construir_tarjeta() -> void:
	_tarjeta = PanelContainer.new()
	_tarjeta.position = Vector2(MARGEN_X, 200)
	_tarjeta.size = Vector2(ANCHO_TARJETA, 0)
	_tarjeta.custom_minimum_size = Vector2(ANCHO_TARJETA, 0)
	_tarjeta.mouse_filter = Control.MOUSE_FILTER_STOP
	var st := Estilos_UI.caja(Estilos_UI.SUPERFICIE, 18, Estilos_UI.BORDE_FUERTE, 1, 0)
	st.shadow_color = Color(0.05, 0.08, 0.14, 0.24)
	st.shadow_size = 18
	st.shadow_offset = Vector2(0, 8)
	_tarjeta.add_theme_stylebox_override("panel", st)
	_raiz.add_child(_tarjeta)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 22)
	m.add_theme_constant_override("margin_right", 22)
	m.add_theme_constant_override("margin_top", 18)
	m.add_theme_constant_override("margin_bottom", 18)
	_tarjeta.add_child(m)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	m.add_child(v)

	# Cabecera: icono + pill categoría + contador + botón saltar
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	v.add_child(top)

	_badge_ic = Estilos_UI.badge_icono("clock", 36, 18, Estilos_UI.ROJO_BIT_SUAVE, Estilos_UI.ROJO_BIT, 10)
	_badge_ic_rect = _badge_ic.get_child(0).get_child(0) as TextureRect
	top.add_child(_badge_ic)

	_pill_categoria = _crear_pill("", Estilos_UI.ROJO_BIT_SUAVE, Estilos_UI.ROJO_BIT)
	_lbl_categoria = _pill_categoria.get_child(0) as Label
	top.add_child(_pill_categoria)

	_lbl_paso = Estilos_UI.texto("1 / 6", 12, Estilos_UI.TINTA_FANTASMA, 700)
	top.add_child(_lbl_paso)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(spacer)

	var btn_saltar := Estilos_UI.boton("Saltar", "fantasma", "", Estilos_UI.TINTA_SUAVE, 32)
	btn_saltar.add_theme_font_size_override("font_size", 13)
	btn_saltar.pressed.connect(_finalizar)
	top.add_child(btn_saltar)

	_lbl_titulo = Estilos_UI.titulo("", 21, Estilos_UI.TINTA)
	_lbl_titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_lbl_titulo)

	_lbl_cuerpo = Estilos_UI.parrafo("", 14, Estilos_UI.TINTA_SUAVE)
	v.add_child(_lbl_cuerpo)

	# Caja de consejo rápido
	var caja_tip := PanelContainer.new()
	caja_tip.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Estilos_UI.SUPERFICIE_2, 12, Estilos_UI.BORDE, 1, 0))
	v.add_child(caja_tip)

	var tm := MarginContainer.new()
	tm.add_theme_constant_override("margin_left", 12)
	tm.add_theme_constant_override("margin_right", 12)
	tm.add_theme_constant_override("margin_top", 9)
	tm.add_theme_constant_override("margin_bottom", 9)
	caja_tip.add_child(tm)

	var trow := HBoxContainer.new()
	trow.add_theme_constant_override("separation", 8)
	tm.add_child(trow)

	var ic_tip := Estilos_UI.icono_rect("info", 16, Estilos_UI.PRIMARIO)
	ic_tip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	trow.add_child(ic_tip)

	_lbl_consejo = Estilos_UI.parrafo("", 13, Estilos_UI.TINTA)
	_lbl_consejo.add_theme_font_override("font", Estilos_UI.fuente_ui(600))
	_lbl_consejo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	trow.add_child(_lbl_consejo)

	v.add_child(Estilos_UI.divisor_horizontal())

	# Pie: puntos de progreso + Anterior / Siguiente
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	v.add_child(footer)

	var pips_row := HBoxContainer.new()
	pips_row.add_theme_constant_override("separation", 6)
	pips_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pips_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	footer.add_child(pips_row)

	for i in range(_pasos.size()):
		var pip := Panel.new()
		pip.custom_minimum_size = Vector2(8, 8)
		pip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pips_row.add_child(pip)
		_pips.append(pip)

	_btn_anterior = Estilos_UI.boton("Anterior", "secundario", "chevron-left", Estilos_UI.TINTA, 44)
	_btn_anterior.pressed.connect(_anterior)
	footer.add_child(_btn_anterior)

	_btn_siguiente = Estilos_UI.boton("Siguiente", "primario", "chevron-right", Estilos_UI.ROJO_BIT, 44)
	_btn_siguiente.pressed.connect(_siguiente)
	footer.add_child(_btn_siguiente)


func _iniciar() -> void:
	await get_tree().process_frame
	if not is_inside_tree():
		return
	var tam := _tam_viewport()
	_mat_velo.set_shader_parameter("viewport_size", tam)
	_mostrar_paso(0, false)
	_tarjeta.modulate.a = 0.0
	_tarjeta.scale = Vector2(0.94, 0.94)
	_tarjeta.pivot_offset = _tarjeta.size / 2.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_tarjeta, "modulate:a", 1.0, 0.22)
	tw.tween_property(_tarjeta, "scale", Vector2.ONE, 0.28) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _mostrar_paso(idx: int, animar_foco: bool = true) -> void:
	_indice = clampi(idx, 0, _pasos.size() - 1)
	var paso: Dictionary = _pasos[_indice]

	var color: Color = paso["color"]
	var fondo_suave: Color = paso["fondo_suave"]

	_badge_ic.add_theme_stylebox_override("panel", Estilos_UI.caja(fondo_suave, 10, Color(0, 0, 0, 0), 0, 0))
	_badge_ic_rect.texture = Estilos_UI.icono(paso["icono"])
	_badge_ic_rect.self_modulate = color

	var st_pill := _pill_categoria.get_theme_stylebox("panel") as StyleBoxFlat
	st_pill.bg_color = fondo_suave
	_lbl_categoria.text = paso["categoria"]
	_lbl_categoria.add_theme_color_override("font_color", color)
	_lbl_paso.text = "%d / %d" % [_indice + 1, _pasos.size()]

	_lbl_titulo.text = paso["titulo"]
	_lbl_cuerpo.text = paso["cuerpo"]
	_lbl_consejo.text = paso["consejo"]

	_btn_anterior.visible = _indice > 0
	var es_ultimo := (_indice == _pasos.size() - 1)
	if es_ultimo:
		_btn_siguiente.text = "¡A vivir!"
		Estilos_UI.aplicar_estilo_boton(_btn_siguiente, "exito", Estilos_UI.EXITO, "play")
	else:
		_btn_siguiente.text = "Siguiente"
		Estilos_UI.aplicar_estilo_boton(_btn_siguiente, "primario", Estilos_UI.ROJO_BIT, "chevron-right")

	_actualizar_pips()

	# Recalcular altura real de la tarjeta antes de ubicarla respecto al foco
	_tarjeta.size = Vector2(ANCHO_TARJETA, 0)
	_tarjeta.reset_size()
	var rect_objetivo := _obtener_rect_objetivo(paso["target"], paso["fallback"])
	_posicionar_tarjeta_y_foco(rect_objetivo, animar_foco, color)


func _actualizar_pips() -> void:
	for i in range(_pips.size()):
		var pip := _pips[i]
		var activo := (i == _indice)
		pip.custom_minimum_size = Vector2(22 if activo else 8, 8)
		var col := Estilos_UI.ROJO_BIT if activo else (Estilos_UI.BORDE_FUERTE if i < _indice else Estilos_UI.GRIS_BARRA)
		pip.add_theme_stylebox_override("panel", Estilos_UI.caja(col, 999, Color(0, 0, 0, 0), 0, 0))


func _obtener_rect_objetivo(clave: String, fallback: Rect2) -> Rect2:
	if escena_principal == null or not is_instance_valid(escena_principal):
		return fallback.grow(PADDING_FOCO)

	var rect := fallback
	match clave:
		"header":
			var h := escena_principal.get_node_or_null("Header_Superior") as Control
			if h != null:
				rect = h.get_global_rect().grow_individual(-6, -4, -6, -4)
		"home_necesidades_acciones":
			var c_nec := _buscar_nodo_recursivo(escena_principal, "Card_Necesidades")
			var c_acc := _buscar_nodo_recursivo(escena_principal, "Card_Acciones")
			if c_nec != null and c_acc != null:
				rect = c_nec.get_global_rect().merge(c_acc.get_global_rect())
			elif c_nec != null:
				rect = c_nec.get_global_rect()
		"nav_actividades":
			var b := escena_principal.get_node_or_null("Barra_Abajo/Boton_Actividades") as Control
			if b != null:
				rect = b.get_global_rect()
		"nav_hab_progreso":
			var b1 := escena_principal.get_node_or_null("Barra_Abajo/Boton_Habilidades") as Control
			var b2 := escena_principal.get_node_or_null("Barra_Abajo/Boton_Progreso") as Control
			if b1 != null and b2 != null:
				rect = b1.get_global_rect().merge(b2.get_global_rect())
		"top_carrera":
			var b := escena_principal.get_node_or_null("Carrera_Button") as Control
			if b != null:
				rect = b.get_global_rect()
		"top_economia":
			var b := escena_principal.get_node_or_null("Economia_Button") as Control
			if b != null:
				rect = b.get_global_rect()

	var resultado := rect.grow(PADDING_FOCO)
	var limites := Rect2(Vector2(2.0, 2.0), _tam_viewport() - Vector2(4.0, 4.0))
	return resultado.intersection(limites)


func _buscar_nodo_recursivo(raiz: Node, nombre: String) -> Control:
	var encontrado := raiz.find_child(nombre, true, false)
	return encontrado as Control


func _posicionar_tarjeta_y_foco(rect_objetivo: Rect2, animar: bool, color_acento: Color) -> void:
	var tam := _tam_viewport()
	var card_h := maxf(_tarjeta.size.y, _tarjeta.get_combined_minimum_size().y)
	var hueco_flecha := 20.0
	var espacio_arriba := rect_objetivo.position.y - 20.0
	var espacio_abajo := (tam.y - 20.0) - rect_objetivo.end.y

	var colocar_abajo := espacio_abajo >= card_h + hueco_flecha or espacio_abajo >= espacio_arriba
	var dest_y := 0.0
	if colocar_abajo:
		dest_y = minf(rect_objetivo.end.y + hueco_flecha, tam.y - card_h - 18.0)
	else:
		dest_y = maxf(18.0, rect_objetivo.position.y - hueco_flecha - card_h)

	var ancho_ui := minf(720.0, tam.x)
	var dest_x := clampf(
		rect_objetivo.get_center().x - ANCHO_TARJETA * 0.5,
		MARGEN_X,
		maxf(MARGEN_X, ancho_ui - ANCHO_TARJETA - MARGEN_X)
	)
	var dest_pos := Vector2(dest_x, dest_y)

	_anillo.color_acento = color_acento
	# Actualizar flecha hacia el foco siguiendo siempre a la tarjeta
	var flecha_x := clampf(rect_objetivo.get_center().x, dest_x + 34.0, dest_x + ANCHO_TARJETA - 34.0)
	_flecha.en_borde_superior = colocar_abajo
	if animar:
		if _tween_foco != null and _tween_foco.is_valid():
			_tween_foco.kill()
		_tween_foco = create_tween().set_parallel(true)
		_tween_foco.tween_method(_aplicar_rect_foco, _rect_foco, rect_objetivo, 0.30) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_tween_foco.tween_property(_tarjeta, "position", dest_pos, 0.30) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_tween_foco.tween_property(_flecha, "x_punta", flecha_x, 0.30) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		_aplicar_rect_foco(rect_objetivo)
		_tarjeta.position = dest_pos
		_flecha.x_punta = flecha_x


func _aplicar_rect_foco(r: Rect2) -> void:
	_rect_foco = r
	var tam := _tam_viewport()
	_mat_velo.set_shader_parameter("viewport_size", tam)
	_mat_velo.set_shader_parameter("hole_rect", Vector4(r.position.x, r.position.y, r.size.x, r.size.y))
	_mat_velo.set_shader_parameter("corner_radius", RADIO_FOCO)
	_anillo.rect_foco = r


func _siguiente() -> void:
	if _cerrado:
		return
	if _indice >= _pasos.size() - 1:
		_finalizar()
	else:
		_mostrar_paso(_indice + 1, true)


func _anterior() -> void:
	if _cerrado or _indice <= 0:
		return
	_mostrar_paso(_indice - 1, true)


func _finalizar() -> void:
	if _cerrado:
		return
	_cerrado = true
	if _tween_foco != null and _tween_foco.is_valid():
		_tween_foco.kill()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_raiz, "modulate:a", 0.0, 0.22)
	tw.tween_property(_tarjeta, "scale", Vector2(0.94, 0.94), 0.22)
	tw.set_parallel(false)
	tw.tween_callback(func():
		terminado.emit()
		queue_free())


func _on_raiz_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.is_pressed():
		var pos: Vector2 = event.position
		if _rect_foco.has_point(pos):
			_siguiente()
		else:
			_anillo.pulsar()


func _unhandled_input(event: InputEvent) -> void:
	if _cerrado:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_finalizar()
		elif event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_RIGHT]:
			get_viewport().set_input_as_handled()
			_siguiente()
		elif event.keycode == KEY_LEFT:
			get_viewport().set_input_as_handled()
			_anterior()


func _crear_pill(texto_pill: String, fondo: Color, col_txt: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var st := Estilos_UI.caja(fondo, 999, Color(0, 0, 0, 0), 0, 0)
	st.content_margin_left = 10
	st.content_margin_right = 10
	st.content_margin_top = 4
	st.content_margin_bottom = 4
	p.add_theme_stylebox_override("panel", st)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var lbl := Estilos_UI.texto(texto_pill, 11, col_txt, 700)
	p.add_child(lbl)
	return p


func _tam_viewport() -> Vector2:
	var s := _velo.size
	if s.x > 0.0 and s.y > 0.0:
		return s
	return get_viewport().get_visible_rect().size


# ---------------------------------------------------------------- anillo animado de foco

class AnilloSpotlight extends Control:
	var rect_foco: Rect2 = Rect2():
		set(val):
			rect_foco = val
			queue_redraw()
	var color_acento: Color = Color("#d62828")
	var _t: float = 0.0
	var _pulso_extra: float = 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func pulsar() -> void:
		_pulso_extra = 1.0

	func _process(delta: float) -> void:
		_t += delta
		if _pulso_extra > 0.0:
			_pulso_extra = maxf(0.0, _pulso_extra - delta * 3.0)
		queue_redraw()

	func _draw() -> void:
		if rect_foco.size.x <= 0.0 or rect_foco.size.y <= 0.0:
			return
		var expansion := (sin(_t * 4.0) * 0.5 + 0.5) * 3.5 + _pulso_extra * 6.0
		var r_ext := rect_foco.grow(expansion)
		_dibujar_borde_redondeado(r_ext, RADIO_FOCO + expansion * 0.6, Color(color_acento, 0.55 + _pulso_extra * 0.35), 4.0)
		_dibujar_borde_redondeado(rect_foco, RADIO_FOCO, Color.WHITE, 2.5)

	func _dibujar_borde_redondeado(rect: Rect2, radio: float, col: Color, grosor: float) -> void:
		var r := minf(radio, minf(rect.size.x, rect.size.y) * 0.5)
		var pts := PackedVector2Array()
		var centros := [
			Vector2(rect.position.x + rect.size.x - r, rect.position.y + r),
			Vector2(rect.position.x + rect.size.x - r, rect.position.y + rect.size.y - r),
			Vector2(rect.position.x + r, rect.position.y + rect.size.y - r),
			Vector2(rect.position.x + r, rect.position.y + r),
		]
		var angs := [-PI * 0.5, 0.0, PI * 0.5, PI]
		for ci in range(4):
			var c: Vector2 = centros[ci]
			var a0: float = angs[ci]
			for s in range(7):
				var a := a0 + (PI * 0.5) * (float(s) / 6.0)
				pts.append(c + Vector2(cos(a), sin(a)) * r)
		pts.append(pts[0])
		draw_polyline(pts, col, grosor, true)


# ---------------------------------------------------------------- flecha de tarjeta hacia el foco

class FlechaTarjeta extends Control:
	var _tarjeta: Control
	var x_punta: float = 0.0:
		set(val):
			x_punta = val
			queue_redraw()
	var en_borde_superior: bool = true:
		set(val):
			en_borde_superior = val
			queue_redraw()

	func _init(tarjeta: Control) -> void:
		_tarjeta = tarjeta
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if _tarjeta == null or not is_instance_valid(_tarjeta) or x_punta <= 0.0:
			return
		var pos := _tarjeta.position
		var tam := _tarjeta.size
		var x := clampf(x_punta, pos.x + 28.0, pos.x + tam.x - 28.0)
		var y := (pos.y + 1.0) if en_borde_superior else (pos.y + tam.y - 1.0)
		var dir_y := -1.0 if en_borde_superior else 1.0
		var base := Vector2(x, y)
		var w := 14.0
		var h := 13.0
		var pts := PackedVector2Array([
			base + Vector2(-w, 0.0),
			base + Vector2(0.0, dir_y * h),
			base + Vector2(w, 0.0),
		])
		draw_colored_polygon(pts, Estilos_UI.SUPERFICIE)
		draw_polyline(pts, Estilos_UI.BORDE_FUERTE, 1.5, true)
