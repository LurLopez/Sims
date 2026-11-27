extends Control

# ============================================================================
# MINIJUEGO "SALIR A CORRER" · PARK RUSH 3D
#
# Runner infinito 3D de 3 carriles (720x1280 vertical). El mundo 3D, el
# personaje 3D dinámico del Sim, la física de rampas/techos y los power-ups
# viven en Runner_Mundo.gd + Runner_Simulacion.gd + Runner_Personaje_3D.gd.
# Este controlador gestiona el título, el HUD arcade limpio, los gestos
# táctiles (deslizar + doble toque tabla), teclado, audio, pausa y resultado
# con recompensa directa al Sim a través de Sistema_Correr.
# ============================================================================

signal cerrado()

const Mundo := preload("res://Scripts/GUI/Minijuego_Correr/Runner_Mundo.gd")
const Sonidos := preload("res://Scripts/GUI/Minijuego_Correr/Sonidos_Correr.gd")
const TEX_MONEDA := preload("res://Imagenes/Minijuego_Correr/Objetos/moneda.png")
const FUENTE_ARCADE := preload("res://Fuentes/UI/TitanOne-400.ttf")

const COLOR_PANEL := Color(0.06, 0.20, 0.44, 0.95)
const COLOR_BORDE := Color("#5eead4")
const COLOR_TEXTO_SUAVE := Color("#d3e6f7")
const COLOR_ORO := Color("#ffd43b")
const COLOR_CIAN := Color("#38bdf8")
const COLOR_VERDE := Color("#34d399")
const COLOR_ROSA := Color("#fb7185")
const COLOR_AZUL_HUD := Color("#1d6ef5")
const COLOR_VERDE_BOTON := Color("#22c55e")
const COLOR_TINTA_HUD := Color("#0b1936")

var _mundo: Runner_Mundo
var _sonidos: Sonidos_Correr

var _hud: Control
var _menu: Control
var _modal_pausa: Control
var _modal_fin: Control
var _velo: ColorRect
var _aviso: Label
var _aviso_tween: Tween
var _velo_tween: Tween
var _lbl_cuenta: Label
var _cuenta_activa: bool = false
var _cuenta_paso: int = 3
var _cuenta_t: float = 0.0

# HUD en partida
var _lbl_puntuacion: Label
var _lbl_mult: Label
var _badge_mult: PanelContainer
var _lbl_distancia: Label
var _lbl_monedas: Label
var _chip_monedas: Control
var _chip_llaves: Control
var _lbl_llaves: Label
var _btn_pausa: Button
var _btn_tabla: Button
var _lbl_tabla_texto: Label
var _lbl_tabla_cant: Label
var _badge_techo: PanelContainer
var _badge_tropiezo: PanelContainer
var _barras_powerups: VBoxContainer
var _powerup_widgets: Dictionary = {} # clave -> {panel, bar, lbl}
var _pill_mision: PanelContainer
var _lbl_mision: Label

# Menú y modales
var _lbl_record_menu: Label
var _lbl_stats_menu: Label
var _lbl_pausa_puntos: Label
var _lbl_pausa_monedas: Label
var _vbox_retos_pausa: VBoxContainer
var _vbox_fin: VBoxContainer

# Reanimación estilo Subway Surfers: primera gratis y luego coste en llaves
var _modal_revive: Control
var _lbl_revive_titulo: Label
var _lbl_revive_coste: Label
var _lbl_revive_tiempo: Label
var _btn_revive: Button
var _revive_tiempo: float = 0.0
var _revive_activo: bool = false
var _revives_gratis_usados: int = 0
var _revives_pagadas: int = 0

var _estado: String = "menu" # menu | jugando | pausa | revive | fin | cerrando
var _tiempo_fin: float = -1.0
var _resumen: Dictionary = {}
var _tam: Vector2 = Vector2(720.0, 1280.0)
var _quit_on_go_back_previo: bool = true
var _racha_monedas: int = 0
var _ultimo_coin_ms: int = 0

# Gestos táctiles (swipe 4 direcciones + doble toque para activar la Tabla)
var _touch_indice: int = -1
var _touch_inicio: Vector2 = Vector2.ZERO
var _touch_hecho: bool = false
var _ultimo_tap_ms: int = 0
var _ultimo_tap_pos: Vector2 = Vector2.ZERO


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_tam = get_viewport_rect().size
	_quit_on_go_back_previo = get_tree().is_quit_on_go_back()
	get_tree().set_quit_on_go_back(false)

	_Crear_Mundo()
	_Crear_HUD()
	_Crear_Menu()
	_Crear_Modales()
	_Crear_Capa_Transicion()
	_Ajustar_A_Tamano()

	if get_viewport() != null:
		get_viewport().size_changed.connect(_Ajustar_A_Tamano)

	_Conectar_Mundo()
	_Mostrar_Menu()
	Musica.Reproducir_Correr()

	_velo.modulate.a = 1.0
	_velo_tween = create_tween()
	_velo_tween.tween_property(_velo, "modulate:a", 0.0, 0.30).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _exit_tree() -> void:
	get_tree().set_quit_on_go_back(_quit_on_go_back_previo)
	if _sonidos != null and is_instance_valid(_sonidos):
		_sonidos.parar_todo()
	Musica.Reproducir_General()


func _notification(que: int) -> void:
	if que != NOTIFICATION_WM_GO_BACK_REQUEST:
		return
	if _estado == "cerrando":
		return
	if _estado == "revive":
		_Terminar_Tras_Caida()
		return
	_Alternar_Pausa()


# ----------------------------------------------------------------------------
# Construcción del mundo y la UI
# ----------------------------------------------------------------------------

func _Crear_Mundo() -> void:
	_mundo = Mundo.new()
	_mundo.name = "Runner_Mundo"
	add_child(_mundo)
	_mundo.configurar_tamano(_tam)

	_sonidos = Sonidos.new()
	_sonidos.name = "Sonidos_Correr"
	add_child(_sonidos)


