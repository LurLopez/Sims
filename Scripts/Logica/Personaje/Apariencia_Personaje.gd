class_name Apariencia_Personaje
extends RefCounted
## Modelo de datos, paletas y arquetipos para la personalización estilo Los Sims.
## Serializado en Variables_Estaticas.Apariencia y consumido por Personaje_Visual
## en el creador, el menú de inicio, el cómic introductorio y Escenario_Actividad.

const GENEROS: Array[Dictionary] = [
	{"id": "hombre", "nombre": "Hombre"},
	{"id": "mujer", "nombre": "Mujer"},
]

const PERSONALIDADES: Array[Dictionary] = [
	{"id": "", "nombre": "Sorpresa", "desc": "Se asignará un rasgo al azar al empezar"},
	{"id": "Trabajador_Compulsivo", "nombre": "Aplicado", "desc": "Prefiere estudiar y centrarse en sus metas"},
	{"id": "Deportista", "nombre": "Deportista", "desc": "Enérgico, activo y amante del deporte"},
	{"id": "Culo_Del_Sofa", "nombre": "Hogareño", "desc": "Disfruta relajándose en casa y viendo la tele"},
]

const COMPLEXIONES: Array[Dictionary] = [
	{"id": "delgado", "nombre": "Delgado"},
	{"id": "normal", "nombre": "Normal"},
	{"id": "atletico", "nombre": "Atlético"},
	{"id": "robusto", "nombre": "Robusto"},
]

const COLORES_PIEL: Array[Dictionary] = [
	{"id": "porcelana", "nombre": "Porcelana", "hex": "#fde4d4"},
	{"id": "marfil", "nombre": "Marfil", "hex": "#fbe0c4"},
	{"id": "claro", "nombre": "Claro", "hex": "#f8cfb4"},
	{"id": "melocoton", "nombre": "Melocotón", "hex": "#f1bb95"},
	{"id": "oliva", "nombre": "Oliva", "hex": "#dfb284"},
	{"id": "dorado", "nombre": "Dorado", "hex": "#e1a274"},
	{"id": "canela", "nombre": "Canela", "hex": "#c68255"},
	{"id": "tostado", "nombre": "Tostado", "hex": "#b06d44"},
	{"id": "bronce", "nombre": "Bronce", "hex": "#9e613c"},
	{"id": "cacao", "nombre": "Cacao", "hex": "#754428"},
	{"id": "cafe", "nombre": "Café", "hex": "#5a321d"},
	{"id": "ebano", "nombre": "Ébano", "hex": "#432415"},
]

const FORMAS_CARA: Array[Dictionary] = [
	{"id": "ovalada", "nombre": "Ovalada"},
	{"id": "cuadrada", "nombre": "Cuadrada"},
	{"id": "redonda", "nombre": "Redonda"},
	{"id": "alargada", "nombre": "Alargada"},
	{"id": "corazon", "nombre": "Corazón"},
]

const FORMAS_OJOS: Array[Dictionary] = [
	{"id": "almendrados", "nombre": "Almendrados"},
	{"id": "grandes", "nombre": "Grandes"},
	{"id": "rasgados", "nombre": "Rasgados"},
	{"id": "caidos", "nombre": "Suaves"},
]

const COLORES_OJOS: Array[Dictionary] = [
	{"id": "castano", "nombre": "Castaño", "hex": "#6b4226"},
	{"id": "oscuro", "nombre": "Oscuro", "hex": "#251c17"},
	{"id": "ambar", "nombre": "Ámbar", "hex": "#c47d1a"},
	{"id": "avellana", "nombre": "Avellana", "hex": "#7c8532"},
	{"id": "verde", "nombre": "Esmeralda", "hex": "#168049"},
	{"id": "oliva", "nombre": "Oliva", "hex": "#4d7c0f"},
	{"id": "azul", "nombre": "Zafiro", "hex": "#2563eb"},
	{"id": "celeste", "nombre": "Celeste", "hex": "#0ea5e9"},
	{"id": "gris", "nombre": "Gris", "hex": "#64748b"},
	{"id": "violeta", "nombre": "Violeta", "hex": "#7c3aed"},
]

const ESTILOS_CEJAS: Array[Dictionary] = [
	{"id": "naturales", "nombre": "Naturales"},
	{"id": "arqueadas", "nombre": "Arqueadas"},
	{"id": "gruesas", "nombre": "Gruesas"},
	{"id": "finas", "nombre": "Finas"},
	{"id": "rectas", "nombre": "Rectas"},
]

const FORMAS_NARIZ: Array[Dictionary] = [
	{"id": "normal", "nombre": "Equilibrada"},
	{"id": "respingona", "nombre": "Respingona"},
	{"id": "recta", "nombre": "Recta"},
	{"id": "ancha", "nombre": "Ancha"},
	{"id": "fina", "nombre": "Fina"},
]

