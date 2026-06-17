class_name Actividad
extends Resource

@export var nombre: String = ""
@export var color: Color = Color.WHITE
@export var icono: Texture2D = null
@export var efectos_necesidades_basicas: Array = [0, 0, 0, 0, 0]
@export var efectos_progreso: Array = [0, 0, 0]

func Obtener_Prioridad() -> int:
	return 1
