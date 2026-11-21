class_name Arte_Cocina
extends RefCounted

# ============================================================================
# Capa de arte del Minijuego de Cocina basada en el pack de sprites PNG
# (Imagenes/Minijuego_Cocina). Incluye:
#   · Registro central de texturas.
#   · Composición por capas de hamburguesas (pan, carne, queso, lechuga...).
#   · Controles dibujados a mano para clientes, tickets, platos, cocción,
#     bebidas, mueble/recipientes de ingredientes y partículas animadas.
# Todos los controles internos usan MOUSE_FILTER_IGNORE: la interacción la
# gestiona Arrastre_Cocina para permitir arrastrar y soltar con el dedo.
# ============================================================================

const FUENTE_UI := preload("res://Fuentes/UI/DMSans-700.ttf")
const FUENTE_TIT := preload("res://Fuentes/UI/Bricolage-800.ttf")

# --- Carga perezosa de texturas ---------------------------------------------
# El pack de la cocina tiene ~150 PNG (~72 MB en RGBA). No deben cargarse al
# arrancar el juego ni al abrir el menú: cada textura se decodifica la primera
# vez que se dibuja y se conserva en caché durante la sesión. Así el arranque
# en móviles modestos no paga memoria ni tiempo de carga que solo usa la cocina.
static var _cache_texturas: Dictionary = {}

static func _tex(ruta: String) -> Texture2D:
	var tex: Texture2D = _cache_texturas.get(ruta)
	if tex == null:
		tex = load(ruta) as Texture2D
		_cache_texturas[ruta] = tex
	return tex


# --- Escenario y mobiliario -------------------------------------------------
static var TEX_FONDO: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Fondo_Restaurante.png")
# Fondo dedicado del banner de la tarjeta "Cocina": mostrador en primer plano,
# damero poco contrastado y comedor desenfocado (incluye viñeta y luz horneadas).
static var TEX_BANNER: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Banner_Cocina.png")
static var TEX_PLANCHA: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Estaciones/Plancha.png")
static var TEX_FREIDORA: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Estaciones/Freidora.png")
static var TEX_REFRESCOS: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Estaciones/Dispensador_Refrescos.png")
static var TEX_PAPELERA: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Estaciones/Papelera.png")
static var TEX_ENCIMERA: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Mostrador/Encimera_Larga.png")
static var TEX_FRENTE_MOSTRADOR: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Mostrador/Frente_Mostrador.png")
static var TEX_TICKET_VERDE: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/UI/Ticket_Verde.png")
static var TEX_BURBUJA: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/UI/Burbuja.png")
static var TEX_TICKET_ROJO: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/UI/Ticket_Rojo.png")

# --- Comida -----------------------------------------------------------------
static var TEX_PAN_INF: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Comida/Ingredientes/Pan_Inferior.png")
static var TEX_PAN_SUP: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Comida/Ingredientes/Pan_Superior.png")
static var TEX_CARNE_CRUDA: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Comida/Ingredientes/Carne_Cruda.png")
static var TEX_CARNE_HECHA: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Comida/Ingredientes/Carne_Hecha.png")
static var TEX_CARNE_QUEMADA: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Comida/Ingredientes/Carne_Quemada.png")
static var TEX_QUESO: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Comida/Ingredientes/Queso.png")
static var TEX_LECHUGA: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Comida/Ingredientes/Lechuga.png")
static var TEX_TOMATE: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Comida/Ingredientes/Tomate.png")
static var TEX_PATATAS: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Comida/Platos/Patatas_Fritas.png")
static var TEX_HAMBURGUESA: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Comida/Platos/Hamburguesa_Sola.png")
static var TEX_REFRESCO: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Comida/Platos/Refresco_Cola.png")
static var TEX_PLATO: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Emplatado/Plato_Vacio.png")
# Plato vacío dibujado en perspectiva 3/4 (para composiciones de cartel/banner,
# donde el plato cenital se leía como un círculo plano).
static var TEX_PLATO_PERSPECTIVA: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Emplatado/Plato_Perspectiva.png")
static var TEX_BANDEJA: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Emplatado/Bandeja_Metal.png")
static var TEX_CESTA: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Emplatado/Cesta_Patatas.png")
static var TEX_VASOS: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Emplatado/Vasos_Rojos.png")
static var TEX_BOL_LECHUGA: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Emplatado/Bol_Lechuga.png")
static var TEX_BANDEJA_TOMATE: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Emplatado/Bandeja_Tomate.png")
static var TEX_PILA_PLATOS: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Emplatado/Pila_Platos.png")
static var TEX_BANDEJAS_APILADAS: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Emplatado/Bandejas_Apiladas.png")

# --- Interfaz ---------------------------------------------------------------
static var TEX_MONEDA: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/UI/Moneda.png")
static var TEX_PILA_MONEDAS: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/UI/Pila_Monedas.png")
static var TEX_RELOJ: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/UI/Reloj.png")
static var TEX_ESTRELLA: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/UI/Estrella_Dorada.png")
static var TEX_ESTRELLA_VACIA: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/UI/Estrella_Vacia.png")
static var TEX_CORAZON: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/UI/Corazon.png")
static var TEX_BOTE_PROPINAS: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/UI/Bote_Propinas.png")
static var TEX_FLECHA: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/UI/Flecha.png")
static var TEX_CANDADO_CERRADO: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/UI/Candado_Cerrado.png")

# --- Ilustraciones de la pantalla de Mejoras --------------------------------
# Tres variantes por mejora (básica, mejorada y profesional). Se generan desde
# las hojas maestras de Arte_Fuente/Minijuego_Cocina/Mejoras con
# `python3 tools/procesar_mejoras_cocina.py`.
const RUTAS_MEJORAS: Dictionary = {
	"plancha": [
		"res://Imagenes/Minijuego_Cocina/Mejoras/plancha_nv1.png",
		"res://Imagenes/Minijuego_Cocina/Mejoras/plancha_nv2.png",
		"res://Imagenes/Minijuego_Cocina/Mejoras/plancha_nv3.png",
	],
	"emplatado": [
		"res://Imagenes/Minijuego_Cocina/Mejoras/emplatado_nv1.png",
		"res://Imagenes/Minijuego_Cocina/Mejoras/emplatado_nv2.png",
		"res://Imagenes/Minijuego_Cocina/Mejoras/emplatado_nv3.png",
	],
	"termostato": [
		"res://Imagenes/Minijuego_Cocina/Mejoras/termostato_nv1.png",
		"res://Imagenes/Minijuego_Cocina/Mejoras/termostato_nv2.png",
		"res://Imagenes/Minijuego_Cocina/Mejoras/termostato_nv3.png",
	],
	"ingredientes": [
		"res://Imagenes/Minijuego_Cocina/Mejoras/ingredientes_nv1.png",
		"res://Imagenes/Minijuego_Cocina/Mejoras/ingredientes_nv2.png",
		"res://Imagenes/Minijuego_Cocina/Mejoras/ingredientes_nv3.png",
	],
	"ambiente": [
		"res://Imagenes/Minijuego_Cocina/Mejoras/ambiente_nv1.png",
		"res://Imagenes/Minijuego_Cocina/Mejoras/ambiente_nv2.png",
		"res://Imagenes/Minijuego_Cocina/Mejoras/ambiente_nv3.png",
	],
}


static func textura_mejora(mejora_id: String, nivel: int) -> Texture2D:
	var variantes: Array = RUTAS_MEJORAS.get(mejora_id, [])
	if variantes.is_empty():
		return null
	return _tex(str(variantes[clampi(nivel, 1, 3) - 1]))


# --- Efectos ----------------------------------------------------------------
static var TEX_VAPOR: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Efectos/Vapor.png")
static var TEX_HUMO: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Efectos/Humo.png")
static var TEX_FUEGO: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Efectos/Fuego.png")
static var TEX_CHISPAS: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Efectos/Chispas.png")
static var TEX_MONEDAS: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Efectos/Monedas.png")
static var TEX_ESTRELLAS: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Efectos/Estrellas.png")
static var TEX_ENFADO: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Efectos/Enfado.png")
static var TEX_FRESCURA: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Efectos/Frescura.png")

# --- Personajes -------------------------------------------------------------
const RUTAS_CLIENTES: Array[String] = [
	"res://Imagenes/Minijuego_Cocina/Clientes/Cliente_01_Nino.png",
	"res://Imagenes/Minijuego_Cocina/Clientes/Cliente_02_Mujer.png",
	"res://Imagenes/Minijuego_Cocina/Clientes/Cliente_03_Mayor.png",
	"res://Imagenes/Minijuego_Cocina/Clientes/Cliente_04_Nina.png",
	"res://Imagenes/Minijuego_Cocina/Clientes/Cliente_05_Ejecutivo.png",
	"res://Imagenes/Minijuego_Cocina/Clientes/Cliente_06_Abuela.png",
	"res://Imagenes/Minijuego_Cocina/Clientes/Cliente_07_Adolescente.png",
	"res://Imagenes/Minijuego_Cocina/Clientes/Cliente_08_Nina_Pequena.png",
]

const RUTAS_CLIENTES_ENOJADOS: Array[String] = [
	"res://Imagenes/Minijuego_Cocina/Clientes/Enojados/Cliente_01_Nino_Enojado.png",
	"res://Imagenes/Minijuego_Cocina/Clientes/Enojados/Cliente_02_Mujer_Enojado.png",
	"res://Imagenes/Minijuego_Cocina/Clientes/Enojados/Cliente_03_Mayor_Enojado.png",
	"res://Imagenes/Minijuego_Cocina/Clientes/Enojados/Cliente_04_Nina_Enojado.png",
	"res://Imagenes/Minijuego_Cocina/Clientes/Enojados/Cliente_05_Ejecutivo_Enojado.png",
	"res://Imagenes/Minijuego_Cocina/Clientes/Enojados/Cliente_06_Abuela_Enojado.png",
	"res://Imagenes/Minijuego_Cocina/Clientes/Enojados/Cliente_07_Adolescente_Enojado.png",
	"res://Imagenes/Minijuego_Cocina/Clientes/Enojados/Cliente_08_Nina_Pequena_Enojado.png",
]

const RUTAS_CHEF: Dictionary = {
	"neutral": "res://Imagenes/Minijuego_Cocina/Chef/Chef_Michelle.png",
	"cruzado": "res://Imagenes/Minijuego_Cocina/Chef/Poses/Chef_Brazos_Cruzados.png",
	"celebra": "res://Imagenes/Minijuego_Cocina/Chef/Poses/Chef_Celebrando.png",
	"enfadada": "res://Imagenes/Minijuego_Cocina/Chef/Poses/Chef_Enfadada.png",
	"pulgar": "res://Imagenes/Minijuego_Cocina/Chef/Poses/Chef_Pulgar_Arriba.png",
	"sirviendo": "res://Imagenes/Minijuego_Cocina/Chef/Poses/Chef_Sirviendo.png",
	"sorprendida": "res://Imagenes/Minijuego_Cocina/Chef/Poses/Chef_Sorprendida.png",
}

