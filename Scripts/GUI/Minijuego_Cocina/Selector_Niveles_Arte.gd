extends RefCounted

# ============================================================================
# Arte cartoon del selector de niveles de la cocina.
#
# Reproduce el lenguaje visual de los mapas de niveles de cocina casual:
# panel de marco celeste con tablero azul embutido, título dorado con contorno
# azul marino, monedas de nivel verdes con marco dorado y tres estrellas, y
# botones inferiores de ATRÁS (oro) y siguiente (verde circular).
#
# Todo se dibuja por código (polígonos redondeados, degradados por vértice y
# texturas del pack) para que escale sin perder nitidez.
# ============================================================================

const FUENTE_CARTOON := preload("res://Fuentes/UI/TitanOne-400.ttf")
const FUENTE_UI := preload("res://Fuentes/UI/DMSans-700.ttf")

const TEX_ESTRELLA := preload("res://Imagenes/Minijuego_Cocina/UI/Estrella_Dorada.png")
const TEX_ESTRELLA_VACIA := preload("res://Imagenes/Minijuego_Cocina/UI/Estrella_Vacia.png")
const TEX_CANDADO := preload("res://Imagenes/UI/Iconos/lock.svg")
const TEX_FONDO := preload("res://Imagenes/Minijuego_Cocina/Fondo_Restaurante_Selector.png")

const ORO_CLARO := Color("#ffe98a")
const ORO := Color("#ffc21a")
const ORO_OSCURO := Color("#e39a05")
const ORO_BORDE := Color("#8a4b00")
const ORO_SOMBRA := Color("#5c3000")

const AZUL_MARCO_CLARO := Color("#9fe9ff")
const AZUL_MARCO := Color("#5ac9f2")
const AZUL_MARCO_MEDIO := Color("#2fa9dd")
const AZUL_MARCO_OSCURO := Color("#166f9f")
const AZUL_MARCO_BORDE := Color("#0b4f78")

const AZUL_TABLERO_CLARO := Color("#2fb0e4")
const AZUL_TABLERO := Color("#1d92c9")
const AZUL_TABLERO_OSCURO := Color("#0e6fa6")
const AZUL_TABLERO_BORDE := Color("#0a4a70")

const VERDE_CLARO := Color("#79e958")
const VERDE := Color("#41c73f")
const VERDE_OSCURO := Color("#1c8b2a")
const VERDE_BORDE := Color("#0b5c18")

const CREMA := Color("#fff7dd")
const NAVY := Color("#10284a")
const NAVY_OSCURO := Color("#081a33")

const ALTO_TITULO_PANEL := 78.0
const ALTO_PIE_PANEL := 88.0
const MARGEN_TABLERO := 18.0


# ============================================================================
# Base de dibujo: utilidades compartidas por todos los controles
# ============================================================================

