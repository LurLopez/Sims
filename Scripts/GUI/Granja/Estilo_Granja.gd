class_name Estilo_Granja
extends RefCounted

# ============================================================================
# Lenguaje visual cohesivo de «La Granja» (estilo cálido de madera, pergamino
# crema, botones 3D con bisel inferior y paleta viva tipo Family Farm/Hay Day).
# ============================================================================

const CREMA := Color("#fffdf5")
const PERGAMINO := Color("#fbf5e6")
const MADERA_OSCURA := Color("#5c3416")
const MADERA := Color("#8b5224")
const MADERA_CLARA := Color("#c68642")
const VERDE_BOSQUE := Color("#14532d")
const VERDE := Color("#16a34a")
const VERDE_CLARO := Color("#dcfce7")
const ORO := Color("#f59e0b")
const ORO_OSCURO := Color("#b45309")
const ORO_SUAVE := Color("#fef3c7")
const AZUL := Color("#0284c7")
const AZUL_SUAVE := Color("#e0f2fe")
const MORADO := Color("#7c3aed")
const MORADO_SUAVE := Color("#f3e8ff")
const ROJO := Color("#dc2626")
const ROJO_SUAVE := Color("#fee2e2")
const TINTA := Color("#3b2511")
const TINTA_SUAVE := Color("#7c5c3b")


static func panel_madera(fondo: Color = CREMA, borde: Color = MADERA,
		radio: int = 18, grosor: int = 2, sombra: int = 7) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = fondo
	st.border_color = borde
	st.set_border_width_all(grosor)
	st.border_width_bottom = grosor + 3
	st.set_corner_radius_all(radio)
	if sombra > 0:
		st.shadow_color = Color(0.10, 0.20, 0.04, 0.30)
		st.shadow_size = sombra
		st.shadow_offset = Vector2(0, 3)
	st.anti_aliasing = true
	return st


static func panel_dock(fondo: Color = Color(0.99, 0.96, 0.89, 0.94),
		borde: Color = Color("#9b642c"), radio: int = 22) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = fondo
	st.border_color = borde
	st.set_border_width_all(2)
	st.border_width_bottom = 5
	st.set_corner_radius_all(radio)
	st.shadow_color = Color(0.08, 0.18, 0.03, 0.34)
	st.shadow_size = 10
	st.shadow_offset = Vector2(0, 4)
	st.anti_aliasing = true
	return st


static func aplicar_boton(btn: Button, color_fondo: Color, color_borde: Color,
		color_texto: Color, color_icono: Color, radio: int = 15,
		margen_h: int = 13) -> void:
	btn.add_theme_color_override("font_color", color_texto)
	btn.add_theme_color_override("font_hover_color", color_texto)
	btn.add_theme_color_override("font_pressed_color", color_texto)
	btn.add_theme_color_override("font_disabled_color", Color(color_texto, 0.45))
	btn.add_theme_color_override("icon_normal_color", color_icono)
	btn.add_theme_color_override("icon_hover_color", color_icono)
	btn.add_theme_color_override("icon_pressed_color", color_icono)
	btn.add_theme_color_override("icon_disabled_color", Color(color_icono, 0.45))

	var normal := panel_madera(color_fondo, color_borde, radio, 2, 5)
	normal.content_margin_left = margen_h
	normal.content_margin_right = margen_h
	normal.content_margin_top = 4
	normal.content_margin_bottom = 6

	var hover := panel_madera(color_fondo.lightened(0.05), color_borde.darkened(0.06), radio, 2, 6)
	hover.content_margin_left = margen_h
	hover.content_margin_right = margen_h
	hover.content_margin_top = 4
	hover.content_margin_bottom = 6

	var pressed := panel_madera(color_fondo.darkened(0.06), color_borde.darkened(0.12), radio, 2, 2)
	pressed.border_width_bottom = 2
	pressed.content_margin_left = margen_h
	pressed.content_margin_right = margen_h
	pressed.content_margin_top = 6
	pressed.content_margin_bottom = 4

	var disabled := panel_madera(Color(color_fondo, 0.58), Color(color_borde, 0.40), radio, 2, 0)
	disabled.border_width_bottom = 2
	disabled.content_margin_left = margen_h
	disabled.content_margin_right = margen_h
	disabled.content_margin_top = 4
	disabled.content_margin_bottom = 4

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


