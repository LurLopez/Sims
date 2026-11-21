extends Control

# ============================================================================
# Minijuego de Cocina de gestión de pedidos.
# Mapa de Niveles + Mejoras en vertical (720x1280) y cocina jugable en
# horizontal (1280x720) con pantalla de carga, ARRASTRAR Y SOLTAR sobre los
# sprites PNG del pack (Imagenes/Minijuego_Cocina) y Modal de Resultados.
# Mantiene el reloj del Sim corriendo en segundo plano.
# ============================================================================

signal cerrado()

const ArteCocina := preload("res://Scripts/GUI/Minijuego_Cocina/Arte_Cocina.gd")
const ArrastreCocina := preload("res://Scripts/GUI/Minijuego_Cocina/Arrastre_Cocina.gd")
const SonidosCocina := preload("res://Scripts/GUI/Minijuego_Cocina/Sonidos_Cocina.gd")
const MejorasCocina := preload("res://Scripts/GUI/Minijuego_Cocina/Mejoras_Cocina.gd")
const SelectorArte := preload("res://Scripts/GUI/Minijuego_Cocina/Selector_Niveles_Arte.gd")

const TAMANO_HORIZONTAL := Vector2i(1280, 720)
const TAMANO_VERTICAL := Vector2i(720, 1280)
const ALTO_TOP_MAPA: float = 104.0
const MARGEN_MAPA: float = 16.0
const MARGEN_PANEL_MAPA: float = 22.0
const ALTO_FILA_MUNDO: float = 124.0
const SEPARACION_MUNDOS: int = 16
const ALTO_TABLERO_NIVELES: float = 900.0
const DURACION_CARGA_NIVEL: float = 1.9
const RETARDO_CARGA_NIVEL: float = 0.35
const VENTANA_COMBO_SEG: float = 2.5
const TIEMPO_BASE_CARNE: float = 4.0
const TIEMPO_BASE_PATATAS: float = 3.6

# Reparto del escenario horizontal (coordenadas locales de Vista_Cocina)
const CENTROS_CLIENTES: Array[float] = [402.0, 636.0, 870.0, 1104.0]
const Y_BASE_CLIENTE: float = 440.0
const ZONA_PLANCHA := Rect2(10.0, 420.0, 246.0, 178.0)
const ZONA_FREIDORA := Rect2(262.0, 420.0, 160.0, 178.0)
const ZONA_REFRESCOS := Rect2(428.0, 420.0, 180.0, 178.0)
const ZONA_PLATOS := Rect2(616.0, 420.0, 400.0, 178.0)
const ZONA_PAPELERA := Rect2(1022.0, 420.0, 94.0, 178.0)
const ZONA_PROPINAS := Rect2(1122.0, 420.0, 150.0, 178.0)
const ZONA_DESPENSA := Rect2(0.0, 620.0, 1280.0, 100.0)
# El pase muestra siempre cuatro huecos, aunque al principio solo dos estén
# desbloqueados con la mejora de Emplatado y Bebidas. Los cerrados se dibujan
# con candado para que la progresión se lea de un vistazo.
const HUECOS_EMPLATADO: int = 4
# Puestos de ingredientes integrados en el mueble bajo la encimera. Cada
# rectángulo es el contenedor completo (incluida su placa grabada) y sirve
# tanto de zona de arrastre como de fuente del toque rápido.
const PUESTOS_INGREDIENTES: Dictionary = {
	"pan": Rect2(598.0, 620.0, 286.0, 98.0),
	"carne": Rect2(22.0, 620.0, 178.0, 98.0),
	"queso": Rect2(1130.0, 620.0, 126.0, 98.0),
	"lechuga": Rect2(892.0, 620.0, 106.0, 98.0),
	"tomate": Rect2(1004.0, 620.0, 120.0, 98.0),
	"patatas": Rect2(216.0, 620.0, 132.0, 98.0),
}
const ORDEN_PUESTOS_INGREDIENTES: Array[String] = [
	"pan", "carne", "queso", "lechuga", "tomate", "patatas"
]

# Estado de navegación y orientación
var _orientacion_aplicada: bool = false
var _restaurante_actual: String = Sistema_Cocina.RESTAURANTE_BURGER
var _restaurante_expandido: String = ""
var _nivel_seleccionado: int = 1

# Subvistas y modales principales
var _vista_mapa: Control
var _vista_cocina: Control
var _vista_carga: Control
var _modal_inicio: Control
var _modal_mejoras: Control
var _modal_resultados: Control
var _modal_salida: Control
var _modal_pausa: Control
var _lbl_salida_resumen: Label
var _lbl_pausa_resumen: Label
var _pausado_por_confirmacion: bool = false
var _quit_on_go_back_previo: bool = true
var _capa_feedback: Control

# Referencias UI — Pantalla de carga (horizontal)
var _barra_carga: ProgressBar
var _lbl_carga_pct: Label
var _lbl_carga_paso: Label
var _lbl_carga_titulo: Label
var _lbl_carga_sub: Label
var _tween_carga: Tween
var _carga_activa: bool = false
var _nivel_en_carga: int = -1

# Referencias UI — Cabecera y selector de restaurantes del mapa (vertical)
var _top_mapa: Panel
var _htop_mapa: HBoxContainer
var _htop_mapa2: HBoxContainer

# Referencias UI — Mapa
var _lbl_mapa_titulo: Label
var _lbl_mapa_rango: Label
var _pill_mapa_turno: PanelContainer
var _lbl_mapa_fondos: Label
var _lbl_mapa_dinero: Label
var _btn_mapa_mejoras: Button
var _lista_restaurantes: VBoxContainer
var _contenedor_niveles: Control
var _fondo_mapa: Control
var _marco_mapa: Control
var _lbl_titulo_panel: Control
var _btn_mapa_atras: Control
var _btn_mapa_siguiente: Control
var _lbl_mapa_pie: Label
var _grid_niveles: GridContainer
var _centro_niveles: CenterContainer
var _barra_scroll_niveles: Control
var _decor_mundos_chef: TextureRect
var _vbox_modal_inicio: VBoxContainer
var _vbox_modal_resultados: VBoxContainer
var _card_resultados: PanelContainer

# Referencias UI — HUD Cocina
var _lbl_cocina_nivel: Label
var _lbl_cocina_reloj: Label
var _lbl_cocina_clientes: Label
var _lbl_cocina_recaudacion: Label
var _bar_cocina_meta: ProgressBar
var _estrellas_hud: Array[TextureRect] = []
var _pill_cocina_combo: PanelContainer
var _lbl_cocina_combo: Label
var _bar_cocina_combo: ProgressBar
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
var _bandeja_emplatado: ArteCocina.Bandeja_Emplatado
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
var _sfx: Sonidos_Cocina
var _efectos: ArteCocina.Capa_Efectos
var _fx_plancha: Array[float] = []
var _fx_freidora: Array[float] = []
var _fx_bebidas: Array[float] = []
var _estrellas_alcanzadas: int = 0
var _origen_vista: Vector2 = Vector2.ZERO
var _shake_t: float = 0.0
var _shake_duracion: float = 0.25
var _shake_fuerza: float = 0.0
var _ultimo_aviso_quemado: float = -10.0
var _rng := RandomNumberGenerator.new()
var _tutorial_foco: ArteCocina.Tutorial_Foco
var _tutorial_panel: PanelContainer
var _tutorial_label: Label
var _tutorial_timer: float = 0.0

# Estado de partida activa
var _jugando: bool = false
var _nivel_actual: int = 1
var _en_turno_partida: bool = false
var _modo_practica_partida: bool = false
var _cfg_nivel_actual: Dictionary = {}
var _tiempo_servicio: float = 0.0
var _clientes_totales: int = 0
var _clientes_pendientes: int = 0
var _recaudacion: int = 0
var _propinas_servicio: int = 0
var _desperdicio_valor: int = 0
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
	_Aplicar_Orientacion_Vertical()
	# En Android, el botón atrás lo gestiona el minijuego (confirmación de
	# salida, cierre de modales, etc.) en vez de cerrar la app de golpe.
	if get_tree() != null:
		_quit_on_go_back_previo = get_tree().is_quit_on_go_back()
		get_tree().set_quit_on_go_back(false)
	Musica.Reproducir_Minijuego()
	_sfx = SonidosCocina.new()
	_sfx.name = "SFX_Cocina"
	add_child(_sfx)
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

	# El mapa de niveles vive en vertical (720x1280) y ocupa todo el viewport.
	if _vista_mapa != null and is_instance_valid(_vista_mapa):
		_vista_mapa.position = Vector2.ZERO
		_vista_mapa.size = Vector2(maxf(float(TAMANO_VERTICAL.x), tam.x), maxf(float(TAMANO_VERTICAL.y), tam.y))
		_Ajustar_Disposicion_Mapa()

	# La cocina y la pantalla de carga viven en horizontal (1280x720) y se centran.
	var ox: float = maxf(0.0, (tam.x - 1280.0) * 0.5)
	var oy: float = maxf(0.0, (tam.y - 720.0) * 0.5)
	_origen_vista = Vector2(ox, oy)
	for nodo in [_vista_cocina, _vista_carga]:
		if nodo != null and is_instance_valid(nodo):
			nodo.position = _origen_vista
			nodo.size = Vector2(1280, 720)


func _Ajustar_Disposicion_Mapa() -> void:
	if _vista_mapa == null or not is_instance_valid(_vista_mapa):
		return
	if _top_mapa == null or not is_instance_valid(_top_mapa):
		return
	var ancho: float = maxf(float(TAMANO_VERTICAL.x), _vista_mapa.size.x)
	var alto: float = maxf(float(TAMANO_VERTICAL.y), _vista_mapa.size.y)
	var ancho_util: float = ancho - MARGEN_MAPA * 2.0

	_top_mapa.size = Vector2(ancho, ALTO_TOP_MAPA)
	_htop_mapa.position = Vector2(MARGEN_MAPA, 8)
	_htop_mapa.size = Vector2(ancho_util, 40)
	_htop_mapa2.position = Vector2(MARGEN_MAPA, 54)
	_htop_mapa2.size = Vector2(ancho_util, 44)

	# Panel único celeste que contiene tanto el selector de mundos como el
	# tablero de niveles; ambos comparten marco, título y botonera inferior.
	var panel_y: float = ALTO_TOP_MAPA + 10.0
	var panel_w: float = ancho - MARGEN_PANEL_MAPA * 2.0
	var panel_h: float = maxf(620.0, alto - panel_y - MARGEN_PANEL_MAPA)
	_marco_mapa.position = Vector2(MARGEN_PANEL_MAPA, panel_y)
	_marco_mapa.size = Vector2(panel_w, panel_h)

	_lbl_titulo_panel.position = Vector2(22.0, 2.0)
	_lbl_titulo_panel.size = Vector2(panel_w - 44.0, 70.0)
	_btn_mapa_atras.position = Vector2(24.0, panel_h - 72.0)
	_btn_mapa_atras.size = Vector2(160.0, 56.0)
	_btn_mapa_siguiente.position = Vector2(panel_w - 92.0, panel_h - 78.0)
	_btn_mapa_siguiente.size = Vector2(62.0, 62.0)
	_lbl_mapa_pie.position = Vector2(190.0, panel_h - 64.0)
	_lbl_mapa_pie.size = Vector2(maxf(80.0, panel_w - 380.0), 40.0)

	var tab: Rect2 = _marco_mapa.rect_tablero()
	var area: Rect2 = Rect2(tab.position + Vector2(10.0, 10.0),
		tab.size - Vector2(20.0, 20.0))
	_contenedor_niveles.position = area.position
	_contenedor_niveles.size = area.size
	if _centro_niveles != null and is_instance_valid(_centro_niveles):
		_centro_niveles.custom_minimum_size = Vector2(
			maxf(0.0, area.size.x - 28.0),
			maxf(0.0, area.size.y - 20.0))
	if _grid_niveles != null and is_instance_valid(_grid_niveles):
		_grid_niveles.custom_minimum_size = Vector2(
			maxf(0.0, area.size.x - 42.0), ALTO_TABLERO_NIVELES)

	# Selector de mundos y mapa de niveles son vistas excluyentes.
	var expandido: bool = _restaurante_expandido != ""
	_lista_restaurantes.visible = not expandido
	_contenedor_niveles.visible = expandido
	_btn_mapa_siguiente.visible = expandido

	var alto_lista: float = ALTO_FILA_MUNDO * float(Sistema_Cocina.ORDEN_RESTAURANTES.size()) \
		+ float(SEPARACION_MUNDOS) * float(maxi(0, Sistema_Cocina.ORDEN_RESTAURANTES.size() - 1))
	var mostrar_chef: bool = not expandido and tab.size.y >= 760.0
	if mostrar_chef:
		var alto_chef: float = 300.0
		var total: float = alto_lista + 24.0 + alto_chef
		var y0: float = tab.position.y + maxf(24.0, (tab.size.y - total) * 0.5)
		_lista_restaurantes.position = Vector2(tab.position.x + 28.0, y0)
		_lista_restaurantes.size = Vector2(tab.size.x - 56.0, alto_lista)
		_decor_mundos_chef.position = Vector2(
			tab.position.x + (tab.size.x - 300.0) * 0.5,
			y0 + alto_lista + 24.0)
		_decor_mundos_chef.size = Vector2(300.0, alto_chef)
	else:
		_lista_restaurantes.position = Vector2(tab.position.x + 28.0,
			tab.position.y + maxf(24.0, (tab.size.y - alto_lista) * 0.5))
		_lista_restaurantes.size = Vector2(tab.size.x - 56.0, alto_lista)
	_decor_mundos_chef.visible = mostrar_chef


func _exit_tree() -> void:
	if get_tree() != null:
		get_tree().set_quit_on_go_back(_quit_on_go_back_previo)
	Musica.Reproducir_General()
	_Cancelar_Carga()
	if _orientacion_aplicada:
		_Aplicar_Orientacion_Vertical()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_Volver_Atras()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_Volver_Atras()


func _Volver_Atras() -> void:
	# Botón atrás físico (Android) o Escape: nunca cierra la app de golpe.
	if _modal_pausa != null and _modal_pausa.visible:
		_Reanudar_Partida()
		return
	if _modal_salida != null and _modal_salida.visible:
		_Cancelar_Salida_Partida()
		return
	if _jugando or _pausado_por_confirmacion:
		_Abrir_Modal_Confirmar_Salida()
		return
	if _carga_activa:
		_Cancelar_Carga()
		_Mostrar_Mapa()
		return
	if _modal_inicio != null and _modal_inicio.visible:
		_modal_inicio.visible = false
		return
	if _modal_mejoras != null and _modal_mejoras.visible:
		if _modal_mejoras.has_method("cerrar"):
			_modal_mejoras.call("cerrar")
		else:
			_modal_mejoras.visible = false
			_Refrescar_Mapa()
		return
	if _modal_resultados != null and _modal_resultados.visible:
		_Mostrar_Mapa()
		return
	if _vista_mapa != null and _vista_mapa.visible:
		_Volver_Mapa()


func _Volver_Mapa() -> void:
	# Dentro de un mundo, "Volver" regresa al selector de mundos. En el
	# selector, vuelve al Sim.
	if _restaurante_expandido != "":
		_restaurante_expandido = ""
		_Refrescar_Mapa()
		return
	_Salir_Al_Sim()


func _Aplicar_Orientacion_Horizontal() -> void:
	_orientacion_aplicada = true
	if DisplayServer.get_name() in ["android", "ios"]:
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
	var win: Window = get_window()
	if win != null:
		win.content_scale_size = TAMANO_HORIZONTAL
	if OS.has_feature("pc") and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_size(TAMANO_HORIZONTAL)
		var pantalla_h := DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
		DisplayServer.window_set_position(Vector2i(
			maxi(0, (pantalla_h.x - TAMANO_HORIZONTAL.x) / 2),
			maxi(0, (pantalla_h.y - TAMANO_HORIZONTAL.y) / 2)))


func _Aplicar_Orientacion_Vertical() -> void:
	_orientacion_aplicada = false
	if DisplayServer.get_name() in ["android", "ios"]:
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	var win: Window = get_window()
	if win != null:
		win.content_scale_size = TAMANO_VERTICAL
	if OS.has_feature("pc") and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_size(TAMANO_VERTICAL)
		var pantalla_v := DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
		DisplayServer.window_set_position(Vector2i(
			maxi(0, (pantalla_v.x - TAMANO_VERTICAL.x) / 2),
			maxi(0, (pantalla_v.y - TAMANO_VERTICAL.y) / 2)))


func _Salir_Al_Sim() -> void:
	_jugando = false
	_Cancelar_Carga()
	_Aplicar_Orientacion_Vertical()
	cerrado.emit()


func _Cancelar_Carga() -> void:
	_carga_activa = false
	_nivel_en_carga = -1
	if _tween_carga != null:
		_tween_carga.kill()
		_tween_carga = null
	if _barra_carga != null and is_instance_valid(_barra_carga):
		_barra_carga.value = 0.0
	if _vista_carga != null and is_instance_valid(_vista_carga):
		_vista_carga.visible = false


# ============================================================================
# Construcción de escena (mapa vertical + cocina horizontal)
# ============================================================================

func _Construir_Raiz() -> void:
	var fondo := ColorRect.new()
	fondo.name = "Fondo_General"
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.color = Color("#0b1220")
	add_child(fondo)

	_Construir_Vista_Mapa()
	_Construir_Vista_Cocina()
	_Construir_Modal_Inicio()
	_Construir_Modal_Mejoras()
	_Construir_Modal_Resultados()
	_Construir_Modal_Confirmar_Salida()
	_Construir_Modal_Pausa()
	_Construir_Vista_Carga()

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
	_vista_mapa.size = Vector2(TAMANO_VERTICAL)
	add_child(_vista_mapa)

	_fondo_mapa = SelectorArte.Fondo_Mapa.new()
	_fondo_mapa.name = "Fondo_Mapa"
	_fondo_mapa.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vista_mapa.add_child(_fondo_mapa)

	_Construir_Barra_Mapa()
	_Construir_Panel_Mapa()


