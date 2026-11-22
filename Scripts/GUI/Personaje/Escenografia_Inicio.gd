class_name Escenografia_Inicio
extends RefCounted
## Arte procedural de las escenas del escenario de Inicio.
##
## Cada pose de `Escenario_Actividad` tiene aquí su fondo y su capa frontal.
## El objetivo es el mismo lenguaje visual que la escena de tiempo libre:
## degradados suaves, luz cálida, muebles con volumen, props dibujados a mano
## y partículas ambientales. Todo se dibuja con primitivas de CanvasItem para
## no depender de texturas y mantenerse ligero en móvil.

const TINTA := Color("#111827")
const FUENTE_COMIC := preload("res://Fuentes/UI/Bricolage-800.ttf")

const PALETA_LIBROS: Array[Color] = [
	Color("#ef4444"), Color("#3b82f6"), Color("#22c55e"), Color("#f59e0b"),
	Color("#8b5cf6"), Color("#0ea5e9"), Color("#e11d48"), Color("#14b8a6"),
	Color("#f97316"), Color("#64748b"),
]


# ---------------------------------------------------------------- entrada

static func dibujar_fondo(c: CanvasItem, esc, w: float, h: float) -> void:
	if w <= 1.0 or h <= 1.0:
		return
	var t: float = esc._t
	var pose: String = esc._pose_actual
	var v: String = esc._variacion_activa
	match pose:
		"correr":
			_correr(c, esc, w, h, t, v)
		"dormir":
			_dormir(c, esc, w, h, t, v)
		"comer":
			_comer(c, esc, w, h, t, v)
		"duchar":
			_duchar(c, esc, w, h, t, v)
		"estudiar":
			_estudiar(c, esc, w, h, t, v)
		"tv":
			_tv(c, esc, w, h, t, v)
		"manualidades":
			_manualidades(c, esc, w, h, t, v)
		"cocinar":
			_cocinar(c, esc, w, h, t, v)
		"fiesta":
			_fiesta(c, esc, w, h, t, v)
		"futbol":
			_futbol(c, esc, w, h, t, v)
		"trabajar":
			_trabajar(c, esc, w, h, t, v)


static func dibujar_frente(c: CanvasItem, esc, w: float, h: float) -> void:
	if w <= 1.0 or h <= 1.0:
		return
	var t: float = esc._t
	var pose: String = esc._pose_actual
	var v: String = esc._variacion_activa
	match pose:
		"correr":
			_frente_correr(c, esc, w, h, t, v)
		"dormir":
			_frente_dormir(c, esc, w, h, t, v)
		"comer":
			_frente_comer(c, esc, w, h, t, v)
		"duchar":
			_frente_duchar(c, esc, w, h, t, v)
		"estudiar":
			_frente_estudiar(c, esc, w, h, t, v)
		"tv":
			_frente_tv(c, esc, w, h, t, v)
		"manualidades":
			_frente_manualidades(c, esc, w, h, t, v)
		"cocinar":
			_frente_cocinar(c, esc, w, h, t, v)
		"fiesta":
			_frente_fiesta(c, esc, w, h, t, v)
		"futbol":
			_frente_futbol(c, esc, w, h, t, v)
		"trabajar":
			_frente_trabajar(c, esc, w, h, t, v)


# ---------------------------------------------------------------- utilidades de dibujo

static func _a(col: Color, alpha: float) -> Color:
	return Color(col.r, col.g, col.b, clampf(alpha, 0.0, 1.0))


static func _grad_v(c: CanvasItem, rect: Rect2, arriba: Color, abajo: Color, bandas: int = 16) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var n: int = maxi(2, bandas)
	for i in range(n):
		var u := float(i) / float(n - 1)
		c.draw_rect(
			Rect2(rect.position.x, rect.position.y + rect.size.y * float(i) / float(n),
				rect.size.x, rect.size.y / float(n) + 1.0),
			arriba.lerp(abajo, u)
		)


static func _grad_h(c: CanvasItem, rect: Rect2, izquierda: Color, derecha: Color, bandas: int = 12) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var n: int = maxi(2, bandas)
	for i in range(n):
		var u := float(i) / float(n - 1)
		c.draw_rect(
			Rect2(rect.position.x + rect.size.x * float(i) / float(n), rect.position.y,
				rect.size.x / float(n) + 1.0, rect.size.y),
			izquierda.lerp(derecha, u)
		)


static func _panel(c: CanvasItem, rect: Rect2, radio: float, relleno: Color) -> void:
	var r := minf(radio, minf(rect.size.x, rect.size.y) * 0.5)
	if r <= 0.5:
		c.draw_rect(rect, relleno)
		return
	c.draw_rect(Rect2(rect.position.x + r, rect.position.y, rect.size.x - r * 2.0, rect.size.y), relleno)
	c.draw_rect(Rect2(rect.position.x, rect.position.y + r, rect.size.x, rect.size.y - r * 2.0), relleno)
	c.draw_circle(Vector2(rect.position.x + r, rect.position.y + r), r, relleno, true, -1.0, true)
	c.draw_circle(Vector2(rect.end.x - r, rect.position.y + r), r, relleno, true, -1.0, true)
	c.draw_circle(Vector2(rect.position.x + r, rect.end.y - r), r, relleno, true, -1.0, true)
	c.draw_circle(Vector2(rect.end.x - r, rect.end.y - r), r, relleno, true, -1.0, true)


static func _panel_borde(c: CanvasItem, rect: Rect2, radio: float, relleno: Color,
		borde: Color, grosor: float = 1.6) -> void:
	_panel(c, rect, radio, relleno)
	if borde.a <= 0.001 or grosor <= 0.0:
		return
	var r := minf(radio, minf(rect.size.x, rect.size.y) * 0.5)
	c.draw_line(Vector2(rect.position.x + r, rect.position.y), Vector2(rect.end.x - r, rect.position.y), borde, grosor, true)
	c.draw_line(Vector2(rect.position.x + r, rect.end.y), Vector2(rect.end.x - r, rect.end.y), borde, grosor, true)
	c.draw_line(Vector2(rect.position.x, rect.position.y + r), Vector2(rect.position.x, rect.end.y - r), borde, grosor, true)
	c.draw_line(Vector2(rect.end.x, rect.position.y + r), Vector2(rect.end.x, rect.end.y - r), borde, grosor, true)
	c.draw_arc(Vector2(rect.position.x + r, rect.position.y + r), r, PI, PI * 1.5, 8, borde, grosor, true)
	c.draw_arc(Vector2(rect.end.x - r, rect.position.y + r), r, PI * 1.5, TAU, 8, borde, grosor, true)
	c.draw_arc(Vector2(rect.end.x - r, rect.end.y - r), r, 0.0, PI * 0.5, 8, borde, grosor, true)
	c.draw_arc(Vector2(rect.position.x + r, rect.end.y - r), r, PI * 0.5, PI, 8, borde, grosor, true)


static func _elipse_pts(centro: Vector2, rx: float, ry: float, segs: int = 26, rot: float = 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var ca := cos(rot)
	var sa := sin(rot)
	for i in range(segs):
		var ang := TAU * float(i) / float(segs)
		var lx := cos(ang) * rx
		var ly := sin(ang) * ry
		pts.append(centro + Vector2(lx * ca - ly * sa, lx * sa + ly * ca))
	return pts


static func _elipse(c: CanvasItem, centro: Vector2, rx: float, ry: float, relleno: Color,
		borde: Color = Color.TRANSPARENT, grosor: float = 0.0, segs: int = 26) -> void:
	var pts := _elipse_pts(centro, rx, ry, segs)
	c.draw_colored_polygon(pts, relleno)
	if borde.a > 0.001 and grosor > 0.0:
		var cerrado := PackedVector2Array(pts)
		cerrado.append(pts[0])
		c.draw_polyline(cerrado, borde, grosor, true)


static func _sombra(c: CanvasItem, centro: Vector2, rx: float, ry: float, alpha: float) -> void:
	c.draw_colored_polygon(_elipse_pts(centro, rx, ry, 24), Color(0.06, 0.05, 0.04, alpha))


static func _rect_borde(c: CanvasItem, rect: Rect2, relleno: Color, borde: Color, grosor: float = 1.6) -> void:
	c.draw_rect(rect, relleno)
	c.draw_rect(rect, borde, false, grosor)


static func _madera(c: CanvasItem, rect: Rect2, col_base: Color, horizontal: bool = true,
		semilla: float = 0.0) -> void:
	c.draw_rect(rect, col_base)
	var oscuro := col_base.darkened(0.18)
	var claro := col_base.lightened(0.10)
	if horizontal:
		for i in range(4):
			var y := rect.position.y + rect.size.y * (0.18 + float(i) * 0.21)
			var off := sin(semilla + float(i) * 1.7) * rect.size.x * 0.025
			c.draw_line(Vector2(rect.position.x + off, y), Vector2(rect.end.x, y + off * 0.2),
				_a(oscuro, 0.30), 1.0, true)
		c.draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, maxf(1.4, rect.size.y * 0.06)), _a(claro, 0.50))
		c.draw_rect(Rect2(rect.position.x, rect.end.y - maxf(1.2, rect.size.y * 0.05), rect.size.x,
			maxf(1.2, rect.size.y * 0.05)), _a(oscuro, 0.38))
	else:
		for i in range(4):
			var x := rect.position.x + rect.size.x * (0.18 + float(i) * 0.21)
			c.draw_line(Vector2(x, rect.position.y), Vector2(x + sin(semilla + float(i)) * 2.0, rect.end.y),
				_a(oscuro, 0.28), 1.0, true)
		c.draw_rect(Rect2(rect.position.x, rect.position.y, maxf(1.4, rect.size.x * 0.05), rect.size.y), _a(claro, 0.40))


static func _azulejos(c: CanvasItem, rect: Rect2, col_base: Color, col_junta: Color,
		tam: float = 30.0, t: float = 0.0, semilla: float = 0.0) -> void:
	_grad_v(c, rect, col_base.lightened(0.05), col_base.darkened(0.07), 12)
	c.draw_rect(rect, col_junta, false, 1.2)
	var x := rect.position.x
	var idx_x := 0
	while x <= rect.end.x:
		c.draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), _a(col_junta, 0.85), 1.2, true)
		x += tam
		idx_x += 1
	var y := rect.position.y
	var idx_y := 0
	while y <= rect.end.y:
		c.draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), _a(col_junta, 0.85), 1.2, true)
		y += tam
		idx_y += 1
	# Brillos suaves dispersos que dan vida al azulejo sin parpadear.
	for i in range(5):
		var fx := rect.position.x + rect.size.x * fmod(0.13 + float(i) * 0.213 + semilla, 1.0)
		var fy := rect.position.y + rect.size.y * fmod(0.19 + float(i) * 0.317, 1.0)
		c.draw_rect(Rect2(fx, fy, tam * 0.62, maxf(1.2, tam * 0.06)), _a(Color.WHITE, 0.16))
	c.draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, maxf(2.0, rect.size.y * 0.03)),
		_a(Color.WHITE, 0.20))


static func _haz(c: CanvasItem, pts: PackedVector2Array, col: Color) -> void:
	if pts.size() >= 3:
		c.draw_colored_polygon(pts, col)


static func _motas(c: CanvasItem, rect: Rect2, t: float, n: int, col: Color, semilla: float = 0.0) -> void:
	for i in range(n):
		var fx := fmod(float(i) * 0.618 + semilla, 1.0)
		var fy := fmod(float(i) * 0.377 + semilla * 0.7, 1.0)
		var px := rect.position.x + rect.size.x * fx + sin(t * (0.30 + 0.09 * float(i % 3)) + float(i) * 1.7) * rect.size.x * 0.035
		var py := rect.position.y + fmod(rect.size.y * fy + t * (2.2 + float(i % 3) * 1.4), rect.size.y)
		var r := 0.7 + float(i % 3) * 0.5
		c.draw_circle(Vector2(px, py), r, col, true, -1.0, true)


static func _bokeh(c: CanvasItem, rect: Rect2, t: float, n: int, colores: Array[Color],
		semilla: float = 0.0, alfa: float = 0.20) -> void:
	for i in range(n):
		var fx := fmod(float(i) * 0.419 + semilla, 1.0)
		var fy := fmod(float(i) * 0.733 + semilla * 0.6, 1.0)
		var px := rect.position.x + rect.size.x * fx + sin(t * 0.35 + float(i)) * 6.0
		var py := rect.position.y + rect.size.y * fy + cos(t * 0.28 + float(i) * 1.3) * 5.0
		var r := 4.0 + float(i % 4) * 4.5
		var col: Color = colores[i % colores.size()]
		c.draw_circle(Vector2(px, py), r, _a(col, alfa * (0.75 + 0.25 * sin(t * 1.1 + float(i)))), true, -1.0, true)


static func _vignette(c: CanvasItem, w: float, h: float, fuerza: float, col: Color = Color.BLACK) -> void:
	var bandas := 7
	for i in range(bandas):
		var u := float(i) / float(bandas)
		var alpha := fuerza * (1.0 - u) * (1.0 - u)
		c.draw_rect(Rect2(0.0, h * u * 0.30, w, h * 0.30 / float(bandas) + 1.0), _a(col, alpha))
		c.draw_rect(Rect2(0.0, h - h * 0.30 * (1.0 - u) - h * 0.30 / float(bandas), w,
			h * 0.30 / float(bandas) + 1.0), _a(col, alpha))


static func _nube(c: CanvasItem, centro: Vector2, r: float, alpha: float) -> void:
	var col := _a(Color.WHITE, alpha)
	c.draw_circle(centro + Vector2(-r * 0.95, r * 0.16), r * 0.62, col, true, -1.0, true)
	c.draw_circle(centro + Vector2(0.0, -r * 0.20), r * 0.92, col, true, -1.0, true)
	c.draw_circle(centro + Vector2(r * 0.92, r * 0.10), r * 0.66, col, true, -1.0, true)
	c.draw_rect(Rect2(centro.x - r * 1.25, centro.y + r * 0.16, r * 2.5, r * 0.52), col)


static func _pajaro(c: CanvasItem, pos: Vector2, tam: float, col: Color) -> void:
	c.draw_arc(pos + Vector2(-tam, 0.0), tam, PI * 0.15, PI * 0.95, 8, col, 1.4, true)
	c.draw_arc(pos + Vector2(tam, 0.0), tam, PI * 0.05, PI * 0.85, 8, col, 1.4, true)


static func _ventana(c: CanvasItem, marco: Rect2, franja: String, t: float,
		con_cortinas: bool = true, col_cortina: Color = Color("#cbd5e1"),
		col_marco: Color = Color("#c8ccd0")) -> void:
	var noche := franja == "noche"
	var atardecer := franja == "atardecer"
	# Sombra y marco exterior.
	c.draw_rect(Rect2(marco.position + Vector2(4.0, 5.0), marco.size), Color(0.10, 0.08, 0.06, 0.14))
	c.draw_rect(marco, col_marco)
	c.draw_rect(marco.grow(-1.0), col_marco.lightened(0.22), false, 1.6)
	var interior := marco.grow(-5.0)
	var cielo_a := Color("#79c8f2")
	var cielo_b := Color("#dff3fd")
	if atardecer:
		cielo_a = Color("#fb923c")
		cielo_b = Color("#fde68a")
	elif noche:
		cielo_a = Color("#111a3a")
		cielo_b = Color("#31356e")
	_grad_v(c, interior, cielo_a, cielo_b, 10)
	if noche:
		for sp: Vector2 in [Vector2(0.18, 0.20), Vector2(0.36, 0.34), Vector2(0.62, 0.15), Vector2(0.78, 0.42), Vector2(0.24, 0.58)]:
			var p := interior.position + Vector2(interior.size.x * sp.x, interior.size.y * sp.y)
			var br := 0.55 + sin(t * 2.6 + sp.x * 12.0) * 0.40
			c.draw_circle(p, 1.4, Color(1.0, 0.98, 0.82, br), true, -1.0, true)
		var luna := interior.position + Vector2(interior.size.x * 0.70, interior.size.y * 0.28)
		c.draw_circle(luna, interior.size.x * 0.26, _a(Color("#fef9c3"), 0.12), true, -1.0, true)
		c.draw_circle(luna, interior.size.x * 0.115, Color("#fef3c7"), true, -1.0, true)
		c.draw_circle(luna + Vector2(interior.size.x * 0.05, -interior.size.y * 0.03),
			interior.size.x * 0.095, cielo_a, true, -1.0, true)
	else:
		var sol := interior.position + Vector2(interior.size.x * (0.72 if not atardecer else 0.52),
			interior.size.y * (0.24 if not atardecer else 0.62))
		c.draw_circle(sol, interior.size.x * 0.27, _a(Color("#fef08a"), 0.20), true, -1.0, true)
		c.draw_circle(sol, interior.size.x * 0.13, Color("#fef08a"), true, -1.0, true)
		c.draw_circle(sol, interior.size.x * 0.13, _a(Color("#f59e0b"), 0.55), false, 1.2)
		var n1 := interior.position + Vector2(interior.size.x * (0.25 + sin(t * 0.30) * 0.035),
			interior.size.y * 0.30)
		var n2 := interior.position + Vector2(interior.size.x * (0.60 + sin(t * 0.24 + 1.8) * 0.028),
			interior.size.y * 0.64)
		_nube(c, n1, interior.size.x * 0.075, 0.90)
		_nube(c, n2, interior.size.x * 0.055, 0.72)
	# Cruceta.
	var barra: float = maxf(2.6, marco.size.x * 0.042)
	var col_barra := col_marco.lightened(0.10)
	c.draw_rect(Rect2(interior.position.x, marco.position.y + marco.size.y * 0.5 - barra * 0.5,
		marco.size.x, barra), col_barra)
	c.draw_rect(Rect2(marco.position.x + marco.size.x * 0.5 - barra * 0.5, marco.position.y,
		barra, marco.size.y), col_barra)
	c.draw_line(Vector2(interior.position.x, marco.position.y + marco.size.y * 0.5 - barra * 0.5),
		Vector2(interior.end.x, marco.position.y + marco.size.y * 0.5 - barra * 0.5),
		Color(1.0, 1.0, 1.0, 0.40), 1.0)
	# Bisel, contorno y alféizar.
	c.draw_rect(interior, Color(1.0, 1.0, 1.0, 0.32), false, 1.2)
	c.draw_rect(marco, col_marco.darkened(0.48), false, 1.2)
	var alto_alf: float = maxf(4.0, marco.size.y * 0.05)
	var alfeizar := Rect2(marco.position.x - 5.0, marco.end.y - 1.0, marco.size.x + 10.0, alto_alf)
	c.draw_rect(alfeizar, col_marco.lightened(0.30))
	c.draw_line(alfeizar.position, Vector2(alfeizar.end.x, alfeizar.position.y),
		col_marco.darkened(0.20), 1.0)
	c.draw_rect(Rect2(alfeizar.position.x + 2.0, alfeizar.end.y, alfeizar.size.x - 4.0, 2.0),
		Color(0.2, 0.12, 0.05, 0.16))
	# Cortinas.
	if con_cortinas:
		var ancho_c: float = maxf(9.0, marco.size.x * 0.18)
		c.draw_rect(Rect2(marco.position.x - ancho_c - 4.0, marco.position.y - 6.0,
			marco.size.x + ancho_c * 2.0 + 8.0, 3.0), col_marco.darkened(0.30))
		_cortina(c, marco.position.x - ancho_c + 1.0, marco.position.y - 3.0, ancho_c,
			marco.size.y + 7.0, col_cortina, -1.0, t, 0.4)
		_cortina(c, marco.end.x - 1.0, marco.position.y - 3.0, ancho_c,
			marco.size.y + 7.0, col_cortina, 1.0, t, 1.3)


static func _cortina(c: CanvasItem, x: float, y: float, ancho: float, alto: float,
		col: Color, lado: float = 1.0, t: float = 0.0, fase: float = 0.0) -> void:
	var vaiven := sin(t * 0.55 + fase) * 1.6
	var sombra := col.darkened(0.20)
	var luz := col.lightened(0.10)
	var pts := PackedVector2Array([
		Vector2(x, y), Vector2(x + ancho, y),
		Vector2(x + ancho + lado * 2.0 + vaiven, y + alto),
		Vector2(x - lado * 1.0 + vaiven, y + alto),
	])
	c.draw_colored_polygon(pts, col)
	c.draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), col.darkened(0.35), 1.1, true)
	for i in range(3):
		var fx := x + ancho * (0.20 + 0.30 * float(i))
		c.draw_line(Vector2(fx, y + 1.0), Vector2(fx + vaiven * 0.8, y + alto),
			_a(sombra, 0.55), 1.8, true)
	for i in range(2):
		var fx2 := x + ancho * (0.34 + 0.30 * float(i))
		c.draw_line(Vector2(fx2, y + 3.0), Vector2(fx2 + vaiven * 0.8, y + alto - 2.0),
			_a(luz, 0.35), 1.2, true)


static func _cuadro(c: CanvasItem, rect: Rect2, tipo: String, t: float = 0.0,
		semilla: float = 0.0, col_marco: Color = Color("#b45309")) -> void:
	c.draw_rect(Rect2(rect.position + Vector2(3.0, 4.0), rect.size), Color(0.1, 0.07, 0.04, 0.16))
	c.draw_rect(rect, col_marco)
	var interior := rect.grow(-4.0)
	c.draw_rect(interior, Color("#f8f5ee"))
	var arte := interior.grow(-4.0)
	match tipo:
		"paisaje":
			_grad_v(c, arte, Color("#bae6fd"), Color("#dcfce7"), 7)
			c.draw_circle(arte.position + Vector2(arte.size.x * 0.72, arte.size.y * 0.28),
				arte.size.x * 0.10, Color("#fde047"), true, -1.0, true)
			c.draw_colored_polygon(PackedVector2Array([
				Vector2(arte.position.x, arte.end.y),
				Vector2(arte.position.x + arte.size.x * 0.30, arte.position.y + arte.size.y * 0.42),
				Vector2(arte.position.x + arte.size.x * 0.62, arte.end.y),
			]), Color("#86efac"))
			c.draw_colored_polygon(PackedVector2Array([
				Vector2(arte.position.x + arte.size.x * 0.34, arte.end.y),
				Vector2(arte.position.x + arte.size.x * 0.70, arte.position.y + arte.size.y * 0.52),
				Vector2(arte.end.x, arte.end.y),
			]), Color("#4ade80"))
		"abstracto":
			c.draw_rect(arte, Color("#fff7ed"))
			c.draw_circle(arte.position + Vector2(arte.size.x * 0.34, arte.size.y * 0.38),
				arte.size.x * 0.22, Color("#f43f5e", 0.78), true, -1.0, true)
			c.draw_circle(arte.position + Vector2(arte.size.x * 0.62, arte.size.y * 0.62),
				arte.size.x * 0.26, Color("#38bdf8", 0.72), true, -1.0, true)
			c.draw_line(arte.position + Vector2(arte.size.x * 0.16, arte.size.y * 0.76),
				arte.position + Vector2(arte.size.x * 0.82, arte.size.y * 0.24),
				Color("#111827", 0.55), 2.0, true)
		"botanico":
			c.draw_rect(arte, Color("#f0fdf4"))
			c.draw_line(Vector2(arte.get_center().x, arte.end.y - 4.0),
				Vector2(arte.get_center().x - 3.0, arte.position.y + 5.0), Color("#166534"), 1.6, true)
			for i in range(4):
				var lado := -1.0 if i % 2 == 0 else 1.0
				var py := arte.position.y + arte.size.y * (0.24 + float(i) * 0.16)
				c.draw_colored_polygon(_elipse_pts(
					Vector2(arte.get_center().x + lado * arte.size.x * 0.17, py),
					arte.size.x * 0.16, arte.size.y * 0.05, 12, lado * 0.35),
					Color("#22c55e" if i % 2 == 0 else "#16a34a"))
		"estrellas":
			c.draw_rect(arte, Color("#172554"))
			for i in range(9):
				var px := arte.position.x + arte.size.x * fmod(0.12 + float(i) * 0.107, 1.0)
				var py := arte.position.y + arte.size.y * fmod(0.16 + float(i) * 0.19, 1.0)
				var br := 0.55 + sin(t * 2.2 + float(i)) * 0.35
				c.draw_circle(Vector2(px, py), 1.3, Color(1.0, 0.97, 0.82, br), true, -1.0, true)
			c.draw_circle(arte.position + Vector2(arte.size.x * 0.68, arte.size.y * 0.30),
				arte.size.x * 0.14, Color("#fef3c7"), true, -1.0, true)
			c.draw_arc(arte.position + Vector2(arte.size.x * 0.68, arte.size.y * 0.30),
				arte.size.x * 0.22, 0.0, TAU, 20, Color("#93c5fd", 0.60), 1.2, true)
		"menu":
			c.draw_rect(arte, Color("#fef3c7"))
			c.draw_string(FUENTE_COMIC, arte.position + Vector2(arte.size.x * 0.18, arte.size.y * 0.38),
				"MENÚ", HORIZONTAL_ALIGNMENT_LEFT, -1, int(maxf(8.0, arte.size.y * 0.22)), Color("#7c2d12"))
			for i in range(3):
				c.draw_line(Vector2(arte.position.x + arte.size.x * 0.16, arte.position.y + arte.size.y * (0.55 + float(i) * 0.12)),
					Vector2(arte.position.x + arte.size.x * (0.60 + float(i % 2) * 0.18), arte.position.y + arte.size.y * (0.55 + float(i) * 0.12)),
					_a(Color("#7c2d12"), 0.55), 1.0, true)
		"reloj":
			c.draw_rect(arte, Color("#f1f5f9"))
			var rc := arte.get_center()
			var rr := minf(arte.size.x, arte.size.y) * 0.40
			c.draw_circle(rc, rr, Color.WHITE, true, -1.0, true)
			c.draw_arc(rc, rr, 0.0, TAU, 24, Color("#334155"), 1.8, true)
			for i in range(12):
				var ang := TAU * float(i) / 12.0
				c.draw_line(rc + Vector2(cos(ang), sin(ang)) * rr * 0.78,
					rc + Vector2(cos(ang), sin(ang)) * rr * 0.90, _a(Color("#64748b"), 0.8), 1.0, true)
			c.draw_line(rc, rc + Vector2(0.0, -rr * 0.55), Color("#111827"), 1.6, true)
			c.draw_line(rc, rc + Vector2(rr * 0.42, rr * 0.18), Color("#dc2626"), 1.4, true)
			c.draw_circle(rc, 1.7, Color("#111827"), true, -1.0, true)
		_:
			c.draw_rect(arte, Color("#fff7ed"))
			c.draw_circle(arte.get_center(), minf(arte.size.x, arte.size.y) * 0.28,
				_a(col_marco, 0.60), true, -1.0, true)
	if tipo != "estrellas":
		# Reflejo de cristal.
		c.draw_colored_polygon(PackedVector2Array([
			arte.position + Vector2(arte.size.x * 0.08, 0.0),
			arte.position + Vector2(arte.size.x * 0.30, 0.0),
			arte.position + Vector2(arte.size.x * 0.06, arte.size.y),
			arte.position,
		]), Color(1.0, 1.0, 1.0, 0.10))
	c.draw_rect(rect, col_marco.darkened(0.42), false, 1.4)
	c.draw_rect(interior, Color(0.0, 0.0, 0.0, 0.12), false, 1.0)


