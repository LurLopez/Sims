extends Node

# ============================================================================
# Sistema de Minijuego de Cocina (gestión de pedidos) + Ropa Equipable.
# Toda la matemática y reglas puras viven aquí como static func para pruebas GUT.
# ============================================================================

signal restaurante_desbloqueado(restaurante_id: String, nombre_restaurante: String)

const RESTAURANTE_BURGER := "burger_street"
const RESTAURANTE_BISTRO := "bistro_tradicional"
const RESTAURANTE_MERCADO := "cocina_mercado"
const RESTAURANTE_ALTA := "alta_cocina"

# 4 mundos de cocina, uno por cada trabajo de hostelería.
const ORDEN_RESTAURANTES: Array[String] = [
	RESTAURANTE_BURGER,
	RESTAURANTE_BISTRO,
	RESTAURANTE_MERCADO,
	RESTAURANTE_ALTA
]

const TRABAJO_A_RESTAURANTE: Dictionary = {
	"Trabajar_En_Comida_Rapida": RESTAURANTE_BURGER,
	"Trabajar_De_Ayudante_Cocina": RESTAURANTE_BISTRO,
	"Trabajar_De_Cocinero_Partida": RESTAURANTE_MERCADO,
	"Trabajar_De_Chef_Ejecutivo": RESTAURANTE_ALTA
}

const LIMITE_SERVICIOS_COMPLETOS_DIA: int = 2
# Alias conservado para saves/scripts antiguos: ahora son "servicios completos".
const LIMITE_SERVICIOS_LIBRES_DIA: int = 2
const TOPE_MICRO_PROPINAS_BASE_EUR: float = 6.0
const MICRO_PROPINA_MIN_EUR: float = 1.0
const MICRO_PROPINA_MAX_EUR: float = 3.0
const PROB_MICRO_COCINA_BASE: float = 0.15
const PROB_MICRO_MANUALIDADES_BASE: float = 0.05
const PROB_MICRO_NECESIDAD_BASE: float = 0.12
const PROB_MICRO_PROPINA_BASE: float = 0.10
const RATIO_PROPINA_MONEDA_A_EUR: float = 0.50
const PLUS_NOMINA_TURNO_BONUS: float = 0.10

# --- Modelo económico del local (v2) ---
# La Caja del restaurante recibe las ventas menos los costes y paga las 5
# mejoras. El dinero personal del Sim sale de las propinas, de una parte del
# beneficio y de la prima por estrellas.
const COSTE_INGREDIENTES_RATIO: float = 0.30
const COSTE_SERVICIO_BASE_EUR: float = 6.0
const COSTE_SERVICIO_POR_NIVEL_EUR: float = 2.0
const COSTE_MERMA_RATIO: float = 0.30
const REPARTO_BENEFICIO_SIM: float = 0.05
const MULT_MODO_PRACTICA: float = 0.25
const BONO_ESTRELLA_RATIO: float = 0.10

const ORDEN_MEJORAS: Array[String] = [
	"plancha",
	"emplatado",
	"termostato",
	"ingredientes",
	"ambiente"
]

# Cada mejora tiene 3 niveles. Además de los números que consume el juego,
# `niveles` describe cada escalón para la pantalla de Mejoras: nombre corto,
# dos o tres beneficios legibles y una frase que invita a subir de nivel.
const MEJORAS_DEF: Dictionary = {
	"plancha": {
		"nombre": "Plancha y Freidora",
		"nombre_corto": "Plancha y Freidora",
		"icono": "flame",
		"acento": "#f97316",
		"costes": [0, 120, 320],
		"huecos": [2, 3, 4],
		"cestas_freidora": [1, 2, 2],
		"mult_tiempo": [1.00, 0.80, 0.65],
		"descripciones": [
			"2 huecos de plancha · 1 cesta · Vel. x1.00",
			"3 huecos de plancha · 2 cestas · Cocción -20%",
			"4 huecos de plancha · 2 cestas · Cocción -35%"
		],
		"niveles": [
			{
				"nombre": "Básica",
				"beneficios": ["2 huecos de plancha", "1 cesta de fritura", "Cocción a velocidad normal"],
				"ganancias": [],
				"frase": "Dos hamburguesas a la vez para arrancar. Sube a tres huecos en cuanto puedas."
			},
			{
				"nombre": "Mejorada",
				"beneficios": ["3 huecos de plancha", "2 cestas de fritura", "Cocción un 20% más rápida"],
				"ganancias": ["+1 hueco de plancha", "+1 cesta de fritura", "−20% tiempo de cocción"],
				"frase": "Tres huecos y dos cestas: el ritmo ya es de diner de verdad."
			},
			{
				"nombre": "Profesional",
				"beneficios": ["4 huecos de plancha", "2 cestas de fritura", "Cocción un 35% más rápida"],
				"ganancias": ["+1 hueco de plancha", "−15% tiempo de cocción"],
				"frase": "Cuatro huecos a pleno rendimiento. La plancha ya no te frena."
			}
		]
	},
	"emplatado": {
		"nombre": "Emplatado y Bebidas",
		"nombre_corto": "Emplatado y Bebidas",
		"icono": "utensils",
		"acento": "#38bdf8",
		"costes": [0, 100, 280],
		"platos": [2, 3, 4],
		"bebidas": [1, 2, 3],
		"tiempo_bebida": [4.0, 2.5, 1.0],
		"descripciones": [
			"2 platos · 1 vaso (4.0 s)",
			"3 platos · 2 vasos (2.5 s)",
			"4 platos · 3 vasos (1.0 s)"
		],
		"niveles": [
			{
				"nombre": "Básico",
				"beneficios": ["2 platos de pase", "1 vaso a la vez", "Refresco en 4.0 s"],
				"ganancias": [],
				"frase": "Dos platos y un vaso para empezar. Con tres platos el pase respira."
			},
			{
				"nombre": "Mejorado",
				"beneficios": ["3 platos de pase", "2 vasos a la vez", "Refresco en 2.5 s"],
				"ganancias": ["+1 plato de pase", "+1 vaso a la vez", "−1.5 s por refresco"],
				"frase": "Tres platos y dos vasos: sirve sin cruzar pedidos ni esperar."
			},
			{
				"nombre": "Profesional",
				"beneficios": ["4 platos de pase", "3 vasos a la vez", "Refresco en 1.0 s"],
				"ganancias": ["+1 plato de pase", "+1 vaso a la vez", "−1.5 s por refresco"],
				"frase": "Cuatro platos y tres vasos. El pase de servicio ya vuela."
			}
		]
	},
	"termostato": {
		"nombre": "Termostato",
		"nombre_corto": "Termostato",
		"icono": "zap",
		"acento": "#facc15",
		"costes": [0, 90, 240],
		"tiempo_quemado": [6.0, 8.1, 10.5],
		"aviso_temprano": [false, false, true],
		"descripciones": [
			"6.0 s antes de quemarse",
			"8.1 s antes de quemarse",
			"10.5 s + aviso visual temprano"
		],
		"niveles": [
			{
				"nombre": "Manual",
				"beneficios": ["6.0 s de margen", "Sin aviso temprano", "Dial de control básico"],
				"ganancias": [],
				"frase": "Seis segundos de margen. Con el dial de precisión ganarás dos más."
			},
			{
				"nombre": "Precisión",
				"beneficios": ["8.1 s de margen", "Sin aviso temprano", "Dial de precisión"],
				"ganancias": ["+2.1 s de margen", "Dial de precisión"],
				"frase": "Ocho segundos y un dial fino. El aviso temprano está a un paso."
			},
			{
				"nombre": "Digital",
				"beneficios": ["10.5 s de margen", "Aviso visual temprano", "Panel digital"],
				"ganancias": ["+2.4 s de margen", "Aviso visual temprano"],
				"frase": "Diez segundos y aviso visual: quemar la comida es cosa del pasado."
			}
		]
	},
	"ingredientes": {
		"nombre": "Calidad de Ingredientes",
		"nombre_corto": "Ingredientes",
		"icono": "sparkles",
		"acento": "#4ade80",
		"costes": [0, 140, 360],
		"mult_precio": [1.00, 1.25, 1.50],
		"descripciones": [
			"Precio base x1.00",
			"Precio por plato x1.25",
			"Precio por plato x1.50"
		],
		"niveles": [
			{
				"nombre": "De proximidad",
				"beneficios": ["Precio base x1.00", "Género de proximidad", "Sin bonificación"],
				"ganancias": [],
				"frase": "Producto correcto, precio correcto. Con género seleccionado subirás cada ticket."
			},
			{
				"nombre": "Seleccionado",
				"beneficios": ["Precio por plato x1.25", "Género seleccionado", "+25% en cada ticket"],
				"ganancias": ["+25% precio por plato", "Género seleccionado"],
				"frase": "Buen producto, mejor ticket. El género premium está a un paso."
			},
			{
				"nombre": "Premium",
				"beneficios": ["Precio por plato x1.50", "Género premium", "+50% en cada ticket"],
				"ganancias": ["+25% precio por plato", "Género premium"],
				"frase": "Producto premium y tickets un 50% más altos. Se nota en la Caja."
			}
		]
	},
	"ambiente": {
		"nombre": "Ambiente del Local",
		"nombre_corto": "Ambiente del Local",
		"icono": "smile",
		"acento": "#f472b6",
		"costes": [0, 110, 300],
		"mult_paciencia": [1.00, 1.15, 1.30],
		"mult_propinas": [1.00, 1.20, 1.40],
		"descripciones": [
			"Paciencia x1.00 · Propinas x1.00",
			"Paciencia x1.15 · Propinas x1.20",
			"Paciencia x1.30 · Propinas x1.40"
		],
		"niveles": [
			{
				"nombre": "Acogedor",
				"beneficios": ["Paciencia x1.00", "Propinas x1.00", "Hilo musical"],
				"ganancias": [],
				"frase": "Un local agradable ya suma. Con el jukebox los clientes esperan mejor."
			},
			{
				"nombre": "Con jukebox",
				"beneficios": ["Paciencia x1.15", "Propinas x1.20", "Jukebox y luz cálida"],
				"ganancias": ["+15% paciencia", "+20% propinas"],
				"frase": "Luz cálida y buena música: los clientes aguantan más y dejan más."
			},
			{
				"nombre": "De lujo",
				"beneficios": ["Paciencia x1.30", "Propinas x1.40", "Jukebox de lujo"],
				"ganancias": ["+15% paciencia", "+20% propinas"],
				"frase": "El jukebox de lujo: esperan con gusto y dejan propinas de estrella."
			}
		]
	}
}