const FORMAS_BOCA: Array[Dictionary] = [
	{"id": "normal", "nombre": "Natural"},
	{"id": "amplia", "nombre": "Amplia"},
	{"id": "gruesa", "nombre": "Gruesa"},
	{"id": "fina", "nombre": "Fina"},
]

const COLORES_LABIOS: Array[Dictionary] = [
	{"id": "natural", "nombre": "Natural", "hex": ""},
	{"id": "nude", "nombre": "Nude", "hex": "#d49a89"},
	{"id": "rosa", "nombre": "Rosa", "hex": "#e87996"},
	{"id": "coral", "nombre": "Coral", "hex": "#ea6b5e"},
	{"id": "rojo", "nombre": "Rojo", "hex": "#c81e32"},
	{"id": "vino", "nombre": "Vino", "hex": "#7f1d3a"},
]

const ESTILOS_LUNAR: Array[Dictionary] = [
	{"id": "ninguno", "nombre": "Ninguno"},
	{"id": "mejilla", "nombre": "Mejilla"},
	{"id": "labio", "nombre": "Junto al labio"},
	{"id": "ceja", "nombre": "En ceja"},
]

const NIVELES_RUBOR: Array[Dictionary] = [
	{"id": "ninguno", "nombre": "Sin rubor"},
	{"id": "suave", "nombre": "Suave"},
	{"id": "intenso", "nombre": "Intenso"},
]

const COLORES_PELO: Array[Dictionary] = [
	{"id": "negro", "nombre": "Negro", "hex": "#1e1b18"},
	{"id": "castano_oscuro", "nombre": "Castaño osc.", "hex": "#432818"},
	{"id": "castano", "nombre": "Castaño", "hex": "#7c4728"},
	{"id": "castano_claro", "nombre": "Avellana", "hex": "#9c6334"},
	{"id": "rubio", "nombre": "Rubio", "hex": "#eab308"},
	{"id": "platino", "nombre": "Platino", "hex": "#ead9b0"},
	{"id": "pelirrojo", "nombre": "Pelirrojo", "hex": "#c2410c"},
	{"id": "caoba", "nombre": "Caoba", "hex": "#7f1d1d"},
	{"id": "gris", "nombre": "Plata", "hex": "#94a3b8"},
	{"id": "blanco", "nombre": "Blanco", "hex": "#e2e8f0"},
	{"id": "azul", "nombre": "Azul", "hex": "#2563eb"},
	{"id": "rosa", "nombre": "Rosa", "hex": "#db2777"},
	{"id": "morado", "nombre": "Morado", "hex": "#7c3aed"},
	{"id": "turquesa", "nombre": "Turquesa", "hex": "#0d9488"},
]

const ESTILOS_PELO: Array[Dictionary] = [
	{"id": "alborotado", "nombre": "Alborotado", "sugerido": "hombre"},
	{"id": "tupe", "nombre": "Tupé", "sugerido": "hombre"},
	{"id": "corto", "nombre": "Corto", "sugerido": "hombre"},
	{"id": "degradado", "nombre": "Degradado", "sugerido": "hombre"},
	{"id": "raya_lado", "nombre": "Raya al lado", "sugerido": "ambos"},
	{"id": "rizado", "nombre": "Rizado", "sugerido": "ambos"},
	{"id": "afro", "nombre": "Afro", "sugerido": "ambos"},
	{"id": "rapado", "nombre": "Rapado", "sugerido": "hombre"},
	{"id": "calvo", "nombre": "Calvo", "sugerido": "hombre"},
	{"id": "largo", "nombre": "Largo", "sugerido": "mujer"},
	{"id": "ondulado", "nombre": "Ondulado", "sugerido": "mujer"},
	{"id": "media_melena", "nombre": "Melena", "sugerido": "mujer"},
	{"id": "bob", "nombre": "Bob flequillo", "sugerido": "mujer"},
	{"id": "coleta", "nombre": "Coleta", "sugerido": "mujer"},
	{"id": "dos_coletas", "nombre": "Dos coletas", "sugerido": "mujer"},
	{"id": "mono", "nombre": "Moño alto", "sugerido": "mujer"},
]

const ESTILOS_VELLO: Array[Dictionary] = [
	{"id": "ninguno", "nombre": "Ninguno"},
	{"id": "sombra", "nombre": "Barba 3 días"},
	{"id": "barba_corta", "nombre": "Barba corta"},
	{"id": "barba_completa", "nombre": "Barba larga"},
	{"id": "bigote", "nombre": "Bigote"},
	{"id": "perilla", "nombre": "Perilla"},
	{"id": "candado", "nombre": "Candado"},
]

