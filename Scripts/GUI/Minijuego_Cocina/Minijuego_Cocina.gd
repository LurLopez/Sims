extends Control

# ============================================================================
# Minijuego de Cocina estilo Cooking Fever (1280x720 Horizontal).
# Mapa de Niveles + Mejoras, Cocina Jugable con ARRASTRAR Y SOLTAR sobre los
# sprites PNG del pack (Imagenes/Minijuego_Cocina) y Modal de Resultados.
# Mantiene el reloj del Sim corriendo en segundo plano.
# ============================================================================

signal cerrado()

const ArteCocina := preload("res://Scripts/GUI/Minijuego_Cocina/Arte_Cocina.gd")
const ArrastreCocina := preload("res://Scripts/GUI/Minijuego_Cocina/Arrastre_Cocina.gd")

const TAMANO_HORIZONTAL := Vector2i(1280, 720)
const TAMANO_VERTICAL := Vector2i(720, 1280)
const VENTANA_COMBO_SEG: float = 2.5
const TIEMPO_BASE_CARNE: float = 4.0
const TIEMPO_BASE_PATATAS: float = 3.6

# Reparto del escenario horizontal (coordenadas locales de Vista_Cocina)
const CENTROS_CLIENTES: Array[float] = [402.0, 636.0, 870.0, 1104.0]
const Y_BASE_CLIENTE: float = 392.0
const ZONA_PLANCHA := Rect2(10.0, 430.0, 246.0, 186.0)
const ZONA_FREIDORA := Rect2(262.0, 430.0, 160.0, 186.0)
const ZONA_REFRESCOS := Rect2(428.0, 430.0, 180.0, 186.0)
const ZONA_PLATOS := Rect2(616.0, 430.0, 400.0, 186.0)
const ZONA_PAPELERA := Rect2(1022.0, 430.0, 94.0, 186.0)
const ZONA_PROPINAS := Rect2(1122.0, 430.0, 150.0, 186.0)
const ZONA_BANDEJA := Rect2(0.0, 622.0, 1280.0, 98.0)

# Estado de navegación y orientación
var _orientacion_aplicada: bool = false
var _restaurante_actual: String = Sistema_Cocina.RESTAURANTE_BURGER
var _nivel_seleccionado: int = 1

# Subvistas y modales principales
var _vista_mapa: Control
var _vista_cocina: Control
var _modal_inicio: Control
var _modal_mejoras: Control
var _modal_resultados: Control
var _capa_feedback: Control

# Referencias UI — Mapa
var _lbl_mapa_rango: Label
var _pill_mapa_turno: PanelContainer
var _lbl_mapa_fondos: Label
var _lbl_mapa_dinero: Label
var _btn_mapa_mejoras: Button
var _hbox_restaurantes: HBoxContainer
var _contenedor_niveles: Control
var _vbox_mejoras_lista: VBoxContainer
var _lbl_mejoras_fondos: Label
var _vbox_modal_inicio: VBoxContainer
var _vbox_modal_resultados: VBoxContainer

# Referencias UI — HUD Cocina
var _lbl_cocina_nivel: Label
var _lbl_cocina_reloj: Label
var _lbl_cocina_recaudacion: Label
var _bar_cocina_meta: ProgressBar
var _estrellas_hud: Array[TextureRect] = []
var _pill_cocina_combo: PanelContainer
var _lbl_cocina_combo: Label
var _pill_cocina_turno: PanelContainer
var _lbl_cocina_reloj_sim: Label
var _lbl_cocina_propinas: Label
var _hud_moneda_icon: TextureRect
var _hud_icono_reloj: TextureRect

# Referencias UI — Clientes y estaciones (sprites PNG)
var _slots_clientes_ui: Array[Dictionary] = []
var _slots_bebidas_ui: Array[Dictionary] = []
var _slots_platos_ui: Array[Dictionary] = []
var _slots_plancha_ui: Array[Dictionary] = []
var _slots_freidora_ui: Array[Dictionary] = []
var _bandeja_items_ui: Array[Dictionary] = []
var _contenedor_plancha: Control
var _contenedor_freidora: Control
var _contenedor_platos: Control
var _contenedor_bebidas: Control
var _lbl_estado_bebidas: Label
var _lbl_estado_plancha: Label
var _lbl_estado_freidora: Label
var _lbl_estado_platos: Label
var _papelera_root: Control
var _papelera_rect: Rect2 = ZONA_PAPELERA
var _propinas_root: Control
var _lbl_estado_propinas: Label
var _chef_root: Control
var _chef_textura: TextureRect
var _chef_burbuja: PanelContainer
var _chef_label: Label
var _chef_tween: Tween
var _banner_servicio: Label
var _banner_tween: Tween
var _anim_tiempo: float = 0.0

# Arrastrar y soltar + efectos
var _arrastre: Arrastre_Cocina
var _efectos: ArteCocina.Capa_Efectos
var _fx_plancha: Array[float] = []
var _fx_freidora: Array[float] = []
var _fx_bebidas: Array[float] = []
var _estrellas_alcanzadas: int = 0

# Estado de partida activa
var _jugando: bool = false
var _nivel_actual: int = 1
var _en_turno_partida: bool = false
var _cfg_nivel_actual: Dictionary = {}
var _tiempo_restante: float = 60.0
var _duracion_nivel: float = 60.0
var _recaudacion: int = 0
var _propinas_servicio: int = 0
var _clientes_atendidos: int = 0
var _combo_actual: int = 0
var _combo_max: int = 0
var _combo_timer: float = 0.0
var _spawn_timer: float = 0.8
var _reloj_sim_refresh: float = 0.0
var _micro_propinas_sesion: float = 0.0
var _cocina_ganada_sesion: int = 0
var _manualidades_ganadas_sesion: int = 0
var _plato_seleccionado: int = -1

# Parámetros calculados al inicio del nivel
var _tiempo_coccion_carne: float = 4.0
var _tiempo_coccion_patatas: float = 3.6
var _tiempo_quemado: float = 6.0
var _aviso_temprano: bool = false
var _velocidad_paciencia: float = 1.0
var _tiempo_bebida: float = 4.0
var _nv_ingredientes: int = 1
var _nv_ambiente: int = 1
var _bonus_ropa_propinas: float = 0.0

# Datos vivos de cocina
var _clientes: Array[Dictionary] = []
var _bebidas: Array[Dictionary] = []
var _platos: Array[Dictionary] = []
var _plancha: Array[Dictionary] = []
var _freidora: Array[Dictionary] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_Aplicar_Orientacion_Horizontal()
	Musica.Reproducir_Minijuego()
	_Construir_Raiz()
	_Centrar_Contenido()
	if get_viewport() != null:
		get_viewport().size_changed.connect(_Centrar_Contenido)
	_Mostrar_Mapa()


func _Centrar_Contenido() -> void:
	var vp: Viewport = get_viewport()
	if vp == null:
		return
	var tam: Vector2 = vp.get_visible_rect().size
	var ox: float = maxf(0.0, (tam.x - 1280.0) * 0.5)
	var oy: float = maxf(0.0, (tam.y - 720.0) * 0.5)
	for nodo in [_vista_mapa, _vista_cocina]:
		if nodo != null and is_instance_valid(nodo):
			nodo.position = Vector2(ox, oy)
			nodo.size = Vector2(1280, 720)


func _exit_tree() -> void:
	Musica.Reproducir_General()
	if _orientacion_aplicada:
		_Restaurar_Orientacion_Vertical()


func _Aplicar_Orientacion_Horizontal() -> void:
	_orientacion_aplicada = true
	if DisplayServer.get_name() != "headless":
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
	var win: Window = get_window()
	if win != null:
		win.content_scale_size = TAMANO_HORIZONTAL
	if OS.has_feature("pc") and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_size(TAMANO_HORIZONTAL)


func _Restaurar_Orientacion_Vertical() -> void:
	_orientacion_aplicada = false
	if DisplayServer.get_name() != "headless":
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	var win: Window = get_window()
	if win != null:
		win.content_scale_size = TAMANO_VERTICAL
	if OS.has_feature("pc") and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_size(TAMANO_VERTICAL)


func _Salir_Al_Sim() -> void:
	_jugando = false
	_Restaurar_Orientacion_Vertical()
	cerrado.emit()


# ============================================================================
# Construcción de escena (1280x720)
# ============================================================================

func _Construir_Raiz() -> void:
	var fondo := ColorRect.new()
	fondo.name = "Fondo_General"
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.color = Color("#f3efe6")
	add_child(fondo)

	_Construir_Vista_Mapa()
	_Construir_Vista_Cocina()
	_Construir_Modal_Inicio()
	_Construir_Modal_Mejoras()
	_Construir_Modal_Resultados()

	_capa_feedback = Control.new()
	_capa_feedback.name = "Capa_Feedback"
	_capa_feedback.set_anchors_preset(Control.PRESET_FULL_RECT)
	_capa_feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_capa_feedback.z_index = 40
	add_child(_capa_feedback)


# ----------------------------------------------------------------------------
# Subvista 1: Mapa de Niveles y Mejoras
# ----------------------------------------------------------------------------

func _Construir_Vista_Mapa() -> void:
	_vista_mapa = Control.new()
	_vista_mapa.name = "Vista_Mapa"
	_vista_mapa.size = Vector2(1280, 720)
	add_child(_vista_mapa)

	# Barra superior (1280 x 68)
	var top := Panel.new()
	top.name = "Mapa_Top_Bar"
	top.position = Vector2.ZERO
	top.size = Vector2(1280, 68)
	var st_top := Estilos_UI.caja(Estilos_UI.NAVY, 0, Color("#2d3a50"), 0, 0)
	st_top.border_width_bottom = 3
	st_top.border_color = Color("#f59e0b")
	top.add_theme_stylebox_override("panel", st_top)
	_vista_mapa.add_child(top)

	var htop := HBoxContainer.new()
	htop.position = Vector2(18, 11)
	htop.size = Vector2(1244, 46)
	htop.add_theme_constant_override("separation", 12)
	top.add_child(htop)

	var btn_volver := Estilos_UI.boton("← Volver al Sim", "secundario", "arrow-left", Estilos_UI.TINTA, 44)
	btn_volver.custom_minimum_size = Vector2(185, 44)
	btn_volver.pressed.connect(_Salir_Al_Sim)
	htop.add_child(btn_volver)

	var tit_box := HBoxContainer.new()
	tit_box.add_theme_constant_override("separation", 10)
	tit_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	htop.add_child(tit_box)

	tit_box.add_child(Estilos_UI.badge_icono("utensils", 38, 19, Color("#ea580c"), Color.WHITE, 10))
	var lbl_tit := Estilos_UI.titulo("Cocina · Cooking Fever", 22, Color.WHITE)
	tit_box.add_child(lbl_tit)

	var pill_rango := PanelContainer.new()
	pill_rango.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var st_rango := Estilos_UI.caja(Color("#24344d"), 999, Color("#f59e0b"), 1, 0)
	st_rango.content_margin_left = 12
	st_rango.content_margin_right = 12
	st_rango.content_margin_top = 4
	st_rango.content_margin_bottom = 4
	pill_rango.add_theme_stylebox_override("panel", st_rango)
	_lbl_mapa_rango = Estilos_UI.texto("Rango 0/9", 12, Color("#fde68a"), 700)
	pill_rango.add_child(_lbl_mapa_rango)
	tit_box.add_child(pill_rango)

	_pill_mapa_turno = Estilos_UI.pill_estado("EN TURNO (+50%)", Estilos_UI.EXITO, Color.WHITE)
	_pill_mapa_turno.visible = false
	htop.add_child(_pill_mapa_turno)

	# Pill Fondos_Cocina
	var pill_fondos := PanelContainer.new()
	pill_fondos.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var st_f := Estilos_UI.caja(Color("#fef3c7"), 999, Color("#d97706"), 1, 0)
	st_f.content_margin_left = 14
	st_f.content_margin_right = 14
	st_f.content_margin_top = 6
	st_f.content_margin_bottom = 6
	pill_fondos.add_theme_stylebox_override("panel", st_f)
	var hf := HBoxContainer.new()
	hf.add_theme_constant_override("separation", 6)
	hf.add_child(Estilos_UI.icono_rect("coins", 16, Color("#b45309")))
	_lbl_mapa_fondos = Estilos_UI.texto("0 Fondos", 14, Color("#92400e"), 700)
	hf.add_child(_lbl_mapa_fondos)
	pill_fondos.add_child(hf)
	htop.add_child(pill_fondos)

	# Pill Dinero del Sim
	var pill_din := PanelContainer.new()
	pill_din.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var st_d := Estilos_UI.caja(Estilos_UI.EXITO_SUAVE, 999, Estilos_UI.EXITO, 1, 0)
	st_d.content_margin_left = 14
	st_d.content_margin_right = 14
	st_d.content_margin_top = 6
	st_d.content_margin_bottom = 6
	pill_din.add_theme_stylebox_override("panel", st_d)
	var hd := HBoxContainer.new()
	hd.add_theme_constant_override("separation", 6)
	hd.add_child(Estilos_UI.icono_rect("euro", 15, Estilos_UI.EXITO_OSCURO))
	_lbl_mapa_dinero = Estilos_UI.texto("0 €", 14, Estilos_UI.EXITO_OSCURO, 700)
	hd.add_child(_lbl_mapa_dinero)
	pill_din.add_child(hd)
	htop.add_child(pill_din)

	_btn_mapa_mejoras = Estilos_UI.boton("Mejoras", "oro", "zap", Estilos_UI.ORO, 44)
	_btn_mapa_mejoras.custom_minimum_size = Vector2(150, 44)
	_btn_mapa_mejoras.pressed.connect(_Abrir_Modal_Mejoras)
	htop.add_child(_btn_mapa_mejoras)

	# Selector de 3 restaurantes (y = 78..142)
	_hbox_restaurantes = HBoxContainer.new()
	_hbox_restaurantes.name = "Selector_Restaurantes"
	_hbox_restaurantes.position = Vector2(20, 78)
	_hbox_restaurantes.size = Vector2(1240, 62)
	_hbox_restaurantes.add_theme_constant_override("separation", 14)
	_vista_mapa.add_child(_hbox_restaurantes)

	# Contenedor mapa de 15 niveles (y = 152..704)
	_contenedor_niveles = Control.new()
	_contenedor_niveles.name = "Contenedor_Niveles"
	_contenedor_niveles.position = Vector2(20, 152)
	_contenedor_niveles.size = Vector2(1240, 552)
	_vista_mapa.add_child(_contenedor_niveles)


func _Mostrar_Mapa() -> void:
	_jugando = false
	if _arrastre != null:
		_arrastre.cancelar()
		_arrastre.habilitado = false
	if _chef_root != null:
		_chef_root.visible = false
	_vista_mapa.visible = true
	_vista_cocina.visible = false
	_modal_inicio.visible = false
	_modal_mejoras.visible = false
	_modal_resultados.visible = false
	_Refrescar_Mapa()


func _Refrescar_Mapa() -> void:
	var rango: int = Sistema_Cocina.Obtener_Rango_Logro()
	var info_rango: Dictionary = Sistema_Cocina.Obtener_Info_Rango(rango)
	_lbl_mapa_rango.text = "Rango %d/9 · %s" % [rango, str(info_rango.get("nombre", ""))]
	_lbl_mapa_fondos.text = "%d Fondos" % Sistema_Cocina.Obtener_Fondos_Cocina()
	_lbl_mapa_dinero.text = "%d €" % int(Variables_Dinamicas.Dinero)
	_pill_mapa_turno.visible = Sistema_Cocina.Esta_En_Turno_Activo(_restaurante_actual)

	var rest_cfg: Dictionary = Sistema_Cocina.Obtener_Restaurante(_restaurante_actual)
	var rest_jugable: bool = bool(rest_cfg.get("implementado", false)) \
		and Sistema_Cocina.Esta_Desbloqueado_Restaurante(_restaurante_actual)
	_btn_mapa_mejoras.disabled = not rest_jugable

	# Selector de 3 restaurantes
	for h in _hbox_restaurantes.get_children():
		h.queue_free()

	for rest_id in Sistema_Cocina.ORDEN_RESTAURANTES:
		var r: Dictionary = Sistema_Cocina.Obtener_Restaurante(rest_id)
		var desbl: bool = Sistema_Cocina.Esta_Desbloqueado_Restaurante(rest_id)
		var impl: bool = bool(r.get("implementado", false))
		var activo: bool = (rest_id == _restaurante_actual)

		var btn := Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 62)
		btn.text = ""
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var bg: Color = Color("#fff7ed") if activo else Estilos_UI.SUPERFICIE
		var borde: Color = Color("#ea580c") if activo else Estilos_UI.BORDE
		var st := Estilos_UI.caja(bg, 14, borde, 2 if activo else 1, 2 if activo else 1)
		st.border_width_bottom = 3
		btn.add_theme_stylebox_override("normal", st)
		btn.add_theme_stylebox_override("hover", st)
		btn.add_theme_stylebox_override("pressed", st)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		btn.pressed.connect(func():
			_restaurante_actual = rest_id
			_Refrescar_Mapa())

		var m := MarginContainer.new()
		m.set_anchors_preset(Control.PRESET_FULL_RECT)
		m.add_theme_constant_override("margin_left", 14)
		m.add_theme_constant_override("margin_right", 14)
		m.add_theme_constant_override("margin_top", 8)
		m.add_theme_constant_override("margin_bottom", 8)
		m.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(m)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		m.add_child(row)

		var ic_nom: String = "utensils" if desbl else "lock"
		var ic_col: Color = Color("#ea580c") if (desbl and impl) else (Estilos_UI.AZUL if desbl else Estilos_UI.TINTA_FANTASMA)
		row.add_child(Estilos_UI.badge_icono(ic_nom, 38, 18, ic_col, Color.WHITE, 10))

		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", 1)
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(col)

		var lbl_n := Estilos_UI.titulo(str(r.get("nombre", rest_id)), 15, Estilos_UI.TINTA)
		lbl_n.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(lbl_n)

		var sub_txt: String
		if desbl and impl:
			sub_txt = "%d / 45 ★ · %d/15 niveles" % [
				Sistema_Cocina.Contar_Estrellas_Totales(rest_id),
				Sistema_Cocina.Contar_Niveles_Superados(rest_id)
			]
		elif desbl and not impl:
			sub_txt = "Desbloqueado · Próximamente (Fase 2)"
		else:
			sub_txt = "Requiere: %s" % str(r.get("trabajo_requerido", ""))
		var lbl_s := Estilos_UI.texto(sub_txt, 12, Estilos_UI.TINTA_SUAVE, 500)
		lbl_s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(lbl_s)

		if Sistema_Cocina.Esta_En_Turno_Activo(rest_id):
			row.add_child(Estilos_UI.pill_estado("TURNO", Estilos_UI.EXITO_SUAVE, Estilos_UI.EXITO_OSCURO))
		elif not impl:
			row.add_child(Estilos_UI.pill_estado("Fase 2", Estilos_UI.AZUL_SUAVE, Estilos_UI.AZUL))

		_hbox_restaurantes.add_child(btn)

	# Mapa de niveles o tarjeta informativa
	for c in _contenedor_niveles.get_children():
		c.queue_free()

	if not rest_jugable:
		_Construir_Tarjeta_Restaurante_No_Jugable(rest_cfg)
		return

	var grid := GridContainer.new()
	grid.name = "Grid_Niveles"
	grid.columns = 5
	grid.position = Vector2.ZERO
	grid.size = _contenedor_niveles.size
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 14)
	_contenedor_niveles.add_child(grid)

	var niveles: Array = rest_cfg.get("niveles", [])
	for n_cfg in niveles:
		var num: int = int(n_cfg.get("nivel", 1))
		var desbl_n: bool = Sistema_Cocina.Esta_Nivel_Desbloqueado(_restaurante_actual, num)
		var est: int = Sistema_Cocina.Obtener_Estrellas_Nivel(_restaurante_actual, num)
		grid.add_child(_Crear_Tarjeta_Nivel(num, n_cfg, desbl_n, est))