func _Construir_Barra_Mapa() -> void:
	# Cabecera compacta de dos filas: mundo/rango y economía/mejoras.
	_top_mapa = Panel.new()
	_top_mapa.name = "Mapa_Top_Bar"
	_top_mapa.position = Vector2.ZERO
	_top_mapa.size = Vector2(TAMANO_VERTICAL.x, ALTO_TOP_MAPA)
	var st_top := StyleBoxFlat.new()
	st_top.bg_color = Color(0.035, 0.095, 0.18, 0.94)
	st_top.corner_radius_bottom_left = 20
	st_top.corner_radius_bottom_right = 20
	st_top.border_width_bottom = 3
	st_top.border_color = SelectorArte.ORO
	st_top.anti_aliasing = true
	_top_mapa.add_theme_stylebox_override("panel", st_top)
	_vista_mapa.add_child(_top_mapa)

	_htop_mapa = HBoxContainer.new()
	_htop_mapa.position = Vector2(MARGEN_MAPA, 8)
	_htop_mapa.size = Vector2(TAMANO_VERTICAL.x - MARGEN_MAPA * 2.0, 40)
	_htop_mapa.add_theme_constant_override("separation", 10)
	_top_mapa.add_child(_htop_mapa)

	_htop_mapa.add_child(Estilos_UI.badge_icono("utensils", 38, 19,
		Color("#f97316"), Color.WHITE, 999))

	_lbl_mapa_titulo = Estilos_UI.titulo("Cocina · Mundos", 21, Color.WHITE)
	_lbl_mapa_titulo.add_theme_font_override("font", SelectorArte.FUENTE_CARTOON)
	_lbl_mapa_titulo.add_theme_font_size_override("font_size", 21)
	_lbl_mapa_titulo.add_theme_color_override("font_outline_color", SelectorArte.NAVY_OSCURO)
	_lbl_mapa_titulo.add_theme_constant_override("outline_size", 6)
	_lbl_mapa_titulo.clip_text = true
	_lbl_mapa_titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_htop_mapa.add_child(_lbl_mapa_titulo)

	var pill_rango := PanelContainer.new()
	pill_rango.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pill_rango.add_theme_stylebox_override("panel",
		SelectorArte.estilo_pildora(Color("#0c203b"), Color("#f6b93b"), 999, 2))
	var h_rango := HBoxContainer.new()
	h_rango.add_theme_constant_override("separation", 5)
	h_rango.add_child(_Icono_Mapa(SelectorArte.TEX_ESTRELLA, 15.0))
	_lbl_mapa_rango = Estilos_UI.texto("Rango 0/9", 12, Color("#ffe98a"), 700)
	h_rango.add_child(_lbl_mapa_rango)
	pill_rango.add_child(h_rango)
	_htop_mapa.add_child(pill_rango)

	_htop_mapa2 = HBoxContainer.new()
	_htop_mapa2.position = Vector2(MARGEN_MAPA, 54)
	_htop_mapa2.size = Vector2(TAMANO_VERTICAL.x - MARGEN_MAPA * 2.0, 44)
	_htop_mapa2.add_theme_constant_override("separation", 8)
	_top_mapa.add_child(_htop_mapa2)

	_lbl_mapa_fondos = Estilos_UI.texto("Caja 0 €", 13, Color("#6b3a00"), 700)
	_htop_mapa2.add_child(_Crear_Pildora_Mapa(
		_Icono_Mapa(ArteCocina.TEX_MONEDA, 19.0),
		_lbl_mapa_fondos, Color("#fff1b8"), Color("#a86200")))

	_lbl_mapa_dinero = Estilos_UI.texto("0 €", 13, Color("#14532d"), 700)
	_htop_mapa2.add_child(_Crear_Pildora_Mapa(
		Estilos_UI.icono_rect("euro", 15, Color("#157936")),
		_lbl_mapa_dinero, Color("#dcfce7"), Color("#16803c")))

	_pill_mapa_turno = Estilos_UI.pill_estado("EN TURNO",
		Color("#fef3c7"), Color("#92400e"))
	_pill_mapa_turno.visible = false
	_htop_mapa2.add_child(_pill_mapa_turno)

	var esp := Control.new()
	esp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	esp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_htop_mapa2.add_child(esp)

	_btn_mapa_mejoras = Button.new()
	_btn_mapa_mejoras.name = "Boton_Mejoras_Mapa"
	_btn_mapa_mejoras.text = "Mejoras"
	_btn_mapa_mejoras.custom_minimum_size = Vector2(136, 42)
	_btn_mapa_mejoras.icon = Estilos_UI.icono("chef-hat")
	_btn_mapa_mejoras.expand_icon = false
	SelectorArte.aplicar_estilos_boton(_btn_mapa_mejoras,
		SelectorArte.estilo_boton_oro(14))
	_btn_mapa_mejoras.pressed.connect(_Abrir_Modal_Mejoras)
	_htop_mapa2.add_child(_btn_mapa_mejoras)


func _Crear_Pildora_Mapa(icono: Control, etiqueta: Label,
		fondo: Color, borde: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.add_theme_stylebox_override("panel",
		SelectorArte.estilo_pildora(fondo, borde, 999, 2))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.add_child(icono)
	h.add_child(etiqueta)
	p.add_child(h)
	return p


func _Icono_Mapa(tex: Texture2D, tam: float, mod: Color = Color.WHITE) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = tex
	tr.custom_minimum_size = Vector2(tam, tam)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.self_modulate = mod
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


func _Construir_Panel_Mapa() -> void:
	# Marco celeste con tablero azul: el mismo contenedor sirve para elegir un
	# mundo y para escoger uno de sus 15 niveles.
	_marco_mapa = SelectorArte.Marco_Mapa.new()
	_marco_mapa.name = "Marco_Selector_Niveles"
	_marco_mapa.position = Vector2(MARGEN_PANEL_MAPA, ALTO_TOP_MAPA + 10.0)
	_marco_mapa.size = Vector2(
		TAMANO_VERTICAL.x - MARGEN_PANEL_MAPA * 2.0,
		TAMANO_VERTICAL.y - ALTO_TOP_MAPA - 24.0)
	_vista_mapa.add_child(_marco_mapa)

	_lbl_titulo_panel = SelectorArte.Titulo_Dorado.new()
	_lbl_titulo_panel.name = "Titulo_Selector"
	_lbl_titulo_panel.configurar("SELECCIONA UN NIVEL", 38)
	_marco_mapa.add_child(_lbl_titulo_panel)

	_btn_mapa_atras = SelectorArte.Boton_Atras.new()
	_btn_mapa_atras.name = "Boton_Atras_Mapa"
	_btn_mapa_atras.tooltip_text = "Volver"
	_btn_mapa_atras.pressed.connect(_Volver_Mapa)
	_marco_mapa.add_child(_btn_mapa_atras)

	_btn_mapa_siguiente = SelectorArte.Boton_Siguiente.new()
	_btn_mapa_siguiente.name = "Boton_Siguiente_Mapa"
	_btn_mapa_siguiente.tooltip_text = "Jugar el siguiente nivel"
	_btn_mapa_siguiente.pressed.connect(_Abrir_Siguiente_Nivel)
	_marco_mapa.add_child(_btn_mapa_siguiente)

	_lbl_mapa_pie = Estilos_UI.texto("", 14, Color("#e8fbff"), 700)
	_lbl_mapa_pie.name = "Pie_Selector"
	_lbl_mapa_pie.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_mapa_pie.add_theme_color_override("font_outline_color", Color("#0b4a72"))
	_lbl_mapa_pie.add_theme_constant_override("outline_size", 4)
	_lbl_mapa_pie.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_marco_mapa.add_child(_lbl_mapa_pie)

	_lista_restaurantes = VBoxContainer.new()
	_lista_restaurantes.name = "Selector_Restaurantes"
	_lista_restaurantes.add_theme_constant_override("separation", SEPARACION_MUNDOS)
	_marco_mapa.add_child(_lista_restaurantes)

	_decor_mundos_chef = TextureRect.new()
	_decor_mundos_chef.name = "Chef_Selector_Mundos"
	_decor_mundos_chef.texture = ArteCocina.textura_chef("pulgar")
	_decor_mundos_chef.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_decor_mundos_chef.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_decor_mundos_chef.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_marco_mapa.add_child(_decor_mundos_chef)

	_contenedor_niveles = Control.new()
	_contenedor_niveles.name = "Contenedor_Niveles"
	_contenedor_niveles.visible = false
	_marco_mapa.add_child(_contenedor_niveles)


func _Abrir_Siguiente_Nivel() -> void:
	if _restaurante_expandido == "":
		return
	var rest: Dictionary = Sistema_Cocina.Obtener_Restaurante(_restaurante_expandido)
	if not bool(rest.get("implementado", false)):
		return
	var niveles: Array = rest.get("niveles", [])
	var objetivo: int = 0
	var ultimo_desbloqueado: int = 1
	for n in range(1, niveles.size() + 1):
		if not Sistema_Cocina.Esta_Nivel_Desbloqueado(_restaurante_expandido, n):
			break
		ultimo_desbloqueado = n
		if objetivo == 0 \
				and Sistema_Cocina.Obtener_Estrellas_Nivel(_restaurante_expandido, n) < 3:
			objetivo = n
	# Si todo está a 3 estrellas, repite el último nivel disponible.
	if objetivo == 0:
		objetivo = ultimo_desbloqueado
	_sfx.reproducir("click", -18.0)
	_Abrir_Modal_Inicio(objetivo)


func _Mostrar_Mapa() -> void:
	_jugando = false
	_pausado_por_confirmacion = false
	_Cancelar_Carga()
	_Aplicar_Orientacion_Vertical()
	if _arrastre != null:
		_arrastre.cancelar()
		_arrastre.habilitado = false
	_Ocultar_Tutorial()
	if _chef_root != null:
		_chef_root.visible = false
	_vista_mapa.visible = true
	_vista_cocina.visible = false
	_modal_inicio.visible = false
	_modal_mejoras.visible = false
	_modal_resultados.visible = false
	if _modal_salida != null:
		_modal_salida.visible = false
	if _modal_pausa != null:
		_modal_pausa.visible = false
	_Centrar_Contenido()
	_Refrescar_Mapa()


func _Refrescar_Mapa() -> void:
	var rango: int = Sistema_Cocina.Obtener_Rango_Logro()
	var info_rango: Dictionary = Sistema_Cocina.Obtener_Info_Rango(rango)
	_lbl_mapa_rango.text = "Rango %d/9" % rango
	_lbl_mapa_fondos.text = "Caja %d €" % Sistema_Cocina.Obtener_Caja_Restaurante()
	_lbl_mapa_dinero.text = "%d €" % int(Variables_Dinamicas.Dinero)
	_pill_mapa_turno.visible = Sistema_Cocina.Esta_En_Turno_Activo(_restaurante_actual)

	var rest_cfg: Dictionary = {}
	var rest_jugable: bool = false
	if _restaurante_expandido != "":
		rest_cfg = Sistema_Cocina.Obtener_Restaurante(_restaurante_expandido)
		rest_jugable = bool(rest_cfg.get("implementado", false)) \
			and Sistema_Cocina.Esta_Desbloqueado_Restaurante(_restaurante_expandido)

	var expandido: bool = _restaurante_expandido != ""
	_lbl_mapa_titulo.text = "Cocina · Mundos" if not expandido \
		else str(rest_cfg.get("nombre", "Niveles"))
	_lbl_titulo_panel.configurar(
		"SELECCIONA UN NIVEL" if expandido else "SELECCIONA UN MUNDO", 38)
	_btn_mapa_mejoras.disabled = not rest_jugable
	_Ajustar_Disposicion_Mapa()

	if expandido:
		_lbl_mapa_pie.text = "%d / 45 ★   ·   %d / 15 niveles" % [
			Sistema_Cocina.Contar_Estrellas_Totales(_restaurante_expandido),
			Sistema_Cocina.Contar_Niveles_Superados(_restaurante_expandido)]
	else:
		_lbl_mapa_pie.text = "Rango %d / 9 · %s" % [
			rango, str(info_rango.get("nombre", ""))]

	_Refrescar_Lista_Mundos()
	_Refrescar_Tablero_Niveles(rest_cfg, rest_jugable)


func _Refrescar_Lista_Mundos() -> void:
	for h in _lista_restaurantes.get_children():
		_lista_restaurantes.remove_child(h)
		h.queue_free()

	for rest_id in Sistema_Cocina.ORDEN_RESTAURANTES:
		var r: Dictionary = Sistema_Cocina.Obtener_Restaurante(rest_id)
		var desbl: bool = Sistema_Cocina.Esta_Desbloqueado_Restaurante(rest_id)
		var impl: bool = bool(r.get("implementado", false))
		var bloqueado: bool = not impl or not desbl
		var rest_actual: String = rest_id

		var btn := Button.new()
		btn.name = "Mundo_%s" % rest_id
		btn.text = ""
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0.0, ALTO_FILA_MUNDO)
		btn.disabled = bloqueado
		btn.mouse_default_cursor_shape = Control.CURSOR_ARROW if bloqueado \
			else Control.CURSOR_POINTING_HAND
		btn.add_theme_font_override("font", SelectorArte.FUENTE_CARTOON)

		var st_n := StyleBoxFlat.new()
		st_n.bg_color = Color("#dce8f1") if bloqueado else Color("#fff8e1")
		st_n.set_corner_radius_all(20)
		st_n.border_color = Color("#9ab4c8") if bloqueado else Color("#e0a020")
		st_n.set_border_width_all(2 if bloqueado else 3)
		st_n.border_width_bottom = 4 if bloqueado else 6
		st_n.anti_aliasing = true
		var st_h := st_n.duplicate() as StyleBoxFlat
		st_h.bg_color = Color("#e8f1f8") if bloqueado else Color("#fffdf2")
		st_h.border_color = Color("#b2c9da") if bloqueado else Color("#f4b53a")
		var st_p := st_n.duplicate() as StyleBoxFlat
		st_p.bg_color = Color("#d2e1ec") if bloqueado else Color("#ffe9a8")
		st_p.border_width_bottom = 3
		btn.add_theme_stylebox_override("normal", st_n)
		btn.add_theme_stylebox_override("hover", st_h)
		btn.add_theme_stylebox_override("pressed", st_p)
		btn.add_theme_stylebox_override("disabled", st_n)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		if not bloqueado:
			btn.pressed.connect(func():
				_restaurante_actual = rest_actual
				_restaurante_expandido = rest_actual
				_sfx.reproducir("click", -18.0)
				_Refrescar_Mapa())

		var m := MarginContainer.new()
		m.set_anchors_preset(Control.PRESET_FULL_RECT)
		m.add_theme_constant_override("margin_left", 18)
		m.add_theme_constant_override("margin_right", 16)
		m.add_theme_constant_override("margin_top", 12)
		m.add_theme_constant_override("margin_bottom", 12)
		m.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(m)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		m.add_child(row)

		var ic_nom: String = "lock" if bloqueado else "utensils"
		var ic_col: Color = Color("#8fa6b8") if bloqueado else Color("#f97316")
		row.add_child(Estilos_UI.badge_icono(ic_nom, 64, 30, ic_col, Color.WHITE, 999))

		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", 2)
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(col)

		var lbl_n := Estilos_UI.titulo(str(r.get("nombre", rest_id)), 21,
			Color("#173b63") if not bloqueado else Color("#6f8799"))
		lbl_n.add_theme_font_override("font", SelectorArte.FUENTE_CARTOON)
		lbl_n.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(lbl_n)

		var trabajo: String = str(r.get("trabajo_requerido", ""))
		var sub_txt: String
		if not impl:
			sub_txt = "%s · Próximamente en la Fase 2" % trabajo
		elif desbl:
			sub_txt = "%s · %d / 45 ★ · %d / 15 niveles" % [
				trabajo,
				Sistema_Cocina.Contar_Estrellas_Totales(rest_id),
				Sistema_Cocina.Contar_Niveles_Superados(rest_id)]
		else:
			sub_txt = "Requiere: %s" % trabajo
		var lbl_s := Estilos_UI.texto(sub_txt, 12,
			Color("#7a6234") if not bloqueado else Color("#7890a2"), 600)
		lbl_s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(lbl_s)

		if bloqueado:
			row.add_child(Estilos_UI.pill_estado("Fase 2",
				Color("#e4f1fa"), Color("#2b7aa6")))
		else:
			if Sistema_Cocina.Esta_En_Turno_Activo(rest_id):
				row.add_child(Estilos_UI.pill_estado("TURNO",
					Color("#fef3c7"), Color("#92400e")))
			var pill_prog := PanelContainer.new()
			pill_prog.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			var st_pill := SelectorArte.estilo_pildora(
				Color("#fff1b8"), Color("#a86200"), 999, 1)
			st_pill.content_margin_left = 8
			st_pill.content_margin_right = 9
			st_pill.content_margin_top = 2
			st_pill.content_margin_bottom = 3
			pill_prog.add_theme_stylebox_override("panel", st_pill)
			var h_prog := HBoxContainer.new()
			h_prog.add_theme_constant_override("separation", 4)
			h_prog.add_child(_Icono_Mapa(SelectorArte.TEX_ESTRELLA, 14.0))
			h_prog.add_child(Estilos_UI.texto("%d/45" %
				Sistema_Cocina.Contar_Estrellas_Totales(rest_id),
				12, Color("#6b3a00"), 700))
			pill_prog.add_child(h_prog)
			row.add_child(pill_prog)
			row.add_child(_Boton_Chevron_Mapa())

		_lista_restaurantes.add_child(btn)

	_lista_restaurantes.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_lista_restaurantes, "modulate:a", 1.0, 0.18)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _Boton_Chevron_Mapa() -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(34.0, 34.0)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := SelectorArte.estilo_pildora(Color("#ffd24a"), Color("#a86200"), 999, 2)
	st.content_margin_left = 0
	st.content_margin_right = 0
	st.content_margin_top = 0
	st.content_margin_bottom = 0
	p.add_theme_stylebox_override("panel", st)
	var c := CenterContainer.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(Estilos_UI.icono_rect("chevron-right", 18, Color("#6b3a00")))
	p.add_child(c)
	return p


func _Refrescar_Tablero_Niveles(rest_cfg: Dictionary, rest_jugable: bool) -> void:
	for c in _contenedor_niveles.get_children():
		_contenedor_niveles.remove_child(c)
		c.queue_free()
	_grid_niveles = null
	_centro_niveles = null
	_barra_scroll_niveles = null

	if _restaurante_expandido == "":
		return
	if not rest_jugable:
		_Construir_Tarjeta_Restaurante_No_Jugable(rest_cfg)
		return

	var scroll := ScrollContainer.new()
	scroll.name = "Scroll_Niveles"
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 28.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_contenedor_niveles.add_child(scroll)

	_centro_niveles = CenterContainer.new()
	_centro_niveles.name = "Centro_Niveles"
	_centro_niveles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_centro_niveles.custom_minimum_size = Vector2(
		maxf(0.0, _contenedor_niveles.size.x - 28.0),
		maxf(0.0, _contenedor_niveles.size.y - 20.0))
	scroll.add_child(_centro_niveles)

	var margen := MarginContainer.new()
	margen.name = "Margen_Niveles"
	margen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margen.add_theme_constant_override("margin_left", 4)
	margen.add_theme_constant_override("margin_right", 10)
	margen.add_theme_constant_override("margin_top", 10)
	margen.add_theme_constant_override("margin_bottom", 10)
	_centro_niveles.add_child(margen)

	_grid_niveles = GridContainer.new()
	_grid_niveles.name = "Grid_Niveles"
	_grid_niveles.columns = 3
	_grid_niveles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid_niveles.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_grid_niveles.add_theme_constant_override("h_separation", 12)
	_grid_niveles.add_theme_constant_override("v_separation", 12)
	_grid_niveles.custom_minimum_size = Vector2(
		maxf(0.0, _contenedor_niveles.size.x - 42.0), ALTO_TABLERO_NIVELES)
	margen.add_child(_grid_niveles)

	var niveles: Array = rest_cfg.get("niveles", [])
	for n_cfg in niveles:
		var num: int = int(n_cfg.get("nivel", 1))
		var desbl_n: bool = Sistema_Cocina.Esta_Nivel_Desbloqueado(
			_restaurante_expandido, num)
		var est: int = Sistema_Cocina.Obtener_Estrellas_Nivel(
			_restaurante_expandido, num)
		_grid_niveles.add_child(_Crear_Tarjeta_Nivel(num, n_cfg, desbl_n, est))

	_barra_scroll_niveles = SelectorArte.Barra_Scroll_Niveles.new()
	_barra_scroll_niveles.name = "Barra_Scroll_Niveles"
	_barra_scroll_niveles.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	_barra_scroll_niveles.offset_right = 18.0
	_barra_scroll_niveles.scroll = scroll
	_contenedor_niveles.add_child(_barra_scroll_niveles)

	_Animar_Revelado_Niveles()


