extends Control

# ============================================================================
# Minijuego de Cocina de gestión de pedidos.
# Selector de mundos/niveles, Mejoras y cocina jugable en horizontal
# (1280x720) con pantalla de carga, ARRASTRAR Y SOLTAR sobre los sprites PNG
# del pack (Imagenes/Minijuego_Cocina) y Modal de Resultados.
# Mantiene el reloj del Sim corriendo en segundo plano y restaura la vertical
# al salir al Sim.
# ============================================================================

signal cerrado()

const ArteCocina := preload("res://Scripts/GUI/Minijuego_Cocina/Arte_Cocina.gd")
const ArrastreCocina := preload("res://Scripts/GUI/Minijuego_Cocina/Arrastre_Cocina.gd")
const SonidosCocina := preload("res://Scripts/GUI/Minijuego_Cocina/Sonidos_Cocina.gd")
const MejorasCocina := preload("res://Scripts/GUI/Minijuego_Cocina/Mejoras_Cocina.gd")
const SelectorArte := preload("res://Scripts/GUI/Minijuego_Cocina/Selector_Niveles_Arte.gd")
const ArteModal := preload("res://Scripts/GUI/Minijuego_Cocina/Arte_Modal_Cocina.gd")

const TAMANO_HORIZONTAL := Vector2i(1280, 720)
const TAMANO_VERTICAL := Vector2i(720, 1280)
const ALTO_TOP_MAPA: float = 96.0
const MARGEN_MAPA: float = 18.0
const MARGEN_PANEL_MAPA: float = 18.0
const ANCHO_MAX_PANEL_MAPA: float = 1240.0
const ALTO_FILA_MUNDO: float = 178.0
const SEPARACION_MUNDOS: int = 16
const ALTO_TABLERO_NIVELES: float = 396.0
const COLUMNAS_NIVELES: int = 5
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
var _lbl_pausa_clientes: Label
var _card_inicio: Control
var _card_pausa: Control
var _card_salida: Control
var _pausado_por_confirmacion: bool = false
var _quit_on_go_back_previo: bool = true
var _capa_feedback: Control

# Referencias UI — Pantalla de carga (horizontal)
var _barra_carga: ProgressBar
var _fondo_carga: TextureRect
var _chef_carga: TextureRect
var _lbl_carga_pct: Label
var _lbl_carga_paso: Label
var _lbl_carga_titulo: Label
var _lbl_carga_sub: Label
var _tween_carga: Tween
var _carga_activa: bool = false
var _nivel_en_carga: int = -1

# Referencias UI — Cabecera y selector de restaurantes del mapa (horizontal)
var _top_mapa: Panel
var _htop_mapa: HBoxContainer
var _htop_mapa2: HBoxContainer

# Referencias UI — Mapa
var _lbl_mapa_titulo: Label
var _btn_mapa_rango: Button
var _pill_mapa_turno: PanelContainer
var _lbl_mapa_fondos: Label
var _lbl_mapa_dinero: Label
var _btn_mapa_mejoras: Button
var _lista_restaurantes: GridContainer
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
var _panel_maestria: PanelContainer
var _lbl_maestria_cabecera: Label
var _lbl_maestria_rango: Label
var _lbl_maestria_nombre: Label
var _lbl_maestria_estrellas: Label
var _bar_maestria: ProgressBar
var _lbl_maestria_faltan: Label
var _lbl_maestria_recompensa_tit: Label
var _lbl_maestria_recompensa: Label
var _modal_maestria: Control
var _card_maestria: Control
var _vbox_modal_maestria: VBoxContainer
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
var _perfil_actual: Dictionary = {}
var _fondo_cocina: TextureRect
var _puestos_nodos: Array[Control] = []
var _despensa_restaurante: String = ""
var _fondo_despensa: ArteCocina.Fondo_Despensa
var _despensa_pila: TextureRect
var _despensa_bandejas: TextureRect
var _est_plancha_tex: TextureRect
var _est_freidora_tex: TextureRect
var _est_bebidas_tex: TextureRect
var _horno_ctrl: ArteCocina.Estacion_Horno
var _olla_ctrl: ArteCocina.Estacion_Olla
var _sarten_ctrl: ArteCocina.Sarten_Salsa
var _botellas_ctrl: ArteCocina.Estacion_Botellas
# Estado de la olla de mercado y de la salsa de alta cocina.
var _olla: Dictionary = {
	"ingredientes": [], "estado": "vacio", "progreso": 0.0,
	"raciones": 0, "receta": ""
}
var _sarten: Dictionary = {
	"estado": "lista", "quemado": 0.0, "removido": 0.0
}

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
var _tiempo_coccion_b: float = 3.6
var _tiempo_olla: float = 6.2
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
var _bebida_items_actuales: Array[String] = []
var _platos: Array[Dictionary] = []
var _plancha: Array[Dictionary] = []
var _freidora: Array[Dictionary] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_Aplicar_Orientacion_Horizontal()
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

	# El mapa vive en horizontal (1280x720) y ocupa todo el viewport; el marco
	# del selector se centra con un ancho máximo para no deformarse en pantallas
	# muy alargadas.
	if _vista_mapa != null and is_instance_valid(_vista_mapa):
		_vista_mapa.position = Vector2.ZERO
		_vista_mapa.size = Vector2(maxf(float(TAMANO_HORIZONTAL.x), tam.x), maxf(float(TAMANO_HORIZONTAL.y), tam.y))
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
	var ancho: float = maxf(float(TAMANO_HORIZONTAL.x), _vista_mapa.size.x)
	var alto: float = maxf(float(TAMANO_HORIZONTAL.y), _vista_mapa.size.y)
	var ancho_util: float = ancho - MARGEN_MAPA * 2.0

	# Cabecera compacta de dos filas: mundo/rango y economía/mejoras.
	_top_mapa.position = Vector2.ZERO
	_top_mapa.size = Vector2(ancho, ALTO_TOP_MAPA)
	_htop_mapa.position = Vector2(MARGEN_MAPA, 6)
	_htop_mapa.size = Vector2(ancho_util, 40)
	_htop_mapa2.position = Vector2(MARGEN_MAPA, 50)
	_htop_mapa2.size = Vector2(ancho_util, 40)

	# Panel único celeste centrado. Al ser horizontal tiene un ancho máximo
	# para que en pantallas muy alargadas no se estiren las tarjetas.
	var panel_w: float = minf(ANCHO_MAX_PANEL_MAPA, ancho - MARGEN_PANEL_MAPA * 2.0)
	var panel_y: float = ALTO_TOP_MAPA + 10.0
	var panel_h: float = maxf(520.0, alto - panel_y - MARGEN_PANEL_MAPA)
	_marco_mapa.position = Vector2((ancho - panel_w) * 0.5, panel_y)
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

	if not expandido:
		# Cuatro mundos en una cuadrícula 2x2 a la izquierda y, a la derecha,
		# el chef como reclamo visual sobre la tarjeta de progreso de Maestría.
		var chef_w: float = 270.0
		var lista_w: float = maxf(360.0, tab.size.x - 56.0 - chef_w - 24.0)
		var alto_lista: float = minf(
			ALTO_FILA_MUNDO * 2.0 + float(SEPARACION_MUNDOS),
			tab.size.y - 24.0)
		var y0: float = tab.position.y + maxf(12.0, (tab.size.y - alto_lista) * 0.5)
		_lista_restaurantes.position = Vector2(tab.position.x + 28.0, y0)
		_lista_restaurantes.size = Vector2(lista_w, alto_lista)
		var col_x: float = tab.position.x + 28.0 + lista_w + 24.0
		_decor_mundos_chef.visible = true
		_decor_mundos_chef.position = Vector2(col_x, tab.position.y + 6.0)
		_decor_mundos_chef.size = Vector2(chef_w, 92.0)
		_panel_maestria.visible = true
		_panel_maestria.position = Vector2(col_x, tab.position.y + 106.0)
		_panel_maestria.size = Vector2(
			chef_w, maxf(240.0, tab.size.y - 114.0))
	else:
		_decor_mundos_chef.visible = false
		_panel_maestria.visible = false


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
	if _modal_maestria != null and _modal_maestria.visible:
		_modal_maestria.visible = false
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
	if _modal_maestria != null and _modal_maestria.visible:
		_modal_maestria.visible = false
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
	if DisplayServer.get_name().to_lower() in ["android", "ios"]:
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
	if DisplayServer.get_name().to_lower() in ["android", "ios"]:
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
	# Ocultamos la vista horizontal antes de girar: mientras Android aplica la
	# vertical solo se ve el fondo oscuro del minijuego, no el mapa estirado.
	if _vista_mapa != null and is_instance_valid(_vista_mapa):
		_vista_mapa.visible = false
	if _vista_cocina != null and is_instance_valid(_vista_cocina):
		_vista_cocina.visible = false
	if _vista_carga != null and is_instance_valid(_vista_carga):
		_vista_carga.visible = false
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
	_Construir_Modal_Maestria()
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
	_vista_mapa.size = Vector2(TAMANO_HORIZONTAL)
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
	_top_mapa.size = Vector2(TAMANO_HORIZONTAL.x, ALTO_TOP_MAPA)
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
	_htop_mapa.position = Vector2(MARGEN_MAPA, 6)
	_htop_mapa.size = Vector2(TAMANO_HORIZONTAL.x - MARGEN_MAPA * 2.0, 40)
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

	_btn_mapa_rango = Button.new()
	_btn_mapa_rango.name = "Boton_Maestria_Mapa"
	_btn_mapa_rango.tooltip_text = "Ver progreso y recompensas de Maestría Culinaria"
	_btn_mapa_rango.icon = SelectorArte.TEX_ESTRELLA
	_btn_mapa_rango.expand_icon = false
	_btn_mapa_rango.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_btn_mapa_rango.add_theme_font_override("font", SelectorArte.FUENTE_CARTOON)
	_btn_mapa_rango.add_theme_font_size_override("font_size", 12)
	_btn_mapa_rango.add_theme_color_override("font_color", Color("#ffe98a"))
	_btn_mapa_rango.add_theme_color_override("font_hover_color", Color("#fff6c7"))
	_btn_mapa_rango.add_theme_color_override("font_pressed_color", Color("#ffd75e"))
	_btn_mapa_rango.add_theme_constant_override("icon_max_width", 15)
	_btn_mapa_rango.add_theme_constant_override("h_separation", 5)
	_btn_mapa_rango.add_theme_stylebox_override("normal",
		SelectorArte.estilo_pildora(Color("#0c203b"), Color("#f6b93b"), 999, 2))
	_btn_mapa_rango.add_theme_stylebox_override("hover",
		SelectorArte.estilo_pildora(Color("#15355a"), Color("#ffd75e"), 999, 2))
	_btn_mapa_rango.add_theme_stylebox_override("pressed",
		SelectorArte.estilo_pildora(Color("#081a30"), Color("#e39a05"), 999, 2))
	_btn_mapa_rango.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_btn_mapa_rango.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_btn_mapa_rango.pressed.connect(_Abrir_Modal_Maestria)
	_htop_mapa.add_child(_btn_mapa_rango)

	_htop_mapa2 = HBoxContainer.new()
	_htop_mapa2.position = Vector2(MARGEN_MAPA, 50)
	_htop_mapa2.size = Vector2(TAMANO_HORIZONTAL.x - MARGEN_MAPA * 2.0, 40)
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
		minf(ANCHO_MAX_PANEL_MAPA, TAMANO_HORIZONTAL.x - MARGEN_PANEL_MAPA * 2.0),
		TAMANO_HORIZONTAL.y - ALTO_TOP_MAPA - 28.0)
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

	_lista_restaurantes = GridContainer.new()
	_lista_restaurantes.name = "Selector_Restaurantes"
	_lista_restaurantes.columns = 2
	_lista_restaurantes.add_theme_constant_override("h_separation", SEPARACION_MUNDOS)
	_lista_restaurantes.add_theme_constant_override("v_separation", SEPARACION_MUNDOS)
	_marco_mapa.add_child(_lista_restaurantes)

	_decor_mundos_chef = TextureRect.new()
	_decor_mundos_chef.name = "Chef_Selector_Mundos"
	_decor_mundos_chef.texture = ArteCocina.textura_chef("pulgar")
	_decor_mundos_chef.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_decor_mundos_chef.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_decor_mundos_chef.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_marco_mapa.add_child(_decor_mundos_chef)

	_Construir_Panel_Maestria()

	_contenedor_niveles = Control.new()
	_contenedor_niveles.name = "Contenedor_Niveles"
	_contenedor_niveles.visible = false
	_marco_mapa.add_child(_contenedor_niveles)


func _Construir_Panel_Maestria() -> void:
	# Tarjeta de progreso visible desde el selector de mundos. Explica de un
	# vistazo que cada 20 ★ se sube de rango y cuál es la siguiente recompensa.
	_panel_maestria = PanelContainer.new()
	_panel_maestria.name = "Panel_Maestria_Mapa"
	_panel_maestria.visible = false
	var st := SelectorArte.estilo_pildora(
		Color(0.035, 0.095, 0.18, 0.94), SelectorArte.ORO, 20, 2)
	st.content_margin_left = 14
	st.content_margin_right = 14
	st.content_margin_top = 10
	st.content_margin_bottom = 10
	_panel_maestria.add_theme_stylebox_override("panel", st)
	# Fijamos un tamaño inicial antes de añadir etiquetas con autowrap: si el
	# ancho arranca en 0, el cálculo de altura mínima se dispara y la tarjeta
	# crece fuera del panel del selector.
	_panel_maestria.size = Vector2(270.0, 316.0)
	_marco_mapa.add_child(_panel_maestria)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	_panel_maestria.add_child(v)

	var cab := HBoxContainer.new()
	cab.alignment = BoxContainer.ALIGNMENT_CENTER
	cab.add_theme_constant_override("separation", 6)
	v.add_child(cab)
	cab.add_child(_Icono_Mapa(SelectorArte.TEX_ESTRELLA, 18.0))
	_lbl_maestria_cabecera = Estilos_UI.texto(
		"MAESTRÍA CULINARIA", 14, SelectorArte.ORO_CLARO, 700)
	_lbl_maestria_cabecera.add_theme_font_override("font", SelectorArte.FUENTE_CARTOON)
	cab.add_child(_lbl_maestria_cabecera)

	_lbl_maestria_rango = Estilos_UI.texto("RANGO 0 / 9", 25, Color.WHITE, 700)
	_lbl_maestria_rango.add_theme_font_override("font", SelectorArte.FUENTE_CARTOON)
	_lbl_maestria_rango.add_theme_color_override(
		"font_outline_color", SelectorArte.NAVY_OSCURO)
	_lbl_maestria_rango.add_theme_constant_override("outline_size", 4)
	_lbl_maestria_rango.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_lbl_maestria_rango)

	_lbl_maestria_nombre = Estilos_UI.texto(
		"Aprendiz", 13, SelectorArte.CREMA, 700)
	_lbl_maestria_nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_lbl_maestria_nombre)

	_lbl_maestria_estrellas = Estilos_UI.texto(
		"0 / 20 ★", 14, SelectorArte.ORO_CLARO, 700)
	_lbl_maestria_estrellas.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_lbl_maestria_estrellas)

	_bar_maestria = _Crear_Barra_Maestria(14.0)
	v.add_child(_bar_maestria)

	_lbl_maestria_faltan = Estilos_UI.texto(
		"Faltan 20 ★ para el Rango 1", 10, Color("#9fe9ff"), 600)
	_lbl_maestria_faltan.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_lbl_maestria_faltan)

	var lbl_regla := Estilos_UI.texto(
		"Cada 20 ★ subes de rango", 9, Color(0.78, 0.92, 1.0, 0.80), 600)
	lbl_regla.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(lbl_regla)

	var esp := Control.new()
	esp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	esp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(esp)

	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel", ArteModal.caja_placa(10, 0.28))
	v.add_child(caja)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 0)
	caja.add_child(rv)
	_lbl_maestria_recompensa_tit = Estilos_UI.texto(
		"SIGUIENTE RECOMPENSA", 9, Color("#9fe9ff"), 700)
	rv.add_child(_lbl_maestria_recompensa_tit)
	_lbl_maestria_recompensa = Estilos_UI.texto(
		"Rango 1 · Pinche de Cocina\nDelantal de Aprendiz", 11, SelectorArte.CREMA, 600)
	rv.add_child(_lbl_maestria_recompensa)

	var btn := Button.new()
	btn.name = "Boton_Ver_Rangos_Maestria"
	btn.text = "VER RANGOS"
	btn.icon = SelectorArte.TEX_ESTRELLA
	btn.expand_icon = false
	btn.custom_minimum_size = Vector2(0.0, 34.0)
	SelectorArte.aplicar_estilos_boton(btn, SelectorArte.estilo_boton_oro(12))
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_constant_override("icon_max_width", 15)
	btn.pressed.connect(_Abrir_Modal_Maestria)
	v.add_child(btn)


func _Crear_Barra_Maestria(alto: float) -> ProgressBar:
	var barra := ProgressBar.new()
	barra.show_percentage = false
	barra.custom_minimum_size = Vector2(0.0, alto)
	barra.max_value = 100.0
	barra.value = 0.0
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.01, 0.06, 0.12, 0.70)
	bg.set_corner_radius_all(999)
	bg.border_color = Color(0.55, 0.89, 1.0, 0.30)
	bg.set_border_width_all(1)
	bg.anti_aliasing = true
	var relleno := StyleBoxFlat.new()
	relleno.bg_color = SelectorArte.ORO
	relleno.set_corner_radius_all(999)
	relleno.border_color = SelectorArte.ORO_BORDE
	relleno.set_border_width_all(1)
	relleno.anti_aliasing = true
	barra.add_theme_stylebox_override("background", bg)
	barra.add_theme_stylebox_override("fill", relleno)
	return barra


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
	_Aplicar_Orientacion_Horizontal()
	if _arrastre != null:
		_arrastre.cancelar()
		_arrastre.habilitado = false
	_Ocultar_Tutorial()
	if _chef_root != null:
		_chef_root.visible = false
	_vista_mapa.visible = true
	_vista_cocina.visible = false
	_modal_inicio.visible = false
	_modal_maestria.visible = false
	_modal_mejoras.visible = false
	_modal_resultados.visible = false
	if _modal_salida != null:
		_modal_salida.visible = false
	if _modal_pausa != null:
		_modal_pausa.visible = false
	if _modal_maestria != null:
		_modal_maestria.visible = false
	_Centrar_Contenido()
	_Refrescar_Mapa()


