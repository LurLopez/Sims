class_name Estilos_UI
extends RefCounted

# Sistema de diseño unificado para Sims Life (720x1280).

const FONDO := Color("#efeff4")
const FONDO_2 := Color("#e4e7ee")
const SUPERFICIE := Color("#ffffff")
const SUPERFICIE_2 := Color("#f7f8fa")
const TINTA := Color("#111827")
const TINTA_SUAVE := Color("#475569")
const TINTA_FANTASMA := Color("#7c8798")

const ROJO_BIT := Color("#d62828")
const ROJO_BIT_OSCURO := Color("#a81c1c")
const ROJO_BIT_SUAVE := Color("#fee2e2")

const PRIMARIO := Color("#d62828")
const PRIMARIO_OSCURO := Color("#a81c1c")
const PRIMARIO_SUAVE := Color("#fee2e2")

const CORAL := Color("#e11d48")
const CORAL_SUAVE := Color("#ffe4e6")
const ORO := Color("#d97706")
const ORO_SUAVE := Color("#fef3c7")
const EXITO := Color("#1ea34a")
const EXITO_OSCURO := Color("#157936")
const EXITO_SUAVE := Color("#dcfce7")
const AVISO := Color("#f59e0b")
const AVISO_SUAVE := Color("#fef3c7")
const PELIGRO := Color("#dc2626")
const PELIGRO_SUAVE := Color("#fee2e2")

const BORDE := Color("#d5dce6")
const BORDE_FUERTE := Color("#b6c1d1")
const AZUL := Color("#1d7afc")
const AZUL_CLARO := Color("#0ea5e9")
const AZUL_SUAVE := Color("#e0f2fe")
const INDIGO := Color("#4f46e5")
const INDIGO_SUAVE := Color("#eef2ff")
const MORADO := Color("#7c3aed")
const MORADO_SUAVE := Color("#ede9fe")
const CIAN := Color("#0891b2")
const CIAN_SUAVE := Color("#ecfeff")
const NAVY := Color("#182234")
const NAVY_OSCURO := Color("#111927")
const GRIS_BARRA := Color("#dde3ec")

const FUENTE_400 := preload("res://Fuentes/UI/DMSans-400.ttf")
const FUENTE_500 := preload("res://Fuentes/UI/DMSans-500.ttf")
const FUENTE_600 := preload("res://Fuentes/UI/DMSans-600.ttf")
const FUENTE_700 := preload("res://Fuentes/UI/DMSans-700.ttf")
const TITULO_500 := preload("res://Fuentes/UI/Bricolage-700.ttf")
const TITULO_600 := preload("res://Fuentes/UI/Bricolage-700.ttf")
const TITULO_700 := preload("res://Fuentes/UI/Bricolage-800.ttf")
const LOGO_400 := preload("res://Fuentes/UI/Bricolage-800.ttf")
const EDITORIAL_600 := preload("res://Fuentes/UI/Fraunces-600.ttf")
const EDITORIAL_700 := preload("res://Fuentes/UI/Fraunces-700.ttf")

const RUTA_AVATAR_PROTA := "res://Imagenes/UI/avatar_prota.png"
static var _cache_avatar: Texture2D = null

const RADIO_TARJETA := 16
const RADIO_BOTON := 12
const RADIO_CHIP := 10
const MARGEN := 20


static func fuente_ui(peso: int = 400) -> FontFile:
	match peso:
		500: return FUENTE_500
		600: return FUENTE_600
		700, 800: return FUENTE_700
		_: return FUENTE_400


static func fuente_titulo(peso: int = 600) -> FontFile:
	return TITULO_700 if peso >= 700 else TITULO_600


static func fuente_logo() -> FontFile:
	return LOGO_400


static func fuente_editorial(peso: int = 600) -> FontFile:
	return EDITORIAL_700 if peso >= 700 else EDITORIAL_600


static func texto(contenido: String, tam: int = 15, color: Color = TINTA, peso: int = 400) -> Label:
	var lbl := Label.new()
	lbl.set_meta("_tema_aplicado", true)
	lbl.text = contenido
	lbl.add_theme_font_override("font", fuente_ui(peso))
	lbl.add_theme_font_size_override("font_size", tam)
	lbl.add_theme_color_override("font_color", color)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return lbl


static func titulo(contenido: String, tam: int = 24, color: Color = TINTA) -> Label:
	var lbl := Label.new()
	lbl.set_meta("_tema_aplicado", true)
	lbl.text = contenido
	lbl.add_theme_font_override("font", fuente_titulo(600))
	lbl.add_theme_font_size_override("font_size", tam)
	lbl.add_theme_color_override("font_color", color)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return lbl


static func parrafo(contenido: String, tam: int = 14, color: Color = TINTA_SUAVE) -> Label:
	var lbl := texto(contenido, tam, color, 400)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return lbl


static func icono(nombre: String) -> Texture2D:
	var ruta := "res://Imagenes/UI/Iconos/%s.svg" % nombre
	if ResourceLoader.exists(ruta):
		return load(ruta)
	return null


# Ilustraciones propias de los muebles de la tienda (PNG con alfa generados
# con tools/procesar_iconos_tienda.py). Se cachean porque las tarjetas se
# reconstruyen cada vez que se abre la tienda.
const RUTAS_ICONOS_TIENDA := {
	"Cama_Basica": "res://Imagenes/Tienda/Iconos/Cama_Basica.png",
	"Cama_Premium": "res://Imagenes/Tienda/Iconos/Cama_Premium.png",
	"Cama_Lujo": "res://Imagenes/Tienda/Iconos/Cama_Lujo.png",
	"Mesa_Basica": "res://Imagenes/Tienda/Iconos/Mesa_Basica.png",
	"Ducha_Basica": "res://Imagenes/Tienda/Iconos/Ducha_Basica.png",
	"Ducha_Premium": "res://Imagenes/Tienda/Iconos/Ducha_Premium.png",
}
static var _cache_iconos_tienda: Dictionary = {}


