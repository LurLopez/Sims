extends Control

# ============================================================================
# Pantalla principal de «La Granja» (horizontal 1280×720).
#
# Lienzo isométrico libre 24×24 con cámara (arrastrar + zoom), huellas reales
# multi-celda (cultivo 2×2, gallina 2×2, vaca 3×3, quesería 3×3, panadería
# 4×3/3×4, molino 4×4), vista previa fantasma al colocar o mover gratis,
# siembra rápida en cadena, inspector contextual y modales estilo granja.
# ============================================================================

signal cerrado()

const TAMANO_HORIZONTAL := Vector2i(1280, 720)
const TAMANO_VERTICAL := Vector2i(720, 1280)
const Datos := preload("res://Scripts/Logica/Escena_Principal/Granja/Datos_Granja.gd")
const Estilo := preload("res://Scripts/GUI/Granja/Estilo_Granja.gd")
const IconoProducto := preload("res://Scripts/GUI/Granja/Icono_Producto.gd")
const MundoGranja := preload("res://Scripts/GUI/Granja/Mundo_Granja.gd")

var _mundo: MundoGranja
var _capa_flotantes: Control

# Cabecera y controles reposicionables
var _cabecera: Control
var _cabecera_der: HBoxContainer
var _controles_camara: PanelContainer
var _dock_der: HBoxContainer
var _lbl_mg: Label
var _lbl_dinero: Label
var _lbl_estado_granja: Label
var _barra_area_fill: Panel
var _btn_ingresar: Button
var _btn_cobrar: Button

# Banner superior contextual
var _banner_modo: PanelContainer
var _banner_modo_lbl: Label

# Barra inferior principal
var _dock_principal: Control
var _btn_construir: Button
var _btn_almacen: Button
var _btn_mejoras: Button
var _btn_recoger_todo: Button
var _btn_mover_modo: Button
var _btn_vender_modo: Button

# Barra contextual de colocación / movimiento (Ghost)
var _barra_ghost: PanelContainer
var _ghost_ico: IconoProducto
var _ghost_titulo: Label
var _ghost_estado: Label
var _btn_ghost_rotar: Button
var _btn_ghost_confirmar: Button

# Barra contextual de siembra rápida
var _barra_siembra: PanelContainer
var _siembra_sub: Label
var _siembra_botones: Dictionary = {}  # clave -> Button
var _semilla_activa: String = ""
var _parcela_siembra_id: int = -1

# Tarjeta inspectora compacta
var _tarjeta_inspector: PanelContainer
var _insp_body: HBoxContainer
var _inspeccionado_id: int = -1

# Modal general (Tienda / Almacén / Mejoras / Conversión / Confirmar venta)
var _modal: Control
var _modal_card: PanelContainer
var _modal_body: VBoxContainer
var _modal_titulo: Label
var _modal_sub: Label
var _modal_badge: Panel
var _modal_icono: TextureRect
var _filtro_tienda: String = "todo"

# Toast y conversión / ingreso
var _toast: PanelContainer
var _toast_lbl: Label
var _toast_tween: Tween
var _spin_cambio: SpinBox
var _lbl_preview: Label
var _lbl_tasa: Label
var _tab_banco: String = "cobrar"  # "cobrar" (MG -> €) | "ingresar" (€ -> MG 1:1)

# Estado de interacción
var _modo: String = "normal"  # "normal" | "colocar" | "mover" | "vender" | "sembrar"
var _orientacion_aplicada: bool = false
var _quit_on_go_back_previo: bool = true
var _cerrado: bool = false
var _refresco_acumulado: float = 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_quit_on_go_back_previo = get_tree().is_quit_on_go_back()
	get_tree().set_quit_on_go_back(false)
	_Aplicar_Orientacion_Horizontal()
	_Construir_UI()
	resized.connect(_Reposicionar_HUD)
	_Reposicionar_HUD()
	_Actualizar_Todo()
	set_process(true)


func _exit_tree() -> void:
	if get_tree() != null:
		get_tree().set_quit_on_go_back(_quit_on_go_back_previo)
	if _orientacion_aplicada:
		_Aplicar_Orientacion_Vertical()


func _process(delta: float) -> void:
	_refresco_acumulado += delta
	if _refresco_acumulado >= 0.30:
		_refresco_acumulado = 0.0
		_Actualizar_Todo()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_Volver_Atras()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed and not k.echo:
			if k.keycode == KEY_R and (_modo == "colocar" or (_modo == "mover" and _mundo != null and bool(_mundo.datos_ghost().get("activo", false)))):
				_Rotar_Ghost()
				get_viewport().set_input_as_handled()
			elif k.keycode == KEY_EQUAL or k.keycode == KEY_KP_ADD:
				if _mundo != null:
					_mundo.ajustar_zoom(1.14)
				get_viewport().set_input_as_handled()
			elif k.keycode == KEY_MINUS or k.keycode == KEY_KP_SUBTRACT:
				if _mundo != null:
					_mundo.ajustar_zoom(1.0 / 1.14)
				get_viewport().set_input_as_handled()


func _notification(que: int) -> void:
	if que == NOTIFICATION_WM_GO_BACK_REQUEST:
		_Volver_Atras()


func _Volver_Atras() -> void:
	if _modal != null and _modal.visible:
		_Cerrar_Modal()
		return
	if _modo != "normal":
		_Establecer_Modo("normal")
		return
	if _inspeccionado_id >= 0:
		_Cerrar_Inspector()
		return
	_Cerrar()


func _Cerrar() -> void:
	if _cerrado:
		return
	_cerrado = true
	Guardar_Variables_Dinamicas.save_game()
	cerrado.emit()


# ------------------------------------------------------------------
# Orientación horizontal 1280×720
# ------------------------------------------------------------------

func _Aplicar_Orientacion_Horizontal() -> void:
	_orientacion_aplicada = true
	if DisplayServer.get_name().to_lower() in ["android", "ios"]:
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
	var win: Window = get_window()
	if win != null:
		win.content_scale_size = TAMANO_HORIZONTAL
	if OS.has_feature("pc") and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_size(TAMANO_HORIZONTAL)
		var pantalla := DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
		DisplayServer.window_set_position(Vector2i(
			maxi(0, (pantalla.x - TAMANO_HORIZONTAL.x) / 2),
			maxi(0, (pantalla.y - TAMANO_HORIZONTAL.y) / 2)))


func _Aplicar_Orientacion_Vertical() -> void:
	_orientacion_aplicada = false
	if DisplayServer.get_name().to_lower() in ["android", "ios"]:
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	var win: Window = get_window()
	if win != null:
		win.content_scale_size = TAMANO_VERTICAL
	if OS.has_feature("pc") and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_size(TAMANO_VERTICAL)
		var pantalla := DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
		DisplayServer.window_set_position(Vector2i(
			maxi(0, (pantalla.x - TAMANO_VERTICAL.x) / 2),
			maxi(0, (pantalla.y - TAMANO_VERTICAL.y) / 2)))


# ------------------------------------------------------------------
# Construcción de la pantalla y HUD
# ------------------------------------------------------------------

func _Construir_UI() -> void:
	_mundo = MundoGranja.new()
	_mundo.name = "Mundo_Granja"
	_mundo.anchor_left = 0.0
	_mundo.anchor_top = 0.0
	_mundo.anchor_right = 1.0
	_mundo.anchor_bottom = 1.0
	_mundo.offset_left = 0.0
	_mundo.offset_top = 0.0
	_mundo.offset_right = 0.0
	_mundo.offset_bottom = 0.0
	_mundo.objeto_tocado.connect(_on_objeto_tocado)
	_mundo.terreno_vacio_tocado.connect(_on_terreno_vacio_tocado)
	_mundo.ampliacion_tocada.connect(_Abrir_Mejoras)
	_mundo.colocar_solicitado.connect(_on_colocar_solicitado)
	_mundo.ghost_movido.connect(_on_ghost_movido)
	_mundo.cancelar_solicitado.connect(_Volver_Atras)
	add_child(_mundo)

	_capa_flotantes = Control.new()
	_capa_flotantes.name = "Capa_Flotantes"
	_capa_flotantes.set_anchors_preset(Control.PRESET_FULL_RECT)
	_capa_flotantes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_capa_flotantes.z_index = 220
	add_child(_capa_flotantes)

	_Construir_Cabecera()
	_Construir_Banner_Modo()
	_Construir_Controles_Camara()
	_Construir_Dock_Inferior()
	_Construir_Barra_Ghost()
	_Construir_Barra_Siembra()
	_Construir_Tarjeta_Inspector()
	_Construir_Modal()
	_Construir_Toast()


func _Construir_Cabecera() -> void:
	_cabecera = Control.new()
	_cabecera.name = "Cabecera"
	_cabecera.position = Vector2(18, 12)
	_cabecera.size = Vector2(1244, 62)
	_cabecera.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cabecera.z_index = 240
	add_child(_cabecera)

	# Tarjeta izquierda: Medallón + título + medidor visual de terreno usado.
	var izq := PanelContainer.new()
	izq.position = Vector2(0, 0)
	izq.custom_minimum_size = Vector2(316, 60)
	izq.add_theme_stylebox_override("panel",
		Estilo.panel_madera(Color(1.0, 0.98, 0.92, 0.96), Color("#4d7c0f"), 18, 2, 7))
	_cabecera.add_child(izq)

	var mi := MarginContainer.new()
	mi.add_theme_constant_override("margin_left", 10)
	mi.add_theme_constant_override("margin_right", 14)
	mi.add_theme_constant_override("margin_top", 6)
	mi.add_theme_constant_override("margin_bottom", 6)
	izq.add_child(mi)

	var hi := HBoxContainer.new()
	hi.add_theme_constant_override("separation", 10)
	hi.alignment = BoxContainer.ALIGNMENT_CENTER
	mi.add_child(hi)

	hi.add_child(Estilos_UI.badge_icono("leaf", 40, 22, Color("#65a30d"), Color.WHITE, 12))

	var tit := VBoxContainer.new()
	tit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tit.add_theme_constant_override("separation", 2)
	tit.alignment = BoxContainer.ALIGNMENT_CENTER
	hi.add_child(tit)

	var fila_tit := HBoxContainer.new()
	fila_tit.add_theme_constant_override("separation", 8)
	tit.add_child(fila_tit)
	fila_tit.add_child(Estilos_UI.titulo("LA GRANJA", 19, Estilo.VERDE_BOSQUE))
	_lbl_estado_granja = Estilos_UI.texto("36/144 u²", 11, Color("#4d7c0f"), 700)
	_lbl_estado_granja.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila_tit.add_child(_lbl_estado_granja)

	# Mini barra de ocupación de terreno.
	var barra_bg := Panel.new()
	barra_bg.custom_minimum_size = Vector2(226, 7)
	barra_bg.size = Vector2(226, 7)
	barra_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st_bg := StyleBoxFlat.new()
	st_bg.bg_color = Color("#e7dfc8")
	st_bg.set_corner_radius_all(4)
	barra_bg.add_theme_stylebox_override("panel", st_bg)
	tit.add_child(barra_bg)

	_barra_area_fill = Panel.new()
	_barra_area_fill.position = Vector2(0, 0)
	_barra_area_fill.size = Vector2(60, 7)
	_barra_area_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st_fill := StyleBoxFlat.new()
	st_fill.bg_color = Color("#65a30d")
	st_fill.set_corner_radius_all(4)
	_barra_area_fill.add_theme_stylebox_override("panel", st_fill)
	barra_bg.add_child(_barra_area_fill)

	# Bloque derecho: MG, €, +MG (ingresar 1:1), Cobrar y Cerrar.
	_cabecera_der = HBoxContainer.new()
	_cabecera_der.position = Vector2(540, 5)
	_cabecera_der.size = Vector2(704, 50)
	_cabecera_der.alignment = BoxContainer.ALIGNMENT_END
	_cabecera_der.add_theme_constant_override("separation", 8)
	_cabecera_der.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cabecera.add_child(_cabecera_der)

	var chip_mg := _Crear_Chip("coins", Color("#d97706"), Color("#fffbeb"), Color("#d97706"))
	_cabecera_der.add_child(chip_mg[0])
	_lbl_mg = chip_mg[1]

	var chip_eur := _Crear_Chip("euro", Color("#16a34a"), Color("#f0fdf4"), Color("#15803d"))
	_cabecera_der.add_child(chip_eur[0])
	_lbl_dinero = chip_eur[1]

	_btn_ingresar = Estilo.crear_boton_hud(
		"MG", "plus", Color.WHITE,
		Estilo.VERDE, Color("#15803d"), Color.WHITE, 92.0, 48.0)
	_btn_ingresar.tooltip_text = "Ingresar euros a MG (1:1)"
	_btn_ingresar.pressed.connect(func() -> void: _Abrir_Conversion("ingresar"))
	_cabecera_der.add_child(_btn_ingresar)

	_btn_cobrar = Estilo.crear_boton_hud(
		"Cobrar", "hand-coins", Color.WHITE,
		Color("#f59e0b"), Color("#b45309"), Color.WHITE, 122.0, 48.0)
	_btn_cobrar.tooltip_text = "Cambiar MG a euros del Sim"
	_btn_cobrar.pressed.connect(func() -> void: _Abrir_Conversion("cobrar"))
	_cabecera_der.add_child(_btn_cobrar)

	var btn_cerrar := Estilo.crear_boton_hud(
		"", "x", Estilo.VERDE_BOSQUE,
		Estilo.CREMA, Estilo.MADERA, Estilo.VERDE_BOSQUE, 48.0, 48.0)
	btn_cerrar.tooltip_text = "Volver al Sim"
	btn_cerrar.pressed.connect(_Cerrar)
	_cabecera_der.add_child(btn_cerrar)


