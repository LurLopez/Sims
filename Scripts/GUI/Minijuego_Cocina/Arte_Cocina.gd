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

## Fondo propio de cada mundo. Los tres nuevos viven en Imagenes/.../Fondos.
static func fondo_restaurante(restaurante_id: String) -> Texture2D:
	var perf: Dictionary = Sistema_Cocina.Obtener_Perfil_Restaurante(restaurante_id)
	return _tex(str(perf.get("fondo", "res://Imagenes/Minijuego_Cocina/Fondo_Restaurante.png")))


static func fondo_selector_restaurante(restaurante_id: String) -> Texture2D:
	var perf: Dictionary = Sistema_Cocina.Obtener_Perfil_Restaurante(restaurante_id)
	return _tex(str(perf.get("fondo_selector", "res://Imagenes/Minijuego_Cocina/Fondo_Restaurante_Selector.png")))

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
# Bebidas y postres que ya venían en el pack y ahora usan los mundos nuevos.
static var TEX_CAFE: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Comida/Extras/Cafe.png")
static var TEX_AGUA: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Comida/Extras/Agua.png")
static var TEX_ZUMO: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Comida/Extras/Zumo_Naranja.png")
static var TEX_TARTA: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Comida/Extras/Tarta_Cereza.png")
static var TEX_HELADO: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Comida/Extras/Helado.png")
static var TEX_DONUT: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Comida/Extras/Donut.png")
static var TEX_CUPCAKE: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Comida/Extras/Cupcake.png")
static var TEX_ENSALADA: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Comida/Extras/Ensalada.png")
static var TEX_BOCADILLO: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Comida/Platos/Bocadillo_Pollo.png")
static var TEX_SALCHICHA: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Comida/Ingredientes/Salchicha_Cruda.png")
static var TEX_SALCHICHA_HECHA: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Comida/Ingredientes/Salchicha_Hecha.png")
# Estaciones del pack que usan el bistró y la alta cocina.
static var TEX_CAFETERA: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Estaciones/Cafetera.png")
static var TEX_VITRINA: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Estaciones/Vitrina_Preparacion.png")
static var TEX_CALENTADOR: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Estaciones/Calentador_Comida.png")
static var TEX_TOSTADOR: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Estaciones/Tostador_Panes.png")
static var TEX_SALSERA: Texture2D:
	get:
		return _tex("res://Imagenes/Minijuego_Cocina/Emplatado/Salsera.png")
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
# Proporción del plato 3/4 de cerámica blanca (642×364): perspectiva más
# generosa para que el hueco cóncavo del plato contraste con el pan brioche.
const PLATO_PERSPECTIVA := 0.567
# Franja de corte del pan inferior que se usa para cerrar el panecillo:
# quita la cara de miga y deja solo el canto dorado inferior redondeado.
const REGION_PAN_CERRADO := Rect2(0.0, 134.0, 386.0, 117.0)


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
		"carne", "filete_crudo":
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
		"cafe":
			return TEX_CAFE
		"agua":
			return TEX_AGUA
		"tarta_cereza":
			return TEX_TARTA
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
	capas.append({"tex": TEX_PAN_INF, "ancho": 108.0, "alto": 36.0, "abajo": 0.0})

	var carnes_ok: int = maxi(0, carnes)
	var cima_vis: float = 20.0
	for i in range(carnes_ok):
		var abajo: float = 14.0 + 17.0 * float(i)
		capas.append({"tex": TEX_CARNE_HECHA, "ancho": 112.0, "alto": 36.0, "abajo": abajo})
		cima_vis = abajo + 22.0

	if queso:
		var abajo: float = cima_vis - 14.0
		capas.append({"tex": TEX_QUESO, "ancho": 120.0, "alto": 34.0, "abajo": abajo})
		cima_vis = abajo + 20.0
	if lechuga:
		var abajo: float = cima_vis - 13.0
		capas.append({"tex": TEX_LECHUGA, "ancho": 128.0, "alto": 32.0, "abajo": abajo})
		cima_vis = abajo + 18.0
	if tomate:
		var abajo: float = cima_vis - 12.0
		capas.append({"tex": TEX_TOMATE, "ancho": 106.0, "alto": 28.0, "abajo": abajo})
		cima_vis = abajo + 15.0

	capas.append({"tex": TEX_PAN_SUP, "ancho": 108.0, "alto": 62.0, "abajo": cima_vis - 7.0})
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

	# Sombra suave de contacto bajo la hamburguesa (degradado radial, sin óvalo duro)
	var sombra_w: float = 124.0 * u
	var sombra_h: float = 40.0 * u
	c.draw_texture_rect(textura_sombra_contacto(),
		Rect2(-sombra_w * 0.5, -sombra_h * 0.52, sombra_w, sombra_h),
		false, Color(0.22, 0.10, 0.03, 0.52 * alpha))

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

	# Sombra suave difuminada del plato de cerámica sobre el papel encerado
	var sh_w: float = ancho_plato * 1.12
	var sh_h: float = alto_plato * 1.06
	c.draw_texture_rect(textura_sombra_contacto(),
		Rect2(centro.x - sh_w * 0.5 + 1.5, centro.y - sh_h * 0.5 + alto_plato * 0.14,
			sh_w, sh_h),
		false, Color(0.10, 0.08, 0.05, 0.58 * alpha))

	# Plato de cerámica blanca brillante en perspectiva 3/4 (sin aro celeste plano)
	dibujar_tex_recortada(c, TEX_PLATO_PERSPECTIVA, r, Color(1.0, 1.0, 1.0, alpha))

	if not tiene_pan:
		return

	var es_pan_solo: bool = carnes == 0 and not queso and not lechuga and not tomate
	var ancho_burger: float = ancho_plato * 0.72
	var base := Vector2(centro.x, centro.y + alto_plato * (0.21 if es_pan_solo else 0.22))

	if es_pan_solo:
		dibujar_pan_cerrado(c, base, ancho_burger, alpha, escala_pop)
	else:
		dibujar_hamburguesa(c, base, ancho_burger, true, carnes, queso, lechuga, tomate,
			alpha, escala_pop)


