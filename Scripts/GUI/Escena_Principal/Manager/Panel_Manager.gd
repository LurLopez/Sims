class_name Panel_Manager
extends Control

## Pantalla principal horizontal (1280x720) del minijuego "El Mánager":
## rotación automática a apaisado al entrar y restauración vertical al salir,
## desbloqueo, fundación con vista previa en directo, resumen del club,
## plantilla humana, pizarra táctica interactiva, mercado/cantera y liga.

signal cerrado

const TAMANO_HORIZONTAL := Vector2i(1280, 720)
const TAMANO_VERTICAL := Vector2i(720, 1280)

const NOMBRES_PESTANAS := [
	["club", "Club"],
	["plantilla", "Plantilla"],
	["tactica", "Táctica"],
	["mercado", "Mercado"],
	["liga", "Liga"],
]

const COLORES_CLUB := [
	["Verde", "#0f766e"],
	["Esmeralda", "#059669"],
	["Azul", "#1d4ed8"],
	["Celeste", "#0284c7"],
	["Rojo", "#dc2626"],
	["Granate", "#9f1239"],
	["Oro", "#d97706"],
	["Violeta", "#7c3aed"],
	["Negro", "#1e293b"],
	["Blanco", "#f8fafc"],
	["Naranja", "#ea580c"],
	["Rosa", "#db2777"],
]

var gestionar_orientacion: bool = true
var _orientacion_aplicada: bool = false
var _quit_on_go_back_previo: bool = false
var _quit_on_go_back_guardado: bool = false
var _saliendo: bool = false

var _tab_actual: String = "club"
var _pestanas_btns: Dictionary = {}
var _scroll: ScrollContainer
var _contenido: VBoxContainer
var _cab_escudo: Cresta_Manager
var _cab_icono: Control
var _subtitulo_cab: Label
var _barra_estado_fila: HBoxContainer
var _chip_presupuesto: Label
var _chip_confianza: Label
var _chip_cita: Label
var _barra_tabs_cont: PanelContainer
var _barra_tabs: HBoxContainer

var _modal_ficha: Control = null
var _modal_oferta: Control = null
var _modal_partido: Panel_Manager_Partido = null
var _dialogo_info: Control = null

var _fund_nombre: LineEdit
var _fund_ciudad: LineEdit
var _fund_color_a: Color = Color("#0f766e")
var _fund_color_b: Color = Color("#f8fafc")
var _fund_patron: int = 1
var _fund_preview_box: HBoxContainer

var _plantilla_filtro_rol: String = ""
var _plantilla_orden: String = "calidad"
var _tactica_slot_sel: int = -1
var _tactica_ban_sel: String = ""

var _feedback_club: String = ""
var _feedback_club_ok: bool = true
var _feedback_plantilla: String = ""
var _feedback_plantilla_ok: bool = true
var _feedback_tactica: String = ""
var _feedback_tactica_ok: bool = true

var _mercado_modo: String = "fichar"
var _mercado_filtro_rol: String = ""
var _mercado_solo_asequibles: bool = true
var _mercado_solo_jovenes: bool = false
var _mercado_limite: int = 20
var _liga_division: int = 4

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	if not (get_parent() is SubViewport) and get_tree() != null:
		_quit_on_go_back_previo = get_tree().is_quit_on_go_back()
		_quit_on_go_back_guardado = true
		get_tree().set_quit_on_go_back(false)
	_Aplicar_Orientacion_Horizontal()
	var club: Dictionary = Sistema_Manager.Club_Usuario()
	if not club.is_empty():
		_liga_division = int(club.get("division", 4))
	_Construir_Base()
	_Refrescar(true)


func _exit_tree() -> void:
	if _quit_on_go_back_guardado and get_tree() != null:
		get_tree().set_quit_on_go_back(_quit_on_go_back_previo)
	if _orientacion_aplicada:
		_Aplicar_Orientacion_Vertical()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_Volver_Atras()
		if get_viewport() != null:
			get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_Volver_Atras()


func _Volver_Atras() -> void:
	if is_instance_valid(_dialogo_info):
		_Cerrar_Dialogos()
		return
	if is_instance_valid(_modal_oferta):
		_Cerrar_Modal_Oferta()
		return
	if is_instance_valid(_modal_ficha):
		_Cerrar_Ficha()
		return
	if is_instance_valid(_modal_partido):
		_modal_partido._Intentar_Salir()
		return
	_Solicitar_Salida()


func _Solicitar_Salida() -> void:
	if _saliendo:
		return
	_saliendo = true
	Estilo_Manager.reproducir_sfx("click")
	cerrado.emit()


func _Aplicar_Orientacion_Horizontal() -> void:
	if not gestionar_orientacion or get_parent() is SubViewport:
		return
	if DisplayServer.get_name() == "headless":
		return
	_orientacion_aplicada = true
	if DisplayServer.get_name().to_lower() in ["android", "ios"]:
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
	var win: Window = get_window()
	if win != null:
		win.content_scale_size = TAMANO_HORIZONTAL
	if OS.has_feature("pc"):
		DisplayServer.window_set_size(TAMANO_HORIZONTAL)
		var pantalla_h := DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
		DisplayServer.window_set_position(Vector2i(
			maxi(0, (pantalla_h.x - TAMANO_HORIZONTAL.x) / 2),
			maxi(0, (pantalla_h.y - TAMANO_HORIZONTAL.y) / 2)))


func _Aplicar_Orientacion_Vertical() -> void:
	_orientacion_aplicada = false
	if not gestionar_orientacion or get_parent() is SubViewport:
		return
	if DisplayServer.get_name() == "headless":
		return
	if DisplayServer.get_name().to_lower() in ["android", "ios"]:
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	var win: Window = get_window()
	if win != null:
		win.content_scale_size = TAMANO_VERTICAL
	if OS.has_feature("pc"):
		DisplayServer.window_set_size(TAMANO_VERTICAL)
		var pantalla_v := DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
		DisplayServer.window_set_position(Vector2i(
			maxi(0, (pantalla_v.x - TAMANO_VERTICAL.x) / 2),
			maxi(0, (pantalla_v.y - TAMANO_VERTICAL.y) / 2)))


func Refrescar() -> void:
	_Refrescar(false)


func _Construir_Base() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var fondo := ColorRect.new()
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.color = Estilos_UI.FONDO
	add_child(fondo)

	var raiz := VBoxContainer.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.add_theme_constant_override("separation", 0)
	add_child(raiz)

	_Construir_Cabecera(raiz)
	_Construir_Tabs(raiz)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	raiz.add_child(_scroll)

	var margen := MarginContainer.new()
	margen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margen.add_theme_constant_override("margin_left", 18)
	margen.add_theme_constant_override("margin_right", 18)
	margen.add_theme_constant_override("margin_top", 12)
	margen.add_theme_constant_override("margin_bottom", 20)
	_scroll.add_child(margen)

	_contenido = VBoxContainer.new()
	_contenido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_contenido.add_theme_constant_override("separation", 12)
	margen.add_child(_contenido)


func _Construir_Cabecera(raiz: VBoxContainer) -> void:
	var cab := PanelContainer.new()
	cab.add_theme_stylebox_override("panel", Estilos_UI.caja(
		Estilo_Manager.COLOR_MANAGER, 0, Estilo_Manager.COLOR_MANAGER_OSCURO, 0, 0))
	raiz.add_child(cab)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 18)
	m.add_theme_constant_override("margin_right", 18)
	m.add_theme_constant_override("margin_top", 8)
	m.add_theme_constant_override("margin_bottom", 8)
	cab.add_child(m)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	m.add_child(h)

	_cab_escudo = Cresta_Manager.new()
	_cab_escudo.custom_minimum_size = Vector2(38, 44)
	_cab_escudo.visible = false
	h.add_child(_cab_escudo)

	_cab_icono = Estilos_UI.badge_icono("trophy", 40, 20, Color("#0b524c"), Color.WHITE, 12)
	h.add_child(_cab_icono)

	var titulos := VBoxContainer.new()
	titulos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titulos.add_theme_constant_override("separation", 1)
	h.add_child(titulos)

	var tit := Estilos_UI.titulo("El Mánager", 20, Color.WHITE)
	titulos.add_child(tit)

	_subtitulo_cab = Estilos_UI.texto("Gestión y vestuario de tu club", 12, Color("#d1fae5"), 600)
	_subtitulo_cab.clip_text = true
	titulos.add_child(_subtitulo_cab)

	_barra_estado_fila = HBoxContainer.new()
	_barra_estado_fila.add_theme_constant_override("separation", 8)
	_barra_estado_fila.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(_barra_estado_fila)

	_chip_presupuesto = _Crear_Pildora_Estado(_barra_estado_fila, Estilo_Manager.COLOR_ORO)
	_chip_confianza = _Crear_Pildora_Estado(_barra_estado_fila, Estilo_Manager.COLOR_MANAGER_OSCURO)
	_chip_cita = _Crear_Pildora_Estado(_barra_estado_fila, Estilos_UI.AZUL)

	var btn_cerrar := Estilo_Manager.boton("Volver", "secundario", "arrow-left", Estilos_UI.TINTA, 40)
	btn_cerrar.custom_minimum_size = Vector2(106, 40)
	btn_cerrar.pressed.connect(_Solicitar_Salida)
	h.add_child(btn_cerrar)


func _Crear_Pildora_Estado(parent: HBoxContainer, color: Color) -> Label:
	var p := PanelContainer.new()
	var st := Estilos_UI.caja(Color.WHITE, 12, color.lerp(Color.WHITE, 0.35), 1, 0)
	st.content_margin_left = 10
	st.content_margin_right = 10
	st.content_margin_top = 5
	st.content_margin_bottom = 5
	p.add_theme_stylebox_override("panel", st)
	parent.add_child(p)

	var lbl := Estilos_UI.texto("", 11, color, 700)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(lbl)
	return lbl


func _Construir_Tabs(raiz: VBoxContainer) -> void:
	_barra_tabs_cont = PanelContainer.new()
	_barra_tabs_cont.add_theme_stylebox_override("panel", Estilos_UI.caja(
		Color.WHITE, 0, Estilos_UI.BORDE, 1, 0))
	raiz.add_child(_barra_tabs_cont)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 18)
	m.add_theme_constant_override("margin_right", 18)
	m.add_theme_constant_override("margin_top", 6)
	m.add_theme_constant_override("margin_bottom", 6)
	_barra_tabs_cont.add_child(m)

	_barra_tabs = HBoxContainer.new()
	_barra_tabs.add_theme_constant_override("separation", 8)
	m.add_child(_barra_tabs)

	for entrada in NOMBRES_PESTANAS:
		var id_tab: String = str(entrada[0])
		var texto_tab: String = str(entrada[1])
		var btn := Estilo_Manager.boton(texto_tab, "chip", "", Estilos_UI.TINTA, 38)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 13)
		btn.clip_text = true
		var tab_local: String = id_tab
		btn.pressed.connect(func():
			Estilo_Manager.reproducir_sfx("click")
			_tab_actual = tab_local
			_Refrescar(true))
		_barra_tabs.add_child(btn)
		_pestanas_btns[id_tab] = btn


func _Refrescar(ir_al_inicio: bool = true) -> void:
	for child in _contenido.get_children():
		child.queue_free()

	var desbloqueado: bool = Sistema_Manager.Desbloqueado()
	var activo: bool = Sistema_Manager.Activo()
	var club: Dictionary = Sistema_Manager.Club_Usuario()

	_Actualizar_Cabecera_Y_Tabs(desbloqueado, activo, club)

	if not desbloqueado:
		_Pantalla_Desbloqueo()
	elif not activo or club.is_empty():
		_Pantalla_Fundacion()
	else:
		match _tab_actual:
			"club":
				_Pantalla_Club(club)
			"plantilla":
				_Pantalla_Plantilla(club)
			"tactica":
				_Pantalla_Tactica(club)
			"mercado":
				Panel_Manager_Vistas.construir_pestana_mercado(self, club)
			"liga":
				Panel_Manager_Vistas.construir_pestana_liga(self)
			_:
				_Pantalla_Club(club)

	if ir_al_inicio and is_instance_valid(_scroll):
		_scroll.scroll_vertical = 0


