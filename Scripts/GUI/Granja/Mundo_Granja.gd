class_name Mundo_Granja
extends Control

# ============================================================================
# Lienzo interactivo isométrico 24×24 con cámara (pan + zoom) de «La Granja».
#
# Proyección isométrica 2:1 exacta: cada unidad de terreno (1×1) mide 48×24 px.
# Los elementos ocupan huellas reales (cultivo 2×2, gallina 2×2, vaca 3×3,
# quesería 3×3, panadería 4×3/3×4, molino 4×4) ordenados por profundidad.
# ============================================================================

signal objeto_tocado(objeto_id: int)
signal terreno_vacio_tocado(gx: int, gy: int)
signal ampliacion_tocada()
signal colocar_solicitado(gx: int, gy: int)
signal ghost_movido(gx: int, gy: int, valido: bool)
signal cancelar_solicitado()

const Datos := preload("res://Scripts/Logica/Escena_Principal/Granja/Datos_Granja.gd")
const ObjetoGranja := preload("res://Scripts/GUI/Granja/Objeto_Granja.gd")
const IconoProducto := preload("res://Scripts/GUI/Granja/Icono_Producto.gd")
const FUENTE_CARTEL := preload("res://Fuentes/UI/Bricolage-800.ttf")
const FUENTE_BOLD := preload("res://Fuentes/UI/DMSans-700.ttf")

const TILE_HW: float = 24.0
const TILE_HH: float = 12.0
const ZOOM_MIN: float = 0.72
const ZOOM_MAX: float = 1.85
const UMBRAL_ARRASTRE: float = 10.0

var _mundo: Node2D
var _capa_terreno: _CapaTerreno
var _capa_objetos: Node2D
var _capa_overlays: _CapaOverlays
var _capa_ghost: _CapaGhost
var _capa_ambiente: _CapaAmbiente

var _nodos_objetos: Dictionary = {}   # id -> Objeto_Granja
var _tex_arbol: Texture2D
var _tex_espantapajaros: Texture2D

# Estado de cámara (pan + zoom suave) y multi-toque.
var _cam_centro_mundo := Vector2.ZERO
var _cam_zoom: float = 1.24
var _cam_zoom_objetivo: float = 1.24
var _arrastrando: bool = false
var _arrastrando_ghost: bool = false
var _pos_inicio_toque := Vector2.ZERO
var _pos_ultimo_toque := Vector2.ZERO
var _hubo_arrastre: bool = false
var _toques_activos: Dictionary = {}  # index -> Vector2 (para pellizco de 2 dedos)
var _dist_pinch_previa: float = 0.0

# Estado interactivo sincronizado desde Granja.gd.
var _modo: String = "normal"  # "normal" | "colocar" | "mover" | "vender" | "sembrar"
var _ghost_activo: bool = false
var _ghost_cat: String = ""
var _ghost_tipo: String = ""
var _ghost_rotado: bool = false
var _ghost_volteado: bool = false
var _ghost_ignorar_id: int = -1
var _ghost_gx: int = 10
var _ghost_gy: int = 10
var _ghost_chequeo: Dictionary = {"ok": false}
var _hover_id: int = -1
var _seleccionado_id: int = -1
var _hover_ampliar: bool = false


# ------------------------------------------------------------------
# Subcapas de dibujado en coordenadas de mundo (Node2D)
# ------------------------------------------------------------------

class _CapaTerreno:
	extends Node2D
	var padre: Mundo_Granja
	var tiempo: float = 0.0

	func _process(delta: float) -> void:
		tiempo += delta
		queue_redraw()

	func _draw() -> void:
		if padre != null:
			padre._Dibujar_Terreno(self, tiempo)


class _CapaOverlays:
	extends Node2D
	var padre: Mundo_Granja

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if padre != null:
			padre._Dibujar_Overlays_Objetos(self)


class _CapaGhost:
	extends Node2D
	var padre: Mundo_Granja
	var tiempo: float = 0.0

	func _process(delta: float) -> void:
		tiempo += delta
		if padre != null and (padre._ghost_activo or padre._modo == "mover"):
			queue_redraw()

	func _draw() -> void:
		if padre != null:
			padre._Dibujar_Ghost(self, tiempo)


class _CapaAmbiente:
	extends Node2D
	var padre: Mundo_Granja
	var tiempo: float = 0.0
	var mariposas: Array[Dictionary] = []
	var motas: Array[Dictionary] = []

	func _ready() -> void:
		for i in range(6):
			mariposas.append({
				"centro": Vector2(-240.0 + float(i) * 95.0, 140.0 + float(i % 3) * 145.0),
				"radio_x": 45.0 + float(i % 3) * 24.0,
				"radio_y": 24.0 + float(i % 2) * 16.0,
				"vel": 0.48 + float(i % 4) * 0.14,
				"fase": float(i) * 1.4,
				"color": [Color("#fef08a"), Color("#fed7aa"), Color("#fbcfe8"), Color("#bae6fd")][i % 4],
			})
		for i in range(14):
			motas.append({
				"base": Vector2(-380.0 + float((i * 113) % 760), 60.0 + float((i * 89) % 480)),
				"fase": float(i) * 0.95,
				"vel": 0.55 + float(i % 3) * 0.20,
				"radio": 1.8 + float(i % 2) * 0.9,
			})

	func _process(delta: float) -> void:
		tiempo += delta
		queue_redraw()

	func _draw() -> void:
		if padre != null:
			padre._Dibujar_Ambiente(self, tiempo, mariposas, motas)


# ------------------------------------------------------------------
# Ciclo de vida
# ------------------------------------------------------------------

