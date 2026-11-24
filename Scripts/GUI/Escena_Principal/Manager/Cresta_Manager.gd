class_name Cresta_Manager
extends Control

# Escudo vectorial procedural del modo «El Mánager». Se dibuja con _draw():
# silueta heráldica suave, 5 patrones recortados con precisión mediante
# Geometry2D.intersect_polygons, medallón central con las iniciales del club,
# brillo diagonal y borde metálico.

@export var color_primario: Color = Color("#d62828")
@export var color_secundario: Color = Color("#ffffff")
@export var patron: int = 1
@export var iniciales: String = "CS"
@export var mostrar_sombra: bool = true

var _fuente: Font = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fuente = Estilos_UI.fuente_titulo(700)
	resized.connect(queue_redraw)


func configurar(nombre: String, colores: Array, patron_escudo: int,
		sombra: bool = true) -> void:
	patron = clampi(patron_escudo, 0, Datos_Manager.PATRONES_ESCUDO.size() - 1)
	mostrar_sombra = sombra
	if colores is Array and colores.size() >= 2:
		color_primario = Color(str(colores[0]))
		color_secundario = Color(str(colores[1]))
	iniciales = _Extraer_Iniciales(nombre)
	_fuente = Estilos_UI.fuente_titulo(700)
	queue_redraw()


func _Extraer_Iniciales(nombre: String) -> String:
	var limpio: String = nombre.strip_edges()
	if limpio == "":
		return "CS"
	var palabras: PackedStringArray = limpio.split(" ", false)
	var resultado: String = ""
	for palabra in palabras:
		if palabra.length() > 0:
			resultado += palabra.substr(0, 1).to_upper()
		if resultado.length() >= 3:
			break
	if resultado == "":
		resultado = limpio.substr(0, 1).to_upper()
	return resultado


func _Puntos_Escudo(rect: Rect2) -> PackedVector2Array:
	var x0: float = rect.position.x + rect.size.x * 0.08
	var x1: float = rect.position.x + rect.size.x * 0.92
	var xm: float = rect.position.x + rect.size.x * 0.50
	var y0: float = rect.position.y + rect.size.y * 0.05
	var y_top_mid: float = rect.position.y + rect.size.y * 0.08
	var y_lado: float = rect.position.y + rect.size.y * 0.52
	var y_bot: float = rect.position.y + rect.size.y * 0.96

	var pts: Array[Vector2] = [
		Vector2(x0, y_top_mid),
		Vector2(xm, y0),
		Vector2(x1, y_top_mid),
		Vector2(x1, y_lado)
	]
	# Curva derecha suave hacia la punta inferior.
	for i in range(1, 7):
		var t: float = float(i) / 7.0
		var p0 := Vector2(x1, y_lado)
		var p1 := Vector2(x1 - rect.size.x * 0.05, rect.position.y + rect.size.y * 0.80)
		var p2 := Vector2(xm, y_bot)
		pts.append(p0.lerp(p1, t).lerp(p1.lerp(p2, t), t))
	pts.append(Vector2(xm, y_bot))
	# Curva izquierda suave hacia arriba.
	for i in range(1, 7):
		var t: float = float(i) / 7.0
		var p0 := Vector2(xm, y_bot)
		var p1 := Vector2(x0 + rect.size.x * 0.05, rect.position.y + rect.size.y * 0.80)
		var p2 := Vector2(x0, y_lado)
		pts.append(p0.lerp(p1, t).lerp(p1.lerp(p2, t), t))
	pts.append(Vector2(x0, y_lado))
	return PackedVector2Array(pts)


func _Dibujar_Recortado(escudo: PackedVector2Array, forma: PackedVector2Array, color: Color) -> void:
	var partes := Geometry2D.intersect_polygons(escudo, forma)
	for parte in partes:
		if parte.size() >= 3:
			draw_colored_polygon(parte, color)


