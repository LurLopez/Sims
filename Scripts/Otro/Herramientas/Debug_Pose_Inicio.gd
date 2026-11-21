class_name Debug_Pose_Inicio
extends RefCounted
## Herramienta de QA para revisar las animaciones del escenario de Inicio sin
## tener que programar ni ejecutar la actividad real.
##
## Uso: cambia POSE_FORZADA y vuelve a lanzar el juego (./jugar.sh). El
## escenario de Inicio y el del menú mostrarán siempre esa pose. No modifica
## la matriz, las necesidades ni el dinero: solo lo que se dibuja.
##
##   "0"            -> desactivado (se ve la actividad real)
##   "idle"         -> siempre tiempo libre / actividad espontánea
##   "correr"       -> siempre corriendo
##   "dormir"       -> siempre durmiendo
##   "comer"        -> siempre comiendo
##   "duchar"       -> siempre duchándose
##   "estudiar"     -> siempre estudiando
##   "tv"           -> siempre viendo la televisión
##   "manualidades" -> siempre con manualidades
##   "cocinar"      -> siempre cocinando
##   "fiesta"       -> siempre de fiesta
##   "futbol"       -> siempre jugando al fútbol
##   "trabajar"     -> siempre trabajando
##
## También acepta el nombre exacto de una actividad del catálogo
## ("Dormir", "Salir_De_Fiesta", "Partido_Futbol"...), útil al añadir
## animaciones nuevas. Si el valor no existe se ignora y se avisa por consola.
##
## FORZAR_CALLE: -1 = estado real · 0 = siempre con vivienda · 1 = siempre en la calle.
## Solo afecta a las poses con variante de calle ("idle" y "comer").

## Cambia estos valores y vuelve a lanzar el juego. También se pueden modificar
## en caliente desde una herramienta de prueba (son variables estáticas).
static var POSE_FORZADA: String = "0"
static var FORZAR_CALLE: int = -1

## Pose -> actividad de referencia que Escenario_Actividad ya sabe dibujar.
const ACTIVIDAD_POR_POSE: Dictionary = {
	"idle": "Actividad_Aleatoria",
	"correr": "Salir_A_Correr",
	"dormir": "Dormir",
	"comer": "Comer_Tupper",
	"duchar": "Duchar",
	"estudiar": "Estudiar",
	"tv": "Ver_La_Television",
	"manualidades": "Practicar_Manualidades",
	"cocinar": "Cocinar",
	"fiesta": "Salir_De_Fiesta",
	"futbol": "Partido_Futbol",
	"trabajar": "Trabajar_En_Comida_Rapida",
}

static var _aviso_mostrado: bool = false


## Nombre de actividad que debe usar Escenario_Actividad. Devuelve "" cuando
## el override está desactivado y hay que dejar pasar el estado real.
static func actividad_forzada() -> String:
	var clave := POSE_FORZADA.strip_edges()
	if clave == "" or clave == "0":
		return ""
	if ACTIVIDAD_POR_POSE.has(clave):
		_avisar_una_vez(clave)
		return str(ACTIVIDAD_POR_POSE[clave])
	if Apariencia_Personaje.POSE_POR_ACTIVIDAD.has(clave):
		_avisar_una_vez(clave)
		return clave
	if not _aviso_mostrado:
		_aviso_mostrado = true
		push_warning("Debug_Pose_Inicio: «%s» no es una pose válida; se usa la actividad real." % clave)
	return ""


## -1 = no fuerza la vivienda; 0 = fuerza vivienda; 1 = fuerza calle.
static func calle_forzada() -> int:
	return clampi(FORZAR_CALLE, -1, 1)


static func _avisar_una_vez(clave: String) -> void:
	if _aviso_mostrado:
		return
	_aviso_mostrado = true
	print("[Debug_Pose_Inicio] Forzando la pose «%s». Pon POSE_FORZADA = \"0\" para volver a la normalidad." % clave)