func _Actualizar_Cabecera_Y_Tabs(desbloqueado: bool, activo: bool, club: Dictionary) -> void:
	var tiene_club: bool = desbloqueado and activo and not club.is_empty()
	_cab_escudo.visible = tiene_club
	_cab_icono.visible = not tiene_club
	_barra_estado_fila.visible = tiene_club
	_barra_tabs_cont.visible = tiene_club

	if not desbloqueado:
		_subtitulo_cab.text = "Desbloquea tu carrera como presidente y entrenador"
		return
	if not tiene_club:
		_subtitulo_cab.text = "Funda tu propio club · 18 futbolistas iniciales"
		return

	_cab_escudo.configurar(str(club.get("nombre", "Club")),
		club.get("colores", Datos_Manager.COLORES_POR_DEFECTO),
		int(club.get("escudo_patron", 1)), 0.0)
	_subtitulo_cab.text = "%s · %s · Temporada %d · Jornada %d/4" % [
		str(club.get("nombre", "Tu Club")),
		Datos_Manager.Nombre_Division(int(club.get("division", 4))),
		Sistema_Manager.Obtener_Temporada(),
		mini(4, Sistema_Manager.Obtener_Jornada() + 1)]

	_chip_presupuesto.text = "Caja %s" % _Euros(int(club.get("presupuesto", 0)))
	var conf: int = int(round(float(club.get("confianza_directiva", 70.0))))
	_chip_confianza.text = "Directiva %d%%" % conf
	if Sistema_Manager.Puede_Jugar_Manual():
		_chip_cita.text = "PARTIDO HOY"
	elif Sistema_Manager.Puede_Jugar_Amistoso():
		_chip_cita.text = "Amistoso libre"
	else:
		_chip_cita.text = "Jornada %d/4" % Sistema_Manager.Obtener_Jornada()

	var hay_aviso_tactica: bool = _Hay_Aviso_Tactica(club)
	for entrada in NOMBRES_PESTANAS:
		var id_tab: String = str(entrada[0])
		var base_txt: String = str(entrada[1])
		var btn: Button = _pestanas_btns.get(id_tab, null)
		if btn == null:
			continue
		var txt: String = base_txt
		if id_tab == "club" and Sistema_Manager.Puede_Jugar_Manual():
			txt = "%s •" % base_txt
		elif id_tab == "tactica" and hay_aviso_tactica:
			txt = "%s !" % base_txt
		btn.text = txt
		var sel: bool = id_tab == _tab_actual
		Estilos_UI.aplicar_estilo_boton(btn, "primario" if sel else "chip",
			Estilo_Manager.COLOR_MANAGER if sel else Estilos_UI.TINTA)


func _Hay_Aviso_Tactica(club: Dictionary) -> bool:
	var slots: Array = Simulador_Manager.Evaluar_Alineacion_Slots(club)
	for s in slots:
		if float(s.get("afinidad", 1.0)) < 0.70:
			return true
		if float(s.get("energia", 100.0)) < 35.0:
			return true
	return false


# ── PANTALLA DE DESBLOQUEO (HORIZONTAL) ──────────────────────────────────────

func _Pantalla_Desbloqueo() -> void:
	var hero := _Tarjeta()
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 16)
	hero.add_child(fila)

	fila.add_child(Estilo_Manager.crear_retrato_manager(76,
		[Estilo_Manager.COLOR_MANAGER.to_html(false), "#ffffff"], "motivado", true, "retrato"))

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	fila.add_child(info)
	info.add_child(Estilos_UI.titulo("Tu paso al banquillo", 22, Estilo_Manager.COLOR_MANAGER_OSCURO))
	info.add_child(Estilos_UI.parrafo(
		"Crea tu propio club desde cero, elige los colores, trata cara a cara con tu vestuario y dirige cada partido desde la banda.",
		13, Estilos_UI.TINTA_SUAVE))

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 14)
	_contenido.add_child(cols)

	var col_izq := _Crear_Columna(cols, 1.1)
	var col_der := _Crear_Columna(cols, 0.9)

	# Vía 1: Retiro deportivo.
	var c_retiro := _Tarjeta(Color.WHITE, col_izq)
	_Titulo_Seccion(c_retiro, "Vía 1 · Retirarte como futbolista",
		"Cuelga las botas y aprovecha tu prestigio en los terrenos de juego")
	var puede_ret: bool = Sistema_Manager.Puede_Desbloquear_Por_Retiro()
	c_retiro.add_child(Estilos_UI.pill_estado(
		"Disponible: puedes retirarte y pasar al banquillo" if puede_ret else "Necesitas una carrera en Superliga lista para el retiro",
		Estilos_UI.EXITO_SUAVE if puede_ret else Estilos_UI.SUPERFICIE_2,
		Estilos_UI.EXITO_OSCURO if puede_ret else Estilos_UI.TINTA_SUAVE))
	var btn_ret := Estilo_Manager.boton(
		"Retirarme y empezar de mánager", "exito", "trophy", Estilos_UI.EXITO, 48)
	btn_ret.disabled = not puede_ret
	btn_ret.pressed.connect(func():
		var res: Dictionary = Sistema_Manager.Desbloquear_Por_Retiro()
		if res.get("ok", false):
			Estilo_Manager.reproducir_sfx("exito")
			_Refrescar(true)
		else:
			Estilo_Manager.reproducir_sfx("error")
			_Mostrar_Info("Aún no disponible", str(res.get("motivo", "No disponible."))))
	c_retiro.add_child(btn_ret)

	# Vía 2: Título de entrenador.
	var c_tit := _Tarjeta(Color.WHITE, col_izq)
	var coste_tit: int = Sistema_Manager.Coste_Desbloqueo_Titulo()
	var dinero_p: int = int(Variables_Dinamicas.Dinero)
	var en_carrera: bool = Sistema_Futbol.Carrera_Activa()
	_Titulo_Seccion(c_tit, "Vía 2 · Título oficial de entrenador",
		"Sácate la licencia pagando %s de tu bolsillo personal" % _Euros(coste_tit))
	_Barra(c_tit, "Tu dinero personal disponible", float(mini(dinero_p, coste_tit)),
		Estilo_Manager.COLOR_MANAGER, " / %s" % _Euros(coste_tit), float(maxi(1, coste_tit)))
	var msg_tit: String = "Tienes un contrato activo como jugador: rescíndelo o retírate primero." if en_carrera \
		else ("Te faltan %s para pagar las tasas." % _Euros(coste_tit - dinero_p) if dinero_p < coste_tit \
		else "Listo para sacarte el título hoy mismo.")
	c_tit.add_child(Estilos_UI.pill_estado(msg_tit,
		Estilo_Manager.COLOR_ORO_SUAVE if (en_carrera or dinero_p < coste_tit) else Estilos_UI.EXITO_SUAVE,
		Estilo_Manager.COLOR_ORO if (en_carrera or dinero_p < coste_tit) else Estilos_UI.EXITO_OSCURO))
	var btn_tit := Estilo_Manager.boton(
		"Pagar título (%s)" % _Euros(coste_tit),
		"oro", "graduation-cap", Estilo_Manager.COLOR_ORO, 48)
	btn_tit.disabled = en_carrera or dinero_p < coste_tit
	btn_tit.pressed.connect(func():
		var res: Dictionary = Sistema_Manager.Desbloquear_Por_Titulo()
		if res.get("ok", false):
			Estilo_Manager.reproducir_sfx("exito")
			_Refrescar(true)
		else:
			Estilo_Manager.reproducir_sfx("error")
			_Mostrar_Info("No se pudo desbloquear", str(res.get("motivo", "No disponible."))))
	c_tit.add_child(btn_tit)

	var feat := _Tarjeta(Color("#f0fdfa"), col_der)
	_Titulo_Seccion(feat, "Qué te espera dentro")
	var puntos := [
		["Vestuario con alma", "18 futbolistas con rostro propio, rasgo y frases según su ánimo.", "users"],
		["Pizarra táctica visual", "Intercambia puestos tocando sobre el césped y ajusta presión o mentalidad.", "target"],
		["Partidos vivos en 2D", "Campo animado horizontal, charla en el 45' y cambios desde la banda.", "play"],
		["Cantera e instalaciones", "Amplía el estadio, mejora los entrenamientos y asciende hasta Superliga.", "trending-up"],
	]
	for p in puntos:
		var box := HBoxContainer.new()
		box.add_theme_constant_override("separation", 10)
		feat.add_child(box)
		box.add_child(Estilos_UI.badge_icono(str(p[2]), 36, 17,
			Estilo_Manager.COLOR_MANAGER_SUAVE, Estilo_Manager.COLOR_MANAGER_OSCURO, 10))
		var tv := VBoxContainer.new()
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_theme_constant_override("separation", 2)
		box.add_child(tv)
		tv.add_child(Estilos_UI.texto(str(p[0]), 13, Estilos_UI.TINTA, 700))
		tv.add_child(Estilos_UI.parrafo(str(p[1]), 12, Estilos_UI.TINTA_SUAVE))


# ── PANTALLA DE FUNDACIÓN DE CLUB (HORIZONTAL) ───────────────────────────────

