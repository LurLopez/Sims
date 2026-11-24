class_name Datos_Manager
extends RefCounted

# Datos estáticos del modo «El Mánager» (Fase 2 — Modo Club).
# Nombres, ciudades, roles, formaciones, tablas de atributos y economía.
# Ninguna función de este archivo lee Variables_Dinamicas: es una tabla pura
# que comparten el simulador, el autoload y la interfaz.

const VERSION_ESTADO: int = 1

# ------------------------------------------------------------------
# Divisiones
# ------------------------------------------------------------------

const DIVISIONES: Dictionary = {
	1: "Superliga",
	2: "1ª Élite",
	3: "2ª Nacional",
	4: "3ª Regional"
}

const DIVISIONES_CORTAS: Dictionary = {
	1: "Superliga",
	2: "1ª Élite",
	3: "2ª Nacional",
	4: "3ª Regional"
}

const CLUBES_POR_DIVISION: int = 4
const TOTAL_CLUBES: int = 16
const JUGADORES_POR_CLUB: int = 18
const PLANTILLA_MINIMA: int = 14
const PLANTILLA_MAXIMA: int = 18
const EDAD_MINIMA: int = 16
const EDAD_MAXIMA: int = 40

# ------------------------------------------------------------------
# Calendario
# ------------------------------------------------------------------

const DIA_PARTIDO_NORMAL: int = 6 # Domingo
const HORAS_PARTIDO_NORMAL: Array = [600, 780, 960, 1140] # 10:00, 13:00, 16:00, 19:00
const HORA_PARTIDO_RAPIDO: int = 1230 # 20:30
const HORA_CIERRE_JORNADA: int = 1439 # 23:59, auto-simulación
const JORNADAS_POR_TEMPORADA: int = 4
const DURACION_PARTIDO_MINUTOS: int = 90

# El partido en vivo dura ~5.4 minutos reales a x1 (40 s a x8).
const SEGUNDOS_POR_MINUTO_X1: float = 3.6
const VELOCIDADES: Array = [1, 2, 4, 8]
const CAMBIOS_MAXIMOS: int = 5

# Energía: +5 % cada 4 horas (240 min) en modo normal.
const RECUPERACION_POR_MINUTO_NORMAL: float = 5.0 / 240.0
const MULTIPLICADOR_RECUPERACION_RAPIDA: float = 7.0
const ENERGIA_MINIMA_EFECTIVA: float = 50.0
const COSTE_ENERGIA_ENTRENAMIENTO: float = 12.0
const COSTE_ENERGIA_ENTRENAMIENTO_LINEA: float = 8.0

# ------------------------------------------------------------------
# Roles posicionales Top Eleven
# ------------------------------------------------------------------

const ROLES: Array = [
	"POR", "DFC", "LD", "LI", "MCD", "MC", "MD", "MI", "MCO", "ED", "EI", "DEL"
]

const NOMBRES_ROLES: Dictionary = {
	"POR": "Portero",
	"DFC": "Defensa central",
	"LD": "Lateral derecho",
	"LI": "Lateral izquierdo",
	"MCD": "Mediocentro defensivo",
	"MC": "Mediocentro",
	"MD": "Mediocentro derecho",
	"MI": "Mediocentro izquierdo",
	"MCO": "Mediocentro ofensivo",
	"ED": "Extremo derecho",
	"EI": "Extremo izquierdo",
	"DEL": "Delantero"
}

const ROLES_PORTEROS: Array = ["POR"]
const ROLES_DEFENSA: Array = ["DFC", "LD", "LI"]
const ROLES_MEDIO: Array = ["MCD", "MC", "MD", "MI", "MCO"]
const ROLES_ATAQUE: Array = ["ED", "EI", "DEL"]

const COLORES_LINEA: Dictionary = {
	"POR": "#d97706",
	"DEF": "#2563eb",
	"MED": "#0d9488",
	"ATA": "#e11d48"
}