func _ready() -> void:
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	clip_contents = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_Aplicar_Transform_Camara)

	if ResourceLoader.exists("res://Imagenes/Granja/Arbol_Manzano.png"):
		_tex_arbol = load("res://Imagenes/Granja/Arbol_Manzano.png")
	if ResourceLoader.exists("res://Imagenes/Granja/Espantapajaros.png"):
		_tex_espantapajaros = load("res://Imagenes/Granja/Espantapajaros.png")

	_mundo = Node2D.new()
	_mundo.name = "Mundo_Iso"
	add_child(_mundo)

	_capa_terreno = _CapaTerreno.new()
	_capa_terreno.name = "Capa_Terreno"
	_capa_terreno.padre = self
	_capa_terreno.z_index = 0
	_mundo.add_child(_capa_terreno)

	_capa_objetos = Node2D.new()
	_capa_objetos.name = "Capa_Objetos"
	_capa_objetos.y_sort_enabled = false
	_capa_objetos.z_index = 10
	_mundo.add_child(_capa_objetos)

	_capa_overlays = _CapaOverlays.new()
	_capa_overlays.name = "Capa_Overlays"
	_capa_overlays.padre = self
	_capa_overlays.z_index = 130
	_mundo.add_child(_capa_overlays)

	_capa_ghost = _CapaGhost.new()
	_capa_ghost.name = "Capa_Ghost"
	_capa_ghost.padre = self
	_capa_ghost.z_index = 150
	_mundo.add_child(_capa_ghost)

	_capa_ambiente = _CapaAmbiente.new()
	_capa_ambiente.name = "Capa_Ambiente"
	_capa_ambiente.padre = self
	_capa_ambiente.z_index = 170
	_mundo.add_child(_capa_ambiente)

	centrar_camara(true)
	set_process(true)


func _process(delta: float) -> void:
	if absf(_cam_zoom - _cam_zoom_objetivo) > 0.001:
		_cam_zoom = lerpf(_cam_zoom, _cam_zoom_objetivo, minf(1.0, delta * 12.0))
	_Aplicar_Transform_Camara()


# ------------------------------------------------------------------
# Proyección isométrica 24×24
# ------------------------------------------------------------------

func grid_a_mundo(gx: float, gy: float) -> Vector2:
	return Vector2((gx - gy) * TILE_HW, (gx + gy) * TILE_HH)


func mundo_a_grid(pos_mundo: Vector2) -> Vector2:
	var gx: float = (pos_mundo.x / TILE_HW + pos_mundo.y / TILE_HH) * 0.5
	var gy: float = (pos_mundo.y / TILE_HH - pos_mundo.x / TILE_HW) * 0.5
	return Vector2(gx, gy)


func _Centro_Vista() -> Vector2:
	if size.x > 10.0 and size.y > 10.0:
		return size * 0.5
	var vp := get_viewport()
	if vp != null:
		var vr := vp.get_visible_rect().size
		if vr.x > 10.0 and vr.y > 10.0:
			return vr * 0.5
	return Vector2(640.0, 360.0)


func pantalla_a_mundo(pos_pantalla: Vector2) -> Vector2:
	return (pos_pantalla - _Centro_Vista()) / maxf(0.1, _cam_zoom) + _cam_centro_mundo


func mundo_a_pantalla(pos_mundo: Vector2) -> Vector2:
	return (pos_mundo - _cam_centro_mundo) * _cam_zoom + _Centro_Vista()


func posicion_pantalla_objeto(objeto_id: int) -> Vector2:
	if _nodos_objetos.has(objeto_id):
		var nodo: ObjetoGranja = _nodos_objetos[objeto_id]
		if is_instance_valid(nodo):
			return mundo_a_pantalla(nodo.centro_mundo() - Vector2(0.0, nodo.altura_visual() * 0.55))
	return size * 0.5


# ------------------------------------------------------------------
# Cámara: centrar, zoom y límites suaves
# ------------------------------------------------------------------

func centrar_camara(instantaneo: bool = false) -> void:
	var rect_t := Sistema_Granja.Rect_Terreno()
	var cx: float = float(rect_t.position.x) + float(rect_t.size.x) * 0.5
	var cy: float = float(rect_t.position.y) + float(rect_t.size.y) * 0.5
	_cam_centro_mundo = grid_a_mundo(cx, cy) + Vector2(0.0, -24.0)
	var nivel: int = Sistema_Granja.Nivel_Terreno()
	var zoom_ideal: float = [1.24, 1.12, 1.02, 0.92, 0.86][clampi(nivel, 0, 4)]
	_cam_zoom_objetivo = zoom_ideal
	if instantaneo:
		_cam_zoom = zoom_ideal
	_Aplicar_Transform_Camara()


func ajustar_zoom(factor: float, foco_pantalla: Vector2 = Vector2(-1.0, -1.0)) -> void:
	var nuevo_zoom: float = clampf(_cam_zoom_objetivo * factor, ZOOM_MIN, ZOOM_MAX)
	if foco_pantalla.x >= 0.0:
		var mundo_antes := pantalla_a_mundo(foco_pantalla)
		_cam_zoom_objetivo = nuevo_zoom
		_cam_zoom = nuevo_zoom
		var mundo_despues := pantalla_a_mundo(foco_pantalla)
		_cam_centro_mundo += (mundo_antes - mundo_despues)
		_Limitar_Camara()
	else:
		_cam_zoom_objetivo = nuevo_zoom
	_Aplicar_Transform_Camara()


func _Limitar_Camara() -> void:
	var centro_mapa := grid_a_mundo(float(Datos.GRID_ANCHO) * 0.5, float(Datos.GRID_ALTO) * 0.5)
	_cam_centro_mundo.x = clampf(_cam_centro_mundo.x, centro_mapa.x - 420.0, centro_mapa.x + 420.0)
	_cam_centro_mundo.y = clampf(_cam_centro_mundo.y, centro_mapa.y - 240.0, centro_mapa.y + 240.0)


func _Aplicar_Transform_Camara() -> void:
	if _mundo == null:
		return
	_mundo.scale = Vector2(_cam_zoom, _cam_zoom)
	_mundo.position = _Centro_Vista() - _cam_centro_mundo * _cam_zoom


# ------------------------------------------------------------------
# Sincronización con Sistema_Granja y estado de modos
# ------------------------------------------------------------------

func establecer_modo(modo: String, seleccionado_id: int = -1) -> void:
	_modo = modo
	_seleccionado_id = seleccionado_id
	if modo != "colocar" and modo != "mover":
		_ghost_activo = false
		_ghost_ignorar_id = -1
	sincronizar_objetos()
	if _capa_terreno != null:
		_capa_terreno.queue_redraw()
	if _capa_ghost != null:
		_capa_ghost.queue_redraw()