func _Crear_Tarjeta_Nivel(num: int, cfg: Dictionary, desbloqueado: bool, estrellas: int) -> Button:
	var btn := Button.new()
	btn.name = "Nivel_%d" % num
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(228, 168)
	btn.disabled = not desbloqueado
	btn.text = ""
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if desbloqueado else Control.CURSOR_ARROW

	var bg: Color = Estilos_UI.SUPERFICIE if desbloqueado else Color("#e5e7eb")
	var borde: Color = Color("#1ea34a") if estrellas >= 3 else (Color("#f59e0b") if estrellas >= 1 else Estilos_UI.BORDE_FUERTE)
	if not desbloqueado:
		borde = Estilos_UI.BORDE
	var st_n := Estilos_UI.caja(bg, 16, borde, 2 if estrellas >= 1 else 1, 2 if desbloqueado else 0)
	st_n.border_width_bottom = 4 if desbloqueado else 2
	var st_h := st_n.duplicate() as StyleBoxFlat
	st_h.bg_color = Color("#fffbeb")
	btn.add_theme_stylebox_override("normal", st_n)
	btn.add_theme_stylebox_override("hover", st_h)
	btn.add_theme_stylebox_override("pressed", st_h)
	btn.add_theme_stylebox_override("disabled", st_n)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	if desbloqueado:
		btn.pressed.connect(_Abrir_Modal_Inicio.bind(num))

	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 14)
	m.add_theme_constant_override("margin_right", 14)
	m.add_theme_constant_override("margin_top", 12)
	m.add_theme_constant_override("margin_bottom", 12)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(m)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 8)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(v)

	var cab := HBoxContainer.new()
	cab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(cab)

	var lbl_num := Estilos_UI.titulo("Nivel %d" % num, 20, Estilos_UI.TINTA if desbloqueado else Estilos_UI.TINTA_FANTASMA)
	lbl_num.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_num.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cab.add_child(lbl_num)

	if not desbloqueado:
		cab.add_child(Estilos_UI.icono_rect("lock", 20, Estilos_UI.TINTA_FANTASMA))
	else:
		cab.add_child(Estilos_UI.pill_estado("%ds" % int(cfg.get("duracion", 60)), Estilos_UI.SUPERFICIE_2, Estilos_UI.TINTA_SUAVE))

	# Fila de 3 estrellas
	var h_est := HBoxContainer.new()
	h_est.alignment = BoxContainer.ALIGNMENT_CENTER
	h_est.add_theme_constant_override("separation", 8)
	h_est.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(h_est)
	for s in range(3):
		var col_s: Color = Color("#f59e0b") if s < estrellas else Color("#cbd5e1")
		h_est.add_child(Estilos_UI.icono_rect("star", 26, col_s))

	var meta_txt: String = "Meta 1★: %d 🪙" % int(cfg.get("meta_1", 50)) if desbloqueado else "Supera Nivel %d" % (num - 1)
	var lbl_meta := Estilos_UI.texto(meta_txt, 13, Estilos_UI.TINTA_SUAVE if desbloqueado else Estilos_UI.TINTA_FANTASMA, 600)
	lbl_meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_meta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(lbl_meta)

	return btn


func _Construir_Tarjeta_Restaurante_No_Jugable(rest_cfg: Dictionary) -> void:
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_contenedor_niveles.add_child(centro)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(680, 320)
	card.add_theme_stylebox_override("panel", Estilos_UI.caja_tarjeta(20, 3))
	centro.add_child(card)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 32)
	m.add_theme_constant_override("margin_right", 32)
	m.add_theme_constant_override("margin_top", 28)
	m.add_theme_constant_override("margin_bottom", 28)
	card.add_child(m)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 14)
	m.add_child(v)

	var rest_id: String = str(rest_cfg.get("id", ""))
	var desbl: bool = Sistema_Cocina.Esta_Desbloqueado_Restaurante(rest_id)
	var impl: bool = bool(rest_cfg.get("implementado", false))

	var ic_box := HBoxContainer.new()
	ic_box.alignment = BoxContainer.ALIGNMENT_CENTER
	ic_box.add_child(Estilos_UI.badge_icono("utensils" if desbl else "lock", 56, 28,
		Estilos_UI.AZUL if desbl else Estilos_UI.TINTA_FANTASMA, Color.WHITE, 16))
	v.add_child(ic_box)

	var t := Estilos_UI.titulo(str(rest_cfg.get("nombre", "")), 26, Estilos_UI.TINTA)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)

	var sub := Estilos_UI.parrafo(str(rest_cfg.get("subtitulo", "")), 16, Estilos_UI.TINTA_SUAVE)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)

	var estado_txt: String
	if desbl and not impl:
		estado_txt = "¡Restaurante desbloqueado por tu empleo! Sus 15 niveles y nuevas recetas llegarán en la Fase 2."
	else:
		estado_txt = "Bloqueado. Trabaja al menos 1 minuto como %s para desbloquear este restaurante." % str(rest_cfg.get("trabajo_requerido", ""))
	var lbl_est := Estilos_UI.parrafo(estado_txt, 15, Estilos_UI.AZUL if desbl else Estilos_UI.ORO)
	lbl_est.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(lbl_est)


# ----------------------------------------------------------------------------
# Modal de Inicio de Nivel
# ----------------------------------------------------------------------------

func _Construir_Modal_Inicio() -> void:
	_modal_inicio = Control.new()
	_modal_inicio.name = "Modal_Inicio_Nivel"
	_modal_inicio.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_inicio.z_index = 25
	_modal_inicio.visible = false
	add_child(_modal_inicio)

	var velo := ColorRect.new()
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	velo.color = Color(0.06, 0.09, 0.15, 0.65)
	_modal_inicio.add_child(velo)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_inicio.add_child(centro)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(680, 0)
	card.add_theme_stylebox_override("panel", Estilos_UI.caja_tarjeta(20, 3))
	centro.add_child(card)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 28)
	m.add_theme_constant_override("margin_right", 28)
	m.add_theme_constant_override("margin_top", 24)
	m.add_theme_constant_override("margin_bottom", 24)
	card.add_child(m)

	_vbox_modal_inicio = VBoxContainer.new()
	_vbox_modal_inicio.add_theme_constant_override("separation", 12)
	m.add_child(_vbox_modal_inicio)


func _Abrir_Modal_Inicio(nivel: int) -> void:
	_nivel_seleccionado = nivel
	var cfg: Dictionary = Sistema_Cocina.Obtener_Config_Nivel(_restaurante_actual, nivel)
	if cfg.is_empty():
		return

	for c in _vbox_modal_inicio.get_children():
		c.queue_free()

	var en_turno: bool = Sistema_Cocina.Esta_En_Turno_Activo(_restaurante_actual)
	var est_prev: int = Sistema_Cocina.Obtener_Estrellas_Nivel(_restaurante_actual, nivel)

	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 10)
	_vbox_modal_inicio.add_child(cab)
	var tit := Estilos_UI.titulo("Nivel %d · %s" % [nivel, Sistema_Cocina.Obtener_Nombre_Restaurante(_restaurante_actual)], 22, Estilos_UI.TINTA)
	tit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(tit)
	cab.add_child(Estilos_UI.pill_estado("%ds" % int(cfg.get("duracion", 60)), Estilos_UI.AZUL_SUAVE, Estilos_UI.AZUL))

	# Objetivos de estrellas
	var metas := HBoxContainer.new()
	metas.add_theme_constant_override("separation", 10)
	_vbox_modal_inicio.add_child(metas)
	for info_m in [
		["1★", int(cfg.get("meta_1", 50)), est_prev >= 1],
		["2★", int(cfg.get("meta_2", 80)), est_prev >= 2],
		["3★", int(cfg.get("meta_3", 110)), est_prev >= 3]
	]:
		var p := PanelContainer.new()
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var st := Estilos_UI.caja(Color("#fef3c7") if info_m[2] else Estilos_UI.SUPERFICIE_2, 12,
			Color("#f59e0b") if info_m[2] else Estilos_UI.BORDE, 1, 0)
		st.content_margin_left = 12
		st.content_margin_right = 12
		st.content_margin_top = 8
		st.content_margin_bottom = 8
		p.add_theme_stylebox_override("panel", st)
		var l := Estilos_UI.texto("%s  %d 🪙" % [info_m[0], info_m[1]], 15, Estilos_UI.TINTA, 700)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		p.add_child(l)
		metas.add_child(p)

	# Menú del servicio
	var menu_lbl := Estilos_UI.texto("Platos del servicio:", 13, Estilos_UI.TINTA_SUAVE, 700)
	_vbox_modal_inicio.add_child(menu_lbl)
	var menu_row := HFlowContainer.new()
	menu_row.add_theme_constant_override("h_separation", 8)
	menu_row.add_theme_constant_override("v_separation", 6)
	_vbox_modal_inicio.add_child(menu_row)
	for plato_id in cfg.get("menu", []):
		var rec: Dictionary = Sistema_Cocina.RECETAS_BURGER_STREET.get(str(plato_id), {})
		var nom: String = str(rec.get("nombre_corto", plato_id))
		menu_row.add_child(Estilos_UI.pill_estado(nom, Color("#ffedd5"), Color("#9a3412")))

	_vbox_modal_inicio.add_child(Estilos_UI.divisor_horizontal())

	# Modificadores del Sim
	var destreza: float = float(Variables_Estaticas.Habilidades[2]) if Variables_Estaticas.Habilidades.size() > 2 else 50.0
	var paciencia: float = float(Variables_Estaticas.Habilidades[5]) if Variables_Estaticas.Habilidades.size() > 5 else 50.0
	var sangre_fria: float = float(Variables_Estaticas.Habilidades[6]) if Variables_Estaticas.Habilidades.size() > 6 else 50.0
	var descanso: float = float(Variables_Dinamicas.Necesidades_Basicas[3]) if Variables_Dinamicas.Necesidades_Basicas.size() > 3 else 50.0
	var mental: float = float(Variables_Dinamicas.Necesidades_Basicas[1]) if Variables_Dinamicas.Necesidades_Basicas.size() > 1 else 50.0
	var resacon: bool = Variables_Dinamicas.Estados_Temporales.has("Resacon")

	var mod_lineas: Array[String] = [
		"• Destreza (%d): velocidad cocción -%.0f%%" % [int(destreza), 15.0 * destreza / 100.0],
		"• Paciencia (%d) y Sangre Fría (%d): mayor margen de quemado y clientes más pacientes" % [int(paciencia), int(sangre_fria)]
	]
	if descanso < 25.0 or mental < 25.0:
		mod_lineas.append("• Aviso fatiga/estrés (<25): la paciencia de clientes baja x1.20 más rápido")
	if resacon:
		mod_lineas.append("• Aviso Resacón: margen de quemado reducido (x0.85)")
	if en_turno:
		mod_lineas.append("• ¡EN TURNO ACTIVO! Fondos x1.5, Progreso x2.0, propinas ilimitadas y +10% nómina hoy")
	else:
		var rest_hoy: int = Sistema_Cocina.Obtener_Servicios_Remunerados_Restantes_Hoy()
		mod_lineas.append("• Modo libre: %d/%d servicios remunerados disponibles hoy" % [rest_hoy, Sistema_Cocina.LIMITE_SERVICIOS_LIBRES_DIA])

	var lbl_mods := Estilos_UI.parrafo("\n".join(mod_lineas), 13, Estilos_UI.TINTA_SUAVE)
	_vbox_modal_inicio.add_child(lbl_mods)

	# Validación de entrada
	var check: Dictionary = Sistema_Cocina.Puede_Entrar_Minijuego()
	var permitido: bool = bool(check.get("permitido", false))
	if not permitido:
		var err := Estilos_UI.parrafo(str(check.get("mensaje", "")), 14, Estilos_UI.PELIGRO)
		_vbox_modal_inicio.add_child(err)

	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 12)
	_vbox_modal_inicio.add_child(btns)

	var btn_cancel := Estilos_UI.boton("Cancelar", "secundario", "", Estilos_UI.TINTA, 48)
	btn_cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_cancel.pressed.connect(func(): _modal_inicio.visible = false)
	btns.add_child(btn_cancel)

	var btn_start := Estilos_UI.boton("¡Empezar Servicio!", "exito", "play", Estilos_UI.EXITO, 48)
	btn_start.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_start.disabled = not permitido
	btn_start.pressed.connect(func():
		_modal_inicio.visible = false
		_Iniciar_Nivel(nivel))
	btns.add_child(btn_start)

	_modal_inicio.visible = true


# ----------------------------------------------------------------------------
# Modal de las 5 Mejoras
# ----------------------------------------------------------------------------

func _Construir_Modal_Mejoras() -> void:
	_modal_mejoras = Control.new()
	_modal_mejoras.name = "Modal_Mejoras"
	_modal_mejoras.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_mejoras.z_index = 25
	_modal_mejoras.visible = false
	add_child(_modal_mejoras)

	var velo := ColorRect.new()
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	velo.color = Color(0.06, 0.09, 0.15, 0.65)
	_modal_mejoras.add_child(velo)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_mejoras.add_child(centro)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(940, 580)
	card.add_theme_stylebox_override("panel", Estilos_UI.caja_tarjeta(20, 3))
	centro.add_child(card)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 24)
	m.add_theme_constant_override("margin_right", 24)
	m.add_theme_constant_override("margin_top", 20)
	m.add_theme_constant_override("margin_bottom", 20)
	card.add_child(m)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	m.add_child(v)

	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 12)
	v.add_child(cab)
	var tit := Estilos_UI.titulo("Mejoras de Cocina", 22, Estilos_UI.TINTA)
	tit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(tit)

	var pill_f := PanelContainer.new()
	var st_f := Estilos_UI.caja(Color("#fef3c7"), 999, Color("#d97706"), 1, 0)
	st_f.content_margin_left = 14
	st_f.content_margin_right = 14
	st_f.content_margin_top = 6
	st_f.content_margin_bottom = 6
	pill_f.add_theme_stylebox_override("panel", st_f)
	_lbl_mejoras_fondos = Estilos_UI.texto("0 Fondos", 14, Color("#92400e"), 700)
	pill_f.add_child(_lbl_mejoras_fondos)
	cab.add_child(pill_f)

	var btn_cerrar := Estilos_UI.boton("Cerrar", "secundario", "x", Estilos_UI.TINTA, 40)
	btn_cerrar.custom_minimum_size = Vector2(115, 40)
	btn_cerrar.pressed.connect(func():
		_modal_mejoras.visible = false
		_Refrescar_Mapa())
	cab.add_child(btn_cerrar)

	v.add_child(Estilos_UI.divisor_horizontal())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)

	_vbox_mejoras_lista = VBoxContainer.new()
	_vbox_mejoras_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vbox_mejoras_lista.add_theme_constant_override("separation", 10)
	scroll.add_child(_vbox_mejoras_lista)


func _Abrir_Modal_Mejoras() -> void:
	_Refrescar_Modal_Mejoras()
	_modal_mejoras.visible = true