const ATRIBUTOS_CLAVE_ROL: Dictionary = {
	"POR": ["posicion", "valentia", "cabeceo", "condicion"],
	"DFC": ["entradas", "marcaje", "posicion", "cabeceo", "fuerza"],
	"LD": ["velocidad", "centros", "entradas", "marcaje", "condicion"],
	"LI": ["velocidad", "centros", "entradas", "marcaje", "condicion"],
	"MCD": ["entradas", "marcaje", "pase", "condicion", "fuerza"],
	"MC": ["pase", "creatividad", "condicion", "regate", "entradas"],
	"MD": ["centros", "velocidad", "pase", "regate"],
	"MI": ["centros", "velocidad", "pase", "regate"],
	"MCO": ["creatividad", "pase", "regate", "disparo"],
	"ED": ["regate", "velocidad", "centros", "disparo"],
	"EI": ["regate", "velocidad", "centros", "disparo"],
	"DEL": ["disparo", "definicion", "cabeceo", "velocidad"]
}

# Plantilla tipo de 18 futbolistas con una distribución jugable.
const PLANTILLA_ROLES: Array = [
	"POR", "POR",
	"DFC", "DFC", "DFC", "LD", "LI",
	"MCD", "MC", "MC", "MCO", "MD", "MI",
	"ED", "EI", "DEL", "DEL", "DEL"
]

const FORMACIONES: Array = ["4-4-2", "4-3-3", "3-5-2", "4-2-3-1"]

# Ranura → rol natural de cada una de las 11 posiciones.
const ROLES_FORMACION: Dictionary = {
	"4-4-2": ["POR", "LD", "DFC", "DFC", "LI", "MD", "MC", "MC", "MI", "DEL", "DEL"],
	"4-3-3": ["POR", "LD", "DFC", "DFC", "LI", "MCD", "MC", "MC", "ED", "DEL", "EI"],
	"3-5-2": ["POR", "DFC", "DFC", "DFC", "MD", "MC", "MCD", "MC", "MI", "DEL", "DEL"],
	"4-2-3-1": ["POR", "LD", "DFC", "DFC", "LI", "MCD", "MC", "MCO", "ED", "EI", "DEL"]
}

const MENTALIDADES: Array = ["defensiva", "equilibrada", "ofensiva"]
const PRESIONES: Array = ["baja", "media", "alta"]

const TACTICA_BASE: Dictionary = {
	"formacion": "4-4-2",
	"mentalidad": "equilibrada",
	"presion": "media"
}

# Afinidad de cada rol del jugador con la ranura de la formación.
# 1.0 = rol natural. Los valores ausentes usan AFINIDAD_MINIMA.
const AFINIDAD_ROL: Dictionary = {
	"POR": {"POR": 1.0},
	"DFC": {"DFC": 1.0, "LD": 0.74, "LI": 0.74, "MCD": 0.64, "MC": 0.45},
	"LD": {"LD": 1.0, "DFC": 0.80, "MD": 0.72, "MCD": 0.60, "MI": 0.46},
	"LI": {"LI": 1.0, "DFC": 0.80, "MI": 0.72, "MCD": 0.60, "MD": 0.46},
	"MCD": {"MCD": 1.0, "MC": 0.86, "DFC": 0.68, "MCO": 0.62, "LD": 0.55, "LI": 0.55},
	"MC": {"MC": 1.0, "MCD": 0.86, "MCO": 0.86, "MD": 0.74, "MI": 0.74, "DEL": 0.48},
	"MD": {"MD": 1.0, "MC": 0.84, "ED": 0.82, "MCO": 0.70, "LD": 0.62, "MI": 0.55},
	"MI": {"MI": 1.0, "MC": 0.84, "EI": 0.82, "MCO": 0.70, "LI": 0.62, "MD": 0.55},
	"MCO": {"MCO": 1.0, "MC": 0.84, "DEL": 0.72, "ED": 0.68, "EI": 0.68, "MD": 0.62, "MI": 0.62},
	"ED": {"ED": 1.0, "MD": 0.80, "EI": 0.66, "DEL": 0.68, "MCO": 0.66},
	"EI": {"EI": 1.0, "MI": 0.80, "ED": 0.66, "DEL": 0.68, "MCO": 0.66},
	"DEL": {"DEL": 1.0, "MCO": 0.70, "ED": 0.68, "EI": 0.68, "MC": 0.42}
}

const AFINIDAD_MINIMA: float = 0.35

# ------------------------------------------------------------------
# Atributos Top Eleven (15 habilidades en 3 bloques)
# ------------------------------------------------------------------