func iniciar_ghost(categoria: String, tipo: String, rotado: bool = false,
		volteado: bool = false, ignorar_id: int = -1, gx_inicial: int = -1, gy_inicial: int = -1) -> void:
	_ghost_activo = true
	_ghost_cat = categoria
	_ghost_tipo = tipo
	_ghost_rotado = rotado and Datos.es_rotable(categoria, tipo)
	_ghost_volteado = volteado
	_ghost_ignorar_id = ignorar_id
	var tam := Datos.tamano_objeto(categoria, tipo, _ghost_rotado)
	if gx_inicial >= 0 and gy_inicial >= 0:
		_ghost_gx = gx_inicial
		_ghost_gy = gy_inicial
	else:
		var hueco := Sistema_Granja.Buscar_Hueco_Libre(tam.x, tam.y, ignorar_id)
		if hueco.x >= 0:
			_ghost_gx = hueco.x
			_ghost_gy = hueco.y
		else:
			var r := Sistema_Granja.Rect_Terreno()
			_ghost_gx = r.position.x + maxi(0, (r.size.x - tam.x) / 2)
			_ghost_gy = r.position.y + maxi(0, (r.size.y - tam.y) / 2)
	_Validar_Ghost()
	sincronizar_objetos()
	if _capa_ghost != null:
		_capa_ghost.queue_redraw()


func rotar_o_voltear_ghost() -> void:
	if not _ghost_activo:
		return
	if Datos.es_rotable(_ghost_cat, _ghost_tipo):
		_ghost_rotado = not _ghost_rotado
	else:
		_ghost_volteado = not _ghost_volteado
	_Validar_Ghost()
	if _capa_ghost != null:
		_capa_ghost.queue_redraw()


func datos_ghost() -> Dictionary:
	return {
		"activo": _ghost_activo,
		"categoria": _ghost_cat,
		"tipo": _ghost_tipo,
		"rotado": _ghost_rotado,
		"volteado": _ghost_volteado,
		"ignorar_id": _ghost_ignorar_id,
		"gx": _ghost_gx,
		"gy": _ghost_gy,
		"valido": bool(_ghost_chequeo.get("ok", false)),
		"motivo": str(_ghost_chequeo.get("motivo", "")),
	}


func _Validar_Ghost() -> void:
	var tam := Datos.tamano_objeto(_ghost_cat, _ghost_tipo, _ghost_rotado)
	_ghost_chequeo = Sistema_Granja.Puede_Colocar(_ghost_gx, _ghost_gy, tam.x, tam.y, _ghost_ignorar_id)
	ghost_movido.emit(_ghost_gx, _ghost_gy, bool(_ghost_chequeo.get("ok", false)))


func sincronizar_objetos() -> void:
	if _capa_objetos == null:
		return
	var presentes: Dictionary = {}
	for obj in Sistema_Granja.Objetos():
		var id: int = int(obj.get("id", -1))
		if id < 0:
			continue
		presentes[id] = true
		var nodo: ObjetoGranja = _nodos_objetos.get(id, null)
		if nodo == null or not is_instance_valid(nodo):
			nodo = ObjetoGranja.new()
			nodo.name = "Obj_%d" % id
			_capa_objetos.add_child(nodo)
			_nodos_objetos[id] = nodo
		var info: Dictionary = Sistema_Granja.Estado_Objeto(id)
		var oculto: bool = (_ghost_activo and _ghost_ignorar_id == id)
		nodo.position = grid_a_mundo(float(info["x"]), float(info["y"]))
		# Orden isométrico estricto por esquina frontal inferior (rango 0..100).
		nodo.z_index = (int(info["x"]) + int(info["ancho"]) + int(info["y"]) + int(info["alto"])) * 2 + int(int(info["y"]) / 6)
		nodo.hover = (id == _hover_id)
		nodo.configurar_datos(
			info,
			_modo == "vender",
			_modo == "mover" and not _ghost_activo,
			id == _seleccionado_id,
			oculto,
			_modo == "sembrar"
		)

	# Eliminar nodos de objetos vendidos.
	for id_viejo in _nodos_objetos.keys():
		if not presentes.has(id_viejo):
			var n = _nodos_objetos[id_viejo]
			if n != null and is_instance_valid(n):
				n.queue_free()
			_nodos_objetos.erase(id_viejo)


func pulso_objeto(objeto_id: int, color_burst: Color = Color("#fbbf24")) -> void:
	if _nodos_objetos.has(objeto_id):
		var nodo: ObjetoGranja = _nodos_objetos[objeto_id]
		if is_instance_valid(nodo):
			nodo.pulso_accion(color_burst)


# ------------------------------------------------------------------
# Entrada de ratón y táctil (pan, zoom, hover, click y ghost)
# ------------------------------------------------------------------

func _Punto_En_Ghost(pos_mundo: Vector2) -> bool:
	if not _ghost_activo:
		return false
	var tam := Datos.tamano_objeto(_ghost_cat, _ghost_tipo, _ghost_rotado)
	var g := mundo_a_grid(pos_mundo)
	return (
		g.x >= float(_ghost_gx) - 0.35 and g.x <= float(_ghost_gx + tam.x) + 0.35
		and g.y >= float(_ghost_gy) - 0.35 and g.y <= float(_ghost_gy + tam.y) + 0.35
	)


func _Mover_Ghost_A_Pantalla(pos_pantalla: Vector2) -> void:
	var pos_mundo := pantalla_a_mundo(pos_pantalla)
	var tam := Datos.tamano_objeto(_ghost_cat, _ghost_tipo, _ghost_rotado)
	var g := mundo_a_grid(pos_mundo)
	var ngx: int = clampi(int(floor(g.x - float(tam.x) * 0.5 + 0.5)), 0, Datos.GRID_ANCHO - tam.x)
	var ngy: int = clampi(int(floor(g.y - float(tam.y) * 0.5 + 0.5)), 0, Datos.GRID_ALTO - tam.y)
	if ngx != _ghost_gx or ngy != _ghost_gy:
		_ghost_gx = ngx
		_ghost_gy = ngy
		_Validar_Ghost()
		if _capa_ghost != null:
			_capa_ghost.queue_redraw()