class Base extends Button:
	func _init() -> void:
		flat = true
		focus_mode = Control.FOCUS_NONE

	static func puntos_redondeados(rect: Rect2, radio: float) -> PackedVector2Array:
		var rad_max: float = maxf(0.0, minf(rect.size.x, rect.size.y) * 0.5 - 0.5)
		var rad: float = clampf(radio, 0.0, rad_max)
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
			for s in range(6):
				var a: float = lerpf(a0, a1, float(s) / 5.0)
				pts.append(cen + Vector2(cos(a), sin(a)) * rad)
		return pts

	static func relleno(c: CanvasItem, rect: Rect2, radio: float, color: Color) -> void:
		if rect.size.x <= 0.5 or rect.size.y <= 0.5 or color.a <= 0.002:
			return
		c.draw_colored_polygon(puntos_redondeados(rect, radio), color)

	static func degradado(c: CanvasItem, rect: Rect2, radio: float,
			arriba: Color, abajo: Color) -> void:
		if rect.size.x <= 0.5 or rect.size.y <= 0.5:
			return
		var pts := puntos_redondeados(rect, radio)
		var cols := PackedColorArray()
		var y0: float = rect.position.y
		var alto: float = maxf(1.0, rect.size.y)
		for p in pts:
			var t: float = clampf((p.y - y0) / alto, 0.0, 1.0)
			cols.append(arriba.lerp(abajo, t))
		c.draw_polygon(pts, cols)

	static func borde(c: CanvasItem, rect: Rect2, radio: float, color: Color,
			grosor: float = 2.0) -> void:
		if rect.size.x <= 1.0 or rect.size.y <= 1.0 or color.a <= 0.002:
			return
		var pts := puntos_redondeados(rect, radio)
		if pts.is_empty():
			return
		pts.append(pts[0])
		c.draw_polyline(pts, color, grosor, true)

	static func sombra(c: CanvasItem, rect: Rect2, radio: float, dy: float,
			color: Color, capas: int = 5) -> void:
		if rect.size.x <= 1.0 or rect.size.y <= 1.0:
			return
		var n: int = maxi(1, capas)
		for i in range(n, 0, -1):
			var t: float = float(i) / float(n)
			var crece: float = t * 4.0
			var r := Rect2(
				rect.position + Vector2(-crece * 0.5, dy + crece * 0.35),
				rect.size + Vector2(crece, crece))
			var col := Color(color.r, color.g, color.b,
				color.a * (1.0 - t * 0.62) / float(n) * 2.2)
			relleno(c, r, radio + crece, col)

	static func gloss(c: CanvasItem, rect: Rect2, radio: float, fraccion: float,
			alpha: float) -> void:
		var alto: float = maxf(5.0, rect.size.y * clampf(fraccion, 0.05, 0.9))
		var r := Rect2(rect.position + Vector2(3.0, 3.0),
			Vector2(maxf(1.0, rect.size.x - 6.0), alto))
		relleno(c, r, maxf(3.0, radio - 3.0), Color(1, 1, 1, alpha))

	static func configurar_label(lbl: Label, tam: int, color: Color,
			outline: Color = Color.TRANSPARENT, grosor: int = 0,
			sombra: bool = false) -> void:
		lbl.add_theme_font_override("font", FUENTE_CARTOON)
		lbl.add_theme_font_size_override("font_size", tam)
		lbl.add_theme_color_override("font_color", color)
		if grosor > 0 and outline.a > 0.0:
			lbl.add_theme_color_override("font_outline_color", outline)
			lbl.add_theme_constant_override("outline_size", grosor)
		if sombra:
			lbl.add_theme_color_override("font_shadow_color", Color(0.02, 0.07, 0.14, 0.45))
			lbl.add_theme_constant_override("shadow_offset_x", 0)
			lbl.add_theme_constant_override("shadow_offset_y", 3)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE

	static func animar_presion(btn: BaseButton, escala: float = 0.96) -> void:
		if btn.has_meta("_selector_anim_presion"):
			return
		btn.set_meta("_selector_anim_presion", true)
		btn.button_down.connect(func():
			if not is_instance_valid(btn):
				return
			btn.pivot_offset = btn.size * 0.5
			var tw := btn.create_tween()
			tw.tween_property(btn, "scale", Vector2(escala, escala), 0.06)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT))
		btn.button_up.connect(func():
			if not is_instance_valid(btn):
				return
			var tw := btn.create_tween()
			tw.tween_property(btn, "scale", Vector2.ONE, 0.12)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT))

	static func flecha_derecha(c: CanvasItem, centro: Vector2, tam: float, color: Color) -> void:
		var ancho: float = tam * 0.62
		var alto: float = tam * 0.62
		var cola: float = tam * 0.24
		var x0: float = centro.x - ancho * 0.55
		var x1: float = centro.x + ancho * 0.55
		var y0: float = centro.y - alto * 0.22
		var y1: float = centro.y + alto * 0.22
		var y2: float = centro.y - alto * 0.5
		var y3: float = centro.y + alto * 0.5
		var pts := PackedVector2Array([
			Vector2(x0, y0), Vector2(x1 - cola, y0), Vector2(x1 - cola, y2),
			Vector2(x1, centro.y), Vector2(x1 - cola, y3), Vector2(x1 - cola, y1),
			Vector2(x0, y1),
		])
		c.draw_colored_polygon(pts, color)