const ROPA_SUPERIOR: Array[Dictionary] = [
	{"id": "sudadera", "nombre": "Sudadera"},
	{"id": "camiseta", "nombre": "Camiseta"},
	{"id": "camisa", "nombre": "Camisa"},
	{"id": "chaqueta", "nombre": "Chaqueta"},
	{"id": "jersey", "nombre": "Jersey"},
	{"id": "top", "nombre": "Sin mangas"},
]

## Estilos de atuendo que sabe dibujar Personaje_Visual.
## "base" usa la ropa superior/inferior elegida en el creador de personaje.
const ESTILOS_ROPA: Array[String] = [
	"base",
	"delantal",
	"chef",
	"gala",
	"michelin",
	"casual",
	"deportivo",
	"verano",
	"invierno",
	"traje",
	"bata",
	"mono",
	"camarero",
	"pijama",
	"fiesta",
	"futbol",
	"cuero",
	"astronauta",
	"vestido",
]

const COLORES_ROPA: Array[Dictionary] = [
	{"id": "azul", "nombre": "Azul", "hex": "#2563eb"},
	{"id": "rojo", "nombre": "Rojo", "hex": "#dc2626"},
	{"id": "verde", "nombre": "Verde", "hex": "#16a34a"},
	{"id": "morado", "nombre": "Morado", "hex": "#7c3aed"},
	{"id": "amarillo", "nombre": "Mostaza", "hex": "#d97706"},
	{"id": "rosa", "nombre": "Rosa", "hex": "#e11d48"},
	{"id": "turquesa", "nombre": "Turquesa", "hex": "#0d9488"},
	{"id": "negro", "nombre": "Grafito", "hex": "#334155"},
	{"id": "blanco", "nombre": "Blanco", "hex": "#f8fafc"},
	{"id": "beige", "nombre": "Arena", "hex": "#d6c3a5"},
	{"id": "naranja", "nombre": "Naranja", "hex": "#ea580c"},
	{"id": "celeste", "nombre": "Celeste", "hex": "#0284c7"},
]

const ROPA_INFERIOR: Array[Dictionary] = [
	{"id": "vaqueros", "nombre": "Vaqueros"},
	{"id": "chino", "nombre": "Chino"},
	{"id": "chandal", "nombre": "Chándal"},
	{"id": "shorts", "nombre": "Shorts"},
	{"id": "falda", "nombre": "Falda"},
]

const COLORES_PANTALON: Array[Dictionary] = [
	{"id": "vaquero", "nombre": "Vaquero", "hex": "#3b6ea5"},
	{"id": "indigo", "nombre": "Índigo", "hex": "#1e3a5f"},
	{"id": "negro", "nombre": "Negro", "hex": "#1e293b"},
	{"id": "gris", "nombre": "Gris", "hex": "#64748b"},
	{"id": "caqui", "nombre": "Caqui", "hex": "#b59a74"},
	{"id": "granate", "nombre": "Granate", "hex": "#7f1d1d"},
	{"id": "oliva", "nombre": "Oliva", "hex": "#3f6212"},
	{"id": "blanco", "nombre": "Blanco", "hex": "#e2e8f0"},
]

const ESTILOS_CALZADO: Array[Dictionary] = [
	{"id": "zapatillas", "nombre": "Deportivas"},
	{"id": "botas", "nombre": "Botas"},
	{"id": "zapatos", "nombre": "Zapatos"},
]

const COLORES_CALZADO: Array[Dictionary] = [
	{"id": "azul", "nombre": "Azul", "hex": "#2563eb"},
	{"id": "blanco", "nombre": "Blanco", "hex": "#f1f5f9"},
	{"id": "negro", "nombre": "Negro", "hex": "#1e293b"},
	{"id": "marron", "nombre": "Marrón", "hex": "#78350f"},
	{"id": "rojo", "nombre": "Rojo", "hex": "#dc2626"},
	{"id": "mostaza", "nombre": "Mostaza", "hex": "#d97706"},
]

const ESTILOS_GAFAS: Array[Dictionary] = [
	{"id": "ninguna", "nombre": "Sin gafas"},
	{"id": "redondas", "nombre": "Redondas"},
	{"id": "cuadradas", "nombre": "Cuadradas"},
	{"id": "aviador", "nombre": "Aviador"},
	{"id": "cateye", "nombre": "Cat-eye"},
	{"id": "sol", "nombre": "De sol"},
]

const ESTILOS_SOMBRERO: Array[Dictionary] = [
	{"id": "ninguno", "nombre": "Ninguno"},
	{"id": "gorra", "nombre": "Gorra"},
	{"id": "gorro", "nombre": "Gorro lana"},
	{"id": "boina", "nombre": "Boina"},
	{"id": "diadema", "nombre": "Diadema"},
]

