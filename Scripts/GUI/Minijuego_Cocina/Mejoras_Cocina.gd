class_name Mejoras_Cocina
extends Control

# ============================================================================
# Pantalla de Mejoras de Cocina (azul noche + latón + esmeralda).
#
# Dos columnas sobre un panel azul noche con marco dorado:
#   · Izquierda: las 5 mejoras con su nivel, estrellas y el coste siguiente.
#   · Derecha: escaparate grande de la siguiente versión, tres pestañas de
#     nivel con su coste, comparativa en dos bloques integrados (Actual vs
#     Con la mejora) y botón de compra.
#
# Tipografía: Titan One en títulos cartoon y Manrope en el resto de textos
# y cifras. La Caja del restaurante paga las mejoras; el dinero personal del
# Sim no se toca. Se abre desde el botón «Mejoras» del mapa de mundos.
# ============================================================================

signal cerrado()
signal compra_realizada(mejora_id: String, nuevo_nivel: int)
signal sonido_solicitado(nombre: String, tono: float)

# Paleta de la pantalla (azul noche + latón + esmeralda).
const C_FONDO := Color("#0a1f31")
const C_FONDO_ALTO := Color("#103049")
const C_PANEL := Color("#102c42")
const C_PANEL_CLARO := Color("#163a52")
const C_LINEA := Color("#27506b")
const C_LINEA_SUAVE := Color("#1c3d56")
const C_ORO := Color("#f5c451")
const C_ORO_CLARO := Color("#fde68a")
const C_CREMA := Color("#f8fafc")
const C_TEXTO := Color("#e7eef5")
const C_MUTED := Color("#9db4c7")
const C_MUTED_OSCURO := Color("#7895ad")
const C_VERDE := Color("#22c55e")
const C_VERDE_OSCURO := Color("#15803d")
const C_VERDE_CLARO := Color("#dcfce7")
const C_AMBAR := Color("#f59e0b")

const FUENTE_CARTOON := preload("res://Fuentes/UI/TitanOne-400.ttf")
const FUENTE_UI_400 := preload("res://Fuentes/UI/Manrope-400.ttf")
const FUENTE_UI_600 := preload("res://Fuentes/UI/Manrope-600.ttf")
const FUENTE_UI_700 := preload("res://Fuentes/UI/Manrope-700.ttf")
const FUENTE_UI_800 := preload("res://Fuentes/UI/Manrope-800.ttf")

const ANCHO_TARJETA := 1180.0
const ALTO_TARJETA := 640.0
const ALTO_CABECERA := 80.0
const ANCHO_IZQUIERDA := 346.0
const ALTO_FILA := 64.0
const ALTO_ESCENARIO_MIN := 146.0
const ALTO_PESTANAS := 56.0
const ALTO_BENEFICIOS := 148.0
const ALTO_CTA := 56.0

var restaurante_id: String = Sistema_Cocina.RESTAURANTE_BURGER
var mejora_seleccionada: String = "plancha"

var _velo: ColorRect
var _centro: CenterContainer
var _tarjeta: Control
var _fondo: Control
var _toast: PanelContainer
var _toast_lbl: Label
var _toast_tween: Tween
var _tween_apertura: Tween

# Cabecera
var _lbl_restaurante: Label
var _lbl_caja: Label
var _pill_caja: PanelContainer

# Columna izquierda
var _lista_mejoras: VBoxContainer
var _filas: Dictionary = {}
var _lbl_rango: Label
var _lbl_niveles: Label
var _lbl_siguiente_rango: Label
var _barra_progreso: ProgressBar

# Columna derecha
var _lbl_nombre_mejora: Label
var _pill_nivel: PanelContainer
var _lbl_pill_nivel: Label
var _lbl_subtitulo_mejora: Label
var _escaparate: Escaparate_Mejora
var _pill_escenario: PanelContainer
var _lbl_pill_escenario: Label
var _pips_escenario: Pips_Mejora
var _tabs: Array = []
var _panel_benef_actual: PanelContainer
var _panel_benef_siguiente: PanelContainer
var _panel_flecha_benef: PanelContainer
var _ic_flecha_benef: TextureRect
var _ic_benef_siguiente: TextureRect
var _lbl_benef_actual: Label
var _lbl_benef_siguiente: Label
var _div_actual: ColorRect
var _div_siguiente: ColorRect
var _lista_actual: VBoxContainer
var _lista_ganancias: VBoxContainer
var _cta: Button


# ============================================================================
# Ciclo de vida y API pública
# ============================================================================

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_Construir()


func abrir(restaurante: String = "") -> void:
	if restaurante != "":
		restaurante_id = restaurante
	if not Sistema_Cocina.MEJORAS_DEF.has(mejora_seleccionada):
		mejora_seleccionada = Sistema_Cocina.ORDEN_MEJORAS[0]
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	if _toast != null:
		_toast.visible = false
	var ya_visible: bool = visible
	visible = true
	_Refrescar_Todo()
	if not ya_visible:
		sonido_solicitado.emit("pop", 1.05)
	call_deferred("_Animar_Apertura")


func cerrar() -> void:
	if not visible:
		return
	visible = false
	cerrado.emit()


func seleccionar_mejora(mejora_id: String) -> void:
	if not Sistema_Cocina.MEJORAS_DEF.has(mejora_id):
		return
	mejora_seleccionada = mejora_id
	if visible:
		_Refrescar_Todo()
		_Animar_Escaparate()


# ============================================================================
# Construcción
# ============================================================================

func _Construir() -> void:
	_velo = ColorRect.new()
	_velo.name = "Velo"
	_velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_velo.color = Color(0.02, 0.05, 0.09, 0.78)
	_velo.mouse_filter = Control.MOUSE_FILTER_STOP
	_velo.gui_input.connect(_on_velo_input)
	add_child(_velo)

	_centro = CenterContainer.new()
	_centro.name = "Centro"
	_centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_centro.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_centro)

	_tarjeta = Control.new()
	_tarjeta.name = "Tarjeta_Mejoras"
	_tarjeta.custom_minimum_size = Vector2(ANCHO_TARJETA, ALTO_TARJETA)
	_tarjeta.mouse_filter = Control.MOUSE_FILTER_STOP
	_centro.add_child(_tarjeta)

	_fondo = Fondo_Panel_Mejoras.new()
	_fondo.name = "Fondo_Panel"
	_fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tarjeta.add_child(_fondo)

	var margen := MarginContainer.new()
	margen.name = "Margen_Interior"
	margen.set_anchors_preset(Control.PRESET_FULL_RECT)
	margen.add_theme_constant_override("margin_left", 20)
	margen.add_theme_constant_override("margin_right", 20)
	margen.add_theme_constant_override("margin_top", 0)
	margen.add_theme_constant_override("margin_bottom", 14)
	margen.mouse_filter = Control.MOUSE_FILTER_PASS
	_tarjeta.add_child(margen)

	var v := VBoxContainer.new()
	v.name = "Contenido"
	v.add_theme_constant_override("separation", 0)
	margen.add_child(v)

	v.add_child(_Construir_Cabecera())

	var margen_cuerpo := MarginContainer.new()
	margen_cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margen_cuerpo.add_theme_constant_override("margin_top", 10)
	margen_cuerpo.mouse_filter = Control.MOUSE_FILTER_PASS
	v.add_child(margen_cuerpo)

	var cuerpo := HBoxContainer.new()
	cuerpo.name = "Cuerpo"
	cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cuerpo.add_theme_constant_override("separation", 14)
	margen_cuerpo.add_child(cuerpo)

	cuerpo.add_child(_Construir_Columna_Izquierda())
	cuerpo.add_child(_Construir_Columna_Derecha())

	_Construir_Toast()
	_Refrescar_Todo()