# Panecillo brioche cerrado en 3/4 con volumen y brillo caramelizado, apoyado
# con sombra suave en el hueco del plato de cerámica blanca.
static func dibujar_pan_cerrado(c: CanvasItem, base: Vector2, ancho: float,
		alpha: float = 1.0, escala_pop: float = 1.0) -> void:
	if ancho <= 2.0:
		return
	ancho *= maxf(0.05, escala_pop)
	var alto_inf: float = ancho * 0.28
	var alto_sup: float = ancho * 0.64
	var r_inf := Rect2(base.x - ancho * 0.46, base.y - alto_inf,
		ancho * 0.92, alto_inf)

	# Sombra de contacto suave y cálida directamente bajo la base del pan
	var sh_w: float = ancho * 1.16
	var sh_h: float = ancho * 0.36
	c.draw_texture_rect(textura_sombra_contacto(),
		Rect2(base.x - sh_w * 0.5, base.y - sh_h * 0.54, sh_w, sh_h),
		false, Color(0.24, 0.11, 0.03, 0.62 * alpha))

	# Base dorada redondeada del pan brioche (sin miga plana)
	c.draw_texture_rect_region(TEX_PAN_INF, r_inf, REGION_PAN_CERRADO,
		Color(1.0, 1.0, 1.0, alpha))

	# Sombra sutil de la hendidura entre la cúpula superior y la base
	var seam_w: float = ancho * 0.92
	var seam_h: float = ancho * 0.15
	c.draw_texture_rect(textura_sombra_contacto(),
		Rect2(base.x - seam_w * 0.5, r_inf.position.y + alto_inf * 0.20 - seam_h * 0.5,
			seam_w, seam_h),
		false, Color(0.28, 0.11, 0.02, 0.34 * alpha))

	# Cúpula superior brioche alta, redonda y brillante, encajada sobre la base
	var r_sup := Rect2(base.x - ancho * 0.5,
		r_inf.position.y - alto_sup + alto_inf * 0.44,
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
		"cafe":
			dibujar_tex(c, TEX_CAFE, Rect2(centro - Vector2(caja * 0.58, caja * 0.52), Vector2(caja * 1.16, caja * 1.04)), col)
		"agua":
			dibujar_tex(c, TEX_AGUA, Rect2(centro - Vector2(caja * 0.45, caja * 0.56), Vector2(caja * 0.90, caja * 1.12)), col)
		"sangria", "vino_tinto":
			dibujar_copa_vino(c, centro, caja, true, alpha)
		"vino_blanco":
			dibujar_copa_vino(c, centro, caja, false, alpha)
		"tarta_cereza":
			dibujar_tex(c, TEX_TARTA, Rect2(centro - Vector2(caja, caja) * 0.5, Vector2(caja, caja)), col)
		"filete_punto", "filete_patatas", "filete_completo", "solomillo_jugoso", "entrecot_hecho":
			var punto_item: String = "al_punto"
			if item_id == "solomillo_jugoso":
				punto_item = "poco_hecho"
			elif item_id == "entrecot_hecho":
				punto_item = "hecho"
			var guarnicion_item: String = "" if item_id == "filete_punto" else "patatas"
			var salsa_item: String = "salsa" if item_id in ["filete_completo", "solomillo_jugoso"] else ""
			dibujar_icono_bistro(c, centro, caja, punto_item, guarnicion_item, salsa_item, alpha)
		"fabada":
			dibujar_plato_mercado(c, centro, caja, "fabada", "", alpha)
		"pisto":
			dibujar_plato_mercado(c, centro, caja, "pisto", "", alpha)
		"pisto_huevo":
			dibujar_plato_mercado(c, centro, caja, "pisto", "huevo", alpha)
		"arroz_senyoret":
			dibujar_plato_mercado(c, centro, caja, "arroz", "", alpha)
		"solomillo_tinto":
			dibujar_icono_alta(c, centro, caja, "solomillo", "pure", alpha)
		"lubina_blanca":
			dibujar_icono_alta(c, centro, caja, "lubina", "esparragos", alpha)
		"pato_tinto":
			dibujar_icono_alta(c, centro, caja, "pato", "pure", alpha)
		_:
			if dibujar_ingrediente_icono(c, item_id, centro, caja, alpha):
				return
			dibujar_tex(c, textura_item(item_id), Rect2(centro - Vector2(caja, caja) * 0.5, Vector2(caja, caja)), col)


# ============================================================================
# Composición de los platos de los mundos 2, 3 y 4
# ============================================================================

static func dibujar_copa_vino(c: CanvasItem, centro: Vector2, caja: float,
		tinto: bool, alpha: float = 1.0) -> void:
	var ancho: float = caja * 0.52
	var alto: float = caja * 0.82
	var base := centro + Vector2(0.0, alto * 0.42)
	var col_vino := Color("#7f1d1d") if tinto else Color("#e7d8a8")
	# Pie y tallo
	c.draw_line(base, base + Vector2(0.0, -alto * 0.26), Color(0.85, 0.92, 1.0, 0.75 * alpha), 2.2, true)
	c.draw_line(base + Vector2(-ancho * 0.34, 0.0), base + Vector2(ancho * 0.34, 0.0),
		Color(0.85, 0.92, 1.0, 0.75 * alpha), 2.2, true)
	# Copa
	var copa := Rect2(centro + Vector2(-ancho * 0.5, -alto * 0.5), Vector2(ancho, alto * 0.55))
	c.draw_colored_polygon(PackedVector2Array([
		copa.position + Vector2(0.0, 0.0),
		copa.position + Vector2(copa.size.x, 0.0),
		copa.position + Vector2(copa.size.x * 0.76, copa.size.y * 0.72),
		copa.position + Vector2(copa.size.x * 0.50, copa.size.y),
		copa.position + Vector2(copa.size.x * 0.24, copa.size.y * 0.72),
	]), Color(0.80, 0.92, 1.0, 0.22 * alpha))
	c.draw_polyline(PackedVector2Array([
		copa.position + Vector2(0.0, 0.0),
		copa.position + Vector2(copa.size.x, 0.0),
		copa.position + Vector2(copa.size.x * 0.76, copa.size.y * 0.72),
		copa.position + Vector2(copa.size.x * 0.50, copa.size.y),
		copa.position + Vector2(copa.size.x * 0.24, copa.size.y * 0.72),
		copa.position + Vector2(0.0, 0.0),
	]), Color(0.86, 0.94, 1.0, 0.80 * alpha), 1.6, true)
	# Vino
	c.draw_colored_polygon(PackedVector2Array([
		copa.position + Vector2(copa.size.x * 0.06, copa.size.y * 0.34),
		copa.position + Vector2(copa.size.x * 0.94, copa.size.y * 0.34),
		copa.position + Vector2(copa.size.x * 0.76, copa.size.y * 0.72),
		copa.position + Vector2(copa.size.x * 0.50, copa.size.y * 0.92),
		copa.position + Vector2(copa.size.x * 0.24, copa.size.y * 0.72),
	]), Color(col_vino, 0.92 * alpha))
	c.draw_line(copa.position + Vector2(copa.size.x * 0.18, copa.size.y * 0.40),
		copa.position + Vector2(copa.size.x * 0.34, copa.size.y * 0.40),
		Color(1.0, 1.0, 1.0, 0.45 * alpha), 1.5, true)


static func punto_color(punto: String) -> Color:
	match punto:
		"crudo": return Color("#e0605a")
		"poco_hecho": return Color("#d97b57")
		"al_punto": return Color("#b5603a")
		"hecho": return Color("#8a4a2a")
		"quemado": return Color("#3f2418")
	return Color("#b5603a")


static func dibujar_filete(c: CanvasItem, centro: Vector2, ancho: float,
		punto: String, alpha: float = 1.0) -> void:
	# Filete con hueso en T dibujado en 3/4. La silueta, el veteado, la costra
	# y la cara de corte cambian con el punto para que se lea de un vistazo
	# tanto en la parrilla (50 px) como en el plato (90 px). Gestiona sus
	# propios `draw_set_transform`: hay que pasarle el centro absoluto del
	# control, no llamarlo dentro de otro transform.
	if ancho <= 2.0:
		return
	var u: float = ancho / 100.0
	var compacto: bool = ancho < 55.0
	var crudo: bool = punto == "crudo" or punto == ""
	var quemado: bool = punto == "quemado"
	var poco: bool = punto == "poco_hecho"
	var al_punto: bool = punto == "al_punto"
	var hecho: bool = punto == "hecho"

	# Sombra de contacto sobre la parrilla o el plato.
	c.draw_set_transform(centro + Vector2(0.0, 23.0 * u), -0.03, Vector2(1.0, 0.30))
	c.draw_circle(Vector2.ZERO, 46.0 * u, Color(0.04, 0.02, 0.01, 0.26 * alpha))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	c.draw_set_transform(centro + Vector2(0.0, -3.0 * u), -0.035, Vector2(u, u))
	var lw: float = maxf(1.1, 2.0 * u) / u

	# Hueso de la pieza: se dibuja antes de la carne para que el lomo lo tape
	# y solo asome el extremo con sus dos nudillos por el borde izquierdo.
	var hueso := Color("#ead8b4")
	var hueso_alto := Color("#fff4d8")
	var hueso_borde := Color("#6f5030")
	if quemado:
		hueso = Color("#a88f6c")
		hueso_alto = Color("#cdb893")
		hueso_borde = Color("#3f2c1a")
	var hueso_a := Vector2(-30.0, 9.0)
	var hueso_b := Vector2(-60.0, 22.0)
	c.draw_line(hueso_a + Vector2(0.8, 2.0), hueso_b + Vector2(0.8, 2.0),
		Color(0.08, 0.04, 0.02, 0.55 * alpha), maxf(5.4, 7.4 * u) / u, true)
	c.draw_circle(hueso_b + Vector2(0.8, 2.0), maxf(3.4, 4.6 * u) / u,
		Color(0.08, 0.04, 0.02, 0.55 * alpha))
	c.draw_line(hueso_a, hueso_b, Color(hueso_borde, alpha),
		maxf(5.8, 7.6 * u) / u, true)
	c.draw_circle(hueso_b, maxf(3.4, 4.6 * u) / u, Color(hueso_borde, alpha))
	c.draw_line(hueso_a, hueso_b, Color(hueso, alpha),
		maxf(4.0, 5.4 * u) / u, true)
	c.draw_circle(hueso_b, maxf(2.6, 3.4 * u) / u, Color(hueso, alpha))
	# Nudillos del extremo.
	c.draw_circle(hueso_b + Vector2(1.0, -5.0), maxf(3.2, 4.4 * u) / u,
		Color(hueso_borde, alpha))
	c.draw_circle(hueso_b + Vector2(1.0, -5.0), maxf(2.2, 3.1 * u) / u,
		Color(hueso, alpha))
	c.draw_circle(hueso_b + Vector2(-1.0, 5.0), maxf(2.9, 4.0 * u) / u,
		Color(hueso_borde, alpha))
	c.draw_circle(hueso_b + Vector2(-1.0, 5.0), maxf(2.0, 2.8 * u) / u,
		Color(hueso, alpha))
	c.draw_line(hueso_a + Vector2(0.0, -0.8), hueso_b + Vector2(0.0, -0.8),
		Color(hueso_alto, 0.75 * alpha), maxf(1.0, 1.3 * u) / u, true)

	# Paleta según el punto.
	var costra := Color("#2a1209")
	var grasa := Color("#e8c79a")
	var carne := Color("#8f3f24")
	var carne_alta := Color("#b75a37")
	var centro_rosa := Color("#d45a51")
	if crudo:
		costra = Color("#a84446")
		grasa = Color("#f2c9bf")
		carne = Color("#cf5c5e")
		carne_alta = Color("#e88683")
		centro_rosa = Color("#f5aaa4")
	elif poco:
		costra = Color("#3b180c")
		grasa = Color("#eccb9d")
		carne = Color("#a84a30")
		carne_alta = Color("#cd6b46")
		centro_rosa = Color("#e8786d")
	elif al_punto:
		costra = Color("#30150a")
		grasa = Color("#e4bf8f")
		carne = Color("#943f24")
		carne_alta = Color("#b95835")
		centro_rosa = Color("#d25a50")
	elif hecho:
		costra = Color("#2a130a")
		grasa = Color("#d8b07b")
		carne = Color("#7b3a1f")
		carne_alta = Color("#9c4e31")
		centro_rosa = Color("#8c4328")
	elif quemado:
		costra = Color("#0c0705")
		grasa = Color("#6b5238")
		carne = Color("#24160e")
		carne_alta = Color("#3a2317")
		centro_rosa = Color("#3d2618")

	# Silueta de lomo ancho, con el borde ligeramente irregular.
	var pts := PackedVector2Array([
		Vector2(-50.0, -6.0), Vector2(-48.0, -20.0), Vector2(-40.0, -30.0),
		Vector2(-28.0, -34.0), Vector2(-16.0, -33.0), Vector2(-5.0, -31.0),
		Vector2(6.0, -33.0), Vector2(18.0, -34.0), Vector2(30.0, -30.0),
		Vector2(41.0, -23.0), Vector2(48.0, -13.0), Vector2(50.0, -2.0),
		Vector2(47.0, 10.0), Vector2(39.0, 18.0), Vector2(29.0, 23.0),
		Vector2(17.0, 26.0), Vector2(5.0, 23.0), Vector2(-6.0, 25.0),
		Vector2(-18.0, 26.0), Vector2(-30.0, 24.0), Vector2(-41.0, 19.0),
		Vector2(-48.0, 11.0),
	])
	# Contorno oscuro: separa la pieza del plato y le da volumen de cartoon.
	c.draw_colored_polygon(pts, Color(costra, alpha))
	# Filo de grasa.
	var pts_grasa := PackedVector2Array()
	for p in pts:
		pts_grasa.append(p * 0.965 + Vector2(0.0, 0.6))
	c.draw_colored_polygon(pts_grasa, Color(grasa, alpha))
	# Carne con degradado vertical suave.
	var interior := PackedVector2Array()
	for p in pts_grasa:
		interior.append(p * 0.925 + Vector2(0.0, 0.8))
	var cols := PackedColorArray()
	for p in interior:
		var t: float = clampf((p.y + 36.0) / 64.0, 0.0, 1.0)
		cols.append(Color(carne_alta.lerp(carne, t), alpha))
	c.draw_polygon(interior, cols)

	# Centro jugoso: el punto se lee por el color del corazón de la pieza.
	if not hecho and not quemado:
		var alpha_core: float = 0.30 if crudo else (0.36 if poco else 0.22)
		var rx_core: float = 19.0 if crudo else (18.0 if poco else 15.0)
		var ry_core: float = 8.0 if crudo else (8.0 if poco else 6.5)
		c.draw_colored_polygon(puntos_elipse(Vector2(-10.0, -2.0), rx_core, ry_core, 24),
			Color(centro_rosa, alpha_core * alpha))
		c.draw_colored_polygon(puntos_elipse(Vector2(-13.0, -3.0), rx_core * 0.58,
			ry_core * 0.55, 20), Color(centro_rosa.lightened(0.22), alpha_core * 0.55 * alpha))

	# Veteado de grasa: el crudo y el poco hecho lucen más veta.
	if crudo or poco:
		var vetas: Array[PackedVector2Array] = [
			PackedVector2Array([Vector2(-40.0, -15.0), Vector2(-31.0, -19.0),
				Vector2(-23.0, -15.0), Vector2(-17.0, -18.0)]),
			PackedVector2Array([Vector2(-36.0, 0.0), Vector2(-27.0, -4.0),
				Vector2(-19.0, 0.0), Vector2(-12.0, -3.0)]),
			PackedVector2Array([Vector2(-29.0, 14.0), Vector2(-20.0, 10.0),
				Vector2(-12.0, 14.0), Vector2(-5.0, 11.0)]),
			PackedVector2Array([Vector2(11.0, -23.0), Vector2(20.0, -26.0),
				Vector2(28.0, -22.0), Vector2(36.0, -25.0)]),
			PackedVector2Array([Vector2(15.0, 4.0), Vector2(24.0, 1.0),
				Vector2(33.0, 5.0), Vector2(40.0, 2.0)]),
		]
		var limite_vetas: int = 2 if compacto else vetas.size()
		for i_veta in range(limite_vetas):
			c.draw_polyline(vetas[i_veta], Color(1.0, 0.91, 0.82, 0.42 * alpha),
				maxf(1.0, 1.7 * u) / u, true)

	# Marcas de parrilla diagonales. En crudo aún no hay costra.
	if not crudo:
		var marcas: Array[PackedVector2Array] = [
			PackedVector2Array([Vector2(-42.0, -19.0), Vector2(-28.0, -29.0)]),
			PackedVector2Array([Vector2(-38.0, -4.0), Vector2(-22.0, -17.0)]),
			PackedVector2Array([Vector2(-33.0, 11.0), Vector2(-16.0, -3.0)]),
			PackedVector2Array([Vector2(8.0, -27.0), Vector2(24.0, -14.0)]),
			PackedVector2Array([Vector2(13.0, -9.0), Vector2(32.0, 6.0)]),
			PackedVector2Array([Vector2(18.0, 9.0), Vector2(37.0, 23.0)]),
		]
		var col_marca: Color = Color(0.10, 0.04, 0.02, 0.58 * alpha)
		if quemado:
			col_marca = Color(0.01, 0.01, 0.01, 0.86 * alpha)
		var limite_marcas: int = 4 if compacto else marcas.size()
		for i_marca in range(limite_marcas):
			var marca: PackedVector2Array = marcas[i_marca]
			c.draw_line(marca[0], marca[1], col_marca, maxf(1.6, 4.0 * u) / u, true)
			if not compacto:
				c.draw_line(marca[0] + Vector2(0.9, -0.7), marca[1] + Vector2(0.9, -0.7),
					Color(carne_alta, 0.30 * alpha), maxf(0.8, 1.3 * u) / u, true)
		# Grietas de la costra en el punto hecho y en el quemado.
		if (hecho or quemado) and not compacto:
			for grieta in [
				PackedVector2Array([Vector2(-31.0, 10.0), Vector2(-25.0, 17.0)]),
				PackedVector2Array([Vector2(26.0, 9.0), Vector2(32.0, 16.0)]),
			]:
				c.draw_line(grieta[0], grieta[1], Color(0.04, 0.02, 0.01, 0.65 * alpha), lw, true)

	# Veta del hueso bajo la superficie: une el extremo visible con el centro
	# de la pieza y refuerza la lectura de chuletón.
	var veta_hueso := PackedVector2Array([
		Vector2(-31.0, 9.0), Vector2(-24.0, 6.0), Vector2(-17.0, 4.0),
		Vector2(-10.0, 2.0), Vector2(-4.0, -1.0),
	])
	c.draw_polyline(veta_hueso, Color(costra.darkened(0.15), 0.55 * alpha),
		maxf(1.8, 3.2 * u) / u, true)
	c.draw_polyline(veta_hueso, Color(grasa, 0.45 * alpha),
		maxf(0.9, 1.5 * u) / u, true)

	# Canto inferior grueso: da volumen de pieza de carne y separa la costra
	# de la sombra. En los puntos jugosos se insinúa el centro rosado.
	var canto := PackedVector2Array([
		Vector2(-46.0, 10.0), Vector2(-40.0, 17.0), Vector2(-30.0, 22.0),
		Vector2(-18.0, 24.0), Vector2(-6.0, 23.0), Vector2(5.0, 21.0),
		Vector2(17.0, 24.0), Vector2(29.0, 21.0), Vector2(39.0, 16.0),
		Vector2(46.0, 8.0),
	])
	c.draw_polyline(canto, Color(costra.darkened(0.15), alpha),
		maxf(2.2, 4.6 * u) / u, true)
	if not hecho and not quemado:
		var linea_punto := PackedVector2Array()
		for p in canto:
			linea_punto.append(p + Vector2(0.0, -2.1))
		c.draw_polyline(linea_punto, Color(centro_rosa, 0.55 * alpha),
			maxf(0.9, 1.5 * u) / u, true)

	# Brillos de jugo y pimienta.
	if not quemado:
		c.draw_set_transform(Vector2(-16.0, -17.0), -0.3, Vector2(1.0, 0.38))
		c.draw_circle(Vector2.ZERO, 8.5, Color(1.0, 0.93, 0.84, 0.26 * alpha))
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		c.draw_circle(Vector2(-24.0, -19.0), 1.8, Color(1.0, 0.97, 0.90, 0.38 * alpha))
		if not compacto:
			c.draw_circle(Vector2(22.0, 13.0), 1.3, Color(0.10, 0.06, 0.03, 0.7 * alpha))
			c.draw_circle(Vector2(-8.0, 14.0), 1.0, Color(0.10, 0.06, 0.03, 0.6 * alpha))
			c.draw_circle(Vector2(20.0, -8.0), 0.9, Color(0.10, 0.06, 0.03, 0.55 * alpha))

	# Romero: solo cuando el filete ya está cocinado y hay tamaño suficiente
	# para que la rama no se convierta en una mancha verde.
	if not crudo and not quemado and ancho >= 55.0:
		var tallo_a := Vector2(22.0, -35.0)
		var tallo_b := Vector2(40.0, -29.0)
		c.draw_line(tallo_a, tallo_b, Color("#3f6212", alpha),
			maxf(1.0, 1.8 * u) / u, true)
		for k in range(4):
			var t: float = float(k) / 3.0
			var base := tallo_a.lerp(tallo_b, t)
			c.draw_line(base, base + Vector2(-3.0, -4.0), Color("#65a30d", alpha),
				maxf(0.8, 1.3 * u) / u, true)
			c.draw_line(base, base + Vector2(3.0, -3.0), Color("#4d7c0f", alpha),
				maxf(0.8, 1.3 * u) / u, true)

	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

static func dibujar_plato_bistro(c: CanvasItem, centro: Vector2, ancho_plato: float,
		proteina: String, punto: String, guarnicion: String, salsa: String,
		alpha: float = 1.0) -> void:
	if ancho_plato <= 2.0:
		return
	var alto_plato: float = ancho_plato * PLATO_PERSPECTIVA
	var c_plato := centro + Vector2(0.0, alto_plato * 0.04)
	var r := Rect2(c_plato - Vector2(ancho_plato, alto_plato) * 0.5,
		Vector2(ancho_plato, alto_plato))

	# Sombra suave de contacto sobre el papel/bandeja metálica.
	var sh_w: float = ancho_plato * 1.10
	var sh_h: float = alto_plato * 1.02
	c.draw_texture_rect(textura_sombra_contacto(),
		Rect2(c_plato.x - sh_w * 0.5 + 1.0, c_plato.y - sh_h * 0.5 + alto_plato * 0.14,
			sh_w, sh_h),
		false, Color(0.08, 0.06, 0.04, 0.52 * alpha))

	# Plato de cerámica blanca 3/4.
	dibujar_tex_recortada(c, TEX_PLATO_PERSPECTIVA, r, Color(1.0, 0.99, 0.97, alpha))

	if proteina == "":
		return

	# Salsa: media luna brillante bajo la carne, no un círculo plano.
	if salsa != "":
		var salsa_c := c_plato + Vector2(-ancho_plato * 0.10, alto_plato * 0.08)
		c.draw_set_transform(salsa_c, 0.0, Vector2(1.0, 0.34))
		c.draw_circle(Vector2.ZERO, ancho_plato * 0.245, Color("#6b2410", 0.92 * alpha))
		c.draw_circle(Vector2(-ancho_plato * 0.035, -ancho_plato * 0.018),
			ancho_plato * 0.185, Color("#8f3416", 0.88 * alpha))
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		c.draw_set_transform(salsa_c + Vector2(-ancho_plato * 0.07, -alto_plato * 0.02),
			0.0, Vector2(1.0, 0.30))
		c.draw_circle(Vector2.ZERO, ancho_plato * 0.075,
			Color(1.0, 0.78, 0.62, 0.30 * alpha))
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Patatas: abanico dorado a la derecha del plato, apoyado en el borde.
	if guarnicion == "patatas":
		var origen_p := c_plato + Vector2(ancho_plato * 0.20, alto_plato * 0.06)
		for i in range(6):
			var t: float = float(i) / 5.0
			var ang: float = lerpf(-0.62, 0.52, t)
			var largo: float = ancho_plato * lerpf(0.14, 0.19, sin(t * PI))
			var p := origen_p + Vector2(float(i - 2.5) * ancho_plato * 0.030,
				-t * alto_plato * 0.04)
			var extremo := p + Vector2(sin(ang) * largo, -cos(ang) * largo)
			c.draw_line(p + Vector2(1.0, 2.0), extremo + Vector2(1.0, 2.0),
				Color(0.28, 0.14, 0.02, 0.30 * alpha),
				maxf(2.0, ancho_plato * 0.050), true)
			c.draw_line(p, extremo, Color("#f5b82e", alpha),
				maxf(1.6, ancho_plato * 0.045), true)
			c.draw_line(p + Vector2(-ancho_plato * 0.006, 0.0),
				extremo + Vector2(-ancho_plato * 0.006, 0.0),
				Color("#fde68a", 0.65 * alpha), maxf(0.8, ancho_plato * 0.014), true)

	# Filete: ocupa el centro del plato y deja sitio a la guarnición.
	var tiene_patatas: bool = guarnicion == "patatas"
	var ancho_filete: float = ancho_plato * (0.57 if not tiene_patatas else 0.51)
	var c_filete := c_plato + Vector2(-ancho_plato * (0.085 if tiene_patatas else 0.015),
		-ancho_plato * 0.035)
	dibujar_filete(c, c_filete, ancho_filete, punto, alpha)

	# Perejil fresco sobre el borde superior del plato.
	var perejil_a := c_plato + Vector2(ancho_plato * 0.04, -alto_plato * 0.26)
	var perejil_b := c_plato + Vector2(ancho_plato * 0.17, -alto_plato * 0.34)
	c.draw_line(perejil_a, perejil_b, Color("#3f6212", 0.95 * alpha),
		maxf(1.0, ancho_plato * 0.014), true)
	for k in range(3):
		var t: float = 0.25 + 0.30 * float(k)
		var base_h := perejil_a.lerp(perejil_b, t)
		c.draw_line(base_h, base_h + Vector2(-ancho_plato * 0.035, -alto_plato * 0.10),
			Color("#4d7c0f", alpha), maxf(0.8, ancho_plato * 0.012), true)
		c.draw_line(base_h, base_h + Vector2(ancho_plato * 0.030, -alto_plato * 0.08),
			Color("#65a30d", alpha), maxf(0.8, ancho_plato * 0.012), true)

	# Pimienta recién molida junto a la carne.
	for i in range(3):
		c.draw_circle(c_plato + Vector2(ancho_plato * (0.02 + 0.035 * float(i)),
			-alto_plato * 0.10 + alto_plato * 0.022 * float(i)),
			maxf(0.8, ancho_plato * 0.008), Color(0.12, 0.07, 0.04, 0.55 * alpha))


static func dibujar_icono_bistro(c: CanvasItem, centro: Vector2, caja: float,
		punto: String, guarnicion: String, salsa: String, alpha: float = 1.0) -> void:
	# Icono de ticket: plato 3/4 del pack con el filete encima. Se mantiene
	# legible a 30-48 px sin depender de detalles que desaparezcan.
	if caja <= 2.0:
		return
	var alto_plato: float = caja * PLATO_PERSPECTIVA
	var c_plato := centro + Vector2(0.0, caja * 0.10)
	var r := Rect2(c_plato - Vector2(caja * 0.98, alto_plato) * 0.5,
		Vector2(caja * 0.98, alto_plato))
	dibujar_tex_recortada(c, TEX_PLATO_PERSPECTIVA, r, Color(1.0, 0.99, 0.97, alpha))

	if salsa != "":
		c.draw_set_transform(c_plato + Vector2(-caja * 0.08, alto_plato * 0.20),
			0.0, Vector2(1.0, 0.34))
		c.draw_circle(Vector2.ZERO, caja * 0.24, Color("#6b2410", 0.90 * alpha))
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	dibujar_filete(c, centro + Vector2(-caja * 0.07, -caja * 0.02),
		caja * 0.52, punto, alpha)

	if guarnicion == "patatas":
		for i in range(6):
			var t: float = float(i) / 5.0
			var p := c_plato + Vector2(caja * 0.22 + t * caja * 0.12,
				caja * 0.02 - sin(t * PI) * caja * 0.07)
			c.draw_line(p + Vector2(-caja * 0.025, caja * 0.05),
				p + Vector2(caja * 0.020, -caja * 0.05),
				Color("#fbbf24", alpha), maxf(1.2, caja * 0.042), true)
	# Perejil mínimo.
	c.draw_line(centro + Vector2(-caja * 0.16, -caja * 0.22),
		centro + Vector2(-caja * 0.26, -caja * 0.30),
		Color("#15803d", 0.90 * alpha), maxf(1.0, caja * 0.022), true)


# ============================================================================
# Ilustraciones procedurales de las mejoras del Bistró
# ============================================================================
# El pack original de mejoras está dibujado para Burger Street (plancha de
# hamburguesas, bandeja de burgers y refrescos). El Bistró necesita su propio
# relato visual: parrilla de filetes, pase con platos y café, dial del punto,
# género de carne y comedor con mantel. Se dibuja por código para que escale
# igual en la tarjeta grande y en el icono de 48 px.

static func dibujar_mejora_bistro(c: CanvasItem, centro: Vector2, ancho: float,
		mejora_id: String, nivel: int) -> void:
	if ancho <= 8.0:
		return
	var compacto: bool = ancho < 110.0
	# Halo cálido de candilejas, común a todas las mejoras del local.
	c.draw_set_transform(centro, 0.0, Vector2(1.0, 0.56))
	for i in range(5, 0, -1):
		c.draw_circle(Vector2.ZERO, ancho * (0.15 + 0.065 * float(i)),
			Color(1.0, 0.66, 0.28, 0.020))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	match mejora_id:
		"plancha":
			_bistro_mejora_plancha(c, centro, ancho, nivel, compacto)
		"emplatado":
			_bistro_mejora_emplatado(c, centro, ancho, nivel, compacto)
		"termostato":
			_bistro_mejora_termostato(c, centro, ancho, nivel, compacto)
		"ingredientes":
			_bistro_mejora_ingredientes(c, centro, ancho, nivel, compacto)
		"ambiente":
			_bistro_mejora_ambiente(c, centro, ancho, nivel, compacto)
		_:
			pass


static func _bistro_mejora_plancha(c: CanvasItem, centro: Vector2, ancho: float,
		nivel: int, compacto: bool) -> void:
	# Mostrador de acero.
	var mostrador := Rect2(centro.x - ancho * 0.47, centro.y + ancho * 0.26,
		ancho * 0.94, ancho * 0.16)
	caja_redondeada(c, mostrador, ancho * 0.045, Color("#2a3038"),
		Color("#59626c"), maxf(1.0, ancho * 0.008))
	c.draw_line(Vector2(mostrador.position.x + ancho * 0.04, mostrador.position.y + 1.0),
		Vector2(mostrador.end.x - ancho * 0.04, mostrador.position.y + 1.0),
		Color(0.94, 0.97, 1.0, 0.30), maxf(1.0, ancho * 0.006), true)

	if compacto:
		var r := Rect2(centro.x - ancho * 0.44, centro.y - ancho * 0.20,
			ancho * 0.88, ancho * 0.54)
		caja_redondeada(c, r, ancho * 0.08, Color("#161a1f"), Color("#424b55"), 1.5)
		for i in range(4):
			var x: float = r.position.x + r.size.x * (0.22 + 0.19 * float(i))
			c.draw_line(Vector2(x, r.position.y + r.size.y * 0.20),
				Vector2(x + r.size.x * 0.06, r.end.y - r.size.y * 0.16),
				Color(0.06, 0.07, 0.08, 0.55), maxf(1.0, ancho * 0.025), true)
		dibujar_filete(c, centro + Vector2(-ancho * 0.06, -ancho * 0.03),
			ancho * 0.46, "al_punto")
		# Cesta de patatas mínima a la derecha.
		var cesta := Rect2(centro.x + ancho * 0.20, centro.y + ancho * 0.06,
			ancho * 0.20, ancho * 0.14)
		caja_redondeada(c, cesta, ancho * 0.03, Color("#8b1d1d"), Color("#e7b06a"), 1.2)
		for i in range(3):
			c.draw_line(Vector2(cesta.position.x + cesta.size.x * 0.22 + float(i) * cesta.size.x * 0.24,
				cesta.position.y - ancho * 0.005),
				Vector2(cesta.position.x + cesta.size.x * 0.28 + float(i) * cesta.size.x * 0.24,
					cesta.position.y - ancho * 0.075), Color("#fbbf24"), maxf(1.2, ancho * 0.025), true)
		return

	# Parrilla 3/4 del pack, escorzada sobre el mostrador.
	var w: float = ancho * 0.64
	var h: float = w * 0.748
	var r := Rect2(centro.x - ancho * 0.15 - w * 0.5, centro.y - ancho * 0.12 - h * 0.5,
		w, h)
	dibujar_tex_recortada(c, TEX_PLANCHA, r)
	# Filetes sobre los fogones visibles (coordenadas normalizadas del PNG).
	var fogones: Array[Vector2] = [
		Vector2(0.40, 0.26), Vector2(0.72, 0.28),
		Vector2(0.32, 0.45), Vector2(0.68, 0.47),
	]
	var cuantos: int = clampi(nivel + 1, 2, 4)
	for i in range(cuantos):
		var p := r.position + Vector2(fogones[i].x * r.size.x, fogones[i].y * r.size.y)
		dibujar_filete(c, p, ancho * 0.155, "al_punto")
	# Freidora al margen derecho: una cesta o dos.
	var bw: float = ancho * 0.23
	var bh: float = bw * 0.952
	var br := Rect2(centro.x + ancho * 0.20, centro.y + ancho * 0.02, bw, bh)
	dibujar_tex_recortada(c, TEX_FREIDORA, br)
	var patatas_n: int = 1 if nivel <= 1 else 2
	for i in range(patatas_n):
		var px: float = br.position.x + br.size.x * (0.29 + 0.43 * float(i))
		var py: float = br.position.y + br.size.y * 0.50
		c.draw_circle(Vector2(px, py), bw * 0.14, Color("#fbbf24", 0.90))
		c.draw_line(Vector2(px - bw * 0.06, py - bw * 0.02),
			Vector2(px + bw * 0.04, py - bw * 0.14), Color("#fde68a", 0.80),
			maxf(1.0, ancho * 0.008), true)
	# Calor y chispas del nivel máximo.
	if nivel >= 3:
		for i in range(3):
			var fx: float = r.position.x + r.size.x * (0.28 + 0.20 * float(i))
			var fy: float = r.position.y + r.size.y * 0.68
			c.draw_colored_polygon(PackedVector2Array([
				Vector2(fx - ancho * 0.018, fy + ancho * 0.05),
				Vector2(fx, fy - ancho * 0.04),
				Vector2(fx + ancho * 0.018, fy + ancho * 0.05),
			]), Color(1.0, 0.55, 0.12, 0.85))


static func _bistro_mejora_emplatado(c: CanvasItem, centro: Vector2, ancho: float,
		nivel: int, compacto: bool) -> void:
	# Mampara de cristal del pase.
	var cristal := Rect2(centro.x - ancho * 0.45, centro.y - ancho * 0.28,
		ancho * 0.90, ancho * 0.20)
	caja_redondeada(c, cristal, ancho * 0.015, Color(0.55, 0.85, 0.90, 0.12))
	c.draw_line(Vector2(cristal.position.x + ancho * 0.02, cristal.end.y - 2.0),
		Vector2(cristal.end.x - ancho * 0.02, cristal.end.y - 2.0),
		Color(0.30, 0.72, 0.68, 0.60), maxf(1.0, ancho * 0.007), true)
	c.draw_line(Vector2(cristal.position.x + ancho * 0.04, cristal.end.y - 4.0),
		Vector2(cristal.position.x + ancho * 0.22, cristal.position.y + 4.0),
		Color(1.0, 1.0, 1.0, 0.12), maxf(1.0, ancho * 0.012), true)

	# Bandeja metálica del pase.
	var tw: float = ancho * 0.78
	var th: float = tw * 0.473
	var tr := Rect2(centro.x - tw * 0.5, centro.y - th * 0.12, tw, th)
	caja_redondeada(c, Rect2(tr.position + Vector2(0.0, ancho * 0.025),
		tr.size + Vector2(0.0, ancho * 0.02)), ancho * 0.03,
		Color(0.02, 0.03, 0.04, 0.30))
	dibujar_tex_recortada(c, TEX_BANDEJA, tr)
	var liner := Rect2(tr.position + Vector2(tw * 0.10, th * 0.22),
		Vector2(tw * 0.80, th * 0.58))
	caja_redondeada(c, liner, ancho * 0.015, Color("#c6b48b"))

	# Platos con filete: 2 / 3 / 4, como los huecos reales de Emplatado.
	var cuantos: int = clampi(nivel + 1, 2, 4)
	var plato_w: float = minf(ancho * 0.22, liner.size.x / 4.5)
	for i in range(cuantos):
		var px: float = liner.position.x + liner.size.x * (0.14 + 0.24 * float(i))
		var py: float = liner.position.y + liner.size.y * 0.48
		var punto: String = "al_punto"
		var guarnicion: String = "" if nivel <= 1 else "patatas"
		var salsa: String = "salsa" if nivel >= 3 else ""
		dibujar_plato_bistro(c, Vector2(px, py), plato_w, "filete", punto,
			guarnicion, salsa)

	# Café: una, dos o tres tazas en la esquina trasera.
	var tazas: int = nivel
	var taza_w: float = ancho * (0.13 if not compacto else 0.20)
	for i in range(tazas):
		var cx: float = tr.position.x + tr.size.x * (0.58 + 0.15 * float(i))
		var cy: float = tr.position.y + taza_w * 0.10
		dibujar_tex_centro(c, TEX_CAFE, Vector2(cx, cy), taza_w)
		# Vapor.
		c.draw_line(Vector2(cx, cy - taza_w * 0.42),
			Vector2(cx + taza_w * 0.10, cy - taza_w * 0.60),
			Color(1.0, 0.95, 0.85, 0.35), maxf(1.0, ancho * 0.006), true)


static func _bistro_mejora_termostato(c: CanvasItem, centro: Vector2, ancho: float,
		nivel: int, compacto: bool) -> void:
	# Base de parrilla y filete a la izquierda.
	var base_w: float = ancho * (0.40 if not compacto else 0.48)
	var base_h: float = base_w * 0.26
	var base_c := centro + Vector2(-ancho * (0.20 if not compacto else 0.02),
		ancho * (0.11 if not compacto else 0.17))
	var base := Rect2(base_c.x - base_w * 0.5, base_c.y - base_h * 0.5,
		base_w, base_h)
	caja_redondeada(c, base, ancho * 0.025, Color("#1b1e23"), Color("#4b5563"), 1.5)
	for i in range(4):
		c.draw_line(Vector2(base.position.x + base.size.x * (0.18 + 0.20 * float(i)),
			base.position.y + base.size.y * 0.18),
			Vector2(base.position.x + base.size.x * (0.23 + 0.20 * float(i)),
				base.end.y - base.size.y * 0.12),
			Color(0.05, 0.06, 0.08, 0.60), maxf(1.0, ancho * 0.016), true)
	dibujar_filete(c, base_c + Vector2(0.0, -base_h * 0.10),
		ancho * (0.26 if not compacto else 0.30), "al_punto")

	# Dial del punto: aguja que avanza con el nivel.
	var radio: float = ancho * (0.15 if compacto else 0.175)
	var g_centro := centro + Vector2(ancho * (0.0 if compacto else 0.10),
		-ancho * (0.06 if compacto else 0.02))
	c.draw_circle(g_centro, radio * 1.14, Color(0.02, 0.03, 0.05, 0.40))
	c.draw_circle(g_centro, radio, Color("#b45309"))
	c.draw_circle(g_centro, radio * 0.86, Color("#0f172a"))
	c.draw_circle(g_centro, radio * 0.78, Color("#16202c"))
	var a0: float = PI * 0.78
	var a1: float = PI * 2.22
	for i in range(18):
		var a: float = lerpf(a0, a1, float(i) / 17.0)
		var col: Color = Color("#22c55e") if i >= 5 and i <= 12 else Color("#7f1d1d")
		c.draw_circle(g_centro + Vector2(cos(a), sin(a)) * radio * 0.83,
			maxf(1.2, radio * 0.035), Color(col, 0.90))
	var aguja: float = lerpf(-0.70, 0.55, float(clampi(nivel, 1, 3) - 1) / 2.0) - PI * 0.5
	c.draw_line(g_centro, g_centro + Vector2(cos(aguja), sin(aguja)) * radio * 0.68,
		Color("#fde68a"), maxf(1.6, radio * 0.08), true)
	c.draw_circle(g_centro, radio * 0.10, Color("#fbbf24"))
	c.draw_circle(g_centro, radio * 0.05, Color("#78350f"))

	if compacto:
		return
	# Termómetro secundario (nivel 2) y panel digital (nivel 3).
	if nivel >= 2:
		var t_centro := g_centro + Vector2(radio * 1.42, -radio * 0.05)
		c.draw_line(t_centro + Vector2(0.0, radio * 0.58),
			t_centro + Vector2(0.0, -radio * 0.28),
			Color("#94a3b8"), maxf(2.0, radio * 0.10), true)
		c.draw_circle(t_centro + Vector2(0.0, -radio * 0.48), radio * 0.17,
			Color("#f8fafc"))
		c.draw_circle(t_centro + Vector2(0.0, -radio * 0.48), radio * 0.09,
			Color("#dc2626"))
	if nivel >= 3:
		var panel := Rect2(g_centro.x - radio * 0.80, g_centro.y + radio * 1.18,
			radio * 1.6, radio * 0.48)
		caja_redondeada(c, panel, radio * 0.10, Color("#052e1a"),
			Color("#22c55e"), maxf(1.0, radio * 0.04))
		var txt: String = "10.5 s"
		var fs: int = maxi(9, int(radio * 0.27))
		c.draw_string(FUENTE_TIT,
			panel.position + Vector2(panel.size.x * 0.10, panel.size.y * 0.72),
			txt, HORIZONTAL_ALIGNMENT_LEFT, panel.size.x * 0.8, fs, Color("#86efac"))
		c.draw_circle(panel.position + Vector2(panel.size.x * 0.90, panel.size.y * 0.30),
			radio * 0.06, Color("#4ade80"))

static func _bistro_mejora_ingredientes(c: CanvasItem, centro: Vector2, ancho: float,
		nivel: int, compacto: bool) -> void:
	# Tabla de madera del carnicero.
	var w: float = ancho * (0.78 if not compacto else 0.70)
	var h: float = w * 0.48
	var tabla := Rect2(centro.x - w * 0.5, centro.y - h * 0.30, w, h)
	caja_redondeada(c, Rect2(tabla.position + Vector2(0.0, ancho * 0.025),
		tabla.size), ancho * 0.035, Color(0.03, 0.02, 0.01, 0.35))
	caja_redondeada(c, tabla, ancho * 0.035, Color("#6b3f1d"),
		Color("#3f240f"), maxf(1.0, ancho * 0.010))
	caja_redondeada(c, tabla.grow(-ancho * 0.015), ancho * 0.028, Color("#8a5326"))
	# Veta de la madera.
	for i in range(3):
		c.draw_line(Vector2(tabla.position.x + w * 0.10,
			tabla.position.y + h * (0.28 + 0.20 * float(i))),
			Vector2(tabla.end.x - w * 0.10,
				tabla.position.y + h * (0.30 + 0.20 * float(i))),
			Color(0.35, 0.20, 0.08, 0.32), maxf(1.0, ancho * 0.006), true)

	# Filete crudo de proximidad sobre la tabla.
	var filete_w: float = ancho * (0.46 if not compacto else 0.52)
	var filete_c := centro + Vector2(0.0, -ancho * 0.025)
	if nivel >= 2:
		dibujar_filete(c, filete_c + Vector2(ancho * 0.10, -ancho * 0.055),
			filete_w * 0.82, "crudo")
	dibujar_filete(c, filete_c, filete_w, "crudo")

	if compacto:
		return
	# Romero y sello de calidad.
	c.draw_line(Vector2(tabla.position.x + w * 0.16, tabla.position.y + h * 0.78),
		Vector2(tabla.position.x + w * 0.34, tabla.position.y + h * 0.52),
		Color("#3f6212"), maxf(1.4, ancho * 0.008), true)
	for i in range(4):
		var t: float = 0.2 + 0.20 * float(i)
		var p: Vector2 = Vector2(tabla.position.x + w * 0.16, tabla.position.y + h * 0.78).lerp(
			Vector2(tabla.position.x + w * 0.34, tabla.position.y + h * 0.52), t)
		c.draw_line(p, p + Vector2(-ancho * 0.018, -ancho * 0.020), Color("#65a30d"),
			maxf(1.0, ancho * 0.006), true)
	# Sello premium con estrella.
	var sello := centro + Vector2(w * 0.34, h * 0.30)
	c.draw_circle(sello, ancho * 0.062, Color("#b45309"))
	c.draw_circle(sello, ancho * 0.052, Color("#fbbf24"))
	c.draw_circle(sello, ancho * 0.040, Color("#052e1a"))
	_dibujar_estrella_mini(c, sello, ancho * 0.030, Color("#fde68a"))
	if nivel >= 3:
		var etiqueta := Rect2(tabla.position.x + w * 0.60, tabla.end.y - h * 0.28,
			w * 0.28, h * 0.24)
		caja_redondeada(c, etiqueta, ancho * 0.012, Color("#fff7e6"),
			Color("#b45309"), 1.2)
		c.draw_string(FUENTE_TIT,
			etiqueta.position + Vector2(etiqueta.size.x * 0.12, etiqueta.size.y * 0.72),
			"PREMIUM", HORIZONTAL_ALIGNMENT_LEFT, etiqueta.size.x * 0.8,
			maxi(8, int(ancho * 0.032)), Color("#9a3412"))


static func _bistro_mejora_ambiente(c: CanvasItem, centro: Vector2, ancho: float,
		nivel: int, compacto: bool) -> void:
	# Pared de terciopelo del bistró.
	var pared_w: float = ancho * (0.84 if not compacto else 0.76)
	var pared_h: float = pared_w * (0.48 if not compacto else 0.58)
	var pared := Rect2(centro.x - pared_w * 0.5, centro.y - pared_h * 0.62,
		pared_w, pared_h)
	caja_redondeada(c, pared, ancho * 0.03, Color("#3f1418"), Color("#7f1d1d"),
		maxf(1.0, ancho * 0.006))
	# Capitoné de la banqueta.
	for i in range(3):
		var x: float = pared.position.x + pared.size.x * (0.22 + 0.28 * float(i))
		c.draw_circle(Vector2(x, pared.position.y + pared.size.y * 0.38),
			ancho * 0.012, Color(0.10, 0.03, 0.04, 0.60))
		c.draw_line(Vector2(x - ancho * 0.06, pared.position.y + pared.size.y * 0.38),
			Vector2(x + ancho * 0.06, pared.position.y + pared.size.y * 0.38),
			Color(0.55, 0.18, 0.20, 0.45), maxf(1.0, ancho * 0.005), true)

	# Espejo dorado.
	var espejo := Rect2(pared.position.x + pared.size.x * 0.10,
		pared.position.y + pared.size.y * 0.08,
		pared.size.x * 0.30, pared.size.y * 0.34)
	caja_redondeada(c, espejo.grow(ancho * 0.012), ancho * 0.015, Color("#b78a2e"))
	caja_redondeada(c, espejo, ancho * 0.012, Color("#b6d7d1"),
		Color("#f5e6b8"), 1.0)
	c.draw_line(Vector2(espejo.position.x + ancho * 0.015, espejo.end.y - ancho * 0.02),
		Vector2(espejo.position.x + ancho * 0.06, espejo.position.y + ancho * 0.02),
		Color(1.0, 1.0, 1.0, 0.45), maxf(1.0, ancho * 0.008), true)

	# Lámpara de pared.
	var lamp_c := pared.position + Vector2(pared.size.x * 0.72, pared.size.y * 0.28)
	c.draw_line(lamp_c + Vector2(0.0, -ancho * 0.03), lamp_c + Vector2(0.0, ancho * 0.03),
		Color("#b78a2e"), maxf(1.0, ancho * 0.008), true)
	c.draw_colored_polygon(PackedVector2Array([
		lamp_c + Vector2(-ancho * 0.055, ancho * 0.02),
		lamp_c + Vector2(ancho * 0.055, ancho * 0.02),
		lamp_c + Vector2(ancho * 0.032, ancho * 0.075),
		lamp_c + Vector2(-ancho * 0.032, ancho * 0.075),
	]), Color("#f5e6b8"))
	c.draw_set_transform(lamp_c + Vector2(0.0, ancho * 0.07), 0.0, Vector2(1.0, 0.45))
	c.draw_circle(Vector2.ZERO, ancho * 0.10, Color(1.0, 0.80, 0.35, 0.28))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Mesa con mantel de cuadros.
	var mesa_w: float = pared_w * 0.46
	var mesa_h: float = mesa_w * 0.56
	var mesa := Rect2(centro.x - mesa_w * 0.52, centro.y + ancho * 0.06,
		mesa_w, mesa_h)
	caja_redondeada(c, Rect2(mesa.position + Vector2(0.0, ancho * 0.035),
		mesa.size), ancho * 0.02, Color(0.05, 0.02, 0.02, 0.35))
	caja_redondeada(c, mesa, ancho * 0.02, Color("#f7f1e1"), Color("#b45309"), 1.2)
	# Cuadros del mantel.
	var paso_c: float = mesa.size.x * 0.14
	var xc: float = mesa.position.x + paso_c
	while xc < mesa.end.x - 2.0:
		c.draw_line(Vector2(xc, mesa.position.y + 2.0), Vector2(xc, mesa.end.y - 2.0),
			Color(0.72, 0.12, 0.12, 0.35), 1.0)
		xc += paso_c
	var yc: float = mesa.position.y + paso_c * 0.6
	while yc < mesa.end.y - 2.0:
		c.draw_line(Vector2(mesa.position.x + 2.0, yc), Vector2(mesa.end.x - 2.0, yc),
			Color(0.72, 0.12, 0.12, 0.35), 1.0)
		yc += paso_c * 0.6
	# Copa de vino y vela.
	var copa := mesa.position + Vector2(mesa.size.x * 0.30, mesa.size.y * 0.12)
	dibujar_copa_vino(c, copa, mesa.size.x * 0.20, true)
	var vela := mesa.position + Vector2(mesa.size.x * 0.68, mesa.size.y * 0.18)
	c.draw_rect(Rect2(vela.x - ancho * 0.012, vela.y, ancho * 0.024, ancho * 0.075),
		Color("#f5e6b8"))
	c.draw_colored_polygon(PackedVector2Array([
		vela + Vector2(-ancho * 0.010, 0.0),
		vela + Vector2(0.0, -ancho * 0.040),
		vela + Vector2(ancho * 0.010, 0.0),
	]), Color("#fbbf24"))

	if nivel >= 2:
		# Segunda lámpara y botella.
		var lamp2 := pared.position + Vector2(pared.size.x * 0.18, pared.size.y * 0.20)
		c.draw_line(lamp2, lamp2 + Vector2(0.0, ancho * 0.05), Color("#b78a2e"),
			maxf(1.0, ancho * 0.006), true)
		c.draw_circle(lamp2 + Vector2(0.0, ancho * 0.065), ancho * 0.045,
			Color(1.0, 0.78, 0.35, 0.24))
		c.draw_circle(mesa.position + Vector2(mesa.size.x * 0.50, mesa.size.y * 0.32),
			ancho * 0.030, Color("#14532d"))
		c.draw_rect(Rect2(mesa.position.x + mesa.size.x * 0.47,
			mesa.position.y + mesa.size.y * 0.05, ancho * 0.018, ancho * 0.065),
			Color("#14532d"))
	if nivel >= 3:
		# Lámpara de techo del nivel máximo.
		var cand := pared.position + Vector2(pared.size.x * 0.52, -ancho * 0.02)
		c.draw_line(cand, cand + Vector2(0.0, ancho * 0.075), Color("#7c5a18"),
			maxf(1.0, ancho * 0.006), true)
		c.draw_circle(cand + Vector2(0.0, ancho * 0.105), ancho * 0.065,
			Color(1.0, 0.85, 0.40, 0.22))
		c.draw_circle(cand + Vector2(0.0, ancho * 0.095), ancho * 0.035,
			Color("#fde68a"))


static func _dibujar_estrella_mini(c: CanvasItem, centro: Vector2, radio: float,
		color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(10):
		var r: float = radio if i % 2 == 0 else radio * 0.44
		var a: float = -PI * 0.5 + PI * float(i) / 5.0
		pts.append(centro + Vector2(cos(a), sin(a)) * r)
	c.draw_colored_polygon(pts, color)


static func dibujar_icono_alta(c: CanvasItem, centro: Vector2, caja: float,
		proteina: String, guarnicion: String, alpha: float = 1.0) -> void:
	# Icono de ticket de alta cocina: medallón grande, puntos de salsa y flor.
	var base := centro + Vector2(0.0, caja * 0.22)
	c.draw_set_transform(base, 0.0, Vector2(1.0, 0.30))
	c.draw_circle(Vector2.ZERO, caja * 0.46, Color(0.06, 0.09, 0.15, 0.24 * alpha))
	c.draw_circle(Vector2.ZERO, caja * 0.42, Color("#f8fafc", 0.94 * alpha))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for i in range(5):
		var a: float = TAU * float(i) / 5.0 - 0.6
		c.draw_circle(base + Vector2(cos(a) * caja * 0.26, sin(a) * caja * 0.10),
			maxf(1.4, caja * 0.032), Color("#7f1d1d", 0.92 * alpha))
	# Proteína
	var centro_p := centro + Vector2(0.0, -caja * 0.04)
	if proteina == "lubina":
		c.draw_colored_polygon(PackedVector2Array([
			centro_p + Vector2(-caja * 0.30, -caja * 0.10),
			centro_p + Vector2(caja * 0.26, -caja * 0.18),
			centro_p + Vector2(caja * 0.32, caja * 0.02),
			centro_p + Vector2(-caja * 0.22, caja * 0.14),
		]), Color("#f1f5f9", alpha))
		c.draw_polyline(PackedVector2Array([
			centro_p + Vector2(-caja * 0.30, -caja * 0.10),
			centro_p + Vector2(caja * 0.26, -caja * 0.18),
			centro_p + Vector2(caja * 0.32, caja * 0.02),
			centro_p + Vector2(-caja * 0.22, caja * 0.14),
			centro_p + Vector2(-caja * 0.30, -caja * 0.10),
		]), Color("#cbd5e1", alpha), 1.2, true)
	else:
		var col := Color("#7f1d1d") if proteina == "solomillo" else Color("#9f1239")
		c.draw_circle(centro_p, caja * 0.22, Color("#3f2418", alpha))
		c.draw_circle(centro_p, caja * 0.17, Color(col, alpha))
		c.draw_circle(centro_p + Vector2(-caja * 0.05, -caja * 0.04), caja * 0.07,
			Color("#f2a3a0", 0.35 * alpha))
	# Guarnición
	if guarnicion == "pure":
		c.draw_set_transform(centro + Vector2(-caja * 0.23, caja * 0.02), 0.0, Vector2(1.0, 0.52))
		c.draw_circle(Vector2.ZERO, caja * 0.15, Color("#fef3c7", alpha))
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		for i in range(3):
			var p := centro + Vector2(-caja * 0.30 + float(i) * caja * 0.06, caja * 0.12)
			c.draw_line(p, p + Vector2(caja * 0.13, -caja * 0.28),
				Color("#4d7c0f", alpha), maxf(1.5, caja * 0.055), true)
	# Flor
	var p_flor := centro + Vector2(caja * 0.23, -caja * 0.22)
	for i in range(5):
		var a2: float = TAU * float(i) / 5.0
		c.draw_circle(p_flor + Vector2(cos(a2), sin(a2)) * caja * 0.035,
			maxf(1.1, caja * 0.024), Color("#f472b6", alpha))
	c.draw_circle(p_flor, maxf(1.0, caja * 0.018), Color("#fbbf24", alpha))


static func dibujar_cuenco(c: CanvasItem, centro: Vector2, ancho: float,
		relleno: Color, alpha: float = 1.0) -> void:
	var alto: float = ancho * 0.46
	var r := Rect2(centro.x - ancho * 0.5, centro.y - alto * 0.5, ancho, alto)
	# Sombra
	c.draw_set_transform(Vector2(centro.x, r.end.y - 2.0), 0.0, Vector2(1.0, 0.30))
	c.draw_circle(Vector2.ZERO, ancho * 0.44, Color(0.0, 0.0, 0.0, 0.20 * alpha))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Cuenco de cerámica
	c.draw_colored_polygon(PackedVector2Array([
		Vector2(r.position.x, r.position.y + alto * 0.22),
		Vector2(r.end.x, r.position.y + alto * 0.22),
		Vector2(r.end.x - ancho * 0.14, r.end.y - alto * 0.10),
		Vector2(r.position.x + ancho * 0.14, r.end.y - alto * 0.10),
	]), Color("#f1f5f9", alpha))
	c.draw_polyline(PackedVector2Array([
		Vector2(r.position.x, r.position.y + alto * 0.22),
		Vector2(r.end.x, r.position.y + alto * 0.22),
		Vector2(r.end.x - ancho * 0.14, r.end.y - alto * 0.10),
		Vector2(r.position.x + ancho * 0.14, r.end.y - alto * 0.10),
		Vector2(r.position.x, r.position.y + alto * 0.22),
	]), Color("#cbd5e1", alpha), 1.5, true)
	# Guiso
	c.draw_set_transform(Vector2(centro.x, r.position.y + alto * 0.26), 0.0, Vector2(1.0, 0.34))
	c.draw_circle(Vector2.ZERO, ancho * 0.42, Color(relleno, alpha))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Borde del guiso
	c.draw_arc(Vector2(centro.x, r.position.y + alto * 0.26), ancho * 0.42, 0.0, TAU, 28,
		Color("#b45309", 0.65 * alpha), 2.0, true)


static func dibujar_plato_mercado(c: CanvasItem, centro: Vector2, caja: float,
		guiso: String, extra: String, alpha: float = 1.0) -> void:
	var relleno := Color("#9a3412")
	var tropezones := Color("#f59e0b")
	if guiso == "pisto":
		relleno = Color("#b91c1c")
		tropezones = Color("#16a34a")
	elif guiso == "arroz":
		relleno = Color("#eab308")
		tropezones = Color("#f97316")
	dibujar_cuenco(c, centro + Vector2(0.0, caja * 0.02), caja * 0.86, relleno, alpha)
	# Tropezones
	for i in range(5):
		var a: float = TAU * float(i) / 5.0 + 0.4
		var p := centro + Vector2(cos(a) * caja * 0.12, -caja * 0.05 + sin(a) * caja * 0.06)
		c.draw_circle(p, caja * 0.035, Color(tropezones, alpha))
	# Huevo frito
	if extra == "huevo":
		c.draw_circle(centro + Vector2(caja * 0.16, -caja * 0.12), caja * 0.12, Color("#f8fafc", alpha))
		c.draw_circle(centro + Vector2(caja * 0.16, -caja * 0.12), caja * 0.06, Color("#f59e0b", alpha))


static func dibujar_plato_alta(c: CanvasItem, centro: Vector2, caja: float,
		proteina: String, salsa: String, guarnicion: String, flor: bool,
		alpha: float = 1.0) -> void:
	var ancho: float = caja * 0.92
	var alto: float = ancho * 0.34
	var centro_plato := centro + Vector2(0.0, alto * 0.16)
	c.draw_set_transform(centro_plato, 0.0, Vector2(1.0, 0.40))
	c.draw_circle(Vector2.ZERO, ancho * 0.50, Color(0.0, 0.0, 0.0, 0.24 * alpha))
	c.draw_circle(Vector2.ZERO, ancho * 0.47, Color("#f8fafc", alpha))
	c.draw_circle(Vector2.ZERO, ancho * 0.34, Color("#e2e8f0", alpha))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Puntos de salsa
	if salsa != "":
		for i in range(5):
			var a: float = TAU * float(i) / 5.0 - 0.6
			var p := centro_plato + Vector2(cos(a) * ancho * 0.25, sin(a) * alto * 0.22)
			c.draw_circle(p, ancho * 0.030, Color("#7f1d1d", 0.90 * alpha))
	# Guarnición
	if guarnicion == "pure":
		c.draw_set_transform(centro_plato + Vector2(-ancho * 0.18, alto * 0.08), 0.0, Vector2(1.0, 0.52))
		c.draw_circle(Vector2.ZERO, ancho * 0.12, Color("#fef3c7", alpha))
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	elif guarnicion == "esparragos":
		for i in range(4):
			var p := centro_plato + Vector2(-ancho * 0.22 + float(i) * ancho * 0.055, alto * 0.10)
			c.draw_line(p, p + Vector2(ancho * 0.14, -alto * 0.30), Color("#4d7c0f", alpha), 5.0, true)
			c.draw_line(p + Vector2(ancho * 0.09, -alto * 0.19), p + Vector2(ancho * 0.13, -alto * 0.26),
				Color("#65a30d", alpha), 3.5, true)
	# Proteína
	if proteina == "solomillo" or proteina == "pato":
		var col := Color("#7f1d1d") if proteina == "solomillo" else Color("#9f1239")
		c.draw_set_transform(centro_plato + Vector2(0.0, -alto * 0.12), 0.0, Vector2(1.0, 0.72))
		c.draw_circle(Vector2.ZERO, ancho * 0.14, Color("#3f2418", alpha))
		c.draw_circle(Vector2.ZERO, ancho * 0.11, Color(col, alpha))
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	elif proteina == "lubina":
		c.draw_colored_polygon(PackedVector2Array([
			centro_plato + Vector2(-ancho * 0.20, -alto * 0.20),
			centro_plato + Vector2(ancho * 0.16, -alto * 0.30),
			centro_plato + Vector2(ancho * 0.22, -alto * 0.06),
			centro_plato + Vector2(-ancho * 0.14, alto * 0.04),
		]), Color("#f1f5f9", alpha))
		c.draw_polyline(PackedVector2Array([
			centro_plato + Vector2(-ancho * 0.20, -alto * 0.20),
			centro_plato + Vector2(ancho * 0.16, -alto * 0.30),
			centro_plato + Vector2(ancho * 0.22, -alto * 0.06),
			centro_plato + Vector2(-ancho * 0.14, alto * 0.04),
			centro_plato + Vector2(-ancho * 0.20, -alto * 0.20),
		]), Color("#cbd5e1", alpha), 1.4, true)
	# Flor comestible opcional
	if flor:
		var p := centro_plato + Vector2(ancho * 0.18, -alto * 0.28)
		for i in range(5):
			var a: float = TAU * float(i) / 5.0
			c.draw_circle(p + Vector2(cos(a), sin(a)) * ancho * 0.032, ancho * 0.022,
				Color("#f472b6", alpha))
		c.draw_circle(p, ancho * 0.016, Color("#fbbf24", alpha))


## Icono de ingrediente de despensa para tickets y arrastre. Devuelve true si
## el id tiene dibujo propio (para no caer en la textura genérica del plato).
static func dibujar_ingrediente_icono(c: CanvasItem, item_id: String, centro: Vector2,
		caja: float, alpha: float = 1.0) -> bool:
	match item_id:
		"filete_crudo", "filete":
			dibujar_filete(c, centro, caja * 0.82, "crudo", alpha)
		"solomillo":
			dibujar_filete(c, centro, caja * 0.82, "al_punto", alpha)
		"lubina":
			c.draw_colored_polygon(PackedVector2Array([
				centro + Vector2(-caja * 0.32, -caja * 0.12),
				centro + Vector2(caja * 0.30, -caja * 0.22),
				centro + Vector2(caja * 0.36, caja * 0.02),
				centro + Vector2(-caja * 0.22, caja * 0.18),
			]), Color("#f1f5f9", alpha))
			c.draw_circle(centro + Vector2(-caja * 0.24, -caja * 0.02), caja * 0.025,
				Color("#0f172a", alpha))
		"pato":
			dibujar_filete(c, centro, caja * 0.80, "hecho", alpha)
			c.draw_line(centro + Vector2(-caja * 0.26, -caja * 0.14),
				centro + Vector2(caja * 0.24, -caja * 0.14), Color("#fde68a", 0.75 * alpha), 3.0, true)
		"huevo":
			c.draw_circle(centro, caja * 0.30, Color("#f8fafc", alpha))
			c.draw_circle(centro + Vector2(caja * 0.02, caja * 0.01), caja * 0.13, Color("#f59e0b", alpha))
		"salsa":
			dibujar_tex(c, TEX_SALSERA, Rect2(centro - Vector2(caja * 0.5, caja * 0.4), Vector2(caja, caja * 0.8)), Color(1, 1, 1, alpha))
		"alubias":
			# Saquito de arpillera con alubias
			c.draw_colored_polygon(PackedVector2Array([
				centro + Vector2(-caja * 0.26, caja * 0.24),
				centro + Vector2(-caja * 0.20, -caja * 0.12),
				centro + Vector2(caja * 0.20, -caja * 0.12),
				centro + Vector2(caja * 0.26, caja * 0.24),
			]), Color("#a16207", alpha))
			c.draw_line(centro + Vector2(-caja * 0.18, -caja * 0.10),
				centro + Vector2(caja * 0.18, -caja * 0.10), Color("#78350f", alpha), 3.0, true)
			for i in range(12):
				var a: float = TAU * float(i) / 12.0
				c.draw_circle(centro + Vector2(cos(a) * caja * 0.13, -caja * 0.02 + sin(a) * caja * 0.08),
					maxf(1.5, caja * 0.038), Color("#78350f", alpha))
		"chorizo":
			c.draw_line(centro + Vector2(-caja * 0.24, caja * 0.10),
				centro + Vector2(caja * 0.22, -caja * 0.10), Color("#991b1b", alpha), caja * 0.18, true)
			c.draw_line(centro + Vector2(-caja * 0.18, caja * 0.07),
				centro + Vector2(caja * 0.16, -caja * 0.07), Color("#fca5a5", 0.55 * alpha), 2.0, true)
		"pimiento":
			c.draw_colored_polygon(PackedVector2Array([
				centro + Vector2(-caja * 0.18, caja * 0.18),
				centro + Vector2(-caja * 0.26, -caja * 0.10),
				centro + Vector2(caja * 0.06, -caja * 0.24),
				centro + Vector2(caja * 0.24, caja * 0.02),
				centro + Vector2(caja * 0.06, caja * 0.24),
			]), Color("#dc2626", alpha))
			c.draw_line(centro + Vector2(caja * 0.06, -caja * 0.24),
				centro + Vector2(caja * 0.14, -caja * 0.32), Color("#15803d", alpha), 3.0, true)
		"arroz":
			dibujar_cuenco(c, centro, caja * 0.82, Color("#fef3c7"), alpha)
			for i in range(9):
				var p := centro + Vector2(-caja * 0.16 + float(i % 3) * caja * 0.16,
					-caja * 0.12 + float(i / 3) * caja * 0.10)
				c.draw_line(p, p + Vector2(caja * 0.04, -caja * 0.02), Color("#f8fafc", alpha), 2.0, true)
		"marisco":
			for i in range(3):
				var p := centro + Vector2(-caja * 0.18 + float(i) * caja * 0.18, caja * 0.02)
				c.draw_arc(p, caja * 0.10, PI * 0.15, PI * 0.85, 10, Color("#f97316", alpha), 4.0, true)
				c.draw_circle(p + Vector2(caja * 0.10, -caja * 0.02), caja * 0.03, Color("#fb923c", alpha))
		"pure":
			dibujar_cuenco(c, centro, caja * 0.82, Color("#fef9c3"), alpha)
		"esparragos":
			for i in range(3):
				var p := centro + Vector2(-caja * 0.15 + float(i) * caja * 0.13, caja * 0.18)
				c.draw_line(p, p + Vector2(caja * 0.07, -caja * 0.34), Color("#4d7c0f", alpha), 4.0, true)
				c.draw_line(p + Vector2(caja * 0.03, -caja * 0.20),
					p + Vector2(caja * 0.09, -caja * 0.31), Color("#84cc16", alpha), 2.5, true)
		"flor":
			var p := centro
			for i in range(6):
				var a: float = TAU * float(i) / 6.0
				c.draw_circle(p + Vector2(cos(a), sin(a)) * caja * 0.12, caja * 0.075,
					Color("#f472b6", alpha))
			c.draw_circle(p, caja * 0.055, Color("#fbbf24", alpha))
		"tarta":
			dibujar_tex(c, TEX_TARTA, Rect2(centro - Vector2(caja * 0.48, caja * 0.48),
				Vector2(caja * 0.96, caja * 0.96)), Color(1, 1, 1, alpha))
		_:
			return false
	return true



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


## Geometría compartida del plato dentro de su hueco del pase. Mantener el
## cálculo en un solo sitio garantiza que el plato dibujado, su sombra y la
## zona táctil queden siempre centrados y con el mismo margen en los 4 huecos.
static func ancho_plato_visible(tam: Vector2, restaurante: String) -> float:
	if restaurante == "burger_street":
		return minf(tam.x * 0.96, tam.y * 0.72)
	# Los mundos 2-4 usan platos más anchos para que la comida se lea, pero
	# siempre dejan un margen dentro de la celda para no tocar la vecina.
	return minf(tam.x * 0.92, tam.y * 1.05)


static func centro_plato_visible(tam: Vector2, restaurante: String) -> Vector2:
	if restaurante == "burger_street":
		return Vector2(tam.x * 0.5, tam.y * 0.62)
	return Vector2(tam.x * 0.5, tam.y * 0.57)


## Rectángulo visual del plato (sin contar el vuelo del pop) centrado en la
## celda. Lo usan QA y los tests de alineación.
static func rect_plato_visible(celda: Rect2, restaurante: String) -> Rect2:
	var ancho: float = ancho_plato_visible(celda.size, restaurante)
	var alto: float = ancho * PLATO_PERSPECTIVA
	var centro: Vector2 = centro_plato_visible(celda.size, restaurante)
	return Rect2(celda.position + centro - Vector2(ancho, alto) * 0.5,
		Vector2(ancho, alto))


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

		# Sombra suave en perspectiva 3/4 bajo la base de la bandeja (trapecio
		# ajustado al escorzo de Bandeja_Metal.png, sin esquinas grises atrás).
		draw_colored_polygon(PackedVector2Array([
			Vector2(28.0, 32.0),
			Vector2(size.x - 28.0, 32.0),
			Vector2(size.x - 6.0, size.y - 4.0),
			Vector2(size.x - 18.0, size.y + 5.0),
			Vector2(18.0, size.y + 5.0),
			Vector2(6.0, size.y - 4.0),
		]), Color(0.02, 0.03, 0.05, 0.28))

		# Bandeja metálica 3D del pack: deja ver el acero cepillado entre los
		# papeles encerados, igual que la bandeja de servicio de la referencia.
		Arte_Cocina.dibujar_tex_recortada(self, Arte_Cocina.TEX_BANDEJA, caja)

		# Compartimentos: los abiertos llevan su propia hoja de papel encerado
		# crema sobre el acero (para que el plato blanco destaque con contraste);
		# los cerrados se muestran como rebajes metálicos con candado.
		for i in range(celdas.size()):
			_dibujar_celda(celdas[i], i < desbloqueados, i)

	func _dibujar_celda(celda: Rect2, desbloqueada: bool, indice: int) -> void:
		if celda.size.x < 8.0 or celda.size.y < 8.0:
			return
		if desbloqueada:
			# Hoja individual de papel encerado cálido asentada en el fondo de
			# la bandeja metálica, con proporción casi cuadrada como la referencia.
			var papel := Rect2(
				celda.position.x + 2.0,
				celda.position.y + 20.0,
				celda.size.x - 4.0,
				celda.size.y - 22.0)
			Arte_Cocina.caja_redondeada(self,
				Rect2(papel.position + Vector2(1.0, 2.5), papel.size), 5.0,
				Color(0.04, 0.03, 0.02, 0.24))
			Arte_Cocina.caja_redondeada(self, papel, 4.5,
				Color("#e2cda7"), Color("#bfa373", 0.78), 1.0)
			# Tono cálido suave del papel (sin bloques blancos cortados)
			Arte_Cocina.caja_redondeada(self, papel.grow(-2.0), 3.5,
				Color("#ebd9b7", 0.55))
			# Sombra interior superior bajo el borde trasero de la bandeja
			draw_rect(Rect2(papel.position + Vector2(2.0, 1.0),
				Vector2(papel.size.x - 4.0, 5.0)), Color(0.32, 0.22, 0.10, 0.10))
			# Borde inferior iluminado del papel
			draw_line(
				Vector2(papel.position.x + 4.0, papel.end.y - 1.2),
				Vector2(papel.end.x - 4.0, papel.end.y - 1.2),
				Color(1.0, 0.97, 0.88, 0.45), 1.1, true)
			return
		# Rebaje metálico oscuro para huecos pendientes de mejora.
		var rebaje := Rect2(celda.position.x + 1.0, celda.position.y + 8.0,
			celda.size.x - 2.0, celda.size.y - 10.0)
		Arte_Cocina.caja_redondeada(self, rebaje, 7.0, Color("#252c32", 0.92))
		Arte_Cocina.caja_redondeada(self, rebaje.grow(-2.0), 6.0, Color("#3d474f", 0.92))
		Arte_Cocina.caja_redondeada(self,
			Rect2(rebaje.position + Vector2(2.0, 2.0),
				Vector2(rebaje.size.x - 4.0, rebaje.size.y * 0.28)), 6.0,
			Color(0.02, 0.04, 0.06, 0.35))
		draw_polyline(PackedVector2Array([
			Vector2(rebaje.position.x + 8.0, rebaje.end.y - 2.0),
			Vector2(rebaje.end.x - 8.0, rebaje.end.y - 2.0),
		]), Color(0.75, 0.82, 0.88, 0.22), 1.4, true)
		_dibujar_hueco_bloqueado(rebaje.grow(-2.0), indice)

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
	# Campos del mundo 1 (hamburguesas)
	var pan: bool = false
	var carnes: int = 0
	var queso: bool = false
	var lechuga: bool = false
	var tomate: bool = false
	# Campos genéricos de los mundos 2-4
	var restaurante: String = "burger_street"
	var proteina: String = ""
	var punto: String = ""
	var guiso: String = ""
	var guarnicion: String = ""
	var salsa: String = ""
	var extra: String = ""
	var flor: bool = false
	var pedida: bool = false
	var seleccionado: bool = false
	var destacado: bool = false
	var tiempo: float = 0.0
	var pop: float = 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func esta_vacio() -> bool:
		if restaurante == "burger_street":
			return not pan and carnes <= 0
		return proteina == "" and guiso == "" and guarnicion == "" and salsa == "" and extra == "" and not flor

	func _draw() -> void:
		if size.x <= 8.0 or size.y <= 8.0:
			return
		var pop_esc: float = 1.0 + sin(clampf(pop, 0.0, 1.0) * PI) * 0.08
		var ancho_plato: float = Arte_Cocina.ancho_plato_visible(size, restaurante)
		var centro: Vector2 = Arte_Cocina.centro_plato_visible(size, restaurante)
		var alto_plato: float = ancho_plato * Arte_Cocina.PLATO_PERSPECTIVA

		# Halo verde solo cuando un cliente está esperando ese plato. La
		# selección no pinta ningún marco: el plato debe verse limpio.
		if pedida:
			var pulso: float = 0.5 + 0.5 * sin(tiempo * 5.0)
			draw_set_transform(centro, 0.0, Vector2(1.0, Arte_Cocina.PLATO_PERSPECTIVA))
			draw_circle(Vector2.ZERO, ancho_plato * 0.54,
				Color(0.13, 0.77, 0.37, 0.14 + 0.10 * pulso))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

		# Plato + composición del mundo correspondiente
		match restaurante:
			"bistro_tradicional":
				Arte_Cocina.dibujar_plato_bistro(self, centro, ancho_plato,
					proteina, punto, guarnicion, salsa, 1.0)
			"cocina_mercado":
				Arte_Cocina.dibujar_plato_mercado(self, centro, ancho_plato,
					guiso, extra, 1.0)
			"alta_cocina":
				Arte_Cocina.dibujar_plato_alta(self, centro, ancho_plato,
					proteina, salsa, guarnicion, flor, 1.0)
			_:
				# En Burger Street el plato de cerámica blanca aparece al colocar
				# el pan; cuando el hueco está vacío se muestra la marca impresa
				# en el papel encerado, igual que en la referencia.
				if not esta_vacio():
					Arte_Cocina.dibujar_plato_hamburguesa(self, centro, ancho_plato,
						pan, carnes, queso, lechuga, tomate, 1.0, pop_esc)

		# Hueco vacío: invitación sutil para montar
		if esta_vacio():
			_dibujar_plato_vacio(centro, ancho_plato)

		# Anillo verde de estado (plato pedido por un cliente)
		if pedida:
			var pts := Arte_Cocina.puntos_elipse(centro + Vector2(0.0, -1.0),
				ancho_plato * 0.50, alto_plato * 0.50, 48)
			pts.append(pts[0])
			draw_polyline(pts, Color(0.13, 0.77, 0.37, 0.92), 2.6, true)

		# Check de plato listo para servir
		if pedida:
			var pulso2: float = 0.5 + 0.5 * sin(tiempo * 6.0)
			var check_c := centro + Vector2(ancho_plato * 0.48, -alto_plato * 0.42)
			draw_circle(check_c, 10.0 + pulso2 * 1.2, Color(0.09, 0.64, 0.29, 0.30))
			draw_circle(check_c, 8.5, Color("#16a34a"))
			draw_polyline(PackedVector2Array([
				check_c + Vector2(-4.0, 0.0), check_c + Vector2(-1.0, 3.2),
				check_c + Vector2(4.2, -3.6)
			]), Color.WHITE, 2.3, true)

	func _dibujar_plato_vacio(centro: Vector2, ancho_plato: float) -> void:
		var pulso: float = 0.5 + 0.5 * sin(tiempo * 3.2)
		var alto_plato: float = ancho_plato * Arte_Cocina.PLATO_PERSPECTIVA
		var alpha_ghost: float = 0.28 + 0.12 * pulso

		if restaurante != "burger_street":
			# Plato vacío genérico: anillo de emplatado + badge "+".
			var radio: float = ancho_plato * 0.20
			var centro_badge := centro + Vector2(0.0, -alto_plato * 0.06)
			draw_arc(centro_badge, radio, 0.0, TAU, 28,
				Color(0.98, 0.85, 0.45, alpha_ghost), 2.0, true)
			var r_badge: float = clampf(radio * 0.36, 7.0, 10.0)
			draw_circle(centro_badge, r_badge, Color(0.12, 0.08, 0.04, 0.62))
			draw_arc(centro_badge, r_badge, 0.0, TAU, 24, Color("#fbbf24"), 1.6, true)
			var b: float = r_badge * 0.42
			draw_line(centro_badge + Vector2(-b, 0.0), centro_badge + Vector2(b, 0.0),
				Color("#fde68a"), 2.0, true)
			draw_line(centro_badge + Vector2(0.0, -b), centro_badge + Vector2(0.0, b),
				Color("#fde68a"), 2.0, true)
			return

		# Marca impresa en sepia sobre el papel encerado: silueta de plato y
		# hamburguesa vintage, exactamente como los huecos vacíos de la referencia.
		var tinta := Color(0.48, 0.36, 0.22, 0.42 + 0.08 * pulso)
		var tinta_suave := Color(0.52, 0.39, 0.24, 0.24 + 0.06 * pulso)
		var aro_ext := Arte_Cocina.puntos_elipse(centro, ancho_plato * 0.40, alto_plato * 0.40, 36)
		aro_ext.append(aro_ext[0])
		draw_polyline(aro_ext, tinta, 1.3, true)
		var aro_int := Arte_Cocina.puntos_elipse(centro, ancho_plato * 0.28, alto_plato * 0.28, 32)
		aro_int.append(aro_int[0])
		draw_polyline(aro_int, tinta_suave, 1.0, true)

		# Icono impreso de hamburguesa pequeña en el centro del papel
		var bw: float = ancho_plato * 0.44
		var c_ico := centro + Vector2(0.0, -alto_plato * 0.02)
		# Base del pan impresa
		var base_r := Rect2(c_ico.x - bw * 0.44, c_ico.y + bw * 0.06, bw * 0.88, bw * 0.18)
		Arte_Cocina.caja_redondeada(self, base_r, bw * 0.08,
			Color(0.72, 0.54, 0.30, 0.34), tinta, 1.1)
		# Franja verde de lechuga impresa
		var lech_r := Rect2(c_ico.x - bw * 0.48, c_ico.y - bw * 0.04, bw * 0.96, bw * 0.11)
		Arte_Cocina.caja_redondeada(self, lech_r, bw * 0.05,
			Color(0.42, 0.58, 0.30, 0.36))
		# Cúpula del pan impresa
		var pts_cup := PackedVector2Array()
		for k in range(15):
			var a: float = PI + PI * float(k) / 14.0
			pts_cup.append(Vector2(c_ico.x + cos(a) * bw * 0.46,
				c_ico.y - bw * 0.03 + sin(a) * bw * 0.32))
		draw_colored_polygon(pts_cup, Color(0.75, 0.54, 0.28, 0.38))
		var pts_cup_borde := PackedVector2Array(pts_cup)
		pts_cup_borde.append(pts_cup[0])
		draw_polyline(pts_cup_borde, tinta, 1.1, true)


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
	var punto: String = ""
	var ventana: bool = false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _dibujar_proteina(centro: Vector2) -> void:
		# Proteínas de los mundos 2-4: filete con punto, huevo, solomillo,
		# lubina o pato. La ventana dorada del horno de alta cocina se dibuja
		# como una franja sobre la barra de progreso.
		var ancho: float = minf(size.x * 0.92, 62.0)
		var bob: float = sin(tiempo * 4.0 + centro.x) * 0.8 if estado == "cocinando" else 0.0
		var punto_vis: String = punto
		if punto_vis == "":
			if estado == "quemado":
				punto_vis = "quemado"
			elif estado == "listo" or estado == "alerta":
				punto_vis = "hecho" if tipo != "lubina" and tipo != "huevo" else "al_punto"
			elif progreso < 0.35:
				punto_vis = "crudo"
			elif progreso < 0.62:
				punto_vis = "poco_hecho"
			elif progreso < 0.85:
				punto_vis = "al_punto"
			else:
				punto_vis = "hecho"
		match tipo:
			"filete", "solomillo", "pato":
				# Se pasa el centro absoluto: dibujar_filete gestiona sus propios
				# transforms (sombra, escala y giro) y no debe heredar otro.
				Arte_Cocina.dibujar_filete(self,
					centro + Vector2(0.0, bob + 3.0), ancho, punto_vis, 1.0)
			"huevo":
				draw_set_transform(centro + Vector2(0.0, bob + 2.0), 0.0,
					Vector2(1.0, 0.72))
				draw_circle(Vector2.ZERO, ancho * 0.62, Color("#f8fafc"))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				draw_circle(centro + Vector2(ancho * 0.10, -ancho * 0.02 + bob),
					ancho * 0.24,
					Color("#f59e0b") if estado != "quemado" else Color("#78350f"))
			"lubina":
				draw_set_transform(centro + Vector2(0.0, bob), 0.0, Vector2.ONE)
				draw_colored_polygon(PackedVector2Array([
					Vector2(-ancho * 0.52, -ancho * 0.16),
					Vector2(ancho * 0.44, -ancho * 0.34),
					Vector2(ancho * 0.56, 0.0),
					Vector2(-ancho * 0.34, ancho * 0.22),
				]), Color("#f1f5f9"))
				draw_polyline(PackedVector2Array([
					Vector2(-ancho * 0.52, -ancho * 0.16),
					Vector2(ancho * 0.44, -ancho * 0.34),
					Vector2(ancho * 0.56, 0.0),
					Vector2(-ancho * 0.34, ancho * 0.22),
					Vector2(-ancho * 0.52, -ancho * 0.16),
				]), Color("#cbd5e1"), 1.5, true)
				draw_circle(Vector2(-ancho * 0.36, -ancho * 0.10), 2.0, Color("#0f172a"))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			_:
				Arte_Cocina.dibujar_ingrediente_icono(self, tipo,
					centro + Vector2(0.0, bob), ancho, 1.0)

		# Barra de punto / ventana de precisión
		var barra := Rect2(8.0, size.y - 14.0, size.x - 16.0, 6.0)
		Arte_Cocina.caja_redondeada(self, barra.grow(1.0), 3.0, Color(0.04, 0.08, 0.12, 0.70))
		if ventana:
			# Franja dorada de la ventana perfecta del horno.
			var x0: float = barra.position.x + barra.size.x * Sistema_Cocina.VENTANA_ALTA_INICIO
			var x1: float = barra.position.x + barra.size.x * Sistema_Cocina.VENTANA_ALTA_FIN
			draw_rect(Rect2(x0, barra.position.y, maxf(2.0, x1 - x0), barra.size.y),
				Color("#fbbf24", 0.80))
			var marca: float = barra.position.x + barra.size.x * clampf(progreso, 0.0, 1.0)
			draw_line(Vector2(marca, barra.position.y - 1.5),
				Vector2(marca, barra.end.y + 1.5), Color.WHITE, 2.0, true)
		else:
			var col_punto := Arte_Cocina.punto_color(punto_vis)
			var p: float = clampf(progreso, 0.0, 1.0)
			draw_rect(Rect2(barra.position, Vector2(barra.size.x * p, barra.size.y)), col_punto)
			var marca2: float = barra.position.x + barra.size.x * p
			draw_line(Vector2(marca2, barra.position.y - 1.5),
				Vector2(marca2, barra.end.y + 1.5), Color.WHITE, 1.6, true)

		# Etiqueta de punto del filete, debajo de la barra para no tapar la carne.
		if tipo == "filete" and punto_vis != "":
			var etiqueta: String = Sistema_Cocina.Punto_Filete_Legible(punto_vis)
			var ancho_e: float = minf(size.x + 12.0, 92.0)
			var r := Rect2(size.x * 0.5 - ancho_e * 0.5, size.y - 1.0, ancho_e, 13.0)
			Arte_Cocina.caja_redondeada(self, r, 4.0, Color(0.08, 0.06, 0.04, 0.86),
				Color(Arte_Cocina.punto_color(punto_vis), 0.85), 1.0)
			draw_string(Arte_Cocina.FUENTE_TIT, Vector2(r.position.x, r.position.y + 10.0),
				etiqueta, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 8, Color("#ffe9b0"))

		if estado == "alerta" or estado == "quemado":
			draw_circle(centro, ancho * 0.46,
				Color(1.0, 0.20, 0.15, 0.16 + 0.12 * (0.5 + 0.5 * sin(tiempo * 10.0))))

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
			if tipo in ["filete", "solomillo", "lubina", "pato", "huevo", "generico"]:
				_dibujar_proteina(centro)
				return
			# Patatas
			var ancho_p: float = minf(size.x * 0.82, 54.0)
			var bob_p: float = sin(tiempo * 5.0) * 1.6 if estado == "cocinando" else 0.0
			bob_p -= sin((1.0 - clampf(flip, 0.0, 1.0)) * PI) * 6.0
			var tinte_p: Color = Color.WHITE
			if estado == "alerta":
				tinte_p = Color.WHITE.lerp(Color(0.55, 0.36, 0.24, 1.0), clampf(quemado, 0.0, 1.0) * 0.65)
			elif estado == "quemado":
				tinte_p = Color(0.32, 0.22, 0.16, 1.0)
			var alto_p: float = ancho_p * float(Arte_Cocina.TEX_PATATAS.get_height()) / maxf(1.0, float(Arte_Cocina.TEX_PATATAS.get_width()))
			var rect_p := Rect2(centro.x - ancho_p * 0.5, centro.y + bob_p - alto_p * 0.5, ancho_p, alto_p)
			draw_texture_rect(Arte_Cocina.TEX_PATATAS, rect_p, false, tinte_p)
			if estado == "alerta" or estado == "quemado":
				var col_alerta := Color(1.0, 0.20, 0.15, 0.18 + 0.14 * (0.5 + 0.5 * sin(tiempo * 10.0)))
				draw_circle(centro, ancho_p * 0.42, col_alerta)
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


class Icono_Item extends Control:
	# Icono reutilizable que dibuja cualquier receta o ingrediente con el
	# mismo lenguaje visual que los tickets y el pase.
	var item_id: String = ""
	var alpha: float = 1.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if size.x <= 2.0 or size.y <= 2.0:
			return
		var lado: float = minf(size.x, size.y)
		Arte_Cocina.dibujar_item(self, item_id, size * 0.5, lado * 0.92, alpha)


class Icono_Mejora extends Control:
	# Icono de la lista de Mejoras. Para el Bistró usa la ilustración
	# procedural del local; para el resto de mundos conserva el PNG del pack.
	var restaurante: String = ""
	var mejora_id: String = ""
	var nivel: int = 1
	var textura: Texture2D = null

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func configurar(rest: String, mejora: String, nv: int, tex: Texture2D = null) -> void:
		restaurante = rest
		mejora_id = mejora
		nivel = clampi(nv, 1, 3)
		textura = tex
		queue_redraw()

	func _draw() -> void:
		if size.x <= 4.0 or size.y <= 4.0:
			return
		if restaurante == Sistema_Cocina.RESTAURANTE_BISTRO:
			var lado: float = minf(size.x, size.y) * 0.94
			Arte_Cocina.dibujar_mejora_bistro(self, size * 0.5, lado,
				mejora_id, nivel)
		elif textura != null:
			var lado_tex: float = minf(size.x, size.y)
			var r := Rect2((size.x - lado_tex) * 0.5, (size.y - lado_tex) * 0.5,
				lado_tex, lado_tex)
			draw_texture_rect(textura, r, false, Color.WHITE)


# ============================================================================
# Bebida con llenado animado
# ============================================================================

class Bebida extends Control:
	var tipo: String = "refresco"
	var estado: String = "listo"
	var progreso: float = 1.0
	var tiempo: float = 0.0
	var pop: float = 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _textura() -> Texture2D:
		match tipo:
			"cafe": return Arte_Cocina.TEX_CAFE
			"agua": return Arte_Cocina.TEX_AGUA
			"zumo": return Arte_Cocina.TEX_ZUMO
			"sangria", "vino_tinto", "vino_blanco": return null
		return Arte_Cocina.TEX_REFRESCO

	func _draw() -> void:
		if size.x <= 4.0 or size.y <= 4.0:
			return
		var caja := Rect2(0, 0, size.x, size.y)
		var tex := _textura()
		var niv: float = clampf(progreso, 0.0, 1.0) if estado == "llenando" else 1.0
		if tex == null:
			# Copas de vino / sangría: se dibujan vectoriales para que el
			# maridaje se lea por color (tinto vs. blanco).
			var tinto: bool = tipo in ["sangria", "vino_tinto"]
			var alpha_copa: float = (0.40 + 0.60 * niv) if estado == "llenando" else 1.0
			Arte_Cocina.dibujar_copa_vino(self, Vector2(size.x * 0.5, size.y * 0.50),
				minf(size.x * 0.92, size.y * 0.90), tinto, alpha_copa)
			if estado == "llenando":
				Arte_Cocina.dibujar_barra(self,
					Rect2(2.0, size.y - 6.0, size.x - 4.0, 5.0), niv, Color("#f472b6"))
			return
		var r := Arte_Cocina.rect_ajustado(tex, caja)

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
				Rect2(2.0, size.y - 6.0, size.x - 4.0, 5.0), niv,
				Color("#38bdf8") if tipo == "refresco" else Color("#fbbf24"))
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
	var estilo: String = ""
	var nombre_visible: String = ""
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
		var dibujo: String = estilo if estilo != "" else ingrediente
		match dibujo:
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
			_:
				_dibujar_generico(caja, dibujo, pulso)
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

	func _dibujar_generico(caja: Rect2, estilo_id: String, pulso: float) -> void:
		# Contenedor neutro de cocina (tabla de madera o bandeja metálica) con
		# el icono vectorial del ingrediente. Da variedad a las despensas de
		# los mundos 2-4 sin convertir cada puesto en una tarjeta de botón.
		var es_bandeja: bool = estilo_id in ["filete_crudo", "solomillo", "lubina", "pato",
			"marisco", "huevo", "salsa"]
		var tabla := Rect2(caja.position.x + 3.0, caja.position.y + 6.0,
			caja.size.x - 6.0, caja.size.y - 4.0)
		_sombra(Vector2(size.x * 0.5, caja.end.y - 1.0), caja.size.x * 0.40, 6.0, 0.27)
		if es_bandeja:
			Arte_Cocina.dibujar_tex_recortada(self, Arte_Cocina.TEX_BANDEJA, tabla)
		else:
			Arte_Cocina.caja_redondeada(self, tabla, 8.0, Color("#7c4a21"), Color("#4a2a12"), 1.5)
			Arte_Cocina.caja_redondeada(self, tabla.grow(-3.0), 6.0, Color("#a86a33"))
			draw_circle(Vector2(tabla.end.x - 12.0, tabla.position.y + 11.0), 4.0,
				Color("#3f240f"))
		# El icono ocupa el centro del recipiente y respira con el hover.
		var lado: float = minf(tabla.size.x * 0.62, tabla.size.y * 0.88)
		var centro := Vector2(tabla.get_center().x, tabla.position.y + tabla.size.y * 0.52)
		Arte_Cocina.dibujar_ingrediente_icono(self, estilo_id, centro, lado, 1.0)
		# Brillo del cristal de la vitrina de postres
		if estilo_id == "tarta":
			draw_arc(Vector2(size.x * 0.5, caja.position.y + 14.0), lado * 0.62,
				PI * 1.10, PI * 1.90, 18, Color(1.0, 1.0, 1.0, 0.30 + 0.10 * pulso), 2.0, true)

	func _dibujar_placa(pulso: float) -> void:
		# Placa pequeña grabada en el estante: nombre del ingrediente, sin
		# convertir el recipiente en un botón.
		var ancho: float = minf(size.x - 14.0, 96.0)
		var r := Rect2(size.x * 0.5 - ancho * 0.5, size.y - 22.0, ancho, 17.0)
		Arte_Cocina.caja_redondeada(self, r, 4.0, Color("#23150b", 0.95),
			Color("#c99a4a", 0.70 + 0.15 * pulso), 1.0)
		draw_rect(Rect2(r.position + Vector2(2.0, 1.5), Vector2(r.size.x - 4.0, 1.2)),
			Color(1.0, 0.90, 0.65, 0.20))
		var nombre: String = nombre_visible
		if nombre == "":
			nombre = str(Arte_Cocina.NOMBRES_INGREDIENTES.get(ingrediente, ingrediente))
		draw_string(Arte_Cocina.FUENTE_TIT, Vector2(r.position.x, r.position.y + 12.5),
			nombre.to_upper(),
			HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 10,
			Color("#ffe9b0") if hover else Color("#e7d8b0"))


# ============================================================================
# Estaciones propias de los mundos 2-4
# ============================================================================

class Estacion_Olla extends Control:
	# Olla de guiso por lotes del mercado: muestra los ingredientes que se han
	# añadido, el progreso de la tanda y las raciones que quedan.
	var ingredientes: Array = []
	var estado: String = "vacio"  # vacio | cocinando | listo
	var progreso: float = 0.0
	var raciones: int = 0
	var receta: String = ""
	var tiempo: float = 0.0
	var pop: float = 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if size.x <= 8.0 or size.y <= 8.0:
			return
		var w: float = size.x
		var h: float = size.y
		var cx: float = w * 0.5
		var base_y: float = h - 14.0
		var pulso: float = 0.5 + 0.5 * sin(tiempo * 4.0)

		# Fogón
		Arte_Cocina.caja_redondeada(self, Rect2(20.0, base_y - 16.0, w - 40.0, 22.0),
			8.0, Color("#1f2937"), Color("#0b1220"), 2.0)
		draw_circle(Vector2(cx, base_y - 8.0), w * 0.26, Color("#f97316", 0.10 + 0.05 * pulso))

		var ancho_olla: float = minf(w * 0.72, 176.0)
		var y_rim: float = 58.0
		var y_bottom: float = base_y - 10.0
		var rx: float = ancho_olla * 0.5

		# Sombra de contacto
		draw_set_transform(Vector2(cx, y_bottom + 2.0), 0.0, Vector2(1.0, 0.24))
		draw_circle(Vector2.ZERO, rx * 1.04, Color(0.0, 0.0, 0.0, 0.30))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

		# Cuerpo de cobre con fondo redondeado
		var cuerpo := PackedVector2Array([
			Vector2(cx - rx, y_rim),
			Vector2(cx + rx, y_rim),
			Vector2(cx + rx * 0.84, y_bottom - 14.0),
			Vector2(cx + rx * 0.50, y_bottom),
			Vector2(cx - rx * 0.50, y_bottom),
			Vector2(cx - rx * 0.84, y_bottom - 14.0),
		])
		draw_colored_polygon(cuerpo, Color("#b45309"))
		# Brillo y sombra del cuerpo
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx - rx * 0.92, y_rim + 10.0),
			Vector2(cx - rx * 0.32, y_rim + 10.0),
			Vector2(cx - rx * 0.30, y_bottom - 18.0),
			Vector2(cx - rx * 0.70, y_bottom - 18.0),
		]), Color("#f59e0b", 0.22))
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx + rx * 0.58, y_rim + 10.0),
			Vector2(cx + rx * 0.90, y_rim + 10.0),
			Vector2(cx + rx * 0.78, y_bottom - 18.0),
			Vector2(cx + rx * 0.60, y_bottom - 18.0),
		]), Color("#7c2d12", 0.35))
		# Aros de cobre
		for frac in [0.35, 0.68]:
			var yy: float = lerpf(y_rim, y_bottom, float(frac))
			draw_line(Vector2(cx - rx * 0.94, yy), Vector2(cx + rx * 0.94, yy),
				Color("#fbbf24", 0.28), 3.0, true)
		draw_polyline(cuerpo, Color("#5b2b12"), 3.0, true)

		# Asas
		draw_arc(Vector2(cx - rx - 1.0, y_rim + 34.0), 14.0, PI * 0.45, PI * 1.55, 14,
			Color("#92400e"), 8.0, true)
		draw_arc(Vector2(cx + rx + 1.0, y_rim + 34.0), 14.0, -PI * 0.55, PI * 0.55, 14,
			Color("#92400e"), 8.0, true)
		draw_arc(Vector2(cx - rx - 1.0, y_rim + 34.0), 14.0, PI * 0.45, PI * 1.55, 14,
			Color("#fbbf24", 0.55), 2.0, true)
		draw_arc(Vector2(cx + rx + 1.0, y_rim + 34.0), 14.0, -PI * 0.55, PI * 0.55, 14,
			Color("#fbbf24", 0.55), 2.0, true)

		# Borde y superficie del guiso
		draw_set_transform(Vector2(cx, y_rim), 0.0, Vector2(1.0, 0.26))
		draw_circle(Vector2.ZERO, rx * 1.02, Color("#d97706"))
		draw_circle(Vector2.ZERO, rx * 0.92, Color("#5b2b12"))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_line(Vector2(cx - rx, y_rim), Vector2(cx + rx, y_rim),
			Color("#fbbf24"), 4.0, true)
		if estado != "vacio":
			var col_guiso := Color("#9a3412")
			if receta == "pisto":
				col_guiso = Color("#b91c1c")
			elif receta == "arroz":
				col_guiso = Color("#eab308")
			draw_set_transform(Vector2(cx, y_rim + 1.0), 0.0, Vector2(1.0, 0.22))
			draw_circle(Vector2.ZERO, rx * 0.84, Color(col_guiso))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			# Tropezones y burbujas
			for k in range(7):
				var a: float = TAU * float(k) / 7.0 + tiempo * 0.5
				var bx: float = cx + cos(a) * rx * 0.44
				var by: float = y_rim + 2.0 + sin(a) * 8.0
				var rr: float = 2.4 + 1.8 * (0.5 + 0.5 * sin(tiempo * 5.0 + float(k)))
				draw_circle(Vector2(bx, by), rr,
					Color(1.0, 0.85, 0.5, 0.55) if receta != "pisto" else Color(0.3, 0.75, 0.25, 0.55))
			# Vapor
			for k in range(3):
				var fase: float = fmod(tiempo * 0.7 + float(k) * 0.33, 1.0)
				var sx: float = cx + sin(tiempo * 1.8 + float(k) * 2.0) * 14.0
				var sy: float = y_rim - 8.0 - fase * 30.0
				draw_circle(Vector2(sx, sy), 4.0 + fase * 6.0,
					Color(1.0, 1.0, 1.0, 0.18 * (1.0 - fase)))

		# Ingredientes añadidos, en fila sobre la olla
		var n: int = ingredientes.size()
		if n > 0:
			var lado: float = 32.0
			var sep: float = 5.0
			var total: float = float(n) * lado + float(n - 1) * sep
			var x0: float = cx - total * 0.5
			for i in range(n):
				var centro_i := Vector2(x0 + lado * 0.5 + float(i) * (lado + sep), 30.0)
				draw_circle(centro_i, lado * 0.60, Color(0.06, 0.09, 0.15, 0.62))
				draw_arc(centro_i, lado * 0.60, 0.0, TAU, 20, Color("#fbbf24", 0.65), 1.5, true)
				Arte_Cocina.dibujar_ingrediente_icono(self, str(ingredientes[i]), centro_i, lado, 1.0)

		# Barra de progreso
		if estado == "cocinando":
			Arte_Cocina.dibujar_barra(self, Rect2(14.0, h - 9.0, w - 28.0, 6.0), progreso,
				Color("#fb923c"))

		# Píldora de raciones
		if estado == "listo" and raciones > 0:
			var pill := Rect2(w - 52.0, 6.0, 44.0, 22.0)
			Arte_Cocina.caja_redondeada(self, pill, 999.0, Color("#166534", 0.95),
				Color("#86efac"), 1.5)
			draw_string(Arte_Cocina.FUENTE_TIT, Vector2(pill.position.x, pill.position.y + 16.0),
				"x%d" % raciones, HORIZONTAL_ALIGNMENT_CENTER, pill.size.x, 13, Color.WHITE)
		# Etiqueta de estado
		var texto: String = "AÑADE 2 INGREDIENTES"
		if estado == "cocinando":
			texto = "COCIENDO…"
		elif estado == "listo":
			texto = "TOCA PARA SERVIR"
		if texto != "":
			draw_string(Arte_Cocina.FUENTE_UI, Vector2(0.0, 13.0), texto,
				HORIZONTAL_ALIGNMENT_CENTER, w, 10, Color("#fde68a", 0.90))


