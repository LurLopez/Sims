class_name Arrastre_Cocina
extends Control

# ============================================================================
# Gestor de arrastrar y soltar del Minijuego de Cocina.
# Permite coger ingredientes, platos, carnes y bebidas y llevarlos a otra
# estación con el dedo/ratón, mostrando un "fantasma" animado del objeto y
# resaltando la zona de destino válida.
#
# Las zonas se registran como rectángulos con dos callables:
#   · origen.obtener(datos)  -> devuelve payload + dibujante o {} si no se puede.
#   · destino.acepta(payload) -> true si admite el objeto.
# El juego decide qué hacer al soltar mediante la señal `soltado`.
# ============================================================================

signal arrastre_iniciado(payload: Dictionary, origen: Dictionary)
signal arrastre_movido(payload: Dictionary, pos: Vector2)
signal arrastre_soltado(payload: Dictionary, destino: Dictionary, pos: Vector2)
signal arrastre_cancelado(payload: Dictionary)
signal origen_tocado(payload: Dictionary, origen: Dictionary)
# Zonas que solo responden al toque (clientes, controles del pase...). Se usan
# cuando no hay un origen arrastrable debajo del dedo, para que un toque corto
# haga la acción principal sin obligar a arrastrar.
signal zona_tocada(datos: Dictionary)

const UMBRAL_ARRASTRE: float = 9.0

var habilitado: bool = true
var destino_actual: Dictionary = {}

var _origenes: Array[Dictionary] = []
var _zonas_toque: Array[Dictionary] = []
var _toque: Dictionary = {}
var _destinos: Array[Dictionary] = []
var _presionando: bool = false
var _activo: bool = false
var _pos_inicial: Vector2 = Vector2.ZERO
var _pos: Vector2 = Vector2.ZERO
var _pos_anterior: Vector2 = Vector2.ZERO
var _velocidad: Vector2 = Vector2.ZERO
var _inclinacion: float = 0.0
var _payload: Dictionary = {}
var _textura: Texture2D = null
var _dibujante: Callable
var _tam_icono: Vector2 = Vector2(92, 92)
var _origen: Dictionary = {}
var _pulso: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process_input(true)
	set_process(true)


# ----------------------------------------------------------------------------
# Registro de zonas
# ----------------------------------------------------------------------------

func limpiar_registros() -> void:
	_origenes.clear()
	_zonas_toque.clear()
	_toque = {}
	_destinos.clear()
	destino_actual = {}


func registrar_origen(rect: Rect2, datos: Dictionary, obtener: Callable) -> void:
	_origenes.append({"rect": rect, "datos": datos, "obtener": obtener})


func registrar_toque(rect: Rect2, datos: Dictionary) -> void:
	_zonas_toque.append({"rect": rect, "datos": datos})


func registrar_destino(rect: Rect2, datos: Dictionary, acepta: Callable) -> void:
	_destinos.append({"rect": rect, "datos": datos, "acepta": acepta})


func _origenes_bajo(pos: Vector2) -> Array[Dictionary]:
	var candidatos: Array[Dictionary] = []
	for i in range(_origenes.size() - 1, -1, -1):
		var o: Dictionary = _origenes[i]
		if (o["rect"] as Rect2).has_point(pos):
			candidatos.append(o)
	if candidatos.size() > 1:
		candidatos.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var da: float = (a["rect"] as Rect2).get_center().distance_squared_to(pos)
			var db: float = (b["rect"] as Rect2).get_center().distance_squared_to(pos)
			return da < db)
	return candidatos


func _origen_bajo(pos: Vector2) -> Dictionary:
	var candidatos := _origenes_bajo(pos)
	return candidatos[0] if not candidatos.is_empty() else {}


func _toque_bajo(pos: Vector2) -> Dictionary:
	var mejor: Dictionary = {}
	var mejor_dist: float = INF
	for i in range(_zonas_toque.size() - 1, -1, -1):
		var z: Dictionary = _zonas_toque[i]
		var r: Rect2 = z["rect"]
		if r.has_point(pos):
			var dist: float = r.get_center().distance_squared_to(pos)
			if dist < mejor_dist:
				mejor_dist = dist
				mejor = z
	return mejor


func _destino_bajo(pos: Vector2) -> Dictionary:
	return resolver_destino(pos, _payload)


func resolver_destino(pos: Vector2, payload: Dictionary) -> Dictionary:
	var rechazado: Dictionary = {}
	for i in range(_destinos.size() - 1, -1, -1):
		var d: Dictionary = _destinos[i]
		if not (d["rect"] as Rect2).has_point(pos):
			continue
		var acepta: Callable = d["acepta"]
		var ok: bool = bool(acepta.call(payload))
		var copia: Dictionary = d.duplicate()
		copia["aceptado"] = ok
		if ok:
			return copia
		if rechazado.is_empty():
			rechazado = copia
	return rechazado


# ----------------------------------------------------------------------------
# Entrada
# ----------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if not habilitado:
		if _activo:
			cancelar()
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var pos: Vector2 = _pos_local(event.position)
		if event.pressed:
			_Iniciar_Pulsacion(pos)
		else:
			_Soltar(pos)
		return

	if event is InputEventMouseMotion and _presionando:
		var pos: Vector2 = _pos_local(event.position)
		_Mover(pos)
		return

	# Compatibilidad directa con pantallas táctiles que no emulan ratón.
	if event is InputEventScreenTouch:
		var pos: Vector2 = _pos_local(event.position)
		if event.pressed:
			_Iniciar_Pulsacion(pos)
		else:
			_Soltar(pos)
		return

	if event is InputEventScreenDrag and _presionando:
		_Mover(_pos_local(event.position))