func _draw() -> void:
	if size.x <= 2.0 or size.y <= 2.0:
		return
	var margen: float = maxf(2.0, size.x * 0.025)
	var rect := Rect2(Vector2(margen, margen), size - Vector2(margen * 2.0, margen * 2.0))
	var puntos: PackedVector2Array = _Puntos_Escudo(rect)

	if mostrar_sombra:
		var sombra := PackedVector2Array()
		for p in puntos:
			sombra.append(p + Vector2(0.0, size.y * 0.035))
		draw_colored_polygon(sombra, Color(0.04, 0.06, 0.12, 0.24))

	# Cuerpo principal del escudo.
	draw_colored_polygon(puntos, color_primario)

	var x0: float = rect.position.x
	var y0: float = rect.position.y
	var w: float = rect.size.x
	var h: float = rect.size.y

	match patron:
		1:
			# Franjas verticales.
			var ancho: float = w * 0.16
			for cx in [x0 + w * 0.30, x0 + w * 0.70]:
				var fr := PackedVector2Array([
					Vector2(cx - ancho * 0.5, y0), Vector2(cx + ancho * 0.5, y0),
					Vector2(cx + ancho * 0.5, y0 + h), Vector2(cx - ancho * 0.5, y0 + h)
				])
				_Dibujar_Recortado(puntos, fr, color_secundario)
		2:
			# Banda diagonal.
			var banda := PackedVector2Array([
				Vector2(x0 - w * 0.1, y0 + h * 0.65),
				Vector2(x0 - w * 0.1, y0 + h * 0.90),
				Vector2(x0 + w * 1.1, y0 + h * 0.30),
				Vector2(x0 + w * 1.1, y0 + h * 0.05)
			])
			_Dibujar_Recortado(puntos, banda, color_secundario)
		3:
			# Mitades verticales.
			var mitad := PackedVector2Array([
				Vector2(x0 + w * 0.50, y0), Vector2(x0 + w, y0),
				Vector2(x0 + w, y0 + h), Vector2(x0 + w * 0.50, y0 + h)
			])
			_Dibujar_Recortado(puntos, mitad, color_secundario)
		4:
			# Cruz centrada.
			var v_bar := PackedVector2Array([
				Vector2(x0 + w * 0.43, y0), Vector2(x0 + w * 0.57, y0),
				Vector2(x0 + w * 0.57, y0 + h), Vector2(x0 + w * 0.43, y0 + h)
			])
			var h_bar := PackedVector2Array([
				Vector2(x0, y0 + h * 0.36), Vector2(x0 + w, y0 + h * 0.36),
				Vector2(x0 + w, y0 + h * 0.50), Vector2(x0, y0 + h * 0.50)
			])
			_Dibujar_Recortado(puntos, v_bar, color_secundario)
			_Dibujar_Recortado(puntos, h_bar, color_secundario)
		_:
			# Liso con banda horizontal elegante.
			var banda_h := PackedVector2Array([
				Vector2(x0, y0 + h * 0.38), Vector2(x0 + w, y0 + h * 0.38),
				Vector2(x0 + w, y0 + h * 0.50), Vector2(x0, y0 + h * 0.50)
			])
			_Dibujar_Recortado(puntos, banda_h, color_secundario)

	# Sombra sutil derecha para dar relieve 2.5D.
	var sombra_rel := PackedVector2Array([
		Vector2(x0 + w * 0.50, y0), Vector2(x0 + w, y0),
		Vector2(x0 + w, y0 + h), Vector2(x0 + w * 0.50, y0 + h)
	])
	_Dibujar_Recortado(puntos, sombra_rel, Color(0, 0, 0, 0.10))

	# Brillo superior sutil.
	var brillo := PackedVector2Array([
		Vector2(x0, y0), Vector2(x0 + w, y0),
		Vector2(x0 + w, y0 + h * 0.24), Vector2(x0, y0 + h * 0.24)
	])
	_Dibujar_Recortado(puntos, brillo, Color(1, 1, 1, 0.14))

	# Medallón central con las iniciales.
	var centro := Vector2(x0 + w * 0.50, y0 + h * 0.43)
	var radio: float = minf(w, h) * 0.23
	draw_circle(centro + Vector2(0.0, radio * 0.08), radio, Color(0, 0, 0, 0.18))
	draw_circle(centro, radio, color_secundario)
	draw_arc(centro, radio, 0.0, TAU, 48, color_primario.darkened(0.18),
		maxf(1.2, radio * 0.10), true)

	if _fuente == null:
		_fuente = Estilos_UI.fuente_titulo(700)
	if _fuente != null:
		var tam: int = maxi(8, int(radio * 0.92))
		var texto: String = iniciales
		var ancho_texto: float = _fuente.get_string_size(
			texto, HORIZONTAL_ALIGNMENT_CENTER, -1.0, tam).x
		var pos := Vector2(centro.x - ancho_texto * 0.5,
			centro.y + _fuente.get_ascent(tam) * 0.34)
		var color_txt: Color = color_primario.darkened(0.18)
		if color_secundario.get_luminance() < 0.25 and color_primario.get_luminance() < 0.25:
			color_txt = Color.WHITE
		draw_string(_fuente, pos, texto, HORIZONTAL_ALIGNMENT_LEFT, -1.0, tam, color_txt)

	# Borde metálico exterior e interior.
	var contorno: PackedVector2Array = puntos.duplicate()
	contorno.append(puntos[0])
	draw_polyline(contorno, color_secundario.darkened(0.12),
		maxf(2.0, size.x * 0.036), true)
	draw_polyline(contorno, Color(0.06, 0.09, 0.16, 0.35),
		maxf(1.0, size.x * 0.012), true)