func _Animar_Revelado_Niveles() -> void:
	if _contenedor_niveles == null or not is_instance_valid(_contenedor_niveles):
		return
	if _grid_niveles == null or not is_instance_valid(_grid_niveles):
		_contenedor_niveles.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(_contenedor_niveles, "modulate:a", 1.0, 0.20)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		return
	# Espera al layout para conocer el tamaño de cada moneda antes de animarla.
	await get_tree().process_frame
	if _grid_niveles == null or not is_instance_valid(_grid_niveles):
		return
	var i: int = 0
	for hijo in _grid_niveles.get_children():
		if not (hijo is Control) or not is_instance_valid(hijo):
			continue
		var c := hijo as Control
		c.pivot_offset = c.size * 0.5
		c.modulate.a = 0.0
		c.scale = Vector2(0.87, 0.87)
		var tw2 := c.create_tween().set_parallel(true)
		tw2.tween_property(c, "modulate:a", 1.0, 0.16)\
			.set_delay(0.022 * float(i))
		tw2.tween_property(c, "scale", Vector2.ONE, 0.26)\
			.set_delay(0.022 * float(i))\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		i += 1


func _Crear_Tarjeta_Nivel(num: int, _cfg: Dictionary, desbloqueado: bool,
		estrellas: int) -> BaseButton:
	var btn := SelectorArte.Boton_Nivel.new()
	btn.name = "Nivel_%d" % num
	btn.nivel = num
	btn.estrellas = estrellas
	btn.desbloqueado = desbloqueado
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0.0, 150.0)
	btn.disabled = not desbloqueado
	if desbloqueado:
		btn.pressed.connect(func():
			_sfx.reproducir("click", -18.0)
			_Abrir_Modal_Inicio(num))
	return btn


func _Construir_Tarjeta_Restaurante_No_Jugable(rest_cfg: Dictionary) -> void:
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_contenedor_niveles.add_child(centro)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(520, 320)
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
	card.custom_minimum_size = Vector2(660, 0)
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
	cab.add_child(Estilos_UI.pill_estado("%d clientes" % int(cfg.get("clientes", 10)), Estilos_UI.AZUL_SUAVE, Estilos_UI.AZUL))

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
		var l := Estilos_UI.texto("%s  %d €" % [info_m[0], info_m[1]], 15, Estilos_UI.TINTA, 700)
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
		var pill_plato := PanelContainer.new()
		var st_pl := Estilos_UI.caja(Color("#ffedd5"), 999, Color("#9a3412", 0.25), 1, 0)
		st_pl.content_margin_left = 6
		st_pl.content_margin_right = 10
		st_pl.content_margin_top = 2
		st_pl.content_margin_bottom = 2
		pill_plato.add_theme_stylebox_override("panel", st_pl)
		var fila_plato := HBoxContainer.new()
		fila_plato.add_theme_constant_override("separation", 4)
		var tex_plato: Texture2D = ArteCocina.TEX_HAMBURGUESA
		if str(plato_id) == "patatas":
			tex_plato = ArteCocina.TEX_PATATAS
		elif str(plato_id) == "refresco":
			tex_plato = ArteCocina.TEX_REFRESCO
		var ic_plato := TextureRect.new()
		ic_plato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic_plato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic_plato.texture = tex_plato
		ic_plato.custom_minimum_size = Vector2(24.0, 24.0)
		ic_plato.size = Vector2(24.0, 24.0)
		fila_plato.add_child(ic_plato)
		fila_plato.add_child(Estilos_UI.texto(nom, 12, Color("#9a3412"), 700))
		pill_plato.add_child(fila_plato)
		menu_row.add_child(pill_plato)

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
		"• Paciencia (%d) y Sangre Fría (%d): mayor margen de quemado y clientes más pacientes" % [int(paciencia), int(sangre_fria)],
		"• Economía: la Caja recibe ventas − 30% ingredientes − gastos del servicio. Tú cobras propinas + 5% del beneficio.",
		"• Tirar comida desperdicia ingredientes: −30% de su valor en la Caja."
	]
	if descanso < 25.0 or mental < 25.0:
		mod_lineas.append("• Aviso fatiga/estrés (<25): la paciencia de clientes baja x1.20 más rápido")
	if resacon:
		mod_lineas.append("• Aviso Resacón: margen de quemado reducido (x0.85)")
	if en_turno:
		mod_lineas.append("• ¡EN TURNO ACTIVO! Propinas x1.5, paga completa ilimitada, Progreso x2.0 y +10% nómina hoy")
	else:
		var rest_hoy: int = Sistema_Cocina.Obtener_Servicios_Completos_Restantes_Hoy()
		mod_lineas.append("• Modo libre: %d/%d servicios con paga completa hoy. Después, modo práctica (25%% para ti; la Caja sigue al 100%%)" % [
			rest_hoy, Sistema_Cocina.LIMITE_SERVICIOS_COMPLETOS_DIA])

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
		_Comenzar_Carga_Nivel(nivel))
	btns.add_child(btn_start)

	_modal_inicio.visible = true


# ----------------------------------------------------------------------------
# Modal de Mejoras (componente propio con escaparate y compra)
# ----------------------------------------------------------------------------

func _Construir_Modal_Mejoras() -> void:
	var modal: Control = MejorasCocina.new()
	modal.name = "Modal_Mejoras"
	modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.z_index = 25
	modal.visible = false
	modal.cerrado.connect(_on_modal_mejoras_cerrado)
	modal.compra_realizada.connect(_on_mejora_comprada)
	modal.sonido_solicitado.connect(_on_sonido_mejoras)
	add_child(modal)
	_modal_mejoras = modal


func _Abrir_Modal_Mejoras() -> void:
	if _restaurante_expandido != "":
		_restaurante_actual = _restaurante_expandido
	if _modal_mejoras != null and _modal_mejoras.has_method("abrir"):
		_modal_mejoras.call("abrir", _restaurante_actual)
		_modal_mejoras.visible = true


func _on_modal_mejoras_cerrado() -> void:
	_Refrescar_Mapa()


func _on_mejora_comprada(_mejora_id: String, _nuevo_nivel: int) -> void:
	_Refrescar_Mapa()


func _on_sonido_mejoras(nombre: String, tono: float) -> void:
	if _sfx != null:
		_sfx.reproducir(nombre, -12.0, tono)


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
	_Construir_Despensa_Ingredientes()
	_Construir_Tutorial()
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


func _Estilo_Boton_CF(relleno: Color, borde: Color) -> StyleBoxFlat:
	# Botón azul brillante con borde claro y sombra inferior, al estilo del
	# menú de la cocina de referencia.
	var st := Estilos_UI.caja(relleno, 11, borde, 2, 0)
	st.content_margin_left = 12
	st.content_margin_right = 14
	st.content_margin_top = 6
	st.content_margin_bottom = 7
	st.border_width_bottom = 4
	st.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	st.shadow_size = 3
	st.shadow_offset = Vector2(0.0, 2.0)
	return st


func _Crear_Boton_Menu_CF() -> Button:
	var btn := Button.new()
	btn.name = "Boton_Menu"
	btn.text = "MENÚ"
	btn.icon = Estilos_UI.icono("menu")
	btn.expand_icon = false
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(116, 40)
	btn.tooltip_text = "Menú: seguir, repetir o volver al mapa"
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_override("font", Estilos_UI.fuente_ui(700))
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_constant_override("icon_max_width", 20)
	btn.add_theme_stylebox_override("normal", _Estilo_Boton_CF(Color("#1976d2"), Color("#bbdefb")))
	btn.add_theme_stylebox_override("hover", _Estilo_Boton_CF(Color("#1e88e5"), Color("#e3f2fd")))
	btn.add_theme_stylebox_override("pressed", _Estilo_Boton_CF(Color("#0d47a1"), Color("#90caf9")))
	for estado in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		btn.add_theme_color_override(estado, Color.WHITE)
	for estado in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
		btn.add_theme_color_override(estado, Color.WHITE)
	Estilos_UI.animar_presion(btn)
	return btn


func _Crear_Pill_Clientes_CF() -> PanelContainer:
	# Contador de clientes con la forma y colores del HUD de referencia:
	# placa azul, icono verde de comensales y número grande en blanco.
	var pill := PanelContainer.new()
	pill.name = "Pill_Clientes"
	pill.tooltip_text = "Clientes que quedan por atender"
	var st := Estilos_UI.caja(Color("#1565c0"), 11, Color("#90caf9"), 2, 0)
	st.content_margin_left = 7
	st.content_margin_right = 12
	st.content_margin_top = 2
	st.content_margin_bottom = 2
	st.border_width_bottom = 4
	st.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	st.shadow_size = 3
	st.shadow_offset = Vector2(0.0, 2.0)
	pill.add_theme_stylebox_override("panel", st)

	var hc := HBoxContainer.new()
	hc.alignment = BoxContainer.ALIGNMENT_CENTER
	hc.add_theme_constant_override("separation", 7)
	pill.add_child(hc)

	var badge := PanelContainer.new()
	var st_b := Estilos_UI.caja(Color("#22c55e"), 999, Color("#bbf7d0"), 2, 0)
	st_b.content_margin_left = 4
	st_b.content_margin_right = 4
	st_b.content_margin_top = 3
	st_b.content_margin_bottom = 3
	badge.add_theme_stylebox_override("panel", st_b)
	var icono := Estilos_UI.icono_rect("users", 17, Color.WHITE)
	icono.custom_minimum_size = Vector2(17, 17)
	badge.add_child(icono)
	hc.add_child(badge)

	_lbl_cocina_clientes = Estilos_UI.titulo("0", 20, Color.WHITE)
	_lbl_cocina_clientes.custom_minimum_size = Vector2(26, 0)
	_lbl_cocina_clientes.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_cocina_clientes.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_lbl_cocina_clientes.add_theme_color_override("font_outline_color", Color("#0d47a1"))
	_lbl_cocina_clientes.add_theme_constant_override("outline_size", 4)
	hc.add_child(_lbl_cocina_clientes)
	return pill


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

	var btn_menu := _Crear_Boton_Menu_CF()
	btn_menu.pressed.connect(_Abrir_Modal_Pausa)
	fila.add_child(btn_menu)

	var pill_clientes := _Crear_Pill_Clientes_CF()
	fila.add_child(pill_clientes)

	# Recaudación + barra con las 3 estrellas, justo después del contador de
	# clientes como en el HUD de referencia.
	var caja_meta := Control.new()
	caja_meta.custom_minimum_size = Vector2(378, 44)
	caja_meta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(caja_meta)

	var fondo_meta := Panel.new()
	fondo_meta.position = Vector2(0, 2)
	fondo_meta.size = Vector2(378, 40)
	var st_meta := Estilos_UI.caja(Color("#0b1f3a", 0.92), 11,
		Color("#fbbf24", 0.90), 1, 0)
	st_meta.border_width_bottom = 3
	st_meta.shadow_color = Color(0.0, 0.0, 0.0, 0.25)
	st_meta.shadow_size = 2
	st_meta.shadow_offset = Vector2(0.0, 2.0)
	fondo_meta.add_theme_stylebox_override("panel", st_meta)
	fondo_meta.tooltip_text = "Recaudación del nivel: la barra y las estrellas marcan la meta"
	fondo_meta.mouse_filter = Control.MOUSE_FILTER_PASS
	caja_meta.add_child(fondo_meta)

	# Moneda dorada grande, como el contador de dinero del juego de referencia.
	var moneda_fondo := Panel.new()
	moneda_fondo.position = Vector2(5, 6)
	moneda_fondo.size = Vector2(32, 32)
	moneda_fondo.add_theme_stylebox_override("panel",
		Estilos_UI.caja(Color("#b45309"), 999, Color("#fde68a"), 2, 0))
	moneda_fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja_meta.add_child(moneda_fondo)

	_hud_moneda_icon = TextureRect.new()
	_hud_moneda_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hud_moneda_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_hud_moneda_icon.texture = ArteCocina.TEX_MONEDA
	_hud_moneda_icon.position = Vector2(9, 10)
	_hud_moneda_icon.size = Vector2(24, 24)
	_hud_moneda_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja_meta.add_child(_hud_moneda_icon)

	_lbl_cocina_recaudacion = Estilos_UI.titulo("0 €", 19, Color("#fde047"))
	_lbl_cocina_recaudacion.position = Vector2(42, 0)
	_lbl_cocina_recaudacion.size = Vector2(92, 26)
	_lbl_cocina_recaudacion.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_lbl_cocina_recaudacion.add_theme_color_override("font_outline_color", Color("#7c2d12"))
	_lbl_cocina_recaudacion.add_theme_constant_override("outline_size", 4)
	caja_meta.add_child(_lbl_cocina_recaudacion)

	_bar_cocina_meta = ProgressBar.new()
	_bar_cocina_meta.position = Vector2(138, 15)
	_bar_cocina_meta.size = Vector2(228, 14)
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
		estrella.size = Vector2(22, 22)
		estrella.pivot_offset = Vector2(11, 11)
		estrella.position = Vector2(138.0 + 228.0 * (float(s + 1) / 3.0) - 11.0, 11.0)
		estrella.mouse_filter = Control.MOUSE_FILTER_IGNORE
		caja_meta.add_child(estrella)
		_estrellas_hud.append(estrella)

	_lbl_cocina_nivel = Estilos_UI.titulo("Nivel 1", 16, Color("#fef9c3"))
	_lbl_cocina_nivel.custom_minimum_size = Vector2(70, 0)
	_lbl_cocina_nivel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fila.add_child(_lbl_cocina_nivel)

	# Reloj de servicio (tiempo transcurrido: el nivel no termina por tiempo)
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
	_lbl_cocina_reloj = Estilos_UI.titulo("00:00", 17, Color.WHITE)
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
	_lbl_cocina_propinas = Estilos_UI.texto("+0 €", 13, Color("#fde68a"), 700)
	hp.add_child(_lbl_cocina_propinas)
	pill_prop.add_child(hp)
	fila.add_child(pill_prop)

	_pill_cocina_combo = PanelContainer.new()
	_pill_cocina_combo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var st_combo := Estilos_UI.caja(Color("#dc2626"), 999, Color("#fde047"), 1, 0)
	st_combo.content_margin_left = 12
	st_combo.content_margin_right = 12
	st_combo.content_margin_top = 4
	st_combo.content_margin_bottom = 4
	_pill_cocina_combo.add_theme_stylebox_override("panel", st_combo)
	_pill_cocina_combo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pill_cocina_combo.visible = false
	fila.add_child(_pill_cocina_combo)
	var vbox_combo := VBoxContainer.new()
	vbox_combo.add_theme_constant_override("separation", 2)
	vbox_combo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lbl_combo := Estilos_UI.texto("COMBO x2", 11, Color("#fef08a"), 700)
	lbl_combo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_combo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox_combo.add_child(lbl_combo)
	_bar_cocina_combo = ProgressBar.new()
	_bar_cocina_combo.custom_minimum_size = Vector2(86.0, 4.0)
	_bar_cocina_combo.show_percentage = false
	_bar_cocina_combo.max_value = 100.0
	_bar_cocina_combo.add_theme_stylebox_override("background",
		Estilos_UI.caja(Color("#450a0a"), 999, Color.TRANSPARENT, 0, 0))
	_bar_cocina_combo.add_theme_stylebox_override("fill",
		Estilos_UI.barra_relleno(Color("#fef08a"), 999))
	vbox_combo.add_child(_bar_cocina_combo)
	_pill_cocina_combo.add_child(vbox_combo)
	_lbl_cocina_combo = lbl_combo

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
	pill.z_index = 5
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := Estilos_UI.caja(Color("#0f172a", 0.86), 999, Color("#fbbf24", 0.65), 1, 0)
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


func _Ocultar_Tutorial() -> void:
	if _tutorial_foco != null:
		_tutorial_foco.visible = false
		_tutorial_foco.focos.clear()
	if _tutorial_panel != null:
		_tutorial_panel.visible = false


func _Rect_Bandeja(ingrediente: String) -> Rect2:
	for item in _bandeja_items_ui:
		if str(item["ingrediente"]) == ingrediente:
			return item["rect"]
	return Rect2()


func _Rect_Cliente_Destino(indice: int) -> Rect2:
	if indice < 0 or indice >= CENTROS_CLIENTES.size():
		return Rect2()
	var cx: float = CENTROS_CLIENTES[indice]
	return Rect2(cx - 100.0, 200.0, 200.0, 218.0)


func _Rect_Bocadillo_Cliente_Destino(indice: int) -> Rect2:
	if indice < 0 or indice >= _slots_clientes_ui.size():
		return Rect2()
	var ui: Dictionary = _slots_clientes_ui[indice]
	var ticket: Control = ui.get("ticket", null)
	if ticket == null or not is_instance_valid(ticket):
		return Rect2()
	return Rect2(ui["pos_ticket"], ticket.size).grow(6.0)


func _Cliente_Necesita_Burger() -> bool:
	for ci in range(_clientes.size()):
		var cl: Dictionary = _clientes[ci]
		if not bool(cl["activo"]):
			continue
		var fase: String = str(_slots_clientes_ui[ci].get("fase", ""))
		if fase in ["entrando", "saliendo"]:
			continue
		for item in cl["items"]:
			var rec: String = str(item)
			if rec.begins_with("burger") and _Cliente_Necesita_Item(cl, rec):
				return true
	return false