const ESTILOS_PENDIENTES: Array[Dictionary] = [
	{"id": "ninguno", "nombre": "Ninguno"},
	{"id": "aros", "nombre": "Aros"},
	{"id": "perlas", "nombre": "Perlas"},
	{"id": "cruz", "nombre": "Colgantes"},
]

const ARQUETIPOS: Array[Dictionary] = [
	{
		"id": "urbano",
		"nombre": "Urbano",
		"hombre": {
			"estilo_pelo": "alborotado", "ropa_superior": "sudadera", "color_ropa": "#2563eb",
			"ropa_inferior": "vaqueros", "color_pantalon": "#3b6ea5", "calzado": "zapatillas",
			"color_calzado": "#2563eb", "sombrero": "ninguno", "gafas": "ninguna",
		},
		"mujer": {
			"estilo_pelo": "coleta", "ropa_superior": "sudadera", "color_ropa": "#e11d48",
			"ropa_inferior": "vaqueros", "color_pantalon": "#1e3a5f", "calzado": "zapatillas",
			"color_calzado": "#f1f5f9", "sombrero": "ninguno", "gafas": "ninguna",
		},
	},
	{
		"id": "ejecutivo",
		"nombre": "Elegante",
		"hombre": {
			"estilo_pelo": "raya_lado", "ropa_superior": "camisa", "color_ropa": "#f8fafc",
			"ropa_inferior": "chino", "color_pantalon": "#1e293b", "calzado": "zapatos",
			"color_calzado": "#78350f", "gafas": "cuadradas", "sombrero": "ninguno",
		},
		"mujer": {
			"estilo_pelo": "mono", "ropa_superior": "camisa", "color_ropa": "#f8fafc",
			"ropa_inferior": "falda", "color_pantalon": "#1e293b", "calzado": "zapatos",
			"color_calzado": "#1e293b", "pendientes": "perlas", "color_labios": "rojo",
		},
	},
	{
		"id": "deportista",
		"nombre": "Atleta",
		"hombre": {
			"estilo_pelo": "degradado", "complexion": "atletico", "ropa_superior": "camiseta",
			"color_ropa": "#16a34a", "ropa_inferior": "shorts", "color_pantalon": "#1e293b",
			"calzado": "zapatillas", "color_calzado": "#dc2626", "sombrero": "gorra",
		},
		"mujer": {
			"estilo_pelo": "coleta", "complexion": "atletico", "ropa_superior": "top",
			"color_ropa": "#0d9488", "ropa_inferior": "chandal", "color_pantalon": "#1e293b",
			"calzado": "zapatillas", "color_calzado": "#f1f5f9", "sombrero": "diadema",
		},
	},
	{
		"id": "alternativo",
		"nombre": "Alternativo",
		"hombre": {
			"estilo_pelo": "tupe", "ropa_superior": "chaqueta", "color_ropa": "#334155",
			"ropa_inferior": "vaqueros", "color_pantalon": "#1e293b", "calzado": "botas",
			"color_calzado": "#1e293b", "sombrero": "gorro", "gafas": "redondas",
		},
		"mujer": {
			"estilo_pelo": "bob", "ropa_superior": "chaqueta", "color_ropa": "#7c3aed",
			"ropa_inferior": "falda", "color_pantalon": "#1e293b", "calzado": "botas",
			"color_calzado": "#1e293b", "pendientes": "aros", "color_labios": "vino",
		},
	},
	{
		"id": "acogedor",
		"nombre": "Acogedor",
		"hombre": {
			"estilo_pelo": "corto", "ropa_superior": "jersey", "color_ropa": "#d97706",
			"ropa_inferior": "chino", "color_pantalon": "#b59a74", "calzado": "zapatos",
			"color_calzado": "#78350f", "gafas": "redondas", "sombrero": "ninguno",
		},
		"mujer": {
			"estilo_pelo": "ondulado", "ropa_superior": "jersey", "color_ropa": "#d6c3a5",
			"ropa_inferior": "vaqueros", "color_pantalon": "#3b6ea5", "calzado": "botas",
			"color_calzado": "#78350f", "sombrero": "boina", "gafas": "cateye",
		},
	},
]

const NOMBRES_HOMBRE: Array[String] = [
	"Alex", "Lucas", "Mateo", "Hugo", "Daniel", "Leo", "Pablo",
	"Adrián", "Diego", "Marcos", "Iván", "Nicolás", "Javier", "Bruno",
]

const NOMBRES_MUJER: Array[String] = [
	"Lucía", "Sofía", "Martina", "Paula", "Valeria", "Julia", "Alba",
	"Elena", "Noa", "Clara", "Carmen", "Laura", "Nora", "Sara",
]

