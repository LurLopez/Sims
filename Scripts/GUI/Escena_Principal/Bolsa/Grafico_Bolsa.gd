class_name Grafico_Bolsa
extends Control

# Gráfico de línea para la evolución del beneficio acumulado de la bolsa.
# Dibuja una línea verde por encima de cero y roja por debajo, con relleno
# suave, rejilla, etiquetas y marcadores de aportes/retiradas.

var puntos: Array = []
var marcadores: Array = []
var _fuente: Font
var _fuente_pequena: Font


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, 230)
	_fuente = Estilos_UI.fuente_ui(600)
	_fuente_pequena = Estilos_UI.fuente_ui(500)
	resized.connect(queue_redraw)


func Configurar(nuevos_puntos: Array, nuevos_marcadores: Array = []) -> void:
	puntos = nuevos_puntos.duplicate(true)
	marcadores = nuevos_marcadores.duplicate(true)
	queue_redraw()


func _draw() -> void:
	if _fuente == null:
		_fuente = Estilos_UI.fuente_ui(600)
		_fuente_pequena = Estilos_UI.fuente_ui(500)

	var area := Rect2(46.0, 12.0, maxf(10.0, size.x - 58.0), maxf(10.0, size.y - 38.0))
	if puntos.is_empty():
		_dibujar_vacio(area, "Aún no hay datos de tu cartera")
		return
	if puntos.size() == 1:
		_dibujar_unico(area, puntos[0])
		return

	var min_b := INF
	var max_b := -INF
	for p in puntos:
		var b := float(p.get("beneficio", 0.0))
		min_b = minf(min_b, b)
		max_b = maxf(max_b, b)
	min_b = minf(min_b, 0.0)
	max_b = maxf(max_b, 0.0)
	var rango := max_b - min_b
	if rango < 1.0:
		rango = 1.0
		min_b -= 0.5
		max_b += 0.5
	else:
		min_b -= rango * 0.08
		max_b += rango * 0.08
	var rango_final := max_b - min_b
	if rango_final <= 0.0:
		rango_final = 1.0

	var y_cero := _y_para(0.0, area, min_b, rango_final)
	_dibujar_rejilla(area, min_b, max_b, y_cero)

	# Relleno y línea por tramos, separando positivos y negativos.
	for i in range(1, puntos.size()):
		var p0: Dictionary = puntos[i - 1]
		var p1: Dictionary = puntos[i]
		var b0 := float(p0.get("beneficio", 0.0))
		var b1 := float(p1.get("beneficio", 0.0))
		var pos0 := _punto_pantalla(p0, area, min_b, rango_final)
		var pos1 := _punto_pantalla(p1, area, min_b, rango_final)
		var mismo_lado := (b0 >= 0.0 and b1 >= 0.0) or (b0 <= 0.0 and b1 <= 0.0)
		if mismo_lado:
			var color := Estilos_UI.EXITO if b0 + b1 >= 0.0 else Estilos_UI.PELIGRO
			if absf(b0) > 0.01 or absf(b1) > 0.01:
				draw_colored_polygon(PackedVector2Array([
					pos0, pos1, Vector2(pos1.x, y_cero), Vector2(pos0.x, y_cero)
				]), Color(color, 0.09))
			draw_line(pos0, pos1, color, 2.4, true)
		else:
			var t := -b0 / (b1 - b0)
			var cruce := Vector2(lerpf(pos0.x, pos1.x, t), y_cero)
			var color0 := Estilos_UI.EXITO if b0 > 0.0 else Estilos_UI.PELIGRO
			var color1 := Estilos_UI.EXITO if b1 > 0.0 else Estilos_UI.PELIGRO
			draw_line(pos0, cruce, color0, 2.4, true)
			draw_line(cruce, pos1, color1, 2.4, true)

	_dibujar_marcadores(area, min_b, rango_final)
	_dibujar_extremos(area)

	# Punto final destacado.
	var ultimo: Dictionary = puntos[-1]
	var fin := _punto_pantalla(ultimo, area, min_b, rango_final)
	var color_fin := Estilos_UI.EXITO if float(ultimo.get("beneficio", 0.0)) >= 0.0 else Estilos_UI.PELIGRO
	draw_circle(fin, 5.5, Color.WHITE)
	draw_circle(fin, 3.6, color_fin)