func _Refrescar_Modal_Mejoras() -> void:
	var fondos: int = Sistema_Cocina.Obtener_Fondos_Cocina()
	_lbl_mejoras_fondos.text = "%d Fondos" % fondos

	for c in _vbox_mejoras_lista.get_children():
		c.queue_free()

	for mejora_id in Sistema_Cocina.ORDEN_MEJORAS:
		var def: Dictionary = Sistema_Cocina.MEJORAS_DEF[mejora_id]
		var nv: int = Sistema_Cocina.Obtener_Nivel_Mejora(_restaurante_actual, mejora_id)
		var coste: int = Sistema_Cocina.Obtener_Coste_Siguiente_Mejora(_restaurante_actual, mejora_id)

		var fila := PanelContainer.new()
		fila.add_theme_stylebox_override("panel", Estilos_UI.caja(Estilos_UI.SUPERFICIE_2, 14, Estilos_UI.BORDE, 1, 0))
		var fm := MarginContainer.new()
		fm.add_theme_constant_override("margin_left", 16)
		fm.add_theme_constant_override("margin_right", 16)
		fm.add_theme_constant_override("margin_top", 12)
		fm.add_theme_constant_override("margin_bottom", 12)
		fila.add_child(fm)

		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 14)
		fm.add_child(h)

		h.add_child(Estilos_UI.badge_icono(str(def.get("icono", "zap")), 44, 22, Color("#ea580c"), Color.WHITE, 12))

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 3)
		h.add_child(info)

		var top_line := HBoxContainer.new()
		top_line.add_theme_constant_override("separation", 8)
		top_line.add_child(Estilos_UI.titulo(str(def.get("nombre", mejora_id)), 16, Estilos_UI.TINTA))
		top_line.add_child(Estilos_UI.pill_estado("Nv. %d / 3" % nv,
			Estilos_UI.EXITO_SUAVE if nv >= 3 else Estilos_UI.ORO_SUAVE,
			Estilos_UI.EXITO_OSCURO if nv >= 3 else Estilos_UI.ORO))
		info.add_child(top_line)

		var descs: Array = def.get("descripciones", [])
		var actual_txt: String = "Actual: %s" % str(descs[nv - 1])
		info.add_child(Estilos_UI.texto(actual_txt, 13, Estilos_UI.TINTA_SUAVE, 500))
		if nv < 3:
			var sig_txt: String = "Siguiente (Nv.%d): %s" % [nv + 1, str(descs[nv])]
			info.add_child(Estilos_UI.texto(sig_txt, 13, Estilos_UI.EXITO_OSCURO, 700))

		if nv >= 3:
			var pill_max := Estilos_UI.pill_estado("✓ MÁXIMO", Estilos_UI.EXITO_SUAVE, Estilos_UI.EXITO_OSCURO)
			h.add_child(pill_max)
		else:
			var btn_buy := Estilos_UI.boton("Mejorar (%d 🪙)" % coste, "exito", "coins", Estilos_UI.EXITO, 44)
			btn_buy.custom_minimum_size = Vector2(185, 44)
			btn_buy.disabled = fondos < coste
			btn_buy.pressed.connect(func():
				var res: Dictionary = Sistema_Cocina.Comprar_Mejora(_restaurante_actual, mejora_id)
				if bool(res.get("exito", false)):
					_Refrescar_Modal_Mejoras()
					_Refrescar_Mapa())
			h.add_child(btn_buy)

		_vbox_mejoras_lista.add_child(fila)


# ----------------------------------------------------------------------------
# Subvista 2: Cocina Jugable (1280x720) con sprites PNG y arrastrar-y-soltar
# ----------------------------------------------------------------------------

func _Construir_Vista_Cocina() -> void:
	_vista_cocina = Control.new()
	_vista_cocina.name = "Vista_Cocina"
	_vista_cocina.size = Vector2(1280, 720)
	_vista_cocina.visible = false
	_vista_cocina.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vista_cocina)

	var fondo := TextureRect.new()
	fondo.name = "Fondo_Restaurante"
	fondo.texture = ArteCocina.TEX_FONDO
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fondo.stretch_mode = TextureRect.STRETCH_SCALE
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vista_cocina.add_child(fondo)

	# Velo superior para dar contraste al HUD
	var velo := ColorRect.new()
	velo.position = Vector2.ZERO
	velo.size = Vector2(1280, 62)
	velo.color = Color(0.02, 0.05, 0.09, 0.30)
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vista_cocina.add_child(velo)

	_Construir_Zona_Clientes()
	# El chef se dibuja antes del mostrador para que la barra lo tape por delante
	_Construir_Chef_Cutin()
	_Construir_Mostrador()
	_Construir_Bandeja_Ingredientes()
	_Construir_HUD_Cocina()

	# Efectos y capa de arrastre siempre por encima del escenario
	_efectos = ArteCocina.Capa_Efectos.new()
	_efectos.name = "Capa_Efectos"
	_efectos.set_anchors_preset(Control.PRESET_FULL_RECT)
	_efectos.z_index = 20
	_vista_cocina.add_child(_efectos)

	_arrastre = ArrastreCocina.new()
	_arrastre.name = "Capa_Arrastre"
	_arrastre.set_anchors_preset(Control.PRESET_FULL_RECT)
	_arrastre.z_index = 30
	_arrastre.arrastre_iniciado.connect(_on_arrastre_iniciado)
	_arrastre.arrastre_soltado.connect(_on_arrastre_soltado)
	_arrastre.arrastre_cancelado.connect(_on_arrastre_cancelado)
	_arrastre.origen_tocado.connect(_on_origen_tocado)
	_vista_cocina.add_child(_arrastre)

	_banner_servicio = Estilos_UI.titulo("", 46, Color("#fef08a"))
	_banner_servicio.name = "Banner_Servicio"
	_banner_servicio.position = Vector2(0, 250)
	_banner_servicio.size = Vector2(1280, 90)
	_banner_servicio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_servicio.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner_servicio.add_theme_color_override("font_outline_color", Color("#7c2d12"))
	_banner_servicio.add_theme_constant_override("outline_size", 12)
	_banner_servicio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_servicio.z_index = 35
	_banner_servicio.modulate.a = 0.0
	_vista_cocina.add_child(_banner_servicio)


func _Construir_HUD_Cocina() -> void:
	var hud := Panel.new()
	hud.name = "HUD_Cocina"
	hud.position = Vector2.ZERO
	hud.size = Vector2(1280, 58)
	var st := Estilos_UI.caja(Color("#0f172a", 0.94), 0, Color("#facc15"), 0, 0)
	st.border_width_bottom = 3
	st.border_color = Color("#facc15")
	hud.add_theme_stylebox_override("panel", st)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vista_cocina.add_child(hud)

	var fila := HBoxContainer.new()
	fila.position = Vector2(10, 7)
	fila.size = Vector2(1260, 44)
	fila.add_theme_constant_override("separation", 10)
	hud.add_child(fila)

	var btn_mapa := Estilos_UI.boton("Mapa", "secundario", "arrow-left", Estilos_UI.TINTA, 38)
	btn_mapa.custom_minimum_size = Vector2(96, 38)
	btn_mapa.pressed.connect(_Mostrar_Mapa)
	fila.add_child(btn_mapa)

	_lbl_cocina_nivel = Estilos_UI.titulo("Nivel 1", 16, Color("#fef9c3"))
	_lbl_cocina_nivel.custom_minimum_size = Vector2(78, 0)
	_lbl_cocina_nivel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fila.add_child(_lbl_cocina_nivel)

	# Recaudación + barra con las 3 estrellas
	var caja_meta := Control.new()
	caja_meta.custom_minimum_size = Vector2(430, 44)
	caja_meta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(caja_meta)

	_hud_moneda_icon = TextureRect.new()
	_hud_moneda_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hud_moneda_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_hud_moneda_icon.texture = ArteCocina.TEX_MONEDA
	_hud_moneda_icon.position = Vector2(2, 8)
	_hud_moneda_icon.size = Vector2(26, 26)
	_hud_moneda_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja_meta.add_child(_hud_moneda_icon)

	_lbl_cocina_recaudacion = Estilos_UI.texto("0 / 115", 14, Color("#fde68a"), 700)
	_lbl_cocina_recaudacion.position = Vector2(32, 9)
	_lbl_cocina_recaudacion.size = Vector2(120, 24)
	caja_meta.add_child(_lbl_cocina_recaudacion)

	_bar_cocina_meta = ProgressBar.new()
	_bar_cocina_meta.position = Vector2(0, 27)
	_bar_cocina_meta.size = Vector2(300, 14)
	_bar_cocina_meta.show_percentage = false
	_bar_cocina_meta.max_value = 100
	_bar_cocina_meta.add_theme_stylebox_override("background",
		Estilos_UI.caja(Color("#1e293b"), 999, Color("#facc15", 0.65), 1, 0))
	_bar_cocina_meta.add_theme_stylebox_override("fill", Estilos_UI.barra_relleno(Color("#facc15")))
	caja_meta.add_child(_bar_cocina_meta)

	_estrellas_hud.clear()
	for s in range(3):
		var estrella := TextureRect.new()
		estrella.name = "Estrella_HUD_%d" % (s + 1)
		estrella.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		estrella.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		estrella.texture = ArteCocina.TEX_ESTRELLA_VACIA
		estrella.size = Vector2(20, 20)
		estrella.position = Vector2(300.0 * (float(s + 1) / 3.0) - 10.0, 24.0)
		estrella.mouse_filter = Control.MOUSE_FILTER_IGNORE
		caja_meta.add_child(estrella)
		_estrellas_hud.append(estrella)

	# Reloj de servicio
	var pill_reloj := PanelContainer.new()
	var st_rel := Estilos_UI.caja(Color("#0b1220", 0.85), 10, Color("#38bdf8"), 2, 0)
	st_rel.content_margin_left = 8
	st_rel.content_margin_right = 10
	st_rel.content_margin_top = 3
	st_rel.content_margin_bottom = 3
	pill_reloj.add_theme_stylebox_override("panel", st_rel)
	var hr := HBoxContainer.new()
	hr.add_theme_constant_override("separation", 5)
	_hud_icono_reloj = TextureRect.new()
	_hud_icono_reloj.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hud_icono_reloj.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_hud_icono_reloj.texture = ArteCocina.TEX_RELOJ
	_hud_icono_reloj.custom_minimum_size = Vector2(22, 22)
	hr.add_child(_hud_icono_reloj)
	_lbl_cocina_reloj = Estilos_UI.titulo("01:00", 17, Color.WHITE)
	hr.add_child(_lbl_cocina_reloj)
	pill_reloj.add_child(hr)
	fila.add_child(pill_reloj)

	# Propinas de la partida
	var pill_prop := PanelContainer.new()
	var st_prop := Estilos_UI.caja(Color("#451a03", 0.85), 10, Color("#fbbf24"), 1, 0)
	st_prop.content_margin_left = 8
	st_prop.content_margin_right = 10
	st_prop.content_margin_top = 3
	st_prop.content_margin_bottom = 3
	pill_prop.add_theme_stylebox_override("panel", st_prop)
	var hp := HBoxContainer.new()
	hp.add_theme_constant_override("separation", 5)
	var ic_prop := TextureRect.new()
	ic_prop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic_prop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic_prop.texture = ArteCocina.TEX_BOTE_PROPINAS
	ic_prop.custom_minimum_size = Vector2(20, 20)
	hp.add_child(ic_prop)
	_lbl_cocina_propinas = Estilos_UI.texto("+0", 13, Color("#fde68a"), 700)
	hp.add_child(_lbl_cocina_propinas)
	pill_prop.add_child(hp)
	fila.add_child(pill_prop)

	_pill_cocina_combo = Estilos_UI.pill_estado("COMBO x2", Color("#dc2626"), Color("#fef08a"))
	_pill_cocina_combo.visible = false
	fila.add_child(_pill_cocina_combo)
	_lbl_cocina_combo = _pill_cocina_combo.get_child(0) as Label

	_pill_cocina_turno = Estilos_UI.pill_estado("EN TURNO +50%", Estilos_UI.EXITO, Color.WHITE)
	_pill_cocina_turno.visible = false
	fila.add_child(_pill_cocina_turno)

	var esp := Control.new()
	esp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(esp)

	_lbl_cocina_reloj_sim = Estilos_UI.texto("Lun 08:00", 12, Color("#dcfce7"), 700)
	_lbl_cocina_reloj_sim.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fila.add_child(_lbl_cocina_reloj_sim)


func _Crear_Etiqueta_Estacion(x: float, y: float, ancho: float, texto: String) -> Label:
	var pill := PanelContainer.new()
	pill.position = Vector2(x, y)
	pill.size = Vector2(ancho, 19)
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := Estilos_UI.caja(Color("#0f172a", 0.78), 999, Color("#fbbf24", 0.55), 1, 0)
	st.content_margin_left = 4
	st.content_margin_right = 4
	st.content_margin_top = 1
	st.content_margin_bottom = 1
	pill.add_theme_stylebox_override("panel", st)
	var lbl := Estilos_UI.texto(texto, 10, Color("#fde68a"), 700)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(lbl)
	_vista_cocina.add_child(pill)
	return lbl


func _Construir_Zona_Clientes() -> void:
	_slots_clientes_ui.clear()
	for i in range(CENTROS_CLIENTES.size()):
		var slot_ui: Dictionary = _Crear_Slot_Cliente_UI(i)
		_slots_clientes_ui.append(slot_ui)


func _Crear_Slot_Cliente_UI(indice: int) -> Dictionary:
	var cx: float = CENTROS_CLIENTES[indice]

	var retrato := ArteCocina.Retrato.new()
	retrato.name = "Retrato_Cliente_%d" % indice
	retrato.variante = indice
	retrato.position = Vector2(cx - 95.0, Y_BASE_CLIENTE - 170.0)
	retrato.size = Vector2(190.0, 170.0)
	retrato.visible = false
	_vista_cocina.add_child(retrato)

	var ticket := ArteCocina.Ticket.new()
	ticket.name = "Ticket_Pedido_%d" % indice
	ticket.position = Vector2(cx - 60.0, 56.0)
	ticket.size = Vector2(120.0, 164.0)
	ticket.visible = false
	_vista_cocina.add_child(ticket)

	return {
		"root": retrato,
		"retrato": retrato,
		"ticket": ticket,
		"centro": Vector2(cx, Y_BASE_CLIENTE - 10.0),
		"pos_retrato": retrato.position,
		"pos_ticket": ticket.position,
		"visible_antes": false,
		"tween": null,
		"destacado": false,
	}


func _Construir_Mostrador() -> void:
	_lbl_estado_plancha = _Crear_Etiqueta_Estacion(ZONA_PLANCHA.position.x, 407.0,
		ZONA_PLANCHA.size.x, "PLANCHA")
	_lbl_estado_freidora = _Crear_Etiqueta_Estacion(ZONA_FREIDORA.position.x, 407.0,
		ZONA_FREIDORA.size.x, "FREIDORA")
	_lbl_estado_bebidas = _Crear_Etiqueta_Estacion(ZONA_REFRESCOS.position.x, 407.0,
		ZONA_REFRESCOS.size.x, "REFRESCOS")
	_lbl_estado_platos = _Crear_Etiqueta_Estacion(ZONA_PLATOS.position.x, 407.0,
		ZONA_PLATOS.size.x, "EMPLATADO")
	_Crear_Etiqueta_Estacion(ZONA_PAPELERA.position.x, 407.0, ZONA_PAPELERA.size.x, "BASURA")
	_Crear_Etiqueta_Estacion(ZONA_PROPINAS.position.x, 407.0, ZONA_PROPINAS.size.x, "PROPINAS")

	# Plancha (4 fogones)
	_Anadir_Textura(ArteCocina.TEX_PLANCHA, Rect2(14.0, 438.0, 238.0, 178.0), "Estacion_Plancha")
	# Freidora (2 cestas)
	_Anadir_Textura(ArteCocina.TEX_FREIDORA, Rect2(266.0, 452.0, 150.0, 143.0), "Estacion_Freidora")
	# Dispensador de refrescos
	_Anadir_Textura(ArteCocina.TEX_REFRESCOS, Rect2(432.0, 432.0, 150.0, 180.0), "Estacion_Refrescos")

	# Bandeja metálica de emplatado
	_Anadir_Textura(ArteCocina.TEX_BANDEJA, Rect2(624.0, 520.0, 384.0, 84.0), "Bandeja_Emplatado")

	# Papelera
	_papelera_root = Control.new()
	_papelera_root.name = "Papelera"
	_papelera_root.position = Vector2(1026.0, 480.0)
	_papelera_root.size = Vector2(86.0, 120.0)
	_papelera_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex_papelera := TextureRect.new()
	tex_papelera.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_papelera.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_papelera.texture = ArteCocina.TEX_PAPELERA
	tex_papelera.set_anchors_preset(Control.PRESET_FULL_RECT)
	tex_papelera.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_papelera_root.add_child(tex_papelera)
	_vista_cocina.add_child(_papelera_root)
	_papelera_rect = Rect2(1014.0, 400.0, 108.0, 216.0)

	# Bote de propinas + monedas
	_propinas_root = Control.new()
	_propinas_root.name = "Propinas"
	_propinas_root.position = Vector2(1124.0, 500.0)
	_propinas_root.size = Vector2(146.0, 110.0)
	_propinas_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex_bote := TextureRect.new()
	tex_bote.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_bote.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_bote.texture = ArteCocina.TEX_BOTE_PROPINAS
	tex_bote.position = Vector2(0.0, 8.0)
	tex_bote.size = Vector2(64.0, 64.0)
	tex_bote.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_propinas_root.add_child(tex_bote)
	var tex_pila := TextureRect.new()
	tex_pila.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_pila.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_pila.texture = ArteCocina.TEX_PILA_MONEDAS
	tex_pila.position = Vector2(62.0, 27.0)
	tex_pila.size = Vector2(84.0, 74.0)
	tex_pila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_propinas_root.add_child(tex_pila)
	_lbl_estado_propinas = Estilos_UI.texto("0 🪙", 14, Color("#fde68a"), 700)
	_lbl_estado_propinas.position = Vector2(58.0, 84.0)
	_lbl_estado_propinas.size = Vector2(90.0, 22.0)
	_lbl_estado_propinas.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_propinas_root.add_child(_lbl_estado_propinas)
	_vista_cocina.add_child(_propinas_root)

	# Contenedores dinámicos (se vacían en cada nivel)
	_contenedor_plancha = _Crear_Contenedor_Dinamico("Contenedor_Plancha")
	_contenedor_freidora = _Crear_Contenedor_Dinamico("Contenedor_Freidora")
	_contenedor_bebidas = _Crear_Contenedor_Dinamico("Contenedor_Bebidas")
	_contenedor_platos = _Crear_Contenedor_Dinamico("Contenedor_Platos")