func _Actualizar_Tutorial() -> void:
	if not _jugando or _nivel_actual != 1 \
			or Sistema_Cocina.Contar_Niveles_Superados("burger_street") > 0:
		_Ocultar_Tutorial()
		return

	var focos: Array[Rect2] = []
	var texto: String = ""
	var hay_pedido_burger: bool = _Cliente_Necesita_Burger()

	# 1) Servir un plato completo que un cliente esté esperando
	for i in range(_platos.size()):
		var rec: String = _Receta_De_Plato(_platos[i])
		if rec == "":
			continue
		for ci in range(_clientes.size()):
			var cl: Dictionary = _clientes[ci]
			if bool(cl["activo"]) and _Cliente_Necesita_Item(cl, rec):
				focos = [_slots_platos_ui[i]["rect"], _Rect_Cliente_Destino(ci)]
				texto = "Sirve el plato al cliente"
				break
		if texto != "":
			break

	# 2) Carne lista y un plato con pan esperando
	if texto == "" and hay_pedido_burger:
		for i in range(_plancha.size()):
			if str(_plancha[i]["estado"]) not in ["listo", "alerta"]:
				continue
			for j in range(_platos.size()):
				if bool(_platos[j]["pan"]) and int(_platos[j]["carnes"]) < 2:
					focos = [_slots_plancha_ui[i]["rect"], _slots_platos_ui[j]["rect"]]
					texto = "Arrastra la carne al pan"
					break
			if texto != "":
				break

	# 3) Comida quemada
	if texto == "":
		for i in range(_plancha.size()):
			if str(_plancha[i]["estado"]) == "quemado":
				focos = [_slots_plancha_ui[i]["rect"], _papelera_rect]
				texto = "Tira lo quemado a la BASURA"
				break
	if texto == "":
		for i in range(_freidora.size()):
			if str(_freidora[i]["estado"]) == "quemado":
				focos = [_slots_freidora_ui[i]["rect"], _papelera_rect]
				texto = "Tira lo quemado a la BASURA"
				break

	# 4) Plato con pan esperando carne
	if texto == "" and hay_pedido_burger:
		for j in range(_platos.size()):
			if not bool(_platos[j]["pan"]) or int(_platos[j]["carnes"]) >= 2:
				continue
			var hay_carne: bool = false
			for sl in _plancha:
				if str(sl["estado"]) != "vacio":
					hay_carne = true
					break
			if not hay_carne:
				for k in range(_plancha.size()):
					if str(_plancha[k]["estado"]) == "vacio":
						focos = [_Rect_Bandeja("carne"), _slots_plancha_ui[k]["rect"]]
						texto = "Toca la CARNE para cocinarla"
						break
			else:
				for k in range(_plancha.size()):
					if str(_plancha[k]["estado"]) in ["cocinando", "listo", "alerta"]:
						focos = [_slots_plancha_ui[k]["rect"]]
						texto = "Espera a que la carne esté lista"
						break
			if texto != "":
				break

	# 5) Poner pan en un plato
	if texto == "" and hay_pedido_burger:
		for j in range(_platos.size()):
			if not bool(_platos[j]["pan"]):
				focos = [_Rect_Bandeja("pan"), _slots_platos_ui[j]["rect"]]
				texto = "Toca el PAN para ponerlo en el plato"
				break

	# 6) Refresco listo para un cliente que lo pide
	if texto == "":
		for i in range(_bebidas.size()):
			if str(_bebidas[i]["estado"]) != "listo":
				continue
			for ci in range(_clientes.size()):
				var cl: Dictionary = _clientes[ci]
				if bool(cl["activo"]) and _Cliente_Necesita_Item(cl, "refresco"):
					focos = [_slots_bebidas_ui[i]["rect"], _Rect_Cliente_Destino(ci)]
					texto = "Arrastra el REFRESCO al cliente"
					break
			if texto != "":
				break

	# 7) Patatas listas para un cliente
	if texto == "":
		for i in range(_freidora.size()):
			if str(_freidora[i]["estado"]) not in ["listo", "alerta"]:
				continue
			for ci in range(_clientes.size()):
				var cl: Dictionary = _clientes[ci]
				if bool(cl["activo"]) and _Cliente_Necesita_Item(cl, "patatas"):
					focos = [_slots_freidora_ui[i]["rect"], _Rect_Cliente_Destino(ci)]
					texto = "Arrastra las PATATAS al cliente"
					break
			if texto != "":
				break

	# 8) Patatas para un cliente sin freír
	if texto == "":
		for ci in range(_clientes.size()):
			var cl: Dictionary = _clientes[ci]
			if not bool(cl["activo"]) or not _Cliente_Necesita_Item(cl, "patatas"):
				continue
			var hay_patatas: bool = false
			for sl in _freidora:
				if str(sl["estado"]) != "vacio":
					hay_patatas = true
					break
			if not hay_patatas:
				for k in range(_freidora.size()):
					if str(_freidora[k]["estado"]) == "vacio":
						focos = [_Rect_Bandeja("patatas"), _slots_freidora_ui[k]["rect"]]
						texto = "Toca las PATATAS para freírlas"
						break
			if texto != "":
				break

	# 9) Plato completo que nadie pide: a la basura
	if texto == "":
		for i in range(_platos.size()):
			var rec2: String = _Receta_De_Plato(_platos[i])
			if rec2 != "" and not _Algun_Cliente_Necesita(rec2):
				focos = [_slots_platos_ui[i]["rect"], _papelera_rect]
				texto = "Nadie pide ese plato: tíralo a la BASURA"
				break

	if texto == "":
		_Ocultar_Tutorial()
		return
	_tutorial_foco.focos = focos
	_tutorial_foco.tiempo = _anim_tiempo
	_tutorial_foco.visible = true
	_tutorial_panel.visible = true
	_tutorial_label.text = "TUTORIAL · " + texto


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
	retrato.position = Vector2(cx - 95.0, Y_BASE_CLIENTE - 175.0)
	retrato.size = Vector2(190.0, 175.0)
	retrato.pivot_offset = Vector2(95.0, 175.0)
	retrato.z_index = 1
	retrato.visible = false
	_vista_cocina.add_child(retrato)

	var ticket := ArteCocina.Ticket.new()
	ticket.name = "Ticket_Pedido_%d" % indice
	ticket.position = Vector2(cx - 80.0, 66.0)
	ticket.size = Vector2(160.0, 132.0)
	ticket.z_index = 5
	ticket.visible = false
	_vista_cocina.add_child(ticket)

	return {
		"root": retrato,
		"retrato": retrato,
		"ticket": ticket,
		"centro": Vector2(cx, Y_BASE_CLIENTE - 68.0),
		"pos_retrato": retrato.position,
		"pos_ticket": ticket.position,
		"visible_antes": false,
		"fase": "inactivo",
		"tipo_salida": "",
		"salida_hasta": 0.0,
		"entrada_hasta": 0.0,
		"bloqueado_hasta": 0.0,
		"aviso_media": false,
		"aviso_baja": false,
		"bocadillo": null,
		"tween": null,
		"destacado": false,
	}


func _Construir_Mostrador() -> void:
	# Repisa de mostrador de acero inoxidable: oculta limpiamente el corte inferior
	# de clientes y chef, y sostiene las estaciones en perspectiva.
	var encimera := TextureRect.new()
	encimera.name = "Encimera_Mostrador"
	encimera.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	encimera.stretch_mode = TextureRect.STRETCH_SCALE
	encimera.texture = ArteCocina.TEX_ENCIMERA
	encimera.position = Vector2(0.0, 418.0)
	encimera.size = Vector2(1280.0, 108.0)
	encimera.z_index = 2
	encimera.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vista_cocina.add_child(encimera)

	# Frente de acero del mostrador: cierra el mueble hasta el suelo y sirve de
	# fondo al mueble bajo de ingredientes (el estante de madera va delante).
	var frente := TextureRect.new()
	frente.name = "Frente_Mostrador"
	frente.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frente.stretch_mode = TextureRect.STRETCH_SCALE
	frente.texture = ArteCocina.TEX_FRENTE_MOSTRADOR
	frente.position = Vector2(0.0, 520.0)
	frente.size = Vector2(1280.0, 186.0)
	frente.z_index = 2
	frente.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vista_cocina.add_child(frente)

	# Etiquetas limpias en el borde frontal de la barra (sin tapar clientes ni comida)
	_lbl_estado_plancha = _Crear_Etiqueta_Estacion(ZONA_PLANCHA.position.x, 599.0,
		ZONA_PLANCHA.size.x, "PLANCHA")
	_lbl_estado_freidora = _Crear_Etiqueta_Estacion(ZONA_FREIDORA.position.x, 599.0,
		ZONA_FREIDORA.size.x, "FREIDORA")
	_lbl_estado_bebidas = _Crear_Etiqueta_Estacion(ZONA_REFRESCOS.position.x, 599.0,
		ZONA_REFRESCOS.size.x, "REFRESCOS")
	_lbl_estado_platos = _Crear_Etiqueta_Estacion(ZONA_PLATOS.position.x, 599.0,
		ZONA_PLATOS.size.x, "EMPLATADO")
	_Crear_Etiqueta_Estacion(ZONA_PAPELERA.position.x, 599.0, ZONA_PAPELERA.size.x, "BASURA")
	_Crear_Etiqueta_Estacion(ZONA_PROPINAS.position.x, 599.0, ZONA_PROPINAS.size.x, "PROPINAS")

	# Plancha (4 fogones)
	var est_plancha := _Anadir_Textura(ArteCocina.TEX_PLANCHA, Rect2(14.0, 424.0, 238.0, 174.0), "Estacion_Plancha")
	est_plancha.z_index = 3
	# Freidora (2 cestas)
	var est_freidora := _Anadir_Textura(ArteCocina.TEX_FREIDORA, Rect2(266.0, 438.0, 150.0, 143.0), "Estacion_Freidora")
	est_freidora.z_index = 3
	# Dispensador de refrescos
	var est_refrescos := _Anadir_Textura(ArteCocina.TEX_REFRESCOS, Rect2(432.0, 418.0, 150.0, 178.0), "Estacion_Refrescos")
	est_refrescos.z_index = 3

	# Mampara de cristal del pase, detrás de la bandeja metálica.
	var fondo_pase := ArteCocina.Fondo_Pase.new()
	fondo_pase.name = "Fondo_Pase"
	fondo_pase.position = Vector2(610.0, 378.0)
	fondo_pase.size = Vector2(410.0, 38.0)
	fondo_pase.z_index = 2
	fondo_pase.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vista_cocina.add_child(fondo_pase)

	# Bandeja metálica de emplatado con compartimentos (pase de platos)
	_bandeja_emplatado = ArteCocina.Bandeja_Emplatado.new()
	_bandeja_emplatado.name = "Bandeja_Emplatado"
	_bandeja_emplatado.position = Vector2(610.0, 416.0)
	_bandeja_emplatado.size = Vector2(410.0, 180.0)
	_bandeja_emplatado.z_index = 3
	_bandeja_emplatado.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vista_cocina.add_child(_bandeja_emplatado)

	# Papelera
	_papelera_root = Control.new()
	_papelera_root.name = "Papelera"
	_papelera_root.position = Vector2(1026.0, 466.0)
	_papelera_root.size = Vector2(86.0, 120.0)
	_papelera_root.z_index = 3
	_papelera_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex_papelera := TextureRect.new()
	tex_papelera.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_papelera.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_papelera.texture = ArteCocina.TEX_PAPELERA
	tex_papelera.set_anchors_preset(Control.PRESET_FULL_RECT)
	tex_papelera.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_papelera_root.add_child(tex_papelera)
	_vista_cocina.add_child(_papelera_root)
	_papelera_rect = Rect2(1014.0, 405.0, 108.0, 195.0)

	# Bote de propinas + monedas
	_propinas_root = Control.new()
	_propinas_root.name = "Propinas"
	_propinas_root.position = Vector2(1124.0, 476.0)
	_propinas_root.size = Vector2(146.0, 118.0)
	_propinas_root.z_index = 3
	_propinas_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex_bote := TextureRect.new()
	tex_bote.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_bote.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_bote.texture = ArteCocina.TEX_BOTE_PROPINAS
	tex_bote.position = Vector2(2.0, 10.0)
	tex_bote.size = Vector2(62.0, 62.0)
	tex_bote.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_propinas_root.add_child(tex_bote)
	var tex_pila := TextureRect.new()
	tex_pila.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_pila.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_pila.texture = ArteCocina.TEX_PILA_MONEDAS
	tex_pila.position = Vector2(64.0, 20.0)
	tex_pila.size = Vector2(80.0, 70.0)
	tex_pila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_propinas_root.add_child(tex_pila)
	var pill_prop_val := PanelContainer.new()
	pill_prop_val.position = Vector2(40.0, 92.0)
	pill_prop_val.size = Vector2(72.0, 22.0)
	pill_prop_val.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st_pv := Estilos_UI.caja(Color("#0f172a", 0.88), 999, Color("#fbbf24", 0.75), 1, 0)
	st_pv.content_margin_left = 6
	st_pv.content_margin_right = 6
	st_pv.content_margin_top = 1
	st_pv.content_margin_bottom = 1
	pill_prop_val.add_theme_stylebox_override("panel", st_pv)
	_lbl_estado_propinas = Estilos_UI.texto("0 €", 12, Color("#fde68a"), 700)
	_lbl_estado_propinas.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_estado_propinas.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_lbl_estado_propinas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill_prop_val.add_child(_lbl_estado_propinas)
	_propinas_root.add_child(pill_prop_val)
	_vista_cocina.add_child(_propinas_root)

	# Contenedores dinámicos (se vacían en cada nivel)
	_contenedor_plancha = _Crear_Contenedor_Dinamico("Contenedor_Plancha")
	_contenedor_freidora = _Crear_Contenedor_Dinamico("Contenedor_Freidora")
	_contenedor_bebidas = _Crear_Contenedor_Dinamico("Contenedor_Bebidas")
	_contenedor_platos = _Crear_Contenedor_Dinamico("Contenedor_Platos")
	for cont in [_contenedor_plancha, _contenedor_freidora, _contenedor_bebidas, _contenedor_platos]:
		cont.z_index = 4


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


func _Construir_Despensa_Ingredientes() -> void:
	# Mueble bajo la encimera integrado en la escena, como la despensa de la
	# cocina de referencia: frente de armario, estante de madera y recipientes
	# reales (panera con dos huecos, bandeja de carne, tabla de queso, bol de
	# lechuga, bandeja de tomate y cesta de patatas). No hay tarjetas ni
	# botonera: la comida se toca o se arrastra directamente del recipiente.
	var fondo := ArteCocina.Fondo_Despensa.new()
	fondo.name = "Fondo_Despensa"
	fondo.position = ZONA_DESPENSA.position
	fondo.size = ZONA_DESPENSA.size
	fondo.z_index = 2
	_vista_cocina.add_child(fondo)

	# Utensilios de apoyo en el hueco libre bajo la freidora y los refrescos.
	var pila := _Anadir_Textura(ArteCocina.TEX_PILA_PLATOS,
		Rect2(390.0, 646.0, 82.0, 62.0), "Despensa_Pila_Platos")
	pila.z_index = 3
	var bandejas := _Anadir_Textura(ArteCocina.TEX_BANDEJAS_APILADAS,
		Rect2(480.0, 652.0, 92.0, 56.0), "Despensa_Bandejas")
	bandejas.z_index = 3

	_bandeja_items_ui.clear()
	for ing in ORDEN_PUESTOS_INGREDIENTES:
		var caja: Rect2 = PUESTOS_INGREDIENTES[ing]
		var item := ArteCocina.Puesto_Ingrediente.new()
		item.name = "Puesto_%s" % ing
		item.ingrediente = ing
		item.position = caja.position
		item.size = caja.size
		item.z_index = 6
		_vista_cocina.add_child(item)
		_bandeja_items_ui.append({
			"nodo": item,
			"ingrediente": ing,
			"rect": caja,
		})


func _Construir_Tutorial() -> void:
	_tutorial_foco = ArteCocina.Tutorial_Foco.new()
	_tutorial_foco.name = "Tutorial_Foco"
	_tutorial_foco.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tutorial_foco.z_index = 18
	_tutorial_foco.visible = false
	_vista_cocina.add_child(_tutorial_foco)

	_tutorial_panel = PanelContainer.new()
	_tutorial_panel.name = "Tutorial_Panel"
	_tutorial_panel.position = Vector2(290.0, 204.0)
	_tutorial_panel.size = Vector2(700.0, 34.0)
	_tutorial_panel.z_index = 18
	_tutorial_panel.visible = false
	_tutorial_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := Estilos_UI.caja(Color("#0f172a", 0.92), 999, Color("#fbbf24"), 2, 0)
	st.content_margin_left = 14
	st.content_margin_right = 14
	st.content_margin_top = 4
	st.content_margin_bottom = 4
	_tutorial_panel.add_theme_stylebox_override("panel", st)
	_tutorial_label = Estilos_UI.texto("", 14, Color("#fde68a"), 700)
	_tutorial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tutorial_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_tutorial_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tutorial_panel.add_child(_tutorial_label)
	_vista_cocina.add_child(_tutorial_panel)


func _Construir_Chef_Cutin() -> void:
	_chef_root = Control.new()
	_chef_root.name = "Chef_Cutin"
	_chef_root.position = Vector2(6.0, 118.0)
	_chef_root.size = Vector2(270.0, 330.0)
	_chef_root.visible = false
	_chef_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chef_root.z_index = 1
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
	_card_resultados = card

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 28)
	m.add_theme_constant_override("margin_right", 28)
	m.add_theme_constant_override("margin_top", 22)
	m.add_theme_constant_override("margin_bottom", 22)
	card.add_child(m)

	_vbox_modal_resultados = VBoxContainer.new()
	_vbox_modal_resultados.add_theme_constant_override("separation", 10)
	m.add_child(_vbox_modal_resultados)


# ----------------------------------------------------------------------------
# Modal de confirmación al abandonar una partida en curso
# ----------------------------------------------------------------------------

func _Construir_Modal_Confirmar_Salida() -> void:
	_modal_salida = Control.new()
	_modal_salida.name = "Modal_Confirmar_Salida"
	_modal_salida.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_salida.z_index = 45
	_modal_salida.visible = false
	add_child(_modal_salida)

	var velo := ColorRect.new()
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	velo.color = Color(0.06, 0.09, 0.15, 0.72)
	_modal_salida.add_child(velo)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_salida.add_child(centro)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(640, 0)
	card.add_theme_stylebox_override("panel", Estilos_UI.caja_tarjeta(20, 3))
	centro.add_child(card)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 30)
	m.add_theme_constant_override("margin_right", 30)
	m.add_theme_constant_override("margin_top", 24)
	m.add_theme_constant_override("margin_bottom", 24)
	card.add_child(m)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	m.add_child(v)

	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 12)
	v.add_child(cab)
	cab.add_child(Estilos_UI.badge_icono("triangle-alert", 44, 22, Estilos_UI.AVISO, Color.WHITE, 12))
	var tit := Estilos_UI.titulo("¿Seguro que quieres salir?", 24, Estilos_UI.TINTA)
	tit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tit.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cab.add_child(tit)

	var txt := Estilos_UI.parrafo(
		"Si sales ahora perderás las ventas y todo el progreso de este nivel. " +
		"No se guardarán las estrellas, las propinas ni la Caja del restaurante.",
		15, Estilos_UI.TINTA_SUAVE)
	v.add_child(txt)

	_lbl_salida_resumen = Estilos_UI.texto("", 14, Estilos_UI.TINTA, 700)
	_lbl_salida_resumen.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_lbl_salida_resumen)

	v.add_child(Estilos_UI.divisor_horizontal())

	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 12)
	v.add_child(btns)

	var btn_seguir := Estilos_UI.boton("Seguir cocinando", "exito", "play", Estilos_UI.EXITO, 50)
	btn_seguir.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_seguir.pressed.connect(_Cancelar_Salida_Partida)
	btns.add_child(btn_seguir)

	var btn_salir := Estilos_UI.boton("Salir y perder progreso", "peligro", "x", Estilos_UI.PELIGRO, 50)
	btn_salir.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_salir.pressed.connect(_Confirmar_Salida_Partida)
	btns.add_child(btn_salir)


func _Intentar_Volver_Al_Mapa() -> void:
	if _jugando or _pausado_por_confirmacion:
		_Abrir_Modal_Confirmar_Salida()
		return
	_Mostrar_Mapa()


# ----------------------------------------------------------------------------
# Modal de pausa (Reanudar / Repetir / Salir)
# ----------------------------------------------------------------------------

func _Construir_Modal_Pausa() -> void:
	_modal_pausa = Control.new()
	_modal_pausa.name = "Modal_Pausa"
	_modal_pausa.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_pausa.z_index = 44
	_modal_pausa.visible = false
	add_child(_modal_pausa)

	var velo := ColorRect.new()
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	velo.color = Color(0.04, 0.07, 0.12, 0.80)
	_modal_pausa.add_child(velo)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_pausa.add_child(centro)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(620, 0)
	card.add_theme_stylebox_override("panel", Estilos_UI.caja_tarjeta(20, 3))
	centro.add_child(card)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 30)
	m.add_theme_constant_override("margin_right", 30)
	m.add_theme_constant_override("margin_top", 24)
	m.add_theme_constant_override("margin_bottom", 24)
	card.add_child(m)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	m.add_child(v)

	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 12)
	v.add_child(cab)
	cab.add_child(Estilos_UI.badge_icono("pause", 44, 22, Color("#0ea5e9"), Color.WHITE, 12))
	var tit := Estilos_UI.titulo("Servicio en pausa", 24, Estilos_UI.TINTA)
	tit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tit.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cab.add_child(tit)

	var txt := Estilos_UI.parrafo(
		"El tiempo y la paciencia de los clientes están detenidos. " +
		"Puedes seguir cocinando, repetir el nivel desde el principio o volver al mapa.",
		15, Estilos_UI.TINTA_SUAVE)
	v.add_child(txt)

	_lbl_pausa_resumen = Estilos_UI.texto("", 14, Estilos_UI.TINTA, 700)
	_lbl_pausa_resumen.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_lbl_pausa_resumen)

	v.add_child(Estilos_UI.divisor_horizontal())

	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 10)
	v.add_child(btns)

	var btn_seguir := Estilos_UI.boton("Seguir cocinando", "exito", "play", Estilos_UI.EXITO, 50)
	btn_seguir.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_seguir.pressed.connect(_Reanudar_Partida)
	btns.add_child(btn_seguir)

	var btn_repetir := Estilos_UI.boton("Repetir", "oro", "rotate-ccw", Estilos_UI.ORO, 50)
	btn_repetir.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_repetir.pressed.connect(_Repetir_Desde_Pausa)
	btns.add_child(btn_repetir)

	var btn_mapa := Estilos_UI.boton("Al mapa", "secundario", "arrow-left", Estilos_UI.TINTA, 50)
	btn_mapa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_mapa.pressed.connect(_Salir_Desde_Pausa)
	btns.add_child(btn_mapa)