func _Refrescar_Mapa() -> void:
	var rango: int = Sistema_Cocina.Obtener_Rango_Logro()
	var info_rango: Dictionary = Sistema_Cocina.Obtener_Info_Rango(rango)
	_lbl_mapa_fondos.text = "Caja %d €" % Sistema_Cocina.Obtener_Caja_Restaurante()
	_lbl_mapa_dinero.text = "%d €" % int(Variables_Dinamicas.Dinero)
	_pill_mapa_turno.visible = Sistema_Cocina.Esta_En_Turno_Activo(_restaurante_actual)
	_Refrescar_Maestria()

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
	if _fondo_mapa != null and _fondo_mapa is SelectorArte.Fondo_Mapa:
		var rest_fondo: String = _restaurante_expandido if _restaurante_expandido != "" \
			else Sistema_Cocina.RESTAURANTE_BURGER
		var textura_fondo: Texture2D = ArteCocina.fondo_selector_restaurante(rest_fondo)
		(_fondo_mapa as SelectorArte.Fondo_Mapa).textura = textura_fondo
		_fondo_mapa.queue_redraw()

	if expandido:
		_lbl_mapa_pie.text = "%d / 45 ★   ·   %d / 15 niveles" % [
			Sistema_Cocina.Contar_Estrellas_Totales(_restaurante_expandido),
			Sistema_Cocina.Contar_Niveles_Superados(_restaurante_expandido)]
	else:
		_lbl_mapa_pie.text = "Rango %d / 9 · %s · %d / %d ★" % [
			rango, str(info_rango.get("nombre", "")),
			Sistema_Cocina.Contar_Estrellas_Totales(),
			Sistema_Cocina.ESTRELLAS_TOTALES_MAX]
		if Sistema_Cocina.desbloqueo_total_qa:
			_lbl_mapa_pie.text += " · MODO PRUEBA: todos los mundos abiertos"

	_Refrescar_Lista_Mundos()
	_Refrescar_Tablero_Niveles(rest_cfg, rest_jugable)


func _Refrescar_Maestria() -> void:
	var p: Dictionary = Sistema_Cocina.Obtener_Progreso_Maestria()
	var rango: int = int(p.get("rango", 0))
	var estrellas: int = int(p.get("estrellas", 0))
	var maximo: bool = bool(p.get("maximo", false))
	var umbral_siguiente: int = int(p.get("umbral_siguiente", estrellas))
	var info: Dictionary = p.get("info", {})
	var info_sig: Dictionary = p.get("info_siguiente", info)
	var nombre: String = str(info.get("nombre", "Aprendiz"))

	if _btn_mapa_rango != null and is_instance_valid(_btn_mapa_rango):
		_btn_mapa_rango.text = "RANGO %d/9 · %d ★" % [rango, estrellas]
		_btn_mapa_rango.tooltip_text = "Maestría Culinaria: Rango %d/9 (%s) · %d ★. Cada 20 ★ subes de rango." % [
			rango, nombre, estrellas]

	if _panel_maestria == null or not is_instance_valid(_panel_maestria):
		return
	_lbl_maestria_rango.text = "RANGO %d / 9" % rango
	_lbl_maestria_nombre.text = nombre
	_bar_maestria.value = clampf(float(p.get("progreso", 0.0)) * 100.0, 0.0, 100.0)
	if maximo:
		_lbl_maestria_estrellas.text = "%d / %d ★" % [
			estrellas, Sistema_Cocina.ESTRELLAS_TOTALES_MAX]
		_lbl_maestria_faltan.text = "Rango máximo alcanzado"
		_lbl_maestria_recompensa_tit.text = "RECOMPENSA DEL RANGO 9"
		_lbl_maestria_recompensa.text = "%s\n%s" % [
			str(info.get("nombre", "")), str(info.get("corta", ""))]
	else:
		_lbl_maestria_estrellas.text = "%d / %d ★" % [estrellas, umbral_siguiente]
		_lbl_maestria_faltan.text = "Faltan %d ★ para el Rango %d" % [
			int(p.get("faltan", 0)), rango + 1]
		_lbl_maestria_recompensa_tit.text = "SIGUIENTE RECOMPENSA · RANGO %d" % (rango + 1)
		_lbl_maestria_recompensa.text = "%s\n%s" % [
			str(info_sig.get("nombre", "")), str(info_sig.get("corta", ""))]


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
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
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

		# Miniatura del local: cada mundo se reconoce por su fondo antes de
		# entrar. Los bloqueados se muestran desaturados.
		var marco_thumb := PanelContainer.new()
		marco_thumb.custom_minimum_size = Vector2(132.0, 78.0)
		marco_thumb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		marco_thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var st_thumb := SelectorArte.estilo_pildora(Color("#0b1220"), Color("#f5c451"), 12, 2)
		st_thumb.content_margin_left = 0
		st_thumb.content_margin_right = 0
		st_thumb.content_margin_top = 0
		st_thumb.content_margin_bottom = 0
		marco_thumb.add_theme_stylebox_override("panel", st_thumb)
		var thumb := TextureRect.new()
		thumb.texture = ArteCocina.fondo_restaurante(rest_id)
		thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		thumb.custom_minimum_size = Vector2(128.0, 74.0)
		thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if bloqueado:
			thumb.modulate = Color(0.52, 0.58, 0.64, 0.82)
		marco_thumb.add_child(thumb)
		row.add_child(marco_thumb)

		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", 2)
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(col)

		var lbl_n := Estilos_UI.titulo(str(r.get("nombre", rest_id)), 20,
			Color("#173b63") if not bloqueado else Color("#6f8799"))
		lbl_n.add_theme_font_override("font", SelectorArte.FUENTE_CARTOON)
		lbl_n.clip_text = true
		lbl_n.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
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
			var idx_mundo: int = Sistema_Cocina.ORDEN_RESTAURANTES.find(rest_id)
			if idx_mundo > 0:
				sub_txt = "Requiere: %s o 1★ en el mundo anterior" % trabajo
			else:
				sub_txt = "Requiere: %s" % trabajo
		var lbl_s := Estilos_UI.texto(sub_txt, 12,
			Color("#7a6234") if not bloqueado else Color("#7890a2"), 600)
		lbl_s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(lbl_s)

		# Estado del mundo en una fila bajo el subtítulo: así el título dispone
		# de todo el ancho de la tarjeta (2×2) junto a la miniatura del local.
		var fila_estado := HBoxContainer.new()
		fila_estado.add_theme_constant_override("separation", 6)
		fila_estado.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(fila_estado)

		if bloqueado:
			if impl:
				fila_estado.add_child(Estilos_UI.pill_estado("BLOQUEADO",
					Color("#e4f1fa"), Color("#2b7aa6")))
		else:
			if Sistema_Cocina.Esta_En_Turno_Activo(rest_id):
				fila_estado.add_child(Estilos_UI.pill_estado("TURNO",
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
			fila_estado.add_child(pill_prog)

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
	_grid_niveles.columns = COLUMNAS_NIVELES
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
	btn.custom_minimum_size = Vector2(0.0, 130.0)
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
# Base común de los modales cartoon (velo, marco azul y contenido)
# ----------------------------------------------------------------------------

func _Crear_Modal_Base(nombre: String, z: int, ancho: float,
		margen_h: int, margen_v: int) -> Dictionary:
	var modal := Control.new()
	modal.name = nombre
	modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.z_index = z
	modal.visible = false
	add_child(modal)

	var velo := ColorRect.new()
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	velo.color = Color(0.02, 0.07, 0.16, 0.78)
	modal.add_child(velo)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.add_child(centro)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(ancho, 0)
	card.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	centro.add_child(card)

	var marco: Control = ArteModal.Marco_Modal.new()
	marco.name = "Marco_Modal"
	marco.set_anchors_preset(Control.PRESET_FULL_RECT)
	marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(marco)

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", margen_h)
	margen.add_theme_constant_override("margin_right", margen_h)
	margen.add_theme_constant_override("margin_top", margen_v)
	margen.add_theme_constant_override("margin_bottom", margen_v)
	card.add_child(margen)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margen.add_child(vbox)
	return {"modal": modal, "card": card, "vbox": vbox}


func _Animar_Entrada_Modal(modal: Control, card: Control) -> void:
	if modal == null or not is_instance_valid(modal):
		return
	modal.modulate.a = 0.0
	if card == null or not is_instance_valid(card):
		var tw_solo := create_tween()
		tw_solo.tween_property(modal, "modulate:a", 1.0, 0.16)
		return
	card.pivot_offset = card.size * 0.5
	card.scale = Vector2(0.93, 0.93)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(modal, "modulate:a", 1.0, 0.16)
	tw.tween_property(card, "scale", Vector2.ONE, 0.30)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ----------------------------------------------------------------------------
# Modal de Inicio de Nivel
# ----------------------------------------------------------------------------

func _Construir_Modal_Inicio() -> void:
	var base: Dictionary = _Crear_Modal_Base("Modal_Inicio_Nivel", 46, 900.0, 44, 28)
	_modal_inicio = base["modal"]
	_card_inicio = base["card"]
	_vbox_modal_inicio = base["vbox"]
	_vbox_modal_inicio.add_theme_constant_override("separation", 10)


func _Abrir_Modal_Inicio(nivel: int) -> void:
	_nivel_seleccionado = nivel
	var cfg: Dictionary = Sistema_Cocina.Obtener_Config_Nivel(_restaurante_actual, nivel)
	if cfg.is_empty():
		return

	for c in _vbox_modal_inicio.get_children():
		_vbox_modal_inicio.remove_child(c)
		c.queue_free()

	var en_turno: bool = Sistema_Cocina.Esta_En_Turno_Activo(_restaurante_actual)
	var est_prev: int = Sistema_Cocina.Obtener_Estrellas_Nivel(_restaurante_actual, nivel)

	# Cabecera: título dorado, mundo y píldora de clientes.
	var tit := ArteModal.crear_titulo("NIVEL %d" % nivel, 42)
	tit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vbox_modal_inicio.add_child(tit)
	var subt := ArteModal.texto_cartoon(
		Sistema_Cocina.Obtener_Nombre_Restaurante(_restaurante_actual),
		17, ArteModal.CREMA, ArteModal.NAVY_OSCURO, 4)
	subt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vbox_modal_inicio.add_child(subt)

	var fila_cli := HBoxContainer.new()
	fila_cli.alignment = BoxContainer.ALIGNMENT_CENTER
	_vbox_modal_inicio.add_child(fila_cli)
	var pill_cli := PanelContainer.new()
	pill_cli.add_theme_stylebox_override("panel", ArteModal.caja_pildora_oro())
	fila_cli.add_child(pill_cli)
	var h_cli := HBoxContainer.new()
	h_cli.add_theme_constant_override("separation", 6)
	pill_cli.add_child(h_cli)
	h_cli.add_child(ArteModal.icono_usuarios(18, ArteModal.NAVY))
	h_cli.add_child(ArteModal.texto_cartoon(
		"%d CLIENTES" % int(cfg.get("clientes", 10)), 15, ArteModal.NAVY,
		Color.TRANSPARENT, 0))

	# Objetivos de estrellas: placas hundidas con estrella dorada y meta.
	var metas := HBoxContainer.new()
	metas.add_theme_constant_override("separation", 12)
	_vbox_modal_inicio.add_child(metas)
	var objetivos: Array = [
		[1, int(cfg.get("meta_1", 50)), est_prev >= 1],
		[2, int(cfg.get("meta_2", 80)), est_prev >= 2],
		[3, int(cfg.get("meta_3", 110)), est_prev >= 3]
	]
	for info_m in objetivos:
		var p := PanelContainer.new()
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p.add_theme_stylebox_override("panel", ArteModal.caja_placa(14, 0.30))
		metas.add_child(p)
		var h_meta := HBoxContainer.new()
		h_meta.alignment = BoxContainer.ALIGNMENT_CENTER
		h_meta.add_theme_constant_override("separation", 9)
		p.add_child(h_meta)
		h_meta.add_child(ArteModal.icono_estrella(30))
		var v_meta := VBoxContainer.new()
		v_meta.add_theme_constant_override("separation", -2)
		h_meta.add_child(v_meta)
		v_meta.add_child(ArteModal.texto_modal(
			"META %d" % int(info_m[0]), 11, ArteModal.CREMA, 700))
		var lbl_meta := ArteModal.texto_cartoon(
			"%d €" % int(info_m[1]), 17, ArteModal.ORO_CLARO, ArteModal.NAVY_OSCURO, 3)
		lbl_meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		v_meta.add_child(lbl_meta)

	# Menú del servicio: píldoras crema con el icono del plato.
	var menu_lbl := ArteModal.texto_cartoon(
		"PLATOS DEL SERVICIO", 14, ArteModal.CREMA, ArteModal.NAVY_OSCURO, 3)
	_vbox_modal_inicio.add_child(menu_lbl)
	var menu_row := HFlowContainer.new()
	menu_row.add_theme_constant_override("h_separation", 8)
	menu_row.add_theme_constant_override("v_separation", 6)
	_vbox_modal_inicio.add_child(menu_row)
	for plato_id in cfg.get("menu", []):
		var rec: Dictionary = Sistema_Cocina.Obtener_Receta(_restaurante_actual, str(plato_id))
		var nom: String = str(rec.get("nombre_corto", plato_id))
		var pill_plato := PanelContainer.new()
		var st_pl := Estilos_UI.caja(Color("#fff7dd"), 999, ArteModal.ORO_BORDE, 2, 0)
		st_pl.content_margin_left = 6
		st_pl.content_margin_right = 12
		st_pl.content_margin_top = 2
		st_pl.content_margin_bottom = 3
		pill_plato.add_theme_stylebox_override("panel", st_pl)
		var fila_plato := HBoxContainer.new()
		fila_plato.add_theme_constant_override("separation", 4)
		var ic_plato := ArteCocina.Icono_Item.new()
		ic_plato.item_id = str(plato_id)
		ic_plato.custom_minimum_size = Vector2(26.0, 26.0)
		ic_plato.size = Vector2(26.0, 26.0)
		fila_plato.add_child(ic_plato)
		fila_plato.add_child(Estilos_UI.texto(nom, 12, Color("#9a3412"), 700))
		pill_plato.add_child(fila_plato)
		menu_row.add_child(pill_plato)

	# Explicación de la mecánica del mundo (solo si no es el montaje clásico)
	var perf_modal: Dictionary = Sistema_Cocina.Obtener_Perfil_Restaurante(_restaurante_actual)
	if str(perf_modal.get("mecanica", "montaje")) != "montaje":
		var caja_mec := PanelContainer.new()
		caja_mec.add_theme_stylebox_override("panel", ArteModal.caja_placa(12, 0.28))
		var lbl_mec := ArteModal.texto_modal(
			"%s: %s" % [str(perf_modal.get("mecanica_titulo", "Mecánica")),
				str(perf_modal.get("mecanica_texto", ""))],
			14, ArteModal.CREMA, 600)
		lbl_mec.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		caja_mec.add_child(lbl_mec)
		_vbox_modal_inicio.add_child(caja_mec)

	_vbox_modal_inicio.add_child(ArteModal.divisor())

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

	var lbl_mods := ArteModal.texto_modal(
		"\n".join(mod_lineas), 14, ArteModal.CREMA, 500)
	lbl_mods.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_vbox_modal_inicio.add_child(lbl_mods)

	# Validación de entrada
	var check: Dictionary = Sistema_Cocina.Puede_Entrar_Minijuego()
	var permitido: bool = bool(check.get("permitido", false))
	if not permitido:
		var err := ArteModal.texto_modal(
			str(check.get("mensaje", "")), 14, Color("#ffd2c7"), 700)
		err.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_vbox_modal_inicio.add_child(err)

	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 14)
	_vbox_modal_inicio.add_child(btns)

	var btn_cancel := ArteModal.crear_boton(
		"CANCELAR", ArteModal.TEX_BOTON_AZUL, "arrow-left", 56, 18)
	btn_cancel.name = "Boton_Cancelar_Inicio"
	btn_cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_cancel.pressed.connect(func(): _modal_inicio.visible = false)
	btns.add_child(btn_cancel)

	var btn_start := ArteModal.crear_boton(
		"¡EMPEZAR SERVICIO!", ArteModal.TEX_BOTON_VERDE, "play", 56, 18)
	btn_start.name = "Boton_Empezar_Servicio"
	btn_start.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_start.disabled = not permitido
	if not permitido:
		btn_start.modulate = Color(1, 1, 1, 0.62)
	btn_start.pressed.connect(func():
		_modal_inicio.visible = false
		_Comenzar_Carga_Nivel(nivel))
	btns.add_child(btn_start)

	_modal_inicio.modulate.a = 0.0
	_modal_inicio.visible = true
	_Animar_Entrada_Modal.call_deferred(_modal_inicio, _card_inicio)


# ----------------------------------------------------------------------------
# Modal de Maestría Culinaria (progreso por estrellas y recompensas)
# ----------------------------------------------------------------------------

func _Construir_Modal_Maestria() -> void:
	var base: Dictionary = _Crear_Modal_Base("Modal_Maestria", 47, 1020.0, 38, 22)
	_modal_maestria = base["modal"]
	_card_maestria = base["card"]
	_vbox_modal_maestria = base["vbox"]
	_vbox_modal_maestria.add_theme_constant_override("separation", 8)


func _Abrir_Modal_Maestria() -> void:
	if _modal_maestria == null or not is_instance_valid(_modal_maestria):
		return
	_Refrescar_Maestria()
	for c in _vbox_modal_maestria.get_children():
		_vbox_modal_maestria.remove_child(c)
		c.queue_free()

	var p: Dictionary = Sistema_Cocina.Obtener_Progreso_Maestria()
	var rango: int = int(p.get("rango", 0))
	var estrellas: int = int(p.get("estrellas", 0))
	var maximo: bool = bool(p.get("maximo", false))
	var info: Dictionary = p.get("info", {})
	var nombre: String = str(info.get("nombre", "Aprendiz"))

	var tit := ArteModal.crear_titulo("MAESTRÍA CULINARIA", 38)
	tit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vbox_modal_maestria.add_child(tit)
	var subt := ArteModal.texto_cartoon(
		"Gana ★ en los niveles: cada 20 ★ subes de rango. Solo cuenta tu mejor marca en cada nivel.",
		14, ArteModal.CREMA, ArteModal.NAVY_OSCURO, 3)
	subt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vbox_modal_maestria.add_child(subt)

	# Resumen: rango actual, estrellas acumuladas y barra hasta el siguiente.
	var resumen := PanelContainer.new()
	resumen.add_theme_stylebox_override("panel", ArteModal.caja_placa(16, 0.34))
	_vbox_modal_maestria.add_child(resumen)
	var h_res := HBoxContainer.new()
	h_res.add_theme_constant_override("separation", 14)
	resumen.add_child(h_res)
	h_res.add_child(ArteModal.icono_estrella(50))
	var col_res := VBoxContainer.new()
	col_res.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_res.add_theme_constant_override("separation", 2)
	h_res.add_child(col_res)
	col_res.add_child(ArteModal.texto_cartoon(
		"RANGO %d / 9 · %s" % [rango, nombre], 20,
		ArteModal.ORO_CLARO, ArteModal.NAVY_OSCURO, 4))
	var detalle: String = "%d ★ de %d" % [estrellas, Sistema_Cocina.ESTRELLAS_TOTALES_MAX]
	if maximo:
		detalle += " · Rango máximo alcanzado"
	else:
		detalle += " · Faltan %d ★ para el Rango %d" % [
			int(p.get("faltan", 0)), rango + 1]
	col_res.add_child(ArteModal.texto_modal(detalle, 13, ArteModal.CREMA, 600))
	var barra := _Crear_Barra_Maestria(16.0)
	barra.value = clampf(float(p.get("progreso", 0.0)) * 100.0, 0.0, 100.0)
	col_res.add_child(barra)

	var cap := ArteModal.texto_cartoon(
		"RECOMPENSAS POR RANGO", 16, ArteModal.CREMA, ArteModal.NAVY_OSCURO, 3)
	_vbox_modal_maestria.add_child(cap)

	# Rejilla 2 columnas: las 9 recompensas caben enteras sin scroll.
	var grid_rangos := GridContainer.new()
	grid_rangos.name = "Lista_Rangos_Maestria"
	grid_rangos.columns = 2
	grid_rangos.add_theme_constant_override("h_separation", 8)
	grid_rangos.add_theme_constant_override("v_separation", 4)
	grid_rangos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vbox_modal_maestria.add_child(grid_rangos)
	for i in range(1, Sistema_Cocina.RANGOS_LOGRO.size()):
		_Agregar_Fila_Rango_Maestria(grid_rangos, i, rango)

	var pie := HBoxContainer.new()
	pie.add_theme_constant_override("separation", 12)
	_vbox_modal_maestria.add_child(pie)
	var hint := ArteModal.texto_modal(
		"Repite niveles para mejorar tus ★: el progreso y las recompensas se guardan solos.",
		12, ArteModal.CREMA_SUAVE, 500)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pie.add_child(hint)
	var btn := ArteModal.crear_boton(
		"ENTENDIDO", ArteModal.TEX_BOTON_VERDE, "check", 52, 18)
	btn.custom_minimum_size = Vector2(220.0, 0.0)
	btn.pressed.connect(func(): _modal_maestria.visible = false)
	pie.add_child(btn)

	_modal_maestria.modulate.a = 0.0
	_modal_maestria.visible = true
	_Animar_Entrada_Modal.call_deferred(_modal_maestria, _card_maestria)


func _Agregar_Fila_Rango_Maestria(grid: GridContainer, indice: int,
		rango_actual: int) -> void:
	var info: Dictionary = Sistema_Cocina.RANGOS_LOGRO[indice]
	var umbral: int = int(info.get("estrellas", 0))
	var es_actual: bool = indice == rango_actual
	var es_siguiente: bool = indice == rango_actual + 1
	var completado: bool = indice < rango_actual

	var fila := PanelContainer.new()
	fila.custom_minimum_size = Vector2(0.0, 42.0)
	fila.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var st := ArteModal.caja_placa(12, 0.34 if es_actual else 0.22)
	st.border_color = Color(0.72, 0.95, 1.0, 0.30)
	st.border_width_bottom = 3
	if es_actual:
		st.bg_color = Color(0.24, 0.16, 0.02, 0.62)
		st.border_color = SelectorArte.ORO
		st.set_border_width_all(2)
		st.border_width_bottom = 4
	elif es_siguiente:
		st.border_color = Color(0.55, 0.89, 1.0, 0.75)
		st.set_border_width_all(2)
		st.border_width_bottom = 3
	elif completado:
		st.border_color = Color(0.42, 0.88, 0.55, 0.55)
	fila.add_theme_stylebox_override("panel", st)
	if not es_actual and not es_siguiente and not completado:
		fila.modulate.a = 0.68
	grid.add_child(fila)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 9)
	fila.add_child(h)

	# Umbral de estrellas.
	var badge := VBoxContainer.new()
	badge.custom_minimum_size = Vector2(52.0, 0.0)
	badge.alignment = BoxContainer.ALIGNMENT_CENTER
	badge.add_theme_constant_override("separation", -2)
	h.add_child(badge)
	var ico := ArteModal.icono_estrella(18, not completado and not es_actual)
	ico.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	badge.add_child(ico)
	var lbl_umbral := ArteModal.texto_cartoon(
		"%d" % umbral, 12, ArteModal.ORO_CLARO, ArteModal.NAVY_OSCURO, 2)
	lbl_umbral.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_umbral.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	badge.add_child(lbl_umbral)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 0)
	h.add_child(col)

	var fila_nombre := HBoxContainer.new()
	fila_nombre.add_theme_constant_override("separation", 6)
	col.add_child(fila_nombre)
	var color_nombre := ArteModal.ORO_CLARO if (es_actual or es_siguiente) 		else (Color("#c8f7d0") if completado else ArteModal.CREMA)
	var nom := ArteModal.texto_cartoon(
		"RANGO %d · %s" % [indice, str(info.get("nombre", ""))],
		14, color_nombre, ArteModal.NAVY_OSCURO, 3)
	nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nom.clip_text = true
	fila_nombre.add_child(nom)
	var benef := ArteModal.texto_modal(
		str(info.get("beneficio", "")), 11,
		Color("#c8f7d0") if completado else ArteModal.CREMA_SUAVE, 500)
	benef.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	benef.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(benef)

	var estado_txt: String = "ACTUAL" if es_actual else 		("SIGUIENTE" if es_siguiente else ("COMPLETADO" if completado else "BLOQUEADO"))
	var color_estado := ArteModal.ORO if es_actual else 		(ArteModal.ORO_CLARO if es_siguiente else 		(Color("#b9f6c2") if completado else Color(0.75, 0.88, 1.0, 0.60)))
	var estado := ArteModal.texto_cartoon(
		estado_txt, 10, color_estado, ArteModal.NAVY_OSCURO, 2)
	estado.custom_minimum_size = Vector2(76.0, 0.0)
	estado.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	estado.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(estado)


