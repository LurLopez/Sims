class_name Panel_Bolsa
extends Control

# Pantalla completa de bolsa: resumen de la cartera, gráfico de evolución y
# estadísticas históricas. La lógica vive en el autoload `Sistema_Bolsa`.

signal cerrado
signal dinero_cambiado

const TABS := ["resumen", "evolucion", "estadisticas"]
const PERIODOS := [1, 5, 10, 0]

var _scroll: ScrollContainer
var _vbox: VBoxContainer
var _tabs_barra: HBoxContainer
var _tabs_botones: Dictionary = {}
var _contenidos: Dictionary = {}

var _hero_pill: PanelContainer
var _hero_valor: Label
var _hero_estado: Label
var _hero_invertido: Label
var _hero_beneficio: Label
var _hero_efectivo: Label
var _hero_nivel_bar: ProgressBar
var _hero_nivel_txt: Label
var _hero_nota: Label
var _hero_btn_invertir: Button
var _hero_btn_aportar: Button
var _hero_btn_retirar: Button

var _mercado_pill: PanelContainer
var _mercado_titulo: Label
var _mercado_evento: Label
var _mercado_detalle: Label
var _perfil_nivel: Label
var _perfil_mental: Label
var _perfil_sangre: Label

var _evo_pill: PanelContainer
var _evo_chart: Grafico_Bolsa
var _evo_mejor: Label
var _evo_peor: Label
var _evo_caida: Label
var _evo_rango: Label
var _periodo_botones: Dictionary = {}
var _periodo_anios: int = 0

var _stats_labels: Dictionary = {}
var _nivel_bar: ProgressBar
var _nivel_pct: Label
var _nivel_salud: Label
var _nivel_sangre: Label
var _nivel_desc: Label
var _ops_lista: VBoxContainer
var _eventos_lista: VBoxContainer

var _dlg_win: Window
var _dlg_titulo: Label
var _dlg_desc: Label
var _dlg_input: LineEdit
var _dlg_nota: Label
var _dlg_error: Label
var _dlg_confirmar: Button
var _dlg_modo: String = "invertir"
var _dlg_maximo: float = 0.0

var _tab_activa: String = "resumen"
var _firma_stats: String = ""
var _firma_ops: String = ""
var _firma_eventos: String = ""
var _tiempo_refresco: float = 0.0


func _ready() -> void:
	position = Vector2.ZERO
	size = get_viewport().get_visible_rect().size
	mouse_filter = Control.MOUSE_FILTER_STOP
	_construir()
	set_process(true)
	if get_viewport() != null and not get_viewport().size_changed.is_connected(_ajustar_tamano):
		get_viewport().size_changed.connect(_ajustar_tamano)


func _ajustar_tamano() -> void:
	position = Vector2.ZERO
	size = get_viewport().get_visible_rect().size


func Abrir(seccion: String = "resumen") -> void:
	visible = true
	_seleccionar_tab(seccion, true)
	_tiempo_refresco = 0.0
	_firma_stats = ""
	_refrescar(true)


func cerrar() -> void:
	visible = false
	cerrado.emit()


func _process(delta: float) -> void:
	if not visible:
		return
	_tiempo_refresco += delta
	if _tiempo_refresco < 0.5:
		return
	_tiempo_refresco = 0.0
	_refrescar(false)


# ----------------------------------------------------------------------------
# Construcción
# ----------------------------------------------------------------------------

func _construir() -> void:
	var fondo := ColorRect.new()
	fondo.color = Estilos_UI.FONDO
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)

	Estilos_UI.Crear_Label_Titulo_Panel("Bolsa e inversiones", self, Estilos_UI.TINTA)
	Estilos_UI.Crear_Boton_Volver_Panel(self, Callable(self, "cerrar"))

	var subtitulo := Estilos_UI.texto(
		"Sigue tu cartera, su evolución y tus estadísticas", 12,
		Estilos_UI.TINTA_SUAVE, 600)
	subtitulo.set_anchors_preset(Control.PRESET_TOP_WIDE)
	subtitulo.offset_left = 74
	subtitulo.offset_top = 158
	subtitulo.offset_right = -20
	subtitulo.offset_bottom = 180
	add_child(subtitulo)

	_tabs_barra = HBoxContainer.new()
	_tabs_barra.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_tabs_barra.offset_left = 20
	_tabs_barra.offset_top = 186
	_tabs_barra.offset_right = -20
	_tabs_barra.offset_bottom = 230
	_tabs_barra.add_theme_constant_override("separation", 8)
	add_child(_tabs_barra)
	for tab in TABS:
		var b := Estilos_UI.boton(_texto_tab(tab), "chip", "", Estilos_UI.AZUL, 42)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_seleccionar_tab.bind(tab, false))
		_tabs_barra.add_child(b)
		_tabs_botones[tab] = b

	_scroll = ScrollContainer.new()
	_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scroll.offset_left = 20
	_scroll.offset_top = 240
	_scroll.offset_right = -20
	_scroll.offset_bottom = -104
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)

	_vbox = VBoxContainer.new()
	_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vbox.add_theme_constant_override("separation", 12)
	_scroll.add_child(_vbox)

	for tab in TABS:
		var contenido := VBoxContainer.new()
		contenido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		contenido.add_theme_constant_override("separation", 12)
		contenido.visible = false
		_vbox.add_child(contenido)
		_contenidos[tab] = contenido

	_construir_resumen(_contenidos["resumen"])
	_construir_evolucion(_contenidos["evolucion"])
	_construir_estadisticas(_contenidos["estadisticas"])
	_construir_dialogo()

	_seleccionar_tab("resumen", true)


func _texto_tab(tab: String) -> String:
	match tab:
		"evolucion":
			return "Evolución"
		"estadisticas":
			return "Estadísticas"
		_:
			return "Resumen"


func _construir_resumen(parent: VBoxContainer) -> void:
	_construir_hero(parent)
	_construir_mercado(parent)
	_construir_perfil(parent)


