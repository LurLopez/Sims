class_name Arte_Modal_Cocina
extends RefCounted

# ============================================================================
# Arte cartoon compartido por los modales del minijuego de cocina.
#
# Reproduce el lenguaje visual de los menús casual de los 2000: panel azul con
# degradado, brillo de cristal y marco grueso; títulos dorados con contorno azul
# marino; placas hundidas para los resúmenes; y botones glossy con icono. Todo
# se dibuja por código salvo los botones, que usan texturas 9-patch derivadas
# del propio pack (tools/generar_botones_modal.py) para que no parezcan UI web.
# ============================================================================

const FUENTE_CARTOON := preload("res://Fuentes/UI/TitanOne-400.ttf")
const FUENTE_UI := preload("res://Fuentes/UI/DMSans-500.ttf")
const FUENTE_UI_MEDIA := preload("res://Fuentes/UI/DMSans-600.ttf")
const FUENTE_UI_FUERTE := preload("res://Fuentes/UI/DMSans-700.ttf")

const TEX_BOTON_AZUL := preload("res://Imagenes/Minijuego_Cocina/UI/Boton_Modal_Azul.png")
const TEX_BOTON_VERDE := preload("res://Imagenes/Minijuego_Cocina/UI/Boton_Modal_Verde.png")
const TEX_BOTON_NARANJA := preload("res://Imagenes/Minijuego_Cocina/UI/Boton_Modal_Naranja.png")
const TEX_BOTON_ROJO := preload("res://Imagenes/Minijuego_Cocina/UI/Boton_Modal_Rojo.png")
const TEX_ESTRELLA := preload("res://Imagenes/Minijuego_Cocina/UI/Estrella_Dorada.png")
const TEX_ESTRELLA_VACIA := preload("res://Imagenes/Minijuego_Cocina/UI/Estrella_Vacia.png")
const TEX_USUARIOS := preload("res://Imagenes/UI/Iconos/users.svg")

const CREMA := Color("#fff7dd")
const CREMA_SUAVE := Color("#d9f3ff")
const ORO_CLARO := Color("#ffe98a")
const ORO := Color("#ffc21a")
const ORO_BORDE := Color("#8a4b00")
const NAVY := Color("#0a2a49")
const NAVY_OSCURO := Color("#061a30")

const ANCHO_REMACHE_BOTON := 64


# ============================================================================
# Utilidades de dibujo (polígonos redondeados, degradados, brillos y sombras)
# ============================================================================

static func puntos_redondeados(rect: Rect2, radio: float) -> PackedVector2Array:
	var rad_max: float = maxf(0.0, minf(rect.size.x, rect.size.y) * 0.5 - 0.5)
	var rad: float = clampf(radio, 0.0, rad_max)
	var puntos := PackedVector2Array()
	var esquinas: Array = [
		[Vector2(rect.end.x - rad, rect.position.y + rad), -PI * 0.5, 0.0],
		[Vector2(rect.end.x - rad, rect.end.y - rad), 0.0, PI * 0.5],
		[Vector2(rect.position.x + rad, rect.end.y - rad), PI * 0.5, PI],
		[Vector2(rect.position.x + rad, rect.position.y + rad), PI, PI * 1.5],
	]
	for esq in esquinas:
		var centro: Vector2 = esq[0]
		var a0: float = esq[1]
		var a1: float = esq[2]
		for paso in range(7):
			var angulo: float = lerpf(a0, a1, float(paso) / 6.0)
			puntos.append(centro + Vector2(cos(angulo), sin(angulo)) * rad)
	return puntos


static func relleno(lienzo: CanvasItem, rect: Rect2, radio: float, color: Color) -> void:
	if rect.size.x <= 0.5 or rect.size.y <= 0.5 or color.a <= 0.002:
		return
	lienzo.draw_colored_polygon(puntos_redondeados(rect, radio), color)


static func degradado(lienzo: CanvasItem, rect: Rect2, radio: float,
		arriba: Color, abajo: Color) -> void:
	if rect.size.x <= 0.5 or rect.size.y <= 0.5:
		return
	var puntos := puntos_redondeados(rect, radio)
	var colores := PackedColorArray()
	var alto: float = maxf(1.0, rect.size.y)
	for punto in puntos:
		var t: float = clampf((punto.y - rect.position.y) / alto, 0.0, 1.0)
		colores.append(arriba.lerp(abajo, t))
	lienzo.draw_polygon(puntos, colores)


