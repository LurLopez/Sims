class_name Logo_Juego
extends HBoxContainer
## Logotipo horizontal oficial de SIMS LIFE.
##
## La insignia es un medallón ilustrado con la cara real del protagonista
## (Personaje_Visual + Apariencia_Personaje), así que el logo local cambia
## automáticamente con el Sim creado. El wordmark y el marco son assets fijos
## de marca; el icono de Play Store / lanzador es un recurso independiente.
##
## Uso:
##   var logo := Logo_Juego.new()
##   logo.tamano_insignia = 104
##   logo.subtitulo = "Simulador de vida en tiempo real"
##   add_child(logo)
##   logo.configurar_apariencia(Variables_Estaticas.Apariencia)

const TEX_WORDMARK_CLARO := preload("res://Imagenes/Marca/wordmark_claro.png")
const TEX_WORDMARK_OSCURO := preload("res://Imagenes/Marca/wordmark_oscuro.png")
const TEX_MARCO := preload("res://Imagenes/Marca/medallon_marco.png")
const FUENTE_SUBTITULO := preload("res://Fuentes/UI/Mulish-700.ttf")

## Margen del hueco de la cara respecto al lado del medallón:
## (1 - r_hueco / lado) / 2. Coincide con Arte_Fuente/Marca/generar_logo.py.
const MARGEN_MARCO := 0.1429
## Alto del wordmark respecto al medallón.
const ALTO_WORDMARK := 0.72

const CREMA_SUBTITULO := Color("#fff0d6")
const MARRON_SUBTITULO := Color("#5c2a2f")
const ORO := Color("#f5b942")
const ORO_OSCURO := Color("#d99a2b")

## Apariencia del Sim que se dibuja en la insignia. Vacío = apariencia global guardada.
var apariencia: Dictionary = {}
var tamano_insignia: int = 104
var animar_retrato: bool = true
var subtitulo: String = "Simulador de vida en tiempo real"
## Tamaño manual del subtítulo en px. 0 = proporcional al medallón.
var tamano_subtitulo: int = 0
## true para fondos claros (wordmark en granate y subtítulo oscuro).
var variante_oscura: bool = false

# --- Compatibilidad con la API anterior (el wordmark ya es un asset fijo).
var texto_principal: String = "SIMS"
var texto_secundario: String = "LIFE"
var tamano_texto_principal: int = 40
var tamano_texto_secundario: int = 15
var color_texto: Color = Color.WHITE
var color_subtitulo: Color = CREMA_SUBTITULO
var color_pill_fondo: Color = Color("#fff7ed")
var color_pill_texto: Color = Color("#d62828")

var _construido: bool = false
var _retrato: Personaje_Visual = null
var _mascara: Panel = null


func _ready() -> void:
	add_theme_constant_override("separation", maxi(6, int(round(tamano_insignia * 0.13))))
	alignment = BoxContainer.ALIGNMENT_BEGIN
	_construir()


## Actualiza la cara dibujada en la insignia sin reconstruir todo el logo.
func configurar_apariencia(datos: Dictionary) -> void:
	apariencia = datos
	if _retrato != null and is_instance_valid(_retrato):
		_retrato.apariencia = _apariencia_actual()


func _apariencia_actual() -> Dictionary:
	if not apariencia.is_empty():
		return Apariencia_Personaje.normalizar(apariencia)
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


func _construir() -> void:
	if _construido:
		return
	_construido = true
	custom_minimum_size = Vector2(0, tamano_insignia)
	add_child(_crear_insignia())
	add_child(_crear_texto())


# ------------------------------------------------------------------ insignia