func _Pantalla_Fundacion() -> void:
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 14)
	_contenido.add_child(cols)

	var col_izq := _Crear_Columna(cols, 0.0, 450.0)
	var col_der := _Crear_Columna(cols, 1.0)

	var bienvenida := _Tarjeta(Color.WHITE, col_izq)
	var cab_h := HBoxContainer.new()
	cab_h.add_theme_constant_override("separation", 12)
	bienvenida.add_child(cab_h)
	cab_h.add_child(Estilo_Manager.crear_retrato_manager(62,
		[_fund_color_a.to_html(false), _fund_color_b.to_html(false)], "motivado", true, "retrato"))
	var bv := VBoxContainer.new()
	bv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bv.add_theme_constant_override("separation", 3)
	cab_h.add_child(bv)
	bv.add_child(Estilos_UI.titulo("Funda tu club", 20, Estilo_Manager.COLOR_MANAGER_OSCURO))
	bv.add_child(Estilos_UI.parrafo("Diseña tu identidad, escudo y colores.", 12, Estilos_UI.TINTA_SUAVE))
	var btn_rand := Estilo_Manager.boton("Sugerir identidad", "chip", "sparkles", Estilo_Manager.COLOR_MANAGER, 40)
	btn_rand.pressed.connect(_Sugerir_Identidad_Club)
	bienvenida.add_child(btn_rand)

	# Vista previa viva del escudo + jugador + mánager.
	var prev_card := _Tarjeta(Color("#ecfdf5"), col_izq)
	_Titulo_Seccion(prev_card, "Identidad en directo", "Escudo, equipación y entrenador")
	_fund_preview_box = HBoxContainer.new()
	_fund_preview_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_fund_preview_box.add_theme_constant_override("separation", 16)
	prev_card.add_child(_fund_preview_box)
	_Actualizar_Preview_Fundacion()

	var btn_fundar := Estilo_Manager.boton(
		"Fundar club y empezar", "exito", "trophy", Estilos_UI.EXITO, 52)
	btn_fundar.pressed.connect(_Intentar_Fundar_Club)
	prev_card.add_child(btn_fundar)

	# Formulario derecho.
	var form := _Tarjeta(Color.WHITE, col_der)
	_Titulo_Seccion(form, "Datos e identidad del club")

	var nom_prev: String = _fund_nombre.text if is_instance_valid(_fund_nombre) else ""
	var ciu_prev: String = _fund_ciudad.text if is_instance_valid(_fund_ciudad) else ""

	var campos_h := HBoxContainer.new()
	campos_h.add_theme_constant_override("separation", 12)
	form.add_child(campos_h)

	var v_nom := VBoxContainer.new()
	v_nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v_nom.add_theme_constant_override("separation", 4)
	campos_h.add_child(v_nom)
	v_nom.add_child(Estilos_UI.texto("Nombre del club", 13, Estilos_UI.TINTA, 700))
	_fund_nombre = LineEdit.new()
	_fund_nombre.text = nom_prev
	_fund_nombre.placeholder_text = "Ej: Real Barrio FC"
	_fund_nombre.max_length = 24
	_fund_nombre.custom_minimum_size.y = 44
	_Estilizar_Campo_Texto(_fund_nombre, 15)
	_fund_nombre.text_changed.connect(func(_t: String): _Actualizar_Preview_Fundacion())
	v_nom.add_child(_fund_nombre)

	var v_ciu := VBoxContainer.new()
	v_ciu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v_ciu.add_theme_constant_override("separation", 4)
	campos_h.add_child(v_ciu)
	v_ciu.add_child(Estilos_UI.texto("Ciudad", 13, Estilos_UI.TINTA, 700))
	_fund_ciudad = LineEdit.new()
	_fund_ciudad.text = ciu_prev
	_fund_ciudad.placeholder_text = "Ej: Valoria"
	_fund_ciudad.max_length = 20
	_fund_ciudad.custom_minimum_size.y = 44
	_Estilizar_Campo_Texto(_fund_ciudad, 15)
	v_ciu.add_child(_fund_ciudad)

	form.add_child(Estilos_UI.texto("Patrón de escudo y camiseta", 13, Estilos_UI.TINTA, 700))
	var opt_patrones: Array = []
	for i in range(Datos_Manager.PATRONES_ESCUDO.size()):
		opt_patrones.append([str(i), str(Datos_Manager.PATRONES_ESCUDO[i])])
	form.add_child(Estilo_Manager.selector_chips(
		opt_patrones, str(_fund_patron), Estilo_Manager.COLOR_MANAGER,
		func(p_str: String):
			_fund_patron = int(p_str)
			_Refrescar(false), false, 12))

	var pal_h := HBoxContainer.new()
	pal_h.add_theme_constant_override("separation", 14)
	form.add_child(pal_h)

	var pv1 := VBoxContainer.new()
	pv1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pv1.add_theme_constant_override("separation", 6)
	pal_h.add_child(pv1)
	pv1.add_child(Estilos_UI.texto("Color principal", 13, Estilos_UI.TINTA, 700))
	pv1.add_child(_Crear_Paleta_Colores(true))

	var pv2 := VBoxContainer.new()
	pv2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pv2.add_theme_constant_override("separation", 6)
	pal_h.add_child(pv2)
	pv2.add_child(Estilos_UI.texto("Color secundario", 13, Estilos_UI.TINTA, 700))
	pv2.add_child(_Crear_Paleta_Colores(false))


func _Estilizar_Campo_Texto(le: LineEdit, tam: int = 15) -> void:
	var st_norm := Estilos_UI.caja(Color("#f8fafc"), 12, Estilos_UI.BORDE, 1, 0)
	st_norm.content_margin_left = 12
	st_norm.content_margin_right = 12
	var st_foc := Estilos_UI.caja(Color.WHITE, 12, Estilo_Manager.COLOR_MANAGER, 2, 0)
	st_foc.content_margin_left = 12
	st_foc.content_margin_right = 12
	le.add_theme_stylebox_override("normal", st_norm)
	le.add_theme_stylebox_override("focus", st_foc)
	le.add_theme_font_override("font", Estilos_UI.fuente_ui(600))
	le.add_theme_font_size_override("font_size", tam)
	le.add_theme_color_override("font_color", Estilos_UI.TINTA)
	le.add_theme_color_override("font_placeholder_color", Estilos_UI.TINTA_FANTASMA)
	le.add_theme_color_override("caret_color", Estilo_Manager.COLOR_MANAGER)


func _Crear_Paleta_Colores(es_principal: bool) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	var actual: Color = _fund_color_a if es_principal else _fund_color_b
	for item in COLORES_CLUB:
		var col := Color(str(item[1]))
		var sel: bool = col.is_equal_approx(actual)
		var b := Button.new()
		b.custom_minimum_size = Vector2(40, 40)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.tooltip_text = str(item[0])
		b.text = "✓" if sel else ""
		var st := StyleBoxFlat.new()
		st.bg_color = col
		st.set_corner_radius_all(10)
		st.border_width_left = 3 if sel else 1
		st.border_width_top = 3 if sel else 1
		st.border_width_right = 3 if sel else 1
		st.border_width_bottom = 3 if sel else 1
		st.border_color = Estilos_UI.TINTA if sel else Color("#94a3b8")
		st.anti_aliasing = true
		b.add_theme_stylebox_override("normal", st)
		b.add_theme_stylebox_override("hover", st)
		b.add_theme_stylebox_override("pressed", st)
		b.add_theme_stylebox_override("focus", st)
		b.add_theme_color_override("font_color", Estilo_Manager.color_para_fondo(col))
		var col_local := col
		b.pressed.connect(func():
			Estilo_Manager.reproducir_sfx("click")
			if es_principal:
				_fund_color_a = col_local
			else:
				_fund_color_b = col_local
			_Actualizar_Preview_Fundacion()
			_Refrescar(false))
		grid.add_child(b)
	return grid


func _Actualizar_Preview_Fundacion() -> void:
	if not is_instance_valid(_fund_preview_box):
		return
	for c in _fund_preview_box.get_children():
		c.queue_free()

	var nombre: String = "Mi Club FC"
	if is_instance_valid(_fund_nombre) and not _fund_nombre.text.strip_edges().is_empty():
		nombre = _fund_nombre.text.strip_edges()
	var cols := ["#" + _fund_color_a.to_html(false), "#" + _fund_color_b.to_html(false)]

	var escudo := Cresta_Manager.new()
	escudo.custom_minimum_size = Vector2(78, 90)
	escudo.configurar(nombre, cols, _fund_patron, 0.0)
	_fund_preview_box.add_child(escudo)

	var muestra := {
		"id": "fund_muestra",
		"nombre": "Mateo Vargas",
		"edad": 22,
		"roles": ["DEL"],
		"dorsal": 10,
		"goles": 2,
		"energia": 100.0,
	}
	_fund_preview_box.add_child(Estilo_Manager.crear_retrato_jugador(
		muestra, cols, _fund_patron, 84, false, "completo", true))
	_fund_preview_box.add_child(Estilo_Manager.crear_retrato_manager(
		84, cols, "feliz", false, "medio_cuerpo"))


func _Sugerir_Identidad_Club() -> void:
	Estilo_Manager.reproducir_sfx("click")
	var nombres: Array = Datos_Manager.NOMBRES_CLUB_SUGERIDOS
	var ciudades: Array = Datos_Manager.CIUDADES_SUGERIDAS
	if not nombres.is_empty() and is_instance_valid(_fund_nombre):
		_fund_nombre.text = str(nombres[_rng.randi() % nombres.size()])
	if not ciudades.is_empty() and is_instance_valid(_fund_ciudad):
		_fund_ciudad.text = str(ciudades[_rng.randi() % ciudades.size()])
	_fund_patron = _rng.randi() % Datos_Manager.PATRONES_ESCUDO.size()
	var idx_a: int = _rng.randi() % (COLORES_CLUB.size() - 1)
	_fund_color_a = Color(str(COLORES_CLUB[idx_a][1]))
	_fund_color_b = Color("#f8fafc") if idx_a != 9 else Color("#1e293b")
	_Actualizar_Preview_Fundacion()
	_Refrescar(false)


func _Intentar_Fundar_Club() -> void:
	var nombre: String = _fund_nombre.text.strip_edges() if is_instance_valid(_fund_nombre) else ""
	var ciudad: String = _fund_ciudad.text.strip_edges() if is_instance_valid(_fund_ciudad) else "Valoria"
	if ciudad.is_empty():
		ciudad = "Valoria"
	var res: Dictionary = Sistema_Manager.Fundar_Club(
		nombre, ["#" + _fund_color_a.to_html(false), "#" + _fund_color_b.to_html(false)],
		_fund_patron, ciudad)
	if res.get("ok", false):
		Estilo_Manager.reproducir_sfx("exito")
		_tab_actual = "club"
		_liga_division = 4
		_feedback_club = "¡Club fundado! Tu vestuario ya espera tus primeras órdenes."
		_feedback_club_ok = true
		_Refrescar(true)
	else:
		Estilo_Manager.reproducir_sfx("error")
		_Mostrar_Info("No se pudo fundar", str(res.get("motivo", "Revisa el nombre o los colores elegidos.")))


# ── PESTAÑA 1: CLUB (HORIZONTAL) ─────────────────────────────────────────────