func _Crear_HUD() -> void:
	_hud = Control.new()
	_hud.name = "HUD"
	_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hud.mouse_filter = Control.MOUSE_FILTER_PASS
	_hud.visible = false
	add_child(_hud)

	# Barra superior limpia (izquierda: puntuación + x1/x2 + metros; derecha: monedas + pausa)
	var margen := MarginContainer.new()
	margen.name = "Margen_Superior"
	margen.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	margen.offset_left = 14.0
	margen.offset_right = -14.0
	margen.offset_top = 20.0
	margen.offset_bottom = 110.0
	margen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(margen)

	var fila_sup := HBoxContainer.new()
	fila_sup.alignment = BoxContainer.ALIGNMENT_BEGIN
	fila_sup.add_theme_constant_override("separation", 8)
	fila_sup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margen.add_child(fila_sup)

	# Columna izquierda: marcador principal + distancia + medidores activos de power-ups
	var col_izq := VBoxContainer.new()
	col_izq.add_theme_constant_override("separation", 6)
	col_izq.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila_sup.add_child(col_izq)

	var pill_score := PanelContainer.new()
	var st_sc := Estilos_UI.caja(Color("#12397a"), 16, Color("#56ccf2"), 3, 6)
	st_sc.border_width_bottom = 5
	st_sc.content_margin_left = 10.0
	st_sc.content_margin_right = 15.0
	st_sc.content_margin_top = 6.0
	st_sc.content_margin_bottom = 7.0
	pill_score.add_theme_stylebox_override("panel", st_sc)
	pill_score.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col_izq.add_child(pill_score)

	var h_sc := HBoxContainer.new()
	h_sc.add_theme_constant_override("separation", 8)
	h_sc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill_score.add_child(h_sc)

	_badge_mult = PanelContainer.new()
	_badge_mult.custom_minimum_size = Vector2(40.0, 28.0)
	_badge_mult.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var st_m := Estilos_UI.caja(Color("#f59e0b"), 9, Color("#fef08a"), 2, 0)
	st_m.border_width_bottom = 3
	st_m.content_margin_left = 8.0
	st_m.content_margin_right = 8.0
	st_m.content_margin_top = 2.0
	st_m.content_margin_bottom = 2.0
	_badge_mult.add_theme_stylebox_override("panel", st_m)
	_badge_mult.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lbl_mult = _Label_Contorno("x1", 14, Color.WHITE, COLOR_TINTA_HUD, 4)
	_lbl_mult.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_mult.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_badge_mult.add_child(_lbl_mult)
	h_sc.add_child(_badge_mult)

	_lbl_puntuacion = _Label_Contorno("000000", 25, Color.WHITE, COLOR_TINTA_HUD, 6)
	h_sc.add_child(_lbl_puntuacion)

	# Chip de metros debajo de la puntuación
	var pill_dist := PanelContainer.new()
	var st_d := Estilos_UI.caja(Color(0.06, 0.19, 0.42, 0.90), 12, Color("#38bdf8"), 2, 3)
	st_d.border_width_bottom = 3
	st_d.content_margin_left = 10.0
	st_d.content_margin_right = 11.0
	st_d.content_margin_top = 3.0
	st_d.content_margin_bottom = 4.0
	pill_dist.add_theme_stylebox_override("panel", st_d)
	pill_dist.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	pill_dist.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col_izq.add_child(pill_dist)

	var h_dist := HBoxContainer.new()
	h_dist.add_theme_constant_override("separation", 5)
	h_dist.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill_dist.add_child(h_dist)
	h_dist.add_child(Estilos_UI.icono_rect("footprints", 13, COLOR_VERDE))
	_lbl_distancia = _Texto_Contorno("0 m", 13, Color.WHITE, COLOR_TINTA_HUD, 3)
	h_dist.add_child(_lbl_distancia)

	# Barras activas de power-ups (solo visibles cuando están activos)
	_barras_powerups = VBoxContainer.new()
	_barras_powerups.name = "Barras_Powerups"
	_barras_powerups.add_theme_constant_override("separation", 5)
	_barras_powerups.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col_izq.add_child(_barras_powerups)
	_Crear_Medidor_Powerup("tabla", "TABLA", COLOR_CIAN, Runner_Simulacion.DURACION_TABLA)
	_Crear_Medidor_Powerup("iman", "IMÁN", COLOR_ROSA, Runner_Simulacion.DURACION_IMAN)
	_Crear_Medidor_Powerup("zapatillas", "SALTO+", COLOR_VERDE, Runner_Simulacion.DURACION_ZAPATILLAS)
	_Crear_Medidor_Powerup("multiplicador", "DOBLE 2X", COLOR_ORO, Runner_Simulacion.DURACION_MULTIPLICADOR)
	_Crear_Medidor_Powerup("jetpack", "JETPACK", Color("#fb923c"), Runner_Simulacion.DURACION_JETPACK)
	_Crear_Medidor_Powerup("pogo", "POGO", Color("#a78bfa"), Runner_Simulacion.DURACION_POGO)

	# Píldora del reto activo (estilo lista de misiones de Subway Surfers)
	_pill_mision = PanelContainer.new()
	_pill_mision.name = "Pill_Mision"
	_pill_mision.custom_minimum_size = Vector2(214.0, 30.0)
	_pill_mision.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pill_mision.visible = false
	var st_mi := Estilos_UI.caja(Color(0.07, 0.16, 0.33, 0.92), 12, Color("#a78bfa"), 2, 4)
	st_mi.border_width_bottom = 3
	st_mi.content_margin_left = 10.0
	st_mi.content_margin_right = 10.0
	st_mi.content_margin_top = 4.0
	st_mi.content_margin_bottom = 5.0
	_pill_mision.add_theme_stylebox_override("panel", st_mi)
	col_izq.add_child(_pill_mision)
	var h_mi := HBoxContainer.new()
	h_mi.add_theme_constant_override("separation", 6)
	h_mi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pill_mision.add_child(h_mi)
	h_mi.add_child(Estilos_UI.icono_rect("target", 14, Color("#c4b5fd")))
	_lbl_mision = _Texto_Contorno("RETO", 10, Color.WHITE, COLOR_TINTA_HUD, 2)
	_lbl_mision.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_mi.add_child(_lbl_mision)

	var sep := Control.new()
	sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila_sup.add_child(sep)

	# Derecha: monedas + botón pausa
	var col_der := HBoxContainer.new()
	col_der.alignment = BoxContainer.ALIGNMENT_END
	col_der.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	col_der.add_theme_constant_override("separation", 8)
	col_der.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila_sup.add_child(col_der)

	_chip_monedas = _Crear_Chip_Monedas()
	col_der.add_child(_chip_monedas)

	_chip_llaves = _Crear_Chip_Llaves()
	col_der.add_child(_chip_llaves)

	_btn_pausa = _Boton_Oscuro("pause", 46)
	_btn_pausa.name = "Boton_Pausa"
	_btn_pausa.pressed.connect(_Alternar_Pausa)
	col_der.add_child(_btn_pausa)

	# Aviso superior central de equilibrio tras tropiezo lateral
	_badge_tropiezo = PanelContainer.new()
	_badge_tropiezo.name = "Badge_Tropiezo"
	_badge_tropiezo.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_badge_tropiezo.offset_left = -125.0
	_badge_tropiezo.offset_right = 125.0
	_badge_tropiezo.offset_top = 86.0
	_badge_tropiezo.offset_bottom = 120.0
	_badge_tropiezo.visible = false
	_badge_tropiezo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st_tr := Estilos_UI.caja(Color("#dc2626"), 999, COLOR_ORO, 2, 4)
	st_tr.content_margin_left = 12.0
	st_tr.content_margin_right = 12.0
	st_tr.content_margin_top = 4.0
	st_tr.content_margin_bottom = 4.0
	_badge_tropiezo.add_theme_stylebox_override("panel", st_tr)
	var lbl_tr := _Texto_Contorno("¡CUIDADO! EQUILIBRIO", 11, Color.WHITE, COLOR_TINTA_HUD, 3)
	lbl_tr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_badge_tropiezo.add_child(lbl_tr)
	_hud.add_child(_badge_tropiezo)

	# Zona inferior: botón táctil de Tabla/Escudo (izquierda) + chip "¡TECHO!" (derecha)
	var barra_inf := HBoxContainer.new()
	barra_inf.name = "Barra_Inferior"
	barra_inf.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	barra_inf.offset_left = 16.0
	barra_inf.offset_right = -16.0
	barra_inf.offset_top = -76.0
	barra_inf.offset_bottom = -20.0
	barra_inf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(barra_inf)

	_btn_tabla = Button.new()
	_btn_tabla.name = "Boton_Tabla"
	_btn_tabla.custom_minimum_size = Vector2(182.0, 50.0)
	_btn_tabla.focus_mode = Control.FOCUS_NONE
	_btn_tabla.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_btn_tabla.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_btn_tabla.pressed.connect(_on_pulsar_tabla)
	var h_tab := HBoxContainer.new()
	h_tab.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h_tab.alignment = BoxContainer.ALIGNMENT_CENTER
	h_tab.add_theme_constant_override("separation", 8)
	h_tab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_btn_tabla.add_child(h_tab)
	h_tab.add_child(Estilos_UI.icono_rect("zap", 18, COLOR_CIAN))
	_lbl_tabla_texto = _Texto_Contorno("TABLA", 13, Color("#7dd3fc"), COLOR_TINTA_HUD, 3)
	h_tab.add_child(_lbl_tabla_texto)
	var pill_cnt := PanelContainer.new()
	pill_cnt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pill_cnt.custom_minimum_size = Vector2(26.0, 24.0)
	var st_cnt := Estilos_UI.caja(Color(0, 0, 0, 0.38), 7, Color(1, 1, 1, 0.18), 1, 0)
	st_cnt.content_margin_left = 7.0
	st_cnt.content_margin_right = 7.0
	st_cnt.content_margin_top = 2.0
	st_cnt.content_margin_bottom = 2.0
	pill_cnt.add_theme_stylebox_override("panel", st_cnt)
	pill_cnt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lbl_tabla_cant = _Texto_Contorno("3", 12, Color.WHITE, COLOR_TINTA_HUD, 2)
	_lbl_tabla_cant.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pill_cnt.add_child(_lbl_tabla_cant)
	h_tab.add_child(pill_cnt)
	_Aplicar_Estilo_Boton_Tabla(false, true)
	barra_inf.add_child(_btn_tabla)

	var sep_inf := Control.new()
	sep_inf.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sep_inf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	barra_inf.add_child(sep_inf)

	_badge_techo = PanelContainer.new()
	_badge_techo.name = "Badge_Techo"
	_badge_techo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_badge_techo.visible = false
	_badge_techo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st_te := Estilos_UI.caja(COLOR_ORO, 999, Color("#0f172a"), 2, 4)
	st_te.content_margin_left = 14.0
	st_te.content_margin_right = 14.0
	st_te.content_margin_top = 6.0
	st_te.content_margin_bottom = 6.0
	_badge_techo.add_theme_stylebox_override("panel", st_te)
	var lbl_te := Estilos_UI.texto("¡POR LOS TECHOS!", 12, Color("#0f172a"), 800)
	_badge_techo.add_child(lbl_te)
	barra_inf.add_child(_badge_techo)


