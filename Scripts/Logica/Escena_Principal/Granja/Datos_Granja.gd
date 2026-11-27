class_name Datos_Granja
extends RefCounted

# ============================================================================
# Catálogo y matemática pura de «La Granja» (Versión 3 — Lienzo libre 24×24).
#
# Mapa isométrico libre de 24×24 unidades de terreno (hasta 576 u²) donde cada
# elemento ocupa su huella real (p. ej. parcela de cultivo 2×2, gallina 2×2,
# vaca 3×3, quesería 3×3, panadería 4×3 rotable a 3×4, molino 4×4).
# Sin límites por tipo: el único límite es el terreno desbloqueado, que se
# amplía con MG. Todo objeto colocado puede moverse gratis o venderse al 50 %.
# ============================================================================

const VERSION_ESTADO: int = 3
const PRECIO_COMPRA: int = 1500
const MONEDAS_INICIALES: int = 100

# Lienzo isométrico libre de 24×24 unidades de terreno (576 u² totales).
const GRID_ANCHO: int = 24
const GRID_ALTO: int = 24
const AREA_TOTAL: int = GRID_ANCHO * GRID_ALTO

# Coste de construir una parcela de tierra cultivable (2×2) y % de reembolso.
const PRECIO_PARCELA_TIERRA: int = 40
const TAMANO_TIERRA := Vector2i(2, 2)
const PORCENTAJE_REEMBOLSO: float = 0.50

# Niveles de terreno desbloqueado (rectángulos inclusivos en el mapa 24×24).
const NIVELES_TERRENO: Array[Dictionary] = [
	{"nivel": 0, "nombre": "Prado inicial", "x_min": 6, "x_max": 17, "y_min": 6, "y_max": 17, "area": 144, "etiqueta": "12×12"},
	{"nivel": 1, "nombre": "Ampliación I", "x_min": 4, "x_max": 19, "y_min": 5, "y_max": 18, "area": 224, "etiqueta": "16×14"},
	{"nivel": 2, "nombre": "Ampliación II", "x_min": 3, "x_max": 20, "y_min": 3, "y_max": 20, "area": 324, "etiqueta": "18×18"},
	{"nivel": 3, "nombre": "Ampliación III", "x_min": 1, "x_max": 22, "y_min": 2, "y_max": 21, "area": 440, "etiqueta": "22×20"},
	{"nivel": 4, "nombre": "Ampliación IV", "x_min": 0, "x_max": 23, "y_min": 0, "y_max": 23, "area": 576, "etiqueta": "24×24"},
]
const NIVEL_TERRENO_MAX: int = 4

# --- Conversión diaria -------------------------------------------------------
# Primeros 10 MG del día a 1:1. A partir de ahí la tasa marginal empieza en 0,5
# y decae en logarítmico. La tasa mínima es 0,10.
const CONVERSION_TRAMO_INICIAL: int = 10
const CONVERSION_TASA_INICIAL: float = 1.0
const CONVERSION_TASA_DESPUES: float = 0.5
const CONVERSION_ESCALA_LOG: float = 50.0
const CONVERSION_TASA_MINIMA: float = 0.10
const HORA_RESET: int = 4

# --- Cultivos ----------------------------------------------------------------
const CULTIVOS: Dictionary = {
	"trigo": {
		"nombre": "Trigo",
		"coste": 5,
		"venta": 12,
		"horas": 2.0,
		"color": "#eab308",
		"uso": "Alimenta Vaca y Molino",
	},
	"zanahoria": {
		"nombre": "Zanahoria",
		"coste": 8,
		"venta": 22,
		"horas": 4.0,
		"color": "#f97316",
		"uso": "Venta directa muy rentable",
	},
	"maiz": {
		"nombre": "Maíz",
		"coste": 12,
		"venta": 35,
		"horas": 6.0,
		"color": "#facc15",
		"uso": "Alimenta Gallina",
	},
}

# --- Productos ---------------------------------------------------------------
const PRODUCTOS: Dictionary = {
	"huevo": {"nombre": "Huevo", "venta": 10, "color": "#fef3c7"},
	"leche": {"nombre": "Leche", "venta": 14, "color": "#f8fafc"},
	"harina": {"nombre": "Harina", "venta": 35, "color": "#f5e6c8"},
	"pan": {"nombre": "Pan", "venta": 75, "color": "#d97706"},
	"queso": {"nombre": "Queso", "venta": 65, "color": "#fde68a"},
}

