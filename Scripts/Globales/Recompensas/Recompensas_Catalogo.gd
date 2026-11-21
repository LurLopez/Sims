class_name Recompensas_Catalogo
extends RefCounted

# ============================================================================
# Catálogo de la pestaña Tienda > Bienestar.
#
# Es la única fuente de verdad de anuncios, servicios, precios, recompensas y
# textos. La UI no inventa productos: lee de aquí y deja que Recompensas valide
# cada operación.
#
# Dos familias de contenido:
#   1. Anuncios recompensados (gratis, simulados, con espera entre uno y otro).
#   2. Servicios de bienestar y rejuvenecimiento pagados con euros del juego.
#
# Aquí no hay gemas, pagos reales ni moneda premium: solo recompensas que
# afectan a la partida (dinero, necesidades, tuppers y años de juventud).
# ============================================================================

const SECCION_ANUNCIOS := "anuncios"
const SECCION_SERVICIOS := "servicios"

const TIPO_ANUNCIO := "anuncio"
const TIPO_SERVICIO := "servicio"

const GRUPO_REJUVENECIMIENTO := "rejuvenecimiento"
const GRUPO_CUIDADO := "cuidado"

const ORDEN_GRUPOS := [GRUPO_REJUVENECIMIENTO, GRUPO_CUIDADO]
const ORDEN_SECCIONES := [SECCION_SERVICIOS, SECCION_ANUNCIOS]