func _Crear_Chip(icono: String, color: Color, fondo: Color, borde: Color) -> Array:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Estilo.panel_madera(fondo, borde, 23, 2, 5))
	panel.custom_minimum_size = Vector2(146, 48)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 8)
	m.add_theme_constant_override("margin_right", 14)
	m.add_theme_constant_override("margin_top", 4)
	m.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(m)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	m.add_child(h)
	h.add_child(Estilos_UI.badge_icono(icono, 28, 15, color, Color.WHITE, 14))
	var lbl := Estilos_UI.texto("0", 15, color.darkened(0.32), 700)
	h.add_child(lbl)
	return [panel, lbl]


func _Construir_Banner_Modo() -> void:
	_banner_modo = PanelContainer.new()
	_banner_modo.name = "Banner_Modo"
	_banner_modo.position = Vector2(360, 76)
	_banner_modo.size = Vector2(560, 36)
	_banner_modo.visible = false
	_banner_modo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_modo.z_index = 250
	_banner_modo.add_theme_stylebox_override("panel",
		Estilo.panel_madera(Estilo.ROJO, Color("#991b1b"), 18, 2, 5))
	add_child(_banner_modo)

	_banner_modo_lbl = Estilos_UI.texto("", 13, Color.WHITE, 700)
	_banner_modo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_modo_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner_modo_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_modo.add_child(_banner_modo_lbl)


func _Construir_Controles_Camara() -> void:
	_controles_camara = PanelContainer.new()
	_controles_camara.name = "Controles_Camara"
	_controles_camara.position = Vector2(1214, 260)
	_controles_camara.custom_minimum_size = Vector2(48, 156)
	_controles_camara.z_index = 235
	_controles_camara.add_theme_stylebox_override("panel", Estilo.panel_dock(Color(1.0, 0.98, 0.92, 0.92), Estilo.MADERA_CLARA, 18))
	add_child(_controles_camara)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 5)
	m.add_theme_constant_override("margin_right", 5)
	m.add_theme_constant_override("margin_top", 6)
	m.add_theme_constant_override("margin_bottom", 6)
	_controles_camara.add_child(m)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	m.add_child(v)

	var btn_mas := Estilo.crear_boton_hud("+", "", Estilo.TINTA, Estilo.CREMA, Estilo.MADERA_CLARA, Estilo.TINTA, 36, 40, 18)
	btn_mas.tooltip_text = "Acercar cámara"
	btn_mas.pressed.connect(func() -> void: _mundo.ajustar_zoom(1.18))
	v.add_child(btn_mas)

	var btn_menos := Estilo.crear_boton_hud("−", "", Estilo.TINTA, Estilo.CREMA, Estilo.MADERA_CLARA, Estilo.TINTA, 36, 40, 18)
	btn_menos.tooltip_text = "Alejar cámara"
	btn_menos.pressed.connect(func() -> void: _mundo.ajustar_zoom(1.0 / 1.18))
	v.add_child(btn_menos)

	var btn_centrar := Estilo.crear_boton_hud("", "target", Estilo.VERDE_BOSQUE, Color("#ecfccb"), Color("#65a30d"), Estilo.VERDE_BOSQUE, 36, 40, 15)
	btn_centrar.tooltip_text = "Centrar granja"
	btn_centrar.pressed.connect(func() -> void: _mundo.centrar_camara(false))
	v.add_child(btn_centrar)


func _Construir_Dock_Inferior() -> void:
	_dock_principal = Control.new()
	_dock_principal.name = "Barra_Inferior"
	_dock_principal.position = Vector2(18, 640)
	_dock_principal.size = Vector2(1244, 66)
	_dock_principal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dock_principal.z_index = 240
	add_child(_dock_principal)

	# Bandeja izquierda (Construir · Almacén · Mejoras).
	var bandeja_izq := PanelContainer.new()
	bandeja_izq.position = Vector2(0, 0)
	bandeja_izq.add_theme_stylebox_override("panel", Estilo.panel_dock())
	_dock_principal.add_child(bandeja_izq)

	var mi := MarginContainer.new()
	mi.add_theme_constant_override("margin_left", 8)
	mi.add_theme_constant_override("margin_right", 8)
	mi.add_theme_constant_override("margin_top", 6)
	mi.add_theme_constant_override("margin_bottom", 8)
	bandeja_izq.add_child(mi)

	var izq := HBoxContainer.new()
	izq.add_theme_constant_override("separation", 8)
	mi.add_child(izq)

	_btn_construir = Estilo.crear_boton_hud(
		"Construir", "store", Color.WHITE,
		Color("#ea580c"), Color("#9a3412"), Color.WHITE, 146.0, 48.0)
	_btn_construir.pressed.connect(func() -> void: _Abrir_Tienda("todo"))
	izq.add_child(_btn_construir)

	_btn_almacen = Estilo.crear_boton_hud(
		"Almacén (0)", "package", Estilo.AZUL,
		Color("#f0f9ff"), Estilo.AZUL, Color("#0c4a6e"), 166.0, 48.0)
	_btn_almacen.pressed.connect(_Abrir_Almacen)
	izq.add_child(_btn_almacen)

	_btn_mejoras = Estilo.crear_boton_hud(
		"Mejoras", "hammer", Estilo.MORADO,
		Color("#f5f3ff"), Estilo.MORADO, Color("#4c1d95"), 148.0, 48.0)
	_btn_mejoras.pressed.connect(_Abrir_Mejoras)
	izq.add_child(_btn_mejoras)

	# Bandeja derecha (Recoger · Mover · Vender · Volver).
	_dock_der = HBoxContainer.new()
	_dock_der.position = Vector2(560, 6)
	_dock_der.size = Vector2(684, 52)
	_dock_der.alignment = BoxContainer.ALIGNMENT_END
	_dock_der.add_theme_constant_override("separation", 8)
	_dock_der.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dock_principal.add_child(_dock_der)

	_btn_recoger_todo = Estilo.crear_boton_hud(
		"Recoger (0)", "sparkles", Color.WHITE,
		Estilo.VERDE, Color("#15803d"), Color.WHITE, 152.0, 48.0)
	_btn_recoger_todo.visible = false
	_btn_recoger_todo.pressed.connect(_Recoger_Todo)
	_dock_der.add_child(_btn_recoger_todo)

	_btn_mover_modo = Estilo.crear_boton_hud(
		"Mover", "hand", Estilo.AZUL,
		Color("#f0f9ff"), Estilo.AZUL, Color("#0c4a6e"), 120.0, 48.0)
	_btn_mover_modo.pressed.connect(func() -> void:
		_Establecer_Modo("normal" if _modo == "mover" else "mover"))
	_dock_der.add_child(_btn_mover_modo)

	_btn_vender_modo = Estilo.crear_boton_hud(
		"Vender", "coins", Estilo.ROJO,
		Color("#fef2f2"), Estilo.ROJO, Color("#991b1b"), 124.0, 48.0)
	_btn_vender_modo.pressed.connect(func() -> void:
		_Establecer_Modo("normal" if _modo == "vender" else "vender"))
	_dock_der.add_child(_btn_vender_modo)

	var btn_volver := Estilo.crear_boton_hud(
		"Volver", "arrow-left", Estilo.TINTA,
		Estilo.CREMA, Estilo.MADERA, Estilo.TINTA, 116.0, 48.0)
	btn_volver.pressed.connect(_Cerrar)
	_dock_der.add_child(btn_volver)


func _Reposicionar_HUD() -> void:
	var w: float = size.x if size.x > 100.0 else float(TAMANO_HORIZONTAL.x)
	var h: float = size.y if size.y > 100.0 else float(TAMANO_HORIZONTAL.y)
	if _cabecera != null:
		_cabecera.position = Vector2(18.0, 12.0)
		_cabecera.size = Vector2(w - 36.0, 62.0)
	if _cabecera_der != null:
		_cabecera_der.position = Vector2(maxf(336.0, w - 36.0 - 704.0), 5.0)
	if _banner_modo != null:
		_banner_modo.position = Vector2((w - _banner_modo.size.x) * 0.5, 76.0)
	if _controles_camara != null:
		_controles_camara.position = Vector2(w - 66.0, (h - 156.0) * 0.5)
	if _dock_principal != null:
		_dock_principal.position = Vector2(18.0, h - 80.0)
		_dock_principal.size = Vector2(w - 36.0, 66.0)
	if _dock_der != null:
		_dock_der.position = Vector2(maxf(488.0, w - 36.0 - 684.0), 6.0)
	if _barra_ghost != null:
		_barra_ghost.size = Vector2(860.0, 78.0)
		_barra_ghost.position = Vector2((w - _barra_ghost.size.x) * 0.5, h - 92.0)
	if _barra_siembra != null:
		_barra_siembra.size = Vector2(880.0, 88.0)
		_barra_siembra.position = Vector2((w - _barra_siembra.size.x) * 0.5, h - 102.0)
	if _tarjeta_inspector != null:
		_tarjeta_inspector.position = Vector2((w - _tarjeta_inspector.size.x) * 0.5, h - 172.0)
	if _modal_card != null:
		_modal_card.position = Vector2((w - _modal_card.size.x) * 0.5, maxf(24.0, (h - _modal_card.size.y) * 0.5))
	if _toast != null:
		_toast.position.x = (w - _toast.size.x) * 0.5


# ------------------------------------------------------------------
# Barras contextuales flotantes: Ghost (colocar/mover), Siembra rápida, Inspector
# ------------------------------------------------------------------

func _Construir_Barra_Ghost() -> void:
	_barra_ghost = PanelContainer.new()
	_barra_ghost.name = "Barra_Ghost"
	_barra_ghost.position = Vector2(210, 628)
	_barra_ghost.size = Vector2(860, 78)
	_barra_ghost.visible = false
	_barra_ghost.z_index = 260
	_barra_ghost.add_theme_stylebox_override("panel", Estilo.panel_dock(Color(1.0, 0.98, 0.92, 0.97), Estilo.VERDE, 22))
	add_child(_barra_ghost)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 14)
	m.add_theme_constant_override("margin_right", 14)
	m.add_theme_constant_override("margin_top", 8)
	m.add_theme_constant_override("margin_bottom", 10)
	_barra_ghost.add_child(m)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	m.add_child(h)

	_ghost_ico = IconoProducto.new()
	_ghost_ico.custom_minimum_size = Vector2(52, 52)
	h.add_child(_ghost_ico)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(col)

	_ghost_titulo = Estilos_UI.titulo("Colocando Molino · 4×4", 16, Estilo.TINTA)
	col.add_child(_ghost_titulo)
	_ghost_estado = Estilos_UI.texto("Toca el mapa para colocar", 12, Color("#15803d"), 600)
	col.add_child(_ghost_estado)

	_btn_ghost_rotar = Estilo.crear_boton_hud(
		"Girar (R)", "rotate-ccw", Estilo.AZUL,
		Estilo.AZUL_SUAVE, Estilo.AZUL, Color("#0c4a6e"), 124.0, 46.0, 13)
	_btn_ghost_rotar.pressed.connect(_Rotar_Ghost)
	h.add_child(_btn_ghost_rotar)

	_btn_ghost_confirmar = Estilo.crear_boton_hud(
		"Colocar aquí", "check", Color.WHITE,
		Estilo.VERDE, Color("#15803d"), Color.WHITE, 148.0, 46.0, 13)
	_btn_ghost_confirmar.pressed.connect(func() -> void:
		var g: Dictionary = _mundo.datos_ghost()
		if bool(g.get("activo", false)):
			_on_colocar_solicitado(int(g.get("gx", 0)), int(g.get("gy", 0))))
	h.add_child(_btn_ghost_confirmar)

	var btn_cancelar := Estilo.crear_boton_hud(
		"Listo", "x", Estilo.ROJO,
		Estilo.ROJO_SUAVE, Estilo.ROJO, Color("#991b1b"), 102.0, 46.0, 13)
	btn_cancelar.pressed.connect(func() -> void: _Establecer_Modo("normal"))
	h.add_child(btn_cancelar)