const BLOQUES_ATRIBUTOS: Dictionary = {
	"defensa": ["entradas", "marcaje", "posicion", "cabeceo", "valentia"],
	"ataque": ["pase", "regate", "centros", "disparo", "definicion"],
	"fisico_mental": ["condicion", "fuerza", "agresividad", "velocidad", "creatividad"]
}

const NOMBRES_ATRIBUTOS: Dictionary = {
	"entradas": "Entradas",
	"marcaje": "Marcaje",
	"posicion": "Colocación",
	"cabeceo": "Cabeceo",
	"valentia": "Valentía",
	"pase": "Pase",
	"regate": "Regate",
	"centros": "Centros",
	"disparo": "Disparo",
	"definicion": "Definición",
	"condicion": "Condición",
	"fuerza": "Fuerza",
	"agresividad": "Agresividad",
	"velocidad": "Velocidad",
	"creatividad": "Creatividad"
}

const ATRIBUTOS: Array = [
	"entradas", "marcaje", "posicion", "cabeceo", "valentia",
	"pase", "regate", "centros", "disparo", "definicion",
	"condicion", "fuerza", "agresividad", "velocidad", "creatividad"
]

const ATRIBUTO_MINIMO: int = 1
const ATRIBUTO_MAXIMO: int = 99

# Bonus de generación por rol. Los valores se suman a la base de la división.
const BONUS_ROL: Dictionary = {
	"POR": {
		"posicion": 18, "valentia": 14, "cabeceo": 6, "condicion": 6, "fuerza": 8,
		"entradas": -8, "marcaje": -6, "pase": -10, "regate": -14, "centros": -12,
		"disparo": -20, "definicion": -20, "velocidad": -4, "creatividad": -6, "agresividad": 2
	},
	"DFC": {
		"entradas": 14, "marcaje": 15, "posicion": 12, "cabeceo": 13, "valentia": 9,
		"pase": -2, "regate": -8, "centros": -6, "disparo": -10, "definicion": -12,
		"condicion": 6, "fuerza": 12, "agresividad": 8, "velocidad": -2, "creatividad": -4
	},
	"LD": {
		"entradas": 8, "marcaje": 8, "posicion": 6, "cabeceo": 2, "valentia": 4,
		"pase": 4, "regate": 4, "centros": 12, "disparo": -6, "definicion": -8,
		"condicion": 8, "fuerza": 2, "agresividad": 2, "velocidad": 10, "creatividad": 2
	},
	"LI": {
		"entradas": 8, "marcaje": 8, "posicion": 6, "cabeceo": 2, "valentia": 4,
		"pase": 4, "regate": 4, "centros": 12, "disparo": -6, "definicion": -8,
		"condicion": 8, "fuerza": 2, "agresividad": 2, "velocidad": 10, "creatividad": 2
	},
	"MCD": {
		"entradas": 11, "marcaje": 11, "posicion": 8, "cabeceo": 5, "valentia": 7,
		"pase": 6, "regate": -4, "centros": -2, "disparo": -6, "definicion": -8,
		"condicion": 10, "fuerza": 8, "agresividad": 7, "velocidad": 2, "creatividad": 2
	},
	"MC": {
		"entradas": 4, "marcaje": 3, "posicion": 4, "cabeceo": -2, "valentia": 2,
		"pase": 13, "regate": 8, "centros": 6, "disparo": 2, "definicion": 0,
		"condicion": 10, "fuerza": 2, "agresividad": 0, "velocidad": 4, "creatividad": 11
	},
	"MD": {
		"entradas": 2, "marcaje": 2, "posicion": 2, "cabeceo": -2, "valentia": 2,
		"pase": 8, "regate": 9, "centros": 12, "disparo": 3, "definicion": 1,
		"condicion": 8, "fuerza": 0, "agresividad": 0, "velocidad": 11, "creatividad": 7
	},
	"MI": {
		"entradas": 2, "marcaje": 2, "posicion": 2, "cabeceo": -2, "valentia": 2,
		"pase": 8, "regate": 9, "centros": 12, "disparo": 3, "definicion": 1,
		"condicion": 8, "fuerza": 0, "agresividad": 0, "velocidad": 11, "creatividad": 7
	},
	"MCO": {
		"entradas": -6, "marcaje": -6, "posicion": 0, "cabeceo": 0, "valentia": 0,
		"pase": 14, "regate": 10, "centros": 6, "disparo": 8, "definicion": 7,
		"condicion": 6, "fuerza": -2, "agresividad": -2, "velocidad": 6, "creatividad": 15
	},
	"ED": {
		"entradas": -8, "marcaje": -8, "posicion": -2, "cabeceo": -2, "valentia": 0,
		"pase": 8, "regate": 13, "centros": 10, "disparo": 9, "definicion": 8,
		"condicion": 7, "fuerza": -3, "agresividad": 0, "velocidad": 13, "creatividad": 9
	},
	"EI": {
		"entradas": -8, "marcaje": -8, "posicion": -2, "cabeceo": -2, "valentia": 0,
		"pase": 8, "regate": 13, "centros": 10, "disparo": 9, "definicion": 8,
		"condicion": 7, "fuerza": -3, "agresividad": 0, "velocidad": 13, "creatividad": 9
	},
	"DEL": {
		"entradas": -10, "marcaje": -10, "posicion": 2, "cabeceo": 12, "valentia": 2,
		"pase": 2, "regate": 7, "centros": -2, "disparo": 15, "definicion": 15,
		"condicion": 8, "fuerza": 4, "agresividad": 4, "velocidad": 9, "creatividad": 4
	}
}

