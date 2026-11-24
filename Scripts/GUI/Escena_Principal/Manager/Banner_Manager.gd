class_name Banner_Manager
extends Control

# Banner ilustrado procedural para la tarjeta de «El Mánager» en Minijuegos.
# Combina estadio bajo focos, césped segado, escudo del club y el Personaje_Visual
# real del Sim vestido de entrenador en traje.

var _cresta: Cresta_Manager = null
var _manager_pj: Personaje_Visual = null
var _club_nombre: String = ""
var _colores: Array = ["#0f766e", "#ffffff"]
var _patron: int = 1
var _fuente_titulo: Font = null
var _fuente_sub: Font = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	custom_minimum_size = Vector2(0, 146)
	_fuente_titulo = Estilos_UI.fuente_titulo(700)
	_fuente_sub = Estilos_UI.fuente_ui(600)

	_cresta = Cresta_Manager.new()
	_cresta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cresta)

	var ap: Dictionary = Estilo_Manager._apariencia_sim_manager(_colores)
	_manager_pj = Personaje_Visual.new(ap, "busto")
	_manager_pj.name = "Manager_Sim_2D"
	_manager_pj.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_manager_pj.dibujar_fondo_sunburst = false
	_manager_pj.animar_idle = false
	_manager_pj.expresion = "feliz"
	add_child(_manager_pj)

	_Actualizar_Layout()
	resized.connect(_Actualizar_Layout)
	queue_redraw()


func configurar(club: Dictionary) -> void:
	if club.is_empty():
		_club_nombre = ""
		_colores = ["#0f766e", "#ffffff"]
		_patron = 1
		if _cresta != null:
			_cresta.configurar("MGR", _colores, _patron, true)
	else:
		_club_nombre = str(club.get("nombre", ""))
		_colores = club.get("colores", ["#0f766e", "#ffffff"])
		_patron = int(club.get("escudo_patron", 1))
		if _cresta != null:
			_cresta.configurar(_club_nombre, _colores, _patron, true)
	if _manager_pj != null:
		_manager_pj.apariencia = Estilo_Manager._apariencia_sim_manager(_colores)
	queue_redraw()


func _Actualizar_Layout() -> void:
	var w: float = size.x
	var h: float = size.y
	if w < 10.0 or h < 10.0:
		return
	if _cresta != null:
		_cresta.position = Vector2(18.0, (h - 90.0) * 0.5)
		_cresta.size = Vector2(90.0, 90.0)
	if _manager_pj != null:
		var alto_p: float = h * 1.18
		var ancho_p: float = alto_p * 0.86
		_manager_pj.position = Vector2(w - ancho_p - 6.0, h - alto_p + 12.0)
		_manager_pj.size = Vector2(ancho_p, alto_p)


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w < 10.0 or h < 10.0:
		return

	var col_pri: Color = Color(str(_colores[0])) if _colores.size() >= 1 else Color("#0f766e")
	var cielo_top: Color = Color("#0b132b")
	var cielo_bot: Color = col_pri.darkened(0.55)
	for y in range(int(h * 0.65)):
		var t: float = float(y) / maxf(1.0, h * 0.65)
		draw_rect(Rect2(0, float(y), w, 1.5), cielo_top.lerp(cielo_bot, t))

	# Haces de focos del estadio.
	for foco_x in [w * 0.14, w * 0.84]:
		draw_colored_polygon(PackedVector2Array([
			Vector2(foco_x, 10.0),
			Vector2(foco_x - 85.0, h * 0.72),
			Vector2(foco_x + 85.0, h * 0.72)
		]), Color(1.0, 0.96, 0.82, 0.055))
		draw_circle(Vector2(foco_x, 10.0), 6.5, Color(1, 0.98, 0.85, 0.25))

	# Césped inferior en franjas.
	var y_cesped: float = h * 0.62
	var h_cesped: float = h - y_cesped
	draw_rect(Rect2(0, y_cesped, w, h_cesped), Color("#15803d"))
	for i in range(9):
		if i % 2 == 0:
			draw_rect(Rect2(w * float(i) / 9.0, y_cesped, w / 9.0, h_cesped), Color("#166534"))
	draw_line(Vector2(0, y_cesped), Vector2(w, y_cesped), Color(1, 1, 1, 0.35), 2.0)

	# Líneas tácticas sutiles en perspectiva.
	draw_arc(Vector2(w * 0.50, y_cesped + h_cesped * 0.5), 42.0, 0.0, TAU, 32, Color(1, 1, 1, 0.18), 1.5)

	# Balón en el césped delante del entrenador.
	var bx: float = w * 0.71
	var by: float = h * 0.80
	draw_circle(Vector2(bx + 2.0, by + 3.0), 15.0, Color(0, 0, 0, 0.32))
	draw_circle(Vector2(bx, by), 15.0, Color.WHITE)
	draw_arc(Vector2(bx, by), 15.0, 0.0, TAU, 24, Color("#111827"), 1.6, true)
	draw_circle(Vector2(bx, by - 2.0), 4.6, Color("#111827"))
	for ang in [0.0, 72.0, 144.0, 216.0, 288.0]:
		var rad: float = deg_to_rad(ang)
		draw_circle(Vector2(bx + cos(rad) * 10.0, by - 1.0 + sin(rad) * 10.0), 2.5, Color("#111827"))

	# Textos principales a la derecha del escudo.
	if _fuente_titulo != null:
		var tx: float = 122.0
		var ty: float = 54.0
		draw_string(_fuente_titulo, Vector2(tx, ty + 2.0), "EL MÁNAGER",
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, 27, Color(0, 0, 0, 0.45))
		draw_string(_fuente_titulo, Vector2(tx, ty), "EL MÁNAGER",
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, 27, Color.WHITE)
	if _fuente_sub != null:
		var sub: String = "%s · Modo Club" % _club_nombre if _club_nombre != "" else "16 clubes · 4 divisiones · 90 min"
		draw_string(_fuente_sub, Vector2(122.0, 78.0), sub,
			HORIZONTAL_ALIGNMENT_LEFT, w - 250.0, 13, Color(1, 1, 1, 0.86))
