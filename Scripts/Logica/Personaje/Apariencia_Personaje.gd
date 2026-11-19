class_name Apariencia_Personaje
extends RefCounted
## Modelo de datos y paletas para la personalización visual del personaje.
## Diseñado para ser serializado en Variables_Estaticas.Apariencia y consumido
## por Personaje_Visual (retrato, creador, cómic y futuras animaciones de actividad).

const GENEROS: Array[Dictionary] = [
	{"id": "hombre", "nombre": "Hombre"},
	{"id": "mujer", "nombre": "Mujer"},
]

const COLORES_PIEL: Array[Dictionary] = [
	{"id": "porcelana", "nombre": "Porcelana", "hex": "#fde4d4"},
	{"id": "claro", "nombre": "Claro", "hex": "#f8cfb4"},
	{"id": "melocoton", "nombre": "Melocotón", "hex": "#f1bb95"},
	{"id": "dorado", "nombre": "Dorado", "hex": "#e1a274"},
	{"id": "canela", "nombre": "Canela", "hex": "#c68255"},
	{"id": "bronce", "nombre": "Bronce", "hex": "#9e613c"},
	{"id": "cacao", "nombre": "Cacao", "hex": "#754428"},
	{"id": "ebano", "nombre": "Ébano", "hex": "#4e2c1a"},
]

const COLORES_OJOS: Array[Dictionary] = [
	{"id": "castano", "nombre": "Castaño", "hex": "#6b4226"},
	{"id": "oscuro", "nombre": "Oscuro", "hex": "#251c17"},
	{"id": "ambar", "nombre": "Ámbar", "hex": "#c47d1a"},
	{"id": "avellana", "nombre": "Avellana", "hex": "#7c8532"},
	{"id": "verde", "nombre": "Verde", "hex": "#228b4e"},
	{"id": "azul", "nombre": "Azul", "hex": "#2563eb"},
	{"id": "celeste", "nombre": "Celeste", "hex": "#0ea5e9"},
	{"id": "gris", "nombre": "Gris", "hex": "#64748b"},
]

const COLORES_PELO: Array[Dictionary] = [
	{"id": "negro", "nombre": "Negro", "hex": "#1e1b18"},
	{"id": "castano_oscuro", "nombre": "Castaño oscuro", "hex": "#432818"},
	{"id": "castano", "nombre": "Castaño", "hex": "#7c4728"},
	{"id": "rubio", "nombre": "Rubio", "hex": "#eab308"},
	{"id": "platino", "nombre": "Platino", "hex": "#ead9b0"},
	{"id": "pelirrojo", "nombre": "Pelirrojo", "hex": "#c2410c"},
	{"id": "caoba", "nombre": "Caoba", "hex": "#7f1d1d"},
	{"id": "gris", "nombre": "Plata", "hex": "#94a3b8"},
	{"id": "azul", "nombre": "Azul", "hex": "#2563eb"},
	{"id": "rosa", "nombre": "Rosa", "hex": "#db2777"},
]

const ESTILOS_PELO: Array[Dictionary] = [
	{"id": "alborotado", "nombre": "Alborotado", "sugerido": "hombre"},
	{"id": "corto", "nombre": "Corto", "sugerido": "hombre"},
	{"id": "rizado", "nombre": "Rizado", "sugerido": "ambos"},
	{"id": "rapado", "nombre": "Rapado", "sugerido": "hombre"},
	{"id": "largo", "nombre": "Largo", "sugerido": "mujer"},
	{"id": "media_melena", "nombre": "Melena", "sugerido": "mujer"},
	{"id": "coleta", "nombre": "Coleta", "sugerido": "mujer"},
	{"id": "mono", "nombre": "Moño", "sugerido": "mujer"},
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
]

const ESTILOS_GAFAS: Array[Dictionary] = [
	{"id": "ninguna", "nombre": "Sin gafas"},
	{"id": "redondas", "nombre": "Redondas"},
	{"id": "cuadradas", "nombre": "Cuadradas"},
]

const ESTILOS_VELLO: Array[Dictionary] = [
	{"id": "ninguno", "nombre": "Ninguno"},
	{"id": "barba_corta", "nombre": "Barba"},
	{"id": "bigote", "nombre": "Bigote"},
	{"id": "perilla", "nombre": "Perilla"},
]

const NOMBRES_HOMBRE: Array[String] = [
	"Alex", "Lucas", "Mateo", "Hugo", "Daniel", "Leo", "Pablo",
	"Adrián", "Diego", "Marcos", "Iván", "Nicolás", "Javier", "Bruno",
]

const NOMBRES_MUJER: Array[String] = [
	"Lucía", "Sofía", "Martina", "Paula", "Valeria", "Julia", "Alba",
	"Elena", "Noa", "Clara", "Carmen", "Laura", "Nora", "Sara",
]

# Mapeo preparado para el futuro sistema de animaciones por actividad.
# Cuando se implementen las animaciones en pantalla principal, basta consultar esta tabla.
const POSE_POR_ACTIVIDAD: Dictionary = {
	"": "idle",
	"Salir_A_Correr": "correr",
	"Dormir": "dormir",
	"Comer": "comer",
	"Duchar": "duchar",
	"Estudiar": "estudiar",
	"Estudiar_Carrera": "estudiar",
	"Examen_Carrera": "estudiar",
	"Ver_La_Television": "tv",
	"Practicar_Manualidades": "manualidades",
}