static func _estante_libros(c: CanvasItem, rect: Rect2, semilla: float = 0.0,
		col_estante: Color = Color("#92400e")) -> void:
	c.draw_rect(rect, Color("#3f2412"))
	for est in range(3):
		var y_base := rect.position.y + rect.size.y * (0.30 + float(est) * 0.30)
		c.draw_rect(Rect2(rect.position.x, y_base, rect.size.x, maxf(2.0, rect.size.y * 0.05)), col_estante)
		c.draw_line(Vector2(rect.position.x, y_base), Vector2(rect.end.x, y_base), col_estante.lightened(0.22), 1.0)
		var x := rect.position.x + 5.0
		var idx := 0
		while x < rect.end.x - 7.0:
			var alto := rect.size.y * (0.14 + 0.055 * float((idx + est * 3) % 5))
			var ancho := maxf(3.4, rect.size.x * (0.035 + 0.010 * float((idx + est) % 3)))
			var col: Color = PALETA_LIBROS[(idx + est * 4 + int(semilla)) % PALETA_LIBROS.size()]
			c.draw_rect(Rect2(x, y_base - alto, ancho, alto), col)
			c.draw_rect(Rect2(x, y_base - alto, ancho, alto), col.darkened(0.35), false, 1.0)
			c.draw_rect(Rect2(x + 1.0, y_base - alto + 2.0, maxf(1.0, ancho * 0.22), alto - 4.0),
				_a(Color.WHITE, 0.22))
			if idx % 5 == 4:
				x += ancho + 7.0
			else:
				x += ancho + 1.4
			idx += 1
	c.draw_rect(rect, Color("#2a170b"), false, 1.2)
	c.draw_rect(Rect2(rect.position.x - 2.0, rect.position.y - 3.0, rect.size.x + 4.0, 4.0),
		col_estante.lightened(0.12))


static func _lampara_colgante(c: CanvasItem, x: float, y: float, alto: float, pantalla: Color,
		t: float = 0.0, calida: bool = true) -> void:
	var y_pantalla := y + alto
	c.draw_line(Vector2(x, y), Vector2(x, y_pantalla), Color("#334155"), 1.6, true)
	var pulso := 1.0 + sin(t * 6.0) * 0.03
	var halo := _a(Color("#fde68a") if calida else Color("#bae6fd"), 0.14)
	c.draw_circle(Vector2(x, y_pantalla + 6.0), 26.0 * pulso, halo, true, -1.0, true)
	c.draw_circle(Vector2(x, y_pantalla + 6.0), 14.0 * pulso, _a(Color("#fde68a") if calida else Color("#bae6fd"), 0.20), true, -1.0, true)
	var shade := PackedVector2Array([
		Vector2(x - 13.0, y_pantalla), Vector2(x + 13.0, y_pantalla),
		Vector2(x + 7.0, y_pantalla + 8.0), Vector2(x - 7.0, y_pantalla + 8.0),
	])
	c.draw_colored_polygon(shade, pantalla)
	c.draw_polyline(PackedVector2Array([shade[0], shade[1], shade[2], shade[3], shade[0]]),
		pantalla.darkened(0.45), 1.2, true)
	c.draw_rect(Rect2(x - 8.0, y_pantalla + 7.0, 16.0, 2.4), Color("#fef08a"))


static func _planta(c: CanvasItem, base: Vector2, alto: float, t: float,
		tono: String = "verde", semilla: float = 0.0) -> void:
	var col_hoja := Color("#54a447")
	var col_hoja_osc := Color("#337636")
	var col_brillo := Color("#91cf70")
	var col_maceta := Color("#b96a3d")
	if tono == "tropical":
		col_hoja = Color("#2f8f5b")
		col_hoja_osc = Color("#1f6a42")
		col_brillo = Color("#6cc98b")
	elif tono == "oliva":
		col_hoja = Color("#7d9a45")
		col_hoja_osc = Color("#5b7131")
		col_brillo = Color("#a9c46a")
	elif tono == "otoño":
		col_hoja = Color("#d97706")
		col_hoja_osc = Color("#9a3412")
		col_brillo = Color("#fbbf24")
	elif tono == "seca":
		col_hoja = Color("#a8a29e")
		col_hoja_osc = Color("#78716c")
		col_brillo = Color("#d6d3d1")
	var alto_maceta := alto * 0.20
	var ancho_maceta := alto * 0.26
	var cima := base.y - alto_maceta
	var y_hojas := cima - alto * 0.02
	_sombra(c, base + Vector2(2.0, 1.0), ancho_maceta * 0.62, maxf(2.0, alto * 0.045), 0.16)
	# Tallos.
	for i in range(3):
		var ang := -0.38 + float(i) * 0.36 + semilla * 0.05
		var fin := Vector2(base.x + sin(ang) * alto * 0.30, y_hojas - alto * 0.38)
		c.draw_line(Vector2(base.x, cima), fin, col_hoja_osc.darkened(0.15), maxf(1.3, alto * 0.018), true)
	# Hojas traseras y delanteras.
	var hojas: Array = [
		[-1.30, 0.34, 0.24, 0.0], [1.25, 0.34, 0.24, 0.6],
		[-1.55, 0.30, 0.20, 1.2], [1.52, 0.30, 0.20, 1.8],
		[-0.68, 0.45, 0.27, 0.3], [0.62, 0.45, 0.27, 0.9],
		[0.02, 0.50, 0.29, 1.5], [-1.02, 0.38, 0.23, 2.1],
		[0.98, 0.38, 0.23, 2.6], [-0.32, 0.30, 0.19, 3.1],
	]
	for i in range(hojas.size()):
		var h: Array = hojas[i]
		var base_h := Vector2(base.x + sin(float(h[0])) * alto * 0.10, y_hojas - alto * 0.20)
		var col_r := col_hoja if i >= 4 else col_hoja_osc
		var col_b := col_brillo if i >= 4 else col_hoja_osc
		_hoja(c, base_h, float(h[0]), alto * float(h[1]), alto * float(h[2]),
			col_r, col_hoja_osc, col_b, t, float(h[3]) + semilla)
	# Maceta de terracota.
	var ancho_base := ancho_maceta * 0.76
	var maceta := PackedVector2Array([
		Vector2(base.x - ancho_maceta * 0.5, cima),
		Vector2(base.x + ancho_maceta * 0.5, cima),
		Vector2(base.x + ancho_base * 0.5, base.y),
		Vector2(base.x - ancho_base * 0.5, base.y),
	])
	c.draw_colored_polygon(maceta, col_maceta)
	c.draw_colored_polygon(PackedVector2Array([
		Vector2(base.x, cima), Vector2(base.x + ancho_maceta * 0.5, cima),
		Vector2(base.x + ancho_base * 0.5, base.y), Vector2(base.x, base.y),
	]), col_maceta.darkened(0.18))
	var mcerr := PackedVector2Array(maceta)
	mcerr.append(maceta[0])
	c.draw_polyline(mcerr, col_maceta.darkened(0.55), 1.4, true)
	var labio := Rect2(base.x - ancho_maceta * 0.56, cima - maxf(3.0, alto * 0.035),
		ancho_maceta * 1.12, maxf(3.5, alto * 0.045))
	c.draw_rect(labio, col_maceta.lightened(0.15))
	c.draw_rect(labio, col_maceta.darkened(0.50), false, 1.2)
	c.draw_rect(Rect2(base.x - ancho_maceta * 0.40, cima + 1.0, ancho_maceta * 0.80,
		maxf(2.0, alto * 0.025)), Color("#4a2a16"))


static func _hoja(c: CanvasItem, base: Vector2, angulo: float, largo: float, ancho: float,
		relleno: Color, borde: Color, brillo: Color, t: float, fase: float) -> void:
	var vaiven := sin(t * 0.85 + fase) * 0.035
	var a := angulo + vaiven
	var dir := Vector2(sin(a), -cos(a))
	var perp := Vector2(cos(a), sin(a))
	var curva := largo * 0.10
	var pts := PackedVector2Array()
	var segmentos := 8
	for i in range(segmentos + 1):
		var u := float(i) / float(segmentos)
		var semi := sin(u * PI) * ancho * 0.5 * (1.0 - 0.18 * u)
		pts.append(base + dir * (u * largo) + perp * (semi + sin(u * PI) * curva))
	for i in range(segmentos, -1, -1):
		var u := float(i) / float(segmentos)
		var semi := sin(u * PI) * ancho * 0.5 * (1.0 - 0.18 * u)
		pts.append(base + dir * (u * largo) - perp * (semi - sin(u * PI) * curva))
	c.draw_colored_polygon(pts, relleno)
	var cerrado := PackedVector2Array(pts)
	cerrado.append(pts[0])
	c.draw_polyline(cerrado, borde, 1.1, true)
	var punta := base + dir * (largo * 0.90)
	c.draw_line(base + dir * (largo * 0.04), punta, _a(brillo, 0.72), 1.0, true)
	c.draw_line(base + dir * (largo * 0.24), base + dir * (largo * 0.55) + perp * (ancho * 0.22),
		_a(brillo, 0.35), 0.9, true)
	c.draw_line(base + dir * (largo * 0.24), base + dir * (largo * 0.55) - perp * (ancho * 0.22),
		_a(brillo, 0.35), 0.9, true)


static func _arbol(c: CanvasItem, base: Vector2, escala: float, col_hoja: Color,
		col_tronco: Color, t: float, fase: float) -> void:
	var alto := 58.0 * escala
	_sombra(c, base + Vector2(2.0, 0.0), 22.0 * escala, 5.0 * escala, 0.14)
	c.draw_rect(Rect2(base.x - 4.0 * escala, base.y - alto * 0.62, 8.0 * escala, alto * 0.62), col_tronco)
	c.draw_rect(Rect2(base.x - 4.0 * escala, base.y - alto * 0.62, 3.0 * escala, alto * 0.62),
		col_tronco.lightened(0.18))
	c.draw_line(Vector2(base.x, base.y - alto * 0.40), Vector2(base.x - 12.0 * escala, base.y - alto * 0.62),
		col_tronco, 2.8 * escala, true)
	c.draw_line(Vector2(base.x, base.y - alto * 0.46), Vector2(base.x + 12.0 * escala, base.y - alto * 0.68),
		col_tronco, 2.6 * escala, true)
	var vaiv := sin(t * 0.7 + fase) * 1.2
	var centro := Vector2(base.x + vaiv, base.y - alto * 0.78)
	c.draw_circle(centro + Vector2(-14.0, 4.0) * escala, 15.0 * escala, col_hoja, true, -1.0, true)
	c.draw_circle(centro + Vector2(14.0, 5.0) * escala, 14.0 * escala, col_hoja, true, -1.0, true)
	c.draw_circle(centro + Vector2(0.0, -8.0) * escala, 18.0 * escala, col_hoja.lightened(0.06), true, -1.0, true)
	c.draw_circle(centro + Vector2(-5.0, -14.0) * escala, 9.0 * escala, col_hoja.lightened(0.16), true, -1.0, true)
	c.draw_arc(centro, 19.0 * escala, PI * 0.9, PI * 1.9, 12, _a(col_hoja.darkened(0.40), 0.55), 1.2, true)


# ---------------------------------------------------------------- tiempo libre en la calle

static func dibujar_calle_idle(c: CanvasItem, esc, w: float, h: float) -> void:
	var t: float = esc._t
	var franja: String = esc._franja_horaria()
	var noche := franja == "noche"
	var atardecer := franja == "atardecer"
	var cielo_a := Color("#6ec5f2")
	var cielo_b := Color("#e3f5fe")
	if atardecer:
		cielo_a = Color("#f97316")
		cielo_b = Color("#fde68a")
	elif noche:
		cielo_a = Color("#111a3a")
		cielo_b = Color("#3b3f7a")
	_grad_v(c, Rect2(0.0, 0.0, w, h * 0.64), cielo_a, cielo_b, 14)
	# Sol / luna.
	var astro := Vector2(w * 0.78, h * 0.16)
	if noche:
		c.draw_circle(astro, 28.0, _a(Color("#fef3c7"), 0.08), true, -1.0, true)
		c.draw_circle(astro, 12.0, Color("#fef3c7"), true, -1.0, true)
		c.draw_circle(astro + Vector2(4.0, -3.0), 10.0, Color("#1a2450"), true, -1.0, true)
		for i in range(8):
			var px := w * fmod(0.06 + float(i) * 0.121, 1.0)
			var py := h * fmod(0.07 + float(i) * 0.054, 0.40)
			var br := 0.45 + sin(t * 2.4 + float(i) * 1.7) * 0.35
			c.draw_circle(Vector2(px, py), 1.4, Color(1.0, 0.97, 0.80, br), true, -1.0, true)
	else:
		var col_sol := Color("#fdba74") if atardecer else Color("#fde047")
		c.draw_circle(astro, 30.0, _a(col_sol, 0.10), true, -1.0, true)
		c.draw_circle(astro, 12.0, col_sol, true, -1.0, true)
		c.draw_circle(astro, 12.0, _a(Color("#f59e0b"), 0.50), false, 1.2)
	# Nubes.
	if not noche:
		for i in range(3):
			var nx := w * (0.16 + float(i) * 0.27) + sin(t * 0.28 + float(i) * 1.7) * 7.0
			var ny := h * (0.10 + 0.045 * float(i % 2))
			_nube(c, Vector2(nx, ny), 15.0 - float(i) * 2.0, 0.72 if not atardecer else 0.55)
	# Skyline lejano.
	var x_edif := 0.0
	var idx := 0
	var col_edif := Color("#8ea6ba") if not noche else Color("#2c3357")
	while x_edif < w:
		var ancho := 30.0 + float((idx * 31) % 48)
		var alto := h * (0.13 + float((idx * 13) % 15) * 0.008)
		var y0 := h * 0.58 - alto
		c.draw_rect(Rect2(x_edif, y0, ancho, alto), col_edif)
		c.draw_rect(Rect2(x_edif, y0, ancho, alto), col_edif.darkened(0.20), false, 0.8)
		for vy in range(2):
			for vx in range(2):
				if (idx + vy + vx) % 2 == 0:
					c.draw_rect(Rect2(x_edif + 6.0 + float(vx) * 12.0, y0 + 6.0 + float(vy) * 10.0, 3.0, 4.0),
						Color("#fde68a", 0.45) if noche or atardecer else Color("#dbeafe", 0.45))
		x_edif += ancho + 6.0
		idx += 1
	# Edificio con cafetería a la izquierda.
	var edif_izq := Rect2(0.0, h * 0.20, w * 0.21, h * 0.42)
	c.draw_rect(edif_izq, Color("#92400e") if not noche else Color("#3b2a22"))
	c.draw_rect(edif_izq, Color("#5c2d16"), false, 1.6)
	for i in range(2):
		var wx := w * 0.030 + float(i) * w * 0.085
		var wy := h * (0.27 + float(i) * 0.13)
		var win := Rect2(wx, wy, w * 0.065, h * 0.09)
		c.draw_rect(win, Color("#fef3c7") if (noche or atardecer) else Color("#bae6fd"))
		c.draw_rect(win, Color("#f59e0b") if (noche or atardecer) else Color("#7dd3fc"), false, 1.4)
		c.draw_line(Vector2(win.get_center().x, win.position.y), Vector2(win.get_center().x, win.end.y),
			Color("#78350f"), 1.0)
	# Toldo de la cafetería.
	var awning_y := h * 0.60
	for i in range(5):
		c.draw_rect(Rect2(w * 0.012 + float(i) * w * 0.040, awning_y, w * 0.040, h * 0.035),
			Color("#ef4444") if i % 2 == 0 else Color("#f8fafc"))
	c.draw_line(Vector2(w * 0.005, awning_y), Vector2(w * 0.215, awning_y), Color("#7f1d1d"), 1.4)
	c.draw_string(FUENTE_COMIC, Vector2(w * 0.055, h * 0.245), "CAFÉ", HORIZONTAL_ALIGNMENT_LEFT, -1,
		int(maxf(10.0, h * 0.055)), Color("#fef3c7"))
	# Edificio con balcones a la derecha.
	var edif_der := Rect2(w * 0.80, h * 0.18, w * 0.20, h * 0.44)
	c.draw_rect(edif_der, Color("#cbd5e1") if not noche else Color("#2c3357"))
	c.draw_rect(edif_der, Color("#64748b") if not noche else Color("#1e293b"), false, 1.6)
	for i in range(3):
		var wx2 := w * 0.825 + float(i % 2) * w * 0.075
		var wy2 := h * (0.24 + float(i / 2) * 0.14)
		c.draw_rect(Rect2(wx2, wy2, w * 0.045, h * 0.075),
			Color("#fde68a") if (noche or atardecer) else Color("#dbeafe"))
		c.draw_rect(Rect2(wx2, wy2, w * 0.045, h * 0.075), Color("#475569"), false, 1.0)
		c.draw_rect(Rect2(wx2 - 3.0, wy2 + h * 0.075, w * 0.052, 3.0), Color("#475569"))
	# Árboles y banco del parque.
	_arbol(c, Vector2(w * 0.24, h * 0.70), 1.2, Color("#3f9a55") if not noche else Color("#24413a"),
		Color("#7a4a24") if not noche else Color("#3f2a18"), t, 0.8)
	_arbol(c, Vector2(w * 0.76, h * 0.70), 1.1, Color("#3e9444") if not noche else Color("#264a3c"),
		Color("#71431f") if not noche else Color("#382513"), t, 2.1)
	var bx := w * 0.32
	var by := h * 0.635
	for i in range(2):
		c.draw_rect(Rect2(bx, by + float(i) * h * 0.042, w * 0.36, maxf(3.2, h * 0.020)),
			Color("#8a5a32") if not noche else Color("#4d3019"))
		c.draw_line(Vector2(bx, by + float(i) * h * 0.042),
			Vector2(bx + w * 0.36, by + float(i) * h * 0.042),
			Color("#5c3a1e") if not noche else Color("#2b180c"), 1.0)
	for px in [bx + 6.0, bx + w * 0.36 - 7.0]:
		c.draw_rect(Rect2(px, by + h * 0.078, maxf(2.6, w * 0.008), h * 0.075),
			Color("#5c3a1e") if not noche else Color("#2b180c"))
	# Farolas con guirnalda.
	for lado in [0, 1]:
		var lx := w * (0.075 if lado == 0 else 0.935)
		c.draw_line(Vector2(lx, h * 0.72), Vector2(lx, h * 0.25), Color("#3f4b57"), 2.6)
		c.draw_line(Vector2(lx, h * 0.25), Vector2(lx + (13.0 if lado == 0 else -13.0), h * 0.25),
			Color("#3f4b57"), 1.8)
		var foco := Vector2(lx + (13.0 if lado == 0 else -13.0), h * 0.265)
		c.draw_circle(foco, 4.0, Color("#fef08a"), true, -1.0, true)
		if noche or atardecer:
			c.draw_circle(foco, 18.0, _a(Color("#fef08a"), 0.13), true, -1.0, true)
	if noche or atardecer:
		var x0 := w * 0.088
		var x1 := w * 0.922
		for i in range(11):
			var u := float(i) / 10.0
			var px := lerpf(x0, x1, u)
			var py := h * 0.265 + sin(u * PI) * h * 0.075
			if i > 0:
				var u_prev := float(i - 1) / 10.0
				c.draw_line(Vector2(lerpf(x0, x1, u_prev), h * 0.265 + sin(u_prev * PI) * h * 0.075),
					Vector2(px, py), Color("#3f4b57", 0.65), 1.0, true)
			c.draw_circle(Vector2(px, py + 3.0), 1.8,
				Color(1.0, 0.90, 0.55, 0.75 + sin(t * 2.0 + float(i)) * 0.20), true, -1.0, true)
	# Suelo de plaza con camino de piedra.
	_grad_v(c, Rect2(0.0, h * 0.66, w, h * 0.34), Color("#86efac") if not noche else Color("#1e3a33"),
		Color("#4ade80") if not noche else Color("#162c29"), 8)
	var camino := PackedVector2Array([
		Vector2(w * 0.06, h * 0.72), Vector2(w * 0.94, h * 0.72),
		Vector2(w * 1.02, h), Vector2(-w * 0.02, h),
	])
	c.draw_colored_polygon(camino, Color("#d6c3a5") if not noche else Color("#4b4a5e"))
	for i in range(5):
		var ty := h * (0.75 + float(i) * 0.05)
		c.draw_line(Vector2(w * 0.04, ty), Vector2(w * 0.96, ty), _a(Color("#b7a98b"), 0.35), 1.0)
	for i in range(7):
		var tx := w * (0.10 + float(i) * 0.13)
		c.draw_line(Vector2(tx, h * 0.72), Vector2(tx - 14.0, h), _a(Color("#b7a98b"), 0.22), 1.0)
	c.draw_line(Vector2(0.0, h * 0.72), Vector2(w, h * 0.72), _a(TINTA, 0.25), 1.2)
	# Bancos laterales y macetas.
	for lado in [0, 1]:
		var px := w * (0.02 if lado == 0 else 0.93)
		c.draw_rect(Rect2(px, h * 0.80, w * 0.055, h * 0.07), Color("#b96a3d"))
		c.draw_rect(Rect2(px - 2.0, h * 0.79, w * 0.061, 3.0), Color("#c97d4d"))
		_planta(c, Vector2(px + w * 0.027, h * 0.79), h * 0.16, t, "verde", 0.4)
	# Palomas picoteando.
	for i in range(2):
		var px2 := w * (0.17 + float(i) * 0.46) + sin(t * 1.8 + float(i) * 2.2) * 5.0
		var py2 := h * 0.935 + cos(t * 6.0 + float(i)) * 2.0
		c.draw_circle(Vector2(px2, py2), 5.0, Color("#94a3b8") if not noche else Color("#64748b"), true, -1.0, true)
		c.draw_circle(Vector2(px2 + 4.0, py2 - 3.0), 2.6, Color("#cbd5e1") if not noche else Color("#94a3b8"), true, -1.0, true)
		c.draw_line(Vector2(px2 + 6.0, py2 - 3.0), Vector2(px2 + 9.0, py2 - 2.0), Color("#f59e0b"), 1.4, true)
		c.draw_line(Vector2(px2 - 4.0, py2 + 5.0), Vector2(px2 - 4.0, py2 + 8.0), Color("#f59e0b"), 1.2, true)
		c.draw_line(Vector2(px2 + 2.0, py2 + 5.0), Vector2(px2 + 2.0, py2 + 8.0), Color("#f59e0b"), 1.2, true)
	# Flores y briznas.
	for i in range(8):
		var fx := w * fmod(0.02 + float(i) * 0.121, 1.0)
		var fy := h * (0.90 + 0.03 * float(i % 3))
		c.draw_line(Vector2(fx, fy), Vector2(fx - 2.0, fy - 5.0),
			Color("#15803d") if not noche else Color("#1f4d3c"), 1.0)
		if i % 3 == 0:
			c.draw_circle(Vector2(fx - 2.0, fy - 6.0), 1.7,
				Color("#fde047") if not noche else Color("#fbbf24"), true, -1.0, true)
	# Luciérnagas y polvo.
	if noche or atardecer:
		for i in range(4):
			var px3 := w * (0.12 + float(i) * 0.22) + sin(t * 0.8 + float(i) * 1.5) * 9.0
			var py3 := h * (0.58 + 0.08 * float(i % 3)) + cos(t * 0.7 + float(i)) * 6.0
			var pulso := 0.35 + (sin(t * 2.5 + float(i) * 1.9) + 1.0) * 0.30
			c.draw_circle(Vector2(px3, py3), 1.8, Color(0.98, 0.88, 0.35, pulso), true, -1.0, true)
	_motas(c, Rect2(w * 0.10, h * 0.10, w * 0.80, h * 0.55), t, 4, _a(Color.WHITE, 0.22), 0.4)


# ---------------------------------------------------------------- correr