func _Crear_Medidor_Powerup(clave: String, titulo: String, color: Color, duracion: float) -> void:
	var p := PanelContainer.new()
	var st := Estilos_UI.caja(Color(0.06, 0.19, 0.42, 0.92), 12, Color(color, 0.85), 2, 4)
	st.border_width_bottom = 3
	st.content_margin_left = 10.0
	st.content_margin_right = 10.0
	st.content_margin_top = 4.0
	st.content_margin_bottom = 5.0
	p.add_theme_stylebox_override("panel", st)
	p.custom_minimum_size = Vector2(188.0, 30.0)
	p.visible = false
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_barras_powerups.add_child(p)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(h)

	var lbl_t := _Texto_Contorno(titulo, 10, Color.WHITE, COLOR_TINTA_HUD, 2)
	lbl_t.custom_minimum_size = Vector2(56.0, 0.0)
	h.add_child(lbl_t)

	var bar := ProgressBar.new()
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.custom_minimum_size = Vector2(72.0, 9.0)
	bar.min_value = 0.0
	bar.max_value = duracion
	bar.value = duracion
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", Estilos_UI.caja(Color(0.08, 0.12, 0.22, 0.9), 999, Color(1, 1, 1, 0.10), 1, 0))
	bar.add_theme_stylebox_override("fill", Estilos_UI.barra_relleno(color, 999))
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(bar)

	var lbl_s := _Texto_Contorno("10s", 10, color, COLOR_TINTA_HUD, 2)
	lbl_s.custom_minimum_size = Vector2(28.0, 0.0)
	lbl_s.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(lbl_s)

	_powerup_widgets[clave] = {"panel": p, "bar": bar, "lbl": lbl_s}


func _Crear_Chip_Monedas() -> PanelContainer:
	var chip := PanelContainer.new()
	var st := Estilos_UI.caja(Color("#12397a"), 16, Color("#ffd43b"), 3, 6)
	st.border_width_bottom = 5
	st.content_margin_left = 10.0
	st.content_margin_right = 14.0
	st.content_margin_top = 6.0
	st.content_margin_bottom = 7.0
	chip.add_theme_stylebox_override("panel", st)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(h)

	var tex := TextureRect.new()
	tex.texture = TEX_MONEDA
	tex.custom_minimum_size = Vector2(26.0, 26.0)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(tex)

	_lbl_monedas = _Label_Contorno("0", 23, COLOR_ORO, COLOR_TINTA_HUD, 6)
	h.add_child(_lbl_monedas)
	return chip


func _Crear_Chip_Llaves() -> PanelContainer:
	var chip := PanelContainer.new()
	var st := Estilos_UI.caja(Color("#2b2350"), 16, Color("#c4b5fd"), 3, 6)
	st.border_width_bottom = 5
	st.content_margin_left = 9.0
	st.content_margin_right = 12.0
	st.content_margin_top = 6.0
	st.content_margin_bottom = 7.0
	chip.add_theme_stylebox_override("panel", st)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 5)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(h)
	h.add_child(Estilos_UI.icono_rect("key", 22, Color("#ddd6fe")))
	_lbl_llaves = _Label_Contorno("0", 22, Color("#f5f3ff"), COLOR_TINTA_HUD, 5)
	h.add_child(_lbl_llaves)
	return chip


func _Crear_Menu() -> void:
	_menu = Control.new()
	_menu.name = "Menu"
	_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_menu.mouse_filter = Control.MOUSE_FILTER_STOP
	_menu.visible = false
	add_child(_menu)

	# Sin velo oscuro: dejamos brillar toda la escena 3D del parque y al Sim en primer plano!
	var margen := MarginContainer.new()
	margen.name = "Margen_Menu"
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margen.add_theme_constant_override("margin_left", 20)
	margen.add_theme_constant_override("margin_right", 20)
	margen.add_theme_constant_override("margin_top", 26)
	margen.add_theme_constant_override("margin_bottom", 26)
	margen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu.add_child(margen)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margen.add_child(v)

	# Emblema superior arcade sobre el cielo despejado (inspirado en la demo!)
	var esp_top := Control.new()
	esp_top.custom_minimum_size = Vector2(0.0, 26.0)
	esp_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(esp_top)

	var logo_box := VBoxContainer.new()
	logo_box.alignment = BoxContainer.ALIGNMENT_CENTER
	logo_box.add_theme_constant_override("separation", 4)
	logo_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(logo_box)

	var banner_tit := PanelContainer.new()
	banner_tit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var st_tit := Estilos_UI.caja(Color("#154396"), 22, Color("#56ccf2"), 4, 14)
	st_tit.border_width_bottom = 8
	st_tit.content_margin_left = 30.0
	st_tit.content_margin_right = 30.0
	st_tit.content_margin_top = 10.0
	st_tit.content_margin_bottom = 10.0
	banner_tit.add_theme_stylebox_override("panel", st_tit)
	banner_tit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lbl_tit := _Label_Contorno("PARK RUSH", 52, Color("#ffde3b"), Color("#0a1936"), 14)
	lbl_tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_tit.add_child(lbl_tit)
	logo_box.add_child(banner_tit)

	var banner_sub := PanelContainer.new()
	banner_sub.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var st_sub := Estilos_UI.caja(Color("#ef2d4a"), 14, Color("#ffe066"), 3, 8)
	st_sub.border_width_bottom = 5
	st_sub.content_margin_left = 22.0
	st_sub.content_margin_right = 22.0
	st_sub.content_margin_top = 4.0
	st_sub.content_margin_bottom = 5.0
	banner_sub.add_theme_stylebox_override("panel", st_sub)
	banner_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lbl_sub := _Label_Contorno("SALIR A CORRER 3D", 19, Color.WHITE, Color("#0a1936"), 7)
	lbl_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_sub.add_child(lbl_sub)
	logo_box.add_child(banner_sub)

	# Chip de récord compacto estilo arcade
	var pill_rec := PanelContainer.new()
	pill_rec.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var st_rec := Estilos_UI.caja(Color(0.06, 0.18, 0.40, 0.92), 999, Color("#ffd43b"), 3, 6)
	st_rec.border_width_bottom = 4
	st_rec.content_margin_left = 18.0
	st_rec.content_margin_right = 18.0
	st_rec.content_margin_top = 6.0
	st_rec.content_margin_bottom = 6.0
	pill_rec.add_theme_stylebox_override("panel", st_rec)
	pill_rec.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h_rec := HBoxContainer.new()
	h_rec.add_theme_constant_override("separation", 7)
	h_rec.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill_rec.add_child(h_rec)
	h_rec.add_child(Estilos_UI.icono_rect("trophy", 16, COLOR_ORO))
	_lbl_record_menu = _Texto_Contorno("SIN RÉCORD AÚN", 13, Color("#fde047"), COLOR_TINTA_HUD, 4)
	h_rec.add_child(_lbl_record_menu)
	v.add_child(pill_rec)

	_lbl_stats_menu = _Texto_Contorno("Corre 100 m para entrenar Deporte y mejorar a tu Sim", 11, Color.WHITE, COLOR_TINTA_HUD, 3)
	_lbl_stats_menu.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_lbl_stats_menu)

	# Espacio central completamente despejado para ver al Sim 3D y la pista
	var esp_centro := Control.new()
	esp_centro.size_flags_vertical = Control.SIZE_EXPAND_FILL
	esp_centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(esp_centro)

	# Botón JUGAR estilo Subway Surfers glossy arcade 3D
	var btn_jugar := Estilos_UI.boton("¡JUGAR!", "exito", "play", COLOR_VERDE_BOTON, 72)
	btn_jugar.name = "Boton_Jugar"
	btn_jugar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_jugar.custom_minimum_size = Vector2(300.0, 72.0)
	btn_jugar.add_theme_font_size_override("font_size", 30)
	btn_jugar.add_theme_font_override("font", FUENTE_ARCADE)
	btn_jugar.add_theme_color_override("font_color", Color.WHITE)
	btn_jugar.add_theme_color_override("font_hover_color", Color("#fef08a"))
	btn_jugar.add_theme_color_override("font_pressed_color", Color.WHITE)
	btn_jugar.add_theme_color_override("font_outline_color", Color("#0a2e16"))
	btn_jugar.add_theme_constant_override("outline_size", 8)
	btn_jugar.add_theme_color_override("icon_normal_color", Color.WHITE)
	btn_jugar.add_theme_color_override("icon_hover_color", Color("#fef08a"))
	btn_jugar.add_theme_constant_override("icon_max_width", 28)
	btn_jugar.add_theme_stylebox_override("normal", _Caja_Boton_Gloss(Color("#22c55e"), 22))
	btn_jugar.add_theme_stylebox_override("hover", _Caja_Boton_Gloss(Color("#34d399"), 22))
	var press_j := _Caja_Boton_Gloss(Color("#16a34a"), 22)
	press_j.border_width_bottom = 3
	btn_jugar.add_theme_stylebox_override("pressed", press_j)
	btn_jugar.pressed.connect(_Empezar_Carrera)
	v.add_child(btn_jugar)

	var hint_menu := _Texto_Contorno("Desliza o WASD · ↑/Espacio Saltar · ↓/S Rodar · Doble Toque / E Tabla", 11, Color(1, 1, 1, 0.96), Color("#090d1a"), 4)
	hint_menu.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_menu.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(hint_menu)

	var btn_salir := _Boton_Oscuro("arrow-left", 46)
	btn_salir.name = "Boton_Salir_Menu"
	btn_salir.set_anchors_preset(Control.PRESET_TOP_LEFT)
	btn_salir.offset_left = 16.0
	btn_salir.offset_top = 20.0
	btn_salir.offset_right = 62.0
	btn_salir.offset_bottom = 66.0
	btn_salir.pressed.connect(_Cerrar)
	_menu.add_child(btn_salir)