const NOMBRES_INGREDIENTES: Dictionary = {
	"pan": "Pan",
	"carne": "Carne",
	"queso": "Queso",
	"lechuga": "Lechuga",
	"tomate": "Tomate",
	"patatas": "Patatas",
}

const TINTE_PLATO := Color("#f8fafc")
# Proporción del plato 3/4 del pase (640×297). Antes se usaba el plato
# cenital comprimido a 0.56 y la vajilla se leía como un óvalo plano; el
# sprite en perspectiva da profundidad real al plato y al pan.
const PLATO_PERSPECTIVA := 0.464
# Franja de corte del pan inferior que se usa para cerrar el panecillo:
# quita la cara de miga y deja solo el canto dorado inferior.
const REGION_PAN_CERRADO := Rect2(0.0, 130.0, 385.0, 96.0)


static func textura_cliente(variante: int, enojado: bool) -> Texture2D:
	var rutas: Array[String] = RUTAS_CLIENTES_ENOJADOS if enojado else RUTAS_CLIENTES
	var idx: int = posmod(variante, rutas.size())
	return _tex(rutas[idx])


static func textura_chef(pose: String) -> Texture2D:
	var ruta: String = str(RUTAS_CHEF.get(pose, RUTAS_CHEF["neutral"]))
	return _tex(ruta)


# Degradado radial negro→transparente que se estira como elipse bajo cada
# sprite para asentarlo sobre el mostrador. Se cachea porque la tarjeta se
# reconstruye cada vez que cambia el estado del minijuego.
static var _cache_sombra: GradientTexture2D = null

static func textura_sombra_contacto() -> GradientTexture2D:
	if _cache_sombra != null:
		return _cache_sombra
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	grad.colors = PackedColorArray([
		Color(0.04, 0.03, 0.02, 0.62),
		Color(0.04, 0.03, 0.02, 0.34),
		Color(0.04, 0.03, 0.02, 0.0),
	])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 128
	tex.height = 128
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 1.0)
	_cache_sombra = tex
	return tex


static func textura_item(item_id: String) -> Texture2D:
	match item_id:
		"pan":
			return TEX_PAN_SUP
		"carne":
			return TEX_CARNE_CRUDA
		"carne_lista", "carne_hecha":
			return TEX_CARNE_HECHA
		"queso":
			return TEX_QUESO
		"lechuga":
			return TEX_LECHUGA
		"tomate":
			return TEX_TOMATE
		"patatas", "patatas_listas":
			return TEX_PATATAS
		"refresco", "bebida":
			return TEX_REFRESCO
		"burger_sola", "burger_queso", "burger_completa", "burger_doble":
			return TEX_PAN_SUP
	return TEX_PLATO


# ============================================================================
# Utilidades de dibujo
# ============================================================================

static func rect_ajustado(tex: Texture2D, caja: Rect2) -> Rect2:
	if tex == null or caja.size.x <= 0.0 or caja.size.y <= 0.0:
		return caja
	var tx: float = float(tex.get_width())
	var ty: float = float(tex.get_height())
	if tx <= 0.0 or ty <= 0.0:
		return caja
	var esc: float = minf(caja.size.x / tx, caja.size.y / ty)
	var tam := Vector2(tx, ty) * esc
	return Rect2(caja.position + (caja.size - tam) * 0.5, tam)


static func dibujar_tex(c: CanvasItem, tex: Texture2D, caja: Rect2,
		modulacion: Color = Color.WHITE) -> Rect2:
	if tex == null:
		return caja
	var r := rect_ajustado(tex, caja)
	c.draw_texture_rect(tex, r, false, modulacion)
	return r


static func dibujar_tex_centro(c: CanvasItem, tex: Texture2D, centro: Vector2,
		ancho: float, alpha: float = 1.0) -> void:
	if tex == null or ancho <= 0.0:
		return
	var alto: float = ancho * float(tex.get_height()) / maxf(1.0, float(tex.get_width()))
	var r := Rect2(centro.x - ancho * 0.5, centro.y - alto * 0.5, ancho, alto)
	c.draw_texture_rect(tex, r, false, Color(1.0, 1.0, 1.0, alpha))


# Rectángulo con los píxeles visibles de una textura (sin el margen
# transparente ni el halo casi invisible que traen los PNG del pack). Se
# cachea por recurso: el cálculo recorre la imagen una sola vez por textura y
# a partir de ahí es gratis.
static var _cache_region: Dictionary = {}
const UMBRAL_ALFA_CONTENIDO: int = 24

static func region_contenido(tex: Texture2D) -> Rect2:
	if tex == null:
		return Rect2()
	var clave: String = tex.resource_path
	if clave == "":
		clave = str(tex.get_instance_id())
	if _cache_region.has(clave):
		var cacheada: Rect2 = _cache_region[clave]
		return cacheada
	var region := Rect2(Vector2.ZERO, tex.get_size())
	var img: Image = tex.get_image()
	if img != null:
		if img.is_compressed():
			img.decompress()
		img.convert(Image.FORMAT_RGBA8)
		var ancho: int = img.get_width()
		var alto: int = img.get_height()
		var datos := img.get_data()
		var min_x: int = ancho
		var min_y: int = alto
		var max_x: int = -1
		var max_y: int = -1
		# Muestreo cada 2 px: suficiente para alinear sprites y 4 veces más
		# rápido que recorrer cada píxel en GDScript. Se compensa el margen
		# al calcular el rectángulo final.
		var paso: int = 2
		for y in range(0, alto, paso):
			var fila: int = y * ancho * 4
			for x in range(0, ancho, paso):
				if datos[fila + x * 4 + 3] > UMBRAL_ALFA_CONTENIDO:
					if x < min_x:
						min_x = x
					if x > max_x:
						max_x = x
					if y < min_y:
						min_y = y
					if y > max_y:
						max_y = y
		if max_x >= min_x and max_y >= min_y:
			max_x = mini(ancho - 1, max_x + paso - 1)
			max_y = mini(alto - 1, max_y + paso - 1)
			region = Rect2(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)
	_cache_region[clave] = region
	return region


# Dibuja solo el contenido visible de la textura, estirado o encogido al
# rectángulo destino. Es la base para alinear los ingredientes entre sí: el
# margen transparente deja de influir en el tamaño y en la posición.
static func dibujar_tex_recortada(c: CanvasItem, tex: Texture2D, destino: Rect2,
		modulacion: Color = Color.WHITE) -> void:
	if tex == null:
		return
	c.draw_texture_rect_region(tex, destino, region_contenido(tex), modulacion)


# Caja de un icono de ingrediente alineado por su borde inferior: todos los
# iconos comparten línea de base y se centran horizontalmente, conservando su
# proporción y sin superar el ancho ni el alto máximos.
static func rect_icono_alineado(tex: Texture2D, centro_x: float, base_y: float,
		ancho_max: float, alto_max: float) -> Rect2:
	var region := region_contenido(tex)
	if region.size.x <= 0.0 or region.size.y <= 0.0:
		return Rect2(centro_x - ancho_max * 0.5, base_y - alto_max, ancho_max, alto_max)
	var esc: float = minf(ancho_max / region.size.x, alto_max / region.size.y)
	var tam: Vector2 = region.size * esc
	return Rect2(centro_x - tam.x * 0.5, base_y - tam.y, tam.x, tam.y)


static func puntos_elipse(centro: Vector2, radio_x: float, radio_y: float,
		segmentos: int = 40) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n: int = maxi(8, segmentos)
	for i in range(n):
		var a: float = TAU * float(i) / float(n)
		pts.append(centro + Vector2(cos(a) * radio_x, sin(a) * radio_y))
	return pts


static func caja_redondeada(c: CanvasItem, rect: Rect2, radio: float, relleno: Color,
		borde: Color = Color.TRANSPARENT, grosor: float = 1.5) -> void:
	if rect.size.x <= 0.5 or rect.size.y <= 0.5:
		return
	var pts := _puntos_redondeados(rect, radio)
	c.draw_colored_polygon(pts, relleno)
	if borde.a > 0.01 and grosor > 0.0:
		var cerrado := PackedVector2Array(pts)
		cerrado.append(pts[0])
		c.draw_polyline(cerrado, borde, grosor, true)


static func _puntos_redondeados(rect: Rect2, radio: float) -> PackedVector2Array:
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
		for s in range(5):
			var a: float = lerpf(a0, a1, float(s) / 4.0)
			pts.append(cen + Vector2(cos(a), sin(a)) * rad)
	return pts


static func dibujar_anillo(c: CanvasItem, centro: Vector2, radio: float,
		valor: float, color: Color, fondo: Color = Color("#0f172a")) -> void:
	c.draw_circle(centro, radio + 2.0, Color(0.04, 0.08, 0.12, 0.82))
	c.draw_arc(centro, radio, 0.0, TAU, 22, Color(0.35, 0.41, 0.5, 0.9), 3.2, true)
	var v: float = clampf(valor, 0.0, 1.0)
	if v > 0.01:
		c.draw_arc(centro, radio, -PI * 0.5, -PI * 0.5 + TAU * v, 22, color, 3.2, true)


static func dibujar_barra(c: CanvasItem, rect: Rect2, valor: float, color: Color,
		fondo: Color = Color(0.06, 0.09, 0.15, 0.55)) -> void:
	if rect.size.x <= 1.0 or rect.size.y <= 1.0:
		return
	caja_redondeada(c, rect, rect.size.y * 0.5, fondo)
	var v: float = clampf(valor, 0.0, 1.0)
	if v > 0.001:
		var ancho: float = maxf(6.0, (rect.size.x - 2.0) * v)
		caja_redondeada(c, Rect2(rect.position + Vector2(1.0, 1.0), Vector2(ancho, rect.size.y - 2.0)),
			(rect.size.y - 2.0) * 0.5, color)


# ============================================================================
# Composición de hamburguesas por capas con los PNG de ingredientes
# ============================================================================
#
# Cada capa se define en unidades sobre un ancho base de 120: ancho y alto
# propios (los ingredientes son fotos en perspectiva y, sin normalizar, la
# pila quedaba demasiado alta y con los bordes desalineados) y la distancia
# de su borde inferior respecto a la base del montaje. Así el pan inferior,
# las carnes, el queso, la lechuga, el tomate y el pan superior comparten
# siempre el mismo eje vertical y se solapan con una cadencia constante.