const NOMBRES_NIVEL_MEJORA: Array[String] = ["Básico", "Mejorado", "Profesional"]

const RECETAS_BURGER_STREET: Dictionary = {
	"burger_sola": {
		"id": "burger_sola",
		"nombre": "Hamburguesa sola",
		"nombre_corto": "Hamb. sola",
		"detalle": "Pan + Carne",
		"precio_base": 12,
		"tipo": "plato"
	},
	"burger_queso": {
		"id": "burger_queso",
		"nombre": "Hamburguesa con queso",
		"nombre_corto": "Con queso",
		"detalle": "Pan + Carne + Queso",
		"precio_base": 16,
		"tipo": "plato"
	},
	"burger_completa": {
		"id": "burger_completa",
		"nombre": "Hamburguesa completa",
		"nombre_corto": "Completa",
		"detalle": "Pan + Carne + Q + L + T",
		"precio_base": 22,
		"tipo": "plato"
	},
	"burger_doble": {
		"id": "burger_doble",
		"nombre": "Hamburguesa doble",
		"nombre_corto": "Doble",
		"detalle": "Pan + 2xCarne + Queso",
		"precio_base": 26,
		"tipo": "plato"
	},
	"patatas": {
		"id": "patatas",
		"nombre": "Patatas fritas",
		"nombre_corto": "Patatas",
		"detalle": "Freidora",
		"precio_base": 8,
		"tipo": "freidora"
	},
	"refresco": {
		"id": "refresco",
		"nombre": "Refresco",
		"nombre_corto": "Refresco",
		"detalle": "Dispensador",
		"precio_base": 6,
		"tipo": "bebida"
	}
}

const RANGOS_LOGRO: Array[Dictionary] = [
	{"rango": 0, "niveles": 0, "nombre": "Aprendiz", "beneficio": "Supera 5 niveles para tu primer rango.", "prenda": ""},
	{"rango": 1, "niveles": 5, "nombre": "Pinche de Cocina", "beneficio": "Desbloquea Delantal de Aprendiz (-5% desgaste Higiene en hostelería).", "prenda": "Delantal_Aprendiz"},
	{"rango": 2, "niveles": 10, "nombre": "Paladar Feliz", "beneficio": "+2 extra en Salud Mental al comer (Tupper y Comida rápida).", "prenda": ""},
	{"rango": 3, "niveles": 15, "nombre": "Cocinero Oficial", "beneficio": "Desbloquea Chaqueta de Chef (+10% salario hostelería y -5% Higiene).", "prenda": "Chaqueta_Chef"},
	{"rango": 4, "niveles": 20, "nombre": "Compra Inteligente", "beneficio": "-20% coste en Comida rápida y +15% saciedad en Comida casera.", "prenda": ""},
	{"rango": 5, "niveles": 25, "nombre": "Manos Expertas", "beneficio": "+15% eficiencia en Manualidades y Cocina.", "prenda": ""},
	{"rango": 6, "niveles": 30, "nombre": "Jefe de Cocina", "beneficio": "Desbloquea Atuendo de Chef de Gala (+20% salario hostelería y -5% Higiene).", "prenda": "Atuendo_Chef_Gala"},
	{"rango": 7, "niveles": 35, "nombre": "Nutrición Superior", "beneficio": "Comer recupera Hambre +15% más rápido y suma +1 Salud Física.", "prenda": ""},
	{"rango": 8, "niveles": 40, "nombre": "Estómago de Hierro", "beneficio": "Inmunidad total al evento aleatorio de Intoxicación alimentaria.", "prenda": ""},
	{"rango": 9, "niveles": 45, "nombre": "Estrella Michelin", "beneficio": "Desbloquea Traje Estrella Michelin (+30% salario, -5% Higiene, +25% propinas).", "prenda": "Traje_Estrella_Michelin"}
]

const DESBLOQUEO_INICIO: String = "inicio"
const DESBLOQUEO_TIENDA: String = "tienda"
const DESBLOQUEO_RANGO: String = "rango"

const CATEGORIAS_ROPA: Array[Dictionary] = [
	{"id": "todo", "nombre": "Todo"},
	{"id": "tienda", "nombre": "Tienda"},
	{"id": "diario", "nombre": "Diario"},
	{"id": "deporte", "nombre": "Deporte"},
	{"id": "elegante", "nombre": "Elegante"},
	{"id": "trabajo", "nombre": "Trabajo"},
	{"id": "fiesta", "nombre": "Fiesta"},
	{"id": "cocina", "nombre": "Cocina"},
]

const ORDEN_ROPA: Array[String] = [
	# Inicio (gratis)
	"Ropa_Calle",
	"Camiseta_Blanca",
	"Sudadera_Gris",
	"Camisa_Cuadros",
	"Conjunto_Verano",
	"Vestido_Flores",
	"Pijama_Estrellada",
	"Jersey_Invierno",
	"Conjunto_Deportivo",
	"Equipacion_Futbol",
	# Tienda (dinero)
	"Camiseta_Universidad",
	"Mono_Taller",
	"Uniforme_Camarero",
	"Bata_Laboratorio",
	"Abrigo_Invierno",
	"Chaqueta_Cuero",
	"Chaqueta_Neon",
	"Traje_Ejecutivo",
	"Vestido_Gala",
	"Esmoquin_Noir",
	"Traje_Astronauta",
	# Cocina (rangos)
	"Delantal_Aprendiz",
	"Chaqueta_Chef",
	"Atuendo_Chef_Gala",
	"Traje_Estrella_Michelin"
]

const NOMBRES_ROPA: Dictionary = {
	"Ropa_Calle": "Ropa de Calle",
	"Camiseta_Blanca": "Camiseta Blanca",
	"Sudadera_Gris": "Sudadera con Capucha",
	"Camisa_Cuadros": "Camisa de Cuadros",
	"Conjunto_Verano": "Conjunto de Verano",
	"Vestido_Flores": "Vestido de Flores",
	"Pijama_Estrellada": "Pijama Estrellada",
	"Jersey_Invierno": "Jersey de Invierno",
	"Conjunto_Deportivo": "Conjunto Deportivo",
	"Equipacion_Futbol": "Equipación de Fútbol",
	"Camiseta_Universidad": "Camiseta Universitaria",
	"Mono_Taller": "Mono de Taller",
	"Uniforme_Camarero": "Uniforme de Camarero",
	"Bata_Laboratorio": "Bata de Laboratorio",
	"Abrigo_Invierno": "Abrigo de Invierno",
	"Chaqueta_Cuero": "Chaqueta de Cuero",
	"Chaqueta_Neon": "Chaqueta Neón",
	"Traje_Ejecutivo": "Traje Ejecutivo",
	"Vestido_Gala": "Vestido de Gala",
	"Esmoquin_Noir": "Esmoquin Noir",
	"Traje_Astronauta": "Traje de Astronauta",
	"Delantal_Aprendiz": "Delantal de Aprendiz",
	"Chaqueta_Chef": "Chaqueta de Chef",
	"Atuendo_Chef_Gala": "Atuendo de Chef de Gala",
	"Traje_Estrella_Michelin": "Traje Estrella Michelin"
}