func _Crear_Modales() -> void:
	# Modal Pausa
	var pausa := _Crear_Modal_Base("PAUSA")
	_modal_pausa = pausa["raiz"] as Control
	var vp := pausa["vbox"] as VBoxContainer
	var tit_p := _Label_Contorno("PAUSA", 34, Color.WHITE, COLOR_TINTA_HUD, 8)
	tit_p.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vp.add_child(tit_p)

	var stats_p := HBoxContainer.new()
	stats_p.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_p.add_theme_constant_override("separation", 10)
	vp.add_child(stats_p)
	var bl_pts := _Bloque_Stat("PUNTOS", "0", Color.WHITE)
	_lbl_pausa_puntos = bl_pts.get_meta("valor") as Label
	stats_p.add_child(bl_pts)
	var bl_mon := _Bloque_Stat("MONEDAS", "0", COLOR_ORO)
	_lbl_pausa_monedas = bl_mon.get_meta("valor") as Label
	stats_p.add_child(bl_mon)

	vp.add_child(_Separador())

	var cab_retos := HBoxContainer.new()
	cab_retos.alignment = BoxContainer.ALIGNMENT_CENTER
	cab_retos.add_theme_constant_override("separation", 6)
	vp.add_child(cab_retos)
	cab_retos.add_child(Estilos_UI.icono_rect("target", 16, COLOR_CIAN))
	cab_retos.add_child(Estilos_UI.texto("RETOS DE LA CARRERA", 11, COLOR_CIAN, 700))
	_vbox_retos_pausa = VBoxContainer.new()
	_vbox_retos_pausa.add_theme_constant_override("separation", 4)
	vp.add_child(_vbox_retos_pausa)

	vp.add_child(_Separador())

	var btn_seguir := Estilos_UI.boton("CONTINUAR", "exito", "play", COLOR_VERDE_BOTON, 56)
	btn_seguir.add_theme_stylebox_override("normal", _Caja_Boton_Gloss(COLOR_VERDE_BOTON, 16))
	btn_seguir.add_theme_stylebox_override("hover", _Caja_Boton_Gloss(COLOR_VERDE_BOTON.lightened(0.08), 16))
	var sp_pr := _Caja_Boton_Gloss(COLOR_VERDE_BOTON.darkened(0.12), 16)
	sp_pr.border_width_bottom = 2
	btn_seguir.add_theme_stylebox_override("pressed", sp_pr)
	btn_seguir.pressed.connect(_Reanudar)
	vp.add_child(btn_seguir)

	var btn_rein := Estilos_UI.boton("REINICIAR", "secundario", "rotate-ccw", COLOR_AZUL_HUD, 50)
	_Aplicar_Boton_Oscuro(btn_rein, COLOR_CIAN)
	btn_rein.pressed.connect(_Reiniciar_Desde_Modal)
	vp.add_child(btn_rein)

	var btn_menu := Estilos_UI.boton("MENÚ", "suave", "house", Color("#cbd5e1"), 46)
	_Aplicar_Boton_Oscuro(btn_menu, Color("#94a3b8"))
	btn_menu.pressed.connect(_Mostrar_Menu)
	vp.add_child(btn_menu)

	var btn_salir := Estilos_UI.boton("SALIR AL HUB", "suave", "arrow-left", Color("#fca5a5"), 46)
	_Aplicar_Boton_Oscuro(btn_salir, Color("#f87171"))
	btn_salir.pressed.connect(_Cerrar)
	vp.add_child(btn_salir)

	# Modal Reanimar (primera gratis, siguientes con llaves)
	var rev := _Crear_Modal_Base("REANIMAR")
	_modal_revive = rev["raiz"] as Control
	var vr := rev["vbox"] as VBoxContainer
	_lbl_revive_tiempo = _Label_Contorno("6", 56, COLOR_ORO, COLOR_TINTA_HUD, 10)
	_lbl_revive_tiempo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vr.add_child(_lbl_revive_tiempo)
	_lbl_revive_titulo = _Label_Contorno("¿CONTINUAR CORRIENDO?", 26, Color.WHITE, COLOR_TINTA_HUD, 7)
	_lbl_revive_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vr.add_child(_lbl_revive_titulo)
	_lbl_revive_coste = Estilos_UI.texto("", 14, COLOR_TEXTO_SUAVE, 500)
	_lbl_revive_coste.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vr.add_child(_lbl_revive_coste)
	vr.add_child(_Separador())
	_btn_revive = Estilos_UI.boton("REANIMAR", "exito", "heart-pulse", COLOR_VERDE_BOTON, 56)
	_btn_revive.add_theme_stylebox_override("normal", _Caja_Boton_Gloss(COLOR_VERDE_BOTON, 16))
	_btn_revive.add_theme_stylebox_override("hover", _Caja_Boton_Gloss(COLOR_VERDE_BOTON.lightened(0.08), 16))
	_btn_revive.pressed.connect(_Reanimar)
	vr.add_child(_btn_revive)
	var btn_final := Estilos_UI.boton("TERMINAR CARRERA", "suave", "x", Color("#fca5a5"), 46)
	_Aplicar_Boton_Oscuro(btn_final, Color("#f87171"))
	btn_final.pressed.connect(_Terminar_Tras_Caida)
	vr.add_child(btn_final)

	# Modal Resultado
	var fin := _Crear_Modal_Base("RESULTADO")
	_modal_fin = fin["raiz"] as Control
	_vbox_fin = fin["vbox"] as VBoxContainer


func _Crear_Capa_Transicion() -> void:
	_aviso = _Label_Contorno("", 24, COLOR_ORO, Color("#0b1220"), 9)
	_aviso.name = "Aviso"
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_aviso.visible = false
	_aviso.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_aviso.z_index = 19
	add_child(_aviso)

	_lbl_cuenta = _Label_Contorno("3", 92, COLOR_ORO, Color("#0b1220"), 14)
	_lbl_cuenta.name = "Cuenta_Atras"
	_lbl_cuenta.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_lbl_cuenta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_cuenta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_lbl_cuenta.visible = false
	_lbl_cuenta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lbl_cuenta.z_index = 21
	add_child(_lbl_cuenta)

	_velo = ColorRect.new()
	_velo.name = "Velo_Transicion"
	_velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_velo.color = Color.BLACK
	_velo.modulate.a = 0.0
	_velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_velo.z_index = 30
	add_child(_velo)


func _Ajustar_A_Tamano() -> void:
	if not is_inside_tree():
		return
	_tam = get_viewport_rect().size
	if _mundo != null and is_instance_valid(_mundo):
		_mundo.configurar_tamano(_tam)
	_aviso.size = Vector2(620.0, 62.0)
	_aviso.position = Vector2(_tam.x * 0.5 - 310.0, _tam.y * 0.20)
	_aviso.pivot_offset = _aviso.size * 0.5


func _Conectar_Mundo() -> void:
	_mundo.moneda_recogida.connect(_on_moneda_recogida)
	_mundo.powerup_recogido.connect(_on_powerup_recogido)
	_mundo.tabla_activada.connect(_on_tabla_activada)
	_mundo.tabla_salvo.connect(_on_tabla_salvo)
	_mundo.tropiezo.connect(_on_tropiezo)
	_mundo.choque.connect(_on_choque)
	_mundo.caido.connect(_on_caido)
	_mundo.revivido.connect(_on_revivido)
	_mundo.llave_recogida.connect(_on_llave_recogida)
	_mundo.caja_abierta.connect(_on_caja_abierta)
	_mundo.mision_completada.connect(_on_mision_completada)
	_mundo.intro_terminada.connect(_on_intro_terminada)
	_mundo.salto_realizado.connect(_on_salto)
	_mundo.deslizamiento_realizado.connect(_on_deslizamiento)
	_mundo.carril_cambiado.connect(_on_carril_cambiado)
	_mundo.aterrizaje.connect(_on_aterrizaje)
	_mundo.paso_dado.connect(_on_paso_dado)
	_mundo.jetpack_iniciado.connect(_on_jetpack_iniciado)
	_mundo.pogo_iniciado.connect(_on_pogo_iniciado)
	_mundo.hito.connect(_on_hito)


# ----------------------------------------------------------------------------
# Flujo del minijuego
# ----------------------------------------------------------------------------

