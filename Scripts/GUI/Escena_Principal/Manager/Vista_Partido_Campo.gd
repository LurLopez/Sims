class_name Vista_Partido_Campo
extends Control

# Visualizador 2D en directo del partido de «El Mánager».
# Pinta el estadio iluminado, las líneas del campo, 22 jugadores en formación
# que basculan con la posesión y el balón desplazándose según los eventos
# (ataques, paradas, córners y goles).

var color_local: Color = Color("#0f766e")
var color_local_sec: Color = Color("#ffffff")
var color_visitante: Color = Color("#dc2626")
var color_visitante_sec: Color = Color("#ffffff")

var _posesion_local: float = 0.5
var _balon_actual := Vector2(0.5, 0.5)
var _balon_objetivo := Vector2(0.5, 0.5)
var _fase_impulso: float = 0.0
var _flash_texto: String = ""
var _flash_color: Color = Color("#fbbf24")
var _flash_tiempo: float = 0.0
var _t: float = 0.0
var _ultimo_minuto: int = -1
var _fuente: Font = null


func _ready() -> void:
	custom_minimum_size = Vector2(0, 178)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	_fuente = Estilos_UI.fuente_titulo(700)
	set_process(true)


func configurar_colores(col_l: Array, col_v: Array) -> void:
	if col_l.size() >= 2:
		color_local = Color(str(col_l[0]))
		color_local_sec = Color(str(col_l[1]))
	if col_v.size() >= 2:
		color_visitante = Color(str(col_v[0]))
		color_visitante_sec = Color(str(col_v[1]))
	# Si ambos clubes comparten color muy parecido, contrastamos el visitante.
	if Vector3(color_local.r - color_visitante.r, color_local.g - color_visitante.g,
			color_local.b - color_visitante.b).length() < 0.25:
		color_visitante = color_visitante.inverted()
	queue_redraw()


func actualizar_estado(estado: Dictionary) -> void:
	var minuto: int = int(estado.get("minuto", 0))
	_posesion_local = clampf(Simulador_Manager.Posesion_Local(estado) / 100.0, 0.25, 0.75)
	var eventos = estado.get("eventos", [])
	if minuto != _ultimo_minuto:
		_ultimo_minuto = minuto
		var sesgo_x: float = clampf(_posesion_local + sin(float(minuto) * 0.7) * 0.16, 0.20, 0.80)
		var sesgo_y: float = 0.50 + cos(float(minuto) * 1.1) * 0.26
		_balon_objetivo = Vector2(sesgo_x, sesgo_y)
		if eventos is Array and not eventos.is_empty():
			var ultimo = eventos[eventos.size() - 1]
			if ultimo is Dictionary and int(ultimo.get("minuto", -1)) == minuto:
				_Reaccionar_Evento(ultimo)
	queue_redraw()


