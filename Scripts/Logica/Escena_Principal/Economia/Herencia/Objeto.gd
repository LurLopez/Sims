class_name Objeto
extends Resource

@export var nombre: String = ""
@export var nombre_visible: String = ""
@export var descripcion: String = ""
@export var precio: float = 0.0
@export var multiplicador: float = 1.0
@export var afecta_a: String = ""
@export var es_basico: bool = false
# Tier visual de la tarjeta: basico, premium, lujo o elite.
@export var tier: String = "basico"
# Texto corto del efecto que se muestra bajo el precio (×1.05 Descanso...).
@export var etiqueta_efecto: String = ""
# Bonificaciones de progreso de los muebles de estudio y cocina.
@export var bonus_progreso_deporte: float = 0.0
@export var bonus_progreso_academico: float = 0.0
@export var bonus_progreso_manualidades: float = 0.0
@export var bonus_progreso_cocina: float = 0.0
@export var bonus_calidad_tupper: float = 0.0


func nombre_para_mostrar() -> String:
	return nombre_visible if nombre_visible != "" else nombre.replace("_", " ")