const POSE_POR_ACTIVIDAD: Dictionary = {
	"": "idle",
	"Salir_A_Correr": "correr",
	"Carrera_Deportiva": "correr",
	"Entrenar_Futbol": "futbol",
	"Entrenamiento_Futbol": "futbol",
	"Partido_Futbol": "futbol",
	"Dormir": "dormir",
	"Comer": "comer",
	"Comer_Tupper": "comer",
	"Comer_Basura": "comer",
	"Cocinar": "cocinar",
	"Duchar": "duchar",
	"Estudiar": "estudiar",
	"Estudiar_Carrera": "estudiar",
	"Examen_Carrera": "estudiar",
	"Ver_La_Television": "tv",
	"Practicar_Manualidades": "manualidades",
	"Salir_De_Fiesta": "fiesta",
}


static func por_defecto() -> Dictionary:
	return {
		"nombre": "",
		"genero": "hombre",
		"personalidad": "",
		"complexion": "normal",
		"color_piel": "#f8cfb4",
		"forma_cara": "ovalada",
		"forma_ojos": "almendrados",
		"color_ojos": "#6b4226",
		"estilo_cejas": "naturales",
		"forma_nariz": "normal",
		"forma_boca": "normal",
		"color_labios": "natural",
		"color_pelo": "#7c4728",
		"estilo_pelo": "alborotado",
		"vello_facial": "ninguno",
		"pecas": false,
		"lunar": "ninguno",
		"rubor": "suave",
		"delineado": false,
		"ropa_superior": "sudadera",
		"color_ropa": "#2563eb",
		"color_ropa_secundario": "#f8fafc",
		"color_ropa_detalle": "#f8fafc",
		"ropa_inferior": "vaqueros",
		"color_pantalon": "#3b6ea5",
		"calzado": "zapatillas",
		"color_calzado": "#2563eb",
		"estilo_ropa": "base",
		"detalle_ropa": "",
		"gafas": "ninguna",
		"sombrero": "ninguno",
		"pendientes": "ninguno",
	}


static func normalizar(datos: Variant) -> Dictionary:
	var base := por_defecto()
	if not (datos is Dictionary):
		return base
	var d: Dictionary = datos

	var genero := str(d.get("genero", base["genero"]))
	if genero != "hombre" and genero != "mujer":
		genero = "hombre"
	base["genero"] = genero

	base["nombre"] = str(d.get("nombre", "")).strip_edges().left(20)

	var pers := str(d.get("personalidad", ""))
	if not _existe_id(PERSONALIDADES, pers):
		pers = ""
	base["personalidad"] = pers

	base["complexion"] = _id_valido(COMPLEXIONES, d.get("complexion", base["complexion"]), base["complexion"])
	base["color_piel"] = _hex_valido(d.get("color_piel", ""), base["color_piel"])
	base["forma_cara"] = _id_valido(FORMAS_CARA, d.get("forma_cara", base["forma_cara"]), base["forma_cara"])
	base["forma_ojos"] = _id_valido(FORMAS_OJOS, d.get("forma_ojos", base["forma_ojos"]), base["forma_ojos"])
	base["color_ojos"] = _hex_valido(d.get("color_ojos", ""), base["color_ojos"])
	base["estilo_cejas"] = _id_valido(ESTILOS_CEJAS, d.get("estilo_cejas", base["estilo_cejas"]), base["estilo_cejas"])
	base["forma_nariz"] = _id_valido(FORMAS_NARIZ, d.get("forma_nariz", base["forma_nariz"]), base["forma_nariz"])
	base["forma_boca"] = _id_valido(FORMAS_BOCA, d.get("forma_boca", base["forma_boca"]), base["forma_boca"])
	base["color_labios"] = _id_valido(COLORES_LABIOS, d.get("color_labios", base["color_labios"]), base["color_labios"])
	base["color_pelo"] = _hex_valido(d.get("color_pelo", ""), base["color_pelo"])

	var pelo := str(d.get("estilo_pelo", base["estilo_pelo"]))
	if not _existe_id(ESTILOS_PELO, pelo):
		pelo = "largo" if genero == "mujer" else "alborotado"
	base["estilo_pelo"] = pelo

	var vello := str(d.get("vello_facial", base["vello_facial"]))
	if genero == "mujer" or not _existe_id(ESTILOS_VELLO, vello):
		vello = "ninguno"
	base["vello_facial"] = vello

	base["pecas"] = bool(d.get("pecas", false))
	base["lunar"] = _id_valido(ESTILOS_LUNAR, d.get("lunar", base["lunar"]), base["lunar"])
	base["rubor"] = _id_valido(NIVELES_RUBOR, d.get("rubor", base["rubor"]), base["rubor"])
	base["delineado"] = bool(d.get("delineado", genero == "mujer" and not d.has("delineado")))

	base["ropa_superior"] = _id_valido(ROPA_SUPERIOR, d.get("ropa_superior", base["ropa_superior"]), base["ropa_superior"])
	base["color_ropa"] = _hex_valido(d.get("color_ropa", ""), base["color_ropa"])
	base["color_ropa_secundario"] = _hex_valido(d.get("color_ropa_secundario", ""), base["color_ropa_secundario"])
	base["color_ropa_detalle"] = _hex_valido(d.get("color_ropa_detalle", ""), base["color_ropa_detalle"])
	base["ropa_inferior"] = _id_valido(ROPA_INFERIOR, d.get("ropa_inferior", base["ropa_inferior"]), base["ropa_inferior"])
	base["color_pantalon"] = _hex_valido(d.get("color_pantalon", ""), base["color_pantalon"])
	base["calzado"] = _id_valido(ESTILOS_CALZADO, d.get("calzado", base["calzado"]), base["calzado"])
	base["color_calzado"] = _hex_valido(d.get("color_calzado", ""), base["color_calzado"])

	var estilo_atuendo := str(d.get("estilo_ropa", base["estilo_ropa"]))
	if not ESTILOS_ROPA.has(estilo_atuendo):
		estilo_atuendo = "base"
	base["estilo_ropa"] = estilo_atuendo
	base["detalle_ropa"] = str(d.get("detalle_ropa", ""))

	base["gafas"] = _id_valido(ESTILOS_GAFAS, d.get("gafas", base["gafas"]), base["gafas"])
	base["sombrero"] = _id_valido(ESTILOS_SOMBRERO, d.get("sombrero", base["sombrero"]), base["sombrero"])
	base["pendientes"] = _id_valido(ESTILOS_PENDIENTES, d.get("pendientes", base["pendientes"]), base["pendientes"])

	return base