func _Pantalla_Club(club: Dictionary) -> void:
	if not _feedback_club.is_empty():
		_contenido.add_child(Estilos_UI.pill_estado(_feedback_club,
			Estilos_UI.EXITO_SUAVE if _feedback_club_ok else Estilos_UI.PELIGRO_SUAVE,
			Estilos_UI.EXITO_OSCURO if _feedback_club_ok else Estilos_UI.PELIGRO))
		_feedback_club = ""

	var div: int = int(club.get("division", 4))
	var colores: Array = club.get("colores", Datos_Manager.COLORES_POR_DEFECTO)
	var patron: int = int(club.get("escudo_patron", 1))
	var plantilla: Array = club.get("plantilla", [])
	var fuerza: Dictionary = Simulador_Manager.Calcular_Fuerza_Club(club, true)
	var pos_tabla: int = _Posicion_Usuario(div, str(club.get("id", "")))

	var cols_lay := HBoxContainer.new()
	cols_lay.add_theme_constant_override("separation", 14)
	_contenido.add_child(cols_lay)

	var col_izq := _Crear_Columna(cols_lay, 1.25)
	var col_der := _Crear_Columna(cols_lay, 1.0)

	# 1. Portada del club + voz del Mánager.
	var hero := _Tarjeta(Color.WHITE, col_izq)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	hero.add_child(top)

	var escudo := Cresta_Manager.new()
	escudo.custom_minimum_size = Vector2(72, 82)
	escudo.configurar(str(club.get("nombre", "Tu Club")), colores, patron, float(fuerza.get("media", 50.0)))
	top.add_child(escudo)

	var meta := VBoxContainer.new()
	meta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta.add_theme_constant_override("separation", 4)
	top.add_child(meta)
	meta.add_child(Estilos_UI.titulo(str(club.get("nombre", "Tu Club")), 20, Estilos_UI.TINTA))
	meta.add_child(Estilos_UI.texto("%s · %s" % [
		str(club.get("ciudad", "Ciudad")), Datos_Manager.Nombre_Division(div)],
		13, Estilo_Manager.COLOR_MANAGER_OSCURO, 700))

	var badges := HBoxContainer.new()
	badges.add_theme_constant_override("separation", 6)
	meta.add_child(badges)
	badges.add_child(Estilos_UI.pill_estado("Posición #%d" % pos_tabla,
		Estilo_Manager.COLOR_MANAGER_SUAVE, Estilo_Manager.COLOR_MANAGER_OSCURO))
	badges.add_child(Estilos_UI.pill_estado("V-E-D: %d-%d-%d" % [
		int(club.get("victorias", 0)), int(club.get("empates", 0)),
		int(club.get("derrotas", 0))], Estilos_UI.AZUL_SUAVE, Estilos_UI.AZUL))

	# Voz humana del mánager.
	var voz_box := PanelContainer.new()
	voz_box.add_theme_stylebox_override("panel", Estilos_UI.caja(
		Color("#f0fdfa"), 14, Color("#99f6e4"), 1, 0))
	hero.add_child(voz_box)
	var vm := MarginContainer.new()
	vm.add_theme_constant_override("margin_left", 10)
	vm.add_theme_constant_override("margin_right", 10)
	vm.add_theme_constant_override("margin_top", 8)
	vm.add_theme_constant_override("margin_bottom", 8)
	voz_box.add_child(vm)
	var vh := HBoxContainer.new()
	vh.add_theme_constant_override("separation", 10)
	vm.add_child(vh)

	var conf: int = int(round(float(club.get("confianza_directiva", 70.0))))
	var racha_arr: Array = club.get("racha", []) if club.get("racha", []) is Array else []
	var racha_sig: int = _Signo_Racha_Consecutiva(racha_arr)
	var exp_coach: String = "feliz" if racha_sig > 0 else ("preocupado" if conf < 40 else "concentrado")
	vh.add_child(Estilo_Manager.crear_retrato_manager(54, colores, exp_coach, true, "retrato"))

	var vt := VBoxContainer.new()
	vt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vt.add_theme_constant_override("separation", 2)
	vh.add_child(vt)
	vt.add_child(Estilos_UI.texto("Diario del Mánager", 11, Estilo_Manager.COLOR_MANAGER_OSCURO, 700))
	vt.add_child(Estilos_UI.parrafo(_Frase_Manager_Club(club, racha_sig, conf), 12, Estilos_UI.TINTA))

	var grid := _Chip_Grid(hero, 4)
	grid.add_child(_Chip_Estadistica("Media XI", "%.1f" % float(fuerza.get("media", 50.0)), Estilos_UI.AZUL))
	grid.add_child(_Chip_Estadistica("Química", "%d%%" % int(fuerza.get("quimica", 100)), Estilo_Manager.COLOR_MANAGER))
	grid.add_child(_Chip_Estadistica("Plantilla", "%d / %d" % [plantilla.size(), Datos_Manager.PLANTILLA_MAXIMA], Estilos_UI.TINTA))
	grid.add_child(_Chip_Estadistica("Caja", _Euros(int(club.get("presupuesto", 0))), Estilo_Manager.COLOR_ORO))

	# 2. Próximo partido / amistoso en columna izquierda.
	_Construir_Tarjeta_Partido_Club(club, fuerza, col_izq)

	# 3. Instalaciones en columna derecha.
	_Construir_Tarjeta_Instalaciones(club, col_der)

	# 4. Economía y Directiva en columna derecha.
	var econ := _Tarjeta(Color.WHITE, col_der)
	_Titulo_Seccion(econ, "Economía y directiva")
	var inst: Dictionary = club.get("instalaciones", {})
	var n_est: int = int(inst.get("estadio", 1))
	var taquilla_est: int = Simulador_Manager.Calcular_Ingresos_Partido(
		div, 1, 0, true, int(club.get("aficion", 1500)), n_est)
	var salario_tot: int = Simulador_Manager.Calcular_Nomina(plantilla)
	var premio_vic: int = int(Datos_Manager.INGRESOS_VICTORIA.get(div, 800))
	_Fila_Dato(econ, "Taquilla + premio (victoria local)", _Euros(taquilla_est), Estilos_UI.EXITO)
	_Fila_Dato(econ, "Premio base por victoria", _Euros(premio_vic), Estilos_UI.AZUL)
	_Fila_Dato(econ, "Masa salarial por jornada", _Euros(salario_tot), Estilos_UI.PELIGRO)
	_Barra(econ, "Confianza de la directiva", float(conf),
		Estilos_UI.EXITO if conf >= 60 else (Estilo_Manager.COLOR_ORO if conf >= 35 else Estilos_UI.PELIGRO), "%")
	_Fila_Dato(econ, "Objetivo de liga", _Texto_Objetivo_Division(div), Estilo_Manager.COLOR_MANAGER_OSCURO)

	# 5. Últimos resultados, palmarés y dimisión en columna derecha.
	var hist := _Tarjeta(Color.WHITE, col_der)
	_Titulo_Seccion(hist, "Historial y palmarés")
	var historial: Array = Sistema_Manager.Obtener_Historial()
	var ascensos: int = 0
	var titulos_1a: int = 0
	for item in historial:
		if item is Dictionary:
			if str(item.get("movimiento", "")) == "asciende":
				ascensos += 1
			if int(item.get("division", 4)) == 1 and bool(item.get("campeon", false)):
				titulos_1a += 1

	var hg := _Chip_Grid(hist, 2)
	hg.add_child(_Chip_Estadistica("Ascensos", str(ascensos), Estilos_UI.EXITO))
	hg.add_child(_Chip_Estadistica("Títulos 1ª Div.", str(titulos_1a), Estilo_Manager.COLOR_ORO))
	var res_rec: Array = Sistema_Manager.Obtener_Ultimos_Resultados()
	if not res_rec.is_empty():
		for i in range(mini(4, res_rec.size())):
			var r: Dictionary = res_rec[i]
			var estado_r: String = str(r.get("resultado", "Empate"))
			var v_e_d: String = "V" if estado_r == "Victoria" else ("D" if estado_r == "Derrota" else "E")
			var col_r: Color = Estilos_UI.EXITO if v_e_d == "V" else (
				Estilos_UI.PELIGRO if v_e_d == "D" else Estilo_Manager.COLOR_ORO)
			var tipo_txt: String = "Amist." if bool(r.get("amistoso", false)) else ("T%d·J%d" % [
				int(r.get("temporada", 1)), int(r.get("jornada", 1))])
			_Fila_Dato(hist, "%s [%s] vs %s" % [
				tipo_txt, v_e_d, str(r.get("rival", "Rival"))],
				str(r.get("marcador", "0-0")), col_r)

	var btn_dimitir := Estilo_Manager.boton("Dimitir y dejar el club", "peligro", "", Estilos_UI.PELIGRO, 42)
	btn_dimitir.pressed.connect(_Confirmar_Renuncia)
	hist.add_child(btn_dimitir)


func _Construir_Tarjeta_Partido_Club(club: Dictionary, fuerza_usu: Dictionary, destino: Control) -> void:
	var prox: Dictionary = Sistema_Manager.Obtener_Proximo_Rival_Estimado()
	var card := _Tarjeta(Color("#f0fdf4") if bool(prox.get("pendiente", false)) else Color.WHITE, destino)
	var rival_id: String = str(prox.get("rival_id", ""))
	var rival: Dictionary = Sistema_Manager.Obtener_Club(rival_id)
	var pendiente: bool = bool(prox.get("pendiente", false))
	var es_local: bool = bool(prox.get("es_local", true))

	_Titulo_Seccion(card, "Día de partido" if pendiente else "Próximo compromiso",
		("Jornada %d/4 · Oficial" % (mini(4, Sistema_Manager.Obtener_Jornada() + 1))) if pendiente else Sistema_Manager.Obtener_Proximo_Partido_Texto())

	if not rival.is_empty():
		var duelo := HBoxContainer.new()
		duelo.add_theme_constant_override("separation", 10)
		card.add_child(duelo)

		var u_box := VBoxContainer.new()
		u_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		u_box.add_theme_constant_override("separation", 4)
		duelo.add_child(u_box)
		var c_usu := Cresta_Manager.new()
		c_usu.custom_minimum_size = Vector2(54, 62)
		c_usu.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		c_usu.configurar(str(club.get("nombre", "")), club.get("colores", Datos_Manager.COLORES_POR_DEFECTO),
			int(club.get("escudo_patron", 1)), 0.0)
		u_box.add_child(c_usu)
		var u_lbl := Estilos_UI.texto(str(club.get("nombre", "Tu club")), 12, Estilos_UI.TINTA, 700)
		u_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		u_lbl.clip_text = true
		u_box.add_child(u_lbl)
		var u_tag := Estilos_UI.texto("LOCAL" if es_local else "VISITANTE", 10, Estilo_Manager.COLOR_MANAGER_OSCURO, 700)
		u_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		u_box.add_child(u_tag)

		var vs_box := VBoxContainer.new()
		vs_box.alignment = BoxContainer.ALIGNMENT_CENTER
		duelo.add_child(vs_box)
		var vs_lbl := Estilos_UI.titulo("VS", 18, Estilo_Manager.COLOR_ORO)
		vs_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vs_box.add_child(vs_lbl)

		var r_box := VBoxContainer.new()
		r_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r_box.add_theme_constant_override("separation", 4)
		duelo.add_child(r_box)
		var c_riv := Cresta_Manager.new()
		c_riv.custom_minimum_size = Vector2(54, 62)
		c_riv.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		c_riv.configurar(str(rival.get("nombre", "Rival")), rival.get("colores", Datos_Manager.COLORES_POR_DEFECTO),
			int(rival.get("escudo_patron", 0)), 0.0)
		r_box.add_child(c_riv)
		var r_lbl := Estilos_UI.texto(str(rival.get("nombre", "Rival")), 12, Estilos_UI.TINTA, 700)
		r_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		r_lbl.clip_text = true
		r_box.add_child(r_lbl)
		var r_tag := Estilos_UI.texto("VISITANTE" if es_local else "LOCAL", 10, Estilos_UI.TINTA_SUAVE, 700)
		r_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		r_box.add_child(r_tag)

		var fuerza_riv: Dictionary = Simulador_Manager.Calcular_Fuerza_Club(rival, not es_local)
		var col_usu_bar: Color = Color(str(club.get("colores", Datos_Manager.COLORES_POR_DEFECTO)[0]))
		var col_riv_bar: Color = Color(str(rival.get("colores", Datos_Manager.COLORES_POR_DEFECTO)[0]))
		if Vector3(col_usu_bar.r - col_riv_bar.r, col_usu_bar.g - col_riv_bar.g, col_usu_bar.b - col_riv_bar.b).length() < 0.25:
			col_riv_bar = Estilos_UI.AZUL if col_usu_bar != Estilos_UI.AZUL else Estilos_UI.PELIGRO
		var m_u: float = float(fuerza_usu.get("media", 50.0))
		var m_r: float = float(fuerza_riv.get("media", 50.0))
		var a_u: float = float(fuerza_usu.get("ataque", 50.0))
		var a_r: float = float(fuerza_riv.get("ataque", 50.0))
		var d_u: float = float(fuerza_usu.get("defensa", 50.0))
		var d_r: float = float(fuerza_riv.get("defensa", 50.0))
		card.add_child(Estilo_Manager.barra_comparativa("Media XI", m_u, m_r,
			"%.0f" % m_u, "%.0f" % m_r, col_usu_bar, col_riv_bar))
		card.add_child(Estilo_Manager.barra_comparativa("Ataque", a_u, a_r,
			"%.0f" % a_u, "%.0f" % a_r, col_usu_bar, col_riv_bar))
		card.add_child(Estilo_Manager.barra_comparativa("Defensa", d_u, d_r,
			"%.0f" % d_u, "%.0f" % d_r, col_usu_bar, col_riv_bar))

	if pendiente:
		var btn_jugar := Estilo_Manager.boton("Jugar partido oficial", "exito", "play", Estilos_UI.EXITO, 50)
		btn_jugar.pressed.connect(func(): _Jugar_Partido(false))
		card.add_child(btn_jugar)
	else:
		var puede_am: bool = Sistema_Manager.Puede_Jugar_Amistoso()
		var btn_am := Estilo_Manager.boton(
			"Jugar partido amistoso" if puede_am else "Amistoso diario ya disputado",
			"primario", "play", Estilo_Manager.COLOR_MANAGER, 48)
		btn_am.disabled = not puede_am
		btn_am.pressed.connect(func(): _Jugar_Partido(true))
		card.add_child(btn_am)

	var atajos := HBoxContainer.new()
	atajos.add_theme_constant_override("separation", 8)
	card.add_child(atajos)
	var b_tac := Estilo_Manager.boton("Ajustar pizarra", "secundario", "", Estilo_Manager.COLOR_MANAGER, 42)
	b_tac.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_tac.pressed.connect(func():
		Estilo_Manager.reproducir_sfx("click")
		_tab_actual = "tactica"
		_Refrescar(true))
	atajos.add_child(b_tac)

	var b_mer := Estilo_Manager.boton("Mercado y cantera", "secundario", "", Estilos_UI.AZUL, 42)
	b_mer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_mer.pressed.connect(func():
		Estilo_Manager.reproducir_sfx("click")
		_tab_actual = "mercado"
		_Refrescar(true))
	atajos.add_child(b_mer)


