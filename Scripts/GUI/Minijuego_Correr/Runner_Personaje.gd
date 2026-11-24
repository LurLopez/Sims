class_name Runner_Personaje
extends Node2D

# ============================================================================
# Forma 2D del protagonista del minijuego "Salir a correr".
#
# Renderiza el Personaje_Visual 2D real del Sim (misma cara, género, edad,
# peinado, gafas, sombrero y ropa equipada) anclado por los pies, con
# inclinación lateral, destello de impacto y sincronización de poses.
# ============================================================================

const ALTURA_REFERENCIA := 205.0
const ANCHO_REFERENCIA := 175.0

var apariencia: Dictionary = {}
var pose: String = "correr":
	set(valor):
		if pose != valor:
			pose = valor
			_Sincronizar_Pose_2D()
			queue_redraw()

var t: float = 0.0
var escala: float = 1.0:
	set(valor):
		escala = valor
		_Actualizar_Transform_2D()
var destello: float = 0.0
var animar: bool = true:
	set(valor):
		animar = valor
		if _personaje_2d != null:
			_personaje_2d.animar_idle = valor
var velocidad: float = 13.0
var inclinacion: float = 0.0:
	set(valor):
		inclinacion = valor
		rotation = inclinacion

var _personaje_2d: Personaje_Visual = null


func _ready() -> void:
	_Asegurar_Personaje_2D()
	_Sincronizar_Pose_2D()
	_Actualizar_Transform_2D()


func _Asegurar_Personaje_2D() -> void:
	if _personaje_2d != null:
		return
	var ap_inicial: Dictionary = apariencia if not apariencia.is_empty() else Banner_Correr._Obtener_Apariencia_Actual()
	_personaje_2d = Personaje_Visual.new(ap_inicial, "cuerpo_completo")
	_personaje_2d.name = "Personaje_Visual_2D"
	_personaje_2d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_personaje_2d.dibujar_fondo_sunburst = false
	_personaje_2d.animar_idle = animar
	add_child(_personaje_2d)


func configurar(datos: Dictionary) -> void:
	apariencia = Apariencia_Personaje.normalizar(datos)
	_Asegurar_Personaje_2D()
	_personaje_2d.apariencia = apariencia
	_Sincronizar_Pose_2D()
	_Actualizar_Transform_2D()
	queue_redraw()


func _Sincronizar_Pose_2D() -> void:
	if _personaje_2d == null:
		return
	match pose:
		"menu":
			_personaje_2d.pose = "idle"
			_personaje_2d.expresion = "feliz"
		"correr":
			_personaje_2d.pose = "correr"
			_personaje_2d.expresion = "concentrado"
		"saltar", "caer":
			_personaje_2d.pose = "volando"
			_personaje_2d.expresion = "feliz"
		"deslizar":
			_personaje_2d.pose = "correr"
			_personaje_2d.expresion = "concentrado"
		"choque":
			_personaje_2d.pose = "sorpresa"
			_personaje_2d.expresion = "panico"
		"celebrar":
			_personaje_2d.pose = "celebrar"
			_personaje_2d.expresion = "feliz"
		_:
			_personaje_2d.pose = "correr"
			_personaje_2d.expresion = "concentrado"


func _Actualizar_Transform_2D() -> void:
	if _personaje_2d == null:
		return
	var w: float = ANCHO_REFERENCIA * escala
	var h: float = ALTURA_REFERENCIA * escala
	_personaje_2d.size = Vector2(w, h)
	_personaje_2d.position = Vector2(-w * 0.5, -h)
	rotation = inclinacion


func _process(delta: float) -> void:
	if animar:
		t += delta
	if destello > 0.0:
		destello = maxf(0.0, destello - delta * 3.4)
		if _personaje_2d != null:
			_personaje_2d.modulate = Color.WHITE.lerp(Color(1.0, 0.42, 0.36), clampf(destello, 0.0, 1.0))
	elif _personaje_2d != null and _personaje_2d.modulate != Color.WHITE:
		_personaje_2d.modulate = Color.WHITE
