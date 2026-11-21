class_name Sprites_Cocina
extends RefCounted

# ============================================================================
# Sprites vectoriales 2.5D de cocina casual para Minijuego_Cocina.
# Todos los controles internos usan MOUSE_FILTER_IGNORE y _draw() nativo
# para funcionar sin dependencias externas en Desktop, Android APK y GUT.
# ============================================================================

const TINTA := Color("#2b1810")
const TINTA_SUAVE := Color("#475569")
const FUENTE_UI := preload("res://Fuentes/UI/DMSans-700.ttf")
const FUENTE_TIT := preload("res://Fuentes/UI/Bricolage-800.ttf")


# ============================================================================
# Primitivas geométricas y sombreado 2.5D
# ============================================================================

static func elipse(centro: Vector2, rx: float, ry: float, segs: int = 24, rot: float = 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var ca := cos(rot)
	var sa := sin(rot)
	for i in range(segs):
		var a := TAU * float(i) / float(segs)
		var lx := cos(a) * rx
		var ly := sin(a) * ry
		pts.append(centro + Vector2(lx * ca - ly * sa, lx * sa + ly * ca))
	return pts


static func dibujar_elipse(c: CanvasItem, centro: Vector2, rx: float, ry: float,
		relleno: Color, borde: Color = Color.TRANSPARENT, grosor: float = 1.6,
		rot: float = 0.0, segs: int = 24) -> void:
	var pts := elipse(centro, rx, ry, segs, rot)
	c.draw_colored_polygon(pts, relleno)
	if borde.a > 0.01 and grosor > 0.0:
		var cerr := PackedVector2Array(pts)
		cerr.append(pts[0])
		c.draw_polyline(cerr, borde, grosor, true)


static func rect_redondeado(rect: Rect2, r: float, segs_esq: int = 5) -> PackedVector2Array:
	var rad := clampf(r, 0.0, minf(rect.size.x, rect.size.y) * 0.5)
	if rad <= 0.5:
		return PackedVector2Array([
			rect.position,
			Vector2(rect.end.x, rect.position.y),
			rect.end,
			Vector2(rect.position.x, rect.end.y)
		])
	var pts := PackedVector2Array()
	var esquinas: Array = [
		[Vector2(rect.end.x - rad, rect.position.y + rad), -PI * 0.5, 0.0],
		[Vector2(rect.end.x - rad, rect.end.y - rad), 0.0, PI * 0.5],
		[Vector2(rect.position.x + rad, rect.end.y - rad), PI * 0.5, PI],
		[Vector2(rect.position.x + rad, rect.position.y + rad), PI, PI * 1.5],
	]
	for esq in esquinas:
		var cen: Vector2 = esq[0]
		var a0: float = esq[1]
		var a1: float = esq[2]
		for s in range(segs_esq + 1):
			var a := lerpf(a0, a1, float(s) / float(segs_esq))
			pts.append(cen + Vector2(cos(a), sin(a)) * rad)
	return pts


static func dibujar_caja(c: CanvasItem, rect: Rect2, r: float, relleno: Color,
		borde: Color = Color.TRANSPARENT, grosor: float = 1.6) -> void:
	var pts := rect_redondeado(rect, r)
	c.draw_colored_polygon(pts, relleno)
	if borde.a > 0.01 and grosor > 0.0:
		var cerr := PackedVector2Array(pts)
		cerr.append(pts[0])
		c.draw_polyline(cerr, borde, grosor, true)


static func dibujar_poligono_borde(c: CanvasItem, pts: PackedVector2Array,
		relleno: Color, borde: Color = Color.TRANSPARENT, grosor: float = 1.6) -> void:
	c.draw_colored_polygon(pts, relleno)
	if borde.a > 0.01 and grosor > 0.0 and pts.size() >= 2:
		var cerr := PackedVector2Array(pts)
		cerr.append(pts[0])
		c.draw_polyline(cerr, borde, grosor, true)


static func dibujar_moneda(c: CanvasItem, centro: Vector2, radio: float) -> void:
	dibujar_elipse(c, centro + Vector2(0.0, radio * 0.22), radio, radio * 0.58, Color("#b45309"), Color("#78350f"), 1.2)
	dibujar_elipse(c, centro, radio, radio * 0.56, Color("#facc15"), Color("#92400e"), 1.4)
	dibujar_elipse(c, centro + Vector2(-radio * 0.10, -radio * 0.08), radio * 0.68, radio * 0.34, Color("#fef08a", 0.75))


static func dibujar_pila_monedas(c: CanvasItem, base: Vector2, cantidad: int, radio: float = 11.0) -> void:
	dibujar_elipse(c, base + Vector2(2.0, 3.0), radio * 1.15, radio * 0.52, Color(0.0, 0.0, 0.0, 0.22))
	for i in range(clampi(cantidad, 1, 7)):
		dibujar_moneda(c, base + Vector2(0.0, -float(i) * (radio * 0.34)), radio)


static func dibujar_vapor(c: CanvasItem, origen: Vector2, tiempo: float, opacidad: float,
		ancho: float = 16.0, alto: float = 22.0, es_humo: bool = false) -> void:
	var col_base := Color(0.22, 0.20, 0.19) if es_humo else Color(1.0, 0.98, 0.94)
	for i in range(3):
		var fase := fmod(tiempo * (0.95 if es_humo else 0.72) + float(i) * 0.33, 1.0)
		var base_x := origen.x + (float(i) - 1.0) * (ancho * 0.45)
		var pts := PackedVector2Array()
		for s in range(6):
			var u := float(s) / 5.0
			var px := base_x + sin(u * PI * 2.2 + tiempo * 3.8 + float(i) * 2.1) * (2.5 + u * 3.5)
			var py := origen.y - fase * (alto * 0.35) - u * alto
			pts.append(Vector2(px, py))
		var alpha := sin(fase * PI) * opacidad
		if alpha > 0.03:
			c.draw_polyline(pts, Color(col_base, alpha), 3.2 if es_humo else 2.2, true)


static func dibujar_burbujas_aceite(c: CanvasItem, centro: Vector2, radio: float, tiempo: float, cantidad: int = 6) -> void:
	for i in range(cantidad):
		var p := fmod(tiempo * 1.65 + float(i) * (1.0 / float(cantidad)), 1.0)
		var ang: float = float(i) * 2.39996 + floor(tiempo * 1.65 + float(i) * 0.2) * 1.3
		var dist := (0.28 + 0.55 * fmod(float(i) * 0.37, 1.0)) * radio
		var pos := centro + Vector2(cos(ang) * dist, sin(ang) * dist * 0.72 - p * 4.0)
		var r_b := (1.5 + sin(p * PI) * 2.2)
		var alpha := sin(p * PI) * 0.85
		if alpha > 0.05:
			c.draw_circle(pos, r_b, Color(1.0, 0.96, 0.78, alpha))


# ============================================================================
# Sprites de Comida 2.5D (compartidos entre cocina y burbujas de pedido)
# ============================================================================

static func dibujar_plato_ceramica(c: CanvasItem, centro: Vector2, rx: float, ry: float,
		brillo_estado: Color = Color.TRANSPARENT) -> void:
	dibujar_elipse(c, centro + Vector2(2.0, 4.2), rx * 1.03, ry * 1.05, Color(0.0, 0.0, 0.0, 0.20))
	if brillo_estado.a > 0.05:
		dibujar_elipse(c, centro, rx * 1.12, ry * 1.14, Color(brillo_estado, brillo_estado.a * 0.28),
			brillo_estado, 2.4)
	dibujar_elipse(c, centro + Vector2(0.0, 2.6), rx * 0.94, ry * 0.95, Color("#cbd5e1"), Color("#64748b"), 1.4)
	dibujar_elipse(c, centro, rx, ry, Color("#ffffff"), Color("#94a3b8"), 1.6)
	dibujar_elipse(c, centro + Vector2(0.0, 0.8), rx * 0.74, ry * 0.70, Color("#eef2f6"), Color("#cbd5e1"), 1.0)
	c.draw_arc(centro, rx * 0.86, PI * 1.08, PI * 1.42, 10, Color(1.0, 1.0, 1.0, 0.9), 2.0, true)


static func dibujar_carne_cocida(c: CanvasItem, centro: Vector2, rx: float, ry: float,
		tostado: float = 1.0, quemada: bool = false) -> void:
	# tostado: 0.0 = cruda rosa, 1.0 = hecha jugosa
	var col_lado := Color("#be185d").lerp(Color("#451a03"), tostado)
	var col_top := Color("#fb7185").lerp(Color("#7c2d12"), tostado)
	var col_luz := Color("#fda4af").lerp(Color("#b45309"), tostado)
	if quemada:
		col_lado = Color("#0c0a09")
		col_top = Color("#1c1917")
		col_luz = Color("#292524")

	dibujar_elipse(c, centro + Vector2(0.0, ry * 0.36), rx, ry * 0.92, col_lado, TINTA, 1.4)
	dibujar_elipse(c, centro, rx, ry * 0.88, col_top, TINTA, 1.4)
	dibujar_elipse(c, centro + Vector2(-rx * 0.12, -ry * 0.14), rx * 0.65, ry * 0.48, Color(col_luz, 0.72))

	if tostado > 0.65 and not quemada:
		for g in range(-1, 2):
			var gx := float(g) * rx * 0.36
			c.draw_line(centro + Vector2(gx - rx * 0.16, -ry * 0.42),
				centro + Vector2(gx + rx * 0.20, ry * 0.32), Color("#3b1506", 0.72), maxf(1.4, rx * 0.08), true)
	elif quemada:
		for g in range(-1, 2):
			var gx := float(g) * rx * 0.32
			c.draw_line(centro + Vector2(gx - rx * 0.12, -ry * 0.25),
				centro + Vector2(gx + rx * 0.14, ry * 0.25), Color("#57534e", 0.7), 1.4, true)


static func dibujar_hamburguesa(c: CanvasItem, centro: Vector2, escala: float,
		tiene_pan: bool, carnes: int, queso: bool, lechuga: bool, tomate: bool,
		con_plato: bool = true, brillo_plato: Color = Color.TRANSPARENT) -> void:
	if con_plato:
		dibujar_plato_ceramica(c, centro + Vector2(0.0, 8.0 * escala), 46.0 * escala, 22.0 * escala, brillo_plato)
	if not tiene_pan:
		return

	var base_y := centro.y + (9.0 * escala if con_plato else 12.0 * escala)
	var w_bun := 28.0 * escala

	# Sombra de la burger sobre el plato
	dibujar_elipse(c, Vector2(centro.x + 1.0 * escala, base_y + 2.0 * escala), w_bun * 0.98, 9.0 * escala, Color(0.0, 0.0, 0.0, 0.18))

	# Pan inferior
	dibujar_elipse(c, Vector2(centro.x, base_y), w_bun * 0.94, 9.2 * escala, Color("#b45309"), TINTA, maxf(1.0, 1.5 * escala))
	dibujar_elipse(c, Vector2(centro.x, base_y - 3.2 * escala), w_bun * 0.94, 8.6 * escala, Color("#eab308"), TINTA, maxf(1.0, 1.3 * escala))
	dibujar_elipse(c, Vector2(centro.x, base_y - 3.6 * escala), w_bun * 0.76, 5.8 * escala, Color("#fef3c7", 0.55))

	var y_cur := base_y - 6.8 * escala

	# Carnes (1 o 2)
	for _i in range(carnes):
		dibujar_carne_cocida(c, Vector2(centro.x, y_cur), w_bun * 0.98, 9.2 * escala, 1.0, false)
		y_cur -= 7.2 * escala

	# Queso cheddar fundido
	if queso:
		var q_y := y_cur + 2.5 * escala
		var pts_q := PackedVector2Array([
			Vector2(centro.x - w_bun * 1.04, q_y - 2.0 * escala),
			Vector2(centro.x, q_y - 6.5 * escala),
			Vector2(centro.x + w_bun * 1.04, q_y - 2.0 * escala),
			Vector2(centro.x + w_bun * 0.58, q_y + 7.2 * escala),
			Vector2(centro.x + 2.0 * escala, q_y + 3.2 * escala),
			Vector2(centro.x - w_bun * 0.62, q_y + 7.6 * escala),
		])
		dibujar_poligono_borde(c, pts_q, Color("#facc15"), Color("#a16207"), maxf(1.0, 1.3 * escala))
		c.draw_line(Vector2(centro.x - w_bun * 0.55, q_y - 2.0 * escala),
			Vector2(centro.x + w_bun * 0.35, q_y - 3.5 * escala), Color("#fef9c3", 0.8), maxf(1.0, 1.6 * escala), true)
		y_cur -= 3.8 * escala

	# Lechuga rizada fresca
	if lechuga:
		var l_y := y_cur + 1.0 * escala
		var pts_l := PackedVector2Array()
		var lobulos := 12
		for k in range(lobulos):
			var ang := TAU * float(k) / float(lobulos)
			var onda := 1.08 if k % 2 == 0 else 0.86
			pts_l.append(Vector2(
				centro.x + cos(ang) * w_bun * 1.08 * onda,
				l_y + sin(ang) * 9.0 * escala * onda
			))
		dibujar_poligono_borde(c, pts_l, Color("#22c55e"), Color("#14532d"), maxf(1.0, 1.3 * escala))
		for k in range(-2, 3):
			c.draw_circle(Vector2(centro.x + float(k) * 9.5 * escala, l_y + absf(float(k)) * 0.8 * escala),
				3.4 * escala, Color("#86efac", 0.72))
		y_cur -= 4.2 * escala

	# Rodajas de tomate
	if tomate:
		var t_y := y_cur + 1.0 * escala
		for dx_t: float in [-9.0, 9.0]:
			var ct := Vector2(centro.x + dx_t * escala, t_y)
			dibujar_elipse(c, ct + Vector2(0.0, 2.0 * escala), 13.5 * escala, 5.2 * escala, Color("#b91c1c"), TINTA, maxf(0.9, 1.1 * escala))
			dibujar_elipse(c, ct, 13.5 * escala, 5.0 * escala, Color("#ef4444"), Color("#991b1b"), maxf(0.9, 1.1 * escala))
			dibujar_elipse(c, ct + Vector2(-2.0 * escala, -0.8 * escala), 7.0 * escala, 2.2 * escala, Color("#fca5a5", 0.55))
		y_cur -= 4.2 * escala

	# Pan superior abombado con semillas de sésamo
	var top_y := y_cur - 3.5 * escala
	var domo := PackedVector2Array([
		Vector2(centro.x - w_bun * 0.98, top_y + 4.5 * escala),
		Vector2(centro.x - w_bun * 0.92, top_y - 7.5 * escala),
		Vector2(centro.x - w_bun * 0.48, top_y - 14.5 * escala),
		Vector2(centro.x, top_y - 16.5 * escala),
		Vector2(centro.x + w_bun * 0.48, top_y - 14.5 * escala),
		Vector2(centro.x + w_bun * 0.92, top_y - 7.5 * escala),
		Vector2(centro.x + w_bun * 0.98, top_y + 4.5 * escala),
		Vector2(centro.x + w_bun * 0.55, top_y + 8.5 * escala),
		Vector2(centro.x, top_y + 9.4 * escala),
		Vector2(centro.x - w_bun * 0.55, top_y + 8.5 * escala),
	])
	dibujar_poligono_borde(c, domo, Color("#c26415"), TINTA, maxf(1.0, 1.6 * escala))
	# Zona dorada media y brillo superior
	dibujar_elipse(c, Vector2(centro.x, top_y - 4.0 * escala), w_bun * 0.76, 8.6 * escala, Color("#ea8c25", 0.85))
	dibujar_elipse(c, Vector2(centro.x - 4.0 * escala, top_y - 8.8 * escala), w_bun * 0.48, 4.4 * escala, Color("#fcd34d", 0.65))
	# Semillas de sésamo
	var semillas: Array[Vector3] = [
		Vector3(-12.0, -7.5, -0.35), Vector3(-4.0, -10.5, 0.2), Vector3(5.0, -10.2, -0.25),
		Vector3(13.0, -6.8, 0.4), Vector3(-7.0, -4.5, 0.15), Vector3(2.0, -5.2, -0.2),
		Vector3(10.0, -2.8, 0.3)
	]
	for sm in semillas:
		dibujar_elipse(c, Vector2(centro.x + sm.x * escala, top_y + sm.y * escala),
			2.4 * escala, 1.15 * escala, Color("#fef3c7"), Color("#92400e", 0.55), 0.7, sm.z, 10)


static func dibujar_patatas(c: CanvasItem, centro: Vector2, escala: float,
		quemado: bool = false, cocinando: bool = false, tiempo: float = 0.0) -> void:
	dibujar_elipse(c, centro + Vector2(1.5 * escala, 20.0 * escala), 20.0 * escala, 6.5 * escala, Color(0.0, 0.0, 0.0, 0.22))

	# Fondo curvo interior de la caja
	var col_fondo_caja := Color("#451a03") if quemado else Color("#eab308")
	dibujar_elipse(c, centro + Vector2(0.0, -8.0 * escala), 17.5 * escala, 9.5 * escala, col_fondo_caja, TINTA, maxf(1.0, 1.4 * escala))

	# Patatas sobresaliendo en abanico
	var palos: Array[Array] = [
		[-12.0, -24.0, -0.26, 20.0],
		[-8.0, -28.0, -0.15, 24.0],
		[-3.5, -30.0, -0.05, 26.0],
		[1.0, -29.0, 0.06, 25.0],
		[6.0, -27.0, 0.16, 24.0],
		[10.5, -23.0, 0.27, 20.0],
		[-10.0, -20.0, -0.18, 18.0],
		[-1.5, -24.0, 0.02, 22.0],
		[7.5, -21.0, 0.20, 19.0],
	]
	for p in palos:
		var fx: float = centro.x + float(p[0]) * escala
		var fy: float = centro.y + float(p[1]) * escala
		var ang: float = float(p[2])
		var lar: float = float(p[3]) * escala
		var anch: float = 4.4 * escala
		var dir := Vector2(sin(ang), cos(ang))
		var perp := Vector2(cos(ang), -sin(ang)) * (anch * 0.5)
		var p0 := Vector2(fx, fy)
		var p1 := p0 + dir * lar
		var pts_f := PackedVector2Array([p0 - perp, p0 + perp, p1 + perp, p1 - perp])
		var col_f := Color("#292524") if quemado else (Color("#f59e0b") if cocinando else Color("#fde047"))
		var col_b := Color("#0c0a09") if quemado else Color("#b45309")
		dibujar_poligono_borde(c, pts_f, col_f, col_b, maxf(0.8, 1.1 * escala))
		if not quemado:
			c.draw_line(p0, p1 - dir * 2.0 * escala, Color("#fef9c3", 0.75), maxf(1.0, 1.3 * escala), true)

	# Cartón clásico rojo con rayas amarillas
	var cup := PackedVector2Array([
		centro + Vector2(-17.5 * escala, -6.5 * escala),
		centro + Vector2(-6.0 * escala, -2.5 * escala),
		centro + Vector2(6.0 * escala, -2.5 * escala),
		centro + Vector2(17.5 * escala, -6.5 * escala),
		centro + Vector2(12.5 * escala, 19.0 * escala),
		centro + Vector2(-12.5 * escala, 19.0 * escala),
	])
	var col_rojo := Color("#450a0a") if quemado else Color("#dc2626")
	dibujar_poligono_borde(c, cup, col_rojo, TINTA, maxf(1.0, 1.5 * escala))
	# Rayas verticales amarillas
	if not quemado:
		for sx: float in [-8.0, 0.0, 8.0]:
			c.draw_line(
				centro + Vector2(sx * escala, -2.0 * escala),
				centro + Vector2(sx * 0.72 * escala, 17.5 * escala),
				Color("#facc15"), maxf(1.2, 2.8 * escala), true
			)
		# Emblema ovalado central
		dibujar_elipse(c, centro + Vector2(0.0, 7.5 * escala), 6.2 * escala, 4.4 * escala, Color("#fef3c7"), Color("#b91c1c"), 1.0)
	if cocinando:
		dibujar_vapor(c, centro + Vector2(0.0, -24.0 * escala), tiempo, 0.45, 14.0 * escala, 14.0 * escala, false)


static func dibujar_refresco(c: CanvasItem, centro: Vector2, escala: float,
		nivel_llenado: float = 1.0, tiempo: float = 0.0) -> void:
	var niv := clampf(nivel_llenado, 0.0, 1.0)
	dibujar_elipse(c, centro + Vector2(1.5 * escala, 22.0 * escala), 15.0 * escala, 5.0 * escala, Color(0.0, 0.0, 0.0, 0.20))

	# Pajita rayada roja y blanca saliendo por arriba
	var p_str0 := centro + Vector2(4.0 * escala, 14.0 * escala)
	var p_str1 := centro + Vector2(11.0 * escala, -28.0 * escala)
	c.draw_line(p_str0, p_str1, Color.WHITE, maxf(2.0, 4.0 * escala), true)
	for k in range(5):
		var u0 := float(k) / 5.0
		var u1 := u0 + 0.10
		c.draw_line(p_str0.lerp(p_str1, u0), p_str0.lerp(p_str1, u1), Color("#ef4444"), maxf(1.8, 3.6 * escala), true)

	# Rodaja de lima verde en el borde superior izquierdo (exacta a la captura)
	var c_lima := centro + Vector2(-12.0 * escala, -16.0 * escala)
	dibujar_elipse(c, c_lima, 8.2 * escala, 6.2 * escala, Color("#15803d"), TINTA, maxf(0.9, 1.2 * escala), -0.45)
	dibujar_elipse(c, c_lima, 6.2 * escala, 4.4 * escala, Color("#84cc16"), Color.TRANSPARENT, 0.0, -0.45)

	# Cuerpo del vaso de cristal
	var vaso := PackedVector2Array([
		centro + Vector2(-15.0 * escala, -15.0 * escala),
		centro + Vector2(15.0 * escala, -15.0 * escala),
		centro + Vector2(10.5 * escala, 20.5 * escala),
		centro + Vector2(-10.5 * escala, 20.5 * escala),
	])
	dibujar_poligono_borde(c, vaso, Color(0.84, 0.95, 1.0, 0.72), Color("#475569"), maxf(1.0, 1.5 * escala))

	# Líquido cola oscuro con nivel dinámico
	if niv > 0.04:
		var y_bot := 18.8 * escala
		var y_top := lerpf(y_bot - 2.0 * escala, -8.5 * escala, niv)
		var t_w := lerpf(9.6 * escala, 13.4 * escala, niv)
		var liq := PackedVector2Array([
			centro + Vector2(-t_w, y_top),
			centro + Vector2(t_w, y_top),
			centro + Vector2(9.4 * escala, y_bot),
			centro + Vector2(-9.4 * escala, y_bot),
		])
		c.draw_colored_polygon(liq, Color("#2a1205"))
		dibujar_elipse(c, centro + Vector2(0.0, y_top), t_w, 3.2 * escala, Color("#78350f"), Color("#451a03"), 0.8)
		# Cubitos de hielo flotando
		if niv > 0.45:
			dibujar_caja(c, Rect2(centro.x - 8.5 * escala, y_top - 3.2 * escala, 6.8 * escala, 5.8 * escala),
				1.5 * escala, Color(0.88, 0.97, 1.0, 0.72), Color.WHITE, 0.8)
			dibujar_caja(c, Rect2(centro.x + 1.0 * escala, y_top - 2.2 * escala, 6.2 * escala, 5.2 * escala),
				1.5 * escala, Color(0.88, 0.97, 1.0, 0.65), Color.WHITE, 0.8)
		# Burbujas efervescentes subiendo
		for b in range(4):
			var bp := fmod(tiempo * 1.4 + float(b) * 0.25, 1.0)
			var bx := centro.x + (float(b) - 1.5) * 4.5 * escala
			var by := lerpf(y_bot - 2.0 * escala, y_top + 2.0 * escala, bp)
			c.draw_circle(Vector2(bx, by), 1.4 * escala, Color("#fcd34d", 0.65 * (1.0 - bp)))

	# Borde elíptico del vaso y reflejo especular
	dibujar_elipse(c, centro + Vector2(0.0, -15.0 * escala), 15.0 * escala, 3.8 * escala,
		Color(1.0, 1.0, 1.0, 0.35), Color("#64748b"), maxf(0.9, 1.3 * escala))
	c.draw_line(centro + Vector2(-9.8 * escala, -10.0 * escala),
		centro + Vector2(-7.2 * escala, 16.0 * escala), Color(1.0, 1.0, 1.0, 0.78), maxf(1.2, 2.2 * escala), true)


static func dibujar_item_por_id(c: CanvasItem, item_id: String, centro: Vector2,
		escala: float, tiempo: float = 0.0) -> void:
	match item_id:
		"burger_sola":
			dibujar_hamburguesa(c, centro, escala, true, 1, false, false, false, true)
		"burger_queso":
			dibujar_hamburguesa(c, centro, escala, true, 1, true, false, false, true)
		"burger_completa":
			dibujar_hamburguesa(c, centro, escala, true, 1, true, true, true, true)
		"burger_doble":
			dibujar_hamburguesa(c, centro, escala, true, 2, true, false, false, true)
		"patatas":
			dibujar_patatas(c, centro, escala, false, false, tiempo)
		"refresco":
			dibujar_refresco(c, centro, escala, 1.0, tiempo)


# ============================================================================
# 1. Fondo del Diner (parte superior: suelo ajedrezado, mesas, barra turquesa)
# ============================================================================

class FondoDiner extends Control:
	var monedas_visibles: int = 0
	var tiempo: float = 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if size.x <= 2.0 or size.y <= 2.0:
			return
		var w := size.x
		var h := size.y
		var y_horiz := h * 0.45
		var y_barra := h - 28.0

		# Pared superior con degradado cielo/crema de diner luminoso
		draw_rect(Rect2(0.0, 0.0, w, y_horiz), Color("#dbeafe"))
		draw_rect(Rect2(0.0, y_horiz * 0.45, w, y_horiz * 0.55), Color("#fef3c7", 0.55))
		# Franja decorativa azul/cromo en la pared
		draw_rect(Rect2(0.0, y_horiz - 16.0, w, 16.0), Color("#93c5fd", 0.55))
		draw_line(Vector2(0.0, y_horiz), Vector2(w, y_horiz), Color("#64748b"), 2.0)

		# Ventanales y pósters retro de diner
		for px: float in [64.0, 390.0, 680.0, 960.0]:
			Sprites_Cocina.dibujar_caja(self, Rect2(px, 12.0, 74.0, 56.0), 4.0, Color("#fffbeb"), Color("#94a3b8"), 2.0)
			draw_rect(Rect2(px + 6.0, 18.0, 62.0, 44.0), Color("#fde68a", 0.65))
			Sprites_Cocina.dibujar_hamburguesa(self, Vector2(px + 37.0, 40.0), 0.36, true, 1, true, true, true, false)

		# Lámparas colgantes cálidas
		for lx: float in [190.0, 520.0, 840.0, 1130.0]:
			draw_line(Vector2(lx, 0.0), Vector2(lx, 18.0), Color("#334155"), 2.2)
			draw_circle(Vector2(lx, 24.0), 26.0, Color("#fef08a", 0.16))
			Sprites_Cocina.dibujar_poligono_borde(self, PackedVector2Array([
				Vector2(lx - 18.0, 22.0), Vector2(lx + 18.0, 22.0),
				Vector2(lx + 9.0, 12.0), Vector2(lx - 9.0, 12.0)
			]), Color("#0284c7"), Color("#1e293b"), 1.6)

		# Mueble rojo de diner al fondo a la derecha (como en la captura)
		Sprites_Cocina.dibujar_caja(self, Rect2(w - 130.0, y_horiz - 48.0, 114.0, 54.0), 4.0, Color("#b91c1c"), Color("#7f1d1d"), 2.0)
		draw_rect(Rect2(w - 122.0, y_horiz - 40.0, 98.0, 10.0), Color("#e2e8f0"))

		# Suelo ajedrezado en perspectiva (blanco y negro clásico)
		var filas := 5
		var cols := 18
		var cx := w * 0.5
		for f in range(filas):
			var t0 := float(f) / float(filas)
			var t1 := float(f + 1) / float(filas)
			var y0 := lerpf(y_horiz, y_barra, t0 * t0 * 0.35 + t0 * 0.65)
			var y1 := lerpf(y_horiz, y_barra, t1 * t1 * 0.35 + t1 * 0.65)
			var esc0 := lerpf(0.62, 1.25, t0)
			var esc1 := lerpf(0.62, 1.25, t1)
			for k in range(cols):
				var u0 := (float(k) / float(cols) - 0.5) * w
				var u1 := (float(k + 1) / float(cols) - 0.5) * w
				var tile := PackedVector2Array([
					Vector2(cx + u0 * esc0, y0),
					Vector2(cx + u1 * esc0, y0),
					Vector2(cx + u1 * esc1, y1),
					Vector2(cx + u0 * esc1, y1),
				])
				var es_oscuro := ((f + k) % 2 == 0)
				draw_colored_polygon(tile, Color("#334155") if es_oscuro else Color("#f1f5f9"))

		# Mesas redondas turquesa con sillas naranjas/rojas (exacto a la referencia)
		for mx: float in [118.0, 385.0, 745.0, 1085.0]:
			_dibujar_mesa_diner(Vector2(mx, y_horiz + 46.0))

		# Velo sutil atmosférico para que destaquen los clientes en primer plano
		draw_rect(Rect2(0.0, 0.0, w, y_barra), Color(1.0, 0.99, 0.96, 0.14))

		# Barra turquesa brillante del mostrador con moldura cromada
		draw_rect(Rect2(0.0, y_barra, w, 18.0), Color("#0d9488"))
		draw_rect(Rect2(0.0, y_barra, w, 6.0), Color("#2dd4bf", 0.85))
		draw_line(Vector2(0.0, y_barra), Vector2(w, y_barra), Color("#0f172a"), 2.0)
		# Borde metálico cromado
		var y_cromo := y_barra + 18.0
		draw_rect(Rect2(0.0, y_cromo, w, 10.0), Color("#94a3b8"))
		draw_rect(Rect2(0.0, y_cromo + 2.0, w, 3.0), Color("#f8fafc"))
		draw_line(Vector2(0.0, y_cromo), Vector2(w, y_cromo), Color("#334155"), 1.6)
		draw_line(Vector2(0.0, h - 1.0), Vector2(w, h - 1.0), Color("#1e293b"), 2.0)

		# Pilas de monedas doradas sobre la esquina derecha de la barra (como la captura)
		if monedas_visibles > 0:
			var cant_a := clampi(1 + monedas_visibles / 25, 2, 6)
			Sprites_Cocina.dibujar_pila_monedas(self, Vector2(w - 52.0, y_barra + 8.0), cant_a, 13.0)
			if monedas_visibles >= 40:
				Sprites_Cocina.dibujar_pila_monedas(self, Vector2(w - 28.0, y_barra + 11.0), clampi(cant_a - 1, 2, 5), 11.0)

	func _dibujar_mesa_diner(centro: Vector2) -> void:
		# Sillas rojas laterales
		for lado: float in [-1.0, 1.0]:
			var sx := centro.x + lado * 48.0
			draw_line(Vector2(sx, centro.y + 4.0), Vector2(sx, centro.y + 24.0), Color("#64748b"), 3.0)
			Sprites_Cocina.dibujar_caja(self, Rect2(sx - 12.0, centro.y - 16.0, 24.0, 22.0), 6.0, Color("#dc2626"), Color("#7f1d1d"), 1.5)
			Sprites_Cocina.dibujar_elipse(self, Vector2(sx, centro.y + 6.0), 14.0, 5.0, Color("#ef4444"), Color("#7f1d1d"), 1.3)
		# Pata cromada y tablero turquesa
		Sprites_Cocina.dibujar_elipse(self, centro + Vector2(0.0, 28.0), 16.0, 5.0, Color("#94a3b8"), Color("#475569"), 1.2)
		draw_line(Vector2(centro.x, centro.y + 6.0), Vector2(centro.x, centro.y + 28.0), Color("#cbd5e1"), 4.5)
		Sprites_Cocina.dibujar_elipse(self, centro + Vector2(0.0, 3.0), 42.0, 12.0, Color("#0f766e"), Color("#134e4a"), 1.5)
		Sprites_Cocina.dibujar_elipse(self, centro, 42.0, 11.5, Color("#14b8a6"), Color("#e2e8f0"), 1.8)
		Sprites_Cocina.dibujar_elipse(self, centro + Vector2(-6.0, -2.0), 22.0, 4.5, Color("#99f6e4", 0.55))


# ============================================================================
# 2. Personaje Cliente Expresivo + Burbuja de Pedido (estilo cocina casual)
# ============================================================================

class SpriteCliente extends Control:
	var variante: int = 0
	var ratio_paciencia: float = 1.0
	var tiempo: float = 0.0
	var fase_parpadeo: float = 0.0
	var rebote_feliz: float = 0.0

	const ARQUETIPOS: Array[Dictionary] = [
		# 0: Chico con gafas y chaleco verde (inspirado en el cliente de la captura)
		{"piel": "#f5cbb0", "pelo": "#6b3e1b", "camisa": "#f8fafc", "chaleco": "#14532d", "ojos": "#16a34a", "estilo": "chico_gafas"},
		# 1: Chica rubia de pelo corto y camiseta blanca (inspirada en la clienta de la captura)
		{"piel": "#f7d3ba", "pelo": "#d4a14d", "camisa": "#e2e8f0", "chaleco": "", "ojos": "#2563eb", "estilo": "chica_bob"},
		# 2: Chico con gorra roja y sudadera azul
		{"piel": "#e6b494", "pelo": "#1e293b", "camisa": "#2563eb", "chaleco": "", "ojos": "#451a03", "estilo": "gorra_roja"},
		# 3: Chica pelirroja con coleta y blusa turquesa
		{"piel": "#fbe0cf", "pelo": "#c2410c", "camisa": "#0d9488", "chaleco": "", "ojos": "#059669", "estilo": "coleta"},
		# 4: Barista barbudo con camisa cuadros
		{"piel": "#d99b78", "pelo": "#3f2618", "camisa": "#b91c1c", "chaleco": "#1e293b", "ojos": "#3b2314", "estilo": "barba"},
		# 5: Ejecutiva con moño elegante
		{"piel": "#f1c2a0", "pelo": "#111827", "camisa": "#7c3aed", "chaleco": "#1e293b", "ojos": "#1d4ed8", "estilo": "mono"},
		# 6: Señor alegre con bigote canoso
		{"piel": "#f3c7aa", "pelo": "#cbd5e1", "camisa": "#d97706", "chaleco": "#78350f", "ojos": "#475569", "estilo": "bigote"},
		# 7: Chica sporty con diadema rosa
		{"piel": "#c68863", "pelo": "#1c1917", "camisa": "#db2777", "chaleco": "", "ojos": "#29180e", "estilo": "diadema"},
	]

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if size.x <= 2.0 or size.y <= 2.0:
			return
		var arq: Dictionary = ARQUETIPOS[variante % ARQUETIPOS.size()]
		var piel := Color(str(arq["piel"]))
		var pelo := Color(str(arq["pelo"]))
		var camisa := Color(str(arq["camisa"]))
		var chaleco_str: String = str(arq["chaleco"])
		var col_ojos := Color(str(arq["ojos"]))
		var estilo: String = str(arq["estilo"])

		var bob := sin(tiempo * 2.4 + float(variante) * 1.1) * 2.2 - sin(rebote_feliz * PI) * 10.0
		var cx := size.x * 0.50
		var base_y := size.y
		var c_cabeza := Vector2(cx, base_y - 96.0 + bob)

		# Pelo trasero (para estilos largos o bob)
		if estilo == "chica_bob":
			Sprites_Cocina.dibujar_elipse(self, c_cabeza + Vector2(0.0, 2.0), 38.0, 42.0, pelo.darkened(0.15), Sprites_Cocina.TINTA, 1.8)
		elif estilo == "coleta":
			Sprites_Cocina.dibujar_elipse(self, c_cabeza + Vector2(-28.0, -4.0), 14.0, 22.0, pelo, Sprites_Cocina.TINTA, 1.6, -0.3)
		elif estilo == "mono":
			Sprites_Cocina.dibujar_elipse(self, c_cabeza + Vector2(0.0, -40.0), 15.0, 12.0, pelo, Sprites_Cocina.TINTA, 1.6)

		# Torso / hombros
		var torso := PackedVector2Array([
			Vector2(cx - 42.0, base_y),
			Vector2(cx - 38.0, base_y - 44.0 + bob * 0.6),
			Vector2(cx - 14.0, base_y - 54.0 + bob * 0.6),
			Vector2(cx + 14.0, base_y - 54.0 + bob * 0.6),
			Vector2(cx + 38.0, base_y - 44.0 + bob * 0.6),
			Vector2(cx + 42.0, base_y),
		])
		Sprites_Cocina.dibujar_poligono_borde(self, torso, camisa, Sprites_Cocina.TINTA, 1.8)

		if chaleco_str != "":
			var col_ch := Color(chaleco_str)
			var chal := PackedVector2Array([
				Vector2(cx - 28.0, base_y),
				Vector2(cx - 25.0, base_y - 50.0 + bob * 0.6),
				Vector2(cx - 10.0, base_y - 52.0 + bob * 0.6),
				Vector2(cx, base_y - 26.0 + bob * 0.6),
				Vector2(cx + 10.0, base_y - 52.0 + bob * 0.6),
				Vector2(cx + 25.0, base_y - 50.0 + bob * 0.6),
				Vector2(cx + 28.0, base_y),
			])
			Sprites_Cocina.dibujar_poligono_borde(self, chal, col_ch, Sprites_Cocina.TINTA, 1.6)
			if estilo == "chico_gafas":
				# Pajarita verde oscura / corbatín
				Sprites_Cocina.dibujar_poligono_borde(self, PackedVector2Array([
					Vector2(cx - 8.0, base_y - 51.0 + bob * 0.6),
					Vector2(cx, base_y - 47.0 + bob * 0.6),
					Vector2(cx + 8.0, base_y - 51.0 + bob * 0.6),
					Vector2(cx + 8.0, base_y - 43.0 + bob * 0.6),
					Vector2(cx, base_y - 47.0 + bob * 0.6),
					Vector2(cx - 8.0, base_y - 43.0 + bob * 0.6),
				]), col_ch, Sprites_Cocina.TINTA, 1.2)

		# Cuello
		Sprites_Cocina.dibujar_caja(self, Rect2(cx - 10.0, c_cabeza.y + 24.0, 20.0, 22.0), 4.0,
			piel.darkened(0.08), Sprites_Cocina.TINTA, 1.5)
		Sprites_Cocina.dibujar_elipse(self, c_cabeza + Vector2(0.0, 32.0), 11.0, 4.0, piel.darkened(0.22))

		# Orejas
		for lado: float in [-1.0, 1.0]:
			Sprites_Cocina.dibujar_elipse(self, c_cabeza + Vector2(lado * 33.0, 4.0), 6.5, 9.0, piel.darkened(0.06), Sprites_Cocina.TINTA, 1.5)

		# Cabeza con sombreado cálido
		Sprites_Cocina.dibujar_elipse(self, c_cabeza, 33.5, 36.5, piel, Sprites_Cocina.TINTA, 1.9)
		Sprites_Cocina.dibujar_elipse(self, c_cabeza + Vector2(-7.0, -9.0), 21.0, 22.0, piel.lightened(0.10))

		# Rubor (más intenso si enfadado)
		var rubor_a := 0.55 if ratio_paciencia < 0.25 else 0.24
		var col_rubor := Color("#ef4444", rubor_a) if ratio_paciencia < 0.25 else Color("#fb7185", rubor_a)
		Sprites_Cocina.dibujar_elipse(self, c_cabeza + Vector2(-17.0, 10.0), 6.5, 3.8, col_rubor)
		Sprites_Cocina.dibujar_elipse(self, c_cabeza + Vector2(17.0, 10.0), 6.5, 3.8, col_rubor)

		# Barba / bigote según arquetipo
		if estilo == "barba":
			var barba := PackedVector2Array([
				c_cabeza + Vector2(-28.0, 6.0), c_cabeza + Vector2(-20.0, 28.0),
				c_cabeza + Vector2(0.0, 39.0), c_cabeza + Vector2(20.0, 28.0),
				c_cabeza + Vector2(28.0, 6.0), c_cabeza + Vector2(18.0, 16.0),
				c_cabeza + Vector2(0.0, 14.0), c_cabeza + Vector2(-18.0, 16.0),
			])
			Sprites_Cocina.dibujar_poligono_borde(self, barba, pelo, Sprites_Cocina.TINTA, 1.5)

		# Ojos con parpadeo natural
		var ciclo_p := fmod(tiempo + fase_parpadeo, 3.8)
		var parpadeando := ciclo_p > 3.66
		for lado: float in [-1.0, 1.0]:
			var ce := c_cabeza + Vector2(lado * 13.0, -1.5)
			if parpadeando:
				draw_line(ce + Vector2(-6.5, 0.0), ce + Vector2(6.5, 0.0), Sprites_Cocina.TINTA, 2.2, true)
			else:
				Sprites_Cocina.dibujar_elipse(self, ce, 7.2, 8.2, Color.WHITE, Sprites_Cocina.TINTA, 1.4)
				draw_circle(ce + Vector2(0.0, 0.5), 4.4, col_ojos)
				draw_circle(ce + Vector2(0.0, 0.5), 2.3, Color("#0f172a"))
				draw_circle(ce + Vector2(-1.6, -1.6), 1.5, Color.WHITE)

			# Cejas expresivas según paciencia
			var incl := 0.0
			if ratio_paciencia < 0.25:
				incl = lado * 4.0
			elif ratio_paciencia < 0.50:
				incl = -lado * 1.5
			draw_line(ce + Vector2(-7.0, -10.5 - incl * 0.5),
				ce + Vector2(7.0, -10.5 + incl), pelo.darkened(0.25), 2.6, true)

		# Gafas redondas (estilo chico de la captura)
		if estilo == "chico_gafas":
			for lado: float in [-1.0, 1.0]:
				var cg := c_cabeza + Vector2(lado * 13.5, -1.0)
				draw_circle(cg, 11.2, Color(0.90, 0.98, 1.0, 0.20))
				draw_arc(cg, 11.2, 0.0, TAU, 22, Color("#64748b"), 2.2, true)
			draw_line(c_cabeza + Vector2(-2.3, -1.0), c_cabeza + Vector2(2.3, -1.0), Color("#64748b"), 2.0, true)

		# Nariz suave
		draw_arc(c_cabeza + Vector2(0.0, 7.5), 3.6, 0.15, PI - 0.15, 8, piel.darkened(0.32), 1.7, true)

		# Bigote si aplica
		if estilo == "bigote":
			Sprites_Cocina.dibujar_elipse(self, c_cabeza + Vector2(-6.5, 13.0), 8.5, 3.8, pelo, Sprites_Cocina.TINTA, 1.1, -0.2)
			Sprites_Cocina.dibujar_elipse(self, c_cabeza + Vector2(6.5, 13.0), 8.5, 3.8, pelo, Sprites_Cocina.TINTA, 1.1, 0.2)

		# Boca según paciencia
		var c_boca := c_cabeza + Vector2(0.0, 18.5)
		if ratio_paciencia >= 0.50:
			var sonrisa := PackedVector2Array([
				c_boca + Vector2(-11.0, -2.5), c_boca + Vector2(11.0, -2.5),
				c_boca + Vector2(8.0, 5.0), c_boca + Vector2(0.0, 7.0), c_boca + Vector2(-8.0, 5.0),
			])
			Sprites_Cocina.dibujar_poligono_borde(self, sonrisa, Color.WHITE, Sprites_Cocina.TINTA, 1.5)
		elif ratio_paciencia >= 0.25:
			draw_line(c_boca + Vector2(-8.0, 1.0), c_boca + Vector2(8.0, 0.0), Sprites_Cocina.TINTA, 2.2, true)
		else:
			var enfado := PackedVector2Array([
				c_boca + Vector2(-9.0, 4.0), c_boca + Vector2(-3.0, -1.5),
				c_boca + Vector2(3.0, -1.5), c_boca + Vector2(9.0, 4.0),
				c_boca + Vector2(6.0, 6.5), c_boca + Vector2(-6.0, 6.5),
			])
			Sprites_Cocina.dibujar_poligono_borde(self, enfado, Color("#991b1b"), Sprites_Cocina.TINTA, 1.5)
			# Gota de enfado / vapor sobre la cabeza
			Sprites_Cocina.dibujar_vapor(self, c_cabeza + Vector2(24.0, -32.0), tiempo * 1.4, 0.55, 10.0, 12.0, false)

		# Pelo frontal / flequillo / gorra
		if estilo == "gorra_roja":
			Sprites_Cocina.dibujar_elipse(self, c_cabeza + Vector2(0.0, -22.0), 34.0, 20.0, Color("#dc2626"), Sprites_Cocina.TINTA, 1.8)
			Sprites_Cocina.dibujar_elipse(self, c_cabeza + Vector2(10.0, -14.0), 28.0, 7.5, Color("#b91c1c"), Sprites_Cocina.TINTA, 1.6, 0.12)
		else:
			var fleq := PackedVector2Array([
				c_cabeza + Vector2(-34.0, -8.0),
				c_cabeza + Vector2(-30.0, -28.0),
				c_cabeza + Vector2(-12.0, -39.0),
				c_cabeza + Vector2(12.0, -39.0),
				c_cabeza + Vector2(30.0, -28.0),
				c_cabeza + Vector2(34.0, -8.0),
				c_cabeza + Vector2(24.0, -14.0),
				c_cabeza + Vector2(12.0, -22.0),
				c_cabeza + Vector2(3.0, -14.0),
				c_cabeza + Vector2(-8.0, -23.0),
				c_cabeza + Vector2(-20.0, -13.0),
			])
			Sprites_Cocina.dibujar_poligono_borde(self, fleq, pelo, Sprites_Cocina.TINTA, 1.7)
			draw_arc(c_cabeza + Vector2(0.0, -24.0), 19.0, PI + 0.5, TAU - 0.5, 12, pelo.lightened(0.28), 2.5, true)
			if estilo == "diadema":
				draw_arc(c_cabeza + Vector2(0.0, -14.0), 30.0, PI + 0.35, TAU - 0.35, 16, Color("#ec4899"), 4.2, true)


class SpriteBurbujaPedido extends Control:
	var items: Array = []
	var entregados: Array = []
	var ratio_paciencia: float = 1.0
	var precio_total: int = 0
	var tiempo: float = 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if size.x <= 2.0 or size.y <= 2.0:
			return
		var rect_b := Rect2(10.0, 4.0, size.x - 14.0, size.y - 8.0)

		# Sombra suave
		Sprites_Cocina.dibujar_caja(self, Rect2(rect_b.position + Vector2(2.0, 4.0), rect_b.size),
			14.0, Color(0.0, 0.0, 0.0, 0.18))
		# Cuerpo blanco de la burbuja
		Sprites_Cocina.dibujar_caja(self, rect_b, 14.0, Color.WHITE, Color("#cbd5e1"), 2.0)

		# Cola del bocadillo apuntando hacia el cliente a la izquierda
		var cola := PackedVector2Array([
			Vector2(rect_b.position.x + 2.0, rect_b.position.y + 38.0),
			Vector2(0.0, rect_b.position.y + 46.0),
			Vector2(rect_b.position.x + 2.0, rect_b.position.y + 56.0),
		])
		draw_colored_polygon(cola, Color.WHITE)
		draw_line(cola[0], cola[1], Color("#cbd5e1"), 2.0, true)
		draw_line(cola[1], cola[2], Color("#cbd5e1"), 2.0, true)

		# Barra de paciencia vertical a la derecha de la burbuja (estilo clásico de cocina)
		var bar_x := rect_b.end.x - 16.0
		var bar_y := rect_b.position.y + 10.0
		var bar_h := rect_b.size.y - 20.0
		var bar_rect := Rect2(bar_x, bar_y, 9.0, bar_h)
		Sprites_Cocina.dibujar_caja(self, bar_rect, 4.5, Color("#e2e8f0"), Color("#94a3b8"), 1.0)

		var r_clamp := clampf(ratio_paciencia, 0.0, 1.0)
		var col_bar := Color("#22c55e")
		if r_clamp < 0.25:
			col_bar = Color("#ef4444")
		elif r_clamp < 0.50:
			col_bar = Color("#f59e0b")

		var fill_h := maxf(4.0, (bar_h - 2.0) * r_clamp)
		if r_clamp > 0.01:
			var fill_rect := Rect2(bar_x + 1.0, bar_y + bar_h - 1.0 - fill_h, 7.0, fill_h)
			Sprites_Cocina.dibujar_caja(self, fill_rect, 3.5, col_bar)

		# Dibujar los 1..3 ítems pedidos con sus sprites reales
		var n := items.size()
		if n <= 0:
			return
		var area_w := rect_b.size.x - 22.0
		var area_cx := rect_b.position.x + area_w * 0.5 + 2.0
		var area_h := rect_b.size.y - 26.0
		var escala := 0.78 if n == 1 else (0.62 if n == 2 else 0.48)

		for i in range(n):
			var cy := rect_b.position.y + 10.0 + area_h * (float(i) + 0.5) / float(n)
			var hecho := i < entregados.size() and bool(entregados[i])
			if hecho:
				Sprites_Cocina.dibujar_elipse(self, Vector2(area_cx, cy), 28.0 * escala, 18.0 * escala, Color("#dcfce7"))
				Sprites_Cocina.dibujar_item_por_id(self, str(items[i]), Vector2(area_cx, cy), escala * 0.85, tiempo)
				draw_circle(Vector2(area_cx + 18.0 * escala, cy - 10.0 * escala), 9.0, Color("#16a34a"))
				draw_polyline(PackedVector2Array([
					Vector2(area_cx + 13.5 * escala, cy - 10.0 * escala),
					Vector2(area_cx + 17.0 * escala, cy - 6.5 * escala),
					Vector2(area_cx + 23.0 * escala, cy - 13.5 * escala),
				]), Color.WHITE, 2.2, true)
			else:
				Sprites_Cocina.dibujar_item_por_id(self, str(items[i]), Vector2(area_cx, cy), escala, tiempo)

		# Etiqueta pequeña del precio abajo
		var txt_p := "%d" % precio_total
		Sprites_Cocina.dibujar_moneda(self, Vector2(area_cx - 12.0, rect_b.end.y - 12.0), 6.5)
		draw_string(Sprites_Cocina.FUENTE_UI, Vector2(area_cx - 1.0, rect_b.end.y - 7.5),
			txt_p, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#92400e"))


# ============================================================================
# 3. Fondo de la Encimera Central (acero cepillado, madera, ketchup, lechuga, tomate)
# ============================================================================

class FondoEncimera extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if size.x <= 2.0 or size.y <= 2.0:
			return
		var w := size.x
		var h := size.y
		var y_trim := h - 14.0

		# Encimera izquierda/central laminado burdeos/caoba cálido
		draw_rect(Rect2(0.0, 0.0, w * 0.64, y_trim), Color("#7f1d1d"))
		draw_rect(Rect2(0.0, 0.0, w * 0.64, 24.0), Color("#991b1b"))
		draw_line(Vector2(0.0, 2.0), Vector2(w * 0.64, 2.0), Color("#fca5a5", 0.30), 3.0)

		# Placa de acero inoxidable cepillado debajo de los platos
		Sprites_Cocina.dibujar_caja(self, Rect2(276.0, 6.0, 496.0, y_trim - 12.0), 10.0,
			Color("#cbd5e1"), Color("#64748b"), 2.2)
		draw_rect(Rect2(284.0, 14.0, 480.0, y_trim - 28.0), Color("#94a3b8", 0.35))

		# Cocina / Plancha de acero inoxidable a la derecha
		Sprites_Cocina.dibujar_caja(self, Rect2(822.0, 4.0, w - 834.0, y_trim - 8.0), 10.0,
			Color("#cbd5e1"), Color("#475569"), 2.4)
		draw_rect(Rect2(830.0, 12.0, w - 850.0, y_trim - 24.0), Color("#e2e8f0", 0.45))
		# Reflejo diagonal metálico en la plancha
		draw_colored_polygon(PackedVector2Array([
			Vector2(860.0, 12.0), Vector2(930.0, 12.0),
			Vector2(870.0, y_trim - 12.0), Vector2(830.0, y_trim - 12.0)
		]), Color(1.0, 1.0, 1.0, 0.22))

		# Props decorativos en el hueco central (x = 776..822): Ketchup, Lechuga, Tomate
		_dibujar_ketchup(Vector2(799.0, 46.0))
		_dibujar_bandeja_lechuga_deco(Vector2(799.0, 134.0))
		_dibujar_plato_tomate_deco(Vector2(799.0, 220.0))

		# Borde frontal ajedrezado blanco y negro (icónico del mostrador de la captura)
		draw_rect(Rect2(0.0, y_trim - 4.0, w, 4.0), Color("#cbd5e1"))
		var ancho_cuadro := 16.0
		var num_c := int(ceil(w / ancho_cuadro))
		for k in range(num_c):
			var col_c := Color("#1e293b") if k % 2 == 0 else Color("#f8fafc")
			draw_rect(Rect2(float(k) * ancho_cuadro, y_trim, ancho_cuadro, 14.0), col_c)
		draw_line(Vector2(0.0, y_trim), Vector2(w, y_trim), Color("#0f172a"), 1.6)

	func _dibujar_ketchup(c: Vector2) -> void:
		Sprites_Cocina.dibujar_elipse(self, c + Vector2(2.0, 24.0), 14.0, 5.0, Color(0.0, 0.0, 0.0, 0.25))
		Sprites_Cocina.dibujar_caja(self, Rect2(c.x - 11.0, c.y - 12.0, 22.0, 36.0), 7.0, Color("#dc2626"), Sprites_Cocina.TINTA, 1.6)
		draw_rect(Rect2(c.x - 7.0, c.y - 6.0, 4.0, 24.0), Color("#fca5a5", 0.55))
		Sprites_Cocina.dibujar_caja(self, Rect2(c.x - 7.0, c.y - 18.0, 14.0, 7.0), 2.5, Color("#facc15"), Sprites_Cocina.TINTA, 1.4)
		Sprites_Cocina.dibujar_poligono_borde(self, PackedVector2Array([
			c + Vector2(-3.0, -18.0), c + Vector2(0.0, -28.0), c + Vector2(3.0, -18.0)
		]), Color("#facc15"), Sprites_Cocina.TINTA, 1.3)

	func _dibujar_bandeja_lechuga_deco(c: Vector2) -> void:
		Sprites_Cocina.dibujar_caja(self, Rect2(c.x - 18.0, c.y - 26.0, 36.0, 52.0), 6.0, Color("#d97706"), Color("#78350f"), 1.6)
		Sprites_Cocina.dibujar_caja(self, Rect2(c.x - 14.0, c.y - 22.0, 28.0, 44.0), 4.0, Color("#fef3c7"))
		for dy: float in [-10.0, 2.0, 12.0]:
			Sprites_Cocina.dibujar_elipse(self, c + Vector2(0.0, dy), 11.0, 8.0, Color("#22c55e"), Color("#15803d"), 1.2)
			Sprites_Cocina.dibujar_elipse(self, c + Vector2(-2.0, dy - 1.5), 6.0, 4.0, Color("#86efac", 0.7))

	func _dibujar_plato_tomate_deco(c: Vector2) -> void:
		Sprites_Cocina.dibujar_plato_ceramica(self, c, 19.0, 16.0)
		for off: Vector2 in [Vector2(-5.0, -3.0), Vector2(5.0, 2.0), Vector2(-1.0, 5.0)]:
			Sprites_Cocina.dibujar_elipse(self, c + off, 7.0, 4.6, Color("#ef4444"), Color("#991b1b"), 1.1)


# ============================================================================
# 4. Sprites Interactivos de Estaciones (Bebidas, Platos, Sartén, Freidora, Bandeja)
# ============================================================================

class SpriteBebida extends Control:
	var estado: String = "listo"
	var progreso: float = 1.0
	var tiempo: float = 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if size.x <= 2.0 or size.y <= 2.0:
			return
		var cx := size.x * 0.5
		var cy := size.y * 0.58

		# Boquilla cromada superior del dispensador
		Sprites_Cocina.dibujar_caja(self, Rect2(cx - 10.0, 2.0, 20.0, 10.0), 3.0, Color("#64748b"), Color("#1e293b"), 1.3)
		Sprites_Cocina.dibujar_caja(self, Rect2(cx - 4.0, 10.0, 8.0, 8.0), 2.0, Color("#cbd5e1"), Color("#334155"), 1.2)

		if estado == "llenando":
			# Chorro de cola cayendo al vaso
			var wob := sin(tiempo * 18.0) * 1.2
			draw_line(Vector2(cx, 18.0), Vector2(cx + wob, cy + 4.0), Color("#451a03"), 3.6, true)
			Sprites_Cocina.dibujar_refresco(self, Vector2(cx, cy), 1.05, progreso, tiempo)
		else:
			# Halo sutil de listo
			Sprites_Cocina.dibujar_elipse(self, Vector2(cx, cy + 16.0), 22.0, 7.0, Color("#38bdf8", 0.30))
			Sprites_Cocina.dibujar_refresco(self, Vector2(cx, cy), 1.12, 1.0, tiempo)


class SpritePlato extends Control:
	var pan: bool = false
	var carnes: int = 0
	var queso: bool = false
	var lechuga: bool = false
	var tomate: bool = false
	var pedida_ahora: bool = false
	var seleccionado: bool = false
	var tiempo: float = 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if size.x <= 2.0 or size.y <= 2.0:
			return
		var mat := Rect2(4.0, 4.0, size.x - 8.0, size.y - 8.0)
		var col_borde := Color("#9a3412")
		var grosor := 1.5
		if pedida_ahora:
			col_borde = Color("#16a34a")
			grosor = 2.8
		elif seleccionado:
			col_borde = Color("#f59e0b")
			grosor = 2.6

		# Papel encerado beige bajo cada plato (exacto a la captura)
		Sprites_Cocina.dibujar_caja(self, mat, 8.0, Color("#e7d3b0"), col_borde, grosor)
		if pedida_ahora:
			var pulso := 0.14 + (sin(tiempo * 6.0) * 0.5 + 0.5) * 0.14
			Sprites_Cocina.dibujar_caja(self, mat, 8.0, Color("#22c55e", pulso))
		elif seleccionado:
			Sprites_Cocina.dibujar_caja(self, mat, 8.0, Color("#fbbf24", 0.15))

		var centro := size * 0.5 + Vector2(0.0, 3.0)
		if not pan:
			# Silueta sutil de hamburguesa impresa en el papel
			Sprites_Cocina.dibujar_elipse(self, centro, 26.0, 14.0, Color("#d4bc94", 0.65), Color("#b49a70", 0.7), 1.3)
			draw_arc(centro - Vector2(0.0, 3.0), 15.0, PI, TAU, 14, Color("#a18458", 0.65), 1.4, true)
			return

		var brillo := Color("#22c55e") if pedida_ahora else (Color("#f59e0b") if seleccionado else Color.TRANSPARENT)
		Sprites_Cocina.dibujar_hamburguesa(self, centro, 1.05, pan, carnes, queso, lechuga, tomate, true, brillo)


class SpriteSarten extends Control:
	var estado: String = "vacio"
	var progreso: float = 0.0
	var quemado: float = 0.0
	var tiempo: float = 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if size.x <= 2.0 or size.y <= 2.0:
			return
		var cen := Vector2(size.x * 0.44, size.y * 0.52)
		var rx := minf(size.x * 0.34, 48.0)
		var ry := minf(size.y * 0.37, 36.0)

		# Rejilla / quemador bajo la sartén
		Sprites_Cocina.dibujar_elipse(self, cen + Vector2(0.0, 4.0), rx * 1.12, ry * 1.08, Color("#334155"), Color("#1e293b"), 1.6)
		if estado in ["cocinando", "listo", "alerta"]:
			var glow := 0.25 + sin(tiempo * 7.0) * 0.08
			Sprites_Cocina.dibujar_elipse(self, cen + Vector2(0.0, 3.0), rx * 1.05, ry * 1.02, Color("#f97316", glow))

		# Mango inclinado de la sartén hacia la derecha
		var h0 := cen + Vector2(rx * 0.78, 2.0)
		var h1 := cen + Vector2(rx * 1.42, 14.0)
		draw_line(h0, h1, Color("#0f172a"), 11.0, true)
		draw_line(h0, h1, Color("#334155"), 7.0, true)
		draw_circle(h1 - Vector2(3.0, 1.0), 2.2, Color("#cbd5e1"))

		# Cuerpo de la sartén de hierro fundido
		Sprites_Cocina.dibujar_elipse(self, cen + Vector2(0.0, 5.0), rx, ry, Color("#0f172a"), Color("#020617"), 1.6)
		Sprites_Cocina.dibujar_elipse(self, cen, rx, ry, Color("#374151"), Color("#64748b"), 2.0)
		Sprites_Cocina.dibujar_elipse(self, cen + Vector2(0.0, 1.0), rx * 0.85, ry * 0.82, Color("#1f2937"), Color("#111827"), 1.4)

		if estado == "vacio":
			return

		# Carne según estado
		var p_rx := rx * 0.64
		var p_ry := ry * 0.56
		match estado:
			"cocinando":
				Sprites_Cocina.dibujar_carne_cocida(self, cen, p_rx, p_ry, progreso * 0.75, false)
				Sprites_Cocina.dibujar_burbujas_aceite(self, cen, p_rx * 0.95, tiempo, 7)
				Sprites_Cocina.dibujar_vapor(self, cen + Vector2(0.0, -p_ry), tiempo, 0.55, 22.0, 20.0, false)
				_dibujar_anillo_progreso(Vector2(cen.x + rx * 0.85, cen.y - ry * 0.68), 11.0, progreso, Color("#f97316"))
			"listo":
				Sprites_Cocina.dibujar_elipse(self, cen, p_rx * 1.15, p_ry * 1.15, Color("#22c55e", 0.28))
				Sprites_Cocina.dibujar_carne_cocida(self, cen, p_rx, p_ry, 1.0, false)
				Sprites_Cocina.dibujar_vapor(self, cen + Vector2(0.0, -p_ry), tiempo, 0.35, 18.0, 16.0, false)
				_dibujar_anillo_progreso(Vector2(cen.x + rx * 0.85, cen.y - ry * 0.68), 11.0, 1.0 - quemado, Color("#22c55e"))
			"alerta":
				var pulso := 0.22 + (sin(tiempo * 12.0) * 0.5 + 0.5) * 0.30
				Sprites_Cocina.dibujar_elipse(self, cen, p_rx * 1.20, p_ry * 1.20, Color("#ef4444", pulso))
				Sprites_Cocina.dibujar_carne_cocida(self, cen, p_rx, p_ry, 1.0, false)
				Sprites_Cocina.dibujar_vapor(self, cen + Vector2(0.0, -p_ry), tiempo, 0.72, 22.0, 22.0, true)
				_dibujar_anillo_progreso(Vector2(cen.x + rx * 0.85, cen.y - ry * 0.68), 11.0, 1.0 - quemado, Color("#ef4444"))
			"quemado":
				Sprites_Cocina.dibujar_carne_cocida(self, cen, p_rx, p_ry, 1.0, true)
				Sprites_Cocina.dibujar_vapor(self, cen + Vector2(0.0, -p_ry), tiempo, 0.85, 24.0, 26.0, true)
				var ic_c := Vector2(cen.x + rx * 0.85, cen.y - ry * 0.68)
				draw_circle(ic_c, 10.0, Color("#dc2626"))
				draw_line(ic_c + Vector2(-4.0, -4.0), ic_c + Vector2(4.0, 4.0), Color.WHITE, 2.2, true)
				draw_line(ic_c + Vector2(4.0, -4.0), ic_c + Vector2(-4.0, 4.0), Color.WHITE, 2.2, true)

	func _dibujar_anillo_progreso(cen: Vector2, r: float, val: float, col: Color) -> void:
		draw_circle(cen, r + 1.5, Color("#0f172a", 0.85))
		draw_arc(cen, r - 1.0, 0.0, TAU, 18, Color("#334155"), 3.2, true)
		var v := clampf(val, 0.0, 1.0)
		if v > 0.01:
			draw_arc(cen, r - 1.0, -PI * 0.5, -PI * 0.5 + TAU * v, 18, col, 3.2, true)


class SpriteFreidora extends Control:
	var estado: String = "vacio"
	var progreso: float = 0.0
	var quemado: float = 0.0
	var tiempo: float = 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if size.x <= 2.0 or size.y <= 2.0:
			return
		var w := size.x
		var h := size.y
		var pozo := Rect2(8.0, 14.0, w - 16.0, h - 22.0)

		# Pozo metálico de la freidora con aceite dorado
		Sprites_Cocina.dibujar_caja(self, pozo, 8.0, Color("#64748b"), Color("#334155"), 2.0)
		var aceite := Rect2(pozo.position + Vector2(5.0, 5.0), pozo.size - Vector2(10.0, 10.0))
		var col_oil := Color("#b45309") if estado == "vacio" else Color("#d97706")
		Sprites_Cocina.dibujar_caja(self, aceite, 5.0, col_oil, Color("#78350f"), 1.2)

		# Cesta de alambre
		var cesta := Rect2(aceite.position + Vector2(4.0, 4.0), aceite.size - Vector2(8.0, 8.0))
		Sprites_Cocina.dibujar_caja(self, cesta, 4.0, Color.TRANSPARENT, Color("#cbd5e1"), 1.6)
		for gx in range(1, 5):
			var lx := lerpf(cesta.position.x, cesta.end.x, float(gx) / 5.0)
			draw_line(Vector2(lx, cesta.position.y), Vector2(lx, cesta.end.y), Color("#94a3b8", 0.5), 1.0)

		var cen := size * 0.5 + Vector2(0.0, 4.0)
		match estado:
			"cocinando":
				Sprites_Cocina.dibujar_patatas(self, cen + Vector2(0.0, 3.0), 0.78, false, true, tiempo)
				Sprites_Cocina.dibujar_burbujas_aceite(self, cen + Vector2(0.0, 8.0), 22.0, tiempo, 6)
				_dibujar_anillo(Vector2(w - 18.0, 18.0), 10.0, progreso, Color("#f97316"))
			"listo":
				Sprites_Cocina.dibujar_elipse(self, cen + Vector2(0.0, 14.0), 24.0, 8.0, Color("#22c55e", 0.35))
				Sprites_Cocina.dibujar_patatas(self, cen, 0.96, false, false, tiempo)
				_dibujar_anillo(Vector2(w - 18.0, 18.0), 10.0, 1.0 - quemado, Color("#22c55e"))
			"alerta":
				var pulso := 0.25 + (sin(tiempo * 12.0) * 0.5 + 0.5) * 0.30
				Sprites_Cocina.dibujar_elipse(self, cen + Vector2(0.0, 14.0), 26.0, 9.0, Color("#ef4444", pulso))
				Sprites_Cocina.dibujar_patatas(self, cen, 0.96, false, false, tiempo)
				Sprites_Cocina.dibujar_vapor(self, cen + Vector2(0.0, -22.0), tiempo, 0.75, 16.0, 18.0, true)
				_dibujar_anillo(Vector2(w - 18.0, 18.0), 10.0, 1.0 - quemado, Color("#ef4444"))
			"quemado":
				Sprites_Cocina.dibujar_patatas(self, cen, 0.92, true, false, tiempo)
				Sprites_Cocina.dibujar_vapor(self, cen + Vector2(0.0, -22.0), tiempo, 0.85, 18.0, 20.0, true)

	func _dibujar_anillo(cen: Vector2, r: float, val: float, col: Color) -> void:
		draw_circle(cen, r + 1.5, Color("#0f172a", 0.85))
		draw_arc(cen, r - 1.0, 0.0, TAU, 16, Color("#334155"), 2.8, true)
		var v := clampf(val, 0.0, 1.0)
		if v > 0.01:
			draw_arc(cen, r - 1.0, -PI * 0.5, -PI * 0.5 + TAU * v, 16, col, 2.8, true)


class SpriteIngrediente extends Control:
	var tipo: String = "pan"
	var activo_papelera: bool = false

	func _init(tipo_inicial: String = "pan") -> void:
		tipo = tipo_inicial
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if size.x <= 2.0 or size.y <= 2.0:
			return
		var cen := Vector2(size.x * 0.5, size.y * 0.42)
		match tipo:
			"pan":
				# Cesta de panadería con panecillos de sésamo (como bajo el mostrador de la captura)
				Sprites_Cocina.dibujar_caja(self, Rect2(cen.x - 42.0, cen.y - 16.0, 84.0, 44.0), 10.0,
					Color("#b45309"), Color("#78350f"), 2.0)
				Sprites_Cocina.dibujar_caja(self, Rect2(cen.x - 36.0, cen.y - 11.0, 72.0, 34.0), 7.0,
					Color("#fef3c7", 0.45))
				for bx: float in [-18.0, 18.0, 0.0]:
					var by := cen.y - (5.0 if bx != 0.0 else 12.0)
					Sprites_Cocina.dibujar_elipse(self, Vector2(cen.x + bx, by + 5.0), 18.0, 8.0, Color("#b45309"), Sprites_Cocina.TINTA, 1.3)
					Sprites_Cocina.dibujar_elipse(self, Vector2(cen.x + bx, by), 18.0, 11.0, Color("#d97706"), Sprites_Cocina.TINTA, 1.4)
					Sprites_Cocina.dibujar_elipse(self, Vector2(cen.x + bx - 3.0, by - 4.0), 9.0, 4.0, Color("#fcd34d", 0.65))
					for sx: float in [-6.0, 0.0, 6.0]:
						draw_circle(Vector2(cen.x + bx + sx, by - 3.0 + absf(sx) * 0.25), 1.3, Color("#fef3c7"))
			"carne":
				# Bandeja metálica con hamburguesas crudas rosas (exacta a la bandeja inferior derecha de la captura)
				Sprites_Cocina.dibujar_caja(self, Rect2(cen.x - 42.0, cen.y - 16.0, 84.0, 44.0), 8.0,
					Color("#cbd5e1"), Color("#475569"), 2.0)
				Sprites_Cocina.dibujar_caja(self, Rect2(cen.x - 36.0, cen.y - 11.0, 72.0, 34.0), 5.0,
					Color("#e2e8f0"))
				for off: Vector2 in [Vector2(-15.0, 6.0), Vector2(14.0, 7.0), Vector2(0.0, -3.0)]:
					Sprites_Cocina.dibujar_carne_cocida(self, cen + off, 18.0, 9.0, 0.0, false)
			"queso":
				# Tabla con lonchas de queso cheddar apiladas
				Sprites_Cocina.dibujar_caja(self, Rect2(cen.x - 40.0, cen.y - 14.0, 80.0, 42.0), 8.0,
					Color("#d97706"), Color("#78350f"), 1.8)
				for idx in range(3):
					var q_off := Vector2(float(idx - 1) * 7.0, float(idx - 1) * -4.0)
					var pts_q := PackedVector2Array([
						cen + q_off + Vector2(-20.0, 4.0), cen + q_off + Vector2(-2.0, -10.0),
						cen + q_off + Vector2(22.0, -2.0), cen + q_off + Vector2(4.0, 12.0),
					])
					Sprites_Cocina.dibujar_poligono_borde(self, pts_q, Color("#facc15"), Color("#a16207"), 1.5)
			"lechuga":
				# Bandeja con hojas verdes frescas de lechuga
				Sprites_Cocina.dibujar_caja(self, Rect2(cen.x - 40.0, cen.y - 15.0, 80.0, 42.0), 8.0,
					Color("#fef3c7"), Color("#b45309"), 1.8)
				for off: Vector2 in [Vector2(-14.0, 3.0), Vector2(14.0, 4.0), Vector2(0.0, -4.0)]:
					var pts_l := PackedVector2Array()
					for k in range(10):
						var ang := TAU * float(k) / 10.0
						var r_m := 1.15 if k % 2 == 0 else 0.82
						pts_l.append(cen + off + Vector2(cos(ang) * 18.0 * r_m, sin(ang) * 12.0 * r_m))
					Sprites_Cocina.dibujar_poligono_borde(self, pts_l, Color("#22c55e"), Color("#14532d"), 1.4)
					Sprites_Cocina.dibujar_elipse(self, cen + off, 7.0, 4.0, Color("#86efac", 0.7))
			"tomate":
				# Plato blanco con tomates enteros y rodajas rojas (exacto al platito de la captura)
				Sprites_Cocina.dibujar_plato_ceramica(self, cen + Vector2(0.0, 4.0), 38.0, 22.0)
				for off: Vector2 in [Vector2(-13.0, 0.0), Vector2(12.0, -2.0)]:
					draw_circle(cen + off, 11.0, Color("#dc2626"))
					draw_arc(cen + off, 11.0, 0.0, TAU, 16, Color("#7f1d1d"), 1.3, true)
					draw_circle(cen + off + Vector2(-3.0, -3.0), 3.0, Color("#fca5a5", 0.75))
				Sprites_Cocina.dibujar_elipse(self, cen + Vector2(1.0, 10.0), 13.0, 7.0, Color("#ef4444"), Color("#991b1b"), 1.4)
				Sprites_Cocina.dibujar_elipse(self, cen + Vector2(-1.0, 9.0), 7.0, 3.0, Color("#fca5a5", 0.65))
			"patatas":
				# Cesta metálica llena de patatas listas para freír
				Sprites_Cocina.dibujar_caja(self, Rect2(cen.x - 36.0, cen.y - 12.0, 72.0, 38.0), 7.0,
					Color("#94a3b8"), Color("#334155"), 1.8)
				for k in range(-3, 4):
					var px := cen.x + float(k) * 8.0
					var py := cen.y - 14.0 + absf(float(k)) * 1.6
					Sprites_Cocina.dibujar_caja(self, Rect2(px - 3.0, py, 6.0, 24.0), 2.0,
						Color("#fde047"), Color("#b45309"), 1.2)
			"papelera":
				# Cubo de basura retro metálico/rojo
				var col_cuerpo := Color("#dc2626") if activo_papelera else Color("#64748b")
				var col_tapa := Color("#ef4444") if activo_papelera else Color("#94a3b8")
				var cubo := PackedVector2Array([
					cen + Vector2(-22.0, -10.0), cen + Vector2(22.0, -10.0),
					cen + Vector2(17.0, 26.0), cen + Vector2(-17.0, 26.0),
				])
				Sprites_Cocina.dibujar_poligono_borde(self, cubo, col_cuerpo, Color("#1e293b"), 1.8)
				for rx: float in [-8.0, 0.0, 8.0]:
					draw_line(cen + Vector2(rx, -4.0), cen + Vector2(rx * 0.8, 21.0), Color("#1e293b", 0.45), 2.0)
				Sprites_Cocina.dibujar_caja(self, Rect2(cen.x - 25.0, cen.y - 18.0, 50.0, 9.0), 4.0, col_tapa, Color("#1e293b"), 1.6)
				draw_arc(cen + Vector2(0.0, -18.0), 7.0, PI, TAU, 10, Color("#1e293b"), 2.4, true)