func _gui_input(event: InputEvent) -> void:
	# Soporte de pellizco con 2 dedos en pantallas táctiles.
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_toques_activos[st.index] = st.position
		else:
			_toques_activos.erase(st.index)
			_dist_pinch_previa = 0.0
		if _toques_activos.size() >= 2:
			_arrastrando = false
			_arrastrando_ghost = false
			var vals := _toques_activos.values()
			_dist_pinch_previa = (vals[0] as Vector2).distance_to(vals[1] as Vector2)
			accept_event()
		return
	if event is InputEventScreenDrag and _toques_activos.size() >= 2:
		var sd := event as InputEventScreenDrag
		_toques_activos[sd.index] = sd.position
		var vals := _toques_activos.values()
		var dist: float = (vals[0] as Vector2).distance_to(vals[1] as Vector2)
		if _dist_pinch_previa > 10.0 and dist > 10.0:
			var centro: Vector2 = ((vals[0] as Vector2) + (vals[1] as Vector2)) * 0.5
			ajustar_zoom(dist / _dist_pinch_previa, centro)
		_dist_pinch_previa = dist
		accept_event()
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			ajustar_zoom(1.12, mb.position)
			accept_event()
			return
		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			ajustar_zoom(1.0 / 1.12, mb.position)
			accept_event()
			return
		if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			cancelar_solicitado.emit()
			accept_event()
			return
		if mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_MIDDLE:
			if mb.pressed:
				_arrastrando = true
				_hubo_arrastre = false
				_pos_inicio_toque = mb.position
				_pos_ultimo_toque = mb.position
				_arrastrando_ghost = (mb.button_index == MOUSE_BUTTON_LEFT and _ghost_activo and _Punto_En_Ghost(pantalla_a_mundo(mb.position)))
				accept_event()
			else:
				var fue_tap: bool = _arrastrando and not _hubo_arrastre and mb.button_index == MOUSE_BUTTON_LEFT
				_arrastrando = false
				_arrastrando_ghost = false
				mouse_default_cursor_shape = Control.CURSOR_ARROW
				if fue_tap:
					_Procesar_Tap(mb.position)
				accept_event()
			return
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _arrastrando:
			var delta_p := mm.position - _pos_ultimo_toque
			_pos_ultimo_toque = mm.position
			if mm.position.distance_to(_pos_inicio_toque) > UMBRAL_ARRASTRE:
				_hubo_arrastre = true
			if _hubo_arrastre:
				if _arrastrando_ghost:
					mouse_default_cursor_shape = Control.CURSOR_MOVE
					_Mover_Ghost_A_Pantalla(mm.position)
				else:
					mouse_default_cursor_shape = Control.CURSOR_DRAG
					_cam_centro_mundo -= delta_p / maxf(0.1, _cam_zoom)
					_Limitar_Camara()
					_Aplicar_Transform_Camara()
			accept_event()
			return
		_Actualizar_Hover(mm.position)
	elif event is InputEventMagnifyGesture:
		var mg := event as InputEventMagnifyGesture
		ajustar_zoom(mg.factor, mg.position)
		accept_event()


func _Actualizar_Hover(pos_pantalla: Vector2) -> void:
	var pos_mundo := pantalla_a_mundo(pos_pantalla)
	if _ghost_activo:
		_Mover_Ghost_A_Pantalla(pos_pantalla)
		return

	var nuevo_hover: int = _Objeto_Bajo_Punto(pos_mundo)
	if nuevo_hover != _hover_id:
		if _nodos_objetos.has(_hover_id) and is_instance_valid(_nodos_objetos[_hover_id]):
			_nodos_objetos[_hover_id].hover = false
			_nodos_objetos[_hover_id].queue_redraw()
		_hover_id = nuevo_hover
		if _nodos_objetos.has(_hover_id) and is_instance_valid(_nodos_objetos[_hover_id]):
			_nodos_objetos[_hover_id].hover = true
			_nodos_objetos[_hover_id].queue_redraw()

	var pos_amp := _Posicion_Cartel_Ampliar()
	var sobre_amp: bool = pos_amp != Vector2.ZERO and pos_mundo.distance_to(pos_amp) < 36.0
	if sobre_amp != _hover_ampliar:
		_hover_ampliar = sobre_amp
		if _capa_terreno != null:
			_capa_terreno.queue_redraw()


func _Procesar_Tap(pos_pantalla: Vector2) -> void:
	var pos_mundo := pantalla_a_mundo(pos_pantalla)

	if _ghost_activo:
		var tam := Datos.tamano_objeto(_ghost_cat, _ghost_tipo, _ghost_rotado)
		var g := mundo_a_grid(pos_mundo)
		_ghost_gx = clampi(int(floor(g.x - float(tam.x) * 0.5 + 0.5)), 0, Datos.GRID_ANCHO - tam.x)
		_ghost_gy = clampi(int(floor(g.y - float(tam.y) * 0.5 + 0.5)), 0, Datos.GRID_ALTO - tam.y)
		_Validar_Ghost()
		if _capa_ghost != null:
			_capa_ghost.queue_redraw()
		colocar_solicitado.emit(_ghost_gx, _ghost_gy)
		return

	# Comprobar primero el cartel flotante de ampliación.
	var pos_amp := _Posicion_Cartel_Ampliar()
	if pos_amp != Vector2.ZERO and pos_mundo.distance_to(pos_amp) < 38.0:
		ampliacion_tocada.emit()
		return

	# Comprobar objetos colocados (de delante hacia atrás por z_index).
	var id_hit: int = _Objeto_Bajo_Punto(pos_mundo)
	if id_hit >= 0:
		objeto_tocado.emit(id_hit)
		return

	# Comprobar si tocó terreno bloqueado o terreno desbloqueado libre.
	var g_tap := mundo_a_grid(pos_mundo)
	var gx: int = int(floor(g_tap.x))
	var gy: int = int(floor(g_tap.y))
	if Datos.celda_en_mapa(gx, gy):
		if Sistema_Granja.Celda_Desbloqueada(gx, gy):
			terreno_vacio_tocado.emit(gx, gy)
		elif Sistema_Granja.Celda_En_Siguiente_Ampliacion(gx, gy):
			ampliacion_tocada.emit()