func _Crear_Contenedor_Dinamico(nombre: String) -> Control:
	var c := Control.new()
	c.name = nombre
	c.size = Vector2(1280, 720)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vista_cocina.add_child(c)
	return c


func _Anadir_Textura(tex: Texture2D, rect: Rect2, nombre: String) -> TextureRect:
	var t := TextureRect.new()
	t.name = nombre
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.texture = tex
	t.position = rect.position
	t.size = rect.size
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vista_cocina.add_child(t)
	return t


func _Construir_Bandeja_Ingredientes() -> void:
	var panel := Panel.new()
	panel.name = "Bandeja_Ingredientes"
	panel.position = ZONA_BANDEJA.position
	panel.size = ZONA_BANDEJA.size
	var st := Estilos_UI.caja(Color("#2b1a0e", 0.97), 0, Color("#92400e"), 0, 0)
	st.border_width_top = 4
	st.border_color = Color("#92400e")
	panel.add_theme_stylebox_override("panel", st)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vista_cocina.add_child(panel)

	var ingredientes: Array[String] = ["pan", "carne", "queso", "lechuga", "tomate", "patatas"]
	var ancho: float = 186.0
	var sep: float = 14.0
	var total: float = ancho * float(ingredientes.size()) + sep * float(ingredientes.size() - 1)
	var x0: float = (1280.0 - total) * 0.5
	_bandeja_items_ui.clear()
	for i in range(ingredientes.size()):
		var ing: String = ingredientes[i]
		var item := ArteCocina.Bandeja_Item.new()
		item.name = "Ingrediente_%s" % ing
		item.ingrediente = ing
		item.textura = ArteCocina.textura_item(ing)
		item.position = Vector2(x0 + float(i) * (ancho + sep), 8.0)
		item.size = Vector2(ancho, 84.0)
		panel.add_child(item)
		_bandeja_items_ui.append({
			"nodo": item,
			"ingrediente": ing,
			"rect": Rect2(Vector2(item.position.x, ZONA_BANDEJA.position.y + item.position.y), item.size),
		})

	var hint := Estilos_UI.texto("ARRASTRA LOS INGREDIENTES HASTA LA PLANCHA, EL PLATO O EL CLIENTE",
		10, Color(1.0, 1.0, 1.0, 0.38), 700)
	hint.position = Vector2(0, 622.0)
	hint.size = Vector2(1280, 8)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vista_cocina.add_child(hint)


func _Construir_Chef_Cutin() -> void:
	_chef_root = Control.new()
	_chef_root.name = "Chef_Cutin"
	_chef_root.position = Vector2(6.0, 119.0)
	_chef_root.size = Vector2(270.0, 330.0)
	_chef_root.visible = false
	_chef_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chef_root.z_index = 15
	_vista_cocina.add_child(_chef_root)

	_chef_textura = TextureRect.new()
	_chef_textura.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_chef_textura.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_chef_textura.texture = ArteCocina.textura_chef("pulgar")
	_chef_textura.position = Vector2(22.0, 56.0)
	_chef_textura.size = Vector2(210.0, 255.0)
	_chef_textura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chef_root.add_child(_chef_textura)

	_chef_burbuja = PanelContainer.new()
	_chef_burbuja.name = "Bocadillo_Chef"
	_chef_burbuja.position = Vector2(4.0, 0.0)
	_chef_burbuja.size = Vector2(250.0, 54.0)
	_chef_burbuja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chef_burbuja.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Color("#fff7ed"), 14, Color("#c2410c"), 2, 0))
	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 10)
	margen.add_theme_constant_override("margin_right", 10)
	margen.add_theme_constant_override("margin_top", 6)
	margen.add_theme_constant_override("margin_bottom", 6)
	margen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chef_burbuja.add_child(margen)
	_chef_label = Estilos_UI.titulo("¡BUEN TRABAJO!", 15, Color("#9a3412"))
	_chef_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chef_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_chef_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_chef_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margen.add_child(_chef_label)
	_chef_root.add_child(_chef_burbuja)


# ----------------------------------------------------------------------------
# Subvista 3: Modal de Resultados del Servicio
# ----------------------------------------------------------------------------

func _Construir_Modal_Resultados() -> void:
	_modal_resultados = Control.new()
	_modal_resultados.name = "Modal_Resultados"
	_modal_resultados.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_resultados.z_index = 30
	_modal_resultados.visible = false
	add_child(_modal_resultados)

	var velo := ColorRect.new()
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	velo.color = Color(0.06, 0.09, 0.15, 0.72)
	_modal_resultados.add_child(velo)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_resultados.add_child(centro)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(720, 0)
	card.add_theme_stylebox_override("panel", Estilos_UI.caja_tarjeta(20, 3))
	centro.add_child(card)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 28)
	m.add_theme_constant_override("margin_right", 28)
	m.add_theme_constant_override("margin_top", 22)
	m.add_theme_constant_override("margin_bottom", 22)
	card.add_child(m)

	_vbox_modal_resultados = VBoxContainer.new()
	_vbox_modal_resultados.add_theme_constant_override("separation", 10)
	m.add_child(_vbox_modal_resultados)


# ============================================================================
# Inicio de Nivel y Construcción de Estaciones según Mejoras
# ============================================================================

func _Iniciar_Nivel(nivel: int) -> void:
	var cfg: Dictionary = Sistema_Cocina.Obtener_Config_Nivel(_restaurante_actual, nivel)
	if cfg.is_empty():
		return

	_nivel_actual = nivel
	_cfg_nivel_actual = cfg
	_en_turno_partida = Sistema_Cocina.Esta_En_Turno_Activo(_restaurante_actual)
	_duracion_nivel = float(cfg.get("duracion", 60))
	_tiempo_restante = _duracion_nivel
	_recaudacion = 0
	_propinas_servicio = 0
	_clientes_atendidos = 0
	_combo_actual = 0
	_combo_max = 0
	_combo_timer = 0.0
	_spawn_timer = 1.2
	_micro_propinas_sesion = 0.0
	_cocina_ganada_sesion = 0
	_manualidades_ganadas_sesion = 0
	_plato_seleccionado = -1
	_anim_tiempo = 0.0
	_estrellas_alcanzadas = 0
	_fx_plancha.clear()
	_fx_freidora.clear()
	_fx_bebidas.clear()

	if _arrastre != null:
		_arrastre.cancelar()
		_arrastre.habilitado = true
	if _efectos != null:
		_efectos.limpiar()
	if _chef_root != null:
		_chef_root.visible = false
	if _chef_tween != null:
		_chef_tween.kill()

	# Parámetros del Sim y mejoras
	var nv_plancha: int = Sistema_Cocina.Obtener_Nivel_Mejora(_restaurante_actual, "plancha")
	var nv_emplatado: int = Sistema_Cocina.Obtener_Nivel_Mejora(_restaurante_actual, "emplatado")
	var nv_termostato: int = Sistema_Cocina.Obtener_Nivel_Mejora(_restaurante_actual, "termostato")
	_nv_ingredientes = Sistema_Cocina.Obtener_Nivel_Mejora(_restaurante_actual, "ingredientes")
	_nv_ambiente = Sistema_Cocina.Obtener_Nivel_Mejora(_restaurante_actual, "ambiente")

	var destreza: float = float(Variables_Estaticas.Habilidades[2]) if Variables_Estaticas.Habilidades.size() > 2 else 50.0
	var paciencia: float = float(Variables_Estaticas.Habilidades[5]) if Variables_Estaticas.Habilidades.size() > 5 else 50.0
	var sangre_fria: float = float(Variables_Estaticas.Habilidades[6]) if Variables_Estaticas.Habilidades.size() > 6 else 50.0
	var descanso: float = float(Variables_Dinamicas.Necesidades_Basicas[3]) if Variables_Dinamicas.Necesidades_Basicas.size() > 3 else 50.0
	var mental: float = float(Variables_Dinamicas.Necesidades_Basicas[1]) if Variables_Dinamicas.Necesidades_Basicas.size() > 1 else 50.0
	var resacon: bool = Variables_Dinamicas.Estados_Temporales.has("Resacon")

	_tiempo_coccion_carne = Sistema_Cocina.Calcular_Tiempo_Coccion(TIEMPO_BASE_CARNE, nv_plancha, destreza)
	_tiempo_coccion_patatas = Sistema_Cocina.Calcular_Tiempo_Coccion(TIEMPO_BASE_PATATAS, nv_plancha, destreza)
	_tiempo_quemado = Sistema_Cocina.Calcular_Tiempo_Quemado(nv_termostato, paciencia, resacon)
	_aviso_temprano = Sistema_Cocina.Tiene_Aviso_Temprano_Termostato(nv_termostato)
	_velocidad_paciencia = Sistema_Cocina.Calcular_Velocidad_Paciencia(_nv_ambiente, paciencia, sangre_fria, descanso, mental)
	_tiempo_bebida = Sistema_Cocina.Obtener_Tiempo_Bebida(nv_emplatado)
	_bonus_ropa_propinas = Sistema_Cocina.Obtener_Bonus_Propinas_Ropa()

	# Reiniciar clientes
	_clientes.clear()
	for i in range(4):
		_clientes.append({
			"activo": false, "items": [], "entregados": [],
			"paciencia": 0.0, "paciencia_max": 25.0, "precio_total": 0,
			"variante": i % 8
		})

	# Construir estaciones dinámicas según mejoras
	_Reconstruir_Estaciones(
		Sistema_Cocina.Obtener_Capacidad_Bebidas(nv_emplatado),
		Sistema_Cocina.Obtener_Huecos_Platos(nv_emplatado),
		Sistema_Cocina.Obtener_Huecos_Plancha(nv_plancha),
		Sistema_Cocina.Obtener_Cestas_Freidora(nv_plancha)
	)

	# Configurar HUD inicial
	_lbl_cocina_nivel.text = "Nivel %d" % nivel
	_pill_cocina_turno.visible = _en_turno_partida
	_pill_cocina_combo.visible = false
	_lbl_cocina_propinas.text = "+0"
	var meta_3: int = maxi(1, int(cfg.get("meta_3", 115)))
	_bar_cocina_meta.max_value = float(meta_3)
	_bar_cocina_meta.value = 0.0
	var m1: float = float(cfg.get("meta_1", 55)) / float(meta_3)
	var m2: float = float(cfg.get("meta_2", 85)) / float(meta_3)
	var ancho_bar: float = _bar_cocina_meta.size.x
	_estrellas_hud[0].position.x = clampf(ancho_bar * m1 - 11.0, 0.0, ancho_bar - 22.0)
	_estrellas_hud[1].position.x = clampf(ancho_bar * m2 - 11.0, 22.0, ancho_bar - 22.0)
	_estrellas_hud[2].position.x = ancho_bar - 22.0
	for estrella in _estrellas_hud:
		estrella.texture = ArteCocina.TEX_ESTRELLA_VACIA
		estrella.scale = Vector2.ONE

	_vista_mapa.visible = false
	_modal_resultados.visible = false
	_vista_cocina.visible = true
	_jugando = true

	_Actualizar_HUD_Cocina()
	_Actualizar_Todas_Las_Estaciones_UI()
	_Actualizar_Todos_Los_Clientes_UI()
	_Registrar_Zonas_Arrastre()
	_Mostrar_Banner("¡A COCINAR!", Color("#fef08a"))
	_Mostrar_Chef("sirviendo", "¡Arrastra los ingredientes!", Color("#9a3412"), 2.4)


func _Reconstruir_Estaciones(num_bebidas: int, num_platos: int, num_plancha: int, num_freidora: int) -> void:
	# --- Refrescos -----------------------------------------------------------
	for c in _contenedor_bebidas.get_children():
		c.queue_free()
	_bebidas.clear()
	_slots_bebidas_ui.clear()
	_fx_bebidas.clear()
	var sep_beb: float = 50.0
	var total_beb: float = 44.0 + sep_beb * float(maxi(0, num_bebidas - 1))
	var x0_beb: float = 505.0 - total_beb * 0.5
	for i in range(num_bebidas):
		_bebidas.append({"estado": "listo", "progreso": 1.0})
		_fx_bebidas.append(0.0)
		var nodo := ArteCocina.Bebida.new()
		nodo.name = "Bebida_%d" % i
		nodo.position = Vector2(x0_beb + sep_beb * float(i), 548.0)
		nodo.size = Vector2(44.0, 68.0)
		_contenedor_bebidas.add_child(nodo)
		_slots_bebidas_ui.append({
			"nodo": nodo,
			"rect": Rect2(nodo.position, nodo.size),
		})

	# --- Platos --------------------------------------------------------------
	for c in _contenedor_platos.get_children():
		c.queue_free()
	_platos.clear()
	_slots_platos_ui.clear()
	var ancho_plato: float = 94.0
	var total_pl: float = ancho_plato * float(num_platos) + 2.0 * float(maxi(0, num_platos - 1))
	var x0_pl: float = ZONA_PLATOS.position.x + (ZONA_PLATOS.size.x - total_pl) * 0.5
	for i in range(num_platos):
		_platos.append({"pan": false, "carnes": 0, "queso": false, "lechuga": false, "tomate": false})
		var nodo := ArteCocina.Plato.new()
		nodo.name = "Plato_%d" % i
		nodo.position = Vector2(x0_pl + float(i) * (ancho_plato + 2.0), 492.0)
		nodo.size = Vector2(ancho_plato, 116.0)
		_contenedor_platos.add_child(nodo)
		_slots_platos_ui.append({
			"nodo": nodo,
			"rect": Rect2(nodo.position, nodo.size),
			"pop": 0.0,
		})

	# --- Plancha -------------------------------------------------------------
	for c in _contenedor_plancha.get_children():
		c.queue_free()
	_plancha.clear()
	_slots_plancha_ui.clear()
	_fx_plancha.clear()
	var centros_fogones: Array[Vector2] = [
		Vector2(97.0, 474.0), Vector2(181.0, 474.0),
		Vector2(95.0, 509.0), Vector2(178.0, 509.0)
	]
	for i in range(num_plancha):
		_plancha.append({"estado": "vacio", "progreso": 0.0, "quemado": 0.0})
		_fx_plancha.append(0.0)
		var nodo := ArteCocina.Punto_Coccion.new()
		nodo.name = "Carne_%d" % i
		nodo.tipo = "carne"
		var centro: Vector2 = centros_fogones[i % centros_fogones.size()]
		nodo.position = centro - Vector2(32.0, 26.0)
		nodo.size = Vector2(64.0, 52.0)
		_contenedor_plancha.add_child(nodo)
		_slots_plancha_ui.append({
			"nodo": nodo,
			"rect": Rect2(nodo.position, nodo.size),
		})

	# --- Freidora ------------------------------------------------------------
	for c in _contenedor_freidora.get_children():
		c.queue_free()
	_freidora.clear()
	_slots_freidora_ui.clear()
	_fx_freidora.clear()
	var centros_cestas: Array[Vector2] = [Vector2(315.0, 520.0), Vector2(366.0, 520.0)]
	for i in range(num_freidora):
		_freidora.append({"estado": "vacio", "progreso": 0.0, "quemado": 0.0})
		_fx_freidora.append(0.0)
		var nodo := ArteCocina.Punto_Coccion.new()
		nodo.name = "Patatas_%d" % i
		nodo.tipo = "patatas"
		var centro: Vector2 = centros_cestas[i % centros_cestas.size()]
		if num_freidora == 1:
			centro = Vector2(341.0, 520.0)
		nodo.position = centro - Vector2(29.0, 24.0)
		nodo.size = Vector2(58.0, 48.0)
		_contenedor_freidora.add_child(nodo)
		_slots_freidora_ui.append({
			"nodo": nodo,
			"rect": Rect2(nodo.position, nodo.size),
		})

	# Etiquetas con capacidades
	_lbl_estado_plancha.text = "PLANCHA · %d fogones" % num_plancha
	_lbl_estado_freidora.text = "FREIDORA · %d cesta%s" % [num_freidora, "" if num_freidora == 1 else "s"]
	_lbl_estado_bebidas.text = "REFRESCOS · %d vaso%s" % [num_bebidas, "" if num_bebidas == 1 else "s"]
	_lbl_estado_platos.text = "EMPLATADO · %d platos" % num_platos


func _Crear_Slot_Coccion_UI(etiqueta: String, _indice: int, _callback: Callable) -> Dictionary:
	var nodo := ArteCocina.Punto_Coccion.new()
	nodo.tipo = "patatas" if etiqueta == "Patatas" else "carne"
	nodo.size = Vector2(58.0, 48.0)
	return {"nodo": nodo}


# ============================================================================
# Registro de zonas de arrastrar y soltar
# ============================================================================