func _Construir_Cabecera() -> Control:
	var cab := Control.new()
	cab.name = "Cabecera"
	cab.custom_minimum_size = Vector2(0, ALTO_CABECERA)
	cab.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 2)
	m.add_theme_constant_override("margin_right", 2)
	m.add_theme_constant_override("margin_top", 10)
	m.add_theme_constant_override("margin_bottom", 10)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cab.add_child(m)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	m.add_child(h)

	h.add_child(Estilos_UI.badge_icono("chef-hat", 46, 24, C_ORO, C_FONDO, 14))

	var titulos := VBoxContainer.new()
	titulos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titulos.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	titulos.add_theme_constant_override("separation", 1)
	titulos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(titulos)

	var tit := Label.new()
	tit.text = "MEJORAS DE COCINA"
	tit.add_theme_font_override("font", FUENTE_CARTOON)
	tit.add_theme_font_size_override("font_size", 27)
	tit.add_theme_color_override("font_color", C_ORO_CLARO)
	tit.add_theme_color_override("font_outline_color", Color("#06131f"))
	tit.add_theme_constant_override("outline_size", 6)
	tit.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
	tit.add_theme_constant_override("shadow_offset_y", 2)
	tit.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	titulos.add_child(tit)

	_lbl_restaurante = _texto("BURGER & STREET FOOD · SUBE EL NIVEL DE TU COCINA", 12, C_MUTED, 700)
	_lbl_restaurante.mouse_filter = Control.MOUSE_FILTER_IGNORE
	titulos.add_child(_lbl_restaurante)

	_pill_caja = PanelContainer.new()
	_pill_caja.name = "Pill_Caja"
	_pill_caja.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var st_caja := Estilos_UI.caja(Color("#071a2a"), 999, Color(C_ORO, 0.5), 1, 0)
	st_caja.content_margin_left = 12
	st_caja.content_margin_right = 15
	st_caja.content_margin_top = 6
	st_caja.content_margin_bottom = 6
	_pill_caja.add_theme_stylebox_override("panel", st_caja)
	var hc := HBoxContainer.new()
	hc.add_theme_constant_override("separation", 8)
	_pill_caja.add_child(hc)
	var moneda := TextureRect.new()
	moneda.texture = Arte_Cocina.TEX_MONEDA
	moneda.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	moneda.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	moneda.custom_minimum_size = Vector2(24, 24)
	moneda.size = Vector2(24, 24)
	moneda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hc.add_child(moneda)
	var col_caja := VBoxContainer.new()
	col_caja.add_theme_constant_override("separation", -2)
	hc.add_child(col_caja)
	var lbl_caja_tit := _texto("CAJA DEL LOCAL", 10, C_MUTED, 700)
	col_caja.add_child(lbl_caja_tit)
	_lbl_caja = _texto("0 €", 19, C_ORO_CLARO, 800)
	_lbl_caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col_caja.add_child(_lbl_caja)
	h.add_child(_pill_caja)

	var btn_cerrar := Estilos_UI.boton_icono("x", C_ORO_CLARO, 46)
	btn_cerrar.name = "Boton_Cerrar"
	btn_cerrar.custom_minimum_size = Vector2(46, 46)
	btn_cerrar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn_cerrar.tooltip_text = "Cerrar mejoras"
	btn_cerrar.add_theme_stylebox_override("normal", Estilos_UI.caja(Color("#0d2a3d"), 999, Color(C_ORO, 0.38), 1, 0))
	btn_cerrar.add_theme_stylebox_override("hover", Estilos_UI.caja(Color("#18445e"), 999, C_ORO, 1, 0))
	btn_cerrar.add_theme_stylebox_override("pressed", Estilos_UI.caja(Color("#0a2030"), 999, C_ORO, 1, 0))
	btn_cerrar.pressed.connect(func():
		sonido_solicitado.emit("click", 1.0)
		cerrar())
	h.add_child(btn_cerrar)
	return cab


func _Construir_Columna_Izquierda() -> Control:
	var izq := VBoxContainer.new()
	izq.name = "Columna_Izquierda"
	izq.custom_minimum_size = Vector2(ANCHO_IZQUIERDA, 0)
	izq.size_flags_vertical = Control.SIZE_EXPAND_FILL
	izq.add_theme_constant_override("separation", 6)

	var cab_lista := HBoxContainer.new()
	cab_lista.add_theme_constant_override("separation", 6)
	izq.add_child(cab_lista)
	var tit := _texto("TUS MEJORAS", 11, C_ORO, 800)
	tit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab_lista.add_child(tit)
	cab_lista.add_child(_Crear_Pildora("5 MEJORAS", Color("#0d2a3e"), C_LINEA, C_MUTED, 10))

	_lista_mejoras = VBoxContainer.new()
	_lista_mejoras.name = "Lista_Mejoras"
	_lista_mejoras.add_theme_constant_override("separation", 6)
	izq.add_child(_lista_mejoras)

	for mejora_id in Sistema_Cocina.ORDEN_MEJORAS:
		_lista_mejoras.add_child(_Construir_Fila_Mejora(mejora_id))

	var esp := Control.new()
	esp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	esp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	izq.add_child(esp)

	izq.add_child(_Construir_Tarjeta_Progreso())

	var hint := HBoxContainer.new()
	hint.add_theme_constant_override("separation", 6)
	var ic_info := Estilos_UI.icono_rect("info", 13, C_MUTED_OSCURO)
	ic_info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hint.add_child(ic_info)
	var lbl_hint := _parrafo("La Caja del local paga las mejoras. Se llena con cada servicio.", 11, C_MUTED_OSCURO, 600)
	lbl_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.add_child(lbl_hint)
	izq.add_child(hint)
	return izq


func _Construir_Fila_Mejora(mejora_id: String) -> Button:
	var btn := Button.new()
	btn.name = "Mejora_%s" % mejora_id
	btn.custom_minimum_size = Vector2(0, ALTO_FILA)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.text = ""
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	Estilos_UI.animar_presion(btn)
	btn.pressed.connect(func():
		if mejora_seleccionada != mejora_id:
			mejora_seleccionada = mejora_id
			sonido_solicitado.emit("click", 1.0)
			_Refrescar_Todo()
			_Animar_Escaparate())

	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 9)
	m.add_theme_constant_override("margin_right", 10)
	m.add_theme_constant_override("margin_top", 6)
	m.add_theme_constant_override("margin_bottom", 6)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(m)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(h)

	var grupo_icono := Control.new()
	grupo_icono.custom_minimum_size = Vector2(48, 48)
	grupo_icono.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	grupo_icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(grupo_icono)

	var marco := PanelContainer.new()
	marco.set_anchors_preset(Control.PRESET_FULL_RECT)
	marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st_marco := Estilos_UI.caja(Color("#071a2a"), 13, Color("#2a5978"), 1, 0)
	st_marco.content_margin_left = 4
	st_marco.content_margin_right = 4
	st_marco.content_margin_top = 4
	st_marco.content_margin_bottom = 4
	marco.add_theme_stylebox_override("panel", st_marco)
	grupo_icono.add_child(marco)

	var icono := Arte_Cocina.Icono_Mejora.new()
	icono.name = "Icono_Mejora"
	icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marco.add_child(icono)

	var check := PanelContainer.new()
	check.name = "Check_Maximo"
	check.position = Vector2(31, 31)
	check.size = Vector2(20, 20)
	check.mouse_filter = Control.MOUSE_FILTER_IGNORE
	check.visible = false
	var st_check := Estilos_UI.caja(C_VERDE, 999, Color("#0a1f31"), 2, 0)
	st_check.content_margin_left = 4
	st_check.content_margin_right = 4
	st_check.content_margin_top = 4
	st_check.content_margin_bottom = 4
	check.add_theme_stylebox_override("panel", st_check)
	check.add_child(Estilos_UI.icono_rect("check", 11, Color.WHITE))
	grupo_icono.add_child(check)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override("separation", 2)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(info)

	var lbl_nombre := _texto(Sistema_Cocina.Obtener_Nombre_Corto_Mejora(restaurante_id, mejora_id), 14, C_CREMA, 700)
	lbl_nombre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_nombre.max_lines_visible = 2
	lbl_nombre.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	lbl_nombre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(lbl_nombre)

	var pie := HBoxContainer.new()
	pie.add_theme_constant_override("separation", 6)
	pie.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(pie)

	var pips := Pips_Mejora.new()
	pips.tam = 7.0
	pips.custom_minimum_size = Vector2(38, 15)
	pips.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pie.add_child(pips)

	var lbl_nivel := _texto("Nv. 1", 11, C_MUTED, 700)
	lbl_nivel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pie.add_child(lbl_nivel)

	var esp := Control.new()
	esp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	esp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pie.add_child(esp)

	var ic_moneda := Estilos_UI.icono_rect("coins", 12, C_ORO)
	ic_moneda.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pie.add_child(ic_moneda)
	var lbl_coste := _texto("120 €", 12, C_ORO, 800)
	lbl_coste.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pie.add_child(lbl_coste)

	_filas[mejora_id] = {
		"btn": btn,
		"icono": icono,
		"pips": pips,
		"nombre": lbl_nombre,
		"nivel": lbl_nivel,
		"coste": lbl_coste,
		"coin": ic_moneda,
		"check": check,
	}
	return btn