static func aleatoria(genero_forzado: String = "") -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var genero := genero_forzado
	if genero != "hombre" and genero != "mujer":
		genero = "mujer" if rng.randi_range(0, 1) == 1 else "hombre"

	var pelos_compatibles: Array[String] = []
	for item in ESTILOS_PELO:
		var sug: String = item["sugerido"]
		if sug == genero or sug == "ambos":
			pelos_compatibles.append(item["id"])
			pelos_compatibles.append(item["id"])
		else:
			pelos_compatibles.append(item["id"])
	var estilo_pelo: String = pelos_compatibles[rng.randi_range(0, pelos_compatibles.size() - 1)]

	var idx_pelo: int = rng.randi_range(0, 9) if rng.randf() < 0.86 else rng.randi_range(10, COLORES_PELO.size() - 1)
	var idx_piel: int = rng.randi_range(0, COLORES_PIEL.size() - 1)
	var idx_ojos: int = rng.randi_range(0, COLORES_OJOS.size() - 1)
	var idx_ropa: int = rng.randi_range(0, COLORES_ROPA.size() - 1)
	var idx_pant: int = rng.randi_range(0, COLORES_PANTALON.size() - 1)
	var idx_calz: int = rng.randi_range(0, COLORES_CALZADO.size() - 1)

	var gafas := "ninguna"
	if rng.randf() < 0.25:
		var ops_g: Array[String] = ["redondas", "cuadradas", "aviador", "cateye", "sol"]
		gafas = ops_g[rng.randi_range(0, ops_g.size() - 1)]

	var sombrero := "ninguno"
	if rng.randf() < 0.20:
		var ops_s: Array[String] = ["gorra", "gorro", "boina", "diadema"]
		sombrero = ops_s[rng.randi_range(0, ops_s.size() - 1)]

	var pendientes := "ninguno"
	if rng.randf() < (0.45 if genero == "mujer" else 0.10):
		var ops_p: Array[String] = ["aros", "perlas", "cruz"]
		pendientes = ops_p[rng.randi_range(0, ops_p.size() - 1)]

	var vello := "ninguno"
	if genero == "hombre" and rng.randf() < 0.34:
		var ops_v: Array[String] = ["sombra", "barba_corta", "barba_completa", "bigote", "perilla", "candado"]
		vello = ops_v[rng.randi_range(0, ops_v.size() - 1)]

	var ropa_inf_ops: Array[String] = ["vaqueros", "chino", "chandal", "shorts"]
	if genero == "mujer":
		ropa_inf_ops.append("falda")
		ropa_inf_ops.append("falda")

	var labios_id := "natural"
	if genero == "mujer" and rng.randf() < 0.50:
		var ops_l: Array[String] = ["nude", "rosa", "coral", "rojo", "vino"]
		labios_id = ops_l[rng.randi_range(0, ops_l.size() - 1)]

	var lunar_id := "ninguno"
	if rng.randf() < 0.16:
		var ops_lu: Array[String] = ["mejilla", "labio", "ceja"]
		lunar_id = ops_lu[rng.randi_range(0, ops_lu.size() - 1)]

	var lista_nombres: Array[String] = NOMBRES_MUJER if genero == "mujer" else NOMBRES_HOMBRE
	var nombre: String = lista_nombres[rng.randi_range(0, lista_nombres.size() - 1)]

	return normalizar({
		"nombre": nombre,
		"genero": genero,
		"personalidad": "",
		"complexion": COMPLEXIONES[rng.randi_range(0, COMPLEXIONES.size() - 1)]["id"],
		"color_piel": COLORES_PIEL[idx_piel]["hex"],
		"forma_cara": FORMAS_CARA[rng.randi_range(0, FORMAS_CARA.size() - 1)]["id"],
		"forma_ojos": FORMAS_OJOS[rng.randi_range(0, FORMAS_OJOS.size() - 1)]["id"],
		"color_ojos": COLORES_OJOS[idx_ojos]["hex"],
		"estilo_cejas": ESTILOS_CEJAS[rng.randi_range(0, ESTILOS_CEJAS.size() - 1)]["id"],
		"forma_nariz": FORMAS_NARIZ[rng.randi_range(0, FORMAS_NARIZ.size() - 1)]["id"],
		"forma_boca": FORMAS_BOCA[rng.randi_range(0, FORMAS_BOCA.size() - 1)]["id"],
		"color_labios": labios_id,
		"color_pelo": COLORES_PELO[idx_pelo]["hex"],
		"estilo_pelo": estilo_pelo,
		"vello_facial": vello,
		"pecas": rng.randf() < 0.22,
		"lunar": lunar_id,
		"rubor": "suave" if rng.randf() < 0.78 else ("intenso" if rng.randf() < 0.5 else "ninguno"),
		"delineado": (genero == "mujer" and rng.randf() < 0.75),
		"ropa_superior": ROPA_SUPERIOR[rng.randi_range(0, ROPA_SUPERIOR.size() - 1)]["id"],
		"color_ropa": COLORES_ROPA[idx_ropa]["hex"],
		"ropa_inferior": ropa_inf_ops[rng.randi_range(0, ropa_inf_ops.size() - 1)],
		"color_pantalon": COLORES_PANTALON[idx_pant]["hex"],
		"calzado": ESTILOS_CALZADO[rng.randi_range(0, ESTILOS_CALZADO.size() - 1)]["id"],
		"color_calzado": COLORES_CALZADO[idx_calz]["hex"],
		"gafas": gafas,
		"sombrero": sombrero,
		"pendientes": pendientes,
	})