func _Abrir_Modal_Pausa() -> void:
	if not _jugando:
		return
	if _modal_pausa == null or not is_instance_valid(_modal_pausa):
		return
	_pausado_por_confirmacion = true
	_jugando = false
	if _arrastre != null:
		_arrastre.cancelar()
		_arrastre.habilitado = false
	_lbl_pausa_resumen.text = "Nivel %d · Ticket %d € · Meta %d € · Quedan %d clientes" % [
		_nivel_actual, _recaudacion,
		int(_cfg_nivel_actual.get("meta_3", 115)), _Clientes_Restantes()]
	_modal_pausa.visible = true
	_modal_pausa.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_modal_pausa, "modulate:a", 1.0, 0.16)


func _Reanudar_Partida() -> void:
	if _modal_pausa != null:
		_modal_pausa.visible = false
	if _modal_salida != null:
		_modal_salida.visible = false
	_pausado_por_confirmacion = false
	_jugando = true
	if _arrastre != null:
		_arrastre.habilitado = true
		_Registrar_Zonas_Arrastre()


func _Repetir_Desde_Pausa() -> void:
	if _modal_pausa != null:
		_modal_pausa.visible = false
	_pausado_por_confirmacion = false
	_Comenzar_Carga_Nivel(_nivel_actual)


func _Salir_Desde_Pausa() -> void:
	if _modal_pausa != null:
		_modal_pausa.visible = false
	_Abrir_Modal_Confirmar_Salida()


func _Abrir_Modal_Confirmar_Salida() -> void:
	if _modal_salida == null or not is_instance_valid(_modal_salida):
		return
	if _jugando:
		_pausado_por_confirmacion = true
		_jugando = false
		if _arrastre != null:
			_arrastre.cancelar()
			_arrastre.habilitado = false
	if _modal_pausa != null:
		_modal_pausa.visible = false
	_lbl_salida_resumen.text = "Ticket actual: %d € · %d clientes atendidos" % [
		_recaudacion, _clientes_atendidos]
	_modal_salida.visible = true
	_modal_salida.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_modal_salida, "modulate:a", 1.0, 0.16)


func _Cancelar_Salida_Partida() -> void:
	if _modal_salida != null:
		_modal_salida.visible = false
	if _pausado_por_confirmacion:
		_pausado_por_confirmacion = false
		_jugando = true
		if _arrastre != null:
			_arrastre.habilitado = true
			_Registrar_Zonas_Arrastre()


func _Confirmar_Salida_Partida() -> void:
	if _modal_salida != null:
		_modal_salida.visible = false
	_pausado_por_confirmacion = false
	# El nivel se abandona sin otorgar recompensas: al volver al mapa se
	# descarta la recaudación y el progreso de esta partida.
	_Mostrar_Mapa()


# ============================================================================
# Pantalla de carga horizontal (al entrar a una partida)
# ============================================================================

func _Construir_Vista_Carga() -> void:
	_vista_carga = Control.new()
	_vista_carga.name = "Vista_Carga"
	_vista_carga.size = Vector2(TAMANO_HORIZONTAL)
	_vista_carga.visible = false
	_vista_carga.mouse_filter = Control.MOUSE_FILTER_STOP
	_vista_carga.z_index = 35
	add_child(_vista_carga)

	var fondo := TextureRect.new()
	fondo.name = "Fondo_Carga"
	fondo.texture = ArteCocina.TEX_FONDO
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fondo.stretch_mode = TextureRect.STRETCH_SCALE
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vista_carga.add_child(fondo)

	var velo := ColorRect.new()
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	velo.color = Color(0.03, 0.06, 0.12, 0.72)
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vista_carga.add_child(velo)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vista_carga.add_child(centro)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(760, 0)
	var st_card := Estilos_UI.caja(Color("#0f172a", 0.96), 24, Color("#f59e0b"), 2, 4)
	st_card.border_width_bottom = 5
	card.add_theme_stylebox_override("panel", st_card)
	centro.add_child(card)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 40)
	m.add_theme_constant_override("margin_right", 40)
	m.add_theme_constant_override("margin_top", 32)
	m.add_theme_constant_override("margin_bottom", 28)
	card.add_child(m)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	m.add_child(v)

	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 18)
	v.add_child(cab)

	var chef := TextureRect.new()
	chef.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chef.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	chef.texture = ArteCocina.textura_chef("sirviendo")
	chef.custom_minimum_size = Vector2(112.0, 112.0)
	chef.size = Vector2(112.0, 112.0)
	cab.add_child(chef)

	var col_txt := VBoxContainer.new()
	col_txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_txt.alignment = BoxContainer.ALIGNMENT_CENTER
	col_txt.add_theme_constant_override("separation", 4)
	cab.add_child(col_txt)

	_lbl_carga_titulo = Estilos_UI.titulo("Nivel 1 · Burger Street", 26, Color.WHITE)
	_lbl_carga_titulo.clip_text = true
	col_txt.add_child(_lbl_carga_titulo)
	_lbl_carga_sub = Estilos_UI.texto("Preparando el servicio…", 14, Color("#fde68a"), 600)
	col_txt.add_child(_lbl_carga_sub)

	var barra_fondo := PanelContainer.new()
	var st_bf := Estilos_UI.caja(Color("#1e293b"), 14, Color("#334155"), 1, 0)
	st_bf.content_margin_left = 4
	st_bf.content_margin_right = 4
	st_bf.content_margin_top = 4
	st_bf.content_margin_bottom = 4
	barra_fondo.add_theme_stylebox_override("panel", st_bf)
	v.add_child(barra_fondo)

	_barra_carga = ProgressBar.new()
	_barra_carga.name = "Barra_Carga"
	_barra_carga.custom_minimum_size = Vector2(0.0, 24.0)
	_barra_carga.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_barra_carga.min_value = 0.0
	_barra_carga.max_value = 100.0
	_barra_carga.value = 0.0
	_barra_carga.show_percentage = false
	_barra_carga.add_theme_stylebox_override("background", Estilos_UI.caja(Color("#0b1220"), 10, Color.TRANSPARENT, 0, 0))
	_barra_carga.add_theme_stylebox_override("fill", Estilos_UI.caja(Color("#f59e0b"), 10, Color("#fbbf24"), 0, 0))
	_barra_carga.value_changed.connect(_on_carga_valor_cambiado)
	barra_fondo.add_child(_barra_carga)

	var pie := HBoxContainer.new()
	pie.add_theme_constant_override("separation", 12)
	v.add_child(pie)

	_lbl_carga_paso = Estilos_UI.texto("Calentando la plancha…", 14, Color("#e2e8f0"), 500)
	_lbl_carga_paso.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pie.add_child(_lbl_carga_paso)

	_lbl_carga_pct = Estilos_UI.texto("0 %", 16, Color("#fbbf24"), 700)
	_lbl_carga_pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pie.add_child(_lbl_carga_pct)

	var pie2 := HBoxContainer.new()
	pie2.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(pie2)

	var btn_cancelar := Estilos_UI.boton("Cancelar", "secundario", "x", Color.WHITE, 42)
	btn_cancelar.custom_minimum_size = Vector2(170, 42)
	btn_cancelar.pressed.connect(_Mostrar_Mapa)
	pie2.add_child(btn_cancelar)


func _Comenzar_Carga_Nivel(nivel: int) -> void:
	var cfg: Dictionary = Sistema_Cocina.Obtener_Config_Nivel(_restaurante_actual, nivel)
	if cfg.is_empty():
		return

	_nivel_en_carga = nivel
	_carga_activa = true
	_jugando = false
	_pausado_por_confirmacion = false
	_modal_inicio.visible = false
	_modal_mejoras.visible = false
	_modal_resultados.visible = false
	if _modal_pausa != null:
		_modal_pausa.visible = false
	_vista_mapa.visible = false
	_vista_cocina.visible = false

	# La partida (y su carga) siempre en horizontal 1280x720
	_Aplicar_Orientacion_Horizontal()
	_Centrar_Contenido()

	_lbl_carga_titulo.text = "Nivel %d · %s" % [nivel, Sistema_Cocina.Obtener_Nombre_Restaurante(_restaurante_actual)]
	_lbl_carga_sub.text = "Preparando el servicio…"
	_lbl_carga_paso.text = "Calentando la plancha…"
	_lbl_carga_pct.text = "0 %"
	_barra_carga.value = 0.0
	_vista_carga.visible = true

	if _tween_carga != null:
		_tween_carga.kill()
	_tween_carga = create_tween()
	_tween_carga.tween_interval(RETARDO_CARGA_NIVEL)
	_tween_carga.tween_property(_barra_carga, "value", 100.0, DURACION_CARGA_NIVEL) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween_carga.tween_callback(_Finalizar_Carga)


func _on_carga_valor_cambiado(valor: float) -> void:
	if _lbl_carga_pct != null and is_instance_valid(_lbl_carga_pct):
		_lbl_carga_pct.text = "%d %%" % int(round(valor))
	if _lbl_carga_paso != null and is_instance_valid(_lbl_carga_paso):
		var paso: String = "Calentando la plancha…"
		if valor >= 30.0:
			paso = "Picando los ingredientes…"
		if valor >= 60.0:
			paso = "Preparando las mesas…"
		if valor >= 85.0:
			paso = "¡Abriendo el restaurante!"
		_lbl_carga_paso.text = paso


func _Finalizar_Carga() -> void:
	if not _carga_activa and _nivel_en_carga < 0:
		return
	var nivel: int = _nivel_en_carga
	if _tween_carga != null:
		_tween_carga.kill()
	_tween_carga = null
	_carga_activa = false
	_nivel_en_carga = -1
	if _vista_carga != null and is_instance_valid(_vista_carga):
		_vista_carga.visible = false
	if _barra_carga != null and is_instance_valid(_barra_carga):
		_barra_carga.value = 0.0
	if nivel > 0:
		_Iniciar_Nivel(nivel)


# ============================================================================
# Inicio de Nivel y Construcción de Estaciones según Mejoras
# ============================================================================

func _Iniciar_Nivel(nivel: int) -> void:
	var cfg: Dictionary = Sistema_Cocina.Obtener_Config_Nivel(_restaurante_actual, nivel)
	if cfg.is_empty():
		return

	_pausado_por_confirmacion = false
	if _modal_salida != null:
		_modal_salida.visible = false
	if _modal_pausa != null:
		_modal_pausa.visible = false
	_nivel_actual = nivel
	_cfg_nivel_actual = cfg
	# Secuencia determinista por restaurante y nivel (memorizable).
	var idx_rest: int = maxi(0, Sistema_Cocina.ORDEN_RESTAURANTES.find(_restaurante_actual))
	_rng.seed = 7919 * nivel + 104729 * (idx_rest + 1) + 15485863
	_en_turno_partida = Sistema_Cocina.Esta_En_Turno_Activo(_restaurante_actual)
	_modo_practica_partida = not _en_turno_partida \
		and Sistema_Cocina.Obtener_Servicios_Completos_Restantes_Hoy() <= 0
	# El nivel termina cuando se han atendido (o perdido) todos los clientes.
	_clientes_totales = maxi(1, int(cfg.get("clientes", 10)))
	_clientes_pendientes = _clientes_totales
	_tiempo_servicio = 0.0
	_recaudacion = 0
	_propinas_servicio = 0
	_desperdicio_valor = 0
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
	_lbl_cocina_propinas.text = "+0 €"
	var meta_3: int = maxi(1, int(cfg.get("meta_3", 115)))
	_bar_cocina_meta.max_value = float(meta_3)
	_bar_cocina_meta.value = 0.0
	var m1: float = float(cfg.get("meta_1", 55)) / float(meta_3)
	var m2: float = float(cfg.get("meta_2", 85)) / float(meta_3)
	var x_bar: float = _bar_cocina_meta.position.x
	var ancho_bar: float = _bar_cocina_meta.size.x
	_estrellas_hud[0].position.x = x_bar + clampf(ancho_bar * m1 - 11.0, 0.0, ancho_bar - 22.0)
	_estrellas_hud[1].position.x = x_bar + clampf(ancho_bar * m2 - 11.0, 22.0, ancho_bar - 22.0)
	_estrellas_hud[2].position.x = x_bar + ancho_bar - 22.0
	for estrella in _estrellas_hud:
		estrella.texture = ArteCocina.TEX_ESTRELLA_VACIA
		estrella.scale = Vector2.ONE

	_vista_mapa.visible = false
	_modal_resultados.visible = false
	_vista_cocina.visible = true
	_jugando = true

	_Reiniciar_UI_Clientes()
	_Ocultar_Tutorial()
	_tutorial_timer = 0.0
	_ultimo_aviso_quemado = -10.0
	_shake_t = 0.0
	_vista_cocina.position = _origen_vista
	_Actualizar_HUD_Cocina()
	_Actualizar_Todas_Las_Estaciones_UI()
	_Actualizar_Todos_Los_Clientes_UI()
	_Registrar_Zonas_Arrastre()
	_Mostrar_Banner("¡A COCINAR!", Color("#fef08a"))
	_Mostrar_Chef("sirviendo", "¡Hoy tenemos %d clientes!" % _clientes_totales, Color("#9a3412"), 2.4)
	if _sfx != null:
		_sfx.reproducir("start", -12.0)


func _Disposicion_Bandeja_Platos(num_desbloqueados: int) -> Array[Rect2]:
	# Cuatro huecos fijos dentro de la alfombrilla de la bandeja metálica 3D.
	# La bandeja y las celdas comparten el mismo cálculo que el dibujo del
	# puesto (Arte_Cocina.rect_liner_emplatado / celdas_emplatado), así los
	# platos, los candados y los controles siempre coinciden.
	if _bandeja_emplatado == null:
		return []
	var caja := Rect2(Vector2.ZERO, _bandeja_emplatado.size)
	var celdas: Array[Rect2] = ArteCocina.celdas_emplatado(caja)
	_bandeja_emplatado.configurar(celdas, num_desbloqueados)
	return celdas


func _Reconstruir_Estaciones(num_bebidas: int, num_platos: int, num_plancha: int, num_freidora: int) -> void:
	# --- Refrescos (alineados sobre la bandeja de goteo del dispensador) -----
	for c in _contenedor_bebidas.get_children():
		c.queue_free()
	_bebidas.clear()
	_slots_bebidas_ui.clear()
	_fx_bebidas.clear()
	var sep_beb: float = 31.0 if num_bebidas >= 3 else 38.0
	var ancho_vaso: float = 38.0
	var total_beb: float = ancho_vaso + sep_beb * float(maxi(0, num_bebidas - 1))
	var x0_beb: float = 526.0 - total_beb * 0.5
	for i in range(num_bebidas):
		_bebidas.append({"estado": "listo", "progreso": 1.0})
		_fx_bebidas.append(0.0)
		var nodo := ArteCocina.Bebida.new()
		nodo.name = "Bebida_%d" % i
		nodo.position = Vector2(x0_beb + sep_beb * float(i), 528.0)
		nodo.size = Vector2(ancho_vaso, 62.0)
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
	var celdas_platos: Array[Rect2] = _Disposicion_Bandeja_Platos(num_platos)
	for i in range(num_platos):
		_platos.append({"pan": false, "carnes": 0, "queso": false, "lechuga": false, "tomate": false})
		var nodo := ArteCocina.Plato.new()
		nodo.name = "Plato_%d" % i
		var celda: Rect2 = celdas_platos[i]
		nodo.position = _bandeja_emplatado.position + celda.position
		nodo.size = celda.size
		_contenedor_platos.add_child(nodo)
		_slots_platos_ui.append({
			"nodo": nodo,
			"rect": Rect2(nodo.position, nodo.size),
			"pop": 0.0,
		})

	# --- Plancha (centros en perspectiva 3/4 de cada quemador) ---------------
	for c in _contenedor_plancha.get_children():
		c.queue_free()
	_plancha.clear()
	_slots_plancha_ui.clear()
	_fx_plancha.clear()
	var centros_fogones: Array[Vector2] = [
		Vector2(103.0, 462.0), Vector2(184.0, 468.0),
		Vector2(84.0, 496.0), Vector2(169.0, 505.0)
	]
	for i in range(num_plancha):
		_plancha.append({"estado": "vacio", "progreso": 0.0, "quemado": 0.0, "avisado": false})
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

	# --- Freidora (centros en perspectiva sobre cada cesta) ------------------
	for c in _contenedor_freidora.get_children():
		c.queue_free()
	_freidora.clear()
	_slots_freidora_ui.clear()
	_fx_freidora.clear()
	var centros_cestas: Array[Vector2] = [Vector2(316.0, 504.0), Vector2(370.0, 510.0)]
	for i in range(num_freidora):
		_freidora.append({"estado": "vacio", "progreso": 0.0, "quemado": 0.0, "avisado": false})
		_fx_freidora.append(0.0)
		var nodo := ArteCocina.Punto_Coccion.new()
		nodo.name = "Patatas_%d" % i
		nodo.tipo = "patatas"
		var centro: Vector2 = centros_cestas[i % centros_cestas.size()]
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
	_lbl_estado_platos.text = "EMPLATADO · %d/%d platos" % [num_platos, HUECOS_EMPLATADO]


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
	for i in range(_slots_plancha_ui.size()):
		var idx_fogon: int = i
		_arrastre.registrar_destino(_slots_plancha_ui[i]["rect"],
			{"tipo": "plancha", "indice": i},
			func(payload: Dictionary) -> bool: return _Puede_Cocinar_En_Plancha(payload, idx_fogon))
	for i in range(_slots_freidora_ui.size()):
		var idx_cesta: int = i
		_arrastre.registrar_destino(_slots_freidora_ui[i]["rect"],
			{"tipo": "freidora", "indice": i},
			func(payload: Dictionary) -> bool: return _Puede_Freir_En_Cesta(payload, idx_cesta))
	for i in range(_slots_platos_ui.size()):
		var idx_plato: int = i
		_arrastre.registrar_destino(_slots_platos_ui[i]["rect"],
			{"tipo": "plato", "indice": i},
			func(payload: Dictionary) -> bool: return _Puede_Anadir_A_Plato(payload, idx_plato))
	for i in range(CENTROS_CLIENTES.size()):
		var idx_cliente: int = i
		var acepta_cliente: Callable = func(payload: Dictionary) -> bool:
			return _Puede_Servir_A_Cliente(payload, idx_cliente)
		# Se puede servir soltando sobre el personaje...
		_arrastre.registrar_destino(_Rect_Cliente_Destino(i),
			{"tipo": "cliente", "indice": i}, acepta_cliente)
		# ...o sobre el bocadillo con el pedido que tiene encima.
		_arrastre.registrar_destino(_Rect_Bocadillo_Cliente_Destino(i),
			{"tipo": "cliente", "indice": i}, acepta_cliente)
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
		"textura": ArteCocina.TEX_PLATO_PERSPECTIVA,
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


func _Puede_Cocinar_En_Plancha(payload: Dictionary, indice: int) -> bool:
	if str(payload.get("tipo", "")) != "ingrediente" or str(payload.get("id", "")) != "carne":
		return false
	if indice < 0 or indice >= _plancha.size():
		return false
	return str(_plancha[indice]["estado"]) == "vacio"