func _Construir_Tarjeta_Instalaciones(club: Dictionary, destino: Control) -> void:
	var card := _Tarjeta(Color.WHITE, destino)
	_Titulo_Seccion(card, "Instalaciones del club",
		"Mejora estadio, ciudad deportiva y cantera (máx. Nv %d)" % Datos_Manager.INSTALACIONES_NIVEL_MAX)
	var inst: Dictionary = club.get("instalaciones", {})
	var defs := [
		["estadio", Estilos_UI.EXITO],
		["entrenamiento", Estilos_UI.AZUL],
		["cantera", Estilo_Manager.COLOR_ORO],
	]
	var pres: int = int(club.get("presupuesto", 0))
	for d in defs:
		var tipo: String = str(d[0])
		var nombre_d: String = str(Datos_Manager.INSTALACIONES_NOMBRES.get(tipo, tipo.capitalize()))
		var desc_d: String = str(Datos_Manager.INSTALACIONES_DESCRIPCIONES.get(tipo, ""))
		var nivel: int = clampi(int(inst.get(tipo, 1)), 1, Datos_Manager.INSTALACIONES_NIVEL_MAX)
		var max_nv: int = Datos_Manager.INSTALACIONES_NIVEL_MAX
		var color_d: Color = d[1]

		var box := PanelContainer.new()
		box.add_theme_stylebox_override("panel", Estilos_UI.caja(Color("#f8fafc"), 12, Estilos_UI.BORDE, 1, 0))
		card.add_child(box)
		var m := MarginContainer.new()
		m.add_theme_constant_override("margin_left", 10)
		m.add_theme_constant_override("margin_right", 10)
		m.add_theme_constant_override("margin_top", 8)
		m.add_theme_constant_override("margin_bottom", 8)
		box.add_child(m)

		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 5)
		m.add_child(v)

		var fh := HBoxContainer.new()
		fh.add_theme_constant_override("separation", 8)
		v.add_child(fh)
		var lbl_n := Estilos_UI.texto(nombre_d, 13, Estilos_UI.TINTA, 700)
		lbl_n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fh.add_child(lbl_n)
		fh.add_child(Estilos_UI.pill_estado("Nv %d/%d" % [nivel, max_nv],
			color_d.lerp(Color.WHITE, 0.85), color_d))

		v.add_child(Estilos_UI.parrafo(desc_d, 11, Estilos_UI.TINTA_SUAVE))
		_Barra(v, "Nivel actual", float(nivel), color_d, " / %d" % max_nv, float(max_nv))

		if nivel < max_nv:
			var coste: int = int(Datos_Manager.INSTALACIONES_COSTES.get(nivel, 50000))
			var btn := Estilo_Manager.boton("Ampliar a Nv %d (%s)" % [nivel + 1, _Euros(coste)],
				"oro", "", color_d, 40)
			btn.disabled = pres < coste
			var tipo_local: String = tipo
			var nom_local: String = nombre_d
			btn.pressed.connect(func():
				var res: Dictionary = Sistema_Manager.Mejorar_Instalacion(tipo_local)
				_feedback_club_ok = res.get("ok", false)
				_feedback_club = "%s mejorada a nivel %d." % [
					nom_local, int(res.get("nivel", nivel + 1))] if _feedback_club_ok else str(res.get("motivo", "No disponible."))
				Estilo_Manager.reproducir_sfx("exito" if _feedback_club_ok else "error")
				_Refrescar(false))
			v.add_child(btn)
		else:
			v.add_child(Estilos_UI.pill_estado("Instalación al máximo nivel",
				Estilos_UI.EXITO_SUAVE, Estilos_UI.EXITO_OSCURO))


# ── PESTAÑA 2: PLANTILLA (HORIZONTAL 3 COLUMNAS) ─────────────────────────────

func _Pantalla_Plantilla(club: Dictionary) -> void:
	var plantilla: Array = club.get("plantilla", [])
	var alineacion: Array = club.get("alineacion", [])
	var colores: Array = club.get("colores", Datos_Manager.COLORES_POR_DEFECTO)
	var patron: int = int(club.get("escudo_patron", 1))
	var capitan_id: String = str(club.get("capitan_id", ""))
	var capitan: Dictionary = Sistema_Manager.Obtener_Jugador_De_Club(
		str(club.get("id", "")), capitan_id)

	var media_total: float = 0.0
	var energia_total: float = 0.0
	for j in plantilla:
		media_total += float(j.get("calidad", 50.0))
		energia_total += float(j.get("energia", 100.0))
	var n_jug: int = maxi(1, plantilla.size())

	var sup := HBoxContainer.new()
	sup.add_theme_constant_override("separation", 14)
	_contenido.add_child(sup)
	var col_s1 := _Crear_Columna(sup, 1.0)
	var col_s2 := _Crear_Columna(sup, 1.25)

	var res_card := _Tarjeta(Color.WHITE, col_s1)
	_Titulo_Seccion(res_card, "Tu vestuario (%d/%d)" % [plantilla.size(), Datos_Manager.PLANTILLA_MAXIMA])
	var grid := _Chip_Grid(res_card, 2)
	grid.add_child(_Chip_Estadistica("Media plantilla", "%.1f" % (media_total / n_jug), Estilos_UI.AZUL))
	grid.add_child(_Chip_Estadistica("Energía media", "%d%%" % int(round(energia_total / n_jug)), Estilos_UI.EXITO))
	grid.add_child(_Chip_Estadistica("Capitanía (C)",
		str(capitan.get("nombre", "Sin asignar")) if not capitan.is_empty() else "Sin asignar",
		Estilo_Manager.COLOR_ORO))
	grid.add_child(_Chip_Estadistica("Masa salarial", "%s/jorn." % _Euros(Simulador_Manager.Calcular_Nomina(plantilla)),
		Estilo_Manager.COLOR_MANAGER))

	# Entrenamiento colectivo + filtros en la derecha.
	var ent_card := _Tarjeta(Color.WHITE, col_s2)
	var nv_ent: int = int(club.get("instalaciones", {}).get("entrenamiento", 1))
	_Titulo_Seccion(ent_card, "Sesión colectiva por línea",
		"1 sesión grupal al día (Ciudad deportiva Nv %d)" % nv_ent)
	if not _feedback_plantilla.is_empty():
		ent_card.add_child(Estilos_UI.pill_estado(_feedback_plantilla,
			Estilos_UI.EXITO_SUAVE if _feedback_plantilla_ok else Estilos_UI.PELIGRO_SUAVE,
			Estilos_UI.EXITO_OSCURO if _feedback_plantilla_ok else Estilos_UI.PELIGRO))
		_feedback_plantilla = ""

	var ya_grupal: bool = int(club.get("entreno_grupal_dia", -1)) == int(Variables_Dinamicas.Minute_Day)
	if ya_grupal:
		ent_card.add_child(Estilos_UI.pill_estado("Sesión colectiva completada por hoy",
			Color("#f1f5f9"), Estilos_UI.TINTA_SUAVE))
	else:
		var h_ent := HBoxContainer.new()
		h_ent.add_theme_constant_override("separation", 8)
		ent_card.add_child(h_ent)
		var lineas := [
			["defensa", "Defensa", Color("#2563eb")],
			["medio", "Centro", Estilo_Manager.COLOR_MANAGER],
			["ataque", "Ataque", Estilos_UI.PELIGRO],
			["fisico", "Físico", Estilo_Manager.COLOR_ORO],
		]
		for lin in lineas:
			var l_id: String = str(lin[0])
			var btn := Estilo_Manager.boton(str(lin[1]), "primario", "", lin[2], 42)
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.pressed.connect(func():
				var res: Dictionary = Sistema_Manager.Entrenar_Linea_Equipo(l_id)
				_feedback_plantilla_ok = res.get("ok", false)
				_feedback_plantilla = "Sesión de %s: %d jugadores (%d subidas de nivel)." % [
					l_id, int(res.get("entrenados", 0)), int(res.get("mejoras", 0))] if _feedback_plantilla_ok else str(res.get("motivo", ""))
				Estilo_Manager.reproducir_sfx("exito" if _feedback_plantilla_ok else "error")
				_Refrescar(false))
			h_ent.add_child(btn)

	var fil_card := _Tarjeta(Color.WHITE, col_s2)
	var fh_fil := HBoxContainer.new()
	fh_fil.add_theme_constant_override("separation", 12)
	fil_card.add_child(fh_fil)

	var fv1 := VBoxContainer.new()
	fv1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fv1.add_theme_constant_override("separation", 4)
	fh_fil.add_child(fv1)
	fv1.add_child(Estilos_UI.texto("Demarcación", 11, Estilos_UI.TINTA_SUAVE, 700))
	fv1.add_child(Estilo_Manager.selector_chips([
		["", "Todos"], ["POR", "POR"], ["DEF", "DEF"], ["MED", "MED"], ["ATA", "ATA"]
	], _plantilla_filtro_rol, Estilo_Manager.COLOR_MANAGER, func(r: String):
		_plantilla_filtro_rol = r
		call_deferred("_Refrescar", false), false, 11))

	var fv2 := VBoxContainer.new()
	fv2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fv2.add_theme_constant_override("separation", 4)
	fh_fil.add_child(fv2)
	fv2.add_child(Estilos_UI.texto("Ordenar por", 11, Estilos_UI.TINTA_SUAVE, 700))
	fv2.add_child(Estilo_Manager.selector_chips([
		["calidad", "Calidad"], ["energia", "Energía"], ["edad", "Edad"], ["goles", "Goles"]
	], _plantilla_orden, Estilos_UI.AZUL, func(ord: String):
		_plantilla_orden = ord
		call_deferred("_Refrescar", false), false, 11))

	var filtrada: Array = []
	for j in plantilla:
		var linea_j: String = Datos_Manager.Linea_De_Rol(Simulador_Manager._Rol_Principal(j))
		if _plantilla_filtro_rol == "" or linea_j == _plantilla_filtro_rol:
			filtrada.append(j)
	var criterio: String = _plantilla_orden
	filtrada.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if criterio == "energia":
			return float(a.get("energia", 0.0)) > float(b.get("energia", 0.0))
		if criterio == "edad":
			return int(a.get("edad", 25)) < int(b.get("edad", 25))
		if criterio == "goles":
			return int(a.get("goles", 0)) > int(b.get("goles", 0))
		return float(a.get("calidad", 0.0)) > float(b.get("calidad", 0.0)))

	# Cuadrícula humana de 3 columnas en horizontal.
	var grid_p := GridContainer.new()
	grid_p.columns = 3
	grid_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_p.add_theme_constant_override("h_separation", 12)
	grid_p.add_theme_constant_override("v_separation", 12)
	_contenido.add_child(grid_p)

	for j in filtrada:
		grid_p.add_child(_Crear_Card_Jugador_Plantilla(
			j, alineacion, capitan_id, colores, patron))


