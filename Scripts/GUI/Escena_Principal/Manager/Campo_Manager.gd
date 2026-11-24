class_name Campo_Manager
extends Control

# Pizarra táctica interactiva del modo «El Mánager». Dibuja un campo vertical
# con áreas, arcos y césped segado, muestra las 11 posiciones con dorsal,
# apellido, anillo de energía, insignia de capitán y aviso de afinidad,
# y permite tocar directamente cualquier jugador para seleccionarlo o cambiarlo.

signal slot_tocado(indice: int, jugador_id: String)

const POSICIONES_FORMACION: Dictionary = {
	"4-4-2": [
		Vector2(0.50, 0.865),
		Vector2(0.15, 0.70), Vector2(0.38, 0.74), Vector2(0.62, 0.74), Vector2(0.85, 0.70),
		Vector2(0.15, 0.44), Vector2(0.38, 0.48), Vector2(0.62, 0.48), Vector2(0.85, 0.44),
		Vector2(0.36, 0.17), Vector2(0.64, 0.17)
	],
	"4-3-3": [
		Vector2(0.50, 0.865),
		Vector2(0.15, 0.70), Vector2(0.38, 0.74), Vector2(0.62, 0.74), Vector2(0.85, 0.70),
		Vector2(0.50, 0.54), Vector2(0.28, 0.44), Vector2(0.72, 0.44),
		Vector2(0.18, 0.19), Vector2(0.50, 0.13), Vector2(0.82, 0.19)
	],
	"3-5-2": [
		Vector2(0.50, 0.865),
		Vector2(0.25, 0.73), Vector2(0.50, 0.76), Vector2(0.75, 0.73),
		Vector2(0.12, 0.44), Vector2(0.33, 0.50), Vector2(0.50, 0.58),
		Vector2(0.67, 0.50), Vector2(0.88, 0.44),
		Vector2(0.36, 0.17), Vector2(0.64, 0.17)
	],
	"4-2-3-1": [
		Vector2(0.50, 0.865),
		Vector2(0.15, 0.70), Vector2(0.38, 0.74), Vector2(0.62, 0.74), Vector2(0.85, 0.70),
		Vector2(0.36, 0.54), Vector2(0.64, 0.54),
		Vector2(0.20, 0.34), Vector2(0.50, 0.36), Vector2(0.80, 0.34),
		Vector2(0.50, 0.13)
	]
}

var alineacion: Array = []
var jugadores: Dictionary = {}
var formacion: String = "4-4-2"
var color_primario: Color = Color("#d62828")
var color_secundario: Color = Color("#ffffff")
var seleccionado_id: String = ""
var capitan_id: String = ""
var _fuente: Font = null
var _fuente_sub: Font = null


func _ready() -> void:
	custom_minimum_size = Vector2(0, 390)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_fuente = Estilos_UI.fuente_ui(700)
	_fuente_sub = Estilos_UI.fuente_ui(600)
	resized.connect(queue_redraw)


func configurar(alineacion_ids: Array, plantilla: Array, formacion_actual: String,
		colores: Array, seleccionado: String = "", capitan: String = "") -> void:
	alineacion = alineacion_ids.duplicate()
	formacion = formacion_actual if POSICIONES_FORMACION.has(formacion_actual) else "4-4-2"
	seleccionado_id = seleccionado
	capitan_id = capitan
	jugadores = {}
	for jugador in plantilla:
		if jugador is Dictionary:
			jugadores[str(jugador.get("id", ""))] = jugador
	if colores is Array and colores.size() >= 2:
		color_primario = Color(str(colores[0]))
		color_secundario = Color(str(colores[1]))
	_fuente = Estilos_UI.fuente_ui(700)
	_fuente_sub = Estilos_UI.fuente_ui(600)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_Procesar_Toque(mb.position)
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_Procesar_Toque(st.position)


func _Procesar_Toque(pos: Vector2) -> void:
	var posiciones: Array = POSICIONES_FORMACION.get(formacion, POSICIONES_FORMACION["4-4-2"])
	var radio_toque: float = maxf(30.0, minf(size.x, size.y) * 0.10)
	var mejor_idx: int = -1
	var mejor_dist: float = radio_toque
	for i in range(mini(alineacion.size(), posiciones.size())):
		var centro := Vector2(size.x * float(posiciones[i].x), size.y * float(posiciones[i].y))
		var d: float = pos.distance_to(centro)
		if d <= mejor_dist:
			mejor_dist = d
			mejor_idx = i
	if mejor_idx >= 0:
		Estilo_Manager.reproducir_sfx("click")
		slot_tocado.emit(mejor_idx, str(alineacion[mejor_idx]))
		accept_event()


