class_name Icono_Producto
extends Control

# Iconos de productos, cultivos y elementos de «La Granja».
# Usa los PNG ilustrados de alta resolución en Imagenes/Granja/ y reserva
# dibujo vectorial limpio solo para monedas (MG / €) y respaldo seguro.

const FUENTE := preload("res://Fuentes/UI/DMSans-700.ttf")

const RUTAS_ICONOS := {
	"huevo": "res://Imagenes/Granja/Icono_Huevo.png",
	"leche": "res://Imagenes/Granja/Icono_Leche.png",
	"harina": "res://Imagenes/Granja/Icono_Harina.png",
	"pan": "res://Imagenes/Granja/Icono_Pan.png",
	"queso": "res://Imagenes/Granja/Icono_Queso.png",
	"tierra": "res://Imagenes/Granja/Icono_Parcela.png",
	"trigo": "res://Imagenes/Granja/Trigo.png",
	"zanahoria": "res://Imagenes/Granja/Zanahoria.png",
	"maiz": "res://Imagenes/Granja/Maiz.png",
	"gallina": "res://Imagenes/Granja/Gallina.png",
	"vaca": "res://Imagenes/Granja/Vaca.png",
	"molino": "res://Imagenes/Granja/Molino.png",
	"panaderia": "res://Imagenes/Granja/Panaderia.png",
	"queseria": "res://Imagenes/Granja/Queseria.png",
}

static var _cache_tex: Dictionary = {}

var tipo: String = "mg"
var _tex: Texture2D = null


func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(54, 54)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_Cargar_Textura()


func configurar(nuevo_tipo: String) -> void:
	tipo = nuevo_tipo
	_Cargar_Textura()
	queue_redraw()


func _Cargar_Textura() -> void:
	_tex = obtener_textura(tipo)


static func obtener_textura(clave: String) -> Texture2D:
	if _cache_tex.has(clave):
		return _cache_tex[clave]
	var ruta: String = str(RUTAS_ICONOS.get(clave, ""))
	if ruta != "" and ResourceLoader.exists(ruta):
		var res := load(ruta)
		if res is Texture2D:
			_cache_tex[clave] = res
			return res
	_cache_tex[clave] = null
	return null


func _draw() -> void:
	if _tex != null:
		var lado: float = minf(size.x, size.y)
		if lado <= 1.0:
			return
		var rect := Rect2((size - Vector2(lado, lado)) * 0.5, Vector2(lado, lado))
		draw_texture_rect(_tex, rect, false)
		return

	var escala: float = minf(size.x, size.y) / 54.0
	if escala <= 0.01:
		return
	draw_set_transform(size * 0.5, 0.0, Vector2(escala, escala))
	var c := Vector2.ZERO
	match tipo:
		"euro":
			draw_circle(c, 22, Color("#15803d"))
			draw_circle(c, 18, Color("#4ade80"))
			draw_circle(c + Vector2(-6, -6), 5, Color(1, 1, 1, 0.55))
			draw_string(FUENTE, c + Vector2(-9, 8), "€", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#14532d"))
		_:
			draw_circle(c, 22, Color("#b45309"))
			draw_circle(c, 18, Color("#fbbf24"))
			draw_circle(c + Vector2(-6, -6), 5, Color(1, 1, 1, 0.60))
			draw_string(FUENTE, c + Vector2(-12, 6), "MG", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#78350f"))