static func crear_boton_hud(texto: String, icono_nombre: String, color_icono: Color,
		color_fondo: Color = CREMA, color_borde: Color = MADERA_CLARA,
		color_texto: Color = TINTA, ancho: float = 136.0, alto: float = 46.0,
		tam_fuente: int = 14) -> Button:
	var btn := Button.new()
	btn.text = texto
	btn.custom_minimum_size = Vector2(ancho, alto)
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_override("font", Estilos_UI.fuente_ui(700))
	btn.add_theme_font_size_override("font_size", tam_fuente)
	btn.add_theme_constant_override("h_separation", 7 if texto != "" else 0)
	if texto == "":
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if icono_nombre != "":
		var tex := Estilos_UI.icono(icono_nombre)
		if tex != null:
			btn.icon = tex
			btn.expand_icon = true
			btn.add_theme_constant_override("icon_max_width", 19)
	aplicar_boton(btn, color_fondo, color_borde, color_texto, color_icono, 15, 12 if texto != "" else 0)
	return btn


static func pill_etiqueta(texto: String, fondo: Color, borde: Color,
		color_texto: Color, tam_fuente: int = 11) -> PanelContainer:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := StyleBoxFlat.new()
	st.bg_color = fondo
	st.border_color = borde
	st.set_border_width_all(1)
	st.border_width_bottom = 2
	st.set_corner_radius_all(10)
	st.content_margin_left = 8
	st.content_margin_right = 8
	st.content_margin_top = 2
	st.content_margin_bottom = 3
	st.anti_aliasing = true
	p.add_theme_stylebox_override("panel", st)
	var lbl := Estilos_UI.texto(texto, tam_fuente, color_texto, 700)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(lbl)
	return p


# Mini visualización de la huella (2×2, 3×3, 4×3, 4×4) para las tarjetas de la tienda.
class HuellaBadge:
	extends Control

	var ancho_celdas: int = 2
	var alto_celdas: int = 2
	var color_relleno: Color = Color("#16a34a")
	var color_borde: Color = Color("#14532d")

	func configurar(w: int, h: int, relleno: Color = Color("#16a34a"), borde: Color = Color("#14532d")) -> void:
		ancho_celdas = maxi(1, w)
		alto_celdas = maxi(1, h)
		color_relleno = relleno
		color_borde = borde
		custom_minimum_size = Vector2(34, 24)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		queue_redraw()

	func _draw() -> void:
		var max_dim: float = float(maxi(ancho_celdas, alto_celdas))
		var rx: float = minf(size.x * 0.44 / max_dim, 5.2)
		var ry: float = rx * 0.52
		var centro := Vector2(size.x * 0.5, size.y * 0.52)
		var cx_off: float = float(ancho_celdas - 1) * 0.5
		var cy_off: float = float(alto_celdas - 1) * 0.5
		for gy in range(alto_celdas):
			for gx in range(ancho_celdas):
				var dx: float = float(gx) - cx_off
				var dy: float = float(gy) - cy_off
				var p := centro + Vector2((dx - dy) * rx, (dx + dy) * ry)
				var pts := PackedVector2Array([
					p + Vector2(0, -ry),
					p + Vector2(rx, 0),
					p + Vector2(0, ry),
					p + Vector2(-rx, 0),
				])
				draw_colored_polygon(pts, color_relleno)
				pts.append(pts[0])
				draw_polyline(pts, color_borde, 1.0, true)