var _restaurantes: Dictionary = {}


func _ready() -> void:
	_Inicializar_Restaurantes()


func _Inicializar_Restaurantes() -> void:
	var niveles_burger: Array = [
		{"nivel": 1, "clientes": 11, "meta_1": 55, "meta_2": 85, "meta_3": 115, "intervalo_spawn": 6.5, "paciencia_base": 28.0, "max_items": 2, "menu": ["burger_sola", "refresco"]},
		{"nivel": 2, "clientes": 12, "meta_1": 70, "meta_2": 105, "meta_3": 140, "intervalo_spawn": 6.0, "paciencia_base": 27.0, "max_items": 2, "menu": ["burger_sola", "refresco"]},
		{"nivel": 3, "clientes": 14, "meta_1": 85, "meta_2": 125, "meta_3": 165, "intervalo_spawn": 5.6, "paciencia_base": 26.0, "max_items": 2, "menu": ["burger_sola", "burger_queso", "refresco"]},
		{"nivel": 4, "clientes": 15, "meta_1": 100, "meta_2": 145, "meta_3": 190, "intervalo_spawn": 5.3, "paciencia_base": 25.5, "max_items": 2, "menu": ["burger_sola", "burger_queso", "refresco"]},
		{"nivel": 5, "clientes": 16, "meta_1": 115, "meta_2": 165, "meta_3": 215, "intervalo_spawn": 5.0, "paciencia_base": 25.0, "max_items": 2, "menu": ["burger_sola", "burger_queso", "patatas", "refresco"]},
		{"nivel": 6, "clientes": 17, "meta_1": 130, "meta_2": 185, "meta_3": 240, "intervalo_spawn": 4.8, "paciencia_base": 24.0, "max_items": 3, "menu": ["burger_sola", "burger_queso", "patatas", "refresco"]},
		{"nivel": 7, "clientes": 19, "meta_1": 145, "meta_2": 205, "meta_3": 265, "intervalo_spawn": 4.6, "paciencia_base": 23.5, "max_items": 3, "menu": ["burger_sola", "burger_queso", "patatas", "refresco"]},
		{"nivel": 8, "clientes": 20, "meta_1": 165, "meta_2": 235, "meta_3": 300, "intervalo_spawn": 4.4, "paciencia_base": 23.0, "max_items": 3, "menu": ["burger_sola", "burger_queso", "burger_completa", "patatas", "refresco"]},
		{"nivel": 9, "clientes": 21, "meta_1": 180, "meta_2": 255, "meta_3": 330, "intervalo_spawn": 4.2, "paciencia_base": 22.0, "max_items": 3, "menu": ["burger_sola", "burger_queso", "burger_completa", "patatas", "refresco"]},
		{"nivel": 10, "clientes": 22, "meta_1": 200, "meta_2": 285, "meta_3": 365, "intervalo_spawn": 4.0, "paciencia_base": 21.5, "max_items": 3, "menu": ["burger_sola", "burger_queso", "burger_completa", "patatas", "refresco"]},
		{"nivel": 11, "clientes": 24, "meta_1": 220, "meta_2": 310, "meta_3": 400, "intervalo_spawn": 3.8, "paciencia_base": 21.0, "max_items": 3, "menu": ["burger_sola", "burger_queso", "burger_completa", "burger_doble", "patatas", "refresco"]},
		{"nivel": 12, "clientes": 25, "meta_1": 235, "meta_2": 335, "meta_3": 430, "intervalo_spawn": 3.7, "paciencia_base": 20.0, "max_items": 3, "menu": ["burger_sola", "burger_queso", "burger_completa", "burger_doble", "patatas", "refresco"]},
		{"nivel": 13, "clientes": 27, "meta_1": 255, "meta_2": 360, "meta_3": 465, "intervalo_spawn": 3.5, "paciencia_base": 19.5, "max_items": 3, "menu": ["burger_sola", "burger_queso", "burger_completa", "burger_doble", "patatas", "refresco"]},
		{"nivel": 14, "clientes": 29, "meta_1": 275, "meta_2": 385, "meta_3": 495, "intervalo_spawn": 3.3, "paciencia_base": 19.0, "max_items": 3, "menu": ["burger_sola", "burger_queso", "burger_completa", "burger_doble", "patatas", "refresco"]},
		{"nivel": 15, "clientes": 31, "meta_1": 295, "meta_2": 415, "meta_3": 535, "intervalo_spawn": 3.1, "paciencia_base": 18.0, "max_items": 3, "menu": ["burger_sola", "burger_queso", "burger_completa", "burger_doble", "patatas", "refresco"]}
	]

	_restaurantes = {
		RESTAURANTE_BURGER: {
			"id": RESTAURANTE_BURGER,
			"nombre": "Burger & Street Food",
			"subtitulo": "Hamburguesas, patatas fritas y refrescos",
			"implementado": true,
			"trabajo_requerido": "Comida Rápida",
			"trabajos_ids": ["Trabajar_En_Comida_Rapida"],
			"niveles": niveles_burger
		},
		RESTAURANTE_BISTRO: {
			"id": RESTAURANTE_BISTRO,
			"nombre": "Bistró Tradicional",
			"subtitulo": "Filetes al punto, salsas artesanas y postres",
			"implementado": false,
			"trabajo_requerido": "Ayudante de Cocina",
			"trabajos_ids": ["Trabajar_De_Ayudante_Cocina"],
			"niveles": []
		},
		RESTAURANTE_MERCADO: {
			"id": RESTAURANTE_MERCADO,
			"nombre": "Cocina de Mercado",
			"subtitulo": "Producto fresco, arroces y guisos de temporada",
			"implementado": false,
			"trabajo_requerido": "Cocinero de Partida",
			"trabajos_ids": ["Trabajar_De_Cocinero_Partida"],
			"niveles": []
		},
		RESTAURANTE_ALTA: {
			"id": RESTAURANTE_ALTA,
			"nombre": "Alta Cocina Gourmet",
			"subtitulo": "Platos de autor y servicio de estrellas",
			"implementado": false,
			"trabajo_requerido": "Chef Ejecutivo",
			"trabajos_ids": ["Trabajar_De_Chef_Ejecutivo"],
			"niveles": []
		}
	}


# ============================================================================
# Funciones puras / estáticas (testeables directamente en GUT)
# ============================================================================

static func Es_Trabajo_Hosteleria(nombre_trabajo: String) -> bool:
	return TRABAJO_A_RESTAURANTE.has(nombre_trabajo)


static func Restaurante_Para_Trabajo(nombre_trabajo: String) -> String:
	return str(TRABAJO_A_RESTAURANTE.get(nombre_trabajo, ""))


static func Obtener_Multiplicador_Plancha(nivel_plancha: int) -> float:
	var idx: int = clampi(nivel_plancha, 1, 3) - 1
	return float(MEJORAS_DEF["plancha"]["mult_tiempo"][idx])


static func Obtener_Huecos_Plancha(nivel_plancha: int) -> int:
	var idx: int = clampi(nivel_plancha, 1, 3) - 1
	return int(MEJORAS_DEF["plancha"]["huecos"][idx])


static func Obtener_Cestas_Freidora(nivel_plancha: int) -> int:
	var idx: int = clampi(nivel_plancha, 1, 3) - 1
	return int(MEJORAS_DEF["plancha"]["cestas_freidora"][idx])


static func Obtener_Huecos_Platos(nivel_emplatado: int) -> int:
	var idx: int = clampi(nivel_emplatado, 1, 3) - 1
	return int(MEJORAS_DEF["emplatado"]["platos"][idx])


static func Obtener_Capacidad_Bebidas(nivel_emplatado: int) -> int:
	var idx: int = clampi(nivel_emplatado, 1, 3) - 1
	return int(MEJORAS_DEF["emplatado"]["bebidas"][idx])


static func Obtener_Tiempo_Bebida(nivel_emplatado: int) -> float:
	var idx: int = clampi(nivel_emplatado, 1, 3) - 1
	return float(MEJORAS_DEF["emplatado"]["tiempo_bebida"][idx])


static func Obtener_Tiempo_Quemado_Base(nivel_termostato: int) -> float:
	var idx: int = clampi(nivel_termostato, 1, 3) - 1
	return float(MEJORAS_DEF["termostato"]["tiempo_quemado"][idx])


static func Tiene_Aviso_Temprano_Termostato(nivel_termostato: int) -> bool:
	var idx: int = clampi(nivel_termostato, 1, 3) - 1
	return bool(MEJORAS_DEF["termostato"]["aviso_temprano"][idx])


static func Obtener_Multiplicador_Ingredientes(nivel_ingredientes: int) -> float:
	var idx: int = clampi(nivel_ingredientes, 1, 3) - 1
	return float(MEJORAS_DEF["ingredientes"]["mult_precio"][idx])


