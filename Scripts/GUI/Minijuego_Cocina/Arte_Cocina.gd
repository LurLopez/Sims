class_name Arte_Cocina
extends RefCounted

# ============================================================================
# Capa de arte del Minijuego de Cocina basada en el pack de sprites PNG
# (Imagenes/Minijuego_Cocina). Incluye:
#   · Registro central de texturas.
#   · Composición por capas de hamburguesas (pan, carne, queso, lechuga...).
#   · Controles dibujados a mano para clientes, tickets, platos, cocción,
#     bebidas, bandeja de ingredientes y partículas animadas.
# Todos los controles internos usan MOUSE_FILTER_IGNORE: la interacción la
# gestiona Arrastre_Cocina para permitir arrastrar y soltar con el dedo.
# ============================================================================

const FUENTE_UI := preload("res://Fuentes/UI/DMSans-700.ttf")
const FUENTE_TIT := preload("res://Fuentes/UI/Bricolage-800.ttf")

# --- Escenario y mobiliario -------------------------------------------------
const TEX_FONDO := preload("res://Imagenes/Minijuego_Cocina/Fondo_Restaurante.png")
const TEX_PLANCHA := preload("res://Imagenes/Minijuego_Cocina/Estaciones/Plancha.png")
const TEX_FREIDORA := preload("res://Imagenes/Minijuego_Cocina/Estaciones/Freidora.png")
const TEX_REFRESCOS := preload("res://Imagenes/Minijuego_Cocina/Estaciones/Dispensador_Refrescos.png")
const TEX_PAPELERA := preload("res://Imagenes/Minijuego_Cocina/Estaciones/Papelera.png")
const TEX_TICKET_VERDE := preload("res://Imagenes/Minijuego_Cocina/UI/Ticket_Verde.png")
const TEX_TICKET_ROJO := preload("res://Imagenes/Minijuego_Cocina/UI/Ticket_Rojo.png")

# --- Comida -----------------------------------------------------------------
const TEX_PAN_INF := preload("res://Imagenes/Minijuego_Cocina/Comida/Ingredientes/Pan_Inferior.png")
const TEX_PAN_SUP := preload("res://Imagenes/Minijuego_Cocina/Comida/Ingredientes/Pan_Superior.png")
const TEX_CARNE_CRUDA := preload("res://Imagenes/Minijuego_Cocina/Comida/Ingredientes/Carne_Cruda.png")
const TEX_CARNE_HECHA := preload("res://Imagenes/Minijuego_Cocina/Comida/Ingredientes/Carne_Hecha.png")
const TEX_CARNE_QUEMADA := preload("res://Imagenes/Minijuego_Cocina/Comida/Ingredientes/Carne_Quemada.png")
const TEX_QUESO := preload("res://Imagenes/Minijuego_Cocina/Comida/Ingredientes/Queso.png")
const TEX_LECHUGA := preload("res://Imagenes/Minijuego_Cocina/Comida/Ingredientes/Lechuga.png")
const TEX_TOMATE := preload("res://Imagenes/Minijuego_Cocina/Comida/Ingredientes/Tomate.png")
const TEX_PATATAS := preload("res://Imagenes/Minijuego_Cocina/Comida/Platos/Patatas_Fritas.png")
const TEX_REFRESCO := preload("res://Imagenes/Minijuego_Cocina/Comida/Platos/Refresco_Cola.png")
const TEX_PLATO := preload("res://Imagenes/Minijuego_Cocina/Emplatado/Plato_Vacio.png")
const TEX_BANDEJA := preload("res://Imagenes/Minijuego_Cocina/Emplatado/Bandeja_Metal.png")
const TEX_CESTA := preload("res://Imagenes/Minijuego_Cocina/Emplatado/Cesta_Patatas.png")
const TEX_VASOS := preload("res://Imagenes/Minijuego_Cocina/Emplatado/Vasos_Rojos.png")