func _Crear_Card_Jugador_Plantilla(jugador: Dictionary, alineacion: Array,
		capitan_id: String, colores: Array, patron: int) -> PanelContainer:
	var jid: String = str(jugador.get("id", ""))
	var es_titular: bool = alineacion.has(jid)
	var es_capitan: bool = jid == capitan_id
	var rol_p: String = Simulador_Manager._Rol_Principal(jugador)
	var col_rol: Color = Datos_Manager.Color_De_Rol(rol_p)

	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	if es_titular:
		card.add_theme_stylebox_override("panel", Estilos_UI.caja(
			Color.WHITE, 16, Estilo_Manager.COLOR_MANAGER.lerp(Color.WHITE, 0.35), 2, 2))
	else:
		card.add_theme_stylebox_override("panel", Estilos_UI.caja_tarjeta(16, 2))

	var m := MarginContainer.new()
	m.mouse_filter = Control.MOUSE_FILTER_PASS
	m.add_theme_constant_override("margin_left", 10)
	m.add_theme_constant_override("margin_right", 10)
	m.add_theme_constant_override("margin_top", 10)
	m.add_theme_constant_override("margin_bottom", 10)
	card.add_child(m)

	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_PASS
	v.add_theme_constant_override("separation", 6)
	m.add_child(v)

	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_PASS
	top.add_theme_constant_override("separation", 10)
	v.add_child(top)
	top.add_child(Estilo_Manager.crear_retrato_jugador(jugador, colores, patron, 54, false, "retrato", true))

	var info := VBoxContainer.new()
	info.mouse_filter = Control.MOUSE_FILTER_PASS
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	top.add_child(info)

	var lbl_nom := Estilos_UI.texto(str(jugador.get("nombre", "")), 14, Estilos_UI.TINTA, 700)
	lbl_nom.clip_text = true
	info.add_child(lbl_nom)

	info.add_child(Estilos_UI.texto("%s · %da · Cal %.0f" % [
		rol_p, int(jugador.get("edad", 22)), float(jugador.get("calidad", 50.0))],
		12, col_rol, 700))

	var pills := HBoxContainer.new()
	pills.mouse_filter = Control.MOUSE_FILTER_PASS
	pills.add_theme_constant_override("separation", 5)
	info.add_child(pills)
	pills.add_child(Estilos_UI.pill_estado("XI" if es_titular else "BAN",
		Estilo_Manager.COLOR_MANAGER_SUAVE if es_titular else Color("#f1f5f9"),
		Estilo_Manager.COLOR_MANAGER_OSCURO if es_titular else Estilos_UI.TINTA_SUAVE))
	if es_capitan:
		pills.add_child(Estilos_UI.pill_estado("(C)",
			Estilo_Manager.COLOR_ORO_SUAVE, Estilo_Manager.COLOR_ORO))

	var energia: float = float(jugador.get("energia", 100.0))
	var col_e: Color = Estilos_UI.EXITO if energia >= 60.0 else (Estilo_Manager.COLOR_ORO if energia >= 35.0 else Estilos_UI.PELIGRO)
	_Barra(v, "Energía", energia, col_e, "%")

	v.add_child(Estilos_UI.texto("%s · %dG · %dA" % [
		_Estrellas(int(jugador.get("estrellas", 1))),
		int(jugador.get("goles", 0)), int(jugador.get("asistencias", 0))],
		11, Estilos_UI.TINTA_SUAVE, 600))

	var btn := Estilo_Manager.boton("Ver ficha", "primario" if es_titular else "secundario",
		"", Estilo_Manager.COLOR_MANAGER, 40)
	btn.mouse_filter = Control.MOUSE_FILTER_PASS
	btn.pressed.connect(func():
		Estilo_Manager.reproducir_sfx("click")
		_Abrir_Ficha_Jugador(jid))
	v.add_child(btn)
	return card


# ── PESTAÑA 3: TÁCTICA (HORIZONTAL PIZARRA + LISTAS) ─────────────────────────

func _Pantalla_Tactica(club: Dictionary) -> void:
	var tactica: Dictionary = club.get("tactica", Datos_Manager.TACTICA_BASE)
	var formacion: String = str(tactica.get("formacion", "4-4-2"))
	var mentalidad: String = str(tactica.get("mentalidad", "equilibrada"))
	var presion: String = str(tactica.get("presion", "media"))
	var alineacion: Array = club.get("alineacion", [])
	var plantilla: Array = club.get("plantilla", [])
	var colores: Array = club.get("colores", Datos_Manager.COLORES_POR_DEFECTO)
	var patron: int = int(club.get("escudo_patron", 1))
	var capitan_id: String = str(club.get("capitan_id", ""))
	var fuerza: Dictionary = Simulador_Manager.Calcular_Fuerza_Club(club, true)
	var slots: Array = Simulador_Manager.Evaluar_Alineacion_Slots(club)

	# 1. Banda superior compacta de fuerza y química.
	var res_card := _Tarjeta()
	var rh := HBoxContainer.new()
	rh.add_theme_constant_override("separation", 12)
	res_card.add_child(rh)
	rh.add_child(_Chip_Estadistica("POR / DEF", "%.0f / %.0f" % [
		float(fuerza.get("porteria", 50.0)), float(fuerza.get("defensa", 50.0))], Estilos_UI.AZUL))
	rh.add_child(_Chip_Estadistica("MED / ATA", "%.0f / %.0f" % [
		float(fuerza.get("medio", 50.0)), float(fuerza.get("ataque", 50.0))], Estilo_Manager.COLOR_MANAGER))
	var qb := VBoxContainer.new()
	qb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	qb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rh.add_child(qb)
	_Barra(qb, "Química de posiciones", float(fuerza.get("quimica", 100)),
		Estilos_UI.EXITO if int(fuerza.get("quimica", 100)) >= 85 else Estilo_Manager.COLOR_ORO, "%")

	if not _feedback_tactica.is_empty():
		res_card.add_child(Estilos_UI.pill_estado(_feedback_tactica,
			Estilos_UI.EXITO_SUAVE if _feedback_tactica_ok else Estilos_UI.PELIGRO_SUAVE,
			Estilos_UI.EXITO_OSCURO if _feedback_tactica_ok else Estilos_UI.PELIGRO))
		_feedback_tactica = ""

	# 2. Split principal horizontal: Pizarra izquierda | Config + XI + Banquillo derecha.
	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 14)
	_contenido.add_child(split)

	var col_izq := _Crear_Columna(split, 0.0, 480.0)
	var col_der := _Crear_Columna(split, 1.0)

	var pizarra_card := _Tarjeta(Color.WHITE, col_izq)
	var h_pz := HBoxContainer.new()
	h_pz.add_theme_constant_override("separation", 8)
	pizarra_card.add_child(h_pz)
	var aviso_txt: String = "Toca un jugador para moverlo"
	var id_sel_campo: String = ""
	if _tactica_slot_sel >= 0 and _tactica_slot_sel < alineacion.size():
		id_sel_campo = str(alineacion[_tactica_slot_sel])
		var j_s: Dictionary = Sistema_Manager.Obtener_Jugador_De_Club(
			str(club.get("id", "")), id_sel_campo)
		aviso_txt = "Elegido: %s" % str(j_s.get("nombre", ""))
	elif not _tactica_ban_sel.is_empty():
		var j_b: Dictionary = Sistema_Manager.Obtener_Jugador_De_Club(
			str(club.get("id", "")), _tactica_ban_sel)
		aviso_txt = "Suplente: %s" % str(j_b.get("nombre", ""))

	var pill_ayuda := Estilos_UI.pill_estado(aviso_txt,
		Estilo_Manager.COLOR_MANAGER_SUAVE, Estilo_Manager.COLOR_MANAGER_OSCURO)
	pill_ayuda.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_pz.add_child(pill_ayuda)

	if not id_sel_campo.is_empty() or not _tactica_ban_sel.is_empty():
		var b_can := Estilo_Manager.boton("Cancelar", "chip", "", Estilos_UI.PELIGRO, 36)
		b_can.pressed.connect(func():
			_tactica_slot_sel = -1
			_tactica_ban_sel = ""
			_Refrescar(false))
		h_pz.add_child(b_can)
	else:
		var b_auto := Estilo_Manager.boton("Mejor XI", "chip", "", Estilo_Manager.COLOR_MANAGER, 36)
		b_auto.pressed.connect(func():
			Sistema_Manager.Alineacion_Automatica()
			_feedback_tactica = "Once optimizado según tu formación."
			_feedback_tactica_ok = true
			Estilo_Manager.reproducir_sfx("exito")
			_Refrescar(false))
		h_pz.add_child(b_auto)

	var campo := Campo_Manager.new()
	campo.custom_minimum_size = Vector2(440, 430)
	campo.configurar(alineacion, plantilla, formacion, colores, id_sel_campo, capitan_id)
	campo.slot_tocado.connect(_Al_Tocar_Slot_Campo)
	pizarra_card.add_child(campo)

	# 3. Configuración táctica + listas en la columna derecha.
	var conf_card := _Tarjeta(Color.WHITE, col_der)
	_Titulo_Seccion(conf_card, "Sistema de juego")

	conf_card.add_child(Estilos_UI.texto("Formación", 12, Estilos_UI.TINTA_SUAVE, 700))
	var opt_form: Array = []
	for f in Datos_Manager.FORMACIONES:
		opt_form.append([str(f), str(f)])
	conf_card.add_child(Estilo_Manager.selector_chips(
		opt_form, formacion, Estilo_Manager.COLOR_MANAGER, func(f_new: String):
			Sistema_Manager.Establecer_Tactica(f_new, mentalidad, presion)
			_tactica_slot_sel = -1
			_Refrescar(false), false, 12))

	var mp_h := HBoxContainer.new()
	mp_h.add_theme_constant_override("separation", 12)
	conf_card.add_child(mp_h)

	var mv_m := VBoxContainer.new()
	mv_m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mv_m.add_theme_constant_override("separation", 4)
	mp_h.add_child(mv_m)
	mv_m.add_child(Estilos_UI.texto("Mentalidad", 12, Estilos_UI.TINTA_SUAVE, 700))
	mv_m.add_child(Estilo_Manager.selector_chips([
		["defensiva", "Defensiva"], ["equilibrada", "Equilibrada"], ["ofensiva", "Ofensiva"]
	], mentalidad, Estilos_UI.AZUL, func(m_new: String):
		Sistema_Manager.Establecer_Tactica(formacion, m_new, presion)
		_Refrescar(false), false, 11))

	var mv_p := VBoxContainer.new()
	mv_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mv_p.add_theme_constant_override("separation", 4)
	mp_h.add_child(mv_p)
	mv_p.add_child(Estilos_UI.texto("Presión", 12, Estilos_UI.TINTA_SUAVE, 700))
	mv_p.add_child(Estilo_Manager.selector_chips([
		["baja", "Baja"], ["media", "Media"], ["alta", "Alta"]
	], presion, Estilo_Manager.COLOR_ORO, func(p_new: String):
		Sistema_Manager.Establecer_Tactica(formacion, mentalidad, p_new)
		_Refrescar(false), false, 11))

	# 4. Once titular en grid de 2 columnas.
	var xi_card := _Tarjeta(Color.WHITE, col_der)
	_Titulo_Seccion(xi_card, "Once titular", "Verde: en su sitio · Ámbar: fuera de puesto")
	var xi_grid := GridContainer.new()
	xi_grid.columns = 2
	xi_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	xi_grid.add_theme_constant_override("h_separation", 8)
	xi_grid.add_theme_constant_override("v_separation", 6)
	xi_card.add_child(xi_grid)
	for slot_info in slots:
		var idx: int = int(slot_info.get("slot", 0))
		var jid: String = str(slot_info.get("jugador_id", ""))
		var j: Dictionary = slot_info.get("jugador", {})
		if j.is_empty():
			continue
		var sel: bool = idx == _tactica_slot_sel
		var af: float = float(slot_info.get("afinidad", 1.0))
		var en_sitio: bool = af >= 0.85
		var rol_req: String = str(slot_info.get("ranura", "MC"))

		var fila := PanelContainer.new()
		fila.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.mouse_filter = Control.MOUSE_FILTER_PASS
		fila.add_theme_stylebox_override("panel", Estilos_UI.caja(
			Color("#ecfdf5") if sel else Color("#f8fafc"), 12,
			Estilo_Manager.COLOR_MANAGER if sel else (Estilos_UI.BORDE if en_sitio else Estilo_Manager.COLOR_ORO), 2 if sel else 1, 0))
		xi_grid.add_child(fila)

		var fm := MarginContainer.new()
		fm.mouse_filter = Control.MOUSE_FILTER_PASS
		fm.add_theme_constant_override("margin_left", 8)
		fm.add_theme_constant_override("margin_right", 8)
		fm.add_theme_constant_override("margin_top", 5)
		fm.add_theme_constant_override("margin_bottom", 5)
		fila.add_child(fm)

		var fh := HBoxContainer.new()
		fh.mouse_filter = Control.MOUSE_FILTER_PASS
		fh.add_theme_constant_override("separation", 6)
		fm.add_child(fh)
		fh.add_child(Estilos_UI.pill_estado(rol_req, Color("#f1f5f9"), Datos_Manager.Color_De_Rol(rol_req)))
		fh.add_child(Estilo_Manager.crear_retrato_jugador(j, colores, patron, 36, false, "retrato", false))

		var ft := VBoxContainer.new()
		ft.mouse_filter = Control.MOUSE_FILTER_PASS
		ft.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ft.add_theme_constant_override("separation", 1)
		fh.add_child(ft)
		var l_nom := Estilos_UI.texto(str(j.get("nombre", "")), 12, Estilos_UI.TINTA, 700)
		l_nom.clip_text = true
		ft.add_child(l_nom)
		ft.add_child(Estilos_UI.texto("Cal %.0f · %d%%" % [
			float(j.get("calidad", 50.0)), int(round(float(j.get("energia", 100.0))))],
			10, Estilos_UI.EXITO if en_sitio else Estilo_Manager.COLOR_ORO, 600))

		var b_sel := Estilo_Manager.boton("✓" if sel else "Mover",
			"primario" if sel else "secundario", "", Estilo_Manager.COLOR_MANAGER, 34)
		b_sel.mouse_filter = Control.MOUSE_FILTER_PASS
		b_sel.add_theme_font_size_override("font_size", 11)
		var idx_local: int = idx
		var jid_local: String = jid
		b_sel.pressed.connect(func(): _Al_Tocar_Slot_Campo(idx_local, jid_local))
		fh.add_child(b_sel)

	# 5. Banquillo en grid de 2 columnas.
	var ban_card := _Tarjeta(Color.WHITE, col_der)
	_Titulo_Seccion(ban_card, "Banquillo disponible", "Toca un suplente y un titular para intercambiarlos")
	var ban_grid := GridContainer.new()
	ban_grid.columns = 2
	ban_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ban_grid.add_theme_constant_override("h_separation", 8)
	ban_grid.add_theme_constant_override("v_separation", 6)
	ban_card.add_child(ban_grid)
	for j in plantilla:
		var jid: String = str(j.get("id", ""))
		if alineacion.has(jid):
			continue
		var sel_b: bool = jid == _tactica_ban_sel
		var rol_p: String = Simulador_Manager._Rol_Principal(j)

		var fila := PanelContainer.new()
		fila.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.mouse_filter = Control.MOUSE_FILTER_PASS
		fila.add_theme_stylebox_override("panel", Estilos_UI.caja(
			Color("#eff6ff") if sel_b else Color("#f8fafc"), 12,
			Estilos_UI.AZUL if sel_b else Estilos_UI.BORDE, 2 if sel_b else 1, 0))
		ban_grid.add_child(fila)

		var fm := MarginContainer.new()
		fm.mouse_filter = Control.MOUSE_FILTER_PASS
		fm.add_theme_constant_override("margin_left", 8)
		fm.add_theme_constant_override("margin_right", 8)
		fm.add_theme_constant_override("margin_top", 5)
		fm.add_theme_constant_override("margin_bottom", 5)
		fila.add_child(fm)

		var fh := HBoxContainer.new()
		fh.mouse_filter = Control.MOUSE_FILTER_PASS
		fh.add_theme_constant_override("separation", 6)
		fm.add_child(fh)
		fh.add_child(Estilo_Manager.crear_retrato_jugador(j, colores, patron, 36, false, "retrato", false))
		var ft := VBoxContainer.new()
		ft.mouse_filter = Control.MOUSE_FILTER_PASS
		ft.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ft.add_theme_constant_override("separation", 1)
		fh.add_child(ft)
		var lb_nom := Estilos_UI.texto(str(j.get("nombre", "")), 12, Estilos_UI.TINTA, 700)
		lb_nom.clip_text = true
		ft.add_child(lb_nom)
		ft.add_child(Estilos_UI.texto("%s · Cal %.0f · %d%%" % [
			rol_p, float(j.get("calidad", 50.0)), int(round(float(j.get("energia", 100.0))))],
			10, Datos_Manager.Color_De_Rol(rol_p), 600))

		var b_ban := Estilo_Manager.boton(
			"Entrar" if _tactica_slot_sel >= 0 else ("✓" if sel_b else "Usar"),
			"exito" if _tactica_slot_sel >= 0 else ("primario" if sel_b else "secundario"),
			"", Estilos_UI.EXITO if _tactica_slot_sel >= 0 else Estilos_UI.AZUL, 34)
		b_ban.mouse_filter = Control.MOUSE_FILTER_PASS
		b_ban.add_theme_font_size_override("font_size", 11)
		var jid_local: String = jid
		b_ban.pressed.connect(func(): _Al_Tocar_Suplente(jid_local))
		fh.add_child(b_ban)