static func borde(lienzo: CanvasItem, rect: Rect2, radio: float, color: Color,
		grosor: float = 2.0) -> void:
	if rect.size.x <= 1.0 or rect.size.y <= 1.0 or color.a <= 0.002:
		return
	var puntos := puntos_redondeados(rect, radio)
	if puntos.is_empty():
		return
	puntos.append(puntos[0])
	lienzo.draw_polyline(puntos, color, grosor, true)


static func sombra(lienzo: CanvasItem, rect: Rect2, radio: float, dy: float,
		color: Color, capas: int = 5) -> void:
	if rect.size.x <= 1.0 or rect.size.y <= 1.0:
		return
	var n: int = maxi(1, capas)
	for i in range(n, 0, -1):
		var t: float = float(i) / float(n)
		var crece: float = t * 5.0
		var r := Rect2(
			rect.position + Vector2(-crece * 0.5, dy + crece * 0.35),
			rect.size + Vector2(crece, crece))
		var col := Color(color.r, color.g, color.b,
			color.a * (1.0 - t * 0.62) / float(n) * 2.4)
		relleno(lienzo, r, radio + crece, col)


static func gloss(lienzo: CanvasItem, rect: Rect2, radio: float, fraccion: float,
		alpha: float) -> void:
	var alto: float = maxf(5.0, rect.size.y * clampf(fraccion, 0.05, 0.9))
	var r := Rect2(rect.position + Vector2(3.0, 3.0),
		Vector2(maxf(1.0, rect.size.x - 6.0), alto))
	relleno(lienzo, r, maxf(3.0, radio - 3.0), Color(1, 1, 1, alpha))


static func brillo_elipse(lienzo: CanvasItem, centro: Vector2, radio_x: float,
		radio_y: float, color: Color) -> void:
	var puntos := PackedVector2Array()
	for i in range(24):
		var angulo: float = TAU * float(i) / 24.0
		puntos.append(centro + Vector2(cos(angulo) * radio_x, sin(angulo) * radio_y))
	lienzo.draw_colored_polygon(puntos, color)


static func destello(lienzo: CanvasItem, centro: Vector2, tam: float, color: Color) -> void:
	var principal := PackedVector2Array([
		centro + Vector2(0.0, -tam),
		centro + Vector2(tam * 0.22, 0.0),
		centro + Vector2(0.0, tam),
		centro + Vector2(-tam * 0.22, 0.0),
	])
	var cruzada := PackedVector2Array([
		centro + Vector2(-tam * 0.70, 0.0),
		centro + Vector2(0.0, -tam * 0.16),
		centro + Vector2(tam * 0.70, 0.0),
		centro + Vector2(0.0, tam * 0.16),
	])
	lienzo.draw_colored_polygon(principal, color)
	lienzo.draw_colored_polygon(cruzada, color)


# ============================================================================
# Helpers estáticos de contenido
# ============================================================================

static func texto_modal(contenido: String, tam: int = 14, color: Color = CREMA,
		peso: int = 500) -> Label:
	var fuente: FontFile = FUENTE_UI
	if peso >= 700:
		fuente = FUENTE_UI_FUERTE
	elif peso >= 600:
		fuente = FUENTE_UI_MEDIA
	var lbl := Label.new()
	lbl.text = contenido
	lbl.add_theme_font_override("font", fuente)
	lbl.add_theme_font_size_override("font_size", tam)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_shadow_color", Color(0.02, 0.08, 0.15, 0.38))
	lbl.add_theme_constant_override("shadow_offset_x", 0)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return lbl


static func texto_cartoon(contenido: String, tam: int = 18, color: Color = CREMA,
		contorno: Color = NAVY_OSCURO, grosor: int = 4) -> Label:
	var lbl := Label.new()
	lbl.text = contenido
	lbl.add_theme_font_override("font", FUENTE_CARTOON)
	lbl.add_theme_font_size_override("font_size", tam)
	lbl.add_theme_color_override("font_color", color)
	if grosor > 0:
		lbl.add_theme_color_override("font_outline_color", contorno)
		lbl.add_theme_constant_override("outline_size", grosor)
		lbl.add_theme_constant_override("shadow_offset_x", 0)
		lbl.add_theme_constant_override("shadow_offset_y", 2)
		lbl.add_theme_color_override("font_shadow_color", Color(0.01, 0.06, 0.12, 0.45))
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return lbl


static func crear_titulo(contenido: String, tam: int = 38) -> Control:
	var titulo := Titulo_Modal.new()
	titulo.configurar(contenido, tam)
	return titulo


static func crear_boton(contenido: String, textura: Texture2D,
		icono_nombre: String = "", alto: int = 60, tam: int = 18) -> Button:
	var boton := Boton_Modal.new()
	boton.configurar(contenido, textura, icono_nombre, alto, tam)
	return boton