func _Mostrar_Menu() -> void:
	_estado = "menu"
	_tiempo_fin = -1.0
	_menu.visible = true
	_hud.visible = false
	_modal_pausa.visible = false
	_modal_fin.visible = false
	if _modal_revive != null:
		_modal_revive.visible = false
	_revive_activo = false
	_cuenta_activa = false
	if _lbl_cuenta != null:
		_lbl_cuenta.visible = false
	_aviso.visible = false
	_mundo.pausar(false)
	_mundo.iniciar_menu(_Apariencia_Actual())
	_Actualizar_Menu()


func _Empezar_Carrera() -> void:
	if _estado == "jugando" or _estado == "cerrando":
		return
	_estado = "jugando"
	_tiempo_fin = -1.0
	_resumen = {}
	_menu.visible = false
	_modal_pausa.visible = false
	_modal_fin.visible = false
	if _modal_revive != null:
		_modal_revive.visible = false
	_revive_activo = false
	_revive_tiempo = 0.0
	_revives_gratis_usados = 0
	_revives_pagadas = 0
	_cuenta_activa = false
	if _lbl_cuenta != null:
		_lbl_cuenta.visible = false
	_hud.visible = true
	_aviso.visible = false
	_mundo.iniciar(_Apariencia_Actual())
	_mundo.pausar(false)
	_Actualizar_HUD()
	_racha_monedas = 0
	_sonidos.reproducir("start", -10.0)
	_sonidos.reproducir("whistle", -8.0, 1.0)


func _Alternar_Pausa() -> void:
	if _estado == "jugando":
		_estado = "pausa"
		_mundo.pausar(true)
		_aviso.visible = false
		_lbl_pausa_puntos.text = _formatear_numero(_mundo.Obtener_Puntuacion())
		_lbl_pausa_monedas.text = _formatear_numero(_mundo.Obtener_Monedas())
		_Actualizar_Retos_Pausa()
		_modal_pausa.visible = true
		_sonidos.reproducir("click", -14.0)
	elif _estado == "pausa":
		_Reanudar()
	elif _estado == "cuenta":
		_cuenta_activa = false
		if _lbl_cuenta != null:
			_lbl_cuenta.visible = false
		_estado = "pausa"
		_modal_pausa.visible = true
	elif _estado == "menu" or _estado == "fin":
		_Cerrar()


func _Actualizar_Retos_Pausa() -> void:
	if _vbox_retos_pausa == null:
		return
	for hijo in _vbox_retos_pausa.get_children():
		hijo.free()
	for m in _mundo.Obtener_Misiones():
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 6)
		_vbox_retos_pausa.add_child(fila)
		var icono := "check" if bool(m.get("completada", false)) else "target"
		fila.add_child(Estilos_UI.icono_rect(icono, 14, COLOR_VERDE if bool(m.get("completada", false)) else Color("#94a3b8")))
		var texto := Estilos_UI.texto(str(m.get("texto", "")), 12, Color.WHITE if bool(m.get("completada", false)) else COLOR_TEXTO_SUAVE, 600)
		texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(texto)
		var prog := Estilos_UI.texto("%d/%d" % [int(m.get("progreso", 0)), int(m.get("objetivo", 0))], 12, COLOR_ORO, 700)
		fila.add_child(prog)


func _Reanudar() -> void:
	if _estado != "pausa":
		return
	_modal_pausa.visible = false
	_estado = "cuenta"
	_cuenta_activa = true
	_cuenta_paso = 3
	_cuenta_t = 1.0
	_lbl_cuenta.text = "3"
	_lbl_cuenta.visible = true
	_sonidos.reproducir("click", -14.0)


func _Reiniciar_Desde_Modal() -> void:
	if _estado == "cerrando":
		return
	_modal_pausa.visible = false
	_modal_fin.visible = false
	_estado = "menu"
	_Empezar_Carrera()


func _Mostrar_Fin() -> void:
	if _estado != "jugando" and _estado != "revive":
		return
	_estado = "fin"
	_revive_activo = false
	_cuenta_activa = false
	if _lbl_cuenta != null:
		_lbl_cuenta.visible = false
	if _modal_revive != null:
		_modal_revive.visible = false
	_mundo.pausar(true)
	_hud.visible = false
	_aviso.visible = false
	_resumen = Sistema_Correr.Registrar_Carrera(
		_mundo.Obtener_Distancia(),
		_mundo.Obtener_Monedas(),
		true,
		_mundo.Obtener_Puntuacion()
	)
	_Construir_Resultado(_resumen)
	_modal_fin.visible = true
	_modal_fin.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_modal_fin, "modulate:a", 1.0, 0.24)
	_sonidos.reproducir("level_end", -12.0)
	if bool(_resumen.get("nuevo_record", false)):
		_sonidos.reproducir("star", -9.0, 1.15)