# --- Animales ----------------------------------------------------------------
const ANIMALES: Dictionary = {
	"gallina": {
		"nombre": "Gallina",
		"precio": 150,
		"tamano": Vector2i(2, 2),
		"rotable": false,
		"come": "maiz",
		"cantidad_come": 1,
		"horas": 4.0,
		"producto": "huevo",
		"cantidad_producto": 2,
		"descripcion": "Corral acogedor · produce huevos frescos",
	},
	"vaca": {
		"nombre": "Vaca",
		"precio": 350,
		"tamano": Vector2i(3, 3),
		"rotable": false,
		"come": "trigo",
		"cantidad_come": 2,
		"horas": 6.0,
		"producto": "leche",
		"cantidad_producto": 2,
		"descripcion": "Prado cercado · produce leche cremosa",
	},
}

# --- Máquinas ----------------------------------------------------------------
const MAQUINAS: Dictionary = {
	"molino": {
		"nombre": "Molino",
		"precio": 250,
		"tamano": Vector2i(4, 4),
		"rotable": false,
		"horas": 2.0,
		"ingredientes": {"trigo": 2},
		"producto": "harina",
		"cantidad_producto": 1,
		"descripcion": "Gran torre con aspas · muele trigo en harina",
	},
	"panaderia": {
		"nombre": "Panadería",
		"precio": 500,
		"tamano": Vector2i(4, 3),
		"rotable": true,
		"horas": 3.0,
		"ingredientes": {"harina": 1, "huevo": 1},
		"producto": "pan",
		"cantidad_producto": 1,
		"descripcion": "Horno de leña artesanal · hornea pan dorado",
	},
	"queseria": {
		"nombre": "Quesería",
		"precio": 700,
		"tamano": Vector2i(3, 3),
		"rotable": false,
		"horas": 4.0,
		"ingredientes": {"leche": 2},
		"producto": "queso",
		"cantidad_producto": 1,
		"descripcion": "Cuba de cobre y prensa · elabora queso curado",
	},
}

# --- Mejoras -----------------------------------------------------------------
# Se compran en orden por categoría (ampliación de terreno y velocidad).
const MEJORAS: Dictionary = {
	"ampliar_1": {"nombre": "Ampliar terreno I", "coste": 250, "campo": "Nivel_Terreno", "valor": 1, "area": 224, "delta": 80, "etiqueta": "16×14"},
	"ampliar_2": {"nombre": "Ampliar terreno II", "coste": 500, "campo": "Nivel_Terreno", "valor": 2, "area": 324, "delta": 100, "etiqueta": "18×18"},
	"ampliar_3": {"nombre": "Ampliar terreno III", "coste": 900, "campo": "Nivel_Terreno", "valor": 3, "area": 440, "delta": 116, "etiqueta": "22×20"},
	"ampliar_4": {"nombre": "Ampliar terreno IV", "coste": 1500, "campo": "Nivel_Terreno", "valor": 4, "area": 576, "delta": 136, "etiqueta": "24×24"},
	"velocidad_1": {"nombre": "Velocidad I", "coste": 400, "campo": "Velocidad", "valor": 1},
	"velocidad_2": {"nombre": "Velocidad II", "coste": 800, "campo": "Velocidad", "valor": 2},
	"velocidad_3": {"nombre": "Velocidad III", "coste": 1200, "campo": "Velocidad", "valor": 3},
}

const ORDEN_MEJORAS: Array[String] = [
	"ampliar_1", "ampliar_2", "ampliar_3", "ampliar_4",
	"velocidad_1", "velocidad_2", "velocidad_3",
]


static func rect_terreno(nivel_terreno: int) -> Rect2i:
	var nivel: int = clampi(nivel_terreno, 0, NIVEL_TERRENO_MAX)
	var cfg: Dictionary = NIVELES_TERRENO[nivel]
	var x_min: int = int(cfg["x_min"])
	var y_min: int = int(cfg["y_min"])
	var w: int = int(cfg["x_max"]) - x_min + 1
	var h: int = int(cfg["y_max"]) - y_min + 1
	return Rect2i(x_min, y_min, w, h)


static func celda_en_mapa(x: int, y: int) -> bool:
	return x >= 0 and x < GRID_ANCHO and y >= 0 and y < GRID_ALTO


static func celda_desbloqueada_xy(x: int, y: int, nivel_terreno: int) -> bool:
	if not celda_en_mapa(x, y):
		return false
	return rect_terreno(nivel_terreno).has_point(Vector2i(x, y))