static func caja_placa(radio: int = 14, alpha: float = 0.30) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.02, 0.11, 0.22, alpha)
	st.set_corner_radius_all(radio)
	st.border_color = Color(0.66, 0.94, 1.0, 0.30)
	st.set_border_width_all(1)
	st.border_width_bottom = 3
	st.content_margin_left = 16
	st.content_margin_right = 16
	st.content_margin_top = 8
	st.content_margin_bottom = 9
	st.anti_aliasing = true
	return st


static func caja_pildora_oro() -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = ORO
	st.set_corner_radius_all(999)
	st.border_color = ORO_BORDE
	st.set_border_width_all(2)
	st.border_width_bottom = 4
	st.content_margin_left = 18
	st.content_margin_right = 18
	st.content_margin_top = 4
	st.content_margin_bottom = 6
	st.anti_aliasing = true
	return st


static func divisor() -> ColorRect:
	var d := ColorRect.new()
	d.color = Color(0.72, 0.95, 1.0, 0.30)
	d.custom_minimum_size = Vector2(0, 2)
	d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return d


static func icono_usuarios(tam: int = 18, color: Color = ORO_CLARO) -> TextureRect:
	var tex := TextureRect.new()
	tex.texture = TEX_USUARIOS
	tex.custom_minimum_size = Vector2(tam, tam)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.self_modulate = color
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tex


static func icono_estrella(tam: int = 30, vacia: bool = false) -> TextureRect:
	var tex := TextureRect.new()
	tex.texture = TEX_ESTRELLA_VACIA if vacia else TEX_ESTRELLA
	tex.custom_minimum_size = Vector2(tam, tam)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tex


# ============================================================================
# Marco azul del modal
# ============================================================================

class Marco_Modal extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		if size.x <= 40.0 or size.y <= 40.0:
			return
		var marco := Rect2(Vector2(0.6, 0.6), size - Vector2(1.2, 1.2))
		# Sombra profunda sobre el fondo de la cocina.
		Arte_Modal_Cocina.sombra(self, marco.grow(-2.0), 28.0, 10.0, Color(0.01, 0.05, 0.12, 0.72), 7)
		# Canto exterior azul oscuro.
		Arte_Modal_Cocina.degradado(self, marco, 30.0, Color("#2fa9dd"), Color("#0b4f78"))
		Arte_Modal_Cocina.borde(self, marco, 30.0, Color("#062f4c"), 4.0)
		# Cara celeste con degradado y brillo superior.
		var cara := marco.grow(-7.0)
		Arte_Modal_Cocina.degradado(self, cara, 24.0, Color("#9de9ff"), Color("#178fc2"))
		Arte_Modal_Cocina.borde(self, cara, 24.0, Color(0.90, 0.99, 1.0, 0.88), 2.0)
		Arte_Modal_Cocina.gloss(self, cara, 22.0, 0.30, 0.16)
		Arte_Modal_Cocina.brillo_elipse(self, cara.position + Vector2(cara.size.x * 0.17, cara.size.y * 0.13),
			cara.size.x * 0.20, cara.size.y * 0.075, Color(1, 1, 1, 0.10))
		# Bisel interior tenue y destellos de esquina.
		Arte_Modal_Cocina.borde(self, cara.grow(-8.0), 18.0, Color(1, 1, 1, 0.15), 1.5)
		Arte_Modal_Cocina.destello(self, Vector2(cara.position.x + 34.0, cara.position.y + 34.0), 9.0,
			Color(1, 1, 1, 0.34))
		Arte_Modal_Cocina.destello(self, Vector2(cara.end.x - 32.0, cara.position.y + 44.0), 6.0,
			Color(1.0, 0.92, 0.52, 0.38))
		Arte_Modal_Cocina.destello(self, Vector2(cara.end.x - 52.0, cara.end.y - 34.0), 5.0,
			Color(1, 1, 1, 0.18))


# ============================================================================
# Título dorado con contorno azul marino y degradado
# ============================================================================