func _Construir_Barra_Siembra() -> void:
	_barra_siembra = PanelContainer.new()
	_barra_siembra.name = "Barra_Siembra"
	_barra_siembra.position = Vector2(200, 618)
	_barra_siembra.custom_minimum_size = Vector2(880, 88)
	_barra_siembra.size = Vector2(880, 88)
	_barra_siembra.visible = false
	_barra_siembra.z_index = 260
	_barra_siembra.add_theme_stylebox_override("panel", Estilo.panel_dock(Color(1.0, 0.99, 0.93, 0.98), Color("#65a30d"), 22))
	add_child(_barra_siembra)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 14)
	m.add_theme_constant_override("margin_right", 14)
	m.add_theme_constant_override("margin_top", 8)
	m.add_theme_constant_override("margin_bottom", 10)
	_barra_siembra.add_child(m)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	m.add_child(h)

	var col_info := VBoxContainer.new()
	col_info.custom_minimum_size = Vector2(150, 0)
	col_info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col_info.alignment = BoxContainer.ALIGNMENT_CENTER
	col_info.add_theme_constant_override("separation", 1)
	h.add_child(col_info)
	col_info.add_child(Estilos_UI.titulo("Sembrar", 16, Estilo.VERDE_BOSQUE))
	_siembra_sub = Estilos_UI.texto("Elige cultivo", 11, Estilo.TINTA_SUAVE, 600)
	_siembra_sub.custom_minimum_size = Vector2(146, 0)
	_siembra_sub.clip_text = true
	col_info.add_child(_siembra_sub)

	for clave in ["trigo", "zanahoria", "maiz"]:
		var d: Dictionary = Datos.CULTIVOS[clave]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(174, 62)
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		Estilo.aplicar_boton(btn, Color("#fffdf5"), Color("#65a30d"), Estilo.TINTA, Color.WHITE, 14, 8)
		btn.pressed.connect(Callable(self, "_Seleccionar_Semilla_Rapida").bind(clave))

		var bh := HBoxContainer.new()
		bh.anchor_left = 0.0
		bh.anchor_top = 0.0
		bh.anchor_right = 1.0
		bh.anchor_bottom = 1.0
		bh.offset_left = 8
		bh.offset_top = 4
		bh.offset_right = -8
		bh.offset_bottom = -6
		bh.add_theme_constant_override("separation", 8)
		bh.alignment = BoxContainer.ALIGNMENT_CENTER
		bh.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(bh)

		var ico := IconoProducto.new()
		ico.custom_minimum_size = Vector2(42, 42)
		ico.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ico.configurar(clave)
		bh.add_child(ico)

		var bc := VBoxContainer.new()
		bc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bc.alignment = BoxContainer.ALIGNMENT_CENTER
		bc.add_theme_constant_override("separation", 0)
		bc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bh.add_child(bc)

		var l_nom := Estilos_UI.titulo(str(d["nombre"]), 14, Estilo.TINTA)
		l_nom.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bc.add_child(l_nom)
		var l_det := Estilos_UI.texto("%d MG · %s" % [int(d["coste"]), Sistema_Granja.Formatear_Tiempo(Sistema_Granja.Duracion_Segundos(float(d["horas"])))], 11, Estilo.TINTA_SUAVE, 700)
		l_det.name = "Detalle"
		l_det.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bc.add_child(l_det)

		_siembra_botones[clave] = btn
		h.add_child(btn)

	# Botones rápidos de mover / cerrar
	var btn_mover_p := Estilo.crear_boton_hud("", "hand", Estilo.AZUL, Estilo.AZUL_SUAVE, Estilo.AZUL, Estilo.AZUL, 46, 56)
	btn_mover_p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn_mover_p.tooltip_text = "Mover esta parcela"
	btn_mover_p.pressed.connect(func() -> void:
		var pid: int = _parcela_siembra_id
		if pid >= 0:
			_Iniciar_Mover_Objeto(pid))
	h.add_child(btn_mover_p)

	var btn_cerrar_s := Estilo.crear_boton_hud("Listo", "check", Color.WHITE, Estilo.VERDE, Color("#15803d"), Color.WHITE, 96, 56, 13)
	btn_cerrar_s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn_cerrar_s.pressed.connect(func() -> void: _Establecer_Modo("normal"))
	h.add_child(btn_cerrar_s)


func _Construir_Tarjeta_Inspector() -> void:
	_tarjeta_inspector = PanelContainer.new()
	_tarjeta_inspector.name = "Tarjeta_Inspector"
	_tarjeta_inspector.position = Vector2(280, 548)
	_tarjeta_inspector.size = Vector2(720, 80)
	_tarjeta_inspector.visible = false
	_tarjeta_inspector.z_index = 255
	_tarjeta_inspector.add_theme_stylebox_override("panel", Estilo.panel_dock(Color(1.0, 0.99, 0.94, 0.97), Estilo.MADERA, 20))
	add_child(_tarjeta_inspector)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 14)
	m.add_theme_constant_override("margin_right", 14)
	m.add_theme_constant_override("margin_top", 8)
	m.add_theme_constant_override("margin_bottom", 10)
	_tarjeta_inspector.add_child(m)

	_insp_body = HBoxContainer.new()
	_insp_body.add_theme_constant_override("separation", 12)
	_insp_body.alignment = BoxContainer.ALIGNMENT_CENTER
	m.add_child(_insp_body)


# ------------------------------------------------------------------
# Modal base (Tienda / Almacén / Mejoras / Conversión / Venta)
# ------------------------------------------------------------------

func _Construir_Modal() -> void:
	_modal = Control.new()
	_modal.name = "Modal_Granja"
	_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal.visible = false
	_modal.z_index = 300
	add_child(_modal)

	var velo := ColorRect.new()
	velo.color = Color(0.04, 0.10, 0.04, 0.56)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	velo.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal.add_child(velo)

	_modal_card = PanelContainer.new()
	_modal_card.position = Vector2(170, 56)
	_modal_card.size = Vector2(940, 608)
	_modal_card.add_theme_stylebox_override("panel",
		Estilo.panel_madera(Estilo.CREMA, Estilo.MADERA_OSCURA, 24, 3, 14))
	_modal.add_child(_modal_card)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	_modal_card.add_child(v)

	var header := PanelContainer.new()
	header.custom_minimum_size = Vector2(0, 78)
	var st_h := StyleBoxFlat.new()
	st_h.bg_color = Estilo.VERDE_BOSQUE
	st_h.border_color = Color("#0f3f22")
	st_h.border_width_bottom = 4
	st_h.corner_radius_top_left = 20
	st_h.corner_radius_top_right = 20
	st_h.anti_aliasing = true
	header.add_theme_stylebox_override("panel", st_h)
	v.add_child(header)

	var hm := MarginContainer.new()
	hm.add_theme_constant_override("margin_left", 20)
	hm.add_theme_constant_override("margin_right", 14)
	hm.add_theme_constant_override("margin_top", 12)
	hm.add_theme_constant_override("margin_bottom", 12)
	header.add_child(hm)

	var hh := HBoxContainer.new()
	hh.add_theme_constant_override("separation", 12)
	hm.add_child(hh)

	_modal_badge = Panel.new()
	_modal_badge.custom_minimum_size = Vector2(48, 48)
	_modal_badge.size = Vector2(48, 48)
	_modal_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_modal_badge.add_theme_stylebox_override("panel", Estilo.panel_madera(Estilo.VERDE, Color("#15803d"), 14, 2, 0))
	hh.add_child(_modal_badge)

	_modal_icono = TextureRect.new()
	_modal_icono.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_icono.offset_left = 12
	_modal_icono.offset_top = 12
	_modal_icono.offset_right = -12
	_modal_icono.offset_bottom = -12
	_modal_icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_modal_icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_modal_icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_modal_badge.add_child(_modal_icono)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 0)
	hh.add_child(col)
	_modal_titulo = Estilos_UI.titulo("Título", 22, Color.WHITE)
	col.add_child(_modal_titulo)
	_modal_sub = Estilos_UI.texto("Subtítulo", 12, Color("#bbf7d0"), 500)
	col.add_child(_modal_sub)

	var btn_cerrar := Estilo.crear_boton_hud("", "x", Estilo.VERDE_BOSQUE, Estilo.CREMA, Color("#9b642c"), Estilo.VERDE_BOSQUE, 42, 42)
	btn_cerrar.pressed.connect(_Cerrar_Modal)
	hh.add_child(btn_cerrar)

	var body_margen := MarginContainer.new()
	body_margen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_margen.add_theme_constant_override("margin_left", 22)
	body_margen.add_theme_constant_override("margin_right", 22)
	body_margen.add_theme_constant_override("margin_top", 14)
	body_margen.add_theme_constant_override("margin_bottom", 16)
	v.add_child(body_margen)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body_margen.add_child(scroll)

	_modal_body = VBoxContainer.new()
	_modal_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_modal_body.add_theme_constant_override("separation", 10)
	scroll.add_child(_modal_body)


func _Abrir_Modal(titulo: String, subtitulo: String, icono: String, color: Color) -> void:
	_Cerrar_Inspector()
	_spin_cambio = null
	_lbl_preview = null
	_lbl_tasa = null
	_modal_titulo.text = titulo
	_modal_sub.text = subtitulo
	_modal_icono.texture = Estilos_UI.icono(icono)
	_modal_icono.modulate = Color.WHITE
	var st := _modal_badge.get_theme_stylebox("panel") as StyleBoxFlat
	if st != null:
		st.bg_color = color
		st.border_color = color.darkened(0.25)
	for hijo in _modal_body.get_children():
		hijo.queue_free()
	_modal.visible = true
	_modal_card.pivot_offset = _modal_card.size * 0.5
	_modal_card.scale = Vector2(0.95, 0.95)
	_modal_card.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_modal_card, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_modal_card, "modulate:a", 1.0, 0.14)


func _Cerrar_Modal() -> void:
	if _modal != null:
		_modal.visible = false
	_spin_cambio = null
	_lbl_preview = null
	_lbl_tasa = null


func _Titulo_Seccion(texto: String, color: Color = Estilo.VERDE_BOSQUE) -> Label:
	var lbl := Estilos_UI.titulo(texto, 14, color)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return lbl


func _Parrafo(texto: String, color: Color = Estilo.TINTA_SUAVE) -> Label:
	return Estilos_UI.parrafo(texto, 12, color)


func _Icono_Prod(clave: String, tam: float = 54.0) -> IconoProducto:
	var ico := IconoProducto.new()
	ico.custom_minimum_size = Vector2(tam, tam)
	ico.configurar(clave)
	return ico


# ------------------------------------------------------------------
# Modos de interacción (normal / colocar / mover / vender / sembrar)
# ------------------------------------------------------------------

func _Establecer_Modo(nuevo_modo: String) -> void:
	_modo = nuevo_modo
	if _modo != "sembrar":
		_semilla_activa = ""
		_parcela_siembra_id = -1
	if _modo != "normal":
		_Cerrar_Inspector()

	var ghost_vis: bool = (_modo == "colocar") or (_modo == "mover" and _mundo != null and bool(_mundo.datos_ghost().get("activo", false)))
	if _barra_ghost != null:
		_barra_ghost.visible = ghost_vis
	if _barra_siembra != null:
		_barra_siembra.visible = (_modo == "sembrar")
	if _dock_principal != null:
		_dock_principal.visible = not ghost_vis and _modo != "sembrar"

	if _banner_modo != null:
		var st := _banner_modo.get_theme_stylebox("panel") as StyleBoxFlat
		if _modo == "vender":
			_banner_modo.visible = true
			_banner_modo_lbl.text = "Modo vender · toca cualquier objeto para venderlo al 50 %"
			if st != null:
				st.bg_color = Estilo.ROJO
				st.border_color = Color("#991b1b")
		elif _modo == "mover":
			_banner_modo.visible = true
			_banner_modo_lbl.text = "Modo mover · toca un elemento para recolocarlo gratis en el mapa"
			if st != null:
				st.bg_color = Estilo.AZUL
				st.border_color = Color("#0369a1")
		elif _modo == "sembrar" and _semilla_activa != "":
			_banner_modo.visible = true
			_banner_modo_lbl.text = "Siembra rápida (%s) · toca otras parcelas vacías o pulsa Listo" % Datos.nombre(_semilla_activa)
			if st != null:
				st.bg_color = Estilo.VERDE
				st.border_color = Color("#15803d")
		else:
			_banner_modo.visible = false

	# Estilizar botones activos de Mover / Vender en el dock.
	if _btn_vender_modo != null:
		if _modo == "vender":
			_btn_vender_modo.text = "Salir venta"
			Estilo.aplicar_boton(_btn_vender_modo, Estilo.ROJO, Color("#991b1b"), Color.WHITE, Color.WHITE)
		else:
			_btn_vender_modo.text = "Vender"
			Estilo.aplicar_boton(_btn_vender_modo, Color("#fef2f2"), Estilo.ROJO, Color("#991b1b"), Estilo.ROJO)
	if _btn_mover_modo != null:
		if _modo == "mover":
			_btn_mover_modo.text = "Salir mover"
			Estilo.aplicar_boton(_btn_mover_modo, Estilo.AZUL, Color("#0369a1"), Color.WHITE, Color.WHITE)
		else:
			_btn_mover_modo.text = "Mover"
			Estilo.aplicar_boton(_btn_mover_modo, Color("#f0f9ff"), Estilo.AZUL, Color("#0c4a6e"), Estilo.AZUL)

	if _mundo != null:
		_mundo.establecer_modo(_modo, _inspeccionado_id)
	_Actualizar_Todo()


func _Establecer_Modo_Vender(activo: bool) -> void:
	_Establecer_Modo("vender" if activo else "normal")


func _Iniciar_Colocacion(categoria: String, tipo: String) -> void:
	_Cerrar_Modal()
	_Establecer_Modo("colocar")
	_mundo.iniciar_ghost(categoria, tipo, false, false, -1)
	_Refrescar_Barra_Ghost()


func _Iniciar_Mover_Objeto(objeto_id: int) -> void:
	var info: Dictionary = Sistema_Granja.Estado_Objeto(objeto_id)
	if not bool(info.get("valida", false)):
		return
	_Cerrar_Inspector()
	_modo = "mover"
	_mundo.establecer_modo("mover", -1)
	_mundo.iniciar_ghost(
		str(info["categoria"]), str(info["tipo"]),
		bool(info["rotado"]), bool(info["volteado"]),
		objeto_id, int(info["x"]), int(info["y"]))
	_Establecer_Modo("mover")
	_Refrescar_Barra_Ghost()


func _Rotar_Ghost() -> void:
	if _mundo == null:
		return
	_mundo.rotar_o_voltear_ghost()
	_Sonido("click", -10.0)
	_Refrescar_Barra_Ghost()