# ----------------------------------------------------------------------------
# Modal de Mejoras (componente propio con escaparate y compra)
# ----------------------------------------------------------------------------

func _Construir_Modal_Mejoras() -> void:
	var modal: Control = MejorasCocina.new()
	modal.name = "Modal_Mejoras"
	modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.z_index = 46
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
	_fondo_cocina = fondo

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
	_arrastre.zona_tocada.connect(_on_zona_tocada)
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
	# Zona generosa que cubre cuerpo y bocadillo del pedido: en móvil el dedo
	# no siempre cae sobre el personaje y antes el plato se rechazaba.
	return Rect2(cx - 108.0, 62.0, 216.0, 384.0)


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
			or _restaurante_actual != Sistema_Cocina.RESTAURANTE_BURGER \
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
				texto = "Arrastra el plato al cliente"
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
	_lbl_estado_propinas = _Crear_Etiqueta_Estacion(ZONA_PROPINAS.position.x, 599.0,
		ZONA_PROPINAS.size.x, "PROPINAS · 0 €")

	# Plancha (4 fogones)
	var est_plancha := _Anadir_Textura(ArteCocina.TEX_PLANCHA, Rect2(14.0, 424.0, 238.0, 174.0), "Estacion_Plancha")
	est_plancha.z_index = 3
	_est_plancha_tex = est_plancha
	# Freidora (2 cestas)
	var est_freidora := _Anadir_Textura(ArteCocina.TEX_FREIDORA, Rect2(266.0, 438.0, 150.0, 143.0), "Estacion_Freidora")
	est_freidora.z_index = 3
	_est_freidora_tex = est_freidora
	# Dispensador de refrescos
	var est_refrescos := _Anadir_Textura(ArteCocina.TEX_REFRESCOS, Rect2(432.0, 418.0, 150.0, 178.0), "Estacion_Refrescos")
	est_refrescos.z_index = 3
	_est_bebidas_tex = est_refrescos

	# Estaciones dibujadas para los mundos 2-4. Se muestran u ocultan según
	# el perfil al iniciar el nivel.
	_olla_ctrl = ArteCocina.Estacion_Olla.new()
	_olla_ctrl.name = "Estacion_Olla"
	_olla_ctrl.position = Vector2(12.0, 414.0)
	_olla_ctrl.size = Vector2(242.0, 190.0)
	_olla_ctrl.z_index = 3
	_olla_ctrl.visible = false
	_vista_cocina.add_child(_olla_ctrl)

	_horno_ctrl = ArteCocina.Estacion_Horno.new()
	_horno_ctrl.name = "Estacion_Horno"
	_horno_ctrl.position = Vector2(18.0, 420.0)
	_horno_ctrl.size = Vector2(230.0, 180.0)
	_horno_ctrl.z_index = 3
	_horno_ctrl.visible = false
	_vista_cocina.add_child(_horno_ctrl)

	_sarten_ctrl = ArteCocina.Sarten_Salsa.new()
	_sarten_ctrl.name = "Estacion_Sarten"
	_sarten_ctrl.position = Vector2(266.0, 432.0)
	_sarten_ctrl.size = Vector2(152.0, 150.0)
	_sarten_ctrl.z_index = 3
	_sarten_ctrl.visible = false
	_vista_cocina.add_child(_sarten_ctrl)

	_botellas_ctrl = ArteCocina.Estacion_Botellas.new()
	_botellas_ctrl.name = "Estacion_Botellas"
	_botellas_ctrl.position = Vector2(436.0, 424.0)
	_botellas_ctrl.size = Vector2(146.0, 170.0)
	_botellas_ctrl.z_index = 3
	_botellas_ctrl.visible = false
	_vista_cocina.add_child(_botellas_ctrl)

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

	# Bote de propinas único (centrado sobre la encimera, con sombra suave y
	# contador integrado en la etiqueta inferior PROPINAS · X €).
	_propinas_root = Control.new()
	_propinas_root.name = "Propinas"
	_propinas_root.position = Vector2(1148.0, 480.0)
	_propinas_root.size = Vector2(98.0, 106.0)
	_propinas_root.z_index = 3
	_propinas_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sombra_bote := TextureRect.new()
	sombra_bote.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sombra_bote.stretch_mode = TextureRect.STRETCH_SCALE
	sombra_bote.texture = ArteCocina.textura_sombra_contacto()
	sombra_bote.position = Vector2(8.0, 78.0)
	sombra_bote.size = Vector2(82.0, 24.0)
	sombra_bote.modulate = Color(0.05, 0.04, 0.03, 0.65)
	sombra_bote.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_propinas_root.add_child(sombra_bote)
	var tex_bote := TextureRect.new()
	tex_bote.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_bote.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_bote.texture = ArteCocina.TEX_BOTE_PROPINAS
	tex_bote.position = Vector2(10.0, 6.0)
	tex_bote.size = Vector2(78.0, 86.0)
	tex_bote.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_propinas_root.add_child(tex_bote)
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
	# reales. Los puestos concretos se reconstruyen al empezar cada mundo.
	var fondo := ArteCocina.Fondo_Despensa.new()
	fondo.name = "Fondo_Despensa"
	fondo.position = ZONA_DESPENSA.position
	fondo.size = ZONA_DESPENSA.size
	fondo.z_index = 2
	_vista_cocina.add_child(fondo)
	_fondo_despensa = fondo

	_Reconstruir_Despensa()


func _Reconstruir_Despensa() -> void:
	for nodo in _puestos_nodos:
		if is_instance_valid(nodo):
			nodo.queue_free()
	_puestos_nodos.clear()
	_bandeja_items_ui.clear()

	# Utensilios de apoyo bajo el mostrador. Cambian poco entre mundos, pero
	# se recolocan para no chocar con la nueva fila de puestos.
	var perf: Dictionary = _perfil_actual
	if perf.is_empty():
		perf = Sistema_Cocina.Obtener_Perfil_Restaurante(_restaurante_actual)
	var puestos: Array = perf.get("puestos", [])
	var es_burger: bool = _restaurante_actual == Sistema_Cocina.RESTAURANTE_BURGER
	if _fondo_despensa != null:
		var color_frente := Color("#123e40")
		if _restaurante_actual == Sistema_Cocina.RESTAURANTE_BISTRO:
			color_frente = Color("#4a1d1d")
		elif _restaurante_actual == Sistema_Cocina.RESTAURANTE_MERCADO:
			color_frente = Color("#5b3a1e")
		elif _restaurante_actual == Sistema_Cocina.RESTAURANTE_ALTA:
			color_frente = Color("#0f1b2e")
		_fondo_despensa.configurar(color_frente)

	if es_burger:
		if _despensa_pila == null:
			_despensa_pila = _Anadir_Textura(ArteCocina.TEX_PILA_PLATOS,
				Rect2(390.0, 646.0, 82.0, 62.0), "Despensa_Pila_Platos")
			_despensa_pila.z_index = 3
		if _despensa_bandejas == null:
			_despensa_bandejas = _Anadir_Textura(ArteCocina.TEX_BANDEJAS_APILADAS,
				Rect2(480.0, 652.0, 92.0, 56.0), "Despensa_Bandejas")
			_despensa_bandejas.z_index = 3
	if _despensa_pila != null and is_instance_valid(_despensa_pila):
		_despensa_pila.visible = es_burger
	if _despensa_bandejas != null and is_instance_valid(_despensa_bandejas):
		_despensa_bandejas.visible = es_burger

	var n: int = maxi(1, puestos.size())
	var margen: float = 18.0
	var sep: float = 8.0
	var ancho_total: float = 1280.0 - margen * 2.0
	var ancho: float = (ancho_total - sep * float(n - 1)) / float(n)
	for i in range(n):
		var p: Dictionary = puestos[i]
		var ing: String = str(p.get("id", ""))
		var caja: Rect2
		if es_burger and PUESTOS_INGREDIENTES.has(ing):
			caja = PUESTOS_INGREDIENTES[ing]
		else:
			caja = Rect2(margen + float(i) * (ancho + sep), 620.0, ancho, 98.0)
		var item := ArteCocina.Puesto_Ingrediente.new()
		item.name = "Puesto_%s" % ing
		item.ingrediente = ing
		item.estilo = str(p.get("estilo", ing))
		item.nombre_visible = str(p.get("nombre", ing))
		item.position = caja.position
		item.size = caja.size
		item.z_index = 6
		_vista_cocina.add_child(item)
		_puestos_nodos.append(item)
		_bandeja_items_ui.append({
			"nodo": item,
			"ingrediente": ing,
			"estilo": item.estilo,
			"rect": caja,
		})
	_despensa_restaurante = _restaurante_actual



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
	var base: Dictionary = _Crear_Modal_Base("Modal_Resultados", 46, 780.0, 34, 24)
	_modal_resultados = base["modal"]
	_card_resultados = base["card"]
	_vbox_modal_resultados = base["vbox"]
	_vbox_modal_resultados.add_theme_constant_override("separation", 8)


# ----------------------------------------------------------------------------
# Modal de confirmación al abandonar una partida en curso
# ----------------------------------------------------------------------------