static func icono_tienda(clave: String) -> Texture2D:
	if _cache_iconos_tienda.has(clave):
		return _cache_iconos_tienda[clave]
	var ruta := str(RUTAS_ICONOS_TIENDA.get(clave, ""))
	var textura: Texture2D = null
	if ruta != "" and ResourceLoader.exists(ruta):
		textura = load(ruta) as Texture2D
	_cache_iconos_tienda[clave] = textura
	return textura


static func icono_rect(nombre: String, tam: int = 22, color: Color = TINTA) -> TextureRect:
	var tex := TextureRect.new()
	tex.texture = icono(nombre)
	tex.custom_minimum_size = Vector2(tam, tam)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.self_modulate = color
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tex


static func color_valor(valor: float) -> Color:
	if valor >= 50.0:
		return EXITO
	elif valor >= 25.0:
		return AVISO
	return PELIGRO


static func caja(color: Color = SUPERFICIE, radio: int = RADIO_TARJETA,
		borde: Color = BORDE, ancho_borde: int = 1, sombra: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radio)
	if ancho_borde > 0:
		s.set_border_width_all(ancho_borde)
		s.border_color = borde
	if sombra > 0:
		s.shadow_color = Color(0.06, 0.09, 0.16, 0.07)
		s.shadow_size = mini(sombra * 2, 8)
		s.shadow_offset = Vector2(0, 2)
	s.anti_aliasing = true
	return s


static func caja_tarjeta(radio: int = RADIO_TARJETA, borde_inf: int = 2) -> StyleBoxFlat:
	var s := caja(SUPERFICIE, radio, BORDE, 1, 2)
	s.border_width_bottom = maxi(1, borde_inf)
	return s


static func barra_fondo(radio: int = 999) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = GRIS_BARRA
	s.set_corner_radius_all(radio)
	s.border_width_top = 1
	s.border_color = Color("#c8d1de")
	s.anti_aliasing = true
	return s


static func barra_relleno(color: Color, radio: int = 999) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radio)
	s.border_width_bottom = 2
	s.border_color = color.darkened(0.24)
	s.anti_aliasing = true
	return s