func _Refrescar_Barra_Ghost() -> void:
	if _barra_ghost == null or _mundo == null:
		return
	var g: Dictionary = _mundo.datos_ghost()
	if not bool(g.get("activo", false)):
		_barra_ghost.visible = false
		return
	_barra_ghost.visible = true
	if _dock_principal != null:
		_dock_principal.visible = false

	var cat: String = str(g["categoria"])
	var tipo: String = str(g["tipo"])
	var rot: bool = bool(g["rotado"])
	var valido: bool = bool(g["valido"])
	var ignorar_id: int = int(g["ignorar_id"])
	var tam := Datos.tamano_objeto(cat, tipo, rot)
	var nombre_obj: String = Datos.nombre(tipo)

	_ghost_ico.configurar("tierra" if cat == "tierra" else tipo)
	if ignorar_id >= 0:
		_ghost_titulo.text = "Moviendo %s · %d×%d (gratis)" % [nombre_obj, tam.x, tam.y]
		_btn_ghost_confirmar.text = "Soltar aquí"
	else:
		var coste: int = Datos.precio_construccion(cat, tipo)
		_ghost_titulo.text = "Colocando %s · %d×%d · %d MG" % [nombre_obj, tam.x, tam.y, coste]
		_btn_ghost_confirmar.text = "Colocar aquí"

	_btn_ghost_rotar.text = "Girar (R)" if Datos.es_rotable(cat, tipo) else "Voltear (R)"
	_btn_ghost_confirmar.disabled = not valido

	var st := _barra_ghost.get_theme_stylebox("panel") as StyleBoxFlat
	if valido:
		_ghost_estado.text = "✓ Posición libre (%d, %d) · toca el mapa para confirmar" % [int(g["gx"]), int(g["gy"])]
		_ghost_estado.add_theme_color_override("font_color", Color("#15803d"))
		if st != null:
			st.border_color = Estilo.VERDE
	else:
		_ghost_estado.text = "✕ %s" % str(g.get("motivo", "No cabe ahí"))
		_ghost_estado.add_theme_color_override("font_color", Estilo.ROJO)
		if st != null:
			st.border_color = Estilo.ROJO


func _on_ghost_movido(_gx: int, _gy: int, _valido: bool) -> void:
	_Refrescar_Barra_Ghost()


func _on_colocar_solicitado(gx: int, gy: int) -> void:
	if _mundo == null:
		return
	var g: Dictionary = _mundo.datos_ghost()
	if not bool(g.get("activo", false)):
		return
	var cat: String = str(g["categoria"])
	var tipo: String = str(g["tipo"])
	var rot: bool = bool(g["rotado"])
	var volt: bool = bool(g["volteado"])
	var ignorar_id: int = int(g["ignorar_id"])

	if ignorar_id >= 0:
		var rm: Dictionary = Sistema_Granja.Mover_Objeto(ignorar_id, gx, gy, rot, volt)
		if bool(rm.get("ok", false)):
			_Sonido("drop")
			_Establecer_Modo("normal")
			_mundo.pulso_objeto(ignorar_id, Estilo.AZUL)
			_Mostrar_Flotante_Objeto(ignorar_id, "Movido", Estilo.AZUL)
			_Mostrar_Toast("%s recolocado gratis." % Datos.nombre(tipo), Estilos_UI.EXITO)
		else:
			_Mostrar_Toast(str(rm.get("motivo", "No cabe ahí.")), Estilos_UI.PELIGRO)
		return

	var r: Dictionary = Sistema_Granja.Construir_En(gx, gy, cat, tipo, rot, volt)
	if bool(r.get("ok", false)):
		_Sonido("coin")
		var nuevo_id: int = int(r.get("id", -1))
		_mundo.sincronizar_objetos()
		_mundo.pulso_objeto(nuevo_id, Estilo.ORO)
		_Mostrar_Flotante_Objeto(nuevo_id, "-%d MG" % int(r.get("coste", 0)), Estilo.ORO_OSCURO)

		# Colocación continua para parcelas de cultivo si quedan MG y espacio!
		var monedas_rest: int = int(Sistema_Granja.Estado().get("Monedas", 0))
		if cat == "tierra" and monedas_rest >= Datos.PRECIO_PARCELA_TIERRA:
			var tam := Datos.tamano_objeto("tierra", "tierra")
			var sig := Sistema_Granja.Buscar_Hueco_Libre(tam.x, tam.y)
			if sig.x >= 0:
				_Mostrar_Toast("Parcela colocada · toca otro sitio o pulsa Listo.", Estilos_UI.EXITO)
				_mundo.iniciar_ghost("tierra", "tierra", false, false, -1, sig.x, sig.y)
				_Refrescar_Barra_Ghost()
				_Actualizar_Todo()
				return

		_Mostrar_Toast("¡%s colocado en tu granja!" % Datos.nombre(tipo), Estilos_UI.EXITO)
		_Establecer_Modo("normal")
	else:
		_Mostrar_Toast(str(r.get("motivo", "No se pudo construir ahí.")), Estilos_UI.PELIGRO)


# ------------------------------------------------------------------
# Interacción con objetos y terreno del mapa
# ------------------------------------------------------------------

func _on_terreno_vacio_tocado(_gx: int, _gy: int) -> void:
	if _modo == "sembrar":
		_Establecer_Modo("normal")
		return
	if _inspeccionado_id >= 0:
		_Cerrar_Inspector()
		return
	if _modo == "vender":
		_Mostrar_Toast("Toca cualquier elemento colocado para venderlo al 50 %.", Estilos_UI.AVISO)
		return
	if _modo == "mover":
		_Mostrar_Toast("Toca un cultivo, animal o máquina para recogerlo y moverlo.", Estilos_UI.AVISO)
		return
	# Tocar césped libre en modo normal abre la tienda para elegir qué colocar.
	_Abrir_Tienda("todo")


func _on_objeto_tocado(objeto_id: int) -> void:
	_Accion_Objeto(objeto_id)


func _Accion_Objeto(objeto_id: int) -> void:
	var info: Dictionary = Sistema_Granja.Estado_Objeto(objeto_id)
	if not bool(info.get("valida", false)):
		return

	if _modo == "vender":
		_Abrir_Confirmar_Venta(objeto_id)
		return

	if _modo == "mover":
		_Iniciar_Mover_Objeto(objeto_id)
		return

	var cat: String = str(info.get("categoria", ""))

	# Si estamos en siembra rápida con una semilla seleccionada y tocamos otra tierra vacía -> plantar en 1 toque!
	if _modo == "sembrar" and cat == "tierra" and str(info.get("cultivo", "")) == "":
		if _semilla_activa != "":
			_Plantar(objeto_id, _semilla_activa, true)
			return
		_parcela_siembra_id = objeto_id
		_Refrescar_Barra_Siembra()
		return

	if _modo == "sembrar":
		_Establecer_Modo("normal")

	match cat:
		"tierra":
			_Accion_Tierra(objeto_id, info)
		"animal":
			_Accion_Animal(objeto_id, info)
		"maquina":
			_Accion_Maquina(objeto_id, info)


func _Accion_Tierra(objeto_id: int, info: Dictionary) -> void:
	if str(info.get("cultivo", "")) == "":
		_Abrir_Selector_Semilla(objeto_id)
		return
	if bool(info.get("listo", false)):
		var r: Dictionary = Sistema_Granja.Cosechar(objeto_id)
		if bool(r.get("ok", false)):
			_Sonido("pop")
			var texto_p := "+1 %s" % Datos.nombre(str(r.get("cultivo", "")))
			_mundo.pulso_objeto(objeto_id, Estilo.VERDE)
			_Mostrar_Flotante_Objeto(objeto_id, texto_p, Color("#15803d"))
			_Mostrar_Toast("%s al almacén" % texto_p, Estilos_UI.EXITO)
			_Cerrar_Inspector()
			_Actualizar_Todo()
		else:
			_Mostrar_Toast(str(r.get("motivo", "No se pudo cosechar.")), Estilos_UI.PELIGRO)
		return
	_Abrir_Inspector(objeto_id)


func _Accion_Animal(objeto_id: int, info: Dictionary) -> void:
	if bool(info.get("listo", false)):
		var r: Dictionary = Sistema_Granja.Recoger_Animal(objeto_id)
		if bool(r.get("ok", false)):
			_Sonido("ding")
			var texto_a := "+%d %s" % [int(r.get("cantidad", 0)), Datos.nombre(str(r.get("producto", "")))]
			_mundo.pulso_objeto(objeto_id, Estilo.ORO)
			_Mostrar_Flotante_Objeto(objeto_id, texto_a, Estilo.ORO_OSCURO)
			_Mostrar_Toast(texto_a, Estilos_UI.EXITO)
			_Cerrar_Inspector()
			_Actualizar_Todo()
		return
	if not bool(info.get("alimentado", false)):
		if bool(info.get("puede_accion", false)):
			var r: Dictionary = Sistema_Granja.Alimentar(objeto_id)
			if bool(r.get("ok", false)):
				_Sonido("drop")
				_mundo.pulso_objeto(objeto_id, Estilo.VERDE)
				_Mostrar_Flotante_Objeto(objeto_id, "Alimentado", Estilo.VERDE)
				_Mostrar_Toast("Animal alimentado. Producirá en %s." %
					Sistema_Granja.Formatear_Tiempo(int(r.get("duracion", 0))), Estilos_UI.EXITO)
				_Cerrar_Inspector()
				_Actualizar_Todo()
				return
		_Abrir_Inspector(objeto_id)
		return
	_Abrir_Inspector(objeto_id)


func _Accion_Maquina(objeto_id: int, info: Dictionary) -> void:
	if bool(info.get("listo", false)):
		var r: Dictionary = Sistema_Granja.Recoger_Maquina(objeto_id)
		if bool(r.get("ok", false)):
			_Sonido("ding")
			var texto_m := "+%d %s" % [int(r.get("cantidad", 0)), Datos.nombre(str(r.get("producto", "")))]
			_mundo.pulso_objeto(objeto_id, Estilo.AZUL)
			_Mostrar_Flotante_Objeto(objeto_id, texto_m, Estilo.AZUL)
			_Mostrar_Toast(texto_m, Estilos_UI.EXITO)
			_Cerrar_Inspector()
			_Actualizar_Todo()
		return
	if not bool(info.get("trabajando", false)) and bool(info.get("puede_accion", false)):
		var r: Dictionary = Sistema_Granja.Cargar_Maquina(objeto_id)
		if bool(r.get("ok", false)):
			_Sonido("click")
			_mundo.pulso_objeto(objeto_id, Estilo.AZUL)
			_Mostrar_Flotante_Objeto(objeto_id, "En marcha", Color("#0891b2"))
			_Mostrar_Toast("Máquina cargada. Lista en %s." %
				Sistema_Granja.Formatear_Tiempo(int(r.get("duracion", 0))), Estilos_UI.EXITO)
			_Cerrar_Inspector()
			_Actualizar_Todo()
			return
	_Abrir_Inspector(objeto_id)


func _Recoger_Todo() -> void:
	var recogidos: int = 0
	for obj in Sistema_Granja.Objetos():
		var id: int = int(obj.get("id", -1))
		var info: Dictionary = Sistema_Granja.Estado_Objeto(id)
		if not bool(info.get("listo", false)):
			continue
		var cat: String = str(info.get("categoria", ""))
		if cat == "tierra":
			var r: Dictionary = Sistema_Granja.Cosechar(id)
			if bool(r.get("ok", false)):
				recogidos += 1
				_mundo.pulso_objeto(id, Estilo.VERDE)
				_Mostrar_Flotante_Objeto(id, "+1 %s" % Datos.nombre(str(r.get("cultivo", ""))), Color("#15803d"))
		elif cat == "animal":
			var r: Dictionary = Sistema_Granja.Recoger_Animal(id)
			if bool(r.get("ok", false)):
				recogidos += 1
				_mundo.pulso_objeto(id, Estilo.ORO)
				_Mostrar_Flotante_Objeto(id, "+%d %s" % [int(r.get("cantidad", 0)), Datos.nombre(str(r.get("producto", "")))], Estilo.ORO_OSCURO)
		elif cat == "maquina":
			var r: Dictionary = Sistema_Granja.Recoger_Maquina(id)
			if bool(r.get("ok", false)):
				recogidos += 1
				_mundo.pulso_objeto(id, Estilo.AZUL)
				_Mostrar_Flotante_Objeto(id, "+%d %s" % [int(r.get("cantidad", 0)), Datos.nombre(str(r.get("producto", "")))], Estilo.AZUL)
	if recogidos > 0:
		_Sonido("ding")
		_Mostrar_Toast("Recogidos %d productos al almacén" % recogidos, Estilos_UI.EXITO)
		_Cerrar_Inspector()
		_Actualizar_Todo()


# ------------------------------------------------------------------
# Siembra rápida flotante (con plantación en cadena)
# ------------------------------------------------------------------

func _Abrir_Selector_Semilla(objeto_id: int) -> void:
	_parcela_siembra_id = objeto_id
	_semilla_activa = ""
	_Establecer_Modo("sembrar")
	_Refrescar_Barra_Siembra()


func _Refrescar_Barra_Siembra() -> void:
	if _barra_siembra == null:
		return
	var monedas: int = int(Sistema_Granja.Estado().get("Monedas", 0))
	if _semilla_activa != "":
		_siembra_sub.text = "%s · 1 toque" % Datos.nombre(_semilla_activa)
	else:
		_siembra_sub.text = "Elige un cultivo"

	for clave in _siembra_botones.keys():
		var btn: Button = _siembra_botones[clave]
		var d: Dictionary = Datos.CULTIVOS[clave]
		var coste: int = int(d["coste"])
		btn.disabled = monedas < coste
		var activa: bool = (clave == _semilla_activa)
		Estilo.aplicar_boton(
			btn,
			Color("#dcfce7") if activa else Estilo.CREMA,
			Color("#15803d") if activa else Color("#65a30d"),
			Estilo.TINTA, Color.WHITE, 14, 8)
		var l_det := btn.find_child("Detalle", true, false) as Label
		if l_det != null:
			l_det.text = "%d MG · %s" % [coste, Sistema_Granja.Formatear_Tiempo(Sistema_Granja.Duracion_Segundos(float(d["horas"])))]
	_Reposicionar_HUD()