static func Obtener_Multiplicador_Paciencia_Ambiente(nivel_ambiente: int) -> float:
	var idx: int = clampi(nivel_ambiente, 1, 3) - 1
	return float(MEJORAS_DEF["ambiente"]["mult_paciencia"][idx])


static func Obtener_Multiplicador_Propinas_Ambiente(nivel_ambiente: int) -> float:
	var idx: int = clampi(nivel_ambiente, 1, 3) - 1
	return float(MEJORAS_DEF["ambiente"]["mult_propinas"][idx])


# --- Datos de presentación de las mejoras (pantalla de Mejoras) ------------

static func Obtener_Info_Nivel_Mejora(mejora_id: String, nivel: int) -> Dictionary:
	if not MEJORAS_DEF.has(mejora_id):
		return {}
	var niveles: Array = MEJORAS_DEF[mejora_id].get("niveles", [])
	var idx: int = clampi(nivel, 1, 3) - 1
	if idx < 0 or idx >= niveles.size():
		return {}
	return niveles[idx]


static func Obtener_Nombre_Nivel_Mejora(mejora_id: String, nivel: int) -> String:
	return str(Obtener_Info_Nivel_Mejora(mejora_id, nivel).get("nombre", NOMBRES_NIVEL_MEJORA[clampi(nivel, 1, 3) - 1]))


static func Obtener_Beneficios_Nivel_Mejora(mejora_id: String, nivel: int) -> Array:
	return Obtener_Info_Nivel_Mejora(mejora_id, nivel).get("beneficios", [])


static func Obtener_Ganancias_Nivel_Mejora(mejora_id: String, nivel: int) -> Array:
	return Obtener_Info_Nivel_Mejora(mejora_id, nivel).get("ganancias", [])


static func Obtener_Frase_Nivel_Mejora(mejora_id: String, nivel: int) -> String:
	return str(Obtener_Info_Nivel_Mejora(mejora_id, nivel).get("frase", ""))


static func Calcular_Tiempo_Coccion(base_seg: float, nivel_plancha: int, destreza_innata: float) -> float:
	var mult_plancha: float = Obtener_Multiplicador_Plancha(nivel_plancha)
	var destreza_norm: float = clampf(destreza_innata, 0.0, 100.0) / 100.0
	var mult_destreza: float = 1.0 - 0.15 * destreza_norm
	return maxf(0.5, base_seg * mult_plancha * mult_destreza)


static func Calcular_Tiempo_Quemado(nivel_termostato: int, paciencia_innata: float, tiene_resacon: bool) -> float:
	var base_quemado: float = Obtener_Tiempo_Quemado_Base(nivel_termostato)
	var paciencia_norm: float = clampf(paciencia_innata, 0.0, 100.0) / 100.0
	var mult_paciencia: float = 1.0 + 0.15 * paciencia_norm
	var mult_resacon: float = 0.85 if tiene_resacon else 1.0
	return base_quemado * mult_paciencia * mult_resacon


static func Calcular_Velocidad_Paciencia(nivel_ambiente: int, paciencia_innata: float,
		sangre_fria: float, descanso: float, salud_mental: float) -> float:
	var mult_ambiente: float = Obtener_Multiplicador_Paciencia_Ambiente(nivel_ambiente)
	var pac_norm: float = clampf(paciencia_innata, 0.0, 100.0) / 100.0
	var sf_norm: float = clampf(sangre_fria, 0.0, 100.0) / 100.0
	var mult_hab: float = 1.0 - 0.10 * pac_norm - 0.10 * sf_norm
	var mult_fatiga: float = 1.20 if (descanso < 25.0 or salud_mental < 25.0) else 1.0
	return (1.0 / mult_ambiente) * mult_hab * mult_fatiga


static func Calcular_Precio_Plato(precio_base: int, nivel_ingredientes: int) -> int:
	return int(round(float(precio_base) * Obtener_Multiplicador_Ingredientes(nivel_ingredientes)))


static func Calcular_Propina_Cliente(precio_pedido: int, ratio_paciencia: float, combo: int,
		nivel_ambiente: int, bonus_ropa_propinas: float = 0.0) -> int:
	var pct_base: float = 0.0
	if ratio_paciencia >= 0.50:
		pct_base = 0.25
	elif ratio_paciencia >= 0.25:
		pct_base = 0.12
	else:
		pct_base = 0.0
	var propina_raw: float = float(maxi(0, precio_pedido)) * pct_base
	var combo_clamped: int = clampi(combo, 1, 5)
	if combo_clamped >= 2:
		propina_raw += float((combo_clamped - 1) * 3)
	var mult_ambiente: float = Obtener_Multiplicador_Propinas_Ambiente(nivel_ambiente)
	var mult_ropa: float = 1.0 + maxf(0.0, bonus_ropa_propinas)
	return int(round(propina_raw * mult_ambiente * mult_ropa))


static func Calcular_Estrellas(ventas: int, meta_1: int, meta_2: int, meta_3: int) -> int:
	if ventas >= meta_3:
		return 3
	if ventas >= meta_2:
		return 2
	if ventas >= meta_1:
		return 1
	return 0


# --- Costes, beneficio y reparto del servicio ---

static func Calcular_Coste_Ingredientes(ventas: int) -> int:
	return int(round(float(maxi(0, ventas)) * COSTE_INGREDIENTES_RATIO))


static func Calcular_Coste_Servicio(nivel: int) -> int:
	var n: int = maxi(1, nivel)
	return int(round(COSTE_SERVICIO_BASE_EUR + COSTE_SERVICIO_POR_NIVEL_EUR * float(n)))


static func Calcular_Coste_Merma(desperdicio_valor: int) -> int:
	return int(round(float(maxi(0, desperdicio_valor)) * COSTE_MERMA_RATIO))


static func Calcular_Costes_Totales(ventas: int, nivel: int, desperdicio_valor: int = 0) -> int:
	return Calcular_Coste_Ingredientes(ventas) + Calcular_Coste_Servicio(nivel) \
		+ Calcular_Coste_Merma(desperdicio_valor)


static func Calcular_Beneficio_Neto(ventas: int, nivel: int, desperdicio_valor: int = 0) -> int:
	return maxi(0, maxi(0, ventas) - Calcular_Costes_Totales(ventas, nivel, desperdicio_valor))


## Parte del beneficio que se lleva el Sim. En modo práctica se reduce al 25%.
static func Calcular_Reparto_Sim(beneficio_neto: int, modo_practica: bool = false) -> int:
	var reparto: float = float(maxi(0, beneficio_neto)) * REPARTO_BENEFICIO_SIM
	if modo_practica:
		reparto *= MULT_MODO_PRACTICA
	return int(round(reparto))


static func Calcular_Caja_Ganada(beneficio_neto: int, reparto_sim: int) -> int:
	return maxi(0, maxi(0, beneficio_neto) - maxi(0, reparto_sim))


## Prima única por mejorar estrellas. Se paga contra los umbrales del nivel,
## así que escalar de nivel multiplica la recompensa sin premiar el farmeo del 1.
static func Calcular_Bono_Estrellas_Eur(estrellas_previas: int, estrellas_nuevas: int,
		meta_1: int, meta_2: int, meta_3: int, mult_precios: float) -> float:
	var prev: int = clampi(estrellas_previas, 0, 3)
	var nuevo: int = clampi(estrellas_nuevas, 0, 3)
	if nuevo <= prev:
		return 0.0
	var metas: Array[int] = [maxi(0, meta_1), maxi(0, meta_2), maxi(0, meta_3)]
	var suma_base: float = 0.0
	for s in range(prev, nuevo):
		suma_base += float(metas[s]) * BONO_ESTRELLA_RATIO
	return round(suma_base * mult_precios * 100.0) / 100.0


static func Calcular_Propinas_Netas_Eur(propinas_servicio: int, estrellas: int, en_turno: bool,
		mult_precios: float, bonus_ropa_propinas: float = 0.0,
		modo_practica: bool = false) -> float:
	if estrellas < 1 or propinas_servicio <= 0:
		return 0.0
	var base_eur: float = float(propinas_servicio) * RATIO_PROPINA_MONEDA_A_EUR
	var mult_turno: float = 1.5 if en_turno else 1.0
	var mult_ropa: float = 1.0 + maxf(0.0, bonus_ropa_propinas)
	var mult_practica: float = MULT_MODO_PRACTICA if modo_practica else 1.0
	return round(base_eur * mult_turno * mult_ropa * mult_precios * mult_practica * 100.0) / 100.0


static func Calcular_Tasa_Drop_Cocina(en_turno: bool, modo_rapido: bool) -> float:
	var mult_turno: float = 2.0 if en_turno else 1.0
	var mult_rapido: float = 7.0 if modo_rapido else 1.0
	return PROB_MICRO_COCINA_BASE * mult_turno * mult_rapido