class Sarten_Salsa extends Control:
	var estado: String = "lista"  # lista | arruinada
	var quemado: float = 0.0
	var tiempo: float = 0.0
	var removido: float = 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if size.x <= 8.0 or size.y <= 8.0:
			return
		var w: float = size.x
		var h: float = size.y
		var cx: float = w * 0.5
		var cy: float = h * 0.52
		var pulso: float = 0.5 + 0.5 * sin(tiempo * 5.0)
		var radio: float = minf(w * 0.34, 52.0)

		# Mango
		draw_line(Vector2(cx + radio * 0.85, cy + radio * 0.18),
			Vector2(w - 6.0, cy - radio * 0.30), Color("#1f2937"), 10.0, true)
		draw_line(Vector2(cx + radio * 0.85, cy + radio * 0.18),
			Vector2(w - 6.0, cy - radio * 0.30), Color("#475569"), 5.0, true)
		# Sartén
		draw_circle(Vector2(cx, cy + 3.0), radio + 4.0, Color(0.0, 0.0, 0.0, 0.25))
		draw_circle(Vector2(cx, cy), radio + 2.0, Color("#334155"))
		draw_circle(Vector2(cx, cy), radio, Color("#0f172a"))
		var col_salsa := Color("#7f1d1d")
		if estado == "arruinada":
			col_salsa = Color("#1c1917")
		draw_circle(Vector2(cx, cy), radio * 0.82, col_salsa)
		# Burbujas
		if estado == "lista":
			for k in range(6):
				var a: float = TAU * float(k) / 6.0 + tiempo * 0.6
				var rr: float = radio * (0.12 + 0.16 * (0.5 + 0.5 * sin(tiempo * 4.0 + float(k))))
				draw_circle(Vector2(cx + cos(a) * radio * 0.38, cy + sin(a) * radio * 0.32),
					rr, Color(1.0, 0.45, 0.30, 0.20))
			# Destello de removido
			if removido > 0.02:
				draw_arc(Vector2(cx, cy), radio * (0.45 + 0.30 * (1.0 - removido)),
					0.0, TAU, 24, Color(1.0, 0.9, 0.6, 0.45 * removido), 3.0, true)
		else:
			for k in range(4):
				var fase: float = fmod(tiempo * 0.8 + float(k) * 0.25, 1.0)
				draw_circle(Vector2(cx + sin(tiempo * 1.3 + float(k)) * 12.0,
					cy - 8.0 - fase * 34.0), 5.0 + fase * 6.0,
					Color(0.15, 0.15, 0.15, 0.30 * (1.0 - fase)))
		# Medidor de quemado
		var barra := Rect2(8.0, h - 16.0, w - 16.0, 7.0)
		Arte_Cocina.caja_redondeada(self, barra.grow(1.0), 3.0, Color(0.03, 0.06, 0.10, 0.80))
		var col_barra := Color("#22c55e") if quemado < 0.55 else Color("#f59e0b")
		if quemado >= 0.82:
			col_barra = Color("#ef4444")
		draw_rect(Rect2(barra.position, Vector2(barra.size.x * clampf(quemado, 0.0, 1.0),
			barra.size.y)), col_barra)
		# Aviso de remover
		if estado == "lista" and quemado > 0.35:
			var alpha: float = 0.55 + 0.45 * pulso
			draw_string(Arte_Cocina.FUENTE_TIT, Vector2(0.0, 14.0), "¡REMUEVE!",
				HORIZONTAL_ALIGNMENT_CENTER, w, 11, Color(1.0, 0.85, 0.35, alpha))
		elif estado == "arruinada":
			draw_string(Arte_Cocina.FUENTE_TIT, Vector2(0.0, 14.0), "QUEMADA",
				HORIZONTAL_ALIGNMENT_CENTER, w, 11, Color("#fca5a5"))


