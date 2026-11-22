class_name Anillo_Nota
extends Control

# Anillo de progreso usado en las pantallas de resultado de los exámenes.
# Dibuja el fondo, el arco de nota y un centro claro para colocar el número.

var valor: float = 0.0
var color: Color = Color("#1ea34a")
var grosor: float = 11.0
var fondo_centro: Color = Color(1, 1, 1, 0.85)


func _init(valor_inicial: float = 0.0, color_inicial: Color = Color("#1ea34a")) -> void:
	valor = clampf(valor_inicial, 0.0, 100.0)
	color = color_inicial
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var centro := size * 0.5
	var radio := minf(size.x, size.y) * 0.5 - 10.0
	draw_circle(centro, radio - 6.0, Color(fondo_centro, fondo_centro.a * 0.75))
	draw_arc(centro, radio, 0.0, TAU, 80, Color(color, 0.16), grosor, true)
	if valor > 0.0:
		var inicio := -PI * 0.5
		var fin := inicio + TAU * (valor / 100.0)
		draw_arc(centro, radio, inicio, fin, 80, color, grosor, true)
		var p_inicio := centro + Vector2(cos(inicio), sin(inicio)) * radio
		var p_fin := centro + Vector2(cos(fin), sin(fin)) * radio
		draw_circle(p_inicio, grosor * 0.5, color)
		draw_circle(p_fin, grosor * 0.5, color)
	draw_circle(centro, radio - 12.0, Color(fondo_centro, fondo_centro.a * 0.55))