# Ilustración isométrica animada en vivo del terreno actual y la siguiente ampliación.
class PreviewTerrenoMejora:
	extends Control

	const Datos := preload("res://Scripts/Logica/Escena_Principal/Granja/Datos_Granja.gd")
	var nivel_actual: int = 0
	var _t: float = 0.0
	var _tex_arbol: Texture2D
	var _tex_molino: Texture2D
	var _tex_trigo: Texture2D

	func _ready() -> void:
		custom_minimum_size = Vector2(360, 152)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		if ResourceLoader.exists("res://Imagenes/Granja/Arbol_Manzano.png"):
			_tex_arbol = load("res://Imagenes/Granja/Arbol_Manzano.png")
		if ResourceLoader.exists("res://Imagenes/Granja/Molino.png"):
			_tex_molino = load("res://Imagenes/Granja/Molino.png")
		if ResourceLoader.exists("res://Imagenes/Granja/Trigo.png"):
			_tex_trigo = load("res://Imagenes/Granja/Trigo.png")
		set_process(true)

	func configurar(nivel: int) -> void:
		nivel_actual = clampi(nivel, 0, Datos.NIVEL_TERRENO_MAX)
		queue_redraw()

	func _process(delta: float) -> void:
		if not is_visible_in_tree():
			return
		_t += delta
		queue_redraw()

	func _iso(gx: float, gy: float, origen: Vector2, hw: float, hh: float) -> Vector2:
		return origen + Vector2((gx - gy) * hw, (gx + gy) * hh)

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		if w < 20.0 or h < 20.0:
			return

		# Cielo / pradera cálida de fondo dentro del escaparate
		draw_rect(Rect2(Vector2.ZERO, size), Color("#65b832"))
		draw_rect(Rect2(0, 0, w, h * 0.42), Color("#7fd145", 0.55))

		var n: float = float(Datos.GRID_ANCHO)
		var hw: float = minf(w * 0.40 / n, h * 0.80 / n)
		var hh: float = hw * 0.50
		var origen := Vector2(w * 0.5, h * 0.5 - n * hh * 0.5 + 4.0)

		# Borde exterior 24×24 (terreno total futuro)
		var p_all := PackedVector2Array([
			_iso(0, 0, origen, hw, hh), _iso(n, 0, origen, hw, hh),
			_iso(n, n, origen, hw, hh), _iso(0, n, origen, hw, hh),
		])
		draw_colored_polygon(p_all, Color("#4f9624"))
		var p_all_l := p_all.duplicate()
		p_all_l.append(p_all[0])
		draw_polyline(p_all_l, Color("#a3e635", 0.45), 1.6, true)

		# Siguiente ampliación pulsando en dorado brillante!
		if nivel_actual < Datos.NIVEL_TERRENO_MAX:
			var r_sig := Datos.rect_terreno(nivel_actual + 1)
			var pulso: float = 0.72 + 0.24 * sin(_t * 4.0)
			var p_sig := PackedVector2Array([
				_iso(r_sig.position.x, r_sig.position.y, origen, hw, hh),
				_iso(r_sig.end.x, r_sig.position.y, origen, hw, hh),
				_iso(r_sig.end.x, r_sig.end.y, origen, hw, hh),
				_iso(r_sig.position.x, r_sig.end.y, origen, hw, hh),
			])
			draw_colored_polygon(p_sig, Color(0.99, 0.84, 0.24, pulso * 0.85))
			var p_sig_l := p_sig.duplicate()
			p_sig_l.append(p_sig[0])
			draw_polyline(p_sig_l, Color("#fffbeb"), 2.4, true)

		# Terreno actualmente desbloqueado en verde esmeralda vivo
		var r_act := Datos.rect_terreno(nivel_actual)
		var p_act := PackedVector2Array([
			_iso(r_act.position.x, r_act.position.y, origen, hw, hh),
			_iso(r_act.end.x, r_act.position.y, origen, hw, hh),
			_iso(r_act.end.x, r_act.end.y, origen, hw, hh),
			_iso(r_act.position.x, r_act.end.y, origen, hw, hh),
		])
		draw_colored_polygon(p_act, Color("#8ee03b"))
		var p_act_l := p_act.duplicate()
		p_act_l.append(p_act[0])
		draw_polyline(p_act_l, Color("#14532d"), 2.0, true)

		# Pequeñas ilustraciones reales dentro del mapa (molino, trigo y manzanos exteriores!)
		var cen := _iso(float(r_act.position.x + r_act.end.x) * 0.5, float(r_act.position.y + r_act.end.y) * 0.5, origen, hw, hh)
		if _tex_molino != null:
			draw_texture_rect(_tex_molino, Rect2(cen + Vector2(-34, -44), Vector2(42, 42)), false)
		if _tex_trigo != null:
			draw_texture_rect(_tex_trigo, Rect2(cen + Vector2(2, -16), Vector2(26, 26)), false)
			draw_texture_rect(_tex_trigo, Rect2(cen + Vector2(-10, -8), Vector2(24, 24)), false)

		if _tex_arbol != null:
			for pos_a in [_iso(-2.2, 4.0, origen, hw, hh), _iso(26.0, 5.0, origen, hw, hh), _iso(-2.0, 20.0, origen, hw, hh), _iso(25.5, 20.0, origen, hw, hh)]:
				draw_texture_rect(_tex_arbol, Rect2(pos_a + Vector2(-18, -32), Vector2(36, 36)), false)

		# Flechas animadas hacia fuera cuando hay ampliación disponible
		if nivel_actual < Datos.NIVEL_TERRENO_MAX:
			var emp: float = sin(_t * 3.8) * 3.5
			var dirs := [Vector2(-1, -0.5), Vector2(1, -0.5), Vector2(1, 0.5), Vector2(-1, 0.5)]
			for d_raw in dirs:
				var d: Vector2 = (d_raw as Vector2).normalized()
				var p_f := cen + d * (44.0 + emp)
				var perp := Vector2(-d.y, d.x)
				var pts := PackedVector2Array([
					p_f - d * 7.0 - perp * 4.5,
					p_f + d * 7.0,
					p_f - d * 7.0 + perp * 4.5,
				])
				draw_colored_polygon(pts, Color("#fffbeb"))
				draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[0]]), Color("#b45309"), 1.6, true)