func _Objeto_Bajo_Punto(pos_mundo: Vector2) -> int:
	var mejor_id: int = -1
	var mejor_z: int = -999999
	for id in _nodos_objetos.keys():
		var nodo: ObjetoGranja = _nodos_objetos[id]
		if nodo == null or not is_instance_valid(nodo) or not nodo.visible:
			continue
		if nodo.contiene_punto_mundo(pos_mundo) and nodo.z_index >= mejor_z:
			mejor_z = nodo.z_index
			mejor_id = int(id)
	return mejor_id


func _Posicion_Cartel_Ampliar() -> Vector2:
	if Sistema_Granja.Nivel_Terreno() >= Datos.NIVEL_TERRENO_MAX:
		return Vector2.ZERO
	var r_act := Sistema_Granja.Rect_Terreno()
	var r_sig := Sistema_Granja.Rect_Siguiente_Ampliacion()
	# Colocar el medallón en el lado derecho del nuevo anillo de ampliación.
	if r_sig.end.x > r_act.end.x:
		return grid_a_mundo(float(r_act.end.x) + 0.9, float(r_act.position.y + r_act.end.y) * 0.5)
	return grid_a_mundo(float(r_act.position.x + r_act.end.x) * 0.5, float(r_act.end.y) + 0.9)


# ------------------------------------------------------------------
# Renderizado del mundo rural y terreno 24×24
# ------------------------------------------------------------------

func _Dibujar_Terreno(canvas: CanvasItem, tiempo: float) -> void:
	var n: float = float(Datos.GRID_ANCHO)

	# 1. Pradera infinita exterior (cubre toda la pantalla en cualquier zoom).
	canvas.draw_rect(Rect2(-1800, -1000, 3600, 2600), Color("#6db82d"))
	# Bandas suaves de colina soleada en el entorno.
	var colina_sup := PackedVector2Array([
		grid_a_mundo(-10, -10), grid_a_mundo(34, -10),
		grid_a_mundo(34, 4), grid_a_mundo(-10, 4),
	])
	canvas.draw_colored_polygon(colina_sup, Color("#78c434", 0.55))

	# 2. Caminos rurales de tierra alrededor del perímetro de la granja.
	_Dibujar_Camino(canvas, grid_a_mundo(-12, -2.5), grid_a_mundo(27, -2.5), 34.0)
	_Dibujar_Camino(canvas, grid_a_mundo(-2.6, -3.5), grid_a_mundo(-2.6, 28), 36.0)
	_Dibujar_Camino(canvas, grid_a_mundo(26.6, -3.0), grid_a_mundo(26.6, 28), 34.0)
	_Dibujar_Camino(canvas, grid_a_mundo(-4.0, 26.5), grid_a_mundo(28.0, 26.5), 34.0)

	# 3. Estanque azul con nenúfares y ondas animadas fuera de la esquina inferior izquierda.
	_Dibujar_Estanque(canvas, grid_a_mundo(-4.2, 16.5), tiempo)

	# 4. Gran parcela total 24×24 (prado exterior aún silvestre).
	var marco_24 := PackedVector2Array([
		grid_a_mundo(0, 0), grid_a_mundo(n, 0),
		grid_a_mundo(n, n), grid_a_mundo(0, n),
	])
	canvas.draw_colored_polygon(marco_24, Color("#7bc832"))

	# Damero sutil en la zona total 24×24 (bloques de 2×2).
	for by in range(0, Datos.GRID_ALTO, 2):
		for bx in range(0, Datos.GRID_ANCHO, 2):
			if ((bx / 2) + (by / 2)) % 2 != 0:
				continue
			var poly := PackedVector2Array([
				grid_a_mundo(bx, by),
				grid_a_mundo(bx + 2, by),
				grid_a_mundo(bx + 2, by + 2),
				grid_a_mundo(bx, by + 2),
			])
			canvas.draw_colored_polygon(poly, Color(1.0, 1.0, 0.78, 0.055))

	# 5. Zona desbloqueada actual: césped más luminoso, segado y cercado con madera baja!
	var r_desb := Sistema_Granja.Rect_Terreno()
	var poly_desb := PackedVector2Array([
		grid_a_mundo(r_desb.position.x, r_desb.position.y),
		grid_a_mundo(r_desb.end.x, r_desb.position.y),
		grid_a_mundo(r_desb.end.x, r_desb.end.y),
		grid_a_mundo(r_desb.position.x, r_desb.end.y),
	])
	canvas.draw_colored_polygon(poly_desb, Color("#8ee03b"))

	# Franjas de césped segado (2×2) dentro de la zona desbloqueada.
	for by in range(r_desb.position.y, r_desb.end.y, 2):
		for bx in range(r_desb.position.x, r_desb.end.x, 2):
			if ((bx / 2) + (by / 2)) % 2 != 0:
				continue
			var w2: int = mini(2, r_desb.end.x - bx)
			var h2: int = mini(2, r_desb.end.y - by)
			var poly := PackedVector2Array([
				grid_a_mundo(bx, by),
				grid_a_mundo(bx + w2, by),
				grid_a_mundo(bx + w2, by + h2),
				grid_a_mundo(bx, by + h2),
			])
			canvas.draw_colored_polygon(poly, Color(1.0, 1.0, 0.80, 0.085))

	# Rejilla fina de construcción (visible con claridad al colocar/mover, sutil en normal).
	var alpha_grid: float = 0.28 if (_ghost_activo or _modo == "mover") else 0.075
	var col_grid := Color(1.0, 1.0, 0.90, alpha_grid)
	for x in range(r_desb.position.x, r_desb.end.x + 1):
		var grueso: float = 1.3 if (x % 2 == 0 and (_ghost_activo or _modo == "mover")) else 0.9
		canvas.draw_line(
			grid_a_mundo(x, r_desb.position.y),
			grid_a_mundo(x, r_desb.end.y), col_grid, grueso, true)
	for y in range(r_desb.position.y, r_desb.end.y + 1):
		var grueso: float = 1.3 if (y % 2 == 0 and (_ghost_activo or _modo == "mover")) else 0.9
		canvas.draw_line(
			grid_a_mundo(r_desb.position.x, y),
			grid_a_mundo(r_desb.end.x, y), col_grid, grueso, true)

	# 6. Vista previa sutil de la siguiente ampliación + florecillas en terreno aún bloqueado.
	var r_sig := Sistema_Granja.Rect_Siguiente_Ampliacion()
	if r_sig.size.x > 0:
		var poly_sig := PackedVector2Array([
			grid_a_mundo(r_sig.position.x, r_sig.position.y),
			grid_a_mundo(r_sig.end.x, r_sig.position.y),
			grid_a_mundo(r_sig.end.x, r_sig.end.y),
			grid_a_mundo(r_sig.position.x, r_sig.end.y),
			grid_a_mundo(r_sig.position.x, r_sig.position.y),
		])
		canvas.draw_polyline(poly_sig, Color(1.0, 0.94, 0.56, 0.42), 2.0, true)

	_Dibujar_Flores_Silvestres(canvas, r_desb, tiempo)

	# 7. Borde de madera bajo rodeando la zona desbloqueada actual.
	_Dibujar_Borde_Terreno(canvas, r_desb)

	# 8. Setos, árboles manzanos, cartel de bienvenida y espantapájaros fuera del 24×24.
	_Dibujar_Entorno_Decorativo(canvas, tiempo)

	# 9. Medallón flotante «Ampliar» en el borde de la siguiente expansión.
	var pos_amp := _Posicion_Cartel_Ampliar()
	if pos_amp != Vector2.ZERO:
		_Dibujar_Medallon_Ampliar(canvas, pos_amp, tiempo)