func _Reaccionar_Evento(ev: Dictionary) -> void:
	var tipo: String = str(ev.get("tipo", ""))
	var eq: String = str(ev.get("equipo", ""))
	var hacia_der: bool = eq == "local"
	match tipo:
		"gol":
			_balon_objetivo = Vector2(0.95 if hacia_der else 0.05, 0.50)
			_flash_texto = "¡GOOOOL!"
			_flash_color = Color("#fbbf24")
			_flash_tiempo = 2.6
			_fase_impulso = 1.0
		"ocasion":
			_balon_objetivo = Vector2(0.89 if hacia_der else 0.11, 0.44)
			_flash_texto = "¡OCASIÓN!"
			_flash_color = Color("#38bdf8")
			_flash_tiempo = 1.5
			_fase_impulso = 0.8
		"corner":
			_balon_objetivo = Vector2(0.94 if hacia_der else 0.06, 0.09)
			_flash_texto = "CÓRNER"
			_flash_color = Color("#a7f3d0")
			_flash_tiempo = 1.2
		"tarjeta":
			_flash_texto = "AMARILLA"
			_flash_color = Color("#facc15")
			_flash_tiempo = 1.4


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_t += delta
	_balon_actual = _balon_actual.lerp(_balon_objetivo, clampf(delta * 4.5, 0.0, 1.0))
	if _flash_tiempo > 0.0:
		_flash_tiempo = maxf(0.0, _flash_tiempo - delta)
	if _fase_impulso > 0.0:
		_fase_impulso = maxf(0.0, _fase_impulso - delta * 1.4)
	queue_redraw()


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w < 20.0 or h < 20.0:
		return

	# Fondo oscuro exterior y césped segado horizontal.
	draw_rect(Rect2(0, 0, w, h), Color("#0b1220"))
	var m_x: float = 10.0
	var m_y: float = 8.0
	var cw: float = w - m_x * 2.0
	var ch: float = h - m_y * 2.0
	draw_rect(Rect2(m_x, m_y, cw, ch), Color("#15803d"))
	var franjas: int = 10
	for i in range(franjas):
		if i % 2 == 0:
			draw_rect(Rect2(m_x + cw * float(i) / float(franjas), m_y,
				cw / float(franjas), ch), Color("#166534"))

	# Focos de estadio en las esquinas.
	for esquina in [Vector2(0, 0), Vector2(w, 0), Vector2(0, h), Vector2(w, h)]:
		draw_circle(esquina, 52.0, Color(1, 1, 0.9, 0.06))

	# Líneas del campo.
	var linea := Color(1, 1, 1, 0.45)
	var g: float = 1.5
	draw_rect(Rect2(m_x, m_y, cw, ch), linea, false, g)
	draw_line(Vector2(w * 0.5, m_y), Vector2(w * 0.5, m_y + ch), linea, g)
	draw_circle(Vector2(w * 0.5, h * 0.5), ch * 0.22, linea, false, g)
	draw_circle(Vector2(w * 0.5, h * 0.5), 2.5, linea)

	# Áreas izquierda (local) y derecha (visitante).
	var aw: float = cw * 0.14
	var ah: float = ch * 0.56
	draw_rect(Rect2(m_x, h * 0.5 - ah * 0.5, aw, ah), linea, false, g)
	draw_rect(Rect2(m_x + cw - aw, h * 0.5 - ah * 0.5, aw, ah), linea, false, g)
	var gh: float = ch * 0.26
	draw_rect(Rect2(m_x - 5.0, h * 0.5 - gh * 0.5, 5.0, gh), Color(1, 1, 1, 0.72), false, g)
	draw_rect(Rect2(m_x + cw, h * 0.5 - gh * 0.5, 5.0, gh), Color(1, 1, 1, 0.72), false, g)

	# 22 jugadores animados basculando hacia el balón.
	var empuje: float = (_balon_actual.x - 0.5) * 0.18
	var slots_x_l: Array = [0.05, 0.21, 0.20, 0.20, 0.21, 0.42, 0.40, 0.40, 0.42, 0.62, 0.62]
	var slots_y_l: Array = [0.50, 0.16, 0.38, 0.62, 0.84, 0.18, 0.39, 0.61, 0.82, 0.37, 0.63]
	for i in range(11):
		var osc: float = sin(_t * 2.6 + float(i) * 1.1) * 0.014
		var px_l: float = clampf(float(slots_x_l[i]) + (0.0 if i == 0 else empuje) + osc, 0.04, 0.92)
		var py_l: float = clampf(float(slots_y_l[i]) + cos(_t * 2.1 + float(i)) * 0.018, 0.10, 0.90)
		var pos_l := Vector2(m_x + cw * px_l, m_y + ch * py_l)
		var c_l: Color = Color("#f59e0b") if i == 0 else color_local
		draw_circle(pos_l + Vector2(1, 1.5), 5.2, Color(0, 0, 0, 0.35))
		draw_circle(pos_l, 5.2, c_l)
		draw_arc(pos_l, 5.2, 0.0, TAU, 16, color_local_sec, 1.3, true)

		var px_v: float = clampf(1.0 - float(slots_x_l[i]) + (0.0 if i == 0 else empuje) - osc, 0.08, 0.96)
		var py_v: float = clampf(float(slots_y_l[i]) - sin(_t * 2.2 + float(i)) * 0.018, 0.10, 0.90)
		var pos_v := Vector2(m_x + cw * px_v, m_y + ch * py_v)
		var c_v: Color = Color("#38bdf8") if i == 0 else color_visitante
		draw_circle(pos_v + Vector2(1, 1.5), 5.2, Color(0, 0, 0, 0.35))
		draw_circle(pos_v, 5.2, c_v)
		draw_arc(pos_v, 5.2, 0.0, TAU, 16, color_visitante_sec, 1.3, true)

	# Balón animado.
	var b_pos := Vector2(m_x + cw * _balon_actual.x, m_y + ch * _balon_actual.y)
	if _fase_impulso > 0.0:
		draw_circle(b_pos, 11.0 + _fase_impulso * 8.0, Color(_flash_color, 0.25 * _fase_impulso))
	draw_circle(b_pos + Vector2(1.5, 2.5), 4.6, Color(0, 0, 0, 0.4))
	draw_circle(b_pos, 4.6, Color.WHITE)
	draw_arc(b_pos, 4.6, 0.0, TAU, 16, Color("#111827"), 1.4, true)

	# Flash visual de evento importante (Gol, Ocasión, Córner).
	if _flash_tiempo > 0.0 and _fuente != null:
		var alfa: float = clampf(_flash_tiempo, 0.0, 1.0)
		var ancho_b: float = 176.0
		var rect_b := Rect2(w * 0.5 - ancho_b * 0.5, h * 0.5 - 17.0, ancho_b, 34.0)
		draw_rect(rect_b, Color(0.05, 0.08, 0.15, 0.86 * alfa))
		draw_rect(rect_b, Color(_flash_color, 0.9 * alfa), false, 2.0)
		var tw: float = _fuente.get_string_size(_flash_texto, HORIZONTAL_ALIGNMENT_CENTER, -1.0, 16).x
		draw_string(_fuente, Vector2(w * 0.5 - tw * 0.5, h * 0.5 + 5.5),
			_flash_texto, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color(_flash_color, alfa))