static func animar_barra(barra: ProgressBar, valor: float, color: Color) -> void:
	if barra == null or not is_instance_valid(barra):
		return
	barra.add_theme_stylebox_override("fill", barra_relleno(color))
	var objetivo := clampf(valor, barra.min_value, barra.max_value)
	if not barra.is_inside_tree() or absf(barra.value - objetivo) < 0.5:
		barra.value = objetivo
		return
	var tw := barra.create_tween()
	tw.tween_property(barra, "value", objetivo, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


static func etiqueta_bienestar(media: float) -> Array:
	if media >= 75.0:
		return ["Genial", EXITO_SUAVE, EXITO]
	elif media >= 50.0:
		return ["Bien", AZUL_SUAVE, AZUL]
	elif media >= 30.0:
		return ["Cansado", AVISO_SUAVE, ORO]
	return ["¡Crítico!", PELIGRO_SUAVE, PELIGRO]


static func textura_avatar() -> Texture2D:
	if _cache_avatar != null:
		return _cache_avatar
	if ResourceLoader.exists(RUTA_AVATAR_PROTA):
		var res := load(RUTA_AVATAR_PROTA)
		if res is Texture2D:
			_cache_avatar = res
			return _cache_avatar
	var img := Image.load_from_file(ProjectSettings.globalize_path(RUTA_AVATAR_PROTA))
	if img != null and not img.is_empty():
		_cache_avatar = ImageTexture.create_from_image(img)
		return _cache_avatar
	return null


static func _obtener_apariencia_actual(datos: Dictionary) -> Dictionary:
	if not datos.is_empty():
		return Apariencia_Personaje.normalizar(datos)
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		var ve: Node = tree.root.get_node_or_null("Variables_Estaticas")
		if ve != null:
			var ap = ve.get("Apariencia")
			if ap is Dictionary and not ap.is_empty():
				var ap_norm := Apariencia_Personaje.normalizar(ap)
				var cocina: Node = tree.root.get_node_or_null("Sistema_Cocina")
				if cocina != null and cocina.has_method("Obtener_Apariencia_Con_Ropa_Equipada"):
					return cocina.call("Obtener_Apariencia_Con_Ropa_Equipada", ap_norm)
				return ap_norm
	return Apariencia_Personaje.por_defecto()


static func avatar_personaje(tam: int = 44, color_borde: Color = Color.WHITE, grosor_borde: int = 2,
		datos_apariencia: Dictionary = {}, animar: bool = false) -> PanelContainer:
	var p := PanelContainer.new()
	p.set_meta("_tema_aplicado", true)
	p.custom_minimum_size = Vector2(tam, tam)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := caja(Color("#bae6fd"), 999, color_borde, grosor_borde, 2)
	st.content_margin_left = grosor_borde
	st.content_margin_right = grosor_borde
	st.content_margin_top = grosor_borde
	st.content_margin_bottom = grosor_borde
	p.add_theme_stylebox_override("panel", st)

	var mascara := Panel.new()
	mascara.name = "MascaraCircular"
	mascara.set_meta("_tema_aplicado", true)
	mascara.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	mascara.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mascara.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mascara.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var st_clip := StyleBoxFlat.new()
	st_clip.bg_color = Color("#bae6fd")
	st_clip.set_corner_radius_all(999)
	st_clip.anti_aliasing = true
	mascara.add_theme_stylebox_override("panel", st_clip)
	p.add_child(mascara)

	var ap := _obtener_apariencia_actual(datos_apariencia)
	var retrato := Personaje_Visual.new(ap, "retrato")
	retrato.name = "Retrato"
	retrato.set_anchors_preset(Control.PRESET_FULL_RECT)
	retrato.expresion = "feliz"
	retrato.animar_idle = animar
	retrato.dibujar_fondo_sunburst = true
	mascara.add_child(retrato)
	return p


static func pill_estado(texto_pill: String, color_fondo: Color, color_texto: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.set_meta("_tema_aplicado", true)
	var st := caja(color_fondo, 999, Color(color_texto, 0.16), 1, 0)
	st.content_margin_left = 10
	st.content_margin_right = 10
	st.content_margin_top = 4
	st.content_margin_bottom = 4
	p.add_theme_stylebox_override("panel", st)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lbl := texto(texto_pill, 11, color_texto, 700)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(lbl)
	return p


static func badge_icono(nombre_icono: String, tam_caja: int = 38, tam_icono: int = 19,
		fondo: Color = ROJO_BIT, color_ic: Color = Color.WHITE, radio: int = 10) -> PanelContainer:
	var p := PanelContainer.new()
	p.set_meta("_tema_aplicado", true)
	p.custom_minimum_size = Vector2(tam_caja, tam_caja)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := caja(fondo, radio, fondo.darkened(0.24), 0, 0)
	st.border_width_bottom = 2 if fondo.a > 0.5 else 0
	st.content_margin_left = 0
	st.content_margin_right = 0
	st.content_margin_top = 0
	st.content_margin_bottom = 0
	p.add_theme_stylebox_override("panel", st)
	var c := CenterContainer.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ic := icono_rect(nombre_icono, tam_icono, color_ic)
	c.add_child(ic)
	p.add_child(c)
	return p


static func _caja_relleno(color: Color, radio: int, borde_inf: int = 4, margen_top: int = 11) -> StyleBoxFlat:
	var s := caja(color, radio, color.darkened(0.26), 0, 0)
	s.border_width_bottom = borde_inf
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = margen_top
	s.content_margin_bottom = maxi(8, 15 - margen_top)
	return s


static func aplicar_estilo_boton(btn: Button, variante: String = "secundario",
		color: Color = PRIMARIO, icono_nombre: String = "") -> void:
	btn.set_meta("_tema_aplicado", true)
	btn.set_meta("_estilo_propio", true)
	btn.add_theme_font_override("font", fuente_ui(600))
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_constant_override("icon_max_width", 20)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var normal: StyleBoxFlat
	var hover: StyleBoxFlat
	var pressed: StyleBoxFlat
	var texto_color := TINTA

	match variante:
		"primario", "exito", "peligro", "oro":
			var base := color
			if variante == "exito": base = EXITO
			elif variante == "peligro": base = PELIGRO
			elif variante == "oro": base = ORO
			normal = _caja_relleno(base, RADIO_BOTON, 4, 11)
			hover = _caja_relleno(base.lightened(0.05), RADIO_BOTON, 4, 11)
			pressed = _caja_relleno(base.darkened(0.10), RADIO_BOTON, 1, 13)
			texto_color = Color.WHITE
		"suave":
			normal = _caja_relleno(Color(color, 0.11), RADIO_BOTON, 2, 11)
			normal.border_color = Color(color, 0.25)
			hover = _caja_relleno(Color(color, 0.17), RADIO_BOTON, 2, 11)
			hover.border_color = Color(color, 0.32)
			pressed = _caja_relleno(Color(color, 0.24), RADIO_BOTON, 1, 12)
			pressed.border_color = Color(color, 0.40)
			texto_color = color
		"tarjeta":
			normal = caja_tarjeta(RADIO_TARJETA, 3)
			normal.content_margin_left = 16
			normal.content_margin_right = 16
			normal.content_margin_top = 12
			normal.content_margin_bottom = 12
			hover = normal.duplicate() as StyleBoxFlat
			hover.bg_color = Color("#fafbfd")
			hover.border_color = BORDE_FUERTE
			pressed = normal.duplicate() as StyleBoxFlat
			pressed.bg_color = ROJO_BIT_SUAVE
			pressed.border_color = ROJO_BIT
			pressed.border_width_bottom = 1
			texto_color = TINTA
		"nav":
			normal = caja(Color(0, 0, 0, 0), 12, Color(0, 0, 0, 0), 0, 0)
			normal.content_margin_top = 4
			normal.content_margin_bottom = 4
			hover = caja(Color("#28344a"), 12, Color(0, 0, 0, 0), 0, 0)
			pressed = caja(ROJO_BIT, 12, ROJO_BIT_OSCURO, 0, 0)
			texto_color = Color("#cbd5e1")
		"top":
			normal = caja(Color(0, 0, 0, 0), 8, Color(0, 0, 0, 0), 0, 0)
			normal.content_margin_left = 8
			normal.content_margin_right = 8
			normal.content_margin_top = 6
			normal.content_margin_bottom = 6
			hover = caja(SUPERFICIE_2, 8, Color(0, 0, 0, 0), 0, 0)
			pressed = caja(PRIMARIO_SUAVE, 8, Color(0, 0, 0, 0), 0, 0)
			texto_color = TINTA_SUAVE
		"chip":
			normal = caja(SUPERFICIE, RADIO_CHIP, BORDE, 1, 0)
			normal.content_margin_left = 14
			normal.content_margin_right = 14
			normal.content_margin_top = 8
			normal.content_margin_bottom = 8
			hover = normal.duplicate() as StyleBoxFlat
			hover.bg_color = SUPERFICIE_2
			pressed = normal.duplicate() as StyleBoxFlat
			pressed.bg_color = PRIMARIO_SUAVE
			pressed.border_color = PRIMARIO
			texto_color = TINTA
		"accion":
			normal = _caja_relleno(color, 10)
			normal.content_margin_left = 14
			normal.content_margin_right = 14
			normal.content_margin_top = 8
			normal.content_margin_bottom = 8
			hover = _caja_relleno(color.darkened(0.06), 10)
			pressed = _caja_relleno(color.darkened(0.14), 10)
			texto_color = Color.WHITE
		"fantasma":
			normal = caja(Color(0, 0, 0, 0), 10, Color(0, 0, 0, 0), 0, 0)
			normal.content_margin_left = 10
			normal.content_margin_right = 10
			normal.content_margin_top = 8
			normal.content_margin_bottom = 8
			hover = caja(SUPERFICIE_2, 10, Color(0, 0, 0, 0), 0, 0)
			pressed = caja(PRIMARIO_SUAVE, 10, Color(0, 0, 0, 0), 0, 0)
			texto_color = TINTA_SUAVE
		_:
			normal = caja(SUPERFICIE, RADIO_BOTON, BORDE_FUERTE, 1, 0)
			normal.border_width_bottom = 2
			normal.content_margin_left = 16
			normal.content_margin_right = 16
			normal.content_margin_top = 10
			normal.content_margin_bottom = 11
			hover = normal.duplicate() as StyleBoxFlat
			hover.bg_color = SUPERFICIE_2
			hover.border_color = BORDE_FUERTE
			pressed = normal.duplicate() as StyleBoxFlat
			pressed.bg_color = PRIMARIO_SUAVE
			pressed.border_color = PRIMARIO
			texto_color = TINTA

	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(normal.bg_color, maxf(0.45, normal.bg_color.a * 0.6))

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_color_override("font_color", texto_color)
	btn.add_theme_color_override("font_hover_color", texto_color)
	btn.add_theme_color_override("font_pressed_color", texto_color)
	btn.add_theme_color_override("font_focus_color", texto_color)
	btn.add_theme_color_override("font_disabled_color", Color(texto_color, 0.45))
	btn.add_theme_color_override("icon_normal_color", texto_color)
	btn.add_theme_color_override("icon_hover_color", texto_color)
	btn.add_theme_color_override("icon_pressed_color", texto_color)
	btn.add_theme_color_override("icon_focus_color", texto_color)
	btn.add_theme_color_override("icon_disabled_color", Color(texto_color, 0.45))

	if icono_nombre != "":
		btn.icon = icono(icono_nombre)
		btn.expand_icon = false
		btn.add_theme_constant_override("h_separation", 10)

	animar_presion(btn)


static func boton(contenido: String, variante: String = "secundario",
		icono_nombre: String = "", color: Color = PRIMARIO, alto: int = 50) -> Button:
	var btn := Button.new()
	btn.text = contenido
	btn.custom_minimum_size = Vector2(0, alto)
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	aplicar_estilo_boton(btn, variante, color, icono_nombre)
	return btn


static func boton_icono(nombre_icono: String, color: Color = TINTA, tam: int = 40) -> Button:
	var btn := Button.new()
	btn.set_meta("_tema_aplicado", true)
	btn.set_meta("_estilo_propio", true)
	btn.custom_minimum_size = Vector2(tam, tam)
	btn.text = ""
	btn.flat = false
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var st_n := caja(SUPERFICIE, 11, BORDE, 1, 1)
	st_n.border_width_bottom = 2
	var st_h := caja(SUPERFICIE_2, 11, BORDE_FUERTE, 1, 1)
	st_h.border_width_bottom = 2
	var st_p := caja(PRIMARIO_SUAVE, 11, PRIMARIO, 1, 0)
	btn.add_theme_stylebox_override("normal", st_n)
	btn.add_theme_stylebox_override("hover", st_h)
	btn.add_theme_stylebox_override("pressed", st_p)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_color_override("icon_normal_color", color)
	btn.add_theme_color_override("icon_hover_color", color)
	btn.add_theme_color_override("icon_pressed_color", PRIMARIO)
	btn.add_theme_color_override("icon_focus_color", color)
	btn.icon = icono(nombre_icono)
	btn.expand_icon = false
	btn.add_theme_constant_override("icon_max_width", 20)
	animar_presion(btn)
	return btn


static func Crear_Tarjeta_Boton(texto_boton: String, color_acento: Color) -> Button:
	var btn := boton(texto_boton, "tarjeta", "", color_acento, 70)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	return btn


static func Aplicar_Estilo_Tarjeta(btn: Button, color_acento: Color) -> void:
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(0, 70)
	aplicar_estilo_boton(btn, "tarjeta", color_acento)


static func Crear_Boton_Volver_Panel(parent: Control, callback: Callable) -> void:
	var btn := boton_icono("arrow-left", TINTA, 42)
	btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	btn.offset_left = 20
	btn.offset_top = 128
	btn.offset_right = 62
	btn.offset_bottom = 170
	btn.tooltip_text = "Volver"
	btn.pressed.connect(callback)
	parent.add_child(btn)


static func Crear_Label_Titulo_Panel(texto_titulo: String, parent: Control, color: Color, con_volver: bool = true) -> void:
	var lbl := titulo(texto_titulo, 24, color)
	lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
	lbl.offset_left = 74 if con_volver else 20
	lbl.offset_right = -20
	lbl.offset_top = 128
	lbl.offset_bottom = 170
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	parent.add_child(lbl)


static func separador(alto: int = 12) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, alto)
	return c


static func divisor_horizontal() -> ColorRect:
	var d := ColorRect.new()
	d.color = BORDE
	d.custom_minimum_size = Vector2(0, 1)
	d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return d


static func encabezado_seccion(contenido: String, accion: String = "") -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var lbl := titulo(contenido, 17, TINTA)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(lbl)
	if accion != "":
		var a := Button.new()
		a.name = "Accion"
		a.text = accion
		a.flat = true
		a.add_theme_font_override("font", fuente_ui(600))
		a.add_theme_font_size_override("font_size", 13)
		a.add_theme_color_override("font_color", PRIMARIO)
		a.add_theme_color_override("font_hover_color", PRIMARIO_OSCURO)
		a.add_theme_color_override("font_pressed_color", PRIMARIO_OSCURO)
		for estado in ["normal", "hover", "pressed", "focus"]:
			a.add_theme_stylebox_override(estado, StyleBoxEmpty.new())
		a.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		h.add_child(a)
	return h


static func estilizar_ventana(win: Window) -> void:
	win.add_theme_font_override("title_font", fuente_titulo())
	win.add_theme_font_size_override("title_font_size", 17)
	win.add_theme_color_override("title_color", TINTA)
	win.add_theme_stylebox_override("panel", caja(SUPERFICIE, 16, BORDE, 1, 3))
	win.add_theme_stylebox_override("embedded_border", caja(SUPERFICIE, 16, BORDE_FUERTE, 1, 4))
	for panel in win.find_children("*", "Panel", true, false):
		panel.add_theme_stylebox_override("panel", caja(SUPERFICIE, 16, BORDE, 1, 0))
	for lbl in win.find_children("*", "Label", true, false):
		lbl.add_theme_font_override("font", fuente_ui(400))
		if not lbl.has_theme_color_override("font_color"):
			lbl.add_theme_color_override("font_color", TINTA)
	for le in win.find_children("*", "LineEdit", true, false):
		le.add_theme_font_override("font", fuente_ui(600))
		le.add_theme_color_override("font_color", TINTA)
		le.add_theme_color_override("font_placeholder_color", TINTA_FANTASMA)
		le.add_theme_stylebox_override("normal", caja(SUPERFICIE_2, 10, BORDE_FUERTE, 1, 0))
		le.add_theme_stylebox_override("focus", caja(SUPERFICIE, 10, PRIMARIO, 2, 0))
	for b in win.find_children("*", "Button", true, false):
		if not b.has_meta("_estilo_propio"):
			aplicar_estilo_boton(b, "secundario")


static func estilizar_dialogo(dlg: AcceptDialog) -> void:
	dlg.add_theme_font_override("title_font", fuente_titulo())
	dlg.add_theme_font_size_override("title_font_size", 17)
	dlg.add_theme_color_override("title_color", TINTA)
	dlg.add_theme_stylebox_override("panel", caja(SUPERFICIE, 16, BORDE, 1, 3))
	dlg.add_theme_stylebox_override("embedded_border", caja(SUPERFICIE, 16, BORDE_FUERTE, 1, 4))
	dlg.add_theme_color_override("font_color", TINTA)
	for lbl in dlg.find_children("*", "Label", true, false):
		lbl.add_theme_font_override("font", fuente_ui(400))
		if not lbl.has_theme_color_override("font_color"):
			lbl.add_theme_color_override("font_color", TINTA)
	for cb in dlg.find_children("*", "CheckBox", true, false):
		cb.add_theme_font_override("font", fuente_ui(400))
		cb.add_theme_color_override("font_color", TINTA)
		cb.add_theme_color_override("font_hover_color", TINTA)
		cb.add_theme_color_override("font_pressed_color", PRIMARIO)
		cb.add_theme_color_override("font_hover_pressed_color", PRIMARIO)
		cb.add_theme_color_override("font_focus_color", TINTA)
	for le in dlg.find_children("*", "LineEdit", true, false):
		le.add_theme_font_override("font", fuente_ui(600))
		le.add_theme_color_override("font_color", TINTA)
		le.add_theme_color_override("font_placeholder_color", TINTA_FANTASMA)
		le.add_theme_stylebox_override("normal", caja(SUPERFICIE_2, 10, BORDE_FUERTE, 1, 0))
		le.add_theme_stylebox_override("focus", caja(SUPERFICIE, 10, PRIMARIO, 2, 0))
	for b in dlg.find_children("*", "Button", true, false):
		if not b.has_meta("_estilo_propio"):
			aplicar_estilo_boton(b, "secundario")
	if dlg.get_ok_button() != null and dlg.get_ok_button().visible:
		aplicar_estilo_boton(dlg.get_ok_button(), "primario")
		dlg.get_ok_button().custom_minimum_size = Vector2(128, 44)
	if dlg is ConfirmationDialog:
		var cancel := (dlg as ConfirmationDialog).get_cancel_button()
		if cancel != null and cancel.visible:
			aplicar_estilo_boton(cancel, "secundario")
			cancel.custom_minimum_size = Vector2(112, 44)


# Los AcceptDialog con Labels en autowrap calculan una altura mínima enorme antes
# de tener ancho asignado (el texto entero en una línea), así que el diálogo se
# abre gigante y sus botones quedan fuera de la pantalla. Llamar en diferido
# justo después de abrir el diálogo para fijar un tamaño válido y centrarlo.
static func fijar_tamano_dialogo(dlg, tam: Vector2i) -> void:
	# Sin tipo estricto: si el diálogo se cerró antes del call_deferred, llega
	# una referencia liberada y la conversión tipada lanzaría un error.
	if dlg == null or not is_instance_valid(dlg):
		return
	var dialogo := dlg as AcceptDialog
	if dialogo == null or not dialogo.is_inside_tree():
		return
	dialogo.size = tam
	var base := dialogo.get_parent()
	if base != null and base.is_inside_tree():
		var area: Vector2 = base.get_viewport().get_visible_rect().size
		dialogo.position = Vector2i((area - Vector2(tam)) * 0.5)


static func animar_entrada(control: Control, retardo: float = 0.0) -> void:
	if control == null:
		return
	control.modulate.a = 0.0
	var tw := control.create_tween()
	tw.tween_property(control, "modulate:a", 1.0, 0.16).set_delay(retardo).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


static func animar_presion(btn: BaseButton) -> void:
	if btn.has_meta("_anim_presion"):
		return
	btn.set_meta("_anim_presion", true)
	btn.button_down.connect(func():
		if not is_instance_valid(btn): return
		btn.pivot_offset = btn.size * 0.5
		var tw := btn.create_tween()
		tw.tween_property(btn, "scale", Vector2(0.98, 0.98), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	btn.button_up.connect(func():
		if not is_instance_valid(btn): return
		var tw := btn.create_tween()
		tw.tween_property(btn, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)


const ICONOS_BOTONES := {
	"Boton_Habilidades": ["Habilidades", "sparkles"],
	"Boton_Progreso": ["Progreso", "chart-no-axes-column"],
	"Boton_Actividades": ["Actividades", "calendar-check-2"],
	"Boton_Necesidades_Basicas": ["Necesidades", "heart-pulse"],
	"Boton_Perfil": ["Perfil", "user-round"],
	"Economia_Button": ["Economía", "wallet"],
	"Calendario_Button": ["Horario", "calendar-days"],
	"Carrera_Button": ["Carrera", "graduation-cap"],
	"Minijuegos_Button": ["Minijuegos", "puzzle"],
	"Vestuario_Button": ["Vestuario", "shirt"],
	"Tienda_Button": ["Tienda", "store"],
	"Temporales": ["Temporales", "clock"],
	"Fijas": ["Fijas", "clipboard-list"],
	"Especiales": ["Especiales", "sparkles"],
	"Necesidades_Basicas": ["Necesidades", "heart-pulse"],
	"Progreso": ["Progreso", "trending-up"],
	"Salir_A_Correr": ["Salir a correr", "footprints"],
	"Carrera_Deportiva": ["Carrera deportiva", "trophy"],
	"Boton_Carrera_Futbol": ["Carrera futbolística", "trophy"],
	"Estudiar": ["Estudiar", "book-open"],
	"Manualidades": ["Manualidades", "palette"],
	"Duchar": ["Duchar", "droplet"],
	"Dormir": ["Dormir", "moon"],
	"Cocinar": ["Cocinar", "utensils"],
	"Comer_Tupper": ["Comida casera", "package"],
	"Comer_Basura": ["Comida rápida", "utensils-crossed"],
	"Comer": ["Comer", "utensils"],
	"Ver_La_Television": ["Ver la televisión", "tv"],
	"Salir_De_Fiesta": ["Salir de fiesta", "party-popper"],
	"Trabajo": ["Trabajo", "briefcase-business"],
	"Cocinero": ["Cocinero", "chef-hat"],
	"Comida_Rapida": ["Comida rápida", "utensils-crossed"],
	"COMIDA_RAPIDA": ["Comida rápida", "utensils-crossed"],
	"Carpintero": ["Carpintero", "hammer"],
	"CARPINTERO": ["Carpintero", "hammer"],
	"Cientifico": ["Científico", "flask-conical"],
	"CIENTIFICO": ["Científico", "flask-conical"],
	"Abogado": ["Abogado", "scale"],
	"ABOGADO": ["Abogado", "scale"],
	"Medico": ["Médico", "stethoscope"],
	"MEDICO": ["Médico", "stethoscope"],
	"Artista": ["Artista", "palette"],
	"ARTISTA": ["Artista", "palette"],
	"Ayudante_Cocina": ["Ayudante de cocina", "utensils"],
	"Cocinero_Partida": ["Cocinero de partida", "flame"],
	"Chef_Ejecutivo": ["Chef ejecutivo", "star"],
	"MARATHON": ["Maratón", "trophy"],
	"Comprar": ["Comprar", "shopping-bag"],
	"Vender": ["Vender", "hand-coins"],
	"Elegir": ["Equipar", "check"],
	"Tab_Mensajes": ["Mensajes", "message-circle"],
	"Tab_Info": ["Datos", "user-round"],
	"Tab_Apuntes": ["Apuntes", "library"],
	"Tab_Despensa": ["Despensa", "package"],
	"Tab_Dormir": ["Dormir", "bed-double"],
	"Tab_Comer": ["Comer", "utensils"],
	"Tab_Duchar": ["Duchar", "shower-head"],
	"Boton_Cerrar": ["", "x"],
	"Boton_Volver": ["", "arrow-left"],
}


static func _icono_para(nombre_nodo: String) -> Array:
	if ICONOS_BOTONES.has(nombre_nodo):
		return ICONOS_BOTONES[nombre_nodo]
	return []


static func aplicar_tema_global(raiz: Node) -> void:
	if raiz == null:
		return
	var nodos := raiz.find_children("*", "", true, false)
	for nodo in nodos:
		if nodo is Button:
			_aplicar_boton_auto(nodo)
	for nodo in nodos:
		if nodo is Label:
			_aplicar_label(nodo)
		elif nodo is Panel:
			_aplicar_panel(nodo)
		elif nodo is ProgressBar:
			_aplicar_progreso(nodo)


static func _aplicar_label(lbl: Label) -> void:
	if lbl.has_meta("_tema_aplicado"):
		return
	lbl.set_meta("_tema_aplicado", true)
	lbl.add_theme_font_override("font", fuente_ui(400))
	if lbl.label_settings != null:
		var ls: LabelSettings = lbl.label_settings.duplicate()
		ls.font = fuente_ui(600)
		if ls.font_size >= 40:
			ls.font_size = 24
		elif ls.font_size >= 30:
			ls.font_size = 20
		lbl.label_settings = ls
	var tam_actual := 0
	if lbl.has_theme_font_size_override("font_size"):
		tam_actual = lbl.get_theme_font_size("font_size")
	if tam_actual >= 40:
		lbl.add_theme_font_size_override("font_size", 24)
	elif tam_actual >= 30:
		lbl.add_theme_font_size_override("font_size", 20)
	elif tam_actual == 0:
		lbl.add_theme_font_size_override("font_size", 15)


static func _aplicar_boton_auto(btn: Button) -> void:
	if btn.has_meta("_tema_aplicado"):
		return
	btn.set_meta("_tema_aplicado", true)
	var info := _icono_para(btn.name)
	var padre := btn.get_parent()
	var en_barra := padre != null and padre.name == "Barra_Abajo"
	var en_horario := btn.name.contains("SEMANA") or btn.name.contains("ACTIVIDAD") or btn.name == "Hora"

	if en_barra:
		btn.text = ""
		btn.icon = null
		btn.tooltip_text = info[0] if info.size() > 0 else ""
		_crear_contenido_nav(btn, info[1] if info.size() > 1 else "circle-help", info[0] if info.size() > 0 else "")
		aplicar_estilo_boton(btn, "nav")
	elif btn.name in ["Boton_Perfil", "Economia_Button", "Calendario_Button", "Carrera_Button", "Minijuegos_Button", "Vestuario_Button", "Tienda_Button"]:
		btn.text = info[0] if info.size() > 0 else btn.text
		aplicar_estilo_boton(btn, "top", PRIMARIO, info[1] if info.size() > 1 else "")
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	elif btn.name.begins_with("Flecha_") or btn.name == "Boton_Cerrar" or btn.name == "Boton_Volver":
		btn.text = ""
		btn.icon = null
		btn.flat = false
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var st_f := caja(SUPERFICIE, 11, BORDE, 1, 1)
		st_f.border_width_bottom = 2
		var st_fh := caja(SUPERFICIE_2, 11, BORDE_FUERTE, 1, 1)
		st_fh.border_width_bottom = 2
		btn.add_theme_stylebox_override("normal", st_f)
		btn.add_theme_stylebox_override("hover", st_fh)
		btn.add_theme_stylebox_override("pressed", caja(PRIMARIO_SUAVE, 11, PRIMARIO, 1, 0))
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var ic := "arrow-left"
		if btn.name == "Flecha_Arriba": ic = "chevron-up"
		elif btn.name == "Flecha_Abajo": ic = "chevron-down"
		elif btn.name == "Flecha_Atras": ic = "arrow-left"
		elif btn.name == "Boton_Cerrar": ic = "x"
		btn.icon = icono(ic)
		btn.expand_icon = false
		btn.add_theme_constant_override("icon_max_width", 20)
		btn.add_theme_color_override("icon_normal_color", TINTA)
		btn.add_theme_color_override("icon_hover_color", TINTA)
		btn.add_theme_color_override("icon_pressed_color", PRIMARIO)
		btn.add_theme_color_override("icon_focus_color", TINTA)
	elif btn.name in ["Comprar", "Vender", "Elegir"]:
		btn.text = info[0] if info.size() > 0 else btn.text
		var var_btn := "primario" if btn.name != "Vender" else "suave"
		var col_btn := EXITO if btn.name == "Comprar" else (AZUL if btn.name == "Elegir" else PELIGRO)
		aplicar_estilo_boton(btn, var_btn, col_btn, info[1] if info.size() > 1 else "")
		btn.add_theme_font_size_override("font_size", 13)
	elif btn.name == "Cancelar":
		btn.text = "Cancelar"
		aplicar_estilo_boton(btn, "secundario")
	elif btn.name in ["Crear_Actividad", "OCUPAR_ACTIVIDAD"]:
		if btn.name == "Crear_Actividad":
			btn.text = "Crear actividad"
		else:
			btn.text = "Elegir actividad"
		aplicar_estilo_boton(btn, "exito", EXITO)
	elif btn.name == "ELIMINAR_ACTIVIDAD":
		btn.text = "Eliminar actividad"
		aplicar_estilo_boton(btn, "peligro", PELIGRO)
	elif btn.name in ["SIGUIENTE SEMANA", "ANTERIOR SEMANA"]:
		aplicar_estilo_boton(btn, "chip", ROJO_BIT)
		btn.add_theme_font_size_override("font_size", 13)
	elif en_horario:
		aplicar_estilo_boton(btn, "chip", ROJO_BIT)
		btn.add_theme_font_size_override("font_size", 14)
	elif info.size() > 0 and info[0] != "":
		btn.text = info[0]
		aplicar_estilo_boton(btn, "tarjeta", PRIMARIO, info[1] if info.size() > 1 else "")
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 70)
	else:
		aplicar_estilo_boton(btn, "secundario")


static func configurar_nav(btn: Button, nombre_icono: String, etiqueta: String) -> void:
	_crear_contenido_nav(btn, nombre_icono, etiqueta)
	aplicar_estilo_boton(btn, "nav")


static func _crear_contenido_nav(btn: Button, nombre_icono: String, etiqueta: String) -> void:
	for hijo in btn.get_children():
		if hijo.name.begins_with("Nav_"):
			hijo.queue_free()
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	var v := VBoxContainer.new()
	v.name = "Nav_Contenido"
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 2
	v.offset_right = -2
	v.offset_top = 4
	v.offset_bottom = -4
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ic := icono_rect(nombre_icono, 20, Color("#cbd5e1"))
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ic)
	var lbl := texto(etiqueta, 11, Color("#cbd5e1"), 600)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(lbl)
	btn.add_child(v)


static func _aplicar_panel(panel: Panel) -> void:
	if panel.has_meta("_tema_aplicado"):
		return
	if panel.name == "Top_Bar_Panel":
		return
	panel.set_meta("_tema_aplicado", true)
	panel.add_theme_stylebox_override("panel", caja_tarjeta())


static func _aplicar_progreso(bar: ProgressBar) -> void:
	if bar.has_meta("_tema_aplicado"):
		return
	bar.set_meta("_tema_aplicado", true)
	bar.show_percentage = false
	bar.add_theme_font_override("font", fuente_ui(600))
	bar.add_theme_font_size_override("font_size", 12)
	bar.add_theme_color_override("font_color", TINTA)
	bar.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0))
	bar.add_theme_constant_override("outline_size", 0)
	bar.add_theme_stylebox_override("background", barra_fondo())
	bar.add_theme_stylebox_override("fill", barra_relleno(EXITO))