# ------------------------------------------------------------------
# Nombres
# ------------------------------------------------------------------

const NOMBRES_FEMENINOS: Array = [
	"Lucía", "Marta", "Elena", "Nerea", "Irene", "Laura", "Carmen"
]

const NOMBRES: Array = [
	"Carlos", "Javier", "Miguel", "Alejandro", "Daniel", "Pablo", "Sergio", "Adrián",
	"Álvaro", "Diego", "Rubén", "Iván", "Marcos", "Hugo", "Mateo", "Lucía", "Marta",
	"Elena", "Nerea", "Irene", "Laura", "Carmen", "Raúl", "Fernando", "Jorge", "Andrés",
	"Víctor", "Roberto", "Gonzalo", "Nacho", "Aitor", "Unai", "Xabi", "Borja", "Óscar",
	"Samuel", "Tomás", "Guillem", "Arnau", "Pau", "Bruno", "Enzo", "Lucas", "Martín",
	"Emilio", "Joaquín", "Ramón", "Salvador", "Vicente", "Esteban"
]

const APELLIDOS: Array = [
	"Benítez", "García", "Martínez", "López", "Sánchez", "Pérez", "Gómez", "Fernández",
	"Ruiz", "Díaz", "Moreno", "Álvarez", "Muñoz", "Romero", "Alonso", "Gutiérrez",
	"Navarro", "Torres", "Domínguez", "Vázquez", "Ramos", "Gil", "Ramírez", "Serrano",
	"Blanco", "Molina", "Morales", "Suárez", "Ortega", "Delgado", "Castro", "Ortiz",
	"Rubio", "Marín", "Sanz", "Iglesias", "Medina", "Garrido", "Cortés", "Castillo",
	"Lozano", "Guerrero", "Cano", "Prieto", "Méndez", "Cruz", "Calvo", "Gallego",
	"Vidal", "León", "Márquez", "Herrera", "Peña", "Flores", "Cabrera", "Campos",
	"Vega", "Fuentes", "Carrasco", "Diez", "Reyes", "Nieto", "Aguilar", "Pascual"
]