func _Al_Tocar_Slot_Campo(indice: int, jugador_id: String) -> void:
	var club: Dictionary = Sistema_Manager.Club_Usuario()
	var alineacion: Array = club.get("alineacion", [])
	if indice < 0 or indice >= alineacion.size():
		return

	if not _tactica_ban_sel.is_empty():
		var res: Dictionary = Sistema_Manager.Intercambiar_Jugadores(jugador_id, _tactica_ban_sel)
		_feedback_tactica_ok = res.get("ok", false)
		_feedback_tactica = "Cambio táctico aplicado en el once." if _feedback_tactica_ok else str(res.get("motivo", ""))
		_tactica_ban_sel = ""
		_tactica_slot_sel = -1
		Estilo_Manager.reproducir_sfx("exito" if _feedback_tactica_ok else "error")
		call_deferred("_Refrescar", false)
		return

	if _tactica_slot_sel == indice:
		_tactica_slot_sel = -1
		Estilo_Manager.reproducir_sfx("click")
		call_deferred("_Refrescar", false)
		return

	if _tactica_slot_sel >= 0 and _tactica_slot_sel < alineacion.size():
		var id_origen: String = str(alineacion[_tactica_slot_sel])
		var res: Dictionary = Sistema_Manager.Intercambiar_Titulares(id_origen, jugador_id)
		_feedback_tactica_ok = res.get("ok", false)
		_feedback_tactica = "Puestos intercambiados sobre la pizarra." if _feedback_tactica_ok else str(res.get("motivo", ""))
		_tactica_slot_sel = -1
		Estilo_Manager.reproducir_sfx("tap" if _feedback_tactica_ok else "error")
		call_deferred("_Refrescar", false)
		return

	_tactica_slot_sel = indice
	_tactica_ban_sel = ""
	Estilo_Manager.reproducir_sfx("click")
	call_deferred("_Refrescar", false)


func _Al_Tocar_Suplente(suplente_id: String) -> void:
	var club: Dictionary = Sistema_Manager.Club_Usuario()
	var alineacion: Array = club.get("alineacion", [])
	if _tactica_slot_sel >= 0 and _tactica_slot_sel < alineacion.size():
		var id_titular: String = str(alineacion[_tactica_slot_sel])
		var res: Dictionary = Sistema_Manager.Intercambiar_Jugadores(id_titular, suplente_id)
		_feedback_tactica_ok = res.get("ok", false)
		_feedback_tactica = "Suplente introducido en el once." if _feedback_tactica_ok else str(res.get("motivo", ""))
		_tactica_slot_sel = -1
		_tactica_ban_sel = ""
		Estilo_Manager.reproducir_sfx("exito" if _feedback_tactica_ok else "error")
		call_deferred("_Refrescar", false)
		return

	_tactica_ban_sel = "" if _tactica_ban_sel == suplente_id else suplente_id
	_tactica_slot_sel = -1
	Estilo_Manager.reproducir_sfx("click")
	call_deferred("_Refrescar", false)


# ── MODALES Y ACCIONES DE MERCADO / FICHA / PARTIDO ──────────────────────────

func _Abrir_Ficha_Jugador(jugador_id: String) -> void:
	Panel_Manager_Vistas.construir_ficha_jugador(self, jugador_id)


func _Cerrar_Ficha() -> void:
	if is_instance_valid(_modal_ficha):
		_modal_ficha.queue_free()
	_modal_ficha = null


func _Abrir_Modal_Oferta(jugador_id: String) -> void:
	Panel_Manager_Vistas.construir_modal_oferta(self, jugador_id)


func _Cerrar_Modal_Oferta() -> void:
	if is_instance_valid(_modal_oferta):
		_modal_oferta.queue_free()
	_modal_oferta = null


func _Enviar_Oferta(jugador_id: String, importe: int) -> void:
	var res: Dictionary = Sistema_Manager.Oferta_Estandar(jugador_id, importe)
	_Cerrar_Modal_Oferta()
	_Refrescar(false)
	if res.get("ok", false):
		Estilo_Manager.reproducir_sfx("exito")
		var jug: Dictionary = res.get("jugador", {})
		_Mostrar_Info("¡Fichaje cerrado!", "%s acepta la oferta de %s y ya viste tu camiseta." % [
			str(jug.get("nombre", "El jugador")), _Euros(importe)])
	else:
		Estilo_Manager.reproducir_sfx("error")
		_Mostrar_Info("Oferta rechazada", str(res.get("motivo", "El club vendedor pide una cifra mayor.")))


func _Confirmar_Clausula(jugador_id: String, nombre: String, importe: int) -> void:
	_Confirmar_Accion("Pagar cláusula de rescisión",
		"¿Abonar %s para incorporar directamente a %s?" % [_Euros(importe), nombre],
		"Pagar %s" % _Euros(importe), "oro", func():
			var res: Dictionary = Sistema_Manager.Pagar_Clausula(jugador_id)
			_Refrescar(false)
			if res.get("ok", false):
				Estilo_Manager.reproducir_sfx("exito")
				_Mostrar_Info("Cláusula abonada", "%s ya forma parte de tu plantilla." % nombre)
			else:
				Estilo_Manager.reproducir_sfx("error")
				_Mostrar_Info("Operación cancelada", str(res.get("motivo", "No se pudo completar."))))