static func marcar_nav_activo(barra: Node, nombre_activo: String) -> void:
	if barra == null:
		return
	for btn in barra.get_children():
		if btn is Button:
			var activo := btn.name == nombre_activo
			var fondo := ROJO_BIT if activo else Color(0, 0, 0, 0)
			var hover := ROJO_BIT.lightened(0.06) if activo else Color("#24334b")
			var st_activo := caja(fondo, 14, ROJO_BIT_OSCURO, 0, 2 if activo else 0)
			if activo:
				st_activo.border_width_bottom = 3
				st_activo.border_width_top = 1
				st_activo.border_color = ROJO_BIT_OSCURO
			var st_hover := caja(hover, 14, Color(0, 0, 0, 0), 0, 0)
			var st_pressed := caja(ROJO_BIT, 14, ROJO_BIT_OSCURO, 0, 0)
			st_pressed.border_width_bottom = 2
			btn.add_theme_stylebox_override("normal", st_activo)
			btn.add_theme_stylebox_override("hover", st_hover)
			btn.add_theme_stylebox_override("pressed", st_pressed)
			if btn.has_node("Nav_Contenido"):
				var col_ic := Color.WHITE if activo else Color("#94a3b8")
				var col_lbl := Color.WHITE if activo else Color("#cbd5e1")
				for hijo in btn.get_node("Nav_Contenido").get_children():
					if hijo is TextureRect:
						hijo.self_modulate = col_ic
					elif hijo is Label:
						hijo.add_theme_color_override("font_color", col_lbl)
						hijo.add_theme_font_override("font", fuente_ui(700 if activo else 600))