func _Apellido(nombre: String) -> String:
	var partes: PackedStringArray = nombre.strip_edges().split(" ", false)
	if partes.size() >= 2:
		return partes[partes.size() - 1]
	return nombre.left(10)


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if rect.size.x < 10.0 or rect.size.y < 10.0:
		return

	# Césped con franjas alternas.
	draw_rect(rect, Color("#15803d"))
	var franjas: int = 10
	for i in range(franjas):
		if i % 2 == 0:
			draw_rect(Rect2(0, rect.size.y * float(i) / float(franjas),
				rect.size.x, rect.size.y / float(franjas)), Color("#166534"))

	# Borde sutil de estadio.
	draw_rect(Rect2(0, 0, rect.size.x, 8), Color(0, 0, 0, 0.14))
	draw_rect(Rect2(0, rect.size.y - 8, rect.size.x, 8), Color(0, 0, 0, 0.14))

	# Líneas del campo.
	var linea := Color(1, 1, 1, 0.45)
	var grosor: float = maxf(1.6, rect.size.x * 0.0038)
	var margen: float = rect.size.x * 0.04
	var ancho_campo: float = rect.size.x - margen * 2.0
	var alto_campo: float = rect.size.y - margen * 2.0

	draw_rect(Rect2(margen, margen, ancho_campo, alto_campo), linea, false, grosor)
	draw_line(Vector2(margen, rect.size.y * 0.5),
		Vector2(rect.size.x - margen, rect.size.y * 0.5), linea, grosor)
	draw_circle(Vector2(rect.size.x * 0.5, rect.size.y * 0.5),
		rect.size.x * 0.115, linea, false, grosor)
	draw_circle(Vector2(rect.size.x * 0.5, rect.size.y * 0.5), 3.2, linea)

	# Áreas grandes y chicas.
	var area_w: float = ancho_campo * 0.52
	var area_h: float = alto_campo * 0.16
	draw_rect(Rect2(rect.size.x * 0.5 - area_w * 0.5, margen, area_w, area_h), linea, false, grosor)
	draw_rect(Rect2(rect.size.x * 0.5 - area_w * 0.5, rect.size.y - margen - area_h, area_w, area_h),
		linea, false, grosor)
	var chica_w: float = ancho_campo * 0.25
	var chica_h: float = alto_campo * 0.06
	draw_rect(Rect2(rect.size.x * 0.5 - chica_w * 0.5, margen, chica_w, chica_h), linea, false, grosor)
	draw_rect(Rect2(rect.size.x * 0.5 - chica_w * 0.5, rect.size.y - margen - chica_h, chica_w, chica_h),
		linea, false, grosor)
	# Porterías.
	var port_w: float = ancho_campo * 0.13
	draw_rect(Rect2(rect.size.x * 0.5 - port_w * 0.5, margen - 6.0, port_w, 6.0),
		Color(1, 1, 1, 0.55), false, grosor)
	draw_rect(Rect2(rect.size.x * 0.5 - port_w * 0.5, rect.size.y - margen, port_w, 6.0),
		Color(1, 1, 1, 0.55), false, grosor)

	var posiciones: Array = POSICIONES_FORMACION.get(formacion, POSICIONES_FORMACION["4-4-2"])
	var slots: Array = Datos_Manager.ROLES_FORMACION.get(formacion, Datos_Manager.ROLES_FORMACION["4-4-2"])
	var radio: float = clampf(minf(rect.size.x, rect.size.y) * 0.052, 16.0, 23.0)

	for i in range(mini(alineacion.size(), posiciones.size())):
		var centro := Vector2(
			rect.size.x * float(posiciones[i].x),
			rect.size.y * float(posiciones[i].y))
		var jugador_id: String = str(alineacion[i])
		var jugador: Dictionary = jugadores.get(jugador_id, {})
		var dorsal: int = int(jugador.get("dorsal", i + 1))
		var energia: float = float(jugador.get("energia", 100.0))
		var ranura: String = str(slots[i]) if i < slots.size() else "MC"
		var afinidad: float = Simulador_Manager._Afinidad_Ranura(jugador, ranura) if not jugador.is_empty() else 1.0
		var es_sel: bool = seleccionado_id != "" and jugador_id == seleccionado_id
		var es_cap: bool = capitan_id != "" and jugador_id == capitan_id

		# Halo de selección.
		if es_sel:
			draw_circle(centro, radio + 8.0, Color("#fbbf24", 0.36))
			draw_arc(centro, radio + 7.5, 0.0, TAU, 36, Color("#fbbf24"), 2.8, true)

		# Anillo exterior de energía.
		var col_e: Color = Color("#22c55e") if energia >= 65.0 else (
			Color("#f59e0b") if energia >= 38.0 else Color("#ef4444"))
		var ang_e: float = -PI * 0.5 + TAU * clampf(energia / 100.0, 0.05, 1.0)
		draw_arc(centro, radio + 3.2, 0.0, TAU, 32, Color(0, 0, 0, 0.35), 2.8, true)
		draw_arc(centro, radio + 3.2, -PI * 0.5, ang_e, 32, col_e, 2.8, true)

		# Sombra y ficha del jugador.
		draw_circle(centro + Vector2(1.5, 2.5), radio, Color(0, 0, 0, 0.32))
		var col_fill: Color = Color("#f59e0b") if ranura == "POR" and color_primario.to_html(false) != "ca8a04" else color_primario
		var col_borde: Color = Color("#111827") if ranura == "POR" else color_secundario
		draw_circle(centro, radio, col_fill)
		draw_arc(centro, radio, 0.0, TAU, 36, col_borde, maxf(1.8, radio * 0.14), true)

		if _fuente != null:
			var texto_d: String = str(dorsal)
			var tam: int = int(radio * 0.96)
			var ancho: float = _fuente.get_string_size(texto_d, HORIZONTAL_ALIGNMENT_CENTER, -1.0, tam).x
			var col_num: Color = col_borde if col_fill.get_luminance() < 0.7 else Estilos_UI.TINTA
			if Vector3(col_num.r - col_fill.r, col_num.g - col_fill.g, col_num.b - col_fill.b).length() < 0.25:
				col_num = Estilo_Manager.color_para_fondo(col_fill)
			draw_string(_fuente,
				centro + Vector2(-ancho * 0.5, _fuente.get_ascent(tam) * 0.36),
				texto_d, HORIZONTAL_ALIGNMENT_LEFT, -1.0, tam, col_num)

		# Insignia de capitán (C) o aviso de posición (!).
		if es_cap:
			var c_pos := centro + Vector2(radio * 0.78, -radio * 0.78)
			draw_circle(c_pos, 7.5, Color("#fbbf24"))
			draw_arc(c_pos, 7.5, 0.0, TAU, 16, Color("#78350f"), 1.2, true)
			if _fuente != null:
				draw_string(_fuente, c_pos + Vector2(-3.5, 3.5), "C", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 9, Color("#78350f"))
		if afinidad < 0.70:
			var a_pos := centro + Vector2(-radio * 0.78, -radio * 0.78)
			draw_circle(a_pos, 7.5, Color("#ef4444"))
			draw_arc(a_pos, 7.5, 0.0, TAU, 16, Color.WHITE, 1.2, true)
			if _fuente != null:
				draw_string(_fuente, a_pos + Vector2(-2.0, 3.5), "!", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color.WHITE)

		# Píldora oscura legible con apellido y rol debajo del nodo.
		if _fuente_sub != null:
			var apellido: String = _Apellido(str(jugador.get("nombre", "")))
			var etiqueta: String = "%s · %s" % [ranura, apellido]
			var tam_lbl: int = 10
			var w_txt: float = _fuente_sub.get_string_size(etiqueta, HORIZONTAL_ALIGNMENT_CENTER, -1.0, tam_lbl).x
			var pill_w: float = minf(w_txt + 10.0, rect.size.x * 0.24)
			var pill_rect := Rect2(centro.x - pill_w * 0.5, centro.y + radio + 5.0, pill_w, 15.0)
			draw_rect(pill_rect, Color(0.05, 0.09, 0.14, 0.78))
			var col_et: Color = Color("#fde047") if es_sel else (Color("#fca5a5") if afinidad < 0.70 else Color.WHITE)
			var pos_txt := Vector2(centro.x - minf(w_txt, pill_w - 6.0) * 0.5, pill_rect.position.y + 11.5)
			draw_string(_fuente_sub, pos_txt, etiqueta, HORIZONTAL_ALIGNMENT_LEFT,
				pill_w - 4.0, tam_lbl, col_et)