func _construir_hero(parent: VBoxContainer) -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Estilos_UI.NAVY, 18, Estilos_UI.NAVY_OSCURO, 0, 4))
	parent.add_child(card)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 18)
	m.add_theme_constant_override("margin_right", 18)
	m.add_theme_constant_override("margin_top", 16)
	m.add_theme_constant_override("margin_bottom", 16)
	card.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	m.add_child(v)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	v.add_child(top)
	var cap := Estilos_UI.texto("VALOR DE LA CARTERA", 10, Color("#93c5fd"), 700)
	cap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(cap)
	_hero_pill = _crear_pill("Nivel 1", Color("#1e3a5f"), Color("#93c5fd"))
	top.add_child(_hero_pill)

	_hero_valor = Estilos_UI.titulo("0 €", 30, Color.WHITE)
	v.add_child(_hero_valor)
	_hero_estado = Estilos_UI.texto("Sin posición abierta", 12, Color("#cbd5e1"), 600)
	v.add_child(_hero_estado)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	v.add_child(fila)
	_hero_invertido = _mini_dato(fila, "INVERTIDO")
	_hero_beneficio = _mini_dato(fila, "BENEFICIO")
	_hero_efectivo = _mini_dato(fila, "EFECTIVO")

	var nivel_top := HBoxContainer.new()
	nivel_top.add_theme_constant_override("separation", 6)
	v.add_child(nivel_top)
	var nivel_lbl := Estilos_UI.texto("Nivel inversor", 11, Color("#cbd5e1"), 600)
	nivel_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nivel_top.add_child(nivel_lbl)
	_hero_nivel_txt = Estilos_UI.texto("1/100", 11, Color("#93c5fd"), 700)
	nivel_top.add_child(_hero_nivel_txt)

	_hero_nivel_bar = ProgressBar.new()
	_hero_nivel_bar.custom_minimum_size = Vector2(0, 7)
	_hero_nivel_bar.min_value = 0
	_hero_nivel_bar.max_value = 100
	_hero_nivel_bar.show_percentage = false
	_hero_nivel_bar.add_theme_stylebox_override("background",
		Estilos_UI.barra_fondo())
	_hero_nivel_bar.add_theme_stylebox_override("fill",
		Estilos_UI.barra_relleno(Estilos_UI.AZUL_CLARO))
	v.add_child(_hero_nivel_bar)

	_hero_nota = Estilos_UI.parrafo("", 11, Color("#cbd5e1"))
	v.add_child(_hero_nota)

	var acciones := HBoxContainer.new()
	acciones.add_theme_constant_override("separation", 8)
	v.add_child(acciones)
	_hero_btn_invertir = Estilos_UI.boton("Invertir en bolsa", "primario",
		"trending-up", Estilos_UI.AZUL, 46)
	_hero_btn_invertir.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hero_btn_invertir.pressed.connect(_mostrar_dialogo.bind("invertir"))
	acciones.add_child(_hero_btn_invertir)
	_hero_btn_aportar = Estilos_UI.boton("Aportar", "primario", "plus",
		Estilos_UI.AZUL_CLARO, 46)
	_hero_btn_aportar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hero_btn_aportar.pressed.connect(_mostrar_dialogo.bind("aportar"))
	acciones.add_child(_hero_btn_aportar)
	_hero_btn_retirar = Estilos_UI.boton("Retirar", "suave", "hand-coins",
		Estilos_UI.PELIGRO, 46)
	_hero_btn_retirar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hero_btn_retirar.pressed.connect(_mostrar_dialogo.bind("retirar"))
	acciones.add_child(_hero_btn_retirar)


func _mini_dato(parent: HBoxContainer, titulo: String) -> Label:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 1)
	parent.add_child(v)
	v.add_child(Estilos_UI.texto(titulo, 9, Color("#93c5fd"), 700))
	var valor := Estilos_UI.texto("—", 14, Color.WHITE, 700)
	v.add_child(valor)
	return valor


func _construir_mercado(parent: VBoxContainer) -> void:
	var card := _crear_card(parent, "Pulso del mercado", "activity", Estilos_UI.AZUL)
	_mercado_pill = card["pill"]
	_mercado_titulo = Estilos_UI.texto("ÚLTIMO MOVIMIENTO", 9, Estilos_UI.TINTA_FANTASMA, 700)
	card["vbox"].add_child(_mercado_titulo)
	_mercado_evento = Estilos_UI.texto("Aún no hay movimientos registrados.", 14,
		Estilos_UI.TINTA, 600)
	_mercado_evento.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card["vbox"].add_child(_mercado_evento)
	_mercado_detalle = Estilos_UI.texto("", 11, Estilos_UI.TINTA_FANTASMA, 500)
	card["vbox"].add_child(_mercado_detalle)


func _construir_perfil(parent: VBoxContainer) -> void:
	var card := _crear_card(parent, "Tu perfil inversor", "user-round", Estilos_UI.INDIGO)
	card["pill"].visible = false
	_perfil_nivel = _fila_perfil(card["vbox"], "star", "Nivel inversor",
		"—", Estilos_UI.INDIGO)
	_perfil_mental = _fila_perfil(card["vbox"], "brain", "Salud mental al invertir",
		"—", Estilos_UI.AZUL)
	_perfil_sangre = _fila_perfil(card["vbox"], "heart-pulse", "Sangre fría",
		"—", Estilos_UI.PELIGRO)
	var info := Estilos_UI.parrafo(
		"El nivel y la salud mental inclinan la balanza de cada movimiento. "
		+ "Con sangre fría baja puedes vender en pánico si la posición pierde más del 15 %.",
		11, Estilos_UI.TINTA_FANTASMA)
	card["vbox"].add_child(info)


func _fila_perfil(parent: VBoxContainer, icono: String, titulo: String,
		valor: String, color: Color) -> Label:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	parent.add_child(h)
	h.add_child(Estilos_UI.badge_icono(icono, 30, 15, color, Color.WHITE, 9))
	var lbl := Estilos_UI.texto(titulo, 13, Estilos_UI.TINTA_SUAVE, 500)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(lbl)
	var v := Estilos_UI.texto(valor, 13, Estilos_UI.TINTA, 700)
	h.add_child(v)
	return v