class Titulo_Modal extends Control:
	static var _shader_cache: Shader

	var _texto: String = ""
	var _tam: int = 38
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
		_lbl_borde.add_theme_constant_override("outline_size", 12)
		_lbl_borde.add_theme_color_override("font_shadow_color", Color(0.01, 0.06, 0.12, 0.55))
		_lbl_borde.add_theme_constant_override("shadow_offset_x", 0)
		_lbl_borde.add_theme_constant_override("shadow_offset_y", 4)
		_lbl_borde.add_theme_constant_override("shadow_outline_size", 12)
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

	func configurar(texto: String, tam: int = 38) -> void:
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
		_lbl_borde.add_theme_constant_override("outline_size", maxi(8, int(_tam * 0.36)))
		_lbl_borde.add_theme_constant_override("shadow_outline_size", maxi(8, int(_tam * 0.36)))
		var ancho: float = FUENTE_CARTOON.get_string_size(
			_texto, HORIZONTAL_ALIGNMENT_LEFT, -1, _tam).x
		custom_minimum_size = Vector2(ancho + 44.0, float(_tam) + 20.0)

	static func _obtener_shader() -> Shader:
		if _shader_cache == null:
			_shader_cache = Shader.new()
			_shader_cache.code = """
shader_type canvas_item;
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 c1 = vec3(1.0, 0.92, 0.36);
	vec3 c2 = vec3(1.0, 0.74, 0.04);
	vec3 c3 = vec3(0.91, 0.45, 0.01);
	float t = clamp(UV.y, 0.0, 1.0);
	vec3 oro = t < 0.5
		? mix(c1, c2, t / 0.5)
		: mix(c2, c3, (t - 0.5) / 0.5);
	COLOR = vec4(oro, 1.0) * tex;
}
"""
		return _shader_cache


# ============================================================================
# Botón glossy con textura 9-patch del pack
# ============================================================================

class Boton_Modal extends Button:
	func configurar(contenido: String, textura: Texture2D,
			icono_nombre: String = "", alto: int = 60, tam: int = 18) -> void:
		text = contenido
		custom_minimum_size = Vector2(0, alto)
		focus_mode = Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		expand_icon = false
		add_theme_font_override("font", FUENTE_CARTOON)
		add_theme_font_size_override("font_size", tam)
		add_theme_color_override("font_color", CREMA)
		add_theme_color_override("font_hover_color", Color.WHITE)
		add_theme_color_override("font_pressed_color", Color.WHITE)
		add_theme_color_override("font_focus_color", Color.WHITE)
		add_theme_color_override("font_disabled_color", Color(CREMA, 0.52))
		add_theme_color_override("font_outline_color", NAVY_OSCURO)
		add_theme_constant_override("outline_size", maxi(3, int(tam * 0.26)))
		add_theme_color_override("font_shadow_color", Color(0.01, 0.06, 0.12, 0.45))
		add_theme_constant_override("shadow_offset_x", 0)
		add_theme_constant_override("shadow_offset_y", 2)
		add_theme_constant_override("shadow_outline_size", maxi(3, int(tam * 0.26)))
		add_theme_constant_override("icon_max_width", maxi(18, int(tam * 1.25)))
		add_theme_constant_override("h_separation", 10)

		add_theme_stylebox_override("normal", _estilo_textura(textura, 0))
		add_theme_stylebox_override("hover", _estilo_textura(textura, 1))
		add_theme_stylebox_override("pressed", _estilo_textura(textura, 2))
		add_theme_stylebox_override("disabled", _estilo_textura(textura, 3))
		add_theme_stylebox_override("focus", StyleBoxEmpty.new())

		if icono_nombre != "":
			icon = Estilos_UI.icono(icono_nombre)
			add_theme_color_override("icon_normal_color", ORO_CLARO)
			add_theme_color_override("icon_hover_color", Color("#fff3b0"))
			add_theme_color_override("icon_pressed_color", Color("#fff3b0"))
			add_theme_color_override("icon_focus_color", ORO_CLARO)
			add_theme_color_override("icon_disabled_color", Color(CREMA, 0.42))

	func bloquear(si: bool) -> void:
		disabled = si
		modulate = Color(1, 1, 1, 0.62) if si else Color.WHITE

	func _estilo_textura(textura: Texture2D, estado: int) -> StyleBoxTexture:
		var st := StyleBoxTexture.new()
		st.texture = textura
		st.texture_margin_left = float(ANCHO_REMACHE_BOTON)
		st.texture_margin_right = float(ANCHO_REMACHE_BOTON)
		st.texture_margin_top = 0.0
		st.texture_margin_bottom = 0.0
		st.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
		st.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
		st.content_margin_left = 26
		st.content_margin_right = 26
		st.content_margin_top = 7
		st.content_margin_bottom = 9
		match estado:
			1:
				st.modulate_color = Color(1.12, 1.12, 1.12)
			2:
				st.modulate_color = Color(0.86, 0.90, 0.96)
				st.content_margin_top = 10
				st.content_margin_bottom = 6
			3:
				st.modulate_color = Color(0.64, 0.70, 0.76, 0.88)
		return st