class Estacion_Horno extends Control:
	var tiempo: float = 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if size.x <= 8.0 or size.y <= 8.0:
			return
		var w: float = size.x
		var h: float = size.y
		var pulso: float = 0.5 + 0.5 * sin(tiempo * 3.0)
		# Cuerpo de acero con marco dorado
		Arte_Cocina.caja_redondeada(self, Rect2(4.0, 20.0, w - 8.0, h - 28.0), 12.0,
			Color("#475569"), Color("#f5c451"), 2.0)
		Arte_Cocina.caja_redondeada(self, Rect2(10.0, 26.0, w - 20.0, h - 44.0), 9.0,
			Color("#64748b"), Color("#334155"), 1.5)
		# Ventana de cristal con calor interior
		var ventana := Rect2(16.0, 34.0, w - 32.0, h * 0.56)
		Arte_Cocina.caja_redondeada(self, ventana, 8.0, Color("#0b1220"))
		Arte_Cocina.caja_redondeada(self, ventana.grow(-5.0), 6.0,
			Color(0.98, 0.52, 0.18, 0.22 + 0.10 * pulso))
		# Bandeja y proteinas dentro del horno
		var bandeja_y: float = ventana.position.y + ventana.size.y * 0.64
		draw_rect(Rect2(ventana.position.x + 9.0, bandeja_y, ventana.size.x - 18.0, 5.0),
			Color("#cbd5e1", 0.80))
		draw_rect(Rect2(ventana.position.x + 9.0, bandeja_y + 5.0, ventana.size.x - 18.0, 2.0),
			Color(0.0, 0.0, 0.0, 0.28))
		for i in range(2):
			draw_circle(Vector2(ventana.position.x + 34.0 + float(i) * 54.0, bandeja_y - 5.0),
				8.0, Color("#7c2d12", 0.75))
		# Reflejos del cristal
		draw_line(Vector2(ventana.position.x + 10.0, ventana.end.y - 8.0),
			Vector2(ventana.position.x + 44.0, ventana.position.y + 8.0),
			Color(1.0, 1.0, 1.0, 0.18), 3.0, true)
		draw_line(Vector2(ventana.position.x + 30.0, ventana.end.y - 8.0),
			Vector2(ventana.position.x + 64.0, ventana.position.y + 8.0),
			Color(1.0, 1.0, 1.0, 0.10), 2.0, true)
		# Tirador
		draw_line(Vector2(ventana.position.x + 10.0, ventana.position.y - 5.0),
			Vector2(ventana.end.x - 10.0, ventana.position.y - 5.0),
			Color("#e2e8f0"), 5.0, true)
		draw_line(Vector2(ventana.position.x + 10.0, ventana.position.y - 5.0),
			Vector2(ventana.end.x - 10.0, ventana.position.y - 5.0),
			Color("#94a3b8"), 2.0, true)
		# Panel de mandos
		draw_rect(Rect2(12.0, h - 34.0, w - 24.0, 18.0), Color("#1e293b"))
		for i in range(2):
			draw_circle(Vector2(34.0 + float(i) * 34.0, h - 25.0), 8.0, Color("#0f172a"))
			draw_circle(Vector2(34.0 + float(i) * 34.0, h - 25.0), 5.5, Color("#f87171"))
		draw_rect(Rect2(w - 72.0, h - 30.0, 42.0, 10.0), Color("#0f172a"))
		draw_string(Arte_Cocina.FUENTE_UI, Vector2(w - 71.0, h - 21.0), "180°",
			HORIZONTAL_ALIGNMENT_CENTER, 40.0, 8, Color("#fbbf24"))
		# Etiqueta superior
		draw_string(Arte_Cocina.FUENTE_UI, Vector2(0.0, 12.0), "HORNO",
			HORIZONTAL_ALIGNMENT_CENTER, w, 9, Color("#fde68a", 0.90))