func _construir_evolucion(parent: VBoxContainer) -> void:
	var card := _crear_card(parent, "Evolución del beneficio", "chart-line", Estilos_UI.EXITO)
	_evo_pill = card["pill"]

	var periodos := HBoxContainer.new()
	periodos.add_theme_constant_override("separation", 6)
	card["vbox"].add_child(periodos)
	for anios in PERIODOS:
		var texto := "Todo" if int(anios) == 0 else "%d año%s" % [int(anios), "" if int(anios) == 1 else "s"]
		var b := Estilos_UI.boton(texto, "chip", "", Estilos_UI.AZUL, 36)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 12)
		b.pressed.connect(_cambiar_periodo.bind(int(anios)))
		periodos.add_child(b)
		_periodo_botones[int(anios)] = b

	_evo_chart = Grafico_Bolsa.new()
	_evo_chart.custom_minimum_size = Vector2(0, 238)
	card["vbox"].add_child(_evo_chart)

	_evo_rango = Estilos_UI.texto("", 10, Estilos_UI.TINTA_FANTASMA, 500)
	card["vbox"].add_child(_evo_rango)

	var pie := HBoxContainer.new()
	pie.add_theme_constant_override("separation", 8)
	card["vbox"].add_child(pie)
	_evo_mejor = _mini_metrica(pie, "MEJOR MOMENTO", Estilos_UI.EXITO)
	_evo_peor = _mini_metrica(pie, "PEOR MOMENTO", Estilos_UI.PELIGRO)
	_evo_caida = _mini_metrica(pie, "MÁX. CAÍDA", Estilos_UI.ORO)

	var nota := Estilos_UI.parrafo(
		"La línea suma las ganancias ya retiradas y la variación de tu posición actual.",
		11, Estilos_UI.TINTA_FANTASMA)
	card["vbox"].add_child(nota)


func _mini_metrica(parent: HBoxContainer, titulo: String, color: Color) -> Label:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 1)
	parent.add_child(v)
	v.add_child(Estilos_UI.texto(titulo, 8, color, 700))
	var valor := Estilos_UI.texto("—", 13, Estilos_UI.TINTA, 700)
	v.add_child(valor)
	return valor


func _construir_estadisticas(parent: VBoxContainer) -> void:
	var card := _crear_card(parent, "Estadísticas de inversión", "chart-no-axes-column",
		Estilos_UI.MORADO)
	card["pill"].visible = false
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	card["vbox"].add_child(grid)
	_crear_stat(grid, "beneficio_total", "Beneficio total", "hand-coins", Estilos_UI.EXITO)
	_crear_stat(grid, "rentabilidad", "Rentabilidad", "target", Estilos_UI.AZUL)
	_crear_stat(grid, "aportado_total", "Capital aportado", "piggy-bank", Estilos_UI.INDIGO)
	_crear_stat(grid, "retirado_total", "Capital retirado", "wallet", Estilos_UI.ORO)
	_crear_stat(grid, "operaciones", "Operaciones", "list-todo", Estilos_UI.CIAN)
	_crear_stat(grid, "acierto", "Tasa de acierto", "badge-check", Estilos_UI.EXITO)
	_crear_stat(grid, "mejor_operacion", "Mejor operación", "trophy", Estilos_UI.EXITO)
	_crear_stat(grid, "peor_operacion", "Peor operación", "triangle-alert", Estilos_UI.PELIGRO)
	_crear_stat(grid, "minutos_activos", "Tiempo invertido", "clock", Estilos_UI.AZUL)
	_crear_stat(grid, "eventos", "Eventos de mercado", "activity", Estilos_UI.MORADO)
	_crear_stat(grid, "racha", "Racha del mercado", "flame", Estilos_UI.ORO)
	_crear_stat(grid, "max_caida", "Máxima caída", "trending-up", Estilos_UI.PELIGRO)

	var nivel_card := _crear_card(parent, "Nivel inversor", "star", Estilos_UI.ORO)
	nivel_card["pill"].visible = false
	var nivel_top := HBoxContainer.new()
	nivel_card["vbox"].add_child(nivel_top)
	var nivel_lbl := Estilos_UI.texto("Experiencia", 12, Estilos_UI.TINTA_SUAVE, 500)
	nivel_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nivel_top.add_child(nivel_lbl)
	_nivel_pct = Estilos_UI.texto("1/100", 13, Estilos_UI.ORO, 700)
	nivel_top.add_child(_nivel_pct)
	_nivel_bar = ProgressBar.new()
	_nivel_bar.custom_minimum_size = Vector2(0, 9)
	_nivel_bar.min_value = 0
	_nivel_bar.max_value = 100
	_nivel_bar.show_percentage = false
	_nivel_bar.add_theme_stylebox_override("background", Estilos_UI.barra_fondo())
	_nivel_bar.add_theme_stylebox_override("fill", Estilos_UI.barra_relleno(Estilos_UI.ORO))
	nivel_card["vbox"].add_child(_nivel_bar)
	_nivel_desc = Estilos_UI.parrafo("", 11, Estilos_UI.TINTA_SUAVE)
	nivel_card["vbox"].add_child(_nivel_desc)
	var perfil := HBoxContainer.new()
	perfil.add_theme_constant_override("separation", 8)
	nivel_card["vbox"].add_child(perfil)
	_nivel_salud = _chip_dato(perfil, "Mental", Estilos_UI.AZUL)
	_nivel_sangre = _chip_dato(perfil, "Sangre fría", Estilos_UI.PELIGRO)

	var ops_card := _crear_card(parent, "Operaciones recientes", "hand-coins", Estilos_UI.AZUL)
	ops_card["pill"].visible = false
	_ops_lista = VBoxContainer.new()
	_ops_lista.add_theme_constant_override("separation", 8)
	ops_card["vbox"].add_child(_ops_lista)

	var ev_card := _crear_card(parent, "Últimos movimientos del mercado", "newspaper",
		Estilos_UI.MORADO)
	ev_card["pill"].visible = false
	_eventos_lista = VBoxContainer.new()
	_eventos_lista.add_theme_constant_override("separation", 8)
	ev_card["vbox"].add_child(_eventos_lista)