static func Calcular_Tasa_Drop_Manualidades(modo_rapido: bool) -> float:
	var mult_rapido: float = 7.0 if modo_rapido else 1.0
	return PROB_MICRO_MANUALIDADES_BASE * mult_rapido


static func Resolver_Drops_Enteros(tasa: float, roll: float = -1.0) -> int:
	if tasa <= 0.0:
		return 0
	var garantizados: int = int(floor(tasa))
	var resto: float = tasa - float(garantizados)
	var tirada: float = roll if roll >= 0.0 else randf()
	var extra: int = 1 if (resto > 0.0 and tirada < resto) else 0
	return garantizados + extra


static func Calcular_Rango_Logro(niveles_superados: int) -> int:
	return clampi(maxi(0, niveles_superados) / 5, 0, 9)


static func Obtener_Prenda_Por_Rango(rango: int) -> String:
	var r: int = clampi(rango, 0, RANGOS_LOGRO.size() - 1)
	return str(RANGOS_LOGRO[r].get("prenda", ""))


static func Obtener_Prendas_Hasta_Rango(rango: int) -> Array[String]:
	var resultado: Array[String] = []
	var max_r: int = clampi(rango, 0, RANGOS_LOGRO.size() - 1)
	for i in range(1, max_r + 1):
		var prenda: String = str(RANGOS_LOGRO[i].get("prenda", ""))
		if prenda != "":
			resultado.append(prenda)
	return resultado


static func Calcular_Multiplicador_Salario_Hosteleria(bonus_ropa: float, plus_nomina_turno: bool) -> float:
	return 1.0 + maxf(0.0, bonus_ropa) + (PLUS_NOMINA_TURNO_BONUS if plus_nomina_turno else 0.0)


static func Calcular_Probabilidad_Desgaste_Higiene(prob_base: float, reduccion_ropa: float) -> float:
	return maxf(0.0, prob_base * (1.0 - clampf(reduccion_ropa, 0.0, 0.95)))


static func Identificar_Hamburguesa(tiene_pan: bool, carnes: int, queso: bool,
		lechuga: bool, tomate: bool) -> String:
	if not tiene_pan or carnes <= 0:
		return ""
	if carnes == 1 and not queso and not lechuga and not tomate:
		return "burger_sola"
	if carnes == 1 and queso and not lechuga and not tomate:
		return "burger_queso"
	if carnes == 1 and queso and lechuga and tomate:
		return "burger_completa"
	if carnes == 2 and queso and not lechuga and not tomate:
		return "burger_doble"
	return ""


# ============================================================================
# Consultas de catálogo y estado
# ============================================================================

func Obtener_Estado() -> Dictionary:
	if not (Variables_Dinamicas.Cocina_Estado is Dictionary) or Variables_Dinamicas.Cocina_Estado.is_empty():
		Variables_Dinamicas.Cocina_Estado = Variables_Dinamicas.Cocina_Estado_Por_Defecto()
	return Variables_Dinamicas.Cocina_Estado


func Obtener_Restaurante(restaurante_id: String) -> Dictionary:
	if _restaurantes.is_empty():
		_Inicializar_Restaurantes()
	return _restaurantes.get(restaurante_id, {})


func Obtener_Nombre_Restaurante(restaurante_id: String) -> String:
	var r: Dictionary = Obtener_Restaurante(restaurante_id)
	return str(r.get("nombre", restaurante_id))


func Obtener_Config_Nivel(restaurante_id: String, nivel: int) -> Dictionary:
	var r: Dictionary = Obtener_Restaurante(restaurante_id)
	var niveles: Array = r.get("niveles", [])
	var idx: int = nivel - 1
	if idx < 0 or idx >= niveles.size():
		return {}
	return niveles[idx]


func Obtener_Fondos_Cocina() -> int:
	return maxi(0, int(Obtener_Estado().get("fondos_cocina", 0)))


## Caja del restaurante en euros. Sustituye a los antiguos "Fondos" y paga las
## 5 mejoras. El dinero personal del Sim no se mezcla con ella.
func Obtener_Caja_Restaurante() -> int:
	return Obtener_Fondos_Cocina()


func Obtener_Rango_Logro() -> int:
	return clampi(int(Obtener_Estado().get("rango_logro", 0)), 0, 9)


func Obtener_Info_Rango(rango: int = -1) -> Dictionary:
	var r: int = clampi(rango if rango >= 0 else Obtener_Rango_Logro(), 0, RANGOS_LOGRO.size() - 1)
	return RANGOS_LOGRO[r]


func Es_Inmune_Intoxicacion() -> bool:
	return Obtener_Rango_Logro() >= 8


func Esta_Desbloqueado_Minijuego() -> bool:
	var desbl: Array = Obtener_Estado().get("restaurantes_desbloqueados", [])
	return not desbl.is_empty()


func Esta_Desbloqueado_Restaurante(restaurante_id: String) -> bool:
	var desbl: Array = Obtener_Estado().get("restaurantes_desbloqueados", [])
	return desbl.has(restaurante_id)


func Obtener_Estrellas_Nivel(restaurante_id: String, nivel: int) -> int:
	var estrellas_dict: Dictionary = Obtener_Estado().get("estrellas_nivel", {})
	var clave: String = "%s_%d" % [restaurante_id, nivel]
	return clampi(int(estrellas_dict.get(clave, 0)), 0, 3)


func Esta_Nivel_Desbloqueado(restaurante_id: String, nivel: int) -> bool:
	if not Esta_Desbloqueado_Restaurante(restaurante_id):
		return false
	var r: Dictionary = Obtener_Restaurante(restaurante_id)
	if not bool(r.get("implementado", false)):
		return false
	if nivel <= 1:
		return true
	return Obtener_Estrellas_Nivel(restaurante_id, nivel - 1) >= 1


func Contar_Niveles_Superados(restaurante_id: String = "") -> int:
	var estrellas_dict: Dictionary = Obtener_Estado().get("estrellas_nivel", {})
	var total: int = 0
	for clave_raw in estrellas_dict.keys():
		var clave: String = str(clave_raw)
		if restaurante_id != "" and not clave.begins_with(restaurante_id + "_"):
			continue
		if int(estrellas_dict[clave_raw]) >= 1:
			total += 1
	return total


func Contar_Estrellas_Totales(restaurante_id: String = "") -> int:
	var estrellas_dict: Dictionary = Obtener_Estado().get("estrellas_nivel", {})
	var total: int = 0
	for clave_raw in estrellas_dict.keys():
		var clave: String = str(clave_raw)
		if restaurante_id != "" and not clave.begins_with(restaurante_id + "_"):
			continue
		total += clampi(int(estrellas_dict[clave_raw]), 0, 3)
	return total


func Obtener_Nivel_Mejora(restaurante_id: String, mejora_id: String) -> int:
	var mejoras_all: Dictionary = Obtener_Estado().get("mejoras", {})
	var rest_mejoras: Dictionary = mejoras_all.get(restaurante_id, {})
	return clampi(int(rest_mejoras.get(mejora_id, 1)), 1, 3)


func Obtener_Coste_Siguiente_Mejora(restaurante_id: String, mejora_id: String) -> int:
	if not MEJORAS_DEF.has(mejora_id):
		return -1
	var nivel_actual: int = Obtener_Nivel_Mejora(restaurante_id, mejora_id)
	if nivel_actual >= 3:
		return -1
	return int(MEJORAS_DEF[mejora_id]["costes"][nivel_actual])


func Comprar_Mejora(restaurante_id: String, mejora_id: String) -> Dictionary:
	if not MEJORAS_DEF.has(mejora_id):
		return {"exito": false, "motivo": "mejora_invalida"}
	var estado: Dictionary = Obtener_Estado()
	var mejoras_all: Dictionary = estado.get("mejoras", {})
	if not mejoras_all.has(restaurante_id):
		return {"exito": false, "motivo": "restaurante_invalido"}
	var nivel_actual: int = Obtener_Nivel_Mejora(restaurante_id, mejora_id)
	if nivel_actual >= 3:
		return {"exito": false, "motivo": "nivel_maximo"}
	var coste: int = int(MEJORAS_DEF[mejora_id]["costes"][nivel_actual])
	var caja: int = Obtener_Caja_Restaurante()
	if caja < coste:
		return {"exito": false, "motivo": "fondos_insuficientes", "coste": coste, "fondos": caja}
	estado["fondos_cocina"] = caja - coste
	mejoras_all[restaurante_id][mejora_id] = nivel_actual + 1
	Guardar_Variables_Dinamicas.save_game()
	return {
		"exito": true,
		"nuevo_nivel": nivel_actual + 1,
		"coste": coste,
		"fondos_restantes": int(estado["fondos_cocina"])
	}