static func aplicar_arquetipo(base_actual: Dictionary, id_arquetipo: String) -> Dictionary:
	var ap := normalizar(base_actual)
	var gen: String = ap["genero"]
	for arq in ARQUETIPOS:
		if arq["id"] == id_arquetipo:
			var patch: Dictionary = arq.get(gen, {})
			for k in patch.keys():
				ap[k] = patch[k]
			return normalizar(ap)
	return ap


static func color_labios_de(datos: Dictionary, piel: Color) -> Color:
	var id_lab := str(datos.get("color_labios", "natural"))
	for item in COLORES_LABIOS:
		if item["id"] == id_lab:
			var hex: String = item["hex"]
			if hex != "" and Color.html_is_valid(hex):
				return Color.html(hex)
	return piel.lerp(Color("#d96b78"), 0.34)


static func nombre_aleatorio(genero: String) -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var lista: Array[String] = NOMBRES_MUJER if genero == "mujer" else NOMBRES_HOMBRE
	return lista[rng.randi_range(0, lista.size() - 1)]


static func es_mujer(datos: Dictionary) -> bool:
	return str(datos.get("genero", "hombre")) == "mujer"


static func etiqueta_genero(datos: Dictionary) -> String:
	return "Mujer" if es_mujer(datos) else "Hombre"


static func etiqueta_personalidad(id_pers: String) -> String:
	for p in PERSONALIDADES:
		if p["id"] == id_pers:
			return str(p["nombre"])
	return id_pers.replace("_", " ").capitalize()


static func pose_para_actividad(nombre_actividad: String) -> String:
	if POSE_POR_ACTIVIDAD.has(nombre_actividad):
		return str(POSE_POR_ACTIVIDAD[nombre_actividad])
	if nombre_actividad.begins_with("Trabajar_"):
		return "trabajar"
	return "idle"