static func _capas_hamburguesa(carnes: int, queso: bool,
		lechuga: bool, tomate: bool) -> Array[Dictionary]:
	var capas: Array[Dictionary] = []
	capas.append({"tex": TEX_PAN_INF, "ancho": 112.0, "alto": 32.0, "abajo": 0.0})

	var carnes_ok: int = maxi(0, carnes)
	var cima_vis: float = 20.0
	for i in range(carnes_ok):
		var abajo: float = 13.0 + 17.0 * float(i)
		capas.append({"tex": TEX_CARNE_HECHA, "ancho": 114.0, "alto": 34.0, "abajo": abajo})
		cima_vis = abajo + 22.0

	if queso:
		var abajo: float = cima_vis - 14.0
		capas.append({"tex": TEX_QUESO, "ancho": 122.0, "alto": 36.0, "abajo": abajo})
		cima_vis = abajo + 22.0
	if lechuga:
		var abajo: float = cima_vis - 13.0
		capas.append({"tex": TEX_LECHUGA, "ancho": 128.0, "alto": 30.0, "abajo": abajo})
		cima_vis = abajo + 17.0
	if tomate:
		var abajo: float = cima_vis - 11.0
		capas.append({"tex": TEX_TOMATE, "ancho": 108.0, "alto": 28.0, "abajo": abajo})
		cima_vis = abajo + 16.0

	capas.append({"tex": TEX_PAN_SUP, "ancho": 112.0, "alto": 54.0, "abajo": cima_vis - 3.0})
	return capas


static func alto_hamburguesa(ancho: float, carnes: int, queso: bool,
		lechuga: bool, tomate: bool) -> float:
	var capas := _capas_hamburguesa(carnes, queso, lechuga, tomate)
	if capas.is_empty():
		return 0.0
	var ultima: Dictionary = capas[capas.size() - 1]
	var alto_120: float = float(ultima["abajo"]) + float(ultima["alto"])
	return alto_120 * (ancho / 120.0)


static func ancho_para_alto(alto: float, carnes: int, queso: bool,
		lechuga: bool, tomate: bool) -> float:
	var alto_120 := alto_hamburguesa(120.0, carnes, queso, lechuga, tomate)
	if alto_120 <= 0.01:
		return 120.0
	return maxf(12.0, alto * 120.0 / alto_120)


static func dibujar_hamburguesa(c: CanvasItem, base: Vector2, ancho: float,
		tiene_pan: bool, carnes: int, queso: bool, lechuga: bool, tomate: bool,
		alpha: float = 1.0, escala_pop: float = 1.0) -> void:
	if not tiene_pan or ancho <= 2.0:
		return
	var u: float = ancho / 120.0
	c.draw_set_transform(base, 0.0, Vector2(escala_pop, escala_pop))
	var col := Color(1.0, 1.0, 1.0, alpha)

	# Sombra de la pila
	c.draw_circle(Vector2(0.0, -2.0 * u), 52.0 * u, Color(0.0, 0.0, 0.0, 0.10 * alpha))

	for capa in _capas_hamburguesa(carnes, queso, lechuga, tomate):
		_dibujar_capa(c, capa["tex"], float(capa["ancho"]) * u,
			-float(capa["abajo"]) * u, float(capa["alto"]) * u, col)

	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _dibujar_capa(c: CanvasItem, tex: Texture2D, ancho: float, abajo_y: float,
		alto: float, col: Color) -> void:
	var r := Rect2(-ancho * 0.5, abajo_y - alto, ancho, alto)
	dibujar_tex_recortada(c, tex, r, col)


static func dibujar_plato_hamburguesa(c: CanvasItem, centro: Vector2, ancho_plato: float,
		tiene_pan: bool, carnes: int, queso: bool, lechuga: bool, tomate: bool,
		alpha: float = 1.0, escala_pop: float = 1.0) -> void:
	if ancho_plato <= 2.0:
		return
	var alto_plato: float = ancho_plato * PLATO_PERSPECTIVA
	var r := Rect2(centro.x - ancho_plato * 0.5, centro.y - alto_plato * 0.5,
		ancho_plato, alto_plato)

	# Sombra de la base sobre el metal de la bandeja
	c.draw_set_transform(centro + Vector2(0.0, alto_plato * 0.12), 0.0,
		Vector2(1.0, 0.42))
	c.draw_circle(Vector2.ZERO, ancho_plato * 0.48, Color(0.02, 0.03, 0.05, 0.24 * alpha))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Plato de cerámica en perspectiva 3/4, con el filo celeste del pase.
	dibujar_tex_recortada(c, TEX_PLATO_PERSPECTIVA, r,
		Color(0.97, 0.99, 1.0, alpha))
	var filo := puntos_elipse(centro + Vector2(0.0, -alto_plato * 0.01),
		ancho_plato * 0.495, alto_plato * 0.495, 48)
	filo.append(filo[0])
	c.draw_polyline(filo, Color(0.40, 0.80, 0.90, 0.52 * alpha), 3.4, true)
	var filo_int := puntos_elipse(centro + Vector2(0.0, -alto_plato * 0.01),
		ancho_plato * 0.472, alto_plato * 0.472, 48)
	filo_int.append(filo_int[0])
	c.draw_polyline(filo_int, Color(0.68, 0.94, 0.99, 0.55 * alpha), 1.3, true)

	if not tiene_pan:
		return

	var ancho_burger: float = ancho_plato * (0.80 if (carnes == 0 and not queso and not lechuga and not tomate) else 0.74)
	var base := Vector2(centro.x, centro.y + alto_plato * 0.10)

	# Sombra del montaje sobre el plato
	c.draw_set_transform(base + Vector2(0.0, 3.0), 0.0, Vector2(1.0, 0.30))
	c.draw_circle(Vector2.ZERO, ancho_burger * 0.46, Color(0.10, 0.05, 0.02, 0.22 * alpha))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if carnes == 0 and not queso and not lechuga and not tomate:
		dibujar_pan_cerrado(c, base, ancho_burger, alpha, escala_pop)
	else:
		dibujar_hamburguesa(c, base, ancho_burger, true, carnes, queso, lechuga, tomate,
			alpha, escala_pop)


# Panecillo cerrado en 3/4 para el pan solo (sin carne ni toppings). El pan
# inferior del pack es una cara de miga pensada para montar hamburguesas; al
# dibujarla entera bajo la tapa, el pan parecía abierto y plano. Aquí se usa
# solo su canto dorado inferior, se tapa el corte con la tapa y se añade una
# sombra de unión, como en la referencia de panecillos sobre plato.
static func dibujar_pan_cerrado(c: CanvasItem, base: Vector2, ancho: float,
		alpha: float = 1.0, escala_pop: float = 1.0) -> void:
	if ancho <= 2.0:
		return
	ancho *= maxf(0.05, escala_pop)
	var u: float = ancho / 112.0
	var alto_sup: float = 60.0 * u
	var alto_inf: float = ancho * 0.27
	var r_inf := Rect2(base.x - ancho * 0.48, base.y - alto_inf,
		ancho * 0.96, alto_inf)

	# Sombra de contacto sobre el plato.
	c.draw_set_transform(base + Vector2(0.0, 2.0 * u), 0.0, Vector2(1.0, 0.30))
	c.draw_circle(Vector2.ZERO, ancho * 0.48, Color(0.10, 0.05, 0.02, 0.24 * alpha))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Canto inferior del pan (sin la miga del corte).
	c.draw_texture_rect_region(TEX_PAN_INF, r_inf, REGION_PAN_CERRADO,
		Color(1.0, 1.0, 1.0, alpha))

	# Sombra de la unión entre la tapa y el canto.
	c.draw_set_transform(Vector2(base.x, r_inf.position.y + alto_inf * 0.16),
		0.0, Vector2(1.0, 0.22))
	c.draw_circle(Vector2.ZERO, ancho * 0.44, Color(0.09, 0.04, 0.01, 0.22 * alpha))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Tapa del pan, encajada sobre el canto.
	var r_sup := Rect2(base.x - ancho * 0.5,
		r_inf.position.y - alto_sup + alto_inf * 0.20,
		ancho, alto_sup)
	dibujar_tex_recortada(c, TEX_PAN_SUP, r_sup, Color(1.0, 1.0, 1.0, alpha))


static func dibujar_item(c: CanvasItem, item_id: String, centro: Vector2, caja: float,
		alpha: float = 1.0, tiempo: float = 0.0) -> void:
	var col := Color(1.0, 1.0, 1.0, alpha)
	match item_id:
		"burger_sola":
			_dibujar_burger_caja(c, centro, caja, 1, false, false, false, alpha)
		"burger_queso":
			_dibujar_burger_caja(c, centro, caja, 1, true, false, false, alpha)
		"burger_completa":
			_dibujar_burger_caja(c, centro, caja, 1, true, true, true, alpha)
		"burger_doble":
			_dibujar_burger_caja(c, centro, caja, 2, true, false, false, alpha)
		"patatas", "patatas_listas":
			dibujar_tex(c, TEX_PATATAS, Rect2(centro - Vector2(caja, caja) * 0.5, Vector2(caja, caja)), col)
		"refresco", "bebida":
			dibujar_tex(c, TEX_REFRESCO, Rect2(centro - Vector2(caja * 0.52, caja * 0.5), Vector2(caja, caja)), col)
		_:
			dibujar_tex(c, textura_item(item_id), Rect2(centro - Vector2(caja, caja) * 0.5, Vector2(caja, caja)), col)


static func _dibujar_burger_caja(c: CanvasItem, centro: Vector2, caja: float,
		carnes: int, queso: bool, lechuga: bool, tomate: bool, alpha: float) -> void:
	var ancho: float = minf(ancho_para_alto(caja, carnes, queso, lechuga, tomate), caja)
	var alto: float = alto_hamburguesa(ancho, carnes, queso, lechuga, tomate)
	var base := Vector2(centro.x, centro.y + alto * 0.5)
	dibujar_hamburguesa(c, base, ancho, true, carnes, queso, lechuga, tomate, alpha)


# ============================================================================
# Retrato de cliente
# ============================================================================