func _Cerrar() -> void:
	if _estado == "cerrando":
		return
	_estado = "cerrando"
	_mundo.detener()
	_sonidos.reproducir("click", -12.0)
	Musica.Reproducir_General()
	if _velo_tween != null and _velo_tween.is_valid():
		_velo_tween.kill()
	_velo.modulate.a = 0.0
	_velo_tween = create_tween()
	_velo_tween.tween_property(_velo, "modulate:a", 1.0, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await _velo_tween.finished
	cerrado.emit()


func _process(delta: float) -> void:
	if _estado == "cuenta":
		_cuenta_t = maxf(0.0, _cuenta_t - delta)
		if _cuenta_t <= 0.0:
			_cuenta_paso -= 1
			if _cuenta_paso <= 0:
				_cuenta_activa = false
				_lbl_cuenta.visible = false
				_estado = "jugando"
				_mundo.pausar(false)
				_sonidos.reproducir("swipe", -8.0, 1.15)
				_Mostrar_Aviso("¡SIGUE!", COLOR_VERDE)
			else:
				_lbl_cuenta.text = str(_cuenta_paso)
				_cuenta_t = 1.0
				_sonidos.reproducir("click", -13.0, 1.0 + float(3 - _cuenta_paso) * 0.06)
		return
	if _estado == "revive":
		_revive_tiempo = maxf(0.0, _revive_tiempo - delta)
		if _lbl_revive_tiempo != null:
			_lbl_revive_tiempo.text = str(int(ceil(_revive_tiempo)))
		if _revive_tiempo <= 0.0:
			_Terminar_Tras_Caida()
		return
	if _estado != "jugando":
		return
	if not _mundo.Esta_Vivo():
		if _mundo.Esta_Reanimable() and not _revive_activo:
			_Abrir_Revive()
		elif not _revive_activo:
			if _tiempo_fin < 0.0:
				_tiempo_fin = 0.0
			_tiempo_fin += delta
			if _tiempo_fin >= 0.65:
				_Mostrar_Fin()
		return
	_Actualizar_HUD()


func _Actualizar_HUD() -> void:
	if _lbl_puntuacion == null:
		return
	var pts: int = _mundo.Obtener_Puntuacion()
	_lbl_puntuacion.text = "%06d" % pts
	var mult: int = _mundo.Obtener_Multiplicador()
	_lbl_mult.text = "x%d" % mult
	if mult > 1:
		var st_m2 := Estilos_UI.caja(Color("#f59e0b"), 9, Color("#fef08a"), 2, 0)
		st_m2.border_width_bottom = 3
		st_m2.content_margin_left = 8.0
		st_m2.content_margin_right = 8.0
		st_m2.content_margin_top = 2.0
		st_m2.content_margin_bottom = 2.0
		_badge_mult.add_theme_stylebox_override("panel", st_m2)
		_lbl_mult.add_theme_color_override("font_color", Color.WHITE)
	else:
		var st_m1 := Estilos_UI.caja(Color("#1d7afc"), 9, Color("#7dd3fc"), 2, 0)
		st_m1.border_width_bottom = 3
		st_m1.content_margin_left = 8.0
		st_m1.content_margin_right = 8.0
		st_m1.content_margin_top = 2.0
		st_m1.content_margin_bottom = 2.0
		_badge_mult.add_theme_stylebox_override("panel", st_m1)
		_lbl_mult.add_theme_color_override("font_color", Color.WHITE)

	_lbl_distancia.text = Sistema_Correr.Formatear_Distancia(_mundo.Obtener_Distancia())
	_lbl_monedas.text = str(_mundo.Obtener_Monedas())
	if _lbl_llaves != null:
		_lbl_llaves.text = str(_mundo.Obtener_Llaves())

	var pu: Dictionary = _mundo.Obtener_Powerups()
	for clave in _powerup_widgets.keys():
		var w: Dictionary = _powerup_widgets[clave]
		var rem: float = float(pu.get(clave, 0.0))
		var panel: Control = w["panel"]
		panel.visible = rem > 0.0
		if rem > 0.0:
			(w["bar"] as ProgressBar).value = rem
			(w["lbl"] as Label).text = "%ds" % int(ceil(rem))

	if _pill_mision != null and _lbl_mision != null:
		var mision: Dictionary = _mundo.Obtener_Mision_Actual()
		_pill_mision.visible = not mision.is_empty()
		if not mision.is_empty():
			_lbl_mision.text = "%s  %d/%d" % [
				str(mision.get("texto", "")),
				int(mision.get("progreso", 0)),
				int(mision.get("objetivo", 0)),
			]

	var tabla_activa: bool = float(pu.get("tabla", 0.0)) > 0.0
	var tablas_izq: int = _mundo.Obtener_Tablas_Restantes()
	_lbl_tabla_texto.text = "SURFEANDO" if tabla_activa else "TABLA"
	_lbl_tabla_cant.text = str(tablas_izq)
	_btn_tabla.disabled = tabla_activa or tablas_izq <= 0
	_Aplicar_Estilo_Boton_Tabla(tabla_activa, tablas_izq > 0)

	_badge_techo.visible = _mundo.Esta_En_Techo()
	_badge_tropiezo.visible = _mundo.Esta_Tropezando()


func _Aplicar_Estilo_Boton_Tabla(activa: bool, disponible: bool) -> void:
	if _btn_tabla == null:
		return
	var st: StyleBoxFlat
	if activa:
		st = Estilos_UI.caja(Color("#0ea5e9"), 16, Color("#fef08a"), 3, 6)
		st.border_width_bottom = 5
		_lbl_tabla_texto.add_theme_color_override("font_color", Color.WHITE)
	elif disponible:
		st = Estilos_UI.caja(Color("#154396"), 16, Color("#56ccf2"), 3, 6)
		st.border_width_bottom = 5
		_lbl_tabla_texto.add_theme_color_override("font_color", Color.WHITE)
	else:
		st = Estilos_UI.caja(Color(0.06, 0.14, 0.28, 0.65), 16, Color(1, 1, 1, 0.18), 2, 0)
		_lbl_tabla_texto.add_theme_color_override("font_color", Color("#94a3b8"))
	_btn_tabla.add_theme_stylebox_override("normal", st)
	_btn_tabla.add_theme_stylebox_override("hover", st)
	_btn_tabla.add_theme_stylebox_override("pressed", st)
	_btn_tabla.add_theme_stylebox_override("disabled", st)


func _Actualizar_Menu() -> void:
	var record: int = Sistema_Correr.Obtener_Record_Distancia()
	var mejor_pts: int = Sistema_Correr.Obtener_Record_Puntuacion()
	if record > 0:
		_lbl_record_menu.text = "RÉCORD · %s · %s pts" % [
			Sistema_Correr.Formatear_Distancia(record),
			_formatear_numero(mejor_pts),
		]
	else:
		_lbl_record_menu.text = "SIN RÉCORD TODAVÍA"

	var carreras: int = Sistema_Correr.Obtener_Carreras()
	if carreras <= 0:
		_lbl_stats_menu.text = "Corre 100 m para subir Deporte y mejorar a tu Sim"
	else:
		_lbl_stats_menu.text = "%d %s · %s monedas acumuladas" % [
			carreras,
			"carrera" if carreras == 1 else "carreras",
			_formatear_numero(Sistema_Correr.Obtener_Monedas_Totales()),
		]


func _Mostrar_Aviso(texto: String, color: Color = COLOR_ORO) -> void:
	if _aviso == null:
		return
	if _aviso_tween != null and _aviso_tween.is_valid():
		_aviso_tween.kill()
	_aviso.text = texto
	_aviso.add_theme_color_override("font_color", color)
	_aviso.visible = true
	_aviso.modulate.a = 1.0
	_aviso.scale = Vector2(0.75, 0.75)
	_aviso_tween = create_tween()
	_aviso_tween.set_parallel(true)
	_aviso_tween.tween_property(_aviso, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_aviso_tween.tween_property(_aviso, "modulate:a", 0.0, 0.45).set_delay(0.80)


# ----------------------------------------------------------------------------
# Resultado con recompensa al Sim
# ----------------------------------------------------------------------------

func _Construir_Resultado(resumen: Dictionary) -> void:
	for hijo in _vbox_fin.get_children():
		hijo.free()

	var recompensa: Dictionary = resumen.get("recompensa", {})
	var nuevo_record: bool = bool(resumen.get("nuevo_record", false))
	var valida: bool = bool(recompensa.get("valida", false))

	var titulo_texto: String = "¡NUEVO RÉCORD!" if nuevo_record else ("¡CASI LO TIENES!" if not valida else "¡BUENA CARRERA!")
	var titulo := _Label_Contorno(titulo_texto, 28, COLOR_ORO if nuevo_record else Color.WHITE, Color("#0b1220"), 8)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vbox_fin.add_child(titulo)

	var sub := Estilos_UI.texto(
		"Has superado tu mejor marca en el parque." if nuevo_record else ("Corre al menos 100 m para entrenar de verdad." if not valida else "Buen entrenamiento. ¡Sigue sumando kilómetros!"),
		12, COLOR_TEXTO_SUAVE, 500)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vbox_fin.add_child(sub)

	var pts_lbl := _Label_Contorno(_formatear_numero(int(resumen.get("puntuacion", 0))) + " PTS", 42, COLOR_ORO, Color("#0b1220"), 10)
	pts_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vbox_fin.add_child(pts_lbl)

	var stats := HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 8)
	_vbox_fin.add_child(stats)
	stats.add_child(_Bloque_Stat("DISTANCIA", Sistema_Correr.Formatear_Distancia(float(resumen.get("distancia", 0.0))), COLOR_CIAN))
	stats.add_child(_Bloque_Stat("MONEDAS", _formatear_numero(int(resumen.get("monedas", 0))), COLOR_ORO))
	stats.add_child(_Bloque_Stat("RÉCORD", Sistema_Correr.Formatear_Distancia(float(resumen.get("mejor_distancia", 0.0))), COLOR_VERDE))

	var retos_hechos: int = 0
	for m in _mundo.Obtener_Misiones():
		if bool(m.get("completada", false)):
			retos_hechos += 1
	var lbl_retos := Estilos_UI.texto("Retos completados: %d/3" % retos_hechos, 12, COLOR_CIAN, 600)
	lbl_retos.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vbox_fin.add_child(lbl_retos)

	_vbox_fin.add_child(_Separador())

	if valida:
		var cab := HBoxContainer.new()
		cab.alignment = BoxContainer.ALIGNMENT_CENTER
		cab.add_theme_constant_override("separation", 8)
		_vbox_fin.add_child(cab)
		cab.add_child(Estilos_UI.badge_icono("dumbbell", 30, 15, Color(0.07, 0.32, 0.16, 0.90), COLOR_VERDE, 9))
		cab.add_child(Estilos_UI.texto("RECOMPENSA PARA TU SIM", 11, COLOR_VERDE, 700))

		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 6)
		_vbox_fin.add_child(grid)
		_Anadir_Recompensa(grid, "Deporte +%d" % int(recompensa.get("deporte", 0)), "dumbbell", COLOR_VERDE)
		_Anadir_Recompensa(grid, "Salud física +%d" % int(recompensa.get("salud_fisica", 0)), "heart-pulse", Color("#f87171"))
		_Anadir_Recompensa(grid, "Salud mental +%d" % int(recompensa.get("salud_mental", 0)), "brain", COLOR_CIAN)
		_Anadir_Recompensa(grid, "Hambre −%d" % abs(int(recompensa.get("hambre", 0))), "utensils", Color("#fb923c"))
		_Anadir_Recompensa(grid, "Descanso −%d" % abs(int(recompensa.get("descanso", 0))), "bed-double", Color("#a78bfa"))
		_Anadir_Recompensa(grid, "Higiene −%d" % abs(int(recompensa.get("higiene", 0))), "shower-head", Color("#38bdf8"))
	else:
		var aviso := Estilos_UI.parrafo("Corre al menos 100 m para obtener recompensa de Deporte y necesidades.", 12, COLOR_TEXTO_SUAVE)
		aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_vbox_fin.add_child(aviso)

	_vbox_fin.add_child(_Separador())

	var btn_otra := Estilos_UI.boton("OTRA VEZ", "exito", "rotate-ccw", COLOR_VERDE_BOTON, 56)
	btn_otra.add_theme_font_size_override("font_size", 19)
	btn_otra.add_theme_font_override("font", Estilos_UI.fuente_titulo(700))
	btn_otra.add_theme_stylebox_override("normal", _Caja_Boton_Gloss(COLOR_VERDE_BOTON, 16))
	btn_otra.add_theme_stylebox_override("hover", _Caja_Boton_Gloss(COLOR_VERDE_BOTON.lightened(0.08), 16))
	var otra_p := _Caja_Boton_Gloss(COLOR_VERDE_BOTON.darkened(0.12), 16)
	otra_p.border_width_bottom = 2
	btn_otra.add_theme_stylebox_override("pressed", otra_p)
	btn_otra.pressed.connect(_Reiniciar_Desde_Modal)
	_vbox_fin.add_child(btn_otra)

	var btn_salir := Estilos_UI.boton("SALIR AL HUB", "secundario", "arrow-left", COLOR_AZUL_HUD, 48)
	_Aplicar_Boton_Oscuro(btn_salir, COLOR_CIAN)
	btn_salir.pressed.connect(_Cerrar)
	_vbox_fin.add_child(btn_salir)