func _Registrar_Zonas_Arrastre() -> void:
	if _arrastre == null:
		return
	_arrastre.limpiar_registros()

	for item in _bandeja_items_ui:
		_arrastre.registrar_origen(item["rect"], {
			"tipo": "bandeja", "ingrediente": item["ingrediente"]
		}, _Obtener_Payload_Bandeja)

	for i in range(_slots_plancha_ui.size()):
		_arrastre.registrar_origen(_slots_plancha_ui[i]["rect"],
			{"tipo": "plancha", "indice": i}, _Obtener_Payload_Plancha)

	for i in range(_slots_freidora_ui.size()):
		_arrastre.registrar_origen(_slots_freidora_ui[i]["rect"],
			{"tipo": "freidora", "indice": i}, _Obtener_Payload_Freidora)

	for i in range(_slots_bebidas_ui.size()):
		_arrastre.registrar_origen(_slots_bebidas_ui[i]["rect"],
			{"tipo": "bebida", "indice": i}, _Obtener_Payload_Bebida)

	for i in range(_slots_platos_ui.size()):
		_arrastre.registrar_origen(_slots_platos_ui[i]["rect"],
			{"tipo": "plato", "indice": i}, _Obtener_Payload_Plato)

	# Destinos
	_arrastre.registrar_destino(ZONA_PLANCHA, {"tipo": "plancha"}, _Acepta_Plancha)
	_arrastre.registrar_destino(ZONA_FREIDORA, {"tipo": "freidora"}, _Acepta_Freidora)
	for i in range(_slots_platos_ui.size()):
		var idx_plato: int = i
		_arrastre.registrar_destino(_slots_platos_ui[i]["rect"],
			{"tipo": "plato", "indice": i},
			func(payload: Dictionary) -> bool: return _Puede_Anadir_A_Plato(payload, idx_plato))
	for i in range(CENTROS_CLIENTES.size()):
		var cx: float = CENTROS_CLIENTES[i]
		var idx_cliente: int = i
		_arrastre.registrar_destino(Rect2(cx - 100.0, 200.0, 200.0, 200.0),
			{"tipo": "cliente", "indice": i},
			func(payload: Dictionary) -> bool: return _Puede_Servir_A_Cliente(payload, idx_cliente))
	_arrastre.registrar_destino(_papelera_rect, {"tipo": "papelera"}, _Acepta_Papelera)


func _Obtener_Payload_Bandeja(datos: Dictionary) -> Dictionary:
	if not _jugando:
		return {}
	var ing: String = str(datos.get("ingrediente", ""))
	if ing == "":
		return {}
	var tex: Texture2D = ArteCocina.textura_item(ing)
	var dibujante := func(c: CanvasItem, centro: Vector2) -> void:
		ArteCocina.dibujar_tex(c, tex, Rect2(centro - Vector2(48.0, 48.0), Vector2(96.0, 96.0)))
	return {
		"payload": {"tipo": "ingrediente", "id": ing},
		"textura": tex,
		"dibujar": dibujante,
		"tam": Vector2(96.0, 96.0),
	}


func _Obtener_Payload_Plancha(datos: Dictionary) -> Dictionary:
	var i: int = int(datos.get("indice", -1))
	if i < 0 or i >= _plancha.size():
		return {}
	var est: String = str(_plancha[i]["estado"])
	if est == "vacio":
		return {}
	if est == "cocinando":
		_Mostrar_Feedback_En_Control(_slots_plancha_ui[i]["nodo"], "Todavía se está haciendo", Estilos_UI.AVISO)
		return {}
	var tex: Texture2D = ArteCocina.TEX_CARNE_QUEMADA if est == "quemado" else ArteCocina.TEX_CARNE_HECHA
	var dibujante := func(c: CanvasItem, centro: Vector2) -> void:
		ArteCocina.dibujar_tex(c, tex, Rect2(centro - Vector2(48.0, 32.0), Vector2(96.0, 64.0)))
	return {
		"payload": {
			"tipo": "carne_quemada" if est == "quemado" else "carne_lista",
			"indice": i,
		},
		"textura": tex,
		"dibujar": dibujante,
		"tam": Vector2(96.0, 64.0),
	}


func _Obtener_Payload_Freidora(datos: Dictionary) -> Dictionary:
	var i: int = int(datos.get("indice", -1))
	if i < 0 or i >= _freidora.size():
		return {}
	var est: String = str(_freidora[i]["estado"])
	if est == "vacio":
		return {}
	if est == "cocinando":
		_Mostrar_Feedback_En_Control(_slots_freidora_ui[i]["nodo"], "Todavía se están friendo", Estilos_UI.AVISO)
		return {}
	var dibujante := func(c: CanvasItem, centro: Vector2) -> void:
		ArteCocina.dibujar_tex(c, ArteCocina.TEX_PATATAS,
			Rect2(centro - Vector2(40.0, 40.0), Vector2(80.0, 80.0)))
	return {
		"payload": {
			"tipo": "patatas_quemadas" if est == "quemado" else "patatas_listas",
			"indice": i,
		},
		"textura": ArteCocina.TEX_PATATAS,
		"dibujar": dibujante,
		"tam": Vector2(80.0, 80.0),
	}


func _Obtener_Payload_Bebida(datos: Dictionary) -> Dictionary:
	var i: int = int(datos.get("indice", -1))
	if i < 0 or i >= _bebidas.size():
		return {}
	if str(_bebidas[i]["estado"]) != "listo":
		_Mostrar_Feedback_En_Control(_slots_bebidas_ui[i]["nodo"], "Se está llenando", Estilos_UI.AVISO)
		return {}
	var dibujante := func(c: CanvasItem, centro: Vector2) -> void:
		ArteCocina.dibujar_tex(c, ArteCocina.TEX_REFRESCO,
			Rect2(centro - Vector2(34.0, 54.0), Vector2(68.0, 108.0)))
	return {
		"payload": {"tipo": "bebida", "indice": i},
		"textura": ArteCocina.TEX_REFRESCO,
		"dibujar": dibujante,
		"tam": Vector2(68.0, 108.0),
	}


func _Obtener_Payload_Plato(datos: Dictionary) -> Dictionary:
	var i: int = int(datos.get("indice", -1))
	if i < 0 or i >= _platos.size():
		return {}
	var p: Dictionary = _platos[i]
	if not bool(p["pan"]):
		_Mostrar_Feedback_En_Control(_slots_platos_ui[i]["nodo"], "Plato vacío", Estilos_UI.TINTA_SUAVE)
		return {}
	var estado_plato: Dictionary = p.duplicate()
	var receta: String = _Receta_De_Plato(p)
	var dibujante := func(c: CanvasItem, centro: Vector2) -> void:
		ArteCocina.dibujar_plato_hamburguesa(c, centro, 118.0,
			bool(estado_plato["pan"]), int(estado_plato["carnes"]),
			bool(estado_plato["queso"]), bool(estado_plato["lechuga"]),
			bool(estado_plato["tomate"]))
	return {
		"payload": {"tipo": "plato", "indice": i, "receta": receta},
		"textura": ArteCocina.TEX_PLATO,
		"dibujar": dibujante,
		"tam": Vector2(100.0, 100.0),
	}


func _Acepta_Plancha(payload: Dictionary) -> bool:
	if str(payload.get("tipo", "")) != "ingrediente" or str(payload.get("id", "")) != "carne":
		return false
	for s in _plancha:
		if str(s["estado"]) == "vacio":
			return true
	return false


func _Acepta_Freidora(payload: Dictionary) -> bool:
	if str(payload.get("tipo", "")) != "ingrediente" or str(payload.get("id", "")) != "patatas":
		return false
	for s in _freidora:
		if str(s["estado"]) == "vacio":
			return true
	return false


func _Puede_Anadir_A_Plato(payload: Dictionary, indice: int) -> bool:
	if indice < 0 or indice >= _platos.size():
		return false
	var p: Dictionary = _platos[indice]
	match str(payload.get("tipo", "")):
		"ingrediente":
			var ing: String = str(payload.get("id", ""))
			if ing == "pan":
				return not bool(p["pan"])
			if ing in ["queso", "lechuga", "tomate"]:
				return bool(p["pan"]) and not bool(p[ing])
			return false
		"carne_lista":
			return bool(p["pan"]) and int(p["carnes"]) < 2
	return false


func _Puede_Servir_A_Cliente(payload: Dictionary, indice: int) -> bool:
	if indice < 0 or indice >= _clientes.size():
		return false
	var cl: Dictionary = _clientes[indice]
	if not bool(cl["activo"]):
		return false
	match str(payload.get("tipo", "")):
		"plato":
			var rec: String = str(payload.get("receta", ""))
			return rec != "" and _Cliente_Necesita_Item(cl, rec)
		"patatas_listas":
			return _Cliente_Necesita_Item(cl, "patatas")
		"bebida":
			return _Cliente_Necesita_Item(cl, "refresco")
	return false


func _Acepta_Papelera(_payload: Dictionary) -> bool:
	return true


# ============================================================================
# Acciones al soltar (drag & drop)
# ============================================================================

func _on_arrastre_iniciado(_payload: Dictionary, _origen: Dictionary) -> void:
	pass


func _on_arrastre_cancelado(_payload: Dictionary) -> void:
	pass


func _on_origen_tocado(payload: Dictionary, origen: Dictionary) -> void:
	if not _jugando:
		return
	var nodo: Control = null
	if origen.has("datos"):
		var d: Dictionary = origen["datos"]
		match str(d.get("tipo", "")):
			"bandeja":
				for item in _bandeja_items_ui:
					if str(item["ingrediente"]) == str(d.get("ingrediente", "")):
						nodo = item["nodo"]
						break
			"plancha":
				nodo = _slots_plancha_ui[int(d.get("indice", 0))]["nodo"]
			"freidora":
				nodo = _slots_freidora_ui[int(d.get("indice", 0))]["nodo"]
			"bebida":
				nodo = _slots_bebidas_ui[int(d.get("indice", 0))]["nodo"]
			"plato":
				nodo = _slots_platos_ui[int(d.get("indice", 0))]["nodo"]
	if nodo != null:
		var pista: String = str(payload.get("pista", "Mantén pulsado y arrastra"))
		_Mostrar_Feedback_En_Control(nodo, pista, Color("#fde68a"), -12.0)


func _on_arrastre_soltado(payload: Dictionary, destino: Dictionary, _pos: Vector2) -> void:
	_Aplicar_Soltar(payload, destino)


func _Aplicar_Soltar(payload: Dictionary, destino: Dictionary) -> bool:
	if not _jugando:
		return false
	if destino.is_empty():
		return false
	var datos: Dictionary = destino.get("datos", {})
	if not bool(destino.get("aceptado", false)):
		_Mostrar_Rechazo(payload, destino)
		return false
	match str(datos.get("tipo", "")):
		"plancha":
			return _Soltar_En_Plancha(payload)
		"freidora":
			return _Soltar_En_Freidora(payload)
		"plato":
			return _Soltar_En_Plato(payload, int(datos.get("indice", -1)))
		"cliente":
			return _Soltar_En_Cliente(payload, int(datos.get("indice", -1)))
		"papelera":
			return _Soltar_En_Papelera(payload)
	return false


func _Depositar_Payload(payload: Dictionary, pos: Vector2) -> bool:
	if _arrastre == null:
		return false
	var destino: Dictionary = _arrastre.resolver_destino(pos, payload)
	return _Aplicar_Soltar(payload, destino)


func _Soltar_En_Plancha(payload: Dictionary) -> bool:
	if str(payload.get("tipo", "")) != "ingrediente" or str(payload.get("id", "")) != "carne":
		return false
	for i in range(_plancha.size()):
		if str(_plancha[i]["estado"]) == "vacio":
			_plancha[i]["estado"] = "cocinando"
			_plancha[i]["progreso"] = 0.0
			_plancha[i]["quemado"] = 0.0
			_Actualizar_Slot_Coccion_UI(_plancha[i], _slots_plancha_ui[i], "Carne")
			_efectos.vapor(Vector2(_slots_plancha_ui[i]["rect"].get_center().x,
				_slots_plancha_ui[i]["rect"].get_center().y - 10.0))
			_Mostrar_Feedback_En_Control(_slots_plancha_ui[i]["nodo"], "¡A la plancha!", Color("#fdba74"), -8.0)
			return true
	_Mostrar_Feedback_En_Control(_slots_plancha_ui[0]["nodo"], "Plancha llena", Estilos_UI.AVISO)
	return false


func _Soltar_En_Freidora(payload: Dictionary) -> bool:
	if str(payload.get("tipo", "")) != "ingrediente" or str(payload.get("id", "")) != "patatas":
		return false
	for i in range(_freidora.size()):
		if str(_freidora[i]["estado"]) == "vacio":
			_freidora[i]["estado"] = "cocinando"
			_freidora[i]["progreso"] = 0.0
			_freidora[i]["quemado"] = 0.0
			_Actualizar_Slot_Coccion_UI(_freidora[i], _slots_freidora_ui[i], "Patatas")
			_Mostrar_Feedback_En_Control(_slots_freidora_ui[i]["nodo"], "¡A freír!", Color("#fdba74"), -8.0)
			return true
	_Mostrar_Feedback_En_Control(_slots_freidora_ui[0]["nodo"], "Freidora llena", Estilos_UI.AVISO)
	return false


func _Soltar_En_Plato(payload: Dictionary, indice: int) -> bool:
	if indice < 0 or indice >= _platos.size():
		return false
	if not _Puede_Anadir_A_Plato(payload, indice):
		return false
	var p: Dictionary = _platos[indice]
	var tipo: String = str(payload.get("tipo", ""))
	var mensaje: String = ""

	if tipo == "ingrediente":
		var ing: String = str(payload.get("id", ""))
		if ing == "pan":
			p["pan"] = true
			mensaje = "Pan colocado"
		elif ing in ["queso", "lechuga", "tomate"]:
			p[ing] = true
			mensaje = "%s añadido" % str(ArteCocina.NOMBRES_INGREDIENTES.get(ing, ing))
		else:
			return false
	elif tipo == "carne_lista":
		var idx_plancha: int = int(payload.get("indice", -1))
		if idx_plancha < 0 or idx_plancha >= _plancha.size():
			return false
		p["carnes"] = int(p["carnes"]) + 1
		_plancha[idx_plancha]["estado"] = "vacio"
		_plancha[idx_plancha]["progreso"] = 0.0
		_plancha[idx_plancha]["quemado"] = 0.0
		_Actualizar_Slot_Coccion_UI(_plancha[idx_plancha], _slots_plancha_ui[idx_plancha], "Carne")
		mensaje = "Carne añadida"
	else:
		return false

	_plato_seleccionado = indice
	_slots_platos_ui[indice]["pop"] = 1.0
	_Actualizar_Plato_UI(indice)
	var receta: String = _Receta_De_Plato(p)
	if receta != "":
		_efectos.estrellas(_slots_platos_ui[indice]["rect"].get_center(), 4)
		if _Algun_Cliente_Necesita(receta):
			mensaje = "%s · ¡llévalo al cliente!" % str(Sistema_Cocina.RECETAS_BURGER_STREET.get(receta, {}).get("nombre_corto", "Listo"))
	if mensaje != "":
		_Mostrar_Feedback_En_Control(_slots_platos_ui[indice]["nodo"], mensaje, Color("#86efac"), -10.0)
	return true


func _Soltar_En_Cliente(payload: Dictionary, indice: int) -> bool:
	if indice < 0 or indice >= _clientes.size():
		return false
	var cl: Dictionary = _clientes[indice]
	if not bool(cl["activo"]):
		return false

	var item_id: String = ""
	var limpiar_plato: bool = false
	var limpiar_freidora: int = -1
	var limpiar_bebida: int = -1
	match str(payload.get("tipo", "")):
		"plato":
			item_id = str(payload.get("receta", ""))
			limpiar_plato = true
		"patatas_listas":
			item_id = "patatas"
			limpiar_freidora = int(payload.get("indice", -1))
		"bebida":
			item_id = "refresco"
			limpiar_bebida = int(payload.get("indice", -1))
		_:
			return false

	if item_id == "":
		_Mostrar_Feedback_En_Control(_slots_clientes_ui[indice]["retrato"], "Ese plato está incompleto", Estilos_UI.AVISO)
		return false
	if not _Cliente_Necesita_Item(cl, item_id):
		_Mostrar_Feedback_En_Control(_slots_clientes_ui[indice]["retrato"], "No lo ha pedido", Estilos_UI.AVISO)
		return false

	if not _Entregar_Item_A_Cliente(indice, item_id):
		return false

	if limpiar_plato:
		var idx_plato: int = int(payload.get("indice", -1))
		if idx_plato >= 0 and idx_plato < _platos.size():
			_Limpiar_Plato(idx_plato)
	if limpiar_freidora >= 0 and limpiar_freidora < _freidora.size():
		_freidora[limpiar_freidora]["estado"] = "vacio"
		_freidora[limpiar_freidora]["progreso"] = 0.0
		_freidora[limpiar_freidora]["quemado"] = 0.0
		_Actualizar_Slot_Coccion_UI(_freidora[limpiar_freidora], _slots_freidora_ui[limpiar_freidora], "Patatas")
	if limpiar_bebida >= 0 and limpiar_bebida < _bebidas.size():
		_bebidas[limpiar_bebida]["estado"] = "llenando"
		_bebidas[limpiar_bebida]["progreso"] = 0.0
		_Actualizar_Bebida_UI(limpiar_bebida)
	return true


