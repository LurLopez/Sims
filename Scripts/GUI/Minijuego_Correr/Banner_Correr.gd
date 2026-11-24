class_name Banner_Correr
extends Control

# Banner de la tarjeta del hub para "Salir a correr". Usa un recorte
# panorámico del arte del parque, monedas, obstáculos y el Personaje_Visual 2D
# real del Sim (con su misma cara, género, peinado y ropa equipada).

const TEX_FONDO: Texture2D = preload("res://Imagenes/Minijuego_Correr/fondo_menu.webp")
const TEX_MONEDA: Texture2D = preload("res://Imagenes/Minijuego_Correr/Objetos/moneda.png")
const TEX_VALLA: Texture2D = preload("res://Imagenes/Minijuego_Correr/Objetos/valla.png")
const TEX_CONTENEDOR: Texture2D = preload("res://Imagenes/Minijuego_Correr/Objetos/contenedor.png")

var _personaje_2d: Personaje_Visual = null


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	custom_minimum_size.y = 142.0

	_personaje_2d = Personaje_Visual.new(_Obtener_Apariencia_Actual(), "cuerpo_completo")
	_personaje_2d.name = "Corredor_Sim_2D"
	_personaje_2d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_personaje_2d.dibujar_fondo_sunburst = false
	_personaje_2d.pose = "correr"
	_personaje_2d.expresion = "feliz"
	add_child(_personaje_2d)
	_Actualizar_Layout_Personaje()
	queue_redraw()


static func _Obtener_Apariencia_Actual() -> Dictionary:
	var base: Dictionary = Apariencia_Personaje.por_defecto()
	var arbol := Engine.get_main_loop() as SceneTree
	if arbol != null and arbol.root != null:
		var est := arbol.root.get_node_or_null("Variables_Estaticas")
		if est != null and "Apariencia" in est:
			base = Apariencia_Personaje.normalizar(est.get("Apariencia"))
		var cocina := arbol.root.get_node_or_null("Sistema_Cocina")
		if cocina != null and cocina.has_method("Obtener_Apariencia_Con_Ropa_Equipada"):
			var ap: Variant = cocina.call("Obtener_Apariencia_Con_Ropa_Equipada", base)
			if ap is Dictionary:
				return Apariencia_Personaje.normalizar(ap)
	return base


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_Actualizar_Layout_Personaje()
		queue_redraw()
	elif what == NOTIFICATION_VISIBILITY_CHANGED and visible and _personaje_2d != null:
		_personaje_2d.apariencia = _Obtener_Apariencia_Actual()


func _Actualizar_Layout_Personaje() -> void:
	if _personaje_2d == null or size.x < 10.0 or size.y < 10.0:
		return
	var w: float = size.x
	var h: float = size.y
	var alto_p: float = h * 1.06
	var ancho_p: float = alto_p * 0.85
	_personaje_2d.position = Vector2(w * 0.62 - ancho_p * 0.5, h - alto_p + 4.0)
	_personaje_2d.size = Vector2(ancho_p, alto_p)


func _draw() -> void:
	if size.x < 10.0 or size.y < 10.0:
		return
	_Actualizar_Layout_Personaje()
	var w: float = size.x
	var h: float = size.y
	var escala: float = w / 680.0

	# Recorte panorámico del parque: mantenemos la proporción de la franja
	# original para no deformar árboles, farolas ni el skyline.
	var src := Rect2(0.0, 700.0, 941.0, 250.0)
	var src_rel: float = src.size.x / src.size.y
	var destino := Rect2(0.0, 0.0, w, h)
	if w / h > src_rel:
		var alto: float = w / src_rel
		destino = Rect2(0.0, (h - alto) * 0.5, w, alto)
	else:
		var ancho: float = h * src_rel
		destino = Rect2((w - ancho) * 0.5, 0.0, ancho, h)
	draw_texture_rect_region(TEX_FONDO, destino, src)

	# Degradado para integrar la franja con la tarjeta.
	for i in range(12):
		var t: float = float(i) / 12.0
		draw_rect(Rect2(0.0, 0.0, w * 0.52, h), Color(0.03, 0.09, 0.18, 0.035 * (1.0 - t)), true)
	for i in range(8):
		draw_rect(Rect2(0.0, h - float(i) * 2.0, w, 2.0), Color(0.02, 0.06, 0.12, 0.025 * float(8 - i)), true)

	# Rayos de sol.
	var sol := Vector2(w * 0.58, h * 0.30)
	for i in range(7):
		var angulo: float = -PI * 0.5 + (float(i) - 3.0) * 0.12
		var largo: float = w * 0.55
		draw_colored_polygon(PackedVector2Array([
			sol,
			sol + Vector2(cos(angulo - 0.012), sin(angulo - 0.012)) * largo,
			sol + Vector2(cos(angulo + 0.012), sin(angulo + 0.012)) * largo,
		]), Color(1.0, 0.94, 0.72, 0.035))

	# Obstáculos y monedas, como una pequeña escena del juego.
	_Dibujar_Textura(TEX_CONTENEDOR, Vector2(w * 0.19, h * 0.99), 66.0 * escala)
	_Dibujar_Textura(TEX_VALLA, Vector2(w * 0.38, h * 1.01), 54.0 * escala)
	_Dibujar_Textura(TEX_VALLA, Vector2(w * 0.82, h * 1.01), 60.0 * escala)

	for moneda in [
		Vector2(w * 0.50, h * 0.76), Vector2(w * 0.57, h * 0.64),
		Vector2(w * 0.64, h * 0.54), Vector2(w * 0.71, h * 0.47),
	]:
		_Dibujar_Textura(TEX_MONEDA, moneda, 24.0 * escala)

	# Líneas de velocidad laterales.
	for i in range(4):
		var y: float = h * (0.26 + float(i) * 0.16)
		draw_line(Vector2(0.0, y), Vector2(w * 0.14, y - 4.0), Color(1, 1, 1, 0.10), 2.0, true)
		draw_line(Vector2(w, y + 8.0), Vector2(w * 0.86, y + 2.0), Color(1, 1, 1, 0.09), 2.0, true)


func _Dibujar_Textura(tex: Texture2D, base: Vector2, alto: float) -> void:
	var ancho: float = alto * float(tex.get_width()) / float(tex.get_height())
	draw_texture_rect(tex, Rect2(base.x - ancho * 0.5, base.y - alto, ancho, alto), false)