const PRODUCTOS := {
	# ---------------------------------------------------------------- anuncios
	"anuncio_dinero": {
		"id": "anuncio_dinero",
		"seccion": SECCION_ANUNCIOS,
		"tipo": TIPO_ANUNCIO,
		"orden": 20,
		"titulo": "Bono de 150 €",
		"subtitulo": "Anuncio de 5 segundos",
		"descripcion": "Un empujón directo para tu cuenta corriente.",
		"recompensa_texto": "+150 €",
		"icono": "hand-coins",
		"color": Color("#1ea34a"),
		"etiqueta": "ANUNCIO",
		"cooldown_seg": 1800,
		"duracion_simulada": 5.0,
		"creativo": "finanzas",
		"recompensas": [
			{"tipo": "euros", "cantidad": 150},
		],
	},
	"anuncio_bienestar": {
		"id": "anuncio_bienestar",
		"seccion": SECCION_ANUNCIOS,
		"tipo": TIPO_ANUNCIO,
		"orden": 21,
		"titulo": "Recarga de bienestar",
		"subtitulo": "Anuncio de 6 segundos",
		"descripcion": "Suma 30 puntos a cada necesidad básica al instante.",
		"recompensa_texto": "+30 a cada necesidad",
		"icono": "heart-pulse",
		"color": Color("#e11d48"),
		"etiqueta": "ANUNCIO",
		"cooldown_seg": 600,
		"duracion_simulada": 6.0,
		"creativo": "chef",
		"recompensas": [
			{"tipo": "necesidades_sumar", "cantidad": 30},
		],
	},
	"anuncio_comida": {
		"id": "anuncio_comida",
		"seccion": SECCION_ANUNCIOS,
		"tipo": TIPO_ANUNCIO,
		"orden": 22,
		"titulo": "Cesta caliente",
		"subtitulo": "Anuncio de 6 segundos",
		"descripcion": "Dos tuppers gourmet listos para guardar en la despensa.",
		"recompensa_texto": "2 tuppers gourmet",
		"icono": "chef-hat",
		"color": Color("#d97706"),
		"etiqueta": "ANUNCIO",
		"cooldown_seg": 900,
		"duracion_simulada": 6.0,
		"creativo": "burger",
		"recompensas": [
			{"tipo": "tuppers", "cantidad": 2, "calidad": 100},
		],
	},
	"anuncio_juventud": {
		"id": "anuncio_juventud",
		"seccion": SECCION_ANUNCIOS,
		"tipo": TIPO_ANUNCIO,
		"orden": 23,
		"titulo": "Spa express",
		"subtitulo": "Anuncio de 8 segundos",
		"descripcion": "Una sesión gratuita de la clínica: tu Sim cumple un año menos.",
		"recompensa_texto": "−1 año",
		"icono": "sparkles",
		"color": Color("#0d9488"),
		"etiqueta": "ANUNCIO",
		"cooldown_seg": 3600,
		"duracion_simulada": 8.0,
		"creativo": "spa",
		"recompensas": [
			{"tipo": "rejuvenecer", "cantidad": 1},
		],
	},

	# --------------------------------------------------------------- servicios
	"servicio_spa": {
		"id": "servicio_spa",
		"seccion": SECCION_SERVICIOS,
		"tipo": TIPO_SERVICIO,
		"grupo": GRUPO_REJUVENECIMIENTO,
		"orden": 40,
		"titulo": "Spa revitalizante",
		"subtitulo": "−1 año de edad",
		"descripcion": "Aguas termales y descanso profundo. Tu Sim recupera un año de juventud.",
		"recompensa_texto": "−1 año",
		"coste_euros": 400,
		"coste_incremento": 150,
		"icono": "leaf",
		"color": Color("#0d9488"),
		"etiqueta": "TRATAMIENTO",
		"recompensas": [
			{"tipo": "rejuvenecer", "cantidad": 1},
		],
	},
	"servicio_clinica": {
		"id": "servicio_clinica",
		"seccion": SECCION_SERVICIOS,
		"tipo": TIPO_SERVICIO,
		"grupo": GRUPO_REJUVENECIMIENTO,
		"orden": 41,
		"titulo": "Clínica regenerativa",
		"subtitulo": "−3 años de edad",
		"descripcion": "Un programa intensivo que devuelve tres años al calendario de tu Sim.",
		"recompensa_texto": "−3 años",
		"coste_euros": 1100,
		"coste_incremento": 350,
		"icono": "stethoscope",
		"color": Color("#4f46e5"),
		"etiqueta": "TRATAMIENTO",
		"recompensas": [
			{"tipo": "rejuvenecer", "cantidad": 3},
		],
	},
	"servicio_capsula": {
		"id": "servicio_capsula",
		"seccion": SECCION_SERVICIOS,
		"tipo": TIPO_SERVICIO,
		"grupo": GRUPO_REJUVENECIMIENTO,
		"orden": 42,
		"titulo": "Cápsula del tiempo",
		"subtitulo": "−5 años de edad",
		"descripcion": "La tecnología más cara de la clínica. Cinco años menos, sin efectos raros.",
		"recompensa_texto": "−5 años",
		"coste_euros": 2200,
		"coste_incremento": 700,
		"icono": "hourglass",
		"color": Color("#b45309"),
		"etiqueta": "TRATAMIENTO",
		"recompensas": [
			{"tipo": "rejuvenecer", "cantidad": 5},
		],
	},
	"servicio_bienestar": {
		"id": "servicio_bienestar",
		"seccion": SECCION_SERVICIOS,
		"tipo": TIPO_SERVICIO,
		"grupo": GRUPO_CUIDADO,
		"orden": 50,
		"titulo": "Día de spa",
		"subtitulo": "Bienestar al 100 %",
		"descripcion": "Salud física, salud mental, hambre, descanso e higiene al máximo.",
		"recompensa_texto": "Todas las necesidades al 100 %",
		"coste_euros": 120,
		"coste_incremento": 0,
		"icono": "heart-pulse",
		"color": Color("#e11d48"),
		"etiqueta": "CUIDADO",
		"recompensas": [
			{"tipo": "necesidades_todas", "valor": 100},
		],
	},
	"servicio_cesta": {
		"id": "servicio_cesta",
		"seccion": SECCION_SERVICIOS,
		"tipo": TIPO_SERVICIO,
		"grupo": GRUPO_CUIDADO,
		"orden": 51,
		"titulo": "Cesta gourmet",
		"subtitulo": "3 tuppers al 100 %",
		"descripcion": "Tres raciones caseras de calidad máxima, listas para la despensa.",
		"recompensa_texto": "3 tuppers gourmet",
		"coste_euros": 90,
		"coste_incremento": 0,
		"icono": "chef-hat",
		"color": Color("#d97706"),
		"etiqueta": "CUIDADO",
		"recompensas": [
			{"tipo": "tuppers", "cantidad": 3, "calidad": 100},
		],
	},
}