func _Soltar_En_Papelera(payload: Dictionary) -> bool:
	match str(payload.get("tipo", "")):
		"plato":
			var idx: int = int(payload.get("indice", -1))
			if idx >= 0 and idx < _platos.size():
				_Limpiar_Plato(idx)
		"carne_lista", "carne_quemada":
			var idx_c: int = int(payload.get("indice", -1))
			if idx_c >= 0 and idx_c < _plancha.size():
				_plancha[idx_c]["estado"] = "vacio"
				_plancha[idx_c]["progreso"] = 0.0
				_plancha[idx_c]["quemado"] = 0.0
				_Actualizar_Slot_Coccion_UI(_plancha[idx_c], _slots_plancha_ui[idx_c], "Carne")
		"patatas_listas", "patatas_quemadas":
			var idx_f: int = int(payload.get("indice", -1))
			if idx_f >= 0 and idx_f < _freidora.size():
				_freidora[idx_f]["estado"] = "vacio"
				_freidora[idx_f]["progreso"] = 0.0
				_freidora[idx_f]["quemado"] = 0.0
				_Actualizar_Slot_Coccion_UI(_freidora[idx_f], _slots_freidora_ui[idx_f], "Patatas")
		"bebida":
			var idx_b: int = int(payload.get("indice", -1))
			if idx_b >= 0 and idx_b < _bebidas.size():
				_bebidas[idx_b]["estado"] = "llenando"
				_bebidas[idx_b]["progreso"] = 0.0
				_Actualizar_Bebida_UI(idx_b)
		_:
			pass
	_efectos.humo(_papelera_rect.get_center())
	_Mostrar_Feedback_En_Control(_papelera_root, "Descartado", Estilos_UI.TINTA_SUAVE, -10.0)
	return true


func _Mostrar_Rechazo(payload: Dictionary, destino: Dictionary) -> void:
	var datos: Dictionary = destino.get("datos", {})
	var tipo: String = str(datos.get("tipo", ""))
	var mensaje: String = "Ahí no va eso"
	match tipo:
		"plancha":
			mensaje = "Solo carne cruda en la plancha"
			if str(payload.get("tipo", "")) == "ingrediente" and str(payload.get("id", "")) == "carne":
				mensaje = "La plancha está llena"
		"freidora":
			mensaje = "Solo patatas en la freidora"
			if str(payload.get("tipo", "")) == "ingrediente" and str(payload.get("id", "")) == "patatas":
				mensaje = "La freidora está llena"
		"plato":
			var idx: int = int(datos.get("indice", -1))
			if str(payload.get("tipo", "")) == "ingrediente":
				var ing: String = str(payload.get("id", ""))
				if ing != "pan" and idx >= 0 and idx < _platos.size() and not bool(_platos[idx]["pan"]):
					mensaje = "Pon pan primero"
				elif ing == "pan":
					mensaje = "Ese plato ya tiene pan"
				else:
					mensaje = "Ese plato ya lo tiene"
			elif str(payload.get("tipo", "")) == "carne_lista":
				mensaje = "Pon pan o ya tiene 2 carnes"
			else:
				mensaje = "Eso no va en el plato"
		"cliente":
			var idx_cl: int = int(datos.get("indice", -1))
			var cliente_activo: bool = idx_cl >= 0 and idx_cl < _clientes.size() \
				and bool(_clientes[idx_cl]["activo"])
			if not cliente_activo:
				mensaje = "Ese cliente ya no está"
			elif str(payload.get("tipo", "")) == "plato" \
					and str(payload.get("receta", "")) == "":
				mensaje = "Ese plato está incompleto"
			else:
				mensaje = "Ese cliente no lo pidió"
		"papelera":
			mensaje = "Eso no se puede tirar"
	if destino.has("rect"):
		var rect: Rect2 = destino["rect"]
		_Mostrar_Feedback_En_Posicion(rect.get_center(), mensaje, Estilos_UI.AVISO)
	else:
		_Mostrar_Feedback_En_Posicion(Vector2(640.0, 400.0), mensaje, Estilos_UI.AVISO)


# ============================================================================
# Bucle en tiempo real de cocina (_process) — O(1), sin llamadas a save_game()
# ============================================================================

func _process(delta: float) -> void:
	if not _jugando:
		return

	_anim_tiempo += delta
	_tiempo_restante = maxf(0.0, _tiempo_restante - delta)
	if _combo_timer > 0.0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			_combo_actual = 0

	# Spawn de clientes
	if _tiempo_restante > 4.0:
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:
			if _Intentar_Spawnear_Cliente():
				var base_int: float = float(_cfg_nivel_actual.get("intervalo_spawn", 5.0))
				_spawn_timer = randf_range(base_int * 0.85, base_int * 1.15)
			else:
				_spawn_timer = 1.0

	# Paciencia de clientes
	for i in range(_clientes.size()):
		var cl: Dictionary = _clientes[i]
		if not bool(cl["activo"]):
			continue
		cl["paciencia"] = float(cl["paciencia"]) - delta * _velocidad_paciencia
		if float(cl["paciencia"]) <= 0.0:
			cl["activo"] = false
			_combo_actual = 0
			_combo_timer = 0.0
			_Mostrar_Feedback_En_Control(_slots_clientes_ui[i]["retrato"], "¡Cliente molesto!", Estilos_UI.PELIGRO)
			_efectos.enfado(_slots_clientes_ui[i]["centro"], 4)
			_Mostrar_Chef("enfadada", "¡Se ha marchado sin comer!", Estilos_UI.PELIGRO, 1.5)
			_Actualizar_Cliente_UI(i)
		else:
			_Actualizar_Paciencia_Cliente_UI(i)

	# Cocción en plancha y freidora
	_Tick_Slots_Coccion(_plancha, _slots_plancha_ui, _tiempo_coccion_carne, "Carne", delta)
	_Tick_Slots_Coccion(_freidora, _slots_freidora_ui, _tiempo_coccion_patatas, "Patatas", delta)

	# Recarga automática de bebidas
	for i in range(_bebidas.size()):
		var b: Dictionary = _bebidas[i]
		if str(b["estado"]) == "llenando":
			b["progreso"] = minf(1.0, float(b["progreso"]) + delta / maxf(0.2, _tiempo_bebida))
			if float(b["progreso"]) >= 1.0:
				b["estado"] = "listo"
			_Actualizar_Bebida_UI(i)

	_Animar_Escena(delta)

	_reloj_sim_refresh -= delta
	if _reloj_sim_refresh <= 0.0:
		_reloj_sim_refresh = 0.5
		_lbl_cocina_reloj_sim.text = Funciones_Globales.Convertir_Minuto_A_Fecha_Hora(
			Variables_Dinamicas.Minute_Day * 1440 + Variables_Dinamicas.Minute_Minute)

	_Actualizar_HUD_Cocina()

	if _tiempo_restante <= 0.0:
		_Finalizar_Servicio()


func _Animar_Escena(delta: float) -> void:
	# Clientes: respiración, parpadeo y tickets animados
	for i in range(_clientes.size()):
		var ui: Dictionary = _slots_clientes_ui[i]
		var retrato: ArteCocina.Retrato = ui["retrato"]
		var ticket: ArteCocina.Ticket = ui["ticket"]
		retrato.tiempo = _anim_tiempo
		ticket.tiempo = _anim_tiempo
		if retrato.rebote > 0.0:
			retrato.rebote = maxf(0.0, retrato.rebote - delta * 2.4)
		retrato.queue_redraw()
		ticket.queue_redraw()

	# Platos: animación de "pop" al añadir una capa
	for i in range(_platos.size()):
		var ui_p: Dictionary = _slots_platos_ui[i]
		var plato: ArteCocina.Plato = ui_p["nodo"]
		plato.tiempo = _anim_tiempo
		ui_p["pop"] = maxf(0.0, float(ui_p.get("pop", 0.0)) - delta * 3.6)
		plato.pop = float(ui_p["pop"])
		plato.queue_redraw()

	# Bebidas
	for i in range(_bebidas.size()):
		var bebida: ArteCocina.Bebida = _slots_bebidas_ui[i]["nodo"]
		bebida.tiempo = _anim_tiempo
		bebida.queue_redraw()

	# Plancha: vapor, humo y chispas
	for i in range(_plancha.size()):
		var estado: String = str(_plancha[i]["estado"])
		if estado == "vacio":
			continue
		var nodo: Control = _slots_plancha_ui[i]["nodo"]
		nodo.tiempo = _anim_tiempo
		nodo.queue_redraw()
		_fx_plancha[i] = float(_fx_plancha[i]) - delta
		if _fx_plancha[i] <= 0.0:
			var centro: Vector2 = _slots_plancha_ui[i]["rect"].get_center()
			match estado:
				"cocinando":
					_fx_plancha[i] = randf_range(0.14, 0.24)
					_efectos.vapor(centro + Vector2(0.0, -8.0))
					if randf() < 0.35:
						_efectos.chispas(centro, 1)
				"listo":
					_fx_plancha[i] = randf_range(0.28, 0.42)
					_efectos.vapor(centro + Vector2(0.0, -8.0))
				"alerta":
					_fx_plancha[i] = randf_range(0.16, 0.26)
					_efectos.humo(centro + Vector2(0.0, -8.0))
					_efectos.fuego(centro + Vector2(randf_range(-6.0, 6.0), 2.0))
				"quemado":
					_fx_plancha[i] = randf_range(0.24, 0.36)
					_efectos.humo(centro + Vector2(0.0, -6.0))

	# Freidora: aceite y humo
	for i in range(_freidora.size()):
		var estado_f: String = str(_freidora[i]["estado"])
		if estado_f == "vacio":
			continue
		var nodo_f: Control = _slots_freidora_ui[i]["nodo"]
		nodo_f.tiempo = _anim_tiempo
		nodo_f.queue_redraw()
		_fx_freidora[i] = float(_fx_freidora[i]) - delta
		if _fx_freidora[i] <= 0.0:
			var centro_f: Vector2 = _slots_freidora_ui[i]["rect"].get_center()
			match estado_f:
				"cocinando":
					_fx_freidora[i] = randf_range(0.18, 0.30)
					_efectos.vapor(centro_f + Vector2(0.0, -12.0))
				"listo":
					_fx_freidora[i] = randf_range(0.35, 0.50)
					_efectos.vapor(centro_f + Vector2(0.0, -12.0))
				"alerta":
					_fx_freidora[i] = randf_range(0.18, 0.28)
					_efectos.humo(centro_f + Vector2(0.0, -12.0))
				"quemado":
					_fx_freidora[i] = randf_range(0.24, 0.36)
					_efectos.humo(centro_f + Vector2(0.0, -10.0))

	# Hover de la bandeja de ingredientes
	var raton: Vector2 = _Posicion_Raton_Local()
	for item in _bandeja_items_ui:
		var nodo_item: ArteCocina.Bandeja_Item = item["nodo"]
		var hover: bool = _jugando and (item["rect"] as Rect2).has_point(raton)
		if nodo_item.hover != hover:
			nodo_item.hover = hover
			nodo_item.queue_redraw()


func _Posicion_Raton_Local() -> Vector2:
	if _vista_cocina == null:
		return Vector2(-1000.0, -1000.0)
	var vp := get_viewport()
	if vp == null:
		return Vector2(-1000.0, -1000.0)
	return _vista_cocina.get_global_transform_with_canvas().affine_inverse() * vp.get_mouse_position()


func _Tick_Slots_Coccion(lista: Array[Dictionary], ui_lista: Array[Dictionary],
		tiempo_coccion: float, etiqueta: String, delta: float) -> void:
	var umbral_alerta: float = 0.45 if _aviso_temprano else 0.65
	for i in range(lista.size()):
		var s: Dictionary = lista[i]
		var est: String = str(s["estado"])
		if est == "vacio" or est == "quemado":
			continue
		if est == "cocinando":
			s["progreso"] = minf(1.0, float(s["progreso"]) + delta / maxf(0.2, tiempo_coccion))
			if float(s["progreso"]) >= 1.0:
				s["estado"] = "listo"
				s["quemado"] = 0.0
			_Actualizar_Slot_Coccion_UI(s, ui_lista[i], etiqueta)
		elif est == "listo" or est == "alerta":
			s["quemado"] = minf(1.0, float(s["quemado"]) + delta / maxf(0.5, _tiempo_quemado))
			if float(s["quemado"]) >= 1.0:
				s["estado"] = "quemado"
				_Mostrar_Feedback_En_Control(ui_lista[i]["nodo"], "¡Quemado!", Estilos_UI.PELIGRO)
			elif float(s["quemado"]) >= umbral_alerta:
				s["estado"] = "alerta"
			_Actualizar_Slot_Coccion_UI(s, ui_lista[i], etiqueta)


func _Intentar_Spawnear_Cliente() -> bool:
	var libres: Array[int] = []
	for i in range(_clientes.size()):
		if not bool(_clientes[i]["activo"]):
			libres.append(i)
	if libres.is_empty():
		return false

	var idx: int = libres[randi() % libres.size()]
	var menu: Array = _cfg_nivel_actual.get("menu", ["burger_sola", "refresco"])
	var max_items: int = clampi(int(_cfg_nivel_actual.get("max_items", 2)), 1, 3)
	var cantidad: int = randi_range(1, max_items)

	var platos_menu: Array[String] = []
	var extras_menu: Array[String] = []
	for item_raw in menu:
		var item_id: String = str(item_raw)
		var rec: Dictionary = Sistema_Cocina.RECETAS_BURGER_STREET.get(item_id, {})
		if str(rec.get("tipo", "")) == "plato":
			platos_menu.append(item_id)
		else:
			extras_menu.append(item_id)

	var pedido: Array[String] = []
	var entregados: Array[bool] = []
	var precio_total: int = 0

	for k in range(cantidad):
		var elegido: String
		if k == 0 and not platos_menu.is_empty():
			elegido = platos_menu[randi() % platos_menu.size()]
		elif k >= 1 and not extras_menu.is_empty() and randf() < 0.65:
			elegido = extras_menu[randi() % extras_menu.size()]
		else:
			elegido = str(menu[randi() % menu.size()])
		pedido.append(elegido)
		entregados.append(false)
		var rec_el: Dictionary = Sistema_Cocina.RECETAS_BURGER_STREET.get(elegido, {})
		precio_total += Sistema_Cocina.Calcular_Precio_Plato(int(rec_el.get("precio_base", 10)), _nv_ingredientes)

	var pac_base: float = float(_cfg_nivel_actual.get("paciencia_base", 25.0))
	var cl: Dictionary = _clientes[idx]
	cl["activo"] = true
	cl["items"] = pedido
	cl["entregados"] = entregados
	cl["paciencia_max"] = pac_base + float(cantidad - 1) * 4.0
	cl["paciencia"] = float(cl["paciencia_max"])
	cl["precio_total"] = precio_total

	# Elegir variante visual distinta a los clientes activos actuales cuando sea posible
	var usadas: Array[int] = []
	for j in range(_clientes.size()):
		if j != idx and bool(_clientes[j]["activo"]):
			usadas.append(int(_clientes[j].get("variante", j)))
	var disp: Array[int] = []
	for v_id in range(8):
		if not usadas.has(v_id):
			disp.append(v_id)
	cl["variante"] = disp[randi() % disp.size()] if not disp.is_empty() else (randi() % 8)

	_Actualizar_Cliente_UI(idx)
	return true


# ============================================================================
# Acciones programáticas (atajos de teclado/tests y compatibilidad)
# ============================================================================

func _on_ingrediente_pan() -> void:
	if not _jugando:
		return
	for i in range(_platos.size()):
		if not bool(_platos[i]["pan"]):
			_platos[i]["pan"] = true
			_plato_seleccionado = i
			_slots_platos_ui[i]["pop"] = 1.0
			_Actualizar_Plato_UI(i)
			return
	_Mostrar_Feedback_En_Control(_slots_platos_ui[0]["nodo"], "Platos llenos", Estilos_UI.AVISO)


func _on_ingrediente_carne() -> void:
	if not _jugando:
		return
	for i in range(_plancha.size()):
		if str(_plancha[i]["estado"]) == "vacio":
			_plancha[i]["estado"] = "cocinando"
			_plancha[i]["progreso"] = 0.0
			_plancha[i]["quemado"] = 0.0
			_Actualizar_Slot_Coccion_UI(_plancha[i], _slots_plancha_ui[i], "Carne")
			return
	_Mostrar_Feedback_En_Control(_slots_plancha_ui[0]["nodo"], "Plancha llena", Estilos_UI.AVISO)


func _on_ingrediente_patatas() -> void:
	if not _jugando:
		return
	for i in range(_freidora.size()):
		if str(_freidora[i]["estado"]) == "vacio":
			_freidora[i]["estado"] = "cocinando"
			_freidora[i]["progreso"] = 0.0
			_freidora[i]["quemado"] = 0.0
			_Actualizar_Slot_Coccion_UI(_freidora[i], _slots_freidora_ui[i], "Patatas")
			return
	_Mostrar_Feedback_En_Control(_slots_freidora_ui[0]["nodo"], "Freidora llena", Estilos_UI.AVISO)


func _on_ingrediente_queso() -> void:
	_Anadir_Topping("queso", "Queso")


func _on_ingrediente_lechuga() -> void:
	_Anadir_Topping("lechuga", "Lechuga")


func _on_ingrediente_tomate() -> void:
	_Anadir_Topping("tomate", "Tomate")


func _Anadir_Topping(clave: String, nombre_vis: String) -> void:
	if not _jugando:
		return
	var orden: Array[int] = _Orden_Busqueda_Platos()
	for idx in orden:
		var p: Dictionary = _platos[idx]
		if bool(p["pan"]) and not bool(p[clave]):
			p[clave] = true
			_plato_seleccionado = idx
			_slots_platos_ui[idx]["pop"] = 1.0
			_Actualizar_Plato_UI(idx)
			return
	_Mostrar_Feedback_En_Control(_contenedor_platos, "Pon pan primero (%s)" % nombre_vis, Estilos_UI.AVISO)