# ----------------------------------------------------------------------------
# Señales del mundo 3D
# ----------------------------------------------------------------------------

func _on_moneda_recogida(_total: int, _posicion: Vector3) -> void:
	var ahora: int = Time.get_ticks_msec()
	if ahora - _ultimo_coin_ms > 900:
		_racha_monedas = 0
	else:
		_racha_monedas = mini(_racha_monedas + 1, 18)
	_ultimo_coin_ms = ahora
	var tono := 1.0 + float(_racha_monedas) * 0.024
	_sonidos.reproducir("coin", -8.0, tono)
	if _chip_monedas != null and is_instance_valid(_chip_monedas):
		_chip_monedas.pivot_offset = _chip_monedas.size * 0.5
		_chip_monedas.scale = Vector2(1.13, 1.13)
		var tw := create_tween()
		tw.tween_property(_chip_monedas, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_powerup_recogido(tipo: String, _duracion: float) -> void:
	if tipo != "JETPACK" and tipo != "POGO" and tipo != "LLAVE":
		_sonidos.reproducir("powerup", -7.0, 1.05)
	match tipo:
		"IMAN":
			_Mostrar_Aviso("¡IMÁN DE MONEDAS!", COLOR_ROSA)
		"ZAPATILLAS":
			_Mostrar_Aviso("¡SÚPER ZAPATILLAS!", COLOR_VERDE)
		"MULTIPLICADOR":
			_Mostrar_Aviso("¡PUNTOS x2!", COLOR_ORO)
		"TABLA":
			_sonidos.reproducir("hoverboard", -8.0, 1.1)
			_Mostrar_Aviso("+1 TABLA URBANA", COLOR_CIAN)
		"JETPACK":
			_Mostrar_Aviso("¡JETPACK! VUELA", Color("#fb923c"))
		"POGO":
			_Mostrar_Aviso("¡POGO COHETE!", Color("#a78bfa"))
		"LLAVE":
			pass
		"CAJA":
			_sonidos.reproducir("star", -8.0, 0.95)


func _on_tabla_activada(_restantes: int) -> void:
	_sonidos.reproducir("hoverboard", -6.5, 1.05)
	_Mostrar_Aviso("¡TABLA ACTIVADA!", COLOR_CIAN)


func _on_tabla_salvo() -> void:
	_sonidos.reproducir("shield_break", -5.5, 1.0)
	_Mostrar_Aviso("¡SALVADO POR LA TABLA!", COLOR_CIAN)


func _on_tropiezo() -> void:
	_sonidos.reproducir("stumble", -5.5, 1.0)
	_sonidos.reproducir("whistle", -9.0, 1.12)
	_Mostrar_Aviso("¡TROPIEZO!", Color("#fb923c"))


func _on_choque(_tipo: String) -> void:
	_sonidos.reproducir("crash", -4.5, 1.0)
	_sonidos.reproducir("whistle", -8.0, 0.92)
	if DisplayServer.get_name().to_lower() == "android":
		Input.vibrate_handheld(90)


func _on_caido(_tipo: String) -> void:
	_Abrir_Revive()


func _Coste_Revive() -> int:
	if _revives_gratis_usados <= 0:
		return 0
	return int(pow(2.0, float(_revives_pagadas)))


func _Abrir_Revive() -> void:
	if _revive_activo or _estado == "fin" or _estado == "cerrando":
		return
	_revive_activo = true
	_estado = "revive"
	_revive_tiempo = 6.0
	_mundo.pausar(true)
	_hud.visible = true
	var coste: int = _Coste_Revive()
	var llaves: int = _mundo.Obtener_Llaves()
	_lbl_revive_titulo.text = "¿CONTINUAR CORRIENDO?"
	_lbl_revive_tiempo.text = "6"
	if coste <= 0:
		_lbl_revive_coste.text = "Reanimación gratuita de esta carrera"
		_btn_revive.text = "REANIMAR GRATIS"
		_btn_revive.disabled = false
	else:
		_lbl_revive_coste.text = "Coste: %d %s · Tienes %d" % [coste, "llave" if coste == 1 else "llaves", llaves]
		_btn_revive.text = "USAR %d %s" % [coste, "LLAVE" if coste == 1 else "LLAVES"]
		_btn_revive.disabled = llaves < coste
	_modal_revive.visible = true
	_modal_revive.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_modal_revive, "modulate:a", 1.0, 0.18)
	_sonidos.reproducir("stumble", -9.0, 0.92)


func _Reanimar() -> void:
	if not _revive_activo:
		return
	var coste: int = _Coste_Revive()
	if coste > 0:
		if not _mundo.Gastar_Llaves(coste):
			return
		_revives_pagadas += 1
	else:
		_revives_gratis_usados += 1
	if not _mundo.revivir():
		return
	_revive_activo = false
	_estado = "jugando"
	_tiempo_fin = -1.0
	_modal_revive.visible = false
	_sonidos.reproducir("level_end", -12.0, 1.2)
	_Mostrar_Aviso("¡SIGUE CORRIENDO!", COLOR_VERDE)
	_Actualizar_HUD()


func _Terminar_Tras_Caida() -> void:
	if _estado != "revive" and _estado != "jugando":
		return
	_revive_activo = false
	if _modal_revive != null:
		_modal_revive.visible = false
	_estado = "jugando"
	_Mostrar_Fin()


func _on_revivido() -> void:
	_Actualizar_HUD()


func _on_intro_terminada() -> void:
	_Mostrar_Aviso("¡CORRE!", COLOR_VERDE)
	_sonidos.reproducir("swipe", -8.0, 1.05)


func _on_llave_recogida(total: int) -> void:
	_sonidos.reproducir("key", -7.0, 1.08)
	_Mostrar_Aviso("+1 LLAVE · %d" % total, Color("#c4b5fd"))


func _on_caja_abierta(texto: String) -> void:
	_sonidos.reproducir("powerup", -7.0, 1.18)
	_Mostrar_Aviso("CAJA MISTERIOSA · %s" % texto, COLOR_ORO)


func _on_mision_completada(texto: String) -> void:
	_sonidos.reproducir("star", -6.5, 1.25)
	_Mostrar_Aviso("RETO COMPLETADO · %s" % texto, COLOR_VERDE)


func _on_salto(super_salto: bool) -> void:
	if super_salto:
		_sonidos.reproducir("super_jump", -6.5, 1.04)
	else:
		_sonidos.reproducir("jump", -7.0, 1.02)


func _on_deslizamiento() -> void:
	_sonidos.reproducir("roll", -6.5, 1.0)


func _on_carril_cambiado(direccion: int) -> void:
	var tono: float = 0.96 if direccion < 0 else 1.05
	_sonidos.reproducir("swipe", -7.0, tono)


func _on_aterrizaje() -> void:
	_sonidos.reproducir("land", -9.5, 1.0)


func _on_paso_dado(en_techo: bool) -> void:
	_sonidos.reproducir_paso(en_techo)


func _on_jetpack_iniciado() -> void:
	_sonidos.reproducir("jetpack", -5.5, 1.0)


func _on_pogo_iniciado() -> void:
	_sonidos.reproducir("pogo", -6.0, 1.0)


func _on_hito(distancia_hito: int) -> void:
	_sonidos.reproducir("star", -8.0, 1.1)
	_Mostrar_Aviso("¡%s!" % Sistema_Correr.Formatear_Distancia(float(distancia_hito)), COLOR_ORO)


func _on_pulsar_tabla() -> void:
	if _estado == "jugando":
		_mundo.activar_tabla()


# ----------------------------------------------------------------------------
# Entrada táctil y teclado
# ----------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if _estado != "jugando":
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if _btn_pausa != null and is_instance_valid(_btn_pausa) and _btn_pausa.get_global_rect().has_point(event.position):
				return
			if _btn_tabla != null and is_instance_valid(_btn_tabla) and _btn_tabla.get_global_rect().has_point(event.position):
				return
		_Procesar_Touch(event)
	elif event is InputEventScreenDrag:
		_Procesar_Drag(event)


func _unhandled_input(event: InputEvent) -> void:
	if _estado == "cerrando":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE, KEY_P:
				_Alternar_Pausa()
			KEY_ENTER:
				if _estado == "menu" or _estado == "fin":
					_Reiniciar_Desde_Modal()
			KEY_LEFT, KEY_A:
				if _estado == "jugando":
					_mundo.cambiar_carril(-1)
			KEY_RIGHT, KEY_D:
				if _estado == "jugando":
					_mundo.cambiar_carril(1)
			KEY_UP, KEY_W, KEY_SPACE:
				if _estado == "jugando":
					_mundo.saltar()
				elif _estado == "menu" and event.keycode == KEY_SPACE:
					_Empezar_Carrera()
			KEY_DOWN, KEY_S:
				if _estado == "jugando":
					_mundo.deslizar()
			KEY_E, KEY_H, KEY_SHIFT:
				if _estado == "jugando":
					_mundo.activar_tabla()


