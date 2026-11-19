class_name Logo_Juego
extends HBoxContainer
## Logotipo horizontal reutilizable del juego.
## La insignia dibuja la cara real del protagonista (Personaje_Visual + Apariencia_Personaje),
## por lo que el logo local cambia automáticamente con el personaje creado.
## El icono de Play Store / lanzador es un recurso fijo independiente.

const TINTA := Color("#111827")

## Apariencia del Sim que se dibuja en la insignia. Vacío = apariencia global guardada.
var apariencia: Dictionary = {}
var tamano_insignia: int = 92
var animar_retrato: bool = true
var texto_principal: String = "SIMS"
var texto_secundario: String = "LIFE"
var subtitulo: String = "Simulador de vida en tiempo real"
var tamano_texto_principal: int = 40
var tamano_texto_secundario: int = 15
var tamano_subtitulo: int = 13
var color_texto: Color = Color.WHITE
var color_subtitulo: Color = Color("#fee2e2")
var color_pill_fondo: Color = Color("#fff7ed")
var color_pill_texto: Color = Estilos_UI.ROJO_BIT

var _construido: bool = false
var _retrato: Personaje_Visual = null
var _mascara: Panel = null


func _ready() -> void:
	add_theme_constant_override("separation", 14)
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
				return Apariencia_Personaje.normalizar(ap)
	return Apariencia_Personaje.por_defecto()


func _construir() -> void:
	if _construido:
		return
	_construido = true
	custom_minimum_size = Vector2(0, tamano_insignia)

	add_child(_crear_insignia())
	add_child(_crear_texto())


func _crear_insignia() -> Control:
	var insignia := Insignia_Logo.new(tamano_insignia)
	insignia.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	insignia.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	insignia.custom_minimum_size = Vector2(tamano_insignia, tamano_insignia)

	var margen := int(round(tamano_insignia * 0.17))
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
	st.bg_color = Color("#bae6fd")
	st.set_corner_radius_all(999)
	st.anti_aliasing = true
	_mascara.add_theme_stylebox_override("panel", st)
	insignia.add_child(_mascara)

	_retrato = Personaje_Visual.new(_apariencia_actual(), "retrato_cercano")
	_retrato.name = "Retrato_Logo"
	_retrato.set_anchors_preset(Control.PRESET_FULL_RECT)
	_retrato.expresion = "feliz"
	_retrato.animar_idle = animar_retrato
	_retrato.dibujar_fondo_sunburst = true
	_retrato.color_fondo_base = Color("#bae6fd")
	_retrato.color_fondo_rayo = Color("#7dd3fc")
	_mascara.add_child(_retrato)

	# Destello dorado en la esquina: refuerza el aire de pegatina cómic.
	var brillo := Estilos_UI.icono_rect("sparkles", maxi(16, int(round(tamano_insignia * 0.25))), Color("#fbbf24"))
	brillo.name = "Destello"
	brillo.position = Vector2(tamano_insignia - brillo.custom_minimum_size.x * 0.7, -brillo.custom_minimum_size.y * 0.25)
	brillo.rotation = deg_to_rad(8.0)
	insignia.add_child(brillo)

	return insignia


func _crear_texto() -> Control:
	var col := VBoxContainer.new()
	col.name = "Texto_Logo"
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 1)

	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_BEGIN
	fila.add_theme_constant_override("separation", 8)
	col.add_child(fila)

	var lbl_principal := Estilos_UI.titulo(texto_principal, tamano_texto_principal, color_texto)
	lbl_principal.add_theme_font_override("font", Estilos_UI.fuente_logo())
	lbl_principal.add_theme_color_override("font_shadow_color", Color(0.28, 0.03, 0.03, 0.55))
	lbl_principal.add_theme_constant_override("shadow_offset_y", 3)
	lbl_principal.add_theme_constant_override("shadow_offset_x", 0)
	fila.add_child(lbl_principal)

	var pill := PanelContainer.new()
	pill.name = "Pill_Life"
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var st := Estilos_UI.caja(color_pill_fondo, 8, TINTA, 2, 1)
	st.content_margin_left = 10
	st.content_margin_right = 10
	st.content_margin_top = 2
	st.content_margin_bottom = 3
	pill.add_theme_stylebox_override("panel", st)
	var lbl_sec := Estilos_UI.texto(texto_secundario, tamano_texto_secundario, color_pill_texto, 800)
	lbl_sec.add_theme_font_override("font", Estilos_UI.fuente_logo())
	pill.add_child(lbl_sec)
	fila.add_child(pill)

	if not subtitulo.is_empty():
		var lbl_sub := Estilos_UI.texto(subtitulo, tamano_subtitulo, color_subtitulo, 600)
		lbl_sub.name = "Subtitulo_Logo"
		col.add_child(lbl_sub)

	return col


## Insignia dibujada a mano: sombra, aro blanco, anillo rojo y aro interior de tinta.
class Insignia_Logo extends Control:
	const TINTA := Color("#111827")
	var _tam: int = 92

	func _init(tam: int = 92) -> void:
		_tam = tam
		custom_minimum_size = Vector2(tam, tam)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var centro := size * 0.5
		var radio := minf(size.x, size.y) * 0.5
		var tinta := TINTA
		draw_circle(centro + Vector2(0.0, radio * 0.05), radio - 1.0, Color(0.04, 0.05, 0.09, 0.30))
		draw_circle(centro, radio - 1.5, Color.WHITE)
		draw_arc(centro, radio - 2.5, 0.0, TAU, 72, tinta, maxf(3.0, radio * 0.055), true)
		draw_circle(centro, radio - radio * 0.10, Estilos_UI.ROJO_BIT)
		draw_arc(centro, radio - radio * 0.10, 0.0, TAU, 72, tinta, maxf(2.0, radio * 0.035), true)
		draw_circle(centro, radio - radio * 0.155, Color.WHITE)
		draw_arc(centro, radio - radio * 0.155, 0.0, TAU, 72, tinta, maxf(1.8, radio * 0.026), true)