func _crear_stat(parent: GridContainer, clave: String, titulo: String,
		icono: String, color: Color) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Estilos_UI.SUPERFICIE_2, 12, Estilos_UI.BORDE, 1, 0))
	parent.add_child(panel)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 10)
	m.add_theme_constant_override("margin_right", 10)
	m.add_theme_constant_override("margin_top", 9)
	m.add_theme_constant_override("margin_bottom", 9)
	panel.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	m.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	v.add_child(top)
	top.add_child(Estilos_UI.icono_rect(icono, 13, color))
	top.add_child(Estilos_UI.texto(titulo, 9, Estilos_UI.TINTA_FANTASMA, 700))
	var valor := Estilos_UI.texto("—", 15, Estilos_UI.TINTA, 700)
	v.add_child(valor)
	_stats_labels[clave] = valor


func _chip_dato(parent: HBoxContainer, titulo: String, color: Color) -> Label:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Color(color, 0.09), 9, Color(color, 0.20), 1, 0))
	parent.add_child(p)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 9)
	m.add_theme_constant_override("margin_right", 9)
	m.add_theme_constant_override("margin_top", 5)
	m.add_theme_constant_override("margin_bottom", 5)
	p.add_child(m)
	var h := HBoxContainer.new()
	m.add_child(h)
	h.add_child(Estilos_UI.texto(titulo + ": ", 10, Estilos_UI.TINTA_SUAVE, 500))
	var valor := Estilos_UI.texto("—", 11, color, 700)
	h.add_child(valor)
	return valor


func _crear_card(parent: VBoxContainer, titulo: String, icono: String,
		color: Color) -> Dictionary:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", Estilos_UI.caja_tarjeta(16, 3))
	parent.add_child(card)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 16)
	m.add_theme_constant_override("margin_right", 16)
	m.add_theme_constant_override("margin_top", 14)
	m.add_theme_constant_override("margin_bottom", 14)
	card.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	m.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 9)
	v.add_child(top)
	top.add_child(Estilos_UI.badge_icono(icono, 32, 17, color, Color.WHITE, 9))
	var lbl := Estilos_UI.titulo(titulo, 15, Estilos_UI.TINTA)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(lbl)
	var pill := _crear_pill("", Estilos_UI.SUPERFICIE_2, Estilos_UI.TINTA_SUAVE)
	top.add_child(pill)
	return {"card": card, "vbox": v, "pill": pill}


# ----------------------------------------------------------------------------
# Actualización
# ----------------------------------------------------------------------------

func _refrescar(force: bool) -> void:
	if not visible:
		return
	_actualizar_hero()
	_actualizar_mercado()
	var firma := _firma_datos()
	if force or firma != _firma_stats:
		_firma_stats = firma
		_actualizar_estadisticas()
		_actualizar_evolucion()
		_actualizar_listas()
	elif _tab_activa == "evolucion":
		_actualizar_evolucion()
	_actualizar_botones_periodo()


func _firma_datos() -> String:
	var stats := Sistema_Bolsa.Obtener_Estadisticas()
	return "%d|%d|%d|%d|%d|%d" % [
		Variables_Dinamicas.Inversion_Historial.size(),
		Variables_Dinamicas.Inversion_Operaciones.size(),
		Variables_Dinamicas.Inversion_Eventos.size(),
		int(round(float(stats["beneficio_total"]) * 100.0)),
		int(stats["nivel"]),
		int(int(stats["minutos_activos"]) / 60),
	]


func _actualizar_hero() -> void:
	var stats := Sistema_Bolsa.Obtener_Estadisticas()
	var activa := bool(stats["activa"])
	var valor := float(stats["valor"])
	var beneficio := float(stats["beneficio_total"])
	var no_realizado := float(stats["beneficio_no_realizado"])
	var nivel := int(stats["nivel"])
	var efectivo := float(Variables_Dinamicas.Dinero)

	_hero_valor.text = _moneda(valor)
	if activa:
		var pct := no_realizado / maxf(1.0, float(stats["invertido"])) * 100.0
		_hero_estado.text = "%s %s (%s) en tu posición" % [
			"Ganando" if no_realizado >= 0.0 else "Perdiendo",
			_moneda_firmada(no_realizado),
			_porcentaje(pct)]
	else:
		_hero_estado.text = "Sin posición abierta · %s disponibles" % _moneda(efectivo)
	_hero_estado.add_theme_color_override("font_color",
		Color("#86efac") if activa and no_realizado >= 0.0 else Color("#fca5a5") if activa else Color("#cbd5e1"))

	_hero_invertido.text = _moneda(float(stats["invertido"]))
	_hero_beneficio.text = _moneda_firmada(beneficio)
	_hero_beneficio.add_theme_color_override("font_color",
		Color("#86efac") if beneficio >= 0.0 else Color("#fca5a5"))
	_hero_efectivo.text = _moneda(efectivo)
	_hero_nivel_txt.text = "%d/100" % nivel
	_aplicar_barra(_hero_nivel_bar, nivel, Estilos_UI.AZUL_CLARO)
	_actualizar_pill(_hero_pill, "Nivel %d" % nivel, Color("#1e3a5f"), Color("#93c5fd"))

	var sangre := int(Variables_Estaticas.Habilidades[6])
	if activa and sangre < int(Sistema_Bolsa.SANGRE_FRIA_MINIMA):
		_hero_nota.text = "Riesgo de pánico: con sangre fría baja venderás si pierdes más del 15 %."
		_hero_nota.add_theme_color_override("font_color", Color("#fca5a5"))
	else:
		_hero_nota.text = "Sangre fría %d/100 · salud mental al invertir %d/100" % [
			sangre, int(Variables_Dinamicas.Salud_Mental_Al_Invertir)]
		_hero_nota.add_theme_color_override("font_color", Color("#cbd5e1"))

	_hero_btn_invertir.visible = not activa
	_hero_btn_aportar.visible = activa
	_hero_btn_retirar.visible = activa