func _Puede_Freir_En_Cesta(payload: Dictionary, indice: int) -> bool:
	if str(payload.get("tipo", "")) != "ingrediente" or str(payload.get("id", "")) != "patatas":
		return false
	if indice < 0 or indice >= _freidora.size():
		return false
	return str(_freidora[indice]["estado"]) == "vacio"


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
	var fase_cl: String = str(_slots_clientes_ui[indice].get("fase", ""))
	if fase_cl in ["entrando", "saliendo"]:
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
	if _sfx != null:
		_sfx.reproducir("click", -20.0, 1.25)


func _on_arrastre_cancelado(_payload: Dictionary) -> void:
	pass


func _on_origen_tocado(payload: Dictionary, origen: Dictionary) -> void:
	if not _jugando:
		return
	var datos: Dictionary = origen.get("datos", {})
	var tipo: String = str(datos.get("tipo", ""))
	if tipo == "bandeja":
		# Tocar un ingrediente hace la acción principal directamente, como en
		# la cocina de referencia: la carne salta a la plancha, las patatas a la
		# freidora y el pan al siguiente plato libre.
		_Accion_Rapida_Ingrediente(str(datos.get("ingrediente", "")))
		return
	if _sfx != null:
		_sfx.reproducir("click", -22.0, 1.4)
	var nodo: Control = null
	match tipo:
		"plancha":
			nodo = _slots_plancha_ui[int(datos.get("indice", 0))]["nodo"]
		"freidora":
			nodo = _slots_freidora_ui[int(datos.get("indice", 0))]["nodo"]
		"bebida":
			nodo = _slots_bebidas_ui[int(datos.get("indice", 0))]["nodo"]
		"plato":
			nodo = _slots_platos_ui[int(datos.get("indice", 0))]["nodo"]
	if nodo != null:
		var pista: String = str(payload.get("pista", "Mantén pulsado y arrastra"))
		_Mostrar_Feedback_En_Control(nodo, pista, Color("#fde68a"), -12.0)


func _Accion_Rapida_Ingrediente(ing: String) -> void:
	if ing == "":
		return
	if _sfx != null:
		_sfx.reproducir("click", -22.0, 1.4)
	match ing:
		"pan":
			var idx_plato: int = _Primer_Plato_Sin_Pan()
			if idx_plato >= 0:
				if _Soltar_En_Plato({"tipo": "ingrediente", "id": "pan"}, idx_plato):
					_Animar_Ingrediente_A_Rect("pan", _Rect_Bandeja("pan"),
						_slots_platos_ui[idx_plato]["rect"])
			else:
				_Mostrar_Feedback_En_Control(_Nodo_Puesto("pan"),
					"Todos los platos tienen pan", Estilos_UI.AVISO, -8.0)
		"carne":
			var idx_fogon: int = _Primer_Hueco_Plancha()
			if idx_fogon >= 0:
				if _Soltar_En_Plancha({"tipo": "ingrediente", "id": "carne"}, idx_fogon):
					_Animar_Ingrediente_A_Rect("carne", _Rect_Bandeja("carne"),
						_slots_plancha_ui[idx_fogon]["rect"])
			else:
				_Soltar_En_Plancha({"tipo": "ingrediente", "id": "carne"})
		"patatas":
			var idx_cesta: int = _Primer_Hueco_Freidora()
			if idx_cesta >= 0:
				if _Soltar_En_Freidora({"tipo": "ingrediente", "id": "patatas"}, idx_cesta):
					_Animar_Ingrediente_A_Rect("patatas", _Rect_Bandeja("patatas"),
						_slots_freidora_ui[idx_cesta]["rect"])
			else:
				_Soltar_En_Freidora({"tipo": "ingrediente", "id": "patatas"})
		"queso", "lechuga", "tomate":
			for idx in _Orden_Busqueda_Platos():
				if bool(_platos[idx]["pan"]) and not bool(_platos[idx][ing]):
					if _Soltar_En_Plato({"tipo": "ingrediente", "id": ing}, idx):
						_Animar_Ingrediente_A_Rect(ing, _Rect_Bandeja(ing),
							_slots_platos_ui[idx]["rect"])
					return
			if _Primer_Plato_Sin_Pan() >= 0:
				_Mostrar_Feedback_En_Control(_Nodo_Puesto(ing),
					"Pon pan primero", Estilos_UI.AVISO, -8.0)
			else:
				_Mostrar_Feedback_En_Control(_Nodo_Puesto(ing),
					"Ese plato ya lo tiene", Estilos_UI.TINTA_SUAVE, -8.0)


func _Primer_Plato_Sin_Pan() -> int:
	for idx in _Orden_Busqueda_Platos():
		if not bool(_platos[idx]["pan"]):
			return idx
	return -1


func _Primer_Hueco_Plancha() -> int:
	for i in range(_plancha.size()):
		if str(_plancha[i]["estado"]) == "vacio":
			return i
	return -1


func _Primer_Hueco_Freidora() -> int:
	for i in range(_freidora.size()):
		if str(_freidora[i]["estado"]) == "vacio":
			return i
	return -1


func _Nodo_Puesto(ing: String) -> Control:
	for item in _bandeja_items_ui:
		if str(item["ingrediente"]) == ing:
			return item["nodo"]
	return null


## Vuelo corto del ingrediente desde su recipiente hasta la estación. Refuerza
## la respuesta al toque sin esperar al final de la animación para aplicar el
## estado: la comida ya está colocada cuando el jugador levanta el dedo.
func _Animar_Ingrediente_A_Rect(ing: String, desde: Rect2, hasta: Rect2) -> void:
	if _capa_feedback == null or _vista_cocina == null:
		return
	var tex: Texture2D = ArteCocina.textura_item(ing)
	if tex == null:
		return
	var tam := Vector2(64.0, 46.0)
	if ing == "pan":
		tam = Vector2(66.0, 42.0)
	elif ing == "patatas":
		tam = Vector2(58.0, 58.0)
	elif ing in ["queso", "lechuga", "tomate"]:
		tam = Vector2(54.0, 40.0)
	var nodo := TextureRect.new()
	nodo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	nodo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	nodo.texture = tex
	nodo.size = tam
	nodo.position = _vista_cocina.global_position + desde.get_center() - tam * 0.5
	nodo.pivot_offset = tam * 0.5
	nodo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_capa_feedback.add_child(nodo)
	var destino: Vector2 = _vista_cocina.global_position + hasta.get_center() - tam * 0.5
	var tw := nodo.create_tween()
	tw.set_parallel(true)
	tw.tween_property(nodo, "position", destino, 0.24) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(nodo, "scale", Vector2(0.72, 0.72), 0.24)
	tw.tween_property(nodo, "modulate:a", 0.0, 0.10).set_delay(0.14)
	tw.chain().tween_callback(nodo.queue_free)


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
			return _Soltar_En_Plancha(payload, int(datos.get("indice", -1)))
		"freidora":
			return _Soltar_En_Freidora(payload, int(datos.get("indice", -1)))
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


func _Soltar_En_Plancha(payload: Dictionary, indice: int = -1) -> bool:
	if str(payload.get("tipo", "")) != "ingrediente" or str(payload.get("id", "")) != "carne":
		return false
	if indice >= 0 and indice < _plancha.size() and str(_plancha[indice]["estado"]) == "vacio":
		var i_fijo: int = indice
		_plancha[i_fijo]["estado"] = "cocinando"
		_plancha[i_fijo]["progreso"] = 0.0
		_plancha[i_fijo]["quemado"] = 0.0
		_plancha[i_fijo]["avisado"] = false
		_Actualizar_Slot_Coccion_UI(_plancha[i_fijo], _slots_plancha_ui[i_fijo], "Carne")
		_efectos.vapor(_slots_plancha_ui[i_fijo]["rect"].get_center() + Vector2(0.0, -8.0))
		_Mostrar_Feedback_En_Control(_slots_plancha_ui[i_fijo]["nodo"], "¡A la plancha!", Color("#fdba74"), -8.0)
		if _sfx != null:
			_sfx.reproducir("sizzle", -16.0, randf_range(0.95, 1.06))
		return true
	for i in range(_plancha.size()):
		if str(_plancha[i]["estado"]) == "vacio":
			_plancha[i]["estado"] = "cocinando"
			_plancha[i]["progreso"] = 0.0
			_plancha[i]["quemado"] = 0.0
			_plancha[i]["avisado"] = false
			_Actualizar_Slot_Coccion_UI(_plancha[i], _slots_plancha_ui[i], "Carne")
			_efectos.vapor(Vector2(_slots_plancha_ui[i]["rect"].get_center().x,
				_slots_plancha_ui[i]["rect"].get_center().y - 10.0))
			_Mostrar_Feedback_En_Control(_slots_plancha_ui[i]["nodo"], "¡A la plancha!", Color("#fdba74"), -8.0)
			if _sfx != null:
				_sfx.reproducir("sizzle", -16.0, randf_range(0.95, 1.06))
			return true
	_Mostrar_Feedback_En_Control(_slots_plancha_ui[0]["nodo"], "Plancha llena", Estilos_UI.AVISO)
	return false


func _Soltar_En_Freidora(payload: Dictionary, indice: int = -1) -> bool:
	if str(payload.get("tipo", "")) != "ingrediente" or str(payload.get("id", "")) != "patatas":
		return false
	if indice >= 0 and indice < _freidora.size() and str(_freidora[indice]["estado"]) == "vacio":
		var i_fijo: int = indice
		_freidora[i_fijo]["estado"] = "cocinando"
		_freidora[i_fijo]["progreso"] = 0.0
		_freidora[i_fijo]["quemado"] = 0.0
		_freidora[i_fijo]["avisado"] = false
		_Actualizar_Slot_Coccion_UI(_freidora[i_fijo], _slots_freidora_ui[i_fijo], "Patatas")
		_Mostrar_Feedback_En_Control(_slots_freidora_ui[i_fijo]["nodo"], "¡A freír!", Color("#fdba74"), -8.0)
		if _sfx != null:
			_sfx.reproducir("sizzle", -17.0, randf_range(0.95, 1.06))
		return true
	for i in range(_freidora.size()):
		if str(_freidora[i]["estado"]) == "vacio":
			_freidora[i]["estado"] = "cocinando"
			_freidora[i]["progreso"] = 0.0
			_freidora[i]["quemado"] = 0.0
			_freidora[i]["avisado"] = false
			_Actualizar_Slot_Coccion_UI(_freidora[i], _slots_freidora_ui[i], "Patatas")
			_Mostrar_Feedback_En_Control(_slots_freidora_ui[i]["nodo"], "¡A freír!", Color("#fdba74"), -8.0)
			if _sfx != null:
				_sfx.reproducir("sizzle", -17.0, randf_range(0.95, 1.06))
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
	if _sfx != null:
		_sfx.reproducir("pop", -12.0, randf_range(0.94, 1.08))
	_Actualizar_Plato_UI(indice)
	var receta: String = _Receta_De_Plato(p)
	if receta != "":
		_efectos.estrellas(_slots_platos_ui[indice]["rect"].get_center(), 4)
		if _sfx != null:
			_sfx.reproducir("ding", -15.0, 1.07)
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
	if _sfx != null:
		_sfx.reproducir("coin", -13.0, randf_range(0.97, 1.06))
		if limpiar_bebida >= 0:
			_sfx.reproducir("pour", -18.0)

	# El plato/vaso/cesta vuela visualmente hasta el cliente
	if limpiar_plato:
		_Animar_Entrega_Desde_Plato(int(payload.get("indice", -1)), indice)
	elif limpiar_freidora >= 0 and limpiar_freidora < _slots_freidora_ui.size():
		_Animar_Entrega_Desde_Estacion(ArteCocina.TEX_PATATAS,
			_slots_freidora_ui[limpiar_freidora]["rect"], indice, Vector2(62.0, 62.0))
	elif limpiar_bebida >= 0 and limpiar_bebida < _slots_bebidas_ui.size():
		_Animar_Entrega_Desde_Estacion(ArteCocina.TEX_REFRESCO,
			_slots_bebidas_ui[limpiar_bebida]["rect"], indice, Vector2(38.0, 58.0))

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


func _Animar_Entrega_Desde_Plato(indice_plato: int, indice_cliente: int) -> void:
	if indice_plato < 0 or indice_plato >= _platos.size() or _capa_feedback == null:
		return
	var p: Dictionary = _platos[indice_plato]
	var ui: Dictionary = _slots_platos_ui[indice_plato]
	var plato := ArteCocina.Plato.new()
	plato.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plato.pan = bool(p["pan"])
	plato.carnes = int(p["carnes"])
	plato.queso = bool(p["queso"])
	plato.lechuga = bool(p["lechuga"])
	plato.tomate = bool(p["tomate"])
	plato.size = Vector2(120.0, 132.0)
	plato.position = _vista_cocina.global_position + (ui["rect"] as Rect2).get_center() - plato.size * 0.5
	plato.pivot_offset = plato.size * 0.5
	_capa_feedback.add_child(plato)
	_Animar_Vuelo_Al_Cliente(plato, indice_cliente)


func _Animar_Entrega_Desde_Estacion(tex: Texture2D, rect_origen: Rect2,
		indice_cliente: int, tam: Vector2) -> void:
	if _capa_feedback == null:
		return
	var nodo := TextureRect.new()
	nodo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	nodo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	nodo.texture = tex
	nodo.size = tam
	nodo.position = _vista_cocina.global_position + rect_origen.get_center() - tam * 0.5
	nodo.pivot_offset = tam * 0.5
	nodo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_capa_feedback.add_child(nodo)
	_Animar_Vuelo_Al_Cliente(nodo, indice_cliente)


func _Animar_Vuelo_Al_Cliente(nodo: Control, indice_cliente: int) -> void:
	if indice_cliente < 0 or indice_cliente >= _slots_clientes_ui.size():
		nodo.queue_free()
		return
	var retrato: Control = _slots_clientes_ui[indice_cliente]["retrato"]
	var destino: Vector2 = retrato.get_global_rect().get_center() - nodo.size * 0.5
	var tw := nodo.create_tween()
	tw.set_parallel(true)
	tw.tween_property(nodo, "position", destino, 0.38)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(nodo, "scale", Vector2(0.55, 0.55), 0.38)
	tw.tween_property(nodo, "rotation", randf_range(-0.12, 0.12), 0.38)
	tw.tween_property(nodo, "modulate:a", 0.0, 0.12).set_delay(0.26)
	tw.chain().tween_callback(func():
		_efectos.frescura(_Posicion_Local(retrato.get_global_rect().get_center()))
		nodo.queue_free())


func _Soltar_En_Papelera(payload: Dictionary) -> bool:
	var merma_antes: int = _desperdicio_valor
	match str(payload.get("tipo", "")):
		"plato":
			var idx: int = int(payload.get("indice", -1))
			if idx >= 0 and idx < _platos.size():
				_Registrar_Merma_Plato(idx)
				_Limpiar_Plato(idx)
		"carne_lista", "carne_quemada":
			var idx_c: int = int(payload.get("indice", -1))
			if idx_c >= 0 and idx_c < _plancha.size():
				_desperdicio_valor += 6
				_plancha[idx_c]["estado"] = "vacio"
				_plancha[idx_c]["progreso"] = 0.0
				_plancha[idx_c]["quemado"] = 0.0
				_Actualizar_Slot_Coccion_UI(_plancha[idx_c], _slots_plancha_ui[idx_c], "Carne")
		"patatas_listas", "patatas_quemadas":
			var idx_f: int = int(payload.get("indice", -1))
			if idx_f >= 0 and idx_f < _freidora.size():
				_desperdicio_valor += 8
				_freidora[idx_f]["estado"] = "vacio"
				_freidora[idx_f]["progreso"] = 0.0
				_freidora[idx_f]["quemado"] = 0.0
				_Actualizar_Slot_Coccion_UI(_freidora[idx_f], _slots_freidora_ui[idx_f], "Patatas")
		"bebida":
			var idx_b: int = int(payload.get("indice", -1))
			if idx_b >= 0 and idx_b < _bebidas.size():
				_desperdicio_valor += 6
				_bebidas[idx_b]["estado"] = "llenando"
				_bebidas[idx_b]["progreso"] = 0.0
				_Actualizar_Bebida_UI(idx_b)
		_:
			pass
	_efectos.humo(_papelera_rect.get_center())
	_Bounce_Control(_papelera_root, 0.08, 0.16)
	if _sfx != null:
		_sfx.reproducir("trash", -13.0)
	var coste_merma: int = Sistema_Cocina.Calcular_Coste_Merma(_desperdicio_valor - merma_antes)
	var txt_merma: String = "Descartado"
	if coste_merma > 0:
		txt_merma = "Descartado · −%d € ingredientes" % coste_merma
	_Mostrar_Feedback_En_Control(_papelera_root, txt_merma, Estilos_UI.TINTA_SUAVE, -10.0)
	return true