func _dibujar_rejilla(area: Rect2, min_b: float, max_b: float, y_cero: float) -> void:
	for i in range(4):
		var t := float(i) / 3.0
		var y := area.position.y + area.size.y * t
		draw_line(Vector2(area.position.x, y), Vector2(area.end.x, y),
			Color(Estilos_UI.BORDE, 0.55), 1.0)
		var valor := lerpf(max_b, min_b, t)
		draw_string(_fuente_pequena, Vector2(0, y + 3.5), _formatear(valor),
			HORIZONTAL_ALIGNMENT_LEFT, 43.0, 9, Estilos_UI.TINTA_FANTASMA)

	if y_cero >= area.position.y and y_cero <= area.end.y:
		_dibujar_linea_discontinua(
			Vector2(area.position.x, y_cero), Vector2(area.end.x, y_cero),
			Color(Estilos_UI.TINTA_FANTASMA, 0.55), 1.2)
		draw_string(_fuente_pequena, Vector2(0, y_cero + 3.5), "0 €",
			HORIZONTAL_ALIGNMENT_LEFT, 43.0, 9, Estilos_UI.TINTA_SUAVE)


func _dibujar_marcadores(area: Rect2, min_b: float, rango_final: float) -> void:
	if marcadores.is_empty():
		return
	var primero := int(puntos[0].get("minuto", 0))
	var ultimo := int(puntos[-1].get("minuto", primero))
	var inicio := maxi(0, marcadores.size() - 22)
	for i in range(inicio, marcadores.size()):
		var op = marcadores[i]
		if not (op is Dictionary):
			continue
		var m := int(op.get("minuto", 0))
		if m < primero or m > ultimo:
			continue
		var x := _x_para_minuto(m, area, primero, ultimo)
		var acumulado := float(op.get("acumulado", 0.0))
		var y := _y_para(acumulado, area, min_b, rango_final)
		var color := Estilos_UI.AZUL
		match str(op.get("tipo", "aporte")):
			"retirada":
				color = Estilos_UI.ORO
			"auto_venta":
				color = Estilos_UI.PELIGRO
		draw_circle(Vector2(x, y), 4.4, Color.WHITE)
		draw_circle(Vector2(x, y), 2.6, color)


func _dibujar_extremos(area: Rect2) -> void:
	var primero: Dictionary = puntos[0]
	var ultimo: Dictionary = puntos[-1]
	var texto_izq := _texto_delta(
		int(ultimo.get("minuto", 0)) - int(primero.get("minuto", 0)))
	var y := size.y - 8.0
	draw_string(_fuente_pequena, Vector2(area.position.x, y), texto_izq,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Estilos_UI.TINTA_FANTASMA)
	draw_string(_fuente_pequena, Vector2(area.end.x - 60.0, y), "Ahora",
		HORIZONTAL_ALIGNMENT_RIGHT, 60.0, 9, Estilos_UI.TINTA_FANTASMA)


func _dibujar_vacio(area: Rect2, mensaje: String) -> void:
	var centro_y := area.position.y + area.size.y * 0.5
	draw_line(Vector2(area.position.x, centro_y), Vector2(area.end.x, centro_y),
		Color(Estilos_UI.BORDE, 0.6), 1.0)
	draw_string(_fuente, Vector2(area.position.x, centro_y - 12.0), mensaje,
		HORIZONTAL_ALIGNMENT_CENTER, area.size.x, 12, Estilos_UI.TINTA_FANTASMA)
	draw_string(_fuente_pequena, Vector2(area.position.x, centro_y + 22.0),
		"El gráfico empezará cuando hagas tu primer aporte",
		HORIZONTAL_ALIGNMENT_CENTER, area.size.x, 10, Color(Estilos_UI.TINTA_FANTASMA, 0.8))