class Estacion_Botellas extends Control:
	var tipo: String = "barra"  # barra | bodega
	var tiempo: float = 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if size.x <= 8.0 or size.y <= 8.0:
			return
		var w: float = size.x
		var h: float = size.y
		var madera := Color("#4a2a12") if tipo == "barra" else Color("#1f2937")
		var brillo := Color("#a86a33") if tipo == "barra" else Color("#334155")
		# Estante
		Arte_Cocina.caja_redondeada(self, Rect2(6.0, h - 42.0, w - 12.0, 12.0), 4.0, madera, brillo, 1.5)
		Arte_Cocina.caja_redondeada(self, Rect2(6.0, h * 0.40, w - 12.0, 10.0), 4.0, madera, brillo, 1.5)
		# Botellas
		var colores := [Color("#7f1d1d"), Color("#166534"), Color("#b45309")]
		if tipo == "bodega":
			colores = [Color("#7f1d1d"), Color("#e7d8a8"), Color("#450a0a")]
		for i in range(3):
			var bx: float = 20.0 + float(i) * (w - 40.0) / 2.0
			var by: float = h - 42.0
			draw_rect(Rect2(bx - 6.0, by - 34.0, 12.0, 22.0), colores[i])
			draw_rect(Rect2(bx - 6.0, by - 34.0, 12.0, 6.0), Color(0.06, 0.09, 0.15, 0.35))
			draw_rect(Rect2(bx - 3.0, by - 48.0, 6.0, 15.0), Color("#166534"))
			draw_circle(Vector2(bx, by - 49.0), 4.0, Color("#fbbf24", 0.55))
		# Copas en el estante superior
		for i in range(2):
			draw_arc(Vector2(w * 0.30 + float(i) * w * 0.28, h * 0.40 - 10.0), 8.0,
				PI, TAU, 12, Color(0.85, 0.94, 1.0, 0.65), 2.0, true)
			draw_line(Vector2(w * 0.30 + float(i) * w * 0.28, h * 0.40 - 2.0),
				Vector2(w * 0.30 + float(i) * w * 0.28, h * 0.40 + 5.0),
				Color(0.85, 0.94, 1.0, 0.65), 2.0, true)
		draw_string(Arte_Cocina.FUENTE_UI, Vector2(0.0, 14.0),
			"BODEGA" if tipo == "bodega" else "BEBIDAS",
			HORIZONTAL_ALIGNMENT_CENTER, w, 10, Color("#fde68a", 0.90))