## Valor de venta del plato tirado, para descontar después el 30% de coste de
## ingredientes. Un plato incompleto se estima en 4 € para no salir gratis.
func _Registrar_Merma_Plato(indice: int) -> void:
	if indice < 0 or indice >= _platos.size():
		return
	var receta: String = _Receta_De_Plato(_platos[indice])
	if receta == "":
		_desperdicio_valor += 4
		return
	var rec: Dictionary = Sistema_Cocina.RECETAS_BURGER_STREET.get(receta, {})
	_desperdicio_valor += Sistema_Cocina.Calcular_Precio_Plato(
		int(rec.get("precio_base", 4)), _nv_ingredientes)


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
	_tiempo_servicio += delta
	if _combo_timer > 0.0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			_combo_actual = 0

	# Reparto de los clientes que faltan por llegar. La partida no tiene
	# límite de tiempo: acaba cuando ya no queda nadie por atender.
	if _clientes_pendientes > 0:
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:
			if _Intentar_Spawnear_Cliente():
				var base_int: float = float(_cfg_nivel_actual.get("intervalo_spawn", 5.0))
				_spawn_timer = _rng.randf_range(base_int * 0.85, base_int * 1.15)
			else:
				_spawn_timer = 1.0

	# Paciencia de clientes
	for i in range(_clientes.size()):
		var cl: Dictionary = _clientes[i]
		if not bool(cl["activo"]):
			continue
		if str(_slots_clientes_ui[i].get("fase", "")) == "entrando":
			continue
		cl["paciencia"] = float(cl["paciencia"]) - delta * _velocidad_paciencia
		if float(cl["paciencia"]) <= 0.0:
			cl["activo"] = false
			_combo_actual = 0
			_combo_timer = 0.0
			_efectos.enfado(_slots_clientes_ui[i]["centro"], 4)
			_Mostrar_Chef("enfadada", "¡Se ha marchado sin comer!", Estilos_UI.PELIGRO, 1.5)
			_Actualizar_Cliente_UI(i)
		else:
			_Actualizar_Paciencia_Cliente_UI(i)

	# Fases de entrada/salida de los clientes (celebran o se van con animación)
	for i in range(_clientes.size()):
		var ui_cl: Dictionary = _slots_clientes_ui[i]
		var fase_cl: String = str(ui_cl.get("fase", "inactivo"))
		if fase_cl == "saliendo" and _anim_tiempo >= float(ui_cl.get("salida_hasta", 0.0)):
			_Animar_Salida_Cliente(i)
		elif fase_cl == "entrando" and _anim_tiempo >= float(ui_cl.get("entrada_hasta", 0.0)):
			ui_cl["fase"] = "esperando"

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
				var nodo_b: ArteCocina.Bebida = _slots_bebidas_ui[i]["nodo"]
				nodo_b.pop = 1.0
				_efectos.frescura(_slots_bebidas_ui[i]["rect"].get_center())
				if _sfx != null:
					_sfx.reproducir("pop", -15.0, 1.15)
			_Actualizar_Bebida_UI(i)

	_Animar_Escena(delta)
	_tutorial_timer -= delta
	if _tutorial_timer <= 0.0:
		_tutorial_timer = 0.15
		_Actualizar_Tutorial()
	if _tutorial_foco != null and _tutorial_foco.visible:
		_tutorial_foco.tiempo = _anim_tiempo
		_tutorial_foco.queue_redraw()

	_reloj_sim_refresh -= delta
	if _reloj_sim_refresh <= 0.0:
		_reloj_sim_refresh = 0.5
		_lbl_cocina_reloj_sim.text = Funciones_Globales.Convertir_Minuto_A_Fecha_Hora(
			Variables_Dinamicas.Minute_Day * 1440 + Variables_Dinamicas.Minute_Minute)

	_Actualizar_HUD_Cocina()

	# Sacudida de pantalla (quemados, clientes enfadados)
	if _shake_t > 0.0:
		_shake_t = maxf(0.0, _shake_t - delta)
		var amp: float = _shake_fuerza * (_shake_t / maxf(0.01, _shake_duracion))
		_vista_cocina.position = _origen_vista + Vector2(
			randf_range(-amp, amp), randf_range(-amp, amp))
	else:
		_vista_cocina.position = _origen_vista

	if _Nivel_Completado():
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
		if retrato.feliz > 0.0:
			retrato.feliz = maxf(0.0, retrato.feliz - delta * 1.15)
		# Ticket: se ladea y tiembla cuando la paciencia baja
		if str(ui.get("fase", "")) == "esperando" and bool(_clientes[i]["activo"]):
			var pos_t: Vector2 = ui["pos_ticket"]
			var ratio_p: float = ticket.ratio
			var inquieto: float = clampf(1.0 - ratio_p, 0.0, 1.0)
			ticket.position.x = pos_t.x + sin(_anim_tiempo * (4.0 + 6.0 * inquieto)) * (0.8 + 3.0 * inquieto)
			ticket.rotation = sin(_anim_tiempo * 2.2) * 0.010 * inquieto
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

	# Pase: los candados de los huecos bloqueados laten suavemente.
	if _bandeja_emplatado != null:
		_bandeja_emplatado.tiempo = _anim_tiempo
		_bandeja_emplatado.queue_redraw()

	# Bebidas
	for i in range(_bebidas.size()):
		var bebida: ArteCocina.Bebida = _slots_bebidas_ui[i]["nodo"]
		bebida.tiempo = _anim_tiempo
		bebida.pop = maxf(0.0, bebida.pop - delta * 2.6)
		bebida.queue_redraw()

	# Plancha: vapor, humo y chispas
	for i in range(_plancha.size()):
		var estado: String = str(_plancha[i]["estado"])
		if estado == "vacio":
			continue
		var nodo: ArteCocina.Punto_Coccion = _slots_plancha_ui[i]["nodo"]
		nodo.tiempo = _anim_tiempo
		nodo.flip = maxf(0.0, nodo.flip - delta * 3.4)
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
		var nodo_f: ArteCocina.Punto_Coccion = _slots_freidora_ui[i]["nodo"]
		nodo_f.tiempo = _anim_tiempo
		nodo_f.flip = maxf(0.0, nodo_f.flip - delta * 3.4)
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

	# Hover de los depósitos de ingredientes
	var raton: Vector2 = _Posicion_Raton_Local()
	for item in _bandeja_items_ui:
		var nodo_item: ArteCocina.Puesto_Ingrediente = item["nodo"]
		var hover: bool = _jugando and (item["rect"] as Rect2).has_point(raton)
		if nodo_item.hover != hover:
			nodo_item.hover = hover
			nodo_item.queue_redraw()
		if nodo_item.hover:
			nodo_item.tiempo = _anim_tiempo
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
				s["avisado"] = false
				var nodo_listo: ArteCocina.Punto_Coccion = ui_lista[i]["nodo"]
				nodo_listo.flip = 1.0
				_efectos.estrellas(ui_lista[i]["rect"].get_center() + Vector2(0.0, -6.0), 3)
				_Mostrar_Feedback_En_Control(nodo_listo, "¡LISTO!", Color("#86efac"), -8.0)
				if _sfx != null:
					_sfx.reproducir("ding", -11.0, randf_range(0.98, 1.04))
			_Actualizar_Slot_Coccion_UI(s, ui_lista[i], etiqueta)
		elif est == "listo" or est == "alerta":
			s["quemado"] = minf(1.0, float(s["quemado"]) + delta / maxf(0.5, _tiempo_quemado))
			if float(s["quemado"]) >= 1.0:
				s["estado"] = "quemado"
				_Mostrar_Feedback_En_Control(ui_lista[i]["nodo"], "¡Quemado!", Estilos_UI.PELIGRO)
				if _anim_tiempo - _ultimo_aviso_quemado > 2.5:
					_ultimo_aviso_quemado = _anim_tiempo
					_Mostrar_Chef("enfadada", "¡Se ha quemado!", Estilos_UI.PELIGRO, 1.2)
					if _sfx != null:
						_sfx.reproducir("burn", -10.0)
					_Sacudir(2.5, 0.20)
				_efectos.humo(ui_lista[i]["rect"].get_center())
			elif float(s["quemado"]) >= umbral_alerta:
				s["estado"] = "alerta"
				if not bool(s.get("avisado", false)):
					s["avisado"] = true
					if _anim_tiempo - _ultimo_aviso_quemado > 2.5:
						_ultimo_aviso_quemado = _anim_tiempo
						_Mostrar_Chef("sorprendida", "¡Se está quemando!", Estilos_UI.AVISO, 1.1)
						_Sacudir(1.4, 0.14)
						if _sfx != null:
							_sfx.reproducir("burn", -17.0)
			_Actualizar_Slot_Coccion_UI(s, ui_lista[i], etiqueta)


func _Intentar_Spawnear_Cliente() -> bool:
	if _clientes_pendientes <= 0:
		return false
	var libres: Array[int] = []
	for i in range(_clientes.size()):
		if bool(_clientes[i]["activo"]):
			continue
		var ui_slot: Dictionary = _slots_clientes_ui[i]
		var fase_slot: String = str(ui_slot.get("fase", "inactivo"))
		if fase_slot in ["entrando", "saliendo"]:
			continue
		if _anim_tiempo < float(ui_slot.get("bloqueado_hasta", 0.0)):
			continue
		libres.append(i)
	if libres.is_empty():
		return false

	var idx: int = libres[_rng.randi() % libres.size()]
	var menu: Array = _cfg_nivel_actual.get("menu", ["burger_sola", "refresco"])
	var max_items: int = clampi(int(_cfg_nivel_actual.get("max_items", 2)), 1, 3)
	var cantidad: int = _rng.randi_range(1, max_items)

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
			elegido = platos_menu[_rng.randi() % platos_menu.size()]
		elif k >= 1 and not extras_menu.is_empty() and _rng.randf() < 0.65:
			elegido = extras_menu[_rng.randi() % extras_menu.size()]
		else:
			elegido = str(menu[_rng.randi() % menu.size()])
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
	cl["variante"] = disp[_rng.randi() % disp.size()] if not disp.is_empty() else (_rng.randi() % 8)

	_clientes_pendientes = maxi(0, _clientes_pendientes - 1)
	_Actualizar_Cliente_UI(idx)
	return true


## Clientes que aún cuentan para la partida: los que no han llegado más los
## que siguen sentados esperando (los que ya se van no cuentan).
func _Clientes_Restantes() -> int:
	var activos: int = 0
	for cl in _clientes:
		if bool(cl["activo"]):
			activos += 1
	return _clientes_pendientes + activos


## La partida termina cuando ya han llegado todos los clientes y ninguno
## sigue en la sala (incluidas las animaciones de entrada y salida).
func _Nivel_Completado() -> bool:
	if _clientes_pendientes > 0:
		return false
	for cl in _clientes:
		if bool(cl["activo"]):
			return false
	for ui in _slots_clientes_ui:
		var fase: String = str(ui.get("fase", "inactivo"))
		if fase == "entrando" or fase == "saliendo":
			return false
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
			_plancha[i]["avisado"] = false
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
			_freidora[i]["avisado"] = false
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
		_desperdicio_valor += 6
		s["estado"] = "vacio"
		s["progreso"] = 0.0
		s["quemado"] = 0.0
		_Actualizar_Slot_Coccion_UI(s, _slots_plancha_ui[indice], "Carne")
		_Mostrar_Feedback_En_Control(_slots_plancha_ui[indice]["nodo"],
			"Descartado · −%d € ingredientes" % Sistema_Cocina.Calcular_Coste_Merma(6),
			Estilos_UI.TINTA_SUAVE)
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
		_desperdicio_valor += 8
		s["estado"] = "vacio"
		s["progreso"] = 0.0
		s["quemado"] = 0.0
		_Actualizar_Slot_Coccion_UI(s, _slots_freidora_ui[indice], "Patatas")
		_Mostrar_Feedback_En_Control(_slots_freidora_ui[indice]["nodo"],
			"Descartado · −%d € ingredientes" % Sistema_Cocina.Calcular_Coste_Merma(8),
			Estilos_UI.TINTA_SUAVE)
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
	var txt_cobro: String = "+%d €" % precio
	if propina > 0:
		txt_cobro += " (+%d € prop.)" % propina
	if _combo_actual >= 2:
		txt_cobro += " · x%d!" % _combo_actual
	_Mostrar_Feedback_En_Control(ancla, txt_cobro, Color("#86efac"), -18.0)

	# Micro-recompensas del Sim por cliente
	var micro: Dictionary = Sistema_Cocina.Procesar_Micro_Recompensa_Cliente(
		_en_turno_partida, _micro_propinas_sesion, {}, _modo_practica_partida)
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
		_Mostrar_Feedback_En_Control(ancla, " · ".join(extras), Color("#fde68a"), 12.0)

	# Fuegos artificiales de monedas, estrellas y reacción del chef
	var centro_cliente: Vector2 = ancla.get_global_rect().get_center()
	var centro_local: Vector2 = _slots_clientes_ui[indice_cliente]["centro"]
	_efectos.monedas(centro_local, 3)
	_efectos.estrellas(centro_local, 5)
	_Lanzar_Monedas(ancla, null, 2)
	if propina > 0 and _propinas_root != null:
		_Lanzar_Monedas(ancla, _propinas_root, 1)
		_Bounce_Control(_propinas_root, 0.12, 0.22)
	if _combo_actual >= 2:
		_Mostrar_Chef("celebra", "¡COMBO x%d! ¡INCREÍBLE!" % _combo_actual, Color("#b91c1c"), 1.5)
		if _sfx != null:
			_sfx.reproducir("combo", -10.0)
	elif ratio >= 0.65:
		_Mostrar_Chef("pulgar", "¡BUEN TRABAJO!", Color("#15803d"), 1.3)
	elif ratio < 0.30:
		_Mostrar_Chef("sorprendida", "¡Por los pelos!", Color("#b45309"), 1.0)

	_Actualizar_Cliente_UI(indice_cliente)
	_Actualizar_HUD_Cocina()


# ============================================================================
# Actualización Visual de HUD y Estaciones
# ============================================================================

func _Actualizar_HUD_Cocina() -> void:
	var segs: int = int(floor(_tiempo_servicio))
	_lbl_cocina_reloj.text = "%02d:%02d" % [segs / 60, segs % 60]
	_lbl_cocina_reloj.add_theme_color_override("font_color", Color.WHITE)
	_lbl_cocina_clientes.text = "%d" % _Clientes_Restantes()
	_lbl_cocina_clientes.add_theme_color_override("font_color",
		Color("#bbf7d0") if _Clientes_Restantes() == 0 else Color.WHITE)

	var m1: int = int(_cfg_nivel_actual.get("meta_1", 55))
	var m2: int = int(_cfg_nivel_actual.get("meta_2", 85))
	var m3: int = int(_cfg_nivel_actual.get("meta_3", 115))
	_bar_cocina_meta.max_value = float(maxi(1, m3))
	_bar_cocina_meta.value = minf(float(m3), float(_recaudacion))
	_lbl_cocina_recaudacion.text = "%d €" % _recaudacion
	_lbl_cocina_propinas.text = "+%d €" % _propinas_servicio
	_lbl_estado_propinas.text = "%d €" % _propinas_servicio

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
				if _sfx != null:
					_sfx.reproducir("star", -10.0)

	if _combo_actual >= 2 and _combo_timer > 0.0:
		_pill_cocina_combo.visible = true
		_lbl_cocina_combo.text = "COMBO x%d" % _combo_actual
		if _bar_cocina_combo != null:
			_bar_cocina_combo.value = clampf(_combo_timer / VENTANA_COMBO_SEG, 0.0, 1.0) * 100.0
		_pill_cocina_combo.pivot_offset = _pill_cocina_combo.size * 0.5
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
	var retrato: ArteCocina.Retrato = ui["retrato"]
	var ticket: ArteCocina.Ticket = ui["ticket"]

	if bool(cl["activo"]):
		var reiniciar: bool = (not bool(ui["visible_antes"])) \
			or str(ui["fase"]) in ["inactivo", "saliendo"]
		if reiniciar:
			_Preparar_Entrada_Cliente(indice)
			ui["visible_antes"] = true
			ui["fase"] = "entrando"

		retrato.visible = true
		ticket.visible = not reiniciar
		retrato.variante = int(cl.get("variante", indice))
		ticket.items = (cl["items"] as Array).duplicate()
		ticket.entregados = (cl["entregados"] as Array).duplicate()
		ticket.destacado = false
		ticket.tiempo = _anim_tiempo

		if reiniciar:
			retrato.ratio = 1.0
			retrato.rebote = 0.0
			retrato.feliz = 0.0
			ticket.ratio = 1.0
			_Animar_Entrada_Cliente(indice)
		_Actualizar_Paciencia_Cliente_UI(indice)
		return

	# Cliente inactivo: celebrar/salir con temporización para que se vea la reacción
	if not bool(ui["visible_antes"]) or str(ui["fase"]) in ["inactivo", "saliendo"]:
		return
	var ratio: float = clampf(float(cl["paciencia"]) / maxf(1.0, float(cl["paciencia_max"])), 0.0, 1.0)
	var se_va_feliz: bool = ratio > 0.001
	ui["fase"] = "saliendo"
	ui["tipo_salida"] = "feliz" if se_va_feliz else "enfadado"
	ui["salida_hasta"] = _anim_tiempo + (0.85 if se_va_feliz else 0.50)
	_Reaccion_Salida_Cliente(indice, se_va_feliz)


func _Preparar_Entrada_Cliente(indice: int) -> void:
	var ui: Dictionary = _slots_clientes_ui[indice]
	var retrato: ArteCocina.Retrato = ui["retrato"]
	var ticket: ArteCocina.Ticket = ui["ticket"]
	var tween_prev: Tween = ui.get("tween", null)
	if tween_prev != null and tween_prev.is_valid():
		tween_prev.kill()
	retrato.position = Vector2(-250.0, (ui["pos_retrato"] as Vector2).y)
	retrato.modulate = Color.WHITE
	retrato.rotation = 0.0
	retrato.scale = Vector2.ONE
	retrato.ratio = 1.0
	retrato.rebote = 0.0
	retrato.feliz = 0.0
	retrato.caminando = 0.0
	ticket.visible = false
	ticket.position = ui["pos_ticket"]
	ticket.modulate = Color(1, 1, 1, 0)
	ticket.scale = Vector2.ONE
	ticket.rotation = 0.0
	ticket.ratio = 1.0
	ticket.pivot_offset = ticket.size * 0.5
	ui["aviso_media"] = false
	ui["aviso_baja"] = false


func _Animar_Entrada_Cliente(indice: int) -> void:
	var ui: Dictionary = _slots_clientes_ui[indice]
	var retrato: ArteCocina.Retrato = ui["retrato"]
	var ticket: ArteCocina.Ticket = ui["ticket"]
	var tween_prev: Tween = ui.get("tween", null)
	if tween_prev != null and tween_prev.is_valid():
		tween_prev.kill()

	var pos_r: Vector2 = ui["pos_retrato"]
	var pos_t: Vector2 = ui["pos_ticket"]
	retrato.position = Vector2(-250.0, pos_r.y)
	retrato.rotation = 0.0
	retrato.scale = Vector2.ONE
	retrato.modulate = Color.WHITE
	retrato.ratio = 1.0
	retrato.rebote = 0.0
	retrato.feliz = 0.0
	retrato.caminando = 1.0
	retrato.visible = true
	ticket.visible = false
	ticket.position = pos_t
	ticket.modulate = Color(1, 1, 1, 0)
	ticket.scale = Vector2(0.78, 0.78)
	ticket.pivot_offset = ticket.size * 0.5

	# Caminata desde el borde izquierdo hasta su mesa
	var distancia: float = pos_r.x + 250.0
	var duracion: float = clampf(distancia / 620.0, 0.75, 2.4)
	var tw := create_tween()
	tw.tween_property(retrato, "position:x", pos_r.x, duracion)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(_Llegada_Cliente.bind(indice))
	ui["tween"] = tw
	ui["entrada_hasta"] = _anim_tiempo + duracion
	ui["fase"] = "entrando"


func _Llegada_Cliente(indice: int) -> void:
	if indice < 0 or indice >= _slots_clientes_ui.size():
		return
	var ui: Dictionary = _slots_clientes_ui[indice]
	var retrato: ArteCocina.Retrato = ui["retrato"]
	var ticket: ArteCocina.Ticket = ui["ticket"]
	retrato.position = ui["pos_retrato"]
	retrato.caminando = 0.0
	retrato.ratio = 1.0
	retrato.feliz = 0.75
	ticket.visible = true
	ticket.position = ui["pos_ticket"]
	ticket.modulate = Color(1, 1, 1, 0)
	ticket.scale = Vector2(0.78, 0.78)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(ticket, "modulate:a", 1.0, 0.22)
	tw.tween_property(ticket, "scale", Vector2.ONE, 0.42)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_Mostrar_Bocadillo_Cliente(indice, "¡Hola!", Color("#b45309"))
	if _sfx != null:
		_sfx.reproducir("pop", -19.0, 1.25)
	# Pequeño saludo con la cabeza al sentarse
	var saludo := create_tween()
	saludo.tween_property(retrato, "rotation", -0.055, 0.16).set_trans(Tween.TRANS_SINE)
	saludo.tween_property(retrato, "rotation", 0.028, 0.20).set_trans(Tween.TRANS_SINE)
	saludo.tween_property(retrato, "rotation", 0.0, 0.14).set_trans(Tween.TRANS_SINE)
	if str(ui.get("fase", "")) == "entrando":
		ui["fase"] = "esperando"
	ui["entrada_hasta"] = _anim_tiempo