func _Construir_Tarjeta_Progreso() -> Control:
	var pc := PanelContainer.new()
	pc.name = "Tarjeta_Progreso"
	pc.custom_minimum_size = Vector2(0, 108)
	var st := Estilos_UI.caja(Color("#0d2a3e"), 14, C_LINEA, 1, 0)
	st.content_margin_left = 12
	st.content_margin_right = 12
	st.content_margin_top = 9
	st.content_margin_bottom = 9
	pc.add_theme_stylebox_override("panel", st)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 5)
	pc.add_child(v)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	v.add_child(fila)
	var tit := _texto("TU PROGRESO", 11, C_ORO, 800)
	tit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(tit)
	_lbl_rango = _texto("Rango 0", 11, C_MUTED, 700)
	fila.add_child(_lbl_rango)

	var nombre_rango := HBoxContainer.new()
	nombre_rango.add_theme_constant_override("separation", 6)
	v.add_child(nombre_rango)
	nombre_rango.add_child(Estilos_UI.icono_rect("star", 15, C_ORO))
	_lbl_niveles = _texto("Aprendiz", 15, C_CREMA, 800)
	_lbl_niveles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nombre_rango.add_child(_lbl_niveles)

	_barra_progreso = ProgressBar.new()
	_barra_progreso.custom_minimum_size = Vector2(0, 10)
	_barra_progreso.show_percentage = false
	_barra_progreso.min_value = 0
	_barra_progreso.max_value = 100
	_barra_progreso.value = 0
	_barra_progreso.add_theme_stylebox_override("background", Estilos_UI.caja(Color("#071a2a"), 999, Color("#245272"), 1, 0))
	_barra_progreso.add_theme_stylebox_override("fill", Estilos_UI.caja(C_ORO, 999, C_ORO_CLARO, 0, 0))
	v.add_child(_barra_progreso)

	_lbl_siguiente_rango = _texto("0 / 20 ★ para el primer rango", 11, C_MUTED, 600)
	_lbl_siguiente_rango.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_lbl_siguiente_rango)
	return pc


func _Construir_Columna_Derecha() -> Control:
	var der := VBoxContainer.new()
	der.name = "Columna_Derecha"
	der.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	der.size_flags_vertical = Control.SIZE_EXPAND_FILL
	der.add_theme_constant_override("separation", 8)

	var fila_tit := HBoxContainer.new()
	fila_tit.add_theme_constant_override("separation", 8)
	der.add_child(fila_tit)

	_lbl_nombre_mejora = _texto("", 23, C_CREMA, 800)
	_lbl_nombre_mejora.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl_nombre_mejora.clip_text = true
	fila_tit.add_child(_lbl_nombre_mejora)

	_pill_nivel = _Crear_Pildora("Nv. 1 / 3", Color("#3a2a12"), Color(C_ORO, 0.6), C_ORO_CLARO, 11)
	_pill_nivel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_lbl_pill_nivel = _pill_nivel.get_child(0) as Label
	fila_tit.add_child(_pill_nivel)

	_lbl_subtitulo_mejora = _texto("", 12, C_ORO, 700)
	_lbl_subtitulo_mejora.mouse_filter = Control.MOUSE_FILTER_IGNORE
	der.add_child(_lbl_subtitulo_mejora)

	_escaparate = Escaparate_Mejora.new()
	_escaparate.name = "Escaparate"
	_escaparate.custom_minimum_size = Vector2(0, ALTO_ESCENARIO_MIN)
	_escaparate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_escaparate.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_escaparate.clip_contents = true
	_escaparate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	der.add_child(_escaparate)

	_pill_escenario = _Crear_Pildora("SIGUIENTE MEJORA", Color("#3a2a12"), Color(C_ORO, 0.55), C_ORO_CLARO, 10)
	_pill_escenario.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_pill_escenario.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_pill_escenario.offset_left = -168
	_pill_escenario.offset_top = 12
	_pill_escenario.offset_right = -14
	_pill_escenario.offset_bottom = 38
	_pill_escenario.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_escaparate.add_child(_pill_escenario)
	_lbl_pill_escenario = _pill_escenario.get_child(0) as Label
	_lbl_pill_escenario.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_pips_escenario = Pips_Mejora.new()
	_pips_escenario.tam = 8.5
	_pips_escenario.custom_minimum_size = Vector2(88, 24)
	_pips_escenario.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_pips_escenario.offset_left = 0
	_pips_escenario.offset_right = 0
	_pips_escenario.offset_top = -36
	_pips_escenario.offset_bottom = -12
	_pips_escenario.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_escaparate.add_child(_pips_escenario)

	var fila_tabs := HBoxContainer.new()
	fila_tabs.name = "Pestanas_Nivel"
	fila_tabs.add_theme_constant_override("separation", 8)
	fila_tabs.custom_minimum_size = Vector2(0, ALTO_PESTANAS)
	der.add_child(fila_tabs)
	for i in range(3):
		var tab := _Construir_Pestana(i + 1)
		_tabs.append(tab)
		fila_tabs.add_child(tab)

	der.add_child(_Construir_Beneficios())
	_Construir_CTA(der)
	return der


func _Construir_Pestana(nivel: int) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "Pestana_Nv%d" % nivel
	p.custom_minimum_size = Vector2(0, ALTO_PESTANAS)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 10)
	m.add_theme_constant_override("margin_right", 10)
	m.add_theme_constant_override("margin_top", 6)
	m.add_theme_constant_override("margin_bottom", 6)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(m)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 1)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(v)

	var top := _texto("NV. %d" % nivel, 11, C_MUTED, 700)
	top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(top)

	var pie := HBoxContainer.new()
	pie.alignment = BoxContainer.ALIGNMENT_CENTER
	pie.add_theme_constant_override("separation", 5)
	pie.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(pie)

	var icono := Estilos_UI.icono_rect("check", 14, C_CREMA)
	icono.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pie.add_child(icono)

	var txt := _texto("", 14, C_CREMA, 800)
	txt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pie.add_child(txt)

	p.set_meta("lbl_top", top)
	p.set_meta("lbl_pie", txt)
	p.set_meta("icono", icono)
	p.set_meta("pie", pie)
	return p