# ============================================================================
# Fondo desenfocado del restaurante con viñeteado azul
# ============================================================================

class Fondo_Mapa extends Base:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(Control.PRESET_FULL_RECT)
		resized.connect(queue_redraw)

	func _draw() -> void:
		if size.x <= 1.0 or size.y <= 1.0:
			return
		# Foto del restaurante desenfocada y estirada a pantalla completa.
		draw_texture_rect(TEX_FONDO, Rect2(Vector2.ZERO, size), false,
			Color(1.0, 1.0, 1.0, 1.0))
		# Oscurecido azul con degradado (arriba más profundo, centro respirable).
		var tinte_arriba := Color(0.03, 0.11, 0.23, 0.66)
		var tinte_abajo := Color(0.02, 0.07, 0.16, 0.80)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.12, 0.24, 0.30))
		# Bandas de viñeteado.
		draw_rect(Rect2(0.0, 0.0, size.x, size.y * 0.24), tinte_arriba)
		draw_rect(Rect2(0.0, size.y * 0.52, size.x, size.y * 0.48), tinte_abajo)
		# Haces de luz suaves para dar profundidad sin competir con el panel.
		var foco := Color(0.55, 0.88, 1.0, 0.045)
		draw_circle(Vector2(size.x * 0.18, size.y * 0.16), size.x * 0.42, foco)
		draw_circle(Vector2(size.x * 0.86, size.y * 0.72), size.x * 0.34, foco)


# ============================================================================
# Marco celeste con tablero azul embutido
# ============================================================================

class Marco_Mapa extends Base:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func rect_tablero() -> Rect2:
		var x: float = MARGEN_TABLERO
		var y: float = ALTO_TITULO_PANEL
		var w: float = maxf(120.0, size.x - MARGEN_TABLERO * 2.0)
		var h: float = maxf(120.0, size.y - y - ALTO_PIE_PANEL)
		return Rect2(x, y, w, h)

	func _draw() -> void:
		if size.x <= 32.0 or size.y <= 64.0:
			return
		var marco := Rect2(Vector2.ZERO, size)
		# Sombra profunda del panel sobre el restaurante.
		Base.sombra(self, marco.grow(-2.0), 30.0, 10.0, Color(0.01, 0.05, 0.12, 0.75), 7)
		# Canto exterior azul oscuro.
		Base.degradado(self, marco, 30.0, AZUL_MARCO_MEDIO, AZUL_MARCO_OSCURO)
		Base.borde(self, marco, 30.0, AZUL_MARCO_BORDE, 4.0)
		# Cara celeste con brillo superior.
		var cara := marco.grow(-5.0)
		Base.degradado(self, cara, 26.0, AZUL_MARCO_CLARO, AZUL_MARCO)
		Base.gloss(self, cara, 25.0, 0.30, 0.16)
		Base.borde(self, cara, 26.0, Color(0.86, 0.97, 1.0, 0.72), 2.0)
		# Placa suave para el título.
		var placa_titulo := Rect2(26.0, 4.0, size.x - 52.0, ALTO_TITULO_PANEL - 10.0)
		Base.relleno(self, placa_titulo, 20.0, Color(1.0, 1.0, 1.0, 0.10))
		Base.borde(self, placa_titulo, 20.0, Color(1.0, 1.0, 1.0, 0.10), 1.5)
		# Tablero hundido.
		var tab := rect_tablero()
		Base.sombra(self, tab, 22.0, 4.0, Color(0.02, 0.10, 0.18, 0.45), 4)
		Base.degradado(self, tab, 22.0, AZUL_TABLERO_CLARO, AZUL_TABLERO_OSCURO)
		Base.borde(self, tab, 22.0, AZUL_TABLERO_BORDE, 5.0)
		# Bisel interior claro y sombra de profundidad arriba.
		var interior := tab.grow(-6.0)
		Base.degradado(self, interior, 17.0, Color("#36b7e8"), Color("#0f77af"))
		Base.borde(self, interior, 17.0, Color(0.55, 0.89, 1.0, 0.34), 2.0)
		var banda_sup := Rect2(interior.position + Vector2(2.0, 2.0),
			Vector2(interior.size.x - 4.0, minf(30.0, interior.size.y * 0.10)))
		Base.relleno(self, banda_sup, 14.0, Color(0.02, 0.18, 0.31, 0.20))
		# Línea de luz en el borde inferior del tablero.
		draw_line(
			Vector2(tab.position.x + 22.0, tab.end.y - 1.5),
			Vector2(tab.end.x - 22.0, tab.end.y - 1.5),
			Color(0.75, 0.96, 1.0, 0.35), 2.0)
		# Separador tenue sobre la franja de botones.
		draw_line(
			Vector2(22.0, size.y - ALTO_PIE_PANEL + 8.0),
			Vector2(size.x - 22.0, size.y - ALTO_PIE_PANEL + 8.0),
			Color(0.05, 0.34, 0.52, 0.30), 2.0)