func _actualizar_mercado() -> void:
	var estado := Sistema_Bolsa.Estado_Mercado()
	var color_estado := _color_estado(str(estado["color"]))
	_actualizar_pill(_mercado_pill, str(estado["texto"]),
		Color(color_estado, 0.13), color_estado)

	var eventos := Sistema_Bolsa.Obtener_Eventos()
	if eventos.is_empty():
		_mercado_titulo.visible = false
		_mercado_evento.text = "El mercado aún no ha registrado movimientos. Invierte para empezar a seguir su pulso."
		_mercado_detalle.text = ""
	else:
		_mercado_titulo.visible = true
		var ultimo: Dictionary = eventos[-1]
		var delta := float(ultimo.get("delta_pct", 0.0))
		_mercado_evento.text = str(ultimo.get("titulo", "Movimiento del mercado"))
		_mercado_detalle.text = "%s %s · %s · %s" % [
			"▲" if delta >= 0.0 else "▼",
			_porcentaje(delta, true),
			Sistema_Bolsa.Hace_Texto(int(ultimo.get("minuto", 0))),
			_moneda_firmada(float(ultimo.get("importe", 0.0))),
		]

	var nivel := Sistema_Bolsa.Progreso_Nivel()
	_perfil_nivel.text = "%d/100" % nivel
	_perfil_mental.text = "%d/100" % int(Variables_Dinamicas.Salud_Mental_Al_Invertir)
	var sangre := int(Variables_Estaticas.Habilidades[6])
	_perfil_sangre.text = "%d/100" % sangre
	_perfil_sangre.add_theme_color_override("font_color",
		Estilos_UI.PELIGRO if sangre < int(Sistema_Bolsa.SANGRE_FRIA_MINIMA) else Estilos_UI.TINTA)


func _actualizar_estadisticas() -> void:
	var stats := Sistema_Bolsa.Obtener_Estadisticas()
	var beneficio := float(stats["beneficio_total"])
	var mejor := float(stats["mejor_operacion"])
	var peor := float(stats["peor_operacion"])
	var caida := float(stats["max_caida"])
	var racha := int(stats["racha_actual"])

	_set_stat("beneficio_total", _moneda_firmada(beneficio),
		Estilos_UI.EXITO if beneficio >= 0.0 else Estilos_UI.PELIGRO)
	_set_stat("rentabilidad", _porcentaje(float(stats["rentabilidad"]), true),
		Estilos_UI.EXITO if float(stats["rentabilidad"]) >= 0.0 else Estilos_UI.PELIGRO)
	_set_stat("aportado_total", _moneda(float(stats["aportado_total"])), Estilos_UI.TINTA)
	_set_stat("retirado_total", _moneda(float(stats["retirado_total"])), Estilos_UI.TINTA)
	_set_stat("operaciones", "%d" % int(stats["operaciones"]), Estilos_UI.TINTA)
	_set_stat("acierto", _porcentaje(float(stats["acierto"])), Estilos_UI.EXITO)
	_set_stat("mejor_operacion", _moneda_firmada(mejor),
		Estilos_UI.EXITO if mejor > 0.0 else Estilos_UI.TINTA)
	_set_stat("peor_operacion", _moneda_firmada(peor),
		Estilos_UI.PELIGRO if peor < 0.0 else Estilos_UI.TINTA)
	_set_stat("minutos_activos", Sistema_Bolsa.Formatear_Tiempo(int(stats["minutos_activos"])),
		Estilos_UI.TINTA)
	_set_stat("eventos", "%d↑ / %d↓" % [int(stats["subidas"]), int(stats["bajadas"])],
		Estilos_UI.TINTA)
	var texto_racha := "—"
	if racha > 0:
		texto_racha = "%d subidas" % racha
	elif racha < 0:
		texto_racha = "%d bajadas" % absi(racha)
	_set_stat("racha", texto_racha, Estilos_UI.EXITO if racha > 0 else Estilos_UI.PELIGRO if racha < 0 else Estilos_UI.TINTA)
	_set_stat("max_caida", ("−" + _moneda(caida)) if caida > 0.01 else "—",
		Estilos_UI.PELIGRO if caida > 0.01 else Estilos_UI.TINTA)

	var nivel := int(stats["nivel"])
	_nivel_pct.text = "%d/100" % nivel
	_aplicar_barra(_nivel_bar, nivel, Estilos_UI.ORO)
	_nivel_salud.text = "%d/100" % int(Variables_Dinamicas.Salud_Mental_Al_Invertir)
	_nivel_sangre.text = "%d/100" % int(Variables_Estaticas.Habilidades[6])
	if nivel >= 100:
		_nivel_desc.text = "Nivel máximo. Tu experiencia hace que el mercado te sea más favorable."
	else:
		_nivel_desc.text = "Sube con los eventos de mercado y al cerrar una posición en positivo. Un nivel alto inclina la probabilidad a tu favor."


func _actualizar_evolucion() -> void:
	var stats := Sistema_Bolsa.Obtener_Estadisticas()
	var total := float(stats["beneficio_total"])
	_actualizar_pill(_evo_pill, _moneda_firmada(total),
		Estilos_UI.EXITO_SUAVE if total >= 0.0 else Estilos_UI.PELIGRO_SUAVE,
		Estilos_UI.EXITO if total >= 0.0 else Estilos_UI.PELIGRO)
	_evo_pill.visible = true

	var hasta := Sistema_Bolsa.Minuto_Actual()
	var desde := -1
	if _periodo_anios > 0:
		var dias_por_anio := maxi(1, int(Variables_Estaticas.Dias_Por_Anio()))
		desde = hasta - _periodo_anios * dias_por_anio * 1440
	var hist := Sistema_Bolsa.Obtener_Historial(desde, hasta)

	var punto_actual := {
		"minuto": hasta,
		"beneficio": Sistema_Bolsa.Beneficio_Acumulado(),
		"valor": float(stats["valor"]),
		"invertido": float(stats["invertido"]),
	}
	if hist.is_empty():
		if Sistema_Bolsa.Esta_Activa() or absf(total) > 0.01:
			hist.append(punto_actual)
	elif int(hist[-1].get("minuto", 0)) < hasta:
		hist.append(punto_actual)
	else:
		hist[-1] = punto_actual

	_evo_chart.Configurar(hist, Sistema_Bolsa.Obtener_Operaciones())

	var mejor := -INF
	var peor := INF
	for p in hist:
		var b := float(p.get("beneficio", 0.0))
		mejor = maxf(mejor, b)
		peor = minf(peor, b)
	if hist.is_empty():
		mejor = 0.0
		peor = 0.0
	_evo_mejor.text = _moneda_firmada(mejor)
	_evo_mejor.add_theme_color_override("font_color",
		Estilos_UI.EXITO if mejor > 0.01 else Estilos_UI.TINTA)
	_evo_peor.text = _moneda_firmada(peor)
	_evo_peor.add_theme_color_override("font_color",
		Estilos_UI.PELIGRO if peor < -0.01 else Estilos_UI.TINTA)
	var caida := float(stats["max_caida"])
	_evo_caida.text = ("−" + _moneda(caida)) if caida > 0.01 else "—"
	_evo_caida.add_theme_color_override("font_color",
		Estilos_UI.ORO if caida > 0.01 else Estilos_UI.TINTA)

	var etiqueta := "Todo el historial" if _periodo_anios == 0 else "Últimos %d año%s" % [
		_periodo_anios, "" if _periodo_anios == 1 else "s"]
	_evo_rango.text = "%s · %d registro%s" % [
		etiqueta, hist.size(), "" if hist.size() == 1 else "s"]