func _Construir_Beneficios() -> Control:
	var contenedor := HBoxContainer.new()
	contenedor.name = "Beneficios"
	contenedor.custom_minimum_size = Vector2(0, ALTO_BENEFICIOS)
	contenedor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contenedor.add_theme_constant_override("separation", 8)
	contenedor.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Bloque izquierdo: nivel actual.
	_panel_benef_actual = PanelContainer.new()
	_panel_benef_actual.name = "Tarjeta_Actual"
	_panel_benef_actual.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel_benef_actual.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_panel_benef_actual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st_act := Estilos_UI.caja(Color("#0c2438"), 14, Color("#244b66"), 1, 0)
	st_act.border_width_bottom = 3
	st_act.content_margin_left = 14
	st_act.content_margin_right = 14
	st_act.content_margin_top = 10
	st_act.content_margin_bottom = 10
	_panel_benef_actual.add_theme_stylebox_override("panel", st_act)
	contenedor.add_child(_panel_benef_actual)

	var v_act := VBoxContainer.new()
	v_act.add_theme_constant_override("separation", 7)
	_panel_benef_actual.add_child(v_act)

	var cab1 := HBoxContainer.new()
	cab1.add_theme_constant_override("separation", 6)
	v_act.add_child(cab1)
	_lbl_benef_actual = _texto("ACTUAL · Nv. 1", 11, C_ORO, 800)
	_lbl_benef_actual.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl_benef_actual.clip_text = true
	cab1.add_child(_lbl_benef_actual)
	cab1.add_child(Estilos_UI.icono_rect("check", 14, C_MUTED_OSCURO))

	_div_actual = ColorRect.new()
	_div_actual.color = Color("#1d415b")
	_div_actual.custom_minimum_size = Vector2(0, 1)
	_div_actual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v_act.add_child(_div_actual)

	_lista_actual = VBoxContainer.new()
	_lista_actual.add_theme_constant_override("separation", 6)
	_lista_actual.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v_act.add_child(_lista_actual)

	# Conector central de progresión.
	var centro_flecha := CenterContainer.new()
	centro_flecha.size_flags_vertical = Control.SIZE_EXPAND_FILL
	centro_flecha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contenedor.add_child(centro_flecha)

	_panel_flecha_benef = PanelContainer.new()
	_panel_flecha_benef.custom_minimum_size = Vector2(30, 30)
	_panel_flecha_benef.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st_fl := Estilos_UI.caja(Color("#0c2e28"), 999, Color(C_VERDE, 0.55), 1, 0)
	st_fl.content_margin_left = 0
	st_fl.content_margin_right = 0
	st_fl.content_margin_top = 0
	st_fl.content_margin_bottom = 0
	_panel_flecha_benef.add_theme_stylebox_override("panel", st_fl)
	var cc_fl := CenterContainer.new()
	cc_fl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ic_flecha_benef = Estilos_UI.icono_rect("chevron-right", 16, Color("#4ade80"))
	cc_fl.add_child(_ic_flecha_benef)
	_panel_flecha_benef.add_child(cc_fl)
	centro_flecha.add_child(_panel_flecha_benef)

	# Bloque derecho: siguiente mejora o rendimiento máximo.
	_panel_benef_siguiente = PanelContainer.new()
	_panel_benef_siguiente.name = "Tarjeta_Mejora"
	_panel_benef_siguiente.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel_benef_siguiente.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_panel_benef_siguiente.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel_benef_siguiente.add_theme_stylebox_override("panel", _Estilo_Bloque_Mejora(false))
	contenedor.add_child(_panel_benef_siguiente)

	var v_sig := VBoxContainer.new()
	v_sig.add_theme_constant_override("separation", 7)
	_panel_benef_siguiente.add_child(v_sig)

	var cab2 := HBoxContainer.new()
	cab2.add_theme_constant_override("separation", 6)
	v_sig.add_child(cab2)
	_lbl_benef_siguiente = _texto("CON LA MEJORA · Nv. 2", 11, Color("#4ade80"), 800)
	_lbl_benef_siguiente.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl_benef_siguiente.clip_text = true
	cab2.add_child(_lbl_benef_siguiente)
	_ic_benef_siguiente = Estilos_UI.icono_rect("trending-up", 14, Color("#4ade80"))
	cab2.add_child(_ic_benef_siguiente)

	_div_siguiente = ColorRect.new()
	_div_siguiente.color = Color("#184e40")
	_div_siguiente.custom_minimum_size = Vector2(0, 1)
	_div_siguiente.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v_sig.add_child(_div_siguiente)

	_lista_ganancias = VBoxContainer.new()
	_lista_ganancias.add_theme_constant_override("separation", 6)
	_lista_ganancias.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v_sig.add_child(_lista_ganancias)

	return contenedor


func _Construir_CTA(der: VBoxContainer) -> void:
	_cta = Button.new()
	_cta.name = "Boton_Comprar_Mejora"
	_cta.text = "MEJORAR"
	_cta.icon = Estilos_UI.icono("coins")
	_cta.expand_icon = false
	_cta.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cta.focus_mode = Control.FOCUS_NONE
	_cta.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_cta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cta.custom_minimum_size = Vector2(0, ALTO_CTA)
	_cta.add_theme_constant_override("icon_max_width", 20)
	_cta.add_theme_constant_override("h_separation", 10)
	_cta.add_theme_font_override("font", _fuente_ui(800))
	_cta.add_theme_font_size_override("font_size", 18)
	Estilos_UI.animar_presion(_cta)
	_cta.pressed.connect(_Comprar_Mejora)
	der.add_child(_cta)


func _Construir_Toast() -> void:
	_toast = PanelContainer.new()
	_toast.name = "Toast_Mejoras"
	_toast.visible = false
	_toast.z_index = 30
	_toast.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_toast.offset_left = 74
	_toast.offset_right = -74
	_toast.offset_top = 86
	_toast.offset_bottom = 138
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tarjeta.add_child(_toast)

	var st := Estilos_UI.caja(Color("#3a2a12"), 12, Color(C_AMBAR, 0.75), 1, 2)
	st.content_margin_left = 12
	st.content_margin_right = 12
	st.content_margin_top = 8
	st.content_margin_bottom = 8
	_toast.add_theme_stylebox_override("panel", st)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.add_child(h)
	h.add_child(Estilos_UI.icono_rect("triangle-alert", 16, C_ORO_CLARO))
	_toast_lbl = _texto("", 13, C_ORO_CLARO, 700)
	_toast_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_toast_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(_toast_lbl)


# ============================================================================
# Refresco de datos
# ============================================================================

func _Refrescar_Todo() -> void:
	if not is_inside_tree():
		return
	_Refrescar_Caja()
	_Refrescar_Lista()
	_Refrescar_Detalle()
	_Refrescar_Progreso()


func _Refrescar_Caja() -> void:
	var caja: int = Sistema_Cocina.Obtener_Caja_Restaurante()
	_lbl_caja.text = "%d €" % caja
	if _lbl_restaurante != null:
		_lbl_restaurante.text = "%s · SUBE EL NIVEL DE TU COCINA" % \
			Sistema_Cocina.Obtener_Nombre_Restaurante(restaurante_id).to_upper()


func _Refrescar_Lista() -> void:
	var caja: int = Sistema_Cocina.Obtener_Caja_Restaurante()
	for mejora_id in Sistema_Cocina.ORDEN_MEJORAS:
		if not _filas.has(mejora_id):
			continue
		var fila: Dictionary = _filas[mejora_id]
		var nv: int = Sistema_Cocina.Obtener_Nivel_Mejora(restaurante_id, mejora_id)
		var coste: int = Sistema_Cocina.Obtener_Coste_Siguiente_Mejora(restaurante_id, mejora_id)
		var seleccionada: bool = (mejora_id == mejora_seleccionada)

		if fila["icono"] != null:
			var tex_mejora: Texture2D = null
			if restaurante_id == Sistema_Cocina.RESTAURANTE_BURGER:
				tex_mejora = Arte_Cocina.textura_mejora(mejora_id, nv)
			if fila["icono"] is Arte_Cocina.Icono_Mejora:
				(fila["icono"] as Arte_Cocina.Icono_Mejora).configurar(
					restaurante_id, mejora_id, nv, tex_mejora)
			elif fila["icono"] is TextureRect:
				fila["icono"].texture = tex_mejora
		if fila.get("nombre") != null:
			fila["nombre"].text = Sistema_Cocina.Obtener_Nombre_Corto_Mejora(restaurante_id, mejora_id)
		if fila["pips"] != null:
			fila["pips"].set_nivel(nv)
		if fila["nivel"] != null:
			fila["nivel"].text = "Nv. %d" % nv
		if fila["check"] != null:
			fila["check"].visible = nv >= 3
		if fila["coste"] != null:
			if nv >= 3:
				fila["coste"].text = "MÁX."
				fila["coste"].add_theme_color_override("font_color", C_VERDE)
			else:
				fila["coste"].text = "%d €" % coste
				fila["coste"].add_theme_color_override("font_color", C_ORO if caja >= coste else C_MUTED_OSCURO)
		if fila["coin"] != null:
			fila["coin"].visible = nv < 3
			fila["coin"].self_modulate = C_ORO if caja >= coste else C_MUTED_OSCURO
		_Estilizar_Fila(fila["btn"] as Button, seleccionada)