func _Seleccionar_Semilla_Rapida(clave: String) -> void:
	_semilla_activa = clave
	if _parcela_siembra_id >= 0:
		var info := Sistema_Granja.Estado_Objeto(_parcela_siembra_id)
		if bool(info.get("valida", false)) and str(info.get("cultivo", "")) == "":
			_Plantar(_parcela_siembra_id, clave, true)
			return
	_Establecer_Modo("sembrar")
	_Refrescar_Barra_Siembra()


func _Plantar(objeto_id: int, clave: String, mantener_siembra: bool = false) -> void:
	var r: Dictionary = Sistema_Granja.Sembrar(objeto_id, clave)
	if bool(r.get("ok", false)):
		_Sonido("drop")
		_mundo.sincronizar_objetos()
		_mundo.pulso_objeto(objeto_id, Estilo.VERDE)
		_Mostrar_Flotante_Objeto(objeto_id, "-%d MG" % int(r.get("coste", 0)), Color("#4d7c0f"))
		_Mostrar_Toast("Plantado %s · listo en %s." % [
			Datos.nombre(clave), Sistema_Granja.Formatear_Tiempo(int(r.get("duracion", 0)))], Estilos_UI.EXITO)

		if mantener_siembra and _Hay_Parcelas_Vacias() and int(Sistema_Granja.Estado().get("Monedas", 0)) >= int(Datos.CULTIVOS[clave]["coste"]):
			_parcela_siembra_id = -1
			_semilla_activa = clave
			_Establecer_Modo("sembrar")
			_Refrescar_Barra_Siembra()
		else:
			_Establecer_Modo("normal")
	else:
		_Mostrar_Toast(str(r.get("motivo", "No se pudo plantar.")), Estilos_UI.PELIGRO)


func _Hay_Parcelas_Vacias() -> bool:
	for obj in Sistema_Granja.Objetos():
		if str(obj.get("categoria", "")) == "tierra" and str(obj.get("cultivo", "")) == "":
			return true
	return false


# ------------------------------------------------------------------
# Tarjeta inspectora compacta (progreso, ingredientes, mover y vender)
# ------------------------------------------------------------------

func _Abrir_Inspector(objeto_id: int) -> void:
	_inspeccionado_id = objeto_id
	_Refrescar_Inspector()
	if _mundo != null:
		_mundo.establecer_modo(_modo, _inspeccionado_id)


func _Cerrar_Inspector() -> void:
	_inspeccionado_id = -1
	if _tarjeta_inspector != null:
		_tarjeta_inspector.visible = false
	if _mundo != null:
		_mundo.establecer_modo(_modo, -1)


func _Refrescar_Inspector() -> void:
	if _tarjeta_inspector == null or _inspeccionado_id < 0:
		return
	var info: Dictionary = Sistema_Granja.Estado_Objeto(_inspeccionado_id)
	if not bool(info.get("valida", false)):
		_Cerrar_Inspector()
		return
	for h in _insp_body.get_children():
		h.queue_free()

	var cat: String = str(info["categoria"])
	var tipo: String = str(info["tipo"])
	var clave_ico: String = str(info["cultivo"]) if (cat == "tierra" and str(info["cultivo"]) != "") else tipo
	_insp_body.add_child(_Icono_Prod(clave_ico, 54))

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 3)
	_insp_body.add_child(col)

	var fila_t := HBoxContainer.new()
	fila_t.add_theme_constant_override("separation", 8)
	col.add_child(fila_t)
	fila_t.add_child(Estilos_UI.titulo(str(info["nombre"]), 16, Estilo.TINTA))
	fila_t.add_child(Estilo.pill_etiqueta("%d×%d" % [int(info["ancho"]), int(info["alto"])],
		Estilo.PERGAMINO, Estilo.MADERA_CLARA, Estilo.TINTA_SUAVE, 10))

	if bool(info["trabajando"]):
		var lbl_est := Estilos_UI.texto("En producción · faltan %s (%d %%)" % [
			Sistema_Granja.Formatear_Tiempo(int(info["restante"])),
			int(round(float(info["progreso"]) * 100.0))], 12, Color("#b45309"), 700)
		col.add_child(lbl_est)
	elif cat == "animal":
		var da: Dictionary = Datos.animal(tipo)
		var come: String = str(da.get("come", ""))
		var cant: int = int(da.get("cantidad_come", 1))
		var tengo: int = Sistema_Granja.Cantidad_Almacen(come)
		col.add_child(Estilos_UI.texto("Necesita %d %s (tienes %d) → %d %s" % [
			cant, Datos.nombre(come), tengo, int(da.get("cantidad_producto", 1)),
			Datos.nombre(str(da.get("producto", "")))], 12, Estilo.ROJO if tengo < cant else Estilo.VERDE_BOSQUE, 700))
	elif cat == "maquina":
		var dm: Dictionary = Datos.maquina(tipo)
		var ing: Dictionary = dm.get("ingredientes", {})
		var partes: Array[String] = []
		for k in ing.keys():
			var ks := str(k)
			partes.append("%d %s (tienes %d)" % [int(ing[k]), Datos.nombre(ks), Sistema_Granja.Cantidad_Almacen(ks)])
		col.add_child(Estilos_UI.texto("Receta: %s → %s" % [", ".join(partes), Datos.nombre(str(dm.get("producto", "")))],
			12, Estilo.TINTA_SUAVE, 700))

	var btn_m := Estilo.crear_boton_hud("Mover", "hand", Estilo.AZUL, Estilo.AZUL_SUAVE, Estilo.AZUL, Color("#0c4a6e"), 112, 42, 13)
	btn_m.pressed.connect(Callable(self, "_Iniciar_Mover_Objeto").bind(_inspeccionado_id))
	_insp_body.add_child(btn_m)

	var btn_v := Estilo.crear_boton_hud("+%d MG" % int(info["reembolso"]), "coins", Estilo.ROJO, Estilo.ROJO_SUAVE, Estilo.ROJO, Color("#991b1b"), 116, 42, 13)
	btn_v.tooltip_text = "Vender (50 % reembolso)"
	btn_v.pressed.connect(Callable(self, "_Abrir_Confirmar_Venta").bind(_inspeccionado_id))
	_insp_body.add_child(btn_v)

	var btn_x := Estilo.crear_boton_hud("", "x", Estilo.TINTA, Estilo.CREMA, Estilo.MADERA_CLARA, Estilo.TINTA, 40, 42)
	btn_x.pressed.connect(_Cerrar_Inspector)
	_insp_body.add_child(btn_x)

	_tarjeta_inspector.visible = true


# ------------------------------------------------------------------
# Actualización periódica de HUD y mapa
# ------------------------------------------------------------------

func _Actualizar_Todo() -> void:
	var estado: Dictionary = Sistema_Granja.Estado()
	var monedas: int = int(estado.get("Monedas", 0))
	if _lbl_mg != null:
		_lbl_mg.text = "%s MG" % Datos.formatear_numero(monedas)
	if _lbl_dinero != null:
		_lbl_dinero.text = "%s €" % Datos.formatear_numero(int(Variables_Dinamicas.Dinero))
	if _btn_ingresar != null:
		_btn_ingresar.disabled = int(floor(float(Variables_Dinamicas.Dinero))) <= 0
	if _btn_cobrar != null:
		_btn_cobrar.disabled = monedas <= 0

	if _mundo != null:
		_mundo.sincronizar_objetos()

	var ocupada: int = Sistema_Granja.Area_Ocupada()
	var total_area: int = Sistema_Granja.Area_Total()
	var listos: int = Sistema_Granja.Contar_Listos()
	var rect_t := Sistema_Granja.Rect_Terreno()

	if _lbl_estado_granja != null:
		if listos > 0:
			_lbl_estado_granja.text = "%d/%d u² · ⚡ %d %s" % [ocupada, total_area, listos, "listo" if listos == 1 else "listos"]
			_lbl_estado_granja.add_theme_color_override("font_color", Color("#d97706"))
		else:
			var sufijo := " · Rápido ÷7" if Variables_Estaticas.Modo_Rapido else ""
			_lbl_estado_granja.text = "%d/%d u² (%d×%d)%s" % [ocupada, total_area, rect_t.size.x, rect_t.size.y, sufijo]
			_lbl_estado_granja.add_theme_color_override("font_color", Color("#4d7c0f"))

	if _barra_area_fill != null:
		var pct: float = clampf(float(ocupada) / float(maxi(1, total_area)), 0.0, 1.0)
		_barra_area_fill.size.x = maxf(6.0, 226.0 * pct)

	if _btn_recoger_todo != null:
		_btn_recoger_todo.visible = listos >= 2 and _modo == "normal"
		if _btn_recoger_todo.visible:
			_btn_recoger_todo.text = "Recoger (%d)" % listos

	if _btn_almacen != null:
		var total: int = 0
		for clave in Sistema_Granja.Almacen().keys():
			total += int(Sistema_Granja.Almacen()[clave])
		_btn_almacen.text = "Almacén (%d)" % total

	if _btn_mejoras != null:
		var asequibles: int = 0
		for clave_m in Sistema_Granja.Mejoras_Disponibles():
			if monedas >= int(Datos.MEJORAS[clave_m].get("coste", 0)):
				asequibles += 1
		_btn_mejoras.text = "Mejoras (%d)" % asequibles if asequibles > 0 else "Mejoras"

	if _inspeccionado_id >= 0 and _tarjeta_inspector != null and _tarjeta_inspector.visible:
		_Refrescar_Inspector()
	if _modo == "sembrar":
		_Refrescar_Barra_Siembra()


# ------------------------------------------------------------------
# Modales: Construir (con huellas visuales), Confirmar venta, Almacén, Mejoras, Conversión
# ------------------------------------------------------------------

func _Abrir_Tienda(filtro: String = "todo") -> void:
	_filtro_tienda = filtro
	if _modo != "normal":
		_Establecer_Modo("normal")
	var libre: int = Sistema_Granja.Area_Libre()
	var total: int = Sistema_Granja.Area_Total()
	_Abrir_Modal(
		"Construir en la granja",
		"%d u² libres de %d u² · elige un elemento y colócalo donde quieras en el mapa" % [libre, total],
		"store", Color("#ea580c"))

	# Pestañas de filtro limpio.
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	_modal_body.add_child(tabs)
	for par in [["todo", "Todo"], ["tierra", "Cultivo"], ["animal", "Animales"], ["maquina", "Máquinas"]]:
		var clave_f: String = par[0]
		var activo: bool = (clave_f == _filtro_tienda)
		var b := Estilo.crear_boton_hud(
			par[1], "", Color.WHITE,
			Estilo.VERDE_BOSQUE if activo else Estilo.PERGAMINO,
			Estilo.VERDE_BOSQUE if activo else Estilo.MADERA_CLARA,
			Color.WHITE if activo else Estilo.TINTA, 118, 38, 13)
		b.pressed.connect(Callable(self, "_Abrir_Tienda").bind(clave_f))
		tabs.add_child(b)

	var monedas: int = int(Sistema_Granja.Estado().get("Monedas", 0))

	if _filtro_tienda in ["todo", "tierra"]:
		_modal_body.add_child(_Titulo_Seccion("CULTIVO", Color("#4d7c0f")))
		var tam_t := Datos.tamano_objeto("tierra")
		var cabe_t: bool = Sistema_Granja.Buscar_Hueco_Libre(tam_t.x, tam_t.y).x >= 0
		_modal_body.add_child(_Crear_Tarjeta_Tienda(
			"tierra", "tierra", "Parcela de cultivo",
			"Siembra trigo, zanahoria o maíz · reembolso %d MG (50 %%)" % Datos.reembolso_venta(Datos.PRECIO_PARCELA_TIERRA),
			Datos.PRECIO_PARCELA_TIERRA, tam_t, false,
			monedas >= Datos.PRECIO_PARCELA_TIERRA, cabe_t, Color("#65a30d")))

	if _filtro_tienda in ["todo", "animal"]:
		_modal_body.add_child(_Titulo_Seccion("ANIMALES", Color("#b45309")))
		for clave in Datos.ANIMALES.keys():
			var d: Dictionary = Datos.ANIMALES[clave]
			var tam_a := Datos.tamano_objeto("animal", str(clave))
			var cabe_a: bool = Sistema_Granja.Buscar_Hueco_Libre(tam_a.x, tam_a.y).x >= 0
			var precio: int = int(d["precio"])
			var sub := "Come %d %s → %d %s · %s · vende %d MG" % [
				int(d["cantidad_come"]), Datos.nombre(str(d["come"])),
				int(d["cantidad_producto"]), Datos.nombre(str(d["producto"])),
				Sistema_Granja.Formatear_Tiempo(Sistema_Granja.Duracion_Segundos(float(d["horas"]))),
				Datos.reembolso_venta(precio)]
			_modal_body.add_child(_Crear_Tarjeta_Tienda(
				"animal", str(clave), str(d["nombre"]), sub, precio, tam_a, false,
				monedas >= precio, cabe_a, Color("#d97706")))

	if _filtro_tienda in ["todo", "maquina"]:
		_modal_body.add_child(_Titulo_Seccion("MÁQUINAS Y TALLERES", Color("#0e7490")))
		for clave in Datos.MAQUINAS.keys():
			var d: Dictionary = Datos.MAQUINAS[clave]
			var tam_m := Datos.tamano_objeto("maquina", str(clave))
			var rotable: bool = Datos.es_rotable("maquina", str(clave))
			var cabe_m: bool = (Sistema_Granja.Buscar_Hueco_Libre(tam_m.x, tam_m.y).x >= 0
				or (rotable and Sistema_Granja.Buscar_Hueco_Libre(tam_m.y, tam_m.x).x >= 0))
			var precio: int = int(d["precio"])
			var partes: Array[String] = []
			for k in d.get("ingredientes", {}).keys():
				partes.append("%d %s" % [int(d["ingredientes"][k]), Datos.nombre(str(k))])
			var sub := "%s → %s · %s · vende %d MG" % [
				", ".join(partes), Datos.nombre(str(d["producto"])),
				Sistema_Granja.Formatear_Tiempo(Sistema_Granja.Duracion_Segundos(float(d["horas"]))),
				Datos.reembolso_venta(precio)]
			_modal_body.add_child(_Crear_Tarjeta_Tienda(
				"maquina", str(clave), str(d["nombre"]), sub, precio, tam_m, rotable,
				monedas >= precio, cabe_m, Color("#0891b2")))

	_modal_body.add_child(_Parrafo("Puedes mover cualquier objeto gratis con «Mover» o venderlo al 50 % con «Vender»."))