func _on_boton_papelera() -> void:
	# La papelera ahora se usa arrastrando objetos hasta ella.
	_Mostrar_Feedback_En_Control(_papelera_root, "Arrastra aquí lo que quieras tirar", Estilos_UI.TINTA_SUAVE, -12.0)


func _on_plancha_pulsada(indice: int) -> void:
	if not _jugando or indice < 0 or indice >= _plancha.size():
		return
	var s: Dictionary = _plancha[indice]
	var est: String = str(s["estado"])
	if est == "vacio":
		return
	if est == "quemado":
		s["estado"] = "vacio"
		s["progreso"] = 0.0
		s["quemado"] = 0.0
		_Actualizar_Slot_Coccion_UI(s, _slots_plancha_ui[indice], "Carne")
		_Mostrar_Feedback_En_Control(_slots_plancha_ui[indice]["nodo"], "Descartado", Estilos_UI.TINTA_SUAVE)
		return
	if est == "cocinando":
		_Mostrar_Feedback_En_Control(_slots_plancha_ui[indice]["nodo"], "Cocinando...", Estilos_UI.AVISO)
		return
	# Estado listo o alerta: pasar carne al plato más adecuado
	var orden: Array[int] = _Orden_Busqueda_Platos()
	var elegido: int = -1
	for idx in orden:
		if bool(_platos[idx]["pan"]) and int(_platos[idx]["carnes"]) == 0:
			elegido = idx
			break
	if elegido == -1:
		for idx in orden:
			if bool(_platos[idx]["pan"]) and int(_platos[idx]["carnes"]) == 1:
				elegido = idx
				break
	if elegido == -1:
		_Mostrar_Feedback_En_Control(_slots_plancha_ui[indice]["nodo"], "Pon un pan en un plato", Estilos_UI.AVISO)
		return

	_platos[elegido]["carnes"] = int(_platos[elegido]["carnes"]) + 1
	_plato_seleccionado = elegido
	_slots_platos_ui[elegido]["pop"] = 1.0
	s["estado"] = "vacio"
	s["progreso"] = 0.0
	s["quemado"] = 0.0
	_Actualizar_Slot_Coccion_UI(s, _slots_plancha_ui[indice], "Carne")
	_Actualizar_Plato_UI(elegido)


func _on_freidora_pulsada(indice: int) -> void:
	if not _jugando or indice < 0 or indice >= _freidora.size():
		return
	var s: Dictionary = _freidora[indice]
	var est: String = str(s["estado"])
	if est == "vacio":
		return
	if est == "quemado":
		s["estado"] = "vacio"
		s["progreso"] = 0.0
		s["quemado"] = 0.0
		_Actualizar_Slot_Coccion_UI(s, _slots_freidora_ui[indice], "Patatas")
		_Mostrar_Feedback_En_Control(_slots_freidora_ui[indice]["nodo"], "Descartado", Estilos_UI.TINTA_SUAVE)
		return
	if est == "cocinando":
		_Mostrar_Feedback_En_Control(_slots_freidora_ui[indice]["nodo"], "Friendo...", Estilos_UI.AVISO)
		return
	if _Entregar_Item_A_Cliente_Urgente("patatas"):
		s["estado"] = "vacio"
		s["progreso"] = 0.0
		s["quemado"] = 0.0
		_Actualizar_Slot_Coccion_UI(s, _slots_freidora_ui[indice], "Patatas")
	else:
		_Mostrar_Feedback_En_Control(_slots_freidora_ui[indice]["nodo"], "Nadie pidió patatas", Estilos_UI.TINTA_SUAVE)


func _on_bebida_pulsada(indice: int) -> void:
	if not _jugando or indice < 0 or indice >= _bebidas.size():
		return
	var b: Dictionary = _bebidas[indice]
	if str(b["estado"]) != "listo":
		return
	if _Entregar_Item_A_Cliente_Urgente("refresco"):
		b["estado"] = "llenando"
		b["progreso"] = 0.0
		_Actualizar_Bebida_UI(indice)
	else:
		_Mostrar_Feedback_En_Control(_slots_bebidas_ui[indice]["nodo"], "Nadie pidió refresco", Estilos_UI.TINTA_SUAVE)


func _on_plato_pulsado(indice: int) -> void:
	if not _jugando or indice < 0 or indice >= _platos.size():
		return
	var p: Dictionary = _platos[indice]
	var receta_id: String = _Receta_De_Plato(p)
	if receta_id != "" and _Entregar_Item_A_Cliente_Urgente(receta_id):
		_Limpiar_Plato(indice)
		return

	_plato_seleccionado = indice
	_Actualizar_Todos_Los_Platos_UI()


func _on_cliente_pulsado(indice_cliente: int) -> void:
	if not _jugando or indice_cliente < 0 or indice_cliente >= _clientes.size():
		return
	var cl: Dictionary = _clientes[indice_cliente]
	if not bool(cl["activo"]):
		return

	# Servir primero el plato seleccionado, luego cualquier plato, freidora o bebida
	var orden_platos: Array[int] = _Orden_Busqueda_Platos()
	for idx_p in orden_platos:
		var rec: String = _Receta_De_Plato(_platos[idx_p])
		if rec != "" and _Entregar_Item_A_Cliente(indice_cliente, rec):
			_Limpiar_Plato(idx_p)
			return

	for i in range(_freidora.size()):
		if str(_freidora[i]["estado"]) in ["listo", "alerta"] and _Entregar_Item_A_Cliente(indice_cliente, "patatas"):
			_freidora[i]["estado"] = "vacio"
			_freidora[i]["progreso"] = 0.0
			_freidora[i]["quemado"] = 0.0
			_Actualizar_Slot_Coccion_UI(_freidora[i], _slots_freidora_ui[i], "Patatas")
			return

	for i in range(_bebidas.size()):
		if str(_bebidas[i]["estado"]) == "listo" and _Entregar_Item_A_Cliente(indice_cliente, "refresco"):
			_bebidas[i]["estado"] = "llenando"
			_bebidas[i]["progreso"] = 0.0
			_Actualizar_Bebida_UI(i)
			return


func _Orden_Busqueda_Platos() -> Array[int]:
	var orden: Array[int] = []
	if _plato_seleccionado >= 0 and _plato_seleccionado < _platos.size():
		orden.append(_plato_seleccionado)
	for i in range(_platos.size()):
		if not orden.has(i):
			orden.append(i)
	return orden


func _Receta_De_Plato(p: Dictionary) -> String:
	return Sistema_Cocina.Identificar_Hamburguesa(
		bool(p["pan"]), int(p["carnes"]), bool(p["queso"]), bool(p["lechuga"]), bool(p["tomate"])
	)


func _Limpiar_Plato(indice: int) -> void:
	_platos[indice] = {"pan": false, "carnes": 0, "queso": false, "lechuga": false, "tomate": false}
	if _plato_seleccionado == indice:
		_plato_seleccionado = -1
	_Actualizar_Todos_Los_Platos_UI()


func _Entregar_Item_A_Cliente_Urgente(item_id: String) -> bool:
	var mejor_idx: int = -1
	var menor_ratio: float = 999.0
	for i in range(_clientes.size()):
		var cl: Dictionary = _clientes[i]
		if not bool(cl["activo"]):
			continue
		if not _Cliente_Necesita_Item(cl, item_id):
			continue
		var ratio: float = float(cl["paciencia"]) / maxf(1.0, float(cl["paciencia_max"]))
		if ratio < menor_ratio:
			menor_ratio = ratio
			mejor_idx = i
	if mejor_idx == -1:
		return false
	return _Entregar_Item_A_Cliente(mejor_idx, item_id)


func _Cliente_Necesita_Item(cl: Dictionary, item_id: String) -> bool:
	var items: Array = cl["items"]
	var entregados: Array = cl["entregados"]
	for j in range(items.size()):
		if str(items[j]) == item_id and not bool(entregados[j]):
			return true
	return false


func _Entregar_Item_A_Cliente(indice_cliente: int, item_id: String) -> bool:
	var cl: Dictionary = _clientes[indice_cliente]
	if not bool(cl["activo"]):
		return false
	var items: Array = cl["items"]
	var entregados: Array = cl["entregados"]
	var marcado: bool = false
	for j in range(items.size()):
		if str(items[j]) == item_id and not bool(entregados[j]):
			entregados[j] = true
			marcado = true
			break
	if not marcado:
		return false

	# Pequeño alivio de paciencia por recibir parte del pedido
	cl["paciencia"] = minf(float(cl["paciencia_max"]), float(cl["paciencia"]) + 2.5)

	var completo: bool = true
	for e in entregados:
		if not bool(e):
			completo = false
			break

	if completo:
		_Completar_Pedido_Cliente(indice_cliente)
	else:
		var retrato: ArteCocina.Retrato = _slots_clientes_ui[indice_cliente]["retrato"]
		retrato.rebote = 1.0
		var centro: Vector2 = _slots_clientes_ui[indice_cliente]["ticket"].get_global_rect().get_center()
		_efectos.frescura(centro)
		_Actualizar_Cliente_UI(indice_cliente)
	_Actualizar_Todos_Los_Platos_UI()
	return true


func _Completar_Pedido_Cliente(indice_cliente: int) -> void:
	var cl: Dictionary = _clientes[indice_cliente]
	if _combo_timer > 0.0:
		_combo_actual = mini(5, _combo_actual + 1)
	else:
		_combo_actual = 1
	_combo_max = maxi(_combo_max, _combo_actual)
	_combo_timer = VENTANA_COMBO_SEG

	var precio: int = int(cl["precio_total"])
	var ratio: float = clampf(float(cl["paciencia"]) / maxf(1.0, float(cl["paciencia_max"])), 0.0, 1.0)
	var propina: int = Sistema_Cocina.Calcular_Propina_Cliente(
		precio, ratio, _combo_actual, _nv_ambiente, _bonus_ropa_propinas)

	_recaudacion += precio + propina
	_propinas_servicio += propina
	_clientes_atendidos += 1
	cl["activo"] = false

	var ancla: Control = _slots_clientes_ui[indice_cliente]["retrato"]
	var txt_cobro: String = "+%d 🪙" % precio
	if propina > 0:
		txt_cobro += " (+%d prop.)" % propina
	if _combo_actual >= 2:
		txt_cobro += " · x%d!" % _combo_actual
	_Mostrar_Feedback_En_Control(ancla, txt_cobro, Estilos_UI.EXITO)

	# Micro-recompensas del Sim por cliente
	var micro: Dictionary = Sistema_Cocina.Procesar_Micro_Recompensa_Cliente(
		_en_turno_partida, _micro_propinas_sesion)
	var c_gan: int = int(micro.get("cocina_ganada", 0))
	var m_gan: int = int(micro.get("manualidades_ganadas", 0))
	var n_gan: int = int(micro.get("necesidad_ganada", 0))
	var p_eur: float = float(micro.get("micro_propina_eur", 0.0))

	var extras: Array[String] = []
	if c_gan > 0:
		_cocina_ganada_sesion += c_gan
		extras.append("+%d Cocina" % c_gan)
	if m_gan > 0:
		_manualidades_ganadas_sesion += m_gan
		extras.append("+%d Manualidades" % m_gan)
	if n_gan > 0:
		var nom_n: String = "Salud Mental" if int(micro.get("necesidad_indice", 1)) == 1 else "Hambre"
		extras.append("+%d %s" % [n_gan, nom_n])
	if p_eur > 0.0:
		_micro_propinas_sesion += p_eur
		extras.append("+%.2f €" % p_eur)

	if not extras.is_empty():
		_Mostrar_Feedback_En_Control(ancla, " · ".join(extras), Color("#d97706"), 26.0)

	# Fuegos artificiales de monedas, estrellas y reacción del chef
	var centro_cliente: Vector2 = ancla.get_global_rect().get_center()
	var centro_local: Vector2 = _slots_clientes_ui[indice_cliente]["centro"]
	_efectos.monedas(centro_local)
	_efectos.estrellas(centro_local, 6)
	_Lanzar_Monedas(ancla)
	if _combo_actual >= 2:
		_Mostrar_Chef("celebra", "¡COMBO x%d! ¡INCREÍBLE!" % _combo_actual, Color("#b91c1c"), 1.5)
	elif ratio >= 0.5:
		_Mostrar_Chef("pulgar", "¡BUEN TRABAJO!", Color("#15803d"), 1.3)
	else:
		_Mostrar_Chef("pulgar", "¡Por los pelos!", Color("#b45309"), 1.3)

	_Actualizar_Cliente_UI(indice_cliente)
	_Actualizar_HUD_Cocina()


# ============================================================================
# Actualización Visual de HUD y Estaciones
# ============================================================================

func _Actualizar_HUD_Cocina() -> void:
	var segs: int = int(ceil(_tiempo_restante))
	_lbl_cocina_reloj.text = "%02d:%02d" % [segs / 60, segs % 60]
	_lbl_cocina_reloj.add_theme_color_override("font_color",
		Color("#fca5a5") if segs <= 10 else Color.WHITE)

	var m1: int = int(_cfg_nivel_actual.get("meta_1", 55))
	var m2: int = int(_cfg_nivel_actual.get("meta_2", 85))
	var m3: int = int(_cfg_nivel_actual.get("meta_3", 115))
	_bar_cocina_meta.max_value = float(maxi(1, m3))
	_bar_cocina_meta.value = minf(float(m3), float(_recaudacion))
	_lbl_cocina_recaudacion.text = "%d / %d" % [_recaudacion, m3]
	_lbl_cocina_propinas.text = "+%d" % _propinas_servicio
	_lbl_estado_propinas.text = "%d" % _propinas_servicio

	var est: int = Sistema_Cocina.Calcular_Estrellas(_recaudacion, m1, m2, m3)
	for s in range(3):
		var ganada: bool = s < est
		var tex: Texture2D = ArteCocina.TEX_ESTRELLA if ganada else ArteCocina.TEX_ESTRELLA_VACIA
		if _estrellas_hud[s].texture != tex:
			_estrellas_hud[s].texture = tex
			if ganada:
				var tw := _estrellas_hud[s].create_tween()
				_estrellas_hud[s].scale = Vector2(1.75, 1.75)
				tw.tween_property(_estrellas_hud[s], "scale", Vector2.ONE, 0.35)\
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				_efectos.estrellas(_Posicion_Local(_estrellas_hud[s].get_global_rect().get_center()), 10)
				_Mostrar_Banner("¡%d ESTRELLA%s!" % [est, "" if est == 1 else "S"],
					Color("#fde047"))

	if _combo_actual >= 2 and _combo_timer > 0.0:
		_pill_cocina_combo.visible = true
		_lbl_cocina_combo.text = "COMBO x%d" % _combo_actual
		var pulso: float = 1.0 + 0.08 * sin(_anim_tiempo * 12.0)
		_pill_cocina_combo.scale = Vector2(pulso, pulso)
	else:
		_pill_cocina_combo.visible = false
		_pill_cocina_combo.scale = Vector2.ONE


func _Actualizar_Todos_Los_Clientes_UI() -> void:
	for i in range(_clientes.size()):
		_Actualizar_Cliente_UI(i)


func _Actualizar_Cliente_UI(indice: int) -> void:
	var cl: Dictionary = _clientes[indice]
	var ui: Dictionary = _slots_clientes_ui[indice]
	var activo: bool = bool(cl["activo"])
	var retrato: ArteCocina.Retrato = ui["retrato"]
	var ticket: ArteCocina.Ticket = ui["ticket"]

	if not activo:
		if bool(ui["visible_antes"]):
			_Animar_Salida_Cliente(indice)
		return

	var primera_vez: bool = not bool(ui["visible_antes"])
	ui["visible_antes"] = true
	retrato.visible = true
	ticket.visible = true
	retrato.variante = int(cl.get("variante", indice))
	retrato.ratio = 1.0
	ticket.items = (cl["items"] as Array).duplicate()
	ticket.entregados = (cl["entregados"] as Array).duplicate()
	ticket.ratio = 1.0
	ticket.destacado = false
	ticket.tiempo = _anim_tiempo

	if primera_vez:
		_Animar_Entrada_Cliente(indice)

	_Actualizar_Paciencia_Cliente_UI(indice)


func _Animar_Entrada_Cliente(indice: int) -> void:
	var ui: Dictionary = _slots_clientes_ui[indice]
	var retrato: ArteCocina.Retrato = ui["retrato"]
	var ticket: ArteCocina.Ticket = ui["ticket"]
	var tween_prev: Tween = ui.get("tween", null)
	if tween_prev != null and tween_prev.is_valid():
		tween_prev.kill()

	var pos_r: Vector2 = ui["pos_retrato"]
	var pos_t: Vector2 = ui["pos_ticket"]
	retrato.position = pos_r + Vector2(0.0, 38.0)
	retrato.modulate = Color(1, 1, 1, 0)
	ticket.position = pos_t + Vector2(0.0, -22.0)
	ticket.modulate = Color(1, 1, 1, 0)
	ticket.pivot_offset = ticket.size * 0.5
	ticket.scale = Vector2(0.82, 0.82)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(retrato, "position", pos_r, 0.40).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(retrato, "modulate:a", 1.0, 0.26)
	tw.tween_property(ticket, "position", pos_t, 0.44).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(ticket, "modulate:a", 1.0, 0.26)
	tw.tween_property(ticket, "scale", Vector2.ONE, 0.44).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	ui["tween"] = tw