func _pos_local(p: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * p


func _Iniciar_Pulsacion(pos: Vector2) -> void:
	if not _presionando and not _activo:
		_pos_inicial = pos
		_pos = pos
		_pos_anterior = pos
		_velocidad = Vector2.ZERO
		_toque = {}
		for origen in _origenes_bajo(pos):
			var obtener: Callable = origen["obtener"]
			var info: Dictionary = obtener.call(origen["datos"])
			if not info.is_empty() and info.has("payload"):
				_presionando = true
				_origen = origen
				_payload = info["payload"]
				_textura = info.get("textura", null)
				_dibujante = info.get("dibujar", Callable())
				_tam_icono = info.get("tam", Vector2(92, 92))
				_inclinacion = 0.0
				get_viewport().set_input_as_handled()
				return
		# Sin origen arrastrable: si hay una zona de toque, recordarla para
		# disparar su acción al levantar el dedo. Nunca activa un arrastre.
		var zona: Dictionary = _toque_bajo(pos)
		if not zona.is_empty():
			_toque = zona
			_presionando = true
			get_viewport().set_input_as_handled()


func _Mover(pos: Vector2) -> void:
	if _activo:
		_pos_anterior = _pos
		_pos = pos
		var delta: Vector2 = _pos - _pos_anterior
		_velocidad = _velocidad.lerp(delta * 30.0, 0.35)
		_inclinacion = clampf(_velocidad.x * 0.0016, -0.22, 0.22)
		destino_actual = _destino_bajo(pos)
		arrastre_movido.emit(_payload, pos)
		get_viewport().set_input_as_handled()
		return
	if not _presionando:
		return
	if pos.distance_to(_pos_inicial) < UMBRAL_ARRASTRE:
		return
	# Si era una zona de solo toque, un movimiento la cancela: el jugador
	# quería desplazarse, no activar la acción.
	if not _toque.is_empty():
		_presionando = false
		_toque = {}
		return
	# Activar arrastre
	_activo = true
	_pos = pos
	_pos_anterior = pos
	_velocidad = Vector2.ZERO
	destino_actual = _destino_bajo(pos)
	arrastre_iniciado.emit(_payload, _origen)
	get_viewport().set_input_as_handled()


func _Soltar(pos: Vector2) -> void:
	if not _presionando and not _activo:
		return
	if _activo:
		_pos = pos
		var destino: Dictionary = _destino_bajo(pos)
		arrastre_soltado.emit(_payload, destino, pos)
	elif not _toque.is_empty():
		zona_tocada.emit(_toque.get("datos", {}))
	else:
		origen_tocado.emit(_payload, _origen)
	_Limpiar()
	get_viewport().set_input_as_handled()


func cancelar() -> void:
	if _activo and not _payload.is_empty():
		arrastre_cancelado.emit(_payload)
	_Limpiar()


func _Limpiar() -> void:
	_presionando = false
	_activo = false
	_payload = {}
	_textura = null
	_dibujante = Callable()
	_origen = {}
	_toque = {}
	destino_actual = {}
	_velocidad = Vector2.ZERO
	_inclinacion = 0.0
	queue_redraw()


# ----------------------------------------------------------------------------
# Animación y dibujo del objeto arrastrado
# ----------------------------------------------------------------------------

func _process(delta: float) -> void:
	if not _activo:
		if _pulso != 0.0:
			_pulso = 0.0
			queue_redraw()
		return
	_pulso += delta
	if _velocidad.length() > 4.0:
		_velocidad = _velocidad.lerp(Vector2.ZERO, 0.12)
	queue_redraw()


func esta_arrastrando() -> bool:
	return _activo


func _draw() -> void:
	if not _activo:
		return
	var elevacion := 30.0
	var flotar: float = sin(_pulso * 7.0) * 2.5
	var centro: Vector2 = _pos + Vector2(0.0, -elevacion + flotar)

	# Zona de destino resaltada
	if not destino_actual.is_empty() and destino_actual.has("rect"):
		var rect: Rect2 = destino_actual["rect"]
		var ok: bool = bool(destino_actual.get("aceptado", false))
		var col := Color("#38bdf8") if ok else Color("#f87171")
		var alpha: float = 0.20 + 0.10 * (0.5 + 0.5 * sin(_pulso * 8.0))
		Arte_Cocina.caja_redondeada(self, rect.grow(2.0), 14.0, Color(col, alpha), col, 3.0)

	# Sombra del objeto en el "suelo"
	draw_set_transform(_pos + Vector2(0.0, 8.0), 0.0, Vector2(1.0, 0.34))
	draw_circle(Vector2.ZERO, 34.0, Color(0.0, 0.0, 0.0, 0.26))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Objeto flotante
	draw_set_transform(centro, _inclinacion, Vector2(1.10, 1.10))
	if _dibujante.is_valid():
		_dibujante.call(self, Vector2.ZERO)
	elif _textura != null:
		var r := Rect2(-_tam_icono * 0.5, _tam_icono)
		draw_texture_rect(_textura, r, false, Color.WHITE)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Punto de agarre bajo el objeto
	draw_circle(_pos, 5.0, Color(1.0, 1.0, 1.0, 0.55))
	draw_arc(_pos, 9.0 + 2.0 * (0.5 + 0.5 * sin(_pulso * 6.0)), 0.0, TAU, 18,
		Color(1.0, 1.0, 1.0, 0.30), 1.5, true)