# 15 clubes IA (3ª Regional se completa con el club del usuario).
const CLUBES_IA: Array = [
	{
		"nombre": "Real Unión", "ciudad": "Puerto Norte",
		"colores": ["#1e3a8a", "#f8fafc"], "patron": 1
	},
	{
		"nombre": "Atlético Aurora", "ciudad": "Valdeoro",
		"colores": ["#dc2626", "#fef3c7"], "patron": 0
	},
	{
		"nombre": "Deportivo Levante", "ciudad": "Costa Azul",
		"colores": ["#0e7490", "#ecfeff"], "patron": 2
	},
	{
		"nombre": "Sporting Norte", "ciudad": "Roca Fría",
		"colores": ["#166534", "#f0fdf4"], "patron": 1
	},
	{
		"nombre": "Unión Metropolitana", "ciudad": "Gran Capital",
		"colores": ["#7c3aed", "#f5f3ff"], "patron": 0
	},
	{
		"nombre": "Real Alcázar", "ciudad": "Alcázar Viejo",
		"colores": ["#b45309", "#fffbeb"], "patron": 2
	},
	{
		"nombre": "CF Sierra Alta", "ciudad": "Sierra Alta",
		"colores": ["#0369a1", "#ffffff"], "patron": 1
	},
	{
		"nombre": "Deportivo Bahía", "ciudad": "Bahía Sur",
		"colores": ["#0891b2", "#fefce8"], "patron": 0
	},
	{
		"nombre": "Club Marino", "ciudad": "Puerto Chico",
		"colores": ["#1d4ed8", "#bfdbfe"], "patron": 2
	},
	{
		"nombre": "Atlético Volcán", "ciudad": "Villa Volcán",
		"colores": ["#c2410c", "#1c1917"], "patron": 1
	},
	{
		"nombre": "Real Olivo", "ciudad": "Campo Verde",
		"colores": ["#4d7c0f", "#fefce8"], "patron": 0
	},
	{
		"nombre": "CF Río Bravo", "ciudad": "Río Bravo",
		"colores": ["#9f1239", "#fff1f2"], "patron": 2
	},
	{
		"nombre": "Sporting Estepa", "ciudad": "Estepa del Sur",
		"colores": ["#a16207", "#fef9c3"], "patron": 1
	},
	{
		"nombre": "Unión Costera", "ciudad": "Costa Serena",
		"colores": ["#0f766e", "#ccfbf1"], "patron": 0
	},
	{
		"nombre": "Club Deportivo Alameda", "ciudad": "Alameda",
		"colores": ["#4338ca", "#e0e7ff"], "patron": 1
	}
]

# Paleta sugerida para el club del usuario.
const PALETA_COLORES: Array = [
	"#d62828", "#1d4ed8", "#0f766e", "#15803d", "#b45309",
	"#7c3aed", "#0e7490", "#be123c", "#334155", "#ca8a04",
	"#ffffff", "#111827"
]

const NOMBRE_CLUB_POR_DEFECTO: String = "Club del Sim"
const CIUDAD_CLUB_POR_DEFECTO: String = "Ciudad del Sim"
const COLORES_POR_DEFECTO: Array = ["#d62828", "#ffffff"]
const PATRON_POR_DEFECTO: int = 1
const PATRONES_ESCUDO: Array = ["Liso", "Franjas", "Diagonal", "Mitades", "Cruz"]

const NOMBRES_CLUB_SUGERIDOS: Array = [
	"Atlético Horizonte", "Racing del Sol", "Sporting Mirador", "Club Atlético Brisa",
	"Unión Deportiva Valle", "Real Estrella", "CD Nueva Era", "CF Villa Verde"
]

const CIUDADES_SUGERIDAS: Array = [
	"Ciudad del Sim", "Puerto Sol", "Valle Verde", "Villa Nueva",
	"Monte Claro", "Bahía Dorada", "Río Claro", "Costa Brava"
]

const INSTALACIONES_NIVEL_MAX: int = 5
const INSTALACIONES_BASE: Dictionary = {
	"estadio": 1,
	"entrenamiento": 1,
	"cantera": 1
}
const INSTALACIONES_COSTES: Dictionary = {
	1: 8000,
	2: 22000,
	3: 60000,
	4: 150000
}
const INSTALACIONES_NOMBRES: Dictionary = {
	"estadio": "Estadio",
	"entrenamiento": "Ciudad Deportiva",
	"cantera": "Academia de Cantera"
}
const INSTALACIONES_DESCRIPCIONES: Dictionary = {
	"estadio": "Aumenta la taquilla local (+20% por nivel) y atrae más afición tras cada victoria.",
	"entrenamiento": "Acelera la recuperación de energía (+15% por nivel) y mejora las opciones de +2 al entrenar.",
	"cantera": "Eleva el nivel de las jóvenes promesas al ojear la cantera."
}
const COSTE_OJEAR_CANTERA: Dictionary = {
	1: 18000,
	2: 9000,
	3: 4500,
	4: 1800
}

# ------------------------------------------------------------------
# Economía
# ------------------------------------------------------------------

const BASE_ATRIBUTOS_DIVISION: Dictionary = {
	1: 78.0,
	2: 64.0,
	3: 50.0,
	4: 40.0
}

const PRESUPUESTO_INICIAL_IA: Dictionary = {
	1: 1200000,
	2: 450000,
	3: 150000,
	4: 60000
}