class BannerRayasBitLife extends Control:
	var color_base: Color
	var color_borde: Color
	var grosor_borde: float
	var alpha_rayas: float

	func _init(base: Color = ROJO_BIT, borde: Color = ROJO_BIT_OSCURO, grosor: float = 3.0, alpha_r: float = 0.065) -> void:
		color_base = base
		color_borde = borde
		grosor_borde = grosor
		alpha_rayas = alpha_r
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip_contents = true

	func _draw() -> void:
		var s := size
		draw_rect(Rect2(Vector2.ZERO, s), color_base)
		# Brillo superior sutil estilo BitLife
		draw_rect(Rect2(0, 0, s.x, minf(26.0, s.y * 0.35)), Color(1.0, 1.0, 1.0, 0.055))
		# Franjas diagonales sutiles
		var paso := 76.0
		var ancho := 28.0
		var sesgo := s.y * 0.45
		var raya_col := Color(1.0, 1.0, 1.0, alpha_rayas)
		var x := -sesgo
		while x < s.x + paso:
			draw_colored_polygon(PackedVector2Array([
				Vector2(x, s.y),
				Vector2(x + ancho, s.y),
				Vector2(x + ancho + sesgo, 0.0),
				Vector2(x + sesgo, 0.0),
			]), raya_col)
			x += paso
		if grosor_borde > 0.0:
			draw_rect(Rect2(0, s.y - grosor_borde, s.x, grosor_borde), color_borde)