## Servicios que aún pagan propinas y parte del beneficio al 100% hoy.
## Fuera de turno son 2; en turno no hay límite y no consume esta cuota.
func Obtener_Servicios_Completos_Restantes_Hoy() -> int:
	var estado: Dictionary = Obtener_Estado()
	if int(estado.get("ultimo_dia_remunerado", -1)) != int(Variables_Dinamicas.Minute_Day):
		return LIMITE_SERVICIOS_COMPLETOS_DIA
	var usados: int = maxi(0, int(estado.get("servicios_remunerados_hoy", 0)))
	return maxi(0, LIMITE_SERVICIOS_COMPLETOS_DIA - usados)


func Obtener_Servicios_Remunerados_Restantes_Hoy() -> int:
	return Obtener_Servicios_Completos_Restantes_Hoy()


# ============================================================================
# Desbloqueo en primer minuto trabajado, turno activo y bloqueos de entrada
# ============================================================================

func Registrar_Minuto_Trabajo_Hosteleria(nombre_trabajo: String) -> bool:
	var rest_id: String = Restaurante_Para_Trabajo(nombre_trabajo)
	if rest_id == "":
		return false
	var estado: Dictionary = Obtener_Estado()
	var desbl: Array = estado.get("restaurantes_desbloqueados", [])
	if desbl.has(rest_id):
		return false

	var es_primero: bool = desbl.is_empty()
	desbl.append(rest_id)
	estado["restaurantes_desbloqueados"] = desbl

	var rest_cfg: Dictionary = Obtener_Restaurante(rest_id)
	var implementado: bool = bool(rest_cfg.get("implementado", false))
	var nombre_rest: String = Obtener_Nombre_Restaurante(rest_id)
	var titulo_msg: String
	if es_primero:
		titulo_msg = "¡Nuevo minijuego desbloqueado: Cocina!"
	elif implementado:
		titulo_msg = "Nuevo restaurante desbloqueado: %s" % nombre_rest
	else:
		titulo_msg = "Nuevo mundo de cocina desbloqueado: %s (Fase 2)" % nombre_rest
	var desc_msg: String
	if es_primero:
		desc_msg = "Has empezado tu primer turno en hostelería y has desbloqueado %s en el apartado Minijuegos.\n\nEntra desde la barra superior (Minijuegos) para atender pedidos, ganar propinas, mejorar tu cocina y subir tu Maestría Culinaria." % nombre_rest
	elif implementado:
		desc_msg = "Tu experiencia en hostelería ha desbloqueado %s en el apartado Minijuegos." % nombre_rest
	else:
		desc_msg = "Tu experiencia en hostelería ha desbloqueado %s. Su mundo de cocina llegará al apartado Minijuegos en la Fase 2." % nombre_rest

	_Agregar_Mensaje_Buzon(titulo_msg, desc_msg)
	Guardar_Variables_Dinamicas.save_game()
	restaurante_desbloqueado.emit(rest_id, nombre_rest)
	return true


func Esta_En_Turno_Activo(restaurante_id: String = "") -> bool:
	var matriz: Array = Variables_Dinamicas.Matriz_Jugador
	if matriz.size() < 1440:
		return false
	var fila_idx: int = int(Variables_Dinamicas.Minute_Minute)
	var col_idx: int = int(Variables_Dinamicas.Minute_Day)
	if fila_idx < 0 or fila_idx >= matriz.size():
		return false
	if col_idx < 0 or col_idx >= (matriz[fila_idx] as Array).size():
		return false
	var celda = matriz[fila_idx][col_idx]
	if not (celda is Actividad_Fija_Trabajo):
		return false
	var rest_celda: String = Restaurante_Para_Trabajo(celda.nombre)
	if rest_celda == "":
		return false
	if restaurante_id == "":
		return true
	return rest_celda == restaurante_id


func Hay_Examen_Activo_O_Inminente(ventana_min: int = 5) -> bool:
	var matriz: Array = Variables_Dinamicas.Matriz_Jugador
	if matriz.size() >= 1440:
		var dia_base: int = int(Variables_Dinamicas.Minute_Day)
		var min_base: int = int(Variables_Dinamicas.Minute_Minute)
		for offset in range(maxi(0, ventana_min) + 1):
			var d: int = dia_base
			var m: int = min_base + offset
			while m >= 1440:
				m -= 1440
				d += 1
			if d < 0 or d >= 574 or m < 0 or m >= matriz.size():
				continue
			if d >= (matriz[m] as Array).size():
				continue
			var celda = matriz[m][d]
			if celda is Actividad_Examen:
				return true
			if celda is Actividad and celda.nombre == "Examen_Carrera":
				return true

	# Respaldo directo contra Carrera_Actual si está matriculado y el examen es hoy
	var carrera = Variables_Dinamicas.Carrera_Actual
	if carrera != null and carrera.matriculado and not carrera.completada \
			and not carrera.fin_de_semana_procesado and int(carrera.hora_examen_dia) >= 0:
		var dia_actual: int = int(Variables_Dinamicas.Minute_Day)
		var es_hoy: bool = (dia_actual == int(carrera.hora_examen_dia)) if Variables_Estaticas.Modo_Rapido \
			else ((dia_actual % 7) == int(carrera.hora_examen_dia))
		if es_hoy:
			var m_actual: int = int(Variables_Dinamicas.Minute_Minute)
			var h_ini: int = int(carrera.hora_examen_inicio)
			if m_actual >= h_ini - maxi(0, ventana_min) and m_actual < h_ini + 60:
				return true

	return false


func Puede_Entrar_Minijuego() -> Dictionary:
	if not Esta_Desbloqueado_Minijuego():
		return {
			"permitido": false,
			"motivo": "bloqueado",
			"mensaje": "Trabaja al menos 1 minuto en Comida Rápida u hostelería para desbloquearlo."
		}
	if Variables_Dinamicas.Necesidades_Basicas.size() >= 4 \
			and float(Variables_Dinamicas.Necesidades_Basicas[3]) <= 5.0:
		return {
			"permitido": false,
			"motivo": "descanso_bajo",
			"mensaje": "Tu Sim está demasiado agotado (Descanso ≤ 5). Descansa antes de entrar en cocina."
		}
	if Hay_Examen_Activo_O_Inminente(5):
		return {
			"permitido": false,
			"motivo": "examen_inminente",
			"mensaje": "Tienes un examen universitario en curso o en menos de 5 minutos. ¡No puedes entrar a la cocina ahora!"
		}
	return {"permitido": true, "motivo": "", "mensaje": ""}


# ============================================================================
# Micro-recompensas por cliente y cierre de nivel
# ============================================================================

func Procesar_Micro_Recompensa_Cliente(en_turno: bool, micro_propinas_acumuladas: float,
		rolls: Dictionary = {}, modo_practica: bool = false) -> Dictionary:
	var resultado: Dictionary = {
		"cocina_ganada": 0,
		"manualidades_ganadas": 0,
		"necesidad_indice": -1,
		"necesidad_ganada": 0,
		"micro_propina_eur": 0.0
	}

	var modo_rapido: bool = Variables_Estaticas.Modo_Rapido
	var tasa_cocina: float = Calcular_Tasa_Drop_Cocina(en_turno, modo_rapido)
	var roll_cocina: float = float(rolls.get("cocina", -1.0))
	var drops_cocina: int = Resolver_Drops_Enteros(tasa_cocina, roll_cocina)
	if drops_cocina > 0 and Variables_Dinamicas.Progreso_Cocina < 100:
		var antes_c: int = Variables_Dinamicas.Progreso_Cocina
		Variables_Dinamicas.Progreso_Cocina = mini(100, Variables_Dinamicas.Progreso_Cocina + drops_cocina)
		resultado["cocina_ganada"] = Variables_Dinamicas.Progreso_Cocina - antes_c

	var tasa_man: float = Calcular_Tasa_Drop_Manualidades(modo_rapido)
	var roll_man: float = float(rolls.get("manualidades", -1.0))
	var drops_man: int = Resolver_Drops_Enteros(tasa_man, roll_man)
	if drops_man > 0 and Variables_Dinamicas.Progreso.size() >= 3 and Variables_Dinamicas.Progreso[2] < 100:
		var antes_m: int = int(Variables_Dinamicas.Progreso[2])
		Variables_Dinamicas.Progreso[2] = mini(100, antes_m + drops_man)
		resultado["manualidades_ganadas"] = int(Variables_Dinamicas.Progreso[2]) - antes_m
		while Variables_Dinamicas.Ultimo_Uso_Progreso.size() < 3:
			Variables_Dinamicas.Ultimo_Uso_Progreso.append(-1)
		Variables_Dinamicas.Ultimo_Uso_Progreso[2] = Variables_Dinamicas.Minute

	# 12% de +1 en Salud Mental (1) o Hambre (2), respetando caps de calle/bancarrota/resacón
	var roll_nec: float = float(rolls.get("necesidad", randf()))
	if roll_nec < PROB_MICRO_NECESIDAD_BASE and Variables_Dinamicas.Necesidades_Basicas.size() >= 3:
		var idx_nec: int = int(rolls.get("necesidad_idx", 1 if randi() % 2 == 0 else 2))
		if idx_nec != 1 and idx_nec != 2:
			idx_nec = 1
		var antes_n: int = int(Variables_Dinamicas.Necesidades_Basicas[idx_nec])
		Actividades_Necesidades_Basicas.Cambiar_Necesidades_Basicas(1, idx_nec)
		var ganancia_n: int = maxi(0, int(Variables_Dinamicas.Necesidades_Basicas[idx_nec]) - antes_n)
		if ganancia_n > 0:
			resultado["necesidad_indice"] = idx_nec
			resultado["necesidad_ganada"] = ganancia_n

	# 10% de micro-propina (1-3 € * Multiplicador_Precios(), tope 6 € * Multiplicador_Precios() por partida).
	# En modo práctica también se reduce al 25%, como el resto del dinero personal.
	var mult_precios: float = Variables_Estaticas.Multiplicador_Precios()
	var mult_practica: float = MULT_MODO_PRACTICA if modo_practica else 1.0
	var tope_sesion: float = round(
		TOPE_MICRO_PROPINAS_BASE_EUR * mult_precios * mult_practica * 100.0) / 100.0
	var restante: float = maxf(0.0, tope_sesion - micro_propinas_acumuladas)
	var roll_prop: float = float(rolls.get("propina", randf()))
	if restante > 0.0001 and roll_prop < PROB_MICRO_PROPINA_BASE:
		var base_eur: float = float(rolls.get("propina_base", randi_range(1, 3)))
		base_eur = clampf(base_eur, MICRO_PROPINA_MIN_EUR, MICRO_PROPINA_MAX_EUR)
		var cantidad_eur: float = round(
			minf(restante, base_eur * mult_precios * mult_practica) * 100.0) / 100.0
		if cantidad_eur > 0.0:
			Variables_Dinamicas.Dinero += cantidad_eur
			resultado["micro_propina_eur"] = cantidad_eur

	return resultado