static func por_defecto() -> Dictionary:
	return {
		"nombre": "",
		"genero": "hombre",
		"color_piel": "#f8cfb4",
		"color_ojos": "#6b4226",
		"color_pelo": "#7c4728",
		"estilo_pelo": "alborotado",
		"color_ropa": "#2563eb",
		"gafas": "ninguna",
		"vello_facial": "ninguno",
		"pecas": false,
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
	base["color_piel"] = _hex_valido(d.get("color_piel", ""), base["color_piel"])
	base["color_ojos"] = _hex_valido(d.get("color_ojos", ""), base["color_ojos"])
	base["color_pelo"] = _hex_valido(d.get("color_pelo", ""), base["color_pelo"])
	base["color_ropa"] = _hex_valido(d.get("color_ropa", ""), base["color_ropa"])

	var pelo := str(d.get("estilo_pelo", base["estilo_pelo"]))
	if not _existe_id(ESTILOS_PELO, pelo):
		pelo = "largo" if genero == "mujer" else "alborotado"
	base["estilo_pelo"] = pelo

	var gafas := str(d.get("gafas", base["gafas"]))
	if not _existe_id(ESTILOS_GAFAS, gafas):
		gafas = "ninguna"
	base["gafas"] = gafas

	var vello := str(d.get("vello_facial", base["vello_facial"]))
	if genero == "mujer" or not _existe_id(ESTILOS_VELLO, vello):
		vello = "ninguno"
	base["vello_facial"] = vello

	base["pecas"] = bool(d.get("pecas", false))
	return base


static func aleatoria(genero_forzado: String = "") -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var genero := genero_forzado
	if genero != "hombre" and genero != "mujer":
		genero = "mujer" if rng.randi_range(0, 1) == 1 else "hombre"

	# Elegir peinado con preferencia natural por género, permitiendo variedad
	var pelos_compatibles: Array[String] = []
	for item in ESTILOS_PELO:
		var sug: String = item["sugerido"]
		if sug == genero or sug == "ambos":
			pelos_compatibles.append(item["id"])
			pelos_compatibles.append(item["id"])
		else:
			pelos_compatibles.append(item["id"])
	var estilo_pelo: String = pelos_compatibles[rng.randi_range(0, pelos_compatibles.size() - 1)]

	# Pelo natural más frecuente que fantasía (85% natural, 15% fantasía)
	var idx_pelo: int = rng.randi_range(0, 7) if rng.randf() < 0.85 else rng.randi_range(8, COLORES_PELO.size() - 1)
	var idx_piel: int = rng.randi_range(0, COLORES_PIEL.size() - 1)
	var idx_ojos: int = rng.randi_range(0, COLORES_OJOS.size() - 1)
	var idx_ropa: int = rng.randi_range(0, COLORES_ROPA.size() - 1)

	var gafas := "ninguna"
	if rng.randf() < 0.24:
		gafas = "redondas" if rng.randf() < 0.5 else "cuadradas"

	var vello := "ninguno"
	if genero == "hombre" and rng.randf() < 0.28:
		var opciones_vello: Array[String] = ["barba_corta", "bigote", "perilla"]
		vello = opciones_vello[rng.randi_range(0, opciones_vello.size() - 1)]

	var pecas: bool = rng.randf() < 0.22
	var lista_nombres: Array[String] = NOMBRES_MUJER if genero == "mujer" else NOMBRES_HOMBRE
	var nombre: String = lista_nombres[rng.randi_range(0, lista_nombres.size() - 1)]

	return {
		"nombre": nombre,
		"genero": genero,
		"color_piel": COLORES_PIEL[idx_piel]["hex"],
		"color_ojos": COLORES_OJOS[idx_ojos]["hex"],
		"color_pelo": COLORES_PELO[idx_pelo]["hex"],
		"estilo_pelo": estilo_pelo,
		"color_ropa": COLORES_ROPA[idx_ropa]["hex"],
		"gafas": gafas,
		"vello_facial": vello,
		"pecas": pecas,
	}


static func nombre_aleatorio(genero: String) -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var lista: Array[String] = NOMBRES_MUJER if genero == "mujer" else NOMBRES_HOMBRE
	return lista[rng.randi_range(0, lista.size() - 1)]


static func es_mujer(datos: Dictionary) -> bool:
	return str(datos.get("genero", "hombre")) == "mujer"


static func etiqueta_genero(datos: Dictionary) -> String:
	return "Mujer" if es_mujer(datos) else "Hombre"


static func pose_para_actividad(nombre_actividad: String) -> String:
	if POSE_POR_ACTIVIDAD.has(nombre_actividad):
		return str(POSE_POR_ACTIVIDAD[nombre_actividad])
	if nombre_actividad.begins_with("Trabajar_"):
		return "trabajar"
	return "idle"


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


static func _existe_id(lista: Array[Dictionary], id_buscado: String) -> bool:
	for item in lista:
		if item["id"] == id_buscado:
			return true
	return false