# ============================================================================
# Título dorado con contorno azul marino y degradado
# ============================================================================

class Titulo_Dorado extends Base:
	static var _shader_cache: Shader

	var _texto: String = ""
	var _tam: int = 40
	var _lbl_borde: Label
	var _lbl_oro: Label

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip_contents = false
		_lbl_borde = Label.new()
		_lbl_borde.set_anchors_preset(Control.PRESET_FULL_RECT)
		_lbl_borde.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_lbl_borde.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_lbl_borde.add_theme_font_override("font", FUENTE_CARTOON)
		_lbl_borde.add_theme_color_override("font_color", NAVY)
		_lbl_borde.add_theme_color_override("font_outline_color", NAVY)
		_lbl_borde.add_theme_constant_override("outline_size", 14)
		_lbl_borde.add_theme_color_override("font_shadow_color", Color(0.02, 0.10, 0.20, 0.55))
		_lbl_borde.add_theme_constant_override("shadow_offset_x", 0)
		_lbl_borde.add_theme_constant_override("shadow_offset_y", 6)
		_lbl_borde.add_theme_constant_override("shadow_outline_size", 14)
		_lbl_borde.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_lbl_borde)

		_lbl_oro = Label.new()
		_lbl_oro.set_anchors_preset(Control.PRESET_FULL_RECT)
		_lbl_oro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_lbl_oro.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_lbl_oro.add_theme_font_override("font", FUENTE_CARTOON)
		_lbl_oro.add_theme_color_override("font_color", Color.WHITE)
		_lbl_oro.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mat := ShaderMaterial.new()
		mat.shader = _obtener_shader()
		_lbl_oro.material = mat
		add_child(_lbl_oro)
		_aplicar()

	func configurar(texto: String, tam: int = 40) -> void:
		_texto = texto
		_tam = tam
		if _lbl_borde != null:
			_aplicar()

	func _aplicar() -> void:
		if _lbl_borde == null or _lbl_oro == null:
			return
		_lbl_borde.text = _texto
		_lbl_oro.text = _texto
		_lbl_borde.add_theme_font_size_override("font_size", _tam)
		_lbl_oro.add_theme_font_size_override("font_size", _tam)
		_lbl_borde.add_theme_constant_override("outline_size", maxi(8, int(_tam * 0.34)))
		_lbl_borde.add_theme_constant_override("shadow_outline_size", maxi(8, int(_tam * 0.34)))

	static func _obtener_shader() -> Shader:
		if _shader_cache == null:
			_shader_cache = Shader.new()
			_shader_cache.code = """
shader_type canvas_item;
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 c1 = vec3(1.0, 0.88, 0.24);
	vec3 c2 = vec3(1.0, 0.68, 0.02);
	vec3 c3 = vec3(0.89, 0.37, 0.01);
	float t = clamp(UV.y, 0.0, 1.0);
	vec3 oro = t < 0.48
		? mix(c1, c2, t / 0.48)
		: mix(c2, c3, (t - 0.48) / 0.52);
	COLOR = vec4(oro, 1.0) * tex;
}
"""
		return _shader_cache