# ============================================================================
# Mueble bajo la encimera donde se guardan los ingredientes
# ============================================================================

class Fondo_Despensa extends Control:
	var color_frente: Color = Color("#123e40")

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func configurar(color: Color) -> void:
		color_frente = color
		queue_redraw()

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		if w <= 8.0 or h <= 8.0:
			return

		# Zócalo de acero bajo el frente del mostrador.
		draw_rect(Rect2(0.0, 0.0, w, 8.0), Color("#8fa3b5"))
		draw_rect(Rect2(0.0, 0.0, w, 2.5), Color("#e2e8f0"))
		draw_rect(Rect2(0.0, 7.0, w, 1.5), Color("#334155", 0.80))

		# Frente de armario tintado a juego con el local.
		draw_rect(Rect2(0.0, 8.0, w, h - 8.0), color_frente)
		draw_rect(Rect2(0.0, 8.0, w, h * 0.42), Color(color_frente.darkened(0.35), 0.55))
		draw_rect(Rect2(0.0, 8.0, w, 4.0), Color(1.0, 0.75, 0.38, 0.10))

		# Costuras del mueble y remaches.
		for x in [318.0, 586.0, 892.0, 1122.0]:
			draw_line(Vector2(x, 13.0), Vector2(x, h - 27.0),
				Color(color_frente.darkened(0.55), 0.80), 2.0)
			draw_line(Vector2(x + 2.0, 13.0), Vector2(x + 2.0, h - 27.0),
				Color(color_frente.lightened(0.35), 0.35), 1.0)
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