func _Dibujar_Camino(canvas: CanvasItem, a: Vector2, b: Vector2, ancho_px: float) -> void:
	canvas.draw_line(a, b, Color("#b9874a"), ancho_px + 6.0, true)
	canvas.draw_line(a, b, Color("#d4a462"), ancho_px, true)
	canvas.draw_line(a, b, Color("#e2b97a", 0.55), ancho_px * 0.45, true)


func _Dibujar_Estanque(canvas: CanvasItem, centro: Vector2, tiempo: float) -> void:
	_Elipse_C(canvas, centro + Vector2(0, 4), 108, 52, Color("#568f22"))
	_Elipse_C(canvas, centro, 98, 46, Color("#22a2d6"))
	_Elipse_C(canvas, centro + Vector2(-8, -4), 76, 34, Color("#38bdf8"))
	_Elipse_C(canvas, centro + Vector2(-18, -8), 36, 14, Color("#bae6fd", 0.50))
	# Ondas animadas suaves.
	for i in range(2):
		var c_o: float = fmod(tiempo * 0.35 + float(i) * 0.5, 1.0)
		var rx: float = 14.0 + c_o * 36.0
		var ry: float = rx * 0.46
		var alpha: float = (1.0 - c_o) * 0.48
		_Contorno_Elipse_C(canvas, centro + Vector2(18, 4), rx, ry, Color(1, 1, 1, alpha), 1.4)
	# Nenúfares.
	for lp in [Vector2(-32, 12), Vector2(28, -10), Vector2(-4, 18)]:
		_Elipse_C(canvas, centro + lp, 9.5, 5.0, Color("#22c55e"))
		canvas.draw_circle(centro + lp + Vector2(2, -1), 2.5, Color("#f472b6"))


func _Dibujar_Flores_Silvestres(canvas: CanvasItem, r_desb: Rect2i, tiempo: float) -> void:
	var colores := [Color("#fef08a"), Color("#ffffff"), Color("#fbcfe8"), Color("#fed7aa")]
	for i in range(42):
		var fx: int = (i * 7 + 3) % Datos.GRID_ANCHO
		var fy: int = (i * 11 + 5) % Datos.GRID_ALTO
		if r_desb.has_point(Vector2i(fx, fy)):
			continue
		var p := grid_a_mundo(float(fx) + 0.5, float(fy) + 0.5)
		var v: float = sin(tiempo * 2.0 + float(i)) * 1.0
		canvas.draw_circle(p + Vector2(v, 0), 2.5, colores[i % colores.size()])
		canvas.draw_circle(p + Vector2(v + 4.5, 2.0), 1.9, colores[(i + 1) % colores.size()])


func _Dibujar_Borde_Terreno(canvas: CanvasItem, r: Rect2i) -> void:
	var p0 := grid_a_mundo(r.position.x, r.position.y)
	var p1 := grid_a_mundo(r.end.x, r.position.y)
	var p2 := grid_a_mundo(r.end.x, r.end.y)
	var p3 := grid_a_mundo(r.position.x, r.end.y)

	# Borde luminoso del terreno cultivable.
	canvas.draw_polyline(PackedVector2Array([p0, p1, p2, p3, p0]), Color("#e5f8a2", 0.72), 2.2, true)

	# Estacas rústicas espaciadas cada 2 celdas marcando el perímetro desbloqueado.
	for x in range(r.position.x, r.end.x + 1, 2):
		_Poste_Perimetro(canvas, grid_a_mundo(x, r.position.y))
		_Poste_Perimetro(canvas, grid_a_mundo(x, r.end.y))
	for y in range(r.position.y + 2, r.end.y, 2):
		_Poste_Perimetro(canvas, grid_a_mundo(r.position.x, y))
		_Poste_Perimetro(canvas, grid_a_mundo(r.end.x, y))


func _Poste_Perimetro(canvas: CanvasItem, p: Vector2) -> void:
	_Elipse_C(canvas, p + Vector2(0, 1.5), 4.0, 2.0, Color(0.10, 0.24, 0.03, 0.26))
	canvas.draw_rect(Rect2(p.x - 2.0, p.y - 8.5, 4.0, 9.0), Color("#7a461e"))
	canvas.draw_rect(Rect2(p.x - 1.3, p.y - 8.5, 1.8, 8.0), Color("#c28344"))
	canvas.draw_rect(Rect2(p.x - 2.4, p.y - 9.8, 4.8, 2.0), Color("#deb072"))