func _crear_insignia() -> Control:
	var insignia := Control.new()
	insignia.name = "Insignia_Logo"
	insignia.custom_minimum_size = Vector2(tamano_insignia, tamano_insignia)
	insignia.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	insignia.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	insignia.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Ventana circular donde se dibuja la cara.
	var margen := int(round(tamano_insignia * MARGEN_MARCO))
	_mascara = Panel.new()
	_mascara.name = "Mascara_Logo"
	_mascara.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mascara.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	_mascara.anchor_left = 0.0
	_mascara.anchor_top = 0.0
	_mascara.anchor_right = 1.0
	_mascara.anchor_bottom = 1.0
	_mascara.offset_left = margen
	_mascara.offset_top = margen
	_mascara.offset_right = -margen
	_mascara.offset_bottom = -margen
	var st := StyleBoxFlat.new()
	st.bg_color = Color("#fde3c8")
	st.set_corner_radius_all(999)
	st.anti_aliasing = true
	_mascara.add_theme_stylebox_override("panel", st)
	insignia.add_child(_mascara)

	_retrato = Personaje_Visual.new(_apariencia_actual(), "retrato")
	_retrato.name = "Retrato_Logo"
	_retrato.margen_retrato = 12.0
	_retrato.expresion = "sonrisa"
	_retrato.animar_idle = animar_retrato
	_retrato.dibujar_fondo_sunburst = true
	_retrato.color_fondo_base = Color("#fde3c8")
	_retrato.color_fondo_rayo = Color("#f8c795")
	_retrato.set_anchors_preset(Control.PRESET_FULL_RECT)
	_mascara.add_child(_retrato)

	# Marco, aros y destello dorado (el centro del PNG es transparente).
	var marco := TextureRect.new()
	marco.name = "Marco_Logo"
	marco.texture = TEX_MARCO
	marco.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	marco.stretch_mode = TextureRect.STRETCH_SCALE
	marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marco.set_anchors_preset(Control.PRESET_FULL_RECT)
	insignia.add_child(marco)

	return insignia


# ------------------------------------------------------------------ texto

func _crear_texto() -> Control:
	var col := VBoxContainer.new()
	col.name = "Texto_Logo"
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 0)

	var textura: Texture2D = TEX_WORDMARK_OSCURO if variante_oscura else TEX_WORDMARK_CLARO
	var aspecto := 1013.0 / 360.0
	if textura != null and textura.get_height() > 0:
		aspecto = float(textura.get_width()) / float(textura.get_height())

	var wordmark := TextureRect.new()
	wordmark.name = "Wordmark_Logo"
	wordmark.texture = textura
	wordmark.custom_minimum_size = Vector2(
		round(tamano_insignia * ALTO_WORDMARK * aspecto),
		round(tamano_insignia * ALTO_WORDMARK))
	wordmark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wordmark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	wordmark.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	wordmark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(wordmark)

	if not subtitulo.is_empty():
		col.add_child(_crear_subtitulo())

	return col


func _crear_subtitulo() -> Control:
	var fila := HBoxContainer.new()
	fila.name = "Subtitulo_Logo"
	fila.add_theme_constant_override("separation", maxi(4, int(round(tamano_insignia * 0.055))))
	fila.alignment = BoxContainer.ALIGNMENT_BEGIN

	var regla := Panel.new()
	regla.name = "Regla_Subtitulo"
	regla.custom_minimum_size = Vector2(
		maxi(12, int(round(tamano_insignia * 0.22))),
		maxi(2, int(round(tamano_insignia * 0.028))))
	regla.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	regla.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := StyleBoxFlat.new()
	st.bg_color = ORO_OSCURO if variante_oscura else ORO
	st.set_corner_radius_all(99)
	st.anti_aliasing = true
	regla.add_theme_stylebox_override("panel", st)
	fila.add_child(regla)

	var lbl := Label.new()
	lbl.name = "Subtitulo_Texto"
	lbl.text = subtitulo
	lbl.add_theme_font_override("font", FUENTE_SUBTITULO)
	var tam_fuente := tamano_subtitulo if tamano_subtitulo > 0 else maxi(9, int(round(tamano_insignia * 0.125)))
	lbl.add_theme_font_size_override("font_size", tam_fuente)
	lbl.add_theme_color_override("font_color", _color_subtitulo_actual())
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(lbl)

	return fila


func _color_subtitulo_actual() -> Color:
	if variante_oscura and color_subtitulo == CREMA_SUBTITULO:
		return MARRON_SUBTITULO
	return color_subtitulo