# ============================================================================
# Moneda de nivel: placa verde con marco dorado y tres estrellas
# ============================================================================

class Boton_Nivel extends BaseButton:
	var nivel: int = 1
	var estrellas: int = 0
	var desbloqueado: bool = true

	var _lbl_num: Label
	var _hover: bool = false

	func _ready() -> void:
		focus_mode = Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if desbloqueado \
			else Control.CURSOR_ARROW
		clip_contents = false
		_lbl_num = Label.new()
		_lbl_num.name = "Numero_Nivel"
		_lbl_num.text = str(nivel)
		Base.configurar_label(_lbl_num, 48, Color.WHITE,
			Color("#0b5c18") if desbloqueado else Color("#1b2d3d"), 10, true)
		_lbl_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_lbl_num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(_lbl_num)
		mouse_entered.connect(_on_hover.bind(true))
		mouse_exited.connect(_on_hover.bind(false))
		resized.connect(_actualizar_layout)
		Base.animar_presion(self, 0.96)
		tooltip_text = "Nivel %d" % nivel if desbloqueado \
			else "Supera el nivel %d para desbloquearlo" % maxi(1, nivel - 1)
		_actualizar_layout()

	func _actualizar_layout() -> void:
		pivot_offset = size * 0.5
		if _lbl_num == null:
			return
		if size.x < 24.0 or size.y < 24.0:
			return
		var placa := _rect_placa()
		_lbl_num.position = placa.position
		_lbl_num.size = placa.size
		_lbl_num.add_theme_font_size_override("font_size",
			48 if placa.size.x >= 170.0 else 42)

	func _rect_placa() -> Rect2:
		var ancho: float = minf(maxf(80.0, size.x - 26.0), 190.0)
		var alto: float = clampf(size.y * 0.47, 86.0, 100.0)
		var alto_estrellas: float = 60.0
		var solape: float = 18.0
		var total: float = alto_estrellas + alto - solape
		var y0: float = maxf(0.0, (size.y - total) * 0.5)
		return Rect2((size.x - ancho) * 0.5, y0 + alto_estrellas - solape, ancho, alto)

	func _draw() -> void:
		if size.x < 24.0 or size.y < 24.0:
			return
		var placa := _rect_placa()
		# Halo de selección al pasar el ratón.
		if _hover and desbloqueado:
			Base.sombra(self, placa.grow(4.0), 22.0, 0.0, Color(0.55, 0.91, 1.0, 0.45), 3)
			Base.borde(self, placa.grow(5.0), 23.0, Color(1, 1, 1, 0.62), 3.0)

		_dibujar_estrellas(placa)

		# Sombra de la moneda sobre el tablero.
		Base.sombra(self, placa, 18.0, 7.0, Color(0.01, 0.17, 0.27, 0.55), 4)
		# Marco dorado (o acero para los niveles bloqueados).
		var oro_arr := ORO_CLARO if desbloqueado else Color("#dbe5ee")
		var oro_aba := ORO_OSCURO if desbloqueado else Color("#8598a8")
		var oro_borde := ORO_BORDE if desbloqueado else Color("#374a5b")
		Base.degradado(self, placa, 19.0, oro_arr, oro_aba)
		Base.borde(self, placa, 19.0, oro_borde, 3.0)
		Base.borde(self, placa.grow(-5.0), 15.0, Color(1, 1, 1, 0.35), 2.0)

		# Placa interior.
		var interior := placa.grow(-8.0)
		var verde_arr := VERDE_CLARO if desbloqueado else Color("#5d7b90")
		var verde_aba := VERDE_OSCURO if desbloqueado else Color("#314b5e")
		var verde_borde := VERDE_BORDE if desbloqueado else Color("#1e3242")
		Base.degradado(self, interior, 12.0, verde_arr, verde_aba)
		Base.borde(self, interior, 12.0, verde_borde, 2.5)
		Base.gloss(self, interior, 11.0, 0.44, 0.26 if desbloqueado else 0.14)
		# Brillo elíptico superior izquierdo.
		var brillo := PackedVector2Array()
		var centro_brillo := interior.position + Vector2(interior.size.x * 0.30,
			interior.size.y * 0.20)
		for i in range(20):
			var a: float = TAU * float(i) / 20.0
			brillo.append(centro_brillo + Vector2(cos(a) * interior.size.x * 0.22,
				sin(a) * interior.size.y * 0.09))
		draw_colored_polygon(brillo, Color(1, 1, 1, 0.22 if desbloqueado else 0.10))
		# Línea inferior de luz.
		draw_line(
			interior.position + Vector2(12.0, interior.size.y - 5.0),
			interior.position + Vector2(interior.size.x - 12.0, interior.size.y - 5.0),
			Color(1.0, 1.0, 1.0, 0.18), 2.0)

		if not desbloqueado:
			_dibujar_candado(placa)

	func _dibujar_estrellas(placa: Rect2) -> void:
		var lado: float = clampf(placa.size.x * 0.40, 48.0, 68.0)
		var solape: float = lado * 0.22
		var total: float = lado * 3.0 - solape * 2.0
		var x0: float = (size.x - total) * 0.5
		var y0: float = placa.position.y - lado + 20.0
		for i in range(3):
			var r := Rect2(Vector2(x0 + float(i) * (lado - solape), y0),
				Vector2(lado, lado))
			var tex: Texture2D = TEX_ESTRELLA if i < estrellas else TEX_ESTRELLA_VACIA
			var mod := Color.WHITE
			if not desbloqueado:
				mod = Color(0.51, 0.62, 0.71, 0.92) if i < estrellas \
					else Color(0.44, 0.56, 0.66, 0.82)
			elif i >= estrellas:
				mod = Color(1.0, 0.91, 0.65, 0.95)
			draw_texture_rect(tex, Rect2(r.position + Vector2(1.5, 3.0), r.size),
				false, Color(0.10, 0.05, 0.0, 0.34))
			draw_texture_rect(tex, r, false, mod)

	func _dibujar_candado(placa: Rect2) -> void:
		var centro := placa.position + Vector2(placa.size.x - 17.0, 6.0)
		draw_circle(centro + Vector2(0, 2.5), 16.5, Color(0.02, 0.10, 0.17, 0.40))
		draw_circle(centro, 15.5, Color("#ffe17a"))
		draw_arc(centro, 15.5, 0.0, TAU, 28, ORO_BORDE, 2.5, true)
		draw_texture_rect(TEX_CANDADO,
			Rect2(centro - Vector2(8.5, 8.5), Vector2(17.0, 17.0)),
			false, Color("#693a00"))

	func _on_hover(activo: bool) -> void:
		if not desbloqueado:
			return
		_hover = activo
		queue_redraw()
		if not is_inside_tree():
			return
		var tw := create_tween()
		tw.tween_property(self, "scale",
			Vector2(1.035, 1.035) if activo else Vector2.ONE, 0.10)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