func _Estilizar_Fila(btn: Button, seleccionada: bool) -> void:
	if btn == null or not is_instance_valid(btn):
		return
	var normal: StyleBoxFlat
	var hover: StyleBoxFlat
	var pressed: StyleBoxFlat
	if seleccionada:
		normal = Estilos_UI.caja(Color("#1b4a64"), 14, C_ORO, 2, 0)
		normal.border_width_left = 4
		normal.border_width_bottom = 4
		hover = normal.duplicate() as StyleBoxFlat
		hover.bg_color = Color("#205571")
		pressed = normal.duplicate() as StyleBoxFlat
		pressed.bg_color = Color("#153f57")
	else:
		normal = Estilos_UI.caja(Color("#102f47"), 14, C_LINEA_SUAVE, 1, 0)
		normal.border_width_bottom = 3
		hover = Estilos_UI.caja(Color("#163b55"), 14, Color("#356b8c"), 1, 0)
		hover.border_width_bottom = 3
		pressed = Estilos_UI.caja(Color("#0d293e"), 14, C_LINEA, 1, 0)
		pressed.border_width_bottom = 3
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", normal)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _Refrescar_Detalle() -> void:
	var def: Dictionary = Sistema_Cocina.MEJORAS_DEF.get(mejora_seleccionada, {})
	if def.is_empty():
		return
	var nv: int = Sistema_Cocina.Obtener_Nivel_Mejora(restaurante_id, mejora_seleccionada)
	var coste: int = Sistema_Cocina.Obtener_Coste_Siguiente_Mejora(restaurante_id, mejora_seleccionada)
	var caja: int = Sistema_Cocina.Obtener_Caja_Restaurante()
	var nivel_vista: int = mini(nv + 1, 3)
	var acento := Color(str(def.get("acento", "#f59e0b")))

	_lbl_nombre_mejora.text = Sistema_Cocina.Obtener_Nombre_Mejora(restaurante_id, mejora_seleccionada)
	_lbl_pill_nivel.text = "ACTUAL · Nv. %d/3" % nv
	_lbl_pill_nivel.add_theme_color_override("font_color",
		C_VERDE_CLARO if nv >= 3 else C_ORO_CLARO)
	_pill_nivel.add_theme_stylebox_override("panel",
		_Estilo_Pildora(Color("#10352a") if nv >= 3 else Color("#3a2a12"),
			Color(C_VERDE, 0.55) if nv >= 3 else Color(C_ORO, 0.6)))

	if nv >= 3:
		_lbl_subtitulo_mejora.text = "TU MEJOR VERSIÓN · Nv. 3 · %s" % \
			Sistema_Cocina.Obtener_Nombre_Nivel_Mejora(mejora_seleccionada, 3, restaurante_id).to_upper()
	else:
		_lbl_subtitulo_mejora.text = "ASÍ SERÁ TU COCINA · Nv. %d · %s" % [
			nivel_vista,
			Sistema_Cocina.Obtener_Nombre_Nivel_Mejora(mejora_seleccionada, nivel_vista, restaurante_id).to_upper()
		]

	_escaparate.configurar(
		Arte_Cocina.textura_mejora(mejora_seleccionada, nivel_vista),
		acento,
		nivel_vista,
		restaurante_id,
		mejora_seleccionada)
	_pips_escenario.set_nivel(nivel_vista)

	if nv >= 3:
		_lbl_pill_escenario.text = "TU MEJOR VERSIÓN"
		_pill_escenario.add_theme_stylebox_override("panel",
			_Estilo_Pildora(Color("#10352a"), Color(C_VERDE, 0.6)))
		_lbl_pill_escenario.add_theme_color_override("font_color", C_VERDE_CLARO)
	else:
		_lbl_pill_escenario.text = "SIGUIENTE MEJORA"
		_pill_escenario.add_theme_stylebox_override("panel",
			_Estilo_Pildora(Color("#3a2a12"), Color(C_ORO, 0.55)))
		_lbl_pill_escenario.add_theme_color_override("font_color", C_ORO_CLARO)

	_Refrescar_Pestanas(nv, coste)
	_Refrescar_Beneficios(nv)
	_Refrescar_CTA(nv, coste, caja)


func _Refrescar_Pestanas(nv: int, coste: int) -> void:
	var costes: Array = Sistema_Cocina.MEJORAS_DEF.get(mejora_seleccionada, {}).get("costes", [0, 0, 0])
	for i in range(3):
		var nivel := i + 1
		var p: PanelContainer = _tabs[i] as PanelContainer
		var lbl_top: Label = p.get_meta("lbl_top") as Label
		var lbl_pie: Label = p.get_meta("lbl_pie") as Label
		var icono: TextureRect = p.get_meta("icono") as TextureRect
		lbl_top.text = "NV. %d" % nivel
		var st: StyleBoxFlat
		if nivel <= nv:
			lbl_top.add_theme_color_override("font_color", Color("#86efac"))
			lbl_pie.text = "INCLUIDO"
			lbl_pie.add_theme_font_override("font", _fuente_ui(800))
			lbl_pie.add_theme_font_size_override("font_size", 14)
			lbl_pie.add_theme_color_override("font_color", C_VERDE_CLARO)
			icono.texture = Estilos_UI.icono("check")
			icono.self_modulate = Color("#86efac")
			st = Estilos_UI.caja(Color("#10352a"), 12, Color("#2b7a58"), 1, 0)
		elif nivel == nv + 1:
			lbl_top.add_theme_color_override("font_color", Color("#dcfce7"))
			lbl_pie.text = "%d €" % coste
			lbl_pie.add_theme_font_override("font", _fuente_ui(800))
			lbl_pie.add_theme_font_size_override("font_size", 14)
			lbl_pie.add_theme_color_override("font_color", Color.WHITE)
			icono.texture = Estilos_UI.icono("coins")
			icono.self_modulate = Color.WHITE
			st = Estilos_UI.caja(C_VERDE_OSCURO, 12, Color("#4ade80"), 1, 0)
		else:
			lbl_top.add_theme_color_override("font_color", C_MUTED_OSCURO)
			var coste_futuro: int = int(costes[nivel - 1]) if nivel - 1 < costes.size() else 0
			lbl_pie.text = "%d €" % coste_futuro
			lbl_pie.add_theme_font_override("font", _fuente_ui(700))
			lbl_pie.add_theme_font_size_override("font_size", 13)
			lbl_pie.add_theme_color_override("font_color", C_MUTED)
			icono.texture = Estilos_UI.icono("lock")
			icono.self_modulate = C_MUTED_OSCURO
			st = Estilos_UI.caja(Color("#0b2334"), 12, C_LINEA_SUAVE, 1, 0)
		st.border_width_bottom = 3
		p.add_theme_stylebox_override("panel", st)


func _Refrescar_Beneficios(nv: int) -> void:
	var actual: Array = Sistema_Cocina.Obtener_Beneficios_Nivel_Mejora(mejora_seleccionada, nv, restaurante_id)
	_lbl_benef_actual.text = "ACTUAL · Nv. %d · %s" % [
		nv, Sistema_Cocina.Obtener_Nombre_Nivel_Mejora(mejora_seleccionada, nv, restaurante_id).to_upper()
	]
	_Limpiar_Contenedor(_lista_actual)
	for txt in actual:
		_lista_actual.add_child(_Crear_Fila_Beneficio(str(txt), false))

	_Limpiar_Contenedor(_lista_ganancias)
	var es_max: bool = nv >= 3
	_panel_benef_siguiente.add_theme_stylebox_override("panel", _Estilo_Bloque_Mejora(es_max))
	_panel_flecha_benef.add_theme_stylebox_override("panel", _Estilo_Flecha_Beneficios(es_max))
	if es_max:
		_lbl_benef_siguiente.text = "RENDIMIENTO MÁXIMO"
		_lbl_benef_siguiente.add_theme_color_override("font_color", C_ORO_CLARO)
		_ic_benef_siguiente.texture = Estilos_UI.icono("badge-check")
		_ic_benef_siguiente.self_modulate = C_ORO
		_ic_flecha_benef.self_modulate = C_ORO_CLARO
		_div_siguiente.color = Color(C_ORO, 0.25)
		_lista_ganancias.add_child(_Crear_Fila_Beneficio("Nivel máximo completado (Nv. 3)", true, true))
		_lista_ganancias.add_child(_Crear_Fila_Beneficio("Bonificación activa al 100% en este local", true, true))
	else:
		var ganancias: Array = Sistema_Cocina.Obtener_Ganancias_Nivel_Mejora(mejora_seleccionada, nv + 1, restaurante_id)
		_lbl_benef_siguiente.text = "CON LA MEJORA · Nv. %d · %s" % [
			nv + 1, Sistema_Cocina.Obtener_Nombre_Nivel_Mejora(mejora_seleccionada, nv + 1, restaurante_id).to_upper()
		]
		_lbl_benef_siguiente.add_theme_color_override("font_color", Color("#4ade80"))
		_ic_benef_siguiente.texture = Estilos_UI.icono("trending-up")
		_ic_benef_siguiente.self_modulate = Color("#4ade80")
		_ic_flecha_benef.self_modulate = Color("#4ade80")
		_div_siguiente.color = Color("#184e40")
		if ganancias.is_empty():
			_lista_ganancias.add_child(_Crear_Fila_Beneficio("Rendimiento mejorado", true))
		else:
			for txt in ganancias:
				_lista_ganancias.add_child(_Crear_Fila_Beneficio(str(txt), true))