func Procesar_Fin_Nivel(restaurante_id: String, nivel: int, recaudacion: int,
		propinas_servicio: int, en_turno: bool, desperdicio_valor: int = 0) -> Dictionary:
	var estado: Dictionary = Obtener_Estado()
	var cfg: Dictionary = Obtener_Config_Nivel(restaurante_id, nivel)
	var meta_1: int = int(cfg.get("meta_1", 50))
	var meta_2: int = int(cfg.get("meta_2", 80))
	var meta_3: int = int(cfg.get("meta_3", 110))

	var dia_actual: int = int(Variables_Dinamicas.Minute_Day)
	if int(estado.get("ultimo_dia_remunerado", -1)) != dia_actual:
		estado["servicios_remunerados_hoy"] = 0
		estado["ultimo_dia_remunerado"] = dia_actual

	# El ticket incluye propinas (bonus de servicio para las estrellas), pero la
	# Caja solo ingresa las ventas de platos/bebidas: las propinas van al equipo.
	var ventas: int = maxi(0, recaudacion - propinas_servicio)
	var estrellas: int = Calcular_Estrellas(recaudacion, meta_1, meta_2, meta_3)

	# --- Caja del restaurante: ventas - ingredientes - servicio - merma ---
	var coste_ingredientes: int = Calcular_Coste_Ingredientes(ventas)
	var coste_servicio: int = Calcular_Coste_Servicio(nivel)
	var coste_merma: int = Calcular_Coste_Merma(desperdicio_valor)
	var costes_totales: int = coste_ingredientes + coste_servicio + coste_merma
	var beneficio_neto: int = Calcular_Beneficio_Neto(ventas, nivel, desperdicio_valor)

	# --- Estrellas y prima única por mejora de estrellas ---
	var estrellas_dict: Dictionary = estado.get("estrellas_nivel", {})
	var clave_nivel: String = "%s_%d" % [restaurante_id, nivel]
	var estrellas_previas: int = clampi(int(estrellas_dict.get(clave_nivel, 0)), 0, 3)

	var mult_precios: float = Variables_Estaticas.Multiplicador_Precios()
	var bono_estrellas_eur: float = Calcular_Bono_Estrellas_Eur(
		estrellas_previas, estrellas, meta_1, meta_2, meta_3, mult_precios)
	if estrellas > estrellas_previas:
		estrellas_dict[clave_nivel] = estrellas
		estado["estrellas_nivel"] = estrellas_dict

	# --- Reparto personal: propinas + parte del beneficio ---
	var propinas_eur: float = 0.0
	var reparto_sim: int = 0
	var modo_practica: bool = false
	var plus_nomina_activado: bool = false
	var bonus_ropa_propinas: float = Obtener_Bonus_Propinas_Ropa()

	if estrellas >= 1:
		if en_turno:
			propinas_eur = Calcular_Propinas_Netas_Eur(
				propinas_servicio, estrellas, true, mult_precios, bonus_ropa_propinas, false)
			reparto_sim = Calcular_Reparto_Sim(beneficio_neto, false)
			estado["plus_nomina_turno_hoy"] = true
			plus_nomina_activado = true
		else:
			var usados: int = maxi(0, int(estado.get("servicios_remunerados_hoy", 0)))
			if usados < LIMITE_SERVICIOS_COMPLETOS_DIA:
				propinas_eur = Calcular_Propinas_Netas_Eur(
					propinas_servicio, estrellas, false, mult_precios, bonus_ropa_propinas, false)
				reparto_sim = Calcular_Reparto_Sim(beneficio_neto, false)
				estado["servicios_remunerados_hoy"] = usados + 1
			else:
				modo_practica = true
				propinas_eur = Calcular_Propinas_Netas_Eur(
					propinas_servicio, estrellas, false, mult_precios, bonus_ropa_propinas, true)
				reparto_sim = Calcular_Reparto_Sim(beneficio_neto, true)

	var caja_ganada: int = Calcular_Caja_Ganada(beneficio_neto, reparto_sim)
	estado["fondos_cocina"] = Obtener_Caja_Restaurante() + caja_ganada

	var dinero_ganado: float = round(
		(bono_estrellas_eur + propinas_eur + float(reparto_sim)) * 100.0) / 100.0
	if dinero_ganado > 0.0:
		Variables_Dinamicas.Dinero += dinero_ganado

	# Logros progresivos cada 5 niveles superados y ropa equipable
	var niveles_superados: int = Contar_Niveles_Superados()
	if niveles_superados > Variables_Estaticas.Record_Max_Niveles_Cocina:
		Variables_Estaticas.Record_Max_Niveles_Cocina = niveles_superados
		Guardar_Variables_Estaticas.save_game()

	var rango_anterior: int = Obtener_Rango_Logro()
	var rango_nuevo: int = Calcular_Rango_Logro(niveles_superados)
	var prendas_desbloqueadas: Array[String] = []

	if rango_nuevo > rango_anterior:
		estado["rango_logro"] = rango_nuevo
		for r in range(rango_anterior + 1, rango_nuevo + 1):
			var info_r: Dictionary = RANGOS_LOGRO[r]
			var prenda: String = str(info_r.get("prenda", ""))
			if prenda != "":
				Variables_Dinamicas.Objetos_Poseidos[prenda] = true
				prendas_desbloqueadas.append(prenda)
			var msg_desc: String = "Has alcanzado el Rango %d/9 de Maestría Culinaria (%s) tras superar %d niveles.\n\nRecompensa: %s" % [
				r, str(info_r.get("nombre", "")), niveles_superados, str(info_r.get("beneficio", ""))
			]
			if prenda != "":
				msg_desc += "\n\nPuedes equipar %s en Vestuario (barra superior)." % Obtener_Nombre_Legible_Ropa(prenda)
			_Agregar_Mensaje_Buzon("Maestría Culinaria: Rango %d/9" % r, msg_desc)

	# Garantía idempotente de prendas hasta el rango alcanzado
	for p_clave in Obtener_Prendas_Hasta_Rango(maxi(rango_anterior, rango_nuevo)):
		if not bool(Variables_Dinamicas.Objetos_Poseidos.get(p_clave, false)):
			Variables_Dinamicas.Objetos_Poseidos[p_clave] = true

	Guardar_Variables_Dinamicas.save_game()

	return {
		"estrellas": estrellas,
		"estrellas_previas": estrellas_previas,
		"superado": estrellas >= 1,
		"ventas": ventas,
		"recaudacion": maxi(0, recaudacion),
		"propinas_servicio": maxi(0, propinas_servicio),
		"coste_ingredientes": coste_ingredientes,
		"coste_servicio": coste_servicio,
		"coste_merma": coste_merma,
		"costes_totales": costes_totales,
		"beneficio_neto": beneficio_neto,
		"reparto_sim": reparto_sim,
		"caja_ganada": caja_ganada,
		"fondos_ganados": caja_ganada,
		"bono_estrellas_eur": bono_estrellas_eur,
		"propinas_eur": propinas_eur,
		"dinero_ganado": dinero_ganado,
		"modo_practica": modo_practica,
		"limite_diario_alcanzado": modo_practica,
		"en_turno": en_turno,
		"plus_nomina_activado": plus_nomina_activado,
		"niveles_superados": niveles_superados,
		"rango_anterior": rango_anterior,
		"rango_nuevo": maxi(rango_anterior, rango_nuevo),
		"subio_rango": rango_nuevo > rango_anterior,
		"prendas_desbloqueadas": prendas_desbloqueadas
	}