class Retrato extends Control:
	var variante: int = 0
	var ratio: float = 1.0
	var tiempo: float = 0.0
	var rebote: float = 0.0
	var feliz: float = 0.0
	var caminando: float = 0.0
	var entrando: float = 1.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if size.x <= 2.0 or size.y <= 2.0:
			return
		var enojado: bool = ratio < 0.45
		var tex := Arte_Cocina.textura_cliente(variante, enojado)
		var bob: float = sin(tiempo * 2.0 + float(variante) * 1.3) * 2.2
		bob -= sin(clampf(rebote, 0.0, 1.0) * PI) * 14.0
		bob -= sin(clampf(feliz, 0.0, 1.0) * PI) * 9.0
		var balanceo: float = sin(tiempo * 0.85 + float(variante) * 1.7) * 0.012
		var desvio: float = sin(tiempo * 0.55 + float(variante) * 0.9) * 1.8
		var paso_t: float = tiempo * 13.0 + float(variante) * 0.37
		if caminando > 0.01:
			# Ciclo de paso: rebote, balanceo lateral y micro-squash
			bob -= absf(sin(paso_t)) * 5.2 * caminando
			balanceo += sin(paso_t * 0.5) * 0.045 * caminando
			desvio += sin(paso_t) * 2.4 * caminando
		var escala_paso: float = 1.0 + sin(paso_t * 2.0) * 0.012 * caminando
		if ratio < 0.22:
			desvio += sin(tiempo * 30.0) * 3.4
			balanceo += sin(tiempo * 26.0) * 0.020
		if feliz > 0.05:
			balanceo += sin(tiempo * 18.0) * 0.030 * feliz
		var esc: float = minf(size.x / maxf(1.0, float(tex.get_width())),
			size.y / maxf(1.0, float(tex.get_height())))
		var tam := Vector2(float(tex.get_width()), float(tex.get_height())) * esc
		if caminando > 0.01:
			balanceo += 0.030 * caminando
		var origen := Vector2(size.x * 0.5 + desvio, size.y + 4.0 + bob)
		draw_set_transform(origen, balanceo, Vector2(1.0, escala_paso))
		var mod := Color(1.0, 1.0, 1.0, clampf(entrando, 0.0, 1.0))
		draw_texture_rect(tex, Rect2(-tam.x * 0.5, -tam.y, tam.x, tam.y), false, mod)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

		# Pequeño "pop" de brillo al recibir comida o celebrar
		var brillo: float = maxf(rebote, feliz)
		if brillo > 0.05:
			draw_circle(Vector2(size.x * 0.5, size.y * 0.42), 34.0 * brillo,
				Color(1.0, 0.95, 0.55, 0.30 * brillo))


# ============================================================================
# Ticket de pedido (clipboard) con barra de paciencia
# ============================================================================

class Ticket extends Control:
	var items: Array = []
	var entregados: Array = []
	var ratio: float = 1.0
	var tiempo: float = 0.0
	var destacado: bool = false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if size.x <= 8.0 or size.y <= 8.0:
			return
		var bajo: bool = ratio < 0.35
		var caja := Rect2(0.0, 0.0, size.x, size.y)
		if bajo:
			caja.position.x += sin(tiempo * 26.0) * 2.0
		# Sombra y burbuja de diálogo
		var tex := Arte_Cocina.TEX_BURBUJA
		var r := Arte_Cocina.rect_ajustado(tex, caja)
		if destacado:
			var pulso_ok: float = 0.5 + 0.5 * sin(tiempo * 8.0)
			draw_texture_rect(tex, r.grow(4.0), false,
				Color(0.28, 0.95, 0.55, 0.45 + 0.25 * pulso_ok))
		elif bajo:
			var pulso_urg: float = 0.5 + 0.5 * sin(tiempo * 10.0)
			draw_texture_rect(tex, r.grow(3.5), false,
				Color(1.0, 0.22, 0.22, 0.35 + 0.30 * pulso_urg))
		draw_texture_rect(tex, Rect2(r.position + Vector2(3.0, 5.0), r.size), false,
			Color(0.0, 0.0, 0.0, 0.18))
		var tinte := Color(1.0, 0.78, 0.78) if bajo else Color.WHITE
		draw_texture_rect(tex, r, false, tinte)

		# Iconos del pedido dentro del cuerpo de la burbuja
		var n: int = items.size()
		if n > 0:
			var icono: float = 48.0 if n == 1 else (38.0 if n == 2 else 31.0)
			var sep: float = 4.0
			var total: float = icono * float(n) + sep * float(n - 1)
			var x0: float = r.position.x + (r.size.x - total) * 0.5
			var cy: float = r.position.y + r.size.y * 0.37
			for i in range(n):
				var cx: float = x0 + icono * 0.5 + float(i) * (icono + sep)
				var hecho: bool = i < entregados.size() and bool(entregados[i])
				Arte_Cocina.dibujar_item(self, str(items[i]), Vector2(cx, cy), icono,
					0.38 if hecho else 1.0, tiempo)
				if hecho:
					draw_circle(Vector2(cx + icono * 0.32, cy - icono * 0.32), 8.0, Color("#16a34a"))
					draw_polyline(PackedVector2Array([
						Vector2(cx + icono * 0.32 - 4.0, cy - icono * 0.32),
						Vector2(cx + icono * 0.32 - 1.0, cy - icono * 0.32 + 3.0),
						Vector2(cx + icono * 0.32 + 4.0, cy - icono * 0.32 - 3.5),
					]), Color.WHITE, 2.2, true)

		# Barra de paciencia integrada en la parte baja de la burbuja (corazón + barra centrados)
		var ancho_barra: float = minf(94.0, r.size.x * 0.62)
		var cor_tam: float = 14.0
		var sep_bar: float = 4.0
		var total_bar: float = cor_tam + sep_bar + ancho_barra
		var x_bar_ini: float = r.position.x + (r.size.x - total_bar) * 0.5
		var y_bar: float = r.position.y + r.size.y * 0.67
		var cor_rect := Rect2(x_bar_ini, y_bar - 1.5, cor_tam, cor_tam)
		var barra := Rect2(x_bar_ini + cor_tam + sep_bar, y_bar, ancho_barra, 11.0)
		Arte_Cocina.dibujar_tex(self, Arte_Cocina.TEX_CORAZON, cor_rect)
		var col: Color = Color("#22c55e")
		if ratio < 0.25:
			col = Color("#ef4444")
		elif ratio < 0.50:
			col = Color("#f59e0b")
		Arte_Cocina.dibujar_barra(self, barra, ratio, col, Color(0.06, 0.09, 0.15, 0.62))


# ============================================================================
# Geometría del pase de emplatado
# ============================================================================

# Zona útil de la bandeja metálica del pack (Bandeja_Metal.png): deja ver el
# borde y las paredes interiores para que el pase tenga profundidad real.
static func rect_liner_emplatado(caja: Rect2) -> Rect2:
	return Rect2(caja.position + Vector2(34.0, 34.0),
		Vector2(caja.size.x - 68.0, caja.size.y - 64.0))


static func celdas_emplatado(caja: Rect2) -> Array[Rect2]:
	var liner := rect_liner_emplatado(caja)
	var interior := liner.grow(-3.0)
	var hueco: float = 5.0
	var ancho: float = (interior.size.x - hueco * 3.0) / 4.0
	var celdas: Array[Rect2] = []
	for i in range(4):
		celdas.append(Rect2(
			interior.position.x + float(i) * (ancho + hueco),
			interior.position.y, ancho, interior.size.y))
	return celdas


# ============================================================================
# Fondo del pase: mampara de cristal con marco cromado
# ============================================================================

class Fondo_Pase extends Control:
	# Mampara de protección del pase, como la de la referencia: cristal
	# translúcido con filo verde, marco de acero y reflejos diagonales.
	# Se dibuja detrás de la bandeja para dar profundidad al puesto.
	var tiempo: float = 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if size.x < 20.0 or size.y < 12.0:
			return
		var w: float = size.x
		var h: float = size.y
		var caja := Rect2(Vector2.ZERO, size)
		var barra: float = 9.0

		# Sombra suave sobre la encimera, por detrás del cristal.
		Arte_Cocina.caja_redondeada(self,
			Rect2(4.0, 2.0, w - 8.0, h), 8.0, Color(0.02, 0.04, 0.05, 0.18))

		# Cristal tintado. Deja ver el diner del fondo.
		var cristal := Rect2(barra, barra, w - barra * 2.0, h - barra * 1.4)
		Arte_Cocina.caja_redondeada(self, cristal, 5.0,
			Color(0.52, 0.82, 0.86, 0.13))
		Arte_Cocina.caja_redondeada(self, cristal.grow(-1.0), 4.5,
			Color(0.78, 0.96, 0.98, 0.05))

		# Reflejos diagonales del cristal.
		var brillo := Color(1.0, 1.0, 1.0, 0.10)
		draw_line(Vector2(cristal.position.x + 18.0, cristal.end.y - 4.0),
			Vector2(cristal.position.x + 62.0, cristal.position.y + 4.0), brillo, 3.0, true)
		draw_line(Vector2(cristal.position.x + 76.0, cristal.end.y - 4.0),
			Vector2(cristal.position.x + 120.0, cristal.position.y + 4.0),
			Color(1.0, 1.0, 1.0, 0.06), 6.0, true)

		# Filo inferior verde azulado.
		draw_line(Vector2(cristal.position.x + 4.0, cristal.end.y - 1.0),
			Vector2(cristal.end.x - 4.0, cristal.end.y - 1.0),
			Color(0.30, 0.72, 0.68, 0.60), 2.0, true)

		# Marco superior de acero con brillo.
		Arte_Cocina.caja_redondeada(self,
			Rect2(0.0, 0.0, w, barra), 4.0, Color("#5b6770"))
		Arte_Cocina.caja_redondeada(self,
			Rect2(2.0, 1.0, w - 4.0, barra * 0.45), 3.0, Color("#d7dee4"))
		draw_line(Vector2(6.0, 1.0), Vector2(w - 6.0, 1.0),
			Color(1.0, 1.0, 1.0, 0.60), 1.2, true)
		draw_line(Vector2(4.0, barra - 1.0), Vector2(w - 4.0, barra - 1.0),
			Color(0.10, 0.14, 0.17, 0.70), 1.6, true)

		# Postes laterales cromados.
		for x in [0.0, w - barra]:
			Arte_Cocina.caja_redondeada(self,
				Rect2(x, 4.0, barra, h - 4.0), 4.0, Color("#4d5861"))
			Arte_Cocina.caja_redondeada(self,
				Rect2(x + 2.0, 6.0, barra - 4.0, h - 10.0), 3.0, Color("#b7c1c8"))
			draw_line(Vector2(x + 2.5, 8.0), Vector2(x + 2.5, h - 6.0),
				Color(1.0, 1.0, 1.0, 0.55), 1.2, true)

		# Zócalo inferior de acero que apoya en la bandeja.
		Arte_Cocina.caja_redondeada(self,
			Rect2(0.0, h - barra * 0.75, w, barra * 0.75), 3.0,
			Color("#3c474f"))
		draw_line(Vector2(6.0, h - barra * 0.75 + 1.0),
			Vector2(w - 6.0, h - barra * 0.75 + 1.0),
			Color(0.92, 0.96, 0.98, 0.45), 1.4, true)

		# Luz cálida del pase cayendo sobre la bandeja.
		var pulso: float = 0.5 + 0.5 * sin(tiempo * 1.6)
		Arte_Cocina.caja_redondeada(self,
			Rect2(barra, h - barra * 0.75, w - barra * 2.0, barra * 0.6), 2.0,
			Color(1.0, 0.78, 0.36, 0.07 + 0.03 * pulso))