func _Crear_Tarjeta_Tienda(categoria: String, tipo: String, titulo: String, subtitulo: String,
		precio: int, tam: Vector2i, rotable: bool, tiene_mg: bool, cabe: bool, color: Color) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel",
		Estilo.panel_madera(Color("#fffcf4"), Color("#e2d4b7"), 16, 2, 2))
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 12)
	m.add_theme_constant_override("margin_right", 12)
	m.add_theme_constant_override("margin_top", 9)
	m.add_theme_constant_override("margin_bottom", 9)
	card.add_child(m)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	m.add_child(h)

	var ico_wrap := PanelContainer.new()
	ico_wrap.custom_minimum_size = Vector2(64, 64)
	ico_wrap.add_theme_stylebox_override("panel",
		Estilo.panel_madera(Color(color.r, color.g, color.b, 0.12), Color(color.r, color.g, color.b, 0.40), 14, 1, 0))
	var cc := CenterContainer.new()
	cc.add_child(_Icono_Prod(tipo, 52))
	ico_wrap.add_child(cc)
	h.add_child(ico_wrap)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 3)
	h.add_child(col)

	var fila_tit := HBoxContainer.new()
	fila_tit.add_theme_constant_override("separation", 8)
	col.add_child(fila_tit)
	fila_tit.add_child(Estilos_UI.titulo(titulo, 16, Estilo.TINTA))

	# Indicador visual de huella (mini grid isométrica + texto "4×4", "4×3", "2×2")!
	var huella_box := HBoxContainer.new()
	huella_box.add_theme_constant_override("separation", 3)
	var badge_grid := Estilo.HuellaBadge.new()
	badge_grid.configurar(tam.x, tam.y, color, color.darkened(0.35))
	huella_box.add_child(badge_grid)
	var txt_tam := "%d×%d (%d u²)" % [tam.x, tam.y, tam.x * tam.y]
	if rotable:
		txt_tam += " · girable"
	huella_box.add_child(Estilo.pill_etiqueta(txt_tam, Estilo.PERGAMINO, Color(color, 0.55), color.darkened(0.3), 10))
	fila_tit.add_child(huella_box)

	var sub := Estilos_UI.texto(subtitulo, 11, Estilo.TINTA_SUAVE, 600)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(sub)

	var texto_btn: String = "%d MG · Colocar" % precio if cabe else "No cabe (%d×%d)" % [tam.x, tam.y]
	var btn := Estilo.crear_boton_hud(
		texto_btn, "plus" if cabe else "", Color.WHITE,
		color, color.darkened(0.25), Color.WHITE, 168.0, 44.0, 13)
	btn.disabled = (not tiene_mg) or (not cabe)
	if not btn.disabled:
		btn.pressed.connect(Callable(self, "_Iniciar_Colocacion").bind(categoria, tipo))
	h.add_child(btn)
	return card


func _Abrir_Confirmar_Venta(objeto_id: int) -> void:
	var info: Dictionary = Sistema_Granja.Estado_Objeto(objeto_id)
	if not bool(info.get("valida", false)):
		return
	var tipo_obj: String = str(info["tipo"])
	var nombre_obj: String = Datos.nombre(tipo_obj)
	var coste: int = int(info["coste_pagado"])
	var reembolso: int = int(info["reembolso"])
	var en_curso: bool = bool(info["trabajando"]) or bool(info["listo"])

	_Abrir_Modal("Vender %s" % nombre_obj, "Recuperas exactamente el 50 % de lo pagado", "coins", Estilo.ROJO)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", Estilo.panel_madera(Color("#fff5f5"), Estilo.ROJO, 16, 2, 2))
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 14)
	m.add_theme_constant_override("margin_right", 14)
	m.add_theme_constant_override("margin_top", 12)
	m.add_theme_constant_override("margin_bottom", 12)
	card.add_child(m)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	m.add_child(h)
	h.add_child(_Icono_Prod(tipo_obj, 66))
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 3)
	h.add_child(col)
	col.add_child(Estilos_UI.titulo("%s (%d×%d)" % [nombre_obj, int(info["ancho"]), int(info["alto"])], 17, Estilo.TINTA))
	col.add_child(Estilos_UI.texto("Coste pagado: %d MG · Reembolso: +%d MG (50 %%)" % [coste, reembolso], 12, Color("#991b1b"), 700))

	var btn_v := Estilo.crear_boton_hud("Vender (+%d MG)" % reembolso, "coins", Color.WHITE,
		Estilo.ROJO, Color("#991b1b"), Color.WHITE, 174, 46, 14)
	btn_v.pressed.connect(Callable(self, "_Confirmar_Venta_Objeto").bind(objeto_id))
	h.add_child(btn_v)
	_modal_body.add_child(card)

	if en_curso:
		_modal_body.add_child(_Parrafo("Aviso: hay una cosecha o producción activa en este objeto; al venderlo se perderá.", Color("#b91c1c")))
	_modal_body.add_child(_Parrafo("Si solo quieres cambiarlo de sitio, usa «Mover» gratis en lugar de venderlo."))

	var fila_b := HBoxContainer.new()
	fila_b.add_theme_constant_override("separation", 10)
	_modal_body.add_child(fila_b)
	var btn_mover := Estilo.crear_boton_hud("Mover gratis en su lugar", "hand", Estilo.AZUL,
		Estilo.AZUL_SUAVE, Estilo.AZUL, Color("#0c4a6e"), 220, 44, 13)
	btn_mover.pressed.connect(func() -> void:
		_Cerrar_Modal()
		_Iniciar_Mover_Objeto(objeto_id))
	fila_b.add_child(btn_mover)

	var btn_cancelar := Estilo.crear_boton_hud("Cancelar", "x", Estilo.TINTA,
		Estilo.CREMA, Estilo.MADERA_CLARA, Estilo.TINTA, 130, 44, 13)
	btn_cancelar.pressed.connect(_Cerrar_Modal)
	fila_b.add_child(btn_cancelar)


func _Confirmar_Venta_Objeto(objeto_id: int) -> void:
	var pos_p: Vector2 = _mundo.posicion_pantalla_objeto(objeto_id)
	var r: Dictionary = Sistema_Granja.Vender_Objeto(objeto_id)
	if bool(r.get("ok", false)):
		_Sonido("coin")
		var reembolso: int = int(r.get("reembolso", 0))
		_Mostrar_Flotante(pos_p, "+%d MG" % reembolso, Estilo.VERDE)
		_Mostrar_Toast("Vendido %s (+%d MG · 50 %%)" % [str(r.get("nombre", "objeto")), reembolso], Estilos_UI.EXITO)
		_Cerrar_Modal()
		_Cerrar_Inspector()
		_Actualizar_Todo()
	else:
		_Mostrar_Toast(str(r.get("motivo", "No se pudo vender.")), Estilos_UI.PELIGRO)


func _Abrir_Almacen() -> void:
	_Abrir_Modal("Almacén", "Vende excedentes para ganar MG o guárdalos para animales y máquinas", "package", Estilo.AZUL)
	var almacen: Dictionary = Sistema_Granja.Almacen()
	if almacen.is_empty():
		_modal_body.add_child(_Parrafo("El almacén está vacío. Planta cultivos, alimenta animales o carga una máquina."))
		return
	var total: int = 0
	var valor_total: int = 0
	for clave in almacen.keys():
		var c: int = int(almacen[clave])
		total += c
		valor_total += Datos.precio_venta(str(clave)) * c

	var btn_todo := Estilo.crear_boton_hud(
		"Vender todo (%d %s · +%d MG)" % [total, "ud" if total == 1 else "uds", valor_total],
		"coins", Color.WHITE, Estilo.VERDE, Color("#15803d"), Color.WHITE, 320, 46, 14)
	btn_todo.pressed.connect(_Vender_Todo)
	_modal_body.add_child(btn_todo)

	for clave in almacen.keys():
		var k: String = str(clave)
		var cantidad: int = int(almacen[clave])
		var precio: int = Datos.precio_venta(k)
		var fila := PanelContainer.new()
		fila.add_theme_stylebox_override("panel", Estilo.panel_madera(Color("#fffcf4"), Color("#e2d4b7"), 15, 2, 2))
		var m := MarginContainer.new()
		m.add_theme_constant_override("margin_left", 12)
		m.add_theme_constant_override("margin_right", 12)
		m.add_theme_constant_override("margin_top", 8)
		m.add_theme_constant_override("margin_bottom", 8)
		fila.add_child(m)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
		h.alignment = BoxContainer.ALIGNMENT_CENTER
		m.add_child(h)
		h.add_child(_Icono_Prod(k, 52))
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 1)
		h.add_child(col)
		col.add_child(Estilos_UI.titulo(Datos.nombre(k), 15, Estilo.TINTA))
		col.add_child(Estilos_UI.texto("%d uds · %d MG/ud · valor total %d MG" % [cantidad, precio, precio * cantidad], 11, Estilo.TINTA_SUAVE, 600))
		if cantidad > 1:
			var b1 := Estilo.crear_boton_hud("Vender 1", "", Estilo.AZUL, Estilo.AZUL_SUAVE, Estilo.AZUL, Color("#0c4a6e"), 102, 40, 12)
			b1.pressed.connect(Callable(self, "_Vender_Unidad").bind(k))
			h.add_child(b1)
		var ball := Estilo.crear_boton_hud("Vender (%d)" % cantidad if cantidad > 1 else "Vender", "", Color.WHITE, Estilo.AZUL, Color("#0369a1"), Color.WHITE, 126, 40, 12)
		ball.pressed.connect(Callable(self, "_Vender_Producto").bind(k))
		h.add_child(ball)
		_modal_body.add_child(fila)


func _Vender_Unidad(clave: String) -> void:
	var r: Dictionary = Sistema_Granja.Vender(clave, 1)
	if bool(r.get("ok", false)):
		_Sonido("coin")
		_Mostrar_Toast("+%d MG por 1 %s" % [int(r.get("total", 0)), Datos.nombre(clave)], Estilos_UI.EXITO)
		_Abrir_Almacen()
		_Actualizar_Todo()
	else:
		_Mostrar_Toast(str(r.get("motivo", "No se pudo vender.")), Estilos_UI.PELIGRO)


func _Vender_Producto(clave: String) -> void:
	var cantidad: int = Sistema_Granja.Cantidad_Almacen(clave)
	var r: Dictionary = Sistema_Granja.Vender(clave, cantidad)
	if bool(r.get("ok", false)):
		_Sonido("coin")
		_Mostrar_Toast("+%d MG por %s" % [int(r.get("total", 0)), Datos.nombre(clave)], Estilos_UI.EXITO)
		_Abrir_Almacen()
		_Actualizar_Todo()
	else:
		_Mostrar_Toast(str(r.get("motivo", "No se pudo vender.")), Estilos_UI.PELIGRO)


func _Vender_Todo() -> void:
	var r: Dictionary = Sistema_Granja.Vender_Todo()
	if bool(r.get("ok", false)):
		_Sonido("coin")
		_Mostrar_Toast("+%d MG por %d productos" % [int(r.get("total", 0)), int(r.get("unidades", 0))], Estilos_UI.EXITO)
		_Abrir_Almacen()
		_Actualizar_Todo()
	else:
		_Mostrar_Toast(str(r.get("motivo", "El almacén está vacío.")), Estilos_UI.AVISO)