# ============================================================================
# Ropa equipable y bonificaciones
# ============================================================================

func Obtener_Clave_Ropa_Equipada() -> String:
	var clave: String = str(Variables_Dinamicas.Objeto_Seleccionado.get("Ropa", "Ropa_Calle"))
	if clave == "" or not Variables_Estaticas.Catalogo_Objetos.has(clave):
		return "Ropa_Calle"
	return clave


func Obtener_Ropa_Equipada() -> Objeto_Ropa:
	var clave: String = Obtener_Clave_Ropa_Equipada()
	var obj = Variables_Estaticas.Catalogo_Objetos.get(clave, null)
	if obj is Objeto_Ropa:
		return obj as Objeto_Ropa
	var fallback = Variables_Estaticas.Catalogo_Objetos.get("Ropa_Calle", null)
	return fallback as Objeto_Ropa if fallback is Objeto_Ropa else null


func Obtener_Nombre_Legible_Ropa(clave: String) -> String:
	if NOMBRES_ROPA.has(clave):
		return str(NOMBRES_ROPA[clave])
	var obj = Variables_Estaticas.Catalogo_Objetos.get(clave, null)
	if obj is Objeto_Ropa and str(obj.nombre) != "":
		return str(obj.nombre).replace("_", " ")
	return clave.replace("_", " ")


## Prendas gratuitas que todo Sim recibe al empezar (o al cargar una partida
## antigua creada antes de que existiera el armario ampliado).
func Obtener_Prendas_Iniciales() -> Array[String]:
	var claves: Array[String] = []
	for clave in ORDEN_ROPA:
		var obj = Variables_Estaticas.Catalogo_Objetos.get(clave, null)
		if obj is Objeto_Ropa and str(obj.desbloqueo) == DESBLOQUEO_INICIO:
			claves.append(clave)
	return claves


func Asegurar_Prendas_Iniciales() -> void:
	for clave in Obtener_Prendas_Iniciales():
		Variables_Dinamicas.Objetos_Poseidos[clave] = true


func Obtener_Categoria_Ropa(clave: String) -> String:
	var obj = Variables_Estaticas.Catalogo_Objetos.get(clave, null)
	if obj is Objeto_Ropa:
		return str(obj.categoria)
	return "diario"


func Obtener_Desbloqueo_Ropa(clave: String) -> String:
	var obj = Variables_Estaticas.Catalogo_Objetos.get(clave, null)
	if obj is Objeto_Ropa:
		return str(obj.desbloqueo)
	return DESBLOQUEO_INICIO


## Precio de compra de la prenda, ya escalado por el modo de juego.
func Obtener_Precio_Ropa(clave: String) -> float:
	var obj = Variables_Estaticas.Catalogo_Objetos.get(clave, null)
	if not (obj is Objeto_Ropa):
		return 0.0
	return Variables_Estaticas.Obtener_Precio_Objeto(obj as Objeto)


## Una prenda es comprable si está en la tienda, tiene precio y aún no se posee.
func Es_Ropa_Comprable(clave: String) -> bool:
	var obj = Variables_Estaticas.Catalogo_Objetos.get(clave, null)
	if not (obj is Objeto_Ropa):
		return false
	if bool(Variables_Dinamicas.Objetos_Poseidos.get(clave, false)):
		return false
	return str(obj.desbloqueo) == DESBLOQUEO_TIENDA and obj.precio > 0.0


func Puede_Comprar_Ropa(clave: String) -> bool:
	return Es_Ropa_Comprable(clave) and Variables_Dinamicas.Dinero >= Obtener_Precio_Ropa(clave)


func Comprar_Ropa(clave: String) -> bool:
	if not Es_Ropa_Comprable(clave):
		return false
	var precio := Obtener_Precio_Ropa(clave)
	if Variables_Dinamicas.Dinero < precio:
		return false
	Variables_Dinamicas.Dinero -= precio
	Variables_Dinamicas.Objetos_Poseidos[clave] = true
	Guardar_Variables_Dinamicas.save_game()
	return true


## Apariencia del personaje con un atuendo concreto aplicado (para la vista
## previa del vestuario) sin modificar la apariencia guardada.
func Obtener_Apariencia_Con_Ropa(apariencia: Dictionary, clave: String) -> Dictionary:
	var obj = Variables_Estaticas.Catalogo_Objetos.get(clave, null)
	var ropa: Objeto_Ropa = obj as Objeto_Ropa if obj is Objeto_Ropa else null
	return Apariencia_Personaje.aplicar_atuendo(apariencia, ropa)


## Apariencia del personaje con la prenda equipada. Se usa en el escenario de
## Inicio, el avatar de cabecera, el retrato del perfil y el logo.
func Obtener_Apariencia_Con_Ropa_Equipada(apariencia: Dictionary) -> Dictionary:
	return Obtener_Apariencia_Con_Ropa(apariencia, Obtener_Clave_Ropa_Equipada())


## Rango de Maestría Culinaria necesario para desbloquear una prenda.
## Devuelve 0 si la prenda es inicial o no pertenece al sistema de rangos.
func Obtener_Rango_Requerido_Ropa(clave: String) -> int:
	for rango in RANGOS_LOGRO:
		if str(rango.get("prenda", "")) == clave:
			return int(rango["rango"])
	return 0


func Obtener_Bonus_Salario_Hosteleria() -> float:
	var ropa: Objeto_Ropa = Obtener_Ropa_Equipada()
	return ropa.bonus_salario_hosteleria if ropa != null else 0.0


func Obtener_Reduccion_Higiene_Hosteleria() -> float:
	var ropa: Objeto_Ropa = Obtener_Ropa_Equipada()
	return ropa.reduccion_higiene_trabajo if ropa != null else 0.0


func Obtener_Bonus_Propinas_Ropa() -> float:
	var ropa: Objeto_Ropa = Obtener_Ropa_Equipada()
	return ropa.bonus_propinas_minijuego if ropa != null else 0.0


func Obtener_Bonus_Salario_General() -> float:
	var ropa: Objeto_Ropa = Obtener_Ropa_Equipada()
	return ropa.bonus_salario_general if ropa != null else 0.0


## Bonus de progreso por índice: 0 = Deporte, 1 = Académico, 2 = Manualidades.
func Obtener_Bonus_Progreso(indice: int) -> float:
	var ropa: Objeto_Ropa = Obtener_Ropa_Equipada()
	if ropa == null:
		return 0.0
	match indice:
		0:
			return ropa.bonus_progreso_deporte
		1:
			return ropa.bonus_progreso_academico
		2:
			return ropa.bonus_progreso_manualidades
	return 0.0


## Reducción de desgaste de Higiene para un trabajo concreto. Los uniformes de
## hostelería y los de cualquier trabajo pueden acumular su mejor reducción.
func Obtener_Reduccion_Higiene_Para_Trabajo(nombre_trabajo: String) -> float:
	var ropa: Objeto_Ropa = Obtener_Ropa_Equipada()
	if ropa == null:
		return 0.0
	var reduccion := ropa.reduccion_higiene_cualquier_trabajo
	if Es_Trabajo_Hosteleria(nombre_trabajo):
		reduccion = maxf(reduccion, ropa.reduccion_higiene_trabajo)
	return clampf(reduccion, 0.0, 0.95)


func Equipar_Ropa(clave: String) -> bool:
	if not bool(Variables_Dinamicas.Objetos_Poseidos.get(clave, false)):
		return false
	var obj = Variables_Estaticas.Catalogo_Objetos.get(clave, null)
	if not (obj is Objeto_Ropa) or obj.afecta_a != "Ropa":
		return false
	Variables_Dinamicas.Objeto_Seleccionado["Ropa"] = clave
	Guardar_Variables_Dinamicas.save_game()
	return true


func _Agregar_Mensaje_Buzon(titulo: String, descripcion: String) -> void:
	var msg := Mensaje.new()
	msg.titulo = titulo
	msg.descripcion = descripcion
	msg.leido = false
	msg.minuto = Variables_Dinamicas.Minute_Day * 1440 + Variables_Dinamicas.Minute_Minute
	Variables_Dinamicas.Mensajes.append(msg)