# ============================================================================
# Bandeja metálica de emplatado (pase de platos)
# ============================================================================

class Bandeja_Emplatado extends Control:
	var celdas: Array[Rect2] = []
	var desbloqueados: int = 4
	var tiempo: float = 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func configurar(rects: Array[Rect2], num_desbloqueados: int = 4) -> void:
		celdas = rects
		desbloqueados = clampi(num_desbloqueados, 0, celdas.size())
		queue_redraw()

	func _draw() -> void:
		if size.x < 40.0 or size.y < 30.0:
			return
		var caja := Rect2(Vector2.ZERO, size)

		# Sombra de contacto sobre la encimera.
		Arte_Cocina.caja_redondeada(self,
			Rect2(5.0, 7.0, size.x - 10.0, size.y - 2.0), 16.0,
			Color(0.02, 0.03, 0.05, 0.30))

		# Bandeja metálica 3D del pack: borde, paredes interiores y reflejos.
		Arte_Cocina.dibujar_tex_recortada(self, Arte_Cocina.TEX_BANDEJA, caja)

		# Alfombrilla interior, hundida respecto al borde metálico.
		var liner := Arte_Cocina.rect_liner_emplatado(caja)
		Arte_Cocina.caja_redondeada(self,
			Rect2(liner.position + Vector2(1.0, -2.0),
				Vector2(liner.size.x - 2.0, liner.size.y * 0.26)), 8.0,
			Color(0.04, 0.03, 0.02, 0.26))
		Arte_Cocina.caja_redondeada(self, liner, 8.0, Color("#c6b48b"))
		Arte_Cocina.caja_redondeada(self,
			Rect2(liner.position + Vector2(2.0, 1.0),
				Vector2(liner.size.x - 4.0, liner.size.y * 0.42)), 7.0,
			Color(1.0, 0.96, 0.86, 0.13))

		# Cuadrícula sutil de la alfombrilla.
		var paso: float = 18.0
		var gx: float = liner.position.x + paso
		while gx < liner.end.x - 4.0:
			draw_line(Vector2(gx, liner.position.y + 3.0),
				Vector2(gx, liner.end.y - 3.0), Color(0.35, 0.28, 0.18, 0.10), 1.0)
			gx += paso
		var gy: float = liner.position.y + paso
		while gy < liner.end.y - 4.0:
			draw_line(Vector2(liner.position.x + 3.0, gy),
				Vector2(liner.end.x - 3.0, gy), Color(0.35, 0.28, 0.18, 0.10), 1.0)
			gy += paso

		# Bisel interior: sombra arriba, luz abajo.
		draw_polyline(PackedVector2Array([
			Vector2(liner.position.x + 7.0, liner.position.y + 0.8),
			Vector2(liner.end.x - 7.0, liner.position.y + 0.8),
		]), Color(0.14, 0.10, 0.06, 0.40), 2.0, true)
		draw_polyline(PackedVector2Array([
			Vector2(liner.position.x + 7.0, liner.end.y - 0.8),
			Vector2(liner.end.x - 7.0, liner.end.y - 0.8),
		]), Color(1.0, 0.98, 0.90, 0.38), 1.8, true)

		# Luz cálida del pase sobre la mitad trasera de la alfombrilla.
		Arte_Cocina.caja_redondeada(self,
			Rect2(liner.position + Vector2(1.0, 1.0),
				Vector2(liner.size.x - 2.0, liner.size.y * 0.30)), 8.0,
			Color(1.0, 0.80, 0.42, 0.06))

		# Compartimentos. Los cerrados se muestran como rebajes metálicos
		# con candado; los abiertos quedan limpios para el plato.
		for i in range(celdas.size()):
			_dibujar_celda(celdas[i], i < desbloqueados, i)

	func _dibujar_celda(celda: Rect2, desbloqueada: bool, indice: int) -> void:
		if celda.size.x < 8.0 or celda.size.y < 8.0:
			return
		if desbloqueada:
			return
		# Rebaje metálico oscuro en la alfombrilla.
		Arte_Cocina.caja_redondeada(self, celda.grow(-1.0), 7.0, Color("#252c32"))
		Arte_Cocina.caja_redondeada(self, celda.grow(-3.0), 6.0, Color("#3d474f"))
		Arte_Cocina.caja_redondeada(self,
			Rect2(celda.position + Vector2(3.0, 3.0),
				Vector2(celda.size.x - 6.0, celda.size.y * 0.30)), 6.0,
			Color(0.02, 0.04, 0.06, 0.35))
		draw_polyline(PackedVector2Array([
			Vector2(celda.position.x + 8.0, celda.end.y - 3.0),
			Vector2(celda.end.x - 8.0, celda.end.y - 3.0),
		]), Color(0.75, 0.82, 0.88, 0.22), 1.4, true)
		_dibujar_hueco_bloqueado(celda.grow(-3.0), indice)

	func _dibujar_hueco_bloqueado(liner: Rect2, indice: int) -> void:
		# Plato fantasma apagado: deja claro que el hueco es para un plato,
		# pero todavía no se puede usar.
		var ancho_plato: float = minf(liner.size.x * 0.78, liner.size.y * 0.62)
		var alto_plato: float = ancho_plato * Arte_Cocina.PLATO_PERSPECTIVA
		var centro := liner.get_center() + Vector2(0.0, 2.0)
		Arte_Cocina.dibujar_tex_recortada(self, Arte_Cocina.TEX_PLATO_PERSPECTIVA,
			Rect2(centro - Vector2(ancho_plato, alto_plato) * 0.5,
				Vector2(ancho_plato, alto_plato)),
			Color(0.62, 0.70, 0.78, 0.24))

		var pulso: float = 0.5 + 0.5 * sin(tiempo * 3.4)
		var lock_ancho: float = minf(liner.size.x * 0.30, 30.0)
		var lock_alto: float = lock_ancho * 288.0 / 257.0
		var lock_centro := liner.get_center() + Vector2(0.0, -liner.size.y * 0.10)
		draw_circle(lock_centro, lock_ancho * 0.80,
			Color(1.0, 0.78, 0.32, 0.10 + 0.05 * pulso))
		Arte_Cocina.dibujar_tex(self, Arte_Cocina.TEX_CANDADO_CERRADO,
			Rect2(lock_centro - Vector2(lock_ancho, lock_alto) * 0.5,
				Vector2(lock_ancho, lock_alto)))

		# Pastilla con el nivel de mejora que abre el hueco.
		var texto := "Nv.%d" % clampi(indice, 2, 3)
		var ancho_pill: float = 38.0
		var pill := Rect2(liner.get_center().x - ancho_pill * 0.5,
			liner.get_center().y + liner.size.y * 0.13, ancho_pill, 15.0)
		Arte_Cocina.caja_redondeada(self, pill, 7.5,
			Color("#111827", 0.94), Color("#fbbf24", 0.72 + 0.16 * pulso), 1.0)
		draw_string(Arte_Cocina.FUENTE_TIT,
			Vector2(pill.position.x, pill.position.y + 11.5), texto,
			HORIZONTAL_ALIGNMENT_CENTER, pill.size.x, 10, Color("#fde68a"))


# ============================================================================
# Plato con hamburguesa montada
# ============================================================================

class Plato extends Control:
	var pan: bool = false
	var carnes: int = 0
	var queso: bool = false
	var lechuga: bool = false
	var tomate: bool = false
	var pedida: bool = false
	var seleccionado: bool = false
	var destacado: bool = false
	var tiempo: float = 0.0
	var pop: float = 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if size.x <= 8.0 or size.y <= 8.0:
			return
		var pop_esc: float = 1.0 + sin(clampf(pop, 0.0, 1.0) * PI) * 0.08
		var ancho_plato: float = minf(size.x * 0.96, size.y * 0.68)
		var alto_plato: float = ancho_plato * Arte_Cocina.PLATO_PERSPECTIVA
		var centro := Vector2(size.x * 0.5, size.y * 0.60)

		# Halo verde solo cuando un cliente está esperando ese plato. La
		# selección no pinta ningún marco: el plato debe verse limpio.
		if pedida:
			var pulso: float = 0.5 + 0.5 * sin(tiempo * 5.0)
			draw_set_transform(centro, 0.0, Vector2(1.0, Arte_Cocina.PLATO_PERSPECTIVA))
			draw_circle(Vector2.ZERO, ancho_plato * 0.54,
				Color(0.13, 0.77, 0.37, 0.14 + 0.10 * pulso))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

		# Plato + hamburguesa montada
		Arte_Cocina.dibujar_plato_hamburguesa(self, centro, ancho_plato,
			pan, carnes, queso, lechuga, tomate, 1.0, pop_esc)

		# Plato vacío: fantasma de pan para invitar a montar
		if not pan:
			_dibujar_plato_vacio(centro, ancho_plato)

		# Anillo verde de estado (plato pedido por un cliente)
		if pedida:
			var pts := Arte_Cocina.puntos_elipse(centro + Vector2(0.0, -1.0),
				ancho_plato * 0.50, alto_plato * 0.50, 48)
			pts.append(pts[0])
			draw_polyline(pts, Color(0.13, 0.77, 0.37, 0.92), 2.6, true)

		# Check de plato listo para servir
		if pedida:
			var pulso: float = 0.5 + 0.5 * sin(tiempo * 6.0)
			var check_c := centro + Vector2(ancho_plato * 0.48, -alto_plato * 0.42)
			draw_circle(check_c, 10.0 + pulso * 1.2, Color(0.09, 0.64, 0.29, 0.30))
			draw_circle(check_c, 8.5, Color("#16a34a"))
			draw_polyline(PackedVector2Array([
				check_c + Vector2(-4.0, 0.0), check_c + Vector2(-1.0, 3.2),
				check_c + Vector2(4.2, -3.6)
			]), Color.WHITE, 2.3, true)

	func _dibujar_plato_vacio(centro: Vector2, ancho_plato: float) -> void:
		var pulso: float = 0.5 + 0.5 * sin(tiempo * 3.2)
		var alto_plato: float = ancho_plato * Arte_Cocina.PLATO_PERSPECTIVA
		var ancho: float = ancho_plato * 0.72
		var alto: float = Arte_Cocina.alto_hamburguesa(ancho, 0, false, false, false)
		var base := centro + Vector2(0.0, alto_plato * 0.10)
		var alpha_ghost: float = 0.28 + 0.12 * pulso

		# Sombra suave bajo el pan fantasma
		draw_set_transform(base + Vector2(0.0, 2.0), 0.0, Vector2(1.0, 0.34))
		draw_circle(Vector2.ZERO, ancho * 0.42, Color(0.12, 0.16, 0.20, 0.10 + 0.05 * pulso))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

		# Pan completo en 3D (canto inferior + tapa), no solo la tapa.
		Arte_Cocina.dibujar_pan_cerrado(self, base, ancho, alpha_ghost)

		# Placa con "+" centrada en el propio pan fantasma: es la referencia
		# visual del plato y queda perfectamente alineada con el icono.
		var r_badge: float = clampf(ancho * 0.16, 7.0, 10.0)
		var badge := base + Vector2(0.0, -alto * 0.46)
		draw_circle(badge + Vector2(0.0, 1.5), r_badge + 1.0, Color(0.0, 0.0, 0.0, 0.18))
		draw_circle(badge, r_badge, Color(0.12, 0.08, 0.04, 0.72))
		draw_arc(badge, r_badge, 0.0, TAU, 24, Color("#fbbf24"), 1.6, true)
		var b: float = r_badge * 0.42
		draw_line(badge + Vector2(-b, 0.0), badge + Vector2(b, 0.0), Color("#fde68a"), 2.0, true)
		draw_line(badge + Vector2(0.0, -b), badge + Vector2(0.0, b), Color("#fde68a"), 2.0, true)