func _actualizar_listas() -> void:
	var ops := Sistema_Bolsa.Obtener_Operaciones()
	var firma_ops := "%d|%d" % [ops.size(), int(ops[-1].get("minuto", 0)) if not ops.is_empty() else -1]
	if firma_ops != _firma_ops:
		_firma_ops = firma_ops
		_limpiar(_ops_lista)
		if ops.is_empty():
			_ops_lista.add_child(Estilos_UI.parrafo(
				"Todavía no has hecho ninguna operación.", 12, Estilos_UI.TINTA_FANTASMA))
		else:
			var maximo := mini(8, ops.size())
			for i in range(ops.size() - 1, ops.size() - 1 - maximo, -1):
				var op: Dictionary = ops[i]
				_ops_lista.add_child(_fila_operacion(op))
				if i > ops.size() - maximo:
					_ops_lista.add_child(Estilos_UI.divisor_horizontal())

	var eventos := Sistema_Bolsa.Obtener_Eventos()
	var firma_eventos := "%d|%d" % [eventos.size(), int(eventos[-1].get("minuto", 0)) if not eventos.is_empty() else -1]
	if firma_eventos != _firma_eventos:
		_firma_eventos = firma_eventos
		_limpiar(_eventos_lista)
		if eventos.is_empty():
			_eventos_lista.add_child(Estilos_UI.parrafo(
				"El mercado todavía no ha registrado movimientos.", 12, Estilos_UI.TINTA_FANTASMA))
		else:
			var maximo := mini(7, eventos.size())
			for i in range(eventos.size() - 1, eventos.size() - 1 - maximo, -1):
				var ev: Dictionary = eventos[i]
				_eventos_lista.add_child(_fila_evento(ev))
				if i > eventos.size() - maximo:
					_eventos_lista.add_child(Estilos_UI.divisor_horizontal())


func _actualizar_botones_periodo() -> void:
	for anios in _periodo_botones.keys():
		var b: Button = _periodo_botones[anios]
		var activo := int(anios) == _periodo_anios
		Estilos_UI.aplicar_estilo_boton(b, "primario" if activo else "chip", Estilos_UI.AZUL)
		b.add_theme_font_size_override("font_size", 12)


func _fila_operacion(op: Dictionary) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 9)
	var tipo := str(op.get("tipo", "aporte"))
	var icono := "plus"
	var color := Estilos_UI.AZUL
	match tipo:
		"retirada":
			icono = "minus"
			color = Estilos_UI.ORO
		"auto_venta":
			icono = "zap"
			color = Estilos_UI.PELIGRO
	h.add_child(Estilos_UI.badge_icono(icono, 30, 15, color, Color.WHITE, 9))
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 1)
	h.add_child(v)
	var titulo := _titulo_operacion(tipo)
	if bool(op.get("cerrado", false)):
		titulo += " · posición cerrada"
	v.add_child(Estilos_UI.texto(titulo, 12, Estilos_UI.TINTA, 600))
	v.add_child(Estilos_UI.texto(Sistema_Bolsa.Hace_Texto(int(op.get("minuto", 0))),
		10, Estilos_UI.TINTA_FANTASMA, 500))
	var der := VBoxContainer.new()
	der.add_theme_constant_override("separation", 1)
	h.add_child(der)
	var monto := Estilos_UI.texto(_moneda(float(op.get("cantidad", 0.0))), 12,
		Estilos_UI.TINTA, 700)
	monto.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	der.add_child(monto)
	var beneficio := float(op.get("beneficio", 0.0))
	if tipo != "aporte":
		var lbl := Estilos_UI.texto(_moneda_firmada(beneficio), 11,
			Estilos_UI.EXITO if beneficio >= 0.0 else Estilos_UI.PELIGRO, 600)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		der.add_child(lbl)
	return h


func _titulo_operacion(tipo: String) -> String:
	match tipo:
		"retirada":
			return "Retirada"
		"auto_venta":
			return "Venta por pánico"
		_:
			return "Aportación"


func _fila_evento(ev: Dictionary) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 9)
	var delta := float(ev.get("delta_pct", 0.0))
	var color := Estilos_UI.EXITO if delta >= 0.0 else Estilos_UI.PELIGRO
	var punto := PanelContainer.new()
	punto.custom_minimum_size = Vector2(10, 10)
	punto.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	punto.add_theme_stylebox_override("panel",
		Estilos_UI.caja(color, 999, color, 0, 0))
	h.add_child(punto)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 1)
	h.add_child(v)
	var titulo := Estilos_UI.texto(str(ev.get("titulo", "Movimiento del mercado")),
		12, Estilos_UI.TINTA, 500)
	titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(titulo)
	v.add_child(Estilos_UI.texto(Sistema_Bolsa.Hace_Texto(int(ev.get("minuto", 0))),
		10, Estilos_UI.TINTA_FANTASMA, 500))
	var delta_lbl := Estilos_UI.texto(_porcentaje(delta, true), 12, color, 700)
	delta_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(delta_lbl)
	return h