const PRESUPUESTO_INICIAL_USUARIO: int = 30000
const AFICION_POR_DIVISION: Dictionary = {1: 25000, 2: 14000, 3: 6000, 4: 1500}
const PRECIO_ENTRADA: Dictionary = {1: 20, 2: 12, 3: 6, 4: 3}
const INGRESOS_VICTORIA: Dictionary = {1: 45000, 2: 18000, 3: 5000, 4: 800}
const PREMIO_TITULO: Dictionary = {1: 300000, 2: 120000, 3: 35000, 4: 8000}
const PREMIO_ASCENSO: Dictionary = {1: 120000, 2: 45000, 3: 15000, 4: 5000}
const SALARIO_MANAGER_JORNADA: Dictionary = {1: 2000, 2: 900, 3: 250, 4: 80}
const PRIMA_MANAGER_TITULO: Dictionary = {1: 5000, 2: 2000, 3: 600, 4: 150}

const COSTE_DESBLOQUEO_TITULO: int = 1500
const REPUTACION_INICIAL: int = 25

# ------------------------------------------------------------------
# Utilidades de nombres
# ------------------------------------------------------------------

static func Nombre_Division(division: int) -> String:
	return str(DIVISIONES.get(clampi(division, 1, 4), "División"))


static func Nombre_Dia(dia_semana: int) -> String:
	var dias: Array = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]
	return str(dias[clampi(dia_semana, 0, 6)])


static func Formatear_Hora(minutos: int) -> String:
	var h: int = clampi(minutos, 0, 1439) / 60
	var m: int = clampi(minutos, 0, 1439) % 60
	return "%02d:%02d" % [h, m]


static func Generar_Nombre(rng: RandomNumberGenerator, usado: Dictionary = {}) -> String:
	var intentos: int = 0
	while intentos < 40:
		var nombre: String = "%s %s" % [
			str(NOMBRES[rng.randi_range(0, NOMBRES.size() - 1)]),
			str(APELLIDOS[rng.randi_range(0, APELLIDOS.size() - 1)])
		]
		if not usado.has(nombre):
			return nombre
		intentos += 1
	# Fallback determinista si la combinación está agotada.
	return "%s %s %d" % [
		str(NOMBRES[rng.randi_range(0, NOMBRES.size() - 1)]),
		str(APELLIDOS[rng.randi_range(0, APELLIDOS.size() - 1)]),
		rng.randi_range(2, 99)
	]


static func Atributos_Planos(datos_atributos) -> Dictionary:
	var planos: Dictionary = {}
	for bloque in BLOQUES_ATRIBUTOS.keys():
		var valores = datos_atributos.get(bloque, {}) if datos_atributos is Dictionary else {}
		if not (valores is Dictionary):
			valores = {}
		for atributo in BLOQUES_ATRIBUTOS[bloque]:
			var valor = valores.get(atributo, 50)
			if typeof(valor) != TYPE_INT and typeof(valor) != TYPE_FLOAT:
				valor = 50
			planos[atributo] = clampf(float(valor), float(ATRIBUTO_MINIMO), float(ATRIBUTO_MAXIMO))
	return planos


static func Construir_Atributos(valores_planos: Dictionary) -> Dictionary:
	var resultado: Dictionary = {"defensa": {}, "ataque": {}, "fisico_mental": {}}
	for bloque in BLOQUES_ATRIBUTOS.keys():
		for atributo in BLOQUES_ATRIBUTOS[bloque]:
			resultado[bloque][atributo] = int(round(clampf(
				float(valores_planos.get(atributo, 50)),
				float(ATRIBUTO_MINIMO), float(ATRIBUTO_MAXIMO))))
	return resultado


static func Linea_De_Rol(rol: String) -> String:
	if ROLES_PORTEROS.has(rol):
		return "POR"
	if ROLES_DEFENSA.has(rol):
		return "DEF"
	if ROLES_MEDIO.has(rol):
		return "MED"
	return "ATA"


static func Color_De_Rol(rol: String) -> Color:
	return Color(str(COLORES_LINEA.get(Linea_De_Rol(rol), "#0d9488")))


static func Es_Nombre_Femenino(nombre_completo: String) -> bool:
	var primer: String = nombre_completo.strip_edges().split(" ", false)[0] if nombre_completo.strip_edges() != "" else ""
	return NOMBRES_FEMENINOS.has(primer)