func _Abrir_Mejoras() -> void:
	var area_act: int = Sistema_Granja.Area_Total()
	var rect_act := Sistema_Granja.Rect_Terreno()
	var nivel_t: int = Sistema_Granja.Nivel_Terreno()
	var nivel_v: int = clampi(int(Sistema_Granja.Estado().get("Velocidad", 0)), 0, 3)
	var monedas: int = int(Sistema_Granja.Estado().get("Monedas", 0))

	_Abrir_Modal(
		"Mejoras de la granja",
		"Terreno actual: %d×%d (%d/%d u²) · Velocidad: −%d %%" % [
			rect_act.size.x, rect_act.size.y, area_act, Datos.AREA_TOTAL, nivel_v * 10],
		"hammer", Estilo.MORADO)

	# 1. Progreso visual del terreno Nivel 0 → IV con iconos de estado.
	var barra_niv := HBoxContainer.new()
	barra_niv.add_theme_constant_override("separation", 6)
	_modal_body.add_child(barra_niv)
	for cfg in Datos.NIVELES_TERRENO:
		var nv: int = int(cfg["nivel"])
		var desb: bool = nv <= nivel_t
		var sig: bool = nv == nivel_t + 1
		var pref: String = "✓ " if desb else ("★ " if sig else "🔒 ")
		var pill := Estilo.pill_etiqueta(
			"%s%s (%d u²)" % [pref, str(cfg["etiqueta"]), int(cfg["area"])],
			Estilo.VERDE_CLARO if desb else (Estilo.ORO_SUAVE if sig else Estilo.PERGAMINO),
			Estilo.VERDE if desb else (Estilo.ORO if sig else Color("#d6c7a8")),
			Estilo.VERDE_BOSQUE if desb else (Estilo.ORO_OSCURO if sig else Estilo.TINTA_SUAVE), 11)
		pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		barra_niv.add_child(pill)

	# 2. Dos tarjetas escaparate ilustradas en vivo (Terreno + Velocidad).
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 14)
	cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_modal_body.add_child(cols)

	# --- Tarjeta izquierda: AMPLIAR TERRENO ---
	var sig_amp: String = Sistema_Granja.Siguiente_Ampliacion()
	var card_t := PanelContainer.new()
	card_t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_t.add_theme_stylebox_override("panel", Estilo.panel_madera(Color("#fffdf6"), Color("#65a30d"), 18, 2, 4))
	cols.add_child(card_t)

	var mt := MarginContainer.new()
	mt.add_theme_constant_override("margin_left", 14)
	mt.add_theme_constant_override("margin_right", 14)
	mt.add_theme_constant_override("margin_top", 12)
	mt.add_theme_constant_override("margin_bottom", 14)
	card_t.add_child(mt)

	var vt := VBoxContainer.new()
	vt.add_theme_constant_override("separation", 10)
	mt.add_child(vt)

	# Escaparate animado del mapa isométrico
	var marco_t := PanelContainer.new()
	marco_t.clip_contents = true
	marco_t.add_theme_stylebox_override("panel", Estilo.panel_madera(Color("#4f9624"), Color("#365314"), 14, 2, 0))
	var prev_t := Estilo.PreviewTerrenoMejora.new()
	prev_t.configurar(nivel_t)
	marco_t.add_child(prev_t)
	vt.add_child(marco_t)

	var ft_tit := HBoxContainer.new()
	ft_tit.add_theme_constant_override("separation", 8)
	vt.add_child(ft_tit)
	if sig_amp != "":
		var da: Dictionary = Datos.MEJORAS[sig_amp]
		var coste_a: int = int(da["coste"])
		var delta_a: int = int(da["delta"])
		ft_tit.add_child(Estilos_UI.titulo(str(da["nombre"]), 17, Estilo.VERDE_BOSQUE))
		ft_tit.add_child(Estilo.pill_etiqueta("+%d u² → %s" % [delta_a, str(da["etiqueta"])],
			Estilo.VERDE_CLARO, Estilo.VERDE, Estilo.VERDE_BOSQUE, 11))
		vt.add_child(_Parrafo(
			"Expande el prado cercado a %d u² totales. En el nuevo espacio caben hasta +%d parcelas 2×2 o +%d molinos 4×4." % [
				int(da["area"]), int(delta_a / 4), int(delta_a / 16)],
			Estilo.TINTA_SUAVE))
		var btn_a := Estilo.crear_boton_hud(
			"Ampliar terreno · %d MG" % coste_a, "coins", Color.WHITE,
			Estilo.VERDE, Color("#15803d"), Color.WHITE, 260, 46, 14)
		btn_a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_a.disabled = monedas < coste_a
		if not btn_a.disabled:
			btn_a.pressed.connect(Callable(self, "_Comprar_Mejora").bind(sig_amp))
		vt.add_child(btn_a)
	else:
		ft_tit.add_child(Estilos_UI.titulo("Terreno al máximo", 17, Estilo.VERDE_BOSQUE))
		ft_tit.add_child(Estilo.pill_etiqueta("24×24 · 576 u²", Estilo.ORO_SUAVE, Estilo.ORO, Estilo.ORO_OSCURO, 11))
		vt.add_child(_Parrafo("Has desbloqueado todo el mapa 24×24. Tienes el máximo espacio disponible para construir libremente.", Estilo.TINTA_SUAVE))
		var btn_max_t := Estilo.crear_boton_hud("Completado", "check", Color.WHITE, Color("#84cc16"), Color("#4d7c0f"), Color.WHITE, 220, 46, 14)
		btn_max_t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_max_t.disabled = true
		vt.add_child(btn_max_t)

	# --- Tarjeta derecha: VELOCIDAD DE PRODUCCIÓN ---
	var sig_vel: String = ""
	for kv in ["velocidad_1", "velocidad_2", "velocidad_3"]:
		if Sistema_Granja.Mejora_Disponible(kv):
			sig_vel = kv
			break

	var card_v := PanelContainer.new()
	card_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_v.add_theme_stylebox_override("panel", Estilo.panel_madera(Color("#fffdf6"), Estilo.MORADO, 18, 2, 4))
	cols.add_child(card_v)

	var mv := MarginContainer.new()
	mv.add_theme_constant_override("margin_left", 14)
	mv.add_theme_constant_override("margin_right", 14)
	mv.add_theme_constant_override("margin_top", 12)
	mv.add_theme_constant_override("margin_bottom", 14)
	card_v.add_child(mv)

	var vv := VBoxContainer.new()
	vv.add_theme_constant_override("separation", 10)
	mv.add_child(vv)

	# Escaparate animado del molino acelerado con ráfagas doradas
	var marco_v := PanelContainer.new()
	marco_v.clip_contents = true
	marco_v.add_theme_stylebox_override("panel", Estilo.panel_madera(Color("#4c1d95"), Color("#3b0764"), 14, 2, 0))
	var prev_v := Estilo.PreviewVelocidadMejora.new()
	prev_v.configurar(nivel_v)
	marco_v.add_child(prev_v)
	vv.add_child(marco_v)

	var fv_tit := HBoxContainer.new()
	fv_tit.add_theme_constant_override("separation", 8)
	vv.add_child(fv_tit)

	if sig_vel != "":
		var dv: Dictionary = Datos.MEJORAS[sig_vel]
		var coste_v: int = int(dv["coste"])
		var nuevo_nv: int = int(dv["valor"])
		fv_tit.add_child(Estilos_UI.titulo(str(dv["nombre"]), 17, Color("#4c1d95")))
		fv_tit.add_child(Estilo.pill_etiqueta("Nv. %d/3 · −%d %% tiempo" % [nuevo_nv, nuevo_nv * 10],
			Estilo.MORADO_SUAVE, Estilo.MORADO, Color("#4c1d95"), 11))

		# Comparativa real de tiempos antes → después
		var factor_act: float = Sistema_Granja.Factor_Tiempo()
		var base_rap: float = (1.0 / 7.0) if Variables_Estaticas.Modo_Rapido else 1.0
		var factor_sig: float = base_rap * (1.0 - 0.10 * float(nuevo_nv))
		var t_trigo_a: String = Sistema_Granja.Formatear_Tiempo(maxi(1, int(round(2.0 * 3600.0 * factor_act))))
		var t_trigo_b: String = Sistema_Granja.Formatear_Tiempo(maxi(1, int(round(2.0 * 3600.0 * factor_sig))))
		var t_vaca_a: String = Sistema_Granja.Formatear_Tiempo(maxi(1, int(round(6.0 * 3600.0 * factor_act))))
		var t_vaca_b: String = Sistema_Granja.Formatear_Tiempo(maxi(1, int(round(6.0 * 3600.0 * factor_sig))))
		vv.add_child(_Parrafo(
			"Acelera cultivos, animales y máquinas. Ejemplo: Trigo %s → %s · Vaca %s → %s." % [
				t_trigo_a, t_trigo_b, t_vaca_a, t_vaca_b],
			Estilo.TINTA_SUAVE))

		var btn_v := Estilo.crear_boton_hud(
			"Mejorar velocidad · %d MG" % coste_v, "coins", Color.WHITE,
			Estilo.MORADO, Color("#5b21b6"), Color.WHITE, 260, 46, 14)
		btn_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_v.disabled = monedas < coste_v
		if not btn_v.disabled:
			btn_v.pressed.connect(Callable(self, "_Comprar_Mejora").bind(sig_vel))
		vv.add_child(btn_v)
	else:
		fv_tit.add_child(Estilos_UI.titulo("Velocidad al máximo", 17, Color("#4c1d95")))
		fv_tit.add_child(Estilo.pill_etiqueta("−30 % tiempo", Estilo.ORO_SUAVE, Estilo.ORO, Estilo.ORO_OSCURO, 11))
		vv.add_child(_Parrafo("Toda tu granja (cultivos, animales y máquinas) produce a máxima velocidad (−30 % de espera).", Estilo.TINTA_SUAVE))
		var btn_max_v := Estilo.crear_boton_hud("Completado", "check", Color.WHITE, Estilo.MORADO, Color("#5b21b6"), Color.WHITE, 220, 46, 14)
		btn_max_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_max_v.disabled = true
		vv.add_child(btn_max_v)

	# 3. Franja inferior con acceso rápido a Ingresar € → MG (1:1).
	var pie := PanelContainer.new()
	pie.add_theme_stylebox_override("panel", Estilo.panel_madera(Estilo.PERGAMINO, Color("#e2d4b7"), 14, 1, 0))
	var mp := MarginContainer.new()
	mp.add_theme_constant_override("margin_left", 14)
	mp.add_theme_constant_override("margin_right", 14)
	mp.add_theme_constant_override("margin_top", 8)
	mp.add_theme_constant_override("margin_bottom", 8)
	pie.add_child(mp)
	var hp := HBoxContainer.new()
	hp.add_theme_constant_override("separation", 12)
	hp.alignment = BoxContainer.ALIGNMENT_CENTER
	mp.add_child(hp)
	var lbl_pie := Estilos_UI.texto(
		"Saldo actual: %s MG · Saldo del Sim: %s €" % [
			Datos.formatear_numero(monedas),
			Datos.formatear_numero(int(Variables_Dinamicas.Dinero))],
		12, Estilo.TINTA, 700)
	lbl_pie.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp.add_child(lbl_pie)
	var btn_ing := Estilo.crear_boton_hud("Ingresar € → MG (1:1)", "plus", Color.WHITE,
		Estilo.VERDE, Color("#15803d"), Color.WHITE, 210, 38, 12)
	btn_ing.disabled = int(floor(float(Variables_Dinamicas.Dinero))) <= 0
	btn_ing.pressed.connect(func() -> void: _Abrir_Conversion("ingresar"))
	hp.add_child(btn_ing)
	_modal_body.add_child(pie)


func _Comprar_Mejora(clave: String) -> void:
	var r: Dictionary = Sistema_Granja.Comprar_Mejora(clave)
	if bool(r.get("ok", false)):
		_Sonido("star")
		_Mostrar_Toast("Mejora comprada: %s" % Datos.MEJORAS[clave].get("nombre", clave), Estilos_UI.EXITO)
		if clave.begins_with("ampliar") and _mundo != null:
			_mundo.centrar_camara(false)
		_Abrir_Mejoras()
		_Actualizar_Todo()
	else:
		_Mostrar_Toast(str(r.get("motivo", "No se pudo comprar.")), Estilos_UI.PELIGRO)


# ------------------------------------------------------------------
# Banco de la Granja: Cobrar (MG → €) e Ingresar (€ → MG · 1:1)
# ------------------------------------------------------------------

func _Abrir_Conversion(tab: String = "cobrar") -> void:
	_tab_banco = tab if tab in ["cobrar", "ingresar"] else "cobrar"
	var es_ingreso: bool = (_tab_banco == "ingresar")
	_Abrir_Modal(
		"Ingresar euros a la granja" if es_ingreso else "Cambiar a euros",
		"Dinero del Sim → Monedas de Granja (relación 1:1)" if es_ingreso else "Monedas de Granja → saldo del Sim",
		"plus" if es_ingreso else "hand-coins",
		Estilo.VERDE if es_ingreso else Estilo.ORO)

	# Pestañas bidireccionales Cobrar / Ingresar.
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 10)
	_modal_body.add_child(tabs)
	var b_cob := Estilo.crear_boton_hud(
		"Cobrar (MG → €)", "hand-coins",
		Color.WHITE if not es_ingreso else Estilo.ORO_OSCURO,
		Estilo.ORO if not es_ingreso else Estilo.PERGAMINO,
		Estilo.ORO_OSCURO if not es_ingreso else Estilo.MADERA_CLARA,
		Color.WHITE if not es_ingreso else Estilo.TINTA, 210, 42, 13)
	b_cob.pressed.connect(func() -> void: _Abrir_Conversion("cobrar"))
	tabs.add_child(b_cob)

	var b_ing := Estilo.crear_boton_hud(
		"Ingresar (€ → MG · 1:1)", "plus",
		Color.WHITE if es_ingreso else Estilo.VERDE_BOSQUE,
		Estilo.VERDE if es_ingreso else Estilo.PERGAMINO,
		Color("#15803d") if es_ingreso else Estilo.MADERA_CLARA,
		Color.WHITE if es_ingreso else Estilo.TINTA, 230, 42, 13)
	b_ing.pressed.connect(func() -> void: _Abrir_Conversion("ingresar"))
	tabs.add_child(b_ing)

	if es_ingreso:
		_Construir_Contenido_Ingresar()
	else:
		_Construir_Contenido_Cobrar()