# ----------------------------------------------------------------------------
# Diálogo de cantidad
# ----------------------------------------------------------------------------

func _construir_dialogo() -> void:
	_dlg_win = Window.new()
	_dlg_win.title = "Invertir en bolsa"
	_dlg_win.exclusive = true
	_dlg_win.size = Vector2i(540, 410)
	_dlg_win.close_requested.connect(func(): _dlg_win.visible = false)
	add_child(_dlg_win)

	var panel := Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Estilos_UI.SUPERFICIE, 10, Estilos_UI.BORDE, 1, 2))
	_dlg_win.add_child(panel)

	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 18
	v.offset_right = -18
	v.offset_top = 16
	v.offset_bottom = -16
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)

	_dlg_titulo = Estilos_UI.titulo("Invertir en bolsa", 18, Estilos_UI.TINTA)
	v.add_child(_dlg_titulo)
	_dlg_desc = Estilos_UI.parrafo("", 13, Estilos_UI.TINTA_SUAVE)
	v.add_child(_dlg_desc)

	_dlg_input = LineEdit.new()
	_dlg_input.custom_minimum_size = Vector2(0, 52)
	_dlg_input.placeholder_text = "Cantidad en €"
	_dlg_input.max_length = 12
	_dlg_input.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER_DECIMAL
	_dlg_input.add_theme_font_override("font", Estilos_UI.fuente_ui(700))
	_dlg_input.add_theme_font_size_override("font_size", 18)
	_dlg_input.add_theme_color_override("font_color", Estilos_UI.TINTA)
	_dlg_input.add_theme_color_override("font_placeholder_color", Estilos_UI.TINTA_FANTASMA)
	_dlg_input.add_theme_stylebox_override("normal",
		Estilos_UI.caja(Estilos_UI.SUPERFICIE_2, 8, Estilos_UI.BORDE_FUERTE, 1, 0))
	_dlg_input.add_theme_stylebox_override("focus",
		Estilos_UI.caja(Estilos_UI.SUPERFICIE, 8, Estilos_UI.AZUL, 2, 0))
	_dlg_input.text_submitted.connect(func(_t): _confirmar_dialogo())
	v.add_child(_dlg_input)

	var rapidos := HBoxContainer.new()
	rapidos.add_theme_constant_override("separation", 6)
	v.add_child(rapidos)
	for info in [[0.25, "25 %"], [0.5, "50 %"], [0.75, "75 %"], [1.0, "Todo"]]:
		var b := Estilos_UI.boton(str(info[1]), "chip", "", Estilos_UI.AZUL, 34)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 12)
		b.pressed.connect(_poner_cantidad_rapida.bind(float(info[0])))
		rapidos.add_child(b)

	_dlg_nota = Estilos_UI.parrafo("", 11, Estilos_UI.TINTA_FANTASMA)
	v.add_child(_dlg_nota)
	_dlg_error = Estilos_UI.parrafo("", 11, Estilos_UI.PELIGRO)
	_dlg_error.visible = false
	v.add_child(_dlg_error)

	var acciones := HBoxContainer.new()
	acciones.add_theme_constant_override("separation", 10)
	v.add_child(acciones)
	_dlg_confirmar = Estilos_UI.boton("Invertir", "primario", "", Estilos_UI.AZUL, 48)
	_dlg_confirmar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dlg_confirmar.pressed.connect(_confirmar_dialogo)
	acciones.add_child(_dlg_confirmar)
	var cancelar := Estilos_UI.boton("Cancelar", "secundario", "", Estilos_UI.PRIMARIO, 48)
	cancelar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancelar.pressed.connect(func(): _dlg_win.visible = false)
	acciones.add_child(cancelar)


func _mostrar_dialogo(modo: String) -> void:
	_dlg_modo = modo
	var activa := Sistema_Bolsa.Esta_Activa()
	if modo == "retirar":
		_dlg_maximo = float(Variables_Dinamicas.Valor_Inversion) if activa else 0.0
		_dlg_win.title = "Retirar inversión"
		_dlg_titulo.text = "Retirar inversión"
		_dlg_desc.text = "Puedes retirar hasta %s. Tu posición vale %s." % [
			_moneda(_dlg_maximo), _moneda(float(Variables_Dinamicas.Valor_Inversion))]
		_dlg_nota.text = "La retirada es inmediata y sin comisiones. Si retiras todo, cerrarás la posición."
		_dlg_confirmar.text = "Retirar"
		Estilos_UI.aplicar_estilo_boton(_dlg_confirmar, "primario", Estilos_UI.PELIGRO, "hand-coins")
	else:
		_dlg_maximo = float(Variables_Dinamicas.Dinero)
		if modo == "aportar" and activa:
			_dlg_win.title = "Aportar a la inversión"
			_dlg_titulo.text = "Aportar a la inversión"
			_dlg_desc.text = "Tienes %s. El aporte se suma a la posición actual (%s)." % [
				_moneda(_dlg_maximo), _moneda(float(Variables_Dinamicas.Valor_Inversion))]
		else:
			_dlg_win.title = "Invertir en bolsa"
			_dlg_titulo.text = "Invertir en bolsa"
			_dlg_desc.text = "Tienes %s. ¿Cuánto quieres invertir?" % _moneda(_dlg_maximo)
		var mental := int(Variables_Dinamicas.Necesidades_Basicas[1])
		_dlg_nota.text = "La salud mental actual (%d/100) fija el sesgo de esta inversión." % mental
		_dlg_confirmar.text = "Invertir"
		Estilos_UI.aplicar_estilo_boton(_dlg_confirmar, "primario", Estilos_UI.AZUL, "trending-up")

	if int(Variables_Estaticas.Habilidades[6]) < int(Sistema_Bolsa.SANGRE_FRIA_MINIMA) \
			and (modo != "retirar"):
		_dlg_nota.text = "Sangre fría baja: si la posición pierde más del 15 %, se venderá automáticamente."

	_dlg_error.visible = false
	_dlg_error.text = ""
	_dlg_input.text = ""
	_dlg_confirmar.disabled = _dlg_maximo <= 0.0
	if _dlg_maximo <= 0.0:
		_dlg_error.text = "No tienes efectivo disponible." if modo != "retirar" else "No hay ninguna inversión activa."
		_dlg_error.visible = true
	Estilos_UI.estilizar_ventana(_dlg_win)
	_dlg_win.popup_centered()
	_dlg_input.grab_focus.call_deferred()