func _Dibujar_Entorno_Decorativo(canvas: CanvasItem, tiempo: float) -> void:
	# Árboles manzanos distribuidos alrededor de la parcela 24×24.
	var arboles: Array[Array] = [
		[grid_a_mundo(-1.8, 3.2), 112.0, 0.0],
		[grid_a_mundo(4.2, -2.0), 104.0, 1.1],
		[grid_a_mundo(14.0, -2.2), 116.0, 2.3],
		[grid_a_mundo(23.5, -1.6), 108.0, 3.4],
		[grid_a_mundo(26.2, 6.0), 114.0, 4.2],
		[grid_a_mundo(26.0, 18.0), 106.0, 5.1],
		[grid_a_mundo(-2.4, 23.0), 118.0, 1.9],
		[grid_a_mundo(10.0, 26.8), 104.0, 2.8],
	]
	for item in arboles:
		var pos: Vector2 = item[0]
		var tam: float = float(item[1])
		var fase: float = float(item[2])
		_Elipse_C(canvas, pos + Vector2(4, 4), tam * 0.34, tam * 0.16, Color(0.10, 0.24, 0.03, 0.28))
		if _tex_arbol != null:
			var ang: float = sin(tiempo * 1.4 + fase) * 0.024
			canvas.draw_set_transform(pos, ang, Vector2.ONE)
			canvas.draw_texture_rect(_tex_arbol, Rect2(-tam * 0.5, -tam + 10.0, tam, tam), false)
			canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Cartel rústico «LA GRANJA» y espantapájaros en el borde superior derecho (bien despejados).
	var pos_cartel := grid_a_mundo(15.6, -1.2)
	canvas.draw_rect(Rect2(pos_cartel.x - 28, pos_cartel.y - 26, 5.5, 28), Color("#6b3c18"))
	canvas.draw_rect(Rect2(pos_cartel.x + 22, pos_cartel.y - 26, 5.5, 28), Color("#6b3c18"))
	canvas.draw_rect(Rect2(pos_cartel.x - 42, pos_cartel.y - 44, 84, 24), Color("#7a461e"))
	canvas.draw_rect(Rect2(pos_cartel.x - 40, pos_cartel.y - 42, 80, 20), Color("#b47135"))
	var tw: float = FUENTE_CARTEL.get_string_size("LA GRANJA", HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	canvas.draw_string(FUENTE_CARTEL, Vector2(pos_cartel.x - tw * 0.5, pos_cartel.y - 28),
		"LA GRANJA", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#fffbeb"))

	# Espantapájaros meciéndose suavemente junto al cartel.
	if _tex_espantapajaros != null:
		var pos_esp := grid_a_mundo(18.5, -0.9)
		_Elipse_C(canvas, pos_esp + Vector2(0, 3), 18, 8, Color(0.10, 0.24, 0.03, 0.28))
		var ang_e: float = sin(tiempo * 1.8) * 0.055
		canvas.draw_set_transform(pos_esp, ang_e, Vector2.ONE)
		canvas.draw_texture_rect(_tex_espantapajaros, Rect2(-36, -74, 72, 72), false)
		canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _Dibujar_Medallon_Ampliar(canvas: CanvasItem, pos: Vector2, tiempo: float) -> void:
	var bob: float = sin(tiempo * 3.0) * 3.0
	var p := pos + Vector2(0, -18.0 + bob)
	var esc: float = 1.08 if _hover_ampliar else 1.0
	canvas.draw_set_transform(p, 0.0, Vector2(esc, esc))
	canvas.draw_circle(Vector2(0, 3), 21.0, Color(0.10, 0.22, 0.04, 0.26))
	canvas.draw_circle(Vector2.ZERO, 20.0, Color("#d97706"))
	canvas.draw_circle(Vector2.ZERO, 17.0, Color("#fffbeb"))
	# Candado dorado
	canvas.draw_arc(Vector2(0, -4.5), 5.5, PI, TAU, 14, Color("#b45309"), 2.4, true)
	canvas.draw_rect(Rect2(-7.5, -4.0, 15.0, 11.5), Color("#f59e0b"))
	canvas.draw_rect(Rect2(-7.5, -4.0, 15.0, 2.8), Color("#fde68a"))
	canvas.draw_circle(Vector2(0, 1.5), 1.9, Color("#78350f"))
	# Pastilla «Ampliar» debajo
	var txt := "Ampliar"
	var tw: float = FUENTE_BOLD.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	var rw: float = tw + 16.0
	canvas.draw_rect(Rect2(-rw * 0.5, 22, rw, 17), Color("#d97706"))
	canvas.draw_rect(Rect2(-rw * 0.5 + 1.5, 23.5, rw - 3.0, 14), Color("#fffbeb"))
	canvas.draw_string(FUENTE_BOLD, Vector2(-tw * 0.5, 34), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#92400e"))
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _Dibujar_Overlays_Objetos(canvas: CanvasItem) -> void:
	var nodos: Array = []
	for id in _nodos_objetos.keys():
		var n = _nodos_objetos[id]
		if n != null and is_instance_valid(n) and n.visible:
			nodos.append(n)
	nodos.sort_custom(func(a, b) -> bool: return a.z_index < b.z_index)
	for n in nodos:
		n.dibujar_overlay_en(canvas)


# ------------------------------------------------------------------
# Vista previa fantasma de colocación / movimiento multi-celda
# ------------------------------------------------------------------

func _Dibujar_Ghost(canvas: CanvasItem, tiempo: float) -> void:
	if not _ghost_activo:
		return
	var tam := Datos.tamano_objeto(_ghost_cat, _ghost_tipo, _ghost_rotado)
	var valido: bool = bool(_ghost_chequeo.get("ok", false))
	var bloqueadas: Dictionary = {}
	for c_b in _ghost_chequeo.get("celdas_bloqueadas", []):
		bloqueadas[c_b] = true
	var ocupadas: Dictionary = {}
	for c_o in _ghost_chequeo.get("celdas_ocupadas", []):
		ocupadas[c_o] = true

	var pulso: float = 0.36 + 0.14 * sin(tiempo * 5.5)

	# Dibujar cada sub-celda 1×1 de la huella (p. ej. las 16 celdas del Molino 4×4!).
	for dy in range(tam.y):
		for dx in range(tam.x):
			var cx: int = _ghost_gx + dx
			var cy: int = _ghost_gy + dy
			var p := Vector2i(cx, cy)
			var col_celda: Color
			if bloqueadas.has(p) or ocupadas.has(p):
				col_celda = Color(0.95, 0.16, 0.16, 0.58)
			elif valido:
				col_celda = Color(0.14, 0.86, 0.36, pulso)
			else:
				col_celda = Color(0.98, 0.62, 0.12, 0.36)
			var poly := PackedVector2Array([
				grid_a_mundo(cx, cy),
				grid_a_mundo(cx + 1, cy),
				grid_a_mundo(cx + 1, cy + 1),
				grid_a_mundo(cx, cy + 1),
			])
			canvas.draw_colored_polygon(poly, col_celda)
			poly.append(poly[0])
			canvas.draw_polyline(poly, Color(1, 1, 1, 0.65), 1.1, true)

	# Contorno exterior brillante de toda la huella.
	var borde := PackedVector2Array([
		grid_a_mundo(_ghost_gx, _ghost_gy),
		grid_a_mundo(_ghost_gx + tam.x, _ghost_gy),
		grid_a_mundo(_ghost_gx + tam.x, _ghost_gy + tam.y),
		grid_a_mundo(_ghost_gx, _ghost_gy + tam.y),
		grid_a_mundo(_ghost_gx, _ghost_gy),
	])
	canvas.draw_polyline(borde, Color("#22c55e") if valido else Color("#ef4444"), 3.2, true)

	# Sprite flotante translúcido del elemento que se va a colocar (tamaño y apoyo fieles).
	var centro := grid_a_mundo(float(_ghost_gx) + float(tam.x) * 0.5, float(_ghost_gy) + float(tam.y) * 0.5)
	var bob: float = sin(tiempo * 4.5) * 3.5 - 4.0
	var clave_ico: String = "tierra" if _ghost_cat == "tierra" else _ghost_tipo
	var tex := IconoProducto.obtener_textura(clave_ico)
	if tex != null:
		var lado: float = 196.0 if _ghost_tipo == "molino" else (156.0 if _ghost_tipo == "panaderia" else (128.0 if tam.x >= 3 else 78.0))
		var base_off_y: float = 26.0 if _ghost_tipo == "molino" else (24.0 if _ghost_tipo == "panaderia" else (18.0 if tam.x >= 3 else 14.0))
		var tinte := Color(0.88, 1.0, 0.90, 0.86) if valido else Color(1.0, 0.62, 0.62, 0.80)
		var fx: float = -1.0 if (_ghost_volteado != _ghost_rotado) else 1.0
		canvas.draw_set_transform(centro + Vector2(0, bob + base_off_y), 0.0, Vector2(fx, 1.0))
		canvas.draw_texture_rect(tex, Rect2(-lado * 0.5, -lado, lado, lado), false, tinte)
		canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Etiqueta compacta con la huella exacta («4×4», «4×3», «2×2»).
	var etq := "%d×%d" % [tam.x, tam.y]
	var tw: float = FUENTE_BOLD.get_string_size(etq, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	var p_etq := grid_a_mundo(_ghost_gx + tam.x, _ghost_gy + tam.y) + Vector2(0, 6)
	canvas.draw_rect(Rect2(p_etq.x - tw * 0.5 - 8, p_etq.y, tw + 16, 18), Color("#15803d") if valido else Color("#b91c1c"))
	canvas.draw_string(FUENTE_BOLD, Vector2(p_etq.x - tw * 0.5, p_etq.y + 13), etq, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)


# ------------------------------------------------------------------
# Ambiente vivo (mariposas y motas de sol)
# ------------------------------------------------------------------

func _Dibujar_Ambiente(canvas: CanvasItem, tiempo: float, mariposas: Array[Dictionary], motas: Array[Dictionary]) -> void:
	for m in motas:
		var base: Vector2 = m["base"]
		var t: float = tiempo * float(m["vel"]) + float(m["fase"])
		var pos := base + Vector2(cos(t * 0.7) * 14.0, sin(t) * 8.0)
		var alpha: float = 0.16 + 0.22 * (0.5 + 0.5 * sin(t * 1.4))
		var r: float = float(m["radio"])
		canvas.draw_circle(pos, r + 1.8, Color(1.0, 0.98, 0.72, alpha * 0.35))
		canvas.draw_circle(pos, r, Color(1.0, 0.99, 0.86, alpha))

	for b in mariposas:
		var cen: Vector2 = b["centro"]
		var t: float = tiempo * float(b["vel"]) + float(b["fase"])
		var pos := cen + Vector2(cos(t) * float(b["radio_x"]), sin(t * 1.5) * float(b["radio_y"]))
		var aleteo: float = 0.35 + 0.65 * absf(sin(tiempo * 13.0 + float(b["fase"])))
		var col: Color = b["color"]
		canvas.draw_circle(pos + Vector2(-3.2 * aleteo, -1.0), 3.0 * aleteo + 0.8, col)
		canvas.draw_circle(pos + Vector2(3.2 * aleteo, -1.0), 3.0 * aleteo + 0.8, col)
		canvas.draw_circle(pos, 1.3, Color("#451a03"))


func _Elipse_C(canvas: CanvasItem, centro: Vector2, rx: float, ry: float, color: Color, puntos: int = 20) -> void:
	var p := PackedVector2Array()
	for i in range(puntos):
		var a := TAU * float(i) / float(puntos)
		p.append(centro + Vector2(cos(a) * rx, sin(a) * ry))
	canvas.draw_colored_polygon(p, color)


func _Contorno_Elipse_C(canvas: CanvasItem, centro: Vector2, rx: float, ry: float, color: Color, ancho: float, puntos: int = 24) -> void:
	var p := PackedVector2Array()
	for i in range(puntos + 1):
		var a := TAU * float(i) / float(puntos)
		p.append(centro + Vector2(cos(a) * rx, sin(a) * ry))
	canvas.draw_polyline(p, color, ancho, true)