static func _correr(c: CanvasItem, esc, w: float, h: float, t: float, v: String) -> void:
	var franja: String = esc._franja_horaria()
	var noche := franja == "noche"
	var atardecer := franja == "atardecer"
	var vel: float = 165.0 if v == "sprint" else 88.0
	var horizonte := h * 0.70
	# Cielo con degradado.
	if noche:
		_grad_v(c, Rect2(0.0, 0.0, w, horizonte), Color("#101a3a"), Color("#3a3f78"), 16)
	elif atardecer:
		_grad_v(c, Rect2(0.0, 0.0, w, horizonte), Color("#f97316"), Color("#fde68a"), 16)
	else:
		_grad_v(c, Rect2(0.0, 0.0, w, horizonte), Color("#6ec5f2"), Color("#e3f5fe"), 16)
	# Sol o luna con halos.
	var astro := Vector2(w * 0.82, h * 0.17)
	if noche:
		c.draw_circle(astro, 30.0, _a(Color("#fef3c7"), 0.08), true, -1.0, true)
		c.draw_circle(astro, 18.0, _a(Color("#fef3c7"), 0.14), true, -1.0, true)
		c.draw_circle(astro, 10.0, Color("#fef3c7"), true, -1.0, true)
		c.draw_circle(astro + Vector2(4.0, -3.0), 9.0, Color("#1a2450"), true, -1.0, true)
		for i in range(7):
			var px := w * fmod(0.06 + float(i) * 0.131, 1.0)
			var py := h * fmod(0.06 + float(i) * 0.053, 0.45)
			var br := 0.45 + sin(t * 2.6 + float(i) * 1.9) * 0.35
			c.draw_circle(Vector2(px, py), 1.5, Color(1.0, 0.97, 0.80, br), true, -1.0, true)
	else:
		var col_sol := Color("#fdba74") if atardecer else Color("#fde047")
		c.draw_circle(astro, 34.0, _a(col_sol, 0.10), true, -1.0, true)
		c.draw_circle(astro, 22.0, _a(col_sol, 0.16), true, -1.0, true)
		c.draw_circle(astro, 12.0, col_sol, true, -1.0, true)
		c.draw_circle(astro, 12.0, _a(Color("#f59e0b"), 0.55), false, 1.2)
	# Nubes con parallax.
	if not noche:
		for i in range(4):
			var ciclo := fmod(t * (vel * 0.16 + 7.0) + float(i) * 190.0, w + 260.0)
			var nx := w + 130.0 - ciclo
			var ny := h * (0.09 + 0.055 * float(i % 3))
			var esc_n := 0.75 + float(i % 3) * 0.20
			_nube(c, Vector2(nx, ny), 16.0 * esc_n, 0.82 if not atardecer else 0.60)
	# Pájaros.
	if not noche:
		for i in range(3):
			var bx := fmod(t * (18.0 + float(i) * 3.0) + float(i) * 64.0, w + 90.0) - 45.0
			var by := h * (0.11 + float(i) * 0.045) + sin(t * 1.8 + float(i)) * 3.0
			_pajaro(c, Vector2(bx, by), 4.2, _a(TINTA, 0.38))
	# Colinas lejanas.
	var col_hill_a := Color("#c7e9c0") if not noche else Color("#22305a")
	var col_hill_b := Color("#8ed49a") if not noche else Color("#1b2848")
	var pts_a := PackedVector2Array()
	var pts_b := PackedVector2Array()
	pts_a.append(Vector2(0.0, horizonte))
	pts_b.append(Vector2(0.0, horizonte))
	for i in range(15):
		var u := float(i) / 14.0
		pts_a.append(Vector2(w * u, horizonte - h * 0.075 - sin(u * 7.4 + 1.2) * h * 0.030))
		pts_b.append(Vector2(w * u, horizonte - h * 0.028 - sin(u * 5.6 + 2.3) * h * 0.022))
	pts_a.append(Vector2(w, horizonte))
	pts_b.append(Vector2(w, horizonte))
	c.draw_colored_polygon(pts_a, col_hill_a)
	c.draw_colored_polygon(pts_b, col_hill_b)
	# Arboleda lejana en parallax.
	for i in range(6):
		var tx := fmod(float(i) * 158.0 - t * vel * 0.50, w + 220.0) - 110.0
		var escala := 0.65 + float(i % 3) * 0.10
		_arbol(c, Vector2(tx, horizonte + 2.0), escala,
			Color("#3f9a55") if not noche else Color("#24413a"),
			Color("#6b4423") if not noche else Color("#3a2a1c"), t, float(i))
	# Árboles cercanos en los laterales.
	_arbol(c, Vector2(w * 0.09, h * 0.79), 1.35, Color("#43a047") if not noche else Color("#2a5040"),
		Color("#7a4a24") if not noche else Color("#3f2a18"), t, 1.2)
	_arbol(c, Vector2(w * 0.93, h * 0.78), 1.25, Color("#3e9444") if not noche else Color("#264a3c"),
		Color("#71431f") if not noche else Color("#382513"), t, 2.4)
	# Césped.
	_grad_v(c, Rect2(0.0, horizonte, w, h - horizonte), Color("#7ed08a") if not noche else Color("#24463a"),
		Color("#3f9a55") if not noche else Color("#182f2b"), 10)
	# Camino asfaltado con bordes y líneas.
	var y_camino := h * 0.765
	var y_fin := h * 0.935
	c.draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, y_camino), Vector2(w, y_camino), Vector2(w, y_fin), Vector2(0.0, y_fin),
	]), Color("#64748b") if not noche else Color("#333a4d"))
	_grad_v(c, Rect2(0.0, y_camino, w, maxf(3.0, h * 0.022)), Color("#94a3b8") if not noche else Color("#4b546b"),
		Color("#64748b") if not noche else Color("#333a4d"), 4)
	c.draw_line(Vector2(0.0, y_camino), Vector2(w, y_camino), _a(TINTA, 0.42), 1.4)
	c.draw_line(Vector2(0.0, y_fin), Vector2(w, y_fin), _a(TINTA, 0.35), 1.2)
	var off := fmod(t * vel * 1.30, 54.0)
	var x := -off
	while x < w + 40.0:
		c.draw_rect(Rect2(x, h * 0.845, 26.0, 3.4), Color("#e2e8f0") if not noche else Color("#8b93a7"))
		x += 54.0
	# Farola del parque.
	var lx := w * 0.055
	c.draw_line(Vector2(lx, h * 0.77), Vector2(lx, h * 0.34), Color("#334155"), 2.6)
	c.draw_line(Vector2(lx, h * 0.34), Vector2(lx + 13.0, h * 0.34), Color("#334155"), 1.8)
	c.draw_circle(Vector2(lx + 13.0, h * 0.355), 4.0, Color("#fef08a"), true, -1.0, true)
	if atardecer or noche:
		c.draw_circle(Vector2(lx + 13.0, h * 0.355), 16.0, _a(Color("#fef08a"), 0.14), true, -1.0, true)
	# Banco lateral.
	var bx := w * 0.90
	c.draw_rect(Rect2(bx, h * 0.72, w * 0.09, maxf(3.0, h * 0.018)), Color("#8a5a32"))
	c.draw_rect(Rect2(bx, h * 0.75, w * 0.09, maxf(3.0, h * 0.018)), Color("#8a5a32"))
	c.draw_rect(Rect2(bx + 4.0, h * 0.735, 2.4, h * 0.06), Color("#5c3a1e"))
	c.draw_rect(Rect2(bx + w * 0.09 - 7.0, h * 0.735, 2.4, h * 0.06), Color("#5c3a1e"))
	# Flores y briznas en primer plano.
	for i in range(10):
		var fx := w * fmod(0.02 + float(i) * 0.109, 1.0)
		var fy := h * (0.90 + 0.045 * float(i % 3))
		c.draw_line(Vector2(fx, fy), Vector2(fx - 2.0, fy - 5.0), Color("#15803d") if not noche else Color("#1f4d3c"), 1.0)
		if i % 3 == 0:
			c.draw_circle(Vector2(fx - 2.0, fy - 6.0), 1.6, Color("#fde047") if not noche else Color("#fbbf24"), true, -1.0, true)
	# Luciérnagas al atardecer o de noche.
	if atardecer or noche:
		for i in range(5):
			var px := w * (0.15 + 0.17 * float(i)) + sin(t * 0.8 + float(i) * 1.4) * 9.0
			var py := h * (0.58 + 0.10 * float(i % 3)) + cos(t * 0.7 + float(i)) * 6.0
			var pulso := 0.35 + (sin(t * 2.4 + float(i) * 1.9) + 1.0) * 0.30
			c.draw_circle(Vector2(px, py), 1.8, Color(0.98, 0.88, 0.35, pulso), true, -1.0, true)


# ---------------------------------------------------------------- dormir

static func _dormir(c: CanvasItem, esc, w: float, h: float, t: float, _v: String) -> void:
	var cx := w * 0.5
	# Habitación nocturna con degradado y foco de luna.
	_grad_v(c, Rect2(0.0, 0.0, w, h), Color("#1d2448"), Color("#0d1326"), 18)
	c.draw_circle(Vector2(w * 0.20, h * 0.18), h * 0.60, _a(Color("#93c5fd"), 0.035), true, -1.0, true)
	c.draw_circle(Vector2(w * 0.20, h * 0.18), h * 0.36, _a(Color("#93c5fd"), 0.05), true, -1.0, true)
	# Ventana con luna, estrellas y skyline.
	var lado := clampf(h * 0.36, 58.0, 88.0)
	var win := Rect2(w * 0.05, h * 0.085, lado, lado * 0.86)
	_ventana(c, win, "noche", t, true, Color("#4338ca"))
	# Haz de luna que entra por la ventana.
	var y_sal := win.position.y + win.size.y * 0.55
	_haz(c, PackedVector2Array([
		Vector2(win.position.x + 8.0, y_sal),
		Vector2(win.end.x - 4.0, y_sal),
		Vector2(w * 0.46, h * 0.92),
		Vector2(w * 0.10, h * 0.92),
	]), _a(Color("#bfdbfe"), 0.055))
	# Cuadro de constelaciones a la izquierda de la cama.
	_cuadro(c, Rect2(w * 0.055, h * 0.50, w * 0.105, h * 0.25), "estrellas", t, 0.2, Color("#475569"))
	# Guirnalda de luces cálidas en la pared derecha.
	var x0 := w * 0.62
	var x1 := w * 0.97
	var y_guir := h * 0.075
	for i in range(9):
		var u := float(i) / 8.0
		var px := lerpf(x0, x1, u)
		var py := y_guir + sin(u * PI) * 10.0
		if i > 0:
			var u_prev := float(i - 1) / 8.0
			var px_prev := lerpf(x0, x1, u_prev)
			var py_prev := y_guir + sin(u_prev * PI) * 10.0
			c.draw_line(Vector2(px_prev, py_prev), Vector2(px, py), Color("#3b4266"), 1.0, true)
		var pulso := 0.65 + sin(t * 2.2 + float(i) * 0.9) * 0.30
		c.draw_circle(Vector2(px, py + 4.0), 5.0, _a(Color("#fde68a"), 0.12 * pulso), true, -1.0, true)
		c.draw_circle(Vector2(px, py + 4.0), 1.7, Color(1.0, 0.90, 0.55, pulso), true, -1.0, true)
	# Cabecero de madera con paneles y moldura.
	var ancho_cab := clampf(w * 0.42, 210.0, 270.0)
	var y_cab := h * 0.43
	var cab := Rect2(cx - ancho_cab * 0.5, y_cab, ancho_cab, h - y_cab + 2.0)
	_madera(c, cab, Color("#6b3f1d"), false, 1.3)
	c.draw_rect(cab, Color("#3f2410"), false, 2.0)
	var n_paneles := 3
	for i in range(n_paneles):
		var pw := ancho_cab / float(n_paneles)
		var panel := Rect2(cab.position.x + pw * float(i) + 7.0, y_cab + 14.0, pw - 14.0,
			h - y_cab - 26.0)
		c.draw_rect(panel, Color("#7b4a24"))
		c.draw_rect(panel, Color("#4a2a12"), false, 1.4)
		c.draw_line(Vector2(panel.position.x + 2.0, panel.position.y + 2.0),
			Vector2(panel.end.x - 2.0, panel.position.y + 2.0), _a(Color("#d6a26b"), 0.35), 1.2)
	c.draw_rect(Rect2(cab.position.x - 5.0, y_cab - 7.0, cab.size.x + 10.0, 9.0), Color("#8a5528"))
	c.draw_rect(Rect2(cab.position.x - 5.0, y_cab - 7.0, cab.size.x + 10.0, 9.0), Color("#4a2a12"), false, 1.6)
	c.draw_line(Vector2(cab.position.x - 2.0, y_cab - 3.0), Vector2(cab.end.x + 2.0, y_cab - 3.0),
		_a(Color("#f0c58f"), 0.55), 1.4)
	# Almohada mullida.
	var alm := Rect2(cx - ancho_cab * 0.30, h * 0.465, ancho_cab * 0.60, h * 0.18)
	_panel_borde(c, alm, 12.0, Color("#eef2ff"), Color("#94a3b8"), 1.6)
	c.draw_rect(Rect2(alm.position.x + 8.0, alm.position.y + 5.0, alm.size.x - 16.0, maxf(2.0, alm.size.y * 0.10)),
		_a(Color.WHITE, 0.55))
	c.draw_line(Vector2(alm.position.x + 5.0, alm.end.y - 5.0), Vector2(alm.end.x - 5.0, alm.end.y - 5.0),
		_a(Color("#64748b"), 0.35), 1.2)
	# Cojín de acento a la izquierda de la almohada.
	var alm2 := Rect2(cx - ancho_cab * 0.44, h * 0.50, ancho_cab * 0.20, h * 0.14)
	_panel_borde(c, alm2, 8.0, Color("#0f766e"), Color("#134e4a"), 1.4)
	c.draw_line(Vector2(alm2.position.x + 6.0, alm2.end.y - 6.0),
		Vector2(alm2.end.x - 6.0, alm2.end.y - 6.0), _a(Color("#5eead4"), 0.30), 1.2)
	# Mesilla con lámpara, reloj y libro.
	var nx := w * 0.815
	var ny := h * 0.60
	var nm := Rect2(nx, ny, w * 0.16, h * 0.26)
	_madera(c, Rect2(nm.position.x + 3.0, nm.position.y, nm.size.x, nm.size.y), Color("#5a321d"), true, 2.1)
	c.draw_rect(Rect2(nm.position.x + 7.0, nm.position.y + nm.size.y * 0.42, nm.size.x - 8.0, 2.0),
		Color("#2f190c"))
	c.draw_circle(Vector2(nm.position.x + nm.size.x * 0.55, nm.position.y + nm.size.y * 0.58), 2.6,
		Color("#d4a373"), true, -1.0, true)
	# Lámpara de mesilla con halo cálido.
	var lx := nm.position.x + nm.size.x * 0.60
	var ly := nm.position.y - 2.0
	c.draw_circle(Vector2(lx, ly - 26.0), 28.0, _a(Color("#fde68a"), 0.10 + sin(t * 4.0) * 0.02), true, -1.0, true)
	c.draw_circle(Vector2(lx, ly - 26.0), 14.0, _a(Color("#fde68a"), 0.16), true, -1.0, true)
	c.draw_rect(Rect2(lx - 2.0, ly - 22.0, 4.0, 18.0), Color("#8a5528"))
	var pant := PackedVector2Array([
		Vector2(lx - 13.0, ly - 22.0), Vector2(lx + 13.0, ly - 22.0),
		Vector2(lx + 9.0, ly - 36.0), Vector2(lx - 9.0, ly - 36.0),
	])
	c.draw_colored_polygon(pant, Color("#fef3c7"))
	c.draw_polyline(PackedVector2Array([pant[0], pant[1], pant[2], pant[3], pant[0]]), Color("#b45309"), 1.4, true)
	c.draw_circle(Vector2(lx, ly - 23.0), 3.0, Color("#fde047"), true, -1.0, true)
	# Reloj digital.
	c.draw_rect(Rect2(nx + w * 0.035, ny + 3.0, 24.0, 13.0), Color("#0f172a"))
	c.draw_string(FUENTE_COMIC, Vector2(nx + w * 0.035 + 2.0, ny + 13.0), "23:47",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("#f87171"))
	# Libro apilado.
	c.draw_rect(Rect2(nx + 2.0, ny - 7.0, 24.0, 6.0), Color("#7c3aed"))
	c.draw_rect(Rect2(nx + 2.0, ny - 7.0, 24.0, 6.0), Color("#3b0764"), false, 1.0)
	# Alfombra.
	_panel(c, Rect2(cx - w * 0.30, h * 0.84, w * 0.60, h * 0.16), 8.0, Color("#312e81"))
	c.draw_rect(Rect2(cx - w * 0.29, h * 0.855, w * 0.58, maxf(1.4, h * 0.010)), _a(Color("#818cf8"), 0.35))
	c.draw_rect(Rect2(cx - w * 0.29, h * 0.895, w * 0.58, maxf(1.4, h * 0.010)), _a(Color("#4f46e5"), 0.45))
	# Polvo suspendido en el haz de luna.
	_motas(c, Rect2(w * 0.10, h * 0.10, w * 0.40, h * 0.70), t, 6, _a(Color("#e0e7ff"), 0.35), 0.55)


# ---------------------------------------------------------------- comer

static func _comer(c: CanvasItem, esc, w: float, h: float, t: float, _v: String) -> void:
	var cx := w * 0.5
	var franja: String = esc._franja_horaria()
	if esc._en_la_calle:
		_comer_calle(c, esc, w, h, t, franja)
		return
	var premium: bool = esc._es_mesa_premium()
	var noche := franja == "noche"
	# Pared con degradado suave.
	if premium:
		_grad_v(c, Rect2(0.0, 0.0, w, h * 0.80), Color("#f3ecdf") if not noche else Color("#2f2a3d"),
			Color("#e6d8c3") if not noche else Color("#241f30"), 14)
		# Damasco discreto.
		for i in range(7):
			var px := w * (0.08 + float(i) * 0.145)
			var py := h * 0.20 + sin(float(i) * 1.7) * 8.0
			c.draw_circle(Vector2(px, py), 2.2, _a(Color("#8a5a32"), 0.10), true, -1.0, true)
			c.draw_arc(Vector2(px, py), 5.0, 0.0, TAU, 10, _a(Color("#8a5a32"), 0.08), 1.0, true)
	else:
		_grad_v(c, Rect2(0.0, 0.0, w, h * 0.80), Color("#fdf6e4") if not noche else Color("#3a3350"),
			Color("#f3e4c6") if not noche else Color("#2e2844"), 14)
		# Rayas verticales de papel pintado.
		var sx := 0.0
		while sx < w:
			c.draw_rect(Rect2(sx, 0.0, 7.0, h * 0.64), _a(Color("#d6b98c"), 0.10))
			sx += 26.0
	# Moldura superior.
	var col_madera := Color("#7c4a24") if premium else Color("#b45309")
	c.draw_rect(Rect2(0.0, 0.0, w, h * 0.035), col_madera)
	c.draw_line(Vector2(0.0, h * 0.035), Vector2(w, h * 0.035), _a(Color("#f3d5a5"), 0.45), 1.2)
	c.draw_line(Vector2(0.0, h * 0.055), Vector2(w, h * 0.055), _a(col_madera.darkened(0.35), 0.55), 1.0)
	# Zócalo / arrimadero.
	var y_zocalo := h * 0.605
	if premium:
		c.draw_rect(Rect2(0.0, y_zocalo, w, h * 0.185), Color("#4a2411") if not noche else Color("#24140d"))
		_madera(c, Rect2(0.0, y_zocalo, w, h * 0.185), Color("#5c2d16") if not noche else Color("#2b1810"), true, 0.8)
		c.draw_rect(Rect2(0.0, y_zocalo, w, 3.0), Color("#d97706"))
	else:
		c.draw_rect(Rect2(0.0, y_zocalo, w, h * 0.185), Color("#dcbf92") if not noche else Color("#3a3049"))
		for i in range(9):
			var px := w * (0.05 + float(i) * 0.115)
			c.draw_line(Vector2(px, y_zocalo + 4.0), Vector2(px, y_zocalo + h * 0.165),
				_a(Color("#b69161"), 0.30), 1.2)
		c.draw_rect(Rect2(0.0, y_zocalo, w, 3.0), Color("#c08b4e"))
	# Ventana con cortinas y planta en el alféizar.
	var lado := clampf(h * 0.34, 54.0, 82.0)
	var win := Rect2(w * 0.035, h * 0.085, lado * 1.10, lado)
	_ventana(c, win, franja, t, true, Color("#b45309") if premium else Color("#2e8b8b"),
		Color("#8a5528") if premium else Color("#c8ccd0"))
	var mx := win.position.x + win.size.x * 0.22
	var my := win.end.y + 4.0
	c.draw_rect(Rect2(mx - 6.0, my - 8.0, 12.0, 8.0), Color("#c2410c"))
	c.draw_rect(Rect2(mx - 6.0, my - 8.0, 12.0, 8.0), Color("#7c2d12"), false, 1.2)
	for i in range(3):
		c.draw_circle(Vector2(mx - 4.0 + float(i) * 4.0, my - 11.0 - float(i % 2) * 2.0), 4.2,
			Color("#22c55e") if i % 2 == 0 else Color("#16a34a"), true, -1.0, true)
	# Cuadro de paisaje a la derecha.
	_cuadro(c, Rect2(w - w * 0.19, h * 0.095, w * 0.145, h * 0.235), "paisaje", t, 0.3,
		Color("#8a5528") if premium else Color("#b45309"))
	# Estante de pared con tarros.
	var ex := w * 0.855
	var ey := h * 0.44
	c.draw_rect(Rect2(ex, ey, w * 0.115, 4.0), col_madera)
	for i in range(2):
		var tx := ex + 6.0 + float(i) * 16.0
		c.draw_rect(Rect2(tx, ey - 13.0, 11.0, 13.0), Color("#fca5a5") if i == 0 else Color("#86efac"))
		c.draw_rect(Rect2(tx - 1.0, ey - 16.0, 13.0, 3.0), Color("#4a2a12"))
		c.draw_rect(Rect2(tx, ey - 13.0, 11.0, 13.0), _a(TINTA, 0.45), false, 1.0)
	# Lámpara colgante con luz cálida.
	var lx := w * 0.72
	var alto_l := h * 0.18
	_lampara_colgante(c, lx, 0.0, alto_l, Color("#d97706") if premium else Color("#f8fafc"), t, true)
	_haz(c, PackedVector2Array([
		Vector2(lx - 20.0, alto_l + h * 0.055),
		Vector2(lx + 20.0, alto_l + h * 0.055),
		Vector2(lx + w * 0.10, h * 0.80),
		Vector2(lx - w * 0.10, h * 0.80),
	]), _a(Color("#fde68a"), 0.055))
	# Rayo de luz de la ventana.
	if franja in ["manana", "tarde"]:
		_haz(c, PackedVector2Array([
			Vector2(win.position.x + win.size.x * 0.2, win.position.y + win.size.y * 0.3),
			Vector2(win.end.x, win.position.y + win.size.y * 0.3),
			Vector2(win.end.x + w * 0.20, h * 0.76),
			Vector2(win.position.x + w * 0.06, h * 0.76),
		]), _a(Color(1.0, 0.97, 0.82), 0.10))
	# Espejo o aparador lateral.
	if premium:
		c.draw_rect(Rect2(w * 0.005, h * 0.36, w * 0.018, h * 0.23), Color("#b45309"))
		c.draw_rect(Rect2(w * 0.002, h * 0.34, w * 0.024, maxf(2.0, h * 0.02)), Color("#d97706"))
	_motas(c, Rect2(0.0, h * 0.10, w, h * 0.60), t, 4, _a(Color.WHITE, 0.28), 0.2)


static func _comer_calle(c: CanvasItem, esc, w: float, h: float, t: float, franja: String) -> void:
	var noche := franja == "noche"
	# La misma plaza urbana del tiempo libre, con cafetería y farolas.
	dibujar_calle_idle(c, esc, w, h)
	# Carrito de comida con toldilla a rayas a la derecha.
	var cart_x := w * 0.83
	var cart_y := h * 0.66
	c.draw_rect(Rect2(cart_x, cart_y, w * 0.13, h * 0.18), Color("#fef3c7") if not noche else Color("#d6c3a5"))
	c.draw_rect(Rect2(cart_x, cart_y, w * 0.13, h * 0.18), Color("#78350f"), false, 1.8)
	c.draw_rect(Rect2(cart_x + 4.0, cart_y + 9.0, w * 0.055, h * 0.055), Color("#f59e0b"))
	c.draw_rect(Rect2(cart_x + 4.0, cart_y + 9.0, w * 0.055, h * 0.055), Color("#78350f"), false, 1.2)
	var awning_y := cart_y - h * 0.045
	for i in range(4):
		c.draw_rect(Rect2(cart_x - 4.0 + float(i) * w * 0.036, awning_y,
			w * 0.036, h * 0.045), Color("#ef4444") if i % 2 == 0 else Color("#f8fafc"))
	c.draw_line(Vector2(cart_x - 4.0, awning_y), Vector2(cart_x + w * 0.15, awning_y), Color("#7f1d1d"), 1.4)
	for i in range(2):
		c.draw_circle(Vector2(cart_x + w * 0.035 + float(i) * w * 0.06, cart_y + h * 0.20), 6.0,
			Color("#334155") if not noche else Color("#1e293b"), true, -1.0, true)
	# Vapor del carrito.
	for i in range(3):
		var p := fmod(t * 0.55 + float(i) * 0.33, 1.0)
		c.draw_circle(Vector2(cart_x + w * 0.045 + sin(t * 2.4 + float(i)) * 4.0,
			cart_y + 4.0 - p * 26.0), 3.2 * (1.0 - p * 0.5), _a(Color.WHITE, (1.0 - p) * 0.35),
			true, -1.0, true)
	# Pájaros.
	if not noche:
		for i in range(2):
			var bx2 := fmod(t * 20.0 + float(i) * 70.0, w + 80.0) - 40.0
			_pajaro(c, Vector2(bx2, h * (0.16 + float(i) * 0.05)), 4.0, _a(TINTA, 0.35))