# Creatividades de los anuncios simulados. Se apoyan en arte ya existente del
# minijuego de cocina y en degradados propios para que la demo se sienta parte
# del universo del juego.
const CREATIVOS := {
	"finanzas": {
		"marca": "BANCO SIMPLE",
		"titular": "Tu cuenta,\nun poco más llena.",
		"subtitulo": "Microcréditos de la demo para llegar a fin de semana.",
		"cta": "Cobrar ahora",
		"etiqueta": "SIMULADO",
		"imagen": "",
		"color_fondo": Color("#047857"),
		"color_fondo_2": Color("#0f172a"),
		"color_acento": Color("#d1fae5"),
		"icono": "wallet",
	},
	"burger": {
		"marca": "BURGER & STREET FOOD",
		"titular": "El menú que\ntriunfa.",
		"subtitulo": "Sabor de barrio, actitud de estrella.",
		"cta": "Pedir ahora",
		"etiqueta": "NUEVO",
		"imagen": "res://Imagenes/Minijuego_Cocina/Comida/Platos/Hamburguesa_Doble.png",
		"color_fondo": Color("#f59e0b"),
		"color_fondo_2": Color("#dc2626"),
		"color_acento": Color("#fef3c7"),
		"icono": "utensils",
	},
	"chef": {
		"marca": "CHEF MICHELLE",
		"titular": "Cocina sin\nestrés.",
		"subtitulo": "El equilibrio también se cocina a fuego lento.",
		"cta": "Entrar",
		"etiqueta": "ESCUELA",
		"imagen": "res://Imagenes/Minijuego_Cocina/Chef/Poses/Chef_Celebrando.png",
		"color_fondo": Color("#e11d48"),
		"color_fondo_2": Color("#7c3aed"),
		"color_acento": Color("#ffe4e6"),
		"icono": "chef-hat",
	},
	"spa": {
		"marca": "CLÍNICA LUMEN",
		"titular": "Vuelve a\nempezar.",
		"subtitulo": "Ciencia suave para años intensos.",
		"cta": "Reservar sesión",
		"etiqueta": "BIENESTAR",
		"imagen": "",
		"color_fondo": Color("#0d9488"),
		"color_fondo_2": Color("#3730a3"),
		"color_acento": Color("#ccfbf1"),
		"icono": "sparkles",
	},
}


static func Obtener_Producto(id: String) -> Dictionary:
	if not PRODUCTOS.has(id):
		return {}
	var producto: Dictionary = PRODUCTOS[id]
	return producto


static func Productos_De(seccion: String) -> Array:
	var resultado: Array = []
	for id in PRODUCTOS:
		var producto: Dictionary = PRODUCTOS[id]
		if str(producto.get("seccion", "")) == seccion:
			resultado.append(producto)
	resultado.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("orden", 0)) < int(b.get("orden", 0)))
	return resultado


static func Servicios_De_Grupo(grupo: String) -> Array:
	var resultado: Array = []
	for producto in Productos_De(SECCION_SERVICIOS):
		if str(producto.get("grupo", "")) == grupo:
			resultado.append(producto)
	return resultado


static func Es_Anuncio(id: String) -> bool:
	return str(Obtener_Producto(id).get("tipo", "")) == TIPO_ANUNCIO


static func Es_Servicio(id: String) -> bool:
	return str(Obtener_Producto(id).get("tipo", "")) == TIPO_SERVICIO


static func Obtener_Creativo(nombre: String) -> Dictionary:
	if not CREATIVOS.has(nombre):
		return CREATIVOS["burger"]
	var creativo: Dictionary = CREATIVOS[nombre]
	return creativo


static func Obtener_Recompensas(producto: Dictionary) -> Array:
	var recompensas = producto.get("recompensas", [])
	return recompensas if recompensas is Array else []


# Precio actual de un servicio. Los tratamientos de rejuvenecimiento suben de
# precio con cada sesión para que alargar la vida no sea un botón infinito;
# los servicios de cuidado mantienen una tarifa fija.
static func Coste_Servicio(producto: Dictionary, tratamientos_realizados: int) -> float:
	var base := maxf(0.0, float(producto.get("coste_euros", 0.0)))
	var incremento := maxf(0.0, float(producto.get("coste_incremento", 0.0)))
	var usos := maxi(0, tratamientos_realizados)
	var total := base + incremento * float(usos)
	return round(total / 5.0) * 5.0