func _Refrescar_CTA(nv: int, coste: int, caja: int) -> void:
	if nv >= 3:
		_cta.text = "NIVEL MÁXIMO · MEJORA COMPLETA"
		_cta.icon = Estilos_UI.icono("badge-check")
		_cta.disabled = true
		_Aplicar_Estilo_CTA(Color("#14532d"), Color("#4ade80"), C_VERDE_CLARO, 16, true)
	elif caja >= coste:
		_cta.text = "MEJORAR A NV. %d  ·  %d €" % [nv + 1, coste]
		_cta.icon = Estilos_UI.icono("coins")
		_cta.disabled = false
		_Aplicar_Estilo_CTA(C_VERDE, C_VERDE.darkened(0.28), Color.WHITE, 18, false)
	else:
		_cta.text = "FALTAN %d €  ·  SIRVE MÁS CLIENTES" % (coste - caja)
		_cta.icon = Estilos_UI.icono("coins")
		_cta.disabled = false
		_Aplicar_Estilo_CTA(Color("#b45309"), Color("#78350f"), Color.WHITE, 16, false)


func _Aplicar_Estilo_CTA(bg: Color, borde_col: Color, texto_col: Color,
		tam: int, bloqueado: bool) -> void:
	_cta.add_theme_font_override("font", _fuente_ui(800))
	_cta.add_theme_font_size_override("font_size", tam)
	if bloqueado:
		var st_dis := Estilos_UI.caja(bg, 12, borde_col, 1, 0)
		st_dis.border_width_bottom = 3
		st_dis.content_margin_left = 20
		st_dis.content_margin_right = 20
		_cta.add_theme_stylebox_override("disabled", st_dis)
		_cta.add_theme_color_override("font_disabled_color", texto_col)
		_cta.add_theme_color_override("icon_disabled_color", texto_col)
		return
	var st_n := Estilos_UI.caja(bg, 12, borde_col, 0, 0)
	st_n.border_width_bottom = 4
	st_n.content_margin_left = 20
	st_n.content_margin_right = 20
	var st_h := Estilos_UI.caja(bg.lightened(0.06), 12, borde_col, 0, 0)
	st_h.border_width_bottom = 4
	st_h.content_margin_left = 20
	st_h.content_margin_right = 20
	var st_p := Estilos_UI.caja(bg.darkened(0.10), 12, borde_col, 0, 0)
	st_p.border_width_bottom = 2
	st_p.content_margin_left = 20
	st_p.content_margin_right = 20
	_cta.add_theme_stylebox_override("normal", st_n)
	_cta.add_theme_stylebox_override("hover", st_h)
	_cta.add_theme_stylebox_override("pressed", st_p)
	_cta.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		_cta.add_theme_color_override(k, texto_col)
	for k in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
		_cta.add_theme_color_override(k, texto_col)


func _Refrescar_Progreso() -> void:
	var p: Dictionary = Sistema_Cocina.Obtener_Progreso_Maestria()
	var rango: int = int(p.get("rango", 0))
	var estrellas: int = int(p.get("estrellas", 0))
	var info: Dictionary = p.get("info", {})
	var maximo: bool = bool(p.get("maximo", false))
	_lbl_rango.text = "RANGO %d/9 · %d ★" % [rango, estrellas]
	_lbl_niveles.text = str(info.get("nombre", "Aprendiz"))
	if maximo:
		_barra_progreso.max_value = 100.0
		_barra_progreso.value = 100.0
		_lbl_siguiente_rango.text = "Rango máximo · %d / %d ★" % [
			estrellas, Sistema_Cocina.ESTRELLAS_TOTALES_MAX]
	else:
		_barra_progreso.max_value = 100.0
		_barra_progreso.value = clampf(
			float(p.get("progreso", 0.0)) * 100.0, 0.0, 100.0)
		_lbl_siguiente_rango.text = "%d / %d ★ para el Rango %d" % [
			estrellas, int(p.get("umbral_siguiente", 0)), rango + 1]


# ============================================================================
# Acciones
# ============================================================================

func _Comprar_Mejora() -> void:
	var nv: int = Sistema_Cocina.Obtener_Nivel_Mejora(restaurante_id, mejora_seleccionada)
	if nv >= 3:
		return
	var coste: int = Sistema_Cocina.Obtener_Coste_Siguiente_Mejora(restaurante_id, mejora_seleccionada)
	var caja: int = Sistema_Cocina.Obtener_Caja_Restaurante()
	if caja < coste:
		sonido_solicitado.emit("click", 0.85)
		_Sacudir_CTA()
		_Pulsar_Caja()
		return

	var res: Dictionary = Sistema_Cocina.Comprar_Mejora(restaurante_id, mejora_seleccionada)
	if not bool(res.get("exito", false)):
		_Mostrar_Toast("No se pudo comprar la mejora. Inténtalo de nuevo.")
		return

	var nuevo_nivel: int = int(res.get("nuevo_nivel", nv + 1))
	sonido_solicitado.emit("coin", 1.0)
	if nuevo_nivel >= 3:
		sonido_solicitado.emit("star", 1.0)
	_Refrescar_Todo()
	_Pulsar_Caja()
	_Celebrar_Nivel(nuevo_nivel)
	_Animar_Escaparate()
	compra_realizada.emit(mejora_seleccionada, nuevo_nivel)


# ============================================================================
# Animaciones y avisos
# ============================================================================

func _Animar_Apertura() -> void:
	if not visible:
		return
	if _tween_apertura != null and _tween_apertura.is_valid():
		_tween_apertura.kill()
	_tarjeta.pivot_offset = _tarjeta.size * 0.5
	_tarjeta.modulate.a = 0.0
	_tarjeta.scale = Vector2(0.965, 0.965)
	_velo.modulate.a = 0.0
	_tween_apertura = create_tween()
	_tween_apertura.set_parallel(true)
	_tween_apertura.tween_property(_velo, "modulate:a", 1.0, 0.16)
	_tween_apertura.tween_property(_tarjeta, "modulate:a", 1.0, 0.16)
	_tween_apertura.tween_property(_tarjeta, "scale", Vector2.ONE, 0.24)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _Animar_Escaparate() -> void:
	if _escaparate == null or not is_instance_valid(_escaparate):
		return
	_escaparate.zoom = 0.9
	var tw := create_tween()
	tw.tween_property(_escaparate, "zoom", 1.0, 0.28)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _Pulsar_Caja() -> void:
	if _pill_caja == null or not is_instance_valid(_pill_caja):
		return
	_pill_caja.pivot_offset = _pill_caja.size * 0.5
	var tw := create_tween()
	tw.tween_property(_pill_caja, "scale", Vector2(1.07, 1.07), 0.08)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_pill_caja, "scale", Vector2.ONE, 0.16)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _Sacudir_CTA() -> void:
	if _cta == null or not is_instance_valid(_cta):
		return
	var x0: float = _cta.position.x
	var tw := create_tween()
	tw.tween_property(_cta, "position:x", x0 - 7.0, 0.05)
	tw.tween_property(_cta, "position:x", x0 + 7.0, 0.07)
	tw.tween_property(_cta, "position:x", x0 - 4.0, 0.05)
	tw.tween_property(_cta, "position:x", x0, 0.06)


func _Mostrar_Toast(mensaje: String) -> void:
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_lbl.text = mensaje
	_toast.visible = true
	_toast.modulate.a = 0.0
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast, "modulate:a", 1.0, 0.14)
	_toast_tween.tween_interval(2.2)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.24)
	_toast_tween.tween_callback(func(): _toast.visible = false)