# ---------------------------------------------------------------- duchar

static func _duchar(c: CanvasItem, esc, w: float, h: float, t: float, _v: String) -> void:
	# Pared alicatada con degradado fresco y luz cenital.
	_grad_v(c, Rect2(0.0, 0.0, w, h), Color("#e6fbfd"), Color("#b7eef2"), 14)
	_azulejos(c, Rect2(0.0, 0.0, w, h), Color("#d5f6f8"), Color("#93dfe5"), 34.0, t, 0.2)
	c.draw_circle(Vector2(w * 0.55, h * 0.10), h * 0.55, _a(Color(1.0, 1.0, 1.0), 0.10), true, -1.0, true)
	c.draw_circle(Vector2(w * 0.55, h * 0.10), h * 0.55, _a(Color(1.0, 0.98, 0.90), 0.07), true, -1.0, true)
	c.draw_circle(Vector2(w * 0.55, h * 0.10), h * 0.32, _a(Color(1.0, 0.99, 0.94), 0.10), true, -1.0, true)
	# Nicho con estantes, botes y planta.
	var nicho := Rect2(w * 0.055, h * 0.24, w * 0.16, h * 0.36)
	c.draw_rect(nicho, Color("#a9e6ea"))
	c.draw_rect(nicho, Color("#6cc7ce"), false, 2.0)
	c.draw_rect(Rect2(nicho.position.x + 4.0, nicho.position.y + 6.0, nicho.size.x - 8.0, 3.0),
		Color("#f0fdfe"))
	var shelf_y := nicho.position.y + nicho.size.y * 0.55
	c.draw_rect(Rect2(nicho.position.x + 3.0, shelf_y, nicho.size.x - 6.0, 3.0), Color("#f0fdfe"))
	var botes := [Color("#f472b6"), Color("#a78bfa"), Color("#34d399")]
	for i in range(3):
		var bx := nicho.position.x + 8.0 + float(i) * (nicho.size.x - 12.0) / 3.0
		c.draw_rect(Rect2(bx, nicho.position.y + 16.0, 10.0, 20.0), botes[i])
		c.draw_rect(Rect2(bx - 1.0, nicho.position.y + 12.0, 12.0, 4.0), botes[i].darkened(0.25))
		c.draw_rect(Rect2(bx, nicho.position.y + 16.0, 10.0, 20.0), _a(TINTA, 0.40), false, 1.0)
	# Planta colgante en el nicho.
	var px := nicho.position.x + nicho.size.x * 0.68
	var py := shelf_y
	c.draw_rect(Rect2(px - 5.0, py - 10.0, 10.0, 10.0), Color("#b96a3d"))
	for i in range(4):
		var ang := -1.1 + float(i) * 0.75
		_hoja(c, Vector2(px, py - 10.0), ang, 16.0, 7.0, Color("#4d9a4a"), Color("#2f6b31"),
			Color("#8bcd6d"), t, float(i) * 0.8)
	# Toallero y toalla.
	var tx := w * 0.055
	var ty := h * 0.66
	c.draw_line(Vector2(tx, ty), Vector2(tx + w * 0.075, ty), Color("#64748b"), 3.0)
	c.draw_rect(Rect2(tx + 4.0, ty + 2.0, w * 0.055, h * 0.20), Color("#fb7185"))
	c.draw_rect(Rect2(tx + 4.0, ty + 2.0, w * 0.055, h * 0.20), Color("#9f1239"), false, 1.2)
	for i in range(3):
		c.draw_line(Vector2(tx + 8.0 + float(i) * 6.0, ty + 5.0),
			Vector2(tx + 8.0 + float(i) * 6.0, ty + h * 0.19), _a(Color("#fecdd3"), 0.45), 1.0)
	# Mampara de cristal a la derecha con perfil cromado.
	var gx := w * 0.83
	c.draw_colored_polygon(PackedVector2Array([
		Vector2(gx, h * 0.06), Vector2(w, h * 0.02), Vector2(w, h * 0.86), Vector2(gx, h * 0.92),
	]), _a(Color(0.85, 0.97, 1.0), 0.30))
	c.draw_line(Vector2(gx, h * 0.06), Vector2(w, h * 0.02), Color("#94a3b8"), 3.0)
	c.draw_line(Vector2(gx, h * 0.06), Vector2(gx, h * 0.92), Color("#cbd5e1"), 2.4)
	c.draw_line(Vector2(gx + 8.0, h * 0.14), Vector2(gx + 8.0, h * 0.82), _a(Color.WHITE, 0.50), 2.0)
	c.draw_line(Vector2(gx + 26.0, h * 0.10), Vector2(gx + 26.0, h * 0.48), _a(Color.WHITE, 0.25), 1.4)
	# Ducha de lluvia cenital sobre el Sim, con tubería.
	var sx := w * 0.42
	var sy := h * 0.055
	c.draw_line(Vector2(0.0, sy), Vector2(sx + 30.0, sy), Color("#94a3b8"), 5.0)
	c.draw_line(Vector2(sx + 30.0, sy), Vector2(sx + 30.0, sy + 12.0), Color("#94a3b8"), 4.0)
	var cab := Rect2(sx - 8.0, sy + 11.0, 76.0, 8.0)
	c.draw_rect(cab, Color("#cbd5e1"))
	c.draw_rect(cab, Color("#64748b"), false, 1.6)
	c.draw_rect(Rect2(cab.position.x + 4.0, cab.position.y + 2.0, cab.size.x - 8.0, 2.0), Color("#f8fafc"))
	for i in range(9):
		var hx := cab.position.x + 6.0 + float(i) * 8.0
		c.draw_circle(Vector2(hx, cab.end.y), 1.2, _a(Color("#38bdf8"), 0.75), true, -1.0, true)
	# Cortina de agua animada.
	var col_agua := _a(Color("#7dd3fc"), 0.55)
	for i in range(11):
		var off := fmod(t * 170.0 + float(i) * 23.0, 120.0)
		var wx := cab.position.x + 8.0 + float(i) * 6.2
		var wy := cab.end.y + off
		if wy < h * 0.80:
			c.draw_line(Vector2(wx, wy), Vector2(wx - 3.0, wy + 9.0), col_agua, 1.8, true)
	# Salpicaduras y charco en el suelo.
	for i in range(5):
		var p := fmod(t * 0.9 + float(i) * 0.21, 1.0)
		var rx := w * 0.12 + float(i) * 16.0
		var ry := h * 0.84
		c.draw_circle(Vector2(rx, ry), 2.0 + p * 10.0, _a(Color("#7dd3fc"), (1.0 - p) * 0.20), true, -1.0, true)
	_elipse(c, Vector2(w * 0.22, h * 0.91), 62.0, 7.0, _a(Color("#38bdf8"), 0.20))
	c.draw_circle(Vector2(w * 0.58, h * 0.92), 7.0, Color("#64748b"), true, -1.0, true)
	c.draw_circle(Vector2(w * 0.58, h * 0.92), 3.4, Color("#334155"), true, -1.0, true)
	for i in range(3):
		c.draw_line(Vector2(w * 0.58 - 5.0 + float(i) * 3.4, h * 0.92),
			Vector2(w * 0.58 - 5.0 + float(i) * 3.4, h * 0.92 - 3.2), Color("#94a3b8"), 1.0)
	# Vapor cálido.
	for i in range(4):
		var pv := fmod(t * 0.30 + float(i) * 0.27, 1.0)
		var vx := w * (0.28 + float(i) * 0.13) + sin(t * 1.1 + float(i) * 2.0) * 6.0
		var vy := h * 0.80 - pv * h * 0.55
		c.draw_circle(Vector2(vx, vy), 10.0 + pv * 8.0, _a(Color.WHITE, (1.0 - pv) * 0.09), true, -1.0, true)


# ---------------------------------------------------------------- estudiar