func _Confirmar_Venta(jugador_id: String, nombre: String) -> void:
	_Confirmar_Accion("Traspasar futbolista",
		"¿Vender a %s e ingresar su valor de mercado en caja?" % nombre,
		"Confirmar venta", "peligro", func():
			var res: Dictionary = Sistema_Manager.Vender_Jugador(jugador_id)
			_Cerrar_Ficha()
			_Refrescar(false)
			if res.get("ok", false):
				Estilo_Manager.reproducir_sfx("exito")
				_Mostrar_Info("Venta completada", "%s ha sido traspasado por %s." % [
					nombre, _Euros(int(res.get("importe", 0)))])
			else:
				Estilo_Manager.reproducir_sfx("error")
				_Mostrar_Info("No se pudo vender", str(res.get("motivo", "No disponible."))))


func _Confirmar_Renuncia() -> void:
	_Confirmar_Accion("Renunciar al club",
		"¿Dejar tu puesto actual? Podrás fundar un club distinto en cualquier momento.",
		"Dejar el club", "peligro", func():
			Sistema_Manager.Renunciar_Al_Club()
			_tab_actual = "club"
			Estilo_Manager.reproducir_sfx("click")
			_Refrescar(true))


func _Jugar_Partido(es_amistoso: bool = false) -> void:
	var estado: Dictionary = Sistema_Manager.Iniciar_Partido_Amistoso() if es_amistoso else Sistema_Manager.Iniciar_Partido_En_Vivo()
	if estado.is_empty():
		Estilo_Manager.reproducir_sfx("error")
		_Mostrar_Info("No se puede iniciar el partido", "No hay ningún partido disponible ahora mismo.")
		return
	Estilo_Manager.reproducir_sfx("silbato")
	if is_instance_valid(_modal_partido):
		_modal_partido.queue_free()
	_modal_partido = Panel_Manager_Partido.new()
	add_child(_modal_partido)
	_modal_partido.cerrado.connect(func():
		if is_instance_valid(_modal_partido):
			_modal_partido.queue_free()
		_modal_partido = null
		_Refrescar(false))
	_modal_partido.abrir(estado)


func _Cerrar_Dialogos() -> void:
	if is_instance_valid(_dialogo_info):
		_dialogo_info.queue_free()
	_dialogo_info = null


func _Mostrar_Info(titulo: String, mensaje: String) -> void:
	_Cerrar_Dialogos()
	var card := _Crear_Overlay_Dialogo(titulo)
	card.add_child(Estilos_UI.parrafo(mensaje, 14, Estilos_UI.TINTA))
	var btn := Estilo_Manager.boton("Entendido", "primario", "", Estilo_Manager.COLOR_MANAGER, 46)
	btn.pressed.connect(func():
		Estilo_Manager.reproducir_sfx("click")
		_Cerrar_Dialogos())
	card.add_child(btn)


func _Confirmar_Accion(titulo: String, mensaje: String, texto_ok: String,
		variante_ok: String, al_confirmar: Callable) -> void:
	_Cerrar_Dialogos()
	var card := _Crear_Overlay_Dialogo(titulo)
	card.add_child(Estilos_UI.parrafo(mensaje, 14, Estilos_UI.TINTA))

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	card.add_child(hb)

	var btn_no := Estilo_Manager.boton("Cancelar", "secundario", "", Estilos_UI.TINTA, 46)
	btn_no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_no.pressed.connect(func():
		Estilo_Manager.reproducir_sfx("click")
		_Cerrar_Dialogos())
	hb.add_child(btn_no)

	var col_ok: Color = Estilos_UI.PELIGRO if variante_ok == "peligro" else (
		Estilo_Manager.COLOR_ORO if variante_ok == "oro" else Estilo_Manager.COLOR_MANAGER)
	var btn_ok := Estilo_Manager.boton(texto_ok, variante_ok, "", col_ok, 46)
	btn_ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_ok.pressed.connect(func():
		_Cerrar_Dialogos()
		al_confirmar.call())
	hb.add_child(btn_ok)


func _Crear_Overlay_Dialogo(titulo: String) -> VBoxContainer:
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.05, 0.08, 0.14, 0.65)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	_dialogo_info = overlay

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(580, 0)
	panel.add_theme_stylebox_override("panel", Estilos_UI.caja(Color.WHITE, 20, Estilos_UI.BORDE, 1, 8))
	center.add_child(panel)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 20)
	m.add_theme_constant_override("margin_right", 20)
	m.add_theme_constant_override("margin_top", 18)
	m.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(m)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	m.add_child(v)
	v.add_child(Estilos_UI.titulo(titulo, 18, Estilos_UI.TINTA))
	return v


# ── HELPERS DE INTERFAZ COMPARTIDOS (INCLUIDO Panel_Manager_Vistas) ──────────

func _Crear_Columna(padre: Control, stretch_ratio: float = 1.0, ancho_fijo: float = 0.0) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	if ancho_fijo > 0.0:
		col.custom_minimum_size.x = ancho_fijo
	else:
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.size_flags_stretch_ratio = stretch_ratio
	padre.add_child(col)
	return col


func _Tarjeta(fondo: Color = Color.WHITE, destino: Control = null) -> VBoxContainer:
	var padre: Control = destino if destino != null else _contenido
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel",
		Estilos_UI.caja_tarjeta(16, 2) if fondo == Color.WHITE else Estilos_UI.caja(fondo, 16, Estilos_UI.BORDE, 1, 2))
	padre.add_child(panel)

	var m := MarginContainer.new()
	m.mouse_filter = Control.MOUSE_FILTER_PASS
	m.add_theme_constant_override("margin_left", 14)
	m.add_theme_constant_override("margin_right", 14)
	m.add_theme_constant_override("margin_top", 12)
	m.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(m)

	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_PASS
	v.add_theme_constant_override("separation", 9)
	m.add_child(v)
	return v


func _Titulo_Seccion(parent: Control, texto: String, subtitulo: String = "") -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	parent.add_child(v)
	v.add_child(Estilos_UI.titulo(texto, 16, Estilos_UI.TINTA))
	if not subtitulo.is_empty():
		v.add_child(Estilos_UI.parrafo(subtitulo, 12, Estilos_UI.TINTA_SUAVE))


func _Fila_Dato(parent: Control, clave: String, valor: String, color: Color = Estilos_UI.TINTA) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	parent.add_child(h)
	var l1 := Estilos_UI.texto(clave, 12, Estilos_UI.TINTA_SUAVE, 500)
	l1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l1.clip_text = true
	h.add_child(l1)
	h.add_child(Estilos_UI.texto(valor, 12, color, 700))


func _Barra(parent: Control, etiqueta: String, valor: float, color: Color,
		sufijo: String = "", maximo: float = 100.0) -> void:
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_PASS
	v.add_theme_constant_override("separation", 3)
	parent.add_child(v)

	var h := HBoxContainer.new()
	h.mouse_filter = Control.MOUSE_FILTER_PASS
	v.add_child(h)
	var l1 := Estilos_UI.texto(etiqueta, 11, Estilos_UI.TINTA_SUAVE, 600)
	l1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l1)
	h.add_child(Estilos_UI.texto("%d%s" % [int(round(valor)), sufijo], 11, color, 700))

	var fondo := Panel.new()
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fondo.custom_minimum_size = Vector2(0, 7)
	fondo.add_theme_stylebox_override("panel", Estilos_UI.caja(Color("#e2e8f0"), 999, Color.TRANSPARENT, 0, 0))
	v.add_child(fondo)

	var fill := Panel.new()
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill.anchor_left = 0.0
	fill.anchor_top = 0.0
	fill.anchor_bottom = 1.0
	fill.anchor_right = clampf(valor / maxf(1.0, maximo), 0.0, 1.0)
	fill.add_theme_stylebox_override("panel", Estilos_UI.caja(color, 999, Color.TRANSPARENT, 0, 0))
	fondo.add_child(fill)


func _Chip_Grid(parent: Control, columnas: int = 2) -> GridContainer:
	var g := GridContainer.new()
	g.columns = columnas
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 8)
	parent.add_child(g)
	return g


func _Chip_Estadistica(titulo: String, valor: String, color: Color = Estilos_UI.TINTA,
		subtexto: String = "") -> Control:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	p.add_theme_stylebox_override("panel", Estilos_UI.caja(Color("#f8fafc"), 12, Estilos_UI.BORDE, 1, 0))

	var m := MarginContainer.new()
	m.mouse_filter = Control.MOUSE_FILTER_PASS
	m.add_theme_constant_override("margin_left", 10)
	m.add_theme_constant_override("margin_right", 10)
	m.add_theme_constant_override("margin_top", 7)
	m.add_theme_constant_override("margin_bottom", 7)
	p.add_child(m)

	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_PASS
	v.add_theme_constant_override("separation", 2)
	m.add_child(v)
	v.add_child(Estilos_UI.texto(titulo, 11, Estilos_UI.TINTA_SUAVE, 600))
	var val_lbl := Estilos_UI.texto(valor, 14, color, 700)
	val_lbl.clip_text = true
	v.add_child(val_lbl)
	if not subtexto.is_empty():
		v.add_child(Estilos_UI.texto(subtexto, 10, Estilos_UI.TINTA_FANTASMA, 500))
	return p


func _Celda_Tabla(parent: Control, texto: String, ancho: int, color: Color, negrita: bool = false) -> void:
	var lbl := Estilos_UI.texto(texto, 12, color, 700 if negrita else 500)
	if ancho <= 0:
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.clip_text = true
		lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	else:
		lbl.custom_minimum_size.x = ancho
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if ancho <= 22 or ancho >= 50 else HORIZONTAL_ALIGNMENT_RIGHT
	parent.add_child(lbl)


func _Estrellas(cantidad: int) -> String:
	var n: int = clampi(cantidad, 1, 5)
	return "★".repeat(n) + "☆".repeat(5 - n)


func _Formatear_Numero(n: int) -> String:
	var neg: bool = n < 0
	var s: String = str(abs(n))
	var out: String = ""
	var cont: int = 0
	for i in range(s.length() - 1, -1, -1):
		if cont > 0 and cont % 3 == 0:
			out = "." + out
		out = s[i] + out
		cont += 1
	return ("-" if neg else "") + out


func _Euros(n: int) -> String:
	return "%s €" % _Formatear_Numero(n)


func _Posicion_Usuario(division: int, club_id: String) -> int:
	var tabla: Array = Sistema_Manager.Obtener_Clasificacion(division)
	for i in range(tabla.size()):
		if str(tabla[i].get("id", "")) == club_id:
			return i + 1
	return 1


func _Signo_Racha_Consecutiva(racha_arr: Array) -> int:
	if racha_arr.is_empty():
		return 0
	var primera: String = str(racha_arr[0])
	if primera != "V" and primera != "D":
		return 0
	var n: int = 0
	for r in racha_arr:
		if str(r) == primera:
			n += 1
		else:
			break
	return n if primera == "V" else -n


func _Frase_Manager_Club(club: Dictionary, racha_sig: int, confianza: int) -> String:
	var nombre_j: String = str(club.get("nombre", "el club"))
	if Sistema_Manager.Puede_Jugar_Manual():
		return "¡Día de partido! El vestuario de %s está enchufado y listo para saltar al césped." % nombre_j
	if racha_sig >= 2:
		return "Llevamos %d victorias seguidas. Hay que mantener el hambre en cada entrenamiento." % racha_sig
	if racha_sig <= -2:
		return "Venimos de una mala racha, pero cerrando filas en defensa daremos la vuelta al rumbo."
	if confianza < 40:
		return "La directiva aprieta: necesitamos sumar puntos cuanto antes y cuidar la química."
	return "El grupo trabaja con buena sintonía. Revisa la pizarra o busca refuerzos si ves margen."


func _Texto_Objetivo_Division(division: int) -> String:
	match division:
		1:
			return "Campeón de Liga (1º)"
		2, 3:
			return "Ascender (1º-2º) · Evitar descenso (3º-4º)"
		_:
			return "Ascender a 3ª División (1º-2º)"