func _Procesar_Touch(event: InputEventScreenTouch) -> void:
	if _estado != "jugando":
		_touch_indice = -1
		return
	if event.pressed:
		if _touch_indice == -1:
			_touch_indice = event.index
			_touch_inicio = event.position
			_touch_hecho = false
	elif event.index == _touch_indice:
		var dist: float = (event.position - _touch_inicio).length()
		if not _touch_hecho and dist < 24.0:
			var ahora: int = Time.get_ticks_msec()
			if ahora - _ultimo_tap_ms < 320 and (event.position - _ultimo_tap_pos).length() < 75.0:
				_mundo.activar_tabla()
				_ultimo_tap_ms = 0
			else:
				_ultimo_tap_ms = ahora
				_ultimo_tap_pos = event.position
		_touch_indice = -1
		_touch_hecho = false


func _Procesar_Drag(event: InputEventScreenDrag) -> void:
	if _estado != "jugando" or event.index != _touch_indice or _touch_hecho:
		return
	var delta: Vector2 = event.position - _touch_inicio
	if delta.length() < 30.0:
		return
	if absf(delta.x) > absf(delta.y):
		_mundo.cambiar_carril(1 if delta.x > 0.0 else -1)
	else:
		if delta.y < 0.0:
			_mundo.saltar()
		else:
			_mundo.deslizar()
	_touch_hecho = true


# ----------------------------------------------------------------------------
# Helpers de apariencia y estilos UI
# ----------------------------------------------------------------------------

func _Apariencia_Actual() -> Dictionary:
	var ap: Dictionary = Variables_Estaticas.Apariencia
	if ap.is_empty():
		ap = Apariencia_Personaje.por_defecto()
	return Sistema_Cocina.Obtener_Apariencia_Con_Ropa_Equipada(ap)


func _Bloque_Stat(titulo: String, valor: String, color: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var st := Estilos_UI.caja(Color(color, 0.10), 14, Color(color, 0.30), 1, 0)
	st.content_margin_left = 8.0
	st.content_margin_right = 8.0
	st.content_margin_top = 6.0
	st.content_margin_bottom = 6.0
	p.add_theme_stylebox_override("panel", st)
	p.custom_minimum_size = Vector2(150.0, 0.0)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	p.add_child(v)
	var t := _Texto_Contorno(titulo, 9, Color(0.80, 0.92, 1.0, 0.86), COLOR_TINTA_HUD, 2)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var val := _Label_Contorno(valor, 21, color, COLOR_TINTA_HUD, 5)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(val)
	p.set_meta("valor", val)
	return p


func _Anadir_Recompensa(grid: GridContainer, texto: String, icono: String, color: Color) -> void:
	var p := PanelContainer.new()
	var st := Estilos_UI.caja(Color(color, 0.10), 9, Color(color, 0.22), 1, 0)
	st.content_margin_left = 8.0
	st.content_margin_right = 8.0
	st.content_margin_top = 4.0
	st.content_margin_bottom = 4.0
	p.add_theme_stylebox_override("panel", st)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	p.add_child(h)
	h.add_child(Estilos_UI.icono_rect(icono, 14, color))
	h.add_child(Estilos_UI.texto(texto, 11, Color.WHITE, 600))
	grid.add_child(p)


func _Boton_Oscuro(icono: String, tam: int = 44) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(tam, tam)
	btn.size = Vector2(tam, tam)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.icon = Estilos_UI.icono(icono)
	btn.expand_icon = false
	btn.add_theme_constant_override("icon_max_width", int(tam * 0.44))
	btn.add_theme_color_override("icon_normal_color", Color.WHITE)
	btn.add_theme_color_override("icon_hover_color", Color.WHITE)
	btn.add_theme_color_override("icon_pressed_color", COLOR_ORO)
	var normal := Estilos_UI.caja(Color("#154396"), 15, Color("#56ccf2"), 3, 5)
	normal.border_width_bottom = 5
	var hover := Estilos_UI.caja(Color("#1e56ba"), 15, Color("#93e4ff"), 3, 6)
	hover.border_width_bottom = 5
	var pressed := Estilos_UI.caja(Color("#0e2f6b"), 15, COLOR_ORO, 3, 2)
	pressed.border_width_bottom = 2
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return btn


func _Texto_Contorno(texto: String, tam: int, color: Color, contorno: Color, grosor: int) -> Label:
	var lbl := Estilos_UI.texto(texto, tam, color, 700)
	lbl.add_theme_color_override("font_outline_color", contorno)
	lbl.add_theme_constant_override("outline_size", grosor)
	lbl.add_theme_color_override("font_shadow_color", Color(0.01, 0.04, 0.10, 0.35))
	lbl.add_theme_constant_override("shadow_offset_x", 0)
	lbl.add_theme_constant_override("shadow_offset_y", 2)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl


func _Caja_Boton_Gloss(color: Color, radio: int) -> StyleBoxFlat:
	var st := Estilos_UI.caja(color, radio, color.lightened(0.28), 2, 10)
	st.border_width_bottom = 6
	st.border_color = color.darkened(0.32)
	st.shadow_color = Color(0.01, 0.04, 0.10, 0.36)
	st.shadow_size = 8
	st.shadow_offset = Vector2(0, 4)
	st.content_margin_left = 20.0
	st.content_margin_right = 20.0
	st.content_margin_top = 12.0
	st.content_margin_bottom = 14.0
	st.corner_detail = 12
	return st


func _Aplicar_Boton_Oscuro(btn: Button, acento: Color) -> void:
	var normal := Estilos_UI.caja(Color(0.025, 0.075, 0.16, 0.92), 14, Color(acento, 0.36), 2, 3)
	normal.border_width_bottom = 3
	normal.content_margin_top = 10.0
	normal.content_margin_bottom = 11.0
	var hover := Estilos_UI.caja(Color(0.045, 0.12, 0.24, 0.96), 14, Color(acento, 0.56), 2, 4)
	hover.border_width_bottom = 3
	var pressed := Estilos_UI.caja(Color(0.06, 0.18, 0.32, 0.98), 14, Color(acento, 0.82), 2, 1)
	pressed.border_width_bottom = 1
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", acento)
	btn.add_theme_color_override("icon_normal_color", acento)
	btn.add_theme_color_override("icon_hover_color", Color.WHITE)
	btn.add_theme_color_override("icon_pressed_color", acento)


func _Label_Contorno(texto: String, tam: int, color: Color, contorno: Color, grosor: int) -> Label:
	var lbl := Label.new()
	lbl.text = texto
	lbl.add_theme_font_override("font", FUENTE_ARCADE)
	lbl.add_theme_font_size_override("font_size", tam)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", contorno)
	lbl.add_theme_constant_override("outline_size", grosor)
	lbl.add_theme_color_override("font_shadow_color", Color(0.02, 0.06, 0.16, 0.55))
	lbl.add_theme_constant_override("shadow_offset_x", 0)
	lbl.add_theme_constant_override("shadow_offset_y", 4)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl


func _Crear_Modal_Base(_titulo: String) -> Dictionary:
	var raiz := Control.new()
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_STOP
	raiz.visible = false
	raiz.z_index = 25
	add_child(raiz)

	var fondo := ColorRect.new()
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.color = Color(0.02, 0.05, 0.14, 0.72)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(fondo)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(centro)

	var card := PanelContainer.new()
	card.name = "Card_Modal"
	card.custom_minimum_size = Vector2(560.0, 0.0)
	var st := Estilos_UI.caja(Color("#12397a"), 28, Color("#56ccf2"), 4, 16)
	st.border_width_bottom = 8
	st.shadow_color = Color(0.0, 0.02, 0.08, 0.55)
	st.shadow_offset = Vector2(0, 8)
	card.add_theme_stylebox_override("panel", st)
	centro.add_child(card)

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 24)
	margen.add_theme_constant_override("margin_right", 24)
	margen.add_theme_constant_override("margin_top", 20)
	margen.add_theme_constant_override("margin_bottom", 20)
	card.add_child(margen)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	margen.add_child(v)
	return {"raiz": raiz, "card": card, "vbox": v}


func _Separador() -> ColorRect:
	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0.0, 1.0)
	sep.color = Color(0.72, 0.90, 1.0, 0.18)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return sep


func _formatear_numero(valor: int) -> String:
	var texto: String = str(maxi(0, valor))
	var resultado: String = ""
	var contador: int = 0
	for i in range(texto.length() - 1, -1, -1):
		resultado = texto[i] + resultado
		contador += 1
		if contador == 3 and i > 0:
			resultado = "." + resultado
			contador = 0
	return resultado