# ============================================================================
# Botón ATRÁS con placa dorada
# ============================================================================

class Boton_Atras extends BaseButton:
	var _lbl: Label

	func _ready() -> void:
		focus_mode = Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		custom_minimum_size = Vector2(160, 56)
		_lbl = Label.new()
		_lbl.text = "ATRÁS"
		Base.configurar_label(_lbl, 24, Color("#fff7cc"), ORO_BORDE, 8, true)
		_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_lbl.position = Vector2(0, -1)
		add_child(_lbl)
		Base.animar_presion(self, 0.96)

	func _draw() -> void:
		if size.x < 8.0 or size.y < 8.0:
			return
		var r := Rect2(Vector2.ZERO, size)
		Base.sombra(self, r, 16.0, 6.0, Color(0.05, 0.03, 0.01, 0.45), 4)
		Base.degradado(self, r, 16.0, Color("#ffd24a"), Color("#e88900"))
		Base.borde(self, r, 16.0, ORO_BORDE, 3.0)
		Base.gloss(self, r, 15.0, 0.44, 0.34)
		Base.borde(self, r.grow(-5.0), 12.0, Color(1, 1, 1, 0.26), 2.0)


# ============================================================================
# Botón circular verde de siguiente nivel
# ============================================================================

class Boton_Siguiente extends BaseButton:
	var _hover: bool = false

	func _ready() -> void:
		focus_mode = Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		custom_minimum_size = Vector2(62, 62)
		mouse_entered.connect(func():
			_hover = true
			queue_redraw())
		mouse_exited.connect(func():
			_hover = false
			queue_redraw())
		Base.animar_presion(self, 0.92)

	func _draw() -> void:
		if size.x < 12.0 or size.y < 12.0:
			return
		var centro := size * 0.5
		var radio: float = minf(size.x, size.y) * 0.5 - 2.0
		# Sombra y anillo exterior.
		draw_circle(centro + Vector2(0, 4), radio + 2.0, Color(0.01, 0.12, 0.04, 0.42))
		draw_circle(centro, radio + 2.0, Color("#f2ffd9"))
		draw_arc(centro, radio + 2.0, 0.0, TAU, 48, Color("#5fae2f"), 2.0, true)
		# Cuerpo verde con degradado.
		draw_circle(centro, radio - 1.0, Color("#53d63c"))
		draw_circle(centro + Vector2(0, 2.0), radio - 4.0, Color("#34b52d"))
		draw_circle(centro - Vector2(0, 2.0), radio - 5.0, Color("#5cdf43"))
		if _hover:
			draw_arc(centro, radio - 0.5, 0.0, TAU, 48, Color(1, 1, 1, 0.55), 3.0, true)
		# Brillo superior.
		var brillo := PackedVector2Array()
		for i in range(24):
			var a: float = TAU * float(i) / 24.0
			brillo.append(centro + Vector2(0, -radio * 0.28) + Vector2(
				cos(a) * radio * 0.55, sin(a) * radio * 0.22))
		draw_colored_polygon(brillo, Color(1, 1, 1, 0.20))
		# Flecha blanca con sombra verde.
		Base.flecha_derecha(self, centro + Vector2(1.5, 3.0), radio * 1.05, Color(0.07, 0.40, 0.10, 0.55))
		Base.flecha_derecha(self, centro + Vector2(0.0, 0.5), radio * 1.05, Color.WHITE)