func _Animar_Salida_Cliente(indice: int) -> void:
	var ui: Dictionary = _slots_clientes_ui[indice]
	ui["visible_antes"] = false
	var retrato: ArteCocina.Retrato = ui["retrato"]
	var ticket: ArteCocina.Ticket = ui["ticket"]
	var tween_prev: Tween = ui.get("tween", null)
	if tween_prev != null and tween_prev.is_valid():
		tween_prev.kill()

	var pos_r: Vector2 = ui["pos_retrato"]
	var pos_t: Vector2 = ui["pos_ticket"]
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(retrato, "position:y", pos_r.y + 30.0, 0.34).set_ease(Tween.EASE_IN)
	tw.tween_property(retrato, "modulate:a", 0.0, 0.28)
	tw.tween_property(ticket, "position:y", pos_t.y - 16.0, 0.34).set_ease(Tween.EASE_IN)
	tw.tween_property(ticket, "modulate:a", 0.0, 0.28)
	tw.chain().tween_callback(func():
		retrato.visible = false
		ticket.visible = false
		retrato.position = pos_r
		ticket.position = pos_t
		retrato.modulate = Color.WHITE
		ticket.modulate = Color.WHITE
		ticket.scale = Vector2.ONE)
	ui["tween"] = tw


func _Actualizar_Paciencia_Cliente_UI(indice: int) -> void:
	var cl: Dictionary = _clientes[indice]
	if not bool(cl["activo"]):
		return
	var ui: Dictionary = _slots_clientes_ui[indice]
	var ratio: float = clampf(float(cl["paciencia"]) / maxf(1.0, float(cl["paciencia_max"])), 0.0, 1.0)
	var retrato: ArteCocina.Retrato = ui["retrato"]
	var ticket: ArteCocina.Ticket = ui["ticket"]
	retrato.ratio = ratio
	retrato.tiempo = _anim_tiempo
	ticket.ratio = ratio
	ticket.tiempo = _anim_tiempo


func _Actualizar_Todas_Las_Estaciones_UI() -> void:
	_Actualizar_Contadores_Estaciones()
	for i in range(_bebidas.size()):
		_Actualizar_Bebida_UI(i)
	_Actualizar_Todos_Los_Platos_UI()
	for i in range(_plancha.size()):
		_Actualizar_Slot_Coccion_UI(_plancha[i], _slots_plancha_ui[i], "Carne")
	for i in range(_freidora.size()):
		_Actualizar_Slot_Coccion_UI(_freidora[i], _slots_freidora_ui[i], "Patatas")


func _Actualizar_Contadores_Estaciones() -> void:
	var listas_b: int = 0
	for b in _bebidas:
		if str(b["estado"]) == "listo":
			listas_b += 1
	_lbl_estado_bebidas.text = "REFRESCOS · %d/%d listos" % [listas_b, _bebidas.size()]

	var libres_p: int = 0
	for s in _plancha:
		if str(s["estado"]) == "vacio":
			libres_p += 1
	_lbl_estado_plancha.text = "PLANCHA · %d/%d libres" % [libres_p, _plancha.size()]

	var libres_f: int = 0
	for s in _freidora:
		if str(s["estado"]) == "vacio":
			libres_f += 1
	_lbl_estado_freidora.text = "FREIDORA · %d/%d libres" % [libres_f, _freidora.size()]

	var listos_pl: int = 0
	for i in range(_platos.size()):
		if _Receta_De_Plato(_platos[i]) != "":
			listos_pl += 1
	_lbl_estado_platos.text = "EMPLATADO · %d/%d listos" % [listos_pl, _platos.size()]


func _Actualizar_Bebida_UI(indice: int) -> void:
	if indice < 0 or indice >= _slots_bebidas_ui.size():
		return
	var b: Dictionary = _bebidas[indice]
	var nodo: ArteCocina.Bebida = _slots_bebidas_ui[indice]["nodo"]
	nodo.estado = str(b["estado"])
	nodo.progreso = float(b["progreso"])
	nodo.tiempo = _anim_tiempo
	nodo.queue_redraw()
	_Actualizar_Contadores_Estaciones()


func _Actualizar_Todos_Los_Platos_UI() -> void:
	for i in range(_platos.size()):
		_Actualizar_Plato_UI(i)


func _Actualizar_Plato_UI(indice: int) -> void:
	var p: Dictionary = _platos[indice]
	var ui: Dictionary = _slots_platos_ui[indice]
	var nodo: ArteCocina.Plato = ui["nodo"]

	var rec_id: String = _Receta_De_Plato(p)
	var pedida_ahora: bool = rec_id != "" and _Algun_Cliente_Necesita(rec_id)
	var sel: bool = (_plato_seleccionado == indice)

	nodo.pan = bool(p["pan"])
	nodo.carnes = int(p["carnes"])
	nodo.queso = bool(p["queso"])
	nodo.lechuga = bool(p["lechuga"])
	nodo.tomate = bool(p["tomate"])
	nodo.pedida = pedida_ahora
	nodo.seleccionado = sel
	nodo.tiempo = _anim_tiempo
	nodo.queue_redraw()


func _Algun_Cliente_Necesita(item_id: String) -> bool:
	for cl in _clientes:
		if bool(cl["activo"]) and _Cliente_Necesita_Item(cl, item_id):
			return true
	return false


func _Actualizar_Slot_Coccion_UI(slot: Dictionary, ui: Dictionary, _etiqueta: String) -> void:
	if ui.is_empty() or not ui.has("nodo"):
		return
	var nodo: ArteCocina.Punto_Coccion = ui["nodo"]
	nodo.estado = str(slot["estado"])
	nodo.progreso = float(slot["progreso"])
	nodo.quemado = float(slot["quemado"])
	nodo.tiempo = _anim_tiempo
	nodo.queue_redraw()
	_Actualizar_Contadores_Estaciones()


func _Mostrar_Feedback_En_Control(ctrl: Control, texto_fb: String, color_fb: Color, offset_y: float = 0.0) -> void:
	if ctrl == null or not is_inside_tree() or _capa_feedback == null:
		return
	var lbl := Estilos_UI.titulo(texto_fb, 15, color_fb)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_color_override("font_outline_color", Color.WHITE)
	lbl.add_theme_constant_override("outline_size", 4)
	var rect: Rect2 = ctrl.get_global_rect()
	lbl.position = Vector2(rect.position.x + 14.0, rect.position.y + 18.0 + offset_y)
	_capa_feedback.add_child(lbl)
	var tw := lbl.create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - 38.0, 1.05).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 1.05).set_delay(0.25)
	tw.chain().tween_callback(lbl.queue_free)


func _Mostrar_Feedback_En_Posicion(pos_local: Vector2, texto_fb: String, color_fb: Color) -> void:
	if _capa_feedback == null or _vista_cocina == null:
		return
	var lbl := Estilos_UI.titulo(texto_fb, 16, color_fb)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_color_override("font_outline_color", Color.WHITE)
	lbl.add_theme_constant_override("outline_size", 5)
	var centro_global: Vector2 = _vista_cocina.global_position + pos_local
	lbl.position = centro_global - Vector2(80.0, 30.0)
	lbl.size = Vector2(160.0, 24.0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_capa_feedback.add_child(lbl)
	var tw := lbl.create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - 34.0, 0.95).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.95).set_delay(0.30)
	tw.chain().tween_callback(lbl.queue_free)


func _Posicion_Local(pos_global: Vector2) -> Vector2:
	if _vista_cocina == null:
		return pos_global
	return _vista_cocina.get_global_transform_with_canvas().affine_inverse() * pos_global


func _Mostrar_Banner(texto: String, color: Color) -> void:
	if _banner_servicio == null:
		return
	if _banner_tween != null and _banner_tween.is_valid():
		_banner_tween.kill()
	_banner_servicio.text = texto
	_banner_servicio.add_theme_color_override("font_color", color)
	_banner_servicio.pivot_offset = _banner_servicio.size * 0.5
	_banner_servicio.modulate.a = 1.0
	_banner_servicio.scale = Vector2(0.65, 0.65)
	_banner_tween = create_tween()
	_banner_tween.tween_property(_banner_servicio, "scale", Vector2.ONE, 0.30)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_tween.tween_interval(0.70)
	_banner_tween.tween_property(_banner_servicio, "modulate:a", 0.0, 0.35)


func _Mostrar_Chef(pose: String, texto: String, color_texto: Color, duracion: float = 1.4) -> void:
	if _chef_root == null:
		return
	if _chef_tween != null and _chef_tween.is_valid():
		_chef_tween.kill()
	_chef_textura.texture = ArteCocina.textura_chef(pose)
	_chef_label.text = texto
	_chef_label.add_theme_color_override("font_color", color_texto)
	_chef_root.visible = true
	_chef_root.modulate.a = 1.0
	_chef_root.position = Vector2(-36.0, 119.0)
	_chef_burbuja.pivot_offset = _chef_burbuja.size * 0.5
	_chef_burbuja.scale = Vector2(0.75, 0.75)
	_chef_tween = create_tween()
	_chef_tween.set_parallel(true)
	_chef_tween.tween_property(_chef_root, "position:x", 6.0, 0.28)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_chef_tween.tween_property(_chef_burbuja, "scale", Vector2.ONE, 0.30)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_chef_tween.chain().tween_interval(duracion)
	_chef_tween.chain().tween_property(_chef_root, "position:x", -40.0, 0.26).set_ease(Tween.EASE_IN)
	_chef_tween.chain().tween_callback(func(): _chef_root.visible = false)


func _Lanzar_Monedas(desde_control: Control) -> void:
	if _capa_feedback == null or _hud_moneda_icon == null:
		return
	var inicio: Vector2 = desde_control.get_global_rect().get_center()
	var destino: Vector2 = _hud_moneda_icon.get_global_rect().get_center()
	for k in range(3):
		var moneda := TextureRect.new()
		moneda.texture = ArteCocina.TEX_MONEDA
		moneda.size = Vector2(26.0, 26.0)
		moneda.position = inicio + Vector2(randf_range(-18.0, 18.0), randf_range(-12.0, 12.0))
		moneda.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		moneda.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		moneda.mouse_filter = Control.MOUSE_FILTER_IGNORE
		moneda.pivot_offset = moneda.size * 0.5
		_capa_feedback.add_child(moneda)
		var tw := moneda.create_tween()
		tw.set_parallel(true)
		tw.tween_property(moneda, "position", destino + Vector2(randf_range(-3.0, 3.0), 0.0), 0.62)\
			.set_delay(0.05 * float(k)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw.tween_property(moneda, "scale", Vector2(0.55, 0.55), 0.62)\
			.set_delay(0.05 * float(k))
		tw.tween_property(moneda, "modulate:a", 0.15, 0.24).set_delay(0.42 + 0.05 * float(k))
		tw.chain().tween_callback(moneda.queue_free)


# ============================================================================
# Finalización de Servicio y Modal de Resultados
# ============================================================================

func _Finalizar_Servicio() -> void:
	_jugando = false
	var resumen: Dictionary = Sistema_Cocina.Procesar_Fin_Nivel(
		_restaurante_actual, _nivel_actual, _recaudacion, _propinas_servicio, _en_turno_partida)
	_Mostrar_Modal_Resultados(resumen)


func _Mostrar_Modal_Resultados(resumen: Dictionary) -> void:
	for c in _vbox_modal_resultados.get_children():
		c.queue_free()

	var estrellas: int = int(resumen.get("estrellas", 0))
	var superado: bool = bool(resumen.get("superado", false))

	var tit_txt: String = "¡SERVICIO SUPERADO!" if superado else "SERVICIO INCOMPLETO"
	var tit := Estilos_UI.titulo(tit_txt, 26, Estilos_UI.EXITO_OSCURO if superado else Estilos_UI.PELIGRO)
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vbox_modal_resultados.add_child(tit)

	var sub := Estilos_UI.texto("Nivel %d · %s" % [_nivel_actual, Sistema_Cocina.Obtener_Nombre_Restaurante(_restaurante_actual)],
		14, Estilos_UI.TINTA_SUAVE, 600)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vbox_modal_resultados.add_child(sub)

	# 3 estrellas grandes
	var h_est := HBoxContainer.new()
	h_est.alignment = BoxContainer.ALIGNMENT_CENTER
	h_est.add_theme_constant_override("separation", 16)
	_vbox_modal_resultados.add_child(h_est)
	for s in range(3):
		h_est.add_child(Estilos_UI.icono_rect("star", 46, Color("#f59e0b") if s < estrellas else Color("#cbd5e1")))

	_vbox_modal_resultados.add_child(Estilos_UI.divisor_horizontal())

	# Tabla de resultados
	var fondos_g: int = int(resumen.get("fondos_ganados", 0))
	var dinero_nivel: float = float(resumen.get("dinero_ganado", 0.0))
	var dinero_total: float = round((dinero_nivel + _micro_propinas_sesion) * 100.0) / 100.0
	var bono_est: float = float(resumen.get("bono_estrellas_eur", 0.0))
	var prop_eur: float = float(resumen.get("propinas_eur", 0.0))

	_Agregar_Fila_Resultado("Recaudación del servicio", "%d 🪙 (%d clientes · Combo máx x%d)" % [_recaudacion, _clientes_atendidos, maxi(1, _combo_max)])
	_Agregar_Fila_Resultado("Fondos de Cocina ganados", "+%d 🪙%s" % [fondos_g, " (En Turno x1.5)" if _en_turno_partida else ""])
	_Agregar_Fila_Resultado("Dinero para el Sim", "+%.2f € (Estrellas %.2f € · Propinas %.2f € · Micro %.2f €)" % [dinero_total, bono_est, prop_eur, _micro_propinas_sesion])
	_Agregar_Fila_Resultado("Progreso Cocina", "+%d (Actual: %d / 100)" % [_cocina_ganada_sesion, Variables_Dinamicas.Progreso_Cocina])
	if _manualidades_ganadas_sesion > 0:
		_Agregar_Fila_Resultado("Progreso Manualidades", "+%d (Actual: %d / 100)" % [_manualidades_ganadas_sesion, int(Variables_Dinamicas.Progreso[2])])

	if bool(resumen.get("plus_nomina_activado", false)):
		_vbox_modal_resultados.add_child(Estilos_UI.pill_estado(
			"✓ +10% bonus asegurado en tu nómina de hostelería al terminar el turno",
			Estilos_UI.EXITO_SUAVE, Estilos_UI.EXITO_OSCURO))
	elif bool(resumen.get("limite_diario_alcanzado", false)):
		_vbox_modal_resultados.add_child(Estilos_UI.pill_estado(
			"Límite diario de propinas en modo libre alcanzado (2/2). En turno son ilimitadas.",
			Estilos_UI.AVISO_SUAVE, Estilos_UI.ORO))

	if bool(resumen.get("subio_rango", false)):
		var r_nuevo: int = int(resumen.get("rango_nuevo", 0))
		var info_r: Dictionary = Sistema_Cocina.Obtener_Info_Rango(r_nuevo)
		var prendas: Array = resumen.get("prendas_desbloqueadas", [])
		var msg_logro: String = "¡Nuevo Rango %d/9: %s! %s" % [r_nuevo, str(info_r.get("nombre", "")), str(info_r.get("beneficio", ""))]
		if not prendas.is_empty():
			var nombres_p: Array[String] = []
			for pk in prendas:
				nombres_p.append(Sistema_Cocina.Obtener_Nombre_Legible_Ropa(str(pk)))
			msg_logro += "\nPrenda desbloqueada: %s (Perfil → Apuntes → Ropa)" % ", ".join(nombres_p)
		var banner_l := PanelContainer.new()
		banner_l.add_theme_stylebox_override("panel", Estilos_UI.caja(Color("#fef3c7"), 12, Color("#d97706"), 2, 0))
		var ml := MarginContainer.new()
		ml.add_theme_constant_override("margin_left", 14)
		ml.add_theme_constant_override("margin_right", 14)
		ml.add_theme_constant_override("margin_top", 8)
		ml.add_theme_constant_override("margin_bottom", 8)
		banner_l.add_child(ml)
		ml.add_child(Estilos_UI.parrafo(msg_logro, 13, Color("#92400e")))
		_vbox_modal_resultados.add_child(banner_l)

	_vbox_modal_resultados.add_child(Estilos_UI.separador(4))

	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 12)
	_vbox_modal_resultados.add_child(btns)

	var btn_mapa := Estilos_UI.boton("Mapa", "secundario", "arrow-left", Estilos_UI.TINTA, 48)
	btn_mapa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_mapa.pressed.connect(_Mostrar_Mapa)
	btns.add_child(btn_mapa)

	var btn_rep := Estilos_UI.boton("Repetir", "oro", "play", Estilos_UI.ORO, 48)
	btn_rep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_rep.pressed.connect(func(): _Iniciar_Nivel(_nivel_actual))
	btns.add_child(btn_rep)

	var tiene_sig: bool = superado and _nivel_actual < 15
	var btn_sig := Estilos_UI.boton("Siguiente Nivel", "exito", "chevron-right", Estilos_UI.EXITO, 48)
	btn_sig.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_sig.disabled = not tiene_sig
	btn_sig.pressed.connect(func(): _Iniciar_Nivel(_nivel_actual + 1))
	btns.add_child(btn_sig)

	_modal_resultados.visible = true


func _Agregar_Fila_Resultado(clave: String, valor: String) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var k := Estilos_UI.texto(clave, 14, Estilos_UI.TINTA_SUAVE, 600)
	k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(k)
	var v := Estilos_UI.texto(valor, 14, Estilos_UI.TINTA, 700)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(v)
	_vbox_modal_resultados.add_child(h)