# --- Interfaz ---------------------------------------------------------------
const TEX_MONEDA := preload("res://Imagenes/Minijuego_Cocina/UI/Moneda.png")
const TEX_PILA_MONEDAS := preload("res://Imagenes/Minijuego_Cocina/UI/Pila_Monedas.png")
const TEX_RELOJ := preload("res://Imagenes/Minijuego_Cocina/UI/Reloj.png")
const TEX_ESTRELLA := preload("res://Imagenes/Minijuego_Cocina/UI/Estrella_Dorada.png")
const TEX_ESTRELLA_VACIA := preload("res://Imagenes/Minijuego_Cocina/UI/Estrella_Vacia.png")
const TEX_CORAZON := preload("res://Imagenes/Minijuego_Cocina/UI/Corazon.png")
const TEX_BOTE_PROPINAS := preload("res://Imagenes/Minijuego_Cocina/UI/Bote_Propinas.png")
const TEX_FLECHA := preload("res://Imagenes/Minijuego_Cocina/UI/Flecha.png")

# --- Efectos ----------------------------------------------------------------
const TEX_VAPOR := preload("res://Imagenes/Minijuego_Cocina/Efectos/Vapor.png")
const TEX_HUMO := preload("res://Imagenes/Minijuego_Cocina/Efectos/Humo.png")
const TEX_FUEGO := preload("res://Imagenes/Minijuego_Cocina/Efectos/Fuego.png")
const TEX_CHISPAS := preload("res://Imagenes/Minijuego_Cocina/Efectos/Chispas.png")
const TEX_MONEDAS := preload("res://Imagenes/Minijuego_Cocina/Efectos/Monedas.png")
const TEX_ESTRELLAS := preload("res://Imagenes/Minijuego_Cocina/Efectos/Estrellas.png")
const TEX_ENFADO := preload("res://Imagenes/Minijuego_Cocina/Efectos/Enfado.png")
const TEX_FRESCURA := preload("res://Imagenes/Minijuego_Cocina/Efectos/Frescura.png")

# --- Personajes -------------------------------------------------------------
const CLIENTES: Array[Texture2D] = [
	preload("res://Imagenes/Minijuego_Cocina/Clientes/Cliente_01_Nino.png"),
	preload("res://Imagenes/Minijuego_Cocina/Clientes/Cliente_02_Mujer.png"),
	preload("res://Imagenes/Minijuego_Cocina/Clientes/Cliente_03_Mayor.png"),
	preload("res://Imagenes/Minijuego_Cocina/Clientes/Cliente_04_Nina.png"),
	preload("res://Imagenes/Minijuego_Cocina/Clientes/Cliente_05_Ejecutivo.png"),
	preload("res://Imagenes/Minijuego_Cocina/Clientes/Cliente_06_Abuela.png"),
	preload("res://Imagenes/Minijuego_Cocina/Clientes/Cliente_07_Adolescente.png"),
	preload("res://Imagenes/Minijuego_Cocina/Clientes/Cliente_08_Nina_Pequena.png"),
]

const CLIENTES_ENOJADOS: Array[Texture2D] = [
	preload("res://Imagenes/Minijuego_Cocina/Clientes/Enojados/Cliente_01_Nino_Enojado.png"),
	preload("res://Imagenes/Minijuego_Cocina/Clientes/Enojados/Cliente_02_Mujer_Enojado.png"),
	preload("res://Imagenes/Minijuego_Cocina/Clientes/Enojados/Cliente_03_Mayor_Enojado.png"),
	preload("res://Imagenes/Minijuego_Cocina/Clientes/Enojados/Cliente_04_Nina_Enojado.png"),
	preload("res://Imagenes/Minijuego_Cocina/Clientes/Enojados/Cliente_05_Ejecutivo_Enojado.png"),
	preload("res://Imagenes/Minijuego_Cocina/Clientes/Enojados/Cliente_06_Abuela_Enojado.png"),
	preload("res://Imagenes/Minijuego_Cocina/Clientes/Enojados/Cliente_07_Adolescente_Enojado.png"),
	preload("res://Imagenes/Minijuego_Cocina/Clientes/Enojados/Cliente_08_Nina_Pequena_Enojado.png"),
]