func _dibujar_unico(area: Rect2, punto: Dictionary) -> void:
	var b := float(punto.get("beneficio", 0.0))
	var color := Estilos_UI.EXITO if b >= 0.0 else Estilos_UI.PELIGRO
	var y_cero := area.position.y + area.size.y * 0.75
	_dibujar_linea_discontinua(Vector2(area.position.x, y_cero), Vector2(area.end.x, y_cero),
		Color(Estilos_UI.TINTA_FANTASMA, 0.5), 1.0)
	var centro := Vector2(area.position.x + area.size.x * 0.5, area.position.y + area.size.y * 0.5)
	draw_line(Vector2(centro.x, y_cero), centro, color, 2.4, true)
	draw_circle(centro, 5.0, Color.WHITE)
	draw_circle(centro, 3.4, color)
	draw_string(_fuente, Vector2(area.position.x, area.end.y - 2.0),
		"Primer registro · esperando más movimientos",
		HORIZONTAL_ALIGNMENT_CENTER, area.size.x, 10, Estilos_UI.TINTA_FANTASMA)


func _punto_pantalla(p: Dictionary, area: Rect2, min_b: float, rango_final: float) -> Vector2:
	var primero := int(puntos[0].get("minuto", 0))
	var ultimo := int(puntos[-1].get("minuto", primero))
	var x := _x_para_minuto(int(p.get("minuto", primero)), area, primero, ultimo)
	var y := _y_para(float(p.get("beneficio", 0.0)), area, min_b, rango_final)
	return Vector2(x, y)


func _x_para_minuto(minuto: int, area: Rect2, primero: int, ultimo: int) -> float:
	if ultimo <= primero:
		return area.position.x + area.size.x * 0.5
	var t := float(minuto - primero) / float(ultimo - primero)
	return area.position.x + clampf(t, 0.0, 1.0) * area.size.x


func _y_para(valor: float, area: Rect2, min_b: float, rango_final: float) -> float:
	var t := (valor - min_b) / rango_final
	return area.end.y - clampf(t, 0.0, 1.0) * area.size.y


func _dibujar_linea_discontinua(desde: Vector2, hasta: Vector2, color: Color, grosor: float) -> void:
	var largo := desde.distance_to(hasta)
	if largo <= 0.0:
		return
	var direccion := (hasta - desde).normalized()
	var recorrido := 0.0
	while recorrido < largo:
		var fin := minf(recorrido + 5.0, largo)
		draw_line(desde + direccion * recorrido, desde + direccion * fin, color, grosor, true)
		recorrido += 9.0


func _formatear(valor: float) -> String:
	var negativo := valor < -0.5
	var absoluto := absf(valor)
	var texto := ""
	if absoluto >= 10000.0:
		texto = "%.0fk" % (absoluto / 1000.0)
	elif absoluto >= 100.0:
		texto = "%.0f" % absoluto
	elif absoluto >= 10.0:
		texto = "%.1f" % absoluto
	else:
		texto = "%.1f" % absoluto
	return ("-" if negativo else "") + texto


func _texto_delta(minutos: int) -> String:
	minutos = maxi(0, minutos)
	if minutos < 60:
		return "Ahora"
	if minutos < 1440:
		return "Hace %d h" % int(minutos / 60)
	var dias := int(minutos / 1440)
	if dias < maxi(1, int(Variables_Estaticas.Dias_Por_Anio())):
		return "Hace %d d" % dias
	var anios := int(minutos / (maxi(1, int(Variables_Estaticas.Dias_Por_Anio())) * 1440))
	return "Hace %d a" % anios