## Devuelve una copia normalizada de la apariencia con la prenda indicada
## superpuesta. Para la ropa de calle (estilo "base") se conservan las
## elecciones del creador de personaje (superior, inferior y calzado).
static func aplicar_atuendo(datos: Variant, ropa: Objeto_Ropa) -> Dictionary:
	var ap := normalizar(datos)
	if ropa == null:
		return ap

	var estilo := str(ropa.estilo_visual)
	if not ESTILOS_ROPA.has(estilo):
		estilo = "base"
	ap["estilo_ropa"] = estilo

	# Cada estilo parte de una prenda base que el renderizador ya sabe dibujar;
	# encima se añaden sus detalles característicos.
	match estilo:
		"delantal":
			ap["ropa_superior"] = "camiseta"
			ap["ropa_inferior"] = "vaqueros"
			ap["calzado"] = "zapatillas"
		"chef", "gala", "michelin":
			ap["ropa_superior"] = "chaqueta"
			ap["ropa_inferior"] = "chino"
			ap["calzado"] = "zapatos"
		"casual":
			ap["ropa_superior"] = "camiseta"
			ap["ropa_inferior"] = "vaqueros"
			ap["calzado"] = "zapatillas"
		"deportivo":
			ap["ropa_superior"] = "sudadera"
			ap["ropa_inferior"] = "chandal"
			ap["calzado"] = "zapatillas"
		"verano":
			ap["ropa_superior"] = "top"
			ap["ropa_inferior"] = "shorts"
			ap["calzado"] = "zapatillas"
		"invierno":
			ap["ropa_superior"] = "jersey"
			ap["ropa_inferior"] = "chino"
			ap["calzado"] = "botas"
		"traje", "bata", "camarero":
			ap["ropa_superior"] = "camisa"
			ap["ropa_inferior"] = "chino"
			ap["calzado"] = "zapatos"
		"mono":
			ap["ropa_superior"] = "camiseta"
			ap["ropa_inferior"] = "vaqueros"
			ap["calzado"] = "botas"
		"pijama":
			ap["ropa_superior"] = "camisa"
			ap["ropa_inferior"] = "chino"
			ap["calzado"] = "zapatillas"
		"fiesta":
			ap["ropa_superior"] = "camisa"
			ap["ropa_inferior"] = "chino"
			ap["calzado"] = "zapatos"
		"futbol":
			ap["ropa_superior"] = "camiseta"
			ap["ropa_inferior"] = "shorts"
			ap["calzado"] = "zapatillas"
		"cuero":
			ap["ropa_superior"] = "camiseta"
			ap["ropa_inferior"] = "vaqueros"
			ap["calzado"] = "botas"
		"astronauta":
			ap["ropa_superior"] = "camiseta"
			ap["ropa_inferior"] = "chino"
			ap["calzado"] = "botas"
		"vestido":
			ap["ropa_superior"] = "top"
			ap["ropa_inferior"] = "falda"
			ap["calzado"] = "zapatos"

	# La ficha de la prenda puede forzar una prenda base concreta.
	if ropa.prenda_superior != "":
		ap["ropa_superior"] = ropa.prenda_superior
	if ropa.prenda_inferior != "":
		ap["ropa_inferior"] = ropa.prenda_inferior
	if ropa.calzado != "":
		ap["calzado"] = ropa.calzado
	ap["detalle_ropa"] = str(ropa.detalle_visual)

	if ropa.color_principal != "":
		ap["color_ropa"] = _hex_valido(ropa.color_principal, ap["color_ropa"])
	if ropa.color_secundario != "":
		ap["color_ropa_secundario"] = _hex_valido(ropa.color_secundario, ap["color_ropa_secundario"])
	if ropa.color_detalle != "":
		ap["color_ropa_detalle"] = _hex_valido(ropa.color_detalle, ap["color_ropa_detalle"])
	if ropa.color_pantalon != "":
		ap["color_pantalon"] = _hex_valido(ropa.color_pantalon, ap["color_pantalon"])
	if ropa.color_zapatillas != "":
		ap["color_calzado"] = _hex_valido(ropa.color_zapatillas, ap["color_calzado"])
	return ap


## Estilo visual de la ropa actual ("base", "delantal", "chef", "gala", "michelin").
static func estilo_ropa_de(datos: Dictionary) -> String:
	return str(datos.get("estilo_ropa", "base"))


static func color_de(datos: Dictionary, clave: String, fallback: Color) -> Color:
	var raw = datos.get(clave, "")
	if raw is Color:
		return raw
	var s := str(raw)
	if s.begins_with("#") and Color.html_is_valid(s):
		return Color.html(s)
	return fallback


static func _hex_valido(valor: Variant, fallback: String) -> String:
	var s := str(valor)
	if s.begins_with("#") and Color.html_is_valid(s):
		return s
	return fallback


static func _id_valido(lista: Array[Dictionary], valor: Variant, fallback: String) -> String:
	var s := str(valor)
	return s if _existe_id(lista, s) else fallback


static func _existe_id(lista: Array[Dictionary], id_buscado: String) -> bool:
	for item in lista:
		if item["id"] == id_buscado:
			return true
	return false