static func celda_en_siguiente_ampliacion_xy(x: int, y: int, nivel_terreno: int) -> bool:
	var nivel: int = clampi(nivel_terreno, 0, NIVEL_TERRENO_MAX)
	if nivel >= NIVEL_TERRENO_MAX:
		return false
	return (not celda_desbloqueada_xy(x, y, nivel)) and celda_desbloqueada_xy(x, y, nivel + 1)


static func area_por_nivel(nivel_terreno: int) -> int:
	var nivel: int = clampi(nivel_terreno, 0, NIVEL_TERRENO_MAX)
	return int(NIVELES_TERRENO[nivel]["area"])


static func tamano_objeto(categoria: String, tipo: String = "", rotado: bool = false) -> Vector2i:
	var base := Vector2i(2, 2)
	match categoria:
		"tierra":
			base = TAMANO_TIERRA
		"animal":
			var a := animal(tipo)
			if a.has("tamano") and a["tamano"] is Vector2i:
				base = a["tamano"]
		"maquina":
			var m := maquina(tipo)
			if m.has("tamano") and m["tamano"] is Vector2i:
				base = m["tamano"]
	if rotado and base.x != base.y:
		return Vector2i(base.y, base.x)
	return base


static func es_rotable(categoria: String, tipo: String = "") -> bool:
	var t := tamano_objeto(categoria, tipo, false)
	return t.x != t.y


static func etiqueta_tamano(categoria: String, tipo: String = "", rotado: bool = false) -> String:
	var t := tamano_objeto(categoria, tipo, rotado)
	return "%d×%d" % [t.x, t.y]


static func precio_construccion(categoria: String, tipo: String = "") -> int:
	match categoria:
		"tierra":
			return PRECIO_PARCELA_TIERRA
		"animal":
			return int(animal(tipo).get("precio", 0))
		"maquina":
			return int(maquina(tipo).get("precio", 0))
		_:
			return 0


static func reembolso_venta(coste_pagado: int) -> int:
	return int(floor(float(maxi(0, coste_pagado)) * PORCENTAJE_REEMBOLSO))


static func cultivo(clave: String) -> Dictionary:
	var datos = CULTIVOS.get(clave, {})
	return datos if datos is Dictionary else {}


static func producto(clave: String) -> Dictionary:
	var datos = PRODUCTOS.get(clave, {})
	return datos if datos is Dictionary else {}


static func animal(clave: String) -> Dictionary:
	var datos = ANIMALES.get(clave, {})
	return datos if datos is Dictionary else {}


static func maquina(clave: String) -> Dictionary:
	var datos = MAQUINAS.get(clave, {})
	return datos if datos is Dictionary else {}


static func nombre(clave: String) -> String:
	if clave == "":
		return "Vacío"
	if clave == "tierra":
		return "Parcela de cultivo"
	var c := cultivo(clave)
	if not c.is_empty():
		return str(c.get("nombre", clave.capitalize()))
	var p := producto(clave)
	if not p.is_empty():
		return str(p.get("nombre", clave.capitalize()))
	var a := animal(clave)
	if not a.is_empty():
		return str(a.get("nombre", clave.capitalize()))
	var m := maquina(clave)
	if not m.is_empty():
		return str(m.get("nombre", clave.capitalize()))
	return clave.capitalize()


static func precio_venta(clave: String) -> int:
	var c := cultivo(clave)
	if not c.is_empty():
		return int(c.get("venta", 0))
	return int(producto(clave).get("venta", 0))


static func es_vendible(clave: String) -> bool:
	return CULTIVOS.has(clave) or PRODUCTOS.has(clave)


static func tasa_conversion(x: float) -> float:
	if x < float(CONVERSION_TRAMO_INICIAL):
		return CONVERSION_TASA_INICIAL
	var dentro: float = maxf(0.0, x - float(CONVERSION_TRAMO_INICIAL))
	var tasa: float = CONVERSION_TASA_DESPUES / (1.0 + log(1.0 + dentro / CONVERSION_ESCALA_LOG) / log(2.0))
	return maxf(CONVERSION_TASA_MINIMA, tasa)


static func formatear_numero(numero: int) -> String:
	var negativo: bool = numero < 0
	var texto: String = str(absi(numero))
	var salida: String = ""
	var contador: int = 0
	for i in range(texto.length() - 1, -1, -1):
		salida = texto.substr(i, 1) + salida
		contador += 1
		if contador % 3 == 0 and i > 0:
			salida = "." + salida
	return ("-" if negativo else "") + salida