func _Reaccion_Salida_Cliente(indice: int, feliz: bool) -> void:
	var ui: Dictionary = _slots_clientes_ui[indice]
	var retrato: ArteCocina.Retrato = ui["retrato"]
	var ticket: ArteCocina.Ticket = ui["ticket"]
	var cl: Dictionary = _clientes[indice]

	if feliz:
		retrato.feliz = 1.0
		retrato.rebote = 1.0
		retrato.ratio = 1.0
		ticket.ratio = 1.0
		var entregados_ok: Array[bool] = []
		for _k in range((cl["items"] as Array).size()):
			entregados_ok.append(true)
		ticket.entregados = entregados_ok
		_Mostrar_Bocadillo_Cliente(indice, "¡Gracias!", Color("#15803d"))
		if _sfx != null:
			_sfx.reproducir("happy", -12.0)
		# Pequeña animación de masticar/celebrar
		var tw_comer := create_tween()
		for _k in range(3):
			tw_comer.tween_property(retrato, "scale", Vector2(1.02, 0.97), 0.09)\
				.set_trans(Tween.TRANS_SINE)
			tw_comer.tween_property(retrato, "scale", Vector2.ONE, 0.09)\
				.set_trans(Tween.TRANS_SINE)
		_efectos.estrellas(ui["centro"], 7)
		_efectos.monedas(ui["centro"], 4)
		_efectos.frescura(retrato.get_global_rect().get_center() - _vista_cocina.global_position)
		# Balanceo de felicidad
		var tw := create_tween()
		tw.tween_property(retrato, "rotation", -0.06, 0.14).set_trans(Tween.TRANS_SINE)
		tw.tween_property(retrato, "rotation", 0.06, 0.18).set_trans(Tween.TRANS_SINE)
		tw.tween_property(retrato, "rotation", -0.03, 0.14).set_trans(Tween.TRANS_SINE)
		tw.tween_property(retrato, "rotation", 0.0, 0.12).set_trans(Tween.TRANS_SINE)
	else:
		retrato.feliz = 0.0
		retrato.rebote = 0.0
		retrato.ratio = 0.0
		ticket.ratio = 0.0
		_Mostrar_Bocadillo_Cliente(indice, "¡Me voy!", Color("#b91c1c"))
		if _sfx != null:
			_sfx.reproducir("angry", -11.0)
		_efectos.enfado(ui["centro"], 4)
		_Sacudir(3.0, 0.22)
		var tw_enf := create_tween()
		var pos_x: float = ui["pos_retrato"].x
		for _k in range(2):
			tw_enf.tween_property(retrato, "position:x", pos_x - 7.0, 0.05)
			tw_enf.tween_property(retrato, "position:x", pos_x + 7.0, 0.05)
		tw_enf.tween_property(retrato, "position:x", pos_x, 0.06)


func _Animar_Salida_Cliente(indice: int) -> void:
	var ui: Dictionary = _slots_clientes_ui[indice]
	var feliz: bool = str(ui.get("tipo_salida", "feliz")) == "feliz"
	ui["tipo_salida"] = ""
	var retrato: ArteCocina.Retrato = ui["retrato"]
	var ticket: ArteCocina.Ticket = ui["ticket"]
	var tween_prev: Tween = ui.get("tween", null)
	if tween_prev != null and tween_prev.is_valid():
		tween_prev.kill()

	var pos_r: Vector2 = ui["pos_retrato"]
	var pos_t: Vector2 = ui["pos_ticket"]
	retrato.visible = true
	retrato.position.y = pos_r.y
	retrato.rotation = 0.0
	retrato.scale = Vector2.ONE
	retrato.caminando = 1.0 if feliz else 1.18

	# El ticket y el bocadillo se quedan en la mesa; el cliente se va andando
	if ticket.visible:
		var tw_ticket := create_tween()
		tw_ticket.tween_property(ticket, "modulate:a", 0.0, 0.18)
		tw_ticket.tween_callback(func():
			ticket.visible = false
			ticket.modulate = Color.WHITE
			ticket.position = pos_t
			ticket.scale = Vector2.ONE)
	if ui.get("bocadillo", null) != null and is_instance_valid(ui["bocadillo"]):
		var tw_boc := create_tween()
		tw_boc.tween_property(ui["bocadillo"], "modulate:a", 0.0, 0.22)

	var destino_x: float = 1280.0 + 260.0
	var distancia: float = destino_x - retrato.position.x
	var duracion: float = clampf(distancia / 450.0, 0.85, 2.8)
	ui["fase"] = "saliendo"
	ui["salida_hasta"] = _anim_tiempo + duracion + 0.6
	ui["bloqueado_hasta"] = _anim_tiempo + duracion + 0.7

	var tw := create_tween()
	tw.tween_property(retrato, "position:x", destino_x, duracion)\
		.set_trans(Tween.TRANS_LINEAR)
	tw.tween_callback(_Fin_Salida_Cliente.bind(indice))
	ui["tween"] = tw


func _Fin_Salida_Cliente(indice: int) -> void:
	if indice < 0 or indice >= _slots_clientes_ui.size():
		return
	var ui: Dictionary = _slots_clientes_ui[indice]
	var retrato: ArteCocina.Retrato = ui["retrato"]
	var ticket: ArteCocina.Ticket = ui["ticket"]
	if ui.get("bocadillo", null) != null and is_instance_valid(ui["bocadillo"]):
		ui["bocadillo"].queue_free()
		ui["bocadillo"] = null
	retrato.visible = false
	retrato.position = ui["pos_retrato"]
	retrato.rotation = 0.0
	retrato.scale = Vector2.ONE
	retrato.modulate = Color.WHITE
	retrato.caminando = 0.0
	retrato.feliz = 0.0
	retrato.rebote = 0.0
	retrato.ratio = 1.0
	ticket.visible = false
	ticket.position = ui["pos_ticket"]
	ticket.modulate = Color.WHITE
	ticket.scale = Vector2.ONE
	ticket.rotation = 0.0
	ui["visible_antes"] = false
	ui["fase"] = "inactivo"
	ui["bloqueado_hasta"] = _anim_tiempo + 0.1


func _Mostrar_Bocadillo_Cliente(indice: int, texto: String, color: Color) -> void:
	if _capa_feedback == null or indice < 0 or indice >= _slots_clientes_ui.size():
		return
	var ui: Dictionary = _slots_clientes_ui[indice]
	var retrato: ArteCocina.Retrato = ui["retrato"]
	if not retrato.visible:
		return
	if ui.get("bocadillo", null) != null and is_instance_valid(ui["bocadillo"]):
		ui["bocadillo"].queue_free()
		ui["bocadillo"] = null

	var raiz := Control.new()
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.size = Vector2(172.0, 50.0)

	var panel := PanelContainer.new()
	panel.position = Vector2.ZERO
	panel.size = Vector2(172.0, 34.0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := Estilos_UI.caja(Color("#fffdf5"), 11, color, 2, 0)
	st.content_margin_left = 8
	st.content_margin_right = 8
	st.content_margin_top = 3
	st.content_margin_bottom = 3
	panel.add_theme_stylebox_override("panel", st)
	var lbl := Estilos_UI.texto(texto, 13, color, 700)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(lbl)
	raiz.add_child(panel)

	var cola := Polygon2D.new()
	cola.polygon = PackedVector2Array([
		Vector2(26.0, 33.0), Vector2(50.0, 33.0), Vector2(34.0, 48.0)
	])
	cola.color = Color("#fffdf5")
	raiz.add_child(cola)
	var borde_cola := Line2D.new()
	borde_cola.points = PackedVector2Array([
		Vector2(26.0, 33.0), Vector2(34.0, 48.0), Vector2(50.0, 33.0)
	])
	borde_cola.width = 2.0
	borde_cola.default_color = color
	raiz.add_child(borde_cola)

	var rect: Rect2 = retrato.get_global_rect()
	var x_min: float = _origen_vista.x + 10.0
	var x_max: float = _origen_vista.x + 1280.0 - 182.0
	raiz.position = Vector2(
		clampf(rect.get_center().x - 86.0, x_min, x_max),
		rect.position.y + rect.size.y - 68.0
	)
	raiz.pivot_offset = Vector2(86.0, 22.0)
	raiz.scale = Vector2(0.72, 0.72)
	raiz.modulate.a = 0.0
	_capa_feedback.add_child(raiz)
	ui["bocadillo"] = raiz

	var tw := raiz.create_tween()
	tw.set_parallel(true)
	tw.tween_property(raiz, "modulate:a", 1.0, 0.12)
	tw.tween_property(raiz, "scale", Vector2.ONE, 0.24)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_interval(0.95)
	tw.chain().tween_property(raiz, "modulate:a", 0.0, 0.22)
	tw.chain().tween_callback(func():
		raiz.queue_free()
		if ui.get("bocadillo", null) == raiz:
			ui["bocadillo"] = null)


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

	# Avisos de impaciencia (solo una vez por cliente, cuando ya está sentado)
	if str(ui.get("fase", "")) == "esperando":
		if ratio < 0.50 and not bool(ui.get("aviso_media", false)):
			ui["aviso_media"] = true
			_Mostrar_Bocadillo_Cliente(indice, "¿Cuánto falta?", Color("#b45309"))
		if ratio < 0.25 and not bool(ui.get("aviso_baja", false)):
			ui["aviso_baja"] = true
			_Mostrar_Bocadillo_Cliente(indice, "¡Tengo prisa!", Color("#b91c1c"))
			_efectos.enfado(ui["centro"], 2)


func _Reiniciar_UI_Clientes() -> void:
	for i in range(_slots_clientes_ui.size()):
		var ui: Dictionary = _slots_clientes_ui[i]
		var retrato: ArteCocina.Retrato = ui["retrato"]
		var ticket: ArteCocina.Ticket = ui["ticket"]
		var tw: Tween = ui.get("tween", null)
		if tw != null and tw.is_valid():
			tw.kill()
		if ui.get("bocadillo", null) != null and is_instance_valid(ui["bocadillo"]):
			ui["bocadillo"].queue_free()
			ui["bocadillo"] = null
		ui["visible_antes"] = false
		ui["fase"] = "inactivo"
		ui["tipo_salida"] = ""
		ui["salida_hasta"] = 0.0
		ui["entrada_hasta"] = 0.0
		ui["bloqueado_hasta"] = 0.0
		ui["aviso_media"] = false
		ui["aviso_baja"] = false
		retrato.visible = false
		ticket.visible = false
		retrato.position = ui["pos_retrato"]
		ticket.position = ui["pos_ticket"]
		retrato.modulate = Color.WHITE
		ticket.modulate = Color.WHITE
		retrato.rotation = 0.0
		ticket.rotation = 0.0
		retrato.ratio = 1.0
		retrato.rebote = 0.0
		retrato.feliz = 0.0
		retrato.caminando = 0.0
		ticket.visible = false
		ticket.scale = Vector2.ONE
		ticket.ratio = 1.0


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
	for i in range(_clientes.size()):
		var cl: Dictionary = _clientes[i]
		if not bool(cl["activo"]):
			continue
		var fase: String = str(_slots_clientes_ui[i].get("fase", ""))
		if fase in ["entrando", "saliendo"]:
			continue
		if _Cliente_Necesita_Item(cl, item_id):
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
	lbl.add_theme_color_override("font_outline_color", Color("#0f172a"))
	lbl.add_theme_constant_override("outline_size", 5)
	var rect: Rect2 = ctrl.get_global_rect()
	lbl.size = Vector2(220.0, 26.0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(rect.get_center().x - 110.0, rect.position.y + 8.0 + offset_y)
	_capa_feedback.add_child(lbl)
	var tw := lbl.create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - 38.0, 1.05).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 1.05).set_delay(0.25)
	tw.chain().tween_callback(lbl.queue_free)


func _Bounce_Control(ctrl: Control, fuerza: float = 0.12, duracion: float = 0.18) -> void:
	if ctrl == null:
		return
	ctrl.pivot_offset = ctrl.size * 0.5
	var tw := ctrl.create_tween()
	tw.tween_property(ctrl, "scale", Vector2(1.0 + fuerza, 1.0 + fuerza), duracion * 0.4)\
		.set_ease(Tween.EASE_OUT)
	tw.tween_property(ctrl, "scale", Vector2.ONE, duracion * 0.6)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _Sacudir(fuerza: float, duracion: float) -> void:
	_shake_fuerza = maxf(_shake_fuerza, fuerza)
	_shake_duracion = maxf(0.05, duracion)
	_shake_t = _shake_duracion


func _Mostrar_Feedback_En_Posicion(pos_local: Vector2, texto_fb: String, color_fb: Color) -> void:
	if _capa_feedback == null or _vista_cocina == null:
		return
	var lbl := Estilos_UI.titulo(texto_fb, 16, color_fb)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_color_override("font_outline_color", Color("#0f172a"))
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


func _Lanzar_Monedas(desde_control: Control, destino_control: Control = null,
		cantidad: int = 3) -> void:
	if _capa_feedback == null or _hud_moneda_icon == null:
		return
	var inicio: Vector2 = desde_control.get_global_rect().get_center()
	var destino: Vector2 = (_hud_moneda_icon if destino_control == null \
		else destino_control).get_global_rect().get_center()
	for k in range(cantidad):
		var moneda := TextureRect.new()
		moneda.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		moneda.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		moneda.texture = ArteCocina.TEX_MONEDA
		moneda.size = Vector2(24.0, 24.0)
		moneda.position = inicio + Vector2(randf_range(-18.0, 18.0), randf_range(-12.0, 12.0))
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
	if _sfx != null:
		_sfx.reproducir("level_end", -11.0)
	_Ocultar_Tutorial()
	if _chef_root != null:
		_chef_root.visible = false
	var resumen: Dictionary = Sistema_Cocina.Procesar_Fin_Nivel(
		_restaurante_actual, _nivel_actual, _recaudacion, _propinas_servicio,
		_en_turno_partida, _desperdicio_valor)
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

	# 3 estrellas grandes con los sprites del pack y animación de entrada
	var h_est := HBoxContainer.new()
	h_est.alignment = BoxContainer.ALIGNMENT_CENTER
	h_est.add_theme_constant_override("separation", 14)
	_vbox_modal_resultados.add_child(h_est)
	for s in range(3):
		var estrella_modal := TextureRect.new()
		estrella_modal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		estrella_modal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		estrella_modal.texture = ArteCocina.TEX_ESTRELLA if s < estrellas else ArteCocina.TEX_ESTRELLA_VACIA
		estrella_modal.custom_minimum_size = Vector2(62.0, 62.0)
		estrella_modal.size = Vector2(62.0, 62.0)
		estrella_modal.pivot_offset = Vector2(31.0, 31.0)
		h_est.add_child(estrella_modal)
		if s < estrellas:
			estrella_modal.scale = Vector2(0.15, 0.15)
			var tw_est := estrella_modal.create_tween()
			tw_est.tween_interval(0.12 + 0.16 * float(s))
			tw_est.tween_property(estrella_modal, "scale", Vector2.ONE, 0.34)\
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_vbox_modal_resultados.add_child(Estilos_UI.divisor_horizontal())

	# Tabla de resultados: ventas -> costes -> Caja -> dinero personal
	var ventas: int = int(resumen.get("ventas", _recaudacion))
	var prop_serv: int = int(resumen.get("propinas_servicio", _propinas_servicio))
	var coste_ing: int = int(resumen.get("coste_ingredientes", 0))
	var coste_serv: int = int(resumen.get("coste_servicio", 0))
	var coste_merma: int = int(resumen.get("coste_merma", 0))
	var costes_total: int = int(resumen.get("costes_totales", coste_ing + coste_serv + coste_merma))
	var beneficio_neto: int = int(resumen.get("beneficio_neto", 0))
	var caja_ganada: int = int(resumen.get("caja_ganada", 0))
	var reparto_sim: int = int(resumen.get("reparto_sim", 0))
	var dinero_nivel: float = float(resumen.get("dinero_ganado", 0.0))
	var dinero_total: float = round((dinero_nivel + _micro_propinas_sesion) * 100.0) / 100.0
	var bono_est: float = float(resumen.get("bono_estrellas_eur", 0.0))
	var prop_eur: float = float(resumen.get("propinas_eur", 0.0))
	var modo_practica: bool = bool(resumen.get("modo_practica", false))

	var ticket_total: int = int(resumen.get("recaudacion", ventas + prop_serv))
	_Agregar_Fila_Resultado("Ticket del servicio", "%d € · %d/%d clientes · Combo x%d" % [
		ticket_total, _clientes_atendidos, _clientes_totales, maxi(1, _combo_max)])
	if prop_serv > 0:
		_Agregar_Fila_Resultado("Ventas (sin propinas)", "%d €" % ventas)
		_Agregar_Fila_Resultado("Propinas cobradas", "%d € · 50%% para ti" % prop_serv)
	_Agregar_Fila_Resultado("Costes del servicio", "−%d €" % costes_total)
	var detalle_costes: String = "Ingredientes −%d € · Servicio −%d €" % [coste_ing, coste_serv]
	if coste_merma > 0:
		detalle_costes += " · Merma −%d €" % coste_merma
	_vbox_modal_resultados.add_child(Estilos_UI.parrafo(detalle_costes, 12, Estilos_UI.TINTA_SUAVE))
	_Agregar_Fila_Resultado("Beneficio neto", "%d €" % beneficio_neto)
	_Agregar_Fila_Resultado("Para la Caja del restaurante", "+%d €" % caja_ganada)
	_Agregar_Fila_Resultado("Tu dinero", "+%.2f €" % dinero_total)
	var detalle_personal: Array[String] = ["Parte del beneficio %.2f €" % float(reparto_sim)]
	if prop_eur > 0.0:
		detalle_personal.append("Propinas %.2f €" % prop_eur)
	if bono_est > 0.0:
		detalle_personal.append("Prima %.2f €" % bono_est)
	if _micro_propinas_sesion > 0.0:
		detalle_personal.append("Micro %.2f €" % _micro_propinas_sesion)
	_vbox_modal_resultados.add_child(Estilos_UI.parrafo(" · ".join(detalle_personal), 12, Estilos_UI.TINTA_SUAVE))
	_Agregar_Fila_Resultado("Progreso Cocina", "+%d (Actual: %d / 100)" % [_cocina_ganada_sesion, Variables_Dinamicas.Progreso_Cocina])
	if _manualidades_ganadas_sesion > 0:
		_Agregar_Fila_Resultado("Progreso Manualidades", "+%d (Actual: %d / 100)" % [_manualidades_ganadas_sesion, int(Variables_Dinamicas.Progreso[2])])

	if bool(resumen.get("plus_nomina_activado", false)):
		_vbox_modal_resultados.add_child(Estilos_UI.pill_estado(
			"✓ +10% bonus asegurado en tu nómina de hostelería al terminar el turno",
			Estilos_UI.EXITO_SUAVE, Estilos_UI.EXITO_OSCURO))
	elif estrellas < 1:
		_vbox_modal_resultados.add_child(Estilos_UI.pill_estado(
			"Servicio incompleto: no cobras propinas ni parte del beneficio. La Caja conserva las ventas netas.",
			Estilos_UI.AVISO_SUAVE, Estilos_UI.ORO))
	elif modo_practica:
		_vbox_modal_resultados.add_child(Estilos_UI.pill_estado(
			"Modo práctica: propinas y parte del beneficio al 25%. La Caja sigue recibiendo el 100%.",
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
			msg_logro += "\nPrenda desbloqueada: %s (Vestuario)" % ", ".join(nombres_p)
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

	var btn_rep := Estilos_UI.boton("Repetir", "oro", "rotate-ccw", Estilos_UI.ORO, 48)
	btn_rep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_rep.pressed.connect(func(): _Comenzar_Carga_Nivel(_nivel_actual))
	btns.add_child(btn_rep)

	var tiene_sig: bool = superado and _nivel_actual < 15
	var btn_sig := Estilos_UI.boton("Siguiente Nivel", "exito", "chevron-right", Estilos_UI.EXITO, 48)
	btn_sig.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_sig.disabled = not tiene_sig
	btn_sig.pressed.connect(func(): _Comenzar_Carga_Nivel(_nivel_actual + 1))
	btns.add_child(btn_sig)

	_modal_resultados.visible = true
	_Animar_Modal_Resultados.call_deferred()


func _Animar_Modal_Resultados() -> void:
	if _modal_resultados == null or _card_resultados == null:
		return
	_card_resultados.pivot_offset = _card_resultados.size * 0.5
	_card_resultados.scale = Vector2(0.92, 0.92)
	_modal_resultados.modulate.a = 0.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_modal_resultados, "modulate:a", 1.0, 0.18)
	tw.tween_property(_card_resultados, "scale", Vector2.ONE, 0.34)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


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