func _Celebrar_Nivel(nivel: int) -> void:
	var capa := Control.new()
	capa.name = "Festejo_Mejora"
	capa.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.z_index = 50
	_tarjeta.add_child(capa)

	var banda := PanelContainer.new()
	banda.custom_minimum_size = Vector2(430, 104)
	banda.position = Vector2((_tarjeta.size.x - 430.0) * 0.5, _tarjeta.size.y * 0.33)
	banda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st_banda := Estilos_UI.caja(Color(0.03, 0.08, 0.13, 0.90), 18, C_ORO, 2, 4)
	st_banda.content_margin_left = 22
	st_banda.content_margin_right = 22
	st_banda.content_margin_top = 8
	st_banda.content_margin_bottom = 10
	banda.add_theme_stylebox_override("panel", st_banda)
	capa.add_child(banda)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banda.add_child(v)

	var tit := Label.new()
	tit.text = "¡NIVEL %d!" % nivel
	tit.add_theme_font_override("font", FUENTE_CARTOON)
	tit.add_theme_font_size_override("font_size", 44)
	tit.add_theme_color_override("font_color", C_ORO_CLARO)
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tit.add_theme_color_override("font_outline_color", Color("#06131f"))
	tit.add_theme_constant_override("outline_size", 8)
	tit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(tit)

	var sub := _texto(Sistema_Cocina.Obtener_Nombre_Mejora(
		restaurante_id, mejora_seleccionada).to_upper(), 14, C_CREMA, 700)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(sub)

	capa.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(capa, "modulate:a", 1.0, 0.10)
	tw.parallel().tween_property(banda, "position:y", banda.position.y - 18, 0.65)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.55)
	tw.tween_property(capa, "modulate:a", 0.0, 0.28)
	tw.tween_callback(func(): capa.queue_free())


# ============================================================================
# Utilidades de construcción y tipografía
# ============================================================================

static func _fuente_ui(peso: int = 600) -> FontFile:
	if peso >= 800:
		return FUENTE_UI_800
	if peso >= 700:
		return FUENTE_UI_700
	if peso >= 600:
		return FUENTE_UI_600
	return FUENTE_UI_400


static func _texto(contenido: String, tam: int = 14, color: Color = C_TEXTO,
		peso: int = 600) -> Label:
	var lbl := Label.new()
	lbl.set_meta("_tema_aplicado", true)
	lbl.text = contenido
	lbl.add_theme_font_override("font", _fuente_ui(peso))
	lbl.add_theme_font_size_override("font_size", tam)
	lbl.add_theme_color_override("font_color", color)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return lbl


static func _parrafo(contenido: String, tam: int = 13, color: Color = C_MUTED,
		peso: int = 600) -> Label:
	var lbl := _texto(contenido, tam, color, peso)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return lbl


func _Crear_Pildora(texto_pill: String, fondo: Color, borde: Color, color_texto: Color, tam: int) -> PanelContainer:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", _Estilo_Pildora(fondo, borde))
	var lbl := _texto(texto_pill, tam, color_texto, 800)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(lbl)
	return p


func _Estilo_Pildora(fondo: Color, borde: Color) -> StyleBoxFlat:
	var st := Estilos_UI.caja(fondo, 999, borde, 1, 0)
	st.content_margin_left = 10
	st.content_margin_right = 10
	st.content_margin_top = 4
	st.content_margin_bottom = 4
	return st


func _Estilo_Bloque_Mejora(maximo: bool) -> StyleBoxFlat:
	var st := Estilos_UI.caja(
		Color("#112c24") if maximo else Color("#0a2b25"),
		14,
		Color(C_ORO, 0.55) if maximo else Color(C_VERDE, 0.60),
		1, 0)
	st.border_width_bottom = 3
	st.content_margin_left = 14
	st.content_margin_right = 14
	st.content_margin_top = 10
	st.content_margin_bottom = 10
	return st


func _Estilo_Flecha_Beneficios(maximo: bool) -> StyleBoxFlat:
	var st := Estilos_UI.caja(
		Color("#1f2c22") if maximo else Color("#0c2e28"),
		999,
		Color(C_ORO, 0.55) if maximo else Color(C_VERDE, 0.55),
		1, 0)
	st.content_margin_left = 0
	st.content_margin_right = 0
	st.content_margin_top = 0
	st.content_margin_bottom = 0
	return st


func _Crear_Fila_Beneficio(texto_item: String, ganancia: bool, dorado: bool = false) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var alineador := MarginContainer.new()
	alineador.add_theme_constant_override("margin_top", 3 if ganancia else 6)
	alineador.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	alineador.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(alineador)

	if ganancia:
		var col_ic := C_ORO_CLARO if dorado else Color("#4ade80")
		var ic := Estilos_UI.icono_rect("check", 14, col_ic)
		alineador.add_child(ic)
	else:
		var punto := PanelContainer.new()
		punto.custom_minimum_size = Vector2(6, 6)
		punto.mouse_filter = Control.MOUSE_FILTER_IGNORE
		punto.add_theme_stylebox_override("panel", Estilos_UI.caja(C_ORO, 999, Color(0, 0, 0, 0), 0, 0))
		alineador.add_child(punto)

	var col_txt := (Color("#fef3c7") if dorado else Color("#ecfdf5")) if ganancia else Color("#dce6f0")
	var lbl := _texto(texto_item, 13, col_txt, 700 if ganancia else 600)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(lbl)
	return h


func _Limpiar_Contenedor(contenedor: Node) -> void:
	for hijo in contenedor.get_children():
		contenedor.remove_child(hijo)
		hijo.queue_free()


func _on_velo_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		cerrar()
	elif event is InputEventScreenTouch and event.pressed:
		cerrar()


# ============================================================================
# Dibujos internos
# ============================================================================

class Fondo_Panel_Mejoras:
	extends Control

	func _draw() -> void:
		var w := size.x
		var h := size.y
		if w <= 0 or h <= 0:
			return

		# Base con sombra exterior.
		var base := StyleBoxFlat.new()
		base.bg_color = Color("#0a1f31")
		base.set_corner_radius_all(28)
		base.border_width_left = 2
		base.border_width_right = 2
		base.border_width_top = 2
		base.border_width_bottom = 2
		base.border_color = Color("#e7b648")
		base.shadow_color = Color(0, 0, 0, 0.55)
		base.shadow_size = 22
		base.shadow_offset = Vector2(0, 8)
		base.anti_aliasing = true
		draw_style_box(base, Rect2(Vector2.ZERO, Vector2(w, h)))

		# Banda superior alineada con ALTO_CABECERA.
		var banda := StyleBoxFlat.new()
		banda.bg_color = Color("#12364f")
		banda.corner_radius_top_left = 26
		banda.corner_radius_top_right = 26
		banda.corner_radius_bottom_left = 0
		banda.corner_radius_bottom_right = 0
		banda.border_width_bottom = 2
		banda.border_color = Color("#f0c154")
		banda.anti_aliasing = true
		draw_style_box(banda, Rect2(0, 0, w, ALTO_CABECERA))

		# Rayado diagonal muy sutil en el cuerpo, recortado a la tarjeta.
		var x_min := 18.0
		var x_max := w - 18.0
		var y0 := 98.0
		var y1 := h - 24.0
		var paso_x := 260.0
		var paso_y := y1 - y0
		var i_min := int(floor((x_min - paso_x) / 34.0)) - 1
		var i_max := int(ceil(x_max / 34.0)) + 1
		for i in range(i_min, i_max + 1):
			var x := float(i) * 34.0
			var t0 := 0.0
			var t1 := 1.0
			t0 = maxf(t0, (x_min - x) / paso_x)
			t1 = minf(t1, (x_max - x) / paso_x)
			if t0 <= t1:
				draw_line(
					Vector2(x + paso_x * t0, y0 + paso_y * t0),
					Vector2(x + paso_x * t1, y0 + paso_y * t1),
					Color(1, 1, 1, 0.022), 1.0)

		# Brillo cálido detrás del escaparate.
		var foco := Vector2(w * 0.66, h * 0.40)
		for i in range(8, 0, -1):
			var r := 28.0 + float(i) * 24.0
			draw_circle(foco, r, Color(0.96, 0.72, 0.31, 0.012))

		# Esquinas doradas.
		var largo := 26.0
		var inset := 12.0
		var color_esquina := Color(0.96, 0.76, 0.32, 0.55)
		for esq in [Vector2(inset, inset), Vector2(w - inset, inset),
				Vector2(inset, h - inset), Vector2(w - inset, h - inset)]:
			var dx := 1.0 if esq.x < w * 0.5 else -1.0
			var dy := 1.0 if esq.y < h * 0.5 else -1.0
			draw_line(esq, esq + Vector2(largo * dx, 0), color_esquina, 2.0)
			draw_line(esq, esq + Vector2(0, largo * dy), color_esquina, 2.0)

		# Filo interior.
		var filo := StyleBoxFlat.new()
		filo.bg_color = Color(0, 0, 0, 0)
		filo.set_corner_radius_all(22)
		filo.border_width_left = 1
		filo.border_width_right = 1
		filo.border_width_top = 1
		filo.border_width_bottom = 1
		filo.border_color = Color(1, 1, 1, 0.055)
		filo.anti_aliasing = true
		draw_style_box(filo, Rect2(6, 6, w - 12, h - 12))