static func _estudiar(c: CanvasItem, esc, w: float, h: float, t: float, _v: String) -> void:
	var franja: String = esc._franja_horaria()
	var noche := franja == "noche"
	var cx := w * 0.5
	# Pared serena con degradado y foco de lámpara.
	_grad_v(c, Rect2(0.0, 0.0, w, h * 0.82), Color("#f4f8fd") if not noche else Color("#262c44"),
		Color("#dde8f4") if not noche else Color("#1c2136"), 14)
	c.draw_rect(Rect2(0.0, 0.0, w, h * 0.030), Color("#cbd5e1") if not noche else Color("#111827"))
	c.draw_line(Vector2(0.0, h * 0.030), Vector2(w, h * 0.030), _a(Color.WHITE, 0.45), 1.0)
	# Ventana a la derecha con cortinas.
	var lado := clampf(h * 0.33, 52.0, 78.0)
	var win := Rect2(w * 0.755, h * 0.085, lado * 1.08, lado)
	_ventana(c, win, franja, t, true, Color("#3b82f6") if not noche else Color("#312e81"),
		Color("#c8ccd0"))
	_haz(c, PackedVector2Array([
		Vector2(win.position.x + 6.0, win.position.y + win.size.y * 0.55),
		Vector2(win.end.x, win.position.y + win.size.y * 0.55),
		Vector2(w * 0.93, h * 0.80),
		Vector2(w * 0.60, h * 0.80),
	]), _a(Color(1.0, 0.96, 0.80), 0.075))
	# Estantería completa a la izquierda.
	var est := Rect2(w * 0.025, h * 0.185, w * 0.195, h * 0.60)
	_estante_libros(c, est, 1.0, Color("#92400e") if not noche else Color("#5b3218"))
	# Planta sobre la estantería.
	_planta(c, Vector2(est.position.x + est.size.x * 0.72, est.position.y - 2.0), h * 0.24, t, "verde", 0.7)
	# Reloj de pared.
	_cuadro(c, Rect2(w * 0.255, h * 0.115, w * 0.060, h * 0.145), "reloj", t, 0.3, Color("#64748b"))
	# Corcho con notas y fotos.
	var cor := Rect2(w * 0.315, h * 0.105, w * 0.145, h * 0.255)
	c.draw_rect(cor, Color("#c69c6d") if not noche else Color("#5d4a36"))
	c.draw_rect(cor, Color("#7c5a35"), false, 2.0)
	for i in range(6):
		var nx := cor.position.x + 7.0 + float(i % 3) * (cor.size.x - 16.0) * 0.5
		var ny := cor.position.y + 8.0 + float(i / 3) * (cor.size.y - 20.0) * 0.55
		var col_n: Color = [Color("#fef08a"), Color("#fca5a5"), Color("#bfdbfe"), Color("#bbf7d0"),
			Color("#fde68a"), Color("#ddd6fe")][i]
		c.draw_rect(Rect2(nx, ny, 22.0, 18.0), col_n)
		c.draw_rect(Rect2(nx, ny, 22.0, 18.0), _a(TINTA, 0.35), false, 0.8)
		c.draw_circle(Vector2(nx + 11.0, ny + 2.0), 1.4, Color("#dc2626"), true, -1.0, true)
		for k in range(2):
			c.draw_line(Vector2(nx + 3.0, ny + 7.0 + float(k) * 4.0), Vector2(nx + 18.0, ny + 7.0 + float(k) * 4.0),
				_a(TINTA, 0.35), 0.8)
	# Póster motivacional a la derecha del corcho.
	c.draw_rect(Rect2(w * 0.485, h * 0.10, w * 0.075, h * 0.17), Color("#0ea5e9"))
	c.draw_string(FUENTE_COMIC, Vector2(w * 0.505, h * 0.195), "GO!", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	c.draw_rect(Rect2(w * 0.485, h * 0.10, w * 0.075, h * 0.17), Color("#0369a1"), false, 1.6)
	# Respaldo de silla detrás del Sim.
	var silla := Rect2(cx - w * 0.095, h * 0.575, w * 0.19, h * 0.235)
	c.draw_rect(silla, Color("#334155") if not noche else Color("#1e293b"))
	c.draw_rect(Rect2(silla.position.x + 5.0, silla.position.y + 5.0, silla.size.x - 10.0, silla.size.y - 10.0),
		Color("#475569") if not noche else Color("#26324a"))
	c.draw_rect(silla, Color("#1e293b"), false, 2.2)
	for i in range(3):
		c.draw_line(Vector2(silla.position.x + 8.0, silla.position.y + 14.0 + float(i) * 13.0),
			Vector2(silla.end.x - 8.0, silla.position.y + 14.0 + float(i) * 13.0),
			_a(Color("#94a3b8"), 0.20), 1.0)
	# Lámpara de escritorio con halo cálido (la base queda tras el escritorio).
	var lx := w * 0.815
	var ly := h * 0.792
	_elipse(c, Vector2(lx, ly), 11.0, 3.2, Color("#334155"), Color("#0f172a"), 1.2)
	c.draw_line(Vector2(lx, ly), Vector2(lx, h * 0.58), Color("#475569"), 3.0)
	c.draw_line(Vector2(lx, h * 0.58), Vector2(lx - 22.0, h * 0.51), Color("#475569"), 3.0)
	var pantalla := PackedVector2Array([
		Vector2(lx - 22.0, h * 0.51),
		Vector2(lx - 34.0, h * 0.565),
		Vector2(lx - 14.0, h * 0.585),
		Vector2(lx - 8.0, h * 0.535),
	])
	c.draw_colored_polygon(pantalla, Color("#1d4ed8") if not noche else Color("#f59e0b"))
	c.draw_polyline(PackedVector2Array([pantalla[0], pantalla[1], pantalla[2], pantalla[3], pantalla[0]]),
		TINTA, 1.4, true)
	c.draw_circle(Vector2(lx - 22.0, h * 0.565), 18.0, _a(Color("#fde68a"), 0.18), true, -1.0, true)
	_haz(c, PackedVector2Array([
		Vector2(lx - 28.0, h * 0.56),
		Vector2(lx - 8.0, h * 0.56),
		Vector2(lx + 28.0, h * 0.792),
		Vector2(lx - 58.0, h * 0.792),
	]), _a(Color("#fde68a"), 0.085))
	# Pila de libros y taza en el escritorio (fondo, la capa frontal pinta el resto).
	c.draw_rect(Rect2(w * 0.665, h * 0.74, 28.0, 7.0), Color("#dc2626"))
	c.draw_rect(Rect2(w * 0.669, h * 0.716, 25.0, 7.0), Color("#2563eb"))
	c.draw_rect(Rect2(w * 0.673, h * 0.694, 22.0, 6.0), Color("#16a34a"))
	c.draw_rect(Rect2(w * 0.665, h * 0.74, 28.0, 7.0), _a(TINTA, 0.5), false, 1.0)
	# Polvo en la luz.
	_motas(c, Rect2(w * 0.10, h * 0.15, w * 0.82, h * 0.62), t, 6, _a(Color.WHITE, 0.35), 0.4)


# ---------------------------------------------------------------- televisión

static func _tv(c: CanvasItem, esc, w: float, h: float, t: float, v: String) -> void:
	var cx := w * 0.5
	var col_tv: Color = esc._color_canal_tv
	# Salón oscuro y cálido.
	_grad_v(c, Rect2(0.0, 0.0, w, h), Color("#242d44"), Color("#111827"), 16)
	c.draw_rect(Rect2(0.0, h * 0.66, w, h * 0.34), Color("#1e293b"))
	# Ventana nocturna a la derecha.
	var lado := clampf(h * 0.34, 54.0, 80.0)
	_ventana(c, Rect2(w * 0.775, h * 0.09, lado * 0.92, lado), "noche", t, true, Color("#4338ca"),
		Color("#475569"))
	# Pósters y estante a la izquierda.
	_cuadro(c, Rect2(w * 0.045, h * 0.10, w * 0.115, h * 0.215), "abstracto", t, 0.2, Color("#334155"))
	c.draw_rect(Rect2(w * 0.045, h * 0.38, w * 0.155, 4.0), Color("#78350f"))
	for i in range(5):
		var bx := w * 0.052 + float(i) * 18.0
		var alto := h * (0.075 + 0.022 * float(i % 3))
		c.draw_rect(Rect2(bx, h * 0.38 - alto, 16.0, alto), PALETA_LIBROS[(i + 2) % PALETA_LIBROS.size()])
		c.draw_rect(Rect2(bx, h * 0.38 - alto, 16.0, alto), _a(TINTA, 0.45), false, 1.0)
	# Televisión en perspectiva a la derecha con pantalla encendida.
	var tv_p := PackedVector2Array([
		Vector2(w * 0.685, h * 0.225), Vector2(w * 0.985, h * 0.195),
		Vector2(w * 0.985, h * 0.575), Vector2(w * 0.685, h * 0.605),
	])
	c.draw_colored_polygon(tv_p, Color("#0f172a"))
	var tv_cerr := PackedVector2Array(tv_p)
	tv_cerr.append(tv_p[0])
	c.draw_polyline(tv_cerr, Color("#020617"), 3.0, true)
	var scr := PackedVector2Array([
		Vector2(w * 0.702, h * 0.248), Vector2(w * 0.966, h * 0.219),
		Vector2(w * 0.966, h * 0.545), Vector2(w * 0.702, h * 0.572),
	])
	_grad_v(c, Rect2(scr[0].x, scr[0].y, scr[1].x - scr[0].x, scr[3].y - scr[0].y),
		col_tv.lightened(0.25), col_tv.darkened(0.35), 10)
	c.draw_colored_polygon(scr, _a(col_tv, 0.92))
	# Imagen simple en la pantalla (sol, montañas y líneas de escaneo).
	c.draw_circle(Vector2(w * 0.84, h * 0.31), 10.0, _a(Color("#fef3c7"), 0.85), true, -1.0, true)
	c.draw_colored_polygon(PackedVector2Array([
		Vector2(w * 0.702, h * 0.50), Vector2(w * 0.76, h * 0.40),
		Vector2(w * 0.82, h * 0.50), Vector2(w * 0.89, h * 0.375),
		Vector2(w * 0.966, h * 0.47), Vector2(w * 0.966, h * 0.545), Vector2(w * 0.702, h * 0.572),
	]), _a(col_tv.darkened(0.55), 0.85))
	for i in range(9):
		var sy := lerpf(scr[0].y, scr[3].y, float(i) / 8.0)
		c.draw_line(Vector2(scr[0].x, sy), Vector2(scr[1].x, sy - 2.0), _a(Color.BLACK, 0.10), 1.0)
	var tv_cerr2 := PackedVector2Array(scr)
	tv_cerr2.append(scr[0])
	c.draw_polyline(tv_cerr2, Color("#020617"), 2.0, true)
	# Halo de la pantalla sobre la pared y el sofá.
	var pulso := 0.10 + sin(t * 7.5) * 0.035
	c.draw_circle(Vector2(w * 0.86, h * 0.46), w * 0.30, _a(col_tv, pulso * 0.55), true, -1.0, true)
	c.draw_circle(Vector2(w * 0.86, h * 0.46), w * 0.18, _a(col_tv, pulso), true, -1.0, true)
	# Mueble bajo la tele con soundbar y consola.
	var mueble := Rect2(w * 0.705, h * 0.60, w * 0.275, h * 0.10)
	_madera(c, mueble, Color("#3f2412"), true, 1.1)
	c.draw_rect(Rect2(mueble.position.x + 6.0, mueble.position.y + 5.0, mueble.size.x - 12.0, 7.0),
		Color("#111827"))
	c.draw_rect(Rect2(mueble.position.x + 6.0, mueble.position.y + 5.0, mueble.size.x - 12.0, 7.0),
		Color("#334155"), false, 1.0)
	c.draw_rect(Rect2(mueble.position.x + mueble.size.x * 0.40, mueble.position.y + 18.0, 34.0, 9.0),
		Color("#e2e8f0"))
	c.draw_rect(Rect2(mueble.position.x + mueble.size.x * 0.40, mueble.position.y + 18.0, 34.0, 9.0),
		Color("#64748b"), false, 1.0)
	# Sofá verde detrás del personaje con cojines.
	var sofa := Rect2(cx - w * 0.21, h * 0.555, w * 0.42, h * 0.245)
	c.draw_rect(sofa, Color("#166534"))
	c.draw_rect(Rect2(sofa.position.x, sofa.position.y, sofa.size.x, sofa.size.y * 0.22),
		Color("#14532d"))
	c.draw_rect(sofa, Color("#052e16"), false, 2.4)
	c.draw_line(Vector2(cx, sofa.position.y + sofa.size.y * 0.18), Vector2(cx, sofa.end.y),
		_a(Color("#052e16"), 0.55), 2.0)
	for i in range(2):
		var cin := Rect2(sofa.position.x + 14.0 + float(i) * (sofa.size.x * 0.53), sofa.position.y + 10.0,
			sofa.size.x * 0.31, sofa.size.y * 0.55)
		_panel_borde(c, cin, 9.0, Color("#15803d"), Color("#052e16"), 1.8)
	# Lámpara de pie entre la estantería y el sofá, con luz cálida.
	var lx := w * 0.245
	var ly := h * 0.80
	c.draw_line(Vector2(lx, ly), Vector2(lx, h * 0.42), Color("#334155"), 3.0)
	c.draw_line(Vector2(lx, ly), Vector2(lx + 14.0, ly), Color("#334155"), 3.0)
	var pantalla := PackedVector2Array([
		Vector2(lx - 16.0, h * 0.37), Vector2(lx + 16.0, h * 0.37),
		Vector2(lx + 10.0, h * 0.425), Vector2(lx - 10.0, h * 0.425),
	])
	c.draw_colored_polygon(pantalla, Color("#fde68a"))
	c.draw_polyline(PackedVector2Array([pantalla[0], pantalla[1], pantalla[2], pantalla[3], pantalla[0]]),
		Color("#b45309"), 1.4, true)
	c.draw_circle(Vector2(lx, h * 0.32), 30.0, _a(Color("#fde68a"), 0.10), true, -1.0, true)
	# Alfombra.
	_elipse(c, Vector2(cx, h * 0.88), w * 0.32, h * 0.10, Color("#3f2412"))
	_elipse(c, Vector2(cx, h * 0.88), w * 0.28, h * 0.08, Color("#7c2d12"))
	# Palomitas y fruta decorativa en el mueble.
	c.draw_circle(Vector2(w * 0.72, h * 0.585), 6.0, Color("#f1f5f9"), true, -1.0, true)
	c.draw_circle(Vector2(w * 0.72, h * 0.61), 5.0, Color("#f59e0b"), true, -1.0, true)
	# Texto de risa si toca.
	if v == "reir":
		var y_r := h * 0.20 + sin(t * 10.0) * 4.0
		c.draw_string(FUENTE_COMIC, Vector2(cx + w * 0.08, y_r), "¡JAJA!",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#fde047"))
	_motas(c, Rect2(w * 0.05, h * 0.10, w * 0.85, h * 0.65), t, 4, _a(col_tv, 0.25), 0.6)


# ---------------------------------------------------------------- manualidades

static func _manualidades(c: CanvasItem, esc, w: float, h: float, t: float, _v: String) -> void:
	var noche: bool = esc._franja_horaria() == "noche"
	var cx := w * 0.5
	# Pared de taller cálida.
	_grad_v(c, Rect2(0.0, 0.0, w, h * 0.82), Color("#fffaf1") if not noche else Color("#2e2a3c"),
		Color("#f5e6d0") if not noche else Color("#241f30"), 14)
	c.draw_rect(Rect2(0.0, 0.0, w, h * 0.028), Color("#b45309") if not noche else Color("#111827"))
	# Galería de cuadros y manchas de pintura.
	_cuadro(c, Rect2(w * 0.030, h * 0.095, w * 0.105, h * 0.205), "abstracto", t, 0.4, Color("#b45309"))
	_cuadro(c, Rect2(w * 0.155, h * 0.145, w * 0.085, h * 0.165), "botanico", t, 0.7, Color("#92400e"))
	c.draw_circle(Vector2(w * 0.115, h * 0.43), 4.0, _a(Color("#ef4444"), 0.65), true, -1.0, true)
	c.draw_circle(Vector2(w * 0.135, h * 0.47), 2.8, _a(Color("#3b82f6"), 0.60), true, -1.0, true)
	c.draw_circle(Vector2(w * 0.095, h * 0.49), 2.2, _a(Color("#facc15"), 0.60), true, -1.0, true)
	c.draw_line(Vector2(w * 0.09, h * 0.52), Vector2(w * 0.15, h * 0.44), _a(Color("#ef4444"), 0.35), 6.0, true)
	# Ventana alta con luz de estudio.
	var lado := clampf(h * 0.29, 46.0, 68.0)
	_ventana(c, Rect2(w * 0.30, h * 0.07, lado * 1.12, lado), "tarde" if not noche else "noche", t,
		true, Color("#f59e0b") if not noche else Color("#312e81"), Color("#c8ccd0"))
	_haz(c, PackedVector2Array([
		Vector2(w * 0.32, h * 0.26), Vector2(w * 0.44, h * 0.26),
		Vector2(w * 0.50, h * 0.78), Vector2(w * 0.22, h * 0.78),
	]), _a(Color(1.0, 0.96, 0.80), 0.075))
	# Caballete a la derecha.
	var ex := w * 0.79
	var ey := h * 0.80
	c.draw_line(Vector2(ex - 30.0, ey), Vector2(ex - 6.0, h * 0.29), Color("#92400e"), 4.2, true)
	c.draw_line(Vector2(ex + 30.0, ey), Vector2(ex + 6.0, h * 0.29), Color("#92400e"), 4.2, true)
	c.draw_line(Vector2(ex, ey), Vector2(ex, h * 0.34), Color("#7c2d12"), 3.4, true)
	var lienzo := Rect2(ex - 38.0, h * 0.22, 76.0, h * 0.34)
	c.draw_rect(lienzo, Color("#fefce8") if not noche else Color("#d6d3d1"))
	c.draw_rect(lienzo, Color("#78350f"), false, 2.0)
	c.draw_circle(lienzo.position + Vector2(lienzo.size.x * 0.38, lienzo.size.y * 0.32),
		lienzo.size.x * 0.16, _a(Color("#f43f5e"), 0.72), true, -1.0, true)
	c.draw_circle(lienzo.position + Vector2(lienzo.size.x * 0.62, lienzo.size.y * 0.58),
		lienzo.size.x * 0.20, _a(Color("#38bdf8"), 0.65), true, -1.0, true)
	c.draw_line(lienzo.position + Vector2(8.0, lienzo.size.y * 0.78),
		lienzo.position + Vector2(lienzo.size.x * 0.82, lienzo.size.y * 0.22),
		_a(Color("#111827"), 0.55), 2.2, true)
	c.draw_rect(Rect2(lienzo.position.x + 4.0, lienzo.end.y + 2.0, lienzo.size.x - 8.0, 4.0),
		Color("#92400e"))
	# Estante con botes y pinceles.
	var sx := w * 0.50
	var sy := h * 0.43
	c.draw_rect(Rect2(sx, sy, w * 0.145, 4.0), Color("#92400e"))
	for i in range(4):
		var bx := sx + 5.0 + float(i) * 18.0
		var col_b: Color = [Color("#ef4444"), Color("#3b82f6"), Color("#facc15"), Color("#22c55e")][i]
		c.draw_rect(Rect2(bx, sy - 15.0, 12.0, 15.0), col_b)
		c.draw_rect(Rect2(bx - 1.0, sy - 18.0, 14.0, 3.0), Color("#78350f"))
		c.draw_rect(Rect2(bx, sy - 15.0, 12.0, 15.0), _a(TINTA, 0.4), false, 0.9)
	var vaso := Rect2(sx + w * 0.095, sy - 20.0, 10.0, 20.0)
	c.draw_rect(vaso, Color("#e2e8f0"))
	c.draw_rect(vaso, Color("#64748b"), false, 1.0)
	for i in range(3):
		c.draw_line(Vector2(vaso.position.x + 3.0 + float(i) * 2.0, vaso.position.y),
			Vector2(vaso.position.x + 1.0 + float(i) * 3.0, vaso.position.y - 12.0),
			Color("#92400e"), 1.6, true)
	# Planta colgante arriba a la derecha.
	var hx := w * 0.935
	var hy := h * 0.035
	c.draw_line(Vector2(hx, 0.0), Vector2(hx, hy + 6.0), Color("#475569"), 1.2)
	c.draw_circle(Vector2(hx, hy + 8.0), 8.0, Color("#b96a3d"), true, -1.0, true)
	for i in range(5):
		var ang := -1.2 + float(i) * 0.6
		_hoja(c, Vector2(hx, hy + 8.0), ang, 26.0, 9.0, Color("#4d9a4a"), Color("#2f6b31"),
			Color("#8bcd6d"), t, float(i) * 0.7)
	# Mesa de trabajo ancha (parte trasera).
	c.draw_rect(Rect2(0.0, h * 0.79, w, h * 0.21), Color("#c2410c") if not noche else Color("#6b2d12"))
	c.draw_line(Vector2(0.0, h * 0.79), Vector2(w, h * 0.79), Color("#7c2d12"), 2.0)
	# Rollos de papel y taburete.
	c.draw_rect(Rect2(w * 0.045, h * 0.74, w * 0.04, h * 0.06), Color("#f8fafc"))
	c.draw_rect(Rect2(w * 0.045, h * 0.74, w * 0.04, h * 0.06), Color("#94a3b8"), false, 1.0)
	c.draw_rect(Rect2(w * 0.075, h * 0.76, w * 0.03, h * 0.04), Color("#fde68a"))
	_motas(c, Rect2(w * 0.08, h * 0.12, w * 0.75, h * 0.64), t, 5, _a(Color("#fbbf24"), 0.25), 0.9)


# ---------------------------------------------------------------- cocinar

static func _cocinar(c: CanvasItem, esc, w: float, h: float, t: float, _v: String) -> void:
	var noche: bool = esc._franja_horaria() == "noche"
	var cx := w * 0.5
	# Pared de cocina cálida.
	_grad_v(c, Rect2(0.0, 0.0, w, h * 0.80), Color("#fffaf0") if not noche else Color("#2d2a3e"),
		Color("#f6e7c9") if not noche else Color("#221f30"), 14)
	c.draw_rect(Rect2(0.0, 0.0, w, h * 0.028), Color("#92400e") if not noche else Color("#111827"))
	# Armarios altos a ambos lados.
	var col_arm := Color("#d6b98c") if not noche else Color("#4a3f2c")
	for lado in [0, 1]:
		var ax := w * (0.015 if lado == 0 else 0.79)
		var aw := w * 0.195
		c.draw_rect(Rect2(ax, h * 0.06, aw, h * 0.30), col_arm)
		c.draw_rect(Rect2(ax, h * 0.06, aw, h * 0.30), col_arm.darkened(0.40), false, 1.8)
		for i in range(2):
			var pw := aw * 0.5
			c.draw_rect(Rect2(ax + pw * float(i) + 3.0, h * 0.075, pw - 6.0, h * 0.27),
				col_arm.lightened(0.06))
			c.draw_rect(Rect2(ax + pw * float(i) + 3.0, h * 0.075, pw - 6.0, h * 0.27),
				col_arm.darkened(0.30), false, 1.0)
			c.draw_rect(Rect2(ax + pw * float(i) + pw * 0.5 - 5.0, h * 0.20, 7.0, 3.0),
				Color("#78350f") if not noche else Color("#cbd5e1"))
	# Ventana sobre el fregadero a la izquierda.
	var lado := clampf(h * 0.27, 42.0, 64.0)
	_ventana(c, Rect2(w * 0.255, h * 0.075, lado * 1.25, lado), esc._franja_horaria(), t, true,
		Color("#f59e0b") if not noche else Color("#312e81"))
	_planta(c, Vector2(w * 0.295, h * 0.40), h * 0.16, t, "verde", 0.3)
	# Campana extractora a la derecha con luz.
	var hx := w * 0.73
	var hy := h * 0.10
	var camp := PackedVector2Array([
		Vector2(hx - 36.0, hy), Vector2(hx + 36.0, hy),
		Vector2(hx + 58.0, hy + h * 0.13), Vector2(hx - 58.0, hy + h * 0.13),
	])
	c.draw_colored_polygon(camp, Color("#cbd5e1"))
	c.draw_polyline(PackedVector2Array([camp[0], camp[1], camp[2], camp[3], camp[0]]),
		Color("#64748b"), 1.8, true)
	c.draw_rect(Rect2(hx - 58.0, hy + h * 0.13, 116.0, 5.0), Color("#94a3b8"))
	c.draw_rect(Rect2(hx - 52.0, hy + h * 0.132, 104.0, 2.0), Color("#f8fafc"))
	_haz(c, PackedVector2Array([
		Vector2(hx - 52.0, hy + h * 0.14), Vector2(hx + 52.0, hy + h * 0.14),
		Vector2(hx + 76.0, h * 0.78), Vector2(hx - 76.0, h * 0.78),
	]), _a(Color(1.0, 0.97, 0.80), 0.07))
	# Rail de utensilios y sartenes colgadas.
	c.draw_rect(Rect2(w * 0.505, h * 0.36, w * 0.15, 3.0), Color("#64748b"))
	for i in range(3):
		var ux := w * 0.525 + float(i) * w * 0.045
		c.draw_line(Vector2(ux, h * 0.365), Vector2(ux, h * 0.44 + float(i % 2) * 8.0),
			Color("#475569"), 2.2, true)
		if i == 0:
			c.draw_circle(Vector2(ux, h * 0.47), 14.0, Color("#475569"), true, -1.0, true)
			c.draw_circle(Vector2(ux, h * 0.47), 10.0, Color("#334155"), true, -1.0, true)
		elif i == 1:
			c.draw_line(Vector2(ux, h * 0.39), Vector2(ux + 7.0, h * 0.46), Color("#94a3b8"), 3.0, true)
		else:
			c.draw_circle(Vector2(ux, h * 0.475), 9.0, Color("#b45309"), true, -1.0, true)
			c.draw_arc(Vector2(ux, h * 0.475), 9.0, 0.0, TAU, 14, Color("#7c2d12"), 1.4, true)
			c.draw_circle(Vector2(ux - 2.0, h * 0.465), 2.6, _a(Color("#f3d5a5"), 0.40), true, -1.0, true)
			c.draw_line(Vector2(ux, h * 0.44), Vector2(ux, h * 0.475), Color("#475569"), 2.0, true)
	# Estante de especias.
	c.draw_rect(Rect2(w * 0.36, h * 0.46, w * 0.105, 3.0), Color("#92400e"))
	for i in range(3):
		var bx := w * 0.365 + float(i) * 16.0
		c.draw_rect(Rect2(bx, h * 0.405, 11.0, h * 0.055), [Color("#fca5a5"), Color("#fde68a"), Color("#86efac")][i])
		c.draw_rect(Rect2(bx - 1.0, h * 0.395, 13.0, 4.0), Color("#78350f"))
		c.draw_rect(Rect2(bx, h * 0.405, 11.0, h * 0.055), _a(TINTA, 0.35), false, 0.9)
	# Azulejos del frente de la encimera.
	_azulejos(c, Rect2(0.0, h * 0.55, w, h * 0.25), Color("#fef3c7") if not noche else Color("#3b3352"),
		Color("#f59e0b") if not noche else Color("#6d5a7a"), 30.0, t, 0.4)
	# Focos cálidos del techo.
	for i in range(2):
		var fx := w * (0.34 + 0.32 * float(i))
		c.draw_circle(Vector2(fx, h * 0.045), 4.0, Color("#fef08a"), true, -1.0, true)
		c.draw_circle(Vector2(fx, h * 0.045), 24.0, _a(Color("#fde68a"), 0.10), true, -1.0, true)
	# Caldero humeante a la derecha sobre la encimera.
	var px := w * 0.77
	var py := h * 0.755
	c.draw_rect(Rect2(px - 24.0, py - 20.0, 48.0, 22.0), Color("#475569"))
	c.draw_rect(Rect2(px - 24.0, py - 20.0, 48.0, 22.0), TINTA, false, 1.6)
	c.draw_rect(Rect2(px - 27.0, py - 24.0, 54.0, 5.0), Color("#64748b"))
	c.draw_line(Vector2(px + 24.0, py - 14.0), Vector2(px + 32.0, py - 14.0), Color("#475569"), 3.0)
	for i in range(3):
		var p := fmod(t * 0.55 + float(i) * 0.3, 1.0)
		c.draw_circle(Vector2(px - 8.0 + float(i) * 8.0 + sin(t * 3.0 + float(i)) * 3.0,
			py - 26.0 - p * 30.0), 3.4 * (1.0 - p * 0.4), _a(Color.WHITE, (1.0 - p) * 0.40),
			true, -1.0, true)
	_motas(c, Rect2(w * 0.10, h * 0.12, w * 0.80, h * 0.60), t, 4, _a(Color("#fbbf24"), 0.25), 1.2)


# ---------------------------------------------------------------- fiesta

static func _fiesta(c: CanvasItem, esc, w: float, h: float, t: float, _v: String) -> void:
	var cx := w * 0.5
	# Sala oscura con degradado violeta.
	_grad_v(c, Rect2(0.0, 0.0, w, h), Color("#1b1038"), Color("#0b0718"), 16)
	# Barra del fondo a la derecha con botellas y neón.
	var bar := Rect2(w * 0.64, h * 0.40, w * 0.34, h * 0.22)
	c.draw_rect(bar, Color("#241436"))
	c.draw_rect(Rect2(bar.position.x, bar.position.y - h * 0.10, bar.size.x, h * 0.10),
		Color("#170d26"))
	for i in range(7):
		var bx := bar.position.x + 8.0 + float(i) * 14.0
		var alto := h * (0.05 + 0.02 * float(i % 3))
		c.draw_rect(Rect2(bx, bar.position.y - h * 0.10 - alto, 9.0, alto),
			[Color("#f43f5e"), Color("#38bdf8"), Color("#fde047"), Color("#a855f7"),
			Color("#34d399"), Color("#fb923c"), Color("#e879f9")][i])
		c.draw_rect(Rect2(bx, bar.position.y - h * 0.10 - alto, 9.0, alto), _a(Color.BLACK, 0.35), false, 0.8)
	c.draw_rect(Rect2(bar.position.x, bar.position.y, bar.size.x, 3.0), _a(Color("#e879f9"), 0.55))
	# Neón "FEST" sobre la barra.
	c.draw_string(FUENTE_COMIC, Vector2(w * 0.735, h * 0.26), "FEST",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 22, _a(Color("#f472b6"), 0.85))
	c.draw_string(FUENTE_COMIC, Vector2(w * 0.735, h * 0.26), "FEST",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 22, _a(Color("#fbcfe8"), 0.35))
	# Altavoces apilados a los lados.
	for lado in [0, 1]:
		var sx := w * (0.035 if lado == 0 else 0.89)
		for i in range(2):
			var sy := h * (0.50 + float(i) * 0.18)
			c.draw_rect(Rect2(sx, sy, w * 0.065, h * 0.15), Color("#111827"))
			c.draw_rect(Rect2(sx, sy, w * 0.065, h * 0.15), Color("#334155"), false, 1.2)
			c.draw_circle(Vector2(sx + w * 0.0325, sy + h * 0.075), h * 0.045, Color("#1e293b"), true, -1.0, true)
			c.draw_circle(Vector2(sx + w * 0.0325, sy + h * 0.075), h * 0.030, Color("#0f172a"), true, -1.0, true)
	# Bola de discoteca con facetas y destellos.
	var bx := cx
	var by := h * 0.10 + sin(t * 0.8) * 1.5
	c.draw_line(Vector2(bx, 0.0), Vector2(bx, by - 13.0), Color("#64748b"), 1.6, true)
	c.draw_circle(Vector2(bx, by), 15.0, Color("#cbd5e1"), true, -1.0, true)
	for i in range(6):
		var ang := TAU * float(i) / 6.0 + t * 0.6
		c.draw_line(Vector2(bx, by), Vector2(bx + cos(ang) * 14.0, by + sin(ang) * 14.0),
			_a(Color("#94a3b8"), 0.55), 1.0)
		if i % 2 == 0:
			c.draw_circle(Vector2(bx + cos(ang) * 13.0, by + sin(ang) * 13.0), 1.8,
				_a(Color("#fef3c7"), 0.85), true, -1.0, true)
	c.draw_circle(Vector2(bx, by), 15.0, Color("#475569"), false, 1.6)
	# Haces de focos volumétricos en movimiento.
	var colores: Array[Color] = [Color("#ec4899"), Color("#38bdf8"), Color("#a855f7"), Color("#f59e0b")]
	for i in range(4):
		var origen := Vector2(w * (0.14 + float(i) * 0.24), 0.0)
		var destino_x := w * (0.22 + float(i) * 0.19) + sin(t * (1.3 + float(i) * 0.2) + float(i) * 1.7) * w * 0.16
		_haz(c, PackedVector2Array([
			origen + Vector2(-5.0, 0.0), origen + Vector2(5.0, 0.0),
			Vector2(destino_x + w * 0.10, h * 0.86), Vector2(destino_x - w * 0.10, h * 0.86),
		]), _a(colores[i], 0.10))
	# Pista de baile con reflejos.
	var y_pista := h * 0.62
	_grad_v(c, Rect2(0.0, y_pista, w, h - y_pista), Color("#241447"), Color("#0b0718"), 8)
	for i in range(8):
		var tx := w * float(i) / 8.0
		c.draw_line(Vector2(tx, y_pista), Vector2(cx + (tx - cx) * 1.25, h), _a(Color("#7c3aed"), 0.18), 1.0)
	for i in range(3):
		var ty := y_pista + (h - y_pista) * (0.25 + float(i) * 0.28)
		c.draw_line(Vector2(0.0, ty), Vector2(w, ty), _a(Color("#7c3aed"), 0.16), 1.0)
	for i in range(3):
		var rx := w * (0.22 + float(i) * 0.27) + sin(t * 1.1 + float(i) * 2.0) * 10.0
		_elipse(c, Vector2(rx, h * 0.86), 34.0, 8.0, _a(colores[i % colores.size()], 0.16))
	# Bokeh de luces.
	_bokeh(c, Rect2(0.0, h * 0.12, w, h * 0.55), t, 12, colores, 0.35, 0.18)
	# Siluetas de público en el fondo.
	for i in range(9):
		var px := w * (0.03 + float(i) * 0.115)
		var py := h * 0.61 + sin(t * 2.4 + float(i) * 1.2) * 2.0
		c.draw_circle(Vector2(px, py), 7.0, _a(Color("#05030d"), 0.85), true, -1.0, true)
		c.draw_rect(Rect2(px - 8.0, py + 5.0, 16.0, h * 0.09), _a(Color("#05030d"), 0.85))
	# Confeti suspendido.
	for i in range(14):
		var px := w * fmod(0.07 + float(i) * 0.067, 1.0) + sin(t * 0.8 + float(i)) * 5.0
		var py := h * fmod(0.10 + float(i) * 0.047 + t * 0.035, 0.78)
		var col := colores[i % colores.size()]
		c.draw_rect(Rect2(px, py, 3.0, 2.0), _a(col, 0.65))
	_vignette(c, w, h, 0.30)


# ---------------------------------------------------------------- fútbol

static func _futbol(c: CanvasItem, esc, w: float, h: float, t: float, _v: String) -> void:
	var franja: String = esc._franja_horaria()
	var noche := franja == "noche"
	var atardecer := franja == "atardecer"
	# Cielo del estadio.
	if noche:
		_grad_v(c, Rect2(0.0, 0.0, w, h * 0.62), Color("#0f1a35"), Color("#263a5e"), 12)
	elif atardecer:
		_grad_v(c, Rect2(0.0, 0.0, w, h * 0.62), Color("#f97316"), Color("#fde68a"), 12)
	else:
		_grad_v(c, Rect2(0.0, 0.0, w, h * 0.62), Color("#6ec5f2"), Color("#e3f5fe"), 12)
	# Nubes y pájaros.
	if not noche:
		_nube(c, Vector2(w * 0.12 + sin(t * 0.3) * 6.0, h * 0.13), 13.0, 0.72)
		_nube(c, Vector2(w * 0.78 + sin(t * 0.25 + 1.0) * 7.0, h * 0.10), 11.0, 0.62)
		for i in range(2):
			var bx := fmod(t * 16.0 + float(i) * 60.0, w + 70.0) - 35.0
			_pajaro(c, Vector2(bx, h * (0.12 + float(i) * 0.04)), 4.0, _a(TINTA, 0.30))
	# Focos del estadio con haces.
	for i in range(2):
		var fx := w * (0.10 + float(i) * 0.78)
		var fy := h * 0.15
		c.draw_line(Vector2(fx, h * 0.34), Vector2(fx, fy), Color("#475569"), 3.0)
		c.draw_rect(Rect2(fx - 20.0, fy - 7.0, 40.0, 10.0), Color("#94a3b8"))
		for k in range(3):
			c.draw_circle(Vector2(fx - 13.0 + float(k) * 13.0, fy - 2.0), 3.2,
				Color("#fef9c3"), true, -1.0, true)
		_haz(c, PackedVector2Array([
			Vector2(fx - 18.0, fy + 2.0), Vector2(fx + 18.0, fy + 2.0),
			Vector2(fx + w * 0.18, h * 0.68), Vector2(fx - w * 0.16, h * 0.68),
		]), _a(Color("#fef9c3"), 0.07 if noche else 0.035))
	# Graderío con público.
	var y_grada := h * 0.50
	c.draw_rect(Rect2(0.0, y_grada, w, h * 0.14), Color("#334155") if not noche else Color("#1e293b"))
	c.draw_rect(Rect2(0.0, y_grada, w, 3.0), Color("#64748b"))
	for fila in range(2):
		for i in range(24):
			var px := w * float(i) / 23.0 + float(fila % 2) * 7.0
			var py := y_grada + 10.0 + float(fila) * 10.0
			var col: Color = [Color("#f43f5e"), Color("#fde047"), Color("#38bdf8"), Color("#f8fafc"),
				Color("#22c55e"), Color("#fb923c")][(i + fila) % 6]
			c.draw_circle(Vector2(px, py), 2.2, _a(col, 0.80), true, -1.0, true)
	# Vallas publicitarias.
	c.draw_rect(Rect2(0.0, h * 0.63, w, h * 0.07), Color("#f8fafc"))
	for i in range(5):
		c.draw_rect(Rect2(w * float(i) / 5.0 + 6.0, h * 0.645, w / 5.0 - 12.0, h * 0.04),
			[Color("#1d4ed8"), Color("#b91c1c"), Color("#047857"), Color("#7c3aed"), Color("#b45309")][i])
	c.draw_rect(Rect2(0.0, h * 0.63, w, h * 0.07), Color("#334155"), false, 1.2)
	# Césped con franjas de siega.
	_grad_v(c, Rect2(0.0, h * 0.70, w, h * 0.30), Color("#22c55e"), Color("#15803d"), 8)
	for i in range(9):
		var sx := w * float(i) / 9.0
		c.draw_rect(Rect2(sx, h * 0.70, w / 18.0, h * 0.30), _a(Color("#16a34a"), 0.35))
	c.draw_line(Vector2(0.0, h * 0.70), Vector2(w, h * 0.70), Color.WHITE, 2.0)
	# Líneas del campo en perspectiva.
	c.draw_line(Vector2(w * 0.02, h * 0.88), Vector2(w * 0.98, h * 0.88), _a(Color.WHITE, 0.55), 2.0)
	c.draw_line(Vector2(w * 0.18, h * 0.74), Vector2(w * 0.18, h * 0.98), _a(Color.WHITE, 0.45), 2.0)
	c.draw_line(Vector2(w * 0.82, h * 0.74), Vector2(w * 0.82, h * 0.98), _a(Color.WHITE, 0.45), 2.0)
	_elipse(c, Vector2(w * 0.5, h * 0.86), 20.0, 5.0, _a(Color.WHITE, 0.10))
	c.draw_arc(Vector2(w * 0.5, h * 0.86), 20.0, 0.0, TAU, 20, _a(Color.WHITE, 0.45), 1.6, true)
	# Portería a la derecha con red.
	var gx := w * 0.815
	var gy := h * 0.555
	var gw := w * 0.105
	c.draw_rect(Rect2(gx, gy, gw, h * 0.19), _a(Color.WHITE, 0.08))
	for i in range(6):
		c.draw_line(Vector2(gx + gw * float(i) / 5.0, gy),
			Vector2(gx + gw * float(i) / 5.0, gy + h * 0.19), _a(Color.WHITE, 0.25), 0.8)
	for i in range(5):
		c.draw_line(Vector2(gx, gy + h * 0.19 * float(i) / 4.0),
			Vector2(gx + gw, gy + h * 0.19 * float(i) / 4.0), _a(Color.WHITE, 0.25), 0.8)
	c.draw_polyline(PackedVector2Array([
		Vector2(gx, gy + h * 0.19), Vector2(gx, gy), Vector2(gx + gw, gy),
		Vector2(gx + gw, gy + h * 0.19),
	]), Color.WHITE, 3.0, true)
	# Banderín de córner.
	var cxf := w * 0.795
	var cyf := h * 0.695
	c.draw_line(Vector2(cxf, cyf), Vector2(cxf, cyf - 18.0), Color("#f8fafc"), 1.6, true)
	c.draw_colored_polygon(PackedVector2Array([
		Vector2(cxf, cyf - 18.0), Vector2(cxf + 12.0, cyf - 15.0), Vector2(cxf, cyf - 11.0),
	]), Color("#facc15"))
	# Césped en primer plano.
	for i in range(14):
		var fx := w * fmod(0.02 + float(i) * 0.073, 1.0)
		var fy := h * (0.90 + 0.03 * float(i % 3))
		c.draw_line(Vector2(fx, fy), Vector2(fx - 2.0, fy - 5.0),
			_a(Color("#166534"), 0.55), 1.0)
	# Confeti si celebra.
	if _v == "celebrar_gol":
		for i in range(14):
			var px := w * fmod(0.08 + float(i) * 0.063, 1.0) + sin(t * 2.0 + float(i)) * 8.0
			var py := h * fmod(0.12 + float(i) * 0.053 + t * 0.06, 0.48)
			c.draw_rect(Rect2(px, py, 3.0, 2.0),
				_a([Color("#f43f5e"), Color("#38bdf8"), Color("#fde047"), Color("#22c55e")][i % 4], 0.85))
	_vignette(c, w, h, 0.16)


# ---------------------------------------------------------------- trabajar

static func _trabajar(c: CanvasItem, esc, w: float, h: float, t: float, _v: String) -> void:
	var franja: String = esc._franja_horaria()
	var noche := franja == "noche"
	var cx := w * 0.5
	# Oficina luminosa con pared gris azulada.
	_grad_v(c, Rect2(0.0, 0.0, w, h * 0.82), Color("#f3f7fc") if not noche else Color("#252c40"),
		Color("#dbe5f1") if not noche else Color("#1a2032"), 14)
	c.draw_rect(Rect2(0.0, 0.0, w, h * 0.028), Color("#cbd5e1") if not noche else Color("#111827"))
	# Ventanal con skyline a la izquierda.
	var lado := clampf(h * 0.38, 60.0, 90.0)
	var win := Rect2(w * 0.035, h * 0.075, lado * 1.25, lado)
	_ventana(c, win, franja, t, false, Color.WHITE, Color("#94a3b8"))
	# Skyline dentro del cristal.
	var sky_y := win.position.y + win.size.y * 0.42
	for i in range(9):
		var bx := win.position.x + 6.0 + float(i) * (win.size.x - 12.0) / 9.0
		var alto := win.size.y * (0.12 + 0.055 * float((i * 3) % 5))
		c.draw_rect(Rect2(bx, sky_y - alto, (win.size.x - 12.0) / 9.0 - 2.0, alto + win.size.y * 0.18),
			_a(Color("#bfdbfe") if not noche else Color("#1e3a5f"), 0.75))
	c.draw_rect(win.grow(-4.0), Color(0.0, 0.0, 0.0, 0.05), false, 2.0)
	# Reloj de pared a la derecha.
	_cuadro(c, Rect2(w * 0.855, h * 0.095, w * 0.075, h * 0.19), "reloj", t, 0.3, Color("#475569"))
	# Estante con carpetas y planta.
	c.draw_rect(Rect2(w * 0.50, h * 0.30, w * 0.19, 4.0), Color("#64748b"))
	for i in range(6):
		var bx := w * 0.51 + float(i) * 18.0
		var alto := h * (0.10 + 0.02 * float(i % 3))
		c.draw_rect(Rect2(bx, h * 0.30 - alto, 14.0, alto),
			[Color("#1d4ed8"), Color("#334155"), Color("#b91c1c"), Color("#047857"),
			Color("#7c3aed"), Color("#b45309")][i])
		c.draw_rect(Rect2(bx, h * 0.30 - alto, 14.0, alto), _a(TINTA, 0.35), false, 1.0)
	_planta(c, Vector2(w * 0.72, h * 0.295), h * 0.20, t, "verde", 0.5)
	# Pizarra con gráficos al fondo.
	var piz := Rect2(w * 0.29, h * 0.10, w * 0.19, h * 0.25)
	c.draw_rect(piz, Color("#f8fafc"))
	c.draw_rect(piz, Color("#64748b"), false, 2.0)
	for i in range(4):
		var bh := piz.size.y * (0.18 + 0.13 * float(i % 3))
		c.draw_rect(Rect2(piz.position.x + 10.0 + float(i) * 20.0, piz.end.y - 8.0 - bh, 12.0, bh),
			_a(Color("#38bdf8"), 0.75))
	c.draw_line(piz.position + Vector2(8.0, 8.0), piz.position + Vector2(piz.size.x - 8.0, 8.0),
		_a(Color("#94a3b8"), 0.55), 1.0)
	# Silla de oficina detrás del Sim.
	var silla := Rect2(cx - w * 0.10, h * 0.565, w * 0.20, h * 0.245)
	c.draw_rect(silla, Color("#334155") if not noche else Color("#1e293b"))
	c.draw_rect(Rect2(silla.position.x + 5.0, silla.position.y + 7.0, silla.size.x - 10.0, silla.size.y - 14.0),
		Color("#475569") if not noche else Color("#26324a"))
	c.draw_rect(silla, Color("#1e293b"), false, 2.2)
	for i in range(4):
		c.draw_line(Vector2(silla.position.x + 9.0, silla.position.y + 16.0 + float(i) * 11.0),
			Vector2(silla.end.x - 9.0, silla.position.y + 16.0 + float(i) * 11.0),
			_a(Color("#94a3b8"), 0.18), 1.0)
	# Lámpara de mesa con luz fría.
	var lx := w * 0.815
	var ly := h * 0.792
	_elipse(c, Vector2(lx, ly), 11.0, 3.2, Color("#334155"), Color("#0f172a"), 1.2)
	c.draw_line(Vector2(lx, ly), Vector2(lx, h * 0.62), Color("#334155"), 3.0)
	c.draw_line(Vector2(lx, h * 0.62), Vector2(lx - 18.0, h * 0.56), Color("#334155"), 3.0)
	var pantalla := PackedVector2Array([
		Vector2(lx - 18.0, h * 0.56), Vector2(lx - 32.0, h * 0.61),
		Vector2(lx - 12.0, h * 0.625), Vector2(lx - 4.0, h * 0.575),
	])
	c.draw_colored_polygon(pantalla, Color("#0ea5e9") if not noche else Color("#f59e0b"))
	c.draw_polyline(PackedVector2Array([pantalla[0], pantalla[1], pantalla[2], pantalla[3], pantalla[0]]),
		TINTA, 1.4, true)
	c.draw_circle(Vector2(lx - 18.0, h * 0.605), 16.0, _a(Color("#bae6fd"), 0.20), true, -1.0, true)
	_haz(c, PackedVector2Array([
		Vector2(lx - 26.0, h * 0.60), Vector2(lx - 6.0, h * 0.60),
		Vector2(lx + 32.0, h * 0.80), Vector2(lx - 52.0, h * 0.80),
	]), _a(Color("#bae6fd"), 0.075))
	# Taza y portátil (fondo).
	c.draw_rect(Rect2(w * 0.64, h * 0.735, 16.0, 15.0), Color("#f8fafc"))
	c.draw_rect(Rect2(w * 0.64, h * 0.735, 16.0, 15.0), Color("#64748b"), false, 1.0)
	c.draw_arc(Vector2(w * 0.64 + 16.0, h * 0.742 + 5.0), 4.0, -PI * 0.5, PI * 0.5, 8,
		Color("#64748b"), 1.4, true)
	for i in range(2):
		var p := fmod(t * 0.5 + float(i) * 0.4, 1.0)
		c.draw_circle(Vector2(w * 0.647 + sin(t * 2.0 + float(i)) * 2.0, h * 0.73 - p * 18.0),
			2.2 * (1.0 - p * 0.4), _a(Color.WHITE, (1.0 - p) * 0.35), true, -1.0, true)
	_motas(c, Rect2(w * 0.08, h * 0.12, w * 0.82, h * 0.62), t, 4, _a(Color.WHITE, 0.24), 0.7)


# ---------------------------------------------------------------- capa frontal

static func _frente_correr(c: CanvasItem, _esc, w: float, h: float, t: float, v: String) -> void:
	var cx := w * 0.5
	_sombra(c, Vector2(cx + 4.0, h * 0.955), 24.0, 5.0, 0.20)
	# Polvo de las zapatillas.
	for i in range(4):
		var p := fmod(t * 2.4 + float(i) * 0.25, 1.0)
		var dx := cx - 24.0 - p * 74.0
		var dy := h * 0.935 - sin(p * PI) * 12.0
		var rad := (1.0 - p) * 9.0 + 2.0
		c.draw_circle(Vector2(dx, dy), rad, Color(0.95, 0.96, 0.98, (1.0 - p) * 0.62), true, -1.0, true)
	# Líneas cinéticas y hojas al sprintar.
	if v == "sprint":
		for i in range(7):
			var lx := w - fmod(t * 470.0 + float(i) * 105.0, w + 100.0)
			var ly := h * (0.12 + float(i) * 0.085)
			c.draw_line(Vector2(lx, ly), Vector2(lx + 58.0, ly), Color(1.0, 1.0, 1.0, 0.62), 2.4, true)
		for i in range(3):
			var hx := fmod(t * 120.0 + float(i) * 90.0, w + 80.0) - 40.0
			var hy := h * (0.30 + float(i) * 0.10) + sin(t * 2.0 + float(i)) * 8.0
			c.draw_colored_polygon(_elipse_pts(Vector2(hx, hy), 4.2, 2.2, 10, sin(t + float(i))), Color("#65a30d", 0.75))
	# Chispas al beber o secarse.
	if v in ["beber_agua", "secar_sudor"]:
		for i in range(3):
			var p2 := fmod(t * 1.4 + float(i) * 0.3, 1.0)
			var sp := Vector2(cx + 40.0 + sin(float(i) * 2.0) * 8.0, h * 0.30 - p2 * 22.0)
			_destello(c, sp, 3.0 + sin(t * 8.0 + float(i)) * 1.2, Color("#fde047", 1.0 - p2))


static func _frente_dormir(c: CanvasItem, esc, w: float, h: float, t: float, v: String) -> void:
	var cx := w * 0.5
	var resp := sin(t * (3.8 if v == "roncar" else 1.9)) * 2.5
	var y_manta := h * 0.685 + resp
	# Manta nórdica con volumen, degradado, costuras y pliegues.
	var segs := 18
	var pts := PackedVector2Array()
	for i in range(segs + 1):
		var u := float(i) / float(segs)
		pts.append(Vector2(w * u, y_manta + sin(u * PI * 2.6 + 0.4) * 2.8 + sin(u * PI) * 1.8))
	pts.append(Vector2(w, h))
	pts.append(Vector2(0.0, h))
	c.draw_colored_polygon(pts, Color("#2f6fd0"))
	# Degradado por bandas bajo el borde ondulado.
	for i in range(8):
		var u0 := float(i) / 8.0
		var y0 := y_manta + 6.0 + (h - y_manta) * u0
		var y1 := y_manta + 6.0 + (h - y_manta) * (u0 + 1.0 / 8.0)
		var col := Color("#3b82f6").lerp(Color("#1e40af"), u0 * 0.85)
		c.draw_rect(Rect2(0.0, y0, w, y1 - y0 + 1.0), col)
	# Sombra de la sábana sobre la manta.
	c.draw_rect(Rect2(0.0, y_manta + 9.0, w, 4.0), _a(Color("#1e3a8a"), 0.28))
	# Lados en sombra para dar volumen de tela.
	_grad_h(c, Rect2(0.0, y_manta + 8.0, w * 0.11, h - y_manta), _a(Color("#1e3a8a"), 0.32),
		Color(0.0, 0.0, 0.0, 0.0), 6)
	_grad_h(c, Rect2(w * 0.89, y_manta + 8.0, w * 0.11, h - y_manta), Color(0.0, 0.0, 0.0, 0.0),
		_a(Color("#1e3a8a"), 0.32), 6)
	# Costuras acolchadas en rombos, con contraste visible.
	for i in range(9):
		var sx := w * (0.02 + float(i) * 0.125)
		c.draw_line(Vector2(sx, y_manta + 17.0), Vector2(sx - w * 0.075, h - 4.0),
			_a(Color("#93c5fd"), 0.20), 1.2, true)
		c.draw_line(Vector2(sx, y_manta + 17.0), Vector2(sx + w * 0.075, h - 4.0),
			_a(Color("#172554"), 0.22), 1.2, true)
	for i in range(4):
		var sy := y_manta + 22.0 + float(i) * (h - y_manta) * 0.22
		c.draw_line(Vector2(w * 0.03, sy), Vector2(w * 0.97, sy + 5.0),
			_a(Color("#60a5fa"), 0.10), 1.0, true)
	# Esquina doblada de la manta en la esquina superior derecha.
	var dobl := PackedVector2Array([
		Vector2(w * 0.82, y_manta + 2.0), Vector2(w, y_manta + 18.0),
		Vector2(w * 0.90, y_manta + 26.0), Vector2(w * 0.80, y_manta + 14.0),
	])
	c.draw_colored_polygon(dobl, Color("#60a5fa"))
	c.draw_polyline(PackedVector2Array([dobl[0], dobl[1], dobl[2], dobl[3], dobl[0]]),
		_a(Color("#1e3a8a"), 0.45), 1.2, true)
	c.draw_line(dobl[0], dobl[2], _a(Color("#dbeafe"), 0.45), 1.0, true)
	# Pliegues verticales y brillos.
	for i in range(5):
		var fx := w * (0.12 + float(i) * 0.18)
		c.draw_line(Vector2(fx, y_manta + 14.0), Vector2(fx - 5.0, h - 1.0),
			_a(Color("#1e3a8a"), 0.26), 2.2, true)
		c.draw_line(Vector2(fx + 3.0, y_manta + 16.0), Vector2(fx - 1.0, h - 1.0),
			_a(Color("#93c5fd"), 0.15), 1.2, true)
	# Sábana doblada superior con dobladillo y pespunte.
	var saban := PackedVector2Array()
	for i in range(segs + 1):
		var u := float(i) / float(segs)
		saban.append(Vector2(w * u, y_manta + sin(u * PI * 2.6 + 0.4) * 2.8 + sin(u * PI) * 1.8))
	for i in range(segs, -1, -1):
		var u := float(i) / float(segs)
		saban.append(Vector2(w * u, y_manta + 12.0 + sin(u * PI * 2.6 + 0.4) * 2.4 + sin(u * PI) * 1.4))
	c.draw_colored_polygon(saban, Color("#e8f1ff"))
	c.draw_rect(Rect2(0.0, y_manta + 11.0, w, 2.0), _a(Color("#93c5fd"), 0.60))
	var dobladillo := PackedVector2Array()
	for i in range(segs + 1):
		var u := float(i) / float(segs)
		dobladillo.append(Vector2(w * u, y_manta + 9.0 + sin(u * PI * 2.6 + 0.4) * 2.0))
	c.draw_polyline(dobladillo, _a(Color("#60a5fa"), 0.75), 1.4, true)
	# Borde inferior y sombra de contacto.
	c.draw_rect(Rect2(0.0, h * 0.975, w, h * 0.025), Color("#1e3a8a"))
	# Libro de cabecera y gafas sobre la manta.
	var lx := w * 0.78
	var ly := h * 0.845
	c.draw_rect(Rect2(lx - 24.0, ly - 8.0, 48.0, 7.0), Color("#7c2d12"))
	c.draw_rect(Rect2(lx - 22.0, ly - 7.0, 44.0, 5.0), Color("#fef3c7"))
	c.draw_rect(Rect2(lx - 24.0, ly - 8.0, 48.0, 7.0), _a(TINTA, 0.55), false, 1.0)
	c.draw_line(Vector2(lx, ly - 7.0), Vector2(lx, ly - 2.0), Color("#b45309"), 1.2, true)
	c.draw_arc(Vector2(lx - 16.0, ly - 12.0), 5.0, 0.0, TAU, 12, Color("#334155"), 1.4, true)
	c.draw_arc(Vector2(lx - 4.0, ly - 12.0), 5.0, 0.0, TAU, 12, Color("#334155"), 1.4, true)
	c.draw_line(Vector2(lx - 11.0, ly - 12.0), Vector2(lx - 9.0, ly - 12.0), Color("#334155"), 1.2, true)
	# Peluche asomando por la izquierda.
	var tx := w * 0.19
	var ty := y_manta - 4.0
	c.draw_circle(Vector2(tx - 7.0, ty - 6.0), 4.6, Color("#d6a06a"), true, -1.0, true)
	c.draw_circle(Vector2(tx + 7.0, ty - 6.0), 4.6, Color("#d6a06a"), true, -1.0, true)
	c.draw_circle(Vector2(tx, ty), 9.0, Color("#c68a55"), true, -1.0, true)
	c.draw_circle(Vector2(tx - 3.0, ty - 2.0), 1.3, Color("#3f2411"), true, -1.0, true)
	c.draw_circle(Vector2(tx + 3.0, ty - 2.0), 1.3, Color("#3f2411"), true, -1.0, true)
	c.draw_circle(Vector2(tx, ty + 2.0), 2.2, Color("#a16207"), true, -1.0, true)
	c.draw_arc(Vector2(tx, ty + 1.0), 3.0, 0.35, PI - 0.35, 8, Color("#3f2411"), 1.0, true)
	# Letras Zzz.
	for i in range(3):
		var p := fmod(t * 0.52 + float(i) * 0.33, 1.0)
		var zx := cx + 48.0 + p * 40.0 + sin(t * 3.0 + float(i)) * 5.0
		var zy := h * 0.52 - p * h * 0.34
		var tam := int(13.0 + p * (14.0 if v == "roncar" else 9.0))
		var col := Color("#fde047" if v == "roncar" else "#e0e7ff", (1.0 - p) * 0.95)
		c.draw_string(FUENTE_COMIC, Vector2(zx, zy), "Z", HORIZONTAL_ALIGNMENT_LEFT, -1, tam, col)
	# Globo de sueño.
	if v == "sonar":
		c.draw_circle(Vector2(cx + 52.0, h * 0.42), 4.0, Color.WHITE, true, -1.0, true)
		c.draw_circle(Vector2(cx + 66.0, h * 0.34), 6.5, Color.WHITE, true, -1.0, true)
		var nc := Vector2(cx + 104.0, h * 0.22)
		c.draw_circle(nc, 24.0, Color.WHITE, true, -1.0, true)
		c.draw_circle(nc + Vector2(-17.0, 4.0), 14.0, Color.WHITE, true, -1.0, true)
		c.draw_circle(nc + Vector2(17.0, 4.0), 14.0, Color.WHITE, true, -1.0, true)
		c.draw_arc(nc, 24.0, 0.0, TAU, 24, TINTA, 2.0, true)
		if esc._icono_sueno == 0:
			c.draw_string(FUENTE_COMIC, nc + Vector2(-9.0, 8.0), "€", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#eab308"))
		elif esc._icono_sueno == 1:
			_estrella(c, nc, 12.0, Color("#f59e0b"))
		else:
			_corazon(c, nc, 10.0, Color("#e11d48"))


static func _frente_comer(c: CanvasItem, esc, w: float, h: float, t: float, v: String) -> void:
	if esc._personaje == null:
		return
	var cx := w * 0.5
	var fase: float = clampf(esc._tiempo_variacion / maxf(0.1, esc._duracion_variacion), 0.0, 1.0)
	var pos_boca: Vector2 = esc._personaje.obtener_punto_local_a_escena(Vector2(1.0, 21.0))
	if v == "":
		var ci: float = esc._personaje.obtener_ciclo_comer(t)
		if ci >= 0.45 and ci <= 0.62:
			var p := (ci - 0.45) / 0.17
			var col_m: Color = esc._personaje.color_bocado
			for k in range(4):
				var dir_x := -1.0 + float(k) * 0.80
				var mx: float = pos_boca.x + dir_x * (6.0 + p * 15.0)
				var my: float = pos_boca.y + 4.0 + p * p * 20.0 - (1.0 - p) * 3.0 * float(k % 2)
				c.draw_circle(Vector2(mx, my), (1.0 - p) * 2.5 + 0.6, Color(col_m, (1.0 - p) * 0.9), true, -1.0, true)
		# Vapor cálido constante sobre el plato.
		_vapor(c, Vector2(cx, h * 0.79), t, 0.32, 3)
		return
	match v:
		"delicioso":
			var env := sin(fase * PI)
			var offs: Array[Vector2] = [Vector2(-62.0, -34.0), Vector2(62.0, -40.0),
				Vector2(-54.0, 4.0), Vector2(68.0, -6.0)]
			for idx in range(4):
				var p_est: Vector2 = Vector2(cx, h * 0.46) + offs[idx]
				var r_est: float = (4.5 + sin(t * 9.0 + float(idx) * 1.7) * 2.4) * env
				if r_est > 0.8:
					_estrella(c, p_est, r_est, Color("#facc15", env))
			for i in range(2):
				var ph := fmod(fase * 1.4 + float(i) * 0.48, 1.0)
				var hx := cx + (-48.0 if i == 0 else 48.0) + sin(t * 4.5 + float(i) * 2.0) * 6.0
				var hy := h * 0.34 - ph * h * 0.20
				var ah := sin(ph * PI) * 0.92
				if ah > 0.05:
					_corazon(c, Vector2(hx, hy), 5.5 + ph * 2.0, Color("#fb7185", ah))
		"soplar":
			var punta = esc._personaje.obtener_punta_tenedor_escena()
			if fase < 0.78:
				var calor := 1.0 - clampf((fase - 0.16) / 0.58, 0.0, 0.92)
				c.draw_circle(punta, 10.0 + sin(t * 14.0) * 1.5, Color("#fb923c", 0.22 * calor), true, -1.0, true)
				var empuje := 0.0
				if fase >= 0.18 and fase <= 0.70:
					empuje = maxf(0.0, sin((fase - 0.18) / 0.52 * PI * 2.0))
				for i in range(3):
					var pv := fmod(t * 1.6 + float(i) * 0.33, 1.0)
					var pts_v := PackedVector2Array()
					for s in range(5):
						var sv := float(s) / 4.0
						var vx: float = punta.x - 4.0 + float(i) * 4.0 + empuje * sv * 18.0 + sin(sv * PI * 2.0 + t * 8.0 + float(i)) * 2.5
						var vy: float = punta.y - 4.0 - pv * 6.0 - sv * (18.0 - empuje * 6.0)
						pts_v.append(Vector2(vx, vy))
					c.draw_polyline(pts_v, Color(1.0, 0.96, 0.90, (1.0 - pv) * 0.72 * calor), 2.0, true)
			if fase >= 0.18 and fase <= 0.68:
				var u := (fase - 0.18) / 0.50
				var ciclo := fmod(u * 2.0, 1.0)
				var dir_v: Vector2 = (punta - pos_boca).normalized()
				var perp_v := Vector2(-dir_v.y, dir_v.x)
				var dist_tot: float = pos_boca.distance_to(punta)
				for i in range(-1, 2):
					var inicio: Vector2 = pos_boca + dir_v * (4.0 + ciclo * (dist_tot * 0.45)) + perp_v * float(i) * 4.2
					var fin: Vector2 = inicio + dir_v * (12.0 + (1.0 - ciclo) * 6.0) + perp_v * float(i) * 2.2
					var medio: Vector2 = (inicio + fin) * 0.5 + perp_v * (sin(ciclo * PI) * 2.5 * float(i))
					var alpha_w := sin(ciclo * PI) * 0.85
					if alpha_w > 0.05:
						c.draw_polyline(PackedVector2Array([inicio, medio, fin]), Color(1.0, 1.0, 1.0, alpha_w), 2.2, true)
		"limpiar_boca":
			if fase >= 0.52 and fase <= 0.82:
				var p := (fase - 0.52) / 0.30
				var r_br := sin(p * PI) * 7.5
				var p_br: Vector2 = pos_boca + Vector2(-13.0, 2.0)
				if r_br > 0.6:
					_estrella(c, p_br, r_br, Color("#fef08a", sin(p * PI)))
					_estrella(c, p_br + Vector2(-8.0, -7.0), r_br * 0.55, Color.WHITE)
		"oler":
			var pos_nariz = esc._personaje.obtener_punto_local_a_escena(Vector2(0.0, 10.0))
			var env_o := sin(fase * PI)
			for i in range(3):
				var p_a := fmod(t * 0.72 + float(i) * 0.33, 1.0)
				var origen_a := Vector2(cx - 16.0 + float(i) * 16.0, h * 0.78)
				var pts_a := PackedVector2Array()
				for s in range(9):
					var u := float(s) / 8.0
					var base_pt: Vector2 = origen_a.lerp(pos_nariz + Vector2(float(i - 1) * 9.0, 4.0),
						clampf(u * 0.75 + p_a * 0.25, 0.0, 1.0))
					var onda := sin(u * PI * 2.5 + t * 4.2 + float(i) * 2.1) * (5.5 * sin(u * PI))
					pts_a.append(base_pt + Vector2(onda, 0.0))
				var alpha_a := sin(p_a * PI) * env_o * 0.78
				if alpha_a > 0.04:
					c.draw_polyline(pts_a, Color("#fef3c7", alpha_a), 2.8, true)
		"beber":
			if fase >= 0.84:
				var p_ref := (fase - 0.84) / 0.16
				var r_ref := sin(p_ref * PI) * 6.0
				if r_ref > 0.5:
					_estrella(c, Vector2(cx + 46.0, h * 0.29), r_ref, Color("#38bdf8", sin(p_ref * PI)))
					_estrella(c, Vector2(cx + 58.0, h * 0.35), r_ref * 0.65, Color("#fde047", sin(p_ref * PI)))
	# Vapor ambiental tenue.
	_vapor(c, Vector2(cx, h * 0.79), t, 0.24, 2)


static func _frente_duchar(c: CanvasItem, esc, w: float, h: float, t: float, v: String) -> void:
	var cx := w * 0.5
	var y_esp := h * 0.80
	# Cortina de espuma con pompas grandes y brillos.
	var bx := -12.0
	while bx <= w + 24.0:
		var r_b := 20.0 + sin(bx * 0.09 + t * 2.0) * 5.0
		var cy := y_esp + 8.0 + sin(bx * 0.05 + t * 1.4) * 3.0
		c.draw_circle(Vector2(bx, cy), r_b, Color("#f8fafc"), true, -1.0, true)
		c.draw_arc(Vector2(bx, cy), r_b, PI, TAU, 14, Color("#bfdbfe", 0.75), 1.4, true)
		c.draw_circle(Vector2(bx - r_b * 0.35, cy - r_b * 0.30), r_b * 0.22, Color(1.0, 1.0, 1.0, 0.55), true, -1.0, true)
		bx += 29.0
	c.draw_rect(Rect2(0.0, y_esp + 12.0, w, h - y_esp), Color("#f8fafc"))
	c.draw_rect(Rect2(0.0, y_esp + 12.0, w, 2.0), Color("#dbeafe"))
	# Pompas flotando.
	for i in range(8):
		var p := fmod(t * 0.42 + float(i) * 0.13, 1.0)
		var px := cx - 100.0 + float(i) * 28.0 + sin(t * 2.4 + float(i)) * 12.0
		var py := h * 0.85 - p * h * 0.68
		var rad := 5.0 + float(i % 4) * 2.2
		c.draw_circle(Vector2(px, py), rad, Color(0.86, 0.97, 1.0, 0.32), true, -1.0, true)
		c.draw_arc(Vector2(px, py), rad, 0.0, TAU, 16, Color.WHITE, 1.4, true)
		c.draw_circle(Vector2(px - rad * 0.35, py - rad * 0.35), rad * 0.22, Color(1.0, 1.0, 1.0, 0.85), true, -1.0, true)
	# Patito de goma sobre la espuma, meciéndose.
	var dx := w * 0.83 + sin(t * 1.2) * 3.0
	var dy := y_esp + 18.0
	_elipse(c, Vector2(dx, dy), 15.0, 8.0, Color("#facc15"), Color("#b45309"), 1.4)
	c.draw_circle(Vector2(dx + 10.0, dy - 8.0), 8.0, Color("#fde047"), true, -1.0, true)
	c.draw_circle(Vector2(dx + 10.0, dy - 8.0), 8.0, Color("#b45309"), false, 1.2)
	c.draw_colored_polygon(PackedVector2Array([
		Vector2(dx + 16.0, dy - 7.0), Vector2(dx + 23.0, dy - 4.0), Vector2(dx + 16.0, dy - 2.0),
	]), Color("#f97316"))
	c.draw_circle(Vector2(dx + 12.0, dy - 10.0), 1.5, Color("#111827"), true, -1.0, true)
	c.draw_arc(Vector2(dx - 2.0, dy), 12.0, PI, TAU, 12, Color("#38bdf8", 0.45), 1.6, true)
	# Notas musicales.
	if v == "cantar":
		var cols: Array[Color] = [Color("#ec4899"), Color("#8b5cf6"), Color("#0284c7")]
		for i in range(3):
			var p := fmod(t * 0.85 + float(i) * 0.33, 1.0)
			var nx := cx + 46.0 + p * 54.0 + sin(t * 5.0 + float(i)) * 8.0
			var ny := h * 0.42 - p * h * 0.30
			_nota(c, Vector2(nx, ny), Color(cols[i], 1.0 - p))
	elif v == "agua_fria":
		for lado: float in [-1.0, 1.0]:
			var sx: float = cx + lado * 66.0 + sin(t * 32.0) * 3.0
			c.draw_line(Vector2(sx, h * 0.24), Vector2(sx + lado * 8.0, h * 0.31), Color("#0284c7"), 2.4, true)
			c.draw_line(Vector2(sx + lado * 8.0, h * 0.31), Vector2(sx, h * 0.38), Color("#0284c7"), 2.4, true)
	elif v == "burbuja_gigante":
		var fase: float = clampf(esc._tiempo_variacion / maxf(0.1, esc._duracion_variacion), 0.0, 1.0)
		var bc := Vector2(cx + 58.0 + fase * 50.0, h * 0.52 - fase * h * 0.28)
		if fase < 0.82:
			var r_g := 10.0 + fase * 22.0
			c.draw_circle(bc, r_g, Color(0.80, 0.96, 1.0, 0.35), true, -1.0, true)
			c.draw_arc(bc, r_g, 0.0, TAU, 24, Color.WHITE, 2.2, true)
			c.draw_circle(bc + Vector2(-r_g * 0.35, -r_g * 0.35), r_g * 0.22, Color(1.0, 1.0, 1.0, 0.85), true, -1.0, true)
		else:
			for k in range(6):
				var ang := TAU * float(k) / 6.0
				c.draw_line(bc + Vector2(cos(ang), sin(ang)) * 16.0,
					bc + Vector2(cos(ang), sin(ang)) * 28.0, Color.WHITE, 2.2, true)
	# Condensación en el borde del cristal.
	for i in range(6):
		var gx := w * 0.87 + float(i % 2) * 9.0
		var gy := h * (0.18 + float(i) * 0.10)
		c.draw_circle(Vector2(gx, gy), 1.6, Color(1.0, 1.0, 1.0, 0.35), true, -1.0, true)


static func _frente_estudiar(c: CanvasItem, esc, w: float, h: float, t: float, v: String) -> void:
	var cx := w * 0.5
	var y_m := h * 0.795
	# Escritorio de madera con perspectiva y grosor.
	_madera(c, Rect2(0.0, y_m, w, h * 0.075), Color("#8a5528"), true, 0.8)
	c.draw_rect(Rect2(0.0, y_m, w, maxf(2.0, h * 0.010)), Color("#c98a4b"))
	c.draw_line(Vector2(0.0, y_m), Vector2(w, y_m), Color("#4a2a12"), 2.0)
	c.draw_rect(Rect2(0.0, y_m + h * 0.075, w, h * 0.13), Color("#5c3317"))
	for i in range(5):
		var px := w * (0.02 + float(i) * 0.245)
		c.draw_rect(Rect2(px, y_m + h * 0.085, w * 0.19, h * 0.10), Color("#6b3d1c"))
		c.draw_rect(Rect2(px, y_m + h * 0.085, w * 0.19, h * 0.10), Color("#3f2410"), false, 1.0)
		c.draw_circle(Vector2(px + w * 0.095, y_m + h * 0.135), 2.2, Color("#d4a373"), true, -1.0, true)
	# Cuaderno abierto, páginas y renglones.
	var lib_y := h * 0.845
	var izq := PackedVector2Array([
		Vector2(cx - 62.0, lib_y), Vector2(cx, lib_y + 6.0),
		Vector2(cx, h * 0.965), Vector2(cx - 68.0, h * 0.945),
	])
	var der := PackedVector2Array([
		Vector2(cx, lib_y + 6.0), Vector2(cx + 62.0, lib_y),
		Vector2(cx + 68.0, h * 0.945), Vector2(cx, h * 0.965),
	])
	c.draw_colored_polygon(izq, Color("#ffffff"))
	c.draw_colored_polygon(der, Color("#f8fafc"))
	c.draw_polyline(PackedVector2Array([izq[0], izq[1], izq[2], izq[3], izq[0]]), Color("#64748b"), 1.6, true)
	c.draw_polyline(PackedVector2Array([der[0], der[1], der[2], der[3], der[0]]), Color("#64748b"), 1.6, true)
	for i in range(5):
		var ly := lib_y + 16.0 + float(i) * 10.0
		c.draw_line(Vector2(cx - 54.0, ly - 3.0), Vector2(cx - 10.0, ly + 1.0), _a(Color("#94a3b8"), 0.55), 1.0)
		c.draw_line(Vector2(cx + 10.0, ly + 1.0), Vector2(cx + 54.0, ly - 3.0), _a(Color("#94a3b8"), 0.55), 1.0)
	# Página que se levanta al pasar.
	if v == "pasar_pagina":
		var p: float = clampf(esc._tiempo_variacion / maxf(0.1, esc._duracion_variacion), 0.0, 1.0)
		var lev := sin(p * PI)
		var p0 := Vector2(cx + 10.0, lib_y + 8.0)
		var p1 := Vector2(cx + 58.0, lib_y + 2.0)
		var p2 := Vector2(cx + 58.0 + lev * 18.0, lib_y + 2.0 - lev * h * 0.16)
		var p3 := Vector2(cx + 10.0, lib_y + 8.0 - lev * h * 0.12)
		c.draw_colored_polygon(PackedVector2Array([p0, p1, p2, p3]), Color(1.0, 1.0, 1.0, 0.92))
		c.draw_polyline(PackedVector2Array([p0, p1, p2, p3, p0]), Color("#94a3b8"), 1.2, true)
	# Anotaciones animadas junto a la mano derecha.
	var escrita := sin(t * 10.0) * 3.0
	for i in range(3):
		var ax := cx + 22.0 + float(i) * 8.0 + escrita
		var ay := h * 0.88 + sin(t * 2.0 + float(i)) * 1.5
		c.draw_line(Vector2(ax, ay), Vector2(ax + 5.0, ay - 2.0), _a(Color("#1d4ed8"), 0.65), 1.0)
	if v == "subrayar":
		var p_sub := fmod(t * 0.9, 1.0)
		var lx_sub := cx - 34.0 + p_sub * 58.0
		c.draw_line(Vector2(lx_sub, h * 0.915), Vector2(lx_sub + 16.0, h * 0.912),
			Color("#fde047", 0.85), 4.0, true)
		c.draw_line(Vector2(lx_sub, h * 0.920), Vector2(lx_sub + 16.0, h * 0.917),
			Color("#facc15", 0.50), 2.0, true)
	# Taza de café humeante a la izquierda.
	var mx := w * 0.14
	var my := h * 0.79
	c.draw_rect(Rect2(mx - 10.0, my - 16.0, 20.0, 17.0), Color("#f8fafc"))
	c.draw_rect(Rect2(mx - 10.0, my - 16.0, 20.0, 17.0), Color("#475569"), false, 1.2)
	c.draw_arc(Vector2(mx + 10.0, my - 8.0), 5.0, -PI * 0.5, PI * 0.5, 8, Color("#475569"), 1.6, true)
	# Lápices en un vaso.
	var vx := w * 0.855
	var vy := h * 0.79
	c.draw_rect(Rect2(vx - 8.0, vy - 20.0, 16.0, 21.0), Color("#c7d2fe"))
	c.draw_rect(Rect2(vx - 8.0, vy - 20.0, 16.0, 21.0), Color("#475569"), false, 1.0)
	for i in range(3):
		c.draw_line(Vector2(vx - 4.0 + float(i) * 4.0, vy - 18.0),
			Vector2(vx - 6.0 + float(i) * 5.0, vy - 34.0), Color("#f59e0b"), 1.6, true)
	# Libros apilados a la derecha.
	c.draw_rect(Rect2(w * 0.70, h * 0.825, 44.0, 7.0), Color("#dc2626"))
	c.draw_rect(Rect2(w * 0.712, h * 0.801, 38.0, 7.0), Color("#2563eb"))
	c.draw_rect(Rect2(w * 0.705, h * 0.777, 41.0, 7.0), Color("#16a34a"))
	for i in range(3):
		c.draw_rect(Rect2(w * 0.70 + 3.0, h * 0.828 + float(i) * 0.0, 44.0, 7.0), _a(TINTA, 0.35), false, 1.0)
	# Notas adhesivas.
	for i in range(3):
		c.draw_rect(Rect2(w * 0.20 + float(i) * 13.0, y_m + 5.0, 11.0, 11.0),
			[Color("#fef08a"), Color("#fca5a5"), Color("#bbf7d0")][i])
	# Chispas de idea.
	if v == "bombilla":
		for i in range(3):
			var p := fmod(t * 2.0 + float(i) * 0.33, 1.0)
			_destello(c, Vector2(cx + 58.0 + sin(float(i) * 2.0) * 10.0, h * 0.28 - p * 20.0),
				3.0 + sin(t * 8.0 + float(i)) * 1.0, Color("#fde047", 1.0 - p))
	_motas(c, Rect2(w * 0.10, h * 0.25, w * 0.75, h * 0.55), t, 4, _a(Color(1.0, 0.97, 0.82), 0.35), 0.3)


static func _frente_tv(c: CanvasItem, esc, w: float, h: float, t: float, v: String) -> void:
	var cx := w * 0.5
	var col_tv: Color = esc._color_canal_tv
	# Luz de la pantalla sobre la escena.
	var pulso := 0.050 + sin(t * 7.5) * 0.018
	c.draw_colored_polygon(PackedVector2Array([
		Vector2(w * 0.66, h * 0.20), Vector2(w, h * 0.16),
		Vector2(w, h * 0.82), Vector2(w * 0.58, h * 0.88),
	]), _a(col_tv, pulso))
	# Asiento del sofá bajo la manta, con costuras y volumen.
	var y_asiento := h * 0.795
	_grad_v(c, Rect2(0.0, y_asiento, w, h * 0.105), Color("#166534"), Color("#14532d"), 6)
	c.draw_rect(Rect2(0.0, y_asiento, w, maxf(2.0, h * 0.010)), Color("#22c55e"))
	c.draw_line(Vector2(cx, y_asiento + 4.0), Vector2(cx, h * 0.90), _a(Color("#052e16"), 0.55), 1.6)
	for i in range(4):
		var sx := w * (0.10 + float(i) * 0.27)
		c.draw_line(Vector2(sx, y_asiento + 6.0), Vector2(sx + 3.0, h * 0.89),
			_a(Color("#052e16"), 0.22), 1.2, true)
	# Manta escocesa sobre el regazo, con pliegues y borde ondulado.
	var y_manta := h * 0.735
	var m_pts := PackedVector2Array()
	for i in range(13):
		var u := float(i) / 12.0
		m_pts.append(Vector2(w * (0.20 + u * 0.60), y_manta + sin(u * PI * 2.4 + 0.7) * 2.6))
	for i in range(9):
		var u2 := 1.0 - float(i) / 8.0
		m_pts.append(Vector2(w * (0.20 + u2 * 0.60), h * 0.872 + sin(u2 * PI * 3.1 + t * 1.2) * 3.0))
	c.draw_colored_polygon(m_pts, Color("#9f1239"))
	# Cuadros de la manta.
	for i in range(4):
		var lx := w * (0.25 + float(i) * 0.14)
		c.draw_line(Vector2(lx, y_manta + 6.0), Vector2(lx - 3.0, h * 0.87),
			_a(Color("#fecdd3"), 0.18), 1.8, true)
	for i in range(3):
		var ly := y_manta + 8.0 + float(i) * h * 0.042
		c.draw_line(Vector2(w * 0.22, ly), Vector2(w * 0.78, ly), _a(Color("#fecdd3"), 0.13), 1.2, true)
	# Pliegues y sombra de la manta.
	for i in range(3):
		var fx := w * (0.28 + float(i) * 0.16)
		c.draw_line(Vector2(fx, y_manta + 8.0), Vector2(fx - 4.0, h * 0.87),
			_a(Color("#4c0519"), 0.35), 2.0, true)
	c.draw_line(Vector2(w * 0.20, h * 0.868), Vector2(w * 0.80, h * 0.868), _a(Color("#4c0519"), 0.55), 1.6, true)
	# Brazos redondeados del sofá en primer plano.
	for lado in [0, 1]:
		var ax := -8.0 if lado == 0 else w - w * 0.075 + 8.0
		var aw := w * 0.075
		_panel_borde(c, Rect2(ax, h * 0.775, aw, h * 0.24), 14.0, Color("#14532d"), Color("#052e16"), 1.6)
		c.draw_rect(Rect2(ax + 6.0, h * 0.79, aw - 12.0, maxf(2.0, h * 0.012)), _a(Color("#4ade80"), 0.18))
		c.draw_line(Vector2(ax + 4.0, h * 0.86), Vector2(ax + aw - 4.0, h * 0.86), _a(Color("#052e16"), 0.55), 1.2)
	# Mesa de café baja en primer plano.
	var y_tab := h * 0.905
	_madera(c, Rect2(0.0, y_tab, w, h * 0.050), Color("#7c2d12"), true, 1.6)
	c.draw_rect(Rect2(0.0, y_tab, w, maxf(1.8, h * 0.009)), Color("#b45309"))
	c.draw_line(Vector2(0.0, y_tab), Vector2(w, y_tab), Color("#451a03"), 2.0)
	c.draw_rect(Rect2(0.0, y_tab + h * 0.050, w, h - y_tab - h * 0.050), Color("#451a03"))
	# Mantel individual bajo el bol.
	c.draw_colored_polygon(PackedVector2Array([
		Vector2(w * 0.09, y_tab + 2.0), Vector2(w * 0.26, y_tab + 2.0),
		Vector2(w * 0.28, h), Vector2(w * 0.07, h),
	]), Color("#fef3c7"))
	# Bol de palomitas.
	var bx := w * 0.17
	var by := y_tab + 3.0
	c.draw_rect(Rect2(bx - 22.0, by - 16.0, 44.0, 20.0), Color("#ef4444"))
	c.draw_rect(Rect2(bx - 22.0, by - 16.0, 44.0, 20.0), Color("#7f1d1d"), false, 1.4)
	for i in range(5):
		var px := bx - 16.0 + float(i) * 8.0
		c.draw_circle(Vector2(px, by - 18.0 - float(i % 2) * 3.0), 7.0, Color("#fef08a"), true, -1.0, true)
		c.draw_circle(Vector2(px, by - 18.0 - float(i % 2) * 3.0), 7.0, Color("#ca8a04"), false, 1.0)
		c.draw_circle(Vector2(px - 2.0, by - 20.0 - float(i % 2) * 3.0), 2.0, Color("#fefce8"), true, -1.0, true)
	# Latas de refresco.
	for i in range(2):
		var lx := w * 0.70 + float(i) * 26.0
		c.draw_rect(Rect2(lx, by - 25.0, 14.0, 29.0), Color("#dc2626") if i == 0 else Color("#2563eb"))
		c.draw_rect(Rect2(lx, by - 25.0, 14.0, 29.0), Color("#7f1d1d") if i == 0 else Color("#1e3a8a"), false, 1.2)
		c.draw_rect(Rect2(lx, by - 20.0, 14.0, 5.0), Color("#f8fafc"))
		c.draw_rect(Rect2(lx + 3.0, by - 28.0, 8.0, 3.0), Color("#cbd5e1"))
	# Mando y revista.
	c.draw_rect(Rect2(cx + 18.0, by - 10.0, 42.0, 14.0), Color("#111827"))
	c.draw_rect(Rect2(cx + 18.0, by - 10.0, 42.0, 14.0), Color("#475569"), false, 1.0)
	for i in range(3):
		c.draw_circle(Vector2(cx + 27.0 + float(i) * 8.0, by - 3.0), 1.5,
			Color("#f87171") if i == 0 else Color("#94a3b8"), true, -1.0, true)
	c.draw_rect(Rect2(w * 0.46, by - 6.0, 34.0, 10.0), Color("#f8fafc"))
	c.draw_rect(Rect2(w * 0.46, by - 6.0, 34.0, 10.0), Color("#94a3b8"), false, 0.8)
	for i in range(2):
		c.draw_line(Vector2(w * 0.465, by - 3.0 + float(i) * 3.0), Vector2(w * 0.50, by - 3.0 + float(i) * 3.0),
			_a(Color("#64748b"), 0.6), 0.8)
	# Palomitas volando hacia la boca.
	if v == "palomitas" and esc._personaje != null:
		var boca: Vector2 = esc._personaje.obtener_punto_local_a_escena(Vector2(0.0, 20.0))
		for i in range(5):
			var p := fmod(t * 1.6 + float(i) * 0.22, 1.0)
			var px2 := lerpf(bx + 10.0, boca.x - 8.0, p)
			var py2 := lerpf(by - 28.0, boca.y, p) - sin(p * PI) * 34.0
			c.draw_circle(Vector2(px2, py2), 3.0, Color("#fef08a"), true, -1.0, true)
			c.draw_circle(Vector2(px2, py2), 3.0, Color("#ca8a04"), false, 0.8)
	# Texto de risa o bostezo.
	if v == "reir":
		c.draw_string(FUENTE_COMIC, Vector2(cx + 58.0, h * 0.20 + sin(t * 10.0) * 3.0), "¡JAJA!",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#fde047"))
	elif v == "bostezo_tv":
		c.draw_string(FUENTE_COMIC, Vector2(cx + 58.0, h * 0.22 + sin(t * 3.0) * 2.0), "¡Uaaah!",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#cbd5e1"))


static func _frente_manualidades(c: CanvasItem, esc, w: float, h: float, t: float, v: String) -> void:
	var cx := w * 0.5
	var y_m := h * 0.795
	# Mesa de taller con mantel de trabajo.
	_madera(c, Rect2(0.0, y_m, w, h * 0.07), Color("#9a3412"), true, 1.2)
	c.draw_rect(Rect2(0.0, y_m, w, maxf(2.0, h * 0.010)), Color("#ea580c"))
	c.draw_line(Vector2(0.0, y_m), Vector2(w, y_m), Color("#7c2d12"), 2.0)
	# Trapo de trabajo con manchas.
	var mantel := PackedVector2Array([
		Vector2(w * 0.08, y_m + 2.0), Vector2(w * 0.92, y_m + 2.0),
		Vector2(w * 0.96, h), Vector2(w * 0.04, h),
	])
	c.draw_colored_polygon(mantel, Color("#f5f5f4"))
	c.draw_polyline(PackedVector2Array([mantel[0], mantel[1], mantel[2], mantel[3], mantel[0]]),
		Color("#d6d3d1"), 1.2, true)
	c.draw_circle(Vector2(w * 0.24, h * 0.90), 5.0, _a(Color("#ef4444"), 0.55), true, -1.0, true)
	c.draw_circle(Vector2(w * 0.76, h * 0.94), 4.0, _a(Color("#3b82f6"), 0.50), true, -1.0, true)
	c.draw_circle(Vector2(w * 0.70, h * 0.90), 3.0, _a(Color("#facc15"), 0.55), true, -1.0, true)
	c.draw_line(Vector2(w * 0.25, h * 0.93), Vector2(w * 0.33, h * 0.89), _a(Color("#ef4444"), 0.40), 3.0, true)
	# Paleta con pintura.
	var px := cx - w * 0.17
	var py := h * 0.88
	_elipse(c, Vector2(px, py), 34.0, 12.0, Color("#e7c9a9"), Color("#92400e"), 1.6)
	for i in range(4):
		var ang := -1.2 + float(i) * 0.7
		c.draw_circle(Vector2(px + cos(ang) * 20.0, py + sin(ang) * 6.0), 4.0,
			[Color("#ef4444"), Color("#3b82f6"), Color("#facc15"), Color("#22c55e")][i], true, -1.0, true)
	c.draw_circle(Vector2(px - 26.0, py - 2.0), 3.2, Color("#e7c9a9"), true, -1.0, true)
	c.draw_arc(Vector2(px - 26.0, py - 2.0), 3.2, 0.0, TAU, 10, Color("#92400e"), 1.0, true)
	# Botes de pintura a la derecha y pinceles.
	for i in range(3):
		var bx := w * 0.68 + float(i) * 20.0
		c.draw_rect(Rect2(bx, y_m + 8.0, 15.0, 19.0),
			[Color("#ef4444"), Color("#3b82f6"), Color("#facc15")][i])
		c.draw_rect(Rect2(bx - 1.0, y_m + 5.0, 17.0, 3.0), Color("#78350f"))
		c.draw_rect(Rect2(bx, y_m + 8.0, 15.0, 19.0), _a(TINTA, 0.40), false, 1.0)
	var vaso := Rect2(cx + w * 0.13, y_m + 4.0, 13.0, 24.0)
	c.draw_rect(vaso, Color("#e2e8f0"))
	c.draw_rect(vaso, Color("#64748b"), false, 1.0)
	for i in range(4):
		c.draw_line(Vector2(vaso.position.x + 3.0 + float(i) * 2.2, vaso.position.y),
			Vector2(vaso.position.x + float(i) * 3.0, vaso.position.y - 16.0), Color("#92400e"), 1.5, true)
		c.draw_circle(Vector2(vaso.position.x + float(i) * 3.0, vaso.position.y - 16.0), 1.6,
			[Color("#ef4444"), Color("#3b82f6"), Color("#facc15"), Color("#22c55e")][i], true, -1.0, true)
	# Chispas de pintura.
	if v == "soplar_pintura":
		for i in range(5):
			var p_s := fmod(t * 1.6 + float(i) * 0.18, 1.0)
			var sx_s := cx + 24.0 + p_s * 90.0
			var sy_s := h * 0.52 + sin(float(i) * 1.7 + t * 3.0) * 12.0
			c.draw_circle(Vector2(sx_s, sy_s), 2.2 + float(i % 2), Color(
				[Color("#ef4444"), Color("#3b82f6"), Color("#facc15"), Color("#22c55e"), Color("#e879f9")][i],
				1.0 - p_s * 0.7), true, -1.0, true)
	if v in ["pincelada_rapida", "admirar"]:
		for i in range(4):
			var p := fmod(t * 1.1 + float(i) * 0.25, 1.0)
			var sx := w * 0.74 + sin(t * 3.0 + float(i)) * 12.0
			var sy := h * 0.40 - p * 18.0
			_estrella(c, Vector2(sx, sy), 3.0 + sin(t * 9.0 + float(i)) * 1.2,
				Color([Color("#f43f5e"), Color("#38bdf8"), Color("#facc15"), Color("#22c55e")][i], 1.0 - p))
	_motas(c, Rect2(w * 0.15, h * 0.20, w * 0.70, h * 0.55), t, 4, _a(Color("#fbbf24"), 0.30), 1.1)


static func _frente_cocinar(c: CanvasItem, esc, w: float, h: float, t: float, v: String) -> void:
	var cx := w * 0.5
	var y_m := h * 0.795
	# Encimera con canto, brillo y muebles bajos con tiradores.
	_madera(c, Rect2(0.0, y_m, w, h * 0.050), Color("#b45309"), true, 0.4)
	c.draw_rect(Rect2(0.0, y_m, w, maxf(2.0, h * 0.010)), Color("#f59e0b"))
	c.draw_line(Vector2(0.0, y_m), Vector2(w, y_m), Color("#78350f"), 2.0)
	var y_f := y_m + h * 0.050
	c.draw_rect(Rect2(0.0, y_f, w, h - y_f), Color("#7c2d12"))
	for i in range(4):
		var px := w * (0.02 + float(i) * 0.245)
		c.draw_rect(Rect2(px, y_f + 6.0, w * 0.19, h - y_f - 12.0), Color("#8a3d18"))
		c.draw_rect(Rect2(px, y_f + 6.0, w * 0.19, h - y_f - 12.0), Color("#4a1d09"), false, 1.2)
		c.draw_rect(Rect2(px + w * 0.055, y_f + 9.0, w * 0.08, maxf(2.0, h * 0.010)), Color("#cbd5e1"))
		c.draw_rect(Rect2(px + w * 0.055, y_f + 9.0, w * 0.08, maxf(2.0, h * 0.010)), Color("#64748b"), false, 0.8)
	# Horno bajo la placa.
	var horno := Rect2(cx - 86.0, y_m + h * 0.022, 172.0, h * 0.155)
	c.draw_rect(horno, Color("#1f2937"))
	c.draw_rect(horno, Color("#0b1220"), false, 2.0)
	c.draw_rect(Rect2(horno.position.x + 7.0, horno.position.y + 8.0, horno.size.x - 14.0, h * 0.070),
		Color("#111827"))
	c.draw_rect(Rect2(horno.position.x + 9.0, horno.position.y + 10.0, horno.size.x - 18.0, h * 0.066),
		_a(Color("#f59e0b"), 0.10))
	c.draw_rect(Rect2(horno.position.x + 18.0, horno.position.y + 3.0, horno.size.x - 36.0, 3.0),
		Color("#94a3b8"))
	for i in range(3):
		c.draw_circle(Vector2(horno.position.x + 10.0 + float(i) * 10.0, horno.end.y - 8.0), 3.4,
			Color("#cbd5e1"), true, -1.0, true)
		c.draw_circle(Vector2(horno.position.x + 10.0 + float(i) * 10.0, horno.end.y - 8.0), 1.4,
			Color("#0f172a"), true, -1.0, true)
	# Sartén grande en primer plano, a la altura de las manos.
	var pan := Vector2(cx, y_m + h * 0.092)
	_elipse(c, pan + Vector2(2.0, 3.0), 48.0, 14.0, _a(Color(0.0, 0.0, 0.0), 0.18))
	_elipse(c, pan, 48.0, 14.0, Color("#334155"), Color("#0f172a"), 2.0)
	_elipse(c, pan + Vector2(0.0, 1.0), 36.0, 10.0, Color("#1f2937"))
	c.draw_line(Vector2(pan.x - 46.0, pan.y + 1.0), Vector2(pan.x - 76.0, pan.y - 8.0),
		Color("#475569"), 6.0, true)
	c.draw_line(Vector2(pan.x - 46.0, pan.y + 1.0), Vector2(pan.x - 76.0, pan.y - 8.0),
		Color("#0f172a"), 1.6, true)
	# Fuego visible alrededor del borde.
	for i in range(8):
		var ang := TAU * float(i) / 8.0
		var fx := pan.x + cos(ang) * 44.0
		var fy := pan.y + sin(ang) * 11.0
		var fh := 3.0 + (sin(t * 13.0 + float(i) * 1.7) + 1.0) * 3.5
		c.draw_colored_polygon(PackedVector2Array([
			Vector2(fx - 3.0, fy + 2.0), Vector2(fx + 3.0, fy + 2.0),
			Vector2(fx + sin(t * 9.0 + float(i)) * 1.6, fy - fh),
		]), Color("#f97316", 0.85))
	# Comida en la sartén.
	for i in range(6):
		var ang_f := float(i) * 1.05 + 0.4
		c.draw_circle(pan + Vector2(cos(ang_f) * 22.0, sin(ang_f) * 6.0 - 2.0), 4.2,
			[Color("#f59e0b"), Color("#dc2626"), Color("#22c55e"), Color("#fbbf24"),
			Color("#ef4444"), Color("#84cc16")][i], true, -1.0, true)
		if i % 2 == 0:
			c.draw_circle(pan + Vector2(cos(ang_f) * 22.0 - 1.0, sin(ang_f) * 6.0 - 3.5), 1.5,
				_a(Color.WHITE, 0.55), true, -1.0, true)
	# Salteado: comida en el aire.
	if v == "saltear":
		for k in range(6):
			var p := fmod(t * 2.2 + float(k) * 0.16, 1.0)
			var sx := pan.x - 22.0 + float(k) * 9.0
			var sy := pan.y - 6.0 - sin(p * PI) * 38.0
			c.draw_circle(Vector2(sx, sy), 4.0,
				[Color("#f59e0b"), Color("#dc2626"), Color("#22c55e"), Color("#fbbf24"),
				Color("#ef4444"), Color("#84cc16")][k], true, -1.0, true)
	# Tabla de cortar a la izquierda con verduras y cuchillo.
	var tb := Rect2(w * 0.045, y_m + 2.0, w * 0.16, h * 0.085)
	c.draw_rect(tb, Color("#c98a4b"))
	c.draw_rect(tb, Color("#8a5528"), false, 1.4)
	c.draw_line(Vector2(tb.position.x + 4.0, tb.position.y + 4.0),
		Vector2(tb.end.x - 4.0, tb.position.y + 4.0), _a(Color("#f3d5a5"), 0.45), 1.2)
	for i in range(3):
		c.draw_circle(Vector2(tb.position.x + 18.0 + float(i) * 18.0, tb.position.y + 10.0), 7.0,
			[Color("#dc2626"), Color("#f97316"), Color("#22c55e")][i], true, -1.0, true)
		c.draw_arc(Vector2(tb.position.x + 18.0 + float(i) * 18.0, tb.position.y + 10.0), 7.0,
			0.0, TAU, 12, Color("#7f1d1d"), 1.0, true)
		c.draw_circle(Vector2(tb.position.x + 18.0 + float(i) * 18.0 - 2.0, tb.position.y + 8.0), 1.6,
			_a(Color.WHITE, 0.50), true, -1.0, true)
	c.draw_line(Vector2(tb.position.x + w * 0.105, tb.position.y - 2.0),
		Vector2(tb.position.x + w * 0.125, tb.position.y + h * 0.050), Color("#64748b"), 2.6, true)
	c.draw_line(Vector2(tb.position.x + w * 0.105, tb.position.y - 2.0),
		Vector2(tb.position.x + w * 0.112, tb.position.y + h * 0.020), Color("#e2e8f0"), 1.2, true)
	# Olla a la derecha con cucharón y vapor.
	var ox := w * 0.80
	var oy := y_m + h * 0.012
	_elipse(c, Vector2(ox + 2.0, oy + 20.0), 36.0, 8.0, _a(Color(0.0, 0.0, 0.0), 0.15))
	c.draw_rect(Rect2(ox - 34.0, oy - 18.0, 68.0, 20.0), Color("#94a3b8"))
	c.draw_rect(Rect2(ox - 34.0, oy - 18.0, 68.0, 20.0), Color("#475569"), false, 1.4)
	_elipse(c, Vector2(ox, oy - 18.0), 34.0, 10.0, Color("#cbd5e1"))
	_elipse(c, Vector2(ox, oy - 18.0), 28.0, 7.0, Color("#f59e0b"))
	for i in range(3):
		c.draw_circle(Vector2(ox - 10.0 + float(i) * 10.0, oy - 18.0 + sin(t * 2.0 + float(i)) * 1.5), 2.2,
			Color("#f97316"), true, -1.0, true)
	c.draw_line(Vector2(ox + 10.0, oy - 16.0), Vector2(ox + 22.0, oy - 36.0), Color("#78350f"), 3.0, true)
	c.draw_circle(Vector2(ox + 22.0, oy - 37.0), 4.0, Color("#78350f"), true, -1.0, true)
	c.draw_line(Vector2(ox + 34.0, oy + 2.0), Vector2(ox + 44.0, oy + 2.0), Color("#475569"), 3.0, true)
	for i in range(3):
		var p2 := fmod(t * 0.6 + float(i) * 0.3, 1.0)
		c.draw_circle(Vector2(ox - 8.0 + float(i) * 8.0 + sin(t * 2.4 + float(i)) * 3.0,
			oy - 28.0 - p2 * 26.0), 3.2 * (1.0 - p2 * 0.4), _a(Color.WHITE, (1.0 - p2) * 0.38), true, -1.0, true)
	# Toalla colgada del tirador del horno.
	var tow := Rect2(w * 0.405, y_m + h * 0.055, w * 0.050, h * 0.095)
	c.draw_rect(tow, Color("#fda4af"))
	c.draw_rect(tow, Color("#9f1239"), false, 1.0)
	for i in range(3):
		c.draw_line(Vector2(tow.position.x + 4.0 + float(i) * 5.0, tow.position.y + 2.0),
			Vector2(tow.position.x + 4.0 + float(i) * 5.0, tow.end.y - 2.0), _a(Color("#fecdd3"), 0.6), 1.0)
	# Vapor y brillos.
	_vapor(c, Vector2(cx, pan.y - 12.0), t, 0.42, 4)
	if v == "oler_guiso" and esc._personaje != null:
		var nariz: Vector2 = esc._personaje.obtener_punto_local_a_escena(Vector2(0.0, 10.0))
		for i in range(3):
			var p_a := fmod(t * 0.7 + float(i) * 0.33, 1.0)
			var pts_a := PackedVector2Array()
			for s_i in range(8):
				var u := float(s_i) / 7.0
				var base_pt: Vector2 = Vector2(cx - 14.0 + float(i) * 14.0, pan.y - 8.0).lerp(
					nariz + Vector2(float(i - 1) * 7.0, 4.0), clampf(u * 0.7 + p_a * 0.3, 0.0, 1.0))
				var onda := sin(u * PI * 2.4 + t * 4.0 + float(i) * 2.0) * (4.5 * sin(u * PI))
				pts_a.append(base_pt + Vector2(onda, 0.0))
			var alpha_a := sin(p_a * PI) * 0.55
			if alpha_a > 0.03:
				c.draw_polyline(pts_a, Color("#fef3c7", alpha_a), 2.4, true)
	if v == "probar":
		for i in range(3):
			_destello(c, Vector2(cx + 44.0 + float(i) * 7.0, h * 0.34 - float(i) * 6.0),
				3.0 + sin(t * 9.0 + float(i)) * 1.2, Color("#fde047", 0.9))


static func _frente_fiesta(c: CanvasItem, _esc, w: float, h: float, t: float, v: String) -> void:
	var cx := w * 0.5
	# Pools de luz en la pista.
	var colores: Array[Color] = [Color("#ec4899"), Color("#38bdf8"), Color("#a855f7"), Color("#f59e0b")]
	for i in range(4):
		var rx := w * (0.16 + float(i) * 0.23) + sin(t * 1.2 + float(i) * 1.8) * 14.0
		_elipse(c, Vector2(rx, h * 0.92), 42.0, 9.0, _a(colores[i], 0.18))
	# Confeti y notas flotando.
	for i in range(10):
		var p := fmod(t * 0.45 + float(i) * 0.117, 1.0)
		var px := w * (0.10 + 0.08 * float(i % 10)) + sin(t * 1.4 + float(i)) * 10.0
		var py := h * (0.85 - p * 0.70)
		c.draw_rect(Rect2(px, py, 3.0 + float(i % 2), 2.0), _a(colores[i % colores.size()], 1.0 - p * 0.6))
	for i in range(3):
		var p2 := fmod(t * 0.75 + float(i) * 0.33, 1.0)
		var nx := cx + (-70.0 if i % 2 == 0 else 66.0) + sin(t * 4.0 + float(i)) * 10.0
		var ny := h * 0.55 - p2 * h * 0.38
		_nota(c, Vector2(nx, ny), Color(colores[i % colores.size()], 1.0 - p2))
	# Siluetas de público en primer plano, escalonadas y más pequeñas.
	var silueta := Color(0.02, 0.01, 0.05, 0.88)
	for i in range(4):
		var lado := -1.0 if i % 2 == 0 else 1.0
		var bx := cx + lado * w * (0.41 + 0.075 * float(i / 2))
		var by := h * 0.985 + float(i / 2) * h * 0.015 + sin(t * 3.0 + float(i) * 1.7) * 2.0
		var cabeza_r := 12.0 + float(i % 2) * 2.0
		c.draw_circle(Vector2(bx, by - 24.0), cabeza_r, silueta, true, -1.0, true)
		_panel(c, Rect2(bx - 18.0 - float(i % 2) * 4.0, by - 13.0, 36.0 + float(i % 2) * 8.0, 40.0),
			9.0, silueta)
		c.draw_line(Vector2(bx - lado * 15.0, by - 8.0),
			Vector2(bx - lado * 30.0, by - 40.0 + sin(t * 4.0 + float(i)) * 9.0), silueta, 7.0, true)
		c.draw_circle(Vector2(bx - lado * 30.0, by - 40.0 + sin(t * 4.0 + float(i)) * 9.0), 3.8,
			silueta, true, -1.0, true)
	if v == "brindar":
		for i in range(3):
			_destello(c, Vector2(cx + 40.0 + float(i) * 12.0, h * 0.32 - float(i) * 8.0),
				3.0 + sin(t * 10.0 + float(i)) * 1.5, Color("#fde047", 0.9))
	elif v == "saltar":
		for i in range(8):
			var ang := TAU * float(i) / 8.0 + t * 0.8
			var dist := 26.0 + fmod(t * 40.0, 30.0)
			var p_s := Vector2(cx + cos(ang) * dist, h * 0.56 + sin(ang) * dist * 0.6)
			c.draw_rect(Rect2(p_s, Vector2(3.0, 2.0)),
				_a(colores[i % colores.size()], 0.85))
	_vignette(c, w, h, 0.28)


static func _frente_futbol(c: CanvasItem, _esc, w: float, h: float, t: float, v: String) -> void:
	var cx := w * 0.5
	# Sombra del jugador y del balón.
	_sombra(c, Vector2(cx + 2.0, h * 0.955), 26.0, 5.0, 0.20)
	var bote := absf(sin(t * 6.5)) * 22.0
	var bx := cx + 38.0 + (sin(t * 3.0) * 16.0 if v == "toques" else 0.0)
	var by := h - 22.0 - bote
	_sombra(c, Vector2(bx, h * 0.955), 13.0, 3.4, 0.16)
	# Balón con pentágonos que giran.
	c.draw_circle(Vector2(bx, by), 14.0, Color.WHITE, true, -1.0, true)
	var giro := t * (4.0 if v == "toques" else 2.0)
	for i in range(5):
		var ang := TAU * float(i) / 5.0 + giro
		var px := bx + cos(ang) * 7.2
		var py := by + sin(ang) * 7.2
		c.draw_circle(Vector2(px, py), 2.8, TINTA, true, -1.0, true)
	c.draw_circle(Vector2(bx, by), 3.8, TINTA, true, -1.0, true)
	c.draw_circle(Vector2(bx, by), 14.0, TINTA, false, 1.8)
	c.draw_circle(Vector2(bx - 4.0, by - 4.0), 3.0, Color(1.0, 1.0, 1.0, 0.55), true, -1.0, true)
	# Chispas de césped al botar.
	for i in range(3):
		var p := fmod(t * 2.0 + float(i) * 0.33, 1.0)
		c.draw_circle(Vector2(bx - 12.0 - p * 16.0, h * 0.94 - sin(p * PI) * 8.0), 2.0 * (1.0 - p),
			Color("#166534", 0.55), true, -1.0, true)
	if v == "celebrar_gol":
		for i in range(4):
			_estrella(c, Vector2(cx - 62.0 + float(i) * 42.0, h * 0.18 + sin(t * 9.0 + float(i)) * 8.0),
				5.0 + sin(t * 10.0 + float(i)) * 2.0, Color("#facc15"))
	# Briznas en primer plano.
	for i in range(9):
		var fx := w * fmod(0.02 + float(i) * 0.113, 1.0)
		var fy := h * (0.94 + 0.025 * float(i % 3))
		c.draw_line(Vector2(fx, fy), Vector2(fx - 3.0, fy - 6.0), Color("#14532d"), 1.2)
	if v == "toques":
		for i in range(4):
			var ty := by + 14.0 + float(i) * 4.0
			c.draw_line(Vector2(bx - 10.0, ty), Vector2(bx + 10.0, ty), _a(Color.WHITE, 0.22), 1.0)
	elif v == "regate":
		for i in range(4):
			var lx := cx - 26.0 - float(i) * 13.0
			var ly := h * (0.78 + float(i) * 0.035)
			c.draw_line(Vector2(lx, ly), Vector2(lx - 18.0, ly), _a(Color.WHITE, 0.30), 1.6, true)


static func _frente_trabajar(c: CanvasItem, esc, w: float, h: float, t: float, v: String) -> void:
	var cx := w * 0.5
	var y_m := h * 0.795
	# Escritorio moderno con canto y faldón.
	_madera(c, Rect2(0.0, y_m, w, h * 0.06), Color("#94a3b8"), true, 0.5)
	c.draw_rect(Rect2(0.0, y_m, w, maxf(2.0, h * 0.010)), Color("#e2e8f0"))
	c.draw_line(Vector2(0.0, y_m), Vector2(w, y_m), Color("#475569"), 2.0)
	c.draw_rect(Rect2(0.0, y_m + h * 0.06, w, h - y_m - h * 0.06), Color("#334155"))
	# Cajoneras del escritorio con tiradores.
	for i in range(4):
		var dx := w * (0.015 + float(i) * 0.245)
		var dw := w * 0.225
		c.draw_rect(Rect2(dx, y_m + h * 0.075, dw, h * 0.105), Color("#3f4b60"))
		c.draw_rect(Rect2(dx, y_m + h * 0.075, dw, h * 0.105), Color("#1e293b"), false, 1.2)
		c.draw_rect(Rect2(dx + dw * 0.38, y_m + h * 0.095, dw * 0.24, maxf(2.0, h * 0.011)),
			Color("#94a3b8"))
	# Portátil abierto frente al Sim, con brillo.
	var lap := Rect2(cx - 52.0, y_m - 40.0, 104.0, 45.0)
	c.draw_rect(lap, Color("#1e293b"))
	c.draw_rect(lap, Color("#0f172a"), false, 2.0)
	var scr := Rect2(lap.position.x + 7.0, lap.position.y + 6.0, lap.size.x - 14.0, lap.size.y - 13.0)
	_grad_v(c, scr, Color("#0ea5e9"), Color("#1e3a8a"), 8)
	for i in range(3):
		var gy := scr.position.y + scr.size.y * (0.30 + float(i) * 0.20)
		c.draw_line(Vector2(scr.position.x + 10.0, gy), Vector2(scr.end.x - 10.0, gy),
			_a(Color.WHITE, 0.20), 1.0)
	c.draw_rect(Rect2(scr.position.x + 12.0, scr.position.y + 6.0, scr.size.x * 0.5, 4.0),
		_a(Color.WHITE, 0.45))
	for i in range(3):
		var bh := 10.0 + float(i % 2) * 8.0
		c.draw_rect(Rect2(scr.position.x + 14.0 + float(i) * 12.0, scr.end.y - 8.0 - bh, 7.0, bh),
			_a(Color("#38bdf8"), 0.75))
	c.draw_rect(Rect2(scr.position.x + 2.0, scr.position.y + 2.0, scr.size.x - 4.0, scr.size.y - 4.0),
		Color(1.0, 1.0, 1.0, 0.08))
	# Teclado y base.
	var base := Rect2(cx - 62.0, y_m + 2.0, 124.0, 9.0)
	c.draw_rect(base, Color("#475569"))
	c.draw_rect(base, Color("#1e293b"), false, 1.2)
	for i in range(9):
		c.draw_rect(Rect2(base.position.x + 5.0 + float(i) * 13.0, base.position.y + 2.0, 10.0, 4.0),
			Color("#94a3b8"))
	# Brillo del portátil sobre la mesa.
	_elipse(c, Vector2(cx, y_m + 12.0), 70.0, 9.0, _a(Color("#38bdf8"), 0.12))
	# Taza humeante a la izquierda.
	var mx := w * 0.14
	var my := y_m + 4.0
	c.draw_rect(Rect2(mx - 10.0, my - 16.0, 20.0, 17.0), Color("#f8fafc"))
	c.draw_rect(Rect2(mx - 10.0, my - 16.0, 20.0, 17.0), Color("#64748b"), false, 1.2)
	c.draw_arc(Vector2(mx + 10.0, my - 8.0), 5.0, -PI * 0.5, PI * 0.5, 8, Color("#64748b"), 1.6, true)
	for i in range(2):
		var p := fmod(t * 0.55 + float(i) * 0.4, 1.0)
		c.draw_circle(Vector2(mx - 3.0 + float(i) * 6.0 + sin(t * 2.0 + float(i)) * 2.0,
			my - 20.0 - p * 16.0), 2.4 * (1.0 - p * 0.4), _a(Color.WHITE, (1.0 - p) * 0.35), true, -1.0, true)
	# Papeles y notas adhesivas.
	c.draw_rect(Rect2(w * 0.70, y_m + 3.0, 46.0, 28.0), Color("#f8fafc"))
	c.draw_rect(Rect2(w * 0.70, y_m + 3.0, 46.0, 28.0), Color("#94a3b8"), false, 1.0)
	for i in range(4):
		c.draw_line(Vector2(w * 0.705, y_m + 8.0 + float(i) * 5.0),
			Vector2(w * 0.70 + 38.0 - float(i % 2) * 10.0, y_m + 8.0 + float(i) * 5.0),
			_a(Color("#64748b"), 0.55), 1.0)
	for i in range(2):
		c.draw_rect(Rect2(w * 0.84 + float(i) * 15.0, y_m + 1.0, 12.0, 12.0),
			Color("#fef08a") if i == 0 else Color("#fca5a5"))
	# Portalápices.
	var vx := w * 0.90
	var vy := y_m + 2.0
	c.draw_rect(Rect2(vx - 7.0, vy - 19.0, 14.0, 20.0), Color("#c7d2fe"))
	c.draw_rect(Rect2(vx - 7.0, vy - 19.0, 14.0, 20.0), Color("#475569"), false, 1.0)
	for i in range(3):
		c.draw_line(Vector2(vx - 4.0 + float(i) * 4.0, vy - 17.0),
			Vector2(vx - 6.0 + float(i) * 5.0, vy - 30.0), Color("#0ea5e9"), 1.6, true)
	# Silla y mesa: reflejo del monitor.
	c.draw_rect(Rect2(0.0, h * 0.985, w, h * 0.015), Color(0.0, 0.0, 0.0, 0.20))
	if v == "ganar_dinero":
		for i in range(3):
			var p2 := fmod(t * 0.9 + float(i) * 0.33, 1.0)
			var ex := cx + 48.0 + float(i) * 16.0
			var ey := h * 0.45 - p2 * h * 0.28
			c.draw_string(FUENTE_COMIC, Vector2(ex, ey), "€", HORIZONTAL_ALIGNMENT_LEFT, -1, 18,
				Color("#16a34a", 1.0 - p2))
	elif v == "estirar_cuello":
		for i in range(2):
			var sx := cx - 34.0 + float(i) * 68.0
			c.draw_arc(Vector2(sx, h * 0.27), 14.0, -PI * 0.35, PI * 0.35, 8,
				_a(Color("#fde047"), 0.55), 1.6, true)
	_motas(c, Rect2(w * 0.10, h * 0.20, w * 0.75, h * 0.55), t, 3, _a(Color.WHITE, 0.24), 0.5)


# ---------------------------------------------------------------- helpers de efectos

static func _estrella(c: CanvasItem, centro: Vector2, r: float, col: Color, puntas: int = 8) -> void:
	if r <= 0.2:
		return
	var pts := PackedVector2Array()
	for i in range(puntas * 2):
		var ang := TAU * float(i) / float(puntas * 2)
		var rad := r if i % 2 == 0 else r * 0.36
		pts.append(centro + Vector2(cos(ang), sin(ang)) * rad)
	c.draw_colored_polygon(pts, col)


static func _corazon(c: CanvasItem, centro: Vector2, r: float, col: Color) -> void:
	c.draw_circle(centro + Vector2(-r * 0.42, -r * 0.25), r * 0.50, col, true, -1.0, true)
	c.draw_circle(centro + Vector2(r * 0.42, -r * 0.25), r * 0.50, col, true, -1.0, true)
	c.draw_colored_polygon(PackedVector2Array([
		centro + Vector2(-r * 0.88, -r * 0.05),
		centro + Vector2(r * 0.88, -r * 0.05),
		centro + Vector2(0.0, r * 0.92),
	]), col)


static func _nota(c: CanvasItem, pos: Vector2, col: Color) -> void:
	c.draw_circle(pos, 4.5, col, true, -1.0, true)
	c.draw_line(pos + Vector2(3.8, 0.0), pos + Vector2(3.8, -15.0), col, 2.4, true)
	c.draw_line(pos + Vector2(3.8, -15.0), pos + Vector2(10.5, -11.0), col, 2.6, true)


static func _destello(c: CanvasItem, centro: Vector2, r: float, col: Color) -> void:
	if r <= 0.2:
		return
	c.draw_line(centro + Vector2(-r, 0.0), centro + Vector2(r, 0.0), col, 1.6, true)
	c.draw_line(centro + Vector2(0.0, -r), centro + Vector2(0.0, r), col, 1.6, true)
	c.draw_circle(centro, r * 0.28, col, true, -1.0, true)


static func _vapor(c: CanvasItem, origen: Vector2, t: float, opacidad: float, cantidad: int = 3) -> void:
	for i in range(cantidad):
		var fase := fmod(t * 0.55 + float(i) * (1.0 / float(maxi(1, cantidad))), 1.0)
		var base_x := origen.x - 14.0 + float(i) * 14.0
		var pts := PackedVector2Array()
		for s in range(7):
			var u := float(s) / 6.0
			var px := base_x + sin(u * PI * 2.2 + t * 3.4 + float(i) * 1.9) * (3.2 + u * 2.4)
			var py := origen.y - fase * 10.0 - u * 24.0
			pts.append(Vector2(px, py))
		var alpha := sin(fase * PI) * opacidad
		if alpha > 0.03:
			c.draw_polyline(pts, Color(1.0, 1.0, 1.0, alpha), 2.2, true)