# ============================================================================
# Punto de cocción (plancha o cesta de freidora)
# ============================================================================

class Punto_Coccion extends Control:
	var tipo: String = "carne"
	var estado: String = "vacio"
	var progreso: float = 0.0
	var quemado: float = 0.0
	var tiempo: float = 0.0
	var flip: float = 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if size.x <= 4.0 or size.y <= 4.0:
			return
		var centro := size * 0.5
		if estado == "vacio":
			var rx: float = size.x * 0.30
			draw_arc(centro, rx, 0.0, TAU, 24, Color(0.30, 0.36, 0.44, 0.28), 1.6, true)
			return

		if tipo == "carne":
			var ancho: float = minf(size.x * 0.92, 62.0)
			var alpha_cruda: float = 0.0
			if estado == "cocinando":
				alpha_cruda = clampf(1.0 - progreso * 1.25, 0.0, 1.0)
			var alpha_hecha: float = 0.0
			var alpha_quemada: float = 0.0
			match estado:
				"cocinando":
					alpha_hecha = clampf(progreso * 1.25 - 0.15, 0.0, 1.0)
				"listo", "alerta":
					alpha_hecha = 1.0 - quemado
					alpha_quemada = quemado
				"quemado":
					alpha_quemada = 1.0
			var y_bob: float = sin(tiempo * 4.0 + centro.x) * 0.8
			# Voltereta al quedar listo: escala vertical 1 -> 0 -> 1
			var fase_flip: float = 1.0 - clampf(flip, 0.0, 1.0)
			var esc_y: float = absf(cos(fase_flip * PI))
			var salto_flip: float = -sin(fase_flip * PI) * 9.0
			draw_set_transform(centro + Vector2(0.0, y_bob + salto_flip), 0.0,
				Vector2(1.0, maxf(0.05, esc_y)))
			if alpha_cruda > 0.02:
				Arte_Cocina.dibujar_tex_centro(self, Arte_Cocina.TEX_CARNE_CRUDA,
					Vector2.ZERO, ancho, alpha_cruda)
			if alpha_hecha > 0.02:
				Arte_Cocina.dibujar_tex_centro(self, Arte_Cocina.TEX_CARNE_HECHA,
					Vector2.ZERO, ancho, alpha_hecha)
			if alpha_quemada > 0.02:
				Arte_Cocina.dibujar_tex_centro(self, Arte_Cocina.TEX_CARNE_QUEMADA,
					Vector2.ZERO, ancho, alpha_quemada)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

			if estado == "alerta" or estado == "quemado":
				var col_pulso := Color(1.0, 0.20, 0.15, 0.18 + 0.14 * (0.5 + 0.5 * sin(tiempo * 10.0)))
				draw_circle(centro, ancho * 0.42, col_pulso)

			# Anillo de estado
			var anillo_pos := Vector2(size.x - 10.0, 10.0)
			match estado:
				"cocinando":
					Arte_Cocina.dibujar_anillo(self, anillo_pos, 8.0, progreso, Color("#fb923c"))
				"listo":
					Arte_Cocina.dibujar_anillo(self, anillo_pos, 8.0, 1.0 - quemado, Color("#22c55e"))
				"alerta":
					Arte_Cocina.dibujar_anillo(self, anillo_pos, 8.0, 1.0 - quemado, Color("#ef4444"))
				"quemado":
					draw_circle(anillo_pos, 8.0, Color("#dc2626"))
					draw_line(anillo_pos + Vector2(-3.5, -3.5), anillo_pos + Vector2(3.5, 3.5),
						Color.WHITE, 2.0, true)
					draw_line(anillo_pos + Vector2(3.5, -3.5), anillo_pos + Vector2(-3.5, 3.5),
						Color.WHITE, 2.0, true)
		else:
			# Patatas
			var ancho_p: float = minf(size.x * 0.82, 54.0)
			var bob_p: float = sin(tiempo * 5.0) * 1.6 if estado == "cocinando" else 0.0
			bob_p -= sin((1.0 - clampf(flip, 0.0, 1.0)) * PI) * 6.0
			var alpha_p: float = 1.0
			if estado == "quemado":
				alpha_p = 0.9
			Arte_Cocina.dibujar_tex_centro(self, Arte_Cocina.TEX_PATATAS,
				centro + Vector2(0, bob_p), ancho_p, alpha_p)
			if estado == "cocinando":
				for k in range(4):
					var fase: float = fmod(tiempo * 1.1 + float(k) * 0.25, 1.0)
					var bx: float = centro.x + (float(k) - 1.5) * 7.0
					var by: float = centro.y + 12.0 - fase * 22.0
					draw_circle(Vector2(bx, by), 1.6 + 1.2 * fase,
						Color(1.0, 0.92, 0.55, 0.65 * (1.0 - fase)))
			var anillo_p := Vector2(size.x - 9.0, 9.0)
			match estado:
				"cocinando":
					Arte_Cocina.dibujar_anillo(self, anillo_p, 7.5, progreso, Color("#fb923c"))
				"listo":
					Arte_Cocina.dibujar_anillo(self, anillo_p, 7.5, 1.0 - quemado, Color("#22c55e"))
				"alerta":
					Arte_Cocina.dibujar_anillo(self, anillo_p, 7.5, 1.0 - quemado, Color("#ef4444"))
				"quemado":
					draw_circle(anillo_p, 7.5, Color("#dc2626"))
					draw_line(anillo_p + Vector2(-3.5, -3.5), anillo_p + Vector2(3.5, 3.5),
						Color.WHITE, 2.0, true)
					draw_line(anillo_p + Vector2(3.5, -3.5), anillo_p + Vector2(-3.5, 3.5),
						Color.WHITE, 2.0, true)


# ============================================================================
# Bebida con llenado animado
# ============================================================================

class Bebida extends Control:
	var estado: String = "listo"
	var progreso: float = 1.0
	var tiempo: float = 0.0
	var pop: float = 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if size.x <= 4.0 or size.y <= 4.0:
			return
		var caja := Rect2(0, 0, size.x, size.y)
		var tex := Arte_Cocina.TEX_REFRESCO
		var r := Arte_Cocina.rect_ajustado(tex, caja)
		var niv: float = clampf(progreso, 0.0, 1.0) if estado == "llenando" else 1.0

		if estado == "llenando":
			var region := Arte_Cocina.region_contenido(tex)
			var r_vis := Arte_Cocina.rect_ajustado(tex, caja)
			draw_texture_rect_region(tex, r_vis, region, Color(1, 1, 1, 0.22))
			if niv > 0.02:
				var src_h: float = region.size.y * niv
				var src := Rect2(region.position.x, region.end.y - src_h, region.size.x, src_h)
				var dst := Rect2(r_vis.position.x, r_vis.end.y - r_vis.size.y * niv,
					r_vis.size.x, r_vis.size.y * niv)
				draw_texture_rect_region(tex, dst, src, Color(1, 1, 1, 1))
			# Chorro desde la boquilla
			var chorro_x: float = r_vis.position.x + r_vis.size.x * 0.5
			draw_line(Vector2(chorro_x, r_vis.position.y - 8.0), Vector2(chorro_x, r_vis.position.y + 4.0),
				Color(0.25, 0.10, 0.03, 0.85), 3.0, true)
			for k in range(3):
				var fase: float = fmod(tiempo * 2.0 + float(k) * 0.33, 1.0)
				draw_circle(Vector2(chorro_x + sin(tiempo * 7.0 + k) * 3.0,
					r_vis.position.y + r_vis.size.y * 0.55 - fase * r_vis.size.y * 0.35),
					1.5, Color(1.0, 0.9, 0.5, 0.5 * (1.0 - fase)))
			Arte_Cocina.dibujar_barra(self,
				Rect2(2.0, size.y - 6.0, size.x - 4.0, 5.0), niv, Color("#38bdf8"))
		else:
			var esc: float = 1.0 + sin(clampf(pop, 0.0, 1.0) * PI) * 0.10
			var r_pop := Rect2(r.position + (r.size - r.size * esc) * 0.5, r.size * esc)
			draw_texture_rect(tex, r_pop, false, Color.WHITE)
			var pulso: float = 0.5 + 0.5 * sin(tiempo * 5.0)
			draw_circle(Vector2(size.x * 0.5, size.y * 0.44),
				r.size.x * (0.38 + 0.06 * pulso), Color(0.35, 0.85, 1.0, 0.10 + 0.06 * pulso))
			if pop > 0.02:
				draw_arc(Vector2(size.x * 0.5, size.y * 0.46), r.size.x * (0.45 + 0.25 * (1.0 - pop)),
					0.0, TAU, 24, Color(0.65, 0.95, 1.0, 0.55 * pop), 2.5, true)


# ============================================================================
# Depósitos de ingredientes del frontal de la encimera
# ============================================================================