class Escaparate_Mejora:
	extends Control

	var textura: Texture2D
	var acento: Color = Color("#f59e0b")
	var zoom: float = 1.0
	var restaurante: String = ""
	var mejora_id: String = ""
	var nivel: int = 1
	var _t: float = 0.0
	var _st_base: StyleBoxFlat
	var _st_borde: StyleBoxFlat

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_process(true)

	func configurar(tex: Texture2D, color_acento: Color, nv: int,
			rest: String = "", mejora: String = "") -> void:
		textura = tex
		acento = color_acento
		restaurante = rest
		mejora_id = mejora
		nivel = clampi(nv, 1, 3)
		queue_redraw()

	func _process(delta: float) -> void:
		if not is_visible_in_tree():
			return
		_t += delta
		queue_redraw()

	func _base() -> StyleBoxFlat:
		if _st_base == null:
			_st_base = StyleBoxFlat.new()
			_st_base.bg_color = Color("#071a2a")
			_st_base.set_corner_radius_all(20)
			_st_base.anti_aliasing = true
		return _st_base

	func _borde() -> StyleBoxFlat:
		if _st_borde == null:
			_st_borde = StyleBoxFlat.new()
			_st_borde.bg_color = Color(0, 0, 0, 0)
			_st_borde.set_corner_radius_all(20)
			_st_borde.border_width_left = 1
			_st_borde.border_width_right = 1
			_st_borde.border_width_top = 1
			_st_borde.border_width_bottom = 1
			_st_borde.border_color = Color(1, 1, 1, 0.09)
			_st_borde.anti_aliasing = true
		return _st_borde

	func _draw() -> void:
		var w := size.x
		var h := size.y
		if w <= 0 or h <= 0:
			return
		var centro := Vector2(w * 0.5, h * 0.48)
		var radio := minf(w, h)

		draw_style_box(_base(), Rect2(Vector2.ZERO, size))

		# Halo cálido.
		for i in range(10, 0, -1):
			draw_circle(centro, radio * (0.18 + 0.035 * float(i)),
				Color(acento, 0.012 + 0.004 * float(11 - i)))

		# Rayos giratorios muy suaves.
		var rayos := 16
		for i in range(rayos):
			var ang := TAU * float(i) / float(rayos) + _t * 0.05
			var r1 := radio * 0.16
			var r2 := radio * 0.47
			var ancho := 0.055
			var p1 := centro + Vector2(cos(ang), sin(ang)) * r1
			var p2 := centro + Vector2(cos(ang - ancho), sin(ang - ancho)) * r2
			var p3 := centro + Vector2(cos(ang + ancho), sin(ang + ancho)) * r2
			draw_colored_polygon(PackedVector2Array([p1, p2, p3]), Color(acento, 0.045))

		# Destellos.
		var puntos := [
			Vector2(0.16, 0.22), Vector2(0.83, 0.30), Vector2(0.12, 0.70),
			Vector2(0.88, 0.66), Vector2(0.26, 0.48), Vector2(0.74, 0.15)
		]
		for i in range(puntos.size()):
			var p: Vector2 = puntos[i] * size
			var pulso := 0.5 + 0.5 * sin(_t * 1.7 + float(i) * 1.9)
			var r := 1.2 + pulso * 1.5
			draw_circle(p, r + 1.5, Color(1, 0.87, 0.55, 0.10 + pulso * 0.08))
			draw_circle(p, r, Color(1, 0.92, 0.66, 0.45 + pulso * 0.35))

		# Sombra de contacto.
		var base_y := h * 0.85
		draw_set_transform(Vector2(w * 0.5, base_y), 0.0, Vector2(1.0, 0.26))
		draw_circle(Vector2.ZERO, w * 0.27, Color(0, 0, 0, 0.42))
		draw_circle(Vector2.ZERO, w * 0.19, Color(0, 0, 0, 0.26))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

		# Objeto.
		if restaurante == Sistema_Cocina.RESTAURANTE_BISTRO:
			var lado_bistro: float = minf(w * 0.84,
				maxf(120.0, (h - 82.0) / 0.64))
			Arte_Cocina.dibujar_mejora_bistro(self,
				Vector2(w * 0.5, h * 0.45 + sin(_t * 1.5) * 3.0),
				lado_bistro, mejora_id, nivel)
		elif restaurante == Sistema_Cocina.RESTAURANTE_MERCADO:
			var lado_mercado: float = minf(w * 0.84,
				maxf(120.0, (h - 82.0) / 0.64))
			Arte_Cocina.dibujar_mejora_mercado(self,
				Vector2(w * 0.5, h * 0.45 + sin(_t * 1.5) * 3.0),
				lado_mercado, mejora_id, nivel)
		elif restaurante == Sistema_Cocina.RESTAURANTE_ALTA:
			var lado_alta: float = minf(w * 0.84,
				maxf(120.0, (h - 82.0) / 0.64))
			Arte_Cocina.dibujar_mejora_alta(self,
				Vector2(w * 0.5, h * 0.45 + sin(_t * 1.5) * 3.0),
				lado_alta, mejora_id, nivel)
		elif textura != null:
			var tex_size := textura.get_size()
			var disponible := Vector2(w - 62.0, h - 86.0)
			var escala := minf(disponible.x / maxf(1.0, tex_size.x),
				disponible.y / maxf(1.0, tex_size.y)) * zoom
			var dsize := tex_size * escala
			var y := h * 0.50 - dsize.y * 0.5 + sin(_t * 1.5) * 3.5
			var rect := Rect2(Vector2((w - dsize.x) * 0.5, y), dsize)
			draw_texture_rect(textura, rect, false, Color.WHITE)

		draw_style_box(_borde(), Rect2(Vector2.ZERO, size))


class Pips_Mejora:
	extends Control

	var nivel: int = 1
	var tam: float = 8.0
	var lleno: Color = Color("#f5c451")
	var vacio: Color = Color("#31536a")

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_nivel(nv: int) -> void:
		nivel = clampi(nv, 0, 3)
		queue_redraw()

	func _draw() -> void:
		var paso := tam * 1.7
		var ancho := paso * 2.0 + tam * 2.0
		var inicio := Vector2((size.x - ancho) * 0.5 + tam, size.y * 0.5)
		for i in range(3):
			var centro := inicio + Vector2(paso * float(i), 0.0)
			var relleno := i < nivel
			if relleno:
				_dibujar_estrella(centro, tam * 1.55, Color(lleno, 0.18))
			_dibujar_estrella(centro, tam, lleno if relleno else vacio, not relleno)

	func _dibujar_estrella(centro: Vector2, radio: float, color: Color, solo_borde: bool = false) -> void:
		var pts := PackedVector2Array()
		for i in range(10):
			var r := radio if i % 2 == 0 else radio * 0.44
			var ang := -PI * 0.5 + PI * float(i) / 5.0
			pts.append(centro + Vector2(cos(ang), sin(ang)) * r)
		pts.append(pts[0])
		if solo_borde:
			draw_polyline(pts, color, 1.2, true)
		else:
			draw_colored_polygon(pts, color)