const CHEF_POSES: Dictionary = {
	"neutral": preload("res://Imagenes/Minijuego_Cocina/Chef/Chef_Michelle.png"),
	"cruzado": preload("res://Imagenes/Minijuego_Cocina/Chef/Poses/Chef_Brazos_Cruzados.png"),
	"celebra": preload("res://Imagenes/Minijuego_Cocina/Chef/Poses/Chef_Celebrando.png"),
	"enfadada": preload("res://Imagenes/Minijuego_Cocina/Chef/Poses/Chef_Enfadada.png"),
	"pulgar": preload("res://Imagenes/Minijuego_Cocina/Chef/Poses/Chef_Pulgar_Arriba.png"),
	"sirviendo": preload("res://Imagenes/Minijuego_Cocina/Chef/Poses/Chef_Sirviendo.png"),
	"sorprendida": preload("res://Imagenes/Minijuego_Cocina/Chef/Poses/Chef_Sorprendida.png"),
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


static func textura_cliente(variante: int, enojado: bool) -> Texture2D:
	var idx: int = posmod(variante, CLIENTES.size())
	return CLIENTES_ENOJADOS[idx] if enojado else CLIENTES[idx]


static func textura_chef(pose: String) -> Texture2D:
	return CHEF_POSES.get(pose, CHEF_POSES["neutral"])


static func textura_item(item_id: String) -> Texture2D:
	match item_id:
		"pan":
			return TEX_PAN_INF
		"carne", "carne_lista", "carne_hecha":
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
	var rad: float = clampf(radio, 0.0, minf(rect.size.x, rect.size.y) * 0.5)
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
		var ancho: float = maxf(3.0, (rect.size.x - 2.0) * v)
		caja_redondeada(c, Rect2(rect.position + Vector2(1.0, 1.0), Vector2(ancho, rect.size.y - 2.0)),
			(rect.size.y - 2.0) * 0.5, color)


# ============================================================================
# Composición de hamburguesas por capas con los PNG de ingredientes
# ============================================================================

static func alto_hamburguesa(ancho: float, carnes: int, queso: bool,
		lechuga: bool, tomate: bool) -> float:
	var y: float = 32.0
	if carnes >= 2:
		y += 22.0 * float(carnes - 1)
	if queso:
		y += 20.0
	if lechuga:
		y += 12.0
	if tomate:
		y += 10.0
	y += 16.0 + 76.0
	return y * (ancho / 120.0)


static func ancho_para_alto(alto: float, carnes: int, queso: bool,
		lechuga: bool, tomate: bool) -> float:
	var ancho: float = 120.0
	if ancho <= 0.0:
		return 0.0
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
	c.draw_set_transform(base, 0.0, Vector2(escala_pop, escala_pop))
	c.draw_circle(Vector2(0.0, -2.0 * u), 52.0 * u, Color(0.0, 0.0, 0.0, 0.10 * alpha))

	_dibujar_capa(c, TEX_PAN_INF, 120.0 * u, -0.0 * u, col)

	var carnes_ok: int = maxi(0, carnes)
	for i in range(carnes_ok):
		var y_bottom: float = (30.0 + 22.0 * float(i)) * u
		_dibujar_capa(c, TEX_CARNE_HECHA, 122.0 * u, -y_bottom, col)

	var y_cap: float = 30.0
	if carnes_ok >= 2:
		y_cap += 22.0 * float(carnes_ok - 1)
	if carnes_ok <= 0:
		y_cap = 16.0
	if queso:
		y_cap += 20.0
		_dibujar_capa(c, TEX_QUESO, 132.0 * u, -(y_cap + 4.0) * u, col)
	if lechuga:
		y_cap += 12.0
		_dibujar_capa(c, TEX_LECHUGA, 136.0 * u, -(y_cap + 2.0) * u, col)
	if tomate:
		y_cap += 10.0
		_dibujar_capa(c, TEX_TOMATE, 124.0 * u, -(y_cap + 2.0) * u, col)
	y_cap += 16.0
	_dibujar_capa(c, TEX_PAN_SUP, 120.0 * u, -y_cap * u, col)

	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _dibujar_capa(c: CanvasItem, tex: Texture2D, ancho: float, abajo_y: float,
		col: Color) -> void:
	var alto: float = ancho * float(tex.get_height()) / maxf(1.0, float(tex.get_width()))
	var r := Rect2(-ancho * 0.5, abajo_y - alto, ancho, alto)
	c.draw_texture_rect(tex, r, false, col)


static func dibujar_plato_hamburguesa(c: CanvasItem, centro: Vector2, ancho_plato: float,
		tiene_pan: bool, carnes: int, queso: bool, lechuga: bool, tomate: bool,
		alpha: float = 1.0, escala_pop: float = 1.0) -> void:
	if ancho_plato <= 2.0:
		return
	var alto_plato: float = ancho_plato * float(TEX_PLATO.get_height()) / float(TEX_PLATO.get_width())
	var r := Rect2(centro.x - ancho_plato * 0.5, centro.y - alto_plato * 0.5, ancho_plato, alto_plato)
	c.draw_texture_rect(TEX_PLATO, r, false, Color(1.0, 1.0, 1.0, alpha))
	if not tiene_pan:
		return
	var ancho_burger: float = ancho_plato * 0.62
	var base := Vector2(centro.x, centro.y + alto_plato * 0.16)
	dibujar_hamburguesa(c, base, ancho_burger, true, carnes, queso, lechuga, tomate, alpha, escala_pop)


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
	var alto: float = caja
	var ancho: float = ancho_para_alto(alto, carnes, queso, lechuga, tomate)
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
		var desliz: float = (1.0 - clampf(entrando, 0.0, 1.0)) * 26.0
		var desvio: float = sin(tiempo * 32.0) * 3.2 if ratio < 0.22 else 0.0
		var caja := Rect2(0.0, bob + desliz, size.x, size.y)
		if enojado and ratio < 0.30:
			caja.position.x += desvio
		var r := Arte_Cocina.rect_ajustado(tex, caja)
		var mod := Color(1.0, 1.0, 1.0, clampf(entrando, 0.0, 1.0))
		draw_texture_rect(tex, r, false, mod)

		# Pequeño "pop" de brillo al recibir comida
		if rebote > 0.05:
			draw_circle(Vector2(size.x * 0.5, size.y * 0.42), 34.0 * rebote,
				Color(1.0, 0.95, 0.55, 0.30 * rebote))


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
		if size.x <= 4.0 or size.y <= 4.0:
			return
		var bajo: bool = ratio < 0.35
		var tex: Texture2D = Arte_Cocina.TEX_TICKET_ROJO if bajo else Arte_Cocina.TEX_TICKET_VERDE
		var alto_barra: float = 12.0
		var caja_ticket := Rect2(0.0, 0.0, size.x, size.y - alto_barra - 3.0)
		if bajo:
			caja_ticket.position.x += sin(tiempo * 26.0) * 2.0
		if destacado:
			Arte_Cocina.caja_redondeada(self, caja_ticket.grow(4.0), 12.0,
				Color(0.22, 0.85, 0.45, 0.22 + 0.12 * sin(tiempo * 8.0)),
				Color("#4ade80"), 3.0)
		var r := Arte_Cocina.dibujar_tex(self, tex, caja_ticket)
		if bajo:
			var pulso: float = 0.10 + (sin(tiempo * 10.0) * 0.5 + 0.5) * 0.12
			Arte_Cocina.caja_redondeada(self, r.grow(2.0), 12.0, Color(1.0, 0.15, 0.15, pulso))

		# Iconos del pedido en fila sobre el papel
		var n: int = items.size()
		if n > 0:
			var icono: float = 42.0 if n == 1 else (34.0 if n == 2 else 28.0)
			var sep: float = 3.0
			var total: float = icono * float(n) + sep * float(n - 1)
			var x0: float = r.position.x + (r.size.x - total) * 0.5
			var cy: float = r.position.y + r.size.y * 0.50
			for i in range(n):
				var cx: float = x0 + icono * 0.5 + float(i) * (icono + sep)
				var hecho: bool = i < entregados.size() and bool(entregados[i])
				Arte_Cocina.dibujar_item(self, str(items[i]), Vector2(cx, cy), icono,
					0.35 if hecho else 1.0, tiempo)
				if hecho:
					draw_circle(Vector2(cx + icono * 0.34, cy - icono * 0.34), 8.5, Color("#16a34a"))
					draw_polyline(PackedVector2Array([
						Vector2(cx + icono * 0.34 - 4.0, cy - icono * 0.34),
						Vector2(cx + icono * 0.34 - 1.0, cy - icono * 0.34 + 3.0),
						Vector2(cx + icono * 0.34 + 4.0, cy - icono * 0.34 - 3.5),
					]), Color.WHITE, 2.2, true)

		# Barra de paciencia con corazón
		var barra := Rect2(0.0, size.y - alto_barra, size.x, alto_barra)
		var cor_rect := Rect2(barra.position.x, barra.position.y - 1.0, alto_barra, alto_barra)
		Arte_Cocina.dibujar_tex(self, Arte_Cocina.TEX_CORAZON, cor_rect)
		var relleno_rect := Rect2(cor_rect.end.x + 2.0, barra.position.y + 1.0,
			barra.size.x - cor_rect.size.x - 2.0, barra.size.y - 2.0)
		var col: Color = Color("#22c55e")
		if ratio < 0.25:
			col = Color("#ef4444")
		elif ratio < 0.50:
			col = Color("#f59e0b")
		Arte_Cocina.dibujar_barra(self, relleno_rect, ratio, col, Color(0.06, 0.09, 0.15, 0.72))


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
		if size.x <= 4.0 or size.y <= 4.0:
			return
		var pop_esc: float = 1.0 + sin(clampf(pop, 0.0, 1.0) * PI) * 0.10
		var centro := size * 0.5
		var ancho_plato: float = minf(size.x * 0.94, size.y * 0.90)
		var box_plato := Rect2(centro - Vector2(ancho_plato, ancho_plato) * 0.5,
			Vector2(ancho_plato, ancho_plato))
		if not pan:
			# Plato vacío con invitación a colocar pan
			var r := Arte_Cocina.dibujar_tex(self, Arte_Cocina.TEX_PLATO, box_plato, Color(1, 1, 1, 0.62))
			draw_arc(r.get_center() + Vector2(0, -2), r.size.x * 0.12, 0.0, TAU, 20,
				Color(0.35, 0.41, 0.5, 0.45), 2.0, true)
			draw_line(r.get_center() + Vector2(-r.size.x * 0.07, -2),
				r.get_center() + Vector2(r.size.x * 0.07, -2), Color(0.35, 0.41, 0.5, 0.45), 2.0, true)
			draw_line(r.get_center() + Vector2(0, -2 - r.size.x * 0.07),
				r.get_center() + Vector2(0, -2 + r.size.x * 0.07), Color(0.35, 0.41, 0.5, 0.45), 2.0, true)
		else:
			Arte_Cocina.dibujar_plato_hamburguesa(self, centro, ancho_plato,
				pan, carnes, queso, lechuga, tomate, 1.0, pop_esc)

		var borde_col := Color.TRANSPARENT
		var grosor := 0.0
		if pedida:
			borde_col = Color("#22c55e")
			grosor = 3.0
		elif seleccionado:
			borde_col = Color("#f59e0b")
			grosor = 2.5
		if borde_col.a > 0.01:
			Arte_Cocina.caja_redondeada(self, Rect2(2, 2, size.x - 4, size.y - 4), 12.0,
				Color(borde_col, 0.10 + 0.05 * sin(tiempo * 5.0)), borde_col, grosor)

		if pedida:
			var pulso: float = 0.5 + 0.5 * sin(tiempo * 6.0)
			Arte_Cocina.caja_redondeada(self, Rect2(2, 2, size.x - 4, size.y - 4), 12.0,
				Color(0.13, 0.77, 0.37, 0.10 + 0.10 * pulso), Color("#4ade80"), 2.0)
			var check_c := Vector2(size.x - 15.0, 15.0)
			draw_circle(check_c, 10.0, Color("#16a34a"))
			draw_polyline(PackedVector2Array([
				check_c + Vector2(-4.5, 0.0), check_c + Vector2(-1.0, 3.5), check_c + Vector2(4.5, -4.0)
			]), Color.WHITE, 2.5, true)


# ============================================================================
# Punto de cocción (plancha o cesta de freidora)
# ============================================================================

class Punto_Coccion extends Control:
	var tipo: String = "carne"
	var estado: String = "vacio"
	var progreso: float = 0.0
	var quemado: float = 0.0
	var tiempo: float = 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if size.x <= 4.0 or size.y <= 4.0:
			return
		var centro := size * 0.5
		if estado == "vacio":
			var rx: float = size.x * 0.30
			draw_arc(centro, rx, 0.0, TAU, 24, Color(0.30, 0.36, 0.44, 0.30), 1.6, true)
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
			if alpha_cruda > 0.02:
				Arte_Cocina.dibujar_tex_centro(self, Arte_Cocina.TEX_CARNE_CRUDA,
					centro + Vector2(0, y_bob), ancho, alpha_cruda)
			if alpha_hecha > 0.02:
				Arte_Cocina.dibujar_tex_centro(self, Arte_Cocina.TEX_CARNE_HECHA,
					centro + Vector2(0, y_bob), ancho, alpha_hecha)
			if alpha_quemada > 0.02:
				Arte_Cocina.dibujar_tex_centro(self, Arte_Cocina.TEX_CARNE_QUEMADA,
					centro + Vector2(0, y_bob), ancho, alpha_quemada)

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
			draw_texture_rect(tex, r, false, Color(1, 1, 1, 0.22))
			if niv > 0.02:
				var src_h: float = float(tex.get_height()) * niv
				var src := Rect2(0.0, float(tex.get_height()) - src_h, float(tex.get_width()), src_h)
				var dst := Rect2(r.position.x, r.position.y + r.size.y - r.size.y * niv,
					r.size.x, r.size.y * niv)
				draw_texture_rect_region(tex, dst, src, Color(1, 1, 1, 1))
			# Chorro desde la boquilla
			var chorro_x: float = r.position.x + r.size.x * 0.5
			draw_line(Vector2(chorro_x, r.position.y - 10.0), Vector2(chorro_x, r.position.y + 4.0),
				Color(0.25, 0.10, 0.03, 0.85), 3.0, true)
			for k in range(3):
				var fase: float = fmod(tiempo * 2.0 + float(k) * 0.33, 1.0)
				draw_circle(Vector2(chorro_x + sin(tiempo * 7.0 + k) * 3.0,
					r.position.y + r.size.y * 0.55 - fase * r.size.y * 0.35),
					1.5, Color(1.0, 0.9, 0.5, 0.5 * (1.0 - fase)))
			Arte_Cocina.dibujar_barra(self,
				Rect2(2.0, size.y - 6.0, size.x - 4.0, 5.0), niv, Color("#38bdf8"))
		else:
			draw_texture_rect(tex, r, false, Color.WHITE)
			var pulso: float = 0.5 + 0.5 * sin(tiempo * 5.0)
			draw_circle(Vector2(size.x * 0.5, size.y * 0.44),
				r.size.x * (0.38 + 0.06 * pulso), Color(0.35, 0.85, 1.0, 0.10 + 0.06 * pulso))


# ============================================================================
# Slots de la bandeja inferior de ingredientes
# ============================================================================

class Bandeja_Item extends Control:
	var ingrediente: String = "pan"
	var textura: Texture2D
	var hover: bool = false
	var tiempo: float = 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if size.x <= 4.0 or size.y <= 4.0:
			return
		var levante: float = -2.0 if hover else 0.0
		var caja := Rect2(0, levante, size.x, size.y)
		var relleno := Color(0.10, 0.06, 0.03, 0.72)
		var borde := Color(0.55, 0.30, 0.10, 0.85)
		if hover:
			relleno = Color(0.22, 0.12, 0.04, 0.90)
			borde = Color("#fbbf24")
		Arte_Cocina.caja_redondeada(self, Rect2(caja.position, caja.size), 12.0,
			relleno, borde, 2.0 if hover else 1.5)
		Arte_Cocina.dibujar_tex(self, textura,
			Rect2(caja.position.x + 6.0, caja.position.y + 5.0, 86.0, size.y - 12.0))
		draw_string(Arte_Cocina.FUENTE_TIT,
			Vector2(caja.position.x + 96.0, caja.position.y + size.y * 0.47),
			str(Arte_Cocina.NOMBRES_INGREDIENTES.get(ingrediente, ingrediente)),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#fde68a"))
		draw_string(Arte_Cocina.FUENTE_UI,
			Vector2(caja.position.x + 96.0, caja.position.y + size.y * 0.70),
			"arrastra", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.55))


# ============================================================================
# Capa de partículas (vapor, humo, chispas, estrellas, enfado)
# ============================================================================

class Capa_Efectos extends Control:
	var _particulas: Array[Dictionary] = []
	const MAX_PARTICULAS: int = 240

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_process(true)

	func emitir(tex: Texture2D, pos: Vector2, vel: Vector2, vida: float,
			escala0: float, escala1: float, rot: float = 0.0,
			giro: float = 0.0, alpha: float = 1.0, gravedad: float = 0.0) -> void:
		if tex == null:
			return
		if _particulas.size() >= MAX_PARTICULAS:
			_particulas.pop_front()
		_particulas.append({
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
				randf_range(-6, 6), 0.95, 160.0)

	func fuego(pos: Vector2) -> void:
		emitir(Arte_Cocina.TEX_FUEGO, pos + Vector2(randf_range(-5, 5), 0),
			Vector2(randf_range(-6, 6), randf_range(-26, -14)),
			randf_range(0.22, 0.38), 0.07, 0.15, 0.0, 0.0, 0.75)

	func estrellas(pos: Vector2, n: int = 7) -> void:
		for _i in range(n):
			var ang: float = randf() * TAU
			var vel: Vector2 = Vector2(cos(ang), sin(ang)) * randf_range(40, 130) + Vector2(0, -40)
			emitir(Arte_Cocina.TEX_ESTRELLAS, pos, vel, randf_range(0.5, 0.9),
				0.10, 0.22, randf() * TAU, randf_range(-4, 4), 0.95, 180.0)

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
			randf_range(0.5, 0.8), 0.12, 0.24, 0.0, 0.6, 0.85)

	func limpiar() -> void:
		_particulas.clear()
		queue_redraw()

	func _process(delta: float) -> void:
		if _particulas.is_empty():
			return
		var vivas: Array[Dictionary] = []
		for p in _particulas:
			p["vida"] = float(p["vida"]) - delta
			if float(p["vida"]) <= 0.0:
				continue
			p["vel"] = (p["vel"] as Vector2) + Vector2(0.0, float(p["grav"])) * delta
			p["pos"] = (p["pos"] as Vector2) + (p["vel"] as Vector2) * delta
			p["rot"] = float(p["rot"]) + float(p["giro"]) * delta
			vivas.append(p)
		_particulas = vivas
		queue_redraw()

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