func _Construir_Modal_Confirmar_Salida() -> void:
	var base: Dictionary = _Crear_Modal_Base("Modal_Confirmar_Salida", 45, 590.0, 42, 30)
	_modal_salida = base["modal"]
	_card_salida = base["card"]
	var v: VBoxContainer = base["vbox"]
	v.add_theme_constant_override("separation", 13)

	var tit := ArteModal.crear_titulo("¿SALIR AL MAPA?", 38)
	tit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(tit)

	var txt := ArteModal.texto_modal(
		"Si sales ahora perderás las ventas, las estrellas y la Caja de este nivel.",
		14, ArteModal.CREMA, 500)
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(txt)

	var placa := PanelContainer.new()
	placa.add_theme_stylebox_override("panel", ArteModal.caja_placa(14, 0.30))
	v.add_child(placa)
	_lbl_salida_resumen = ArteModal.texto_cartoon(
		"", 15, ArteModal.ORO_CLARO, ArteModal.NAVY_OSCURO, 3)
	_lbl_salida_resumen.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placa.add_child(_lbl_salida_resumen)

	v.add_child(ArteModal.divisor())

	var btns := VBoxContainer.new()
	btns.add_theme_constant_override("separation", 10)
	v.add_child(btns)

	var btn_seguir := ArteModal.crear_boton(
		"SEGUIR COCINANDO", ArteModal.TEX_BOTON_VERDE, "play", 60, 18)
	btn_seguir.name = "Boton_Seguir_Salida"
	btn_seguir.pressed.connect(_Cancelar_Salida_Partida)
	btns.add_child(btn_seguir)

	var btn_salir := ArteModal.crear_boton(
		"SALIR Y PERDER PROGRESO", ArteModal.TEX_BOTON_ROJO, "x", 60, 17)
	btn_salir.name = "Boton_Confirmar_Salida"
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
	var base: Dictionary = _Crear_Modal_Base("Modal_Pausa", 44, 560.0, 42, 30)
	_modal_pausa = base["modal"]
	_card_pausa = base["card"]
	var v: VBoxContainer = base["vbox"]
	v.add_theme_constant_override("separation", 13)

	var tit := ArteModal.crear_titulo("PAUSA", 46)
	tit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(tit)

	var txt := ArteModal.texto_modal(
		"El tiempo y la paciencia de los clientes están detenidos.",
		14, ArteModal.CREMA, 500)
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(txt)

	# Resumen del servicio en una placa hundida.
	var placa := PanelContainer.new()
	placa.add_theme_stylebox_override("panel", ArteModal.caja_placa(14, 0.30))
	v.add_child(placa)
	var v_resumen := VBoxContainer.new()
	v_resumen.add_theme_constant_override("separation", 2)
	placa.add_child(v_resumen)
	_lbl_pausa_resumen = ArteModal.texto_cartoon(
		"", 15, ArteModal.ORO_CLARO, ArteModal.NAVY_OSCURO, 3)
	_lbl_pausa_resumen.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v_resumen.add_child(_lbl_pausa_resumen)
	var fila_cli := HBoxContainer.new()
	fila_cli.alignment = BoxContainer.ALIGNMENT_CENTER
	fila_cli.add_theme_constant_override("separation", 6)
	v_resumen.add_child(fila_cli)
	fila_cli.add_child(ArteModal.icono_usuarios(16, ArteModal.CREMA))
	_lbl_pausa_clientes = ArteModal.texto_modal("", 13, ArteModal.CREMA, 700)
	fila_cli.add_child(_lbl_pausa_clientes)

	v.add_child(ArteModal.divisor())

	var btns := VBoxContainer.new()
	btns.add_theme_constant_override("separation", 10)
	v.add_child(btns)

	var btn_seguir := ArteModal.crear_boton(
		"SEGUIR COCINANDO", ArteModal.TEX_BOTON_VERDE, "play", 62, 18)
	btn_seguir.name = "Boton_Seguir"
	btn_seguir.pressed.connect(_Reanudar_Partida)
	btns.add_child(btn_seguir)

	var btn_repetir := ArteModal.crear_boton(
		"REPETIR NIVEL", ArteModal.TEX_BOTON_NARANJA, "rotate-ccw", 62, 18)
	btn_repetir.name = "Boton_Repetir"
	btn_repetir.pressed.connect(_Repetir_Desde_Pausa)
	btns.add_child(btn_repetir)

	var btn_mapa := ArteModal.crear_boton(
		"AL MAPA", ArteModal.TEX_BOTON_AZUL, "arrow-left", 62, 18)
	btn_mapa.name = "Boton_Al_Mapa"
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
	_lbl_pausa_resumen.text = "NIVEL %d  ·  TICKET %d €  ·  META %d €" % [
		_nivel_actual, _recaudacion, int(_cfg_nivel_actual.get("meta_3", 115))]
	_lbl_pausa_clientes.text = "QUEDAN %d CLIENTES" % _Clientes_Restantes()
	_modal_pausa.modulate.a = 0.0
	_modal_pausa.visible = true
	_Animar_Entrada_Modal.call_deferred(_modal_pausa, _card_pausa)


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
	_lbl_salida_resumen.text = "TICKET ACTUAL %d €  ·  %d CLIENTES ATENDIDOS" % [
		_recaudacion, _clientes_atendidos]
	_modal_salida.modulate.a = 0.0
	_modal_salida.visible = true
	_Animar_Entrada_Modal.call_deferred(_modal_salida, _card_salida)


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
	_vista_carga.z_index = 55
	add_child(_vista_carga)

	var fondo := TextureRect.new()
	fondo.name = "Fondo_Carga"
	fondo.texture = ArteCocina.TEX_FONDO
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fondo.stretch_mode = TextureRect.STRETCH_SCALE
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vista_carga.add_child(fondo)
	_fondo_carga = fondo

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
	_chef_carga = chef

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
	_modal_maestria.visible = false
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
	_lbl_carga_paso.text = "Preparando la cocina…"
	if _fondo_carga != null:
		_fondo_carga.texture = ArteCocina.fondo_restaurante(_restaurante_actual)
	if _chef_carga != null:
		_chef_carga.texture = ArteCocina.textura_chef(
			"sirviendo" if _restaurante_actual == Sistema_Cocina.RESTAURANTE_BURGER else "pulgar")
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
		var paso: String = "Preparando la cocina…"
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
	_perfil_actual = Sistema_Cocina.Obtener_Perfil_Restaurante(_restaurante_actual)
	if _despensa_restaurante != _restaurante_actual:
		_Reconstruir_Despensa()
	_Actualizar_Estaciones_Mundo()
	_olla = {"ingredientes": [], "estado": "vacio", "progreso": 0.0,
		"raciones": 0, "receta": ""}
	_sarten = {"estado": "lista", "quemado": 0.0, "removido": 0.0}
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
	_tiempo_coccion_b = _tiempo_coccion_patatas
	match str(_perfil_actual.get("estacion_a", {}).get("tipo", "")):
		"parrilla":
			_tiempo_coccion_carne = Sistema_Cocina.Calcular_Tiempo_Coccion(5.2, nv_plancha, destreza)
		"horno":
			_tiempo_coccion_carne = Sistema_Cocina.Calcular_Tiempo_Coccion(5.6, nv_plancha, destreza)
	match str(_perfil_actual.get("estacion_b", {}).get("tipo", "")):
		"plancha":
			_tiempo_coccion_b = Sistema_Cocina.Calcular_Tiempo_Coccion(2.6, nv_plancha, destreza)
		"freidora":
			_tiempo_coccion_b = _tiempo_coccion_patatas
	_tiempo_olla = Sistema_Cocina.Calcular_Tiempo_Coccion(6.2, nv_plancha, destreza)
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

	# Construir estaciones dinámicas según mejoras. La bodega/barra siempre
	# tiene al menos un hueco por tipo de bebida del mundo (tinto + blanco en
	# Alta Cocina, agua + sangría en Mercado) para que el maridaje sea posible
	# desde el nivel 1 sin depender de la mejora de Emplatado.
	var beb_items_perfil: Array = _perfil_actual.get("bebida", {}).get("items", ["refresco"])
	var num_bebidas: int = maxi(Sistema_Cocina.Obtener_Capacidad_Bebidas(nv_emplatado),
		beb_items_perfil.size())
	_Reconstruir_Estaciones(
		num_bebidas,
		Sistema_Cocina.Obtener_Huecos_Platos(nv_emplatado),
		Sistema_Cocina.Obtener_Huecos_Plancha(nv_plancha),
		Sistema_Cocina.Obtener_Cestas_Freidora(nv_plancha)
	)

	# Configurar HUD inicial
	_lbl_cocina_nivel.text = "Nivel %d" % nivel
	_pill_cocina_turno.visible = _en_turno_partida
	_pill_cocina_combo.visible = false
	_lbl_estado_propinas.text = "PROPINAS · 0 €"
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
	var texto_chef: String = "¡Hoy tenemos %d clientes!" % _clientes_totales
	if str(_perfil_actual.get("mecanica", "montaje")) != "montaje":
		texto_chef = "¡%d clientes! %s" % [_clientes_totales,
			str(_perfil_actual.get("mecanica_titulo", ""))]
	_Mostrar_Chef("sirviendo", texto_chef, Color("#9a3412"), 2.8)
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


func _Plato_Vacio() -> Dictionary:
	return {
		"pan": false, "carnes": 0, "queso": false, "lechuga": false, "tomate": false,
		"proteina": "", "punto": "", "guiso": "", "guarnicion": "", "salsa": "",
		"extra": "", "flor": false
	}


func _Reconstruir_Estaciones(num_bebidas: int, num_platos: int, num_plancha: int, num_freidora: int) -> void:
	var perf: Dictionary = _perfil_actual
	if perf.is_empty():
		perf = Sistema_Cocina.Obtener_Perfil_Restaurante(_restaurante_actual)
	var est_a: Dictionary = perf.get("estacion_a", {})
	var est_b: Dictionary = perf.get("estacion_b", {})
	var tipo_a: String = str(est_a.get("tipo", "plancha"))
	var tipo_b: String = str(est_b.get("tipo", "freidora"))
	var beb_cfg: Dictionary = perf.get("bebida", {})
	var beb_items: Array = beb_cfg.get("items", ["refresco"])

	# --- Bebidas --------------------------------------------------------------
	for c in _contenedor_bebidas.get_children():
		c.queue_free()
	_bebidas.clear()
	_slots_bebidas_ui.clear()
	_bebida_items_actuales.clear()
	_fx_bebidas.clear()
	var sep_beb: float = 32.0 if num_bebidas == 2 else (31.0 if num_bebidas >= 3 else 0.0)
	var ancho_vaso: float = 44.0 if num_bebidas <= 2 else 38.0
	var total_beb: float = ancho_vaso + sep_beb * float(maxi(0, num_bebidas - 1))
	var x0_beb: float = 526.0 - total_beb * 0.5
	for i in range(num_bebidas):
		var item_beb: String = str(beb_items[i % maxi(1, beb_items.size())])
		_bebida_items_actuales.append(item_beb)
		_bebidas.append({"estado": "listo", "progreso": 1.0, "item": item_beb})
		_fx_bebidas.append(0.0)
		var nodo := ArteCocina.Bebida.new()
		nodo.name = "Bebida_%d" % i
		nodo.tipo = item_beb
		nodo.position = Vector2(x0_beb + sep_beb * float(i), 514.0)
		nodo.size = Vector2(ancho_vaso, 76.0)
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
		_platos.append(_Plato_Vacio())
		var nodo := ArteCocina.Plato.new()
		nodo.name = "Plato_%d" % i
		nodo.restaurante = _restaurante_actual
		var celda: Rect2 = celdas_platos[i]
		nodo.position = _bandeja_emplatado.position + celda.position
		nodo.size = celda.size
		_contenedor_platos.add_child(nodo)
		_slots_platos_ui.append({
			"nodo": nodo,
			"rect": Rect2(nodo.position, nodo.size),
			"pop": 0.0,
		})

	# --- Estación A (plancha / parrilla / horno) -----------------------------
	for c in _contenedor_plancha.get_children():
		c.queue_free()
	_plancha.clear()
	_slots_plancha_ui.clear()
	_fx_plancha.clear()
	var centros_fogones: Array[Vector2] = [
		Vector2(103.0, 462.0), Vector2(184.0, 468.0),
		Vector2(84.0, 496.0), Vector2(169.0, 505.0)
	]
	var n_slots_a: int = 0
	if tipo_a in ["plancha", "parrilla", "horno"]:
		n_slots_a = num_plancha
	var tipo_slot_a: String = "carne"
	if tipo_a == "parrilla":
		tipo_slot_a = "filete"
	elif tipo_a == "horno":
		tipo_slot_a = "generico"
	for i in range(n_slots_a):
		_plancha.append({"estado": "vacio", "progreso": 0.0, "quemado": 0.0,
			"avisado": false, "item": "", "punto": ""})
		_fx_plancha.append(0.0)
		var nodo := ArteCocina.Punto_Coccion.new()
		nodo.name = "Coccion_A_%d" % i
		nodo.tipo = tipo_slot_a
		var centro: Vector2 = centros_fogones[i % centros_fogones.size()]
		if tipo_a == "horno":
			centro = Vector2(60.0 + float(i % 2) * 92.0, 486.0 + float(i / 2) * 46.0)
		nodo.position = centro - Vector2(32.0, 26.0)
		nodo.size = Vector2(64.0, 52.0)
		_contenedor_plancha.add_child(nodo)
		_slots_plancha_ui.append({
			"nodo": nodo,
			"rect": Rect2(nodo.position, nodo.size),
		})

	# --- Estación B (freidora / plancha de huevos / salsa) -------------------
	for c in _contenedor_freidora.get_children():
		c.queue_free()
	_freidora.clear()
	_slots_freidora_ui.clear()
	_fx_freidora.clear()
	var n_slots_b: int = 0
	var tipo_slot_b: String = "patatas"
	if tipo_b == "freidora":
		n_slots_b = num_freidora
	elif tipo_b == "plancha":
		n_slots_b = 2
		tipo_slot_b = "huevo"
	var centros_b: Array[Vector2] = [Vector2(316.0, 504.0), Vector2(370.0, 510.0)]
	if tipo_b == "plancha":
		centros_b = [Vector2(300.0, 482.0), Vector2(362.0, 506.0)]
	for i in range(n_slots_b):
		_freidora.append({"estado": "vacio", "progreso": 0.0, "quemado": 0.0,
			"avisado": false, "item": "", "punto": ""})
		_fx_freidora.append(0.0)
		var nodo := ArteCocina.Punto_Coccion.new()
		nodo.name = "Coccion_B_%d" % i
		nodo.tipo = tipo_slot_b
		var centro: Vector2 = centros_b[i % centros_b.size()]
		nodo.position = centro - Vector2(29.0, 24.0)
		nodo.size = Vector2(58.0, 48.0)
		_contenedor_freidora.add_child(nodo)
		_slots_freidora_ui.append({
			"nodo": nodo,
			"rect": Rect2(nodo.position, nodo.size),
		})

	# Etiquetas con capacidades y nombre del mundo
	var nombre_a: String = str(est_a.get("nombre", "ESTACIÓN"))
	var nombre_b: String = str(est_b.get("nombre", "ESTACIÓN"))
	if tipo_a == "olla":
		_lbl_estado_plancha.text = "OLLA · %d raciones" % 4
	elif tipo_a == "horno":
		_lbl_estado_plancha.text = "%s · %d huecos" % [nombre_a, n_slots_a]
	else:
		_lbl_estado_plancha.text = "%s · %d hueco%s" % [nombre_a, n_slots_a,
			"" if n_slots_a == 1 else "s"]
	if tipo_b == "sarten":
		_lbl_estado_freidora.text = "SALSAS · remover"
	elif tipo_b == "plancha":
		_lbl_estado_freidora.text = "PLANCHA · %d huecos" % n_slots_b
	else:
		_lbl_estado_freidora.text = "%s · %d cesta%s" % [nombre_b, n_slots_b,
			"" if n_slots_b == 1 else "s"]
	_lbl_estado_bebidas.text = "%s · %d" % [str(beb_cfg.get("nombre", "BEBIDAS")), num_bebidas]
	_lbl_estado_platos.text = "EMPLATADO · %d/%d platos" % [num_platos, HUECOS_EMPLATADO]


## Ajusta fondo, estaciones y tintes al mundo que se va a jugar.
func _Actualizar_Estaciones_Mundo() -> void:
	var perf: Dictionary = _perfil_actual
	if perf.is_empty():
		return
	var est_a: Dictionary = perf.get("estacion_a", {})
	var est_b: Dictionary = perf.get("estacion_b", {})
	var beb: Dictionary = perf.get("bebida", {})
	var tipo_a: String = str(est_a.get("tipo", "plancha"))
	var tipo_b: String = str(est_b.get("tipo", "freidora"))
	var tipo_beb: String = str(beb.get("tipo", "refresco"))
	if _fondo_cocina != null:
		_fondo_cocina.texture = ArteCocina.fondo_restaurante(_restaurante_actual)

	# Estación A
	if _est_plancha_tex != null:
		_est_plancha_tex.visible = tipo_a in ["plancha", "parrilla"]
		_est_plancha_tex.texture = ArteCocina.TEX_PLANCHA
	if _horno_ctrl != null:
		_horno_ctrl.visible = tipo_a == "horno"
	if _olla_ctrl != null:
		_olla_ctrl.visible = tipo_a == "olla"
	# Estación B
	if _est_freidora_tex != null:
		_est_freidora_tex.visible = tipo_b == "freidora" or tipo_b == "plancha"
		_est_freidora_tex.texture = ArteCocina.TEX_FREIDORA if tipo_b == "freidora" else ArteCocina.TEX_PLANCHA
		if tipo_b == "plancha":
			_est_freidora_tex.position = Vector2(262.0, 430.0)
			_est_freidora_tex.size = Vector2(156.0, 162.0)
		else:
			_est_freidora_tex.position = Vector2(266.0, 438.0)
			_est_freidora_tex.size = Vector2(150.0, 143.0)
	if _sarten_ctrl != null:
		_sarten_ctrl.visible = tipo_b == "sarten"
	# Bebidas
	var es_textura: bool = tipo_beb in ["refresco", "cafetera"]
	if _est_bebidas_tex != null:
		_est_bebidas_tex.visible = es_textura
		if tipo_beb == "cafetera":
			_est_bebidas_tex.texture = ArteCocina.TEX_CAFETERA
			_est_bebidas_tex.position = Vector2(438.0, 422.0)
			_est_bebidas_tex.size = Vector2(138.0, 170.0)
		else:
			_est_bebidas_tex.texture = ArteCocina.TEX_REFRESCOS
			_est_bebidas_tex.position = Vector2(432.0, 418.0)
			_est_bebidas_tex.size = Vector2(150.0, 178.0)
	if _botellas_ctrl != null:
		_botellas_ctrl.visible = not es_textura
		_botellas_ctrl.tipo = "bodega" if tipo_beb == "bodega" else "barra"
	# Tinte del mostrador para integrarlo con cada local
	var tinte := Color(str(perf.get("tinte_mostrador", "#ffffff")))
	for nodo in _vista_cocina.get_children():
		if nodo.name in ["Encimera_Mostrador", "Frente_Mostrador"] and nodo is CanvasItem:
			(nodo as CanvasItem).modulate = tinte



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

	# Olla de mercado y sartén de alta cocina: se arrastran sus elaboraciones
	# al pase, igual que la carne o las patatas del mundo 1.
	if _olla_ctrl != null and _olla_ctrl.visible:
		_arrastre.registrar_origen(ZONA_PLANCHA, {"tipo": "olla"}, _Obtener_Payload_Olla)
	if _sarten_ctrl != null and _sarten_ctrl.visible:
		_arrastre.registrar_origen(ZONA_FREIDORA, {"tipo": "sarten"}, _Obtener_Payload_Sarten)

	# Destinos
	_arrastre.registrar_destino(ZONA_PLANCHA, {"tipo": "plancha"}, _Acepta_Plancha)
	if _olla_ctrl != null and _olla_ctrl.visible:
		_arrastre.registrar_destino(ZONA_PLANCHA, {"tipo": "olla"}, _Acepta_Olla)
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
		# Toque corto sobre el cliente: sirve el plato/bebida que tenga listo
		# y que ese cliente esté esperando.
		_arrastre.registrar_toque(_Rect_Cliente_Destino(i),
			{"tipo": "cliente", "indice": i})
	_arrastre.registrar_destino(_papelera_rect, {"tipo": "papelera"}, _Acepta_Papelera)
	_arrastre.registrar_toque(_papelera_rect, {"tipo": "papelera"})

	# Zonas de toque de estaciones y pase. Funcionan como respaldo cuando el
	# origen no puede arrastrarse (plato vacío, carne aún cruda, bebida
	# llenándose...), para que el toque siempre dé una respuesta clara.
	for i in range(_slots_plancha_ui.size()):
		_arrastre.registrar_toque(_slots_plancha_ui[i]["rect"],
			{"tipo": "plancha", "indice": i})
	for i in range(_slots_freidora_ui.size()):
		_arrastre.registrar_toque(_slots_freidora_ui[i]["rect"],
			{"tipo": "freidora", "indice": i})
	for i in range(_slots_bebidas_ui.size()):
		_arrastre.registrar_toque(_slots_bebidas_ui[i]["rect"],
			{"tipo": "bebida", "indice": i})
	for i in range(_slots_platos_ui.size()):
		_arrastre.registrar_toque(_slots_platos_ui[i]["rect"],
			{"tipo": "plato", "indice": i})