func _Construir_Contenido_Ingresar() -> void:
	var disponible_eur: int = maxi(0, int(floor(float(Variables_Dinamicas.Dinero))))
	var monedas_act: int = int(Sistema_Granja.Estado().get("Monedas", 0))

	if disponible_eur <= 0:
		_modal_body.add_child(_Parrafo("No tienes euros disponibles en el saldo del Sim para trasladar a la granja."))
		return

	_modal_body.add_child(_Parrafo(
		"Saldo del Sim: %s € · Monedas de Granja actuales: %s MG · Relación fija 1 € = 1 MG." % [
			Datos.formatear_numero(disponible_eur), Datos.formatear_numero(monedas_act)]))

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	_modal_body.add_child(fila)
	fila.add_child(Estilos_UI.titulo("Cantidad (€):", 16, Estilo.TINTA))

	_spin_cambio = SpinBox.new()
	_spin_cambio.min_value = 0
	_spin_cambio.max_value = disponible_eur
	_spin_cambio.step = 1
	_spin_cambio.value = mini(50, disponible_eur)
	_spin_cambio.custom_minimum_size = Vector2(180, 46)
	var linea := _spin_cambio.get_line_edit()
	if linea != null:
		linea.add_theme_font_override("font", Estilos_UI.fuente_ui(700))
		linea.add_theme_font_size_override("font_size", 18)
		linea.add_theme_color_override("font_color", Estilo.TINTA)
		linea.add_theme_stylebox_override("normal", Estilo.panel_madera(Estilo.CREMA, Estilo.MADERA_CLARA, 12, 2, 0))
		linea.add_theme_stylebox_override("focus", Estilo.panel_madera(Estilo.VERDE_CLARO, Estilo.VERDE, 12, 2, 0))
		linea.alignment = HORIZONTAL_ALIGNMENT_CENTER
	fila.add_child(_spin_cambio)

	var botones := HBoxContainer.new()
	botones.add_theme_constant_override("separation", 8)
	_modal_body.add_child(botones)
	for cantidad in [10, 50, 100, 500]:
		var b := Estilo.crear_boton_hud("%d €" % cantidad, "", Estilo.VERDE_BOSQUE, Estilo.VERDE_CLARO, Estilo.VERDE, Estilo.VERDE_BOSQUE, 86, 38, 13)
		b.pressed.connect(func() -> void:
			if _spin_cambio != null:
				_spin_cambio.value = mini(cantidad, disponible_eur))
		botones.add_child(b)
	var b_todo := Estilo.crear_boton_hud("Todo (%d €)" % disponible_eur, "", Estilo.VERDE_BOSQUE, Estilo.VERDE_CLARO, Estilo.VERDE, Estilo.VERDE_BOSQUE, 140, 38, 13)
	b_todo.pressed.connect(func() -> void:
		if _spin_cambio != null:
			_spin_cambio.value = disponible_eur)
	botones.add_child(b_todo)

	_lbl_preview = Estilos_UI.titulo("Recibirás 0 MG", 26, Color("#15803d"))
	_modal_body.add_child(_lbl_preview)
	_lbl_tasa = _Parrafo("Relación fija 1:1 · traslado inmediato sin límite diario")
	_modal_body.add_child(_lbl_tasa)

	var btn := Estilo.crear_boton_hud("Trasladar a la granja", "plus", Color.WHITE, Estilo.VERDE, Color("#15803d"), Color.WHITE, 280, 48, 15)
	btn.pressed.connect(_Confirmar_Ingreso)
	_modal_body.add_child(btn)
	_modal_body.add_child(_Parrafo("Los euros ingresados se convierten en Monedas de Granja (1:1) al instante. Puedes volver a retirarlos con «Cobrar» cuando quieras."))
	_spin_cambio.value_changed.connect(_Actualizar_Preview_Ingreso)
	_Actualizar_Preview_Ingreso(_spin_cambio.value)


func _Actualizar_Preview_Ingreso(_valor: float) -> void:
	if _spin_cambio == null or _lbl_preview == null or _lbl_tasa == null:
		return
	var preview: Dictionary = Sistema_Granja.Previsualizar_Ingreso(int(_spin_cambio.value))
	var mg: int = int(preview.get("monedas", 0))
	_lbl_preview.text = "Recibirás +%s MG" % Datos.formatear_numero(mg)
	_lbl_tasa.text = "Coste: %s € · Relación exacta 1:1 (1 € = 1 MG)" % Datos.formatear_numero(mg)


func _Confirmar_Ingreso() -> void:
	if _spin_cambio == null:
		return
	var r: Dictionary = Sistema_Granja.Ingresar(int(_spin_cambio.value))
	if bool(r.get("ok", false)):
		_Sonido("coin")
		_Mostrar_Toast("+%s MG ingresados en la granja (1:1)" % Datos.formatear_numero(int(r.get("monedas", 0))), Estilos_UI.EXITO)
		_Cerrar_Modal()
		_Actualizar_Todo()
	else:
		_Mostrar_Toast(str(r.get("motivo", "No se pudo ingresar.")), Estilos_UI.PELIGRO)


func _Construir_Contenido_Cobrar() -> void:
	var estado: Dictionary = Sistema_Granja.Estado()
	var monedas: int = int(estado.get("Monedas", 0))
	var convertido: int = Sistema_Granja.Convertido_Hoy()
	var tasa: float = Sistema_Granja.Tasa_Marginal()

	if monedas <= 0:
		_modal_body.add_child(_Parrafo("No tienes Monedas de Granja. Vende productos en el Almacén o ingresa euros (1:1) en la pestaña superior."))
		return

	_modal_body.add_child(_Parrafo("Hoy has cambiado %d MG · tasa del siguiente MG: %.2f · reinicio diario a las 04:00." % [convertido, tasa]))

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	_modal_body.add_child(fila)
	fila.add_child(Estilos_UI.titulo("Cantidad (MG):", 16, Estilo.TINTA))

	_spin_cambio = SpinBox.new()
	_spin_cambio.min_value = 0
	_spin_cambio.max_value = monedas
	_spin_cambio.step = 1
	_spin_cambio.value = mini(10, monedas)
	_spin_cambio.custom_minimum_size = Vector2(180, 46)
	var linea := _spin_cambio.get_line_edit()
	if linea != null:
		linea.add_theme_font_override("font", Estilos_UI.fuente_ui(700))
		linea.add_theme_font_size_override("font_size", 18)
		linea.add_theme_color_override("font_color", Estilo.TINTA)
		linea.add_theme_stylebox_override("normal", Estilo.panel_madera(Estilo.CREMA, Estilo.MADERA_CLARA, 12, 2, 0))
		linea.add_theme_stylebox_override("focus", Estilo.panel_madera(Estilo.ORO_SUAVE, Estilo.ORO, 12, 2, 0))
		linea.alignment = HORIZONTAL_ALIGNMENT_CENTER
	fila.add_child(_spin_cambio)

	var botones := HBoxContainer.new()
	botones.add_theme_constant_override("separation", 8)
	_modal_body.add_child(botones)
	for cantidad in [10, 50, 100]:
		var b := Estilo.crear_boton_hud(str(cantidad), "", Estilo.ORO_OSCURO, Estilo.ORO_SUAVE, Estilo.ORO, Estilo.ORO_OSCURO, 80, 38, 13)
		b.pressed.connect(func() -> void:
			if _spin_cambio != null:
				_spin_cambio.value = mini(cantidad, monedas))
		botones.add_child(b)
	var b_todo := Estilo.crear_boton_hud("Todo (%d)" % monedas, "", Estilo.ORO_OSCURO, Estilo.ORO_SUAVE, Estilo.ORO, Estilo.ORO_OSCURO, 130, 38, 13)
	b_todo.pressed.connect(func() -> void:
		if _spin_cambio != null:
			_spin_cambio.value = monedas)
	botones.add_child(b_todo)

	_lbl_preview = Estilos_UI.titulo("Recibirás 0,00 €", 26, Color("#15803d"))
	_modal_body.add_child(_lbl_preview)
	_lbl_tasa = _Parrafo("Tasa media: 1,00 · primeros 10 MG del día a 1:1")
	_modal_body.add_child(_lbl_tasa)

	var btn := Estilo.crear_boton_hud("Cambiar a euros", "hand-coins", Color.WHITE, Estilo.ORO, Estilo.ORO_OSCURO, Color.WHITE, 260, 48, 15)
	btn.pressed.connect(_Confirmar_Cambio)
	_modal_body.add_child(btn)
	_modal_body.add_child(_Parrafo("La tasa es marginal: los primeros 10 MG del día son 1:1; después baja en logarítmico hasta un mínimo de 0,10."))
	_spin_cambio.value_changed.connect(_Actualizar_Preview_Cambio)
	_Actualizar_Preview_Cambio(_spin_cambio.value)


func _Actualizar_Preview_Cambio(_valor: float) -> void:
	if _spin_cambio == null or _lbl_preview == null or _lbl_tasa == null:
		return
	var preview: Dictionary = Sistema_Granja.Previsualizar_Cambio(int(_spin_cambio.value))
	_lbl_preview.text = "Recibirás %.2f €" % float(preview.get("euros", 0.0))
	_lbl_tasa.text = "Tasa media: %.2f · tasa del siguiente MG: %.2f" % [
		float(preview.get("tasa_media", 0.0)), float(preview.get("tasa_marginal", 0.0))]


func _Confirmar_Cambio() -> void:
	if _spin_cambio == null:
		return
	var r: Dictionary = Sistema_Granja.Cambiar(int(_spin_cambio.value))
	if bool(r.get("ok", false)):
		_Sonido("coin")
		_Mostrar_Toast("+%.2f € al dinero del Sim" % float(r.get("euros", 0.0)), Estilos_UI.EXITO)
		_Cerrar_Modal()
		_Actualizar_Todo()
	else:
		_Mostrar_Toast(str(r.get("motivo", "No se pudo cambiar.")), Estilos_UI.PELIGRO)


# ------------------------------------------------------------------
# Flotantes, SFX y Toast
# ------------------------------------------------------------------

func _Mostrar_Flotante_Objeto(objeto_id: int, texto: String, color: Color) -> void:
	if _mundo == null:
		return
	_Mostrar_Flotante(_mundo.posicion_pantalla_objeto(objeto_id), texto, color)


func _Mostrar_Flotante(pos: Vector2, texto: String, color: Color) -> void:
	if _capa_flotantes == null or not is_inside_tree():
		return
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", Estilo.panel_madera(Color("#fffbeb"), color, 14, 2, 4))
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 10)
	m.add_theme_constant_override("margin_right", 10)
	m.add_theme_constant_override("margin_top", 3)
	m.add_theme_constant_override("margin_bottom", 4)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(m)
	var lbl := Estilos_UI.texto(texto, 13, color.darkened(0.25), 700)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(lbl)
	panel.position = pos - Vector2(46.0, 16.0)
	_capa_flotantes.add_child(panel)

	var tw := panel.create_tween().set_parallel(true)
	tw.tween_property(panel, "position:y", panel.position.y - 48.0, 0.95).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate:a", 0.0, 0.45).set_delay(0.50)
	tw.chain().tween_callback(panel.queue_free)


func _Sonido(nombre: String, volumen_db: float = -6.0) -> void:
	var ruta := "res://Sonidos/SFX/%s.wav" % nombre
	if not ResourceLoader.exists(ruta):
		return
	var player := AudioStreamPlayer.new()
	player.stream = load(ruta)
	player.bus = "SFX"
	player.volume_db = volumen_db
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func _Construir_Toast() -> void:
	_toast = PanelContainer.new()
	_toast.position = Vector2(380, 82)
	_toast.size = Vector2(520, 44)
	_toast.visible = false
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.z_index = 290
	_toast.add_theme_stylebox_override("panel",
		Estilo.panel_madera(Estilo.VERDE_BOSQUE, Estilo.ORO, 16, 2, 6))
	add_child(_toast)

	_toast_lbl = Label.new()
	_toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_toast_lbl.add_theme_font_override("font", Estilos_UI.fuente_ui(600))
	_toast_lbl.add_theme_font_size_override("font_size", 14)
	_toast_lbl.add_theme_color_override("font_color", Color.WHITE)
	_toast_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	_toast_lbl.offset_left = 12
	_toast_lbl.offset_right = -12
	_toast_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.add_child(_toast_lbl)


func _Mostrar_Toast(texto: String, color: Color = Estilos_UI.EXITO) -> void:
	if _toast == null:
		return
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_lbl.text = texto
	var st := _toast.get_theme_stylebox("panel") as StyleBoxFlat
	if st != null:
		st.bg_color = color.darkened(0.35)
		st.border_color = color
	var w: float = size.x if size.x > 100.0 else float(TAMANO_HORIZONTAL.x)
	_toast.visible = true
	_toast.position = Vector2((w - _toast.size.x) * 0.5, 68.0)
	_toast.modulate.a = 0.0
	_toast_tween = create_tween()
	_toast_tween.set_parallel(false)
	_toast_tween.tween_property(_toast, "position:y", 82.0, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_toast_tween.parallel().tween_property(_toast, "modulate:a", 1.0, 0.14)
	_toast_tween.tween_interval(2.4)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.25)
	_toast_tween.tween_callback(func() -> void: _toast.visible = false)