# Ilustración animada en vivo de la mejora de velocidad (molino acelerado + ráfagas doradas + cultivos).
class PreviewVelocidadMejora:
	extends Control

	var nivel_actual: int = 0
	var _t: float = 0.0
	var _ang: float = 0.0
	var _tex_torre: Texture2D
	var _tex_aspas: Texture2D
	var _tex_trigo: Texture2D
	var _tex_pan: Texture2D

	func _ready() -> void:
		custom_minimum_size = Vector2(360, 152)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		if ResourceLoader.exists("res://Imagenes/Granja/Molino_Torre.png"):
			_tex_torre = load("res://Imagenes/Granja/Molino_Torre.png")
		if ResourceLoader.exists("res://Imagenes/Granja/Molino_Aspas.png"):
			_tex_aspas = load("res://Imagenes/Granja/Molino_Aspas.png")
		if ResourceLoader.exists("res://Imagenes/Granja/Trigo.png"):
			_tex_trigo = load("res://Imagenes/Granja/Trigo.png")
		if ResourceLoader.exists("res://Imagenes/Granja/Icono_Pan.png"):
			_tex_pan = load("res://Imagenes/Granja/Icono_Pan.png")
		set_process(true)

	func configurar(nivel: int) -> void:
		nivel_actual = clampi(nivel, 0, 3)
		queue_redraw()

	func _process(delta: float) -> void:
		if not is_visible_in_tree():
			return
		_t += delta
		var vel: float = 1.6 + float(nivel_actual) * 1.15
		_ang = fmod(_ang + vel * delta, TAU)
		queue_redraw()

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		if w < 20.0 or h < 20.0:
			return

		# Fondo luminoso morado-dorado estilo taller acelerado
		draw_rect(Rect2(Vector2.ZERO, size), Color("#4c1d95"))
		draw_rect(Rect2(0, 0, w, h * 0.56), Color("#6d28d9", 0.72))
		# Suelo curvo de colina verde al pie
		var colina := PackedVector2Array([
			Vector2(0, h), Vector2(0, h * 0.78),
			Vector2(w * 0.35, h * 0.68), Vector2(w * 0.70, h * 0.72),
			Vector2(w, h * 0.80), Vector2(w, h),
		])
		draw_colored_polygon(colina, Color("#65a30d"))

		# Ráfagas de viento doradas animadas atravesando el cielo
		for i in range(4):
			var c: float = fmod(_t * (0.65 + float(nivel_actual) * 0.25) + float(i) * 0.25, 1.0)
			var x0: float = lerpf(-60.0, w + 40.0, c)
			var y0: float = 24.0 + float(i) * 26.0 + sin(c * 8.0) * 4.0
			var alpha: float = sin(c * PI) * 0.65
			draw_line(Vector2(x0 - 44.0, y0), Vector2(x0 + 18.0, y0), Color(1.0, 0.92, 0.45, alpha), 3.0, true)
			draw_line(Vector2(x0 - 24.0, y0 + 5.0), Vector2(x0 + 8.0, y0 + 5.0), Color(0.86, 0.94, 1.0, alpha * 0.75), 1.8, true)

		# Halo dorado tras el molino
		var cx := w * 0.5
		draw_circle(Vector2(cx, h * 0.48), 58.0, Color(0.98, 0.84, 0.28, 0.22))
		draw_circle(Vector2(cx, h * 0.48), 40.0, Color(1.0, 0.94, 0.56, 0.26))

		# Molino real con aspas girando a toda velocidad!
		var tam: float = 114.0
		var base := Vector2(cx - 10.0, h * 0.88)
		if _tex_torre != null:
			draw_texture_rect(_tex_torre, Rect2(base.x - tam * 0.5, base.y - tam, tam, tam), false)
		if _tex_aspas != null:
			var hub := base + Vector2(tam * (0.65 - 0.5), -tam * (1.0 - 0.265))
			var ta: float = 96.0
			draw_set_transform(hub, _ang, Vector2.ONE)
			draw_texture_rect(_tex_aspas, Rect2(-ta * 0.5, -ta * 0.5, ta, ta), false)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

		# Trigo y pan acompañando a izquierda y derecha
		if _tex_trigo != null:
			var bob1: float = sin(_t * 3.0) * 2.0
			draw_texture_rect(_tex_trigo, Rect2(cx - 118.0, h * 0.46 + bob1, 56, 56), false)
		if _tex_pan != null:
			var bob2: float = sin(_t * 3.0 + 1.4) * 2.5
			draw_texture_rect(_tex_pan, Rect2(cx + 66.0, h * 0.48 + bob2, 52, 52), false)

		# Estrellitas doradas destellando
		for i in range(5):
			var a: float = _t * 1.4 + float(i) * (TAU / 5.0)
			var p := Vector2(cx, h * 0.46) + Vector2(cos(a) * 86.0, sin(a) * 34.0)
			var r: float = 2.6 + 2.0 * absf(sin(_t * 5.0 + float(i)))
			var col := Color(1.0, 0.96, 0.56, 0.9)
			draw_line(p - Vector2(r, 0), p + Vector2(r, 0), col, 1.8, true)
			draw_line(p - Vector2(0, r), p + Vector2(0, r), col, 1.8, true)