func _Obtener_Payload_Bandeja(datos: Dictionary) -> Dictionary:
	if not _jugando:
		return {}
	var ing: String = str(datos.get("ingrediente", ""))
	if ing == "":
		return {}
	var tex: Texture2D = ArteCocina.textura_item(ing)
	var dibujante := func(c: CanvasItem, centro: Vector2) -> void:
		if ing == "pan":
			ArteCocina.dibujar_pan_cerrado(c, centro + Vector2(0.0, 26.0), 82.0, 1.0)
		elif not ArteCocina.dibujar_ingrediente_icono(c, ing, centro, 86.0, 1.0):
			ArteCocina.dibujar_tex(c, tex, Rect2(centro - Vector2(48.0, 48.0), Vector2(96.0, 96.0)))
	return {
		"payload": {"tipo": "ingrediente", "id": ing},
		"textura": tex,
		"dibujar": dibujante,
		"tam": Vector2(96.0, 96.0),
	}


func _Obtener_Payload_Olla(_datos: Dictionary) -> Dictionary:
	if not _jugando or str(_olla.get("estado", "")) != "listo" \
			or int(_olla.get("raciones", 0)) <= 0:
		if _jugando and _olla_ctrl != null:
			_Mostrar_Feedback_En_Control(_olla_ctrl, "La olla no está lista", Estilos_UI.AVISO)
		return {}
	var receta: String = str(_olla.get("receta", ""))
	var dibujante := func(c: CanvasItem, centro: Vector2) -> void:
		ArteCocina.dibujar_plato_mercado(c, centro, 110.0, receta, "", 1.0)
	return {
		"payload": {"tipo": "guiso", "guiso": receta},
		"textura": ArteCocina.TEX_PLATO_PERSPECTIVA,
		"dibujar": dibujante,
		"tam": Vector2(100.0, 100.0),
	}


func _Obtener_Payload_Sarten(_datos: Dictionary) -> Dictionary:
	if not _jugando or str(_sarten.get("estado", "")) != "lista":
		return {}
	var dibujante := func(c: CanvasItem, centro: Vector2) -> void:
		c.draw_circle(centro, 28.0, Color("#7f1d1d"))
		c.draw_arc(centro, 30.0, 0.0, TAU, 24, Color("#fbbf24", 0.75), 2.0, true)
	return {
		"payload": {"tipo": "salsa"},
		"textura": ArteCocina.TEX_SALSERA,
		"dibujar": dibujante,
		"tam": Vector2(80.0, 80.0),
	}