# Cada ingrediente vive en un cajón abierto en la parte inferior del
# mostrador (como las cajas de una cocina real): el jugador coge la comida
# de la pila, no de un botón. Sin marcos amarillos ni etiquetas de acción.
class Puesto_Ingrediente extends Control:
	# Recipiente real de un ingrediente dentro del mueble bajo la encimera.
	# Cada puesto tiene su propia silueta (panera de madera, bandeja metálica,
	# tabla, bol, cesta...) para que la despensa se lea como cocina y no como
	# una fila de botones. La interacción la resuelve Arrastre_Cocina.
	var ingrediente: String = "pan"
	var hover: bool = false
	var tiempo: float = 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if size.x <= 8.0 or size.y <= 8.0:
			return
		var levante: float = 3.0 if hover else 0.0
		var pulso: float = 0.5 + 0.5 * sin(tiempo * 5.0)

		# Halo cálido común, siempre por detrás del recipiente.
		if hover:
			draw_set_transform(Vector2(size.x * 0.5, size.y * 0.54), 0.0, Vector2(1.0, 0.58))
			draw_circle(Vector2.ZERO, size.x * 0.48,
				Color(1.0, 0.78, 0.36, 0.07 + 0.05 * pulso))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

		var caja := Rect2(2.0, 2.0 - levante, size.x - 4.0, size.y - 26.0)
		match ingrediente:
			"pan":
				_dibujar_pan(caja, pulso)
			"carne":
				_dibujar_carne(caja)
			"queso":
				_dibujar_queso(caja)
			"lechuga":
				_dibujar_lechuga(caja)
			"tomate":
				_dibujar_tomate(caja)
			"patatas":
				_dibujar_patatas(caja, pulso)
		_dibujar_placa(pulso)

	func _sombra(centro: Vector2, radio_x: float, radio_y: float, alpha: float = 0.26) -> void:
		if radio_x <= 0.5:
			return
		draw_set_transform(centro, 0.0, Vector2(1.0, radio_y / radio_x))
		draw_circle(Vector2.ZERO, radio_x, Color(0.0, 0.0, 0.0, alpha))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	func _dibujar_pan(caja: Rect2, _pulso: float) -> void:
		# Panera de madera con dos huecos, como el compartimento de pan de la
		# referencia. Los panecillos se ven de frente y se pueden tocar.
		_sombra(Vector2(size.x * 0.5, caja.end.y - 1.0), caja.size.x * 0.46, 8.0, 0.30)
		Arte_Cocina.caja_redondeada(self, caja, 10.0, Color("#3f240f"), Color("#1f1208"), 2.0)
		Arte_Cocina.caja_redondeada(self, caja.grow(-4.0), 8.0, Color("#7c4a21"))
		draw_rect(Rect2(caja.position + Vector2(7.0, 5.0),
			Vector2(caja.size.x - 14.0, 4.0)), Color("#b9793d", 0.65))

		var interior := caja.grow(-8.0)
		var sep: float = 5.0
		var ancho_hueco: float = (interior.size.x - sep) * 0.5
		for i in range(2):
			var hueco := Rect2(interior.position.x + float(i) * (ancho_hueco + sep),
				interior.position.y + 1.0, ancho_hueco, interior.size.y - 6.0)
			Arte_Cocina.caja_redondeada(self, hueco, 5.0, Color("#2a170a"))
			draw_rect(Rect2(hueco.position + Vector2(2.0, 2.0),
				Vector2(hueco.size.x - 4.0, hueco.size.y * 0.34)), Color(0.0, 0.0, 0.0, 0.22))

			var cx: float = hueco.get_center().x
			var base_y: float = hueco.end.y - 5.0
			# Tres panecillos completos (pan inferior + pan superior) en
			# perspectiva, con el del fondo ligeramente elevado para dar
			# profundidad a la panera. Antes se dibujaban solo tapas
			# recortadas y el conjunto se leía como un relieve plano.
			_sombra(Vector2(cx, base_y + 1.5), ancho_hueco * 0.42, 5.5, 0.26)
			_sombra(Vector2(cx - 36.0, base_y + 1.0), 14.0, 3.5, 0.18)
			_sombra(Vector2(cx + 36.0, base_y + 1.0), 14.0, 3.5, 0.18)
			Arte_Cocina.dibujar_pan_cerrado(self, Vector2(cx, base_y - 8.0), 34.0, 0.88)
			Arte_Cocina.dibujar_pan_cerrado(self, Vector2(cx - 35.0, base_y), 40.0)
			Arte_Cocina.dibujar_pan_cerrado(self, Vector2(cx + 35.0, base_y), 40.0)

	func _dibujar_carne(caja: Rect2) -> void:
		# Bandeja metálica con hamburguesas crudas, como las bandejas de
		# preparación de la referencia.
		_sombra(Vector2(size.x * 0.5, caja.end.y - 1.0), caja.size.x * 0.44, 7.0, 0.28)
		var bandeja := Rect2(caja.position.x + 2.0, caja.position.y + caja.size.y * 0.30,
			caja.size.x - 4.0, caja.size.y * 0.64)
		Arte_Cocina.dibujar_tex_recortada(self, Arte_Cocina.TEX_BANDEJA, bandeja)

		var patty_w: float = minf(54.0, bandeja.size.x * 0.32)
		var patty_h: float = patty_w * 0.46
		var cx: float = bandeja.get_center().x
		var cy: float = bandeja.position.y + bandeja.size.y * 0.46
		for off in [-1.90, 0.0, 1.90]:
			var pos := Vector2(cx + float(off) * patty_w * 0.52,
				cy + absf(float(off)) * 2.0)
			_sombra(pos + Vector2(0.0, patty_h * 0.24), patty_w * 0.52, 4.0, 0.22)
			Arte_Cocina.dibujar_tex_recortada(self, Arte_Cocina.TEX_CARNE_CRUDA,
				Rect2(pos - Vector2(patty_w, patty_h) * 0.5, Vector2(patty_w, patty_h)))

	func _dibujar_queso(caja: Rect2) -> void:
		# Tabla de madera con lonchas de cheddar apiladas.
		_sombra(Vector2(size.x * 0.5, caja.end.y - 1.0), caja.size.x * 0.40, 6.0, 0.27)
		var tabla := Rect2(caja.position.x + 3.0, caja.position.y + caja.size.y * 0.30,
			caja.size.x - 6.0, caja.size.y * 0.60)
		Arte_Cocina.caja_redondeada(self, tabla, 8.0, Color("#7c4a21"), Color("#4a2a12"), 1.5)
		Arte_Cocina.caja_redondeada(self, tabla.grow(-3.0), 6.0, Color("#a86a33"))
		draw_circle(Vector2(tabla.end.x - 12.0, tabla.position.y + 11.0), 5.0, Color("#3f240f"))
		for i in range(3):
			var off := Vector2(float(i - 1) * 10.0, float(i - 1) * -3.0)
			Arte_Cocina.dibujar_tex_recortada(self, Arte_Cocina.TEX_QUESO,
				Rect2(tabla.get_center() + off - Vector2(26.0, 18.0), Vector2(52.0, 36.0)))

	func _dibujar_lechuga(caja: Rect2) -> void:
		# Bol metálico con hojas frescas.
		_sombra(Vector2(size.x * 0.5, caja.end.y - 1.0), caja.size.x * 0.38, 6.0, 0.27)
		Arte_Cocina.dibujar_tex_recortada(self, Arte_Cocina.TEX_BOL_LECHUGA,
			Rect2(caja.position.x + 1.0, caja.position.y + 1.0,
				caja.size.x - 2.0, caja.size.y - 2.0))

	func _dibujar_tomate(caja: Rect2) -> void:
		# Bandeja de acero con rodajas de tomate.
		_sombra(Vector2(size.x * 0.5, caja.end.y - 1.0), caja.size.x * 0.42, 6.0, 0.27)
		Arte_Cocina.dibujar_tex_recortada(self, Arte_Cocina.TEX_BANDEJA_TOMATE,
			Rect2(caja.position.x + 1.0, caja.position.y + 2.0,
				caja.size.x - 2.0, caja.size.y - 4.0))

	func _dibujar_patatas(caja: Rect2, _pulso: float) -> void:
		# Cesta roja con patatas cortadas en bastones asomando por el borde.
		_sombra(Vector2(size.x * 0.5, caja.end.y - 1.0), caja.size.x * 0.38, 6.0, 0.27)
		var cx: float = size.x * 0.5
		var base_y: float = caja.end.y - 1.0
		for i in range(7):
			var t: float = float(i) / 6.0
			var x: float = cx + lerpf(-30.0, 30.0, t)
			var alto: float = 36.0 + sin(t * PI) * 11.0
			var incl: float = lerpf(-0.30, 0.30, t)
			var a := Vector2(x, base_y - 18.0)
			var b := a + Vector2(sin(incl) * alto, -cos(incl) * alto)
			draw_line(a, b, Color("#b45309"), 8.0, true)
			draw_line(a, b, Color("#fde047"), 5.0, true)
			draw_line(a + Vector2(0.0, -1.0), b + Vector2(0.0, -1.0),
				Color("#fef3c7", 0.60), 1.4, true)
		var cesta := Rect2(cx - caja.size.x * 0.42, base_y - 49.0,
			caja.size.x * 0.84, 49.0)
		Arte_Cocina.dibujar_tex_recortada(self, Arte_Cocina.TEX_CESTA, cesta)

	func _dibujar_placa(pulso: float) -> void:
		# Placa pequeña grabada en el estante: nombre del ingrediente, sin
		# convertir el recipiente en un botón.
		var ancho: float = minf(size.x - 14.0, 88.0)
		var r := Rect2(size.x * 0.5 - ancho * 0.5, size.y - 22.0, ancho, 17.0)
		Arte_Cocina.caja_redondeada(self, r, 4.0, Color("#23150b", 0.95),
			Color("#c99a4a", 0.70 + 0.15 * pulso), 1.0)
		draw_rect(Rect2(r.position + Vector2(2.0, 1.5), Vector2(r.size.x - 4.0, 1.2)),
			Color(1.0, 0.90, 0.65, 0.20))
		draw_string(Arte_Cocina.FUENTE_TIT, Vector2(r.position.x, r.position.y + 12.5),
			str(Arte_Cocina.NOMBRES_INGREDIENTES.get(ingrediente, ingrediente)).to_upper(),
			HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 10,
			Color("#ffe9b0") if hover else Color("#e7d8b0"))


# ============================================================================
# Mueble bajo la encimera donde se guardan los ingredientes
# ============================================================================