func _poner_cantidad_rapida(fraccion: float) -> void:
	if _dlg_maximo <= 0.0:
		return
	var cantidad := _dlg_maximo * fraccion
	if fraccion >= 1.0:
		cantidad = _dlg_maximo
	_dlg_input.text = _numero_editable(cantidad)
	_dlg_input.caret_column = _dlg_input.text.length()


func _confirmar_dialogo() -> void:
	var texto := _dlg_input.text.strip_edges().replace(",", ".")
	if texto.is_empty():
		_error_dialogo("Escribe una cantidad.")
		return
	if not texto.is_valid_float():
		_error_dialogo("La cantidad no es válida.")
		return
	var cantidad := float(texto)
	if cantidad <= 0.0:
		_error_dialogo("La cantidad debe ser mayor que 0 €.")
		return
	if cantidad > _dlg_maximo + 0.005:
		_error_dialogo("El máximo disponible es %s." % _moneda(_dlg_maximo))
		return

	var resultado: Dictionary
	if _dlg_modo == "retirar":
		resultado = Sistema_Bolsa.Retirar(cantidad, "manual")
	else:
		resultado = Sistema_Bolsa.Invertir(cantidad)
	if not bool(resultado.get("ok", false)):
		_error_dialogo(str(resultado.get("mensaje", "No se pudo completar la operación.")))
		return

	_dlg_win.visible = false
	Guardar_Variables_Dinamicas.save_game()
	_firma_stats = ""
	_firma_ops = ""
	_firma_eventos = ""
	_refrescar(true)
	dinero_cambiado.emit()


func _error_dialogo(mensaje: String) -> void:
	_dlg_error.text = mensaje
	_dlg_error.visible = true


# ----------------------------------------------------------------------------
# Navegación y utilidades
# ----------------------------------------------------------------------------

func _seleccionar_tab(tab: String, forzar: bool) -> void:
	if not TABS.has(tab):
		tab = "resumen"
	_tab_activa = tab
	for clave in _contenidos.keys():
		_contenidos[clave].visible = str(clave) == tab
	for clave in _tabs_botones.keys():
		var b: Button = _tabs_botones[clave]
		var activo := str(clave) == tab
		Estilos_UI.aplicar_estilo_boton(b, "primario" if activo else "chip", Estilos_UI.AZUL)
		b.add_theme_font_size_override("font_size", 13)
	if forzar:
		_scroll.scroll_vertical = 0
		_refrescar(true)


func _cambiar_periodo(anios: int) -> void:
	_periodo_anios = anios
	_actualizar_evolucion()
	_actualizar_botones_periodo()


func _actualizar_pill(pill: PanelContainer, texto_pill: String,
		fondo: Color, color_texto: Color) -> void:
	if pill == null:
		return
	var st := Estilos_UI.caja(fondo, 999, Color(color_texto, 0.18), 1, 0)
	st.content_margin_left = 10
	st.content_margin_right = 10
	st.content_margin_top = 4
	st.content_margin_bottom = 4
	pill.add_theme_stylebox_override("panel", st)
	if pill.get_child_count() > 0 and pill.get_child(0) is Label:
		var lbl := pill.get_child(0) as Label
		lbl.text = texto_pill
		lbl.add_theme_color_override("font_color", color_texto)


func _crear_pill(texto_pill: String, fondo: Color, color_texto: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := Estilos_UI.caja(fondo, 999, Color(color_texto, 0.18), 1, 0)
	st.content_margin_left = 10
	st.content_margin_right = 10
	st.content_margin_top = 4
	st.content_margin_bottom = 4
	p.add_theme_stylebox_override("panel", st)
	var lbl := Estilos_UI.texto(texto_pill, 11, color_texto, 700)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(lbl)
	return p


func _aplicar_barra(barra: ProgressBar, valor: float, color: Color) -> void:
	if barra == null or not is_instance_valid(barra):
		return
	barra.add_theme_stylebox_override("fill", Estilos_UI.barra_relleno(color))
	barra.value = clampf(valor, barra.min_value, barra.max_value)


func _set_stat(clave: String, valor: String, color: Color) -> void:
	if not _stats_labels.has(clave):
		return
	var lbl: Label = _stats_labels[clave]
	lbl.text = valor
	lbl.add_theme_color_override("font_color", color)


func _limpiar(contenedor: Node) -> void:
	for hijo in contenedor.get_children():
		contenedor.remove_child(hijo)
		hijo.queue_free()


func _color_estado(nombre: String) -> Color:
	match nombre:
		"exito":
			return Estilos_UI.EXITO
		"peligro":
			return Estilos_UI.PELIGRO
		_:
			return Estilos_UI.AVISO


func _moneda(valor: float) -> String:
	var negativo := valor < -0.005
	var entero := int(round(absf(valor)))
	return ("-" if negativo else "") + _separar_miles(entero) + " €"


func _moneda_firmada(valor: float) -> String:
	if absf(valor) < 0.005:
		return "0 €"
	return ("+" if valor > 0.0 else "−") + _separar_miles(int(round(absf(valor)))) + " €"


func _porcentaje(valor: float, con_signo: bool = false) -> String:
	if con_signo:
		return ("+" if valor >= 0.0 else "−") + "%.1f %%" % absf(valor)
	return "%.1f %%" % valor


func _separar_miles(numero: int) -> String:
	var texto := str(numero)
	var resultado := ""
	var contador := 0
	for i in range(texto.length() - 1, -1, -1):
		resultado = texto[i] + resultado
		contador += 1
		if contador % 3 == 0 and i > 0:
			resultado = "." + resultado
	return resultado


func _numero_editable(valor: float) -> String:
	if absf(valor - round(valor)) < 0.005:
		return str(int(round(valor)))
	return "%.2f" % valor