func _Obtener_Payload_Plancha(datos: Dictionary) -> Dictionary:
	var i: int = int(datos.get("indice", -1))
	if i < 0 or i >= _plancha.size():
		return {}
	var est: String = str(_plancha[i]["estado"])
	if est == "vacio":
		return {}
	var item: String = str(_plancha[i].get("item", "carne"))
	var punto: String = str(_plancha[i].get("punto", ""))
	var quemado: bool = est == "quemado" or est == "pasado" or punto == "quemado"
	var punto_vis: String = punto
	if quemado:
		punto_vis = "quemado"
	var dibujante := func(c: CanvasItem, centro: Vector2) -> void:
		if _restaurante_actual == Sistema_Cocina.RESTAURANTE_BISTRO:
			ArteCocina.dibujar_filete(c, centro, 86.0, punto_vis, 1.0)
		elif not ArteCocina.dibujar_ingrediente_icono(c, item, centro, 82.0, 1.0):
			var tex_f: Texture2D = ArteCocina.TEX_CARNE_QUEMADA if quemado else (
				ArteCocina.TEX_CARNE_CRUDA if est == "cocinando" else ArteCocina.TEX_CARNE_HECHA)
			ArteCocina.dibujar_tex(c, tex_f, Rect2(centro - Vector2(48.0, 32.0), Vector2(96.0, 64.0)))
	# Todos los estados se pueden arrastrar. La carne quemada o pasada solo
	# puede ir a la basura; la que aún se está haciendo se puede coger para
	# recolocarla, pero el pase la rechaza con un aviso claro.
	var tipo_payload: String = "proteina"
	if quemado:
		tipo_payload = "carne_quemada"
	elif _restaurante_actual != Sistema_Cocina.RESTAURANTE_BISTRO and est != "listo" and est != "alerta":
		tipo_payload = "carne_cruda"
	elif _restaurante_actual == Sistema_Cocina.RESTAURANTE_BURGER:
		tipo_payload = "carne_lista"
	return {
		"payload": {
			"tipo": tipo_payload,
			"proteina": "filete" if _restaurante_actual == Sistema_Cocina.RESTAURANTE_BISTRO else item,
			"punto": punto_vis,
			"estado": est,
			"indice": i,
		},
		"textura": ArteCocina.TEX_CARNE_HECHA,
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
		return {}
	var item: String = str(_freidora[i].get("item", "patatas"))
	var quemadas: bool = est == "quemado"
	var dibujante := func(c: CanvasItem, centro: Vector2) -> void:
		if item == "huevo":
			ArteCocina.dibujar_ingrediente_icono(c, "huevo", centro, 70.0, 1.0)
		else:
			var tinte_p: Color = Color(0.32, 0.22, 0.16, 1.0) if quemadas else Color.WHITE
			ArteCocina.dibujar_tex(c, ArteCocina.TEX_PATATAS,
				Rect2(centro - Vector2(40.0, 40.0), Vector2(80.0, 80.0)), tinte_p)
	return {
		"payload": {
			"tipo": "huevo_listo" if item == "huevo" else (
				"patatas_quemadas" if est == "quemado" else "patatas_listas"),
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
		return {}
	var item: String = str(_bebidas[i].get("item", "refresco"))
	var dibujante := func(c: CanvasItem, centro: Vector2) -> void:
		ArteCocina.dibujar_item(c, item, centro, 82.0, 1.0)
	return {
		"payload": {"tipo": "bebida", "indice": i, "item": item},
		"textura": ArteCocina.textura_item(item),
		"dibujar": dibujante,
		"tam": Vector2(68.0, 108.0),
	}


func _Obtener_Payload_Plato(datos: Dictionary) -> Dictionary:
	var i: int = int(datos.get("indice", -1))
	if i < 0 or i >= _platos.size():
		return {}
	var p: Dictionary = _platos[i]
	var vacio: bool = _Plato_Esta_Vacio(p)
	if vacio:
		_Mostrar_Feedback_En_Control(_slots_platos_ui[i]["nodo"], "Plato vacío", Estilos_UI.TINTA_SUAVE)
		return {}
	var estado_plato: Dictionary = p.duplicate()
	var receta: String = _Receta_De_Plato(p)
	var dibujante := func(c: CanvasItem, centro: Vector2) -> void:
		_Dibujar_Plato_Borrador(c, centro, 118.0, estado_plato)
	return {
		"payload": {"tipo": "plato", "indice": i, "receta": receta},
		"textura": ArteCocina.TEX_PLATO_PERSPECTIVA,
		"dibujar": dibujante,
		"tam": Vector2(100.0, 100.0),
	}


func _Acepta_Plancha(payload: Dictionary) -> bool:
	if str(payload.get("tipo", "")) != "ingrediente":
		return false
	var ing: String = str(payload.get("id", ""))
	for s in _plancha:
		if str(s["estado"]) != "vacio":
			continue
		if _Ingrediente_Aceptado_Estacion_A(ing):
			return true
	return false


func _Ingrediente_Aceptado_Estacion_A(ing: String) -> bool:
	if _restaurante_actual == Sistema_Cocina.RESTAURANTE_BURGER \
			or _restaurante_actual == Sistema_Cocina.RESTAURANTE_BISTRO:
		return ing == "carne"
	if _restaurante_actual == Sistema_Cocina.RESTAURANTE_ALTA:
		return ing in ["solomillo", "lubina", "pato"]
	return false


func _Acepta_Olla(payload: Dictionary) -> bool:
	if str(payload.get("tipo", "")) != "ingrediente":
		return false
	return Sistema_Cocina.Olla_Acepta_Ingrediente(
		_olla.get("ingredientes", []), str(payload.get("id", "")))


func _Acepta_Freidora(payload: Dictionary) -> bool:
	if str(payload.get("tipo", "")) != "ingrediente":
		return false
	var ing: String = str(payload.get("id", ""))
	if _restaurante_actual == Sistema_Cocina.RESTAURANTE_MERCADO:
		if ing != "huevo":
			return false
	elif _restaurante_actual == Sistema_Cocina.RESTAURANTE_ALTA:
		return false
	else:
		if ing != "patatas":
			return false
	for s in _freidora:
		if str(s["estado"]) == "vacio":
			return true
	return false


func _Puede_Cocinar_En_Plancha(payload: Dictionary, indice: int) -> bool:
	if str(payload.get("tipo", "")) != "ingrediente":
		return false
	if indice < 0 or indice >= _plancha.size():
		return false
	if str(_plancha[indice]["estado"]) != "vacio":
		return false
	return _Ingrediente_Aceptado_Estacion_A(str(payload.get("id", "")))


func _Puede_Freir_En_Cesta(payload: Dictionary, indice: int) -> bool:
	if str(payload.get("tipo", "")) != "ingrediente":
		return false
	if indice < 0 or indice >= _freidora.size():
		return false
	if str(_freidora[indice]["estado"]) != "vacio":
		return false
	var ing: String = str(payload.get("id", ""))
	if _restaurante_actual == Sistema_Cocina.RESTAURANTE_MERCADO:
		return ing == "huevo"
	if _restaurante_actual == Sistema_Cocina.RESTAURANTE_ALTA:
		return false
	return ing == "patatas"


func _Puede_Anadir_A_Plato(payload: Dictionary, indice: int) -> bool:
	if indice < 0 or indice >= _platos.size():
		return false
	var p: Dictionary = _platos[indice]
	var tipo: String = str(payload.get("tipo", ""))
	if _restaurante_actual == Sistema_Cocina.RESTAURANTE_BURGER:
		match tipo:
			"ingrediente":
				var ing: String = str(payload.get("id", ""))
				if ing == "pan":
					return not bool(p["pan"])
				if ing in ["queso", "lechuga", "tomate"]:
					return bool(p["pan"]) and not bool(p[ing])
				return false
			"carne_lista":
				return bool(p["pan"]) and int(p["carnes"]) < 2
			"patatas_listas":
				return false
		return false

	if _restaurante_actual == Sistema_Cocina.RESTAURANTE_BISTRO:
		if tipo == "proteina":
			var estado_p: String = str(payload.get("estado", "listo"))
			return str(p.get("proteina", "")) == "" \
				and str(payload.get("proteina", "")) == "filete" \
				and str(payload.get("punto", "")) in ["poco_hecho", "al_punto", "hecho"] \
				and estado_p in ["listo", "cocinando"]
		if tipo == "patatas_listas":
			return str(p.get("guarnicion", "")) == ""
		if tipo == "ingrediente":
			var ing_b: String = str(payload.get("id", ""))
			if ing_b == "salsa":
				return str(p.get("salsa", "")) == ""
		return false

	if _restaurante_actual == Sistema_Cocina.RESTAURANTE_MERCADO:
		if tipo == "guiso":
			return str(p.get("guiso", "")) == ""
		if tipo == "huevo_listo":
			return str(p.get("guiso", "")) == "pisto" and str(p.get("extra", "")) == ""
		return false

	if _restaurante_actual == Sistema_Cocina.RESTAURANTE_ALTA:
		if tipo == "proteina":
			return str(p.get("proteina", "")) == "" \
				and str(payload.get("proteina", "")) in ["solomillo", "lubina", "pato"] \
				and str(payload.get("estado", "listo")) == "listo"
		if tipo == "salsa":
			return str(p.get("salsa", "")) == ""
		if tipo == "ingrediente":
			var ing_a: String = str(payload.get("id", ""))
			if ing_a in ["pure", "esparragos"]:
				return str(p.get("guarnicion", "")) == ""
			if ing_a == "flor":
				return not bool(p.get("flor", false))
		return false
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
	var tipo: String = str(payload.get("tipo", ""))
	if tipo == "plato":
		var rec: String = str(payload.get("receta", ""))
		return rec != "" and _Cliente_Necesita_Item(cl, rec)
	if tipo == "bebida":
		var item: String = str(payload.get("item", "refresco"))
		return _Cliente_Necesita_Item(cl, item)
	if tipo == "patatas_listas":
		return _restaurante_actual == Sistema_Cocina.RESTAURANTE_BURGER \
			and _Cliente_Necesita_Item(cl, "patatas")
	if tipo == "ingrediente" and _restaurante_actual == Sistema_Cocina.RESTAURANTE_BISTRO:
		var ing: String = str(payload.get("id", ""))
		if ing == "tarta_cereza":
			return _Cliente_Necesita_Item(cl, "tarta_cereza")
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
	if tipo == "plancha":
		_on_plancha_pulsada(int(datos.get("indice", -1)))
		return
	if tipo == "freidora":
		_on_freidora_pulsada(int(datos.get("indice", -1)))
		return
	if tipo == "bebida":
		_on_bebida_pulsada(int(datos.get("indice", -1)))
		return
	if tipo == "plato":
		_on_plato_pulsado(int(datos.get("indice", -1)))
		return
	if _sfx != null:
		_sfx.reproducir("click", -22.0, 1.4)
	var nodo: Control = null
	match tipo:
		"olla":
			nodo = _olla_ctrl
		"sarten":
			nodo = _sarten_ctrl
	if tipo == "olla":
		_Servir_Racion_Olla()
		return
	if tipo == "sarten":
		_Remover_Salsa()
		return
	if nodo != null:
		var pista: String = str(payload.get("pista", "Mantén pulsado y arrastra"))
		_Mostrar_Feedback_En_Control(nodo, pista, Color("#fde68a"), -12.0)


## Toques de respaldo en zonas sin payload arrastrable (plato vacío, carne
## aún cruda, bebida llenándose, cliente o papelera).
func _on_zona_tocada(datos: Dictionary) -> void:
	if not _jugando or datos.is_empty():
		return
	match str(datos.get("tipo", "")):
		"cliente":
			_on_cliente_pulsado(int(datos.get("indice", -1)))
		"plancha":
			_on_plancha_pulsada(int(datos.get("indice", -1)))
		"freidora":
			_on_freidora_pulsada(int(datos.get("indice", -1)))
		"bebida":
			_on_bebida_pulsada(int(datos.get("indice", -1)))
		"plato":
			_on_plato_pulsado(int(datos.get("indice", -1)))
		"papelera":
			_on_boton_papelera()


func _Accion_Rapida_Ingrediente(ing: String) -> void:
	if ing == "":
		return
	if _sfx != null:
		_sfx.reproducir("click", -22.0, 1.4)
	if _restaurante_actual == Sistema_Cocina.RESTAURANTE_BURGER:
		_Accion_Rapida_Burger(ing)
		return
	if _restaurante_actual == Sistema_Cocina.RESTAURANTE_BISTRO:
		_Accion_Rapida_Bistro(ing)
		return
	if _restaurante_actual == Sistema_Cocina.RESTAURANTE_MERCADO:
		_Accion_Rapida_Mercado(ing)
		return
	if _restaurante_actual == Sistema_Cocina.RESTAURANTE_ALTA:
		_Accion_Rapida_Alta(ing)
		return


func _Accion_Rapida_Burger(ing: String) -> void:
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


func _Accion_Rapida_Bistro(ing: String) -> void:
	match ing:
		"carne":
			var idx: int = _Primer_Hueco_Plancha()
			if idx >= 0:
				if _Soltar_En_Plancha({"tipo": "ingrediente", "id": "carne"}, idx):
					_Animar_Ingrediente_A_Rect("carne", _Rect_Bandeja("carne"),
						_slots_plancha_ui[idx]["rect"])
			else:
				_Mostrar_Feedback_En_Control(_Nodo_Puesto("carne"),
					"La parrilla está llena", Estilos_UI.AVISO, -8.0)
		"patatas":
			var idx_f: int = _Primer_Hueco_Freidora()
			if idx_f >= 0:
				if _Soltar_En_Freidora({"tipo": "ingrediente", "id": "patatas"}, idx_f):
					_Animar_Ingrediente_A_Rect("patatas", _Rect_Bandeja("patatas"),
						_slots_freidora_ui[idx_f]["rect"])
			else:
				_Soltar_En_Freidora({"tipo": "ingrediente", "id": "patatas"})
		"salsa":
			var payload_s := {"tipo": "ingrediente", "id": "salsa"}
			var idx_s: int = _Primer_Plato_Que_Complete_Pedido(payload_s,
				{"salsa": "salsa"})
			if idx_s < 0:
				for idx_p in _Orden_Busqueda_Platos():
					if str(_platos[idx_p].get("salsa", "")) == "":
						idx_s = idx_p
						break
			if idx_s >= 0:
				if _Soltar_En_Plato(payload_s, idx_s):
					_Animar_Ingrediente_A_Rect("salsa", _Rect_Bandeja("salsa"),
						_slots_platos_ui[idx_s]["rect"])
				return
			_Mostrar_Feedback_En_Control(_Nodo_Puesto("salsa"),
				"Todos los platos tienen salsa", Estilos_UI.TINTA_SUAVE, -8.0)
		"tarta_cereza":
			_Mostrar_Feedback_En_Control(_Nodo_Puesto("tarta_cereza"),
				"Arrastra la tarta al cliente", Color("#fde68a"), -8.0)


func _Accion_Rapida_Mercado(ing: String) -> void:
	if ing == "huevo":
		var idx: int = _Primer_Hueco_Freidora()
		if idx >= 0:
			if _Soltar_En_Freidora({"tipo": "ingrediente", "id": "huevo"}, idx):
				_Animar_Ingrediente_A_Rect("huevo", _Rect_Bandeja("huevo"),
					_slots_freidora_ui[idx]["rect"])
		else:
			_Mostrar_Feedback_En_Control(_Nodo_Puesto("huevo"),
				"La plancha está llena", Estilos_UI.AVISO, -8.0)
		return
	_Anadir_Ingrediente_Olla(ing)


func _Accion_Rapida_Alta(ing: String) -> void:
	if ing in ["solomillo", "lubina", "pato"]:
		var idx: int = _Primer_Hueco_Plancha()
		if idx >= 0:
			if _Soltar_En_Plancha({"tipo": "ingrediente", "id": ing}, idx):
				_Animar_Ingrediente_A_Rect(ing, _Rect_Bandeja(ing),
					_slots_plancha_ui[idx]["rect"])
		else:
			_Mostrar_Feedback_En_Control(_Nodo_Puesto(ing),
				"El horno está lleno", Estilos_UI.AVISO, -8.0)
		return
	if ing in ["pure", "esparragos", "flor"]:
		for idx_p in _Orden_Busqueda_Platos():
			var pl: Dictionary = _platos[idx_p]
			var libre: bool = false
			if ing == "flor":
				libre = not bool(pl.get("flor", false))
			else:
				libre = str(pl.get("guarnicion", "")) == ""
			if libre:
				if _Soltar_En_Plato({"tipo": "ingrediente", "id": ing}, idx_p):
					_Animar_Ingrediente_A_Rect(ing, _Rect_Bandeja(ing),
						_slots_platos_ui[idx_p]["rect"])
				return
		_Mostrar_Feedback_En_Control(_Nodo_Puesto(ing),
			"No hay plato libre para eso", Estilos_UI.TINTA_SUAVE, -8.0)


func _Anadir_Ingrediente_Olla(ing: String) -> void:
	if str(_olla.get("estado", "vacio")) == "cocinando":
		_Mostrar_Feedback_En_Control(_olla_ctrl, "El guiso se está cociendo", Estilos_UI.AVISO)
		return
	if str(_olla.get("estado", "vacio")) == "listo":
		_Mostrar_Feedback_En_Control(_olla_ctrl, "Sirve las raciones antes de empezar otro guiso",
			Estilos_UI.AVISO)
		return
	var ingrs: Array = _olla.get("ingredientes", [])
	if not Sistema_Cocina.Olla_Acepta_Ingrediente(ingrs, ing):
		_Mostrar_Feedback_En_Control(_olla_ctrl, "Ese ingrediente no va con el guiso",
			Estilos_UI.AVISO)
		return
	ingrs.append(ing)
	_olla["ingredientes"] = ingrs
	if ingrs.size() >= 2:
		var receta: String = Sistema_Cocina.Resolver_Receta_Olla(ingrs)
		if receta == "":
			_Mostrar_Feedback_En_Control(_olla_ctrl, "Esa mezcla no es ningún guiso",
				Estilos_UI.AVISO)
			_olla["ingredientes"] = []
		else:
			_olla["receta"] = receta
			_olla["estado"] = "cocinando"
			_olla["progreso"] = 0.0
			_olla["raciones"] = 0
			_Mostrar_Banner("¡%s A LA OLLA!" % str(Sistema_Cocina.Receta_De_Olla(receta).get(
				"nombre_corto", receta)).to_upper(), Color("#fbbf24"))
	_Actualizar_Olla_UI()


func _Servir_Racion_Olla() -> void:
	if str(_olla.get("estado", "")) != "listo" or int(_olla.get("raciones", 0)) <= 0:
		_Mostrar_Feedback_En_Control(_olla_ctrl, "La olla todavía no está lista", Estilos_UI.AVISO)
		return
	var idx: int = -1
	for idx_p in _Orden_Busqueda_Platos():
		if str(_platos[idx_p].get("guiso", "")) == "":
			idx = idx_p
			break
	if idx < 0:
		_Mostrar_Feedback_En_Control(_olla_ctrl, "No hay platos libres en el pase", Estilos_UI.AVISO)
		return
	var receta: String = str(_olla.get("receta", ""))
	if not _Soltar_En_Plato({"tipo": "guiso", "guiso": receta}, idx):
		return
	_Animar_Ingrediente_A_Rect(receta, ZONA_PLANCHA, _slots_platos_ui[idx]["rect"])


func _Limpiar_Slot_Coccion(lista: Array[Dictionary], ui: Array[Dictionary], indice: int,
		etiqueta: String) -> void:
	if indice < 0 or indice >= lista.size():
		return
	lista[indice]["estado"] = "vacio"
	lista[indice]["progreso"] = 0.0
	lista[indice]["quemado"] = 0.0
	lista[indice]["avisado"] = false
	lista[indice]["item"] = ""
	lista[indice]["punto"] = ""
	_Actualizar_Slot_Coccion_UI(lista[indice], ui[indice], etiqueta)


func _Actualizar_Olla_UI() -> void:
	if _olla_ctrl == null:
		return
	_olla_ctrl.ingredientes = (_olla.get("ingredientes", []) as Array).duplicate()
	_olla_ctrl.estado = str(_olla.get("estado", "vacio"))
	_olla_ctrl.progreso = float(_olla.get("progreso", 0.0))
	_olla_ctrl.raciones = int(_olla.get("raciones", 0))
	_olla_ctrl.receta = str(_olla.get("receta", ""))
	_olla_ctrl.queue_redraw()


func _Remover_Salsa() -> void:
	if _sarten_ctrl == null:
		return
	if str(_sarten.get("estado", "lista")) == "arruinada":
		_sarten = {"estado": "lista", "quemado": 0.0, "removido": 0.0}
		_Mostrar_Feedback_En_Control(_sarten_ctrl, "Salsa nueva", Color("#86efac"))
	else:
		_sarten["quemado"] = maxf(0.0, float(_sarten.get("quemado", 0.0)) - 0.34)
		_sarten["removido"] = 1.0
		_Mostrar_Feedback_En_Control(_sarten_ctrl, "Removido", Color("#fde68a"))
	_Actualizar_Sarten_UI()


func _Actualizar_Sarten_UI() -> void:
	if _sarten_ctrl == null:
		return
	_sarten_ctrl.estado = str(_sarten.get("estado", "lista"))
	_sarten_ctrl.quemado = float(_sarten.get("quemado", 0.0))
	_sarten_ctrl.removido = float(_sarten.get("removido", 0.0))
	_sarten_ctrl.queue_redraw()


## Primer plato en el que añadir `mutacion` produce una receta que algún
## cliente está esperando. Se usa para que los toques rápidos del Bistró no
## metan la proteína/guarnición/salsa en el plato equivocado.
func _Primer_Plato_Que_Complete_Pedido(payload: Dictionary,
		mutacion: Dictionary) -> int:
	for idx in _Orden_Busqueda_Platos():
		if not _Puede_Anadir_A_Plato(payload, idx):
			continue
		var copia: Dictionary = _platos[idx].duplicate()
		for clave in mutacion.keys():
			copia[clave] = mutacion[clave]
		var rec: String = _Receta_De_Plato(copia)
		if rec != "" and _Algun_Cliente_Necesita(rec):
			return idx
	return -1


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
	if str(payload.get("tipo", "")) != "ingrediente":
		return false
	var ing: String = str(payload.get("id", ""))
	if not _Ingrediente_Aceptado_Estacion_A(ing):
		return false
	if indice >= 0 and indice < _plancha.size() and str(_plancha[indice]["estado"]) == "vacio":
		return _Iniciar_Coccion_A(indice, ing)
	for i in range(_plancha.size()):
		if str(_plancha[i]["estado"]) == "vacio":
			return _Iniciar_Coccion_A(i, ing)
	if not _slots_plancha_ui.is_empty():
		_Mostrar_Feedback_En_Control(_slots_plancha_ui[0]["nodo"], "Estación llena", Estilos_UI.AVISO)
	return false


func _Iniciar_Coccion_A(indice: int, ing: String) -> bool:
	if indice < 0 or indice >= _plancha.size():
		return false
	var nodo: ArteCocina.Punto_Coccion = _slots_plancha_ui[indice]["nodo"]
	_plancha[indice]["estado"] = "cocinando"
	_plancha[indice]["progreso"] = 0.0
	_plancha[indice]["quemado"] = 0.0
	_plancha[indice]["avisado"] = false
	_plancha[indice]["item"] = ing
	_plancha[indice]["punto"] = ""
	if _restaurante_actual == Sistema_Cocina.RESTAURANTE_BURGER:
		nodo.tipo = "carne"
	elif _restaurante_actual == Sistema_Cocina.RESTAURANTE_BISTRO:
		nodo.tipo = "filete"
	else:
		nodo.tipo = ing if ing != "generico" else "generico"
	_Actualizar_Slot_Coccion_UI(_plancha[indice], _slots_plancha_ui[indice], ing.capitalize())
	_efectos.vapor(_slots_plancha_ui[indice]["rect"].get_center() + Vector2(0.0, -8.0))
	var texto: String = "¡A la plancha!" if _restaurante_actual == Sistema_Cocina.RESTAURANTE_BURGER \
		else ("¡A la parrilla!" if _restaurante_actual == Sistema_Cocina.RESTAURANTE_BISTRO else "¡Al horno!")
	_Mostrar_Feedback_En_Control(_slots_plancha_ui[indice]["nodo"], texto, Color("#fdba74"), -8.0)
	if _sfx != null:
		_sfx.reproducir("sizzle", -16.0, randf_range(0.95, 1.06))
	return true


func _Soltar_En_Freidora(payload: Dictionary, indice: int = -1) -> bool:
	if str(payload.get("tipo", "")) != "ingrediente":
		return false
	var ing: String = str(payload.get("id", ""))
	if _restaurante_actual == Sistema_Cocina.RESTAURANTE_MERCADO:
		if ing != "huevo":
			return false
	elif _restaurante_actual == Sistema_Cocina.RESTAURANTE_ALTA:
		return false
	elif ing != "patatas":
		return false
	if indice >= 0 and indice < _freidora.size() and str(_freidora[indice]["estado"]) == "vacio":
		return _Iniciar_Coccion_B(indice, ing)
	for i in range(_freidora.size()):
		if str(_freidora[i]["estado"]) == "vacio":
			return _Iniciar_Coccion_B(i, ing)
	if not _slots_freidora_ui.is_empty():
		_Mostrar_Feedback_En_Control(_slots_freidora_ui[0]["nodo"], "Estación llena", Estilos_UI.AVISO)
	return false


func _Iniciar_Coccion_B(indice: int, ing: String) -> bool:
	if indice < 0 or indice >= _freidora.size():
		return false
	var nodo: ArteCocina.Punto_Coccion = _slots_freidora_ui[indice]["nodo"]
	_freidora[indice]["estado"] = "cocinando"
	_freidora[indice]["progreso"] = 0.0
	_freidora[indice]["quemado"] = 0.0
	_freidora[indice]["avisado"] = false
	_freidora[indice]["item"] = ing
	nodo.tipo = "huevo" if ing == "huevo" else "patatas"
	_Actualizar_Slot_Coccion_UI(_freidora[indice], _slots_freidora_ui[indice], ing.capitalize())
	var texto: String = "¡A la plancha!" if ing == "huevo" else "¡A freír!"
	_Mostrar_Feedback_En_Control(_slots_freidora_ui[indice]["nodo"], texto, Color("#fdba74"), -8.0)
	if _sfx != null:
		_sfx.reproducir("sizzle", -17.0, randf_range(0.95, 1.06))
	return true


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
		elif ing == "salsa":
			p["salsa"] = "salsa"
			mensaje = "Salsa añadida"
		elif ing in ["pure", "esparragos"]:
			p["guarnicion"] = ing
			mensaje = "%s añadido" % ("Puré" if ing == "pure" else "Espárragos")
		elif ing == "flor":
			p["flor"] = true
			mensaje = "Flor colocada"
		else:
			return false
	elif tipo == "carne_lista":
		var idx_plancha: int = int(payload.get("indice", -1))
		if idx_plancha < 0 or idx_plancha >= _plancha.size():
			return false
		p["carnes"] = int(p["carnes"]) + 1
		_Limpiar_Slot_Coccion(_plancha, _slots_plancha_ui, idx_plancha, "Carne")
		mensaje = "Carne añadida"
	elif tipo == "proteina":
		p["proteina"] = str(payload.get("proteina", ""))
		p["punto"] = str(payload.get("punto", ""))
		var idx_a: int = int(payload.get("indice", -1))
		if idx_a >= 0 and idx_a < _plancha.size():
			_Limpiar_Slot_Coccion(_plancha, _slots_plancha_ui, idx_a, p["proteina"])
		mensaje = "%s al plato" % str(p["proteina"]).capitalize()
	elif tipo == "patatas_listas":
		p["guarnicion"] = "patatas"
		var idx_f: int = int(payload.get("indice", -1))
		if idx_f >= 0 and idx_f < _freidora.size():
			_Limpiar_Slot_Coccion(_freidora, _slots_freidora_ui, idx_f, "Patatas")
		mensaje = "Patatas añadidas"
	elif tipo == "huevo_listo":
		p["extra"] = "huevo"
		var idx_h: int = int(payload.get("indice", -1))
		if idx_h >= 0 and idx_h < _freidora.size():
			_Limpiar_Slot_Coccion(_freidora, _slots_freidora_ui, idx_h, "Huevo")
		mensaje = "Huevo añadido"
	elif tipo == "guiso":
		p["guiso"] = str(payload.get("guiso", ""))
		_olla["raciones"] = maxi(0, int(_olla.get("raciones", 0)) - 1)
		if int(_olla["raciones"]) <= 0:
			_olla = {"ingredientes": [], "estado": "vacio", "progreso": 0.0,
				"raciones": 0, "receta": ""}
		_Actualizar_Olla_UI()
		mensaje = "Ración servida"
	elif tipo == "salsa":
		p["salsa"] = "reduccion"
		mensaje = "Salsa añadida"
	else:
		return false

	_plato_seleccionado = indice
	_slots_platos_ui[indice]["pop"] = 1.0
	if _sfx != null:
		_sfx.reproducir("pop", -12.0, randf_range(0.94, 1.08))
	_Actualizar_Plato_UI(indice)
	_Actualizar_Contadores_Estaciones()
	var receta: String = _Receta_De_Plato(p)
	if receta != "":
		_efectos.estrellas(_slots_platos_ui[indice]["rect"].get_center(), 4)
		if _sfx != null:
			_sfx.reproducir("ding", -15.0, 1.07)
		if _Algun_Cliente_Necesita(receta):
			mensaje = "%s · ¡llévalo al cliente!" % str(Sistema_Cocina.Obtener_Receta(
				_restaurante_actual, receta).get("nombre_corto", "Listo"))
	if mensaje != "":
		_Mostrar_Feedback_En_Control(_slots_platos_ui[indice]["nodo"], mensaje, Color("#86efac"), -10.0)
	return true


func _Soltar_En_Cliente(payload: Dictionary, indice: int) -> bool:
	if indice < 0 or indice >= _clientes.size():
		return false
	if not _Cliente_Puede_Recibir(indice):
		return false
	var cl: Dictionary = _clientes[indice]
	if not bool(cl["activo"]):
		return false

	var item_id: String = ""
	var limpiar_plato: bool = false
	var limpiar_freidora: int = -1
	var limpiar_bebida: int = -1
	var flor_extra: bool = false
	match str(payload.get("tipo", "")):
		"plato":
			item_id = str(payload.get("receta", ""))
			limpiar_plato = true
			var idx_p: int = int(payload.get("indice", -1))
			if idx_p >= 0 and idx_p < _platos.size():
				flor_extra = bool(_platos[idx_p].get("flor", false))
		"patatas_listas":
			item_id = "patatas"
			limpiar_freidora = int(payload.get("indice", -1))
		"bebida":
			item_id = str(payload.get("item", "refresco"))
			limpiar_bebida = int(payload.get("indice", -1))
		"ingrediente":
			var ing_postre: String = str(payload.get("id", ""))
			if Sistema_Cocina.Es_Receta_Postre(_restaurante_actual, ing_postre):
				item_id = ing_postre
			else:
				return false
		_:
			return false

	if item_id == "":
		_Mostrar_Feedback_En_Control(_slots_clientes_ui[indice]["retrato"], "Ese plato está incompleto", Estilos_UI.AVISO)
		return false
	if not _Cliente_Necesita_Item(cl, item_id):
		_Mostrar_Feedback_En_Control(_slots_clientes_ui[indice]["retrato"], "No lo ha pedido", Estilos_UI.AVISO)
		return false

	if flor_extra:
		cl["flor"] = true
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
		_Animar_Entrega_Desde_Bebida(limpiar_bebida, indice, item_id)

	if limpiar_plato:
		var idx_plato: int = int(payload.get("indice", -1))
		if idx_plato >= 0 and idx_plato < _platos.size():
			_Limpiar_Plato(idx_plato)
	if limpiar_freidora >= 0 and limpiar_freidora < _freidora.size():
		_Limpiar_Slot_Coccion(_freidora, _slots_freidora_ui, limpiar_freidora, "Patatas")
	if limpiar_bebida >= 0 and limpiar_bebida < _bebidas.size():
		_bebidas[limpiar_bebida]["estado"] = "llenando"
		_bebidas[limpiar_bebida]["progreso"] = 0.0
		_Actualizar_Bebida_UI(limpiar_bebida)
	return true


func _Animar_Entrega_Desde_Bebida(indice_bebida: int, indice_cliente: int, item_id: String) -> void:
	if _capa_feedback == null or indice_bebida < 0 or indice_bebida >= _slots_bebidas_ui.size():
		return
	var rect: Rect2 = _slots_bebidas_ui[indice_bebida]["rect"]
	var nodo := ArteCocina.Bebida.new()
	nodo.tipo = item_id
	nodo.size = Vector2(46.0, 76.0)
	nodo.position = _vista_cocina.global_position + rect.get_center() - nodo.size * 0.5
	nodo.pivot_offset = nodo.size * 0.5
	nodo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_capa_feedback.add_child(nodo)
	_Animar_Vuelo_Al_Cliente(nodo, indice_cliente)


func _Animar_Entrega_Desde_Plato(indice_plato: int, indice_cliente: int) -> void:
	if indice_plato < 0 or indice_plato >= _platos.size() or _capa_feedback == null:
		return
	var p: Dictionary = _platos[indice_plato]
	var ui: Dictionary = _slots_platos_ui[indice_plato]
	var plato := ArteCocina.Plato.new()
	plato.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plato.restaurante = _restaurante_actual
	plato.pan = bool(p["pan"])
	plato.carnes = int(p["carnes"])
	plato.queso = bool(p["queso"])
	plato.lechuga = bool(p["lechuga"])
	plato.tomate = bool(p["tomate"])
	plato.proteina = str(p.get("proteina", ""))
	plato.punto = str(p.get("punto", ""))
	plato.guiso = str(p.get("guiso", ""))
	plato.guarnicion = str(p.get("guarnicion", ""))
	plato.salsa = str(p.get("salsa", ""))
	plato.extra = str(p.get("extra", ""))
	plato.flor = bool(p.get("flor", false))
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
		"carne_lista", "carne_quemada", "carne_cruda":
			var idx_c: int = int(payload.get("indice", -1))
			if idx_c >= 0 and idx_c < _plancha.size():
				_desperdicio_valor += 6
				_Limpiar_Slot_Coccion(_plancha, _slots_plancha_ui, idx_c, "Carne")
		"proteina":
			var idx_p: int = int(payload.get("indice", -1))
			if idx_p >= 0 and idx_p < _plancha.size():
				_desperdicio_valor += 6
				_Limpiar_Slot_Coccion(_plancha, _slots_plancha_ui, idx_p, "Proteína")
		"patatas_listas", "patatas_quemadas":
			var idx_f: int = int(payload.get("indice", -1))
			if idx_f >= 0 and idx_f < _freidora.size():
				_desperdicio_valor += 8
				_Limpiar_Slot_Coccion(_freidora, _slots_freidora_ui, idx_f, "Patatas")
		"huevo_listo":
			var idx_h: int = int(payload.get("indice", -1))
			if idx_h >= 0 and idx_h < _freidora.size():
				_desperdicio_valor += 4
				_Limpiar_Slot_Coccion(_freidora, _slots_freidora_ui, idx_h, "Huevo")
		"guiso":
			# Tirar una ración de la olla: se descuenta del lote.
			_olla["raciones"] = maxi(0, int(_olla.get("raciones", 0)) - 1)
			if int(_olla["raciones"]) <= 0:
				_olla = {"ingredientes": [], "estado": "vacio", "progreso": 0.0,
					"raciones": 0, "receta": ""}
			_Actualizar_Olla_UI()
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
	var rec: Dictionary = Sistema_Cocina.Obtener_Receta(_restaurante_actual, receta)
	_desperdicio_valor += Sistema_Cocina.Calcular_Precio_Plato(
		int(rec.get("precio_base", 4)), _nv_ingredientes)


func _Mostrar_Rechazo(payload: Dictionary, destino: Dictionary) -> void:
	var datos: Dictionary = destino.get("datos", {})
	var tipo: String = str(datos.get("tipo", ""))
	var mensaje: String = "Ahí no va eso"
	match tipo:
		"plancha":
			mensaje = "Aquí no va eso"
			if _restaurante_actual == Sistema_Cocina.RESTAURANTE_BISTRO:
				mensaje = "Solo filetes en la parrilla"
			elif _restaurante_actual == Sistema_Cocina.RESTAURANTE_ALTA:
				mensaje = "Solo proteínas en el horno"
			elif _restaurante_actual == Sistema_Cocina.RESTAURANTE_MERCADO:
				mensaje = "Añade los ingredientes a la olla"
			elif str(payload.get("tipo", "")) == "ingrediente" and str(payload.get("id", "")) == "carne":
				mensaje = "La plancha está llena"
		"freidora":
			mensaje = "Aquí no va eso"
			if _restaurante_actual == Sistema_Cocina.RESTAURANTE_MERCADO:
				mensaje = "Solo huevos en la plancha"
			elif _restaurante_actual == Sistema_Cocina.RESTAURANTE_ALTA:
				mensaje = "La salsa se remueve, no se llena"
			elif str(payload.get("tipo", "")) == "ingrediente" and str(payload.get("id", "")) == "patatas":
				mensaje = "La freidora está llena"
		"plato":
			var idx: int = int(datos.get("indice", -1))
			var tipo_payload: String = str(payload.get("tipo", ""))
			if tipo_payload == "ingrediente":
				var ing: String = str(payload.get("id", ""))
				if _restaurante_actual == Sistema_Cocina.RESTAURANTE_BURGER:
					if ing != "pan" and idx >= 0 and idx < _platos.size() and not bool(_platos[idx]["pan"]):
						mensaje = "Pon pan primero"
					elif ing == "pan":
						mensaje = "Ese plato ya tiene pan"
					else:
						mensaje = "Ese plato ya lo tiene"
				else:
					mensaje = "Ese plato ya tiene ese ingrediente"
			elif tipo_payload == "proteina":
				var punt: String = str(payload.get("punto", ""))
				var est_p: String = str(payload.get("estado", ""))
				if _restaurante_actual == Sistema_Cocina.RESTAURANTE_BISTRO \
						and punt in ["", "crudo"]:
					mensaje = "Aún está crudo · espera a que tome punto"
				elif _restaurante_actual == Sistema_Cocina.RESTAURANTE_ALTA \
						and est_p != "listo":
					mensaje = "Espera la ventana dorada"
				else:
					mensaje = "Ese plato ya tiene proteína"
			elif tipo_payload == "carne_quemada":
				mensaje = "Está quemada: tírala a la basura"
			elif tipo_payload == "carne_cruda":
				mensaje = "Todavía se está haciendo"
			elif tipo_payload in ["patatas_listas", "huevo_listo", "guiso", "salsa"]:
				mensaje = "Ese plato ya tiene esa elaboración"
			elif tipo_payload == "carne_lista":
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

	# Cocción en la estación A y en la estación B (según el mundo)
	_Tick_Slots_Coccion(_plancha, _slots_plancha_ui, _tiempo_coccion_carne,
		"Carne", delta)
	_Tick_Slots_Coccion(_freidora, _slots_freidora_ui, _tiempo_coccion_b,
		"Patatas", delta)

	# Olla de guiso por lotes (mercado)
	if str(_olla.get("estado", "")) == "cocinando":
		_olla["progreso"] = minf(1.0, float(_olla.get("progreso", 0.0)) + delta / maxf(0.5, _tiempo_olla))
		if float(_olla["progreso"]) >= 1.0:
			_olla["estado"] = "listo"
			_olla["raciones"] = 4
			_Mostrar_Banner("¡GUISO LISTO! · 4 RACIONES", Color("#fbbf24"))
			_Mostrar_Chef("pulgar", "¡Olla a punto!", Color("#15803d"), 1.4)
			if _sfx != null:
				_sfx.reproducir("star", -12.0)
		_Actualizar_Olla_UI()

	# Sartén de salsa (alta cocina): se quema si no se remueve
	if _restaurante_actual == Sistema_Cocina.RESTAURANTE_ALTA:
		if str(_sarten.get("estado", "lista")) == "lista":
			_sarten["quemado"] = minf(1.0, float(_sarten.get("quemado", 0.0)) \
				+ delta * 0.042 * 6.0 / maxf(1.0, _tiempo_quemado))
			if float(_sarten["quemado"]) >= 1.0:
				_sarten["estado"] = "arruinada"
				_Mostrar_Feedback_En_Control(_sarten_ctrl, "¡Salsa quemada!", Estilos_UI.PELIGRO)
				_Mostrar_Chef("enfadada", "La salsa se ha quemado…", Estilos_UI.PELIGRO, 1.4)
		if float(_sarten.get("removido", 0.0)) > 0.0:
			_sarten["removido"] = maxf(0.0, float(_sarten["removido"]) - delta * 1.8)
		_Actualizar_Sarten_UI()

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

	# Estaciones temáticas: animación de olla, salsa, horno y bodega
	if _olla_ctrl != null:
		_olla_ctrl.tiempo = _anim_tiempo
		_olla_ctrl.queue_redraw()
	if _sarten_ctrl != null:
		_sarten_ctrl.tiempo = _anim_tiempo
		_sarten_ctrl.queue_redraw()
	if _horno_ctrl != null:
		_horno_ctrl.tiempo = _anim_tiempo
		_horno_ctrl.queue_redraw()
	if _botellas_ctrl != null:
		_botellas_ctrl.tiempo = _anim_tiempo
		_botellas_ctrl.queue_redraw()

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
		if est == "vacio" or est == "quemado" or est == "pasado":
			continue
		var item: String = str(s.get("item", ""))
		var es_filete: bool = _restaurante_actual == Sistema_Cocina.RESTAURANTE_BISTRO \
			and item == "carne"
		var es_alta: bool = _restaurante_actual == Sistema_Cocina.RESTAURANTE_ALTA \
			and item in ["solomillo", "lubina", "pato"]
		var nodo: ArteCocina.Punto_Coccion = ui_lista[i]["nodo"]

		if es_filete:
			# Bistró: la carne pasa por crudo → poco hecho → al punto → hecho.
			# Se puede retirar en cualquier punto servible; después empieza a quemarse.
			s["progreso"] = minf(1.0, float(s["progreso"]) + delta / maxf(0.2, tiempo_coccion))
			if float(s["progreso"]) >= 1.0:
				s["quemado"] = minf(1.0, float(s["quemado"]) + delta / maxf(0.5, _tiempo_quemado))
			var punto_previo: String = str(s.get("punto", ""))
			var punto_nuevo: String = Sistema_Cocina.Calcular_Punto_Filete(
				float(s["progreso"]), float(s["quemado"]))
			s["punto"] = punto_nuevo
			s["estado"] = "cocinando" if float(s["progreso"]) < 1.0 else "listo"
			if punto_nuevo == "quemado":
				s["estado"] = "quemado"
				if punto_previo != "quemado":
					_Mostrar_Feedback_En_Control(nodo, "¡QUEMADO!", Estilos_UI.PELIGRO)
					_efectos.humo(ui_lista[i]["rect"].get_center())
			elif punto_nuevo != punto_previo and punto_nuevo in ["al_punto", "hecho"]:
				nodo.flip = 1.0
				_efectos.estrellas(ui_lista[i]["rect"].get_center() + Vector2(0.0, -6.0), 2)
				if _sfx != null:
					_sfx.reproducir("ding", -16.0, 1.06)
			if s["estado"] == "listo" and est == "cocinando":
				nodo.flip = 1.0
			_Actualizar_Slot_Coccion_UI(s, ui_lista[i], etiqueta)
			continue

		if es_alta:
			# Alta cocina: ventana dorada estrecha. Antes = crudo; después = pasado.
			var estado_previo: String = est
			s["progreso"] = minf(1.15, float(s["progreso"]) + delta / maxf(0.2, tiempo_coccion))
			var fase: String = Sistema_Cocina.Estado_Proteina_Alta(float(s["progreso"]))
			if fase == "listo":
				s["estado"] = "listo"
				if estado_previo != "listo":
					nodo.flip = 1.0
					_efectos.estrellas(ui_lista[i]["rect"].get_center() + Vector2(0.0, -6.0), 3)
					_Mostrar_Feedback_En_Control(nodo, "¡EN SU PUNTO!", Color("#86efac"), -8.0)
					if _sfx != null:
						_sfx.reproducir("ding", -11.0, 1.02)
			elif fase == "pasado":
				s["estado"] = "pasado"
				if estado_previo != "pasado":
					_Mostrar_Feedback_En_Control(nodo, "¡PASADO!", Estilos_UI.PELIGRO)
					_efectos.humo(ui_lista[i]["rect"].get_center())
					if _sfx != null:
						_sfx.reproducir("burn", -13.0)
			else:
				s["estado"] = "cocinando"
			_Actualizar_Slot_Coccion_UI(s, ui_lista[i], etiqueta)
			continue

		# Comportamiento clásico (hamburguesa, patatas, huevos)
		if est == "cocinando":
			s["progreso"] = minf(1.0, float(s["progreso"]) + delta / maxf(0.2, tiempo_coccion))
			if float(s["progreso"]) >= 1.0:
				s["estado"] = "listo"
				s["quemado"] = 0.0
				s["avisado"] = false
				nodo.flip = 1.0
				_efectos.estrellas(ui_lista[i]["rect"].get_center() + Vector2(0.0, -6.0), 3)
				_Mostrar_Feedback_En_Control(nodo, "¡LISTO!", Color("#86efac"), -8.0)
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
	var max_items: int = clampi(int(_cfg_nivel_actual.get("max_items", 2)), 1, 4)
	var cantidad: int = _rng.randi_range(1, max_items)
	var recetas_rest: Dictionary = Sistema_Cocina.Obtener_Recetas_Restaurante(_restaurante_actual)

	var platos_menu: Array[String] = []
	var extras_menu: Array[String] = []
	for item_raw in menu:
		var item_id: String = str(item_raw)
		var rec: Dictionary = recetas_rest.get(item_id, {})
		if str(rec.get("tipo", "")) == "plato":
			platos_menu.append(item_id)
		else:
			extras_menu.append(item_id)

	var pedido: Array[String] = []
	var entregados: Array[bool] = []
	var precio_total: int = 0

	if _restaurante_actual == Sistema_Cocina.RESTAURANTE_ALTA and not platos_menu.is_empty():
		# Alta cocina: el plato llega siempre con su maridaje. El jugador debe
		# servir la copa correcta (tinto o blanco) además del plato.
		var plato_alta: String = platos_menu[_rng.randi() % platos_menu.size()]
		var rec_alta: Dictionary = recetas_rest.get(plato_alta, {})
		pedido.append(plato_alta)
		entregados.append(false)
		precio_total += Sistema_Cocina.Calcular_Precio_Plato(
			int(rec_alta.get("precio_base", 10)), _nv_ingredientes)
		var maridaje: String = str(rec_alta.get("maridaje", ""))
		if maridaje != "":
			pedido.append(maridaje)
			entregados.append(false)
			precio_total += Sistema_Cocina.Calcular_Precio_Plato(
				int(recetas_rest.get(maridaje, {}).get("precio_base", 10)), _nv_ingredientes)
		if max_items >= 3 and _rng.randf() < 0.30:
			var otro_plato: String = platos_menu[_rng.randi() % platos_menu.size()]
			if otro_plato != plato_alta:
				pedido.append(otro_plato)
				entregados.append(false)
				precio_total += Sistema_Cocina.Calcular_Precio_Plato(
					int(recetas_rest.get(otro_plato, {}).get("precio_base", 10)), _nv_ingredientes)
	else:
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
			var rec_el: Dictionary = recetas_rest.get(elegido, {})
			precio_total += Sistema_Cocina.Calcular_Precio_Plato(
				int(rec_el.get("precio_base", 10)), _nv_ingredientes)

	var pac_base: float = float(_cfg_nivel_actual.get("paciencia_base", 25.0))
	var cl: Dictionary = _clientes[idx]
	cl["activo"] = true
	cl["items"] = pedido
	cl["entregados"] = entregados
	cl["flor"] = false
	cl["paciencia_max"] = pac_base + float(maxi(0, pedido.size() - 1)) * 4.0
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
			_plancha[i]["item"] = "carne"
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
			_freidora[i]["item"] = "patatas"
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
		_Mostrar_Feedback_En_Control(_slots_plancha_ui[indice]["nodo"],
			"Toca el filete para ponerlo en la parrilla" if _restaurante_actual == Sistema_Cocina.RESTAURANTE_BISTRO else "Toca la carne para ponerla en la plancha",
			Estilos_UI.TINTA_SUAVE, -8.0)
		return
	var item: String = str(s.get("item", "carne"))
	if est == "quemado" or est == "pasado":
		_desperdicio_valor += 6
		var nodo_q: ArteCocina.Punto_Coccion = _slots_plancha_ui[indice]["nodo"]
		_Limpiar_Slot_Coccion(_plancha, _slots_plancha_ui, indice, item)
		_Mostrar_Feedback_En_Control(nodo_q,
			"Descartado · −%d € ingredientes" % Sistema_Cocina.Calcular_Coste_Merma(6),
			Estilos_UI.TINTA_SUAVE)
		return

	if _restaurante_actual == Sistema_Cocina.RESTAURANTE_BISTRO:
		var punto: String = str(s.get("punto", "crudo"))
		if punto in ["crudo", ""]:
			_Mostrar_Feedback_En_Control(_slots_plancha_ui[indice]["nodo"],
				"Aún está crudo · espera", Estilos_UI.AVISO)
			return
		if punto == "quemado":
			_desperdicio_valor += 6
			_Limpiar_Slot_Coccion(_plancha, _slots_plancha_ui, indice, "Filete")
			_Mostrar_Feedback_En_Control(_slots_plancha_ui[indice]["nodo"], "Quemado", Estilos_UI.PELIGRO)
			return
		var payload_b := {"tipo": "proteina", "proteina": "filete", "punto": punto, "indice": indice}
		var elegido_b: int = _Primer_Plato_Que_Complete_Pedido(payload_b,
			{"proteina": "filete", "punto": punto})
		if elegido_b < 0:
			for idx in _Orden_Busqueda_Platos():
				if str(_platos[idx].get("proteina", "")) == "":
					elegido_b = idx
					break
		if elegido_b < 0:
			_Mostrar_Feedback_En_Control(_slots_plancha_ui[indice]["nodo"],
				"No hay plato libre en el pase", Estilos_UI.AVISO)
			return
		if _Soltar_En_Plato(payload_b, elegido_b):
			_Mostrar_Feedback_En_Control(_slots_plancha_ui[indice]["nodo"],
				"¡%s!" % Sistema_Cocina.Punto_Filete_Legible(punto), Color("#86efac"), -8.0)
		return

	if _restaurante_actual == Sistema_Cocina.RESTAURANTE_ALTA:
		if est != "listo":
			_Mostrar_Feedback_En_Control(_slots_plancha_ui[indice]["nodo"],
				"Espera la ventana dorada", Estilos_UI.AVISO)
			return
		var elegido_a: int = -1
		for idx in _Orden_Busqueda_Platos():
			if str(_platos[idx].get("proteina", "")) == "":
				elegido_a = idx
				break
		if elegido_a < 0:
			_Mostrar_Feedback_En_Control(_slots_plancha_ui[indice]["nodo"],
				"No hay plato libre en el pase", Estilos_UI.AVISO)
			return
		if _Soltar_En_Plato({"tipo": "proteina", "proteina": item, "punto": "", "indice": indice},
				elegido_a):
			_Mostrar_Feedback_En_Control(_slots_plancha_ui[indice]["nodo"],
				"¡Al pase!", Color("#86efac"), -8.0)
		return

	# Hamburguesa (mundo 1): la carne cocinada debe arrastrarse hasta el pan
	# para mantener el reto; tocarla solo avisa al jugador.
	if est == "cocinando":
		_Mostrar_Feedback_En_Control(_slots_plancha_ui[indice]["nodo"], "Cocinando...", Estilos_UI.AVISO)
		return
	if _sfx != null:
		_sfx.reproducir("click", -22.0, 1.35)
	_Mostrar_Feedback_En_Control(_slots_plancha_ui[indice]["nodo"],
		"Arrastra la carne al pan", Color("#fde68a"), -8.0)


func _on_freidora_pulsada(indice: int) -> void:
	if not _jugando or indice < 0 or indice >= _freidora.size():
		return
	var s: Dictionary = _freidora[indice]
	var est: String = str(s["estado"])
	if est == "vacio":
		_Mostrar_Feedback_En_Control(_slots_freidora_ui[indice]["nodo"],
			"Toca las patatas para freírlas", Estilos_UI.TINTA_SUAVE, -8.0)
		return
	var item: String = str(s.get("item", "patatas"))
	if est == "quemado":
		_desperdicio_valor += 8
		var nodo_q: ArteCocina.Punto_Coccion = _slots_freidora_ui[indice]["nodo"]
		_Limpiar_Slot_Coccion(_freidora, _slots_freidora_ui, indice, item)
		_Mostrar_Feedback_En_Control(nodo_q,
			"Descartado · −%d € ingredientes" % Sistema_Cocina.Calcular_Coste_Merma(8),
			Estilos_UI.TINTA_SUAVE)
		return
	if est == "cocinando":
		_Mostrar_Feedback_En_Control(_slots_freidora_ui[indice]["nodo"],
			"Friendo..." if item != "huevo" else "Cocinando...", Estilos_UI.AVISO)
		return

	if _restaurante_actual == Sistema_Cocina.RESTAURANTE_BISTRO:
		# Las patatas son guarnición del pase, no un plato suelto. Se prioriza
		# el plato que complete un pedido real antes que el primero libre.
		var payload_p := {"tipo": "patatas_listas", "indice": indice}
		var elegido_p: int = _Primer_Plato_Que_Complete_Pedido(payload_p,
			{"guarnicion": "patatas"})
		if elegido_p < 0:
			for idx in _Orden_Busqueda_Platos():
				if str(_platos[idx].get("guarnicion", "")) == "":
					elegido_p = idx
					break
		if elegido_p >= 0:
			if _Soltar_En_Plato(payload_p, elegido_p):
				_Mostrar_Feedback_En_Control(_slots_freidora_ui[indice]["nodo"],
					"¡Patatas al pase!", Color("#86efac"), -8.0)
			return
		_Mostrar_Feedback_En_Control(_slots_freidora_ui[indice]["nodo"],
			"No hay plato libre", Estilos_UI.AVISO)
		return

	if _restaurante_actual == Sistema_Cocina.RESTAURANTE_MERCADO:
		for idx in _Orden_Busqueda_Platos():
			if str(_platos[idx].get("guiso", "")) == "pisto" \
					and str(_platos[idx].get("extra", "")) == "":
				if _Soltar_En_Plato({"tipo": "huevo_listo", "indice": indice}, idx):
					_Mostrar_Feedback_En_Control(_slots_freidora_ui[indice]["nodo"],
						"¡Huevo al pisto!", Color("#86efac"), -8.0)
				return
		_Mostrar_Feedback_En_Control(_slots_freidora_ui[indice]["nodo"],
			"Prepara un pisto en el pase", Estilos_UI.AVISO)
		return

	if _sfx != null:
		_sfx.reproducir("click", -22.0, 1.35)
	_Mostrar_Feedback_En_Control(_slots_freidora_ui[indice]["nodo"],
		"Arrastra las patatas al cliente", Color("#fde68a"), -8.0)


func _on_bebida_pulsada(indice: int) -> void:
	if not _jugando or indice < 0 or indice >= _bebidas.size():
		return
	var b: Dictionary = _bebidas[indice]
	if str(b["estado"]) != "listo":
		_Mostrar_Feedback_En_Control(_slots_bebidas_ui[indice]["nodo"],
			"Se está llenando", Estilos_UI.AVISO)
		return
	var item: String = str(b.get("item", "refresco"))
	var nombre_beb: String = str(Sistema_Cocina.Obtener_Receta(_restaurante_actual, item).get(
		"nombre_corto", "bebida")).to_lower()
	if _sfx != null:
		_sfx.reproducir("click", -22.0, 1.35)
	_Mostrar_Feedback_En_Control(_slots_bebidas_ui[indice]["nodo"],
		"Arrastra %s al cliente" % ("el " + nombre_beb if item == "refresco" or item == "cafe" else "la bebida"),
		Color("#fde68a"), -8.0)


func _on_plato_pulsado(indice: int) -> void:
	if not _jugando or indice < 0 or indice >= _platos.size():
		return
	var p: Dictionary = _platos[indice]
	var receta_id: String = _Receta_De_Plato(p)
	if receta_id != "":
		if _Algun_Cliente_Necesita(receta_id):
			if _sfx != null:
				_sfx.reproducir("click", -22.0, 1.35)
			_Mostrar_Feedback_En_Control(_slots_platos_ui[indice]["nodo"],
				"Arrastra el plato al cliente", Color("#fde68a"), -10.0)
		else:
			var nombre: String = str(Sistema_Cocina.Obtener_Receta(
				_restaurante_actual, receta_id).get("nombre_corto", "Ese plato"))
			_Mostrar_Feedback_En_Control(_slots_platos_ui[indice]["nodo"],
				"Nadie ha pedido %s · arrástralo a la basura" % nombre,
				Estilos_UI.TINTA_SUAVE, -10.0)
	elif not _Plato_Esta_Vacio(p):
		_Mostrar_Feedback_En_Control(_slots_platos_ui[indice]["nodo"],
			"Plato incompleto · añade lo que pida el cliente",
			Estilos_UI.AVISO, -10.0)
	_plato_seleccionado = indice
	_Actualizar_Todos_Los_Platos_UI()


func _Cliente_Puede_Recibir(indice: int) -> bool:
	if indice < 0 or indice >= _clientes.size():
		return false
	if not bool(_clientes[indice]["activo"]):
		return false
	var fase: String = str(_slots_clientes_ui[indice].get("fase", ""))
	return fase == "esperando" or fase == ""


func _on_cliente_pulsado(indice_cliente: int) -> void:
	if not _jugando or indice_cliente < 0 or indice_cliente >= _clientes.size():
		return
	if not _Cliente_Puede_Recibir(indice_cliente):
		return
	_Mostrar_Feedback_En_Control(_slots_clientes_ui[indice_cliente]["retrato"],
		"Arrastra el pedido hasta el cliente", Color("#fde68a"), -12.0)


func _Orden_Busqueda_Platos() -> Array[int]:
	var orden: Array[int] = []
	if _plato_seleccionado >= 0 and _plato_seleccionado < _platos.size():
		orden.append(_plato_seleccionado)
	for i in range(_platos.size()):
		if not orden.has(i):
			orden.append(i)
	return orden


func _Plato_Esta_Vacio(p: Dictionary) -> bool:
	if _restaurante_actual == Sistema_Cocina.RESTAURANTE_BURGER:
		return not bool(p.get("pan", false)) and int(p.get("carnes", 0)) <= 0
	return str(p.get("proteina", "")) == "" and str(p.get("guiso", "")) == "" \
		and str(p.get("guarnicion", "")) == "" and str(p.get("salsa", "")) == "" \
		and str(p.get("extra", "")) == "" and not bool(p.get("flor", false))


func _Dibujar_Plato_Borrador(c: CanvasItem, centro: Vector2, caja: float, p: Dictionary) -> void:
	if _restaurante_actual == Sistema_Cocina.RESTAURANTE_BISTRO:
		ArteCocina.dibujar_plato_bistro(c, centro, caja, str(p.get("proteina", "")),
			str(p.get("punto", "")), str(p.get("guarnicion", "")), str(p.get("salsa", "")))
	elif _restaurante_actual == Sistema_Cocina.RESTAURANTE_MERCADO:
		ArteCocina.dibujar_plato_mercado(c, centro, caja, str(p.get("guiso", "")),
			str(p.get("extra", "")))
	elif _restaurante_actual == Sistema_Cocina.RESTAURANTE_ALTA:
		ArteCocina.dibujar_plato_alta(c, centro, caja, str(p.get("proteina", "")),
			str(p.get("salsa", "")), str(p.get("guarnicion", "")), bool(p.get("flor", false)))
	else:
		ArteCocina.dibujar_plato_hamburguesa(c, centro, caja,
			bool(p.get("pan", false)), int(p.get("carnes", 0)),
			bool(p.get("queso", false)), bool(p.get("lechuga", false)),
			bool(p.get("tomate", false)))


func _Receta_De_Plato(p: Dictionary) -> String:
	if _restaurante_actual == Sistema_Cocina.RESTAURANTE_BISTRO:
		return Sistema_Cocina.Identificar_Plato_Bistro(
			str(p.get("proteina", "")), str(p.get("punto", "")),
			str(p.get("guarnicion", "")), str(p.get("salsa", "")))
	if _restaurante_actual == Sistema_Cocina.RESTAURANTE_MERCADO:
		return Sistema_Cocina.Identificar_Plato_Mercado(
			str(p.get("guiso", "")), str(p.get("extra", "")))
	if _restaurante_actual == Sistema_Cocina.RESTAURANTE_ALTA:
		return Sistema_Cocina.Identificar_Plato_Alta(
			str(p.get("proteina", "")), str(p.get("salsa", "")),
			str(p.get("guarnicion", "")))
	return Sistema_Cocina.Identificar_Hamburguesa(
		bool(p.get("pan", false)), int(p.get("carnes", 0)),
		bool(p.get("queso", false)), bool(p.get("lechuga", false)),
		bool(p.get("tomate", false)))


func _Limpiar_Plato(indice: int) -> void:
	_platos[indice] = _Plato_Vacio()
	if _plato_seleccionado == indice:
		_plato_seleccionado = -1
	_Actualizar_Todos_Los_Platos_UI()


func _Cliente_Urgente_Para_Item(item_id: String) -> int:
	var mejor_idx: int = -1
	var menor_ratio: float = 999.0
	for i in range(_clientes.size()):
		if not _Cliente_Puede_Recibir(i):
			continue
		var cl: Dictionary = _clientes[i]
		if not _Cliente_Necesita_Item(cl, item_id):
			continue
		var ratio: float = float(cl["paciencia"]) / maxf(1.0, float(cl["paciencia_max"]))
		if ratio < menor_ratio:
			menor_ratio = ratio
			mejor_idx = i
	return mejor_idx


func _Entregar_Item_A_Cliente_Urgente(item_id: String) -> bool:
	var mejor_idx: int = _Cliente_Urgente_Para_Item(item_id)
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
	var flor_bonus: bool = bool(cl.get("flor", false))
	if flor_bonus:
		propina += 3
		cl["flor"] = false

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
	if flor_bonus:
		extras.append("+3 € flor")

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
	_lbl_estado_propinas.text = "PROPINAS · %d €" % _propinas_servicio

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
	var perf: Dictionary = _perfil_actual
	if perf.is_empty():
		perf = Sistema_Cocina.Obtener_Perfil_Restaurante(_restaurante_actual)
	var est_a: Dictionary = perf.get("estacion_a", {})
	var est_b: Dictionary = perf.get("estacion_b", {})
	var beb: Dictionary = perf.get("bebida", {})
	var tipo_a: String = str(est_a.get("tipo", "plancha"))
	var tipo_b: String = str(est_b.get("tipo", "freidora"))

	var listas_b: int = 0
	for b in _bebidas:
		if str(b["estado"]) == "listo":
			listas_b += 1
	_lbl_estado_bebidas.text = "%s · %d/%d listos" % [
		str(beb.get("nombre", "BEBIDAS")), listas_b, _bebidas.size()]

	if tipo_a == "olla":
		if str(_olla.get("estado", "vacio")) == "listo":
			_lbl_estado_plancha.text = "OLLA · %d raciones" % int(_olla.get("raciones", 0))
		elif str(_olla.get("estado", "vacio")) == "cocinando":
			_lbl_estado_plancha.text = "OLLA · cociendo…"
		else:
			_lbl_estado_plancha.text = "OLLA · añade 2 ingredientes"
	else:
		var libres_p: int = 0
		for s in _plancha:
			if str(s["estado"]) == "vacio":
				libres_p += 1
		_lbl_estado_plancha.text = "%s · %d/%d libres" % [
			str(est_a.get("nombre", "COCCIÓN")), libres_p, _plancha.size()]

	if tipo_b == "sarten":
		if str(_sarten.get("estado", "lista")) == "arruinada":
			_lbl_estado_freidora.text = "SALSAS · ¡quemada!"
		else:
			_lbl_estado_freidora.text = "SALSAS · remueve (%d%%)" % int(
				float(_sarten.get("quemado", 0.0)) * 100.0)
	else:
		var libres_f: int = 0
		for s in _freidora:
			if str(s["estado"]) == "vacio":
				libres_f += 1
		_lbl_estado_freidora.text = "%s · %d/%d libres" % [
			str(est_b.get("nombre", "FREIDORA")), libres_f, _freidora.size()]

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
	nodo.tipo = str(b.get("item", "refresco"))
	nodo.estado = str(b["estado"])
	nodo.progreso = float(b["progreso"])
	nodo.tiempo = _anim_tiempo
	nodo.queue_redraw()
	_Actualizar_Contadores_Estaciones()


func _Actualizar_Todos_Los_Platos_UI() -> void:
	for i in range(_platos.size()):
		_Actualizar_Plato_UI(i)
	_Actualizar_Contadores_Estaciones()


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
	nodo.restaurante = _restaurante_actual
	nodo.proteina = str(p.get("proteina", ""))
	nodo.punto = str(p.get("punto", ""))
	nodo.guiso = str(p.get("guiso", ""))
	nodo.guarnicion = str(p.get("guarnicion", ""))
	nodo.salsa = str(p.get("salsa", ""))
	nodo.extra = str(p.get("extra", ""))
	nodo.flor = bool(p.get("flor", false))
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
	nodo.punto = str(slot.get("punto", ""))
	nodo.ventana = _restaurante_actual == Sistema_Cocina.RESTAURANTE_ALTA \
		and str(slot.get("item", "")) in ["solomillo", "lubina", "pato"]
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
	var pose_real: String = pose
	# La pose «sirviendo» del pack lleva una hamburguesa en la mano: en los
	# locales de bistró, mercado y alta cocina usamos el pulgar arriba.
	if pose == "sirviendo" and _restaurante_actual != Sistema_Cocina.RESTAURANTE_BURGER:
		pose_real = "pulgar"
	_chef_textura.texture = ArteCocina.textura_chef(pose_real)
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
		_vbox_modal_resultados.remove_child(c)
		c.queue_free()

	var estrellas: int = int(resumen.get("estrellas", 0))
	var superado: bool = bool(resumen.get("superado", false))

	var tit_txt: String = "¡SERVICIO SUPERADO!" if superado else "SERVICIO INCOMPLETO"
	var tit := ArteModal.crear_titulo(tit_txt, 34)
	tit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vbox_modal_resultados.add_child(tit)

	var sub := ArteModal.texto_cartoon(
		"NIVEL %d · %s" % [_nivel_actual, Sistema_Cocina.Obtener_Nombre_Restaurante(_restaurante_actual)],
		14, ArteModal.CREMA, ArteModal.NAVY_OSCURO, 4)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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

	_vbox_modal_resultados.add_child(ArteModal.divisor())

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
	_vbox_modal_resultados.add_child(ArteModal.texto_modal(
		detalle_costes, 12, ArteModal.CREMA, 500))
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
	_vbox_modal_resultados.add_child(ArteModal.texto_modal(
		" · ".join(detalle_personal), 12, ArteModal.CREMA, 500))
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
		msg_logro += "\nMaestría: %d ★ acumuladas." % int(resumen.get("estrellas_totales", 0))
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

	var btn_mapa := ArteModal.crear_boton(
		"MAPA", ArteModal.TEX_BOTON_AZUL, "arrow-left", 52, 17)
	btn_mapa.name = "Boton_Mapa_Resultados"
	btn_mapa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_mapa.pressed.connect(_Mostrar_Mapa)
	btns.add_child(btn_mapa)

	var btn_rep := ArteModal.crear_boton(
		"REPETIR", ArteModal.TEX_BOTON_NARANJA, "rotate-ccw", 52, 17)
	btn_rep.name = "Boton_Repetir_Resultados"
	btn_rep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_rep.pressed.connect(func(): _Comenzar_Carga_Nivel(_nivel_actual))
	btns.add_child(btn_rep)

	var tiene_sig: bool = superado and _nivel_actual < 15
	var btn_sig := ArteModal.crear_boton(
		"SIGUIENTE NIVEL", ArteModal.TEX_BOTON_VERDE, "chevron-right", 52, 17)
	btn_sig.name = "Boton_Siguiente_Resultados"
	btn_sig.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_sig.disabled = not tiene_sig
	if not tiene_sig:
		btn_sig.modulate = Color(1, 1, 1, 0.62)
	btn_sig.pressed.connect(func(): _Comenzar_Carga_Nivel(_nivel_actual + 1))
	btns.add_child(btn_sig)

	_modal_resultados.modulate.a = 0.0
	_modal_resultados.visible = true
	_Animar_Modal_Resultados.call_deferred()


func _Animar_Modal_Resultados() -> void:
	if _modal_resultados == null or _card_resultados == null:
		return
	_Animar_Entrada_Modal(_modal_resultados, _card_resultados)


func _Agregar_Fila_Resultado(clave: String, valor: String) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var k := ArteModal.texto_modal(clave, 14, ArteModal.CREMA, 600)
	k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(k)
	var v := ArteModal.texto_modal(valor, 14, ArteModal.ORO_CLARO, 700)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(v)
	_vbox_modal_resultados.add_child(h)