class Fondo_Despensa extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		if w <= 8.0 or h <= 8.0:
			return

		# Zócalo de acero bajo el frente del mostrador.
		draw_rect(Rect2(0.0, 0.0, w, 8.0), Color("#8fa3b5"))
		draw_rect(Rect2(0.0, 0.0, w, 2.5), Color("#e2e8f0"))
		draw_rect(Rect2(0.0, 7.0, w, 1.5), Color("#334155", 0.80))

		# Frente de armario verde teal, a juego con las paredes del diner.
		draw_rect(Rect2(0.0, 8.0, w, h - 8.0), Color("#123e40"))
		draw_rect(Rect2(0.0, 8.0, w, h * 0.42), Color(0.06, 0.20, 0.21, 0.55))
		draw_rect(Rect2(0.0, 8.0, w, 4.0), Color(1.0, 0.75, 0.38, 0.10))

		# Costuras del mueble y remaches.
		for x in [318.0, 586.0, 892.0, 1122.0]:
			draw_line(Vector2(x, 13.0), Vector2(x, h - 27.0), Color("#0a2b2d", 0.75), 2.0)
			draw_line(Vector2(x + 2.0, 13.0), Vector2(x + 2.0, h - 27.0),
				Color("#2a6366", 0.35), 1.0)
		for x in [26.0, 300.0, 604.0, 880.0, 1130.0, 1254.0]:
			draw_circle(Vector2(x, 18.0), 2.2, Color("#9fb3c8", 0.75))
			draw_circle(Vector2(x, h - 32.0), 2.2, Color("#9fb3c8", 0.55))

		# Estante de madera con canto y veta.
		draw_rect(Rect2(0.0, h - 28.0, w, 28.0), Color("#4a2a12"))
		draw_rect(Rect2(0.0, h - 28.0, w, 5.0), Color("#a86a33"))
		draw_rect(Rect2(0.0, h - 23.0, w, 2.0), Color("#c98a4a", 0.50))
		draw_line(Vector2(0.0, h - 8.0), Vector2(w, h - 8.0), Color("#2b1608", 0.80), 2.0)
		for i in range(0, int(w), 96):
			draw_line(Vector2(float(i), h - 26.0), Vector2(float(i) + 54.0, h - 26.0),
				Color("#c98a4a", 0.18), 1.0)
			draw_line(Vector2(float(i) + 40.0, h - 15.0),
				Vector2(float(i) + 92.0, h - 15.0), Color("#2b1608", 0.35), 1.0)


# ============================================================================
# Foco de tutorial: resplandor suave sobre origen y destino (sin marcos)
# ============================================================================

class Tutorial_Foco extends Control:
	var focos: Array[Rect2] = []
	var tiempo: float = 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		# Solo un halo cálido pulsante: nada de cuadros ni contornos que
		# tapen la comida o los ingredientes.
		for i in range(focos.size()):
			var r: Rect2 = focos[i]
			if r.size.x <= 4.0 or r.size.y <= 4.0:
				continue
			var pulso: float = 0.55 + 0.35 * sin(tiempo * 4.2 + float(i) * 1.3)
			var centro: Vector2 = r.get_center()
			var radio: float = maxf(r.size.x, r.size.y) * 0.52
			var aplanado: float = clampf(r.size.y / maxf(1.0, r.size.x), 0.35, 1.0)
			draw_set_transform(centro, 0.0, Vector2(1.0, aplanado))
			draw_circle(Vector2.ZERO, radio * (0.70 + 0.06 * pulso),
				Color(1.0, 0.86, 0.42, 0.10 + 0.08 * pulso))
			draw_circle(Vector2.ZERO, radio * (0.46 + 0.05 * pulso),
				Color(1.0, 0.92, 0.62, 0.08 + 0.06 * pulso))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			# Dos destellos pequeños en lugar de esquinas de marco.
			var destello: float = 0.6 + 0.4 * sin(tiempo * 5.0 + float(i))
			draw_circle(r.position + Vector2(9.0, 9.0), 2.8,
				Color(1.0, 0.94, 0.70, 0.70 * destello))
			draw_circle(r.end - Vector2(9.0, 9.0), 2.4,
				Color(1.0, 0.94, 0.70, 0.60 * destello))


# ============================================================================
# Capa de partículas (vapor, humo, chispas, estrellas, enfado)
# ============================================================================

class Capa_Efectos_Aditivos extends Control:
	var particulas: Array[Dictionary] = []

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = mat

	func _draw() -> void:
		for p in particulas:
			var tex: Texture2D = p["tex"]
			var t: float = 1.0 - clampf(float(p["vida"]) / maxf(0.001, float(p["vida_max"])), 0.0, 1.0)
			var esc: float = lerpf(float(p["esc0"]), float(p["esc1"]), t)
			var alpha: float = float(p["alpha"]) * sin(clampf(t * 1.05, 0.0, 1.0) * PI)
			draw_set_transform(p["pos"], float(p["rot"]), Vector2(esc, esc))
			var w: float = float(tex.get_width())
			var h: float = float(tex.get_height())
			draw_texture_rect(tex, Rect2(-w * 0.5, -h * 0.5, w, h), false,
				Color(1.0, 1.0, 1.0, clampf(alpha, 0.0, 1.0)))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


class Capa_Efectos extends Control:
	var _particulas: Array[Dictionary] = []
	var _capa_add: Capa_Efectos_Aditivos
	const MAX_PARTICULAS: int = 240

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_process(true)
		_capa_add = Capa_Efectos_Aditivos.new()
		_capa_add.name = "Capa_Aditiva"
		_capa_add.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(_capa_add)

	func emitir(tex: Texture2D, pos: Vector2, vel: Vector2, vida: float,
			escala0: float, escala1: float, rot: float = 0.0,
			giro: float = 0.0, alpha: float = 1.0, gravedad: float = 0.0,
			aditivo: bool = false) -> void:
		if tex == null:
			return
		var lista: Array[Dictionary] = _capa_add.particulas if aditivo else _particulas
		if lista.size() >= MAX_PARTICULAS:
			lista.pop_front()
		lista.append({
			"tex": tex, "pos": pos, "vel": vel, "vida": vida, "vida_max": vida,
			"esc0": escala0, "esc1": escala1, "rot": rot, "giro": giro,
			"alpha": alpha, "grav": gravedad,
		})

	func vapor(pos: Vector2) -> void:
		emitir(Arte_Cocina.TEX_VAPOR, pos + Vector2(randf_range(-6, 6), 0),
			Vector2(randf_range(-6, 6), randf_range(-36, -22)),
			randf_range(0.7, 1.1), 0.10, 0.26, randf_range(-0.3, 0.3),
			randf_range(-0.3, 0.3), 0.28)

	func humo(pos: Vector2) -> void:
		emitir(Arte_Cocina.TEX_HUMO, pos + Vector2(randf_range(-6, 6), 0),
			Vector2(randf_range(-10, 10), randf_range(-38, -20)),
			randf_range(1.1, 1.7), 0.10, 0.30, randf_range(-0.4, 0.4),
			randf_range(-0.4, 0.4), 0.42)

	func chispas(pos: Vector2, n: int = 3) -> void:
		for _i in range(n):
			emitir(Arte_Cocina.TEX_CHISPAS, pos + Vector2(randf_range(-14, 14), randf_range(-6, 6)),
				Vector2(randf_range(-40, 40), randf_range(-70, -20)),
				randf_range(0.3, 0.6), 0.05, 0.12, randf_range(0, TAU),
				randf_range(-6, 6), 0.95, 160.0, true)

	func fuego(pos: Vector2) -> void:
		emitir(Arte_Cocina.TEX_FUEGO, pos + Vector2(randf_range(-5, 5), 0),
			Vector2(randf_range(-6, 6), randf_range(-26, -14)),
			randf_range(0.22, 0.38), 0.07, 0.15, 0.0, 0.0, 0.85, 0.0, true)

	func estrellas(pos: Vector2, n: int = 7) -> void:
		for _i in range(n):
			var ang: float = randf() * TAU
			var vel: Vector2 = Vector2(cos(ang), sin(ang)) * randf_range(40, 130) + Vector2(0, -40)
			emitir(Arte_Cocina.TEX_ESTRELLAS, pos, vel, randf_range(0.5, 0.9),
				0.09, 0.20, randf() * TAU, randf_range(-4, 4), 0.95, 180.0, true)

	func monedas(pos: Vector2, n: int = 5) -> void:
		for _i in range(n):
			emitir(Arte_Cocina.TEX_MONEDAS, pos + Vector2(randf_range(-16, 16), randf_range(-8, 8)),
				Vector2(randf_range(-55, 55), randf_range(-150, -80)),
				randf_range(0.8, 1.2), 0.08, 0.16, randf_range(-0.4, 0.4),
				randf_range(-3, 3), 1.0, 320.0)

	func enfado(pos: Vector2, n: int = 3) -> void:
		for _i in range(n):
			emitir(Arte_Cocina.TEX_ENFADO, pos + Vector2(randf_range(-20, 20), randf_range(-10, 10)),
				Vector2(randf_range(-25, 25), randf_range(-55, -25)),
				randf_range(0.5, 0.8), 0.08, 0.18, randf_range(-0.3, 0.3),
				randf_range(-2, 2), 0.9)

	func frescura(pos: Vector2) -> void:
		emitir(Arte_Cocina.TEX_FRESCURA, pos, Vector2(0, -18),
			randf_range(0.5, 0.8), 0.12, 0.24, 0.0, 0.6, 0.92)

	func limpiar() -> void:
		_particulas.clear()
		if _capa_add != null:
			_capa_add.particulas.clear()
			_capa_add.queue_redraw()
		queue_redraw()

	func _process(delta: float) -> void:
		if not _particulas.is_empty():
			_particulas = _Avanzar_Lista(_particulas, delta)
			queue_redraw()
		if _capa_add != null and not _capa_add.particulas.is_empty():
			_capa_add.particulas = _Avanzar_Lista(_capa_add.particulas, delta)
			_capa_add.queue_redraw()

	func _Avanzar_Lista(lista: Array[Dictionary], delta: float) -> Array[Dictionary]:
		var vivas: Array[Dictionary] = []
		for p in lista:
			p["vida"] = float(p["vida"]) - delta
			if float(p["vida"]) <= 0.0:
				continue
			p["vel"] = (p["vel"] as Vector2) + Vector2(0.0, float(p["grav"])) * delta
			p["pos"] = (p["pos"] as Vector2) + (p["vel"] as Vector2) * delta
			p["rot"] = float(p["rot"]) + float(p["giro"]) * delta
			vivas.append(p)
		return vivas

	func _draw() -> void:
		for p in _particulas:
			var tex: Texture2D = p["tex"]
			var t: float = 1.0 - clampf(float(p["vida"]) / maxf(0.001, float(p["vida_max"])), 0.0, 1.0)
			var esc: float = lerpf(float(p["esc0"]), float(p["esc1"]), t)
			var alpha: float = float(p["alpha"]) * sin(clampf(t * 1.05, 0.0, 1.0) * PI)
			draw_set_transform(p["pos"], float(p["rot"]), Vector2(esc, esc))
			var w: float = float(tex.get_width())
			var h: float = float(tex.get_height())
			draw_texture_rect(tex, Rect2(-w * 0.5, -h * 0.5, w, h), false,
				Color(1.0, 1.0, 1.0, clampf(alpha, 0.0, 1.0)))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