# ============================================================================
# Barra de desplazamiento vertical del tablero
# ============================================================================

class Barra_Scroll_Niveles extends Base:
	var scroll: ScrollContainer

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		if scroll != null:
			scroll.get_v_scroll_bar().value_changed.connect(_on_scroll.bind())
			scroll.resized.connect(queue_redraw)
		resized.connect(queue_redraw)

	func _on_scroll(_valor: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if size.x < 4.0 or size.y < 20.0:
			return
		# Raíl blanco redondeado, como en la referencia.
		var railon := Rect2(2.0, 4.0, size.x - 4.0, size.y - 8.0)
		Base.sombra(self, railon, railon.size.x * 0.5, 2.0, Color(0.01, 0.12, 0.20, 0.35), 3)
		Base.relleno(self, railon, railon.size.x * 0.5, Color(0.94, 0.99, 1.0, 0.66))
		Base.borde(self, railon, railon.size.x * 0.5, Color(1, 1, 1, 0.75), 1.5)

		if scroll == null:
			return
		var barra: VScrollBar = scroll.get_v_scroll_bar()
		if barra == null:
			return
		var contenido: float = maxf(1.0, barra.max_value - barra.min_value)
		var visible: float = maxf(1.0, barra.page)
		var proporcion: float = clampf(visible / contenido, 0.08, 1.0)
		var alto_thumb: float = maxf(26.0, (railon.size.y - 8.0) * proporcion)
		var t: float = 0.0
		var recorrido: float = maxf(1.0, contenido - visible)
		if recorrido > 0.5:
			t = clampf((barra.value - barra.min_value) / recorrido, 0.0, 1.0)
		var y_thumb: float = railon.position.y + 4.0 \
			+ (railon.size.y - 8.0 - alto_thumb) * t
		var ancho_thumb: float = minf(9.0, railon.size.x - 4.0)
		var thumb := Rect2(
			railon.position.x + (railon.size.x - ancho_thumb) * 0.5,
			y_thumb, ancho_thumb, alto_thumb)
		Base.sombra(self, thumb, thumb.size.x * 0.5, 2.0, Color(0.35, 0.22, 0.02, 0.35), 2)
		Base.degradado(self, thumb, thumb.size.x * 0.5, Color("#fff3b0"), Color("#f0a51c"))
		Base.borde(self, thumb, thumb.size.x * 0.5, Color("#a86200"), 1.5)


# ============================================================================
# Estilos de botones y píldoras del HUD
# ============================================================================

static func estilo_pildora(fondo: Color, borde_col: Color, radio: int = 999,
		alto_borde: int = 2) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = fondo
	st.set_corner_radius_all(radio)
	st.border_color = borde_col
	st.set_border_width_all(alto_borde)
	st.border_width_bottom = maxi(alto_borde, 3)
	st.content_margin_left = 12
	st.content_margin_right = 12
	st.content_margin_top = 5
	st.content_margin_bottom = 6
	st.anti_aliasing = true
	return st


static func estilo_boton_oro(radio: int = 14) -> Array[StyleBoxFlat]:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#ffc21a")
	normal.set_corner_radius_all(radio)
	normal.border_color = ORO_BORDE
	normal.set_border_width_all(2)
	normal.border_width_bottom = 4
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	normal.content_margin_top = 7
	normal.content_margin_bottom = 9
	normal.anti_aliasing = true

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#ffd34d")
	hover.border_color = Color("#9c5900")

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("#eda90a")
	pressed.border_width_bottom = 1
	pressed.content_margin_top = 9
	pressed.content_margin_bottom = 7
	return [normal, hover, pressed]


static func estilo_boton_azul(radio: int = 14) -> Array[StyleBoxFlat]:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#2fa9dd")
	normal.set_corner_radius_all(radio)
	normal.border_color = Color("#0b4f78")
	normal.set_border_width_all(2)
	normal.border_width_bottom = 4
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	normal.content_margin_top = 7
	normal.content_margin_bottom = 9
	normal.anti_aliasing = true

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#43bcec")

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("#1d90c4")
	pressed.border_width_bottom = 1
	pressed.content_margin_top = 9
	pressed.content_margin_bottom = 7
	return [normal, hover, pressed]


static func aplicar_estilos_boton(btn: Button, estilos: Array[StyleBoxFlat]) -> void:
	btn.add_theme_stylebox_override("normal", estilos[0])
	btn.add_theme_stylebox_override("hover", estilos[1])
	btn.add_theme_stylebox_override("pressed", estilos[2])
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_font_override("font", FUENTE_CARTOON)
	btn.add_theme_font_size_override("font_size", 17)
	btn.add_theme_color_override("font_color", Color("#fff8da"))
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color("#fff3c4"))
	btn.add_theme_color_override("font_focus_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.45))
	btn.add_theme_color_override("icon_normal_color", Color("#fff8da"))
	btn.add_theme_color_override("icon_hover_color", Color.WHITE)
	btn.add_theme_color_override("icon_pressed_color", Color("#fff3c4"))
	btn.add_theme_color_override("icon_focus_color", Color.WHITE)
	btn.add_theme_color_override("icon_disabled_color", Color(1, 1, 1, 0.40))
	btn.add_theme_constant_override("icon_max_width", 18)
	btn.add_theme_constant_override("h_separation", 7)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
